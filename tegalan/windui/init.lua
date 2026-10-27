--[[
	CeszParadiseHub â€” WINDUI app (loader)  [tab-per-tab migration build]
	Dipanggil router saat getgenv().GAG_APP = "windui" (atau manual).
	Fitur = 100% module dari garden (logika sama persis). UI = WindUI native.
	Tab yang belum dimigrasi tampil placeholder â€” migrasi progresif per tab.
--]]

local branch = (getgenv and getgenv().GAG_BRANCH) or _G.GAG_BRANCH or "main"
local revision = (getgenv and getgenv().GAG_REVISION) or _G.GAG_REVISION or branch
local compile = loadstring or load
local LOCAL_ROOT = (getgenv and getgenv().GAG_LOCAL_ROOT) or _G.GAG_LOCAL_ROOT
local BASE = LOCAL_ROOT and (LOCAL_ROOT .. "/windui")
    or ("https://raw.githubusercontent.com/MisthiosOG/testgden/" .. revision .. "/tegalan/windui")

-- Remove any previous legacy UI before WindUI/modules initialize. This runs
-- before a library download, so a failed reload cannot leave the old shell
-- visually masquerading as the current build.
pcall(function()
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local host = (gethui and gethui()) or game:GetService("CoreGui")
    local function clear(container)
        for _, child in ipairs(container:GetChildren()) do
            local n = child.Name:lower()
            if n:find("cesz", 1, true) or n:find("gag", 1, true)
                or n:find("allegiaan", 1, true) then
                child:Destroy()
            end
        end
    end
    clear(host)
    if player and player:FindFirstChild("PlayerGui") then clear(player.PlayerGui) end
end)
print("[CeszParadiseHub][WINDUI] windui loader selected")

-- Mirror chain: CDN raw.github kadang nge-cache 404 lama abis push path baru.
-- Kombinasi: query unik (beda cache key) + path HEAD + mirror jsdelivr.
local MIRRORS = {
	BASE,
	"https://raw.githubusercontent.com/MisthiosOG/testgden/HEAD/tegalan/windui",
	("https://cdn.jsdelivr.net/gh/MisthiosOG/testgden@" .. branch .. "/tegalan/windui"),
}
local function httpFetch(url)
	local ok, src = pcall(function() return game:HttpGet(url) end)
	if ok and type(src) == "string" and #src > 0 and src:sub(1, 3) ~= "404" then return src end
	return nil
end
local function fetchMirror(relPath, tag)
	tag = tag or tostring(os.clock())
	for _, host in ipairs(MIRRORS) do
		local src = httpFetch(host .. "/" .. relPath .. "?m=" .. tag .. "-" .. tostring(math.random(1, 1e6)))
		if src then return src end
	end
	return nil
end

-- Selalu load dari bundle.lua (1 HttpGet, kilat). Workflow: edit modul ->
-- `node tools/bundle.js` -> push. Kalau bundle gagal / ada modul yg belum
-- ke-bundle, fungsi fetch di bawah fallback ambil per-modul dari GitHub.
local FILES
do
	local src
	if LOCAL_ROOT then
		local ok, r = pcall(function() return readfile(BASE .. "/bundle.lua") end)
		src = ok and r or nil
	else
		src = fetchMirror("bundle.lua", "b")
	end
	if type(src) == "string" and #src > 0 then
		local chunk = compile(src, "@bundle.lua")
		if chunk then
			local okr, tbl = pcall(chunk)
			if okr and type(tbl) == "table" then FILES = tbl end
		end
	end
	if FILES then
		print("[CeszParadiseHub/windui] OK Bundle loaded sukses (Mode Kilat)")
	else
		warn("[CeszParadiseHub/windui] WARN Bundle gagal dimuat, beralih ke download per-modul HTTP (lambat)...")
	end
end

-- Ambil source modul: dari bundle (memori) kalau ada, else HttpGet (dev/fallback).
local function fetch(relPath)
	-- UI shell is fetched independently so a stale embedded bundle can never
	-- resurrect the legacy window during a UI-only migration.
	if not LOCAL_ROOT and relPath == "ui/window.lua" then
		for _, host in ipairs(MIRRORS) do
			local src = httpFetch(host .. "/" .. relPath .. "?windui=" .. tostring(os.clock()))
			if src then return src end
		end
	end
	if FILES and FILES[relPath] then return FILES[relPath] end
	if LOCAL_ROOT then
		local ok, src = pcall(function() return readfile(BASE .. "/" .. relPath) end)
		if ok and type(src) == "string" and #src > 0 then return src end
		return nil
	end
	return fetchMirror(relPath)
end

local function loadModule(relPath)
	local src = fetch(relPath)
	if type(src) ~= "string" or src == "" then
		error(("[CeszParadiseHub/windui] gagal ambil %s"):format(relPath))
	end
    local chunk, err = compile(src, "@" .. relPath)
	if not chunk then
		error(("[CeszParadiseHub/windui] gagal compile %s: %s"):format(relPath, tostring(err)))
	end
	local mod = chunk()
	if type(mod) ~= "function" then
		error(("[CeszParadiseHub/windui] modul %s harus 'return function(ctx)'"):format(relPath))
	end
	return mod
