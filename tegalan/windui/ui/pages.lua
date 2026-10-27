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
					W.notify(notifyTitle, title .. " ➔ " .. (v and "ON" or "OFF"))
				end
				if ctx.log then ctx.log(title .. " ➔ " .. (v and "ON" or "OFF")) end
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

	-- Single dropdown: opsi bisa string atau {name=, display=}; snapshot saat build
	-- + refresh() buat dipanggil ulang (WindUI Dropdown punya :Refresh).
	local function makeSingleW(parent, title, desc, getOptions, getv, setv)
		local d2v, v2d = {}, {}
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
		local displays, selected = snapshot()
		local control = parent:Dropdown({
			Title = title,
			Desc = desc,
			Values = displays,
			Value = selected,
			AllowNone = true,
			Callback = safe(function(d)
				setv(d2v[d] or d)
				persist()
			end),
		})
		return control, function()
			task.spawn(function()
				local ds, sel2 = snapshot()
				pcall(function() control:Refresh(ds) end)
				pcall(function() control:Select(sel2) end)
			end)
		end
	end

	-- Multi dropdown dinamis (pet team dll): opsi {value=, display=}, selSet keyed value.
	-- Tampilan: display dipecah "Nama | detail" -> opsi WindUI {Title=nama, Desc=detail},
	-- 2 baris, Desc TextWrapped bawaan dist -> nama pet SELALU kebaca utuh.
	-- SearchBarEnabled = search bawaan dist (filter Title, case-insensitive substring).
	-- MenuWidth 300 + patch UISizeConstraint (bawaan dist membatasi 300x400).
	-- Value/persist tetap keyed uuid (t.v) — bentuk state lama tidak berubah.
	local function makeMultiDynW(parent, title, desc, getOptions, selSet, onChange, opts)
		opts = opts or {}
		local function splitDisplay(d)
			d = tostring(d or "")
			local cut = d:find(" | ", 1, true)
			if cut then return d:sub(1, cut - 1), d:sub(cut + 3) end
			return d, nil
		end
		local function snapshot()
			local list, displays, selected = {}, {}, {}
			pcall(function()
				list = getOptions() or {}
			end)
			for _, o in ipairs(list) do
				local t, rest = splitDisplay(o.display)
				displays[#displays + 1] = { Title = t, Desc = rest, v = o.value }
				if selSet[o.value] then selected[#selected + 1] = t end
			end
			return displays, selected
		end
		local displays, selected = snapshot()
		local control = parent:Dropdown({
			Title = title,
			Desc = desc,
			Values = displays,
			Multi = true,
			AllowNone = true,
			SearchBarEnabled = true,
			MenuWidth = 240,
			Value = selected,
			Callback = safe(function(sel)
				if type(sel) == "string" then sel = { sel } end
				for k in pairs(selSet) do selSet[k] = nil end
				for _, t in ipairs(sel or {}) do
					local v = (type(t) == "table") and t.v or nil
					if v then selSet[v] = true end
				end
				persist()
				if onChange then onChange() end
			end),
		})
		-- Constraint menu bawaan dist 300x400 -> pas dengan rumus MenuCanvas dist
		-- (MenuWidth + 6+6+5+5+18+6+6 = +52). Refresh tidak menimpanya (constraint
		-- bukan anak ScrollingFrame).
		task.spawn(function()
			local mc = control and control.UIElements and control.UIElements.MenuCanvas
			local c = mc and mc:FindFirstChildOfClass("UISizeConstraint")
			if c then c.MaxSize = Vector2.new(292, 440) end
		end)
		-- Dist tidak set TextWrapped di Title opsi (overflow -> kepotong). Nama
		-- panjang dibikin wrap 2 baris; baris opsi sendiri AutomaticSize=Y (dist).
		local function wrapTitles()
			local sf = control and control.UIElements and control.UIElements.Menu
				and control.UIElements.Menu:FindFirstChild("Frame")
				and control.UIElements.Menu.Frame:FindFirstChild("ScrollingFrame")
			for _, opt in ipairs(sf and sf:GetChildren() or {}) do
				local tf = opt:FindFirstChild("Title", true)
				local tl = tf and tf:FindFirstChildOfClass("TextLabel")
				if tl then tl.TextWrapped = true end
			end
		end
		wrapTitles()
		local function refresh()
			task.spawn(function()
				local ds, sel2 = snapshot()
				pcall(function() control:Refresh(ds) end)
				pcall(function() control:Select(sel2) end)
				wrapTitles()
			end)
		end
		if opts.register then
			W.refreshers[#W.refreshers + 1] = refresh
		end
		return control, refresh
	end

	-- Multi dropdown statis (reg.PET_OPTIONS dll): opsi string, selSet keyed string.
	local function makeMultiW(parent, title, desc, options, selSet, onChange)
		local control = parent:Dropdown({
			Title = title,
			Desc = desc,
			Values = options,
			Multi = true,
			AllowNone = true,
			Value = (function()
				local out = {}
				for _, o in ipairs(options) do
					if selSet[o] then out[#out + 1] = o end
				end
				return out
			end)(),
			Callback = safe(function(sel)
				if type(sel) == "string" then sel = { sel } end
				for k in pairs(selSet) do selSet[k] = nil end
				for _, d in ipairs(sel or {}) do selSet[d] = true end
				persist()
				if onChange then onChange() end
			end),
		})
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

	-- (hrow/HStack dibuang: element WindUI ngelewat padding halaman -> bar kepotong kanan)

	----------------------------------------------------------------- TAB: PET (pilot — PnP V1/V2 + Boost)
	local v2Ctrl -- sync mutual exclusion

	local function buildPetTab(tab)
	-- Mini-tab [Pickup V1][Pickup V2][Boost]: native, ukuran beku.
	-- WindUI Button + SetTitle nambah "▸ " -> panjang teks beda -> label wrap -> bar melar
	-- (tab "ga solid"). Bar Roblox polos: parent SAMA dgn card sections -> padding halaman
	-- kebaca identik, lebar fix 1/3 per tombol, status aktif via warna (teks ga pernah diubah).
	local DEFS = {
		v1    = { name = "Pickup V1" },
		v2    = { name = "Pickup V2" },
		boost = { name = "Boost" },
	}
	local ORDER = { "v1", "v2", "boost" }
	local secs = {}

	local function miniTab(id, buildFn)
		local sec = section(tab, DEFS[id].name)
		buildFn(sec)
		secs[id] = sec
	end

		local function addRefresh(sec)
			sec:Button({
				Title = "Update Pet List",
				Desc = "Baca ulang inventory — refresh dropdown dinamis",
				Callback = safe(function()
					for _, fn in ipairs(W.refreshers) do
						pcall(fn)
					end
					ctx.log("Pet list di-refresh.")
				end),
			})
		end

		--------------------------------------------------- panel 1: Pickup Pet V1
		miniTab("v1", function(sec)
			makeMultiDynW(sec, "Select Pets for Pickup [V1]",
				"Pilih pet dari backpack (kosong = semua yg di garden)",
				function() return ctx.inventoryPetOptions(CFG.pnpUuids) end,
				CFG.pnpUuids, function() persist() end, { register = true })
			makeInputW(sec, "Pickup Delay (sec)", "Jeda tiap siklus (idealnya = saat skill ready)",
				function() return CFG.pickupDelay end,
				function(t) CFG.pickupDelay = tonumber(t) or 0.3 end)
			makeInputW(sec, "Equip Delay (sec)", "Jeda unequip -> equip (1E-20 = near-instant)",
				function()
					if CFG.equipDelay == 1e-20 or CFG.equipDelay == 0 or not CFG.equipDelay then return "1E-20" end
					return tostring(CFG.equipDelay)
				end,
				function(t)
					if tostring(t):upper():find("1E%-20") then
						CFG.equipDelay = 1e-20
					else
						CFG.equipDelay = tonumber(t) or 1e-20
					end
				end)
			makeInputW(sec, "Scan Interval (sec)", "Frekuensi cek cooldown (min 0.01)",
				function() return CFG.pnpScanInterval end,
				function(t) CFG.pnpScanInterval = math.max(0.01, tonumber(t) or 0.05) end)
			makeToggleW(sec, "Enable Automation Pickup V1",
				"Polling GetPetCooldown (lama). Nyalain ini matiin V2.",
				function() return CFG.pnpEnabled end,
				function(v)
					CFG.pnpEnabled = v; persist()
					if v then
						CFG.pnpV2Enabled = false; persist()
						if ctx.stopPnpV2 then pcall(function() ctx.stopPnpV2() end) end
						if v2Ctrl then pcall(function() v2Ctrl:Set(false) end) end
						if ctx.startPnpV1 then pcall(function() ctx.startPnpV1() end) end
					else
						if ctx.stopPnpV1 then pcall(function() ctx.stopPnpV1() end) end
					end
				end)
			addRefresh(sec)
		end)

		--------------------------------------------------- panel 2: Pickup Pet V2
		miniTab("v2", function(sec)
			makeMultiDynW(sec, "Select Pets for Pickup [V2]",
				"Pilih pet dari backpack (kosong = semua yg di garden)",
				function() return ctx.inventoryPetOptions(CFG.pnpV2Uuids) end,
				CFG.pnpV2Uuids, function() persist() end, { register = true })
			makeInputW(sec, "Pickup Delay (sec)", "Jeda sebelum tiap pickup",
				function() return CFG.pnpV2PickupDelay end,
				function(t) CFG.pnpV2PickupDelay = tonumber(t) or 0.05 end)
			makeInputW(sec, "Equip Delay (sec)", "Jeda antara unequip -> equip",
				function() return CFG.pnpV2EquipDelay end,
				function(t) CFG.pnpV2EquipDelay = tonumber(t) or 0.03 end)
			makeInputW(sec, "Scan Interval (sec)", "Frekuensi cek cd dari cache event (min 0.02)",
				function() return CFG.pnpV2ScanInterval end,
				function(t) CFG.pnpV2ScanInterval = math.max(0.02, tonumber(t) or 0.05) end)
			v2Ctrl = makeToggleW(sec, "Enable Automation Pickup V2",
				"Event-driven (PetCooldownsUpdated), stabil. Nyalain ini matiin V1.",
				function() return CFG.pnpV2Enabled end,
				function(v)
					CFG.pnpV2Enabled = v; persist()
					if v then
						CFG.pnpEnabled = false; persist()
						if ctx.stopPnpV1 then pcall(function() ctx.stopPnpV1() end) end
						if ctx.startPnpV2 then pcall(function() ctx.startPnpV2() end) end
					else
						if ctx.stopPnpV2 then pcall(function() ctx.stopPnpV2() end) end
					end
				end)
			addRefresh(sec)
		end)

		--------------------------------------------------- panel 3: Boost Pet
		miniTab("boost", function(sec)
			makeMultiDynW(sec, "Select Pets to Boost", "Pet yang mau di-boost (aktif di garden)",
				function() return ctx.inventoryPetOptions(CFG.boostPetUuids) end,
				CFG.boostPetUuids, function() persist() end, { register = true })
			makeMultiDynW(sec, "Select Boost Items", "Item boost (Pet Toy) yang dipakai",
				function() return ctx.getBoostItemOptions(CFG.boostItemNames) end,
				CFG.boostItemNames, function() persist() end, { register = true })
			makeToggleW(sec, "Enable Automation Boost",
				"Auto apply boost item ke pet, re-apply pas boost habis",
				function() return CFG.boostEnabled end,
				function(v)
					CFG.boostEnabled = v; persist()
					if v and ctx.startBoostPet then pcall(function() ctx.startBoostPet() end) end
				end)
			addRefresh(sec)
		end)

		--------------------------------------------------- mini-tab bar (native, ukuran beku)
		-- Parent = parent card sections (ContainerFrame, padding halaman sama) ->
		-- lebar bar PERSIS selebar cards. SortOrder kontainer = LayoutOrder + semua
		-- element WindUI LayoutOrder 0 -> -1000 dipastikan row pertama.
		-- Warna dari theme WindUI langsung (GetThemes), fallback konstanta Dark.
		-- JANGAN baca Outline.BackgroundColor3: konstanta theme "Outline" = #FFFFFF,
		-- ThemeTag-nya belum di-apply pas tab dibangun -> bar nyala putih.
		local container = secs.v1.ElementFrame.Parent
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
		bar.Name = "PetMiniTabs"
		bar.LayoutOrder = -1000
		bar.Size = UDim2.new(1, 0, 0, 40)
		bar.BackgroundColor3 = pillBg
		bar.Parent = container
		Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 10)

		local row = Instance.new("UIListLayout")
		row.FillDirection = Enum.FillDirection.Horizontal
		row.Padding = UDim.new(0, 6)
		row.SortOrder = Enum.SortOrder.LayoutOrder
		row.VerticalAlignment = Enum.VerticalAlignment.Center
		row.Parent = bar

		local btns = {}
		local function paint(id, on)
			local b = btns[id]
			b.BackgroundColor3 = activeBg
			b.BackgroundTransparency = on and 0 or 1
			b.TextColor3 = on and ((cur and cur.Text) or Color3.fromRGB(255, 255, 255)) or txth
		end

		for i, id in ipairs(ORDER) do
			local b = Instance.new("TextButton")
			b.Name = "Tab_" .. id
			b.LayoutOrder = i
			b.Size = UDim2.new(1 / 3, -4, 1, -8)
			b.AutoButtonColor = false
			b.BackgroundTransparency = 1
			b.Text = DEFS[id].name
			b.TextTruncate = Enum.TextTruncate.AtEnd
			b.TextSize = 14
			b.Font = Enum.Font.GothamMedium
			Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
			b.Parent = bar
			btns[id] = b
		end

		local function selectPanel(id)
			for pid, sec in pairs(secs) do
				pcall(function() sec.ElementFrame.Visible = (pid == id) end)
			end
			for _, pid in ipairs(ORDER) do paint(pid, pid == id) end
		end
		for _, id in ipairs(ORDER) do
			btns[id].Activated:Connect(function() selectPanel(id) end)
		end

		-- Ukuran section dist dipin manual (Open/Close = snapshot Top+Contentpx).
		-- Kalau pin kebaca sebelum layout jalan -> pin kecil -> konten ter-clip
		-- (panel "kosong", kasus V1/V2). Matikan mode expandable + force auto-size:
		-- section selalu sebesar konten, Open/Close dist jadi no-op permanen.
		local function unlockSize()
			for _, id in ipairs(ORDER) do
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

		selectPanel("v1")
	end

	----------------------------------------------------------------- REGISTRY TAB
	-- Urutan sesuai Pink Royale. build = nil -> placeholder (belum dimigrasi).
	local MIGRATED = {
		Pet = buildPetTab,
		-- berikutnya: Inventory, Misc, Farm, Hatch, ... (satu per satu)
	}

	local TABS = {
		{ id = "Pet",       title = "Pet",       icon = "solar:cat-bold" },
		{ id = "Farm",      title = "Farm",      icon = "solar:leaf-bold" },
		{ id = "Hatch",     title = "Hatch",     icon = "solar:egg-bold" },
		{ id = "Elephant",  title = "Elephant",  icon = "solar:wild-animal-bold" },
		{ id = "Flow",      title = "Flow",      icon = "solar:flow-square-bold" },
		{ id = "Leveling",  title = "Leveling",  icon = "solar:bolt-bold" },
		{ id = "Mutation",  title = "Mutation",  icon = "solar:flask-bold" },
		{ id = "Inventory", title = "Inventory", icon = "solar:backpack-bold" },
		{ id = "Shop",      title = "Shop",      icon = "solar:cart-bold" },
		{ id = "Misc",      title = "Misc",      icon = "solar:settings-bold" },
	}

	local first
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
			local ok, err = pcall(MIGRATED[def.id], tab)
			if not ok then
				ctx.log("build tab " .. def.id .. " gagal: " .. tostring(err))
				pcall(function()
					tab:Paragraph({
						Title = "Tab gagal dibangun",
						Desc = tostring(err),
					})
				end)
			end
		else
			tab:Paragraph({
				Title = "Belum dimigrasi",
				Desc = "Tab '" .. def.id .. "' masih jalan di build lama (Pink Royale). Migrasi tab-per-tab ke WindUI — tab ini menyusul.",
			})
			tab:Paragraph({
				Title = "Status fitur",
				Desc = "Logika fitur TETAP LOADED (CFG, persistence, auto-resume). Cuma panel kontrol-nya yang belum pindah.",
			})
		end
	end

	----------------------------------------------------------------- default tab (pilot)
	pcall(function() if first and first.Select then first:Select() end end)

	ctx.log("WindUI pages dibangun: Pet (pilot) + 9 placeholder.")
end
