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

	-- pcall+yield guard: kontrol banyak dibangun berurutan; melonggarkan tiap 8 elemen
	local buildCounter = 0
	local function breathe()
		buildCounter += 1
		if buildCounter % 8 == 0 then task.wait() end
	end

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
		breathe()
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
		breathe()
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
		breathe()
		return control, function()
			task.spawn(function()
				local ds, sel2 = snapshot()
				pcall(function() control:Refresh(ds) end)
				pcall(function() control:Select(sel2) end)
			end)
		end
	end

	-- Multi dropdown dinamis (pet team dll): opsi {value=, display=}, selSet keyed value.
	-- Refresh = re-snapshot opsi terkini dari inventory lalu :Refresh + :Select.
	local function makeMultiDynW(parent, title, desc, getOptions, selSet, onChange, opts)
		opts = opts or {}
		local d2v = {}
		local function snapshot()
			local list, displays, selected = {}, {}, {}
			pcall(function()
				list = getOptions() or {}
			end)
			table.clear(d2v)
			for _, o in ipairs(list) do
				local v, d = o.value, o.display
				d2v[d] = v
				displays[#displays + 1] = d
				if selSet[v] then selected[#selected + 1] = d end
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
			Value = selected,
			Callback = safe(function(sel)
				if type(sel) == "string" then sel = { sel } end
				for k in pairs(selSet) do selSet[k] = nil end
				for _, d in ipairs(sel or {}) do
					local v = d2v[d]
					if v then selSet[v] = true end
				end
				persist()
				if onChange then onChange() end
			end),
		})
		breathe()
		local function refresh()
			task.spawn(function()
				local ds, sel2 = snapshot()
				pcall(function() control:Refresh(ds) end)
				pcall(function() control:Select(sel2) end)
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
		breathe()
		return control
	end

	-- Section header polos: Box=false -> selalu kebuka, NOL klik.
	-- (Box=true bikin collapsible harus di-klik dulu — itu yang bikin kepanjangan.)
	local function section(tab, title, opened)
		return tab:Section({ Title = title, TextSize = 19 })
	end

	-- Row nyamping: HStack = anak-anak auto split lebar sama (horizontal).
	-- Fallback: kalau build WindUI ga punya HStack -> parent vertical biasa.
	local function hrow(parent)
		local ok, g = pcall(function() return parent:HStack({}) end)
		if ok and g then return g end
		return parent
	end

	----------------------------------------------------------------- TAB: PET (pilot — PnP V1/V2 + Boost)
	local v2Ctrl -- sync mutual exclusion

	local function buildPetTab(tab)
		--------------------------------------------------- mini-tab bar: [Pickup V1][Pickup V2][Boost]
		local bar = hrow(tab)
		local DEFS = {
			{ id = "v1",    name = "Pickup Pet V1" },
			{ id = "v2",    name = "Pickup Pet V2" },
			{ id = "boost", name = "Boost Pet" },
		}
		local secs, btns = {}, {}
		local function selectPanel(id)
			for pid, sec in pairs(secs) do
				if sec.ElementFrame then pcall(function() sec.ElementFrame.Visible = (pid == id) end) end
			end
			for pid, btn in pairs(btns) do
				pcall(function()
					btn:SetTitle((pid == id and "▸ " or "") .. DEFS[pid].name)
				end)
			end
		end

		local function miniTab(id, buildFn)
			btns[id] = bar:Button({
				Title = DEFS[id].name,
				Callback = safe(function() selectPanel(id) end),
			})
			breathe()
			local sec = section(tab, DEFS[id].name)
			buildFn(sec)
			secs[id] = sec
			breathe()
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
		breathe()
	end

	----------------------------------------------------------------- default tab (pilot)
	pcall(function() if first and first.Select then first:Select() end end)

	ctx.log("WindUI pages dibangun: Pet (pilot) + 9 placeholder.")
end
