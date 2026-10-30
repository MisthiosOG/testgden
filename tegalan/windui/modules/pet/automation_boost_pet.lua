--[[ boostpet.lua — Automation Boost Pet.
     Pilih pet + item boost (Pet Toy). Otomatis apply boost ke pet;
     re-apply pas boost habis (berdasar durasi item, atribut "p" = boostTime detik).
     Mekanik: pegang Tool bertag "PetBoost" lalu PetBoostService:FireServer("ApplyBoost", petUuid). ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local CFG = ctx.CFG
	local LP = ctx.LP
	local RS = game:GetService("ReplicatedStorage")
	local PetBoostService = RS:WaitForChild("GameEvents"):WaitForChild("PetBoostService")
	local function setStatus(s) ctx.setStatus(s) end

	-- "Medium Pet Toy x42[Passive Boost]" -> "Medium Pet Toy"
	local function baseName(n) return (tostring(n):gsub("%s*x%d+.*$", "")) end

	-- Daftar item boost (tag PetBoost) di backpack, dedupe per base name -> dropdown.
	function ctx.getBoostItemOptions(selectedSet)
		local out, seen = {}, {}
		local bp = LP:FindFirstChildOfClass("Backpack")
		if not bp then return out end
		for _, t in ipairs(bp:GetChildren()) do
			if t:IsA("Tool") and t:HasTag("PetBoost") then
				local bn = baseName(t.Name)
				if not seen[bn] then
					seen[bn] = true
					local dur = t:GetAttribute("p")
					out[#out + 1] = { value = bn, display = dur and (bn .. " (" .. tostring(dur) .. "s)") or bn }
				end
			end
		end
		table.sort(out, function(a, b)
			local sa = selectedSet and selectedSet[a.value] and 1 or 0
			local sb = selectedSet and selectedSet[b.value] and 1 or 0
			if sa ~= sb then return sa > sb end
			return a.display < b.display
		end)
		return out
	end

	local THRESHOLD = 5 -- detik; boost dianggap habis kalau sisa <= ini

	-- Key unik per varian boost: type + amount. Small & Medium Pet Toy sama-sama
	-- PASSIVE_BOOST tapi amount beda (0.1 vs 0.2) dan BISA di-stack, jadi harus dibedakan.
	local function boostKey(btype, amount)
		local n = tonumber(amount)
		return tostring(btype) .. "|" .. (n and tostring(n) or tostring(amount))
	end

	-- Baca boost yang MASIH aktif di pet (dari PetData.Boosts, sisa Time > THRESHOLD).
	-- Keyed by type+amount supaya varian beda amount tidak saling menutupi.
	local function petActiveTypes(uuid)
		local out = {}
		local ok, d = pcall(function() return DataService:GetData() end)
		local data = ok and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data
		local pd = data and data[uuid]
		local boosts = pd and pd.PetData and pd.PetData.Boosts
		if type(boosts) == "table" then
			for _, b in ipairs(boosts) do
				if b.BoostType and (tonumber(b.Time) or 0) > THRESHOLD then
					out[boostKey(b.BoostType, b.BoostAmount)] = true
				end
			end
		end
		return out
	end

	-- Pet dianggap AKTIF di garden kalau uuid-nya ada di PetsData.EquippedPets (array uuid).
	-- Boost cuma berlaku ke pet yang lagi placed; kalau nggak placed, skip (percuma).
	local function isPetActive(uuid)
		local ok, d = pcall(function() return DataService:GetData() end)
		local eq = ok and d and d.PetsData and d.PetsData.EquippedPets
		return type(eq) == "table" and table.find(eq, uuid) ~= nil
	end

	-- Cari tool boost dipilih (Character dulu) yang varian (type+amount)-nya BELUM aktif di pet.
	-- accept(tool) opsional: filter item (default = item yang dipilih di dropdown Boost).
	local function findToolForMissing(activeTypes, accept)
		local sel = CFG.boostItemNames or {}
		accept = accept or function(t) return sel[baseName(t.Name)] end
		for _, src in ipairs({ LP.Character, LP:FindFirstChildOfClass("Backpack") }) do
			if src then
				for _, t in ipairs(src:GetChildren()) do
					if t:IsA("Tool") and t:HasTag("PetBoost") and accept(t) then
						local bt = t:GetAttribute("q")
						if bt and not activeTypes[boostKey(bt, t:GetAttribute("o"))] then return t end
					end
				end
			end
		end
		return nil
	end

	local function boostLoop()
		ctx.state.boostId = (ctx.state.boostId or 0) + 1
		local myId = ctx.state.boostId
		ctx.elevate()

		while CFG.boostEnabled and ctx.alive() and ctx.state.boostId == myId do
			local pets = CFG.boostPetUuids or {}
			if not next(pets) then
				setStatus("Boost: pilih pet dulu")
				task.wait(3)
			else
				for uuid in pairs(pets) do
					if not CFG.boostEnabled or ctx.state.boostId ~= myId then break end
					-- Skip pet yang nggak aktif/placed di garden (boost ga guna)
					if not isPetActive(uuid) then continue end
					-- Cek state asli: boost apa yang masih aktif di pet ini
					local active = petActiveTypes(uuid)
					local tool = findToolForMissing(active)
					if tool then
						local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
						if hum then
							-- pastikan item bener-bener dipegang sebelum ApplyBoost
							local held
							for _ = 1, 3 do
								pcall(function() hum:EquipTool(tool) end)
								task.wait(0.35)
								held = LP.Character and LP.Character:FindFirstChildWhichIsA("Tool")
								if held and held:HasTag("PetBoost") then break end
								tool = findToolForMissing(active)
								if not tool then break end
							end
							if held and held:HasTag("PetBoost") then
								pcall(function() PetBoostService:FireServer("ApplyBoost", uuid) end)
								setStatus(("Boost: %s -> #%s"):format(baseName(held.Name), uuid:sub(2, 5)))
								task.wait(0.6)
							end
						end
					end
				end
				task.wait(2)
			end
		end
	end

	function ctx.startBoostPet() task.spawn(boostLoop) end

	----------------------------------------------------------------- Auto Boost Team (hatch)
	-- Dipanggil HATCH tepat setelah satu team selesai dipasang (dan tiap kali team itu
	-- udah kepasang pas putaran hatch). Cek tiap pet team: varian Pet Toy yang dipunya tapi
	-- belum aktif / udah mau habis -> pasang. Abis tiap boost, toy dilepas lagi dari tangan.
	-- Toy yang nggak dipunya = skip. Nggak ada loop terpisah -> nggak rebutan tool sama hatch.
	local function isPetToy(t) return tostring(t.Name):find("Pet Toy", 1, true) ~= nil end

	function ctx.boostTeamNow(teamSet, label)
		if not CFG.hatchBoostEnabled or not CFG.hatchEnabled or not next(teamSet or {}) then return 0 end
		local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
		if not hum then return 0 end
		local n = 0
		for uuid in pairs(teamSet) do
			if not (CFG.hatchBoostEnabled and CFG.hatchEnabled) then break end
			if isPetActive(uuid) then
				-- satu pet bisa butuh beberapa toy (Small+Medium+Large numpuk)
				for _ = 1, 3 do
					local tool = findToolForMissing(petActiveTypes(uuid), isPetToy)
					if not tool then break end -- semua varian yang dipunya udah aktif
					pcall(function() hum:EquipTool(tool) end)
					task.wait(0.35)
					local held = LP.Character and LP.Character:FindFirstChildWhichIsA("Tool")
					if held and held:HasTag("PetBoost") then
						pcall(function() PetBoostService:FireServer("ApplyBoost", uuid) end)
						n = n + 1
						ctx.state.hatchStatus = ("%s: boost %s -> #%s"):format(label or "Team", baseName(held.Name), uuid:sub(2, 5))
						task.wait(0.5)
					end
					pcall(function() hum:UnequipTools() end) -- lepas lagi abis dipake
					task.wait(0.15)
					if not (held and held:HasTag("PetBoost")) then break end
				end
			end
		end
		return n
	end

	-- toggle cuma nyalain/matiin flag (nggak ada loop lagi)
	function ctx.startHatchBoost() end
	function ctx.stopHatchBoost() end
end
