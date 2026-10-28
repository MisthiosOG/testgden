--[[ automation_pickup_pet_v1.lua — PnP V1 (POLLING).
     Tiap pet target punya thread sendiri: query GetPetCooldown -> kalau ready pickup-place.
     Langsung & simpel, tapi kena JITTER latency server (round-trip tiap cek).
     Config SENDIRI: pnpUuids, pickupDelay, equipDelay, pnpScanInterval, pnpEnabled.
     Fungsi: ctx.startPnpV1 / ctx.stopPnpV1. Juga expose ctx.inventoryPetOptions (dipakai V1 & V2). ]]
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

	local GetPetCooldown = RS:WaitForChild("GameEvents"):WaitForChild("GetPetCooldown")

	-- InvokeServer bisa MACET (server gak balas) -> thread pet mati selamanya
	-- (petThreads stuck, gak pernah respown). Wrap: timeout 5s + cancel thread.
	-- Shared via ctx.state (V2 punya implementasi sama).
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

	local function readMainCd(uuid)
		local cd, timedOut = invokeCd(GetPetCooldown, uuid, 5)
		if timedOut then
			local okd, d = pcall(function() return DataService:GetData() end)
			local pt = okd and d and d.PetsData and d.PetsData.PetInventory
				and d.PetsData.PetInventory.Data and d.PetsData.PetInventory.Data[uuid]
			ctx.log(("PnP V1 %s: read cd TIMEOUT (server gak balas)")
				:format(pt and tostring(pt.PetType) or uuid:sub(2, 9)))
			return nil
		end
		if type(cd) ~= "table" then return nil end
		local data, mainCd = {}, 0
		for _, e in ipairs(cd) do
			local t = tonumber(e.Time) or 0
			data[#data + 1] = { Passive = e.Passive, Time = t }
			if not tostring(e.Passive or ""):find("Mutation") then
				if t > mainCd then mainCd = t end
			end
		end
		cdMap[uuid] = { data = data }
		return mainCd
	end

	-- Target CUMA pet yang udah di papan (EquippedPets). Pet yang masih di
	-- inventory GAK dipapanin otomatis — pickup harus diem kalo board kosong;
	-- naruh pet manual itu urusan user. Pilihan dropdown cuma ngefilter pet
	-- yang ada di papan.
	local function targetPets()
		local out = {}
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d then return out end
		local eq  = d.PetsData and d.PetsData.EquippedPets
		local inv = d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data
		if not eq then return out end
		local sel = CFG.pnpUuids or {}
		for _, uuid in ipairs(eq) do
			if (not next(sel)) or sel[uuid] then
				out[#out + 1] = { uuid = uuid, petType = inv and inv[uuid] and inv[uuid].PetType }
			end
		end
		return out
	end

	-- daftar pet dari INVENTORY buat dropdown Select Pets (SHARED: dipakai V1 & V2).
	function ctx.inventoryPetOptions(selectedSet)
		local out = {}
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d then return out end
		local inv = d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data
		if not inv then return out end
		local eq = d.PetsData.EquippedPets or {}
		local eqSet = {}; for _, u in ipairs(eq) do eqSet[u] = true end
		for uuid, v in pairs(inv) do
			local pt = v.PetType or "?"
			local pd = v.PetData or {}
			local age = pd.Level or 0
			local mut = pd.MutationType
			local mutName = mut
			if mut and ctx.reg and ctx.reg.mutDisplay then mutName = ctx.reg.mutDisplay(mut) end
			local mutPrefix = (mut and mut ~= "" and mut ~= "Normal") and (tostring(mutName) .. " ") or ""
			local weight = (pd.BaseWeight or 0) * (1 + 0.1 * age)
			local tag = eqSet[uuid] and " [aktif]" or ""
			out[#out + 1] = {
				value = uuid,
				kg = weight, -- buat sort terberat dulu
				display = ("%s%s | %.2f KG | Age %s | #%s%s"):format(mutPrefix, pt, weight, tostring(age), uuid:sub(2, 5), tag),
			}
		end
		if selectedSet and next(inv) then
			local valid = {}
			for uuid in pairs(inv) do valid[uuid] = true end
			local changed = false
			for u in pairs(selectedSet) do
				if not valid[u] then selectedSet[u] = nil; changed = true end
			end
			if changed and ctx.persistState then ctx.persistState() end
		end
		table.sort(out, function(a, b)
			local selA = selectedSet and selectedSet[a.value] and 1 or 0
			local selB = selectedSet and selectedSet[b.value] and 1 or 0
			if selA ~= selB then return selA > selB end
			local ka, kb = a.kg or 0, b.kg or 0
			if ka ~= kb then return ka > kb end -- terberat dulu
			return a.display < b.display
		end)
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

	----------------------------------------------------------------- loop (polling, paralel per-pet)
	-- Pet masih di papan? true/false; nil = data gak kebaca (anggep oke).
	local function inEquipped(uuid)
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d then return nil end
		local eq = d.PetsData and d.PetsData.EquippedPets
		if not eq then return nil end
		for _, u in ipairs(eq) do if u == uuid then return true end end
		return false
	end

	local petThreads = {}
	local function runPetThread(uuid, myId)
		petThreads[uuid] = true
		while CFG.pnpEnabled and ctx.alive() and ctx.state.pnpV1Id == myId do
			local target = nil
			for _, p in ipairs(targetPets()) do
				if p.uuid == uuid then target = p; break end
			end
			if not target then break end

			local pos = placePos()
			if not pos then
				task.wait(1)
			else
				local mainCd = readMainCd(uuid)
				if mainCd ~= nil and mainCd <= READY_TH then
					if (CFG.pickupDelay or 0) > 0 then task.wait(CFG.pickupDelay) end
					if not (CFG.pnpEnabled and ctx.state.pnpV1Id == myId) then break end
					pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
					task.wait(math.max(0.01, CFG.equipDelay or 0.03))
					-- Re-place retry sampai pet beneran balik ke papan. Kalo
					-- ditinggal di inventory, dia ilang dari daftar target &
					-- gak pernah dikerjain lagi (pickup gagal total diam-diam).
					for _ = 1, 5 do
						if not (CFG.pnpEnabled and ctx.state.pnpV1Id == myId) then break end
						pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
						task.wait(0.4)
						if inEquipped(uuid) ~= false then break end
					end
				end
				-- Wait sadar-cd: cd masih panjang -> poll pelan (maks 1s),
				-- hemat RPC; cd mau habis / gak ada -> scan normal.
				local w = (mainCd and mainCd > READY_TH) and math.min(math.max(mainCd, 0.1), 1)
					or (math.max(0.01, tonumber(CFG.pnpScanInterval) or 0.05))
				task.wait(w)
			end
		end
		petThreads[uuid] = nil
	end

	local function pnpLoop()
		ctx.state.pnpV1Id = (ctx.state.pnpV1Id or 0) + 1
		local myId = ctx.state.pnpV1Id
		ctx.elevate()
		while CFG.pnpEnabled and ctx.alive() and ctx.state.pnpV1Id == myId do
			local pets = targetPets()
			if #pets == 0 then
				setStatus("PNP V1: board kosong — idle (place pet manual)")
			else
				for _, p in ipairs(pets) do
					if not petThreads[p.uuid] then task.spawn(runPetThread, p.uuid, myId) end
				end
				setStatus(("PNP V1 (polling): %d pet di papan"):format(#pets))
			end
			task.wait(1)
		end
	end

	function ctx.startPnpV1() task.spawn(pnpLoop) end
	function ctx.stopPnpV1() ctx.state.pnpV1Id = (ctx.state.pnpV1Id or 0) + 1 end -- bump id -> loop lama mati

	-- Force pickup: langsung cycle semua pet target di papan, abaikan cd.
	function ctx.forcePickupPets()
		local pets = targetPets()
		for _, p in ipairs(pets) do
			task.spawn(function()
				local pos = placePos()
				if pos then
					pcall(function() PetsService:FireServer("UnequipPet", p.uuid) end)
					task.wait(math.max(0.01, CFG.equipDelay or 0.03))
					pcall(function() PetsService:FireServer("EquipPet", p.uuid, CFrame.new(pos)) end)
					ctx.log(("PnP V1 %s: force pickup"):format(p.petType or p.uuid:sub(2, 9)))
				end
			end)
		end
		return #pets
	end
end
