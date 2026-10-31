--[[ automation_pickup_pet_v1.lua ΓÇö PnP V1 (skill-trigger detection).
     Trick skip-animasi: tarik pet SETELAH skill mulai (efeknya tetap jalan walau pet ditarik),
     terus langsung place lagi -> cooldown mulai dari awal tanpa nunggu animasi.

     Pemicu "skill mulai" (dari log in-game):
       1. ZONE  : RemoteEvent PetZoneAbility(uuid, true, ...)  (Peacock, Lion, dst.)
       2. CD0   : cooldown salah satu passive (non-Mutation) nyentuh 0 dengan sendirinya
       3. (ADV dihapus ΓÇö cd yang di-advance tetap countdown ke 0 dulu, jadi ketangkep CD0)
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
	local CD0_MIN        = 0.8  -- (fallback) ancang-ancang abis cd 0 kalau sinyal animasi nggak kebaca
	-- Pet non-zone: tarik pas ANIMASI SKILL mulai (CustomAnimationState di ActivePetStates,
	-- mis. Dilo "Frill", Hotdog "Pee"), bukan pas cd 0. Dari log: cd 0 != skill mulai ΓÇö
	-- Dilo kadang baru ancang-ancang beberapa detik abis cd 0 -> narik pas cd0+0.8 = skill ilang.
	local ANIM_DELAY     = 1.2  -- (cadangan) tarik segini abis animasi skill kalau notif skill nggak datang
	-- Sinyal UTAMA non-zone: notifikasi skill pertama dari pet itu ("Rainbow Dilophosaurus spat
	-- venom...", "Rainbow Hotdog Daschund just dropped..."). Animasi Frill BELUM berarti skill
	-- jalan -> narik Frill+0.3 kadang cuma keluar 4 venom. Pandora narik ~0.4-0.9 s abis venom pertama.
	local NOTIF_DELAY    = 0.35 -- 0.8 kelamaan (Dilo keburu jalan sambil nyembur); Pandora tercepat ~0.39
	local NOTIF_NAME_POS = 25   -- nama pet harus di awal pesan (bukan "...to Rainbow Hotdog")
	local ANIM_WAIT      = 8    -- abis cd 0, tunggu animasi maksimal segini (lewat = batal, siklus berikutnya)
	local ANIM_CD_MAX    = 0    -- animasi dihitung skill cuma kalau cd passive non-zone udah 0
	                            -- (dulu <= 2: animasi reaksi pas cd 2 bikin Dilo ketarik "mangap doang")
	local ANIM_EARLY     = 1.0  -- animasi datang sebelum push cd 0 (Hotdog ~3 ms) -> masih dihitung kalau <= ini
	local ZONE_FALLBACK  = 2.0  -- pet zone: kalau event ZONE nggak datang segini setelah CD0, tetap tarik
	local ADV_DROP, ADV_LOW = nil, nil -- (trigger ADV dihapus)
	local PLACE_GRACE    = 1.5  -- abis place: sampel cd pertama yang 0 nggak dihitung CD0 (anti loop).
	                            -- ADV & ZONE tetap jalan (team loop bisa langsung advance pet baru di-place)
	local UNEQUIP_ACK    = 0.35 -- maks nunggu server konfirmasi unequip
	local VERIFY_WAIT    = 0.8  -- maks nunggu konfirmasi equip sebelum retry
	local EQUIP_RETRIES  = 3
	local MIN_POLL       = SCAN_INTERVAL

	local GameEvents          = RS:WaitForChild("GameEvents")

	-- DIAGNOSTIK: tiap keputusan PnP dicatat ke file pnp_debug.txt (workspace executor).
	local dbgLines, dbgT0, dbgDirty = {}, os.clock(), false
	local function dbg(fmt, ...)
		local ok, s = pcall(string.format, fmt, ...)
		dbgLines[#dbgLines + 1] = ("%8.3f  %s"):format(os.clock() - dbgT0, ok and s or fmt)
		if #dbgLines > 3000 then table.remove(dbgLines, 1) end
		dbgDirty = true
	end
	task.spawn(function()
		while ctx.alive() do
			if dbgDirty and writefile then
				dbgDirty = false
				pcall(writefile, "pnp_debug.txt", table.concat(dbgLines, "\n"))
			end
			task.wait(2)
		end
	end)
	local function short(u) return tostring(u):sub(2, 6) end
	local function cdStr(cur)
		if not cur then return "nil" end
		local p = {}
		for k, t in pairs(cur) do p[#p + 1] = ("%s=%g"):format(k:gsub("#%d+$", ""), t) end
		return table.concat(p, ",")
	end
	local GetPetCooldown      = GameEvents:WaitForChild("GetPetCooldown")
	local PetCooldownsUpdated = GameEvents:FindFirstChild("PetCooldownsUpdated")
	local PetZoneAbility      = GameEvents:FindFirstChild("PetZoneAbility")
	local DataStream          = GameEvents:FindFirstChild("DataStream")

	-- Kunci lintas-instance: kalau ada 2 hub hidup (re-execute tanpa rejoin), cuma 1 yang
	-- boleh narik pet yang sama -> nggak ada lagi unequip/equip dobel.
	local LOCK
	do
		local g = (getgenv and getgenv()) or _G
		g.__pnpLock = g.__pnpLock or {}
		LOCK = g.__pnpLock
	end

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
	local pendingKey = {} -- uuid -> passive key yang lagi ditunggu (CD0 non-zone)
	local CANCEL_MAX = 10 -- cd balik naik tapi <= ini = bacaan 0 tadi palsu (bukan reset skill)
	-- Cuma pet yang dipilih di dropdown PnP yang boleh dijadwalin. Dulu semua pet di kebun ikut
	-- dijadwalin -> pet non-target nyimpen jadwal basi & ngeblok sinyal berikutnya.
	local function isTgt(uuid)
		local sel = CFG.pnpUuids or {}
		return (not next(sel)) or sel[uuid] == true
	end
	local animOn     = {} -- uuid -> os.clock() animasi skill mulai (nil = nggak animasi)
	local animName   = {} -- uuid -> nama animasi terakhir
	local notifAt    = {} -- uuid -> os.clock() notif skill pertama siklus ini
	local waitAnim   = {} -- uuid -> deadline nunggu animasi abis cd 0
	local animSeen   = false -- pernah nerima state animasi (kalau nggak -> fallback CD0_MIN)
	local onAnim

	local lastPush = {} -- uuid -> os.clock() terakhir dapet push cd dari server
	local zeroAt   = {} -- uuid -> os.clock() terakhir passive non-zone kebaca 0

	-- "lagi nunggu skill": passive non-zone 0 sekarang ATAU baru aja (<1.5 s) kebaca 0.
	local function readyish(uuid, cur)
		cur = cur or prevCd[uuid]
		if cur then
			for key, t in pairs(cur) do
				if not key:find("Mutation") and not zonePassive[key:gsub("#%d+$", "")] and t <= 0 then
					return true
				end
			end
		end
		return zeroAt[uuid] ~= nil and os.clock() - zeroAt[uuid] < 1.5
	end

	local function onCd(uuid, cd, src)
		if type(cd) ~= "table" then return end
		local now = os.clock()
		if src == "push" then
			lastPush[uuid] = now
		elseif now - (lastPush[uuid] or 0) < 2.5 then
			-- Poll GetPetCooldown kadang ngasih angka BASI abis cd dipotong tim (push =5, poll =53
			-- di detik yang sama). Kalau push masih jalan, poll diabaikan biar nggak nimpa.
			return
		end
		if #cd == 0 then
			-- JANGAN hapus prevCd: server kadang kirim {kosong}/inf sesaat walau pet nggak
			-- dicabut -> sampel berikutnya dianggap "pertama" & 0 -> ketarik tanpa skill.
			lastEmpty[uuid] = now
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
		if hasInf then return end -- transisi unequip/equip
		lastValid[uuid] = now

		local prev = prevCd[uuid]
		prevCd[uuid] = cur
		if not isTgt(uuid) then fireAt[uuid], waitAnim[uuid], pendingKey[uuid] = nil, nil, nil; return end
		for key, t in pairs(cur) do
			if not key:find("Mutation") and not zonePassive[key:gsub("#%d+$", "")] then
				if t <= 0 then zeroAt[uuid] = now end
			end
		end
		if not CFG.pnpEnabled then return end

		-- Pickup CD0 yang lagi nunggu: verifikasi pakai sampel berikutnya.
		local pk = pendingKey[uuid]
		if notifAt[uuid] and not fireAt[uuid] and not busy[uuid] then
			-- siklus selesai tanpa ditarik -> reset biar notif siklus berikutnya kebaca
			local any0 = false
			for key, t in pairs(cur) do
				if not key:find("Mutation") and t <= 0 then any0 = true; break end
			end
			if not any0 then notifAt[uuid] = nil end
		end
		if pk and waitAnim[uuid] and not fireAt[uuid] then
			local t = cur[pk]
			if t and t > CANCEL_MAX then
				-- cd ke-reset tanpa animasi/notif kebaca = skill INSTAN (Apex Predator, Rascal, dll.)
				-- udah keluar. Dulu dibatalin -> pet nggak pernah ditarik. Sekarang langsung tarik.
				dbg("%s RESET tanpa anim/notif -> tarik sekarang (%s)", short(uuid), cdStr(cur))
				waitAnim[uuid], pendingKey[uuid] = nil, nil
				fireAt[uuid] = now
				fireReason[uuid] = "RESET"
			end
		end
		if pk and fireAt[uuid] and not busy[uuid] then
			local t = cur[pk]
			if t and t > CANCEL_MAX then
				fireAt[uuid] = now -- cd ke-reset = skill BARU keluar -> tarik sekarang
				fireReason[uuid] = "RESET"
				pendingKey[uuid] = nil
			elseif t and t > 0 then
				fireAt[uuid], pendingKey[uuid] = nil, nil -- 0 tadi glitch, batal
			end
		end

		local reason, isZone, rKey
		for key, t in pairs(cur) do
			if not key:find("Mutation") then
				local p = prev and prev[key]
				local r
				-- WAJIB transisi beneran (>0 -> 0). Sampel pertama yang udah 0 (pas baru
				-- nyalain / baru join) nggak dihitung: nggak tau kapan nyampe 0, dan sering
				-- skill-nya belum/nggak keluar -> dulu ketarik tanpa skill.
				if t <= 0 and p and p > 0 then
					r = "CD0"
				end
				if r then
					local z = zonePassive[key:gsub("#%d+$", "")] == true
					-- passive non-zone menang (langsung dijadwalkan); zone nunggu event
					if not reason or (isZone and not z) then reason, isZone, rKey = r, z, key end
				end
			end
		end
		if not reason then return end
		dbg("%s CD0 %s zone=%s src=%s prev=%s", short(uuid), tostring(rKey), tostring(isZone), tostring(src), cdStr(prev))
		if isZone then
			-- skill zone baru "keluar" pas event ZONE; tunggu itu (dengan fallback)
			if not fireAt[uuid] and not waitZone[uuid] then waitZone[uuid] = now + ZONE_FALLBACK end
		elseif animSeen then
			-- cd 0 BELUM berarti skill mulai. Tunggu animasi skill (onAnim). Kalau animasinya
			-- udah nyala duluan (kadang datang sebelum push cd 0), langsung jadwalin.
			if not fireAt[uuid] then
				if animOn[uuid] and now - animOn[uuid] <= ANIM_EARLY then
					fireAt[uuid] = math.max(now, animOn[uuid] + ANIM_DELAY)
					fireReason[uuid] = "ANIM"
				else
					waitAnim[uuid] = now + ANIM_WAIT
					pendingKey[uuid] = rKey
				end
			end
		else
			-- fallback: game belum pernah ngirim state animasi -> pakai jeda tetap abis cd 0
			if not fireAt[uuid] then pendingKey[uuid] = rKey end
			schedule(uuid, reason, false, CD0_MIN)
		end
	end

	-- Animasi skill (ancang-ancang) dari DataStream ActivePetsService_Replicator:
	--   {"ROOT/ActivePetStates/<player>/<uuid>/CustomAnimationState", "<nama anim>"}
	-- value nil/"" = animasi selesai.
	function onAnim(uuid, anim)
		local now = os.clock()
		if anim == nil or anim == "" then animOn[uuid], animName[uuid] = nil, nil; return end
		animSeen = true
		-- Event "selesai" ('') kadang nggak nyampe -> dulu animOn nyangkut & SEMUA animasi
		-- berikutnya diabaikan (Dilo ngeskill sampai kelar nggak ketarik). Sekarang: anggap
		-- animasi baru kalau namanya beda atau yang lama udah > 1.5 s.
		if animOn[uuid] and animName[uuid] == anim and now - animOn[uuid] < 1.5 then return end
		animOn[uuid], animName[uuid] = now, anim
		if not isTgt(uuid) then return end
		if not CFG.pnpEnabled or busy[uuid] or fireAt[uuid] then
			dbg("%s ANIM '%s' diabaikan (busy=%s fireAt=%s)", short(uuid), anim, tostring(busy[uuid]), tostring(fireAt[uuid] ~= nil))
			return
		end
		-- cuma dihitung skill kalau ada passive NON-zone yang cd-nya 0 (atau baru aja 0)
		if not readyish(uuid) then
			dbg("%s ANIM '%s' diabaikan: belum ready (%s)", short(uuid), anim, cdStr(prevCd[uuid]))
			return
		end
		dbg("%s ANIM '%s' -> tarik +%.2fs", short(uuid), anim, ANIM_DELAY)
		waitAnim[uuid], pendingKey[uuid] = nil, nil
		fireAt[uuid] = now + ANIM_DELAY
		fireReason[uuid] = "ANIM"
	end

	-- Notifikasi skill: pesan diawali nama pet (opsional prefix mutasi). Cuma pet target yang
	-- cd passive non-zone-nya 0 (lagi nunggu skill) & belum ada notif di siklus ini.
	local petTypeCache = {}
	local function petTypeOf(uuid)
		if petTypeCache[uuid] then return petTypeCache[uuid] end
		local ok, d = pcall(function() return DataService:GetData() end)
		local inv = ok and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data
		local pt = inv and inv[uuid] and inv[uuid].PetType
		if pt then petTypeCache[uuid] = tostring(pt) end
		return petTypeCache[uuid]
	end
	local function onNotif(msg)
		if type(msg) ~= "string" or not CFG.pnpEnabled then return end
		local low = msg:lower()
		local now = os.clock()
		for uuid, cur in pairs(prevCd) do
			local pt = isTgt(uuid) and petTypeOf(uuid)
			local pos = pt and low:find(pt:lower(), 1, true)
			if pos and pos <= NOTIF_NAME_POS then
				if busy[uuid] or notifAt[uuid] then
					-- venom lanjutan di siklus yang sama -> normal, diem aja
				elseif not readyish(uuid, cur) then
					dbg("%s NOTIF diabaikan: belum ready (%s) msg=%s", short(uuid), cdStr(cur), msg:sub(1, 50))
				else
					dbg("%s NOTIF -> tarik +%.2fs msg=%s", short(uuid), NOTIF_DELAY, msg:sub(1, 50))
					notifAt[uuid] = now
					waitAnim[uuid], pendingKey[uuid] = nil, nil
					fireAt[uuid] = now + NOTIF_DELAY -- override jadwal Frill: tunggu skill beneran jalan
					fireReason[uuid] = "NOTIF"
				end
			end
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
		for _, k in ipairs({ "__pnpV1CdConn", "__pnpV1ZoneConn", "__pnpV1AnimConn", "__pnpV1NotifConn" }) do
			if g[k] then pcall(function() g[k]:Disconnect() end) end
			g[k] = nil
		end
		local Notification = GameEvents:FindFirstChild("Notification")
		if Notification and Notification:IsA("RemoteEvent") then
			g.__pnpV1NotifConn = Notification.OnClientEvent:Connect(function(msg)
				pcall(onNotif, msg)
			end)
		end
		if DataStream then
			local prefix = "ROOT/ActivePetStates/" .. LP.Name .. "/"
			g.__pnpV1AnimConn = DataStream.OnClientEvent:Connect(function(kind, channel, list)
				if kind ~= "UpdateData" or channel ~= "ActivePetsService_Replicator" or type(list) ~= "table" then return end
				for _, e in ipairs(list) do
					local path = type(e) == "table" and e[1]
					if type(path) == "string" and path:sub(1, #prefix) == prefix then
						local uuid, field = path:sub(#prefix + 1):match("^([^/]+)/([^/]+)$")
						if uuid and field == "CustomAnimationState" then
							local v = e[2]
							pcall(onAnim, uuid, type(v) == "string" and v or nil)
						end
					end
				end
			end)
		end
		if PetCooldownsUpdated then
			g.__pnpV1CdConn = PetCooldownsUpdated.OnClientEvent:Connect(function(uuid, cdTable)
				if type(uuid) == "string" then onCd(uuid, cdTable, "push") end
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

	local HUB_TAG = {} -- identitas instance ini (buat kunci lintas-instance)
	local lastPlacedAt = {} -- uuid -> os.clock() terakhir di-place
	local doPnp

	-- return true kalau pet sukses balik ke kebun. Pet WAJIB dicoba balik walau PnP dimatiin.
	local function doPnpInner(uuid)
		local pos = placePos()
		fireAt[uuid], waitZone[uuid], pendingKey[uuid], waitAnim[uuid] = nil, nil, nil, nil
		notifAt[uuid] = nil
		if not pos then return true end
		-- Kunci lintas-instance: cuma nolak kalau yang lagi/baru narik itu INSTANCE LAIN.
		-- (Dulu nolak juga tarikan sendiri < 2.5 s -> pas cd dipotong tim & pet ready lagi
		--  cepet, tarikan di-skip diam-diam. Makin lama main = makin sering kejadian.)
		local lk = LOCK[uuid]
		if type(lk) ~= "table" then lk = nil end -- format lama (angka) dari versi sebelumnya
		if lk and lk.tag ~= HUB_TAG and os.clock() - lk.t < 2.5 then dbg("%s SKIP: dikunci hub lain", short(uuid)); return true end
		LOCK[uuid] = { t = os.clock(), tag = HUB_TAG }
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
		animOn[uuid], animName[uuid] = nil, nil -- animasi lama punya pet yang udah ditarik
		ignoreUntil[uuid] = os.clock() + PLACE_GRACE
		busy[uuid] = nil
		LOCK[uuid] = { t = os.clock(), tag = HUB_TAG }
		lastPlacedAt[uuid] = os.clock()
		return placed
	end

	-- Pembungkus: error di tengah pickup nggak boleh ninggalin busy nyangkut (pet nggak
	-- pernah ditarik lagi).
	function doPnp(uuid)
		local ok, res = pcall(doPnpInner, uuid)
		busy[uuid] = nil
		if not ok then
			if ctx.log then ctx.log("[PNP V1] error pickup: " .. tostring(res)) end
			return true
		end
		return res
	end

	local petThreads = {}
	local function runPetThread(uuid, myId)
		petThreads[uuid] = true
		-- jadwal basi dari sebelum thread ini hidup jangan langsung ditembak
		if fireAt[uuid] and os.clock() - fireAt[uuid] > 2 then fireAt[uuid] = nil end
		local lastPoll, polling, lastEqCheck, missing = 0, false, 0, 0
		while alive(myId) do
			-- pcall per putaran: dulu 1 error = thread mati TAPI petThreads[uuid] tetap true
			-- -> pet itu nggak pernah di-handle lagi sampai re-execute (makin lama makin parah).
			local okTick, stop = pcall(function()
				local now = os.clock()
				if now - lastEqCheck > 0.5 then
					lastEqCheck = now
					if not isTarget(uuid) then return true end
					-- DataService suka telat abis place: keluar cuma kalau 3x berturut-turut
					-- nggak ke-equip, nggak lagi ada tarikan nunggu, & udah > 3 s abis place.
					if equippedSet()[uuid] then
						missing = 0
					elseif not fireAt[uuid] and not busy[uuid]
						and now - (lastPlacedAt[uuid] or 0) > 3 then
						missing = missing + 1
						if missing >= 3 then return true end
					end
				end

				if waitZone[uuid] and now >= waitZone[uuid] then
					waitZone[uuid] = nil
					schedule(uuid, "CD0")
				end
				if waitAnim[uuid] and now >= waitAnim[uuid] then
					-- belum ada sinyal: TETAP nunggu (pet bisa nahan cd 0 lama nunggu target).
					-- Begitu cd reset / animasi / notif datang, ditarik. Dulu dibatalin -> miss.
					waitAnim[uuid] = now + ANIM_WAIT
				end

				if fireAt[uuid] and now >= fireAt[uuid] then
					local why = fireReason[uuid] or "?"
					dbg("%s TARIK alasan=%s (%s)", short(uuid), why, cdStr(prevCd[uuid]))
					if ctx.log then
						ctx.log(("[PNP V1] tarik #%s alasan=%s anim=%s"):format(uuid:sub(2, 5), why,
							animOn[uuid] and ("%.2fs"):format(now - animOn[uuid]) or "-"))
					end
					if doPnp(uuid) then
						setStatus(("PNP V1: #%s ditarik (%s)"):format(uuid:sub(2, 5), why))
					else
						setStatus("PNP V1: gagal place ulang pet #" .. uuid:sub(2, 5) .. " (cek backpack)")
					end
					lastEqCheck, missing = os.clock(), 0
				elseif not polling and now - lastPoll >= SCAN_INTERVAL then
					lastPoll, polling = now, true
					task.spawn(function() pcall(pollCd, uuid); polling = false end)
				end
			end)
			if not okTick and ctx.log then ctx.log("[PNP V1] error loop: " .. tostring(stop)) end
			if okTick and stop then break end
			task.wait(0.03)
		end
		fireAt[uuid], waitZone[uuid], prevCd[uuid], pendingKey[uuid] = nil, nil, nil, nil
		waitAnim[uuid] = nil
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