end

local ctx = {
	BASE  = BASE,
	state = {
		tradeRunning = false,
		completed    = 0,
		status       = "IDLE",
		logLines     = {},
		gui          = nil,
	},
	ui   = {},
	reg  = {},
	deps = {},
}

function ctx.alive()
	return ctx.state.isAlive ~= false
end
function ctx.elevate()
	pcall(function()
		local f = setthreadidentity or setidentity
			or (syn and syn.set_thread_identity)
			or (getgenv and getgenv().setthreadidentity)
		if f then f(7) end
	end)
end


-- Logo AH buat tombol minimize. Download sekali, cache via getcustomasset (fallback: teks "AH").
function ctx.getLogo()
	if _G.__AH_LOGO ~= nil then return _G.__AH_LOGO or nil end
	local asset = false
	pcall(function()
		local gca = getcustomasset or getsynasset or (syn and syn.getcustomasset)
		if not (gca and writefile) then return end
		local path = "CeszParadiseHUB/logo_icon.png"
		if not (isfile and isfile(path)) then
			if makefolder and not (isfolder and isfolder("CeszParadiseHUB")) then makefolder("CeszParadiseHUB") end
			writefile(path, game:HttpGet("https://raw.githubusercontent.com/milmscr/opoki/" .. branch .. "/tegalan/Logo/logo_icon.png"))
		end
		asset = gca(path) or false
	end)
	_G.__AH_LOGO = asset
	return asset or nil
end

-- Loader untuk file yang BUKAN pola return function(ctx) (mis. webhook helper/formatter).
-- Karena app di-load via HttpGet (bukan ModuleScript), require(script...) nggak jalan â€”
-- jadi file webhook di-fetch di sini dan hasilnya ditaruh di ctx.
local function loadRaw(relPath)
	local src = fetch(relPath)
	if type(src) ~= "string" then return nil end
	local chunk = loadstring(src, "@" .. relPath)
	if not chunk then return nil end
	local okr, val = pcall(chunk)
	return okr and val or nil
end
ctx.sendWebhook     = loadRaw("modules/core/webhook.lua")     -- function(url, payload, ctx)
ctx.webhookMutation = loadRaw("modules/mutation/webhook.lua") -- table {sendEnabled, sendSubmitted, sendClaimed}
ctx.webhookLeveling = loadRaw("modules/leveling/webhook.lua") -- table leveling webhook
ctx.webhookElephant = loadRaw("modules/elephant/webhook.lua") -- table elephant webhook
ctx.webhookCleanse  = loadRaw("modules/mutation/cleanse_webhook.lua") -- table cleanse/mutation webhook

-- Modul dikelompokkan per-menu: tiap fitur punya folder sendiri (varian = v1/v2),
-- infra bersama di modules/core/. Urutan load tetap dijaga (dependency).
local MODULES = {
	"modules/core/services.lua",
	"modules/core/registry.lua",
	"modules/core/config.lua",
	"ui/theme.lua",
	"modules/inventory/automation_trade.lua",
	"modules/inventory/automation_accept.lua",
	"modules/pet/automation_pickup_pet_v1.lua",
	"modules/pet/automation_pickup_pet_v2.lua",
	"modules/pet/automation_boost_pet.lua",
	"modules/shop/automation_shop.lua",
	"modules/shop/automation_merchant.lua",
	"modules/shop/premium_shop.lua",
	"modules/leveling/automation_leveling_v1.lua",
	"modules/leveling/automation_leveling_v2.lua",
	"modules/elephant/automation_elephant_v1.lua",
	"modules/elephant/automation_elephant_v2.lua",
	"modules/growth/automation_growth.lua",
	"modules/hatch/automation_hatch.lua",
	"modules/event/automation_beanstalk.lua",
	"modules/event/automation_beanstalk_hop.lua",
	"modules/farm/automation_reclaimer.lua",
	"modules/farm/automation_plants.lua",
	"modules/farm/automation_sprinkler.lua",
	"modules/farm/automation_water.lua",
	"modules/farm/automation_shovel.lua",
	"modules/farm/automation_collect.lua",
	"modules/farm/automation_favorite.lua",
	"modules/mutation/automation_mutation_machine.lua",
	"modules/mutation/automation_mutation.lua",
	"modules/misc/esp_label.lua",
	"modules/misc/esp_inventory.lua",
	"modules/misc/player_mods.lua",
	"modules/misc/perf_mods.lua",
	"modules/misc/automation_reconnect.lua",
	"ui/window.lua",
	"ui/pages.lua",
	"app.lua",
}

for _, rel in ipairs(MODULES) do
	local ok, err = pcall(function()
		print("[GAGHub][WINDUI] module " .. rel)
		loadModule(rel)(ctx)
	end)
	if not ok then
		warn("[GAGHub][WINDUI] module failed " .. rel .. ": " .. tostring(err))
		if rel == "ui/window.lua" then return nil end
	end
end

return ctx
