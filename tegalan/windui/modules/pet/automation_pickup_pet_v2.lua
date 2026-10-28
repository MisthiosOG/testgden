--[[ automation_pickup_pet_v2.lua — PnP V2 (EVENT-DRIVEN).
     BUKAN polling. Dengerin RemoteEvent server `PetCooldownsUpdated` yang PUSH cooldown tiap
     berubah (nol round-trip -> nol jitter -> stabil). Actor act dari cd real-time di memori.
     Config SENDIRI: pnpV2Uuids, pnpV2PickupDelay, pnpV2EquipDelay, pnpV2ScanInterval, pnpV2Enabled.
     Fungsi: ctx.startPnpV2 / ctx.stopPnpV2. Dropdown pakai ctx.inventoryPetOptions (dari V1). ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local PetsService = ctx.deps.PetsService
	local CFG         = ctx.CFG
	local function setStatus(s) ctx.setStatus(s) end

	local RS = game:GetService("ReplicatedStorage")
	local LP = ctx.LP

	local cdMap = ctx.state.cdMap or {}
	ctx.state.cdMap = cdMap
	-- Ready = cd habis. 0.05 buat noleransi residual cd tipis (server kadang
	-- masih ngasih 0.001 padahal skill udah ready).
	local READY_TH = 0.05

	local GameEvents = RS:WaitForChild("GameEvents")
	local GetPetCooldown = GameEvents:WaitForChild("GetPetCooldown")           -- seed awal
	local PetCooldownsUpdated = GameEvents:WaitForChild("PetCooldownsUpdated") -- push cd real-time

	local function computeMainCd(cd)
		if type(cd) ~= "table" then return nil end
		local data, mainCd = {}, 0
		for _, e in ipairs(cd) do
			local t = tonumber(e.Time) or 0
			data[#data + 1] = { Passive = e.Passive, Time = t }
			if not tostring(e.Passive or ""):find("Mutation") then
				if t > mainCd then mainCd = t end
			end
		end
		return mainCd, data
	end

	-- cdLive: cd real-time per pet, di-update oleh event PetCooldownsUpdated (server push).
	local cdLive = {}
	ctx.state.pnpV2CdLive = cdLive
	do
		local g = (getgenv and getgenv()) or _G
		if g.__pnpV2CdConn then pcall(function() g.__pnpV2CdConn:Disconnect() end) end
		g.__pnpV2CdConn = PetCooldownsUpdated.OnClientEvent:Connect(function(uuid, cdTable)
			if type(uuid) ~= "string" then return end
			local m, data = computeMainCd(cdTable)
			if m ~= nil then cdLive[uuid] = m; cdMap[uuid] = { data = data } end
		end)
	end
	local function seedCd(uuid)
		local ok, cd = pcall(function() return GetPetCooldown:InvokeServer(uuid) end)
		local m, data = computeMainCd(ok and cd or nil)
		if m ~= nil then cdLive[uuid] = m; cdMap[uuid] = { data = data } end
	end

	-- Target CUMA pet yang udah di papan (EquippedPets). Pet yang masih di
	-- inventory GAK pernah dipapanin otomatis — pickup harus Diam saat board
	-- kosong, samayang naruh pet manual adalah tugas pengguna. Pilihan dropdown
	-- hanya memfilter pet yang sedang berada di papan.
	local function targetPets()
		local out = {}
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d then return out end
		local eq  = d.PetsData and d.PetsData.EquippedPets
		local inv = d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data
		if not eq then return out end
		local sel = CFG.pnpV2Uuids or {}
		for _, uuid in ipairs(eq) do
			if (not next(sel)) or sel[uuid] then
				out[#out + 1] = { uuid = uuid, petType = inv and inv[uuid] and inv[uuid].PetType }
			end
		end
		return out
	end

	local GetFarm = require(RS.Modules.GetFarm)
	local function placePos()
		local farm = GetFarm and GetFarm(LP)
		local pa = farm and farm:FindFirstChild("PetArea")
		if pa then return pa.Position end
		local char = LP.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		return hrp and hrp.Position or nil
	end

	-- Pet masih di papan? true/false; nil = data gak kebaca (anggep oke, jangan loop).
	local function inEquipped(uuid)
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d then return nil end
		local eq = d.PetsData and d.PetsData.EquippedPets
		if not eq then return nil end
		for _, u in ipairs(eq) do if u == uuid then return true end end
		return false
	end

	----------------------------------------------------------------- loop (event-driven, paralel per-pet)
	local petThreads = {}
	local lastPlace = {}
	local lastSeed  = {}
	-- seed ulang cd kalau masih nil (gagal) tiap 3s; kalau udah ada, refresh
	-- periodik tiap 10s sebagai jaring pengaman — push event gak selalu dateng
	-- buat pet yang cd-nya "diam" di server (kasus Lion gak pernah kepickup).
	local SEED_RETRY, SEED_PERIOD = 3, 10
	local function ensureCd(uuid)
		local due = (cdLive[uuid] == nil) and SEED_RETRY or SEED_PERIOD
		if os.clock() - (lastSeed[uuid] or 0) < due then return end
		lastSeed[uuid] = os.clock()
		seedCd(uuid)
	end

	local function runPetThread(uuid, myId)
		petThreads[uuid] = true
		ensureCd(uuid)
		while CFG.pnpV2Enabled and ctx.alive() and ctx.state.pnpV2Id == myId do
			local target = nil
			for _, p in ipairs(targetPets()) do
				if p.uuid == uuid then target = p; break end
			end
			if not target then break end

			ensureCd(uuid)
			local pos = placePos()
			local cd = cdLive[uuid]
			if not pos then
				task.wait(1)
			elseif cd ~= nil and cd <= READY_TH and (os.clock() - (lastPlace[uuid] or 0)) > 0.25 then
				if (CFG.pnpV2PickupDelay or 0) > 0 then task.wait(CFG.pnpV2PickupDelay) end
				if not (CFG.pnpV2Enabled and ctx.state.pnpV2Id == myId) then break end
				pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
				task.wait(math.max(0.01, CFG.pnpV2EquipDelay or 0.03))
				-- Re-place retry sampai pet beneran balik ke papan. Kalo ditinggal
				-- di inventory, dia ilang dari daftar target & gak pernah
				-- dikerjain lagi (pickup gagal total diam-diam).
				for _ = 1, 5 do
					if not (CFG.pnpV2Enabled and ctx.state.pnpV2Id == myId) then break end
					pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
					task.wait(0.4)
					if inEquipped(uuid) ~= false then break end
				end
				lastPlace[uuid] = os.clock()
			end
			task.wait(math.max(0.02, tonumber(CFG.pnpV2ScanInterval) or 0.05))
		end
		petThreads[uuid] = nil
	end

	local function pnpLoop()
		ctx.state.pnpV2Id = (ctx.state.pnpV2Id or 0) + 1
		local myId = ctx.state.pnpV2Id
		ctx.elevate()
		while CFG.pnpV2Enabled and ctx.alive() and ctx.state.pnpV2Id == myId do
			local pets = targetPets()
			if #pets == 0 then
				setStatus("PNP V2: board kosong — idle (place pet manual)")
			else
				for _, p in ipairs(pets) do
					if not petThreads[p.uuid] then task.spawn(runPetThread, p.uuid, myId) end
				end
				setStatus(("PNP V2 (event-driven): %d pet di papan"):format(#pets))
			end
			task.wait(1)
		end
	end

	function ctx.startPnpV2() task.spawn(pnpLoop) end
	function ctx.stopPnpV2() ctx.state.pnpV2Id = (ctx.state.pnpV2Id or 0) + 1 end
end
