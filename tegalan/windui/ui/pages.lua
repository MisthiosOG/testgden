--[[ pages.lua — WindUI native, migrasi tab-per-tab.
     Fitur = 100% module dari garden (ctx.start*/stop*, CFG, reg — kontrak sama).
     Tab yang sudah dimigrasi: Pet (pilot). Tab lain = placeholder.
     Kalau mau migrasi tab berikutnya: tulis build<tab>Tab lalu daftar di MIGRATED. ]]
return function(ctx)
	local CFG     = ctx.CFG
	local persist = ctx.persistState
	local reg     = ctx.reg
	local W       = ctx.wi
	local window  = W.window

	----------------------------------------------------------------- helper
	local function safe(fn)
		return function(...)
			local args = { ... }
			local ok, err = pcall(fn, table.unpack(args))
			if not ok then ctx.log("[pages] callback error: " .. tostring(err)) end
		end
	end

	-- Build ATOMIK: tanpa task.wait() di tengah build. Dist pin ukuran Section
	-- dari snapshot Top+Content (10751+) — yield bikin layout jalan pas konten
	-- belum lengkap -> pin stale -> panel kepotong (kasus V2).

	local function makeToggleW(parent, title, desc, getv, setv, notifyTitle)
		local control
		control = parent:Toggle({
			Title = title,
			Desc = desc,
			Value = (type(getv) == "function") and (getv() == true) or false,
			Callback = safe(function(v)
				setv(v)
				persist()
				if notifyTitle then
					W.notify(notifyTitle, title .. " -> " .. (v and "ON" or "OFF"))
				end
				if ctx.log then ctx.log(title .. " -> " .. (v and "ON" or "OFF")) end
				if control and control.Set and type(getv) == "function" then
					local real = getv()
					if real ~= v then pcall(function() control:Set(real) end) end
				end
			end),
		})
		return control
	end

	local function makeInputW(parent, title, desc, getv, setv)
		parent:Input({
			Title = title,
			Desc = desc,
			Type = "Input",
			Value = tostring((type(getv) == "function") and getv() or (getv or "")),
			Callback = safe(function(value)
				setv(value)
				persist()
			end),
		})
	end

	-- Cache opsi dinamis: dropdown V1, V2 & Boost pets sama-sama ambil
	-- ctx.inventoryPetOptions -> GetData bisa nunggu data game pas baru join
	-- (freeze 4.5-23s kalau 3 dropdown fetch serial). Caller pertama fetch,
	-- caller lain nunggu hasilnya -> cukup SATU GetData per cacheKey per TTL.
	local optCache = {}
	-- Cache opsi 5 menit: dropdown gak perlu re-scan tiap buka (dulu TTL 5s ->
	-- tiap klik Mindahin freeze). "Update Pet List" satu-satunya yang force
	-- re-scan (klik eksplisit user, jadi wajar nunggu sekali).
	local TTL_OPTIONS = 300
	local function fetchOptions(cacheKey, getOptions, force)
		if not cacheKey then
			local ok, list = pcall(getOptions)
			return (ok and type(list) == "table") and list or {}
		end
		local c = optCache[cacheKey]
		if c then
			if not c.done then
				local t0 = os.clock()
				while not optCache[cacheKey].done and os.clock() - t0 < 30 do task.wait(0.2) end
				local fc = optCache[cacheKey]
				return (fc and fc.done) and fc.list or {}
			end
			if not force and os.clock() - c.at < TTL_OPTIONS then return c.list end
		end
		optCache[cacheKey] = { done = false }
		local ok, list = pcall(getOptions)
		list = (ok and type(list) == "table") and list or {}
		if #list == 0 then
			-- GAK cache hasil kosong (join awal: data game belum siap). Cache
			-- kosong 5 menit = dropdown mati & retry cuma baca cache yang sama.
			if c and c.done and #c.list > 0 then
				optCache[cacheKey] = c
			else
				optCache[cacheKey] = { done = true, at = 0, list = {} }
			end
			return list
		end
		optCache[cacheKey] = { done = true, at = os.clock(), list = list }
		return list
	end

	-- Patch dropdown dist: constraint menu (bawaan 300x400 -> kapasitas rumus
	-- MenuWidth+52) + TextWrapped di Title opsi (dist gak set -> nama panjang
	-- kepotong). Harus dipanggil ulang tiap kali rows dibangun ulang (Refresh).
	local function patchDropdown(control)
		pcall(function()
			local mc = control.UIElements and control.UIElements.MenuCanvas
			local c = mc and mc:FindFirstChildOfClass("UISizeConstraint")
			if c then
				local maxH = 440
				-- Adaptive: dropdown di bawah layar dulu kepotong & scroll mentok
				-- (gak bisa kesampai) — clamp tinggi menu ke sisa ruang layar
				-- di bawah elemen. Min 140 biar search-bar tetap kesampai.
				pcall(function()
					local cam = workspace.CurrentCamera
					local vp = cam and cam.ViewportSize
					local ef = control.ElementFrame
					if ef and vp and vp.Y > 0 then
						local avail = vp.Y - (ef.AbsolutePosition.Y + ef.AbsoluteSize.Y) - 16
						if avail < maxH then maxH = math.max(140, math.floor(avail)) end
					end
				end)
				c.MaxSize = Vector2.new(292, maxH)
			end
		end)
		pcall(function()
			local sf = control.UIElements and control.UIElements.Menu
				and control.UIElements.Menu:FindFirstChild("Frame")
				and control.UIElements.Menu.Frame:FindFirstChild("ScrollingFrame")
			for _, opt in ipairs(sf and sf:GetChildren() or {}) do
				local tf = opt:FindFirstChild("Title", true)
				local tl = tf and tf:FindFirstChildOfClass("TextLabel")
				if tl then tl.TextWrapped = true end
			end
		end)
	end

	-- Isi rows via TABEL MENU langsung: Refresh dist bangun baris dari ARGUMEN
	-- dan nandain seleksi dari ap.Value milik menu (bukan element). Jangan
	-- andelin :Select — itu Refresh(ap.Values) dgn Values menu yang bisa beda
	-- table dari assignment ke element.
	-- (Fix "dropdown kosong pas reExec"): Semua fungsi menu library (Display/
	-- Refresh/Select) baca state dari table CONTROL (closure ap di library),
	-- BUKAN table menu -> restore harus nulis control.Value+control.Values.
	-- Serta: ekor Refresh() nembak Callback(ap.Value) & nimpa control.Values —
	-- refreshGate biar echo itu tidak dianggap klik user (gak nge-wipe set).
	local refreshGate = false
	local function dropdownFill(control, values, selected)
		control.Values = values
		control.Value = selected
		local menu = control.DropdownMenu or control
		menu.Values = values
		menu.Value = selected
		refreshGate = true
		pcall(function() menu:Refresh(values) end)
		refreshGate = false
		pcall(patchDropdown, control)
		return (values and #values) or 0
	end

	-- ponytail: prebuild rows di background pernah dicoba (anti-freeze klik) —
	-- DIBATALK: ribuan row instance hidup = FPS drop parah. Kembali lazy: click
	-- pertama ngehitch sekali (0.5-2s), sisanya instan & FPS aman. Upgrade path =
	-- list virtualisasi per-row di level library.

	-- Open hook: fillFn dipanggil TIAP menu dibuka (fillFn sendiri yang ngecek
	-- udah ke-build atau belum -> murah). Dulu cuma sekali, jadi "Update Pet
	-- List" harus rebuild semua dropdown langsung = freeze lama.
	-- dist ngebind klik ke <menuTabel>:Open() (bukan selalu table yang kita
	-- hold) -> hook dipasang di KEDUA sink: menu.Open & control.Open.
	local function lazyOpen(control, fillFn)
		local menu = control.DropdownMenu or control
		local function onOpen()
			pcall(fillFn)
		end
		local o1, o2 = menu.Open, control.Open
		menu.Open = function(self, ...)
			if o1 then pcall(o1, self, ...) end
			onOpen()
		end
		if control ~= menu and o2 then
			control.Open = function(self, ...)
				if o2 then pcall(o2, self, ...) end
				onOpen()
			end
		end
	end

	-- Single dropdown: opsi bisa string atau {name=, display=}; snapshot saat build
	-- + refresh() buat dipanggil ulang (WindUI Dropdown punya :Refresh).
	local function makeSingleW(parent, title, desc, getOptions, getv, setv, opts)
		opts = opts or {}
		local d2v, v2d = {}, {}
		-- WindUI menembak Callback() dengan Value konstruktur (echo kosong) tiap
		-- kali rows dibangun/refresh -> selalu-guard: echo PERTAMA (kosong) bukan
		-- pilihan user, jangan ditulis ke CFG (bisa nimpa saved value).
		local echoGuard = true
		local function snapshot()
			local opts, displays, selected = {}, {}, nil
			pcall(function()
				opts = getOptions() or {}
			end)
			table.clear(d2v); table.clear(v2d)
			local cur = getv()
			for _, o in ipairs(opts) do
				local d = (type(o) == "table") and (o.display or o.name) or o
				local v = (type(o) == "table") and (o.name or o.value) or o
				d2v[d] = v; v2d[v] = d
				displays[#displays + 1] = d
				if v == cur or d == cur then selected = d end
			end
			return displays, selected
		end
		local control
		local built = false
		local function fill()
			if built then return end
			built = true
			local displays, selected = snapshot()
			dropdownFill(control, displays, selected)
		end
		local dis0, sel0 = snapshot()
		control = parent:Dropdown({
			Title = title,
			Desc = desc,
			Values = {},
			Value = "",
			AllowNone = true,
			SearchBarEnabled = true,
			Callback = safe(function(d)
				if echoGuard then echoGuard = false; return end
				if refreshGate then return end -- ekor Refresh = echo, bukan klik
				setv(d2v[d] or d)
				persist()
			end),
		})
		-- Sinkron label tombol dgn saved value TANPA menunggu menu dibuka
		-- (WindUI cuma update label pas Display() dipanggil -> tanpa ini
		-- dropdown yang udah ke-restore tetap keliatan "--" = keliatan kosong).
		-- Sinkron label tombol dgn saved value TANPA menunggu menu dibuka.
		-- Tulis ke CONTROL.Value (sumber kebenaran library — Display/Refresh/
		-- Select baca dari control), bukan menu.Value (dulu: restore tetap
		-- tampak "--" walau data ke-load).
		pcall(function()
			control.Values = dis0
			control.Value = sel0 or ""
			control:Display()
		end)
		-- LAZY: baris dibangun SAAT MENU PERTAMA DIBUKA (menu kebuka instan,
		-- baris menyusul di thread sendiri). ponytail: open pertama list besar
		-- masih ngehitch — upgrade path = list virtualisasi.
		lazyOpen(control, fill)
		local function refresh()
			-- "Update Pet List": cuma tandain basi; rows dibangun ulang pas dibuka lagi.
			built = false
		end
		if opts.register and W.refreshers then
			W.refreshers[#W.refreshers + 1] = refresh
		end
		-- Warmer (no-UI): snapshot data doang buat pre-warm cache pas boot.
		if opts.register and W.ddWarmers then
			W.ddWarmers[#W.ddWarmers + 1] = function() pcall(snapshot) end
		end
		return control, refresh
	end

	-- Multi dropdown dinamis (pet team dll): opsi {value=, display=}, selSet keyed value.
	-- Tampilan: display dipecah "Nama | detail" -> opsi WindUI {Title=nama, Desc=detail},
	-- 2 baris, Desc TextWrapped bawaan dist -> nama pet SELALU kebaca utuh.
	-- SearchBarEnabled = search bawaan dist (filter Title, case-insensitive substring).
	-- MenuWidth 300 + patch UISizeConstraint (bawaan dist membatasi 300x400).
	-- Value/persist tetap keyed uuid (t.v) — bentuk state lama tidak berubah.
	local function makeMultiDynW(parent, title, desc, getOptions, selSet, onChange, opts)
		opts = opts or {}
		-- Reverse map display-title -> value uuid (isi tiap snapshot), buat
		-- normalisasi callback yang datang sebagai title string.
		local title2v = {}
		-- WindUI menembak Callback() (echo pilihan kosong) saat konstruksi & tiap
		-- Refresh rows. Echo pertama BUKAN input user -> di-skip, kalau tidak
		-- selSet ketimpa kosong lalu ke-persist (teams hilang pas reExec).
		local echoGuard = true
		local function splitDisplay(d)
			d = tostring(d or "")
			local cut = d:find(" | ", 1, true)
			if cut then return d:sub(1, cut - 1), d:sub(cut + 3) end
			return d, nil
		end
		local function snapshot(force)
			-- fetchOptions: cache+dedupe (GetData). force=true = tombol refresh
			-- eksplisit, lewatin cache. Cap opts.max: inventory GAG bisa ribuan
			-- pet -> Refresh dist bangun baris sinkron = freeze.
			local list = fetchOptions(opts.cacheKey, getOptions, force)
			local max = opts.max or 250
			local displays, selected = {}, {}
			table.clear(title2v)
			-- Yang ke-select DULUAN (cache dipakai bareng banyak dropdown, urutan
			-- aslinya ngikut dropdown lain) + biar nggak kepotong cap max.
			local ordered = {}
			for _, o in ipairs(list) do if selSet[o.value] then ordered[#ordered + 1] = o end end
			for _, o in ipairs(list) do if not selSet[o.value] then ordered[#ordered + 1] = o end end
			for i, o in ipairs(ordered) do
				if i > max then break end
				local t, rest = splitDisplay(o.display)
				displays[#displays + 1] = { Title = t, Desc = rest, v = o.value }
				title2v[t] = o.value
				if selSet[o.value] then selected[#selected + 1] = t end
			end
			return displays, selected, math.max(0, #list - max)
		end
		-- Values kosong saat build: snapshot (bisa nge-getData, first-call nunggu
		-- data game = freeze) dikerjakan task.spawn di bawah setelah window jadi.
		local control = parent:Dropdown({
			Title = title,
			Desc = desc,
			Values = {},
			Multi = true,
			AllowNone = true,
			SearchBarEnabled = true,
			MenuWidth = 240,
			Value = {},
			Callback = safe(function(sel)
				if echoGuard then echoGuard = false; return end
				-- Ekor Refresh() meng-echo Callback dgn Value saat itu — bukan
				-- klik user; tanpa gate ini set ketimpa & ke-persist kosong.
				if refreshGate then return end
				if type(sel) == "string" then sel = { sel } end
				-- Normalisasi dulu, baru wipe+isi: echo Refresh mengirim table
				-- opsi (ada .v), kadang title string. Tanpa ini, echo berisi
				-- title polos menghapus semua uuid dari selSet.
				local newSet = {}
				for _, t in ipairs(sel or {}) do
					local v
					if type(t) == "table" then
						v = t.v or t.value or (t.Title and title2v[t.Title]) or nil
					else
						v = title2v[t] or t
					end
					if v then newSet[v] = true end
				end
				for k in pairs(selSet) do selSet[k] = nil end
				for k in pairs(newSet) do selSet[k] = true end
				persist()
				if onChange then onChange() end
			end),
		})
		-- Constraint menu + wrap Title opsi ditangani patchDropdown() (module level)
		-- (local dideklarasi SEBELUM buildRows — dulu `built` di buildRows nulis global)
		local pendingDone, pending, built = false, nil, false
		local function buildRows(p)
			built = true
			dropdownFill(control, p.ds, p.sel2)
		end
		-- LAZY: baris dibangun pas menu pertama dibuka. Snapshot datanya sendiri
		-- jalan 0.5s setelah build di thread sendiri (fetchOptions = cukup 1x
		-- GetData), BARIS gak dibangun pas load/post-load = freeze scan habis.
		task.delay(0.5, function()
			pcall(function()
				local ds, sel2, extra = snapshot()
				-- Pas reExec, inventory game kadang belum siap (snapshot balik
				-- kosong & hasil kosong ke-cached 5s) -> jangan finalkan kosong;
				-- retry pelan SAMPAI isi muncul (cap 20s), kalau tidak label dan
				-- daftar mati kosong permanen sampai buka manual.
				local t0 = os.clock()
				while #ds == 0 and os.clock() - t0 < 20 do
					task.wait(1.5)
					ds, sel2, extra = snapshot()
				end
				pendingDone, pending = true, { ds = ds, sel2 = sel2, extra = extra }
				-- Label instan: restore keliatan tanpa harus buka dropdown
				-- (build rows tetap lazy sampai menu dibuka pertama kali).
				-- Tulis CONTROL.Value (baca komentar dropdownFill).
				pcall(function()
					control.Values = ds
					control.Value = sel2
					control:Display()
				end)
			end)
		end)
		local fillPending = false
		local function fill()
			-- Rows udah ke-pre-build pas boot (pre-warm)? Gak perlu rebuild.
			if built then return end
			-- GAK blocking jalur klik: menu kebuka INSTAN walau snapshot belum
			-- siap. Rows nanggung dibangun di thread sendiri begitu data datang
			-- (Refresh saat menu terbuka) — dulu: klik nunggu sampai 25s = freeze.
			if pendingDone then
				if pending then buildRows(pending) end
				return
			end
			if fillPending then return end
			fillPending = true
			task.spawn(function()
				local t0 = os.clock()
				while not pendingDone and os.clock() - t0 < 25 do task.wait(0.1) end
				fillPending = false
				if pending then buildRows(pending) end
			end)
		end
		lazyOpen(control, fill)
		local function refresh()
			-- Tombol "Update Pet List": JANGAN rebuild rows di sini (dulu rebuild
			-- semua dropdown x 250 row = freeze lama). Cukup ambil data baru di
			-- background (cache udah dikosongin addRefresh -> 1x GetData buat
			-- semua), update label, rows dibangun ulang pas dropdown dibuka lagi.
			built, pendingDone, pending = false, false, nil
			task.spawn(function()
				local ds, sel2, extra = snapshot()
				pendingDone, pending = true, { ds = ds, sel2 = sel2, extra = extra }
				pcall(function()
					control.Values = ds
					control.Value = sel2
					control:Display()
				end)
			end)
		end
		if opts.register then
			W.refreshers[#W.refreshers + 1] = refresh
		end
		return control, refresh
	end

	-- Multi dropdown statis (reg.PET_OPTIONS dll): opsi string, selSet keyed string.
	-- Rows di-defer: 4x dropdown dgn PET_OPTIONS penuh dibangun sinkron = freeze 53s.
	local function makeMultiW(parent, title, desc, options, selSet, onChange, opts)
		opts = opts or {}
		-- Echo-guard: Callback() pertama dari konstruktor bukan input user.
		local echoGuard = true
		local function savedTitles()
			local out = {}
			for _, o in ipairs(options) do
				if selSet[o] then out[#out + 1] = o end
			end
			return out
		end
		local control = parent:Dropdown({
			Title = title,
			Desc = desc,
			Values = {},
			Multi = true,
			AllowNone = true,
			SearchBarEnabled = true,
			MenuWidth = 240,
			Value = {},
			Callback = safe(function(sel)
				if echoGuard then echoGuard = false; return end
				if refreshGate then return end -- ekor Refresh = echo, bukan klik
				if type(sel) == "string" then sel = { sel } end
				for k in pairs(selSet) do selSet[k] = nil end
				for _, d in ipairs(sel or {}) do selSet[d] = true end
				persist()
				if onChange then onChange() end
			end),
		})
		-- Label instan biar saved selection kebaca tanpa buka menu.
		-- Label instan biar saved selection kebaca tanpa buka menu.
		-- Tulis ke CONTROL.Value (lihat komentar dropdownFill).
		pcall(function()
			control.Values = options
			control.Value = savedTitles()
			control:Display()
		end)
		-- LAZY: baris dibangun pas menu pertama dibuka — 4x PET_OPTIONS penuh
		-- dibangun sinkron (ctor/fill) = freeze berdetik; menu kebuka instan,
		-- baris menyusul. ponytail: open pertama list besar ngehitch sekali —
		-- upgrade path = list virtualisasi buat dropdown dist.
		local built = false
		local function fill()
			if built then return end
			built = true
			local n = dropdownFill(control, options, savedTitles())
			if ctx.log then
				ctx.log(("dropdown '%s' filled (%d options)"):format(title, n))
			end
		end
		lazyOpen(control, fill)
		return control
	end

	-- Section header polos: Box=false -> tanpa box; Opened=true -> konten langsung kebuka
	-- (default lib = Opened:false + tiap section dapat anak -> Expandable + chevron klik).
	-- Chevron dibunuh via polling: begitu muncul (Frame+ImageLabel di header), dipatikan.
	local function section(tab, title, opened)
		local sec = tab:Section({ Title = title, TextSize = 19, Opened = true })
	task.spawn(function()
		for _ = 1, 50 do
			pcall(function()
				local top = sec.ElementFrame.Outline.Top
				for _, ch in ipairs(top:GetChildren()) do
					if ch:IsA("Frame") and ch:FindFirstChildOfClass("ImageLabel") then
						ch.Visible = false
					end
				end
			end)
			task.wait(0.5)
		end
	end)
	return sec
end

-- Tombol "Update Pet List" (style Pet): jalankan semua refresher dropdown dinamis.
local function addRefresh(sec)
	sec:Button({
		Title = "Update Pet List",
		Desc = "Re-read the inventory and refresh dynamic dropdowns",
		Callback = safe(function()
			-- Kosongin cache sekali -> refresher pertama fetch, sisanya nunggu hasil
			-- yang sama (1x GetData). Rows nggak dibangun di sini -> nggak freeze.
			table.clear(optCache)
			for _, fn in ipairs(W.refreshers) do
				pcall(fn)
			end
			ctx.log("Pet list refreshed.")
			W.notify("Pet List", "Updated - dropdown baru kebaca pas dibuka")
		end),
	})
end

-- Mini-tab bar native (style Pet): [A][B][C...] di atas panel section.
-- Parent sama dgn card sections (ContainerFrame, padding halaman identik) ->
-- lebar bar PERSIS selebar cards. SortOrder kontainer = LayoutOrder + semua
-- element WindUI LayoutOrder 0 -> -1000 dipastikan row pertama.
-- Warna dari theme WindUI langsung (GetThemes), fallback konstanta Dark.
-- JANGAN baca Outline.BackgroundColor3: konstanta theme "Outline" = #FFFFFF,
-- ThemeTag-nya belum di-apply pas tab dibangun -> bar nyala putih.
local function miniBar(secs, order, defs, defaultId, rows)
	local container = secs[order[1]].ElementFrame.Parent
	local lib = W.windui
	local okTheme, cur = pcall(function()
		local th = lib and lib.GetThemes and lib:GetThemes() or nil
		local name = lib and lib.GetCurrentTheme and lib:GetCurrentTheme() or nil
		return th and name and th[name] or nil
	end)
	local bgc = (okTheme and cur and cur.Background) or Color3.fromRGB(16, 16, 16)
	local elc = (okTheme and cur and cur.ElementBackground) or Color3.fromRGB(42, 42, 44)
	local txth = (okTheme and cur and cur.Placeholder) or Color3.fromRGB(161, 161, 170)
	local pillBg = bgc:Lerp(elc, 0.30)
	local activeBg = elc:Lerp(Color3.new(1, 1, 1), 0.10)

	local bar = Instance.new("Frame")
	bar.Name = "MiniTabs"
	bar.LayoutOrder = -1000
	bar.Size = UDim2.new(1, 0, 0, 40)
	bar.BackgroundColor3 = pillBg
	bar.Parent = container
	Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 10)

	-- rows (opsional): pecah pill jadi R baris — {{a,b},{c}} -> 2 baris.
	-- order tetap list flat buat paint/unlock. Hatch: baris 1 = run config,
	-- baris 2 = rule config (biar gak berdesakan 5 pill sambung).
	local rowsDef = rows or { order }
	bar.Size = UDim2.new(1, 0, 0, (#rowsDef * 36) + ((#rowsDef - 1) * 4))
	local vstack = Instance.new("UIListLayout")
	vstack.FillDirection = Enum.FillDirection.Vertical
	vstack.Padding = UDim.new(0, 4)
	vstack.SortOrder = Enum.SortOrder.LayoutOrder
	vstack.VerticalAlignment = Enum.VerticalAlignment.Center
	vstack.Parent = bar

	local btns = {}
	local function paint(id, on)
		local b = btns[id]
		b.BackgroundColor3 = activeBg
		b.BackgroundTransparency = on and 0 or 1
		b.TextColor3 = on and ((cur and cur.Text) or Color3.fromRGB(255, 255, 255)) or txth
	end

	for ri, rlist in ipairs(rowsDef) do
		local rf = Instance.new("Frame")
		rf.Name = "MiniRow" .. ri
		rf.LayoutOrder = ri
		rf.Size = UDim2.new(1, 0, 0, 36)
		rf.BackgroundTransparency = 1
		rf.Parent = bar
		local hl = Instance.new("UIListLayout")
		hl.FillDirection = Enum.FillDirection.Horizontal
		hl.Padding = UDim.new(0, 6)
		hl.SortOrder = Enum.SortOrder.LayoutOrder
		hl.VerticalAlignment = Enum.VerticalAlignment.Center
		hl.Parent = rf
		for ci, id in ipairs(rlist) do
			local b = Instance.new("TextButton")
			b.Name = "Tab_" .. id
			b.LayoutOrder = ci
			b.Size = UDim2.new(1 / #rlist, -6, 0, 32)
			b.AutoButtonColor = false
			b.BackgroundTransparency = 1
			b.Text = defs[id].name
			b.TextTruncate = Enum.TextTruncate.AtEnd
			b.TextSize = 14
			b.Font = Enum.Font.GothamMedium
			Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
			b.Parent = rf
			btns[id] = b
		end
	end

	local function selectPanel(id)
		for pid, sec in pairs(secs) do
			pcall(function() sec.ElementFrame.Visible = (pid == id) end)
		end
		for _, pid in ipairs(order) do paint(pid, pid == id) end
	end
	for _, id in ipairs(order) do
		btns[id].Activated:Connect(function() selectPanel(id) end)
	end

	-- Ukuran section dist dipin manual (Open/Close = snapshot Top+Contentpx).
	-- Kalau pin kebaca sebelum layout jalan -> pin kecil -> konten ter-clip
	-- (panel "kosong"). Matikan mode expandable + force auto-size: section selalu
	-- sebesar konten, Open/Close dist jadi no-op permanen.
	local function unlockSize()
		for _, id in ipairs(order) do
			local s = secs[id]
			local ef = s and s.ElementFrame
			if ef and ef:FindFirstChild("Outline") then
				s.Expandable = false
				pcall(function()
					ef.AutomaticSize = Enum.AutomaticSize.Y
					ef.Size = UDim2.new(1, 0, 0, 0)
					ef.Outline.Content.Visible = true
				end)
			end
		end
	end
	task.defer(unlockSize)
	task.delay(0.15, unlockSize)

	selectPanel(defaultId)
end

	-- (hrow/HStack dibuang: element WindUI ngelewat padding halaman -> bar kepotong kanan)

	----------------------------------------------------------------- TAB: PET (Pickup V1 + Boost)
	local function buildPetTab(tab)
	-- Mini-tab [Pickup V1][Boost]: miniBar() — bar native beku + panel
	-- section auto-size (bukan HStack WindUI: element-nya ngelewat padding halaman).
	local DEFS = {
		v1    = { name = "Pickup V1" },
		boost = { name = "Boost" },
	}
	local ORDER = { "v1", "boost" }
	local secs = {}

	local function miniTab(id, buildFn)
		local sec = section(tab, DEFS[id].name)
		buildFn(sec)
		secs[id] = sec
	end

		--------------------------------------------------- panel 1: Pickup Pet V1
		miniTab("v1", function(sec)
			makeMultiDynW(sec, "Select Pets for Pickup [V1]",
				"Pick pets from your backpack (empty = every pet in the garden)",
				function() return ctx.inventoryPetOptions(CFG.pnpUuids) end,
				CFG.pnpUuids, function() persist() end,
				{ register = true, cacheKey = "inv_pets", fillDelay = 0.3, max = 250 })
			-- Timing V1 dikunci di modul (pickup 0.5 / equip 1E-20 / scan 0.20), nggak ada input.
			makeToggleW(sec, "Enable Automation Pickup V1",
				"Pickup right after the skill starts, re-place instantly.",
				function() return CFG.pnpEnabled end,
				function(v)
					CFG.pnpEnabled = v; persist()
					if v then
						if ctx.startPnpV1 then pcall(function() ctx.startPnpV1() end) end
					else
						if ctx.stopPnpV1 then pcall(function() ctx.stopPnpV1() end) end
					end
				end)
			addRefresh(sec)
		end)

		--------------------------------------------------- panel 2: Boost Pet
		miniTab("boost", function(sec)
			makeMultiDynW(sec, "Select Pets to Boost", "Pets to boost (active in the garden)",
				function() return ctx.inventoryPetOptions(CFG.boostPetUuids) end,
				CFG.boostPetUuids, function() persist() end,
				{ register = true, cacheKey = "inv_pets", fillDelay = 2.3, max = 250 })
			makeMultiDynW(sec, "Select Boost Items", "Boost items (Pet Toy) to use",
				function() return ctx.getBoostItemOptions(CFG.boostItemNames) end,
				CFG.boostItemNames, function() persist() end,
				{ register = true, cacheKey = "boost_items", fillDelay = 3.3, max = 250 })
			makeToggleW(sec, "Enable Automation Boost",
				"Auto apply boost items to pets, re-applies when the boost expires",
				function() return CFG.boostEnabled end,
				function(v)
					CFG.boostEnabled = v; persist()
					if v and ctx.startBoostPet then pcall(function() ctx.startBoostPet() end) end
				end)
			addRefresh(sec)
		end)

		miniBar(secs, ORDER, DEFS, "v1")
	end

	----------------------------------------------------------------- TAB: INVENTORY (Trade Ticket/Gift + Accept + Favorite)
	local function buildInventoryTab(tab)
		local idefs = {
			ticket = { name = "Trade Ticket" },
			gift   = { name = "Trade Gift" },
			accept = { name = "Auto Accept" },
			fav    = { name = "Favorite" },
		}
		local iorder = { "ticket", "gift", "accept", "fav" }
		local isecs = {}

		local function miniTab(id, buildFn)
			local sec = section(tab, idefs[id].name)
			buildFn(sec)
			isecs[id] = sec
		end

		local function playerOptions()
			local out = {}
			if ctx.getPlayers then
				pcall(function()
					for _, n in ipairs(ctx.getPlayers()) do out[#out + 1] = n end
				end)
			end
			return out
		end

		-- Status trade live: Paragraph :SetDesc (RichText tag warna dist).
		-- Mulai 3s setelah load + update hanya saat teks berubah — jangan bersaing
		-- dgn build window.
		local function addStatus(sec, isGift)
			local stat = sec:Paragraph({
				Title = isGift and "Gift Trade Status" or "Ticket Trade Status",
				Desc = "Completed: 0\nMatching pets: -\nStatus: IDLE",
			})
			task.spawn(function()
				task.wait(3)
				local last = ""
				while ctx.alive() do
					pcall(function()
						local avail = ctx.countMatchingPets and ctx.countMatchingPets(isGift) or 0
						local availCol = avail > 0 and "#5acc78" or "#dc5050"
						local active = isGift and CFG.tradeGiftEnabled or CFG.tradeTicketEnabled
						local methodRunning = ctx.state.tradeRunning
							and ((isGift and CFG.tradeMethod == "gift") or (not isGift and CFG.tradeMethod == "ticket"))
						local statusText = methodRunning and ctx.state.status
							or (active and "RUNNING" or "IDLE")
						local comp = methodRunning and (ctx.state.completed or 0) or 0
						local total = isGift and (CFG.giftTotalGifts or 0) or (CFG.totalTrades or 0)
						local unit = isGift and " gifts" or ""
						local txt = ("Completed: %d / %d%s\nMatching pets: <font color=\"%s\"><b>%d</b></font>\nStatus: %s")
							:format(comp, total, unit, availCol, avail, statusText)
						if txt ~= last then
							last = txt
							stat:SetDesc(txt)
						end
					end)
					task.wait(2)
				end
			end)
		end

		miniTab("ticket", function(sec)
			makeSingleW(sec, "Target Player", "Target player for ticket trades",
				playerOptions,
				function() return CFG.targetPlayer end,
				function(v) CFG.targetPlayer = v end, { register = true, fillDelay = 0.5 })
			makeMultiW(sec, "Pet Types to Trade", "Filter pets by type (empty = all non-favorite)",
				reg.PET_OPTIONS, CFG.petTypes, function() persist() end, { fillDelay = 1.1 })
			makeInputW(sec, "Weight Filter (KG)", "In-game display weight | 0=off | +6 = min 6kg | -6 = max 6kg",
				function() return CFG.weightFilter end,
				function(t) CFG.weightFilter = tonumber(t) or 0 end)
			makeInputW(sec, "Age Filter", "0 = off | +50 = min age 50 | -50 = max age 50",
				function() return CFG.ageFilter end,
				function(t) CFG.ageFilter = tonumber(t) or 0 end)
			makeInputW(sec, "Pets Per Trade", "Pets included in each trade",
				function() return CFG.petsPerTrade end,
				function(t)
					local n = tonumber(t)
					CFG.petsPerTrade = (n and n > 0) and math.floor(n) or 1
				end)
			makeInputW(sec, "Total Trades", "How many trades to run",
				function() return CFG.totalTrades end,
				function(t)
					local n = tonumber(t)
					CFG.totalTrades = (n and n >= 0) and math.floor(n) or 0
				end)
			makeToggleW(sec, "Auto Unfavorite [Trade]", "Remove favorite before trading",
				function() return CFG.autoUnfavorite end,
				function(v) CFG.autoUnfavorite = v end)
			addStatus(sec, false)
			makeToggleW(sec, "Enable Trade by Ticket", "Send a ticket trade request, fill pets, accept & confirm",
				function() return CFG.tradeTicketEnabled or (CFG.tradeEnabled and CFG.tradeMethod == "ticket") end,
				function(v)
					CFG.tradeTicketEnabled = v
					CFG.tradeEnabled = v
					if v then
						CFG.tradeGiftEnabled = false
						CFG.tradeMethod = "ticket"
						persist()
						ctx.state.completed = 0
						if ctx.startTrade then pcall(function() ctx.startTrade("ticket") end) end
					else
						persist()
						if CFG.tradeMethod == "ticket" and ctx.stopTrade then pcall(ctx.stopTrade) end
					end
				end)
			addRefresh(sec)
		end)

		miniTab("gift", function(sec)
			makeSingleW(sec, "Target Player", "Target player for gifts (defaults to the ticket target)",
				playerOptions,
				function() return (CFG.giftTargetPlayer ~= "" and CFG.giftTargetPlayer) or CFG.targetPlayer end,
				function(v) CFG.giftTargetPlayer = v end, { register = true, fillDelay = 0.8 })
			makeMultiW(sec, "Pet Types to Gift", "Filter pets by type (empty = all non-favorite)",
				reg.PET_OPTIONS, CFG.giftPetTypes, function() persist() end, { fillDelay = 1.4 })
			makeInputW(sec, "Weight Filter (KG)", "0=off | +6 = min 6kg | -6 = max 6kg",
				function() return CFG.giftWeightFilter end,
				function(t) CFG.giftWeightFilter = tonumber(t) or 0 end)
			makeInputW(sec, "Age Filter", "0=off | +50 = min age 50 | -50 = max age 50",
				function() return CFG.giftAgeFilter end,
				function(t) CFG.giftAgeFilter = tonumber(t) or 0 end)
			makeInputW(sec, "Pets Per Batch", "Pets gifted per round",
				function() return CFG.giftPetsPerBatch end,
				function(t)
					local n = tonumber(t)
					CFG.giftPetsPerBatch = (n and n > 0) and math.floor(n) or 1
				end)
			makeInputW(sec, "Total Gifts", "Pets/gifts to send before stopping",
				function() return CFG.giftTotalGifts end,
				function(t)
					local n = tonumber(t)
					CFG.giftTotalGifts = (n and n >= 0) and math.floor(n) or 0
				end)
			makeToggleW(sec, "Auto Unfavorite [Gift]", "Remove favorite before gifting",
				function() return CFG.giftAutoUnfavorite end,
				function(v) CFG.giftAutoUnfavorite = v end)
			addStatus(sec, true)
			makeToggleW(sec, "Enable Trade by Gift", "Send pet gifts directly without tickets (fast & automatic)",
				function() return CFG.tradeGiftEnabled or (CFG.tradeEnabled and CFG.tradeMethod == "gift") end,
				function(v)
					CFG.tradeGiftEnabled = v
					if v then
						CFG.tradeTicketEnabled = false
						CFG.tradeEnabled = false
						CFG.tradeMethod = "gift"
						persist()
						ctx.state.completed = 0
						if ctx.startTrade then pcall(function() ctx.startTrade("gift") end) end
					else
						persist()
						if CFG.tradeMethod == "gift" and ctx.stopTrade then pcall(ctx.stopTrade) end
					end
				end)
			addRefresh(sec)
		end)

		miniTab("accept", function(sec)
			makeToggleW(sec, "Automation Accept Gifts", "Auto accept incoming gifts",
				function() return CFG.acceptGifts end,
				function(v) CFG.acceptGifts = v end)
			makeToggleW(sec, "Automation Accept Trades", "Auto accept incoming trades",
				function() return CFG.acceptTrades end,
				function(v) CFG.acceptTrades = v end)
			addRefresh(sec)
		end)

		miniTab("fav", function(sec)
			makeToggleW(sec, "Auto Favourite Pets", "Auto favorite the selected pet types",
				function() return CFG.autoFavorite end,
				function(v)
					CFG.autoFavorite = v
					if ctx.startAutoFavorite and ctx.stopAutoFavorite then
						if v then pcall(ctx.startAutoFavorite)
						else pcall(ctx.stopAutoFavorite) end
					end
				end)
			makeMultiW(sec, "Favourite Pet Types", "Pet types to favorite",
				reg.PET_OPTIONS, CFG.favoritePetTypes, function() persist() end, { fillDelay = 1.7 })
			makeToggleW(sec, "Auto Unfavourite Pets", "Auto unfavorite the selected pet types",
				function() return CFG.autoUnfavoritePets end,
				function(v)
					CFG.autoUnfavoritePets = v
					if v and ctx.startAutoUnfavorite then pcall(ctx.startAutoUnfavorite)
					elseif ctx.stopAutoUnfavorite then pcall(ctx.stopAutoUnfavorite) end
				end)
			makeMultiW(sec, "Unfavourite Pet Types", "Pet types to unfavorite (empty = all pets)",
				reg.PET_OPTIONS, CFG.unfavoritePetTypes, function() persist() end, { fillDelay = 2.0 })
			addRefresh(sec)
		end)

		miniBar(isecs, iorder, idefs, "ticket")
	end

	----------------------------------------------------------------- TAB: FARM (Plants/Care/Shovel/Harvest)
	local function buildFarmTab(tab)
		local fdefs = {
			plants  = { name = "Plants" },
			care    = { name = "Care" },
			shovel  = { name = "Shovel" },
			harvest = { name = "Harvest" },
		}
		local forder = { "plants", "care", "shovel", "harvest" }
		local fsecs = {}

		local function miniTab(id, buildFn)
			local sec = section(tab, fdefs[id].name)
			buildFn(sec)
			fsecs[id] = sec
		end

		--------------------------------------------------- panel 1: Plants
		miniTab("plants", function(sec)
			makeMultiDynW(sec, "Select Seeds", "Pick seeds from the inventory (number = quantity).",
				function() return ctx.getPlantSeedOptions() end,
				CFG.plantSeedNames, function() persist() end,
				{ register = true, cacheKey = "inv_seeds", fillDelay = 0.3 })
			makeSingleW(sec, "Select Position", "Plant location. Good Position = tidy rows ordered left -> right.",
				function() return { "Random", "Player Position", "Good Position" } end,
				function() return CFG.plantPosition end,
				function(v) CFG.plantPosition = v end, { fillDelay = 0.5 })
			makeToggleW(sec, "Shovel Blocking Plants", "Good Position: shovel old plants blocking row cells so rows stay truly ordered without server-side shifting.",
				function() return CFG.goodClear ~= false end,
				function(v) CFG.goodClear = v; persist() end)
			makeInputW(sec, "Delay To Plants", "Extra delay (sec) per seed planted.",
				function() return tostring(CFG.plantDelay) end,
				function(t) CFG.plantDelay = tonumber(t) or 0 end)
			makeToggleW(sec, "Auto Plants Seed", "Auto plant the selected seeds.",
				function() return CFG.plantSeedEnabled end,
				function(v)
					CFG.plantSeedEnabled = v
					if v and ctx.startPlant then pcall(function() ctx.startPlant() end) end
				end)
			addRefresh(sec)
		end)

		--------------------------------------------------- panel 2: Care (Sprinkler + Sprinkler Shovel + Water)
		miniTab("care", function(sec)
			makeMultiDynW(sec, "Select Sprinkler", "Sprinklers to place (number = quantity).",
				function() return ctx.getSprinklerOptions() end,
				CFG.sprinklerNames, function() persist() end, { register = true, fillDelay = 0.6 })
			makeMultiDynW(sec, "Select Sprinkler Plants", "Place near these plants. Empty = use Position.",
				function() return ctx.getSprinklerPlantOptions() end,
				CFG.sprinklerPlantNames, function() persist() end, { register = true, fillDelay = 0.8 })
			makeSingleW(sec, "Select Sprinkler Position", "Place location when Plants is empty.",
				function() return { "Random", "Player Position" } end,
				function() return CFG.sprinklerPosition end,
				function(v) CFG.sprinklerPosition = v end, { fillDelay = 1.0 })
			makeInputW(sec, "Delay To Sprinkler", "Extra delay (sec) per placement.",
				function() return tostring(CFG.sprinklerDelay) end,
				function(t) CFG.sprinklerDelay = tonumber(t) or 0 end)
			makeToggleW(sec, "Auto Sprinkler", "Auto place the selected sprinklers.",
				function() return CFG.sprinklerEnabled end,
				function(v)
					CFG.sprinklerEnabled = v
					if v and ctx.startSprinkler then pcall(function() ctx.startSprinkler() end) end
				end)
			makeMultiDynW(sec, "Select Shovel Sprinkler", "Placed sprinklers to remove. 'All' = every sprinkler.",
				function() return ctx.getShovelSprinklerOptions() end,
				CFG.shovelSprinklerNames, function() persist() end, { register = true, fillDelay = 1.2 })
			makeInputW(sec, "Delay To Shovel Sprinkler", "Extra delay (sec) per removal.",
				function() return tostring(CFG.shovelSprinklerDelay) end,
				function(t) CFG.shovelSprinklerDelay = tonumber(t) or 0 end)
			makeToggleW(sec, "Auto Shovel Sprinkler", "Auto remove the selected sprinklers (equips the Shovel).",
				function() return CFG.shovelSprinklerEnabled end,
				function(v)
					CFG.shovelSprinklerEnabled = v
					if v and ctx.startShovelSprinkler then pcall(function() ctx.startShovelSprinkler() end) end
				end)
			makeMultiDynW(sec, "Select Water Fruits", "Pick fruits/plants to water. 'All' = everything.",
				function() return ctx.getWaterFruitOptions() end,
				CFG.waterFruitNames, function() persist() end, { register = true, fillDelay = 1.4 })
			makeInputW(sec, "Delay to Water", "Extra delay (sec) per watering cycle.",
				function() return tostring(CFG.waterDelay) end,
				function(t) CFG.waterDelay = tonumber(t) or 1 end)
			makeToggleW(sec, "Auto Water Fruits", "Auto water the selected fruits.",
				function() return CFG.waterEnabled end,
				function(v)
					CFG.waterEnabled = v
					if v and ctx.startWater then pcall(function() ctx.startWater() end) end
				end)
			addRefresh(sec)
		end)

		--------------------------------------------------- panel 3: Shovel (Tree + Fruits)
		miniTab("shovel", function(sec)
			makeMultiDynW(sec, "Select Tree", "Pick trees/plants to shovel. 'All' = everything.",
				function() return ctx.getShovelTreeOptions() end,
				CFG.shovelTreeNames, function() persist() end, { register = true, fillDelay = 1.6 })
			makeInputW(sec, "Delay To Shovel Tree", "Extra delay (sec) per shovel tree cycle.",
				function() return tostring(CFG.shovelTreeDelay) end,
				function(t) CFG.shovelTreeDelay = tonumber(t) or 0 end)
			makeToggleW(sec, "Auto Shovel Tree", "Auto shovel the selected trees/plants.",
				function() return CFG.shovelTreeEnabled end,
				function(v)
					CFG.shovelTreeEnabled = v
					if v and ctx.startShovelTree then pcall(function() ctx.startShovelTree() end) end
				end)
			makeMultiDynW(sec, "Select Shovel Fruits", "Fruit types to shovel. 'All' = everything.",
				function() return ctx.getShovelFruitOptions() end,
				CFG.shovelFruitNames, function() persist() end, { register = true, fillDelay = 1.8 })
			makeMultiDynW(sec, "Select Shovel Mutation", "Mutation filter. Empty/'All' = ignore.",
				function() return ctx.getShovelMutationOptions() end,
				CFG.shovelFruitMuts, function() persist() end, { register = true, fillDelay = 2.0 })
			makeMultiDynW(sec, "Select Shovel Variant", "Variant filter (Gold/Rainbow/etc). Empty/'All' = ignore.",
				function() return ctx.getShovelVariantOptions() end,
				CFG.shovelFruitVariants, function() persist() end, { register = true, fillDelay = 2.2 })
			makeSingleW(sec, "Select Shovel Threshold Mode", "How fruit weight is compared.",
				function() return ctx.getShovelModeOptions() end,
				function() return CFG.shovelFruitMode end,
				function(v) CFG.shovelFruitMode = v end, { fillDelay = 2.4 })
			makeInputW(sec, "Shovel Weight Threshold", "Enter '0' to skip this filter.",
				function() return tostring(CFG.shovelFruitWeight) end,
				function(t) CFG.shovelFruitWeight = tonumber(t) or 0 end)
			makeInputW(sec, "Delay To Shovel Fruit", "Extra delay (sec) per shovel fruit cycle.",
				function() return tostring(CFG.shovelFruitDelay) end,
				function(t) CFG.shovelFruitDelay = tonumber(t) or 0 end)
			makeToggleW(sec, "Auto Shovel Fruits", "Shovel plants whose fruits match the filter.",
				function() return CFG.shovelFruitEnabled end,
				function(v)
					CFG.shovelFruitEnabled = v
					if v and ctx.startShovelFruit then pcall(function() ctx.startShovelFruit() end) end
				end)
			addRefresh(sec)
		end)

		--------------------------------------------------- panel 4: Harvest (Collect + Favorite + Reclaimer)
		miniTab("harvest", function(sec)
			makeInputW(sec, "Delay To Collect", "Extra delay (sec) per collect cycle.",
				function() return tostring(CFG.collectDelay) end,
				function(t) CFG.collectDelay = tonumber(t) or 0 end)
			makeToggleW(sec, "Stop Collect If Backpack Is Full Max", "Stop collecting once the backpack is full.",
				function() return CFG.collectStopIfFull end,
				function(v) CFG.collectStopIfFull = v end)
			makeToggleW(sec, "Auto Sell Fruit If Backpack Full", "Sell all fruits once the backpack is full.",
				function() return CFG.collectAutoSellIfFull end,
				function(v) CFG.collectAutoSellIfFull = v end)
			makeMultiDynW(sec, "Select Whitelist Fruit", "Pick fruit types to collect.",
				function() return ctx.getCollectFruitOptions() end,
				CFG.collectWlFruitNames, function() persist() end,
				{ register = true, cacheKey = "collect_fruits", fillDelay = 2.6 })
			makeToggleW(sec, "Auto Collect Whitelisted Fruits", "Collect only whitelisted fruit types.",
				function() return CFG.collectWlFruitEnabled end,
				function(v)
					CFG.collectWlFruitEnabled = v
					if v and ctx.startCollect then pcall(function() ctx.startCollect() end) end
				end)
			makeMultiDynW(sec, "Select Whitelist Mutations", "Pick mutations to collect.",
				function() return ctx.getCollectMutationOptions() end,
				CFG.collectWlMutNames, function() persist() end, { register = true, fillDelay = 2.8 })
			makeToggleW(sec, "Auto Collect Whitelisted Mutations", "Collect only fruits with whitelisted mutations.",
				function() return CFG.collectWlMutEnabled end,
				function(v)
					CFG.collectWlMutEnabled = v
					if v and ctx.startCollect then pcall(function() ctx.startCollect() end) end
				end)
			makeMultiDynW(sec, "Select Combined Fruits", "Filter by fruit type.",
				function() return ctx.getCollectFruitOptions() end,
				CFG.collectCombFruitNames, function() persist() end,
				{ register = true, cacheKey = "collect_fruits", fillDelay = 3.0 })
			makeMultiDynW(sec, "Select Combined Mutation", "Filter by mutation type.",
				function() return ctx.getCollectMutationOptions() end,
				CFG.collectCombMutNames, function() persist() end, { register = true, fillDelay = 3.2 })
			makeMultiDynW(sec, "Select Combined Variant", "Filter by variant type.",
				function() return ctx.getCollectVariantOptions() end,
				CFG.collectCombVariants, function() persist() end, { register = true, fillDelay = 3.4 })
			makeSingleW(sec, "Whitelist Weight Mode", "How fruit weight is compared.",
				function() return ctx.getCollectModeOptions() end,
				function() return CFG.collectCombMode end,
				function(v) CFG.collectCombMode = v end, { fillDelay = 3.6 })
			makeInputW(sec, "Whitelist Weight", "Enter '0' to skip this filter.",
				function() return tostring(CFG.collectCombWeight) end,
				function(t) CFG.collectCombWeight = tonumber(t) or 0 end)
			makeToggleW(sec, "Auto Collect Fruits", "Collect fruits matching ALL combined criteria.",
				function() return CFG.collectCombEnabled end,
				function(v)
					CFG.collectCombEnabled = v
					if v and ctx.startCollect then pcall(function() ctx.startCollect() end) end
				end)
			makeMultiDynW(sec, "Select Fruits [Fav]", "Garden fruit types to favorite (empty = any).",
				function() return ctx.getFavFruitOptions() end,
				CFG.favFruitNames, function() persist() end, { register = true, fillDelay = 3.8 })
			makeMultiDynW(sec, "Filter Mutations [Fav]", "Required mutations (empty = any mutation counts).",
				function() return ctx.getFavMutationOptions() end,
				CFG.favMutNames, function() persist() end, { register = true, fillDelay = 4.0 })
			makeSingleW(sec, "Weight Mode [Fav]", "Fruit weight comparison (empty = off).",
				function() return ctx.getFavModeOptions() end,
				function() return CFG.favMode end,
				function(v) CFG.favMode = v end, { fillDelay = 4.2 })
			makeInputW(sec, "Weight Value [Fav]", "Weight threshold (0 = off).",
				function() return tostring(CFG.favWeight) end,
				function(t) CFG.favWeight = tonumber(t) or 0 end)
			makeInputW(sec, "Delay To Favorite", "Seconds per favorite scan cycle.",
				function() return tostring(CFG.favDelay) end,
				function(t) CFG.favDelay = tonumber(t) or 1 end)
			makeToggleW(sec, "Auto Favorite Fruits", "Favorite garden fruits matching the filter.",
				function() return CFG.favEnabled end,
				function(v)
					CFG.favEnabled = v
					if v and ctx.startFavorite then pcall(function() ctx.startFavorite() end) end
				end)
			makeToggleW(sec, "Auto Unfavorite Fruits", "Unfavorite garden fruits matching the filter.",
				function() return CFG.unfavEnabled end,
				function(v)
					CFG.unfavEnabled = v
					if v and ctx.startFavorite then pcall(function() ctx.startFavorite() end) end
				end)
			makeMultiDynW(sec, "Select Plants [Reclaim]", "Pick plants to reclaim. 'All' = everything.",
				function() return ctx.getReclaimPlantOptions() end,
				CFG.reclaimPlantNames, function() persist() end, { register = true, fillDelay = 4.4 })
			makeToggleW(sec, "Auto Reclaimer Plants", "Auto reclaim the selected plants with the Reclaimer tool",
				function() return CFG.reclaimEnabled end,
				function(v)
					CFG.reclaimEnabled = v
					if v and ctx.startReclaim then pcall(function() ctx.startReclaim() end) end
				end)
			addRefresh(sec)
		end)

		miniBar(fsecs, forder, fdefs, "plants")
	end

	----------------------------------------------------------------- TAB: HATCH (Auto Hatch + Auto Sell)
	local function buildHatchTab(tab)
		local hdefs = {
			ctrl   = { name = "Status & Control" },
			teams  = { name = "Teams" },
			eggs   = { name = "Egg Configuration" },
			bronto = { name = "Bronto Configuration" },
			sell   = { name = "Sell Configuration" },
		}
		local horder = { "ctrl", "teams", "eggs", "bronto", "sell" }
		local hsecs = {}
		local function miniTab(id, buildFn)
			local sec = section(tab, hdefs[id].name)
			buildFn(sec)
			hsecs[id] = sec
		end

		--------------------------------------------------- panel 1: Status & Control
		miniTab("ctrl", function(sec)
			-- Live status lengkap (style SRC lama): status, phase, team, bp,
			-- egg tracking, placed, hatched, sell cycle, recovery stat (2s).
			local stat = sec:Paragraph({
				Title = "Live Status",
				Desc = "Status: -",
			})
			task.spawn(function()
				task.wait(3)
				local last = ""
				while ctx.alive() do
					pcall(function()
						local s = ctx.getHatchSummary and ctx.getHatchSummary()
						if s then
							local proc = s.proc or {}
							local txt = table.concat({
								("Status: %s   |   Phase: %s"):format(tostring(s.status or "-"), tostring(s.phase or "-")),
								("Backpack: %s / %s"):format(tostring(s.backpack or 0), tostring(s.maxBackpack or 0)),
								("Egg: %s"):format(tostring(s.currentEgg or "-")),
								("   Before: %s  ->  Now: %s"):format(
									tostring(s.eggBefore or 0), tostring(s.currentAmount or 0)),
								("Placed: %s / %s   |   Ready: %s"):format(
									tostring(s.placed or 0), tostring(s.maxPlaced or 0), tostring(s.ready or 0)),
								("Hatched: %s   |   Sell Cycle: %s / %s   (%s)"):format(
									tostring(s.eggsHatched or 0), tostring(s.cycleProg or 0), tostring(s.cycleTarget or 0), tostring(s.sellMode or "-")),
								("Recovery: Koi %s (%s%%)  |  Seal %s (%s%%)"):format(
									tostring(proc.koiCount or 0), tostring(proc.koiPct or 0),
									tostring(proc.sealCount or 0), tostring(proc.sealPct or 0)),
							}, "\n")
							if txt ~= last then last = txt; stat:SetDesc(txt) end
						end
					end)
					task.wait(2.0)
				end
			end)

			-- Master toggle = pengganti Start/Stop bar; handleInventoryFull
			-- memanggil ctx.ui.rHatchToggle pas Auto Hatch distop (Invent Max).
			local masterCtrl = makeToggleW(sec, "Enable Auto Hatch",
				"Auto place eggs, hatch (Core/Hatch/Bronto teams), and sell per your config.",
				function() return CFG.hatchEnabled end,
				function(v)
					-- WAJIB set flag dulu: loop hatch while CFG.hatchEnabled —
					-- tanpa ini loop mati instan & toggle snap balik ke OFF.
					CFG.hatchEnabled = v
					if v then
						if ctx.startHatch then pcall(function() ctx.startHatch() end) end
					else
						if ctx.stopHatch then pcall(function() ctx.stopHatch() end) end
						if not CFG.hatchRejoinMinusEnabled and not CFG.hatchRejoinPlusEnabled and ctx.stopEggMinusWatcher then
							pcall(function() ctx.stopEggMinusWatcher() end)
						end
					end
				end)
			ctx.ui.rHatchToggle = function()
				pcall(function() masterCtrl:Set(CFG.hatchEnabled) end)
			end
			makeToggleW(sec, "Auto GM Sprinkler",
				"Keep a Grandmaster Sprinkler placed — re-places when it's about to expire (lasts ~10 min).",
				function() return CFG.gmSprinklerEnabled end,
				function(v)
					CFG.gmSprinklerEnabled = v
					if v then
						if ctx.startGmSprinkler then pcall(function() ctx.startGmSprinkler() end) end
					else
						if ctx.stopGmSprinkler then pcall(function() ctx.stopGmSprinkler() end) end
					end
					persist()
				end)
			makeToggleW(sec, "Auto Sell Pets", "Auto sell backpack pets per your settings.",
				function() return CFG.autoSellEnabled end,
				function(v) CFG.autoSellEnabled = v end)
		end)

		--------------------------------------------------- panel 2: Teams
		miniTab("teams", function(sec)
			makeMultiDynW(sec, "Core Team", "Percepat egg (incubation speed)",
				function() return ctx.inventoryPetOptions(CFG.hatchCoreTeam) end,
				CFG.hatchCoreTeam, function() persist() end,
				{ register = true, cacheKey = "inv_pets", fillDelay = 0.2, max = 250 })
			makeInputW(sec, "Core Equip Delay (sec)", "Delay between pets while equipping the Core team",
				function() return tostring(CFG.hatchCoreEquipDelay or 0) end,
				function(t) CFG.hatchCoreEquipDelay = tonumber(t) or 0 end)
			makeInputW(sec, "Core Unequip Delay (sec)", "Delay between pets while unequipping the Core team",
				function() return tostring(CFG.hatchCoreUnequipDelay or 1) end,
				function(t) CFG.hatchCoreUnequipDelay = tonumber(t) or 1 end)

			makeMultiDynW(sec, "Hatch Team", "Hatch ready eggs (Koi = refunds the egg)",
				function() return ctx.inventoryPetOptions(CFG.hatchHatchTeam) end,
				CFG.hatchHatchTeam, function() persist() end,
				{ register = true, cacheKey = "inv_pets", fillDelay = 0.4, max = 250 })
			makeInputW(sec, "Hatch Equip Delay (sec)", "Delay between pets while equipping the Hatch team",
				function() return tostring(CFG.hatchTeamEquipDelay or 0) end,
				function(t) CFG.hatchTeamEquipDelay = tonumber(t) or 0 end)
			makeInputW(sec, "Hatch Unequip Delay (sec)", "Delay between pets while unequipping the Hatch team",
				function() return tostring(CFG.hatchTeamUnequipDelay or 1) end,
				function(t) CFG.hatchTeamUnequipDelay = tonumber(t) or 1 end)
			makeInputW(sec, "Hatch Team Delay (sec)", "Wait after the team swap before hatching",
				function() return tostring(CFG.hatchTeamDelay or 5.5) end,
				function(t) CFG.hatchTeamDelay = tonumber(t) or 5.5 end)

			makeMultiDynW(sec, "Bronto Team", "+30% pet weight while hatching (Brontosaurus)",
				function() return ctx.inventoryPetOptions(CFG.hatchBrontoTeam) end,
				CFG.hatchBrontoTeam, function() persist() end,
				{ register = true, cacheKey = "inv_pets", fillDelay = 0.6, max = 250 })
			makeInputW(sec, "Bronto Equip Delay (sec)", "Delay between pets while equipping the Bronto team",
				function() return tostring(CFG.hatchBrontoEquipDelay or 0) end,
				function(t) CFG.hatchBrontoEquipDelay = tonumber(t) or 0 end)
			makeInputW(sec, "Bronto Unequip Delay (sec)", "Delay between pets while unequipping the Bronto team",
				function() return tostring(CFG.hatchBrontoUnequipDelay or 1) end,
				function(t) CFG.hatchBrontoUnequipDelay = tonumber(t) or 1 end)
			makeInputW(sec, "Bronto Team Delay (sec)", "Wait after the team swap before the Bronto hatch",
				function() return tostring(CFG.brontoTeamDelay or 5.5) end,
				function(t) CFG.brontoTeamDelay = tonumber(t) or 5.5 end)

			makeMultiDynW(sec, "Sell Team", "Sell + convert pets back into eggs (Seal the Deal)",
				function() return ctx.inventoryPetOptions(CFG.hatchSellTeam) end,
				CFG.hatchSellTeam, function() persist() end,
				{ register = true, cacheKey = "inv_pets", fillDelay = 0.8, max = 250 })
			makeInputW(sec, "Sell Equip Delay (sec)", "Delay between pets while equipping the Sell team",
				function() return tostring(CFG.hatchSellEquipDelay or 0) end,
				function(t) CFG.hatchSellEquipDelay = tonumber(t) or 0 end)
			makeInputW(sec, "Sell Unequip Delay (sec)", "Delay between pets while unequipping the Sell team",
				function() return tostring(CFG.hatchSellUnequipDelay or 1) end,
				function(t) CFG.hatchSellUnequipDelay = tonumber(t) or 1 end)
			makeInputW(sec, "Sell Team Delay (sec)", "Wait after the team swap before selling",
				function() return tostring(CFG.sellTeamDelay or 5.5) end,
				function(t) CFG.sellTeamDelay = tonumber(t) or 5.5 end)
			addRefresh(sec)
		end)

		--------------------------------------------------- panel 3: Egg Configuration
		miniTab("eggs", function(sec)
			makeSingleW(sec, "Egg to Hatch", "Eggs from the backpack (number = quantity).",
				function() return ctx.getEggBackpackOptions() end,
				function() return tostring(CFG.hatchEggName or "") end,
				function(v) if v ~= "" then CFG.hatchEggName = v end end,
				{ register = true, fillDelay = 1.8 })
			makeSingleW(sec, "Placement Pattern", "Grid = tidy rows, Random = scattered.",
				function() return { "Grid", "Random" } end,
				function() return CFG.hatchPlacePattern or "Grid" end,
				function(v) CFG.hatchPlacePattern = (v == "Random") and "Random" or "Grid" end, { fillDelay = 2.0 })
			makeInputW(sec, "Max Placed", "Maximum eggs placed in the garden.",
				function() return tostring(CFG.hatchMaxPlaced or 8) end,
				function(t) CFG.hatchMaxPlaced = math.max(1, tonumber(t) or 8) end)

			makeToggleW(sec, "Auto Rejoin on Egg Minus", "Rejoin the server once the egg deficit hits the threshold.",
				function() return CFG.hatchRejoinMinusEnabled end,
				function(v)
					CFG.hatchRejoinMinusEnabled = v
					if v and ctx.startEggMinusWatcher then pcall(function() ctx.startEggMinusWatcher() end) end
					if not v and not CFG.hatchRejoinPlusEnabled and ctx.stopEggMinusWatcher then
						pcall(function() ctx.stopEggMinusWatcher() end)
					end
				end)
			makeInputW(sec, "Egg Minus Threshold", "Deficit that triggers the rejoin (e.g. 20).",
				function() return tostring(CFG.hatchRejoinMinusThreshold or 20) end,
				function(t) CFG.hatchRejoinMinusThreshold = tonumber(t) or 20 end)
			makeToggleW(sec, "Auto Rejoin on Egg Plus", "Rejoin the server once the egg surplus hits the threshold.",
				function() return CFG.hatchRejoinPlusEnabled end,
				function(v)
					CFG.hatchRejoinPlusEnabled = v
					if v and ctx.startEggMinusWatcher then pcall(function() ctx.startEggMinusWatcher() end) end
					if not v and not CFG.hatchRejoinMinusEnabled and ctx.stopEggMinusWatcher then
						pcall(function() ctx.stopEggMinusWatcher() end)
					end
				end)
			makeInputW(sec, "Egg Plus Threshold", "Surplus that triggers the rejoin (e.g. 20).",
				function() return tostring(CFG.hatchRejoinPlusThreshold or 20) end,
				function(t) CFG.hatchRejoinPlusThreshold = tonumber(t) or 20 end)
			makeInputW(sec, "Hatch Webhook URL", "Webhook alert for bronto/special eggs (empty = off).",
				function() return tostring(CFG.hatchWebhookUrl or "") end,
				function(t) CFG.hatchWebhookUrl = tostring(t or "") end)
			addRefresh(sec)
		end)

		--------------------------------------------------- panel 4: Bronto Configuration
		miniTab("bronto", function(sec)
			sec:Paragraph({
				Title = "Sell & Bronto Rule (Bulk)",
				Desc = "Weight < KG -> action (SELL/KEEP). Weight >= KG -> KEEP + BRONTO (hatched with the Bronto team). Mark ★ Special = always Bronto + alert.",
			})

			-- Bulk editor: per-pet rule terpadu (dipakai sell & bronto).
			local bulkSel, bulkKg, bulkAction, bulkSpecial = {}, 0.8, "sell", false
			makeMultiW(sec, "Select Pet Types (Bulk)", "Select multiple pet types at once",
				reg.PET_OPTIONS, bulkSel, function() persist() end, { fillDelay = 1.0 })
			makeInputW(sec, "KG (Bulk)", "Weight threshold for the selected pets",
				function() return tostring(bulkKg) end,
				function(t) bulkKg = tonumber(t) or 0.8 end)
			makeSingleW(sec, "Below KG Action (Bulk)", "Action when weight is below the threshold",
				function() return { "sell", "keep" } end,
				function() return bulkAction end,
				function(v) bulkAction = (v == "keep") and "keep" or "sell" end, { fillDelay = 1.1 })
			makeToggleW(sec, "Special Pet (Bulk)", "Mark the selected pets as Special (★ alert & Bronto).",
				function() return bulkSpecial end,
				function(v) bulkSpecial = v end)

			local remVal, remRefresh = nil, nil
			sec:Button({
				Title = "APPLY BULK LIST",
				Desc = "Apply the rules above to all selected pets (overwrites existing rules).",
				Callback = safe(function()
					CFG.hatchSellList = CFG.hatchSellList or {}
					local n = 0
					for name in pairs(bulkSel) do
						CFG.hatchSellList[name] = {
							kg = tonumber(bulkKg) or 0.8,
							action = (bulkAction == "keep") and "KEEP" or "SELL",
							special = bulkSpecial == true,
						}
						n = n + 1
					end
					if n > 0 then
						persist()
						ctx.log(("Hatch: %d bulk rules applied"):format(n))
						if remRefresh then pcall(remRefresh) end
						W.notify("Hatch", n .. " rules applied")
					end
				end),
			})

			remCtrl, remRefresh = makeSingleW(sec, "Pick Rule to Remove",
				"Rules listed in the Sell & Bronto Config.",
				function()
					local list = {}
					for k in pairs(CFG.hatchSellList or {}) do list[#list + 1] = k end
					table.sort(list)
					return list
				end,
				function() return remVal end,
				function(v) remVal = v end, { register = true, fillDelay = 1.2 })

			sec:Button({
				Title = "Remove Selected Rule",
				Desc = "Delete the pet rule selected in the dropdown above.",
				Callback = safe(function()
					if remVal and CFG.hatchSellList then
						CFG.hatchSellList[remVal] = nil
						remVal = nil
						persist()
						if remRefresh then pcall(remRefresh) end
						ctx.log("Hatch: rule removed")
					end
				end),
			})

			sec:Button({
				Title = "CLEAR ALL RULES",
				Desc = "Delete ALL Sell & Bronto rules.",
				Callback = safe(function()
					CFG.hatchSellList = {}
					persist()
					if remRefresh then pcall(remRefresh) end
					ctx.log("Hatch: all rules removed")
				end),
			})

			makeToggleW(sec, "Don't Hatch Special Pets", "Skip special pets entirely (never hatch them).",
				function() return CFG.brontoSkipSpecial end,
				function(v) CFG.brontoSkipSpecial = v end)
			addRefresh(sec)
		end)

		--------------------------------------------------- panel 5: Sell Configuration
		miniTab("sell", function(sec)
			makeMultiW(sec, "Pets to Sell", "Pet types TO SELL (the rest get favorited for safety)",
				reg.PET_OPTIONS, CFG.sellPetTypes, function() persist() end, { fillDelay = 1.0 })
			makeInputW(sec, "Sell Weight Threshold", "Sell when weight is below this (0 = off)",
				function() return tostring(CFG.sellWeightThreshold or 0) end,
				function(t) CFG.sellWeightThreshold = tonumber(t) or 0 end)
			makeInputW(sec, "Sell Age Threshold", "Sell when age is below this (0 = off)",
				function() return tostring(CFG.sellAgeThreshold or 0) end,
				function(t) CFG.sellAgeThreshold = tonumber(t) or 0 end)
			makeMultiW(sec, "Special Pets to Sell", "Special pets (sold by weight)",
				reg.PET_EGG_ONLY, CFG.sellSpecialTypes, function() persist() end, { fillDelay = 1.1 })
			makeInputW(sec, "Special Pet Weight Threshold", "Sell special pets with weight below this (0 = off)",
				function() return tostring(CFG.sellSpecialWeight or 0) end,
				function(t) CFG.sellSpecialWeight = tonumber(t) or 0 end)

			sec:Paragraph({
				Title = "Trigger & Execution",
				Desc = "When selling runs and how.",
			})
			makeSingleW(sec, "Sell Trigger", "Cycle = sell every N hatch cycles. Backpack = sell once pets reach the limit.",
				function() return { "Cycle", "Backpack" } end,
				function() return CFG.sellMode or "Cycle" end,
				function(v) CFG.sellMode = (v == "Backpack") and "Backpack" or "Cycle" end, { fillDelay = 1.2 })
			makeInputW(sec, "Sell Every N Cycles", "Used when Sell Trigger = Cycle.",
				function() return tostring(CFG.sellEveryNCycles or 1) end,
				function(t) CFG.sellEveryNCycles = math.max(1, tonumber(t) or 1) end)
			makeInputW(sec, "Auto Sell At Total Pets", "Used when Sell Trigger = Backpack.",
				function() return tostring(CFG.sellWhenReach or 100) end,
				function(t) CFG.sellWhenReach = tonumber(t) or 100 end)
			makeSingleW(sec, "Sell Style", "One by One = sell only matching pets (safe). All at Once = sell every matching non-favorited pet.",
				function() return { "One by One", "All at Once" } end,
				function() return CFG.sellStyle or "All at Once" end,
				function(v) CFG.sellStyle = (v == "One by One") and "One by One" or "All at Once" end, { fillDelay = 1.3 })
			makeToggleW(sec, "Auto Boost Before Sell", "Boost active pets with toys before selling",
				function() return CFG.autoBoostBeforeSell end,
				function(v) CFG.autoBoostBeforeSell = v end)
			sec:Button({
				Title = "Sell Now (manual)", Desc = "Run the sell process once, right now.",
				Callback = safe(function()
					if ctx.hatchDoSell then task.spawn(function() pcall(ctx.hatchDoSell) end) end
				end),
			})
			addRefresh(sec)
		end)

		-- 2 baris: atas = Status/Teams/Egg (run), bawah = Sell/Bronto (rule)
		miniBar(hsecs, horder, hdefs, "ctrl", { { "ctrl", "teams", "eggs" }, { "sell", "bronto" } })
	end

	----------------------------------------------------------------- live status helper (dipakai Elephant & Leveling)
	-- Paragraph tipu + loop SetDesc kala teks berubah (pola addStatus di INVENTORY
	-- tapi generic). Cache teks terakhir biar gak bersaing dgn layout dist.
	local function liveStatus(sec, title, getTxt, interval)
		local stat = sec:Paragraph({ Title = title, Desc = "Loading stats..." })
		task.spawn(function()
			task.wait(3)
			local last = ""
			while ctx.alive() do
				pcall(function()
					local txt = getTxt()
					if txt and txt ~= last and txt ~= "" then
						last = txt
						stat:SetDesc(txt)
					end
				end)
				task.wait(interval or 1.5)
			end
		end)
	end

	----------------------------------------------------------------- TAB: ELEPHANT (V1 + V2 Swap 40)
	local function buildElephantTab(tab)
		local edefs = {
			v1 = { name = "Elephant V1" },
			v2 = { name = "Elephant V2 (Swap 40)" },
		}
		local eorder = { "v1", "v2" }
		local esecs = {}

		local function miniTab(id, buildFn)
			local sec = section(tab, edefs[id].name)
			buildFn(sec)
			esecs[id] = sec
		end

		-- panel 1: Automation Elephant V1 (penempatan = garden Elephant V1)
		miniTab("v1", function(sec)
			liveStatus(sec, "Elephant V1 Status", function()
				local ok, s = pcall(function() return ctx.getElephantSummary() end)
				if not ok or not s then return nil end
				local col = s.status == "ACTIVE" and "#5acc78" or "#dc5050"
				return ("Automation Status: <font color=\"%s\"><b>%s</b></font>\n\n" ..
					"Elephant Team: <font color=\"#8c929e\">%s</font>\n" ..
					"Target Types: <font color=\"#f5c82d\">%s</font>\n" ..
					"Target Pets Ready: <font color=\"#8c929e\">%s</font>\n" ..
					"Pets at Max KG: <font color=\"#8c929e\">%s</font>\n\n" ..
					"Max Target Pets: <font color=\"#8c929e\">%s</font>\n" ..
					"Target Weight: <font color=\"#f5c82d\"><b>%s</b></font>")
					:format(col, s.status, s.team, s.types, s.ready, s.maxKg, s.maxTarget, s.targetWeight)
			end, 1.5)
			makeMultiDynW(sec, "V1 Pet Team", "Select elephant pet team (stays in the garden)",
				function() return ctx.inventoryPetOptions(CFG.elephantTeamUuids) end,
				CFG.elephantTeamUuids, function() persist() end,
				{ register = true, cacheKey = "inv_pets", fillDelay = 0.4, max = 250 })
			makeMultiW(sec, "V1 Target Pet Types", "Select pet types to auto-elephant (all pets in game)",
				reg.PET_OPTIONS, CFG.elephantPetTypes, function() persist() end,
				{ fillDelay = 0.8 })
			makeInputW(sec, "Target Weight (KG)", "Release pets at this weight — ANY value, decimals OK (e.g. 3.5, 4.7, 6.2). No presets.",
				function() return CFG.elephantTargetWeight end,
				function(t) CFG.elephantTargetWeight = tonumber(t) or 5.5 end)
			makeToggleW(sec, "Enable Automation Elephant",
				"Rotate target pets automatically. OFF = removes all target pets from the garden.",
				function() return CFG.elephantEnabled end,
				function(v)
					CFG.elephantEnabled = v; persist()
					if v then
						if ctx.startElephant then pcall(function() ctx.startElephant() end) end
					else
						if ctx.stopElephant then pcall(function() ctx.stopElephant() end) end
					end
				end)
			addRefresh(sec)
		end)

		-- panel 2: Automation Elephant V2 (swap gajah di trigger level)
		miniTab("v2", function(sec)
			liveStatus(sec, "Elephant V2 Status", function()
				local ok, s = pcall(function() return ctx.getElephantV2Summary() end)
				if not ok or not s then return nil end
				local col = s.status == "ACTIVE" and "#5acc78" or "#dc5050"
				return ("Automation Status: <font color=\"%s\"><b>%s</b></font>  |  <font color=\"#f5c82d\">%s</font>\n\n" ..
					"Elephant Team: <font color=\"#8c929e\">%s</font>\n" ..
					"Target Types: <font color=\"#f5c82d\">%s</font>\n" ..
					"Target Pets Ready: <font color=\"#8c929e\">%s</font>\n" ..
					"Pets at Max KG: <font color=\"#8c929e\">%s</font>\n" ..
					"Max Target Pets: <font color=\"#8c929e\">%s</font>  |  Target Weight: <font color=\"#f5c82d\"><b>%s</b></font>\n\n" ..
					"Elephant: <font color=\"#8c929e\">%s</font>\n" ..
					"Switch: <font color=\"#8c929e\">%s</font>\n" ..
					"Elephant enters at target Age >= <font color=\"#f5c82d\"><b>%s</b></font>")
					:format(col, s.status, tostring(s.info), s.team, s.types, s.ready, s.maxKg,
						s.maxTarget, s.targetWeight, s.gajah, s.switch, s.level)
			end, 1.5)
			makeMultiDynW(sec, "V2 Elephant Team", "Team standing by in the garden (source of the Pet Switch choice)",
				function() return ctx.inventoryPetOptions(CFG.elephantV2Team) end,
				CFG.elephantV2Team, function() persist() end,
				{ register = true, cacheKey = "inv_pets", fillDelay = 0.6, max = 250 })
			makeMultiW(sec, "V2 Target Pet Types", "Select pet types to auto-level + elephant (all pets in game)",
				reg.PET_OPTIONS, CFG.elephantV2Types, function() persist() end,
				{ fillDelay = 1.0 })
			makeSingleW(sec, "Elephant Pet (Slot 1)", "The elephant sent in when a target reaches the trigger level",
				function() return ctx.elephantV2GajahOptions() end,
				function() return CFG.elephantV2Gajah end,
				function(uuid) CFG.elephantV2Gajah = uuid end,
				{ fillDelay = 1.2 })
			makeSingleW(sec, "Pet Switch (Slot 2)", "Pet from the Team that the Elephant replaces (usually Capy)",
				function() return ctx.elephantV2SwitchOptions() end,
				function() return CFG.elephantV2Switch end,
				function(uuid) CFG.elephantV2Switch = uuid end,
				{ fillDelay = 1.4 })
			makeInputW(sec, "Target Weight (KG)", "Release pets at this weight — ANY value, decimals OK (e.g. 3.5, 4.7, 6.2). No presets.",
				function() return CFG.elephantV2Weight end,
				function(t) CFG.elephantV2Weight = tonumber(t) or 5.5 end)
			makeInputW(sec, "Trigger Level", "Target level to send the Elephant in (default 40)",
				function() return CFG.elephantV2Level end,
				function(t) CFG.elephantV2Level = math.floor(tonumber(t) or 40) end)
			makeToggleW(sec, "Enable Elephant V2",
				"Rotate targets + auto-swap the Gajah at the trigger level. Runs together with PNP.",
				function() return CFG.elephantV2Enabled end,
				function(v)
					CFG.elephantV2Enabled = v; persist()
					if v then
						if ctx.startElephantV2 then pcall(function() ctx.startElephantV2() end) end
					else
						if ctx.stopElephantV2 then pcall(function() ctx.stopElephantV2() end) end
					end
				end)
			addRefresh(sec)
		end)

		miniBar(esecs, eorder, edefs, "v1")
	end

	----------------------------------------------------------------- TAB: FLOW (growth pipeline)
	local function buildFlowTab(tab)
		local fdefs = {
			flow     = { name = "Flow Config" },
			elephant = { name = "Elephant" },
			mut      = { name = "Mutation" },
			level    = { name = "Leveling" },
		}
		local forder = { "flow", "elephant", "mut", "level" }
		local fsecs = {}

		local function miniTab(id, buildFn)
			local sec = section(tab, fdefs[id].name)
			buildFn(sec)
			fsecs[id] = sec
		end

		-- panel 1: Flow Config (Controls & Targets + Configuration Flow)
		miniTab("flow", function(sec)
			makeMultiW(sec, "Flow Target Pet Types (Default)",
				"Default targets; used by any step whose own target types are empty",
				reg.PET_OPTIONS, CFG.growthPetTypes, function() persist() end,
				{ fillDelay = 0.4 })
			-- Step 1..6 pipeline — penempatan sama garden, opsi None/Elephant/
			-- Mutation/Leveling/P1/P2.
			local FLOW_OPTS = {
				{ name = "none",         display = "None (empty)" },
				{ name = "elephant",     display = "Elephant" },
				{ name = "mutation",     display = "Mutation" },
				{ name = "leveling",     display = "Leveling" },
				{ name = "leveling_p1",  display = "Leveling Phase 1" },
				{ name = "leveling_p2",  display = "Leveling Phase 2" },
			}
			local function capStep(s)
				for _, o in ipairs(FLOW_OPTS) do
					if o.name == s then return o.display end
				end
				return "Select"
			end
			local stepDesc = {
				"First step in pipeline flow", "Second step in pipeline flow",
				"Third step in pipeline flow", "Fourth step in pipeline flow",
				"Fifth step in pipeline flow", "Sixth step in pipeline flow",
			}
			for i = 1, 6 do
				makeSingleW(sec, "Step " .. i, stepDesc[i],
					function() return FLOW_OPTS end,
					function() return capStep((CFG.growthFlow or {})[i]) end,
					function(code)
						CFG.growthFlow = CFG.growthFlow or {}
						CFG.growthFlow[i] = code
						persist()
					end)
			end
			makeToggleW(sec, "Enable Automation Growth (Flow)", "Runs the step pipeline above in order.",
				function() return CFG.growthEnabled end,
				function(v)
					CFG.growthEnabled = v; persist()
					if v then
						if ctx.startGrowth then pcall(function() ctx.startGrowth() end) end
					else
						if ctx.stopGrowth then pcall(function() ctx.stopGrowth() end) end
					end
				end)
		end)

		-- panel 2: step Elephant
		miniTab("elephant", function(sec)
			makeMultiW(sec, "Elephant Target Pet Types", "Targets for the Elephant step (empty = use Default)",
				reg.PET_OPTIONS, CFG.growthPetTypesElephant, function() persist() end,
				{ fillDelay = 0.6 })
			makeMultiDynW(sec, "Elephant Pet Team", "Aura team used to grow weight",
				function() return ctx.inventoryPetOptions(CFG.growthElephantTeam) end,
				CFG.growthElephantTeam, function() persist() end,
				{ register = true, cacheKey = "inv_pets", fillDelay = 0.8, max = 250 })
			makeInputW(sec, "Target Weight (KG)", "Target weight before moving to the next step (e.g. 5.5)",
				function() return CFG.growthElephantWeight end,
				function(t) CFG.growthElephantWeight = tonumber(t) or 5.5 end)
			makeInputW(sec, "Max Target Pets", "Max target pets in the garden (Elephant step)",
				function() return CFG.growthElephantMax end,
				function(t) CFG.growthElephantMax = math.max(1, math.floor(tonumber(t) or 2)) end)
			addRefresh(sec)
		end)

		-- panel 3: step Mutation
		miniTab("mut", function(sec)
			makeMultiW(sec, "Mutation Target Pet Types", "Targets for the Mutation step (empty = use Default)",
				reg.PET_OPTIONS, CFG.growthPetTypesMutation, function() persist() end,
				{ fillDelay = 0.6 })
			makeMultiDynW(sec, "Mutation Pet Team", "Aura team that gives mutations",
				function() return ctx.inventoryPetOptions(CFG.growthMutationTeam) end,
				CFG.growthMutationTeam, function() persist() end,
				{ register = true, cacheKey = "inv_pets", fillDelay = 0.8, max = 250 })
			makeMultiW(sec, "Target Mutations", "Desired mutations (wrong mutations get auto cleansed)",
				reg.MUT_OPTIONS, CFG.growthMutationTargets, function() persist() end,
				{ fillDelay = 1.0 })
			makeInputW(sec, "Max Target Pets", "Max target pets in the garden (Mutation step)",
				function() return CFG.growthMutationMax end,
				function(t) CFG.growthMutationMax = math.max(1, math.floor(tonumber(t) or 2)) end)
			addRefresh(sec)
		end)

		-- panel 4: step Leveling
		miniTab("level", function(sec)
			makeMultiW(sec, "Leveling Target Pet Types", "Targets for the Leveling step (empty = use Default)",
				reg.PET_OPTIONS, CFG.growthPetTypesLeveling, function() persist() end,
				{ fillDelay = 0.6 })
			makeMultiDynW(sec, "Leveling Phase 1 Pet Team", "Team for Phase 1 (Age 1 to Phase 1 Target)",
				function() return ctx.inventoryPetOptions(CFG.growthLevP1Team) end,
				CFG.growthLevP1Team, function() persist() end,
				{ register = true, cacheKey = "inv_pets", fillDelay = 0.8, max = 250 })
			makeInputW(sec, "Leveling Phase 1 Target", "End of Phase 1 / start of Phase 2 (default 40)",
				function() return CFG.growthLevP1Target end,
				function(t) CFG.growthLevP1Target = math.floor(tonumber(t) or 40) end)
			makeInputW(sec, "Leveling Phase 1 Max Pets", "Max target pets in garden during Phase 1",
				function() return CFG.growthLevP1Max end,
				function(t) CFG.growthLevP1Max = math.max(1, math.floor(tonumber(t) or 3)) end)
			makeMultiDynW(sec, "Leveling Phase 2 Pet Team", "Team for Phase 2 (Phase 1 Target to Final Target)",
				function() return ctx.inventoryPetOptions(CFG.growthLevP2Team) end,
				CFG.growthLevP2Team, function() persist() end,
				{ register = true, cacheKey = "inv_pets", fillDelay = 1.0, max = 250 })
			makeInputW(sec, "Leveling Phase 2 Target", "Final target level (default 500 = max age)",
				function() return CFG.growthLevP2Target end,
				function(t) CFG.growthLevP2Target = math.floor(tonumber(t) or 500) end)
			makeInputW(sec, "Leveling Phase 2 Max Pets", "Max target pets in garden during Phase 2",
				function() return CFG.growthLevP2Max end,
				function(t) CFG.growthLevP2Max = math.max(1, math.floor(tonumber(t) or 1)) end)
			addRefresh(sec)
		end)

		miniBar(fsecs, forder, fdefs, "flow", { { "flow", "elephant" }, { "mut", "level" } })
	end

	----------------------------------------------------------------- TAB: LEVELING (V1 + V2 2-phase)
	local function buildLevelingTab(tab)
		local ldefs = {
			v1 = { name = "Leveling V1" },
			v2 = { name = "Leveling V2" },
		}
		local lorder = { "v1", "v2" }
		local lsecs = {}

		local function miniTab(id, buildFn)
			local sec = section(tab, ldefs[id].name)
			buildFn(sec)
			lsecs[id] = sec
		end

		-- panel 1: Automation Leveling V1
		miniTab("v1", function(sec)
			liveStatus(sec, "Leveling V1 Status", function()
				local ok, s = pcall(function() return ctx.getLevelingSummary() end)
				if not ok or not s then return nil end
				local col = s.status == "ACTIVE" and "#5acc78" or "#dc5050"
				return ("Automation Status: <font color=\"%s\"><b>%s</b></font>\n\n" ..
					"<b>Current Settings:</b>\n" ..
					"Pet Team: <font color=\"#8c929e\">%s</font>\n" ..
					"Target Types: <font color=\"#f5c82d\">%s</font>\n" ..
					"Pets Ready to Level: <font color=\"#8c929e\">%s</font>\n" ..
					"Pets at Max Level: <font color=\"#8c929e\">%s</font>\n" ..
					"Max in Garden: <font color=\"#8c929e\">%s</font>\n\n" ..
					"Target Level: <font color=\"#f5c82d\"><b>%s</b></font>\n\n" ..
					"Ready: Settings configured")
					:format(col, s.status, s.team, s.types, s.ready, s.maxLvl, s.maxInGarden, s.targetLevel)
			end, 1.5)
			makeMultiDynW(sec, "Leveling Pet Team", "Select pets to keep in the garden while leveling",
				function() return ctx.inventoryPetOptions(CFG.levelingTeamUuids) end,
				CFG.levelingTeamUuids, function() persist() end,
				{ register = true, cacheKey = "inv_pets", fillDelay = 0.4, max = 250 })
			makeMultiW(sec, "Leveling Pet Types", "Select pet types to auto-level (all pets in game)",
				reg.PET_OPTIONS, CFG.levelingPetTypes, function() persist() end,
				{ fillDelay = 0.8 })
			makeInputW(sec, "Target Level", "Target level to reach before un-equipping",
				function() return CFG.levelingTargetLevel end,
				function(t) CFG.levelingTargetLevel = math.floor(tonumber(t) or 500) end)
			makeInputW(sec, "Max Pets in Garden", "Maximum active leveling pets allowed in the garden",
				function() return CFG.levelingMaxPets end,
				function(t) CFG.levelingMaxPets = math.max(1, math.floor(tonumber(t) or 2)) end)
			makeToggleW(sec, "Enable Automation Leveling", "Equips and rotates pets automatically based on the settings above.",
				function() return CFG.levelingEnabled end,
				function(v)
					CFG.levelingEnabled = v; persist()
					if v then
						if ctx.startLeveling then pcall(function() ctx.startLeveling() end) end
					else
						if ctx.stopLeveling then pcall(function() ctx.stopLeveling() end) end
					end
				end)
			addRefresh(sec)
		end)

		-- panel 2: Automation Leveling V2 (2 fase)
		miniTab("v2", function(sec)
			liveStatus(sec, "Leveling V2 Status", function()
				local ok, s = pcall(function() return ctx.getLevelingV2Summary() end)
				if not ok or not s then return nil end
				local col = s.status == "ACTIVE" and "#5acc78" or "#dc5050"
				return ("Automation Status: <font color=\"%s\"><b>%s</b></font>  |  <font color=\"#f5c82d\">%s</font>\n\n" ..
					"<b>Target Types:</b> <font color=\"#8c929e\">%s</font>\n\n" ..
					"<b>Phase 1</b> (->%s): team <font color=\"#8c929e\">%s</font> | queued <font color=\"#f5c82d\">%s</font> pet\n" ..
					"<b>Phase 2</b> (->%s): team <font color=\"#8c929e\">%s</font> | queued <font color=\"#f5c82d\">%s</font> pet\n" ..
					"<b>Pet at Max Level:</b> <font color=\"#5acc78\">%s</font> pet")
					:format(col, s.status, tostring(s.phase), tostring(s.types),
						tostring(s.p1target), tostring(s.p1team), tostring(s.p1queue),
						tostring(s.p2target), tostring(s.p2team), tostring(s.p2queue),
						tostring(s.maxLvl or 0))
			end, 1.5)
			makeMultiW(sec, "Leveling Target Pet Types", "Pet types to level up (all pets in game)",
				reg.PET_OPTIONS, CFG.levelingV2PetTypes, function() persist() end,
				{ fillDelay = 0.6 })
			makeMultiDynW(sec, "Leveling Phase 1 Pet Team", "Team for Phase 1 (Age 1 to Phase 1 Target)",
				function() return ctx.inventoryPetOptions(CFG.levelingV2P1Team) end,
				CFG.levelingV2P1Team, function() persist() end,
				{ register = true, cacheKey = "inv_pets", fillDelay = 0.8, max = 250 })
			makeInputW(sec, "Leveling Phase 1 Target", "End of Phase 1 / start of Phase 2 (default 40)",
				function() return CFG.levelingV2P1Target end,
				function(t) CFG.levelingV2P1Target = math.floor(tonumber(t) or 40) end)
			makeInputW(sec, "Leveling Phase 1 Max Pets", "Max target pets in garden during Phase 1",
				function() return CFG.levelingV2P1Max end,
				function(t) CFG.levelingV2P1Max = math.max(1, math.floor(tonumber(t) or 3)) end)
			makeMultiDynW(sec, "Leveling Phase 2 Pet Team", "Team for Phase 2 (Phase 1 Target to Final Target)",
				function() return ctx.inventoryPetOptions(CFG.levelingV2P2Team) end,
				CFG.levelingV2P2Team, function() persist() end,
				{ register = true, cacheKey = "inv_pets", fillDelay = 1.0, max = 250 })
			makeInputW(sec, "Leveling Phase 2 Target", "Final target level (default 500 = max age)",
				function() return CFG.levelingV2P2Target end,
				function(t) CFG.levelingV2P2Target = math.floor(tonumber(t) or 500) end)
			makeInputW(sec, "Leveling Phase 2 Max Pets", "Max target pets in garden during Phase 2",
				function() return CFG.levelingV2P2Max end,
				function(t) CFG.levelingV2P2Max = math.max(1, math.floor(tonumber(t) or 1)) end)
			makeToggleW(sec, "Enable Automation Leveling V2", "Levels pets in 2 stages (Phase 1 team -> Phase 2 team).",
				function() return CFG.levelingV2Enabled end,
				function(v)
					CFG.levelingV2Enabled = v; persist()
					if v then
						if ctx.startLevelingV2 then pcall(function() ctx.startLevelingV2() end) end
					else
						if ctx.stopLevelingV2 then pcall(function() ctx.stopLevelingV2() end) end
					end
				end)
			addRefresh(sec)
		end)

		miniBar(lsecs, lorder, ldefs, "v1")
	end

	----------------------------------------------------------------- TAB: MUTATION (Machine + Aura Cleanse)
	local function buildMutationTab(tab)
		local mdefs = {
			machine = { name = "Machine" },
			cleanse = { name = "Aura Cleanse" },
		}
		local morder = { "machine", "cleanse" }
		local msecs = {}

		local function miniTab(id, buildFn)
			local sec = section(tab, mdefs[id].name)
			buildFn(sec)
			msecs[id] = sec
		end

		-- panel 1: Mutation Machine
		miniTab("machine", function(sec)
			liveStatus(sec, "Mutation Machine Status", function()
				local ok, s = pcall(function() return ctx.getMutationSummary() end)
				if not ok or not s then return nil end
				local col = s.status == "ACTIVE" and "#5acc78" or "#dc5050"
				return ("Status: <font color=\"%s\"><b>%s</b></font>\n" ..
					"Phase: <b>%s</b>\n\n" ..
					"EXP Team: <font color=\"#8c929e\">%s pets</font>\n" ..
					"Boost Team: <font color=\"#8c929e\">%s pets</font>\n" ..
					"Phoenix Team: <font color=\"#8c929e\">%s pets</font>\n\n" ..
					"Target Types: <font color=\"#f5c82d\">%s</font>\n" ..
					"Keep Mutations: <font color=\"#f5c82d\">%s</font>\n" ..
					"Target Age: <font color=\"#f5c82d\"><b>%s</b></font>\n\n" ..
					"Machine: <font color=\"#85d0ff\"><b>%s</b></font>\n\n" ..
					"Target Pets Ready: <font color=\"#8c929e\">%s pets</font>\n" ..
					"Target Pets Done: <font color=\"#5acc78\"><b>%s pets</b></font>")
					:format(col, s.status, tostring(s.phase), tostring(s.expCount), tostring(s.boostCount),
						tostring(s.phoenixCount), tostring(s.types), tostring(s.mutations),
						tostring(s.targetAge), tostring(s.machine), tostring(s.readyCount), tostring(s.doneCount))
			end, 1.5)
			makeMultiDynW(sec, "EXP Team (Leveling)", "Pets for leveling the target to age 50/500",
				function() return ctx.inventoryPetOptions(CFG.mutationExpTeam) end,
				CFG.mutationExpTeam, function() persist() end,
				{ register = true, cacheKey = "inv_pets", fillDelay = 0.4, max = 250 })
			makeMultiDynW(sec, "Boost Team (Machine)", "Pets for boosting the mutation machine speed",
				function() return ctx.inventoryPetOptions(CFG.mutationBoostTeam) end,
				CFG.mutationBoostTeam, function() persist() end,
				{ register = true, cacheKey = "inv_pets", fillDelay = 0.6, max = 250 })
			makeMultiDynW(sec, "Phoenix Team (Claim)", "Pets for claiming the mutated pet",
				function() return ctx.inventoryPetOptions(CFG.mutationPhoenixTeam) end,
				CFG.mutationPhoenixTeam, function() persist() end,
				{ register = true, cacheKey = "inv_pets", fillDelay = 0.8, max = 250 })
			makeMultiW(sec, "Target Pet Types", "Pet types to mutate (all pets in game)",
				reg.PET_OPTIONS, CFG.mutationTargetTypes, function() persist() end,
				{ fillDelay = 1.0 })
			makeMultiW(sec, "Target Mutations (Machine)", "Stop when the pet gets these mutations (machine mutations only)",
				reg.MACHINE_MUT_OPTIONS or reg.MUT_OPTIONS, CFG.mutationTargetMutations, function() persist() end,
				{ fillDelay = 1.2 })
			makeInputW(sec, "Target Age", "Level to reach before submitting (e.g. 50 or 500)",
				function() return CFG.mutationTargetAge end,
				function(t) CFG.mutationTargetAge = math.floor(tonumber(t) or 50) end)
			makeInputW(sec, "Delay Auto Claim (sec)", "Wait before claiming the mutated pet from the machine",
				function() return CFG.mutationDelayAutoClaim end,
				function(t) CFG.mutationDelayAutoClaim = tonumber(t) or 0.5 end)
			makeToggleW(sec, "Enable Auto Mutation Machine", "Submits, starts, and claims mutated pets automatically.",
				function() return CFG.mutationEnabled end,
				function(v)
					CFG.mutationEnabled = v; persist()
					if v then
						if ctx.startMutation then pcall(function() ctx.startMutation() end) end
					else
						if ctx.stopMutation then pcall(function() ctx.stopMutation() end) end
					end
				end)
			addRefresh(sec)
		end)

		-- panel 2: Aura Cleanse (mutasi via aura + cleanse salah)
		miniTab("cleanse", function(sec)
			liveStatus(sec, "Aura Mutation Status", function()
				local ok, s = pcall(function() return ctx.getCleanseSummary() end)
				if not ok or not s then return nil end
				local col = s.status == "ACTIVE" and "#5acc78" or "#dc5050"
				local already = ""
				if type(s.keepOrder) == "table" and type(s.already) == "table" then
					for _, k in ipairs(s.keepOrder) do
						already = already .. ("- Already %s: <font color=\"#8c929e\">%s pets</font>\n")
							:format(tostring(k), tostring(s.already[k] or 0))
					end
				end
				return ("Automation Status: <font color=\"%s\"><b>%s</b></font>\n\n" ..
					"Mutation Team: <font color=\"#8c929e\">%s pets</font>\n" ..
					"Target Types: <font color=\"#f5c82d\">%s</font>\n" ..
					"Mutations to Keep: <font color=\"#f5c82d\">%s</font>\n\n" ..
					"Pet Statistics:\n" ..
					"- Pets Ready to Mutation: <font color=\"#8c929e\">%s pets</font>\n" ..
					"%s\n" ..
					"Max in Garden: <font color=\"#8c929e\">%s pets</font>\n\n" ..
					"Status: <font color=\"#85d0ff\">%s</font>")
					:format(col, s.status, tostring(s.team), tostring(s.types), tostring(s.keep),
						tostring(s.ready), already, tostring(s.maxPets), tostring(s.phase))
			end, 1.5)
			makeMultiDynW(sec, "Pet Team for Mutation", "Mutation aura pets (stay in the garden)",
				function() return ctx.inventoryPetOptions(CFG.cleanseTeamUuids) end,
				CFG.cleanseTeamUuids, function() persist() end,
				{ register = true, cacheKey = "inv_pets", fillDelay = 0.6, max = 250 })
			makeMultiW(sec, "Pet Types for Mutation", "Target pet types to mutate (all pets in game)",
				reg.PET_OPTIONS, CFG.cleansePetTypes, function() persist() end,
				{ fillDelay = 0.8 })
			makeMultiW(sec, "Mutations to Keep", "These mutations are kept (won't be cleansed)",
				reg.MUT_OPTIONS, CFG.cleanseKeepMutations, function() persist() end,
				{ fillDelay = 1.0 })
			makeInputW(sec, "Max Pets in Garden", "Max target pets in the garden at once",
				function() return CFG.cleanseMaxPets end,
				function(t) CFG.cleanseMaxPets = math.max(1, math.floor(tonumber(t) or 2)) end)
			makeToggleW(sec, "Enable Auto Mutation", "Mutates targets via aura; cleanses wrong mutations, keeps the kept ones.",
				function() return CFG.cleanseEnabled end,
				function(v)
					CFG.cleanseEnabled = v; persist()
					if v then
						if ctx.startCleanse then pcall(function() ctx.startCleanse() end) end
					else
						if ctx.stopCleanse then pcall(function() ctx.stopCleanse() end) end
					end
				end)
			addRefresh(sec)
		end)

		miniBar(msecs, morder, mdefs, "machine")
	end

	----------------------------------------------------------------- TAB: SHOP (Seeds/Eggs/Gears/Merchant/Premium)
	local function buildShopTab(tab)
		local sdefs = {
			seed     = { name = "Seeds" },
			egg      = { name = "Eggs" },
			gear     = { name = "Gears" },
			merchant = { name = "Merchant" },
			premium  = { name = "Premium" },
		}
		local sorder = { "seed", "egg", "gear", "merchant", "premium" }
		local ssecs = {}

		local function miniTab(id, buildFn)
			local sec = section(tab, sdefs[id].name)
			buildFn(sec)
			ssecs[id] = sec
		end

		-- panel 1-3: Buy Seed / Egg / Gear (placement sama garden)
		miniTab("seed", function(sec)
			makeMultiDynW(sec, "Select Seeds to Buy", "Pick seeds to auto-buy (live stock)",
				function() return ctx.getSeedShopOptions(CFG.buySeedNames) end,
				CFG.buySeedNames, function() persist() end,
				{ register = true, cacheKey = "shop_seed", fillDelay = 0.4 })
			makeToggleW(sec, "Enable Automation Buy Seed", "Auto-buys the selected seeds whenever they are in stock.",
				function() return CFG.buySeedEnabled end,
				function(v)
					CFG.buySeedEnabled = v; persist()
					if v and ctx.startBuySeed then pcall(function() ctx.startBuySeed() end) end
				end)
			addRefresh(sec)
		end)
		miniTab("egg", function(sec)
			makeMultiDynW(sec, "Select Eggs to Buy", "Pick eggs to auto-buy (live stock)",
				function() return ctx.getEggShopOptions(CFG.buyEggNames) end,
				CFG.buyEggNames, function() persist() end,
				{ register = true, cacheKey = "shop_egg", fillDelay = 0.6 })
			makeToggleW(sec, "Enable Automation Buy Egg", "Auto-buys the selected eggs whenever they are in stock.",
				function() return CFG.buyEggEnabled end,
				function(v)
					CFG.buyEggEnabled = v; persist()
					if v and ctx.startBuyEgg then pcall(function() ctx.startBuyEgg() end) end
				end)
			addRefresh(sec)
		end)
		miniTab("gear", function(sec)
			makeMultiDynW(sec, "Select Gear to Buy", "Pick gear to auto-buy (live stock)",
				function() return ctx.getGearShopOptions(CFG.buyGearNames) end,
				CFG.buyGearNames, function() persist() end,
				{ register = true, cacheKey = "shop_gear", fillDelay = 0.8 })
			makeToggleW(sec, "Enable Automation Buy Gear", "Auto-buys the selected gear whenever it is in stock.",
				function() return CFG.buyGearEnabled end,
				function(v)
					CFG.buyGearEnabled = v; persist()
					if v and ctx.startBuyGear then pcall(function() ctx.startBuyGear() end) end
				end)
			addRefresh(sec)
		end)

		-- panel 4: Merchant (item selection per merchant + toggles + Open Shop UI)
		miniTab("merchant", function(sec)
			liveStatus(sec, "Merchant Status", function()
				local ok, s = pcall(function() return ctx.getMerchantSummary() end)
				if not ok or not s then return nil end
				local lines = {}
				if s.activeMerchant then
					lines[#lines + 1] = ("Active Traveling: <font color=\"#5acc78\"><b>%s</b></font>"):format(tostring(s.activeMerchant))
				else
					lines[#lines + 1] = "Active Traveling: <font color=\"#dc5050\">None</font>"
				end
				if s.mode == "all" then
					lines[#lines + 1] = "Mode: <font color=\"#f5c82d\"><b>Buy ALL items (All)</b></font>"
				elseif s.mode == "best" then
					lines[#lines + 1] = "Mode: <font color=\"#f5c82d\"><b>Buy the MOST EXPENSIVE item (Best)</b></font>"
				elseif type(s.picks) == "table" and #s.picks > 0 then
					lines[#lines + 1] = "Selected items to buy:"
					for _, p in ipairs(s.picks) do
						local parts = {}
						for _, it in ipairs(p.items or {}) do
							if it.price then
								local a = math.abs(it.price)
								local num
								if a >= 1e9 then num = ("%sb"):format(("%0.2f"):format(it.price / 1e9))
								elseif a >= 1e6 then num = ("%sm"):format(("%0.2f"):format(it.price / 1e6))
								elseif a >= 1e3 then num = ("%sk"):format(("%0.2f"):format(it.price / 1e3))
								else num = tostring(it.price) end
								parts[#parts + 1] = ("%s (%s)"):format(tostring(it.name), num)
							else
								parts[#parts + 1] = tostring(it.name)
							end
						end
						lines[#lines + 1] = ("- <font color=\"#5acc78\"><b>%s</b></font>: <font color=\"#f5c82d\">%s</font>")
							:format(tostring(p.title), table.concat(parts, ", "))
					end
				else
					lines[#lines + 1] = "<font color=\"#dc5050\">No items selected yet.</font> Pick in 'Select Items per Merchant' or turn on Auto Buy All/Best."
				end
				return table.concat(lines, "\n")
			end, 2)
			-- Item selection per merchant (travel) & per event shop — placement
			-- garden: dipilah dua grup, di sini jadi satu panel urut (travel dulu).
			pcall(function()
				for _, m in ipairs(ctx.getMerchantList()) do
					local kind, id, mtitle = m.kind, m.id, m.title
					local heading = (kind == "travel") and (mtitle .. " Merchant") or mtitle
					makeMultiDynW(sec, "Select Items - " .. heading,
						("Items from %s%s. 'All' = everything."):format(mtitle, (kind == "travel") and " merchant" or ""),
						function() return ctx.getMerchantItemOptions(id) end,
						ctx.merchantSelFor(id), function() persist() end,
						{ register = true, cacheKey = "merch_" .. tostring(id), fillDelay = 0.5 })
				end
			end)
			makeToggleW(sec, "Auto Buy Merchant", "Buys the selected items (merchant & event shop) whenever they appear / restock",
				function() return CFG.merchantBuyEnabled end,
				function(v)
					CFG.merchantBuyEnabled = v; persist()
					if v and ctx.startBuyMerchant then pcall(function() ctx.startBuyMerchant() end) end
				end)
			makeToggleW(sec, "Auto Buy All Merchant", "Buys EVERY item that is in stock",
				function() return CFG.merchantBuyAll end,
				function(v)
					CFG.merchantBuyAll = v; persist()
					if v and ctx.startBuyMerchant then pcall(function() ctx.startBuyMerchant() end) end
				end)
			makeToggleW(sec, "Auto Buy Best Merchant", "Buys the 1 MOST EXPENSIVE item in stock",
				function() return CFG.merchantBuyBest end,
				function(v)
					CFG.merchantBuyBest = v; persist()
					if v and ctx.startBuyMerchant then pcall(function() ctx.startBuyMerchant() end) end
				end)
			makeSingleW(sec, "Merchant UI to Open", "Event shop whose UI should be opened (one shop at a time)",
				function() return ctx.getEventShopOptions() end,
				function() return CFG.merchantUiShop end,
				function(code)
					CFG.merchantUiShop = code; persist()
					if ctx.openEventShopUI then pcall(function() ctx.openEventShopUI(code) end) end
				end)
			sec:Button({
				Title = "Open Shop UI Now", Desc = "Opens the selected shop UI now (while the shop is active).",
				Callback = safe(function()
					if ctx.openEventShopUI then pcall(function() ctx.openEventShopUI() end) end
				end),
			})
			makeToggleW(sec, "Auto Open UI", "Keeps the selected shop UI open (re-opens automatically, without the NPC)",
				function() return CFG.merchantAutoOpenUI end,
				function(v)
					CFG.merchantAutoOpenUI = v; persist()
					if v then
						if ctx.startAutoOpenUI then pcall(function() ctx.startAutoOpenUI() end) end
					elseif ctx.stopAutoOpenUI then
						pcall(function() ctx.stopAutoOpenUI() end)
					end
				end)
			addRefresh(sec)
		end)

		-- panel 5: Premium
		miniTab("premium", function(sec)
			makeSingleW(sec, "Select Item", "Select the gamepass/product to purchase",
				function() return ctx.getPremiumItemOptions() end,
				function() return CFG.premiumItem end,
				function(code)
					CFG.premiumItem = code; persist()
					if ctx.premiumShowPrice then pcall(function() ctx.premiumShowPrice() end) end
				end)
			makeSingleW(sec, "Payment Method", "Pay with Robux / in-game Token",
				function() return { { name = "robux", display = "Robux" }, { name = "token", display = "Token" } } end,
				function() return CFG.premiumPay == "token" and "Token" or "Robux" end,
				function(code) CFG.premiumPay = code; persist() end)
			sec:Button({
				Title = "Purchase Item", Desc = "Buys the selected item with the payment method above.",
				Callback = safe(function()
					if ctx.premiumBuy then pcall(function() ctx.premiumBuy() end) end
				end),
			})
			sec:Button({
				Title = "Gift to Player", Desc = "Buys the Gift variant of this item (if available).",
				Callback = safe(function()
					if ctx.premiumGift then pcall(function() ctx.premiumGift() end) end
				end),
			})
			addRefresh(sec)
		end)

		miniBar(ssecs, sorder, sdefs, "seed", { { "seed", "egg", "gear" }, { "merchant", "premium" } })
	end

	----------------------------------------------------------------- TAB: MISC (Player & ESP / Rejoin / Webhook / Performance)
	local function buildMiscTab(tab)
		local xdefs = {
			player  = { name = "Player & ESP" },
			rejoin  = { name = "Rejoin" },
			webhook = { name = "Webhook" },
			perf    = { name = "Performance" },
		}
		local xorder = { "player", "rejoin", "webhook", "perf" }
		local xsecs = {}

		local function miniTab(id, buildFn)
			local sec = section(tab, xdefs[id].name)
			buildFn(sec)
			xsecs[id] = sec
		end

		-- panel 1: Player (Noclip / Walk Speed / Infinity Jump) + ESP
		miniTab("player", function(sec)
			makeToggleW(sec, "Noclip", "Walk through walls and obstacles",
				function() return CFG.noclipEnabled end,
				function(v)
					if ctx.setNoclip then pcall(function() ctx.setNoclip(v) end) end
					persist()
				end)
			makeInputW(sec, "Walk Speed", "Player walk speed (default 16)",
				function() return CFG.walkSpeed end,
				function(t)
					CFG.walkSpeed = tonumber(t) or 16
					if ctx.applyWalkSpeed then pcall(function() ctx.applyWalkSpeed() end) end
				end)
			makeToggleW(sec, "Enable Walk Speed", "Applies the custom walk speed",
				function() return CFG.walkSpeedEnabled end,
				function(v)
					if ctx.setWalkSpeed then pcall(function() ctx.setWalkSpeed(v) end) end
					persist()
				end)
			makeToggleW(sec, "Infinity Jump", "Jump in mid-air infinitely",
				function() return CFG.infJumpEnabled end,
				function(v)
					if ctx.setInfJump then pcall(function() ctx.setInfJump(v) end) end
					persist()
				end)
			makeToggleW(sec, "Enable ESP Label", "Floating labels above pets (name + weight + level + mutation)",
				function() return CFG.espEnabled end,
				function(v)
					CFG.espEnabled = v; persist()
					if v then
						if ctx.startEsp then pcall(function() ctx.startEsp() end) end
					elseif ctx.stopEsp then
						pcall(function() ctx.stopEsp() end)
					end
				end)
			makeSingleW(sec, "ESP Label Mode", "Where the pet ESP renders",
				function() return {
					{ name = "target", display = "Target (floating on pet)" },
					{ name = "screen", display = "Screen (side panel list)" },
				} end,
				function() return CFG.espMode end,
				function(code)
					CFG.espMode = code; persist()
					if CFG.espEnabled then
						if ctx.stopEsp then pcall(function() ctx.stopEsp() end) end
						if ctx.startEsp then pcall(function() ctx.startEsp() end) end
					end
				end)
			makeToggleW(sec, "Enable ESP Egg", "NEBULA-style floating egg info (egg name, hatch timer/Base Weight or hatched pet + size class). Separate from pet ESP.",
				function() return CFG.espEggEnabled end,
				function(v)
					CFG.espEggEnabled = v; persist()
					if v then
						if ctx.startEspEgg then pcall(function() ctx.startEspEgg() end) end
					elseif ctx.stopEspEgg then
						pcall(function() ctx.stopEspEgg() end)
					end
				end)
			makeSingleW(sec, "ESP Egg Mode", "Where the egg ESP renders",
				function() return {
					{ name = "target", display = "Target (floating on egg)" },
					{ name = "screen", display = "Screen (side panel list)" },
				} end,
				function() return CFG.espEggMode end,
				function(code)
					CFG.espEggMode = code; persist()
					if CFG.espEggEnabled then
						if ctx.stopEspEgg then pcall(function() ctx.stopEspEgg() end) end
						if ctx.startEspEgg then pcall(function() ctx.startEspEgg() end) end
					end
				end)
			makeToggleW(sec, "Enable ESP Base Weight", "Shows the Base Weight on every pet slot when opening the inventory",
				function() return CFG.espInvEnabled end,
				function(v)
					CFG.espInvEnabled = v; persist()
					if v then
						if ctx.startEspInv then pcall(function() ctx.startEspInv() end) end
					elseif ctx.stopEspInv then
						pcall(function() ctx.stopEspInv() end)
					end
				end)
			makeSingleW(sec, "Base Weight Display", "Which data shows on the pet label",
				function() return {
					{ name = "base", display = "Base Weight Only" },
					{ name = "age",  display = "Base + Age" },
					{ name = "max",  display = "Base + Max" },
				} end,
				function() return CFG.espInvMode end,
				function(code) CFG.espInvMode = code; persist() end)
		end)

		-- panel 2: Rejoin (auto reconnect + periodic)
		miniTab("rejoin", function(sec)
			makeToggleW(sec, "Auto Reconnect", "Rejoins automatically when kicked / disconnected",
				function() return CFG.autoReconnect ~= false end,
				function(v) CFG.autoReconnect = v; persist() end)
			liveStatus(sec, "Periodic Rejoin", function()
				if CFG.reconnectEnabled then
					local rem = ctx.state.reconnectRemaining
					if rem then
						return ("Rejoin in: <font color=\"#5acc78\"><b>%d:%02d</b></font>")
							:format(math.floor(rem / 60), rem % 60)
					end
					return "Rejoin: <font color=\"#5acc78\"><b>ON</b></font>"
				end
				return "Rejoin: OFF"
			end, 1)
			makeInputW(sec, "Interval (minutes)", "Rejoins the server periodically every N minutes (e.g. 1 = every minute).",
				function() return CFG.reconnectInterval end,
				function(t) CFG.reconnectInterval = tonumber(t) or 5; persist() end)
			makeToggleW(sec, "Periodic Rejoin", "Rejoins the server periodically on the interval above",
				function() return CFG.reconnectEnabled end,
				function(v)
					CFG.reconnectEnabled = v; persist()
					if v and ctx.startReconnect then pcall(function() ctx.startReconnect() end) end
				end)
		end)

		-- panel 3: Webhook (URL + test)
		miniTab("webhook", function(sec)
			makeInputW(sec, "Discord Webhook URL", "Webhook URL for automation updates (Leveling, Mutation & Elephant)",
				function() return CFG.webhookUrl end,
				function(t) CFG.webhookUrl = t; persist() end)
			sec:Button({
				Title = "Test Webhook Connection", Desc = "Sends a test notification to your Discord channel.",
				Callback = safe(function()
					if not CFG.webhookUrl or CFG.webhookUrl == "" then
						if ctx.log then ctx.log("[Webhook Test] FAILED: webhook URL is empty!") end
						return
					end
					if ctx.log then ctx.log("[Webhook Test] Sending test payload...") end
					task.spawn(function()
						local sendWebhook = ctx.sendWebhook
						if sendWebhook then
							pcall(function()
								sendWebhook(CFG.webhookUrl, {
									embeds = {
										{
											title = "Webhook Connection Test",
											description = "Discord Webhook connected successfully to Dopamine!",
											color = 3066993,
											fields = {
												{
													name = "Profile :",
													value = string.format("> Username : ||%s||", ctx.LP.Name),
													inline = false,
												},
											},
											footer = {
												text = os.date("%B %d | %I:%M %p"),
												icon_url = "https://raw.githubusercontent.com/milmscr/opoki/main/tegalan/Logo/logo_icon.png",
											},
										},
									},
								}, ctx)
							end)
						elseif ctx.log then
							ctx.log("[Webhook Test] FAILED to load the sender module.")
						end
					end)
				end),
			})
		end)

		-- panel 4: Performance (hide plants / FX / render)
		miniTab("perf", function(sec)
			makeToggleW(sec, "Hide My Garden Plants", "Hides plants on your own farm for better FPS",
				function() return CFG.hideMyPlants end,
				function(v)
					if ctx.setHidePlants then pcall(function() ctx.setHidePlants("mine", v) end) end
					persist()
				end)
			makeToggleW(sec, "Hide Other Gardens Plants", "Hides plants on other players' farms",
				function() return CFG.hideOtherPlants end,
				function(v)
					if ctx.setHidePlants then pcall(function() ctx.setHidePlants("other", v) end) end
					persist()
				end)
			makeToggleW(sec, "Auto Remove Spider Web FX", "Continuously removes spider web particle effects",
				function() return CFG.autoRemoveWebFx end,
				function(v)
					if ctx.setAutoRemoveWeb then pcall(function() ctx.setAutoRemoveWeb(v) end) end
					persist()
				end)
			makeSingleW(sec, "Performance Mode", "Off: normal. Low: shadows off. Extreme: all particle effects off.",
				function() return ctx.getPerfModeOptions() end,
				function() return CFG.perfMode or "off" end,
				function(code)
					if ctx.setPerfMode then pcall(function() ctx.setPerfMode(code) end) end
					persist()
				end)
			makeToggleW(sec, "Disable 3D Rendering", "Stops rendering the 3D world (huge FPS gains, black screen)",
				function() return CFG.disable3d end,
				function(v)
					if ctx.setDisable3d then pcall(function() ctx.setDisable3d(v) end) end
					persist()
				end)
		end)

		miniBar(xsecs, xorder, xdefs, "player", { { "player", "rejoin" }, { "webhook", "perf" } })
	end

	----------------------------------------------------------------- TAB: SETTINGS
	local function buildSettingsTab(tab)
		local persist = ctx.persistState

		local DEFS = {
			general = { name = "General" },
			config  = { name = "Config" },
			control = { name = "Control" },
			logs    = { name = "Logs" },
		}
		local ORDER = { "general", "config", "control", "logs" }
		local secs = {}
		local function miniTab(id, buildFn)
			local sec = section(tab, DEFS[id].name)
			buildFn(sec)
			secs[id] = sec
		end

		--------------------------------------------------- panel 1: General
		miniTab("general", function(sec)
			sec:Paragraph({
				Title = "Dopamine | P².Achieve",
				Desc = ("Build: %s\nToggle UI: click the logo open button or press K.\nConfig file: state_%s.json in the executor workspace (auto-saves on every change + every 10s).")
					:format(
						tostring((getgenv and getgenv().GAG_REVISION) or ctx.BASE or "-"),
						tostring(ctx.LP.UserId)),
			})

			-- Theme WindUI (bawaan lib; ganti tanpa reload).
			local themes = {}
			pcall(function()
				local th = W.windui.GetThemes and W.windui:GetThemes()
				if th then for nm in pairs(th) do themes[#themes + 1] = tostring(nm) end end
			end)
			table.sort(themes)
			if #themes == 0 then themes = { "Dark", "Light" } end
			local curTheme = nil
			pcall(function() curTheme = W.windui.GetCurrentTheme and W.windui:GetCurrentTheme() end)
			makeSingleW(sec, "Theme WindUI", "Built-in WindUI theme, applies instantly.",
				function() return themes end,
				function() return curTheme or themes[1] end,
				function(v)
					pcall(function() if W.windui.SetTheme then W.windui:SetTheme(v) end end)
					W.notify("Settings", "Theme: " .. tostring(v))
				end, { fillDelay = 2.2 })

			sec:Button({
				Title = "Reload Hub",
				Desc = "Re-run the loader (pulls the latest build from the repo).",
				Callback = safe(function()
					local rev = (getgenv and getgenv().GAG_REVISION) or "main"
					pcall(function()
						loadstring(game:HttpGet("https://raw.githubusercontent.com/MisthiosOG/testgden/"
							.. tostring(rev) .. "/tegalan/init.lua?t=" .. os.time()))()
					end)
				end),
			})
		end)

		--------------------------------------------------- panel 2: Config
		miniTab("config", function(sec)
			-- Live config status: what got loaded at boot + FS probe verdict.
			local fsDiag = sec:Paragraph({
				Title = "Config Status",
				Desc = "Checking...",
			})
			task.spawn(function()
				local last = ""
				while ctx.alive() do
					pcall(function()
						local info = tostring(ctx.state.cfgLoadInfo
							or "No config loaded this session yet")
						local fs = tostring(ctx.state.fsStatus or "")
						local txt = info .. (fs ~= "" and ("\n" .. fs) or "")
						if txt ~= last then last = txt; fsDiag:SetDesc(txt) end
					end)
					task.wait(3)
				end
			end)
			sec:Paragraph({
				Title = "Config Storage",
				Desc = "Run Config Storage Test to check every path.",
			})
			sec:Button({
				Title = "Save Config Now",
				Desc = "Force-save all settings to the state file.",
				Callback = safe(function()
					persist()
					local okr, info = pcall(function()
						local path = tostring(ctx.CFG_STATE_PATH or "")
						return path .. " (" .. tostring(#readfile(path)) .. " bytes)"
					end)
					if okr then
						W.notify("Settings", "Saved -> " .. info)
						ctx.log("Settings: manual save -> " .. info)
					else
						W.notify("Settings", "Save FAILED, read the log")
						ctx.log("Settings: save FAILED (readfile/writefile rejected)")
					end
				end),
			})
			sec:Button({
				Title = "Config Storage Test",
				Desc = "Test writefile + readfile on every candidate path, live.",
				Callback = safe(function()
					local cands = ctx.CFG_STATE_CANDIDATES or {}
					local lines = {}
					if type(writefile) ~= "function" or type(readfile) ~= "function" then
						lines[1] = "Executor has NO writefile/readfile, config persistence impossible"
					elseif #cands == 0 then
						lines[1] = "No candidate paths registered"
					else
						for _, p in ipairs(cands) do
							local errOut = nil
							local okPing = pcall(function()
								local pf = p .. ".probe"
								writefile(pf, "1")
								if readfile(pf) ~= "1" then errOut = "readback mismatch" end
								pcall(delfile, pf)
							end)
							if not okPing then errOut = "executor rejected the path" end
							if errOut then
								lines[#lines + 1] = p .. "  FAIL (" .. errOut .. ")"
							else
								lines[#lines + 1] = p .. "  OK"
							end
						end
					end
					pcall(function() fsDiag:SetDesc(table.concat(lines, "\n")) end)
					ctx.log("[config] storage test: " .. tostring(#lines) .. " path(s) checked")
				end),
			})
			sec:Button({
				Title = "Restore Config Backup",
				Desc = "Copy the last good config (.bak) over the main file, then re-exec.",
				Callback = safe(function()
					local mainP = tostring(ctx.CFG_STATE_PATH or "")
					local bakP = mainP .. ".bak"
					local okr, detail = pcall(function()
						local data = readfile(bakP)
						assert(data and #data > 0, "backup empty")
						writefile(mainP, data)
						pcall(function()
							local gp = "garden_state_" .. tostring(ctx.LP.UserId) .. ".json"
							if isfile(gp) then writefile(gp, data) end
						end)
						return #data
					end)
					if okr then
						W.notify("Config", "Backup restored (" .. tostring(detail) .. " bytes), re-exec the script now")
						ctx.log("[config] backup restored -> " .. mainP)
					else
						W.notify("Config", "No backup file found")
						ctx.log("[config] restore FAILED: " .. tostring(detail))
					end
				end),
			})
		end)

		--------------------------------------------------- panel 3: Control
		miniTab("control", function(sec)
			sec:Paragraph({
				Title = "Automation Control",
				Desc = "STOP ALL turns off every automation + player/perf mods in one go. Toggles snap back to OFF and persist to the config.",
			})

			-- STOP ALL: matiin SEMUA automation (sweep flag *Enabled) + player/perf
			-- mods dibalikin ke default + stop function yg tersedia. Loop automation
			-- semuanya nge-flag CFG tiap tick -> flag mati = loop berhenti sendiri.
			local function doStopAll()
				for k, v in pairs(CFG) do
					if type(v) == "boolean" and tostring(k):find("Enabled", 1, true) then CFG[k] = false end
				end
				CFG.autoReconnect  = false
				CFG.hideMyPlants   = false
				CFG.hideOtherPlants= false
				CFG.autoRemoveWebFx= false
				CFG.disable3d      = false
				for _, fn in ipairs({ "stopPnpV1", "stopTrade", "stopHatch",
					"stopAutoFavorite", "stopAutoUnfavorite", "stopEggMinusWatcher", "stopReclaim",
					"stopGrowth", "stopLeveling", "stopLevelingV2", "stopElephant", "stopElephantV2",
					"stopMutation", "stopCleanse", "stopBoostPet", "stopReconnect" }) do
					if ctx[fn] then pcall(ctx[fn]) end
				end
				if ctx.setNoclip then pcall(function() ctx.setNoclip(false) end) end
				if ctx.setWalkSpeed then pcall(function() ctx.setWalkSpeed(false) end) end
				if ctx.setInfJump then pcall(function() ctx.setInfJump(false) end) end
				if ctx.setHidePlants then
					pcall(function() ctx.setHidePlants("mine", false) end)
					pcall(function() ctx.setHidePlants("other", false) end)
				end
				if ctx.setAutoRemoveWeb then pcall(function() ctx.setAutoRemoveWeb(false) end) end
				if ctx.setDisable3d then pcall(function() ctx.setDisable3d(false) end) end
				if ctx.setPerfMode then pcall(function() ctx.setPerfMode("off") end) end
				persist()
				ctx.log("Settings: ALL automation stopped.")
				W.notify("Settings", "All automation STOPPED.")
			end

			sec:Button({
				Title = "STOP ALL Automation",
				Desc = "Turn off all automation + player/perf mods (asks for confirmation first).",
				Callback = safe(function()
					local okd = pcall(function()
						window:Dialog({
							Title = "Stop All Automation?",
							Content = "All automation, player mods, and perf mode will be turned off.",
							Buttons = {
								{ Title = "Yes, Stop All", Variant = "Primary", Callback = doStopAll },
								{ Title = "Cancel", Variant = "Secondary", Callback = function() end },
							},
						})
					end)
					if not okd then doStopAll() end -- dist tanpa Dialog -> langsung eksekusi
				end),
			})
		end)

		--------------------------------------------------- panel 4: Logs
		miniTab("logs", function(sec)
			-- Log live: 8 baris terakhir ctx.state.logLines.
			local logs = sec:Paragraph({ Title = "Logs", Desc = "-" })
			task.spawn(function()
				task.wait(3)
				while ctx.alive() do
					pcall(function()
						local n = #ctx.state.logLines
						local from = math.max(1, n - 7)
						local t = {}
						for i = from, n do t[#t + 1] = ctx.state.logLines[i] end
						logs:SetDesc(table.concat(t, "\n"))
					end)
					task.wait(3)
				end
			end)
		end)

		miniBar(secs, ORDER, DEFS, "general")
	end

	----------------------------------------------------------------- REGISTRY TAB
	-- Urutan sesuai Pink Royale. build = nil -> placeholder (belum dimigrasi).
	local MIGRATED = {
		Pet = buildPetTab,
		Inventory = buildInventoryTab,
		Farm = buildFarmTab,
		Hatch = buildHatchTab,
		Elephant = buildElephantTab,
		Flow = buildFlowTab,
		Leveling = buildLevelingTab,
		Mutation = buildMutationTab,
		Shop = buildShopTab,
		Misc = buildMiscTab,
		Settings = buildSettingsTab,
	}

	local TABS = {
		{ id = "Pet",       title = "Pet",       icon = "solar:cat-bold" },
		{ id = "Farm",      title = "Farm",      icon = "solar:leaf-bold" },
		{ id = "Hatch",     title = "Hatch",     icon = "solar:confetti-bold" },
		{ id = "Elephant",  title = "Elephant",  icon = "solar:dumbbell-bold" },
		{ id = "Flow",      title = "Flow",      icon = "solar:branching-paths-up-bold" },
		{ id = "Leveling",  title = "Leveling",  icon = "solar:bolt-bold" },
		{ id = "Mutation",  title = "Mutation",  icon = "solar:test-tube-bold" },
		{ id = "Inventory", title = "Inventory", icon = "solar:backpack-bold" },
		{ id = "Shop",      title = "Shop",      icon = "solar:cart-bold" },
		{ id = "Misc",      title = "Misc",      icon = "solar:settings-bold" },
		{ id = "Settings",  title = "Settings",  icon = "solar:settings-minimalistic-bold" },
	}

	local first
	local buildT0 = os.clock()
	for i, def in ipairs(TABS) do
		local tab = window:Tab({
			Title = def.title,
			Desc = def.id,
			Icon = def.icon,
		})
		W.tabs[def.id] = tab

		-- bridge warisan buat app.lua (loop selectTab & auto-resume)
		ctx.ui.pages[def.id] = { Visible = false }
		ctx.ui.tabBtns[def.id] = {
			setActive = function(active)
				if active then pcall(function() tab:Select() end) end
			end,
		}

		if i == 1 then first = tab end

		if MIGRATED[def.id] then
			local t0 = os.clock()
			local ok, err = pcall(MIGRATED[def.id], tab)
			ctx.log(("[pages] tab %s dibangun (%.0f ms)"):format(def.id, (os.clock() - t0) * 1000))
			if not ok then
				ctx.log("build tab " .. def.id .. " gagal: " .. tostring(err))
				pcall(function()
					tab:Paragraph({
						Title = "Tab Failed To Build",
						Desc = tostring(err),
					})
				end)
			end
		else
			tab:Paragraph({
				Title = "Not Migrated Yet",
				Desc = "Tab '" .. def.id .. "' still runs in the old build (Pink Royale). Migration to WindUI goes one tab at a time; this tab is next.",
			})
			tab:Paragraph({
				Title = "Feature Status",
				Desc = "Feature logic stays LOADED (CFG, persistence, auto-resume). Only the control panel has not moved yet.",
			})
		end
	end
	ctx.log(("[pages] total build UI (%.0f ms)"):format((os.clock() - buildT0) * 1000))

	----------------------------------------------------------------- default tab (pilot)
	pcall(function() if first and first.Select then first:Select() end end)

	-- PRE-WARM cache dropdown (NO-UI): snapshot data semua dropdown dinamis
	-- pas boot (beberapa kali buat kejar data game yang lambat masuk) + tiap
	-- 4 menit biar cache gak pernah dingin. Baris dropdown tetap dibangun saat
	-- menu pertama dibuka — pre-build ratusan baris UI di background = frame
	-- drop (udah dicoba, tau rasanya).
	task.spawn(function()
		local function warm()
			for _, w in ipairs(W.ddWarmers or {}) do pcall(w) end
		end
		task.wait(1.5); warm()
		task.wait(15);   warm()
		task.wait(45);   warm()
		while ctx.alive() do
			task.wait(240)
			if ctx.alive() then warm() end
		end
	end)

	ctx.log("WindUI pages dibangun: SEMUA TAB (Pet, Farm, Hatch, Elephant, Flow, Leveling, Mutation, Inventory, Shop, Misc, Settings).")
end
