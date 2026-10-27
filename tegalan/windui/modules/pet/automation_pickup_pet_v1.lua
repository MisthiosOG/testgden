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
	local READY_TH = 0

	local GetPetCooldown = RS:WaitForChild("GameEvents"):WaitForChild("GetPetCooldown")

	local function readMainCd(uuid)
		local ok, cd = pcall(function() return GetPetCooldown:InvokeServer(uuid) end)
		if not ok or type(cd) ~= "table" then return nil end
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

	-- Target = pet yang UDAH di papan + pet kepilihan yang MASIH DI INVENTORY
	-- (needEquip). Dulu kandidat cuma dari EquippedPets -> pet kepilih di
	-- dropdown tapi belum di-equip gak pernah jadi target (serta-lion gak
	-- kepickup). Pet inventory kepilihan dianggap target & di tempatkan otomatis
	-- oleh thread-nya (cek cd baru relevan SETELAH pet beneran di papan).
	local equippedSet = {}
	local function targetPets()
		local out = {}
		table.clear(equippedSet)
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d then return out end
		local eq  = d.PetsData and d.PetsData.EquippedPets
		local inv = d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data
		if not eq then return out end
		local sel = CFG.pnpUuids or {}
		for _, uuid in ipairs(eq) do
			equippedSet[uuid] = true
			local pt = inv and inv[uuid] and inv[uuid].PetType
			if (not next(sel)) or sel[uuid] then
				out[#out + 1] = { uuid = uuid, petType = pt }
			end
		end
		if next(sel) and inv then
			for uuid in pairs(sel) do
				if not equippedSet[uuid] and inv[uuid] then
					out[#out + 1] = { uuid = uuid, petType = inv[uuid].PetType, needEquip = true }
				end
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
	local petThreads = {}
	local lastEquipTry = {}
	local function runPetThread(uuid, myId, needEquip)
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
			elseif target.needEquip then
				-- Pilihan pet belum di papan (masih inventory): tempatkan
				-- langsung, jangan nunggu cd (cd baru ada setelah ditempatkan).
				-- Guard 1.5s: kalau place gagal (papan penuh), gak spam RPC.
				if os.clock() - (lastEquipTry[uuid] or 0) >= 1.5 then
					lastEquipTry[uuid] = os.clock()
					pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
				end
				task.wait(0.5)
			else
				local mainCd = readMainCd(uuid)
				if pos and mainCd ~= nil and mainCd <= READY_TH then
					if (CFG.pickupDelay or 0) > 0 then task.wait(CFG.pickupDelay) end
					if not (CFG.pnpEnabled and ctx.state.pnpV1Id == myId) then break end
					pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
					task.wait(math.max(0.01, CFG.equipDelay or 0.03))
					if not (CFG.pnpEnabled and ctx.state.pnpV1Id == myId) then break end
					pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
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
				setStatus("PNP V1: tidak ada pet target (equip pet dulu)")
			else
				local neq = 0
				for _, p in ipairs(pets) do
					if p.needEquip then neq = neq + 1 end
					if not petThreads[p.uuid] then task.spawn(runPetThread, p.uuid, myId, p.needEquip) end
				end
				setStatus(neq > 0
					and ("PNP V1: %d pet (%d sedang dipapanin otomatis)"):format(#pets, neq)
					or ("PNP V1 (polling): %d pet"):format(#pets))
			end
			task.wait(1)
		end
	end

	function ctx.startPnpV1() task.spawn(pnpLoop) end
	function ctx.stopPnpV1() ctx.state.pnpV1Id = (ctx.state.pnpV1Id or 0) + 1 end -- bump id -> loop lama mati
end
