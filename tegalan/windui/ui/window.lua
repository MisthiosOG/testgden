--[[ window.lua — jendela utama WINDUI build (tab-per-tab migration).
     UI = WindUI 1.6.66 (rilis yang sama dengan trade/, sudah teruji).
     Tidak ada shim/compat layer: pages.lua memakai ctx.wi.* langsung.
     Jembatan warisan untuk app.lua: ctx.ui.pages / ctx.ui.tabBtns (tabel dummy). ]]
return function(ctx)
	local UserInputService = ctx.Services.UserInputService

	----------------------------------------------------------------- bersihkan GUI lama
	pcall(function()
		local host = (gethui and gethui()) or game:GetService("CoreGui")
		for _, nm in ipairs({ "GAGGarden", "CeszParadiseGarden", "AllegiaanGarden" }) do
			local old = host:FindFirstChild(nm)
			if old then old:Destroy() end
			local pg = ctx.LP:FindFirstChild("PlayerGui")
			if pg and pg:FindFirstChild(nm) then pg[nm]:Destroy() end
		end
	end)

	----------------------------------------------------------------- load WindUI
	-- Lib di-vendor ke repo (patched: drag pakai Position langsung, bukan
	-- Tween per mousemove — versi upstream bikin window nge-lag saat digeser).
	-- Fallback: rilis upstream Footagesus kalau raw repo gagal.
	local compile = loadstring or load
	local LIB_URLS = {
		"https://raw.githubusercontent.com/MisthiosOG/testgden/main/tegalan/windui/lib/windui-1.6.66.lua",
		"https://github.com/Footagesus/WindUI/releases/download/1.6.66/main.lua",
	}
	local WindUI, errLib
	for _, libUrl in ipairs(LIB_URLS) do
		local ok = pcall(function()
			WindUI = compile(game:HttpGet(libUrl))()
		end)
		if ok and WindUI and WindUI.CreateWindow then break end
		WindUI = nil
	end
	if not (WindUI and WindUI.CreateWindow) then
		warn("[WindUIHub] gagal load WindUI library: " .. tostring(errLib))
		error("[WindUIHub] WindUI failed to load — hub berhenti.", 0)
	end

	----------------------------------------------------------------- window
	local window = WindUI:CreateWindow({
		Title = "Dopamine | P².Achieve",
		Icon = "solar:planet-3-bold-duotone",
		Folder = "CeszParadiseWindUI",
		Size = UDim2.fromOffset(720, 520),
		NewElements = true,
		ToggleKey = Enum.KeyCode.K,
		OpenButton = {
			Enabled = true,
			OnlyMobile = false,
			Draggable = true,
			-- Ikon doang (bulat kecil) + outline solid tipis — gradient
			-- pink-biru default WindUI-nya yang norak, jadi di-reset solid.
			Title = "Dopamine | P².Achieve",
			Icon = "solar:planet-3-bold-duotone",
			OnlyIcon = true,
			CornerRadius = UDim.new(1, 0),
			StrokeThickness = 1.4,
			Color = ColorSequence.new(Color3.fromHex("#666666")),
		},
	})

	ctx.wi = {
		windui = WindUI,
		window = window,
		tabs   = {},   -- id -> WindUI tab object
		refreshers = {}, -- fungsi refresh dropdown dinamis (dipanggil tombol List refresh)
	}

	-- Bridge warisan buat app.lua (loop selectTab default + auto-resume):
	-- app.lua lama iterasi pages (set .Visible) & tabBtns (setActive) — dummy supaya aman.
	ctx.ui.pages   = {}
	ctx.ui.tabBtns = {}

	ctx.state.isAlive = true
	-- Badge bawah judul: build stage, bukan rev (rev masih ada di log & config).
	pcall(function()
		window:Tag({
			Title = "Beta Test",
			Icon = "solar:rocket-bold",
		})
	end)

	----------------------------------------------------------------- logger
	local logLines = ctx.state.logLines
	function ctx.log(msg)
		table.insert(logLines, os.date("%H:%M:%S ") .. msg)
		while #logLines > 50 do table.remove(logLines, 1) end
		print("[WindUIHub] " .. tostring(msg))
	end

	----------------------------------------------------------------- status (footer legacy — cukup log; UI status bakal jadi Paragraph per tab)
	function ctx.setStatus(s)
		local isActive = tostring(s):lower():find("active") ~= nil
			or tostring(s):lower():find("jalan") ~= nil
		ctx.state.statusValue = tostring(s)
		ctx.state.statusActive = isActive
	end

	----------------------------------------------------------------- API helper global buat pages.lua
	-- wrap callback: semua callback user di-pcall supaya 1 bug fitur ga bikin UI mati.
	function ctx.wi.toggle(tab, opts)
		return tab:Toggle(opts)
	end
	function ctx.wi.notify(title, content, dur)
		pcall(function()
			WindUI:Notify({
				Title = tostring(title),
				Content = tostring(content or ""),
				Duration = tonumber(dur) or 4,
			})
		end)
	end

	print("[WindUIHub] window ready (WindUI " .. tostring(WindUI.Version or "1.6.66") .. ")")
	ctx.log("CeszParadiseHub WindUI window siap.")
end
