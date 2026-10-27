--[[ registry.lua — bangun opsi dropdown dari data game.
     Mengisi: ctx.reg = { comboKey, mutDisplay, PET_OPTIONS, MUT_OPTIONS, SKIN_OPTIONS } ]]
return function(ctx)
	local PetEggs   = ctx.deps.PetEggs
	local PetList   = ctx.deps.PetList or {}
	local EnumToMut = ctx.deps.EnumToMut
	local SkinsReg  = ctx.deps.SkinsReg

	-- Map nama pet -> asset id icon (dari PetList[pet].Icon = "rbxassetid://123").
	local PET_ICONS = {}
	for petName, d in pairs(PetList) do
		if type(d) == "table" and d.Icon then
			local id = tostring(d.Icon):match("(%d+)")
			if id then PET_ICONS[tostring(petName)] = id end
		end
	end

	-- opsi dropdown = kombinasi "Pet - Egg"
	local function comboKey(petType, egg)
		return tostring(petType) .. " - " .. tostring(egg)
	end

	local function petBaseName(str)
		if not str then return "" end
		local base = tostring(str):match("^(.-)%s*-%s*")
		return base or tostring(str)
	end

	----------------------------------------------------------------- PET_OPTIONS & petEggMap
	local RAW_PET_OPTIONS = {}
	local PET_OPTIONS = {}
	local petEggMap = {}
	do
		local eggNames = {}
		for eggName in pairs(PetEggs) do eggNames[#eggNames + 1] = eggName end
		table.sort(eggNames)

		local seen = {}
		for _, eggName in ipairs(eggNames) do
			local egg = PetEggs[eggName]
			local items = egg and egg.RarityData and egg.RarityData.Items
			if items then
				local cnt = 0; for _ in pairs(items) do cnt = cnt + 1 end
				local realEgg = eggName ~= "Fake Egg" and cnt <= 40
				for petName in pairs(items) do
					if not tostring(petName):match("^Egg/") then
						local nameStr = tostring(petName):match("([^/]+)$") or tostring(petName)
						if not seen[nameStr] then
							seen[nameStr] = true
							RAW_PET_OPTIONS[#RAW_PET_OPTIONS + 1] = nameStr
						end
						if realEgg and not petEggMap[nameStr] then
							petEggMap[nameStr] = eggName
						end
					end
				end
			end
		end

		for petName in pairs(PetList) do
			if not tostring(petName):match("^Egg/") then
				local nameStr = tostring(petName):match("([^/]+)$") or tostring(petName)
				if not seen[nameStr] then
					seen[nameStr] = true
					RAW_PET_OPTIONS[#RAW_PET_OPTIONS + 1] = nameStr
				end
			end
		end

		table.sort(RAW_PET_OPTIONS)

		for _, pt in ipairs(RAW_PET_OPTIONS) do
			local egg = petEggMap[pt]
			PET_OPTIONS[#PET_OPTIONS + 1] = egg and (pt .. " - " .. egg) or pt
		end
		table.sort(PET_OPTIONS)
	end

	local function petEggLabel(pt)
		if not pt then return "" end
		local base = petBaseName(pt)
		local egg = petEggMap[base] or petEggMap[pt]
		return egg and (base .. " - " .. egg) or tostring(pt)
	end

	----------------------------------------------------------------- PET_COMBO_OPTIONS (Pet - Egg)
	-- Bedakan pet per egg (premium vs biasa). Dipakai snipe biar bisa target spesifik.
	local PET_COMBO_OPTIONS = {}
	do
		local seen = {}
		local eggNames = {}
		for eggName in pairs(PetEggs) do eggNames[#eggNames + 1] = eggName end
		table.sort(eggNames)

		for _, eggName in ipairs(eggNames) do
			local egg = PetEggs[eggName]
			local items = egg and egg.RarityData and egg.RarityData.Items
			if items then
				local cnt = 0; for _ in pairs(items) do cnt = cnt + 1 end
				local realEgg = eggName ~= "Fake Egg" and cnt <= 40
				if realEgg then
					for petName in pairs(items) do
						if not tostring(petName):match("^Egg/") then
							local nameStr = tostring(petName):match("([^/]+)$") or tostring(petName)
							local k = comboKey(nameStr, eggName)
							if not seen[k] then seen[k] = true; PET_COMBO_OPTIONS[#PET_COMBO_OPTIONS + 1] = k end
						end
					end
				end
			end
		end
		table.sort(PET_COMBO_OPTIONS)
	end

	-- Helper pencocokan universal
	local function petMatchesType(typeSet, petType, petData)
		if not typeSet or not next(typeSet) or not petType then return false end
		if typeSet[petType] then return true end

		local base = petBaseName(petType)
		if base ~= petType and typeSet[base] then return true end

		local rawName = (base ~= "" and base ~= petType) and base or petType
		local egg = (petData and petData.HatchedFrom) or petEggMap[rawName] or petEggMap[petType]
		if egg then
			local combo = rawName .. " - " .. egg
			if typeSet[combo] then return true end
		end

		local ptLower = rawName:lower()
		for k in pairs(typeSet) do
			local kBaseLower = petBaseName(k):lower()
			if kBaseLower == ptLower then return true end
		end

		return false
	end

	----------------------------------------------------------------- MUT_OPTIONS
	local MUT_OPTIONS, seenMut = { "None" }, { None = true }
	for _, name in pairs(EnumToMut) do
		if name ~= "Normal" and not seenMut[name] then
			seenMut[name] = true
			MUT_OPTIONS[#MUT_OPTIONS + 1] = name
		end
	end
	table.sort(MUT_OPTIONS)

	----------------------------------------------------------------- SKIN_OPTIONS
	local SKIN_OPTIONS = {}
	for name, data in pairs(SkinsReg) do
		SKIN_OPTIONS[#SKIN_OPTIONS + 1] = { name = name, display = data.DisplayName or name }
	end
	table.sort(SKIN_OPTIONS, function(a, b) return a.display < b.display end)

	----------------------------------------------------------------- mutDisplay
	local function mutDisplay(code)
		if code == nil or code == "" or code == "m" or code == "None" or code == "Normal" then
			return "None"
		end
		return EnumToMut[code] or code
	end

	ctx.reg = {
		comboKey          = comboKey,
		petBaseName       = petBaseName,
		petEggLabel       = petEggLabel,
		petEggMap         = petEggMap,
		petMatchesType    = petMatchesType,
		mutDisplay        = mutDisplay,
		PET_OPTIONS       = PET_OPTIONS,
		RAW_PET_OPTIONS   = RAW_PET_OPTIONS,
		PET_COMBO_OPTIONS = PET_COMBO_OPTIONS,
		PET_ICONS         = PET_ICONS,
		MUT_OPTIONS       = MUT_OPTIONS,
		SKIN_OPTIONS      = SKIN_OPTIONS,
	}
	ctx.petEggMap = petEggMap
	ctx.petBaseName = petBaseName
	ctx.petEggLabel = petEggLabel
	ctx.petMatchesType = petMatchesType
end
