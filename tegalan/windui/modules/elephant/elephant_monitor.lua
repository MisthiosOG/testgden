--[[ elephant_monitor.lua — Monitor injek gajah per pet target.
     Skill gajah nambah BaseWeight pet +0.1 KG per skill. BaseWeight nggak berubah karena
     age (berat tampil = BaseWeight * (1 + 0.1*age)), jadi tiap kenaikan BaseWeight = injek gajah.
     Hitungan: injek = round(kenaikan / 0.1). Dicatat per uuid, awet antar re-execute (getgenv).
     Fungsi: ctx.elephantMonitorText(typeSet, targetWeight) -> teks buat liveStatus,
             ctx.resetElephantMonitor(). ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local STEP = 0.1 -- KG per skill gajah

	local g = (getgenv and getgenv()) or _G
	g.__elephantMon = g.__elephantMon or {}
	local mon = g.__elephantMon -- uuid -> { startW, lastW, hits, lastAt }

	local function snapshot()
		local ok, d = pcall(function() return DataService:GetData() end)
		local pd = ok and d and d.PetsData
		if not pd then return nil, nil end
		return pd.EquippedPets or {}, (pd.PetInventory and pd.PetInventory.Data) or {}
	end

	-- Sampling 1 detik: cuma pet yang lagi di kebun (yang bisa kena skill gajah).
	g.__elephantMonGen = (g.__elephantMonGen or 0) + 1
	local myGen = g.__elephantMonGen
	task.spawn(function()
		while ctx.alive() and g.__elephantMonGen == myGen do
			pcall(function()
				local eq, inv = snapshot()
				if not eq then return end
				for _, uuid in ipairs(eq) do
					local p = inv[uuid]
					local w = p and p.PetData and tonumber(p.PetData.BaseWeight)
					if w then
						local m = mon[uuid]
						if not m then
							mon[uuid] = { startW = w, lastW = w, hits = 0, lastAt = 0 }
						elseif w > m.lastW + 1e-4 then
							local n = math.floor((w - m.lastW) / STEP + 0.5)
							m.hits = m.hits + math.max(1, n)
							m.lastW, m.lastAt = w, os.clock()
						elseif w < m.lastW - 1e-4 then
							m.lastW = w -- berat turun (data aneh) -> ikutin, jangan hitung
						end
					end
				end
			end)
			task.wait(1)
		end
	end)

	local function matches(typeSet, p)
		if not typeSet or not next(typeSet) then return false end
		if ctx.petMatchesType then return ctx.petMatchesType(typeSet, p.PetType, p.PetData) end
		return typeSet[p.PetType] == true
	end

	function ctx.elephantMonitorText(typeSet, targetW)
		local eq, inv = snapshot()
		if not eq then return nil end
		targetW = tonumber(targetW) or 5.5
		local lines, total = {}, 0
		for _, uuid in ipairs(eq) do
			local p = inv[uuid]
			if p and matches(typeSet, p) then
				local pd = p.PetData or {}
				local w = tonumber(pd.BaseWeight) or 0
				local m = mon[uuid] or { startW = w, hits = 0, lastAt = 0 }
				total = total + m.hits
				local left = math.max(0, math.ceil((targetW - w) / STEP - 1e-6))
				local ago = (m.lastAt > 0) and ("%ds lalu"):format(math.floor(os.clock() - m.lastAt)) or "-"
				lines[#lines + 1] = ("<b>%s</b> #%s | Age %s\n" ..
					"  %.2f → <font color=\"#f5c82d\">%.2f KG</font> | injek <font color=\"#5acc78\"><b>%dx</b></font>" ..
					" | sisa %dx | terakhir %s")
					:format(tostring(p.PetType), uuid:sub(2, 5), tostring(pd.Level or 0),
						m.startW, w, m.hits, left, ago)
			end
		end
		if #lines == 0 then return "Belum ada pet target di kebun." end
		return ("Total injek (pet di kebun): <b>%dx</b>\n\n"):format(total) .. table.concat(lines, "\n")
	end

	function ctx.resetElephantMonitor()
		for k in pairs(mon) do mon[k] = nil end
	end
end
