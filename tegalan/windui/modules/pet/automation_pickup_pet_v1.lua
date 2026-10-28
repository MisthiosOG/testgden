--[[ automation_pickup_pet_v1.lua — PnP V1 (SKILL-RESET DETECTION).
     Trick skip-animasi: pickup pet TEPAT SETELAH skill keluar, lalu langsung place lagi.
     Deteksi "skill keluar" = cooldown salah satu passive LOMPAT NAIK (reset ke durasi penuh),
     BUKAN cd == 0 (cd 0 = skill belum keluar; pickup di situ malah ngebatalin skill).
     Sumber cd: event PetCooldownsUpdated (push instan) + polling GetPetCooldown (cadangan).
     Config SENDIRI: pnpUuids, pickupDelay, equipDelay, pnpScanInterval, pnpEnabled.
       pickupDelay     = jeda setelah place sebelum boleh pickup lagi (anti spam)
       equipDelay      = jeda unequip -> equip
       pnpScanInterval = interval polling cd cadangan
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

	local RESET_JUMP     = 1    -- cd naik > ini (detik) = skill baru keluar
	local MIN_EQUIP_GAP  = 0.05 -- unequip->equip minimal; lebih cepat dari ini server sering nolak
	local MIN_POLL       = 0.1  -- polling cadangan minimal (anti throttle)
	local VERIFY_WAIT    = 0.6  -- tunggu pet muncul lagi di EquippedPets sebelum retry
	local EQUIP_RETRIES  = 3

	local GameEvents          = RS:WaitForChild("GameEvents")
	local GetPetCooldown      = GameEvents:WaitForChild("GetPetCooldown")
	local PetCooldownsUpdated = GameEvents:FindFirstChild("PetCooldownsUpdated")

	-------------------------------------------------------------- state per pet
	local prevCd      = {} -- uuid -> { [passiveKey] = time } (sampel terakhir)
	local pending     = {} -- uuid -> true kalau skill baru keluar & belum di-PnP
	local busy        = {} -- uuid -> true selama proses pickup/place
	local ignoreUntil = {} -- uuid -> os.clock(); abaikan lompatan cd akibat place kita sendiri

	-- Ubah tabel cd server jadi { key = time }. Tabel kosong/invalid -> nil (BUKAN "ready").
	local function parseCd(cd)
		if type(cd) ~= "table" or #cd == 0 then return nil end
		local map, data, seen = {}, {}, {}
		for _, e in ipairs(cd) do
			local name = tostring(e.Passive or "?")
			local t = tonumber(e.Time) or 0
			data[#data + 1] = { Passive = e.Passive, Time = t }
			seen[name] = (seen[name] or 0) + 1
			map[name .. "#" .. seen[name]] = t
		end
		return map, data
	end

	local function onCd(uuid, cd)
		local cur, data = parseCd(cd)
		if not cur then return end
		cdMap[uuid] = { data = data }
		local prev = prevCd[uuid]
		prevCd[uuid] = cur
		if not prev or busy[uuid] or os.clock() < (ignoreUntil[uuid] or 0) then return end
		for key, t in pairs(cur) do
			if not key:find("Mutation") then
				local p = prev[key]
				if p and t > p + RESET_JUMP then
					pending[uuid] = true
					return
				end
			end
		end
	end

	do
		local g = (getgenv and getgenv()) or _G
		if g.__pnpV1CdConn then pcall(function() g.__pnpV1CdConn:Disconnect() end) end
		g.__pnpV1CdConn = nil
		if PetCooldownsUpdated then
			g.__pnpV1CdConn = PetCooldownsUpdated.OnClientEvent:Connect(function(uuid, cdTable)
				if type(uuid) == "string" and CFG.pnpEnabled then onCd(uuid, cdTable) end
			end)
		end
	end

	local function pollCd(uuid)
		local ok, cd = pcall(function() return GetPetCooldown:InvokeServer(uuid) end)
		if ok then onCd(uuid, cd) end
	end

	-------------------------------------------------------------- data helpers
	local function equippedSet()
		local ok, d = pcall(function() return DataService:GetData() end)
		local eq = ok and d and d.PetsData and d.PetsData.EquippedPets
		local set = {}
		if eq then for _, u in ipairs(eq) do set[u] = true end end
		return set, ok and d or nil
	end

	local function targetPets()
		local out = {}
		local eqSet, d = equippedSet()
		if not d then return out end
		local inv = d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data
		local sel = CFG.pnpUuids or {}
		for _, uuid in ipairs(d.PetsData.EquippedPets or {}) do
			if (not next(sel)) or sel[uuid] then
				out[#out + 1] = { uuid = uuid, petType = inv and inv[uuid] and inv[uuid].PetType }
			end
		end
		return out
	end

	local function isTarget(uuid)
		local sel = CFG.pnpUuids or {}
		return (not next(sel)) or sel[uuid] == true
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

	-------------------------------------------------------------- pickup & place
	local function alive(myId)
		return CFG.pnpEnabled and ctx.alive() and ctx.state.pnpV1Id == myId
	end

	-- return true kalau pet sukses balik ke kebun
	local function doPnp(uuid, myId)
		local pos = placePos()
		if not pos then return true end
		busy[uuid] = true
		pending[uuid] = nil

		pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
		task.wait(math.max(MIN_EQUIP_GAP, tonumber(CFG.equipDelay) or 0))

		-- Equip + verifikasi. Pet WAJIB balik walau PnP dimatiin di tengah jalan.
		local placed = false
		for _ = 1, EQUIP_RETRIES do
			pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
			local t0 = os.clock()
			repeat task.wait(0.1) until equippedSet()[uuid] or os.clock() - t0 > VERIFY_WAIT
			if equippedSet()[uuid] then placed = true; break end
		end

		-- baseline cd baru; lompatan cd sesaat setelah place bukan skill
		prevCd[uuid] = nil
		ignoreUntil[uuid] = os.clock() + math.max(0.25, tonumber(CFG.pickupDelay) or 0.3)
		busy[uuid] = nil
		if alive(myId) then pollCd(uuid) end
		return placed
	end

	local petThreads = {}
	local function runPetThread(uuid, myId)
		petThreads[uuid] = true
		local lastPoll, polling = 0, false
		while alive(myId) do
			if not isTarget(uuid) or not equippedSet()[uuid] then break end

			if pending[uuid] then
				if not doPnp(uuid, myId) then
					setStatus("PNP V1: gagal place ulang pet #" .. uuid:sub(2, 5) .. " (cek backpack)")
					break
				end
			elseif not polling and os.clock() - lastPoll >= math.max(MIN_POLL, tonumber(CFG.pnpScanInterval) or 0) then
				lastPoll, polling = os.clock(), true
				task.spawn(function() pollCd(uuid); polling = false end)
			end
			task.wait(0.03)
		end
		pending[uuid], prevCd[uuid] = nil, nil
		petThreads[uuid] = nil
	end

	local function pnpLoop()
		ctx.state.pnpV1Id = (ctx.state.pnpV1Id or 0) + 1
		local myId = ctx.state.pnpV1Id
		ctx.elevate()
		while alive(myId) do
			local pets = targetPets()
			if #pets == 0 then
				setStatus("PNP V1: tidak ada pet target (equip pet dulu)")
			else
				for _, p in ipairs(pets) do
					if not petThreads[p.uuid] then task.spawn(runPetThread, p.uuid, myId) end
				end
				setStatus(("PNP V1: %d pet (tunggu skill keluar)"):format(#pets))
			end
			task.wait(1)
		end
	end

	function ctx.startPnpV1() task.spawn(pnpLoop) end
	function ctx.stopPnpV1() ctx.state.pnpV1Id = (ctx.state.pnpV1Id or 0) + 1 end
end
