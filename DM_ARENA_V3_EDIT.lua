-- ╔══════════════════════════════════════════════════════╗
-- ║    DM ARENA SCRIPT | V3  by Malinnowski              ║
-- ║                  Open/Close: K                       ║
-- ╚══════════════════════════════════════════════════════╝

-- ══════════════════════════════════════════
--  ANTI-DETECT: скрывает следы скрипта
-- ══════════════════════════════════════════
local _rawset    = rawset
local _rawget    = rawget
local _pairs     = pairs
local _ipairs    = ipairs
local _tostring  = tostring
local _pcall     = pcall
local _task      = task
local _RS        = game:GetService("RunService")
local _TW        = game:GetService("TweenService")
local _UIS       = game:GetService("UserInputService")
local _Players   = game:GetService("Players")

-- Обфусцируем имя ScreenGui чтобы не детектился по имени
local GUI_NAME = string.char(68,77,95,65,82,69,78,65,95,71,85,73) -- "DM_ARENA_GUI"

local Players      = _Players
local TweenService = _TW
local UIS          = _UIS
local RunService   = _RS
local ContentProv  = game:GetService("ContentProvider")

local STAFF_GROUP_ID = 36077422

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:Wait()
local humanoid  = character:WaitForChild("Humanoid")
local rootPart  = character:WaitForChild("HumanoidRootPart")

local values          = {}
local keybinds        = {}
local toggleCallbacks = {}
local notifyNames     = {}
local guiVisible      = false
local pickerOpen      = false

player.CharacterAdded:Connect(function(c)
    character = c
    humanoid  = c:WaitForChild("Humanoid")
    rootPart  = c:WaitForChild("HumanoidRootPart")
end)

task.spawn(function()
    pcall(function()
        ContentProv:PreloadAsync({
            "rbxassetid://73965231027852","rbxassetid://103344771690872",
            "rbxassetid://14219436180","rbxassetid://14219516515",
            "rbxassetid://11738355467","rbxassetid://123652566388954",
            "rbxassetid://16081386298","rbxassetid://9405931578",
            "rbxassetid://14895333462","rbxassetid://73132811772878",
            "rbxassetid://17193841062","rbxassetid://13321877099",
            "rbxassetid://13379765910","rbxassetid://11127408662",
        })
    end)
end)

-- ══════════════════════════════════════════
--  SOUNDS
-- ══════════════════════════════════════════
local function playSound(id, vol)
    local s = Instance.new("Sound", workspace)
    s.SoundId = "rbxassetid://"..tostring(id)
    s.Volume  = vol or 0.5
    s.RollOffMaxDistance = 0
    s:Play()
    game:GetService("Debris"):AddItem(s, 3)
end
local SND_CLICK      = "139009780109934"
local SND_OPEN       = "138498992667102"
local SND_CLOSE      = "138498992667102"
local SND_TOGGLE_ON  = "135165335432475"
local SND_TOGGLE_OFF = "122125495508907"

-- ══════════════════════════════════════════
--  SCREEN GUI
-- ══════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = GUI_NAME
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent         = playerGui

-- ══════════════════════════════════════════
--  ICON IDs
-- ══════════════════════════════════════════
local ICON_CHECK_ID = "73965231027852"
local ICON_CROSS_ID = "103344771690872"
local ICON_SKULL_ID = "104280509740477"
local ICON_FPS_ID   = "11344298921"
local ICON_CHECK    = "rbxassetid://"..ICON_CHECK_ID
local ICON_X        = "rbxassetid://"..ICON_CROSS_ID

-- ══════════════════════════════════════════
--  RIGHT NOTIFY STACK
-- ══════════════════════════════════════════
local NOTIFY_W=230; local NOTIFY_H=34; local NOTIFY_GAP=5
local notifyStack={}
local function _getNotifyY(i) return -(NOTIFY_H+NOTIFY_GAP)*(i-1)-NOTIFY_H-80 end

local function _spawnRightNotify(iconId, iconColor, text, borderColor)
    for i,item in ipairs(notifyStack) do
        TweenService:Create(item.frame,TweenInfo.new(0.2,Enum.EasingStyle.Quad),{
            Position=UDim2.new(1,-(NOTIFY_W+14),1,_getNotifyY(i+1))
        }):Play()
    end
    local frame=Instance.new("Frame",ScreenGui)
    frame.Size=UDim2.new(0,NOTIFY_W,0,NOTIFY_H)
    frame.BackgroundColor3=Color3.fromRGB(10,10,10)
    frame.BackgroundTransparency=0; frame.BorderSizePixel=0; frame.ZIndex=90
    Instance.new("UICorner",frame).CornerRadius=UDim.new(0,10)
    local stroke=Instance.new("UIStroke",frame)
    stroke.Color=borderColor or Color3.fromRGB(50,50,50); stroke.Thickness=1.5
    local iconImg=Instance.new("ImageLabel",frame)
    iconImg.Size=UDim2.new(0,16,0,16); iconImg.Position=UDim2.new(0,10,0.5,-8)
    iconImg.BackgroundTransparency=1; iconImg.Image="rbxassetid://"..iconId
    iconImg.ImageColor3=iconColor; iconImg.ZIndex=91
    local lbl=Instance.new("TextLabel",frame)
    lbl.Size=UDim2.new(1,-34,1,0); lbl.Position=UDim2.new(0,32,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=text
    lbl.Font=Enum.Font.GothamBold; lbl.TextSize=12
    lbl.TextColor3=Color3.fromRGB(255,255,255)
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=91
    frame.Position=UDim2.new(1,NOTIFY_W+14,1,_getNotifyY(1))
    TweenService:Create(frame,TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{
        Position=UDim2.new(1,-(NOTIFY_W+14),1,_getNotifyY(1))
    }):Play()
    local entry={frame=frame}; table.insert(notifyStack,1,entry)
    task.delay(2.4,function()
        for i,item in ipairs(notifyStack) do if item==entry then table.remove(notifyStack,i); break end end
        for i,item in ipairs(notifyStack) do
            TweenService:Create(item.frame,TweenInfo.new(0.2,Enum.EasingStyle.Quad),{
                Position=UDim2.new(1,-(NOTIFY_W+14),1,_getNotifyY(i))
            }):Play()
        end
        TweenService:Create(frame,TweenInfo.new(0.28,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{
            Position=UDim2.new(1,NOTIFY_W+14,1,frame.Position.Y.Offset)
        }):Play()
        TweenService:Create(frame,TweenInfo.new(0.28),{BackgroundTransparency=1}):Play()
        TweenService:Create(stroke,TweenInfo.new(0.28),{Transparency=1}):Play()
        TweenService:Create(lbl,TweenInfo.new(0.28),{TextTransparency=1}):Play()
        TweenService:Create(iconImg,TweenInfo.new(0.28),{ImageTransparency=1}):Play()
        task.delay(0.3,function() frame:Destroy() end)
    end)
end

local function pushNotify(name, on)
    if not values["notifs"] then return end
    _spawnRightNotify(
        on and ICON_CHECK_ID or ICON_CROSS_ID,
        on and Color3.fromRGB(80,255,120) or Color3.fromRGB(255,80,80),
        name..(on and "  ON" or "  OFF"),
        on and Color3.fromRGB(0,200,80) or Color3.fromRGB(200,40,40)
    )
end

local function showToast()
    _spawnRightNotify(ICON_CHECK_ID, Color3.fromRGB(200,200,200), "Copied to clipboard!", Color3.fromRGB(80,80,80))
end

local function respawnNotify(_icon, col, msg)
    local id = tostring(_icon):gsub("rbxassetid://","")
    _spawnRightNotify(id, col, msg, Color3.fromRGB(80,80,80))
end

-- ══════════════════════════════════════════
--  LEFT NOTIFY STACK (Player events)
-- ══════════════════════════════════════════
local LEFT_NOTIFY_W=220; local LEFT_NOTIFY_H=34; local LEFT_NOTIFY_GAP=5
local leftNotifyStack={}
local function _getLeftNotifyY(i) return -(LEFT_NOTIFY_H+LEFT_NOTIFY_GAP)*(i-1)-LEFT_NOTIFY_H-80 end

local function _spawnLeftNotify(iconId, iconColor, text, borderColor)
    for i,item in ipairs(leftNotifyStack) do
        TweenService:Create(item.frame,TweenInfo.new(0.2,Enum.EasingStyle.Quad),{
            Position=UDim2.new(0,14,1,_getLeftNotifyY(i+1))
        }):Play()
    end
    local frame=Instance.new("Frame",ScreenGui)
    frame.Size=UDim2.new(0,LEFT_NOTIFY_W,0,LEFT_NOTIFY_H)
    frame.BackgroundColor3=Color3.fromRGB(10,10,10)
    frame.BackgroundTransparency=0; frame.BorderSizePixel=0; frame.ZIndex=90
    Instance.new("UICorner",frame).CornerRadius=UDim.new(0,10)
    local stroke=Instance.new("UIStroke",frame)
    stroke.Color=borderColor or Color3.fromRGB(50,50,50); stroke.Thickness=1.5
    local iconImg=Instance.new("ImageLabel",frame)
    iconImg.Size=UDim2.new(0,16,0,16); iconImg.Position=UDim2.new(0,10,0.5,-8)
    iconImg.BackgroundTransparency=1; iconImg.Image="rbxassetid://"..iconId
    iconImg.ImageColor3=iconColor; iconImg.ZIndex=91
    local lbl=Instance.new("TextLabel",frame)
    lbl.Size=UDim2.new(1,-34,1,0); lbl.Position=UDim2.new(0,32,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=text
    lbl.Font=Enum.Font.GothamBold; lbl.TextSize=12
    lbl.TextColor3=Color3.fromRGB(255,255,255)
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=91
    frame.Position=UDim2.new(0,-(LEFT_NOTIFY_W+14),1,_getLeftNotifyY(1))
    TweenService:Create(frame,TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{
        Position=UDim2.new(0,14,1,_getLeftNotifyY(1))
    }):Play()
    local entry={frame=frame}; table.insert(leftNotifyStack,1,entry)
    task.delay(2.4,function()
        for i,item in ipairs(leftNotifyStack) do if item==entry then table.remove(leftNotifyStack,i); break end end
        for i,item in ipairs(leftNotifyStack) do
            TweenService:Create(item.frame,TweenInfo.new(0.2,Enum.EasingStyle.Quad),{
                Position=UDim2.new(0,14,1,_getLeftNotifyY(i))
            }):Play()
        end
        TweenService:Create(frame,TweenInfo.new(0.28,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{
            Position=UDim2.new(0,-(LEFT_NOTIFY_W+14),1,frame.Position.Y.Offset)
        }):Play()
        TweenService:Create(frame,TweenInfo.new(0.28),{BackgroundTransparency=1}):Play()
        TweenService:Create(stroke,TweenInfo.new(0.28),{Transparency=1}):Play()
        TweenService:Create(lbl,TweenInfo.new(0.28),{TextTransparency=1}):Play()
        TweenService:Create(iconImg,TweenInfo.new(0.28),{ImageTransparency=1}):Play()
        task.delay(0.3,function() frame:Destroy() end)
    end)
end

local function pushPlayerNotify(pName, eventType)
    if eventType=="joined" then
        _spawnLeftNotify(ICON_CHECK_ID, Color3.fromRGB(80,255,120), pName.." joined", Color3.fromRGB(0,200,80))
    elseif eventType=="left" then
        _spawnLeftNotify(ICON_CROSS_ID, Color3.fromRGB(255,80,80), pName.." left", Color3.fromRGB(200,40,40))
    elseif eventType=="died" then
        _spawnLeftNotify(ICON_SKULL_ID, Color3.fromRGB(220,220,220), pName.." died", Color3.fromRGB(180,180,180))
    end
end

local deathConns = {}
local deathDebounce = {}

local function trackPlayerDeath(p)
    if deathConns[p.Name] then pcall(function() deathConns[p.Name]:Disconnect() end) end
    local function hookChar(char)
        local hum = char:WaitForChild("Humanoid", 5)
        if not hum then return end
        if deathConns[p.Name] then pcall(function() deathConns[p.Name]:Disconnect() end) end
        deathConns[p.Name] = hum.Died:Connect(function()
            if p == player then return end
            if deathDebounce[p.Name] then return end
            deathDebounce[p.Name] = true
            pushPlayerNotify(p.Name, "died")
            task.delay(1, function() deathDebounce[p.Name] = nil end)
        end)
    end
    if p.Character then task.spawn(hookChar, p.Character) end
    p.CharacterAdded:Connect(function(c) task.spawn(hookChar, c) end)
end

local activeFunctions = {}
local activeBar, activeList, WatermarkFrame, WMStroke

-- ══════════════════════════════════════════
--  WATERMARK
-- ══════════════════════════════════════════
local function updateWatermarkFuncs()
    if not WatermarkFrame then return end
    for _,c in ipairs(WatermarkFrame:GetChildren()) do
        if c:IsA("Frame") and c.Name:find("WMRow") then c:Destroy() end
    end
    local list = {}
    for k,v in pairs(activeFunctions) do if v then table.insert(list, k) end end
    table.sort(list)
    if #list == 0 then
        WatermarkFrame.Size = UDim2.new(0,10,0,30)
        WatermarkFrame.Visible = values["watermark"] == true
        return
    end
    local rowY = 30
    local rowIndex = 0
    for i = 1, #list, 4 do
        rowIndex = rowIndex + 1
        local rowFrame = Instance.new("Frame", WatermarkFrame)
        rowFrame.Name = "WMRow_"..rowIndex
        rowFrame.BackgroundTransparency = 1
        rowFrame.ZIndex = 22
        rowFrame.AutomaticSize = Enum.AutomaticSize.X
        rowFrame.Size = UDim2.new(0, 10, 0, 16)
        rowFrame.Position = UDim2.new(0, 0, 0, rowY)
        local layout = Instance.new("UIListLayout", rowFrame)
        layout.FillDirection = Enum.FillDirection.Horizontal
        layout.Padding = UDim.new(0, 6)
        layout.VerticalAlignment = Enum.VerticalAlignment.Center
        for j = i, math.min(i+3, #list) do
            local fname = list[j]
            local chip = Instance.new("Frame", rowFrame)
            chip.BackgroundColor3 = Color3.fromRGB(18,18,18)
            chip.BorderSizePixel = 0; chip.ZIndex = 22
            chip.AutomaticSize = Enum.AutomaticSize.X
            chip.Size = UDim2.new(0, 10, 1, 0)
            Instance.new("UICorner", chip).CornerRadius = UDim.new(0,5)
            local chipStroke = Instance.new("UIStroke", chip)
            chipStroke.Color = Color3.fromRGB(50,50,50); chipStroke.Thickness = 1
            local pad = Instance.new("UIPadding", chip)
            pad.PaddingLeft = UDim.new(0,6); pad.PaddingRight = UDim.new(0,6)
            local lbl2 = Instance.new("TextLabel", chip)
            lbl2.BackgroundTransparency = 1
            lbl2.Size = UDim2.new(0,0,1,0)
            lbl2.AutomaticSize = Enum.AutomaticSize.X
            lbl2.Text = fname
            lbl2.Font = Enum.Font.GothamBold; lbl2.TextSize = 9
            lbl2.TextColor3 = Color3.fromRGB(255,255,255); lbl2.ZIndex = 23
            local grad = Instance.new("UIGradient", lbl2)
            grad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
                ColorSequenceKeypoint.new(0.3, Color3.fromRGB(80,80,80)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255,255,255)),
                ColorSequenceKeypoint.new(0.7, Color3.fromRGB(80,80,80)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255,255,255)),
            })
            local offset = (j-1) * 0.3
            RunService.Heartbeat:Connect(function()
                grad.Offset = Vector2.new(math.sin(tick()*2 + offset)*0.9, 0)
            end)
        end
        rowY = rowY + 20
    end
    WatermarkFrame.Size = UDim2.new(0, 10, 0, 30 + rowIndex * 20)
    if values["watermark"] == true then WatermarkFrame.Visible = true end
end

local function updateActiveBar()
    if not activeList then return end
    for _,c in ipairs(activeList:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end
    local count=0
    for k,v in pairs(activeFunctions) do
        if v then
            count = count + 1
            local lb=Instance.new("TextLabel",activeList)
            lb.Size=UDim2.new(1,0,0,11); lb.BackgroundTransparency=1
            lb.Text="• "..k; lb.Font=Enum.Font.GothamBold; lb.TextSize=9
            lb.TextColor3=Color3.fromRGB(255,255,255); lb.TextXAlignment=Enum.TextXAlignment.Left
        end
    end
    if activeBar then activeBar.Visible=(values["watermark"]==true) and count>0 end
    updateWatermarkFuncs()
end

WatermarkFrame=Instance.new("Frame",ScreenGui)
WatermarkFrame.AutomaticSize=Enum.AutomaticSize.X
WatermarkFrame.Size=UDim2.new(0,10,0,30); WatermarkFrame.Position=UDim2.new(0,10,0,10)
WatermarkFrame.BackgroundColor3=Color3.fromRGB(6,6,6); WatermarkFrame.BorderSizePixel=0
WatermarkFrame.ZIndex=20; WatermarkFrame.Visible=false
Instance.new("UICorner",WatermarkFrame).CornerRadius=UDim.new(0,8)
local WMPad=Instance.new("UIPadding",WatermarkFrame)
WMPad.PaddingLeft=UDim.new(0,10); WMPad.PaddingRight=UDim.new(0,10)
WMStroke=Instance.new("UIStroke",WatermarkFrame); WMStroke.Color=Color3.fromRGB(255,255,255); WMStroke.Thickness=1
local wmT = 0
RunService.Heartbeat:Connect(function(dt)
    if not WatermarkFrame.Visible then return end
    wmT = wmT + dt * 2
    local v = (math.sin(wmT) + 1) / 2
    WMStroke.Color = Color3.fromRGB(v * 255, v * 255, v * 255)
end)
local WMLabel=Instance.new("TextLabel",WatermarkFrame)
WMLabel.AutomaticSize=Enum.AutomaticSize.X
WMLabel.Size=UDim2.new(0,0,0,30); WMLabel.BackgroundTransparency=1
WMLabel.Font=Enum.Font.GothamBold; WMLabel.TextSize=11
WMLabel.TextColor3=Color3.fromRGB(255,255,255); WMLabel.ZIndex=21
local WMGrad=Instance.new("UIGradient",WMLabel)
WMGrad.Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(255,255,255)),
    ColorSequenceKeypoint.new(0.35,Color3.fromRGB(60,60,60)),
    ColorSequenceKeypoint.new(0.5,Color3.fromRGB(255,255,255)),
    ColorSequenceKeypoint.new(0.65,Color3.fromRGB(60,60,60)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(255,255,255)),
})
local fps = 0
local fpsTimer = 0
local fpsCount = 0
local pingMs = 0
local pingTimer = 0

