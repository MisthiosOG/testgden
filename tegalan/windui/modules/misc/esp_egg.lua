--[[ esp_egg.lua — NEBULA-style Egg ESP (milik Sam, dipotret 1:1) + mode screen.
     MODE "target": BillboardGui polos nempel di egg (NEBULA asli):
       - belum siap : <kuning>nama egg</> \n <oranye>m:ss</> \n <abu kecil>BW: xkg</>
       - siap       : <kuning>nama egg</> \n <putih>pet (est kg)</> \n <warna>[Size class]</>
     MODE "screen": panel list di sisi kanan layar, satu baris per egg —
       info muncul di layar, bukan di objek. Ready eggs paling atas.
     Size class: >=7 Titanic (merah) / >=6 Semi Titanic (oranye) / >=3 Huge (kuning)
     / sisanya Small (hijau). Isi egg dari upvalue handler PetEggService +
     scan BaseWeight di DataService:GetData. GothamBold 17, RichText.
     Toggle: CFG.espEggEnabled — TERPISAH dari ESP pet.
     Mode: CFG.espEggMode ("target"/"screen"). ]]
return function(ctx)
	local RS = game:GetService("ReplicatedStorage")
	local CS = game:GetService("CollectionService")
	local LP = ctx.LP
	local DataService = ctx.deps.DataService

	-- Game nampilin berat = BaseWeight * 1.10 (sama kayak NEBULA).
	local WEIGHT_MULT = 1.1

	-- eggPets[uuid] = nama pet yang bakal menetas (upvalue handler hatch).
	local eggPets = {}
	-- Cache BaseWeight per uuid (scan data game — NEBULA buildBW).
	local bwCache = {}
	local panel -- { sg, scroll, rows[], layout } untuk mode screen
	local lastMode

	local function updateEggPets()
		pcall(function()
			local remote = RS.GameEvents:FindFirstChild("PetEggService")
			if not remote then return end
			local con = getconnections(remote.OnClientEvent)[1]
			if not con or not con.Function then return end
			local hatchFunc = getupvalue(getupvalue(con.Function, 1), 2)
			eggPets = getupvalue(hatchFunc, 2) or {}
		end)
	end

	local function buildBW()
		pcall(function()
			local ok, d = pcall(function() return DataService:GetData() end)
			if not ok or not d then return end
			local function scan(t)
				for k, v in pairs(t) do
					if type(v) == "table" then
						if v.Data and v.Data.BaseWeight then
							bwCache[tostring(k)] = v.Data.BaseWeight
						else
							scan(v)
						end
					end
				end
			end
			scan(d)
		end)
	end

	local function getBW(uuid)
		if not bwCache[uuid] then buildBW() end
		return bwCache[uuid]
	end

	local function round(n, d)
		local m = 10 ^ (d or 2)
		return math.floor(n * m + 0.5) / m
	end

	local function formatTime(sec)
		sec = math.max(0, math.floor(sec or 0))
		return string.format("%d:%02d", math.floor(sec / 60), sec % 60)
	end

	local function getSizeInfo(kg)
		if kg >= 7 then return "Titanic", "#FF2A2A"
		elseif kg >= 6 then return "Semi Titanic", "#FF8C00"
		elseif kg >= 3 then return "Huge", "#FFD400"
		elseif kg >= 0 then return "Small", "#3CFF3C"
		end
		return "Unknown", "#FFFFFF"
	end

	-- makeESP: Billboard 220x90 nutup 3.5 stud, GothamBold 17, stroke solid,
	-- tanpa background/emoji — 1:1 dengan NEBULA. Text cuma di-update kalo beda.
	local function makeESP(obj, text)
		local part = obj:FindFirstChildWhichIsA("BasePart", true)
		if not part then return end

		local gui = obj:FindFirstChild("EggESP_UI")
		if not gui then
			gui = Instance.new("BillboardGui")
			gui.Name = "EggESP_UI"
			gui.Adornee = part
			gui.Size = UDim2.fromOffset(220, 90)
			gui.StudsOffset = Vector3.new(0, 3.5, 0)
			gui.AlwaysOnTop = true

			local lbl = Instance.new("TextLabel", gui)
			lbl.Name = "Text"
			lbl.Size = UDim2.fromScale(1, 1)
			lbl.BackgroundTransparency = 1
			lbl.RichText = true
			lbl.TextSize = 17
			lbl.Font = Enum.Font.GothamBold
			lbl.TextColor3 = Color3.new(1, 1, 1)
			lbl.TextStrokeTransparency = 0

			gui.Parent = obj
		end

		if gui.Text.Text ~= text then
			gui.Text.Text = text
		end
	end

	local function clearBillboards()
		for _, egg in ipairs(CS:GetTagged("PetEggServer")) do
			pcall(function()
				local g = egg:FindFirstChild("EggESP_UI")
				if g then g:Destroy() end
			end)
		end
	end

	-- ===== Screen mode: panel list di sisi kanan layar =====
	-- ponytail: panel builder didup dari esp_label.lua (~45 baris) — abstraksi
	-- modul bersama gak worth wiring-nya saat ini; naikin kalau ESP ketiga muncul.
	local ACCENT = Color3.fromRGB(255, 212, 0)

	local function ensurePanel(title)
		if panel and panel.Parent then return panel end
		local sg = Instance.new("ScreenGui")
		sg.Name = "CespEggPanel"
		sg.ResetOnSpawn = false
		sg.DisplayOrder = 50
		sg.Parent = (gethui and gethui()) or game:GetService("CoreGui")

		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(1, 0.5)
		f.Position = UDim2.new(1, -10, 0.5, 0)
		f.Size = UDim2.fromOffset(280, 300)
		f.BackgroundColor3 = Color3.fromRGB(16, 12, 20)
		f.BackgroundTransparency = 0.25
		f.BorderSizePixel = 0
		f.Parent = sg
		Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
		local st = Instance.new("UIStroke", f)
		st.Color = ACCENT
		st.Thickness = 1.2
		st.Transparency = 0.35

		local hdr = Instance.new("TextLabel")
		hdr.Size = UDim2.new(1, -12, 0, 26)
		hdr.Position = UDim2.fromOffset(6, 0)
		hdr.BackgroundTransparency = 1
		hdr.Font = Enum.Font.GothamBold
		hdr.TextSize = 13
		hdr.RichText = true
		hdr.TextXAlignment = Enum.TextXAlignment.Left
		hdr.TextColor3 = ACCENT
		hdr.Text = title
		hdr.Parent = f

		local scroll = Instance.new("ScrollingFrame")
		scroll.Position = UDim2.fromOffset(6, 28)
		scroll.Size = UDim2.new(1, -12, 1, -34)
		scroll.BackgroundTransparency = 1
		scroll.BorderSizePixel = 0
		scroll.ScrollBarThickness = 3
		scroll.ScrollingDirection = Enum.ScrollingDirection.Y
		scroll.CanvasSize = UDim2.new()
		scroll.Parent = f
		local layout = Instance.new("UIListLayout", scroll)
		layout.Padding = UDim.new(0, 2)
		layout.SortOrder = Enum.SortOrder.LayoutOrder

		panel = { sg = sg, scroll = scroll, rows = {}, layout = layout }
		return panel
	end

	local function renderRows(rows)
		local p = ensurePanel("<b>EGG ESP</b>  (screen)")
		for i, txt in ipairs(rows) do
			local r = p.rows[i]
			if not r then
				r = Instance.new("TextLabel")
				r.BackgroundTransparency = 1
				r.Size = UDim2.new(1, -4, 0, 18)
				r.Font = Enum.Font.Gotham
				r.TextSize = 13
				r.RichText = true
				r.TextXAlignment = Enum.TextXAlignment.Left
				r.TextTruncate = Enum.TextTruncate.AtEnd
				r.TextColor3 = Color3.new(1, 1, 1)
				r.LayoutOrder = i
				r.Parent = p.scroll
				p.rows[i] = r
			end
			if r.Text ~= txt then r.Text = txt end
		end
		for i = #rows + 1, #p.rows do p.rows[i]:Destroy(); p.rows[i] = nil end
		p.scroll.CanvasSize = UDim2.fromOffset(0, p.layout.AbsoluteContentSize.Y + 6)
	end

	local function clearPanel()
		if panel then pcall(function() panel.sg:Destroy() end); panel = nil end
	end

	local function clearAll()
		clearBillboards()
		clearPanel()
	end

	local lastMeta = 0
	local function update(mode)
		local now = os.clock()
		-- Refresh metadata egg/BW tiap 3s (murah, yang tiap-tick cuma teks).
		if now - lastMeta >= 3 then
			lastMeta = now
			updateEggPets()
			buildBW()
		end

		-- Kumpulin data dulu; render sesuai mode.
		local entries = {}
		for _, egg in ipairs(CS:GetTagged("PetEggServer")) do
			if egg:GetAttribute("OWNER") == LP.Name then
				if egg:GetAttribute("READY") or tonumber(egg:GetAttribute("TimeToHatch")) then
					local uuid = tostring(egg:GetAttribute("OBJECT_UUID"))
					local bw = getBW(uuid)
					if bw then
						entries[#entries + 1] = {
							egg = egg,
							eggName = egg:GetAttribute("EggName") or egg.Name,
							uuid = uuid,
							bw = bw,
							ready = egg:GetAttribute("READY"),
							timeLeft = tonumber(egg:GetAttribute("TimeToHatch")) or 0,
						}
					end
				end
			end
		end
		-- Ready dulu, sisanya sisa-waktu ascending.
		table.sort(entries, function(a, b)
			if a.ready ~= b.ready then return a.ready == true end
			return a.timeLeft < b.timeLeft
		end)

		if mode == "screen" then
			local rows = {}
			for i, e in ipairs(entries) do
				if i > 40 then break end
				local petName = eggPets[e.uuid] or "Pet"
				local t
				if not e.ready then
					t = ("<font color='#FFD400'>%s</font> <font color='#FF5E00'>%s</font> <font size='11' color='#BBBBBB'>BW: %skg</font>")
						:format(e.eggName, formatTime(e.timeLeft), tostring(e.bw))
				else
					local est = round(e.bw * WEIGHT_MULT, 2)
					local size, color = getSizeInfo(est)
					t = ("<font color='#FFD400'>%s</font> <font color='#FFFFFF'>%s (%skg)</font> <font color='%s'>[%s]</font>")
						:format(e.eggName, petName, tostring(est), color, size)
				end
				rows[#rows + 1] = t
			end
			renderRows(rows)
		else
			clearPanel()
			for _, e in ipairs(entries) do
				local petName = eggPets[e.uuid] or "Pet"
				local text
				if not e.ready then
					text = string.format(
						'<font color="#FFD400">%s</font>\n<font color="#FF5E00">%s</font>\n<font size="12" color="#BBBBBB">BW: %skg</font>',
						e.eggName,
						formatTime(e.timeLeft),
						tostring(e.bw)
					)
				else
					local est = round(e.bw * WEIGHT_MULT, 2)
					local size, color = getSizeInfo(est)
					text = string.format(
						'<font color="#FFD400">%s</font>\n<font color="#FFFFFF">%s (%skg)</font>\n<font color="%s">[%s]</font>',
						e.eggName,
						petName,
						tostring(est),
						color,
						size
					)
				end
				makeESP(e.egg, text)
			end
		end
	end

	local loopId = 0
	function ctx.startEspEgg()
		loopId = loopId + 1
		local my = loopId
		task.spawn(function()
			updateEggPets()
			buildBW()
			while ctx.alive() and ctx.CFG.espEggEnabled and loopId == my do
				local mode = (ctx.CFG.espEggMode == "screen") and "screen" or "target"
				if mode ~= lastMode then
					lastMode = mode
					clearAll()
				end
				pcall(update, mode)
				task.wait(0.5)
			end
			clearAll()
		end)
	end

	function ctx.stopEspEgg()
		loopId = loopId + 1
		clearAll()
	end
end
