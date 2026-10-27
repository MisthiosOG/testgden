--[[ esp_label.lua — ESP PET dengan 2 mode:
     target : label BillboardGui nempel di atas tiap pet di dunia (klasik).
     screen : panel list di sisi kanan layar, satu baris per pet — info muncul
              di layar, BUKAN nempel di objek.
     Data pet: nama tipe + berat (BaseWeight*1.1) + level + mutasi.
     ESP EGG TERPISAH di modules/misc/esp_egg.lua (mode masing-masing).
     Toggle: CFG.espEnabled, mode: CFG.espMode ("target"/"screen"). ]]
return function(ctx)
	local LP = ctx.LP
	local DataService = ctx.deps.DataService

	-- Game nampilin berat = BaseWeight * 1.1 (bukan raw BaseWeight).
	local WEIGHT_MULT = 1.1

	local bbFolder
	local billboards = {} -- key -> { gui, lbl }
	local panel -- { sg, scroll, rows[] } untuk mode screen
	local lastMode

	local function ensureFolder()
		if bbFolder and bbFolder.Parent then return bbFolder end
		bbFolder = Instance.new("Folder")
		bbFolder.Name = "AllegiaanESP"
		bbFolder.Parent = (gethui and gethui()) or game:GetService("CoreGui")
		return bbFolder
	end

	local function partOf(model)
		if model:IsA("BasePart") then return model end
		if model.PrimaryPart then return model.PrimaryPart end
		for _, d in ipairs(model:GetDescendants()) do if d:IsA("BasePart") then return d end end
		return nil
	end

	local function makeBB(key, adornee, offset)
		local bb = Instance.new("BillboardGui")
		bb.Name = "esp_" .. key
		bb.Adornee = adornee
		bb.Size = UDim2.fromOffset(260, 72)
		bb.StudsOffset = Vector3.new(0, offset or 2.8, 0)
		bb.AlwaysOnTop = true
		bb.MaxDistance = 600
		bb.LightInfluence = 0
		bb.ClipsDescendants = false
		bb.Parent = ensureFolder()

		-- Background card (dark,According to menu theme)
		local bg = Instance.new("Frame")
		bg.Size = UDim2.new(1, 0, 1, 0)
		bg.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
		bg.BackgroundTransparency = 0.22
		bg.BorderSizePixel = 0
		bg.Parent = bb
		Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 10)
		local bgStroke = Instance.new("UIStroke", bg)
		bgStroke.Color = Color3.fromRGB(235, 235, 235)
		bgStroke.Thickness = 1.2
		bgStroke.Transparency = 0.4
		bgStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		local lbl = Instance.new("TextLabel")
		lbl.BackgroundTransparency = 1
		lbl.Size = UDim2.new(1, -8, 1, 0)
		lbl.Position = UDim2.fromOffset(4, 0)
		lbl.Font = Enum.Font.FredokaOne
		lbl.TextSize = 15
		lbl.RichText = true
		lbl.TextColor3 = Color3.new(1, 1, 1)
		lbl.TextStrokeTransparency = 0.5
		lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
		lbl.TextYAlignment = Enum.TextYAlignment.Center
		lbl.ZIndex = 4
		lbl.Parent = bg

		local rec = { gui = bb, lbl = lbl }
		billboards[key] = rec
		return rec
	end

	local function acquire(key, adornee, offset)
		local rec = billboards[key]
		if (not rec) or rec.gui.Adornee ~= adornee or not rec.gui.Parent then
			if rec then rec.gui:Destroy(); billboards[key] = nil end
			rec = makeBB(key, adornee, offset)
		end
		return rec
	end

	local function clearBillboards()
		for _, rec in pairs(billboards) do pcall(function() rec.gui:Destroy() end) end
		billboards = {}
		if bbFolder then pcall(function() bbFolder:Destroy() end); bbFolder = nil end
	end

	-- ===== Screen mode: panel list di sisi kanan layar =====
	-- ponytail: panel builder didup di esp_egg.lua (~45 baris) — abstraksi
	-- modul bersama gak worth wiring-nya saat ini; naikin kalau ESP ketiga muncul.
	local ACCENT = Color3.fromRGB(235, 235, 235)
	-- Palet teks monokrom (sesuai menu): putih / abu.
	local C_NAME = "#FFFFFF"
	local C_WEIGHT = "#D6D6D6"
	local C_LV = "#969696"
	local C_MUT = "#B4B4B4"

	local function ensurePanel(title)
		if panel and panel.Parent then return panel end
		clearBillboards()
		local sg = Instance.new("ScreenGui")
		sg.Name = "CespPetPanel"
		sg.ResetOnSpawn = false
		sg.DisplayOrder = 50
		sg.Parent = (gethui and gethui()) or game:GetService("CoreGui")

		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(1, 0.5)
		f.Position = UDim2.new(1, -10, 0.5, 0)
		f.Size = UDim2.fromOffset(260, 300)
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
		local p = ensurePanel("<b>PET ESP</b>  (screen)")
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

	-- ===== Data pet =====
	local function update(mode)
		local okData, d = pcall(function() return DataService:GetData() end)
		local inv = okData and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}
		local seen = {}
		local rows = {}
		local pp = workspace:FindFirstChild("PetsPhysical")
		if pp then
			for _, mover in ipairs(pp:GetChildren()) do
				for _, petModel in ipairs(mover:GetChildren()) do
					if petModel:IsA("Model") then
						local uuid = petModel.Name
						local pData = inv[uuid]
						if pData then
							local pt = pData.PetType or "Pet"
							local pd = pData.PetData or {}
							local bw = tonumber(pd.BaseWeight)
							local lv = tonumber(pd.Level) or 0
							local mut = pd.MutationType
							local mutTxt = (mut and mut ~= "" and mut ~= "Normal" and mut ~= "m") and tostring(mut) or nil

							if mode == "screen" then
								local w = bw and string.format("%.2fkg", bw * WEIGHT_MULT) or "-"
								local t = ("<font color='%s'><b>%s</b></font> <font color='%s'>%s</font> <font color='%s'>Lv.%d</font>")
									:format(C_NAME, tostring(pt), C_WEIGHT, w, C_LV, lv)
								if mutTxt then t = t .. (" <font color='%s'>%s</font>"):format(C_MUT, mutTxt) end
								rows[#rows + 1] = t
								if #rows >= 40 then break end
							else
								local adornee = partOf(petModel)
								if adornee then
									local key = "pet_" .. tostring(uuid)
									seen[key] = true
									local rec = acquire(key, adornee, 2.5)
									local lines = { ("<font color='%s'><b>🐾 %s</b></font>"):format(C_NAME, tostring(pt)) }
									if bw then
										lines[#lines + 1] = ("<font color='%s'>%.2f KG</font> <font color='%s'>[Lv.%d]</font>"):format(C_WEIGHT, bw * WEIGHT_MULT, C_LV, lv)
									end
									if mutTxt then
										lines[#lines + 1] = ("<font color='%s'>✨ %s</font>"):format(C_MUT, mutTxt)
									end
									rec.lbl.Text = table.concat(lines, "\n")
								end
							end
						end
					end
				end
				if #rows >= 40 then break end
			end
		end

		if mode == "screen" then
			renderRows(rows)
		else
			clearPanel()
			for key, rec in pairs(billboards) do
				if not seen[key] then rec.gui:Destroy(); billboards[key] = nil end
			end
		end
	end

	local function clearAll()
		clearBillboards()
		clearPanel()
	end

	local loopId = 0
	function ctx.startEsp()
		loopId = loopId + 1
		local my = loopId
		-- Generation guard: loop dari eksekusi loader sebelumnya mati saat gen naik,
		-- jadi panel nggak jadi zombie pasesp re-exec / toggle off.
		local gen = (getgenv().GAG_ESP_GEN or 0)
		task.spawn(function()
			while ctx.alive() and ctx.CFG.espEnabled and loopId == my and (getgenv().GAG_ESP_GEN or 0) == gen do
				local mode = (ctx.CFG.espMode == "screen") and "screen" or "target"
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

	function ctx.stopEsp()
		loopId = loopId + 1
		clearAll()
	end
end