RunService.Heartbeat:Connect(function(dt)
    fpsCount = fpsCount + 1
    fpsTimer = fpsTimer + dt
    if fpsTimer>=0.5 then fps=math.floor(fpsCount/fpsTimer); fpsCount=0; fpsTimer=0 end
    pingTimer = pingTimer + dt
    if pingTimer>=1 then
        local ok,p=pcall(function() return player:GetNetworkPing() end)
        pingMs=ok and math.floor(p*1000) or 0; pingTimer=0
    end
    if WatermarkFrame.Visible then
        WMLabel.Text=string.format("DM ARENA | V3  |  %s  |  FPS: %d  |  PING: %dms", player.Name, fps, pingMs)
        WMGrad.Offset=Vector2.new(math.sin(tick()*2)*0.7,0)
    end
end)
local wmDrag,wmDragStart,wmDragPos=false,nil,nil
WatermarkFrame.InputBegan:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1 then
        wmDrag=true; wmDragStart=inp.Position; wmDragPos=WatermarkFrame.Position
        inp.Changed:Connect(function() if inp.UserInputState==Enum.UserInputState.End then wmDrag=false end end)
    end
end)

activeBar=Instance.new("Frame",ScreenGui)
activeBar.Size=UDim2.new(0,130,0,10); activeBar.AutomaticSize=Enum.AutomaticSize.Y
activeBar.Position=UDim2.new(1,-140,0,10); activeBar.BackgroundColor3=Color3.fromRGB(6,6,6)
activeBar.BorderSizePixel=0; activeBar.ZIndex=20; activeBar.Visible=false
Instance.new("UICorner",activeBar).CornerRadius=UDim.new(0,8)
local ABPad=Instance.new("UIPadding",activeBar)
ABPad.PaddingLeft=UDim.new(0,8); ABPad.PaddingRight=UDim.new(0,8)
ABPad.PaddingTop=UDim.new(0,6); ABPad.PaddingBottom=UDim.new(0,6)
Instance.new("UIStroke",activeBar).Color=Color3.fromRGB(30,30,30)
activeList=Instance.new("UIListLayout",activeBar); activeList.Padding=UDim.new(0,2)

-- ══════════════════════════════════════════
--  CLOSED HINT — TOP CENTER
-- ══════════════════════════════════════════
local ClosedHint=Instance.new("Frame",ScreenGui)
ClosedHint.Size=UDim2.new(0,260,0,28)
ClosedHint.Position=UDim2.new(0.5,-130,0,10)
ClosedHint.BackgroundColor3=Color3.fromRGB(10,10,10)
ClosedHint.BackgroundTransparency=0
ClosedHint.BorderSizePixel=0; ClosedHint.ZIndex=5
Instance.new("UICorner",ClosedHint).CornerRadius=UDim.new(0,8)
local CHStroke=Instance.new("UIStroke",ClosedHint)
CHStroke.Color=Color3.fromRGB(40,40,40); CHStroke.Thickness=1; CHStroke.Transparency=0
local ClosedHintLabel=Instance.new("TextLabel",ClosedHint)
ClosedHintLabel.Size=UDim2.new(1,0,1,0)
ClosedHintLabel.BackgroundTransparency=1
ClosedHintLabel.Text="DM ARENA V3  •  Press K to open"
ClosedHintLabel.Font=Enum.Font.GothamBold; ClosedHintLabel.TextSize=11
ClosedHintLabel.TextColor3=Color3.fromRGB(255,255,255); ClosedHintLabel.TextTransparency=0; ClosedHintLabel.ZIndex=6
local CHLabelGrad=Instance.new("UIGradient",ClosedHintLabel)
CHLabelGrad.Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(255,255,255)),
    ColorSequenceKeypoint.new(0.5,Color3.fromRGB(180,180,180)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(255,255,255)),
})
RunService.Heartbeat:Connect(function() CHLabelGrad.Offset=Vector2.new(math.sin(tick()*1.5)*0.8,0) end)
local chStrokeT=0
RunService.Heartbeat:Connect(function(dt)
    chStrokeT = chStrokeT + dt * 1.5
    local v=(math.sin(chStrokeT)+1)/2
    CHStroke.Color=Color3.fromRGB(v*120,v*120,v*120)
end)

local CreditLabel=Instance.new("TextLabel",ScreenGui)
CreditLabel.Size=UDim2.new(0,150,0,16); CreditLabel.Position=UDim2.new(0,6,1,-20)
CreditLabel.BackgroundTransparency=1; CreditLabel.Text="By: @Malinnowski"
CreditLabel.Font=Enum.Font.GothamBold; CreditLabel.TextSize=10; CreditLabel.ZIndex=5
CreditLabel.TextXAlignment=Enum.TextXAlignment.Left
local CreditGrad=Instance.new("UIGradient",CreditLabel)
CreditGrad.Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(255,255,255)),
    ColorSequenceKeypoint.new(0.5,Color3.fromRGB(160,160,160)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(255,255,255))
})
RunService.Heartbeat:Connect(function() CreditGrad.Offset=Vector2.new(math.sin(tick()*1.8)*0.9,0) end)

-- ══════════════════════════════════════════
--  FOV CIRCLE
-- ══════════════════════════════════════════
local FOVCircle=Instance.new("Frame",ScreenGui)
FOVCircle.BackgroundTransparency=1; FOVCircle.BorderSizePixel=0; FOVCircle.ZIndex=50; FOVCircle.Visible=false
Instance.new("UICorner",FOVCircle).CornerRadius=UDim.new(1,0)
local FOVStroke=Instance.new("UIStroke",FOVCircle)
FOVStroke.Thickness=1.5; FOVStroke.Color=Color3.fromRGB(255,255,255)
FOVStroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border

