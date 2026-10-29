--[[ flow_notify.lua — Notif pojok kanan bawah tiap fitur pindah ke tahap/flow berikutnya.
     Satu tempat buat SEMUA fitur: mantau field status yang udah ditulis tiap modul
     (ctx.state.*Status + ctx.setStatus) dan munculin notif WindUI pas tahapnya ganti.
     - Angka di-strip pas bandingin, jadi countdown / "3/5 aktif" nggak nyepam.
     - Per fitur min 2.5 s antar notif.
     - Pesan yang cuma "detak" (PnP narik, countdown GM, placing x/y, dst.) di-skip.
     Toggle: CFG.flowNotifyEnabled (Settings > General). Notif khusus (mis. Blessing gajah)
     panggil ctx.flowNotify(title, msg) langsung. ]]
return function(ctx)
	local CFG = ctx.CFG
	if CFG.flowNotifyEnabled == nil then CFG.flowNotifyEnabled = true end

	local FIELDS = {
		{ key = "hatchStatus",      title = "Hatch" },
		{ key = "elephantStatus",   title = "Elephant V1" },
		{ key = "elephantV2Status", title = "Elephant V2" },
		{ key = "levelingStatus",   title = "Leveling V1" },
		{ key = "levelingV2Status", title = "Leveling V2" },
		{ key = "growthStatus",     title = "Flow" },
		{ key = "mutationStatus",   title = "Mutation Machine" },
		{ key = "fsStatus",         title = "Status" },
	}

	-- detak rutin, bukan pindah tahap
	local SKIP = {
		"^pnp v1", "gm sprinkler: %d+s left", "^placing", "^boost%.%.%.", "nunggu egg ready",
		"auto collect: collect", "^idle$", "loading", "^%s*$",
	}

	local function norm(s)
		s = tostring(s or ""):lower()
		s = s:gsub("%d+%.?%d*", "#"):gsub("%s+", " ")
		return s
	end
	local function skipped(s)
		local low = tostring(s or ""):lower()
		for _, p in ipairs(SKIP) do if low:find(p) then return true end end
		return false
	end

	local lastSent = {} -- title -> os.clock()
	function ctx.flowNotify(title, msg, dur)
		if not CFG.flowNotifyEnabled then return end
		local now = os.clock()
		if lastSent[title .. "|" .. tostring(msg)] and now - lastSent[title .. "|" .. tostring(msg)] < 2 then return end
		lastSent[title .. "|" .. tostring(msg)] = now
		if ctx.wi and ctx.wi.notify then ctx.wi.notify(title, msg, dur or 4) end
		if ctx.log then ctx.log(("[%s] %s"):format(title, tostring(msg))) end
	end

	local lastNorm, lastAt = {}, {}
	local function check(id, title, value)
		if value == nil then return end
		local n = norm(value)
		if lastNorm[id] == nil then lastNorm[id] = n; return end -- baseline pas load, jangan notif
		if n == lastNorm[id] then return end
		lastNorm[id] = n
		if skipped(value) then return end
		local now = os.clock()
		if now - (lastAt[id] or 0) < 2.5 then return end
		lastAt[id] = now
		ctx.flowNotify(title, tostring(value))
	end

	task.spawn(function()
		while ctx.alive() do
			pcall(function()
				if CFG.flowNotifyEnabled then
					local st = ctx.state
					for _, f in ipairs(FIELDS) do check(f.key, f.title, st[f.key]) end
					-- status umum (ctx.setStatus): judul = teks sebelum ":" kalau ada
					local sv = st.statusValue
					if sv then
						local head, rest = tostring(sv):match("^([^:]+):%s*(.+)$")
						check("statusValue:" .. (head or "?"), head or "Status", rest and sv or sv)
					end
				end
			end)
			task.wait(0.5)
		end
	end)
end
