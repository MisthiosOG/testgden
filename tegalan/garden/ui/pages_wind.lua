-- WindUI-native garden pages. This intentionally replaces the legacy pages.lua
-- builder; automation modules and CFG remain unchanged.
return function(ctx)
    local WindUI = ctx.ui.windWindow
    local CFG = ctx.CFG
    local function tab(name, icon) return ctx.ui.windTabs[name] or WindUI:Tab({ Title = name, Icon = icon }) end
    local function toggle(t, title, desc, key, starter)
        local control = t:Toggle({
            Title = title, Desc = desc, Value = CFG[key] == true,
            Callback = function(v)
                CFG[key] = v
                if ctx.persistState then ctx.persistState() end
                if v and starter then starter() end
            end,
        })
        return control
    end
    local function input(t, title, key, default)
        return t:Input({
            Title = title, Value = tostring(CFG[key] or default),
            Callback = function(v) CFG[key] = tonumber(v) or default; if ctx.persistState then ctx.persistState() end end,
        })
    end
    local function multi(t, title, values, selected, callback)
        return t:Dropdown({
            Title = title, Values = values, Multi = true, AllowNone = true,
            SearchBarEnabled = true,
            Callback = function(items)
                for k in pairs(selected) do selected[k] = nil end
                for _, item in ipairs(items or {}) do selected[item] = true end
                if callback then callback() end
            end,
        })
    end

    local function dynamicMulti(t, title, getter, selected, callback)
        local values = type(getter) == "function" and getter() or {}
        local display, reverse = {}, {}
        for _, item in ipairs(values) do
            if type(item) == "table" then
                local label = item.display or item.name or item.value
                display[#display + 1] = label
                reverse[label] = item.value or item.name or label
            else
                display[#display + 1] = item
            end
        end
        return t:Dropdown({
            Title = title, Values = display, Multi = true, AllowNone = true,
            SearchBarEnabled = true,
            Callback = function(items)
                for key in pairs(selected) do selected[key] = nil end
                for _, item in ipairs(items or {}) do selected[reverse[item] or item] = true end
                if callback then callback() end
            end,
        })
    end

    local pet = tab("Pet", "paw-print")
    toggle(pet, "Auto Pick & Place V1", "Existing polling PNP logic", "pnpEnabled", ctx.startPnpV1)
    toggle(pet, "Auto Pick & Place V2", "Existing event-driven PNP logic", "pnpV2Enabled", ctx.startPnpV2)
    input(pet, "PNP V1 Pickup Delay", "pickupDelay", 0.3)
    input(pet, "PNP V2 Pickup Delay", "pnpV2PickupDelay", 0.05)
    toggle(pet, "Auto Boost Pet", "Existing pet boost automation", "boostEnabled", ctx.startBoostPet)
    dynamicMulti(pet, "PNP V1 Pets", function() return ctx.inventoryPetOptions and ctx.inventoryPetOptions(CFG.pnpUuids) or {} end, CFG.pnpUuids, function() if ctx.persistState then ctx.persistState() end end)
    dynamicMulti(pet, "PNP V2 Pets", function() return ctx.inventoryPetOptions and ctx.inventoryPetOptions(CFG.pnpV2Uuids) or {} end, CFG.pnpV2Uuids, function() if ctx.persistState then ctx.persistState() end end)

    local farm = tab("Farm", "wheat")
    toggle(farm, "Auto Plants", "Plant selected seeds", "plantSeedEnabled", ctx.startPlant)
    toggle(farm, "Auto Sprinkler", "Place selected sprinklers", "sprinklerEnabled", ctx.startSprinkler)
    toggle(farm, "Auto Water", "Water selected fruits", "waterEnabled", ctx.startWater)
    toggle(farm, "Auto Collect", "Harvest selected fruits", "collectWlFruitEnabled", ctx.startCollect)
    toggle(farm, "Auto Favorite", "Favorite selected fruits", "favEnabled", ctx.startFavorite)
    toggle(farm, "Auto Unfavorite", "Unfavorite selected fruits", "unfavEnabled", ctx.startFavorite)
    toggle(farm, "Auto Reclaimer", "Reclaim selected plants", "reclaimEnabled", ctx.startReclaim)
    dynamicMulti(farm, "Seeds", function() return ctx.getPlantSeedOptions and ctx.getPlantSeedOptions() or {} end, CFG.plantSeedNames, function() if ctx.persistState then ctx.persistState() end end)
    dynamicMulti(farm, "Sprinklers", function() return ctx.getSprinklerOptions and ctx.getSprinklerOptions() or {} end, CFG.sprinklerNames, function() if ctx.persistState then ctx.persistState() end end)

    local hatch = tab("Hatch", "egg")
    toggle(hatch, "Auto Hatch", "Existing hatch automation", "hatchEnabled", ctx.startHatch)
    toggle(hatch, "Auto Sell", "Existing hatch sell automation", "autoSellEnabled")
    input(hatch, "Hatch Team Delay", "hatchTeamDelay", 5.5)
    input(hatch, "Max Eggs Placed", "hatchMaxPlaced", 8)

    local elephant = tab("Elephant", "rabbit")
    toggle(elephant, "Auto Elephant", "Existing elephant automation", "elephantEnabled", ctx.startElephant)
    toggle(elephant, "Auto Elephant V2", "Existing elephant V2 automation", "elephantV2Enabled", ctx.startElephantV2)

    local flow = tab("Flow", "git-branch")
    toggle(flow, "Growth Pipeline", "Existing elephant/mutation/leveling pipeline", "growthEnabled", ctx.startGrowth)
    toggle(flow, "Beanstalk Event", "Existing Beanstalk automation", "beanstalkPlantEnabled", ctx.startBeanstalk)

    local inventory = tab("Inventory", "backpack")
    toggle(inventory, "Accept Gifts", "Existing gift accept automation", "acceptGifts")
    toggle(inventory, "Accept Trades", "Existing trade accept automation", "acceptTrades")
    toggle(inventory, "Trade Ticket", "Existing trade ticket automation", "tradeTicketEnabled", function() if ctx.startTrade then ctx.startTrade("ticket") end end)
    toggle(inventory, "Trade Gift", "Existing gift automation", "tradeGiftEnabled", function() if ctx.startTrade then ctx.startTrade("gift") end end)

    local leveling = tab("Leveling", "zap")
    toggle(leveling, "Leveling", "Existing leveling automation", "levelingEnabled", ctx.startLeveling)
    toggle(leveling, "Leveling V2", "Existing leveling V2 automation", "levelingV2Enabled", ctx.startLevelingV2)
    input(leveling, "Level Target", "levelingTargetLevel", 500)

    local mutation = tab("Mutation", "flask-conical")
    toggle(mutation, "Mutation", "Existing mutation automation", "mutationEnabled", ctx.startMutation)
    toggle(mutation, "Cleanse", "Existing cleanse automation", "cleanseEnabled", ctx.startCleanse)

    local shop = tab("Shop", "shopping-cart")
    toggle(shop, "Buy Seeds", "Existing shop automation", "buySeedEnabled", ctx.startBuySeed)
    toggle(shop, "Buy Eggs", "Existing shop automation", "buyEggEnabled", ctx.startBuyEgg)
    toggle(shop, "Buy Gear", "Existing shop automation", "buyGearEnabled", ctx.startBuyGear)
    toggle(shop, "Buy Merchant", "Existing merchant automation", "merchantBuyEnabled", ctx.startBuyMerchant)

    local misc = tab("Misc", "settings")
    toggle(misc, "ESP Labels", "Existing ESP label module", "espEnabled", ctx.startEsp)
    toggle(misc, "ESP Inventory", "Existing ESP inventory module", "espInvEnabled", ctx.startEspInv)
    toggle(misc, "Noclip", "Existing player modifier", "noclipEnabled", function() if ctx.setNoclip then ctx.setNoclip(true) end end)
    toggle(misc, "Infinity Jump", "Existing player modifier", "infJumpEnabled", function() if ctx.setInfJump then ctx.setInfJump(true) end end)
    toggle(misc, "Auto Reconnect", "Existing reconnect module", "reconnectEnabled", ctx.startReconnect)
    toggle(misc, "Performance Mode", "Existing performance module", "perfMode", ctx.startPerf)

    if ctx.notify then ctx.notify("Native WindUI pages loaded") end
end