RunService.Heartbeat:Connect(function()
    if not values["aimbot"] then FOVCircle.Visible=false; return end
    local cam=workspace.CurrentCamera; if not cam then return end
    local vp=cam.ViewportSize
    local fovDeg=values["aim_fov"] or 90
    local radius=(fovDeg/180)*(vp.X/2)
    radius=math.clamp(radius,10,vp.X)
    FOVCircle.Size=UDim2.new(0,radius*2,0,radius*2)
    FOVCircle.Position=UDim2.new(0,vp.X/2-radius,0,vp.Y/2-radius)
    FOVCircle.Visible=true
end)

-- ══════════════════════════════════════════
--  KEYBIND PANEL
-- ══════════════════════════════════════════
local KBPanel=Instance.new("Frame",ScreenGui)
KBPanel.Size=UDim2.new(0,270,0,50); KBPanel.Position=UDim2.new(0,10,0,54)
KBPanel.BackgroundColor3=Color3.fromRGB(6,6,6); KBPanel.BorderSizePixel=0
KBPanel.ZIndex=25; KBPanel.Visible=false; KBPanel.AutomaticSize=Enum.AutomaticSize.Y
Instance.new("UICorner",KBPanel).CornerRadius=UDim.new(0,12)
local KBStroke=Instance.new("UIStroke",KBPanel); KBStroke.Color=Color3.fromRGB(255,255,255); KBStroke.Thickness=1.2
local kbStrokeT=0
RunService.Heartbeat:Connect(function(dt)
    if not KBPanel.Visible then return end
    kbStrokeT = kbStrokeT + dt * 2
    local v=(math.sin(kbStrokeT)+1)/2
    KBStroke.Color=Color3.fromRGB(v*255,v*255,v*255)
end)
local KBHead=Instance.new("Frame",KBPanel)
KBHead.Size=UDim2.new(1,0,0,40); KBHead.BackgroundTransparency=1; KBHead.ZIndex=26
local KBHeadLbl=Instance.new("TextLabel",KBHead)
KBHeadLbl.Size=UDim2.new(1,0,1,0); KBHeadLbl.BackgroundTransparency=1; KBHeadLbl.Text="KEYBINDS"
KBHeadLbl.Font=Enum.Font.GothamBold; KBHeadLbl.TextSize=12; KBHeadLbl.TextColor3=Color3.fromRGB(255,255,255)
KBHeadLbl.TextXAlignment=Enum.TextXAlignment.Center; KBHeadLbl.ZIndex=27
local KBDiv=Instance.new("Frame",KBPanel)
KBDiv.Size=UDim2.new(1,-20,0,1); KBDiv.Position=UDim2.new(0,10,0,40)
KBDiv.BackgroundColor3=Color3.fromRGB(22,22,22); KBDiv.BorderSizePixel=0; KBDiv.ZIndex=26
local KBList=Instance.new("Frame",KBPanel)
KBList.Size=UDim2.new(1,-16,0,0); KBList.Position=UDim2.new(0,8,0,46)
KBList.BackgroundTransparency=1; KBList.ZIndex=26; KBList.AutomaticSize=Enum.AutomaticSize.Y
local KBLayout=Instance.new("UIListLayout",KBList)
KBLayout.Padding=UDim.new(0,3); KBLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center
Instance.new("UIPadding",KBList).PaddingBottom=UDim.new(0,8)
local kbDrag,kbDragStart,kbDragPos=false,nil,nil
KBHead.InputBegan:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1 then
        kbDrag=true; kbDragStart=inp.Position; kbDragPos=KBPanel.Position
        inp.Changed:Connect(function() if inp.UserInputState==Enum.UserInputState.End then kbDrag=false end end)
    end
end)
KBPanel.InputChanged:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseWheel then
        local delta=-inp.Position.Z*40
        local maxY=math.max(0,KBList.AbsoluteContentSize.Y-KBPanel.AbsoluteSize.Y+60)
        local cur=KBList.Position.Y.Offset
        KBList.Position=UDim2.new(0,8,0,math.clamp(cur-delta,-maxY,46))
    end
end)
UIS.InputChanged:Connect(function(inp)
    if kbDrag and inp.UserInputType==Enum.UserInputType.MouseMovement then
        local d=inp.Position-kbDragStart
        KBPanel.Position=UDim2.new(kbDragPos.X.Scale,kbDragPos.X.Offset+d.X,kbDragPos.Y.Scale,kbDragPos.Y.Offset+d.Y)
    end
    if wmDrag and inp.UserInputType==Enum.UserInputType.MouseMovement then
        local d=inp.Position-wmDragStart
        WatermarkFrame.Position=UDim2.new(wmDragPos.X.Scale,wmDragPos.X.Offset+d.X,wmDragPos.Y.Scale,wmDragPos.Y.Offset+d.Y)
    end
end)

local function rebuildKBPanel()
    for _,c in ipairs(KBList:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
    local hasAny=false
    for key,kname in pairs(keybinds) do
        if kname and values[key]==true then
            hasAny=true
            local displayName=notifyNames[key] or string.upper(key:gsub("_"," "))
            local row=Instance.new("Frame",KBList)
            row.Size=UDim2.new(1,0,0,32); row.BackgroundColor3=Color3.fromRGB(11,11,11)
            row.BorderSizePixel=0; row.ZIndex=27
            Instance.new("UICorner",row).CornerRadius=UDim.new(0,8)
            Instance.new("UIStroke",row).Color=Color3.fromRGB(22,22,22)
            local fnLbl=Instance.new("TextLabel",row)
            fnLbl.Size=UDim2.new(0.55,0,1,0); fnLbl.Position=UDim2.new(0,14,0,0)
            fnLbl.BackgroundTransparency=1; fnLbl.Text=displayName
            fnLbl.Font=Enum.Font.GothamBold; fnLbl.TextSize=11
            fnLbl.TextColor3=Color3.fromRGB(210,210,210)
            fnLbl.TextXAlignment=Enum.TextXAlignment.Left; fnLbl.ZIndex=28
            local badgeW=math.max(44,#kname*9+16)
            local badge=Instance.new("Frame",row)
            badge.Size=UDim2.new(0,badgeW,0,22); badge.AnchorPoint=Vector2.new(0.5,0.5)
            badge.Position=UDim2.new(0.775,0,0.5,0)
            badge.BackgroundColor3=Color3.fromRGB(18,18,18); badge.BorderSizePixel=0; badge.ZIndex=28
            Instance.new("UICorner",badge).CornerRadius=UDim.new(0,6)
            Instance.new("UIStroke",badge).Color=Color3.fromRGB(55,55,55)
            local bLbl=Instance.new("TextLabel",badge)
            bLbl.Size=UDim2.new(1,0,1,0); bLbl.BackgroundTransparency=1
            bLbl.Text=kname; bLbl.Font=Enum.Font.GothamBold; bLbl.TextSize=10
            bLbl.TextColor3=Color3.fromRGB(255,255,255)
            bLbl.TextXAlignment=Enum.TextXAlignment.Center; bLbl.ZIndex=29
        end
    end
    if not hasAny then
        local empty=Instance.new("TextLabel",KBList)
        empty.Size=UDim2.new(1,0,0,28); empty.BackgroundTransparency=1
        empty.Text="No active binds"; empty.Font=Enum.Font.Gotham; empty.TextSize=10
        empty.TextColor3=Color3.fromRGB(50,50,50)
        empty.TextXAlignment=Enum.TextXAlignment.Center; empty.ZIndex=27
    end
end

-- ══════════════════════════════════════════
--  KEYBIND PICKER
-- ══════════════════════════════════════════
local bindingKey=nil; local bindingConn=nil
local SKIP_KEYS={"LeftShift","RightShift","LeftControl","RightControl","LeftAlt","RightAlt","LeftMeta","RightMeta","CapsLock","Unknown"}
local function isSkipKey(kc)
    for _,sk in ipairs(SKIP_KEYS) do if kc==sk then return true end end
    return false
end

local PickerFrame=Instance.new("Frame",ScreenGui)
PickerFrame.Size=UDim2.new(0,240,0,72); PickerFrame.Position=UDim2.new(0.5,-120,0.5,-36)
PickerFrame.BackgroundColor3=Color3.fromRGB(8,8,8); PickerFrame.BorderSizePixel=0
PickerFrame.ZIndex=200; PickerFrame.Visible=false
Instance.new("UICorner",PickerFrame).CornerRadius=UDim.new(0,14)
local PickerStroke=Instance.new("UIStroke",PickerFrame)
PickerStroke.Color=Color3.fromRGB(255,255,255); PickerStroke.Thickness=1.5
local pickerT=0
RunService.Heartbeat:Connect(function(dt)
    if not PickerFrame.Visible then return end
    pickerT = pickerT + dt * 3
    local v=(math.sin(pickerT)+1)/2
    PickerStroke.Color=Color3.fromRGB(v*255,v*255,v*255)
end)
local PickerOverlay=Instance.new("Frame",ScreenGui)
PickerOverlay.Size=UDim2.new(1,0,1,0); PickerOverlay.BackgroundTransparency=0.88
PickerOverlay.BackgroundColor3=Color3.fromRGB(0,0,0)
PickerOverlay.ZIndex=199; PickerOverlay.Visible=false; PickerOverlay.BorderSizePixel=0
local PickerTitle=Instance.new("TextLabel",PickerFrame)
PickerTitle.Size=UDim2.new(1,0,0,40); PickerTitle.BackgroundTransparency=1
PickerTitle.Text="Press any key to bind"
PickerTitle.Font=Enum.Font.GothamBold; PickerTitle.TextSize=14
PickerTitle.TextColor3=Color3.fromRGB(255,255,255); PickerTitle.ZIndex=201
local PickerSub=Instance.new("TextLabel",PickerFrame)
PickerSub.Size=UDim2.new(1,0,0,22); PickerSub.Position=UDim2.new(0,0,0,44)
PickerSub.BackgroundTransparency=1; PickerSub.Text="[ESC] cancel   [X] remove bind"
PickerSub.Font=Enum.Font.Gotham; PickerSub.TextSize=8
PickerSub.TextColor3=Color3.fromRGB(65,65,65); PickerSub.ZIndex=201

local function openPicker(key, onDone)
    if pickerOpen and bindingKey==key then return end
    if pickerOpen and bindingConn then bindingConn:Disconnect(); bindingConn=nil end
    pickerOpen=true; bindingKey=key
    PickerOverlay.Visible=true; PickerFrame.Visible=true
    PickerFrame.Size=UDim2.new(0,210,0,60)
    TweenService:Create(PickerFrame,TweenInfo.new(0.22,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0,240,0,72)}):Play()
    local function closePicker()
        pickerOpen=false; bindingKey=nil
        TweenService:Create(PickerFrame,TweenInfo.new(0.14,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Size=UDim2.new(0,210,0,60)}):Play()
        task.delay(0.16,function() PickerFrame.Visible=false; PickerOverlay.Visible=false end)
        if bindingConn then bindingConn:Disconnect(); bindingConn=nil end
        rebuildKBPanel()
        if onDone then onDone() end
    end
    local mouseReady = false
    task.delay(0.1, function() mouseReady = true end)
    bindingConn=UIS.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then
            if not mouseReady then return end
            keybinds[key]="MB1"; closePicker(); return
        end
        if inp.UserInputType==Enum.UserInputType.MouseButton2 then keybinds[key]="MB2"; closePicker(); return end
        if inp.UserInputType==Enum.UserInputType.MouseButton3 then keybinds[key]="MB3"; closePicker(); return end
        if inp.UserInputType==Enum.UserInputType.Keyboard then
            local kc=tostring(inp.KeyCode):gsub("Enum%.KeyCode%.","")
            if kc=="" or isSkipKey(kc) then return end
            if kc=="Escape" then closePicker(); return end
            if kc=="X" then keybinds[key]=nil; closePicker(); return end
            keybinds[key]=kc; closePicker()
        end
    end)
end

-- ══════════════════════════════════════════
--  AIMBOT
-- ══════════════════════════════════════════
local aimbotConn=nil; local aimbotHeld=false; local aimbotLockedTarget=nil

local function getAimTarget()
    local cam=workspace.CurrentCamera; if not cam then return nil end
    local vp=cam.ViewportSize
    local cx,cy=vp.X/2,vp.Y/2
    local fovDeg=values["aim_fov"] or 90
    local pixelFOV=(fovDeg/180)*(vp.X/2)
    local best=nil; local bestDist=pixelFOV+1
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=player then
            local ch=p.Character
            if ch then
                local hum=ch:FindFirstChild("Humanoid")
                local head=ch:FindFirstChild("Head")
                if hum and hum.Health>0 and head then
                    local skip=rootPart and (head.Position-rootPart.Position).Magnitude>(values["esp_dist"] or 500)
                    if not skip then
                        local sp,onScreen=cam:WorldToScreenPoint(head.Position)
                        if onScreen then
                            local sd=Vector2.new(sp.X-cx,sp.Y-cy).Magnitude
                            if sd<=pixelFOV and sd<bestDist then bestDist=sd; best=head end
                        end
                    end
                end
            end
        end
    end
    return best
