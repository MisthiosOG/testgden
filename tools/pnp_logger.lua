--[[ pnp_logger.lua — DIAGNOSTIK pickup pet. Bukan fitur, cuma rekam data.
     Rekam dengan timestamp:
       CD   : perubahan cooldown pet (event PetCooldownsUpdated + polling GetPetCooldown)
       EQ   : perubahan daftar EquippedPets
       OUT  : remote yang DIKIRIM client soal pet (termasuk punya hub lain, mis. Pandora)
       IN   : semua RemoteEvent yang diterima dari server (buat nyari event "skill keluar")
     Hasil: file pnp_log.txt di folder workspace executor (+ clipboard kalau bisa).
     Durasi default 60 detik. Ubah: getgenv().PNPLOG_DURATION = 90 ]]

local DURATION = (getgenv and getgenv().PNPLOG_DURATION) or 60
local RS = game:GetService("ReplicatedStorage")
local GE = RS:WaitForChild("GameEvents")
local GetPetCooldown = GE:WaitForChild("GetPetCooldown")
local CdPush = GE:FindFirstChild("PetCooldownsUpdated")
local okDS, DataService = pcall(function() return require(RS.Modules.DataService) end)

local t0 = os.clock()
local lines = {}
local function log(s)
	s = ("%8.3f  %s"):format(os.clock() - t0, s)
	lines[#lines + 1] = s
	print("[PNPLOG] " .. s)
end

local function ser(v, depth)
	depth = depth or 0
	local t = typeof(v)
	if t == "string" then
		if #v >= 30 and v:find("^{") then return v:sub(2, 6) end -- uuid dipendekin
		return v
	elseif t == "number" then
		return (v % 1 == 0) and tostring(v) or ("%.2f"):format(v)
	elseif t == "Instance" then
		return "<" .. v.Name .. ">"
	elseif t == "CFrame" or t == "Vector3" then
		local p = (t == "CFrame") and v.Position or v
		return ("(%.0f,%.0f,%.0f)"):format(p.X, p.Y, p.Z)
	elseif t == "table" then
		if depth >= 3 then return "{..}" end
		local parts, n = {}, 0
		for k, val in pairs(v) do
			n = n + 1
			if n > 12 then parts[#parts + 1] = "..."; break end
			parts[#parts + 1] = (type(k) == "number" and "" or (tostring(k) .. "=")) .. ser(val, depth + 1)
		end
		return "{" .. table.concat(parts, ", ") .. "}"
	end
	return tostring(v)
end
local function serArgs(...)
	local out = {}
	for i = 1, select("#", ...) do out[#out + 1] = ser((select(i, ...))) end
	local s = table.concat(out, " | ")
	return #s > 400 and (s:sub(1, 400) .. "...") or s
end

local function cdStr(cd)
	if type(cd) ~= "table" then return tostring(cd) end
	local parts = {}
	for _, e in ipairs(cd) do
		parts[#parts + 1] = ("%s=%.2f"):format(tostring(e.Passive), tonumber(e.Time) or -1)
	end
	return #parts == 0 and "{kosong}" or table.concat(parts, ", ")
end

local conns, running = {}, true

-- CD via push event
local lastCd = {}
local function onCd(src, uuid, cd)
	local s = cdStr(cd)
	if lastCd[uuid] ~= s then
		lastCd[uuid] = s
		log(("CD   %-4s %s  %s"):format(src, ser(uuid), s))
	end
end
if CdPush then
	conns[#conns + 1] = CdPush.OnClientEvent:Connect(function(uuid, cd) onCd("push", uuid, cd) end)
else
	log("INFO PetCooldownsUpdated TIDAK ADA")
end

-- IN: semua RemoteEvent dari server (kecuali cd push, udah di atas). Rate-limit per remote.
-- ANIM: state animasi skill pet (DataStream ActivePetStates/.../CustomAnimationState), TANPA limit.
local inCount = {}
local DS = GE:FindFirstChild("DataStream")
if DS then
	local prefix = "ROOT/ActivePetStates/" .. game:GetService("Players").LocalPlayer.Name .. "/"
	conns[#conns + 1] = DS.OnClientEvent:Connect(function(kind, channel, list)
		if type(list) ~= "table" then return end
		for _, e in ipairs(list) do
			local path = type(e) == "table" and e[1]
			if type(path) == "string" and path:sub(1, #prefix) == prefix then
				local uuid, field = path:sub(#prefix + 1):match("^([^/]+)/([^/]+)$")
				if field == "CustomAnimationState" then
					log(("ANIM %s  '%s'"):format(ser(uuid), tostring(e[2] or "")))
				end
			end
		end
	end)
end
for _, r in ipairs(RS:GetDescendants()) do
	if r:IsA("RemoteEvent") and r ~= CdPush then
		local name = r:GetFullName():gsub("^ReplicatedStorage%.", "")
		conns[#conns + 1] = r.OnClientEvent:Connect(function(...)
			local sec = math.floor(os.clock())
			local c = inCount[name]
			if not c or c.sec ~= sec then c = { sec = sec, n = 0 }; inCount[name] = c end
			c.n = c.n + 1
			if c.n <= 5 then log(("IN   %s  %s"):format(name, serArgs(...))) end
		end)
	end
end

-- OUT: hook remote keluar yang berhubungan dengan pet
local selfCall = false
local oldNamecall
if hookmetamethod and getnamecallmethod then
	oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
		local m = getnamecallmethod()
		if running and (m == "FireServer" or m == "InvokeServer") and typeof(self) == "Instance" then
			if selfCall then
				selfCall = false
			elseif self.Name:find("Pet") then
				local msg = ("OUT  %s:%s  %s"):format(self.Name, m, serArgs(...))
				task.spawn(log, msg)
			end
		end
		return oldNamecall(self, ...)
	end))
else
	log("INFO executor tidak support hookmetamethod -> OUT tidak terekam")
end

-- MARK: tanda di atas pet (mis. "!" pas ready). Pantau model pet di workspace:
-- GUI/efek yang muncul/hilang, Visible/Enabled yang berubah, attribute model.
local LP = game:GetService("Players").LocalPlayer
local watched = {}
local markCount = {}
local function mlog(key, s)
	local sec = math.floor(os.clock())
	local c = markCount[key]
	if not c or c.sec ~= sec then c = { sec = sec, n = 0 }; markCount[key] = c end
	c.n = c.n + 1
	if c.n <= 4 then log(s) end
end
local function describe(d)
	local s = d.ClassName .. ":" .. d.Name
	pcall(function() if d:IsA("TextLabel") or d:IsA("TextButton") then s = s .. " text='" .. tostring(d.Text) .. "'" end end)
	pcall(function() if d:IsA("ImageLabel") or d:IsA("ImageButton") then s = s .. " img=" .. tostring(d.Image) end end)
	return s
end
local function isVisual(d)
	return d:IsA("BillboardGui") or d:IsA("GuiObject") or d:IsA("ParticleEmitter")
		or d:IsA("Highlight") or d:IsA("Beam") or d:IsA("Decal")
end
local function hookVis(pet, d)
	pcall(function()
		if d:IsA("BillboardGui") or d:IsA("ParticleEmitter") or d:IsA("Highlight") or d:IsA("Beam") then
			conns[#conns + 1] = d:GetPropertyChangedSignal("Enabled"):Connect(function()
				mlog(pet .. d.Name, ("MARK %s  %s Enabled=%s"):format(pet, describe(d), tostring(d.Enabled)))
			end)
		elseif d:IsA("GuiObject") then
			conns[#conns + 1] = d:GetPropertyChangedSignal("Visible"):Connect(function()
				mlog(pet .. d.Name, ("MARK %s  %s Visible=%s"):format(pet, describe(d), tostring(d.Visible)))
			end)
			if d:IsA("TextLabel") then
				conns[#conns + 1] = d:GetPropertyChangedSignal("Text"):Connect(function()
					mlog(pet .. d.Name .. "t", ("MARK %s  %s"):format(pet, describe(d)))
				end)
			end
		end
	end)
end
local function watchModel(m)
	if watched[m] then return end
	watched[m] = true
	local pet = ser(m.Name)
	log(("MARK %s  model %s di %s"):format(pet, m.ClassName, m.Parent and m.Parent:GetFullName() or "?"))
	for _, d in ipairs(m:GetDescendants()) do if isVisual(d) then hookVis(pet, d) end end
	conns[#conns + 1] = m.DescendantAdded:Connect(function(d)
		if isVisual(d) then
			mlog(pet .. "+" .. d.Name, ("MARK %s  +%s"):format(pet, describe(d)))
			hookVis(pet, d)
		end
	end)
	conns[#conns + 1] = m.DescendantRemoving:Connect(function(d)
		if d:IsA("BillboardGui") or d:IsA("Highlight") or d:IsA("ParticleEmitter") then
			mlog(pet .. "-" .. d.Name, ("MARK %s  -%s"):format(pet, describe(d)))
		end
	end)
	conns[#conns + 1] = m.AttributeChanged:Connect(function(a)
		mlog(pet .. "@" .. a, ("MARK %s  attr %s=%s"):format(pet, a, ser(m:GetAttribute(a))))
	end)
end
-- BillboardGui di PlayerGui yang nempel ke pet
pcall(function()
	local pg = LP:WaitForChild("PlayerGui", 5)
	if pg then
		conns[#conns + 1] = pg.DescendantAdded:Connect(function(d)
			if d:IsA("BillboardGui") then
				task.defer(function()
					local a = d.Adornee
					mlog("pg" .. d.Name, ("MARK pgui +Billboard %s adornee=%s"):format(d.Name, a and a:GetFullName() or "nil"))
				end)
			end
		end)
	end
end)
-- BillboardGui / gambar / teks "!" yang muncul DI MANA AJA (workspace + PlayerGui)
local function anyVisual(where, d)
	pcall(function()
		if d:IsA("BillboardGui") then
			task.defer(function()
				local a = d.Adornee or d.Parent
				mlog("bb" .. d.Name, ("MARK %s +Billboard %s at=%s"):format(where, d.Name, a and a:GetFullName() or "nil"))
			end)
		elseif (d:IsA("TextLabel") or d:IsA("TextButton")) then
			local function chk()
				if tostring(d.Text):find("!", 1, true) and #tostring(d.Text) <= 3 then
					mlog("tx" .. d:GetFullName(), ("MARK %s !text %s vis=%s"):format(where, d:GetFullName(), tostring(d.Visible)))
				end
			end
			chk()
			conns[#conns + 1] = d:GetPropertyChangedSignal("Text"):Connect(chk)
		end
	end)
end
conns[#conns + 1] = workspace.DescendantAdded:Connect(function(d)
	if d:IsA("BillboardGui") or d:IsA("TextLabel") then anyVisual("ws", d) end
end)
pcall(function()
	local pg = LP:WaitForChild("PlayerGui", 5)
	for _, d in ipairs(pg:GetDescendants()) do anyVisual("pg", d) end
	conns[#conns + 1] = pg.DescendantAdded:Connect(function(d) anyVisual("pg", d) end)
end)

-- cari model pet (nama = uuid) tiap 3 detik (pet di-place ulang = model baru)
task.spawn(function()
	while running do
		local eq = {}
		if okDS then
			local ok, d = pcall(function() return DataService:GetData() end)
			eq = (ok and d and d.PetsData and d.PetsData.EquippedPets) or {}
		end
		local want = {}
		for _, u in ipairs(eq) do want[u] = true end
		if next(want) then
			for _, d in ipairs(workspace:GetDescendants()) do
				if want[d.Name] and (d:IsA("Model") or d:IsA("BasePart")) then watchModel(d) end
			end
		end
		task.wait(3)
	end
end)

-- polling cd + equipped
local lastEq = ""
task.spawn(function()
	while running do
		local eq = {}
		if okDS then
			local ok, d = pcall(function() return DataService:GetData() end)
			eq = (ok and d and d.PetsData and d.PetsData.EquippedPets) or {}
		end
		local short = {}
		for _, u in ipairs(eq) do short[#short + 1] = ser(u) end
		local s = table.concat(short, ",")
		if s ~= lastEq then lastEq = s; log("EQ   [" .. s .. "]") end
		for _, u in ipairs(eq) do
			task.spawn(function()
				selfCall = true
				local ok, cd = pcall(function() return GetPetCooldown:InvokeServer(u) end)
				selfCall = false
				if ok then onCd("poll", u, cd) end
			end)
		end
		task.wait(0.2)
	end
end)

log(("START logger %d detik"):format(DURATION))
task.delay(DURATION, function()
	running = false
	for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
	log("STOP")
	local txt = table.concat(lines, "\n")
	pcall(function() writefile("pnp_log.txt", txt) end)
	pcall(function() setclipboard(txt) end)
	print("[PNPLOG] selesai -> pnp_log.txt (" .. #lines .. " baris), juga di-copy ke clipboard")
end)
