--[[
	GAG Hub — Router
	Satu entry point untuk dua server berbeda. Jalankan:
		loadstring(game:HttpGet("https://raw.githubusercontent.com/milmscr/opoki//main/GAGSeller/init.lua"))()

	Router mendeteksi PlaceId lalu memuat app yang sesuai:
	  - Trade World  -> GAGSeller/trade/init.lua   (fitur seller sekarang)
	  - selain itu   -> GAGSeller/garden/init.lua  (fitur garden)
--]]

-- Branch: "main" = production. Override buat dev: getgenv().GAG_BRANCH = "dev"
local branch = (getgenv and getgenv().GAG_BRANCH) or _G.GAG_BRANCH or "main"
local compile = loadstring or load
local LOCAL_ROOT = (getgenv and getgenv().GAG_LOCAL_ROOT) or _G.GAG_LOCAL_ROOT
local ROOT = LOCAL_ROOT or ("https://raw.githubusercontent.com/milmscr/opoki/" .. branch .. "/tegalan")

-- PlaceId server Trade World.
local TRADE_WORLD_PLACE = 129954712878723

-- Pilih sub-app. Override: getgenv().GAG_APP = "hatch" atau "garden" atau "trade".
local appOverride = (getgenv and getgenv().GAG_APP) or _G.GAG_APP
local detectedTarget = (game.PlaceId == TRADE_WORLD_PLACE) and "trade" or "garden"
-- Garden World must never inherit a stale GAG_APP="trade" from the executor.
local target = (appOverride == "trade" and detectedTarget ~= "trade")
    and detectedTarget or (appOverride or detectedTarget)
print(("[GAGHub][WINDUI] router target=%s place=%s"):format(target, tostring(game.PlaceId)))
if getgenv then
    getgenv().__OPOKI_BUILD = "windui-2026-10-27"
else
    _G.__OPOKI_BUILD = "windui-2026-10-27"
end

-- Telemetry ke dashboard web (heartbeat + inventory). Logika di modul terpisah biar loader tetap bersih.
pcall(function()
    local tchunk = compile(game:HttpGet(ROOT .. "/shared/telemetry.lua?t=" .. os.time()), "@shared/telemetry.lua")
	if tchunk then tchunk()(target) end
end)

local url = ROOT .. "/" .. target .. "/init.lua?t=" .. os.time()
local ok, src = pcall(function()
    if LOCAL_ROOT then
        local path = ROOT .. "/" .. target .. "/init.lua"
        return readfile(path)
    end
    return game:HttpGet(url)
end)
if not ok or type(src) ~= "string" or src == "" then
	warn(("[GAGHub] gagal ambil app '%s' (PlaceId=%s): %s"):format(target, tostring(game.PlaceId), tostring(src)))
	return
end

local chunk, err = compile(src, "@" .. target .. "/init.lua")
if not chunk then
	warn(("[GAGHub] gagal compile app '%s': %s"):format(target, tostring(err)))
	return
end

print(("[GAGHub] PlaceId=%s -> memuat app '%s'"):format(tostring(game.PlaceId), target))
return chunk()
