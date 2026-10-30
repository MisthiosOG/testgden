--[[ automation_gm_sprinkler.lua — Auto GM Sprinkler (toggle di tab Hatch,
     di bawah Enable Auto Hatch). Jaga 1 Grandmaster Sprinkler terpasang
     terus: cek objek sprinkler milik sendiri di Objects_Physical (attribute
     Lifetime = sisa detik, 1 GM kuat 10 menit), kalau tidak ada / mau mati
     (sisa <= GM_REFILL) -> equip tool "Grandmaster Sprinkler x<n>" ->
     SprinklerService:FireServer("Create", CFrame.new(pos)).
     Fungsi: ctx.startGmSprinkler / ctx.stopGmSprinkler. ]]
return function(ctx)
	local LP, CFG = ctx.LP, ctx.CFG
	local RS = game:GetService("ReplicatedStorage")
	local GE = RS:WaitForChild("GameEvents")
	local SprinklerService = GE:WaitForChild("SprinklerService")
	local GM_TYPE   = "Grandmaster Sprinkler"
	local GM_REFILL = 45 -- pasang baru ketika sisa 45 detik, jangan sampai terputus
	-- JANGAN `local setStatus = ctx.setStatus`: ctx.setStatus baru dibuat di ui/window.lua
	-- (dimuat SETELAH modul ini) -> nil -> loop error & mati abis place GM pertama.
	local function setStatus(s) if ctx.setStatus then pcall(ctx.setStatus, s) end end

	local function important()
		local ok, GetFarm = pcall(function() return require(RS.Modules.GetFarm) end)
		if not ok or not GetFarm then return nil end
		local ok2, f = pcall(function() return GetFarm(LP) end)
		return (ok2 and f and f:FindFirstChild("Important")) or nil
	end

	-- state, lifeMin = "none"/"alive"/"expiring", sisa detik terkecil dari
	-- sprinkler yang terpasang. Attribute Lifetime yang tidak ada = dianggap
	-- tetap berjalan (anti-spam) — objek yang hilang saat expired tetap tertangkap.
	local function gmState()
		local imp = important()
		local of = imp and imp:FindFirstChild("Objects_Physical")
		if not of then return "none", 0 end
		-- Pakai sisa waktu TERBESAR: kalau GM lama mau habis tapi GM baru udah kepasang,
		-- itu "alive" (dulu pakai terkecil -> nge-place ulang tiap 4 detik sampai GM lama habis).
		local found, noLife, maxLife = false, false, -1
		for _, o in ipairs(of:GetChildren()) do
			if (o:GetAttribute("OBJECT_TYPE") or o.Name) == GM_TYPE
				and o:GetAttribute("OWNER") == LP.Name then
				found = true
				local life = tonumber(o:GetAttribute("Lifetime"))
				if life then
					if life > maxLife then maxLife = life end
				else
					noLife = true
				end
			end
		end
		if not found then return "none", 0 end
		if noLife then return "alive", math.max(0, maxLife) end
		if maxLife <= GM_REFILL then return "expiring", maxLife end
		return "alive", maxLife
	end

	local function gmInventory()
		for _, where in ipairs({ LP:FindFirstChild("Backpack"), LP.Character }) do
			if where then for _, t in ipairs(where:GetChildren()) do
				if t:IsA("Tool") and t.Name:match("^" .. GM_TYPE .. " x%d+") then
					if (tonumber(t.Name:match("x(%d+)$")) or 0) > 0 then return t end
				end
			end end
		end
		return nil
	end

	local function equipGm(tool)
		local c = LP.Character
		if c and tool.Parent == c then return true end
		local hum = c and c:FindFirstChildOfClass("Humanoid")
		if hum then pcall(function() hum:EquipTool(tool) end) end
		return (c and tool.Parent == c) or false
	end

	-- titik acak di dalam area farm (Plant_Locations), format yang sama dengan Auto Sprinkler.
	local function gmPos()
		local imp = important()
		local pl = imp and imp:FindFirstChild("Plant_Locations")
		if not pl then return nil end
		local parts = {}
		for _, p in ipairs(pl:GetChildren()) do if p:IsA("BasePart") then parts[#parts + 1] = p end end
		if #parts == 0 then return nil end
		local p = parts[math.random(1, #parts)]
		local hx, hz = p.Size.X / 2 - 1, p.Size.Z / 2 - 1
		return Vector3.new(
			p.Position.X + (math.random() * 2 - 1) * hx,
			p.Position.Y,
			p.Position.Z + (math.random() * 2 - 1) * hz)
	end

	local function gmLoop(myId)
		ctx.elevate()
		while CFG.gmSprinklerEnabled and ctx.alive() and ctx.state.gmSprId == myId do
			-- satu error di satu putaran nggak boleh matiin loop
			local okTick, errTick = pcall(function()
			-- GM cuma jalan kalau Auto Hatch nyala. Loop tetap hidup, jadi begitu Auto Hatch
			-- di-ON-in, GM langsung jalan tanpa perlu toggle ulang.
			if not CFG.hatchEnabled then
				setStatus("GM Sprinkler: waiting for Auto Hatch")
				return
			end
			-- jangan rebutan tool sama hatch yang lagi naro egg / ganti team
			if ctx.state.hatchPlacing or ctx.state.teamSwapActive then return end
			local st, life = gmState()
			if st == "alive" then
				setStatus(("GM Sprinkler: %ss left"):format(math.floor(life)))
			else
				local tool = gmInventory()
				if not tool then
					setStatus("GM Sprinkler: no stock")
				else
					local pos = gmPos()
					if pos and equipGm(tool) then
						pcall(function() SprinklerService:FireServer("Create", CFrame.new(pos)) end)
						setStatus("GM Sprinkler: placed")
						-- lepas lagi dari tangan (hatch butuh tangan kosong buat egg)
						task.wait(0.3)
						pcall(function()
							local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
							if hum then hum:UnequipTools() end
						end)
						-- berselang 3 detik: beri waktu server untuk melakukan spawn, jangan terjadi double-place
						task.wait(3)
					end
				end
			end
			end)
			if not okTick and ctx.log then ctx.log("[GM Sprinkler] error: " .. tostring(errTick)) end
			task.wait(1)
		end
	end

	function ctx.startGmSprinkler()
		ctx.state.gmSprId = (ctx.state.gmSprId or 0) + 1
		local myId = ctx.state.gmSprId
		task.spawn(function() gmLoop(myId) end)
	end

	function ctx.stopGmSprinkler()
		ctx.state.gmSprId = (ctx.state.gmSprId or 0) + 1
	end
end
