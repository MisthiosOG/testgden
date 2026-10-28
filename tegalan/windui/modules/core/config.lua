--[[ config.lua — CFG default + persist/load state JSON (garden). ]]
return function(ctx)
	local HttpService = ctx.Services.HttpService
	local Players = ctx.Services.Players or game:GetService("Players")

	-- 1. Pastikan LocalPlayer dan UserId sudah siap (hindari nil)
	local localPlayer = Players.LocalPlayer
	while not localPlayer do
		Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
		localPlayer = Players.LocalPlayer
	end
	local userId = localPlayer.UserId

	local CFG = {
		-- Automation Trade (Ticket)
		targetPlayer   = "",      -- nama player tujuan
		petTypes       = {},      -- set: {["Fire Wisp"]=true}; kosong = semua non-favorite
		weightFilter   = 0,       -- 0=off | +N = minimal Nkg | -N = maksimal Nkg
		ageFilter      = 0,       -- 0=off | +N = minimal age N | -N = maksimal age N
		petsPerTrade   = 12,
		totalTrades    = 14,
		autoUnfavorite = false,
		tradeEnabled   = false,   -- Enable Automation Trade (Ticket)
		tradeTicketEnabled = false,

		-- Automation Trade (Gift)
		giftTargetPlayer     = "",
		giftPetTypes         = {},
		giftWeightFilter     = 0,
		giftAgeFilter        = 0,
		giftPetsPerBatch     = 12,
		giftTotalGifts       = 100,
		giftAutoUnfavorite   = false,
		tradeGiftEnabled     = false,

		-- ===== Auto Hatch + Auto Sell =====
		hatchEnabled    = false,
		autoSellEnabled = false,
		-- teams (set uuid pet)
		hatchCoreTeam   = {},  -- team default/idle
		hatchHatchTeam  = {},  -- team saat hatch (recovery + speed)
		hatchBrontoTeam = {},  -- team bronto (hatch speed)
		hatchSellTeam   = {},  -- team saat jual (boost harga)
		-- egg config
		hatchEggName    = "Rare Egg", -- egg yg di-place & di-hatch
		hatchMaxPlaced  = 8,          -- target egg ke-place di garden
		hatchPlacePattern = "Grid",   -- pola taro egg: "Grid" (rapih) / "Random" (sebar acak)
		hatchTeamDelay  = 5.5,        -- detik tunggu abis swap team sebelum hatch
		hatchWebhookUrl   = "",       -- webhook Discord buat Hatch Alert (bronto)
		hatchAlertEnabled = false,    -- kirim alert pas pet masuk filter bronto
		hatchRejoinMinusEnabled   = false, -- Auto rejoin kalau egg minus
		hatchRejoinMinusThreshold = 20,    -- Threshold jumlah minus untuk trigger rejoin (misal: 20 -> <= -20)
		hatchRejoinPlusEnabled    = false, -- Auto rejoin kalau egg bertambah (plus)
		hatchRejoinPlusThreshold  = 20,    -- Threshold jumlah plus untuk trigger rejoin (misal: 20 -> >= +20)
		-- bronto config: egg yg pending pet-nya cocok -> hatch pakai Bronto team (+30% berat)
		brontoSpecialPets    = {},   -- set "Pet - Egg" (special: wajib bronto)
		brontoSpecialWeight  = 0,    -- special cuma kalau weight > ini (0 = ga difilter)
		brontoUniversalTypes = {},   -- set tipe pet buat aturan universal (kosong = semua)
		brontoUniversalWeight = 0,   -- pakai bronto kalau weight > ini (0 = off)
		brontoSkipSpecial    = false,-- jangan hatch special pet sama sekali
		brontoTeamDelay      = 5.5,  -- detik tunggu abis swap team sebelum hatch bronto
		-- sell config (filter = DIJUAL; sisanya difavoritin biar aman)
		sellPetTypes       = {},   -- set tipe pet yg dijual
		sellWeightThreshold = 5,   -- jual kalau BaseWeight < ini
		sellAgeThreshold    = 3,   -- jual kalau Age/Level < ini
		sellSpecialTypes    = {},  -- pet spesial (jual by weight)
		sellSpecialWeight   = 10,  -- 0=off
		sellMode   = "Cycle",      -- Cycle | Backpack
		sellStyle  = "All at Once",
		sellEveryNCycles = 1,
		sellWhenReach    = 100,    -- jual kalau backpack pet >= ini
		sellTeamDelay    = 5.5,    -- detik tunggu abis swap team sebelum jual
		autoBoostBeforeSell = false,
		hatchCoreEquipDelay   = 0,
		hatchCoreUnequipDelay = 1,
		hatchBrontoEquipDelay = 0,
		hatchBrontoUnequipDelay = 1,
		hatchTeamEquipDelay   = 0,
		hatchTeamUnequipDelay = 1,
		hatchSellEquipDelay   = 0,
		hatchSellUnequipDelay = 1,
		hatchSellList         = {}, -- { [petName] = { kg = 3, action = "SELL"|"KEEP" } }
		autoUnfavoritePets    = false,
		unfavoritePetTypes    = {},
		tradeMethod           = "ticket", -- "ticket" | "gift"

		-- Automation Accept
		acceptGifts   = false,
		acceptTrades  = false,

		-- Automation Favourite Pets (placeholder)
		autoFavorite      = false,
		favoritePetTypes  = {},

		-- PNP (Pick & Place) pet
		pnpPetTypes = {},     -- (lama) filter per-tipe; kosong = semua equipped
		-- PnP V1 (polling)
		pnpUuids    = {},     -- filter per-UUID pet equipped; kosong = semua equipped
		pickupDelay = 0.5,    -- jeda setelah skill mulai sebelum pet ditarik
		equipDelay  = 1e-20,  -- jeda tambahan unequip -> equip setelah server konfirmasi (1E-20 = tanpa jeda)
		pnpScanInterval = 0.5,  -- (nggak dipakai V1 lagi; timing dikunci di modul)
		pnpEnabled  = false,
		espEnabled  = false, -- ESP Label pet (label melayang di dunia)
		espMode     = "target", -- tampilan ESP pet: "target" (billboard di objek) / "screen" (panel di layar)
		espEggEnabled = false, -- ESP Egg (style NEBULA) — terpisah dari ESP pet
		espEggMode    = "target", -- tampilan ESP egg: "target" / "screen"
		espInvEnabled = false, -- ESP base weight di tiap slot pet inventory
		espInvMode  = "age",   -- tampilan ESP inv: "age" (base+age) / "max" (base+max@500)
		noclipEnabled    = false, -- Player: tembus tembok
		walkSpeedEnabled = false, -- Player: pakai custom walk speed
		walkSpeed        = 16,    -- Player: walk speed custom (default 16)
		infJumpEnabled   = false, -- Player: lompat tak terbatas di udara
		hideMyPlants     = false, -- Perf: sembunyiin plant kebun sendiri
		hideOtherPlants  = false, -- Perf: sembunyiin plant kebun lain
		autoRemoveWebFx  = false, -- Perf: auto hapus efek spider web
		perfMode         = "off", -- Perf: off / low / extreme
		disable3d        = false, -- Perf: matiin 3D rendering
		premiumItem      = "",     -- Premium Shop: key item terpilih (DevProductIds)
		premiumPay       = "robux",-- Premium Shop: robux / token

		-- Automation Leveling
		levelingTeamUuids   = {},
		levelingPetTypes    = {},
		levelingTargetLevel = 500,
		levelingMaxPets     = 2,
		levelingEnabled     = false,

		-- Automation Leveling V2 (2 phase)
		levelingV2PetTypes = {},
		levelingV2P1Team   = {},
		levelingV2P1Target = 40,
		levelingV2P1Max    = 3,
		levelingV2P2Team   = {},
		levelingV2P2Target = 500,
		levelingV2P2Max    = 1,
		levelingV2Enabled  = false,

		-- Growth (pipeline: Elephant -> Mutation -> Leveling, batch per-step, config TERPISAH)
		growthEnabled      = false,
		growthPetTypes     = {},                                                    -- target default (dipakai step yg per-step-nya kosong)
		growthFlow         = { "elephant", "mutation", "leveling" }, -- urutan Step 1/2/3
		-- target pet PER-METHOD (kalau kosong -> fallback ke growthPetTypes)
		growthPetTypesElephant = {},
		growthPetTypesMutation = {},
		growthPetTypesLeveling = {},
		-- step Elephant
		growthElephantTeam   = {},
		growthElephantWeight = 5.5,
		growthElephantMax    = 2,
		-- step Mutation (aura)
		growthMutationTeam    = {},
		growthMutationTargets = {},   -- target mutasi (mis. Ember/Nightmare/Rainbow)
		growthMutationMax     = 2,
		-- step Leveling (2 phase)
		growthLevP1Team   = {},
		growthLevP1Target = 40,
		growthLevP1Max    = 3,
		growthLevP2Team   = {},
		growthLevP2Target = 500,
		growthLevP2Max    = 1,

		-- Automation Mutation
		mutationExpTeam       = {},
		mutationBoostTeam     = {},
		mutationPhoenixTeam   = {},
		mutationTargetTypes   = {},
		mutationTargetMutations = {},
		mutationTargetAge     = 50,
		mutationDelayAutoClaim = 0.5,
		mutationEnabled       = false,

		-- Automation Shop (buy seed/egg/gear)
		buySeedNames   = {},
		buySeedEnabled = false,
		buyEggNames    = {},
		buyEggEnabled  = false,
		buyGearNames   = {},
		buyGearEnabled = false,

		-- Automation Merchant (Traveling Merchant auto-buy) — toggle bisa nyala barengan (union)
		merchantBuyEnabled = false,    -- Auto Buy Merchant: beli item terpilih (per-merchant)
		merchantBuyAll     = false,    -- Auto Buy All: beli semua item ada stock
		merchantBuyBest    = false,    -- Auto Buy Best: beli 1 item termahal ada stock
		merchantItems      = {},       -- selection PER-MERCHANT/EVENT: { [id] = {item=true} }
		merchantUiShop     = "",       -- Open UI: event shop yang mau dibuka UI-nya
		merchantAutoOpenUI = false,    -- Open UI: jaga UI shop terpilih tetap kebuka

		-- Automation Water (siram plant terpilih pakai Watering Can / Water_RE)
		waterFruitNames = {},
		waterEnabled    = false,
		waterDelay      = 1,

		-- Automation Shovel (hapus plant / fruit via Remove_Item)
		shovelTreeNames    = {},
		shovelTreeEnabled  = false,
		shovelTreeDelay    = 0,
		shovelFruitNames    = {},
		shovelFruitMuts     = {},
		shovelFruitVariants = {},
		shovelFruitMode     = ">= (berat minimal)",
		shovelFruitWeight   = 0,
		shovelFruitEnabled  = false,
		shovelFruitDelay    = 0,

		-- Automation Collection (harvest fruit via Crops.Collect)
		collectDelay          = 0,
		collectStopIfFull     = false,
		collectAutoSellIfFull = false,
		collectWlFruitNames   = {},
		collectWlFruitEnabled = false,
		collectWlMutNames     = {},
		collectWlMutEnabled   = false,
		collectCombFruitNames = {},
		collectCombMutNames   = {},
		collectCombVariants   = {},
		collectCombMode       = ">= (berat minimal)",
		collectCombWeight     = 0,
		collectCombEnabled    = false,
		-- Blacklist Mutation: collect SEMUA buah bermutasi kecuali mutasi yang di-blacklist
		-- (buah tanpa mutasi nggak di-collect)
		collectBlMutNames     = {},
		collectBlMutEnabled   = false,

		-- Automation Favorite (favorite/unfavorite fruit via Favorite Tool)
		favFruitNames = {},
		favMutNames   = {},
		favMode       = ">= (berat minimal)",
		favWeight     = 0,
		favDelay      = 1,
		favEnabled    = false,
		unfavEnabled  = false,

		-- Automation Reclaimer (Farm): reclaim plant terpilih pakai tool Reclaimer
		reclaimPlantNames = {},
		reclaimEnabled    = false,
		reclaimSpeed      = 0.15,

		-- Automation Plants (Farm): tanam seed dari inventory
		plantSeedNames   = {},
		plantPosition    = "Random",
		plantDelay       = 0,
		goodClear        = true,
		plantSeedEnabled = false,

		-- Automation Sprinkler (Farm): pasang + shovel sprinkler
		sprinklerNames        = {},
		sprinklerPlantNames   = {},
		sprinklerPosition     = "Random",
		sprinklerDelay        = 0,
		sprinklerEnabled      = false,
		shovelSprinklerNames  = {},
		shovelSprinklerDelay  = 0,
		shovelSprinklerEnabled = false,

		-- Auto GM Sprinkler (tab Hatch): jaga 1 Grandmaster Sprinkler terpasang
		gmSprinklerEnabled     = false,

		-- Auto-Reconnect (Misc): auto rejoin kalau ke-kick / disconnect (seperti di Trade)
		autoReconnect     = true,

		-- Automation Reconnect (Misc): auto rejoin tiap interval
		reconnectEnabled  = false,
		reconnectInterval = 5,   -- menit

		-- Automation Cleanse Mutation (mutasi via aura + cleanse)
		cleanseTeamUuids     = {},   -- Pet Team for Mutation (aura pemberi mutasi)
		cleansePetTypes      = {},   -- Pet Types for Mutation (target)
		cleanseKeepMutations = {},   -- Mutations to Keep (won't cleanse)
		cleanseMaxPets       = 2,    -- Max Pets in Garden (target)
		cleanseEnabled       = false,

		-- Automation Boost Pet
		boostPetUuids  = {},
		boostItemNames = {},
		boostEnabled   = false,

		-- Automation Elephant (V1)
		elephantTeamUuids   = {},
		elephantPetTypes    = {},
		elephantTargetWeight = 5.5,
		elephantMaxPets     = 2,
		elephantEnabled     = false,
		-- Elephant V2: swap gajah keluar-masuk saat target hit level 40 (barengan PNP)
		elephantV2Team      = {},   -- sumber pet Switch (team standby di garden)
		elephantV2Types     = {},   -- tipe pet target yg dipantau levelnya
		elephantV2Weight    = 5.5,  -- berat max target sebelum dilepas
		elephantV2MaxPets   = 3,    -- jumlah pet target aktif barengan
		elephantV2Gajah     = "",   -- uuid pet gajah (booster berat)
		elephantV2Switch    = "",   -- uuid pet team yg ditukar sama gajah
		elephantV2Level     = 40,   -- ambang level target buat masukin gajah
		elephantV2Interval  = 0.1,  -- interval baca level (detik)
		elephantV2Enabled   = false,

		-- Automation Event: Beanstalk (NPC Jack) — feed plant sesuai craving trait
		beanstalkPlantEnabled   = false, -- auto tanam seed craving
		beanstalkCollectEnabled = false, -- auto panen fruit craving
		beanstalkSubmitEnabled  = false, -- auto setor produce craving ke beanstalk
		beanstalkClaimEnabled   = false, -- auto claim reward beanstalk (reward point aktif)
		beanstalkAutoSellEnabled= false, -- backpack mentok (trait salah) -> jual SEMUA backpack
		beanstalkHopEnabled     = false, -- auto hop server sampai nemu beanstalk growth < 900
		beanstalkPlantCount     = 20,    -- target jumlah tanam per siklus
		beanstalkDelay          = 0.2,   -- jeda antar aksi (detik)
		buyBeanstalkShopNames   = {},    -- item Beanstalk Event Shop (Goliath's Goods/Friends Deals)
		buyBeanstalkShopEnabled = false,

		-- webhook (opsional)
		webhookUrl     = "",
		webhookEnabled = false,
	}

	-- Setiap clone punya file terpisah. Tujuh executor, tujuh tingkah: yang
	-- nolak write di root, yang nolak slash, yang cuma nerima backslash, yang
	-- VFS-nya ngaco. Jadi simpan ke SEMUA kandidat path (murah), dan saat load
	-- baca yang pertama ketemu. Paling nggak SATU pasti lengket.
	local STORAGE_DIR = "CeszParadiseWindUI"
	pcall(makefolder, STORAGE_DIR)
	local baseName = "state_" .. tostring(userId) .. ".json"
	local legacyName = "garden_state_" .. tostring(userId) .. ".json"
	local STATE_CANDIDATES = {
		baseName,              -- root, format baru (REAL & mayoritas executor: root OK)
		legacyName,            -- root, format lama (kompat garden build)
		STORAGE_DIR .. "/" .. baseName,
		STORAGE_DIR .. "\\" .. baseName,
		STORAGE_DIR .. "\\" .. baseName:gsub("%.", "_") .. ".json", -- netral buat VFS aneh
	}
	-- FS helper: semua akses lewat pcall supaya executor yang nge-throw
	-- di writefile/readfile gak bikin config module mati.
	local function fsIsFile(p)
		if type(isfile) == "function" then return pcall(isfile, p) and isfile(p) or false end
		return false
	end
	local function fsRead(p)
		if type(readfile) == "function" then
			local ok, r = pcall(readfile, p)
			if ok then return r end
		end
		return nil
	end
	local function fsWrite(p, content)
		if type(writefile) == "function" then
			local ok, err = pcall(writefile, p, content)
			return ok, err
		end
		return false, "no writefile"
	end
	local statePathUsed = nil

	local function findStatePath()
		for _, p in ipairs(STATE_CANDIDATES) do
			if fsIsFile(p) then return p end
		end
		return nil
	end

	-- Migrasi file lama yang pernah tersimpan di root (jangan hilangkan setting).
	do
		local target = STATE_CANDIDATES[1]
		local okWriteFlag = false
		pcall(function()
			if fsIsFile(legacyName) and not fsIsFile(target) then
				local old = fsRead(legacyName)
				if old and #old > 0 then
					okWriteFlag = fsWrite(target, old)
					print("[GAGHub][WINDUI] config migrated: " .. legacyName .. " -> " .. target)
				end
			end
		end)
	end

	-- 1. Simpan ke SEMUA kandidat path (paling mentok satu pasti nyantol)
	local function persistState()
		local okAny = false
		if type(writefile) == "function" then
			local okSer, ser = pcall(function() return HttpService:JSONEncode(CFG) end)
			if okSer then
				for _, p in ipairs(STATE_CANDIDATES) do
					local okw = pcall(writefile, p, ser)
					if okw then
						okAny = true
						statePathUsed = p
					end
				end
			end
		end
		return okAny
	end

	-- 2. Muat dari kandidat pertama yang ada
	local function loadState()
		local path = findStatePath()
		if path then
			local raw = fsRead(path)
			if raw and #raw > 0 then
				local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
				if ok and type(data) == "table" then
					statePathUsed = path
					return data
				end
			end
		end
		return nil
	end

	do
		local st = loadState()
		if st then
			print("[GAGHub][WINDUI] config loaded")
			local function tbl(v) return (type(v) == "table") and v or {} end
			local function migratePetSet(t)
				if type(t) ~= "table" then return {} end
				local out = {}
				local petEggLabel = ctx.petEggLabel or (ctx.reg and ctx.reg.petEggLabel)
				for k, v in pairs(t) do
					local newK = petEggLabel and petEggLabel(k) or k
					out[newK] = v
				end
				return out
			end

			CFG.targetPlayer   = st.targetPlayer or ""
			CFG.petTypes       = migratePetSet(st.petTypes)
			CFG.weightFilter   = tonumber(st.weightFilter) or 0
			CFG.ageFilter      = tonumber(st.ageFilter) or 0
			CFG.petsPerTrade   = tonumber(st.petsPerTrade) or 12
			CFG.totalTrades    = tonumber(st.totalTrades) or 14
			CFG.autoUnfavorite = st.autoUnfavorite or false
			CFG.tradeEnabled   = st.tradeEnabled or false
			CFG.tradeTicketEnabled = st.tradeTicketEnabled or st.tradeEnabled or false

			CFG.giftTargetPlayer     = st.giftTargetPlayer or ""
			CFG.giftPetTypes         = migratePetSet(st.giftPetTypes)
			CFG.giftWeightFilter     = tonumber(st.giftWeightFilter) or 0
			CFG.giftAgeFilter        = tonumber(st.giftAgeFilter) or 0
			CFG.giftPetsPerBatch     = tonumber(st.giftPetsPerBatch) or 12
			CFG.giftTotalGifts       = tonumber(st.giftTotalGifts) or 100
			CFG.giftAutoUnfavorite   = st.giftAutoUnfavorite or false
			CFG.tradeGiftEnabled     = st.tradeGiftEnabled or false
			-- Auto Hatch + Auto Sell
			CFG.hatchEnabled    = st.hatchEnabled or false
			CFG.autoSellEnabled = st.autoSellEnabled or false
			CFG.hatchCoreTeam   = tbl(st.hatchCoreTeam)
			CFG.hatchHatchTeam  = tbl(st.hatchHatchTeam)
			CFG.hatchBrontoTeam = tbl(st.hatchBrontoTeam)
			CFG.hatchSellTeam   = tbl(st.hatchSellTeam)
			CFG.hatchEggName    = st.hatchEggName or "Rare Egg"
			CFG.hatchMaxPlaced  = tonumber(st.hatchMaxPlaced) or 8
			CFG.hatchPlacePattern = st.hatchPlacePattern or "Grid"
			CFG.hatchTeamDelay  = tonumber(st.hatchTeamDelay) or 5.5
			CFG.hatchSpeed      = tonumber(st.hatchSpeed) or 0
			CFG.hatchWebhookUrl   = st.hatchWebhookUrl or ""
			CFG.hatchAlertEnabled = st.hatchAlertEnabled or false
			CFG.hatchRejoinMinusEnabled   = st.hatchRejoinMinusEnabled or false
			CFG.hatchRejoinMinusThreshold = tonumber(st.hatchRejoinMinusThreshold) or 20
			CFG.hatchRejoinPlusEnabled    = st.hatchRejoinPlusEnabled or false
			CFG.hatchRejoinPlusThreshold  = tonumber(st.hatchRejoinPlusThreshold) or 20
			CFG.brontoSpecialPets    = tbl(st.brontoSpecialPets)
			CFG.brontoSpecialWeight  = tonumber(st.brontoSpecialWeight) or 0
			CFG.brontoUniversalTypes = tbl(st.brontoUniversalTypes)
			CFG.brontoUniversalWeight = tonumber(st.brontoUniversalWeight) or 0
			CFG.brontoSkipSpecial    = st.brontoSkipSpecial or false
			CFG.brontoTeamDelay      = tonumber(st.brontoTeamDelay) or 5.5
			CFG.sellPetTypes    = tbl(st.sellPetTypes)
			CFG.sellWeightThreshold = tonumber(st.sellWeightThreshold) or 5
			CFG.sellAgeThreshold    = tonumber(st.sellAgeThreshold) or 3
			CFG.sellSpecialTypes    = tbl(st.sellSpecialTypes)
			CFG.sellSpecialWeight   = tonumber(st.sellSpecialWeight) or 10
			CFG.sellMode   = st.sellMode or "Cycle"
			CFG.sellStyle  = st.sellStyle or "All at Once"
			CFG.sellEveryNCycles = tonumber(st.sellEveryNCycles) or 1
			CFG.sellWhenReach    = tonumber(st.sellWhenReach) or 100
			CFG.sellTeamDelay    = tonumber(st.sellTeamDelay) or 5.5
			CFG.autoBoostBeforeSell = st.autoBoostBeforeSell or false
			CFG.hatchCoreEquipDelay   = tonumber(st.hatchCoreEquipDelay) or 0
			CFG.hatchCoreUnequipDelay = tonumber(st.hatchCoreUnequipDelay) or 1
			CFG.hatchBrontoEquipDelay = tonumber(st.hatchBrontoEquipDelay) or 0
			CFG.hatchBrontoUnequipDelay = tonumber(st.hatchBrontoUnequipDelay) or 1
			CFG.hatchTeamEquipDelay   = tonumber(st.hatchTeamEquipDelay) or 0
			CFG.hatchTeamUnequipDelay = tonumber(st.hatchTeamUnequipDelay) or 1
			CFG.hatchSellEquipDelay   = tonumber(st.hatchSellEquipDelay) or 0
			CFG.hatchSellUnequipDelay = tonumber(st.hatchSellUnequipDelay) or 1
			CFG.hatchSellList         = migratePetSet(st.hatchSellList)
			CFG.autoUnfavoritePets    = st.autoUnfavoritePets or false
			CFG.unfavoritePetTypes    = migratePetSet(st.unfavoritePetTypes)
			CFG.tradeMethod           = st.tradeMethod or "ticket"
			CFG.acceptGifts    = st.acceptGifts or false
			CFG.acceptTrades   = st.acceptTrades or false
			CFG.autoFavorite   = st.autoFavorite or false
			CFG.favoritePetTypes = migratePetSet(st.favoritePetTypes)
			CFG.pnpPetTypes = (type(st.pnpPetTypes) == "table") and st.pnpPetTypes or {}
			CFG.pnpUuids    = (type(st.pnpUuids) == "table") and st.pnpUuids or {}
			CFG.pickupDelay = tonumber(st.pickupDelay) or 0.5
			CFG.equipDelay  = tonumber(st.equipDelay) or 1e-20
			CFG.pnpScanInterval = tonumber(st.pnpScanInterval) or 0.5
			CFG.pnpEnabled  = st.pnpEnabled or false
			CFG.espEnabled = st.espEnabled or false
			CFG.espMode = st.espMode or "target"
			CFG.espEggEnabled = st.espEggEnabled or false
			CFG.espEggMode = st.espEggMode or "target"
			CFG.espInvEnabled = st.espInvEnabled or false
			CFG.espInvMode = st.espInvMode or "age"
			CFG.noclipEnabled = st.noclipEnabled or false
			CFG.walkSpeedEnabled = st.walkSpeedEnabled or false
			CFG.walkSpeed = tonumber(st.walkSpeed) or 16
			CFG.infJumpEnabled = st.infJumpEnabled or false
			CFG.hideMyPlants = st.hideMyPlants or false
			CFG.hideOtherPlants = st.hideOtherPlants or false
			CFG.autoRemoveWebFx = st.autoRemoveWebFx or false
			CFG.perfMode = st.perfMode or "off"
			CFG.disable3d = st.disable3d or false
			CFG.premiumItem = st.premiumItem or ""
			CFG.premiumPay = st.premiumPay or "robux"
			
			CFG.levelingTeamUuids   = (type(st.levelingTeamUuids) == "table") and st.levelingTeamUuids or {}
			CFG.levelingPetTypes    = migratePetSet(st.levelingPetTypes)
			CFG.levelingTargetLevel = tonumber(st.levelingTargetLevel) or 500
			CFG.levelingMaxPets     = tonumber(st.levelingMaxPets) or 2
			CFG.levelingEnabled     = st.levelingEnabled or false

			-- Leveling V2
			CFG.levelingV2PetTypes = migratePetSet(st.levelingV2PetTypes)
			CFG.levelingV2P1Team   = (type(st.levelingV2P1Team) == "table") and st.levelingV2P1Team or {}
			CFG.levelingV2P1Target = tonumber(st.levelingV2P1Target) or 40
			CFG.levelingV2P1Max    = tonumber(st.levelingV2P1Max) or 3
			CFG.levelingV2P2Team   = (type(st.levelingV2P2Team) == "table") and st.levelingV2P2Team or {}
			CFG.levelingV2P2Target = tonumber(st.levelingV2P2Target) or 500
			CFG.levelingV2P2Max    = tonumber(st.levelingV2P2Max) or 1
			CFG.levelingV2Enabled  = st.levelingV2Enabled or false

			-- Growth
			CFG.growthEnabled  = st.growthEnabled or false
			CFG.growthPetTypes = migratePetSet(st.growthPetTypes)
			CFG.growthPetTypesElephant = migratePetSet(st.growthPetTypesElephant)
			CFG.growthPetTypesMutation = migratePetSet(st.growthPetTypesMutation)
			CFG.growthPetTypesLeveling = migratePetSet(st.growthPetTypesLeveling)
			CFG.growthFlow     = (type(st.growthFlow) == "table") and st.growthFlow or { "elephant", "mutation", "leveling" }
			CFG.growthElephantTeam   = (type(st.growthElephantTeam) == "table") and st.growthElephantTeam or {}
			CFG.growthElephantWeight = tonumber(st.growthElephantWeight) or 5.5
			CFG.growthElephantMax    = tonumber(st.growthElephantMax) or 2
			CFG.growthMutationTeam    = (type(st.growthMutationTeam) == "table") and st.growthMutationTeam or {}
			CFG.growthMutationTargets = (type(st.growthMutationTargets) == "table") and st.growthMutationTargets or {}
			CFG.growthMutationMax     = tonumber(st.growthMutationMax) or 2
			CFG.growthLevP1Team   = (type(st.growthLevP1Team) == "table") and st.growthLevP1Team or {}
			CFG.growthLevP1Target = tonumber(st.growthLevP1Target) or 40
			CFG.growthLevP1Max    = tonumber(st.growthLevP1Max) or 3
			CFG.growthLevP2Team   = (type(st.growthLevP2Team) == "table") and st.growthLevP2Team or {}
			CFG.growthLevP2Target = tonumber(st.growthLevP2Target) or 500
			CFG.growthLevP2Max    = tonumber(st.growthLevP2Max) or 1

			-- Automation Mutation
			CFG.mutationExpTeam       = (type(st.mutationExpTeam) == "table") and st.mutationExpTeam or {}
			CFG.mutationBoostTeam     = (type(st.mutationBoostTeam) == "table") and st.mutationBoostTeam or {}
			CFG.mutationPhoenixTeam   = (type(st.mutationPhoenixTeam) == "table") and st.mutationPhoenixTeam or {}
			CFG.mutationTargetTypes   = migratePetSet(st.mutationTargetTypes)
			CFG.mutationTargetMutations = (type(st.mutationTargetMutations) == "table") and st.mutationTargetMutations or {}
			CFG.mutationTargetAge     = tonumber(st.mutationTargetAge) or 50
			CFG.mutationDelayAutoClaim = tonumber(st.mutationDelayAutoClaim) or 0.5
			CFG.mutationEnabled       = st.mutationEnabled or false

			CFG.buySeedNames   = (type(st.buySeedNames) == "table") and st.buySeedNames or {}
			CFG.buySeedEnabled = st.buySeedEnabled or false
			CFG.buyEggNames    = (type(st.buyEggNames) == "table") and st.buyEggNames or {}
			CFG.buyEggEnabled  = st.buyEggEnabled or false
			CFG.buyGearNames   = (type(st.buyGearNames) == "table") and st.buyGearNames or {}
			CFG.buyGearEnabled = st.buyGearEnabled or false

			CFG.merchantBuyEnabled = st.merchantBuyEnabled or false
			CFG.merchantBuyAll     = st.merchantBuyAll or false
			CFG.merchantBuyBest    = st.merchantBuyBest or false
			CFG.merchantItems      = (type(st.merchantItems) == "table") and st.merchantItems or {}
			CFG.merchantUiShop     = st.merchantUiShop or ""
			CFG.merchantAutoOpenUI = st.merchantAutoOpenUI or false

			CFG.waterFruitNames = (type(st.waterFruitNames) == "table") and st.waterFruitNames or {}
			CFG.waterEnabled    = st.waterEnabled or false
			CFG.waterDelay      = tonumber(st.waterDelay) or 1

			CFG.shovelTreeNames    = (type(st.shovelTreeNames) == "table") and st.shovelTreeNames or {}
			CFG.shovelTreeEnabled  = st.shovelTreeEnabled or false
			CFG.shovelTreeDelay    = tonumber(st.shovelTreeDelay) or 0
			CFG.shovelFruitNames    = (type(st.shovelFruitNames) == "table") and st.shovelFruitNames or {}
			CFG.shovelFruitMuts     = (type(st.shovelFruitMuts) == "table") and st.shovelFruitMuts or {}
			CFG.shovelFruitVariants = (type(st.shovelFruitVariants) == "table") and st.shovelFruitVariants or {}
			CFG.shovelFruitMode     = st.shovelFruitMode or ">= (berat minimal)"
			CFG.shovelFruitWeight   = tonumber(st.shovelFruitWeight) or 0
			CFG.shovelFruitEnabled  = st.shovelFruitEnabled or false
			CFG.shovelFruitDelay    = tonumber(st.shovelFruitDelay) or 0

			CFG.collectDelay          = tonumber(st.collectDelay) or 0
			CFG.collectStopIfFull     = st.collectStopIfFull or false
			CFG.collectAutoSellIfFull = st.collectAutoSellIfFull or false
			CFG.collectWlFruitNames   = (type(st.collectWlFruitNames) == "table") and st.collectWlFruitNames or {}
			CFG.collectWlFruitEnabled = st.collectWlFruitEnabled or false
			CFG.collectWlMutNames     = (type(st.collectWlMutNames) == "table") and st.collectWlMutNames or {}
			CFG.collectWlMutEnabled   = st.collectWlMutEnabled or false
			CFG.collectCombFruitNames = (type(st.collectCombFruitNames) == "table") and st.collectCombFruitNames or {}
			CFG.collectCombMutNames   = (type(st.collectCombMutNames) == "table") and st.collectCombMutNames or {}
			CFG.collectCombVariants   = (type(st.collectCombVariants) == "table") and st.collectCombVariants or {}
			CFG.collectCombMode       = st.collectCombMode or ">= (berat minimal)"
			CFG.collectCombWeight     = tonumber(st.collectCombWeight) or 0
			CFG.collectCombEnabled    = st.collectCombEnabled or false
			CFG.collectBlMutNames     = (type(st.collectBlMutNames) == "table") and st.collectBlMutNames or {}
			CFG.collectBlMutEnabled   = st.collectBlMutEnabled or false

			CFG.favFruitNames = (type(st.favFruitNames) == "table") and st.favFruitNames or {}
			CFG.favMutNames   = (type(st.favMutNames) == "table") and st.favMutNames or {}
			CFG.favMode       = st.favMode or ">= (berat minimal)"
			CFG.favWeight     = tonumber(st.favWeight) or 0
			CFG.favDelay      = tonumber(st.favDelay) or 1
			CFG.favEnabled    = st.favEnabled or false
			CFG.unfavEnabled  = st.unfavEnabled or false

			CFG.reclaimPlantNames = (type(st.reclaimPlantNames) == "table") and st.reclaimPlantNames or {}
			CFG.reclaimEnabled    = st.reclaimEnabled or false
			CFG.reclaimSpeed      = tonumber(st.reclaimSpeed) or 0.15
			CFG.plantSeedNames   = (type(st.plantSeedNames) == "table") and st.plantSeedNames or {}
			local pp = st.plantPosition
			if pp == "God Position" then pp = "Good Position" end -- rename lama
			CFG.plantPosition    = (pp == "Player Position" or pp == "Good Position") and pp or "Random"
			CFG.goodClear        = (st.goodClear ~= false)
			CFG.plantDelay       = tonumber(st.plantDelay) or 0
			CFG.plantSeedEnabled = st.plantSeedEnabled or false
			CFG.sprinklerNames        = (type(st.sprinklerNames) == "table") and st.sprinklerNames or {}
			CFG.sprinklerPlantNames   = (type(st.sprinklerPlantNames) == "table") and st.sprinklerPlantNames or {}
			CFG.sprinklerPosition     = (st.sprinklerPosition == "Player Position") and "Player Position" or "Random"
			CFG.sprinklerDelay        = tonumber(st.sprinklerDelay) or 0
			CFG.sprinklerEnabled      = st.sprinklerEnabled or false
			CFG.shovelSprinklerNames  = (type(st.shovelSprinklerNames) == "table") and st.shovelSprinklerNames or {}
			CFG.shovelSprinklerDelay  = tonumber(st.shovelSprinklerDelay) or 0
			CFG.shovelSprinklerEnabled = st.shovelSprinklerEnabled or false
			CFG.gmSprinklerEnabled    = st.gmSprinklerEnabled or false
			if st.autoReconnect ~= nil then CFG.autoReconnect = st.autoReconnect end
			CFG.reconnectEnabled  = st.reconnectEnabled or false
			CFG.reconnectInterval = tonumber(st.reconnectInterval) or 5

			CFG.cleanseTeamUuids     = (type(st.cleanseTeamUuids) == "table") and st.cleanseTeamUuids or {}
			CFG.cleansePetTypes      = migratePetSet(st.cleansePetTypes)
			CFG.cleanseKeepMutations = (type(st.cleanseKeepMutations) == "table") and st.cleanseKeepMutations or {}
			CFG.cleanseMaxPets       = tonumber(st.cleanseMaxPets) or 2
			CFG.cleanseEnabled       = st.cleanseEnabled or false

			CFG.boostPetUuids  = (type(st.boostPetUuids) == "table") and st.boostPetUuids or {}
			CFG.boostItemNames = (type(st.boostItemNames) == "table") and st.boostItemNames or {}
			CFG.boostEnabled   = st.boostEnabled or false

			CFG.elephantTeamUuids   = (type(st.elephantTeamUuids) == "table") and st.elephantTeamUuids or {}
			CFG.elephantPetTypes    = migratePetSet(st.elephantPetTypes)
			CFG.elephantTargetWeight = tonumber(st.elephantTargetWeight) or 5.5
			CFG.elephantMaxPets     = tonumber(st.elephantMaxPets) or 2
			CFG.elephantEnabled     = st.elephantEnabled or false
			CFG.elephantV2Team      = (type(st.elephantV2Team) == "table") and st.elephantV2Team or {}
			CFG.elephantV2Types     = migratePetSet(st.elephantV2Types)
			CFG.elephantV2Weight    = tonumber(st.elephantV2Weight) or 5.5
			CFG.elephantV2MaxPets   = tonumber(st.elephantV2MaxPets) or 3
			CFG.elephantV2Gajah     = (type(st.elephantV2Gajah) == "string") and st.elephantV2Gajah or ""
			CFG.elephantV2Switch    = (type(st.elephantV2Switch) == "string") and st.elephantV2Switch or ""
			CFG.elephantV2Level     = tonumber(st.elephantV2Level) or 40
			CFG.elephantV2Interval  = tonumber(st.elephantV2Interval) or 0.1
			CFG.elephantV2Enabled   = st.elephantV2Enabled or false

			CFG.beanstalkPlantEnabled   = st.beanstalkPlantEnabled or false
			CFG.beanstalkCollectEnabled = st.beanstalkCollectEnabled or false
			CFG.beanstalkSubmitEnabled  = st.beanstalkSubmitEnabled or false
			CFG.beanstalkClaimEnabled   = st.beanstalkClaimEnabled or false
			CFG.beanstalkAutoSellEnabled= st.beanstalkAutoSellEnabled or false
			CFG.beanstalkHopEnabled     = st.beanstalkHopEnabled or false
			CFG.beanstalkPlantCount     = tonumber(st.beanstalkPlantCount) or 20
			CFG.beanstalkDelay          = tonumber(st.beanstalkDelay) or 0.2
			CFG.buyBeanstalkShopNames   = (type(st.buyBeanstalkShopNames) == "table") and st.buyBeanstalkShopNames or {}
			CFG.buyBeanstalkShopEnabled = st.buyBeanstalkShopEnabled or false

			CFG.webhookUrl     = st.webhookUrl or ""
			CFG.webhookEnabled = st.webhookEnabled or false

			-- Bukti restore yang kelihatan di UI (Settings > Config Status).
			local nKeys = 0
			for _ in pairs(st) do nKeys = nKeys + 1 end
			ctx.state.cfgLoadInfo = "LOADED " .. tostring(nKeys)
				.. " settings from " .. tostring(statePathUsed or "file")
			print("[GAGHub][WINDUI] " .. ctx.state.cfgLoadInfo)
		else
			print("[GAGHub][WINDUI] config: no saved state, defaults")
		end
	end

	ctx.CFG = CFG

	------------------------------------------------------------------ Autosave
	-- Safety net di atas save-on-change dari UI (toggle/input/dropdown sudah
	-- persist instan): dirty-check tiap 10s nangkep perubahan CFG dari runtime
	-- module + flush terakhir saat client mati (BindToClose).
	-- Error FS TIDAK di-swallow: catat 1x ke log biar ketahuan kenapa config
	-- nggak nempel di executor tertentu (no writefile / write ditolak).
	local lastSaved = nil
	local fsWarned = false
	-- config.lua jalan SEBELUM window.lua, jadi ctx.log belum ada -> log manual
	-- via logLines biar statusnya cumul terlihat di Settings > Logs.
	local earlyLog = ctx.log
	if type(earlyLog) ~= "function" then
		earlyLog = function(msg)
			local L = ctx.state and ctx.state.logLines
			if L then L[#L + 1] = os.date("%H:%M:%S ") .. tostring(msg) end
			print("[WindUIHub] " .. tostring(msg))
		end
	end
	-- jsonSafe CFG runtime bisa nyampur nilai non-JSON (fungsi, Instance, NaN)
	-- -> JSONEncode nge-throw -> file gak pernah ketulis & folder kosong.
	-- Drop-in clone yang cuma nyimpen number/string/boolean/table polos.
	local function jsonSafe(v, depth)
		local t = type(v)
		if t == "number" then
			if v ~= v or v == math.huge or v == -math.huge then return 0 end
			return v
		elseif t == "string" or t == "boolean" then
			return v
		elseif t == "table" and depth < 9 then
			local out = {}
			for k, val in pairs(v) do
				local kt = type(k)
				if kt == "string" or kt == "number" then
					local sv = jsonSafe(val, depth + 1)
					if sv ~= nil then out[k] = sv end
				end
			end
			return out
		end
		return nil
	end
	local function autoSave()
		if type(writefile) ~= "function" then return end
		-- jsonSafe: BGANYA executor JSONEncode-nya nge-throw kalau CFG kecampur
		-- fungsi/instance/NaN (module runtime bisa nambahin) -> file gak pernah
		-- ketulis & folder tetap kosong. Bersihin dulu: cuma angka/string/boolean
		-- yang lolos, sisanya dibuang. 1e-20 aman, hasil string pasti encodable.
		local ok, ser = pcall(function()
			return HttpService:JSONEncode(jsonSafe(CFG, 0))
		end)
		if not ok then
			if not fsWarned then
				fsWarned = true
				earlyLog("autosave FAIL (encode): " .. tostring(ser))
			end
			return
		end
		if lastSaved == ser then return end
		-- Backup rotasi: sebelum nimpa file utama, arsipkan isi lamanya ke .bak.
		-- Kalau ada wipe aneh, selalu ada jalan pulang satu langkah.
		if type(readfile) == "function" and type(writefile) == "function" then
			pcall(function()
				local mainP = STATE_CANDIDATES[1]
				local old = readfile(mainP)
				if old and #old > 0 and old ~= ser then
					writefile(mainP .. ".bak", old)
				end
			end)
		end
		-- Tulis ke SEMUA kandidat: VFS executor beda-beda tingkahnya, dan
		-- satu path yang nyantol itu semua yang dibutuhkan buat load balik.
		local wroteAny = false
		for _, p in ipairs(STATE_CANDIDATES) do
			local okw = pcall(writefile, p, ser)
			if okw then
				wroteAny = true
				statePathUsed = p
			end
		end
		if wroteAny then
			lastSaved = ser
		elseif not fsWarned then
			fsWarned = true
			earlyLog("autosave FAIL (write): semua kandidat path ditolak executor")
		end
	end

	ctx.persistState = function()
		lastSaved = nil
		autoSave()
	end

	task.spawn(function()
		while true do
			task.wait(10)
			autoSave()
		end
	end)
	pcall(function() game:BindToClose(autoSave) end)

	-- Probe filesystem tiap kandidat: tulis 1 byte + baca balik. JANGAN break
	-- di kandidat pertama (executor bisa nolak slash tapi terima backslash).
	pcall(function()
		ctx.CFG_STATE_PATH = STATE_CANDIDATES[1]
		ctx.CFG_STATE_CANDIDATES = STATE_CANDIDATES
	end)
	task.spawn(function()
		local okPaths, badPaths = {}, {}
		if type(writefile) == "function" and type(readfile) == "function" then
			for _, p in ipairs(STATE_CANDIDATES) do
				pcall(function()
					local pf = p .. ".probe"
					writefile(pf, "1")
					if readfile(pf) == "1" then
						okPaths[#okPaths + 1] = p
					else
						badPaths[#badPaths + 1] = p
					end
					pcall(delfile, pf)
				end)
			end
		end
		local summary
		if #okPaths > 0 then
			summary = "Config storage OK via: " .. table.concat(okPaths, ", ")
			if #badPaths > 0 then
				summary = summary .. "  |  rejected: " .. table.concat(badPaths, ", ")
			end
		else
			summary = "Config storage MATI di executor ini (writefile/readfile gagal semua)"
		end
		ctx.state.fsStatus = summary
		earlyLog(summary)
		-- Toast PENDEK: path utama aja, satu baris (nungulin semua kandidat
		-- path = notif numpuk jelek). Detail lengkup tetap kebaca di panel
		-- Config Status & tab Logs.
		local toast
		if #okPaths > 0 then
			toast = "Config OK: " .. okPaths[1]
		else
			toast = "Config storage MATI - cek tab Settings"
		end
		task.delay(4.5, function()
			if ctx.wi and ctx.wi.notify then
				pcall(function() ctx.wi.notify("Config", toast, 4) end)
			end
		end)
	end)
end