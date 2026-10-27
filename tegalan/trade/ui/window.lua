--[[ window.lua — jendela utama trade PINK ROYALE (720x470):
     Sidebar modern, player profile card, glowing title bar, responsive auto-scaling,
     modal konfirmasi close, floating maximize jewel, toast notifications, UI setting helpers. ]]
return function(ctx)
	local Players          = ctx.Services.Players or game:GetService("Players")
	local UserInputService = ctx.Services.UserInputService or game:GetService("UserInputService")
	local TS               = game:GetService("TweenService")
	local LP  = ctx.LP or Players.LocalPlayer
	local CFG = ctx.CFG
	local C   = ctx.C
	local F   = ctx.F
	local mk, corner, stroke, pad, grad = ctx.mk, ctx.corner, ctx.stroke, ctx.pad, ctx.grad

	ctx.ui = ctx.ui or {}
	ctx.ui.pages   = ctx.ui.pages or {}
	ctx.ui.tabBtns = ctx.ui.tabBtns or {}

	----------------------------------------------------------------- bersihkan GUI lama
	pcall(function()
		local host = (gethui and gethui()) or game:GetService("CoreGui")
		for _, nm in ipairs({ "GAGSeller", "CeszParadiseTrade", "GAGTrade" }) do
			local old = host:FindFirstChild(nm); if old then old:Destroy() end
			local pg = LP:FindFirstChild("PlayerGui")
			if pg and pg:FindFirstChild(nm) then pg[nm]:Destroy() end
		end
	end)

	local gui = Instance.new("ScreenGui")
	gui.Name = "CeszParadiseTrade"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = LP:WaitForChild("PlayerGui")
	ctx.state.gui = gui
	ctx.state.isAlive = true
	gui.Destroying:Connect(function()
		ctx.state.isAlive = false
	end)

	----------------------------------------------------------------- Floating Maximize Jewel
	local maxIcon = mk("TextButton", {
		Size = UDim2.fromOffset(50, 50),
		Position = UDim2.new(0, 16, 0.5, -25),
		BackgroundColor3 = C.panel,
		Text = "✦",
		Font = F.bold,
		TextSize = 22,
		TextColor3 = C.acc,
		Visible = false,
		Active = true,
		ZIndex = 100,
	}, gui)
	corner(maxIcon, 25)
	stroke(maxIcon, C.acc, 2, 0.1)

	local maxGlow = mk("Frame", {
		Size = UDim2.new(1, 14, 1, 14),
		Position = UDim2.new(0, -7, 0, -7),
		BackgroundColor3 = C.acc,
		BackgroundTransparency = 0.75,
		BorderSizePixel = 0,
		ZIndex = 99,
	}, maxIcon)
	corner(maxGlow, 30)

	pcall(function()
		local logo = ctx.getLogo and ctx.getLogo()
		if logo then
			maxIcon.Text = ""
			local img = mk("ImageLabel", {
				Size = UDim2.fromScale(1, 1),
				Position = UDim2.fromScale(0, 0),
				BackgroundTransparency = 1,
				Image = logo,
				ScaleType = Enum.ScaleType.Fit,
				ZIndex = 101,
			}, maxIcon)
			corner(img, 25)
		end
	end)

	do
		local dragging, ds, sp
		maxIcon.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				dragging = true; ds = i.Position; sp = maxIcon.Position
			end
		end)
		UserInputService.InputChanged:Connect(function(i)
			if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
				local d = i.Position - ds
				maxIcon.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
			end
		end)
		UserInputService.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
	end

	----------------------------------------------------------------- Main Window (720x470)
	local DEFAULT_W, DEFAULT_H = 720, 470
	local main = mk("Frame", {
		Size = UDim2.fromOffset(DEFAULT_W, DEFAULT_H),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = C.bg,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Active = true,
	}, gui)
	corner(main, 14)
	stroke(main, C.stroke, 1.8, 0.25)

	local innerAmbient = mk("Frame", {
		Name = "innerAmbient",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = C.acc,
		BackgroundTransparency = 0.94,
		BorderSizePixel = 0,
	}, main)
	corner(innerAmbient, 14)

	TS:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.02,
	}):Play()

	-- fitScale: margin 40px, clamp 0.4 - 1.0
	local uiScale = Instance.new("UIScale"); uiScale.Parent = main
	local function fitScale()
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		local w = (main.Size.X.Offset > 0) and main.Size.X.Offset or DEFAULT_W
		local h = (main.Size.Y.Offset > 0) and main.Size.Y.Offset or DEFAULT_H
		local s = math.min(1, (vp.X - 40) / w, (vp.Y - 40) / h)
		uiScale.Scale = math.clamp(s, 0.4, 1.0)
	end
	fitScale()
	pcall(function()
		local cam = workspace.CurrentCamera
		if cam then cam:GetPropertyChangedSignal("ViewportSize"):Connect(fitScale) end
	end)

	----------------------------------------------------------------- Modern Title Bar
	local titleBar = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundColor3 = C.panel,
		BorderSizePixel = 0,
		ZIndex = 5,
	}, main)
	corner(titleBar, 16)

	local titleGrad = mk("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = C.acc,
		BackgroundTransparency = 0.88,
		BorderSizePixel = 0,
		ZIndex = 6,
	}, titleBar)
	corner(titleGrad, 16)
	grad(titleGrad, 0, C.acc, C.acc2)

	local titleLine = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 2),
		Position = UDim2.new(0, 0, 1, -2),
		BackgroundColor3 = C.acc,
		BorderSizePixel = 0,
		ZIndex = 7,
	}, titleBar)
	grad(titleLine, 0, C.acc, C.acc2)

	local titleIcon = mk("TextLabel", {
		Size = UDim2.fromOffset(30, 48),
		Position = UDim2.fromOffset(16, 0),
		BackgroundTransparency = 1,
		Text = "✦",
		Font = F.title,
		TextSize = 20,
		TextColor3 = C.acc,
		ZIndex = 8,
	}, titleBar)

	pcall(function()
		local logo = ctx.getLogo and ctx.getLogo()
		if logo then
			titleIcon.Text = ""
			local tImg = mk("ImageLabel", {
				Size = UDim2.fromOffset(26, 26),
				Position = UDim2.fromOffset(2, 11),
				BackgroundTransparency = 1,
				Image = logo,
				ScaleType = Enum.ScaleType.Fit,
				ZIndex = 9,
			}, titleIcon)
			corner(tImg, 13)
		end
	end)

	local titleLabel = mk("TextLabel", {
		Size = UDim2.new(0, 120, 1, 0),
		Position = UDim2.fromOffset(46, 0),
		BackgroundTransparency = 1,
		Text = "CeszParadise",
		Font = F.title,
		TextSize = 15,
		TextColor3 = C.txt,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 8,
	}, titleBar)

	local subPill = mk("Frame", {
		Size = UDim2.fromOffset(105, 24),
		Position = UDim2.fromOffset(168, 12),
		BackgroundColor3 = C.row,
		BorderSizePixel = 0,
		ZIndex = 8,
	}, titleBar)
	corner(subPill, 12)
	stroke(subPill, C.acc, 1, 0.5)
	pad(subPill, 6, 6, 0, 0)

	local subLabel = mk("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "❖ GAG Trade",
		Font = F.bold,
		TextSize = 10.5,
		TextColor3 = C.accSoft,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 9,
	}, subPill)

	do
		local dragging, ds, sp
		titleBar.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				dragging = true; ds = i.Position; sp = main.Position
			end
		end)
		UserInputService.InputChanged:Connect(function(i)
			if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
				local d = i.Position - ds
				main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
			end
		end)
		UserInputService.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
	end

	local function makeTitleBtn(label, posX, isClose)
		local btn = mk("TextButton", {
			Size = UDim2.fromOffset(30, 30),
			Position = UDim2.new(1, posX, 0, 9),
			BackgroundColor3 = C.row,
			Text = label,
			Font = F.bold,
			TextSize = 13,
			TextColor3 = C.txt,
			ZIndex = 10,
			AutoButtonColor = false,
		}, titleBar)
		corner(btn, 8)
		stroke(btn, isClose and C.red or C.strokeSub, 1, 0.4)

		btn.MouseEnter:Connect(function()
			TS:Create(btn, TweenInfo.new(0.15), {
				BackgroundColor3 = isClose and C.red or C.acc,
				TextColor3 = Color3.new(1, 1, 1),
			}):Play()
		end)
		btn.MouseLeave:Connect(function()
			TS:Create(btn, TweenInfo.new(0.15), {
				BackgroundColor3 = C.row,
				TextColor3 = C.txt,
			}):Play()
		end)
		return btn
	end

	local minBtn   = makeTitleBtn("—", -76, false)
	local closeBtn = makeTitleBtn("✕", -38, true)

	minBtn.MouseButton1Click:Connect(function()
		TS:Create(main, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Size = UDim2.fromOffset(0, 0),
			BackgroundTransparency = 1,
		}):Play()
		task.delay(0.2, function()
			main.Visible = false
			maxIcon.Visible = true
		end)
	end)

	maxIcon.MouseButton1Click:Connect(function()
		maxIcon.Visible = false
		main.Visible = true
		main.Size = UDim2.fromOffset(0, 0)
		fitScale()
		TS:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(DEFAULT_W, DEFAULT_H),
			BackgroundTransparency = 0.02,
		}):Play()
	end)

	----------------------------------------------------------------- Dedicated FPS Monitor Card (Paten & Jelas)
	local fpsCard = mk("Frame", {
		Size = UDim2.fromOffset(116, 32),
		Position = UDim2.new(1, -202, 0.5, -16),
		BackgroundColor3 = C.row,
		BorderSizePixel = 0,
		ZIndex = 10,
	}, titleBar)
	corner(fpsCard, 10)
	local fpsStroke = stroke(fpsCard, C.strokeSub, 1.2, 0.3)

	local fpsGlow = mk("Frame", {
		Size = UDim2.new(0.6, 0, 0, 2),
		Position = UDim2.new(0.2, 0, 0, 0),
		BackgroundColor3 = C.acc,
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		ZIndex = 11,
	}, fpsCard)
	corner(fpsGlow, 2)
	grad(fpsGlow, 0, C.acc, C.acc2)

	local ledHalo = mk("Frame", {
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.fromOffset(10, 9),
		BackgroundColor3 = Color3.fromRGB(80, 230, 130),
		BackgroundTransparency = 0.75,
		BorderSizePixel = 0,
		ZIndex = 11,
	}, fpsCard)
	corner(ledHalo, 7)

	local ledDot = mk("Frame", {
		Size = UDim2.fromOffset(6, 6),
		Position = UDim2.fromOffset(14, 13),
		BackgroundColor3 = Color3.fromRGB(80, 230, 130),
		BorderSizePixel = 0,
		ZIndex = 12,
	}, fpsCard)
	corner(ledDot, 3)

	local fpsNum = mk("TextLabel", {
		Size = UDim2.new(0, 48, 1, 0),
		Position = UDim2.fromOffset(26, 0),
		BackgroundTransparency = 1,
		Text = "60",
		Font = F.bold,
		TextSize = 16,
		TextColor3 = Color3.fromRGB(80, 230, 130),
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 12,
	}, fpsCard)

	local fpsUnit = mk("TextLabel", {
		Size = UDim2.new(1, -78, 1, 0),
		Position = UDim2.fromOffset(78, 0),
		BackgroundTransparency = 1,
		Text = "FPS",
		Font = F.bold,
		TextSize = 11,
		TextColor3 = C.sub,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 12,
	}, fpsCard)

	fpsCard.MouseEnter:Connect(function()
		TS:Create(fpsStroke, TweenInfo.new(0.2), { Color = C.acc, Transparency = 0 }):Play()
		TS:Create(fpsCard, TweenInfo.new(0.2), { BackgroundColor3 = C.rowAlt }):Play()
	end)
	fpsCard.MouseLeave:Connect(function()
		TS:Create(fpsStroke, TweenInfo.new(0.2), { Color = C.strokeSub, Transparency = 0.3 }):Play()
		TS:Create(fpsCard, TweenInfo.new(0.2), { BackgroundColor3 = C.row }):Play()
	end)

	do
		local RunService = game:GetService("RunService")
		local frameCount = 0
		local lastUpdate = tick()
		local fpsConn
		fpsConn = RunService.RenderStepped:Connect(function()
			if not ctx.state.isAlive then
				if fpsConn then fpsConn:Disconnect(); fpsConn = nil end
				return
			end
			frameCount = frameCount + 1
			local now = tick()
			local diff = now - lastUpdate
			if diff >= 0.5 then
				local fps = math.clamp(math.round(frameCount / diff), 1, 999)
				fpsNum.Text = tostring(fps)
				if fps >= 50 then
					local col = Color3.fromRGB(80, 230, 130)
					ledHalo.BackgroundColor3 = col
					ledDot.BackgroundColor3 = col
					fpsNum.TextColor3 = col
				elseif fps >= 30 then
					local col = Color3.fromRGB(250, 195, 60)
					ledHalo.BackgroundColor3 = col
					ledDot.BackgroundColor3 = col
					fpsNum.TextColor3 = col
				else
					local col = Color3.fromRGB(250, 80, 80)
					ledHalo.BackgroundColor3 = col
					ledDot.BackgroundColor3 = col
					fpsNum.TextColor3 = col
				end
				frameCount = 0
				lastUpdate = now
			end
		end)
	end

	----------------------------------------------------------------- Confirm Close Dialog (Modal)
	local function confirmClose()
		local overlay = mk("TextButton", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 50,
		}, gui)

		local box = mk("Frame", {
			Size = UDim2.fromOffset(320, 160),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3 = C.panel,
			BorderSizePixel = 0,
			ZIndex = 51,
		}, overlay)
		corner(box, 14)
		stroke(box, C.acc, 1.5, 0.3)

		local boxShine = mk("Frame", {
			Size = UDim2.new(1, 0, 0, 3),
			BackgroundColor3 = C.acc,
			BorderSizePixel = 0,
			ZIndex = 52,
		}, box)
		corner(boxShine, 14)
		grad(boxShine, 0, C.acc, C.acc2)

		mk("TextLabel", {
			Size = UDim2.new(1, -24, 0, 36),
			Position = UDim2.fromOffset(12, 18),
			BackgroundTransparency = 1,
			Text = "✦ Close CeszParadiseHub?",
			Font = F.title,
			TextSize = 17,
			TextColor3 = C.accSoft,
			ZIndex = 52,
		}, box)

		mk("TextLabel", {
			Size = UDim2.new(1, -24, 0, 24),
			Position = UDim2.fromOffset(12, 54),
			BackgroundTransparency = 1,
			Text = "Apakah kamu yakin ingin menutup hub ini?",
			Font = F.reg,
			TextSize = 13,
			TextColor3 = C.sub,
			ZIndex = 52,
		}, box)

		local noBtn = mk("TextButton", {
			Size = UDim2.fromOffset(130, 40),
			Position = UDim2.new(0, 20, 1, -52),
			BackgroundColor3 = C.row,
			Text = "Batal",
			Font = F.bold,
			TextSize = 14,
			TextColor3 = C.txt,
			ZIndex = 52,
			AutoButtonColor = false,
		}, box)
		corner(noBtn, 10)
		stroke(noBtn, C.strokeSub, 1, 0.5)

		local yesBtn = mk("TextButton", {
			Size = UDim2.fromOffset(130, 40),
			Position = UDim2.new(1, -150, 1, -52),
			BackgroundColor3 = C.red,
			Text = "Ya, Tutup",
			Font = F.bold,
			TextSize = 14,
			TextColor3 = Color3.new(1, 1, 1),
			ZIndex = 52,
			AutoButtonColor = false,
		}, box)
		corner(yesBtn, 10)
		stroke(yesBtn, C.red, 1.2, 0.2)

		noBtn.MouseEnter:Connect(function() noBtn.BackgroundColor3 = C.rowHover end)
		noBtn.MouseLeave:Connect(function() noBtn.BackgroundColor3 = C.row end)
		noBtn.MouseButton1Click:Connect(function() overlay:Destroy() end)
		yesBtn.MouseButton1Click:Connect(function() gui:Destroy() end)
	end
	closeBtn.MouseButton1Click:Connect(confirmClose)

	----------------------------------------------------------------- Toast Notifications (ctx.notify)
	local toastStack = {}
	function ctx.notify(msg)
		if not gui or not gui.Parent then return end
		while #toastStack >= 3 do
			local old = table.remove(toastStack, 1)
			if old and old.card and old.card.Parent then
				pcall(function() old.card:Destroy() end)
			end
		end

		local toast = mk("Frame", {
			Size = UDim2.new(1, -40, 0, 32),
			Position = UDim2.new(0, 20, 0, 52 + #toastStack * 36),
			BackgroundColor3 = C.panel,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 60,
		}, main)
		corner(toast, 8)
		local tStroke = stroke(toast, C.acc, 1, 0.3)
		pad(toast, 10, 10, 0, 0)

		local tIcon = mk("TextLabel", {
			Size = UDim2.fromOffset(20, 32),
			Position = UDim2.fromOffset(0, 0),
			BackgroundTransparency = 1,
			Text = "✦",
			Font = F.bold,
			TextSize = 13,
			TextColor3 = C.acc,
			TextTransparency = 1,
			ZIndex = 61,
		}, toast)

		local tMsg = mk("TextLabel", {
			Size = UDim2.new(1, -26, 1, 0),
			Position = UDim2.fromOffset(26, 0),
			BackgroundTransparency = 1,
			Text = tostring(msg),
			Font = F.reg,
			TextSize = 12,
			TextColor3 = C.txt,
			TextTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 61,
		}, toast)

		local entry = { card = toast }
		table.insert(toastStack, entry)

		TS:Create(toast, TweenInfo.new(0.2), { BackgroundTransparency = 0.05 }):Play()
		TS:Create(tMsg, TweenInfo.new(0.2), { TextTransparency = 0 }):Play()
		TS:Create(tIcon, TweenInfo.new(0.2), { TextTransparency = 0 }):Play()

		task.delay(2.0, function()
			if toast and toast.Parent then
				local tw = TS:Create(toast, TweenInfo.new(0.25), { BackgroundTransparency = 1 })
				TS:Create(tMsg, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
				TS:Create(tIcon, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
				tw:Play()
				tw.Completed:Connect(function()
					pcall(function() toast:Destroy() end)
					for i, v in ipairs(toastStack) do
						if v == entry then table.remove(toastStack, i); break end
					end
				end)
			end
		end)
	end

	----------------------------------------------------------------- Left Sidebar (180px)
	local sidebar = mk("Frame", {
		Size = UDim2.new(0, 180, 1, -54),
		Position = UDim2.fromOffset(8, 48),
		BackgroundColor3 = C.panel,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, main)
	corner(sidebar, 12)
	stroke(sidebar, C.strokeSub, 1, 0.5)
	pad(sidebar, 8, 8, 8, 8)

	local tabButtonsFrame = mk("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, -58),
		Position = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = C.acc,
		ScrollBarImageTransparency = 0.5,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingEnabled = true,
	}, sidebar)
	mk("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, tabButtonsFrame)

	local profileCard = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 46),
		Position = UDim2.new(0, 0, 1, -46),
		BackgroundColor3 = C.row,
		BorderSizePixel = 0,
	}, sidebar)
	corner(profileCard, 10)
	stroke(profileCard, C.stroke, 1.2, 0.4)
	pad(profileCard, 6, 6, 4, 4)

	local avatar = mk("ImageLabel", {
		Size = UDim2.fromOffset(34, 34),
		BackgroundColor3 = C.panel,
		BorderSizePixel = 0,
	}, profileCard)
	corner(avatar, 17)
	stroke(avatar, C.acc, 1.5, 0.2)
	pcall(function()
		avatar.Image = Players:GetUserThumbnailAsync(LP.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
	end)

	local nameLabel = mk("TextLabel", {
		Size = UDim2.new(1, -42, 0, 18),
		Position = UDim2.fromOffset(42, 2),
		BackgroundTransparency = 1,
		Text = LP.DisplayName or LP.Name,
		Font = F.bold,
		TextSize = 12,
		TextColor3 = C.txt,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, profileCard)

	local statusPill = mk("TextLabel", {
		Size = UDim2.new(1, -42, 0, 16),
		Position = UDim2.fromOffset(42, 18),
		BackgroundTransparency = 1,
		Text = "Trade Plaza ✦",
		Font = F.bold,
		TextSize = 10,
		TextColor3 = C.accSoft,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, profileCard)

	----------------------------------------------------------------- Right Content Frame
	local content = mk("Frame", {
		Position = UDim2.fromOffset(196, 50),
		Size = UDim2.new(1, -206, 1, -66),
		BackgroundTransparency = 1,
	}, main)

	----------------------------------------------------------------- Resize Grip (Smooth & Subtle)
	local grip = mk("TextButton", {
		Size = UDim2.fromOffset(22, 22),
		Position = UDim2.new(1, -24, 1, -24),
		BackgroundTransparency = 1,
		Text = "◢",
		Font = F.bold,
		TextSize = 14,
		TextColor3 = C.strokeSub,
		AutoButtonColor = false,
		Active = true,
		ZIndex = 20,
	}, main)
	grip.MouseEnter:Connect(function() grip.TextColor3 = C.acc end)
	grip.MouseLeave:Connect(function() grip.TextColor3 = C.strokeSub end)
	do
		local rz, ds, ss
		grip.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				rz = true; ds = i.Position; ss = Vector2.new(main.Size.X.Offset, main.Size.Y.Offset)
			end
		end)
		UserInputService.InputChanged:Connect(function(i)
			if rz and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
				local scale = uiScale.Scale > 0 and uiScale.Scale or 1
				local d = i.Position - ds
				local w = math.clamp(ss.X + d.X / scale, 480, 1600)
				local h = math.clamp(ss.Y + d.Y / scale, 320, 1000)
				main.Size = UDim2.fromOffset(w, h)
				fitScale()
			end
		end)
		UserInputService.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				rz = false
			end
		end)
	end

	----------------------------------------------------------------- Status Footer
	local statusFooter = mk("Frame", {
		Size = UDim2.new(1, -214, 0, 20),
		Position = UDim2.new(0, 202, 1, -24),
		BackgroundTransparency = 1,
	}, main)
	local statusText = mk("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "○ Status: idle  |  Loop: OFF",
		Font = F.bold,
		TextSize = 11,
		TextColor3 = C.sub,
		TextXAlignment = Enum.TextXAlignment.Left,
		Visible = false,
	}, statusFooter)

	function ctx.setStatus(s)
		local isActive = tostring(s):lower():find("active") ~= nil or tostring(s):lower():find("on") ~= nil
		statusText.Text = ("%s Status: %s  |  Loop: %s"):format(
			isActive and "●" or "○",
			tostring(s),
			CFG.autoSell and "ON ✦" or "OFF"
		)
		statusText.TextColor3 = isActive and C.green or C.sub
	end

	----------------------------------------------------------------- Logger
	local logLines = ctx.state.logLines
	function ctx.log(msg)
		table.insert(logLines, os.date("%H:%M:%S ") .. msg)
		while #logLines > 12 do table.remove(logLines, 1) end
		if ctx.ui.logBox then ctx.ui.logBox.Text = table.concat(logLines, "\n") end
	end

	----------------------------------------------------------------- Sidebar Tab System (makePage)
	local TAB_SECTIONS = {
		Sell = "COMMERCE",
		Buy = "COMMERCE",
		Inventory = "COMMERCE",
		Misc = "SYSTEM",
	}
	local SECTION_ORDERS = {
		COMMERCE = 100,
		SYSTEM = 200,
	}

	local createdSections = {}
	local function ensureSidebarSection(secName)
		if not secName or createdSections[secName] then return end
		createdSections[secName] = true
		local secH = mk("TextLabel", {
			Size = UDim2.new(1, 0, 0, 20),
			BackgroundTransparency = 1,
			Text = tostring(secName):upper(),
			Font = F.bold,
			TextSize = 10,
			TextColor3 = C.sub,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = SECTION_ORDERS[secName] or 999,
		}, tabButtonsFrame)
		pad(secH, 6, 0, 2, 0)
	end

	local function makePage(name, titleText, icon, order, fixedLayout, customSection)
		local pages, tabBtns = ctx.ui.pages, ctx.ui.tabBtns
		local secName = customSection or TAB_SECTIONS[name] or "COMMERCE"
		ensureSidebarSection(secName)

		local baseOrder = (SECTION_ORDERS[secName] or 100) + (order or 1)

		local btn = mk("TextButton", {
			Size = UDim2.new(1, 0, 0, 34),
			BackgroundColor3 = C.row,
			BackgroundTransparency = 0,
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = baseOrder,
		}, tabButtonsFrame)
		corner(btn, 8)
		pad(btn, 10, 8, 0, 0)

		local bar = mk("Frame", {
			Size = UDim2.new(0, 3, 1, -8),
			Position = UDim2.new(0, -10, 0, 4),
			BackgroundColor3 = C.acc,
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = 5,
		}, btn)
		corner(bar, 2)

		local iconLbl = mk("TextLabel", {
			Size = UDim2.fromOffset(20, 34),
			Position = UDim2.fromOffset(0, 0),
			BackgroundTransparency = 1,
			Text = icon or "✦",
			Font = F.bold,
			TextSize = 14,
			TextColor3 = C.sub,
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 4,
		}, btn)

		local nameLbl = mk("TextLabel", {
			Size = UDim2.new(1, -26, 1, 0),
			Position = UDim2.fromOffset(26, 0),
			BackgroundTransparency = 1,
			Text = name,
			Font = F.bold,
			TextSize = 13,
			TextColor3 = C.sub,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 4,
		}, btn)

		local function setActive(isActive)
			if isActive then
				TS:Create(btn, TweenInfo.new(0.15), {
					BackgroundColor3 = C.rowAlt,
					BackgroundTransparency = 0,
				}):Play()
				TS:Create(iconLbl, TweenInfo.new(0.15), { TextColor3 = C.acc }):Play()
				TS:Create(nameLbl, TweenInfo.new(0.15), { TextColor3 = C.txt }):Play()
				bar.Visible = true
				bar.Position = UDim2.new(0, -10, 0, 4)
				TS:Create(bar, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
					Position = UDim2.new(0, -6, 0, 4),
				}):Play()
			else
				TS:Create(btn, TweenInfo.new(0.15), {
					BackgroundColor3 = C.row,
					BackgroundTransparency = 0,
				}):Play()
				TS:Create(iconLbl, TweenInfo.new(0.15), { TextColor3 = C.sub }):Play()
				TS:Create(nameLbl, TweenInfo.new(0.15), { TextColor3 = C.sub }):Play()
				bar.Visible = false
				bar.Position = UDim2.new(0, -10, 0, 4)
			end
		end

		btn.MouseEnter:Connect(function()
			if not bar.Visible then
				TS:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = C.rowHover }):Play()
				TS:Create(iconLbl, TweenInfo.new(0.15), { TextColor3 = C.acc }):Play()
				TS:Create(nameLbl, TweenInfo.new(0.15), { TextColor3 = C.txt }):Play()
			end
		end)
		btn.MouseLeave:Connect(function()
			if not bar.Visible then
				TS:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = C.row }):Play()
				TS:Create(iconLbl, TweenInfo.new(0.15), { TextColor3 = C.sub }):Play()
				TS:Create(nameLbl, TweenInfo.new(0.15), { TextColor3 = C.sub }):Play()
			end
		end)

		tabBtns[name] = { btn = btn, line = bar, setActive = setActive }

		local pg
		if fixedLayout then
			pg = mk("Frame", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Visible = false,
			}, content)
			pad(pg, 4, 8, 4, 8)
		else
			pg = mk("ScrollingFrame", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Visible = false,
				ScrollBarThickness = 4,
				ScrollBarImageTransparency = 0.5,
				CanvasSize = UDim2.new(),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ScrollBarImageColor3 = C.acc,
				BorderSizePixel = 0,
			}, content)
			pad(pg, 4, 10, 4, 10)
			mk("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, pg)
		end
		pages[name] = pg

		local headerFrame = mk("Frame", {
			Size = UDim2.new(1, 0, 0, 40),
			BackgroundTransparency = 1,
			LayoutOrder = 0,
		}, pg)
		local tTitle = mk("TextLabel", {
			Size = UDim2.new(1, 0, 0, 28),
			BackgroundTransparency = 1,
			Text = (icon or "✦") .. "  " .. (titleText or name),
			Font = F.title,
			TextSize = 22,
			TextColor3 = C.txt,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, headerFrame)
		local underline = mk("Frame", {
			Size = UDim2.new(0, 60, 0, 3),
			Position = UDim2.new(0, 0, 1, -4),
			BackgroundColor3 = C.acc,
			BorderSizePixel = 0,
		}, headerFrame)
		corner(underline, 2)
		grad(underline, 0, C.acc, C.acc2)

		btn.MouseButton1Click:Connect(function()
			for n, p in pairs(pages) do p.Visible = (n == name) end
			for n, b in pairs(tabBtns) do
				if b.setActive then b.setActive(n == name) end
			end
		end)

		return pg
	end

	----------------------------------------------------------------- Setting Controls (WAJIB KONSISTEN)
	local function makeToggle(parent, optOrTitle, desc, getv, setv, order)
		local opt
		if type(optOrTitle) == "table" then
			opt = optOrTitle
		else
			opt = {
				label = optOrTitle,
				desc = desc,
				value = (type(getv) == "function" and getv()) or false,
				onChange = setv,
				order = order,
			}
		end

		local label = opt.label or "Toggle"
		local descText = opt.desc or ""
		local curVal = opt.value and true or false
		local onChange = opt.onChange

		local row = mk("Frame", {
			Size = UDim2.new(1, 0, 0, 52),
			BackgroundColor3 = C.row,
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			LayoutOrder = opt.order or 0,
		}, parent)
		corner(row, 10)
		pad(row, 12, 12, 6, 6)

		local txts = mk("Frame", {
			Size = UDim2.new(1, -56, 1, 0),
			BackgroundTransparency = 1,
		}, row)

		local lbl = mk("TextLabel", {
			Size = UDim2.new(1, 0, 0, 20),
			Position = UDim2.fromOffset(0, descText ~= "" and 0 or 10),
			BackgroundTransparency = 1,
			Text = label,
			Font = F.bold,
			TextSize = 13,
			TextColor3 = C.txt,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, txts)

		if descText ~= "" then
			local dLbl = mk("TextLabel", {
				Size = UDim2.new(1, 0, 0, 16),
				Position = UDim2.fromOffset(0, 20),
				BackgroundTransparency = 1,
				Text = descText,
				Font = F.reg,
				TextSize = 11,
				TextColor3 = C.sub,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}, txts)
		end

		local switch = mk("TextButton", {
			Size = UDim2.fromOffset(40, 22),
			Position = UDim2.new(1, -40, 0.5, -11),
			BackgroundColor3 = curVal and C.acc or C.row,
			Text = "",
			AutoButtonColor = false,
		}, row)
		corner(switch, 999)
		local swStroke = stroke(switch, curVal and C.acc or C.strokeSub, 1, 0.4)

		local knob = mk("Frame", {
			Size = UDim2.fromOffset(18, 18),
			Position = curVal and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
		}, switch)
		corner(knob, 999)

		local function updateVisual(v, anim)
			local targetBg = v and C.acc or C.row
			local targetStroke = v and C.acc or C.strokeSub
			local targetPos = v and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
			if anim then
				TS:Create(switch, TweenInfo.new(0.15), { BackgroundColor3 = targetBg }):Play()
				TS:Create(swStroke, TweenInfo.new(0.15), { Color = targetStroke }):Play()
				TS:Create(knob, TweenInfo.new(0.15), { Position = targetPos }):Play()
			else
				switch.BackgroundColor3 = targetBg
				swStroke.Color = targetStroke
				knob.Position = targetPos
			end
		end

		local function setVal(v, skipCallback)
			curVal = v and true or false
			updateVisual(curVal, true)
			if not skipCallback then
				ctx.log(label .. ": " .. (curVal and "ON" or "OFF"))
				if onChange then onChange(curVal) end
			end
		end

		switch.MouseButton1Click:Connect(function()
			setVal(not curVal)
		end)

		local comp = {
			Frame = row,
			Set = function(self, v) setVal(v, false) end,
			Get = function(self) return curVal end,
			refresh = function() if type(getv) == "function" then setVal(getv(), true) end end,
		}
		return comp
	end

	local function makeSlider(parent, optOrTitle, minVal, maxVal, curVal, suffixStr, onChangeCb, orderNum)
		local opt
		if type(optOrTitle) == "table" then
			opt = optOrTitle
		else
			opt = {
				label = optOrTitle,
				min = minVal or 0,
				max = maxVal or 100,
				value = curVal or minVal or 0,
				suffix = suffixStr or "",
				onChange = onChangeCb,
				order = orderNum,
			}
		end

		local label = opt.label or "Slider"
		local min = opt.min or 0
		local max = opt.max or 100
		local cur = math.clamp(opt.value or min, min, max)
		local suffix = opt.suffix or ""
		local onChange = opt.onChange

		local row = mk("Frame", {
			Size = UDim2.new(1, 0, 0, 56),
			BackgroundColor3 = C.row,
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			LayoutOrder = opt.order or 0,
		}, parent)
		corner(row, 10)
		pad(row, 12, 12, 8, 8)

		local topRow = mk("Frame", {
			Size = UDim2.new(1, 0, 0, 20),
			Position = UDim2.fromOffset(0, 0),
			BackgroundTransparency = 1,
		}, row)

		local lbl = mk("TextLabel", {
			Size = UDim2.new(1, -80, 1, 0),
			BackgroundTransparency = 1,
			Text = label,
			Font = F.bold,
			TextSize = 13,
			TextColor3 = C.txt,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, topRow)

		local valLbl = mk("TextLabel", {
			Size = UDim2.fromOffset(80, 20),
			Position = UDim2.new(1, -80, 0, 0),
			BackgroundTransparency = 1,
			Text = tostring(cur) .. suffix,
			Font = F.bold,
			TextSize = 13,
			TextColor3 = C.acc,
			TextXAlignment = Enum.TextXAlignment.Right,
		}, topRow)

		local track = mk("TextButton", {
			Size = UDim2.new(1, 0, 0, 4),
			Position = UDim2.new(0, 0, 1, -10),
			BackgroundColor3 = C.row,
			Text = "",
			AutoButtonColor = false,
		}, row)
		corner(track, 2)

		local fill = mk("Frame", {
			Size = UDim2.new((cur - min) / math.max(1, (max - min)), 0, 1, 0),
			BackgroundColor3 = C.acc,
			BorderSizePixel = 0,
		}, track)
		corner(fill, 2)
		grad(fill, 0, C.acc, C.acc2)

		local knob = mk("Frame", {
			Size = UDim2.fromOffset(14, 14),
			Position = UDim2.new(1, -7, 0.5, -7),
			BackgroundColor3 = C.acc,
			BorderSizePixel = 0,
			ZIndex = 5,
		}, fill)
		corner(knob, 999)
		stroke(knob, Color3.new(1, 1, 1), 1.5, 0)

		local function updateFromPct(pct, skipCallback)
			pct = math.clamp(pct, 0, 1)
			local step = opt.step or 1
			local raw = min + pct * (max - min)
			local rounded = math.round(raw / step) * step
			cur = math.clamp(rounded, min, max)
			fill.Size = UDim2.new((cur - min) / math.max(1, (max - min)), 0, 1, 0)
			valLbl.Text = tostring(cur) .. suffix
			if not skipCallback then
				ctx.log(label .. ": " .. tostring(cur))
				if onChange then onChange(cur) end
			end
		end

		local dragging = false
		local function onInput(i)
			local absPos = track.AbsolutePosition.X
			local absSize = track.AbsoluteSize.X
			if absSize > 0 then
				local pct = (i.Position.X - absPos) / absSize
				updateFromPct(pct, false)
			end
		end

		track.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				dragging = true; onInput(i)
			end
		end)
		UserInputService.InputChanged:Connect(function(i)
			if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
				onInput(i)
			end
		end)
		UserInputService.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)

		return {
			Frame = row,
			Set = function(self, v)
				local pct = (v - min) / math.max(1, (max - min))
				updateFromPct(pct, true)
			end,
			Get = function(self) return cur end,
		}
	end

	local function makeDropdown(parent, optOrTitle, desc, options, getList, setList, order, customOpts)
		if type(optOrTitle) ~= "table" and type(getList) == "function" then
			-- Delegasi ke standard dropdown multi/search bila ada di ctx
			if ctx.makeDropdown and ctx.makeDropdown ~= makeDropdown then
				return ctx.makeDropdown(parent, optOrTitle, desc, options, getList, setList, order, customOpts)
			end
		end

		local opt = (type(optOrTitle) == "table") and optOrTitle or {
			label = optOrTitle,
			options = options or {},
			value = (type(getList) == "function" and getList()) or "",
			onChange = setList,
			order = order,
		}

		local label = opt.label or "Dropdown"
		local opts = opt.options or {}
		local curVal = opt.value or (opts[1] or "")
		local onChange = opt.onChange

		local row = mk("Frame", {
			Size = UDim2.new(1, 0, 0, 44),
			BackgroundColor3 = C.row,
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			ZIndex = 15,
			LayoutOrder = opt.order or 0,
		}, parent)
		corner(row, 10)
		pad(row, 12, 12, 4, 4)

		local lbl = mk("TextLabel", {
			Size = UDim2.new(0.5, 0, 1, 0),
			BackgroundTransparency = 1,
			Text = label,
			Font = F.bold,
			TextSize = 13,
			TextColor3 = C.txt,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 16,
		}, row)

		local btn = mk("TextButton", {
			Size = UDim2.new(0.48, 0, 1, -6),
			Position = UDim2.new(0.52, 0, 0, 3),
			BackgroundColor3 = C.panel,
			Text = tostring(curVal) .. "  ▾",
			Font = F.bold,
			TextSize = 12,
			TextColor3 = C.accSoft,
			AutoButtonColor = false,
			ZIndex = 16,
		}, row)
		corner(btn, 8)
		stroke(btn, C.strokeSub, 1, 0.4)

		local listFrame = mk("ScrollingFrame", {
			Size = UDim2.new(0.48, 0, 0, 120),
			Position = UDim2.new(0.52, 0, 1, 4),
			BackgroundColor3 = C.panel,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = C.acc,
			Visible = false,
			ZIndex = 30,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
		}, row)
		corner(listFrame, 8)
		stroke(listFrame, C.acc, 1.2, 0.3)
		pad(listFrame, 4, 4, 4, 4)
		mk("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, listFrame)

		local function rebuildList()
			for _, c in ipairs(listFrame:GetChildren()) do
				if c:IsA("TextButton") then c:Destroy() end
			end
			for _, item in ipairs(opts) do
				local itm = mk("TextButton", {
					Size = UDim2.new(1, 0, 0, 26),
					BackgroundColor3 = (item == curVal) and C.acc or C.row,
					BackgroundTransparency = (item == curVal) and 0.8 or 1,
					Text = "  " .. tostring(item),
					Font = F.bold,
					TextSize = 12,
					TextColor3 = (item == curVal) and C.acc or C.txt,
					TextXAlignment = Enum.TextXAlignment.Left,
					AutoButtonColor = false,
					ZIndex = 31,
				}, listFrame)
				corner(itm, 6)

				itm.MouseEnter:Connect(function()
					TS:Create(itm, TweenInfo.new(0.15), { BackgroundColor3 = C.rowHover, BackgroundTransparency = 0.5 }):Play()
				end)
				itm.MouseLeave:Connect(function()
					TS:Create(itm, TweenInfo.new(0.15), {
						BackgroundColor3 = (item == curVal) and C.acc or C.row,
						BackgroundTransparency = (item == curVal) and 0.8 or 1,
					}):Play()
				end)

				itm.MouseButton1Click:Connect(function()
					curVal = item
					btn.Text = tostring(curVal) .. "  ▾"
					listFrame.Visible = false
					ctx.log(label .. ": " .. tostring(curVal))
					if onChange then onChange(curVal) end
					rebuildList()
				end)
			end
		end
		rebuildList()

		btn.MouseButton1Click:Connect(function()
			listFrame.Visible = not listFrame.Visible
		end)

		return {
			Frame = row,
			Set = function(self, v)
				curVal = v
				btn.Text = tostring(curVal) .. "  ▾"
				rebuildList()
			end,
			Get = function(self) return curVal end,
		}
	end

	local function makeButton(parent, optOrLabel, styleOrColor, onClickCb, orderNum)
		local opt
		if type(optOrLabel) == "table" then
			opt = optOrLabel
		else
			opt = {
				label = optOrLabel,
				style = (type(styleOrColor) == "string") and styleOrColor or "primary",
				color = (typeof(styleOrColor) == "Color3") and styleOrColor or nil,
				onClick = onClickCb,
				order = orderNum,
			}
		end

		local label = opt.label or "Button"
		local style = opt.style or "primary"
		local onClick = opt.onClick

		local bgCol = opt.color or (style == "danger" and C.red or (style == "ghost" and C.row or C.acc))
		local txtCol = (style == "ghost") and C.txt or Color3.new(1, 1, 1)

		local btn = mk("TextButton", {
			Size = UDim2.new(1, 0, 0, 40),
			BackgroundColor3 = bgCol,
			Text = label,
			Font = F.bold,
			TextSize = 13,
			TextColor3 = txtCol,
			AutoButtonColor = false,
			LayoutOrder = opt.order or 0,
		}, parent)
		corner(btn, 10)
		if style == "primary" then
			grad(btn, 0, C.acc, C.acc2)
			stroke(btn, C.accSoft, 1, 0.3)
		else
			stroke(btn, bgCol, 1, 0.3)
		end

		btn.MouseEnter:Connect(function()
			TS:Create(btn, TweenInfo.new(0.15), {
				BackgroundColor3 = (style == "danger" and Color3.fromRGB(240, 80, 90) or (style == "ghost" and C.rowHover or C.accSoft)),
			}):Play()
		end)
		btn.MouseLeave:Connect(function()
			TS:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = bgCol }):Play()
		end)

		btn.MouseButton1Click:Connect(function()
			if onClick then
				local res = onClick()
				if type(res) == "string" and res ~= "" then
					ctx.log(res)
					ctx.notify(res)
				end
			end
		end)

		return btn
	end

	local function makeSection(parent, optOrTitle)
		local title = (type(optOrTitle) == "table") and optOrTitle.title or tostring(optOrTitle or "Section")

		local secFrame = mk("Frame", {
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
		}, parent)
		local lout = mk("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, secFrame)

		local hRow = mk("Frame", {
			Size = UDim2.new(1, 0, 0, 24),
			BackgroundTransparency = 1,
			LayoutOrder = 0,
		}, secFrame)

		local lbl = mk("TextLabel", {
			Size = UDim2.new(1, 0, 0, 18),
			BackgroundTransparency = 1,
			Text = title:upper(),
			Font = F.bold,
			TextSize = 11,
			TextColor3 = C.acc,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, hRow)

		local line = mk("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.new(0, 0, 1, -1),
			BackgroundColor3 = C.acc,
			BackgroundTransparency = 0.6,
			BorderSizePixel = 0,
		}, hRow)
		grad(line, 0, C.acc, C.acc2)

		return secFrame
	end

	----------------------------------------------------------------- Exports to ctx.ui and ctx
	ctx.ui.main            = main
	ctx.ui.maxIcon         = maxIcon
	ctx.ui.content         = content
	ctx.ui.tabButtonsFrame = tabButtonsFrame
	ctx.ui.sidebar         = sidebar
	ctx.ui.statusText      = statusText

	ctx.ui.makeToggle      = makeToggle
	ctx.ui.makeSlider      = makeSlider
	ctx.ui.makeDropdown    = makeDropdown
	ctx.ui.makeButton      = makeButton
	ctx.ui.makeSection     = makeSection
	ctx.ui.makePage        = makePage

	ctx.makePage           = makePage
	ctx.makeToggle         = makeToggle
	ctx.makeSlider         = makeSlider
	ctx.makeButton         = makeButton
	ctx.makeSection        = makeSection
end
