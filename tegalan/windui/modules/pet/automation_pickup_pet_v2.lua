--[[ automation_pickup_pet_v2.lua — PnP V2 (EVENT-DRIVEN + seed anti-macet).
     Sumber cd: push `PetCooldownsUpdated` (real-time) + seed `GetPetCooldown`
     yang DIPROTEKSI TIMEOUT (5s) & serialized. InvokeServer yang macet dulu
     bekukan thread pet SELAMANYA (petThreads stuck -> gak pernah respown) —
     sekarang seed jalan di task sendiri; thread pet CUMA baca cache cdLive.
     Re-place di-retry sampai pet ke-verify balik di EquippedPets.
     Force-pickup manual: ctx.forcePickupPets (tombol di tab Pet > Pickup V2).
     Config SENDIRI: pnpV2Uuids, pnpV2PickupDelay, pnpV2EquipDelay, pnpV2ScanInterval, pnpV2Enabled.
     Fungsi: ctx.startPnpV2 / ctx.stopPnpV2 / ctx.forcePickupPets.
     Dropdown pakai ctx.inventoryPetOptions (dari V1). ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local PetsService = ctx.deps.PetsService
	local CFG         = ctx.CFG
	local function setStatus(s) ctx.setStatus(s) end

	local RS = game:GetService("ReplicatedStorage")
	local LP = ctx.LP

	local cdMap = ctx.state.cdMap or {}
	ctx.state.cdMap = cdMap
	-- Ready = cd habis. 0.05 = toleransi residual cd tipis (server kadang
	-- ngasih 0.001 padahal skill udah ready).
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

	----------------------------------------------------------------- diagnostics
	-- Log hemat ke panel Logs (Settings -> Logs): per pet cuma pas state berubah.
	local petNames = {} -- uuid -> PetType (diisi targetPets)
	local lastDiag, lastDiagT = {}, {}
	local function dlog(uuid, msg)
		local now = os.clock()
		if lastDiag[uuid] == msg and (now - (lastDiagT[uuid] or 0)) < 15 then return end
		lastDiag[uuid] = msg
		lastDiagT[uuid] = now
		ctx.log(("PnP V2 %s: %s"):format(petNames[uuid] or uuid:sub(2, 9), msg))
	end

	----------------------------------------------------------------- seed cd (timeout + serialized)
	-- InvokeServer bisa MACET (server gak balas) -> task pemanggil mati selamanya
	-- (penyebab lama: pet "mati total", gak pernah kepickup sampai re-exec).
	-- Seed jalan di task sendiri, timeout 5s, thread nyangkut di-cancel.
	local invokeCd = ctx.state.pnpInvokeCdTimeout
	if not invokeCd then
		invokeCd = function(remote, uuid, timeoutS)
			local result, done = nil, false
			local th = task.spawn(function()
				local ok, cd = pcall(function() return remote:InvokeServer(uuid) end)
				result = (ok and type(cd) == "table") and cd or false
				done = true
			end)
			local t0 = os.clock()
			while not done and os.clock() - t0 < (timeoutS or 5) do task.wait(0.05) end
			if not done then
				pcall(function() task.cancel(th) end)
				return nil, true
			end
			return (result == false) and nil or result, false
		end
		ctx.state.pnpInvokeCdTimeout = invokeCd
	end

	local seedBusy = false
	local lastSeed = {} -- uuid -> os.clock() seed terakhir (in-flight atau done)
	local SEED_RETRY, SEED_PERIOD = 3, 10 -- nil -> retry 3s; udah ada -> refresh 10s
	local function queueSeed(uuid)
		if seedBusy then return end
		local due = (cdLive[uuid] == nil) and SEED_RETRY or SEED_PERIOD
		if os.clock() - (lastSeed[uuid] or 0) < due then return end
		seedBusy = true
		lastSeed[uuid] = os.clock()
		task.spawn(function()
			local cd, timedOut = invokeCd(GetPetCooldown, uuid, 5)
			seedBusy = false
			if timedOut then
				dlog(uuid, "seed cd TIMEOUT (server gak balas — retry otomatis)")
				return
			end
			if cd then
				local m, data = computeMainCd(cd)
				if m ~= nil then
					cdLive[uuid] = m
					cdMap[uuid] = { data = data }
				end
			end
		end)
	end

	----------------------------------------------------------------- target = pet di PAPAN (EquippedPets)
	-- Pet yang masih di inventory GAK pernah dipapanin otomatis — pickup IDLE
	-- kalo board kosong; naruh pet manual itu urusan user.
	local function targetPets()
		local out = {}
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d then return out end
		local eq  = d.PetsData and d.PetsData.EquippedPets
		local inv = d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data
		if not eq then return out end
		local sel = CFG.pnpV2Uuids or {}
		for _, uuid in ipairs(eq) do
			local iv = inv and inv[uuid]
			if iv then petNames[uuid] = iv.PetType or petNames[uuid] end
			if (not next(sel)) or sel[uuid] then
				out[#out + 1] = { uuid = uuid, petType = iv and iv.PetType }
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

	----------------------------------------------------------------- pickup cycle
	-- Satu siklus penuh: unequip -> equip(retry <= 5x sampai terverifikasi balik).
	-- Dipakai thread cd-ready & tombol Force Pickup (myId beda, guard longgar).
	local function pickupOnce(uuid, myId, why)
		local pos = placePos()
		if not pos then
			dlog(uuid, "pickup skip: posisi place gak ada")
			return false
		end
		if (CFG.pnpV2PickupDelay or 0) > 0 then task.wait(CFG.pnpV2PickupDelay) end
		if myId and not (CFG.pnpV2Enabled and ctx.state.pnpV2Id == myId) then return false end
		pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
		dlog(uuid, "pickup (" .. tostring(why or "cd ready") .. ")")
		task.wait(math.max(0.01, CFG.pnpV2EquipDelay or 0.03))
		for _ = 1, 5 do
			if myId and not (CFG.pnpV2Enabled and ctx.state.pnpV2Id == myId) then return false end
			pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
			task.wait(0.4)
			if inEquipped(uuid) ~= false then
				dlog(uuid, "re-place oke")
				return true
			end
		end
		dlog(uuid, "re-place GAGAL 5x — pet nyangkut di inventory!")
		return false
	end

	----------------------------------------------------------------- loop (event-driven, paralel per-pet)
	local petThreads = {}
	local lastPlace = {}
	local function runPetThread(uuid, myId)
		petThreads[uuid] = true
		while CFG.pnpV2Enabled and ctx.alive() and ctx.state.pnpV2Id == myId do
			local target = nil
			for _, p in ipairs(targetPets()) do
				if p.uuid == uuid then target = p; break end
			end
			if not target then break end

			queueSeed(uuid)
			local cd = cdLive[uuid]
			if cd == nil then
				dlog(uuid, "cd belum kebaca (nunggu seed/push)")
			elseif cd <= READY_TH and (os.clock() - (lastPlace[uuid] or 0)) > 0.5 then
				if pickupOnce(uuid, myId, ("cd ready (%.1f)"):format(cd)) then
					lastPlace[uuid] = os.clock()
				end
			end
			task.wait(math.max(0.05, tonumber(CFG.pnpV2ScanInterval) or 0.1))
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

	-- Force pickup: langsung cycle SEMUA pet target di papan, abaikan cd
	-- (buat ngetes / nylamatin pet bandel tanpa nunggu cd).
	function ctx.forcePickupPets()
		local myId = ctx.state.pnpV2Id or 0
		local pets = targetPets()
		for _, p in ipairs(pets) do
			task.spawn(function() pickupOnce(p.uuid, myId, "FORCE") end)
		end
		return #pets
	end
end
