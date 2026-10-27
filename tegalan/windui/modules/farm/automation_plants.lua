--[[ automation_plants.lua — Auto Plant seed (Farm).
     Tanam seed dari inventory ke farm.
     Remote: Plant_RE:FireServer(Vector3 pos, "SeedName")
     Seed & jumlah dari DataService InventoryData (ItemType="Seed", ItemData.ItemName/Quantity).
     WAJIB megang tool seed-nya pas Plant_RE -> equip ulang tiap mau tanam (kayak reclaimer).
     Posisi: Random / Player Position / God Position (barisan lurus, skip
     posisi terisi biar server nggak geser tanaman ke kolom sebelah).
     Fungsi: ctx.getPlantSeedOptions / ctx.startPlant. ]]
return function(ctx)
	local LP  = ctx.LP
	local CFG = ctx.CFG
	local RS  = game:GetService("ReplicatedStorage")
	local GE  = RS:WaitForChild("GameEvents")
	local Plant_RE = GE:WaitForChild("Plant_RE")
	local DataService = ctx.deps.DataService
	local function setStatus(s) ctx.setStatus(s) end

	local function myFarm()
		local ok, GetFarm = pcall(function() return require(RS.Modules.GetFarm) end)
		if ok and GetFarm then
			local ok2, f = pcall(function() return GetFarm(LP) end)
			if ok2 then return f end
		end
		return nil
	end
	local function important() local f = myFarm(); return f and f:FindFirstChild("Important") end
	local function canPlantParts()
		local imp = important()
		local pl = imp and imp:FindFirstChild("Plant_Locations")
		local parts = {}
		if pl then for _, p in ipairs(pl:GetChildren()) do if p:IsA("BasePart") then parts[#parts + 1] = p end end end
		return parts
	end
	local function plantsFolder()
		local f = myFarm()
		local imp = f and f:FindFirstChild("Important")
		return imp and imp:FindFirstChild("Plants_Physical")
	end

	----------------------------------------------------------------- seed inventory
	-- name -> total quantity (dari semua entry Seed di InventoryData)
	local function seedInventory()
		local out = {}
		local ok, d = pcall(function() return DataService:GetData() end)
		if ok and d and type(d.InventoryData) == "table" then
			for _, v in pairs(d.InventoryData) do
				if type(v) == "table" and v.ItemType == "Seed" and v.ItemData then
					local nm = v.ItemData.ItemName
					local q = tonumber(v.ItemData.Quantity) or 0
					if nm then out[nm] = (out[nm] or 0) + q end
				end
			end
		end
		return out
	end

	-- Opsi dropdown seed: "Nama (jumlah)". Sekalian buang seed yg udah 0 dari selection.
	local function seedOptions()
		local inv = seedInventory()
		local sel = CFG.plantSeedNames
		if type(sel) == "table" then
			local changed = false
			for nm in pairs(sel) do if (inv[nm] or 0) <= 0 then sel[nm] = nil; changed = true end end
			if changed and ctx.persistState then pcall(ctx.persistState) end
		end
		local names = {}
		for n, q in pairs(inv) do if q > 0 then names[#names + 1] = n end end
		table.sort(names)
		local out = {}
		for _, n in ipairs(names) do out[#out + 1] = { value = n, display = ("%s (%d)"):format(n, inv[n]) } end
		return out
	end
	function ctx.getPlantSeedOptions() return seedOptions() end

	----------------------------------------------------------------- posisi
	local function randomPos()
		local parts = canPlantParts()
		if #parts == 0 then return nil end
		local p = parts[math.random(1, #parts)]
		local hx, hz = p.Size.X / 2 - 1, p.Size.Z / 2 - 1
		local x = p.Position.X + (math.random() * 2 - 1) * hx
		local z = p.Position.Z + (math.random() * 2 - 1) * hz
		return Vector3.new(x, p.Position.Y, z)
	end
	local function playerPos()
		local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
		if not hrp then return nil end
		local parts = canPlantParts()
		local y = parts[1] and parts[1].Position.Y or 0
		return Vector3.new(hrp.Position.X, y, hrp.Position.Z)
	end

	-- God Position: TANAM SEBARIS LURUS (model "..........."). Baris pertama
	-- lisih tengah part Can_Plant (Z tetap), X maju GOD_STEP tiap tanam;
	-- mentok ujung -> pindah baris baru (Z += GOD_STEP) -> barisan lurus
	-- beraturan, bukan acak. Cursor dipertahankan antar siklus.
	-- PENTING: minta posisi yang udah keisi = server GESESER plant ke cell
	-- sebelah sendiri (dgn sendirinya jadi kolom kedua paralel). Makanya tiap
	-- kandidat dicek dulu ke plant yang ada; kena -> cursor maju sendiri.
	local GOD_STEP = 2.5
	local GOD_TAKE_R = GOD_STEP - 0.1 -- < step, biar tetangga sebaris g lolos
	local godCursor = { part = nil, x = 0, row = 0 }
	local function godSpots(pf) -- posisi (X,Z) semua plant, sekali per tanam
		local out = {}
		if not pf then return out end
		for _, m in ipairs(pf:GetChildren()) do
			local ok, pv = pcall(function() return m:GetPivot().Position end)
			if ok and pv then out[#out + 1] = { pv.X, pv.Z } end
		end
		return out
	end
	local function godTaken(spots, x, z)
		for _, s in ipairs(spots) do
			if math.abs(s[1] - x) < GOD_TAKE_R and math.abs(s[2] - z) < GOD_TAKE_R then
				return true
			end
		end
		return false
	end
	local function godPos()
		local parts = canPlantParts()
		if #parts == 0 then godCursor = { part = nil, x = 0, row = 0 }; return nil end
		local p = parts[1]
		local halfX = p.Size.X / 2 - 0.75
		local halfZ = p.Size.Z / 2 - 1
		local spots = godSpots(plantsFolder())
		local startX = p.Position.X - halfX + GOD_STEP
		for _ = 1, 800 do -- sweep capped; habis semua = lahan beneran keblokir
			if godCursor.part ~= p then godCursor = { part = p, x = 0, row = 0 } end
			local x = startX + godCursor.x * GOD_STEP
			if x > p.Position.X + halfX then -- baris penuh -> turun ke baris baru
				godCursor.x = 0
				godCursor.row = godCursor.row + 1
				x = startX
			end
			local z = p.Position.Z - halfZ + godCursor.row * GOD_STEP
			if z > p.Position.Z + halfZ then -- lahan penuh -> mulai lagi dari baris 1
				godCursor.row = 0
				godCursor.x = 0
				z = p.Position.Z - halfZ
			end
			godCursor.x = godCursor.x + 1
			godCursor.part = p
			if not godTaken(spots, x, z) then
				return Vector3.new(x, p.Position.Y, z)
			end
			-- spot keisi -> cursor udah maju, coba kandidat berikutnya
		end
		return nil -- semua spot keblokir (tanaman raksasa/dll); coba tik depan
	end

	----------------------------------------------------------------- ack tanam
	-- Server nyatet plant baru di Plants_Physical secara ASYNC. Kalau kita
	-- ngebut (plantDelay 0), fire berikutnya nyamain server sebelum plant
	-- sebelumnya terdaftar di occupancy -> server nabrak dan naruh plant di
	-- POSISI ACAK. Makanya tiap fire DITUNGGU sampe plant barunya beneran
	-- muncul (ack, max 2.5s) baru lanjut. Ini bikin God Position lurus di
	-- SEMUA nilai delay (0 pun bisa, kecepatan = secepat server nyatet);
	-- delay user tetap jadi gap tambahan di atas ack.
	-- ponytail: God Position udah skip spot terisi (radius GOD_TAKE_R, cek
	-- pivot semua plant). Celah yang tersisa: tanaman RAKSASA badannya nutup
	-- cell sebelah tapi pivotnya jauh -> lolos cek. Upgrade kalau kejadian:
	-- verifikasi per-tanam (cocokkan pivot plant baru dgn request, shovel +
	-- tanam ulang kalau meleset).
	local function plantSet(pf)
		local set = {}
		for _, m in ipairs(pf:GetChildren()) do
			local ok, pv = pcall(function() return m:GetPivot().Position end)
			if ok and pv then set[string.format("%d,%d,%d", pv.X, pv.Y, pv.Z)] = true end
		end
		return set
	end
	local function plantAck(before, timeout)
		local pf = plantsFolder()
		local t0 = os.clock()
		while before and pf and os.clock() - t0 < (timeout or 2.5) do
			if not CFG.plantSeedEnabled then return end
			for k in pairs(plantSet(pf)) do
				if not before[k] then return end -- plant baru kedetect -> server siap
			end
			task.wait(0.05)
		end
	end

	----------------------------------------------------------------- equip seed
	-- Tool seed namanya "<Nama> Seed [Xjumlah]". Server WAJIB kamu megang tool-nya
	-- pas Plant_RE, jadi equip ulang tiap mau tanam (walau user pindah manual).
	local function seedBase(t)
		return t:IsA("Tool") and t.Name:match("^(.-) Seed %[X%d+%]") or nil
	end
	local function holdingSeed(name)
		local ch = LP.Character
		if ch then for _, t in ipairs(ch:GetChildren()) do if seedBase(t) == name then return true end end end
		return false
	end
	local function equipSeed(name)
		if holdingSeed(name) then return true end
		local bp = LP:FindFirstChild("Backpack")
		local tool
		if bp then for _, t in ipairs(bp:GetChildren()) do if seedBase(t) == name then tool = t; break end end end
		if tool then
			local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
			if hum then pcall(function() hum:EquipTool(tool) end) end
		end
		return holdingSeed(name)
	end

	----------------------------------------------------------------- loop tanam
	local function plantLoop(myId)
		ctx.elevate()
		while CFG.plantSeedEnabled and ctx.alive() and ctx.state.plantId == myId do
			local sel = CFG.plantSeedNames or {}
			if next(sel) then
				local inv = seedInventory()
				local mode = (CFG.plantPosition == "Player Position" and "Player Position")
					or (CFG.plantPosition == "God Position" and "God Position")
					or "Random"
				-- Kecepatan sepenuhnya ikut Delay input (0 = secepat mungkin).
				local planted, anySeed = 0, false
				for name in pairs(sel) do
					local qty = inv[name] or 0
					if qty > 0 then
						anySeed = true
						for _ = 1, qty do
							if not CFG.plantSeedEnabled or ctx.state.plantId ~= myId then break end
							if equipSeed(name) then -- equip seed tiap mau tanam
								local pos = (mode == "Player Position" and playerPos())
									or (mode == "God Position" and godPos())
									or randomPos()
								if pos then
									-- snapshot SEBELUM fire, biar ack ga ketuker dgn plant lama
									local pf = plantsFolder()
									local before = pf and plantSet(pf) or nil
									pcall(function() Plant_RE:FireServer(pos, name) end)
									planted = planted + 1
									plantAck(before, 2.5) -- tunggu server nyatet plantnya
								end
							end
							task.wait(tonumber(CFG.plantDelay) or 0)
						end
					end
				end
				if not anySeed then setStatus("Plants: seed terpilih habis")
				else setStatus(("Plants: tanam %d (%s)"):format(planted, mode)) end
			else
				setStatus("Plants: pilih seed dulu")
			end
			task.wait(1)
		end
	end

	function ctx.startPlant()
		ctx.state.plantId = (ctx.state.plantId or 0) + 1
		local myId = ctx.state.plantId
		task.spawn(function() plantLoop(myId) end)
	end
end
