--[[ esp_label.lua — ESP PET dengan 2 mode:
     target : label BillboardGui nempel di atas tiap pet di dunia (klasik).
     screen : PLAIN TEXT list di layar (tanpa background/frame) — per baris:
              nama + berat + level + cd skill ("15s | 10m" / "READY").
     Shared screen renderer: modul ini (load pertama) yang owns gui list
     layar; esp_egg (load kedua) nimpa baris egg-nya lewat ctx.espScreenData.
      Keduanya ON → satu list (font 16) + pembatas di antara egg dan pet.
      Satu ON → list sama, tanpa pembatas. Nama pet warna tetap per nama.
     Data pet: nama tipe + berat (BaseWeight*1.1) + level + cd skill.
     Cd pet dapet dari server push PetCooldownsUpdated + seed GetPetCooldown
     (sisa detik di-interpolasi lokal biar countdown halus antara push).
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

	-- ===== Shared screen list (TABEL KOLOM, tanpa background) =====
	-- ctx.espScreenData.pet / .egg masing-masing modul isi sendiri — bentuknya
	-- SLOT SPEC per baris: { name=richtext, kg=richtext, lv=richtext?, tail=richtext? }
	-- paint() render jadi tabel 4 kolom rata kanan-tengah layar:
	--   [nama (kiri)] [kg (kanan)] [lv (kanan)] [tail (kiri)]
	-- Kolom bikin semua baris SIMETRIS walau panjang nama beda-beda. Frame
	-- per baris di-pool biar gak buang2 instance tiap 0.5s.
	ctx.espScreenData = ctx.espScreenData or { pet = nil, egg = nil }
	local screenData = ctx.espScreenData
	local listSg, listFrame
	local rowPool = {} -- i -> { frame, name, kg, lv, tail, sep }

	-- Lebar kolom (total blok 480px): 232 nama, 82 kg, 58 lv, 90 tail + gap 6px.
	local C_NAME_W, C_KG_W, C_LV_W, C_GAP = 232, 82, 58, 6
	local C_KG_X = C_NAME_W + C_GAP
	local C_LV_X = C_KG_X + C_KG_W + C_GAP
	local C_TAIL_X = C_LV_X + C_LV_W + C_GAP

	local function newCol(parent, x, w, size)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Position = UDim2.fromOffset(x or 0, 0)
		l.Size = UDim2.fromOffset(w, 22)
		l.Font = Enum.Font.GothamBold
		l.RichText = true
		l.TextSize = size or 13
		l.TextTruncate = Enum.TextTruncate.AtEnd
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.TextYAlignment = Enum.TextYAlignment.Center
		l.TextColor3 = Color3.new(1, 1, 1)
		local st = Instance.new("UIStroke")
		st.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		st.Color = Color3.new(0, 0, 0)
		st.Thickness = 1.5
		st.Transparency = 0.1
		st.Parent = l
		l.Parent = parent
		return l
	end

	local function getSlot(i)
		local r = rowPool[i]
		if r and not r.frame.Parent then
			pcall(function() r.frame:Destroy() end)
			r = nil
		end
		if not r then
			local frame = Instance.new("Frame")
			frame.BackgroundTransparency = 1
			frame.Size = UDim2.new(1, 0, 0, 22)
			frame.LayoutOrder = i
			r = {
				frame = frame,
				name = newCol(frame, 0, C_NAME_W, 16),
				kg = newCol(frame, C_KG_X, C_KG_W, 13),
				lv = newCol(frame, C_LV_X, C_LV_W, 13),
				tail = newCol(frame, C_TAIL_X, 480 - C_TAIL_X, 13),
				sep = newCol(frame, 0, 480, 12),
			}
			r.kg.TextXAlignment = Enum.TextXAlignment.Right
			r.lv.TextXAlignment = Enum.TextXAlignment.Right
			frame.Parent = listFrame
			rowPool[i] = r
		end
		return r
	end

	local function paint()
		local hasE = screenData.egg and #screenData.egg > 0
		local hasP = screenData.pet and #screenData.pet > 0
		if not (hasE or hasP) then
			if listSg then pcall(function() listSg:Destroy() end) end
			listSg, listFrame = nil, nil
			rowPool = {}
			return
		end
		if not (listSg and listSg.Parent) then
			listSg = Instance.new("ScreenGui")
			listSg.Name = "CespEspList"
			listSg.ResetOnSpawn = false
			listSg.DisplayOrder = 50
			listSg.IgnoreGuiInset = true
			listSg.Parent = (gethui and gethui()) or game:GetService("CoreGui")

			listFrame = Instance.new("Frame")
			-- Sisi KANAN TENGAH: blok nempel pinggir kanan layar.
			listFrame.AnchorPoint = Vector2.new(1, 0.5)
			listFrame.Position = UDim2.new(1, -14, 0.5, 0)
			listFrame.Size = UDim2.new(0, 480, 0, 0)
			listFrame.AutomaticSize = Enum.AutomaticSize.Y
			listFrame.BackgroundTransparency = 1
			local layout = Instance.new("UIListLayout")
			layout.FillDirection = Enum.FillDirection.Vertical
			layout.SortOrder = Enum.SortOrder.LayoutOrder
			layout.Parent = listFrame
			listFrame.Parent = listSg
		end

		-- Slot urut: [egg…, pembatas, pet…]
		local slots = {}
		for _, s in ipairs(screenData.egg or {}) do slots[#slots + 1] = s end
		if hasE and hasP then slots[#slots + 1] = { sep = true } end
		for _, s in ipairs(screenData.pet or {}) do slots[#slots + 1] = s end

		for i, s in ipairs(slots) do
			local r = getSlot(i)
			r.frame.LayoutOrder = i
			if s.sep then
				r.name.Visible, r.kg.Visible, r.lv.Visible, r.tail.Visible = false, false, false, false
				r.sep.Visible = true
				r.sep.Text = '<font color="#9A9A9A">' .. string.rep("─", 22) .. "</font>"
			else
				r.name.Visible = s.name ~= nil
				r.kg.Visible = s.kg ~= nil
				r.lv.Visible = s.lv ~= nil
				r.tail.Visible = s.tail ~= nil
				r.sep.Visible = false
				r.name.Text = s.name or ""
				r.kg.Text = s.kg or ""
				r.lv.Text = s.lv or ""
				r.tail.Text = s.tail or ""
			end
		end
		-- Buang row lebih dari slot sekarang.
		for i = #slots + 1, #rowPool do
			local r = rowPool[i]
			if r then pcall(function() r.frame:Destroy() end) end
			rowPool[i] = nil
		end
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
	local C_S_CD = "#FFD21E" -- warna sisa cd skill (READY pakai hijau C_S_LV)
	local function nameColor(s)
		local h = 0
		for i = 1, #s do h = (h * 31 + string.byte(s, i)) % 100003 end
		return NAME_COLORS[(h % #NAME_COLORS) + 1]
	end

	-- ===== Data cooldown pet (server push PetCooldownsUpdated) =====
	-- Event kirim (uuid, {{Time=<sisa detik>, Passive=<nama>}, ...}).
	-- Passive "Mutation" bukan skill → di-skip, konsisten dengan logika pickup.
	-- Sisa detik di-interpolasi lokal (Time - elapsed) biar countdown jalan
	-- halus antara dua push server.
	local cdRem = {} -- uuid -> { times = {sisa detik per skill}, at = os.clock() }
	local cdSeeded = {} -- uuid -> true (seed GetPetCooldown sudah/sedang dijalankan)
	local RSRaw = game:GetService("ReplicatedStorage")
	local cdGameEvents = RSRaw:FindFirstChild("GameEvents")
	local cdPushEvent = cdGameEvents and cdGameEvents:FindFirstChild("PetCooldownsUpdated")
	local cdSeedRemote = cdGameEvents and cdGameEvents:FindFirstChild("GetPetCooldown")

	local function storeCd(uuid, cdTable)
		if type(cdTable) ~= "table" then return end
		local times = {}
		for _, e in ipairs(cdTable) do
			if not tostring(e.Passive or ""):find("Mutation") then
				times[#times + 1] = tonumber(e.Time) or 0
			end
		end
		cdRem[uuid] = { times = times, at = os.clock() }
	end

	local gEnv = (getgenv and getgenv()) or _G
	if gEnv.__cespCdConn then pcall(function() gEnv.__cespCdConn:Disconnect() end) end
	gEnv.__cespCdConn = nil
	if cdPushEvent then
		gEnv.__cespCdConn = cdPushEvent.OnClientEvent:Connect(function(uuid, cdTable)
			if type(uuid) == "string" then storeCd(uuid, cdTable) end
		end)
	end

	-- Seed awal per pet: InvokeServer yield → fire-and-forget di task.spawn.
	local function seedCd(uuid)
		if cdSeeded[uuid] or not cdSeedRemote then return end
		cdSeeded[uuid] = true
		task.spawn(function()
			local ok, cd = pcall(function() return cdSeedRemote:InvokeServer(uuid) end)
			if ok then storeCd(uuid, cd) end
		end)
	end

	local function fmtDur(sec)
		if sec < 60 then return ("%ds"):format(math.clamp(math.ceil(sec), 0, 59)) end
		if sec < 3600 then return ("%dm"):format(math.floor(sec / 60)) end
		return ("%dh"):format(math.floor(sec / 3600))
	end

	-- Segmen cd untuk satu pet: "15s | 10m" atau "READY", nil kalau pet
	-- tanpa skill / data belum masuk (seed dikirim sekali per uuid).
	local function cdSegment(uuid)
		local rec = cdRem[uuid]
		if not rec then seedCd(uuid); return nil end
		if #rec.times == 0 then return nil end
		local el = os.clock() - rec.at
		local parts, allReady = {}, true
		for _, t0 in ipairs(rec.times) do
			local rem = t0 - el
			if rem > 0.05 then
				allReady = false
				parts[#parts + 1] = fmtDur(rem)
			end
		end
		if allReady then return "READY" end
		return table.concat(parts, " | ")
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
								-- Slot spec: [nama][kg][Lv][cd]. Cd skill ("15s | 10m"),
								-- READY kalau semua skill siap — pengganti teks mutasi.
								local cd = cdSegment(uuid)
								rows[#rows + 1] = {
									name = ('<b><font color="%s">%s</font></b>'):format(nameColor(tostring(pt)), tostring(pt)),
									kg = ('<font color="%s">%s</font>'):format(C_S_WEIGHT, w),
									lv = ('<font color="%s">Lv.%d</font>'):format(C_S_LV, lv),
									tail = cd and ('<font color="%s">%s</font>'):format((cd == "READY") and C_S_LV or C_S_CD, cd) or nil,
								}
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
