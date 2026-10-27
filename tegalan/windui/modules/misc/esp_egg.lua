--[[ esp_egg.lua — NEBULA-style Egg ESP (milik Sam, dipotret 1:1) + mode screen.
     MODE "target": BillboardGui polos nempel di egg (NEBULA asli):
       - belum siap : <kuning>nama egg</> \n <oranye>m:ss</> \n <abu kecil>BW: xkg</>
       - siap       : <kuning>nama egg</> \n <putih>pet (est kg)</> \n <warna>[Size class]</>
     MODE "screen": list TABEL KOLOM tanpa background di sisi KANAN TENGAH —
         font 16 bold + outline hitam, nama pet berwarna. Ready eggs paling atas.
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

	-- Nama pet di list screen dikasih warna tetap per nama (hash) — cerah,
	-- rapih, konsisten dengan warna di ESP pet.
	local NAME_COLORS = {
		"#33C1FF", "#FF5EC8", "#4DF08A", "#B06CFF", "#2CE8CC", "#FF7A3C", "#C6FF33", "#FFD21E",
	}
	local function eggNameColor(s)
		local h = 0
		for i = 1, #s do h = (h * 31 + string.byte(s, i)) % 100003 end
		return NAME_COLORS[(h % #NAME_COLORS) + 1]
	end

	-- eggPets[uuid] = nama pet yang bakal menetas (upvalue handler hatch).
	local eggPets = {}
	-- Cache BaseWeight per uuid (scan data game — NEBULA buildBW).
	local bwCache = {}
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

	-- ===== Screen mode: PLAIN TEXT list (tanpa background), lewat shared
	-- renderer di esp_label (ctx.espScreenData / ctx.espScreenPaint).
	-- Fallback: kalau renderer shared belum ada (label module gak ke-load),
	-- bikin gui list sendiri yang gayanya sama.
	local listSg, listFrame
	local rowPool = {}

	-- Kolom tanda tangan yang sama dengan layanan yang dibagikan di esp_label agar daftar cadangan (fallback) tampil dengan tampilan yang sama.
	local function fbNewCol(parent, x, w, size)
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

	local function screenClaim(rows)
		if ctx.espScreenPaint then
			ctx.espScreenData.egg = (rows and #rows > 0) and rows or nil
			ctx.espScreenPaint()
			return
		end
		-- Fallback (label module gak ke-load): renderer tabel kolom sendiri.
		local has = rows and #rows > 0
		if not has then
			if listSg then pcall(function() listSg:Destroy() end) end
			listSg, listFrame, rowPool = nil, nil, {}
			return
		end
		if not (listSg and listSg.Parent) then
			listSg = Instance.new("ScreenGui")
			listSg.Name = "CespEspListEggOnly"
			listSg.ResetOnSpawn = false
			listSg.DisplayOrder = 50
			listSg.IgnoreGuiInset = true
			listSg.Parent = (gethui and gethui()) or game:GetService("CoreGui")

			listFrame = Instance.new("Frame")
			-- Sisi KANAN TENGAH (sama dengan renderer shared di esp_label).
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
			rowPool = {}
		end
		local W_N, W_K, W_L, GP = 232, 82, 58, 6
		for i, s in ipairs(rows) do
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
					name = fbNewCol(frame, 0, W_N, 16),
					kg = fbNewCol(frame, W_N + GP, W_K, 13),
					lv = fbNewCol(frame, W_N + GP + W_K + GP, W_L, 13),
					tail = fbNewCol(frame, W_N + GP + W_K + GP + W_L + GP, 480 - (W_N + GP + W_K + GP + W_L + GP), 13),
				}
				r.kg.TextXAlignment = Enum.TextXAlignment.Right
				r.lv.TextXAlignment = Enum.TextXAlignment.Right
				frame.Parent = listFrame
				rowPool[i] = r
			end
			r.frame.LayoutOrder = i
			r.name.Text, r.kg.Text, r.lv.Text, r.tail.Text = s.name or "", s.kg or "", s.lv or "", s.tail or ""
			r.name.Visible, r.kg.Visible, r.lv.Visible, r.tail.Visible = s.name ~= nil, s.kg ~= nil, s.lv ~= nil, s.tail ~= nil
		end
		for i = #rows + 1, #rowPool do
			if rowPool[i] then pcall(function() rowPool[i].frame:Destroy() end) end
			rowPool[i] = nil
		end
	end

	local function clearAll()
		clearBillboards()
		screenClaim(nil)
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
				local tl = tonumber(egg:GetAttribute("TimeToHatch"))
				-- Countdown jalan kapan pun TimeToHatch > 0. READY dipercaya
				-- cuma kalo timer habis/absen — game ngeset READY=true duluan
				-- sebelum egg beneran siap.
				local isReady = not (tl and tl > 0)
				if egg:GetAttribute("READY") ~= nil or tl then
					local uuid = tostring(egg:GetAttribute("OBJECT_UUID"))
					local bw = getBW(uuid)
					if bw then
						entries[#entries + 1] = {
							egg = egg,
							eggName = egg:GetAttribute("EggName") or egg.Name,
							uuid = uuid,
							bw = bw,
							ready = isReady,
							timeLeft = tl or 0,
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

		-- Slot spec screen (sama bentuknya dengan pet di esp_label):
		-- [nama][kg][lv kosong][tail] → kolom tetap lurus antar baris.
		local rows = {}
		for i, e in ipairs(entries) do
			if i > 40 then break end
			local petName = eggPets[e.uuid] or "Pet"
			if not e.ready then
				rows[#rows + 1] = {
					name = ('<font color="#FFD400">%s</font>'):format(e.eggName),
					kg = ('<font color="#33C1FF">BW: %skg</font>'):format(tostring(e.bw)),
					tail = ('<font color="#FF5E00">%s</font>'):format(formatTime(e.timeLeft)),
				}
			else
				local est = round(e.bw * WEIGHT_MULT, 2)
				local size, color = getSizeInfo(est)
				rows[#rows + 1] = {
					name = ('<font color="#FFD400">%s</font> <b><font color="%s">%s</font></b>')
						:format(e.eggName, eggNameColor(petName), petName),
					kg = ('<font color="#FFAA00">(%skg)</font>'):format(tostring(est)),
					tail = ('<font color="%s">[%s]</font>'):format(color, size),
				}
			end
		end

		if mode == "screen" then
			screenClaim(rows)
		else
			screenClaim(nil)
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
		-- Generation guard: loop dari eksekusi loader sebelumnya mati saat gen naik.
		local gen = (getgenv().GAG_ESP_GEN or 0)
		task.spawn(function()
			updateEggPets()
			buildBW()
			while ctx.alive() and ctx.CFG.espEggEnabled and loopId == my and (getgenv().GAG_ESP_GEN or 0) == gen do
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
