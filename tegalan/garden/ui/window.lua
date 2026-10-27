-- WindUI compatibility shell.
-- Automation modules remain untouched: this file only adapts the existing
-- ctx UI contract to WindUI controls.
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
    local version = "1.6.66"
    local WindUI = loadstring(game:HttpGet(
        "https://github.com/Footagesus/WindUI/releases/download/"
            .. version .. "/main.lua"
    ))()
    assert(WindUI and WindUI.CreateWindow, "WindUI failed to load")

    local window = WindUI:CreateWindow({
        Title = "CeszParadiseHub",
        Icon = "sprout",
        ToggleKey = Enum.KeyCode.K,
        Size = UDim2.fromOffset(760, 520),
        Theme = "Dark",
        OpenButton = {
            Enabled = true,
            OnlyMobile = false,
            Title = "CeszParadiseHub",
            Icon = "sprout",
        },
    })

    ctx.ui = ctx.ui or {}
    ctx.ui.pages = {}
    ctx.ui.tabBtns = {}
    ctx.ui.windWindow = window
    ctx.ui.logLines = ctx.state.logLines
    ctx.state.isAlive = true

    local tabs = {}
    local tabIcons = {
        Pet = "paw-print", Farm = "wheat", Hatch = "egg",
        Elephant = "rabbit", Flow = "git-branch", Leveling = "zap",
        Mutation = "flask-conical", Inventory = "backpack",
        Shop = "shopping-cart", Misc = "settings",
    }

    function ctx.alive()
        return ctx.state.isAlive ~= false
    end
    function ctx.setStatus(value)
        ctx.state.status = tostring(value)
    end
    function ctx.log(message)
        local lines = ctx.state.logLines
        lines[#lines + 1] = os.date("%H:%M:%S ") .. tostring(message)
        while #lines > 12 do table.remove(lines, 1) end
    end
    function ctx.notify(message)
        pcall(function()
            WindUI:Notify({ Title = "CeszParadiseHub", Content = tostring(message), Duration = 3 })
        end)
    end

    local function asValues(options)
        local out = {}
        for _, option in ipairs(options or {}) do
            out[#out + 1] = type(option) == "table"
                and (option.display or option.name or option.value) or option
        end
        return out
    end

    local function parentTab(parent)
        return parent and (parent.__windTab or parent) or tabs.Misc
    end

    local function makePage(name, title, icon)
        local tab = tabs[name] or window:Tab({ Title = title or name, Icon = icon or tabIcons[name] })
        tabs[name] = tab
        local page = { __windTab = tab, Visible = false }
        ctx.ui.pages[name] = page
        ctx.ui.tabBtns[name] = {
            setActive = function(active)
                if active and tab.Select then pcall(function() tab:Select() end) end
            end,
        }
        return page
    end

    local function makeAccordion(parent, title)
        local tab = parentTab(parent)
        if tab.Section then
            local ok, section = pcall(function() return tab:Section({ Title = title }) end)
            if ok and section then return section end
        end
        return tab
    end

    local function makeToggle(parent, title, desc, getValue, setValue)
        local tab = parentTab(parent)
        local control = tab:Toggle({
            Title = title,
            Desc = desc,
            Value = type(getValue) == "function" and getValue() or false,
            Callback = function(value)
                if setValue then setValue(value) end
            end,
        })
        return setmetatable({ _windControl = control }, {
            __index = control,
            __call = function()
                if control and control.Set and getValue then control:Set(getValue()) end
            end,
        })
    end

    local function makeInput(parent, title, desc, getValue, setValue)
        local tab = parentTab(parent)
        return tab:Input({
            Title = title,
            Desc = desc,
            Value = type(getValue) == "function" and tostring(getValue()) or "",
            Callback = function(value)
                if setValue then setValue(value) end
            end,
        })
    end

    local function makeSingleDropdown(parent, title, desc, getOptions, getValue, setValue)
        local tab = parentTab(parent)
        local options = type(getOptions) == "function" and getOptions() or {}
        local displayToCode = {}
        local codeToDisplay = {}
        for _, option in ipairs(options) do
            if type(option) == "table" then
                displayToCode[option.display or option.name or option.value] = option.name or option.value
                codeToDisplay[option.name or option.value] = option.display or option.name or option.value
            end
        end
        return tab:Dropdown({
            Title = title,
            Desc = desc,
            Values = asValues(options),
            Value = type(getValue) == "function" and codeToDisplay[getValue()] or nil,
            AllowNone = true,
            SearchBarEnabled = #options > 12,
            Callback = function(value)
                if setValue then setValue(displayToCode[value] or value) end
            end,
        })
    end

    local function makeMultiDropdown(parent, title, desc, options, selected, onChange)
        local tab = parentTab(parent)
        local values, displayToValue = {}, {}
        for _, option in ipairs(options or {}) do
            local display = type(option) == "table" and (option.display or option.name or option.value) or option
            local value = type(option) == "table" and (option.value or option.name) or option
            values[#values + 1] = display
            displayToValue[display] = value
        end
        return tab:Dropdown({
            Title = title,
            Desc = desc,
            Values = values,
            Multi = true,
            AllowNone = true,
            SearchBarEnabled = true,
            Callback = function(items)
                for key in pairs(selected or {}) do selected[key] = nil end
                for _, value in ipairs(items or {}) do selected[displayToValue[value] or value] = true end
                if onChange then onChange() end
            end,
        })
    end

    local function makeMultiDropdownDyn(parent, title, desc, getOptions, selected, onChange)
        local tab = parentTab(parent)
        local values = type(getOptions) == "function" and getOptions() or {}
        local displayToValue = {}
        for _, option in ipairs(values) do
            if type(option) == "table" then
                displayToValue[option.display or option.name or option.value] = option.value or option.name
            end
        end
        local dropdown = tab:Dropdown({
            Title = title,
            Desc = desc,
            Values = asValues(values),
            Multi = true,
            AllowNone = true,
            SearchBarEnabled = true,
            Callback = function(items)
                for key in pairs(selected or {}) do selected[key] = nil end
                for _, value in ipairs(items or {}) do
                    selected[displayToValue[value] or value] = true
                end
                if onChange then onChange() end
            end,
        })
        return dropdown
    end

    local function makeButton(parent, title, desc, callback)
        return parentTab(parent):Button({ Title = title, Desc = desc, Callback = callback })
    end

    local function makeSubTabs(parent, list, defaultId)
        local tabsOut = {}
        for _, item in ipairs(list or {}) do
            local id = item.id or item
            tabsOut[id] = parentTab(parent)
        end
        return { wrapper = parent, pages = tabsOut, selectTab = function() end, bottomBarFrame = parent }
    end

    local function makeStartStopBar(parent, getRunning, onStart, onStop)
        local tab = parentTab(parent)
        tab:Button({ Title = "START", Callback = onStart })
        tab:Button({ Title = "STOP", Color = Color3.fromRGB(220, 70, 90), Callback = onStop })
    end

    ctx.makePage = makePage
    ctx.makeAccordion = makeAccordion
    ctx.makeToggle = makeToggle
    ctx.makeInput = makeInput
    ctx.makeSingleDropdown = makeSingleDropdown
    ctx.makeMultiDropdown = makeMultiDropdown
    ctx.makeMultiDropdownDyn = makeMultiDropdownDyn
    ctx.makeButton = makeButton
    ctx.makeSubTabs = makeSubTabs
    ctx.makeStartStopBar = makeStartStopBar
    ctx.C = ctx.C or {}
    ctx.F = ctx.F or {}
    ctx.ui.windTabs = tabs

    WindUI:Notify({ Title = "CeszParadiseHub", Content = "WindUI shell loaded", Duration = 3 })
end
