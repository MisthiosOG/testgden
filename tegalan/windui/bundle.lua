-- AUTO-GENERATED oleh tools/bundle.js — JANGAN edit manual.
-- Edit modul-nya langsung, terus run `node tools/bundle.js`.
-- 44 modul, di-generate 2026-10-28T20:27:14.356Z
return {
	["app.lua"] = [=[
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

	-- auto-resume Auto GM Sprinkler (tab Hatch)
	if CFG.gmSprinklerEnabled and ctx.startGmSprinkler then
		ctx.startGmSprinkler()
		ctx.log("Auto-resume: Auto GM Sprinkler ON.")
	end

	-- auto-resume Auto Reconnect (biar loop rejoin lanjut tiap masuk server)
	if CFG.reconnectEnabled and ctx.startReconnect then
		ctx.startReconnect()
		ctx.log("Auto-resume: Auto Reconnect ON.")
	end

	-- auto-resume PNP V1 kalau sebelumnya aktif
	if CFG.pnpEnabled and ctx.startPnpV1 then
		task.wait(1)
		ctx.startPnpV1()
		ctx.log("Auto-resume: PNP V1 ON.")
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
	if (CFG.collectWlFruitEnabled or CFG.collectWlMutEnabled or CFG.collectCombEnabled or CFG.collectBlMutEnabled) and ctx.startCollect then
		ctx.startCollect(); ctx.log("Auto-resume: Auto Collect ON.")
	end
	if (CFG.favEnabled or CFG.unfavEnabled) and ctx.startFavorite then
		ctx.startFavorite(); ctx.log("Auto-resume: Auto Favorite ON.")
	end
	if CFG.beanstalkClaimEnabled and ctx.startBeanstalkClaim then ctx.startBeanstalkClaim(); ctx.log("Auto-resume: Beanstalk Claim Reward ON.") end
	if CFG.beanstalkHopEnabled and ctx.startBeanstalkHop then task.wait(3); ctx.startBeanstalkHop(); ctx.log("Auto-resume: Beanstalk Auto Hop ON.") end
	if CFG.buyBeanstalkShopEnabled and ctx.startBuyBeanstalkShop then ctx.startBuyBeanstalkShop(); ctx.log("Auto-resume: Buy Beanstalk Shop ON.") end
end
]=],
	["lib/windui-1.6.66.lua"] = [=[
--[[
     _      ___         ____  ______
    | | /| / (_)__  ___/ / / / /  _/
    | |/ |/ / / _ \/ _  / /_/ // /  
    |__/|__/_/_//_/\_,_/\____/___/
    
    v1.6.65  |  2026-07-01  |  Roblox UI Library for scripts
    
    To view the source code, see the `src/` folder on the official GitHub repository.
    
    Author: Footagesus (Footages, .ftgs, oftgs)
    Github: https://github.com/Footagesus/WindUI
    Discord: https://discord.gg/ftgs-development-hub-1300692552005189632
    License: MIT
]]

type ConfigType__DARKLUA_TYPE_a={
Object:Instance,
Camera:Instance?,
Interactive:boolean?,
Height:number?,
Focused:boolean,

Window:any,
WindUI:any,
Tab:any,
Parent:Instance,
}local a a={cache={}, load=function(b)if not a.cache[b]then a.cache[b]={c=a[b]()}end return a.cache[b].c end}do function a.a()

local b

local d={
New=nil,
Init=nil,
Shapes={
Circle={
Image="rbxassetid://111665032676235",
Rect=Rect.new(512,512,512,512),
Radius=512,
},
CircleOutline={
Image="rbxassetid://108556680453287",
Rect=Rect.new(512,512,512,512),
Radius=512,
},
CircleGlass={
Image="rbxassetid://95600044758841",
Rect=Rect.new(512,512,512,512),
Radius=512,
},



SquircleH={
Image="rbxassetid://125083578015333",
Rect=Rect.new(512,325,512,325),
Radius=325,
},
SquircleHOutline={
Image="rbxassetid://107043713170567",
Rect=Rect.new(512,325,512,325),
Radius=325,
},
SquircleHGlass={
Image="rbxassetid://84819521201001",
Rect=Rect.new(512,325,512,325),
Radius=325,
},
["SquircleH-TL-TR"]={
Image="rbxassetid://90680657206619",
Rect=Rect.new(807,512,807,512),
Radius=325,
AutoChange=false,
},
["SquircleH-BL-BR"]={
Image="rbxassetid://99216342056719",
Rect=Rect.new(0,512,0,512),
Radius=325,
AutoChange=false,
},

SquircleV={
Image="rbxassetid://124965260437653",
Rect=Rect.new(325,512,325,512),
Radius=325,
},
SquircleVOutline={
Image="rbxassetid://88808835404198",
Rect=Rect.new(325,512,325,512),
Radius=325,
},
SquircleVGlass={
Image="rbxassetid://124982801466667",
Rect=Rect.new(325,512,325,512),
Radius=325,
},

Squircle={
Image="rbxassetid://89641024074289",
Rect=Rect.new(460,460,460,460),
Radius=310,
},
SquircleOutline={
Image="rbxassetid://74029063732681",
Rect=Rect.new(512,512,512,512),
Radius=310,
},
SquircleGlass={
Image="rbxassetid://131126436897551",
Rect=Rect.new(512,512,512,512),
Radius=310,
},

["Squircle-TL-TR"]={
Image="rbxassetid://75712142040725",
Rect=Rect.new(512,512,512,512),
Radius=310,
AutoChange=false,
},
["Squircle-BL-BR"]={
Image="rbxassetid://83676684425544",
Rect=Rect.new(512,0,512,0),
Radius=310,
AutoChange=false,
},Square=
{
Image="rbxassetid://82909646051652",
Rect=Rect.new(512,512,512,512),
Radius=512,
AutoChange=false,
},
},
}

function d.Init(e,f)
b=f
return e.New
end

function d.New(e,f,g,h,i,j,l)
local m={
Radius=f or 0,
Type=g or"Circle",
GetRadius=nil,
GetType=nil,
SetRadius=nil,
SetType=nil,
}

local p={
["Glass-0.7"]="SquircleGlass",
["Glass-1"]="SquircleGlass",
["Glass-1.4"]="SquircleGlass",
["Squircle-Outline"]="SquircleOutline",
}

local function GetShape(r)
return d.Shapes[p[r]or r]or d.Shapes.Circle
end

local r=b.New(j and"ImageButton"or"ImageLabel",{
Image="",
ScaleType=l~=false and"Slice"or nil,
SliceCenter=m.Type~="Squircle"and Rect.new(512,512,512,512)or nil,
SliceScale=1,
ThemeTag=h and h.ThemeTag or nil,
BackgroundTransparency=1,
},i)

for u,v in next,h do
if not table.find({"ThemeTag"},u)then
r[u]=v
end
end

function m.SetRadius(u,v)
m.Radius=v
r.SliceScale=math.max(v/GetShape(m.Type).Radius,0.0001)
return m
end

function m.SetType(u,v)
m.Type=v
local x=GetShape(v)
r.Image=x.Image
r.SliceCenter=x.Rect
m:SetRadius(m.Radius)
return m
end

function m.GetRadius(u)
return m.Radius
end

function m.GetType(u)
return m.Type
end

m:SetRadius(f)
m:SetType(g)

b.AddSignal(r:GetPropertyChangedSignal"AbsoluteSize",function()
local u=GetShape(m.Type)
if u.AutoChange==false then
return
end

if string.find(m.Type,"Squircle")then
local v=string.find(m.Type,"Glass")and"Glass"or nil
local x=string.find(m.Type,"Outline")and"Outline"or nil

local z=math.round(r.AbsoluteSize.X/b.UIScale)
local A=math.round(r.AbsoluteSize.Y/b.UIScale)

local B=m.Radius~=0 and m.Radius or math.min(z,A)/2
local C=d.Shapes.Squircle.Radius/1024
local F=B/math.min(z,A)

local G

if z>A then
if F>=C then
G="SquircleH"..(x or v or"")
else
G="Squircle"..(x or v or"")
end
elseif z<A then
if F>=C then
G="SquircleV"..(x or v or"")
else
G="Squircle"..(x or v or"")
end
else
if F>=C then
G="Circle"..(x or v or"")
else
G="Squircle"..(x or v or"")
end
end

if G~=m:GetType()then
m:SetType(G)
end
end
end)

return r,m
end

return d end function a.b()

local b=(cloneref or clonereference or function(b)return b end)

local d=b(game:GetService"ReplicatedStorage":WaitForChild("GetIcons",99999):InvokeServer())

local function parseIconString(e)
if type(e)=="string"then
local f=e:find":"
if f then
local g=e:sub(1,f-1)
local h=e:sub(f+1)
return g,h
end
end
return nil,e
end

function d.AddIcons(e,f)
if type(e)~="string"or type(f)~="table"then
error"AddIcons: packName must be string, iconsData must be table"
return
end

if not d.Icons[e]then
d.Icons[e]={
Icons={},
Spritesheets={}
}
end

for g,h in pairs(f)do
if type(h)=="number"or(type(h)=="string"and h:match"^rbxassetid://")then
local i=h
if type(h)=="number"then
i="rbxassetid://"..tostring(h)
end

d.Icons[e].Icons[g]={
Image=i,
ImageRectSize=Vector2.new(0,0),
ImageRectPosition=Vector2.new(0,0),
Parts=nil
}
d.Icons[e].Spritesheets[i]=i

elseif type(h)=="table"then
if h.Image and h.ImageRectSize and h.ImageRectPosition then
local i=h.Image
if type(i)=="number"then
i="rbxassetid://"..tostring(i)
end

d.Icons[e].Icons[g]={
Image=i,
ImageRectSize=h.ImageRectSize,
ImageRectPosition=h.ImageRectPosition,
Parts=h.Parts
}

if not d.Icons[e].Spritesheets[i]then
d.Icons[e].Spritesheets[i]=i
end
else
warn("AddIcons: Invalid spritesheet data format for icon '"..g.."'")
end
else
warn("AddIcons: Unsupported data type for icon '"..g.."': "..type(h))
end
end
end

function d.SetIconsType(e)
d.IconsType=e
end

local e
function d.Init(f,g)
d.New=f
d.IconThemeTag=g

e=f
return d
end

function d.Icon(f,g,h)
h=h~=false
local i,j=parseIconString(f)

local l=i or g or d.IconsType
local m=j

local p=d.Icons[l]

if p and p.Icons and p.Icons[m]then
return{
p.Spritesheets[tostring(p.Icons[m].Image)],
p.Icons[m],
}
elseif p and p[m]and string.find(p[m],"rbxassetid://")then
return h and{
p[m],
{ImageRectSize=Vector2.new(0,0),ImageRectPosition=Vector2.new(0,0)}
}or p[m]
end
return nil
end

function d.GetIcon(f,g)
return d.Icon(f,g,false)
end


function d.Icon2(f,g,h)
return d.Icon(f,g,true)
end

function d.Image(f)
local g={
Icon=f.Icon or nil,
Type=f.Type,
Colors=f.Colors or{(d.IconThemeTag or Color3.new(1,1,1)),Color3.new(1,1,1)},
Transparency=f.Transparency or{0,0},
Size=f.Size or UDim2.new(0,24,0,24),

IconFrame=nil,
}

local h={}
local i={}

for j,l in next,g.Colors do
h[j]={
ThemeTag=typeof(l)=="string"and l,
Color=typeof(l)=="Color3"and l,
}
end

for j,l in next,g.Transparency do
i[j]={
ThemeTag=typeof(l)=="string"and l,
Value=typeof(l)=="number"and l,
}
end


local j=d.Icon2(g.Icon,g.Type)
local l=typeof(j)=="string"and string.find(j,'rbxassetid://')

if d.New then
local m=e or d.New



local p=m("ImageLabel",{
Size=g.Size,
BackgroundTransparency=1,
ImageColor3=h[1].Color or nil,
ImageTransparency=i[1].Value or nil,
ThemeTag=h[1].ThemeTag and{
ImageColor3=h[1].ThemeTag,
ImageTransparency=i[1].ThemeTag,
},
Image=l and j or j[1],
ImageRectSize=l and nil or j[2].ImageRectSize,
ImageRectOffset=l and nil or j[2].ImageRectPosition,
})


if not l and j[2].Parts then
for r,u in next,j[2].Parts do
local v=d.Icon(u,g.Type)

m("ImageLabel",{
Size=UDim2.new(1,0,1,0),
BackgroundTransparency=1,
ImageColor3=h[1+r].Color or nil,
ImageTransparency=i[1+r].Value or nil,
ThemeTag=h[1+r].ThemeTag and{
ImageColor3=h[1+r].ThemeTag,
ImageTransparency=i[1+r].ThemeTag,
},
Image=v[1],
ImageRectSize=v[2].ImageRectSize,
ImageRectOffset=v[2].ImageRectPosition,
Parent=p,
})
end
end

g.IconFrame=p
else
local m=Instance.new"ImageLabel"
m.Size=g.Size
m.BackgroundTransparency=1
m.ImageColor3=h[1].Color
m.ImageTransparency=i[1].Value or nil
m.Image=l and j or j[1]
m.ImageRectSize=l and nil or j[2].ImageRectSize
m.ImageRectOffset=l and nil or j[2].ImageRectPosition


if not l and j[2].Parts then
for p,r in next,j[2].Parts do
local u=d.Icon(r,g.Type)

local v=Instance.New"ImageLabel"
v.Size=UDim2.new(1,0,1,0)
v.BackgroundTransparency=1
v.ImageColor3=h[1+p].Color
v.ImageTransparency=i[1+p].Value or nil
v.Image=u[1]
v.ImageRectSize=u[2].ImageRectSize
v.ImageRectOffset=u[2].ImageRectPosition
v.Parent=m
end
end

g.IconFrame=m
end


return g
end

return d end function a.c()
return function(b)
return{


Primary="Icon",

White=Color3.new(1,1,1),
Black=Color3.new(0,0,0),

Dialog="Accent",

Background="Accent",
BackgroundTransparency=0,
Hover="Text",

PanelBackground="White",
PanelBackgroundTransparency=0.95,

WindowBackground="Background",

WindowShadow="Black",


WindowTopbarTitle="Text",
WindowTopbarAuthor="Text",
WindowTopbarIcon="Icon",
WindowTopbarButtonIcon="Icon",


WindowSearchBarBackground="Dialog",

TabBackground="Hover",
TabBackgroundHover="Hover",
TabBackgroundHoverTransparency=0.97,
TabBackgroundActive="Hover",
TabBackgroundActiveTransparency=0.93,
TabText="Text",
TabTextTransparency=0.3,
TabTextTransparencyActive=0,
TabTitle="Text",
TabIcon="Icon",
TabIconTransparency=0.4,
TabIconTransparencyActive=0.1,
TabBorderTransparency=1,
TabBorderTransparencyActive=0.75,
TabBorder="White",

ElementBackground="Text",
ElementBackgroundTransparency=0.93,
ElementBackgroundHover=b:AddColor("ElementBackground","#ffffff",0.1),
ElementTitle="Text",
ElementDesc="Text",
ElementIcon="Icon",

PopupBackground="Background",
PopupBackgroundTransparency="BackgroundTransparency",
PopupTitle="Text",
PopupContent="Text",
PopupIcon="Icon",

DialogBackground="Dialog",
DialogBackgroundTransparency="BackgroundTransparency",
DialogTitle="Text",
DialogContent="Text",
DialogIcon="Icon",

Toggle="Button",
ToggleBar="White",

Checkbox="Primary",
CheckboxIcon="White",
CheckboxBorder="White",
CheckboxBorderTransparency=0.75,

SliderIcon="Icon",

Slider="Primary",
SliderThumb="White",
SliderIconFrom="SliderIcon",
SliderIconTo="SliderIcon",

ProgressBar="Primary",
ProgressBarTrack="Text",
ProgressBarTrackTransparency=0.9,
ProgressBarText="Text",

Tooltip=Color3.fromHex"4C4C4C",
TooltipText="White",
TooltipSecondary="Primary",
TooltipSecondaryText="White",

TabSectionIcon="Icon",

SectionIcon="Icon",

SectionExpandIcon="Icon",
SectionExpandIconTransparency=0.4,
SectionBox="Text",
SectionBoxTransparency=0.95,
SectionBoxBorder="White",
SectionBoxBorderTransparency=0.75,
SectionBoxBackground="Text",
SectionBoxBackgroundTransparency=0.97,

SearchBarBorder="White",
SearchBarBorderTransparency=0.75,

Notification="Background",
Notification2="White",
Notification2Transparency=0.92,
NotificationTitle="Text",
NotificationTitleTransparency=0,
NotificationContent="Text",
NotificationContentTransparency=0.4,
NotificationDuration="White",
NotificationDurationTransparency=0.95,
NotificationBorder="White",
NotificationBorderTransparency=0.75,

DropdownTabBorder="White",
DropdownTabBackground="ElementBackground",
DropdownBackground="Background",

LabelBackground="White",
LabelBackgroundTransparency=0.95,

ViewportBackground="ElementBackground",
ViewportBackgroundTransparency="ElementBackgroundTransparency",
}
end end function a.d()

local b=(cloneref or clonereference or function(b)
return b
end)

local d=b(game:GetService"RunService")
local e=b(game:GetService"UserInputService")
local f=b(game:GetService"TweenService")
local g=b(game:GetService"LocalizationService")
local h=b(game:GetService"HttpService")

local i=a.load'a'local j=

d.Heartbeat

local l="https://raw.githubusercontent.com/Footagesus/Icons/main/Main-v2.lua"

local m
if d:IsStudio()or not writefile then
m=a.load'b'
else
m=loadstring(
game.HttpGet and game:HttpGet(l)or h:GetAsync(l)
)()
end

m.SetIconsType"lucide"

local p

local r
r={
Font="rbxassetid://12187365364",
Localization=nil,
CanDraggable=true,
Theme=nil,
Themes=nil,
Icons=m,
Signals={},
Objects={},
LocalizationObjects={},
UIScale=1,
FontObjects={},
Language=string.match(g.SystemLocaleId,"^[a-z]+"),
Request=http_request or(syn and syn.request)or request,
DefaultProperties={
ScreenGui={
ResetOnSpawn=false,
ZIndexBehavior="Sibling",
},
CanvasGroup={
BorderSizePixel=0,
BackgroundColor3=Color3.new(1,1,1),
},
Frame={
BorderSizePixel=0,
BackgroundColor3=Color3.new(1,1,1),
},
TextLabel={
BackgroundColor3=Color3.new(1,1,1),
BorderSizePixel=0,
Text="",
RichText=true,
TextColor3=Color3.new(1,1,1),
TextSize=14,
},
TextButton={
BackgroundColor3=Color3.new(1,1,1),
BorderSizePixel=0,
Text="",
AutoButtonColor=false,
TextColor3=Color3.new(1,1,1),
TextSize=14,
},
TextBox={
BackgroundColor3=Color3.new(1,1,1),
BorderColor3=Color3.new(0,0,0),
ClearTextOnFocus=false,
Text="",
TextColor3=Color3.new(0,0,0),
TextSize=14,
},
ImageLabel={
BackgroundTransparency=1,
BackgroundColor3=Color3.new(1,1,1),
BorderSizePixel=0,
},
ImageButton={
BackgroundColor3=Color3.new(1,1,1),
BorderSizePixel=0,
AutoButtonColor=false,
},
UIListLayout={
SortOrder="LayoutOrder",
},
ScrollingFrame={
ScrollBarImageTransparency=1,
BorderSizePixel=0,
},
VideoFrame={
BorderSizePixel=0,
},
},
Colors={
Red="#e53935",
Orange="#f57c00",
Green="#43a047",
Blue="#039be5",
White="#ffffff",
Grey="#484848",
},
ThemeFallbacks=nil,





















ThemeChangeCallbacks={},
}

function r.Init(u)
p=u

r.ThemeFallbacks=a.load'c'(r)

r.UIScale=u.UIScale

i:Init(r)
end

function r.AddSignal(u,v)
local x=u:Connect(v)
table.insert(r.Signals,x)
return x
end

function r.DisconnectAll()
for u,v in next,r.Signals do
local x=table.remove(r.Signals,u)
x:Disconnect()
end
end

function r.SafeCallback(u,...)
if not u then
return
end

local v,x=pcall(u,...)
if not v then
if p and p.Window and p.Window.Debug then local
z, A=x:find":%d+: "

warn("[ WindUI: DEBUG Mode ] "..x)

return p:Notify{
Title="DEBUG Mode: Error",
Content=not A and x or x:sub(A+1),
Duration=8,
}
end
end
end

function r.Gradient(u,v)
if p and p.Gradient then
return p:Gradient(u,v)
end

local x={}
local z={}

for A,B in next,u do
local C=tonumber(A)
if C then
C=math.clamp(C/100,0,1)
table.insert(x,ColorSequenceKeypoint.new(C,B.Color))
table.insert(z,NumberSequenceKeypoint.new(C,B.Transparency or 0))
end
end

table.sort(x,function(A,B)
return A.Time<B.Time
end)
table.sort(z,function(A,B)
return A.Time<B.Time
end)

if#x<2 then
error"ColorSequence requires at least 2 keypoints"
end

local A={
Color=ColorSequence.new(x),
Transparency=NumberSequence.new(z),
}

if v then
for B,C in pairs(v)do
A[B]=C
end
end

return A
end

function r.SetTheme(u)
local v=r.Theme
r.Theme=u
r.UpdateTheme(nil,false)

for x,z in next,r.ThemeChangeCallbacks do
r.SafeCallback(z,u,v)
end
end

function r.AddFontObject(u)
table.insert(r.FontObjects,u)
r.UpdateFont(r.Font)
end

function r.UpdateFont(u)
r.Font=u
for v,x in next,r.FontObjects do
x.FontFace=Font.new(u,x.FontFace.Weight,x.FontFace.Style)
end
end

function r.GetThemeProperty(u,v)
local function getValue(x,z)
local A=z[x]

if A==nil then
return nil
end

if typeof(A)=="string"and string.sub(A,1,1)=="#"then
return Color3.fromHex(A)
end

if typeof(A)=="Color3"then
return A
end

if typeof(A)=="number"then
return A
end

if typeof(A)=="table"and A.Color and A.Transparency then
return A
end

if typeof(A)=="function"then
return A(z)
end

return A
end

local x=getValue(u,v)
if x~=nil then
if typeof(x)=="string"and string.sub(x,1,1)~="#"then
local z=r.GetThemeProperty(x,v)
if z~=nil then
return z
end
else
return x
end
end

local z=r.ThemeFallbacks[u]
if z~=nil then
if typeof(z)=="string"and string.sub(z,1,1)~="#"then
return r.GetThemeProperty(z,v)
else
return getValue(u,{[u]=z})
end
end

x=getValue(u,r.Themes.Dark)
if x~=nil then
if typeof(x)=="string"and string.sub(x,1,1)~="#"then
local A=r.GetThemeProperty(x,r.Themes.Dark)
if A~=nil then
return A
end
else
return x
end
end

if z~=nil then
if typeof(z)=="string"and string.sub(z,1,1)~="#"then
return r.GetThemeProperty(z,r.Themes.Dark)
else
return getValue(u,{[u]=z})
end
end

return nil
end

function r.AddThemeObject(u,v,x)
if r.Objects[u]then
for z,A in pairs(v)do
r.Objects[u].Properties[z]=A
end
else
r.Objects[u]={Object=u,Properties=v}
end

if not x then
r.UpdateTheme(u,false)
end
return u
end

function r.AddLangObject(u)
local v=r.LocalizationObjects[u]
if not v then
return
end

local x=v.Object

r.SetLangForObject(u)

return x
end

function r.UpdateTheme(u,v,x,z,A,B)
local function ApplyTheme(C)
for F,G in pairs(C.Properties or{})do
local H=r.GetThemeProperty(G,r.Theme)
if H~=nil then
if typeof(H)=="Color3"then
local J=C.Object:FindFirstChild"LibraryGradient"
if J then
J:Destroy()
end

if x then
r.Tween(
C.Object,
z or 0.2,
{[F]=H},
A or Enum.EasingStyle.Quint,
B or Enum.EasingDirection.Out
):Play()
elseif v then
r.Tween(C.Object,0.08,{[F]=H}):Play()
else
C.Object[F]=H
end
elseif typeof(H)=="table"and H.Color and H.Transparency then
C.Object[F]=Color3.new(1,1,1)

local J=C.Object:FindFirstChild"LibraryGradient"
if not J then
J=Instance.new"UIGradient"
J.Name="LibraryGradient"
J.Parent=C.Object
end

J.Color=H.Color
J.Transparency=H.Transparency

for L,M in pairs(H)do
if L~="Color"and L~="Transparency"and J[L]~=nil then
J[L]=M
end
end
elseif typeof(H)=="number"then
if x then
r.Tween(
C.Object,
z or 0.2,
{[F]=H},
A or Enum.EasingStyle.Quint,
B or Enum.EasingDirection.Out
):Play()
elseif v then
r.Tween(C.Object,0.08,{[F]=H}):Play()
else
C.Object[F]=H
end
end
else
local J=C.Object:FindFirstChild"LibraryGradient"
if J then
J:Destroy()
end
end
end
end

if u then
local C=r.Objects[u]
if C then
ApplyTheme(C)
end
else
for C,F in pairs(r.Objects)do
ApplyTheme(F)
end
end
end

function r.SetThemeTag(u,v,x,z,A)
r.AddThemeObject(u,v)
r.UpdateTheme(u,false,true,x,z,A)
end

function r.SetLangForObject(u)
if r.Localization and r.Localization.Enabled then
local v=r.LocalizationObjects[u]
if not v then
return
end

local x=v.Object
local z=v.TranslationId

local A=r.Localization.Translations[r.Language]
if A and A[z]then
x.Text=A[z]
else
local B=r.Localization
and r.Localization.Translations
and r.Localization.Translations.en
or nil
if B and B[z]then
x.Text=B[z]
else
x.Text="["..z.."]"
end
end
end
end

function r.ChangeTranslationKey(u,v,x)
if r.Localization and r.Localization.Enabled then
local z=string.match(x,"^"..r.Localization.Prefix.."(.+)")
if z then
for A,B in ipairs(r.LocalizationObjects)do
if B.Object==v then
B.TranslationId=z
r.SetLangForObject(A)
return
end
end

table.insert(r.LocalizationObjects,{
TranslationId=z,
Object=v,
})
r.SetLangForObject(#r.LocalizationObjects)
end
end
end

function r.UpdateLang(u)
if u then
r.Language=u
end

for v=1,#r.LocalizationObjects do
local x=r.LocalizationObjects[v]
if x.Object and x.Object.Parent~=nil then
r.SetLangForObject(v)
else
r.LocalizationObjects[v]=nil
end
end
end

function r.SetLanguage(u)
r.Language=u
r.UpdateLang()
end

function r.Icon(u,v)
return m.Icon2(u,nil,v~=false)
end

function r.AddIcons(u,v)
return m.AddIcons(u,v)
end

function r.New(u,v,x)
local z=Instance.new(u)

for A,B in next,r.DefaultProperties[u]or{}do
z[A]=B
end

for A,B in next,v or{}do
if A~="ThemeTag"then
z[A]=B
end
if r.Localization and r.Localization.Enabled and A=="Text"then
local C=string.match(B,"^"..r.Localization.Prefix.."(.+)")
if C then
local F=#r.LocalizationObjects+1
r.LocalizationObjects[F]={TranslationId=C,Object=z}

r.SetLangForObject(F)
end
end
end

for A,B in next,x or{}do
B.Parent=z
end

if v and v.ThemeTag then
r.AddThemeObject(z,v.ThemeTag)
end
if v and v.FontFace then
r.AddFontObject(z)
end
return z
end

function r.Tween(u,v,x,...)
return f:Create(u,TweenInfo.new(v,...),x)
end








































































function r.NewRoundFrame(u,v,x,z,A,B)
return i:New(u,v,x,z,A,nil)
end

local u=r.New local v=
r.Tween

function r.SetDraggable(x)
r.CanDraggable=x
end

function r.Drag(x,z,A)
local B=p.GenerateGUID()

local C
local F=false
local G,H
local J

local L={
CanDraggable=true,
}

if not z or typeof(z)~="table"then
z={x}
end

local function update(M)
if not F or not L.CanDraggable then
return
end

local N=M.Position-G
x.Position=UDim2.new(
H.X.Scale,
H.X.Offset+N.X,
H.Y.Scale,
H.Y.Offset+N.Y
)
end

for M,N in pairs(z)do
N.InputBegan:Connect(function(O)
if not L.CanDraggable or F then
return
end

if
O.UserInputType==Enum.UserInputType.MouseButton1
or O.UserInputType==Enum.UserInputType.Touch
then
if p and p.CurrentInput and p.CurrentInput~=B then
return
end

p.CurrentInput=B

F=true
J=O
C=N
G=O.Position
H=x.Position

if A and typeof(A)=="function"then
A(true,C)
end
end
end)
end

e.InputChanged:Connect(function(M)
if not F then
return
end
if p.CurrentInput and p.CurrentInput~=B then
return
end

if J.UserInputType==Enum.UserInputType.MouseButton1 then
if M.UserInputType==Enum.UserInputType.MouseMovement then
update(M)
end
elseif J.UserInputType==Enum.UserInputType.Touch then
if M==J then
update(M)
end
end
end)

e.InputEnded:Connect(function(M)
if not F or p.CurrentInput~=B then
return
end

if
M==J
or(
J.UserInputType==Enum.UserInputType.MouseButton1
and M.UserInputType==Enum.UserInputType.MouseButton1
)
then
p.CurrentInput=nil
F=false
J=nil
C=nil

if A and typeof(A)=="function"then
A(false,nil)
end
end
end)

function L.Set(M,N)
L.CanDraggable=N
end

return L
end

m.Init(u,"Icon")

function r.SanitizeFilename(x)
local z=x:match"([^/]+)$"or x

z=z:gsub("%.[^%.]+$","")

z=z:gsub("[^%w%-_]","_")

if#z>50 then
z=z:sub(1,50)
end

return z
end

function r.Image(x,z,A,B,C,F,G,H)
B=B or"Temp"
z=r.SanitizeFilename(z)

local J=u("Frame",{
Size=UDim2.new(0,0,0,0),
BackgroundTransparency=1,
},{
u("ImageLabel",{
Size=UDim2.new(1,0,1,0),
BackgroundTransparency=1,
ScaleType="Crop",
ThemeTag=(r.Icon(x)or G)and{
ImageColor3=F and(H or"Icon")or nil,
}or nil,
},{
u("UICorner",{
CornerRadius=UDim.new(0,A),
}),
}),
})
if r.Icon(x)then
J.ImageLabel:Destroy()

local L=m.Image{
Icon=x,
Size=UDim2.new(1,0,1,0),
Colors={
(F and(H or"Icon")or false),
"Button",
},
}.IconFrame
L.Parent=J
elseif string.find(x,"http")and not string.find(x,"roblox.com")then
local L="WindUI/"..B.."/assets/."..C.."-"..z..".png"
local M,N=pcall(function()
task.spawn(function()
local M=r.Request
and r.Request{
Url=x,
Method="GET",
}.Body
or{}

if not d:IsStudio()and writefile then
writefile(L,M)
end


local N,O=pcall(getcustomasset,L)
if N then
J.ImageLabel.Image=O
else
warn(
string.format(
"[ WindUI.Creator ] Failed to load custom asset '%s': %s",
L,
tostring(O)
)
)
J:Destroy()

return
end
end)
end)
if not M then
warn(
"[ WindUI.Creator ]  '"..identifyexecutor()
or"Studio".."' doesnt support the URL Images. Error: "..N
)

J:Destroy()
end
elseif x==""then
J.Visible=false
else
J.ImageLabel.Image=x
end

return J
end

function r.Color3ToHSB(x)
local z,A,B=x.R,x.G,x.B
local C=math.max(z,A,B)
local F=math.min(z,A,B)
local G=C-F

local H=0
if G~=0 then
if C==z then
H=(A-B)/G%6
elseif C==A then
H=(B-z)/G+2
else
H=(z-A)/G+4
end
H=H*60
else
H=0
end

local J=(C==0)and 0 or(G/C)
local L=C

return{
h=math.floor(H+0.5),
s=J,
b=L,
}
end

function r.GetPerceivedBrightness(x)
local z=x.R
local A=x.G
local B=x.B
return 0.299*z+0.587*A+0.114*B
end

function r.GetTextColorForHSB(x,z)
local A=r.Color3ToHSB(x)local
B, C, F=A.h, A.s, A.b
if r.GetPerceivedBrightness(x)>(z or 0.5)then
return Color3.fromHSV(B/360,0,0.05)
else
return Color3.fromHSV(B/360,0,0.98)
end
end

function r.GetAverageColor(x)
local z,A,B=0,0,0
local C=x.Color.Keypoints
for F,G in ipairs(C)do

z=z+G.Value.R
A=A+G.Value.G
B=B+G.Value.B
end
local F=#C
return Color3.new(z/F,A/F,B/F)
end

function r.GenerateUniqueID(x)
return h:GenerateGUID(false)
end

function r.OnThemeChange(x,z)
if typeof(z)~="function"then
return
end

local A=h:GenerateGUID(false)
r.ThemeChangeCallbacks[A]=z

return{
Disconnect=function()
r.ThemeChangeCallbacks[A]=nil
end,
}
end

function r.AddColor(x,z,A,B)
B=math.clamp(B or 1,0,1)
if typeof(A)=="string"then
A=Color3.fromHex(A)
end

return function(C)
local F
if typeof(z)=="string"and string.sub(z,1,1)~="#"then
F=r.GetThemeProperty(z,C)
elseif typeof(z)=="string"then
F=Color3.fromHex(z)
else
F=z
end

if not F or typeof(F)~="Color3"then
return nil
end

return Color3.new(
math.clamp(F.R+A.R*B,0,1),
math.clamp(F.G+A.G*B,0,1),
math.clamp(F.B+A.B*B,0,1)
)
end
end

function r.GetElementPosition(x,z,A,B)
if type(A)~="number"or A~=math.floor(A)then
return nil,1
end






local C=#z


if C==0 or A<1 or A>C then
return nil,2
end

local function isDelimiter(F)
if F==nil then
return true
end
local G=F.__type
return G=="Divider"or G=="Space"or G=="Section"
end

if isDelimiter(z[A])then
return nil,3
end

local function calculate(F,G)
if G==1 then
return"Squircle"
end
if F==1 then
return B and"SquircleH-TL-TR"or"Squircle-TL-TR"
end
if F==G then
return B and"SquircleH-BL-BR"or"Squircle-BL-BR"
end
return"Square"
end

local F=1
local G=0

for H=1,C do
local J=z[H]
if isDelimiter(J)then
if A>=F and A<=H-1 then
local L=A-F+1
return calculate(L,G)
end
F=H+1
G=0
else
G=G+1
end
end

if A>=F and A<=C then
local H=A-F+1
return calculate(H,G)
end

return nil,4
end

return r end function a.e()

local b={}







function b.New(d,e,f)
local g={
Enabled=e.Enabled or false,
Translations=e.Translations or{},
Prefix=e.Prefix or"loc:",
DefaultLanguage=e.DefaultLanguage or"en"
}

f.Localization=g

return g
end



return b end function a.f()
local b=a.load'd'
local d=b.New
local e=b.Tween

local f={
Size=UDim2.new(0,300,1,-156),
SizeLower=UDim2.new(0,300,1,-56),
UICorner=18,
UIPadding=14,

Holder=nil,
NotificationIndex=0,
Notifications={},
}

function f.Init(g)
local h={
Lower=false,
}

function h.SetLower(i)
h.Lower=i
h.Frame.Size=i and f.SizeLower or f.Size
end

h.Frame=d("Frame",{
Position=UDim2.new(1,-29,0,56),
AnchorPoint=Vector2.new(1,0),
Size=f.Size,
Parent=g,
BackgroundTransparency=1,




},{
d("UIListLayout",{
HorizontalAlignment="Center",
SortOrder="LayoutOrder",
VerticalAlignment="Bottom",
Padding=UDim.new(0,8),
}),
d("UIPadding",{
PaddingBottom=UDim.new(0,29),
}),
})
return h
end

function f.New(g)
local h={
Title=g.Title or"Notification",
Content=g.Content or nil,
Icon=g.Icon or nil,
IconThemed=g.IconThemed,
Background=g.Background,
BackgroundImageTransparency=g.BackgroundImageTransparency,
Duration=g.Duration or 5,
Buttons=g.Buttons or{},
CanClose=g.CanClose~=false,
UIElements={},
Closed=false,
}



f.NotificationIndex=f.NotificationIndex+1
f.Notifications[f.NotificationIndex]=h









local i

if h.Icon then





















i=b.Image(
h.Icon,
h.Title..":"..h.Icon,
0,
g.Window,
"Notification",
h.IconThemed
)
i.Size=UDim2.new(0,26,0,26)
i.Position=UDim2.new(0,f.UIPadding,0,f.UIPadding)

end

local l
if h.CanClose then
l=d("ImageButton",{
Image=b.Icon"x"[1],
ImageRectSize=b.Icon"x"[2].ImageRectSize,
ImageRectOffset=b.Icon"x"[2].ImageRectPosition,
BackgroundTransparency=1,
Size=UDim2.new(0,16,0,16),
Position=UDim2.new(1,-f.UIPadding,0,f.UIPadding),
AnchorPoint=Vector2.new(1,0),
ThemeTag={
ImageColor3="Text",
},
ImageTransparency=0.4,
},{
d("TextButton",{
Size=UDim2.new(1,8,1,8),
BackgroundTransparency=1,
AnchorPoint=Vector2.new(0.5,0.5),
Position=UDim2.new(0.5,0,0.5,0),
Text="",
}),
})
end

local m=b.NewRoundFrame(f.UICorner,"Squircle",{
Size=UDim2.new(0,0,1,0),
ThemeTag={
ImageTransparency="NotificationDurationTransparency",
ImageColor3="NotificationDuration",
},

})

local p=d("Frame",{
Size=UDim2.new(1,h.Icon and-28-f.UIPadding or 0,1,0),
Position=UDim2.new(1,0,0,0),
AnchorPoint=Vector2.new(1,0),
BackgroundTransparency=1,
AutomaticSize="Y",
},{
d("UIPadding",{
PaddingTop=UDim.new(0,f.UIPadding),
PaddingLeft=UDim.new(0,f.UIPadding),
PaddingRight=UDim.new(0,f.UIPadding),
PaddingBottom=UDim.new(0,f.UIPadding),
}),
d("TextLabel",{
AutomaticSize="Y",
Size=UDim2.new(1,-30-f.UIPadding,0,0),
TextWrapped=true,
TextXAlignment="Left",
RichText=true,
BackgroundTransparency=1,
TextSize=18,
ThemeTag={
TextColor3="NotificationTitle",
TextTransparency="NotificationTitleTransparency",
},
Text=h.Title,
FontFace=Font.new(b.Font,Enum.FontWeight.SemiBold),
}),
d("UIListLayout",{
Padding=UDim.new(0,f.UIPadding/3),
}),
})

if h.Content then
d("TextLabel",{
AutomaticSize="Y",
Size=UDim2.new(1,0,0,0),
TextWrapped=true,
TextXAlignment="Left",
RichText=true,
BackgroundTransparency=1,

TextSize=15,
ThemeTag={
TextColor3="NotificationContent",
TextTransparency="NotificationContentTransparency",
},
Text=h.Content,
FontFace=Font.new(b.Font,Enum.FontWeight.Medium),
Parent=p,
})
end

local r=b.NewRoundFrame(f.UICorner,"Squircle",{
Size=UDim2.new(1,0,0,0),
Position=UDim2.new(2,0,1,0),
AnchorPoint=Vector2.new(0,1),
AutomaticSize="Y",
ImageTransparency=0.05,
ThemeTag={
ImageColor3="Notification",
},

},{
b.NewRoundFrame(f.UICorner,"Squircle",{
Size=UDim2.new(1,0,1,0),
ThemeTag={
ImageColor3="Notification2",
ImageTransparency="Notification2Transparency",
},
}),
d("Frame",{
Size=UDim2.new(1,0,1,0),
BackgroundTransparency=1,
Name="DurationFrame",
},{






d("Frame",{
Size=UDim2.new(1,0,1,0),
BackgroundTransparency=1,
ClipsDescendants=true,
},{
m,
}),




}),
d("ImageLabel",{
Name="Background",
Image=h.Background,
BackgroundTransparency=1,
Size=UDim2.new(1,0,1,0),
ScaleType="Crop",
ImageTransparency=h.BackgroundImageTransparency,

},{
d("UICorner",{
CornerRadius=UDim.new(0,f.UICorner),
}),
}),

p,
i,
l,
})

local u=d("Frame",{
BackgroundTransparency=1,
Size=UDim2.new(1,0,0,0),
Parent=g.Holder,
},{
r,
})

function h.Close(v)
if not h.Closed then
h.Closed=true
e(
u,
0.45,
{Size=UDim2.new(1,0,0,-8)},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()
e(r,0.55,{Position=UDim2.new(2,0,1,0)},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
task.wait(0.45)
u:Destroy()
end
end

task.spawn(function()
task.wait()
e(
u,
0.45,
{Size=UDim2.new(1,0,0,r.AbsoluteSize.Y)},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()
e(r,0.45,{Position=UDim2.new(0,0,1,0)},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
if h.Duration then
m.Size=UDim2.new(0,r.DurationFrame.AbsoluteSize.X,1,0)
e(
r.DurationFrame.Frame,
h.Duration,
{Size=UDim2.new(0,0,1,0)},
Enum.EasingStyle.Linear,
Enum.EasingDirection.InOut
):Play()
task.wait(h.Duration)
h:Close()
end
end)

if l then
b.AddSignal(l.TextButton.MouseButton1Click,function()
h:Close()
end)
end


return h
end

return f end function a.g()












local b=4294967296;local d=b-1;local function c(e,f)local g,h=0,1;while e~=0 or f~=0 do local i,l=e%2,f%2;local m=(i+l)%2;g=g+m*h;e=math.floor(e/2)f=math.floor(f/2)h=h*2 end;return g%b end;local function k(e,f,g,...)local h;if f then e=e%b;f=f%b;h=c(e,f)if g then h=k(h,g,...)end;return h elseif e then return e%b else return 0 end end;local function n(e,f,g,...)local h;if f then e=e%b;f=f%b;h=(e+f-c(e,f))/2;if g then h=n(h,g,...)end;return h elseif e then return e%b else return d end end;local function o(e)return d-e end;local function q(e,f)if f<0 then return lshift(e,-f)end;return math.floor(e%4294967296/2^f)end;local function s(e,f)if f>31 or f<-31 then return 0 end;return q(e%b,f)end;local function lshift(e,f)if f<0 then return s(e,-f)end;return e*2^f%4294967296 end;local function t(e,f)e=e%b;f=f%32;local g=n(e,2^f-1)return s(e,f)+lshift(g,32-f)end;local e={0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2}local function w(f)return string.gsub(f,".",function(g)return string.format("%02x",string.byte(g))end)end;local function y(f,g)local h=""for i=1,g do local l=f%256;h=string.char(l)..h;f=(f-l)/256 end;return h end;local function D(f,g)local h=0;for i=g,g+3 do h=h*256+string.byte(f,i)end;return h end;local function E(f,g)local h=64-(g+9)%64;g=y(8*g,8)f=f.."\128"..string.rep("\0",h)..g;assert(#f%64==0)return f end;local function I(f)f[1]=0x6a09e667;f[2]=0xbb67ae85;f[3]=0x3c6ef372;f[4]=0xa54ff53a;f[5]=0x510e527f;f[6]=0x9b05688c;f[7]=0x1f83d9ab;f[8]=0x5be0cd19;return f end;local function K(f,g,h)local i={}for l=1,16 do i[l]=D(f,g+(l-1)*4)end;for l=17,64 do local m=i[l-15]local p=k(t(m,7),t(m,18),s(m,3))m=i[l-2]i[l]=(i[l-16]+p+i[l-7]+k(t(m,17),t(m,19),s(m,10)))%b end;local l,m,p,r,u,v,x,z=h[1],h[2],h[3],h[4],h[5],h[6],h[7],h[8]for A=1,64 do local B=k(t(l,2),t(l,13),t(l,22))local C=k(n(l,m),n(l,p),n(m,p))local F=(B+C)%b;local G=k(t(u,6),t(u,11),t(u,25))local H=k(n(u,v),n(o(u),x))local J=(z+G+H+e[A]+i[A])%b;z=x;x=v;v=u;u=(r+J)%b;r=p;p=m;m=l;l=(J+F)%b end;h[1]=(h[1]+l)%b;h[2]=(h[2]+m)%b;h[3]=(h[3]+p)%b;h[4]=(h[4]+r)%b;h[5]=(h[5]+u)%b;h[6]=(h[6]+v)%b;h[7]=(h[7]+x)%b;h[8]=(h[8]+z)%b end;local function Z(f)f=E(f,#f)local g=I{}for h=1,#f,64 do K(f,h,g)end;return w(y(g[1],4)..y(g[2],4)..y(g[3],4)..y(g[4],4)..y(g[5],4)..y(g[6],4)..y(g[7],4)..y(g[8],4))end;local f;local g={["\\"]="\\",["\""]="\"",["\b"]="b",["\f"]="f",["\n"]="n",["\r"]="r",["\t"]="t"}local h={["/"]="/"}for i,l in pairs(g)do h[l]=i end;local i=function(i)return"\\"..(g[i]or string.format("u%04x",i:byte()))end;local l=function(l)return"null"end;local m=function(m,p)local r={}p=p or{}if p[m]then error"circular reference"end;p[m]=true;if rawget(m,1)~=nil or next(m)==nil then local u=0;for v in pairs(m)do if type(v)~="number"then error"invalid table: mixed or invalid key types"end;u=u+1 end;if u~=#m then error"invalid table: sparse array"end;for v,x in ipairs(m)do table.insert(r,f(x,p))end;p[m]=nil;return"["..table.concat(r,",").."]"else for u,v in pairs(m)do if type(u)~="string"then error"invalid table: mixed or invalid key types"end;table.insert(r,f(u,p)..":"..f(v,p))end;p[m]=nil;return"{"..table.concat(r,",").."}"end end;local p=function(p)return'"'..p:gsub('[%z\1-\31\\"]',i)..'"'end;local r=function(r)if r~=r or r<=-math.huge or r>=math.huge then error("unexpected number value '"..tostring(r).."'")end;return string.format("%.14g",r)end;local u={["nil"]=l,table=m,string=p,number=r,boolean=tostring}f=function(v,x)local z=type(v)local A=u[z]if A then return A(v,x)end;error("unexpected type '"..z.."'")end;local v=function(v)return f(v)end;local x;local z=function(...)local z={}for A=1,select("#",...)do z[select(A,...)]=true end;return z end;local A=z(" ","\t","\r","\n")local B=z(" ","\t","\r","\n","]","}",",")local C=z("\\","/",'"',"b","f","n","r","t","u")local F=z("true","false","null")local G={["true"]=true,["false"]=false,null=nil}local H=function(H,J,L,M)for N=J,#H do if L[H:sub(N,N)]~=M then return N end end;return#H+1 end;local J=function(J,L,M)local N=1;local O=1;for P=1,L-1 do O=O+1;if J:sub(P,P)=="\n"then N=N+1;O=1 end end;error(string.format("%s at line %d col %d",M,N,O))end;local L=function(L)local M=math.floor;if L<=0x7f then return string.char(L)elseif L<=0x7ff then return string.char(M(L/64)+192,L%64+128)elseif L<=0xffff then return string.char(M(L/4096)+224,M(L%4096/64)+128,L%64+128)elseif L<=0x10ffff then return string.char(M(L/262144)+240,M(L%262144/4096)+128,M(L%4096/64)+128,L%64+128)end;error(string.format("invalid unicode codepoint '%x'",L))end;local M=function(M)local N=tonumber(M:sub(1,4),16)local O=tonumber(M:sub(7,10),16)if O then return L((N-0xd800)*0x400+O-0xdc00+0x10000)else return L(N)end end;local N=function(N,O)local P=""local Q=O+1;local R=Q;while Q<=#N do local S=N:byte(Q)if S<32 then J(N,Q,"control character in string")elseif S==92 then P=P..N:sub(R,Q-1)Q=Q+1;local T=N:sub(Q,Q)if T=="u"then local U=N:match("^[dD][89aAbB]%x%x\\u%x%x%x%x",Q+1)or N:match("^%x%x%x%x",Q+1)or J(N,Q-1,"invalid unicode escape in string")P=P..M(U)Q=Q+#U else if not C[T]then J(N,Q-1,"invalid escape char '"..T.."' in string")end;P=P..h[T]end;R=Q+1 elseif S==34 then P=P..N:sub(R,Q-1)return P,Q+1 end;Q=Q+1 end;J(N,O,"expected closing quote for string")end;local O=function(O,P)local Q=H(O,P,B)local R=O:sub(P,Q-1)local S=tonumber(R)if not S then J(O,P,"invalid number '"..R.."'")end;return S,Q end;local P=function(P,Q)local R=H(P,Q,B)local S=P:sub(Q,R-1)if not F[S]then J(P,Q,"invalid literal '"..S.."'")end;return G[S],R end;local Q=function(Q,R)local S={}local T=1;R=R+1;while 1 do local U;R=H(Q,R,A,true)if Q:sub(R,R)=="]"then R=R+1;break end;U,R=x(Q,R)S[T]=U;T=T+1;R=H(Q,R,A,true)local V=Q:sub(R,R)R=R+1;if V=="]"then break end;if V~=","then J(Q,R,"expected ']' or ','")end end;return S,R end;local R=function(R,S)local T={}S=S+1;while 1 do local U,V;S=H(R,S,A,true)if R:sub(S,S)=="}"then S=S+1;break end;if R:sub(S,S)~='"'then J(R,S,"expected string for key")end;U,S=x(R,S)S=H(R,S,A,true)if R:sub(S,S)~=":"then J(R,S,"expected ':' after key")end;S=H(R,S+1,A,true)V,S=x(R,S)T[U]=V;S=H(R,S,A,true)local W=R:sub(S,S)S=S+1;if W=="}"then break end;if W~=","then J(R,S,"expected '}' or ','")end end;return T,S end;local S={['"']=N,["0"]=O,["1"]=O,["2"]=O,["3"]=O,["4"]=O,["5"]=O,["6"]=O,["7"]=O,["8"]=O,["9"]=O,["-"]=O,t=P,f=P,n=P,["["]=Q,["{"]=R}x=function(T,U)local V=T:sub(U,U)local W=S[V]if W then return W(T,U)end;J(T,U,"unexpected character '"..V.."'")end;local T=function(T)if type(T)~="string"then error("expected argument of type string, got "..type(T))end;local U,V=x(T,H(T,1,A,true))V=H(T,V,A,true)if V<=#T then J(T,V,"trailing garbage")end;return U end;
local U,V,W=v,T,Z;





local X={}

local Y=(cloneref or clonereference or function(Y)return Y end)


function X.New(_,aa)

local ab=_;
local ac=aa;
local ad=true;


local ae=function(ae)end;


repeat task.wait(1)until game:IsLoaded();


local af=false;
local ag,ah,ai,aj,ak,al,am,an,ao=setclipboard or toclipboard,request or http_request or syn_request,string.char,tostring,string.sub,os.time,math.random,math.floor,gethwid or function()return Y(game:GetService"Players").LocalPlayer.UserId end
local ap,aq="",0;


local ar="https://api.platoboost.app";
local as=ah{
Url=ar.."/public/connectivity",
Method="GET"
};
if as.StatusCode~=200 and as.StatusCode~=429 then
ar="https://api.platoboost.net";
end


function cacheLink()
if aq+(600)<al()then
local at=ah{
Url=ar.."/public/start",
Method="POST",
Body=U{
service=ab,
identifier=W(ao())
},
Headers={
["Content-Type"]="application/json",
["User-Agent"]="Roblox/Exploit"
}
};

if at.StatusCode==200 then
local au=V(at.Body);

if au.success==true then
ap=au.data.url;
aq=al();
return true,ap
else
ae(au.message);
return false,au.message
end
elseif at.StatusCode==429 then
local au="you are being rate limited, please wait 20 seconds and try again.";
ae(au);
return false,au
end

local au="Failed to cache link.";
ae(au);
return false,au
else
return true,ap
end
end

cacheLink();


local at=function()
local at=""
for au=1,16 do
at=at..ai(an(am()*(26))+97)
end
return at
end


for au=1,5 do
local av=at();
task.wait(0.2)
if at()==av then
local aw="platoboost nonce error.";
ae(aw);
error(aw);
end
end


local au=function()
local au,av=cacheLink();

if au then
ag(av);
end
end


local av=function(av)
local aw=at();
local ax=ar.."/public/redeem/"..aj(ab);

local ay={
identifier=W(ao()),
key=av
}

if ad then
ay.nonce=aw;
end

local az=ah{
Url=ax,
Method="POST",
Body=U(ay),
Headers={
["Content-Type"]="application/json"
}
};

if az.StatusCode==200 then
local aA=V(az.Body);

if aA.success==true then
if aA.data.valid==true then
if ad then
if aA.data.hash==W("true".."-"..aw.."-"..ac)then
return true
else
ae"failed to verify integrity.";
return false
end
else
return true
end
else
ae"key is invalid.";
return false
end
else
if ak(aA.message,1,27)=="unique constraint violation"then
ae"you already have an active key, please wait for it to expire before redeeming it.";
return false
else
ae(aA.message);
return false
end
end
elseif az.StatusCode==429 then
ae"you are being rate limited, please wait 20 seconds and try again.";
return false
else
ae"server returned an invalid status code, please try again later.";
return false
end
end


local aw=function(aw)
if af==true then
return false,("A request is already being sent, please slow down.")
else
af=true;
end

local ax=at();
local ay=ar.."/public/whitelist/"..aj(ab).."?identifier="..W(ao()).."&key="..aw;

if ad then
ay=ay.."&nonce="..ax;
end

local az=ah{
Url=ay,
Method="GET",
};

af=false;

if az.StatusCode==200 then
local aA=V(az.Body);

if aA.success==true then
if aA.data.valid==true then
if ad then
if aA.data.hash==W("true".."-"..ax.."-"..ac)then
return true,""
else
return false,("failed to verify integrity.")
end
else
return true
end
else
if ak(aw,1,4)=="KEY_"then
return true,av(aw)
else
return false,("Key is invalid.")
end
end
else
return false,(aA.message)
end
elseif az.StatusCode==429 then
return false,("You are being rate limited, please wait 20 seconds and try again.")
else
return false,("Server returned an invalid status code, please try again later.")
end
end


local ax=function(ax)
local ay=at();
local az=ar.."/public/flag/"..aj(ab).."?name="..ax;

if ad then
az=az.."&nonce="..ay;
end

local aA=ah{
Url=az,
Method="GET",
};

if aA.StatusCode==200 then
local aB=V(aA.Body);

if aB.success==true then
if ad then
if aB.data.hash==W(aj(aB.data.value).."-"..ay.."-"..ac)then
return aB.data.value
else
ae"failed to verify integrity.";
return nil
end
else
return aB.data.value
end
else
ae(aB.message);
return nil
end
else
return nil
end
end


return{
Verify=aw,
GetFlag=ax,
Copy=au,
}
end


return X end function a.h()






local aa=(cloneref or clonereference or function(aa)
return aa
end)

local ab=aa(game:GetService"HttpService")
local ac={}

function ac.New(ad)
local ae=gethwid or function()
return aa(game:GetService"Players").LocalPlayer.UserId
end
local af,ag=request or http_request or syn_request,setclipboard or toclipboard

function ValidateKey(ah)
local ai="https://api.pandauth.com/api/v1/keys/validate"

local aj={
ServiceID=ad,
HWID=tostring(ae()),
Key=tostring(ah),
}

local ak=ab:JSONEncode(aj)
local al,am=pcall(function()
return af{
Url=ai,
Method="POST",
Headers={
["User-Agent"]="Roblox/Exploit",
["Content-Type"]="application/json",
},
Body=ak,
}
end)

if al and am then
if am.Success then
local an,ao=pcall(function()
return ab:JSONDecode(am.Body)
end)

if an and ao then
if ao.Authenticated_Status and ao.Authenticated_Status=="Success"then
return true,"Authenticated"
else
local ap=ao.Note or"Unknown reason"
return false,"Authentication failed: "..ap
end
else
return false,"JSON decode error"
end
else
warn(
" HTTP request was not successful. Code: "
..tostring(am.StatusCode)
.." Message: "
..am.StatusMessage
)
return false,"HTTP request failed: "..am.StatusMessage
end
else
return false,"Request pcall error"
end
end

function GetKeyLink()
return"https://new.pandadevelopment.net/getkey/"..tostring(ad).."?hwid="..tostring(ae())
end

function CopyLink()
return ag(GetKeyLink())
end

return{
Verify=ValidateKey,
Copy=CopyLink,
}
end

return ac end function a.i()







local aa={}

function aa.New(ab,ac)
local ad="https://sdkapi-public.luarmor.net/library.lua"

local ae=loadstring(game.HttpGet and game:HttpGet(ad)or HttpService:GetAsync(ad))()
local af=setclipboard or toclipboard

ae.script_id=ab

function ValidateKey(ag)
local ah=ae.check_key(ag)


if ah.code=="KEY_VALID"then
return true,"Whitelisted!"
elseif ah.code=="KEY_HWID_LOCKED"then
return false,"Key linked to a different HWID. Please reset it using our bot"
elseif ah.code=="KEY_INCORRECT"then
return false,"Key is wrong or deleted!"
else
return false,"Key check failed:"..ah.message.." Code: "..ah.code
end
end

function CopyLink()
af(tostring(ac))
end

return{
Verify=ValidateKey,
Copy=CopyLink,
}
end

return aa end function a.j()









local aa={}

function aa.New(ab,ac,ad)
JunkieProtected.API_KEY=ac
JunkieProtected.PROVIDER=ad
JunkieProtected.SERVICE_ID=ab

local function ValidateKey(ae)
if not ae or ae==""then
print"No key provided!"

return false,"No key provided. Please get a key."
end

local af=JunkieProtected.IsKeylessMode()
if af and af.keyless_mode then
print"Keyless mode enabled. Starting script..."
return true,"Keyless mode enabled. Starting script..."
end

local ag=JunkieProtected.ValidateKey{Key=ae}
if ag=="valid"then
print"Key is valid! Starting script..."
load()
if _G.JD_IsPremium then
print"Premium user detected!"
else
print"Standard user"
end

return true,"Key is valid!"
else
local ah=JunkieProtected.GetKeyLink()
print"Invalid key!"

return false,"Invalid key. Get one from:"..ah
end
end

local function copyLink()
local ae=JunkieProtected.GetKeyLink()

if setclipboard then
setclipboard(ae)
end
end
return{
Verify=ValidateKey,
Copy=copyLink
}
end

return aa end function a.k()



return{
platoboost={
Name="Platoboost",
Icon="rbxassetid://75920162824531",
Args={"ServiceId","Secret"},

New=a.load'g'.New
},
pandadevelopment={
Name="Panda Development",
Icon="panda",
Args={"ServiceId"},

New=a.load'h'.New
},
luarmor={
Name="Luarmor",
Icon="rbxassetid://130918283130165",
Args={"ScriptId","Discord"},

New=a.load'i'.New
},
junkiedevelopment={
Name="Junkie Development",
Icon="rbxassetid://106310347705078",
Args={"ServiceId","ApiKey","Provider"},

New=a.load'j'.New
},


}end function a.l()



return[[
{
    "name": "windui",
    "version": "1.6.65",
    "main": "./dist/main.lua",
    "repository": "https://github.com/Footagesus/WindUI",
    "discord": "https://discord.gg/ftgs-development-hub-1300692552005189632",
    "author": "Footagesus",
    "description": "Roblox UI Library for scripts",
    "license": "MIT",
    "scripts": {
        "dev": "bash build/build.sh dev $INPUT_FILE",
        "build": "bash build/build.sh build $INPUT_FILE",
        "live": "python3 -m http.server 8642",
        "watch": "chokidar . -i 'node_modules' -i 'dist' -i 'build' -c 'npm run dev --'",
        "live-build": "concurrently \"npm run live\" \"npm run watch --\"",
        "example-live-build": "INPUT_FILE=main_example.lua npm run live-build",
        "updater": "python3 updater/main.py"
    },
    "keywords": [
        "ui-library",
        "ui-design",
        "script",
        "script-hub",
        "exploiting"
    ],
    "devDependencies": {
        "chokidar-cli": "^3.0.0",
        "concurrently": "^9.2.0"
    }
}
]]end function a.m()

local aa={}

local ab=a.load'd'
local ac=ab.New
local ad=ab.Tween

function aa.New(ae,af,ag,ah,ai,aj,ak,al)
ah=ah or"Primary"
local am=al or(not ak and 10 or 999)
local an
if af and af~=""then
an=ac("ImageLabel",{
Image=ab.Icon(af)[1],
ImageRectSize=ab.Icon(af)[2].ImageRectSize,
ImageRectOffset=ab.Icon(af)[2].ImageRectPosition,
Size=UDim2.new(0,21,0,21),
BackgroundTransparency=1,
ImageColor3=ah=="White"and Color3.new(0,0,0)or nil,
ImageTransparency=ah=="White"and 0.4 or 0,
ThemeTag={
ImageColor3=ah~="White"and"Icon"or nil,
},
})
end

local ao=ac("TextButton",{
Size=UDim2.new(0,0,1,0),
AutomaticSize="X",
Parent=ai,
BackgroundTransparency=1,
},{
ab.NewRoundFrame(am,"Squircle",{
ThemeTag={
ImageColor3=ah~="White"and"Button"or nil,
},
ImageColor3=ah=="White"and Color3.new(1,1,1)or nil,
Size=UDim2.new(1,0,1,0),
Name="Squircle",
ImageTransparency=ah=="Primary"and 0 or ah=="White"and 0 or 0.9,
}),

ab.NewRoundFrame(am,"Squircle",{



ImageColor3=Color3.new(1,1,1),
Size=UDim2.new(1,0,1,0),
Name="Special",
ImageTransparency=ah=="Secondary"and 0.95 or 1,
}),

ab.NewRoundFrame(am,"Shadow-sm",{



ImageColor3=Color3.new(0,0,0),
Size=UDim2.new(1,3,1,3),
AnchorPoint=Vector2.new(0.5,0.5),
Position=UDim2.new(0.5,0,0.5,0),
Name="Shadow",

ImageTransparency=1,
Visible=not ak,
}),

ab.NewRoundFrame(am,"SquircleGlass",{
ThemeTag={
ImageColor3="White",
},
Size=UDim2.new(1,1,1,1),

ImageTransparency=0.9,
AnchorPoint=Vector2.new(0.5,0.5),
Position=UDim2.new(0.5,0,0.5,0),
Name="Outline",
},{













}),

ab.NewRoundFrame(am,"Squircle",{
Size=UDim2.new(1,0,1,0),
Name="Frame",
ThemeTag={
ImageColor3=ah~="White"and"Text"or nil,
},
ImageColor3=ah=="White"and Color3.new(0,0,0)or nil,
ImageTransparency=1,
},{
ac("UIPadding",{
PaddingLeft=UDim.new(0,16),
PaddingRight=UDim.new(0,16),
}),
ac("UIListLayout",{
FillDirection="Horizontal",
Padding=UDim.new(0,8),
VerticalAlignment="Center",
HorizontalAlignment="Center",
}),
an,
ac("TextLabel",{
BackgroundTransparency=1,
FontFace=Font.new(ab.Font,Enum.FontWeight.SemiBold),
Text=ae or"Button",
ThemeTag={
TextColor3=(ah~="Primary"and ah~="White")and"Text",
},
TextColor3=ah=="Primary"and Color3.new(1,1,1)
or ah=="White"and Color3.new(0,0,0)
or nil,
AutomaticSize="XY",
TextSize=18,
}),
}),
})

ab.AddSignal(ao.MouseEnter,function()
ad(ao.Frame,0.047,{ImageTransparency=0.95}):Play()
end)
ab.AddSignal(ao.MouseLeave,function()
ad(ao.Frame,0.047,{ImageTransparency=1}):Play()
end)
ab.AddSignal(ao.MouseButton1Click,function()
if aj then
aj:Close()()
end
if ag then
ab.SafeCallback(ag)
end
end)

return ao
end

return aa end function a.n()

local aa={}

local ab=a.load'd'
local ac=ab.New local ad=
ab.Tween

function aa.New(ae,af,ag,ah,ai,aj,ak,al,am)
ah=ah or"Input"
local an=ak or 10
local ao
if af and af~=""then
ao=ac("ImageLabel",{
Image=ab.Icon(af)[1],
ImageRectSize=ab.Icon(af)[2].ImageRectSize,
ImageRectOffset=ab.Icon(af)[2].ImageRectPosition,
Size=UDim2.new(0,21,0,21),
BackgroundTransparency=1,
ThemeTag={
ImageColor3="Icon",
},
})
end

local ap=ah=="Textarea"

local aq=ac("TextBox",{
BackgroundTransparency=1,
TextSize=17,
FontFace=Font.new(ab.Font,Enum.FontWeight.Regular),
Size=UDim2.new(1,ao and-29 or 0,1,0),
PlaceholderText=ae,
ClearTextOnFocus=al or false,
ClipsDescendants=true,
TextWrapped=ap,
MultiLine=ap,
TextXAlignment="Left",
TextYAlignment=ah~="Textarea"and"Center"or"Top",

ThemeTag={
PlaceholderColor3="PlaceholderText",
TextColor3="Text",
},
})

local ar=ac("Frame",{
Size=UDim2.new(1,0,0,42),
Parent=ag,
BackgroundTransparency=1,
},{
ac("Frame",{
Size=UDim2.new(1,0,1,0),
BackgroundTransparency=1,
},{
ab.NewRoundFrame(an,"Squircle",{
ThemeTag={
ImageColor3="Placeholder",
},
Size=UDim2.new(1,0,1,0),
ImageTransparency=0.85,
}),
not am and ab.NewRoundFrame(an-1,"SquircleGlass",{
ThemeTag={
ImageColor3="Outline",
},
Size=UDim2.new(1,1,1,1),
AnchorPoint=Vector2.new(0.5,0.5),
Position=UDim2.new(0.5,0,0.5,0),
ImageTransparency=0.8,
})or nil,
ab.NewRoundFrame(an,"Squircle",{
Size=UDim2.new(1,0,1,0),
Name="Frame",
ThemeTag={
ImageColor3="LabelBackground",
ImageTransparency="LabelBackgroundTransparency",
},


},{
ac("UIPadding",{
PaddingTop=UDim.new(0,ah~="Textarea"and 0 or 12),
PaddingLeft=UDim.new(0,12),
PaddingRight=UDim.new(0,12),
PaddingBottom=UDim.new(0,ah~="Textarea"and 0 or 12),
}),
ac("UIListLayout",{
FillDirection="Horizontal",
Padding=UDim.new(0,8),
VerticalAlignment=ah~="Textarea"and"Center"or"Top",
HorizontalAlignment="Left",
}),
ao,
aq,
}),
}),
})










if aj then
ab.AddSignal(aq:GetPropertyChangedSignal"Text",function()
if ai then
ab.SafeCallback(ai,aq.Text)
end
end)
else
ab.AddSignal(aq.FocusLost,function()
if ai then
ab.SafeCallback(ai,aq.Text)
end
end)
end

return ar
end

return aa end function a.o()

local aa=a.load'd'
local ab=aa.New
local ac=aa.Tween




local ad={
Holder=nil,

Parent=nil,
}

function ad.Create(ae,af,ag,ah,ai)
local aj={
UICorner=28,
UIPadding=12,

Window=ag,
WindUI=ah,

UIElements={},
}

if ae then
aj.UIPadding=0
end
if ae then
aj.UICorner=26
end

af=af or"Dialog"

if not ae then
aj.UIElements.FullScreen=ab("Frame",{
ZIndex=999,
BackgroundTransparency=1,
BackgroundColor3=Color3.fromHex"#000000",
Size=UDim2.new(1,0,1,0),
Active=false,
Visible=false,
Parent=ad.Parent
or(ag and ag.UIElements and ag.UIElements.Main and ag.UIElements.Main.Main),
},{
ab("UICorner",{
CornerRadius=UDim.new(0,ag.UICorner),
}),
})
end

ab("ImageLabel",{
Image="rbxassetid://8992230677",
ThemeTag={
ImageColor3="WindowShadow",

},
ImageTransparency=1,
Size=UDim2.new(1,100,1,100),
Position=UDim2.new(0,-50,0,-50),
ScaleType="Slice",
SliceCenter=Rect.new(99,99,99,99),
BackgroundTransparency=1,
ZIndex=-999999999999999,
Name="Blur",
})

aj.UIElements.Main=ab("Frame",{
Size=UDim2.new(0,280,0,0),
ThemeTag={
BackgroundColor3=af.."Background",
},
AutomaticSize="Y",
BackgroundTransparency=1,
Visible=false,
ZIndex=99999,
},{
ab("UIPadding",{
PaddingTop=UDim.new(0,aj.UIPadding),
PaddingLeft=UDim.new(0,aj.UIPadding),
PaddingRight=UDim.new(0,aj.UIPadding),
PaddingBottom=UDim.new(0,aj.UIPadding),
}),
})

aj.UIElements.MainContainer=aa.NewRoundFrame(aj.UICorner,"Squircle",{
Visible=false,

ImageTransparency=ae and 0.15 or 0,
Parent=ai or aj.UIElements.FullScreen,
Position=UDim2.new(0.5,0,0.5,0),
AnchorPoint=Vector2.new(0.5,0.5),
AutomaticSize="XY",
ThemeTag={
ImageColor3=af.."Background",
ImageTransparency=af.."BackgroundTransparency",
},
ZIndex=9999,
},{






aj.UIElements.Main,




















})

function aj.Open(ak)
if not ae then
aj.UIElements.FullScreen.Visible=true
aj.UIElements.FullScreen.Active=true
end

task.spawn(function()
aj.UIElements.MainContainer.Visible=true

if not ae then
ac(aj.UIElements.FullScreen,0.1,{BackgroundTransparency=0.65}):Play()
end
ac(aj.UIElements.MainContainer,0.1,{ImageTransparency=0}):Play()


task.spawn(function()
task.wait(0.05)
aj.UIElements.Main.Visible=true
end)
end)
end
function aj.Close(ak)
if not ae then
ac(aj.UIElements.FullScreen,0.1,{BackgroundTransparency=1}):Play()
aj.UIElements.FullScreen.Active=false
task.spawn(function()
task.wait(0.1)
aj.UIElements.FullScreen.Visible=false
end)
end
aj.UIElements.Main.Visible=false

ac(aj.UIElements.MainContainer,0.1,{ImageTransparency=1}):Play()



task.spawn(function()
task.wait(0.1)
if not ae then
aj.UIElements.FullScreen:Destroy()
else
aj.UIElements.MainContainer:Destroy()
end
end)

return function()end
end


return aj
end

return ad end function a.p()

local aa={}

local ab=a.load'd'
local ac=ab.New
local ad=ab.Tween

local ae=a.load'm'.New
local af=a.load'n'.New

function aa.new(ag,ah,ai,aj)
local ak=a.load'o'
local al=ak.Create(true,"Popup",ag.Window,ag.WindUI,ag.WindUI.ScreenGui.KeySystem)

local am={}

local an

local ao=(ag.KeySystem.Thumbnail and ag.KeySystem.Thumbnail.Width)or 200

local ap=430
if ag.KeySystem.Thumbnail and ag.KeySystem.Thumbnail.Image then
ap=430+(ao/2)
end

al.UIElements.Main.AutomaticSize="Y"
al.UIElements.Main.Size=UDim2.new(0,ap,0,0)

local aq

if ag.Icon then
aq=
ab.Image(ag.Icon,ag.Title..":"..ag.Icon,0,"Temp","KeySystem",ag.IconThemed)
aq.Size=UDim2.new(0,24,0,24)
aq.LayoutOrder=-1
end

local ar=ac("TextLabel",{
AutomaticSize="XY",
BackgroundTransparency=1,
Text=ag.KeySystem.Title or ag.Title,
FontFace=Font.new(ab.Font,Enum.FontWeight.SemiBold),
ThemeTag={
TextColor3="Text",
},
TextSize=20,
})

local as=ac("TextLabel",{
AutomaticSize="XY",
BackgroundTransparency=1,
Text="Key System",
AnchorPoint=Vector2.new(1,0.5),
Position=UDim2.new(1,0,0.5,0),
TextTransparency=1,
FontFace=Font.new(ab.Font,Enum.FontWeight.Medium),
ThemeTag={
TextColor3="Text",
},
TextSize=16,
})

local at=ac("Frame",{
BackgroundTransparency=1,
AutomaticSize="XY",
},{
ac("UIListLayout",{
Padding=UDim.new(0,14),
FillDirection="Horizontal",
VerticalAlignment="Center",
}),
aq,
ar,
})

local au=ac("Frame",{
AutomaticSize="Y",
Size=UDim2.new(1,0,0,0),
BackgroundTransparency=1,
},{





at,
as,
})

local av=af("Enter Key","key",nil,"Input",function(av)
an=av
end)

local aw
if ag.KeySystem.Note and ag.KeySystem.Note~=""then
aw=ac("TextLabel",{
Size=UDim2.new(1,0,0,0),
AutomaticSize="Y",
FontFace=Font.new(ab.Font,Enum.FontWeight.Medium),
TextXAlignment="Left",
Text=ag.KeySystem.Note,
TextSize=18,
TextTransparency=0.4,
ThemeTag={
TextColor3="Text",
},
BackgroundTransparency=1,
RichText=true,
TextWrapped=true,
})
end

local ax=ac("Frame",{
Size=UDim2.new(1,0,0,42),
BackgroundTransparency=1,
},{
ac("Frame",{
BackgroundTransparency=1,
AutomaticSize="X",
Size=UDim2.new(0,0,1,0),
},{
ac("UIListLayout",{
Padding=UDim.new(0,9),
FillDirection="Horizontal",
}),
}),
})

local ay
if ag.KeySystem.Thumbnail and ag.KeySystem.Thumbnail.Image then
local az
if ag.KeySystem.Thumbnail.Title then
az=ac("TextLabel",{
Text=ag.KeySystem.Thumbnail.Title,
ThemeTag={
TextColor3="Text",
},
TextSize=18,
FontFace=Font.new(ab.Font,Enum.FontWeight.Medium),
BackgroundTransparency=1,
AutomaticSize="XY",
AnchorPoint=Vector2.new(0.5,0.5),
Position=UDim2.new(0.5,0,0.5,0),
})
end
ay=ac("ImageLabel",{
Image=ag.KeySystem.Thumbnail.Image,
BackgroundTransparency=1,
Size=UDim2.new(0,ao,1,-12),
Position=UDim2.new(0,6,0,6),
Parent=al.UIElements.Main,
ScaleType="Crop",
},{
az,
ac("UICorner",{
CornerRadius=UDim.new(0,20),
}),
})
end

ac("Frame",{

Size=UDim2.new(1,ay and-ao or 0,1,0),
Position=UDim2.new(0,ay and ao or 0,0,0),
BackgroundTransparency=1,
Parent=al.UIElements.Main,
},{
ac("Frame",{

Size=UDim2.new(1,0,1,0),
BackgroundTransparency=1,
},{
ac("UIListLayout",{
Padding=UDim.new(0,18),
FillDirection="Vertical",
}),
au,
aw,
av,
ax,
ac("UIPadding",{
PaddingTop=UDim.new(0,16),
PaddingLeft=UDim.new(0,16),
PaddingRight=UDim.new(0,16),
PaddingBottom=UDim.new(0,16),
}),
}),
})





local az=ae("Exit","log-out",function()
al:Close()()
end,"Tertiary",ax.Frame)

if ay then
az.Parent=ay
az.Size=UDim2.new(0,0,0,42)
az.Position=UDim2.new(0,10,1,-10)
az.AnchorPoint=Vector2.new(0,1)
end

if ag.KeySystem.URL then
ae("Get key","key",function()
setclipboard(ag.KeySystem.URL)
end,"Secondary",ax.Frame)
end

if ag.KeySystem.API then








local aA=240
local aB=false
local b=ae("Get key","key",nil,"Secondary",ax.Frame)

local d=ab.NewRoundFrame(99,"Squircle",{
Size=UDim2.new(0,1,1,0),
ThemeTag={
ImageColor3="Text",
},
ImageTransparency=0.9,
})

ac("Frame",{
BackgroundTransparency=1,
Size=UDim2.new(0,0,1,0),
AutomaticSize="X",
Parent=b.Frame,
},{
d,
ac("UIPadding",{
PaddingLeft=UDim.new(0,5),
PaddingRight=UDim.new(0,5),
}),
})

local f=ab.Image("chevron-down","chevron-down",0,"Temp","KeySystem",true)

f.Size=UDim2.new(1,0,1,0)

ac("Frame",{
Size=UDim2.new(0,21,0,21),
Parent=b.Frame,
BackgroundTransparency=1,
},{
f,
})

local g=ab.NewRoundFrame(15,"Squircle",{
Size=UDim2.new(1,0,0,0),
AutomaticSize="Y",
ThemeTag={
ImageColor3="Background",
},
},{
ac("UIPadding",{
PaddingTop=UDim.new(0,5),
PaddingLeft=UDim.new(0,5),
PaddingRight=UDim.new(0,5),
PaddingBottom=UDim.new(0,5),
}),
ac("UIListLayout",{
FillDirection="Vertical",
Padding=UDim.new(0,5),
}),
})

local h=ac("Frame",{
BackgroundTransparency=1,
Size=UDim2.new(0,aA,0,0),
ClipsDescendants=true,
AnchorPoint=Vector2.new(1,0),
Parent=b,
Position=UDim2.new(1,0,1,15),
},{
g,
})

ac("TextLabel",{
Text="Select Service",
BackgroundTransparency=1,
FontFace=Font.new(ab.Font,Enum.FontWeight.Medium),
ThemeTag={TextColor3="Text"},
TextTransparency=0.2,
TextSize=16,
Size=UDim2.new(1,0,0,0),
AutomaticSize="Y",
TextWrapped=true,
TextXAlignment="Left",
Parent=g,
},{
ac("UIPadding",{
PaddingTop=UDim.new(0,10),
PaddingLeft=UDim.new(0,10),
PaddingRight=UDim.new(0,10),
PaddingBottom=UDim.new(0,10),
}),
})

for i,l in next,ag.KeySystem.API do
local m=ag.WindUI.Services[l.Type]
if m then
local p={}
for r,u in next,m.Args do
table.insert(p,l[u])
end

local r=m.New(table.unpack(p))
r.Type=l.Type
table.insert(am,r)

local u=ab.Image(
l.Icon or m.Icon or Icons[l.Type]or"user",
l.Icon or m.Icon or Icons[l.Type]or"user",
0,
"Temp",
"KeySystem",
true
)
u.Size=UDim2.new(0,24,0,24)

local v=ab.NewRoundFrame(10,"Squircle",{
Size=UDim2.new(1,0,0,0),
ThemeTag={ImageColor3="Text"},
ImageTransparency=1,
Parent=g,
AutomaticSize="Y",
},{
ac("UIListLayout",{
FillDirection="Horizontal",
Padding=UDim.new(0,10),
VerticalAlignment="Center",
}),
u,
ac("UIPadding",{
PaddingTop=UDim.new(0,10),
PaddingLeft=UDim.new(0,10),
PaddingRight=UDim.new(0,10),
PaddingBottom=UDim.new(0,10),
}),
ac("Frame",{
BackgroundTransparency=1,
Size=UDim2.new(1,-34,0,0),
AutomaticSize="Y",
},{
ac("UIListLayout",{
FillDirection="Vertical",
Padding=UDim.new(0,5),
HorizontalAlignment="Center",
}),
ac("TextLabel",{
Text=l.Title or m.Name,
BackgroundTransparency=1,
FontFace=Font.new(ab.Font,Enum.FontWeight.Medium),
ThemeTag={TextColor3="Text"},
TextTransparency=0.05,
TextSize=18,
Size=UDim2.new(1,0,0,0),
AutomaticSize="Y",
TextWrapped=true,
TextXAlignment="Left",
}),
ac("TextLabel",{
Text=l.Desc or"",
BackgroundTransparency=1,
FontFace=Font.new(ab.Font,Enum.FontWeight.Regular),
ThemeTag={TextColor3="Text"},
TextTransparency=0.2,
TextSize=16,
Size=UDim2.new(1,0,0,0),
AutomaticSize="Y",
TextWrapped=true,
Visible=l.Desc and true or false,
TextXAlignment="Left",
}),
}),
},true)

ab.AddSignal(v.MouseEnter,function()
ad(v,0.08,{ImageTransparency=0.95}):Play()
end)
ab.AddSignal(v.InputEnded,function()
ad(v,0.08,{ImageTransparency=1}):Play()
end)
ab.AddSignal(v.MouseButton1Click,function()
r.Copy()
ag.WindUI:Notify{
Title="Key System",
Content="Key link copied to clipboard.",
Image="key",
}
end)
end
end

ab.AddSignal(b.MouseButton1Click,function()
if not aB then
ad(
h,
0.3,
{Size=UDim2.new(0,aA,0,g.AbsoluteSize.Y+1)},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()
ad(f,0.3,{Rotation=180},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
else
ad(
h,
0.25,
{Size=UDim2.new(0,aA,0,0)},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()
ad(f,0.25,{Rotation=0},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
end
aB=not aB
end)
end

local function handleSuccess(aA)
al:Close()()
writefile((ag.Folder or"Temp").."/"..ah..".key",tostring(aA))
task.wait(0.4)
ai(true)
end

local aA=ae("Submit","arrow-right",function()
local aA=tostring(an or"empty")local aB=
ag.Folder or ag.Title

if ag.KeySystem.KeyValidator then
local b=ag.KeySystem.KeyValidator(aA)

if b then
if ag.KeySystem.SaveKey then
handleSuccess(aA)
else
al:Close()()
task.wait(0.4)
ai(true)
end
else
ag.WindUI:Notify{
Title="Key System. Error",
Content="Invalid key.",
Icon="triangle-alert",
}
end
elseif not ag.KeySystem.API then
local b=type(ag.KeySystem.Key)=="table"and table.find(ag.KeySystem.Key,aA)
or ag.KeySystem.Key==aA

if b then
if ag.KeySystem.SaveKey then
handleSuccess(aA)
else
al:Close()()
task.wait(0.4)
ai(true)
end
end
else
local b,d
for f,g in next,am do
local h,i=g.Verify(aA)
if h then
b,d=true,i
break
end
d=i
end

if b then
handleSuccess(aA)
else
ag.WindUI:Notify{
Title="Key System. Error",
Content=d,
Icon="triangle-alert",
}
end
end
end,"Primary",ax)

aA.AnchorPoint=Vector2.new(1,0.5)
aA.Position=UDim2.new(1,0,0.5,0)










al:Open()
end

return aa end function a.q()




local aa=(cloneref or clonereference or function(aa)return aa end)


local function map(ab,ac,ad,ae,af)
return(ab-ac)*(af-ae)/(ad-ac)+ae
end

local function viewportPointToWorld(ab,ac)
local ad=aa(game:GetService"Workspace").CurrentCamera:ScreenPointToRay(ab.X,ab.Y)
return ad.Origin+ad.Direction*ac
end

local function getOffset()
local ab=aa(game:GetService"Workspace").CurrentCamera.ViewportSize.Y
return map(ab,0,2560,8,56)
end

return{viewportPointToWorld,getOffset}end function a.r()



local aa=(cloneref or clonereference or function(aa)return aa end)


local ab=a.load'd'
local ac=ab.New


local ad,ae=unpack(a.load'q')
local af=Instance.new("Folder",aa(game:GetService"Workspace").CurrentCamera)


local function createAcrylic()
local ag=ac("Part",{
Name="Body",
Color=Color3.new(0,0,0),
Material=Enum.Material.Glass,
Size=Vector3.new(1,1,0),
Anchored=true,
CanCollide=false,
Locked=true,
CastShadow=false,
Transparency=0.98,
},{
ac("SpecialMesh",{
MeshType=Enum.MeshType.Brick,
Offset=Vector3.new(0,0,-1E-6),
}),
})

return ag
end


local function createAcrylicBlur(ag)
local ah={}

ag=ag or 0.001
local ai={
topLeft=Vector2.new(),
topRight=Vector2.new(),
bottomRight=Vector2.new(),
}
local aj=createAcrylic()
aj.Parent=af

local function updatePositions(ak,al)
ai.topLeft=al
ai.topRight=al+Vector2.new(ak.X,0)
ai.bottomRight=al+ak
end

local function render()
local ak=aa(game:GetService"Workspace").CurrentCamera
if ak then
ak=ak.CFrame
end
local al=ak
if not al then
al=CFrame.new()
end

local am=al
local an=ai.topLeft
local ao=ai.topRight
local ap=ai.bottomRight

local aq=ad(an,ag)
local ar=ad(ao,ag)
local as=ad(ap,ag)

local at=(ar-aq).Magnitude
local au=(ar-as).Magnitude

aj.CFrame=
CFrame.fromMatrix((aq+as)/2,am.XVector,am.YVector,am.ZVector)
aj.Mesh.Scale=Vector3.new(at,au,0)
end

local function onChange(ak)
local al=ae()
local am=ak.AbsoluteSize-Vector2.new(al,al)
local an=ak.AbsolutePosition+Vector2.new(al/2,al/2)

updatePositions(am,an)
task.spawn(render)
end

local function renderOnChange()
local ak=aa(game:GetService"Workspace").CurrentCamera
if not ak then
return
end

table.insert(ah,ak:GetPropertyChangedSignal"CFrame":Connect(render))
table.insert(ah,ak:GetPropertyChangedSignal"ViewportSize":Connect(render))
table.insert(ah,ak:GetPropertyChangedSignal"FieldOfView":Connect(render))
task.spawn(render)
end

aj.Destroying:Connect(function()
for ak,al in ah do
pcall(function()
al:Disconnect()
end)
end
end)

renderOnChange()

return onChange,aj
end

return function(ag)
local ah={}
local ai,aj=createAcrylicBlur(ag)

local ak=ac("Frame",{
BackgroundTransparency=1,
Size=UDim2.fromScale(1,1),
})

ab.AddSignal(ak:GetPropertyChangedSignal"AbsolutePosition",function()
ai(ak)
end)

ab.AddSignal(ak:GetPropertyChangedSignal"AbsoluteSize",function()
ai(ak)
end)

ah.AddParent=function(al)
ab.AddSignal(al:GetPropertyChangedSignal"Visible",function()

end)
end

ah.SetVisibility=function(al)
aj.Transparency=al and 0.98 or 1
end

ah.Frame=ak
ah.Model=aj

return ah
end end function a.s()


local aa=a.load'd'
local ab=a.load'r'

local ac=aa.New

return function(ad)
local ae={}

ae.Frame=ac("Frame",{
Size=UDim2.fromScale(1,1),
BackgroundTransparency=1,
BackgroundColor3=Color3.fromRGB(255,255,255),
BorderSizePixel=0,
},{












ac("UICorner",{
CornerRadius=UDim.new(0,8),
}),

ac("Frame",{
BackgroundTransparency=1,
Size=UDim2.fromScale(1,1),
Name="Background",
ThemeTag={
BackgroundColor3="AcrylicMain",
},
},{
ac("UICorner",{
CornerRadius=UDim.new(0,8),
}),
}),

ac("Frame",{
BackgroundColor3=Color3.fromRGB(255,255,255),
BackgroundTransparency=1,
Size=UDim2.fromScale(1,1),
},{










}),

ac("ImageLabel",{
Image="rbxassetid://9968344105",
ImageTransparency=0.98,
ScaleType=Enum.ScaleType.Tile,
TileSize=UDim2.new(0,128,0,128),
Size=UDim2.fromScale(1,1),
BackgroundTransparency=1,
},{
ac("UICorner",{
CornerRadius=UDim.new(0,8),
}),
}),

ac("ImageLabel",{
Image="rbxassetid://9968344227",
ImageTransparency=0.9,
ScaleType=Enum.ScaleType.Tile,
TileSize=UDim2.new(0,128,0,128),
Size=UDim2.fromScale(1,1),
BackgroundTransparency=1,
ThemeTag={
ImageTransparency="AcrylicNoise",
},
},{
ac("UICorner",{
CornerRadius=UDim.new(0,8),
}),
}),

ac("Frame",{
BackgroundTransparency=1,
Size=UDim2.fromScale(1,1),
ZIndex=2,
},{










}),
})


local af

task.wait()
if ad.UseAcrylic then
af=ab()

af.Frame.Parent=ae.Frame
ae.Model=af.Model
ae.AddParent=af.AddParent
ae.SetVisibility=af.SetVisibility
end

return ae,af
end end function a.t()



local aa=(cloneref or clonereference or function(aa)return aa end)


local ab={
AcrylicBlur=a.load'r',

AcrylicPaint=a.load's',
}

function ab.init()
local ac=Instance.new"DepthOfFieldEffect"
ac.FarIntensity=0
ac.InFocusRadius=0.1
ac.NearIntensity=1

local ad={}

function ab.Enable()
for ae,af in pairs(ad)do
af.Enabled=false
end
ac.Parent=aa(game:GetService"Lighting")
end

function ab.Disable()
for ae,af in pairs(ad)do
af.Enabled=af.enabled
end
ac.Parent=nil
end

local function registerDefaults()
local function register(ae)
if ae:IsA"DepthOfFieldEffect"then
ad[ae]={enabled=ae.Enabled}
end
end

for ae,af in pairs(aa(game:GetService"Lighting"):GetChildren())do
register(af)
end

if aa(game:GetService"Workspace").CurrentCamera then
for ae,af in pairs(aa(game:GetService"Workspace").CurrentCamera:GetChildren())do
register(af)
end
end
end

registerDefaults()
ab.Enable()
end

return ab end function a.u()

local aa={}

local ab=a.load'd'
local ac=ab.New local ad=
ab.Tween


function aa.new(ae,af)
local ag={
Title=ae.Title or"Dialog",
Content=ae.Content,
Icon=ae.Icon,
IconThemed=ae.IconThemed,
Thumbnail=ae.Thumbnail,
Buttons=ae.Buttons,

IconSize=22,
}

local ah=a.load'o'
local ai=ah.Create(true,"Popup",ae.WindUI.Window,ae.WindUI,af)

local aj=200

local ak=430
if ag.Thumbnail and ag.Thumbnail.Image then
ak=430+(aj/2)
end

ai.UIElements.Main.AutomaticSize="Y"
ai.UIElements.Main.Size=UDim2.new(0,ak,0,0)



local al

if ag.Icon then
al=ab.Image(
ag.Icon,
ag.Title..":"..ag.Icon,
0,
ae.WindUI.Window,
"Popup",
true,
ae.IconThemed,
"PopupIcon"
)
al.Size=UDim2.new(0,ag.IconSize,0,ag.IconSize)
al.LayoutOrder=-1
end


local am=ac("TextLabel",{
AutomaticSize="Y",
BackgroundTransparency=1,
Text=ag.Title,
TextXAlignment="Left",
FontFace=Font.new(ab.Font,Enum.FontWeight.SemiBold),
ThemeTag={
TextColor3="PopupTitle",
},
TextSize=20,
TextWrapped=true,
Size=UDim2.new(1,al and-ag.IconSize-14 or 0,0,0)
})

local an=ac("Frame",{
BackgroundTransparency=1,
AutomaticSize="XY",
},{
ac("UIListLayout",{
Padding=UDim.new(0,14),
FillDirection="Horizontal",
VerticalAlignment="Center"
}),
al,am
})

local ao=ac("Frame",{
AutomaticSize="Y",
Size=UDim2.new(1,0,0,0),
BackgroundTransparency=1,
},{





an,
})

local ap
if ag.Content and ag.Content~=""then
ap=ac("TextLabel",{
Size=UDim2.new(1,0,0,0),
AutomaticSize="Y",
FontFace=Font.new(ab.Font,Enum.FontWeight.Medium),
TextXAlignment="Left",
Text=ag.Content,
TextSize=18,
TextTransparency=.2,
ThemeTag={
TextColor3="PopupContent",
},
BackgroundTransparency=1,
RichText=true,
TextWrapped=true,
})
end

local aq=ac("Frame",{
Size=UDim2.new(1,0,0,42),
BackgroundTransparency=1,
},{
ac("UIListLayout",{
Padding=UDim.new(0,9),
FillDirection="Horizontal",
HorizontalAlignment="Right"
})
})

local ar
if ag.Thumbnail and ag.Thumbnail.Image then
local as
if ag.Thumbnail.Title then
as=ac("TextLabel",{
Text=ag.Thumbnail.Title,
ThemeTag={
TextColor3="Text",
},
TextSize=18,
FontFace=Font.new(ab.Font,Enum.FontWeight.Medium),
BackgroundTransparency=1,
AutomaticSize="XY",
AnchorPoint=Vector2.new(0.5,0.5),
Position=UDim2.new(0.5,0,0.5,0),
})
end
ar=ac("ImageLabel",{
Image=ag.Thumbnail.Image,
BackgroundTransparency=1,
Size=UDim2.new(0,aj,1,0),
Parent=ai.UIElements.Main,
ScaleType="Crop"
},{
as,
ac("UICorner",{
CornerRadius=UDim.new(0,0),
})
})
end

ac("Frame",{

Size=UDim2.new(1,ar and-aj or 0,1,0),
Position=UDim2.new(0,ar and aj or 0,0,0),
BackgroundTransparency=1,
Parent=ai.UIElements.Main
},{
ac("Frame",{

Size=UDim2.new(1,0,1,0),
BackgroundTransparency=1,
},{
ac("UIListLayout",{
Padding=UDim.new(0,18),
FillDirection="Vertical",
}),
ao,
ap,
aq,
ac("UIPadding",{
PaddingTop=UDim.new(0,16),
PaddingLeft=UDim.new(0,16),
PaddingRight=UDim.new(0,16),
PaddingBottom=UDim.new(0,16),
})
}),
})

local as=a.load'm'.New

for at,au in next,ag.Buttons do
as(au.Title,au.Icon,au.Callback,au.Variant,aq,ai)
end

ai:Open()


return ag
end

return aa end function a.v()
return function(aa,ab)
return{
Dark={
Name="Dark",

Accent=Color3.fromHex"#18181b",
Dialog=Color3.fromHex"#1a1a1a",
Outline=Color3.fromHex"#FFFFFF",
Text=Color3.fromHex"#FFFFFF",
Placeholder=Color3.fromHex"#a1a1a1",
Background=Color3.fromHex"#101010",
Button=Color3.fromHex"#52525b",
Icon=Color3.fromHex"#a1a1aa",
Toggle=Color3.fromHex"#33C759",
Slider=Color3.fromHex"#0091FF",
Checkbox=Color3.fromHex"#0091FF",

PanelBackground=Color3.fromHex"#FFFFFF",
PanelBackgroundTransparency=0.95,

SliderIcon=Color3.fromHex"#908F95",
Primary=Color3.fromHex"#0091FF",


LabelBackground=Color3.fromHex"#000000",
LabelBackgroundTransparency=0.83,

ElementBackground=Color3.fromHex"#2A2A2C",
ElementBackgroundTransparency=0,
},

Light={
Name="Light",

Accent=Color3.fromHex"#efefef",
Dialog=Color3.fromHex"#f4f4f5",
Outline=Color3.fromHex"#ffffff",
Text=Color3.fromHex"#000000",
Placeholder=Color3.fromHex"#555555",
Background=Color3.fromHex"#FFFFFF",
Button=Color3.fromHex"#18181b",
Icon=Color3.fromHex"#52525b",
Toggle=Color3.fromHex"#33C759",
Slider=Color3.fromHex"#0091FF",
Checkbox=Color3.fromHex"#0091FF",

DropdownTabBackground=Color3.fromHex"#bebebe",
DropdownBackground=Color3.fromHex"#ffffff",

TabBackground=Color3.fromHex"#ffffff",
TabBackgroundHover=Color3.fromHex"#f3f3f3",
TabBackgroundHoverTransparency=0,
TabBackgroundActive=Color3.fromHex"#efefef",
TabBackgroundActiveTransparency=0,

PanelBackground=Color3.fromHex"#efefef",
PanelBackgroundTransparency=0,

LabelBackground=Color3.fromHex"#efefef",
LabelBackgroundTransparency=0,

ElementBackground=Color3.fromHex"#ffffff",
ElementBackgroundTransparency=0,
},

Rose={
Name="Rose",

Accent=Color3.fromHex"#be185d",
Dialog=Color3.fromHex"#4c0519",

Text=Color3.fromHex"#fdf2f8",
Placeholder=Color3.fromHex"#d67aa6",
Background=Color3.fromHex"#1f0308",
Button=Color3.fromHex"#e95f74",
Icon=Color3.fromHex"#fb7185",

ElementBackground=Color3.fromHex"#381E23",
ElementBackgroundTransparency=0,
},

Plant={
Name="Plant",

Accent=Color3.fromHex"#166534",
Dialog=Color3.fromHex"#052e16",

Text=Color3.fromHex"#f0fdf4",
Placeholder=Color3.fromHex"#4fbf7a",
Background=Color3.fromHex"#0a1b0f",
Button=Color3.fromHex"#16a34a",
Icon=Color3.fromHex"#4ade80",

ElementBackground=Color3.fromHex"#28342A",
ElementBackgroundTransparency=0,
},

Red={
Name="Red",

Accent=Color3.fromHex"#991b1b",
Dialog=Color3.fromHex"#450a0a",

Text=Color3.fromHex"#fef2f2",
Placeholder=Color3.fromHex"#d95353",
Background=Color3.fromHex"#1c0606",
Button=Color3.fromHex"#dc2626",
Icon=Color3.fromHex"#ef4444",

ElementBackground=Color3.fromHex"#322221",
ElementBackgroundTransparency=0,
},

Indigo={
Name="Indigo",

Accent=Color3.fromHex"#3730a3",
Dialog=Color3.fromHex"#1e1b4b",

Text=Color3.fromHex"#f1f5f9",
Placeholder=Color3.fromHex"#7078d9",
Background=Color3.fromHex"#0f0a2e",
Button=Color3.fromHex"#4f46e5",
Icon=Color3.fromHex"#6366f1",

ElementBackground=Color3.fromHex"#282543",
ElementBackgroundTransparency=0,
},

Sky={
Name="Sky",

Accent=Color3.fromHex"#00d4ff",
Dialog=Color3.fromHex"#0a4d66",

Text=Color3.fromHex"#e6f7ff",
Placeholder=Color3.fromHex"#66b3cc",
Background=Color3.fromHex"#051a26",
Button=Color3.fromHex"#00a8cc",
Icon=Color3.fromHex"#2db8d9",

Toggle=Color3.fromHex"#00d9d9",
Slider=Color3.fromHex"#00d4ff",
Checkbox=Color3.fromHex"#00d4ff",

PanelBackground=Color3.fromHex"#0d3a47",
PanelBackgroundTransparency=0.8,

ElementBackground=Color3.fromHex"#172E3B",
ElementBackgroundTransparency=0,
},

Violet={
Name="Violet",

Accent=Color3.fromHex"#6d28d9",
Dialog=Color3.fromHex"#3c1361",

Text=Color3.fromHex"#faf5ff",
Placeholder=Color3.fromHex"#8f7ee0",
Background=Color3.fromHex"#1e0a3e",
Button=Color3.fromHex"#7c3aed",
Icon=Color3.fromHex"#8b5cf6",

ElementBackground=Color3.fromHex"#342650",
ElementBackgroundTransparency=0,
},

Amber={
Name="Amber",

Accent=aa:Gradient({
["0"]={Color=Color3.fromHex"#b45309",Transparency=0},
["100"]={Color=Color3.fromHex"#d97706",Transparency=0},
},{Rotation=45}),

Dialog=aa:Gradient({
["0"]={Color=Color3.fromHex"#451a03",Transparency=0},
["100"]={Color=Color3.fromHex"#6b2e05",Transparency=0},
},{Rotation=90}),






Text=aa:Gradient({
["0"]={Color=Color3.fromHex"#fffbeb",Transparency=0},
["100"]={Color=Color3.fromHex"#fff7ed",Transparency=0},
},{Rotation=45}),

Placeholder=aa:Gradient({
["0"]={Color=Color3.fromHex"#d1a326",Transparency=0},
["100"]={Color=Color3.fromHex"#fbbf24",Transparency=0},
},{Rotation=45}),

Background=aa:Gradient({
["0"]={Color=Color3.fromHex"#1c1003",Transparency=0},
["100"]={Color=Color3.fromHex"#3f210d",Transparency=0},
},{Rotation=90}),

Button=aa:Gradient({
["0"]={Color=Color3.fromHex"#d97706",Transparency=0},
["100"]={Color=Color3.fromHex"#f59e0b",Transparency=0},
},{Rotation=45}),

Icon=Color3.fromHex"#f59e0b",

Toggle=aa:Gradient({
["0"]={Color=Color3.fromHex"#d97706",Transparency=0},
["100"]={Color=Color3.fromHex"#f59e0b",Transparency=0},
},{Rotation=45}),

Slider=Color3.fromHex"#d97706",

Checkbox=aa:Gradient({
["0"]={Color=Color3.fromHex"#d97706",Transparency=0},
["100"]={Color=Color3.fromHex"#fbbf24",Transparency=0},
},{Rotation=45}),

PanelBackground=Color3.fromHex"#FFFFFF",
PanelBackgroundTransparency=0.95,

ElementBackground=Color3.fromHex"#3A2E22",
ElementBackgroundTransparency=0,
},

Emerald={
Name="Emerald",

Accent=Color3.fromHex"#047857",
Dialog=Color3.fromHex"#022c22",

Text=Color3.fromHex"#ecfdf5",
Placeholder=Color3.fromHex"#3fbf8f",
Background=Color3.fromHex"#011411",
Button=Color3.fromHex"#059669",
Icon=Color3.fromHex"#10b981",

ElementBackground=Color3.fromHex"#202E2A",
ElementBackgroundTransparency=0,
},

Midnight={
Name="Midnight",

Accent=Color3.fromHex"#1e3a8a",
Dialog=Color3.fromHex"#0c1e42",

Text=Color3.fromHex"#dbeafe",
Placeholder=Color3.fromHex"#2f74d1",
Background=Color3.fromHex"#0a0f1e",
Button=Color3.fromHex"#2563eb",
Primary=Color3.fromHex"#2563eb",
Icon=Color3.fromHex"#5591f4",

ElementBackground=Color3.fromHex"#242836",
ElementBackgroundTransparency=0,
},

Crimson={
Name="Crimson",

Accent=Color3.fromHex"#b91c1c",
Dialog=Color3.fromHex"#450a0a",

Text=Color3.fromHex"#fef2f2",
Placeholder=Color3.fromHex"#6f757b",
Background=Color3.fromHex"#0c0404",
Button=Color3.fromHex"#991b1b",
Icon=Color3.fromHex"#dc2626",

ElementBackground=Color3.fromHex"#251F1F",
ElementBackgroundTransparency=0,
},

MonokaiPro={
Name="Monokai Pro",

Accent=Color3.fromHex"#fc9867",
Dialog=Color3.fromHex"#1e1e1e",

Text=Color3.fromHex"#fcfcfa",
Placeholder=Color3.fromHex"#afafaf",
Background=Color3.fromHex"#191622",
Button=Color3.fromHex"#ab9df2",
Icon=Color3.fromHex"#a9dc76",

ElementBackground=Color3.fromHex"#323039",
ElementBackgroundTransparency=0,

Metadata={
PullRequest=23,
},
},

CottonCandy={
Name="Cotton Candy",

Accent=Color3.fromHex"#ec4899",
Dialog=Color3.fromHex"#2d1b3d",

Text=Color3.fromHex"#fdf2f8",
Placeholder=Color3.fromHex"#8a5fd3",
Background=Color3.fromHex"#1a0b2e",
Button=Color3.fromHex"#d946ef",
Slider=Color3.fromHex"#d946ef",
Icon=Color3.fromHex"#06b6d4",

ElementBackground=Color3.fromHex"#312643",
ElementBackgroundTransparency=0,
},

Mellowsi={
Name="Mellowsi",

Accent=Color3.fromHex"#342A1E",
Dialog=Color3.fromHex"#291C13",

Text=Color3.fromHex"#F5EBDD",
Placeholder=Color3.fromHex"#9C8A73",
Background=Color3.fromHex"#1C1002",
Button=Color3.fromHex"#342A1E",
Icon=Color3.fromHex"#C9B79C",

Toggle=Color3.fromHex"#a9873f",
Slider=Color3.fromHex"#C9A24D",
Checkbox=Color3.fromHex"#C9A24D",

ElementBackground=Color3.fromHex"#33291E",
ElementBackgroundTransparency=0,

Metadata={
PullRequest=52,
},
},

Rainbow={
Name="Rainbow",

Accent=aa:Gradient({
["0"]={Color=Color3.fromHex"#00ff41",Transparency=0},
["33"]={Color=Color3.fromHex"#00ffff",Transparency=0},
["66"]={Color=Color3.fromHex"#0080ff",Transparency=0},
["100"]={Color=Color3.fromHex"#8000ff",Transparency=0},
},{Rotation=45}),

Dialog=aa:Gradient({
["0"]={Color=Color3.fromHex"#ff0080",Transparency=0},
["25"]={Color=Color3.fromHex"#8000ff",Transparency=0},
["50"]={Color=Color3.fromHex"#0080ff",Transparency=0},
["75"]={Color=Color3.fromHex"#00ff80",Transparency=0},
["100"]={Color=Color3.fromHex"#ff8000",Transparency=0},
},{Rotation=135}),


Text=Color3.fromHex"#ffffff",
Placeholder=Color3.fromHex"#00ff80",

Background=aa:Gradient({
["0"]={Color=Color3.fromHex"#ff0040",Transparency=0},
["20"]={Color=Color3.fromHex"#ff4000",Transparency=0},
["40"]={Color=Color3.fromHex"#ffff00",Transparency=0},
["60"]={Color=Color3.fromHex"#00ff40",Transparency=0},
["80"]={Color=Color3.fromHex"#0040ff",Transparency=0},
["100"]={Color=Color3.fromHex"#4000ff",Transparency=0},
},{Rotation=90}),

Button=aa:Gradient({
["0"]={Color=Color3.fromHex"#ff0080",Transparency=0},
["25"]={Color=Color3.fromHex"#ff8000",Transparency=0},
["50"]={Color=Color3.fromHex"#ffff00",Transparency=0},
["75"]={Color=Color3.fromHex"#80ff00",Transparency=0},
["100"]={Color=Color3.fromHex"#00ffff",Transparency=0},
},{Rotation=60}),

Icon=Color3.fromHex"#ffffff",
},
}
end end function a.w()

local aa={}

local ab=a.load'd'
local ac=ab.New local ad=
ab.Tween

function aa.New(ae,af,ag,ah,ai,aj)
local ak=ai or 10
local al
if af and af~=""then
al=ac("ImageLabel",{
Image=ab.Icon(af)[1],
ImageRectSize=ab.Icon(af)[2].ImageRectSize,
ImageRectOffset=ab.Icon(af)[2].ImageRectPosition,
Size=UDim2.new(0,21,0,21),
BackgroundTransparency=1,
ThemeTag={
ImageColor3="Icon",
},
})
end

local am=ac("TextLabel",{
BackgroundTransparency=1,
TextSize=17,
FontFace=Font.new(ab.Font,Enum.FontWeight.Regular),
Size=UDim2.new(1,al and-29 or 0,1,0),
TextXAlignment="Left",
ThemeTag={
TextColor3=ah and"Placeholder"or"Text",
},
Text=ae,
})

local an=ac("TextButton",{
Size=UDim2.new(1,0,0,42),
Parent=ag,
BackgroundTransparency=1,
Text="",
},{
ac("Frame",{
Size=UDim2.new(1,0,1,0),
BackgroundTransparency=1,
},{
ab.NewRoundFrame(ak,"Squircle",{
ThemeTag={
ImageColor3="Placeholder",
},
Size=UDim2.new(1,0,1,0),
ImageTransparency=0.85,
}),
not aj and ab.NewRoundFrame(ak,"SquircleGlass",{
ThemeTag={
ImageColor3="Outline",
},
Size=UDim2.new(1,1,1,1),
ImageTransparency=0.9,
AnchorPoint=Vector2.new(0.5,0.5),
Position=UDim2.new(0.5,0,0.5,0),
})or nil,
ab.NewRoundFrame(ak,"Squircle",{
Size=UDim2.new(1,0,1,0),
Name="Frame",
ThemeTag={
ImageColor3="LabelBackground",
ImageTransparency="LabelBackgroundTransparency",
},


},{
ac("UIPadding",{
PaddingLeft=UDim.new(0,12),
PaddingRight=UDim.new(0,12),
}),
ac("UIListLayout",{
FillDirection="Horizontal",
Padding=UDim.new(0,8),
VerticalAlignment="Center",
HorizontalAlignment="Left",
}),
al,
am,
}),
}),
})

return an
end

return aa end function a.x()

local aa={}

local ab=cloneref or clonereference or function(ab)
return ab
end
local ac=ab(game:GetService"UserInputService")

local ad=a.load'd'
local ae=ad.New

function aa.New(af,ag,ah,ai,aj)
local ak=ae("Frame",{
Size=UDim2.new(0,ai,1,0),
BackgroundTransparency=1,
Position=UDim2.new(1,0,0,0),
AnchorPoint=Vector2.new(1,0),
Parent=ag,
ZIndex=999,
Active=true,
})

local al=ad.NewRoundFrame(ai/2,"Squircle",{
Size=UDim2.new(1,0,0,0),
ImageTransparency=0.85,
ThemeTag={ImageColor3="Text"},
Parent=ak,
})

local am=ae("Frame",{
Size=UDim2.new(1,12,1,12),
Position=UDim2.new(0.5,0,0.5,0),
AnchorPoint=Vector2.new(0.5,0.5),
BackgroundTransparency=1,
Active=true,
ZIndex=999,
Parent=al,
})

local an=ad:GenerateUniqueID()
local ao=false
local ap,aq

local function UpdateVisuals()
local ar=af.AbsoluteCanvasSize.Y
local as=af.AbsoluteWindowSize.Y

if ar<=as then
al.Visible=false
return
end

al.Visible=true

local at=math.clamp(as/ar,0.05,1)
al.Size=UDim2.new(1,0,at,0)

local au=ar-as
local av=1-at

if au>0 then
local aw=af.CanvasPosition.Y/au
al.Position=UDim2.new(0,0,math.clamp(aw*av,0,av),0)
else
al.Position=UDim2.new(0,0,0,0)
end
end

local function StopDrag()
if aj.CurrentInput==an then
aj.CurrentInput=nil
end
ao=false
af.ScrollingEnabled=true
if ap then
ap:Disconnect()
end
if aq then
aq:Disconnect()
end
end

ad.AddSignal(am.InputBegan,function(ar)
if
ar.UserInputType~=Enum.UserInputType.MouseButton1
and ar.UserInputType~=Enum.UserInputType.Touch
then
return
end
if ao then
return
end
if aj.CurrentInput and aj.CurrentInput~=an then
return
end

aj.CurrentInput=an

ao=true
af.ScrollingEnabled=false

local as=ar.Position.Y
local at=af.CanvasPosition.Y

ap=ac.InputChanged:Connect(function(au)
if
au.UserInputType==Enum.UserInputType.MouseMovement
or au.UserInputType==Enum.UserInputType.Touch
then
local av=au.Position.Y-as

local aw=af.AbsoluteCanvasSize.Y
local ax=af.AbsoluteWindowSize.Y
local ay=math.max(aw-ax,0)

local az=ak.AbsoluteSize.Y
local aA=al.AbsoluteSize.Y
local aB=math.max(az-aA,1)

local b=av*(ay/aB)

af.CanvasPosition=
Vector2.new(af.CanvasPosition.X,math.clamp(at+b,0,ay))
end
end)

aq=ac.InputEnded:Connect(function(au)
if au.UserInputType==ar.UserInputType then
if aj.CurrentInput and aj.CurrentInput~=an then
return
end

aj.CurrentInput=nil

StopDrag()
end
end)
end)

ad.AddSignal(af:GetPropertyChangedSignal"AbsoluteWindowSize",UpdateVisuals)
ad.AddSignal(af:GetPropertyChangedSignal"AbsoluteCanvasSize",UpdateVisuals)
ad.AddSignal(af:GetPropertyChangedSignal"CanvasPosition",UpdateVisuals)

UpdateVisuals()

return ak
end

return aa end function a.y()

local aa={}

local ab=a.load'd'
local ac=ab.New
local ad=ab.Tween

function aa.New(ae,af,ag)
local ah={
Title=af.Title or"Tag",
Icon=af.Icon,
Color=af.Color or Color3.fromHex"#315dff",
Radius=af.Radius or 999,
Border=af.Border or false,

TagFrame=nil,
Height=26,
Padding=10,
TextSize=14,
IconSize=16,
}

local ai
if ah.Icon then
ai=ab.Image(ah.Icon,ah.Icon,0,af.Window,"Tag",false)

ai.Size=UDim2.new(0,ah.IconSize,0,ah.IconSize)
ai.ImageLabel.ImageColor3=typeof(ah.Color)=="Color3"
and ab.GetTextColorForHSB(ah.Color)
or typeof(ah.Color)=="string"
and(ab.GetTextColorForHSB(ab.GetThemeProperty(ah.Color,ab.Theme)))
end

local aj=ac("TextLabel",{
BackgroundTransparency=1,
AutomaticSize="XY",
TextSize=ah.TextSize,
FontFace=Font.new(ab.Font,Enum.FontWeight.SemiBold),
Text=ah.Title,
TextColor3=typeof(ah.Color)=="Color3"and ab.GetTextColorForHSB(ah.Color)or typeof(
ah.Color
)=="string"and(ab.GetTextColorForHSB(ab.GetThemeProperty(ah.Color,ab.Theme))),
})

local ak

if typeof(ah.Color)=="table"then
ak=ac"UIGradient"
for al,am in next,ah.Color do
ak[al]=am
end

aj.TextColor3=ab.GetTextColorForHSB(ab.GetAverageColor(ak))
if ai then
ai.ImageLabel.ImageColor3=ab.GetTextColorForHSB(ab.GetAverageColor(ak))
end
end

local al=ab.NewRoundFrame(ah.Radius,"Squircle",{
AutomaticSize="X",
Size=UDim2.new(0,0,0,ah.Height),
Parent=ag,
ImageColor3=typeof(ah.Color)=="Color3"and ah.Color
or typeof(ah.Color)=="table"and Color3.new(1,1,1)
or nil,
ThemeTag=typeof(ah.Color)=="string"and{
ImageColor3=ah.Color,
},
},{
ak,
ab.NewRoundFrame(ah.Radius+1,"SquircleGlass",{
Size=UDim2.new(1,1,1,1),
AnchorPoint=Vector2.new(0.5,0.5),
Position=UDim2.new(0.5,0,0.5,0),
ThemeTag={
ImageColor3="White",
},
ImageTransparency=0.75,
}),
ac("Frame",{
Size=UDim2.new(0,0,1,0),
AutomaticSize="X",
Name="Content",
BackgroundTransparency=1,
},{
ai,
aj,
ac("UIPadding",{
PaddingLeft=UDim.new(0,ah.Padding),
PaddingRight=UDim.new(0,ah.Padding),
}),
ac("UIListLayout",{
FillDirection="Horizontal",
VerticalAlignment="Center",
Padding=UDim.new(0,ah.Padding/1.5),
}),
}),
})

function ah.SetTitle(am,an)
ah.Title=an
aj.Text=an

return ah
end

function ah.SetColor(am,an)
ah.Color=an
if typeof(an)=="table"then
local ao=ab.GetAverageColor(an)
ad(aj,0.06,{TextColor3=ab.GetTextColorForHSB(ao)}):Play()
local ap=al:FindFirstChildOfClass"UIGradient"or ac("UIGradient",{Parent=al})
for aq,ar in next,an do
ap[aq]=ar
end
ad(al,0.06,{ImageColor3=Color3.new(1,1,1)}):Play()
else
if ak then
ak:Destroy()
end
ad(aj,0.06,{TextColor3=ab.GetTextColorForHSB(an)}):Play()
if ai then
ad(ai.ImageLabel,0.06,{ImageColor3=ab.GetTextColorForHSB(an)}):Play()
end
ad(al,0.06,{ImageColor3=an}):Play()
end

return ah
end

function ah.SetIcon(am,an)
ah.Icon=an

if an then
ai=ab.Image(an,an,0,af.Window,"Tag",false)

ai.Size=UDim2.new(0,ah.IconSize,0,ah.IconSize)
ai.Parent=al

if typeof(ah.Color)=="Color3"then
ai.ImageLabel.ImageColor3=ab.GetTextColorForHSB(ah.Color)
elseif typeof(ah.Color)=="table"then
ai.ImageLabel.ImageColor3=ab.GetTextColorForHSB(ab.GetAverageColor(ak))
end
else
if ai then
ai:Destroy()
ai=nil
end
end
return ah
end

function ah.Destroy(am)
al:Destroy()
return ah
end

ab:OnThemeChange(function(am,an)
aj.TextColor3=ab.GetTextColorForHSB(ab.GetThemeProperty(ah.Color,ab.Theme))
ai.ImageLabel.ImageColor3=
ab.GetTextColorForHSB(ab.GetThemeProperty(ah.Color,ab.Theme))
end)

return ah
end

return aa end function a.z()

local aa=(cloneref or clonereference or function(aa)return aa end)


local ab=aa(game:GetService"RunService")
local ac=aa(game:GetService"HttpService")

local ad

local ae
ae={
Folder=nil,
Path=nil,
Configs={},
Parser={
Colorpicker={
Save=function(af)
return{
__type=af.__type,
value=af.Default:ToHex(),
transparency=af.Transparency or nil,
}
end,
Load=function(af,ag)
if af and af.Update then
af:Update(Color3.fromHex(ag.value),ag.transparency or nil)
end
end
},
Dropdown={
Save=function(af)
return{
__type=af.__type,
value=af.Value,
}
end,
Load=function(af,ag)
if af and af.Select then
af:Select(ag.value)
end
end
},
Input={
Save=function(af)
return{
__type=af.__type,
value=af.Value,
}
end,
Load=function(af,ag)
if af and af.Set then
af:Set(ag.value)
end
end
},
Keybind={
Save=function(af)
return{
__type=af.__type,
value=af.Value,
}
end,
Load=function(af,ag)
if af and af.Set then
af:Set(ag.value)
end
end
},
Slider={
Save=function(af)
return{
__type=af.__type,
value=af.Value.Default,
}
end,
Load=function(af,ag)
if af and af.Set then
af:Set(tonumber(ag.value))
end
end
},
Toggle={
Save=function(af)
return{
__type=af.__type,
value=af.Value,
}
end,
Load=function(af,ag)
if af and af.Set then
af:Set(ag.value)
end
end
},
}
}

function ae.Init(af,ag)
if not ag.Folder then
warn"[ WindUI.ConfigManager ] Window.Folder is not specified."
return false
end
if ab:IsStudio()or not writefile then
warn"[ WindUI.ConfigManager ] The config system doesn't work in the studio."
return false
end

ad=ag
ae.Folder=ad.Folder
ae.Path="WindUI/"..tostring(ae.Folder).."/config/"

if not isfolder(ae.Path)then
makefolder(ae.Path)
end

local ah=ae:AllConfigs()

for ai,aj in next,ah do
if isfile and readfile and isfile(aj..".json")then
ae.Configs[aj]=readfile(aj..".json")
end
end

return ae
end

function ae.SetPath(af,ag)
if not ag then
warn"[ WindUI.ConfigManager ] Custom path is not specified."
return false
end

ae.Path=ag
if not ag:match"/$"then
ae.Path=ag.."/"
end

if not isfolder(ae.Path)then
makefolder(ae.Path)
end

return true
end

function ae.CreateConfig(af,ag,ah)
local ai={
Path=ae.Path..ag..".json",
Elements={},
CustomData={},
AutoLoad=ah or false,
Version=1.2,
}

if not ag then
return false,"No config file is selected"
end

function ai.SetAsCurrent(aj)
ad:SetCurrentConfig(ai)
end

function ai.Register(aj,ak,al)
ai.Elements[ak]=al
end

function ai.Set(aj,ak,al)
ai.CustomData[ak]=al
end

function ai.Get(aj,ak)
return ai.CustomData[ak]
end

function ai.SetAutoLoad(aj,ak)
ai.AutoLoad=ak
end

function ai.Save(aj)
if ad.PendingFlags then
for ak,al in next,ad.PendingFlags do
ai:Register(ak,al)
end
end

local ak={
__version=ai.Version,
__elements={},
__autoload=ai.AutoLoad,
__custom=ai.CustomData
}

for al,am in next,ai.Elements do
if ae.Parser[am.__type]then
ak.__elements[tostring(al)]=ae.Parser[am.__type].Save(am)
end
end

local al=ac:JSONEncode(ak)
if writefile then
writefile(ai.Path,al)
end

return ak
end

function ai.Load(aj)
if isfile and not isfile(ai.Path)then
return false,"Config file does not exist"
end

local ak,al=pcall(function()
local ak=readfile or function()
warn"[ WindUI.ConfigManager ] The config system doesn't work in the studio."
return nil
end
return ac:JSONDecode(ak(ai.Path))
end)

if not ak then
return false,"Failed to parse config file"
end

if not al.__version then
local am={
__version=ai.Version,
__elements=al,
__custom={}
}
al=am
end

if ad.PendingFlags then
for am,an in next,ad.PendingFlags do
ai:Register(am,an)
end
end

for am,an in next,(al.__elements or{})do
if ai.Elements[am]and ae.Parser[an.__type]then
task.spawn(function()
ae.Parser[an.__type].Load(ai.Elements[am],an)
end)
end
end

ai.CustomData=al.__custom or{}

return ai.CustomData
end

function ai.Delete(aj)
if not delfile then
return false,"delfile function is not available"
end

if not isfile(ai.Path)then
return false,"Config file does not exist"
end

local ak,al=pcall(function()
delfile(ai.Path)
end)

if not ak then
return false,"Failed to delete config file: "..tostring(al)
end

ae.Configs[ag]=nil

if ad.CurrentConfig==ai then
ad.CurrentConfig=nil
end

return true,"Config deleted successfully"
end

function ai.GetData(aj)
return{
elements=ai.Elements,
custom=ai.CustomData,
autoload=ai.AutoLoad
}
end


if isfile(ai.Path)then
local aj,ak=pcall(function()
return ac:JSONDecode(readfile(ai.Path))
end)

if aj and ak and ak.__autoload then
ai.AutoLoad=true

task.spawn(function()
task.wait(0.5)
local al,am=pcall(function()
return ai:Load()
end)
if al then
if ad.Debug then print("[ WindUI.ConfigManager ] AutoLoaded config: "..ag)end
else
warn("[ WindUI.ConfigManager ] Failed to AutoLoad config: "..ag.." - "..tostring(am))
end
end)
end
end


ai:SetAsCurrent()
ae.Configs[ag]=ai
return ai
end

function ae.Config(af,ag,ah)
return ae:CreateConfig(ag,ah)
end

function ae.GetAutoLoadConfigs(af)
local ag={}

for ah,ai in pairs(ae.Configs)do
if ai.AutoLoad then
table.insert(ag,ah)
end
end

return ag
end

function ae.DeleteConfig(af,ag)
if not delfile then
return false,"delfile function is not available"
end

local ah=ae.Path..ag..".json"

if not isfile(ah)then
return false,"Config file does not exist"
end

local ai,aj=pcall(function()
delfile(ah)
end)

if not ai then
return false,"Failed to delete config file: "..tostring(aj)
end

ae.Configs[ag]=nil

if ad.CurrentConfig and ad.CurrentConfig.Path==ah then
ad.CurrentConfig=nil
end

return true,"Config deleted successfully"
end

function ae.AllConfigs(af)
if not listfiles then return{}end

local ag={}
if not isfolder(ae.Path)then
makefolder(ae.Path)
return ag
end

for ah,ai in next,listfiles(ae.Path)do
local aj=ai:match"([^\\/]+)%.json$"
if aj then
table.insert(ag,aj)
end
end

return ag
end

function ae.GetConfig(af,ag)
return ae.Configs[ag]
end

return ae end function a.A()
local aa={}

local ab=a.load'd'
local ac=ab.New
local ad=ab.Tween


local ae=(cloneref or clonereference or function(ae)return ae end)


ae(game:GetService"UserInputService")


function aa.New(af)
local ag={
Button=nil
}

local ah













local ai=ac("TextLabel",{
Text=af.Title,
TextSize=17,
FontFace=Font.new(ab.Font,Enum.FontWeight.Medium),
BackgroundTransparency=1,
AutomaticSize="XY",
})

local aj=ac("Frame",{
Size=UDim2.new(0,36,0,36),
BackgroundTransparency=1,
Name="Drag",
},{
ac("ImageLabel",{
Image=ab.Icon"move"[1],
ImageRectOffset=ab.Icon"move"[2].ImageRectPosition,
ImageRectSize=ab.Icon"move"[2].ImageRectSize,
Size=UDim2.new(0,18,0,18),
BackgroundTransparency=1,
Position=UDim2.new(0.5,0,0.5,0),
AnchorPoint=Vector2.new(0.5,0.5),
ThemeTag={
ImageColor3="Icon",
},
ImageTransparency=.3,
})
})
local ak=ac("Frame",{
Size=UDim2.new(0,1,1,0),
Position=UDim2.new(0,36,0.5,0),
AnchorPoint=Vector2.new(0,0.5),
BackgroundColor3=Color3.new(1,1,1),
BackgroundTransparency=.9,
})

local al=ac("Frame",{
Size=UDim2.new(0,0,0,0),
Position=UDim2.new(0.5,0,0,28),
AnchorPoint=Vector2.new(0.5,0.5),
Parent=af.Parent,
BackgroundTransparency=1,
Active=true,
Visible=false,
})


local am=ac("UIScale",{
Scale=1,
})

local an=ac("Frame",{
Size=UDim2.new(0,0,0,44),
AutomaticSize="X",
Parent=al,
Active=false,
BackgroundTransparency=.25,
ZIndex=99,
BackgroundColor3=Color3.new(0,0,0),
},{
am,
ac("UICorner",{
CornerRadius=UDim.new(1,0)
}),
ac("UIStroke",{
Thickness=1,
ApplyStrokeMode="Border",
Color=Color3.new(1,1,1),
Transparency=0,
},{
ac("UIGradient",{
Color=ColorSequence.new(Color3.fromHex"40c9ff",Color3.fromHex"e81cff")
})
}),
aj,
ak,

ac("UIListLayout",{
Padding=UDim.new(0,4),
FillDirection="Horizontal",
VerticalAlignment="Center",
}),

ac("TextButton",{
AutomaticSize="XY",
Active=true,
BackgroundTransparency=1,
Size=UDim2.new(0,0,0,36),

BackgroundColor3=Color3.new(1,1,1),
},{
ac("UICorner",{
CornerRadius=UDim.new(1,-4)
}),
ah,
ac("UIListLayout",{
Padding=UDim.new(0,af.UIPadding),
FillDirection="Horizontal",
VerticalAlignment="Center",
}),
ai,
ac("UIPadding",{
PaddingLeft=UDim.new(0,11),
PaddingRight=UDim.new(0,11),
}),
}),
ac("UIPadding",{
PaddingLeft=UDim.new(0,4),
PaddingRight=UDim.new(0,4),
})
})

ag.Button=an



function ag.SetIcon(ao,ap)
if ah then
ah:Destroy()
end
if ap then
ah=ab.Image(
ap,
af.Title,
0,
af.Folder,
"OpenButton",
true,
af.IconThemed
)
ah.Size=UDim2.new(0,22,0,22)
ah.LayoutOrder=-1
ah.Parent=ag.Button.TextButton
end
end

if af.Icon then
ag:SetIcon(af.Icon)
end



ab.AddSignal(an:GetPropertyChangedSignal"AbsoluteSize",function()
al.Size=UDim2.new(
0,an.AbsoluteSize.X,
0,an.AbsoluteSize.Y
)
end)

ab.AddSignal(an.TextButton.MouseEnter,function()
ad(an.TextButton,.1,{BackgroundTransparency=.93}):Play()
end)
ab.AddSignal(an.TextButton.MouseLeave,function()
ad(an.TextButton,.1,{BackgroundTransparency=1}):Play()
end)

local ao=ab.Drag(al)


function ag.Visible(ap,aq)
al.Visible=aq
end

function ag.SetScale(ap,aq)
am.Scale=aq
end

function ag.Edit(ap,aq)
local ar={
Title=aq.Title,
Icon=aq.Icon,
Enabled=aq.Enabled,
Position=aq.Position,
OnlyIcon=aq.OnlyIcon or false,
Draggable=aq.Draggable or nil,
OnlyMobile=aq.OnlyMobile,
CornerRadius=aq.CornerRadius or UDim.new(1,0),
StrokeThickness=aq.StrokeThickness or 2,
Scale=aq.Scale or 1,
Color=aq.Color
or ColorSequence.new(Color3.fromHex"40c9ff",Color3.fromHex"e81cff"),
}



if ar.Enabled==false then
af.IsOpenButtonEnabled=false
end

if ar.OnlyMobile~=false then
ar.OnlyMobile=true
else
af.IsPC=false
end


if ar.Draggable==false and aj and ak then
aj.Visible=ar.Draggable
ak.Visible=ar.Draggable

if ao then
ao:Set(ar.Draggable)
end
end

if ar.Position and al then
al.Position=ar.Position
end

if ar.OnlyIcon==true and ai then
ai.Visible=false
an.TextButton.UIPadding.PaddingLeft=UDim.new(0,7)
an.TextButton.UIPadding.PaddingRight=UDim.new(0,7)
elseif ar.OnlyIcon==false then
ai.Visible=true
an.TextButton.UIPadding.PaddingLeft=UDim.new(0,11)
an.TextButton.UIPadding.PaddingRight=UDim.new(0,11)
end





if ai then
if ar.Title then
ai.Text=ar.Title
ab:ChangeTranslationKey(ai,ar.Title)
elseif ar.Title==nil then

end
end

if ar.Icon then
ag:SetIcon(ar.Icon)
end

an.UIStroke.UIGradient.Color=ar.Color
if Glow then
Glow.UIGradient.Color=ar.Color
end

an.UICorner.CornerRadius=ar.CornerRadius
an.TextButton.UICorner.CornerRadius=UDim.new(ar.CornerRadius.Scale,ar.CornerRadius.Offset-4)
an.UIStroke.Thickness=ar.StrokeThickness

ag:SetScale(ar.Scale)
end

return ag
end



return aa end function a.B()
local aa={}

local ab=a.load'd'
local ac=ab.New
local ad=ab.Tween


function aa.New(ae,af,ag,ah,ai,aj)
local ak={
Container=nil,
TooltipSize=16,

TooltipArrowSizeX=ai=="Small"and 16 or 24,
TooltipArrowSizeY=ai=="Small"and 6 or 9,

PaddingX=ai=="Small"and 12 or 14,
PaddingY=ai=="Small"and 7 or 9,

Radius=999,

TitleFrame=nil,
}

ah=ah or""
aj=aj~=false

local al=ac("TextLabel",{
AutomaticSize="XY",
TextWrapped=aj,
BackgroundTransparency=1,
FontFace=Font.new(ab.Font,Enum.FontWeight.Medium),
Text=ae,
TextSize=ai=="Small"and 15 or 17,
TextTransparency=1,
ThemeTag={
TextColor3="Tooltip"..ah.."Text",
}
})

ak.TitleFrame=al

local am=ac("UIScale",{
Scale=.9
})

local an=ac("Frame",{
AnchorPoint=Vector2.new(0.5,0),
AutomaticSize="XY",
BackgroundTransparency=1,
Parent=af,

Visible=false
},{
ac("UISizeConstraint",{
MaxSize=Vector2.new(400,math.huge)
}),
ac("Frame",{
AutomaticSize="XY",
BackgroundTransparency=1,
LayoutOrder=99,
Visible=ag,
Name="Arrow",
},{
ac("ImageLabel",{
Size=UDim2.new(0,ak.TooltipArrowSizeX,0,ak.TooltipArrowSizeY),
BackgroundTransparency=1,

Image="rbxassetid://105854070513330",
ThemeTag={
ImageColor3="Tooltip"..ah,
},
},{










}),
}),
ab.NewRoundFrame(ak.Radius,"Squircle",{
AutomaticSize="XY",
ThemeTag={
ImageColor3="Tooltip"..ah,
},
ImageTransparency=1,
Name="Background",
},{



ac("Frame",{



AutomaticSize="XY",
BackgroundTransparency=1,
},{
ac("UICorner",{
CornerRadius=UDim.new(0,16),
}),
ac("UIListLayout",{
Padding=UDim.new(0,12),
FillDirection="Horizontal",
VerticalAlignment="Center"
}),

al,
ac("UIPadding",{
PaddingTop=UDim.new(0,ak.PaddingY),
PaddingLeft=UDim.new(0,ak.PaddingX),
PaddingRight=UDim.new(0,ak.PaddingX),
PaddingBottom=UDim.new(0,ak.PaddingY),
}),
})
}),
am,
ac("UIListLayout",{
Padding=UDim.new(0,0),
FillDirection="Vertical",
VerticalAlignment="Center",
HorizontalAlignment="Center",
}),
})
ak.Container=an

function ak.Open(ao)
an.Visible=true


ad(an.Background,.2,{ImageTransparency=0},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
ad(an.Arrow.ImageLabel,.2,{ImageTransparency=0},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
ad(al,.2,{TextTransparency=0},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
ad(am,.22,{Scale=1},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
end

function ak.Close(ao,ap)

ad(an.Background,.3,{ImageTransparency=1},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
ad(an.Arrow.ImageLabel,.2,{ImageTransparency=1},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
ad(al,.3,{TextTransparency=1},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
ad(am,.35,{Scale=.9},Enum.EasingStyle.Quint,Enum.EasingDirection.In):Play()

ap=ap~=false
if ap then
task.wait(.35)

an.Visible=false
an:Destroy()
end
end

return ak
end



return aa end function a.C()
game:GetService"ReplicatedStorage"
local aa=a.load'd'
local ab=aa.New
local ac=aa.NewRoundFrame
local ad=aa.Tween

local ae=(cloneref or clonereference or function(ae)
return ae
end)

ae(game:GetService"UserInputService")

local af=a.load'y'

local function Color3ToHSB(ag)
local ah,ai,aj=ag.R,ag.G,ag.B
local ak=math.max(ah,ai,aj)
local al=math.min(ah,ai,aj)
local am=ak-al

local an=0
if am~=0 then
if ak==ah then
an=(ai-aj)/am%6
elseif ak==ai then
an=(aj-ah)/am+2
else
an=(ah-ai)/am+4
end
an=an*60
else
an=0
end

local ao=(ak==0)and 0 or(am/ak)
local ap=ak

return{
h=math.floor(an+0.5),
s=ao,
b=ap,
}
end

local function GetPerceivedBrightness(ag)
local ah=ag.R
local ai=ag.G
local aj=ag.B
return 0.299*ah+0.587*ai+0.114*aj
end

local function GetTextColorForHSB(ag)
local ah=Color3ToHSB(ag)local
ai, aj, ak=ah.h, ah.s, ah.b
if GetPerceivedBrightness(ag)>0.5 then
return Color3.fromHSV(ai/360,0,0.05)
else
return Color3.fromHSV(ai/360,0,0.98)
end
end

return function(ag)
local ah={
Title=ag.Title,
Desc=ag.Desc or nil,
Hover=ag.Hover,
Thumbnail=ag.Thumbnail,
ThumbnailSize=ag.ThumbnailSize or 80,
Image=ag.Image,
IconThemed=ag.IconThemed or false,
ImageSize=ag.ImageSize or 30,
Color=ag.Color,
Scalable=ag.Scalable,
Parent=ag.Parent,
Justify=ag.Justify or"Between",
UIPadding=ag.Window.ElementConfig.UIPadding,
UICorner=ag.Window.ElementConfig.UICorner,
Size=ag.Size or"Default",
Tags=ag.Tags or{},
UIElements={},

Index=ag.Index,
}

local ai=ah.Size=="Small"and-4 or ah.Size=="Large"and 4 or 0
local aj=ah.Size=="Small"and-4 or ah.Size=="Large"and 4 or 0

local ak=ah.ImageSize
local al=ah.ThumbnailSize
local am=true


local an=0

local ao
local ap
if ah.Thumbnail then
ao=aa.Image(
ah.Thumbnail,
ah.Title,
ag.Window.NewElements and ah.UICorner-11 or(ah.UICorner-4),
ag.Window.Folder,
"Thumbnail",
false,
ah.IconThemed
)
ao.Size=UDim2.new(1,0,0,al)
end
if ah.Image then
ap=aa.Image(
ah.Image,
ah.Title,
ag.Window.NewElements and ah.UICorner-11 or(ah.UICorner-4),
ag.Window.Folder,
"Image",
ah.IconThemed,
not ah.Color and true or false,
"ElementIcon"
)

if typeof(ah.Color)=="string"and not string.find(ah.Image,"rbxthumb")then
ap.ImageLabel.ImageColor3=GetTextColorForHSB(Color3.fromHex(aa.Colors[ah.Color]))
elseif typeof(ah.Color)=="Color3"and not string.find(ah.Image,"rbxthumb")then
ap.ImageLabel.ImageColor3=GetTextColorForHSB(ah.Color)
end

ap.Size=UDim2.new(0,ak,0,ak)

an=ak
end

local function CreateText(aq,ar)
local as=typeof(ah.Color)=="string"
and GetTextColorForHSB(Color3.fromHex(aa.Colors[ah.Color]))
or typeof(ah.Color)=="Color3"and GetTextColorForHSB(ah.Color)

return ab("TextLabel",{
BackgroundTransparency=1,
Text=aq or"",
TextSize=ar=="Desc"and 15 or 17,
TextXAlignment="Left",
ThemeTag={
TextColor3=not ah.Color and("Element"..ar)or nil,
},
TextColor3=ah.Color and as or nil,
TextTransparency=ar=="Desc"and 0.3 or 0,
TextWrapped=true,
Size=UDim2.new(ah.Justify=="Between"and 1 or 0,0,0,0),
AutomaticSize=ah.Justify=="Between"and"Y"or"XY",
FontFace=Font.new(aa.Font,ar=="Desc"and Enum.FontWeight.Medium or Enum.FontWeight.SemiBold),
})
end

local aq=CreateText(ah.Title,"Title")
local ar=CreateText(ah.Desc,"Desc")
if not ah.Title or ah.Title==""then
ar.Visible=false
end
if not ah.Desc or ah.Desc==""then
ar.Visible=false
end

ah.UIElements.Title=aq
ah.UIElements.Desc=ar

ah.UIElements.Container=ab("Frame",{
Size=UDim2.new(1,0,1,0),
AutomaticSize="Y",
BackgroundTransparency=1,
},{
ab("UIListLayout",{
Padding=UDim.new(0,ah.UIPadding),
FillDirection="Vertical",
VerticalAlignment="Center",
HorizontalAlignment=ah.Justify=="Between"and"Left"or"Center",
}),
ao,
ab("Frame",{
Size=UDim2.new(
ah.Justify=="Between"and 1 or 0,
ah.Justify=="Between"and-ag.TextOffset or 0,
0,
0
),
AutomaticSize=ah.Justify=="Between"and"Y"or"XY",
BackgroundTransparency=1,
Name="TitleFrame",
},{
ab("UIListLayout",{
Padding=UDim.new(0,ah.UIPadding),
FillDirection="Horizontal",
VerticalAlignment=ag.Window.NewElements and(ah.Justify=="Between"and"Top"or"Center")
or"Center",
HorizontalAlignment=ah.Justify~="Between"and ah.Justify or"Center",
}),
ap,
ab("Frame",{
BackgroundTransparency=1,
AutomaticSize=ah.Justify=="Between"and"Y"or"XY",
Size=UDim2.new(
ah.Justify=="Between"and 1 or 0,
ah.Justify=="Between"and(ap and-an-ah.UIPadding or-an)
or 0,
1,
0
),
Name="TitleFrame",
},{
ab("UIPadding",{
PaddingTop=UDim.new(0,(ag.Window.NewElements and ah.UIPadding/2 or 0)+aj),
PaddingLeft=UDim.new(0,(ag.Window.NewElements and ah.UIPadding/2 or 0)+ai),
PaddingRight=UDim.new(
0,
(ag.Window.NewElements and ah.UIPadding/2 or 0)+ai
),
PaddingBottom=UDim.new(
0,
(ag.Window.NewElements and ah.UIPadding/2 or 0)+aj
),
}),
ab("UIListLayout",{
Padding=UDim.new(0,6),
FillDirection="Vertical",
VerticalAlignment="Center",
HorizontalAlignment="Left",
}),
ab("ScrollingFrame",{
Size=UDim2.new(1,0,0,0),
AutomaticSize="Y",
LayoutOrder=-99,
BackgroundTransparency=1,
ScrollingDirection="X",
CanvasSize=UDim2.new(0,0,0,0),
ScrollBarThickness=0,
Visible=false,
},{
ab("UIListLayout",{
FillDirection="Horizontal",
VerticalAlignment="Center",
HorizontalAlignment="Left",
Padding=UDim.new(0,ag.Window.UIPadding/2),
}),
}),
ab("Frame",{
Name="Space",
Size=UDim2.new(1,0,0,0),
BackgroundTransparency=1,
Visible=false,
}),
aq,
ar,
}),
}),
})

for as,at in next,ag.Tags or{}do
if not ah.UIElements.Container.TitleFrame.TitleFrame.ScrollingFrame.Visible then
ah.UIElements.Container.TitleFrame.TitleFrame.ScrollingFrame.Visible=true
ah.UIElements.Container.TitleFrame.TitleFrame.Space.Visible=true
end
af:New(at,ah.UIElements.Container.TitleFrame.TitleFrame.ScrollingFrame)
end

aa.AddSignal(
ah.UIElements.Container.TitleFrame.TitleFrame.ScrollingFrame.UIListLayout:GetPropertyChangedSignal
"AbsoluteContentSize"
,
function()
ah.UIElements.Container.TitleFrame.TitleFrame.ScrollingFrame.Size=UDim2.new(
1,
0,
0,
ah.UIElements.Container.TitleFrame.TitleFrame.ScrollingFrame.UIListLayout.AbsoluteContentSize.Y
/ag.ParentConfig.UIScale
)
end
)





local as=aa.Image("lock","lock",0,ag.Window.Folder,"Lock",false)
as.Size=UDim2.new(0,20,0,20)
as.ImageLabel.ImageColor3=Color3.new(1,1,1)
as.ImageLabel.ImageTransparency=0.4

local at=ab("TextLabel",{
Text="Locked",
TextSize=18,
FontFace=Font.new(aa.Font,Enum.FontWeight.Medium),
AutomaticSize="XY",
BackgroundTransparency=1,
TextColor3=Color3.new(1,1,1),
TextTransparency=0.05,
})

local au=ab("Frame",{
Size=UDim2.new(1,ah.UIPadding*2,1,ah.UIPadding*2),
BackgroundTransparency=1,
AnchorPoint=Vector2.new(0.5,0.5),
Position=UDim2.new(0.5,0,0.5,0),
ZIndex=9999999,
})

local av,aw=ac(ah.UICorner,"Squircle",{
Size=UDim2.new(1,0,1,0),
ImageTransparency=0.25,
ImageColor3=Color3.new(0,0,0),
Visible=false,
Active=false,
Parent=au,
},{
ab("UIListLayout",{
FillDirection="Horizontal",
VerticalAlignment="Center",
HorizontalAlignment="Center",
Padding=UDim.new(0,8),
}),
as,
at,
},nil,true)local

ax=ac(ah.UICorner,"Squircle-Outline",{
Size=UDim2.new(1,0,1,0),
ImageTransparency=1,
Active=false,
ThemeTag={
ImageColor3="Text",
},
Parent=au,
},{
ab("UIListLayout",{
FillDirection="Horizontal",
VerticalAlignment="Center",
HorizontalAlignment="Center",
Padding=UDim.new(0,8),
}),
},nil,true)

local ay,az=ac(ah.UICorner,"Squircle",{
Size=UDim2.new(1,0,1,0),
ImageTransparency=1,
Active=false,
ThemeTag={
ImageColor3="Text",
},
Parent=au,
},{
ab("UIListLayout",{
FillDirection="Horizontal",
VerticalAlignment="Center",
HorizontalAlignment="Center",
Padding=UDim.new(0,8),
}),
},nil,true)local

aA=ac(ah.UICorner,"Squircle-Outline",{
Size=UDim2.new(1,0,1,0),
ImageTransparency=1,
Visible=false,
Active=false,
ThemeTag={
ImageColor3="Text",
},
Parent=au,
},{
ab("UIListLayout",{
FillDirection="Horizontal",
VerticalAlignment="Center",
HorizontalAlignment="Center",
Padding=UDim.new(0,8),
}),
ab("UIGradient",{
Name="HoverGradient",
Color=ColorSequence.new{
ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),
ColorSequenceKeypoint.new(0.5,Color3.new(1,1,1)),
ColorSequenceKeypoint.new(1,Color3.new(1,1,1)),
},
Transparency=NumberSequence.new{
NumberSequenceKeypoint.new(0,1),
NumberSequenceKeypoint.new(0.25,0.9),
NumberSequenceKeypoint.new(0.5,0.3),
NumberSequenceKeypoint.new(0.75,0.9),
NumberSequenceKeypoint.new(1,1),
},
}),
},nil,true)

local aB,b=ac(ah.UICorner,"Squircle",{
Size=UDim2.new(1,0,1,0),
ImageTransparency=1,
Active=false,
ThemeTag={
ImageColor3="Text",
},
Parent=au,
},{
ab("UIGradient",{
Name="HoverGradient",
Color=ColorSequence.new{
ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),
ColorSequenceKeypoint.new(0.5,Color3.new(1,1,1)),
ColorSequenceKeypoint.new(1,Color3.new(1,1,1)),
},
Transparency=NumberSequence.new{
NumberSequenceKeypoint.new(0,1),
NumberSequenceKeypoint.new(0.25,0.9),
NumberSequenceKeypoint.new(0.5,0.3),
NumberSequenceKeypoint.new(0.75,0.9),
NumberSequenceKeypoint.new(1,1),
},
}),
ab("UIListLayout",{
FillDirection="Horizontal",
VerticalAlignment="Center",
HorizontalAlignment="Center",
Padding=UDim.new(0,8),
}),
},nil,true)

local d,f=ac(ah.UICorner,"Squircle",{
Size=UDim2.new(1,0,0,0),
AutomaticSize="Y",
ImageTransparency=ah.Color and 0.05 or(not ag.Window.NewElements and 0.93 or nil),



Parent=ag.Parent,
ThemeTag={
ImageColor3=not ah.Color and(ag.Window.NewElements and"ElementBackground"or"Text")or nil,
ImageTransparency=not ah.Color
and(ag.Window.NewElements and"ElementBackgroundTransparency"or nil)
or nil,
},
ImageColor3=ah.Color and(typeof(ah.Color)=="string"and Color3.fromHex(
aa.Colors[ah.Color]
)or typeof(ah.Color)=="Color3"and ah.Color)or nil,
},{
ah.UIElements.Container,
au,
ab("UIPadding",{
PaddingTop=UDim.new(0,ah.UIPadding),
PaddingLeft=UDim.new(0,ah.UIPadding),
PaddingRight=UDim.new(0,ah.UIPadding),
PaddingBottom=UDim.new(0,ah.UIPadding),
}),
},true,true)

ah.UIElements.Main=d
ah.UIElements.Locked=av

if ah.Hover then
aa.AddSignal(d.MouseEnter,function()
if am then

ad(aB,0.12,{ImageTransparency=0.9}):Play()
ad(aA,0.12,{ImageTransparency=0.8}):Play()
aa.AddSignal(d.MouseMoved,function(g,h)
aB.HoverGradient.Offset=
Vector2.new(((g-d.AbsolutePosition.X)/d.AbsoluteSize.X)-0.5,0)
aA.HoverGradient.Offset=
Vector2.new(((g-d.AbsolutePosition.X)/d.AbsoluteSize.X)-0.5,0)
end)
end
end)
aa.AddSignal(d.InputEnded,function()
if am then

ad(aB,0.12,{ImageTransparency=1}):Play()
ad(aA,0.12,{ImageTransparency=1}):Play()
end
end)
end

function ah.SetTitle(g,h)
ah.Title=h
aq.Text=h
end

function ah.SetDesc(g,h)
ah.Desc=h
ar.Text=h or""
if not h then
ar.Visible=false
elseif not ar.Visible then
ar.Visible=true
end
end

function ah.Colorize(g,h,i)
if ah.Color then
h[i]=typeof(ah.Color)=="string"
and GetTextColorForHSB(Color3.fromHex(aa.Colors[ah.Color]))
or typeof(ah.Color)=="Color3"and GetTextColorForHSB(ah.Color)
or nil
end
end

if ag.ElementTable then
aa.AddSignal(aq:GetPropertyChangedSignal"Text",function()
if ah.Title~=aq.Text then
ah:SetTitle(aq.Text)
ag.ElementTable.Title=aq.Text
end
end)
aa.AddSignal(ar:GetPropertyChangedSignal"Text",function()
if ah.Desc~=ar.Text then
ah:SetDesc(ar.Text)
ag.ElementTable.Desc=ar.Text
end
end)
end





function ah.SetThumbnail(g,h,i)
ah.Thumbnail=h
if i then
ah.ThumbnailSize=i
al=i
end

if ao then
if h then
ao:Destroy()
ao=aa.Image(
h,
ah.Title,
ah.UICorner-3,
ag.Window.Folder,
"Thumbnail",
false,
ah.IconThemed
)
if ao then
ao.Size=UDim2.new(1,0,0,al)
ao.Parent=ah.UIElements.Container
local l=ah.UIElements.Container:FindFirstChild"UIListLayout"
if l then
ao.LayoutOrder=-1
end
end
else
ao.Visible=false
end
else
if h then
ao=aa.Image(
h,
ah.Title,
ah.UICorner-3,
ag.Window.Folder,
"Thumbnail",
false,
ah.IconThemed
)
if ao then
ao.Size=UDim2.new(1,0,0,al)
ao.Parent=ah.UIElements.Container
local l=ah.UIElements.Container:FindFirstChild"UIListLayout"
if l then
ao.LayoutOrder=-1
end
end
end
end
end

function ah.SetImage(g,h,i)
ah.Image=h
if i then
ah.ImageSize=i
ak=i
end

if h then
local l=ap and ap.Parent or ah.UIElements.Container.TitleFrame
if ap then
ap:Destroy()
end

ap=aa.Image(
h,
h,
ah.UICorner-3,
ag.Window.Folder,
"Image",
not ah.Color and true or false
)
if ap then
if typeof(ah.Color)=="string"and not string.find(ah.Image,"rbxthumb")then
ap.ImageLabel.ImageColor3=
GetTextColorForHSB(Color3.fromHex(aa.Colors[ah.Color]))
elseif typeof(ah.Color)=="Color3"and not string.find(ah.Image,"rbxthumb")then
ap.ImageLabel.ImageColor3=GetTextColorForHSB(ah.Color)
end

ap.Visible=true
ap.Parent=l
ap.LayoutOrder=-99

ap.Size=UDim2.new(0,ak,0,ak)
an=ah.ImageSize+ah.UIPadding
end
else
if ap then
ap.Visible=true
end
an=0
end

ah.UIElements.Container.TitleFrame.TitleFrame.Size=UDim2.new(1,-an,1,0)
end

function ah.Destroy(g)
d:Destroy()
end

function ah.Lock(g,h)
am=false
av.Active=true
av.Visible=true
at.Text=h or"Locked"
end

function ah.Unlock(g)
am=true
av.Active=false
av.Visible=false
end

function ah.Highlight(g)
local h=ab("UIGradient",{
Color=ColorSequence.new{
ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),
ColorSequenceKeypoint.new(0.5,Color3.new(1,1,1)),
ColorSequenceKeypoint.new(1,Color3.new(1,1,1)),
},
Transparency=NumberSequence.new{
NumberSequenceKeypoint.new(0,1),
NumberSequenceKeypoint.new(0.1,0.9),
NumberSequenceKeypoint.new(0.5,0.3),
NumberSequenceKeypoint.new(0.9,0.9),
NumberSequenceKeypoint.new(1,1),
},
Rotation=0,
Offset=Vector2.new(-1,0),
Parent=ax,
})

local i=ab("UIGradient",{
Color=ColorSequence.new{
ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),
ColorSequenceKeypoint.new(0.5,Color3.new(1,1,1)),
ColorSequenceKeypoint.new(1,Color3.new(1,1,1)),
},
Transparency=NumberSequence.new{
NumberSequenceKeypoint.new(0,1),
NumberSequenceKeypoint.new(0.15,0.8),
NumberSequenceKeypoint.new(0.5,0.1),
NumberSequenceKeypoint.new(0.85,0.8),
NumberSequenceKeypoint.new(1,1),
},
Rotation=0,
Offset=Vector2.new(-1,0),
Parent=ay,
})

ax.ImageTransparency=0.65
ay.ImageTransparency=0.88

ad(h,0.75,{
Offset=Vector2.new(1,0),
}):Play()

ad(i,0.75,{
Offset=Vector2.new(1,0),
}):Play()

task.spawn(function()
task.wait(0.75)
ax.ImageTransparency=1
ay.ImageTransparency=1
h:Destroy()
i:Destroy()
end)
end

function ah.UpdateShape(g)
if ag.Window.NewElements then
local h=aa:GetElementPosition(
g.Elements,
ah.Index,
ag.ParentConfig.ParentTable.__type=="HStack"or ag.ParentConfig.ParentTable.__type=="Group"
)

if h and d then
f:SetType(h)
aw:SetType(h)
az:SetType(h)

b:SetType(h)

end
end
end





return ah
end end function a.D()

local aa=a.load'd'
local ab=aa.New

local ac={}

local ad=a.load'm'.New

function ac.New(ae,af)
af.Hover=false
af.TextOffset=0
af.ParentConfig=af
af.IsButtons=af.Buttons and#af.Buttons>0 and true or false

local ag={
__type="Paragraph",
Title=af.Title or"Paragraph",
Desc=af.Desc or nil,

Locked=af.Locked or false,
}
local ah=a.load'C'(af)

ag.ParagraphFrame=ah
if af.Buttons and#af.Buttons>0 then
local ai=ab("Frame",{
Size=UDim2.new(1,0,0,38),
BackgroundTransparency=1,
AutomaticSize="Y",
Parent=ah.UIElements.Container,
},{
ab("UIListLayout",{
Padding=UDim.new(0,10),
FillDirection="Vertical",
}),
})

for aj,ak in next,af.Buttons do
local al=ad(
ak.Title,
ak.Icon,
ak.Callback,
ak.Variant or"White",
ai,
nil,
nil,
af.Window.NewElements and 999 or 10
)
al.Size=UDim2.new(1,0,0,38)

end
end

return ag.__type,ag
end

return ac end function a.E()

local aa=a.load'd'local ab=
aa.New

local ac={}

function ac.New(ad,ae)
local af={
__type="Button",
Title=ae.Title or"Button",
Desc=ae.Desc or nil,
Icon=ae.Icon or"mouse-pointer-click",
IconThemed=ae.IconThemed or false,
IconColor=ae.IconColor or nil,
Color=ae.Color,
Justify=ae.Justify or"Between",
IconAlign=ae.IconAlign or"Right",
Locked=ae.Locked or false,
LockedTitle=ae.LockedTitle,
Callback=ae.Callback or function()end,
UIElements={},
}

local ag=true

af.ButtonFrame=a.load'C'{
Title=af.Title,
Desc=af.Desc,
Parent=ae.Parent,




Window=ae.Window,
Color=af.Color,
Justify=af.Justify,
TextOffset=20,
Hover=true,
Scalable=true,
Tab=ae.Tab,
Index=ae.Index,
ElementTable=af,
ParentConfig=ae,
Size=ae.Size,
Tags=ae.Tags,
}














af.UIElements.ButtonIcon=aa.Image(
af.Icon,
af.Icon,
0,
ae.Window.Folder,
"Button",
not(af.Color or af.IconColor)and true or nil,
af.IconThemed
)

if af.IconColor then
af.UIElements.ButtonIcon.ImageLabel.ImageColor3=af.IconColor
end

af.UIElements.ButtonIcon.Size=UDim2.new(0,20,0,20)
af.UIElements.ButtonIcon.Parent=af.Justify=="Between"and af.ButtonFrame.UIElements.Main
or af.ButtonFrame.UIElements.Container.TitleFrame
af.UIElements.ButtonIcon.LayoutOrder=af.IconAlign=="Left"and-99999 or 99999
af.UIElements.ButtonIcon.AnchorPoint=Vector2.new(1,0.5)
af.UIElements.ButtonIcon.Position=UDim2.new(1,0,0.5,0)

af.ButtonFrame:Colorize(af.UIElements.ButtonIcon.ImageLabel,"ImageColor3")

function af.Lock(ah)
af.Locked=true
ag=false
return af.ButtonFrame:Lock(af.LockedTitle)
end
function af.Unlock(ah)
af.Locked=false
ag=true
return af.ButtonFrame:Unlock()
end

if af.Locked then
af:Lock()
end

aa.AddSignal(af.ButtonFrame.UIElements.Main.MouseButton1Click,function()
if ag then
task.spawn(function()
aa.SafeCallback(af.Callback)
end)
end
end)
return af.__type,af
end

return ac end function a.F()

local aa={}

local ab=a.load'd'
local ac=ab.New
local ad=ab.Tween

local ae=game:GetService"UserInputService"

function aa.New(af,ag,ah,ai,aj,ak,al)
local am={
GlassSpritesheet={
Id="rbxassetid://77297718671545",
MirroredId="rbxassetid://92258969882244",
Size=Vector2.new(102,128),
Total=80,
Cols=10,
},
}

function am.GetGlassFrame(an,ao:number):(string,Vector2,Vector2)
local ap=am.GlassSpritesheet
local aq:number

if ao<=0.4 then
aq=math.floor((ao/0.4)*(ap.Total-1))
elseif ao<0.6 then
aq=ap.Total-1
else
aq=math.floor(((ao-0.6)/0.4)*(ap.Total-1))
end

aq=math.clamp(aq,0,ap.Total-1)

local ar=ao>=0.6
if ar then
aq=(ap.Total-1)-aq
end

local as=ar and ap.MirroredId or ap.Id

return as,ap.Size,Vector2.new((aq%ap.Cols)*ap.Size.X,math.floor(aq/ap.Cols)*ap.Size.Y)
end

local an=12
local ao
if ag and ag~=""then
ao=ac("ImageLabel",{
Size=UDim2.new(0,13,0,13),
BackgroundTransparency=1,
AnchorPoint=Vector2.new(0.5,0.5),
Position=UDim2.new(0.5,0,0.5,0),
Image=ab.Icon(ag)[1],
ImageRectOffset=ab.Icon(ag)[2].ImageRectPosition,
ImageRectSize=ab.Icon(ag)[2].ImageRectSize,
ImageTransparency=1,
ImageColor3=Color3.new(0,0,0),
})
end

local ap=ac("Frame",{
Size=UDim2.new(0,2,0,26),
BackgroundTransparency=1,
Parent=ai,
})

local aq=ab.NewRoundFrame(an,"Squircle",{
ImageTransparency=0.85,
ThemeTag={
ImageColor3="Text",
},
Parent=ap,
Size=UDim2.new(0,ak and(52)or(40.8),0,24),
AnchorPoint=Vector2.new(1,0.5),
Position=UDim2.new(0,0,0.5,0),
Name="ToggleFrame",
},{
ab.NewRoundFrame(an,"Squircle",{
Size=UDim2.new(1,0,1,0),
Name="Layer",
ThemeTag={
ImageColor3="Toggle",
},
ImageTransparency=1,
}),
ab.NewRoundFrame(an,"SquircleOutline",{
Size=UDim2.new(1,0,1,0),
Name="Stroke",
ImageColor3=Color3.new(1,1,1),
ImageTransparency=1,
},{
ac("UIGradient",{
Rotation=90,
Transparency=NumberSequence.new{
NumberSequenceKeypoint.new(0,0),
NumberSequenceKeypoint.new(1,1),
},
}),
}),


ab.NewRoundFrame(an,"Squircle",{
Size=UDim2.new(0,ak and 30 or 20,0,20),
Position=UDim2.new(0,2,0.5,0),
AnchorPoint=Vector2.new(0,0.5),
ImageTransparency=1,
Name="Frame",
},{
ab.NewRoundFrame(an,"Squircle",{
Size=UDim2.new(1,0,1,0),
ImageTransparency=0,
AnchorPoint=Vector2.new(0.5,0.5),
Position=UDim2.new(0.5,0,0.5,0),
Name="Bar",
},{
ab.New("Frame",{
Size=UDim2.new(1,0,1,0),
BackgroundColor3=Color3.new(1,1,1),
Name="Highlight",
BackgroundTransparency=1,
},{
ab.NewRoundFrame(9999,"SquircleGlass",{
Size=UDim2.new(1,1,1,1),
ImageColor3=Color3.new(1,1,1),
Name="SquircleGlass",
ImageTransparency=0.5,
AnchorPoint=Vector2.new(0.5,0.5),
Position=UDim2.new(0.5,0,0.5,0),
}),
ab.NewRoundFrame(an,"Squircle",{
Size=UDim2.new(1,0,1,0),
Name="GlassBackground",
ImageTransparency=0,
ThemeTag={
ImageColor3="ElementBackground",
},
ZIndex=-1,
}),
ac("ImageLabel",{
Size=UDim2.new(1,0,1,0),
BackgroundTransparency=1,
Name="Glass",
ImageTransparency=0,
},{
ac("UICorner",{
CornerRadius=UDim.new(1,0),
}),
}),






ab.NewRoundFrame(an,"Squircle",{
Size=UDim2.new(1,0,1,0),
Name="BarOverlay",
ThemeTag={
ImageColor3="ToggleBar",
},
ZIndex=999,
}),
}),
ao,
ac("UIScale",{
Scale=1,
}),
}),
}),
ac("TextButton",{
Size=UDim2.new(1,0,1,0),
BackgroundTransparency=1,
Position=UDim2.new(0.5,0,0.5,0),
AnchorPoint=Vector2.new(0.5,0.5),
Name="Hitbox",
Text="",
}),
})

local ar
local as

local at=ak and 30 or 20
local au=aq.Size.X.Offset

function am.Set(av,aw,ax,ay)
if not ay then
if aw then
ad(aq.Frame,0.35,{
Position=UDim2.new(0,au-at-2,0.5,0),
},Enum.EasingStyle.Back,Enum.EasingDirection.Out):Play()
ab.SetThemeTag(aq.Frame.Bar.Highlight.Glass,{ImageColor3="Toggle"},0.15)

ad(
aq.Frame.Bar.Highlight.Glass,
0.15,
{ImageTransparency=0},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()
else
ad(aq.Frame,0.35,{
Position=UDim2.new(0,2,0.5,0),
},Enum.EasingStyle.Back,Enum.EasingDirection.Out):Play()
ab.SetThemeTag(aq.Frame.Bar.Highlight.Glass,{ImageColor3="Text"},0.15)
ad(
aq.Frame.Bar.Highlight.Glass,
0.15,
{ImageTransparency=0.85},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()
end
else
if aw then
aq.Frame.Position=UDim2.new(0,au-at-2,0.5,0)
else
aq.Frame.Position=UDim2.new(0,2,0.5,0)
end
end

if aw then
ad(aq.Layer,0.1,{
ImageTransparency=0,
}):Play()
ab.SetThemeTag(aq.Frame.Bar.Highlight.Glass,{ImageColor3="Toggle"},0.1)
ad(
aq.Frame.Bar.Highlight.Glass,
0.1,
{ImageTransparency=0},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()

if ao then
ad(ao,0.1,{
ImageTransparency=0,
}):Play()
end

local az,aA,aB=am:GetGlassFrame(1)

aq.Frame.Bar.Highlight.Glass.Image=az
aq.Frame.Bar.Highlight.Glass.ImageRectSize=aA
aq.Frame.Bar.Highlight.Glass.ImageRectOffset=aB
else
ad(aq.Layer,0.1,{
ImageTransparency=1,
}):Play()
ab.SetThemeTag(aq.Frame.Bar.Highlight.Glass,{ImageColor3="Text"},0.1)
ad(
aq.Frame.Bar.Highlight.Glass,
0.1,
{ImageTransparency=0.85},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()

if ao then
ad(ao,0.1,{
ImageTransparency=1,
}):Play()
end

local az,aA,aB=am:GetGlassFrame(0)

aq.Frame.Bar.Highlight.Glass.Image=az
aq.Frame.Bar.Highlight.Glass.ImageRectSize=aA
aq.Frame.Bar.Highlight.Glass.ImageRectOffset=aB
end

ax=ax~=false

task.spawn(function()
if aj and ax then
ab.SafeCallback(aj,aw)
end
end)
end

function am.Animate(av,aw,ax)
if not al.Window.IsToggleDragging then
al.Window.IsToggleDragging=true

local ay=aw.Position.X
local az=aw.Position.Y
local aA=aq.Frame.Position.X.Offset
local aB=false
local b=false

ad(
aq.Frame.Bar.UIScale,
0.28,
{Scale=1.5},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()
ad(
aq.Frame.Bar.Highlight.BarOverlay,
0.28,
{ImageTransparency=0.86},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()

if ar then
ar:Disconnect()
end

ar=ae.InputChanged:Connect(function(d)
if not al.Window.IsToggleDragging then
return
end
if
d.UserInputType~=Enum.UserInputType.MouseMovement
and d.UserInputType~=Enum.UserInputType.Touch
then
return
end
if aB then
return
end

local f=math.abs(d.Position.X-ay)
math.abs(d.Position.Y-az)

if not b and f>8 then
b=true
end

local g=d.Position.X-ay
local h=math.max(2,math.min(aA+g,au-at-2))

local i=math.clamp((h-2)/(au-at-4),0,1)

local l,m,p=am:GetGlassFrame(i)
aq.Frame.Bar.Highlight.Glass.Image=l
aq.Frame.Bar.Highlight.Glass.ImageRectSize=m
aq.Frame.Bar.Highlight.Glass.ImageRectOffset=p

ad(aq.Frame,0.12,{
Position=UDim2.new(0,h,0.5,0),
},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
end)

if as then
as:Disconnect()
end

as=ae.InputEnded:Connect(function(d)
if not al.Window.IsToggleDragging then
return
end
if
d.UserInputType~=Enum.UserInputType.MouseButton1
and d.UserInputType~=Enum.UserInputType.Touch
then
return
end

al.Window.IsToggleDragging=false

if ar then
ar:Disconnect()
ar=nil
end
if as then
as:Disconnect()
as=nil
end

al.WindUI.CurrentInput=nil

if aB then
return
end

if not b then
ax:Set(not ax.Value,true,false)
else
local f=aq.Frame.Position.X.Offset
local g=f+at/2
local h=g>au/2
ax:Set(h,true,false)
end

ad(
aq.Frame.Bar.UIScale,
0.23,
{Scale=1},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()
ad(
aq.Frame.Bar.Highlight.BarOverlay,
0.23,
{ImageTransparency=0},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()
end)
end
end

return ap,am
end

return aa end function a.G()

local aa={}

local ab=a.load'd'local ac=
ab.New
local ad=ab.Tween


function aa.New(ae,af,ag,ah,ai,aj)
local ak={}

af=af or"sfsymbols:checkmark"

local al=9

local am=ab.Image(
af,
af,
0,
(aj and aj.Window.Folder or"Temp"),
"Checkbox",
true,
false,
"CheckboxIcon"
)
am.Size=UDim2.new(1,-26+ag,1,-26+ag)
am.AnchorPoint=Vector2.new(0.5,0.5)
am.Position=UDim2.new(0.5,0,0.5,0)


local an=ab.NewRoundFrame(al,"Squircle",{
ImageTransparency=.85,
ThemeTag={
ImageColor3="Text"
},
Parent=ah,
Size=UDim2.new(0,26,0,26),
},{
ab.NewRoundFrame(al,"Squircle",{
Size=UDim2.new(1,0,1,0),
Name="Layer",
ThemeTag={
ImageColor3="Checkbox",
},
ImageTransparency=1,
}),
ab.NewRoundFrame(al,"Glass-1.4",{
Size=UDim2.new(1,0,1,0),
Name="Stroke",
ThemeTag={
ImageColor3="CheckboxBorder",
ImageTransparency="CheckboxBorderTransparency",
},
},{







}),

am,
},true)

function ak.Set(ao,ap)
if ap then
ad(an.Layer,0.06,{
ImageTransparency=0,
}):Play()



ad(am.ImageLabel,0.06,{
ImageTransparency=0,
}):Play()
else
ad(an.Layer,0.05,{
ImageTransparency=1,
}):Play()



ad(am.ImageLabel,0.06,{
ImageTransparency=1,
}):Play()
end

task.spawn(function()
if ai then
ab.SafeCallback(ai,ap)
end
end)
end

return an,ak
end


return aa end function a.H()
local aa=a.load'd'local ab=
aa.New local ac=
aa.Tween

local ad=a.load'F'.New
local ae=a.load'G'.New

local af={}

function af.New(ag,ah)
local ai={
__type="Toggle",
Title=ah.Title or"Toggle",
Desc=ah.Desc or nil,
Locked=ah.Locked or false,
LockedTitle=ah.LockedTitle,
Value=ah.Value,
Icon=ah.Icon or nil,
IconSize=ah.IconSize or 23,
Type=ah.Type or"Toggle",
Callback=ah.Callback or function()end,
UIElements={},
}
ai.ToggleFrame=a.load'C'{
Title=ai.Title,
Desc=ai.Desc,




Window=ah.Window,
Parent=ah.Parent,
TextOffset=(52),
Hover=false,
Tab=ah.Tab,
Index=ah.Index,
ElementTable=ai,
ParentConfig=ah,
Tags=ah.Tags,
}

local aj=true

if ai.Value==nil then
ai.Value=false
end

function ai.Lock(ak)
ai.Locked=true
aj=false
return ai.ToggleFrame:Lock(ai.LockedTitle)
end
function ai.Unlock(ak)
ai.Locked=false
aj=true
return ai.ToggleFrame:Unlock()
end

if ai.Locked then
ai:Lock()
end

local ak=ai.Value

local al,am
if ai.Type=="Toggle"then
al,am=ad(
ak,
ai.Icon,
ai.IconSize,
ai.ToggleFrame.UIElements.Main,
ai.Callback,
ah.Window.NewElements,
ah
)
elseif ai.Type=="Checkbox"then
al,am=ae(
ak,
ai.Icon,
ai.IconSize,
ai.ToggleFrame.UIElements.Main,
ai.Callback,
ah
)
else
error("Unknown Toggle Type: "..tostring(ai.Type))
end

al.AnchorPoint=Vector2.new(1,ah.Window.NewElements and 0 or 0.5)
al.Position=UDim2.new(1,0,ah.Window.NewElements and 0 or 0.5,0)

function ai.Set(an,ao,ap,aq)
if aj then
am:Set(ao,ap,aq or false)
ak=ao
ai.Value=ao
end
end

ai:Set(ak,false,ah.Window.NewElements)

local an=ah.WindUI.GenerateGUID()

if ah.Window.NewElements and am.Animate then
if ai.Type=="Toggle"then
aa.AddSignal(al.ToggleFrame.Hitbox.InputBegan,function(ao)
if
not ah.Window.IsToggleDragging
and(
ao.UserInputType==Enum.UserInputType.MouseButton1
or ao.UserInputType==Enum.UserInputType.Touch
)
then
if ah.WindUI.CurrentInput and ah.WindUI.CurrentInput~=an then
return
end

ah.WindUI.CurrentInput=an
am:Animate(ao,ai)
end
end)
end





else
if ai.Type=="Toggle"then
aa.AddSignal(al.ToggleFrame.Hitbox.MouseButton1Click,function()
ai:Set(not ai.Value,nil,ah.Window.NewElements)
end)
elseif ai.Type=="Checkbox"then
aa.AddSignal(al.MouseButton1Click,function()
ai:Set(not ai.Value,nil,ah.Window.NewElements)
end)
end
end

return ai.__type,ai
end

return af end function a.I()

local aa=(cloneref or clonereference or function(aa)
return aa
end)

local ac=aa(game:GetService"UserInputService")
local ad=aa(game:GetService"RunService")

local ae=a.load'd'
local af=ae.New
local ag=ae.Tween

local ah={}

local ai=false

function ah.New(aj,ak)
local al={
__type="Slider",
Title=ak.Title or nil,
Desc=ak.Desc or nil,
Locked=ak.Locked or nil,
LockedTitle=ak.LockedTitle,
Value=ak.Value or{},
Icons=ak.Icons or nil,
IsTooltip=ak.IsTooltip or false,
IsTextbox=ak.IsTextbox,
Step=ak.Step or 1,
Callback=ak.Callback or function()end,
UIElements={},
IsFocusing=false,

Width=ak.Width or 130,
TextBoxWidth=ak.Window.NewElements and 40 or 30,
ThumbSize=13,
IconSize=26,
}
if al.Icons=={}then
al.Icons={
From="sfsymbols:sunMinFill",
To="sfsymbols:sunMaxFill",
}
end
if al.IsTextbox==nil and al.Title==nil then
al.IsTextbox=false
else
al.IsTextbox=al.IsTextbox~=false
end

local am
local an
local ao
local ap=al.Value.Default or al.Value.Min or 0

local aq=ap
local ar=(ap-(al.Value.Min or 0))/((al.Value.Max or 100)-(al.Value.Min or 0))

local as=true
local at=al.Step%1~=0

local function FormatValue(au)
if at then
return tonumber(string.format("%.2f",au))
end
return math.floor(au+0.5)
end

local function CalculateValue(au)
if at then
return math.floor(au/al.Step+0.5)*al.Step
else
return math.floor(au/al.Step+0.5)*al.Step
end
end

local au,av
local aw=32
if al.Icons then
if al.Icons.From then
au=ae.Image(
al.Icons.From,
al.Icons.From,
0,
ak.Window.Folder,
"SliderIconFrom",
true,
true,
"SliderIconFrom"
)
au.Size=UDim2.new(0,al.IconSize,0,al.IconSize)
aw=aw+al.IconSize-2
end
if al.Icons.To then
av=ae.Image(
al.Icons.To,
al.Icons.To,
0,
ak.Window.Folder,
"SliderIconTo",
true,
true,
"SliderIconTo"
)
av.Size=UDim2.new(0,al.IconSize,0,al.IconSize)
aw=aw+al.IconSize-2
end
end
al.SliderFrame=a.load'C'{
Title=al.Title,
Desc=al.Desc,
Parent=ak.Parent,
TextOffset=al.Width,
Hover=false,
Tab=ak.Tab,
Index=ak.Index,
Window=ak.Window,
ElementTable=al,
ParentConfig=ak,
Tags=ak.Tags,
}

al.UIElements.SliderIcon=ae.NewRoundFrame(99,"Squircle",{
ImageTransparency=0.95,
Size=UDim2.new(1,not al.IsTextbox and-aw or(-al.TextBoxWidth-8),0,4),
AnchorPoint=Vector2.new(0.5,0.5),
Position=UDim2.new(0.5,0,0.5,0),
Name="Frame",
ThemeTag={
ImageColor3="Text",
},
},{
ae.NewRoundFrame(99,"Squircle",{
Name="Frame",
Size=UDim2.new(ar,0,1,0),
ImageTransparency=0.1,
ThemeTag={
ImageColor3="Slider",
},
},{
ae.NewRoundFrame(99,"Squircle",{
Size=UDim2.new(
0,
ak.Window.NewElements and(al.ThumbSize*2)or(al.ThumbSize+2),
0,
ak.Window.NewElements and(al.ThumbSize+4)or(al.ThumbSize+2)
),
Position=UDim2.new(1,0,0.5,0),
AnchorPoint=Vector2.new(0.5,0.5),
ThemeTag={
ImageColor3="SliderThumb",
},
Name="Thumb",
},{
ae.NewRoundFrame(999,"SquircleGlass",{
Size=UDim2.new(1,0,1,0),
ImageColor3=Color3.new(1,1,1),
Name="Highlight",
ImageTransparency=0.5,
}),
}),
}),
})

al.UIElements.SliderContainer=af("Frame",{
Size=UDim2.new(al.Title==nil and 1 or 0,al.Title==nil and 0 or al.Width,0,0),
AutomaticSize="Y",
Position=UDim2.new(1,al.IsTextbox and(ak.Window.NewElements and-16 or 0)or 0,0.5,0),
AnchorPoint=Vector2.new(1,0.5),
BackgroundTransparency=1,
Parent=al.SliderFrame.UIElements.Main,
},{
af("UIListLayout",{
Padding=UDim.new(0,al.Title~=nil and 8 or 12),
FillDirection="Horizontal",
VerticalAlignment="Center",
HorizontalAlignment=al.Icons
and(al.Icons.From and(al.Icons.To and"Center"or"Left")or al.Icons.To and"Right")
or"Center",
}),
au,
al.UIElements.SliderIcon,
av,
af("TextBox",{
Size=UDim2.new(0,al.TextBoxWidth,0,0),
TextXAlignment="Left",
Text=FormatValue(ap),
ThemeTag={
TextColor3="Text",
},
TextTransparency=0.4,
AutomaticSize="Y",
TextSize=15,
FontFace=Font.new(ae.Font,Enum.FontWeight.Medium),
BackgroundTransparency=1,
LayoutOrder=-1,
Visible=al.IsTextbox,
}),
})

local ax
if al.IsTooltip then
ax=a.load'B'.New(
ap,
al.UIElements.SliderIcon.Frame.Thumb,
true,
"Secondary",
"Small",
false
)
ax.Container.AnchorPoint=Vector2.new(0.5,1)
ax.Container.Position=UDim2.new(0.5,0,0,-8)
end

function al.Lock(ay)
al.Locked=true
as=false
return al.SliderFrame:Lock(al.LockedTitle)
end
function al.Unlock(ay)
al.Locked=false
as=true
return al.SliderFrame:Unlock()
end

if al.Locked then
al:Lock()
end


local ay=ak.Tab.UIElements.ContainerFrame

function al.Set(az,aA,aB)
if as then
if
not al.IsFocusing
and not ai
and(
not aB
or(
aB.UserInputType==Enum.UserInputType.MouseButton1
or aB.UserInputType==Enum.UserInputType.Touch
)
)
then
if aB then
am=(aB.UserInputType==Enum.UserInputType.Touch)
ay.ScrollingEnabled=false
ai=true

local b=am and aB.Position.X or ac:GetMouseLocation().X
local d=math.clamp(
(b-al.UIElements.SliderIcon.AbsolutePosition.X)
/al.UIElements.SliderIcon.AbsoluteSize.X,
0,
1
)
aA=CalculateValue(al.Value.Min+d*(al.Value.Max-al.Value.Min))
aA=math.clamp(aA,al.Value.Min or 0,al.Value.Max or 100)

if aA~=aq then
ag(al.UIElements.SliderIcon.Frame,0.05,{Size=UDim2.new(d,0,1,0)}):Play()
al.UIElements.SliderContainer.TextBox.Text=FormatValue(aA)
if ax then
ax.TitleFrame.Text=FormatValue(aA)
end
al.Value.Default=FormatValue(aA)
aq=aA
ae.SafeCallback(al.Callback,FormatValue(aA))
end

an=ad.RenderStepped:Connect(function()
local f=am and aB.Position.X or ac:GetMouseLocation().X
local g=math.clamp(
(f-al.UIElements.SliderIcon.AbsolutePosition.X)
/al.UIElements.SliderIcon.AbsoluteSize.X,
0,
1
)
aA=CalculateValue(al.Value.Min+g*(al.Value.Max-al.Value.Min))

if aA~=aq then
ag(al.UIElements.SliderIcon.Frame,0.05,{Size=UDim2.new(g,0,1,0)}):Play()
al.UIElements.SliderContainer.TextBox.Text=FormatValue(aA)
if ax then
ax.TitleFrame.Text=FormatValue(aA)
end
al.Value.Default=FormatValue(aA)
aq=aA
ae.SafeCallback(al.Callback,FormatValue(aA))
end
end)


ao=ac.InputEnded:Connect(function(f)
if
(
f.UserInputType==Enum.UserInputType.MouseButton1
or f.UserInputType==Enum.UserInputType.Touch
)and aB==f
then
an:Disconnect()
ao:Disconnect()
ai=false
ay.ScrollingEnabled=true

ak.WindUI.CurrentInput=nil

if ak.Window.NewElements then
ag(al.UIElements.SliderIcon.Frame.Thumb,0.2,{
ImageTransparency=0,
Size=UDim2.new(
0,
ak.Window.NewElements and(al.ThumbSize*2)or(al.ThumbSize+2),
0,
ak.Window.NewElements and(al.ThumbSize+4)or(al.ThumbSize+2)
),
},Enum.EasingStyle.Quint,Enum.EasingDirection.InOut):Play()
end
if ax then
ax:Close(false)
end
end
end)
else
aA=math.clamp(aA,al.Value.Min or 0,al.Value.Max or 100)

local b=math.clamp(
(aA-(al.Value.Min or 0))/((al.Value.Max or 100)-(al.Value.Min or 0)),
0,
1
)
aA=CalculateValue(al.Value.Min+b*(al.Value.Max-al.Value.Min))

if aA~=aq then
ag(al.UIElements.SliderIcon.Frame,0.05,{Size=UDim2.new(b,0,1,0)}):Play()
al.UIElements.SliderContainer.TextBox.Text=FormatValue(aA)
if ax then
ax.TitleFrame.Text=FormatValue(aA)
end
al.Value.Default=FormatValue(aA)
aq=aA
ae.SafeCallback(al.Callback,FormatValue(aA))
end
end
end
end
end

function al.SetMax(az,aA)
al.Value.Max=aA

local aB=tonumber(al.Value.Default)or aq
if aB>aA then
al:Set(aA)
else
local b=
math.clamp((aB-(al.Value.Min or 0))/(aA-(al.Value.Min or 0)),0,1)
ag(al.UIElements.SliderIcon.Frame,0.1,{Size=UDim2.new(b,0,1,0)}):Play()
end
end

function al.SetMin(az,aA)
al.Value.Min=aA

local aB=tonumber(al.Value.Default)or aq
if aB<aA then
al:Set(aA)
else
local b=math.clamp((aB-aA)/((al.Value.Max or 100)-aA),0,1)
ag(al.UIElements.SliderIcon.Frame,0.1,{Size=UDim2.new(b,0,1,0)}):Play()
end
end

ae.AddSignal(al.UIElements.SliderContainer.TextBox.FocusLost,function(az)
local aA=tonumber(al.UIElements.SliderContainer.TextBox.Text)
if aA then
al:Set(aA)
else
al.UIElements.SliderContainer.TextBox.Text=FormatValue(aq)
if ax then
ax.TitleFrame.Text=FormatValue(aq)
end
end
end)

local az=ak.WindUI.GenerateGUID()

ae.AddSignal(al.UIElements.SliderContainer.InputBegan,function(aA)
if al.Locked or ai then
return
end
if
aA.UserInputType==Enum.UserInputType.MouseButton1
or aA.UserInputType==Enum.UserInputType.Touch
then
if ak.WindUI.CurrentInput and ak.WindUI.CurrentInput~=az then
return
end
ak.WindUI.CurrentInput=az

al:Set(ap,aA)


if ak.Window.NewElements then
ag(al.UIElements.SliderIcon.Frame.Thumb,0.24,{
ImageTransparency=0.85,
Size=UDim2.new(
0,
(ak.Window.NewElements and(al.ThumbSize*2)or al.ThumbSize)+8,
0,
al.ThumbSize+8
),
},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
end
if ax then
ax:Open()
end

end
end)

return al.__type,al
end

return ah end function a.J()

local aa=a.load'd'
local ac=aa.New
local ad=aa.Tween

local ae={}

local function ToFiniteNumber(af)
local ag=tonumber(af)
if ag==nil or ag~=ag or math.abs(ag)==math.huge then
return nil
end

return ag
end

local function FormatNumber(af)
if af%1==0 then
return tostring(af)
end

return tostring(tonumber(string.format("%.2f",af)))
end

function ae.New(af,ag)
local ah=typeof(ag.Value)=="table"and ag.Value or{}
local ai=ToFiniteNumber(ah.Min)or ToFiniteNumber(ag.Min)or 0
local aj=ToFiniteNumber(ah.Max)or ToFiniteNumber(ag.Max)or 100

if ai>aj then
ai,aj=aj,ai
end

local ak=typeof(ag.Value)=="number"and ag.Value
or ToFiniteNumber(ah.Default)
or ToFiniteNumber(ag.Default)
or ai
ak=ToFiniteNumber(ak)or ai

local al=ag.Indeterminate==true

local am=ag.ShowValue
if am==nil then
am=not al
end

local an=math.max(ToFiniteNumber(ag.ValueWidth)or 44,0)

local ao={
__type="ProgressBar",
Title=ag.Title or"Progress",
Desc=ag.Desc or nil,
Value={
Min=ai,
Max=aj,
Default=math.clamp(ak,ai,aj),
},
ShowValue=am,
DisplayMode=ag.DisplayMode or"Percent",
Format=ag.Format,
Animate=ag.Animate~=false,
AnimationDuration=math.max(ToFiniteNumber(ag.AnimationDuration)or 0.15,0),
Indeterminate=al,
IndeterminateText=ag.IndeterminateText or"",
Speed=math.max(ToFiniteNumber(ag.Speed)or 1,0.01),
ControlGap=math.max(ToFiniteNumber(ag.ControlGap)or 16,0),
UIElements={},

Width=math.max(ToFiniteNumber(ag.Width)or 160,0),
ValueWidth=an,
}

local function GetRatio(ap)
if ao.Value.Max==ao.Value.Min then
return ap>=ao.Value.Max and 1 or 0
end

return math.clamp((ap-ao.Value.Min)/(ao.Value.Max-ao.Value.Min),0,1)
end

local function GetValueText(ap,aq)
if ao.Indeterminate then
return tostring(ao.IndeterminateText)
end

local ar=aq*100

if typeof(ao.Format)=="function"then
local as,at=
pcall(ao.Format,ap,ar,ao.Value.Min,ao.Value.Max)

if as and at~=nil then
return tostring(at)
end
end

if ao.DisplayMode=="Value"then
return FormatNumber(ap)
elseif ao.DisplayMode=="Fraction"then
return FormatNumber(ap).."/"..FormatNumber(ao.Value.Max)
end

return tostring(math.floor(ar+0.5)).."%"
end

ao.ProgressBarFrame=a.load'C'{
Title=ao.Title,
Desc=ao.Desc,
Parent=ag.Parent,
TextOffset=ao.Width+ao.ControlGap,
Hover=false,
Tab=ag.Tab,
Index=ag.Index,
Window=ag.Window,
ElementTable=ao,
ParentConfig=ag,
Tags=ag.Tags,
}

ao.UIElements.Fill=aa.NewRoundFrame(99,"Squircle",{
Name="Fill",
Size=ao.Indeterminate and UDim2.new(0.3,0,1,0)
or UDim2.new(GetRatio(ao.Value.Default),0,1,0),
Position=ao.Indeterminate and UDim2.new(-0.3,0,0,0)or UDim2.new(0,0,0,0),
ThemeTag={
ImageColor3="ProgressBar",
},
})

ao.UIElements.Bar=aa.NewRoundFrame(99,"Squircle",{
Name="Bar",
Size=UDim2.new(1,ao.ShowValue and-(ao.ValueWidth+8)or 0,0,6),
ClipsDescendants=true,
ImageTransparency=0.9,
ThemeTag={
ImageColor3="ProgressBarTrack",
ImageTransparency="ProgressBarTrackTransparency",
},
},{
ao.UIElements.Fill,
})

ao.UIElements.Value=ac("TextLabel",{
Name="Value",
Size=UDim2.new(0,ao.ValueWidth,0,20),
BackgroundTransparency=1,
FontFace=Font.new(aa.Font,Enum.FontWeight.Medium),
Text=GetValueText(ao.Value.Default,GetRatio(ao.Value.Default)),
TextSize=14,
TextTransparency=0.25,
TextTruncate="AtEnd",
TextXAlignment="Right",
Visible=ao.ShowValue,
ThemeTag={
TextColor3="ProgressBarText",
},
})

ao.UIElements.Container=ac("Frame",{
Name="ProgressBarContainer",
Size=UDim2.new(0,ao.Width,0,36),
Position=UDim2.new(1,0,ag.Window.NewElements and 0 or 0.5,0),
AnchorPoint=Vector2.new(1,ag.Window.NewElements and 0 or 0.5),
BackgroundTransparency=1,
Parent=ao.ProgressBarFrame.UIElements.Main,
},{
ac("UIListLayout",{
Padding=UDim.new(0,8),
FillDirection="Horizontal",
HorizontalAlignment="Right",
VerticalAlignment="Center",
}),
ao.UIElements.Bar,
ao.UIElements.Value,
})

if ao.Indeterminate then
local ap=ad(
ao.UIElements.Fill,
1/ao.Speed,
{Position=UDim2.new(1,0,0,0)},
Enum.EasingStyle.Linear,
Enum.EasingDirection.InOut,-1

)
aa.AddSignal(ao.UIElements.Bar.Destroying,function()
ap:Cancel()
end)
ap:Play()
end

local function Update(ap,aq)
local ar=ToFiniteNumber(ap)
if ar==nil then
return ao.Value.Default
end

ar=math.clamp(ar,ao.Value.Min,ao.Value.Max)
ao.Value.Default=ar

local as=GetRatio(ar)
local at=UDim2.new(as,0,1,0)

if ao.UIElements.Fill and not ao.Indeterminate then
if aq or not ao.Animate or ao.AnimationDuration<=0 then
ao.UIElements.Fill.Size=at
else
ad(
ao.UIElements.Fill,
ao.AnimationDuration,
{Size=at},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()
end
end

ao.UIElements.Value.Text=GetValueText(ar,as)

return ar
end

function ao.Set(ap,aq)
return Update(aq,false)
end

function ao.Get(ap)
return ao.Value.Default
end

function ao.GetPercentage(ap)
return GetRatio(ao.Value.Default)*100
end

function ao.SetRange(ap,aq,ar)
aq=ToFiniteNumber(aq)
ar=ToFiniteNumber(ar)

if aq==nil or ar==nil then
return ao.Value.Min,ao.Value.Max
end

if aq>ar then
aq,ar=ar,aq
end

ao.Value.Min=aq
ao.Value.Max=ar
Update(ao.Value.Default,false)

return aq,ar
end

function ao.SetMin(ap,aq)
aq=ToFiniteNumber(aq)
if aq==nil then
return ao.Value.Min
end

ao:SetRange(aq,math.max(aq,ao.Value.Max))
return ao.Value.Min
end

function ao.SetMax(ap,aq)
aq=ToFiniteNumber(aq)
if aq==nil then
return ao.Value.Max
end

ao:SetRange(math.min(ao.Value.Min,aq),aq)
return ao.Value.Max
end

Update(ao.Value.Default,true)

return ao.__type,ao
end

return ae end function a.K()

local aa=(cloneref or clonereference or function(aa)
return aa
end)

local ac=aa(game:GetService"UserInputService")

local ad=a.load'd'
local ae=ad.New local af=
ad.Tween

local ag={
UICorner=6,
UIPadding=8,
}

local ah=a.load'w'.New

function ag.New(ai,aj)
local function NormalizeKeyCode(ak)
if typeof(ak)=="EnumItem"then
return ak.Name
elseif type(ak)=="string"then
return ak
else
return"F"
end
end

local ak={
__type="Keybind",
Title=aj.Title or"Keybind",
Desc=aj.Desc or nil,
Locked=aj.Locked or false,
LockedTitle=aj.LockedTitle,
Value=NormalizeKeyCode(aj.Value)or"F",
Callback=aj.Callback or function()end,
CanChange=aj.CanChange~=false,
Blacklist=aj.Blacklist or{},
Picking=false,
UIElements={},
}

local al={}

for am,an in next,ak.Blacklist do
table.insert(al,Enum.KeyCode[NormalizeKeyCode(an)])
end
table.insert(al,Enum.KeyCode[NormalizeKeyCode"Escape"])

local am=true

ak.KeybindFrame=a.load'C'{
Title=ak.Title,
Desc=ak.Desc,
Parent=aj.Parent,
TextOffset=85,
Hover=ak.CanChange,
Tab=aj.Tab,
Index=aj.Index,
Window=aj.Window,
ElementTable=ak,
ParentConfig=aj,
Tags=aj.Tags,
}

ak.UIElements.Keybind=ah(
ak.Value,
nil,
ak.KeybindFrame.UIElements.Main,
nil,
aj.Window.NewElements and 12 or 10
)

ak.UIElements.Keybind.Size=
UDim2.new(0,24+ak.UIElements.Keybind.Frame.Frame.TextLabel.TextBounds.X,0,42)
ak.UIElements.Keybind.AnchorPoint=Vector2.new(1,0.5)
ak.UIElements.Keybind.Position=UDim2.new(1,0,0.5,0)
ak.UIElements.Keybind.Interactable=false

ae("UIScale",{
Parent=ak.UIElements.Keybind,
Scale=0.85,
})

ad.AddSignal(
ak.UIElements.Keybind.Frame.Frame.TextLabel:GetPropertyChangedSignal"TextBounds",
function()
ak.UIElements.Keybind.Size=
UDim2.new(0,24+ak.UIElements.Keybind.Frame.Frame.TextLabel.TextBounds.X,0,42)
end
)

function ak.Lock(an)
ak.Locked=true
am=false
return ak.KeybindFrame:Lock(ak.LockedTitle)
end
function ak.Unlock(an)
ak.Locked=false
am=true
return ak.KeybindFrame:Unlock()
end

function ak.Set(an,ao)
local ap=NormalizeKeyCode(ao)
ak.Value=ap
ak.UIElements.Keybind.Frame.Frame.TextLabel.Text=ap
end

if ak.Locked then
ak:Lock()
end

local an

ad.AddSignal(ak.KeybindFrame.UIElements.Main.MouseButton1Click,function()
if am then
if ak.CanChange then
ak.Picking=true
ak.UIElements.Keybind.Frame.Frame.TextLabel.Text="..."



local ao
ao=ac.InputBegan:Connect(function(ap)
local aq

if ap.UserInputType==Enum.UserInputType.Keyboard then
if table.find(al,ap.KeyCode)then
aq=nil
return
else
aq=ap.KeyCode.Name
end
elseif
ap.UserInputType==Enum.UserInputType.MouseButton1
and not table.find(al,"MouseLeftButton")
then
aq="MouseLeftButton"
elseif
ap.UserInputType==Enum.UserInputType.MouseButton2
and not table.find(al,"MouseRightButton")
then
aq="MouseRightButton"
end

if an then
an:Disconnect()
end

an=ac.InputEnded:Connect(function(ar)
if
aq
and(
ar.KeyCode.Name==aq
or aq=="MouseLeft"and ar.UserInputType==Enum.UserInputType.MouseButton1
or aq=="MouseRight"and ar.UserInputType==Enum.UserInputType.MouseButton2
)
then
ak.Picking=false

ak.UIElements.Keybind.Frame.Frame.TextLabel.Text=aq
ak.Value=aq

ao:Disconnect()
an:Disconnect()
end
end)
end)
end
end
end)

ad.AddSignal(ac.InputBegan,function(ao,ap)
if ac:GetFocusedTextBox()then
return
end
if not am then
return
end
if ak.Picking then
return
end

if ao.UserInputType==Enum.UserInputType.Keyboard then
if ao.KeyCode.Name==ak.Value then
ad.SafeCallback(ak.Callback,ao.KeyCode.Name)
end
elseif ao.UserInputType==Enum.UserInputType.MouseButton1 and ak.Value=="MouseLeft"then
ad.SafeCallback(ak.Callback,"MouseLeft")
elseif ao.UserInputType==Enum.UserInputType.MouseButton2 and ak.Value=="MouseRight"then
ad.SafeCallback(ak.Callback,"MouseRight")
end
end)

return ak.__type,ak
end

return ag end function a.L()

local aa=a.load'd'local ac=
aa.New local ad=
aa.Tween

local ae={
UICorner=8,
UIPadding=8,
}local af=a.load'm'

.New
local ag=a.load'n'.New

function ae.New(ah,ai)
local aj={
__type="Input",
Title=ai.Title or"Input",
Desc=ai.Desc or nil,
Type=ai.Type or"Input",
Locked=ai.Locked or false,
LockedTitle=ai.LockedTitle,
InputIcon=ai.InputIcon or false,
Placeholder=ai.Placeholder or"Enter Text...",
Value=ai.Value or"",
Callback=ai.Callback or function()end,
ClearTextOnFocus=ai.ClearTextOnFocus or false,
UIElements={},

Width=150,
}

local ak=true

aj.InputFrame=a.load'C'{
Title=aj.Title,
Desc=aj.Desc,
Parent=ai.Parent,
TextOffset=aj.Width,
Hover=false,
Tab=ai.Tab,
Index=ai.Index,
Window=ai.Window,
ElementTable=aj,
ParentConfig=ai,
Tags=ai.Tags,
}

local al=ag(
aj.Placeholder,
aj.InputIcon,
aj.Type=="Textarea"and aj.InputFrame.UIElements.Container or aj.InputFrame.UIElements.Main,
aj.Type,
function(al)
aj:Set(al,true)
end,
nil,
ai.Window.NewElements and 12 or 10,
aj.ClearTextOnFocus
)

if aj.Type~="Textarea"then
al.Size=UDim2.new(0,aj.Width,0,36)
al.Position=UDim2.new(1,0,ai.Window.NewElements and 0 or 0.5,0)
al.AnchorPoint=Vector2.new(1,ai.Window.NewElements and 0 or 0.5)
else
al.Size=UDim2.new(1,0,0,148)
end






function aj.Lock(am)
aj.Locked=true
ak=false
return aj.InputFrame:Lock(aj.LockedTitle)
end
function aj.Unlock(am)
aj.Locked=false
ak=true
return aj.InputFrame:Unlock()
end

function aj.Set(am,an,ao)
if ak then
aj.Value=an
aa.SafeCallback(aj.Callback,an)

if not ao then
al.Frame.Frame.TextBox.Text=an
end
end
end

function aj.SetPlaceholder(am,an)
al.Frame.Frame.TextBox.PlaceholderText=an
aj.Placeholder=an
end

aj:Set(aj.Value)

if aj.Locked then
aj:Lock()
end

return aj.__type,aj
end

return ae end function a.M()

local aa=a.load'd'
local ae=aa.New

local af={}

function af.New(ag,ah)
local ai=ae("Frame",{
Size=ah.ParentType~="Group"and UDim2.new(1,0,0,1)or UDim2.new(0,1,1,0),
Position=UDim2.new(0.5,0,0.5,0),
AnchorPoint=Vector2.new(0.5,0.5),
BackgroundTransparency=.9,
ThemeTag={
BackgroundColor3="Text"
}
})
local aj=ae("Frame",{
Parent=ah.Parent,
Size=ah.ParentType~="Group"and UDim2.new(1,-7,0,7)or UDim2.new(0,7,1,-7),
BackgroundTransparency=1,
},{
ai
})

return"Divider",{__type="Divider",ElementFrame=aj}
end

return af end function a.N()
local aa={}

local ae=(cloneref or clonereference or function(ae)
return ae
end)

local af=ae(game:GetService"UserInputService")
local ag=ae(game:GetService"Players").LocalPlayer:GetMouse()
local ah=ae(game:GetService"Workspace").CurrentCamera local ai=

workspace.CurrentCamera

local aj=a.load'n'.New

local ak=a.load'd'
local al=ak.New
local am=ak.Tween

local an=0.67

function aa.New(ao,ap,aq,ar)
local as={}

if not ap.Callback then
ar="Menu"
end

ap.UIElements.UIListLayout=al("UIListLayout",{
Padding=UDim.new(0,aq.MenuPadding/1.5),
FillDirection="Vertical",
HorizontalAlignment="Center",
})

ap.UIElements.Menu=ak.NewRoundFrame(aq.MenuCorner,"Squircle",{
ThemeTag={
ImageColor3="DropdownBackground",
},
ImageTransparency=1,
Size=UDim2.new(1,0,1,0),
AnchorPoint=Vector2.new(1,0),
Position=UDim2.new(1,0,0,0),
},{
al("UIPadding",{
PaddingTop=UDim.new(0,aq.MenuPadding),
PaddingLeft=UDim.new(0,aq.MenuPadding),
PaddingRight=UDim.new(0,aq.MenuPadding),
PaddingBottom=UDim.new(0,aq.MenuPadding),
}),
al("UIListLayout",{
FillDirection="Vertical",
Padding=UDim.new(0,aq.MenuPadding),
}),
al("Frame",{
BackgroundTransparency=1,
Size=UDim2.new(1,0,1,ap.SearchBarEnabled and-aq.MenuPadding-aq.SearchBarHeight),

ClipsDescendants=true,
LayoutOrder=999,
Name="Frame",
},{
al("UICorner",{
CornerRadius=UDim.new(0,aq.MenuCorner-aq.MenuPadding),
}),
al("ScrollingFrame",{
Size=UDim2.new(1,0,1,0),
ScrollBarThickness=0,
ScrollingDirection="Y",
AutomaticCanvasSize="Y",
CanvasSize=UDim2.new(0,0,0,0),
BackgroundTransparency=1,
ScrollBarImageTransparency=1,
},{
ap.UIElements.UIListLayout,
}),
}),
})

ap.UIElements.MenuCanvas=al("Frame",{
Size=UDim2.new(0,ap.MenuWidth,0,300),
BackgroundTransparency=1,
Position=UDim2.new(-10,0,-10,0),
Visible=false,
Active=false,

Parent=ao.WindUI.DropdownGui,
AnchorPoint=Vector2.new(1,0),
},{
ap.UIElements.Menu,
al("UISizeConstraint",{
MinSize=Vector2.new(170,0),
MaxSize=Vector2.new(300,400),
}),
})

local function RecalculateCanvasSize()
ap.UIElements.Menu.Frame.ScrollingFrame.CanvasSize=
UDim2.fromOffset(0,ap.UIElements.UIListLayout.AbsoluteContentSize.Y)
end

local function RecalculateListSize()
local at=ao.WindUI.DropdownGui.AbsoluteSize.Y

local au=ap.UIElements.UIListLayout.AbsoluteContentSize.Y/ao.UIScale
local av=ap.SearchBarEnabled and(aq.SearchBarHeight+(aq.MenuPadding*3))
or(aq.MenuPadding*2)
local aw=au+av

if aw>at then
ap.UIElements.MenuCanvas.Size=
UDim2.fromOffset(ap.UIElements.MenuCanvas.AbsoluteSize.X,at)
else
ap.UIElements.MenuCanvas.Size=
UDim2.fromOffset(ap.UIElements.MenuCanvas.AbsoluteSize.X,aw)
end
end

function UpdatePosition()
local at=ap.UIElements.Dropdown or ap.DropdownFrame.UIElements.Main
local au=ap.UIElements.MenuCanvas

local av=ah.ViewportSize.Y
-(at.AbsolutePosition.Y+at.AbsoluteSize.Y)
-aq.MenuPadding
-54
local aw=au.AbsoluteSize.Y+aq.MenuPadding

local ax=-54
if av<aw then
ax=aw-av-54
end

au.Position=UDim2.new(
0,
at.AbsolutePosition.X+at.AbsoluteSize.X,
0,
at.AbsolutePosition.Y+at.AbsoluteSize.Y-ax+(aq.MenuPadding*2)
)
end

local at

function as.Display(au)
local av=ap.Values
local aw=""

if ap.Multi then
local ax={}
if typeof(ap.Value)=="table"then
for ay,az in ipairs(ap.Value)do
local aA=typeof(az)=="table"and az.Title or az
ax[aA]=true
end
end

for ay,az in ipairs(av)do
local aA=typeof(az)=="table"and az.Title or az
if ax[aA]then
aw=aw..aA..", "
end
end

if#aw>0 then
aw=aw:sub(1,#aw-2)
end
else
aw=typeof(ap.Value)=="table"and(ap.Value.Title or ap.Value[1])
or ap.Value
or""
end

if ap.UIElements.Dropdown then
ap.UIElements.Dropdown.Frame.Frame.TextLabel.Text=(aw==""and"--"or aw)
end
end

local function Callback(au)
as:Display()
if ap.Locked then
return
end

if ap.Callback then
task.spawn(function()
if ap.Locked then
return
end
ak.SafeCallback(ap.Callback,ap.Value)
end)
else
task.spawn(function()
if ap.Locked then
return
end
ak.SafeCallback(au)
end)
end
end

function as.LockValues(au,av)
if not av then
return
end

for aw,ax in next,ap.Tabs do
if ax and ax.UIElements and ax.UIElements.TabItem then
local ay=ax.Name
local az=false

for aA,aB in next,av do
if ay==aB then
az=true
break
end
end

if az then
am(ax.UIElements.TabItem,0.1,{ImageTransparency=1}):Play()

am(ax.UIElements.TabItem.Frame.Title.TextLabel,0.1,{TextTransparency=0.6}):Play()
if ax.UIElements.TabIcon then
am(ax.UIElements.TabIcon.ImageLabel,0.1,{ImageTransparency=0.6}):Play()
end

ax.UIElements.TabItem.Active=false
ax.Locked=true
else
if ax.Selected then
am(ax.UIElements.TabItem,0.1,{ImageTransparency=an}):Play()

am(ax.UIElements.TabItem.Frame.Title.TextLabel,0.1,{TextTransparency=0}):Play()
if ax.UIElements.TabIcon then
am(ax.UIElements.TabIcon.ImageLabel,0.1,{ImageTransparency=0}):Play()
end
else
am(ax.UIElements.TabItem,0.1,{ImageTransparency=1}):Play()

am(
ax.UIElements.TabItem.Frame.Title.TextLabel,
0.1,
{TextTransparency=ar=="Dropdown"and 0.4 or 0.05}
):Play()
if ax.UIElements.TabIcon then
am(
ax.UIElements.TabIcon.ImageLabel,
0.1,
{ImageTransparency=ar=="Dropdown"and 0.2 or 0}
):Play()
end
end

ax.UIElements.TabItem.Active=true
ax.Locked=false
end
end
end
end

-- [patch] pilihan yang lagi ke-select naik ke baris paling atas (dipanggil tiap
-- menu dibuka & abis Refresh). Cuma ganti LayoutOrder, nggak bangun ulang row.
function as.SortSelectedFirst(au)
for aw,ax in next,ap.Tabs do
local ti=ax and ax.UIElements and ax.UIElements.TabItem
if ti then
local base=typeof(aw)=="number"and aw or 0
ti.LayoutOrder=(ax.Selected and 0 or 1000000)+base
end
end
pcall(function()
ap.UIElements.Menu.Frame.ScrollingFrame.CanvasPosition=Vector2.new(0,0)
end)
end

function as.Refresh(au,av)
if ao.Window.Destroyed then
return
end

for aw,ax in next,ap.UIElements.Menu.Frame.ScrollingFrame:GetChildren()do
if not ax:IsA"UIListLayout"then
ax:Destroy()
end
end

ap.Tabs={}

if ap.SearchBarEnabled then
if not at then
at=aj("Search...","search",ap.UIElements.Menu,nil,function(aw)
local q=string.lower(aw)
for ax,ay in next,ap.Tabs do
ay.UIElements.TabItem.Visible=string.find(string.lower(ay.Name),q,1,true)~=nil
end
-- [patch] recalc SEKALI setelah loop (dulu per-row = O(n^2) + layout paksa tiap row)
RecalculateListSize()
RecalculateCanvasSize()
end,true)
at.Size=UDim2.new(1,0,0,aq.SearchBarHeight)
at.Position=UDim2.new(0,0,0,0)
at.Name="SearchBar"
end
end

for aw,ax in next,av do
if ax.Type~="Divider"then
local ay={
Name=typeof(ax)=="table"and ax.Title or ax,
Desc=typeof(ax)=="table"and ax.Desc or nil,
Icon=typeof(ax)=="table"and ax.Icon or nil,
IconSize=typeof(ax)=="table"and ax.IconSize or nil,
Original=ax,
Selected=false,
Locked=typeof(ax)=="table"and ax.Locked or false,
UIElements={},
}
local az
if ay.Icon then
az=ak.Image(ay.Icon,ay.Icon,0,ao.Window.Folder,"Dropdown",true)
az.Size=
UDim2.new(0,ay.IconSize or aq.TabIcon,0,ay.IconSize or aq.TabIcon)
az.ImageLabel.ImageTransparency=ar=="Dropdown"and 0.2 or 0
ay.UIElements.TabIcon=az
end
ay.UIElements.TabItem=ak.NewRoundFrame(
aq.MenuCorner-aq.MenuPadding,
"Squircle",
{
Size=UDim2.new(1,0,0,36),
AutomaticSize=ay.Desc and"Y",
ImageTransparency=1,
Parent=ap.UIElements.Menu.Frame.ScrollingFrame,

ThemeTag={
ImageColor3="DropdownTabBackground",
},
Active=not ay.Locked,
},
{
ak.NewRoundFrame(aq.MenuCorner-aq.MenuPadding,"Glass-1.4",{
Size=UDim2.new(1,0,1,0),
ThemeTag={
ImageColor3="DropdownTabBorder",
},
ImageTransparency=1,
Name="Highlight",
},{













}),
al("Frame",{
Size=UDim2.new(1,0,1,0),
BackgroundTransparency=1,
},{
al("UIListLayout",{
Padding=UDim.new(0,aq.TabPadding),
FillDirection="Horizontal",
VerticalAlignment="Center",
}),
al("UIPadding",{
PaddingTop=UDim.new(0,aq.TabPadding),
PaddingLeft=UDim.new(0,aq.TabPadding),
PaddingRight=UDim.new(0,aq.TabPadding),
PaddingBottom=UDim.new(0,aq.TabPadding),
}),
al("UICorner",{
CornerRadius=UDim.new(0,aq.MenuCorner-aq.MenuPadding),
}),
az,
al("Frame",{
Size=UDim2.new(1,az and-aq.TabPadding-aq.TabIcon or 0,0,0),
BackgroundTransparency=1,
AutomaticSize="Y",
Name="Title",
},{
al("TextLabel",{
Text=ay.Name,
TextXAlignment="Left",
FontFace=Font.new(ak.Font,Enum.FontWeight.Medium),
ThemeTag={
TextColor3="Text",
BackgroundColor3="Text",
},
TextSize=15,
BackgroundTransparency=1,
TextTransparency=ar=="Dropdown"and 0.4 or 0.05,
LayoutOrder=999,
AutomaticSize="Y",
Size=UDim2.new(1,0,0,0),
}),
al("TextLabel",{
Text=ay.Desc or"",
TextXAlignment="Left",
FontFace=Font.new(ak.Font,Enum.FontWeight.Regular),
ThemeTag={
TextColor3="Text",
BackgroundColor3="Text",
},
TextSize=15,
BackgroundTransparency=1,
TextTransparency=ar=="Dropdown"and 0.6 or 0.35,
LayoutOrder=999,
AutomaticSize="Y",
TextWrapped=true,
Size=UDim2.new(1,0,0,0),
Visible=ay.Desc and true or false,
Name="Desc",
}),
al("UIListLayout",{
Padding=UDim.new(0,aq.TabPadding/3),
FillDirection="Vertical",
}),
}),
}),
},
true
)

if ay.Locked then
ay.UIElements.TabItem.Frame.Title.TextLabel.TextTransparency=0.6
if ay.UIElements.TabIcon then
ay.UIElements.TabIcon.ImageLabel.ImageTransparency=0.6
end
end

if ap.Multi and typeof(ap.Value)=="string"then
for aA,aB in next,ap.Values do
if typeof(aB)=="table"then
if aB.Title==ap.Value then
ap.Value={aB}
end
else
if aB==ap.Value then
ap.Value={ap.Value}
end
end
end
end

if ap.Multi then
local aA=false
if typeof(ap.Value)=="table"then
for aB,b in ipairs(ap.Value)do
local d=typeof(b)=="table"and b.Title or b
if d==ay.Name then
aA=true
break
end
end
end
ay.Selected=aA
else
local aA=typeof(ap.Value)=="table"and ap.Value.Title or ap.Value
ay.Selected=aA==ay.Name
end

if ay.Selected and not ay.Locked then
ay.UIElements.TabItem.ImageTransparency=an

ay.UIElements.TabItem.Frame.Title.TextLabel.TextTransparency=0
if ay.UIElements.TabIcon then
ay.UIElements.TabIcon.ImageLabel.ImageTransparency=0
end
end

ap.Tabs[aw]=ay
-- [patch] urutan eksplisit (dipakai SortSelectedFirst); Display dipindah ke luar loop
if typeof(aw)=="number"then ay.UIElements.TabItem.LayoutOrder=aw end

if ar=="Dropdown"then
ak.AddSignal(ay.UIElements.TabItem.MouseButton1Click,function()
if ap.Locked or ay.Locked then
return
end

if ap.Multi then
if not ay.Selected then
ay.Selected=true
am(
ay.UIElements.TabItem,
0.1,
{ImageTransparency=an}
):Play()

am(ay.UIElements.TabItem.Frame.Title.TextLabel,0.1,{TextTransparency=0}):Play()
if ay.UIElements.TabIcon then
am(ay.UIElements.TabIcon.ImageLabel,0.1,{ImageTransparency=0}):Play()
end
table.insert(ap.Value,ay.Original)
else
if not ap.AllowNone and#ap.Value==1 then
return
end
ay.Selected=false
am(ay.UIElements.TabItem,0.1,{ImageTransparency=1}):Play()

am(ay.UIElements.TabItem.Frame.Title.TextLabel,0.1,{TextTransparency=0.4}):Play()
if ay.UIElements.TabIcon then
am(ay.UIElements.TabIcon.ImageLabel,0.1,{ImageTransparency=0.2}):Play()
end

for aA,aB in next,ap.Value do
if typeof(aB)=="table"and(aB.Title==ay.Name)or(aB==ay.Name)then
table.remove(ap.Value,aA)
break
end
end
end
else
for aA,aB in next,ap.Tabs do
am(aB.UIElements.TabItem,0.1,{ImageTransparency=1}):Play()

am(
aB.UIElements.TabItem.Frame.Title.TextLabel,
0.1,
{TextTransparency=0.4}
):Play()
if aB.UIElements.TabIcon then
am(aB.UIElements.TabIcon.ImageLabel,0.1,{ImageTransparency=0.2}):Play()
end
aB.Selected=false
end
ay.Selected=true
am(ay.UIElements.TabItem,0.1,{ImageTransparency=an}):Play()

am(ay.UIElements.TabItem.Frame.Title.TextLabel,0.1,{TextTransparency=0}):Play()
if ay.UIElements.TabIcon then
am(ay.UIElements.TabIcon.ImageLabel,0.1,{ImageTransparency=0}):Play()
end
ap.Value=ay.Original
end
Callback()
end)
elseif ar=="Menu"then
if not ay.Locked then
ak.AddSignal(ay.UIElements.TabItem.MouseEnter,function()
am(ay.UIElements.TabItem,0.08,{ImageTransparency=an}):Play()
end)
ak.AddSignal(ay.UIElements.TabItem.InputEnded,function()
am(ay.UIElements.TabItem,0.08,{ImageTransparency=1}):Play()
end)
end
ak.AddSignal(ay.UIElements.TabItem.MouseButton1Click,function()
if ap.Locked or ay.Locked then
return
end
Callback(ax.Callback or function()end)
end)
end
else a.load'M'
:New{Parent=ap.UIElements.Menu.Frame.ScrollingFrame}
end
end

-- [patch] Display + recalc SEKALI (dulu tiap row: O(n^2) & layout paksa -> freeze)
as:Display()
if ar=="Dropdown"then as:SortSelectedFirst()end
RecalculateCanvasSize()
RecalculateListSize()










ap.UIElements.MenuCanvas.Size=UDim2.new(
0,
ap.MenuWidth+6+6+5+5+18+6+6,
ap.UIElements.MenuCanvas.Size.Y.Scale,
ap.UIElements.MenuCanvas.Size.Y.Offset
)
Callback()

ap.Values=av
end

as:Refresh(ap.Values)

function as.Select(au,av)
if av then
ap.Value=av
else
if ap.Multi then
ap.Value={}
else
ap.Value=nil
end
end
as:Refresh(ap.Values)
end

RecalculateListSize()
RecalculateCanvasSize()

function as.Open(au)
if not ap.Locked then
if ar=="Dropdown"then pcall(as.SortSelectedFirst,as)end
ap.UIElements.Menu.Visible=true
ap.UIElements.MenuCanvas.Visible=true
ap.UIElements.MenuCanvas.Active=true
ap.UIElements.Menu.Size=UDim2.new(1,0,0,0)
am(ap.UIElements.Menu,0.1,{
Size=UDim2.new(1,0,1,0),
ImageTransparency=0,
},Enum.EasingStyle.Quart,Enum.EasingDirection.Out):Play()

task.spawn(function()
task.wait(0.1)
if ap.Locked then
return
end
ap.Opened=true
end)

UpdatePosition()
end
end

function as.Close(au)
ap.Opened=false

am(ap.UIElements.Menu,0.25,{
Size=UDim2.new(1,0,0,0),
ImageTransparency=1,
},Enum.EasingStyle.Quart,Enum.EasingDirection.Out):Play()

task.spawn(function()
task.wait(0.1)
ap.UIElements.Menu.Visible=false
end)

task.spawn(function()
task.wait(0.25)
ap.UIElements.MenuCanvas.Visible=false
ap.UIElements.MenuCanvas.Active=false
end)
end

ak.AddSignal(
(
ap.UIElements.Dropdown and ap.UIElements.Dropdown.MouseButton1Click
or ap.DropdownFrame.UIElements.Main.MouseButton1Click
),
function()
as:Open()
end
)

ak.AddSignal(af.InputBegan,function(au)
if
au.UserInputType==Enum.UserInputType.MouseButton1
or au.UserInputType==Enum.UserInputType.Touch
then
local av=ap.UIElements.MenuCanvas
local aw,ax=av.AbsolutePosition,av.AbsoluteSize

local ay=ap.UIElements.Dropdown or ap.DropdownFrame.UIElements.Main
local az=ay.AbsolutePosition
local aA=ay.AbsoluteSize

local aB=ag.X>=az.X
and ag.X<=az.X+aA.X
and ag.Y>=az.Y
and ag.Y<=az.Y+aA.Y

local b=ag.X>=aw.X
and ag.X<=aw.X+ax.X
and ag.Y>=aw.Y
and ag.Y<=aw.Y+ax.Y

if ao.Window.CanDropdown and ap.Opened and not aB and not b then
as:Close()
end
end
end)

ak.AddSignal(
ap.UIElements.Dropdown and ap.UIElements.Dropdown:GetPropertyChangedSignal"AbsolutePosition"
or ap.DropdownFrame.UIElements.Main:GetPropertyChangedSignal"AbsolutePosition",
UpdatePosition
)

return as
end

return aa end function a.O()

local aa=(cloneref or clonereference or function(aa)
return aa
end)

aa(game:GetService"UserInputService")
aa(game:GetService"Players").LocalPlayer:GetMouse()local ae=
aa(game:GetService"Workspace").CurrentCamera

local af=a.load'd'
local ag=af.New local ah=
af.Tween

local ai=a.load'w'.New local aj=a.load'n'
.New
local ak=a.load'N'.New local al=

workspace.CurrentCamera

local am={
UICorner=10,
UIPadding=12,
MenuCorner=15,
MenuPadding=5,
TabPadding=10,
SearchBarHeight=39,
TabIcon=18,
}

function am.New(an,ao)
local ap={
__type="Dropdown",
Title=ao.Title or"Dropdown",
Desc=ao.Desc or nil,
Locked=ao.Locked or false,
LockedTitle=ao.LockedTitle,
Values=ao.Values or{},
MenuWidth=ao.MenuWidth or 180,
Value=ao.Value,
AllowNone=ao.AllowNone,
SearchBarEnabled=ao.SearchBarEnabled or false,
Multi=ao.Multi,
Callback=ao.Callback or nil,

UIElements={},

Opened=false,
Tabs={},

Width=150,
}

if ap.Multi and not ap.Value then
ap.Value={}
end
if ap.Values and typeof(ap.Value)=="number"then
ap.Value=ap.Values[ap.Value]
end

ap.DropdownFrame=a.load'C'{
Title=ap.Title,
Desc=ap.Desc,
Parent=ao.Parent,
TextOffset=ap.Callback and ap.Width or 20,
Hover=not ap.Callback and true or false,
Tab=ao.Tab,
Index=ao.Index,
Window=ao.Window,
ElementTable=ap,
ParentConfig=ao,
Tags=ao.Tags,
}

if ap.Callback then
ap.UIElements.Dropdown=
ai("",nil,ap.DropdownFrame.UIElements.Main,nil,ao.Window.NewElements and 12 or 10)

ap.UIElements.Dropdown.Frame.Frame.TextLabel.TextTruncate="AtEnd"
ap.UIElements.Dropdown.Frame.Frame.TextLabel.Size=
UDim2.new(1,ap.UIElements.Dropdown.Frame.Frame.TextLabel.Size.X.Offset-18-12-12,0,0)

ap.UIElements.Dropdown.Size=UDim2.new(0,ap.Width,0,36)
ap.UIElements.Dropdown.Position=UDim2.new(1,0,ao.Window.NewElements and 0 or 0.5,0)
ap.UIElements.Dropdown.AnchorPoint=Vector2.new(1,ao.Window.NewElements and 0 or 0.5)





end

ap.DropdownMenu=ak(ao,ap,am,"Dropdown")

ap.Display=ap.DropdownMenu.Display
ap.Refresh=ap.DropdownMenu.Refresh
ap.Select=ap.DropdownMenu.Select
ap.Open=ap.DropdownMenu.Open
ap.Close=ap.DropdownMenu.Close

ag("ImageLabel",{
Image=af.Icon"chevrons-up-down"[1],
ImageRectOffset=af.Icon"chevrons-up-down"[2].ImageRectPosition,
ImageRectSize=af.Icon"chevrons-up-down"[2].ImageRectSize,
Size=UDim2.new(0,18,0,18),
Position=UDim2.new(1,ap.UIElements.Dropdown and-12 or 0,0.5,0),
ThemeTag={
ImageColor3="Icon",
},
AnchorPoint=Vector2.new(1,0.5),
Parent=ap.UIElements.Dropdown and ap.UIElements.Dropdown.Frame
or ap.DropdownFrame.UIElements.Main,
})

function ap.Lock(aq)
ap.Locked=true
if ap.Opened or ap.UIElements.MenuCanvas.Visible then
ap:Close()
end
return ap.DropdownFrame:Lock(ap.LockedTitle)
end
function ap.Unlock(aq)
ap.Locked=false
return ap.DropdownFrame:Unlock()
end

if ap.Locked then
ap:Lock()
end

return ap.__type,ap
end

return am end function a.P()




local aa={}
local af={
lua={
"and",
"break",
"or",
"else",
"elseif",
"if",
"then",
"until",
"repeat",
"while",
"do",
"for",
"in",
"end",
"local",
"return",
"function",
"export",
},
rbx={
"game",
"workspace",
"script",
"math",
"string",
"table",
"task",
"wait",
"select",
"next",
"Enum",
"tick",
"assert",
"shared",
"loadstring",
"tonumber",
"tostring",
"type",
"typeof",
"unpack",
"Instance",
"CFrame",
"Vector3",
"Vector2",
"Color3",
"UDim",
"UDim2",
"Ray",
"BrickColor",
"OverlapParams",
"RaycastParams",
"Axes",
"Random",
"Region3",
"Rect",
"TweenInfo",
"collectgarbage",
"not",
"utf8",
"pcall",
"xpcall",
"_G",
"setmetatable",
"getmetatable",
"os",
"pairs",
"ipairs",
},
operators={
"#",
"+",
"-",
"*",
"%",
"/",
"^",
"=",
"~",
"=",
"<",
">",
},
}

local ag={
numbers=Color3.fromHex"#FAB387",
boolean=Color3.fromHex"#FAB387",
operator=Color3.fromHex"#94E2D5",
lua=Color3.fromHex"#CBA6F7",
rbx=Color3.fromHex"#F38BA8",
str=Color3.fromHex"#A6E3A1",
comment=Color3.fromHex"#9399B2",
null=Color3.fromHex"#F38BA8",
call=Color3.fromHex"#89B4FA",
self_call=Color3.fromHex"#89B4FA",
local_property=Color3.fromHex"#CBA6F7",
}

local function createKeywordSet(ai)
local ak={}
for al,am in ipairs(ai)do
ak[am]=true
end
return ak
end

local ai=createKeywordSet(af.lua)
local ak=createKeywordSet(af.rbx)
local al=createKeywordSet(af.operators)

local function getHighlight(am,an)
local ao=am[an]

if ag[ao.."_color"]then
return ag[ao.."_color"]
end

if tonumber(ao)then
return ag.numbers
elseif ao=="nil"then
return ag.null
elseif ao:sub(1,2)=="--"then
return ag.comment
elseif al[ao]then
return ag.operator
elseif ai[ao]then
return ag.lua
elseif ak[ao]then
return ag.rbx
elseif ao:sub(1,1)=='"'or ao:sub(1,1)=="'"then
return ag.str
elseif ao=="true"or ao=="false"then
return ag.boolean
end

if am[an+1]=="("then
if am[an-1]==":"then
return ag.self_call
end

return ag.call
end

if am[an-1]=="."then
if am[an-2]=="Enum"then
return ag.rbx
end

return ag.local_property
end
end

function aa.run(am,an)
if an~=nil then
for ao,ap in next,an do
ag[ao]=ap
end
end

local ao={}
local ap=""

local aq=false
local ar=false
local as=false

for at=1,#am do
local au=am:sub(at,at)

if ar then
if au=="\n"and not as then
table.insert(ao,ap)
table.insert(ao,au)
ap=""

ar=false
elseif am:sub(at-1,at)=="]]"and as then
ap=ap.."]"

table.insert(ao,ap)
ap=""

ar=false
as=false
else
ap=ap..au
end
elseif aq then
if au==aq and am:sub(at-1,at-1)~="\\"or au=="\n"then
ap=ap..au
aq=false
else
ap=ap..au
end
else
if am:sub(at,at+1)=="--"then
table.insert(ao,ap)
ap="-"
ar=true
as=am:sub(at+2,at+3)=="[["
elseif au=='"'or au=="'"then
table.insert(ao,ap)
ap=au
aq=au
elseif al[au]then
table.insert(ao,ap)
table.insert(ao,au)
ap=""
elseif au:match"[%w_]"then
ap=ap..au
else
table.insert(ao,ap)
table.insert(ao,au)
ap=""
end
end
end

table.insert(ao,ap)

local at={}

for au,av in ipairs(ao)do
local aw=getHighlight(ao,au)

if aw then
local ax=string.format(
'<font color = "#%s">%s</font>',
aw:ToHex(),
av:gsub("<","&lt;"):gsub(">","&gt;")
)

table.insert(at,ax)
else
table.insert(at,av)
end
end

return table.concat(at)
end

return aa end function a.Q()

local aa={}

local af=a.load'd'
local ag=af.New
local ai=af.Tween

local ak=a.load'P'

function aa.New(al,am,an,ao,ap)
local aq={
Radius=am.ElementConfig.UICorner,
Padding=am.NewElements and am.ElementConfig.UIPadding+4 or am.ElementConfig.UIPadding,

CodeFrame=nil,
}

local ar=ag("TextLabel",{
Text="",
TextColor3=Color3.fromHex"#CDD6F4",
TextTransparency=0,
TextSize=al.CodeSize,
TextWrapped=false,
LineHeight=1.15,
RichText=true,
TextXAlignment="Left",
Size=UDim2.new(0,0,0,0),
BackgroundTransparency=1,
AutomaticSize="XY",
},{
ag("UIPadding",{
PaddingTop=UDim.new(0,aq.Padding+3),
PaddingLeft=UDim.new(0,aq.Padding+3),
PaddingRight=UDim.new(0,aq.Padding+3),
PaddingBottom=UDim.new(0,aq.Padding+3),
}),
})
ar.Font="Code"

local as=ag("ScrollingFrame",{
Size=UDim2.new(1,0,0,0),
BackgroundTransparency=1,
AutomaticCanvasSize=al.Height~=nil and"XY"or"X",
ScrollingDirection=al.Height~=nil and"XY"or"X",
ElasticBehavior="Never",
CanvasSize=UDim2.new(0,0,0,0),
ScrollBarThickness=0,
},{
ar,
})

local at=al.CanCopied
and ag("TextButton",{
BackgroundTransparency=1,
Size=UDim2.new(0,35,0,35),
Position=UDim2.new(1,-aq.Padding/2,0,aq.Padding/2),
AnchorPoint=Vector2.new(1,0),
Visible=ao and true or false,
},{
af.NewRoundFrame(aq.Radius-4,"Squircle",{



ImageColor3=Color3.fromHex"#ffffff",
ImageTransparency=1,
Size=UDim2.new(1,0,1,0),
AnchorPoint=Vector2.new(0.5,0.5),
Position=UDim2.new(0.5,0,0.5,0),
Name="Button",
},{
ag("UIScale",{
Scale=1,
}),
ag("ImageLabel",{
Image=af.Icon"copy"[1],
ImageRectSize=af.Icon"copy"[2].ImageRectSize,
ImageRectOffset=af.Icon"copy"[2].ImageRectPosition,
BackgroundTransparency=1,
AnchorPoint=Vector2.new(0.5,0.5),
Position=UDim2.new(0.5,0,0.5,0),
Size=UDim2.new(0,12,0,12),



ImageColor3=Color3.fromHex"#ffffff",
ImageTransparency=0.1,
}),
}),
})
or nil

local au,av=af.NewRoundFrame(aq.Radius,"SquircleOutline",{
Size=UDim2.new(1,0,1,0),



ImageColor3=Color3.fromHex"#ffffff",
ImageTransparency=0.955,
Visible=false,
})

local aw,ax=af.NewRoundFrame(aq.Radius,"Squircle-TL-TR",{



ImageColor3=Color3.fromHex"#ffffff",
ImageTransparency=0.96,
Size=UDim2.new(1,0,0,20+(aq.Padding*2)),
Visible=al.Title and true or false,
},{










ag("TextLabel",{
Text=al.Title,



TextColor3=Color3.fromHex"#ffffff",
TextTransparency=0.2,
TextSize=18,
AutomaticSize="Y",
FontFace=Font.new(af.Font,Enum.FontWeight.Medium),
TextXAlignment="Left",
BackgroundTransparency=1,
TextTruncate="AtEnd",
Size=UDim2.new(1,at and-20-(aq.Padding*2),0,0),
}),
ag("UIPadding",{

PaddingLeft=UDim.new(0,aq.Padding+3),
PaddingRight=UDim.new(0,aq.Padding+3),

}),
ag("UIListLayout",{
Padding=UDim.new(0,aq.Padding),
FillDirection="Horizontal",
VerticalAlignment="Center",
}),
})

local ay,az=af.NewRoundFrame(aq.Radius,"Squircle",{



ImageColor3=Color3.fromHex"#212121",
ImageTransparency=0.035,
Size=al.Height~=nil
and UDim2.new(1,0,al.Height.Scale,al.Height.Offset==0 and-40 or al.Height.Offset)
or UDim2.new(1,0,0,20+(aq.Padding*2)),
AutomaticSize=al.Height~=nil and"None"or"Y",
Parent=an,
},{
au,
ag("Frame",{
BackgroundTransparency=1,
Size=UDim2.new(1,0,al.Height~=nil and 1 or 0,0),
AutomaticSize=al.Height~=nil and"None"or"Y",
},{
aw,
as,
ag("UIListLayout",{
Padding=UDim.new(0,0),
FillDirection="Vertical",
}),
}),
at,
},nil,true)

aq.CodeFrame=ay
aq.CodeFrameModule=az
aq.OutlineFrame=au
aq.OutlineFrameModule=av
aq.TopbarFrame=aw
aq.TopbarFrameModule=ax

af.AddSignal(ar:GetPropertyChangedSignal"TextBounds",function()
if al.Height~=nil then
as.Size=UDim2.new(1,0,1,al.Title~=nil and-(20+(aq.Padding*2))or nil)
else
as.Size=
UDim2.new(1,0,0,(ar.TextBounds.Y/(ap or 1))+((aq.Padding+3)*2))
end
end)

function aq.Set(aA)
ar.Text=ak.run(aA,al.CodeTheme)
end

function aq.Destroy()
ay:Destroy()
aq=nil
end

aq.Set(al.Code)

if at then
af.AddSignal(at.InputBegan,function(aA:InputObject)
if
aA.UserInputType==Enum.UserInputType.MouseButton1
or aA.UserInputType==Enum.UserInputType.Touch
then
ai(at.Button,0.05,{ImageTransparency=0.95}):Play()
ai(at.Button.UIScale,0.05,{Scale=0.9}):Play()
end
end)
af.AddSignal(at.InputEnded,function()
ai(at.Button,0.08,{ImageTransparency=1}):Play()
ai(at.Button.UIScale,0.08,{Scale=1}):Play()
end)
af.AddSignal(at.MouseButton1Click,function()
if ao then
ao()
local aA=af.Icon"check"
at.Button.ImageLabel.Image=aA[1]
at.Button.ImageLabel.ImageRectSize=aA[2].ImageRectSize
at.Button.ImageLabel.ImageRectOffset=aA[2].ImageRectPosition

task.delay(1,function()
local aB=af.Icon"copy"
at.Button.ImageLabel.Image=aB[1]
at.Button.ImageLabel.ImageRectSize=aB[2].ImageRectSize
at.Button.ImageLabel.ImageRectOffset=aB[2].ImageRectPosition
end)
end
end)
end

return aq
end

return aa end function a.R()

local aa=a.load'd'local af=
aa.New


local ag=a.load'Q'

local ai={}

function ai.New(ak,al)
local am={
__type="Code",
Title=al.Title,
Code=al.Code,
CodeSize=al.CodeSize or 18,
Height=al.Height,
CodeTheme=al.CodeTheme,
Locked=false,
CanCopied=al.CanCopied~=false,
OnCopy=al.OnCopy,

Index=al.Index,
}

local an=not am.Locked











local ao=ag.New(am,al.Window,al.Parent,function()
if an then
local ao=am.Title or"code"
local ap,aq=pcall(function()
if toclipboard then
toclipboard(am.Code)
end
if setclipboard then
setclipboard(am.Code)
end

if am.OnCopy then
am.OnCopy()
end
end)
if not ap then
al.WindUI:Notify{
Title="Error",
Content="The "..ao.." is not copied. Error: "..aq,
Icon="x",
Duration=5,
}
end
end
end,al.WindUI.UIScale)

function am.SetCode(ap,aq)
ao.Set(aq)
am.Code=aq
end

function am.Set(ap,aq)
return am.SetCode(aq)
end

function am.Destroy(ap)
ao.Destroy()
am=nil
end

function am.UpdateShape(ap)
if al.Window.NewElements then
local aq=aa:GetElementPosition(
ap.Elements,
am.Index,
al.ParentType=="HStack"or al.ParentType=="Group"
)

if aq and ao.CodeFrameModule then
ao.CodeFrameModule:SetType(aq)

print(aq)
ao.TopbarFrameModule:SetType(
table.find({"Squircle-BL-BR","SquircleH-BL-BR"},aq)~=nil and"Square"or aq
)
end
end
end

am.UIElements={Main=ao.CodeFrame}
am.ElementFrame=ao.CodeFrame

return am.__type,am
end

return ai end function a.S()

local aa=a.load'd'
local af=aa.New local ag=
aa.Tween

local ai=(cloneref or clonereference or function(ai)
return ai
end)

local ak=ai(game:GetService"UserInputService")
ai(game:GetService"TouchInputService")
local al=ai(game:GetService"RunService")
local am=ai(game:GetService"Players")local an=

al.RenderStepped
local ao=am.LocalPlayer
local ap=ao:GetMouse()

local aq=a.load'm'.New
local ar=a.load'n'.New

local as={
UICorner=9,

}

local at

function as.Colorpicker(au,av,aw,ax,ay)
local az={
__type="Colorpicker",
Title=av.Title,
Desc=av.Desc,
Default=av.Value or av.Default,
Callback=av.Callback,
Transparency=av.Transparency,
UIElements=av.UIElements,

TextPadding=10,
}

local aA={}
local aB=az.Transparency~=nil

function az.SetHSVFromRGB(b,d)
local f,g,h=Color3.toHSV(d)
az.Hue=f
az.Sat=g
az.Vib=h
end

az:SetHSVFromRGB(az.Default)

local b=a.load'o'
local d=b.Create(nil,"Dialog",aw,ax,aw.UIElements.Main.Main)

az.ColorpickerFrame=d

d.UIElements.Main.Size=UDim2.new(1,0,0,0)



local f,g,h=az.Hue,az.Sat,az.Vib

az.UIElements.Title=af("TextLabel",{
Text=az.Title,
TextSize=20,
FontFace=Font.new(aa.Font,Enum.FontWeight.SemiBold),
TextXAlignment="Left",
Size=UDim2.new(0,0,0,0),
AutomaticSize="Y",
ThemeTag={
TextColor3="Text",
},
BackgroundTransparency=1,
Parent=d.UIElements.Main,
},{
af("UIPadding",{
PaddingTop=UDim.new(0,az.TextPadding/2),
PaddingLeft=UDim.new(0,az.TextPadding/2),
PaddingRight=UDim.new(0,az.TextPadding/2),
PaddingBottom=UDim.new(0,az.TextPadding/2),
}),
})





local i=af("Frame",{
Size=UDim2.new(1,0,1,0),
Position=UDim2.new(0,0,0,0),
BackgroundTransparency=1,
})

local l=af("Frame",{
Size=UDim2.new(0,14,0,14),
AnchorPoint=Vector2.new(0.5,0.5),
Position=UDim2.new(0.5,0,0,0),
Parent=i,
BackgroundColor3=az.Default,
},{
af("UIStroke",{
Thickness=2,
Transparency=0.1,
ThemeTag={
Color="Text",
},
}),
af("UICorner",{
CornerRadius=UDim.new(1,0),
}),
})

az.UIElements.SatVibMap=af("ImageLabel",{
Size=UDim2.fromOffset(160,158),
Position=UDim2.fromOffset(0,40+az.TextPadding),
Image="rbxassetid://4155801252",
BackgroundColor3=Color3.fromHSV(f,1,1),
BackgroundTransparency=0,
Parent=d.UIElements.Main,
},{
af("UICorner",{
CornerRadius=UDim.new(0,8),
}),
aa.NewRoundFrame(8,"SquircleOutline",{
ThemeTag={
ImageColor3="Outline",
},
Size=UDim2.new(1,0,1,0),
ImageTransparency=0.85,
ZIndex=99999,
},{
af("UIGradient",{
Rotation=45,
Color=ColorSequence.new{
ColorSequenceKeypoint.new(0.0,Color3.fromRGB(255,255,255)),
ColorSequenceKeypoint.new(0.5,Color3.fromRGB(255,255,255)),
ColorSequenceKeypoint.new(1.0,Color3.fromRGB(255,255,255)),
},
Transparency=NumberSequence.new{
NumberSequenceKeypoint.new(0.0,0.1),
NumberSequenceKeypoint.new(0.5,1),
NumberSequenceKeypoint.new(1.0,0.1),
},
}),
}),

l,
})

az.UIElements.Inputs=af("Frame",{
AutomaticSize="XY",
Size=UDim2.new(0,0,0,0),
Position=UDim2.fromOffset(
aB and 240 or 210,
40+az.TextPadding
),
BackgroundTransparency=1,
Parent=d.UIElements.Main,
},{
af("UIListLayout",{
Padding=UDim.new(0,4),
FillDirection="Vertical",
}),
})





local m=af("Frame",{
BackgroundColor3=az.Default,
Size=UDim2.fromScale(1,1),
BackgroundTransparency=az.Transparency,
},{
af("UICorner",{
CornerRadius=UDim.new(0,8),
}),
})

af("ImageLabel",{
Image="http://www.roblox.com/asset/?id=14204231522",
ImageTransparency=0.45,
ScaleType=Enum.ScaleType.Tile,
TileSize=UDim2.fromOffset(40,40),
BackgroundTransparency=1,
Position=UDim2.fromOffset(85,208+az.TextPadding),
Size=UDim2.fromOffset(75,24),
Parent=d.UIElements.Main,
},{
af("UICorner",{
CornerRadius=UDim.new(0,8),
}),
aa.NewRoundFrame(8,"SquircleOutline",{
ThemeTag={
ImageColor3="Outline",
},
Size=UDim2.new(1,0,1,0),
ImageTransparency=0.85,
ZIndex=99999,
},{
af("UIGradient",{
Rotation=60,
Color=ColorSequence.new{
ColorSequenceKeypoint.new(0.0,Color3.fromRGB(255,255,255)),
ColorSequenceKeypoint.new(0.5,Color3.fromRGB(255,255,255)),
ColorSequenceKeypoint.new(1.0,Color3.fromRGB(255,255,255)),
},
Transparency=NumberSequence.new{
NumberSequenceKeypoint.new(0.0,0.1),
NumberSequenceKeypoint.new(0.5,1),
NumberSequenceKeypoint.new(1.0,0.1),
},
}),
}),







m,
})

local p=af("Frame",{
BackgroundColor3=az.Default,
Size=UDim2.fromScale(1,1),
BackgroundTransparency=0,
ZIndex=9,
},{
af("UICorner",{
CornerRadius=UDim.new(0,8),
}),
})

af("ImageLabel",{
Image="http://www.roblox.com/asset/?id=14204231522",
ImageTransparency=0.45,
ScaleType=Enum.ScaleType.Tile,
TileSize=UDim2.fromOffset(40,40),
BackgroundTransparency=1,
Position=UDim2.fromOffset(0,208+az.TextPadding),
Size=UDim2.fromOffset(75,24),
Parent=d.UIElements.Main,
},{
af("UICorner",{
CornerRadius=UDim.new(0,8),
}),







aa.NewRoundFrame(8,"SquircleOutline",{
ThemeTag={
ImageColor3="Outline",
},
Size=UDim2.new(1,0,1,0),
ImageTransparency=0.85,
ZIndex=99999,
},{
af("UIGradient",{
Rotation=60,
Color=ColorSequence.new{
ColorSequenceKeypoint.new(0.0,Color3.fromRGB(255,255,255)),
ColorSequenceKeypoint.new(0.5,Color3.fromRGB(255,255,255)),
ColorSequenceKeypoint.new(1.0,Color3.fromRGB(255,255,255)),
},
Transparency=NumberSequence.new{
NumberSequenceKeypoint.new(0.0,0.1),
NumberSequenceKeypoint.new(0.5,1),
NumberSequenceKeypoint.new(1.0,0.1),
},
}),
}),
p,
})

local r={}

for u=0,1,0.1 do
table.insert(r,ColorSequenceKeypoint.new(u,Color3.fromHSV(u,1,1)))
end

local u=af("UIGradient",{
Color=ColorSequence.new(r),
Rotation=90,
})

local v=af("Frame",{
Size=UDim2.new(0,14,0,14),
AnchorPoint=Vector2.new(0.5,0.5),
Position=UDim2.new(0.5,0,0,0),
Parent=i,


BackgroundColor3=az.Default,
},{
af("UIStroke",{
Thickness=2,
Transparency=0.1,
ThemeTag={
Color="Text",
},
}),
af("UICorner",{
CornerRadius=UDim.new(1,0),
}),
})

local x=af("Frame",{
Size=UDim2.fromOffset(6,192),
Position=UDim2.fromOffset(180,40+az.TextPadding),
Parent=d.UIElements.Main,
},{
af("UICorner",{
CornerRadius=UDim.new(1,0),
}),
u,
i,
})

local function CreateNewInput(z,A)
local B=ar(z,nil,az.UIElements.Inputs,nil,nil,nil,nil,nil,true)

af("TextLabel",{
BackgroundTransparency=1,
TextTransparency=0.4,
TextSize=17,
FontFace=Font.new(aa.Font,Enum.FontWeight.Regular),
AutomaticSize="XY",
ThemeTag={
TextColor3="Placeholder",
},
AnchorPoint=Vector2.new(1,0.5),
Position=UDim2.new(1,-12,0.5,0),
Parent=B.Frame,
Text=z,
})

af("UIScale",{
Parent=B,
Scale=0.85,
})

B.Frame.Frame.TextBox.Text=A
B.Size=UDim2.new(0,150,0,42)

return B
end

local function ToRGB(z)
return{
R=math.floor(z.R*255),
G=math.floor(z.G*255),
B=math.floor(z.B*255),
}
end

local z=CreateNewInput("Hex","#"..az.Default:ToHex())

local A=CreateNewInput("Red",ToRGB(az.Default).R)
local B=CreateNewInput("Green",ToRGB(az.Default).G)
local C=CreateNewInput("Blue",ToRGB(az.Default).B)
local F
if aB then
F=CreateNewInput("Alpha",((1-az.Transparency)*100).."%")
end

local G=af("Frame",{
Size=UDim2.new(0,0,0,40),
AutomaticSize="Y",
Position=UDim2.new(0,0,0,254+az.TextPadding),
BackgroundTransparency=1,
Parent=d.UIElements.Main,
LayoutOrder=4,
},{
af("UIListLayout",{
Padding=UDim.new(0,6),
FillDirection="Horizontal",
HorizontalAlignment="Right",
}),






})

aa.AddSignal(d.UIElements.Main:GetPropertyChangedSignal"AbsoluteSize",function()
az.UIElements.Title.Size=UDim2.new(
0,
d.UIElements.Main.AbsoluteSize.X/av.UIScale-(d.UIPadding*2),
0,
0
)
G.Size=UDim2.new(
0,
d.UIElements.Main.AbsoluteSize.X/av.UIScale-d.UIPadding*2,
0,
40
)
end)

local H={
{
Title="Cancel",
Variant="Secondary",
Callback=function()
av.IsShowed=false
for H,J in next,aA do
J:Disconnect()
end
aA={}
end,
},
{
Title="Apply",

Variant="Primary",
Callback=function()
av.IsShowed=false
for H,J in next,aA do
J:Disconnect()
end
aA={}

ay(Color3.fromHSV(az.Hue,az.Sat,az.Vib),az.Transparency)
end,
},
}

for J,L in next,H do
local M=aq(
L.Title,
L.Icon,
L.Callback,
L.Variant,
G,
d,
true
)
M.Size=UDim2.new(0.5,-3,0,40)
M.AutomaticSize="None"
end

local J,L,M
if aB then
local N=af("Frame",{
Size=UDim2.new(1,0,1,0),
Position=UDim2.fromOffset(0,0),
BackgroundTransparency=1,
})

L=af("ImageLabel",{
Size=UDim2.new(0,14,0,14),
AnchorPoint=Vector2.new(0.5,0.5),
Position=UDim2.new(0.5,0,0,0),
ThemeTag={
BackgroundColor3="Text",
},
Parent=N,
},{
af("UIStroke",{
Thickness=2,
Transparency=0.1,
ThemeTag={
Color="Text",
},
}),
af("UICorner",{
CornerRadius=UDim.new(1,0),
}),
})

M=af("Frame",{
Size=UDim2.fromScale(1,1),
},{
af("UIGradient",{
Transparency=NumberSequence.new{
NumberSequenceKeypoint.new(0,0),
NumberSequenceKeypoint.new(1,1),
},
Rotation=270,
}),
af("UICorner",{
CornerRadius=UDim.new(0,6),
}),
})

J=af("Frame",{
Size=UDim2.fromOffset(6,192),
Position=UDim2.fromOffset(210,40+az.TextPadding),
Parent=d.UIElements.Main,
BackgroundTransparency=1,
},{
af("UICorner",{
CornerRadius=UDim.new(1,0),
}),
af("ImageLabel",{
Image="rbxassetid://14204231522",
ImageTransparency=0.45,
ScaleType=Enum.ScaleType.Tile,
TileSize=UDim2.fromOffset(40,40),
BackgroundTransparency=1,
Size=UDim2.fromScale(1,1),
},{
af("UICorner",{
CornerRadius=UDim.new(1,0),
}),
}),
M,
N,
})
end

function az.Round(N,O,P)
if P==0 then
return math.floor(O)
end
O=tostring(O)
return O:find"%."and tonumber(O:sub(1,O:find"%."+P))or O
end

function az.Update(N,O,P)
if O then
f,g,h=Color3.toHSV(O)
else
f,g,h=az.Hue,az.Sat,az.Vib
end

az.UIElements.SatVibMap.BackgroundColor3=Color3.fromHSV(f,1,1)
l.Position=UDim2.new(g,0,1-h,0)
l.BackgroundColor3=Color3.fromHSV(f,g,h)
p.BackgroundColor3=Color3.fromHSV(f,g,h)
v.BackgroundColor3=Color3.fromHSV(f,1,1)
v.Position=UDim2.new(0.5,0,f,0)

z.Frame.Frame.TextBox.Text="#"..Color3.fromHSV(f,g,h):ToHex()
A.Frame.Frame.TextBox.Text=ToRGB(Color3.fromHSV(f,g,h)).R
B.Frame.Frame.TextBox.Text=ToRGB(Color3.fromHSV(f,g,h)).G
C.Frame.Frame.TextBox.Text=ToRGB(Color3.fromHSV(f,g,h)).B

if P or aB then
p.BackgroundTransparency=az.Transparency or P
M.BackgroundColor3=Color3.fromHSV(f,g,h)
L.BackgroundColor3=Color3.fromHSV(f,g,h)
L.BackgroundTransparency=az.Transparency or P
L.Position=UDim2.new(0.5,0,1-az.Transparency or P,0)
F.Frame.Frame.TextBox.Text=az:Round(
(1-az.Transparency or P)*100,
0
).."%"
end
end

az:Update(az.Default,az.Transparency)

local function GetRGB()
local N=Color3.fromHSV(az.Hue,az.Sat,az.Vib)
return{R=math.floor(N.r*255),G=math.floor(N.g*255),B=math.floor(N.b*255)}
end



local function clamp(N,O,P)
return math.clamp(tonumber(N)or 0,O,P)
end

table.insert(
aA,
aa.AddSignal(z.Frame.Frame.TextBox.FocusLost,function(N)
if N then
local O=z.Frame.Frame.TextBox.Text:gsub("#","")
local P,Q=pcall(Color3.fromHex,O)
if P and typeof(Q)=="Color3"then
az.Hue,az.Sat,az.Vib=Color3.toHSV(Q)
az:Update()
az.Default=Q
end
end
end)
)

local function updateColorFromInput(N,O)
aa.AddSignal(N.Frame.Frame.TextBox.FocusLost,function(P)
if P then
local Q=N.Frame.Frame.TextBox
local R=GetRGB()
local S=clamp(Q.Text,0,255)
Q.Text=tostring(S)

R[O]=S
local T=Color3.fromRGB(R.R,R.G,R.B)
az.Hue,az.Sat,az.Vib=Color3.toHSV(T)
az:Update()
end
end)
end

updateColorFromInput(A,"R")
updateColorFromInput(B,"G")
updateColorFromInput(C,"B")

if aB then
aa.AddSignal(F.Frame.Frame.TextBox.FocusLost,function(N)
if N then
local O=F.Frame.Frame.TextBox
local P=clamp(O.Text,0,100)
O.Text=tostring(P)

az.Transparency=1-P*0.01
az:Update(nil,az.Transparency)
end
end)
end



local function UpdateSatVib(N,O)
local P=N.AbsolutePosition.X
local Q=P+N.AbsoluteSize.X
local R=N.AbsolutePosition.Y
local S=R+N.AbsoluteSize.Y

local T=math.clamp(ap.X,P,Q)
local U=math.clamp(ap.Y,R,S)

O.Sat=(T-P)/(Q-P)
O.Vib=1-((U-R)/(S-R))

O:Update()
end

local function UpdateHue(N,O)
local P=N.AbsolutePosition.Y
local Q=P+N.AbsoluteSize.Y

local R=math.clamp(ap.Y,P,Q)

O.Hue=(R-P)/(Q-P)

O:Update()
end

local function UpdateTransparency(N,O)
local P=N.AbsolutePosition.Y
local Q=P+N.AbsoluteSize.Y

local R=math.clamp(ap.Y,P,Q)

O.Transparency=1-((R-P)/(Q-P))

O:Update()
end

local N=ax.GenerateGUID()

table.insert(
aA,
ak.InputChanged:Connect(function(O)
if
O.UserInputType~=Enum.UserInputType.MouseMovement
and O.UserInputType~=Enum.UserInputType.Touch
then
return
end

if at=="SatVib"then
UpdateSatVib(az.UIElements.SatVibMap,az)
elseif at=="Hue"then
UpdateHue(x,az)
elseif at=="Transparency"then
UpdateTransparency(J,az)
end
end)
)

table.insert(
aA,
az.UIElements.SatVibMap.InputBegan:Connect(function(O)
if
O.UserInputType~=Enum.UserInputType.MouseButton1
and O.UserInputType~=Enum.UserInputType.Touch
then
return
end

if ax.CurrentInput and ax.CurrentInput~=N then
return
end
ax.CurrentInput=N

if at and at~="SatVib"then
return
end

at="SatVib"

UpdateSatVib(az.UIElements.SatVibMap,az)
end)
)

table.insert(
aA,
x.InputBegan:Connect(function(O)
if
O.UserInputType~=Enum.UserInputType.MouseButton1
and O.UserInputType~=Enum.UserInputType.Touch
then
return
end

if ax.CurrentInput and ax.CurrentInput~=N then
return
end
ax.CurrentInput=N

if at and at~="Hue"then
return
end

at="Hue"

UpdateHue(x,az)
end)
)

if J then
table.insert(
aA,
J.InputBegan:Connect(function(O)
if
O.UserInputType~=Enum.UserInputType.MouseButton1
and O.UserInputType~=Enum.UserInputType.Touch
then
return
end

if ax.CurrentInput and ax.CurrentInput~=N then
return
end
ax.CurrentInput=N

if at and at~="Transparency"then
return
end

at="Transparency"

UpdateTransparency(J,az)
end)
)
end

table.insert(
aA,
ak.InputEnded:Connect(function(O)
at=nil

if ax.CurrentInput and ax.CurrentInput~=N then
return
end
ax.CurrentInput=nil
end)
)

return az
end

function as.New(au,av)
local aw={
__type="Colorpicker",
Title=av.Title or"Colorpicker",
Desc=av.Desc or nil,
Locked=av.Locked or false,
LockedTitle=av.LockedTitle,
Default=av.Default or Color3.new(1,1,1),
Callback=av.Callback or function()end,

UIScale=av.UIScale,
Transparency=av.Transparency,
UIElements={},

IsShowed=false,
}

local ax=true



aw.ColorpickerFrame=a.load'C'{
Title=aw.Title,
Desc=aw.Desc,
Parent=av.Parent,
TextOffset=40,
Hover=false,
Tab=av.Tab,
Index=av.Index,
Window=av.Window,
ElementTable=aw,
ParentConfig=av,
Tags=av.Tags,
}

aw.UIElements.Colorpicker=aa.NewRoundFrame(as.UICorner,"Squircle",{
ImageTransparency=0,
Active=true,
ImageColor3=aw.Default,
Parent=aw.ColorpickerFrame.UIElements.Main,
Size=UDim2.new(0,26,0,26),
AnchorPoint=Vector2.new(1,0),
Position=UDim2.new(1,0,0,0),
ZIndex=2,
},{
aa.NewRoundFrame(as.UICorner,"SquircleGlass",{
Size=UDim2.new(1,0,1,0),
ThemeTag={
ImageColor3="Outline",
},
ImageTransparency=0.55,
}),
},true)

function aw.Lock(ay)
aw.Locked=true
ax=false
return aw.ColorpickerFrame:Lock(aw.LockedTitle)
end
function aw.Unlock(ay)
aw.Locked=false
ax=true
return aw.ColorpickerFrame:Unlock()
end

if aw.Locked then
aw:Lock()
end

function aw.Update(ay,az,aA)
aw.UIElements.Colorpicker.ImageTransparency=aA or 0
aw.UIElements.Colorpicker.ImageColor3=az
aw.Default=az
if aA then
aw.Transparency=aA
end
end

function aw.Set(ay,az,aA)
return aw:Update(az,aA)
end

aa.AddSignal(aw.UIElements.Colorpicker.MouseButton1Click,function()
if ax and not aw.IsShowed then
aw.IsShowed=true

as:Colorpicker(aw,av.Window,av.WindUI,function(ay,az)
aw:Update(ay,az)
aw.Default=ay
aw.Transparency=az
aa.SafeCallback(aw.Callback,ay,az)
end).ColorpickerFrame
:Open()
end
end)

return aw.__type,aw
end

return as end function a.T()

local aa=a.load'd'
local af=aa.New
local ai=aa.Tween

local ak={}

function ak.New(al,am)
local an={
__type="Section",
Title=am.Title or"Section",
Desc=am.Desc,
Icon=am.Icon,
IconThemed=am.IconThemed,
TextXAlignment=am.TextXAlignment or"Left",
TextSize=am.TextSize or 19,
DescTextSize=am.DescTextSize or 16,
Box=am.Box or false,
BoxBorder=am.BoxBorder or false,
FontWeight=am.FontWeight or Enum.FontWeight.SemiBold,
DescFontWeight=am.DescFontWeight or Enum.FontWeight.Medium,
TextTransparency=am.TextTransparency or 0.05,
DescTextTransparency=am.DescTextTransparency or 0.4,
Opened=am.Opened or false,
UIElements={},

HeaderSize=48,
IconSize=20,
Padding=10,

Elements={},

Expandable=false,
}

local ao

function an.SetIcon(ap,aq)
an.Icon=aq or nil
if ao then
ao:Destroy()
end
if aq then
ao=aa.Image(
aq,
aq..":"..an.Title,
0,
am.Window.Folder,
an.__type,
true,
an.IconThemed,
"SectionIcon"
)
ao.Size=UDim2.new(0,an.IconSize,0,an.IconSize)
end
end

local ap=af("Frame",{
Size=UDim2.new(0,an.IconSize,0,an.IconSize),
BackgroundTransparency=1,
Visible=false,
},{
af("ImageLabel",{
Size=UDim2.new(1,0,1,0),
BackgroundTransparency=1,
Image=aa.Icon"chevron-down"[1],
ImageRectSize=aa.Icon"chevron-down"[2].ImageRectSize,
ImageRectOffset=aa.Icon"chevron-down"[2].ImageRectPosition,
ThemeTag={
ImageTransparency="SectionExpandIconTransparency",
ImageColor3="SectionExpandIcon",
},
}),
})

if an.Icon then
an:SetIcon(an.Icon)
end

local aq=af("Frame",{
Size=UDim2.new(1,0,1,0),
BackgroundTransparency=1,
},{
af("UIListLayout",{
FillDirection="Vertical",
HorizontalAlignment=an.TextXAlignment,
VerticalAlignment="Center",
Padding=UDim.new(0,4),
}),
})

local ar,as

local function createTitle(at,au)
return af("TextLabel",{
BackgroundTransparency=1,
TextXAlignment=an.TextXAlignment,
AutomaticSize="Y",
TextSize=au=="Title"and an.TextSize or an.DescTextSize,
TextTransparency=au=="Title"and an.TextTransparency or an.DescTextTransparency,
ThemeTag={
TextColor3="Text",
},
FontFace=Font.new(aa.Font,au=="Title"and an.FontWeight or an.DescFontWeight),


Text=at,
Size=UDim2.new(1,0,0,0),
TextWrapped=true,
Parent=aq,
})
end

ar=createTitle(an.Title,"Title")
if an.Desc then
as=createTitle(an.Desc,"Desc")
end

local function UpdateTitleSize()
local at=0
if ao then
at=at-(an.IconSize+8)
end
if ap.Visible then
at=at-(an.IconSize+8)
end
aq.Size=UDim2.new(1,at,0,0)
end

local at=aa.NewRoundFrame(am.Window.ElementConfig.UICorner,"Squircle",{
Size=UDim2.new(1,0,0,0),
BackgroundTransparency=1,
Parent=am.Parent,

AutomaticSize="Y",
ThemeTag={
ImageTransparency=an.Box and"SectionBoxBackgroundTransparency"or nil,
ImageColor3="SectionBoxBackground",
},
ImageTransparency=not an.Box and 1 or nil,
},{
aa.NewRoundFrame(am.Window.ElementConfig.UICorner-1,"SquircleOutline",{
Size=UDim2.new(1,0,1,0),



ThemeTag={

ImageColor3="SectionBoxBorder",
},
ImageTransparency=an.Box and an.BoxBorder and 0.92 or 1,
Name="Outline",
ClipsDescendants=true,
},{
af("TextButton",{
Size=UDim2.new(1,0,0,an.Expandable and 0 or(not as and an.HeaderSize or 0)),
BackgroundTransparency=1,
AutomaticSize=(not an.Expandable or as)and"Y"or nil,
Text="",
Name="Top",
},{
an.Box and af("UIPadding",{
PaddingTop=UDim.new(
0,
am.Window.ElementConfig.UIPadding+(am.Window.NewElements and 4 or 0)
),
PaddingLeft=UDim.new(
0,
am.Window.ElementConfig.UIPadding+(am.Window.NewElements and 4 or 0)
),
PaddingRight=UDim.new(
0,
am.Window.ElementConfig.UIPadding+(am.Window.NewElements and 4 or 0)
),
PaddingBottom=UDim.new(
0,
am.Window.ElementConfig.UIPadding+(am.Window.NewElements and 4 or 0)
),
})or nil,
ao,
aq,
af("UIListLayout",{
Padding=UDim.new(0,8),
FillDirection="Horizontal",
VerticalAlignment="Center",
HorizontalAlignment="Left",
}),
ap,
}),
af("Frame",{
BackgroundTransparency=1,
Size=UDim2.new(1,0,0,0),
AutomaticSize="Y",
Name="Content",
Visible=false,
Position=UDim2.new(0,0,0,an.HeaderSize+10),
},{
an.Box and af("UIPadding",{
PaddingLeft=UDim.new(0,am.Window.ElementConfig.UIPadding/1.5),
PaddingRight=UDim.new(0,am.Window.ElementConfig.UIPadding/1.5),
PaddingBottom=UDim.new(0,am.Window.ElementConfig.UIPadding/1.5),
})or nil,
af("UIListLayout",{
FillDirection="Vertical",
Padding=UDim.new(0,am.Tab.Gap),
VerticalAlignment="Top",
}),
}),
}),
})





an.ElementFrame=at

at.Outline.Top:GetPropertyChangedSignal"AbsoluteSize":Connect(function()
at.Outline.Content.Position=UDim2.new(0,0,0,(at.Outline.Top.AbsoluteSize.Y/am.UIScale)+10)

if an.Opened then
an:Open(true)
else
an.Close(true)
end
end)

local au=am.ElementsModule

au.Load(an,at.Outline.Content,au.Elements,am.Window,am.WindUI,function()
if not an.Expandable then
an.Expandable=true
ap.Visible=true
UpdateTitleSize()
end
end,au,am.UIScale,am.Tab)

UpdateTitleSize()

function an.SetTitle(av,aw)
an.Title=aw
ar.Text=aw
end

function an.SetDesc(av,aw)
an.Desc=aw
if not as then
as=createTitle(aw,"Desc")
end
as.Text=aw
end

function an.Destroy(av)
for aw,ax in next,an.Elements do
ax:Destroy()
end








at:Destroy()
end

function an.Open(av,aw)
if an.Expandable then
an.Opened=true
if aw then
at.Size=UDim2.new(
at.Size.X.Scale,
at.Size.X.Offset,
0,
at.Outline.Top.AbsoluteSize.Y/am.UIScale
+(at.Outline.Content.AbsoluteSize.Y/am.UIScale)
+10
)
ap.ImageLabel.Rotation=180
else
ai(at,0.33,{
Size=UDim2.new(
at.Size.X.Scale,
at.Size.X.Offset,
0,
at.Outline.Top.AbsoluteSize.Y/am.UIScale
+(at.Outline.Content.AbsoluteSize.Y/am.UIScale)
+10
),
},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()

ai(
ap.ImageLabel,
0.2,
{Rotation=180},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()
end
end
end
function an.Close(av,aw)
if an.Expandable then
an.Opened=false
if aw then
at.Size=UDim2.new(
at.Size.X.Scale,
at.Size.X.Offset,
0,
(at.Outline.Top.AbsoluteSize.Y/am.UIScale)
)
ap.ImageLabel.Rotation=0
else
ai(at,0.26,{
Size=UDim2.new(
at.Size.X.Scale,
at.Size.X.Offset,
0,
(at.Outline.Top.AbsoluteSize.Y/am.UIScale)
),
},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
ai(
ap.ImageLabel,
0.2,
{Rotation=0},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()
end
end
end

aa.AddSignal(at.Outline.Top.MouseButton1Click,function()
if an.Expandable then
if an.Opened then
an:Close()
else
an:Open()
end
end
end)

aa.AddSignal(at.Outline.Content.UIListLayout:GetPropertyChangedSignal"AbsoluteContentSize",function()
if an.Opened then
an:Open(true)
else
an:Close(true)
end
end)

task.defer(function()
if an.Expandable then








at.Size=
UDim2.new(at.Size.X.Scale,at.Size.X.Offset,0,at.Outline.Top.AbsoluteSize.Y/am.UIScale)
at.AutomaticSize="None"
at.Outline.Top.Size=UDim2.new(1,0,0,(not as and an.HeaderSize or 0))
at.Outline.Top.AutomaticSize=(not an.Expandable or as)and"Y"or"None"
at.Outline.Content.Visible=true
end
if an.Opened then
an:Open()
else
an:Close(true)
end
end)

return an.__type,an
end

return ak end function a.U()

local aa=a.load'd'
local af=aa.New

local ai={}

function ai.New(ak,al)
local am=af("Frame",{
Parent=al.Parent,
Size=not table.find({"Group","HStack"},al.ParentType)and UDim2.new(1,-7,0,7*(al.Columns or 1))or UDim2.new(0,7*(al.Columns or 1),0,0),
BackgroundTransparency=1,
})

return"Space",{__type="Space",ElementFrame=am}
end

return ai end function a.V()
local aa=a.load'd'
local af=aa.New

local ai={}

local function ParseAspectRatio(ak)
if type(ak)=="string"then
local al,am=ak:match"(%d+):(%d+)"
if al and am then
return tonumber(al)/tonumber(am)
end
elseif type(ak)=="number"then
return ak
end
return nil
end

function ai.New(ak,al)
local am={
__type="Image",
Image=al.Image or"",
AspectRatio=al.AspectRatio or"16:9",
Radius=al.Radius or al.Window.ElementConfig.UICorner,
}
local an=aa.Image(
am.Image,
am.Image,
am.Radius,
al.Window.Folder,
"Image",
false
)
if an and an.Parent then
an.Parent=al.Parent
an.Size=UDim2.new(1,0,0,0)
an.BackgroundTransparency=1












local ao=ParseAspectRatio(am.AspectRatio)
local ap

if ao then
ap=af("UIAspectRatioConstraint",{
Parent=an,
AspectRatio=ao,
AspectType="ScaleWithParentSize",
DominantAxis="Width"
})
end

function am.Destroy(aq)
an:Destroy()
end
end

return am.__type,am
end

return ai end function a.W()
local aa=a.load'd'
local af=aa.New

local ai={}

function ai.New(ak,al)
local am={
__type="Group",
Elements={},
ElementFrame=nil,
}

local an=af("Frame",{
Size=UDim2.new(1,0,0,0),
BackgroundTransparency=1,
AutomaticSize="Y",
Parent=al.Parent,
},{
af("UIListLayout",{
FillDirection="Horizontal",
HorizontalAlignment="Center",

Padding=UDim.new(0,al.Tab and al.Tab.Gap or(al.Window.NewElements and 1 or 6))
}),
})

am.ElementFrame=an

local ao=al.ElementsModule
ao.Load(
am,
an,
ao.Elements,
al.Window,
al.WindUI,
function(ap,aq)
local ar=al.Tab and al.Tab.Gap or(al.Window.NewElements and 1 or 6)

local as={}
local at=0

for au,av in next,aq do
if av.__type=="Space"then
at=at+(av.ElementFrame.Size.X.Offset or 6)
elseif av.__type=="Divider"then
at=at+(av.ElementFrame.Size.X.Offset or 1)
else
table.insert(as,av)
end
end

local au=#as
if au==0 then return end

local av=1/au

local aw=ar*(au-1)

local ax=-(aw+at)

local ay=math.floor(ax/au)
local az=ax-(ay*au)

for aA,aB in next,as do
local b=ay
if aA<=math.abs(az)then
b=b-1
end

if aB.ElementFrame then
aB.ElementFrame.Size=UDim2.new(av,b,1,0)
end
end
end,
ao,
al.UIScale,
al.Tab
)



return am.__type,am
end

return ai end function a.X()
local aa=a.load'd'
local af=aa.New

local ai={}

function ai.New(ak,al)
local am={
__type="HStack",
AutoSpace=al.AutoSpace or false,
Elements={},
ElementFrame=nil,
}

local an=af("Frame",{
Size=UDim2.new(1,0,0,0),
BackgroundTransparency=1,
AutomaticSize="Y",
Parent=al.Parent,
},{
af("UIListLayout",{
FillDirection="Horizontal",
HorizontalAlignment="Center",

Padding=UDim.new(0,al.Tab and al.Tab.Gap or(al.Window.NewElements and 1 or 6)),
}),
})

am.ElementFrame=an

local ao=al.ElementsModule
ao.Load(
am,
an,
ao.Elements,
al.Window,
al.WindUI,
function(ap,aq)
local ar=al.Tab and al.Tab.Gap or(al.Window.NewElements and 1 or 6)

local as={}
local at=0

for au,av in next,aq do
if av.__type=="Space"then
at=at+(av.ElementFrame.Size.X.Offset or 6)
elseif av.__type=="Divider"then
at=at+(av.ElementFrame.Size.X.Offset or 1)
else
table.insert(as,av)
end
end

local au=#as
if au==0 then
return
end

local av=1/au

local aw=ar*(au-1)

local ax=-(aw+at)

local ay=math.floor(ax/au)
local az=ax-(ay*au)

for aA,aB in next,as do
local b=ay
if aA<=math.abs(az)then
b=b-1
end

if aB.ElementFrame then
aB.ElementFrame.Size=UDim2.new(av,b,1,0)
end
end
end,
ao,
al.UIScale,
al.Tab
)

if am.AutoSpace then
for ap in next,ao.Elements do
if ap~="Space"and ap~="Divider"then
local aq=am[ap]
am[ap]=function(ar,as)
if#am.Elements>0 then
am:Space()
end
return aq(ar,as)
end
end
end
end

return am.__type,am
end

return ai end function a.Y()

local aa=a.load'd'
local af=aa.New

local ai={}

function ai.New(ak,al)
local am={
__type="VStack",
Elements={},
ElementFrame=nil,
}

local an=af("Frame",{
Size=UDim2.new(1,0,0,0),
BackgroundTransparency=1,
AutomaticSize="Y",
Parent=al.Parent,
},{
af("UIListLayout",{
FillDirection="Vertical",
HorizontalAlignment="Center",

Padding=UDim.new(0,al.Tab and al.Tab.Gap or(al.Window.NewElements and 1 or 6))
}),
})

am.ElementFrame=an

local ao=al.ElementsModule
ao.Load(
am,
an,
ao.Elements,
al.Window,
al.WindUI,







































nil,
ao,
al.UIScale,
al.Tab
)



return am.__type,am
end

return ai end function a.Z()
local aa=(cloneref or clonereference or function(aa)
return aa
end)

local af=aa(game:GetService"UserInputService")

local ai=a.load'd'
local ak=ai.New

local al={}














function al.New(am,an:ConfigType__DARKLUA_TYPE_a)
local ao={
__type="Viewport",
Object=an.Object,
Camera=an.Camera or Instance.new"Camera",
Interactive=an.Interactive or false,
Height=an.Height or 200,
Focused=an.Focused~=false,
}

local ap=false
local aq=false
local ar,as=0

local at=ai.NewRoundFrame(an.Window.ElementConfig.UICorner,"Squircle",{
Size=UDim2.new(1,0,0,ao.Height),
Parent=an.Parent,
ThemeTag={
ImageColor3="ViewportBackground",
ImageTransparency="ViewportBackgroundTransparency",
},
},{
ak("CanvasGroup",{
Size=UDim2.new(1,0,1,0),
BackgroundTransparency=1,
},{
ak("UICorner",{
CornerRadius=UDim.new(0,an.Window.ElementConfig.UICorner),
}),
ak("ViewportFrame",{
Name="Viewport",
Size=UDim2.new(1,0,1,0),
BackgroundTransparency=1,
CurrentCamera=ao.Camera,
Active=ao.Interactive,
},{
ao.Object,
}),
}),
})

local function IsTouchInsideViewport(au)
local av=at.CanvasGroup.Viewport.AbsolutePosition
local aw=at.CanvasGroup.Viewport.AbsoluteSize

return au.X>=av.X
and au.X<=av.X+aw.X
and au.Y>=av.Y
and au.Y<=av.Y+aw.Y
end

local au=an.WindUI.GenerateGUID()

ai.AddSignal(at.CanvasGroup.Viewport.MouseEnter,function()
if ao.Interactive then
an.Tab.UIElements.ContainerFrame.ScrollingEnabled=false
end
end)

ai.AddSignal(at.CanvasGroup.Viewport.InputEnded,function(av)
if
av.UserInputType==Enum.UserInputType.MouseMovement
or av.UserInputType==Enum.UserInputType.Touch
then
an.Tab.UIElements.ContainerFrame.ScrollingEnabled=true
end
end)

ai.AddSignal(at.CanvasGroup.Viewport.InputBegan,function(av)
if ao.Interactive then
if
(av.UserInputType==Enum.UserInputType.MouseButton1)
or(av.UserInputType==Enum.UserInputType.Touch and not aq)
then
if an.WindUI.CurrentInput and an.WindUI.CurrentInput~=au then
return
end

an.WindUI.CurrentInput=au

ap=true
as=av.Position
end
end
end)

ai.AddSignal(af.InputEnded,function(av)
if ao.Interactive then
if
av.UserInputType==Enum.UserInputType.MouseButton1
or av.UserInputType==Enum.UserInputType.Touch
then
if an.WindUI.CurrentInput and an.WindUI.CurrentInput~=au then
return
end

an.WindUI.CurrentInput=nil

ap=false
end
end
end)

ai.AddSignal(af.InputChanged,function(av)
if ao.Interactive and ap and not aq then
if
av.UserInputType==Enum.UserInputType.MouseMovement
or av.UserInputType==Enum.UserInputType.Touch
then
local aw=av.Position-as
as=av.Position

local ax=ao.Object:GetPivot().Position
local ay=ao.Camera

local az=CFrame.fromAxisAngle(Vector3.new(0,1,0),-aw.X*0.02)
ay.CFrame=CFrame.new(ax)*az*CFrame.new(-ax)*ay.CFrame

local aA=CFrame.fromAxisAngle(ay.CFrame.RightVector,-aw.Y*0.02)
local aB=CFrame.new(ax)*aA*CFrame.new(-ax)*ay.CFrame

if aB.UpVector.Y>0.1 then
ay.CFrame=aB
end
end
end
end)

ai.AddSignal(at.CanvasGroup.Viewport.InputChanged,function(av)
if ao.Interactive then
if av.UserInputType==Enum.UserInputType.MouseWheel then
local aw=av.Position.Z*2
ao.Camera.CFrame+=ao.Camera.CFrame.LookVector*aw
end
end
end)

ai.AddSignal(af.TouchPinch,function(av,aw,ax,ay)
if not IsTouchInsideViewport(av[1])or not IsTouchInsideViewport(av[2])then
return
end
if ao.Interactive then
if ay==Enum.UserInputState.Begin then
aq=true
ap=false
ar=(av[1]-av[2]).Magnitude
elseif ay==Enum.UserInputState.Change then
if aq then
local az=(av[1]-av[2]).Magnitude
local aA=(az-ar)*0.03
ar=az
ao.Camera.CFrame+=ao.Camera.CFrame.LookVector*aA
end
elseif ay==Enum.UserInputState.End or ay==Enum.UserInputState.Cancel then
aq=false
end
end
end)

local function FocusCamera()
local av=ao.Object:IsA"BasePart"and ao.Object.Size
or select(2,ao.Object:GetBoundingBox(0))
local aw=math.max(av.X,av.Y,av.Z)
local ax=aw*2
local ay=ao.Object:GetPivot().Position

ao.Camera.CFrame=
CFrame.new(ay+Vector3.new(0,aw/2,ax),ay)
end

if ao.Focused then
FocusCamera()
end

function ao.SetObject(av,aw,ax)
if ax then
aw=aw:Clone()
end
if ao.Object then
ao.Object:Destroy()
end

ao.Object=aw
ao.Object.Parent=at.CanvasGroup.Viewport
end

function ao.SetHeight(av,aw)
at.Size=UDim2.new(1,0,0,aw)
end

function ao.Focus(av)
if ao.Object then
FocusCamera()
end
end

function ao.SetCamera(av,aw)
ao.Camera=aw
at.CanvasGroup.Viewport.CurrentCamera=aw
end

function ao.SetInteractive(av,aw)
ao.Interactive=aw
at.CanvasGroup.Viewport.Active=aw
end

ao.Main=at

return ao.__type,ao
end

return al end function a._()

return{
Elements={
Paragraph=a.load'D',
Button=a.load'E',
Toggle=a.load'H',
Slider=a.load'I',
ProgressBar=a.load'J',
Keybind=a.load'K',
Input=a.load'L',
Dropdown=a.load'O',
Code=a.load'R',
Colorpicker=a.load'S',
Section=a.load'T',
Divider=a.load'M',
Space=a.load'U',
Image=a.load'V',
Group=a.load'W',
HStack=a.load'X',
VStack=a.load'Y',
Viewport=a.load'Z',

},
Load=function(aa,af,ai,ak,al,am,an,ao,ap)
for aq,ar in next,ai do
aa[aq]=function(as,at)
at=at or{}
at.Tab=ap or aa
at.ParentType=aa.__type
at.ParentTable=aa
at.Index=#aa.Elements+1
at.GlobalIndex=#ak.AllElements+1
at.Parent=af
at.Window=ak
at.WindUI=al
at.UIScale=ao
at.ElementsModule=an local

au, av=ar:New(at)

if at.Flag and typeof(at.Flag)=="string"then
if ak.CurrentConfig then
ak.CurrentConfig:Register(at.Flag,av)

if ak.PendingConfigData and ak.PendingConfigData[at.Flag]then
local aw=ak.PendingConfigData[at.Flag]

local ax=ak.ConfigManager
if ax.Parser[aw.__type]then
task.defer(function()
local ay,az=pcall(function()
ax.Parser[aw.__type].Load(av,aw)
end)

if ay then
ak.PendingConfigData[at.Flag]=nil
else
warn(
"[ WindUI ] Failed to apply pending config for '"
..at.Flag
.."': "
..tostring(az)
)
end
end)
end
end
else
ak.PendingFlags=ak.PendingFlags or{}
ak.PendingFlags[at.Flag]=av
end
end

local aw
for ax,ay in next,av do
if typeof(ay)=="table"and ax~="ElementFrame"and ax:match"Frame$"then
aw=ay
break
end
end

if aw then
av.ElementFrame=aw.UIElements.Main
function av.SetTitle(ax,ay)
return aw.SetTitle and aw:SetTitle(ay)
end
function av.SetDesc(ax,ay)
return aw.SetDesc and aw:SetDesc(ay)
end
function av.SetImage(ax,ay,az)
return aw.SetImage and aw:SetImage(ay,az)
end
function av.SetThumbnail(ax,ay,az)
return aw.SetThumbnail and aw:SetThumbnail(ay,az)
end
function av.Highlight(ax)
aw:Highlight()
end
function av.Destroy(ax)
aw:Destroy()

table.remove(ak.AllElements,at.GlobalIndex)
table.remove(aa.Elements,at.Index)
table.remove(ap.Elements,at.Index)
aa:UpdateAllElementShapes(aa)
end
end

ak.AllElements[at.Index]=av
aa.Elements[at.Index]=av
if ap then
ap.Elements[at.Index]=av
end

if ak.NewElements then
aa:UpdateAllElementShapes(aa)
end

if am then
am(av,aa.Elements)
end
return av
end
end
function aa.UpdateAllElementShapes(aq,ar)
for as,at in next,ar.Elements do
local au
for av,aw in pairs(at)do
if typeof(aw)=="table"and av:match"Frame$"then
au=aw
break
end
end

if not au and at.UpdateShape then
au=at
end

if au then

au.Index=as
if au.UpdateShape then

au.UpdateShape(ar)
end
end
end
end
end,
}end function a.aa()

local aa=(cloneref or clonereference or function(aa)
return aa
end)

local af=game:GetService"Players"

aa(game:GetService"UserInputService")
local ai=af.LocalPlayer:GetMouse()

local ak=a.load'd'
local al=ak.New

local am=a.load'B'.New
local an=a.load'x'.New



local ao={


Tabs={},
Containers={},
SelectedTab=nil,
TabCount=0,
ToolTipParent=nil,
TabHighlight=nil,

OnChangeFunc=function(ao)end,
}

function ao.Init(ap,aq,ar,as)
Window=ap
WindUI=aq
ao.ToolTipParent=ar
ao.TabHighlight=as
return ao
end

function ao.New(ap,aq)
local ar={
__type="Tab",
Title=ap.Title or"Tab",
Desc=ap.Desc,
Icon=ap.Icon,
IconColor=ap.IconColor,
IconShape=ap.IconShape,
IconThemed=ap.IconThemed,
Locked=ap.Locked,
ShowTabTitle=ap.ShowTabTitle,
TabTitleAlign=ap.TabTitleAlign or"Left",
CustomEmptyPage=(ap.CustomEmptyPage and next(ap.CustomEmptyPage)~=nil)and ap.CustomEmptyPage
or{Icon="lucide:frown",IconSize=48,Title="This tab is Empty",Desc=nil},
Border=ap.Border,
Selected=false,
Index=nil,
Parent=ap.Parent,
UIElements={},
Elements={},
ContainerFrame=nil,
UICorner=Window.UICorner-(Window.UIPadding/2),

Gap=Window.NewElements and 1 or 6,

TabPaddingX=4+(Window.UIPadding/2),
TabPaddingY=3+(Window.UIPadding/2),
TitlePaddingY=0,
}









if ar.IconShape then
ar.TabPaddingX=2+(Window.UIPadding/4)
ar.TabPaddingY=2+(Window.UIPadding/4)
ar.TitlePaddingY=2+(Window.UIPadding/4)
end

ao.TabCount=ao.TabCount+1

local as=ao.TabCount
ar.Index=as

ar.UIElements.Main=ak.NewRoundFrame(ar.UICorner,"Squircle",{
BackgroundTransparency=1,
Size=UDim2.new(1,-7,0,0),
AutomaticSize="Y",
Parent=ap.Parent,
ThemeTag={
ImageColor3="TabBackground",
},
ImageTransparency=1,
},{
ak.NewRoundFrame(ar.UICorner-1,"Glass-1.4",{
Size=UDim2.new(1,1,1,1),
ThemeTag={
ImageColor3="TabBorder",
},
AnchorPoint=Vector2.new(0.5,0.5),
Position=UDim2.new(0.5,0,0.5,0),
ImageTransparency=1,
Name="Outline",
},{













}),
ak.NewRoundFrame(ar.UICorner,"Squircle",{
Size=UDim2.new(1,0,0,0),
AutomaticSize="Y",
ThemeTag={
ImageColor3="Text",
},
ImageTransparency=1,
Name="Frame",
},{
al("UIListLayout",{
SortOrder="LayoutOrder",
Padding=UDim.new(0,2+(Window.UIPadding/2)),
FillDirection="Horizontal",
VerticalAlignment="Center",
}),
al("TextLabel",{
Text=ar.Title,
ThemeTag={
TextColor3="TabTitle",
},
TextTransparency=not ar.Locked and 0.4 or 0.7,
TextSize=15,
Size=UDim2.new(1,0,0,0),
FontFace=Font.new(ak.Font,Enum.FontWeight.Medium),
TextWrapped=true,
RichText=true,
AutomaticSize="Y",
LayoutOrder=2,
TextXAlignment="Left",
BackgroundTransparency=1,
},{
al("UIPadding",{
PaddingTop=UDim.new(0,ar.TitlePaddingY),


PaddingBottom=UDim.new(0,ar.TitlePaddingY),
}),
}),
al("UIPadding",{
PaddingTop=UDim.new(0,ar.TabPaddingY),
PaddingLeft=UDim.new(0,ar.TabPaddingX),
PaddingRight=UDim.new(0,ar.TabPaddingX),
PaddingBottom=UDim.new(0,ar.TabPaddingY),
}),
}),
},true)

local at=0
local au
local av

if ar.Icon then
au=ak.Image(
ar.Icon,
ar.Icon..":"..ar.Title,
0,
Window.Folder,
ar.__type,
ar.IconColor and false or true,
ar.IconThemed,
"TabIcon"
)
au.Size=UDim2.new(0,16,0,16)
if ar.IconColor then
au.ImageLabel.ImageColor3=ar.IconColor
end
if not ar.IconShape then
au.Parent=ar.UIElements.Main.Frame
ar.UIElements.Icon=au
au.ImageLabel.ImageTransparency=not ar.Locked and 0 or 0.7
at=-18-(Window.UIPadding/2)
ar.UIElements.Main.Frame.TextLabel.Size=UDim2.new(1,at,0,0)
elseif ar.IconColor then
ak.NewRoundFrame(
ar.IconShape~="Circle"and(ar.UICorner+5-(2+(Window.UIPadding/4)))or 9999,
"Squircle",
{
Size=UDim2.new(0,26,0,26),
ImageColor3=ar.IconColor,
Parent=ar.UIElements.Main.Frame,
},
{
au,
ak.NewRoundFrame(
ar.IconShape~="Circle"and(ar.UICorner+5-(2+(Window.UIPadding/4)))or 9999,
"Glass-1.4",
{
Size=UDim2.new(1,0,1,0),
ThemeTag={
ImageColor3="White",
},
ImageTransparency=0,
Name="Outline",
},
{













}
),
}
)
au.AnchorPoint=Vector2.new(0.5,0.5)
au.Position=UDim2.new(0.5,0,0.5,0)
au.ImageLabel.ImageTransparency=0
au.ImageLabel.ImageColor3=ak.GetTextColorForHSB(ar.IconColor,0.68)
at=-28-(Window.UIPadding/2)
ar.UIElements.Main.Frame.TextLabel.Size=UDim2.new(1,at,0,0)
end

av=
ak.Image(ar.Icon,ar.Icon..":"..ar.Title,0,Window.Folder,ar.__type,true,ar.IconThemed)
av.Size=UDim2.new(0,16,0,16)
av.ImageLabel.ImageTransparency=not ar.Locked and 0 or 0.7
at=-30




end

ar.UIElements.ContainerFrame=al("ScrollingFrame",{
Size=UDim2.new(1,0,1,ar.ShowTabTitle and-((Window.UIPadding*2.4)+12)or 0),
BackgroundTransparency=1,
ScrollBarThickness=0,
ElasticBehavior="Never",
CanvasSize=UDim2.new(0,0,0,0),
AnchorPoint=Vector2.new(0,1),
Position=UDim2.new(0,0,1,0),
AutomaticCanvasSize="Y",

ScrollingDirection="Y",
},{
al("UIPadding",{
PaddingTop=UDim.new(0,not Window.HidePanelBackground and 20 or 10),
PaddingLeft=UDim.new(0,not Window.HidePanelBackground and 20 or 10),
PaddingRight=UDim.new(0,not Window.HidePanelBackground and 20 or 10),
PaddingBottom=UDim.new(0,not Window.HidePanelBackground and 20 or 10),
}),
al("UIListLayout",{
SortOrder="LayoutOrder",
Padding=UDim.new(0,ar.Gap),
HorizontalAlignment="Center",
}),
})





ar.UIElements.ContainerFrameCanvas=al("Frame",{
Size=UDim2.new(1,0,1,0),
BackgroundTransparency=1,
Visible=false,
Parent=Window.UIElements.MainBar,
ZIndex=5,
},{
ar.UIElements.ContainerFrame,
al("Frame",{
Size=UDim2.new(1,-14,1,-14),
Position=UDim2.new(0.5,0,0.5,0),
AnchorPoint=Vector2.new(0.5,0.5),
BackgroundTransparency=1,
Name="ScrollSliderHolder",
}),
al("Frame",{
Size=UDim2.new(1,0,0,((Window.UIPadding*2.4)+12)),
BackgroundTransparency=1,
Visible=ar.ShowTabTitle or false,
Name="TabTitle",
},{
av,
al("TextLabel",{
Text=ar.Title,
ThemeTag={
TextColor3="Text",
},
TextSize=20,
TextTransparency=0.1,
Size=UDim2.new(0,0,1,0),
FontFace=Font.new(ak.Font,Enum.FontWeight.SemiBold),

RichText=true,
LayoutOrder=2,
TextXAlignment="Left",
BackgroundTransparency=1,
AutomaticSize="X",
}),
al("UIPadding",{
PaddingTop=UDim.new(0,20),
PaddingLeft=UDim.new(0,20),
PaddingRight=UDim.new(0,20),
PaddingBottom=UDim.new(0,20),
}),
al("UIListLayout",{
SortOrder="LayoutOrder",
Padding=UDim.new(0,10),
FillDirection="Horizontal",
VerticalAlignment="Center",
HorizontalAlignment=ar.TabTitleAlign,
}),
}),
al("Frame",{
Size=UDim2.new(1,0,0,1),
BackgroundTransparency=0.9,
ThemeTag={
BackgroundColor3="Text",
},
Position=UDim2.new(0,0,0,((Window.UIPadding*2.4)+12)),
Visible=ar.ShowTabTitle or false,
}),
})

ao.Containers[as]=ar.UIElements.ContainerFrameCanvas
ao.Tabs[as]=ar

ar.ContainerFrame=ar.UIElements.ContainerFrameCanvas

ak.AddSignal(ar.UIElements.Main.MouseButton1Click,function()
if not ar.Locked then
ao:SelectTab(as)
end
end)

if Window.ScrollBarEnabled then
an(
ar.UIElements.ContainerFrame,
ar.UIElements.ContainerFrameCanvas.ScrollSliderHolder,
Window,
4,
WindUI
)
end

local aw
local ax
local ay
local az=false


if ar.Desc then
ak.AddSignal(ar.UIElements.Main.InputBegan,function()
az=true
ax=task.spawn(function()
task.wait(0.35)
if az and not aw then
aw=am(ar.Desc,ao.ToolTipParent,true)
aw.Container.AnchorPoint=Vector2.new(0.5,0.5)

local function updatePosition()
if aw then
aw.Container.Position=UDim2.new(0,ai.X,0,ai.Y-4)
end
end

updatePosition()
ay=ai.Move:Connect(updatePosition)
aw:Open()
end
end)
end)
end

ak.AddSignal(ar.UIElements.Main.MouseEnter,function()
if not ar.Locked then
ak.SetThemeTag(ar.UIElements.Main.Frame,{
ImageTransparency="TabBackgroundHoverTransparency",
ImageColor3="TabBackgroundHover",
},0.1)
end
end)
ak.AddSignal(ar.UIElements.Main.InputEnded,function()
if ar.Desc then
az=false
if ax then
task.cancel(ax)
ax=nil
end
if ay then
ay:Disconnect()
ay=nil
end
if aw then
aw:Close()
aw=nil
end
end

if not ar.Locked then
ak.SetThemeTag(ar.UIElements.Main.Frame,{
ImageTransparency="TabBorderTransparency",
},0.1)
end
end)

function ar.ScrollToTheElement(aA,aB)
ar.UIElements.ContainerFrame.ScrollingEnabled=false

ak.Tween(ar.UIElements.ContainerFrame,0.45,{
CanvasPosition=Vector2.new(
0,
ar.Elements[aB].ElementFrame.AbsolutePosition.Y
-ar.UIElements.ContainerFrame.AbsolutePosition.Y
-ar.UIElements.ContainerFrame.UIPadding.PaddingTop.Offset
),
},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()

task.spawn(function()
task.wait(0.48)

if ar.Elements[aB].Highlight then
ar.Elements[aB]:Highlight()
end
ar.UIElements.ContainerFrame.ScrollingEnabled=true
end)

return ar
end



local aA=a.load'_'

aA.Load(
ar,
ar.UIElements.ContainerFrame,
aA.Elements,
Window,
WindUI,
nil,
aA,
aq,
ar
)

function ar.LockAll(aB)

for b,d in next,Window.AllElements do
if d.Tab and d.Tab.Index and d.Tab.Index==ar.Index and d.Lock then
d:Lock()
end
end
end
function ar.UnlockAll(aB)
for b,d in next,Window.AllElements do
if d.Tab and d.Tab.Index and d.Tab.Index==ar.Index and d.Unlock then
d:Unlock()
end
end
end
function ar.GetLocked(aB)
local b={}

for d,f in next,Window.AllElements do
if f.Tab and f.Tab.Index and f.Tab.Index==ar.Index and f.Locked==true then
table.insert(b,f)
end
end

return b
end
function ar.GetUnlocked(aB)
local b={}

for d,f in next,Window.AllElements do
if f.Tab and f.Tab.Index and f.Tab.Index==ar.Index and f.Locked==false then
table.insert(b,f)
end
end

return b
end

function ar.Select(aB)
return ao:SelectTab(ar.Index)
end

task.spawn(function()
local aB
if ar.CustomEmptyPage.Icon then
aB=
ak.Image(ar.CustomEmptyPage.Icon,ar.CustomEmptyPage.Icon,0,"Temp","EmptyPage",true)
aB.Size=
UDim2.fromOffset(ar.CustomEmptyPage.IconSize or 48,ar.CustomEmptyPage.IconSize or 48)
end

local b=al("Frame",{
BackgroundTransparency=1,
Size=UDim2.new(1,0,1,-Window.UIElements.Main.Main.Topbar.AbsoluteSize.Y),
Parent=ar.UIElements.ContainerFrame,
},{
al("UIListLayout",{
Padding=UDim.new(0,8),
SortOrder="LayoutOrder",
VerticalAlignment="Center",
HorizontalAlignment="Center",
FillDirection="Vertical",
}),











aB,
ar.CustomEmptyPage.Title and al("TextLabel",{
AutomaticSize="XY",
Text=ar.CustomEmptyPage.Title,
ThemeTag={
TextColor3="Text",
},
TextSize=18,
TextTransparency=0.5,
BackgroundTransparency=1,
FontFace=Font.new(ak.Font,Enum.FontWeight.Medium),
})or nil,
ar.CustomEmptyPage.Desc and al("TextLabel",{
AutomaticSize="XY",
Text=ar.CustomEmptyPage.Desc,
ThemeTag={
TextColor3="Text",
},
TextSize=15,
TextTransparency=0.65,
BackgroundTransparency=1,
FontFace=Font.new(ak.Font,Enum.FontWeight.Regular),
})or nil,
})





local d
d=ak.AddSignal(ar.UIElements.ContainerFrame.ChildAdded,function()
b.Visible=false
d:Disconnect()
end)
end)

return ar
end

function ao.OnChange(ap,aq)
ao.OnChangeFunc=aq
end

function ao.SelectTab(ap,aq)
if not ao.Tabs[aq].Locked then
ao.SelectedTab=aq

for ar,as in next,ao.Tabs do
if not as.Locked then
ak.SetThemeTag(as.UIElements.Main,{
ImageTransparency="TabBorderTransparency",
},0.15)
if as.Border then
ak.SetThemeTag(as.UIElements.Main.Outline,{
ImageTransparency="TabBorderTransparency",
},0.15)
end
ak.SetThemeTag(as.UIElements.Main.Frame.TextLabel,{
TextTransparency="TabTextTransparency",
},0.15)
if as.UIElements.Icon and not as.IconColor then
ak.SetThemeTag(as.UIElements.Icon.ImageLabel,{
ImageTransparency="TabIconTransparency",
},0.15)
end
as.Selected=false
end
end
ak.SetThemeTag(ao.Tabs[aq].UIElements.Main,{
ImageColor3="TabBackgroundActive",
ImageTransparency="TabBackgroundActiveTransparency",
},0.15)
if ao.Tabs[aq].Border then
ak.SetThemeTag(ao.Tabs[aq].UIElements.Main.Outline,{
ImageTransparency="TabBorderTransparencyActive",
},0.15)
end
ak.SetThemeTag(ao.Tabs[aq].UIElements.Main.Frame.TextLabel,{
TextTransparency="TabTextTransparencyActive",
},0.15)
if ao.Tabs[aq].UIElements.Icon and not ao.Tabs[aq].IconColor then
ak.SetThemeTag(ao.Tabs[aq].UIElements.Icon.ImageLabel,{
ImageTransparency="TabIconTransparencyActive",
},0.15)
end
ao.Tabs[aq].Selected=true

task.spawn(function()
for ar,as in next,ao.Containers do
as.AnchorPoint=Vector2.new(0,0.05)
as.Visible=false
end
ao.Containers[aq].Visible=true
local ar=game:GetService"TweenService"

local as=TweenInfo.new(0.15,Enum.EasingStyle.Quart,Enum.EasingDirection.Out)
local at=ar:Create(ao.Containers[aq],as,{
AnchorPoint=Vector2.new(0,0),
})
at:Play()
end)

ao.OnChangeFunc(aq)
end
end

return ao end function a.ab()

local aa={}


local af=a.load'd'
local ai=af.New
local ak=af.Tween

local al=a.load'aa'

function aa.New(am,an,ao,ap,aq)
local ar={
Title=am.Title or"Section",
Icon=am.Icon,
IconThemed=am.IconThemed,
Opened=am.Opened or false,

HeaderSize=42,
IconSize=18,

Expandable=false,
}

local as
if ar.Icon then
as=af.Image(
ar.Icon,
ar.Icon,
0,
ao,
"Section",
true,
ar.IconThemed,
"TabSectionIcon"
)

as.Size=UDim2.new(0,ar.IconSize,0,ar.IconSize)
as.ImageLabel.ImageTransparency=.25
end

local at=ai("Frame",{
Size=UDim2.new(0,ar.IconSize,0,ar.IconSize),
BackgroundTransparency=1,
Visible=false
},{
ai("ImageLabel",{
Size=UDim2.new(1,0,1,0),
BackgroundTransparency=1,
Image=af.Icon"chevron-down"[1],
ImageRectSize=af.Icon"chevron-down"[2].ImageRectSize,
ImageRectOffset=af.Icon"chevron-down"[2].ImageRectPosition,
ThemeTag={
ImageColor3="Icon",
},
ImageTransparency=.7,
})
})

local au=ai("Frame",{
Size=UDim2.new(1,0,0,ar.HeaderSize),
BackgroundTransparency=1,
Parent=an,
ClipsDescendants=true,
},{
ai("TextButton",{
Size=UDim2.new(1,0,0,ar.HeaderSize),
BackgroundTransparency=1,
Text="",
},{
as,
ai("TextLabel",{
Text=ar.Title,
TextXAlignment="Left",
Size=UDim2.new(
1,
as and(-ar.IconSize-10)*2
or(-ar.IconSize-10),

1,
0
),
ThemeTag={
TextColor3="Text",
},
FontFace=Font.new(af.Font,Enum.FontWeight.SemiBold),
TextSize=14,
BackgroundTransparency=1,
TextTransparency=.7,

TextWrapped=true
}),
ai("UIListLayout",{
FillDirection="Horizontal",
VerticalAlignment="Center",
Padding=UDim.new(0,10)
}),
at,
ai("UIPadding",{
PaddingLeft=UDim.new(0,11),
PaddingRight=UDim.new(0,11),
})
}),
ai("Frame",{
BackgroundTransparency=1,
Size=UDim2.new(1,0,0,0),
AutomaticSize="Y",
Name="Content",
Visible=true,
Position=UDim2.new(0,0,0,ar.HeaderSize)
},{
ai("UIListLayout",{
FillDirection="Vertical",
Padding=UDim.new(0,aq.Gap),
VerticalAlignment="Bottom",
}),
})
})


function ar.Tab(av,aw)
if not ar.Expandable then
ar.Expandable=true
at.Visible=true
end
aw.Parent=au.Content
return al.New(aw,ap)
end

function ar.Open(av)
if ar.Expandable then
ar.Opened=true
ak(au,0.33,{
Size=UDim2.new(1,0,0,ar.HeaderSize+(au.Content.AbsoluteSize.Y/ap))
},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()

ak(at.ImageLabel,0.1,{Rotation=180},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
end
end
function ar.Close(av)
if ar.Expandable then
ar.Opened=false
ak(au,0.26,{
Size=UDim2.new(1,0,0,ar.HeaderSize)
},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
ak(at.ImageLabel,0.1,{Rotation=0},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
end
end

af.AddSignal(au.TextButton.MouseButton1Click,function()
if ar.Expandable then
if ar.Opened then
ar:Close()
else
ar:Open()
end
end
end)

af.AddSignal(au.Content.UIListLayout:GetPropertyChangedSignal"AbsoluteContentSize",function()
if ar.Opened then
ar:Open()
end
end)

if ar.Opened then
task.spawn(function()
task.wait()
ar:Open()
end)
end



return ar
end


return aa end function a.ac()
return{
Tab="table-of-contents",
Paragraph="type",
Button="square-mouse-pointer",
Toggle="toggle-right",
Slider="sliders-horizontal",
Keybind="command",
Input="text-cursor-input",
Dropdown="chevrons-up-down",
Code="terminal",
Colorpicker="palette",
}end function a.ad()
local aa=(cloneref or clonereference or function(aa)
return aa
end)

aa(game:GetService"UserInputService")

local af={
Margin=8,
Padding=9,
}

local ai=a.load'd'
local ak=ai.New
local al=ai.Tween

function af.new(am,an,ao)
local ap={
IconSize=18,
Padding=14,
Radius=22,
Width=400,
MaxHeight=380,

Icons=a.load'ac',
}

local aq=ak("TextBox",{
Text="",
PlaceholderText="Search...",
ThemeTag={
PlaceholderColor3="Placeholder",
TextColor3="Text",
},
Size=UDim2.new(1,-((ap.IconSize*2)+(ap.Padding*2)),0,0),
AutomaticSize="Y",
ClipsDescendants=true,
ClearTextOnFocus=false,
BackgroundTransparency=1,
TextXAlignment="Left",
FontFace=Font.new(ai.Font,Enum.FontWeight.Regular),
TextSize=18,
})

local ar=ak("ImageLabel",{
Image=ai.Icon"x"[1],
ImageRectSize=ai.Icon"x"[2].ImageRectSize,
ImageRectOffset=ai.Icon"x"[2].ImageRectPosition,
BackgroundTransparency=1,
ThemeTag={
ImageColor3="Icon",
},
ImageTransparency=0.1,
Size=UDim2.new(0,ap.IconSize,0,ap.IconSize),
},{
ak("TextButton",{
Size=UDim2.new(1,8,1,8),
BackgroundTransparency=1,
Active=true,
ZIndex=999999999,
AnchorPoint=Vector2.new(0.5,0.5),
Position=UDim2.new(0.5,0,0.5,0),
Text="",
}),
})

local as=ak("ScrollingFrame",{
Size=UDim2.new(1,0,0,0),
AutomaticCanvasSize="Y",
ScrollingDirection="Y",
ElasticBehavior="Never",
ScrollBarThickness=0,
CanvasSize=UDim2.new(0,0,0,0),
BackgroundTransparency=1,
Visible=false,
},{
ak("UIListLayout",{
Padding=UDim.new(0,0),
FillDirection="Vertical",
}),
ak("UIPadding",{
PaddingTop=UDim.new(0,ap.Padding),
PaddingLeft=UDim.new(0,ap.Padding),
PaddingRight=UDim.new(0,ap.Padding),
PaddingBottom=UDim.new(0,ap.Padding),
}),
})

local at=ai.NewRoundFrame(ap.Radius,"Squircle",{
Size=UDim2.new(1,0,1,0),
ThemeTag={
ImageColor3="WindowSearchBarBackground",
},
ImageTransparency=0,
},{
ai.NewRoundFrame(ap.Radius,"Squircle",{
Size=UDim2.new(1,0,1,0),
BackgroundTransparency=1,

Visible=false,
ThemeTag={
ImageColor3="White",
},
ImageTransparency=1,
Name="Frame",
},{
ak("Frame",{
Size=UDim2.new(1,0,0,46),
BackgroundTransparency=1,
},{








ak("Frame",{
Size=UDim2.new(1,0,1,0),
BackgroundTransparency=1,
},{
ak("ImageLabel",{
Image=ai.Icon"search"[1],
ImageRectSize=ai.Icon"search"[2].ImageRectSize,
ImageRectOffset=ai.Icon"search"[2].ImageRectPosition,
BackgroundTransparency=1,
ThemeTag={
ImageColor3="Icon",
},
ImageTransparency=0.1,
Size=UDim2.new(0,ap.IconSize,0,ap.IconSize),
}),
aq,
ar,
ak("UIListLayout",{
Padding=UDim.new(0,ap.Padding),
FillDirection="Horizontal",
VerticalAlignment="Center",
}),
ak("UIPadding",{
PaddingLeft=UDim.new(0,ap.Padding),
PaddingRight=UDim.new(0,ap.Padding),
}),
}),
}),
ak("Frame",{
BackgroundTransparency=1,
AutomaticSize="Y",
Size=UDim2.new(1,0,0,0),
Name="Results",
},{
ak("Frame",{
Size=UDim2.new(1,0,0,1),
ThemeTag={
BackgroundColor3="Outline",
},
BackgroundTransparency=0.9,
Visible=false,
}),
as,
ak("UISizeConstraint",{
MaxSize=Vector2.new(ap.Width,ap.MaxHeight),
}),
}),
ak("UIListLayout",{
Padding=UDim.new(0,0),
FillDirection="Vertical",
}),
}),
})

local au=ak("Frame",{
Size=UDim2.new(0,ap.Width,0,0),
AutomaticSize="Y",
Parent=an,
BackgroundTransparency=1,
Position=UDim2.new(0.5,0,0.5,0),
AnchorPoint=Vector2.new(0.5,0.5),
Visible=false,

ZIndex=99999999,
},{
ak("UIScale",{
Scale=0.9,
}),
at,















})

local function CreateSearchTab(av,aw,ax,ay,az,aA)
local aB=ak("TextButton",{
Size=UDim2.new(1,0,0,0),
AutomaticSize="Y",
BackgroundTransparency=1,
Parent=ay or nil,
},{
ai.NewRoundFrame(ap.Radius-11,"Squircle",{
Size=UDim2.new(1,0,0,0),
Position=UDim2.new(0.5,0,0.5,0),
AnchorPoint=Vector2.new(0.5,0.5),

ThemeTag={
ImageColor3="Text",
},
ImageTransparency=1,
Name="Main",
},{
ai.NewRoundFrame(ap.Radius-11,"Glass-1",{
Size=UDim2.new(1,0,1,0),
Position=UDim2.new(0.5,0,0.5,0),
AnchorPoint=Vector2.new(0.5,0.5),
ThemeTag={
ImageColor3="White",
},
ImageTransparency=1,
Name="Outline",
},{








ak("UIPadding",{
PaddingTop=UDim.new(0,ap.Padding-2),
PaddingLeft=UDim.new(0,ap.Padding),
PaddingRight=UDim.new(0,ap.Padding),
PaddingBottom=UDim.new(0,ap.Padding-2),
}),
ak("ImageLabel",{
Image=ai.Icon(ax)[1],
ImageRectSize=ai.Icon(ax)[2].ImageRectSize,
ImageRectOffset=ai.Icon(ax)[2].ImageRectPosition,
BackgroundTransparency=1,
ThemeTag={
ImageColor3="Icon",
},
ImageTransparency=0.1,
Size=UDim2.new(0,ap.IconSize,0,ap.IconSize),
}),
ak("Frame",{
Size=UDim2.new(1,-ap.IconSize-ap.Padding,0,0),
BackgroundTransparency=1,
},{
ak("TextLabel",{
Text=av,
ThemeTag={
TextColor3="Text",
},
TextSize=17,
BackgroundTransparency=1,
TextXAlignment="Left",
FontFace=Font.new(ai.Font,Enum.FontWeight.Medium),
Size=UDim2.new(1,0,0,0),
TextTruncate="AtEnd",
AutomaticSize="Y",
Name="Title",
}),
ak("TextLabel",{
Text=aw or"",
Visible=aw and true or false,
ThemeTag={
TextColor3="Text",
},
TextSize=15,
TextTransparency=0.3,
BackgroundTransparency=1,
TextXAlignment="Left",
FontFace=Font.new(ai.Font,Enum.FontWeight.Medium),
Size=UDim2.new(1,0,0,0),
TextTruncate="AtEnd",
AutomaticSize="Y",
Name="Desc",
})or nil,
ak("UIListLayout",{
Padding=UDim.new(0,6),
FillDirection="Vertical",
}),
}),
ak("UIListLayout",{
Padding=UDim.new(0,ap.Padding),
FillDirection="Horizontal",
}),
}),
},true),
ak("Frame",{
Name="ParentContainer",
Size=UDim2.new(1,-ap.Padding,0,0),
AutomaticSize="Y",
BackgroundTransparency=1,
Visible=az,

},{
ai.NewRoundFrame(99,"Squircle",{
Size=UDim2.new(0,2,1,0),
BackgroundTransparency=1,
ThemeTag={
ImageColor3="Text",
},
ImageTransparency=0.9,
}),
ak("Frame",{
Size=UDim2.new(1,-ap.Padding-2,0,0),
Position=UDim2.new(0,ap.Padding+2,0,0),
BackgroundTransparency=1,
},{
ak("UIListLayout",{
Padding=UDim.new(0,0),
FillDirection="Vertical",
}),
}),
}),
ak("UIListLayout",{
Padding=UDim.new(0,0),
FillDirection="Vertical",
HorizontalAlignment="Right",
}),
})



aB.Main.Size=UDim2.new(
1,
0,
0,
aB.Main.Outline.Frame.Desc.Visible
and(((ap.Padding-2)*2)+aB.Main.Outline.Frame.Title.TextBounds.Y+6+aB.Main.Outline.Frame.Desc.TextBounds.Y)
or(((ap.Padding-2)*2)+aB.Main.Outline.Frame.Title.TextBounds.Y)
)

ai.AddSignal(aB.Main.MouseEnter,function()
al(aB.Main,0.04,{ImageTransparency=0.95}):Play()

end)
ai.AddSignal(aB.Main.InputEnded,function()
al(aB.Main,0.08,{ImageTransparency=1}):Play()

end)
ai.AddSignal(aB.Main.MouseButton1Click,function()
if aA then
aA()
end
end)

return aB
end

local function ContainsText(av,aw)
if not aw or aw==""then
return false
end

if not av or av==""then
return false
end

local ax=string.lower(av)
local ay=string.lower(aw)

return string.find(ax,ay,1,true)~=nil
end

local function Search(av)
if not av or av==""then
return{}
end

local aw={}
for ax,ay in next,am.Tabs do
local az=ContainsText(ay.Title or"",av)
local aA={}

for aB,b in next,ay.Elements do
if b.__type~="Section"then
local d=ContainsText(b.Title or"",av)
local f=ContainsText(b.Desc or"",av)

if d or f then
aA[aB]={
Title=b.Title,
Desc=b.Desc,
Original=b,
__type=b.__type,
Index=aB,
}
end
end
end

if az or next(aA)~=nil then
aw[ax]={
Tab=ay,
Title=ay.Title,
Icon=ay.Icon,
Elements=aA,
}
end
end
return aw
end

ai.AddSignal(as.UIListLayout:GetPropertyChangedSignal"AbsoluteContentSize",function()

al(as,0.06,{
Size=UDim2.new(
1,
0,
0,
math.clamp(
as.UIListLayout.AbsoluteContentSize.Y+(ap.Padding*2),
0,
ap.MaxHeight
)
),
},Enum.EasingStyle.Quint,Enum.EasingDirection.InOut):Play()






end)

function ap.Open(av)
task.spawn(function()
at.Frame.Visible=true
au.Visible=true
al(au.UIScale,0.12,{Scale=1},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
end)
end

function ap.Close(av,aw)
task.spawn(function()
ao()
at.Frame.Visible=false
al(au.UIScale,0.12,{Scale=1},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()

task.wait(0.12)
au.Visible=false
if aw then
au:Destroy()
end
end)
end

ai.AddSignal(ar.TextButton.MouseButton1Click,function()
ap:Close(true)
end)

ap:Open()

function ap.Search(av,aw)
aw=aw or""

local ax=Search(aw)

as.Visible=true
at.Frame.Results.Frame.Visible=true
for ay,az in next,as:GetChildren()do
if az.ClassName~="UIListLayout"and az.ClassName~="UIPadding"then
az:Destroy()
end
end

if ax and next(ax)~=nil then
for ay,az in next,ax do
local aA=ap.Icons.Tab
local aB=CreateSearchTab(az.Title,nil,aA,as,true,function()
ap:Close()
am:SelectTab(ay)
end)
if az.Elements and next(az.Elements)~=nil then
for b,d in next,az.Elements do
local f=ap.Icons[d.__type]
CreateSearchTab(
d.Title,
d.Desc,
f,
aB:FindFirstChild"ParentContainer"and aB.ParentContainer.Frame
or nil,
false,
function()
ap:Close()
am:SelectTab(ay)
if az.Tab.ScrollToTheElement then

az.Tab:ScrollToTheElement(d.Index)
end

end
)

end
end
end
elseif aw~=""then
ak("TextLabel",{
Size=UDim2.new(1,0,0,70),
Text="No results found",
TextSize=16,
ThemeTag={
TextColor3="Text",
},
TextTransparency=0.2,
BackgroundTransparency=1,
FontFace=Font.new(ai.Font,Enum.FontWeight.Medium),
Parent=as,
Name="NotFound",
})
else
as.Visible=false
at.Frame.Results.Frame.Visible=false
end
end

ai.AddSignal(aq:GetPropertyChangedSignal"Text",function()
ap:Search(aq.Text)
end)

return ap
end

return af end function a.ae()



local aa=(cloneref or clonereference or function(aa)
return aa
end)

local af=aa(game:GetService"UserInputService")
local ai=aa(game:GetService"RunService")
local ak=aa(game:GetService"Players")

local al=workspace.CurrentCamera

local am=a.load't'

local an=a.load'd'
local ao=an.New
local ap=an.Tween


local aq=a.load'w'.New
local ar=a.load'm'.New
local as=a.load'x'.New
local at=a.load'y'

local au=a.load'z'



return function(av)
local aw={
Title=av.Title or"UI Library",
Author=av.Author,
Icon=av.Icon,
IconSize=av.IconSize or 22,
IconThemed=av.IconThemed,
IconRadius=av.IconRadius or 0,
Folder=av.Folder,
Resizable=av.Resizable~=false,
Background=av.Background,
BackgroundImageTransparency=av.BackgroundImageTransparency or 0,
ShadowTransparency=av.ShadowTransparency or 0.6,
User=av.User or{},
Footer=av.Footer or{},
Topbar=av.Topbar or{Height=52,ButtonsType="Default"},

Size=av.Size,

MinSize=av.MinSize or Vector2.new(560,350),
MaxSize=av.MaxSize or Vector2.new(850,560),

TopBarButtonIconSize=av.TopBarButtonIconSize,

ToggleKey=av.ToggleKey,
ElementsRadius=av.ElementsRadius,
Radius=av.Radius or 16,
Transparent=av.Transparent or false,
HideSearchBar=av.HideSearchBar~=false,
ScrollBarEnabled=av.ScrollBarEnabled or false,
SideBarWidth=av.SideBarWidth or 200,
Acrylic=av.Acrylic or false,
NewElements=av.NewElements or false,
IgnoreAlerts=av.IgnoreAlerts or false,
HidePanelBackground=av.HidePanelBackground or false,
AutoScale=av.AutoScale~=false,
OpenButton=av.OpenButton,
DragFrameSize=160,

Position=UDim2.new(0.5,0,0.5,0),
UICorner=16,
UIPadding=14,
UIElements={},
CanDropdown=true,
Closed=false,
Parent=av.Parent,
Destroyed=false,
IsFullscreen=false,
CanResize=av.Resizable~=false,
IsOpenButtonEnabled=true,

CurrentConfig=nil,
ConfigManager=nil,
AcrylicPaint=nil,
CurrentTab=nil,
TabModule=nil,

OnOpenCallback=nil,
OnCloseCallback=nil,
OnDestroyCallback=nil,

IsPC=false,

Gap=5,

TopBarButtons={},
AllElements={},

ElementConfig={},

PendingFlags={},

IsToggleDragging=false,
}

aw.UICorner=aw.Radius

aw.TopBarButtonIconSize=aw.TopBarButtonIconSize or(aw.Topbar.ButtonsType=="Mac"and 11 or 16)

aw.ElementConfig={
UIPadding=(aw.NewElements and 10 or 13),
UICorner=aw.ElementsRadius or(aw.NewElements and 23 or 16),
}

local ax=aw.Size or UDim2.new(0,580,0,460)
aw.Size=UDim2.new(
ax.X.Scale,
math.clamp(ax.X.Offset,aw.MinSize.X,aw.MaxSize.X),
ax.Y.Scale,
math.clamp(ax.Y.Offset,aw.MinSize.Y,aw.MaxSize.Y)
)

if aw.Topbar=={}then
aw.Topbar={Height=52,ButtonsType="Default"}
end

if not ai:IsStudio()and aw.Folder and writefile then
if not isfolder("WindUI/"..aw.Folder)then
makefolder("WindUI/"..aw.Folder)
end
if not isfolder("WindUI/"..aw.Folder.."/assets")then
makefolder("WindUI/"..aw.Folder.."/assets")
end
if not isfolder(aw.Folder)then
makefolder(aw.Folder)
end
if not isfolder(aw.Folder.."/assets")then
makefolder(aw.Folder.."/assets")
end
end

local ay=ao("UICorner",{
CornerRadius=UDim.new(0,aw.UICorner),
})

if aw.Folder then
aw.ConfigManager=au:Init(aw)
end

if aw.Acrylic then local
az=am.AcrylicPaint{UseAcrylic=aw.Acrylic}

aw.AcrylicPaint=az
end

local az=ao("Frame",{
Size=UDim2.new(0,32,0,32),
Position=UDim2.new(1,0,1,0),
AnchorPoint=Vector2.new(0.5,0.5),
BackgroundTransparency=1,
ZIndex=99,
Active=true,
},{
ao("ImageLabel",{
Size=UDim2.new(0,96,0,96),
BackgroundTransparency=1,
Image="rbxassetid://120997033468887",
Position=UDim2.new(0.5,-16,0.5,-16),
AnchorPoint=Vector2.new(0.5,0.5),
ImageTransparency=1,
}),
})
local aA=an.NewRoundFrame(aw.UICorner,"Squircle",{
Size=UDim2.new(1,0,1,0),
ImageTransparency=1,
ImageColor3=Color3.new(0,0,0),
ZIndex=98,
Active=false,
},{
ao("ImageLabel",{
Size=UDim2.new(0,70,0,70),
Image=an.Icon"expand"[1],
ImageRectOffset=an.Icon"expand"[2].ImageRectPosition,
ImageRectSize=an.Icon"expand"[2].ImageRectSize,
BackgroundTransparency=1,
Position=UDim2.new(0.5,0,0.5,0),
AnchorPoint=Vector2.new(0.5,0.5),
ImageTransparency=1,
}),
})

local aB=an.NewRoundFrame(aw.UICorner,"Squircle",{
Size=UDim2.new(1,0,1,0),
ImageTransparency=1,
ImageColor3=Color3.new(0,0,0),
ZIndex=999,
Active=false,
})









aw.UIElements.SideBar=ao("ScrollingFrame",{
Size=UDim2.new(
1,
aw.ScrollBarEnabled and-3-(aw.UIPadding/2)or 0,
1,
not aw.HideSearchBar and-45 or 0
),
Position=UDim2.new(0,0,1,0),
AnchorPoint=Vector2.new(0,1),
BackgroundTransparency=1,
ScrollBarThickness=0,
ElasticBehavior="Never",
CanvasSize=UDim2.new(0,0,0,0),
AutomaticCanvasSize="Y",
ScrollingDirection="Y",
ClipsDescendants=true,
VerticalScrollBarPosition="Left",
},{
ao("Frame",{
BackgroundTransparency=1,
AutomaticSize="Y",
Size=UDim2.new(1,0,0,0),
Name="Frame",
},{
ao("UIPadding",{



PaddingBottom=UDim.new(0,aw.UIPadding/2),
}),
ao("UIListLayout",{
SortOrder="LayoutOrder",
Padding=UDim.new(0,aw.Gap),
}),
}),
ao("UIPadding",{

PaddingLeft=UDim.new(0,aw.UIPadding/2),
PaddingRight=UDim.new(0,aw.UIPadding/2),
PaddingBottom=UDim.new(0,aw.UIPadding/2),
}),

})

aw.UIElements.SideBarContainer=ao("Frame",{
Size=UDim2.new(
0,
aw.SideBarWidth,
1,
aw.User.Enabled and-aw.Topbar.Height-42-(aw.UIPadding*2)or-aw.Topbar.Height
),
Position=UDim2.new(0,0,0,aw.Topbar.Height),
BackgroundTransparency=1,
Visible=true,
},{
ao("Frame",{
Name="Content",
BackgroundTransparency=1,
Size=UDim2.new(1,0,1,not aw.HideSearchBar and-45-aw.UIPadding or-aw.UIPadding/2),
Position=UDim2.new(0,0,1,-aw.UIPadding/2),
AnchorPoint=Vector2.new(0,1),
}),
aw.UIElements.SideBar,
})

if aw.ScrollBarEnabled then
as(
aw.UIElements.SideBar,
aw.UIElements.SideBarContainer.Content,
aw,
3,
av.WindUI
)
end

aw.UIElements.MainBar=ao("Frame",{
Size=UDim2.new(1,-aw.UIElements.SideBarContainer.AbsoluteSize.X,1,-aw.Topbar.Height),
Position=UDim2.new(1,0,1,0),
AnchorPoint=Vector2.new(1,1),
BackgroundTransparency=1,
},{
an.NewRoundFrame(aw.UICorner-(aw.UIPadding/2),"Squircle",{
Size=UDim2.new(1,0,1,0),
ThemeTag={
ImageColor3="PanelBackground",
ImageTransparency="PanelBackgroundTransparency",
},


ZIndex=3,
Name="Background",
Visible=not aw.HidePanelBackground,
}),
ao("UIPadding",{

PaddingLeft=UDim.new(0,aw.UIPadding/2),
PaddingRight=UDim.new(0,aw.UIPadding/2),
PaddingBottom=UDim.new(0,aw.UIPadding/2),
}),
})

local b=ao("ImageLabel",{
Image="rbxassetid://8992230677",
ThemeTag={
ImageColor3="WindowShadow",

},
ImageTransparency=1,
Size=UDim2.new(1,100,1,100),
Position=UDim2.new(0,-50,0,-50),
ScaleType="Slice",
SliceCenter=Rect.new(99,99,99,99),
BackgroundTransparency=1,
ZIndex=-999999999999999,
Name="Blur",
})

if af.TouchEnabled and not af.KeyboardEnabled then
aw.IsPC=false
elseif af.KeyboardEnabled then
aw.IsPC=true
else
aw.IsPC=nil
end







local d
if aw.User then
local function GetUserThumb()local
f=ak:GetUserThumbnailAsync(
aw.User.Anonymous and 1 or ak.LocalPlayer.UserId,
Enum.ThumbnailType.HeadShot,
Enum.ThumbnailSize.Size420x420
)
return f
end

d=ao("TextButton",{
Size=UDim2.new(
0,
aw.UIElements.SideBarContainer.AbsoluteSize.X-(aw.UIPadding/2),
0,
42+aw.UIPadding
),
Position=UDim2.new(0,aw.UIPadding/2,1,-(aw.UIPadding/2)),
AnchorPoint=Vector2.new(0,1),
BackgroundTransparency=1,
Visible=aw.User.Enabled or false,
},{
an.NewRoundFrame(aw.UICorner-(aw.UIPadding/2),"SquircleOutline",{
Size=UDim2.new(1,0,1,0),
ThemeTag={
ImageColor3="Text",
},
ImageTransparency=1,
Name="Outline",
},{
ao("UIGradient",{
Rotation=78,
Color=ColorSequence.new{
ColorSequenceKeypoint.new(0.0,Color3.fromRGB(255,255,255)),
ColorSequenceKeypoint.new(0.5,Color3.fromRGB(255,255,255)),
ColorSequenceKeypoint.new(1.0,Color3.fromRGB(255,255,255)),
},
Transparency=NumberSequence.new{
NumberSequenceKeypoint.new(0.0,0.1),
NumberSequenceKeypoint.new(0.5,1),
NumberSequenceKeypoint.new(1.0,0.1),
},
}),
}),
an.NewRoundFrame(aw.UICorner-(aw.UIPadding/2),"Squircle",{
Size=UDim2.new(1,0,1,0),
ThemeTag={
ImageColor3="Text",
},
ImageTransparency=1,
Name="UserIcon",
},{
ao("ImageLabel",{
Image=GetUserThumb(),
BackgroundTransparency=1,
Size=UDim2.new(0,42,0,42),
ThemeTag={
BackgroundColor3="Text",
},
BackgroundTransparency=0.93,
},{
ao("UICorner",{
CornerRadius=UDim.new(1,0),
}),
}),
ao("Frame",{
AutomaticSize="XY",
BackgroundTransparency=1,
},{
ao("TextLabel",{
Text=aw.User.Anonymous and"Anonymous"or ak.LocalPlayer.DisplayName,
TextSize=17,
ThemeTag={
TextColor3="Text",
},
FontFace=Font.new(an.Font,Enum.FontWeight.SemiBold),
AutomaticSize="Y",
BackgroundTransparency=1,
Size=UDim2.new(1,-27,0,0),
TextTruncate="AtEnd",
TextXAlignment="Left",
Name="DisplayName",
}),
ao("TextLabel",{
Text=aw.User.Anonymous and"anonymous"or ak.LocalPlayer.Name,
TextSize=15,
TextTransparency=0.6,
ThemeTag={
TextColor3="Text",
},
FontFace=Font.new(an.Font,Enum.FontWeight.Medium),
AutomaticSize="Y",
BackgroundTransparency=1,
Size=UDim2.new(1,-27,0,0),
TextTruncate="AtEnd",
TextXAlignment="Left",
Name="UserName",
}),
ao("UIListLayout",{
Padding=UDim.new(0,4),
HorizontalAlignment="Left",
}),
}),
ao("UIListLayout",{
Padding=UDim.new(0,aw.UIPadding),
FillDirection="Horizontal",
VerticalAlignment="Center",
}),
ao("UIPadding",{
PaddingLeft=UDim.new(0,aw.UIPadding/2),
PaddingRight=UDim.new(0,aw.UIPadding/2),
}),
}),
})

function aw.User.Enable(f)
aw.User.Enabled=true
ap(
aw.UIElements.SideBarContainer,
0.25,
{Size=UDim2.new(0,aw.SideBarWidth,1,-aw.Topbar.Height-42-(aw.UIPadding*2))},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()
d.Visible=true
end
function aw.User.Disable(f)
aw.User.Enabled=false
ap(
aw.UIElements.SideBarContainer,
0.25,
{Size=UDim2.new(0,aw.SideBarWidth,1,-aw.Topbar.Height)},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()
d.Visible=false
end
function aw.User.SetAnonymous(f,g)
if g~=false then
g=true
end
aw.User.Anonymous=g
d.UserIcon.ImageLabel.Image=GetUserThumb()
d.UserIcon.Frame.DisplayName.Text=g and"Anonymous"or ak.LocalPlayer.DisplayName
d.UserIcon.Frame.UserName.Text=g and"anonymous"or ak.LocalPlayer.Name
end

if aw.User.Enabled then
aw.User:Enable()
else
aw.User:Disable()
end

if aw.User.Callback then
an.AddSignal(d.MouseButton1Click,function()
aw.User.Callback()
end)
an.AddSignal(d.MouseEnter,function()
ap(d.UserIcon,0.04,{ImageTransparency=0.95}):Play()
ap(d.Outline,0.04,{ImageTransparency=0.85}):Play()
end)
an.AddSignal(d.InputEnded,function()
ap(d.UserIcon,0.04,{ImageTransparency=1}):Play()
ap(d.Outline,0.04,{ImageTransparency=1}):Play()
end)
end
end

local f
local g

local h=false
local i

local l=typeof(aw.Background)=="string"and string.match(aw.Background,"^video:(.+)")or nil

local m=typeof(aw.Background)=="string"
and not l
and string.match(aw.Background,"^https?://.+")
or nil

local p=typeof(aw.Background)=="string"
and not l
and string.match(aw.Background,"^rbxassetid://%d+")
or nil

local function GetImageExtension(r)
if not r or typeof(r)~="string"then
return".png"
end
local u=r:match"^([^?#]+)"or r
local v=u:match"%.(%w+)$"
if v then
v=v:lower()
if v=="jpg"or v=="jpeg"or v=="png"or v=="webp"then
return"."..v
end
end
return".png"
end



if typeof(aw.Background)=="string"and l then
h=true

if string.find(l,"http")then
local r=(aw.Folder or"Temp").."/assets/."..an.SanitizeFilename(l)..".webm"
if not isfile(r)then
local u,v=pcall(function()





local u=game.HttpGet and game:HttpGet(l)
or an.Request{
Url=l,
Method="GET",
Headers={["User-Agent"]="Roblox/Exploit"},
}.Body

writefile(r,u)
end)
if not u then
warn("[ WindUI.Window.Background ] Failed to download video: "..tostring(v))
end
end

local u,v=pcall(function()
return getcustomasset(r)
end)
if not u then
warn("[ WindUI.Window.Background ] Failed to load custom asset: "..tostring(v))
end
warn"[ WindUI.Window.Background ] VideoFrame may not work with custom video"
l=v
end

i=ao("VideoFrame",{
BackgroundTransparency=1,
Size=UDim2.new(1,0,1,0),
Video=l,
Looped=true,
Volume=0,
},{
ao("UICorner",{
CornerRadius=UDim.new(0,aw.UICorner),
}),
})
i:Play()
elseif m then
local r=(aw.Folder or"Temp")
.."/assets/."
..an.SanitizeFilename(m)
..GetImageExtension(m)

if isfile and not isfile(r)then
local u,v=pcall(function()
local u=game.HttpGet and game:HttpGet(m)
or an.Request{
Url=m,
Method="GET",
Headers={["User-Agent"]="Roblox/Exploit"},
}.Body

writefile(r,u)
end)

if not u then
warn("[ Window.Background ] Failed to download image: "..tostring(v))
end
end

local u,v=pcall(function()
return getcustomasset(r)
end)

if not u then
warn("[ Window.Background ] Failed to load custom asset: "..tostring(v))
end

i=ao("ImageLabel",{
BackgroundTransparency=1,
Size=UDim2.new(1,0,1,0),
Image=v,
ImageTransparency=0,
ScaleType="Crop",
},{
ao("UICorner",{
CornerRadius=UDim.new(0,aw.UICorner),
}),
})
elseif p then
i=ao("ImageLabel",{
BackgroundTransparency=1,
Size=UDim2.new(1,0,1,0),
Image=p,
ImageTransparency=0,
ScaleType="Crop",
},{
ao("UICorner",{
CornerRadius=UDim.new(0,aw.UICorner),
}),
})
elseif aw.Background then
i=ao("ImageLabel",{
BackgroundTransparency=1,
Size=UDim2.new(1,0,1,0),
Image=typeof(aw.Background)=="string"and aw.Background or"",
ImageTransparency=1,
ScaleType="Crop",
},{
ao("UICorner",{
CornerRadius=UDim.new(0,aw.UICorner),
}),
})
end

local r=an.NewRoundFrame(99,"Squircle",{
ImageTransparency=0.8,
ImageColor3=Color3.new(1,1,1),
Size=UDim2.new(0,0,0,4),
Position=UDim2.new(0.5,0,1,4),
AnchorPoint=Vector2.new(0.5,0),
},{
ao("TextButton",{
Size=UDim2.new(1,12,1,12),
BackgroundTransparency=1,
Position=UDim2.new(0.5,0,0.5,0),
AnchorPoint=Vector2.new(0.5,0.5),
Active=true,
ZIndex=99,
Name="Frame",
}),
})

function createAuthor(u)
return ao("TextLabel",{
Text=u,
FontFace=Font.new(an.Font,Enum.FontWeight.Medium),
BackgroundTransparency=1,
TextTransparency=0.35,
AutomaticSize="XY",
Parent=aw.UIElements.Main and aw.UIElements.Main.Main.Topbar.Left.Title,
TextXAlignment="Left",
TextSize=13,
LayoutOrder=2,
ThemeTag={
TextColor3="WindowTopbarAuthor",
},
Name="Author",
})
end

local u
local v

if aw.Author then
u=createAuthor(aw.Author)
end

local x=ao("TextLabel",{
Text=aw.Title,
FontFace=Font.new(an.Font,Enum.FontWeight.SemiBold),
BackgroundTransparency=1,
AutomaticSize="XY",
Name="Title",
TextXAlignment="Left",
TextSize=16,
ThemeTag={
TextColor3="WindowTopbarTitle",
},
})

aw.UIElements.Main=ao("Frame",{
Size=UDim2.new(aw.Size.X.Scale,aw.Size.X.Offset,0,0),
Position=aw.Position,
BackgroundTransparency=1,
Parent=av.Parent,
AnchorPoint=Vector2.new(0.5,0.5),
Active=true,

},{
av.WindUI.UIScaleObj,
aw.AcrylicPaint and aw.AcrylicPaint.Frame or nil,
b,
an.NewRoundFrame(aw.UICorner,"Squircle",{
ImageTransparency=1,
Size=UDim2.new(1,0,1,0),
AnchorPoint=Vector2.new(0.5,0.5),
Position=UDim2.new(0.5,0,0.5,0),
Name="Background",
ThemeTag={
ImageColor3="WindowBackground",
},

},{
i,
r,
az,
}),




ay,
aA,
aB,
ao("Frame",{
Size=UDim2.new(1,0,1,0),
BackgroundTransparency=1,
Name="Main",

Visible=false,
ZIndex=97,
},{
ao("UICorner",{
CornerRadius=UDim.new(0,aw.UICorner),
}),
aw.UIElements.SideBarContainer,
aw.UIElements.MainBar,

d,

g,
ao("Frame",{
Size=UDim2.new(1,0,0,aw.Topbar.Height),
BackgroundTransparency=1,
BackgroundColor3=Color3.fromRGB(50,50,50),
Name="Topbar",
},{
f,






ao("Frame",{
AutomaticSize="X",
Size=UDim2.new(0,0,1,0),
BackgroundTransparency=1,
Name="Left",
},{
ao("UIListLayout",{
Padding=UDim.new(0,aw.UIPadding+4),
SortOrder="LayoutOrder",
FillDirection="Horizontal",
VerticalAlignment="Center",
}),
ao("Frame",{
AutomaticSize="XY",
BackgroundTransparency=1,
Name="Title",
Size=UDim2.new(0,0,1,0),
LayoutOrder=2,
},{
ao("UIListLayout",{
Padding=UDim.new(0,0),
SortOrder="LayoutOrder",
FillDirection="Vertical",
VerticalAlignment="Center",
}),
x,
u,
}),
ao("UIPadding",{
PaddingLeft=UDim.new(0,4),
}),
}),
ao("CanvasGroup",{
Size=UDim2.new(0,0,1,0),
BackgroundTransparency=1,
Name="Center",
AnchorPoint=Vector2.new(0,0.5),
Position=UDim2.new(0,0,0.5,0),
AutomaticSize="Y",
Visible=false,
},{



ao("ScrollingFrame",{
Name="Holder",
BackgroundTransparency=1,
AutomaticSize="Y",
ScrollBarThickness=0,
ScrollingDirection="X",
AutomaticCanvasSize="X",
CanvasSize=UDim2.new(0,0,0,0),
Size=UDim2.new(1,0,1,0),


},{

ao("UIListLayout",{
FillDirection="Horizontal",
VerticalAlignment="Center",
HorizontalAlignment="Left",
Padding=UDim.new(0,aw.UIPadding/2),
}),
}),
}),
ao("Frame",{
AutomaticSize="XY",
BackgroundTransparency=1,
Position=UDim2.new(aw.Topbar.ButtonsType=="Default"and 1 or 0,0,0.5,0),
AnchorPoint=Vector2.new(aw.Topbar.ButtonsType=="Default"and 1 or 0,0.5),
Name="Right",
},{
ao("UIListLayout",{
Padding=UDim.new(0,aw.Topbar.ButtonsType=="Default"and 9 or 0),
FillDirection="Horizontal",
SortOrder="LayoutOrder",
}),
}),
ao("UIPadding",{
PaddingTop=UDim.new(0,aw.UIPadding),
PaddingLeft=UDim.new(
0,
aw.Topbar.ButtonsType=="Default"and aw.UIPadding or aw.UIPadding-2
),
PaddingRight=UDim.new(0,8),
PaddingBottom=UDim.new(0,aw.UIPadding),
}),
}),
}),
})

an.AddSignal(aw.UIElements.Main.Main.Topbar.Left:GetPropertyChangedSignal"AbsoluteSize",function()
local z=0
local A=aw.UIElements.Main.Main.Topbar.Right.UIListLayout.AbsoluteContentSize.X
/av.WindUI.UIScale

z=aw.UIElements.Main.Main.Topbar.Left.AbsoluteSize.X/av.WindUI.UIScale
if aw.Topbar.ButtonsType~="Default"then
z=z+A+aw.UIPadding-4
end

aw.UIElements.Main.Main.Topbar.Center.Position=
UDim2.new(0,z+(aw.UIPadding/av.WindUI.UIScale),0.5,0)
aw.UIElements.Main.Main.Topbar.Center.Size=UDim2.new(
1,
-z
-(aw.UIPadding/av.WindUI.UIScale)
-(aw.Topbar.ButtonsType=="Default"and A+aw.UIPadding or 0),
1,
0
)
end)

if aw.Topbar.ButtonsType~="Default"then
an.AddSignal(aw.UIElements.Main.Main.Topbar.Right:GetPropertyChangedSignal"AbsoluteSize",function()
aw.UIElements.Main.Main.Topbar.Left.Position=UDim2.new(
0,
(aw.UIElements.Main.Main.Topbar.Right.AbsoluteSize.X/av.WindUI.UIScale)+aw.UIPadding-4,
0,
0
)
end)
end

function aw.CreateTopbarButton(z,A,B,C,F,G,H,J)
local L=an.Image(
B,
B,
0,
aw.Folder,
"WindowTopbarIcon",
aw.Topbar.ButtonsType=="Default"and true or false,
G,
"WindowTopbarButtonIcon"
)
L.Size=aw.Topbar.ButtonsType=="Default"
and UDim2.new(0,J or aw.TopBarButtonIconSize,0,J or aw.TopBarButtonIconSize)
or UDim2.new(0,0,0,0)
L.AnchorPoint=Vector2.new(0.5,0.5)
L.Position=UDim2.new(0.5,0,0.5,0)
L.ImageLabel.ImageTransparency=aw.Topbar.ButtonsType=="Default"and 0 or 1

if aw.Topbar.ButtonsType~="Default"then
L.ImageLabel.ImageColor3=an.GetTextColorForHSB(H)
end

local M=an.NewRoundFrame(
aw.Topbar.ButtonsType=="Default"and aw.UICorner-(aw.UIPadding/2)or 999,
"Squircle",
{
Size=aw.Topbar.ButtonsType=="Default"
and UDim2.new(0,aw.Topbar.Height-16,0,aw.Topbar.Height-16)
or UDim2.new(0,14,0,14),
LayoutOrder=F or 999,


ZIndex=9999,
AnchorPoint=Vector2.new(0.5,0.5),
Position=UDim2.new(0.5,0,0.5,0),
ImageColor3=aw.Topbar.ButtonsType~="Default"and(H or Color3.fromHex"#ff3030")or nil,
ThemeTag=aw.Topbar.ButtonsType=="Default"and{
ImageColor3="Text",
}or nil,
ImageTransparency=aw.Topbar.ButtonsType=="Default"and 1 or 0,
},
{












L,
ao("UIScale",{
Scale=1,
}),
},
true
)

local N=ao("Frame",{
Size=aw.Topbar.ButtonsType~="Default"and UDim2.new(0,24,0,24)
or UDim2.new(0,aw.Topbar.Height-16,0,aw.Topbar.Height-16),
BackgroundTransparency=1,
Parent=aw.UIElements.Main.Main.Topbar.Right,
LayoutOrder=F or 999,
},{
M,
})



aw.TopBarButtons[100-F]={
Name=A,
Object=N,
}

an.AddSignal(M.MouseButton1Click,function()
if C then
C()
end
end)
an.AddSignal(M.MouseEnter,function()
if aw.Topbar.ButtonsType=="Default"then
ap(M,0.15,{ImageTransparency=0.93}):Play()


else

ap(
L.ImageLabel,
0.1,
{ImageTransparency=0},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()
ap(L,0.1,{
Size=UDim2.new(
0,
J or aw.TopBarButtonIconSize,
0,
J or aw.TopBarButtonIconSize
),
},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
end
end)

an.AddSignal(M.MouseButton1Down,function()
ap(M.UIScale,0.2,{Scale=0.9},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
end)

an.AddSignal(M.MouseLeave,function()
if aw.Topbar.ButtonsType=="Default"then
ap(M,0.1,{ImageTransparency=1}):Play()


else

ap(
L.ImageLabel,
0.1,
{ImageTransparency=1},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()
ap(
L,
0.1,
{Size=UDim2.new(0,0,0,0)},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()
end
end)

an.AddSignal(M.InputEnded,function()
ap(M.UIScale,0.2,{Scale=1},Enum.EasingStyle.Quint,Enum.EasingDirection.InOut):Play()
end)

return M
end

function aw.Topbar.Button(z,A:{
Name:string,
Icon:string,
Callback:any,
LayoutOrder:number,
IconThemed:boolean,
Color:Color3,
IconSize:number,
})
return aw:CreateTopbarButton(
A.Name,
A.Icon,
A.Callback,
A.LayoutOrder or 0,
A.IconThemed,
A.Color,
A.IconSize
)
end



local z=an.Drag(
aw.UIElements.Main,
{aw.UIElements.Main.Main.Topbar,r.Frame},
function(z,A)
if not aw.Closed then
if z and A==r.Frame then
ap(r,0.1,{ImageTransparency=0.35}):Play()
else
ap(r,0.2,{ImageTransparency=0.8}):Play()
end
aw.Position=aw.UIElements.Main.Position
aw.Dragging=z
end
end
)

if not h and aw.Background and typeof(aw.Background)=="table"then
local A=ao"UIGradient"
for B,C in next,aw.Background do
A[B]=C
end

aw.UIElements.BackgroundGradient=an.NewRoundFrame(aw.UICorner,"Squircle",{
Size=UDim2.new(1,0,1,0),
Parent=aw.UIElements.Main.Background,
ImageTransparency=aw.Transparent and av.WindUI.TransparencyValue or 0,
},{
A,
})
end














aw.OpenButtonMain=a.load'A'.New(aw)

task.spawn(function()
if aw.Icon then
local A=ao("Frame",{
Size=UDim2.new(0,22,0,22),
BackgroundTransparency=1,
Parent=aw.UIElements.Main.Main.Topbar.Left,
})

v=an.Image(
aw.Icon,
aw.Title,
aw.IconRadius,
aw.Folder,
"Window",
true,
aw.IconThemed,
"WindowTopbarIcon"
)
v.Parent=A
v.Size=UDim2.new(0,aw.IconSize,0,aw.IconSize)
v.Position=UDim2.new(0.5,0,0.5,0)
v.AnchorPoint=Vector2.new(0.5,0.5)

aw.OpenButtonMain:SetIcon(aw.Icon)











else
aw.OpenButtonMain:SetIcon(aw.Icon)

end
end)

function aw.SetToggleKey(A,B)
aw.ToggleKey=B
end

function aw.SetTitle(A,B)
aw.Title=B
x.Text=B
end

function aw.SetAuthor(A,B)
aw.Author=B
if not u then
u=createAuthor(aw.Author)
end

u.Text=B
end

function aw.SetSize(A,B)
if typeof(B)=="UDim2"then
aw.Size=B

ap(aw.UIElements.Main,0.08,{Size=B},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
end
end

function aw.SetBackgroundImage(A,B)
aw.UIElements.Main.Background.ImageLabel.Image=B
end
function aw.SetBackgroundImageTransparency(A,B)
if i and i:IsA"ImageLabel"then
i.ImageTransparency=math.floor(B*10+0.5)/10
end
aw.BackgroundImageTransparency=math.floor(B*10+0.5)/10
end

function aw.SetBackgroundTransparency(A,B)
local C=math.floor(tonumber(B)*10+0.5)/10
av.WindUI.TransparencyValue=C
aw:ToggleTransparency(C>0)
end

local A
local B
an.Icon"minimize"
an.Icon"maximize"

aw:CreateTopbarButton(
"Fullscreen",
aw.Topbar.ButtonsType=="Mac"and"rbxassetid://127426072704909"or"maximize",
function()
aw:ToggleFullscreen()
end,
(aw.Topbar.ButtonsType=="Default"and 998 or 999),
true,
Color3.fromHex"#60C762",
aw.Topbar.ButtonsType=="Mac"and 9 or nil
)

local function SetSize(C)
ap(aw.UIElements.Main,0.45,{
Size=not aw.IsFullscreen and B or UDim2.new(
0,
(av.WindUI.ScreenGui.AbsoluteSize.X-20)/av.WindUI.UIScale,
0,
(av.WindUI.ScreenGui.AbsoluteSize.Y-20-52)/av.WindUI.UIScale
),
},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()

ap(
aw.UIElements.Main,
0.45,
{Position=not aw.IsFullscreen and A or UDim2.new(0.5,0,0.5,26)},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()
end

function aw.ToggleFullscreen(C)
local F=aw.IsFullscreen

z:Set(F)

if not F then
A=aw.UIElements.Main.Position
B=aw.UIElements.Main.Size

aw.CanResize=false
else
if aw.Resizable then
aw.CanResize=true
end
end

aw.IsFullscreen=not F

SetSize(true)
end

an.AddSignal(av.WindUI.ScreenGui:GetPropertyChangedSignal"AbsoluteSize",function()
if aw.IsFullscreen then
SetSize()
end
end)

aw:CreateTopbarButton("Minimize","minus",function()
if aw.Close then
aw:Close()
end






















end,(aw.Topbar.ButtonsType=="Default"and 997 or 998),nil,Color3.fromHex"#F4C948")

function aw.OnOpen(C,F)
aw.OnOpenCallback=F
end
function aw.OnClose(C,F)
aw.OnCloseCallback=F
end
function aw.OnDestroy(C,F)
aw.OnDestroyCallback=F
end

if av.WindUI.UseAcrylic then
aw.AcrylicPaint.AddParent(aw.UIElements.Main)
end

function aw.SetIconSize(C,F)
local G
if typeof(F)=="number"then
G=UDim2.new(0,F,0,F)
aw.IconSize=F
elseif typeof(F)=="UDim2"then
G=F
aw.IconSize=F.X.Offset
end

if v then
v.Size=G
end
end

function aw.Open(C)
if aw.Destroyed then
return
end
task.spawn(function()
if aw.OnOpenCallback then
task.spawn(function()
an.SafeCallback(aw.OnOpenCallback)
end)
end

task.wait(0.06)
aw.Closed=false

aw.UIElements.Main.Size=UDim2.new(aw.Size.X.Scale,aw.Size.X.Offset,0,100)

ap(aw.UIElements.Main,0.8,{

Size=aw.Size,
},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()

if aw.UIElements.BackgroundGradient then
ap(aw.UIElements.BackgroundGradient,0.2,{
ImageTransparency=0,
},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
end

aw.UIElements.Main.Background.ImageTransparency=1
ap(aw.UIElements.Main.Background,0.4,{

ImageTransparency=aw.Transparent and av.WindUI.TransparencyValue or 0,
},Enum.EasingStyle.Exponential,Enum.EasingDirection.Out):Play()

if i then
if i:IsA"VideoFrame"then
i.Visible=true
else
ap(i,0.2,{
ImageTransparency=aw.BackgroundImageTransparency,
},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
end
end

if aw.OpenButtonMain and aw.IsOpenButtonEnabled then
aw.OpenButtonMain:Visible(false)
end









ap(
b,
0.25,
{ImageTransparency=aw.ShadowTransparency},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()




ap(
r,
0.45,
{Size=UDim2.new(0,aw.DragFrameSize,0,4),ImageTransparency=0.8},
Enum.EasingStyle.Exponential,
Enum.EasingDirection.Out
):Play()
z:Set(true)

if aw.Resizable then
ap(
az.ImageLabel,
0.45,
{ImageTransparency=0.8},
Enum.EasingStyle.Exponential,
Enum.EasingDirection.Out
):Play()
aw.CanResize=true
end

aw.CanDropdown=true
aw.UIElements.Main.Visible=true



aw.UIElements.Main:WaitForChild"Main".Visible=true

av.WindUI:ToggleAcrylic(true)

end)
end
function aw.Close(C)
if aw.Destroyed then
return
end

local F={}

if aw.OnCloseCallback then
task.spawn(function()
an.SafeCallback(aw.OnCloseCallback)
end)
end

av.WindUI:ToggleAcrylic(false)

if aw.UIElements.Main and aw.UIElements.Main:WaitForChild"Main"then
aw.UIElements.Main.Main.Visible=false
end

aw.CanDropdown=false
aw.Closed=true

ap(aw.UIElements.Main,0.9,{

Size=UDim2.new(aw.Size.X.Scale,aw.Size.X.Offset,0,0),
},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
if aw.UIElements.BackgroundGradient then
ap(aw.UIElements.BackgroundGradient,0.2,{
ImageTransparency=1,
},Enum.EasingStyle.Quint,Enum.EasingDirection.InOut):Play()
end

ap(aw.UIElements.Main.Background,0.3,{

ImageTransparency=1,
},Enum.EasingStyle.Exponential,Enum.EasingDirection.InOut):Play()








if i then
if i:IsA"VideoFrame"then
i.Visible=false
else
ap(i,0.3,{
ImageTransparency=1,
},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
end
end
ap(b,0.25,{ImageTransparency=1},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()




ap(
r,
0.3,
{Size=UDim2.new(0,0,0,4),ImageTransparency=1},
Enum.EasingStyle.Exponential,
Enum.EasingDirection.InOut
):Play()
ap(
az.ImageLabel,
0.3,
{ImageTransparency=1},
Enum.EasingStyle.Exponential,
Enum.EasingDirection.Out
):Play()
z:Set(false)
aw.CanResize=false

task.spawn(function()
task.wait(0.4)

if not aw.Closed then
return
end

aw.UIElements.Main.Visible=false

if aw.OpenButtonMain and not aw.Destroyed and not aw.IsPC and aw.IsOpenButtonEnabled then
aw.OpenButtonMain:Visible(true)
end
end)

function F.Destroy(G)
task.spawn(function()
if aw.OnDestroyCallback then
task.spawn(function()
an.SafeCallback(aw.OnDestroyCallback)
end)
end

if aw.AcrylicPaint and aw.AcrylicPaint.Model then
aw.AcrylicPaint.Model:Destroy()
end

aw.Destroyed=true

task.wait(0.4)

av.WindUI.ScreenGui:Destroy()
av.WindUI.NotificationGui:Destroy()
av.WindUI.DropdownGui:Destroy()
av.WindUI.TooltipGui:Destroy()

an.DisconnectAll()

return
end)
end

return F
end
function aw.Destroy(C)
return aw:Close():Destroy()
end
function aw.Toggle(C)
if aw.Closed then
aw:Open()
else
aw:Close()
end
end

function aw.ToggleTransparency(C,F)

aw.Transparent=F
av.WindUI.Transparent=F

aw.UIElements.Main.Background.ImageTransparency=F and av.WindUI.TransparencyValue or 0


end

function aw.LockAll(C)
for F,G in next,aw.AllElements do
if G.Lock then
G:Lock()
end
end
end
function aw.UnlockAll(C)
for F,G in next,aw.AllElements do
if G.Unlock then
G:Unlock()
end
end
end
function aw.GetLocked(C)
local F={}

for G,H in next,aw.AllElements do
if H.Locked then
table.insert(F,H)
end
end

return F
end
function aw.GetUnlocked(C)
local F={}

for G,H in next,aw.AllElements do
if H.Locked==false then
table.insert(F,H)
end
end

return F
end

function aw.GetUIScale(C,F)
return av.WindUI.UIScale
end

function aw.SetUIScale(C,F)
av.WindUI.UIScale=F
ap(av.WindUI.UIScaleObj,0.2,{Scale=F},Enum.EasingStyle.Quint,Enum.EasingDirection.Out):Play()
return aw
end

function aw.SetToTheCenter(C)
ap(
aw.UIElements.Main,
0.45,
{Position=UDim2.new(0.5,0,0.5,0)},
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
):Play()
return aw
end

function aw.SetCurrentConfig(C,F)
aw.CurrentConfig=F
end

do
local C=40
local F=al.ViewportSize
local G=Vector2.new(aw.Size.X.Offset,aw.Size.Y.Offset)

if not aw.IsFullscreen and aw.AutoScale then
local H=F.X-(C*2)
local J=F.Y-(C*2)

local L=H/G.X
local M=J/G.Y

local N=math.min(L,M)

local O=0.3
local P=1.0

local Q=math.clamp(N,O,P)

local R=aw:GetUIScale()or 1
local S=0.05

if math.abs(Q-R)>S then
aw:SetUIScale(Q)
end
end
end

if aw.OpenButtonMain and aw.OpenButtonMain.Button then
an.AddSignal(aw.OpenButtonMain.Button.TextButton.MouseButton1Click,function()


aw:Open()
end)
end

an.AddSignal(af.InputBegan,function(C,F)
if F then
return
end

if aw.ToggleKey then
if C.KeyCode==aw.ToggleKey then
aw:Toggle()
end
end
end)

task.spawn(function()

aw:Open()
end)

function aw.EditOpenButton(C,F)
return aw.OpenButtonMain:Edit(F)
end

if aw.OpenButton and typeof(aw.OpenButton)=="table"then
aw:EditOpenButton(aw.OpenButton)
end

local C=a.load'aa'
local F=a.load'ab'
local G=C.Init(aw,av.WindUI,av.WindUI.TooltipGui)
G:OnChange(function(H)
aw.CurrentTab=H
end)

aw.TabModule=G

function aw.Tab(H,J)
J.Parent=aw.UIElements.SideBar.Frame
return G.New(J,av.WindUI.UIScale)
end

function aw.SelectTab(H,J)
G:SelectTab(J)
end

function aw.Section(H,J)
return F.New(
J,
aw.UIElements.SideBar.Frame,
aw.Folder,
av.WindUI.UIScale,
aw
)
end

function aw.IsResizable(H,J)
aw.Resizable=J
aw.CanResize=J
end

function aw.SetPanelBackground(H,J)
if typeof(J)=="boolean"then
aw.HidePanelBackground=J

aw.UIElements.MainBar.Background.Visible=J

if G then
for L,M in next,G.Containers do
M.ScrollingFrame.UIPadding.PaddingTop=UDim.new(0,aw.HidePanelBackground and 20 or 10)
M.ScrollingFrame.UIPadding.PaddingLeft=
UDim.new(0,aw.HidePanelBackground and 20 or 10)
M.ScrollingFrame.UIPadding.PaddingRight=
UDim.new(0,aw.HidePanelBackground and 20 or 10)
M.ScrollingFrame.UIPadding.PaddingBottom=
UDim.new(0,aw.HidePanelBackground and 20 or 10)
end
end
end
end

function aw.Divider(H)
local J=ao("Frame",{
Size=UDim2.new(1,0,0,1),
Position=UDim2.new(0.5,0,0,0),
AnchorPoint=Vector2.new(0.5,0),
BackgroundTransparency=0.9,
ThemeTag={
BackgroundColor3="Text",
},
})
local L=ao("Frame",{
Parent=aw.UIElements.SideBar.Frame,

Size=UDim2.new(1,-7,0,5),
BackgroundTransparency=1,
},{
J,
})

return L
end

local H=a.load'o'
function aw.Dialog(J,L)
local M={
Title=L.Title or"Dialog",
Width=L.Width or 320,
Content=L.Content,
Buttons=L.Buttons or{},

TextPadding=14,
}
local N=H.Create(false,"Dialog",aw,av.WindUI,aw.UIElements.Main.Main)

N.UIElements.Main.Size=UDim2.new(0,M.Width,0,0)

local O=ao("Frame",{
Size=UDim2.new(1,0,1,0),
AutomaticSize="Y",
BackgroundTransparency=1,
Parent=N.UIElements.Main,
},{
ao("UIListLayout",{
FillDirection="Vertical",

Padding=UDim.new(0,N.UIPadding),
}),
})

local P=ao("Frame",{
Size=UDim2.new(1,0,0,0),
AutomaticSize="Y",
BackgroundTransparency=1,
Parent=O,
},{
ao("UIListLayout",{
FillDirection="Horizontal",
Padding=UDim.new(0,N.UIPadding),
VerticalAlignment="Center",
}),
ao("UIPadding",{
PaddingTop=UDim.new(0,M.TextPadding/2),
PaddingLeft=UDim.new(0,M.TextPadding/2),
PaddingRight=UDim.new(0,M.TextPadding/2),
}),
})

local Q
if L.Icon then
Q=an.Image(
L.Icon,
M.Title..":"..L.Icon,
0,
aw,
"Dialog",
true,
L.IconThemed
)
Q.Size=UDim2.new(0,22,0,22)
Q.Parent=P
end

N.UIElements.UIListLayout=ao("UIListLayout",{
Padding=UDim.new(0,12),
FillDirection="Vertical",
HorizontalAlignment="Left",
VerticalFlex="SpaceBetween",
Parent=N.UIElements.Main,
})

ao("UISizeConstraint",{
MinSize=Vector2.new(180,20),
MaxSize=Vector2.new(400,math.huge),
Parent=N.UIElements.Main,
})

N.UIElements.Title=ao("TextLabel",{
Text=M.Title,
TextSize=20,
FontFace=Font.new(an.Font,Enum.FontWeight.SemiBold),
TextXAlignment="Left",
TextWrapped=true,
RichText=true,
Size=UDim2.new(1,Q and-26-N.UIPadding or 0,0,0),
AutomaticSize="Y",
ThemeTag={
TextColor3="Text",
},
BackgroundTransparency=1,
Parent=P,
})
if M.Content then
ao("TextLabel",{
Text=M.Content,
TextSize=18,
TextTransparency=0.4,
TextWrapped=true,
RichText=true,
FontFace=Font.new(an.Font,Enum.FontWeight.Medium),
TextXAlignment="Left",
Size=UDim2.new(1,0,0,0),
AutomaticSize="Y",
LayoutOrder=2,
ThemeTag={
TextColor3="Text",
},
BackgroundTransparency=1,
Parent=O,
},{
ao("UIPadding",{
PaddingLeft=UDim.new(0,M.TextPadding/2),
PaddingRight=UDim.new(0,M.TextPadding/2),
PaddingBottom=UDim.new(0,M.TextPadding/2),
}),
})
end

local R=ao("UIListLayout",{
Padding=UDim.new(0,6),
FillDirection="Horizontal",
HorizontalAlignment="Center",
HorizontalFlex="Fill",
})

local S=ao("Frame",{
Size=UDim2.new(1,0,0,36),
AutomaticSize="None",
BackgroundTransparency=1,
Parent=N.UIElements.Main,
LayoutOrder=4,
},{
R,






})

local T={}

for U,V in next,M.Buttons do
local W=
ar(V.Title,V.Icon,V.Callback,V.Variant,S,N,true)
table.insert(T,W)
W.Size=UDim2.new(1,0,1,0)
end





















































N:Open()

return N
end

local J=false

aw:CreateTopbarButton("Close","x",function()
if not J then
if not aw.IgnoreAlerts then
J=true

aw:Dialog{

Title="Close Window",
Content="Do you want to close this window? You will not be able to open it again.",
Buttons={
{
Title="Cancel",

Callback=function()
J=false
end,
Variant="Secondary",
},
{
Title="Close Window",

Callback=function()
J=false
aw:Destroy()
end,
Variant="Primary",
},
},
}
else
aw:Destroy()
end
end
end,(aw.Topbar.ButtonsType=="Default"and 999 or 997),nil,Color3.fromHex"#F4695F")

function aw.Tag(L,M)
if aw.UIElements.Main.Main.Topbar.Center.Visible==false then
aw.UIElements.Main.Main.Topbar.Center.Visible=true
end
M.Window=aw
return at:New(M,aw.UIElements.Main.Main.Topbar.Center.Holder)
end

local L=av.WindUI.GenerateGUID()

local function startResizing(M)
if aw.CanResize then
isResizing=true
aA.Active=true
initialSize=aw.UIElements.Main.Size
initialInputPosition=M.Position


ap(az.ImageLabel,0.1,{ImageTransparency=0.35}):Play()

an.AddSignal(M.Changed,function()
if M.UserInputState==Enum.UserInputState.End then
if av.WindUI.CurrentInput and av.WindUI.CurrentInput~=L then
return
end

av.WindUI.CurrentInput=nil

isResizing=false
aA.Active=false


ap(az.ImageLabel,0.17,{ImageTransparency=0.8}):Play()
end
end)
end
end

an.AddSignal(az.InputBegan,function(M)
if
M.UserInputType==Enum.UserInputType.MouseButton1
or M.UserInputType==Enum.UserInputType.Touch
then
if av.WindUI.CurrentInput and av.WindUI.CurrentInput~=L then
return
end
av.WindUI.CurrentInput=L

if aw.CanResize then
startResizing(M)
end
end
end)

an.AddSignal(af.InputChanged,function(M)
if
M.UserInputType==Enum.UserInputType.MouseMovement
or M.UserInputType==Enum.UserInputType.Touch
then
if isResizing and aw.CanResize then
local N=M.Position-initialInputPosition
local O=UDim2.new(0,initialSize.X.Offset+N.X*2,0,initialSize.Y.Offset+N.Y*2)

O=UDim2.new(
O.X.Scale,
math.clamp(O.X.Offset,aw.MinSize.X,aw.MaxSize.X),
O.Y.Scale,
math.clamp(O.Y.Offset,aw.MinSize.Y,aw.MaxSize.Y)
)

ap(aw.UIElements.Main,0.08,{
Size=O,
},Enum.EasingStyle.Quad,Enum.EasingDirection.Out):Play()

aw.Size=O
end
end
end)

an.AddSignal(az.MouseEnter,function()
if av.WindUI.CurrentInput and av.WindUI.CurrentInput~=L then
return
end
if not isResizing then
ap(az.ImageLabel,0.1,{ImageTransparency=0.35}):Play()
end
end)
an.AddSignal(az.MouseLeave,function()
if av.WindUI.CurrentInput and av.WindUI.CurrentInput~=L then
return
end
if not isResizing then
ap(az.ImageLabel,0.17,{ImageTransparency=0.8}):Play()
end
end)



local M=0
local N=0.4
local O
local P=0

function onDoubleClick()
aw:SetToTheCenter()
end

an.AddSignal(r.Frame.MouseButton1Up,function()
local Q=tick()
local R=aw.Position

P=P+1

if P==1 then
M=Q
O=R

task.spawn(function()
task.wait(N)
if P==1 then
P=0
O=nil
end
end)
elseif P==2 then
if Q-M<=N and R==O then
onDoubleClick()
end

P=0
O=nil
M=0
else
P=1
M=Q
O=R
end
end)



if not aw.HideSearchBar then
local Q=a.load'ad'
local R=false





















local S=aq("Search","search",aw.UIElements.SideBarContainer,true)
S.Size=UDim2.new(1,-aw.UIPadding/2,0,39)
S.Position=UDim2.new(0,aw.UIPadding/2,0,0)

an.AddSignal(S.MouseButton1Click,function()
if R then
return
end

Q.new(aw.TabModule,aw.UIElements.Main,function()

R=false
if aw.Resizable then
aw.CanResize=true
end

ap(aB,0.1,{ImageTransparency=1}):Play()
aB.Active=false
end)
ap(aB,0.1,{ImageTransparency=0.65}):Play()
aB.Active=true

R=true
aw.CanResize=false
end)
end



function aw.DisableTopbarButtons(Q,R)
for S,T in next,R do
for U,V in next,aw.TopBarButtons do
if V.Name==T then
V.Object.Visible=false
end
end
end
end



























return aw
end end end

local aa={
Window=nil,
Theme=nil,
Creator=a.load'd',
LocalizationModule=a.load'e',
NotificationModule=a.load'f',
Themes=nil,
Transparent=false,

TransparencyValue=0.15,

UIScale=1,

ConfigManager=nil,
Version="0.0.0",

Services=a.load'k',

OnThemeChangeFunction=nil,

cloneref=nil,
UIScaleObj=nil,

CreateWindow=nil,

CurrentInput=nil,
}

local af=(cloneref or clonereference or function(af)
return af
end)

aa.cloneref=af

local ai=af(game:GetService"HttpService")
local ak=af(game:GetService"Players")
local al=af(game:GetService"CoreGui")
local am=af(game:GetService"RunService")
local an=af(game:GetService"UserInputService")

function aa.GenerateGUID()
return ai:GenerateGUID(false)
end

local ao=aa.GenerateGUID()

an.InputBegan:Connect(function(ap,aq)




task.defer(function()
if
ap.UserInputType==Enum.UserInputType.MouseButton1
or ap.UserInputType==Enum.UserInputType.Touch
then
if aa.CurrentInput and aa.CurrentInput~=ao then
return
end

aa.CurrentInput=ao


end
end)
end)
an.InputEnded:Connect(function(ap,aq)
if ap.UserInputType==Enum.UserInputType.MouseButton1 or ap.UserInputType==Enum.UserInputType.Touch then
if aa.CurrentInput and aa.CurrentInput~=ao then
return
end

aa.CurrentInput=nil
end
end)

local ap=ak.LocalPlayer or nil

local aq=ai:JSONDecode(a.load'l')
if aq then
aa.Version=aq.version
end

local ar=a.load'p'

local as=aa.Creator

local at=as.New




local au=a.load't'

local av=protectgui or(syn and syn.protect_gui)or function()end

local aw=gethui and gethui()or(al or ap:WaitForChild"PlayerGui")

local ax=at("UIScale",{
Scale=aa.UIScale,
})

aa.UIScaleObj=ax

aa.ScreenGui=at("ScreenGui",{
Name="WindUI",
Parent=aw,
IgnoreGuiInset=true,
ScreenInsets="None",
DisplayOrder=-99999,
},{

at("Folder",{
Name="Window",
}),






at("Folder",{
Name="KeySystem",
}),
at("Folder",{
Name="Popups",
}),
at("Folder",{
Name="ToolTips",
}),
})

aa.NotificationGui=at("ScreenGui",{
Name="WindUI/Notifications",
Parent=aw,
IgnoreGuiInset=true,
})
aa.DropdownGui=at("ScreenGui",{
Name="WindUI/Dropdowns",
Parent=aw,
IgnoreGuiInset=true,
})
aa.TooltipGui=at("ScreenGui",{
Name="WindUI/Tooltips",
Parent=aw,
IgnoreGuiInset=true,
})
av(aa.ScreenGui)
av(aa.NotificationGui)
av(aa.DropdownGui)
av(aa.TooltipGui)

as.Init(aa)

function aa.SetParent(ay,az)
if aa.ScreenGui then
aa.ScreenGui.Parent=az
end
if aa.NotificationGui then
aa.NotificationGui.Parent=az
end
if aa.DropdownGui then
aa.DropdownGui.Parent=az
end
if aa.TooltipGui then
aa.TooltipGui.Parent=az
end
end
math.clamp(aa.TransparencyValue,0,1)

local ay=aa.NotificationModule.Init(aa.NotificationGui)

function aa.Notify(az,aA)
aA.Holder=ay.Frame
aA.Window=aa.Window

return aa.NotificationModule.New(aA)
end

function aa.SetNotificationLower(az,aA)
ay.SetLower(aA)
end

function aa.SetFont(az,aA)
as.UpdateFont(aA)
end

function aa.OnThemeChange(az,aA)
aa.OnThemeChangeFunction=aA
end

function aa.AddTheme(az,aA)
aa.Themes[aA.Name]=aA
return aA
end

function aa.SetTheme(az,aA)
if aa.Themes[aA]then
aa.Theme=aa.Themes[aA]
as.SetTheme(aa.Themes[aA])

if aa.OnThemeChangeFunction then
aa.OnThemeChangeFunction(aA)
end

return aa.Themes[aA]
end
return nil
end

function aa.GetThemes(az)
return aa.Themes
end
function aa.GetCurrentTheme(az)
return aa.Theme.Name
end
function aa.GetTransparency(az)
return aa.Transparent or false
end
function aa.GetWindowSize(az)
return aa.Window.UIElements.Main.Size
end
function aa.Localization(az,aA)
return aa.LocalizationModule:New(aA,as)
end

function aa.SetLanguage(az,aA)
if as.Localization then
return as.SetLanguage(aA)
end
return false
end

function aa.ToggleAcrylic(az,aA)
if aa.Window and aa.Window.AcrylicPaint and aa.Window.AcrylicPaint.Model then
aa.Window.Acrylic=aA
aa.Window.AcrylicPaint.Model.Transparency=aA and 0.98 or 1
if aA then
au.Enable()
else
au.Disable()
end
end
end

function aa.Gradient(az,aA,aB)
local b={}
local d={}

for f,g in next,aA do
local h=tonumber(f)
if h then
h=math.clamp(h/100,0,1)

local i=g.Color
if typeof(i)=="string"and string.sub(i,1,1)=="#"then
i=Color3.fromHex(i)
end

local l=g.Transparency or 0

table.insert(b,ColorSequenceKeypoint.new(h,i))
table.insert(d,NumberSequenceKeypoint.new(h,l))
end
end

table.sort(b,function(f,g)
return f.Time<g.Time
end)
table.sort(d,function(f,g)
return f.Time<g.Time
end)

if#b<2 then
table.insert(b,ColorSequenceKeypoint.new(1,b[1].Value))
table.insert(d,NumberSequenceKeypoint.new(1,d[1].Value))
end

local f={
Color=ColorSequence.new(b),
Transparency=NumberSequence.new(d),
}

if aB then
for g,h in pairs(aB)do
f[g]=h
end
end

return f
end

function aa.Popup(az,aA)
aA.WindUI=aa
return a.load'u'.new(aA,aa.ScreenGui.Popups)
end

aa.Themes=a.load'v'(aa,as)

as.Themes=aa.Themes

aa:SetTheme"Dark"
aa:SetLanguage(as.Language)

function aa.CreateWindow(az,aA)
local aB=a.load'ae'

if not am:IsStudio()and writefile then
if not isfolder"WindUI"then
makefolder"WindUI"
end
if aA.Folder then
makefolder(aA.Folder)
else
makefolder(aA.Title)
end
end

aA.WindUI=aa
aA.Window=aa.Window
aA.Parent=aa.ScreenGui.Window

if aa.Window then
warn"You cannot create more than one window"
return
end

local b=true

local d=aa.Themes[aA.Theme or"Dark"]


as.SetTheme(d)

local f=gethwid or function()
return ak.LocalPlayer.UserId
end

local g=f()

if aA.KeySystem then
b=false

local function loadKeysystem()
ar.new(aA,g,function(h)
b=h
end)
end

local h=(aA.Folder or"Temp").."/"..g..".key"

if aA.KeySystem.KeyValidator then
if aA.KeySystem.SaveKey and isfile(h)then
local i=readfile(h)
local l=aA.KeySystem.KeyValidator(i)

if l then
b=true
else
loadKeysystem()
end
else
loadKeysystem()
end
elseif not aA.KeySystem.API then
if aA.KeySystem.SaveKey and isfile(h)then
local i=readfile(h)
local l=(type(aA.KeySystem.Key)=="table")and table.find(aA.KeySystem.Key,i)
or tostring(aA.KeySystem.Key)==tostring(i)

if l then
b=true
else
loadKeysystem()
end
else
loadKeysystem()
end
else
if isfile(h)then
local i=readfile(h)
local l=false

for m,p in next,aA.KeySystem.API do
local r=aa.Services[p.Type]
if r then
local u={}
for v,x in next,r.Args do
table.insert(u,p[x])
end

local v=r.New(table.unpack(u))
local x=v.Verify(i)
if x then
l=true
break
end
end
end

b=l
if not l then
loadKeysystem()
end
else
loadKeysystem()
end
end

repeat
task.wait()
until b
end

local h=aB(aA)

aa.Transparent=aA.Transparent
aa.Window=h

if aA.Acrylic then
au.init()
end













return h
end

return aa]=],
	["modules/core/config.lua"] = [=[
--[[ config.lua — CFG default + persist/load state JSON (garden). ]]
return function(ctx)
	local HttpService = ctx.Services.HttpService
	local Players = ctx.Services.Players or game:GetService("Players")

	-- 1. Pastikan LocalPlayer dan UserId sudah siap (hindari nil)
	local localPlayer = Players.LocalPlayer
	while not localPlayer do
		Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
		localPlayer = Players.LocalPlayer
	end
	local userId = localPlayer.UserId

	local CFG = {
		-- Automation Trade (Ticket)
		targetPlayer   = "",      -- nama player tujuan
		petTypes       = {},      -- set: {["Fire Wisp"]=true}; kosong = semua non-favorite
		weightFilter   = 0,       -- 0=off | +N = minimal Nkg | -N = maksimal Nkg
		ageFilter      = 0,       -- 0=off | +N = minimal age N | -N = maksimal age N
		petsPerTrade   = 12,
		totalTrades    = 14,
		autoUnfavorite = false,
		tradeEnabled   = false,   -- Enable Automation Trade (Ticket)
		tradeTicketEnabled = false,

		-- Automation Trade (Gift)
		giftTargetPlayer     = "",
		giftPetTypes         = {},
		giftWeightFilter     = 0,
		giftAgeFilter        = 0,
		giftPetsPerBatch     = 12,
		giftTotalGifts       = 100,
		giftAutoUnfavorite   = false,
		tradeGiftEnabled     = false,

		-- ===== Auto Hatch + Auto Sell =====
		hatchEnabled    = false,
		autoSellEnabled = false,
		-- teams (set uuid pet)
		hatchCoreTeam   = {},  -- team default/idle
		hatchHatchTeam  = {},  -- team saat hatch (recovery + speed)
		hatchBrontoTeam = {},  -- team bronto (hatch speed)
		hatchSellTeam   = {},  -- team saat jual (boost harga)
		-- egg config
		hatchEggName    = "Rare Egg", -- egg yg di-place & di-hatch
		hatchMaxPlaced  = 8,          -- target egg ke-place di garden
		hatchPlacePattern = "Grid",   -- pola taro egg: "Grid" (rapih) / "Random" (sebar acak)
		hatchTeamDelay  = 5.5,        -- detik tunggu abis swap team sebelum hatch
		hatchWebhookUrl   = "",       -- webhook Discord buat Hatch Alert (bronto)
		hatchAlertEnabled = false,    -- kirim alert pas pet masuk filter bronto
		hatchRejoinMinusEnabled   = false, -- Auto rejoin kalau egg minus
		hatchRejoinMinusThreshold = 20,    -- Threshold jumlah minus untuk trigger rejoin (misal: 20 -> <= -20)
		hatchRejoinPlusEnabled    = false, -- Auto rejoin kalau egg bertambah (plus)
		hatchRejoinPlusThreshold  = 20,    -- Threshold jumlah plus untuk trigger rejoin (misal: 20 -> >= +20)
		-- bronto config: egg yg pending pet-nya cocok -> hatch pakai Bronto team (+30% berat)
		brontoSpecialPets    = {},   -- set "Pet - Egg" (special: wajib bronto)
		brontoSpecialWeight  = 0,    -- special cuma kalau weight > ini (0 = ga difilter)
		brontoUniversalTypes = {},   -- set tipe pet buat aturan universal (kosong = semua)
		brontoUniversalWeight = 0,   -- pakai bronto kalau weight > ini (0 = off)
		brontoSkipSpecial    = false,-- jangan hatch special pet sama sekali
		brontoTeamDelay      = 5.5,  -- detik tunggu abis swap team sebelum hatch bronto
		-- sell config (filter = DIJUAL; sisanya difavoritin biar aman)
		sellPetTypes       = {},   -- set tipe pet yg dijual
		sellWeightThreshold = 5,   -- jual kalau BaseWeight < ini
		sellAgeThreshold    = 3,   -- jual kalau Age/Level < ini
		sellSpecialTypes    = {},  -- pet spesial (jual by weight)
		sellSpecialWeight   = 10,  -- 0=off
		sellMode   = "Cycle",      -- Cycle | Backpack
		sellStyle  = "All at Once",
		sellEveryNCycles = 1,
		sellWhenReach    = 100,    -- jual kalau backpack pet >= ini
		sellTeamDelay    = 5.5,    -- detik tunggu abis swap team sebelum jual
		autoBoostBeforeSell = false,
		hatchCoreEquipDelay   = 0,
		hatchCoreUnequipDelay = 1,
		hatchBrontoEquipDelay = 0,
		hatchBrontoUnequipDelay = 1,
		hatchTeamEquipDelay   = 0,
		hatchTeamUnequipDelay = 1,
		hatchSellEquipDelay   = 0,
		hatchSellUnequipDelay = 1,
		hatchSellList         = {}, -- { [petName] = { kg = 3, action = "SELL"|"KEEP" } }
		autoUnfavoritePets    = false,
		unfavoritePetTypes    = {},
		tradeMethod           = "ticket", -- "ticket" | "gift"

		-- Automation Accept
		acceptGifts   = false,
		acceptTrades  = false,

		-- Automation Favourite Pets (placeholder)
		autoFavorite      = false,
		favoritePetTypes  = {},

		-- PNP (Pick & Place) pet
		pnpPetTypes = {},     -- (lama) filter per-tipe; kosong = semua equipped
		-- PnP V1 (polling)
		pnpUuids    = {},     -- filter per-UUID pet equipped; kosong = semua equipped
		pickupDelay = 0.5,    -- jeda setelah skill mulai sebelum pet ditarik
		equipDelay  = 1e-20,  -- jeda tambahan unequip -> equip setelah server konfirmasi (1E-20 = tanpa jeda)
		pnpScanInterval = 0.5,  -- (nggak dipakai V1 lagi; timing dikunci di modul)
		pnpEnabled  = false,
		espEnabled  = false, -- ESP Label pet (label melayang di dunia)
		espMode     = "target", -- tampilan ESP pet: "target" (billboard di objek) / "screen" (panel di layar)
		espEggEnabled = false, -- ESP Egg (style NEBULA) — terpisah dari ESP pet
		espEggMode    = "target", -- tampilan ESP egg: "target" / "screen"
		espInvEnabled = false, -- ESP base weight di tiap slot pet inventory
		espInvMode  = "age",   -- tampilan ESP inv: "age" (base+age) / "max" (base+max@500)
		noclipEnabled    = false, -- Player: tembus tembok
		walkSpeedEnabled = false, -- Player: pakai custom walk speed
		walkSpeed        = 16,    -- Player: walk speed custom (default 16)
		infJumpEnabled   = false, -- Player: lompat tak terbatas di udara
		hideMyPlants     = false, -- Perf: sembunyiin plant kebun sendiri
		hideOtherPlants  = false, -- Perf: sembunyiin plant kebun lain
		autoRemoveWebFx  = false, -- Perf: auto hapus efek spider web
		perfMode         = "off", -- Perf: off / low / extreme
		disable3d        = false, -- Perf: matiin 3D rendering
		premiumItem      = "",     -- Premium Shop: key item terpilih (DevProductIds)
		premiumPay       = "robux",-- Premium Shop: robux / token

		-- Automation Leveling
		levelingTeamUuids   = {},
		levelingPetTypes    = {},
		levelingTargetLevel = 500,
		levelingMaxPets     = 2,
		levelingEnabled     = false,

		-- Automation Leveling V2 (2 phase)
		levelingV2PetTypes = {},
		levelingV2P1Team   = {},
		levelingV2P1Target = 40,
		levelingV2P1Max    = 3,
		levelingV2P2Team   = {},
		levelingV2P2Target = 500,
		levelingV2P2Max    = 1,
		levelingV2Enabled  = false,

		-- Growth (pipeline: Elephant -> Mutation -> Leveling, batch per-step, config TERPISAH)
		growthEnabled      = false,
		growthPetTypes     = {},                                                    -- target default (dipakai step yg per-step-nya kosong)
		growthFlow         = { "elephant", "mutation", "leveling" }, -- urutan Step 1/2/3
		-- target pet PER-METHOD (kalau kosong -> fallback ke growthPetTypes)
		growthPetTypesElephant = {},
		growthPetTypesMutation = {},
		growthPetTypesLeveling = {},
		-- step Elephant
		growthElephantTeam   = {},
		growthElephantWeight = 5.5,
		growthElephantMax    = 2,
		-- step Mutation (aura)
		growthMutationTeam    = {},
		growthMutationTargets = {},   -- target mutasi (mis. Ember/Nightmare/Rainbow)
		growthMutationMax     = 2,
		-- step Leveling (2 phase)
		growthLevP1Team   = {},
		growthLevP1Target = 40,
		growthLevP1Max    = 3,
		growthLevP2Team   = {},
		growthLevP2Target = 500,
		growthLevP2Max    = 1,

		-- Automation Mutation
		mutationExpTeam       = {},
		mutationBoostTeam     = {},
		mutationPhoenixTeam   = {},
		mutationTargetTypes   = {},
		mutationTargetMutations = {},
		mutationTargetAge     = 50,
		mutationDelayAutoClaim = 0.5,
		mutationEnabled       = false,

		-- Automation Shop (buy seed/egg/gear)
		buySeedNames   = {},
		buySeedEnabled = false,
		buyEggNames    = {},
		buyEggEnabled  = false,
		buyGearNames   = {},
		buyGearEnabled = false,

		-- Automation Merchant (Traveling Merchant auto-buy) — toggle bisa nyala barengan (union)
		merchantBuyEnabled = false,    -- Auto Buy Merchant: beli item terpilih (per-merchant)
		merchantBuyAll     = false,    -- Auto Buy All: beli semua item ada stock
		merchantBuyBest    = false,    -- Auto Buy Best: beli 1 item termahal ada stock
		merchantItems      = {},       -- selection PER-MERCHANT/EVENT: { [id] = {item=true} }
		merchantUiShop     = "",       -- Open UI: event shop yang mau dibuka UI-nya
		merchantAutoOpenUI = false,    -- Open UI: jaga UI shop terpilih tetap kebuka

		-- Automation Water (siram plant terpilih pakai Watering Can / Water_RE)
		waterFruitNames = {},
		waterEnabled    = false,
		waterDelay      = 1,

		-- Automation Shovel (hapus plant / fruit via Remove_Item)
		shovelTreeNames    = {},
		shovelTreeEnabled  = false,
		shovelTreeDelay    = 0,
		shovelFruitNames    = {},
		shovelFruitMuts     = {},
		shovelFruitVariants = {},
		shovelFruitMode     = ">= (berat minimal)",
		shovelFruitWeight   = 0,
		shovelFruitEnabled  = false,
		shovelFruitDelay    = 0,

		-- Automation Collection (harvest fruit via Crops.Collect)
		collectDelay          = 0,
		collectStopIfFull     = false,
		collectAutoSellIfFull = false,
		collectWlFruitNames   = {},
		collectWlFruitEnabled = false,
		collectWlMutNames     = {},
		collectWlMutEnabled   = false,
		collectCombFruitNames = {},
		collectCombMutNames   = {},
		collectCombVariants   = {},
		collectCombMode       = ">= (berat minimal)",
		collectCombWeight     = 0,
		collectCombEnabled    = false,
		-- Blacklist Mutation: collect SEMUA buah bermutasi kecuali mutasi yang di-blacklist
		-- (buah tanpa mutasi nggak di-collect)
		collectBlMutNames     = {},
		collectBlMutEnabled   = false,

		-- Automation Favorite (favorite/unfavorite fruit via Favorite Tool)
		favFruitNames = {},
		favMutNames   = {},
		favMode       = ">= (berat minimal)",
		favWeight     = 0,
		favDelay      = 1,
		favEnabled    = false,
		unfavEnabled  = false,

		-- Automation Reclaimer (Farm): reclaim plant terpilih pakai tool Reclaimer
		reclaimPlantNames = {},
		reclaimEnabled    = false,
		reclaimSpeed      = 0.15,

		-- Automation Plants (Farm): tanam seed dari inventory
		plantSeedNames   = {},
		plantPosition    = "Random",
		plantDelay       = 0,
		goodClear        = true,
		plantSeedEnabled = false,

		-- Automation Sprinkler (Farm): pasang + shovel sprinkler
		sprinklerNames        = {},
		sprinklerPlantNames   = {},
		sprinklerPosition     = "Random",
		sprinklerDelay        = 0,
		sprinklerEnabled      = false,
		shovelSprinklerNames  = {},
		shovelSprinklerDelay  = 0,
		shovelSprinklerEnabled = false,

		-- Auto GM Sprinkler (tab Hatch): jaga 1 Grandmaster Sprinkler terpasang
		gmSprinklerEnabled     = false,

		-- Auto-Reconnect (Misc): auto rejoin kalau ke-kick / disconnect (seperti di Trade)
		autoReconnect     = true,

		-- Automation Reconnect (Misc): auto rejoin tiap interval
		reconnectEnabled  = false,
		reconnectInterval = 5,   -- menit

		-- Automation Cleanse Mutation (mutasi via aura + cleanse)
		cleanseTeamUuids     = {},   -- Pet Team for Mutation (aura pemberi mutasi)
		cleansePetTypes      = {},   -- Pet Types for Mutation (target)
		cleanseKeepMutations = {},   -- Mutations to Keep (won't cleanse)
		cleanseMaxPets       = 2,    -- Max Pets in Garden (target)
		cleanseEnabled       = false,

		-- Automation Boost Pet
		boostPetUuids  = {},
		boostItemNames = {},
		boostEnabled   = false,

		-- Automation Elephant (V1)
		elephantTeamUuids   = {},
		elephantPetTypes    = {},
		elephantTargetWeight = 5.5,
		elephantMaxPets     = 2,
		elephantEnabled     = false,
		-- Elephant V2: swap gajah keluar-masuk saat target hit level 40 (barengan PNP)
		elephantV2Team      = {},   -- sumber pet Switch (team standby di garden)
		elephantV2Types     = {},   -- tipe pet target yg dipantau levelnya
		elephantV2Weight    = 5.5,  -- berat max target sebelum dilepas
		elephantV2MaxPets   = 3,    -- jumlah pet target aktif barengan
		elephantV2Gajah     = "",   -- uuid pet gajah (booster berat)
		elephantV2Switch    = "",   -- uuid pet team yg ditukar sama gajah
		elephantV2Level     = 40,   -- ambang level target buat masukin gajah
		elephantV2Interval  = 0.1,  -- interval baca level (detik)
		elephantV2Enabled   = false,

		-- Automation Event: Beanstalk (NPC Jack) — feed plant sesuai craving trait
		beanstalkPlantEnabled   = false, -- auto tanam seed craving
		beanstalkCollectEnabled = false, -- auto panen fruit craving
		beanstalkSubmitEnabled  = false, -- auto setor produce craving ke beanstalk
		beanstalkClaimEnabled   = false, -- auto claim reward beanstalk (reward point aktif)
		beanstalkAutoSellEnabled= false, -- backpack mentok (trait salah) -> jual SEMUA backpack
		beanstalkHopEnabled     = false, -- auto hop server sampai nemu beanstalk growth < 900
		beanstalkPlantCount     = 20,    -- target jumlah tanam per siklus
		beanstalkDelay          = 0.2,   -- jeda antar aksi (detik)
		buyBeanstalkShopNames   = {},    -- item Beanstalk Event Shop (Goliath's Goods/Friends Deals)
		buyBeanstalkShopEnabled = false,

		-- webhook (opsional)
		webhookUrl     = "",
		webhookEnabled = false,
	}

	-- Setiap clone punya file terpisah. Tujuh executor, tujuh tingkah: yang
	-- nolak write di root, yang nolak slash, yang cuma nerima backslash, yang
	-- VFS-nya ngaco. Jadi simpan ke SEMUA kandidat path (murah), dan saat load
	-- baca yang pertama ketemu. Paling nggak SATU pasti lengket.
	local STORAGE_DIR = "CeszParadiseWindUI"
	pcall(makefolder, STORAGE_DIR)
	local baseName = "state_" .. tostring(userId) .. ".json"
	local legacyName = "garden_state_" .. tostring(userId) .. ".json"
	local STATE_CANDIDATES = {
		baseName,              -- root, format baru (REAL & mayoritas executor: root OK)
		legacyName,            -- root, format lama (kompat garden build)
		STORAGE_DIR .. "/" .. baseName,
		STORAGE_DIR .. "\\" .. baseName,
		STORAGE_DIR .. "\\" .. baseName:gsub("%.", "_") .. ".json", -- netral buat VFS aneh
	}
	-- FS helper: semua akses lewat pcall supaya executor yang nge-throw
	-- di writefile/readfile gak bikin config module mati.
	local function fsIsFile(p)
		if type(isfile) == "function" then return pcall(isfile, p) and isfile(p) or false end
		return false
	end
	local function fsRead(p)
		if type(readfile) == "function" then
			local ok, r = pcall(readfile, p)
			if ok then return r end
		end
		return nil
	end
	local function fsWrite(p, content)
		if type(writefile) == "function" then
			local ok, err = pcall(writefile, p, content)
			return ok, err
		end
		return false, "no writefile"
	end
	local statePathUsed = nil

	local function findStatePath()
		for _, p in ipairs(STATE_CANDIDATES) do
			if fsIsFile(p) then return p end
		end
		return nil
	end

	-- Migrasi file lama yang pernah tersimpan di root (jangan hilangkan setting).
	do
		local target = STATE_CANDIDATES[1]
		local okWriteFlag = false
		pcall(function()
			if fsIsFile(legacyName) and not fsIsFile(target) then
				local old = fsRead(legacyName)
				if old and #old > 0 then
					okWriteFlag = fsWrite(target, old)
					print("[GAGHub][WINDUI] config migrated: " .. legacyName .. " -> " .. target)
				end
			end
		end)
	end

	-- 1. Simpan ke SEMUA kandidat path (paling mentok satu pasti nyantol)
	local function persistState()
		local okAny = false
		if type(writefile) == "function" then
			local okSer, ser = pcall(function() return HttpService:JSONEncode(CFG) end)
			if okSer then
				for _, p in ipairs(STATE_CANDIDATES) do
					local okw = pcall(writefile, p, ser)
					if okw then
						okAny = true
						statePathUsed = p
					end
				end
			end
		end
		return okAny
	end

	-- 2. Muat dari kandidat pertama yang ada
	local function loadState()
		local path = findStatePath()
		if path then
			local raw = fsRead(path)
			if raw and #raw > 0 then
				local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
				if ok and type(data) == "table" then
					statePathUsed = path
					return data
				end
			end
		end
		return nil
	end

	do
		local st = loadState()
		if st then
			print("[GAGHub][WINDUI] config loaded")
			local function tbl(v) return (type(v) == "table") and v or {} end
			local function migratePetSet(t)
				if type(t) ~= "table" then return {} end
				local out = {}
				local petEggLabel = ctx.petEggLabel or (ctx.reg and ctx.reg.petEggLabel)
				for k, v in pairs(t) do
					local newK = petEggLabel and petEggLabel(k) or k
					out[newK] = v
				end
				return out
			end

			CFG.targetPlayer   = st.targetPlayer or ""
			CFG.petTypes       = migratePetSet(st.petTypes)
			CFG.weightFilter   = tonumber(st.weightFilter) or 0
			CFG.ageFilter      = tonumber(st.ageFilter) or 0
			CFG.petsPerTrade   = tonumber(st.petsPerTrade) or 12
			CFG.totalTrades    = tonumber(st.totalTrades) or 14
			CFG.autoUnfavorite = st.autoUnfavorite or false
			CFG.tradeEnabled   = st.tradeEnabled or false
			CFG.tradeTicketEnabled = st.tradeTicketEnabled or st.tradeEnabled or false

			CFG.giftTargetPlayer     = st.giftTargetPlayer or ""
			CFG.giftPetTypes         = migratePetSet(st.giftPetTypes)
			CFG.giftWeightFilter     = tonumber(st.giftWeightFilter) or 0
			CFG.giftAgeFilter        = tonumber(st.giftAgeFilter) or 0
			CFG.giftPetsPerBatch     = tonumber(st.giftPetsPerBatch) or 12
			CFG.giftTotalGifts       = tonumber(st.giftTotalGifts) or 100
			CFG.giftAutoUnfavorite   = st.giftAutoUnfavorite or false
			CFG.tradeGiftEnabled     = st.tradeGiftEnabled or false
			-- Auto Hatch + Auto Sell
			CFG.hatchEnabled    = st.hatchEnabled or false
			CFG.autoSellEnabled = st.autoSellEnabled or false
			CFG.hatchCoreTeam   = tbl(st.hatchCoreTeam)
			CFG.hatchHatchTeam  = tbl(st.hatchHatchTeam)
			CFG.hatchBrontoTeam = tbl(st.hatchBrontoTeam)
			CFG.hatchSellTeam   = tbl(st.hatchSellTeam)
			CFG.hatchEggName    = st.hatchEggName or "Rare Egg"
			CFG.hatchMaxPlaced  = tonumber(st.hatchMaxPlaced) or 8
			CFG.hatchPlacePattern = st.hatchPlacePattern or "Grid"
			CFG.hatchTeamDelay  = tonumber(st.hatchTeamDelay) or 5.5
			CFG.hatchSpeed      = tonumber(st.hatchSpeed) or 0
			CFG.hatchWebhookUrl   = st.hatchWebhookUrl or ""
			CFG.hatchAlertEnabled = st.hatchAlertEnabled or false
			CFG.hatchRejoinMinusEnabled   = st.hatchRejoinMinusEnabled or false
			CFG.hatchRejoinMinusThreshold = tonumber(st.hatchRejoinMinusThreshold) or 20
			CFG.hatchRejoinPlusEnabled    = st.hatchRejoinPlusEnabled or false
			CFG.hatchRejoinPlusThreshold  = tonumber(st.hatchRejoinPlusThreshold) or 20
			CFG.brontoSpecialPets    = tbl(st.brontoSpecialPets)
			CFG.brontoSpecialWeight  = tonumber(st.brontoSpecialWeight) or 0
			CFG.brontoUniversalTypes = tbl(st.brontoUniversalTypes)
			CFG.brontoUniversalWeight = tonumber(st.brontoUniversalWeight) or 0
			CFG.brontoSkipSpecial    = st.brontoSkipSpecial or false
			CFG.brontoTeamDelay      = tonumber(st.brontoTeamDelay) or 5.5
			CFG.sellPetTypes    = tbl(st.sellPetTypes)
			CFG.sellWeightThreshold = tonumber(st.sellWeightThreshold) or 5
			CFG.sellAgeThreshold    = tonumber(st.sellAgeThreshold) or 3
			CFG.sellSpecialTypes    = tbl(st.sellSpecialTypes)
			CFG.sellSpecialWeight   = tonumber(st.sellSpecialWeight) or 10
			CFG.sellMode   = st.sellMode or "Cycle"
			CFG.sellStyle  = st.sellStyle or "All at Once"
			CFG.sellEveryNCycles = tonumber(st.sellEveryNCycles) or 1
			CFG.sellWhenReach    = tonumber(st.sellWhenReach) or 100
			CFG.sellTeamDelay    = tonumber(st.sellTeamDelay) or 5.5
			CFG.autoBoostBeforeSell = st.autoBoostBeforeSell or false
			CFG.hatchCoreEquipDelay   = tonumber(st.hatchCoreEquipDelay) or 0
			CFG.hatchCoreUnequipDelay = tonumber(st.hatchCoreUnequipDelay) or 1
			CFG.hatchBrontoEquipDelay = tonumber(st.hatchBrontoEquipDelay) or 0
			CFG.hatchBrontoUnequipDelay = tonumber(st.hatchBrontoUnequipDelay) or 1
			CFG.hatchTeamEquipDelay   = tonumber(st.hatchTeamEquipDelay) or 0
			CFG.hatchTeamUnequipDelay = tonumber(st.hatchTeamUnequipDelay) or 1
			CFG.hatchSellEquipDelay   = tonumber(st.hatchSellEquipDelay) or 0
			CFG.hatchSellUnequipDelay = tonumber(st.hatchSellUnequipDelay) or 1
			CFG.hatchSellList         = migratePetSet(st.hatchSellList)
			CFG.autoUnfavoritePets    = st.autoUnfavoritePets or false
			CFG.unfavoritePetTypes    = migratePetSet(st.unfavoritePetTypes)
			CFG.tradeMethod           = st.tradeMethod or "ticket"
			CFG.acceptGifts    = st.acceptGifts or false
			CFG.acceptTrades   = st.acceptTrades or false
			CFG.autoFavorite   = st.autoFavorite or false
			CFG.favoritePetTypes = migratePetSet(st.favoritePetTypes)
			CFG.pnpPetTypes = (type(st.pnpPetTypes) == "table") and st.pnpPetTypes or {}
			CFG.pnpUuids    = (type(st.pnpUuids) == "table") and st.pnpUuids or {}
			CFG.pickupDelay = tonumber(st.pickupDelay) or 0.5
			CFG.equipDelay  = tonumber(st.equipDelay) or 1e-20
			CFG.pnpScanInterval = tonumber(st.pnpScanInterval) or 0.5
			CFG.pnpEnabled  = st.pnpEnabled or false
			CFG.espEnabled = st.espEnabled or false
			CFG.espMode = st.espMode or "target"
			CFG.espEggEnabled = st.espEggEnabled or false
			CFG.espEggMode = st.espEggMode or "target"
			CFG.espInvEnabled = st.espInvEnabled or false
			CFG.espInvMode = st.espInvMode or "age"
			CFG.noclipEnabled = st.noclipEnabled or false
			CFG.walkSpeedEnabled = st.walkSpeedEnabled or false
			CFG.walkSpeed = tonumber(st.walkSpeed) or 16
			CFG.infJumpEnabled = st.infJumpEnabled or false
			CFG.hideMyPlants = st.hideMyPlants or false
			CFG.hideOtherPlants = st.hideOtherPlants or false
			CFG.autoRemoveWebFx = st.autoRemoveWebFx or false
			CFG.perfMode = st.perfMode or "off"
			CFG.disable3d = st.disable3d or false
			CFG.premiumItem = st.premiumItem or ""
			CFG.premiumPay = st.premiumPay or "robux"
			
			CFG.levelingTeamUuids   = (type(st.levelingTeamUuids) == "table") and st.levelingTeamUuids or {}
			CFG.levelingPetTypes    = migratePetSet(st.levelingPetTypes)
			CFG.levelingTargetLevel = tonumber(st.levelingTargetLevel) or 500
			CFG.levelingMaxPets     = tonumber(st.levelingMaxPets) or 2
			CFG.levelingEnabled     = st.levelingEnabled or false

			-- Leveling V2
			CFG.levelingV2PetTypes = migratePetSet(st.levelingV2PetTypes)
			CFG.levelingV2P1Team   = (type(st.levelingV2P1Team) == "table") and st.levelingV2P1Team or {}
			CFG.levelingV2P1Target = tonumber(st.levelingV2P1Target) or 40
			CFG.levelingV2P1Max    = tonumber(st.levelingV2P1Max) or 3
			CFG.levelingV2P2Team   = (type(st.levelingV2P2Team) == "table") and st.levelingV2P2Team or {}
			CFG.levelingV2P2Target = tonumber(st.levelingV2P2Target) or 500
			CFG.levelingV2P2Max    = tonumber(st.levelingV2P2Max) or 1
			CFG.levelingV2Enabled  = st.levelingV2Enabled or false

			-- Growth
			CFG.growthEnabled  = st.growthEnabled or false
			CFG.growthPetTypes = migratePetSet(st.growthPetTypes)
			CFG.growthPetTypesElephant = migratePetSet(st.growthPetTypesElephant)
			CFG.growthPetTypesMutation = migratePetSet(st.growthPetTypesMutation)
			CFG.growthPetTypesLeveling = migratePetSet(st.growthPetTypesLeveling)
			CFG.growthFlow     = (type(st.growthFlow) == "table") and st.growthFlow or { "elephant", "mutation", "leveling" }
			CFG.growthElephantTeam   = (type(st.growthElephantTeam) == "table") and st.growthElephantTeam or {}
			CFG.growthElephantWeight = tonumber(st.growthElephantWeight) or 5.5
			CFG.growthElephantMax    = tonumber(st.growthElephantMax) or 2
			CFG.growthMutationTeam    = (type(st.growthMutationTeam) == "table") and st.growthMutationTeam or {}
			CFG.growthMutationTargets = (type(st.growthMutationTargets) == "table") and st.growthMutationTargets or {}
			CFG.growthMutationMax     = tonumber(st.growthMutationMax) or 2
			CFG.growthLevP1Team   = (type(st.growthLevP1Team) == "table") and st.growthLevP1Team or {}
			CFG.growthLevP1Target = tonumber(st.growthLevP1Target) or 40
			CFG.growthLevP1Max    = tonumber(st.growthLevP1Max) or 3
			CFG.growthLevP2Team   = (type(st.growthLevP2Team) == "table") and st.growthLevP2Team or {}
			CFG.growthLevP2Target = tonumber(st.growthLevP2Target) or 500
			CFG.growthLevP2Max    = tonumber(st.growthLevP2Max) or 1

			-- Automation Mutation
			CFG.mutationExpTeam       = (type(st.mutationExpTeam) == "table") and st.mutationExpTeam or {}
			CFG.mutationBoostTeam     = (type(st.mutationBoostTeam) == "table") and st.mutationBoostTeam or {}
			CFG.mutationPhoenixTeam   = (type(st.mutationPhoenixTeam) == "table") and st.mutationPhoenixTeam or {}
			CFG.mutationTargetTypes   = migratePetSet(st.mutationTargetTypes)
			CFG.mutationTargetMutations = (type(st.mutationTargetMutations) == "table") and st.mutationTargetMutations or {}
			CFG.mutationTargetAge     = tonumber(st.mutationTargetAge) or 50
			CFG.mutationDelayAutoClaim = tonumber(st.mutationDelayAutoClaim) or 0.5
			CFG.mutationEnabled       = st.mutationEnabled or false

			CFG.buySeedNames   = (type(st.buySeedNames) == "table") and st.buySeedNames or {}
			CFG.buySeedEnabled = st.buySeedEnabled or false
			CFG.buyEggNames    = (type(st.buyEggNames) == "table") and st.buyEggNames or {}
			CFG.buyEggEnabled  = st.buyEggEnabled or false
			CFG.buyGearNames   = (type(st.buyGearNames) == "table") and st.buyGearNames or {}
			CFG.buyGearEnabled = st.buyGearEnabled or false

			CFG.merchantBuyEnabled = st.merchantBuyEnabled or false
			CFG.merchantBuyAll     = st.merchantBuyAll or false
			CFG.merchantBuyBest    = st.merchantBuyBest or false
			CFG.merchantItems      = (type(st.merchantItems) == "table") and st.merchantItems or {}
			CFG.merchantUiShop     = st.merchantUiShop or ""
			CFG.merchantAutoOpenUI = st.merchantAutoOpenUI or false

			CFG.waterFruitNames = (type(st.waterFruitNames) == "table") and st.waterFruitNames or {}
			CFG.waterEnabled    = st.waterEnabled or false
			CFG.waterDelay      = tonumber(st.waterDelay) or 1

			CFG.shovelTreeNames    = (type(st.shovelTreeNames) == "table") and st.shovelTreeNames or {}
			CFG.shovelTreeEnabled  = st.shovelTreeEnabled or false
			CFG.shovelTreeDelay    = tonumber(st.shovelTreeDelay) or 0
			CFG.shovelFruitNames    = (type(st.shovelFruitNames) == "table") and st.shovelFruitNames or {}
			CFG.shovelFruitMuts     = (type(st.shovelFruitMuts) == "table") and st.shovelFruitMuts or {}
			CFG.shovelFruitVariants = (type(st.shovelFruitVariants) == "table") and st.shovelFruitVariants or {}
			CFG.shovelFruitMode     = st.shovelFruitMode or ">= (berat minimal)"
			CFG.shovelFruitWeight   = tonumber(st.shovelFruitWeight) or 0
			CFG.shovelFruitEnabled  = st.shovelFruitEnabled or false
			CFG.shovelFruitDelay    = tonumber(st.shovelFruitDelay) or 0

			CFG.collectDelay          = tonumber(st.collectDelay) or 0
			CFG.collectStopIfFull     = st.collectStopIfFull or false
			CFG.collectAutoSellIfFull = st.collectAutoSellIfFull or false
			CFG.collectWlFruitNames   = (type(st.collectWlFruitNames) == "table") and st.collectWlFruitNames or {}
			CFG.collectWlFruitEnabled = st.collectWlFruitEnabled or false
			CFG.collectWlMutNames     = (type(st.collectWlMutNames) == "table") and st.collectWlMutNames or {}
			CFG.collectWlMutEnabled   = st.collectWlMutEnabled or false
			CFG.collectCombFruitNames = (type(st.collectCombFruitNames) == "table") and st.collectCombFruitNames or {}
			CFG.collectCombMutNames   = (type(st.collectCombMutNames) == "table") and st.collectCombMutNames or {}
			CFG.collectCombVariants   = (type(st.collectCombVariants) == "table") and st.collectCombVariants or {}
			CFG.collectCombMode       = st.collectCombMode or ">= (berat minimal)"
			CFG.collectCombWeight     = tonumber(st.collectCombWeight) or 0
			CFG.collectCombEnabled    = st.collectCombEnabled or false
			CFG.collectBlMutNames     = (type(st.collectBlMutNames) == "table") and st.collectBlMutNames or {}
			CFG.collectBlMutEnabled   = st.collectBlMutEnabled or false

			CFG.favFruitNames = (type(st.favFruitNames) == "table") and st.favFruitNames or {}
			CFG.favMutNames   = (type(st.favMutNames) == "table") and st.favMutNames or {}
			CFG.favMode       = st.favMode or ">= (berat minimal)"
			CFG.favWeight     = tonumber(st.favWeight) or 0
			CFG.favDelay      = tonumber(st.favDelay) or 1
			CFG.favEnabled    = st.favEnabled or false
			CFG.unfavEnabled  = st.unfavEnabled or false

			CFG.reclaimPlantNames = (type(st.reclaimPlantNames) == "table") and st.reclaimPlantNames or {}
			CFG.reclaimEnabled    = st.reclaimEnabled or false
			CFG.reclaimSpeed      = tonumber(st.reclaimSpeed) or 0.15
			CFG.plantSeedNames   = (type(st.plantSeedNames) == "table") and st.plantSeedNames or {}
			local pp = st.plantPosition
			if pp == "God Position" then pp = "Good Position" end -- rename lama
			CFG.plantPosition    = (pp == "Player Position" or pp == "Good Position") and pp or "Random"
			CFG.goodClear        = (st.goodClear ~= false)
			CFG.plantDelay       = tonumber(st.plantDelay) or 0
			CFG.plantSeedEnabled = st.plantSeedEnabled or false
			CFG.sprinklerNames        = (type(st.sprinklerNames) == "table") and st.sprinklerNames or {}
			CFG.sprinklerPlantNames   = (type(st.sprinklerPlantNames) == "table") and st.sprinklerPlantNames or {}
			CFG.sprinklerPosition     = (st.sprinklerPosition == "Player Position") and "Player Position" or "Random"
			CFG.sprinklerDelay        = tonumber(st.sprinklerDelay) or 0
			CFG.sprinklerEnabled      = st.sprinklerEnabled or false
			CFG.shovelSprinklerNames  = (type(st.shovelSprinklerNames) == "table") and st.shovelSprinklerNames or {}
			CFG.shovelSprinklerDelay  = tonumber(st.shovelSprinklerDelay) or 0
			CFG.shovelSprinklerEnabled = st.shovelSprinklerEnabled or false
			CFG.gmSprinklerEnabled    = st.gmSprinklerEnabled or false
			if st.autoReconnect ~= nil then CFG.autoReconnect = st.autoReconnect end
			CFG.reconnectEnabled  = st.reconnectEnabled or false
			CFG.reconnectInterval = tonumber(st.reconnectInterval) or 5

			CFG.cleanseTeamUuids     = (type(st.cleanseTeamUuids) == "table") and st.cleanseTeamUuids or {}
			CFG.cleansePetTypes      = migratePetSet(st.cleansePetTypes)
			CFG.cleanseKeepMutations = (type(st.cleanseKeepMutations) == "table") and st.cleanseKeepMutations or {}
			CFG.cleanseMaxPets       = tonumber(st.cleanseMaxPets) or 2
			CFG.cleanseEnabled       = st.cleanseEnabled or false

			CFG.boostPetUuids  = (type(st.boostPetUuids) == "table") and st.boostPetUuids or {}
			CFG.boostItemNames = (type(st.boostItemNames) == "table") and st.boostItemNames or {}
			CFG.boostEnabled   = st.boostEnabled or false

			CFG.elephantTeamUuids   = (type(st.elephantTeamUuids) == "table") and st.elephantTeamUuids or {}
			CFG.elephantPetTypes    = migratePetSet(st.elephantPetTypes)
			CFG.elephantTargetWeight = tonumber(st.elephantTargetWeight) or 5.5
			CFG.elephantMaxPets     = tonumber(st.elephantMaxPets) or 2
			CFG.elephantEnabled     = st.elephantEnabled or false
			CFG.elephantV2Team      = (type(st.elephantV2Team) == "table") and st.elephantV2Team or {}
			CFG.elephantV2Types     = migratePetSet(st.elephantV2Types)
			CFG.elephantV2Weight    = tonumber(st.elephantV2Weight) or 5.5
			CFG.elephantV2MaxPets   = tonumber(st.elephantV2MaxPets) or 3
			CFG.elephantV2Gajah     = (type(st.elephantV2Gajah) == "string") and st.elephantV2Gajah or ""
			CFG.elephantV2Switch    = (type(st.elephantV2Switch) == "string") and st.elephantV2Switch or ""
			CFG.elephantV2Level     = tonumber(st.elephantV2Level) or 40
			CFG.elephantV2Interval  = tonumber(st.elephantV2Interval) or 0.1
			CFG.elephantV2Enabled   = st.elephantV2Enabled or false

			CFG.beanstalkPlantEnabled   = st.beanstalkPlantEnabled or false
			CFG.beanstalkCollectEnabled = st.beanstalkCollectEnabled or false
			CFG.beanstalkSubmitEnabled  = st.beanstalkSubmitEnabled or false
			CFG.beanstalkClaimEnabled   = st.beanstalkClaimEnabled or false
			CFG.beanstalkAutoSellEnabled= st.beanstalkAutoSellEnabled or false
			CFG.beanstalkHopEnabled     = st.beanstalkHopEnabled or false
			CFG.beanstalkPlantCount     = tonumber(st.beanstalkPlantCount) or 20
			CFG.beanstalkDelay          = tonumber(st.beanstalkDelay) or 0.2
			CFG.buyBeanstalkShopNames   = (type(st.buyBeanstalkShopNames) == "table") and st.buyBeanstalkShopNames or {}
			CFG.buyBeanstalkShopEnabled = st.buyBeanstalkShopEnabled or false

			CFG.webhookUrl     = st.webhookUrl or ""
			CFG.webhookEnabled = st.webhookEnabled or false

			-- Bukti restore yang kelihatan di UI (Settings > Config Status).
			local nKeys = 0
			for _ in pairs(st) do nKeys = nKeys + 1 end
			ctx.state.cfgLoadInfo = "LOADED " .. tostring(nKeys)
				.. " settings from " .. tostring(statePathUsed or "file")
			print("[GAGHub][WINDUI] " .. ctx.state.cfgLoadInfo)
		else
			print("[GAGHub][WINDUI] config: no saved state, defaults")
		end
	end

	ctx.CFG = CFG

	------------------------------------------------------------------ Autosave
	-- Safety net di atas save-on-change dari UI (toggle/input/dropdown sudah
	-- persist instan): dirty-check tiap 10s nangkep perubahan CFG dari runtime
	-- module + flush terakhir saat client mati (BindToClose).
	-- Error FS TIDAK di-swallow: catat 1x ke log biar ketahuan kenapa config
	-- nggak nempel di executor tertentu (no writefile / write ditolak).
	local lastSaved = nil
	local fsWarned = false
	-- config.lua jalan SEBELUM window.lua, jadi ctx.log belum ada -> log manual
	-- via logLines biar statusnya cumul terlihat di Settings > Logs.
	local earlyLog = ctx.log
	if type(earlyLog) ~= "function" then
		earlyLog = function(msg)
			local L = ctx.state and ctx.state.logLines
			if L then L[#L + 1] = os.date("%H:%M:%S ") .. tostring(msg) end
			print("[WindUIHub] " .. tostring(msg))
		end
	end
	-- jsonSafe CFG runtime bisa nyampur nilai non-JSON (fungsi, Instance, NaN)
	-- -> JSONEncode nge-throw -> file gak pernah ketulis & folder kosong.
	-- Drop-in clone yang cuma nyimpen number/string/boolean/table polos.
	local function jsonSafe(v, depth)
		local t = type(v)
		if t == "number" then
			if v ~= v or v == math.huge or v == -math.huge then return 0 end
			return v
		elseif t == "string" or t == "boolean" then
			return v
		elseif t == "table" and depth < 9 then
			local out = {}
			for k, val in pairs(v) do
				local kt = type(k)
				if kt == "string" or kt == "number" then
					local sv = jsonSafe(val, depth + 1)
					if sv ~= nil then out[k] = sv end
				end
			end
			return out
		end
		return nil
	end
	local function autoSave()
		if type(writefile) ~= "function" then return end
		-- jsonSafe: BGANYA executor JSONEncode-nya nge-throw kalau CFG kecampur
		-- fungsi/instance/NaN (module runtime bisa nambahin) -> file gak pernah
		-- ketulis & folder tetap kosong. Bersihin dulu: cuma angka/string/boolean
		-- yang lolos, sisanya dibuang. 1e-20 aman, hasil string pasti encodable.
		local ok, ser = pcall(function()
			return HttpService:JSONEncode(jsonSafe(CFG, 0))
		end)
		if not ok then
			if not fsWarned then
				fsWarned = true
				earlyLog("autosave FAIL (encode): " .. tostring(ser))
			end
			return
		end
		if lastSaved == ser then return end
		-- Backup rotasi: sebelum nimpa file utama, arsipkan isi lamanya ke .bak.
		-- Kalau ada wipe aneh, selalu ada jalan pulang satu langkah.
		if type(readfile) == "function" and type(writefile) == "function" then
			pcall(function()
				local mainP = STATE_CANDIDATES[1]
				local old = readfile(mainP)
				if old and #old > 0 and old ~= ser then
					writefile(mainP .. ".bak", old)
				end
			end)
		end
		-- Tulis ke SEMUA kandidat: VFS executor beda-beda tingkahnya, dan
		-- satu path yang nyantol itu semua yang dibutuhkan buat load balik.
		local wroteAny = false
		for _, p in ipairs(STATE_CANDIDATES) do
			local okw = pcall(writefile, p, ser)
			if okw then
				wroteAny = true
				statePathUsed = p
			end
		end
		if wroteAny then
			lastSaved = ser
		elseif not fsWarned then
			fsWarned = true
			earlyLog("autosave FAIL (write): semua kandidat path ditolak executor")
		end
	end

	ctx.persistState = function()
		lastSaved = nil
		autoSave()
	end

	task.spawn(function()
		while true do
			task.wait(10)
			autoSave()
		end
	end)
	pcall(function() game:BindToClose(autoSave) end)

	-- Probe filesystem tiap kandidat: tulis 1 byte + baca balik. JANGAN break
	-- di kandidat pertama (executor bisa nolak slash tapi terima backslash).
	pcall(function()
		ctx.CFG_STATE_PATH = STATE_CANDIDATES[1]
		ctx.CFG_STATE_CANDIDATES = STATE_CANDIDATES
	end)
	task.spawn(function()
		local okPaths, badPaths = {}, {}
		if type(writefile) == "function" and type(readfile) == "function" then
			for _, p in ipairs(STATE_CANDIDATES) do
				pcall(function()
					local pf = p .. ".probe"
					writefile(pf, "1")
					if readfile(pf) == "1" then
						okPaths[#okPaths + 1] = p
					else
						badPaths[#badPaths + 1] = p
					end
					pcall(delfile, pf)
				end)
			end
		end
		local summary
		if #okPaths > 0 then
			summary = "Config storage OK via: " .. table.concat(okPaths, ", ")
			if #badPaths > 0 then
				summary = summary .. "  |  rejected: " .. table.concat(badPaths, ", ")
			end
		else
			summary = "Config storage MATI di executor ini (writefile/readfile gagal semua)"
		end
		ctx.state.fsStatus = summary
		earlyLog(summary)
		-- Toast PENDEK: path utama aja, satu baris (nungulin semua kandidat
		-- path = notif numpuk jelek). Detail lengkup tetap kebaca di panel
		-- Config Status & tab Logs.
		local toast
		if #okPaths > 0 then
			toast = "Config OK: " .. okPaths[1]
		else
			toast = "Config storage MATI - cek tab Settings"
		end
		task.delay(4.5, function()
			if ctx.wi and ctx.wi.notify then
				pcall(function() ctx.wi.notify("Config", toast, 4) end)
			end
		end)
	end)
end]=],
	["modules/core/registry.lua"] = [=[
--[[ registry.lua — opsi dropdown pet type & mutation. ]]
return function(ctx)
	local PetEggs   = ctx.deps.PetEggs
	local EnumToMut = ctx.deps.EnumToMut

	-- Daftar pet type unik & pemetaan ke egg asal (format "Pet - Egg" apabila dari egg).
	local RAW_PET_OPTIONS = {} -- nama pet polos (mis. "Raccoon")
	local PET_OPTIONS = {}     -- opsi dropdown: "Pet - Egg" jika ada egg, atau "Pet" jika bukan dari egg
	local petEggMap = {}       -- petType -> eggName (egg asli pertama yg punya pet ini)
	do
		local eggNames = {}
		for eggName in pairs(PetEggs) do eggNames[#eggNames + 1] = eggName end
		table.sort(eggNames)

		local seen = {}
		for _, eggName in ipairs(eggNames) do
			local egg = PetEggs[eggName]
			local items = egg and egg.RarityData and egg.RarityData.Items
			if items then
				-- skip egg catch-all/admin (mis. "Fake Egg" isi 431 pet) dari peta pet->egg
				local cnt = 0; for _ in pairs(items) do cnt = cnt + 1 end
				local realEgg = eggName ~= "Fake Egg" and cnt <= 40
				for petName in pairs(items) do
					local s = tostring(petName):match("([^/]+)$") or tostring(petName)
					if not tostring(petName):match("^Egg/") and not seen[s] then
						seen[s] = true
						RAW_PET_OPTIONS[#RAW_PET_OPTIONS + 1] = s
					end
					if realEgg and not petEggMap[s] then petEggMap[s] = eggName end
				end
			end
		end

		-- Pet tambahan dari PetList jika ada
		local okPL, PetList = pcall(function()
			return require(game:GetService("ReplicatedStorage").Data.PetRegistry.PetList)
		end)
		if okPL and type(PetList) == "table" then
			for petName in pairs(PetList) do
				local s = tostring(petName):match("([^/]+)$") or tostring(petName)
				if not tostring(petName):match("^Egg/") and not seen[s] then
					seen[s] = true
					RAW_PET_OPTIONS[#RAW_PET_OPTIONS + 1] = s
				end
			end
		end

		table.sort(RAW_PET_OPTIONS)

		-- Bangun PET_OPTIONS: jika dari egg -> "Pet - Egg", jika bukan -> "Pet"
		for _, pt in ipairs(RAW_PET_OPTIONS) do
			local egg = petEggMap[pt]
			PET_OPTIONS[#PET_OPTIONS + 1] = egg and (pt .. " - " .. egg) or pt
		end
		table.sort(PET_OPTIONS)
	end

	local function petBaseName(str)
		if not str then return "" end
		local base = tostring(str):match("^(.-)%s*-%s*")
		return base or tostring(str)
	end

	local function petEggLabel(pt)
		if not pt then return "" end
		local base = petBaseName(pt)
		local egg = petEggMap[base] or petEggMap[pt]
		return egg and (base .. " - " .. egg) or tostring(pt)
	end

	-- Opsi filter sell / compatibility alias
	local PET_EGG_OPTIONS = PET_OPTIONS

	-- CUMA pet yang punya egg asli (format "Pet - Egg"). Buat filter yang wajib ada egg-nya
	-- (Special Pets, Universal, Pet to Sell) — pet tanpa egg tidak ditampilkan.
	local PET_EGG_ONLY = {}
	for _, pt in ipairs(RAW_PET_OPTIONS) do
		if petEggMap[pt] then PET_EGG_ONLY[#PET_EGG_ONLY + 1] = pt .. " - " .. petEggMap[pt] end
	end
	table.sort(PET_EGG_ONLY)

	-- Helper pencocokan universal: periksa apakah pet cocok dengan himpunan pilihan (typeSet).
	-- Mendukung tipe key "Pet - Egg" maupun key nama polos ("Pet") untuk backward compatibility.
	local function petMatchesType(typeSet, petType, petData)
		if not typeSet or not next(typeSet) or not petType then return false end
		-- 1. Direct match (mis. typeSet["Raccoon - Night Egg"] atau typeSet["Raccoon"])
		if typeSet[petType] then return true end

		-- 2. Base pet name jika petType berformat "Pet - Egg"
		local base = petBaseName(petType)
		if base ~= petType and typeSet[base] then return true end

		-- 3. Cek kombinasi "Pet - Egg" dari data pet atau peta egg
		local rawName = (base ~= "" and base ~= petType) and base or petType
		local egg = (petData and petData.HatchedFrom) or petEggMap[rawName] or petEggMap[petType]
		if egg then
			local combo = rawName .. " - " .. egg
			if typeSet[combo] then return true end
		end

		-- 4. Case-insensitive fallback
		local ptLower = rawName:lower()
		for k in pairs(typeSet) do
			local kBaseLower = petBaseName(k):lower()
			if kBaseLower == ptLower then return true end
		end

		return false
	end

	local MUT_OPTIONS, seenMut = { "None" }, { None = true }
	for _, name in pairs(EnumToMut) do
		if name ~= "Normal" and not seenMut[name] then
			seenMut[name] = true
			MUT_OPTIONS[#MUT_OPTIONS + 1] = name
		end
	end
	table.sort(MUT_OPTIONS)

	-- Mutasi yang bisa dari mesin: MachineMutationTypes (base) + Level500MutationTypes (500 only).
	local MACHINE_MUT_OPTIONS = { "None" }
	do
		local ok, MutReg = pcall(function()
			return require(game:GetService("ReplicatedStorage").Data.PetRegistry.PetMutationRegistry)
		end)
		local names, seen = {}, {}
		if ok and MutReg then
			for _, src in ipairs({ MutReg.MachineMutationTypes, MutReg.Level500MutationTypes }) do
				if type(src) == "table" then
					for name in pairs(src) do
						local n = tostring(name)
						if not seen[n] then seen[n] = true; names[#names + 1] = n end
					end
				end
			end
			-- Ice Golem-exclusive dari Mutation Machine (via passive Cold Gears): ada di
			-- PetMutationRegistry tapi bukan di MachineMutationTypes/Level500 -> tambah manual.
			for _, n in ipairs({ "ChristmasRally", "JollyDecorator", "MerryNursery", "GiantGolem" }) do
				local pmr = MutReg.PetMutationRegistry
				if type(pmr) == "table" and pmr[n] and not seen[n] then
					seen[n] = true; names[#names + 1] = n
				end
			end
		end
		if #names > 0 then
			table.sort(names)
			for _, n in ipairs(names) do MACHINE_MUT_OPTIONS[#MACHINE_MUT_OPTIONS + 1] = n end
		else
			MACHINE_MUT_OPTIONS = MUT_OPTIONS -- fallback: semua mutasi
		end
	end

	local function mutDisplay(code)
		if code == nil or code == "" or code == "m" or code == "None" or code == "Normal" then return "None" end
		return EnumToMut[code] or code
	end

	ctx.reg = {
		PET_OPTIONS = PET_OPTIONS,
		RAW_PET_OPTIONS = RAW_PET_OPTIONS,
		PET_EGG_OPTIONS = PET_EGG_OPTIONS,
		PET_EGG_ONLY = PET_EGG_ONLY,
		petEggMap = petEggMap,
		petBaseName = petBaseName,
		petEggLabel = petEggLabel,
		petMatchesType = petMatchesType,
		MUT_OPTIONS = MUT_OPTIONS,
		MACHINE_MUT_OPTIONS = MACHINE_MUT_OPTIONS,
		mutDisplay = mutDisplay,
	}
	ctx.petEggMap = petEggMap
	ctx.petBaseName = petBaseName
	ctx.petEggLabel = petEggLabel
	ctx.petMatchesType = petMatchesType
end
]=],
	["modules/core/services.lua"] = [=[
--[[ services.lua — services + deps game (garden). ]]
return function(ctx)
	local Players     = game:GetService("Players")
	local RS          = game:GetService("ReplicatedStorage")
	local HttpService = game:GetService("HttpService")
	local UserInputService = game:GetService("UserInputService")

	if not game:IsLoaded() then game.Loaded:Wait() end
	repeat task.wait() until Players.LocalPlayer

	ctx.Services = {
		Players = Players, RS = RS, HttpService = HttpService, UserInputService = UserInputService,
	}
	ctx.LP = Players.LocalPlayer

	local DataService = require(RS.Modules.DataService)
	local PetEggs     = require(RS.Data.PetRegistry.PetEggs)
	local MutReg      = require(RS.Data.PetRegistry.PetMutationRegistry)
	local okPU, PU    = pcall(require, RS.Modules.PetServices.PetUtilities)

	-- TradingController singleton (buat baca state trade aktif)
	local okTC, TradingController = pcall(require, RS.Modules.TradeControllers.TradingController)

	local TradeEvents = RS.GameEvents.TradeEvents

	ctx.deps = {
		DataService      = DataService,
		PetEggs          = PetEggs,
		MutReg           = MutReg,
		EnumToMut        = MutReg.EnumToPetMutation,
		TradingController = okTC and TradingController or nil,

		TradeEvents   = TradeEvents,
		SendRequest   = TradeEvents.SendRequest,
		RespondRequest = TradeEvents.RespondRequest,
		AddItem       = TradeEvents.AddItem,
		RemoveItem    = TradeEvents.RemoveItem,
		Accept        = TradeEvents.Accept,
		Confirm       = TradeEvents.Confirm,
		Decline       = TradeEvents.Decline,
		FavoriteItem  = RS.GameEvents:FindFirstChild("Favorite_Item"),
		Gift          = RS.GameEvents:FindFirstChild("Gift"),
		-- Gift pet langsung (beda dari trade): GiftPet masuk, AcceptPetGift buat terima.
		GiftPet       = RS.GameEvents:FindFirstChild("GiftPet"),
		AcceptPetGift = RS.GameEvents:FindFirstChild("AcceptPetGift"),
		-- PNP (pick & place): PetsService("UnequipPet",uuid) / ("EquipPet",uuid,cframeStr)
		PetsService   = RS.GameEvents:FindFirstChild("PetsService"),
		PU            = okPU and PU or nil,
		-- cooldown skill: PetCooldownsUpdated(uuid, {{Time=,Passive=},...})
		PetCooldownsUpdated = RS.GameEvents:FindFirstChild("PetCooldownsUpdated"),
	}
end
]=],
	["modules/core/webhook.lua"] = [=[
--[[ sender.lua — Helper kirim webhook Discord dengan bypass proxy. ]]
local HttpService = game:GetService("HttpService")

local function sendWebhook(url, payload, ctx)
	if not url or url == "" then return end

	-- Trim leading and trailing whitespace
	local cleanUrl = url:match("^%s*(.-)%s*$")
	if not cleanUrl or cleanUrl == "" then return end

	-- Nama & avatar pengirim webhook (override default). Semua notif tampil "CeszParadiseHub".
	if type(payload) == "table" then
		if not payload.username then payload.username = "CeszParadise" end
		if not payload.avatar_url then payload.avatar_url = "https://raw.githubusercontent.com/milmscr/opoki/main/tegalan/Logo/logo_icon.png" end
	end
	
	-- Gunakan proxy jika menggunakan HttpService standard karena Discord memblokir Roblox UA
	local proxiedUrl = cleanUrl:gsub("discord.com/api/webhooks/", "webhook.lewis.es/api/webhooks/")
	proxiedUrl = proxiedUrl:gsub("discordapp.com/api/webhooks/", "webhook.lewis.es/api/webhooks/")
	
	local jsonPayload = HttpService:JSONEncode(payload)

	-- Kirim di thread TERPISAH (fire-and-forget) supaya request HTTP yg blocking
	-- (~100-500ms) TIDAK nge-freeze loop automation yg manggil -> cegah stutter.
	task.spawn(function()
	local sent = false
	local reqErr = ""

	-- 1. Coba gunakan executor HTTP request (client-side, bypass blocks)
	-- Mendukung baik key uppercase maupun lowercase untuk menjamin kompatibilitas 100% executor
	local reqFn = (syn and syn.request) or (http and http.request) or http_request or request
	if reqFn then
		local success, res = pcall(function()
			return reqFn({
				Url = cleanUrl,
				url = cleanUrl,
				Method = "POST",
				method = "POST",
				Headers = {
					["Content-Type"] = "application/json",
					["content-type"] = "application/json"
				},
				headers = {
					["Content-Type"] = "application/json",
					["content-type"] = "application/json"
				},
				Body = jsonPayload,
				body = jsonPayload
			})
		end)
		if success and res then
			if res.StatusCode == 200 or res.StatusCode == 204 then
				sent = true
			else
				reqErr = "StatusCode: " .. tostring(res.StatusCode) .. " - " .. tostring(res.Body or "No response body")
			end
		else
			reqErr = tostring(res or "Unknown executor request error")
		end
	else
		reqErr = "Executor tidak memiliki fungsi request/http_request"
	end

	-- 2. Fallback ke HttpService:PostAsync (menggunakan proxy) jika executor request gagal atau tidak tersedia
	if not sent then
		local success, err = pcall(function()
			HttpService:PostAsync(proxiedUrl, jsonPayload, Enum.HttpContentType.ApplicationJson)
		end)
		if success then
			sent = true
		else
			local errMsg = "Fallback failed: " .. tostring(err) .. " | Exec error: " .. reqErr
			warn("[AllegiaanGarden Webhook] " .. errMsg)
			if ctx and ctx.log then
				ctx.log("[Webhook Error] " .. errMsg)
			end
		end
	end
	end)
end

return sendWebhook
]=],
	["modules/elephant/automation_elephant_v1.lua"] = [=[
--[[ elephant.lua — Automation Elephant (V1).
     Sama seperti Leveling, tapi patokan = BERAT (PetData.BaseWeight, KG), bukan Level.
     Passive elephant numbuhin berat pet target; kalau pet sudah mencapai Target Weight
     (mis. 5.5 KG = max), dicabut dan diganti pet target lain yang belum max. ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local PetsService = ctx.deps.PetsService
	local CFG         = ctx.CFG
	local LP          = ctx.LP
	local RS          = game:GetService("ReplicatedStorage")

	local function farmCenter()
		local GetFarm = require(RS.Modules.GetFarm)
		local farm = GetFarm and GetFarm(LP)
		local pa = farm and farm:FindFirstChild("PetArea")
		if pa then return pa.Position end
		local char = LP.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		return hrp and hrp.Position or nil
	end

	local slotOf, nextSlot = {}, 0
	local GRID_COLS, GRID_SP = 6, 3
	local function getPos(uuid)
		if not slotOf[uuid] then slotOf[uuid] = nextSlot; nextSlot = nextSlot + 1 end
		local center = farmCenter()
		if not center then return nil end
		local i = slotOf[uuid]
		local col = i % GRID_COLS
		local row = math.floor(i / GRID_COLS)
		local offX = (col - (GRID_COLS - 1) / 2) * GRID_SP
		local offZ = (row - 1) * GRID_SP
		return center + Vector3.new(offX, 0, offZ)
	end

	local function matchesType(typeSet, pt, pd)
		if ctx.petMatchesType then return ctx.petMatchesType(typeSet, pt, pd) end
		return typeSet and typeSet[pt] == true
	end

	ctx.state.elephantStatus = "Idle"

	-- Ringkasan statistik untuk UI Status
	function ctx.getElephantSummary()
		local ok, d = pcall(function() return DataService:GetData() end)
		local inv = ok and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}

		local teamCount = 0
		for _ in pairs(CFG.elephantTeamUuids) do teamCount = teamCount + 1 end

		local typesList = {}
		for k in pairs(CFG.elephantPetTypes) do table.insert(typesList, k) end
		table.sort(typesList)
		local typesStr = #typesList > 0 and table.concat(typesList, ", ") or "None"

		local readyCount, maxKgCount = 0, 0
		local targetW = CFG.elephantTargetWeight or 5.5

		for _, v in pairs(inv) do
			local pt = v.PetType
			if matchesType(CFG.elephantPetTypes, pt, v.PetData) then
				local pd = v.PetData or {}
				local w = pd.BaseWeight or 0
				if not pd.IsFavorite then
					if w < targetW then readyCount = readyCount + 1 else maxKgCount = maxKgCount + 1 end
				end
			end
		end

		return {
			status = CFG.elephantEnabled and "ACTIVE" or "STOPPED",
			team = string.format("%d pets", teamCount),
			types = typesStr,
			ready = string.format("%d pets", readyCount),
			maxKg = string.format("%d pets", maxKgCount),
			maxTarget = string.format("%d pets", CFG.elephantMaxPets or 2),
			targetWeight = string.format("%.2f KG", targetW),
		}
	end

	local function checkElephant()
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d then return end
		local petsData = d.PetsData
		if not petsData then return end
		local eq = petsData.EquippedPets or {}
		local inv = petsData.PetInventory and petsData.PetInventory.Data or {}

		local teamSet = CFG.elephantTeamUuids or {}
		local targetTypes = CFG.elephantPetTypes or {}
		local targetW = CFG.elephantTargetWeight or 5.5
		local maxPets = CFG.elephantMaxPets or 2

		-- Lacak equip lokal (kebal delay replikasi)
		local localEq, localEqCount = {}, 0
		for _, uuid in ipairs(eq) do localEq[uuid] = true; localEqCount = localEqCount + 1 end

		-- A. FIRST RUN: cabut semua pet aktif
		if ctx.state.elephantFirstRun then
			ctx.state.elephantFirstRun = false
			if #eq > 0 then
				ctx.state.elephantStatus = "Resetting garden..."
				for _, uuid in ipairs(eq) do
					pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
					localEq[uuid] = nil; localEqCount = localEqCount - 1
					task.wait(0.25)
				end
			end
		end

		-- B. PERSISTENSI TEAM: pasang lagi pet team yang kecabut
		for uuid, _ in pairs(teamSet) do
			if not localEq[uuid] then
				ctx.state.elephantStatus = "Re-equipping team..."
				local pos = getPos(uuid)
				if pos then
					pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
					localEq[uuid] = true; localEqCount = localEqCount + 1
					task.wait(0.3)
				end
			end
		end

		-- C. KLASIFIKASI pet target yang di-equip (by BaseWeight)
		local currentGrowing = {}  -- weight < target
		local finishedMax = {}     -- weight >= target
		local otherEquipped = {}
		for uuid, _ in pairs(localEq) do
			if not teamSet[uuid] then
				local pInfo = inv[uuid]
				local pt = pInfo and pInfo.PetType
				local pd = pInfo and pInfo.PetData or {}
				local w = pd.BaseWeight or 0
				if matchesType(targetTypes, pt, pd) then
					if w < targetW then
						table.insert(currentGrowing, uuid)
						-- catat waktu mulai growing (buat Duration di webhook per-pet)
						ctx.state.elephantStartTime = ctx.state.elephantStartTime or {}
						if not ctx.state.elephantStartTime[uuid] then
							ctx.state.elephantStartTime[uuid] = os.time()
						end
					else table.insert(finishedMax, uuid) end
				else
					table.insert(otherEquipped, uuid)
				end
			end
		end

		-- D. LEPAS pet yang sudah MAX KG (+ webhook agregat + kartu per-pet)
		for _, uuid in ipairs(finishedMax) do
			local pInfo = inv[uuid]
			local pd = pInfo and pInfo.PetData or {}
			local pt = pInfo and pInfo.PetType or "?"
			local w = pd.BaseWeight or 0
			-- Durasi: dari mulai growing sampai sekarang; nil kalau start ga kecatat (mis. reload)
			local duration
			if ctx.state.elephantStartTime and ctx.state.elephantStartTime[uuid] then
				duration = os.time() - ctx.state.elephantStartTime[uuid]
				ctx.state.elephantStartTime[uuid] = nil
			end
			pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
			localEq[uuid] = nil; localEqCount = localEqCount - 1
			if ctx.webhookElephant then
				if ctx.webhookElephant.onFinished then
					pcall(function() ctx.webhookElephant.onFinished(ctx, pt, w) end)
				end
				if ctx.webhookElephant.sendFinished then
					pcall(function() ctx.webhookElephant.sendFinished(ctx, pt, w, pd.MutationType, pd.Level or 0, duration) end)
				end
			end
			task.wait(0.25)
		end

		-- E. TAMBAH pet baru dari inventory (BaseWeight terendah dulu)
		local needed = maxPets - #currentGrowing
		if needed > 0 then
			local pool = {}
			for uuid, v in pairs(inv) do
				local pt = v.PetType
				local pd = v.PetData or {}
				local w = pd.BaseWeight or 0
				if not localEq[uuid] and matchesType(targetTypes, pt, pd) and w < targetW and not pd.IsFavorite then
					table.insert(pool, { uuid = uuid, weight = w })
				end
			end
			table.sort(pool, function(a, b) return a.weight < b.weight end)

			for i = 1, math.min(needed, #pool) do
				local target = pool[i]
				local pos = getPos(target.uuid)
				if pos then
					if localEqCount >= 15 and #otherEquipped > 0 then
						local toRemove = table.remove(otherEquipped)
						pcall(function() PetsService:FireServer("UnequipPet", toRemove) end)
						localEq[toRemove] = nil; localEqCount = localEqCount - 1
						task.wait(0.25)
					end
					pcall(function() PetsService:FireServer("EquipPet", target.uuid, CFrame.new(pos)) end)
					localEq[target.uuid] = true; localEqCount = localEqCount + 1
					table.insert(currentGrowing, target.uuid)
					ctx.state.elephantStartTime = ctx.state.elephantStartTime or {}
					ctx.state.elephantStartTime[target.uuid] = os.time()
					task.wait(0.3)
				end
			end
		end

		ctx.state.elephantStatus = string.format("Elephant: %d/%d active", #currentGrowing, maxPets)
	end

	local function elephantLoop()
		ctx.state.elephantId = (ctx.state.elephantId or 0) + 1
		local myId = ctx.state.elephantId
		ctx.elevate()
		ctx.state.elephantFirstRun = true

		-- Webhook saat enable (sama seperti leveling: cukup URL keisi, sender cek URL sendiri)
		task.spawn(function()
			if ctx.webhookElephant then
				pcall(function() ctx.webhookElephant.sendEnabled(ctx) end)
			end
		end)

		while CFG.elephantEnabled and ctx.alive() and ctx.state.elephantId == myId do
			pcall(checkElephant)
			task.wait(3.0)
		end
		ctx.state.elephantStatus = "Idle"
	end

	function ctx.startElephant()
		if ctx.cancelClearGarden then ctx.cancelClearGarden() end -- batalkan clear tertunda dari fitur lain
		ctx.state.elephantCfgOverride = nil -- webhook elephant pakai config standalone (bukan Growth)
		ctx.state.elephantWebhookPost = nil -- standalone: edit pesan (bukan POST tiap selesai)
		task.spawn(elephantLoop)
	end

	-- Matikan: hentikan loop lalu CABUT SEMUA pet dari garden sampai kosong total.
	function ctx.stopElephant()
		ctx.state.elephantId = (ctx.state.elephantId or 0) + 1 -- invalidate loop yang jalan
		task.spawn(function()
			ctx.state.elephantStatus = "Clearing garden..."
			task.wait(0.3)
			for _ = 1, 30 do
				local ok, d = pcall(function() return DataService:GetData() end)
				local eq = ok and d and d.PetsData and d.PetsData.EquippedPets or {}
				if #eq == 0 then break end
				for _, uuid in ipairs(eq) do
					pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
					task.wait(0.2)
				end
				task.wait(0.4)
			end
			ctx.state.elephantStatus = "Idle (garden empty)"
		end)
	end
end
]=],
	["modules/elephant/automation_elephant_v2.lua"] = [=[
--[[ elephant_v2.lua — Automation Elephant V2.
     Sama seperti V1 (equip team + rotasi pet target by BaseWeight, lepas pas
     capai Target Weight, jaga Max Target Pets aktif), TAPI plus swap GAJAH:
     gajah normalnya di luar garden; begitu ada target >= Trigger Level (mis. 40)
     gajah di-swap MASUK nuker 1 pet Switch (tanpa delay), keluar lagi pas ga ada
     target di level itu. Leveling target dilakukan PNP (jalan barengan).

     2 loop terpisah:
       - rotationLoop: pelan (~1.5s) — jaga team + rotasi target (ala V1).
       - swapLoop: cepat (0.1s) — cuma swap gajah <-> switch. ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local PetsService = ctx.deps.PetsService
	local CFG = ctx.CFG
	local LP  = ctx.LP
	local RS  = game:GetService("ReplicatedStorage")

	local function farmCenter()
		local ok, GetFarm = pcall(function() return require(RS.Modules.GetFarm) end)
		local farm = ok and GetFarm and GetFarm(LP)
		local pa = farm and farm:FindFirstChild("PetArea")
		if pa then return pa.Position end
		local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
		return hrp and hrp.Position or nil
	end
	local slotOf, nextSlot = {}, 0
	local function getPos(uuid)
		if not slotOf[uuid] then slotOf[uuid] = nextSlot; nextSlot = nextSlot + 1 end
		local c = farmCenter(); if not c then return nil end
		local i = slotOf[uuid]
		return c + Vector3.new(((i % 6) - 2.5) * 3, 0, (math.floor(i / 6) - 1) * 3)
	end

	local function snapshot()
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d or not d.PetsData then return nil, nil end
		return d.PetsData.EquippedPets or {}, (d.PetsData.PetInventory and d.PetsData.PetInventory.Data) or {}
	end
	local function isEquipped(eq, uuid)
		if not uuid or uuid == "" or not eq then return false end
		for _, u in ipairs(eq) do if u == uuid then return true end end
		return false
	end

	local function matchesType(typeSet, pt, pd)
		if ctx.petMatchesType then return ctx.petMatchesType(typeSet, pt, pd) end
		return typeSet and typeSet[pt] == true
	end

	----------------------------------------------------- STATUS
	function ctx.getElephantV2Summary()
		local _, inv = snapshot()
		inv = inv or {}
		local teamCount = 0
		for _ in pairs(CFG.elephantV2Team or {}) do teamCount = teamCount + 1 end
		local typesList = {}
		for k in pairs(CFG.elephantV2Types or {}) do table.insert(typesList, k) end
		table.sort(typesList)
		local targetW = CFG.elephantV2Weight or 5.5
		local readyCount, maxKgCount = 0, 0
		for _, v in pairs(inv) do
			if matchesType(CFG.elephantV2Types, v.PetType, v.PetData) then
				local pd = v.PetData or {}
				if not pd.IsFavorite then
					if (pd.BaseWeight or 0) < targetW then readyCount = readyCount + 1 else maxKgCount = maxKgCount + 1 end
				end
			end
		end
		return {
			status = CFG.elephantV2Enabled and "ACTIVE" or "STOPPED",
			info   = ctx.state.elephantV2Status or "Idle",
			team   = string.format("%d pets", teamCount),
			types  = #typesList > 0 and table.concat(typesList, ", ") or "None",
			ready  = string.format("%d pets", readyCount),
			maxKg  = string.format("%d pets", maxKgCount),
			maxTarget = string.format("%d pets", CFG.elephantV2MaxPets or 3),
			targetWeight = string.format("%.2f KG", targetW),
			gajah  = ctx.elephantV2Label(CFG.elephantV2Gajah),
			switch = ctx.elephantV2Label(CFG.elephantV2Switch),
			level  = tostring(CFG.elephantV2Level or 40),
		}
	end

	----------------------------------------------------- ROTASI (ala V1)
	-- absentSince[uuid] = os.clock() sejak pet TERAKHIR kali kebaca ga ke-equip. Dipakai di
	-- reserved mode: elephant cuma re-equip pet yg absent >= 5 detik (biar ga ngerebut PnP yg
	-- cuma unequip sebentar pas pickup). Reset ke nil begitu pet kebaca ke-equip lagi.
	local absentSince = {}
	local ABSENT_GRACE = 5 -- detik
	local function absentLongEnough(uuid)
		absentSince[uuid] = absentSince[uuid] or os.clock()
		return (os.clock() - absentSince[uuid]) >= ABSENT_GRACE
	end
	local function checkRotation()
		local eq, inv = snapshot()
		if not eq then return end
		local teamSet = CFG.elephantV2Team or {}
		local targetTypes = CFG.elephantV2Types or {}
		local targetW = CFG.elephantV2Weight or 5.5
		local maxPets = CFG.elephantV2MaxPets or 3
		local gajah, switch = CFG.elephantV2Gajah, CFG.elephantV2Switch
		local gajahIn = isEquipped(eq, gajah)

		-- A. FIRST RUN (pas enable): reset garden dulu — TAPI di mode reserved (switch kosong)
		--    reset-all DILEWATI biar pet PnP yg lagi jalan ga ke-wipe. Langsung lanjut naruh team.
		local reserved = (switch == nil or switch == "")
		if ctx.state.elephantV2FirstRun then
			ctx.state.elephantV2FirstRun = false
			if not reserved and #eq > 0 then
				ctx.state.elephantV2Status = "Reset garden (removing all pets)..."
				for _, uuid in ipairs(eq) do
					pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
					task.wait(0.2)
				end
				return
			end
			-- reserved: jangan reset, lanjut ke penempatan team di bawah
		end

		local localEq, localEqCount = {}, 0
		for _, uuid in ipairs(eq) do localEq[uuid] = true; localEqCount = localEqCount + 1 end
		-- pet yg lagi ke-equip -> reset timer absent-nya (dia lagi ada)
		for uuid in pairs(localEq) do absentSince[uuid] = nil end

		-- B. PERSISTENSI TEAM: pasang lagi team yg kecabut (skip gajah; skip switch pas gajah in).
		--    RESERVED mode: cuma re-equip kalau udah absent >= 5s -> ga ngerebut PnP yg unequip
		--    sebentar pas pickup (PnP bakal balikin sendiri jauh sebelum 5s).
		for uuid in pairs(teamSet) do
			if uuid ~= gajah and not (gajahIn and uuid == switch) then
				if not localEq[uuid] then
					if (not reserved) or absentLongEnough(uuid) then
						local pos = getPos(uuid)
						if pos then
							pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
							localEq[uuid] = true; localEqCount = localEqCount + 1
							absentSince[uuid] = nil
							task.wait(0.25)
						end
					end
				end
			end
		end

		-- C. KLASIFIKASI target equipped by BaseWeight (jangan sentuh team & gajah)
		local currentGrowing, finishedMax = {}, {}
		for uuid in pairs(localEq) do
			if not teamSet[uuid] and uuid ~= gajah then
				local pInfo = inv[uuid]
				local pd = pInfo and pInfo.PetData or {}
				local pt = pInfo and pInfo.PetType
				if pt and matchesType(targetTypes, pt, pd) then
					if (pd.BaseWeight or 0) < targetW then table.insert(currentGrowing, uuid)
					else table.insert(finishedMax, uuid) end
				end
			end
		end

		-- D. LEPAS target yang sudah MAX KG
		for _, uuid in ipairs(finishedMax) do
			pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
			localEq[uuid] = nil; localEqCount = localEqCount - 1
			task.wait(0.2)
		end

		-- E. TAMBAH target baru (BaseWeight terendah dulu) sampai maxPets
		local needed = maxPets - #currentGrowing
		if needed > 0 then
			local pool = {}
			for uuid, v in pairs(inv) do
				local pd = v.PetData or {}
				if not localEq[uuid] and matchesType(targetTypes, v.PetType, pd) and (pd.BaseWeight or 0) < targetW and not pd.IsFavorite then
					table.insert(pool, { uuid = uuid, weight = pd.BaseWeight or 0 })
				end
			end
			table.sort(pool, function(a, b) return a.weight < b.weight end)
			for i = 1, math.min(needed, #pool) do
				local uuid = pool[i].uuid
				-- RESERVED: skip pet yg baru aja absent (<5s) -> kemungkinan cuma lagi di-PnP
				-- (unequip sebentar). Cuma tambahin yg beneran nganggur/absent lama.
				if (not reserved) or absentLongEnough(uuid) then
					local pos = getPos(uuid)
					if pos then
						pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
						localEq[uuid] = true; localEqCount = localEqCount + 1
						absentSince[uuid] = nil
						table.insert(currentGrowing, uuid)
						task.wait(0.3)
					end
				end
			end
		end
	end

	----------------------------------------------------- SWAP GAJAH (cepat)
	-- Cuma trigger kalau ada target yang LAGI KE-EQUIP, masih growing (weight < target),
	-- dan level >= ambang. Pet maxed / yang cuma nganggur di inventory TIDAK dihitung.
	local function anyTargetReady(eq, inv)
		local types = CFG.elephantV2Types or {}
		local thr = CFG.elephantV2Level or 40
		local targetW = CFG.elephantV2Weight or 5.5
		for _, u in ipairs(eq) do
			local v = inv[u]
			if v and matchesType(types, v.PetType, v.PetData) then
				local pd = v.PetData or {}
				if (pd.BaseWeight or 0) < targetW and (pd.Level or 0) >= thr then return true end
			end
		end
		return false
	end
	local function eqCount(eq) return eq and #eq or 0 end

	-- Masukin GAJAH dengan AMAN: gajah HANYA boleh nuker SWITCH, atau pakai slot yang
	-- beneran kosong. Kalau Switch lagi ga ke-equip DAN garden penuh -> SKIP (biar
	-- ga bump pet lain sembarangan). Ini kunci: slot bebas WAJIB dari switch dulu.
	local function swapInGajah(gajah, switch)
		local eq = snapshot()
		if isEquipped(eq, gajah) then return true end
		local pos = farmCenter()
		if isEquipped(eq, switch) then
			-- cabut switch, TUNGGU beneran kecabut (slot bebas), baru masukin gajah
			pcall(function() PetsService:FireServer("UnequipPet", switch) end)
			for _ = 1, 8 do
				task.wait(0.04)
				eq = snapshot()
				if not isEquipped(eq, switch) then break end
			end
			if isEquipped(eq, switch) then return false end -- gagal cabut switch, jangan equip
		elseif eqCount(eq) >= 8 then
			return false -- switch ga ada & garden penuh -> jangan bump pet lain
		end
		-- slot dijamin ada (dari switch / emang kosong)
		if pos then pcall(function() PetsService:FireServer("EquipPet", gajah, CFrame.new(pos)) end) end
		for _ = 1, 3 do task.wait(0.06); if isEquipped(snapshot(), gajah) then return true end end
		return false
	end

	-- Keluarin GAJAH: cabut gajah, balikin SWITCH ke slot yang bebas.
	local function swapOutGajah(gajah, switch)
		local eq = snapshot()
		if not isEquipped(eq, gajah) then return true end
		local pos = farmCenter()
		pcall(function() PetsService:FireServer("UnequipPet", gajah) end)
		for _ = 1, 8 do
			task.wait(0.04)
			eq = snapshot()
			if not isEquipped(eq, gajah) then break end
		end
		-- reserved mode (switch kosong): slot dibiarin kosong, JANGAN equip apa2 (biar PnP aman)
		if switch and switch ~= "" and pos then pcall(function() PetsService:FireServer("EquipPet", switch, CFrame.new(pos)) end) end
		return true
	end

	-- Cari 1 pet target yang lagi ke-equip, tipe cocok, weight < target, level >= ambang.
	-- Return uuid + BaseWeight-nya. Dipakai buat mode reserved (boost by 0.1kg).
	local function getReadyTarget(eq, inv)
		local types = CFG.elephantV2Types or {}
		local thr = CFG.elephantV2Level or 40
		local targetW = CFG.elephantV2Weight or 5.5
		for _, u in ipairs(eq) do
			local v = inv[u]
			if v and matchesType(types, v.PetType, v.PetData) then
				local pd = v.PetData or {}
				if (pd.BaseWeight or 0) < targetW and (pd.Level or 0) >= thr then return u, (pd.BaseWeight or 0) end
			end
		end
		return nil
	end
	local function baseWOf(inv, uuid)
		local v = inv and inv[uuid]; local pd = v and v.PetData
		return pd and (pd.BaseWeight or 0) or nil
	end

	local function rotationLoop(myId)
		while CFG.elephantV2Enabled and ctx.alive() and ctx.state.elephantV2Id == myId do
			-- Rotasi TETAP jalan (naruh team + rotasi target). Yang dimatiin cuma reset-all pas
			-- reserved (di checkRotation) biar pet PnP ga ke-wipe.
			pcall(checkRotation)
			task.wait(1.5)
		end
	end

	local function swapLoop(myId)
		while CFG.elephantV2Enabled and ctx.alive() and ctx.state.elephantV2Id == myId do
			local gajah, switch = CFG.elephantV2Gajah, CFG.elephantV2Switch
			local reserved = (switch == nil or switch == "")
			if gajah == "" or gajah == nil then
				ctx.state.elephantV2Status = "Select the Elephant first"
				task.wait(1)
			else
				local eq, inv = snapshot()
				if eq then
					local gajahIn = isEquipped(eq, gajah)
					if reserved then
						-- ===== MODE RESERVED: gajah masuk pas ada target lvl 40, keluar pas target +0.1kg =====
						local tUuid = getReadyTarget(eq, inv)
						if not tUuid then
							if gajahIn then
								swapOutGajah(gajah, switch)
								ctx.state.elephantV2TargetUuid = nil
								ctx.state.elephantV2Status = "Standby (no lvl " .. tostring(CFG.elephantV2Level or 40) .. " target)"
							else
								ctx.state.elephantV2Status = "Standby (waiting for a lvl " .. tostring(CFG.elephantV2Level or 40) .. " target)"
							end
						else
							if not gajahIn then
								-- masuk pakai slot kosong yang kamu reserve; catat berat target saat masuk
								if swapInGajah(gajah, switch) then
									ctx.state.elephantV2TargetUuid = tUuid
									ctx.state.elephantV2TargetW0 = baseWOf(inv, tUuid)
									ctx.state.elephantV2Status = "Elephant IN (boosting target)"
								end
							else
								-- gajah in: cek target yg ditrack udah naik 0.1kg? kalau ya -> keluar
								local trackU = ctx.state.elephantV2TargetUuid
								local w0 = ctx.state.elephantV2TargetW0
								local wc = trackU and baseWOf(inv, trackU) or nil
								if (not trackU) or (not wc) or (w0 and wc >= w0 + 0.1) then
									swapOutGajah(gajah, switch)
									ctx.state.elephantV2TargetUuid = nil
									ctx.state.elephantV2Status = "Elephant out (target +0.1kg)"
								else
									ctx.state.elephantV2Status = ("Boost... (+%.2f/0.10 kg)"):format(math.max(0, wc - (w0 or wc)))
								end
							end
						end
					else
						-- ===== MODE NORMAL (pakai switch): perilaku lama =====
						local ready = anyTargetReady(eq, inv)
						if ready and not gajahIn then
							swapInGajah(gajah, switch)
							ctx.state.elephantV2Status = "Elephant IN (target lvl " .. tostring(CFG.elephantV2Level or 40) .. ")"
						elseif not ready and gajahIn then
							swapOutGajah(gajah, switch)
							ctx.state.elephantV2Status = "Standby (elephant out)"
						else
							ctx.state.elephantV2Status = gajahIn and "Elephant active" or "Standby"
						end
					end
				end
				task.wait(CFG.elephantV2Interval or 0.1)
			end
		end
	end

	function ctx.startElephantV2()
		ctx.state.elephantV2Id = (ctx.state.elephantV2Id or 0) + 1
		local myId = ctx.state.elephantV2Id
		ctx.state.elephantV2FirstRun = true -- pas enable: reset garden dulu (cabut semua)
		ctx.elevate()
		task.spawn(function() rotationLoop(myId) end)
		task.spawn(function() swapLoop(myId) end)
	end
	function ctx.stopElephantV2()
		ctx.state.elephantV2Id = (ctx.state.elephantV2Id or 0) + 1
		ctx.state.elephantV2FirstRun = false
		ctx.state.elephantV2TargetUuid = nil
		local switch = CFG.elephantV2Switch
		local reserved = (switch == nil or switch == "")
		if reserved then
			-- MODE RESERVED: CUMA cabut gajah, JANGAN sentuh pet lain (PnP tetep aman jalan)
			ctx.state.elephantV2Status = "Removing elephant..."
			task.spawn(function()
				local gajah = CFG.elephantV2Gajah
				for _ = 1, 5 do
					local eq = snapshot()
					if not eq or not isEquipped(eq, gajah) then break end
					pcall(function() PetsService:FireServer("UnequipPet", gajah) end)
					task.wait(0.12)
				end
				ctx.state.elephantV2Status = "Idle (elephant out, PnP keeps running)"
			end)
			return
		end
		ctx.state.elephantV2Status = "Removing all pets (clearing garden)..."
		-- Cabut SEMUA pet aktif di garden sampai bener2 bersih (multi-pass, kebal delay replikasi)
		task.spawn(function()
			for _ = 1, 5 do
				local eq = snapshot()
				if not eq or #eq == 0 then break end
				for _, uuid in ipairs(eq) do
					pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
					task.wait(0.12)
				end
				task.wait(0.2)
			end
			ctx.state.elephantV2Status = "Idle (garden clear)"
		end)
	end

	----------------------------------------------------- UI helpers
	local function petLabel(uuid)
		if not uuid or uuid == "" then return "Select" end
		local _, inv = snapshot()
		local v = inv and inv[uuid]
		if not v then return "#" .. tostring(uuid):sub(2, 5) end
		local pd = v.PetData or {}
		local mut = pd.MutationType
		local mutName = (mut and ctx.reg and ctx.reg.mutDisplay) and ctx.reg.mutDisplay(mut) or mut
		local pre = (mut and mut ~= "" and mut ~= "Normal") and (tostring(mutName) .. " ") or ""
		return ("%s%s | Age %s | #%s"):format(pre, v.PetType or "?", tostring(pd.Level or 0), tostring(uuid):sub(2, 5))
	end
	ctx.elephantV2Label = petLabel

	function ctx.elephantV2GajahOptions()
		local out = { { name = "", display = "Clear" } }
		for _, o in ipairs(ctx.inventoryPetOptions and ctx.inventoryPetOptions() or {}) do
			out[#out + 1] = { name = o.value, display = o.display }
		end
		return out
	end
	function ctx.elephantV2SwitchOptions()
		-- Opsi Kosongkan di paling atas (buat mode reserved: slot dibiarin kosong).
		-- Tampilin SEMUA pet inventory (bukan cuma team) biar pilihan selalu keliatan.
		local out = { { name = "", display = "Clear (reserved slot)" } }
		for _, o in ipairs(ctx.inventoryPetOptions and ctx.inventoryPetOptions() or {}) do
			out[#out + 1] = { name = o.value, display = o.display }
		end
		return out
	end
end
]=],
	["modules/elephant/webhook.lua"] = [=[
--[[ webhook/elephant.lua — Discord webhook untuk Automation Elephant.
     Konsep:
       - sendEnabled: kirim 1 pesan (Boosting Statistics KOSONG), tangkap message id.
       - onFinished:  tiap pet target selesai (>= max KG), tambah ke tally lalu
                      EDIT pesan yang sama (boosting stats keisi bertahap).
     Pakai executor request() langsung (POST ?wait=true buat dapat id, PATCH buat edit). ]]
local HttpService = game:GetService("HttpService")
local elephantWebhook = {}

local USERNAME = "CeszParadise"
local AVATAR = "https://raw.githubusercontent.com/milmscr/opoki/main/tegalan/Logo/logo_icon.png"

local function bracketLabel(w)
	local lo = math.floor(w * 10) / 10
	return string.format("%.2f-%.2f KG", lo + 0.01, lo + 0.09)
end

-- Format durasi detik -> "Xh Ym Zs" / "Xm Ys" / "Ys". nil/false -> "-" (start ga kecatat).
local function fmtDuration(sec)
	if sec == nil then return "-" end
	sec = math.max(0, math.floor(tonumber(sec) or 0))
	if sec >= 3600 then return string.format("%dh %dm %ds", math.floor(sec / 3600), math.floor((sec % 3600) / 60), sec % 60) end
	if sec >= 60 then return string.format("%dm %ds", math.floor(sec / 60), sec % 60) end
	return string.format("%ds", sec)
end

local function reqFn()
	return (syn and syn.request) or (http and http.request) or http_request or request
end

-- Sumber config: override Growth (ctx.state.elephantCfgOverride) kalau ada, else CFG standalone.
local function ecfg(ctx)
	local o = ctx.state and ctx.state.elephantCfgOverride
	if o then return o.team or {}, o.types or {}, o.weight or 5.5 end
	local CFG = ctx.CFG
	return CFG.elephantTeamUuids or {}, CFG.elephantPetTypes or {}, CFG.elephantTargetWeight or 5.5
end

-- Scan inventory live: pisah pet target jadi 'selesai' (>= target KG) dan 'sisa' (< target KG).
-- Yang selesai dikelompokkan per type + bracket berat (byType), plus total maxCount.
-- Sumber angka Boosting Statistics & Pets at Max KG = SEMUA pet target yang sudah max di data,
-- bukan cuma yang selesai selama sesi ini (tahan reload / re-enable).
local function scanTargets(ctx)
	local ok, d = pcall(function() return ctx.deps.DataService:GetData() end)
	local inv = ok and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}
	local _, tt, tw = ecfg(ctx)
	local byType, maxCount, remains = {}, 0, 0
	for _, v in pairs(inv) do
		local match = v.PetType and ((ctx.petMatchesType and ctx.petMatchesType(tt, v.PetType, v.PetData)) or tt[v.PetType])
		if match and not (v.PetData or {}).IsFavorite then
			local w = (v.PetData or {}).BaseWeight or 0
			if w < tw then
				remains = remains + 1
			else
				maxCount = maxCount + 1
				local bt = byType[v.PetType]
				if not bt then bt = { total = 0, brackets = {}, order = {} }; byType[v.PetType] = bt end
				bt.total = bt.total + 1
				local lbl = bracketLabel(w)
				if not bt.brackets[lbl] then bt.brackets[lbl] = 0; bt.order[#bt.order + 1] = lbl end
				bt.brackets[lbl] = bt.brackets[lbl] + 1
			end
		end
	end
	return byType, maxCount, remains
end

local function buildPayload(ctx)
	local base = ctx.state.elephantBase or {}
	local byType, maxCount, remains = scanTargets(ctx)

	local typeKeys = {}
	for t in pairs(byType) do typeKeys[#typeKeys + 1] = t end
	table.sort(typeKeys)
	local lines = {}
	for _, t in ipairs(typeKeys) do
		local bt = byType[t]
		lines[#lines + 1] = string.format("**%s:** %d", t, bt.total)
		table.sort(bt.order)
		for _, lbl in ipairs(bt.order) do
			lines[#lines + 1] = string.format("\226\128\162 %s (%s): %d", t, lbl, bt.brackets[lbl])
		end
	end
	local boostText = #lines > 0 and table.concat(lines, "\n") or "*Belum ada pet selesai*"

	local desc = string.format(
		"**Profile :**\n> \240\159\145\164 Username : ||%s||\n\n" ..
		"**Teams :**\n> Elephant Team: `%s`\n\n" ..
		"**Target Types :**\n> `%s`\n\n" ..
		"**Boosting Statistics :**\n%s\n\n" ..
		"**Pets at Max KG :** `%d`\n" ..
		"**Remains Queue :** `%d`",
		ctx.LP.Name, base.teamText or "None", base.typesText or "None",
		boostText, maxCount, remains)
	if #desc > 4000 then desc = desc:sub(1, 3980) .. "\n... (truncated)" end

	return {
		username = USERNAME,
		avatar_url = AVATAR,
		embeds = {
			{
				title = "\240\159\147\138 Growth \226\128\162 Elephant Statistics",
				color = 3066993,
				description = desc,
				footer = { text = os.date("%B %d | %I:%M %p"), icon_url = "https://raw.githubusercontent.com/milmscr/opoki/main/tegalan/Logo/logo_icon.png" },
			}
		}
	}
end

-- Kirim saat enable: reset tally, kirim pesan (boosting kosong), simpan message id.
function elephantWebhook.sendEnabled(ctx)
	local CFG = ctx.CFG
	if not CFG.webhookUrl or CFG.webhookUrl == "" then return end

	-- base info (team + target types)
	local ok, d = pcall(function() return ctx.deps.DataService:GetData() end)
	local inv = ok and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}
	local teamSet, typesSet = ecfg(ctx)
	local teamCount, teamOrder = {}, {}
	for uuid in pairs(teamSet) do
		local v = inv[uuid]
		if v then
			local pt = v.PetType or "?"
			local mut = v.PetData and v.PetData.MutationType
			local mutName = (mut and ctx.reg and ctx.reg.mutDisplay) and ctx.reg.mutDisplay(mut) or mut
			local disp = (mut and mut ~= "" and mut ~= "Normal") and (tostring(mutName) .. " " .. pt) or pt
			if not teamCount[disp] then teamCount[disp] = 0; teamOrder[#teamOrder + 1] = disp end
			teamCount[disp] = teamCount[disp] + 1
		end
	end
	table.sort(teamOrder)
	local teamParts = {}
	for _, disp in ipairs(teamOrder) do teamParts[#teamParts + 1] = teamCount[disp] .. " " .. disp end

	local typesList = {}
	for t in pairs(typesSet) do typesList[#typesList + 1] = t end
	table.sort(typesList)

	ctx.state.elephantBase = {
		teamText = #teamParts > 0 and table.concat(teamParts, ", ") or "None",
		typesText = #typesList > 0 and table.concat(typesList, ", ") or "None",
	}
	ctx.state.elephantTally = { byType = {}, maxCount = 0 }
	ctx.state.elephantMsgId = nil

	-- POST ?wait=true buat dapat message id
	local f = reqFn()
	if not f then return end
	local url = CFG.webhookUrl
	local sep = url:find("?", 1, true) and "&" or "?"
	local body = HttpService:JSONEncode(buildPayload(ctx))
	local okReq, res = pcall(function()
		return f({
			Url = url .. sep .. "wait=true", Method = "POST",
			Headers = { ["Content-Type"] = "application/json" }, Body = body,
		})
	end)
	if okReq and res and res.Body then
		local okj, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
		if okj and type(data) == "table" and data.id then
			ctx.state.elephantMsgId = tostring(data.id)
		end
	end
end

-- Tiap pet target selesai (>= max KG): kirim/EDIT pesan. Angka dihitung live dari
-- data di buildPayload (scanTargets), jadi tidak perlu tally manual lagi.
function elephantWebhook.onFinished(ctx, petType, weight)
	local CFG = ctx.CFG
	if not CFG.webhookUrl or CFG.webhookUrl == "" then return end

	-- Mode POST (Growth: kirim pesan baru tiap pet selesai) ATAU edit pesan (standalone).
	local f = reqFn()
	if not f then return end
	local body = HttpService:JSONEncode(buildPayload(ctx))
	local postMode = ctx.state and ctx.state.elephantWebhookPost
	-- Request HTTP di thread terpisah (non-blocking) biar ga nge-freeze loop automation
	task.spawn(function()
		if ctx.state.elephantMsgId and not postMode then
			pcall(function()
				f({
					Url = CFG.webhookUrl .. "/messages/" .. ctx.state.elephantMsgId, Method = "PATCH",
					Headers = { ["Content-Type"] = "application/json" }, Body = body,
				})
			end)
		elseif ctx.sendWebhook then
			pcall(function() ctx.sendWebhook(CFG.webhookUrl, HttpService:JSONDecode(body), ctx) end)
		end
	end)
end

-- Kartu PER-PET saat 1 pet capai Max KG. Dikirim TIAP pet beres (pesan baru),
-- pelengkap statistik agregat. durationSec = nil -> "Duration: -" (start ga kecatat).
function elephantWebhook.sendFinished(ctx, petType, weight, mutation, age, durationSec)
	local CFG = ctx.CFG
	if not CFG.webhookUrl or CFG.webhookUrl == "" then return end
	local mutDisplay = (ctx.reg and ctx.reg.mutDisplay and ctx.reg.mutDisplay(mutation)) or mutation or "None"
	local _, _, remains = scanTargets(ctx)

	local payload = {
		username = USERNAME,
		avatar_url = AVATAR,
		embeds = {
			{
				title = "\240\159\144\152 Growth \226\128\162 Elephant", -- 🐘
				color = 3066993, -- Green
				fields = {
					{
						name = "Profile :",
						value = string.format("> Username : ||%s||", ctx.LP.Name),
						inline = false
					},
					{
						name = "Max KG Reached",
						value = string.format(
							"> Pet Type: `%s`\n" ..
							"> Mutation: `%s`\n" ..
							"> Weight: `%.2f KG`\n" ..
							"> Age: `%s`\n" ..
							"> Duration: `%s`\n" ..
							"> Remains Queue: `%s`",
							tostring(petType or "?"),
							tostring(mutDisplay),
							tonumber(weight) or 0,
							tostring(age or "-"),
							fmtDuration(durationSec),
							tostring(remains)
						),
						inline = false
					}
				},
				footer = {
					text = os.date("%B %d | %I:%M %p"),
					icon_url = "https://raw.githubusercontent.com/milmscr/opoki/main/tegalan/Logo/logo_icon.png"
				}
			}
		}
	}
	if ctx.sendWebhook then ctx.sendWebhook(CFG.webhookUrl, payload, ctx) end
end

return elephantWebhook
]=],
	["modules/event/automation_beanstalk_hop.lua"] = [=[
--[[ automation_beanstalk_hop.lua — Auto Server Hop (Beanstalk).
     Tujuan: nyari server yg beanstalk growth-nya BELUM 900 biar bisa terus kontribusi & dapat reward.
     BATASAN: growth = state runtime server, API daftar server Roblox cuma kasih player count,
     JADI ga bisa tau growth sebelum join. Cara kerja: JOIN -> cek growth -> kalau >=900 (penuh/CD)
     hop ke server lain; kalau < 900 STAY & farm (biar toggle plant/collect/submit/claim yg kerja).
     Begitu growth server ini nyampe 900, hop lagi. Tanpa batas hop (sampai nemu yg < 900).

     Teknis: http request (server list) + TeleportToPlaceInstance(jobId) + queueonteleport (re-run hub).
     Config: CFG.beanstalkHopEnabled. Fungsi: ctx.startBeanstalkHop / ctx.stopBeanstalkHop.
]]
return function(ctx)
	local LP  = ctx.LP
	local CFG = ctx.CFG
	local TeleportService = game:GetService("TeleportService")
	local HttpService     = game:GetService("HttpService")
	local function setStatus(s) ctx.setStatus(s) end
	local branch = (getgenv and getgenv().GAG_BRANCH) or _G.GAG_BRANCH or "main"

	-- ref Teleport di-cache biar bypass hook __namecall anti-teleport
	local TeleportFn = TeleportService.Teleport

	-- queue loader hub biar auto jalan lagi abis pindah server (branch dijaga)
	local function queueLoader()
		local q = (syn and syn.queue_on_teleport) or queue_on_teleport
			or (fluxus and fluxus.queue_on_teleport) or (getgenv and getgenv().queue_on_teleport)
		if q then
			local cmd = ('if getgenv then getgenv().GAG_BRANCH=%q end loadstring(game:HttpGet("https://raw.githubusercontent.com/Tirta71/ScriptMarketGAG/%s/GAGSeller/init.lua"))()'):format(branch, branch)
			pcall(function() q(cmd) end)
		end
	end

	local function httpReq()
		return http_request or request or (syn and syn.request) or (http and http.request)
	end

	-- daftar jobId server publik yg masih ada room, exclude server sekarang (max 3 halaman)
	local function fetchServers()
		local req = httpReq(); if not req then return {} end
		local out, cursor = {}, ""
		for _ = 1, 3 do
			local url = ("https://games.roblox.com/v1/games/%d/servers/Public?limit=100&sortOrder=Desc"):format(game.PlaceId)
			if cursor ~= "" then url = url .. "&cursor=" .. cursor end
			local ok, resp = pcall(function() return req({ Url = url, Method = "GET" }) end)
			if not ok or type(resp) ~= "table" or resp.StatusCode ~= 200 then break end
			local ok2, data = pcall(function() return HttpService:JSONDecode(resp.Body) end)
			if not ok2 or type(data) ~= "table" then break end
			for _, s in ipairs(data.data or {}) do
				if s.id ~= game.JobId and (tonumber(s.playing) or 0) < (tonumber(s.maxPlayers) or 0) then
					out[#out + 1] = s.id
				end
			end
			cursor = data.nextPageCursor
			if not cursor or cursor == "" then break end
		end
		return out
	end

	-- pindah ke server lain (acak dari daftar). Fallback: Teleport random kalau daftar kosong/gagal.
	-- Cek CFG.beanstalkHopEnabled di tiap tahap: kalau user matiin di tengah proses (mis. pas
	-- ambil daftar server), langsung batal SEBELUM teleport -> matiin selalu aman & instan.
	local function hop()
		if not CFG.beanstalkHopEnabled then return false end
		queueLoader()
		task.wait(0.4)
		if not CFG.beanstalkHopEnabled then return false end
		local servers = fetchServers()
		if not CFG.beanstalkHopEnabled then return false end
		-- shuffle
		for i = #servers, 2, -1 do local j = math.random(1, i); servers[i], servers[j] = servers[j], servers[i] end
		for _, jobId in ipairs(servers) do
			if not CFG.beanstalkHopEnabled then return false end
			local ok = pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LP) end)
			if ok then return true end
			task.wait(0.3)
		end
		if not CFG.beanstalkHopEnabled then return false end
		-- fallback: server random (bisa kebetulan sama, tapi lebih baik drpd stuck)
		pcall(function() TeleportFn(TeleportService, game.PlaceId, LP) end)
		return true
	end

	-- growth beanstalk sekarang dari billboard: return cur, max (nil kalau ga kebaca)
	local function growth()
		local inter = workspace:FindFirstChild("Interaction")
		local m = inter and inter:FindFirstChild("BeanstalkEventModel")
		if not m then return nil end
		for _, g in ipairs(m:GetDescendants()) do
			if g:IsA("TextLabel") then
				local a, b = g.Text:match("^(%d+)%s*/%s*(%d+)$")
				if a and b then return tonumber(a), tonumber(b) end
			end
		end
		return nil
	end

	local function hopLoop()
		ctx.state.beanHopId = (ctx.state.beanHopId or 0) + 1
		local myId = ctx.state.beanHopId
		ctx.elevate()
		local t0 = os.clock() -- buat timeout nunggu event kebaca
		while CFG.beanstalkHopEnabled and ctx.alive() and ctx.state.beanHopId == myId do
			local cur, max = growth()
			if not cur then
				-- event belum kebaca; kasih grace 40s (nunggu map load) sebelum nyerah & hop
				if os.clock() - t0 > 40 then
					setStatus("Beanstalk Hop: event ga kebaca — cari server lain...")
					hop(); return
				end
				setStatus("Beanstalk Hop: nunggu beanstalk kebaca...")
				task.wait(2)
			elseif cur >= max then
				setStatus(("Beanstalk Hop: server penuh (%d/%d) — cari server baru..."):format(cur, max))
				hop(); return -- instance ini ilang setelah teleport
			else
				-- server bagus: stay, biar automation lain yg farming. Cek berkala sampai 900.
				setStatus(("Beanstalk Hop: server OK (%d/%d) — farming"):format(cur, max))
				t0 = os.clock()
				task.wait(15)
			end
		end
	end

	function ctx.startBeanstalkHop()
		if not CFG.beanstalkHopEnabled then return end
		task.spawn(hopLoop)
	end
	function ctx.stopBeanstalkHop() ctx.state.beanHopId = (ctx.state.beanHopId or 0) + 1 end
end
]=],
	["modules/event/automation_beanstalk.lua"] = [=[
--[[ automation_beanstalk.lua — Automation Beanstalk Event (NPC Jack).
     Beanstalk minta 1 TRAIT tanaman (mis. "Vegetable"), refresh tiap jam. Feed plant
     yang trait-nya cocok -> naikin Beanstalk Growth global (mis. 0/900) & dapat reward.
     Craving DIBACA dari billboard "We need <trait> Plants" (selalu akurat, ga nebak RNG).

     Flow (tiap sub-toggle bisa nyala sendiri, jalan 1 loop):
       Auto Plant   : tanam seed yang trait-nya == craving, sampai target N (input).
       Auto Collect : panen fruit yang trait-nya == craving (ke backpack).
       Auto Submit  : equip tiap produce tool trait==craving -> SubmitHeldPlant.
                      SENGAJA per-plant (bukan SubmitAllPlant) biar crop lain (non-craving,
                      mahal) TIDAK ikut kefeed. Aman.

     Remote:
       Plant_RE:FireServer(pos, seedName)
       GameEvents.Crops.Collect:FireServer({fruitModels})
       GameEvents.Events.BeanstalkEvent.BeanstalkRESubmitHeldPlant:FireServer()
]]
return function(ctx)
	local LP          = ctx.LP
	local CFG         = ctx.CFG
	local RS          = game:GetService("ReplicatedStorage")
	local GE          = RS:WaitForChild("GameEvents")
	local DataService = ctx.deps.DataService
	local function setStatus(s) ctx.setStatus(s) end

	local Plant_RE = GE:WaitForChild("Plant_RE")
	local Collect  = GE:WaitForChild("Crops"):WaitForChild("Collect")
	local BeanEv   = GE:WaitForChild("Events"):WaitForChild("BeanstalkEvent")
	local SubmitHeld = BeanEv:WaitForChild("BeanstalkRESubmitHeldPlant")
	local SubmitAll  = BeanEv:WaitForChild("BeanstalkRESubmitAllPlant")
	local SellInventory = GE:FindFirstChild("Sell_Inventory") -- jual SEMUA isi backpack (NPC Steven)
	local IS; pcall(function() IS = require(RS.Modules.InventoryService) end)
	local function backpackFull()
		if not IS then return false end
		local ok, full = pcall(function() return IS:IsMaxInventory() end)
		return ok and full == true
	end

	local PlantTraits
	pcall(function() PlantTraits = require(RS.Modules.PlantTraitsData) end)
	local ALL_TRAITS = { "Berry", "Flower", "Fruit", "Leafy", "Vegetable", "Woody", "Prickly", "Stalky", "Tropical" }
	pcall(function()
		local cfg = require(RS.Data.Events.BeanstalkEvent.BeanstalkEventConfig)
		if type(cfg.Traits) == "table" and #cfg.Traits > 0 then ALL_TRAITS = cfg.Traits end
	end)

	local function hasTrait(name, trait)
		if not name or name == "" or not trait then return false end
		if PlantTraits and PlantTraits.HasTrait then
			local ok, res = pcall(function() return PlantTraits.HasTrait(name, trait) end)
			if ok then return res == true end
		end
		return false
	end

	----------------------------------------------------------------- craving (baca billboard)
	local function beanModel() return workspace:FindFirstChild("Interaction") and workspace.Interaction:FindFirstChild("BeanstalkEventModel") end
	-- Buang tag rich-text lalu cari trait yang cocok di ALL_TRAITS.
	local function parseTrait(txt)
		if not txt then return nil end
		local clean = txt:gsub("<[^>]->", "")
		for _, tr in ipairs(ALL_TRAITS) do
			if clean:find(tr, 1, true) then return tr end
		end
		return nil
	end
	-- craving trait sekarang (nil kalau event ga aktif / label ga ketemu)
	local function currentCraving()
		local m = beanModel(); if not m then return nil end
		for _, g in ipairs(m:GetDescendants()) do
			if g:IsA("TextLabel") and g.Text:find("need") then
				local tr = parseTrait(g.Text)
				if tr then return tr end
			end
		end
		return nil
	end
	-- progress growth global "X/Y" dari billboard (buat status)
	local function growthText()
		local m = beanModel(); if not m then return nil end
		for _, g in ipairs(m:GetDescendants()) do
			if g:IsA("TextLabel") then
				local a, b = g.Text:match("^(%d+)%s*/%s*(%d+)$")
				if a and b then return a .. "/" .. b end
			end
		end
		return nil
	end
	-- Event aktif = model ada DAN billboard nampilin UI event (craving / growth / decay).
	-- CATATAN: attribute workspace "ActivateBeanstalk" TERNYATA ga reliable (bisa false pas
	-- event jelas jalan), jadi JANGAN dipakai. Billboard = sumber kebenaran.
	-- Beanstalk PENUH (growth mentok a>=b): setor lebih lanjut percuma, tunggu reset.
	-- CATATAN: label "Beanstalk Decays in:" itu timer decay NORMAL yg SELALU muncul selama
	-- event jalan (bukan penanda cooldown), jadi JANGAN dipakai — cukup cek growth mentok.
	local function isDecaying()
		local m = beanModel(); if not m then return false end
		for _, g in ipairs(m:GetDescendants()) do
			if g:IsA("TextLabel") then
				local a, b = g.Text:match("^(%d+)%s*/%s*(%d+)$")
				if a and b and tonumber(a) >= tonumber(b) then return true end
			end
		end
		return false
	end
	local function isActive()
		if beanModel() == nil then return false end
		return currentCraving() ~= nil or growthText() ~= nil or isDecaying()
	end

	----------------------------------------------------------------- seed inventory (per trait)
	local function seedInventory()
		local out = {}
		local ok, d = pcall(function() return DataService:GetData() end)
		if ok and d and type(d.InventoryData) == "table" then
			for _, v in pairs(d.InventoryData) do
				if type(v) == "table" and v.ItemType == "Seed" and v.ItemData then
					local nm = v.ItemData.ItemName
					local q = tonumber(v.ItemData.Quantity) or 0
					if nm then out[nm] = (out[nm] or 0) + q end
				end
			end
		end
		return out
	end

	----------------------------------------------------------------- farm helpers (plant)
	local function myFarm()
		local ok, GetFarm = pcall(function() return require(RS.Modules.GetFarm) end)
		if ok and GetFarm then
			local ok2, f = pcall(function() return GetFarm(LP) end)
			if ok2 then return f end
		end
		return nil
	end
	local function canPlantParts()
		local f = myFarm()
		local imp = f and f:FindFirstChild("Important")
		local pl = imp and imp:FindFirstChild("Plant_Locations")
		local parts = {}
		if pl then for _, p in ipairs(pl:GetChildren()) do if p:IsA("BasePart") then parts[#parts + 1] = p end end end
		return parts
	end
	local function randomPos()
		local parts = canPlantParts()
		if #parts == 0 then return nil end
		local p = parts[math.random(1, #parts)]
		local hx, hz = p.Size.X / 2 - 1, p.Size.Z / 2 - 1
		local x = p.Position.X + (math.random() * 2 - 1) * hx
		local z = p.Position.Z + (math.random() * 2 - 1) * hz
		return Vector3.new(x, p.Position.Y, z)
	end
	-- equip seed tool "<Nama> Seed [Xn]" (server wajib megang pas Plant_RE)
	local function seedBase(t) return t:IsA("Tool") and t.Name:match("^(.-) Seed %[X%d+%]") or nil end
	local function holdingSeed(name)
		local ch = LP.Character
		if ch then for _, t in ipairs(ch:GetChildren()) do if seedBase(t) == name then return true end end end
		return false
	end
	local function equipSeed(name)
		if holdingSeed(name) then return true end
		local bp = LP:FindFirstChild("Backpack")
		local tool
		if bp then for _, t in ipairs(bp:GetChildren()) do if seedBase(t) == name then tool = t; break end end end
		if tool then
			local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
			if hum then pcall(function() hum:EquipTool(tool) end) end
		end
		return holdingSeed(name)
	end

	----------------------------------------------------------------- fruit di farm (collect)
	-- PENTING: cuma sentuh kebun MILIK SENDIRI. Semua garden namanya "Farm", dibedain lewat
	-- Important.Data.Owner. Dulu cuma skip CommunityGarden -> kesapu kebun pemain lain (bug).
	local function myGarden()
		local f = myFarm()            -- via GetFarm(LP), paling akurat
		if f then return f end
		local Farm = workspace:FindFirstChild("Farm"); if not Farm then return nil end
		for _, g in ipairs(Farm:GetChildren()) do
			local d = g:FindFirstChild("Important") and g.Important:FindFirstChild("Data")
			local o = d and d:FindFirstChild("Owner")
			if o and o.Value == LP.Name then return g end
		end
		return nil
	end
	local function myPlantsPhysical()
		local g = myGarden(); local imp = g and g:FindFirstChild("Important")
		return imp and imp:FindFirstChild("Plants_Physical")
	end
	local function eachFruit(fn)
		local pp = myPlantsPhysical(); if not pp then return end
		for _, plant in ipairs(pp:GetChildren()) do
			local fr = plant:FindFirstChild("Fruits")
			if fr then for _, f in ipairs(fr:GetChildren()) do fn(f) end end
		end
	end

	-- iterasi tiap plant (model) yang lagi tumbuh di kebun SENDIRI
	local function eachPlant(fn)
		local pp = myPlantsPhysical(); if not pp then return end
		for _, plant in ipairs(pp:GetChildren()) do
			if plant:IsA("Model") then fn(plant) end
		end
	end
	-- cache nama tanaman -> set trait (biar HasTrait ga dipanggil berulang)
	local nameTraitCache = {}
	local function traitsOf(name)
		local c = nameTraitCache[name]
		if c then return c end
		c = {}
		for _, tr in ipairs(ALL_TRAITS) do if hasTrait(name, tr) then c[tr] = true end end
		nameTraitCache[name] = c
		return c
	end
	-- jumlah plant tumbuh per SEMUA trait (1x pass). return map trait->count
	local function plantedByTrait()
		local counts = {}
		for _, tr in ipairs(ALL_TRAITS) do counts[tr] = 0 end
		eachPlant(function(p)
			for tr in pairs(traitsOf(p.Name)) do counts[tr] = (counts[tr] or 0) + 1 end
		end)
		return counts
	end
	-- jumlah plant 1 trait yang sudah ketanam (+ breakdown per nama)
	local function plantedInfo(trait)
		local total, byName = 0, {}
		eachPlant(function(p)
			if hasTrait(p.Name, trait) then
				total = total + 1
				byName[p.Name] = (byName[p.Name] or 0) + 1
			end
		end)
		return total, byName
	end

	----------------------------------------------------------------- produce tool di backpack (submit)
	-- Tool hasil panen: punya child "Item_String" (nama tanaman), bukan pet (PET_UUID), bukan seed.
	local function produceName(t)
		if not t:IsA("Tool") then return nil end
		if t:GetAttribute("PET_UUID") then return nil end
		if t.Name:match("Seed %[X%d+%]") then return nil end
		local is = t:FindFirstChild("Item_String")
		if is and is.Value ~= "" then return is.Value end
		return nil
	end
	-- daftar produce tool di backpack yang cocok trait
	local function cravingProduceTools(trait)
		local out = {}
		local bp = LP:FindFirstChild("Backpack"); if not bp then return out end
		for _, t in ipairs(bp:GetChildren()) do
			local nm = produceName(t)
			if nm and hasTrait(nm, trait) then out[#out + 1] = t end
		end
		return out
	end

	----------------------------------------------------------------- status summary buat GUI
	function ctx.getBeanstalkSummary()
		local craving = currentCraving()
		local res = { active = isActive(), craving = craving, traits = ALL_TRAITS }
		res.growth = growthText() or "-"
		local ok, d = pcall(function() return DataService:GetData() end)
		res.contributed = (ok and d and d.BeanstalkEvent and d.BeanstalkEvent.EventsContributed) or 0
		res.target = tonumber(CFG.beanstalkPlantCount) or 0
		-- ketanam per SEMUA trait (buat display "Vegetable 50/20, Flower 0/20, ...")
		local counts = plantedByTrait()
		res.perTrait = {}
		for _, tr in ipairs(ALL_TRAITS) do
			res.perTrait[#res.perTrait + 1] = { trait = tr, planted = counts[tr] or 0, target = res.target, craving = (tr == craving) }
		end
		if craving then
			res.ready = #cravingProduceTools(craving)               -- produce craving siap setor
			res.planted = counts[craving] or 0                      -- ketanam trait craving
			local seeds, seedTotal = seedInventory(), 0
			for nm, q in pairs(seeds) do if q > 0 and hasTrait(nm, craving) then seedTotal = seedTotal + q end end
			res.seeds = seedTotal
		else
			res.ready, res.seeds, res.planted = 0, 0, 0
		end
		return res
	end

	----------------------------------------------------------------- aksi tunggal (reusable)
	-- FOKUS 1 TRAIT per panggilan: pilih trait pertama (urutan ALL_TRAITS) yang masih < target
	-- DAN ada seed-nya, tanam persis sampai target (ga lebih). Count dihitung ulang tiap siklus
	-- jadi ga overshoot. return jumlahBaru, namaTrait.
	function ctx.beanstalkPlantOnce(target)
		target = tonumber(target) or 0; if target <= 0 then return 0, nil end
		local counts = plantedByTrait()
		local inv = seedInventory()
		for _, trait in ipairs(ALL_TRAITS) do
			local need = target - (counts[trait] or 0)
			if need > 0 then
				local names = {}
				for nm, q in pairs(inv) do if q > 0 and hasTrait(nm, trait) then names[#names + 1] = nm end end
				table.sort(names)
				if #names > 0 then
					local planted = 0
					for _, name in ipairs(names) do
						while (inv[name] or 0) > 0 and planted < need do
							if not CFG.beanstalkPlantEnabled or not ctx.alive() then return planted, trait end
							if equipSeed(name) then
								local pos = randomPos()
								if pos then
									pcall(function() Plant_RE:FireServer(pos, name) end)
									planted = planted + 1; inv[name] = inv[name] - 1
								else break end
							else break end
							task.wait(tonumber(CFG.beanstalkDelay) or 0.2)
						end
						if planted >= need then break end
					end
					return planted, trait  -- selesai 1 trait dulu, sisanya siklus berikut
				end
			end
		end
		return 0, nil
	end

	-- Panen fruit craving ke backpack. return jumlah dikirim, atau -1 kalau backpack penuh (dijeda).
	function ctx.beanstalkCollectOnce(trait)
		trait = trait or currentCraving(); if not trait then return 0 end
		if backpackFull() then return -1 end   -- penuh: jeda collect (ga spam)
		local batch = {}
		eachFruit(function(f) if hasTrait(f.Name, trait) then batch[#batch + 1] = f end end)
		local n = 0
		for i = 1, #batch, 40 do
			if not ctx.alive() then break end
			local chunk = {}
			for j = i, math.min(i + 39, #batch) do chunk[#chunk + 1] = batch[j] end
			pcall(function() Collect:FireServer(chunk) end)
			n = n + #chunk
			task.wait(0.1)
		end
		return n
	end

	-- Setor SEMUA plant sekaligus (BeanstalkRESubmitAllPlant, 1 call). Server hanya kredit
	-- plant yang sesuai craving. return jumlah produce craving yang ada saat setor (perkiraan).
	function ctx.beanstalkSubmitOnce(trait)
		trait = trait or currentCraving(); if not trait then return 0 end
		local n = #cravingProduceTools(trait)
		if n <= 0 then return 0 end
		pcall(function() SubmitAll:FireServer() end)
		task.wait(0.5)
		return n
	end

	-- Claim reward: tiap RewardPoint yang ProximityPrompt-nya Enabled -> fireproximityprompt.
	-- Itu memicu handler client asli (BeanstalkGrowController) yang FireServer ClaimReward(i)
	-- dengan index BENAR, jadi ga usah nebak index. return jumlah reward yang di-claim.
	local function rewardPrompts()
		local m = beanModel(); if not m then return {} end
		local bs = m:FindFirstChild("BeanStalk2")
		local root = bs and bs:FindFirstChild("Root")
		local rp = root and root:FindFirstChild("RewardPoints")
		local out = {}
		if rp then
			for _, pt in ipairs(rp:GetChildren()) do
				local pp = pt:FindFirstChildWhichIsA("ProximityPrompt", true)
				if pp and pp.Enabled then out[#out + 1] = pp end
			end
		end
		return out
	end
	function ctx.beanstalkClaimOnce()
		if type(fireproximityprompt) ~= "function" then return 0 end
		local prompts = rewardPrompts()
		local n = 0
		for _, pp in ipairs(prompts) do
			if not ctx.alive() then break end
			pcall(function() fireproximityprompt(pp) end)
			n = n + 1
			task.wait(0.2)
		end
		return n
	end

	local function claimLoop()
		ctx.state.beanClaimId = (ctx.state.beanClaimId or 0) + 1
		local myId = ctx.state.beanClaimId
		ctx.elevate()
		while CFG.beanstalkClaimEnabled and ctx.alive() and ctx.state.beanClaimId == myId do
			if isActive() then
				local c = ctx.beanstalkClaimOnce()
				if c > 0 then setStatus(("Beanstalk: claim %d reward"):format(c)) end
			end
			task.wait(3)
		end
	end
	function ctx.startBeanstalkClaim()
		if not CFG.beanstalkClaimEnabled then return end
		task.spawn(claimLoop)
	end
	function ctx.stopBeanstalkClaim() ctx.state.beanClaimId = (ctx.state.beanClaimId or 0) + 1 end

	-- Jual SEMUA isi backpack (recovery pas mentok: backpack penuh trait salah). Return true kalau di-fire.
	function ctx.beanstalkSellAll()
		if not SellInventory then return false end
		pcall(function() SellInventory:FireServer() end)
		return true
	end

	----------------------------------------------------------------- loop utama (1 loop, semua toggle)
	local function anyOn() return CFG.beanstalkPlantEnabled or CFG.beanstalkCollectEnabled or CFG.beanstalkSubmitEnabled or false end
	ctx.beanstalkAnyOn = anyOn

	local function beanstalkLoop()
		ctx.state.beanstalkId = (ctx.state.beanstalkId or 0) + 1
		local myId = ctx.state.beanstalkId
		ctx.elevate()
		while anyOn() and ctx.alive() and ctx.state.beanstalkId == myId do
			if not isActive() then
				setStatus("Beanstalk: event ga aktif, tunggu...")
				task.wait(5)
			else
				-- Auto Plant: top-up SEMUA trait, ga butuh craving (pre-stock).
				if CFG.beanstalkPlantEnabled then
					local p, tr = ctx.beanstalkPlantOnce(CFG.beanstalkPlantCount)
					if p > 0 then setStatus(("Beanstalk: tanam %d %s"):format(p, tr or "")) end
				end
				local trait = currentCraving()
				if not trait then
					if not CFG.beanstalkPlantEnabled then setStatus("Beanstalk: craving ga kebaca, tunggu...") end
					task.wait(3)
				else
					if isDecaying() then
						-- growth penuh: setor ditolak (CD). Cukup nunggu refresh, jangan setor/jual/collect.
						setStatus("Beanstalk: growth penuh (CD) — nunggu refresh")
					else
						-- 1) SUBMIT dulu: kredit produce craving + kosongin slot-nya di backpack.
						if CFG.beanstalkSubmitEnabled then
							local s = ctx.beanstalkSubmitOnce(trait)
							if s > 0 then setStatus(("Beanstalk: setor %d %s"):format(s, trait))
							else setStatus(("Beanstalk: nunggu %s plant (craving)"):format(trait)) end
						end
						-- 2) Backpack MASIH penuh setelah submit = keisi trait salah (clog).
						--    Jual semua biar lega (kalau toggle Auto Sell ON). Produce craving udah
						--    kesetor di langkah 1, jadi yang kejual cuma sisa trait lain.
						local full = backpackFull()
						if full and CFG.beanstalkAutoSellEnabled and #cravingProduceTools(trait) == 0 then
							if ctx.beanstalkSellAll() then
								setStatus("Beanstalk: backpack mentok (trait salah) — jual semua")
								task.wait(1); full = backpackFull()
							end
						end
						-- 3) COLLECT fruit craving (isi backpack buat disetor siklus berikut).
						if CFG.beanstalkCollectEnabled then
							local c = ctx.beanstalkCollectOnce(trait)
							if c > 0 then setStatus(("Beanstalk: panen %d %s"):format(c, trait))
							elseif c < 0 then setStatus("Beanstalk: backpack penuh — collect dijeda"..(CFG.beanstalkAutoSellEnabled and "" or " (nyalain Auto Sell)")) end
						end
					end
					task.wait(math.max(0.5, tonumber(CFG.beanstalkDelay) or 0.5) + 0.5)
				end
			end
		end
	end

	function ctx.startBeanstalk()
		if not anyOn() then return end
		task.spawn(beanstalkLoop)
	end
	function ctx.stopBeanstalk() ctx.state.beanstalkId = (ctx.state.beanstalkId or 0) + 1 end

	----------------------------------------------------------------- Beanstalk Event Shop (auto-buy)
	-- Shop beanstalk = "Goliath's Goods" (Main) + "Goliath's Friends Deals" (Friendship).
	-- Beli: GameEvents.BuyEventShopStock:FireServer(item, shopName). Currency Sheckles.
	local SHOP_LIST = { "Goliath's Goods", "Goliath's Friends Deals" }
	local BuyEventShopStock = GE:FindFirstChild("BuyEventShopStock")
	local function eventShopData()
		local ok, ESD = pcall(function() return require(RS.Data.EventShopData) end)
		return ok and ESD or {}
	end
	-- Tampilkan SEMUA item yang di-display shop (TANPA filter harga). Item mahal (Price >= 1e9
	-- kayak Gnome, Pet Shard GiantBean) itu harga Sheckle valid, dibeli via BuyEventShopStock;
	-- FallbackPrice/PurchaseID cuma opsi Robux. Cuma skip DisplayInShop==false.
	local function shopBuyable(v)
		return type(v) == "table" and v.DisplayInShop ~= false
	end
	local function shopStock(shop, item)
		local ok, d = pcall(function() return DataService:GetData() end)
		local s = ok and d and d.EventShopStock and d.EventShopStock[shop]
		local st = s and s.Stocks and s.Stocks[item]
		return st and tonumber(st.Stock) or 0
	end

	-- opsi dropdown item shop (gabungan 2 shop, "All" di atas)
	function ctx.getBeanstalkShopOptions()
		local ESD = eventShopData()
		local out = { { value = "All", display = "All (semua item)" } }
		local seen = {}
		for _, shop in ipairs(SHOP_LIST) do
			local cat = ESD[shop]
			if cat then
				local names = {}
				for name, v in pairs(cat) do if shopBuyable(v) and not seen[name] then seen[name] = true; names[#names + 1] = name end end
				table.sort(names)
				for _, n in ipairs(names) do out[#out + 1] = { value = n, display = n } end
			end
		end
		return out
	end

	local function buyShopLoop()
		ctx.state.beanShopId = (ctx.state.beanShopId or 0) + 1
		local myId = ctx.state.beanShopId
		ctx.elevate()
		while CFG.buyBeanstalkShopEnabled and ctx.alive() and ctx.state.beanShopId == myId do
			local sel = CFG.buyBeanstalkShopNames or {}
			if next(sel) and BuyEventShopStock then
				local ESD = eventShopData()
				local bought = 0
				for _, shop in ipairs(SHOP_LIST) do
					local cat = ESD[shop]
					if cat then
						for name, v in pairs(cat) do
							if shopBuyable(v) and (sel["All"] or sel[name]) then
								local n = shopStock(shop, name)
								for _ = 1, n do
									if not CFG.buyBeanstalkShopEnabled or ctx.state.beanShopId ~= myId then break end
									pcall(function() BuyEventShopStock:FireServer(name, shop) end)
									bought = bought + 1
									task.wait(0.15)
								end
							end
						end
					end
				end
				if bought > 0 then setStatus(("Beanstalk Shop: beli %d item"):format(bought)) end
			end
			task.wait(2)
		end
	end
	function ctx.startBuyBeanstalkShop() task.spawn(buyShopLoop) end
	function ctx.stopBuyBeanstalkShop() ctx.state.beanShopId = (ctx.state.beanShopId or 0) + 1 end
end
]=],
	["modules/farm/automation_collect.lua"] = [=[
--[[ automation_collect.lua — Auto Collect fruit (harvest ke backpack).
     Remote (dari CollectController): GameEvents.Crops.Collect:FireServer({fruitModel,...})
       — batch collect list FRUIT MODEL. Jalan walau jauh (server ga cek proximity).
     Backpack full: require(Modules.InventoryService):IsMaxInventory().
     Auto-sell: GameEvents.SellFood_RE:FireServer().
     3 mode (bisa barengan), collect fruit yang cocok SALAH SATU mode aktif:
       1) Whitelist Fruit   : tipe fruit terpilih
       2) Whitelist Mutation: fruit punya mutasi terpilih
       3) Combined          : fruit + mutasi + variant + berat (SEMUA kriteria)
       4) Blacklist Mutation: SEMUA buah bermutasi, kecuali yang punya mutasi di blacklist
                              (buah tanpa mutasi nggak di-collect) ]]
return function(ctx)
	local RS  = game:GetService("ReplicatedStorage")
	local CFG = ctx.CFG
	local LP  = ctx.LP
	local Collect = RS.GameEvents:WaitForChild("Crops"):WaitForChild("Collect")
	local SellInv = RS.GameEvents:WaitForChild("Sell_Inventory")
	local IS
	pcall(function() IS = require(RS.Modules.InventoryService) end)

	-- Jual semua fruit: HARUS deket NPC jual (Steven) — teleport bentar, jual, balik.
	local function sellAllFruits()
		local char = LP.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		local npcs = workspace:FindFirstChild("NPCS")
		local steven = npcs and npcs:FindFirstChild("Steven")
		local shrp = steven and steven:FindFirstChild("HumanoidRootPart")
		if not shrp then return end
		local orig = hrp.CFrame
		hrp.CFrame = shrp.CFrame * CFrame.new(0, 0, 4) -- deket Steven
		task.wait(0.5)
		pcall(function() SellInv:FireServer() end)
		task.wait(0.8)
		pcall(function() if hrp and hrp.Parent then hrp.CFrame = orig end end) -- balik
	end

	local NOT_MUTATION = {
		FruitVersion = true, MaxAge = true, GrowRateMulti = true, WeightMulti = true,
		DoneGrowTime = true, FruitSpawnIndex = true, OfflineGrowthTarget = true,
		MasteryGrowthMulti = true, MasterySizeMulti = true,
	}

	local function backpackFull()
		if not IS then return false end
		local ok, full = pcall(function() return IS:IsMaxInventory() end)
		return ok and full == true
	end

	-- Cuma kebun MILIK SENDIRI. Semua garden namanya "Farm", dibedain lewat Important.Data.Owner.
	-- Skip-CommunityGarden aja ga cukup -> kesapu kebun pemain lain (bug).
	local function myGarden()
		local ok, GetFarm = pcall(function() return require(RS.Modules.GetFarm) end)
		if ok and GetFarm then local ok2, f = pcall(function() return GetFarm(LP) end); if ok2 and f then return f end end
		local Farm = workspace:FindFirstChild("Farm"); if not Farm then return nil end
		for _, g in ipairs(Farm:GetChildren()) do
			local d = g:FindFirstChild("Important") and g.Important:FindFirstChild("Data")
			local o = d and d:FindFirstChild("Owner")
			if o and o.Value == LP.Name then return g end
		end
		return nil
	end
	local function eachFruit(fn)
		local g = myGarden(); local imp = g and g:FindFirstChild("Important")
		local pp = imp and imp:FindFirstChild("Plants_Physical")
		if not pp then return end
		for _, plant in ipairs(pp:GetChildren()) do
			local fr = plant:FindFirstChild("Fruits")
			if fr then for _, f in ipairs(fr:GetChildren()) do fn(f) end end
		end
	end

	----------------------------------------------------------------- opsi UI
	local function optionsFrom(names, allLabel)
		local out = { { value = "All", display = allLabel or "All" } }
		for _, n in ipairs(names) do out[#out + 1] = { value = n, display = n } end
		return out
	end
	local function catalog()
		local ok, t = pcall(function() return require(RS.Data.SeedShopData) end)
		local names = {}
		if ok and type(t) == "table" then
			for k in pairs(t) do local n = tostring(k); if n ~= "RefreshTime" and n ~= "Gear" then names[#names + 1] = n end end
			table.sort(names)
		end
		return names
	end
	function ctx.getCollectFruitOptions() return optionsFrom(catalog(), "All (semua fruit)") end
	function ctx.getCollectVariantOptions()
		local set = { Normal = true, Gold = true, Rainbow = true }
		eachFruit(function(f) local v = f:FindFirstChild("Variant"); if v and v.Value ~= "" then set[tostring(v.Value)] = true end end)
		local names = {} for k in pairs(set) do names[#names + 1] = k end; table.sort(names)
		return optionsFrom(names, "All (semua variant)")
	end
	function ctx.getCollectMutationOptions()
		-- daftar LENGKAP semua mutasi buah dari registry (MutationHandler.MutationNames)
		local ok, MH = pcall(function() return require(RS.Modules.MutationHandler) end)
		local names = {}
		if ok and MH and type(MH.MutationNames) == "table" then
			local mn = MH.MutationNames
			if mn[1] ~= nil then for _, v in ipairs(mn) do names[#names + 1] = tostring(v) end
			else for k in pairs(mn) do names[#names + 1] = tostring(k) end end
			table.sort(names)
		end
		return optionsFrom(names, "All (semua mutasi)")
	end
	function ctx.getCollectModeOptions() return { ">= (berat minimal)", "<= (berat maksimal)" } end
	-- opsi blacklist: semua mutasi TANPA "All" (blacklist All = nggak ada yang ke-harvest)
	function ctx.getCollectBlMutOptions()
		local out = {}
		for _, o in ipairs(ctx.getCollectMutationOptions()) do
			if o.value ~= "All" then out[#out + 1] = o end
		end
		return out
	end

	----------------------------------------------------------------- match per-mode
	local function hasSelMut(f, muts)
		for m in pairs(muts) do if m ~= "All" and f:GetAttribute(m) == true then return true end end
		return false
	end
	local function fruitVariant(f) local v = f:FindFirstChild("Variant"); return v and tostring(v.Value) or "Normal" end
	local function fruitWeight(f) local w = f:FindFirstChild("Weight"); return w and tonumber(w.Value) or 0 end

	-- mode 1: whitelist fruit type
	local function matchWlFruit(f)
		if not CFG.collectWlFruitEnabled then return false end
		local sel = CFG.collectWlFruitNames or {}
		return sel["All"] == true or sel[f.Name] == true
	end
	-- mode 2: whitelist mutation
	local function matchWlMut(f)
		if not CFG.collectWlMutEnabled then return false end
		local muts = CFG.collectWlMutNames or {}
		if muts["All"] then return true end
		return hasSelMut(f, muts)
	end
	-- mode 3: combined (SEMUA kriteria)
	local function matchCombined(f)
		if not CFG.collectCombEnabled then return false end
		local sel  = CFG.collectCombFruitNames or {}
		local muts = CFG.collectCombMutNames or {}
		local vars = CFG.collectCombVariants or {}
		if not (next(sel) == nil or sel["All"] or sel[f.Name]) then return false end
		if not (next(muts) == nil or muts["All"] or hasSelMut(f, muts)) then return false end
		if not (next(vars) == nil or vars["All"] or vars[fruitVariant(f)]) then return false end
		local thr = tonumber(CFG.collectCombWeight) or 0
		if thr > 0 then
			local w = fruitWeight(f)
			if (CFG.collectCombMode or ">="):find("<=") then if not (w <= thr) then return false end
			else if not (w >= thr) then return false end end
		end
		return true
	end

	-- mode 4: blacklist mutation — collect SEMUA buah yang punya mutasi, kecuali yang punya
	-- salah satu mutasi di blacklist. Buah tanpa mutasi = skip.
	local mutNameSet
	local function getMutNameSet()
		if mutNameSet then return mutNameSet end
		local set = {}
		pcall(function()
			local MH = require(RS.Modules.MutationHandler)
			local mn = MH and MH.MutationNames
			if type(mn) == "table" then
				if mn[1] ~= nil then for _, v in ipairs(mn) do set[tostring(v)] = true end
				else for k in pairs(mn) do set[tostring(k)] = true end end
			end
		end)
		if next(set) then mutNameSet = set end -- registry belum siap -> coba lagi nanti
		return set
	end
	-- daftar mutasi yang nempel di buah (atribut boolean true)
	local function fruitMutations(f)
		local out = {}
		local names = getMutNameSet()
		local useRegistry = next(names) ~= nil
		for k, v in pairs(f:GetAttributes()) do
			if v == true and not NOT_MUTATION[k] and ((not useRegistry) or names[k]) then
				out[#out + 1] = k
			end
		end
		return out
	end
	local function matchBlMut(f)
		if not CFG.collectBlMutEnabled then return false end
		local muts = fruitMutations(f)
		if #muts == 0 then return false end -- buah non-mutasi nggak di-harvest
		local bl = CFG.collectBlMutNames or {}
		for _, m in ipairs(muts) do
			if bl[m] then return false end
		end
		return true
	end

	local function shouldCollect(f)
		return matchWlFruit(f) or matchWlMut(f) or matchCombined(f) or matchBlMut(f)
	end
	local function anyEnabled()
		return CFG.collectWlFruitEnabled or CFG.collectWlMutEnabled or CFG.collectCombEnabled
			or CFG.collectBlMutEnabled
	end

	----------------------------------------------------------------- loop
	local running = false
	local function collectLoop()
		ctx.state.collectId = (ctx.state.collectId or 0) + 1
		local myId = ctx.state.collectId
		ctx.elevate()
		while anyEnabled() and ctx.alive() and ctx.state.collectId == myId do
			-- backpack full handling
			if backpackFull() then
				if CFG.collectAutoSellIfFull then
					ctx.setStatus("Auto Collect: backpack penuh -> jual (ke Steven)")
					sellAllFruits()
					task.wait(0.5)
				elseif CFG.collectStopIfFull then
					ctx.setStatus("Auto Collect: backpack penuh -> stop")
					task.wait(math.max(1, tonumber(CFG.collectDelay) or 0))
					-- lanjut cek lagi (ga collect)
				end
			end
			if not (backpackFull() and CFG.collectStopIfFull and not CFG.collectAutoSellIfFull) then
				-- kumpulin fruit yg cocok
				local batch = {}
				eachFruit(function(f) if shouldCollect(f) then batch[#batch + 1] = f end end)
				-- fire per-chunk (biar payload ga kegedean)
				local n = 0
				for i = 1, #batch, 40 do
					if not anyEnabled() or ctx.state.collectId ~= myId then break end
					local chunk = {}
					for j = i, math.min(i + 39, #batch) do chunk[#chunk + 1] = batch[j] end
					pcall(function() Collect:FireServer(chunk) end)
					n = n + #chunk
					task.wait(0.1)
					if backpackFull() then break end
				end
				ctx.setStatus(("Auto Collect: collect %d fruit"):format(n))
			end
			task.wait(math.max(0.5, tonumber(CFG.collectDelay) or 0) + 0.5)
		end
		running = false
	end

	-- 1 loop dipakai bareng semua mode; idempotent (semua toggle panggil ini).
	function ctx.startCollect()
		if running then return end
		running = true
		task.spawn(collectLoop)
	end
	function ctx.stopCollect() ctx.state.collectId = (ctx.state.collectId or 0) + 1 end
end
]=],
	["modules/farm/automation_favorite.lua"] = [=[
--[[ automation_favorite.lua — Auto Favorite/Unfavorite fruit.
     Favorite = "lock" buah biar ga kejual/keshovel. Pakai Favorite Tool (equip + guard).
     Remote (dari Favorite Tool script): LockToolRemote:InvokeServer(favTool, fruitModel, state)
       state=true -> favorite, false -> unfavorite. RemoteFunction.
     State fruit: fruit:GetAttribute("Favorited") (boolean). Cuma fruit tag "Harvestable".
     Filter: tipe fruit + mutasi (required) + berat (mode + threshold). ]]
return function(ctx)
	local RS  = game:GetService("ReplicatedStorage")
	local CFG = ctx.CFG
	local LP  = ctx.LP
	-- Ambil remote LAZY (jangan WaitForChild di module-load -> bisa nge-block init).
	local function favRemote()
		local GE = RS:FindFirstChild("GameEvents"); if not GE then return nil end
		return GE:FindFirstChild("FavoriteToolRemote") or GE:FindFirstChild("Favorite_Item")
	end
	-- Panggil remote: RemoteFunction -> InvokeServer, RemoteEvent -> FireServer.
	local function doFav(tool, fruit, state)
		local re = favRemote(); if not re then return end
		pcall(function()
			if re:IsA("RemoteFunction") then re:InvokeServer(tool, fruit, state)
			else re:FireServer(tool, fruit, state) end
		end)
	end

	----------------------------------------------------------------- tool equip + guard
	local function findTool()
		for _, where in ipairs({ LP.Character, LP:FindFirstChildOfClass("Backpack") }) do
			if where then for _, t in ipairs(where:GetChildren()) do
				if t:IsA("Tool") and tostring(t.Name):find("Favorite") then return t end
			end end
		end
	end
	local function heldTool()
		local char = LP.Character
		if not char then return nil end
		for _, t in ipairs(char:GetChildren()) do
			if t:IsA("Tool") and tostring(t.Name):find("Favorite") then return t end
		end
	end
	local function equipTool()
		local char = LP.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hum then return false end
		if heldTool() then return true end
		local tl = findTool()
		if not tl then return false end
		pcall(function() hum:EquipTool(tl) end)
		task.wait(0.2)
		return heldTool() ~= nil
	end
	local guardRunning = false
	local function ensureGuard()
		if guardRunning then return end
		guardRunning = true
		task.spawn(function()
			while (CFG.favEnabled or CFG.unfavEnabled) and ctx.alive() do
				if not heldTool() then equipTool() end
				task.wait(0.25)
			end
			guardRunning = false
		end)
	end

	----------------------------------------------------------------- opsi UI
	local function optionsFrom(names, allLabel)
		local out = { { value = "All", display = allLabel or "All" } }
		for _, n in ipairs(names) do out[#out + 1] = { value = n, display = n } end
		return out
	end
	local function catalog()
		local ok, t = pcall(function() return require(RS.Data.SeedShopData) end)
		local names = {}
		if ok and type(t) == "table" then
			for k in pairs(t) do local n = tostring(k); if n ~= "RefreshTime" and n ~= "Gear" then names[#names + 1] = n end end
			table.sort(names)
		end
		return names
	end
	function ctx.getFavFruitOptions() return optionsFrom(catalog(), "All (semua fruit)") end
	function ctx.getFavMutationOptions()
		local ok, MH = pcall(function() return require(RS.Modules.MutationHandler) end)
		local names = {}
		if ok and MH and type(MH.MutationNames) == "table" then
			local mn = MH.MutationNames
			if mn[1] ~= nil then for _, v in ipairs(mn) do names[#names + 1] = tostring(v) end
			else for k in pairs(mn) do names[#names + 1] = tostring(k) end end
			table.sort(names)
		end
		return optionsFrom(names, "All (mutasi apapun)")
	end
	function ctx.getFavModeOptions() return { ">= (berat minimal)", "<= (berat maksimal)" } end

	----------------------------------------------------------------- match filter
	local function fruitWeight(f) local w = f:FindFirstChild("Weight"); return w and tonumber(w.Value) or 0 end
	local function fruitMatches(f)
		local sel  = CFG.favFruitNames or {}
		local muts = CFG.favMutNames or {}
		-- tipe (kosong = any)
		if not (next(sel) == nil or sel["All"] or sel[f.Name]) then return false end
		-- mutasi required (kosong = any). Fruit harus punya salah satu mutasi terpilih.
		if not (next(muts) == nil or muts["All"]) then
			local hit = false
			for m in pairs(muts) do if m ~= "All" and f:GetAttribute(m) == true then hit = true; break end end
			if not hit then return false end
		end
		-- berat (0 = off)
		local thr = tonumber(CFG.favWeight) or 0
		if thr > 0 then
			local w = fruitWeight(f)
			if (CFG.favMode or ">="):find("<=") then if not (w <= thr) then return false end
			else if not (w >= thr) then return false end end
		end
		return true
	end

	-- kebun MILIK SENDIRI aja. Semua garden namanya "Farm", dibedain lewat Important.Data.Owner
	-- -> skip-CommunityGarden aja kesapu kebun pemain lain (bug).
	local function myGarden()
		local ok, GetFarm = pcall(function() return require(RS.Modules.GetFarm) end)
		if ok and GetFarm then local ok2, f = pcall(function() return GetFarm(LP) end); if ok2 and f then return f end end
		local Farm = workspace:FindFirstChild("Farm"); if not Farm then return nil end
		for _, g in ipairs(Farm:GetChildren()) do
			local d = g:FindFirstChild("Important") and g.Important:FindFirstChild("Data")
			local o = d and d:FindFirstChild("Owner")
			if o and o.Value == LP.Name then return g end
		end
		return nil
	end
	local function eachHarvestable(fn)
		local g = myGarden(); local imp = g and g:FindFirstChild("Important")
		local pp = imp and imp:FindFirstChild("Plants_Physical")
		if not pp then return end
		for _, plant in ipairs(pp:GetChildren()) do
			local fr = plant:FindFirstChild("Fruits")
			if fr then for _, f in ipairs(fr:GetChildren()) do
				if f:HasTag("Harvestable") then fn(f) end
			end end
		end
	end

	----------------------------------------------------------------- loop
	local function favLoop()
		ctx.state.favId = (ctx.state.favId or 0) + 1
		local myId = ctx.state.favId
		ctx.elevate()
		while (CFG.favEnabled or CFG.unfavEnabled) and ctx.alive() and ctx.state.favId == myId do
			local tool = heldTool() or findTool()
			if not tool then
				ctx.setStatus("Auto Favorite: Favorite Tool ga ada")
			else
				local n = 0
				eachHarvestable(function(f)
					if not (CFG.favEnabled or CFG.unfavEnabled) or ctx.state.favId ~= myId then return end
					if not fruitMatches(f) then return end
					local isFav = f:GetAttribute("Favorited") == true
					if CFG.favEnabled and not isFav then
						doFav(tool, f, true); n = n + 1; task.wait(0.08)
					elseif CFG.unfavEnabled and isFav then
						doFav(tool, f, false); n = n + 1; task.wait(0.08)
					end
				end)
				ctx.setStatus(("Auto Favorite: proses %d buah"):format(n))
			end
			task.wait(math.max(0.5, tonumber(CFG.favDelay) or 1) + 0.5)
		end
	end

	function ctx.startFavorite()
		equipTool(); ensureGuard()
		task.spawn(favLoop)
	end
	function ctx.stopFavorite() ctx.state.favId = (ctx.state.favId or 0) + 1 end
end
]=],
	["modules/farm/automation_gm_sprinkler.lua"] = [=[
--[[ automation_gm_sprinkler.lua — Auto GM Sprinkler (toggle di tab Hatch,
     di bawah Enable Auto Hatch). Jaga 1 Grandmaster Sprinkler terpasang
     terus: cek objek sprinkler milik sendiri di Objects_Physical (attribute
     Lifetime = sisa detik, 1 GM kuat 10 menit), kalau tidak ada / mau mati
     (sisa <= GM_REFILL) -> equip tool "Grandmaster Sprinkler x<n>" ->
     SprinklerService:FireServer("Create", CFrame.new(pos)).
     Fungsi: ctx.startGmSprinkler / ctx.stopGmSprinkler. ]]
return function(ctx)
	local LP, CFG = ctx.LP, ctx.CFG
	local RS = game:GetService("ReplicatedStorage")
	local GE = RS:WaitForChild("GameEvents")
	local SprinklerService = GE:WaitForChild("SprinklerService")
	local GM_TYPE   = "Grandmaster Sprinkler"
	local GM_REFILL = 45 -- pasang baru ketika sisa 45 detik, jangan sampai terputus
	local setStatus = ctx.setStatus

	local function important()
		local ok, GetFarm = pcall(function() return require(RS.Modules.GetFarm) end)
		if not ok or not GetFarm then return nil end
		local ok2, f = pcall(function() return GetFarm(LP) end)
		return (ok2 and f and f:FindFirstChild("Important")) or nil
	end

	-- state, lifeMin = "none"/"alive"/"expiring", sisa detik terkecil dari
	-- sprinkler yang terpasang. Attribute Lifetime yang tidak ada = dianggap
	-- tetap berjalan (anti-spam) — objek yang hilang saat expired tetap tertangkap.
	local function gmState()
		local imp = important()
		local of = imp and imp:FindFirstChild("Objects_Physical")
		if not of then return "none", 0 end
		local found, minLife = false, math.huge
		for _, o in ipairs(of:GetChildren()) do
			if (o:GetAttribute("OBJECT_TYPE") or o.Name) == GM_TYPE
				and o:GetAttribute("OWNER") == LP.Name then
				found = true
				local life = tonumber(o:GetAttribute("Lifetime"))
				if life and life < minLife then minLife = life end
			end
		end
		if not found then return "none", 0 end
		if minLife < math.huge and minLife <= GM_REFILL then return "expiring", minLife end
		return "alive", (minLife < math.huge and minLife or 0)
	end

	local function gmInventory()
		for _, where in ipairs({ LP:FindFirstChild("Backpack"), LP.Character }) do
			if where then for _, t in ipairs(where:GetChildren()) do
				if t:IsA("Tool") and t.Name:match("^" .. GM_TYPE .. " x%d+") then
					if (tonumber(t.Name:match("x(%d+)$")) or 0) > 0 then return t end
				end
			end end
		end
		return nil
	end

	local function equipGm(tool)
		local c = LP.Character
		if c and tool.Parent == c then return true end
		local hum = c and c:FindFirstChildOfClass("Humanoid")
		if hum then pcall(function() hum:EquipTool(tool) end) end
		return (c and tool.Parent == c) or false
	end

	-- titik acak di dalam area farm (Plant_Locations), format yang sama dengan Auto Sprinkler.
	local function gmPos()
		local imp = important()
		local pl = imp and imp:FindFirstChild("Plant_Locations")
		if not pl then return nil end
		local parts = {}
		for _, p in ipairs(pl:GetChildren()) do if p:IsA("BasePart") then parts[#parts + 1] = p end end
		if #parts == 0 then return nil end
		local p = parts[math.random(1, #parts)]
		local hx, hz = p.Size.X / 2 - 1, p.Size.Z / 2 - 1
		return Vector3.new(
			p.Position.X + (math.random() * 2 - 1) * hx,
			p.Position.Y,
			p.Position.Z + (math.random() * 2 - 1) * hz)
	end

	local function gmLoop(myId)
		ctx.elevate()
		while CFG.gmSprinklerEnabled and ctx.alive() and ctx.state.gmSprId == myId do
			local st, life = gmState()
			if st == "alive" then
				setStatus(("GM Sprinkler: %ss left"):format(math.floor(life)))
			else
				local tool = gmInventory()
				if not tool then
					setStatus("GM Sprinkler: no stock")
				else
					local pos = gmPos()
					if pos and equipGm(tool) then
						pcall(function() SprinklerService:FireServer("Create", CFrame.new(pos)) end)
						setStatus("GM Sprinkler: placed")
						-- berselang 3 detik: beri waktu server untuk melakukan spawn, jangan terjadi double-place
						task.wait(3)
					end
				end
			end
			task.wait(1)
		end
	end

	function ctx.startGmSprinkler()
		ctx.state.gmSprId = (ctx.state.gmSprId or 0) + 1
		local myId = ctx.state.gmSprId
		task.spawn(function() gmLoop(myId) end)
	end

	function ctx.stopGmSprinkler()
		ctx.state.gmSprId = (ctx.state.gmSprId or 0) + 1
	end
end
]=],
	["modules/farm/automation_plants.lua"] = [=[
--[[ automation_plants.lua — Auto Plant seed (Farm).
     Tanam seed dari inventory ke farm.
     Remote: Plant_RE:FireServer(Vector3 pos, "SeedName")
     Seed & jumlah dari DataService InventoryData (ItemType="Seed", ItemData.ItemName/Quantity).
     WAJIB megang tool seed-nya pas Plant_RE -> equip ulang tiap mau tanam (kayak reclaimer).
     Posisi: Random / Player Position / Good Position (barisan lurus urut
     kiri->kanan; cell yang dipegang plant lama di-shovel biar server
     nggak geser tanaman baru — toggle "Shovel Penghalang").
     Fungsi: ctx.getPlantSeedOptions / ctx.startPlant. ]]
return function(ctx)
	local LP  = ctx.LP
	local CFG = ctx.CFG
	local RS  = game:GetService("ReplicatedStorage")
	local GE  = RS:WaitForChild("GameEvents")
	local Plant_RE = GE:WaitForChild("Plant_RE")
	local DataService = ctx.deps.DataService
	local function setStatus(s) ctx.setStatus(s) end

	local function myFarm()
		local ok, GetFarm = pcall(function() return require(RS.Modules.GetFarm) end)
		if ok and GetFarm then
			local ok2, f = pcall(function() return GetFarm(LP) end)
			if ok2 then return f end
		end
		return nil
	end
	local function important() local f = myFarm(); return f and f:FindFirstChild("Important") end
	local function canPlantParts()
		local imp = important()
		local pl = imp and imp:FindFirstChild("Plant_Locations")
		local parts = {}
		if pl then for _, p in ipairs(pl:GetChildren()) do if p:IsA("BasePart") then parts[#parts + 1] = p end end end
		return parts
	end
	local function plantsFolder()
		local f = myFarm()
		local imp = f and f:FindFirstChild("Important")
		return imp and imp:FindFirstChild("Plants_Physical")
	end

	----------------------------------------------------------------- seed inventory
	-- name -> total quantity (dari semua entry Seed di InventoryData)
	local function seedInventory()
		local out = {}
		local ok, d = pcall(function() return DataService:GetData() end)
		if ok and d and type(d.InventoryData) == "table" then
			for _, v in pairs(d.InventoryData) do
				if type(v) == "table" and v.ItemType == "Seed" and v.ItemData then
					local nm = v.ItemData.ItemName
					local q = tonumber(v.ItemData.Quantity) or 0
					if nm then out[nm] = (out[nm] or 0) + q end
				end
			end
		end
		return out
	end

	-- Opsi dropdown seed: "Nama (jumlah)". Sekalian buang seed yg udah 0 dari selection.
	local function seedOptions()
		local inv = seedInventory()
		local sel = CFG.plantSeedNames
		if type(sel) == "table" then
			local changed = false
			for nm in pairs(sel) do if (inv[nm] or 0) <= 0 then sel[nm] = nil; changed = true end end
			if changed and ctx.persistState then pcall(ctx.persistState) end
		end
		local names = {}
		for n, q in pairs(inv) do if q > 0 then names[#names + 1] = n end end
		table.sort(names)
		local out = {}
		for _, n in ipairs(names) do out[#out + 1] = { value = n, display = ("%s (%d)"):format(n, inv[n]) } end
		return out
	end
	function ctx.getPlantSeedOptions() return seedOptions() end

	----------------------------------------------------------------- posisi
	local function randomPos()
		local parts = canPlantParts()
		if #parts == 0 then return nil end
		local p = parts[math.random(1, #parts)]
		local hx, hz = p.Size.X / 2 - 1, p.Size.Z / 2 - 1
		local x = p.Position.X + (math.random() * 2 - 1) * hx
		local z = p.Position.Z + (math.random() * 2 - 1) * hz
		return Vector3.new(x, p.Position.Y, z)
	end
	local function playerPos()
		local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
		if not hrp then return nil end
		local parts = canPlantParts()
		local y = parts[1] and parts[1].Position.Y or 0
		return Vector3.new(hrp.Position.X, y, hrp.Position.Z)
	end

	-- Good Position (request user: "god mode kaya grid egg"): SEL-SEL grid
	-- DIBUTAKIN DITENGAH lahan — simetris kiri-kanan & atas-bawah, baris rata
	-- kiri->kanan (sama geometrinya sama grid egg di automation_hatch, cuma
	-- spacing 2.5 karena server min jarak tanaman lebih rapet dari egg).
	-- Anchor tetap = pivot server plant pertama (anti snap server); semua
	-- offset RELATIF ke patokan, jadi snap kenanya rata — barisan ga miring.
	-- Cell yang dipegang plant lama DIBERSIHKAN dulu (toggle "Shovel
	-- Penghalang"); gagal -> skip 1 cell.
	local GOOD_STEP   = 2.5
	local GOOD_TAKE_R = GOOD_STEP - 0.1
	local RemoveItem = RS:WaitForChild("GameEvents"):WaitForChild("Remove_Item")
	local goodCursor = { part = nil, col = 0, row = 0 }
	local anchorPos = nil -- pivot server plant pertama = patokan
	local function heldShovel()
		local ch = LP.Character
		if ch then for _, t in ipairs(ch:GetChildren()) do
			if t:IsA("Tool") and tostring(t.Name):find("Shovel") then return t end
		end end
		return nil
	end
	local function equipShovel() -- server nolak Remove_Item kalau ga pegang Shovel
		if heldShovel() then return true end
		local sh
		for _, w in ipairs({ LP.Character, LP:FindFirstChild("Backpack") }) do
			if w then for _, t in ipairs(w:GetChildren()) do
				if t:IsA("Tool") and tostring(t.Name):find("Shovel") then sh = t; break end
			end end
			if sh then break end
		end
		local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
		if sh and hum then pcall(function() hum:EquipTool(sh) end); task.wait(0.15) end
		return heldShovel() ~= nil
	end
	local function blockersAt(pf, x, z) -- plant yang pivot-nya makan cell (x,z)
		local out = {}
		if pf then
			for _, m in ipairs(pf:GetChildren()) do
				local ok, pv = pcall(function() return m:GetPivot().Position end)
				if ok and pv and math.abs(pv.X - x) < GOOD_TAKE_R and math.abs(pv.Z - z) < GOOD_TAKE_R then
					out[#out + 1] = m
				end
			end
		end
		return out
	end
	local function clearBlocker(m) -- Remove_Item(PrimaryPart) & tunggu ilang beneran
		local part = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
		if not (part and equipShovel()) then return false end
		pcall(function() RemoveItem:FireServer(part) end)
		local t0 = os.clock()
		while m.Parent and os.clock() - t0 < 2 do task.wait(0.05) end
		return not m.Parent
	end
	local function goodPos()
		local parts = canPlantParts()
		if #parts == 0 then goodCursor = { part = nil, col = 0, row = 0 }; return nil end
		local p = parts[1]
		local halfX = p.Size.X / 2 - 0.75
		local halfZ = p.Size.Z / 2 - 1
		if goodCursor.part ~= p then goodCursor = { part = p, col = 0, row = 0 }; anchorPos = nil end
		-- Grid CENTERED di lahan (kayak gridPositions egg): sisa tepi kiri =
		-- sisa tepi kanan, baris rata. Cursor jalan baris-per-baris full plot.
		local cols = math.max(1, math.floor((halfX * 2) / GOOD_STEP) + 1)
		local originX = p.Position.X - ((cols - 1) * GOOD_STEP) / 2
		local originZ = p.Position.Z - (math.floor((halfZ * 2) / GOOD_STEP) * GOOD_STEP) / 2
		for _ = 1, 800 do -- cap sweep; lahan beneran keblokir -> coba lagi tik depan
			local x, z
			if anchorPos then -- grid RELATIF pivot plant pertama (patokan)
				x = anchorPos.X + goodCursor.col * GOOD_STEP
				z = anchorPos.Z + goodCursor.row * GOOD_STEP
			else
				x = originX + goodCursor.col * GOOD_STEP
				z = originZ + goodCursor.row * GOOD_STEP
			end
			if x > p.Position.X + halfX then -- mentok kanan -> baris baru di bawah
				goodCursor.col, goodCursor.row = 0, goodCursor.row + 1
				x = anchorPos and anchorPos.X or originX
				z = anchorPos and (anchorPos.Z + goodCursor.row * GOOD_STEP)
					or (originZ + goodCursor.row * GOOD_STEP)
			end
			if z > p.Position.Z + halfZ then -- lahan penuh -> mulai baris awal lagi
				goodCursor.col, goodCursor.row = 0, 0
				x = anchorPos and anchorPos.X or originX
				z = anchorPos and anchorPos.Z or originZ
			end
			local bl = blockersAt(plantsFolder(), x, z)
			local free = (#bl == 0)
			if not free and CFG.goodClear ~= false then
				local cleared = 0
				for _, m in ipairs(bl) do if clearBlocker(m) then cleared = cleared + 1 end end
				free = (cleared == #bl)
			end
			goodCursor.col = goodCursor.col + 1 -- cell selesai diproses (tanam/shovel/skip)
			if free then return Vector3.new(x, p.Position.Y, z) end
		end
		return nil
	end

	-- Kenapa speed 0 rozak? Fire ke server itu ASYNC: bisa ketelen, dan
	-- posisi yang kita kirim bisa di-snap/geser server beda dari dugaan
	-- frame kita — grid absolut frame kita lama-lama selang-seling nabrak,
	-- server naruh plant ke posisi acak. Fix 2 lapis: (1) cursor TIDAK MAJU
	-- selama cell belum keisi beneran; fire yang gagap ditembak ULANG tiap
	-- ~0.6s ke posisi sama (cap 8s -> skip, ga bohong). (2) patokan grid =
	-- PIVOT SERVER plant pertama (request user), semua cell berikutnya
	-- offset relatif dari situ. Stragglers nyasar tetap dipungut
	-- "Shovel Penghalang" di sweep lain. Delay 0 = secepat pencatatan
	-- server per plant, barisan tetap lurus.
	local function waitCellOccupied(pos, seedName)
		if not pos then return nil end
		local t0 = os.clock()
		local nextRetry = os.clock() + 0.6
		while os.clock() - t0 < 8 do
			if not CFG.plantSeedEnabled then return nil end
			local pf = plantsFolder()
			if pf then
				for _, m in ipairs(pf:GetChildren()) do
					local ok, pv = pcall(function() return m:GetPivot().Position end)
					if ok and pv and math.abs(pv.X - pos.X) < GOOD_TAKE_R and math.abs(pv.Z - pos.Z) < GOOD_TAKE_R then
						return pv -- pivot server plant baru -> ini jadi patokan
					end
				end
			end
			if os.clock() >= nextRetry then -- fire ketelen/nyasar -> tembak lagi ke pos SAMA
				pcall(function() Plant_RE:FireServer(pos, seedName) end)
				nextRetry = os.clock() + 0.6
			end
			task.wait(0.05)
		end
		return nil
	end

----------------------------------------------------------------- ack tanam
	-- Server nyatet plant baru di Plants_Physical secara ASYNC. Kalau kita
	-- ngebut (plantDelay 0), fire berikutnya nyamain server sebelum plant
	-- sebelumnya terdaftar di occupancy -> server nabrak dan naruh plant di
	-- POSISI ACAK. Makanya tiap fire DITUNGGU sampe plant barunya beneran
	-- muncul (ack, max 2.5s) baru lanjut. Ini bikin Good Position lurus di
	-- SEMUA nilai delay (0 pun bisa, kecepatan = secepat server nyatet).
	-- ponytail: Good Position udah bersihin penghalang jalurnya (pivot,
	-- radius GOOD_TAKE_R + Remove_Item). Celah: tanaman yang server anggap
	-- nutup cell tapi pivot-nya jauh (jarang). Upgrade: verifikasi per-tanam.
	local function plantSet(pf)
		local set = {}
		for _, m in ipairs(pf:GetChildren()) do
			local ok, pv = pcall(function() return m:GetPivot().Position end)
			if ok and pv then set[string.format("%d,%d,%d", pv.X, pv.Y, pv.Z)] = true end
		end
		return set
	end
	local function plantAck(before, timeout)
		local pf = plantsFolder()
		local t0 = os.clock()
		while before and pf and os.clock() - t0 < (timeout or 2.5) do
			if not CFG.plantSeedEnabled then return end
			for k in pairs(plantSet(pf)) do
				if not before[k] then return end -- plant baru kedetect -> server siap
			end
			task.wait(0.05)
		end
	end

	----------------------------------------------------------------- equip seed
	-- Tool seed namanya "<Nama> Seed [Xjumlah]". Server WAJIB kamu megang tool-nya
	-- pas Plant_RE, jadi equip ulang tiap mau tanam (walau user pindah manual).
	local function seedBase(t)
		return t:IsA("Tool") and t.Name:match("^(.-) Seed %[X%d+%]") or nil
	end
	local function holdingSeed(name)
		local ch = LP.Character
		if ch then for _, t in ipairs(ch:GetChildren()) do if seedBase(t) == name then return true end end end
		return false
	end
	local function equipSeed(name)
		if holdingSeed(name) then return true end
		local bp = LP:FindFirstChild("Backpack")
		local tool
		if bp then for _, t in ipairs(bp:GetChildren()) do if seedBase(t) == name then tool = t; break end end end
		if tool then
			local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
			if hum then pcall(function() hum:EquipTool(tool) end) end
		end
		return holdingSeed(name)
	end

	----------------------------------------------------------------- loop tanam
	local function plantLoop(myId)
		ctx.elevate()
		while CFG.plantSeedEnabled and ctx.alive() and ctx.state.plantId == myId do
			local sel = CFG.plantSeedNames or {}
			if next(sel) then
				local inv = seedInventory()
				local mode = (CFG.plantPosition == "Player Position" and "Player Position")
					or (CFG.plantPosition == "Good Position" and "Good Position")
					or "Random"
				-- Kecepatan sepenuhnya ikut Delay input (0 = secepat mungkin).
				local planted, anySeed = 0, false
				for name in pairs(sel) do
					local qty = inv[name] or 0
					if qty > 0 then
						anySeed = true
						for _ = 1, qty do
							if not CFG.plantSeedEnabled or ctx.state.plantId ~= myId then break end
							if equipSeed(name) then -- equip seed tiap mau tanam
								local pos = (mode == "Player Position" and playerPos())
									or (mode == "Good Position" and goodPos())
									or randomPos()
								if pos then
									-- snapshot SEBELUM fire, biar ack ga ketuker dgn plant lama
									local pf = plantsFolder()
									local before = pf and plantSet(pf) or nil
									pcall(function() Plant_RE:FireServer(pos, name) end)
									planted = planted + 1
									if mode == "Good Position" then
										local landed = waitCellOccupied(pos, name)
										-- Patokan = pivot server plant PERTAMA
										-- (request user): semua cell berikutnya
										-- offset relatif dari sini.
										if landed and anchorPos == nil then anchorPos = landed end
									else
										plantAck(before, 2.5)
									end
								end
							end
							task.wait(tonumber(CFG.plantDelay) or 0)
						end
					end
				end
				if not anySeed then setStatus("Plants: seed terpilih habis")
				else setStatus(("Plants: tanam %d (%s)"):format(planted, mode)) end
			else
				setStatus("Plants: pilih seed dulu")
			end
			task.wait(1)
		end
	end

	function ctx.startPlant()
		ctx.state.plantId = (ctx.state.plantId or 0) + 1
		local myId = ctx.state.plantId
		task.spawn(function() plantLoop(myId) end)
	end
end
]=],
	["modules/farm/automation_reclaimer.lua"] = [=[
--[[ automation_reclaimer.lua — Auto Reclaimer plant (Farm).
     Reclaim plant yg ditanam di garden pakai tool Reclaimer.
     Remote: ReclaimerService_RE:FireServer("TryReclaim", plantModel)
       plantModel = Model di Farm.Important.Plants_Physical (mis. "Blueberry").
     Dropdown "Select Plants": jenis plant unik yg ada di garden (+ "All").
     Butuh tool Reclaimer (auto-equip di loop). Tiap reclaim makan 1 charge Reclaimer.
     Fungsi: ctx.getReclaimPlantOptions / ctx.startReclaim. ]]
return function(ctx)
	local LP  = ctx.LP
	local CFG = ctx.CFG
	local RS  = game:GetService("ReplicatedStorage")
	local GE  = RS:WaitForChild("GameEvents")
	local ReclaimRE = GE:WaitForChild("ReclaimerService_RE")
	local function setStatus(s) ctx.setStatus(s) end

	local function myFarm()
		local ok, GetFarm = pcall(function() return require(RS.Modules.GetFarm) end)
		if ok and GetFarm then
			local ok2, f = pcall(function() return GetFarm(LP) end)
			if ok2 then return f end
		end
		return nil
	end

	local function plantsFolder()
		local f = myFarm()
		local imp = f and f:FindFirstChild("Important")
		return imp and imp:FindFirstChild("Plants_Physical")
	end

	-- Jenis plant unik yg lagi ada di garden.
	local function existingTypes()
		local seen = {}
		local pf = plantsFolder()
		if pf then for _, m in ipairs(pf:GetChildren()) do if m.Name then seen[m.Name] = true end end end
		return seen
	end

	-- Buang plant terpilih yg udah ga ada di garden (kecuali "All"),
	-- biar ga kepilih tapi tanamannya udah abis.
	local function pruneSelection(existing)
		local sel = CFG.reclaimPlantNames
		if type(sel) ~= "table" then return end
		local changed = false
		for name in pairs(sel) do
			if name ~= "All" and not existing[name] then sel[name] = nil; changed = true end
		end
		if changed and ctx.persistState then pcall(ctx.persistState) end
	end

	-- Opsi dropdown: "All" + jenis plant yg lagi ada. Sekalian prune selection stale.
	local function plantOptions()
		local existing = existingTypes()
		pruneSelection(existing)
		local out = { { value = "All", display = "All (semua plant)" } }
		local names = {}
		for n in pairs(existing) do names[#names + 1] = n end
		table.sort(names)
		for _, n in ipairs(names) do out[#out + 1] = { value = n, display = n } end
		return out
	end
	function ctx.getReclaimPlantOptions() return plantOptions() end

	-- Nama tool di inventory ada suffix jumlah (mis. "Reclaimer x50634"),
	-- jadi cocokin per-prefix, bukan exact.
	local function isReclaimer(t)
		return t:IsA("Tool") and t.Name:match("^Reclaimer") ~= nil
	end
	local function heldReclaimer()
		local char = LP.Character
		if not char then return nil end
		for _, t in ipairs(char:GetChildren()) do if isReclaimer(t) then return t end end
		return nil
	end

	-- Equip tool Reclaimer dari Backpack kalau belum kepegang.
	local function equipReclaimer()
		local char = LP.Character
		if not char then return false end
		if heldReclaimer() then return true end
		local bp = LP:FindFirstChild("Backpack")
		local tool
		if bp then for _, t in ipairs(bp:GetChildren()) do if isReclaimer(t) then tool = t; break end end end
		if tool then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then pcall(function() hum:EquipTool(tool) end) end
		end
		return heldReclaimer() ~= nil
	end

	----------------------------------------------------------------- loop reclaim
	local POLL = 1
	local function reclaimLoop(myId)
		ctx.elevate()
		while CFG.reclaimEnabled and ctx.alive() and ctx.state.reclaimId == myId do
			local pf = plantsFolder()
			local sel = CFG.reclaimPlantNames or {}
			local all = sel["All"]
			if pf and (all or next(sel)) then
				local hasTool = equipReclaimer()
				if not hasTool then
					setStatus("Reclaimer: tool 'Reclaimer' ga ada di inventory")
				else
					local n = 0
					for _, m in ipairs(pf:GetChildren()) do
						if not CFG.reclaimEnabled or ctx.state.reclaimId ~= myId then break end
						if all or sel[m.Name] then
							pcall(function() ReclaimRE:FireServer("TryReclaim", m) end)
							n = n + 1
							task.wait(CFG.reclaimSpeed or 0.15)
						end
					end
					setStatus(("Reclaimer: proses %d plant"):format(n))
				end
			else
				setStatus("Reclaimer: pilih plant dulu")
			end
			task.wait(POLL)
		end
	end

	-- Guard: selama enable, tool Reclaimer WAJIB tetap kepegang. Kalau user pindah
	-- manual ke pet/tool lain, langsung equip ulang Reclaimer (cek cepat 0.25s).
	local function keepEquipped(myId)
		while CFG.reclaimEnabled and ctx.alive() and ctx.state.reclaimId == myId do
			if not heldReclaimer() then equipReclaimer() end
			task.wait(0.25)
		end
	end

	function ctx.startReclaim()
		ctx.state.reclaimId = (ctx.state.reclaimId or 0) + 1
		local myId = ctx.state.reclaimId
		equipReclaimer() -- equip langsung pas enable
		task.spawn(function() reclaimLoop(myId) end)
		task.spawn(function() keepEquipped(myId) end)
	end
end
]=],
	["modules/farm/automation_shovel.lua"] = [=[
--[[ automation_shovel.lua — Auto Shovel (2 mode):
       1) Shovel Tree/Plant  : hapus plant dari tipe terpilih (CFG.shovelTreeNames).
       2) Shovel Fruit        : hapus plant kalau punya FRUIT yang cocok filter
                                (tipe + mutasi + variant + berat vs threshold).
     Mekanisme (dari remote spy + tes live): Remove_Item:FireServer(plant.PrimaryPart)
     — hapus SELURUH plant. Ga perlu equip Shovel (server terima langsung).
     Plant ada di workspace.Farm.<garden>.Important.Plants_Physical (nama = tipe).
     Tiap plant.Fruits berisi fruit models: child Weight (NumberValue), Variant (StringValue),
     + attribute mutasi boolean (Wet/Twisted/dll). ]]
return function(ctx)
	local RS  = game:GetService("ReplicatedStorage")
	local CFG = ctx.CFG
	local LP  = ctx.LP
	local Remove = RS:WaitForChild("GameEvents"):WaitForChild("Remove_Item")

	-- cari + equip Shovel dulu (server nolak kalau ga pegang shovel)
	local function findShovel()
		for _, where in ipairs({ LP.Character, LP:FindFirstChildOfClass("Backpack") }) do
			if where then
				for _, t in ipairs(where:GetChildren()) do
					if t:IsA("Tool") and tostring(t.Name):find("Shovel") then return t end
				end
			end
		end
	end
	local function heldShovel()
		local char = LP.Character
		if not char then return nil end
		for _, t in ipairs(char:GetChildren()) do
			if t:IsA("Tool") and tostring(t.Name):find("Shovel") then return t end
		end
	end
	local function equipShovel()
		local char = LP.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hum then return false end
		if heldShovel() then return true end
		local sh = findShovel()
		if not sh then return false end
		pcall(function() hum:EquipTool(sh) end)
		task.wait(0.2)
		return heldShovel() ~= nil
	end

	-- Guard (mirip reclaimer): selama shovel aktif, Shovel WAJIB tetap kepegang.
	-- Kalau user pindah manual ke tool lain, langsung equip ulang (cek 0.25s).
	local guardRunning = false
	local function ensureGuard()
		if guardRunning then return end
		guardRunning = true
		task.spawn(function()
			while (CFG.shovelTreeEnabled or CFG.shovelFruitEnabled) and ctx.alive() do
				if not heldShovel() then equipShovel() end
				task.wait(0.25)
			end
			guardRunning = false
		end)
	end

	-- attribute fruit yang BUKAN mutasi (metadata) — dibuang pas listing opsi mutasi
	local NOT_MUTATION = {
		FruitVersion = true, MaxAge = true, GrowRateMulti = true, WeightMulti = true,
		DoneGrowTime = true, FruitSpawnIndex = true, OfflineGrowthTarget = true,
		MasteryGrowthMulti = true, MasterySizeMulti = true,
	}

	local function optionsFrom(names, allLabel)
		local out = { { value = "All", display = allLabel or "All" } }
		for _, n in ipairs(names) do out[#out + 1] = { value = n, display = n } end
		return out
	end

	-- iterasi plant di kebun MILIK SENDIRI. KRITIS: shovel nyabut tanaman -> JANGAN sampai
	-- kena kebun pemain lain. Semua garden namanya "Farm", dibedain lewat Important.Data.Owner.
	local function myGarden()
		local ok, GetFarm = pcall(function() return require(RS.Modules.GetFarm) end)
		if ok and GetFarm then local ok2, f = pcall(function() return GetFarm(LP) end); if ok2 and f then return f end end
		local Farm = workspace:FindFirstChild("Farm"); if not Farm then return nil end
		for _, g in ipairs(Farm:GetChildren()) do
			local d = g:FindFirstChild("Important") and g.Important:FindFirstChild("Data")
			local o = d and d:FindFirstChild("Owner")
			if o and o.Value == LP.Name then return g end
		end
		return nil
	end
	local function eachPlant(fn)
		local g = myGarden(); local imp = g and g:FindFirstChild("Important")
		local pp = imp and imp:FindFirstChild("Plants_Physical")
		if not pp then return end
		for _, plant in ipairs(pp:GetChildren()) do fn(plant) end
	end

	-- shovel SELURUH plant (Remove_Item di part plant)
	local function shovel(plant)
		local part = plant.PrimaryPart or plant:FindFirstChildWhichIsA("BasePart")
		if part then pcall(function() Remove:FireServer(part) end) end
	end
	-- shovel 1 BUAH aja (Remove_Item di part buah -> plant tetap)
	local function shovelFruit(fruit)
		local part = fruit.PrimaryPart or fruit:FindFirstChildWhichIsA("BasePart")
		if part then pcall(function() Remove:FireServer(part) end) end
	end

	----------------------------------------------------------------- opsi (buat UI)
	local function catalog()
		local ok, t = pcall(function() return require(RS.Data.SeedShopData) end)
		local names = {}
		if ok and type(t) == "table" then
			for k in pairs(t) do local n = tostring(k); if n ~= "RefreshTime" and n ~= "Gear" then names[#names + 1] = n end end
			table.sort(names)
		end
		return names
	end
	function ctx.getShovelTreeOptions()  return optionsFrom(catalog(), "All (semua plant)") end
	function ctx.getShovelFruitOptions() return optionsFrom(catalog(), "All (semua fruit)") end
	function ctx.getShovelVariantOptions()
		-- kumpulin variant yg ADA di garden + base
		local set = { Normal = true, Gold = true, Rainbow = true }
		eachPlant(function(plant)
			local fr = plant:FindFirstChild("Fruits")
			if fr then for _, f in ipairs(fr:GetChildren()) do
				local v = f:FindFirstChild("Variant"); if v and v.Value ~= "" then set[tostring(v.Value)] = true end
			end end
		end)
		local names = {} for k in pairs(set) do names[#names + 1] = k end; table.sort(names)
		return optionsFrom(names, "All (semua variant)")
	end
	function ctx.getShovelMutationOptions()
		-- daftar LENGKAP semua mutasi buah dari registry (MutationHandler.MutationNames)
		local ok, MH = pcall(function() return require(RS.Modules.MutationHandler) end)
		local names = {}
		if ok and MH and type(MH.MutationNames) == "table" then
			local mn = MH.MutationNames
			if mn[1] ~= nil then for _, v in ipairs(mn) do names[#names + 1] = tostring(v) end
			else for k in pairs(mn) do names[#names + 1] = tostring(k) end end
			table.sort(names)
		end
		return optionsFrom(names, "All (semua mutasi)")
	end
	function ctx.getShovelModeOptions() return { ">= (berat minimal)", "<= (berat maksimal)" } end

	----------------------------------------------------------------- cek fruit cocok filter
	local function fruitMatches(f)
		local sel  = CFG.shovelFruitNames or {}
		local muts = CFG.shovelFruitMuts or {}
		local vars = CFG.shovelFruitVariants or {}
		-- tipe
		if not (next(sel) == nil or sel["All"] or sel[f.Name]) then return false end
		-- variant
		if not (next(vars) == nil or vars["All"]) then
			local fv = f:FindFirstChild("Variant")
			local vn = fv and tostring(fv.Value) or "Normal"
			if not vars[vn] then return false end
		end
		-- mutasi (fruit harus punya salah satu mutasi terpilih)
		if not (next(muts) == nil or muts["All"]) then
			local hit = false
			for m in pairs(muts) do if m ~= "All" and f:GetAttribute(m) == true then hit = true; break end end
			if not hit then return false end
		end
		-- berat vs threshold
		local thr = tonumber(CFG.shovelFruitWeight) or 0
		if thr > 0 then
			local w = f:FindFirstChild("Weight")
			local wv = w and tonumber(w.Value) or 0
			local mode = CFG.shovelFruitMode or ">="
			if mode:find("<=") then if not (wv <= thr) then return false end
			else if not (wv >= thr) then return false end end
		end
		return true
	end

	----------------------------------------------------------------- loop: shovel tree/plant
	local function treeLoop()
		ctx.state.shovelTreeId = (ctx.state.shovelTreeId or 0) + 1
		local myId = ctx.state.shovelTreeId
		ctx.elevate()
		while CFG.shovelTreeEnabled and ctx.alive() and ctx.state.shovelTreeId == myId do
			if not equipShovel() then
				ctx.setStatus("Auto Shovel Tree: Shovel ga ada / gagal equip")
				task.wait(math.max(1, tonumber(CFG.shovelTreeDelay) or 0))
			else
				local sel = CFG.shovelTreeNames or {}
				local all = sel["All"]
				local n = 0
				eachPlant(function(plant)
					if not CFG.shovelTreeEnabled or ctx.state.shovelTreeId ~= myId then return end
					if all or sel[plant.Name] then
						shovel(plant); n = n + 1; task.wait(0.12)
					end
				end)
				ctx.setStatus(("Auto Shovel Tree: cabut %d plant"):format(n))
				task.wait(math.max(0.5, tonumber(CFG.shovelTreeDelay) or 0) + 0.5)
			end
		end
	end

	----------------------------------------------------------------- loop: shovel fruit
	local function fruitLoop()
		ctx.state.shovelFruitId = (ctx.state.shovelFruitId or 0) + 1
		local myId = ctx.state.shovelFruitId
		ctx.elevate()
		while CFG.shovelFruitEnabled and ctx.alive() and ctx.state.shovelFruitId == myId do
			if not equipShovel() then
				ctx.setStatus("Auto Shovel Fruit: Shovel ga ada / gagal equip")
				task.wait(math.max(1, tonumber(CFG.shovelFruitDelay) or 0))
			else
				local n = 0
				eachPlant(function(plant)
					if not CFG.shovelFruitEnabled or ctx.state.shovelFruitId ~= myId then return end
					local fr = plant:FindFirstChild("Fruits")
					if not fr then return end
					-- hapus TIAP buah yg cocok filter (plant tetap ada)
					for _, f in ipairs(fr:GetChildren()) do
						if not CFG.shovelFruitEnabled or ctx.state.shovelFruitId ~= myId then break end
						if fruitMatches(f) then shovelFruit(f); n = n + 1; task.wait(0.12) end
					end
				end)
				ctx.setStatus(("Auto Shovel Fruit: cabut %d buah"):format(n))
				task.wait(math.max(0.5, tonumber(CFG.shovelFruitDelay) or 0) + 0.5)
			end
		end
	end

	function ctx.startShovelTree()  equipShovel(); ensureGuard(); task.spawn(treeLoop) end
	function ctx.stopShovelTree()   ctx.state.shovelTreeId = (ctx.state.shovelTreeId or 0) + 1 end
	function ctx.startShovelFruit() equipShovel(); ensureGuard(); task.spawn(fruitLoop) end
	function ctx.stopShovelFruit()  ctx.state.shovelFruitId = (ctx.state.shovelFruitId or 0) + 1 end
end
]=],
	["modules/farm/automation_sprinkler.lua"] = [=[
--[[ automation_sprinkler.lua — Auto Sprinkler + Sprinkler Shovel (Farm).
     Pasang sprinkler:  equip tool sprinkler -> SprinklerService:FireServer("Create", CFrame)
     Cabut sprinkler:   equip Shovel        -> DeleteObject:FireServer(sprinklerModel)
     Sprinkler & jumlah dari Backpack tool "<Nama> Sprinkler x<jumlah>".
     Posisi pasang: kalau "Sprinkler Plants" dipilih -> di posisi plant itu;
                    kalau kosong -> Position mode (Random / Player Position).
     Fungsi: ctx.getSprinklerOptions / ctx.getSprinklerPlantOptions /
             ctx.getShovelSprinklerOptions / ctx.startSprinkler / ctx.startShovelSprinkler ]]
return function(ctx)
	local LP  = ctx.LP
	local CFG = ctx.CFG
	local RS  = game:GetService("ReplicatedStorage")
	local GE  = RS:WaitForChild("GameEvents")
	local SprinklerService = GE:WaitForChild("SprinklerService")
	local DeleteObject     = GE:WaitForChild("DeleteObject")
	local function setStatus(s) ctx.setStatus(s) end

	local function myFarm()
		local ok, GetFarm = pcall(function() return require(RS.Modules.GetFarm) end)
		if ok and GetFarm then local ok2, f = pcall(function() return GetFarm(LP) end); if ok2 then return f end end
		return nil
	end
	local function important() local f = myFarm(); return f and f:FindFirstChild("Important") end
	local function plantsFolder() local imp = important(); return imp and imp:FindFirstChild("Plants_Physical") end
	local function objectsFolder() local imp = important(); return imp and imp:FindFirstChild("Objects_Physical") end
	local function canPlantParts()
		local imp = important(); local pl = imp and imp:FindFirstChild("Plant_Locations")
		local parts = {}
		if pl then for _, p in ipairs(pl:GetChildren()) do if p:IsA("BasePart") then parts[#parts + 1] = p end end end
		return parts
	end

	----------------------------------------------------------------- inventory sprinkler
	local function sprinklerBase(t) return t:IsA("Tool") and t.Name:match("^(.- Sprinkler) x%d+") or nil end
	-- name -> jumlah (dari Backpack + Character)
	local function sprinklerInventory()
		local out = {}
		for _, where in ipairs({ LP:FindFirstChild("Backpack"), LP.Character }) do
			if where then for _, t in ipairs(where:GetChildren()) do
				local b = sprinklerBase(t)
				if b then out[b] = (out[b] or 0) + (tonumber(t.Name:match("x(%d+)$")) or 0) end
			end end
		end
		return out
	end
	local function sprinklerOptions()
		local inv = sprinklerInventory()
		-- prune sprinkler terpilih yg stok-nya udah 0
		local sel = CFG.sprinklerNames
		if type(sel) == "table" then
			local changed = false
			for nm in pairs(sel) do if (inv[nm] or 0) <= 0 then sel[nm] = nil; changed = true end end
			if changed and ctx.persistState then pcall(ctx.persistState) end
		end
		local names = {}
		for n, q in pairs(inv) do if q > 0 then names[#names + 1] = n end end
		table.sort(names)
		local out = {}
		for _, n in ipairs(names) do out[#out + 1] = { value = n, display = ("%s (%d)"):format(n, inv[n]) } end
		return out
	end
	ctx.getSprinklerOptions = sprinklerOptions

	-- jenis plant unik di garden (buat "place near plants") + "All"
	function ctx.getSprinklerPlantOptions()
		local out = { { value = "All", display = "All (semua plant)" } }
		local pf = plantsFolder()
		if pf then
			local seen, names = {}, {}
			for _, m in ipairs(pf:GetChildren()) do if m.Name and not seen[m.Name] then seen[m.Name] = true; names[#names + 1] = m.Name end end
			table.sort(names)
			for _, n in ipairs(names) do out[#out + 1] = { value = n, display = n } end
		end
		return out
	end

	-- Opsi shovel: gabungan jenis sprinkler yg kamu punya (inventory) + yg lagi
	-- terpasang, + "All". Daftar dari inventory bikin stabil (ga ilang pas objek
	-- expire). Sekalian prune pilihan yg jenisnya udah ga ada sama sekali.
	function ctx.getShovelSprinklerOptions()
		local set = {}
		for n in pairs(sprinklerInventory()) do set[n] = true end
		local of = objectsFolder()
		if of then for _, o in ipairs(of:GetChildren()) do
			local ty = o:GetAttribute("OBJECT_TYPE") or o.Name
			if ty then set[ty] = true end
		end end
		local sel = CFG.shovelSprinklerNames
		if type(sel) == "table" then
			local changed = false
			for nm in pairs(sel) do if nm ~= "All" and not set[nm] then sel[nm] = nil; changed = true end end
			if changed and ctx.persistState then pcall(ctx.persistState) end
		end
		local names = {}
		for n in pairs(set) do names[#names + 1] = n end
		table.sort(names)
		local out = { { value = "All", display = "All (semua terpasang)" } }
		for _, n in ipairs(names) do out[#out + 1] = { value = n, display = n } end
		return out
	end

	----------------------------------------------------------------- equip helper
	local function heldName() local c = LP.Character; local t = c and c:FindFirstChildOfClass("Tool"); return t and t.Name end
	local function equipByPredicate(pred)
		local c = LP.Character
		if c then for _, t in ipairs(c:GetChildren()) do if t:IsA("Tool") and pred(t) then return true end end end
		local bp = LP:FindFirstChild("Backpack")
		if bp then for _, t in ipairs(bp:GetChildren()) do if t:IsA("Tool") and pred(t) then
			local hum = c and c:FindFirstChildOfClass("Humanoid"); if hum then pcall(function() hum:EquipTool(t) end) end
			break
		end end end
		if c then for _, t in ipairs(c:GetChildren()) do if t:IsA("Tool") and pred(t) then return true end end end
		return false
	end
	local function equipSprinkler(name) return equipByPredicate(function(t) return sprinklerBase(t) == name end) end
	local function equipShovel() return equipByPredicate(function(t) return t.Name == "Shovel [Destroy Plants]" or t.Name:match("^Shovel") end) end

	----------------------------------------------------------------- posisi
	local function randomPos()
		local parts = canPlantParts(); if #parts == 0 then return nil end
		local p = parts[math.random(1, #parts)]
		local hx, hz = p.Size.X / 2 - 1, p.Size.Z / 2 - 1
		return Vector3.new(p.Position.X + (math.random() * 2 - 1) * hx, p.Position.Y, p.Position.Z + (math.random() * 2 - 1) * hz)
	end
	local function playerPos()
		local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"); if not hrp then return nil end
		local parts = canPlantParts(); local y = parts[1] and parts[1].Position.Y or 0
		return Vector3.new(hrp.Position.X, y, hrp.Position.Z)
	end
	-- posisi plant yg tipenya dipilih (buat "place near plants")
	local function plantPositions(sel)
		local out = {}
		local pf = plantsFolder(); if not pf then return out end
		local all = sel["All"]
		for _, m in ipairs(pf:GetChildren()) do
			if all or sel[m.Name] then
				local piv = m:GetPivot(); out[#out + 1] = Vector3.new(piv.X, piv.Y, piv.Z)
			end
		end
		return out
	end

	----------------------------------------------------------------- loop PASANG
	local function sprinklerLoop(myId)
		ctx.elevate()
		while CFG.sprinklerEnabled and ctx.alive() and ctx.state.sprinklerId == myId do
			local selSpr = CFG.sprinklerNames or {}
			local inv = sprinklerInventory()
			-- daftar tipe sprinkler terpilih yg masih ada stok (urut stabil)
			local types = {}
			for n in pairs(selSpr) do if (inv[n] or 0) > 0 then types[#types + 1] = n end end
			table.sort(types)
			if #types == 0 then
				setStatus("Sprinkler: pilih sprinkler (stok kosong?)")
			else
				-- posisi target
				local plantsSel = CFG.sprinklerPlantNames or {}
				local positions
				if next(plantsSel) then
					positions = plantPositions(plantsSel)
				else
					local mode = CFG.sprinklerPosition == "Player Position" and "Player Position" or "Random"
					positions = { mode == "Player Position" and playerPos() or randomPos() }
				end
				local placed = 0
				for _, pos in ipairs(positions) do
					if not CFG.sprinklerEnabled or ctx.state.sprinklerId ~= myId then break end
					if pos then
						-- rotasi 1-1 antar tipe, indeks persist antar-siklus (biar ga tipe pertama terus)
						ctx.state.sprRotIdx = (ctx.state.sprRotIdx or 0) % #types + 1
						local name = types[ctx.state.sprRotIdx]
						if equipSprinkler(name) then
							pcall(function() SprinklerService:FireServer("Create", CFrame.new(pos)) end)
							placed = placed + 1
							task.wait(tonumber(CFG.sprinklerDelay) or 0)
						end
					end
				end
				setStatus(("Sprinkler: pasang %d"):format(placed))
			end
			task.wait(1)
		end
	end
	function ctx.startSprinkler()
		ctx.state.sprinklerId = (ctx.state.sprinklerId or 0) + 1
		local myId = ctx.state.sprinklerId
		task.spawn(function() sprinklerLoop(myId) end)
	end

	----------------------------------------------------------------- loop CABUT (shovel)
	local function shovelLoop(myId)
		ctx.elevate()
		while CFG.shovelSprinklerEnabled and ctx.alive() and ctx.state.shovelSprId == myId do
			local sel = CFG.shovelSprinklerNames or {}
			local of = objectsFolder()
			if of and next(sel) then
				local all = sel["All"]
				equipShovel()
				local removed = 0
				for _, o in ipairs(of:GetChildren()) do
					if not CFG.shovelSprinklerEnabled or ctx.state.shovelSprId ~= myId then break end
					local ty = o:GetAttribute("OBJECT_TYPE") or o.Name
					if all or sel[ty] then
						pcall(function() DeleteObject:FireServer(o) end)
						removed = removed + 1
						task.wait(tonumber(CFG.shovelSprinklerDelay) or 0)
					end
				end
				setStatus(("Shovel Sprinkler: cabut %d"):format(removed))
			else
				setStatus("Shovel Sprinkler: pilih sprinkler dulu")
			end
			task.wait(1)
		end
	end
	function ctx.startShovelSprinkler()
		ctx.state.shovelSprId = (ctx.state.shovelSprId or 0) + 1
		local myId = ctx.state.shovelSprId
		task.spawn(function() shovelLoop(myId) end)
	end
end
]=],
	["modules/farm/automation_water.lua"] = [=[
--[[ automation_water.lua — Auto Water Fruits.
     Siram plant terpilih pakai Watering Can. Mekanisme (dari remote spy):
       Water_RE:FireServer(plant:GetPivot().Position)
     Ga perlu equip can — server auto-decrement uses dari Watering Can di inventory.
     Loop tiap CFG.waterDelay detik, cuma siram plant yang tipenya ada di CFG.waterFruitNames
     (atau "All"). Plant ada di workspace.Farm.<garden>.Important.Plants_Physical (nama = tipe fruit). ]]
return function(ctx)
	local RS  = game:GetService("ReplicatedStorage")
	local CFG = ctx.CFG
	local LP  = ctx.LP
	local Water = RS:WaitForChild("GameEvents"):WaitForChild("Water_RE")

	-- cari Watering Can (prioritas regular = uses banyak; fallback Super/Sugar/apapun)
	local function findCan()
		local best, fallback
		for _, where in ipairs({ LP.Character, LP:FindFirstChildOfClass("Backpack") }) do
			if where then
				for _, t in ipairs(where:GetChildren()) do
					local n = tostring(t.Name)
					if t:IsA("Tool") and n:find("Watering Can") then
						if not n:find("Super") and not n:find("Sugar") then best = best or t
						else fallback = fallback or t end
					end
				end
			end
		end
		return best or fallback
	end

	local function heldCan()
		local char = LP.Character
		if not char then return nil end
		for _, t in ipairs(char:GetChildren()) do
			if t:IsA("Tool") and tostring(t.Name):find("Watering Can") then return t end
		end
	end
	-- pastiin Watering Can ke-equip (server nyiram cuma pas can dipegang)
	local function equipCan()
		local char = LP.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hum then return false end
		if heldCan() then return true end
		local can = findCan()
		if not can then return false end
		pcall(function() hum:EquipTool(can) end)
		task.wait(0.2)
		return heldCan() ~= nil
	end

	-- Guard (mirip reclaimer): selama auto water aktif, Watering Can WAJIB tetap kepegang.
	-- Kalau user pindah manual ke tool lain, langsung equip ulang (cek 0.25s).
	local guardRunning = false
	local function ensureGuard()
		if guardRunning then return end
		guardRunning = true
		task.spawn(function()
			while CFG.waterEnabled and ctx.alive() do
				if not heldCan() then equipCan() end
				task.wait(0.25)
			end
			guardRunning = false
		end)
	end

	-- opsi fruit = katalog seed (semua yang bisa ditanam). Format sama kayak shop.
	local function optionsFrom(names)
		local out = { { value = "All", display = "All (siram semua)" } }
		for _, n in ipairs(names) do out[#out + 1] = { value = n, display = n } end
		return out
	end
	function ctx.getWaterFruitOptions()
		local ok, t = pcall(function() return require(RS.Data.SeedShopData) end)
		local names = {}
		if ok and type(t) == "table" then
			for k in pairs(t) do
				local n = tostring(k)
				if n ~= "RefreshTime" and n ~= "Gear" then names[#names + 1] = n end
			end
			table.sort(names)
		end
		return optionsFrom(names)
	end

	-- iterasi plant di kebun MILIK SENDIRI. Semua garden namanya "Farm", dibedain lewat
	-- Important.Data.Owner -> skip-CommunityGarden aja kesapu kebun pemain lain (bug).
	local function myGarden()
		local ok, GetFarm = pcall(function() return require(RS.Modules.GetFarm) end)
		if ok and GetFarm then local ok2, f = pcall(function() return GetFarm(LP) end); if ok2 and f then return f end end
		local Farm = workspace:FindFirstChild("Farm"); if not Farm then return nil end
		for _, g in ipairs(Farm:GetChildren()) do
			local d = g:FindFirstChild("Important") and g.Important:FindFirstChild("Data")
			local o = d and d:FindFirstChild("Owner")
			if o and o.Value == LP.Name then return g end
		end
		return nil
	end
	local function eachPlant(fn)
		local g = myGarden(); local imp = g and g:FindFirstChild("Important")
		local pp = imp and imp:FindFirstChild("Plants_Physical")
		if not pp then return end
		for _, plant in ipairs(pp:GetChildren()) do fn(plant) end
	end

	local function waterLoop()
		ctx.state.waterId = (ctx.state.waterId or 0) + 1
		local myId = ctx.state.waterId
		ctx.elevate()
		while CFG.waterEnabled and ctx.alive() and ctx.state.waterId == myId do
			local sel = CFG.waterFruitNames or {}
			local all = sel["All"]
			local n = 0
			-- equip can dulu; kalau ga ada, kasih tau & tunggu
			if not equipCan() then
				ctx.setStatus("Auto Water: Watering Can ga ada / gagal equip")
				task.wait(math.max(1, tonumber(CFG.waterDelay) or 1))
			else
			eachPlant(function(plant)
				if not CFG.waterEnabled or ctx.state.waterId ~= myId then return end
				if all or sel[plant.Name] then
					local ok, pos = pcall(function() return plant:GetPivot().Position end)
					if ok and pos then
						pcall(function() Water:FireServer(pos) end)
						n = n + 1
						task.wait(0.05) -- jeda antar-fire biar ga flood remote
					end
				end
			end)
				ctx.setStatus(("Auto Water: siram %d plant"):format(n))
				task.wait(math.max(0.5, tonumber(CFG.waterDelay) or 1))
			end
		end
	end

	function ctx.startWater() equipCan(); ensureGuard(); task.spawn(waterLoop) end
	function ctx.stopWater() ctx.state.waterId = (ctx.state.waterId or 0) + 1 end
end
]=],
	["modules/growth/automation_growth.lua"] = [=[
--[[ growth.lua — Growth pipeline (BATCH per-step): jalankan target pet lewat urutan
     step (default Elephant -> Mutation -> Leveling), semua pet kelar 1 step baru lanjut.
     Config TERPISAH dari fitur standalone (growth*).
     Step & kriteria "complete":
       elephant : BaseWeight >= growthElephantWeight
       mutation : dapat salah satu growthMutationTargets (aura team; mutasi salah -> shard)
       leveling : Level >= growthLevP2Target (2 phase: P1 team -> P2 team)
     Saat ganti step/phase: bersihin garden TOTAL dulu -> pasang team baru (lengkap) -> proses. ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local PetsService = ctx.deps.PetsService
	local CFG = ctx.CFG
	local LP  = ctx.LP
	local RS  = game:GetService("ReplicatedStorage")
	local PetShardService = RS:WaitForChild("GameEvents"):WaitForChild("PetShardService_RE")
	local mutDisplay = (ctx.reg and ctx.reg.mutDisplay) or function(c) return c end

	----------------------------------------------------------------- posisi grid
	local function farmCenter()
		local GetFarm = require(RS.Modules.GetFarm)
		local farm = GetFarm and GetFarm(LP)
		local pa = farm and farm:FindFirstChild("PetArea")
		if pa then return pa.Position end
		local char = LP.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		return hrp and hrp.Position or nil
	end
	local slotOf, nextSlot = {}, 0
	local function getPos(uuid)
		if not slotOf[uuid] then slotOf[uuid] = nextSlot; nextSlot = nextSlot + 1 end
		local center = farmCenter(); if not center then return nil end
		local i = slotOf[uuid]
		return center + Vector3.new((i % 6 - 2.5) * 3, 0, (math.floor(i / 6) - 1) * 3)
	end

	----------------------------------------------------------------- helper mutasi/shard
	-- pet yang di-favorite JANGAN diproses & JANGAN dihitung di step manapun
	-- (elephant/mutation/leveling). Kalau ikut dihitung, pet fav yg ga pernah beres
	-- bikin step "belum semua selesai" selamanya -> growth mandek.
	local function isFav(pd) return (pd or {}).IsFavorite == true end
	local function matchesType(typeSet, pt, pd)
		if ctx.petMatchesType then return ctx.petMatchesType(typeSet, pt, pd) end
		return typeSet and typeSet[pt] == true
	end
	-- Flow efektif: buang step kosong/"none" (mis. cuma mau Mutation+Leveling, Step 3 dikosongin).
	local function effFlow()
    	local out = {}
    	local validSteps = {
        	elephant = true,
        	mutation = true,
        	leveling = true,
        	leveling_p1 = true,
        	leveling_p2 = true,
    	}
    	for _, s in ipairs(CFG.growthFlow or {}) do
        	if validSteps[s] then
            	out[#out + 1] = s
        	end
    	end
    	return out
	end
	-- Target pet PER-METHOD: tiap step bisa punya target beda (mis. leveling: Dilo/
	-- Lion/Mimic, mutation: Hotdog/Griffin/Mimic). Kalau set per-step kosong ->
	-- fallback ke growthPetTypes (global). Backward-compatible.
	local function typesFor(step)
    	local per
    	if step == "elephant" then
        	per = CFG.growthPetTypesElephant
    	elseif step == "mutation" then
        	per = CFG.growthPetTypesMutation
    	elseif step == "leveling_p1" then
        	per = CFG.growthPetTypesLeveling
        	if not (per and next(per)) and CFG.growthPetTypesElephant and next(CFG.growthPetTypesElephant) then
            	per = CFG.growthPetTypesElephant
        	end
    	elseif step == "leveling" or step == "leveling_p2" then
        	per = CFG.growthPetTypesLeveling
    	end
    	if per and next(per) then return per end
    	return CFG.growthPetTypes or {}
	end
	-- ada target ke-set di mana pun (global / salah satu per-step)?
	local function anyTypesSet()
		if next(CFG.growthPetTypes or {}) then return true end
		return next(CFG.growthPetTypesElephant or {}) or next(CFG.growthPetTypesMutation or {})
			or next(CFG.growthPetTypesLeveling or {}) or false
	end
	local function mutOf(pd) return mutDisplay((pd or {}).MutationType) end
	local function hasMut(pd)
		local m = (pd or {}).MutationType
		return m ~= nil and m ~= "" and m ~= "None" and m ~= "Normal"
	end
	local function findShard()
		for _, where in ipairs({ LP.Character, LP:FindFirstChildOfClass("Backpack") }) do
			if where then
				for _, t in ipairs(where:GetChildren()) do
					if t:IsA("Tool") and (t:HasTag("PetShardTool") or tostring(t.Name):find("Cleansing Pet Shard")) then return t end
				end
			end
		end
	end
	local function findPetModel(uuid)
		local pm = workspace:FindFirstChild("PetsPhysical")
		if not pm then return nil end
		for _, mover in ipairs(pm:GetChildren()) do
			local m = mover:FindFirstChild(uuid); if m then return m end
		end
	end
	local function cleansePet(uuid)
		local model = findPetModel(uuid); if not model then return end
		local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
		local shard = findShard()
		if hum and shard then pcall(function() hum:EquipTool(shard) end); task.wait(0.3) end
		local held = LP.Character and LP.Character:FindFirstChildWhichIsA("Tool")
		if held and (held:HasTag("PetShardTool") or tostring(held.Name):find("Cleansing Pet Shard")) then
			pcall(function() PetShardService:FireServer("ApplyShard", model) end)
			task.wait(0.3)
		end
	end

	----------------------------------------------------------------- kriteria complete per step
	local function stepDone(step, pd)
    	pd = pd or {}
    	if step == "elephant" then
        	return (pd.BaseWeight or 0) >= (CFG.growthElephantWeight or 3.845)
    	elseif step == "mutation" then
        	local tg = CFG.growthMutationTargets or {}
        	if not next(tg) then return true end
        	return tg[mutOf(pd)] == true
    	elseif step == "leveling" then
        	return (pd.Level or 0) >= (CFG.growthLevP2Target or 500)
    	elseif step == "leveling_p1" then
        	return (pd.Level or 0) >= (CFG.growthLevP1Target or 50)
    	elseif step == "leveling_p2" then
        	return (pd.Level or 0) >= (CFG.growthLevP2Target or 500)
    	end
    	return true
	end

	ctx.state.growthStatus = "Idle"

	----------------------------------------------------------------- ringkasan status
	function ctx.getGrowthSummary()
		local ok, d = pcall(function() return DataService:GetData() end)
		local inv = ok and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}
		local flow = effFlow()
		local perStep = {}
		for _, s in ipairs(flow) do perStep[s] = { done = 0, total = 0 } end
		for _, v in pairs(inv) do
			if not isFav(v.PetData) and v.PetData then   -- skip pet tanpa PetData
				for _, s in ipairs(flow) do
					if matchesType(typesFor(s), v.PetType, v.PetData) then
						perStep[s].total = perStep[s].total + 1
						if stepDone(s, v.PetData) then perStep[s].done = perStep[s].done + 1 end
					end
				end
			end
		end
		local function nm(t) local o = {}; for k in pairs(t or {}) do o[#o + 1] = k end; return #o > 0 and table.concat(o, ", ") or "-" end
		-- label target: kalau ada per-method di-set -> "E:.. | M:.. | L:..", else global.
		local function typesLabel()
			local e, m, l = CFG.growthPetTypesElephant or {}, CFG.growthPetTypesMutation or {}, CFG.growthPetTypesLeveling or {}
			if not (next(e) or next(m) or next(l)) then return nm(CFG.growthPetTypes) end
			return ("E:%s | M:%s | L:%s"):format(nm(typesFor("elephant")), nm(typesFor("mutation")), nm(typesFor("leveling")))
		end
		-- ringkas team: hitung per tipe pet -> "Peacock x3, Dog x2" (biar ga kepanjangan)
		local function teamNm(teamSet)
			local count, order, total = {}, {}, 0
			for uuid in pairs(teamSet or {}) do
				local v = inv[uuid]
				local pt = (v and v.PetType) or "?"
				if not count[pt] then order[#order + 1] = pt end
				count[pt] = (count[pt] or 0) + 1
				total = total + 1
			end
			if total == 0 then return "-" end
			local parts = {}
			for _, pt in ipairs(order) do
				parts[#parts + 1] = count[pt] > 1 and (pt .. " x" .. count[pt]) or pt
			end
			return ("(%d) %s"):format(total, table.concat(parts, ", "))
		end
		return {
			status = CFG.growthEnabled and "ACTIVE" or "STOPPED",
			step = ctx.state.growthStep or "-",
			flow = (#flow > 0) and table.concat(flow, " -> ") or "-",
			types = typesLabel(),
			perStep = perStep,
			teamElephant = teamNm(CFG.growthElephantTeam),
			teamMutation = teamNm(CFG.growthMutationTeam),
			teamLevP1 = teamNm(CFG.growthLevP1Team),
			teamLevP2 = teamNm(CFG.growthLevP2Team),
		}
	end

	----------------------------------------------------------------- core check
	local function checkGrowth()
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d or not d.PetsData then return end
		local eq  = d.PetsData.EquippedPets or {}
		local inv = d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}
		local flow = effFlow()
		if not anyTypesSet() or #flow == 0 then
			ctx.state.growthStatus = "Growth: set target pet & flow dulu"
			return
		end

		-- STEP AKTIF = step pertama di flow yg belum selesai.
		-- Flow yang umum: leveling_p1 -> elephant -> leveling / mutation
		-- Di tahap elephant, pet levelnya ter-reset (level turun). Setelah semua pet level 50
		-- di-boost elephant dan levelnya reset, elephant tidak ada lagi target siap (level 50).
		-- Jika masih ada target pet yang belum capai target weight, sistem otomatis balik ke leveling_p1.
		local step, stepIdx
		local p1Target = CFG.growthLevP1Target or 50
		local hasElephantInFlow = false
		local hasLevP1InFlow = false
		for _, s in ipairs(flow) do
			if s == "elephant" then hasElephantInFlow = true end
			if s == "leveling_p1" then hasLevP1InFlow = true end
		end

		-- Jika flow mengandung siklus leveling_p1 + elephant:
		if hasElephantInFlow and hasLevP1InFlow then
			local tyEle = typesFor("elephant")
			local tyP1 = typesFor("leveling_p1")

			local anyNeedWeight = false
			local anyReadyLevel50 = false
			local anyNeedLevel50 = false

			for _, v in pairs(inv) do
				if v.PetData and not isFav(v.PetData) then
					local pd = v.PetData
					local lvl = pd.Level or 0
					-- Cek apakah pet target elephant butuh up weight
					if (matchesType(tyEle, v.PetType, pd) or matchesType(tyP1, v.PetType, pd)) and not stepDone("elephant", pd) then
						anyNeedWeight = true
						if lvl >= p1Target then
							anyReadyLevel50 = true
						else
							anyNeedLevel50 = true
						end
					end
				end
			end

			-- Tentukan step untuk fase siklus elephant / leveling_p1:
			local cycleStep = nil
			if anyNeedWeight then
				local cyclePhase = ctx.state.growthCyclePhase
				if not cyclePhase then
					-- Initial phase: kalau semua pet target sudah level 50 -> langsung elephant, kalau ada yg belum -> leveling_p1
					if anyReadyLevel50 and not anyNeedLevel50 then
						cyclePhase = "elephant"
					else
						cyclePhase = "leveling_p1"
					end
				end

				if cyclePhase == "leveling_p1" then
					-- Tetap di leveling_p1 sampai SEMUA pet target (yg butuh weight) sudah level >= 50
					if not anyNeedLevel50 then
						-- Selesai semua leveling_p1! Switch ke elephant
						cyclePhase = "elephant"
					end
				elseif cyclePhase == "elephant" then
					-- Tetap di elephant sampai TIDAK ADA LAGI pet level >= 50 (semua sudah ter-reset)
					if not anyReadyLevel50 then
						-- Semua pet level 50 sudah di-boost & ter-reset! Switch balik ke leveling_p1
						cyclePhase = "leveling_p1"
					end
				end
				ctx.state.growthCyclePhase = cyclePhase
				cycleStep = cyclePhase
			else
				ctx.state.growthCyclePhase = nil
			end

			for i, s in ipairs(flow) do
				if s == "leveling_p1" or s == "elephant" then
					if anyNeedWeight then
						-- Masih dalam proses weight: pilih step sesuai status kesiapan
						if s == cycleStep then
							step, stepIdx = s, i
							break
						end
						-- Jika bukan cycleStep, lewati
					else
						-- Weight sudah beres semua! leveling_p1 & elephant dianggap done, lanjut ke step berikutnya (mutation/leveling)
					end
				else
					-- Step lain (mutation, leveling, leveling_p2, dll)
					local ty = typesFor(s)
					local allDone = true
					for _, v in pairs(inv) do
						if matchesType(ty, v.PetType, v.PetData) and v.PetData and not isFav(v.PetData) and not stepDone(s, v.PetData) then
							allDone = false
							break
						end
					end
					if not allDone then
						step, stepIdx = s, i
						break
					end
				end
			end
		else
			-- Flow standar tanpa kombinasi leveling_p1 + elephant
			for i, s in ipairs(flow) do
				local ty = typesFor(s)
				local allDone = true
				for _, v in pairs(inv) do
					if matchesType(ty, v.PetType, v.PetData) and v.PetData and not isFav(v.PetData) and not stepDone(s, v.PetData) then
						allDone = false; break
					end
				end
				if not allDone then step, stepIdx = s, i; break end
			end
		end

		if not step then
			ctx.state.growthStep = "SELESAI"
			ctx.state.growthStatus = "Growth: semua step selesai ✓"
			if ctx.state.growthClearKey ~= "__done" then ctx.state.growthClearKey = "__done"; if ctx.clearGarden then ctx.clearGarden("Growth") end end
			return
		end

		-- target pet buat step aktif ini (per-method / fallback global)
		local types = typesFor(step)

		-- team / max / kriteria "masih perlu diproses" untuk step ini (leveling: sub-phase)
		local team, maxPets, needsWork
		local levPhase2 = false  -- true kalau step leveling lagi di Phase 2 (buat catat duration)
		local stepLabel = ("Step %d: %s"):format(stepIdx, step)
		if step == "elephant" then
			local p1Target = CFG.growthLevP1Target or 50
			team, maxPets = CFG.growthElephantTeam or {}, CFG.growthElephantMax or 2
			-- Elephant HANYA boleh ambil pet yang belum target weight DAN level >= p1Target (level 50)
			needsWork = function(pd)
				return not stepDone("elephant", pd) and (pd.Level or 0) >= p1Target
			end
		elseif step == "mutation" then
			team, maxPets = CFG.growthMutationTeam or {}, CFG.growthMutationMax or 2
			needsWork = function(pd) return not stepDone("mutation", pd) end
		elseif step == "leveling_p1" then
			local p1Target = CFG.growthLevP1Target or 50
			team, maxPets = CFG.growthLevP1Team or {}, CFG.growthLevP1Max or 3
			stepLabel = stepLabel .. " (Phase 1 - forced)"
			needsWork = function(pd)
				return (pd.Level or 0) < p1Target and not stepDone("elephant", pd)
			end
		elseif step == "leveling_p2" then
			team, maxPets = CFG.growthLevP2Team or {}, CFG.growthLevP2Max or 1
			stepLabel = stepLabel .. " (Phase 2 - forced)"
			needsWork = function(pd) return (pd.Level or 0) < (CFG.growthLevP2Target or 500) end
			levPhase2 = true
		else -- step == "leveling" (auto phase)
			local p1t = CFG.growthLevP1Target or 50
			local phase1 = false
			for _, v in pairs(inv) do
				if matchesType(types, v.PetType, v.PetData) and not isFav(v.PetData) and not stepDone("leveling", v.PetData) and ((v.PetData or {}).Level or 0) < p1t then
					phase1 = true
					break
				end
			end
			if phase1 then
				team, maxPets = CFG.growthLevP1Team or {}, CFG.growthLevP1Max or 3
				stepLabel = stepLabel .. " (Phase 1 - auto)"
				needsWork = function(pd) return (pd.Level or 0) < p1t end
			else
				team, maxPets = CFG.growthLevP2Team or {}, CFG.growthLevP2Max or 1
				stepLabel = stepLabel .. " (Phase 2 - auto)"
				needsWork = function(pd) return not stepDone("leveling", pd) end
				levPhase2 = true
			end
		end
		ctx.state.growthStep = stepLabel

		-- Kirim webhook "enabled" SEKALI pas MASUK step baru (mis. enable -> elephant duluan).
		if ctx.state.growthLastStepName ~= step then
			ctx.state.growthLastStepName = step
			if step == "elephant" and ctx.webhookElephant and ctx.webhookElephant.sendEnabled then
				pcall(function() ctx.webhookElephant.sendEnabled(ctx) end)
			end
			-- leveling: TIDAK kirim webhook "enabled" pas masuk step; cuma pas pet beres (sendFinished).
			-- mutation (aura/cleanse) ga punya sendEnabled -> notif cuma per pet dapat mutasi
		end

		local localEq = {}
		for _, uuid in ipairs(eq) do localEq[uuid] = true end

		-- Transisi step/phase -> bersihin garden TOTAL dulu (verified kosong).
		if ctx.state.growthClearKey ~= nil and ctx.state.growthClearKey ~= stepLabel then
			ctx.state.growthClearing = true
		end
		ctx.state.growthClearKey = stepLabel
		if ctx.state.growthFirstRun or ctx.state.growthClearing then
			if #eq > 0 then
				ctx.state.growthStatus = ("%s: bersihin garden (%d pet)..."):format(stepLabel, #eq)
				for _, uuid in ipairs(eq) do
					pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
					task.wait(0.1)
				end
				return
			end
			ctx.state.growthFirstRun = false
			ctx.state.growthClearing = false
		end

		-- Pasang team step ini + PASTIKAN LENGKAP dulu.
		local teamComplete = true
		for uuid in pairs(team) do
			if not localEq[uuid] then
				teamComplete = false
				local pos = getPos(uuid)
				if pos then
					pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
					task.wait(0.15)
				end
			end
		end
		if not teamComplete then
			ctx.state.growthStatus = stepLabel .. ": nunggu team lengkap..."
			return
		end

		-- Klasifikasi target pet equipped: kalau ga perlu kerja lagi -> lepas.
		-- Khusus mutation: mutasi SALAH (bukan target) -> cleanse (shard) biar coba lagi.
		local active = {}
		for uuid in pairs(localEq) do
			if not team[uuid] then
				local v = inv[uuid]
				if v and matchesType(types, v.PetType, v.PetData) then
					local pd = v.PetData or {}
					if pd.IsFavorite then
						-- Favorite -> JANGAN cleanse, JANGAN biarin di garden. Keluarkan.
						pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
						localEq[uuid] = nil
						task.wait(0.1)
					elseif needsWork(pd) then
						if step == "mutation" and hasMut(pd) and not (CFG.growthMutationTargets or {})[mutOf(pd)] then
							cleansePet(uuid) -- mutasi salah -> cleanse
						end
						table.insert(active, uuid)
						if step == "elephant" then
							ctx.state.growthElephantStart = ctx.state.growthElephantStart or {}
							if not ctx.state.growthElephantStart[uuid] then
								ctx.state.growthElephantStart[uuid] = os.time()
							end
						elseif step == "leveling" and levPhase2 then
							-- catat mulai leveling Phase 2 (buat Duration di webhook, samain v2)
							ctx.state.growthLevStart = ctx.state.growthLevStart or {}
							if not ctx.state.growthLevStart[uuid] then
								ctx.state.growthLevStart[uuid] = os.time()
							end
						end
					else
						-- pet SELESAI step ini -> kirim webhook (template per-step)
						local pt = v.PetType
						if step == "elephant" and stepDone("elephant", pd) and ctx.webhookElephant and ctx.webhookElephant.onFinished then
							-- Durasi: dari pet masuk garden (equip) sampai lepas; nil kalau ga kecatat
							local dur
							if ctx.state.growthElephantStart and ctx.state.growthElephantStart[uuid] then
								dur = os.time() - ctx.state.growthElephantStart[uuid]
								ctx.state.growthElephantStart[uuid] = nil
							end
							pcall(function() ctx.webhookElephant.onFinished(ctx, pt, pd.BaseWeight or 0) end)
							if ctx.webhookElephant.sendFinished then
								pcall(function() ctx.webhookElephant.sendFinished(ctx, pt, pd.BaseWeight or 0, pd.MutationType, pd.Level or 0, dur) end)
							end
						elseif step == "mutation" and ctx.webhookCleanse and ctx.webhookCleanse.sendObtained then
							-- aura/cleanse webhook (bukan mutasi mesin)
							local remainsM = 0
							for _, iv in pairs(inv) do
								if matchesType(types, iv.PetType, iv.PetData) and not isFav(iv.PetData) and not stepDone("mutation", iv.PetData) then remainsM = remainsM + 1 end
							end
							pcall(function() ctx.webhookCleanse.sendObtained(ctx, pt, mutOf(pd), pd.Level or 0, remainsM) end)
						elseif step == "leveling" and stepDone("leveling", pd)
							and ctx.webhookLeveling and ctx.webhookLeveling.sendFinished then
							-- CUMA Phase 2 (reached final). Phase 1 (P1Target) ga kirim.
							local remains = 0
							for _, iv in pairs(inv) do
								if matchesType(types, iv.PetType, iv.PetData) and not isFav(iv.PetData) and not stepDone("leveling", iv.PetData) then remains = remains + 1 end
							end
							-- Duration: dari pet masuk Phase 2 sampai capai target final (nil = Unknown)
							local dur
							if ctx.state.growthLevStart and ctx.state.growthLevStart[uuid] then
								dur = os.time() - ctx.state.growthLevStart[uuid]
								ctx.state.growthLevStart[uuid] = nil
							end
							pcall(function() ctx.webhookLeveling.sendFinished(ctx, pt, mutOf(pd), pd.Level or 0, dur, remains) end)
						end
						pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
						localEq[uuid] = nil
						task.wait(0.1)
					end
				else
            -- ⭐ INI PERUBAHAN PENTING: Pet bukan team dan bukan target → KELUARKAN!
            		pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
            		localEq[uuid] = nil
           			task.wait(0.1)
				end
			end
		end

		-- Tambah target pet baru yg butuh kerja di step/phase ini, sampai maxPets.
		local needed = maxPets - #active
		if needed > 0 then
			local pool = {}
			for uuid, v in pairs(inv) do
				-- skip pet tanpa PetData agar tidak masuk garden secara salah
				if not localEq[uuid] and matchesType(types, v.PetType, v.PetData) and v.PetData
					and not v.PetData.IsFavorite and needsWork(v.PetData) then
					local sortKey = v.PetData.Level or 0
					if step == "elephant" then
						sortKey = v.PetData.BaseWeight or 0
					end
					table.insert(pool, { uuid = uuid, key = sortKey })
				end
			end
			table.sort(pool, function(a, b) return a.key < b.key end)
			for i = 1, math.min(needed, #pool) do
				local pos = getPos(pool[i].uuid)
				if pos then
					pcall(function() PetsService:FireServer("EquipPet", pool[i].uuid, CFrame.new(pos)) end)
					localEq[pool[i].uuid] = true
					table.insert(active, pool[i].uuid)
					if step == "elephant" then
						ctx.state.growthElephantStart = ctx.state.growthElephantStart or {}
						ctx.state.growthElephantStart[pool[i].uuid] = os.time()
					elseif step == "leveling" and levPhase2 then
						ctx.state.growthLevStart = ctx.state.growthLevStart or {}
						ctx.state.growthLevStart[pool[i].uuid] = os.time()
					end
					task.wait(0.15)
				end
			end
		end

		ctx.state.growthStatus = ("%s: %d/%d aktif"):format(stepLabel, #active, maxPets)
	end

	----------------------------------------------------------------- loop
	local function growthLoop()
		ctx.state.growthId = (ctx.state.growthId or 0) + 1
		local myId = ctx.state.growthId
		ctx.elevate()
		ctx.state.growthFirstRun = true
		ctx.state.growthClearKey = nil
		while CFG.growthEnabled and ctx.alive() and ctx.state.growthId == myId do
			pcall(checkGrowth)
			-- pas bersihin/transisi -> cek cepat (1s) biar garden cepat bersih & lanjut;
			-- steady (proses grow/level) -> 2s (hemat, toh pet numbuh di server).
			task.wait((ctx.state.growthClearing or ctx.state.growthFirstRun) and 0.5 or 2)
		end
		ctx.state.growthStatus = "Idle"
	end

	function ctx.startGrowth()
		if ctx.cancelClearGarden then ctx.cancelClearGarden() end
		-- override config webhook elephant -> baca config GROWTH (bukan standalone)
		ctx.state.elephantCfgOverride = { team = CFG.growthElephantTeam, types = CFG.growthPetTypes, weight = CFG.growthElephantWeight }
		ctx.state.elephantWebhookPost = true -- Growth: POST pesan baru tiap pet selesai (bukan edit)
		ctx.state.growthLastStepName = nil -- reset biar step pertama kirim webhook "enabled"
		ctx.state.growthCyclePhase = nil
		task.spawn(growthLoop)
	end
	function ctx.stopGrowth()
		ctx.state.growthId = (ctx.state.growthId or 0) + 1
		ctx.state.elephantCfgOverride = nil -- balikin webhook elephant ke config standalone
		ctx.state.elephantWebhookPost = nil -- balikin webhook elephant ke mode edit (standalone)
		ctx.state.growthCyclePhase = nil
		if ctx.clearGarden then ctx.clearGarden("Growth") end
	end
end]=],
	["modules/hatch/automation_hatch.lua"] = [=[
--[[ hatch.lua — Auto Hatch + Auto Sell (Stage 1).
     - Team-swap dengan GUARD: team ga diproses kalau yg ke-equip udah sesuai.
     - Auto Hatch: equip hatch team -> hatch semua egg READY -> hitung cycle.
     - Auto Sell: pet yg COCOK filter dijual; sisanya DIFAVORITIN biar aman.
       Favorite via Favorite_Item (toggle), jual via SellPet_RE / SellAllPets_RE.
     Catatan: auto-place egg baru & bronto phase = stage berikutnya. ]]
return function(ctx)
	local RS = game:GetService("ReplicatedStorage")
	local LP = ctx.LP
	local CFG = ctx.CFG
	local DataService = ctx.deps.DataService
	local PetsRemote = RS.GameEvents.PetsService
	local FavoriteRemote = RS.GameEvents:FindFirstChild("Favorite_Item")
	local SellPet = RS.GameEvents:FindFirstChild("SellPet_RE")
	local SellAll = RS.GameEvents:FindFirstChild("SellAllPets_RE")
	local EggRemote = RS.GameEvents.PetEggService
	local FAV_KEY = "d"
	pcall(function() FAV_KEY = require(RS.Data.EnumRegistry.InventoryServiceEnums).Favorite end)

	-- LISTEN notif game = recovery ASLI (1 notif = 1 egg balik). Sumber paling akurat.
	--   Hatch: "Lucky Hatch! Your egg has been recovered."
	--   Sell : "Lucky Pet! You got a ... egg back from selling your pet!"
	do
		local g = (getgenv and getgenv()) or _G
		if g.__hatchNotifConn then pcall(function() g.__hatchNotifConn:Disconnect() end) end
		local NotifRemote = RS.GameEvents:FindFirstChild("Notification")
		if NotifRemote then
			g.__hatchNotifConn = NotifRemote.OnClientEvent:Connect(function(msg)
				if type(msg) ~= "string" or not CFG.hatchEnabled then return end
				local l = msg:lower()
				if l:find("egg has been recovered") then
					ctx.state.periodHatchRec = (ctx.state.periodHatchRec or 0) + 1
				elseif l:find("egg back from selling") then
					ctx.state.periodSellRec = (ctx.state.periodSellRec or 0) + 1
				end
			end)
		end
	end

	----------------------------------------------------------------- util
	local function getData() local ok, d = pcall(function() return DataService:GetData() end); return ok and d or nil end
	local function inventory() local d = getData(); return d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {} end
	local function equippedList() local d = getData(); return d and d.PetsData and d.PetsData.EquippedPets or {} end

	local function farmCenter()
		local GetFarm = require(RS.Modules.GetFarm)
		local farm = GetFarm and GetFarm(LP)
		local pa = farm and farm:FindFirstChild("PetArea")
		if pa then return pa.Position end
		local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
		return hrp and hrp.Position or nil
	end
	local slotOf, nextSlot = {}, 0
	local function getPos(uuid)
		if not slotOf[uuid] then slotOf[uuid] = nextSlot; nextSlot = nextSlot + 1 end
		local c = farmCenter(); if not c then return nil end
		local i = slotOf[uuid]
		return c + Vector3.new((i % 6 - 2.5) * 3, 0, (math.floor(i / 6) - 1) * 3)
	end

	----------------------------------------------------------------- TEAM + GUARD
	-- ActivePetsService: sumber pet yg beneran AKTIF (model spawn + passive kebaca).
	local ActivePets; pcall(function() ActivePets = require(RS.Modules.PetServices.ActivePetsService) end)
	-- teamSet = { [uuid]=true }. Return true kalau equipped PERSIS == teamSet.
	local function teamMatches(teamSet)
		if not next(teamSet or {}) then return true end -- team kosong = ga usah proses
		local eq = equippedList()
		local eqSet, eqN = {}, 0
		for _, u in ipairs(eq) do eqSet[u] = true; eqN = eqN + 1 end
		local tN = 0
		for u in pairs(teamSet) do if not eqSet[u] then return false end; tN = tN + 1 end
		return eqN == tN
	end
	-- Semua anggota team udah AKTIF di garden (ClientPetState) -> passive-nya kebaca.
	local function teamActive(teamSet)
		if not next(teamSet or {}) then return true end
		if not ActivePets or not ActivePets.ClientPetState then return true end -- ga bisa cek -> anggap ok
		local cps = ActivePets.ClientPetState[LP.Name]
		if not cps then return false end
		for u in pairs(teamSet) do if cps[u] == nil then return false end end
		return true
	end

	-- 1 pass: cabut non-team, pasang anggota team yg belum ke-equip.
	local function equipTeamOnce(teamSet, unequipDelay, equipDelay)
		local unDelay = tonumber(unequipDelay) or 0.1
		local eqDelay = tonumber(equipDelay) or 0.15
		local keep = {}
		for u in pairs(teamSet) do keep[u] = true end
		local hasUnequipped = false
		for _, u in ipairs(equippedList()) do
			if not keep[u] then
				pcall(function() PetsRemote:FireServer("UnequipPet", u) end)
				hasUnequipped = true
				if unDelay > 0 then task.wait(unDelay) end
			end
		end
		-- Jika ada pet yg dicabut, beri jeda sedikit agar server game membebaskan slot garden
		if hasUnequipped then task.wait(0.15) end

		local eqNow = {}
		for _, u in ipairs(equippedList()) do eqNow[u] = true end
		for u in pairs(teamSet) do
			if not eqNow[u] then
				local pos = getPos(u)
				if pos then
					pcall(function() PetsRemote:FireServer("EquipPet", u, CFrame.new(pos)) end)
					if eqDelay > 0 then task.wait(eqDelay) end
				end
			end
		end
	end

	-- Equip team: BLOK sampai team LENGKAP ter-equip (data). Boost/passive (bronto/koi/seal)
	-- diterapin server-side pas pet KE-EQUIP, BUKAN pas model kerender di client. ClientPetState
	-- (spawn model) cuma dipake sbg sinyal cepat kalau kebaca — tapi di LOW PERFORMANCE MODE
	-- model pet sering ga spawn, jadi JANGAN jadiin gate. Kalau ga kebaca aktif, tetap lanjut
	-- setelah settle delay (team udah ke-equip = boost udah masuk server).
	local function equipTeam(teamSet, label, unequipDelay, equipDelay)
		if not next(teamSet or {}) then return true end
		if teamMatches(teamSet) and teamActive(teamSet) then return true end -- fast path
		ctx.state.teamSwapActive = true
		ctx.state.hatchStatus = (label or "Team") .. ": equipping..."
		-- 1) pasang sampai data-equipped lengkap
		local ok = false
		for _ = 1, 8 do
			if teamMatches(teamSet) then ok = true; break end
			equipTeamOnce(teamSet, unequipDelay, equipDelay)
			task.wait(0.25)
		end
		if not ok then
			ctx.state.teamSwapActive = false
			return false
		end
		-- 2) best-effort tunggu pet aktif (model spawn) — poll max ~4s. Begitu kebaca, lanjut.
		for _ = 1, 20 do
			if teamActive(teamSet) then
				ctx.state.teamSwapActive = false
				return true
			end
			ctx.state.hatchStatus = (label or "Team") .. ": nunggu pet aktif..."
			task.wait(0.2)
		end
		-- 3) ga kebaca aktif (kemungkinan low-perf, model ga spawn) TAPI udah ke-equip di data.
		--    Boost server tetap kepasang -> LANJUT (jgn skip). Settle bentar buat jaga2.
		ctx.state.hatchStatus = (label or "Team") .. ": ke-equip (settle)..."
		task.wait(1.5)
		ctx.state.teamSwapActive = false
		return true
	end

	----------------------------------------------------------------- FAVORITE / SELL
	local function petTools()
		local out = {}
		local bp = LP:FindFirstChildOfClass("Backpack")
		for _, src in ipairs({ bp, LP.Character }) do
			if src then for _, t in ipairs(src:GetChildren()) do
				if t:IsA("Tool") and t:GetAttribute("PET_UUID") then out[#out + 1] = t end
			end end
		end
		return out
	end
	local function isFav(tool) return tool:GetAttribute(FAV_KEY) == true end
	local function setFav(tool, want)
		if isFav(tool) ~= want and FavoriteRemote then
			pcall(function() FavoriteRemote:FireServer(tool) end); task.wait(0.06)
		end
	end

	-- filter disimpan pakai label "Pet - Egg"; cocokin pakai label yg sama.
	local petEggLabel = (ctx.reg and ctx.reg.petEggLabel) or (ctx.petEggLabel) or function(p) return p end
	local petBaseName = (ctx.reg and ctx.reg.petBaseName) or (ctx.petBaseName) or function(p) return tostring(p):match("^(.-)%s*-%s*") or tostring(p) end

	-- Helper pencocokan pet ke Sell & Bronto Config list
	local function findRule(petType, petData)
		if not CFG.hatchSellList or not next(CFG.hatchSellList) or not petType then return nil end
		-- 1. Direct match
		if CFG.hatchSellList[petType] then return CFG.hatchSellList[petType] end
		-- 2. Combo match (Pet - Egg) via petData / registry
		local base = petBaseName(petType)
		local rawName = (base ~= "" and base ~= petType) and base or petType
		local egg = (petData and petData.HatchedFrom) or (ctx.reg and ctx.reg.petEggMap and (ctx.reg.petEggMap[rawName] or ctx.reg.petEggMap[petType]))
		if egg then
			local combo = rawName .. " - " .. egg
			if CFG.hatchSellList[combo] then return CFG.hatchSellList[combo] end
		end
		-- 3. Label match
		local key = petEggLabel(petType)
		if CFG.hatchSellList[key] then return CFG.hatchSellList[key] end
		-- 4. Case-insensitive / base name match
		local ptLower = rawName:lower()
		local keyLower = tostring(key or ""):lower()
		for name, r in pairs(CFG.hatchSellList) do
			local nLower = tostring(name):lower()
			local bLower = petBaseName(name):lower()
			if nLower == ptLower or nLower == keyLower or bLower == ptLower then
				return r
			end
		end
		return nil
	end

	-- apakah pet ini termasuk yg DIJUAL (cocok filter)?
	-- PENTING: pakai berat TAMPIL (BaseWeight*(1+0.1*Level)) = yg keliatan di game/dropdown,
	-- BUKAN BaseWeight mentah (beda angka -> salah keep/favorite). Weight & Age = AND
	-- (harus dua-duanya kepenuhi; 0 = filter itu dimatiin).
	local function shouldSell(petType, pd)
		pd = pd or {}
		local age = pd.Level or 0
		local w = (pd.BaseWeight or 0) * (1 + 0.1 * age)
		local key = petEggLabel(petType)

		-- Prioritas 1: Sell & Bronto Config List terpadu (Bulk / per-pet setting)
		local rule = findRule(petType, pd)
		if rule then
			if rule.special == true then
				return false -- Special pet (bintang aktif) mutlak disimpan (KEEP)
			end
			local targetKg = tonumber(rule.kg) or 0
			if w >= targetKg then
				return false -- Weight >= KG -> KEEP (pet aman, tetap disimpan, dan masuk ke proses Bronto)
			else
				-- Weight < KG -> mengikuti pengaturan tombol KEEP / SELL
				return rule.action == "SELL"
			end
		elseif CFG.hatchSellList and next(CFG.hatchSellList) then
			-- Pet tidak ada di list config -> KEEP (aman)
			return false
		end

		-- Fallback: config lama (Pets to Sell & Special Pets to Sell)
		if (CFG.sellPetTypes or {})[key] then
			local wt = CFG.sellWeightThreshold or 0
			local at = CFG.sellAgeThreshold or 0
			local wOk = wt <= 0 or w < wt
			local aOk = at <= 0 or age < at
			if (wt > 0 or at > 0) and wOk and aOk then return true end
		end
		if (CFG.sellSpecialTypes or {})[key] then
			local sw = CFG.sellSpecialWeight or 0
			if sw > 0 and w < sw then return true end
		end
		return false
	end

	-- Jalankan sell: pet yg keep -> favorit; pet yg dijual -> unfavorit lalu jual.
	local function doSell()
		-- GUARD: filter kosong -> batalin (biar ga ada kecelakaan)
		if not next(CFG.hatchSellList or {}) and not next(CFG.sellPetTypes or {}) and not next(CFG.sellSpecialTypes or {}) then
			ctx.state.hatchStatus = "Sell dibatalin: filter 'Pets to Sell' kosong"
			return 0
		end
		local inv = inventory()
		local keeps, sells = {}, {}
		for _, t in ipairs(petTools()) do
			local uuid = t:GetAttribute("PET_UUID")
			local v = inv[uuid]
			local pt = (v and v.PetType) or t:GetAttribute("f")
			local pd = v and v.PetData
			if isFav(t) then
				keeps[#keeps + 1] = t              -- udah favorit = MUTLAK ga dijual (walau filter cocok)
			elseif shouldSell(pt, pd) then
				sells[#sells + 1] = t
			else
				keeps[#keeps + 1] = t
			end
		end

		if CFG.sellStyle == "All at Once" then
			-- proteksi: favoritin semua keep, unfavorit yg mau dijual
			ctx.state.hatchStatus = "Selling: favorit proteksi..."
			for _, t in ipairs(keeps) do setFav(t, true) end
			for _, t in ipairs(sells) do setFav(t, false) end
			-- VERIFY: tunggu sync + cek SEMUA keep bener favorit; retry; abort kalau gagal.
			local safe = false
			for _ = 1, 4 do
				task.wait(0.5)
				local bad = {}
				for _, t in ipairs(keeps) do if t.Parent and not isFav(t) then bad[#bad + 1] = t end end
				if #bad == 0 then safe = true; break end
				ctx.state.hatchStatus = ("Verify: %d keep-pet belum favorit, retry..."):format(#bad)
				for _, t in ipairs(bad) do setFav(t, true) end
			end
			if not safe then
				ctx.state.hatchStatus = "Sell DIBATALIN: ada keep-pet belum favorit (aman, ga jadi jual)"
				return 0
			end
			if SellAll then pcall(function() SellAll:FireServer() end) end
			ctx.state.hatchSellCycles = (ctx.state.hatchSellCycles or 0) + 1
			ctx.state.hatchStatus = ("Sold all-at-once (%d matched)"):format(#sells)
			return #sells
		else
			-- One by One: cuma jual yg cocok filter, targeted (aman by design)
			ctx.state.hatchStatus = "Selling one-by-one..."
			for _, t in ipairs(sells) do
				if t.Parent then
					setFav(t, false)
					if SellPet then pcall(function() SellPet:FireServer(t, true) end) end
					task.wait(0.1)
				end
			end
			ctx.state.hatchSellCycles = (ctx.state.hatchSellCycles or 0) + 1
			ctx.state.hatchStatus = ("Sold %d pet (one by one)"):format(#sells)
			return #sells
		end
	end
	ctx.hatchDoSell = doSell -- expose buat tombol manual

	----------------------------------------------------------------- HATCH
	-- Egg ready = timer habis (TimeToHatch <= 0). Egg yg timer-nya jalan = belum ready.
	-- eggMode = fwd decl, dibind abis eggPending (predicate "egg sesuai config").
	local eggMode
	local function readyEggs()
		local GetFarm = require(RS.Modules.GetFarm); local farm = GetFarm(LP)
		local t = {}
		if farm then for _, e in ipairs(farm:GetDescendants()) do
			if e:IsA("Model") and e.Name == "PetEgg" and e:GetAttribute("OWNER") == LP.Name then
				local tth = tonumber(e:GetAttribute("TimeToHatch")) or 0
				-- HANYA egg sesuai pilihan yang boleh di-hatch — egg tipe lain
				-- (sisa config lama, mis. Paradise saat pilih Common) dibiarkan.
				if tth <= 0 and (not eggMode or eggMode(e)) then t[#t + 1] = e end
			end
		end end
		return t
	end
	local function backpackPetCount()
		local n = 0
		for _, t in ipairs(petTools()) do local _ = t; n = n + 1 end
		return n
	end
	local function getInventoryCapacity()
		local d = getData()
		local maxCap = d and d.PetsData and d.PetsData.MutableStats and tonumber(d.PetsData.MutableStats.MaxPetsInInventory) or 0
		local bpc = backpackPetCount()
		local inv = inventory()
		local invCount = 0
		for _ in pairs(inv) do invCount = invCount + 1 end
		local cur = math.max(bpc, invCount)
		return cur, maxCap
	end

	-- Parse nama tool egg & jumlahnya (mendukung angka positif dan minus misal "Paradise Egg x-20", "Paradise Egg -20", "x -20", "[x-20]", dll)
	local function parseEggTool(t)
		if not (t and t:IsA("Tool") and not t:GetAttribute("PET_UUID")) then
			return nil, 0
		end
		local raw = tostring(t.Name)
		local rawLower = raw:lower()
		local targetEgg = CFG.hatchEggName
		local hasEgg = rawLower:find("egg", 1, true) or (targetEgg and rawLower:find(targetEgg:lower(), 1, true))
		if not hasEgg then
			return nil, 0
		end

		-- Normalize unicode dashes/minuses ke ASCII "-"
		-- \226\128\147 = en-dash (–), \226\128\148 = em-dash (—), \226\136\146 = minus sign (−)
		local norm = raw:gsub("[\226\128\147\226\128\148\226\136\146]", "-")

		-- Cek attribute / child Value jika ada
		local attrVal = t:GetAttribute("Quantity") or t:GetAttribute("Count") or t:GetAttribute("Amount")
		if not attrVal then
			local qChild = t:FindFirstChild("Quantity") or t:FindFirstChild("Count") or t:FindFirstChild("Amount")
			if qChild and (qChild:IsA("IntValue") or qChild:IsA("NumberValue")) then
				attrVal = qChild.Value
			end
		end

		-- Ekstraksi base & count dari string
		-- Format 1: "Egg Name x-20", "Egg Name x -20", "Egg Name [X-20]", "Egg Name (x - 20)"
		local base, cnt = norm:match("^(.-)%s*[%[%(]?%s*[xX]%s*([%-+]?%s*%d+)%s*[%]%)]?$")
		-- Format 2: "Egg Name -20", "Egg Name [-20]", "Egg Name (-20)", "Egg Name - 20"
		if not cnt then
			base, cnt = norm:match("^(.-)%s*[%[%(]?%s*([%-+]%s*%d+)%s*[%]%)]?$")
		end
		-- Format 3: "Egg Name [20]" atau "Egg Name (20)"
		if not cnt then
			base, cnt = norm:match("^(.-)%s*[%[%(]%s*([%-+]?%s*%d+)%s*[%]%)]$")
		end

		if cnt then
			local num = tonumber((cnt:gsub("%s+", "")))
			if num then
				-- Bersihkan base dari bracket/tanda sisa
				base = base and base:gsub("[%[%(]%s*$", ""):match("^%s*(.-)%s*$") or raw
				return base, num
			end
		end

		-- Jika name tidak ada format angka, tapi ada attribute bernilai angka
		if attrVal and tonumber(attrVal) then
			local cleanBase = norm:match("^%s*(.-)%s*$")
			return cleanBase, tonumber(attrVal)
		end

		return norm:match("^%s*(.-)%s*$"), 1
	end

	-- Daftar egg di backpack + jumlah (buat dropdown Egg Configuration).
	function ctx.getEggBackpackOptions()
		local out = {}
		local bp = LP:FindFirstChildOfClass("Backpack")
		if bp then for _, t in ipairs(bp:GetChildren()) do
			local base, cnt = parseEggTool(t)
			if base then
				out[#out + 1] = { name = base, display = ("%s x%d"):format(base, cnt) }
			end
		end end
		table.sort(out, function(a, b) return a.name < b.name end)
		return out
	end

	----------------------------------------------------------------- PLACE EGG
	-- Pending pet dari egg (dari SavedObjects): return petType, displayWeight (base*1.1)
	local eggSlotKey
	local function eggPending(egg)
		local uuid = egg:GetAttribute("OBJECT_UUID"); if not uuid then return nil, 0 end
		local d = getData(); local slots = d and d.SaveSlots and d.SaveSlots.AllSlots
		if not slots then return nil, 0 end
		local function fromSlot(s) local so = s and s.SavedObjects and s.SavedObjects[uuid]; return so and so.Data end
		local dt = eggSlotKey and fromSlot(slots[eggSlotKey])
		if not dt then for sn, slot in pairs(slots) do if type(slot) == "table" then local x = fromSlot(slot); if x then eggSlotKey = sn; dt = x; break end end end end
		if not dt then return nil, 0 end
		return dt.Type, (tonumber(dt.BaseWeight) or 0) * 1.1
	end
	-- Bind predicate tipe egg: cocok kalau label egg-nya mengandung CFG.hatchEggName
	-- ("Dog - Common Egg" cocok "Common Egg"). Data belum ke-load -> fail-open.
	eggMode = function(e)
		local target = CFG.hatchEggName
		if not target or target == "" then return true end
		local pt = eggPending(e)
		if not pt then return true end
		return petEggLabel(pt):lower():find(target:lower(), 1, true) ~= nil
	end
	local function placedEggCount()
		local GetFarm = require(RS.Modules.GetFarm); local farm = GetFarm(LP)
		local n = 0
		if farm then for _, e in ipairs(farm:GetDescendants()) do
			-- Hitung CUMA egg sesuai config: egg tipe lain dibiarkan di farm
			-- (gak di-hatch, gak ngitung slot) — nggak nyandera place target.
			if e:IsA("Model") and e.Name == "PetEgg" and e:GetAttribute("OWNER") == LP.Name and eggMode(e) then n = n + 1 end
		end end
		return n
	end
	local function plantLocPart()
		local GetFarm = require(RS.Modules.GetFarm); local farm = GetFarm(LP)
		local PL = farm and farm:FindFirstChild("Plant_Locations", true)
		if not PL then return nil end
		if PL:IsA("BasePart") then return PL end
		for _, d in ipairs(PL:GetDescendants()) do if d:IsA("BasePart") then return d end end
		return nil
	end
	-- Grid FIX & rapih: n slot, center di area, baris rata (spacing 4 studs).
	-- + sedikit baris cadangan di belakang biar tetap bisa penuh kalau ada egg nyempil.
	local function gridPositions(n)
		local p = plantLocPart(); if not p then return {} end
		n = math.max(1, n or 9)
		local SP = 4 -- jarak antar egg (min server = 3, kasih margin biar ga "Too close")
		local usableX = math.max(SP, p.Size.X - 4)
		local cols = math.max(1, math.min(n, math.floor(usableX / SP) + 1))
		-- baris = cukup buat n + 1 baris cadangan (anti-stuck, tetap rapi)
		local rows = math.ceil(n / cols) + 1
		local startX = -((cols - 1) * SP) / 2
		local startZ = -((rows - 1) * SP) / 2
		local out = {}
		for r = 0, rows - 1 do
			for c = 0, cols - 1 do
				out[#out + 1] = p.Position + Vector3.new(startX + c * SP, p.Size.Y / 2 + 0.2, startZ + r * SP)
			end
		end
		return out
	end
	-- Sebar egg ACAK di dalam area, tetap jaga jarak antar-egg biar ga "Too close".
	local function randomPositions(n)
		local p = plantLocPart(); if not p then return {} end
		n = math.max(1, n or 9)
		local SP = 4 -- jarak minimum antar egg
		local halfX = math.max(SP, p.Size.X / 2 - 2)
		local halfZ = math.max(SP, p.Size.Z / 2 - 2)
		local y = p.Size.Y / 2 + 0.2
		local out, tries = {}, 0
		-- generate lebih banyak dari n (buffer) biar tetap bisa penuh walau ada yg bentrok
		while #out < n * 2 and tries < n * 40 do
			tries = tries + 1
			local cand = p.Position + Vector3.new((math.random() * 2 - 1) * halfX, y, (math.random() * 2 - 1) * halfZ)
			local ok = true
			for _, e in ipairs(out) do
				if (Vector3.new(e.X, 0, e.Z) - Vector3.new(cand.X, 0, cand.Z)).Magnitude < SP then ok = false; break end
			end
			if ok then out[#out + 1] = cand end
		end
		return out
	end
	local function currentEggs()
		local GetFarm = require(RS.Modules.GetFarm); local farm = GetFarm(LP)
		local t = {}
		if farm then for _, e in ipairs(farm:GetDescendants()) do
			if e:IsA("Model") and e.Name == "PetEgg" and e:GetAttribute("OWNER") == LP.Name then t[#t + 1] = e end
		end end
		return t
	end
	local function slotOccupied(pos, eggs)
		for _, e in ipairs(eggs) do
			local ep = e:GetPivot().Position
			if (Vector3.new(ep.X, 0, ep.Z) - Vector3.new(pos.X, 0, pos.Z)).Magnitude < 3.5 then return true end
		end
		return false
	end
	-- return tool egg yg lagi dipegang (scan SEMUA tool, bukan cuma yg pertama) + apakah ada
	-- tool lain (pet/egg beda) yg ikut nyangkut.
	local function scanHeld(eggName)
		local char = LP.Character
		local heldEgg, otherCount = nil, 0
		if char then for _, t in ipairs(char:GetChildren()) do
			if t:IsA("Tool") then
				if not t:GetAttribute("PET_UUID") and tostring(t.Name):find(eggName, 1, true) then heldEgg = t
				else otherCount = otherCount + 1 end
			end
		end end
		return heldEgg, otherCount
	end
	local function equipEggTool(eggName)
		local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
		if not hum then return nil end
		local heldEgg, otherCount = scanHeld(eggName)
		-- udah megang egg yg bener DAN ga ada tool lain nyangkut -> ok
		if heldEgg and otherCount == 0 then return heldEgg end
		-- ada pet/egg-lain ke-pegang barengan (bug double-hold) -> lepas SEMUA biar bersih
		pcall(function() hum:UnequipTools() end); task.wait(0.15)
		local bp = LP:FindFirstChildOfClass("Backpack")
		if bp then for _, t in ipairs(bp:GetChildren()) do
			if t:IsA("Tool") and tostring(t.Name):find(eggName, 1, true) and not t:GetAttribute("PET_UUID") then
				pcall(function() hum:EquipTool(t) end); task.wait(0.35)
				-- pastiin abis equip ga ada tool lain nyusup lagi
				local eg2, oc2 = scanHeld(eggName)
				if eg2 and oc2 > 0 then pcall(function() hum:UnequipTools() end); task.wait(0.1); pcall(function() hum:EquipTool(t) end); task.wait(0.25) end
				return t
			end
		end end
		return nil
	end
	-- Isi egg RAPIH ke grid, cuma di slot yg kosong. Retry sampai penuh (target).
	local function placeEggs(target)
		local eggName = CFG.hatchEggName or "Rare Egg"
		if not equipEggTool(eggName) then ctx.state.hatchStatus = "Egg '" .. eggName .. "' ga ada di backpack"; return 0 end
		local start = placedEggCount()
		local isRandom = (CFG.hatchPlacePattern == "Random")
		-- isi slot kosong sampai TEPAT target; berhenti kalau 1 pass ga nambah (mentok)
		for _ = 1, 3 do
			if placedEggCount() >= target then break end
			local before = placedEggCount()
			-- Random: sebar ulang tiap pass (spot baru). Grid: pola tetap.
			local grid = isRandom and randomPositions(target) or gridPositions(target)
			local eggs = currentEggs()
			for _, pos in ipairs(grid) do
				if not CFG.hatchEnabled or placedEggCount() >= target then break end
				if not slotOccupied(pos, eggs) then
					equipEggTool(eggName)
					-- pastiin bener-bener MEGANG egg (scan semua tool, bukan cuma yg pertama;
					-- kadang pet hasil hatch ikut ke-pegang). Kalau ada pet nyangkut, equipEggTool
					-- di atas udah bersihin -> re-scan.
					local held = scanHeld(eggName)
					if held then
						pcall(function() EggRemote:FireServer("CreateEgg", pos) end)
						task.wait(0.3)
						eggs = currentEggs() -- refresh biar ga dobel di slot sama
						ctx.state.hatchStatus = ("Placing: %d/%d egg"):format(placedEggCount(), target)
					end
				end
			end
			if placedEggCount() <= before then break end -- ga nambah -> mentok
		end
		return placedEggCount() - start
	end
	local function unionTeam(a, b)
		local u = {}
		for k in pairs(a or {}) do u[k] = true end
		for k in pairs(b or {}) do u[k] = true end
		return u
	end

	-- Klasifikasi egg buat bronto: "skip" | "bronto" | "normal"
	local function classifyEgg(egg)
		local pt, w = eggPending(egg)
		if not pt then return "normal" end

		local key = petEggLabel(pt)

		-- 1) Prioritas 1: Sell & Bronto Config List terpadu
		local rule = findRule(pt)
		if rule then
			if rule.special == true then
				if CFG.brontoSkipSpecial then return "skip" end
				return "bronto"
			end
			local targetKg = tonumber(rule.kg) or 0
			if w >= targetKg then
				if CFG.brontoSkipSpecial then return "skip" end
				return "bronto"
			else
				return "normal"
			end
		end

		-- 2) Fallback filter lama jika ada
		local isSpecial = (CFG.brontoSpecialPets or {})[key] == true
		if isSpecial and (CFG.brontoSpecialWeight or 0) > 0 and w <= CFG.brontoSpecialWeight then isSpecial = false end
		if isSpecial and CFG.brontoSkipSpecial then return "skip" end
		local isUni = false
		if (CFG.brontoUniversalWeight or 0) > 0 and w > CFG.brontoUniversalWeight then
			local types = CFG.brontoUniversalTypes or {}
			if not next(types) or types[key] then isUni = true end
		end
		if isSpecial or isUni then return "bronto" end
		return "normal"
	end

	----------------------------------------------------------------- Hatch Alert (webhook bronto)
	local PetList; pcall(function() PetList = require(RS.Data.PetRegistry.PetList) end)
	local PetRegistry; pcall(function() PetRegistry = require(RS.Data.PetRegistry) end)
	local function petSize(eggName, petType, baseW)
		local egg = PetRegistry and PetRegistry.PetEggs and PetRegistry.PetEggs[eggName]
		local item = egg and egg.RarityData and egg.RarityData.Items and egg.RarityData.Items[petType]
		local wr = item and item.GeneratedPetData and item.GeneratedPetData.WeightRange
		if type(wr) == "table" and wr[1] and wr[2] and wr[2] > wr[1] then
			local f = (baseW - wr[1]) / (wr[2] - wr[1])
			if f < 0.33 then return "Small" elseif f < 0.7 then return "Normal" else return "Big" end
		end
		return "Normal"
	end
	-- dispWeight = berat tampil (base*1.1). Bronto = dispWeight*1.3 (+30%).
	local function sendHatchAlert(petType, eggName, dispWeight, isBrontoHatch)
		local url = (CFG.hatchWebhookUrl and CFG.hatchWebhookUrl ~= "" and CFG.hatchWebhookUrl) or CFG.webhookUrl
		if not url or url == "" or not ctx.sendWebhook then return end
		if isBrontoHatch == nil then isBrontoHatch = true end
		local finalW = isBrontoHatch and (dispWeight * 1.3) or dispWeight
		local weightStr = isBrontoHatch and (("`%.2f KG` ➜ `%.2f KG` (+30%%)"):format(dispWeight, finalW)) or (("`%.2f KG`"):format(dispWeight))
		local rule = findRule(petType)
		local isSpec = (rule and rule.special == true)
		local alertTitle = isSpec and "✦ CeszParadise — ★ SPECIAL PET Alert" or "✦ CeszParadise — 🦕 BRONTO PET Alert"
		local alertColor = isSpec and 16766720 or 5814783
		local payload = {
			content = "@everyone",
			embeds = { {
				title = alertTitle,
				color = alertColor,
				fields = {
					{
						name = "**Profile :**",
						value = ("> Username : **%s**"):format(LP.Name),
						inline = false,
					},
					{
						name = "**Hatched :**",
						value = ("> Pet Name: `%s` %s\n> Hatched From: `%s`\n> Weight: %s")
							:format(petType, isSpec and "⭐" or "", eggName, weightStr),
						inline = false,
					},
				},
				footer = {
					text = ("Server Version: %s\n%s"):format(tostring(game.PlaceVersion), os.date("%B %d | %I:%M %p")),
					icon_url = "https://raw.githubusercontent.com/milmscr/opoki/main/tegalan/Logo/logo_icon.png",
				},
			} },
		}
		pcall(function() ctx.sendWebhook(url, payload, ctx) end)
	end

	local function sendInventoryFullWebhook(cur, maxCap)
		local url = (CFG.hatchWebhookUrl and CFG.hatchWebhookUrl ~= "" and CFG.hatchWebhookUrl) or CFG.webhookUrl
		if not url or url == "" or not ctx.sendWebhook then return end
		local payload = {
			content = ("@everyone ⚠️ **Auto Hatch STOPPED** — Invent Max `%d/%d`"):format(cur, maxCap),
			embeds = { {
				title = "⚠️ CeszParadise — Inventory Full Alert",
				color = 16728135,
				description = ("> **Status :** `Invent Max %d/%d`\n> Auto Hatch otomatis dihentikan karena kapasitas penyimpanan pet telah mencapai batas maksimal!"):format(cur, maxCap),
				fields = {
					{
						name = "**Profile :**",
						value = ("> Username : **%s**"):format(LP.Name),
						inline = false,
					},
					{
						name = "**Inventory Statistics :**",
						value = ("> Current Pets: `%d`\n> Max Capacity: `%d`\n> Capacity Status: `Penuh (%d/%d)`"):format(cur, maxCap, cur, maxCap),
						inline = false,
					},
				},
				footer = {
					text = ("Server Version: %s\n%s"):format(tostring(game.PlaceVersion), os.date("%B %d | %I:%M %p")),
					icon_url = "https://raw.githubusercontent.com/milmscr/opoki/main/tegalan/Logo/logo_icon.png",
				},
			} },
		}
		pcall(function() ctx.sendWebhook(url, payload, ctx) end)
	end

	local function handleInventoryFull(cur, maxCap)
		if not CFG.hatchEnabled and ctx.state.hatchStatus and ctx.state.hatchStatus:find("Invent Max") then return end
		CFG.hatchEnabled = false
		if ctx.persistState then pcall(ctx.persistState) end
		ctx.stopHatch()
		if ctx.ui and ctx.ui.rHatchToggle then
			pcall(ctx.ui.rHatchToggle)
		end
		ctx.state.hatchPhase = ("Invent Max (%d/%d)"):format(cur, maxCap)
		ctx.state.hatchStatus = ("Auto Hatch STOPPED: Invent Max %d/%d"):format(cur, maxCap)
		if ctx.log then ctx.log(("Auto Hatch STOPPED: Invent Max %d/%d"):format(cur, maxCap)) end
		task.spawn(function()
			sendInventoryFullWebhook(cur, maxCap)
		end)
	end

	local function eggAmount(eggName)
		local n = 0
		local target = tostring(eggName or ""):lower():match("^%s*(.-)%s*$")
		if target == "" then return 0 end
		local safeTarget = target:gsub("([%%%^%$%(%)%%.%[%]%*%+%-%?])", "%%%1")
		for _, src in ipairs({ LP:FindFirstChildOfClass("Backpack"), LP.Character }) do
			if src then for _, t in ipairs(src:GetChildren()) do
				local base, cnt = parseEggTool(t)
				if base then
					local b = tostring(base):lower():match("^%s*(.-)%s*$")
					if b == target then
						n = n + cnt
					elseif b:find("%f[%a]" .. safeTarget .. "%f[%A]") then
						n = n + cnt
					end
				end
			end end
		end
		return n
	end

	local function totalEggCount(eggName)
		return eggAmount(eggName) + placedEggCount()
	end

	----------------------------------------------------------------- Auto Rejoin on Egg Threshold (Minus / Plus)
	local function sendRejoinWebhook(rType, eggName, curAmt, netResult, thresh)
		local url = CFG.webhookUrl
		if not url or url == "" or not ctx.sendWebhook then return end
		local diffStr = (type(netResult) == "number") and (("%+d"):format(netResult)) or tostring(netResult)
		local isPlus = (rType == "Plus")
		local title = isPlus and "🔄 CeszParadise — Auto Rejoin (Egg Plus)" or "🔄 CeszParadise — Auto Rejoin (Egg Minus)"
		local color = isPlus and 3066993 or 16744272
		local sign = isPlus and "+" or "-"
		local notifyText = ("auto rejoin on, %s %d (%s)"):format(eggName, curAmt, diffStr)
		local desc = isPlus
			and ("> **Status :** `%s`\n> Penambahan egg terdeteksi surplus melebihi ambang batas (`+%d`)! Melakukan auto rejoin ke server..."):format(notifyText, thresh)
			or ("> **Status :** `%s`\n> Pengurangan egg terdeteksi minus melebihi ambang batas (`-%d`)! Melakukan auto rejoin ke server..."):format(notifyText, thresh)
		local payload = {
			content = ("@everyone ⚠️ **Auto Rejoin** — `%s`"):format(notifyText),
			embeds = { {
				title = title,
				color = color,
				description = desc,
				fields = {
					{
						name = "**Profile :**",
						value = ("> Username : **%s**\n> Display : **%s**"):format(LP.Name, LP.DisplayName or LP.Name),
						inline = false,
					},
					{
						name = "**Egg Information :**",
						value = ("> Egg Name : `%s`\n> Current Egg : `%d` (`%s`)\n> Threshold : `%s%d`"):format(eggName, curAmt, diffStr, sign, thresh),
						inline = false,
					},
					{
						name = "**Action :**",
						value = "> Reconnecting to server immediately...",
						inline = false,
					},
				},
				footer = {
					text = ("Server Version: %s\n%s"):format(tostring(game.PlaceVersion), os.date("%B %d | %I:%M %p")),
					icon_url = "https://raw.githubusercontent.com/milmscr/opoki/main/tegalan/Logo/logo_icon.png",
				},
			} },
		}
		pcall(function() ctx.sendWebhook(url, payload, ctx) end)
	end

	function ctx.testRejoinWebhook()
		local eggName = CFG.hatchEggName or "Paradise Egg"
		local thresh = math.abs(tonumber(CFG.hatchRejoinMinusThreshold) or 20)
		sendRejoinWebhook("Minus", eggName, 200, -thresh, thresh)
	end

	function ctx.testRejoinPlusWebhook()
		local eggName = CFG.hatchEggName or "Paradise Egg"
		local thresh = math.abs(tonumber(CFG.hatchRejoinPlusThreshold) or 20)
		sendRejoinWebhook("Plus", eggName, 220, thresh, thresh)
	end

	local function sendStartHatchWebhook()
		local url = CFG.webhookUrl
		if not url or url == "" or not ctx.sendWebhook then return end
		local eggName = CFG.hatchEggName or "Rare Egg"
		local eggBefore = ctx.state.hatchEggBefore or 0
		local bpc = 0
		for _, t in ipairs((function() local o={}; local bp=LP:FindFirstChildOfClass("Backpack"); for _,src in ipairs({bp,LP.Character}) do if src then for _,c in ipairs(src:GetChildren()) do if c:IsA("Tool") and c:GetAttribute("PET_UUID") then o[#o+1]=c end end end end; return o end)()) do bpc=bpc+1 end
		local maxBp = 0
		pcall(function() local d = require(game:GetService("ReplicatedStorage").Modules.GetData)(LP); if d then maxBp = tonumber(d.PetsData.MutableStats.MaxPetsInInventory) or 0 end end)
		local rec = ctx.getRecoveryStat and ctx.getRecoveryStat() or {}
		local payload = {
			embeds = { {
				title = "🥚 CeszParadise — Auto Hatch Started",
				color = 3066993,
				description = "> **Auto Hatch** telah dimulai! Memulai siklus hatching otomatis...",
				fields = {
					{
						name = "**Profile :**",
						value = ("> Username : **%s**\n> Display : **%s**"):format(LP.Name, LP.DisplayName or LP.Name),
						inline = false,
					},
					{
						name = "**Egg Info :**",
						value = ("> Egg Name : `%s`\n> Egg Before : `%d`\n> Max Placed : `%d`"):format(eggName, eggBefore, CFG.hatchMaxPlaced or 8),
						inline = false,
					},
					{
						name = "**Inventory :**",
						value = ("> Pet on Backpack : `%d/%d`"):format(bpc, maxBp),
						inline = false,
					},
					{
						name = "**Recovery Stat :**",
						value = ("> Koi (hatch) : `%d ekor → %.1f%%`\n> Seal (sell) : `%d ekor → %.1f%%`"):format(
							(rec.koiCount or 0), (rec.koiPct or 0),
							(rec.sealCount or 0), (rec.sealPct or 0)),
						inline = false,
					},
					{
						name = "**Sell Config :**",
						value = ("> Sell Mode : `%s`\n> Sell Style : `%s`\n> Sell Every : `%d cycles`"):format(
							CFG.sellMode or "Cycle", CFG.sellStyle or "All at Once", CFG.sellEveryNCycles or 1),
						inline = false,
					},
				},
				footer = {
					text = ("Server Version: %s\n%s"):format(tostring(game.PlaceVersion), os.date("%B %d | %I:%M %p")),
					icon_url = "https://raw.githubusercontent.com/milmscr/opoki/main/tegalan/Logo/logo_icon.png",
				},
			} },
		}
		pcall(function() ctx.sendWebhook(url, payload, ctx) end)
	end

	local function checkEggThreshold()
		local eggName = CFG.hatchEggName or "Rare Egg"
		local curAmt = totalEggCount(eggName)
		local eggBefore = ctx.state.hatchEggBefore or 0

		-- Inisialisasi hatchEggBefore jika belum ada atau saat ganti egg
		if ctx.state.lastTrackedEggName ~= eggName then
			ctx.state.lastTrackedEggName = eggName
			ctx.state.hatchEggBefore = curAmt
			eggBefore = curAmt
		elseif (not ctx.state.hatchEggBefore or ctx.state.hatchEggBefore == 0) and curAmt > 0 and CFG.hatchEnabled then
			ctx.state.hatchEggBefore = curAmt
			eggBefore = curAmt
		end

		local netResult = curAmt - eggBefore

		-- 1. Cek THRESHOLD EGG MINUS (berkurang)
		if CFG.hatchRejoinMinusEnabled then
			local minusThresh = math.abs(tonumber(CFG.hatchRejoinMinusThreshold) or 20)
			if minusThresh <= 0 then minusThresh = 20 end

			-- netResult minus melebihi threshold (misal: netResult <= -20)
			if eggBefore > 0 and netResult <= -minusThresh then
				return true, "Minus", eggName, curAmt, netResult, minusThresh
			end

			-- Tool stack egg itu sendiri minus di backpack (misal: curAmt <= -20)
			if curAmt <= -minusThresh then
				return true, "Minus", eggName, curAmt, curAmt, minusThresh
			end

			-- Cek jika ada tool egg lain di inventory dengan stack minus
			local counts = {}
			for _, src in ipairs({ LP:FindFirstChildOfClass("Backpack"), LP.Character }) do
				if src then
					for _, t in ipairs(src:GetChildren()) do
						local base, qty = parseEggTool(t)
						if base then counts[base] = (counts[base] or 0) + qty end
					end
				end
			end
			for name, qty in pairs(counts) do
				if qty <= -minusThresh then
					return true, "Minus", name, qty, qty, minusThresh
				end
			end
		end

		-- 2. Cek THRESHOLD EGG PLUS (bertambah)
		if CFG.hatchRejoinPlusEnabled then
			local plusThresh = math.abs(tonumber(CFG.hatchRejoinPlusThreshold) or 20)
			if plusThresh <= 0 then plusThresh = 20 end

			-- netResult bertambah melebihi threshold (misal: netResult >= +20)
			if eggBefore > 0 and netResult >= plusThresh then
				return true, "Plus", eggName, curAmt, netResult, plusThresh
			end
		end

		return false, nil, eggName, curAmt, netResult, 0
	end

	local function doDirectReconnect()
		if ctx.reconnect then
			pcall(ctx.reconnect)
		else
			local branch = (getgenv and getgenv().GAG_BRANCH) or _G.GAG_BRANCH or "main"
			local q = (syn and syn.queue_on_teleport) or queue_on_teleport
				or (fluxus and fluxus.queue_on_teleport) or (getgenv and getgenv().queue_on_teleport)
			if q then
				pcall(function()
					q(('if getgenv then getgenv().GAG_BRANCH=%q end loadstring(game:HttpGet("https://raw.githubusercontent.com/milmscr/opoki/%s/tegalan/init.lua"))()'):format(branch, branch))
				end)
			end
			task.wait(0.4)
			local TeleportService = game:GetService("TeleportService")
			local TeleportFn = TeleportService.Teleport
			local ok = pcall(function() TeleportFn(TeleportService, game.PlaceId, LP) end)
			if not ok then
				pcall(function() TeleportService:Teleport(game.PlaceId, LP) end)
			end
		end
	end

	local function handleEggRejoin(rType, eggName, curAmt, netResult, thresh)
		if ctx.state.hatchIsRejoining then return end
		ctx.state.hatchIsRejoining = true

		local diffStr = (type(netResult) == "number") and (("%+d"):format(netResult)) or tostring(netResult)
		local sign = (rType == "Plus") and "+" or "-"
		local reason = ("auto rejoin on, %s %d (%s)"):format(eggName, curAmt, diffStr)
		ctx.state.hatchPhase = "Auto Rejoin"
		ctx.state.hatchStatus = ("Rejoining (%s %d [%s])..."):format(eggName, curAmt, diffStr)
		if ctx.log then ctx.log(("[Auto Hatch] %s (Threshold: %s%d) -> Rejoining server immediately..."):format(reason, sign, thresh)) end

		-- Kirim webhook rejoin
		task.spawn(function()
			sendRejoinWebhook(rType, eggName, curAmt, netResult, thresh)
		end)

		-- Jeda 1.2 detik agar webhook selesai dikirim sebelum client disconnect
		task.wait(1.2)

		-- Eksekusi Reconnect (seperti di interval rejoin)
		doDirectReconnect()
	end

	----------------------------------------------------------------- Cycle Statistics (webhook)
	-- Team ringkas: "N Nama Lengkap" (mutasi + tipe), grup per nama.
	local function teamNames(set)
		local mutDisplay = (ctx.reg and ctx.reg.mutDisplay) or function(x) return x end
		local inv = inventory()
		local tally, order = {}, {}
		for u in pairs(set or {}) do
			local v = inv[u]
			if v then
				local pt = v.PetType or "?"
				local mut = v.PetData and v.PetData.MutationType
				local mutName = mut and mutDisplay(mut) or mut
				local name = (mut and mut ~= "" and mut ~= "Normal") and (tostring(mutName) .. " " .. pt) or pt
				if not tally[name] then tally[name] = 0; order[#order + 1] = name end
				tally[name] = tally[name] + 1
			end
		end
		table.sort(order)
		local parts = {}
		for _, name in ipairs(order) do parts[#parts + 1] = tally[name] .. " " .. name end
		return #parts > 0 and table.concat(parts, ", ") or "None"
	end
	ctx.hatchTeamNames = teamNames

	-- Kategori Hunt: Special (dari filter Bronto Config) + Heavy (>= 5kg, gabungan Huge s/d Colossal).
	-- Apakah pet masuk filter Special di Sell & Bronto Configuration?
	local function isBrontoSpecial(petType, w)
		local rule = findRule(petType)
		if rule then
			if rule.special == true then return true end
			local targetKg = tonumber(rule.kg) or 0
			return (tonumber(w) or 0) >= targetKg
		end
		local key = petEggLabel(petType)
		if (CFG.brontoSpecialPets or {})[key] ~= true then return false end
		if (CFG.brontoSpecialWeight or 0) > 0 and (w or 0) <= CFG.brontoSpecialWeight then return false end
		return true
	end
	-- akumulasi pet ke-hatch: Special vs Heavy (>= 5 kg). Simpan list semua bobot per petType.
	local function trackHatch(petType, dispW, special)
		ctx.state.hatchTiers = ctx.state.hatchTiers or {}
		dispW = tonumber(dispW) or 0
		local category = special and "Special" or (dispW >= 5 and "Heavy" or nil)
		if not category then return end -- <5kg non-special: skip

		local bucket = ctx.state.hatchTiers[category]
		if not bucket then bucket = {}; ctx.state.hatchTiers[category] = bucket end
		local t = bucket[petType]
		if not t then t = { n = 0, weights = {} }; bucket[petType] = t end
		t.n = t.n + 1
		t.weights[#t.weights + 1] = dispW
	end
	ctx.hatchIsBrontoSpecial = isBrontoSpecial

	-- Recovery stat DIHITUNG dari team yg dipilih (formula game, bukan empiris).
	-- Per pet: value = clamp(Base + Scale*scaledLevel, 0, Max). scaledLevel diminishing
	-- di atas 100. Total di-cap 50% (cap per egg). Koi @ Hatch team, Seal @ Sell team.
	local function scaledLevel(lv)
		lv = lv or 0
		if lv <= 100 then return lv
		elseif lv <= 120 then return (lv - 100) * 0.25 + 100
		else return (lv - 120) * 0.1 + 105 end
	end
	local function passivePct(teamSet, typeMatch, base, scale, maxPer)
		local inv = inventory()
		local n, total = 0, 0
		for u in pairs(teamSet or {}) do
			local v = inv[u]
			if v and tostring(v.PetType):find(typeMatch) then
				n = n + 1
				local val = base + scale * scaledLevel((v.PetData or {}).Level or 0)
				total = total + math.clamp(val, 0, maxPer) -- per-pet asli (Max 10), total ga di-cap
			end
		end
		return n, total
	end
	-- Koi (Fish of Fortune): Base1 Scale0.22 Max10. Seal (Seal the Deal): Base1 Scale0.05 Max10.
	function ctx.getRecoveryStat()
		local kn, kp = passivePct(CFG.hatchHatchTeam, "Koi", 1, 0.22, 10)
		local sn, sp = passivePct(CFG.hatchSellTeam, "Seal", 1, 0.05, 10)
		return {
			koiCount = kn, koiPct = kp,
			sealCount = sn, sealPct = sp,
		}
	end

	-- Recovery ASLI dihitung dari notif game (listener di atas): periodHatchRec / periodSellRec.
	-- periodHatched / periodSold = jumlah aksi (buat hitung % efektif).

	local function fmtDur(sec)
		sec = math.max(0, math.floor(sec))
		local h = math.floor(sec / 3600); local m = math.floor((sec % 3600) / 60); local s = sec % 60
		local p = {}
		if h > 0 then p[#p + 1] = h .. "h" end
		if m > 0 then p[#p + 1] = m .. "m" end
		p[#p + 1] = s .. "s"
		return table.concat(p, " ")
	end

	local function sendCycleStats()
		local url = CFG.webhookUrl
		if not url or url == "" or not ctx.sendWebhook then return end
		local eggName = CFG.hatchEggName or "Rare Egg"
		local hatched = ctx.state.hatchEggsHatched or 0
		local eggBefore = ctx.state.hatchEggBefore or 0
		local curAmt = totalEggCount(eggName)

		-- Format Hunt: Special (range min-max kg) & Heavy/Huge-Colossal (daftar bobot tiap pet)
		local tiers = ctx.state.hatchTiers or {}
		local huntLines, totalPets = {}, 0

		-- 1. Special Pets (langsung hasil tanpa judul 'Special:')
		local specBucket = tiers["Special"] or {}
		local specKeys = {}
		for pt in pairs(specBucket) do specKeys[#specKeys + 1] = pt end
		table.sort(specKeys)
		for _, pt in ipairs(specKeys) do
			local t = specBucket[pt]
			totalPets = totalPets + t.n
			local minW, maxW = math.huge, 0
			for _, w in ipairs(t.weights) do
				if w < minW then minW = w end
				if w > maxW then maxW = w end
			end
			local rng = (minW == maxW or minW == math.huge) and ("`%.2f kg`"):format(maxW)
				or ("`%.2f-%.2f kg`"):format(minW, maxW)
			huntLines[#huntLines + 1] = ("> • **%s** `x%d` (%s)"):format(pt, t.n, rng)
		end

		-- 2. Heavy / Huge-Colossal Pets (daftar bobot per pet)
		local heavyBucket = tiers["Heavy"] or {}
		local heavyKeys = {}
		for pt in pairs(heavyBucket) do heavyKeys[#heavyKeys + 1] = pt end
		table.sort(heavyKeys)
		for _, pt in ipairs(heavyKeys) do
			local t = heavyBucket[pt]
			totalPets = totalPets + t.n
			local wStrs = {}
			for _, w in ipairs(t.weights) do
				wStrs[#wStrs + 1] = ("%.2f"):format(w)
			end
			huntLines[#huntLines + 1] = ("> • **%s** `x%d` (`%skg`)"):format(pt, t.n, table.concat(wStrs, ", "))
		end

		local huntText = #huntLines > 0 and table.concat(huntLines, "\n"):sub(1, 1020) or "> • *Tidak ada pet bronto*"

		-- Recovery deterministik (cap 50%). Koi dari Hatch+Bronto team; Seal dari Sell team.
		local rec = ctx.getRecoveryStat()
		local sellDone = ctx.state.sellDoneThisReport == true
		local recHatchCycle = math.floor((ctx.state.periodHatchRec or 0) + 0.5)
		local recSellCycle = sellDone and math.floor((ctx.state.periodSellRec or 0) + 0.5) or 0
		local koiPctShown = rec.koiPct
		local sellPctShown = sellDone and rec.sealPct or 0
		local totalRecovery = recHatchCycle + recSellCycle

		local curAdj = curAmt
		local maxBp = 0
		local d = getData(); if d then maxBp = tonumber(d.PetsData.MutableStats.MaxPetsInInventory) or 0 end
		local hatchCycles = ctx.state.hatchRounds or 0
		local netResult = curAdj - eggBefore

		local payload = { embeds = { {
			title = "📊 Tracking",
			color = 5793266,
			fields = {
				{
					name = "**Profile :**",
					value = ("> Username : **%s**"):format(LP.Name),
					inline = false
				},
				{
					name = "**Hatch Statistics :**",
					value = ("> Cycle Count: `%d`\n> Total Hatched: `%d`\n> Sell Cycle: `%d / %d`\n> Reduce Time: `%s`\n> Duration: `%s`\n> \n> Egg Name: `%s`\n> Pet on Inventory: `%d/%d`")
						:format(
							hatchCycles,
							hatched,
							(ctx.state.hatchReportSellProg or ((ctx.state.hatchRounds or 0) - (ctx.state.hatchLastSellCycle or 0))),
							CFG.sellEveryNCycles or 1,
							fmtDur(os.time() - (ctx.state.hatchCycleStartTime or os.time())),
							fmtDur(os.time() - (ctx.state.hatchStartTime or os.time())),
							eggName,
							backpackPetCount(),
							maxBp
						),
					inline = false
				},
				{
					name = ("**Hatch Bronto (%d):**"):format(totalPets),
					value = huntText,
					inline = false
				},
				{
					name = "**Egg Statistics :**",
					value = ("> Egg Before: `%d`\n> Current Egg: `%d` (`%+d`)\n> Lucky Hatch: `%d` (`%.2f%%`)\n> Lucky Sell: `%d` (`%.2f%%`)\n> Total Recovery: `%d`")
						:format(eggBefore, curAdj, netResult, recHatchCycle, koiPctShown, recSellCycle, sellPctShown, totalRecovery),
					inline = false
				},
			},
			footer = {
				text = ("Server Version: %s\n%s"):format(tostring(game.PlaceVersion), os.date("%B %d | %I:%M %p")),
				icon_url = "https://raw.githubusercontent.com/milmscr/opoki/main/tegalan/Logo/logo_icon.png"
			},
		} } }
		pcall(function() ctx.sendWebhook(url, payload, ctx) end)
		ctx.state.hatchCycleStartTime = os.time()
		-- reset counter periode (Lucky Hatch/Sell dihitung ulang tiap webhook)
		ctx.state.periodHatched, ctx.state.periodSold, ctx.state.sellDoneThisReport = 0, 0, false
		ctx.state.periodHatchRec, ctx.state.periodSellRec = 0, 0
	end
	ctx.hatchSendCycleStats = sendCycleStats
	ctx.hatchTrack = trackHatch

	----------------------------------------------------------------- STATUS
	ctx.state.hatchStatus = "Idle"
	function ctx.getHatchSummary()
		-- team: format per pet "Mutasi - Nama - Berat - Age" (pakai teamNames global)
		local nm = teamNames
		-- max backpack + jumlah egg terpilih
		local d = getData()
		local maxBp = d and d.PetsData and d.PetsData.MutableStats and tonumber(d.PetsData.MutableStats.MaxPetsInInventory) or 0
		local eggName = CFG.hatchEggName or "Rare Egg"
		local curEgg = totalEggCount(eggName)
		return {
			status = CFG.hatchEnabled and "RUNNING" or "STOPPED",
			phase = ctx.state.hatchPhase or "-",
			core = nm(CFG.hatchCoreTeam), hatch = nm(CFG.hatchHatchTeam),
			bronto = nm(CFG.hatchBrontoTeam), sell = nm(CFG.hatchSellTeam),
			backpack = backpackPetCount(), maxBackpack = maxBp,
			currentEgg = eggName, eggBefore = ctx.state.hatchEggBefore or curEgg, currentAmount = curEgg,
			eggsHatched = ctx.state.hatchEggsHatched or 0,
			sellCycles = ctx.state.hatchSellCycles or 0,
			ready = #readyEggs(),
			placed = placedEggCount(),
			maxPlaced = CFG.hatchMaxPlaced or 9,
			sellMode = CFG.sellMode or "Cycle",
			cycleProg = (ctx.state.hatchRounds or 0) - (ctx.state.hatchLastSellCycle or 0),
			cycleTarget = CFG.sellEveryNCycles or 1,
			proc = ctx.getRecoveryStat(),
		}
	end

	----------------------------------------------------------------- LOOP
	local function tick()
		local bpc = backpackPetCount()
		local maxP = CFG.hatchMaxPlaced or 9
		local placed = placedEggCount()

		-- CHECK EGG THRESHOLD (Fallback saat Auto Sell dimatikan atau kondisi stuck total):
		-- Jika Auto Sell mati, atau stuck (tidak ada egg di inventory, plot kosong, dan tidak ada pet untuk di-sell),
		-- cek langsung agar tidak idle selamanya.
		-- Jika Auto Sell aktif, pengecekan UTAMA dilakukan SETELAH sell di bawah agar egg bisa balik dulu (Seal the Deal recovery).
		if CFG.hatchRejoinMinusEnabled or CFG.hatchRejoinPlusEnabled then
			local curEgg = totalEggCount(CFG.hatchEggName or "Rare Egg")
			local isStuck = (curEgg <= 0 and placed == 0 and bpc == 0)
			if not CFG.autoSellEnabled or isStuck then
				local shouldRejoin, rType, rEgg, rCur, rNet, rThresh = checkEggThreshold()
				if shouldRejoin then
					handleEggRejoin(rType, rEgg, rCur, rNet, rThresh)
					return
				end
			end
		end

		-- cycle = jumlah RONDE hatch (tiap 1 batch garden selesai di-hatch = 1 cycle)
		local cycle = ctx.state.hatchRounds or 0
		-- 1) SELL trigger: mode "Cycle" (tiap N cycle) atau "Backpack" (pas penuh)
		local sellNow = false
		if CFG.autoSellEnabled then
			if CFG.sellMode == "Cycle" then
				sellNow = (cycle - (ctx.state.hatchLastSellCycle or 0)) >= (CFG.sellEveryNCycles or 1)
			else
				sellNow = bpc >= (CFG.sellWhenReach or 100)
			end
		end
		if sellNow then
			ctx.state.pnpBlockedByHatch = true
			ctx.state.hatchPhase = "Selling Pets"
			if next(CFG.hatchSellTeam or {}) and not equipTeam(CFG.hatchSellTeam, "Sell Team", CFG.hatchSellUnequipDelay, CFG.hatchSellEquipDelay) then return end -- team wajib lengkap
			task.wait(CFG.sellTeamDelay or 5.5)
			local sold = doSell()
			ctx.state.periodSold = (ctx.state.periodSold or 0) + (tonumber(sold) or 0)
			-- Backpack mode & 0 matched -> naikin threshold biar trigger sell gak
			-- nembak tiap tick (loop sell selamanya, hatch gak pernah jalan).
			if (tonumber(sold) or 0) == 0 and CFG.sellMode == "Backpack" then
				CFG.sellWhenReach = bpc + 1
				ctx.log(("Hatch: sell 0 match — Sell Trigger (BP) dinaikin ke %d biar hatch jalan lagi"):format(CFG.sellWhenReach))
			end
			ctx.state.sellDoneThisReport = true
			-- simpan progress sell-cycle SEBELUM reset (biar webhook nampilin 2/2 bukan 0/2)
			ctx.state.hatchReportSellProg = cycle - (ctx.state.hatchLastSellCycle or 0)
			ctx.state.hatchLastSellCycle = cycle

			-- Tunggu 2 detik agar notifikasi Lucky Pet / recovery Seal the Deal selesai masuk ke inventory
			task.wait(2.0)

			-- 1) Kirim Webhook Sell Terlebih Dahulu Sebelum Rejoin!
			sendCycleStats()
			ctx.state.hatchPendingReport = false

			-- 2) Beri jeda 0.6s agar HTTP request webhook sell terkirim ke Discord
			task.wait(0.6)

			-- 3) CEK EGG THRESHOLD (MINUS / PLUS) SETELAH SIKLUS AUTO SELL SELESAI:
			-- Memberi kesempatan Sell Team mengembalikan egg (Seal recovery) terlebih dahulu.
			-- Jika setelah sell selesai egg minus/plus melebihi threshold -> kirim webhook rejoin lalu langsung auto rejoin!
			if CFG.hatchRejoinMinusEnabled or CFG.hatchRejoinPlusEnabled then
				local shouldRejoin, rType, rEgg, rCur, rNet, rThresh = checkEggThreshold()
				if shouldRejoin then
					handleEggRejoin(rType, rEgg, rCur, rNet, rThresh)
					return
				end
			end

			return
		end

		-- CHECK INVENTORY FULL: jika penyimpanan penuh, hentikan auto hatch & kirim webhook
		local curPets, maxPets = getInventoryCapacity()
		if maxPets > 0 and curPets >= maxPets then
			if CFG.autoSellEnabled and not ctx.state.sellDoneThisReport then
				ctx.state.pnpBlockedByHatch = true
				ctx.state.hatchPhase = "Selling Pets (Inv Full)"
				if not next(CFG.hatchSellTeam or {}) or equipTeam(CFG.hatchSellTeam, "Sell Team", CFG.hatchSellUnequipDelay, CFG.hatchSellEquipDelay) then
					task.wait(CFG.sellTeamDelay or 5.5)
					local sold = doSell()
					ctx.state.periodSold = (ctx.state.periodSold or 0) + (tonumber(sold) or 0)
					-- Sama: 0 match di mode Backpack -> naikin threshold (anti-stuck).
					if (tonumber(sold) or 0) == 0 and CFG.sellMode == "Backpack" then
						CFG.sellWhenReach = curPets + 1
						ctx.log(("Hatch: sell 0 match (inv full) — Sell Trigger (BP) dinaikin ke %d"):format(CFG.sellWhenReach))
					end
					ctx.state.sellDoneThisReport = true
					curPets, maxPets = getInventoryCapacity()
					task.wait(2.0)

					-- Kirim webhook sell dulu
					sendCycleStats()
					ctx.state.hatchPendingReport = false
					task.wait(0.6)

					-- Cek egg threshold setelah sell darurat
					if CFG.hatchRejoinMinusEnabled or CFG.hatchRejoinPlusEnabled then
						local shouldRejoin, rType, rEgg, rCur, rNet, rThresh = checkEggThreshold()
						if shouldRejoin then
							handleEggRejoin(rType, rEgg, rCur, rNet, rThresh)
							return
						end
					end
				end
			end
			if maxPets > 0 and curPets >= maxPets then
				handleInventoryFull(curPets, maxPets)
				return
			end
		end

		-- clamp target ke kapasitas farm biar ga nyangkut (mis. Max Placed > MaxEggsInFarm)
		local d = getData()
		local farmCap = d and d.PetsData and d.PetsData.MutableStats and d.PetsData.MutableStats.MaxEggsInFarm or maxP
		maxP = math.min(maxP, farmCap)

		local placed = placedEggCount()

		-- 2) PLACE (best-effort): tambah egg kalau kurang. JANGAN stuck kalau ga bisa penuh
		--    (grid bentrok egg recovered / kapasitas farm mentok) -> lanjut proses egg yg ada.
		if placed < maxP then
			ctx.state.hatchPhase = ("Placing Eggs (%d/%d)"):format(placed, maxP)
			if not equipTeam(CFG.hatchCoreTeam, "Core Team", CFG.hatchCoreUnequipDelay, CFG.hatchCoreEquipDelay) then return end -- team wajib lengkap dulu
			ctx.state.pnpBlockedByHatch = false
			local added = placeEggs(maxP)
			placed = placedEggCount()
			if added > 0 and placed < maxP then return end -- masih nambah -> lanjut place tick berikut
			-- added==0 (mentok) & belum penuh -> anti-stuck: lanjut proses egg yg udah ada
		end

		-- REPORT: garden udah ke-refill (place selesai). Kalau ada report pending dari
		-- hatch/sell sebelumnya, KIRIM sekarang -> Current Amount = backpack + garden (stabil).
		if ctx.state.hatchPendingReport then
			ctx.state.hatchPendingReport = false
			task.spawn(sendCycleStats)
		end

		local ready = readyEggs()
		-- 3) HATCH: HANYA kalau SEMUA egg (yg ke-place) udah READY (jangan switch selama timer jalan)
		if placed > 0 and #ready >= placed then
			ctx.state.pnpBlockedByHatch = true
			local curHatchPets, maxHatchPets = getInventoryCapacity()
			if maxHatchPets > 0 and curHatchPets >= maxHatchPets then
				handleInventoryFull(curHatchPets, maxHatchPets)
				return
			end

			ctx.state.hatchPhase = "Hatching"
			-- klasifikasi tiap egg: normal (Hatch team) / bronto (Bronto team) / skip
			local normal, bronto = {}, {}
			for _, e in ipairs(ready) do
				local c = classifyEgg(e)
				if c == "bronto" then bronto[#bronto + 1] = e
				elseif c == "normal" then normal[#normal + 1] = e end
			end
			local function hatchList(list)
				for _, e in ipairs(list) do
					if not CFG.hatchEnabled then break end
					local cPets, mPets = getInventoryCapacity()
					if mPets > 0 and cPets >= mPets then
						handleInventoryFull(cPets, mPets)
						break
					end
					local pt, w = eggPending(e)
					if pt then
						local isSpecial = isBrontoSpecial(pt, w)
						trackHatch(pt, w, isSpecial)
						if isSpecial then
							task.spawn(function() sendHatchAlert(pt, CFG.hatchEggName or "Rare Egg", w, false) end)
						end
					end
					pcall(function() EggRemote:FireServer("HatchPet", e) end)
					ctx.state.hatchEggsHatched = (ctx.state.hatchEggsHatched or 0) + 1
				end
			end
			-- pass NORMAL -> Hatch Team (Koi recover)
			if #normal > 0 then
				if next(CFG.hatchHatchTeam or {}) and not equipTeam(CFG.hatchHatchTeam, "Hatch Team", CFG.hatchTeamUnequipDelay, CFG.hatchTeamEquipDelay) then return end
				if next(CFG.hatchHatchTeam or {}) and (CFG.hatchTeamDelay or 5.5) > 0 then
					task.wait(CFG.hatchTeamDelay or 5.5)
				end
				ctx.state.hatchPhase = ("Hatching Hatch-team (%d)"):format(#normal)
				hatchList(normal)
			end
			if not CFG.hatchEnabled then return end
			-- pass BRONTO -> Bronto Team (+30% berat) + kirim Hatch Alert per pet
			if #bronto > 0 then
				if next(CFG.hatchBrontoTeam or {}) and not equipTeam(CFG.hatchBrontoTeam, "Bronto Team", CFG.hatchBrontoUnequipDelay, CFG.hatchBrontoEquipDelay) then return end
				if next(CFG.hatchBrontoTeam or {}) and (CFG.brontoTeamDelay or 5.5) > 0 then
					task.wait(CFG.brontoTeamDelay or 5.5)
				end
				ctx.state.hatchPhase = ("Hatching Bronto-team (%d)"):format(#bronto)
				for _, e in ipairs(bronto) do
					if not CFG.hatchEnabled then break end
					local cPets, mPets = getInventoryCapacity()
					if mPets > 0 and cPets >= mPets then
						handleInventoryFull(cPets, mPets)
						break
					end
					local pt, w = eggPending(e)
					-- pet ini di-hatch pakai Bronto team -> berat aktual +30% (buat tier Hunt)
					if pt then trackHatch(pt, w * 1.3, isBrontoSpecial(pt, w)); task.spawn(function() sendHatchAlert(pt, CFG.hatchEggName or "Rare Egg", w) end) end
					pcall(function() EggRemote:FireServer("HatchPet", e) end)
					ctx.state.hatchEggsHatched = (ctx.state.hatchEggsHatched or 0) + 1
				end
			end
			if not CFG.hatchEnabled then return end
			-- jumlah hatch (recovery-nya diisi listener notif). Beri jeda biar notif nyusul.
			ctx.state.periodHatched = (ctx.state.periodHatched or 0) + #normal + #bronto
			task.wait(1.5)
			-- 1 batch (normal+bronto) selesai = 1 ronde/cycle
			ctx.state.hatchRounds = (ctx.state.hatchRounds or 0) + 1
			-- TANDAI report pending. Webhook ga dikirim di sini — ditunda sampai garden
			-- ke-refill (place egg lagi) biar Current Amount stabil & Lucky Hatch keitung.
			if not (ctx.state.sellDoneThisReport) then ctx.state.hatchReportSellProg = nil end
			ctx.state.hatchPendingReport = true
			return
		end

		-- 4) INCUBATE: masih ada egg belum ready -> TETAP Core Team (speed), jangan switch/hatch
		ctx.state.hatchPhase = ("Incubating (%d/%d ready)"):format(#ready, placed)
		equipTeam(CFG.hatchCoreTeam, "Core Team")
		ctx.state.pnpBlockedByHatch = false
		ctx.state.hatchStatus = ("Nunggu egg ready (%d/%d)..."):format(#ready, placed)
	end

	local function loop()
		ctx.state.hatchId = (ctx.state.hatchId or 0) + 1
		local my = ctx.state.hatchId
		ctx.elevate()
		while CFG.hatchEnabled and ctx.alive() and ctx.state.hatchId == my do
			pcall(tick)
			task.wait(1.0)
		end
		ctx.state.hatchStatus = "Idle"
		ctx.state.pnpBlockedByHatch = false
		ctx.state.teamSwapActive = false
	end

	function ctx.startHatch()
		if ctx.cancelClearGarden then ctx.cancelClearGarden() end
		-- RESET semua statistik: tiap nyalain ulang mulai dari awal (webhook + live status)
		ctx.state.hatchEggsHatched = 0
		ctx.state.hatchRounds = 0
		ctx.state.hatchLastSellCycle = 0
		ctx.state.hatchReportSellProg = nil
		ctx.state.hatchSellCycles = 0
		ctx.state.hatchTiers = {}
		ctx.state.periodHatched = 0
		ctx.state.periodSold = 0
		ctx.state.periodHatchRec = 0
		ctx.state.periodSellRec = 0
		ctx.state.sellDoneThisReport = false
		ctx.state.hatchPendingReport = false
		ctx.state.hatchIsRejoining = false
		-- catat jumlah egg terpilih di awal (buat "Egg Before") = backpack + placed
		local eggName = CFG.hatchEggName or "Rare Egg"
		ctx.state.lastTrackedEggName = eggName
		ctx.state.hatchEggBefore = totalEggCount(eggName)
		ctx.state.hatchStartTime = os.time()
		ctx.state.hatchCycleStartTime = os.time()
		task.spawn(loop)
		task.spawn(sendStartHatchWebhook)
		if (CFG.hatchRejoinMinusEnabled or CFG.hatchRejoinPlusEnabled) and ctx.startEggMinusWatcher then
			ctx.startEggMinusWatcher()
		end
	end
	function ctx.stopHatch()
		ctx.state.hatchId = (ctx.state.hatchId or 0) + 1
		ctx.state.hatchStatus = "Idle"
		ctx.state.pnpBlockedByHatch = false
		ctx.state.teamSwapActive = false
	end

	----------------------------------------------------------------- AUTO FAVORITE
	-- Favoritin otomatis pet yg tipenya ada di CFG.favoritePetTypes (biar ga ke-sell).
	-- favoritePetTypes = key PET_OPTIONS (nama pet polos); tool attribute "f" = nama pet.
	function ctx.startAutoFavorite()
		ctx.state.autoFavId = (ctx.state.autoFavId or 0) + 1
		local my = ctx.state.autoFavId
		ctx.elevate()
		task.spawn(function()
			while CFG.autoFavorite and ctx.alive() and ctx.state.autoFavId == my do
				if next(CFG.favoritePetTypes or {}) then
					for _, t in ipairs(petTools()) do
						local pt = t:GetAttribute("f")
						local matchFav = pt and (ctx.petMatchesType and ctx.petMatchesType(CFG.favoritePetTypes, pt) or (CFG.favoritePetTypes)[pt])
						if matchFav and not isFav(t) then
							setFav(t, true)
						end
					end
				end
				task.wait(3)
			end
		end)
	end
	function ctx.stopAutoFavorite()
		ctx.state.autoFavId = (ctx.state.autoFavId or 0) + 1
	end

	----------------------------------------------------------------- AUTO UNFAVORITE
	-- Unfavoritin otomatis pet yg tipenya ada di CFG.unfavoritePetTypes (atau semua jika kosong).
	function ctx.startAutoUnfavorite()
		ctx.state.autoUnfavId = (ctx.state.autoUnfavId or 0) + 1
		local my = ctx.state.autoUnfavId
		ctx.elevate()
		task.spawn(function()
			while CFG.autoUnfavoritePets and ctx.alive() and ctx.state.autoUnfavId == my do
				for _, t in ipairs(petTools()) do
					local pt = t:GetAttribute("f")
					local match = (not next(CFG.unfavoritePetTypes or {})) or (pt and (ctx.petMatchesType and ctx.petMatchesType(CFG.unfavoritePetTypes, pt) or (CFG.unfavoritePetTypes)[pt]))
					if match and isFav(t) then
						setFav(t, false)
					end
				end
				task.wait(3)
			end
		end)
	end
	function ctx.stopAutoUnfavorite()
		ctx.state.autoUnfavId = (ctx.state.autoUnfavId or 0) + 1
	end

	----------------------------------------------------------------- EGG THRESHOLD WATCHER
	-- Watcher independen jika Auto Rejoin on Egg Minus / Plus diaktifkan, agar tetap terpantau
	-- meskipun Auto Hatch sedang idle atau di luar siklus hatch.
	local function eggMinusWatcherLoop(myId)
		while (CFG.hatchRejoinMinusEnabled or CFG.hatchRejoinPlusEnabled) and ctx.alive() and ctx.state.eggMinusWatchId == myId do
			-- Jika Auto Hatch aktif dan Auto Sell aktif, biarkan loop Auto Hatch yang mengecek setelah sell
			if not CFG.hatchEnabled or not CFG.autoSellEnabled then
				local shouldRejoin, rType, rEgg, rCur, rNet, rThresh = checkEggThreshold()
				if shouldRejoin then
					handleEggRejoin(rType, rEgg, rCur, rNet, rThresh)
					return
				end
			end
			task.wait(2.0)
		end
	end

	function ctx.startEggMinusWatcher()
		ctx.state.eggMinusWatchId = (ctx.state.eggMinusWatchId or 0) + 1
		local myId = ctx.state.eggMinusWatchId
		task.spawn(function() eggMinusWatcherLoop(myId) end)
	end
	function ctx.stopEggMinusWatcher()
		ctx.state.eggMinusWatchId = (ctx.state.eggMinusWatchId or 0) + 1
	end
end
]=],
	["modules/inventory/automation_accept.lua"] = [=[
--[[ accept.lua — Automation Accept.
     * Accept Gifts : gift pet LANGSUNG (tanpa trade/tiket). Remote GiftPet masuk,
                      dijawab AcceptPetGift:FireServer(true, giftId).
     * Accept Trades: auto-terima AJAKAN trade masuk (RespondRequest true) [menyusul].
     Dua hal berbeda — gift ≠ trade. ]]
return function(ctx)
	local CFG            = ctx.CFG
	local SendRequest    = ctx.deps.SendRequest
	local RespondRequest = ctx.deps.RespondRequest
	local GiftPet        = ctx.deps.GiftPet
	local AcceptPetGift  = ctx.deps.AcceptPetGift
	local TC             = ctx.deps.TradingController
	local Accept         = ctx.deps.Accept
	local Confirm        = ctx.deps.Confirm
	local function log(m) ctx.log(m) end

	----------------------------------------------------------------- AUTO ACCEPT GIFT
	-- GiftPet.OnClientEvent(giftId, petDescription, senderName)
	-- UI notif dibuat game di PlayerGui.Gift_Notification.Frame (tiap gift = 1 clone,
	-- tombolnya di notif.Holder.Frame.Accept). Kita picu klik tombol itu supaya
	-- handler asli jalan (destroy UI + fire AcceptPetGift) -> UI ikut hilang.
	local LP = ctx.LP

	local function clickAcceptButtons()
		local pg = LP:FindFirstChild("PlayerGui")
		local gn = pg and pg:FindFirstChild("Gift_Notification")
		local frame = gn and gn:FindFirstChild("Frame")
		if not frame then return 0 end
		local n = 0
		for _, notif in ipairs(frame:GetChildren()) do
			local holder = notif:FindFirstChild("Holder")
			local inner  = holder and holder:FindFirstChild("Frame")
			local accept = inner and inner:FindFirstChild("Accept")
			if accept then
				local fired = false
				if type(getconnections) == "function" then
					for _, c in ipairs(getconnections(accept.MouseButton1Click)) do
						pcall(function() c:Fire() end); fired = true
					end
				end
				if fired then n += 1 end
			end
		end
		return n
	end

	if GiftPet and AcceptPetGift then
		GiftPet.OnClientEvent:Connect(function(giftId, petDesc, sender)
			if not CFG.acceptGifts then return end
			if type(giftId) ~= "string" then return end
			log(("Gift masuk dari %s: %s"):format(tostring(sender), tostring(petDesc)))
			-- Terima langsung via remote tanpa jeda (instant response)
			pcall(function() AcceptPetGift:FireServer(true, giftId) end)
			task.spawn(function()
				task.wait(0.04)
				local clicked = clickAcceptButtons()
				local pg = LP:FindFirstChild("PlayerGui")
				local gn = pg and pg:FindFirstChild("Gift_Notification")
				local frame = gn and gn:FindFirstChild("Frame")
				if frame then for _, c in ipairs(frame:GetChildren()) do c:Destroy() end end
			end)
			log("Gift diterima ✓")
		end)
	else
		warn("[CeszParadise] GiftPet/AcceptPetGift remote tidak ketemu — auto accept gift nonaktif.")
	end

	----------------------------------------------------------------- AUTO ACCEPT TRADE
	-- 1) Terima AJAKAN masuk: SendRequest.OnClientEvent(reqId, sender) -> RespondRequest(reqId,true)
	if SendRequest and RespondRequest then
		pcall(function()
			SendRequest.OnClientEvent:Connect(function(requestId, senderPlayer)
				if not CFG.acceptTrades then return end
				log("Auto-terima ajakan trade dari " .. tostring(senderPlayer and senderPlayer.Name or "?"))
				task.wait(0.3)
				pcall(function() RespondRequest:FireServer(requestId, true) end)
			end)
		end)
	end

	-- 2) Di window trade masuk: auto Accept (pas cooldown habis) -> tunggu lawan -> Confirm.
	--    Penerima ngasih kosong. Guard: jangan ganggu Automation Trade kita sendiri.
	if TC and TC.OnTradeCreated and Accept and Confirm then
		TC.OnTradeCreated:Connect(function()
			if not CFG.acceptTrades then return end
			if ctx.state.tradeRunning then return end -- kita lagi jadi pengirim, jangan diganggu
			task.spawn(function()
				log("Window trade masuk — auto accept + confirm.")
				-- auto accept: spam pelan sampai status KITA jadi Accepted (cooldown habis)
				local myOk, a0 = false, os.clock()
				repeat
					pcall(function() Accept:FireServer() end)
					task.wait(1)
					local s = ctx.myState and ctx.myState(ctx.replicatorData())
					if s == "Accepted" or s == "Confirmed" then myOk = true; break end
				until (not (TC and TC.CurrentTradeReplicator)) or (os.clock() - a0) > 20
				if not myOk or not (TC and TC.CurrentTradeReplicator) then return end

				-- tunggu lawan accept
				local t0 = os.clock()
				local otherOk = false
				repeat
					task.wait(0.5)
					if ctx.otherAccepted and ctx.otherAccepted(ctx.replicatorData()) then otherOk = true; break end
				until (not (TC and TC.CurrentTradeReplicator)) or (os.clock() - t0) > 60
				if not otherOk or not (TC and TC.CurrentTradeReplicator) then return end

				-- confirm sampai trade tertutup
				t0 = os.clock()
				repeat
					pcall(function() Confirm:FireServer() end)
					task.wait(1.5)
				until (not (TC and TC.CurrentTradeReplicator)) or (os.clock() - t0) > 15
				log("Trade masuk selesai (confirmed).")
			end)
		end)
	end
end
]=],
	["modules/inventory/automation_trade.lua"] = [=[
--[[ trade.lua — inti Automation Trade.
     Alur per-trade: SendRequest -> tunggu window kebuka -> AddItem pets -> Accept
                     -> tunggu lawan accept -> Confirm -> tunggu selesai.
     Mengisi: ctx.getPlayers, ctx.getData, ctx.matchingPetUuids,
              ctx.startTrade, ctx.stopTrade ]]
return function(ctx)
	local Players     = ctx.Services.Players
	local LP          = ctx.LP
	local CFG         = ctx.CFG
	local DataService = ctx.deps.DataService
	local TC          = ctx.deps.TradingController
	local SendRequest = ctx.deps.SendRequest
	local AddItem     = ctx.deps.AddItem
	local Accept      = ctx.deps.Accept
	local Confirm     = ctx.deps.Confirm
	local Decline     = ctx.deps.Decline
	local FavoriteItem = ctx.deps.FavoriteItem
	local function log(m) ctx.log(m) end
	local function setStatus(s) ctx.setStatus(s) end

	----------------------------------------------------------------- data helpers
	local function getData()
		local ok, d = pcall(function() return DataService:GetData() end)
		if ok then return d end
		return nil
	end
	ctx.getData = getData

	local function getPlayers()
		local list = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LP then list[#list + 1] = p.Name end
		end
		table.sort(list)
		return list
	end
	ctx.getPlayers = getPlayers

	-- cek pet cocok dengan filter CFG (bisa mode ticket atau gift)
	local function petPasses(v, isGift)
		local pt = v.PetType
		local pd = v.PetData
		if not (pt and pd) then return false end
		-- filter type (kosong = semua)
		local pTypes = isGift and CFG.giftPetTypes or CFG.petTypes
		local matchType = (ctx.petMatchesType and ctx.petMatchesType(pTypes, pt, pd)) or (pTypes and pTypes[pt])
		if pTypes and next(pTypes) and not matchType then return false end
		-- weight: berat TAMPIL di game = BaseWeight + 0.5 (pakai angka tampilan di filter)
		local w = (pd.BaseWeight or 0) + 0.5
		local wf = isGift and (CFG.giftWeightFilter or 0) or (CFG.weightFilter or 0)
		if wf > 0 and w < wf then return false end
		if wf < 0 and w > -wf then return false end
		-- age (Level)
		local age = pd.Level or 0
		local af = isGift and (CFG.giftAgeFilter or 0) or (CFG.ageFilter or 0)
		if af > 0 and age < af then return false end
		if af < 0 and age > -af then return false end
		return true
	end

	-- kumpulkan uuid pet yang cocok (maksimal `limit`)
	local function matchingPetUuids(limit, isGift)
		local out = {}
		local d = getData()
		local pinv = d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data
		if not pinv then return out end
		-- pet yang lagi di-equip jangan di-trade
		local equipped = {}
		if d.PetsData.EquippedPets then for _, u in ipairs(d.PetsData.EquippedPets) do equipped[u] = true end end
		local autoUnfav = isGift and CFG.giftAutoUnfavorite or CFG.autoUnfavorite
		for uuid, v in pairs(pinv) do
			if #out >= limit then break end
			if not equipped[uuid] and petPasses(v, isGift) then
				local fav = v.PetData.IsFavorite
				if (not fav) or autoUnfav then
					out[#out + 1] = { uuid = uuid, fav = fav, petType = v.PetType }
				end
			end
		end
		return out
	end
	ctx.matchingPetUuids = matchingPetUuids

	-- Hitung SEMUA pet yang cocok filter (tanpa limit) untuk status GUI.
	function ctx.countMatchingPets(isGift)
		if isGift == nil then isGift = (CFG.tradeMethod == "gift") end
		local n = 0
		local d = getData()
		local pinv = d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data
		if not pinv then return 0 end
		local equipped = {}
		if d.PetsData.EquippedPets then for _, u in ipairs(d.PetsData.EquippedPets) do equipped[u] = true end end
		local autoUnfav = isGift and CFG.giftAutoUnfavorite or CFG.autoUnfavorite
		for uuid, v in pairs(pinv) do
			if not equipped[uuid] and petPasses(v, isGift) then
				local fav = v.PetData.IsFavorite
				if (not fav) or autoUnfav then n = n + 1 end
			end
		end
		return n
	end

	-- PRE-PASS: unfavorite SEMUA pet favorite yang lolos filter dulu (dipanggil di awal
	-- trade). Biar ga ke-race pas add item (unfav satu-satu tiap batch rawan gagal).
	local function unfavoriteAllMatching(isGift)
		local autoUnfav = isGift and CFG.giftAutoUnfavorite or CFG.autoUnfavorite
		if not (autoUnfav and FavoriteItem) then return end
		local d = getData()
		local pinv = d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data
		if not pinv then return end
		local equipped = {}
		if d.PetsData.EquippedPets then for _, u in ipairs(d.PetsData.EquippedPets) do equipped[u] = true end end
		local favSet, favCount = {}, 0
		for uuid, v in pairs(pinv) do
			if not equipped[uuid] and petPasses(v, isGift) and v.PetData.IsFavorite then
				favSet[uuid] = true; favCount = favCount + 1
			end
		end
		if favCount == 0 then return end
		setStatus(("Unfavorite %d pet target dulu..."):format(favCount))
		local Favorite_Item_BE = game:GetService("ReplicatedStorage").GameEvents:FindFirstChild("Favorite_Item_BE")
		local done = 0
		for _, src in ipairs({ LP:FindFirstChildOfClass("Backpack"), LP.Character }) do
			if src then for _, t in ipairs(src:GetChildren()) do
				local u = t:IsA("Tool") and t:GetAttribute("PET_UUID")
				if u and favSet[u] then
					pcall(function() FavoriteItem:FireServer(t) end)
					if Favorite_Item_BE then pcall(function() Favorite_Item_BE:Fire(t) end) end
					favSet[u] = nil; done = done + 1
					task.wait(0.04)
				end
			end end
		end
		if done > 0 then task.wait(0.2) end -- kasih waktu sync sebelum mulai trade
	end
	ctx.unfavoriteAllMatching = unfavoriteAllMatching

	----------------------------------------------------------------- trade-state read
	local function replicatorData()
		if not (TC and TC.CurrentTradeReplicator) then return nil end
		local rep = TC.CurrentTradeReplicator
		local ok, d = pcall(function() return rep:GetDataAsync() end)
		if ok and d then return d end
		ok, d = pcall(function() return rep:GetData() end)
		if ok then return d end
		return nil
	end

	ctx.replicatorData = replicatorData

	-- Skema (dari remote-spy): d.players = {p1,p2}, d.states = {[1]="None"/"Accepted", [2]=...}
	-- state index sejajar dengan players. Lawan dianggap accept kalau statenya "Accepted"/"Confirmed".
	local function stateOf(d, wantSelf)
		if type(d) ~= "table" then return nil end
		local players = d.players or d.Players
		local states  = d.states or d.States
		if type(players) ~= "table" or type(states) ~= "table" then return nil end
		local idx
		for i, p in ipairs(players) do
			if wantSelf then if p == LP then idx = i end
			else if p ~= LP then idx = i end end
		end
		if not idx then return nil end
		return states[idx]
	end
	local function otherState(d) return stateOf(d, false) end
	local function myState(d) return stateOf(d, true) end
	ctx.myState = myState
	local function otherAccepted(d)
		local s = otherState(d)
		return s == "Accepted" or s == "Confirmed"
	end
	ctx.otherAccepted = otherAccepted

	-- Trade cuma bisa dikirim kalau kita lagi MEGANG Trading Ticket.
	local function equipTradingTicket()
		local char = LP.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hum then return false end
		-- sudah megang tiket?
		for _, t in ipairs(char:GetChildren()) do
			if t:IsA("Tool") and t.Name:find("Trading Ticket") then return true end
		end
		local bp = LP:FindFirstChild("Backpack")
		if not bp then return false end
		for _, t in ipairs(bp:GetChildren()) do
			if t:IsA("Tool") and t.Name:find("Trading Ticket") then
				pcall(function() hum:EquipTool(t) end)
				task.wait(0.3)
				return true
			end
		end
		return false
	end
	ctx.equipTradingTicket = equipTradingTicket

	----------------------------------------------------------------- one trade
	local function doOneTrade(target)
		-- Cek dulu ketersediaan pet yang cocok sebelum melakukan apapun!
		local pets = matchingPetUuids(CFG.petsPerTrade)
		if #pets == 0 then
			log("Tidak ada pet cocok filter. Stop send ticket request.")
			setStatus("Tidak ada pet cocok filter. Auto stop.")
			ctx.state.tradeRunning = false
			CFG.tradeEnabled = false
			if ctx.persistState then ctx.persistState() end
			if ctx.refreshTradeStatus then ctx.refreshTradeStatus() end
			return false
		end

		-- pegang tiket dulu, wajib biar panel trade kebuka
		if not equipTradingTicket() then
			log("Trading Ticket tidak ada / gagal di-equip. Stop.")
			ctx.state.tradeRunning = false
			return false
		end
		setStatus("Kirim ajakan ke " .. target.Name)
		pcall(function() SendRequest:FireServer(target) end)

		-- tunggu window trade kebuka (lawan accept request)
		local t0 = os.clock()
		repeat task.wait(0.3) until (not ctx.state.tradeRunning) or (TC and TC.CurrentTradeReplicator) or (os.clock() - t0) > 20
		if not ctx.state.tradeRunning then return false end
		if not (TC and TC.CurrentTradeReplicator) then
			log("Timeout: " .. target.Name .. " tidak accept ajakan.")
			return false
		end

		-- re-check ketersediaan pet setelah trade terbuka
		pets = matchingPetUuids(CFG.petsPerTrade)
		if #pets == 0 then
			log("Tidak ada pet cocok filter. Batalkan trade.")
			pcall(function() Decline:FireServer() end)
			ctx.state.tradeRunning = false
			CFG.tradeEnabled = false
			if ctx.persistState then ctx.persistState() end
			if ctx.refreshTradeStatus then ctx.refreshTradeStatus() end
			return false
		end

		-- auto unfavorite dulu kalau perlu.
		-- PENTING: Favorite_Item butuh TOOL object (bukan uuid). Cari tool di Backpack/Character.
		if CFG.autoUnfavorite and FavoriteItem then
			local Favorite_Item_BE = game:GetService("ReplicatedStorage").GameEvents:FindFirstChild("Favorite_Item_BE")
			local function findToolByUuid(uuid)
				local bp = LP:FindFirstChildOfClass("Backpack")
				if bp then for _, t in ipairs(bp:GetChildren()) do
					if t:IsA("Tool") and t:GetAttribute("PET_UUID") == uuid then return t end
				end end
				if LP.Character then for _, t in ipairs(LP.Character:GetChildren()) do
					if t:IsA("Tool") and t:GetAttribute("PET_UUID") == uuid then return t end
				end end
				return nil
			end
			for _, p in ipairs(pets) do
				if p.fav then
					local tool = findToolByUuid(p.uuid)
					if tool then
						pcall(function() FavoriteItem:FireServer(tool) end)
						if Favorite_Item_BE then pcall(function() Favorite_Item_BE:Fire(tool) end) end
						task.wait(0.15)
					end
				end
			end
			task.wait(0.3)
		end

		-- add item (percepat proses pengisian pet)
		log(("Cocok %d pet. Mengisi offer..."):format(#pets))
		setStatus(("Menambah %d pet..."):format(#pets))
		for _, p in ipairs(pets) do
			if not ctx.state.tradeRunning then break end
			pcall(function() AddItem:FireServer("Pet", p.uuid) end)
			task.wait(0.06)
		end

		-- verifikasi berapa pet yang benar-benar masuk ke offer kita
		task.wait(0.4)
		do
			local d = replicatorData()
			local myIdx
			if d and d.players then for i, pl in ipairs(d.players) do if pl == LP then myIdx = i end end end
			local n = 0
			if d and myIdx and d.offers and d.offers[myIdx] then
				for _ in pairs(d.offers[myIdx].items or {}) do n += 1 end
			end
			log(("Pet masuk ke offer: %d/%d"):format(n, #pets))
			if n == 0 then
				log("AddItem tidak masuk — cek: pet favorit? equipped? uuid?")
			end
		end

		-- Auto-accept: game punya cooldown anti-scam sebelum tombol Accept aktif.
		-- Daripada nebak durasinya, kita spam Accept pelan sampai status KITA jadi
		-- "Accepted" (artinya cooldown sudah habis & Accept kebaca). Otomatis nunggu pas.
		setStatus("Accept (nunggu cooldown game)...")
		local myOk = false
		local a0 = os.clock()
		repeat
			pcall(function() Accept:FireServer() end)
			task.wait(1)
			local s = myState(replicatorData())
			if s == "Accepted" or s == "Confirmed" then myOk = true; break end
		until (not ctx.state.tradeRunning) or (not (TC and TC.CurrentTradeReplicator)) or (os.clock() - a0) > 20
		if not ctx.state.tradeRunning or not (TC and TC.CurrentTradeReplicator) then return false end
		if not myOk then
			log("Accept kita belum kebaca setelah 20s. Batalkan.")
			pcall(function() Decline:FireServer() end)
			return false
		end
		log("Accept kita OK.")
		setStatus("Menunggu lawan accept...")

		-- tunggu lawan accept
		t0 = os.clock()
		local accepted = false
		repeat
			task.wait(0.5)
			if otherAccepted(replicatorData()) then accepted = true; break end
		until (not ctx.state.tradeRunning) or (not (TC and TC.CurrentTradeReplicator)) or (os.clock() - t0) > 30
		if not ctx.state.tradeRunning then return false end
		if not (TC and TC.CurrentTradeReplicator) then
			log("Trade ditutup sebelum selesai.")
			return false
		end
		if not accepted then
			log("Lawan tidak accept (timeout). Batalkan.")
			pcall(function() Decline:FireServer() end)
			return false
		end

		-- confirm (retry sampai trade tertutup)
		setStatus("Confirm... menunggu selesai")
		t0 = os.clock()
		repeat
			pcall(function() Confirm:FireServer() end)
			task.wait(1.5)
		until (not (TC and TC.CurrentTradeReplicator)) or (not ctx.state.tradeRunning) or (os.clock() - t0) > 15
		if TC and TC.CurrentTradeReplicator then
			log("Confirm terkirim tapi trade belum tertutup.")
			return false
		end
		return true
	end

	----------------------------------------------------------------- one gift (tanpa ticket)
	local function doOneGift(target)
		local pets = matchingPetUuids(CFG.petsPerTrade or 1)
		if #pets == 0 then
			log("Tidak ada pet cocok filter untuk Gift. Stop.")
			setStatus("Pet cocok filter 0. Auto stop.")
			ctx.state.tradeRunning = false
			CFG.tradeEnabled = false
			if ctx.persistState then ctx.persistState() end
			if ctx.refreshTradeStatus then ctx.refreshTradeStatus() end
			return false
		end

		local targetChar = target.Character
		local targetHrp = targetChar and (targetChar:FindFirstChild("HumanoidRootPart") or targetChar.PrimaryPart)
		if not targetHrp then
			log("Target " .. target.Name .. " belum spawn / tidak ada character.")
			setStatus("Target tidak ada character.")
			return false
		end

		local myChar = LP.Character
		local myHrp = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar.PrimaryPart)
		local hum = myChar and myChar:FindFirstChildOfClass("Humanoid")
		if not myHrp or not hum then
			log("Character kita belum siap.")
			return false
		end

		-- Teleport dekat target (berdiri di depan target dalam jarak ~3 stud)
		local dist = (myHrp.Position - targetHrp.Position).Magnitude
		if dist > 6 then
			setStatus(("Mendekat ke %s (jarak: %.1f)..."):format(target.Name, dist))
			pcall(function()
				myHrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, -3) * CFrame.Angles(0, math.pi, 0)
			end)
			task.wait(0.1)
		end

		local GiftPet = ctx.deps.GiftPet or game:GetService("ReplicatedStorage").GameEvents:FindFirstChild("GiftPet")
		local Gift = ctx.deps.Gift or game:GetService("ReplicatedStorage").GameEvents:FindFirstChild("Gift")
		local Favorite_Item = ctx.deps.FavoriteItem or game:GetService("ReplicatedStorage").GameEvents:FindFirstChild("Favorite_Item")
		local Favorite_Item_BE = game:GetService("ReplicatedStorage").GameEvents:FindFirstChild("Favorite_Item_BE")

		local function findToolByUuid(uuid)
			local bp = LP:FindFirstChildOfClass("Backpack")
			if bp then for _, t in ipairs(bp:GetChildren()) do
				if t:IsA("Tool") and t:GetAttribute("PET_UUID") == uuid then return t end
			end end
			if LP.Character then for _, t in ipairs(LP.Character:GetChildren()) do
				if t:IsA("Tool") and t:GetAttribute("PET_UUID") == uuid then return t end
			end end
			return nil
		end

		local sentCount = 0

		for _, p in ipairs(pets) do
			if not ctx.state.tradeRunning then break end
			local tool = findToolByUuid(p.uuid)
			if tool then
				-- Auto unfavorite jika difavoritkan
				if p.fav and Favorite_Item then
					pcall(function() Favorite_Item:FireServer(tool) end)
					if Favorite_Item_BE then pcall(function() Favorite_Item_BE:Fire(tool) end) end
				end

				-- Equip tool ke character dan tunggu sampai ter-equip (polling kilat 0.02s)
				if hum and tool.Parent ~= LP.Character then
					hum:EquipTool(tool)
					local eq0 = os.clock()
					repeat task.wait(0.02) until tool.Parent == LP.Character or (os.clock() - eq0) > 0.8
				end

				-- Pastikan masih dekat target
				if myHrp and targetHrp and (myHrp.Position - targetHrp.Position).Magnitude > 6 then
					pcall(function()
						myHrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, -3) * CFrame.Angles(0, math.pi, 0)
					end)
				end

				setStatus(("Mengirim gift pet ke %s..."):format(target.Name))

				-- 1. Picu interaksi ProximityPrompt di target character (tanpa hold delay)
				if target.Character then
					for _, desc in ipairs(target.Character:GetDescendants()) do
						if desc:IsA("ProximityPrompt") then
							local aText = desc.ActionText:lower()
							local oText = desc.ObjectText:lower()
							local pName = desc.Name:lower()
							if aText:find("gift") or oText:find("gift") or pName:find("gift") or aText:find("give") then
								pcall(function()
									desc.HoldDuration = 0
									if type(fireproximityprompt) == "function" then
										fireproximityprompt(desc, 0)
										fireproximityprompt(desc)
									else
										desc:InputHoldBegin()
										desc:InputHoldEnd()
									end
								end)
								break
							end
						end
					end
				end

				-- 2. Picu Remote Events langsung
				if GiftPet then
					pcall(function() GiftPet:FireServer(target, tool) end)
					pcall(function() GiftPet:FireServer(target) end)
					pcall(function() GiftPet:FireServer(target, p.uuid) end)
					pcall(function() GiftPet:FireServer(tool, target) end)
					pcall(function() GiftPet:FireServer(target.Character) end)
				end
				if Gift then
					pcall(function() Gift:FireServer(target, tool) end)
					pcall(function() Gift:FireServer(target) end)
					pcall(function() Gift:FireServer(target, p.uuid) end)
					pcall(function() Gift:FireServer(tool, target) end)
					pcall(function() Gift:FireServer(target.Character) end)
				end

				local GE = game:GetService("ReplicatedStorage"):FindFirstChild("GameEvents")
				if GE then
					local sendGift = GE:FindFirstChild("SendGift") or GE:FindFirstChild("GiftItem")
					if sendGift and sendGift:IsA("RemoteEvent") then
						pcall(function() sendGift:FireServer(target, tool) end)
						pcall(function() sendGift:FireServer(target) end)
					end
				end

				-- 3. Coba tool:Activate()
				pcall(function() tool:Activate() end)

				-- Tunggu verifikasi cepat apakah pet sudah terkirim / diterima lawan (tool hilang)
				local waitStart = os.clock()
				local petGone = false
				while (os.clock() - waitStart) < 1.8 and ctx.state.tradeRunning do
					if not findToolByUuid(p.uuid) then
						petGone = true
						break
					end
					task.wait(0.04)
					-- Jika belum terkirim setelah 0.25s, picu ulang prompt & remote
					if (os.clock() - waitStart) > 0.25 and math.floor((os.clock() - waitStart) * 100) % 25 == 0 then
						if target.Character then
							for _, desc in ipairs(target.Character:GetDescendants()) do
								if desc:IsA("ProximityPrompt") then
									pcall(function()
										desc.HoldDuration = 0
										if type(fireproximityprompt) == "function" then
											fireproximityprompt(desc, 0)
										else
											desc:InputHoldBegin()
											desc:InputHoldEnd()
										end
									end)
									break
								end
							end
						end
						if GiftPet then pcall(function() GiftPet:FireServer(target, tool) end) end
						if Gift then pcall(function() Gift:FireServer(target, tool) end) end
					end
				end

				if petGone then
					sentCount = sentCount + 1
					log(("Gift terkirim & diterima %s: %s"):format(target.Name, tostring(p.petType or "Pet")))
				else
					log(("Gift %s ke %s timeout/belum diterima."):format(tostring(p.petType or "Pet"), target.Name))
				end
				task.wait(0.04)
			end
		end

		return sentCount > 0
	end

	----------------------------------------------------------------- loop
	local function tradeLoop()
		ctx.elevate()
		local isGift = (CFG.tradeMethod == "gift")
		unfavoriteAllMatching(isGift) -- unfav semua target favorite dulu, baru mulai trade
		while ctx.state.tradeRunning do
			local totalLimit = isGift and (CFG.giftTotalGifts or CFG.totalTrades) or CFG.totalTrades
			if ctx.state.completed >= totalLimit then
				ctx.state.status = "DONE"
				setStatus(("Selesai %d/%d %s."):format(ctx.state.completed, totalLimit, isGift and "gift" or "trade"))
				ctx.state.tradeRunning = false
				if isGift then CFG.tradeGiftEnabled = false else CFG.tradeTicketEnabled = false; CFG.tradeEnabled = false end
				if ctx.refreshTradeStatus then ctx.refreshTradeStatus() end
				if ctx.refreshGiftStatus then ctx.refreshGiftStatus() end
				break
			end
			-- Stop kalau pet cocok filter sudah habis -> jangan kirim trade/gift lagi.
			if ctx.countMatchingPets(isGift) == 0 then
				ctx.state.status = "DONE"
				setStatus("Pet habis (sesuai filter). " .. (isGift and "Gift" or "Trade") .. " dihentikan.")
				ctx.state.tradeRunning = false
				if isGift then CFG.tradeGiftEnabled = false else CFG.tradeTicketEnabled = false; CFG.tradeEnabled = false end
				if ctx.persistState then ctx.persistState() end
				if ctx.refreshTradeStatus then ctx.refreshTradeStatus() end
				if ctx.refreshGiftStatus then ctx.refreshGiftStatus() end
				break
			end

			local targetName = isGift and (CFG.giftTargetPlayer ~= "" and CFG.giftTargetPlayer or CFG.targetPlayer) or CFG.targetPlayer
			local target = targetName ~= "" and Players:FindFirstChild(targetName) or nil
			if not target then
				setStatus("Target player (" .. tostring(targetName) .. ") tidak ada / belum dipilih.")
				task.wait(1.5)
			else
				ctx.state.status = "RUNNING"
				if ctx.refreshTradeStatus then ctx.refreshTradeStatus() end
				if ctx.refreshGiftStatus then ctx.refreshGiftStatus() end
				local ok = isGift and doOneGift(target) or doOneTrade(target)
				if ok then
					ctx.state.completed += 1
					log(("%s sukses (%d/%d)"):format(isGift and "Gift" or "Trade", ctx.state.completed, totalLimit))
					if ctx.notifyTrade then
						local petLimit = isGift and (CFG.giftPetsPerBatch or 12) or CFG.petsPerTrade
						ctx.notifyTrade(target, #matchingPetUuids(petLimit, isGift))
					end
				end
				if ctx.refreshTradeStatus then ctx.refreshTradeStatus() end
				if ctx.refreshGiftStatus then ctx.refreshGiftStatus() end
				task.wait(isGift and 0.2 or 1.5)
			end
		end
	end

	function ctx.startTrade(method)
		if ctx.state.tradeRunning then return end
		if method then CFG.tradeMethod = method end
		ctx.state.tradeRunning = true
		ctx.state.status = "RUNNING"
		task.spawn(tradeLoop)
	end

	function ctx.stopTrade()
		ctx.state.tradeRunning = false
		ctx.state.status = "IDLE"
		if ctx.refreshTradeStatus then ctx.refreshTradeStatus() end
		if ctx.refreshGiftStatus then ctx.refreshGiftStatus() end
	end
end
]=],
	["modules/leveling/automation_leveling_v1.lua"] = [=[
--[[ leveling.lua — logika leveling pet otomatis (garden). ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local PetsService = ctx.deps.PetsService
	local CFG         = ctx.CFG
	local LP          = ctx.LP
	local RS          = game:GetService("ReplicatedStorage")

	local function farmCenter()
		local GetFarm = require(RS.Modules.GetFarm)
		local farm = GetFarm and GetFarm(LP)
		local pa = farm and farm:FindFirstChild("PetArea")
		if pa then return pa.Position end
		local char = LP.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		return hrp and hrp.Position or nil
	end

	local slotOf, nextSlot = {}, 0
	local GRID_COLS, GRID_SP = 6, 3
	local function getPos(uuid)
		if not slotOf[uuid] then slotOf[uuid] = nextSlot; nextSlot = nextSlot + 1 end
		local center = farmCenter()
		if not center then return nil end
		local i = slotOf[uuid]
		local col = i % GRID_COLS
		local row = math.floor(i / GRID_COLS)
		local offX = (col - (GRID_COLS - 1) / 2) * GRID_SP
		local offZ = (row - 1) * GRID_SP
		return center + Vector3.new(offX, 0, offZ)
	end

	local function matchesType(typeSet, pt, pd)
		if ctx.petMatchesType then return ctx.petMatchesType(typeSet, pt, pd) end
		return typeSet and typeSet[pt] == true
	end

	ctx.state.levelingStatus = "Idle"

	-- Mendapatkan ringkasan statistik leveling untuk UI
	function ctx.getLevelingSummary()
		local ok, d = pcall(function() return DataService:GetData() end)
		local inv = ok and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}
		
		local teamCount = 0
		for _ in pairs(CFG.levelingTeamUuids) do teamCount = teamCount + 1 end
		
		local typesList = {}
		for k in pairs(CFG.levelingPetTypes) do table.insert(typesList, k) end
		table.sort(typesList)
		local typesStr = #typesList > 0 and table.concat(typesList, ", ") or "None"
		
		local readyCount = 0
		local maxLvlCount = 0
		local targetLvl = CFG.levelingTargetLevel or 500
		
		for _, v in pairs(inv) do
			local pt = v.PetType
			if matchesType(CFG.levelingPetTypes, pt, v.PetData) then
				local pd = v.PetData or {}
				local lvl = pd.Level or 0
				if not pd.IsFavorite then
					if lvl < targetLvl then
						readyCount = readyCount + 1
					else
						maxLvlCount = maxLvlCount + 1
					end
				end
			end
		end
		
		return {
			status = CFG.levelingEnabled and "ACTIVE" or "STOPPED",
			team = string.format("%d pets selected", teamCount),
			types = typesStr,
			ready = string.format("%d pets", readyCount),
			maxLvl = string.format("%d pets", maxLvlCount),
			maxInGarden = string.format("%d pets", CFG.levelingMaxPets or 2),
			targetLevel = tostring(targetLvl),
		}
	end

	-- Mendapatkan semua tipe unik pet yang dimiliki di inventory
	function ctx.getInventoryPetTypes(selectedSet)
		local out, seen = {}, {}
		local ok, d = pcall(function() return DataService:GetData() end)
		local inv = ok and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data
		if inv then
			for _, v in pairs(inv) do
				local pt = v.PetType
				if pt and not seen[pt] then
					seen[pt] = true
					table.insert(out, { value = pt, display = pt })
				end
			end
		end
		-- Selalu tampilkan tipe yang DIPILIH walau stok 0 (biar pilihan ga ilang dari filter).
		if selectedSet then
			for t in pairs(selectedSet) do
				if not seen[t] then
					seen[t] = true
					table.insert(out, { value = t, display = t .. " (0 di inventory)" })
				end
			end
		end
		table.sort(out, function(a, b)
			local selA = selectedSet and selectedSet[a.value] and 1 or 0
			local selB = selectedSet and selectedSet[b.value] and 1 or 0
			if selA ~= selB then
				return selA > selB
			end
			return a.display < b.display
		end)
		return out
	end

	local function checkLeveling()
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d then return end
		local petsData = d.PetsData
		if not petsData then return end
		local eq = petsData.EquippedPets or {}
		local inv = petsData.PetInventory and petsData.PetInventory.Data or {}

		local teamSet = CFG.levelingTeamUuids or {}
		local targetTypes = CFG.levelingPetTypes or {}
		local targetLvl = CFG.levelingTargetLevel or 500
		local maxLvlPets = CFG.levelingMaxPets or 2

		-- Lacak status equip secara lokal agar kebal dari delay replikasi server
		local localEq = {}
		local localEqCount = 0
		for _, uuid in ipairs(eq) do
			localEq[uuid] = true
			localEqCount = localEqCount + 1
		end

		-- A. DETEKSI FIRST RUN: Cabut semua pet jika ada pet aktif
		if ctx.state.levelingFirstRun then
			ctx.state.levelingFirstRun = false
			if #eq > 0 then
				ctx.state.levelingStatus = "Resetting garden..."
				for _, uuid in ipairs(eq) do
					pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
					localEq[uuid] = nil
					localEqCount = localEqCount - 1
					task.wait(0.25)
				end
			end
		end

		-- B. DETEKSI PERSISTENSI TEAM: Pasang kembali pet team yang dicabut oleh user/game
		for uuid, _ in pairs(teamSet) do
			if not localEq[uuid] then
				ctx.state.levelingStatus = "Re-equipping team..."
				local pos = getPos(uuid)
				if pos then
					pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
					localEq[uuid] = true
					localEqCount = localEqCount + 1
					task.wait(0.3)
				end
			end
		end

		-- C. KLASIFIKASI PET YANG SEDANG DI-EQUIP (berdasarkan localEq terbaru)
		local currentLeveling = {}   -- list of active leveling uuids (lvl < targetLvl)
		local finishedLeveling = {}  -- list of finished leveling uuids (lvl >= targetLvl)
		local otherEquipped = {}     -- list of other uuids (not team, not target type)

		for uuid, _ in pairs(localEq) do
			if not teamSet[uuid] then
				local pInfo = inv[uuid]
				local pt = pInfo and pInfo.PetType
				local pd = pInfo and pInfo.PetData or {}
				local lvl = pd.Level or 0

				if matchesType(targetTypes, pt, pd) then
					if lvl < targetLvl then
						table.insert(currentLeveling, uuid)
						-- Catat waktu mulai jika belum ada
						ctx.state.levelingStartTime = ctx.state.levelingStartTime or {}
						if not ctx.state.levelingStartTime[uuid] then
							ctx.state.levelingStartTime[uuid] = os.time()
						end
					else
						table.insert(finishedLeveling, uuid)
					end
				else
					table.insert(otherEquipped, uuid)
				end
			end
		end

		-- D. LEPAS PET LEVELING YANG SUDAH SELESAI (mencapai target level)
		for _, uuid in ipairs(finishedLeveling) do
			local duration = 0
			if ctx.state.levelingStartTime and ctx.state.levelingStartTime[uuid] then
				duration = os.time() - ctx.state.levelingStartTime[uuid]
				ctx.state.levelingStartTime[uuid] = nil
			end

			local pInfo = inv[uuid]
			local petType = pInfo and pInfo.PetType or "Unknown"
			local pd = pInfo and pInfo.PetData or {}
			local mutation = pd.MutationType or "Normal"
			local finalAge = pd.Level or targetLvl

			pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
			localEq[uuid] = nil
			localEqCount = localEqCount - 1
			task.wait(0.25)

			-- Hitung sisa antrean
			local remainsQueue = 0
			for otherUuid, v in pairs(inv) do
				local pt = v.PetType
				local otherPd = v.PetData or {}
				if matchesType(targetTypes, pt, otherPd) and not localEq[otherUuid] then
					local otherLvl = otherPd.Level or 0
					if otherLvl < targetLvl and not otherPd.IsFavorite then
						remainsQueue = remainsQueue + 1
					end
				end
			end

			-- Kirim Webhook Finished
			task.spawn(function()
				local WebhookLev = ctx.webhookLeveling
				if WebhookLev then
					pcall(function() WebhookLev.sendFinished(ctx, petType, mutation, finalAge, duration, remainsQueue) end)
				end
			end)
		end

		-- E. TAMBAHKAN PET BARU DARI INVENTORY
		local currentActiveCount = #currentLeveling
		local needed = maxLvlPets - currentActiveCount

		if needed > 0 then
			-- Cari pool pet di inventory yang tidak ter-equip di localEq
			local pool = {}
			for uuid, v in pairs(inv) do
				local pt = v.PetType
				local pd = v.PetData or {}
				local lvl = pd.Level or 0

				if not localEq[uuid] and matchesType(targetTypes, pt, pd) and lvl < targetLvl and not pd.IsFavorite then
					table.insert(pool, { uuid = uuid, petType = pt, level = lvl })
				end
			end
			table.sort(pool, function(a, b) return a.level < b.level end) -- Prioritaskan level terendah

			for i = 1, math.min(needed, #pool) do
				local target = pool[i]
				local pos = getPos(target.uuid)
				if pos then
					-- Jika total equipped secara lokal penuh (misal >= 15), copot non-team non-leveling
					if localEqCount >= 15 and #otherEquipped > 0 then
						local toRemove = table.remove(otherEquipped)
						pcall(function() PetsService:FireServer("UnequipPet", toRemove) end)
						localEq[toRemove] = nil
						localEqCount = localEqCount - 1
						task.wait(0.25)
					end
					
					pcall(function() PetsService:FireServer("EquipPet", target.uuid, CFrame.new(pos)) end)
					localEq[target.uuid] = true
					localEqCount = localEqCount + 1
					table.insert(currentLeveling, target.uuid)
					-- Catat waktu mulai
					ctx.state.levelingStartTime = ctx.state.levelingStartTime or {}
					ctx.state.levelingStartTime[target.uuid] = os.time()
					task.wait(0.3)
				end
			end
		end

		-- Update status akhir setelah proses
		ctx.state.levelingStatus = string.format("Leveling: %d/%d aktif", #currentLeveling, maxLvlPets)
	end

	local function levelingLoop()
		ctx.state.levelingId = (ctx.state.levelingId or 0) + 1
		local myId = ctx.state.levelingId
		ctx.elevate()
		
		ctx.state.levelingFirstRun = true

		-- Kirim webhook Enabled
		task.spawn(function()
			local WebhookLev = ctx.webhookLeveling
			if WebhookLev then
				local queueList = {}
				local teamList = {}
				local okData, d = pcall(function() return DataService:GetData() end)
				if okData and d and d.PetsData then
					local inv = d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}
					
					-- 1. Antrean pet target
					local targetTypes = CFG.levelingPetTypes or {}
					local targetLvl = CFG.levelingTargetLevel or 500
					for _, v in pairs(inv) do
						local pt = v.PetType
						if matchesType(targetTypes, pt, v.PetData) then
							local pd = v.PetData or {}
							local lvl = pd.Level or 0
							if lvl < targetLvl then
								table.insert(queueList, { type = pt, level = lvl })
							end
						end
					end

					-- 2. Nama pet dalam EXP team
					local teamUuids = CFG.levelingTeamUuids or {}
					for uuid, _ in pairs(teamUuids) do
						local pInfo = inv[uuid]
						if pInfo then
							table.insert(teamList, pInfo.PetType)
						end
					end
				end
				pcall(function() WebhookLev.sendEnabled(ctx, queueList, teamList) end)
			end
		end)
		
		while CFG.levelingEnabled and ctx.alive() and ctx.state.levelingId == myId do
			pcall(checkLeveling)
			task.wait(3.0)
		end
		ctx.state.levelingStatus = "Idle"
	end

	function ctx.startLeveling()
		if ctx.cancelClearGarden then ctx.cancelClearGarden() end -- batalkan clear tertunda
		task.spawn(levelingLoop) -- loop set firstRun=true -> reset garden + equip team
	end

	-- Batalkan clearGarden yang mungkin lagi jalan (dipanggil saat fitur di-ENABLE lagi,
	-- biar pet team yang baru dipasang ga ke-unequip balik oleh clear yang tertunda).
	function ctx.cancelClearGarden()
		ctx.state.clearGardenId = (ctx.state.clearGardenId or 0) + 1
	end

	-- Lepas SEMUA pet dari garden (dipakai stop leveling/mutation/cleanse, mirror elephant).
	function ctx.clearGarden(label)
		ctx.state.clearGardenId = (ctx.state.clearGardenId or 0) + 1
		local myGen = ctx.state.clearGardenId
		task.spawn(function()
			if ctx.setStatus then ctx.setStatus((label or "Clear") .. ": lepas pet dari garden...") end
			task.wait(0.3)
			for _ = 1, 30 do
				if ctx.state.clearGardenId ~= myGen then return end -- dibatalkan (fitur di-enable lagi)
				local ok, d = pcall(function() return DataService:GetData() end)
				local eq = ok and d and d.PetsData and d.PetsData.EquippedPets or {}
				if #eq == 0 then break end
				for _, uuid in ipairs(eq) do
					if ctx.state.clearGardenId ~= myGen then return end
					pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
					task.wait(0.2)
				end
				task.wait(0.4)
			end
			if ctx.state.clearGardenId == myGen and ctx.setStatus then ctx.setStatus((label or "Clear") .. ": garden kosong.") end
		end)
	end

	function ctx.stopLeveling()
		ctx.state.levelingId = (ctx.state.levelingId or 0) + 1 -- matikan loop
		ctx.clearGarden("Leveling")
	end
end
]=],
	["modules/leveling/automation_leveling_v2.lua"] = [=[
--[[ leveling_v2.lua — Automation Leveling V2 (2 phase).
     Konsep sama dengan V1 tapi bertahap:
       Phase 1: pakai Phase 1 Team, level target pet dari age 1 s/d Phase 1 Target,
                max Phase 1 Max Pets di garden.
       Phase 2: setelah semua target pet >= Phase 1 Target, ganti ke Phase 2 Team,
                level s/d Phase 2 Target (final), max Phase 2 Max Pets.
     Team & jumlah pet di garden beda per-phase (mis. cepat di awal, sedikit di akhir). ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local PetsService = ctx.deps.PetsService
	local CFG = ctx.CFG
	local LP  = ctx.LP
	local RS  = game:GetService("ReplicatedStorage")

	----------------------------------------------------------------- posisi grid
	local function farmCenter()
		local GetFarm = require(RS.Modules.GetFarm)
		local farm = GetFarm and GetFarm(LP)
		local pa = farm and farm:FindFirstChild("PetArea")
		if pa then return pa.Position end
		local char = LP.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		return hrp and hrp.Position or nil
	end
	local slotOf, nextSlot = {}, 0
	local GRID_COLS, GRID_SP = 6, 3
	local function getPos(uuid)
		if not slotOf[uuid] then slotOf[uuid] = nextSlot; nextSlot = nextSlot + 1 end
		local center = farmCenter()
		if not center then return nil end
		local i = slotOf[uuid]
		local col = i % GRID_COLS
		local row = math.floor(i / GRID_COLS)
		return center + Vector3.new((col - (GRID_COLS - 1) / 2) * GRID_SP, 0, (row - 1) * GRID_SP)
	end

	local function matchesType(typeSet, pt, pd)
		if ctx.petMatchesType then return ctx.petMatchesType(typeSet, pt, pd) end
		return typeSet and typeSet[pt] == true
	end

	ctx.state.levelingV2Status = "Idle"

	----------------------------------------------------------------- ringkasan status
	function ctx.getLevelingV2Summary()
		local ok, d = pcall(function() return DataService:GetData() end)
		local inv = ok and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}
		local types = CFG.levelingV2PetTypes or {}
		local p1t = CFG.levelingV2P1Target or 40
		local p2t = CFG.levelingV2P2Target or 500
		local p1q, p2q, maxq = 0, 0, 0
		for _, v in pairs(inv) do
			if matchesType(types, v.PetType, v.PetData) and not (v.PetData or {}).IsFavorite then
				local lvl = (v.PetData or {}).Level or 0
				if lvl < p1t then p1q = p1q + 1
				elseif lvl < p2t then p2q = p2q + 1
				else maxq = maxq + 1 end          -- udah >= target final = max level
			end
		end
		local function cnt(t) local n = 0; for _ in pairs(t or {}) do n = n + 1 end; return n end
		local function nm(t) local o = {}; for k in pairs(t or {}) do o[#o + 1] = k end; return #o > 0 and table.concat(o, ", ") or "-" end
		return {
			status = CFG.levelingV2Enabled and "ACTIVE" or "STOPPED",
			phase = ctx.state.levelingV2Phase or "-",
			types = nm(types),
			p1team = cnt(CFG.levelingV2P1Team), p2team = cnt(CFG.levelingV2P2Team),
			p1queue = p1q, p2queue = p2q, maxLvl = maxq,
			p1target = p1t, p2target = p2t,
		}
	end

	----------------------------------------------------------------- core check
	local function checkV2()
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d then return end
		local petsData = d.PetsData
		if not petsData then return end
		local eq  = petsData.EquippedPets or {}
		local inv = petsData.PetInventory and petsData.PetInventory.Data or {}

		local targetTypes = CFG.levelingV2PetTypes or {}
		local p1Team = CFG.levelingV2P1Team or {}
		local p2Team = CFG.levelingV2P2Team or {}
		local p1Target = CFG.levelingV2P1Target or 40
		local p2Target = CFG.levelingV2P2Target or 500
		local p1Max = CFG.levelingV2P1Max or 3
		local p2Max = CFG.levelingV2P2Max or 1

		-- Tentukan phase aktif: ada target pet < p1Target -> Phase 1, else Phase 2.
		local phase1Work = 0
		for _, v in pairs(inv) do
			if matchesType(targetTypes, v.PetType, v.PetData) and ((v.PetData or {}).Level or 0) < p1Target and not (v.PetData or {}).IsFavorite then phase1Work = phase1Work + 1 end
		end
		local phase = (phase1Work > 0) and 1 or 2
		ctx.state.levelingV2Phase = "Phase " .. phase
		local team       = (phase == 1) and p1Team or p2Team
		local otherTeam  = (phase == 1) and p2Team or p1Team
		local phaseTarget = (phase == 1) and p1Target or p2Target
		local phaseMin    = (phase == 1) and 0 or p1Target  -- batas bawah level utk phase ini
		local maxPets     = (phase == 1) and p1Max or p2Max

		-- Deteksi TRANSISI phase -> picu pembersihan garden TOTAL.
		if ctx.state.levelingV2LastPhase ~= nil and ctx.state.levelingV2LastPhase ~= phase then
			ctx.state.levelingV2Clearing = true
		end
		ctx.state.levelingV2LastPhase = phase

		local localEq = {}
		for _, uuid in ipairs(eq) do localEq[uuid] = true end

		-- A. First run / TRANSISI phase: bersihin garden TOTAL & pastikan BENAR-BENAR kosong
		-- dulu (verified) sebelum pasang team phase baru. Cegah sisa pet phase 1 nyangkut.
		if ctx.state.levelingV2FirstRun or ctx.state.levelingV2Clearing then
			if #eq > 0 then
				ctx.state.levelingV2Status = ("Phase %d: bersihin garden dulu (%d pet)..."):format(phase, #eq)
				for _, uuid in ipairs(eq) do
					pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
					task.wait(0.2)
				end
				return -- cek ulang cycle berikutnya sampai garden BENAR-BENAR kosong
			end
			-- garden udah kosong -> pembersihan selesai, lanjut pasang team
			ctx.state.levelingV2FirstRun = false
			ctx.state.levelingV2Clearing = false
		end

		-- C. Pasang team phase ini + PASTIKAN LENGKAP dulu sebelum proses target pet.
		-- Cek dari data equipped asli; kalau belum lengkap, equip lalu RETURN (recheck).
		local teamComplete = true
		for uuid in pairs(team) do
			if not localEq[uuid] then
				teamComplete = false
				local pos = getPos(uuid)
				if pos then
					pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
					task.wait(0.25)
				end
			end
		end
		if not teamComplete then
			ctx.state.levelingV2Status = ("Phase %d: nunggu team lengkap..."):format(phase)
			return -- tunggu team komplit dulu, baru proses target pet
		end

		-- D. Target pet yang lulus phase (level >= phaseTarget) -> lepas
		local active = {}
		for uuid in pairs(localEq) do
			if not team[uuid] and not otherTeam[uuid] then
				local v = inv[uuid]
				if v and matchesType(targetTypes, v.PetType, v.PetData) then
					local pd  = v.PetData or {}
					local lvl = pd.Level or 0
					if lvl >= phaseTarget then
						-- Webhook HANYA pas phase 2 (pet mencapai target final). Phase 1 = intermediate, skip.
						if phase == 2 then
							local petType  = v.PetType or "Unknown"
							local mutation = pd.MutationType or "Normal"
							local finalAge = pd.Level or phaseTarget
							local duration = 0
							ctx.state.levelingV2StartTime = ctx.state.levelingV2StartTime or {}
							if ctx.state.levelingV2StartTime[uuid] then
								duration = os.time() - ctx.state.levelingV2StartTime[uuid]
								ctx.state.levelingV2StartTime[uuid] = nil
							end
							-- Sisa antrean phase 2 (target type, level dalam [p1Target, p2Target), belum equipped, bukan favorite)
							local remainsQueue = 0
							for ou, ov in pairs(inv) do
								if ou ~= uuid and not localEq[ou] and matchesType(targetTypes, ov.PetType, ov.PetData) then
									local ol = (ov.PetData or {}).Level or 0
									if ol >= p1Target and ol < p2Target and not (ov.PetData or {}).IsFavorite then
										remainsQueue = remainsQueue + 1
									end
								end
							end
							task.spawn(function()
								local W = ctx.webhookLeveling
								if W and W.sendFinished then
									pcall(function() W.sendFinished(ctx, petType, mutation, finalAge, duration, remainsQueue) end)
								end
							end)
						end
						pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
						localEq[uuid] = nil
						task.wait(0.2)
					else
						table.insert(active, uuid)
						-- Catat waktu mulai leveling phase 2 (buat Duration di webhook)
						if phase == 2 then
							ctx.state.levelingV2StartTime = ctx.state.levelingV2StartTime or {}
							if not ctx.state.levelingV2StartTime[uuid] then
								ctx.state.levelingV2StartTime[uuid] = os.time()
							end
						end
					end
				end
			end
		end

		-- E. Tambah target pet baru buat phase ini (level dalam [phaseMin, phaseTarget))
		local needed = maxPets - #active
		if needed > 0 then
			local pool = {}
			for uuid, v in pairs(inv) do
				local lvl = (v.PetData or {}).Level or 0
				if not localEq[uuid] and matchesType(targetTypes, v.PetType, v.PetData) and lvl >= phaseMin and lvl < phaseTarget and not (v.PetData or {}).IsFavorite then
					table.insert(pool, { uuid = uuid, level = lvl })
				end
			end
			table.sort(pool, function(a, b) return a.level < b.level end) -- level terendah dulu
			for i = 1, math.min(needed, #pool) do
				local pos = getPos(pool[i].uuid)
				if pos then
					pcall(function() PetsService:FireServer("EquipPet", pool[i].uuid, CFrame.new(pos)) end)
					localEq[pool[i].uuid] = true
					table.insert(active, pool[i].uuid)
					-- Catat waktu mulai leveling phase 2 (buat Duration di webhook)
					if phase == 2 then
						ctx.state.levelingV2StartTime = ctx.state.levelingV2StartTime or {}
						ctx.state.levelingV2StartTime[pool[i].uuid] = os.time()
					end
					task.wait(0.25)
				end
			end
		end

		ctx.state.levelingV2Status = ("Phase %d: %d/%d aktif"):format(phase, #active, maxPets)
	end

	----------------------------------------------------------------- loop
	local function loopV2()
		ctx.state.levelingV2Id = (ctx.state.levelingV2Id or 0) + 1
		local myId = ctx.state.levelingV2Id
		ctx.elevate()
		ctx.state.levelingV2FirstRun = true
		ctx.state.levelingV2LastPhase = nil -- reset biar ga false-trigger transisi di cycle pertama
		while CFG.levelingV2Enabled and ctx.alive() and ctx.state.levelingV2Id == myId do
			pcall(checkV2)
			task.wait(3)
		end
		ctx.state.levelingV2Status = "Idle"
	end

	function ctx.startLevelingV2()
		if ctx.cancelClearGarden then ctx.cancelClearGarden() end -- batalkan clear tertunda
		task.spawn(loopV2)
	end
	function ctx.stopLevelingV2()
		ctx.state.levelingV2Id = (ctx.state.levelingV2Id or 0) + 1 -- matikan loop
		if ctx.clearGarden then ctx.clearGarden("Leveling V2") end
	end
end
]=],
	["modules/leveling/webhook.lua"] = [=[
--[[ webhook/leveling.lua — Discord webhook untuk leveling.
     Di-load via HttpGet loader; sender diambil dari ctx.sendWebhook (bukan require script). ]]
local HttpService = game:GetService("HttpService")

local levelingWebhook = {}

local function formatDuration(sec)
	if not sec or sec <= 0 then return "Unknown" end
	local h = math.floor(sec / 3600)
	local m = math.floor((sec % 3600) / 60)
	local s = sec % 60
	local parts = {}
	if h > 0 then table.insert(parts, h .. "h") end
	if m > 0 then table.insert(parts, m .. "m") end
	if s > 0 or #parts == 0 then table.insert(parts, s .. "s") end
	return table.concat(parts, " ")
end

-- Webhook saat leveling di-enable
function levelingWebhook.sendEnabled(ctx, queueList, teamList, targetAge)
	local CFG = ctx.CFG
	if not CFG.webhookUrl or CFG.webhookUrl == "" then return end
	queueList = queueList or {}
	teamList = teamList or {}

	local petLines = {}
	for _, p in ipairs(queueList) do
		table.insert(petLines, string.format("> - `%s` (Level %d)", p.type, p.level))
	end
	local petsText = #petLines > 0 and table.concat(petLines, "\n") or "> - Tidak ada pet di antrean"

	local teamLines = {}
	for _, pName in ipairs(teamList) do
		table.insert(teamLines, "`" .. pName .. "`")
	end
	local teamText = #teamLines > 0 and table.concat(teamLines, ", ") or "None"

	local payload = {
		embeds = {
			{
				title = "Growth • Leveling Enabled",
				color = 3066993, -- Green
				fields = {
					{
						name = "Profile :",
						value = string.format("> Username : ||%s||", ctx.LP.Name),
						inline = false
					},
					{
						name = "Leveling Configuration",
						value = string.format(
							"> EXP Pet Team: %s\n" ..
							"> Target Age: `%s`\n" ..
							"> Queue Count: `%d`",
							teamText,
							tostring(targetAge or CFG.levelingTargetLevel or 500),
							#queueList
						),
						inline = false
					},
					{
						name = "Leveling Queue Status",
						value = petsText,
						inline = false
					}
				},
				footer = {
					text = os.date("%B %d | %I:%M %p"),
					icon_url = "https://raw.githubusercontent.com/milmscr/opoki/main/tegalan/Logo/logo_icon.png"
				}
			}
		}
	}
	if ctx.sendWebhook then ctx.sendWebhook(CFG.webhookUrl, payload, ctx) end
end

-- Webhook saat pet selesai leveling
function levelingWebhook.sendFinished(ctx, petType, mutation, age, durationSec, remainsQueue)
	local CFG = ctx.CFG
	if not CFG.webhookUrl or CFG.webhookUrl == "" then return end

	local mutDisplay = ctx.reg.mutDisplay and ctx.reg.mutDisplay(mutation) or mutation
	local durationStr = formatDuration(durationSec)

	local payload = {
		embeds = {
			{
				title = "Growth • Leveling",
				color = 3066993, -- Green
				fields = {
					{
						name = "Profile :",
						value = string.format("> Username : ||%s||", ctx.LP.Name),
						inline = false
					},
					{
						name = "Final Age Reached",
						value = string.format(
							"> Pet Type: `%s`\n" ..
							"> Mutation: `%s`\n" ..
							"> Age: `%s`\n" ..
							"> Duration: `%s`\n" ..
							"> Remains Queue: `%s`",
							petType,
							mutDisplay,
							tostring(age),
							durationStr,
							tostring(remainsQueue)
						),
						inline = false
					}
				},
				footer = {
					text = os.date("%B %d | %I:%M %p"),
					icon_url = "https://raw.githubusercontent.com/milmscr/opoki/main/tegalan/Logo/logo_icon.png"
				}
			}
		}
	}
	if ctx.sendWebhook then ctx.sendWebhook(CFG.webhookUrl, payload, ctx) end
end

return levelingWebhook
]=],
	["modules/misc/automation_reconnect.lua"] = [=[
--[[ automation_reconnect.lua — Auto Reconnect/Rejoin tiap interval (Misc).
     Tiap X menit: queue loader (biar hub auto jalan lagi abis rejoin) lalu
     teleport ke server yg SAMA (reconnect), fallback server baru kalau gagal.
     Config: CFG.reconnectEnabled (toggle), CFG.reconnectInterval (menit).
     Fungsi: ctx.startReconnect. Auto-resume di app.lua biar loop lanjut tiap masuk. ]]
return function(ctx)
	local LP  = ctx.LP
	local CFG = ctx.CFG
	local TeleportService = game:GetService("TeleportService")
	local function setStatus(s) ctx.setStatus(s) end

	local branch = (getgenv and getgenv().GAG_BRANCH) or _G.GAG_BRANCH or "main"

	-- queue loader hub biar auto jalan lagi setelah rejoin (branch dijaga).
	local function queueLoader()
		local q = (syn and syn.queue_on_teleport) or queue_on_teleport
			or (fluxus and fluxus.queue_on_teleport) or (getgenv and getgenv().queue_on_teleport)
		if q then
			local cmd = ('if getgenv then getgenv().GAG_BRANCH=%q end loadstring(game:HttpGet("https://raw.githubusercontent.com/milmscr/opoki/%s/tegalan/init.lua"))()'):format(branch, branch)
			pcall(function() q(cmd) end)
		end
	end

	-- Cache reference Teleport SEKARANG (bukan pas dipanggil) biar bypass hook
	-- __namecall yg mungkin dipasang game buat block teleport pihak-3.
	local TeleportFn = TeleportService.Teleport

	local function doReconnect()
		queueLoader()
		task.wait(0.4)
		-- Teleport(placeId, player) via cached-ref. Pas di private server, Roblox
		-- rejoin ke private server juga (bukan publik) -> stay private. Kalau di
		-- server publik, ke publik. TeleportToPlaceInstance JANGAN dipakai (773 +
		-- diblok buat private).
		local ok = pcall(function() TeleportFn(TeleportService, game.PlaceId, LP) end)
		if not ok then
			pcall(function() TeleportService:Teleport(game.PlaceId, LP) end)
		end
	end

	local function reconnectLoop(myId)
		while CFG.reconnectEnabled and ctx.alive() and ctx.state.reconnectId == myId do
			local mins = tonumber(CFG.reconnectInterval) or 5
			if mins <= 0 then mins = 5 end
			local total = mins * 60
			local t0 = os.clock()
			while os.clock() - t0 < total do
				if not CFG.reconnectEnabled or ctx.state.reconnectId ~= myId or not ctx.alive() then
					ctx.state.reconnectRemaining = nil; return
				end
				local rem = math.ceil(total - (os.clock() - t0))
				ctx.state.reconnectRemaining = rem
				setStatus(("Reconnect: %d dtk lagi"):format(rem))
				task.wait(1)
			end
			if CFG.reconnectEnabled and ctx.state.reconnectId == myId then
				setStatus("Reconnect: rejoin...")
				doReconnect()
				return -- instance ini bakal ilang setelah teleport
			end
		end
	end

	function ctx.startReconnect()
		ctx.state.reconnectId = (ctx.state.reconnectId or 0) + 1
		local myId = ctx.state.reconnectId
		task.spawn(function() reconnectLoop(myId) end)
	end

	ctx.reconnect = doReconnect
end
]=],
	["modules/misc/esp_egg.lua"] = [=[
--[[ esp_egg.lua — NEBULA-style Egg ESP (milik Sam, dipotret 1:1) + mode screen.
     MODE "target": BillboardGui polos nempel di egg (NEBULA asli):
       - belum siap : <kuning>nama egg</> \n <oranye>m:ss</> \n <abu kecil>BW: xkg</>
       - siap       : <kuning>nama egg</> \n <putih>pet (est kg)</> \n <warna>[Size class]</>
     MODE "screen": list TABEL KOLOM tanpa background di sisi KANAN TENGAH —
         font 16 bold + outline hitam, nama pet berwarna. Ready eggs paling atas.
     Size class: >=7 Titanic (merah) / >=6 Semi Titanic (oranye) / >=3 Huge (kuning)
     / sisanya Small (hijau). Isi egg dari upvalue handler PetEggService +
     scan BaseWeight di DataService:GetData. GothamBold 17, RichText.
     Toggle: CFG.espEggEnabled — TERPISAH dari ESP pet.
     Mode: CFG.espEggMode ("target"/"screen"). ]]
return function(ctx)
	local RS = game:GetService("ReplicatedStorage")
	local CS = game:GetService("CollectionService")
	local LP = ctx.LP
	local DataService = ctx.deps.DataService

	-- Game nampilin berat = BaseWeight * 1.10 (sama kayak NEBULA).
	local WEIGHT_MULT = 1.1

	-- Nama pet di list screen dikasih warna tetap per nama (hash) — cerah,
	-- rapih, konsisten dengan warna di ESP pet.
	local NAME_COLORS = {
		"#33C1FF", "#FF5EC8", "#4DF08A", "#B06CFF", "#2CE8CC", "#FF7A3C", "#C6FF33", "#FFD21E",
	}
	local function eggNameColor(s)
		local h = 0
		for i = 1, #s do h = (h * 31 + string.byte(s, i)) % 100003 end
		return NAME_COLORS[(h % #NAME_COLORS) + 1]
	end

	-- eggPets[uuid] = nama pet yang bakal menetas (upvalue handler hatch).
	local eggPets = {}
	-- Cache BaseWeight per uuid (scan data game — NEBULA buildBW).
	local bwCache = {}
	-- Sisa hatch per uuid dari data egg (fallback countdown kalau attribute
	-- TimeToHatch-nya gak direplikasi ke client / absen).
	local eggTimer = {}
	local lastMode

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
						local dd = v.Data
						if type(dd) == "table" then
							-- Pet = punya BaseWeight. Egg yang masih CD cuma
							-- punya TimeToHatch di data (pet belum di-roll).
							if dd.BaseWeight then bwCache[tostring(k)] = dd.BaseWeight end
							if dd.TimeToHatch then eggTimer[tostring(k)] = tonumber(dd.TimeToHatch) end
						end
						scan(v)
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

	-- Sisa detik hatch: attribute live > data egg. Attr <=0 = kondisi live
	-- ready — GAK ditimpa data, yang bisa basi (sisa hatch lama).
	local function resolveTimer(uuid, tlAttr)
		if tlAttr then
			if tlAttr > 0 then return tlAttr end
			return 0
		end
		if not bwCache[uuid] then buildBW() end
		local dt = eggTimer[uuid]
		return (dt and dt > 0) and dt or 0
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

	local function clearBillboards()
		for _, egg in ipairs(CS:GetTagged("PetEggServer")) do
			pcall(function()
				local g = egg:FindFirstChild("EggESP_UI")
				if g then g:Destroy() end
			end)
		end
	end

	-- ===== Screen mode: PLAIN TEXT list (tanpa background), lewat shared
	-- renderer di esp_label (ctx.espScreenData / ctx.espScreenPaint).
	-- Fallback: kalau renderer shared belum ada (label module gak ke-load),
	-- bikin gui list sendiri yang gayanya sama.
	local listSg, listFrame
	local rowPool = {}

	-- Kolom tanda tangan yang sama dengan layanan yang dibagikan di esp_label agar daftar cadangan (fallback) tampil dengan tampilan yang sama.
	local function fbNewCol(parent, x, w, size)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Position = UDim2.fromOffset(x or 0, 0)
		l.Size = UDim2.fromOffset(w, 22)
		l.Font = Enum.Font.GothamBold
		l.RichText = true
		l.TextSize = size or 13
		l.TextTruncate = Enum.TextTruncate.AtEnd
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.TextYAlignment = Enum.TextYAlignment.Center
		l.TextColor3 = Color3.new(1, 1, 1)
		local st = Instance.new("UIStroke")
		st.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		st.Color = Color3.new(0, 0, 0)
		st.Thickness = 1.5
		st.Transparency = 0.1
		st.Parent = l
		l.Parent = parent
		return l
	end

	local function screenClaim(rows)
		if ctx.espScreenPaint then
			ctx.espScreenData.egg = (rows and #rows > 0) and rows or nil
			ctx.espScreenPaint()
			return
		end
		-- Fallback (label module gak ke-load): renderer tabel kolom sendiri.
		local has = rows and #rows > 0
		if not has then
			if listSg then pcall(function() listSg:Destroy() end) end
			listSg, listFrame, rowPool = nil, nil, {}
			return
		end
		if not (listSg and listSg.Parent) then
			listSg = Instance.new("ScreenGui")
			listSg.Name = "CespEspListEggOnly"
			listSg.ResetOnSpawn = false
			listSg.DisplayOrder = 50
			listSg.IgnoreGuiInset = true
			listSg.Parent = (gethui and gethui()) or game:GetService("CoreGui")

			listFrame = Instance.new("Frame")
			-- Sisi KANAN TENGAH (sama dengan renderer shared di esp_label).
			listFrame.AnchorPoint = Vector2.new(1, 0.5)
			listFrame.Position = UDim2.new(1, -14, 0.5, 0)
			listFrame.Size = UDim2.new(0, 480, 0, 0)
			listFrame.AutomaticSize = Enum.AutomaticSize.Y
			listFrame.BackgroundTransparency = 1
			local layout = Instance.new("UIListLayout")
			layout.FillDirection = Enum.FillDirection.Vertical
			layout.SortOrder = Enum.SortOrder.LayoutOrder
			layout.Parent = listFrame
			listFrame.Parent = listSg
			rowPool = {}
		end
		local W_N, W_K, W_L, GP = 232, 82, 58, 6
		for i, s in ipairs(rows) do
			local r = rowPool[i]
			if r and not r.frame.Parent then
				pcall(function() r.frame:Destroy() end)
				r = nil
			end
			if not r then
				local frame = Instance.new("Frame")
				frame.BackgroundTransparency = 1
				frame.Size = UDim2.new(1, 0, 0, 22)
				frame.LayoutOrder = i
				r = {
					frame = frame,
					name = fbNewCol(frame, 0, W_N, 16),
					kg = fbNewCol(frame, W_N + GP, W_K, 13),
					lv = fbNewCol(frame, W_N + GP + W_K + GP, W_L, 13),
					tail = fbNewCol(frame, W_N + GP + W_K + GP + W_L + GP, 480 - (W_N + GP + W_K + GP + W_L + GP), 13),
				}
				r.kg.TextXAlignment = Enum.TextXAlignment.Right
				r.lv.TextXAlignment = Enum.TextXAlignment.Right
				frame.Parent = listFrame
				rowPool[i] = r
			end
			r.frame.LayoutOrder = i
			r.name.Text, r.kg.Text, r.lv.Text, r.tail.Text = s.name or "", s.kg or "", s.lv or "", s.tail or ""
			r.name.Visible, r.kg.Visible, r.lv.Visible, r.tail.Visible = s.name ~= nil, s.kg ~= nil, s.lv ~= nil, s.tail ~= nil
		end
		for i = #rows + 1, #rowPool do
			if rowPool[i] then pcall(function() rowPool[i].frame:Destroy() end) end
			rowPool[i] = nil
		end
	end

	local function clearAll()
		clearBillboards()
		screenClaim(nil)
	end

	local lastMeta = 0
	local function update(mode)
		local now = os.clock()
		-- Refresh metadata egg/BW tiap 3s (murah, yang tiap-tick cuma teks).
		if now - lastMeta >= 3 then
			lastMeta = now
			updateEggPets()
			buildBW()
		end

		-- Kumpulin data dulu; render sesuai mode.
		local entries = {}
		for _, egg in ipairs(CS:GetTagged("PetEggServer")) do
			if egg:GetAttribute("OWNER") == LP.Name then
				local uuid = tostring(egg:GetAttribute("OBJECT_UUID"))
				-- Sisa waktu: attribute TimeToHatch live dulu; kalo absen,
				-- fallback ke data egg (SavedObjects.Data.TimeToHatch via
				-- GetData — attribute model kadang gak direplikasi).
				local tl = resolveTimer(uuid, tonumber(egg:GetAttribute("TimeToHatch")))
				-- Countdown jalan selama tl > 0. READY dipercaya cuma kalo
				-- timer habis/absen — game ngeset READY=true duluan sebelum
				-- egg beneran siap.
				local isReady = not (tl and tl > 0)
				if egg:GetAttribute("READY") ~= nil or tl then
					local bw = getBW(uuid)
					-- Egg yang masih CD gak punya BaseWeight di data (pet
					-- belum di-roll) — tetep render name + countdown.
					-- BaseWeight cuma ada di egg ready.
					if bw or not isReady then
						entries[#entries + 1] = {
							egg = egg,
							eggName = egg:GetAttribute("EggName") or egg.Name,
							uuid = uuid,
							bw = bw,
							ready = isReady,
							timeLeft = tl or 0,
						}
					end
				end
			end
		end
		-- Ready dulu, sisanya sisa-waktu ascending.
		table.sort(entries, function(a, b)
			if a.ready ~= b.ready then return a.ready == true end
			return a.timeLeft < b.timeLeft
		end)

		-- Slot spec screen (sama bentuknya dengan pet di esp_label):
		-- [nama][kg][lv kosong][tail] → kolom tetap lurus antar baris.
		local rows = {}
		for i, e in ipairs(entries) do
			if i > 40 then break end
			local petName = eggPets[e.uuid] or "Pet"
			if not e.ready then
				rows[#rows + 1] = {
					name = ('<font color="#FFD400">%s</font>'):format(e.eggName),
					kg = e.bw and ('<font color="#33C1FF">BW: %skg</font>'):format(tostring(e.bw)) or nil,
					tail = ('<font color="#FF5E00">%s</font>'):format(formatTime(e.timeLeft)),
				}
			else
				local est = round(e.bw * WEIGHT_MULT, 2)
				local size, color = getSizeInfo(est)
				rows[#rows + 1] = {
					name = ('<font color="#FFD400">%s</font> <b><font color="%s">%s</font></b>')
						:format(e.eggName, eggNameColor(petName), petName),
					kg = ('<font color="#FFAA00">(%skg)</font>'):format(tostring(est)),
					tail = ('<font color="%s">[%s]</font>'):format(color, size),
				}
			end
		end

		if mode == "screen" then
			screenClaim(rows)
		else
			screenClaim(nil)
			for _, e in ipairs(entries) do
				local petName = eggPets[e.uuid] or "Pet"
				local text
				if not e.ready then
					-- BW line cuma kalo datanya udah ada (egg ready biasanya);
					-- egg CD udah cukup nama + countdown.
					text = e.bw
						and string.format(
							'<font color="#FFD400">%s</font>\n<font color="#FF5E00">%s</font>\n<font size="12" color="#BBBBBB">BW: %skg</font>',
							e.eggName,
							formatTime(e.timeLeft),
							tostring(e.bw)
						)
						or string.format(
							'<font color="#FFD400">%s</font>\n<font color="#FF5E00">%s</font>',
							e.eggName,
							formatTime(e.timeLeft)
						)
				else
					local est = round(e.bw * WEIGHT_MULT, 2)
					local size, color = getSizeInfo(est)
					text = string.format(
						'<font color="#FFD400">%s</font>\n<font color="#FFFFFF">%s (%skg)</font>\n<font color="%s">[%s]</font>',
						e.eggName,
						petName,
						tostring(est),
						color,
						size
					)
				end
				makeESP(e.egg, text)
			end
		end
	end

	local loopId = 0
	function ctx.startEspEgg()
		loopId = loopId + 1
		local my = loopId
		-- Generation guard: loop dari eksekusi loader sebelumnya mati saat gen naik.
		local gen = (getgenv().GAG_ESP_GEN or 0)
		task.spawn(function()
			updateEggPets()
			buildBW()
			while ctx.alive() and ctx.CFG.espEggEnabled and loopId == my and (getgenv().GAG_ESP_GEN or 0) == gen do
				local mode = (ctx.CFG.espEggMode == "screen") and "screen" or "target"
				if mode ~= lastMode then
					lastMode = mode
					clearAll()
				end
				pcall(update, mode)
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
]=],
	["modules/misc/esp_inventory.lua"] = [=[
--[[ esp_inventory.lua — ESP Base Weight di INVENTORY (Pet Items).
     Nempel label kecil "Base X.XX KG" di tiap slot pet di backpack GUI,
     jadi pas buka inventory langsung keliatan BaseWeight tiap pet.
     Mapping: slot.ToolName.Text == Tool.Name -> Tool.PET_UUID ->
              PetData.BaseWeight (dari DataService).
     Toggle: CFG.espInvEnabled. ]]
return function(ctx)
	local RS = game:GetService("ReplicatedStorage")
	local LP = ctx.LP
	local DataService = ctx.deps.DataService

	local GRID_PATH   = { "BackpackGui", "Backpack", "Inventory", "ScrollingFrame", "UIGridFrame" }
	local HOTBAR_PATH = { "BackpackGui", "Backpack", "Hotbar" }
	local LBL_NAME    = "AH_BaseW" -- label yg kita tempel di slot

	local function byPath(path)
		local n = LP:FindFirstChild("PlayerGui")
		for _, seg in ipairs(path) do
			if not n then return nil end
			n = n:FindFirstChild(seg)
		end
		return n
	end
	-- container slot pet: grid inventory + hotbar (bar bawah, termasuk pet yg dipegang).
	local function containers()
		local out = {}
		local g = byPath(GRID_PATH);   if g then out[#out + 1] = g end
		local h = byPath(HOTBAR_PATH); if h then out[#out + 1] = h end
		return out
	end

	-- map Tool.Name -> {base, level} (cuma pet). Dibangun tiap refresh (murah).
	local function buildWeightMap()
		local ok, d = pcall(function() return DataService:GetData() end)
		local inv = ok and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}
		local byUuid = {}
		for uuid, v in pairs(inv) do
			local pd = v.PetData or {}
			if pd.BaseWeight then byUuid[uuid] = { base = pd.BaseWeight, level = pd.Level or 0 } end
		end
		local byName = {}
		local function scan(where)
			if not where then return end
			for _, t in ipairs(where:GetChildren()) do
				if t:IsA("Tool") and t:GetAttribute("ItemType") == "Pet" then
					local uuid = t:GetAttribute("PET_UUID")
					local e = uuid and byUuid[uuid]
					if e and byName[t.Name] == nil then byName[t.Name] = e end
				end
			end
		end
		scan(LP.Character)
		scan(LP:FindFirstChildOfClass("Backpack"))
		return byName
	end

	-- Game: Weight = BaseWeight * (1 + 0.1*Level). MAX_LEVEL = umur 500.
	-- Berat "dasar" (level dasar) yg biasa dilihat = BaseWeight * 1.1, di-floor
	-- 1 desimal — persis game (5.5 base -> 6.0, 5.6 -> 6.1). Max = base*(1+0.1*500).
	local WEIGHT_MULT = 1.1
	local MAX_LEVEL   = 500
	local function floor1(n) return math.floor(n * 10) / 10 end
	local function baseKG(bw) return floor1(bw * WEIGHT_MULT) end
	local function maxKG(bw)  return floor1(bw * (1 + 0.1 * MAX_LEVEL)) end

	-- teks label sesuai mode CFG.espInvMode ("base" / "age" / "max").
	local function labelText(e)
		local base = baseKG(e.base)
		local mode = ctx.CFG.espInvMode
		if mode == "max" then
			return ("%.1f \u{2192} %.1f KG"):format(base, maxKG(e.base))
		elseif mode == "base" then
			return ("%.1f KG"):format(base)
		end
		return ("%.1f KG A%d"):format(base, e.level or 0)
	end

	-- tempel/refresh label di slot; hapus dari slot non-pet.
	local function setLabel(slot, e)
		local lbl = slot:FindFirstChild(LBL_NAME)
		if not e then
			if lbl then lbl:Destroy() end
			return
		end
		if not lbl then
			lbl = Instance.new("TextLabel")
			lbl.Name = LBL_NAME
			lbl.AnchorPoint = Vector2.new(0.5, 1)
			lbl.Position = UDim2.new(0.5, 0, 1, 0)
			lbl.Size = UDim2.new(1, 0, 0, 15)
			lbl.BackgroundColor3 = Color3.fromRGB(24, 10, 32)
			lbl.BackgroundTransparency = 0.15
			lbl.Font = Enum.Font.MontserratBold
			lbl.TextSize = 11
			lbl.TextScaled = true -- auto-fit biar muat di slot sempit
			lbl.TextColor3 = Color3.fromRGB(255, 215, 240) -- soft pastel rose
			lbl.TextStrokeTransparency = 0.4
			lbl.TextStrokeColor3 = Color3.fromRGB(60, 10, 40)
			lbl.ZIndex = 20
			lbl.RichText = false
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 4)
			corner.Parent = lbl
			local str = Instance.new("UIStroke")
			str.Color = Color3.fromRGB(255, 95, 175)
			str.Transparency = 0.4
			str.Thickness = 1
			str.Parent = lbl
			local con = Instance.new("UITextSizeConstraint")
			con.MaxTextSize = 12
			con.Parent = lbl
			lbl.Parent = slot
		end
		lbl.Text = labelText(e)
	end

	local function clearAll()
		for _, c in ipairs(containers()) do
			for _, slot in ipairs(c:GetChildren()) do
				if slot:IsA("GuiButton") then
					local lbl = slot:FindFirstChild(LBL_NAME)
					if lbl then lbl:Destroy() end
				end
			end
		end
	end

	local function update()
		local cs = containers()
		if #cs == 0 then return end
		local byName = buildWeightMap()
		for _, c in ipairs(cs) do
			for _, slot in ipairs(c:GetChildren()) do
				if slot:IsA("GuiButton") then
					local tn = slot:FindFirstChild("ToolName")
					local name = tn and tn:IsA("TextLabel") and tn.Text or nil
					setLabel(slot, name and byName[name] or nil)
				end
			end
		end
	end

	local loopId = 0
	function ctx.startEspInv()
		loopId = loopId + 1
		local my = loopId
		task.spawn(function()
			while ctx.alive() and ctx.CFG.espInvEnabled and loopId == my do
				pcall(update)
				task.wait(0.5)
			end
			pcall(clearAll)
		end)
	end

	function ctx.stopEspInv()
		loopId = loopId + 1
		pcall(clearAll)
	end
end
]=],
	["modules/misc/esp_label.lua"] = [=[
--[[ esp_label.lua — ESP PET dengan 2 mode:
     target : label BillboardGui nempel di atas tiap pet di dunia (klasik).
     screen : PLAIN TEXT list di layar (tanpa background/frame) — per baris:
              nama + berat + level + cd skill ("15s | 10m" / "READY").
     Shared screen renderer: modul ini (load pertama) yang owns gui list
     layar; esp_egg (load kedua) nimpa baris egg-nya lewat ctx.espScreenData.
      Keduanya ON → satu list (font 16) + pembatas di antara egg dan pet.
      Satu ON → list sama, tanpa pembatas. Nama pet warna tetap per nama.
     Data pet: nama tipe + berat (BaseWeight*1.1) + level + cd skill.
     Cd pet dapet dari server push PetCooldownsUpdated + seed GetPetCooldown
     (sisa detik di-interpolasi lokal biar countdown halus antara push).
     ESP EGG TERPISAH di modules/misc/esp_egg.lua.
     Toggle: CFG.espEnabled, mode: CFG.espMode ("target"/"screen"). ]]
return function(ctx)
	local LP = ctx.LP
	local DataService = ctx.deps.DataService

	-- Game nampilin berat = BaseWeight * 1.1 (bukan raw BaseWeight).
	local WEIGHT_MULT = 1.1

	local bbFolder
	local billboards = {} -- key -> { gui, lbl }
	local lastMode

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

		-- Background card (dark, sesuai tema menu)
		local bg = Instance.new("Frame")
		bg.Size = UDim2.new(1, 0, 1, 0)
		bg.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
		bg.BackgroundTransparency = 0.22
		bg.BorderSizePixel = 0
		bg.Parent = bb
		Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 10)
		local bgStroke = Instance.new("UIStroke", bg)
		bgStroke.Color = Color3.fromRGB(235, 235, 235)
		bgStroke.Thickness = 1.2
		bgStroke.Transparency = 0.4
		bgStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		local lbl = Instance.new("TextLabel")
		lbl.BackgroundTransparency = 1
		lbl.Size = UDim2.new(1, -8, 1, 0)
		lbl.Position = UDim2.fromOffset(4, 0)
		lbl.Font = Enum.Font.FredokaOne
		lbl.TextSize = 15
		lbl.RichText = true
		lbl.TextColor3 = Color3.new(1, 1, 1)
		lbl.TextStrokeTransparency = 0.5
		lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
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

	local function clearBillboards()
		for _, rec in pairs(billboards) do pcall(function() rec.gui:Destroy() end) end
		billboards = {}
		if bbFolder then pcall(function() bbFolder:Destroy() end); bbFolder = nil end
	end

	-- ===== Shared screen list (TABEL KOLOM, tanpa background) =====
	-- ctx.espScreenData.pet / .egg masing-masing modul isi sendiri — bentuknya
	-- SLOT SPEC per baris: { name=richtext, kg=richtext, lv=richtext?, tail=richtext? }
	-- paint() render jadi tabel 4 kolom rata kanan-tengah layar:
	--   [nama (kiri)] [kg (kanan)] [lv (kanan)] [tail (kiri)]
	-- Kolom bikin semua baris SIMETRIS walau panjang nama beda-beda. Frame
	-- per baris di-pool biar gak buang2 instance tiap 0.5s.
	ctx.espScreenData = ctx.espScreenData or { pet = nil, egg = nil }
	local screenData = ctx.espScreenData
	local listSg, listFrame
	local rowPool = {} -- i -> { frame, name, kg, lv, tail, sep }

	-- Lebar kolom (total blok 480px): 232 nama, 82 kg, 58 lv, 90 tail + gap 6px.
	local C_NAME_W, C_KG_W, C_LV_W, C_GAP = 232, 82, 58, 6
	local C_KG_X = C_NAME_W + C_GAP
	local C_LV_X = C_KG_X + C_KG_W + C_GAP
	local C_TAIL_X = C_LV_X + C_LV_W + C_GAP

	local function newCol(parent, x, w, size)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Position = UDim2.fromOffset(x or 0, 0)
		l.Size = UDim2.fromOffset(w, 22)
		l.Font = Enum.Font.GothamBold
		l.RichText = true
		l.TextSize = size or 13
		l.TextTruncate = Enum.TextTruncate.AtEnd
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.TextYAlignment = Enum.TextYAlignment.Center
		l.TextColor3 = Color3.new(1, 1, 1)
		local st = Instance.new("UIStroke")
		st.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		st.Color = Color3.new(0, 0, 0)
		st.Thickness = 1.5
		st.Transparency = 0.1
		st.Parent = l
		l.Parent = parent
		return l
	end

	local function getSlot(i)
		local r = rowPool[i]
		if r and not r.frame.Parent then
			pcall(function() r.frame:Destroy() end)
			r = nil
		end
		if not r then
			local frame = Instance.new("Frame")
			frame.BackgroundTransparency = 1
			frame.Size = UDim2.new(1, 0, 0, 22)
			frame.LayoutOrder = i
			r = {
				frame = frame,
				name = newCol(frame, 0, C_NAME_W, 16),
				kg = newCol(frame, C_KG_X, C_KG_W, 13),
				lv = newCol(frame, C_LV_X, C_LV_W, 13),
				tail = newCol(frame, C_TAIL_X, 480 - C_TAIL_X, 13),
				sep = newCol(frame, 0, 480, 12),
			}
			r.kg.TextXAlignment = Enum.TextXAlignment.Right
			r.lv.TextXAlignment = Enum.TextXAlignment.Right
			frame.Parent = listFrame
			rowPool[i] = r
		end
		return r
	end

	local function paint()
		local hasE = screenData.egg and #screenData.egg > 0
		local hasP = screenData.pet and #screenData.pet > 0
		if not (hasE or hasP) then
			if listSg then pcall(function() listSg:Destroy() end) end
			listSg, listFrame = nil, nil
			rowPool = {}
			return
		end
		if not (listSg and listSg.Parent) then
			listSg = Instance.new("ScreenGui")
			listSg.Name = "CespEspList"
			listSg.ResetOnSpawn = false
			listSg.DisplayOrder = 50
			listSg.IgnoreGuiInset = true
			listSg.Parent = (gethui and gethui()) or game:GetService("CoreGui")

			listFrame = Instance.new("Frame")
			-- Sisi KANAN TENGAH: blok nempel pinggir kanan layar.
			listFrame.AnchorPoint = Vector2.new(1, 0.5)
			listFrame.Position = UDim2.new(1, -14, 0.5, 0)
			listFrame.Size = UDim2.new(0, 480, 0, 0)
			listFrame.AutomaticSize = Enum.AutomaticSize.Y
			listFrame.BackgroundTransparency = 1
			local layout = Instance.new("UIListLayout")
			layout.FillDirection = Enum.FillDirection.Vertical
			layout.SortOrder = Enum.SortOrder.LayoutOrder
			layout.Parent = listFrame
			listFrame.Parent = listSg
		end

		-- Slot urut: [egg…, pembatas, pet…]
		local slots = {}
		for _, s in ipairs(screenData.egg or {}) do slots[#slots + 1] = s end
		if hasE and hasP then slots[#slots + 1] = { sep = true } end
		for _, s in ipairs(screenData.pet or {}) do slots[#slots + 1] = s end

		for i, s in ipairs(slots) do
			local r = getSlot(i)
			r.frame.LayoutOrder = i
			if s.sep then
				r.name.Visible, r.kg.Visible, r.lv.Visible, r.tail.Visible = false, false, false, false
				r.sep.Visible = true
				r.sep.Text = '<font color="#9A9A9A">' .. string.rep("─", 22) .. "</font>"
			else
				r.name.Visible = s.name ~= nil
				r.kg.Visible = s.kg ~= nil
				r.lv.Visible = s.lv ~= nil
				r.tail.Visible = s.tail ~= nil
				r.sep.Visible = false
				r.name.Text = s.name or ""
				r.kg.Text = s.kg or ""
				r.lv.Text = s.lv or ""
				r.tail.Text = s.tail or ""
			end
		end
		-- Buang row lebih dari slot sekarang.
		for i = #slots + 1, #rowPool do
			local r = rowPool[i]
			if r then pcall(function() r.frame:Destroy() end) end
			rowPool[i] = nil
		end
	end
	ctx.espScreenPaint = paint

	local function claimPetScreen(rows)
		screenData.pet = (rows and #rows > 0) and rows or nil
		paint()
	end

	-- Palet billboard (target mode): card gelap di belakang → putih/abu aman.
	local C_NAME = "#FFFFFF"
	local C_WEIGHT = "#D6D6D6"
	local C_LV = "#969696"
	local C_MUT = "#B4B4B4"

	-- Palet screen list: TANPA background → teks harus cerah biar kebaca.
	-- Nama pet: warna tetap per nama (hash) — beda-beda tapi konsisten.
	local NAME_COLORS = {
		"#33C1FF", "#FF5EC8", "#4DF08A", "#B06CFF", "#2CE8CC", "#FF7A3C", "#C6FF33", "#FFD21E",
	}
	local C_S_WEIGHT = "#FFAA00"
	local C_S_LV = "#33FF77"
	local C_S_CD = "#FFD21E" -- warna sisa cd skill (READY pakai hijau C_S_LV)
	local function nameColor(s)
		local h = 0
		for i = 1, #s do h = (h * 31 + string.byte(s, i)) % 100003 end
		return NAME_COLORS[(h % #NAME_COLORS) + 1]
	end

	-- ===== Data cooldown pet (server push PetCooldownsUpdated) =====
	-- Event kirim (uuid, {{Time=<sisa detik>, Passive=<nama>}, ...}).
	-- Passive "Mutation" bukan skill → di-skip, konsisten dengan logika pickup.
	-- Sisa detik di-interpolasi lokal (Time - elapsed) biar countdown jalan
	-- halus antara dua push server.
	local cdRem = {} -- uuid -> { times = {sisa detik per skill}, at = os.clock() }
	local cdSeeded = {} -- uuid -> true (seed GetPetCooldown sudah/sedang dijalankan)
	local RSRaw = game:GetService("ReplicatedStorage")
	local cdGameEvents = RSRaw:FindFirstChild("GameEvents")
	local cdPushEvent = cdGameEvents and cdGameEvents:FindFirstChild("PetCooldownsUpdated")
	local cdSeedRemote = cdGameEvents and cdGameEvents:FindFirstChild("GetPetCooldown")

	local function storeCd(uuid, cdTable)
		if type(cdTable) ~= "table" then return end
		local times = {}
		for _, e in ipairs(cdTable) do
			if not tostring(e.Passive or ""):find("Mutation") then
				times[#times + 1] = tonumber(e.Time) or 0
			end
		end
		cdRem[uuid] = { times = times, at = os.clock() }
	end

	local gEnv = (getgenv and getgenv()) or _G
	if gEnv.__cespCdConn then pcall(function() gEnv.__cespCdConn:Disconnect() end) end
	gEnv.__cespCdConn = nil
	if cdPushEvent then
		gEnv.__cespCdConn = cdPushEvent.OnClientEvent:Connect(function(uuid, cdTable)
			if type(uuid) == "string" then storeCd(uuid, cdTable) end
		end)
	end

	-- Seed awal per pet: InvokeServer yield → fire-and-forget di task.spawn.
	local function seedCd(uuid)
		if cdSeeded[uuid] or not cdSeedRemote then return end
		cdSeeded[uuid] = true
		task.spawn(function()
			local ok, cd = pcall(function() return cdSeedRemote:InvokeServer(uuid) end)
			if ok then storeCd(uuid, cd) end
		end)
	end

	local function fmtDur(sec)
		if sec < 60 then return ("%ds"):format(math.clamp(math.ceil(sec), 0, 59)) end
		if sec < 3600 then return ("%dm"):format(math.floor(sec / 60)) end
		return ("%dh"):format(math.floor(sec / 3600))
	end

	-- Segmen cd untuk satu pet: "15s | 10m" atau "READY", nil kalau pet
	-- tanpa skill / data belum masuk (seed dikirim sekali per uuid).
	local function cdSegment(uuid)
		local rec = cdRem[uuid]
		if not rec then seedCd(uuid); return nil end
		if #rec.times == 0 then return nil end
		local el = os.clock() - rec.at
		local parts, allReady = {}, true
		for _, t0 in ipairs(rec.times) do
			local rem = t0 - el
			if rem > 0.05 then
				allReady = false
				parts[#parts + 1] = fmtDur(rem)
			end
		end
		if allReady then return "READY" end
		return table.concat(parts, " | ")
	end

	-- ===== Data pet =====
	local function update(mode)
		local okData, d = pcall(function() return DataService:GetData() end)
		local inv = okData and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}
		local seen = {}
		local rows = {}
		local pp = workspace:FindFirstChild("PetsPhysical")
		if pp then
			for _, mover in ipairs(pp:GetChildren()) do
				for _, petModel in ipairs(mover:GetChildren()) do
					if petModel:IsA("Model") then
						local uuid = petModel.Name
						local pData = inv[uuid]
						if pData then
							local pt = pData.PetType or "Pet"
							local pd = pData.PetData or {}
							local bw = tonumber(pd.BaseWeight)
							local lv = tonumber(pd.Level) or 0
							local mut = pd.MutationType
							local mutTxt = (mut and mut ~= "" and mut ~= "Normal" and mut ~= "m") and tostring(mut) or nil

							if mode == "screen" then
								local w = bw and string.format("%.2fkg", bw * WEIGHT_MULT) or "-"
								-- Slot spec: [nama][kg][Lv][cd]. Cd skill ("15s | 10m"),
								-- READY kalau semua skill siap — pengganti teks mutasi.
								local cd = cdSegment(uuid)
								rows[#rows + 1] = {
									name = ('<b><font color="%s">%s</font></b>'):format(nameColor(tostring(pt)), tostring(pt)),
									kg = ('<font color="%s">%s</font>'):format(C_S_WEIGHT, w),
									lv = ('<font color="%s">Lv.%d</font>'):format(C_S_LV, lv),
									tail = cd and ('<font color="%s">%s</font>'):format((cd == "READY") and C_S_LV or C_S_CD, cd) or nil,
								}
								if #rows >= 40 then break end
							else
								local adornee = partOf(petModel)
								if adornee then
									local key = "pet_" .. tostring(uuid)
									seen[key] = true
									local rec = acquire(key, adornee, 2.5)
									local lines = { ("<font color='%s'><b>🐾 %s</b></font>"):format(C_NAME, tostring(pt)) }
									if bw then
										lines[#lines + 1] = ("<font color='%s'>%.2f KG</font> <font color='%s'>[Lv.%d]</font>"):format(C_WEIGHT, bw * WEIGHT_MULT, C_LV, lv)
									end
									if mutTxt then
										lines[#lines + 1] = ("<font color='%s'>✨ %s</font>"):format(C_MUT, mutTxt)
									end
									rec.lbl.Text = table.concat(lines, "\n")
								end
							end
						end
					end
				end
				if #rows >= 40 then break end
			end
		end

		if mode == "screen" then
			claimPetScreen(rows)
		else
			claimPetScreen(nil)
			for key, rec in pairs(billboards) do
				if not seen[key] then rec.gui:Destroy(); billboards[key] = nil end
			end
		end
	end

	local function clearAll()
		clearBillboards()
		claimPetScreen(nil)
	end

	local loopId = 0
	function ctx.startEsp()
		loopId = loopId + 1
		local my = loopId
		-- Generation guard: loop dari eksekusi loader sebelumnya mati saat gen naik.
		local gen = (getgenv().GAG_ESP_GEN or 0)
		task.spawn(function()
			while ctx.alive() and ctx.CFG.espEnabled and loopId == my and (getgenv().GAG_ESP_GEN or 0) == gen do
				local mode = (ctx.CFG.espMode == "screen") and "screen" or "target"
				if mode ~= lastMode then
					lastMode = mode
					clearAll()
				end
				pcall(update, mode)
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
]=],
	["modules/misc/perf_mods.lua"] = [=[
--[[ perf_mods.lua — Performance / Graphics Optimization.
     - Hide My/Other Garden Plants : sembunyiin plant (LocalTransparencyModifier) buat FPS.
     - Auto Remove Spider Web FX    : hapus particle/trail/beam efek web terus-menerus.
     - Performance Mode (off/low/extreme) : matiin shadow & (extreme) semua efek partikel.
     - Disable 3D Rendering          : RunService:Set3dRenderingEnabled(false).
     Toggle: CFG.hideMyPlants / hideOtherPlants / autoRemoveWebFx / perfMode / disable3d. ]]
return function(ctx)
	local RS  = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	local Lighting = game:GetService("Lighting")
	local LP  = ctx.LP
	local CFG = ctx.CFG

	local function myFarm()
		local f; pcall(function() f = require(RS.Modules.GetFarm)(LP) end)
		return f
	end
	-- iterasi Plants_Physical: which = "mine" / "other"
	local function eachPlantContainer(which, fn)
		local Farm = workspace:FindFirstChild("Farm"); if not Farm then return end
		local mine = myFarm()
		for _, g in ipairs(Farm:GetChildren()) do
			local isMine = (g == mine)
			if (which == "mine" and isMine) or (which == "other" and not isMine) then
				local imp = g:FindFirstChild("Important")
				local pp = imp and imp:FindFirstChild("Plants_Physical")
				if pp then fn(pp) end
			end
		end
	end

	------------------------------------------------------------------- hide plants
	local function applyHide(which, hidden)
		eachPlantContainer(which, function(pp)
			for _, d in ipairs(pp:GetDescendants()) do
				if d:IsA("BasePart") then d.LocalTransparencyModifier = hidden and 1 or 0 end
			end
		end)
	end

	local hideConn
	local function hideLoopActive() return CFG.hideMyPlants or CFG.hideOtherPlants end
	local function ensureHideLoop()
		if hideConn then return end
		hideConn = task.spawn(function()
			while ctx.alive() and hideLoopActive() do
				if CFG.hideMyPlants then applyHide("mine", true) end
				if CFG.hideOtherPlants then applyHide("other", true) end
				task.wait(1) -- catch plant baru; ga perlu tiap frame
			end
			hideConn = nil
		end)
	end
	function ctx.setHidePlants(which, v)
		if which == "mine" then CFG.hideMyPlants = v else CFG.hideOtherPlants = v end
		if v then ensureHideLoop() else applyHide(which, false) end
	end

	------------------------------------------------------------------- spider web FX
	local WEB_MATCH = { "web", "spider", "cobweb" }
	local WEB_CLASS = { ParticleEmitter = true, Trail = true, Beam = true, Decal = true, Texture = true }
	local function isWeb(d)
		if not WEB_CLASS[d.ClassName] then return false end
		local n = d.Name:lower()
		for _, m in ipairs(WEB_MATCH) do if n:find(m) then return true end end
		return false
	end
	local webConn
	function ctx.setAutoRemoveWeb(v)
		CFG.autoRemoveWebFx = v
		if v then
			if webConn then return end
			webConn = task.spawn(function()
				while ctx.alive() and CFG.autoRemoveWebFx do
					for _, d in ipairs(workspace:GetDescendants()) do
						if isWeb(d) then pcall(function() d:Destroy() end) end
					end
					task.wait(1)
				end
				webConn = nil
			end)
		end
	end

	------------------------------------------------------------------- performance mode
	local FX_CLASS = { ParticleEmitter = true, Trail = true, Beam = true, Fire = true, Smoke = true, Sparkles = true, Explosion = true }
	local function setAllFxEnabled(on)
		for _, d in ipairs(workspace:GetDescendants()) do
			if FX_CLASS[d.ClassName] then pcall(function() d.Enabled = on end) end
		end
	end
	local pmConn
	local function stopPmLoop() if pmConn then task.cancel(pmConn); pmConn = nil end end
	function ctx.setPerfMode(mode)
		CFG.perfMode = mode
		stopPmLoop()
		if mode == "off" then
			pcall(function() Lighting.GlobalShadows = true end)
			setAllFxEnabled(true)
		elseif mode == "low" then
			pcall(function() Lighting.GlobalShadows = false end)
		elseif mode == "extreme" then
			pcall(function() Lighting.GlobalShadows = false end)
			-- terus-terusan matiin efek partikel (extreme FPS)
			pmConn = task.spawn(function()
				while ctx.alive() and CFG.perfMode == "extreme" do
					setAllFxEnabled(false)
					task.wait(1.5)
				end
			end)
		end
	end
	function ctx.getPerfModeOptions()
		return { { name = "off", display = "Off" }, { name = "low", display = "Low" }, { name = "extreme", display = "Extreme" } }
	end

	------------------------------------------------------------------- disable 3D
	function ctx.setDisable3d(v)
		CFG.disable3d = v
		ctx.elevate()
		pcall(function() RunService:Set3dRenderingEnabled(not v) end)
	end
end
]=],
	["modules/misc/player_mods.lua"] = [=[
--[[ player_mods.lua — utilitas Player: Noclip, Walk Speed, Infinity Jump.
     Semua toggle-able & guarded (auto re-apply tiap frame selama aktif).
     Toggle: CFG.noclipEnabled / CFG.walkSpeedEnabled (+CFG.walkSpeed) / CFG.infJumpEnabled. ]]
return function(ctx)
	local RunService = game:GetService("RunService")
	local UIS = game:GetService("UserInputService")
	local LP  = ctx.LP
	local CFG = ctx.CFG
	local DEFAULT_WS = 16

	local function char() return LP.Character end
	local function hum()
		local c = char()
		return c and c:FindFirstChildOfClass("Humanoid")
	end

	------------------------------------------------------------------- NOCLIP
	local noclipConn
	local function startNoclip()
		if noclipConn then return end
		noclipConn = RunService.Stepped:Connect(function()
			local c = char()
			if not c then return end
			for _, p in ipairs(c:GetDescendants()) do
				if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
			end
		end)
	end
	local function stopNoclip()
		if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
	end
	function ctx.setNoclip(v)
		CFG.noclipEnabled = v
		if v then startNoclip() else stopNoclip() end
	end

	------------------------------------------------------------------- WALK SPEED
	local wsConn
	local function startWS()
		if wsConn then return end
		wsConn = RunService.Stepped:Connect(function()
			local h = hum()
			if h then
				local target = tonumber(CFG.walkSpeed) or DEFAULT_WS
				if h.WalkSpeed ~= target then h.WalkSpeed = target end
			end
		end)
	end
	local function stopWS()
		if wsConn then wsConn:Disconnect(); wsConn = nil end
		local h = hum()
		if h then h.WalkSpeed = DEFAULT_WS end
	end
	function ctx.setWalkSpeed(v)
		CFG.walkSpeedEnabled = v
		if v then startWS() else stopWS() end
	end
	-- dipanggil pas nilai input berubah (biar langsung kepakai kalau lagi ON)
	function ctx.applyWalkSpeed()
		if not CFG.walkSpeedEnabled then return end
		local h = hum()
		if h then h.WalkSpeed = tonumber(CFG.walkSpeed) or DEFAULT_WS end
	end

	------------------------------------------------------------------- INFINITY JUMP
	local jumpConn
	local function startInfJump()
		if jumpConn then return end
		jumpConn = UIS.JumpRequest:Connect(function()
			local h = hum()
			if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
		end)
	end
	local function stopInfJump()
		if jumpConn then jumpConn:Disconnect(); jumpConn = nil end
	end
	function ctx.setInfJump(v)
		CFG.infJumpEnabled = v
		if v then startInfJump() else stopInfJump() end
	end
end
]=],
	["modules/mutation/automation_mutation_machine.lua"] = [=[
--[[ mutation.lua — logika mesin mutasi pet otomatis (garden). ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local PetsService = ctx.deps.PetsService
	local CFG         = ctx.CFG
	local LP          = ctx.LP
	local RS          = game:GetService("ReplicatedStorage")
	local TimeHelper  = require(RS.Modules.TimeHelper)
	local PetMutationMachineService_RE = RS:WaitForChild("GameEvents").PetMutationMachineService_RE

	local function farmCenter()
		local GetFarm = require(RS.Modules.GetFarm)
		local farm = GetFarm and GetFarm(LP)
		local pa = farm and farm:FindFirstChild("PetArea")
		if pa then return pa.Position end
		local char = LP.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		return hrp and hrp.Position or nil
	end

	local function cleanUuid(u)
		if not u then return "" end
		return tostring(u):lower():gsub("[{}]", "")
	end

	local function hasTargetMutation(pd, targetMutations)
		if not pd then return false end
		local mut = pd.MutationType
		local display = ctx.reg.mutDisplay and ctx.reg.mutDisplay(mut) or tostring(mut or "None")
		return targetMutations[display] == true
	end

	local function matchesType(typeSet, pt, pd)
		if ctx.petMatchesType then return ctx.petMatchesType(typeSet, pt, pd) end
		return typeSet and typeSet[pt] == true
	end

	local slotOf, nextSlot = {}, 0
	local GRID_COLS, GRID_SP = 6, 3
	local function getPos(uuid)
		if not slotOf[uuid] then slotOf[uuid] = nextSlot; nextSlot = nextSlot + 1 end
		local center = farmCenter()
		if not center then return nil end
		local i = slotOf[uuid]
		local col = i % GRID_COLS
		local row = math.floor(i / GRID_COLS)
		local offX = (col - (GRID_COLS - 1) / 2) * GRID_SP
		local offZ = (row - 1) * GRID_SP
		return center + Vector3.new(offX, 0, offZ)
	end

	-- Helper untuk memastikan tim pet terpasang 100% dengan benar (dengan retry loop)
	local function ensureEquippedTeam(targetTeamSet, targetPetUuid)
		local targetActive = {}
		if targetPetUuid then
			targetActive[cleanUuid(targetPetUuid)] = true
		end
		for u, _ in pairs(targetTeamSet) do
			targetActive[cleanUuid(u)] = true
		end

		for attempt = 1, 3 do
			local ok, d = pcall(function() return DataService:GetData() end)
			if not ok or not d or not d.PetsData then break end
			local eq = d.PetsData.EquippedPets or {}
			
			local localEq = {}
			for _, uuid in ipairs(eq) do
				localEq[cleanUuid(uuid)] = true
			end

			-- 1. Lepas pet yang tidak diijinkan berada di garden
			local unequippedAny = false
			for _, uuid in ipairs(eq) do
				local cu = cleanUuid(uuid)
				if not targetActive[cu] then
					pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
					unequippedAny = true
					task.wait(0.1)
				end
			end

			-- 2. Pasang target pet (jika leveling)
			local equippedAny = false
			if targetPetUuid and not localEq[cleanUuid(targetPetUuid)] then
				local pos = getPos(targetPetUuid)
				if pos then
					pcall(function() PetsService:FireServer("EquipPet", targetPetUuid, CFrame.new(pos)) end)
					equippedAny = true
					task.wait(0.1)
				end
			end

			-- 3. Pasang sisa anggota team yang belum terpasang
			for uuid, _ in pairs(targetTeamSet) do
				local cu = cleanUuid(uuid)
				if not localEq[cu] then
					local pos = getPos(uuid)
					if pos then
						pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
						equippedAny = true
						task.wait(0.1)
					end
				end
			end

			-- Jika tidak ada aktivitas unequip/equip lagi, berarti kebun sudah sinkron
			if not unequippedAny and not equippedAny then
				break
			end
			task.wait(0.3)
		end

		-- Verifikasi kelengkapan: SEMUA anggota target harus benar-benar ke-equip (no miss).
		local ok, d = pcall(function() return DataService:GetData() end)
		local eq = ok and d and d.PetsData and d.PetsData.EquippedPets or {}
		local eqSet = {}
		for _, uuid in ipairs(eq) do eqSet[cleanUuid(uuid)] = true end
		for cu in pairs(targetActive) do
			if not eqSet[cu] then return false end
		end
		return true
	end

	ctx.state.mutationStatus = "Idle"
	ctx.state.mutationPhase = "Idle"

	-- Mendapatkan ringkasan statistik mutation untuk UI
	function ctx.getMutationSummary()
		local ok, d = pcall(function() return DataService:GetData() end)
		local inv = ok and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}
		local machine = ok and d and d.PetMutationMachine or {}

		local expCount = 0
		for _ in pairs(CFG.mutationExpTeam) do expCount = expCount + 1 end

		local boostCount = 0
		for _ in pairs(CFG.mutationBoostTeam) do boostCount = boostCount + 1 end

		local phoenixCount = 0
		for _ in pairs(CFG.mutationPhoenixTeam) do phoenixCount = phoenixCount + 1 end

		local typesList = {}
		for k in pairs(CFG.mutationTargetTypes) do table.insert(typesList, k) end
		table.sort(typesList)
		local typesStr = #typesList > 0 and table.concat(typesList, ", ") or "None"

		local mutsList = {}
		for k in pairs(CFG.mutationTargetMutations) do table.insert(mutsList, k) end
		table.sort(mutsList)
		local mutsStr = #mutsList > 0 and table.concat(mutsList, ", ") or "None"

		local targetAge = CFG.mutationTargetAge or 50

		-- Info mesin
		local machineStr = "Empty"
		if machine.SubmittedPet then
			local pt = machine.SubmittedPet.PetType or "?"
			local mut = machine.SubmittedPet.PetData and machine.SubmittedPet.PetData.MutationType or "Normal"
			local mutName = ctx.reg.mutDisplay and ctx.reg.mutDisplay(mut) or mut
			machineStr = string.format("%s | %s", pt, mutName)
			if machine.PetReady then
				machineStr = machineStr .. " [Ready]"
			elseif machine.IsRunning or (machine.TimeLeft and machine.TimeLeft > 0) then
				local v2 = TimeHelper:GenerateColonFormatFromTime(machine.TimeLeft) or "00:00"
				machineStr = machineStr .. string.format(" [CD: %s]", v2)
			end
		end

		local readyCount = 0
		local doneCount = 0

		for _, v in pairs(inv) do
			local pt = v.PetType
			if matchesType(CFG.mutationTargetTypes, pt, v.PetData) then
				local pd = v.PetData or {}
				local lvl = pd.Level or 0
				local mut = pd.MutationType or "Normal"
				local isFav = pd.IsFavorite or false

				if not isFav then
					if hasTargetMutation(pd, CFG.mutationTargetMutations) then
						doneCount = doneCount + 1
					else
						-- Belum punya mutasi target = masih perlu diproses (bakal di-leveling
						-- dulu kalau age belum cukup, lalu di-submit). Hitung semua, lepas dari level.
						readyCount = readyCount + 1
					end
				end
			end
		end

		return {
			status = CFG.mutationEnabled and "ACTIVE" or "STOPPED",
			phase = ctx.state.mutationPhase or "Idle",
			expCount = expCount,
			boostCount = boostCount,
			phoenixCount = phoenixCount,
			types = typesStr,
			mutations = mutsStr,
			targetAge = targetAge,
			machine = machineStr,
			readyCount = readyCount,
			doneCount = doneCount,
		}
	end

	local function checkMutation()
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d then return end
		local petsData = d.PetsData
		local machine = d.PetMutationMachine
		if not petsData or not machine then return end
		local eq = petsData.EquippedPets or {}
		local inv = petsData.PetInventory and petsData.PetInventory.Data or {}

		local expTeam = CFG.mutationExpTeam or {}
		local boostTeam = CFG.mutationBoostTeam or {}
		local phoenixTeam = CFG.mutationPhoenixTeam or {}
		local targetTypes = CFG.mutationTargetTypes or {}
		local targetMutations = CFG.mutationTargetMutations or {}
		local targetAge = CFG.mutationTargetAge or 50
		local delayClaim = CFG.mutationDelayAutoClaim or 0.5

		-- CATATAN: passing team ASLI (uuid ber-kurawal) ke ensureEquippedTeam. cleanUuid dipakai
		-- HANYA buat matching di dalam fungsi; EquipPet butuh uuid format asli (dengan {}).

		-- A. DETEKSI APAKAH PET READY UNTUK DICLAIM
		if machine.PetReady then
			-- Validasi Phoenix team LENGKAP dulu (no miss) sebelum claim.
			if not ensureEquippedTeam(phoenixTeam) then
				ctx.state.mutationPhase = "Menunggu Phoenix Team lengkap..."
				return
			end
			ctx.state.mutationPhase = "Claiming Pet"

			-- Tunggu delay klaim
			task.wait(delayClaim)
			
			-- 1. Ambil snapshot mutasi pet di inventory sebelum klaim
			local preSnapshot = {}
			local okSnap, snapD = pcall(function() return DataService:GetData() end)
			if okSnap and snapD and snapD.PetsData then
				local invD = snapD.PetsData.PetInventory and snapD.PetsData.PetInventory.Data or {}
				for u, v in pairs(invD) do
					if matchesType(targetTypes, v.PetType, v.PetData) then
						preSnapshot[u] = v.PetData and v.PetData.MutationType or "Normal"
					end
				end
			end

			-- Kirim remote klaim
			pcall(function() PetMutationMachineService_RE:FireServer("ClaimMutatedPet") end)
			task.wait(1.0)

			-- 2. Tentukan pet hasil klaim.
			-- Sumber UTAMA = machine.SubmittedPet (pet yg barusan diproses) -> reliable, ga
			-- jadi "Unknown" walau data inventory telat sync. Diff inventory dipakai buat
			-- refine (mis. dapat mutasi hasil terbaru) kalau ketemu.
			local sp = machine.SubmittedPet or {}
			local claimedPetType = sp.PetType or "Unknown"
			local outcomeMutation = (sp.PetData and sp.PetData.MutationType) or "Normal"

			local ok3, d3 = pcall(function() return DataService:GetData() end)
			if ok3 and d3 and d3.PetsData then
				local newInv = d3.PetsData.PetInventory and d3.PetsData.PetInventory.Data or {}
				for u, v in pairs(newInv) do
					if matchesType(targetTypes, v.PetType, v.PetData) then
						local pd = v.PetData or {}
						local mut = pd.MutationType or "Normal"
						if not preSnapshot[u] or preSnapshot[u] ~= mut then
							claimedPetType = v.PetType
							outcomeMutation = mut
							break
						end
					end
				end
			end
			local isMatched = hasTargetMutation({ MutationType = outcomeMutation }, targetMutations)

			-- Durasi proses: dari submit sampai klaim
			local duration = 0
			if ctx.state.mutationSubmitTime then
				duration = os.time() - ctx.state.mutationSubmitTime
				ctx.state.mutationSubmitTime = nil
			end

			-- Kirim Webhook Claimed
			task.spawn(function()
				local WebhookMut = ctx.webhookMutation
				if WebhookMut then
					pcall(function() WebhookMut.sendClaimed(ctx, claimedPetType, outcomeMutation, isMatched, duration) end)
				end
			end)

			if isMatched then
				-- Pet ini dapat mutasi target. JANGAN matikan automation — lanjut proses
				-- pet ready berikutnya (section D sudah auto-skip pet yg sudah hasTargetMutation,
				-- jadi pet ini ga bakal diproses ulang).
				ctx.state.mutationPhase = "Matched! Lanjut next target..."
			else
				ctx.state.mutationPhase = "Non-target, lanjut..."
			end
			return
		end

		-- B. DETEKSI APAKAH MESIN SEDANG BERJALAN
		if machine.IsRunning or (machine.TimeLeft and machine.TimeLeft > 0) then
			-- Validasi Boost team LENGKAP dulu (no miss) baru dianggap boosting.
			if ensureEquippedTeam(boostTeam) then
				ctx.state.mutationPhase = "Boosting Machine"
			else
				ctx.state.mutationPhase = "Menunggu Boost Team lengkap..."
			end
			return
		end

		-- C. DETEKSI PET SUDAH DI-SUBMIT TETAPI BELUM DI-START
		if machine.SubmittedPet and not machine.IsRunning then
			ctx.state.mutationPhase = "Starting Machine"
			pcall(function() PetMutationMachineService_RE:FireServer("StartMachine") end)
			task.wait(0.5)
			return
		end

		-- D. DETEKSI MESIN KOSONG: Cari pet dari inventory untuk dimasukkan ke mesin
		if not machine.SubmittedPet then
			-- Cari pet target yang siap (level >= targetAge)
			local candidateUuid, candidateType
			for uuid, v in pairs(inv) do
				local pt = v.PetType
				local pd = v.PetData or {}
				local lvl = pd.Level or 0
				local mut = pd.MutationType or "Normal"
				local isFav = pd.IsFavorite or false

				-- Hanya pet tipe target, dengan level >= targetAge, bukan favorite, dan belum memiliki mutasi target
				if matchesType(targetTypes, pt, pd) and lvl >= targetAge and not isFav and not hasTargetMutation(pd, targetMutations) then
					candidateUuid = uuid
					candidateType = pt
					break
				end
			end

			-- Jika ada pet yang siap, submit ke mesin!
			if candidateUuid then
				ctx.state.mutationPhase = "Submitting Target"
				
				-- 1. Pastikan dicopot dari garden dulu sebelum di-submit
				pcall(function() PetsService:FireServer("UnequipPet", candidateUuid) end)
				task.wait(0.25)

				-- 2. Cari tool pet tersebut di Backpack atau Character
				local targetTool
				for _, item in ipairs(LP.Backpack:GetChildren()) do
					if item:IsA("Tool") and cleanUuid(item:GetAttribute("PET_UUID")) == cleanUuid(candidateUuid) then
						targetTool = item
						break
					end
				end
				if not targetTool and LP.Character then
					for _, item in ipairs(LP.Character:GetChildren()) do
						if item:IsA("Tool") and cleanUuid(item:GetAttribute("PET_UUID")) == cleanUuid(candidateUuid) then
							targetTool = item
							break
						end
					end
				end

				-- 3. Equip pet ke tangan lalu VERIFIKASI beneran dipegang sebelum submit.
				--    Cegah submit KOSONG kalau equip gagal/ke-race (mesin nerima submit hampa
				--    -> langsung "ready" tanpa isi). Kalau gagal pegang, JANGAN submit.
				if targetTool then
					local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
					local held
					for _ = 1, 4 do
						pcall(function()
							if hum then hum:EquipTool(targetTool) else targetTool.Parent = LP.Character end
						end)
						task.wait(0.35)
						local h = LP.Character and LP.Character:FindFirstChildWhichIsA("Tool")
						if h and cleanUuid(h:GetAttribute("PET_UUID")) == cleanUuid(candidateUuid) then
							held = h
							break
						end
					end

					if held then
						pcall(function() PetMutationMachineService_RE:FireServer("SubmitHeldPet") end)
						-- Duration: dari mulai EXP leveling kalau pet ini sempat di-level, else dari submit
						ctx.state.mutationStartTime = ctx.state.mutationStartTime or {}
						ctx.state.mutationSubmitTime = ctx.state.mutationStartTime[candidateUuid] or os.time()
						ctx.state.mutationStartTime[candidateUuid] = nil
						task.wait(0.5)

						-- Kirim Webhook Submitted
						task.spawn(function()
							local WebhookMut = ctx.webhookMutation
							if WebhookMut then
								local petLevel = inv[candidateUuid] and inv[candidateUuid].PetData and inv[candidateUuid].PetData.Level or 50
								pcall(function() WebhookMut.sendSubmitted(ctx, candidateType, petLevel) end)
							end
						end)

						-- Jalankan mesin langsung di detik yang sama
						pcall(function() PetMutationMachineService_RE:FireServer("StartMachine") end)
						task.wait(0.3)
					else
						ctx.state.mutationPhase = "Gagal pegang pet, retry..."
					end
				end
				return
			end

			-- Jika tidak ada pet yang siap, cari pet target yang levelnya kurang untuk kita LEVELING!
			local levelUuid, levelType, levelLvl
			for uuid, v in pairs(inv) do
				local pt = v.PetType
				local pd = v.PetData or {}
				local lvl = pd.Level or 0
				local mut = pd.MutationType or "Normal"
				local isFav = pd.IsFavorite or false

				if matchesType(targetTypes, pt, pd) and lvl < targetAge and not isFav and not hasTargetMutation(pd, targetMutations) then
					-- Prioritaskan level yang paling tinggi tapi masih di bawah targetAge agar cepat jadi!
					if not levelLvl or lvl > levelLvl then
						levelUuid = uuid
						levelType = pt
						levelLvl = lvl
					end
				end
			end

			-- Jika ada pet yang perlu di-leveling:
			if levelUuid then
				-- Validasi EXP team + target pet LENGKAP dulu (no miss).
				if ensureEquippedTeam(expTeam, levelUuid) then
					ctx.state.mutationPhase = "Leveling Target"
					-- Catat mulai proses EXP leveling pet ini (buat Duration total)
					ctx.state.mutationStartTime = ctx.state.mutationStartTime or {}
					if not ctx.state.mutationStartTime[levelUuid] then
						ctx.state.mutationStartTime[levelUuid] = os.time()
					end
				else
					ctx.state.mutationPhase = "Menunggu EXP Team lengkap..."
				end
				return
			end

			-- Jika sama sekali tidak ada pet kandidat
			ctx.state.mutationPhase = "Idle (No Targets)"
		end
	end

	local function mutationLoop()
		ctx.state.mutationId = (ctx.state.mutationId or 0) + 1
		local myId = ctx.state.mutationId
		ctx.elevate()

		-- Kirim Webhook Enabled
		task.spawn(function()
			local WebhookMut = ctx.webhookMutation
			if WebhookMut then
				local expTeamList = {}
				local boostTeamList = {}
				local phoenixTeamList = {}

				local okData, d = pcall(function() return DataService:GetData() end)
				if okData and d and d.PetsData then
					local inv = d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}

					-- 1. EXP Team
					for uuid, _ in pairs(CFG.mutationExpTeam or {}) do
						local pInfo = inv[uuid]
						if pInfo then table.insert(expTeamList, pInfo.PetType) end
					end

					-- 2. Boost Team
					for uuid, _ in pairs(CFG.mutationBoostTeam or {}) do
						local pInfo = inv[uuid]
						if pInfo then table.insert(boostTeamList, pInfo.PetType) end
					end

					-- 3. Phoenix Team
					for uuid, _ in pairs(CFG.mutationPhoenixTeam or {}) do
						local pInfo = inv[uuid]
						if pInfo then table.insert(phoenixTeamList, pInfo.PetType) end
					end
				end

				pcall(function() 
					WebhookMut.sendEnabled(ctx, CFG.mutationTargetTypes, CFG.mutationTargetMutations, CFG.mutationTargetAge, expTeamList, boostTeamList, phoenixTeamList)
				end)
			end
		end)

		while CFG.mutationEnabled and ctx.alive() and ctx.state.mutationId == myId do
			pcall(checkMutation)
			task.wait(3.0)
		end
		ctx.state.mutationStatus = "Idle"
		ctx.state.mutationPhase = "Idle"
	end

	function ctx.startMutation()
		if ctx.cancelClearGarden then ctx.cancelClearGarden() end
		task.spawn(mutationLoop)
	end

	function ctx.stopMutation()
		ctx.state.mutationId = (ctx.state.mutationId or 0) + 1 -- matikan loop
		if ctx.clearGarden then ctx.clearGarden("Mutation") end
	end
end
]=],
	["modules/mutation/automation_mutation.lua"] = [=[
--[[ cleanse.lua — Automation Cleanse Mutation (mutasi via aura + auto cleanse).
     - Pet Team for Mutation (aura pemberi mutasi) tetap di garden.
     - Pet target (Pet Types) dirotasi di garden (max = Max Pets in Garden) buat kena aura.
     - Target dapat mutasi di "Keep" -> disimpan (dikeluarkan dari garden).
     - Target dapat mutasi LAIN -> di-cleanse (Cleansing Pet Shard) biar coba lagi.
     Cleanse: pegang shard lalu PetShardService_RE:FireServer("ApplyShard", petModel). ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local PetsService = ctx.deps.PetsService
	local CFG = ctx.CFG
	local LP = ctx.LP
	local RS = game:GetService("ReplicatedStorage")
	local PetShardService = RS:WaitForChild("GameEvents"):WaitForChild("PetShardService_RE")
	local function setStatus(s) ctx.setStatus(s) end

	local function mutName(code)
		if ctx.reg and ctx.reg.mutDisplay then return ctx.reg.mutDisplay(code) end
		return tostring(code)
	end
	local function cleanUuid(u) return (tostring(u):gsub("[{}]", "")) end

	local function matchesType(typeSet, pt, pd)
		if ctx.petMatchesType then return ctx.petMatchesType(typeSet, pt, pd) end
		return typeSet and typeSet[pt] == true
	end

	----------------------------------------------------------------- placement
	local function farmCenter()
		local GetFarm = require(RS.Modules.GetFarm)
		local farm = GetFarm and GetFarm(LP)
		local pa = farm and farm:FindFirstChild("PetArea")
		if pa then return pa.Position end
		local char = LP.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		return hrp and hrp.Position or nil
	end
	local slotOf, nextSlot = {}, 0
	local GRID_COLS, GRID_SP = 6, 3
	local function getPos(uuid)
		if not slotOf[uuid] then slotOf[uuid] = nextSlot; nextSlot = nextSlot + 1 end
		local center = farmCenter(); if not center then return nil end
		local i = slotOf[uuid]
		local col, row = i % GRID_COLS, math.floor(i / GRID_COLS)
		return center + Vector3.new((col - (GRID_COLS - 1) / 2) * GRID_SP, 0, (row - 1) * GRID_SP)
	end

	----------------------------------------------------------------- shard cleanse
	local function findShard()
		for _, src in ipairs({ LP.Character, LP:FindFirstChildOfClass("Backpack") }) do
			if src then for _, t in ipairs(src:GetChildren()) do
				if t:IsA("Tool") and (t:HasTag("PetShardTool") or tostring(t.Name):find("Cleansing Pet Shard")) then return t end
			end end
		end
		return nil
	end
	local function findPetModel(uuid)
		local pp = workspace:FindFirstChild("PetsPhysical")
		if not pp then return nil end
		for _, d in ipairs(pp:GetDescendants()) do
			if d.Name == uuid then return d end
		end
		return nil
	end
	-- Cleanse pet yang SUDAH equipped (model ada di garden).
	local function cleansePet(uuid)
		local model = findPetModel(uuid)
		if not model then return false, "model tidak ada" end
		local shard = findShard()
		if not shard then return false, "shard habis" end
		local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
		if not hum then return false, "no humanoid" end
		local held
		for _ = 1, 3 do
			pcall(function() hum:EquipTool(shard) end); task.wait(0.3)
			held = LP.Character and LP.Character:FindFirstChildWhichIsA("Tool")
			if held and (held:HasTag("PetShardTool") or tostring(held.Name):find("Cleansing Pet Shard")) then break end
			shard = findShard(); if not shard then break end
		end
		if held and (held:HasTag("PetShardTool") or tostring(held.Name):find("Cleansing Pet Shard")) then
			pcall(function() PetShardService:FireServer("ApplyShard", model) end)
			task.wait(0.4)
			return true
		end
		return false, "gagal pegang shard"
	end

	----------------------------------------------------------------- mutasi helpers
	local function hasMut(pd)
		local m = pd.MutationType
		if not m or m == "" or m == "Normal" or m == "m" then return false end
		return mutName(m) ~= "None"
	end
	local function isKept(pd)
		return hasMut(pd) and CFG.cleanseKeepMutations[mutName(pd.MutationType)] == true
	end

	ctx.state.cleansePhase = "Idle"

	-- Ringkasan status untuk UI
	function ctx.getCleanseSummary()
		local ok, d = pcall(function() return DataService:GetData() end)
		local inv = ok and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}

		local teamCount = 0
		for _ in pairs(CFG.cleanseTeamUuids or {}) do teamCount = teamCount + 1 end
		local typesList = {}
		for k in pairs(CFG.cleansePetTypes or {}) do typesList[#typesList + 1] = k end
		table.sort(typesList)
		local keepOrder = {}
		for k in pairs(CFG.cleanseKeepMutations or {}) do keepOrder[#keepOrder + 1] = k end
		table.sort(keepOrder)

		local ready, already = 0, {}
		for _, k in ipairs(keepOrder) do already[k] = 0 end
		for _, v in pairs(inv) do
			local pt = v.PetType
			if pt and matchesType(CFG.cleansePetTypes, pt, v.PetData) then
				local pd = v.PetData or {}
				local disp = hasMut(pd) and mutName(pd.MutationType) or "None"
				if CFG.cleanseKeepMutations[disp] then
					already[disp] = (already[disp] or 0) + 1
				elseif not pd.IsFavorite then
					ready = ready + 1
				end
			end
		end

		return {
			status = CFG.cleanseEnabled and "ACTIVE" or "STOPPED",
			team = teamCount,
			types = #typesList > 0 and table.concat(typesList, ", ") or "None",
			keep = #keepOrder > 0 and table.concat(keepOrder, ", ") or "None",
			ready = ready,
			already = already,
			keepOrder = keepOrder,
			maxPets = CFG.cleanseMaxPets or 2,
			phase = ctx.state.cleansePhase or "Idle",
		}
	end

	----------------------------------------------------------------- loop utama
	local function checkCleanse()
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d or not d.PetsData then return end
		local eq = d.PetsData.EquippedPets or {}
		local inv = d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}

		local teamSet = CFG.cleanseTeamUuids or {}
		local targetTypes = CFG.cleansePetTypes or {}
		local maxPets = CFG.cleanseMaxPets or 2

		local localEq = {}
		for _, u in ipairs(eq) do localEq[cleanUuid(u)] = u end -- clean->original

		-- A. FIRST RUN: reset garden
		if ctx.state.cleanseFirstRun then
			ctx.state.cleanseFirstRun = false
			for _, uuid in ipairs(eq) do
				pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
				localEq[cleanUuid(uuid)] = nil
				task.wait(0.1)
			end
		end

		-- B. Pasang team aura (persisten)
		for uuid in pairs(teamSet) do
			if not localEq[cleanUuid(uuid)] then
				local pos = getPos(uuid)
				if pos then
					pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
					localEq[cleanUuid(uuid)] = uuid
					task.wait(0.1)
				end
			end
		end

		-- C. Proses pet target yang equipped
		local activeTargets = 0
		for cu, origUuid in pairs(localEq) do
			if not teamSet[origUuid] and not teamSet["{" .. cu .. "}"] then
				local pInfo = inv[origUuid] or inv["{" .. cu .. "}"]
				local pt = pInfo and pInfo.PetType
				local pd = pInfo and pInfo.PetData or {}
				if pt and matchesType(targetTypes, pt, pd) then
					if pd.IsFavorite then
						-- Favorite -> JANGAN cleanse (lindungi mutasi). Keluarkan dari garden.
						ctx.state.cleansePhase = "Skip favorite (protected)"
						pcall(function() PetsService:FireServer("UnequipPet", origUuid) end)
						localEq[cu] = nil
						task.wait(0.1)
					elseif isKept(pd) then
						-- Harvest: mutasi bagus -> keluarkan dari garden (disimpan)
						ctx.state.cleansePhase = "Harvest " .. mutName(pd.MutationType)
						pcall(function() PetsService:FireServer("UnequipPet", origUuid) end)
						localEq[cu] = nil
						task.wait(0.15)

						-- Webhook: mutasi didapat
						if ctx.webhookCleanse then
							local gotType, gotMut, gotAge = pt, mutName(pd.MutationType), pd.Level or 0
							local remains = 0
							for _, iv in pairs(inv) do
								local ipt = iv.PetType
								if ipt and matchesType(targetTypes, ipt, iv.PetData) then
									local ipd = iv.PetData or {}
									if not ipd.IsFavorite and not isKept(ipd) then remains = remains + 1 end
								end
							end
							task.spawn(function()
								pcall(function() ctx.webhookCleanse.sendObtained(ctx, gotType, gotMut, gotAge, remains) end)
							end)
						end
					elseif hasMut(pd) then
						-- Mutasi salah -> cleanse (tetap di garden buat coba lagi)
						ctx.state.cleansePhase = "Cleanse " .. mutName(pd.MutationType)
						cleansePet(origUuid)
						activeTargets = activeTargets + 1
					else
						-- Normal -> lagi nunggu aura
						activeTargets = activeTargets + 1
					end
				elseif not (pt and matchesType(targetTypes, pt, pd)) then
					-- pet lain (bukan team, bukan target) -> keluarkan
					pcall(function() PetsService:FireServer("UnequipPet", origUuid) end)
					localEq[cu] = nil
					task.wait(0.1)
				end
			end
		end

		-- D. Isi garden dengan target baru sampai maxPets (belum punya mutasi keep)
		local needed = maxPets - activeTargets
		if needed > 0 then
			local pool = {}
			for uuid, v in pairs(inv) do
				local pt = v.PetType
				local pd = v.PetData or {}
				if not localEq[cleanUuid(uuid)] and pt and matchesType(targetTypes, pt, pd) and not pd.IsFavorite and not isKept(pd) then
					pool[#pool + 1] = uuid
				end
			end
			for i = 1, math.min(needed, #pool) do
				local pos = getPos(pool[i])
				if pos then
					pcall(function() PetsService:FireServer("EquipPet", pool[i], CFrame.new(pos)) end)
					localEq[cleanUuid(pool[i])] = pool[i]
					activeTargets = activeTargets + 1
					task.wait(0.15)
				end
			end
		end

		ctx.state.cleansePhase = string.format("Farming: %d/%d target", activeTargets, maxPets)
	end

	local function cleanseLoop()
		ctx.state.cleanseId = (ctx.state.cleanseId or 0) + 1
		local myId = ctx.state.cleanseId
		ctx.elevate()
		ctx.state.cleanseFirstRun = true

		while CFG.cleanseEnabled and ctx.alive() and ctx.state.cleanseId == myId do
			if not next(CFG.cleansePetTypes or {}) then
				setStatus("Cleanse: pilih Pet Types dulu")
				task.wait(3)
			else
				pcall(checkCleanse)
				setStatus("Cleanse " .. tostring(ctx.state.cleansePhase))
				task.wait(3)
			end
		end
		ctx.state.cleansePhase = "Idle"
	end

	function ctx.startCleanse()
		if ctx.cancelClearGarden then ctx.cancelClearGarden() end -- batalkan clear tertunda
		task.spawn(cleanseLoop) -- loop set firstRun=true -> reset garden + equip team aura
	end

	function ctx.stopCleanse()
		ctx.state.cleanseId = (ctx.state.cleanseId or 0) + 1 -- matikan loop
		if ctx.clearGarden then ctx.clearGarden("Auto Mutation") end
	end
end
]=],
	["modules/mutation/cleanse_webhook.lua"] = [=[
--[[ webhook/cleanse.lua — webhook Automation Mutation (aura + cleanse).
     Dikirim saat pet target dapat mutasi "keep" (harvest). ]]
local cleanseWebhook = {}

function cleanseWebhook.sendObtained(ctx, petType, mutation, age, remainsQueue)
	local CFG = ctx.CFG
	if not CFG.webhookUrl or CFG.webhookUrl == "" then return end

	local payload = {
		embeds = {
			{
				title = "\240\159\140\177 Growth \226\128\162 Mutation",
				color = 3066993,
				fields = {
					{
						name = "Profile :",
						value = string.format("> Username : ||%s||", ctx.LP.Name),
						inline = false,
					},
					{
						name = "Mutation Obtained",
						value = string.format(
							"> Pet Type: `%s`\n" ..
							"> Mutation: `%s`\n" ..
							"> Age: `%s`\n" ..
							"> Remains Queue: `%s`",
							tostring(petType or "?"),
							tostring(mutation or "?"),
							tostring(age or 0),
							tostring(remainsQueue or 0)
						),
						inline = false,
					},
				},
				footer = {
					text = os.date("%B %d | %I:%M %p"),
					icon_url = "https://raw.githubusercontent.com/milmscr/opoki/main/tegalan/Logo/logo_icon.png",
				},
			},
		},
	}
	if ctx.sendWebhook then ctx.sendWebhook(CFG.webhookUrl, payload, ctx) end
end

return cleanseWebhook
]=],
	["modules/mutation/webhook.lua"] = [=[
--[[ webhook/mutation.lua — Discord webhook untuk mutation.
     Di-load via HttpGet loader; sender diambil dari ctx.sendWebhook (bukan require script). ]]
local HttpService = game:GetService("HttpService")

local mutationWebhook = {}

-- Webhook saat mutasi di-enable
function mutationWebhook.sendEnabled(ctx, targetTypes, targetMuts, targetAge, expTeamList, boostTeamList, phoenixTeamList)
	local CFG = ctx.CFG
	if not CFG.webhookUrl or CFG.webhookUrl == "" then return end

	local typesList = {}
	for k in pairs(targetTypes) do table.insert(typesList, "`" .. k .. "`") end
	local typesText = #typesList > 0 and table.concat(typesList, ", ") or "None"

	local mutsList = {}
	for k in pairs(targetMuts) do table.insert(mutsList, "`" .. k .. "`") end
	local mutsText = #mutsList > 0 and table.concat(mutsList, ", ") or "None"

	local expText = #expTeamList > 0 and table.concat(expTeamList, ", ") or "None"
	local boostText = #boostTeamList > 0 and table.concat(boostTeamList, ", ") or "None"
	local phText = #phoenixTeamList > 0 and table.concat(phoenixTeamList, ", ") or "None"

	local payload = {
		embeds = {
			{
				title = "Mutation • Machine Enabled",
				color = 10181046, -- Purple (hex 0x9b59b6 -> 10181046)
				fields = {
					{
						name = "Profile :",
						value = string.format("> Username : ||%s||", ctx.LP.Name),
						inline = false
					},
					{
						name = "Mutation Configuration",
						value = string.format(
							"> Target Types: %s\n" ..
							"> Keep Mutations: %s\n" ..
							"> Target Age: `%s`",
							typesText,
							mutsText,
							tostring(targetAge)
						),
						inline = false
					},
					{
						name = "Mutation Support Teams",
						value = string.format(
							"> EXP Team: %s\n" ..
							"> Boost Team: %s\n" ..
							"> Phoenix Team: %s",
							expText,
							boostText,
							phText
						),
						inline = false
					}
				},
				footer = {
					text = os.date("%B %d | %I:%M %p"),
					icon_url = "https://raw.githubusercontent.com/milmscr/opoki/main/tegalan/Logo/logo_icon.png"
				}
			}
		}
	}
	if ctx.sendWebhook then ctx.sendWebhook(CFG.webhookUrl, payload, ctx) end
end

-- Webhook saat pet disubmit ke mesin
function mutationWebhook.sendSubmitted(ctx, petType, level)
	local CFG = ctx.CFG
	if not CFG.webhookUrl or CFG.webhookUrl == "" then return end

	local payload = {
		embeds = {
			{
				title = "Mutation • Pet Submitted",
				color = 10181046, -- Purple
				fields = {
					{
						name = "Profile :",
						value = string.format("> Username : ||%s||", ctx.LP.Name),
						inline = false
					},
					{
						name = "Machine Status",
						value = string.format(
							"> Submitted Pet: `%s`\n" ..
							"> Age: `%s` (Target: `%s`)",
							petType,
							tostring(level),
							tostring(CFG.mutationTargetAge)
						),
						inline = false
					}
				},
				footer = {
					text = os.date("%B %d | %I:%M %p"),
					icon_url = "https://raw.githubusercontent.com/milmscr/opoki/main/tegalan/Logo/logo_icon.png"
				}
			}
		}
	}
	if ctx.sendWebhook then ctx.sendWebhook(CFG.webhookUrl, payload, ctx) end
end

-- Format detik -> "Xm Ys" / "Ys"
local function fmtDuration(sec)
	sec = math.max(0, math.floor(tonumber(sec) or 0))
	if sec >= 60 then return string.format("%dm %ds", math.floor(sec / 60), sec % 60) end
	return string.format("%ds", sec)
end

-- Webhook saat pet diklaim (hasil mutasi)
function mutationWebhook.sendClaimed(ctx, petType, outcomeMutation, isMatched, duration)
	local CFG = ctx.CFG
	if not CFG.webhookUrl or CFG.webhookUrl == "" then return end

	local mutDisplay = ctx.reg.mutDisplay and ctx.reg.mutDisplay(outcomeMutation) or outcomeMutation
	local statusText = isMatched and "✅ Target Found" or "❌ Non-target"

	local payload = {
		embeds = {
			{
				title = "Mutation • Pet Claimed",
				color = isMatched and 3066993 or 10181046, -- Green or Purple
				fields = {
					{
						name = "Profile :",
						value = string.format("> Username : ||%s||", ctx.LP.Name),
						inline = false
					},
					{
						name = "Claim Outcome",
						value = string.format(
							"> Pet Type: `%s`\n" ..
							"> Outcome Mutation: `%s`\n" ..
							"> Duration: `%s`\n" ..
							"> Status: **%s**",
							petType,
							mutDisplay,
							fmtDuration(duration),
							statusText
						),
						inline = false
					}
				},
				footer = {
					text = os.date("%B %d | %I:%M %p"),
					icon_url = "https://raw.githubusercontent.com/milmscr/opoki/main/tegalan/Logo/logo_icon.png"
				}
			}
		}
	}
	if ctx.sendWebhook then ctx.sendWebhook(CFG.webhookUrl, payload, ctx) end
end

return mutationWebhook
]=],
	["modules/pet/automation_boost_pet.lua"] = [=[
--[[ boostpet.lua — Automation Boost Pet.
     Pilih pet + item boost (Pet Toy). Otomatis apply boost ke pet;
     re-apply pas boost habis (berdasar durasi item, atribut "p" = boostTime detik).
     Mekanik: pegang Tool bertag "PetBoost" lalu PetBoostService:FireServer("ApplyBoost", petUuid). ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local CFG = ctx.CFG
	local LP = ctx.LP
	local RS = game:GetService("ReplicatedStorage")
	local PetBoostService = RS:WaitForChild("GameEvents"):WaitForChild("PetBoostService")
	local function setStatus(s) ctx.setStatus(s) end

	-- "Medium Pet Toy x42[Passive Boost]" -> "Medium Pet Toy"
	local function baseName(n) return (tostring(n):gsub("%s*x%d+.*$", "")) end

	-- Daftar item boost (tag PetBoost) di backpack, dedupe per base name -> dropdown.
	function ctx.getBoostItemOptions(selectedSet)
		local out, seen = {}, {}
		local bp = LP:FindFirstChildOfClass("Backpack")
		if not bp then return out end
		for _, t in ipairs(bp:GetChildren()) do
			if t:IsA("Tool") and t:HasTag("PetBoost") then
				local bn = baseName(t.Name)
				if not seen[bn] then
					seen[bn] = true
					local dur = t:GetAttribute("p")
					out[#out + 1] = { value = bn, display = dur and (bn .. " (" .. tostring(dur) .. "s)") or bn }
				end
			end
		end
		table.sort(out, function(a, b)
			local sa = selectedSet and selectedSet[a.value] and 1 or 0
			local sb = selectedSet and selectedSet[b.value] and 1 or 0
			if sa ~= sb then return sa > sb end
			return a.display < b.display
		end)
		return out
	end

	local THRESHOLD = 5 -- detik; boost dianggap habis kalau sisa <= ini

	-- Key unik per varian boost: type + amount. Small & Medium Pet Toy sama-sama
	-- PASSIVE_BOOST tapi amount beda (0.1 vs 0.2) dan BISA di-stack, jadi harus dibedakan.
	local function boostKey(btype, amount)
		local n = tonumber(amount)
		return tostring(btype) .. "|" .. (n and tostring(n) or tostring(amount))
	end

	-- Baca boost yang MASIH aktif di pet (dari PetData.Boosts, sisa Time > THRESHOLD).
	-- Keyed by type+amount supaya varian beda amount tidak saling menutupi.
	local function petActiveTypes(uuid)
		local out = {}
		local ok, d = pcall(function() return DataService:GetData() end)
		local data = ok and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data
		local pd = data and data[uuid]
		local boosts = pd and pd.PetData and pd.PetData.Boosts
		if type(boosts) == "table" then
			for _, b in ipairs(boosts) do
				if b.BoostType and (tonumber(b.Time) or 0) > THRESHOLD then
					out[boostKey(b.BoostType, b.BoostAmount)] = true
				end
			end
		end
		return out
	end

	-- Pet dianggap AKTIF di garden kalau uuid-nya ada di PetsData.EquippedPets (array uuid).
	-- Boost cuma berlaku ke pet yang lagi placed; kalau nggak placed, skip (percuma).
	local function isPetActive(uuid)
		local ok, d = pcall(function() return DataService:GetData() end)
		local eq = ok and d and d.PetsData and d.PetsData.EquippedPets
		return type(eq) == "table" and table.find(eq, uuid) ~= nil
	end

	-- Cari tool boost dipilih (Character dulu) yang varian (type+amount)-nya BELUM aktif di pet.
	local function findToolForMissing(activeTypes)
		local sel = CFG.boostItemNames or {}
		for _, src in ipairs({ LP.Character, LP:FindFirstChildOfClass("Backpack") }) do
			if src then
				for _, t in ipairs(src:GetChildren()) do
					if t:IsA("Tool") and t:HasTag("PetBoost") and sel[baseName(t.Name)] then
						local bt = t:GetAttribute("q")
						if bt and not activeTypes[boostKey(bt, t:GetAttribute("o"))] then return t end
					end
				end
			end
		end
		return nil
	end

	local function boostLoop()
		ctx.state.boostId = (ctx.state.boostId or 0) + 1
		local myId = ctx.state.boostId
		ctx.elevate()

		while CFG.boostEnabled and ctx.alive() and ctx.state.boostId == myId do
			local pets = CFG.boostPetUuids or {}
			if not next(pets) then
				setStatus("Boost: pilih pet dulu")
				task.wait(3)
			else
				for uuid in pairs(pets) do
					if not CFG.boostEnabled or ctx.state.boostId ~= myId then break end
					-- Skip pet yang nggak aktif/placed di garden (boost ga guna)
					if not isPetActive(uuid) then continue end
					-- Cek state asli: boost apa yang masih aktif di pet ini
					local active = petActiveTypes(uuid)
					local tool = findToolForMissing(active)
					if tool then
						local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
						if hum then
							-- pastikan item bener-bener dipegang sebelum ApplyBoost
							local held
							for _ = 1, 3 do
								pcall(function() hum:EquipTool(tool) end)
								task.wait(0.35)
								held = LP.Character and LP.Character:FindFirstChildWhichIsA("Tool")
								if held and held:HasTag("PetBoost") then break end
								tool = findToolForMissing(active)
								if not tool then break end
							end
							if held and held:HasTag("PetBoost") then
								pcall(function() PetBoostService:FireServer("ApplyBoost", uuid) end)
								setStatus(("Boost: %s -> #%s"):format(baseName(held.Name), uuid:sub(2, 5)))
								task.wait(0.6)
							end
						end
					end
				end
				task.wait(2)
			end
		end
	end

	function ctx.startBoostPet() task.spawn(boostLoop) end
end
]=],
	["modules/pet/automation_pickup_pet_v1.lua"] = [=[
--[[ automation_pickup_pet_v1.lua — PnP V1 (skill-trigger detection).
     Trick skip-animasi: tarik pet SETELAH skill mulai (efeknya tetap jalan walau pet ditarik),
     terus langsung place lagi -> cooldown mulai dari awal tanpa nunggu animasi.

     Pemicu "skill mulai" (dari log in-game):
       1. ZONE  : RemoteEvent PetZoneAbility(uuid, true, ...)  (Peacock, Lion, dst.)
       2. CD0   : cooldown salah satu passive (non-Mutation) nyentuh 0 dengan sendirinya
       3. (ADV dihapus — cd yang di-advance tetap countdown ke 0 dulu, jadi ketangkep CD0)
     Pet zone: CD0 nunggu event ZONE (fallback kalau event nggak datang), terus +PICKUP_DELAY.
     Pet non-zone: CD0 + CD0_MIN (ancang-ancang 0.8 s).
     Setelah pemicu: tunggu PICKUP_DELAY -> Unequip -> tunggu server ack -> Equip -> verifikasi.

     Timing dikunci di konstanta (PICKUP_DELAY 0.5 / EQUIP_DELAY 1E-20 / SCAN_INTERVAL 0.20).
     Config: pnpUuids, pnpEnabled.
     Fungsi: ctx.startPnpV1 / ctx.stopPnpV1 / ctx.forcePickupPets. Expose ctx.inventoryPetOptions (V1 & V2). ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local PetsService = ctx.deps.PetsService
	local CFG         = ctx.CFG
	local function setStatus(s) ctx.setStatus(s) end

	local RS = game:GetService("ReplicatedStorage")
	local LP = ctx.LP

	local cdMap = ctx.state.cdMap or {}
	ctx.state.cdMap = cdMap

	-- Timing DIKUNCI (hasil tes in-game, nggak dibaca dari CFG / UI lagi)
	local PICKUP_DELAY   = 0.5   -- jeda setelah skill mulai sebelum pet ditarik
	local EQUIP_DELAY    = 1e-20 -- jeda tambahan unequip -> equip setelah server ack (praktis 0)
	local SCAN_INTERVAL  = 0.20  -- polling cd cadangan (sinyal utama = push server)
	local CD0_MIN        = 0.8  -- ancang-ancang abis cd 0 (Pandora narik Dilo/Hotdog ~0.6-1.3 s abis cd 0)
	local ZONE_FALLBACK  = 2.0  -- pet zone: kalau event ZONE nggak datang segini setelah CD0, tetap tarik
	local ADV_DROP, ADV_LOW = nil, nil -- (trigger ADV dihapus)
	local PLACE_GRACE    = 1.5  -- abis place: sampel cd pertama yang 0 nggak dihitung CD0 (anti loop).
	                            -- ADV & ZONE tetap jalan (team loop bisa langsung advance pet baru di-place)
	local UNEQUIP_ACK    = 0.35 -- maks nunggu server konfirmasi unequip
	local VERIFY_WAIT    = 0.8  -- maks nunggu konfirmasi equip sebelum retry
	local EQUIP_RETRIES  = 3
	local MIN_POLL       = SCAN_INTERVAL

	local GameEvents          = RS:WaitForChild("GameEvents")
	local GetPetCooldown      = GameEvents:WaitForChild("GetPetCooldown")
	local PetCooldownsUpdated = GameEvents:FindFirstChild("PetCooldownsUpdated")
	local PetZoneAbility      = GameEvents:FindFirstChild("PetZoneAbility")

	-------------------------------------------------------------- state per pet
	local prevCd      = {} -- uuid -> { [passiveKey] = time }
	local fireAt      = {} -- uuid -> os.clock() kapan pickup
	local fireReason  = {} -- uuid -> "ZONE"/"CD0"/"ADV"/"FORCE"
	local waitZone    = {} -- uuid -> deadline fallback buat pet zone
	-- Passive yang skill-nya zone (keluar pas event PetZoneAbility, ~0.4-1 s SETELAH cd 0).
	-- Dipelajari otomatis dari event & disimpan di getgenv biar awet antar reload.
	local zonePassive
	do
		local g = (getgenv and getgenv()) or _G
		g.__pnpZonePassive = g.__pnpZonePassive or { ["Lion Call"] = true, ["Utter Beauty"] = true }
		zonePassive = g.__pnpZonePassive
	end
	local busy        = {} -- uuid -> true selama pickup/place
	local ignoreUntil = {} -- uuid -> os.clock()
	local lastEmpty   = {} -- uuid -> os.clock() terakhir cd kosong (server: pet ke-unequip)
	local lastValid   = {} -- uuid -> os.clock() terakhir cd valid (server: pet ada di kebun)

	local function commitDelay()
		return PICKUP_DELAY
	end

	local function schedule(uuid, reason, override, minDelay)
		if busy[uuid] then return end
		if fireAt[uuid] and not override then return end
		fireAt[uuid] = os.clock() + math.max(commitDelay(), minDelay or 0)
		fireReason[uuid] = reason
	end

	-------------------------------------------------------------- sumber sinyal
	local function onCd(uuid, cd)
		if type(cd) ~= "table" then return end
		local now = os.clock()
		if #cd == 0 then
			lastEmpty[uuid] = now
			prevCd[uuid] = nil
			return
		end
		local cur, data, seen, hasInf = {}, {}, {}, false
		for _, e in ipairs(cd) do
			local name = tostring(e.Passive or "?")
			local t = tonumber(e.Time) or 0
			if t == math.huge then hasInf = true end
			data[#data + 1] = { Passive = e.Passive, Time = t }
			seen[name] = (seen[name] or 0) + 1
			cur[name .. "#" .. seen[name]] = t
		end
		cdMap[uuid] = { data = data }
		if hasInf then prevCd[uuid] = nil; return end -- transisi unequip/equip
		lastValid[uuid] = now

		local prev = prevCd[uuid]
		prevCd[uuid] = cur
		if not CFG.pnpEnabled then return end

		local reason, isZone
		for key, t in pairs(cur) do
			if not key:find("Mutation") then
				local p = prev and prev[key]
				local r
				-- p == nil = sampel pertama. Abis place jangan langsung dianggap CD0 (anti loop
				-- kalau ada passive yang memang nyangkut di 0).
				if t <= 0 and ((p == nil and now >= (ignoreUntil[uuid] or 0)) or (p and p > 0)) then
					r = "CD0"
				end
				-- (Trigger ADV dihapus: dari log, cd yang di-advance ke ~4-5 TETAP countdown ke 0
				--  dulu baru skill keluar. Narik pas ADV = narik sebelum skill -> skill hilang.)
				if r then
					local z = zonePassive[key:gsub("#%d+$", "")] == true
					-- passive non-zone menang (langsung dijadwalkan); zone nunggu event
					if not reason or (isZone and not z) then reason, isZone = r, z end
				end
			end
		end
		if not reason then return end
		if isZone then
			-- skill zone baru "keluar" pas event ZONE; tunggu itu (dengan fallback)
			if not fireAt[uuid] and not waitZone[uuid] then waitZone[uuid] = now + ZONE_FALLBACK end
		else
			-- CD0 natural: skill butuh ~0.8 s buat "nempel" sebelum aman ditarik (ancang-ancang)
			schedule(uuid, reason, false, CD0_MIN)
		end
	end

	local function onZone(a1, active, _, model, passiveName)
		local uuid = (type(a1) == "string" and a1:sub(1, 1) == "{") and a1
			or (typeof(model) == "Instance" and model.Name) or nil
		if not uuid then return end
		if type(passiveName) == "string" then zonePassive[passiveName] = true end
		if active ~= true or not CFG.pnpEnabled then return end
		waitZone[uuid] = nil
		schedule(uuid, "ZONE", true) -- hitung jeda dari event ZONE (lebih akurat dari CD0)
	end

	do
		local g = (getgenv and getgenv()) or _G
		for _, k in ipairs({ "__pnpV1CdConn", "__pnpV1ZoneConn" }) do
			if g[k] then pcall(function() g[k]:Disconnect() end) end
			g[k] = nil
		end
		if PetCooldownsUpdated then
			g.__pnpV1CdConn = PetCooldownsUpdated.OnClientEvent:Connect(function(uuid, cdTable)
				if type(uuid) == "string" then onCd(uuid, cdTable) end
			end)
		end
		if PetZoneAbility then
			g.__pnpV1ZoneConn = PetZoneAbility.OnClientEvent:Connect(onZone)
		end
	end

	local function pollCd(uuid)
		local ok, cd = pcall(function() return GetPetCooldown:InvokeServer(uuid) end)
		if ok then onCd(uuid, cd) end
	end

	-------------------------------------------------------------- data helpers
	local function getData()
		local ok, d = pcall(function() return DataService:GetData() end)
		return ok and d or nil
	end

	local function equippedSet()
		local d = getData()
		local set = {}
		local eq = d and d.PetsData and d.PetsData.EquippedPets
		if eq then for _, u in ipairs(eq) do set[u] = true end end
		return set
	end

	local function isTarget(uuid)
		local sel = CFG.pnpUuids or {}
		return (not next(sel)) or sel[uuid] == true
	end

	local function targetPets()
		local out = {}
		local d = getData()
		local eq = d and d.PetsData and d.PetsData.EquippedPets
		if not eq then return out end
		local inv = d.PetsData.PetInventory and d.PetsData.PetInventory.Data
		for _, uuid in ipairs(eq) do
			if isTarget(uuid) then
				out[#out + 1] = { uuid = uuid, petType = inv and inv[uuid] and inv[uuid].PetType }
			end
		end
		return out
	end

	-- daftar pet dari INVENTORY buat dropdown Select Pets (SHARED: dipakai V1 & V2).
	function ctx.inventoryPetOptions(selectedSet)
		local out = {}
		local d = getData()
		if not d then return out end
		local inv = d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data
		if not inv then return out end
		local eq = d.PetsData.EquippedPets or {}
		local eqSet = {}; for _, u in ipairs(eq) do eqSet[u] = true end
		for uuid, v in pairs(inv) do
			local pt = v.PetType or "?"
			local pd = v.PetData or {}
			local age = pd.Level or 0
			local mut = pd.MutationType
			local mutName = mut
			if mut and ctx.reg and ctx.reg.mutDisplay then mutName = ctx.reg.mutDisplay(mut) end
			local mutPrefix = (mut and mut ~= "" and mut ~= "Normal") and (tostring(mutName) .. " ") or ""
			local weight = (pd.BaseWeight or 0) * (1 + 0.1 * age)
			local tag = eqSet[uuid] and " [aktif]" or ""
			out[#out + 1] = {
				value = uuid,
				display = ("%s%s | %.2f KG | Age %s | #%s%s"):format(mutPrefix, pt, weight, tostring(age), uuid:sub(2, 5), tag),
			}
		end
		if selectedSet and next(inv) then
			local valid = {}
			for uuid in pairs(inv) do valid[uuid] = true end
			local changed = false
			for u in pairs(selectedSet) do
				if not valid[u] then selectedSet[u] = nil; changed = true end
			end
			if changed and ctx.persistState then ctx.persistState() end
		end
		table.sort(out, function(a, b)
			local selA = selectedSet and selectedSet[a.value] and 1 or 0
			local selB = selectedSet and selectedSet[b.value] and 1 or 0
			if selA ~= selB then return selA > selB end
			return a.display < b.display
		end)
		return out
	end

	local GetFarm = require(RS.Modules.GetFarm)
	local function placePos()
		local farm = GetFarm and GetFarm(LP)
		local pa = farm and farm:FindFirstChild("PetArea")
		if pa then return pa.Position end
		local char = LP.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		return hrp and hrp.Position or nil
	end

	-------------------------------------------------------------- pickup & place
	local function alive(myId)
		return CFG.pnpEnabled and ctx.alive() and ctx.state.pnpV1Id == myId
	end

	-- return true kalau pet sukses balik ke kebun. Pet WAJIB dicoba balik walau PnP dimatiin.
	local function doPnp(uuid)
		local pos = placePos()
		fireAt[uuid], waitZone[uuid] = nil, nil
		if not pos then return true end
		busy[uuid] = true

		local tU = os.clock()
		pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
		repeat task.wait(0.02) until (lastEmpty[uuid] or 0) >= tU or os.clock() - tU > UNEQUIP_ACK
		if EQUIP_DELAY > 0.001 then task.wait(EQUIP_DELAY) end

		local placed = false
		for _ = 1, EQUIP_RETRIES do
			local tE = os.clock()
			pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
			repeat task.wait(0.05) until (lastValid[uuid] or 0) > tE or os.clock() - tE > VERIFY_WAIT
			if (lastValid[uuid] or 0) > tE or equippedSet()[uuid] then placed = true; break end
		end

		prevCd[uuid] = nil
		ignoreUntil[uuid] = os.clock() + PLACE_GRACE
		busy[uuid] = nil
		return placed
	end

	local petThreads = {}
	local function runPetThread(uuid, myId)
		petThreads[uuid] = true
		local lastPoll, polling, lastEqCheck = 0, false, 0
		while alive(myId) do
			local now = os.clock()
			if now - lastEqCheck > 0.5 then
				lastEqCheck = now
				if not isTarget(uuid) or not equippedSet()[uuid] then break end
			end

			if waitZone[uuid] and now >= waitZone[uuid] then
				waitZone[uuid] = nil
				schedule(uuid, "CD0")
			end

			if fireAt[uuid] and now >= fireAt[uuid] then
				local why = fireReason[uuid] or "?"
				if doPnp(uuid) then
					setStatus(("PNP V1: #%s ditarik (%s)"):format(uuid:sub(2, 5), why))
				else
					setStatus("PNP V1: gagal place ulang pet #" .. uuid:sub(2, 5) .. " (cek backpack)")
					break
				end
				lastEqCheck = os.clock() -- DataService telat update abis place
			elseif not polling and now - lastPoll >= SCAN_INTERVAL then
				lastPoll, polling = now, true
				task.spawn(function() pollCd(uuid); polling = false end)
			end
			task.wait(0.03)
		end
		fireAt[uuid], waitZone[uuid], prevCd[uuid] = nil, nil, nil
		petThreads[uuid] = nil
	end

	local function pnpLoop()
		ctx.state.pnpV1Id = (ctx.state.pnpV1Id or 0) + 1
		local myId = ctx.state.pnpV1Id
		ctx.elevate()
		while alive(myId) do
			local pets = targetPets()
			if #pets == 0 then
				setStatus("PNP V1: tidak ada pet target (equip pet dulu)")
			else
				for _, p in ipairs(pets) do
					if not petThreads[p.uuid] then task.spawn(runPetThread, p.uuid, myId) end
				end
			end
			task.wait(1)
		end
	end

	function ctx.startPnpV1() task.spawn(pnpLoop) end
	function ctx.stopPnpV1() ctx.state.pnpV1Id = (ctx.state.pnpV1Id or 0) + 1 end

	-- Tombol "Force Pickup Now": tarik + place ulang semua pet target sekarang (abaikan cd).
	function ctx.forcePickupPets()
		local pets = targetPets()
		for _, p in ipairs(pets) do
			if not busy[p.uuid] then task.spawn(doPnp, p.uuid) end
		end
		return #pets
	end
end
]=],
	["modules/shop/automation_merchant.lua"] = [=[
--[[ automation_merchant.lua — Auto Buy Merchant (Traveling Merchant + Event/Night Shop).

     DUA jenis shop, disatuin di UI/loop yang sama:

     1) TRAVELING MERCHANT (kind "travel") — cuma 1 aktif per waktu.
          Katalog: TravelingMerchantData[MerchantType].ShopData
          Stok:    data.TravelingMerchantShopStock.Stocks[itemName].Stock
          Beli:    BuyTravelingMerchantShopStock:FireServer(itemName)               (sheckles)
          MerchantType di-canon-kan (dua "4th July" -> satu "American").

     2) EVENT / NIGHT SHOP (kind "event") — mis. Twilight Shop, Blood Moon Shop.
          Katalog: EventShopData[shopName]
          Stok:    data.EventShopStock[shopName].Stocks[itemName].Stock
          Beli:    BuyEventShopStock:FireServer(itemName, shopName)                 (sheckles)
          Ga perlu UI kebuka — remote diterima langsung selama shop lagi aktif.

     Item terpilih disimpan PER-ENTRI: CFG.merchantItems[id] = { [itemName]=true }.
     Toggle auto-buy (bisa nyala barengan, target di-UNION):
       merchantBuyEnabled -> beli item terpilih utk entri yang lagi ada stok
       merchantBuyAll     -> beli SEMUA item yang ada stock
       merchantBuyBest    -> beli 1 item TERMAHAL yang ada stock (per entri)
     Beli dipicu saat marker restock per-shop berubah, sama pola kayak Buy Seed. ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local CFG = ctx.CFG
	local RS = game:GetService("ReplicatedStorage")
	local GE = RS:WaitForChild("GameEvents")
	local BuyMerchant  = GE:WaitForChild("BuyTravelingMerchantShopStock")
	local BuyEventShop = GE:WaitForChild("BuyEventShopStock")
	local MerchantData = require(RS.Data.TravelingMerchant.TravelingMerchantData)
	local EventShopData = require(RS.Data.EventShopData)
	local EventShopUI = (function() local ok, m = pcall(function() return require(RS.Modules.EventShopUIController) end); return ok and m or nil end)()
	local UpdateService = (function() local ok, m = pcall(function() return require(RS.Modules.UpdateService) end); return ok and m or nil end)()
	local function setStatus(s) ctx.setStatus(s) end

	-- Event shop yang punya katalog di EventShopData (urutan tetap; UI-nya bisa dibuka).
	local KNOWN_EVENT = {
		"Twilight Shop", "Blood Moon Shop", "Summer Seed Shop", "Tide Token Shop",
		"Honey Coin Shop", "Honey Seed Shop", "Royal Jelly Shop", "Moon Coin Shop",
		"Easter Seed Shop", "Fall Market Seed Shop", "Fall Market Gear Shop",
		"Fall Market Pet Shop", "Fall Market Cosmetic Shop", "Goliath's Goods",
		"Goliath's Friends Deals",
	}

	-- Traveling merchant yang di-gabung jadi 1 entri UI (id canonical + judul rapih).
	local MERGE = {
		["American Traveling Merchant"]      = { id = "American", title = "American" },
		["American Traveling Merchant 2026"] = { id = "American", title = "American" },
	}
	local function canonId(mt) local m = MERGE[mt]; return m and m.id or mt end
	local function keysOf(id) -- id canonical -> daftar merchantType yang tercakup
		local ks = {}
		for key in pairs(MerchantData) do
			if canonId(key) == id then ks[#ks + 1] = key end
		end
		return ks
	end

	local function getData()
		local ok, d = pcall(function() return DataService:GetData() end)
		return ok and d or nil
	end

	-- Katalog + info traveling merchant yang AKTIF. return shopData, merchantType, merchantStock
	local function activeShop(d)
		d = d or getData()
		local ms = d and d.TravelingMerchantShopStock
		local mt = ms and ms.MerchantType
		if not mt or not MerchantData[mt] then return nil, nil, ms end
		return MerchantData[mt].ShopData, mt, ms
	end

	-- id ini traveling merchant? (kalau bukan -> dianggap event shop)
	local function isTravelId(id)
		for k in pairs(MerchantData) do if canonId(k) == id then return true end end
		return false
	end

	-- Semua event shop: KNOWN_EVENT dulu (urut), lalu shop lain yang ADA di EventShopStock
	-- (event lama/musiman yang katalognya ga di EventShopData -> tetap kebawa).
	local function allEventShops(d)
		local out, seen = {}, {}
		for _, s in ipairs(KNOWN_EVENT) do if not seen[s] then seen[s] = true; out[#out + 1] = s end end
		local ess = (d or getData()) and (d or getData()).EventShopStock
		local extra = {}
		if type(ess) == "table" then
			for shop, v in pairs(ess) do
				if shop ~= "" and type(v) == "table" and v.Stocks and not seen[shop] then
					seen[shop] = true; extra[#extra + 1] = shop
				end
			end
		end
		table.sort(extra)
		for _, s in ipairs(extra) do out[#out + 1] = s end
		return out
	end

	-- Katalog event shop: EventShopData kalau ada; else fallback dari stok live (tanpa harga).
	local function eventCatalog(shopName, d)
		local cat = EventShopData[shopName]
		if cat then return cat end
		local ess = (d or getData()) and (d or getData()).EventShopStock
		local s = ess and ess[shopName]
		local out = {}
		if s and type(s.Stocks) == "table" then
			for item in pairs(s.Stocks) do out[item] = { Price = 0, DisplayInShop = true } end
		end
		return out
	end

	-- Tampilkan SEMUA item yang di-display shop (TANPA filter harga). Item mahal (Price >= 1e9
	-- kayak Gnome, Pet Shard, Red Panda dll) itu harga Sheckle valid, dibeli via remote;
	-- PurchaseID/FallbackPrice cuma opsi Robux. Cuma skip DisplayInShop==false (disembunyiin game).
	local function isBuyable(v)
		return type(v) == "table" and v.DisplayInShop ~= false
	end

	-- Entri punya minimal 1 item yang bisa dibeli? (kalau ga ada, entri disembunyiin dari list)
	local function hasShecklesShop(shop)
		if type(shop) ~= "table" then return false end
		for _, v in pairs(shop) do
			if type(v) == "table" and v.DisplayInShop ~= false and isBuyable(v) then return true end
		end
		return false
	end
	local function entryHasSheckles(id, kind)
		if kind == "travel" then
			for _, key in ipairs(keysOf(id)) do
				if hasShecklesShop(MerchantData[key] and MerchantData[key].ShopData) then return true end
			end
			return false
		end
		return hasShecklesShop(eventCatalog(id))
	end

	----------------------------------------------------------------- opsi UI
	-- Daftar entri buat UI (traveling dulu diurut by title, lalu event shop).
	-- Cuma entri yang punya item beli-pakai-sheckles yang ditampilin.
	function ctx.getMerchantList()
		local out, seenId = {}, {}
		for key, m in pairs(MerchantData) do
			local id = canonId(key)
			if not seenId[id] and entryHasSheckles(id, "travel") then
				seenId[id] = true
				out[#out + 1] = { id = id, title = (MERGE[key] and MERGE[key].title) or m.Title or id, kind = "travel" }
			end
		end
		table.sort(out, function(a, b) return a.title < b.title end)
		for _, shopName in ipairs(allEventShops()) do
			if entryHasSheckles(shopName, "event") then
				out[#out + 1] = { id = shopName, title = shopName, kind = "event" }
			end
		end
		return out
	end

	-- Opsi item utk SATU entri (union katalog; item habis tetap tampil).
	function ctx.getMerchantItemOptions(id)
		local out = { { value = "All", display = "All (semua item)" } }
		local names, seen = {}, {}
		local function addFrom(shop)
			if not shop then return end
			for name, v in pairs(shop) do
				if v.DisplayInShop ~= false and isBuyable(v) and not seen[name] then
					seen[name] = true; names[#names + 1] = name
				end
			end
		end
		if isTravelId(id) then
			for _, key in ipairs(keysOf(id)) do addFrom(MerchantData[key] and MerchantData[key].ShopData) end
		else
			addFrom(eventCatalog(id))
		end
		table.sort(names)
		for _, n in ipairs(names) do out[#out + 1] = { value = n, display = n } end
		return out
	end

	-- Set selection utk entri (di-key pakai id).
	function ctx.merchantSelFor(id)
		CFG.merchantItems = CFG.merchantItems or {}
		CFG.merchantItems[id] = CFG.merchantItems[id] or {}
		return CFG.merchantItems[id]
	end

	-- Ada toggle auto-buy yang aktif? (master on/off buat loop)
	local function anyOn()
		return CFG.merchantBuyEnabled or CFG.merchantBuyAll or CFG.merchantBuyBest or false
	end
	ctx.merchantAnyOn = anyOn

	-- Ringkasan buat status live di UI: fokus ke ITEM yang dipilih buat dibeli per shop.
	-- res = { activeMerchant=<nama traveling aktif|nil>, mode="all"|"best"|nil,
	--         picks = { {title=, kind=, items={...}} ... } }  -- entri yang punya pilihan
	function ctx.getMerchantSummary()
		local d = getData()
		local _, mt = activeShop(d)
		local res = {
			activeMerchant = mt and (MerchantData[mt].Title or mt) or nil,
			mode = CFG.merchantBuyAll and "all" or (CFG.merchantBuyBest and "best") or nil,
			picks = {},
		}
		-- Kalau mode global (All/Best) nyala, item pilihan ga relevan.
		if res.mode then return res end
		-- Katalog gabungan buat 1 entri (buat ambil harga sheckles).
		local function catalogOf(id, kind)
			local cat = {}
			if kind == "travel" then
				for _, key in ipairs(keysOf(id)) do
					local sd = MerchantData[key] and MerchantData[key].ShopData
					if sd then for n, v in pairs(sd) do cat[n] = v end end
				end
			else
				cat = eventCatalog(id, d)
			end
			return cat
		end
		for _, m in ipairs(ctx.getMerchantList()) do
			local sel = (CFG.merchantItems and CFG.merchantItems[m.id]) or {}
			local cat = catalogOf(m.id, m.kind)
			local items = {}
			if sel["All"] then
				items = { { name = "All", price = nil } }
			else
				local names = {}
				for name, on in pairs(sel) do if on then names[#names + 1] = name end end
				table.sort(names)
				for _, name in ipairs(names) do
					local v = cat[name]
					items[#items + 1] = { name = name, price = v and v.Price or nil }
				end
			end
			if #items > 0 then
				res.picks[#res.picks + 1] = { title = m.title, kind = m.kind, items = items }
			end
		end
		return res
	end

	----------------------------------------------------------------- pilih target
	-- Toggle bisa nyala barengan; target-nya di-UNION (item ga dobel).
	-- stockOf(name) -> jumlah stock; selKey -> id buat CFG.merchantItems.
	local function pickTargets(catalog, stockOf, selKey)
		local targets, added = {}, {}
		local function add(name, s, price)
			if not added[name] then added[name] = true; targets[#targets + 1] = { name = name, stock = s, price = price } end
		end

		local buyAll   = CFG.merchantBuyAll
		local buySel   = CFG.merchantBuyEnabled
		local buyBest  = CFG.merchantBuyBest
		local sel = (CFG.merchantItems and CFG.merchantItems[selKey]) or {}
		local all = sel["All"]

		local bestName, bestPrice, bestStock = nil, -1, 0
		for name, v in pairs(catalog) do
			if v.DisplayInShop ~= false and isBuyable(v) then
				local s = stockOf(name)
				if s > 0 then
					local price = v.Price or 0
					if buyAll then
						add(name, s, price)
					else
						if buySel and (all or sel[name]) then add(name, s, price) end
					end
					if buyBest and price > bestPrice then bestName, bestPrice, bestStock = name, price, s end
				end
			end
		end
		if buyBest and bestName then add(bestName, bestStock, bestPrice) end
		return targets
	end

	----------------------------------------------------------------- loop beli
	local POLL = 2
	local function buyLoop()
		ctx.state.merchantId = (ctx.state.merchantId or 0) + 1
		local myId = ctx.state.merchantId
		ctx.elevate()
		local lastMarker = {} -- per-source: [srcKey] = markerVal

		-- Proses 1 source: beli target-nya kalau marker restock berubah. return jumlah beli.
		local function processSource(srcKey, marker, catalog, stockOf, selKey, buyFn)
			if lastMarker[srcKey] == marker then return nil end -- belum restock -> skip
			lastMarker[srcKey] = marker
			local targets = pickTargets(catalog, stockOf, selKey)
			local bought = 0
			for _, t in ipairs(targets) do
				for _ = 1, t.stock do
					if not anyOn() or ctx.state.merchantId ~= myId then break end
					pcall(buyFn, t.name)
					bought = bought + 1
					task.wait(0.15)
				end
			end
			return bought
		end

		while anyOn() and ctx.alive() and ctx.state.merchantId == myId do
			local d = getData()
			local acted = {}

			-- (1) Traveling merchant aktif
			local shop, mt, ms = activeShop(d)
			if mt then
				local marker = "travel|" .. tostring(mt) .. "|" .. tostring(ms.MerchantStartTime)
				local stocks = ms.Stocks or {}
				local bought = processSource("travel", marker, shop,
					function(n) return stocks[n] and stocks[n].Stock or 0 end,
					canonId(mt),
					function(n) BuyMerchant:FireServer(n) end)
				if bought then acted[#acted + 1] = ("%s:%d"):format(MerchantData[mt].Title or mt, bought) end
			else
				lastMarker["travel"] = nil -- reset biar pas merchant muncul langsung beli
			end

			-- (2) Event / night shop (Twilight, Blood Moon, event lama, ...)
			local ess = d and d.EventShopStock
			for _, shopName in ipairs(allEventShops(d)) do
				local s = ess and ess[shopName]
				local stocks = s and s.Stocks
				local catalog = eventCatalog(shopName, d)
				if stocks and catalog and next(catalog) then
					local marker = "event|" .. shopName .. "|" .. tostring(s.ShopSeed)
					local bought = processSource("event:" .. shopName, marker, catalog,
						function(n) return stocks[n] and stocks[n].Stock or 0 end,
						shopName,
						function(n) BuyEventShop:FireServer(n, shopName) end)
					if bought then acted[#acted + 1] = ("%s:%d"):format(shopName, bought) end
				else
					lastMarker["event:" .. shopName] = nil
				end
			end

			if #acted > 0 then
				setStatus("Merchant beli -> " .. table.concat(acted, ", "))
			else
				setStatus("Merchant: nunggu restock / merchant muncul")
			end
			task.wait(POLL)
		end
		setStatus("Merchant: idle")
	end

	function ctx.startBuyMerchant() task.spawn(buyLoop) end

	----------------------------------------------------------------- Open Shop UI
	-- Daftar shop buat dropdown "Merchant UI to Open" (event shop yang punya UI controller).
	function ctx.getEventShopOptions()
		local out = {}
		for _, s in ipairs(KNOWN_EVENT) do out[#out + 1] = { name = s, display = s } end
		return out
	end
	function ctx.getMerchantUiDisplay()
		return (CFG.merchantUiShop ~= nil and CFG.merchantUiShop ~= "") and CFG.merchantUiShop or "Select"
	end

	-- Nama ScreenGui event shop = shopName tanpa spasi + "EventShop_UI" (mis. "TwilightShopEventShop_UI").
	local function uiGuiName(shopName) return (shopName:gsub("%s+", "")) .. "EventShop_UI" end
	local function isUiOpen(shopName)
		local pg = ctx.LP and ctx.LP.PlayerGui
		local g = pg and pg:FindFirstChild(uiGuiName(shopName))
		return g and g.Enabled == true
	end
	local function shopActive(shopName)
		if not UpdateService then return true end
		local ok, r = pcall(function() return UpdateService:IsActive(shopName) end)
		return ok and r or false
	end

	-- Buka UI shop 1x (kalau shop aktif). return true kalau kebuka.
	function ctx.openEventShopUI(shopName)
		shopName = shopName or CFG.merchantUiShop
		if not shopName or shopName == "" or not EventShopUI then return false end
		if not shopActive(shopName) then
			setStatus(("Open UI: %s belum aktif"):format(shopName))
			return false
		end
		pcall(function() EventShopUI:Open(shopName) end)
		return true
	end

	-- Auto Open UI: jaga UI shop terpilih tetap kebuka (buka ulang kalau ke-close & shop aktif).
	local function autoOpenLoop()
		ctx.state.merchantUiId = (ctx.state.merchantUiId or 0) + 1
		local myId = ctx.state.merchantUiId
		while CFG.merchantAutoOpenUI and ctx.alive() and ctx.state.merchantUiId == myId do
			local shop = CFG.merchantUiShop
			if shop and shop ~= "" and EventShopUI then
				if shopActive(shop) then
					if not isUiOpen(shop) then pcall(function() EventShopUI:Open(shop) end) end
				end
			end
			task.wait(2)
		end
	end
	function ctx.startAutoOpenUI() task.spawn(autoOpenLoop) end
	function ctx.stopAutoOpenUI() ctx.state.merchantUiId = (ctx.state.merchantUiId or 0) + 1 end
end
]=],
	["modules/shop/automation_shop.lua"] = [=[
--[[ shop.lua — Automation Buy Seed / Egg / Gear.
     Opsi dropdown diambil dari REGISTRY katalog shop (bukan stock), jadi semua
     item tampil walau lagi habis; item baru dari update game auto masuk.
       Seed -> SeedShopData
       Gear -> GearShopData.Gear
       Egg  -> PetEggData
     Ada opsi "All" = beli semua yang lagi ada stock.
     Remote:
       BuySeedStock:FireServer("Shop", seedName)
       BuyGearStock:FireServer(gearName)
       BuyPetEgg:FireServer(eggIndex) ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local CFG = ctx.CFG
	local RS = game:GetService("ReplicatedStorage")
	local GE = RS:WaitForChild("GameEvents")
	local BuySeedStock = GE:WaitForChild("BuySeedStock")
	local BuyGearStock = GE:WaitForChild("BuyGearStock")
	local BuyPetEgg    = GE:WaitForChild("BuyPetEgg")
	local function setStatus(s) ctx.setStatus(s) end

	local function getData()
		local ok, d = pcall(function() return DataService:GetData() end)
		return ok and d or nil
	end

	-- Ambil daftar nama dari registry katalog; buang key non-item (RefreshTime, Gear).
	local function catalogNames(getTbl)
		local ok, t = pcall(getTbl)
		local out = {}
		if ok and type(t) == "table" then
			for k in pairs(t) do
				local n = tostring(k)
				if n ~= "RefreshTime" and n ~= "Gear" then out[#out + 1] = n end
			end
			table.sort(out)
		end
		return out
	end

	local function optionsFrom(names, sel)
		local out = { { value = "All", display = "All (beli semua)" } }
		for _, n in ipairs(names) do out[#out + 1] = { value = n, display = n } end
		return out
	end

	function ctx.getSeedShopOptions(sel)
		return optionsFrom(catalogNames(function() return require(RS.Data.SeedShopData) end), sel)
	end
	function ctx.getGearShopOptions(sel)
		return optionsFrom(catalogNames(function() return require(RS.Data.GearShopData).Gear end), sel)
	end
	function ctx.getEggShopOptions(sel)
		return optionsFrom(catalogNames(function() return require(RS.Data.PetEggData) end), sel)
	end

	----------------------------------------------------------------- loop beli
	-- Poll = cek marker restock (cuma BACA, bukan beli -> murah, ga lag).
	-- Beli tetap hanya saat marker berubah (restock). 2s biar deteksi cepat (minim miss).
	local POLL = 2

	local function buySeedLoop()
		ctx.state.buySeedId = (ctx.state.buySeedId or 0) + 1
		local myId = ctx.state.buySeedId
		ctx.elevate()
		local lastMarker
		while CFG.buySeedEnabled and ctx.alive() and ctx.state.buySeedId == myId do
			local d = getData()
			-- Game mindahin stok seed ke d.SeedStocks.Shop (d.SeedStock singular udah BEKU:
			-- markernya ga update lagi -> loop lama cuma beli sekali terus stuck "nunggu restock").
			-- Prefer path baru; fallback ke singular biar aman kalau server balikin lagi.
			local shop = d and ((d.SeedStocks and d.SeedStocks.Shop) or d.SeedStock)
			local marker = shop and shop.Seed
			if marker ~= lastMarker then -- restock baru (atau pertama jalan) -> beli
				lastMarker = marker
				local st = shop and shop.Stocks or {}
				local sel = CFG.buySeedNames or {}
				local all = sel["All"]
				local bought = 0
				for name, v in pairs(st) do
					if all or sel[name] then
						local stock = type(v) == "table" and v.Stock or 0
						for _ = 1, stock do
							if not CFG.buySeedEnabled or ctx.state.buySeedId ~= myId then break end
							pcall(function() BuySeedStock:FireServer("Shop", name) end)
							bought = bought + 1; task.wait(0.15)
						end
					end
				end
				setStatus(("Buy Seed: restock -> beli %d"):format(bought))
			else
				setStatus("Buy Seed: nunggu restock")
			end
			task.wait(POLL)
		end
	end

	local function buyGearLoop()
		ctx.state.buyGearId = (ctx.state.buyGearId or 0) + 1
		local myId = ctx.state.buyGearId
		ctx.elevate()
		local lastMarker
		while CFG.buyGearEnabled and ctx.alive() and ctx.state.buyGearId == myId do
			local d = getData()
			local marker = d and d.GearStock and d.GearStock.Gear
			if marker ~= lastMarker then
				lastMarker = marker
				local st = d and d.GearStock and d.GearStock.Stocks or {}
				local sel = CFG.buyGearNames or {}
				local all = sel["All"]
				local bought = 0
				for name, v in pairs(st) do
					if all or sel[name] then
						local stock = type(v) == "table" and v.Stock or 0
						for _ = 1, stock do
							if not CFG.buyGearEnabled or ctx.state.buyGearId ~= myId then break end
							pcall(function() BuyGearStock:FireServer(name) end)
							bought = bought + 1; task.wait(0.15)
						end
					end
				end
				setStatus(("Buy Gear: restock -> beli %d"):format(bought))
			else
				setStatus("Buy Gear: nunggu restock")
			end
			task.wait(POLL)
		end
	end

	local function buyEggLoop()
		ctx.state.buyEggId = (ctx.state.buyEggId or 0) + 1
		local myId = ctx.state.buyEggId
		ctx.elevate()
		local lastMarker
		while CFG.buyEggEnabled and ctx.alive() and ctx.state.buyEggId == myId do
			local d = getData()
			local marker = d and d.PetEggStock and d.PetEggStock.Egg
			if marker ~= lastMarker then
				lastMarker = marker
				local st = d and d.PetEggStock and d.PetEggStock.Stocks or {}
				local sel = CFG.buyEggNames or {}
				local all = sel["All"]
				local bought = 0
				for index, v in pairs(st) do
					local nm = type(v) == "table" and v.EggName
					local stock = type(v) == "table" and v.Stock or 0
					if nm and (all or sel[nm]) then
						for _ = 1, stock do
							if not CFG.buyEggEnabled or ctx.state.buyEggId ~= myId then break end
							pcall(function() BuyPetEgg:FireServer(index) end)
							bought = bought + 1; task.wait(0.15)
						end
					end
				end
				setStatus(("Buy Egg: restock -> beli %d"):format(bought))
			else
				setStatus("Buy Egg: nunggu restock")
			end
			task.wait(POLL)
		end
	end

	function ctx.startBuySeed() task.spawn(buySeedLoop) end
	function ctx.startBuyGear() task.spawn(buyGearLoop) end
	function ctx.startBuyEgg() task.spawn(buyEggLoop) end
end
]=],
	["modules/shop/premium_shop.lua"] = [=[
--[[ premium_shop.lua — Premium Shop beli via Robux atau Token.
     Sumber katalog: RS.Data.GiftData (sama seperti sc lain, ~394 item, live).
       tiap entry: { Display, NormalId (beli sendiri), GiftId (gift ke player) }.
     Beli:
       Token : GameEvents.TradeEvents.TradeTokens.Purchase:InvokeServer(id)
       Robux : MarketController:PromptPurchaseRobux(id, Enum.InfoType.Product)
     Gift  : pakai GiftId (game handle penerima). ]]
return function(ctx)
	local RS  = game:GetService("ReplicatedStorage")
	local MPS = game:GetService("MarketplaceService")
	local LP  = ctx.LP
	local CFG = ctx.CFG

	local MC; pcall(function() MC = require(RS.Modules.MarketController) end)
	local function giftData()
		local ok, d = pcall(function() return require(RS.Data.GiftData) end)
		return ok and d or {}
	end
	local function ttFolder()
		local ge = RS:FindFirstChild("GameEvents")
		local te = ge and ge:FindFirstChild("TradeEvents")
		return te and te:FindFirstChild("TradeTokens")
	end

	-- entry katalog berdasarkan key CFG.premiumItem.
	local function entryOf(key)
		local d = giftData()
		return key and d[key] or nil
	end

	------------------------------------------------------------- harga (Robux)
	-- Harga token dinamis (RAP), susah/ga stabil -> tampilkan harga Robux dari
	-- GetProductInfo. Di-cache; prefetch pelan di background (hindari rate limit).
	-- id -> number (harga) | false (id ga valid / ga dijual Robux) | nil (belum kebaca)
	-- PENTING: kegagalan karena throttle TIDAK di-cache (biar dicoba lagi), cuma
	-- id==0 / hasil valid-tanpa-harga yg di-cache false permanen.
	-- Cache disimpan di getgenv() biar SELAMAT dari reload script (dalam sesi/
	-- server yg sama) -> reload berikutnya 0 panggilan, harga langsung muncul.
	local priceCache = (getgenv and (getgenv().__AH_PREM_PRICE or (function() getgenv().__AH_PREM_PRICE = {}; return getgenv().__AH_PREM_PRICE end)())) or {}
	-- Tabel harga STATIS (id -> PriceInRobux), di-fetch sekali & ditempel di sini
	-- (kayak shop lain) -> instan selamanya, 0 panggilan walau reload/rejoin.
	-- Nilai 99999/999999999 = penanda off-sale dari game, sengaja tetap disimpan.
	-- Live-fetch tetap jalan buat id yg belum ada di sini (item/harga baru).
	local PRICE = {
		[3248690960]=19,[3248692171]=3,[3248692845]=55,[3248695199]=85,[3248695947]=21,[3248696942]=35,[3248697546]=80,[3248716238]=150,[3248744789]=175,[3249981764]=639,[3250137172]=49,[3250137261]=99,[3250137355]=325,[3250139018]=895,[3253012192]=240,[3259333414]=235,[3260229242]=39,
		[3260940714]=200,[3261009117]=99,[3265889601]=79,[3265889751]=99,[3265889948]=149,[3265927408]=6,[3265927978]=8,[3267528421]=999999999,[3267548052]=999999999,[3267548161]=999999999,[3267580365]=79,[3269001250]=459,[3273005969]=40900,[3273006109]=459,[3273679012]=999999999,[3273973729]=249,[3276346455]=19,[3276346509]=39,[3276346557]=89,[3276346676]=129,
		[3277000452]=149,[3277675404]=255,[3277814538]=575,[3277814625]=1699,[3278426597]=99999,[3281679093]=119,[3282157312]=999999999,[3282157462]=999999999,[3282870834]=205,[3282918403]=59,[3284390402]=715,[3286038236]=149,[3286560171]=119,[3290672626]=199,[3290672712]=575,[3290672848]=1699,[3295548770]=999999999,[3295548781]=1699,[3295548782]=999999999,[3300962946]=8000,
		[3300962950]=8000,[3300962952]=8000,[3300984139]=315,[3301473650]=39,[3301567955]=429,[3301567958]=149,[3301567960]=999999999,[3304968889]=329,[3306352279]=999999999,[3306352283]=999999999,[3306352284]=999999999,[3306767043]=139,[3311112163]=399,[3311388942]=999999999,[3311388948]=999999999,[3311388951]=999999999,[3312005774]=475,[3312007044]=135,[3312008833]=399,[3312011056]=419,
		[3312011732]=529,[3312012483]=589,[3312013208]=599,[3312013874]=679,[3312014286]=629,[3316261725]=99,[3316826714]=280,[3317459182]=99999,[3317459186]=99999,[3317459188]=999999999,[3317729900]=215,[3317730202]=715,[3323657547]=575,[3323657552]=999999999,[3323657553]=999999999,[3329526686]=189,[3329527365]=119,[3329528135]=35,[3330286148]=999999999,[3330286154]=99999,
		[3330286155]=99999,[3330562080]=929,[3338826790]=999999999,[3338826791]=999999999,[3338826792]=999999999,[3345148119]=385,[3345819463]=99999,[3345819470]=999999999,[3345819472]=999999999,[3352931398]=19,[3354130076]=115,[3354839803]=999999999,[3354839817]=999999999,[3354839826]=999999999,[3362680911]=999999999,[3362680916]=999999999,[3362680917]=999999999,[3371226353]=999999999,[3371226360]=999999999,[3371226363]=999999999,
		[3372004188]=395,[3379038152]=999999999,[3379038157]=999999999,[3379038159]=999999999,[3379245220]=139,[3379593726]=99999999,[3387753634]=999999999,[3387753638]=999999999,[3387753641]=199,[3388359799]=939,[3388360759]=897,[3388363071]=768,[3388363390]=839,[3394224231]=999999999,[3394224237]=999999999,[3394224239]=999999999,[3401426983]=149,[3401426984]=1249,[3401426985]=429,[3407391662]=199,
		[3407391663]=575,[3407391666]=1699,[3411693833]=749,[3414035789]=369,[3414586855]=149,[3420021043]=575,[3420021044]=1699,[3420021045]=199,[3426542757]=479,[3427163853]=9999999,[3427163854]=999999999,[3427163857]=999999,[3432380384]=399,[3438653517]=1699,[3438653518]=575,[3438653519]=199,[3444449485]=9999999,[3444449486]=9999999,[3444449487]=9999999,[3445155701]=6,
		[3445164189]=479,[3445262332]=530,[3449810469]=199,[3449810471]=1699,[3449810472]=575,[3455804869]=279,[3456989527]=150,[3460376533]=50,[3460378135]=250,[3460378800]=1000,[3460379424]=5000,[3460379831]=25000,[3460380041]=149,[3460380235]=149,[3460600736]=1699,
		[3460600737]=575,[3460600740]=199,[3461239818]=595,[3467103687]=1249,[3467103688]=429,[3467110142]=429,[3467110145]=1249,[3471911127]=1627,[3472461575]=625,[3472461579]=1899,[3472461584]=7450,[3472461585]=219,[3477922697]=429,[3477922698]=149,[3477922700]=1249,[3478031738]=149,[3478031853]=429,[3478031941]=1249,[3478043835]=4999,[3482199602]=79,
		[3482199918]=230,[3482200241]=679,[3482271454]=1799,[3482980939]=679,[3482982251]=799,[3483801741]=149,[3483801743]=4999,[3483801744]=1249,[3483801745]=429,[3489363338]=429,[3489363342]=1249,[3489363343]=149,[3489363344]=4999,[3490207231]=1299,[3497475839]=149,[3497475843]=4999,[3497475844]=1249,[3497475846]=429,[3498980651]=1799,
		[3512151971]=149,[3512151973]=429,[3512151976]=1249,[3512151977]=4999,[3519865801]=799,[3520430327]=429,[3520430328]=1249,[3520430329]=149,[3520430331]=4999,[3546475721]=1700,[3563674024]=1699,[3568823262]=639,[3568827015]=59,[3568827227]=175,[3568827595]=499,[3570157250]=4999,[3570335691]=6999,[3576524674]=149,[3576524780]=429,[3576524860]=1249,
		[3576525035]=4999,[3584036637]=149,[3584036735]=429,[3584036839]=1249,[3584075576]=639,[3587190661]=4999,[3587239446]=639,[3588292639]=199,[3588293165]=575,[3588293244]=1699,[3588293328]=6999,[3602505965]=149,[3602506028]=429,[3602506064]=1249,[3602506115]=4999,[3602742364]=639,[3603829987]=199,[3603830024]=575,[3603830055]=1699,[3603830077]=6999,
		[3607717721]=59,[3607717736]=175,[3607717758]=499,[3607717778]=1999,[3607717910]=639,[3608858826]=79,[3608858860]=230,[3608858882]=679,[3608858906]=2799,[3610249313]=279,[3611262564]=59,[3611262600]=175,[3611262627]=499,[3612305749]=59,[3612305786]=175,[3612305812]=499,[3612305842]=1999,[3612306093]=639,[3625639161]=79,[3625640337]=230,[3625641435]=679,[3625642643]=2799,[3708088084]=959,
	}
	-- Harga dari MarketplaceService:GetProductInfo(id, Product) — HARUS pakai
	-- InfoType.Product (MC:GetProductInfo cache-nya di-key by id doang, bisa
	-- ketuker sama info Asset). Engine nge-cache hasil per (id,infoType), jadi
	-- id yg udah pernah kefetch (mis. sama shop asli game) balik instan.
	-- RetryPcall manual: throttle ga di-cache -> diulang di pass prefetch berikut.
	local function fetchPrice(id)
		if id == nil or id == 0 then return nil end
		local st = PRICE[id]                     -- tabel statis: instan, 0 panggilan
		if st ~= nil then return st end
		local c = priceCache[id]
		if c ~= nil then return c or nil end
		local ok, info = pcall(function() return MPS:GetProductInfo(id, Enum.InfoType.Product) end)
		if not ok then return nil end           -- throttle/error: jangan cache, coba lagi nanti
		local p = info and info.PriceInRobux
		priceCache[id] = p or false             -- ok tapi ga ada harga = ga dijual Robux
		return p or nil
	end

	local prefetchStarted = false
	-- Prefetch PARALEL (bounded): fetchPrice yield di network, jadi N worker
	-- coroutine bikin ~N request barengan (game aslinya izinin ~36) -> jauh
	-- lebih cepet drpd 1-per-1. Multi-pass buat yg kena throttle (belum ke-cache).
	local WORKERS = 24
	local function startPrefetch(entries)
		if prefetchStarted then return end
		prefetchStarted = true
		task.spawn(function()
			for pass = 1, 6 do
				local idx = 0
				local finished = 0
				for _ = 1, WORKERS do
					task.spawn(function()
						while ctx.alive() do
							idx = idx + 1                 -- coroutine kooperatif: aman antar-yield
							local e = entries[idx]
							if not e then break end
							if e.id ~= 0 and priceCache[e.id] == nil then fetchPrice(e.id) end
						end
						finished = finished + 1
					end)
				end
				while finished < WORKERS and ctx.alive() do task.wait() end
				local remaining = 0
				for _, e in ipairs(entries) do
					if e.id ~= 0 and priceCache[e.id] == nil then remaining = remaining + 1 end
				end
				if remaining == 0 or not ctx.alive() then break end
				task.wait(0.5)                            -- napas sebentar sebelum retry throttle
			end
		end)
	end

	-- prewarm: mulai isi cache harga di background (dipanggil pas hub kebuka),
	-- jadi pas buka Premium Shop harga udah siap. Ringan & ga nge-block.
	function ctx.premiumPrewarm()
		local d = giftData()
		local ids = {}
		for _, v in pairs(d) do
			if type(v) == "table" and v.NormalId and v.NormalId ~= 0 and PRICE[v.NormalId] == nil then
				ids[#ids + 1] = { id = v.NormalId }   -- yg udah di tabel statis ga usah fetch
			end
		end
		startPrefetch(ids)
	end

	-- opsi dropdown item: cuma entry yg BENERAN bisa dibeli (NormalId ~= 0).
	-- Item 0/0 (mis. seed) itu cuma item trade/RAP, ga dijual di shop -> skip.
	-- Display + harga Robux (kalau udah ke-cache). Prefetch jalan di background.
	function ctx.getPremiumItemOptions()
		local d = giftData()
		local out, ids = {}, {}
		for k, v in pairs(d) do
			if type(v) == "table" and v.NormalId and v.NormalId ~= 0 then
				local disp = tostring(v.Display or k)
				local p = PRICE[v.NormalId] or priceCache[v.NormalId]
				if type(p) == "number" then
					disp = disp .. ("  (R$ %d)"):format(p)
				end
				out[#out + 1] = { name = k, display = disp }
				if PRICE[v.NormalId] == nil then ids[#ids + 1] = { id = v.NormalId } end
			end
		end
		table.sort(out, function(a, b) return a.display < b.display end)
		startPrefetch(ids)
		return out
	end
	function ctx.getPremiumPayOptions()
		return { { name = "robux", display = "Robux" }, { name = "token", display = "Token" } }
	end

	-- prompt beli 1 id sesuai payment method (token / robux).
	local function purchaseId(id, label)
		if CFG.premiumPay == "token" then
			local tt = ttFolder()
			if not (tt and tt:FindFirstChild("Purchase")) then ctx.setStatus("Premium Shop: Token remote ga ada"); return end
			local canOk, can = pcall(function() return tt.CanPurchase:InvokeServer(id) end)
			if canOk and can then
				pcall(function() tt.Purchase:InvokeServer(id) end)
				ctx.setStatus("Premium Shop: " .. label .. " via Token…")
			else
				ctx.setStatus("Premium Shop: item ini ga bisa Token, pakai Robux")
			end
		else
			if MC and MC.PromptPurchaseRobux then
				pcall(function() MC:PromptPurchaseRobux(id, Enum.InfoType.Product) end)
			else
				pcall(function() MPS:PromptProductPurchase(LP, id) end)
			end
			ctx.setStatus("Premium Shop: prompt Robux " .. label .. " dibuka")
		end
	end

	-- fetch harga item terpilih & tampilkan di status (dipanggil saat milih item).
	function ctx.premiumShowPrice()
		local e = entryOf(CFG.premiumItem)
		if not (e and e.NormalId) then return end
		local name = tostring(e.Display or CFG.premiumItem)
		local p = fetchPrice(e.NormalId)
		if p then
			ctx.setStatus(("Premium: %s — R$ %d"):format(name, p))
		else
			ctx.setStatus(("Premium: %s"):format(name))
		end
	end

	-- BELI buat diri sendiri (NormalId).
	function ctx.premiumBuy()
		local e = entryOf(CFG.premiumItem)
		if not (e and e.NormalId) then ctx.setStatus("Premium Shop: pilih item dulu"); return end
		purchaseId(e.NormalId, "beli")
	end

	-- GIFT ke player (GiftId). Game yg minta penerima.
	function ctx.premiumGift()
		local e = entryOf(CFG.premiumItem)
		if not (e and e.GiftId) then ctx.setStatus("Premium Shop: item ini ga ada opsi Gift"); return end
		purchaseId(e.GiftId, "gift")
	end
end
]=],
	["ui/pages.lua"] = [=[
--[[ pages.lua — WindUI native, migrasi tab-per-tab.
     Fitur = 100% module dari garden (ctx.start*/stop*, CFG, reg — kontrak sama).
     Tab yang sudah dimigrasi: Pet (pilot). Tab lain = placeholder.
     Kalau mau migrasi tab berikutnya: tulis build<tab>Tab lalu daftar di MIGRATED. ]]
return function(ctx)
	local CFG     = ctx.CFG
	local persist = ctx.persistState
	local reg     = ctx.reg
	local W       = ctx.wi
	local window  = W.window

	----------------------------------------------------------------- helper
	local function safe(fn)
		return function(...)
			local args = { ... }
			local ok, err = pcall(fn, table.unpack(args))
			if not ok then ctx.log("[pages] callback error: " .. tostring(err)) end
		end
	end

	-- Build ATOMIK: tanpa task.wait() di tengah build. Dist pin ukuran Section
	-- dari snapshot Top+Content (10751+) — yield bikin layout jalan pas konten
	-- belum lengkap -> pin stale -> panel kepotong (kasus V2).

	local function makeToggleW(parent, title, desc, getv, setv, notifyTitle)
		local control
		control = parent:Toggle({
			Title = title,
			Desc = desc,
			Value = (type(getv) == "function") and (getv() == true) or false,
			Callback = safe(function(v)
				setv(v)
				persist()
				if notifyTitle then
					W.notify(notifyTitle, title .. " -> " .. (v and "ON" or "OFF"))
				end
				if ctx.log then ctx.log(title .. " -> " .. (v and "ON" or "OFF")) end
				if control and control.Set and type(getv) == "function" then
					local real = getv()
					if real ~= v then pcall(function() control:Set(real) end) end
				end
			end),
		})
		return control
	end

	local function makeInputW(parent, title, desc, getv, setv)
		parent:Input({
			Title = title,
			Desc = desc,
			Type = "Input",
			Value = tostring((type(getv) == "function") and getv() or (getv or "")),
			Callback = safe(function(value)
				setv(value)
				persist()
			end),
		})
	end

	-- Cache opsi dinamis: dropdown V1, V2 & Boost pets sama-sama ambil
	-- ctx.inventoryPetOptions -> GetData bisa nunggu data game pas baru join
	-- (freeze 4.5-23s kalau 3 dropdown fetch serial). Caller pertama fetch,
	-- caller lain nunggu hasilnya -> cukup SATU GetData per cacheKey per TTL.
	local optCache = {}
	-- Cache opsi 5 menit: dropdown gak perlu re-scan tiap buka (dulu TTL 5s ->
	-- tiap klik Mindahin freeze). "Update Pet List" satu-satunya yang force
	-- re-scan (klik eksplisit user, jadi wajar nunggu sekali).
	local TTL_OPTIONS = 300
	local function fetchOptions(cacheKey, getOptions, force)
		if not cacheKey then
			local ok, list = pcall(getOptions)
			return (ok and type(list) == "table") and list or {}
		end
		local c = optCache[cacheKey]
		if c then
			if not c.done then
				local t0 = os.clock()
				while not optCache[cacheKey].done and os.clock() - t0 < 30 do task.wait(0.2) end
				local fc = optCache[cacheKey]
				return (fc and fc.done) and fc.list or {}
			end
			if not force and os.clock() - c.at < TTL_OPTIONS then return c.list end
		end
		optCache[cacheKey] = { done = false }
		local ok, list = pcall(getOptions)
		list = (ok and type(list) == "table") and list or {}
		if #list == 0 then
			-- GAK cache hasil kosong (join awal: data game belum siap). Cache
			-- kosong 5 menit = dropdown mati & retry cuma baca cache yang sama.
			if c and c.done and #c.list > 0 then
				optCache[cacheKey] = c
			else
				optCache[cacheKey] = { done = true, at = 0, list = {} }
			end
			return list
		end
		optCache[cacheKey] = { done = true, at = os.clock(), list = list }
		return list
	end

	-- Patch dropdown dist: constraint menu (bawaan 300x400 -> kapasitas rumus
	-- MenuWidth+52) + TextWrapped di Title opsi (dist gak set -> nama panjang
	-- kepotong). Harus dipanggil ulang tiap kali rows dibangun ulang (Refresh).
	local function patchDropdown(control)
		pcall(function()
			local mc = control.UIElements and control.UIElements.MenuCanvas
			local c = mc and mc:FindFirstChildOfClass("UISizeConstraint")
			if c then
				local maxH = 440
				-- Adaptive: dropdown di bawah layar dulu kepotong & scroll mentok
				-- (gak bisa kesampai) — clamp tinggi menu ke sisa ruang layar
				-- di bawah elemen. Min 140 biar search-bar tetap kesampai.
				pcall(function()
					local cam = workspace.CurrentCamera
					local vp = cam and cam.ViewportSize
					local ef = control.ElementFrame
					if ef and vp and vp.Y > 0 then
						local avail = vp.Y - (ef.AbsolutePosition.Y + ef.AbsoluteSize.Y) - 16
						if avail < maxH then maxH = math.max(140, math.floor(avail)) end
					end
				end)
				c.MaxSize = Vector2.new(292, maxH)
			end
		end)
		pcall(function()
			local sf = control.UIElements and control.UIElements.Menu
				and control.UIElements.Menu:FindFirstChild("Frame")
				and control.UIElements.Menu.Frame:FindFirstChild("ScrollingFrame")
			for _, opt in ipairs(sf and sf:GetChildren() or {}) do
				local tf = opt:FindFirstChild("Title", true)
				local tl = tf and tf:FindFirstChildOfClass("TextLabel")
				if tl then tl.TextWrapped = true end
			end
		end)
	end

	-- Isi rows via TABEL MENU langsung: Refresh dist bangun baris dari ARGUMEN
	-- dan nandain seleksi dari ap.Value milik menu (bukan element). Jangan
	-- andelin :Select — itu Refresh(ap.Values) dgn Values menu yang bisa beda
	-- table dari assignment ke element.
	-- (Fix "dropdown kosong pas reExec"): Semua fungsi menu library (Display/
	-- Refresh/Select) baca state dari table CONTROL (closure ap di library),
	-- BUKAN table menu -> restore harus nulis control.Value+control.Values.
	-- Serta: ekor Refresh() nembak Callback(ap.Value) & nimpa control.Values —
	-- refreshGate biar echo itu tidak dianggap klik user (gak nge-wipe set).
	local refreshGate = false
	local function dropdownFill(control, values, selected)
		control.Values = values
		control.Value = selected
		local menu = control.DropdownMenu or control
		menu.Values = values
		menu.Value = selected
		refreshGate = true
		pcall(function() menu:Refresh(values) end)
		refreshGate = false
		pcall(patchDropdown, control)
		return (values and #values) or 0
	end

	-- ponytail: prebuild rows di background pernah dicoba (anti-freeze klik) —
	-- DIBATALK: ribuan row instance hidup = FPS drop parah. Kembali lazy: click
	-- pertama ngehitch sekali (0.5-2s), sisanya instan & FPS aman. Upgrade path =
	-- list virtualisasi per-row di level library.

	-- Open hook: fillFn dipanggil TIAP menu dibuka (fillFn sendiri yang ngecek
	-- udah ke-build atau belum -> murah). Dulu cuma sekali, jadi "Update Pet
	-- List" harus rebuild semua dropdown langsung = freeze lama.
	-- dist ngebind klik ke <menuTabel>:Open() (bukan selalu table yang kita
	-- hold) -> hook dipasang di KEDUA sink: menu.Open & control.Open.
	local function lazyOpen(control, fillFn)
		local menu = control.DropdownMenu or control
		local function onOpen()
			pcall(fillFn)
		end
		local o1, o2 = menu.Open, control.Open
		menu.Open = function(self, ...)
			if o1 then pcall(o1, self, ...) end
			onOpen()
		end
		if control ~= menu and o2 then
			control.Open = function(self, ...)
				if o2 then pcall(o2, self, ...) end
				onOpen()
			end
		end
	end

	-- Single dropdown: opsi bisa string atau {name=, display=}; snapshot saat build
	-- + refresh() buat dipanggil ulang (WindUI Dropdown punya :Refresh).
	local function makeSingleW(parent, title, desc, getOptions, getv, setv, opts)
		opts = opts or {}
		local d2v, v2d = {}, {}
		-- WindUI menembak Callback() dengan Value konstruktur (echo kosong) tiap
		-- kali rows dibangun/refresh -> selalu-guard: echo PERTAMA (kosong) bukan
		-- pilihan user, jangan ditulis ke CFG (bisa nimpa saved value).
		local echoGuard = true
		local function snapshot()
			local opts, displays, selected = {}, {}, nil
			pcall(function()
				opts = getOptions() or {}
			end)
			table.clear(d2v); table.clear(v2d)
			local cur = getv()
			for _, o in ipairs(opts) do
				local d = (type(o) == "table") and (o.display or o.name) or o
				local v = (type(o) == "table") and (o.name or o.value) or o
				d2v[d] = v; v2d[v] = d
				displays[#displays + 1] = d
				if v == cur or d == cur then selected = d end
			end
			return displays, selected
		end
		local control
		local built = false
		local function fill()
			if built then return end
			built = true
			local displays, selected = snapshot()
			dropdownFill(control, displays, selected)
		end
		local dis0, sel0 = snapshot()
		control = parent:Dropdown({
			Title = title,
			Desc = desc,
			Values = {},
			Value = "",
			AllowNone = true,
			SearchBarEnabled = true,
			Callback = safe(function(d)
				if echoGuard then echoGuard = false; return end
				if refreshGate then return end -- ekor Refresh = echo, bukan klik
				setv(d2v[d] or d)
				persist()
			end),
		})
		-- Sinkron label tombol dgn saved value TANPA menunggu menu dibuka
		-- (WindUI cuma update label pas Display() dipanggil -> tanpa ini
		-- dropdown yang udah ke-restore tetap keliatan "--" = keliatan kosong).
		-- Sinkron label tombol dgn saved value TANPA menunggu menu dibuka.
		-- Tulis ke CONTROL.Value (sumber kebenaran library — Display/Refresh/
		-- Select baca dari control), bukan menu.Value (dulu: restore tetap
		-- tampak "--" walau data ke-load).
		pcall(function()
			control.Values = dis0
			control.Value = sel0 or ""
			control:Display()
		end)
		-- LAZY: baris dibangun SAAT MENU PERTAMA DIBUKA (menu kebuka instan,
		-- baris menyusul di thread sendiri). ponytail: open pertama list besar
		-- masih ngehitch — upgrade path = list virtualisasi.
		lazyOpen(control, fill)
		local function refresh()
			-- "Update Pet List": cuma tandain basi; rows dibangun ulang pas dibuka lagi.
			built = false
		end
		if opts.register and W.refreshers then
			W.refreshers[#W.refreshers + 1] = refresh
		end
		-- Warmer (no-UI): snapshot data doang buat pre-warm cache pas boot.
		if opts.register and W.ddWarmers then
			W.ddWarmers[#W.ddWarmers + 1] = function() pcall(snapshot) end
		end
		return control, refresh
	end

	-- Multi dropdown dinamis (pet team dll): opsi {value=, display=}, selSet keyed value.
	-- Tampilan: display dipecah "Nama | detail" -> opsi WindUI {Title=nama, Desc=detail},
	-- 2 baris, Desc TextWrapped bawaan dist -> nama pet SELALU kebaca utuh.
	-- SearchBarEnabled = search bawaan dist (filter Title, case-insensitive substring).
	-- MenuWidth 300 + patch UISizeConstraint (bawaan dist membatasi 300x400).
	-- Value/persist tetap keyed uuid (t.v) — bentuk state lama tidak berubah.
	local function makeMultiDynW(parent, title, desc, getOptions, selSet, onChange, opts)
		opts = opts or {}
		-- Reverse map display-title -> value uuid (isi tiap snapshot), buat
		-- normalisasi callback yang datang sebagai title string.
		local title2v = {}
		-- WindUI menembak Callback() (echo pilihan kosong) saat konstruksi & tiap
		-- Refresh rows. Echo pertama BUKAN input user -> di-skip, kalau tidak
		-- selSet ketimpa kosong lalu ke-persist (teams hilang pas reExec).
		local echoGuard = true
		local function splitDisplay(d)
			d = tostring(d or "")
			local cut = d:find(" | ", 1, true)
			if cut then return d:sub(1, cut - 1), d:sub(cut + 3) end
			return d, nil
		end
		local function snapshot(force)
			-- fetchOptions: cache+dedupe (GetData). force=true = tombol refresh
			-- eksplisit, lewatin cache. Cap opts.max: inventory GAG bisa ribuan
			-- pet -> Refresh dist bangun baris sinkron = freeze.
			local list = fetchOptions(opts.cacheKey, getOptions, force)
			local max = opts.max or 250
			local displays, selected = {}, {}
			table.clear(title2v)
			-- Yang ke-select DULUAN (cache dipakai bareng banyak dropdown, urutan
			-- aslinya ngikut dropdown lain) + biar nggak kepotong cap max.
			local ordered = {}
			for _, o in ipairs(list) do if selSet[o.value] then ordered[#ordered + 1] = o end end
			for _, o in ipairs(list) do if not selSet[o.value] then ordered[#ordered + 1] = o end end
			for i, o in ipairs(ordered) do
				if i > max then break end
				local t, rest = splitDisplay(o.display)
				displays[#displays + 1] = { Title = t, Desc = rest, v = o.value }
				title2v[t] = o.value
				if selSet[o.value] then selected[#selected + 1] = t end
			end
			return displays, selected, math.max(0, #list - max)
		end
		-- Values kosong saat build: snapshot (bisa nge-getData, first-call nunggu
		-- data game = freeze) dikerjakan task.spawn di bawah setelah window jadi.
		local control = parent:Dropdown({
			Title = title,
			Desc = desc,
			Values = {},
			Multi = true,
			AllowNone = true,
			SearchBarEnabled = true,
			MenuWidth = 240,
			Value = {},
			Callback = safe(function(sel)
				if echoGuard then echoGuard = false; return end
				-- Ekor Refresh() meng-echo Callback dgn Value saat itu — bukan
				-- klik user; tanpa gate ini set ketimpa & ke-persist kosong.
				if refreshGate then return end
				if type(sel) == "string" then sel = { sel } end
				-- Normalisasi dulu, baru wipe+isi: echo Refresh mengirim table
				-- opsi (ada .v), kadang title string. Tanpa ini, echo berisi
				-- title polos menghapus semua uuid dari selSet.
				local newSet = {}
				for _, t in ipairs(sel or {}) do
					local v
					if type(t) == "table" then
						v = t.v or t.value or (t.Title and title2v[t.Title]) or nil
					else
						v = title2v[t] or t
					end
					if v then newSet[v] = true end
				end
				for k in pairs(selSet) do selSet[k] = nil end
				for k in pairs(newSet) do selSet[k] = true end
				persist()
				if onChange then onChange() end
			end),
		})
		-- Constraint menu + wrap Title opsi ditangani patchDropdown() (module level)
		-- (local dideklarasi SEBELUM buildRows — dulu `built` di buildRows nulis global)
		local pendingDone, pending, built = false, nil, false
		local function buildRows(p)
			built = true
			dropdownFill(control, p.ds, p.sel2)
		end
		-- LAZY: baris dibangun pas menu pertama dibuka. Snapshot datanya sendiri
		-- jalan 0.5s setelah build di thread sendiri (fetchOptions = cukup 1x
		-- GetData), BARIS gak dibangun pas load/post-load = freeze scan habis.
		task.delay(0.5, function()
			pcall(function()
				local ds, sel2, extra = snapshot()
				-- Pas reExec, inventory game kadang belum siap (snapshot balik
				-- kosong & hasil kosong ke-cached 5s) -> jangan finalkan kosong;
				-- retry pelan SAMPAI isi muncul (cap 20s), kalau tidak label dan
				-- daftar mati kosong permanen sampai buka manual.
				local t0 = os.clock()
				while #ds == 0 and os.clock() - t0 < 20 do
					task.wait(1.5)
					ds, sel2, extra = snapshot()
				end
				pendingDone, pending = true, { ds = ds, sel2 = sel2, extra = extra }
				-- Label instan: restore keliatan tanpa harus buka dropdown
				-- (build rows tetap lazy sampai menu dibuka pertama kali).
				-- Tulis CONTROL.Value (baca komentar dropdownFill).
				pcall(function()
					control.Values = ds
					control.Value = sel2
					control:Display()
				end)
			end)
		end)
		local fillPending = false
		local function fill()
			-- Rows udah ke-pre-build pas boot (pre-warm)? Gak perlu rebuild.
			if built then return end
			-- GAK blocking jalur klik: menu kebuka INSTAN walau snapshot belum
			-- siap. Rows nanggung dibangun di thread sendiri begitu data datang
			-- (Refresh saat menu terbuka) — dulu: klik nunggu sampai 25s = freeze.
			if pendingDone then
				if pending then buildRows(pending) end
				return
			end
			if fillPending then return end
			fillPending = true
			task.spawn(function()
				local t0 = os.clock()
				while not pendingDone and os.clock() - t0 < 25 do task.wait(0.1) end
				fillPending = false
				if pending then buildRows(pending) end
			end)
		end
		lazyOpen(control, fill)
		local function refresh()
			-- Tombol "Update Pet List": JANGAN rebuild rows di sini (dulu rebuild
			-- semua dropdown x 250 row = freeze lama). Cukup ambil data baru di
			-- background (cache udah dikosongin addRefresh -> 1x GetData buat
			-- semua), update label, rows dibangun ulang pas dropdown dibuka lagi.
			built, pendingDone, pending = false, false, nil
			task.spawn(function()
				local ds, sel2, extra = snapshot()
				pendingDone, pending = true, { ds = ds, sel2 = sel2, extra = extra }
				pcall(function()
					control.Values = ds
					control.Value = sel2
					control:Display()
				end)
			end)
		end
		if opts.register then
			W.refreshers[#W.refreshers + 1] = refresh
		end
		return control, refresh
	end

	-- Multi dropdown statis (reg.PET_OPTIONS dll): opsi string, selSet keyed string.
	-- Rows di-defer: 4x dropdown dgn PET_OPTIONS penuh dibangun sinkron = freeze 53s.
	local function makeMultiW(parent, title, desc, options, selSet, onChange, opts)
		opts = opts or {}
		-- Echo-guard: Callback() pertama dari konstruktor bukan input user.
		local echoGuard = true
		local function savedTitles()
			local out = {}
			for _, o in ipairs(options) do
				if selSet[o] then out[#out + 1] = o end
			end
			return out
		end
		local control = parent:Dropdown({
			Title = title,
			Desc = desc,
			Values = {},
			Multi = true,
			AllowNone = true,
			SearchBarEnabled = true,
			MenuWidth = 240,
			Value = {},
			Callback = safe(function(sel)
				if echoGuard then echoGuard = false; return end
				if refreshGate then return end -- ekor Refresh = echo, bukan klik
				if type(sel) == "string" then sel = { sel } end
				for k in pairs(selSet) do selSet[k] = nil end
				for _, d in ipairs(sel or {}) do selSet[d] = true end
				persist()
				if onChange then onChange() end
			end),
		})
		-- Label instan biar saved selection kebaca tanpa buka menu.
		-- Label instan biar saved selection kebaca tanpa buka menu.
		-- Tulis ke CONTROL.Value (lihat komentar dropdownFill).
		pcall(function()
			control.Values = options
			control.Value = savedTitles()
			control:Display()
		end)
		-- LAZY: baris dibangun pas menu pertama dibuka — 4x PET_OPTIONS penuh
		-- dibangun sinkron (ctor/fill) = freeze berdetik; menu kebuka instan,
		-- baris menyusul. ponytail: open pertama list besar ngehitch sekali —
		-- upgrade path = list virtualisasi buat dropdown dist.
		local built = false
		local function fill()
			if built then return end
			built = true
			local n = dropdownFill(control, options, savedTitles())
			if ctx.log then
				ctx.log(("dropdown '%s' filled (%d options)"):format(title, n))
			end
		end
		lazyOpen(control, fill)
		return control
	end

	-- Section header polos: Box=false -> tanpa box; Opened=true -> konten langsung kebuka
	-- (default lib = Opened:false + tiap section dapat anak -> Expandable + chevron klik).
	-- Chevron dibunuh via polling: begitu muncul (Frame+ImageLabel di header), dipatikan.
	local function section(tab, title, opened)
		local sec = tab:Section({ Title = title, TextSize = 19, Opened = true })
	task.spawn(function()
		for _ = 1, 50 do
			pcall(function()
				local top = sec.ElementFrame.Outline.Top
				for _, ch in ipairs(top:GetChildren()) do
					if ch:IsA("Frame") and ch:FindFirstChildOfClass("ImageLabel") then
						ch.Visible = false
					end
				end
			end)
			task.wait(0.5)
		end
	end)
	return sec
end

-- Tombol "Update Pet List" (style Pet): jalankan semua refresher dropdown dinamis.
local function addRefresh(sec)
	sec:Button({
		Title = "Update Pet List",
		Desc = "Re-read the inventory and refresh dynamic dropdowns",
		Callback = safe(function()
			-- Kosongin cache sekali -> refresher pertama fetch, sisanya nunggu hasil
			-- yang sama (1x GetData). Rows nggak dibangun di sini -> nggak freeze.
			table.clear(optCache)
			for _, fn in ipairs(W.refreshers) do
				pcall(fn)
			end
			ctx.log("Pet list refreshed.")
			W.notify("Pet List", "Updated - dropdown baru kebaca pas dibuka")
		end),
	})
end

-- Mini-tab bar native (style Pet): [A][B][C...] di atas panel section.
-- Parent sama dgn card sections (ContainerFrame, padding halaman identik) ->
-- lebar bar PERSIS selebar cards. SortOrder kontainer = LayoutOrder + semua
-- element WindUI LayoutOrder 0 -> -1000 dipastikan row pertama.
-- Warna dari theme WindUI langsung (GetThemes), fallback konstanta Dark.
-- JANGAN baca Outline.BackgroundColor3: konstanta theme "Outline" = #FFFFFF,
-- ThemeTag-nya belum di-apply pas tab dibangun -> bar nyala putih.
local function miniBar(secs, order, defs, defaultId, rows)
	local container = secs[order[1]].ElementFrame.Parent
	local lib = W.windui
	local okTheme, cur = pcall(function()
		local th = lib and lib.GetThemes and lib:GetThemes() or nil
		local name = lib and lib.GetCurrentTheme and lib:GetCurrentTheme() or nil
		return th and name and th[name] or nil
	end)
	local bgc = (okTheme and cur and cur.Background) or Color3.fromRGB(16, 16, 16)
	local elc = (okTheme and cur and cur.ElementBackground) or Color3.fromRGB(42, 42, 44)
	local txth = (okTheme and cur and cur.Placeholder) or Color3.fromRGB(161, 161, 170)
	local pillBg = bgc:Lerp(elc, 0.30)
	local activeBg = elc:Lerp(Color3.new(1, 1, 1), 0.10)

	local bar = Instance.new("Frame")
	bar.Name = "MiniTabs"
	bar.LayoutOrder = -1000
	bar.Size = UDim2.new(1, 0, 0, 40)
	bar.BackgroundColor3 = pillBg
	bar.Parent = container
	Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 10)

	-- rows (opsional): pecah pill jadi R baris — {{a,b},{c}} -> 2 baris.
	-- order tetap list flat buat paint/unlock. Hatch: baris 1 = run config,
	-- baris 2 = rule config (biar gak berdesakan 5 pill sambung).
	local rowsDef = rows or { order }
	bar.Size = UDim2.new(1, 0, 0, (#rowsDef * 36) + ((#rowsDef - 1) * 4))
	local vstack = Instance.new("UIListLayout")
	vstack.FillDirection = Enum.FillDirection.Vertical
	vstack.Padding = UDim.new(0, 4)
	vstack.SortOrder = Enum.SortOrder.LayoutOrder
	vstack.VerticalAlignment = Enum.VerticalAlignment.Center
	vstack.Parent = bar

	local btns = {}
	local function paint(id, on)
		local b = btns[id]
		b.BackgroundColor3 = activeBg
		b.BackgroundTransparency = on and 0 or 1
		b.TextColor3 = on and ((cur and cur.Text) or Color3.fromRGB(255, 255, 255)) or txth
	end

	for ri, rlist in ipairs(rowsDef) do
		local rf = Instance.new("Frame")
		rf.Name = "MiniRow" .. ri
		rf.LayoutOrder = ri
		rf.Size = UDim2.new(1, 0, 0, 36)
		rf.BackgroundTransparency = 1
		rf.Parent = bar
		local hl = Instance.new("UIListLayout")
		hl.FillDirection = Enum.FillDirection.Horizontal
		hl.Padding = UDim.new(0, 6)
		hl.SortOrder = Enum.SortOrder.LayoutOrder
		hl.VerticalAlignment = Enum.VerticalAlignment.Center
		hl.Parent = rf
		for ci, id in ipairs(rlist) do
			local b = Instance.new("TextButton")
			b.Name = "Tab_" .. id
			b.LayoutOrder = ci
			b.Size = UDim2.new(1 / #rlist, -6, 0, 32)
			b.AutoButtonColor = false
			b.BackgroundTransparency = 1
			b.Text = defs[id].name
			b.TextTruncate = Enum.TextTruncate.AtEnd
			b.TextSize = 14
			b.Font = Enum.Font.GothamMedium
			Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
			b.Parent = rf
			btns[id] = b
		end
	end

	local function selectPanel(id)
		for pid, sec in pairs(secs) do
			pcall(function() sec.ElementFrame.Visible = (pid == id) end)
		end
		for _, pid in ipairs(order) do paint(pid, pid == id) end
	end
	for _, id in ipairs(order) do
		btns[id].Activated:Connect(function() selectPanel(id) end)
	end

	-- Ukuran section dist dipin manual (Open/Close = snapshot Top+Contentpx).
	-- Kalau pin kebaca sebelum layout jalan -> pin kecil -> konten ter-clip
	-- (panel "kosong"). Matikan mode expandable + force auto-size: section selalu
	-- sebesar konten, Open/Close dist jadi no-op permanen.
	local function unlockSize()
		for _, id in ipairs(order) do
			local s = secs[id]
			local ef = s and s.ElementFrame
			if ef and ef:FindFirstChild("Outline") then
				s.Expandable = false
				pcall(function()
					ef.AutomaticSize = Enum.AutomaticSize.Y
					ef.Size = UDim2.new(1, 0, 0, 0)
					ef.Outline.Content.Visible = true
				end)
			end
		end
	end
	task.defer(unlockSize)
	task.delay(0.15, unlockSize)

	selectPanel(defaultId)
end

	-- (hrow/HStack dibuang: element WindUI ngelewat padding halaman -> bar kepotong kanan)

	----------------------------------------------------------------- TAB: PET (Pickup V1 + Boost)
	local function buildPetTab(tab)
	-- Mini-tab [Pickup V1][Boost]: miniBar() — bar native beku + panel
	-- section auto-size (bukan HStack WindUI: element-nya ngelewat padding halaman).
	local DEFS = {
		v1    = { name = "Pickup V1" },
		boost = { name = "Boost" },
	}
	local ORDER = { "v1", "boost" }
	local secs = {}

	local function miniTab(id, buildFn)
		local sec = section(tab, DEFS[id].name)
		buildFn(sec)
		secs[id] = sec
	end

		--------------------------------------------------- panel 1: Pickup Pet V1
		miniTab("v1", function(sec)
			makeMultiDynW(sec, "Select Pets for Pickup [V1]",
				"Pick pets from your backpack (empty = every pet in the garden)",
				function() return ctx.inventoryPetOptions(CFG.pnpUuids) end,
				CFG.pnpUuids, function() persist() end,
				{ register = true, cacheKey = "inv_pets", fillDelay = 0.3, max = 250 })
			-- Timing V1 dikunci di modul (pickup 0.5 / equip 1E-20 / scan 0.20), nggak ada input.
			makeToggleW(sec, "Enable Automation Pickup V1",
				"Pickup right after the skill starts, re-place instantly.",
				function() return CFG.pnpEnabled end,
				function(v)
					CFG.pnpEnabled = v; persist()
					if v then
						if ctx.startPnpV1 then pcall(function() ctx.startPnpV1() end) end
					else
						if ctx.stopPnpV1 then pcall(function() ctx.stopPnpV1() end) end
					end
				end)
			addRefresh(sec)
		end)

		--------------------------------------------------- panel 2: Boost Pet
		miniTab("boost", function(sec)
			makeMultiDynW(sec, "Select Pets to Boost", "Pets to boost (active in the garden)",
				function() return ctx.inventoryPetOptions(CFG.boostPetUuids) end,
				CFG.boostPetUuids, function() persist() end,
				{ register = true, cacheKey = "inv_pets", fillDelay = 2.3, max = 250 })
			makeMultiDynW(sec, "Select Boost Items", "Boost items (Pet Toy) to use",
				function() return ctx.getBoostItemOptions(CFG.boostItemNames) end,
				CFG.boostItemNames, function() persist() end,
				{ register = true, cacheKey = "boost_items", fillDelay = 3.3, max = 250 })
			makeToggleW(sec, "Enable Automation Boost",
				"Auto apply boost items to pets, re-applies when the boost expires",
				function() return CFG.boostEnabled end,
				function(v)
					CFG.boostEnabled = v; persist()
					if v and ctx.startBoostPet then pcall(function() ctx.startBoostPet() end) end
				end)
			addRefresh(sec)
		end)

		miniBar(secs, ORDER, DEFS, "v1")
	end

	----------------------------------------------------------------- TAB: INVENTORY (Trade Ticket/Gift + Accept + Favorite)
	local function buildInventoryTab(tab)
		local idefs = {
			ticket = { name = "Trade Ticket" },
			gift   = { name = "Trade Gift" },
			accept = { name = "Auto Accept" },
			fav    = { name = "Favorite" },
		}
		local iorder = { "ticket", "gift", "accept", "fav" }
		local isecs = {}

		local function miniTab(id, buildFn)
			local sec = section(tab, idefs[id].name)
			buildFn(sec)
			isecs[id] = sec
		end

		local function playerOptions()
			local out = {}
			if ctx.getPlayers then
				pcall(function()
					for _, n in ipairs(ctx.getPlayers()) do out[#out + 1] = n end
				end)
			end
			return out
		end

		-- Status trade live: Paragraph :SetDesc (RichText tag warna dist).
		-- Mulai 3s setelah load + update hanya saat teks berubah — jangan bersaing
		-- dgn build window.
		local function addStatus(sec, isGift)
			local stat = sec:Paragraph({
				Title = isGift and "Gift Trade Status" or "Ticket Trade Status",
				Desc = "Completed: 0\nMatching pets: -\nStatus: IDLE",
			})
			task.spawn(function()
				task.wait(3)
				local last = ""
				while ctx.alive() do
					pcall(function()
						local avail = ctx.countMatchingPets and ctx.countMatchingPets(isGift) or 0
						local availCol = avail > 0 and "#5acc78" or "#dc5050"
						local active = isGift and CFG.tradeGiftEnabled or CFG.tradeTicketEnabled
						local methodRunning = ctx.state.tradeRunning
							and ((isGift and CFG.tradeMethod == "gift") or (not isGift and CFG.tradeMethod == "ticket"))
						local statusText = methodRunning and ctx.state.status
							or (active and "RUNNING" or "IDLE")
						local comp = methodRunning and (ctx.state.completed or 0) or 0
						local total = isGift and (CFG.giftTotalGifts or 0) or (CFG.totalTrades or 0)
						local unit = isGift and " gifts" or ""
						local txt = ("Completed: %d / %d%s\nMatching pets: <font color=\"%s\"><b>%d</b></font>\nStatus: %s")
							:format(comp, total, unit, availCol, avail, statusText)
						if txt ~= last then
							last = txt
							stat:SetDesc(txt)
						end
					end)
					task.wait(2)
				end
			end)
		end

		miniTab("ticket", function(sec)
			makeSingleW(sec, "Target Player", "Target player for ticket trades",
				playerOptions,
				function() return CFG.targetPlayer end,
				function(v) CFG.targetPlayer = v end, { register = true, fillDelay = 0.5 })
			makeMultiW(sec, "Pet Types to Trade", "Filter pets by type (empty = all non-favorite)",
				reg.PET_OPTIONS, CFG.petTypes, function() persist() end, { fillDelay = 1.1 })
			makeInputW(sec, "Weight Filter (KG)", "In-game display weight | 0=off | +6 = min 6kg | -6 = max 6kg",
				function() return CFG.weightFilter end,
				function(t) CFG.weightFilter = tonumber(t) or 0 end)
			makeInputW(sec, "Age Filter", "0 = off | +50 = min age 50 | -50 = max age 50",
				function() return CFG.ageFilter end,
				function(t) CFG.ageFilter = tonumber(t) or 0 end)
			makeInputW(sec, "Pets Per Trade", "Pets included in each trade",
				function() return CFG.petsPerTrade end,
				function(t)
					local n = tonumber(t)
					CFG.petsPerTrade = (n and n > 0) and math.floor(n) or 1
				end)
			makeInputW(sec, "Total Trades", "How many trades to run",
				function() return CFG.totalTrades end,
				function(t)
					local n = tonumber(t)
					CFG.totalTrades = (n and n >= 0) and math.floor(n) or 0
				end)
			makeToggleW(sec, "Auto Unfavorite [Trade]", "Remove favorite before trading",
				function() return CFG.autoUnfavorite end,
				function(v) CFG.autoUnfavorite = v end)
			addStatus(sec, false)
			makeToggleW(sec, "Enable Trade by Ticket", "Send a ticket trade request, fill pets, accept & confirm",
				function() return CFG.tradeTicketEnabled or (CFG.tradeEnabled and CFG.tradeMethod == "ticket") end,
				function(v)
					CFG.tradeTicketEnabled = v
					CFG.tradeEnabled = v
					if v then
						CFG.tradeGiftEnabled = false
						CFG.tradeMethod = "ticket"
						persist()
						ctx.state.completed = 0
						if ctx.startTrade then pcall(function() ctx.startTrade("ticket") end) end
					else
						persist()
						if CFG.tradeMethod == "ticket" and ctx.stopTrade then pcall(ctx.stopTrade) end
					end
				end)
			addRefresh(sec)
		end)

		miniTab("gift", function(sec)
			makeSingleW(sec, "Target Player", "Target player for gifts (defaults to the ticket target)",
				playerOptions,
				function() return (CFG.giftTargetPlayer ~= "" and CFG.giftTargetPlayer) or CFG.targetPlayer end,
				function(v) CFG.giftTargetPlayer = v end, { register = true, fillDelay = 0.8 })
			makeMultiW(sec, "Pet Types to Gift", "Filter pets by type (empty = all non-favorite)",
				reg.PET_OPTIONS, CFG.giftPetTypes, function() persist() end, { fillDelay = 1.4 })
			makeInputW(sec, "Weight Filter (KG)", "0=off | +6 = min 6kg | -6 = max 6kg",
				function() return CFG.giftWeightFilter end,
				function(t) CFG.giftWeightFilter = tonumber(t) or 0 end)
			makeInputW(sec, "Age Filter", "0=off | +50 = min age 50 | -50 = max age 50",
				function() return CFG.giftAgeFilter end,
				function(t) CFG.giftAgeFilter = tonumber(t) or 0 end)
			makeInputW(sec, "Pets Per Batch", "Pets gifted per round",
				function() return CFG.giftPetsPerBatch end,
				function(t)
					local n = tonumber(t)
					CFG.giftPetsPerBatch = (n and n > 0) and math.floor(n) or 1
				end)
			makeInputW(sec, "Total Gifts", "Pets/gifts to send before stopping",
				function() return CFG.giftTotalGifts end,
				function(t)
					local n = tonumber(t)
					CFG.giftTotalGifts = (n and n >= 0) and math.floor(n) or 0
				end)
			makeToggleW(sec, "Auto Unfavorite [Gift]", "Remove favorite before gifting",
				function() return CFG.giftAutoUnfavorite end,
				function(v) CFG.giftAutoUnfavorite = v end)
			addStatus(sec, true)
			makeToggleW(sec, "Enable Trade by Gift", "Send pet gifts directly without tickets (fast & automatic)",
				function() return CFG.tradeGiftEnabled or (CFG.tradeEnabled and CFG.tradeMethod == "gift") end,
				function(v)
					CFG.tradeGiftEnabled = v
					if v then
						CFG.tradeTicketEnabled = false
						CFG.tradeEnabled = false
						CFG.tradeMethod = "gift"
						persist()
						ctx.state.completed = 0
						if ctx.startTrade then pcall(function() ctx.startTrade("gift") end) end
					else
						persist()
						if CFG.tradeMethod == "gift" and ctx.stopTrade then pcall(ctx.stopTrade) end
					end
				end)
			addRefresh(sec)
		end)

		miniTab("accept", function(sec)
			makeToggleW(sec, "Automation Accept Gifts", "Auto accept incoming gifts",
				function() return CFG.acceptGifts end,
				function(v) CFG.acceptGifts = v end)
			makeToggleW(sec, "Automation Accept Trades", "Auto accept incoming trades",
				function() return CFG.acceptTrades end,
				function(v) CFG.acceptTrades = v end)
			addRefresh(sec)
		end)

		miniTab("fav", function(sec)
			makeToggleW(sec, "Auto Favourite Pets", "Auto favorite the selected pet types",
				function() return CFG.autoFavorite end,
				function(v)
					CFG.autoFavorite = v
					if ctx.startAutoFavorite and ctx.stopAutoFavorite then
						if v then pcall(ctx.startAutoFavorite)
						else pcall(ctx.stopAutoFavorite) end
					end
				end)
			makeMultiW(sec, "Favourite Pet Types", "Pet types to favorite",
				reg.PET_OPTIONS, CFG.favoritePetTypes, function() persist() end, { fillDelay = 1.7 })
			makeToggleW(sec, "Auto Unfavourite Pets", "Auto unfavorite the selected pet types",
				function() return CFG.autoUnfavoritePets end,
				function(v)
					CFG.autoUnfavoritePets = v
					if v and ctx.startAutoUnfavorite then pcall(ctx.startAutoUnfavorite)
					elseif ctx.stopAutoUnfavorite then pcall(ctx.stopAutoUnfavorite) end
				end)
			makeMultiW(sec, "Unfavourite Pet Types", "Pet types to unfavorite (empty = all pets)",
				reg.PET_OPTIONS, CFG.unfavoritePetTypes, function() persist() end, { fillDelay = 2.0 })
			addRefresh(sec)
		end)

		miniBar(isecs, iorder, idefs, "ticket")
	end

	----------------------------------------------------------------- TAB: FARM (Plants/Care/Shovel/Harvest)
	local function buildFarmTab(tab)
		local fdefs = {
			plants  = { name = "Plants" },
			care    = { name = "Care" },
			shovel  = { name = "Shovel" },
			harvest = { name = "Harvest" },
			fav     = { name = "Favorite" },
			reclaim = { name = "Reclaim" },
		}
		local forder = { "plants", "care", "shovel", "harvest", "fav", "reclaim" }
		local fsecs = {}

		local function miniTab(id, buildFn)
			local sec = section(tab, fdefs[id].name)
			buildFn(sec)
			fsecs[id] = sec
		end

		--------------------------------------------------- panel 1: Plants
		miniTab("plants", function(sec)
			makeMultiDynW(sec, "Select Seeds", "Pick seeds from the inventory (number = quantity).",
				function() return ctx.getPlantSeedOptions() end,
				CFG.plantSeedNames, function() persist() end,
				{ register = true, cacheKey = "inv_seeds", fillDelay = 0.3 })
			makeSingleW(sec, "Select Position", "Plant location. Good Position = tidy rows ordered left -> right.",
				function() return { "Random", "Player Position", "Good Position" } end,
				function() return CFG.plantPosition end,
				function(v) CFG.plantPosition = v end, { fillDelay = 0.5 })
			makeToggleW(sec, "Shovel Blocking Plants", "Good Position: shovel old plants blocking row cells so rows stay truly ordered without server-side shifting.",
				function() return CFG.goodClear ~= false end,
				function(v) CFG.goodClear = v; persist() end)
			makeInputW(sec, "Delay To Plants", "Extra delay (sec) per seed planted.",
				function() return tostring(CFG.plantDelay) end,
				function(t) CFG.plantDelay = tonumber(t) or 0 end)
			makeToggleW(sec, "Auto Plants Seed", "Auto plant the selected seeds.",
				function() return CFG.plantSeedEnabled end,
				function(v)
					CFG.plantSeedEnabled = v
					if v and ctx.startPlant then pcall(function() ctx.startPlant() end) end
				end)
			addRefresh(sec)
		end)

		--------------------------------------------------- panel 2: Care (Sprinkler + Sprinkler Shovel + Water)
		miniTab("care", function(sec)
			makeMultiDynW(sec, "Select Sprinkler", "Sprinklers to place (number = quantity).",
				function() return ctx.getSprinklerOptions() end,
				CFG.sprinklerNames, function() persist() end, { register = true, fillDelay = 0.6 })
			makeMultiDynW(sec, "Select Sprinkler Plants", "Place near these plants. Empty = use Position.",
				function() return ctx.getSprinklerPlantOptions() end,
				CFG.sprinklerPlantNames, function() persist() end, { register = true, fillDelay = 0.8 })
			makeSingleW(sec, "Select Sprinkler Position", "Place location when Plants is empty.",
				function() return { "Random", "Player Position" } end,
				function() return CFG.sprinklerPosition end,
				function(v) CFG.sprinklerPosition = v end, { fillDelay = 1.0 })
			makeInputW(sec, "Delay To Sprinkler", "Extra delay (sec) per placement.",
				function() return tostring(CFG.sprinklerDelay) end,
				function(t) CFG.sprinklerDelay = tonumber(t) or 0 end)
			makeToggleW(sec, "Auto Sprinkler", "Auto place the selected sprinklers.",
				function() return CFG.sprinklerEnabled end,
				function(v)
					CFG.sprinklerEnabled = v
					if v and ctx.startSprinkler then pcall(function() ctx.startSprinkler() end) end
				end)
			makeMultiDynW(sec, "Select Shovel Sprinkler", "Placed sprinklers to remove. 'All' = every sprinkler.",
				function() return ctx.getShovelSprinklerOptions() end,
				CFG.shovelSprinklerNames, function() persist() end, { register = true, fillDelay = 1.2 })
			makeInputW(sec, "Delay To Shovel Sprinkler", "Extra delay (sec) per removal.",
				function() return tostring(CFG.shovelSprinklerDelay) end,
				function(t) CFG.shovelSprinklerDelay = tonumber(t) or 0 end)
			makeToggleW(sec, "Auto Shovel Sprinkler", "Auto remove the selected sprinklers (equips the Shovel).",
				function() return CFG.shovelSprinklerEnabled end,
				function(v)
					CFG.shovelSprinklerEnabled = v
					if v and ctx.startShovelSprinkler then pcall(function() ctx.startShovelSprinkler() end) end
				end)
			makeMultiDynW(sec, "Select Water Fruits", "Pick fruits/plants to water. 'All' = everything.",
				function() return ctx.getWaterFruitOptions() end,
				CFG.waterFruitNames, function() persist() end, { register = true, fillDelay = 1.4 })
			makeInputW(sec, "Delay to Water", "Extra delay (sec) per watering cycle.",
				function() return tostring(CFG.waterDelay) end,
				function(t) CFG.waterDelay = tonumber(t) or 1 end)
			makeToggleW(sec, "Auto Water Fruits", "Auto water the selected fruits.",
				function() return CFG.waterEnabled end,
				function(v)
					CFG.waterEnabled = v
					if v and ctx.startWater then pcall(function() ctx.startWater() end) end
				end)
			addRefresh(sec)
		end)

		--------------------------------------------------- panel 3: Shovel (Tree + Fruits)
		miniTab("shovel", function(sec)
			makeMultiDynW(sec, "Select Tree", "Pick trees/plants to shovel. 'All' = everything.",
				function() return ctx.getShovelTreeOptions() end,
				CFG.shovelTreeNames, function() persist() end, { register = true, fillDelay = 1.6 })
			makeInputW(sec, "Delay To Shovel Tree", "Extra delay (sec) per shovel tree cycle.",
				function() return tostring(CFG.shovelTreeDelay) end,
				function(t) CFG.shovelTreeDelay = tonumber(t) or 0 end)
			makeToggleW(sec, "Auto Shovel Tree", "Auto shovel the selected trees/plants.",
				function() return CFG.shovelTreeEnabled end,
				function(v)
					CFG.shovelTreeEnabled = v
					if v and ctx.startShovelTree then pcall(function() ctx.startShovelTree() end) end
				end)
			makeMultiDynW(sec, "Select Shovel Fruits", "Fruit types to shovel. 'All' = everything.",
				function() return ctx.getShovelFruitOptions() end,
				CFG.shovelFruitNames, function() persist() end, { register = true, fillDelay = 1.8 })
			makeMultiDynW(sec, "Select Shovel Mutation", "Mutation filter. Empty/'All' = ignore.",
				function() return ctx.getShovelMutationOptions() end,
				CFG.shovelFruitMuts, function() persist() end, { register = true, fillDelay = 2.0 })
			makeMultiDynW(sec, "Select Shovel Variant", "Variant filter (Gold/Rainbow/etc). Empty/'All' = ignore.",
				function() return ctx.getShovelVariantOptions() end,
				CFG.shovelFruitVariants, function() persist() end, { register = true, fillDelay = 2.2 })
			makeSingleW(sec, "Select Shovel Threshold Mode", "How fruit weight is compared.",
				function() return ctx.getShovelModeOptions() end,
				function() return CFG.shovelFruitMode end,
				function(v) CFG.shovelFruitMode = v end, { fillDelay = 2.4 })
			makeInputW(sec, "Shovel Weight Threshold", "Enter '0' to skip this filter.",
				function() return tostring(CFG.shovelFruitWeight) end,
				function(t) CFG.shovelFruitWeight = tonumber(t) or 0 end)
			makeInputW(sec, "Delay To Shovel Fruit", "Extra delay (sec) per shovel fruit cycle.",
				function() return tostring(CFG.shovelFruitDelay) end,
				function(t) CFG.shovelFruitDelay = tonumber(t) or 0 end)
			makeToggleW(sec, "Auto Shovel Fruits", "Shovel plants whose fruits match the filter.",
				function() return CFG.shovelFruitEnabled end,
				function(v)
					CFG.shovelFruitEnabled = v
					if v and ctx.startShovelFruit then pcall(function() ctx.startShovelFruit() end) end
				end)
			addRefresh(sec)
		end)

		--------------------------------------------------- panel 4: Harvest (Collect)
		miniTab("harvest", function(sec)
			makeInputW(sec, "Delay To Collect", "Extra delay (sec) per collect cycle.",
				function() return tostring(CFG.collectDelay) end,
				function(t) CFG.collectDelay = tonumber(t) or 0 end)
			makeToggleW(sec, "Stop Collect If Backpack Is Full Max", "Stop collecting once the backpack is full.",
				function() return CFG.collectStopIfFull end,
				function(v) CFG.collectStopIfFull = v end)
			makeToggleW(sec, "Auto Sell Fruit If Backpack Full", "Sell all fruits once the backpack is full.",
				function() return CFG.collectAutoSellIfFull end,
				function(v) CFG.collectAutoSellIfFull = v end)
			makeMultiDynW(sec, "Select Whitelist Fruit", "Pick fruit types to collect.",
				function() return ctx.getCollectFruitOptions() end,
				CFG.collectWlFruitNames, function() persist() end,
				{ register = true, cacheKey = "collect_fruits", fillDelay = 2.6 })
			makeToggleW(sec, "Auto Collect Whitelisted Fruits", "Collect only whitelisted fruit types.",
				function() return CFG.collectWlFruitEnabled end,
				function(v)
					CFG.collectWlFruitEnabled = v
					if v and ctx.startCollect then pcall(function() ctx.startCollect() end) end
				end)
			makeMultiDynW(sec, "Select Whitelist Mutations", "Pick mutations to collect.",
				function() return ctx.getCollectMutationOptions() end,
				CFG.collectWlMutNames, function() persist() end, { register = true, fillDelay = 2.8 })
			makeToggleW(sec, "Auto Collect Whitelisted Mutations", "Collect only fruits with whitelisted mutations.",
				function() return CFG.collectWlMutEnabled end,
				function(v)
					CFG.collectWlMutEnabled = v
					if v and ctx.startCollect then pcall(function() ctx.startCollect() end) end
				end)
			makeMultiDynW(sec, "Select Combined Fruits", "Filter by fruit type.",
				function() return ctx.getCollectFruitOptions() end,
				CFG.collectCombFruitNames, function() persist() end,
				{ register = true, cacheKey = "collect_fruits", fillDelay = 3.0 })
			makeMultiDynW(sec, "Select Combined Mutation", "Filter by mutation type.",
				function() return ctx.getCollectMutationOptions() end,
				CFG.collectCombMutNames, function() persist() end, { register = true, fillDelay = 3.2 })
			makeMultiDynW(sec, "Select Combined Variant", "Filter by variant type.",
				function() return ctx.getCollectVariantOptions() end,
				CFG.collectCombVariants, function() persist() end, { register = true, fillDelay = 3.4 })
			makeSingleW(sec, "Whitelist Weight Mode", "How fruit weight is compared.",
				function() return ctx.getCollectModeOptions() end,
				function() return CFG.collectCombMode end,
				function(v) CFG.collectCombMode = v end, { fillDelay = 3.6 })
			makeInputW(sec, "Whitelist Weight", "Enter '0' to skip this filter.",
				function() return tostring(CFG.collectCombWeight) end,
				function(t) CFG.collectCombWeight = tonumber(t) or 0 end)
			makeToggleW(sec, "Auto Collect Fruits", "Collect fruits matching ALL combined criteria.",
				function() return CFG.collectCombEnabled end,
				function(v)
					CFG.collectCombEnabled = v
					if v and ctx.startCollect then pcall(function() ctx.startCollect() end) end
				end)
			makeMultiDynW(sec, "Select Blacklist Mutations", "Mutations to SKIP. Every other mutated fruit is collected (non-mutated fruits are never collected).",
				function() return ctx.getCollectBlMutOptions() end,
				CFG.collectBlMutNames, function() persist() end, { register = true, fillDelay = 3.7 })
			makeToggleW(sec, "Auto Collect Mutated (Blacklist)", "Collect all mutated fruits except the blacklisted mutations.",
				function() return CFG.collectBlMutEnabled end,
				function(v)
					CFG.collectBlMutEnabled = v
					if v and ctx.startCollect then pcall(function() ctx.startCollect() end) end
				end)
			addRefresh(sec)
		end)

		--------------------------------------------------- panel 5: Favorite
		miniTab("fav", function(sec)
			makeMultiDynW(sec, "Select Fruits [Fav]", "Garden fruit types to favorite (empty = any).",
				function() return ctx.getFavFruitOptions() end,
				CFG.favFruitNames, function() persist() end, { register = true, fillDelay = 3.8 })
			makeMultiDynW(sec, "Filter Mutations [Fav]", "Required mutations (empty = any mutation counts).",
				function() return ctx.getFavMutationOptions() end,
				CFG.favMutNames, function() persist() end, { register = true, fillDelay = 4.0 })
			makeSingleW(sec, "Weight Mode [Fav]", "Fruit weight comparison (empty = off).",
				function() return ctx.getFavModeOptions() end,
				function() return CFG.favMode end,
				function(v) CFG.favMode = v end, { fillDelay = 4.2 })
			makeInputW(sec, "Weight Value [Fav]", "Weight threshold (0 = off).",
				function() return tostring(CFG.favWeight) end,
				function(t) CFG.favWeight = tonumber(t) or 0 end)
			makeInputW(sec, "Delay To Favorite", "Seconds per favorite scan cycle.",
				function() return tostring(CFG.favDelay) end,
				function(t) CFG.favDelay = tonumber(t) or 1 end)
			makeToggleW(sec, "Auto Favorite Fruits", "Favorite garden fruits matching the filter.",
				function() return CFG.favEnabled end,
				function(v)
					CFG.favEnabled = v
					if v and ctx.startFavorite then pcall(function() ctx.startFavorite() end) end
				end)
			makeToggleW(sec, "Auto Unfavorite Fruits", "Unfavorite garden fruits matching the filter.",
				function() return CFG.unfavEnabled end,
				function(v)
					CFG.unfavEnabled = v
					if v and ctx.startFavorite then pcall(function() ctx.startFavorite() end) end
				end)
			addRefresh(sec)
		end)

		--------------------------------------------------- panel 6: Reclaim
		miniTab("reclaim", function(sec)
			makeMultiDynW(sec, "Select Plants [Reclaim]", "Pick plants to reclaim. 'All' = everything.",
				function() return ctx.getReclaimPlantOptions() end,
				CFG.reclaimPlantNames, function() persist() end, { register = true, fillDelay = 4.4 })
			makeToggleW(sec, "Auto Reclaimer Plants", "Auto reclaim the selected plants with the Reclaimer tool",
				function() return CFG.reclaimEnabled end,
				function(v)
					CFG.reclaimEnabled = v
					if v and ctx.startReclaim then pcall(function() ctx.startReclaim() end) end
				end)
			addRefresh(sec)
		end)

		miniBar(fsecs, forder, fdefs, "plants",
			{ { "plants", "care", "shovel" }, { "harvest", "fav", "reclaim" } })
	end

	----------------------------------------------------------------- TAB: HATCH (Auto Hatch + Auto Sell)
	local function buildHatchTab(tab)
		local hdefs = {
			ctrl   = { name = "Status & Control" },
			teams  = { name = "Teams" },
			eggs   = { name = "Egg Configuration" },
			bronto = { name = "Bronto Configuration" },
			sell   = { name = "Sell Configuration" },
		}
		local horder = { "ctrl", "teams", "eggs", "bronto", "sell" }
		local hsecs = {}
		local function miniTab(id, buildFn)
			local sec = section(tab, hdefs[id].name)
			buildFn(sec)
			hsecs[id] = sec
		end

		--------------------------------------------------- panel 1: Status & Control
		miniTab("ctrl", function(sec)
			-- Live status lengkap (style SRC lama): status, phase, team, bp,
			-- egg tracking, placed, hatched, sell cycle, recovery stat (2s).
			local stat = sec:Paragraph({
				Title = "Live Status",
				Desc = "Status: -",
			})
			task.spawn(function()
				task.wait(3)
				local last = ""
				while ctx.alive() do
					pcall(function()
						local s = ctx.getHatchSummary and ctx.getHatchSummary()
						if s then
							local proc = s.proc or {}
							local txt = table.concat({
								("Status: %s   |   Phase: %s"):format(tostring(s.status or "-"), tostring(s.phase or "-")),
								("Backpack: %s / %s"):format(tostring(s.backpack or 0), tostring(s.maxBackpack or 0)),
								("Egg: %s"):format(tostring(s.currentEgg or "-")),
								("   Before: %s  ->  Now: %s"):format(
									tostring(s.eggBefore or 0), tostring(s.currentAmount or 0)),
								("Placed: %s / %s   |   Ready: %s"):format(
									tostring(s.placed or 0), tostring(s.maxPlaced or 0), tostring(s.ready or 0)),
								("Hatched: %s   |   Sell Cycle: %s / %s   (%s)"):format(
									tostring(s.eggsHatched or 0), tostring(s.cycleProg or 0), tostring(s.cycleTarget or 0), tostring(s.sellMode or "-")),
								("Recovery: Koi %s (%s%%)  |  Seal %s (%s%%)"):format(
									tostring(proc.koiCount or 0), tostring(proc.koiPct or 0),
									tostring(proc.sealCount or 0), tostring(proc.sealPct or 0)),
							}, "\n")
							if txt ~= last then last = txt; stat:SetDesc(txt) end
						end
					end)
					task.wait(2.0)
				end
			end)

			-- Master toggle = pengganti Start/Stop bar; handleInventoryFull
			-- memanggil ctx.ui.rHatchToggle pas Auto Hatch distop (Invent Max).
			local masterCtrl = makeToggleW(sec, "Enable Auto Hatch",
				"Auto place eggs, hatch (Core/Hatch/Bronto teams), and sell per your config.",
				function() return CFG.hatchEnabled end,
				function(v)
					-- WAJIB set flag dulu: loop hatch while CFG.hatchEnabled —
					-- tanpa ini loop mati instan & toggle snap balik ke OFF.
					CFG.hatchEnabled = v
					if v then
						if ctx.startHatch then pcall(function() ctx.startHatch() end) end
					else
						if ctx.stopHatch then pcall(function() ctx.stopHatch() end) end
						if not CFG.hatchRejoinMinusEnabled and not CFG.hatchRejoinPlusEnabled and ctx.stopEggMinusWatcher then
							pcall(function() ctx.stopEggMinusWatcher() end)
						end
					end
				end)
			ctx.ui.rHatchToggle = function()
				pcall(function() masterCtrl:Set(CFG.hatchEnabled) end)
			end
			makeToggleW(sec, "Auto GM Sprinkler",
				"Keep a Grandmaster Sprinkler placed — re-places when it's about to expire (lasts ~10 min).",
				function() return CFG.gmSprinklerEnabled end,
				function(v)
					CFG.gmSprinklerEnabled = v
					if v then
						if ctx.startGmSprinkler then pcall(function() ctx.startGmSprinkler() end) end
					else
						if ctx.stopGmSprinkler then pcall(function() ctx.stopGmSprinkler() end) end
					end
					persist()
				end)
			makeToggleW(sec, "Auto Sell Pets", "Auto sell backpack pets per your settings.",
				function() return CFG.autoSellEnabled end,
				function(v) CFG.autoSellEnabled = v end)
		end)

		--------------------------------------------------- panel 2: Teams
		miniTab("teams", function(sec)
			makeMultiDynW(sec, "Core Team", "Percepat egg (incubation speed)",
				function() return ctx.inventoryPetOptions(CFG.hatchCoreTeam) end,
				CFG.hatchCoreTeam, function() persist() end,
				{ register = true, cacheKey = "inv_pets", fillDelay = 0.2, max = 250 })
			makeInputW(sec, "Core Equip Delay (sec)", "Delay between pets while equipping the Core team",
				function() return tostring(CFG.hatchCoreEquipDelay or 0) end,
				function(t) CFG.hatchCoreEquipDelay = tonumber(t) or 0 end)
			makeInputW(sec, "Core Unequip Delay (sec)", "Delay between pets while unequipping the Core team",
				function() return tostring(CFG.hatchCoreUnequipDelay or 1) end,
				function(t) CFG.hatchCoreUnequipDelay = tonumber(t) or 1 end)

			makeMultiDynW(sec, "Hatch Team", "Hatch ready eggs (Koi = refunds the egg)",
				function() return ctx.inventoryPetOptions(CFG.hatchHatchTeam) end,
				CFG.hatchHatchTeam, function() persist() end,
				{ register = true, cacheKey = "inv_pets", fillDelay = 0.4, max = 250 })
			makeInputW(sec, "Hatch Equip Delay (sec)", "Delay between pets while equipping the Hatch team",
				function() return tostring(CFG.hatchTeamEquipDelay or 0) end,
				function(t) CFG.hatchTeamEquipDelay = tonumber(t) or 0 end)
			makeInputW(sec, "Hatch Unequip Delay (sec)", "Delay between pets while unequipping the Hatch team",
				function() return tostring(CFG.hatchTeamUnequipDelay or 1) end,
				function(t) CFG.hatchTeamUnequipDelay = tonumber(t) or 1 end)
			makeInputW(sec, "Hatch Team Delay (sec)", "Wait after the team swap before hatching",
				function() return tostring(CFG.hatchTeamDelay or 5.5) end,
				function(t) CFG.hatchTeamDelay = tonumber(t) or 5.5 end)

			makeMultiDynW(sec, "Bronto Team", "+30% pet weight while hatching (Brontosaurus)",
				function() return ctx.inventoryPetOptions(CFG.hatchBrontoTeam) end,
				CFG.hatchBrontoTeam, function() persist() end,
				{ register = true, cacheKey = "inv_pets", fillDelay = 0.6, max = 250 })
			makeInputW(sec, "Bronto Equip Delay (sec)", "Delay between pets while equipping the Bronto team",
				function() return tostring(CFG.hatchBrontoEquipDelay or 0) end,
				function(t) CFG.hatchBrontoEquipDelay = tonumber(t) or 0 end)
			makeInputW(sec, "Bronto Unequip Delay (sec)", "Delay between pets while unequipping the Bronto team",
				function() return tostring(CFG.hatchBrontoUnequipDelay or 1) end,
				function(t) CFG.hatchBrontoUnequipDelay = tonumber(t) or 1 end)
			makeInputW(sec, "Bronto Team Delay (sec)", "Wait after the team swap before the Bronto hatch",
				function() return tostring(CFG.brontoTeamDelay or 5.5) end,
				function(t) CFG.brontoTeamDelay = tonumber(t) or 5.5 end)

			makeMultiDynW(sec, "Sell Team", "Sell + convert pets back into eggs (Seal the Deal)",
				function() return ctx.inventoryPetOptions(CFG.hatchSellTeam) end,
				CFG.hatchSellTeam, function() persist() end,
				{ register = true, cacheKey = "inv_pets", fillDelay = 0.8, max = 250 })
			makeInputW(sec, "Sell Equip Delay (sec)", "Delay between pets while equipping the Sell team",
				function() return tostring(CFG.hatchSellEquipDelay or 0) end,
				function(t) CFG.hatchSellEquipDelay = tonumber(t) or 0 end)
			makeInputW(sec, "Sell Unequip Delay (sec)", "Delay between pets while unequipping the Sell team",
				function() return tostring(CFG.hatchSellUnequipDelay or 1) end,
				function(t) CFG.hatchSellUnequipDelay = tonumber(t) or 1 end)
			makeInputW(sec, "Sell Team Delay (sec)", "Wait after the team swap before selling",
				function() return tostring(CFG.sellTeamDelay or 5.5) end,
				function(t) CFG.sellTeamDelay = tonumber(t) or 5.5 end)
			addRefresh(sec)
		end)

		--------------------------------------------------- panel 3: Egg Configuration
		miniTab("eggs", function(sec)
			makeSingleW(sec, "Egg to Hatch", "Eggs from the backpack (number = quantity).",
				function() return ctx.getEggBackpackOptions() end,
				function() return tostring(CFG.hatchEggName or "") end,
				function(v) if v ~= "" then CFG.hatchEggName = v end end,
				{ register = true, fillDelay = 1.8 })
			makeSingleW(sec, "Placement Pattern", "Grid = tidy rows, Random = scattered.",
				function() return { "Grid", "Random" } end,
				function() return CFG.hatchPlacePattern or "Grid" end,
				function(v) CFG.hatchPlacePattern = (v == "Random") and "Random" or "Grid" end, { fillDelay = 2.0 })
			makeInputW(sec, "Max Placed", "Maximum eggs placed in the garden.",
				function() return tostring(CFG.hatchMaxPlaced or 8) end,
				function(t) CFG.hatchMaxPlaced = math.max(1, tonumber(t) or 8) end)

			makeToggleW(sec, "Auto Rejoin on Egg Minus", "Rejoin the server once the egg deficit hits the threshold.",
				function() return CFG.hatchRejoinMinusEnabled end,
				function(v)
					CFG.hatchRejoinMinusEnabled = v
					if v and ctx.startEggMinusWatcher then pcall(function() ctx.startEggMinusWatcher() end) end
					if not v and not CFG.hatchRejoinPlusEnabled and ctx.stopEggMinusWatcher then
						pcall(function() ctx.stopEggMinusWatcher() end)
					end
				end)
			makeInputW(sec, "Egg Minus Threshold", "Deficit that triggers the rejoin (e.g. 20).",
				function() return tostring(CFG.hatchRejoinMinusThreshold or 20) end,
				function(t) CFG.hatchRejoinMinusThreshold = tonumber(t) or 20 end)
			makeToggleW(sec, "Auto Rejoin on Egg Plus", "Rejoin the server once the egg surplus hits the threshold.",
				function() return CFG.hatchRejoinPlusEnabled end,
				function(v)
					CFG.hatchRejoinPlusEnabled = v
					if v and ctx.startEggMinusWatcher then pcall(function() ctx.startEggMinusWatcher() end) end
					if not v and not CFG.hatchRejoinMinusEnabled and ctx.stopEggMinusWatcher then
						pcall(function() ctx.stopEggMinusWatcher() end)
					end
				end)
			makeInputW(sec, "Egg Plus Threshold", "Surplus that triggers the rejoin (e.g. 20).",
				function() return tostring(CFG.hatchRejoinPlusThreshold or 20) end,
				function(t) CFG.hatchRejoinPlusThreshold = tonumber(t) or 20 end)
			makeInputW(sec, "Hatch Webhook URL", "Webhook alert for bronto/special eggs (empty = off).",
				function() return tostring(CFG.hatchWebhookUrl or "") end,
				function(t) CFG.hatchWebhookUrl = tostring(t or "") end)
			addRefresh(sec)
		end)

		--------------------------------------------------- panel 4: Bronto Configuration
		miniTab("bronto", function(sec)
			sec:Paragraph({
				Title = "Sell & Bronto Rule (Bulk)",
				Desc = "Weight < KG -> action (SELL/KEEP). Weight >= KG -> KEEP + BRONTO (hatched with the Bronto team). Mark ★ Special = always Bronto + alert.",
			})

			-- Bulk editor: per-pet rule terpadu (dipakai sell & bronto).
			local bulkSel, bulkKg, bulkAction, bulkSpecial = {}, 0.8, "sell", false
			makeMultiW(sec, "Select Pet Types (Bulk)", "Select multiple pet types at once",
				reg.PET_OPTIONS, bulkSel, function() persist() end, { fillDelay = 1.0 })
			makeInputW(sec, "KG (Bulk)", "Weight threshold for the selected pets",
				function() return tostring(bulkKg) end,
				function(t) bulkKg = tonumber(t) or 0.8 end)
			makeSingleW(sec, "Below KG Action (Bulk)", "Action when weight is below the threshold",
				function() return { "sell", "keep" } end,
				function() return bulkAction end,
				function(v) bulkAction = (v == "keep") and "keep" or "sell" end, { fillDelay = 1.1 })
			makeToggleW(sec, "Special Pet (Bulk)", "Mark the selected pets as Special (★ alert & Bronto).",
				function() return bulkSpecial end,
				function(v) bulkSpecial = v end)

			local remVal, remRefresh = nil, nil
			sec:Button({
				Title = "APPLY BULK LIST",
				Desc = "Apply the rules above to all selected pets (overwrites existing rules).",
				Callback = safe(function()
					CFG.hatchSellList = CFG.hatchSellList or {}
					local n = 0
					for name in pairs(bulkSel) do
						CFG.hatchSellList[name] = {
							kg = tonumber(bulkKg) or 0.8,
							action = (bulkAction == "keep") and "KEEP" or "SELL",
							special = bulkSpecial == true,
						}
						n = n + 1
					end
					if n > 0 then
						persist()
						ctx.log(("Hatch: %d bulk rules applied"):format(n))
						if remRefresh then pcall(remRefresh) end
						W.notify("Hatch", n .. " rules applied")
					end
				end),
			})

			remCtrl, remRefresh = makeSingleW(sec, "Pick Rule to Remove",
				"Rules listed in the Sell & Bronto Config.",
				function()
					local list = {}
					for k in pairs(CFG.hatchSellList or {}) do list[#list + 1] = k end
					table.sort(list)
					return list
				end,
				function() return remVal end,
				function(v) remVal = v end, { register = true, fillDelay = 1.2 })

			sec:Button({
				Title = "Remove Selected Rule",
				Desc = "Delete the pet rule selected in the dropdown above.",
				Callback = safe(function()
					if remVal and CFG.hatchSellList then
						CFG.hatchSellList[remVal] = nil
						remVal = nil
						persist()
						if remRefresh then pcall(remRefresh) end
						ctx.log("Hatch: rule removed")
					end
				end),
			})

			sec:Button({
				Title = "CLEAR ALL RULES",
				Desc = "Delete ALL Sell & Bronto rules.",
				Callback = safe(function()
					CFG.hatchSellList = {}
					persist()
					if remRefresh then pcall(remRefresh) end
					ctx.log("Hatch: all rules removed")
				end),
			})

			makeToggleW(sec, "Don't Hatch Special Pets", "Skip special pets entirely (never hatch them).",
				function() return CFG.brontoSkipSpecial end,
				function(v) CFG.brontoSkipSpecial = v end)
			addRefresh(sec)
		end)

		--------------------------------------------------- panel 5: Sell Configuration
		miniTab("sell", function(sec)
			makeMultiW(sec, "Pets to Sell", "Pet types TO SELL (the rest get favorited for safety)",
				reg.PET_OPTIONS, CFG.sellPetTypes, function() persist() end, { fillDelay = 1.0 })
			makeInputW(sec, "Sell Weight Threshold", "Sell when weight is below this (0 = off)",
				function() return tostring(CFG.sellWeightThreshold or 0) end,
				function(t) CFG.sellWeightThreshold = tonumber(t) or 0 end)
			makeInputW(sec, "Sell Age Threshold", "Sell when age is below this (0 = off)",
				function() return tostring(CFG.sellAgeThreshold or 0) end,
				function(t) CFG.sellAgeThreshold = tonumber(t) or 0 end)
			makeMultiW(sec, "Special Pets to Sell", "Special pets (sold by weight)",
				reg.PET_EGG_ONLY, CFG.sellSpecialTypes, function() persist() end, { fillDelay = 1.1 })
			makeInputW(sec, "Special Pet Weight Threshold", "Sell special pets with weight below this (0 = off)",
				function() return tostring(CFG.sellSpecialWeight or 0) end,
				function(t) CFG.sellSpecialWeight = tonumber(t) or 0 end)

			sec:Paragraph({
				Title = "Trigger & Execution",
				Desc = "When selling runs and how.",
			})
			makeSingleW(sec, "Sell Trigger", "Cycle = sell every N hatch cycles. Backpack = sell once pets reach the limit.",
				function() return { "Cycle", "Backpack" } end,
				function() return CFG.sellMode or "Cycle" end,
				function(v) CFG.sellMode = (v == "Backpack") and "Backpack" or "Cycle" end, { fillDelay = 1.2 })
			makeInputW(sec, "Sell Every N Cycles", "Used when Sell Trigger = Cycle.",
				function() return tostring(CFG.sellEveryNCycles or 1) end,
				function(t) CFG.sellEveryNCycles = math.max(1, tonumber(t) or 1) end)
			makeInputW(sec, "Auto Sell At Total Pets", "Used when Sell Trigger = Backpack.",
				function() return tostring(CFG.sellWhenReach or 100) end,
				function(t) CFG.sellWhenReach = tonumber(t) or 100 end)
			makeSingleW(sec, "Sell Style", "One by One = sell only matching pets (safe). All at Once = sell every matching non-favorited pet.",
				function() return { "One by One", "All at Once" } end,
				function() return CFG.sellStyle or "All at Once" end,
				function(v) CFG.sellStyle = (v == "One by One") and "One by One" or "All at Once" end, { fillDelay = 1.3 })
			makeToggleW(sec, "Auto Boost Before Sell", "Boost active pets with toys before selling",
				function() return CFG.autoBoostBeforeSell end,
				function(v) CFG.autoBoostBeforeSell = v end)
			sec:Button({
				Title = "Sell Now (manual)", Desc = "Run the sell process once, right now.",
				Callback = safe(function()
					if ctx.hatchDoSell then task.spawn(function() pcall(ctx.hatchDoSell) end) end
				end),
			})
			addRefresh(sec)
		end)

		-- 2 baris: atas = Status/Teams/Egg (run), bawah = Sell/Bronto (rule)
		miniBar(hsecs, horder, hdefs, "ctrl", { { "ctrl", "teams", "eggs" }, { "sell", "bronto" } })
	end

	----------------------------------------------------------------- live status helper (dipakai Elephant & Leveling)
	-- Paragraph tipu + loop SetDesc kala teks berubah (pola addStatus di INVENTORY
	-- tapi generic). Cache teks terakhir biar gak bersaing dgn layout dist.
	local function liveStatus(sec, title, getTxt, interval)
		local stat = sec:Paragraph({ Title = title, Desc = "Loading stats..." })
		task.spawn(function()
			task.wait(3)
			local last = ""
			while ctx.alive() do
				pcall(function()
					local txt = getTxt()
					if txt and txt ~= last and txt ~= "" then
						last = txt
						stat:SetDesc(txt)
					end
				end)
				task.wait(interval or 1.5)
			end
		end)
	end

	----------------------------------------------------------------- TAB: ELEPHANT (V1 + V2 Swap 40)
	local function buildElephantTab(tab)
		local edefs = {
			v1 = { name = "Elephant V1" },
			v2 = { name = "Elephant V2 (Swap 40)" },
		}
		local eorder = { "v1", "v2" }
		local esecs = {}

		local function miniTab(id, buildFn)
			local sec = section(tab, edefs[id].name)
			buildFn(sec)
			esecs[id] = sec
		end

		-- panel 1: Automation Elephant V1 (penempatan = garden Elephant V1)
		miniTab("v1", function(sec)
			liveStatus(sec, "Elephant V1 Status", function()
				local ok, s = pcall(function() return ctx.getElephantSummary() end)
				if not ok or not s then return nil end
				local col = s.status == "ACTIVE" and "#5acc78" or "#dc5050"
				return ("Automation Status: <font color=\"%s\"><b>%s</b></font>\n\n" ..
					"Elephant Team: <font color=\"#8c929e\">%s</font>\n" ..
					"Target Types: <font color=\"#f5c82d\">%s</font>\n" ..
					"Target Pets Ready: <font color=\"#8c929e\">%s</font>\n" ..
					"Pets at Max KG: <font color=\"#8c929e\">%s</font>\n\n" ..
					"Max Target Pets: <font color=\"#8c929e\">%s</font>\n" ..
					"Target Weight: <font color=\"#f5c82d\"><b>%s</b></font>")
					:format(col, s.status, s.team, s.types, s.ready, s.maxKg, s.maxTarget, s.targetWeight)
			end, 1.5)
			makeMultiDynW(sec, "V1 Pet Team", "Select elephant pet team (stays in the garden)",
				function() return ctx.inventoryPetOptions(CFG.elephantTeamUuids) end,
				CFG.elephantTeamUuids, function() persist() end,
				{ register = true, cacheKey = "inv_pets", fillDelay = 0.4, max = 250 })
			makeMultiW(sec, "V1 Target Pet Types", "Select pet types to auto-elephant (all pets in game)",
				reg.PET_OPTIONS, CFG.elephantPetTypes, function() persist() end,
				{ fillDelay = 0.8 })
			makeInputW(sec, "Target Weight (KG)", "Release pets at this weight — ANY value, decimals OK (e.g. 3.5, 4.7, 6.2). No presets.",
				function() return CFG.elephantTargetWeight end,
				function(t) CFG.elephantTargetWeight = tonumber(t) or 5.5 end)
			makeToggleW(sec, "Enable Automation Elephant",
				"Rotate target pets automatically. OFF = removes all target pets from the garden.",
				function() return CFG.elephantEnabled end,
				function(v)
					CFG.elephantEnabled = v; persist()
					if v then
						if ctx.startElephant then pcall(function() ctx.startElephant() end) end
					else
						if ctx.stopElephant then pcall(function() ctx.stopElephant() end) end
					end
				end)
			addRefresh(sec)
		end)

		-- panel 2: Automation Elephant V2 (swap gajah di trigger level)
		miniTab("v2", function(sec)
			liveStatus(sec, "Elephant V2 Status", function()
				local ok, s = pcall(function() return ctx.getElephantV2Summary() end)
				if not ok or not s then return nil end
				local col = s.status == "ACTIVE" and "#5acc78" or "#dc5050"
				return ("Automation Status: <font color=\"%s\"><b>%s</b></font>  |  <font color=\"#f5c82d\">%s</font>\n\n" ..
					"Elephant Team: <font color=\"#8c929e\">%s</font>\n" ..
					"Target Types: <font color=\"#f5c82d\">%s</font>\n" ..
					"Target Pets Ready: <font color=\"#8c929e\">%s</font>\n" ..
					"Pets at Max KG: <font color=\"#8c929e\">%s</font>\n" ..
					"Max Target Pets: <font color=\"#8c929e\">%s</font>  |  Target Weight: <font color=\"#f5c82d\"><b>%s</b></font>\n\n" ..
					"Elephant: <font color=\"#8c929e\">%s</font>\n" ..
					"Switch: <font color=\"#8c929e\">%s</font>\n" ..
					"Elephant enters at target Age >= <font color=\"#f5c82d\"><b>%s</b></font>")
					:format(col, s.status, tostring(s.info), s.team, s.types, s.ready, s.maxKg,
						s.maxTarget, s.targetWeight, s.gajah, s.switch, s.level)
			end, 1.5)
			makeMultiDynW(sec, "V2 Elephant Team", "Team standing by in the garden (source of the Pet Switch choice)",
				function() return ctx.inventoryPetOptions(CFG.elephantV2Team) end,
				CFG.elephantV2Team, function() persist() end,
				{ register = true, cacheKey = "inv_pets", fillDelay = 0.6, max = 250 })
			makeMultiW(sec, "V2 Target Pet Types", "Select pet types to auto-level + elephant (all pets in game)",
				reg.PET_OPTIONS, CFG.elephantV2Types, function() persist() end,
				{ fillDelay = 1.0 })
			makeSingleW(sec, "Elephant Pet (Slot 1)", "The elephant sent in when a target reaches the trigger level",
				function() return ctx.elephantV2GajahOptions() end,
				function() return CFG.elephantV2Gajah end,
				function(uuid) CFG.elephantV2Gajah = uuid end,
				{ fillDelay = 1.2 })
			makeSingleW(sec, "Pet Switch (Slot 2)", "Pet from the Team that the Elephant replaces (usually Capy)",
				function() return ctx.elephantV2SwitchOptions() end,
				function() return CFG.elephantV2Switch end,
				function(uuid) CFG.elephantV2Switch = uuid end,
				{ fillDelay = 1.4 })
			makeInputW(sec, "Target Weight (KG)", "Release pets at this weight — ANY value, decimals OK (e.g. 3.5, 4.7, 6.2). No presets.",
				function() return CFG.elephantV2Weight end,
				function(t) CFG.elephantV2Weight = tonumber(t) or 5.5 end)
			makeInputW(sec, "Trigger Level", "Target level to send the Elephant in (default 40)",
				function() return CFG.elephantV2Level end,
				function(t) CFG.elephantV2Level = math.floor(tonumber(t) or 40) end)
			makeToggleW(sec, "Enable Elephant V2",
				"Rotate targets + auto-swap the Gajah at the trigger level. Runs together with PNP.",
				function() return CFG.elephantV2Enabled end,
				function(v)
					CFG.elephantV2Enabled = v; persist()
					if v then
						if ctx.startElephantV2 then pcall(function() ctx.startElephantV2() end) end
					else
						if ctx.stopElephantV2 then pcall(function() ctx.stopElephantV2() end) end
					end
				end)
			addRefresh(sec)
		end)

		miniBar(esecs, eorder, edefs, "v1")
	end

	----------------------------------------------------------------- TAB: FLOW (growth pipeline)
	local function buildFlowTab(tab)
		local fdefs = {
			flow     = { name = "Flow Config" },
			elephant = { name = "Elephant" },
			mut      = { name = "Mutation" },
			level    = { name = "Leveling" },
		}
		local forder = { "flow", "elephant", "mut", "level" }
		local fsecs = {}

		local function miniTab(id, buildFn)
			local sec = section(tab, fdefs[id].name)
			buildFn(sec)
			fsecs[id] = sec
		end

		-- panel 1: Flow Config (Controls & Targets + Configuration Flow)
		miniTab("flow", function(sec)
			makeMultiW(sec, "Flow Target Pet Types (Default)",
				"Default targets; used by any step whose own target types are empty",
				reg.PET_OPTIONS, CFG.growthPetTypes, function() persist() end,
				{ fillDelay = 0.4 })
			-- Step 1..6 pipeline — penempatan sama garden, opsi None/Elephant/
			-- Mutation/Leveling/P1/P2.
			local FLOW_OPTS = {
				{ name = "none",         display = "None (empty)" },
				{ name = "elephant",     display = "Elephant" },
				{ name = "mutation",     display = "Mutation" },
				{ name = "leveling",     display = "Leveling" },
				{ name = "leveling_p1",  display = "Leveling Phase 1" },
				{ name = "leveling_p2",  display = "Leveling Phase 2" },
			}
			local function capStep(s)
				for _, o in ipairs(FLOW_OPTS) do
					if o.name == s then return o.display end
				end
				return "Select"
			end
			local stepDesc = {
				"First step in pipeline flow", "Second step in pipeline flow",
				"Third step in pipeline flow", "Fourth step in pipeline flow",
				"Fifth step in pipeline flow", "Sixth step in pipeline flow",
			}
			for i = 1, 6 do
				makeSingleW(sec, "Step " .. i, stepDesc[i],
					function() return FLOW_OPTS end,
					function() return capStep((CFG.growthFlow or {})[i]) end,
					function(code)
						CFG.growthFlow = CFG.growthFlow or {}
						CFG.growthFlow[i] = code
						persist()
					end)
			end
			makeToggleW(sec, "Enable Automation Growth (Flow)", "Runs the step pipeline above in order.",
				function() return CFG.growthEnabled end,
				function(v)
					CFG.growthEnabled = v; persist()
					if v then
						if ctx.startGrowth then pcall(function() ctx.startGrowth() end) end
					else
						if ctx.stopGrowth then pcall(function() ctx.stopGrowth() end) end
					end
				end)
		end)

		-- panel 2: step Elephant
		miniTab("elephant", function(sec)
			makeMultiW(sec, "Elephant Target Pet Types", "Targets for the Elephant step (empty = use Default)",
				reg.PET_OPTIONS, CFG.growthPetTypesElephant, function() persist() end,
				{ fillDelay = 0.6 })
			makeMultiDynW(sec, "Elephant Pet Team", "Aura team used to grow weight",
				function() return ctx.inventoryPetOptions(CFG.growthElephantTeam) end,
				CFG.growthElephantTeam, function() persist() end,
				{ register = true, cacheKey = "inv_pets", fillDelay = 0.8, max = 250 })
			makeInputW(sec, "Target Weight (KG)", "Target weight before moving to the next step (e.g. 5.5)",
				function() return CFG.growthElephantWeight end,
				function(t) CFG.growthElephantWeight = tonumber(t) or 5.5 end)
			makeInputW(sec, "Max Target Pets", "Max target pets in the garden (Elephant step)",
				function() return CFG.growthElephantMax end,
				function(t) CFG.growthElephantMax = math.max(1, math.floor(tonumber(t) or 2)) end)
			addRefresh(sec)
		end)

		-- panel 3: step Mutation
		miniTab("mut", function(sec)
			makeMultiW(sec, "Mutation Target Pet Types", "Targets for the Mutation step (empty = use Default)",
				reg.PET_OPTIONS, CFG.growthPetTypesMutation, function() persist() end,
				{ fillDelay = 0.6 })
			makeMultiDynW(sec, "Mutation Pet Team", "Aura team that gives mutations",
				function() return ctx.inventoryPetOptions(CFG.growthMutationTeam) end,
				CFG.growthMutationTeam, function() persist() end,
				{ register = true, cacheKey = "inv_pets", fillDelay = 0.8, max = 250 })
			makeMultiW(sec, "Target Mutations", "Desired mutations (wrong mutations get auto cleansed)",
				reg.MUT_OPTIONS, CFG.growthMutationTargets, function() persist() end,
				{ fillDelay = 1.0 })
			makeInputW(sec, "Max Target Pets", "Max target pets in the garden (Mutation step)",
				function() return CFG.growthMutationMax end,
				function(t) CFG.growthMutationMax = math.max(1, math.floor(tonumber(t) or 2)) end)
			addRefresh(sec)
		end)

		-- panel 4: step Leveling
		miniTab("level", function(sec)
			makeMultiW(sec, "Leveling Target Pet Types", "Targets for the Leveling step (empty = use Default)",
				reg.PET_OPTIONS, CFG.growthPetTypesLeveling, function() persist() end,
				{ fillDelay = 0.6 })
			makeMultiDynW(sec, "Leveling Phase 1 Pet Team", "Team for Phase 1 (Age 1 to Phase 1 Target)",
				function() return ctx.inventoryPetOptions(CFG.growthLevP1Team) end,
				CFG.growthLevP1Team, function() persist() end,
				{ register = true, cacheKey = "inv_pets", fillDelay = 0.8, max = 250 })
			makeInputW(sec, "Leveling Phase 1 Target", "End of Phase 1 / start of Phase 2 (default 40)",
				function() return CFG.growthLevP1Target end,
				function(t) CFG.growthLevP1Target = math.floor(tonumber(t) or 40) end)
			makeInputW(sec, "Leveling Phase 1 Max Pets", "Max target pets in garden during Phase 1",
				function() return CFG.growthLevP1Max end,
				function(t) CFG.growthLevP1Max = math.max(1, math.floor(tonumber(t) or 3)) end)
			makeMultiDynW(sec, "Leveling Phase 2 Pet Team", "Team for Phase 2 (Phase 1 Target to Final Target)",
				function() return ctx.inventoryPetOptions(CFG.growthLevP2Team) end,
				CFG.growthLevP2Team, function() persist() end,
				{ register = true, cacheKey = "inv_pets", fillDelay = 1.0, max = 250 })
			makeInputW(sec, "Leveling Phase 2 Target", "Final target level (default 500 = max age)",
				function() return CFG.growthLevP2Target end,
				function(t) CFG.growthLevP2Target = math.floor(tonumber(t) or 500) end)
			makeInputW(sec, "Leveling Phase 2 Max Pets", "Max target pets in garden during Phase 2",
				function() return CFG.growthLevP2Max end,
				function(t) CFG.growthLevP2Max = math.max(1, math.floor(tonumber(t) or 1)) end)
			addRefresh(sec)
		end)

		miniBar(fsecs, forder, fdefs, "flow", { { "flow", "elephant" }, { "mut", "level" } })
	end

	----------------------------------------------------------------- TAB: LEVELING (V1 + V2 2-phase)
	local function buildLevelingTab(tab)
		local ldefs = {
			v1 = { name = "Leveling V1" },
			v2 = { name = "Leveling V2" },
		}
		local lorder = { "v1", "v2" }
		local lsecs = {}

		local function miniTab(id, buildFn)
			local sec = section(tab, ldefs[id].name)
			buildFn(sec)
			lsecs[id] = sec
		end

		-- panel 1: Automation Leveling V1
		miniTab("v1", function(sec)
			liveStatus(sec, "Leveling V1 Status", function()
				local ok, s = pcall(function() return ctx.getLevelingSummary() end)
				if not ok or not s then return nil end
				local col = s.status == "ACTIVE" and "#5acc78" or "#dc5050"
				return ("Automation Status: <font color=\"%s\"><b>%s</b></font>\n\n" ..
					"<b>Current Settings:</b>\n" ..
					"Pet Team: <font color=\"#8c929e\">%s</font>\n" ..
					"Target Types: <font color=\"#f5c82d\">%s</font>\n" ..
					"Pets Ready to Level: <font color=\"#8c929e\">%s</font>\n" ..
					"Pets at Max Level: <font color=\"#8c929e\">%s</font>\n" ..
					"Max in Garden: <font color=\"#8c929e\">%s</font>\n\n" ..
					"Target Level: <font color=\"#f5c82d\"><b>%s</b></font>\n\n" ..
					"Ready: Settings configured")
					:format(col, s.status, s.team, s.types, s.ready, s.maxLvl, s.maxInGarden, s.targetLevel)
			end, 1.5)
			makeMultiDynW(sec, "Leveling Pet Team", "Select pets to keep in the garden while leveling",
				function() return ctx.inventoryPetOptions(CFG.levelingTeamUuids) end,
				CFG.levelingTeamUuids, function() persist() end,
				{ register = true, cacheKey = "inv_pets", fillDelay = 0.4, max = 250 })
			makeMultiW(sec, "Leveling Pet Types", "Select pet types to auto-level (all pets in game)",
				reg.PET_OPTIONS, CFG.levelingPetTypes, function() persist() end,
				{ fillDelay = 0.8 })
			makeInputW(sec, "Target Level", "Target level to reach before un-equipping",
				function() return CFG.levelingTargetLevel end,
				function(t) CFG.levelingTargetLevel = math.floor(tonumber(t) or 500) end)
			makeInputW(sec, "Max Pets in Garden", "Maximum active leveling pets allowed in the garden",
				function() return CFG.levelingMaxPets end,
				function(t) CFG.levelingMaxPets = math.max(1, math.floor(tonumber(t) or 2)) end)
			makeToggleW(sec, "Enable Automation Leveling", "Equips and rotates pets automatically based on the settings above.",
				function() return CFG.levelingEnabled end,
				function(v)
					CFG.levelingEnabled = v; persist()
					if v then
						if ctx.startLeveling then pcall(function() ctx.startLeveling() end) end
					else
						if ctx.stopLeveling then pcall(function() ctx.stopLeveling() end) end
					end
				end)
			addRefresh(sec)
		end)

		-- panel 2: Automation Leveling V2 (2 fase)
		miniTab("v2", function(sec)
			liveStatus(sec, "Leveling V2 Status", function()
				local ok, s = pcall(function() return ctx.getLevelingV2Summary() end)
				if not ok or not s then return nil end
				local col = s.status == "ACTIVE" and "#5acc78" or "#dc5050"
				return ("Automation Status: <font color=\"%s\"><b>%s</b></font>  |  <font color=\"#f5c82d\">%s</font>\n\n" ..
					"<b>Target Types:</b> <font color=\"#8c929e\">%s</font>\n\n" ..
					"<b>Phase 1</b> (->%s): team <font color=\"#8c929e\">%s</font> | queued <font color=\"#f5c82d\">%s</font> pet\n" ..
					"<b>Phase 2</b> (->%s): team <font color=\"#8c929e\">%s</font> | queued <font color=\"#f5c82d\">%s</font> pet\n" ..
					"<b>Pet at Max Level:</b> <font color=\"#5acc78\">%s</font> pet")
					:format(col, s.status, tostring(s.phase), tostring(s.types),
						tostring(s.p1target), tostring(s.p1team), tostring(s.p1queue),
						tostring(s.p2target), tostring(s.p2team), tostring(s.p2queue),
						tostring(s.maxLvl or 0))
			end, 1.5)
			makeMultiW(sec, "Leveling Target Pet Types", "Pet types to level up (all pets in game)",
				reg.PET_OPTIONS, CFG.levelingV2PetTypes, function() persist() end,
				{ fillDelay = 0.6 })
			makeMultiDynW(sec, "Leveling Phase 1 Pet Team", "Team for Phase 1 (Age 1 to Phase 1 Target)",
				function() return ctx.inventoryPetOptions(CFG.levelingV2P1Team) end,
				CFG.levelingV2P1Team, function() persist() end,
				{ register = true, cacheKey = "inv_pets", fillDelay = 0.8, max = 250 })
			makeInputW(sec, "Leveling Phase 1 Target", "End of Phase 1 / start of Phase 2 (default 40)",
				function() return CFG.levelingV2P1Target end,
				function(t) CFG.levelingV2P1Target = math.floor(tonumber(t) or 40) end)
			makeInputW(sec, "Leveling Phase 1 Max Pets", "Max target pets in garden during Phase 1",
				function() return CFG.levelingV2P1Max end,
				function(t) CFG.levelingV2P1Max = math.max(1, math.floor(tonumber(t) or 3)) end)
			makeMultiDynW(sec, "Leveling Phase 2 Pet Team", "Team for Phase 2 (Phase 1 Target to Final Target)",
				function() return ctx.inventoryPetOptions(CFG.levelingV2P2Team) end,
				CFG.levelingV2P2Team, function() persist() end,
				{ register = true, cacheKey = "inv_pets", fillDelay = 1.0, max = 250 })
			makeInputW(sec, "Leveling Phase 2 Target", "Final target level (default 500 = max age)",
				function() return CFG.levelingV2P2Target end,
				function(t) CFG.levelingV2P2Target = math.floor(tonumber(t) or 500) end)
			makeInputW(sec, "Leveling Phase 2 Max Pets", "Max target pets in garden during Phase 2",
				function() return CFG.levelingV2P2Max end,
				function(t) CFG.levelingV2P2Max = math.max(1, math.floor(tonumber(t) or 1)) end)
			makeToggleW(sec, "Enable Automation Leveling V2", "Levels pets in 2 stages (Phase 1 team -> Phase 2 team).",
				function() return CFG.levelingV2Enabled end,
				function(v)
					CFG.levelingV2Enabled = v; persist()
					if v then
						if ctx.startLevelingV2 then pcall(function() ctx.startLevelingV2() end) end
					else
						if ctx.stopLevelingV2 then pcall(function() ctx.stopLevelingV2() end) end
					end
				end)
			addRefresh(sec)
		end)

		miniBar(lsecs, lorder, ldefs, "v1")
	end

	----------------------------------------------------------------- TAB: MUTATION (Machine + Aura Cleanse)
	local function buildMutationTab(tab)
		local mdefs = {
			machine = { name = "Machine" },
			cleanse = { name = "Aura Cleanse" },
		}
		local morder = { "machine", "cleanse" }
		local msecs = {}

		local function miniTab(id, buildFn)
			local sec = section(tab, mdefs[id].name)
			buildFn(sec)
			msecs[id] = sec
		end

		-- panel 1: Mutation Machine
		miniTab("machine", function(sec)
			liveStatus(sec, "Mutation Machine Status", function()
				local ok, s = pcall(function() return ctx.getMutationSummary() end)
				if not ok or not s then return nil end
				local col = s.status == "ACTIVE" and "#5acc78" or "#dc5050"
				return ("Status: <font color=\"%s\"><b>%s</b></font>\n" ..
					"Phase: <b>%s</b>\n\n" ..
					"EXP Team: <font color=\"#8c929e\">%s pets</font>\n" ..
					"Boost Team: <font color=\"#8c929e\">%s pets</font>\n" ..
					"Phoenix Team: <font color=\"#8c929e\">%s pets</font>\n\n" ..
					"Target Types: <font color=\"#f5c82d\">%s</font>\n" ..
					"Keep Mutations: <font color=\"#f5c82d\">%s</font>\n" ..
					"Target Age: <font color=\"#f5c82d\"><b>%s</b></font>\n\n" ..
					"Machine: <font color=\"#85d0ff\"><b>%s</b></font>\n\n" ..
					"Target Pets Ready: <font color=\"#8c929e\">%s pets</font>\n" ..
					"Target Pets Done: <font color=\"#5acc78\"><b>%s pets</b></font>")
					:format(col, s.status, tostring(s.phase), tostring(s.expCount), tostring(s.boostCount),
						tostring(s.phoenixCount), tostring(s.types), tostring(s.mutations),
						tostring(s.targetAge), tostring(s.machine), tostring(s.readyCount), tostring(s.doneCount))
			end, 1.5)
			makeMultiDynW(sec, "EXP Team (Leveling)", "Pets for leveling the target to age 50/500",
				function() return ctx.inventoryPetOptions(CFG.mutationExpTeam) end,
				CFG.mutationExpTeam, function() persist() end,
				{ register = true, cacheKey = "inv_pets", fillDelay = 0.4, max = 250 })
			makeMultiDynW(sec, "Boost Team (Machine)", "Pets for boosting the mutation machine speed",
				function() return ctx.inventoryPetOptions(CFG.mutationBoostTeam) end,
				CFG.mutationBoostTeam, function() persist() end,
				{ register = true, cacheKey = "inv_pets", fillDelay = 0.6, max = 250 })
			makeMultiDynW(sec, "Phoenix Team (Claim)", "Pets for claiming the mutated pet",
				function() return ctx.inventoryPetOptions(CFG.mutationPhoenixTeam) end,
				CFG.mutationPhoenixTeam, function() persist() end,
				{ register = true, cacheKey = "inv_pets", fillDelay = 0.8, max = 250 })
			makeMultiW(sec, "Target Pet Types", "Pet types to mutate (all pets in game)",
				reg.PET_OPTIONS, CFG.mutationTargetTypes, function() persist() end,
				{ fillDelay = 1.0 })
			makeMultiW(sec, "Target Mutations (Machine)", "Stop when the pet gets these mutations (machine mutations only)",
				reg.MACHINE_MUT_OPTIONS or reg.MUT_OPTIONS, CFG.mutationTargetMutations, function() persist() end,
				{ fillDelay = 1.2 })
			makeInputW(sec, "Target Age", "Level to reach before submitting (e.g. 50 or 500)",
				function() return CFG.mutationTargetAge end,
				function(t) CFG.mutationTargetAge = math.floor(tonumber(t) or 50) end)
			makeInputW(sec, "Delay Auto Claim (sec)", "Wait before claiming the mutated pet from the machine",
				function() return CFG.mutationDelayAutoClaim end,
				function(t) CFG.mutationDelayAutoClaim = tonumber(t) or 0.5 end)
			makeToggleW(sec, "Enable Auto Mutation Machine", "Submits, starts, and claims mutated pets automatically.",
				function() return CFG.mutationEnabled end,
				function(v)
					CFG.mutationEnabled = v; persist()
					if v then
						if ctx.startMutation then pcall(function() ctx.startMutation() end) end
					else
						if ctx.stopMutation then pcall(function() ctx.stopMutation() end) end
					end
				end)
			addRefresh(sec)
		end)

		-- panel 2: Aura Cleanse (mutasi via aura + cleanse salah)
		miniTab("cleanse", function(sec)
			liveStatus(sec, "Aura Mutation Status", function()
				local ok, s = pcall(function() return ctx.getCleanseSummary() end)
				if not ok or not s then return nil end
				local col = s.status == "ACTIVE" and "#5acc78" or "#dc5050"
				local already = ""
				if type(s.keepOrder) == "table" and type(s.already) == "table" then
					for _, k in ipairs(s.keepOrder) do
						already = already .. ("- Already %s: <font color=\"#8c929e\">%s pets</font>\n")
							:format(tostring(k), tostring(s.already[k] or 0))
					end
				end
				return ("Automation Status: <font color=\"%s\"><b>%s</b></font>\n\n" ..
					"Mutation Team: <font color=\"#8c929e\">%s pets</font>\n" ..
					"Target Types: <font color=\"#f5c82d\">%s</font>\n" ..
					"Mutations to Keep: <font color=\"#f5c82d\">%s</font>\n\n" ..
					"Pet Statistics:\n" ..
					"- Pets Ready to Mutation: <font color=\"#8c929e\">%s pets</font>\n" ..
					"%s\n" ..
					"Max in Garden: <font color=\"#8c929e\">%s pets</font>\n\n" ..
					"Status: <font color=\"#85d0ff\">%s</font>")
					:format(col, s.status, tostring(s.team), tostring(s.types), tostring(s.keep),
						tostring(s.ready), already, tostring(s.maxPets), tostring(s.phase))
			end, 1.5)
			makeMultiDynW(sec, "Pet Team for Mutation", "Mutation aura pets (stay in the garden)",
				function() return ctx.inventoryPetOptions(CFG.cleanseTeamUuids) end,
				CFG.cleanseTeamUuids, function() persist() end,
				{ register = true, cacheKey = "inv_pets", fillDelay = 0.6, max = 250 })
			makeMultiW(sec, "Pet Types for Mutation", "Target pet types to mutate (all pets in game)",
				reg.PET_OPTIONS, CFG.cleansePetTypes, function() persist() end,
				{ fillDelay = 0.8 })
			makeMultiW(sec, "Mutations to Keep", "These mutations are kept (won't be cleansed)",
				reg.MUT_OPTIONS, CFG.cleanseKeepMutations, function() persist() end,
				{ fillDelay = 1.0 })
			makeInputW(sec, "Max Pets in Garden", "Max target pets in the garden at once",
				function() return CFG.cleanseMaxPets end,
				function(t) CFG.cleanseMaxPets = math.max(1, math.floor(tonumber(t) or 2)) end)
			makeToggleW(sec, "Enable Auto Mutation", "Mutates targets via aura; cleanses wrong mutations, keeps the kept ones.",
				function() return CFG.cleanseEnabled end,
				function(v)
					CFG.cleanseEnabled = v; persist()
					if v then
						if ctx.startCleanse then pcall(function() ctx.startCleanse() end) end
					else
						if ctx.stopCleanse then pcall(function() ctx.stopCleanse() end) end
					end
				end)
			addRefresh(sec)
		end)

		miniBar(msecs, morder, mdefs, "machine")
	end

	----------------------------------------------------------------- TAB: SHOP (Seeds/Eggs/Gears/Merchant/Premium)
	local function buildShopTab(tab)
		local sdefs = {
			seed     = { name = "Seeds" },
			egg      = { name = "Eggs" },
			gear     = { name = "Gears" },
			merchant = { name = "Merchant" },
			premium  = { name = "Premium" },
		}
		local sorder = { "seed", "egg", "gear", "merchant", "premium" }
		local ssecs = {}

		local function miniTab(id, buildFn)
			local sec = section(tab, sdefs[id].name)
			buildFn(sec)
			ssecs[id] = sec
		end

		-- panel 1-3: Buy Seed / Egg / Gear (placement sama garden)
		miniTab("seed", function(sec)
			makeMultiDynW(sec, "Select Seeds to Buy", "Pick seeds to auto-buy (live stock)",
				function() return ctx.getSeedShopOptions(CFG.buySeedNames) end,
				CFG.buySeedNames, function() persist() end,
				{ register = true, cacheKey = "shop_seed", fillDelay = 0.4 })
			makeToggleW(sec, "Enable Automation Buy Seed", "Auto-buys the selected seeds whenever they are in stock.",
				function() return CFG.buySeedEnabled end,
				function(v)
					CFG.buySeedEnabled = v; persist()
					if v and ctx.startBuySeed then pcall(function() ctx.startBuySeed() end) end
				end)
			addRefresh(sec)
		end)
		miniTab("egg", function(sec)
			makeMultiDynW(sec, "Select Eggs to Buy", "Pick eggs to auto-buy (live stock)",
				function() return ctx.getEggShopOptions(CFG.buyEggNames) end,
				CFG.buyEggNames, function() persist() end,
				{ register = true, cacheKey = "shop_egg", fillDelay = 0.6 })
			makeToggleW(sec, "Enable Automation Buy Egg", "Auto-buys the selected eggs whenever they are in stock.",
				function() return CFG.buyEggEnabled end,
				function(v)
					CFG.buyEggEnabled = v; persist()
					if v and ctx.startBuyEgg then pcall(function() ctx.startBuyEgg() end) end
				end)
			addRefresh(sec)
		end)
		miniTab("gear", function(sec)
			makeMultiDynW(sec, "Select Gear to Buy", "Pick gear to auto-buy (live stock)",
				function() return ctx.getGearShopOptions(CFG.buyGearNames) end,
				CFG.buyGearNames, function() persist() end,
				{ register = true, cacheKey = "shop_gear", fillDelay = 0.8 })
			makeToggleW(sec, "Enable Automation Buy Gear", "Auto-buys the selected gear whenever it is in stock.",
				function() return CFG.buyGearEnabled end,
				function(v)
					CFG.buyGearEnabled = v; persist()
					if v and ctx.startBuyGear then pcall(function() ctx.startBuyGear() end) end
				end)
			addRefresh(sec)
		end)

		-- panel 4: Merchant (item selection per merchant + toggles + Open Shop UI)
		miniTab("merchant", function(sec)
			liveStatus(sec, "Merchant Status", function()
				local ok, s = pcall(function() return ctx.getMerchantSummary() end)
				if not ok or not s then return nil end
				local lines = {}
				if s.activeMerchant then
					lines[#lines + 1] = ("Active Traveling: <font color=\"#5acc78\"><b>%s</b></font>"):format(tostring(s.activeMerchant))
				else
					lines[#lines + 1] = "Active Traveling: <font color=\"#dc5050\">None</font>"
				end
				if s.mode == "all" then
					lines[#lines + 1] = "Mode: <font color=\"#f5c82d\"><b>Buy ALL items (All)</b></font>"
				elseif s.mode == "best" then
					lines[#lines + 1] = "Mode: <font color=\"#f5c82d\"><b>Buy the MOST EXPENSIVE item (Best)</b></font>"
				elseif type(s.picks) == "table" and #s.picks > 0 then
					lines[#lines + 1] = "Selected items to buy:"
					for _, p in ipairs(s.picks) do
						local parts = {}
						for _, it in ipairs(p.items or {}) do
							if it.price then
								local a = math.abs(it.price)
								local num
								if a >= 1e9 then num = ("%sb"):format(("%0.2f"):format(it.price / 1e9))
								elseif a >= 1e6 then num = ("%sm"):format(("%0.2f"):format(it.price / 1e6))
								elseif a >= 1e3 then num = ("%sk"):format(("%0.2f"):format(it.price / 1e3))
								else num = tostring(it.price) end
								parts[#parts + 1] = ("%s (%s)"):format(tostring(it.name), num)
							else
								parts[#parts + 1] = tostring(it.name)
							end
						end
						lines[#lines + 1] = ("- <font color=\"#5acc78\"><b>%s</b></font>: <font color=\"#f5c82d\">%s</font>")
							:format(tostring(p.title), table.concat(parts, ", "))
					end
				else
					lines[#lines + 1] = "<font color=\"#dc5050\">No items selected yet.</font> Pick in 'Select Items per Merchant' or turn on Auto Buy All/Best."
				end
				return table.concat(lines, "\n")
			end, 2)
			-- Item selection per merchant (travel) & per event shop — placement
			-- garden: dipilah dua grup, di sini jadi satu panel urut (travel dulu).
			pcall(function()
				for _, m in ipairs(ctx.getMerchantList()) do
					local kind, id, mtitle = m.kind, m.id, m.title
					local heading = (kind == "travel") and (mtitle .. " Merchant") or mtitle
					makeMultiDynW(sec, "Select Items - " .. heading,
						("Items from %s%s. 'All' = everything."):format(mtitle, (kind == "travel") and " merchant" or ""),
						function() return ctx.getMerchantItemOptions(id) end,
						ctx.merchantSelFor(id), function() persist() end,
						{ register = true, cacheKey = "merch_" .. tostring(id), fillDelay = 0.5 })
				end
			end)
			makeToggleW(sec, "Auto Buy Merchant", "Buys the selected items (merchant & event shop) whenever they appear / restock",
				function() return CFG.merchantBuyEnabled end,
				function(v)
					CFG.merchantBuyEnabled = v; persist()
					if v and ctx.startBuyMerchant then pcall(function() ctx.startBuyMerchant() end) end
				end)
			makeToggleW(sec, "Auto Buy All Merchant", "Buys EVERY item that is in stock",
				function() return CFG.merchantBuyAll end,
				function(v)
					CFG.merchantBuyAll = v; persist()
					if v and ctx.startBuyMerchant then pcall(function() ctx.startBuyMerchant() end) end
				end)
			makeToggleW(sec, "Auto Buy Best Merchant", "Buys the 1 MOST EXPENSIVE item in stock",
				function() return CFG.merchantBuyBest end,
				function(v)
					CFG.merchantBuyBest = v; persist()
					if v and ctx.startBuyMerchant then pcall(function() ctx.startBuyMerchant() end) end
				end)
			makeSingleW(sec, "Merchant UI to Open", "Event shop whose UI should be opened (one shop at a time)",
				function() return ctx.getEventShopOptions() end,
				function() return CFG.merchantUiShop end,
				function(code)
					CFG.merchantUiShop = code; persist()
					if ctx.openEventShopUI then pcall(function() ctx.openEventShopUI(code) end) end
				end)
			sec:Button({
				Title = "Open Shop UI Now", Desc = "Opens the selected shop UI now (while the shop is active).",
				Callback = safe(function()
					if ctx.openEventShopUI then pcall(function() ctx.openEventShopUI() end) end
				end),
			})
			makeToggleW(sec, "Auto Open UI", "Keeps the selected shop UI open (re-opens automatically, without the NPC)",
				function() return CFG.merchantAutoOpenUI end,
				function(v)
					CFG.merchantAutoOpenUI = v; persist()
					if v then
						if ctx.startAutoOpenUI then pcall(function() ctx.startAutoOpenUI() end) end
					elseif ctx.stopAutoOpenUI then
						pcall(function() ctx.stopAutoOpenUI() end)
					end
				end)
			addRefresh(sec)
		end)

		-- panel 5: Premium
		miniTab("premium", function(sec)
			makeSingleW(sec, "Select Item", "Select the gamepass/product to purchase",
				function() return ctx.getPremiumItemOptions() end,
				function() return CFG.premiumItem end,
				function(code)
					CFG.premiumItem = code; persist()
					if ctx.premiumShowPrice then pcall(function() ctx.premiumShowPrice() end) end
				end)
			makeSingleW(sec, "Payment Method", "Pay with Robux / in-game Token",
				function() return { { name = "robux", display = "Robux" }, { name = "token", display = "Token" } } end,
				function() return CFG.premiumPay == "token" and "Token" or "Robux" end,
				function(code) CFG.premiumPay = code; persist() end)
			sec:Button({
				Title = "Purchase Item", Desc = "Buys the selected item with the payment method above.",
				Callback = safe(function()
					if ctx.premiumBuy then pcall(function() ctx.premiumBuy() end) end
				end),
			})
			sec:Button({
				Title = "Gift to Player", Desc = "Buys the Gift variant of this item (if available).",
				Callback = safe(function()
					if ctx.premiumGift then pcall(function() ctx.premiumGift() end) end
				end),
			})
			addRefresh(sec)
		end)

		miniBar(ssecs, sorder, sdefs, "seed", { { "seed", "egg", "gear" }, { "merchant", "premium" } })
	end

	----------------------------------------------------------------- TAB: MISC (Player & ESP / Rejoin / Webhook / Performance)
	local function buildMiscTab(tab)
		local xdefs = {
			player  = { name = "Player & ESP" },
			rejoin  = { name = "Rejoin" },
			webhook = { name = "Webhook" },
			perf    = { name = "Performance" },
		}
		local xorder = { "player", "rejoin", "webhook", "perf" }
		local xsecs = {}

		local function miniTab(id, buildFn)
			local sec = section(tab, xdefs[id].name)
			buildFn(sec)
			xsecs[id] = sec
		end

		-- panel 1: Player (Noclip / Walk Speed / Infinity Jump) + ESP
		miniTab("player", function(sec)
			makeToggleW(sec, "Noclip", "Walk through walls and obstacles",
				function() return CFG.noclipEnabled end,
				function(v)
					if ctx.setNoclip then pcall(function() ctx.setNoclip(v) end) end
					persist()
				end)
			makeInputW(sec, "Walk Speed", "Player walk speed (default 16)",
				function() return CFG.walkSpeed end,
				function(t)
					CFG.walkSpeed = tonumber(t) or 16
					if ctx.applyWalkSpeed then pcall(function() ctx.applyWalkSpeed() end) end
				end)
			makeToggleW(sec, "Enable Walk Speed", "Applies the custom walk speed",
				function() return CFG.walkSpeedEnabled end,
				function(v)
					if ctx.setWalkSpeed then pcall(function() ctx.setWalkSpeed(v) end) end
					persist()
				end)
			makeToggleW(sec, "Infinity Jump", "Jump in mid-air infinitely",
				function() return CFG.infJumpEnabled end,
				function(v)
					if ctx.setInfJump then pcall(function() ctx.setInfJump(v) end) end
					persist()
				end)
			makeToggleW(sec, "Enable ESP Label", "Floating labels above pets (name + weight + level + mutation)",
				function() return CFG.espEnabled end,
				function(v)
					CFG.espEnabled = v; persist()
					if v then
						if ctx.startEsp then pcall(function() ctx.startEsp() end) end
					elseif ctx.stopEsp then
						pcall(function() ctx.stopEsp() end)
					end
				end)
			makeSingleW(sec, "ESP Label Mode", "Where the pet ESP renders",
				function() return {
					{ name = "target", display = "Target (floating on pet)" },
					{ name = "screen", display = "Screen (side panel list)" },
				} end,
				function() return CFG.espMode end,
				function(code)
					CFG.espMode = code; persist()
					if CFG.espEnabled then
						if ctx.stopEsp then pcall(function() ctx.stopEsp() end) end
						if ctx.startEsp then pcall(function() ctx.startEsp() end) end
					end
				end)
			makeToggleW(sec, "Enable ESP Egg", "NEBULA-style floating egg info (egg name, hatch timer/Base Weight or hatched pet + size class). Separate from pet ESP.",
				function() return CFG.espEggEnabled end,
				function(v)
					CFG.espEggEnabled = v; persist()
					if v then
						if ctx.startEspEgg then pcall(function() ctx.startEspEgg() end) end
					elseif ctx.stopEspEgg then
						pcall(function() ctx.stopEspEgg() end)
					end
				end)
			makeSingleW(sec, "ESP Egg Mode", "Where the egg ESP renders",
				function() return {
					{ name = "target", display = "Target (floating on egg)" },
					{ name = "screen", display = "Screen (side panel list)" },
				} end,
				function() return CFG.espEggMode end,
				function(code)
					CFG.espEggMode = code; persist()
					if CFG.espEggEnabled then
						if ctx.stopEspEgg then pcall(function() ctx.stopEspEgg() end) end
						if ctx.startEspEgg then pcall(function() ctx.startEspEgg() end) end
					end
				end)
			makeToggleW(sec, "Enable ESP Base Weight", "Shows the Base Weight on every pet slot when opening the inventory",
				function() return CFG.espInvEnabled end,
				function(v)
					CFG.espInvEnabled = v; persist()
					if v then
						if ctx.startEspInv then pcall(function() ctx.startEspInv() end) end
					elseif ctx.stopEspInv then
						pcall(function() ctx.stopEspInv() end)
					end
				end)
			makeSingleW(sec, "Base Weight Display", "Which data shows on the pet label",
				function() return {
					{ name = "base", display = "Base Weight Only" },
					{ name = "age",  display = "Base + Age" },
					{ name = "max",  display = "Base + Max" },
				} end,
				function() return CFG.espInvMode end,
				function(code) CFG.espInvMode = code; persist() end)
		end)

		-- panel 2: Rejoin (auto reconnect + periodic)
		miniTab("rejoin", function(sec)
			makeToggleW(sec, "Auto Reconnect", "Rejoins automatically when kicked / disconnected",
				function() return CFG.autoReconnect ~= false end,
				function(v) CFG.autoReconnect = v; persist() end)
			liveStatus(sec, "Periodic Rejoin", function()
				if CFG.reconnectEnabled then
					local rem = ctx.state.reconnectRemaining
					if rem then
						return ("Rejoin in: <font color=\"#5acc78\"><b>%d:%02d</b></font>")
							:format(math.floor(rem / 60), rem % 60)
					end
					return "Rejoin: <font color=\"#5acc78\"><b>ON</b></font>"
				end
				return "Rejoin: OFF"
			end, 1)
			makeInputW(sec, "Interval (minutes)", "Rejoins the server periodically every N minutes (e.g. 1 = every minute).",
				function() return CFG.reconnectInterval end,
				function(t) CFG.reconnectInterval = tonumber(t) or 5; persist() end)
			makeToggleW(sec, "Periodic Rejoin", "Rejoins the server periodically on the interval above",
				function() return CFG.reconnectEnabled end,
				function(v)
					CFG.reconnectEnabled = v; persist()
					if v and ctx.startReconnect then pcall(function() ctx.startReconnect() end) end
				end)
		end)

		-- panel 3: Webhook (URL + test)
		miniTab("webhook", function(sec)
			makeInputW(sec, "Discord Webhook URL", "Webhook URL for automation updates (Leveling, Mutation & Elephant)",
				function() return CFG.webhookUrl end,
				function(t) CFG.webhookUrl = t; persist() end)
			sec:Button({
				Title = "Test Webhook Connection", Desc = "Sends a test notification to your Discord channel.",
				Callback = safe(function()
					if not CFG.webhookUrl or CFG.webhookUrl == "" then
						if ctx.log then ctx.log("[Webhook Test] FAILED: webhook URL is empty!") end
						return
					end
					if ctx.log then ctx.log("[Webhook Test] Sending test payload...") end
					task.spawn(function()
						local sendWebhook = ctx.sendWebhook
						if sendWebhook then
							pcall(function()
								sendWebhook(CFG.webhookUrl, {
									embeds = {
										{
											title = "Webhook Connection Test",
											description = "Discord Webhook connected successfully to Dopamine!",
											color = 3066993,
											fields = {
												{
													name = "Profile :",
													value = string.format("> Username : ||%s||", ctx.LP.Name),
													inline = false,
												},
											},
											footer = {
												text = os.date("%B %d | %I:%M %p"),
												icon_url = "https://raw.githubusercontent.com/milmscr/opoki/main/tegalan/Logo/logo_icon.png",
											},
										},
									},
								}, ctx)
							end)
						elseif ctx.log then
							ctx.log("[Webhook Test] FAILED to load the sender module.")
						end
					end)
				end),
			})
		end)

		-- panel 4: Performance (hide plants / FX / render)
		miniTab("perf", function(sec)
			makeToggleW(sec, "Hide My Garden Plants", "Hides plants on your own farm for better FPS",
				function() return CFG.hideMyPlants end,
				function(v)
					if ctx.setHidePlants then pcall(function() ctx.setHidePlants("mine", v) end) end
					persist()
				end)
			makeToggleW(sec, "Hide Other Gardens Plants", "Hides plants on other players' farms",
				function() return CFG.hideOtherPlants end,
				function(v)
					if ctx.setHidePlants then pcall(function() ctx.setHidePlants("other", v) end) end
					persist()
				end)
			makeToggleW(sec, "Auto Remove Spider Web FX", "Continuously removes spider web particle effects",
				function() return CFG.autoRemoveWebFx end,
				function(v)
					if ctx.setAutoRemoveWeb then pcall(function() ctx.setAutoRemoveWeb(v) end) end
					persist()
				end)
			makeSingleW(sec, "Performance Mode", "Off: normal. Low: shadows off. Extreme: all particle effects off.",
				function() return ctx.getPerfModeOptions() end,
				function() return CFG.perfMode or "off" end,
				function(code)
					if ctx.setPerfMode then pcall(function() ctx.setPerfMode(code) end) end
					persist()
				end)
			makeToggleW(sec, "Disable 3D Rendering", "Stops rendering the 3D world (huge FPS gains, black screen)",
				function() return CFG.disable3d end,
				function(v)
					if ctx.setDisable3d then pcall(function() ctx.setDisable3d(v) end) end
					persist()
				end)
		end)

		miniBar(xsecs, xorder, xdefs, "player", { { "player", "rejoin" }, { "webhook", "perf" } })
	end

	----------------------------------------------------------------- TAB: SETTINGS
	local function buildSettingsTab(tab)
		local persist = ctx.persistState

		local DEFS = {
			general = { name = "General" },
			config  = { name = "Config" },
			control = { name = "Control" },
			logs    = { name = "Logs" },
		}
		local ORDER = { "general", "config", "control", "logs" }
		local secs = {}
		local function miniTab(id, buildFn)
			local sec = section(tab, DEFS[id].name)
			buildFn(sec)
			secs[id] = sec
		end

		--------------------------------------------------- panel 1: General
		miniTab("general", function(sec)
			sec:Paragraph({
				Title = "Dopamine | P².Achieve",
				Desc = ("Build: %s\nToggle UI: click the logo open button or press K.\nConfig file: state_%s.json in the executor workspace (auto-saves on every change + every 10s).")
					:format(
						tostring((getgenv and getgenv().GAG_REVISION) or ctx.BASE or "-"),
						tostring(ctx.LP.UserId)),
			})

			-- Theme WindUI (bawaan lib; ganti tanpa reload).
			local themes = {}
			pcall(function()
				local th = W.windui.GetThemes and W.windui:GetThemes()
				if th then for nm in pairs(th) do themes[#themes + 1] = tostring(nm) end end
			end)
			table.sort(themes)
			if #themes == 0 then themes = { "Dark", "Light" } end
			local curTheme = nil
			pcall(function() curTheme = W.windui.GetCurrentTheme and W.windui:GetCurrentTheme() end)
			makeSingleW(sec, "Theme WindUI", "Built-in WindUI theme, applies instantly.",
				function() return themes end,
				function() return curTheme or themes[1] end,
				function(v)
					pcall(function() if W.windui.SetTheme then W.windui:SetTheme(v) end end)
					W.notify("Settings", "Theme: " .. tostring(v))
				end, { fillDelay = 2.2 })

			sec:Button({
				Title = "Reload Hub",
				Desc = "Re-run the loader (pulls the latest build from the repo).",
				Callback = safe(function()
					local rev = (getgenv and getgenv().GAG_REVISION) or "main"
					pcall(function()
						loadstring(game:HttpGet("https://raw.githubusercontent.com/MisthiosOG/testgden/"
							.. tostring(rev) .. "/tegalan/init.lua?t=" .. os.time()))()
					end)
				end),
			})
		end)

		--------------------------------------------------- panel 2: Config
		miniTab("config", function(sec)
			-- Live config status: what got loaded at boot + FS probe verdict.
			local fsDiag = sec:Paragraph({
				Title = "Config Status",
				Desc = "Checking...",
			})
			task.spawn(function()
				local last = ""
				while ctx.alive() do
					pcall(function()
						local info = tostring(ctx.state.cfgLoadInfo
							or "No config loaded this session yet")
						local fs = tostring(ctx.state.fsStatus or "")
						local txt = info .. (fs ~= "" and ("\n" .. fs) or "")
						if txt ~= last then last = txt; fsDiag:SetDesc(txt) end
					end)
					task.wait(3)
				end
			end)
			sec:Paragraph({
				Title = "Config Storage",
				Desc = "Run Config Storage Test to check every path.",
			})
			sec:Button({
				Title = "Save Config Now",
				Desc = "Force-save all settings to the state file.",
				Callback = safe(function()
					persist()
					local okr, info = pcall(function()
						local path = tostring(ctx.CFG_STATE_PATH or "")
						return path .. " (" .. tostring(#readfile(path)) .. " bytes)"
					end)
					if okr then
						W.notify("Settings", "Saved -> " .. info)
						ctx.log("Settings: manual save -> " .. info)
					else
						W.notify("Settings", "Save FAILED, read the log")
						ctx.log("Settings: save FAILED (readfile/writefile rejected)")
					end
				end),
			})
			sec:Button({
				Title = "Config Storage Test",
				Desc = "Test writefile + readfile on every candidate path, live.",
				Callback = safe(function()
					local cands = ctx.CFG_STATE_CANDIDATES or {}
					local lines = {}
					if type(writefile) ~= "function" or type(readfile) ~= "function" then
						lines[1] = "Executor has NO writefile/readfile, config persistence impossible"
					elseif #cands == 0 then
						lines[1] = "No candidate paths registered"
					else
						for _, p in ipairs(cands) do
							local errOut = nil
							local okPing = pcall(function()
								local pf = p .. ".probe"
								writefile(pf, "1")
								if readfile(pf) ~= "1" then errOut = "readback mismatch" end
								pcall(delfile, pf)
							end)
							if not okPing then errOut = "executor rejected the path" end
							if errOut then
								lines[#lines + 1] = p .. "  FAIL (" .. errOut .. ")"
							else
								lines[#lines + 1] = p .. "  OK"
							end
						end
					end
					pcall(function() fsDiag:SetDesc(table.concat(lines, "\n")) end)
					ctx.log("[config] storage test: " .. tostring(#lines) .. " path(s) checked")
				end),
			})
			sec:Button({
				Title = "Restore Config Backup",
				Desc = "Copy the last good config (.bak) over the main file, then re-exec.",
				Callback = safe(function()
					local mainP = tostring(ctx.CFG_STATE_PATH or "")
					local bakP = mainP .. ".bak"
					local okr, detail = pcall(function()
						local data = readfile(bakP)
						assert(data and #data > 0, "backup empty")
						writefile(mainP, data)
						pcall(function()
							local gp = "garden_state_" .. tostring(ctx.LP.UserId) .. ".json"
							if isfile(gp) then writefile(gp, data) end
						end)
						return #data
					end)
					if okr then
						W.notify("Config", "Backup restored (" .. tostring(detail) .. " bytes), re-exec the script now")
						ctx.log("[config] backup restored -> " .. mainP)
					else
						W.notify("Config", "No backup file found")
						ctx.log("[config] restore FAILED: " .. tostring(detail))
					end
				end),
			})
		end)

		--------------------------------------------------- panel 3: Control
		miniTab("control", function(sec)
			sec:Paragraph({
				Title = "Automation Control",
				Desc = "STOP ALL turns off every automation + player/perf mods in one go. Toggles snap back to OFF and persist to the config.",
			})

			-- STOP ALL: matiin SEMUA automation (sweep flag *Enabled) + player/perf
			-- mods dibalikin ke default + stop function yg tersedia. Loop automation
			-- semuanya nge-flag CFG tiap tick -> flag mati = loop berhenti sendiri.
			local function doStopAll()
				for k, v in pairs(CFG) do
					if type(v) == "boolean" and tostring(k):find("Enabled", 1, true) then CFG[k] = false end
				end
				CFG.autoReconnect  = false
				CFG.hideMyPlants   = false
				CFG.hideOtherPlants= false
				CFG.autoRemoveWebFx= false
				CFG.disable3d      = false
				for _, fn in ipairs({ "stopPnpV1", "stopTrade", "stopHatch",
					"stopAutoFavorite", "stopAutoUnfavorite", "stopEggMinusWatcher", "stopReclaim",
					"stopGrowth", "stopLeveling", "stopLevelingV2", "stopElephant", "stopElephantV2",
					"stopMutation", "stopCleanse", "stopBoostPet", "stopReconnect" }) do
					if ctx[fn] then pcall(ctx[fn]) end
				end
				if ctx.setNoclip then pcall(function() ctx.setNoclip(false) end) end
				if ctx.setWalkSpeed then pcall(function() ctx.setWalkSpeed(false) end) end
				if ctx.setInfJump then pcall(function() ctx.setInfJump(false) end) end
				if ctx.setHidePlants then
					pcall(function() ctx.setHidePlants("mine", false) end)
					pcall(function() ctx.setHidePlants("other", false) end)
				end
				if ctx.setAutoRemoveWeb then pcall(function() ctx.setAutoRemoveWeb(false) end) end
				if ctx.setDisable3d then pcall(function() ctx.setDisable3d(false) end) end
				if ctx.setPerfMode then pcall(function() ctx.setPerfMode("off") end) end
				persist()
				ctx.log("Settings: ALL automation stopped.")
				W.notify("Settings", "All automation STOPPED.")
			end

			sec:Button({
				Title = "STOP ALL Automation",
				Desc = "Turn off all automation + player/perf mods (asks for confirmation first).",
				Callback = safe(function()
					local okd = pcall(function()
						window:Dialog({
							Title = "Stop All Automation?",
							Content = "All automation, player mods, and perf mode will be turned off.",
							Buttons = {
								{ Title = "Yes, Stop All", Variant = "Primary", Callback = doStopAll },
								{ Title = "Cancel", Variant = "Secondary", Callback = function() end },
							},
						})
					end)
					if not okd then doStopAll() end -- dist tanpa Dialog -> langsung eksekusi
				end),
			})
		end)

		--------------------------------------------------- panel 4: Logs
		miniTab("logs", function(sec)
			-- Log live: 8 baris terakhir ctx.state.logLines.
			local logs = sec:Paragraph({ Title = "Logs", Desc = "-" })
			task.spawn(function()
				task.wait(3)
				while ctx.alive() do
					pcall(function()
						local n = #ctx.state.logLines
						local from = math.max(1, n - 7)
						local t = {}
						for i = from, n do t[#t + 1] = ctx.state.logLines[i] end
						logs:SetDesc(table.concat(t, "\n"))
					end)
					task.wait(3)
				end
			end)
		end)

		miniBar(secs, ORDER, DEFS, "general")
	end

	----------------------------------------------------------------- REGISTRY TAB
	-- Urutan sesuai Pink Royale. build = nil -> placeholder (belum dimigrasi).
	local MIGRATED = {
		Pet = buildPetTab,
		Inventory = buildInventoryTab,
		Farm = buildFarmTab,
		Hatch = buildHatchTab,
		Elephant = buildElephantTab,
		Flow = buildFlowTab,
		Leveling = buildLevelingTab,
		Mutation = buildMutationTab,
		Shop = buildShopTab,
		Misc = buildMiscTab,
		Settings = buildSettingsTab,
	}

	local TABS = {
		{ id = "Pet",       title = "Pet",       icon = "solar:cat-bold" },
		{ id = "Farm",      title = "Farm",      icon = "solar:leaf-bold" },
		{ id = "Hatch",     title = "Hatch",     icon = "solar:confetti-bold" },
		{ id = "Elephant",  title = "Elephant",  icon = "solar:dumbbell-bold" },
		{ id = "Flow",      title = "Flow",      icon = "solar:branching-paths-up-bold" },
		{ id = "Leveling",  title = "Leveling",  icon = "solar:bolt-bold" },
		{ id = "Mutation",  title = "Mutation",  icon = "solar:test-tube-bold" },
		{ id = "Inventory", title = "Inventory", icon = "solar:backpack-bold" },
		{ id = "Shop",      title = "Shop",      icon = "solar:cart-bold" },
		{ id = "Misc",      title = "Misc",      icon = "solar:settings-bold" },
		{ id = "Settings",  title = "Settings",  icon = "solar:settings-minimalistic-bold" },
	}

	local first
	local buildT0 = os.clock()
	for i, def in ipairs(TABS) do
		local tab = window:Tab({
			Title = def.title,
			Desc = def.id,
			Icon = def.icon,
		})
		W.tabs[def.id] = tab

		-- bridge warisan buat app.lua (loop selectTab & auto-resume)
		ctx.ui.pages[def.id] = { Visible = false }
		ctx.ui.tabBtns[def.id] = {
			setActive = function(active)
				if active then pcall(function() tab:Select() end) end
			end,
		}

		if i == 1 then first = tab end

		if MIGRATED[def.id] then
			local t0 = os.clock()
			local ok, err = pcall(MIGRATED[def.id], tab)
			ctx.log(("[pages] tab %s dibangun (%.0f ms)"):format(def.id, (os.clock() - t0) * 1000))
			if not ok then
				ctx.log("build tab " .. def.id .. " gagal: " .. tostring(err))
				pcall(function()
					tab:Paragraph({
						Title = "Tab Failed To Build",
						Desc = tostring(err),
					})
				end)
			end
		else
			tab:Paragraph({
				Title = "Not Migrated Yet",
				Desc = "Tab '" .. def.id .. "' still runs in the old build (Pink Royale). Migration to WindUI goes one tab at a time; this tab is next.",
			})
			tab:Paragraph({
				Title = "Feature Status",
				Desc = "Feature logic stays LOADED (CFG, persistence, auto-resume). Only the control panel has not moved yet.",
			})
		end
	end
	ctx.log(("[pages] total build UI (%.0f ms)"):format((os.clock() - buildT0) * 1000))

	----------------------------------------------------------------- default tab (pilot)
	pcall(function() if first and first.Select then first:Select() end end)

	-- PRE-WARM cache dropdown (NO-UI): snapshot data semua dropdown dinamis
	-- pas boot (beberapa kali buat kejar data game yang lambat masuk) + tiap
	-- 4 menit biar cache gak pernah dingin. Baris dropdown tetap dibangun saat
	-- menu pertama dibuka — pre-build ratusan baris UI di background = frame
	-- drop (udah dicoba, tau rasanya).
	task.spawn(function()
		local function warm()
			for _, w in ipairs(W.ddWarmers or {}) do pcall(w) end
		end
		task.wait(1.5); warm()
		task.wait(15);   warm()
		task.wait(45);   warm()
		while ctx.alive() do
			task.wait(240)
			if ctx.alive() then warm() end
		end
	end)

	ctx.log("WindUI pages dibangun: SEMUA TAB (Pet, Farm, Hatch, Elephant, Flow, Leveling, Mutation, Inventory, Shop, Misc, Settings).")
end
]=],
	["ui/theme.lua"] = [=[
--[[ theme.lua — palet warna PINK ROYALE ELEGAN + helper pembuat Instance.
     Karakter: Midnight Velvet Rose, Shimmering Pearl, Radiant Hot Rose, Soft Neon Sakura. ]]
return function(ctx)
	local C = {
		bg        = Color3.fromRGB(15, 9, 20),         -- Deep obsidian velvet (solid & clean)
		panel     = Color3.fromRGB(24, 13, 31),        -- Dark luxury wine panel
		row       = Color3.fromRGB(36, 19, 46),        -- Card container
		rowAlt    = Color3.fromRGB(58, 28, 74),        -- Elevated card / active item
		rowHover  = Color3.fromRGB(72, 35, 92),        -- Hover state card
		stroke    = Color3.fromRGB(255, 95, 175),      -- Radiant rose-pink border
		strokeSub = Color3.fromRGB(130, 68, 140),      -- Clear border outline
		acc       = Color3.fromRGB(255, 55, 145),      -- Hot Radiant Rose (aksen utama)
		acc2      = Color3.fromRGB(255, 135, 205),     -- Soft Neon Sakura (gradient partner)
		accSoft   = Color3.fromRGB(255, 215, 240),     -- Pastel Rose Shimmer (teks aksen super terang)
		glow      = Color3.fromRGB(255, 60, 145),      -- Ambient glow
		txt       = Color3.fromRGB(255, 255, 255),     -- Pure White (teks utama ultra-tajam & kontras tinggi)
		sub       = Color3.fromRGB(235, 205, 235),     -- Light Soft Rose-Lilac (deskripsi & label sekunder terbaca jelas!)
		green     = Color3.fromRGB(110, 245, 185),     -- Luminous Mint-Emerald
		red       = Color3.fromRGB(255, 75, 120),      -- Passion Crimson Rose
	}

	local F = {
		title = Enum.Font.FredokaOne,       -- Judul / Header / Branding (Modern & Segar, beda total dari Gotham)
		bold  = Enum.Font.MontserratBold,   -- Subheader / Tombol / Label Tebal (Tajam & Elegan)
		semi  = Enum.Font.MontserratMedium, -- Dropdown item / Value pill
		reg   = Enum.Font.Ubuntu,           -- Deskripsi & isi teks (Sangat nyaman dibaca)
		code  = Enum.Font.Code,             -- Console logs
	}

	local function mk(cls, props, parent)
		local o = Instance.new(cls)
		for k, v in pairs(props) do o[k] = v end
		o.Parent = parent
		return o
	end

	local function corner(o, r)
		return mk("UICorner", { CornerRadius = UDim.new(0, r or 10) }, o)
	end

	local function stroke(o, col, thick, trans)
		return mk("UIStroke", {
			Color = col or C.strokeSub,
			Thickness = thick or 1.2,
			Transparency = trans or 0.35,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}, o)
	end

	local function pad(o, l, r, t, b)
		return mk("UIPadding", {
			PaddingLeft = UDim.new(0, l),
			PaddingRight = UDim.new(0, r),
			PaddingTop = UDim.new(0, t),
			PaddingBottom = UDim.new(0, b),
		}, o)
	end

	local function grad(o, rot, col1, col2)
		return mk("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, col1 or C.acc),
				ColorSequenceKeypoint.new(1, col2 or C.acc2),
			}),
			Rotation = rot or 90,
		}, o)
	end

	ctx.C      = C
	ctx.F      = F
	ctx.mk     = mk
	ctx.corner = corner
	ctx.stroke = stroke
	ctx.pad    = pad
	ctx.grad   = grad
end
]=],
	["ui/window.lua"] = [=[
--[[ window.lua — jendela utama WINDUI build (tab-per-tab migration).
     UI = WindUI 1.6.66 (rilis yang sama dengan trade/, sudah teruji).
     Tidak ada shim/compat layer: pages.lua memakai ctx.wi.* langsung.
     Jembatan warisan untuk app.lua: ctx.ui.pages / ctx.ui.tabBtns (tabel dummy). ]]
return function(ctx)
	local UserInputService = ctx.Services.UserInputService

	----------------------------------------------------------------- bersihkan GUI lama
	pcall(function()
		local host = (gethui and gethui()) or game:GetService("CoreGui")
		for _, nm in ipairs({ "GAGGarden", "CeszParadiseGarden", "AllegiaanGarden" }) do
			local old = host:FindFirstChild(nm)
			if old then old:Destroy() end
			local pg = ctx.LP:FindFirstChild("PlayerGui")
			if pg and pg:FindFirstChild(nm) then pg[nm]:Destroy() end
		end
	end)

	----------------------------------------------------------------- load WindUI
	-- Lib di-vendor ke repo (patched: drag pakai Position langsung, bukan
	-- Tween per mousemove — versi upstream bikin window nge-lag saat digeser).
	-- Fallback: rilis upstream Footagesus kalau raw repo gagal.
	local compile = loadstring or load
	local LIB_URLS = {
		"https://raw.githubusercontent.com/MisthiosOG/testgden/main/tegalan/windui/lib/windui-1.6.66.lua",
		"https://github.com/Footagesus/WindUI/releases/download/1.6.66/main.lua",
	}
	local WindUI, errLib
	for _, libUrl in ipairs(LIB_URLS) do
		local ok = pcall(function()
			WindUI = compile(game:HttpGet(libUrl))()
		end)
		if ok and WindUI and WindUI.CreateWindow then break end
		WindUI = nil
	end
	if not (WindUI and WindUI.CreateWindow) then
		warn("[WindUIHub] gagal load WindUI library: " .. tostring(errLib))
		error("[WindUIHub] WindUI failed to load — hub berhenti.", 0)
	end

	----------------------------------------------------------------- window
	local window = WindUI:CreateWindow({
		Title = "Dopamine | P².Achieve",
		Icon = "solar:planet-3-bold-duotone",
		Folder = "CeszParadiseWindUI",
		Size = UDim2.fromOffset(720, 520),
		NewElements = true,
		ToggleKey = Enum.KeyCode.K,
		OpenButton = {
			Enabled = true,
			OnlyMobile = false,
			Draggable = true,
			-- Ikon doang (bulat kecil) + outline solid tipis — gradient
			-- pink-biru default WindUI-nya yang norak, jadi di-reset solid.
			Title = "Dopamine | P².Achieve",
			Icon = "solar:planet-3-bold-duotone",
			OnlyIcon = true,
			CornerRadius = UDim.new(1, 0),
			StrokeThickness = 1.4,
			Color = ColorSequence.new(Color3.fromHex("#666666")),
		},
	})

	ctx.wi = {
		windui = WindUI,
		window = window,
		tabs   = {},   -- id -> WindUI tab object
		refreshers = {}, -- fungsi refresh dropdown dinamis (dipanggil tombol List refresh)
		ddWarmers  = {}, -- snapshot-only warmers (pre-warm cache dropdown, no-UI)
	}

	-- Bridge warisan buat app.lua (loop selectTab default + auto-resume):
	-- app.lua lama iterasi pages (set .Visible) & tabBtns (setActive) — dummy supaya aman.
	ctx.ui.pages   = {}
	ctx.ui.tabBtns = {}

	ctx.state.isAlive = true
	-- Badge bawah judul: build stage, bukan rev (rev masih ada di log & config).
	pcall(function()
		window:Tag({
			Title = "Beta Test",
			Icon = "solar:rocket-bold",
		})
	end)

	----------------------------------------------------------------- logger
	local logLines = ctx.state.logLines
	function ctx.log(msg)
		table.insert(logLines, os.date("%H:%M:%S ") .. msg)
		while #logLines > 50 do table.remove(logLines, 1) end
		print("[WindUIHub] " .. tostring(msg))
	end

	----------------------------------------------------------------- status (footer legacy — cukup log; UI status bakal jadi Paragraph per tab)
	function ctx.setStatus(s)
		local isActive = tostring(s):lower():find("active") ~= nil
			or tostring(s):lower():find("jalan") ~= nil
		ctx.state.statusValue = tostring(s)
		ctx.state.statusActive = isActive
	end

	----------------------------------------------------------------- API helper global buat pages.lua
	-- wrap callback: semua callback user di-pcall supaya 1 bug fitur ga bikin UI mati.
	function ctx.wi.toggle(tab, opts)
		return tab:Toggle(opts)
	end
	function ctx.wi.notify(title, content, dur)
		pcall(function()
			WindUI:Notify({
				Title = tostring(title),
				Content = tostring(content or ""),
				Duration = tonumber(dur) or 4,
			})
		end)
	end

	print("[WindUIHub] window ready (WindUI " .. tostring(WindUI.Version or "1.6.66") .. ")")
	ctx.log("CeszParadiseHub WindUI window siap.")
end
]=],
}
