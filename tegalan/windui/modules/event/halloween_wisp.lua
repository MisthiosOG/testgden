--[[ halloween_wisp.lua — Event Halloween 2026: Auto Collect Horseman Wisp.
     Pas Headless Horseman lagi "Riding", dia jatuhin Wisp (workspace.HorsemanHuntVisuals,
     model "Wisp", hidup 45 s). Game ngumpulin wisp sendiri kalau karakter dalam radius 6
     (HorsemanHuntController.startCollect -> HorsemanHunt.Collect:FireServer(rideId, index)).
     Server ngecek jarak (<= 22) & kecepatan (<= 80 studs/s), jadi kita GERAK ke tiap wisp
     (bukan teleport) pakai kecepatan aman, biar collect bawaan game yang jalan.
     Cadangan: kalau udah nempel tapi wisp nggak keambil, cari (rideId, index) wisp itu di
     tabel controller (getgc) lalu FireServer langsung.
     Config: wispEnabled, wispSpeed, wispReturn. Fungsi: ctx.startWisp / ctx.stopWisp /
     ctx.getWispSummary. ]]
return function(ctx)
	local CFG = ctx.CFG
	local LP  = ctx.LP
	local RS  = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	local function setStatus(s) if ctx.setStatus then pcall(ctx.setStatus, s) end end

	local MAX_SPEED   = 60   -- server tolak > 80 (+slack 12); 60 aman
	local REACH       = 2.5  -- dianggap udah di atas wisp
	local STUCK_WAIT  = 1.2  -- di atas wisp segini & belum keambil -> fallback FireServer

	local function hunt()
		local ge = RS:FindFirstChild("GameEvents")
		local ev = ge and ge:FindFirstChild("Events")
		local hw = ev and ev:FindFirstChild("Halloween2026Event")
		return hw and hw:FindFirstChild("HorsemanHunt")
	end
	local function phase()
		local h = hunt()
		local ok, p = pcall(function() return h and h:GetAttribute("Phase") end)
		return ok and p or nil
	end

	local function wisps()
		local out = {}
		local f = workspace:FindFirstChild("HorsemanHuntVisuals")
		if not f then return out end
		for _, m in ipairs(f:GetChildren()) do
			if m:IsA("Model") and m.Name == "Wisp" then
				local ok, pos = pcall(function() return m:GetPivot().Position end)
				if ok and pos then out[#out + 1] = { model = m, pos = pos } end
			end
		end
		return out
	end

	local stats = { collected = 0, startAt = nil, last = nil }

	-- cadangan: cari entry wisp {RideId, Index, Model} di memori controller
	local function findWispIds(model)
		if type(getgc) ~= "function" then return nil end
		local ok, res = pcall(function()
			for _, v in ipairs(getgc(true)) do
				if type(v) == "table" and rawget(v, "Model") == model
					and type(rawget(v, "RideId")) == "number" and type(rawget(v, "Index")) == "number" then
					return { v.RideId, v.Index }
				end
			end
		end)
		return ok and res or nil
	end

	local function hrp()
		local c = LP.Character
		return c and c:FindFirstChild("HumanoidRootPart")
	end

	-- gerak lurus ke target dengan kecepatan aman. return true kalau nyampe.
	local function moveTo(target, myId)
		local speed = math.clamp(tonumber(CFG.wispSpeed) or 45, 10, MAX_SPEED)
		local t0 = os.clock()
		while CFG.wispEnabled and ctx.alive() and ctx.state.wispId == myId do
			local root = hrp()
			if not root then return false end
			local cur = root.Position
			local flat = Vector3.new(target.X, cur.Y, target.Z)
			local d = flat - cur
			if d.Magnitude <= REACH then return true end
			local dt = RunService.Heartbeat:Wait()
			local step = math.min(d.Magnitude, speed * dt)
			local np = cur + d.Unit * step
			pcall(function()
				root.CFrame = CFrame.new(np, np + d.Unit)
				root.AssemblyLinearVelocity = Vector3.zero
			end)
			if os.clock() - t0 > 20 then return false end
		end
		return false
	end

	local function loop(myId)
		ctx.elevate()
		local home = nil
		local idleSince = nil
		while CFG.wispEnabled and ctx.alive() and ctx.state.wispId == myId do
			local ok, err = pcall(function()
				local list = wisps()
				local root = hrp()
				if not root then task.wait(1); return end
				if #list == 0 then
					setStatus(("Wisp: menunggu wisp (phase: %s)"):format(tostring(phase() or "-")))
					idleSince = idleSince or os.clock()
					-- balik ke posisi awal kalau udah sepi 5 s
					if home and CFG.wispReturn ~= false and os.clock() - idleSince > 5 then
						moveTo(home, myId)
						home = nil
					end
					task.wait(0.5)
					return
				end
				idleSince = nil
				if not home then home = root.Position end
				stats.startAt = stats.startAt or os.time()
				-- wisp terdekat dulu
				table.sort(list, function(a, b)
					return (a.pos - root.Position).Magnitude < (b.pos - root.Position).Magnitude
				end)
				local w = list[1]
				setStatus(("Wisp: ambil (%d di map, %d terkumpul)"):format(#list, stats.collected))
				if not moveTo(w.pos, myId) then return end
				-- tunggu collect bawaan game
				local t0 = os.clock()
				while w.model.Parent and os.clock() - t0 < STUCK_WAIT do task.wait(0.05) end
				if w.model.Parent then
					local ids = findWispIds(w.model)
					local h = hunt()
					local remote = h and h:FindFirstChild("Collect")
					if ids and remote then
						pcall(function() remote:FireServer(ids[1], ids[2]) end)
						local t1 = os.clock()
						while w.model.Parent and os.clock() - t1 < 1 do task.wait(0.05) end
					end
				end
				if not w.model.Parent then
					stats.collected = stats.collected + 1
					stats.last = os.time()
				end
			end)
			if not ok and ctx.log then ctx.log("[Wisp] error: " .. tostring(err)) end
			task.wait(0.05)
		end
	end

	function ctx.startWisp()
		ctx.state.wispId = (ctx.state.wispId or 0) + 1
		task.spawn(loop, ctx.state.wispId)
	end
	function ctx.stopWisp()
		ctx.state.wispId = (ctx.state.wispId or 0) + 1
	end
	function ctx.getWispSummary()
		return {
			status = CFG.wispEnabled and "ACTIVE" or "STOPPED",
			phase = tostring(phase() or "-"),
			onMap = #wisps(),
			collected = stats.collected,
			last = stats.last and os.date("%H:%M:%S", stats.last) or "-",
		}
	end
end
