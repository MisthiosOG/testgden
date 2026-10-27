-- WindUI compatibility shell for Trade World.
-- Seller/sniper modules and CFG callbacks remain unchanged.
return function(ctx)
    pcall(function()
        local host = (gethui and gethui()) or game:GetService("CoreGui")
        for _, name in ipairs({ "GAGGarden", "CeszParadiseGarden", "AllegiaanGarden", "GAGSeller", "GAGTrade", "CeszParadiseTrade" }) do
            local old = host:FindFirstChild(name)
            if old then old:Destroy() end
            local playerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
            local oldPlayerGui = playerGui and playerGui:FindFirstChild(name)
            if oldPlayerGui then oldPlayerGui:Destroy() end
        end
    end)
    local compile = loadstring or load
    local WindUI = compile(game:HttpGet(
        "https://github.com/Footagesus/WindUI/releases/download/1.6.66/main.lua"
    ))()
    assert(WindUI and WindUI.CreateWindow, "WindUI failed to load")

    local window = WindUI:CreateWindow({
        Title = "iStealth WindUI Trade",
        Icon = "shopping-cart",
        ToggleKey = Enum.KeyCode.K,
        Size = UDim2.fromOffset(760, 520),
        Theme = "Dark",
        OpenButton = { Enabled = true, OnlyMobile = false, Title = "iStealth WindUI Trade", Icon = "shopping-cart" },
    })

    ctx.ui = ctx.ui or {}
    ctx.ui.pages = {}
    ctx.ui.tabBtns = {}
    ctx.ui.windWindow = window
    ctx.state.isAlive = true

    local compatGui = Instance.new("ScreenGui")
    compatGui.Name = "iStealthTradeCompat"
    compatGui.ResetOnSpawn = false
    compatGui.Enabled = false
    compatGui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
    local compatRoot = Instance.new("Frame")
    compatRoot.Size = UDim2.fromOffset(1, 1)
    compatRoot.Visible = false
    compatRoot.Parent = compatGui
    local legacyMk = ctx.mk
    local compatOwners = {}
    ctx.mk = function(className, props, parent)
        local owner = type(parent) == "table" and parent.__windTab or compatOwners[parent]
        local instance = legacyMk(className, props, (owner and compatRoot) or parent)
        if owner then compatOwners[instance] = owner end
        return instance
    end

    local tabs = {}
    local noopSignal = { Connect = function() return { Disconnect = function() end } end }
    local function tabFor(parent)
        return (type(parent) == "table" and parent.__windTab)
            or compatOwners[parent] or (parent and parent.__windTab)
            or tabs.Sell
    end
    local function makePage(name, title, icon)
        local tab = tabs[name] or window:Tab({ Title = title or name, Icon = icon })
        tabs[name] = tab
        ctx.ui.pages[name] = { __windTab = tab, Visible = false }
        ctx.ui.tabBtns[name] = {
            btn = { MouseButton1Click = noopSignal, BackgroundTransparency = 1, TextColor3 = Color3.new(1, 1, 1) },
            line = { Visible = false },
            setActive = function(active)
                if active and tab.Select then pcall(function() tab:Select() end) end
            end,
        }
        return ctx.ui.pages[name]
    end
    local function asValues(options)
        local out = {}
        for _, value in ipairs(options or {}) do
            out[#out + 1] = type(value) == "table"
                and (value.display or value.name or value.value) or value
        end
        return out
    end
    local function makeAccordion(parent, title)
        local tab = tabFor(parent)
        if tab.Section then
            local ok, section = pcall(function() return tab:Section({ Title = title }) end)
            if ok and section then return section end
        end
        return tab
    end
    local function makeToggle(parent, title, desc, getValue, setValue)
        local control = tabFor(parent):Toggle({
            Title = title, Desc = desc,
            Value = type(getValue) == "function" and getValue() or false,
            Callback = function(value) if setValue then setValue(value) end end,
        })
        return setmetatable({ _windControl = control }, {
            __index = control,
            __call = function()
                if control and control.Set and getValue then control:Set(getValue()) end
            end,
        })
    end
    local function makeInput(parent, title, desc, getValue, setValue)
        return tabFor(parent):Input({
            Title = title, Desc = desc,
            Value = type(getValue) == "function" and tostring(getValue()) or "",
            Callback = function(value) if setValue then setValue(value) end end,
        })
    end
    local function makeSingleDropdown(parent, title, desc, getOptions, getValue, setValue)
        local options = type(getOptions) == "function" and getOptions() or {}
        local displayToValue, valueToDisplay = {}, {}
        for _, option in ipairs(options) do
            if type(option) == "table" then
                local display = option.display or option.name or option.value
                local value = option.name or option.value
                displayToValue[display], valueToDisplay[value] = value, display
            end
        end
        return tabFor(parent):Dropdown({
            Title = title, Desc = desc, Values = asValues(options),
            Value = valueToDisplay[type(getValue) == "function" and getValue() or ""],
            AllowNone = true, SearchBarEnabled = #options > 12,
            Callback = function(value) if setValue then setValue(displayToValue[value] or value) end end,
        })
    end
    local function makeDropdown(parent, title, desc, options, selected, onChange)
        local displayToValue = {}
        for _, option in ipairs(options or {}) do
            if type(option) == "table" then
                displayToValue[option.display or option.name or option.value] = option.value or option.name
            else displayToValue[option] = option end
        end
        return tabFor(parent):Dropdown({
            Title = title, Desc = desc, Values = asValues(options), Multi = true,
            AllowNone = true, SearchBarEnabled = true,
            Callback = function(values)
                for key in pairs(selected or {}) do selected[key] = nil end
                for _, value in ipairs(values or {}) do selected[displayToValue[value] or value] = true end
                if onChange then onChange() end
            end,
        })
    end
    local function makeButton(parent, title, color, callback)
        return tabFor(parent):Button({ Title = title, Color = color, Callback = callback })
    end
    ctx.makePage = makePage
    ctx.makeAccordion = makeAccordion
    ctx.makeToggle = makeToggle
    ctx.makeInput = makeInput
    ctx.makeSingleDropdown = makeSingleDropdown
    ctx.makeDropdown = makeDropdown
    ctx.makeButton = makeButton
    function ctx.selectTab(name)
        local data = ctx.ui.tabBtns[name]
        if data and data.setActive then data.setActive(true) end
    end
    ctx.C = ctx.C or {}
    ctx.F = ctx.F or {}
    ctx.ui.windTabs = tabs
    pcall(function() WindUI:Notify({ Title = "iStealth WindUI Trade", Content = "BUILD windui-2026-10-27", Duration = 5 }) end)
end
