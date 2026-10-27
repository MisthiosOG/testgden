--[[ pages.lua — halaman garden. Tab: Pet, Elephant, Growth, Leveling, Mutation, Event, Inventory, Shop, Misc.
     Isi utama ada di tab Inventory (Automation Trade + Automation Accept + Automation Favourite). ]]
return function(ctx)
	local C = ctx.C
	local F = ctx.F
	local CFG = ctx.CFG
	local mk, corner, stroke, pad = ctx.mk, ctx.corner, ctx.stroke, ctx.pad
	local persist = ctx.persistState
	local reg = ctx.reg
	local function log(m) ctx.log(m) end

	-- True kalau GuiObject benar-benar kelihatan di layar (tab aktif + accordion kebuka
	-- + window ga diminimize). Dipakai supaya loop status berhenti hitung/redraw label
	-- yang lagi nggak dilihat — cegah layout-thrashing yang bikin CPU naik.
	local function onScreen(o)
		while o and o ~= game do
			if o:IsA("GuiObject") and not o.Visible then return false end
			o = o.Parent
		end
		return o == game
	end

	local makePage = ctx.makePage
	local makeAccordion = ctx.makeAccordion
	local makeToggle = ctx.makeToggle
	local makeInput = ctx.makeInput
	local makeSingleDropdown = ctx.makeSingleDropdown
	local makeMultiDropdown = ctx.makeMultiDropdown
	local makeMultiDropdownDyn = ctx.makeMultiDropdownDyn
	local makeButton = ctx.makeButton
	local makeSubTabs = ctx.makeSubTabs
	local makeStartStopBar = ctx.makeStartStopBar

	local FIXED_TABS = {
		Hatch = true, Flow = true, Shop = true, Elephant = true,
		Pet = true, Inventory = true, Leveling = true, Mutation = true,
		Farm = true, Misc = true,
	}
	-- sidebar tabs (urut sesuai referensi)
	local TABS = {
		{ "Pet", "Pet", "🐾" },
		{ "Farm", "Farm", "🌾" },
		{ "Hatch", "Hatch", "🥚" },
		{ "Elephant", "Elephant", "🐘" },
		{ "Flow", "Flow", "🌱" },
		{ "Leveling", "Leveling", "⚡" },
		{ "Mutation", "Mutation", "🧪" },
		{ "Inventory", "Inventory", "🎒" },
		{ "Shop", "Shop", "🛒" },
		{ "Misc", "Misc", "⚙️" },
	}
	local pageRef = {}
	for i, t in ipairs(TABS) do
		pageRef[t[1]] = makePage(t[1], t[2], t[3], i, FIXED_TABS[t[1]])
	end

	-- placeholder untuk tab yang belum diisi
	local function placeholder(page)
		local box = mk("Frame", { Size = UDim2.new(1, 0, 0, 90), BackgroundColor3 = C.row, LayoutOrder = 1 }, page)
		corner(box, 8); stroke(box); pad(box, 14, 14, 12, 12)
		mk("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "Fitur untuk tab ini belum tersedia.", Font = F.reg, TextSize = 13, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top }, box)
	end
	------------------------------------------------------------------ FARM
	do
		local farmPage = pageRef["Farm"]
		local farmSub = makeSubTabs(farmPage, {
			{ id = "plants",  name = "Plants" },
			{ id = "care",    name = "Sprinkler & Water" },
			{ id = "shovel",  name = "Shovel" },
			{ id = "harvest", name = "Harvest & Fav" },
		}, "plants", { hasBottomBar = false, hasInfoLine = false })

		local pFarmPlants  = farmSub.pages["plants"]
		local pFarmCare    = farmSub.pages["care"]
		local pFarmShovel  = farmSub.pages["shovel"]
		local pFarmHarvest = farmSub.pages["harvest"]

		-- Automation Plants (fitur aktif): pilih seed + posisi + delay + toggle
		local plAcc = makeAccordion(pFarmPlants, "Automation Plants", 1, true)
		makeMultiDropdownDyn(plAcc, "Select Seeds", "Pilih seed dari inventory (angka = jumlah).",
			function() return ctx.getPlantSeedOptions() end, CFG.plantSeedNames, function() persist() end, 1)
		makeSingleDropdown(plAcc, "Select Position", "Lokasi tanam di farm.",
			function() return { "Random", "Player Position" } end,
			function() return CFG.plantPosition end,
			function(v) CFG.plantPosition = v; persist() end, 2)
		makeInput(plAcc, "Delay To Plants", "Extra delay (detik) tiap tanam seed.",
			function() return tostring(CFG.plantDelay) end,
			function(t) CFG.plantDelay = tonumber(t) or 0; persist() end, 3)
		makeToggle(plAcc, "Auto Plants Seed", "Tanam seed terpilih otomatis.",
			function() return CFG.plantSeedEnabled end,
			function(v) CFG.plantSeedEnabled = v; persist(); if v and ctx.startPlant then ctx.startPlant() end end, 4)

		-- Automation Sprinkler (fitur aktif): pasang sprinkler + shovel sprinkler
		local sprAcc = makeAccordion(pFarmCare, "Automation Sprinkler", 1, true)
		makeMultiDropdownDyn(sprAcc, "Select Sprinkler", "Sprinkler yg mau dipasang (angka = jumlah).",
			function() return ctx.getSprinklerOptions() end, CFG.sprinklerNames, function() persist() end, 1)
		makeMultiDropdownDyn(sprAcc, "Select Sprinkler Plants", "Pasang dekat plant ini. Kosong = pakai Position.",
			function() return ctx.getSprinklerPlantOptions() end, CFG.sprinklerPlantNames, function() persist() end, 2)
		makeSingleDropdown(sprAcc, "Select Sprinkler Position", "Lokasi pasang kalau Plants kosong.",
			function() return { "Random", "Player Position" } end,
			function() return CFG.sprinklerPosition end,
			function(v) CFG.sprinklerPosition = v; persist() end, 3)
		makeInput(sprAcc, "Delay To Sprinkler", "Extra delay (detik) tiap pasang.",
			function() return tostring(CFG.sprinklerDelay) end,
			function(t) CFG.sprinklerDelay = tonumber(t) or 0; persist() end, 4)
		makeToggle(sprAcc, "Auto Sprinkler", "Pasang sprinkler terpilih otomatis.",
			function() return CFG.sprinklerEnabled end,
			function(v) CFG.sprinklerEnabled = v; persist(); if v and ctx.startSprinkler then ctx.startSprinkler() end end, 5)

		-- sub-accordion: Sprinkler Shovel (cabut sprinkler terpasang, butuh Shovel)
		local shAcc = makeAccordion(sprAcc, "Sprinkler Shovel", 6, false)
		makeMultiDropdownDyn(shAcc, "Select Shovel Sprinkler", "Jenis sprinkler terpasang yg mau dicabut. 'All' = semua.",
			function() return ctx.getShovelSprinklerOptions() end, CFG.shovelSprinklerNames, function() persist() end, 1)
		makeInput(shAcc, "Delay To Shovel Sprinkler", "Extra delay (detik) tiap cabut.",
			function() return tostring(CFG.shovelSprinklerDelay) end,
			function(t) CFG.shovelSprinklerDelay = tonumber(t) or 0; persist() end, 2)
		makeToggle(shAcc, "Auto Shovel Sprinkler", "Cabut sprinkler terpilih otomatis (equip Shovel).",
			function() return CFG.shovelSprinklerEnabled end,
			function(v) CFG.shovelSprinklerEnabled = v; persist(); if v and ctx.startShovelSprinkler then ctx.startShovelSprinkler() end end, 3)

		-- Automation Water (fitur aktif): siram plant terpilih pakai Watering Can (Water_RE)
		local watAcc = makeAccordion(pFarmCare, "Automation Water", 2, true)
		makeMultiDropdownDyn(watAcc, "Select Water Fruits", "Pilih fruit/plant yang mau disiram. 'All' = semua.",
			function() return ctx.getWaterFruitOptions() end, CFG.waterFruitNames, function() persist() end, 1)
		makeInput(watAcc, "Delay to Water", "Extra delay (detik) tiap siklus siram.",
			function() return tostring(CFG.waterDelay) end,
			function(t) CFG.waterDelay = tonumber(t) or 1; persist() end, 2)
		makeToggle(watAcc, "Auto Water Fruits", "Siram fruit terpilih otomatis.",
			function() return CFG.waterEnabled end,
			function(v) CFG.waterEnabled = v; persist(); if v and ctx.startWater then ctx.startWater() end end, 3)

		-- Automation Shovel (fitur aktif): shovel tree/plant + shovel fruit (filter)
		local shvAcc = makeAccordion(pFarmShovel, "Automation Shovel", 1, true)
		makeMultiDropdownDyn(shvAcc, "Select Tree", "Pilih tree/plant yang mau di-shovel. 'All' = semua.",
			function() return ctx.getShovelTreeOptions() end, CFG.shovelTreeNames, function() persist() end, 1)
		makeInput(shvAcc, "Delay To Shovel Tree", "Extra delay (detik) tiap siklus shovel tree.",
			function() return tostring(CFG.shovelTreeDelay) end,
			function(t) CFG.shovelTreeDelay = tonumber(t) or 0; persist() end, 2)
		makeToggle(shvAcc, "Auto Shovel Tree", "Shovel tree/plant terpilih otomatis.",
			function() return CFG.shovelTreeEnabled end,
			function(v) CFG.shovelTreeEnabled = v; persist(); if v and ctx.startShovelTree then ctx.startShovelTree() end end, 3)

		-- sub: Fruits Shovel (shovel plant kalau fruit-nya cocok filter)
		local frShv = makeAccordion(shvAcc, "Fruits Shovel", 4, false)
		makeMultiDropdownDyn(frShv, "Select Shovel Fruits", "Tipe fruit yang mau di-shovel. 'All' = semua.",
			function() return ctx.getShovelFruitOptions() end, CFG.shovelFruitNames, function() persist() end, 1)
		makeMultiDropdownDyn(frShv, "Select Shovel Mutation", "Filter mutasi. Kosong/'All' = abaikan.",
			function() return ctx.getShovelMutationOptions() end, CFG.shovelFruitMuts, function() persist() end, 2)
		makeMultiDropdownDyn(frShv, "Select Shovel Variant", "Filter variant (Gold/Rainbow/dll). Kosong/'All' = abaikan.",
			function() return ctx.getShovelVariantOptions() end, CFG.shovelFruitVariants, function() persist() end, 3)
		makeSingleDropdown(frShv, "Select Shovel Threshold Mode", "Cara banding berat fruit.",
			function() return ctx.getShovelModeOptions() end,
			function() return CFG.shovelFruitMode end,
			function(v) CFG.shovelFruitMode = v; persist() end, 4)
		makeInput(frShv, "Shovel Weight Threshold", "Kalau ga mau pakai, isi '0'.",
			function() return tostring(CFG.shovelFruitWeight) end,
			function(t) CFG.shovelFruitWeight = tonumber(t) or 0; persist() end, 5)
		makeInput(frShv, "Delay To Shovel Fruit", "Extra delay (detik) tiap siklus shovel fruit.",
			function() return tostring(CFG.shovelFruitDelay) end,
			function(t) CFG.shovelFruitDelay = tonumber(t) or 0; persist() end, 6)
		makeToggle(frShv, "Auto Shovel Fruits", "Shovel plant yang fruit-nya cocok filter.",
			function() return CFG.shovelFruitEnabled end,
			function(v) CFG.shovelFruitEnabled = v; persist(); if v and ctx.startShovelFruit then ctx.startShovelFruit() end end, 7)

		-- Automation Collection (fitur aktif): auto harvest fruit (3 mode whitelist)
		local colAcc = makeAccordion(pFarmHarvest, "Automation Collection", 1, true)
		makeInput(colAcc, "Delay To Collect", "Extra delay (detik) tiap siklus collect.",
			function() return tostring(CFG.collectDelay) end,
			function(t) CFG.collectDelay = tonumber(t) or 0; persist() end, 1)
		makeToggle(colAcc, "Stop Collect If Backpack Is Full Max", "Stop collect pas backpack penuh.",
			function() return CFG.collectStopIfFull end,
			function(v) CFG.collectStopIfFull = v; persist() end, 2)
		makeToggle(colAcc, "Auto Sell Fruit If Backpack Full", "Jual semua fruit pas backpack penuh.",
			function() return CFG.collectAutoSellIfFull end,
			function(v) CFG.collectAutoSellIfFull = v; persist() end, 3)

		-- sub: Whitelist Fruit
		local colWf = makeAccordion(colAcc, "Collect Whitelist Fruit", 4, false)
		makeMultiDropdownDyn(colWf, "Select Whitelist Fruit", "Pilih tipe fruit yang mau di-collect.",
			function() return ctx.getCollectFruitOptions() end, CFG.collectWlFruitNames, function() persist() end, 1)
		makeToggle(colWf, "Auto Collect Whitelisted Fruits", "Collect cuma tipe fruit yang di-whitelist.",
			function() return CFG.collectWlFruitEnabled end,
			function(v) CFG.collectWlFruitEnabled = v; persist(); if v and ctx.startCollect then ctx.startCollect() end end, 2)

		-- sub: Whitelist Mutation
		local colWm = makeAccordion(colAcc, "Collect Whitelist Mutation", 5, false)
		makeMultiDropdownDyn(colWm, "Select Whitelist Mutations", "Pilih mutasi yang mau di-collect.",
			function() return ctx.getCollectMutationOptions() end, CFG.collectWlMutNames, function() persist() end, 1)
		makeToggle(colWm, "Auto Collect Whitelisted Mutations", "Collect cuma fruit dgn mutasi yang di-whitelist.",
			function() return CFG.collectWlMutEnabled end,
			function(v) CFG.collectWlMutEnabled = v; persist(); if v and ctx.startCollect then ctx.startCollect() end end, 2)

		-- sub: Combined (semua kriteria)
		local colCb = makeAccordion(colAcc, "Collect Whitelist Combined", 6, false)
		makeMultiDropdownDyn(colCb, "Select Combined Fruits", "Filter by fruit type.",
			function() return ctx.getCollectFruitOptions() end, CFG.collectCombFruitNames, function() persist() end, 1)
		makeMultiDropdownDyn(colCb, "Select Combined Mutation", "Filter by mutation type.",
			function() return ctx.getCollectMutationOptions() end, CFG.collectCombMutNames, function() persist() end, 2)
		makeMultiDropdownDyn(colCb, "Select Combined Variant", "Filter by variant type.",
			function() return ctx.getCollectVariantOptions() end, CFG.collectCombVariants, function() persist() end, 3)
		makeSingleDropdown(colCb, "Whitelist Weight Mode", "Cara banding berat fruit.",
			function() return ctx.getCollectModeOptions() end,
			function() return CFG.collectCombMode end,
			function(v) CFG.collectCombMode = v; persist() end, 4)
		makeInput(colCb, "Whitelist Weight", "Kalau ga dipakai, isi '0'.",
			function() return tostring(CFG.collectCombWeight) end,
			function(t) CFG.collectCombWeight = tonumber(t) or 0; persist() end, 5)
		makeToggle(colCb, "Auto Collect Fruits", "Collect fruit yang cocok SEMUA kriteria combined.",
			function() return CFG.collectCombEnabled end,
			function(v) CFG.collectCombEnabled = v; persist(); if v and ctx.startCollect then ctx.startCollect() end end, 6)

		-- Automation Favorite (fitur aktif): favorite/unfavorite fruit via Favorite Tool
		local favAcc = makeAccordion(pFarmHarvest, "Automation Favorite", 2, false)
		makeMultiDropdownDyn(favAcc, "Select Fruits", "Tipe fruit di garden buat di-favorite (kosong = any).",
			function() return ctx.getFavFruitOptions() end, CFG.favFruitNames, function() persist() end, 1)
		makeMultiDropdownDyn(favAcc, "Filter Mutations", "Mutasi yang diperluin (kosong = mutasi apapun OK).",
			function() return ctx.getFavMutationOptions() end, CFG.favMutNames, function() persist() end, 2)
		makeSingleDropdown(favAcc, "Weight Mode", "Banding berat fruit (kosong = off).",
			function() return ctx.getFavModeOptions() end,
			function() return CFG.favMode end,
			function(v) CFG.favMode = v; persist() end, 3)
		makeInput(favAcc, "Weight Value", "Threshold berat (0 = off).",
			function() return tostring(CFG.favWeight) end,
			function(t) CFG.favWeight = tonumber(t) or 0; persist() end, 4)
		makeInput(favAcc, "Delay To Favorite", "Detik tiap siklus scan favorite.",
			function() return tostring(CFG.favDelay) end,
			function(t) CFG.favDelay = tonumber(t) or 1; persist() end, 5)
		makeToggle(favAcc, "Auto Favorite Fruits", "Favorite fruit garden yang cocok filter.",
			function() return CFG.favEnabled end,
			function(v) CFG.favEnabled = v; persist(); if v and ctx.startFavorite then ctx.startFavorite() end end, 6)
		makeToggle(favAcc, "Auto Unfavorite Fruits", "Unfavorite fruit garden yang cocok filter.",
			function() return CFG.unfavEnabled end,
			function(v) CFG.unfavEnabled = v; persist(); if v and ctx.startFavorite then ctx.startFavorite() end end, 7)

		-- Automation Reclaimer (fitur aktif): pilih plant + toggle auto reclaim
		local recAcc = makeAccordion(pFarmHarvest, "Automation Reclaimer", 3, false)
		makeMultiDropdownDyn(recAcc, "Select Plants", "Pilih plant yg mau di-reclaim. 'All' = semua.",
			function() return ctx.getReclaimPlantOptions() end, CFG.reclaimPlantNames, function() persist() end, 1)
		makeToggle(recAcc, "Auto Reclaimer Plants", "Auto reclaim plant terpilih pakai tool Reclaimer",
			function() return CFG.reclaimEnabled end,
			function(v) CFG.reclaimEnabled = v; persist(); if v and ctx.startReclaim then ctx.startReclaim() end end, 2)
	end

	------------------------------------------------------------------ FLOW (pipeline batch per-step)
	do
		local flowPage = pageRef["Flow"] or pageRef["Growth"]
		local FLOW_OPTS = { { name = "none", display = "None (kosong)" }, { name = "elephant", display = "Elephant" }, { name = "mutation", display = "Mutation" }, { name = "leveling", display = "Leveling" }, { name = "leveling_p1", display = "Leveling Phase 1" }, { name = "leveling_p2", display = "Leveling Phase 2" } }
		local function capStep(s) for _, o in ipairs(FLOW_OPTS) do if o.name == s then return o.display end end return "Select" end

		local sub = makeSubTabs(flowPage, {
			{ id = "flow",     name = "Flow Config" },
			{ id = "elephant", name = "Elephant" },
			{ id = "mutation", name = "Mutation" },
			{ id = "leveling", name = "Leveling" },
		}, "flow", { hasBottomBar = true, hasInfoLine = false })

		-- 1) FLOW CONFIG
		local pFlow = sub.pages["flow"]
		local gMainAcc = makeAccordion(pFlow, "Flow Controls & Targets", 1, true)
		makeMultiDropdown(gMainAcc, "Flow Target Pet Types (Default)", "Target default; dipakai step yg target per-method-nya kosong",
			reg.PET_OPTIONS, CFG.growthPetTypes, function() persist() end, 1)

		local gFlow = makeAccordion(pFlow, "Configuration Flow", 2, true)
		local stepDesc = { "First step in pipeline flow", "Second step in pipeline flow", "Third step in pipeline flow", "Fourth step in pipeline flow", "Fifth step in pipeline flow", "Sixth step in pipeline flow", }
		for i = 1, 6 do
			makeSingleDropdown(gFlow, "Step " .. i, stepDesc[i],
				function() return FLOW_OPTS end,
				function() return capStep((CFG.growthFlow or {})[i]) end,
				function(code) CFG.growthFlow = CFG.growthFlow or {}; CFG.growthFlow[i] = code; persist() end, i)
		end

		-- 2) ELEPHANT STEP
		local pEle = sub.pages["elephant"]
		local gEle = makeAccordion(pEle, "Configuration Auto Elephant", 1, true)
		makeMultiDropdown(gEle, "Elephant Target Pet Types", "Target khusus step Elephant (kosong = pakai Default)",
			reg.PET_OPTIONS, CFG.growthPetTypesElephant, function() persist() end, 0)
		makeMultiDropdownDyn(gEle, "Elephant Pet Team", "Team aura buat grow weight",
			function() return ctx.inventoryPetOptions(CFG.growthElephantTeam) end, CFG.growthElephantTeam, function() persist() end, 1)
		makeInput(gEle, "Target Weight (KG)", "Berat target sebelum lanjut step berikutnya (mis. 5.5)",
			function() return tostring(CFG.growthElephantWeight) end, function(t) CFG.growthElephantWeight = tonumber(t) or 5.5; persist() end, 2)
		makeInput(gEle, "Max Target Pets", "Max pet target di garden (step Elephant)",
			function() return tostring(CFG.growthElephantMax) end, function(t) CFG.growthElephantMax = tonumber(t) or 2; persist() end, 3)

		-- 3) MUTATION STEP
		local pMut = sub.pages["mutation"]
		local gMut = makeAccordion(pMut, "Configuration Auto Mutation", 1, true)
		makeMultiDropdown(gMut, "Mutation Target Pet Types", "Target khusus step Mutation (kosong = pakai Default)",
			reg.PET_OPTIONS, CFG.growthPetTypesMutation, function() persist() end, 0)
		makeMultiDropdownDyn(gMut, "Mutation Pet Team", "Team aura pemberi mutasi",
			function() return ctx.inventoryPetOptions(CFG.growthMutationTeam) end, CFG.growthMutationTeam, function() persist() end, 1)
		makeMultiDropdown(gMut, "Target Mutations", "Mutasi yang diinginkan (mutasi salah -> auto cleanse)",
			reg.MUT_OPTIONS, CFG.growthMutationTargets, function() persist() end, 2)
		makeInput(gMut, "Max Target Pets", "Max pet target di garden (step Mutation)",
			function() return tostring(CFG.growthMutationMax) end, function(t) CFG.growthMutationMax = tonumber(t) or 2; persist() end, 3)

		-- 4) LEVELING STEP
		local pLev = sub.pages["leveling"]
		local gLev = makeAccordion(pLev, "Configuration Auto Leveling", 1, true)
		makeMultiDropdown(gLev, "Leveling Target Pet Types", "Target khusus step Leveling (kosong = pakai Default)",
			reg.PET_OPTIONS, CFG.growthPetTypesLeveling, function() persist() end, 0)
		makeMultiDropdownDyn(gLev, "Leveling Phase 1 Pet Team", "Team for Phase 1 (Age 1 to Phase 1 Target)",
			function() return ctx.inventoryPetOptions(CFG.growthLevP1Team) end, CFG.growthLevP1Team, function() persist() end, 1)
		makeInput(gLev, "Leveling Phase 1 Target", "End of Phase 1 / start of Phase 2 (default 40)",
			function() return tostring(CFG.growthLevP1Target) end, function(t) CFG.growthLevP1Target = tonumber(t) or 40; persist() end, 2)
		makeInput(gLev, "Leveling Phase 1 Max Pets", "Max target pets in garden during Phase 1",
			function() return tostring(CFG.growthLevP1Max) end, function(t) CFG.growthLevP1Max = tonumber(t) or 3; persist() end, 3)
		makeMultiDropdownDyn(gLev, "Leveling Phase 2 Pet Team", "Team for Phase 2 (Phase 1 Target to Final Target)",
			function() return ctx.inventoryPetOptions(CFG.growthLevP2Team) end, CFG.growthLevP2Team, function() persist() end, 4)
		makeInput(gLev, "Leveling Phase 2 Target", "Final target level (default 500 = max age)",
			function() return tostring(CFG.growthLevP2Target) end, function(t) CFG.growthLevP2Target = tonumber(t) or 500; persist() end, 5)
		makeInput(gLev, "Leveling Phase 2 Max Pets", "Max target pets in garden during Phase 2",
			function() return tostring(CFG.growthLevP2Max) end, function(t) CFG.growthLevP2Max = tonumber(t) or 1; persist() end, 6)

		-- Start / Stop Bar (PATEN DI BAWAH)
		makeStartStopBar(sub.bottomBarFrame or flowPage,
			function() return CFG.growthEnabled end,
			function()
				CFG.growthEnabled = true
				persist()
				ctx.startGrowth()
			end,
			function()
				CFG.growthEnabled = false
				persist()
				ctx.stopGrowth()
			end, 999)
	end

	------------------------------------------------------------------ HATCH (auto hatch + auto sell)
	do
		local hatchPage = pageRef["Hatch"]

		local sub = makeSubTabs(hatchPage, {
			{ id = "core",   name = "Main Team" },
			{ id = "bronto", name = "Bronto Team" },
			{ id = "hatch",  name = "Hatch Team" },
			{ id = "sell",   name = "Sell Team" },
			{ id = "config", name = "Config" },
		}, "core", { hasBottomBar = true, hasInfoLine = true })

		-- Helper live updater info line: 🐾 Main (0)  🦕 Bronto (0)  🥚 Hatch (0)  💰 Sell (0)
		local function countTeam(t)
			local c = 0
			if type(t) == "table" then
				for k, v in pairs(t) do
					if v == true or (type(v) == "table" and next(v)) then c = c + 1 end
				end
			end
			return c
		end

		local function updateHatchInfoLine()
			if not sub.infoLabel then return end
			local mCount = countTeam(CFG.hatchCoreTeam)
			local bCount = countTeam(CFG.hatchBrontoTeam)
			local hCount = countTeam(CFG.hatchHatchTeam)
			local sCount = countTeam(CFG.hatchSellTeam)
			sub.infoLabel.Text = ("🐾 <font color=\"#ffffff\"><b>Main (%d)</b></font>   🦕 <font color=\"#ffffff\"><b>Bronto (%d)</b></font>   🥚 <font color=\"#ffffff\"><b>Hatch (%d)</b></font>   💰 <font color=\"#ffffff\"><b>Sell (%d)</b></font>"):format(mCount, bCount, hCount, sCount)
		end
		updateHatchInfoLine()

		-- 1) MAIN / CORE TEAM SUB-TAB
		local pCore = sub.pages["core"]
		local cDelayAcc = makeAccordion(pCore, "( Main Team ) Delay Settings", 1, true)
		makeInput(cDelayAcc, "Delay Equip (sec)", "Jeda antar pet pas equip Main team",
			function() return tostring(CFG.hatchCoreEquipDelay or 0) end,
			function(t) CFG.hatchCoreEquipDelay = tonumber(t) or 0; persist() end, 1)
		makeInput(cDelayAcc, "Delay Unequip (sec)", "Jeda antar pet pas unequip Main team",
			function() return tostring(CFG.hatchCoreUnequipDelay or 1) end,
			function(t) CFG.hatchCoreUnequipDelay = tonumber(t) or 1; persist() end, 2)

		local cPetAcc = makeAccordion(pCore, "Select Pet (Main Team)", 2, true)
		makeMultiDropdownDyn(cPetAcc, "Core Team (Main)", "Percepat egg (incubation speed)",
			function() return ctx.inventoryPetOptions(CFG.hatchCoreTeam) end, CFG.hatchCoreTeam,
			function() persist(); updateHatchInfoLine() end, 1)

		-- 2) BRONTO TEAM SUB-TAB
		local pBronto = sub.pages["bronto"]
		local bDelayAcc = makeAccordion(pBronto, "( Bronto Team ) Delay Settings", 1, true)
		makeInput(bDelayAcc, "Delay Equip (sec)", "Jeda antar pet pas equip Bronto team",
			function() return tostring(CFG.hatchBrontoEquipDelay or 0) end,
			function(t) CFG.hatchBrontoEquipDelay = tonumber(t) or 0; persist() end, 1)
		makeInput(bDelayAcc, "Delay Unequip (sec)", "Jeda antar pet pas unequip Bronto team",
			function() return tostring(CFG.hatchBrontoUnequipDelay or 1) end,
			function(t) CFG.hatchBrontoUnequipDelay = tonumber(t) or 1; persist() end, 2)
		makeInput(bDelayAcc, "Bronto Team Delay (sec)", "Tunggu abis swap team sebelum hatch bronto",
			function() return tostring(CFG.brontoTeamDelay or 5.5) end,
			function(t) CFG.brontoTeamDelay = tonumber(t) or 5.5; persist() end, 3)

		local bPetAcc = makeAccordion(pBronto, "Select Pet (Bronto Team)", 2, true)
		makeMultiDropdownDyn(bPetAcc, "Bronto Team", "+30% berat pet pas hatch (Brontosaurus)",
			function() return ctx.inventoryPetOptions(CFG.hatchBrontoTeam) end, CFG.hatchBrontoTeam,
			function() persist(); updateHatchInfoLine() end, 1)

		-- 3) HATCH TEAM SUB-TAB
		local pHatch = sub.pages["hatch"]
		local hDelayAcc = makeAccordion(pHatch, "( Hatch Team ) Delay Settings", 1, true)
		makeInput(hDelayAcc, "Delay Equip (sec)", "Jeda antar pet pas equip Hatch team",
			function() return tostring(CFG.hatchTeamEquipDelay or 0) end,
			function(t) CFG.hatchTeamEquipDelay = tonumber(t) or 0; persist() end, 1)
		makeInput(hDelayAcc, "Delay Unequip (sec)", "Jeda antar pet pas unequip Hatch team",
			function() return tostring(CFG.hatchTeamUnequipDelay or 1) end,
			function(t) CFG.hatchTeamUnequipDelay = tonumber(t) or 1; persist() end, 2)
		makeInput(hDelayAcc, "Hatch Team Delay (sec)", "Tunggu abis swap team sebelum hatch",
			function() return tostring(CFG.hatchTeamDelay or 5.5) end,
			function(t) CFG.hatchTeamDelay = tonumber(t) or 5.5; persist() end, 3)

		local hPetAcc = makeAccordion(pHatch, "Select Pet (Hatch Team)", 2, true)
		makeMultiDropdownDyn(hPetAcc, "Hatch Team", "Hatch egg ready (Koi = balikin egg)",
			function() return ctx.inventoryPetOptions(CFG.hatchHatchTeam) end, CFG.hatchHatchTeam,
			function() persist(); updateHatchInfoLine() end, 1)

		-- 4) SELL TEAM SUB-TAB
		local pSell = sub.pages["sell"]
		local sDelayAcc = makeAccordion(pSell, "( Sell Team ) Delay Settings", 1, true)
		makeInput(sDelayAcc, "Delay Equip (sec)", "Jeda antar pet pas equip Sell team",
			function() return tostring(CFG.hatchSellEquipDelay or 0) end,
			function(t) CFG.hatchSellEquipDelay = tonumber(t) or 0; persist() end, 1)
		makeInput(sDelayAcc, "Delay Unequip (sec)", "Jeda antar pet pas unequip Sell team",
			function() return tostring(CFG.hatchSellUnequipDelay or 1) end,
			function(t) CFG.hatchSellUnequipDelay = tonumber(t) or 1; persist() end, 2)
		makeInput(sDelayAcc, "Sell Team Delay (sec)", "Tunggu abis swap team sebelum jual",
			function() return tostring(CFG.sellTeamDelay or 5.5) end,
			function(t) CFG.sellTeamDelay = tonumber(t) or 5.5; persist() end, 3)
		makeToggle(sDelayAcc, "Auto Boost Before Sell", "Boost pet aktif pakai toy sebelum jual",
			function() return CFG.autoBoostBeforeSell end,
			function(v) CFG.autoBoostBeforeSell = v; persist() end, 4)

		local sPetAcc = makeAccordion(pSell, "Select Pet (Sell Team)", 2, true)
		makeMultiDropdownDyn(sPetAcc, "Sell Team", "Jual + balikin pet jadi egg (Seal the Deal)",
			function() return ctx.inventoryPetOptions(CFG.hatchSellTeam) end, CFG.hatchSellTeam,
			function() persist(); updateHatchInfoLine() end, 1)

		-- 5) CONFIG SUB-TAB (Sell & Bronto Table exact as Node Hub + Bulk + Egg Config)
		local pCfg = sub.pages["config"]

		-- Sell & Bronto Table Accordion
		local sCfgAcc = makeAccordion(pCfg, "Sell & Bronto Configuration", 1, true)

		-- Info Card
		local infoCard = mk("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = C.panel,
			LayoutOrder = 1,
		}, sCfgAcc)
		corner(infoCard, 8)
		stroke(infoCard, C.strokeSub, 1, 0.4)
		pad(infoCard, 8, 8, 8, 8)
		mk("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Text = "- Weight < KG -> mengikuti pengaturan tombol KEEP / SELL.\n- Weight >= KG -> KEEP + BRONTO (otomatis di-hatch pakai Bronto team + disimpan aman).",
			Font = F.reg,
			TextSize = 11,
			TextColor3 = C.txt,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			LineHeight = 1.3,
		}, infoCard)

		-- Auto Sell Enable Toggle
		makeToggle(sCfgAcc, "Auto Sell Pets", "Jual otomatis pet di backpack sesuai pengaturan",
			function() return CFG.autoSellEnabled end,
			function(v) CFG.autoSellEnabled = v; persist() end, 2)

		-- Sell Trigger Mode row: Cycle | Total Pets (Backpack)
		local trigRow = mk("Frame", {
			Size = UDim2.new(1, 0, 0, 36),
			BackgroundTransparency = 1,
			LayoutOrder = 3,
		}, sCfgAcc)
		mk("TextLabel", {
			Size = UDim2.new(0, 110, 1, 0),
			BackgroundTransparency = 1,
			Text = "Sell Trigger :",
			Font = F.bold,
			TextSize = 12,
			TextColor3 = C.txt,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, trigRow)

		local trigContainer = mk("Frame", {
			Size = UDim2.new(1, -110, 0, 28),
			Position = UDim2.new(0, 110, 0.5, -14),
			BackgroundTransparency = 1,
		}, trigRow)
		mk("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 6),
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}, trigContainer)

		local bTrigCycle = mk("TextButton", {
			Size = UDim2.new(0.5, -3, 1, 0),
			BackgroundColor3 = C.row,
			Text = "By Cycle",
			Font = F.bold,
			TextSize = 12,
			TextColor3 = C.sub,
			AutoButtonColor = false,
			LayoutOrder = 1,
		}, trigContainer)
		corner(bTrigCycle, 6)
		local sTrigCycleStroke = stroke(bTrigCycle, C.strokeSub, 1, 0.5)

		local bTrigBp = mk("TextButton", {
			Size = UDim2.new(0.5, -3, 1, 0),
			BackgroundColor3 = C.row,
			Text = "Total Pet (BP)",
			Font = F.bold,
			TextSize = 12,
			TextColor3 = C.sub,
			AutoButtonColor = false,
			LayoutOrder = 2,
		}, trigContainer)
		corner(bTrigBp, 6)
		local sTrigBpStroke = stroke(bTrigBp, C.strokeSub, 1, 0.5)

		-- Threshold Rows:
		-- 1) Sell Every N Cycles row
		local cycleRow = mk("Frame", {
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundTransparency = 1,
			LayoutOrder = 4,
		}, sCfgAcc)
		mk("TextLabel", {
			Size = UDim2.new(1, -70, 1, 0),
			BackgroundTransparency = 1,
			Text = "Sell Tiap Berapa Cycle (Hatch Round) :",
			Font = F.bold,
			TextSize = 11.5,
			TextColor3 = C.txt,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, cycleRow)
		local cycleBoxFrame = mk("Frame", {
			Size = UDim2.fromOffset(56, 26),
			Position = UDim2.new(1, -58, 0.5, -13),
			BackgroundColor3 = C.panel,
		}, cycleRow)
		corner(cycleBoxFrame, 6)
		stroke(cycleBoxFrame, C.strokeSub, 1, 0.5)
		local cycleBox = mk("TextBox", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = tostring(CFG.sellEveryNCycles or 1),
			Font = F.bold,
			TextSize = 12,
			TextColor3 = C.txt,
			ClearTextOnFocus = false,
			TextXAlignment = Enum.TextXAlignment.Center,
		}, cycleBoxFrame)
		cycleBox.FocusLost:Connect(function()
			CFG.sellEveryNCycles = math.max(1, tonumber(cycleBox.Text) or 1)
			cycleBox.Text = tostring(CFG.sellEveryNCycles)
			persist()
		end)

		-- 2) Activation row: Auto Sell Aktif Saat Total Pet
		local actRow = mk("Frame", {
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundTransparency = 1,
			LayoutOrder = 5,
		}, sCfgAcc)
		local actLbl = mk("TextLabel", {
			Size = UDim2.new(1, -70, 1, 0),
			BackgroundTransparency = 1,
			Text = "Auto Sell Aktif Saat Total Pet :",
			Font = F.bold,
			TextSize = 11.5,
			TextColor3 = C.txt,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, actRow)
		local actBoxFrame = mk("Frame", {
			Size = UDim2.fromOffset(56, 26),
			Position = UDim2.new(1, -58, 0.5, -13),
			BackgroundColor3 = C.panel,
		}, actRow)
		corner(actBoxFrame, 6)
		stroke(actBoxFrame, C.strokeSub, 1, 0.5)
		local actBox = mk("TextBox", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = tostring(CFG.sellWhenReach or 24),
			Font = F.bold,
			TextSize = 12,
			TextColor3 = C.txt,
			ClearTextOnFocus = false,
			TextXAlignment = Enum.TextXAlignment.Center,
		}, actBoxFrame)
		actBox.FocusLost:Connect(function()
			CFG.sellWhenReach = tonumber(actBox.Text) or 24
			actBox.Text = tostring(CFG.sellWhenReach)
			persist()
		end)

		local function updateSellTriggerBtns()
			local isCycle = (CFG.sellMode == "Cycle")
			bTrigCycle.BackgroundColor3 = isCycle and C.rowAlt or C.panel
			bTrigCycle.TextColor3 = isCycle and Color3.new(1, 1, 1) or C.txt
			sTrigCycleStroke.Color = isCycle and C.acc or C.strokeSub

			bTrigBp.BackgroundColor3 = (not isCycle) and C.rowAlt or C.panel
			bTrigBp.TextColor3 = (not isCycle) and Color3.new(1, 1, 1) or C.txt
			sTrigBpStroke.Color = (not isCycle) and C.acc or C.strokeSub

			cycleRow.Visible = isCycle
			actRow.Visible = not isCycle
		end
		updateSellTriggerBtns()

		bTrigCycle.MouseButton1Click:Connect(function()
			CFG.sellMode = "Cycle"
			persist()
			updateSellTriggerBtns()
		end)
		bTrigBp.MouseButton1Click:Connect(function()
			CFG.sellMode = "Backpack"
			persist()
			updateSellTriggerBtns()
		end)

		-- Sell Style row: Sell One By One | Sell All
		local modeRow = mk("Frame", {
			Size = UDim2.new(1, 0, 0, 36),
			BackgroundTransparency = 1,
			LayoutOrder = 6,
		}, sCfgAcc)
		mk("TextLabel", {
			Size = UDim2.new(0, 110, 1, 0),
			BackgroundTransparency = 1,
			Text = "Sell Style :",
			Font = F.bold,
			TextSize = 12,
			TextColor3 = C.txt,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, modeRow)

		local modeContainer = mk("Frame", {
			Size = UDim2.new(1, -110, 0, 28),
			Position = UDim2.new(0, 110, 0.5, -14),
			BackgroundTransparency = 1,
		}, modeRow)
		mk("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 6),
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}, modeContainer)

		local bOneByOne = mk("TextButton", {
			Size = UDim2.new(0.5, -3, 1, 0),
			BackgroundColor3 = C.row,
			Text = "Sell One By One",
			Font = F.bold,
			TextSize = 12,
			TextColor3 = C.sub,
			AutoButtonColor = false,
			LayoutOrder = 1,
		}, modeContainer)
		corner(bOneByOne, 6)
		local sOneStroke = stroke(bOneByOne, C.strokeSub, 1, 0.5)

		local bSellAll = mk("TextButton", {
			Size = UDim2.new(0.5, -3, 1, 0),
			BackgroundColor3 = C.row,
			Text = "Sell All",
			Font = F.bold,
			TextSize = 12,
			TextColor3 = C.sub,
			AutoButtonColor = false,
			LayoutOrder = 2,
		}, modeContainer)
		corner(bSellAll, 6)
		local sAllStroke = stroke(bSellAll, C.strokeSub, 1, 0.5)

		local function updateSellModeBtns()
			local isAll = (CFG.sellStyle == "All at Once")
			bOneByOne.BackgroundColor3 = (not isAll) and C.rowAlt or C.panel
			bOneByOne.TextColor3 = (not isAll) and Color3.new(1, 1, 1) or C.txt
			sOneStroke.Color = (not isAll) and C.acc or C.strokeSub

			bSellAll.BackgroundColor3 = isAll and C.rowAlt or C.panel
			bSellAll.TextColor3 = isAll and Color3.new(1, 1, 1) or C.txt
			sAllStroke.Color = isAll and C.acc or C.strokeSub
		end
		updateSellModeBtns()

		bOneByOne.MouseButton1Click:Connect(function()
			CFG.sellStyle = "One by One"
			persist()
			updateSellModeBtns()
		end)
		bSellAll.MouseButton1Click:Connect(function()
			CFG.sellStyle = "All at Once"
			persist()
			updateSellModeBtns()
		end)

		-- Search Bar for Configured Pets Table
		local searchRow = mk("Frame", {
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundColor3 = C.panel,
			LayoutOrder = 7,
		}, sCfgAcc)
		corner(searchRow, 6)
		stroke(searchRow, C.strokeSub, 1, 0.4)
		pad(searchRow, 8, 8, 0, 0)
		local sellTableSearch = mk("TextBox", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			PlaceholderText = "Search Pet Name...",
			PlaceholderColor3 = C.sub,
			Text = "",
			Font = F.reg,
			TextSize = 13,
			TextColor3 = C.txt,
			ClearTextOnFocus = false,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, searchRow)

		-- Dynamic Pet List Table Container
		local tableListFrame = mk("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = 8,
		}, sCfgAcc)
		mk("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 4),
		}, tableListFrame)

		local tableRows = {}

		local function rebuildSellTable()
			for _, r in ipairs(tableRows) do
				if r.frame then r.frame:Destroy() end
			end
			tableRows = {}

			CFG.hatchSellList = CFG.hatchSellList or {}

			local sortedKeys = {}
			for k in pairs(CFG.hatchSellList) do sortedKeys[#sortedKeys + 1] = k end
			table.sort(sortedKeys)

			local q = sellTableSearch.Text:lower()

			for i, petName in ipairs(sortedKeys) do
				local rule = CFG.hatchSellList[petName]
				if rule and type(rule) == "table" then
					local petLower = petName:lower()
					local visible = (q == "" or petLower:find(q, 1, true) ~= nil)

					local rowFrame = mk("Frame", {
						Size = UDim2.new(1, 0, 0, 32),
						BackgroundColor3 = C.panel,
						Visible = visible,
						LayoutOrder = i,
					}, tableListFrame)
					corner(rowFrame, 6)
					stroke(rowFrame, C.strokeSub, 1, 0.3)
					pad(rowFrame, 8, 6, 0, 0)

					-- Left: Pet Name + Sub Rule Text
					local nameCol = mk("Frame", {
						Size = UDim2.new(1, -198, 1, 0),
						BackgroundTransparency = 1,
					}, rowFrame)
					local pNameLbl = mk("TextLabel", {
						Size = UDim2.new(1, 0, 0, 17),
						Position = UDim2.new(0, 0, 0, 0),
						BackgroundTransparency = 1,
						Text = (rule.special and "<font color=\"#ffd700\">★ </font>" or "") .. petName,
						Font = F.bold,
						TextSize = 13,
						TextColor3 = C.txt,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextTruncate = Enum.TextTruncate.AtEnd,
						RichText = true,
					}, nameCol)

					local subRuleLbl = mk("TextLabel", {
						Size = UDim2.new(1, 0, 0, 14),
						Position = UDim2.new(0, 0, 0, 16),
						BackgroundTransparency = 1,
						Font = F.reg,
						TextSize = 10.5,
						TextXAlignment = Enum.TextXAlignment.Left,
						RichText = true,
					}, nameCol)

					local function updateRuleText()
						local curKg = tonumber(rule.kg) or 0.8
						local curAction = tostring(rule.action or "KEEP"):upper()
						local col = curAction == "KEEP" and "#6ef5b9" or "#ff4b78"
						if rule.special then
							subRuleLbl.Text = string.format("<font color=\"#ffd700\"><b>★ SPECIAL</b></font> <font color=\"#ebd0eb\">| &lt; %.2f</font> <font color=\"%s\"><b>%s</b></font> <font color=\"#ebd0eb\">| &gt;= %.2f BRONTO+KEEP</font>", curKg, col, curAction, curKg)
						else
							subRuleLbl.Text = string.format("<font color=\"#ebd0eb\">&lt; %.2f</font> <font color=\"%s\"><b>%s</b></font> <font color=\"#ebd0eb\">| &gt;= %.2f BRONTO + KEEP</font>", curKg, col, curAction, curKg)
						end
					end
					updateRuleText()

					-- Star button (Special Pet toggle) [ ★ ] / [ ☆ ]
					local starBtn = mk("TextButton", {
						Size = UDim2.fromOffset(26, 24),
						Position = UDim2.new(1, -192, 0.5, -12),
						BackgroundColor3 = rule.special and Color3.fromRGB(60, 48, 15) or C.row,
						Text = rule.special and "★" or "☆",
						Font = F.bold,
						TextSize = 14,
						TextColor3 = rule.special and Color3.fromRGB(255, 215, 0) or C.sub,
						AutoButtonColor = false,
					}, rowFrame)
					corner(starBtn, 5)
					local starStroke = stroke(starBtn, rule.special and Color3.fromRGB(255, 215, 0) or C.strokeSub, 1, rule.special and 0.3 or 0.6)

					local function updateStarUI()
						local isSpec = (rule.special == true)
						starBtn.Text = isSpec and "★" or "☆"
						starBtn.TextColor3 = isSpec and Color3.fromRGB(255, 215, 0) or C.sub
						starBtn.BackgroundColor3 = isSpec and Color3.fromRGB(60, 48, 15) or C.row
						starStroke.Color = isSpec and Color3.fromRGB(255, 215, 0) or C.strokeSub
						starStroke.Transparency = isSpec and 0.3 or 0.6
						pNameLbl.Text = (isSpec and "<font color=\"#ffd700\">★ </font>" or "") .. petName
					end

					starBtn.MouseButton1Click:Connect(function()
						rule.special = not (rule.special == true)
						persist()
						updateStarUI()
						updateRuleText()
					end)

					-- KG input box [ 0.8 ]
					local kgFrame = mk("Frame", {
						Size = UDim2.fromOffset(46, 24),
						Position = UDim2.new(1, -160, 0.5, -12),
						BackgroundColor3 = C.row,
					}, rowFrame)
					corner(kgFrame, 5)
					stroke(kgFrame, C.strokeSub, 1, 0.5)
					local kgBox = mk("TextBox", {
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						Text = tostring(rule.kg or 0.8),
						Font = F.bold,
						TextSize = 12.5,
						TextColor3 = C.txt,
						ClearTextOnFocus = false,
						TextXAlignment = Enum.TextXAlignment.Center,
					}, kgFrame)
					kgBox.FocusLost:Connect(function()
						rule.kg = tonumber(kgBox.Text) or 0.8
						kgBox.Text = tostring(rule.kg)
						persist()
						updateRuleText()
					end)

					-- Action button [ KEEP ] / [ SELL ]
					local actBtn = mk("TextButton", {
						Size = UDim2.fromOffset(68, 24),
						Position = UDim2.new(1, -108, 0.5, -12),
						BackgroundColor3 = rule.action == "SELL" and Color3.fromRGB(120, 35, 35) or Color3.fromRGB(30, 85, 45),
						Text = tostring(rule.action or "KEEP"):upper(),
						Font = F.bold,
						TextSize = 11.5,
						TextColor3 = Color3.new(1, 1, 1),
						AutoButtonColor = false,
					}, rowFrame)
					corner(actBtn, 5)
					stroke(actBtn, rule.action == "SELL" and Color3.fromRGB(180, 50, 50) or Color3.fromRGB(50, 150, 70), 1, 0.4)

					actBtn.MouseButton1Click:Connect(function()
						if rule.action == "SELL" then
							rule.action = "KEEP"
							actBtn.Text = "KEEP"
							actBtn.BackgroundColor3 = Color3.fromRGB(30, 85, 45)
						else
							rule.action = "SELL"
							actBtn.Text = "SELL"
							actBtn.BackgroundColor3 = Color3.fromRGB(120, 35, 35)
						end
						persist()
						updateRuleText()
					end)

					-- Delete button [ - ]
					local delBtn = mk("TextButton", {
						Size = UDim2.fromOffset(26, 24),
						Position = UDim2.new(1, -34, 0.5, -12),
						BackgroundColor3 = Color3.fromRGB(100, 30, 30),
						Text = "-",
						Font = F.bold,
						TextSize = 14,
						TextColor3 = Color3.new(1, 1, 1),
						AutoButtonColor = false,
					}, rowFrame)
					corner(delBtn, 5)
					stroke(delBtn, Color3.fromRGB(160, 40, 40), 1, 0.4)

					delBtn.MouseButton1Click:Connect(function()
						CFG.hatchSellList[petName] = nil
						persist()
						rebuildSellTable()
					end)

					tableRows[#tableRows + 1] = { frame = rowFrame, name = petLower }
				end
			end
		end

		sellTableSearch:GetPropertyChangedSignal("Text"):Connect(function()
			local q = sellTableSearch.Text:lower()
			for _, r in ipairs(tableRows) do
				if r.frame then
					r.frame.Visible = (q == "" or r.name:find(q, 1, true) ~= nil)
				end
			end
		end)

		rebuildSellTable()

		-- Bulk Controls Below List
		local bulkPetSet = {}
		local bulkKgVal = 0.8
		local bulkActionVal = "sell"
		local bulkSpecialVal = false

		local updateBulkPetDd = makeMultiDropdown(sCfgAcc, "Select Pet Types (Bulk)", "Pilih beberapa jenis pet sekaligus",
			reg.PET_OPTIONS, bulkPetSet, nil, 9)

		makeInput(sCfgAcc, "KG (Bulk)", "Batas berat target pet",
			function() return tostring(bulkKgVal) end,
			function(t) bulkKgVal = tonumber(t) or 0.8 end, 10)

		local ACTION_OPTS = { { name = "sell", display = "sell" }, { name = "keep", display = "keep" } }
		makeSingleDropdown(sCfgAcc, "Below KG Action (Bulk)", "Aksi jika pet di bawah batas KG",
			function() return ACTION_OPTS end,
			function() return bulkActionVal end,
			function(code) bulkActionVal = code end, 11)

		makeToggle(sCfgAcc, "Special Pet (Bulk)", "Tandai pet terpilih sebagai Special Pet (★ Alert & Bronto count)",
			function() return bulkSpecialVal end,
			function(v) bulkSpecialVal = v end, 12)

		makeButton(sCfgAcc, "APPLY BULK LIST", "Terapkan setting ke semua pet terpilih di atas",
			function()
				CFG.hatchSellList = CFG.hatchSellList or {}
				local countApplied = 0
				for petName, isSel in pairs(bulkPetSet) do
					if isSel then
						CFG.hatchSellList[petName] = {
							kg = tonumber(bulkKgVal) or 0.8,
							action = tostring(bulkActionVal):upper(),
							special = bulkSpecialVal == true,
						}
						countApplied = countApplied + 1
					end
				end
				if countApplied > 0 then
					persist()
					rebuildSellTable()
					if ctx.log then ctx.log(("✦ Bulk config diterapkan untuk %d jenis pet"):format(countApplied)) end
				end
			end, 13)

		makeButton(sCfgAcc, "CLEAR BULK SELECTION", "Kosongkan checklist pet terpilih",
			function()
				for k in pairs(bulkPetSet) do bulkPetSet[k] = nil end
				bulkSpecialVal = false
				if updateBulkPetDd then updateBulkPetDd() end
			end, 14)

		-- Manual Sell Now button
		makeButton(sCfgAcc, "Sell Now (manual)", "Jalankan proses sell sekali sekarang",
			function() task.spawn(function() pcall(ctx.hatchDoSell) end) end, 15)

		makeToggle(sCfgAcc, "Don't Hatch Bronto Pets", "Skip pet yang memenuhi syarat Bronto (jangan di-hatch)",
			function() return CFG.brontoSkipSpecial end, function(v) CFG.brontoSkipSpecial = v; persist() end, 16)

		-- Egg Configuration Accordion
		local hEgg = makeAccordion(pCfg, "Egg Configuration", 2, false)
		makeSingleDropdown(hEgg, "Egg to Hatch", "Egg dari backpack yg di-place & di-hatch (+ jumlah)",
			function() return ctx.getEggBackpackOptions() end,
			function() return tostring(CFG.hatchEggName or "") end,
			function(code) CFG.hatchEggName = code; persist() end, 1)
		makeSingleDropdown(hEgg, "Placement Pattern", "Pola taro egg: Grid (rapih) / Random (sebar acak)",
			function() return { "Grid", "Random" } end,
			function() return CFG.hatchPlacePattern or "Grid" end,
			function(code) CFG.hatchPlacePattern = code; persist() end, 2)
		makeInput(hEgg, "Max Placed", "Maksimal egg ke-place di garden",
			function() return tostring(CFG.hatchMaxPlaced) end, function(t) CFG.hatchMaxPlaced = tonumber(t) or 8; persist() end, 3)
		makeToggle(hEgg, "Auto Rejoin on Egg Minus", "Auto rejoin server jika egg minus mencapai batas",
			function() return CFG.hatchRejoinMinusEnabled end,
			function(v)
				CFG.hatchRejoinMinusEnabled = v; persist()
				if v and ctx.startEggMinusWatcher then
					ctx.startEggMinusWatcher()
				elseif not v and not CFG.hatchRejoinPlusEnabled and ctx.stopEggMinusWatcher then
					ctx.stopEggMinusWatcher()
				end
			end, 4)
		makeInput(hEgg, "Egg Minus Threshold", "Batas jumlah minus untuk trigger rejoin (misal: 20)",
			function() return tostring(CFG.hatchRejoinMinusThreshold or 20) end,
			function(t) CFG.hatchRejoinMinusThreshold = tonumber(t) or 20; persist() end, 5)
		makeToggle(hEgg, "Auto Rejoin on Egg Plus", "Auto rejoin server jika egg bertambah mencapai batas",
			function() return CFG.hatchRejoinPlusEnabled end,
			function(v)
				CFG.hatchRejoinPlusEnabled = v; persist()
				if v and ctx.startEggMinusWatcher then
					ctx.startEggMinusWatcher()
				elseif not v and not CFG.hatchRejoinMinusEnabled and ctx.stopEggMinusWatcher then
					ctx.stopEggMinusWatcher()
				end
			end, 6)
		makeInput(hEgg, "Egg Plus Threshold", "Batas jumlah penambahan untuk trigger rejoin (misal: 20)",
			function() return tostring(CFG.hatchRejoinPlusThreshold or 20) end,
			function(t) CFG.hatchRejoinPlusThreshold = tonumber(t) or 20; persist() end, 7)

		-- START / STOP BAR (PATEN DI BAWAH HATCH PAGE)
		makeStartStopBar(sub.bottomBarFrame or hatchPage,
			function() return CFG.hatchEnabled end,
			function()
				CFG.hatchEnabled = true
				persist()
				ctx.startHatch()
			end,
			function()
				CFG.hatchEnabled = false
				persist()
				ctx.stopHatch()
			end, 999)
	end

	------------------------------------------------------------------ SHOP
	do
		local shopPage = pageRef["Shop"]

		local sub = makeSubTabs(shopPage, {
			{ id = "seed",     name = "Seeds" },
			{ id = "egg",      name = "Eggs" },
			{ id = "gear",     name = "Gears" },
			{ id = "merchant", name = "Merchant" },
			{ id = "premium",  name = "Premium" },
		}, "seed", 1)

		-- 1) SEEDS
		local pSeed = sub.pages["seed"]
		local seedAcc = makeAccordion(pSeed, "Automation Buy Seed", 1, true)
		makeMultiDropdownDyn(seedAcc, "Select Seeds to Buy", "Pilih seed buat auto-beli (stock realtime)",
			function() return ctx.getSeedShopOptions(CFG.buySeedNames) end, CFG.buySeedNames, function() persist() end, 1)
		makeToggle(seedAcc, "Enable Automation Buy Seed", "Auto-beli seed terpilih tiap ada stock",
			function() return CFG.buySeedEnabled end,
			function(v) CFG.buySeedEnabled = v; persist(); if v then ctx.startBuySeed() end end, 2)

		-- 2) EGGS
		local pEgg = sub.pages["egg"]
		local eggAcc = makeAccordion(pEgg, "Automation Buy Egg", 1, true)
		makeMultiDropdownDyn(eggAcc, "Select Eggs to Buy", "Pilih egg buat auto-beli (stock realtime)",
			function() return ctx.getEggShopOptions(CFG.buyEggNames) end, CFG.buyEggNames, function() persist() end, 1)
		makeToggle(eggAcc, "Enable Automation Buy Egg", "Auto-beli egg terpilih tiap ada stock",
			function() return CFG.buyEggEnabled end,
			function(v) CFG.buyEggEnabled = v; persist(); if v then ctx.startBuyEgg() end end, 2)

		-- 3) GEARS
		local pGear = sub.pages["gear"]
		local gearAcc = makeAccordion(pGear, "Automation Buy Gear", 1, true)
		makeMultiDropdownDyn(gearAcc, "Select Gear to Buy", "Pilih gear buat auto-beli (stock realtime)",
			function() return ctx.getGearShopOptions(CFG.buyGearNames) end, CFG.buyGearNames, function() persist() end, 1)
		makeToggle(gearAcc, "Enable Automation Buy Gear", "Auto-beli gear terpilih tiap ada stock",
			function() return CFG.buyGearEnabled end,
			function(v) CFG.buyGearEnabled = v; persist(); if v then ctx.startBuyGear() end end, 2)

		-- 4) MERCHANT
		local pMer = sub.pages["merchant"]
		local merAcc = makeAccordion(pMer, "Automation Buy Merchant", 1, true)
		local merStatus = mk("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1, Text = "Loading...",
			Font = F.reg, TextSize = 12, TextColor3 = C.txt,
			TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
			LineHeight = 1.3, RichText = true, LayoutOrder = 0
		}, merAcc)
		mk("Frame", { Size = UDim2.new(1, 0, 0, 8), BackgroundTransparency = 1, LayoutOrder = 1 }, merAcc)
		task.spawn(function()
			while ctx.alive() do
				if not onScreen(shopPage) then task.wait(1) continue end
				local ok, s = pcall(function() return ctx.getMerchantSummary() end)
				if ok and s then
					local lines = {}
					if s.activeMerchant then
						lines[#lines + 1] = "Traveling aktif: <font color=\"#5acc78\"><b>" .. s.activeMerchant .. "</b></font>"
					else
						lines[#lines + 1] = "Traveling aktif: <font color=\"#dc5050\">Tidak Ada</font>"
					end
					if s.mode == "all" then
						lines[#lines + 1] = "Mode: <font color=\"#f5c82d\"><b>Beli SEMUA item (All)</b></font>"
					elseif s.mode == "best" then
						lines[#lines + 1] = "Mode: <font color=\"#f5c82d\"><b>Beli item TERMAHAL (Best)</b></font>"
					elseif s.picks and #s.picks > 0 then
						lines[#lines + 1] = "Item dipilih buat dibeli:"
						for _, p in ipairs(s.picks) do
							local function shortNum(n)
								local a = math.abs(n)
								local s
								if a >= 1e9 then s = string.format("%.2f", n / 1e9):gsub("%.?0+$", "") .. "b"
								elseif a >= 1e6 then s = string.format("%.2f", n / 1e6):gsub("%.?0+$", "") .. "m"
								elseif a >= 1e3 then s = string.format("%.2f", n / 1e3):gsub("%.?0+$", "") .. "k"
								else s = tostring(n) end
								return s
							end
							local parts = {}
							for _, it in ipairs(p.items) do
								if it.price then
									parts[#parts + 1] = string.format("%s (%s)", it.name, shortNum(it.price))
								else
									parts[#parts + 1] = it.name
								end
							end
							lines[#lines + 1] = string.format(
								"- <font color=\"#5acc78\"><b>%s</b></font>: <font color=\"#f5c82d\">%s</font>",
								p.title, table.concat(parts, ", "))
						end
					else
						lines[#lines + 1] = "<font color=\"#dc5050\">Belum ada item dipilih.</font> Pilih di 'Select Items per Merchant' atau nyalakan Auto Buy All/Best."
					end
					merStatus.Text = table.concat(lines, "\n")
				end
				task.wait(2)
			end
		end)
		-- Pilih item — dipisah: Traveling Merchant vs Event Shop (biar rapih). Set duluan.
		-- Dua-duanya 1 path/buy toggle yang sama (Auto Buy Merchant/All/Best).
		local merSel = makeAccordion(merAcc, "Select Items per Merchant", 2, false)
		local evtSel = makeAccordion(merAcc, "Select Items per Event Shop", 3, false)
		do
			local iM, iE = 0, 0
			for _, m in ipairs(ctx.getMerchantList()) do
				local id = m.id
				if m.kind == "travel" then
					iM = iM + 1
					makeMultiDropdownDyn(merSel, m.title .. " Merchant", "Item dari " .. m.title .. " merchant. 'All' = semua.",
						function() return ctx.getMerchantItemOptions(id) end, ctx.merchantSelFor(id), function() persist() end, iM)
				else
					iE = iE + 1
					makeMultiDropdownDyn(evtSel, m.title, "Item dari " .. m.title .. ". 'All' = semua.",
						function() return ctx.getMerchantItemOptions(id) end, ctx.merchantSelFor(id), function() persist() end, iE)
				end
			end
		end
		-- Toggle bisa nyala barengan; target-nya digabung (union). Berlaku utk merchant & event shop.
		makeToggle(merAcc, "Auto Buy Merchant", "Beli item terpilih (merchant & event shop) tiap muncul / restock",
			function() return CFG.merchantBuyEnabled end,
			function(v) CFG.merchantBuyEnabled = v; persist(); if v then ctx.startBuyMerchant() end end, 4)
		makeToggle(merAcc, "Auto Buy All Merchant", "Beli SEMUA item yang ada stock",
			function() return CFG.merchantBuyAll end,
			function(v) CFG.merchantBuyAll = v; persist(); if v then ctx.startBuyMerchant() end end, 5)
		makeToggle(merAcc, "Auto Buy Best Merchant", "Beli 1 item TERMAHAL yang ada stock",
			function() return CFG.merchantBuyBest end,
			function(v) CFG.merchantBuyBest = v; persist(); if v then ctx.startBuyMerchant() end end, 6)

		-- Open Shop UI (event/night shop — tampilkan UI shop tanpa NPC)
		local merUi = makeAccordion(merAcc, "Open Shop UI", 7, false)
		makeSingleDropdown(merUi, "Merchant UI to Open", "Event shop yang mau dibuka UI-nya (1 shop per waktu)",
			function() return ctx.getEventShopOptions() end,
			function() return ctx.getMerchantUiDisplay() end,
			function(code) CFG.merchantUiShop = code; persist(); if ctx.openEventShopUI then ctx.openEventShopUI(code) end end, 1)
		makeButton(merUi, "Open Shop UI Now", "Buka UI shop terpilih sekarang (kalau shop lagi aktif)",
			function() if ctx.openEventShopUI then ctx.openEventShopUI() end end, 2)
		makeToggle(merUi, "Auto Open UI", "Jaga UI shop terpilih tetap kebuka (buka ulang otomatis, tanpa NPC)",
			function() return CFG.merchantAutoOpenUI end,
			function(v) CFG.merchantAutoOpenUI = v; persist()
				if v then ctx.startAutoOpenUI() elseif ctx.stopAutoOpenUI then ctx.stopAutoOpenUI() end end, 3)

		-- 5) PREMIUM
		local pPrem = sub.pages["premium"]
		local premAcc = makeAccordion(pPrem, "Premium Shop", 1, true)
		makeSingleDropdown(premAcc, "Select Item", "Select gamepass/product to purchase",
			function() return ctx.getPremiumItemOptions() end,
			function()
				for _, o in ipairs(ctx.getPremiumItemOptions()) do if o.name == CFG.premiumItem then return o.display end end
				return "Select Option"
			end,
			function(code) CFG.premiumItem = code; persist(); if ctx.premiumShowPrice then ctx.premiumShowPrice() end end, 1)
		makeSingleDropdown(premAcc, "Payment Method", "Pilih bayar pakai Robux / in-game Token",
			function() return ctx.getPremiumPayOptions() end,
			function() return CFG.premiumPay == "token" and "Token" or "Robux" end,
			function(code) CFG.premiumPay = code; persist() end, 2)
		makeButton(premAcc, "Purchase Item", "Beli item terpilih dengan payment method di atas",
			function() if ctx.premiumBuy then ctx.premiumBuy() end end, 3)
		makeButton(premAcc, "Gift to Player", "Beli varian Gift item ini (kalau tersedia)",
			function() if ctx.premiumGift then ctx.premiumGift() end end, 4)
	end

	------------------------------------------------------------------ ELEPHANT (V1 & V2)
	do
		local elephantPage = pageRef["Elephant"]
		local sub = makeSubTabs(elephantPage, {
			{ id = "v1", name = "Elephant V1" },
			{ id = "v2", name = "Elephant V2 (Swap 40)" },
		}, "v1", 1)

		-- V1 SUB-TAB
		local pV1 = sub.pages["v1"]
		local acc = makeAccordion(pV1, "Automation Elephant V1", 1, true)

		-- Status (live)
		local statusLbl = mk("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1, Text = "Loading stats...",
			Font = F.reg, TextSize = 12, TextColor3 = C.txt,
			TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
			LineHeight = 1.3, RichText = true, LayoutOrder = 0
		}, acc)
		mk("Frame", { Size = UDim2.new(1, 0, 0, 8), BackgroundTransparency = 1, LayoutOrder = 1 }, acc)
		task.spawn(function()
			while ctx.alive() do
				if not onScreen(elephantPage) then task.wait(1) continue end
				local ok, s = pcall(function() return ctx.getElephantSummary() end)
				if ok and s then
					local col = s.status == "ACTIVE" and "#5acc78" or "#dc5050"
					statusLbl.Text = string.format(
						"Automation Status: <font color=\"%s\"><b>%s</b></font>\n\n" ..
						"Elephant Team: <font color=\"#8c929e\">%s</font>\n" ..
						"Target Types: <font color=\"#f5c82d\">%s</font>\n" ..
						"Target Pets Ready: <font color=\"#8c929e\">%s</font>\n" ..
						"Pets at Max KG: <font color=\"#8c929e\">%s</font>\n\n" ..
						"Max Target Pets: <font color=\"#8c929e\">%s</font>\n" ..
						"Target Weight: <font color=\"#f5c82d\"><b>%s</b></font>",
						col, s.status, s.team, s.types, s.ready, s.maxKg, s.maxTarget, s.targetWeight)
				end
				task.wait(1.5)
			end
		end)

		-- Settings (dalam accordion yang sama)
		makeMultiDropdownDyn(acc, "V1 Pet Team", "Select elephant pet team (tetap di garden)",
			function() return ctx.inventoryPetOptions(CFG.elephantTeamUuids) end, CFG.elephantTeamUuids, function() persist() end, 2)
		makeMultiDropdown(acc, "V1 Target Pet Types", "Select pet types to auto-elephant (semua pet di game)",
			reg.PET_OPTIONS, CFG.elephantPetTypes, function() persist() end, 3)
		makeInput(acc, "Target Weight (KG)", "Berat max sebelum diganti (mis. 5.5)",
			function() return tostring(CFG.elephantTargetWeight) end,
			function(txt) CFG.elephantTargetWeight = tonumber(txt) or 5.5; persist() end, 4)
		makeInput(acc, "Max Target Pets", "Jumlah pet target aktif barengan",
			function() return tostring(CFG.elephantMaxPets) end,
			function(txt) CFG.elephantMaxPets = tonumber(txt) or 2; persist() end, 5)
		local refreshEleBar
		makeToggle(acc, "Enable Automation Elephant", "Rotasi pet target otomatis. OFF = cabut semua pet dari garden.",
			function() return CFG.elephantEnabled end,
			function(v)
				CFG.elephantEnabled = v; persist()
				if v then ctx.startElephant() else ctx.stopElephant() end
				if refreshEleBar then refreshEleBar() end
			end, 6)

		-- ===================== ELEPHANT V2 (swap gajah on lvl 40) =====================
		local pV2 = sub.pages["v2"]
		local acc2 = makeAccordion(pV2, "Automation Elephant V2", 1, true)

		local v2Lbl = mk("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1, Text = "Loading...",
			Font = F.reg, TextSize = 12, TextColor3 = C.txt,
			TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
			LineHeight = 1.3, RichText = true, LayoutOrder = 0
		}, acc2)
		mk("Frame", { Size = UDim2.new(1, 0, 0, 8), BackgroundTransparency = 1, LayoutOrder = 1 }, acc2)
		task.spawn(function()
			while ctx.alive() do
				if not onScreen(elephantPage) then task.wait(1) continue end
				local ok, s = pcall(function() return ctx.getElephantV2Summary() end)
				if ok and s then
					local col = s.status == "ACTIVE" and "#5acc78" or "#dc5050"
					v2Lbl.Text = string.format(
						"Automation Status: <font color=\"%s\"><b>%s</b></font>  |  <font color=\"#f5c82d\">%s</font>\n\n" ..
						"Elephant Team: <font color=\"#8c929e\">%s</font>\n" ..
						"Target Types: <font color=\"#f5c82d\">%s</font>\n" ..
						"Target Pets Ready: <font color=\"#8c929e\">%s</font>\n" ..
						"Pets at Max KG: <font color=\"#8c929e\">%s</font>\n" ..
						"Max Target Pets: <font color=\"#8c929e\">%s</font>  |  Target Weight: <font color=\"#f5c82d\"><b>%s</b></font>\n\n" ..
						"Gajah: <font color=\"#8c929e\">%s</font>\n" ..
						"Switch: <font color=\"#8c929e\">%s</font>\n" ..
						"Gajah masuk saat target Age >= <font color=\"#f5c82d\"><b>%s</b></font>",
						col, s.status, s.info, s.team, s.types, s.ready, s.maxKg, s.maxTarget, s.targetWeight, s.gajah, s.switch, s.level)
				end
				task.wait(0.5)
			end
		end)

		makeMultiDropdownDyn(acc2, "V2 Elephant Team", "Team standby di garden (sumber pilihan Pet Switch)",
			function() return ctx.inventoryPetOptions(CFG.elephantV2Team) end, CFG.elephantV2Team, function() persist() end, 2)
		makeMultiDropdown(acc2, "V2 Target Pet Types", "Select pet types to auto-level + elephant (semua pet di game)",
			reg.PET_OPTIONS, CFG.elephantV2Types, function() persist() end, 3)
		makeSingleDropdown(acc2, "Gajah Pet (Slot 1)", "Pilih gajah yang akan di-swap masuk saat target lvl 40",
			function() return ctx.elephantV2GajahOptions() end,
			function() return ctx.elephantV2Label(CFG.elephantV2Gajah) end,
			function(uuid) CFG.elephantV2Gajah = uuid; persist() end, 4)
		makeSingleDropdown(acc2, "Pet Switch (Slot 2)", "Pilih pet dari Team yang diganti oleh Gajah (biasanya Capy)",
			function() return ctx.elephantV2SwitchOptions() end,
			function() return ctx.elephantV2Label(CFG.elephantV2Switch) end,
			function(uuid) CFG.elephantV2Switch = uuid; persist() end, 5)
		makeInput(acc2, "Target Weight (KG)", "Berat max target sebelum dilepas (mis. 5.5)",
			function() return tostring(CFG.elephantV2Weight) end,
			function(txt) CFG.elephantV2Weight = tonumber(txt) or 5.5; persist() end, 6)
		makeInput(acc2, "Max Target Pets", "Jumlah pet target aktif barengan di garden",
			function() return tostring(CFG.elephantV2MaxPets) end,
			function(txt) CFG.elephantV2MaxPets = tonumber(txt) or 3; persist() end, 7)
		makeInput(acc2, "Trigger Level", "Level target buat masukin gajah (default 40)",
			function() return tostring(CFG.elephantV2Level) end,
			function(txt) CFG.elephantV2Level = tonumber(txt) or 40; persist() end, 8)
		makeToggle(acc2, "Enable Elephant V2", "Rotasi target + swap gajah otomatis saat target lvl 40. Jalan barengan PNP.",
			function() return CFG.elephantV2Enabled end,
			function(v)
				CFG.elephantV2Enabled = v; persist()
				if v then ctx.startElephantV2() else ctx.stopElephantV2() end
			end, 9)

		-- Start/Stop Bar for V1
		refreshEleBar = makeStartStopBar(elephantPage,
			function() return CFG.elephantEnabled end,
			function()
				CFG.elephantEnabled = true; persist(); ctx.startElephant()
			end,
			function()
				CFG.elephantEnabled = false; persist(); ctx.stopElephant()
			end, 999)
	end

	------------------------------------------------------------------ LEVELING
	local levelingPage = pageRef["Leveling"]
	do
		local levSub = makeSubTabs(levelingPage, {
			{ id = "v1", name = "Leveling V1" },
			{ id = "v2", name = "Leveling V2" },
		}, "v1", { hasBottomBar = false, hasInfoLine = false })

		local pLevV1 = levSub.pages["v1"]
		local pLevV2 = levSub.pages["v2"]

		-- Automation Leveling V1 — status + settings jadi satu accordion
		local levAcc = makeAccordion(pLevV1, "Automation Leveling V1", 1, true)

		local statusLbl = mk("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Text = "Loading stats...",
			Font = F.reg,
			TextSize = 13,
			TextColor3 = C.txt,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			LineHeight = 1.35,
			RichText = true,
			LayoutOrder = 0
		}, levAcc)
		-- spacer pemisah status & settings
		mk("Frame", { Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1, LayoutOrder = 1 }, levAcc)

		task.spawn(function()
			while ctx.alive() do
				if not onScreen(levelingPage) then task.wait(1) continue end
				local ok, s = pcall(function() return ctx.getLevelingSummary() end)
				if ok and s then
					local statusColor = s.status == "ACTIVE" and "#5acc78" or "#dc5050"
					statusLbl.Text = string.format(
						"Automation Status: <font color=\"%s\"><b>%s</b></font>\n\n" ..
						"<b>Current Settings:</b>\n" ..
						"Pet Team: <font color=\"#8c929e\">%s</font>\n" ..
						"Target Types: <font color=\"#f5c82d\">%s</font>\n" ..
						"Pets Ready to Level: <font color=\"#8c929e\">%s</font>\n" ..
						"Pets at Max Level: <font color=\"#8c929e\">%s</font>\n" ..
						"Max in Garden: <font color=\"#8c929e\">%s</font>\n\n" ..
						"Target Level: <font color=\"#f5c82d\"><b>%s</b></font>\n\n" ..
						"Ready: Settings configured",
						statusColor, s.status,
						s.team,
						s.types,
						s.ready,
						s.maxLvl,
						s.maxInGarden,
						s.targetLevel
					)
				end
				task.wait(1.5)
			end
		end)

		-- Settings (di accordion yang sama, setelah status + spacer)
		-- Leveling Pet Team (Multi-dropdown UUIDs)
		makeMultiDropdownDyn(levAcc, "Leveling Pet Team", "Select pets to keep in garden while leveling",
			function() return ctx.inventoryPetOptions(CFG.levelingTeamUuids) end, CFG.levelingTeamUuids, function() persist() end, 2)

		-- Leveling Pet Types (semua pet di game, bukan cuma yang di inventory)
		makeMultiDropdown(levAcc, "Leveling Pet Types", "Select pet types to auto-level (semua pet di game)",
			reg.PET_OPTIONS, CFG.levelingPetTypes, function() persist() end, 3)

		-- Target Level (Input)
		makeInput(levAcc, "Target Level", "Target level to reach before un-equipping",
			function() return tostring(CFG.levelingTargetLevel) end,
			function(txt) CFG.levelingTargetLevel = tonumber(txt) or 500; persist() end, 4)

		-- Max Pets in Garden (Input)
		makeInput(levAcc, "Max Pets in Garden", "Maximum active leveling pets allowed in garden",
			function() return tostring(CFG.levelingMaxPets) end,
			function(txt) CFG.levelingMaxPets = tonumber(txt) or 2; persist() end, 5)

		-- Enable Automation Leveling (Toggle)
		makeToggle(levAcc, "Enable Automation Leveling", "Equip and rotate pets automatically based on settings",
			function() return CFG.levelingEnabled end,
			function(v)
				CFG.levelingEnabled = v; persist()
				if v then ctx.startLeveling() else ctx.stopLeveling() end
			end, 6)

		---------------------------------------------------------- Automation Leveling V2 (2 phase)
		local lv2 = makeAccordion(pLevV2, "Automation Leveling V2", 1, true)

		local lv2Lbl = mk("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
			Text = "Loading...", Font = F.reg, TextSize = 13, TextColor3 = C.txt,
			TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, LineHeight = 1.35, RichText = true, LayoutOrder = 0
		}, lv2)
		mk("Frame", { Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1, LayoutOrder = 1 }, lv2)
		task.spawn(function()
			while ctx.alive() do
				if not onScreen(levelingPage) then task.wait(1) continue end
				local ok, s = pcall(function() return ctx.getLevelingV2Summary() end)
				if ok and s then
					local col = s.status == "ACTIVE" and "#5acc78" or "#dc5050"
					lv2Lbl.Text = string.format(
						"Automation Status: <font color=\"%s\"><b>%s</b></font>  |  <font color=\"#f5c82d\">%s</font>\n\n" ..
						"<b>Target Types:</b> <font color=\"#8c929e\">%s</font>\n\n" ..
						"<b>Phase 1</b> (→%s): team <font color=\"#8c929e\">%d</font> | antre <font color=\"#f5c82d\">%d</font> pet\n" ..
						"<b>Phase 2</b> (→%s): team <font color=\"#8c929e\">%d</font> | antre <font color=\"#f5c82d\">%d</font> pet\n" ..
						"<b>Pet at Max Level:</b> <font color=\"#5acc78\">%d</font> pet",
						col, s.status, s.phase, s.types,
						tostring(s.p1target), s.p1team, s.p1queue,
						tostring(s.p2target), s.p2team, s.p2queue,
						s.maxLvl or 0)
				end
				task.wait(1.5)
			end
		end)

		-- Target Pet Types (semua pet di game)
		makeMultiDropdown(lv2, "Leveling Target Pet Types", "Pet types to level up (semua pet di game)",
			reg.PET_OPTIONS, CFG.levelingV2PetTypes, function() persist() end, 2)

		-- Phase 1
		makeMultiDropdownDyn(lv2, "Leveling Phase 1 Pet Team", "Team for Phase 1 (Age 1 to Phase 1 Target)",
			function() return ctx.inventoryPetOptions(CFG.levelingV2P1Team) end, CFG.levelingV2P1Team, function() persist() end, 3)
		makeInput(lv2, "Leveling Phase 1 Target", "End of Phase 1 / start of Phase 2 (default 40)",
			function() return tostring(CFG.levelingV2P1Target) end,
			function(txt) CFG.levelingV2P1Target = tonumber(txt) or 40; persist() end, 4)
		makeInput(lv2, "Leveling Phase 1 Max Pets", "Max target pets in garden during Phase 1",
			function() return tostring(CFG.levelingV2P1Max) end,
			function(txt) CFG.levelingV2P1Max = tonumber(txt) or 3; persist() end, 5)

		-- Phase 2
		makeMultiDropdownDyn(lv2, "Leveling Phase 2 Pet Team", "Team for Phase 2 (Phase 1 Target to Final Target)",
			function() return ctx.inventoryPetOptions(CFG.levelingV2P2Team) end, CFG.levelingV2P2Team, function() persist() end, 6)
		makeInput(lv2, "Leveling Phase 2 Target", "Final target level (default 500 = max age)",
			function() return tostring(CFG.levelingV2P2Target) end,
			function(txt) CFG.levelingV2P2Target = tonumber(txt) or 500; persist() end, 7)
		makeInput(lv2, "Leveling Phase 2 Max Pets", "Max target pets in garden during Phase 2",
			function() return tostring(CFG.levelingV2P2Max) end,
			function(txt) CFG.levelingV2P2Max = tonumber(txt) or 1; persist() end, 8)

		-- Enable
		makeToggle(lv2, "Enable Automation Leveling V2", "Level pet 2 tahap (Phase 1 team -> Phase 2 team)",
			function() return CFG.levelingV2Enabled end,
			function(v)
				CFG.levelingV2Enabled = v; persist()
				if v then ctx.startLevelingV2() else ctx.stopLevelingV2() end
			end, 9)
	end

	------------------------------------------------------------------ MUTATION
	local mutationPage = pageRef["Mutation"]
	do
		local mutSub = makeSubTabs(mutationPage, {
			{ id = "machine", name = "Machine" },
			{ id = "cleanse", name = "Aura Cleanse" },
		}, "machine", { hasBottomBar = false, hasInfoLine = false })

		local pMutMachine = mutSub.pages["machine"]
		local pMutCleanse = mutSub.pages["cleanse"]

		-- 1. Status Accordion (Machine)
		local statusAcc = makeAccordion(pMutMachine, "Automation Mutation Machine", 1, true)
		
		local statusLbl = mk("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Text = "Loading stats...",
			Font = F.reg,
			TextSize = 13,
			TextColor3 = C.txt,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			LineHeight = 1.35,
			RichText = true,
			LayoutOrder = 0
		}, statusAcc)
		mk("Frame", { Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1, LayoutOrder = 1 }, statusAcc)

		task.spawn(function()
			while ctx.alive() do
				if not onScreen(mutationPage) then task.wait(1) continue end
				local ok, s = pcall(function() return ctx.getMutationSummary() end)
				if ok and s then
					local statusColor = s.status == "ACTIVE" and "#5acc78" or "#dc5050"
					statusLbl.Text = string.format(
						"Status: <font color=\"%s\"><b>%s</b></font>\n" ..
						"Phase: <b>%s</b>\n\n" ..
						"EXP Team: <font color=\"#8c929e\">%d pets</font>\n" ..
						"Boost Team: <font color=\"#8c929e\">%d pets</font>\n" ..
						"Phoenix Team: <font color=\"#8c929e\">%d pets</font>\n\n" ..
						"Target Types: <font color=\"#f5c82d\">%s</font>\n" ..
						"Keep Mutations: <font color=\"#f5c82d\">%s</font>\n" ..
						"Target Age: <font color=\"#f5c82d\"><b>%s</b></font>\n\n" ..
						"Machine: <font color=\"#85d0ff\"><b>%s</b></font>\n\n" ..
						"Target Pets Ready: <font color=\"#8c929e\">%d pets</font>\n" ..
						"Target Pets Done: <font color=\"#5acc78\"><b>%d pets</b></font>",
						statusColor, s.status,
						s.phase,
						s.expCount,
						s.boostCount,
						s.phoenixCount,
						s.types,
						s.mutations,
						tostring(s.targetAge),
						s.machine,
						s.readyCount,
						s.doneCount
					)
				end
				task.wait(1.5)
			end
		end)

		-- Settings (dalam accordion yang sama dengan status)
		local settingsAcc = statusAcc

		-- EXP Team (Multi-dropdown UUIDs)
		makeMultiDropdownDyn(settingsAcc, "EXP Team (Leveling)", "Pets for leveling target to age 50/500",
			function() return ctx.inventoryPetOptions(CFG.mutationExpTeam) end, CFG.mutationExpTeam, function() persist() end, 2)

		-- Boost Team (Machine) (Multi-dropdown UUIDs)
		makeMultiDropdownDyn(settingsAcc, "Boost Team (Machine)", "Pets for boosting mutation machine speed",
			function() return ctx.inventoryPetOptions(CFG.mutationBoostTeam) end, CFG.mutationBoostTeam, function() persist() end, 3)

		-- Phoenix Team (Claim) (Multi-dropdown UUIDs)
		makeMultiDropdownDyn(settingsAcc, "Phoenix Team (Claim)", "Pets for claiming mutated pet",
			function() return ctx.inventoryPetOptions(CFG.mutationPhoenixTeam) end, CFG.mutationPhoenixTeam, function() persist() end, 4)

		-- Target Pet Types (semua pet di game, bukan cuma yang di inventory)
		makeMultiDropdown(settingsAcc, "Target Pet Types", "Pet types to mutate (semua pet di game)",
			reg.PET_OPTIONS, CFG.mutationTargetTypes, function() persist() end, 5)

		-- Target Mutations (Multi-dropdown Mutations)
		makeMultiDropdown(settingsAcc, "Target Mutations (Machine)", "Stop when pet gets these mutations (hanya mutasi mesin)",
			ctx.reg.MACHINE_MUT_OPTIONS or ctx.reg.MUT_OPTIONS or {"None"}, CFG.mutationTargetMutations, function() persist() end, 6)

		-- Target Age (Input)
		makeInput(settingsAcc, "Target Age", "Level to reach before submitting (e.g. 50 or 500)",
			function() return tostring(CFG.mutationTargetAge) end,
			function(txt) CFG.mutationTargetAge = tonumber(txt) or 50; persist() end, 7)

		-- Delay Auto Claim (Input)
		makeInput(settingsAcc, "Delay Auto Claim (sec)", "Wait before claiming mutated pet from machine",
			function() return tostring(CFG.mutationDelayAutoClaim) end,
			function(txt) CFG.mutationDelayAutoClaim = tonumber(txt) or 0.5; persist() end, 8)

		-- Enable Auto Mutation Machine (Toggle)
		ctx.state.mutationToggleRender = makeToggle(settingsAcc, "Enable Auto Mutation Machine", "Submit, start, and claim mutated pets automatically",
			function() return CFG.mutationEnabled end,
			function(v)
				CFG.mutationEnabled = v; persist()
				if v then ctx.startMutation() else ctx.stopMutation() end
			end, 9)

		-- Accordion: Automation Mutation (mutasi via aura + cleanse)
		local cleanseAcc = makeAccordion(pMutCleanse, "Automation Mutation (Aura)", 1, true)

		-- Status (live)
		local cleanseLbl = mk("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1, Text = "Loading stats...",
			Font = F.reg, TextSize = 13, TextColor3 = C.txt,
			TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
			LineHeight = 1.35, RichText = true, LayoutOrder = 0
		}, cleanseAcc)
		mk("Frame", { Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1, LayoutOrder = 1 }, cleanseAcc)
		task.spawn(function()
			while ctx.alive() do
				if not onScreen(mutationPage) then task.wait(1) continue end
				local ok, s = pcall(function() return ctx.getCleanseSummary() end)
				if ok and s then
					local col = s.status == "ACTIVE" and "#5acc78" or "#dc5050"
					local alreadyLines = ""
					for _, k in ipairs(s.keepOrder) do
						alreadyLines = alreadyLines .. string.format("- Already %s: <font color=\"#8c929e\">%d pets</font>\n", k, s.already[k] or 0)
					end
					cleanseLbl.Text = string.format(
						"Automation Status: <font color=\"%s\"><b>%s</b></font>\n\n" ..
						"Mutation Team: <font color=\"#8c929e\">%d pets</font>\n" ..
						"Target Types: <font color=\"#f5c82d\">%s</font>\n" ..
						"Mutations to Keep: <font color=\"#f5c82d\">%s</font>\n\n" ..
						"Pet Statistics:\n" ..
						"- Pets Ready to Mutation: <font color=\"#8c929e\">%d pets</font>\n" ..
						"%s\n" ..
						"Max in Garden: <font color=\"#8c929e\">%d pets</font>\n\n" ..
						"Status: <font color=\"#85d0ff\">%s</font>",
						col, s.status, s.team, s.types, s.keep, s.ready, alreadyLines, s.maxPets, s.phase)
				end
				task.wait(1.5)
			end
		end)

		makeMultiDropdownDyn(cleanseAcc, "Pet Team for Mutation", "Pet aura pemberi mutasi (tetap di garden)",
			function() return ctx.inventoryPetOptions(CFG.cleanseTeamUuids) end, CFG.cleanseTeamUuids, function() persist() end, 2)
		makeMultiDropdown(cleanseAcc, "Pet Types for Mutation", "Tipe pet target yang mau dimutasi (semua pet di game)",
			reg.PET_OPTIONS, CFG.cleansePetTypes, function() persist() end, 3)
		makeMultiDropdown(cleanseAcc, "Mutations to Keep", "Mutasi ini disimpan (won't be cleansed)",
			ctx.reg.MUT_OPTIONS or {"None"}, CFG.cleanseKeepMutations, function() persist() end, 4)
		makeInput(cleanseAcc, "Max Pets in Garden", "Max pet target di garden barengan",
			function() return tostring(CFG.cleanseMaxPets) end,
			function(txt) CFG.cleanseMaxPets = tonumber(txt) or 2; persist() end, 5)
		makeToggle(cleanseAcc, "Enable Auto Mutation", "Mutasi target via aura; cleanse mutasi salah, simpan mutasi keep",
			function() return CFG.cleanseEnabled end,
			function(v)
				CFG.cleanseEnabled = v; persist()
				if v then ctx.startCleanse() else ctx.stopCleanse() end
			end, 6)
	end

	------------------------------------------------------------------ PET (PNP)
	local pet = pageRef["Pet"]
	local v1Render, v2Render -- buat sync visual mutual-exclusion

	local petSub = makeSubTabs(pet, {
		{ id = "v1",    name = "PnP V1" },
		{ id = "v2",    name = "PnP V2" },
		{ id = "boost", name = "Boost Pet" },
	}, "v1", { hasBottomBar = false, hasInfoLine = false })

	local pPetV1 = petSub.pages["v1"]
	local pPetV2 = petSub.pages["v2"]
	local pPetBoost = petSub.pages["boost"]

	------------------------------------------------------------------ PnP V1 (polling)
	local pnp = makeAccordion(pPetV1, "Automation Pickup Pet V1", 1, true)
	makeMultiDropdownDyn(pnp, "Select Pets for Pickup [V1]", "Pilih pet dari backpack (kosong = semua yg di garden)",
		function() return ctx.inventoryPetOptions(CFG.pnpUuids) end, CFG.pnpUuids, function() persist() end, 1)
	makeInput(pnp, "Pickup Delay (Seconds) [V1]", "Jeda tiap siklus (idealnya = saat skill ready)",
		function() return CFG.pickupDelay end,
		function(txt) CFG.pickupDelay = tonumber(txt) or 0.3; persist() end, 2)
	makeInput(pnp, "Equip Delay (Seconds) [V1]", "Jeda antara unequip -> equip",
		function()
			if CFG.equipDelay == 1e-20 or CFG.equipDelay == 0 or not CFG.equipDelay then return "1E-20" end
			return tostring(CFG.equipDelay)
		end,
		function(txt)
			if tostring(txt):upper():find("1E%-20") then
				CFG.equipDelay = 1e-20
			else
				CFG.equipDelay = tonumber(txt) or 1e-20
			end
			persist()
		end, 3)
	makeInput(pnp, "Scan Interval (Seconds) [V1]", "Frekuensi cek cooldown (kecil = makin ketat, min 0.01)",
		function() return CFG.pnpScanInterval end,
		function(txt) CFG.pnpScanInterval = math.max(0.01, tonumber(txt) or 0.05); persist() end, 4)
	v1Render = makeToggle(pnp, "Enable Automation Pickup V1", "Polling GetPetCooldown (lama). Nyalain ini matiin V2.",
		function() return CFG.pnpEnabled end,
		function(v)
			CFG.pnpEnabled = v; persist()
			if v then
				CFG.pnpV2Enabled = false; persist()
				if ctx.stopPnpV2 then ctx.stopPnpV2() end
				if type(v2Render) == 'function' then pcall(v2Render) elseif type(v2Render) == 'table' and type(v2Render.refresh) == 'function' then pcall(v2Render.refresh) end
				if ctx.startPnpV1 then ctx.startPnpV1() end
			else
				if ctx.stopPnpV1 then ctx.stopPnpV1() end
			end
		end, 5)

	------------------------------------------------------------------ PnP V2 (event-driven)
	local pnp2 = makeAccordion(pPetV2, "Automation Pickup Pet V2", 1, true)
	makeMultiDropdownDyn(pnp2, "Select Pets for Pickup [V2]", "Pilih pet dari backpack (kosong = semua yg di garden)",
		function() return ctx.inventoryPetOptions(CFG.pnpV2Uuids) end, CFG.pnpV2Uuids, function() persist() end, 1)
	makeInput(pnp2, "Pickup Delay (Seconds) [V2]", "Jeda sebelum tiap pickup",
		function() return CFG.pnpV2PickupDelay end,
		function(txt) CFG.pnpV2PickupDelay = tonumber(txt) or 0.05; persist() end, 2)
	makeInput(pnp2, "Equip Delay (Seconds) [V2]", "Jeda antara unequip -> equip",
		function() return CFG.pnpV2EquipDelay end,
		function(txt) CFG.pnpV2EquipDelay = tonumber(txt) or 0.03; persist() end, 3)
	makeInput(pnp2, "Scan Interval (Seconds) [V2]", "Frekuensi cek cd dari cache event (min 0.02)",
		function() return CFG.pnpV2ScanInterval end,
		function(txt) CFG.pnpV2ScanInterval = math.max(0.02, tonumber(txt) or 0.05); persist() end, 4)
	v2Render = makeToggle(pnp2, "Enable Automation Pickup V2", "Event-driven (PetCooldownsUpdated), stabil. Nyalain ini matiin V1.",
		function() return CFG.pnpV2Enabled end,
		function(v)
			CFG.pnpV2Enabled = v; persist()
			if v then
				CFG.pnpEnabled = false; persist()
				if ctx.stopPnpV1 then ctx.stopPnpV1() end
				if type(v1Render) == 'function' then pcall(v1Render) elseif type(v1Render) == 'table' and type(v1Render.refresh) == 'function' then pcall(v1Render.refresh) end
				if ctx.startPnpV2 then ctx.startPnpV2() end
			else
				if ctx.stopPnpV2 then ctx.stopPnpV2() end
			end
		end, 5)

	-- Accordion: Automation Boost Pet
	local boostAcc = makeAccordion(pPetBoost, "Automation Boost Pet", 1, true)
	makeMultiDropdownDyn(boostAcc, "Select Pets to Boost", "Pilih pet yang mau di-boost (aktif di garden)",
		function() return ctx.inventoryPetOptions(CFG.boostPetUuids) end, CFG.boostPetUuids, function() persist() end, 1)
	makeMultiDropdownDyn(boostAcc, "Select Boost Items", "Pilih item boost (Pet Toy) yang dipakai",
		function() return ctx.getBoostItemOptions(CFG.boostItemNames) end, CFG.boostItemNames, function() persist() end, 2)
	makeToggle(boostAcc, "Enable Automation Boost", "Auto apply boost item ke pet, re-apply pas boost habis",
		function() return CFG.boostEnabled end,
		function(v)
			CFG.boostEnabled = v; persist()
			if v then ctx.startBoostPet() end
		end, 3)

	------------------------------------------------------------------ INVENTORY
	local inv = pageRef["Inventory"]

	local invSub = makeSubTabs(inv, {
		{ id = "trade_ticket", name = "Trade Ticket" },
		{ id = "trade_gift",   name = "Trade Gift" },
		{ id = "accept",       name = "Auto Accept" },
		{ id = "fav",          name = "Favorite" },
	}, "trade_ticket", { hasBottomBar = false, hasInfoLine = false })

	local pInvTicket = invSub.pages["trade_ticket"]
	local pInvGift   = invSub.pages["trade_gift"]
	local pInvAccept = invSub.pages["accept"]
	local pInvFav    = invSub.pages["fav"]

	local targetOptions = function()
		local out = {}
		for _, n in ipairs(ctx.getPlayers()) do out[#out + 1] = n end
		return out
	end

	------------------------------------------------------------------ 1) SUB-TAB: TRADE TICKET
	local atTicket = makeAccordion(pInvTicket, "Auto Trade by Ticket", 1, true)

	makeSingleDropdown(atTicket, "Target Player", "Select player to trade with", targetOptions,
		function() return CFG.targetPlayer end,
		function(v) CFG.targetPlayer = v; persist() end, 1)

	makeMultiDropdown(atTicket, "Pet Types to Trade", "Filter pets by type (empty = all non-favorite)",
		reg.PET_OPTIONS, CFG.petTypes, function() persist() end, 2)

	makeInput(atTicket, "Weight Filter (KG)", "pakai berat tampilan game | 0=off | +6 = min 6kg | -6 = max 6kg",
		function() return CFG.weightFilter end,
		function(txt) CFG.weightFilter = tonumber(txt) or 0; persist() end, 3)

	makeInput(atTicket, "Age Filter", "0 = off | +50 = at least age 50 | -50 = at most age 50",
		function() return CFG.ageFilter end,
		function(txt) CFG.ageFilter = tonumber(txt) or 0; persist() end, 4)

	makeInput(atTicket, "Pets Per Trade", "Number of pets to add each trade",
		function() return CFG.petsPerTrade end,
		function(txt) local n = tonumber(txt); CFG.petsPerTrade = (n and n > 0) and math.floor(n) or 1; persist() end, 5)

	makeInput(atTicket, "Total Trades", "How many trades to perform",
		function() return CFG.totalTrades end,
		function(txt) local n = tonumber(txt); CFG.totalTrades = (n and n >= 0) and math.floor(n) or 0; persist() end, 6)

	makeToggle(atTicket, "Auto Unfavorite [Trade]", "Remove favorite before trading",
		function() return CFG.autoUnfavorite end,
		function(v) CFG.autoUnfavorite = v; persist() end, 7)

	-- Trade Ticket Status
	local stFrameTicket = mk("Frame", { Size = UDim2.new(1, 0, 0, 66), BackgroundTransparency = 1, LayoutOrder = 0 }, atTicket)
	mk("TextLabel", { Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 4), BackgroundTransparency = 1, Text = "Ticket Trade Status", Font = F.bold, TextSize = 14, TextColor3 = C.txt, TextXAlignment = Enum.TextXAlignment.Left }, stFrameTicket)
	local stLblTicket = mk("TextLabel", { Size = UDim2.new(1, 0, 0, 44), Position = UDim2.fromOffset(0, 22), BackgroundTransparency = 1, Text = "Completed: 0 / 0\nPet cocok filter: -\nStatus: IDLE", Font = F.reg, TextSize = 11, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, RichText = true }, stFrameTicket)
	function ctx.refreshTradeStatus()
		local avail = ctx.countMatchingPets and ctx.countMatchingPets(false) or 0
		local availCol = avail > 0 and "#5acc78" or "#dc5050"
		local statusText = (CFG.tradeMethod == "ticket" and ctx.state.tradeRunning) and ctx.state.status or (CFG.tradeTicketEnabled and "RUNNING" or "IDLE")
		local comp = (CFG.tradeMethod == "ticket") and ctx.state.completed or 0
		stLblTicket.Text = ("Completed: %d / %d\nPet cocok filter: <font color=\"%s\"><b>%d</b></font>\nStatus: %s"):format(
			comp, CFG.totalTrades, availCol, avail, statusText)
	end
	task.spawn(function()
		while ctx.alive() do
			if not onScreen(stLblTicket) then task.wait(2) continue end
			pcall(function() ctx.refreshTradeStatus() end)
			task.wait(2)
		end
	end)

	-- Enable Trade Ticket Toggle
	makeToggle(atTicket, "Enable Trade by Ticket", "Kirim trade request tiket, isi pet, terima & confirm",
		function() return CFG.tradeTicketEnabled or (CFG.tradeEnabled and CFG.tradeMethod == "ticket") end,
		function(v)
			CFG.tradeTicketEnabled = v
			CFG.tradeEnabled = v
			if v then
				CFG.tradeGiftEnabled = false
				CFG.tradeMethod = "ticket"
				persist()
				ctx.state.completed = 0
				ctx.startTrade("ticket")
			else
				persist()
				if CFG.tradeMethod == "ticket" then
					ctx.stopTrade()
				end
			end
			ctx.refreshTradeStatus()
			if ctx.refreshGiftStatus then ctx.refreshGiftStatus() end
		end, 9)

	------------------------------------------------------------------ 2) SUB-TAB: TRADE GIFT
	local atGift = makeAccordion(pInvGift, "Auto Trade by Gift", 1, true)

	makeSingleDropdown(atGift, "Target Player", "Select player to send gifts to", targetOptions,
		function() return (CFG.giftTargetPlayer ~= "" and CFG.giftTargetPlayer) or CFG.targetPlayer end,
		function(v) CFG.giftTargetPlayer = v; persist() end, 1)

	makeMultiDropdown(atGift, "Pet Types to Gift", "Filter pets by type (empty = all non-favorite)",
		reg.PET_OPTIONS, CFG.giftPetTypes, function() persist() end, 2)

	makeInput(atGift, "Weight Filter (KG)", "0=off | +6 = min 6kg | -6 = max 6kg",
		function() return CFG.giftWeightFilter end,
		function(txt) CFG.giftWeightFilter = tonumber(txt) or 0; persist() end, 3)

	makeInput(atGift, "Age Filter", "0=off | +50 = at least age 50 | -50 = at most age 50",
		function() return CFG.giftAgeFilter end,
		function(txt) CFG.giftAgeFilter = tonumber(txt) or 0; persist() end, 4)

	makeInput(atGift, "Pets Per Batch", "Jumlah pet di-gift per ronde",
		function() return CFG.giftPetsPerBatch end,
		function(txt) local n = tonumber(txt); CFG.giftPetsPerBatch = (n and n > 0) and math.floor(n) or 1; persist() end, 5)

	makeInput(atGift, "Total Gifts", "Berapa pet/gift yang dikirim sebelum berhenti",
		function() return CFG.giftTotalGifts end,
		function(txt) local n = tonumber(txt); CFG.giftTotalGifts = (n and n >= 0) and math.floor(n) or 0; persist() end, 6)

	makeToggle(atGift, "Auto Unfavorite [Gift]", "Remove favorite before sending gift",
		function() return CFG.giftAutoUnfavorite end,
		function(v) CFG.giftAutoUnfavorite = v; persist() end, 7)

	-- Gift Status
	local stFrameGift = mk("Frame", { Size = UDim2.new(1, 0, 0, 66), BackgroundTransparency = 1, LayoutOrder = 0 }, atGift)
	mk("TextLabel", { Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 4), BackgroundTransparency = 1, Text = "Gift Trade Status", Font = F.bold, TextSize = 14, TextColor3 = C.txt, TextXAlignment = Enum.TextXAlignment.Left }, stFrameGift)
	local stLblGift = mk("TextLabel", { Size = UDim2.new(1, 0, 0, 44), Position = UDim2.fromOffset(0, 22), BackgroundTransparency = 1, Text = "Completed: 0 / 0\nPet cocok filter: -\nStatus: IDLE", Font = F.reg, TextSize = 11, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, RichText = true }, stFrameGift)
	function ctx.refreshGiftStatus()
		local avail = ctx.countMatchingPets and ctx.countMatchingPets(true) or 0
		local availCol = avail > 0 and "#5acc78" or "#dc5050"
		local statusText = (CFG.tradeMethod == "gift" and ctx.state.tradeRunning) and ctx.state.status or (CFG.tradeGiftEnabled and "RUNNING" or "IDLE")
		local comp = (CFG.tradeMethod == "gift") and ctx.state.completed or 0
		stLblGift.Text = ("Completed: %d / %d gifts\nPet cocok filter: <font color=\"%s\"><b>%d</b></font>\nStatus: %s"):format(
			comp, CFG.giftTotalGifts, availCol, avail, statusText)
	end
	task.spawn(function()
		while ctx.alive() do
			if not onScreen(stLblGift) then task.wait(2) continue end
			pcall(function() ctx.refreshGiftStatus() end)
			task.wait(2)
		end
	end)

	-- Enable Trade Gift Toggle
	makeToggle(atGift, "Enable Trade by Gift", "Kirim gift pet langsung tanpa tiket (cepat & otomatis)",
		function() return CFG.tradeGiftEnabled or (CFG.tradeEnabled and CFG.tradeMethod == "gift") end,
		function(v)
			CFG.tradeGiftEnabled = v
			if v then
				CFG.tradeTicketEnabled = false
				CFG.tradeEnabled = false
				CFG.tradeMethod = "gift"
				persist()
				ctx.state.completed = 0
				ctx.startTrade("gift")
			else
				persist()
				if CFG.tradeMethod == "gift" then
					ctx.stopTrade()
				end
			end
			ctx.refreshGiftStatus()
			if ctx.refreshTradeStatus then ctx.refreshTradeStatus() end
		end, 9)

	-- Accordion: Automation Accept
	local acc = makeAccordion(pInvAccept, "Automation Accept", 1, true)
	makeToggle(acc, "Automation Accept Gifts", "Automation accept incoming gifts",
		function() return CFG.acceptGifts end,
		function(v) CFG.acceptGifts = v; persist() end, 1)
	makeToggle(acc, "Automation Accept Trades", "Automation accept incoming trades",
		function() return CFG.acceptTrades end,
		function(v) CFG.acceptTrades = v; persist() end, 2)

	-- Accordion: Automation Favourite Pets
	local fav = makeAccordion(pInvFav, "Automation Favourite Pets", 1, true)
	makeToggle(fav, "Auto Favourite Pets", "Automatically favorite selected pet types",
		function() return CFG.autoFavorite end,
		function(v) CFG.autoFavorite = v; persist(); if v then ctx.startAutoFavorite() else ctx.stopAutoFavorite() end end, 1)
	makeMultiDropdown(fav, "Favourite Pet Types", "Pet types to keep favorited",
		reg.PET_OPTIONS, CFG.favoritePetTypes, function() persist() end, 2)

	-- Accordion: Automation Unfavourite Pets
	local unfav = makeAccordion(pInvFav, "Automation Unfavourite Pets", 2, true)
	makeToggle(unfav, "Auto Unfavourite Pets", "Automatically unfavorite selected pet types",
		function() return CFG.autoUnfavoritePets end,
		function(v)
			CFG.autoUnfavoritePets = v; persist()
			if v and ctx.startAutoUnfavorite then ctx.startAutoUnfavorite()
			elseif ctx.stopAutoUnfavorite then ctx.stopAutoUnfavorite() end
		end, 1)
	makeMultiDropdown(unfav, "Unfavourite Pet Types", "Pet types to automatically unfavorite (kosong = semua pet)",
		reg.PET_OPTIONS, CFG.unfavoritePetTypes, function() persist() end, 2)

	------------------------------------------------------------------ MISC (log & webhooks)
	local misc = pageRef["Misc"]
	local miscSub = makeSubTabs(misc, {
		{ id = "player_esp", name = "Player & ESP" },
		{ id = "rejoin",     name = "Rejoin" },
		{ id = "webhook",    name = "Webhook" },
		{ id = "perf",       name = "Performance" },
	}, "player_esp", { hasBottomBar = false, hasInfoLine = false })

	local pMiscPlayer  = miscSub.pages["player_esp"]
	local pMiscRejoin  = miscSub.pages["rejoin"]
	local pMiscWebhook = miscSub.pages["webhook"]
	local pMiscPerf    = miscSub.pages["perf"]

	-- Player Accordion (Noclip / Walk Speed / Infinity Jump)
	local plAcc = makeAccordion(pMiscPlayer, "Player", 1, true)
	makeToggle(plAcc, "Noclip", "Walk through walls and obstacles",
		function() return CFG.noclipEnabled end,
		function(v) if ctx.setNoclip then ctx.setNoclip(v) end; persist() end, 1)
	makeInput(plAcc, "Walk Speed", "Player walk speed (default 16)",
		function() return tostring(CFG.walkSpeed) end,
		function(t) CFG.walkSpeed = tonumber(t) or 16; if ctx.applyWalkSpeed then ctx.applyWalkSpeed() end; persist() end, 2)
	makeToggle(plAcc, "Enable Walk Speed", "Apply custom walk speed",
		function() return CFG.walkSpeedEnabled end,
		function(v) if ctx.setWalkSpeed then ctx.setWalkSpeed(v) end; persist() end, 3)
	makeToggle(plAcc, "Infinity Jump", "Jump in mid-air infinitely",
		function() return CFG.infJumpEnabled end,
		function(v) if ctx.setInfJump then ctx.setInfJump(v) end; persist() end, 4)

	-- ESP Label Accordion
	local espAcc = makeAccordion(pMiscPlayer, "ESP Label (Pet & Egg)", 2, true)
	makeToggle(espAcc, "Enable ESP Label", "Label melayang di atas pet (nama+berat) & egg (nama+waktu hatch)",
		function() return CFG.espEnabled end,
		function(v)
			CFG.espEnabled = v; persist()
			if v then ctx.startEsp() else ctx.stopEsp() end
		end, 1)

	-- ESP Base Weight (Inventory) Accordion
	local espInvAcc = makeAccordion(pMiscPlayer, "ESP Base Weight (Inventory)", 3, false)
	makeToggle(espInvAcc, "Enable ESP Base Weight", "Tampilkan Base Weight di tiap slot pet saat buka inventory",
		function() return CFG.espInvEnabled end,
		function(v)
			CFG.espInvEnabled = v; persist()
			if v then ctx.startEspInv() else ctx.stopEspInv() end
		end, 1)
	local espInvModeOpts = { { name = "base", display = "Base Weight Only" }, { name = "age", display = "Base + Age" }, { name = "max", display = "Base + Max" } }
	makeSingleDropdown(espInvAcc, "Tampilan", "Pilih data yang tampil di label pet.",
		function() return espInvModeOpts end,
		function() for _, o in ipairs(espInvModeOpts) do if o.name == CFG.espInvMode then return o.display end end return "Base + Age" end,
		function(code) CFG.espInvMode = code; persist() end, 2)

	-- Auto-Reconnect toggle (rejoin otomatis kalau ke-kick / disconnect)
	local reconCard = mk("Frame", { Size = UDim2.new(1, 0, 0, 56), BackgroundColor3 = C.row, LayoutOrder = 1 }, pMiscRejoin)
	corner(reconCard, 10); stroke(reconCard); pad(reconCard, 12, 12, 0, 0)
	makeToggle(reconCard, "Auto Reconnect", "Rejoin otomatis kalau ke-kick / disconnect",
		function() return CFG.autoReconnect ~= false end,
		function(v) CFG.autoReconnect = v; persist() end, 1)

	-- Periodic Rejoin (Interval) Accordion
	local rcAcc = makeAccordion(pMiscRejoin, "Periodic Rejoin (Interval)", 2, true)
	-- countdown live di paling atas
	local rcLbl = mk("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
		Text = "Rejoin: OFF", Font = F.bold, TextSize = 15,
		TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 0,
	}, rcAcc)
	mk("Frame", { Size = UDim2.new(1, 0, 0, 8), BackgroundTransparency = 1, LayoutOrder = 0 }, rcAcc)
	task.spawn(function()
		while ctx.alive() do
			if CFG.reconnectEnabled then
				local rem = ctx.state.reconnectRemaining
				if rem then
					rcLbl.Text = ("⏱ Rejoin in: %d:%02d"):format(math.floor(rem / 60), rem % 60)
				else
					rcLbl.Text = "⏱ Rejoin: ON"
				end
				rcLbl.TextColor3 = C.acc
			else
				rcLbl.Text = "Rejoin: OFF"
				rcLbl.TextColor3 = C.sub
			end
			task.wait(0.5)
		end
	end)
	makeInput(rcAcc, "Interval (menit)", "Rejoin server berkala tiap sekian menit (mis. 1 = tiap 1 menit).",
		function() return tostring(CFG.reconnectInterval) end,
		function(t) CFG.reconnectInterval = tonumber(t) or 5; persist() end, 1)
	makeToggle(rcAcc, "Periodic Rejoin", "Rejoin server berkala tiap interval waktu",
		function() return CFG.reconnectEnabled end,
		function(v) CFG.reconnectEnabled = v; persist(); if v and ctx.startReconnect then ctx.startReconnect() end end, 2)

	-- Webhook Settings Accordion
	local whAcc = makeAccordion(pMiscWebhook, "Discord Webhook Settings", 1, true)

	-- Discord Webhook URL Input
	makeInput(whAcc, "Discord Webhook URL", "Webhook URL for automation updates (Leveling, Mutation & Elephant)",
		function() return CFG.webhookUrl end,
		function(txt) CFG.webhookUrl = txt; persist() end, 1)

	-- Test Webhook Connection (Button)
	makeButton(whAcc, "Test Webhook Connection", "Send a test notification to your Discord channel",
		function()
			if not CFG.webhookUrl or CFG.webhookUrl == "" then
				ctx.log("[Webhook Test] Gagal: Webhook URL kosong!")
				return
			end
			ctx.log("[Webhook Test] Mengirim test payload...")
			task.spawn(function()
				local sendWebhook = ctx.sendWebhook
				if sendWebhook then
					pcall(function()
						sendWebhook(CFG.webhookUrl, {
							embeds = {
								{
									title = "Webhook Connection Test",
									description = "Koneksi Discord Webhook berhasil tersambung dengan CeszParadise Garden!",
									color = 3066993, -- Green
									fields = {
										{
											name = "Profile :",
											value = string.format("> Username : ||%s||", ctx.LP.Name),
											inline = false
										}
									},
									footer = {
										text = os.date("%B %d | %I:%M %p"),
										icon_url = "https://raw.githubusercontent.com/milmscr/opoki/main/tegalan/Logo/logo_icon.png"
									}
								}
							}
						}, ctx)
					end)
				else
					ctx.log("[Webhook Test] Gagal meload modul sender.")
				end
			end)
		end, 2)

	-- Performance / Graphics Optimization Accordion
	local perfAcc = makeAccordion(pMiscPerf, "Performance", 1, true)
	makeToggle(perfAcc, "Hide My Garden Plants", "Hide plants on your own farm for better FPS",
		function() return CFG.hideMyPlants end,
		function(v) if ctx.setHidePlants then ctx.setHidePlants("mine", v) end; persist() end, 1)
	makeToggle(perfAcc, "Hide Other Gardens Plants", "Hide plants on other players' farms",
		function() return CFG.hideOtherPlants end,
		function(v) if ctx.setHidePlants then ctx.setHidePlants("other", v) end; persist() end, 2)
	makeToggle(perfAcc, "Auto Remove Spider Web FX", "Continuously remove spider web particle effects",
		function() return CFG.autoRemoveWebFx end,
		function(v) if ctx.setAutoRemoveWeb then ctx.setAutoRemoveWeb(v) end; persist() end, 3)
	mk("TextLabel", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = "- [ Graphics Optimization ] -", Font = F.bold, TextSize = 12, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 4 }, perfAcc)
	makeSingleDropdown(perfAcc, "Performance Mode", "Off: normal. Low: matiin shadow. Extreme: matiin semua efek partikel.",
		function() return ctx.getPerfModeOptions() end,
		function() local m = CFG.perfMode or "off"; for _, o in ipairs(ctx.getPerfModeOptions()) do if o.name == m then return o.display end end return "Off" end,
		function(code) if ctx.setPerfMode then ctx.setPerfMode(code) end; persist() end, 5)
	makeToggle(perfAcc, "Disable 3D Rendering", "Stop rendering the 3D world (huge FPS, black screen)",
		function() return CFG.disable3d end,
		function(v) if ctx.setDisable3d then ctx.setDisable3d(v) end; persist() end, 6)

	ctx.refreshTradeStatus()
end
