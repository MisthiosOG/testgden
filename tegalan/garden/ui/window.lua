-- WindUI compatibility shell.
-- Automation modules remain untouched: this file only adapts the existing
-- ctx UI contract to WindUI controls.
return function(ctx)
    print("[GAGHub][WINDUI] garden shell begin")
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
    local compile = loadstring or load
    local WindUI = compile(game:HttpGet(
        "https://github.com/Footagesus/WindUI/releases/download/"
            .. version .. "/main.lua"
    ))()
    assert(WindUI and WindUI.CreateWindow, "WindUI failed to load")

    local window = WindUI:CreateWindow({
        Title = "iStealth WindUI Garden",
        Icon = "sprout",
        ToggleKey = Enum.KeyCode.K,
        Size = UDim2.fromOffset(760, 520),
        Theme = "Dark",
        OpenButton = {
            Enabled = true,
            OnlyMobile = false,
            Title = "iStealth WindUI Garden",
            Icon = "sprout",
        },
    })
    print("[GAGHub][WINDUI] garden window created")

    ctx.ui = ctx.ui or {}
    ctx.ui.pages = {}
    ctx.ui.tabBtns = {}
    ctx.ui.windWindow = window
    ctx.ui.logLines = ctx.state.logLines
    ctx.state.isAlive = true

    -- Legacy pages still create layout-only Frames through ctx.mk. Keep those
    -- objects alive in a hidden compatibility host; visible controls come from
    -- WindUI adapters below. This preserves page/module logic without rendering
    -- the old shell or attempting to parent Instances to a WindUI tab object.
    local compatGui = Instance.new("ScreenGui")
    compatGui.Name = "iStealthGardenCompat"
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
        return (type(parent) == "table" and parent.__windTab)
            or compatOwners[parent] or (parent and parent.__windTab)
            or tabs.Misc
    end

    local function makePage(name, title, icon)
        -- Ignore emoji icons from pages.lua; WindUI resolves lucide names only,
        -- unknown names trigger remote icon fetches that stall window build.
        local tab = tabs[name] or window:Tab({ Title = title or name, Icon = tabIcons[name] })
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
        -- Return a page-style wrapper (not the raw tab) so nested accordions
        -- and mk() calls resolve through __windTab instead of falling back
        -- to tabs.Misc. Legacy open/close states degrade to a flat list of
        -- controls on the owning sub-tab, preserving creation order.
        return { __windTab = tab, Visible = false }
    end

    -- Every adapter is crash-proof: a failing getter or failing WindUI control
    -- logs one line and returns a harmless stub instead of killing pages.lua
    -- (one throw used to blank every tab built after it).
    local function safe(tag, fn)
        local ok, result = pcall(fn)
        if not ok then
            print("[GAGHub][WINDUI] adapter fail " .. tostring(tag) .. ": " .. tostring(result))
            return nil
        end
        return result
    end

    local function makeToggle(parent, title, desc, getValue, setValue)
        task.wait()
        local tab = parentTab(parent)
        local initial = (type(getValue) == "function" and safe("toggle-get", getValue)) or false
        local control = safe("toggle", function()
            return tab:Toggle({
                Title = title,
                Desc = desc,
                Value = initial == true,
                Callback = function(value)
                    if setValue then pcall(setValue, value) end
                end,
            })
        end)
        return setmetatable({ _windControl = control }, {
            __index = control,
            __call = function()
                if control and control.Set and getValue then
                    local ok, v = pcall(getValue)
                    if ok and v ~= nil then pcall(function() control:Set(v == true) end) end
                end
            end,
        })
    end

    local function makeInput(parent, title, desc, getValue, setValue)
        task.wait()
        local tab = parentTab(parent)
        local initial = (type(getValue) == "function" and safe("input-get", getValue)) or nil
        return safe("input", function()
            return tab:Input({
                Title = title,
                Desc = desc,
                Value = initial ~= nil and tostring(initial) or "",
                Callback = function(value)
                    if setValue then pcall(setValue, value) end
                end,
            })
        end)
    end

    local function makeSingleDropdown(parent, title, desc, getOptions, getValue, setValue)
        task.wait()
        local tab = parentTab(parent)
        local options = (type(getOptions) == "function" and safe("dropdown-get", getOptions)) or {}
        if type(options) ~= "table" then options = {} end
        local displayToCode = {}
        local codeToDisplay = {}
        for _, option in ipairs(options) do
            if type(option) == "table" then
                displayToCode[option.display or option.name or option.value] = option.name or option.value
                codeToDisplay[option.name or option.value] = option.display or option.name or option.value
            end
        end
        local current = (type(getValue) == "function" and safe("dropdown-cur", getValue)) or nil
        return safe("dropdown", function()
            return tab:Dropdown({
                Title = title,
                Desc = desc,
                Values = asValues(options),
                Value = current ~= nil and codeToDisplay[current] or nil,
                AllowNone = true,
                SearchBarEnabled = #options > 25,
                Callback = function(value)
                    if setValue then pcall(setValue, displayToCode[value] or value) end
                end,
            })
        end)
    end

    local function makeMultiDropdown(parent, title, desc, options, selected, onChange)
        task.wait()
        local tab = parentTab(parent)
        local values, displayToValue = {}, {}
        for _, option in ipairs(options or {}) do
            local display = type(option) == "table" and (option.display or option.name or option.value) or option
            local value = type(option) == "table" and (option.value or option.name) or option
            values[#values + 1] = display
            displayToValue[display] = value
        end
        return safe("multidd", function()
            return tab:Dropdown({
                Title = title,
                Desc = desc,
                Values = values,
                Multi = true,
                AllowNone = true,
                SearchBarEnabled = #values > 25,
                Callback = function(items)
                    for key in pairs(selected or {}) do selected[key] = nil end
                    for _, value in ipairs(items or {}) do selected[displayToValue[value] or value] = true end
                    if onChange then pcall(onChange) end
                end,
            })
        end)
    end

    local function makeMultiDropdownDyn(parent, title, desc, getOptions, selected, onChange)
        task.wait()
        local tab = parentTab(parent)
        local values = (type(getOptions) == "function" and safe("dyn-get", getOptions)) or {}
        if type(values) ~= "table" then values = {} end
        local displayToValue = {}
        for _, option in ipairs(values) do
            if type(option) == "table" then
                displayToValue[option.display or option.name or option.value] = option.value or option.name
            end
        end
        return safe("dyndd", function()
            return tab:Dropdown({
                Title = title,
                Desc = desc,
                Values = asValues(values),
                Multi = true,
                AllowNone = true,
                SearchBarEnabled = #values > 25,
                Callback = function(items)
                    for key in pairs(selected or {}) do selected[key] = nil end
                    for _, value in ipairs(items or {}) do
                        selected[displayToValue[value] or value] = true
                    end
                    if onChange then pcall(onChange) end
                end,
            })
        end)
    end

    local function makeButton(parent, title, desc, callback)
        task.wait()
        return safe("button", function()
            return parentTab(parent):Button({ Title = title, Desc = desc, Callback = callback })
        end)
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

    WindUI:Notify({ Title = "iStealth WindUI Garden", Content = "BUILD windui-2026-10-27", Duration = 5 })
end