end

local function startAimbot()
    if aimbotConn then aimbotConn:Disconnect(); aimbotConn=nil end
    aimbotConn=RunService.RenderStepped:Connect(function(dt)
        if not values["aimbot"] or not aimbotHeld then return end
        local cam=workspace.CurrentCamera; if not cam then return end
        if aimbotLockedTarget then
            local pChar=aimbotLockedTarget.Parent
            local pHum=pChar and pChar:FindFirstChild("Humanoid")
            if not aimbotLockedTarget.Parent or (pHum and pHum.Health<=0) then
                aimbotLockedTarget=nil
            end
        end
        if not aimbotLockedTarget then aimbotLockedTarget=getAimTarget() end
        local target=aimbotLockedTarget; if not target then return end

        local smooth=math.clamp(values["aim_smooth"] or 5,1,20)
        local headPos=target.Position + target.CFrame.UpVector * 0.2
        local camPos=cam.CFrame.Position
        if (headPos-camPos).Magnitude<0.1 then return end

        local vp=cam.ViewportSize
        local sp=cam:WorldToScreenPoint(headPos)
        local dist2D=Vector2.new(sp.X - vp.X/2, sp.Y - vp.Y/2).Magnitude
        if dist2D < 2 then return end

        local targetCF=CFrame.lookAt(camPos, headPos)
        local alpha=math.clamp(dt * (22 - smooth) * 8, 0, 1)
        local lerpedCF = cam.CFrame:Lerp(targetCF, alpha)
        cam.CFrame = CFrame.fromMatrix(camPos, lerpedCF.RightVector, lerpedCF.UpVector, -lerpedCF.LookVector)
    end)
end
local function stopAimbot()
    if aimbotConn then aimbotConn:Disconnect(); aimbotConn=nil end
end

-- ══════════════════════════════════════════
--  GLOBAL KEYBIND LISTENER
-- ══════════════════════════════════════════
local function getInputName(inp)
    if inp.UserInputType==Enum.UserInputType.Keyboard then
        local kc=tostring(inp.KeyCode):gsub("Enum%.KeyCode%.","")
        if kc=="" or isSkipKey(kc) then return nil end
        return kc
    elseif inp.UserInputType==Enum.UserInputType.MouseButton1 then return "MB1"
    elseif inp.UserInputType==Enum.UserInputType.MouseButton2 then return "MB2"
    elseif inp.UserInputType==Enum.UserInputType.MouseButton3 then return "MB3"
    end
    return nil
end

UIS.InputBegan:Connect(function(inp,gpe)
    if pickerOpen then return end
    if gpe and inp.UserInputType~=Enum.UserInputType.Keyboard then return end
    local inputName=getInputName(inp); if not inputName then return end
    for key,kname in pairs(keybinds) do
        if kname==inputName then
            if key=="aimbot" then
                aimbotHeld=true; aimbotLockedTarget=nil
            elseif toggleCallbacks[key] then
                task.spawn(toggleCallbacks[key])
            end
        end
    end
end)
UIS.InputEnded:Connect(function(inp)
    local inputName=getInputName(inp); if not inputName then return end
    if keybinds["aimbot"] and keybinds["aimbot"]==inputName then
        aimbotHeld=false; aimbotLockedTarget=nil
    end
end)

-- ══════════════════════════════════════════
--  MAIN FRAME
-- ══════════════════════════════════════════
local MainFrame=Instance.new("Frame",ScreenGui)
MainFrame.Size=UDim2.new(0,540,0,420)
MainFrame.Position=UDim2.new(0.5,-270,0.5,-210)
MainFrame.BackgroundColor3=Color3.fromRGB(5,5,5)
MainFrame.BorderSizePixel=0; MainFrame.Visible=false; MainFrame.ZIndex=30
MainFrame.ClipsDescendants=true
Instance.new("UICorner",MainFrame).CornerRadius=UDim.new(0,14)
local MainStroke=Instance.new("UIStroke",MainFrame)
MainStroke.Thickness=1.5; MainStroke.Color=Color3.fromRGB(255,255,255)
local UIScaleObj=Instance.new("UIScale",MainFrame); UIScaleObj.Scale=1.0

local InnerFrame=Instance.new("Frame",MainFrame)
InnerFrame.Size=UDim2.new(1,0,1,0); InnerFrame.BackgroundTransparency=1; InnerFrame.ZIndex=30

local TopLine=Instance.new("Frame",InnerFrame)
TopLine.Size=UDim2.new(0.55,0,0,1); TopLine.Position=UDim2.new(0.225,0,0,0)
TopLine.BackgroundColor3=Color3.fromRGB(255,255,255); TopLine.BorderSizePixel=0; TopLine.ZIndex=31
local TLG=Instance.new("UIGradient",TopLine)
TLG.Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(0,0,0)),
    ColorSequenceKeypoint.new(0.5,Color3.fromRGB(255,255,255)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(0,0,0))
})

local BottomLabel=Instance.new("TextLabel",InnerFrame)
BottomLabel.Size=UDim2.new(1,-16,0,14); BottomLabel.Position=UDim2.new(0,8,1,-20)
BottomLabel.BackgroundTransparency=1; BottomLabel.Text="thank you for using this script  ♡"
BottomLabel.Font=Enum.Font.Gotham; BottomLabel.TextSize=9
BottomLabel.TextColor3=Color3.fromRGB(255,255,255); BottomLabel.TextTransparency=0.65
BottomLabel.TextXAlignment=Enum.TextXAlignment.Right; BottomLabel.ZIndex=31

local snowTimer=0
RunService.Heartbeat:Connect(function(dt)
    if not guiVisible then return end
    snowTimer = snowTimer + dt
    if snowTimer<0.065 then return end; snowTimer=0
    local side=math.random(1,4); local sp
    if side==1 then sp=UDim2.new(math.random(5,95)/100,0,0,-8)
    elseif side==2 then sp=UDim2.new(math.random(5,95)/100,0,1,2)
    elseif side==3 then sp=UDim2.new(0,-8,math.random(5,95)/100,0)
    else sp=UDim2.new(1,2,math.random(5,95)/100,0) end
    local img=Instance.new("ImageLabel",MainFrame)
    img.Size=UDim2.new(0,math.random(8,16),0,math.random(8,16))
    img.Position=sp; img.BackgroundTransparency=1
    img.Image="rbxassetid://17193841062"; img.ImageTransparency=1
    img.ZIndex=32; img.Rotation=math.random(0,360)
    local dx=(math.random()-0.5)*120; local dy=(math.random()-0.5)*120
    local tp=UDim2.new(sp.X.Scale,sp.X.Offset+dx,sp.Y.Scale,sp.Y.Offset+dy)
    TweenService:Create(img,TweenInfo.new(0.12),{ImageTransparency=0}):Play()
    task.delay(0.12,function()
        TweenService:Create(img,TweenInfo.new(1.6,Enum.EasingStyle.Quad),{ImageTransparency=1,Position=tp,Rotation=img.Rotation+math.random(-200,200)}):Play()
        task.delay(1.7,function() img:Destroy() end)
    end)
end)

-- HEADER
local Header=Instance.new("Frame",InnerFrame)
Header.Size=UDim2.new(1,0,0,52); Header.BackgroundTransparency=1; Header.ZIndex=31

local TitleLabel=Instance.new("TextLabel",Header)
TitleLabel.Size=UDim2.new(0,280,0,28); TitleLabel.Position=UDim2.new(0,14,0,8)
TitleLabel.BackgroundTransparency=1; TitleLabel.Text="DM ARENA SCRIPT  |  V3"
TitleLabel.Font=Enum.Font.GothamBold; TitleLabel.TextSize=16
TitleLabel.TextColor3=Color3.fromRGB(255,255,255)
TitleLabel.TextXAlignment=Enum.TextXAlignment.Left; TitleLabel.ZIndex=32
local TitleGrad=Instance.new("UIGradient",TitleLabel)
TitleGrad.Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(255,255,255)),
    ColorSequenceKeypoint.new(0.3,Color3.fromRGB(60,60,60)),
    ColorSequenceKeypoint.new(0.5,Color3.fromRGB(255,255,255)),
    ColorSequenceKeypoint.new(0.7,Color3.fromRGB(60,60,60)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(255,255,255))
})

local HintLabel=Instance.new("TextLabel",Header)
HintLabel.Size=UDim2.new(0,200,0,14); HintLabel.Position=UDim2.new(0,14,0,36)
HintLabel.BackgroundTransparency=1; HintLabel.Text="K — hide / show"
HintLabel.Font=Enum.Font.Gotham; HintLabel.TextSize=9
HintLabel.TextColor3=Color3.fromRGB(255,255,255); HintLabel.TextTransparency=0.4
HintLabel.TextXAlignment=Enum.TextXAlignment.Left; HintLabel.ZIndex=32

local function makeSocialBtn(parent,iconId,label,xPos,link)
    local wrap=Instance.new("Frame",parent)
    wrap.Size=UDim2.new(0,90,0,26); wrap.Position=UDim2.new(0,xPos,0,13)
    wrap.BackgroundTransparency=1; wrap.ZIndex=32
    local icon=Instance.new("ImageLabel",wrap)
    icon.Size=UDim2.new(0,18,0,18); icon.Position=UDim2.new(0,0,0.5,-9)
    icon.BackgroundTransparency=1; icon.Image="rbxassetid://"..iconId
    icon.ImageColor3=Color3.fromRGB(255,255,255); icon.ZIndex=33
    local lbl2=Instance.new("TextLabel",wrap)
    lbl2.Size=UDim2.new(1,-24,1,0); lbl2.Position=UDim2.new(0,22,0,0)
    lbl2.BackgroundTransparency=1; lbl2.Text=label; lbl2.Font=Enum.Font.GothamBold
    lbl2.TextSize=12; lbl2.TextColor3=Color3.fromRGB(255,255,255)
    lbl2.TextTransparency=0.35; lbl2.TextXAlignment=Enum.TextXAlignment.Left; lbl2.ZIndex=33
    local hb=Instance.new("TextButton",wrap)
    hb.Size=UDim2.new(1,0,1,0); hb.BackgroundTransparency=1; hb.Text=""; hb.ZIndex=34
    hb.MouseEnter:Connect(function()
        TweenService:Create(wrap,TweenInfo.new(0.15),{Size=UDim2.new(0,100,0,30),Position=UDim2.new(0,xPos-5,0,11)}):Play()
        TweenService:Create(lbl2,TweenInfo.new(0.15),{TextTransparency=0}):Play()
    end)
    hb.MouseLeave:Connect(function()
        TweenService:Create(wrap,TweenInfo.new(0.15),{Size=UDim2.new(0,90,0,26),Position=UDim2.new(0,xPos,0,13)}):Play()
        TweenService:Create(lbl2,TweenInfo.new(0.15),{TextTransparency=0.35}):Play()
    end)
    hb.MouseButton1Click:Connect(function()
        if setclipboard then setclipboard(link) end; task.spawn(showToast)
    end)
end
makeSocialBtn(Header,"14895333462","Telegram",290,"https://t.me/dmarenascripts")
makeSocialBtn(Header,"73132811772878","Discord",390,"https://discord.gg/rjzVs24N")

local CloseBtn=Instance.new("ImageButton",InnerFrame)
CloseBtn.Size=UDim2.new(0,22,0,22); CloseBtn.Position=UDim2.new(1,-32,0,15)
CloseBtn.BackgroundTransparency=1; CloseBtn.Image="rbxassetid://14219436180"
CloseBtn.ImageColor3=Color3.fromRGB(70,70,70); CloseBtn.ZIndex=34
CloseBtn.MouseEnter:Connect(function() TweenService:Create(CloseBtn,TweenInfo.new(0.15),{ImageColor3=Color3.fromRGB(255,255,255)}):Play() end)
CloseBtn.MouseLeave:Connect(function() TweenService:Create(CloseBtn,TweenInfo.new(0.15),{ImageColor3=Color3.fromRGB(70,70,70)}):Play() end)

