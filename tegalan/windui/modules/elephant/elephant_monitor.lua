--[[ elephant_monitor.lua — Monitor Blessing gajah per pet target.
     Skill gajah nambah BaseWeight pet +0.1 KG per skill (= 1 Blessing). BaseWeight nggak berubah
     karena age (berat tampil = BaseWeight * (1 + 0.1*age)), jadi tiap kenaikan = Blessing.
     Dicatat per uuid (awet antar re-execute via getgenv):
       - waktu masuk kebun, Blessing pertama, Blessing terakhir
       - SELESAI pas berat >= Target Weight atau pet keluar kebun setelah dapet Blessing
       - riwayat pet yang udah selesai (#1, #2, ...) + durasinya
     Notif (ctx.flowNotify) tiap Blessing & tiap pet selesai.
     Fungsi: ctx.elephantMonitorText(typeSet, targetWeight), ctx.resetElephantMonitor(). ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local CFG = ctx.CFG
	local STEP = 0.1 -- KG per Blessing

	local g = (getgenv and getgenv()) or _G
	if type(g.__elephantMon2) ~= "table" then g.__elephantMon2 = { pets = {}, done = {}, seq = 0 } end
	local M = g.__elephantMon2
	-- pets[uuid] = { petType, startW, lastW, hits, enterAt, firstAt, lastAt }
	-- done[i]    = { n, uuid, petType, startW, endW, hits, secs, reason, at }

	local function snapshot()
		local ok, d = pcall(function() return DataService:GetData() end)
		local pd = ok and d and d.PetsData
		if not pd then return nil, nil end
		return pd.EquippedPets or {}, (pd.PetInventory and pd.PetInventory.Data) or {}
	end

	local function fmtDur(s)
		s = math.max(0, math.floor(s or 0))
		if s >= 3600 then return ("%dj %02dm %02ds"):format(s // 3600, (s % 3600) // 60, s % 60) end
		return ("%dm %02ds"):format(s // 60, s % 60)
	end

	local function matches(typeSet, petType, petData)
		if not typeSet or not next(typeSet) then return false end
		if ctx.petMatchesType then return ctx.petMatchesType(typeSet, petType, petData) end
		return typeSet[petType] == true
	end

	-- target aktif: pet ini kebaca target di V1/V2 yang lagi nyala?
	local function targetWeightFor(petType, petData)
		if CFG.elephantV2Enabled and matches(CFG.elephantV2Types, petType, petData) then
			return tonumber(CFG.elephantV2Weight) or 5.5
		end
		if CFG.elephantEnabled and matches(CFG.elephantPetTypes, petType, petData) then
			return tonumber(CFG.elephantTargetWeight) or 5.5
		end
		return nil
	end

	local function finish(uuid, m, endW, reason)
		M.seq = M.seq + 1
		local secs = os.time() - (m.firstAt or m.enterAt or os.time())
		table.insert(M.done, 1, {
			n = M.seq, uuid = uuid, petType = m.petType, startW = m.startW, endW = endW,
			hits = m.hits, secs = secs, reason = reason, at = os.time(),
		})
		while #M.done > 15 do table.remove(M.done) end
		if ctx.flowNotify then
			ctx.flowNotify("Elephant", ("Pet #%d selesai: %s %.2f → %.2f KG | %d Blessing | %s")
				:format(M.seq, tostring(m.petType), m.startW, endW, m.hits, fmtDur(secs)), 6)
		end
		M.pets[uuid] = nil
	end

	-- Sampling 1 detik: pet yang lagi di kebun (yang bisa kena skill gajah).
	g.__elephantMonGen = (g.__elephantMonGen or 0) + 1
	local myGen = g.__elephantMonGen
	task.spawn(function()
		while ctx.alive() and g.__elephantMonGen == myGen do
			pcall(function()
				local eq, inv = snapshot()
				if not eq then return end
				local now, inGarden = os.time(), {}
				for _, uuid in ipairs(eq) do
					inGarden[uuid] = true
					local p = inv[uuid]
					local pd = p and p.PetData
					local w = pd and tonumber(pd.BaseWeight)
					if w then
						local m = M.pets[uuid]
						if not m then
							M.pets[uuid] = { petType = p.PetType, startW = w, lastW = w, hits = 0, enterAt = now }
						elseif w > m.lastW + 1e-4 then
							local n = math.max(1, math.floor((w - m.lastW) / STEP + 0.5))
							m.hits = m.hits + n
							m.lastW, m.lastAt = w, now
							m.firstAt = m.firstAt or now
							if ctx.flowNotify then
								ctx.flowNotify("Elephant", ("Blessing #%d → %s (%.2f KG)"):format(m.hits, tostring(m.petType), w), 3)
							end
							local tw = targetWeightFor(p.PetType, pd)
							if tw and w >= tw - 1e-4 then finish(uuid, m, w, "target") end
						elseif w < m.lastW - 1e-4 then
							m.lastW = w -- data aneh -> ikutin, jangan hitung
						end
					end
				end
				-- pet keluar kebun: kalau udah dapet Blessing, catat selesai (dicabut elephant)
				for uuid, m in pairs(M.pets) do
					if not inGarden[uuid] then
						if m.hits > 0 then finish(uuid, m, m.lastW, "dicabut") else M.pets[uuid] = nil end
					end
				end
			end)
			task.wait(1)
		end
	end)

	function ctx.elephantMonitorText(typeSet, targetW)
		local eq, inv = snapshot()
		if not eq then return nil end
		targetW = tonumber(targetW) or 5.5
		local now = os.time()
		local lines, total = {}, 0
		for _, uuid in ipairs(eq) do
			local p = inv[uuid]
			if p and matches(typeSet, p.PetType, p.PetData) then
				local pd = p.PetData or {}
				local w = tonumber(pd.BaseWeight) or 0
				local m = M.pets[uuid] or { startW = w, hits = 0, enterAt = now }
				total = total + m.hits
				local left = math.max(0, math.ceil((targetW - w) / STEP - 1e-6))
				local ago = m.lastAt and (fmtDur(now - m.lastAt) .. " lalu") or "-"
				local run = fmtDur(now - (m.firstAt or m.enterAt or now))
				-- estimasi selesai dari rata-rata jeda Blessing (cuma ditampilin kalau datanya cukup)
				local eta = ""
				if m.hits >= 2 and m.firstAt and m.lastAt and m.lastAt > m.firstAt and left > 0 then
					local per = (m.lastAt - m.firstAt) / (m.hits - 1)
					eta = " (±" .. fmtDur(per * left) .. " lagi)"
				end
				lines[#lines + 1] = ("<b>%s</b> #%s | Age %s | jalan <b>%s</b>\n" ..
					"  %.2f → <font color=\"#f5c82d\">%.2f KG</font> | Blessing <font color=\"#5acc78\"><b>%dx</b></font>" ..
					" | sisa %dx%s | terakhir %s")
					:format(tostring(p.PetType), uuid:sub(2, 5), tostring(pd.Level or 0), run,
						m.startW, w, m.hits, left, eta, ago)
			end
		end
		local out = {}
		out[#out + 1] = ("Total Blessing (pet di kebun): <b>%dx</b>"):format(total)
		out[#out + 1] = #lines > 0 and table.concat(lines, "\n") or "Belum ada pet target di kebun."
		-- riwayat pet selesai
		local hist = {}
		for _, d in ipairs(M.done) do
			if #hist >= 8 then break end
			if matches(typeSet, d.petType) then
				hist[#hist + 1] = ("#%d %s | %.2f → %.2f KG | %dx Blessing | <b>%s</b> | %s | %s")
					:format(d.n, tostring(d.petType), d.startW, d.endW, d.hits, fmtDur(d.secs),
						d.reason == "target" and "target" or "dicabut", os.date("%H:%M", d.at))
			end
		end
		if #hist > 0 then
			out[#out + 1] = "\n<b>Selesai:</b>\n" .. table.concat(hist, "\n")
		end
		return table.concat(out, "\n\n")
	end

	function ctx.resetElephantMonitor()
		M.pets, M.done, M.seq = {}, {}, 0
	end
end
