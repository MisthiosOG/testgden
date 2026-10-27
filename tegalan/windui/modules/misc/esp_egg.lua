--[[ esp_egg.lua — NEBULA-style Egg ESP (milik Sam, dipotret 1:1).
     Label melayang di tiap egg MILIK SENDIRI (CollectionService tag
     "PetEggServer" + OWNER attr):
       - belum siap : <kuning>nama egg</> \n <oranye>m:ss</> \n <abu kecil>BW: xkg</>
       - siap       : <kuning>nama egg</> \n <putih>pet (est kg)</> \n <warna>[Size class]</>
     Size class: >=7 Titanic (merah) / >=6 Semi Titanic (oranye) / >=3 Huge (kuning)
     / sisanya Small (hijau). Isi egg (pet yg bakal menetas + BW) dari upvalue
     handler PetEggService.OnClientEvent + scan BaseWeight di DataService:GetData.
     Style: BillboardGui polos (tanpa kartu/emoji), GothamBold 17, RichText.
     Toggle: CFG.espEggEnabled — TERPISAH dari ESP pet (espEnabled). ]]
return function(ctx)
	local RS = game:GetService("ReplicatedStorage")
	local CS = game:GetService("CollectionService")
	local LP = ctx.LP
	local DataService = ctx.deps.DataService

	-- Game nampilin berat = BaseWeight * 1.10 (sama kayak NEBULA).
	local WEIGHT_MULT = 1.1

	-- eggPets[uuid] = nama pet yang bakal menetas (upvalue handler hatch).
	local eggPets = {}
	-- Cache BaseWeight per uuid (scan data game — NEBULA buildBW).
	local bwCache = {}

	local function updateEggPets()
		pcall(function()
			local remote = RS.GameEvents:FindFirstChild("PetEggService")
			if not remote then return end
			local con = getconnections(remote.OnClientEvent)[1]
			if not con or not con.Function then return end
			local hatchFunc = getupvalue(getupvalue(con.Function, 1), 2)
			eggPets = getupvalue(hatchFunc, 2) or {}
		end)
	end

	local function buildBW()
		pcall(function()
			local ok, d = pcall(function() return DataService:GetData() end)
			if not ok or not d then return end
			local function scan(t)
				for k, v in pairs(t) do
					if type(v) == "table" then
						if v.Data and v.Data.BaseWeight then
							bwCache[tostring(k)] = v.Data.BaseWeight
						else
							scan(v)
						end
					end
				end
			end
			scan(d)
		end)
	end

	local function getBW(uuid)
		if not bwCache[uuid] then buildBW() end
		return bwCache[uuid]
	end

	local function round(n, d)
		local m = 10 ^ (d or 2)
		return math.floor(n * m + 0.5) / m
	end

	local function formatTime(sec)
		sec = math.max(0, math.floor(sec or 0))
		return string.format("%d:%02d", math.floor(sec / 60), sec % 60)
	end

	local function getSizeInfo(kg)
		if kg >= 7 then return "Titanic", "#FF2A2A"
		elseif kg >= 6 then return "Semi Titanic", "#FF8C00"
		elseif kg >= 3 then return "Huge", "#FFD400"
		elseif kg >= 0 then return "Small", "#3CFF3C"
		end
		return "Unknown", "#FFFFFF"
	end

	-- makeESP: Billboard 220x90 nutup 3.5 stud, GothamBold 17, stroke solid,
	-- tanpa background/emoji — 1:1 dengan NEBULA. Text cuma di-update kalo beda.
	local function makeESP(obj, text)
		local part = obj:FindFirstChildWhichIsA("BasePart", true)
		if not part then return end

		local gui = obj:FindFirstChild("EggESP_UI")
		if not gui then
			gui = Instance.new("BillboardGui")
			gui.Name = "EggESP_UI"
			gui.Adornee = part
			gui.Size = UDim2.fromOffset(220, 90)
			gui.StudsOffset = Vector3.new(0, 3.5, 0)
			gui.AlwaysOnTop = true

			local lbl = Instance.new("TextLabel", gui)
			lbl.Name = "Text"
			lbl.Size = UDim2.fromScale(1, 1)
			lbl.BackgroundTransparency = 1
			lbl.RichText = true
			lbl.TextSize = 17
			lbl.Font = Enum.Font.GothamBold
			lbl.TextColor3 = Color3.new(1, 1, 1)
			lbl.TextStrokeTransparency = 0

			gui.Parent = obj
		end

		if gui.Text.Text ~= text then
			gui.Text.Text = text
		end
	end

	local function clearAll()
		for _, egg in ipairs(CS:GetTagged("PetEggServer")) do
			pcall(function()
				local g = egg:FindFirstChild("EggESP_UI")
				if g then g:Destroy() end
			end)
		end
	end

	local lastMeta = 0
	local function update()
		local now = os.clock()
		-- Refresh metadata egg/BW tiap 3s (murah, yang tiap-tick cuma teks).
		if now - lastMeta >= 3 then
			lastMeta = now
			updateEggPets()
			buildBW()
		end
		for _, egg in ipairs(CS:GetTagged("PetEggServer")) do
			if egg:GetAttribute("OWNER") ~= LP.Name then continue end
			if not (egg:GetAttribute("READY") or tonumber(egg:GetAttribute("TimeToHatch"))) then continue end

			local uuid = tostring(egg:GetAttribute("OBJECT_UUID"))
			local bw = getBW(uuid)
			if not bw then continue end

			local eggName = egg:GetAttribute("EggName") or egg.Name
			local petName = eggPets[uuid] or "Pet"
			local ready = egg:GetAttribute("READY")
			local timeLeft = egg:GetAttribute("TimeToHatch")

			local text
			if not ready then
				text = string.format(
					'<font color="#FFD400">%s</font>\n<font color="#FF5E00">%s</font>\n<font size="12" color="#BBBBBB">BW: %skg</font>',
					eggName,
					formatTime(timeLeft),
					tostring(bw)
				)
			else
				local est = round(bw * WEIGHT_MULT, 2)
				local size, color = getSizeInfo(est)
				text = string.format(
					'<font color="#FFD400">%s</font>\n<font color="#FFFFFF">%s (%skg)</font>\n<font color="%s">[%s]</font>',
					eggName,
					petName,
					tostring(est),
					color,
					size
				)
			end

			makeESP(egg, text)
		end
	end

	local loopId = 0
	function ctx.startEspEgg()
		loopId = loopId + 1
		local my = loopId
		task.spawn(function()
			updateEggPets()
			buildBW()
			while ctx.alive() and ctx.CFG.espEggEnabled and loopId == my do
				pcall(update)
				task.wait(0.5)
			end
			clearAll()
		end)
	end

	function ctx.stopEspEgg()
		loopId = loopId + 1
		clearAll()
	end
end
