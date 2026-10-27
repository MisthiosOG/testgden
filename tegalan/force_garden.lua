-- iStealth WindUI Garden direct launcher.
-- Bypasses stale GAG_APP/router overrides; production diagnostic entrypoint.
local compile = loadstring or load
assert(compile, "No Luau compiler available")
local BUILD = "pink-royale-2026-10-27"
local REVISION = "6e5100e7ed6d598c74032f3392f67aa7b8566648"
local BASE = "https://raw.githubusercontent.com/MisthiosOG/testgden/" .. REVISION .. "/tegalan/garden"
print("[iStealth][DIRECT] build=" .. BUILD)

local function clearLegacy()
    pcall(function()
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        local host = (gethui and gethui()) or game:GetService("CoreGui")
        local function clear(container)
            for _, node in ipairs(container:GetDescendants()) do
                local name = node.Name:lower()
                if name:find("cesz", 1, true) or name:find("gag", 1, true)
                    or name:find("allegiaan", 1, true) then
                    pcall(function() node:Destroy() end)
                end
            end
        end
        clear(host)
        if player and player:FindFirstChild("PlayerGui") then clear(player.PlayerGui) end
    end)
end

clearLegacy()
if getgenv then getgenv().GAG_REVISION = REVISION else _G.GAG_REVISION = REVISION end
local ok, source = pcall(function()
    return game:HttpGet(BASE .. "/init.lua?direct=" .. tostring(os.clock()))
end)
assert(ok and type(source) == "string" and #source > 0, "Garden source download failed")
print("[iStealth][DIRECT] garden_source=" .. tostring(#source))
local fn, err = compile(source, "@garden/init.lua")
assert(fn, err)
return fn()
