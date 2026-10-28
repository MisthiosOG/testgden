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
local inCount = {}
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
