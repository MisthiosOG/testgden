--[[ automation_pickup_pet_v1.lua — PnP V1 (skill-trigger detection).
     Trick skip-animasi: tarik pet SETELAH skill mulai (efeknya tetap jalan walau pet ditarik),
     terus langsung place lagi -> cooldown mulai dari awal tanpa nunggu animasi.

     Pemicu "skill mulai" (dari log in-game):
       1. ZONE  : RemoteEvent PetZoneAbility(uuid, true, ...)  (Peacock, Lion, dst.)
       2. CD0   : cooldown salah satu passive (non-Mutation) nyentuh 0 dengan sendirinya
       3. (ADV dihapus — cd yang di-advance tetap countdown ke 0 dulu, jadi ketangkep CD0)
     Pet zone: CD0 nunggu event ZONE (fallback kalau event nggak datang), terus +PICKUP_DELAY.
     Pet non-zone: CD0 + CD0_MIN (ancang-ancang 0.8 s).
     Setelah pemicu: tunggu PICKUP_DELAY -> Unequip -> tunggu server ack -> Equip -> verifikasi.

     Timing dikunci di konstanta (PICKUP_DELAY 0.5 / EQUIP_DELAY 1E-20 / SCAN_INTERVAL 0.20).
     Config: pnpUuids, pnpEnabled.
     Fungsi: ctx.startPnpV1 / ctx.stopPnpV1 / ctx.forcePickupPets. Expose ctx.inventoryPetOptions (V1 & V2). ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local PetsService = ctx.deps.PetsService
	local CFG         = ctx.CFG
	local function setStatus(s) ctx.setStatus(s) end

	local RS = game:GetService("ReplicatedStorage")
	local LP = ctx.LP

	local cdMap = ctx.state.cdMap or {}
	ctx.state.cdMap = cdMap

	-- Timing DIKUNCI (hasil tes in-game, nggak dibaca dari CFG / UI lagi)
	local PICKUP_DELAY   = 0.5   -- jeda setelah skill mulai sebelum pet ditarik
	local EQUIP_DELAY    = 1e-20 -- jeda tambahan unequip -> equip setelah server ack (praktis 0)
	local SCAN_INTERVAL  = 0.20  -- polling cd cadangan (sinyal utama = push server)
	local CD0_MIN        = 0.8  -- ancang-ancang abis cd 0 (Pandora narik Dilo/Hotdog ~0.6-1.3 s abis cd 0)
	local ZONE_FALLBACK  = 2.0  -- pet zone: kalau event ZONE nggak datang segini setelah CD0, tetap tarik
	local ADV_DROP, ADV_LOW = nil, nil -- (trigger ADV dihapus)
	local PLACE_GRACE    = 1.5  -- abis place: sampel cd pertama yang 0 nggak dihitung CD0 (anti loop).
	                            -- ADV & ZONE tetap jalan (team loop bisa langsung advance pet baru di-place)
	local UNEQUIP_ACK    = 0.35 -- maks nunggu server konfirmasi unequip
	local VERIFY_WAIT    = 0.8  -- maks nunggu konfirmasi equip sebelum retry
	local EQUIP_RETRIES  = 3
	local MIN_POLL       = SCAN_INTERVAL

	local GameEvents          = RS:WaitForChild("GameEvents")
	local GetPetCooldown      = GameEvents:WaitForChild("GetPetCooldown")
	local PetCooldownsUpdated = GameEvents:FindFirstChild("PetCooldownsUpdated")
	local PetZoneAbility      = GameEvents:FindFirstChild("PetZoneAbility")

	-------------------------------------------------------------- state per pet
	local prevCd      = {} -- uuid -> { [passiveKey] = time }
	local fireAt      = {} -- uuid -> os.clock() kapan pickup
	local fireReason  = {} -- uuid -> "ZONE"/"CD0"/"ADV"/"FORCE"
	local waitZone    = {} -- uuid -> deadline fallback buat pet zone
	-- Passive yang skill-nya zone (keluar pas event PetZoneAbility, ~0.4-1 s SETELAH cd 0).
	-- Dipelajari otomatis dari event & disimpan di getgenv biar awet antar reload.
	local zonePassive
	do
		local g = (getgenv and getgenv()) or _G
		g.__pnpZonePassive = g.__pnpZonePassive or { ["Lion Call"] = true, ["Utter Beauty"] = true }
		zonePassive = g.__pnpZonePassive
	end
	local busy        = {} -- uuid -> true selama pickup/place
	local ignoreUntil = {} -- uuid -> os.clock()
	local lastEmpty   = {} -- uuid -> os.clock() terakhir cd kosong (server: pet ke-unequip)
	local lastValid   = {} -- uuid -> os.clock() terakhir cd valid (server: pet ada di kebun)

	local function commitDelay()
		return PICKUP_DELAY
	end

	local function schedule(uuid, reason, override, minDelay)
		if busy[uuid] then return end
		if fireAt[uuid] and not override then return end
		fireAt[uuid] = os.clock() + math.max(commitDelay(), minDelay or 0)
		fireReason[uuid] = reason
	end

	-------------------------------------------------------------- sumber sinyal
	local function onCd(uuid, cd)
		if type(cd) ~= "table" then return end
		local now = os.clock()
		if #cd == 0 then
			lastEmpty[uuid] = now
			prevCd[uuid] = nil
			return
		end
		local cur, data, seen, hasInf = {}, {}, {}, false
		for _, e in ipairs(cd) do
			local name = tostring(e.Passive or "?")
			local t = tonumber(e.Time) or 0
			if t == math.huge then hasInf = true end
			data[#data + 1] = { Passive = e.Passive, Time = t }
			seen[name] = (seen[name] or 0) + 1
			cur[name .. "#" .. seen[name]] = t
		end
		cdMap[uuid] = { data = data }
		if hasInf then prevCd[uuid] = nil; return end -- transisi unequip/equip
		lastValid[uuid] = now

		local prev = prevCd[uuid]
		prevCd[uuid] = cur
		if not CFG.pnpEnabled then return end

		local reason, isZone
		for key, t in pairs(cur) do
			if not key:find("Mutation") then
				local p = prev and prev[key]
				local r
				-- p == nil = sampel pertama. Abis place jangan langsung dianggap CD0 (anti loop
				-- kalau ada passive yang memang nyangkut di 0).
				if t <= 0 and ((p == nil and now >= (ignoreUntil[uuid] or 0)) or (p and p > 0)) then
					r = "CD0"
				end
				-- (Trigger ADV dihapus: dari log, cd yang di-advance ke ~4-5 TETAP countdown ke 0
				--  dulu baru skill keluar. Narik pas ADV = narik sebelum skill -> skill hilang.)
				if r then
					local z = zonePassive[key:gsub("#%d+$", "")] == true
					-- passive non-zone menang (langsung dijadwalkan); zone nunggu event
					if not reason or (isZone and not z) then reason, isZone = r, z end
				end
			end
		end
		if not reason then return end
		if isZone then
			-- skill zone baru "keluar" pas event ZONE; tunggu itu (dengan fallback)
			if not fireAt[uuid] and not waitZone[uuid] then waitZone[uuid] = now + ZONE_FALLBACK end
		else
			-- CD0 natural: skill butuh ~0.8 s buat "nempel" sebelum aman ditarik (ancang-ancang)
			schedule(uuid, reason, false, CD0_MIN)
		end
	end

	local function onZone(a1, active, _, model, passiveName)
		local uuid = (type(a1) == "string" and a1:sub(1, 1) == "{") and a1
			or (typeof(model) == "Instance" and model.Name) or nil
		if not uuid then return end
		if type(passiveName) == "string" then zonePassive[passiveName] = true end
		if active ~= true or not CFG.pnpEnabled then return end
		waitZone[uuid] = nil
		schedule(uuid, "ZONE", true) -- hitung jeda dari event ZONE (lebih akurat dari CD0)
	end

	do
		local g = (getgenv and getgenv()) or _G
		for _, k in ipairs({ "__pnpV1CdConn", "__pnpV1ZoneConn" }) do
			if g[k] then pcall(function() g[k]:Disconnect() end) end
			g[k] = nil
		end
		if PetCooldownsUpdated then
			g.__pnpV1CdConn = PetCooldownsUpdated.OnClientEvent:Connect(function(uuid, cdTable)
				if type(uuid) == "string" then onCd(uuid, cdTable) end
			end)
		end
		if PetZoneAbility then
			g.__pnpV1ZoneConn = PetZoneAbility.OnClientEvent:Connect(onZone)
		end
	end

	local function pollCd(uuid)
		local ok, cd = pcall(function() return GetPetCooldown:InvokeServer(uuid) end)
		if ok then onCd(uuid, cd) end
	end

	-------------------------------------------------------------- data helpers
	local function getData()
		local ok, d = pcall(function() return DataService:GetData() end)
		return ok and d or nil
	end

	local function equippedSet()
		local d = getData()
		local set = {}
		local eq = d and d.PetsData and d.PetsData.EquippedPets
		if eq then for _, u in ipairs(eq) do set[u] = true end end
		return set
	end

	local function isTarget(uuid)
		local sel = CFG.pnpUuids or {}
		return (not next(sel)) or sel[uuid] == true
	end

	local function targetPets()
		local out = {}
		local d = getData()
		local eq = d and d.PetsData and d.PetsData.EquippedPets
		if not eq then return out end
		local inv = d.PetsData.PetInventory and d.PetsData.PetInventory.Data
		for _, uuid in ipairs(eq) do
			if isTarget(uuid) then
				out[#out + 1] = { uuid = uuid, petType = inv and inv[uuid] and inv[uuid].PetType }
			end
		end
		return out
	end

	-- daftar pet dari INVENTORY buat dropdown Select Pets (SHARED: dipakai V1 & V2).
	function ctx.inventoryPetOptions(selectedSet)
		local out = {}
		local d = getData()
		if not d then return out end
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

	-- return true kalau pet sukses balik ke kebun. Pet WAJIB dicoba balik walau PnP dimatiin.
	local function doPnp(uuid)
		local pos = placePos()
		fireAt[uuid], waitZone[uuid] = nil, nil
		if not pos then return true end
		busy[uuid] = true

		local tU = os.clock()
		pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
		repeat task.wait(0.02) until (lastEmpty[uuid] or 0) >= tU or os.clock() - tU > UNEQUIP_ACK
		if EQUIP_DELAY > 0.001 then task.wait(EQUIP_DELAY) end

		local placed = false
		for _ = 1, EQUIP_RETRIES do
			local tE = os.clock()
			pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
			repeat task.wait(0.05) until (lastValid[uuid] or 0) > tE or os.clock() - tE > VERIFY_WAIT
			if (lastValid[uuid] or 0) > tE or equippedSet()[uuid] then placed = true; break end
		end

		prevCd[uuid] = nil
		ignoreUntil[uuid] = os.clock() + PLACE_GRACE
		busy[uuid] = nil
		return placed
	end

	local petThreads = {}
	local function runPetThread(uuid, myId)
		petThreads[uuid] = true
		local lastPoll, polling, lastEqCheck = 0, false, 0
		while alive(myId) do
			local now = os.clock()
			if now - lastEqCheck > 0.5 then
				lastEqCheck = now
				if not isTarget(uuid) or not equippedSet()[uuid] then break end
			end

			if waitZone[uuid] and now >= waitZone[uuid] then
				waitZone[uuid] = nil
				schedule(uuid, "CD0")
			end

			if fireAt[uuid] and now >= fireAt[uuid] then
				local why = fireReason[uuid] or "?"
				if doPnp(uuid) then
					setStatus(("PNP V1: #%s ditarik (%s)"):format(uuid:sub(2, 5), why))
				else
					setStatus("PNP V1: gagal place ulang pet #" .. uuid:sub(2, 5) .. " (cek backpack)")
					break
				end
				lastEqCheck = os.clock() -- DataService telat update abis place
			elseif not polling and now - lastPoll >= SCAN_INTERVAL then
				lastPoll, polling = now, true
				task.spawn(function() pollCd(uuid); polling = false end)
			end
			task.wait(0.03)
		end
		fireAt[uuid], waitZone[uuid], prevCd[uuid] = nil, nil, nil
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
			end
			task.wait(1)
		end
	end

	function ctx.startPnpV1() task.spawn(pnpLoop) end
	function ctx.stopPnpV1() ctx.state.pnpV1Id = (ctx.state.pnpV1Id or 0) + 1 end

	-- Tombol "Force Pickup Now": tarik + place ulang semua pet target sekarang (abaikan cd).
	function ctx.forcePickupPets()
		local pets = targetPets()
		for _, p in ipairs(pets) do
			if not busy[p.uuid] then task.spawn(doPnp, p.uuid) end
		end
		return #pets
	end
end