local HeaderDiv=Instance.new("Frame",InnerFrame)
HeaderDiv.Size=UDim2.new(1,-28,0,1); HeaderDiv.Position=UDim2.new(0,14,0,52)
HeaderDiv.BackgroundColor3=Color3.fromRGB(20,20,20); HeaderDiv.BorderSizePixel=0; HeaderDiv.ZIndex=31

-- SIDEBAR
local SideBar=Instance.new("Frame",InnerFrame)
SideBar.Size=UDim2.new(0,112,1,-72); SideBar.Position=UDim2.new(0,8,0,58)
SideBar.BackgroundTransparency=1; SideBar.ZIndex=31
local SideList=Instance.new("UIListLayout",SideBar)
SideList.Padding=UDim.new(0,3); SideList.HorizontalAlignment=Enum.HorizontalAlignment.Center
Instance.new("UIPadding",SideBar).PaddingTop=UDim.new(0,6)
local SideDiv=Instance.new("Frame",InnerFrame)
SideDiv.Size=UDim2.new(0,1,1,-74); SideDiv.Position=UDim2.new(0,124,0,58)
SideDiv.BackgroundColor3=Color3.fromRGB(20,20,20); SideDiv.BorderSizePixel=0; SideDiv.ZIndex=31

local ContentScroll=Instance.new("ScrollingFrame",InnerFrame)
ContentScroll.Size=UDim2.new(1,-142,1,-80); ContentScroll.Position=UDim2.new(0,132,0,58)
ContentScroll.BackgroundTransparency=1; ContentScroll.BorderSizePixel=0
ContentScroll.ScrollBarThickness=2; ContentScroll.ScrollBarImageColor3=Color3.fromRGB(45,45,45)
ContentScroll.ZIndex=31; ContentScroll.CanvasSize=UDim2.new(0,0,0,0)
ContentScroll.ScrollingDirection=Enum.ScrollingDirection.Y
ContentScroll.ElasticBehavior=Enum.ElasticBehavior.Never

UIS.InputChanged:Connect(function(inp)
    if inp.UserInputType~=Enum.UserInputType.MouseWheel then return end
    local mp=UIS:GetMouseLocation()
    local delta=-inp.Position.Z*55

    if guiVisible then
        local af=MainFrame.AbsolutePosition; local as=MainFrame.AbsoluteSize
        if mp.X>=af.X and mp.X<=af.X+as.X and mp.Y>=af.Y and mp.Y<=af.Y+as.Y then
            local maxY=math.max(0,ContentScroll.AbsoluteCanvasSize.Y-ContentScroll.AbsoluteSize.Y)
            ContentScroll.CanvasPosition=Vector2.new(0,math.clamp(ContentScroll.CanvasPosition.Y+delta,0,maxY))
            return
        end
    end

    if StaffPanel and StaffPanel.Visible then
        local af2=StaffPanel.AbsolutePosition; local as2=StaffPanel.AbsoluteSize
        if mp.X>=af2.X and mp.X<=af2.X+as2.X and mp.Y>=af2.Y and mp.Y<=af2.Y+as2.Y then
            local maxY=math.max(0,SFScroll.AbsoluteCanvasSize.Y-SFScroll.AbsoluteSize.Y)
            SFScroll.CanvasPosition=Vector2.new(0,math.clamp(SFScroll.CanvasPosition.Y+delta,0,maxY))
            return
        end
    end

    if KBPanel.Visible then
        local af3=KBPanel.AbsolutePosition; local as3=KBPanel.AbsoluteSize
        if mp.X>=af3.X and mp.X<=af3.X+as3.X and mp.Y>=af3.Y and mp.Y<=af3.Y+as3.Y then
            local maxY=math.max(0,KBLayout.AbsoluteContentSize.Y-KBPanel.AbsoluteSize.Y+60)
            local cur=KBList.Position.Y.Offset
            KBList.Position=UDim2.new(0,8,0,math.clamp(cur-delta,-maxY,46))
        end
    end
end)

-- ══════════════════════════════════════════
--  STAFF SPECTATOR
-- ══════════════════════════════════════════
local GroupService = game:GetService("GroupService")

local StaffPanel = Instance.new("Frame", ScreenGui)
StaffPanel.Size = UDim2.new(0, 260, 0, 320)
StaffPanel.Position = UDim2.new(1, 280, 0.5, -160)
StaffPanel.BackgroundColor3 = Color3.fromRGB(6, 6, 6)
StaffPanel.BorderSizePixel = 0; StaffPanel.ZIndex = 85
StaffPanel.Visible = false; StaffPanel.ClipsDescendants = true
Instance.new("UICorner", StaffPanel).CornerRadius = UDim.new(0, 14)
local StaffStroke = Instance.new("UIStroke", StaffPanel)
StaffStroke.Color = Color3.fromRGB(200,200,200); StaffStroke.Thickness = 1.5
local staffStrokeT = 0
RunService.Heartbeat:Connect(function(dt)
    if not StaffPanel.Visible then return end
    staffStrokeT = staffStrokeT + dt * 2
    local v = (math.sin(staffStrokeT) + 1) / 2
    StaffStroke.Color = Color3.fromRGB(v*255, v*255, v*255)
end)

local sfDrag, sfDragStart, sfDragPos = false, nil, nil
local SFHeader = Instance.new("Frame", StaffPanel)
SFHeader.Size = UDim2.new(1,0,0,46); SFHeader.BackgroundTransparency = 1; SFHeader.ZIndex = 86
SFHeader.InputBegan:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1 then
        sfDrag=true; sfDragStart=inp.Position; sfDragPos=StaffPanel.Position
        inp.Changed:Connect(function() if inp.UserInputState==Enum.UserInputState.End then sfDrag=false end end)
    end
end)
UIS.InputChanged:Connect(function(inp)
    if sfDrag and inp.UserInputType==Enum.UserInputType.MouseMovement then
        local d=inp.Position-sfDragStart
        StaffPanel.Position=UDim2.new(sfDragPos.X.Scale,sfDragPos.X.Offset+d.X,sfDragPos.Y.Scale,sfDragPos.Y.Offset+d.Y)
    end
end)

local SFTitle = Instance.new("TextLabel", SFHeader)
SFTitle.Size = UDim2.new(1,0,1,0); SFTitle.Position = UDim2.new(0,0,0,0)
SFTitle.BackgroundTransparency = 1
SFTitle.Text = "STAFF"
SFTitle.Font = Enum.Font.GothamBold; SFTitle.TextSize = 13
SFTitle.TextColor3 = Color3.fromRGB(255,255,255)
SFTitle.TextXAlignment = Enum.TextXAlignment.Center
SFTitle.ZIndex = 87
local SFTitleGrad = Instance.new("UIGradient", SFTitle)
SFTitleGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150,150,150)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255,255,255)),
})
RunService.Heartbeat:Connect(function() SFTitleGrad.Offset = Vector2.new(math.sin(tick()*2)*0.7, 0) end)

local SFDiv = Instance.new("Frame", StaffPanel)
SFDiv.Size = UDim2.new(1,-24,0,1); SFDiv.Position = UDim2.new(0,12,0,46)
SFDiv.BackgroundColor3 = Color3.fromRGB(30,30,30); SFDiv.BorderSizePixel = 0; SFDiv.ZIndex = 86

local SFScroll = Instance.new("ScrollingFrame", StaffPanel)
SFScroll.Size = UDim2.new(1,-8,1,-58); SFScroll.Position = UDim2.new(0,4,0,52)
SFScroll.BackgroundTransparency = 1; SFScroll.BorderSizePixel = 0
SFScroll.ScrollBarThickness = 2; SFScroll.ScrollBarImageColor3 = Color3.fromRGB(80,80,80)
SFScroll.ZIndex = 86; SFScroll.CanvasSize = UDim2.new(0,0,0,0)
local SFLayout = Instance.new("UIListLayout", SFScroll)
SFLayout.Padding = UDim.new(0,4)
Instance.new("UIPadding", SFScroll).PaddingTop = UDim.new(0,4)

local rankCache = {}

local function getGroupRank(p)
    if rankCache[p.UserId] then return rankCache[p.UserId].rank, rankCache[p.UserId].role end
    task.spawn(function()
        pcall(function()
            local groups = GroupService:GetGroupsAsync(p.UserId)
            for _, g in ipairs(groups) do
                if g.Id == STAFF_GROUP_ID and g.Rank > 10 then
                    rankCache[p.UserId] = {rank = g.Rank, role = g.Role}
                    break
                end
            end
        end)
    end)
    return nil, nil
end

local function rebuildStaffList()
    for _,c in ipairs(SFScroll:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
    local staffFound = false
    for _,p in ipairs(Players:GetPlayers()) do
        local rank, role = getGroupRank(p)
        if rank and rank > 10 then
            staffFound = true
            local row = Instance.new("Frame", SFScroll)
            row.Size = UDim2.new(1,-8,0,44); row.BackgroundColor3 = Color3.fromRGB(12,12,12)
            row.BorderSizePixel = 0; row.ZIndex = 87
            Instance.new("UICorner", row).CornerRadius = UDim.new(0,10)
            local rowStroke = Instance.new("UIStroke", row)
            rowStroke.Color = Color3.fromRGB(50,50,50); rowStroke.Thickness = 1
            local avatar = Instance.new("ImageLabel", row)
            avatar.Size = UDim2.new(0,32,0,32); avatar.Position = UDim2.new(0,8,0.5,-16)
            avatar.BackgroundColor3 = Color3.fromRGB(20,20,20)
            avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId="..p.UserId.."&width=48&height=48&format=png"
            avatar.ZIndex = 88
            Instance.new("UICorner", avatar).CornerRadius = UDim.new(1,0)
            local nameLbl = Instance.new("TextLabel", row)
            nameLbl.Size = UDim2.new(1,-52,0,18); nameLbl.Position = UDim2.new(0,48,0,6)
            nameLbl.BackgroundTransparency = 1; nameLbl.Text = p.Name
            nameLbl.Font = Enum.Font.GothamBold; nameLbl.TextSize = 12
            nameLbl.TextColor3 = Color3.fromRGB(255,255,255)
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left; nameLbl.ZIndex = 88
            local rankLbl = Instance.new("TextLabel", row)
            rankLbl.Size = UDim2.new(1,-52,0,14); rankLbl.Position = UDim2.new(0,48,0,24)
            rankLbl.BackgroundTransparency = 1; rankLbl.Text = role or "Staff"
            rankLbl.Font = Enum.Font.Gotham; rankLbl.TextSize = 9
            rankLbl.TextColor3 = Color3.fromRGB(180,180,180)
            rankLbl.TextXAlignment = Enum.TextXAlignment.Left; rankLbl.ZIndex = 88
        end
    end
    if not staffFound then
        local empty = Instance.new("TextLabel", SFScroll)
        empty.Size = UDim2.new(1,0,0,40); empty.BackgroundTransparency = 1
        empty.Text = "No staff online"; empty.Font = Enum.Font.GothamBold; empty.TextSize = 11
        empty.TextColor3 = Color3.fromRGB(80,80,80)
        empty.TextXAlignment = Enum.TextXAlignment.Center; empty.ZIndex = 87
    end
    task.spawn(function()
        task.wait(); task.wait()
        SFScroll.CanvasSize = UDim2.new(0,0,0,SFLayout.AbsoluteContentSize.Y+10)
    end)
end

local staffVisible = false
local function showStaffPanel()
    staffVisible = true
    rankCache = {}
    StaffPanel.Visible = true
    rebuildStaffList()
    TweenService:Create(StaffPanel, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -274, 0.5, -160)
    }):Play()
    task.spawn(function()
        while staffVisible do task.wait(3); if staffVisible then rebuildStaffList() end end
    end)
end

local function hideStaffPanel()
    staffVisible = false
    TweenService:Create(StaffPanel, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
        Position = UDim2.new(1, 280, 0.5, -160)
    }):Play()
    task.delay(0.35, function() if not staffVisible then StaffPanel.Visible = false end end)
end

-- ══════════════════════════════════════════
--  TAB DATA  (MOVEMENT убран, Fast Reload убран)
-- ══════════════════════════════════════════
local tabs={
    {name="MAIN",     icon="14219516515"},
    {name="AIM",      icon="11738355467"},
    {name="MISC",     icon="16081386298"},
    {name="FPS+",     icon=ICON_FPS_ID},
    {name="SETTINGS", icon="9405931578"},
}

