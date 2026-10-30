--[[ hatch.lua — Auto Hatch + Auto Sell (Stage 1).
     - Team-swap dengan GUARD: team ga diproses kalau yg ke-equip udah sesuai.
     - Auto Hatch: equip hatch team -> hatch semua egg READY -> hitung cycle.
     - Auto Sell: pet yg COCOK filter dijual; sisanya DIFAVORITIN biar aman.
       Favorite via Favorite_Item (toggle), jual via SellPet_RE / SellAllPets_RE.
     Catatan: auto-place egg baru & bronto phase = stage berikutnya. ]]
return function(ctx)
	local RS = game:GetService("ReplicatedStorage")
	local LP = ctx.LP
	local CFG = ctx.CFG
	local DataService = ctx.deps.DataService
	local PetsRemote = RS.GameEvents.PetsService
	local FavoriteRemote = RS.GameEvents:FindFirstChild("Favorite_Item")
	local SellPet = RS.GameEvents:FindFirstChild("SellPet_RE")
	local SellAll = RS.GameEvents:FindFirstChild("SellAllPets_RE")
	local EggRemote = RS.GameEvents.PetEggService
	local FAV_KEY = "d"
	pcall(function() FAV_KEY = require(RS.Data.EnumRegistry.InventoryServiceEnums).Favorite end)

	-- LISTEN notif game = recovery ASLI (1 notif = 1 egg balik). Sumber paling akurat.
	--   Hatch: "Lucky Hatch! Your egg has been recovered."
	--   Sell : "Lucky Pet! You got a ... egg back from selling your pet!"
	do
		local g = (getgenv and getgenv()) or _G
		if g.__hatchNotifConn then pcall(function() g.__hatchNotifConn:Disconnect() end) end
		local NotifRemote = RS.GameEvents:FindFirstChild("Notification")
		if NotifRemote then
			g.__hatchNotifConn = NotifRemote.OnClientEvent:Connect(function(msg)
				if type(msg) ~= "string" or not CFG.hatchEnabled then return end
				local l = msg:lower()
				if l:find("egg has been recovered") then
					ctx.state.periodHatchRec = (ctx.state.periodHatchRec or 0) + 1
				elseif l:find("egg back from selling") then
					ctx.state.periodSellRec = (ctx.state.periodSellRec or 0) + 1
				end
			end)
		end
	end

	----------------------------------------------------------------- util
	local function getData() local ok, d = pcall(function() return DataService:GetData() end); return ok and d or nil end
	local function inventory() local d = getData(); return d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {} end
	local function equippedList() local d = getData(); return d and d.PetsData and d.PetsData.EquippedPets or {} end

	local function farmCenter()
		local GetFarm = require(RS.Modules.GetFarm)
		local farm = GetFarm and GetFarm(LP)
		local pa = farm and farm:FindFirstChild("PetArea")
		if pa then return pa.Position end
		local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
		return hrp and hrp.Position or nil
	end
	local slotOf, nextSlot = {}, 0
	local function getPos(uuid)
		if not slotOf[uuid] then slotOf[uuid] = nextSlot; nextSlot = nextSlot + 1 end
		local c = farmCenter(); if not c then return nil end
		local i = slotOf[uuid]
		return c + Vector3.new((i % 6 - 2.5) * 3, 0, (math.floor(i / 6) - 1) * 3)
	end

	----------------------------------------------------------------- TEAM + GUARD
	-- ActivePetsService: sumber pet yg beneran AKTIF (model spawn + passive kebaca).
	local ActivePets; pcall(function() ActivePets = require(RS.Modules.PetServices.ActivePetsService) end)
	-- teamSet = { [uuid]=true }. Return true kalau equipped PERSIS == teamSet.
	local function teamMatches(teamSet)
		if not next(teamSet or {}) then return true end -- team kosong = ga usah proses
		local eq = equippedList()
		local eqSet, eqN = {}, 0
		for _, u in ipairs(eq) do eqSet[u] = true; eqN = eqN + 1 end
		local tN = 0
		for u in pairs(teamSet) do if not eqSet[u] then return false end; tN = tN + 1 end
		return eqN == tN
	end
	-- Semua anggota team udah AKTIF di garden (ClientPetState) -> passive-nya kebaca.
	local function teamActive(teamSet)
		if not next(teamSet or {}) then return true end
		if not ActivePets or not ActivePets.ClientPetState then return true end -- ga bisa cek -> anggap ok
		local cps = ActivePets.ClientPetState[LP.Name]
		if not cps then return false end
		for u in pairs(teamSet) do if cps[u] == nil then return false end end
		return true
	end

	-- Posisi rapi per team: grid kecil di tengah PetArea, urutan tetap (uuid di-sort),
	-- jadi tiap team selalu kepasang di pola yang sama. (Dulu slot naik terus tiap pet
	-- baru -> lama-lama pet ditaruh makin jauh / berantakan.)
	local TEAM_COLS, TEAM_SP = 4, 3
	local function teamPositions(teamSet)
		local c = farmCenter(); if not c then return {} end
		local list = {}
		for u in pairs(teamSet) do list[#list + 1] = u end
		table.sort(list)
		local n = #list
		local cols = math.min(TEAM_COLS, math.max(1, n))
		local rows = math.ceil(n / cols)
		local out = {}
		for i, u in ipairs(list) do
			local col = (i - 1) % cols
			local row = math.floor((i - 1) / cols)
			out[u] = c + Vector3.new((col - (cols - 1) / 2) * TEAM_SP, 0, (row - (rows - 1) / 2) * TEAM_SP)
		end
		return out
	end

	-- 1 pass, 2 tahap:
	--  A) cabut SEMUA pet yang bukan anggota team, terus TUNGGU sampai beneran kosong
	--     (data server). Dulu cuma jeda 0.15 s -> equip team baru kena "max pets in garden".
	--  B) baru pasang anggota team yang belum ke-equip, posisi grid rapi.
	local function equipTeamOnce(teamSet, unequipDelay, equipDelay, label)
		local unDelay = tonumber(unequipDelay) or 0.1
		local eqDelay = tonumber(equipDelay) or 0.15

		local function leftovers()
			local out = {}
			for _, u in ipairs(equippedList()) do if not teamSet[u] then out[#out + 1] = u end end
			return out
		end

		local rest = leftovers()
		if #rest > 0 then
			ctx.state.hatchStatus = (label or "Team") .. ": clearing garden..."
			for _, u in ipairs(rest) do
				pcall(function() PetsRemote:FireServer("UnequipPet", u) end)
				if unDelay > 0 then task.wait(unDelay) end
			end
			local t0 = os.clock()
			repeat task.wait(0.1); rest = leftovers() until #rest == 0 or os.clock() - t0 > 4
			if #rest > 0 then return end -- belum bersih -> jangan equip, pass berikutnya coba lagi
		end

		local eqNow = {}
		for _, u in ipairs(equippedList()) do eqNow[u] = true end
		local pos = teamPositions(teamSet)
		for u in pairs(teamSet) do
			if not eqNow[u] and pos[u] then
				pcall(function() PetsRemote:FireServer("EquipPet", u, CFrame.new(pos[u])) end)
				if eqDelay > 0 then task.wait(eqDelay) end
			end
		end
	end

	-- Equip team: BLOK sampai team LENGKAP ter-equip (data). Boost/passive (bronto/koi/seal)
	-- diterapin server-side pas pet KE-EQUIP, BUKAN pas model kerender di client. ClientPetState
	-- (spawn model) cuma dipake sbg sinyal cepat kalau kebaca — tapi di LOW PERFORMANCE MODE
	-- model pet sering ga spawn, jadi JANGAN jadiin gate. Kalau ga kebaca aktif, tetap lanjut
	-- setelah settle delay (team udah ke-equip = boost udah masuk server).
	local function equipTeam(teamSet, label, unequipDelay, equipDelay)
		if not next(teamSet or {}) then return true end
		if teamMatches(teamSet) and teamActive(teamSet) then return true end -- fast path
		ctx.state.teamSwapActive = true
		ctx.state.hatchStatus = (label or "Team") .. ": equipping..."
		-- 1) pasang sampai data-equipped lengkap
		local ok = false
		for _ = 1, 8 do
			if teamMatches(teamSet) then ok = true; break end
			equipTeamOnce(teamSet, unequipDelay, equipDelay, label)
			ctx.state.hatchStatus = (label or "Team") .. ": equipping..."
			-- tunggu data equip nyusul sebelum pass berikutnya (anti equip dobel)
			local t0 = os.clock()
			repeat task.wait(0.15) until teamMatches(teamSet) or os.clock() - t0 > 1.5
		end
		if not ok then
			ctx.state.teamSwapActive = false
			return false
		end
		-- 2) best-effort tunggu pet aktif (model spawn) — poll max ~4s. Begitu kebaca, lanjut.
		for _ = 1, 20 do
			if teamActive(teamSet) then
				ctx.state.teamSwapActive = false
				return true
			end
			ctx.state.hatchStatus = (label or "Team") .. ": nunggu pet aktif..."
			task.wait(0.2)
		end
		-- 3) ga kebaca aktif (kemungkinan low-perf, model ga spawn) TAPI udah ke-equip di data.
		--    Boost server tetap kepasang -> LANJUT (jgn skip). Settle bentar buat jaga2.
		ctx.state.hatchStatus = (label or "Team") .. ": ke-equip (settle)..."
		task.wait(1.5)
		ctx.state.teamSwapActive = false
		return true
	end

	----------------------------------------------------------------- FAVORITE / SELL
	local function petTools()
		local out = {}
		local bp = LP:FindFirstChildOfClass("Backpack")
		for _, src in ipairs({ bp, LP.Character }) do
			if src then for _, t in ipairs(src:GetChildren()) do
				if t:IsA("Tool") and t:GetAttribute("PET_UUID") then out[#out + 1] = t end
			end end
		end
		return out
	end
	local function isFav(tool) return tool:GetAttribute(FAV_KEY) == true end
	local function setFav(tool, want)
		if isFav(tool) ~= want and FavoriteRemote then
			pcall(function() FavoriteRemote:FireServer(tool) end); task.wait(0.06)
		end
	end

	-- filter disimpan pakai label "Pet - Egg"; cocokin pakai label yg sama.
	local petEggLabel = (ctx.reg and ctx.reg.petEggLabel) or (ctx.petEggLabel) or function(p) return p end
	local petBaseName = (ctx.reg and ctx.reg.petBaseName) or (ctx.petBaseName) or function(p) return tostring(p):match("^(.-)%s*-%s*") or tostring(p) end

	-- Helper pencocokan pet ke Sell & Bronto Config list
	local function findRule(petType, petData)
		if not CFG.hatchSellList or not next(CFG.hatchSellList) or not petType then return nil end
		-- 1. Direct match
		if CFG.hatchSellList[petType] then return CFG.hatchSellList[petType] end
		-- 2. Combo match (Pet - Egg) via petData / registry
		local base = petBaseName(petType)
		local rawName = (base ~= "" and base ~= petType) and base or petType
		local egg = (petData and petData.HatchedFrom) or (ctx.reg and ctx.reg.petEggMap and (ctx.reg.petEggMap[rawName] or ctx.reg.petEggMap[petType]))
		if egg then
			local combo = rawName .. " - " .. egg
			if CFG.hatchSellList[combo] then return CFG.hatchSellList[combo] end
		end
		-- 3. Label match
		local key = petEggLabel(petType)
		if CFG.hatchSellList[key] then return CFG.hatchSellList[key] end
		-- 4. Case-insensitive / base name match
		local ptLower = rawName:lower()
		local keyLower = tostring(key or ""):lower()
		for name, r in pairs(CFG.hatchSellList) do
			local nLower = tostring(name):lower()
			local bLower = petBaseName(name):lower()
			if nLower == ptLower or nLower == keyLower or bLower == ptLower then
				return r
			end
		end
		return nil
	end

	-- apakah pet ini termasuk yg DIJUAL (cocok filter)?
	-- PENTING: pakai berat TAMPIL (BaseWeight*(1+0.1*Level)) = yg keliatan di game/dropdown,
	-- BUKAN BaseWeight mentah (beda angka -> salah keep/favorite). Weight & Age = AND
	-- (harus dua-duanya kepenuhi; 0 = filter itu dimatiin).
	local function shouldSell(petType, pd)
		pd = pd or {}
		local age = pd.Level or 0
		local w = (pd.BaseWeight or 0) * (1 + 0.1 * age)
		local key = petEggLabel(petType)

		-- Prioritas 1: Sell & Bronto Config List terpadu (Bulk / per-pet setting)
		local rule = findRule(petType, pd)
		if rule then
			if rule.special == true then
				return false -- Special pet (bintang aktif) mutlak disimpan (KEEP)
			end
			local targetKg = tonumber(rule.kg) or 0
			if w >= targetKg then
				return false -- Weight >= KG -> KEEP (pet aman, tetap disimpan, dan masuk ke proses Bronto)
			else
				-- Weight < KG -> mengikuti pengaturan tombol KEEP / SELL
				return rule.action == "SELL"
			end
		elseif CFG.hatchSellList and next(CFG.hatchSellList) then
			-- Pet tidak ada di list config -> KEEP (aman)
			return false
		end

		-- Fallback: config lama (Pets to Sell & Special Pets to Sell)
		if (CFG.sellPetTypes or {})[key] then
			local wt = CFG.sellWeightThreshold or 0
			local at = CFG.sellAgeThreshold or 0
			local wOk = wt <= 0 or w < wt
			local aOk = at <= 0 or age < at
			if (wt > 0 or at > 0) and wOk and aOk then return true end
		end
		if (CFG.sellSpecialTypes or {})[key] then
			local sw = CFG.sellSpecialWeight or 0
			if sw > 0 and w < sw then return true end
		end
		return false
	end

	-- Jalankan sell: pet yg keep -> favorit; pet yg dijual -> unfavorit lalu jual.
	local function doSell()
		-- GUARD: filter kosong -> batalin (biar ga ada kecelakaan)
		if not next(CFG.hatchSellList or {}) and not next(CFG.sellPetTypes or {}) and not next(CFG.sellSpecialTypes or {}) then
			ctx.state.hatchStatus = "Sell dibatalin: filter 'Pets to Sell' kosong"
			return 0
		end
		local inv = inventory()
		local keeps, sells = {}, {}
		for _, t in ipairs(petTools()) do
			local uuid = t:GetAttribute("PET_UUID")
			local v = inv[uuid]
			local pt = (v and v.PetType) or t:GetAttribute("f")
			local pd = v and v.PetData
			if isFav(t) then
				keeps[#keeps + 1] = t              -- udah favorit = MUTLAK ga dijual (walau filter cocok)
			elseif shouldSell(pt, pd) then
				sells[#sells + 1] = t
			else
				keeps[#keeps + 1] = t
			end
		end

		if CFG.sellStyle == "All at Once" then
			-- proteksi: favoritin semua keep, unfavorit yg mau dijual
			ctx.state.hatchStatus = "Selling: favorit proteksi..."
			for _, t in ipairs(keeps) do setFav(t, true) end
			for _, t in ipairs(sells) do setFav(t, false) end
			-- VERIFY: tunggu sync + cek SEMUA keep bener favorit; retry; abort kalau gagal.
			local safe = false
			for _ = 1, 4 do
				task.wait(0.5)
				local bad = {}
				for _, t in ipairs(keeps) do if t.Parent and not isFav(t) then bad[#bad + 1] = t end end
				if #bad == 0 then safe = true; break end
				ctx.state.hatchStatus = ("Verify: %d keep-pet belum favorit, retry..."):format(#bad)
				for _, t in ipairs(bad) do setFav(t, true) end
			end
			if not safe then
				ctx.state.hatchStatus = "Sell DIBATALIN: ada keep-pet belum favorit (aman, ga jadi jual)"
				return 0
			end
			if SellAll then pcall(function() SellAll:FireServer() end) end
			ctx.state.hatchSellCycles = (ctx.state.hatchSellCycles or 0) + 1
			ctx.state.hatchStatus = ("Sold all-at-once (%d matched)"):format(#sells)
			return #sells
		else
			-- One by One: cuma jual yg cocok filter, targeted (aman by design)
			ctx.state.hatchStatus = "Selling one-by-one..."
			for _, t in ipairs(sells) do
				if t.Parent then
					setFav(t, false)
					if SellPet then pcall(function() SellPet:FireServer(t, true) end) end
					task.wait(0.1)
				end
			end
			ctx.state.hatchSellCycles = (ctx.state.hatchSellCycles or 0) + 1
			ctx.state.hatchStatus = ("Sold %d pet (one by one)"):format(#sells)
			return #sells
		end
	end
	ctx.hatchDoSell = doSell -- expose buat tombol manual

	----------------------------------------------------------------- HATCH
	-- Egg ready = timer habis (TimeToHatch <= 0). Egg yg timer-nya jalan = belum ready.
	-- eggMode = fwd decl, dibind abis eggPending (predicate "egg sesuai config").
	local eggMode
	local function readyEggs()
		local GetFarm = require(RS.Modules.GetFarm); local farm = GetFarm(LP)
		local t = {}
		if farm then for _, e in ipairs(farm:GetDescendants()) do
			if e:IsA("Model") and e.Name == "PetEgg" and e:GetAttribute("OWNER") == LP.Name then
				local tth = tonumber(e:GetAttribute("TimeToHatch")) or 0
				-- HANYA egg sesuai pilihan yang boleh di-hatch — egg tipe lain
				-- (sisa config lama, mis. Paradise saat pilih Common) dibiarkan.
				if tth <= 0 and (not eggMode or eggMode(e)) then t[#t + 1] = e end
			end
		end end
		return t
	end
	local function backpackPetCount()
		local n = 0
		for _, t in ipairs(petTools()) do local _ = t; n = n + 1 end
		return n
	end
	local function getInventoryCapacity()
		local d = getData()
		local maxCap = d and d.PetsData and d.PetsData.MutableStats and tonumber(d.PetsData.MutableStats.MaxPetsInInventory) or 0
		local bpc = backpackPetCount()
		local inv = inventory()
		local invCount = 0
		for _ in pairs(inv) do invCount = invCount + 1 end
		local cur = math.max(bpc, invCount)
		return cur, maxCap
	end

	-- Parse nama tool egg & jumlahnya (mendukung angka positif dan minus misal "Paradise Egg x-20", "Paradise Egg -20", "x -20", "[x-20]", dll)
	local function parseEggTool(t)
		if not (t and t:IsA("Tool") and not t:GetAttribute("PET_UUID")) then
			return nil, 0
		end
		local raw = tostring(t.Name)
		local rawLower = raw:lower()
		local targetEgg = CFG.hatchEggName
		local hasEgg = rawLower:find("egg", 1, true) or (targetEgg and rawLower:find(targetEgg:lower(), 1, true))
		if not hasEgg then
			return nil, 0
		end

		-- Normalize unicode dashes/minuses ke ASCII "-"
		-- \226\128\147 = en-dash (–), \226\128\148 = em-dash (—), \226\136\146 = minus sign (−)
		local norm = raw:gsub("[\226\128\147\226\128\148\226\136\146]", "-")

		-- Cek attribute / child Value jika ada
		local attrVal = t:GetAttribute("Quantity") or t:GetAttribute("Count") or t:GetAttribute("Amount")
		if not attrVal then
			local qChild = t:FindFirstChild("Quantity") or t:FindFirstChild("Count") or t:FindFirstChild("Amount")
			if qChild and (qChild:IsA("IntValue") or qChild:IsA("NumberValue")) then
				attrVal = qChild.Value
			end
		end

		-- Ekstraksi base & count dari string
		-- Format 1: "Egg Name x-20", "Egg Name x -20", "Egg Name [X-20]", "Egg Name (x - 20)"
		local base, cnt = norm:match("^(.-)%s*[%[%(]?%s*[xX]%s*([%-+]?%s*%d+)%s*[%]%)]?$")
		-- Format 2: "Egg Name -20", "Egg Name [-20]", "Egg Name (-20)", "Egg Name - 20"
		if not cnt then
			base, cnt = norm:match("^(.-)%s*[%[%(]?%s*([%-+]%s*%d+)%s*[%]%)]?$")
		end
		-- Format 3: "Egg Name [20]" atau "Egg Name (20)"
		if not cnt then
			base, cnt = norm:match("^(.-)%s*[%[%(]%s*([%-+]?%s*%d+)%s*[%]%)]$")
		end

		if cnt then
			local num = tonumber((cnt:gsub("%s+", "")))
			if num then
				-- Bersihkan base dari bracket/tanda sisa
				base = base and base:gsub("[%[%(]%s*$", ""):match("^%s*(.-)%s*$") or raw
				return base, num
			end
		end

		-- Jika name tidak ada format angka, tapi ada attribute bernilai angka
		if attrVal and tonumber(attrVal) then
			local cleanBase = norm:match("^%s*(.-)%s*$")
			return cleanBase, tonumber(attrVal)
		end

		return norm:match("^%s*(.-)%s*$"), 1
	end

	-- Daftar egg di backpack + jumlah (buat dropdown Egg Configuration).
	function ctx.getEggBackpackOptions()
		local out = {}
		local bp = LP:FindFirstChildOfClass("Backpack")
		if bp then for _, t in ipairs(bp:GetChildren()) do
			local base, cnt = parseEggTool(t)
			if base then
				out[#out + 1] = { name = base, display = ("%s x%d"):format(base, cnt) }
			end
		end end
		table.sort(out, function(a, b) return a.name < b.name end)
		return out
	end

	----------------------------------------------------------------- PLACE EGG
	-- Pending pet dari egg (dari SavedObjects): return petType, displayWeight (base*1.1)
	local eggSlotKey
	local function eggPending(egg)
		local uuid = egg:GetAttribute("OBJECT_UUID"); if not uuid then return nil, 0 end
		local d = getData(); local slots = d and d.SaveSlots and d.SaveSlots.AllSlots
		if not slots then return nil, 0 end
		local function fromSlot(s) local so = s and s.SavedObjects and s.SavedObjects[uuid]; return so and so.Data end
		local dt = eggSlotKey and fromSlot(slots[eggSlotKey])
		if not dt then for sn, slot in pairs(slots) do if type(slot) == "table" then local x = fromSlot(slot); if x then eggSlotKey = sn; dt = x; break end end end end
		if not dt then return nil, 0 end
		return dt.Type, (tonumber(dt.BaseWeight) or 0) * 1.1
	end
	-- Bind predicate tipe egg: cocok kalau label egg-nya mengandung CFG.hatchEggName
	-- ("Dog - Common Egg" cocok "Common Egg"). Data belum ke-load -> fail-open.
	eggMode = function(e)
		local target = CFG.hatchEggName
		if not target or target == "" then return true end
		local pt = eggPending(e)
		if not pt then return true end
		return petEggLabel(pt):lower():find(target:lower(), 1, true) ~= nil
	end
	local function placedEggCount()
		local GetFarm = require(RS.Modules.GetFarm); local farm = GetFarm(LP)
		local n = 0
		if farm then for _, e in ipairs(farm:GetDescendants()) do
			-- Hitung CUMA egg sesuai config: egg tipe lain dibiarkan di farm
			-- (gak di-hatch, gak ngitung slot) — nggak nyandera place target.
			if e:IsA("Model") and e.Name == "PetEgg" and e:GetAttribute("OWNER") == LP.Name and eggMode(e) then n = n + 1 end
		end end
		return n
	end
	local function plantLocPart()
		local GetFarm = require(RS.Modules.GetFarm); local farm = GetFarm(LP)
		local PL = farm and farm:FindFirstChild("Plant_Locations", true)
		if not PL then return nil end
		if PL:IsA("BasePart") then return PL end
		for _, d in ipairs(PL:GetDescendants()) do if d:IsA("BasePart") then return d end end
		return nil
	end
	-- Grid FIX & rapih: n slot, center di area, baris rata (spacing 4 studs).
	-- + sedikit baris cadangan di belakang biar tetap bisa penuh kalau ada egg nyempil.
	local function gridPositions(n)
		local p = plantLocPart(); if not p then return {} end
		n = math.max(1, n or 9)
		local SP = 4 -- jarak antar egg (min server = 3, kasih margin biar ga "Too close")
		local usableX = math.max(SP, p.Size.X - 4)
		local cols = math.max(1, math.min(n, math.floor(usableX / SP) + 1))
		-- baris = cukup buat n + 1 baris cadangan (anti-stuck, tetap rapi)
		local rows = math.ceil(n / cols) + 1
		local startX = -((cols - 1) * SP) / 2
		local startZ = -((rows - 1) * SP) / 2
		local out = {}
		for r = 0, rows - 1 do
			for c = 0, cols - 1 do
				out[#out + 1] = p.Position + Vector3.new(startX + c * SP, p.Size.Y / 2 + 0.2, startZ + r * SP)
			end
		end
		return out
	end
	-- Sebar egg ACAK di dalam area, tetap jaga jarak antar-egg biar ga "Too close".
	local function randomPositions(n)
		local p = plantLocPart(); if not p then return {} end
		n = math.max(1, n or 9)
		local SP = 4 -- jarak minimum antar egg
		local halfX = math.max(SP, p.Size.X / 2 - 2)
		local halfZ = math.max(SP, p.Size.Z / 2 - 2)
		local y = p.Size.Y / 2 + 0.2
		local out, tries = {}, 0
		-- generate lebih banyak dari n (buffer) biar tetap bisa penuh walau ada yg bentrok
		while #out < n * 2 and tries < n * 40 do
			tries = tries + 1
			local cand = p.Position + Vector3.new((math.random() * 2 - 1) * halfX, y, (math.random() * 2 - 1) * halfZ)
			local ok = true
			for _, e in ipairs(out) do
				if (Vector3.new(e.X, 0, e.Z) - Vector3.new(cand.X, 0, cand.Z)).Magnitude < SP then ok = false; break end
			end
			if ok then out[#out + 1] = cand end
		end
		return out
	end
	-- Circle: egg muter jadi 1 lingkaran di tengah area. Radius ngikut jumlah egg (jarak antar
	-- egg ~SP), jadi makin dikit egg makin kecil lingkarannya. Kalau area kekecilan, ring
	-- kedua (luar). Plus ring cadangan di luar buat jaga-jaga ada egg nyempil.
	local function circlePositions(n)
		local p = plantLocPart(); if not p then return {} end
		n = math.max(1, n or 9)
		local SP = 4
		local y = p.Size.Y / 2 + 0.2
		local maxR = math.max(SP, math.min(p.Size.X, p.Size.Z) / 2 - 2)
		local out = {}
		if n == 1 then return { p.Position + Vector3.new(0, y, 0) } end
		local function ring(count, r, phase)
			for i = 0, count - 1 do
				local a = phase + (i / count) * math.pi * 2
				out[#out + 1] = p.Position + Vector3.new(math.cos(a) * r, y, math.sin(a) * r)
			end
		end
		local r = math.max(SP * 0.75, n * SP / (2 * math.pi))
		if r <= maxR then
			ring(n, r, -math.pi / 2)
			-- cadangan: ring luar (cuma kepake kalau slot utama keblok)
			local r2 = r + SP
			if r2 <= maxR then ring(math.max(1, math.floor(2 * math.pi * r2 / SP)), r2, -math.pi / 2) end
		else
			-- 1 ring nggak muat: ring luar penuh di maxR, sisanya ring dalam
			local outerN = math.max(1, math.floor(2 * math.pi * maxR / SP))
			ring(math.min(n, outerN), maxR, -math.pi / 2)
			local left = n - outerN
			local r1 = maxR - SP
			while left > 0 and r1 >= SP * 0.75 do
				local c = math.max(1, math.min(left, math.floor(2 * math.pi * r1 / SP)))
				ring(c, r1, -math.pi / 2)
				left = left - c
				r1 = r1 - SP
			end
		end
		return out
	end
	-- Line: 1 garis lurus atas -> bawah (sumbu Z) di tengah area. Kepanjangan = kolom kedua
	-- di sebelahnya. Plus 1 slot cadangan di ujung.
	local function linePositions(n)
		local p = plantLocPart(); if not p then return {} end
		n = math.max(1, n or 9)
		local SP = 4
		local y = p.Size.Y / 2 + 0.2
		local usableZ = math.max(SP, p.Size.Z - 4)
		local perCol = math.max(1, math.min(n + 1, math.floor(usableZ / SP) + 1))
		local cols = math.ceil((n + 1) / perCol)
		local out = {}
		for c = 0, cols - 1 do
			local inCol = math.min(perCol, (n + 1) - c * perCol)
			local startZ = -((inCol - 1) * SP) / 2
			local x = (c - (cols - 1) / 2) * SP
			for r = 0, inCol - 1 do
				out[#out + 1] = p.Position + Vector3.new(x, y, startZ + r * SP)
			end
		end
		return out
	end
	local function currentEggs()
		local GetFarm = require(RS.Modules.GetFarm); local farm = GetFarm(LP)
		local t = {}
		if farm then for _, e in ipairs(farm:GetDescendants()) do
			if e:IsA("Model") and e.Name == "PetEgg" and e:GetAttribute("OWNER") == LP.Name then t[#t + 1] = e end
		end end
		return t
	end
	local function slotOccupied(pos, eggs)
		for _, e in ipairs(eggs) do
			local ep = e:GetPivot().Position
			if (Vector3.new(ep.X, 0, ep.Z) - Vector3.new(pos.X, 0, pos.Z)).Magnitude < 3.5 then return true end
		end
		return false
	end
	-- return tool egg yg lagi dipegang (scan SEMUA tool, bukan cuma yg pertama) + apakah ada
	-- tool lain (pet/egg beda) yg ikut nyangkut.
	local function scanHeld(eggName)
		local char = LP.Character
		local heldEgg, otherCount = nil, 0
		if char then for _, t in ipairs(char:GetChildren()) do
			if t:IsA("Tool") then
				if not t:GetAttribute("PET_UUID") and tostring(t.Name):find(eggName, 1, true) then heldEgg = t
				else otherCount = otherCount + 1 end
			end
		end end
		return heldEgg, otherCount
	end
	local function equipEggTool(eggName)
		local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
		if not hum then return nil end
		local heldEgg, otherCount = scanHeld(eggName)
		-- udah megang egg yg bener DAN ga ada tool lain nyangkut -> ok
		if heldEgg and otherCount == 0 then return heldEgg end
		-- ada pet/egg-lain ke-pegang barengan (bug double-hold) -> lepas SEMUA biar bersih
		pcall(function() hum:UnequipTools() end); task.wait(0.15)
		local bp = LP:FindFirstChildOfClass("Backpack")
		if bp then for _, t in ipairs(bp:GetChildren()) do
			if t:IsA("Tool") and tostring(t.Name):find(eggName, 1, true) and not t:GetAttribute("PET_UUID") then
				pcall(function() hum:EquipTool(t) end); task.wait(0.35)
				-- pastiin abis equip ga ada tool lain nyusup lagi
				local eg2, oc2 = scanHeld(eggName)
				if eg2 and oc2 > 0 then pcall(function() hum:UnequipTools() end); task.wait(0.1); pcall(function() hum:EquipTool(t) end); task.wait(0.25) end
				return t
			end
		end end
		return nil
	end
	-- Isi egg RAPIH ke grid, cuma di slot yg kosong. Retry sampai penuh (target).
	local function placeEggs(target)
		local eggName = CFG.hatchEggName or "Rare Egg"
		if not equipEggTool(eggName) then ctx.state.hatchStatus = "Egg '" .. eggName .. "' ga ada di backpack"; return 0 end
		local start = placedEggCount()
		local pattern = CFG.hatchPlacePattern or "Grid"
		local isRandom = (pattern == "Random")
		-- isi slot kosong sampai TEPAT target; berhenti kalau 1 pass ga nambah (mentok)
		for _ = 1, 3 do
			if placedEggCount() >= target then break end
			local before = placedEggCount()
			-- Random: sebar ulang tiap pass (spot baru). Grid/Circle/Line: pola tetap.
			local grid = isRandom and randomPositions(target)
				or (pattern == "Circle" and circlePositions(target))
				or (pattern == "Line" and linePositions(target))
				or gridPositions(target)
			local eggs = currentEggs()
			for _, pos in ipairs(grid) do
				if not CFG.hatchEnabled or placedEggCount() >= target then break end
				if not slotOccupied(pos, eggs) then
					equipEggTool(eggName)
					-- pastiin bener-bener MEGANG egg (scan semua tool, bukan cuma yg pertama;
					-- kadang pet hasil hatch ikut ke-pegang). Kalau ada pet nyangkut, equipEggTool
					-- di atas udah bersihin -> re-scan.
					local held = scanHeld(eggName)
					if held then
						pcall(function() EggRemote:FireServer("CreateEgg", pos) end)
						task.wait(0.3)
						eggs = currentEggs() -- refresh biar ga dobel di slot sama
						ctx.state.hatchStatus = ("Placing: %d/%d egg"):format(placedEggCount(), target)
					end
				end
			end
			if placedEggCount() <= before then break end -- ga nambah -> mentok
		end
		return placedEggCount() - start
	end
	local function unionTeam(a, b)
		local u = {}
		for k in pairs(a or {}) do u[k] = true end
		for k in pairs(b or {}) do u[k] = true end
		return u
	end

	-- Klasifikasi egg buat bronto: "skip" | "bronto" | "normal"
	local function classifyEgg(egg)
		local pt, w = eggPending(egg)
		if not pt then return "normal" end

		local key = petEggLabel(pt)

		-- 1) Prioritas 1: Sell & Bronto Config List terpadu
		local rule = findRule(pt)
		if rule then
			local z = rule.special == true
			if z then
				if CFG.brontoSkipSpecial then return "skip" end
				return "bronto"
			end
			local targetKg = tonumber(rule.kg) or 0
			if w >= targetKg then
				-- (dulu toggle "Don't Hatch Special" ikut nge-skip SEMUA egg bronto, bukan cuma special)
				return "bronto"
			else
				return "normal"
			end
		end

		-- 2) Fallback filter lama jika ada
		local isSpecial = (CFG.brontoSpecialPets or {})[key] == true
		if isSpecial and (CFG.brontoSpecialWeight or 0) > 0 and w <= CFG.brontoSpecialWeight then isSpecial = false end
		if isSpecial and CFG.brontoSkipSpecial then return "skip" end
		local isUni = false
		if (CFG.brontoUniversalWeight or 0) > 0 and w > CFG.brontoUniversalWeight then
			local types = CFG.brontoUniversalTypes or {}
			if not next(types) or types[key] then isUni = true end
		end
		if isSpecial or isUni then return "bronto" end
		return "normal"
	end

	----------------------------------------------------------------- Hatch Alert (webhook bronto)
	local PetList; pcall(function() PetList = require(RS.Data.PetRegistry.PetList) end)
	local PetRegistry; pcall(function() PetRegistry = require(RS.Data.PetRegistry) end)
	local function petSize(eggName, petType, baseW)
		local egg = PetRegistry and PetRegistry.PetEggs and PetRegistry.PetEggs[eggName]
		local item = egg and egg.RarityData and egg.RarityData.Items and egg.RarityData.Items[petType]
		local wr = item and item.GeneratedPetData and item.GeneratedPetData.WeightRange
		if type(wr) == "table" and wr[1] and wr[2] and wr[2] > wr[1] then
			local f = (baseW - wr[1]) / (wr[2] - wr[1])
			if f < 0.33 then return "Small" elseif f < 0.7 then return "Normal" else return "Big" end
		end
		return "Normal"
	end
	-- dispWeight = berat tampil (base*1.1). Bronto = dispWeight*1.3 (+30%).
	local function sendHatchAlert(petType, eggName, dispWeight, isBrontoHatch)
		local url = (CFG.hatchWebhookUrl and CFG.hatchWebhookUrl ~= "" and CFG.hatchWebhookUrl) or CFG.webhookUrl
		if not url or url == "" or not ctx.sendWebhook then return end
		if isBrontoHatch == nil then isBrontoHatch = true end
		local finalW = isBrontoHatch and (dispWeight * 1.3) or dispWeight
		local weightStr = isBrontoHatch and (("`%.2f KG` ➜ `%.2f KG` (+30%%)"):format(dispWeight, finalW)) or (("`%.2f KG`"):format(dispWeight))
		local rule = findRule(petType)
		local isSpec = (rule and rule.special == true)
		local alertTitle = isSpec and "✦ CeszParadise — ★ SPECIAL PET Alert" or "✦ CeszParadise — 🦕 BRONTO PET Alert"
		local alertColor = isSpec and 16766720 or 5814783
		local payload = {
			content = "@everyone",
			embeds = { {
				title = alertTitle,
				color = alertColor,
				fields = {
					{
						name = "**Profile :**",
						value = ("> Username : **%s**"):format(LP.Name),
						inline = false,
					},
					{
						name = "**Hatched :**",
						value = ("> Pet Name: `%s` %s\n> Hatched From: `%s`\n> Weight: %s")
							:format(petType, isSpec and "⭐" or "", eggName, weightStr),
						inline = false,
					},
				},
				footer = {
					text = ("Server Version: %s\n%s"):format(tostring(game.PlaceVersion), os.date("%B %d | %I:%M %p")),
					icon_url = "https://raw.githubusercontent.com/milmscr/opoki/main/tegalan/Logo/logo_icon.png",
				},
			} },
		}
		pcall(function() ctx.sendWebhook(url, payload, ctx) end)
	end

	local function sendInventoryFullWebhook(cur, maxCap)
		local url = (CFG.hatchWebhookUrl and CFG.hatchWebhookUrl ~= "" and CFG.hatchWebhookUrl) or CFG.webhookUrl
		if not url or url == "" or not ctx.sendWebhook then return end
		local payload = {
			content = ("@everyone ⚠️ **Auto Hatch STOPPED** — Invent Max `%d/%d`"):format(cur, maxCap),
			embeds = { {
				title = "⚠️ CeszParadise — Inventory Full Alert",
				color = 16728135,
				description = ("> **Status :** `Invent Max %d/%d`\n> Auto Hatch otomatis dihentikan karena kapasitas penyimpanan pet telah mencapai batas maksimal!"):format(cur, maxCap),
				fields = {
					{
						name = "**Profile :**",
						value = ("> Username : **%s**"):format(LP.Name),
						inline = false,
					},
					{
						name = "**Inventory Statistics :**",
						value = ("> Current Pets: `%d`\n> Max Capacity: `%d`\n> Capacity Status: `Penuh (%d/%d)`"):format(cur, maxCap, cur, maxCap),
						inline = false,
					},
				},
				footer = {
					text = ("Server Version: %s\n%s"):format(tostring(game.PlaceVersion), os.date("%B %d | %I:%M %p")),
					icon_url = "https://raw.githubusercontent.com/milmscr/opoki/main/tegalan/Logo/logo_icon.png",
				},
			} },
		}
		pcall(function() ctx.sendWebhook(url, payload, ctx) end)
	end

	local function handleInventoryFull(cur, maxCap)
		if not CFG.hatchEnabled and ctx.state.hatchStatus and ctx.state.hatchStatus:find("Invent Max") then return end
		CFG.hatchEnabled = false
		if ctx.persistState then pcall(ctx.persistState) end
		ctx.stopHatch()
		if ctx.ui and ctx.ui.rHatchToggle then
			pcall(ctx.ui.rHatchToggle)
		end
		ctx.state.hatchPhase = ("Invent Max (%d/%d)"):format(cur, maxCap)
		ctx.state.hatchStatus = ("Auto Hatch STOPPED: Invent Max %d/%d"):format(cur, maxCap)
		if ctx.log then ctx.log(("Auto Hatch STOPPED: Invent Max %d/%d"):format(cur, maxCap)) end
		task.spawn(function()
			sendInventoryFullWebhook(cur, maxCap)
		end)
	end

	local function eggAmount(eggName)
		local n = 0
		local target = tostring(eggName or ""):lower():match("^%s*(.-)%s*$")
		if target == "" then return 0 end
		local safeTarget = target:gsub("([%%%^%$%(%)%%.%[%]%*%+%-%?])", "%%%1")
		for _, src in ipairs({ LP:FindFirstChildOfClass("Backpack"), LP.Character }) do
			if src then for _, t in ipairs(src:GetChildren()) do
				local base, cnt = parseEggTool(t)
				if base then
					local b = tostring(base):lower():match("^%s*(.-)%s*$")
					if b == target then
						n = n + cnt
					elseif b:find("%f[%a]" .. safeTarget .. "%f[%A]") then
						n = n + cnt
					end
				end
			end end
		end
		return n
	end

	local function totalEggCount(eggName)
		return eggAmount(eggName) + placedEggCount()
	end

	----------------------------------------------------------------- Auto Rejoin on Egg Threshold (Minus / Plus)
	local function sendRejoinWebhook(rType, eggName, curAmt, netResult, thresh)
		local url = CFG.webhookUrl
		if not url or url == "" or not ctx.sendWebhook then return end
		local diffStr = (type(netResult) == "number") and (("%+d"):format(netResult)) or tostring(netResult)
		local isPlus = (rType == "Plus")
		local title = isPlus and "🔄 CeszParadise — Auto Rejoin (Egg Plus)" or "🔄 CeszParadise — Auto Rejoin (Egg Minus)"
		local color = isPlus and 3066993 or 16744272
		local sign = isPlus and "+" or "-"
		local notifyText = ("auto rejoin on, %s %d (%s)"):format(eggName, curAmt, diffStr)
		local desc = isPlus
			and ("> **Status :** `%s`\n> Penambahan egg terdeteksi surplus melebihi ambang batas (`+%d`)! Melakukan auto rejoin ke server..."):format(notifyText, thresh)
			or ("> **Status :** `%s`\n> Pengurangan egg terdeteksi minus melebihi ambang batas (`-%d`)! Melakukan auto rejoin ke server..."):format(notifyText, thresh)
		local payload = {
			content = ("@everyone ⚠️ **Auto Rejoin** — `%s`"):format(notifyText),
			embeds = { {
				title = title,
				color = color,
				description = desc,
				fields = {
					{
						name = "**Profile :**",
						value = ("> Username : **%s**\n> Display : **%s**"):format(LP.Name, LP.DisplayName or LP.Name),
						inline = false,
					},
					{
						name = "**Egg Information :**",
						value = ("> Egg Name : `%s`\n> Current Egg : `%d` (`%s`)\n> Threshold : `%s%d`"):format(eggName, curAmt, diffStr, sign, thresh),
						inline = false,
					},
					{
						name = "**Action :**",
						value = "> Reconnecting to server immediately...",
						inline = false,
					},
				},
				footer = {
					text = ("Server Version: %s\n%s"):format(tostring(game.PlaceVersion), os.date("%B %d | %I:%M %p")),
					icon_url = "https://raw.githubusercontent.com/milmscr/opoki/main/tegalan/Logo/logo_icon.png",
				},
			} },
		}
		pcall(function() ctx.sendWebhook(url, payload, ctx) end)
	end

	function ctx.testRejoinWebhook()
		local eggName = CFG.hatchEggName or "Paradise Egg"
		local thresh = math.abs(tonumber(CFG.hatchRejoinMinusThreshold) or 20)
		sendRejoinWebhook("Minus", eggName, 200, -thresh, thresh)
	end

	function ctx.testRejoinPlusWebhook()
		local eggName = CFG.hatchEggName or "Paradise Egg"
		local thresh = math.abs(tonumber(CFG.hatchRejoinPlusThreshold) or 20)
		sendRejoinWebhook("Plus", eggName, 220, thresh, thresh)
	end

	local function sendStartHatchWebhook()
		local url = CFG.webhookUrl
		if not url or url == "" or not ctx.sendWebhook then return end
		local eggName = CFG.hatchEggName or "Rare Egg"
		local eggBefore = ctx.state.hatchEggBefore or 0
		local bpc = 0
		for _, t in ipairs((function() local o={}; local bp=LP:FindFirstChildOfClass("Backpack"); for _,src in ipairs({bp,LP.Character}) do if src then for _,c in ipairs(src:GetChildren()) do if c:IsA("Tool") and c:GetAttribute("PET_UUID") then o[#o+1]=c end end end end; return o end)()) do bpc=bpc+1 end
		local maxBp = 0
		pcall(function() local d = require(game:GetService("ReplicatedStorage").Modules.GetData)(LP); if d then maxBp = tonumber(d.PetsData.MutableStats.MaxPetsInInventory) or 0 end end)
		local rec = ctx.getRecoveryStat and ctx.getRecoveryStat() or {}
		local payload = {
			embeds = { {
				title = "🥚 CeszParadise — Auto Hatch Started",
				color = 3066993,
				description = "> **Auto Hatch** telah dimulai! Memulai siklus hatching otomatis...",
				fields = {
					{
						name = "**Profile :**",
						value = ("> Username : **%s**\n> Display : **%s**"):format(LP.Name, LP.DisplayName or LP.Name),
						inline = false,
					},
					{
						name = "**Egg Info :**",
						value = ("> Egg Name : `%s`\n> Egg Before : `%d`\n> Max Placed : `%d`"):format(eggName, eggBefore, CFG.hatchMaxPlaced or 8),
						inline = false,
					},
					{
						name = "**Inventory :**",
						value = ("> Pet on Backpack : `%d/%d`"):format(bpc, maxBp),
						inline = false,
					},
					{
						name = "**Recovery Stat :**",
						value = ("> Koi (hatch) : `%d ekor → %.1f%%`\n> Seal (sell) : `%d ekor → %.1f%%`"):format(
							(rec.koiCount or 0), (rec.koiPct or 0),
							(rec.sealCount or 0), (rec.sealPct or 0)),
						inline = false,
					},
					{
						name = "**Sell Config :**",
						value = ("> Sell Mode : `%s`\n> Sell Style : `%s`\n> Sell Every : `%d cycles`"):format(
							CFG.sellMode or "Cycle", CFG.sellStyle or "All at Once", CFG.sellEveryNCycles or 1),
						inline = false,
					},
				},
				footer = {
					text = ("Server Version: %s\n%s"):format(tostring(game.PlaceVersion), os.date("%B %d | %I:%M %p")),
					icon_url = "https://raw.githubusercontent.com/milmscr/opoki/main/tegalan/Logo/logo_icon.png",
				},
			} },
		}
		pcall(function() ctx.sendWebhook(url, payload, ctx) end)
	end

	local function checkEggThreshold()
		local eggName = CFG.hatchEggName or "Rare Egg"
		local curAmt = totalEggCount(eggName)
		local eggBefore = ctx.state.hatchEggBefore or 0

		-- Inisialisasi hatchEggBefore jika belum ada atau saat ganti egg
		if ctx.state.lastTrackedEggName ~= eggName then
			ctx.state.lastTrackedEggName = eggName
			ctx.state.hatchEggBefore = curAmt
			eggBefore = curAmt
		elseif (not ctx.state.hatchEggBefore or ctx.state.hatchEggBefore == 0) and curAmt > 0 and CFG.hatchEnabled then
			ctx.state.hatchEggBefore = curAmt
			eggBefore = curAmt
		end

		local netResult = curAmt - eggBefore

		-- 1. Cek THRESHOLD EGG MINUS (berkurang)
		if CFG.hatchRejoinMinusEnabled then
			local minusThresh = math.abs(tonumber(CFG.hatchRejoinMinusThreshold) or 20)
			if minusThresh <= 0 then minusThresh = 20 end

			-- netResult minus melebihi threshold (misal: netResult <= -20)
			if eggBefore > 0 and netResult <= -minusThresh then
				return true, "Minus", eggName, curAmt, netResult, minusThresh
			end

			-- Tool stack egg itu sendiri minus di backpack (misal: curAmt <= -20)
			if curAmt <= -minusThresh then
				return true, "Minus", eggName, curAmt, curAmt, minusThresh
			end

			-- Cek jika ada tool egg lain di inventory dengan stack minus
			local counts = {}
			for _, src in ipairs({ LP:FindFirstChildOfClass("Backpack"), LP.Character }) do
				if src then
					for _, t in ipairs(src:GetChildren()) do
						local base, qty = parseEggTool(t)
						if base then counts[base] = (counts[base] or 0) + qty end
					end
				end
			end
			for name, qty in pairs(counts) do
				if qty <= -minusThresh then
					return true, "Minus", name, qty, qty, minusThresh
				end
			end
		end

		-- 2. Cek THRESHOLD EGG PLUS (bertambah)
		if CFG.hatchRejoinPlusEnabled then
			local plusThresh = math.abs(tonumber(CFG.hatchRejoinPlusThreshold) or 20)
			if plusThresh <= 0 then plusThresh = 20 end

			-- netResult bertambah melebihi threshold (misal: netResult >= +20)
			if eggBefore > 0 and netResult >= plusThresh then
				return true, "Plus", eggName, curAmt, netResult, plusThresh
			end
		end

		return false, nil, eggName, curAmt, netResult, 0
	end

	local function doDirectReconnect()
		if ctx.reconnect then
			pcall(ctx.reconnect)
		else
			local branch = (getgenv and getgenv().GAG_BRANCH) or _G.GAG_BRANCH or "main"
			local q = (syn and syn.queue_on_teleport) or queue_on_teleport
				or (fluxus and fluxus.queue_on_teleport) or (getgenv and getgenv().queue_on_teleport)
			if q then
				pcall(function()
					q(('if getgenv then getgenv().GAG_BRANCH=%q end loadstring(game:HttpGet("https://raw.githubusercontent.com/milmscr/opoki/%s/tegalan/init.lua"))()'):format(branch, branch))
				end)
			end
			task.wait(0.4)
			local TeleportService = game:GetService("TeleportService")
			local TeleportFn = TeleportService.Teleport
			local ok = pcall(function() TeleportFn(TeleportService, game.PlaceId, LP) end)
			if not ok then
				pcall(function() TeleportService:Teleport(game.PlaceId, LP) end)
			end
		end
	end

	local function handleEggRejoin(rType, eggName, curAmt, netResult, thresh)
		if ctx.state.hatchIsRejoining then return end
		ctx.state.hatchIsRejoining = true

		local diffStr = (type(netResult) == "number") and (("%+d"):format(netResult)) or tostring(netResult)
		local sign = (rType == "Plus") and "+" or "-"
		local reason = ("auto rejoin on, %s %d (%s)"):format(eggName, curAmt, diffStr)
		ctx.state.hatchPhase = "Auto Rejoin"
		ctx.state.hatchStatus = ("Rejoining (%s %d [%s])..."):format(eggName, curAmt, diffStr)
		if ctx.log then ctx.log(("[Auto Hatch] %s (Threshold: %s%d) -> Rejoining server immediately..."):format(reason, sign, thresh)) end

		-- Kirim webhook rejoin
		task.spawn(function()
			sendRejoinWebhook(rType, eggName, curAmt, netResult, thresh)
		end)

		-- Jeda 1.2 detik agar webhook selesai dikirim sebelum client disconnect
		task.wait(1.2)

		-- Eksekusi Reconnect (seperti di interval rejoin)
		doDirectReconnect()
	end

	----------------------------------------------------------------- Cycle Statistics (webhook)
	-- Team ringkas: "N Nama Lengkap" (mutasi + tipe), grup per nama.
	local function teamNames(set)
		local mutDisplay = (ctx.reg and ctx.reg.mutDisplay) or function(x) return x end
		local inv = inventory()
		local tally, order = {}, {}
		for u in pairs(set or {}) do
			local v = inv[u]
			if v then
				local pt = v.PetType or "?"
				local mut = v.PetData and v.PetData.MutationType
				local mutName = mut and mutDisplay(mut) or mut
				local name = (mut and mut ~= "" and mut ~= "Normal") and (tostring(mutName) .. " " .. pt) or pt
				if not tally[name] then tally[name] = 0; order[#order + 1] = name end
				tally[name] = tally[name] + 1
			end
		end
		table.sort(order)
		local parts = {}
		for _, name in ipairs(order) do parts[#parts + 1] = tally[name] .. " " .. name end
		return #parts > 0 and table.concat(parts, ", ") or "None"
	end
	ctx.hatchTeamNames = teamNames

	-- Kategori Hunt: Special (dari filter Bronto Config) + Heavy (>= 5kg, gabungan Huge s/d Colossal).
	-- Apakah pet masuk filter Special di Sell & Bronto Configuration?
	local function isBrontoSpecial(petType, w)
		local rule = findRule(petType)
		if rule then
			if rule.special == true then return true end
			local targetKg = tonumber(rule.kg) or 0
			return (tonumber(w) or 0) >= targetKg
		end
		local key = petEggLabel(petType)
		if (CFG.brontoSpecialPets or {})[key] ~= true then return false end
		if (CFG.brontoSpecialWeight or 0) > 0 and (w or 0) <= CFG.brontoSpecialWeight then return false end
		return true
	end
	-- akumulasi pet ke-hatch: Special vs Heavy (>= 5 kg). Simpan list semua bobot per petType.
	local function trackHatch(petType, dispW, special)
		ctx.state.hatchTiers = ctx.state.hatchTiers or {}
		dispW = tonumber(dispW) or 0
		local category = special and "Special" or (dispW >= 5 and "Heavy" or nil)
		if not category then return end -- <5kg non-special: skip

		local bucket = ctx.state.hatchTiers[category]
		if not bucket then bucket = {}; ctx.state.hatchTiers[category] = bucket end
		local t = bucket[petType]
		if not t then t = { n = 0, weights = {} }; bucket[petType] = t end
		t.n = t.n + 1
		t.weights[#t.weights + 1] = dispW
	end
	ctx.hatchIsBrontoSpecial = isBrontoSpecial

	-- Recovery stat DIHITUNG dari team yg dipilih (formula game, bukan empiris).
	-- Per pet: value = clamp(Base + Scale*scaledLevel, 0, Max). scaledLevel diminishing
	-- di atas 100. Total di-cap 50% (cap per egg). Koi @ Hatch team, Seal @ Sell team.
	local function scaledLevel(lv)
		lv = lv or 0
		if lv <= 100 then return lv
		elseif lv <= 120 then return (lv - 100) * 0.25 + 100
		else return (lv - 120) * 0.1 + 105 end
	end
	local function passivePct(teamSet, typeMatch, base, scale, maxPer)
		local inv = inventory()
		local n, total = 0, 0
		for u in pairs(teamSet or {}) do
			local v = inv[u]
			if v and tostring(v.PetType):find(typeMatch) then
				n = n + 1
				local val = base + scale * scaledLevel((v.PetData or {}).Level or 0)
				total = total + math.clamp(val, 0, maxPer) -- per-pet asli (Max 10), total ga di-cap
			end
		end
		return n, total
	end
	-- Koi (Fish of Fortune): Base1 Scale0.22 Max10. Seal (Seal the Deal): Base1 Scale0.05 Max10.
	function ctx.getRecoveryStat()
		local kn, kp = passivePct(CFG.hatchHatchTeam, "Koi", 1, 0.22, 10)
		local sn, sp = passivePct(CFG.hatchSellTeam, "Seal", 1, 0.05, 10)
		return {
			koiCount = kn, koiPct = kp,
			sealCount = sn, sealPct = sp,
		}
	end

	-- Recovery ASLI dihitung dari notif game (listener di atas): periodHatchRec / periodSellRec.
	-- periodHatched / periodSold = jumlah aksi (buat hitung % efektif).

	local function fmtDur(sec)
		sec = math.max(0, math.floor(sec))
		local h = math.floor(sec / 3600); local m = math.floor((sec % 3600) / 60); local s = sec % 60
		local p = {}
		if h > 0 then p[#p + 1] = h .. "h" end
		if m > 0 then p[#p + 1] = m .. "m" end
		p[#p + 1] = s .. "s"
		return table.concat(p, " ")
	end

	local function sendCycleStats()
		local url = CFG.webhookUrl
		if not url or url == "" or not ctx.sendWebhook then return end
		local eggName = CFG.hatchEggName or "Rare Egg"
		local hatched = ctx.state.hatchEggsHatched or 0
		local eggBefore = ctx.state.hatchEggBefore or 0
		local curAmt = totalEggCount(eggName)

		-- Format Hunt: Special (range min-max kg) & Heavy/Huge-Colossal (daftar bobot tiap pet)
		local tiers = ctx.state.hatchTiers or {}
		local huntLines, totalPets = {}, 0

		-- 1. Special Pets (langsung hasil tanpa judul 'Special:')
		local specBucket = tiers["Special"] or {}
		local specKeys = {}
		for pt in pairs(specBucket) do specKeys[#specKeys + 1] = pt end
		table.sort(specKeys)
		for _, pt in ipairs(specKeys) do
			local t = specBucket[pt]
			totalPets = totalPets + t.n
			local minW, maxW = math.huge, 0
			for _, w in ipairs(t.weights) do
				if w < minW then minW = w end
				if w > maxW then maxW = w end
			end
			local rng = (minW == maxW or minW == math.huge) and ("`%.2f kg`"):format(maxW)
				or ("`%.2f-%.2f kg`"):format(minW, maxW)
			huntLines[#huntLines + 1] = ("> • **%s** `x%d` (%s)"):format(pt, t.n, rng)
		end

		-- 2. Heavy / Huge-Colossal Pets (daftar bobot per pet)
		local heavyBucket = tiers["Heavy"] or {}
		local heavyKeys = {}
		for pt in pairs(heavyBucket) do heavyKeys[#heavyKeys + 1] = pt end
		table.sort(heavyKeys)
		for _, pt in ipairs(heavyKeys) do
			local t = heavyBucket[pt]
			totalPets = totalPets + t.n
			local wStrs = {}
			for _, w in ipairs(t.weights) do
				wStrs[#wStrs + 1] = ("%.2f"):format(w)
			end
			huntLines[#huntLines + 1] = ("> • **%s** `x%d` (`%skg`)"):format(pt, t.n, table.concat(wStrs, ", "))
		end

		local huntText = #huntLines > 0 and table.concat(huntLines, "\n"):sub(1, 1020) or "> • *Tidak ada pet bronto*"

		-- Recovery deterministik (cap 50%). Koi dari Hatch+Bronto team; Seal dari Sell team.
		local rec = ctx.getRecoveryStat()
		local sellDone = ctx.state.sellDoneThisReport == true
		local recHatchCycle = math.floor((ctx.state.periodHatchRec or 0) + 0.5)
		local recSellCycle = sellDone and math.floor((ctx.state.periodSellRec or 0) + 0.5) or 0
		local koiPctShown = rec.koiPct
		local sellPctShown = sellDone and rec.sealPct or 0
		local totalRecovery = recHatchCycle + recSellCycle

		local curAdj = curAmt
		local maxBp = 0
		local d = getData(); if d then maxBp = tonumber(d.PetsData.MutableStats.MaxPetsInInventory) or 0 end
		local hatchCycles = ctx.state.hatchRounds or 0
		local netResult = curAdj - eggBefore

		local payload = { embeds = { {
			title = "📊 Tracking",
			color = 5793266,
			fields = {
				{
					name = "**Profile :**",
					value = ("> Username : **%s**"):format(LP.Name),
					inline = false
				},
				{
					name = "**Hatch Statistics :**",
					value = ("> Cycle Count: `%d`\n> Total Hatched: `%d`\n> Sell Cycle: `%d / %d`\n> Reduce Time: `%s`\n> Duration: `%s`\n> \n> Egg Name: `%s`\n> Pet on Inventory: `%d/%d`")
						:format(
							hatchCycles,
							hatched,
							(ctx.state.hatchReportSellProg or ((ctx.state.hatchRounds or 0) - (ctx.state.hatchLastSellCycle or 0))),
							CFG.sellEveryNCycles or 1,
							fmtDur(os.time() - (ctx.state.hatchCycleStartTime or os.time())),
							fmtDur(os.time() - (ctx.state.hatchStartTime or os.time())),
							eggName,
							backpackPetCount(),
							maxBp
						),
					inline = false
				},
				{
					name = ("**Hatch Bronto (%d):**"):format(totalPets),
					value = huntText,
					inline = false
				},
				{
					name = "**Egg Statistics :**",
					value = ("> Egg Before: `%d`\n> Current Egg: `%d` (`%+d`)\n> Lucky Hatch: `%d` (`%.2f%%`)\n> Lucky Sell: `%d` (`%.2f%%`)\n> Total Recovery: `%d`")
						:format(eggBefore, curAdj, netResult, recHatchCycle, koiPctShown, recSellCycle, sellPctShown, totalRecovery),
					inline = false
				},
			},
			footer = {
				text = ("Server Version: %s\n%s"):format(tostring(game.PlaceVersion), os.date("%B %d | %I:%M %p")),
				icon_url = "https://raw.githubusercontent.com/milmscr/opoki/main/tegalan/Logo/logo_icon.png"
			},
		} } }
		pcall(function() ctx.sendWebhook(url, payload, ctx) end)
		ctx.state.hatchCycleStartTime = os.time()
		-- reset counter periode (Lucky Hatch/Sell dihitung ulang tiap webhook)
		ctx.state.periodHatched, ctx.state.periodSold, ctx.state.sellDoneThisReport = 0, 0, false
		ctx.state.periodHatchRec, ctx.state.periodSellRec = 0, 0
	end
	ctx.hatchSendCycleStats = sendCycleStats
	ctx.hatchTrack = trackHatch

	----------------------------------------------------------------- STATUS
	ctx.state.hatchStatus = "Idle"
	function ctx.getHatchSummary()
		-- team: format per pet "Mutasi - Nama - Berat - Age" (pakai teamNames global)
		local nm = teamNames
		-- max backpack + jumlah egg terpilih
		local d = getData()
		local maxBp = d and d.PetsData and d.PetsData.MutableStats and tonumber(d.PetsData.MutableStats.MaxPetsInInventory) or 0
		local eggName = CFG.hatchEggName or "Rare Egg"
		local curEgg = totalEggCount(eggName)
		return {
			status = CFG.hatchEnabled and "RUNNING" or "STOPPED",
			phase = ctx.state.hatchPhase or "-",
			core = nm(CFG.hatchCoreTeam), hatch = nm(CFG.hatchHatchTeam),
			bronto = nm(CFG.hatchBrontoTeam), sell = nm(CFG.hatchSellTeam),
			backpack = backpackPetCount(), maxBackpack = maxBp,
			currentEgg = eggName, eggBefore = ctx.state.hatchEggBefore or curEgg, currentAmount = curEgg,
			eggsHatched = ctx.state.hatchEggsHatched or 0,
			sellCycles = ctx.state.hatchSellCycles or 0,
			ready = #readyEggs(),
			placed = placedEggCount(),
			maxPlaced = CFG.hatchMaxPlaced or 9,
			sellMode = CFG.sellMode or "Cycle",
			cycleProg = (ctx.state.hatchRounds or 0) - (ctx.state.hatchLastSellCycle or 0),
			cycleTarget = CFG.sellEveryNCycles or 1,
			proc = ctx.getRecoveryStat(),
		}
	end

	----------------------------------------------------------------- LOOP
	local function tick()
		local bpc = backpackPetCount()
		local maxP = CFG.hatchMaxPlaced or 9
		local placed = placedEggCount()

		-- CHECK EGG THRESHOLD (Fallback saat Auto Sell dimatikan atau kondisi stuck total):
		-- Jika Auto Sell mati, atau stuck (tidak ada egg di inventory, plot kosong, dan tidak ada pet untuk di-sell),
		-- cek langsung agar tidak idle selamanya.
		-- Jika Auto Sell aktif, pengecekan UTAMA dilakukan SETELAH sell di bawah agar egg bisa balik dulu (Seal the Deal recovery).
		if CFG.hatchRejoinMinusEnabled or CFG.hatchRejoinPlusEnabled then
			local curEgg = totalEggCount(CFG.hatchEggName or "Rare Egg")
			local isStuck = (curEgg <= 0 and placed == 0 and bpc == 0)
			if not CFG.autoSellEnabled or isStuck then
				local shouldRejoin, rType, rEgg, rCur, rNet, rThresh = checkEggThreshold()
				if shouldRejoin then
					handleEggRejoin(rType, rEgg, rCur, rNet, rThresh)
					return
				end
			end
		end

		-- cycle = jumlah RONDE hatch (tiap 1 batch garden selesai di-hatch = 1 cycle)
		local cycle = ctx.state.hatchRounds or 0
		-- 1) SELL trigger: mode "Cycle" (tiap N cycle) atau "Backpack" (pas penuh)
		local sellNow = false
		if CFG.autoSellEnabled then
			if CFG.sellMode == "Cycle" then
				sellNow = (cycle - (ctx.state.hatchLastSellCycle or 0)) >= (CFG.sellEveryNCycles or 1)
			else
				sellNow = bpc >= (CFG.sellWhenReach or 100)
			end
		end
		if sellNow then
			ctx.state.pnpBlockedByHatch = true
			ctx.state.hatchPhase = "Selling Pets"
			if next(CFG.hatchSellTeam or {}) and not equipTeam(CFG.hatchSellTeam, "Sell Team", CFG.hatchSellUnequipDelay, CFG.hatchSellEquipDelay) then return end -- team wajib lengkap
			task.wait(CFG.sellTeamDelay or 5.5)
			local sold = doSell()
			ctx.state.periodSold = (ctx.state.periodSold or 0) + (tonumber(sold) or 0)
			-- Backpack mode & 0 matched -> naikin threshold biar trigger sell gak
			-- nembak tiap tick (loop sell selamanya, hatch gak pernah jalan).
			if (tonumber(sold) or 0) == 0 and CFG.sellMode == "Backpack" then
				CFG.sellWhenReach = bpc + 1
				ctx.log(("Hatch: sell 0 match — Sell Trigger (BP) dinaikin ke %d biar hatch jalan lagi"):format(CFG.sellWhenReach))
			end
			ctx.state.sellDoneThisReport = true
			-- simpan progress sell-cycle SEBELUM reset (biar webhook nampilin 2/2 bukan 0/2)
			ctx.state.hatchReportSellProg = cycle - (ctx.state.hatchLastSellCycle or 0)
			ctx.state.hatchLastSellCycle = cycle

			-- Tunggu 2 detik agar notifikasi Lucky Pet / recovery Seal the Deal selesai masuk ke inventory
			task.wait(2.0)

			-- 1) Kirim Webhook Sell Terlebih Dahulu Sebelum Rejoin!
			sendCycleStats()
			ctx.state.hatchPendingReport = false

			-- 2) Beri jeda 0.6s agar HTTP request webhook sell terkirim ke Discord
			task.wait(0.6)

			-- 3) CEK EGG THRESHOLD (MINUS / PLUS) SETELAH SIKLUS AUTO SELL SELESAI:
			-- Memberi kesempatan Sell Team mengembalikan egg (Seal recovery) terlebih dahulu.
			-- Jika setelah sell selesai egg minus/plus melebihi threshold -> kirim webhook rejoin lalu langsung auto rejoin!
			if CFG.hatchRejoinMinusEnabled or CFG.hatchRejoinPlusEnabled then
				local shouldRejoin, rType, rEgg, rCur, rNet, rThresh = checkEggThreshold()
				if shouldRejoin then
					handleEggRejoin(rType, rEgg, rCur, rNet, rThresh)
					return
				end
			end

			return
		end

		-- CHECK INVENTORY FULL: jika penyimpanan penuh, hentikan auto hatch & kirim webhook
		local curPets, maxPets = getInventoryCapacity()
		if maxPets > 0 and curPets >= maxPets then
			if CFG.autoSellEnabled and not ctx.state.sellDoneThisReport then
				ctx.state.pnpBlockedByHatch = true
				ctx.state.hatchPhase = "Selling Pets (Inv Full)"
				if not next(CFG.hatchSellTeam or {}) or equipTeam(CFG.hatchSellTeam, "Sell Team", CFG.hatchSellUnequipDelay, CFG.hatchSellEquipDelay) then
					task.wait(CFG.sellTeamDelay or 5.5)
					local sold = doSell()
					ctx.state.periodSold = (ctx.state.periodSold or 0) + (tonumber(sold) or 0)
					-- Sama: 0 match di mode Backpack -> naikin threshold (anti-stuck).
					if (tonumber(sold) or 0) == 0 and CFG.sellMode == "Backpack" then
						CFG.sellWhenReach = curPets + 1
						ctx.log(("Hatch: sell 0 match (inv full) — Sell Trigger (BP) dinaikin ke %d"):format(CFG.sellWhenReach))
					end
					ctx.state.sellDoneThisReport = true
					curPets, maxPets = getInventoryCapacity()
					task.wait(2.0)

					-- Kirim webhook sell dulu
					sendCycleStats()
					ctx.state.hatchPendingReport = false
					task.wait(0.6)

					-- Cek egg threshold setelah sell darurat
					if CFG.hatchRejoinMinusEnabled or CFG.hatchRejoinPlusEnabled then
						local shouldRejoin, rType, rEgg, rCur, rNet, rThresh = checkEggThreshold()
						if shouldRejoin then
							handleEggRejoin(rType, rEgg, rCur, rNet, rThresh)
							return
						end
					end
				end
			end
			if maxPets > 0 and curPets >= maxPets then
				handleInventoryFull(curPets, maxPets)
				return
			end
		end

		-- clamp target ke kapasitas farm biar ga nyangkut (mis. Max Placed > MaxEggsInFarm)
		local d = getData()
		local farmCap = d and d.PetsData and d.PetsData.MutableStats and d.PetsData.MutableStats.MaxEggsInFarm or maxP
		maxP = math.min(maxP, farmCap)

		local placed = placedEggCount()

		-- 2) PLACE (best-effort): tambah egg kalau kurang. JANGAN stuck kalau ga bisa penuh
		--    (grid bentrok egg recovered / kapasitas farm mentok) -> lanjut proses egg yg ada.
		if placed < maxP then
			ctx.state.hatchPhase = ("Placing Eggs (%d/%d)"):format(placed, maxP)
			if not equipTeam(CFG.hatchCoreTeam, "Core Team", CFG.hatchCoreUnequipDelay, CFG.hatchCoreEquipDelay) then return end -- team wajib lengkap dulu
			ctx.state.pnpBlockedByHatch = false
			local added = placeEggs(maxP)
			placed = placedEggCount()
			if added > 0 and placed < maxP then return end -- masih nambah -> lanjut place tick berikut
			-- added==0 (mentok) & belum penuh -> anti-stuck: lanjut proses egg yg udah ada
		end

		-- REPORT: garden udah ke-refill (place selesai). Kalau ada report pending dari
		-- hatch/sell sebelumnya, KIRIM sekarang -> Current Amount = backpack + garden (stabil).
		if ctx.state.hatchPendingReport then
			ctx.state.hatchPendingReport = false
			task.spawn(sendCycleStats)
		end

		local ready = readyEggs()
		-- 3) HATCH: HANYA kalau SEMUA egg (yg ke-place) udah READY (jangan switch selama timer jalan)
		if placed > 0 and #ready >= placed then
			ctx.state.pnpBlockedByHatch = true
			local curHatchPets, maxHatchPets = getInventoryCapacity()
			if maxHatchPets > 0 and curHatchPets >= maxHatchPets then
				handleInventoryFull(curHatchPets, maxHatchPets)
				return
			end

			ctx.state.hatchPhase = "Hatching"
			-- klasifikasi tiap egg: normal (Hatch team) / bronto (Bronto team) / skip
			local normal, bronto = {}, {}
			for _, e in ipairs(ready) do
				local c = classifyEgg(e)
				if c == "bronto" then bronto[#bronto + 1] = e
				elseif c == "normal" then normal[#normal + 1] = e end
			end
			local function hatchList(list)
				for _, e in ipairs(list) do
					if not CFG.hatchEnabled then break end
					local cPets, mPets = getInventoryCapacity()
					if mPets > 0 and cPets >= mPets then
						handleInventoryFull(cPets, mPets)
						break
					end
					local pt, w = eggPending(e)
					if pt then
						local isSpecial = isBrontoSpecial(pt, w)
						trackHatch(pt, w, isSpecial)
						if isSpecial then
							task.spawn(function() sendHatchAlert(pt, CFG.hatchEggName or "Rare Egg", w, false) end)
						end
					end
					pcall(function() EggRemote:FireServer("HatchPet", e) end)
					ctx.state.hatchEggsHatched = (ctx.state.hatchEggsHatched or 0) + 1
				end
			end
			-- pass NORMAL -> Hatch Team (Koi recover)
			if #normal > 0 then
				if next(CFG.hatchHatchTeam or {}) and not equipTeam(CFG.hatchHatchTeam, "Hatch Team", CFG.hatchTeamUnequipDelay, CFG.hatchTeamEquipDelay) then return end
				if next(CFG.hatchHatchTeam or {}) and (CFG.hatchTeamDelay or 5.5) > 0 then
					task.wait(CFG.hatchTeamDelay or 5.5)
				end
				ctx.state.hatchPhase = ("Hatching Hatch-team (%d)"):format(#normal)
				hatchList(normal)
			end
			if not CFG.hatchEnabled then return end
			-- pass BRONTO -> Bronto Team (+30% berat) + kirim Hatch Alert per pet
			if #bronto > 0 then
				if next(CFG.hatchBrontoTeam or {}) and not equipTeam(CFG.hatchBrontoTeam, "Bronto Team", CFG.hatchBrontoUnequipDelay, CFG.hatchBrontoEquipDelay) then return end
				if next(CFG.hatchBrontoTeam or {}) and (CFG.brontoTeamDelay or 5.5) > 0 then
					task.wait(CFG.brontoTeamDelay or 5.5)
				end
				ctx.state.hatchPhase = ("Hatching Bronto-team (%d)"):format(#bronto)
				for _, e in ipairs(bronto) do
					if not CFG.hatchEnabled then break end
					local cPets, mPets = getInventoryCapacity()
					if mPets > 0 and cPets >= mPets then
						handleInventoryFull(cPets, mPets)
						break
					end
					local pt, w = eggPending(e)
					-- pet ini di-hatch pakai Bronto team -> berat aktual +30% (buat tier Hunt)
					if pt then trackHatch(pt, w * 1.3, isBrontoSpecial(pt, w)); task.spawn(function() sendHatchAlert(pt, CFG.hatchEggName or "Rare Egg", w) end) end
					pcall(function() EggRemote:FireServer("HatchPet", e) end)
					ctx.state.hatchEggsHatched = (ctx.state.hatchEggsHatched or 0) + 1
				end
			end
			if not CFG.hatchEnabled then return end
			-- jumlah hatch (recovery-nya diisi listener notif). Beri jeda biar notif nyusul.
			ctx.state.periodHatched = (ctx.state.periodHatched or 0) + #normal + #bronto
			task.wait(1.5)
			-- 1 batch (normal+bronto) selesai = 1 ronde/cycle
			ctx.state.hatchRounds = (ctx.state.hatchRounds or 0) + 1
			-- TANDAI report pending. Webhook ga dikirim di sini — ditunda sampai garden
			-- ke-refill (place egg lagi) biar Current Amount stabil & Lucky Hatch keitung.
			if not (ctx.state.sellDoneThisReport) then ctx.state.hatchReportSellProg = nil end
			ctx.state.hatchPendingReport = true
			return
		end

		-- 4) INCUBATE: masih ada egg belum ready -> TETAP Core Team (speed), jangan switch/hatch
		ctx.state.hatchPhase = ("Incubating (%d/%d ready)"):format(#ready, placed)
		equipTeam(CFG.hatchCoreTeam, "Core Team")
		ctx.state.pnpBlockedByHatch = false
		ctx.state.hatchStatus = ("Nunggu egg ready (%d/%d)..."):format(#ready, placed)
	end

	local function loop()
		ctx.state.hatchId = (ctx.state.hatchId or 0) + 1
		local my = ctx.state.hatchId
		ctx.elevate()
		while CFG.hatchEnabled and ctx.alive() and ctx.state.hatchId == my do
			pcall(tick)
			task.wait(1.0)
		end
		ctx.state.hatchStatus = "Idle"
		ctx.state.pnpBlockedByHatch = false
		ctx.state.teamSwapActive = false
	end

	function ctx.startHatch()
		if ctx.cancelClearGarden then ctx.cancelClearGarden() end
		-- RESET semua statistik: tiap nyalain ulang mulai dari awal (webhook + live status)
		ctx.state.hatchEggsHatched = 0
		ctx.state.hatchRounds = 0
		ctx.state.hatchLastSellCycle = 0
		ctx.state.hatchReportSellProg = nil
		ctx.state.hatchSellCycles = 0
		ctx.state.hatchTiers = {}
		ctx.state.periodHatched = 0
		ctx.state.periodSold = 0
		ctx.state.periodHatchRec = 0
		ctx.state.periodSellRec = 0
		ctx.state.sellDoneThisReport = false
		ctx.state.hatchPendingReport = false
		ctx.state.hatchIsRejoining = false
		-- catat jumlah egg terpilih di awal (buat "Egg Before") = backpack + placed
		local eggName = CFG.hatchEggName or "Rare Egg"
		ctx.state.lastTrackedEggName = eggName
		ctx.state.hatchEggBefore = totalEggCount(eggName)
		ctx.state.hatchStartTime = os.time()
		ctx.state.hatchCycleStartTime = os.time()
		task.spawn(loop)
		task.spawn(sendStartHatchWebhook)
		if (CFG.hatchRejoinMinusEnabled or CFG.hatchRejoinPlusEnabled) and ctx.startEggMinusWatcher then
			ctx.startEggMinusWatcher()
		end
	end
	function ctx.stopHatch()
		ctx.state.hatchId = (ctx.state.hatchId or 0) + 1
		ctx.state.hatchStatus = "Idle"
		ctx.state.pnpBlockedByHatch = false
		ctx.state.teamSwapActive = false
	end

	----------------------------------------------------------------- AUTO FAVORITE
	-- Favoritin otomatis pet yg tipenya ada di CFG.favoritePetTypes (biar ga ke-sell).
	-- favoritePetTypes = key PET_OPTIONS (nama pet polos); tool attribute "f" = nama pet.
	function ctx.startAutoFavorite()
		ctx.state.autoFavId = (ctx.state.autoFavId or 0) + 1
		local my = ctx.state.autoFavId
		ctx.elevate()
		task.spawn(function()
			while CFG.autoFavorite and ctx.alive() and ctx.state.autoFavId == my do
				if next(CFG.favoritePetTypes or {}) then
					for _, t in ipairs(petTools()) do
						local pt = t:GetAttribute("f")
						local matchFav = pt and (ctx.petMatchesType and ctx.petMatchesType(CFG.favoritePetTypes, pt) or (CFG.favoritePetTypes)[pt])
						if matchFav and not isFav(t) then
							setFav(t, true)
						end
					end
				end
				task.wait(3)
			end
		end)
	end
	function ctx.stopAutoFavorite()
		ctx.state.autoFavId = (ctx.state.autoFavId or 0) + 1
	end

	----------------------------------------------------------------- AUTO UNFAVORITE
	-- Unfavoritin otomatis pet yg tipenya ada di CFG.unfavoritePetTypes (atau semua jika kosong).
	function ctx.startAutoUnfavorite()
		ctx.state.autoUnfavId = (ctx.state.autoUnfavId or 0) + 1
		local my = ctx.state.autoUnfavId
		ctx.elevate()
		task.spawn(function()
			while CFG.autoUnfavoritePets and ctx.alive() and ctx.state.autoUnfavId == my do
				for _, t in ipairs(petTools()) do
					local pt = t:GetAttribute("f")
					local match = (not next(CFG.unfavoritePetTypes or {})) or (pt and (ctx.petMatchesType and ctx.petMatchesType(CFG.unfavoritePetTypes, pt) or (CFG.unfavoritePetTypes)[pt]))
					if match and isFav(t) then
						setFav(t, false)
					end
				end
				task.wait(3)
			end
		end)
	end
	function ctx.stopAutoUnfavorite()
		ctx.state.autoUnfavId = (ctx.state.autoUnfavId or 0) + 1
	end

	----------------------------------------------------------------- EGG THRESHOLD WATCHER
	-- Watcher independen jika Auto Rejoin on Egg Minus / Plus diaktifkan, agar tetap terpantau
	-- meskipun Auto Hatch sedang idle atau di luar siklus hatch.
	local function eggMinusWatcherLoop(myId)
		while (CFG.hatchRejoinMinusEnabled or CFG.hatchRejoinPlusEnabled) and ctx.alive() and ctx.state.eggMinusWatchId == myId do
			-- Jika Auto Hatch aktif dan Auto Sell aktif, biarkan loop Auto Hatch yang mengecek setelah sell
			if not CFG.hatchEnabled or not CFG.autoSellEnabled then
				local shouldRejoin, rType, rEgg, rCur, rNet, rThresh = checkEggThreshold()
				if shouldRejoin then
					handleEggRejoin(rType, rEgg, rCur, rNet, rThresh)
					return
				end
			end
			task.wait(2.0)
		end
	end

	function ctx.startEggMinusWatcher()
		ctx.state.eggMinusWatchId = (ctx.state.eggMinusWatchId or 0) + 1
		local myId = ctx.state.eggMinusWatchId
		task.spawn(function() eggMinusWatcherLoop(myId) end)
	end
	function ctx.stopEggMinusWatcher()
		ctx.state.eggMinusWatchId = (ctx.state.eggMinusWatchId or 0) + 1
	end
end
