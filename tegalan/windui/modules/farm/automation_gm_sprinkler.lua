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
	local setStatus = ctx.setStatus

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
		local found, minLife = false, math.huge
		for _, o in ipairs(of:GetChildren()) do
			if (o:GetAttribute("OBJECT_TYPE") or o.Name) == GM_TYPE
				and o:GetAttribute("OWNER") == LP.Name then
				found = true
				local life = tonumber(o:GetAttribute("Lifetime"))
				if life and life < minLife then minLife = life end
			end
		end
		if not found then return "none", 0 end
		if minLife < math.huge and minLife <= GM_REFILL then return "expiring", minLife end
		return "alive", (minLife < math.huge and minLife or 0)
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
						-- berselang 3 detik: beri waktu server untuk melakukan spawn, jangan terjadi double-place
						task.wait(3)
					end
				end
			end
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
