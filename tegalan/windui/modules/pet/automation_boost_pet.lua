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

	----------------------------------------------------------------- Auto Boost Hatch Teams
	-- Boost SEMUA pet team hatch (Core/Hatch/Bronto/Sell) yang lagi di kebun pakai Pet Toy
	-- (Small/Medium/Large — apa aja yang ada di backpack). Re-apply pas boost-nya habis.
	-- Toy yang nggak dipunya = di-skip. Cuma jalan selama Enable Auto Hatch ON, dan nunggu
	-- kalau hatch lagi ganti team / naro egg (biar nggak rebutan pegang tool).
	local function isPetToy(t) return tostring(t.Name):find("Pet Toy", 1, true) ~= nil end

	local function hatchTeamSet()
		local set = {}
		for _, k in ipairs({ "hatchCoreTeam", "hatchHatchTeam", "hatchBrontoTeam", "hatchSellTeam" }) do
			for u in pairs(CFG[k] or {}) do set[u] = true end
		end
		return set
	end

	local function hatchBusy()
		return ctx.state.teamSwapActive or ctx.state.hatchPlacing
	end

	local function hatchBoostLoop(myId)
		ctx.elevate()
		while CFG.hatchBoostEnabled and ctx.alive() and ctx.state.hatchBoostId == myId do
			local okTick, err = pcall(function()
				if not CFG.hatchEnabled then setStatus("Team Boost: waiting for Auto Hatch"); return end
				local team = hatchTeamSet()
				if not next(team) then return end
				local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
				if not hum then return end
				local usedTool = false
				for uuid in pairs(team) do
					if not CFG.hatchBoostEnabled or not CFG.hatchEnabled or hatchBusy() then break end
					if isPetActive(uuid) then
						-- satu pet bisa butuh beberapa toy (Small+Medium+Large stack)
						for _ = 1, 3 do
							if hatchBusy() then break end
							local active = petActiveTypes(uuid)
							local tool = findToolForMissing(active, isPetToy)
							if not tool then break end -- semua varian yang dipunya udah aktif / habis
							pcall(function() hum:EquipTool(tool) end)
							task.wait(0.35)
							local held = LP.Character and LP.Character:FindFirstChildWhichIsA("Tool")
							if not (held and held:HasTag("PetBoost")) then break end
							usedTool = true
							pcall(function() PetBoostService:FireServer("ApplyBoost", uuid) end)
							setStatus(("Team Boost: %s -> #%s"):format(baseName(held.Name), uuid:sub(2, 5)))
							task.wait(0.6)
						end
					end
				end
				-- jangan ninggalin toy kepegang (hatch butuh tangan kosong buat egg)
				if usedTool then pcall(function() hum:UnequipTools() end) end
			end)
			if not okTick and ctx.log then ctx.log("[Team Boost] error: " .. tostring(err)) end
			task.wait(3)
		end
	end

	function ctx.startHatchBoost()
		ctx.state.hatchBoostId = (ctx.state.hatchBoostId or 0) + 1
		local myId = ctx.state.hatchBoostId
		task.spawn(hatchBoostLoop, myId)
	end
	function ctx.stopHatchBoost()
		ctx.state.hatchBoostId = (ctx.state.hatchBoostId or 0) + 1
	end
end
