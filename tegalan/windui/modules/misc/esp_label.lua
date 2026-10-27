--[[ esp_label.lua — ESP PET dengan 2 mode:
     target : label BillboardGui nempel di atas tiap pet di dunia (klasik).
     screen : PLAIN TEXT list di layar (tanpa background/frame) — per baris:
              nama + berat + level + mutasi.
     Shared screen renderer: modul ini (load pertama) yang owns gui list
     layar; esp_egg (load kedua) nimpa baris egg-nya lewat ctx.espScreenData.
      Keduanya ON → satu list (font 16) + pembatas di antara egg dan pet.
      Satu ON → list sama, tanpa pembatas. Nama pet warna tetap per nama.
     Data pet: nama tipe + berat (BaseWeight*1.1) + level + mutasi.
     ESP EGG TERPISAH di modules/misc/esp_egg.lua.
     Toggle: CFG.espEnabled, mode: CFG.espMode ("target"/"screen"). ]]
return function(ctx)
	local LP = ctx.LP
	local DataService = ctx.deps.DataService

	-- Game nampilin berat = BaseWeight * 1.1 (bukan raw BaseWeight).
	local WEIGHT_MULT = 1.1

	local bbFolder
	local billboards = {} -- key -> { gui, lbl }
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

		-- Background card (dark, sesuai tema menu)
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

	-- ===== Shared screen list (plain text, tanpa background) =====
	-- ctx.espScreenData.pet / .egg masing-masing modul isi sendiri;
	-- paint() gabungin: [egg baris] \n [pembatas] \n [pet baris].
	-- Dua-duanya ON → font 16; satu → font 16, tanpa pembatas.
	ctx.espScreenData = ctx.espScreenData or { pet = nil, egg = nil }
	local screenData = ctx.espScreenData
	local listSg, listLbl

	local function paint()
		local hasE = screenData.egg and #screenData.egg > 0
		local hasP = screenData.pet and #screenData.pet > 0
		if not (hasE or hasP) then
			if listSg then pcall(function() listSg:Destroy() end) end
			listSg, listLbl = nil, nil
			return
		end
		if not (listSg and listSg.Parent) then
			listSg = Instance.new("ScreenGui")
			listSg.Name = "CespEspList"
			listSg.ResetOnSpawn = false
			listSg.DisplayOrder = 50
			listSg.IgnoreGuiInset = true
			listSg.Parent = (gethui and gethui()) or game:GetService("CoreGui")

			listLbl = Instance.new("TextLabel")
			listLbl.AnchorPoint = Vector2.new(0, 0.5)
			listLbl.Position = UDim2.new(0, 14, 0.5, 0)
			listLbl.Size = UDim2.new(0, 480, 0, 0)
			listLbl.AutomaticSize = Enum.AutomaticSize.Y
			listLbl.BackgroundTransparency = 1
			listLbl.Font = Enum.Font.GothamBold
			listLbl.RichText = true
			listLbl.TextXAlignment = Enum.TextXAlignment.Left
			listLbl.TextYAlignment = Enum.TextYAlignment.Top
			listLbl.TextColor3 = Color3.new(1, 1, 1)
			-- Outline tebal biar teks tetap kebaca di background terang (sky).
			local listStroke = Instance.new("UIStroke")
			listStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
			listStroke.Color = Color3.new(0, 0, 0)
			listStroke.Thickness = 1.6
			listStroke.Transparency = 0.1
			listStroke.Parent = listLbl
			listLbl.Text = ""
			listLbl.Parent = listSg
		end

		local lines = {}
		if hasE then
			for _, t in ipairs(screenData.egg) do lines[#lines + 1] = t end
		end
		if hasE and hasP then
			lines[#lines + 1] = '<font color="#9A9A9A" size="12">' .. string.rep("─", 20) .. "</font>"
		end
		if hasP then
			for _, t in ipairs(screenData.pet) do lines[#lines + 1] = t end
		end
		listLbl.TextSize = 16
		listLbl.Text = table.concat(lines, "\n")
	end
	ctx.espScreenPaint = paint

	local function claimPetScreen(rows)
		screenData.pet = (rows and #rows > 0) and rows or nil
		paint()
	end

	-- Palet billboard (target mode): card gelap di belakang → putih/abu aman.
	local C_NAME = "#FFFFFF"
	local C_WEIGHT = "#D6D6D6"
	local C_LV = "#969696"
	local C_MUT = "#B4B4B4"

	-- Palet screen list: TANPA background → teks harus cerah biar kebaca.
	-- Nama pet: warna tetap per nama (hash) — beda-beda tapi konsisten.
	local NAME_COLORS = {
		"#33C1FF", "#FF5EC8", "#4DF08A", "#B06CFF", "#2CE8CC", "#FF7A3C", "#C6FF33", "#FFD21E",
	}
	local C_S_WEIGHT = "#FFAA00"
	local C_S_LV = "#33FF77"
	local MUT_SCREEN = {
		Golden = "#FFD700", Rainbow = "#FF4FD8", Frozen = "#33CFFF", Wet = "#00B0FF",
		Shocked = "#FFEE33", Moonlit = "#9D66FF", Shiny = "#FFB300", Huge = "#FF3D3D",
		Mega = "#E60000", Tiny = "#4DD2FF", Windstruck = "#66FFCC", Tempered = "#FF7043",
	}
	local function nameColor(s)
		local h = 0
		for i = 1, #s do h = (h * 31 + string.byte(s, i)) % 100003 end
		return NAME_COLORS[(h % #NAME_COLORS) + 1]
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
								local t = ('<font size="17" color="%s"><b>%s</b></font> <font size="13" color="%s">%s</font> <font size="13" color="%s">Lv.%d</font>')
									:format(nameColor(tostring(pt)), tostring(pt), C_S_WEIGHT, w, C_S_LV, lv)
								if mutTxt then
									local mc = MUT_SCREEN[mutTxt] or nameColor("m" .. mutTxt)
									t = t .. (' <font size="13" color="%s">• %s</font>'):format(mc, mutTxt)
								end
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
			claimPetScreen(rows)
		else
			claimPetScreen(nil)
			for key, rec in pairs(billboards) do
				if not seen[key] then rec.gui:Destroy(); billboards[key] = nil end
			end
		end
	end

	local function clearAll()
		clearBillboards()
		claimPetScreen(nil)
	end

	local loopId = 0
	function ctx.startEsp()
		loopId = loopId + 1
		local my = loopId
		-- Generation guard: loop dari eksekusi loader sebelumnya mati saat gen naik.
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
