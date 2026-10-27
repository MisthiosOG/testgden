--[[ registry.lua — opsi dropdown pet type & mutation. ]]
return function(ctx)
	local PetEggs   = ctx.deps.PetEggs
	local EnumToMut = ctx.deps.EnumToMut

	-- Daftar pet type unik & pemetaan ke egg asal (format "Pet - Egg" apabila dari egg).
	local RAW_PET_OPTIONS = {} -- nama pet polos (mis. "Raccoon")
	local PET_OPTIONS = {}     -- opsi dropdown: "Pet - Egg" jika ada egg, atau "Pet" jika bukan dari egg
	local petEggMap = {}       -- petType -> eggName (egg asli pertama yg punya pet ini)
	do
		local eggNames = {}
		for eggName in pairs(PetEggs) do eggNames[#eggNames + 1] = eggName end
		table.sort(eggNames)

		local seen = {}
		for _, eggName in ipairs(eggNames) do
			local egg = PetEggs[eggName]
			local items = egg and egg.RarityData and egg.RarityData.Items
			if items then
				-- skip egg catch-all/admin (mis. "Fake Egg" isi 431 pet) dari peta pet->egg
				local cnt = 0; for _ in pairs(items) do cnt = cnt + 1 end
				local realEgg = eggName ~= "Fake Egg" and cnt <= 40
				for petName in pairs(items) do
					local s = tostring(petName):match("([^/]+)$") or tostring(petName)
					if not tostring(petName):match("^Egg/") and not seen[s] then
						seen[s] = true
						RAW_PET_OPTIONS[#RAW_PET_OPTIONS + 1] = s
					end
					if realEgg and not petEggMap[s] then petEggMap[s] = eggName end
				end
			end
		end

		-- Pet tambahan dari PetList jika ada
		local okPL, PetList = pcall(function()
			return require(game:GetService("ReplicatedStorage").Data.PetRegistry.PetList)
		end)
		if okPL and type(PetList) == "table" then
			for petName in pairs(PetList) do
				local s = tostring(petName):match("([^/]+)$") or tostring(petName)
				if not tostring(petName):match("^Egg/") and not seen[s] then
					seen[s] = true
					RAW_PET_OPTIONS[#RAW_PET_OPTIONS + 1] = s
				end
			end
		end

		table.sort(RAW_PET_OPTIONS)

		-- Bangun PET_OPTIONS: jika dari egg -> "Pet - Egg", jika bukan -> "Pet"
		for _, pt in ipairs(RAW_PET_OPTIONS) do
			local egg = petEggMap[pt]
			PET_OPTIONS[#PET_OPTIONS + 1] = egg and (pt .. " - " .. egg) or pt
		end
		table.sort(PET_OPTIONS)
	end

	local function petBaseName(str)
		if not str then return "" end
		local base = tostring(str):match("^(.-)%s*-%s*")
		return base or tostring(str)
	end

	local function petEggLabel(pt)
		if not pt then return "" end
		local base = petBaseName(pt)
		local egg = petEggMap[base] or petEggMap[pt]
		return egg and (base .. " - " .. egg) or tostring(pt)
	end

	-- Opsi filter sell / compatibility alias
	local PET_EGG_OPTIONS = PET_OPTIONS

	-- CUMA pet yang punya egg asli (format "Pet - Egg"). Buat filter yang wajib ada egg-nya
	-- (Special Pets, Universal, Pet to Sell) — pet tanpa egg tidak ditampilkan.
	local PET_EGG_ONLY = {}
	for _, pt in ipairs(RAW_PET_OPTIONS) do
		if petEggMap[pt] then PET_EGG_ONLY[#PET_EGG_ONLY + 1] = pt .. " - " .. petEggMap[pt] end
	end
	table.sort(PET_EGG_ONLY)

	-- Helper pencocokan universal: periksa apakah pet cocok dengan himpunan pilihan (typeSet).
	-- Mendukung tipe key "Pet - Egg" maupun key nama polos ("Pet") untuk backward compatibility.
	local function petMatchesType(typeSet, petType, petData)
		if not typeSet or not next(typeSet) or not petType then return false end
		-- 1. Direct match (mis. typeSet["Raccoon - Night Egg"] atau typeSet["Raccoon"])
		if typeSet[petType] then return true end

		-- 2. Base pet name jika petType berformat "Pet - Egg"
		local base = petBaseName(petType)
		if base ~= petType and typeSet[base] then return true end

		-- 3. Cek kombinasi "Pet - Egg" dari data pet atau peta egg
		local rawName = (base ~= "" and base ~= petType) and base or petType
		local egg = (petData and petData.HatchedFrom) or petEggMap[rawName] or petEggMap[petType]
		if egg then
			local combo = rawName .. " - " .. egg
			if typeSet[combo] then return true end
		end

		-- 4. Case-insensitive fallback
		local ptLower = rawName:lower()
		for k in pairs(typeSet) do
			local kBaseLower = petBaseName(k):lower()
			if kBaseLower == ptLower then return true end
		end

		return false
	end

	local MUT_OPTIONS, seenMut = { "None" }, { None = true }
	for _, name in pairs(EnumToMut) do
		if name ~= "Normal" and not seenMut[name] then
			seenMut[name] = true
			MUT_OPTIONS[#MUT_OPTIONS + 1] = name
		end
	end
	table.sort(MUT_OPTIONS)

	-- Mutasi yang bisa dari mesin: MachineMutationTypes (base) + Level500MutationTypes (500 only).
	local MACHINE_MUT_OPTIONS = { "None" }
	do
		local ok, MutReg = pcall(function()
			return require(game:GetService("ReplicatedStorage").Data.PetRegistry.PetMutationRegistry)
		end)
		local names, seen = {}, {}
		if ok and MutReg then
			for _, src in ipairs({ MutReg.MachineMutationTypes, MutReg.Level500MutationTypes }) do
				if type(src) == "table" then
					for name in pairs(src) do
						local n = tostring(name)
						if not seen[n] then seen[n] = true; names[#names + 1] = n end
					end
				end
			end
			-- Ice Golem-exclusive dari Mutation Machine (via passive Cold Gears): ada di
			-- PetMutationRegistry tapi bukan di MachineMutationTypes/Level500 -> tambah manual.
			for _, n in ipairs({ "ChristmasRally", "JollyDecorator", "MerryNursery", "GiantGolem" }) do
				local pmr = MutReg.PetMutationRegistry
				if type(pmr) == "table" and pmr[n] and not seen[n] then
					seen[n] = true; names[#names + 1] = n
				end
			end
		end
		if #names > 0 then
			table.sort(names)
			for _, n in ipairs(names) do MACHINE_MUT_OPTIONS[#MACHINE_MUT_OPTIONS + 1] = n end
		else
			MACHINE_MUT_OPTIONS = MUT_OPTIONS -- fallback: semua mutasi
		end
	end

	local function mutDisplay(code)
		if code == nil or code == "" or code == "m" or code == "None" or code == "Normal" then return "None" end
		return EnumToMut[code] or code
	end

	ctx.reg = {
		PET_OPTIONS = PET_OPTIONS,
		RAW_PET_OPTIONS = RAW_PET_OPTIONS,
		PET_EGG_OPTIONS = PET_EGG_OPTIONS,
		PET_EGG_ONLY = PET_EGG_ONLY,
		petEggMap = petEggMap,
		petBaseName = petBaseName,
		petEggLabel = petEggLabel,
		petMatchesType = petMatchesType,
		MUT_OPTIONS = MUT_OPTIONS,
		MACHINE_MUT_OPTIONS = MACHINE_MUT_OPTIONS,
		mutDisplay = mutDisplay,
	}
	ctx.petEggMap = petEggMap
	ctx.petBaseName = petBaseName
	ctx.petEggLabel = petEggLabel
	ctx.petMatchesType = petMatchesType
end
