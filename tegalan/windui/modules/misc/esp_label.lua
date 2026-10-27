--[[ esp_label.lua — ESP PET: label melayang (BillboardGui) di dunia 3D di atas
     tiap pet fisik (nama + berat + level + mutasi).
     ESP EGG SUDAH TERPISAH: modules/misc/esp_egg.lua (style NEBULA, toggle
     CFG.espEggEnabled sendiri — biar gak nyampur).
     Toggle: CFG.espEnabled. ]]
return function(ctx)
	local LP = ctx.LP
	local DataService = ctx.deps.DataService

	-- Game nampilin berat = BaseWeight * 1.1 (bukan raw BaseWeight).
	local WEIGHT_MULT = 1.1

	local bbFolder
	local billboards = {} -- key -> { gui, lbl }

	local function ensureFolder()
		if bbFolder and bbFolder.Parent then return bbFolder end
		bbFolder = Instance.new("Folder")
		bbFolder.Name = "AllegiaanESP"
		bbFolder.Parent = (gethui and gethui()) or game:GetService("CoreGui")
		return bbFolder
	end

	local function partOf(model)
		if model:IsA("BasePart") then return model end
		if model.PrimaryPart then return model.PrimaryPart end
		for _, d in ipairs(model:GetDescendants()) do if d:IsA("BasePart") then return d end end
		return nil
	end

	local function makeBB(key, adornee, offset)
		local bb = Instance.new("BillboardGui")
		bb.Name = "esp_" .. key
		bb.Adornee = adornee
		bb.Size = UDim2.fromOffset(260, 72)
		bb.StudsOffset = Vector3.new(0, offset or 2.8, 0)
		bb.AlwaysOnTop = true
		bb.MaxDistance = 600
		bb.LightInfluence = 0
		bb.ClipsDescendants = false
		bb.Parent = ensureFolder()

		-- Background card (translucent dark pink)
		local bg = Instance.new("Frame")
		bg.Size = UDim2.new(1, 0, 1, 0)
		bg.BackgroundColor3 = Color3.fromRGB(18, 6, 26)
		bg.BackgroundTransparency = 0.22
		bg.BorderSizePixel = 0
		bg.Parent = bb
		Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 10)
		local bgStroke = Instance.new("UIStroke", bg)
		bgStroke.Color = Color3.fromRGB(255, 55, 145)
		bgStroke.Thickness = 1.4
		bgStroke.Transparency = 0.3
		bgStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		-- Top accent glow strip
		local topBar = Instance.new("Frame")
		topBar.Size = UDim2.new(0.7, 0, 0, 2)
		topBar.Position = UDim2.new(0.15, 0, 0, 0)
		topBar.BackgroundColor3 = Color3.fromRGB(255, 135, 205)
		topBar.BackgroundTransparency = 0.1
		topBar.BorderSizePixel = 0
		topBar.ZIndex = 3
		topBar.Parent = bg
		Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 2)

		local lbl = Instance.new("TextLabel")
		lbl.BackgroundTransparency = 1
		lbl.Size = UDim2.new(1, -8, 1, 0)
		lbl.Position = UDim2.fromOffset(4, 0)
		lbl.Font = Enum.Font.FredokaOne
		lbl.TextSize = 15
		lbl.RichText = true
		lbl.TextColor3 = Color3.new(1, 1, 1)
		lbl.TextStrokeTransparency = 0.5
		lbl.TextStrokeColor3 = Color3.fromRGB(120, 0, 60)
		lbl.TextYAlignment = Enum.TextYAlignment.Center
		lbl.ZIndex = 4
		lbl.Parent = bg

		local rec = { gui = bb, lbl = lbl }
		billboards[key] = rec
		return rec
	end

	local function acquire(key, adornee, offset)
		local rec = billboards[key]
		if (not rec) or rec.gui.Adornee ~= adornee or not rec.gui.Parent then
			if rec then rec.gui:Destroy(); billboards[key] = nil end
			rec = makeBB(key, adornee, offset)
		end
		return rec
	end

	local function update()
		local seen = {}

		-- ===== PET (nama + berat + lv) — ESP egg di modul terpisah =====
		local okData, d = pcall(function() return DataService:GetData() end)
		local inv = okData and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}
		local pp = workspace:FindFirstChild("PetsPhysical")
		if pp then
			for _, mover in ipairs(pp:GetChildren()) do
				for _, petModel in ipairs(mover:GetChildren()) do
					if petModel:IsA("Model") then
						local uuid = petModel.Name
						local pData = inv[uuid]
						if pData then
							local adornee = partOf(petModel)
							if adornee then
								local key = "pet_" .. tostring(uuid)
								seen[key] = true
								local rec = acquire(key, adornee, 2.5)
								local pt = pData.PetType or "Pet"
								local pd = pData.PetData or {}
								local bw = tonumber(pd.BaseWeight)
								local lv = tonumber(pd.Level) or 0
								local mut = pd.MutationType

								local lines = { ("<font color='#FF5FA0'><b>🐾 %s</b></font>"):format(tostring(pt)) }
								if bw then
									lines[#lines + 1] = ("<font color='#FFD7F0'>%.2f KG</font> <font color='#FF87CD'>[Lv.%d]</font>"):format(bw * WEIGHT_MULT, lv)
								end
								if mut and mut ~= "" and mut ~= "Normal" and mut ~= "m" then
									lines[#lines + 1] = ("<font color='#6EF5B9'>✨ %s</font>"):format(tostring(mut))
								end
								rec.lbl.Text = table.concat(lines, "\n")
							end
						end
					end
				end
			end
		end

		for key, rec in pairs(billboards) do
			if not seen[key] then rec.gui:Destroy(); billboards[key] = nil end
		end
	end

	local function clearAll()
		for _, rec in pairs(billboards) do pcall(function() rec.gui:Destroy() end) end
		billboards = {}
		if bbFolder then pcall(function() bbFolder:Destroy() end); bbFolder = nil end
	end

	local loopId = 0
	function ctx.startEsp()
		loopId = loopId + 1
		local my = loopId
		task.spawn(function()
			while ctx.alive() and ctx.CFG.espEnabled and loopId == my do
				pcall(update)
				task.wait(0.5)
			end
			clearAll()
		end)
	end

	function ctx.stopEsp()
		loopId = loopId + 1
		clearAll()
	end
end