local tabContent={
    MAIN={
        {type="section",name="ESP — Players"},
        {type="toggle",name="ESP Enable",    key="esp_players",func="esp_toggle",  notify="ESP"},
        {type="toggle",name="Show Names",    key="esp_names",                      notify="ESP Names",  nobind=true},
        {type="toggle",name="Show Health",   key="esp_health",                     notify="ESP Health", nobind=true},
        {type="toggle",name="Show Distance", key="esp_dist_show",                  notify="ESP Dist",   nobind=true},
        {type="toggle",name="Show Weapon",   key="esp_weapon",                     notify="ESP Weapon", nobind=true},
        {type="toggle",name="ESP Highlight", key="esp_boxes",  func="esp_boxes",   notify="ESP Boxes",  nobind=true},
        {type="slider",name="Max Distance",  key="esp_dist",   min=50,max=2000,val=500},
    },
    AIM={
        {type="section",name="Aimbot — Hold key to aim"},
        {type="toggle",name="Aimbot",        key="aimbot",     func="aimbot_func", notify="Aimbot"},
        {type="slider",name="FOV",           key="aim_fov",    min=1,max=360,val=90},
        {type="slider",name="Smooth",        key="aim_smooth", min=1,max=20,val=5},
    },
    MISC={
        {type="section",name="Visual"},
        {type="toggle",name="Fullbright",    key="fullbright", func="fullbright",  notify="Fullbright", nobind=true},
        {type="toggle",name="Remove Fog",    key="remfog",     func="remfog",      notify="Remove Fog", nobind=true},
        {type="toggle",name="Third Person",  key="thirdperson",                    notify="3rd Person", nobind=true},
        {type="section",name="Staff"},
        {type="toggle",name="Staff Spectator",key="staff_spec",func="staff_spec",  notify="Staff Spec", nobind=true},
    },
    ["FPS+"]={
        {type="section",name="FPS Boost"},
        {type="toggle",name="Remove Props",  key="remprops",   func="remprops",    notify="No Props",   nobind=true},
        {type="toggle",name="Potato Mode",   key="potato",     func="potato",      notify="Potato",     nobind=true},
    },
    SETTINGS={
        {type="section",name="Interface"},
        {type="toggle",name="Watermark",     key="watermark",  func="watermark",   notify="Watermark",  nobind=true},
        {type="toggle",name="Notifications", key="notifs",                         notify="Notifs",     nobind=true},
        {type="toggle",name="Keybinds Panel",key="keybinds",   func="keybinds_toggle",notify="Keybinds",nobind=true},
        {type="slider",name="UI Scale",      key="ui_scale",   min=70,max=130,val=100,func="ui_scale"},
    },
}

-- ══════════════════════════════════════════
--  ESP SYSTEM
-- ══════════════════════════════════════════
local espConns={}; local highlights={}
local espFolder=Instance.new("Folder",workspace); espFolder.Name="DM_ESP"

local function removeESP(p)
    if espConns[p.Name] then espConns[p.Name]:Disconnect(); espConns[p.Name]=nil end
    local bb=espFolder:FindFirstChild("ESP_"..p.Name); if bb then bb:Destroy() end
    local bbW=espFolder:FindFirstChild("ESPW_"..p.Name); if bbW then bbW:Destroy() end
    local hl=espFolder:FindFirstChild("HL_"..p.Name); if hl then hl:Destroy() end
    highlights[p.Name]=nil
end

local function createESP(target)
    if target==player then return end
    removeESP(target)
    local function tryBuild()
        local char=target.Character; if not char then return false end
        local hrp=char:FindFirstChild("HumanoidRootPart")
        local hum=char:FindFirstChild("Humanoid"); if not hrp or not hum then return false end
        local hl=Instance.new("Highlight")
        hl.Name="HL_"..target.Name; hl.FillTransparency=1
        hl.OutlineColor=Color3.fromRGB(255,255,255); hl.OutlineTransparency=0
        hl.Adornee=char; hl.Parent=espFolder
        highlights[target.Name]=hl
        local bb=Instance.new("BillboardGui")
        bb.Name="ESP_"..target.Name; bb.Adornee=hrp
        bb.Size=UDim2.new(0,110,0,82)
        bb.StudsOffsetWorldSpace=Vector3.new(2.6,1,0)
        bb.AlwaysOnTop=true; bb.ResetOnSpawn=false; bb.Parent=espFolder
        local distL=Instance.new("TextLabel",bb)
        distL.Size=UDim2.new(1,0,0,11); distL.Position=UDim2.new(0,0,0,0)
        distL.BackgroundTransparency=1; distL.Text="0m"
        distL.Font=Enum.Font.GothamBold; distL.TextSize=9
        distL.TextColor3=Color3.fromRGB(255,255,255); distL.TextStrokeTransparency=0.3
        distL.TextXAlignment=Enum.TextXAlignment.Left
        local nameL=Instance.new("TextLabel",bb)
        nameL.Size=UDim2.new(1,0,0,14); nameL.Position=UDim2.new(0,0,0,12)
        nameL.BackgroundTransparency=1; nameL.Text=target.Name
        nameL.Font=Enum.Font.GothamBold; nameL.TextSize=11
        nameL.TextColor3=Color3.fromRGB(255,255,255); nameL.TextStrokeTransparency=0.3
        nameL.TextXAlignment=Enum.TextXAlignment.Left
        local hpBg=Instance.new("Frame",bb)
        hpBg.Size=UDim2.new(0,5,0,38); hpBg.Position=UDim2.new(0,0,0,28)
        hpBg.BackgroundColor3=Color3.fromRGB(28,28,28); hpBg.BorderSizePixel=0
        Instance.new("UICorner",hpBg).CornerRadius=UDim.new(1,0)
        local hpFill=Instance.new("Frame",hpBg)
        hpFill.AnchorPoint=Vector2.new(0,1); hpFill.Position=UDim2.new(0,0,1,0)
        hpFill.Size=UDim2.new(1,0,1,0)
        hpFill.BackgroundColor3=Color3.fromRGB(255,255,255); hpFill.BorderSizePixel=0
        Instance.new("UICorner",hpFill).CornerRadius=UDim.new(1,0)
        local hpIcon=Instance.new("ImageLabel",bb)
        hpIcon.Size=UDim2.new(0,10,0,10); hpIcon.Position=UDim2.new(0,-3,0,67)
        hpIcon.BackgroundTransparency=1; hpIcon.Image="rbxassetid://13321877099"
        hpIcon.ImageColor3=Color3.fromRGB(255,255,255)
        local hpTxt=Instance.new("TextLabel",bb)
        hpTxt.Size=UDim2.new(0,20,0,9); hpTxt.Position=UDim2.new(0,8,0,68)
        hpTxt.BackgroundTransparency=1; hpTxt.Font=Enum.Font.GothamBold; hpTxt.TextSize=7
        hpTxt.TextColor3=Color3.fromRGB(255,255,255); hpTxt.TextXAlignment=Enum.TextXAlignment.Left
        hpTxt.TextStrokeTransparency=0.4
        local arBg=Instance.new("Frame",bb)
        arBg.Size=UDim2.new(0,5,0,38); arBg.Position=UDim2.new(0,8,0,28)
        arBg.BackgroundColor3=Color3.fromRGB(28,28,28); arBg.BorderSizePixel=0
        Instance.new("UICorner",arBg).CornerRadius=UDim.new(1,0)
        local arFill=Instance.new("Frame",arBg)
        arFill.AnchorPoint=Vector2.new(0,1); arFill.Position=UDim2.new(0,0,1,0)
        arFill.Size=UDim2.new(1,0,0,0)
        arFill.BackgroundColor3=Color3.fromRGB(255,255,255); arFill.BorderSizePixel=0
        Instance.new("UICorner",arFill).CornerRadius=UDim.new(1,0)
        local arIcon=Instance.new("ImageLabel",bb)
        arIcon.Size=UDim2.new(0,10,0,10); arIcon.Position=UDim2.new(0,5,0,67)
        arIcon.BackgroundTransparency=1; arIcon.Image="rbxassetid://13379765910"
        arIcon.ImageColor3=Color3.fromRGB(255,255,255)
        local arTxt=Instance.new("TextLabel",bb)
        arTxt.Size=UDim2.new(0,20,0,9); arTxt.Position=UDim2.new(0,16,0,68)
        arTxt.BackgroundTransparency=1; arTxt.Font=Enum.Font.GothamBold; arTxt.TextSize=7
        arTxt.TextColor3=Color3.fromRGB(255,255,255); arTxt.TextXAlignment=Enum.TextXAlignment.Left
        arTxt.TextStrokeTransparency=0.4
        local bbW=Instance.new("BillboardGui")
        bbW.Name="ESPW_"..target.Name; bbW.Adornee=hrp
        bbW.Size=UDim2.new(0,120,0,18)
        bbW.StudsOffsetWorldSpace=Vector3.new(0,-3.2,0)
        bbW.AlwaysOnTop=true; bbW.ResetOnSpawn=false; bbW.Parent=espFolder
        local weapIcon=Instance.new("ImageLabel",bbW)
        weapIcon.Size=UDim2.new(0,12,0,12); weapIcon.Position=UDim2.new(0,0,0.5,-6)
        weapIcon.BackgroundTransparency=1; weapIcon.Image="rbxassetid://11127408662"
        weapIcon.ImageColor3=Color3.fromRGB(255,255,255)
        local weapL=Instance.new("TextLabel",bbW)
        weapL.Size=UDim2.new(1,-16,1,0); weapL.Position=UDim2.new(0,16,0,0)
        weapL.BackgroundTransparency=1; weapL.Text=""
        weapL.Font=Enum.Font.GothamBold; weapL.TextSize=9
        weapL.TextColor3=Color3.fromRGB(255,255,255); weapL.TextXAlignment=Enum.TextXAlignment.Left
        local lastHP=-1; local lastArm=-1; local lastDist=-1; local lastTool=""
        espConns[target.Name]=RunService.Heartbeat:Connect(function()
            local enabled=values["esp_players"]==true
            bb.Enabled=enabled
            if hl and hl.Parent then hl.Enabled=enabled and values["esp_boxes"]~=false end
            if not enabled then bbW.Enabled=false; return end
            local c2=target.Character; if not c2 then return end
            local h2=c2:FindFirstChild("Humanoid"); if not h2 then return end
            local hrp2=c2:FindFirstChild("HumanoidRootPart"); if not hrp2 then return end
            nameL.Visible=values["esp_names"]~=false
            local dist=rootPart and math.floor((hrp2.Position-rootPart.Position).Magnitude) or 0
            distL.Visible=values["esp_dist_show"]==true
            if dist~=lastDist then distL.Text=dist.."m"; lastDist=dist end
            bbW.Enabled=enabled and values["esp_weapon"]==true
            if values["esp_weapon"] then
                local tool=c2:FindFirstChildOfClass("Tool")
                local tn=tool and tool.Name or ""
                if tn~=lastTool then weapL.Text=tn; lastTool=tn end
            end
            local hp=math.clamp(h2.Health,0,h2.MaxHealth)
            local pct=h2.MaxHealth>0 and hp/h2.MaxHealth or 0
            local hpInt=math.floor(hp)
            if hpInt~=lastHP then
                hpFill.Size=UDim2.new(1,0,pct,0); lastHP=hpInt
            end
            local show=values["esp_health"]~=false
            hpBg.Visible=show; hpTxt.Visible=false; hpIcon.Visible=show
            local armVal=0
            for _,sn in ipairs({"Armor","Shield","Armour","Defence","Defense"}) do
                local st=c2:FindFirstChild("Stats") or target:FindFirstChild("leaderstats")
                if st then local v2=st:FindFirstChild(sn); if v2 then armVal=math.clamp(math.floor(v2.Value),0,100); break end end
            end
            if armVal~=lastArm then
                arFill.Size=UDim2.new(1,0,armVal/100,0); lastArm=armVal
            end
            arBg.Visible=show; arTxt.Visible=false; arIcon.Visible=show
        end)
        return true
    end
    if not tryBuild() then
        local conn; conn = target.CharacterAdded:Connect(function()
            conn:Disconnect()
            task.wait(0.6)
            if values["esp_players"] then createESP(target) end
        end)
    end
end

local function refreshESP()
    for _,p in ipairs(Players:GetPlayers()) do removeESP(p) end
    if not values["esp_players"] then return end
    for _,p in ipairs(Players:GetPlayers()) do createESP(p) end
