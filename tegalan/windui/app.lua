--[[ app.lua â€” init akhir garden: default tab Inventory + auto-resume automation. ]]
return function(ctx)
	local CFG = ctx.CFG
	local pages = ctx.ui.pages
	local tabBtns = ctx.ui.tabBtns
	local C = ctx.C

	-- toast "loaded" = notifikasi bawaan WindUI (custom ScreenGui lama dihapus:
	-- numpuk, jelek, emoji-nya rusak/âœ¦ mojibake)
	pcall(function()
		local initFps = math.clamp(math.round(workspace:GetRealPhysicsFPS() or 60), 1, 999)
		if ctx.wi and ctx.wi.notify then
			ctx.wi.notify("Dopamine | P².Achieve", "Garden loaded | " .. initFps .. " FPS", 4)
		end
	end)

	-- default tab = Inventory
	local function selectTab(name)
		for n, p in pairs(pages) do p.Visible = (n == name) end
		for n, b in pairs(tabBtns) do
			if b.setActive then
				b.setActive(n == name)
			else
				b.btn.BackgroundTransparency = (n == name) and 0.85 or 1
				b.btn.TextColor3 = (n == name) and C.txt or C.sub
				b.line.Visible = (n == name)
			end
		end
	end
	selectTab("Pet")

	ctx.log("CeszParadiseHub Garden dimuat.")
	ctx.setStatus("idle")

	-- Anti-AFK: reset timer idle Roblox (kick ~20 menit) tiap Idled fire, via VirtualUser.
	pcall(function()
		local VirtualUser = game:GetService("VirtualUser")
		ctx.LP.Idled:Connect(function()
			pcall(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new())
			end)
			ctx.log("Anti-AFK: reset idle timer.")
		end)
		ctx.log("Anti-AFK aktif.")
	end)

	------------------------------------------------------------------ Auto-Reconnect (on Disconnect)
	-- Kalau ke-kick / DC / error (dialog Roblox muncul) -> otomatis rejoin ke game yg sama,
	-- lalu hub di-load ulang di server baru (via queue_on_teleport). Ikut branch aktif.
	pcall(function()
		local GuiService = game:GetService("GuiService")
		local TeleportService = game:GetService("TeleportService")
		local branch = (getgenv and getgenv().GAG_BRANCH) or _G.GAG_BRANCH or "main"
		local RECON = ("if getgenv then getgenv().GAG_BRANCH=%q end;loadstring(game:HttpGet('https://raw.githubusercontent.com/milmscr/opoki/%s/tegalan/init.lua'))()"):format(branch, branch)
		local reconnecting = false
		local function reconnect()
			if reconnecting or CFG.autoReconnect == false then return end -- cek toggle real-time
			reconnecting = true
			ctx.log("Ke-DC/kick terdeteksi â€” auto reconnect...")
			local q = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport)
			if q then pcall(function() q(RECON) end) end
			task.wait(3)
			pcall(function() TeleportService:Teleport(game.PlaceId, ctx.LP) end)
			-- fallback: kalau teleport gagal (place instance), coba matchmaking biasa
			task.wait(8)
			pcall(function() TeleportService:Teleport(game.PlaceId, ctx.LP) end)
		end
		GuiService.ErrorMessageChanged:Connect(reconnect)
		ctx.log("Auto-Reconnect (anti-DC) aktif.")
	end)

	-- auto-resume ESP label kalau sebelumnya aktif
	if CFG.espEnabled and ctx.startEsp then
		ctx.startEsp()
		ctx.log("Auto-resume: ESP Label ON.")
	end
	if CFG.espEggEnabled and ctx.startEspEgg then
		ctx.startEspEgg()
		ctx.log("Auto-resume: ESP Egg ON.")
	end
	if CFG.espInvEnabled and ctx.startEspInv then
		ctx.startEspInv()
		ctx.log("Auto-resume: ESP Base Weight (Inventory) ON.")
	end
	if CFG.noclipEnabled and ctx.setNoclip then ctx.setNoclip(true); ctx.log("Auto-resume: Noclip ON.") end
	if CFG.walkSpeedEnabled and ctx.setWalkSpeed then ctx.setWalkSpeed(true); ctx.log("Auto-resume: Walk Speed ON.") end
	if CFG.infJumpEnabled and ctx.setInfJump then ctx.setInfJump(true); ctx.log("Auto-resume: Infinity Jump ON.") end
	if CFG.hideMyPlants and ctx.setHidePlants then ctx.setHidePlants("mine", true); ctx.log("Auto-resume: Hide My Plants ON.") end
	if CFG.hideOtherPlants and ctx.setHidePlants then ctx.setHidePlants("other", true); ctx.log("Auto-resume: Hide Other Plants ON.") end
	if CFG.autoRemoveWebFx and ctx.setAutoRemoveWeb then ctx.setAutoRemoveWeb(true); ctx.log("Auto-resume: Auto Remove Web FX ON.") end
	if CFG.perfMode and CFG.perfMode ~= "off" and ctx.setPerfMode then ctx.setPerfMode(CFG.perfMode); ctx.log("Auto-resume: Performance Mode = " .. tostring(CFG.perfMode)) end
	if CFG.disable3d and ctx.setDisable3d then ctx.setDisable3d(true); ctx.log("Auto-resume: Disable 3D ON.") end

	-- pre-warm harga Premium Shop di background (ditunda biar ga rebutan sama init).
	if ctx.premiumPrewarm then
		task.delay(6, function() if ctx.alive() then ctx.premiumPrewarm() end end)
	end

	-- auto-resume Auto Reclaimer kalau sebelumnya aktif
	if CFG.reclaimEnabled and ctx.startReclaim then
		ctx.startReclaim()
		ctx.log("Auto-resume: Auto Reclaimer ON.")
	end

	-- auto-resume Auto Plants kalau sebelumnya aktif
	if CFG.plantSeedEnabled and ctx.startPlant then
		ctx.startPlant()
		ctx.log("Auto-resume: Auto Plants ON.")
	end

	-- auto-resume Auto Sprinkler + Shovel Sprinkler
	if CFG.sprinklerEnabled and ctx.startSprinkler then
		ctx.startSprinkler()
		ctx.log("Auto-resume: Auto Sprinkler ON.")
	end
	if CFG.shovelSprinklerEnabled and ctx.startShovelSprinkler then
		ctx.startShovelSprinkler()
		ctx.log("Auto-resume: Auto Shovel Sprinkler ON.")
	end

	-- auto-resume Auto Reconnect (biar loop rejoin lanjut tiap masuk server)
	if CFG.reconnectEnabled and ctx.startReconnect then
		ctx.startReconnect()
		ctx.log("Auto-resume: Auto Reconnect ON.")
	end

	-- auto-resume PNP kalau sebelumnya aktif (V1 polling / V2 event-driven, mutually exclusive)
	if CFG.pnpEnabled and ctx.startPnpV1 then
		task.wait(1)
		ctx.startPnpV1()
		ctx.log("Auto-resume: PNP V1 ON.")
	elseif CFG.pnpV2Enabled and ctx.startPnpV2 then
		task.wait(1)
		ctx.startPnpV2()
		ctx.log("Auto-resume: PNP V2 ON.")
	end

	-- auto-resume kalau sebelumnya aktif
	if CFG.tradeEnabled or CFG.tradeTicketEnabled then
		task.wait(1.5)
		ctx.state.completed = 0
		ctx.startTrade("ticket")
		if ctx.refreshTradeStatus then ctx.refreshTradeStatus() end
		ctx.log("Auto-resume: automation trade (ticket) ON.")
	elseif CFG.tradeGiftEnabled then
		task.wait(1.5)
		ctx.state.completed = 0
		ctx.startTrade("gift")
		if ctx.refreshGiftStatus then ctx.refreshGiftStatus() end
		ctx.log("Auto-resume: automation trade (gift) ON.")
	end

	-- auto-resume Leveling kalau sebelumnya aktif
	if CFG.levelingEnabled and ctx.startLeveling then
		task.wait(2.0)
		ctx.startLeveling()
		ctx.log("Auto-resume: Leveling ON.")
	end

	-- auto-resume Leveling V2 kalau sebelumnya aktif
	if CFG.levelingV2Enabled and ctx.startLevelingV2 then
		task.wait(2.0)
		ctx.startLevelingV2()
		ctx.log("Auto-resume: Leveling V2 ON.")
	end

	-- auto-resume Auto Hatch kalau sebelumnya aktif
	if CFG.hatchEnabled and ctx.startHatch then
		task.wait(2.0)
		ctx.startHatch()
		ctx.log("Auto-resume: Auto Hatch ON.")
	end

	-- auto-resume Egg Rejoin Watcher kalau sebelumnya aktif
	if (CFG.hatchRejoinMinusEnabled or CFG.hatchRejoinPlusEnabled) and ctx.startEggMinusWatcher then
		ctx.startEggMinusWatcher()
		ctx.log("Auto-resume: Egg Rejoin Watcher ON.")
	end

	-- auto-resume Auto Favourite Pets kalau sebelumnya aktif
	if CFG.autoFavorite and ctx.startAutoFavorite then
		ctx.startAutoFavorite()
		ctx.log("Auto-resume: Auto Favourite ON.")
	end

	-- auto-resume Growth kalau sebelumnya aktif
	if CFG.growthEnabled and ctx.startGrowth then
		task.wait(2.0)
		ctx.startGrowth()
		ctx.log("Auto-resume: Growth ON.")
	end

	-- auto-resume Mutation kalau sebelumnya aktif
	if CFG.mutationEnabled and ctx.startMutation then
		task.wait(2.5)
		ctx.startMutation()
		ctx.log("Auto-resume: Mutation ON.")
	end

	-- auto-resume Elephant kalau sebelumnya aktif
	if CFG.elephantEnabled and ctx.startElephant then
		task.wait(2.5)
		ctx.startElephant()
		ctx.log("Auto-resume: Elephant ON.")
	end

	if CFG.elephantV2Enabled and ctx.startElephantV2 then
		task.wait(2.5)
		ctx.startElephantV2()
		ctx.log("Auto-resume: Elephant V2 ON.")
	end

	-- auto-resume Boost Pet kalau sebelumnya aktif
	if CFG.boostEnabled and ctx.startBoostPet then
		task.wait(2.5)
		ctx.startBoostPet()
		ctx.log("Auto-resume: Boost Pet ON.")
	end

	-- auto-resume Cleanse kalau sebelumnya aktif
	if CFG.cleanseEnabled and ctx.startCleanse then
		task.wait(2.5)
		ctx.startCleanse()
		ctx.log("Auto-resume: Cleanse ON.")
	end

	-- auto-resume Beanstalk Event kalau sebelumnya aktif
	if ctx.beanstalkAnyOn and ctx.beanstalkAnyOn() and ctx.startBeanstalk then
		task.wait(2.5)
		ctx.startBeanstalk()
		ctx.log("Auto-resume: Beanstalk Event ON.")
	end

	-- auto-resume Shop (buy seed/egg/gear)
	if CFG.buySeedEnabled and ctx.startBuySeed then ctx.startBuySeed(); ctx.log("Auto-resume: Buy Seed ON.") end
	if CFG.buyEggEnabled and ctx.startBuyEgg then ctx.startBuyEgg(); ctx.log("Auto-resume: Buy Egg ON.") end
	if CFG.buyGearEnabled and ctx.startBuyGear then ctx.startBuyGear(); ctx.log("Auto-resume: Buy Gear ON.") end
	if ctx.merchantAnyOn and ctx.merchantAnyOn() and ctx.startBuyMerchant then ctx.startBuyMerchant(); ctx.log("Auto-resume: Buy Merchant ON.") end
	if CFG.merchantAutoOpenUI and ctx.startAutoOpenUI then ctx.startAutoOpenUI(); ctx.log("Auto-resume: Merchant Auto Open UI ON.") end
	if CFG.waterEnabled and ctx.startWater then ctx.startWater(); ctx.log("Auto-resume: Auto Water ON.") end
	if CFG.shovelTreeEnabled and ctx.startShovelTree then ctx.startShovelTree(); ctx.log("Auto-resume: Auto Shovel Tree ON.") end
	if CFG.shovelFruitEnabled and ctx.startShovelFruit then ctx.startShovelFruit(); ctx.log("Auto-resume: Auto Shovel Fruit ON.") end
	if (CFG.collectWlFruitEnabled or CFG.collectWlMutEnabled or CFG.collectCombEnabled) and ctx.startCollect then
		ctx.startCollect(); ctx.log("Auto-resume: Auto Collect ON.")
	end
	if (CFG.favEnabled or CFG.unfavEnabled) and ctx.startFavorite then
		ctx.startFavorite(); ctx.log("Auto-resume: Auto Favorite ON.")
	end
	if CFG.beanstalkClaimEnabled and ctx.startBeanstalkClaim then ctx.startBeanstalkClaim(); ctx.log("Auto-resume: Beanstalk Claim Reward ON.") end
	if CFG.beanstalkHopEnabled and ctx.startBeanstalkHop then task.wait(3); ctx.startBeanstalkHop(); ctx.log("Auto-resume: Beanstalk Auto Hop ON.") end
	if CFG.buyBeanstalkShopEnabled and ctx.startBuyBeanstalkShop then ctx.startBuyBeanstalkShop(); ctx.log("Auto-resume: Buy Beanstalk Shop ON.") end
end
