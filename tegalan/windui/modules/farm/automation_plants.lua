--[[ automation_plants.lua — Auto Plant seed (Farm).
     Tanam seed dari inventory ke farm.
     Remote: Plant_RE:FireServer(Vector3 pos, "SeedName")
     Seed & jumlah dari DataService InventoryData (ItemType="Seed", ItemData.ItemName/Quantity).
     WAJIB megang tool seed-nya pas Plant_RE -> equip ulang tiap mau tanam (kayak reclaimer).
     Posisi: Random / Player Position / Good Position (barisan lurus urut
     kiri->kanan; cell yang dipegang plant lama di-shovel biar server
     nggak geser tanaman baru — toggle "Shovel Penghalang").
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

	-- Good Position: BARISAN DETERMINISTIK, URUT KIRI -> KANAN per baris
	-- (row-major; cursor TIDAK PERNAH lompat biar urutannya nyambung).
	-- Cell berikutnya = kolom skrg + GOOD_STEP (X); mentok kanan -> baris baru
	-- (Z += GOOD_STEP). Cell yang masih dipegang plant lama DIBERSIHKAN dulu
	-- (Remove_Item dgn Shovel kepegang, sama kayak tab Shovel; toggle
	-- "Shovel Penghalang") -> jalur dijamin kosong, server PASTI naruh plant
	-- di posisi yang diminta, nggak ada geser acak. Kalau toggle off / shovel
	-- gagal, baru maju 1 cell (skip).
	local GOOD_STEP   = 2.5
	local GOOD_TAKE_R = GOOD_STEP - 0.1
	local RemoveItem = RS:WaitForChild("GameEvents"):WaitForChild("Remove_Item")
	local goodCursor = { part = nil, col = 0, row = 0 }
	local function heldShovel()
		local ch = LP.Character
		if ch then for _, t in ipairs(ch:GetChildren()) do
			if t:IsA("Tool") and tostring(t.Name):find("Shovel") then return t end
		end end
		return nil
	end
	local function equipShovel() -- server nolak Remove_Item kalau ga pegang Shovel
		if heldShovel() then return true end
		local sh
		for _, w in ipairs({ LP.Character, LP:FindFirstChild("Backpack") }) do
			if w then for _, t in ipairs(w:GetChildren()) do
				if t:IsA("Tool") and tostring(t.Name):find("Shovel") then sh = t; break end
			end end
			if sh then break end
		end
		local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
		if sh and hum then pcall(function() hum:EquipTool(sh) end); task.wait(0.15) end
		return heldShovel() ~= nil
	end
	local function blockersAt(pf, x, z) -- plant yang pivot-nya makan cell (x,z)
		local out = {}
		if pf then
			for _, m in ipairs(pf:GetChildren()) do
				local ok, pv = pcall(function() return m:GetPivot().Position end)
				if ok and pv and math.abs(pv.X - x) < GOOD_TAKE_R and math.abs(pv.Z - z) < GOOD_TAKE_R then
					out[#out + 1] = m
				end
			end
		end
		return out
	end
	local function clearBlocker(m) -- Remove_Item(PrimaryPart) & tunggu ilang beneran
		local part = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
		if not (part and equipShovel()) then return false end
		pcall(function() RemoveItem:FireServer(part) end)
		local t0 = os.clock()
		while m.Parent and os.clock() - t0 < 2 do task.wait(0.05) end
		return not m.Parent
	end
	local function goodPos()
		local parts = canPlantParts()
		if #parts == 0 then goodCursor = { part = nil, col = 0, row = 0 }; return nil end
		local p = parts[1]
		local halfX = p.Size.X / 2 - 0.75
		local halfZ = p.Size.Z / 2 - 1
		if goodCursor.part ~= p then goodCursor = { part = p, col = 0, row = 0 } end
		for _ = 1, 800 do -- cap sweep; lahan beneran keblokir -> coba lagi tik depan
			local x = p.Position.X - halfX + GOOD_STEP + goodCursor.col * GOOD_STEP
			local z = p.Position.Z - halfZ + goodCursor.row * GOOD_STEP
			if x > p.Position.X + halfX then -- baris penuh -> turun ke baris baru
				goodCursor.col, goodCursor.row = 0, goodCursor.row + 1
				x = p.Position.X - halfX + GOOD_STEP
				z = p.Position.Z - halfZ + goodCursor.row * GOOD_STEP
			end
			if z > p.Position.Z + halfZ then -- lahan penuh -> mulai baris awal lagi
				goodCursor.col, goodCursor.row = 0, 0
				x = p.Position.X - halfX + GOOD_STEP
				z = p.Position.Z - halfZ
			end
			local bl = blockersAt(plantsFolder(), x, z)
			local free = (#bl == 0)
			if not free and CFG.goodClear ~= false then
				local cleared = 0
				for _, m in ipairs(bl) do if clearBlocker(m) then cleared = cleared + 1 end end
				free = (cleared == #bl)
			end
			goodCursor.col = goodCursor.col + 1 -- cell selesai diproses (tanam/shovel/skip)
			if free then return Vector3.new(x, p.Position.Y, z) end
		end
		return nil
	end

		-- Speed 0 vs speed 1 beda tata letak? Ini penyebabnya: ack yang lama
	-- cuma nunggu "ADA plant baru" — pivot baru bisa datang dari plant LAMA
	-- yang di-repivot server, jadi ack sering keluar duluan padahal plant
	-- baru sendiri belum dicatet server -> fire berikutnya nabrak -> server
	-- geser posisi -> hasil "ngacak" di delay 0. Good Position makanya
	-- nggak pake ack generik, tapi nunggu plant beneran MUNCUL DI CELL yang
	-- diminta (pivot deket pos_request). Layar nggak bisa bohong: kalau
	-- cell-nya belum keisi, kita nggak jalan. Ini bikin barisan lurus di
	-- SEMUA nilai delay (0 pun, kecepatan = secepat server nyatet).
	local function waitCellOccupied(pos, timeout)
		if not pos then return end
		local t0 = os.clock()
		while os.clock() - t0 < (timeout or 2.5) do
			if not CFG.plantSeedEnabled then return end
			local pf = plantsFolder()
			if pf then
				for _, m in ipairs(pf:GetChildren()) do
					local ok, pv = pcall(function() return m:GetPivot().Position end)
					if ok and pv and math.abs(pv.X - pos.X) < GOOD_TAKE_R and math.abs(pv.Z - pos.Z) < GOOD_TAKE_R then
						return -- plant baru udah beneran duduk di cell-nya
					end
				end
			end
			task.wait(0.05)
		end
	end

----------------------------------------------------------------- ack tanam
	-- Server nyatet plant baru di Plants_Physical secara ASYNC. Kalau kita
	-- ngebut (plantDelay 0), fire berikutnya nyamain server sebelum plant
	-- sebelumnya terdaftar di occupancy -> server nabrak dan naruh plant di
	-- POSISI ACAK. Makanya tiap fire DITUNGGU sampe plant barunya beneran
	-- muncul (ack, max 2.5s) baru lanjut. Ini bikin Good Position lurus di
	-- SEMUA nilai delay (0 pun bisa, kecepatan = secepat server nyatet).
	-- ponytail: Good Position udah bersihin penghalang jalurnya (pivot,
	-- radius GOOD_TAKE_R + Remove_Item). Celah: tanaman yang server anggap
	-- nutup cell tapi pivot-nya jauh (jarang). Upgrade: verifikasi per-tanam.
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
					or (CFG.plantPosition == "Good Position" and "Good Position")
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
									or (mode == "Good Position" and goodPos())
									or randomPos()
								if pos then
									-- snapshot SEBELUM fire, biar ack ga ketuker dgn plant lama
									local pf = plantsFolder()
									local before = pf and plantSet(pf) or nil
								pcall(function() Plant_RE:FireServer(pos, name) end)
								planted = planted + 1
								-- Good Position: nunggu plant duduk DI CELL-nya
								-- (bukan cuma "ada plant baru") -> speed 0 tetap urut.
								if mode == "Good Position" then
									waitCellOccupied(pos, 2.5)
								else
									plantAck(before, 2.5)
								end
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