end
local function applyEspBoxes()
    for pname,hl in pairs(highlights) do
        if hl and hl.Parent then hl.Enabled=values["esp_players"]==true and values["esp_boxes"]~=false end
    end
end

-- ══════════════════════════════════════════
--  FPS+ SYSTEM
-- ══════════════════════════════════════════
local removedProps = {}
local originalTextures = {}

local PROP_KEYWORDS = {
    "tree","bush","shrub","plant","fence","pole","lamp","light","post",
    "bench","barrel","crate","box","rock","stone","pillar","column","statue",
    "flower","grass","weed","sign","trash","bin","hedge",
    "дерев","забор","куст","фонарь","столб","камень","ящик","бочка"
}

local function isProp(obj)
    if not obj:IsA("Model") and not obj:IsA("BasePart") then return false end
    local name = obj.Name:lower()
    for _, kw in ipairs(PROP_KEYWORDS) do
        if name:find(kw) then return true end
    end
    if obj:IsA("BasePart") and obj.Anchored then
        local sz = obj.Size
        if sz.X < 8 and sz.Y < 12 and sz.Z < 8 then
            if not name:find("floor") and not name:find("wall") and not name:find("base") and not name:find("ground") and not name:find("road") then
                return true
            end
        end
    end
    return false
end

local function applyRemoveProps(enabled)
    if enabled then
        task.spawn(function()
            local count = 0
            for _, obj in ipairs(workspace:GetDescendants()) do
                local isChar = false
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.Character and obj:IsDescendantOf(p.Character) then isChar = true; break end
                end
                if not isChar then
                if isProp(obj) then
                    if obj:IsA("BasePart") then
                        table.insert(removedProps, {obj=obj, trans=obj.Transparency, collide=obj.CanCollide})
                        obj.Transparency = 1; obj.CanCollide = false; count = count + 1
                    elseif obj:IsA("Model") then
                        for _, part in ipairs(obj:GetDescendants()) do
                            if part:IsA("BasePart") then
                                table.insert(removedProps, {obj=part, trans=part.Transparency, collide=part.CanCollide})
                                part.Transparency = 1; part.CanCollide = false; count = count + 1
                            end
                        end
                    end
                end
                if count % 200 == 0 then task.wait() end
                end
            end
            _spawnRightNotify(ICON_CHECK_ID, Color3.fromRGB(80,255,120), "Removed "..count.." props", Color3.fromRGB(0,200,80))
        end)
    else
        for _, data in ipairs(removedProps) do
            pcall(function() data.obj.Transparency = data.trans; data.obj.CanCollide = data.collide end)
        end
        removedProps = {}
        _spawnRightNotify(ICON_CHECK_ID, Color3.fromRGB(200,200,200), "Props restored", Color3.fromRGB(80,80,80))
    end
end

local function applyPotato(enabled)
    local L = game:GetService("Lighting")
    if enabled then
        originalTextures = {
            brightness=L.Brightness, shadows=L.GlobalShadows, ambient=L.Ambient,
            outambient=L.OutdoorAmbient, fogend=L.FogEnd, fogstart=L.FogStart,
        }
        for _, fx in ipairs(L:GetChildren()) do
            if fx:IsA("BloomEffect") or fx:IsA("BlurEffect") or fx:IsA("ColorCorrectionEffect")
                or fx:IsA("SunRaysEffect") or fx:IsA("DepthOfFieldEffect") then fx.Enabled = false end
        end
        L.GlobalShadows=false; L.Brightness=2
        L.Ambient=Color3.fromRGB(200,200,200); L.OutdoorAmbient=Color3.fromRGB(200,200,200)
        L.FogEnd=1e9; L.FogStart=1e9
        task.spawn(function()
            for _, v in ipairs(workspace:GetDescendants()) do
                if v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 1 end
                if v:IsA("SpecialMesh") then pcall(function() v.TextureId = "" end) end
            end
        end)
        pcall(function() workspace.Terrain.Decoration = false end)
        task.spawn(function()
            for _, v in ipairs(workspace:GetDescendants()) do
                if v:IsA("ParticleEmitter") or v:IsA("Beam") or v:IsA("Trail") then v.Enabled = false end
            end
        end)
        _spawnRightNotify(ICON_CHECK_ID, Color3.fromRGB(80,255,120), "Potato mode ON", Color3.fromRGB(0,200,80))
    else
        if originalTextures.brightness then
            L.Brightness=originalTextures.brightness; L.GlobalShadows=originalTextures.shadows
            L.Ambient=originalTextures.ambient; L.OutdoorAmbient=originalTextures.outambient
            L.FogEnd=originalTextures.fogend; L.FogStart=originalTextures.fogstart
        end
        for _, fx in ipairs(L:GetChildren()) do
            if fx:IsA("BloomEffect") or fx:IsA("BlurEffect") or fx:IsA("ColorCorrectionEffect")
                or fx:IsA("SunRaysEffect") or fx:IsA("DepthOfFieldEffect") then fx.Enabled = true end
        end
        task.spawn(function()
            for _, v in ipairs(workspace:GetDescendants()) do
                if v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 0 end
                if v:IsA("ParticleEmitter") or v:IsA("Beam") or v:IsA("Trail") then v.Enabled = true end
            end
        end)
        pcall(function() workspace.Terrain.Decoration = true end)
        _spawnRightNotify(ICON_CHECK_ID, Color3.fromRGB(200,200,200), "Potato mode OFF", Color3.fromRGB(80,80,80))
    end
end

-- ══════════════════════════════════════════
--  APPLY FUNCTION
-- ══════════════════════════════════════════
local function applyFunction(key,funcName,val)
    if not funcName then return end
    if funcName=="esp_toggle"   then refreshESP()
    elseif funcName=="esp_boxes" then applyEspBoxes()
    elseif funcName=="aimbot_func" then
        if values[key] then startAimbot() else stopAimbot(); aimbotHeld=false; aimbotLockedTarget=nil end
    elseif funcName=="fullbright" then
        local L=game:GetService("Lighting")
        if values[key] then L.Brightness=2;L.ClockTime=14;L.FogEnd=1e6;L.GlobalShadows=false;L.Ambient=Color3.fromRGB(255,255,255)
        else L.Brightness=1;L.ClockTime=14;L.GlobalShadows=true;L.Ambient=Color3.fromRGB(127,127,127) end
    elseif funcName=="remfog"   then game:GetService("Lighting").FogEnd=values[key] and 1e9 or 100000
    elseif funcName=="watermark"       then WatermarkFrame.Visible=values[key]; updateActiveBar()
    elseif funcName=="keybinds_toggle" then KBPanel.Visible=values[key]; if values[key] then rebuildKBPanel() end
    elseif funcName=="ui_scale"        then UIScaleObj.Scale=val/100
    elseif funcName=="staff_spec" then
        if values[key] then showStaffPanel() else hideStaffPanel() end
    elseif funcName=="remprops" then applyRemoveProps(values[key])
    elseif funcName=="potato"   then applyPotato(values[key])
    end
end

Players.PlayerAdded:Connect(function(p)
    task.wait(0.5)
    pushPlayerNotify(p.Name, "joined")
    trackPlayerDeath(p)
    p.CharacterAdded:Connect(function()
        task.wait(0.6)
        if values["esp_players"] then createESP(p) end
    end)
    if values["esp_players"] then createESP(p) end
end)
Players.PlayerRemoving:Connect(function(p)
    pushPlayerNotify(p.Name, "left")
    removeESP(p)
end)
for _,p in ipairs(Players:GetPlayers()) do
    if p~=player then
        trackPlayerDeath(p)
        p.CharacterAdded:Connect(function()
            task.wait(0.6)
            if values["esp_players"] then createESP(p) end
        end)
        if values["esp_players"] then createESP(p) end
    end
end

-- ══════════════════════════════════════════
--  ELEMENT BUILDERS
-- ══════════════════════════════════════════
local function mkSection(parent,name)
    local row=Instance.new("Frame",parent); row.Size=UDim2.new(1,0,0,26); row.BackgroundTransparency=1; row.ZIndex=32
    local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(1,-4,0,16); lbl.Position=UDim2.new(0,2,0,5)
    lbl.BackgroundTransparency=1; lbl.Text=string.upper(name); lbl.Font=Enum.Font.GothamBold
    lbl.TextSize=9; lbl.TextColor3=Color3.fromRGB(65,65,65); lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=33
    local div=Instance.new("Frame",row); div.Size=UDim2.new(1,-2,0,1); div.Position=UDim2.new(0,2,1,-1)
    div.BackgroundColor3=Color3.fromRGB(18,18,18); div.BorderSizePixel=0; div.ZIndex=33
end

local function mkToggle(parent,info)
    local row=Instance.new("Frame",parent)
    row.Size=UDim2.new(1,0,0,34); row.BackgroundColor3=Color3.fromRGB(10,10,10)
    row.BorderSizePixel=0; row.ZIndex=32
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,8)
    if info.notify then notifyNames[info.key]=info.notify end
    local hasBind=not info.nobind
    if hasBind then
        local dotsBtn=Instance.new("TextButton",row)
        dotsBtn.Size=UDim2.new(0,20,0,22); dotsBtn.Position=UDim2.new(1,-26,0.5,-11)
        dotsBtn.BackgroundTransparency=1; dotsBtn.Text="···"; dotsBtn.Font=Enum.Font.GothamBold
        dotsBtn.TextSize=13; dotsBtn.TextColor3=Color3.fromRGB(50,50,50); dotsBtn.ZIndex=36
        local bindBadge=Instance.new("Frame",row)
        bindBadge.Size=UDim2.new(0,0,0,18); bindBadge.BackgroundColor3=Color3.fromRGB(20,20,20)
        bindBadge.BorderSizePixel=0; bindBadge.ZIndex=36; bindBadge.Visible=false
        Instance.new("UICorner",bindBadge).CornerRadius=UDim.new(0,5)
        Instance.new("UIStroke",bindBadge).Color=Color3.fromRGB(55,55,55)
        local bindLbl=Instance.new("TextLabel",bindBadge)
        bindLbl.Size=UDim2.new(1,0,1,0); bindLbl.BackgroundTransparency=1
        bindLbl.Font=Enum.Font.GothamBold; bindLbl.TextSize=9
        bindLbl.TextColor3=Color3.fromRGB(200,200,200); bindLbl.ZIndex=37
        local function refreshBadge()
            local kname=keybinds[info.key]
            if kname then
                local w=math.max(34,#kname*7+16)
                bindBadge.Size=UDim2.new(0,w,0,18); bindBadge.Position=UDim2.new(1,-w-4,0.5,-9)
                bindLbl.Text=kname; bindBadge.Visible=true; dotsBtn.Visible=false
            else bindBadge.Visible=false; dotsBtn.Visible=true end
        end
        refreshBadge()
        local function onBindClick() playSound(SND_CLICK); openPicker(info.key,refreshBadge) end
        dotsBtn.MouseEnter:Connect(function() TweenService:Create(dotsBtn,TweenInfo.new(0.1),{TextColor3=Color3.fromRGB(200,200,200)}):Play() end)
        dotsBtn.MouseLeave:Connect(function() TweenService:Create(dotsBtn,TweenInfo.new(0.1),{TextColor3=Color3.fromRGB(50,50,50)}):Play() end)
        dotsBtn.MouseButton1Click:Connect(onBindClick)
        bindBadge.InputBegan:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseButton1 then onBindClick() end
        end)
    end
    local lbl=Instance.new("TextLabel",row)
    lbl.Size=hasBind and UDim2.new(1,-84,1,0) or UDim2.new(1,-52,1,0)
    lbl.Position=UDim2.new(0,12,0,0); lbl.BackgroundTransparency=1
    lbl.Text=info.name; lbl.Font=Enum.Font.Gotham; lbl.TextSize=12
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=33
    local track=Instance.new("Frame",row)
    track.Size=UDim2.new(0,34,0,18); track.Position=UDim2.new(1,-58,0.5,-9)
    track.BorderSizePixel=0; track.ZIndex=33
    Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)
    local ts=Instance.new("UIStroke",track); ts.Thickness=1
    local knob=Instance.new("Frame",track)
    knob.Size=UDim2.new(0,12,0,12); knob.BorderSizePixel=0; knob.ZIndex=34
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
    local function applyVisual(on)
        track.BackgroundColor3=on and Color3.fromRGB(255,255,255) or Color3.fromRGB(22,22,22)
        ts.Color=on and Color3.fromRGB(200,200,200) or Color3.fromRGB(38,38,38)
        knob.Position=on and UDim2.new(0,19,0.5,-6) or UDim2.new(0,3,0.5,-6)
        knob.BackgroundColor3=on and Color3.fromRGB(0,0,0) or Color3.fromRGB(70,70,70)
        lbl.TextColor3=on and Color3.fromRGB(255,255,255) or Color3.fromRGB(140,140,140)
    end
    if values[info.key]==nil then values[info.key]=false end
    applyVisual(values[info.key])
    local busy=false
    local function doToggle()
        if busy then return end; busy=true
        local on_new = not values[info.key]
        if on_new then playSound(SND_TOGGLE_ON, 0.25) else playSound(SND_TOGGLE_OFF, 0.25) end
        values[info.key]=on_new; local on=values[info.key]
        TweenService:Create(track,TweenInfo.new(0.18),{BackgroundColor3=on and Color3.fromRGB(255,255,255) or Color3.fromRGB(22,22,22)}):Play()
        TweenService:Create(ts,TweenInfo.new(0.18),{Color=on and Color3.fromRGB(200,200,200) or Color3.fromRGB(38,38,38)}):Play()
        TweenService:Create(knob,TweenInfo.new(0.18),{Position=on and UDim2.new(0,19,0.5,-6) or UDim2.new(0,3,0.5,-6),BackgroundColor3=on and Color3.fromRGB(0,0,0) or Color3.fromRGB(70,70,70)}):Play()
        TweenService:Create(lbl,TweenInfo.new(0.18),{TextColor3=on and Color3.fromRGB(255,255,255) or Color3.fromRGB(140,140,140)}):Play()
        applyFunction(info.key,info.func,nil)
        if info.notify then activeFunctions[info.notify]=on; updateActiveBar(); pushNotify(info.notify,on) end
        if values["keybinds"] then rebuildKBPanel() end
        task.wait(0.2); busy=false
    end
    toggleCallbacks[info.key]=doToggle
    local btn=Instance.new("TextButton",row)
    btn.Size=hasBind and UDim2.new(1,-64,1,0) or UDim2.new(1,-48,1,0)
    btn.BackgroundTransparency=1; btn.Text=""; btn.ZIndex=35
    btn.MouseButton1Click:Connect(doToggle)
    btn.MouseEnter:Connect(function() TweenService:Create(row,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(16,16,16)}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(row,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(10,10,10)}):Play() end)
