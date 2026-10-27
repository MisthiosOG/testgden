-- Native WindUI pages. Mirrors the old hierarchy:
-- main tab -> sub-tab sections -> collapsible WindUI sections -> controls.
return function(ctx)
    local window = ctx.ui.windWindow
    local CFG = ctx.CFG
    local function save() if ctx.persistState then ctx.persistState() end end
    local function t(name, icon) return ctx.ui.windTabs[name] or window:Tab({ Title = name, Icon = icon }) end
    local function section(tab, title)
        if tab.Section then
            local ok, value = pcall(function() return tab:Section({ Title = title }) end)
            if ok and value then return value end
        end
        return tab
    end
    -- Starter receives the toggle value: loop-based starters ignore it,
    -- imperative modifiers (setNoclip / setInfJump) need the direction.
    local function toggle(tab, title, desc, key, starter)
        return tab:Toggle({ Title = title, Desc = desc, Value = CFG[key] == true,
            Callback = function(v) CFG[key] = v; save(); if v and starter then starter(v) end end })
    end
    local function input(tab, title, key, fallback, desc)
        return tab:Input({ Title = title, Desc = desc, Value = tostring(CFG[key] or fallback),
            Callback = function(v) CFG[key] = tonumber(v) or fallback; save() end })
    end
    local function multi(tab, title, getter, selected, desc)
        local options = type(getter) == "function" and getter() or getter or {}
        local values, reverse = {}, {}
        for _, item in ipairs(options) do
            local value = type(item) == "table" and (item.value or item.name) or item
            local display = type(item) == "table" and (item.display or item.name or item.value) or item
            values[#values + 1] = display; reverse[display] = value
        end
        return tab:Dropdown({ Title = title, Desc = desc, Values = values, Multi = true,
            AllowNone = true, SearchBarEnabled = true,
            Callback = function(items)
                for k in pairs(selected) do selected[k] = nil end
                for _, item in ipairs(items or {}) do selected[reverse[item] or item] = true end
                save()
            end })
    end
    local function button(tab, title, callback) return tab:Button({ Title = title, Callback = callback }) end

    -- PET
    do
        local tab = t("Pet", "paw-print")
        local pnp = section(tab, "Pick & Place")
        toggle(pnp, "PNP V1", "Polling implementation", "pnpEnabled", ctx.startPnpV1)
        toggle(pnp, "PNP V2", "Event-driven implementation", "pnpV2Enabled", ctx.startPnpV2)
        input(pnp, "V1 Pickup Delay", "pickupDelay", 0.3)
        input(pnp, "V2 Pickup Delay", "pnpV2PickupDelay", 0.05)
        multi(pnp, "V1 Pet Selection", function() return ctx.inventoryPetOptions and ctx.inventoryPetOptions(CFG.pnpUuids) or {} end, CFG.pnpUuids)
        multi(pnp, "V2 Pet Selection", function() return ctx.inventoryPetOptions and ctx.inventoryPetOptions(CFG.pnpV2Uuids) or {} end, CFG.pnpV2Uuids)
        local boost = section(tab, "Boost")
        toggle(boost, "Auto Boost Pet", "Existing boost module", "boostEnabled", ctx.startBoostPet)
    end

    -- FARM WITH SUBTAB SECTIONS
    do
        local tab = t("Farm", "wheat")
        local plants = section(tab, "Plants")
        multi(plants, "Seeds", function() return ctx.getPlantSeedOptions and ctx.getPlantSeedOptions() or {} end, CFG.plantSeedNames)
        toggle(plants, "Auto Plants", "Plant selected seeds", "plantSeedEnabled", ctx.startPlant)
        input(plants, "Plant Delay", "plantDelay", 0)
        local care = section(tab, "Sprinkler & Water")
        multi(care, "Sprinklers", function() return ctx.getSprinklerOptions and ctx.getSprinklerOptions() or {} end, CFG.sprinklerNames)
        toggle(care, "Auto Sprinkler", "Place selected sprinklers", "sprinklerEnabled", ctx.startSprinkler)
        toggle(care, "Auto Water", "Water selected fruit", "waterEnabled", ctx.startWater)
        input(care, "Water Delay", "waterDelay", 1)
        local harvest = section(tab, "Harvest & Favorite")
        toggle(harvest, "Auto Collect", "Harvest selected fruit", "collectWlFruitEnabled", ctx.startCollect)
        toggle(harvest, "Auto Favorite", "Favorite selected fruit", "favEnabled", ctx.startFavorite)
        toggle(harvest, "Auto Unfavorite", "Unfavorite selected fruit", "unfavEnabled", ctx.startFavorite)
        local shovel = section(tab, "Shovel & Reclaimer")
        toggle(shovel, "Auto Shovel Tree", "Remove selected trees", "shovelTreeEnabled", ctx.startShovelTree)
        toggle(shovel, "Auto Shovel Fruit", "Remove selected fruit", "shovelFruitEnabled", ctx.startShovelFruit)
        toggle(shovel, "Auto Reclaimer", "Reclaim selected plants", "reclaimEnabled", ctx.startReclaim)
    end

    -- HATCH SUBTABS AS SECTIONS
    do
        local tab = t("Hatch", "egg")
        local core = section(tab, "Main Team")
        toggle(core, "Auto Hatch", "Hatch selected eggs", "hatchEnabled", ctx.startHatch)
        input(core, "Egg Name", "hatchEggName", "Rare Egg")
        input(core, "Max Eggs", "hatchMaxPlaced", 8)
        input(core, "Team Delay", "hatchTeamDelay", 5.5)
        local bronto = section(tab, "Bronto Team")
        multi(bronto, "Bronto Team", function() return ctx.inventoryPetOptions and ctx.inventoryPetOptions(CFG.hatchBrontoTeam) or {} end, CFG.hatchBrontoTeam)
        input(bronto, "Bronto Weight", "brontoUniversalWeight", 0)
        local sell = section(tab, "Sell Team")
        toggle(sell, "Auto Sell", "Sell configured hatch results", "autoSellEnabled")
        multi(sell, "Sell Pet Types", function() return ctx.reg and ctx.reg.PET_OPTIONS or {} end, CFG.sellPetTypes)
        local config = section(tab, "Hatch Config")
        toggle(config, "Egg Minus Rejoin", "Reconnect on minus egg delta", "hatchRejoinMinusEnabled", ctx.startEggMinusWatcher)
        toggle(config, "Egg Plus Rejoin", "Reconnect on plus egg delta", "hatchRejoinPlusEnabled", ctx.startEggMinusWatcher)
    end

    -- FLOW SUBTABS
    do
        local tab = t("Flow", "git-branch")
        local main = section(tab, "Flow Controls")
        toggle(main, "Growth Pipeline", "Elephant -> Mutation -> Leveling", "growthEnabled", ctx.startGrowth)
        multi(main, "Default Target Types", function() return ctx.reg and ctx.reg.PET_OPTIONS or {} end, CFG.growthPetTypes)
        local elephant = section(tab, "Elephant Step")
        input(elephant, "Target Weight", "growthElephantWeight", 5.5)
        input(elephant, "Max Pets", "growthElephantMax", 2)
        local mutation = section(tab, "Mutation Step")
        multi(mutation, "Target Mutations", function() return ctx.reg and ctx.reg.MUT_OPTIONS or {} end, CFG.growthMutationTargets)
        toggle(mutation, "Mutation", "Existing mutation module", "mutationEnabled", ctx.startMutation)
        local leveling = section(tab, "Leveling Step")
        input(leveling, "Phase 1 Target", "growthLevP1Target", 40)
        input(leveling, "Phase 2 Target", "growthLevP2Target", 500)
    end

    local level = t("Leveling", "zap")
    toggle(section(level, "Leveling Controls"), "Leveling V1", "Existing leveling", "levelingEnabled", ctx.startLeveling)
    toggle(section(level, "Leveling Controls"), "Leveling V2", "Two-phase leveling", "levelingV2Enabled", ctx.startLevelingV2)
    input(section(level, "Leveling Controls"), "Target Level", "levelingTargetLevel", 500)

    local mut = t("Mutation", "flask-conical")
    toggle(section(mut, "Mutation Machine"), "Auto Mutation", "Existing mutation machine", "mutationEnabled", ctx.startMutation)
    toggle(section(mut, "Mutation Machine"), "Auto Cleanse", "Existing cleanse module", "cleanseEnabled", ctx.startCleanse)

    local inv = t("Inventory", "backpack")
    toggle(section(inv, "Trade & Gifts"), "Trade Ticket", "Existing trade automation", "tradeTicketEnabled", function() if ctx.startTrade then ctx.startTrade("ticket") end end)
    toggle(section(inv, "Trade & Gifts"), "Trade Gift", "Existing gift automation", "tradeGiftEnabled", function() if ctx.startTrade then ctx.startTrade("gift") end end)
    toggle(section(inv, "Trade & Gifts"), "Accept Gifts", "Accept incoming gifts", "acceptGifts")
    toggle(section(inv, "Trade & Gifts"), "Accept Trades", "Accept incoming trades", "acceptTrades")

    local shop = t("Shop", "shopping-cart")
    toggle(section(shop, "Seeds"), "Buy Seeds", "Existing shop automation", "buySeedEnabled", ctx.startBuySeed)
    toggle(section(shop, "Eggs"), "Buy Eggs", "Existing shop automation", "buyEggEnabled", ctx.startBuyEgg)
    toggle(section(shop, "Gears"), "Buy Gear", "Existing shop automation", "buyGearEnabled", ctx.startBuyGear)
    toggle(section(shop, "Merchant"), "Buy Merchant", "Existing merchant automation", "merchantBuyEnabled", ctx.startBuyMerchant)

    local misc = t("Misc", "settings")
    toggle(section(misc, "Performance"), "Noclip", "Player modifier", "noclipEnabled", function(v) if ctx.setNoclip then ctx.setNoclip(v) end end)
    toggle(section(misc, "Performance"), "Infinity Jump", "Player modifier", "infJumpEnabled", function(v) if ctx.setInfJump then ctx.setInfJump(v) end end)
    toggle(section(misc, "Performance"), "ESP Labels", "Existing ESP labels", "espEnabled", ctx.startEsp)
    toggle(section(misc, "Performance"), "ESP Inventory", "Existing ESP inventory", "espInvEnabled", ctx.startEspInv)
    toggle(section(misc, "Reconnect"), "Auto Reconnect", "Reconnect on disconnect", "reconnectEnabled", ctx.startReconnect)

    if ctx.notify then ctx.notify("Native WindUI pages loaded") end
end