end

local function mkSlider(parent,info)
    local row=Instance.new("Frame",parent); row.Size=UDim2.new(1,0,0,46); row.BackgroundColor3=Color3.fromRGB(10,10,10); row.BorderSizePixel=0; row.ZIndex=32
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,8)
    local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(0.6,0,0,22); lbl.Position=UDim2.new(0,12,0,5); lbl.BackgroundTransparency=1; lbl.Text=info.name; lbl.Font=Enum.Font.Gotham; lbl.TextSize=12; lbl.TextColor3=Color3.fromRGB(140,140,140); lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=33
    local curVal=values[info.key] or info.val
    local valLbl=Instance.new("TextLabel",row); valLbl.Size=UDim2.new(0.4,-12,0,22); valLbl.Position=UDim2.new(0.6,0,0,5); valLbl.BackgroundTransparency=1; valLbl.Text=tostring(curVal); valLbl.Font=Enum.Font.GothamBold; valLbl.TextSize=12; valLbl.TextColor3=Color3.fromRGB(255,255,255); valLbl.TextXAlignment=Enum.TextXAlignment.Right; valLbl.ZIndex=33
    local bg=Instance.new("Frame",row); bg.Size=UDim2.new(1,-22,0,4); bg.Position=UDim2.new(0,11,1,-14); bg.BackgroundColor3=Color3.fromRGB(26,26,26); bg.BorderSizePixel=0; bg.ZIndex=33; Instance.new("UICorner",bg).CornerRadius=UDim.new(1,0)
    local p0=(curVal-info.min)/(info.max-info.min)
    local fill=Instance.new("Frame",bg); fill.Size=UDim2.new(p0,0,1,0); fill.BackgroundColor3=Color3.fromRGB(255,255,255); fill.BorderSizePixel=0; fill.ZIndex=34; Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)
    local handle=Instance.new("Frame",bg); handle.Size=UDim2.new(0,10,0,10); handle.AnchorPoint=Vector2.new(0.5,0.5); handle.Position=UDim2.new(p0,0,0.5,0); handle.BackgroundColor3=Color3.fromRGB(255,255,255); handle.BorderSizePixel=0; handle.ZIndex=35; Instance.new("UICorner",handle).CornerRadius=UDim.new(1,0)
    if values[info.key]==nil then values[info.key]=info.val end
    local drag=false
    bg.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)
    UIS.InputChanged:Connect(function(i)
        if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
            local p=math.clamp((i.Position.X-bg.AbsolutePosition.X)/bg.AbsoluteSize.X,0,1)
            local v=math.floor(info.min+p*(info.max-info.min))
            values[info.key]=v; valLbl.Text=tostring(v); fill.Size=UDim2.new(p,0,1,0); handle.Position=UDim2.new(p,0,0.5,0)
            applyFunction(info.key,info.func,v)
        end
    end)
end

-- ══════════════════════════════════════════
--  BUILD / SELECT TAB
-- ══════════════════════════════════════════
local currentLayout=nil
local function buildContent(tabName)
    ContentScroll.CanvasPosition=Vector2.zero
    for _,c in ipairs(ContentScroll:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
    local cl=Instance.new("UIListLayout",ContentScroll)
    cl.Padding=UDim.new(0,5); cl.HorizontalAlignment=Enum.HorizontalAlignment.Center
    currentLayout=cl
    local cp=Instance.new("UIPadding",ContentScroll)
    cp.PaddingTop=UDim.new(0,8); cp.PaddingBottom=UDim.new(0,10); cp.PaddingLeft=UDim.new(0,2); cp.PaddingRight=UDim.new(0,6)
    for _,item in ipairs(tabContent[tabName] or {}) do
        if item.type=="section"    then mkSection(ContentScroll,item.name)
        elseif item.type=="toggle" then mkToggle(ContentScroll,item)
        elseif item.type=="slider" then mkSlider(ContentScroll,item)
        end
    end
    task.spawn(function()
        task.wait(); task.wait()
        if cl and cl.Parent then ContentScroll.CanvasSize=UDim2.new(0,0,0,cl.AbsoluteContentSize.Y+20) end
        ContentScroll.CanvasPosition=Vector2.zero
    end)
end

local tabButtons={}; local activeTab=nil
local function selectTab(name)
    activeTab=name
    for tname,tbtn in pairs(tabButtons) do
        local on=tname==name
        TweenService:Create(tbtn,TweenInfo.new(0.15),{BackgroundColor3=on and Color3.fromRGB(255,255,255) or Color3.fromRGB(12,12,12)}):Play()
        local img=tbtn:FindFirstChildOfClass("ImageLabel"); if img then TweenService:Create(img,TweenInfo.new(0.15),{ImageColor3=on and Color3.fromRGB(0,0,0) or Color3.fromRGB(85,85,85)}):Play() end
        local tlbl=tbtn:FindFirstChildOfClass("TextLabel"); if tlbl then TweenService:Create(tlbl,TweenInfo.new(0.15),{TextColor3=on and Color3.fromRGB(0,0,0) or Color3.fromRGB(85,85,85)}):Play() end
    end
    buildContent(name)
end

for _,tab in ipairs(tabs) do
    local btn=Instance.new("TextButton",SideBar)
    btn.Size=UDim2.new(1,-6,0,38); btn.BackgroundColor3=Color3.fromRGB(12,12,12); btn.Text=""; btn.BorderSizePixel=0; btn.ZIndex=32
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,9)
    local icon=Instance.new("ImageLabel",btn); icon.Size=UDim2.new(0,16,0,16); icon.Position=UDim2.new(0,10,0.5,-8); icon.BackgroundTransparency=1; icon.Image="rbxassetid://"..tab.icon; icon.ImageColor3=Color3.fromRGB(85,85,85); icon.ZIndex=33
    local tlbl=Instance.new("TextLabel",btn); tlbl.Size=UDim2.new(1,-34,1,0); tlbl.Position=UDim2.new(0,32,0,0); tlbl.BackgroundTransparency=1; tlbl.Text=tab.name; tlbl.Font=Enum.Font.GothamBold; tlbl.TextSize=11; tlbl.TextColor3=Color3.fromRGB(85,85,85); tlbl.TextXAlignment=Enum.TextXAlignment.Left; tlbl.ZIndex=33
    tabButtons[tab.name]=btn
    btn.MouseButton1Click:Connect(function() playSound(SND_CLICK); selectTab(tab.name) end)
    btn.MouseEnter:Connect(function() if activeTab~=tab.name then TweenService:Create(btn,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(18,18,18)}):Play() end end)
    btn.MouseLeave:Connect(function() if activeTab~=tab.name then TweenService:Create(btn,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(12,12,12)}):Play() end end)
end
selectTab("MAIN")

RunService.Heartbeat:Connect(function() TitleGrad.Offset=Vector2.new(math.sin(tick()*2.5)*0.8,0) end)
local strokeT=0
RunService.Heartbeat:Connect(function(dt)
    strokeT = strokeT + dt * 2
    local v=(math.sin(strokeT)+1)/2
    MainStroke.Color=Color3.fromRGB(v*255,v*255,v*255)
end)

-- ══════════════════════════════════════════
--  SHOW / HIDE
-- ══════════════════════════════════════════
local function showGui()
    guiVisible=true
    TweenService:Create(ClosedHint,TweenInfo.new(0.2),{BackgroundTransparency=1}):Play()
    TweenService:Create(CHStroke,TweenInfo.new(0.2),{Transparency=1}):Play()
    TweenService:Create(ClosedHintLabel,TweenInfo.new(0.2),{TextTransparency=1}):Play()
    playSound(SND_OPEN)
    MainFrame.Position=UDim2.new(0.5,-270,0.5,-210)
    MainFrame.Size=UDim2.new(0,540,0,0); MainFrame.BackgroundTransparency=0.15; MainFrame.Visible=true
    TweenService:Create(MainFrame,TweenInfo.new(0.42,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0,540,0,420),BackgroundTransparency=0}):Play()
end

local function hideGui()
    guiVisible=false; playSound(SND_CLOSE)
    task.delay(0.4,function()
        if not guiVisible then
            TweenService:Create(ClosedHint,TweenInfo.new(0.3),{BackgroundTransparency=0}):Play()
            TweenService:Create(CHStroke,TweenInfo.new(0.3),{Transparency=0}):Play()
            TweenService:Create(ClosedHintLabel,TweenInfo.new(0.3),{TextTransparency=0}):Play()
        end
    end)
    local cp=MainFrame.Position
    TweenService:Create(MainFrame,TweenInfo.new(0.38,Enum.EasingStyle.Quint,Enum.EasingDirection.In),{
        Size=UDim2.new(0,540,0,0),
        Position=UDim2.new(cp.X.Scale,cp.X.Offset,cp.Y.Scale,cp.Y.Offset+200),
        BackgroundTransparency=1
    }):Play()
    task.delay(0.4,function()
        if not guiVisible then MainFrame.Visible=false; MainFrame.Position=UDim2.new(0.5,-270,0.5,-210) end
    end)
end
CloseBtn.MouseButton1Click:Connect(hideGui)

UIS.InputBegan:Connect(function(inp,gpe)
    if gpe or pickerOpen then return end
    if inp.KeyCode==Enum.KeyCode.K then if guiVisible then hideGui() else showGui() end end
end)

-- DRAG
local dragging,dragInput,dragStart,startPos=false,nil,nil,nil
Header.InputBegan:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1 then
        dragging=true; dragStart=inp.Position; startPos=MainFrame.Position
        inp.Changed:Connect(function() if inp.UserInputState==Enum.UserInputState.End then dragging=false end end)
    end
end)
Header.InputChanged:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseMovement then dragInput=inp end end)
UIS.InputChanged:Connect(function(inp)
    if inp==dragInput and dragging then
        local d=inp.Position-dragStart
        MainFrame.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
    end
end)

ClosedHint.BackgroundTransparency = 0
CHStroke.Transparency = 0
ClosedHintLabel.TextTransparency = 0

task.wait(0.5)
rebuildKBPanel()
print("[DM ARENA V3] Loaded | K = toggle | t.me/dmarenascripts")