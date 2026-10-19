-- Noky Script Emden | V10 Édition Propre
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    error("Emden doit être lancé côté client, dans un LocalScript.")
end
local Mouse = LocalPlayer:GetMouse()

pcall(function()
    for _, v in pairs(CoreGui:GetChildren()) do
        if v.Name == "Noky_EmdenUI" then v:Destroy() end
    end
end)
if LocalPlayer:FindFirstChild("PlayerGui") then
    for _, v in pairs(LocalPlayer.PlayerGui:GetChildren()) do
        if v.Name == "Noky_EmdenUI" then v:Destroy() end
    end
end

local Settings = {
    Visuals  = { Enable=false,Box=false,Name=false,Health=false,Distance=false,Skeleton=false,Snaplines=false,Weapon=false,MaxDistance=1000 },
    ESPColors= { Box=Color3.fromRGB(255,255,255) },
    Movement = { Noclip=false,NoFallDamage=false,GodMode=false,UnlimitedEnergy=false,ClickTP=false,Fly=false,FlySpeed=60,FlyUpKey=Enum.KeyCode.Space,FlyDownKey=Enum.KeyCode.LeftControl },
    Misc     = { ShowFPS=false },
    Vehicle  = { SpeedMultiplier=0.025,BrakeForce=0.150,AccelKey=Enum.KeyCode.Unknown,BrakeKey=Enum.KeyCode.Unknown,Fly=false,FlySpeed=100,FlyResponsiveness=2.5,UnlimitedHealth=false,FlyUpKey=Enum.KeyCode.Space,FlyDownKey=Enum.KeyCode.LeftControl },
    Controls = { MenuKey=Enum.KeyCode.X }
}

-- Adaptateurs des ressources propres au jeu : renseigner les chemins exacts.
-- Les chemins partent du Player (énergie) ou du Model du véhicule (santé).
-- Exemple de format : Path={"Stats","Energy"}, Maximum=100.
local ResourceBindings = {
    Energy = { Path={}, Maximum=nil, Names={energy=true,stamina=true,endurance=true} },
    VehicleHealth = { Path={}, Maximum=nil, Names={health=true,vehiclehealth=true,durability=true} }
}

-- Cache les recherches pour ne pas parcourir le véhicule à chaque image.
local ResourceCache=setmetatable({}, {__mode="k"})
local function RefillResource(owner,binding)
    if not owner then return end
    if #binding.Path>0 and type(binding.Maximum)=="number" then
        local value=owner
        for _,name in ipairs(binding.Path) do
            value=value:FindFirstChild(name)
            if not value then return end
        end
        if (value:IsA("NumberValue") or value:IsA("IntValue")) and value.Value<binding.Maximum then
            value.Value=binding.Maximum
        end
        return
    end
    local cache=ResourceCache[owner]
    if not cache then cache={}; ResourceCache[owner]=cache end
    local entry=cache[binding]
    if not entry or os.clock()-entry.time>3 then
        entry={time=os.clock(),targets={}}
        cache[binding]=entry
        local nodes={owner}
        for _,node in ipairs(owner:GetDescendants()) do table.insert(nodes,node) end
        for _,node in ipairs(nodes) do
            -- Valeurs numériques avec maximum explicite dans un attribut ou un voisin.
            if (node:IsA("NumberValue") or node:IsA("IntValue")) and binding.Names[string.lower(node.Name)] then
                local maximum=node:GetAttribute("MaxValue") or node:GetAttribute("Max")
                local sibling=node.Parent and node.Parent:FindFirstChild("Max"..node.Name)
                if sibling and (sibling:IsA("NumberValue") or sibling:IsA("IntValue")) then maximum=sibling.Value end
                if type(maximum)=="number" and maximum>0 then
                    table.insert(entry.targets,{node=node,maximum=maximum})
                end
            end
            -- Ressources stockées comme attributs : Energy / MaxEnergy, etc.
            for name,value in pairs(node:GetAttributes()) do
                if type(value)=="number" and binding.Names[string.lower(name)] then
                    local maximum=node:GetAttribute("Max"..name)
                    if type(maximum)=="number" and maximum>0 then
                        table.insert(entry.targets,{node=node,attribute=name,maximum=maximum})
                    end
                end
            end
        end
        if #entry.targets==0 then
            warn("[Emden] Aucune ressource avec maximum explicite trouvée dans "..owner:GetFullName())
        end
    end
    for _,target in ipairs(entry.targets) do
        if target.node.Parent then
            if target.attribute then
                local value=target.node:GetAttribute(target.attribute)
                if type(value)=="number" and value<target.maximum then target.node:SetAttribute(target.attribute,target.maximum) end
            elseif target.node.Value<target.maximum then
                target.node.Value=target.maximum
            end
        end
    end
end

-- Palette de couleurs
local Theme = {
    Background   = Color3.fromRGB(18, 18, 24),
    Surface      = Color3.fromRGB(26, 26, 34),
    SurfaceLight = Color3.fromRGB(34, 34, 44),
    Sidebar      = Color3.fromRGB(22, 22, 30),
    Accent       = Color3.fromRGB(140, 80, 255),
    AccentLight  = Color3.fromRGB(170, 120, 255),
    Text         = Color3.fromRGB(240, 240, 250),
    TextMuted    = Color3.fromRGB(150, 145, 165),
    Stroke       = Color3.fromRGB(120, 70, 220),
    Danger       = Color3.fromRGB(255, 80, 80)
}

local sg = Instance.new("ScreenGui")
sg.Name="Noky_EmdenUI"; sg.ResetOnSpawn=false; sg.IgnoreGuiInset=true
local ok = pcall(function() sg.Parent=CoreGui end)
if not ok then sg.Parent=LocalPlayer:WaitForChild("PlayerGui") end

local UIVisible = true
local _ff,_fl=0,tick()
local _frameCount=0

-- ==========================================
-- BOUTON FLOTTANT (MINIMISÉ)
-- ==========================================
local FloatBtn = Instance.new("TextButton", sg)
FloatBtn.Size = UDim2.new(0, 50, 0, 50)
FloatBtn.Position = UDim2.new(0, 20, 0.5, -25)
FloatBtn.BackgroundColor3 = Theme.Accent
FloatBtn.Text = "N"
FloatBtn.TextColor3 = Theme.Text
FloatBtn.Font = Enum.Font.GothamBlack
FloatBtn.TextSize = 24
FloatBtn.Visible = false
FloatBtn.Active = true
Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(1, 0)
local fBtnStroke = Instance.new("UIStroke", FloatBtn)
fBtnStroke.Color = Theme.AccentLight
fBtnStroke.Thickness = 2

-- Animation du bouton flottant
TweenService:Create(FloatBtn, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
    Size = UDim2.new(0, 55, 0, 55)
}):Play()

-- ==========================================
-- FENÊTRE PRINCIPALE
-- ==========================================
local MainFrame = Instance.new("Frame", sg)
MainFrame.Size=UDim2.new(0,700,0,480); MainFrame.Position=UDim2.new(0.5,-350,0.5,-240)
MainFrame.BackgroundColor3=Theme.Background; MainFrame.BorderSizePixel=0; MainFrame.Active=true
MainFrame.ClipsDescendants = true
Instance.new("UICorner",MainFrame).CornerRadius=UDim.new(0,10)
local ms=Instance.new("UIStroke",MainFrame); ms.Color=Theme.Stroke; ms.Transparency=0.3; ms.Thickness=1.5
Instance.new("UIGradient",MainFrame).Color=ColorSequence.new{
    ColorSequenceKeypoint.new(0,Color3.fromRGB(20,20,28)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(14,14,20))
}

-- Bouton Réduire (en haut à droite)
local MinimizeBtn = Instance.new("TextButton", MainFrame)
MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
MinimizeBtn.Position = UDim2.new(1, -40, 0, 10)
MinimizeBtn.BackgroundColor3 = Theme.Surface
MinimizeBtn.Text = "—"
MinimizeBtn.TextColor3 = Theme.TextMuted
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 18
MinimizeBtn.ZIndex = 5
Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0, 6)

MinimizeBtn.MouseEnter:Connect(function() MinimizeBtn.TextColor3 = Theme.Danger end)
MinimizeBtn.MouseLeave:Connect(function() MinimizeBtn.TextColor3 = Theme.TextMuted end)

-- Logique de réduction / ouverture
local function MinimizeMenu()
    UIVisible = false
    TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0)
    }):Play()
    task.delay(0.3, function()
        MainFrame.Visible = false
        FloatBtn.Visible = true
    end)
end

local function OpenMenu()
    UIVisible = true
    FloatBtn.Visible = false
    MainFrame.Visible = true
    MainFrame.Size = UDim2.new(0, 0, 0, 0)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 700, 0, 480),
        Position = UDim2.new(0.5, -350, 0.5, -240)
    }):Play()
end

MinimizeBtn.MouseButton1Click:Connect(MinimizeMenu)
FloatBtn.MouseButton1Click:Connect(OpenMenu)

-- Glissement
local dragging,dragInput,dragStart,startPos
MainFrame.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then
        dragging=true; dragStart=i.Position; startPos=MainFrame.Position
        i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dragging=false end end)
    end
end)
MainFrame.InputChanged:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseMovement then dragInput=i end end)
UserInputService.InputChanged:Connect(function(i)
    if i==dragInput and dragging then
        local d=i.Position-dragStart
        MainFrame.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
    end
end)

UserInputService.InputBegan:Connect(function(input,gpe)
    if gpe then return end
    if input.KeyCode==Settings.Controls.MenuKey then
        if UIVisible then MinimizeMenu() else OpenMenu() end
    end
    if input.UserInputType==Enum.UserInputType.MouseButton1 and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        if Settings.Movement.ClickTP then
            local r=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if r then r.CFrame=CFrame.new(Mouse.Hit.Position+Vector3.new(0,3,0)) end
        end
    end
end)

-- Compteur FPS
local FPSLabel = Instance.new("TextLabel", sg)
FPSLabel.Size=UDim2.new(0,130,0,30); FPSLabel.Position=UDim2.new(1,-140,0,10)
FPSLabel.BackgroundColor3=Theme.Surface; FPSLabel.BackgroundTransparency=0.3
FPSLabel.TextColor3=Color3.fromRGB(0,255,140)
FPSLabel.TextStrokeTransparency=0.5; FPSLabel.Font=Enum.Font.GothamBold
FPSLabel.TextSize=15; FPSLabel.TextXAlignment=Enum.TextXAlignment.Center; FPSLabel.Visible=false
FPSLabel.Text="FPS: 0"
Instance.new("UICorner",FPSLabel).CornerRadius=UDim.new(0,8)
Instance.new("UIStroke",FPSLabel).Color=Theme.Accent

-- ==========================================
-- BARRE LATÉRALE & UI
-- ==========================================
local Sidebar=Instance.new("Frame",MainFrame)
Sidebar.Size=UDim2.new(0,180,1,0); Sidebar.BackgroundColor3=Theme.Sidebar; Sidebar.BorderSizePixel=0
Instance.new("UICorner",Sidebar).CornerRadius=UDim.new(0,10)
local sGs=Instance.new("UIGradient",Sidebar)
sGs.Color=ColorSequence.new{
    ColorSequenceKeypoint.new(0,Color3.fromRGB(24,22,32)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(16,14,22))
}

local Logo=Instance.new("TextLabel",Sidebar)
Logo.Size=UDim2.new(1,0,0,30); Logo.Position=UDim2.new(0,18,0,18); Logo.BackgroundTransparency=1
Logo.Text="NOKY"; Logo.TextColor3=Theme.AccentLight; Logo.Font=Enum.Font.GothamBlack
Logo.TextSize=26; Logo.TextXAlignment=Enum.TextXAlignment.Left
Logo.TextStrokeTransparency=0.7

local SubLogo=Instance.new("TextLabel",Sidebar)
SubLogo.Size=UDim2.new(1,0,0,20); SubLogo.Position=UDim2.new(0,18,0,44); SubLogo.BackgroundTransparency=1
SubLogo.Text="SCRIPT EMDEN"; SubLogo.TextColor3=Theme.TextMuted; SubLogo.TextTransparency=0.3
SubLogo.Font=Enum.Font.GothamMedium; SubLogo.TextSize=10; SubLogo.TextXAlignment=Enum.TextXAlignment.Left
SubLogo.TextStrokeTransparency=0.8

local sepLine=Instance.new("Frame",Sidebar)
sepLine.Size=UDim2.new(1,-30,0,1); sepLine.Position=UDim2.new(0,15,0,72)
sepLine.BackgroundColor3=Theme.Stroke; sepLine.BackgroundTransparency=0.5

-- Panneau profil
local SP=Instance.new("Frame",Sidebar)
SP.Size=UDim2.new(1,-20,0,70); SP.Position=UDim2.new(0,10,1,-80)
SP.BackgroundColor3=Theme.Surface; SP.BorderSizePixel=0
Instance.new("UICorner",SP).CornerRadius=UDim.new(0,8)
Instance.new("UIStroke",SP).Color=Theme.Accent; Instance.new("UIStroke",SP).Transparency=0.7

local SP_Ico=Instance.new("ImageLabel",SP)
SP_Ico.Size=UDim2.new(0,40,0,40); SP_Ico.Position=UDim2.new(0,10,0.5,-20)
SP_Ico.BackgroundColor3=Theme.SurfaceLight
Instance.new("UICorner",SP_Ico).CornerRadius=UDim.new(1,0)
task.spawn(function()
    local c,r=Players:GetUserThumbnailAsync(LocalPlayer.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size420x420)
    if r then SP_Ico.Image=c end
end)
local SP_N=Instance.new("TextLabel",SP)
SP_N.Size=UDim2.new(1,-60,0,16); SP_N.Position=UDim2.new(0,58,0,14)
SP_N.BackgroundTransparency=1; SP_N.Text=LocalPlayer.Name; SP_N.TextColor3=Theme.Text
SP_N.Font=Enum.Font.GothamBold; SP_N.TextSize=12; SP_N.TextXAlignment=Enum.TextXAlignment.Left
local SP_R=Instance.new("TextLabel",SP)
SP_R.Size=UDim2.new(1,-60,0,14); SP_R.Position=UDim2.new(0,58,0,34)
SP_R.BackgroundTransparency=1; SP_R.Text="Utilisateur VIP"; SP_R.TextColor3=Theme.AccentLight
SP_R.Font=Enum.Font.GothamMedium; SP_R.TextSize=11; SP_R.TextXAlignment=Enum.TextXAlignment.Left

local TabContainers=Instance.new("Frame",MainFrame)
TabContainers.Size=UDim2.new(1,-200,1,-20); TabContainers.Position=UDim2.new(0,190,0,10)
TabContainers.BackgroundTransparency=1

local Tabs={}
local function SwitchTab(id)
    for tid,tab in pairs(Tabs) do
        local a=tid==id
        TweenService:Create(tab.Btn,TweenInfo.new(0.15),{
            BackgroundColor3=a and Theme.Accent or Color3.fromRGB(26,26,34),
            TextColor3=a and Theme.Text or Theme.TextMuted
        }):Play()
        tab.Container.Visible=a
    end
end

local function CreateTab(text,id,idx)
    local btn=Instance.new("TextButton",Sidebar)
    btn.Size=UDim2.new(1,-20,0,36); btn.Position=UDim2.new(0,10,0,88+(idx*44))
    btn.BackgroundColor3=Theme.Surface; btn.BorderSizePixel=0
    btn.Text="  "..text; btn.TextColor3=Theme.TextMuted
    btn.Font=Enum.Font.GothamBold; btn.TextSize=13; btn.TextXAlignment=Enum.TextXAlignment.Left
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,6)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=Theme.SurfaceLight}):Play()
    end)
    btn.MouseLeave:Connect(function()
        if not Tabs[id] or not (Tabs[id].Btn.BackgroundColor3==Theme.Accent) then
            TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=Theme.Surface}):Play()
        end
    end)
    local c=Instance.new("ScrollingFrame",TabContainers)
    c.Size=UDim2.new(1,0,1,0); c.BackgroundTransparency=1; c.BorderSizePixel=0
    c.ScrollBarThickness=3; c.ScrollBarImageColor3=Theme.Accent; c.Visible=false
    local t=Instance.new("TextLabel",c)
    t.Size=UDim2.new(1,0,0,40); t.BackgroundTransparency=1; t.Text=text
    t.TextColor3=Theme.Text; t.Font=Enum.Font.GothamBold; t.TextSize=24
    t.TextXAlignment=Enum.TextXAlignment.Left
    local tLine=Instance.new("Frame",c)
    tLine.Size=UDim2.new(0,60,0,3); tLine.Position=UDim2.new(0,0,0,42)
    tLine.BackgroundColor3=Theme.Accent; Instance.new("UICorner",tLine).CornerRadius=UDim.new(1,0)
    Tabs[id]={Btn=btn,Container=c,YOff=52}
    btn.MouseButton1Click:Connect(function() SwitchTab(id) end)
end

local function Sec(tid,text)
    local tab=Tabs[tid]; local s=Instance.new("TextLabel",tab.Container)
    s.Size=UDim2.new(1,-10,0,25); s.Position=UDim2.new(0,0,0,tab.YOff); tab.YOff+=30
    s.BackgroundTransparency=1; s.Text=text; s.TextColor3=Theme.AccentLight
    s.Font=Enum.Font.GothamBlack; s.TextSize=13; s.TextXAlignment=Enum.TextXAlignment.Left
    tab.Container.CanvasSize=UDim2.new(0,0,0,tab.YOff+10)
end

local function Toggle(tid,text,cat,key)
    local tab=Tabs[tid]; local row=Instance.new("Frame",tab.Container)
    row.Size=UDim2.new(1,-10,0,40); row.Position=UDim2.new(0,0,0,tab.YOff); tab.YOff+=46
    row.BackgroundColor3=Theme.Surface; Instance.new("UICorner",row).CornerRadius=UDim.new(0,6)
    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(0.7,0,1,0); lbl.Position=UDim2.new(0,15,0,0); lbl.BackgroundTransparency=1
    lbl.Text=text; lbl.TextColor3=Theme.Text; lbl.Font=Enum.Font.GothamMedium
    lbl.TextSize=13; lbl.TextXAlignment=Enum.TextXAlignment.Left
    local tBg=Instance.new("Frame",row)
    tBg.Size=UDim2.new(0,36,0,18); tBg.AnchorPoint=Vector2.new(1,0.5); tBg.Position=UDim2.new(1,-15,0.5,0)
    tBg.BackgroundColor3=Color3.fromRGB(45,40,60); Instance.new("UICorner",tBg).CornerRadius=UDim.new(1,0)
    local tC=Instance.new("Frame",tBg)
    tC.Size=UDim2.new(0,14,0,14); tC.AnchorPoint=Vector2.new(0,0.5); tC.Position=UDim2.new(0,2,0.5,0)
    tC.BackgroundColor3=Color3.fromRGB(150,130,180); Instance.new("UICorner",tC).CornerRadius=UDim.new(1,0)
    local btn=Instance.new("TextButton",row); btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1; btn.Text=""
    btn.MouseButton1Click:Connect(function()
        Settings[cat][key]=not Settings[cat][key]; local st=Settings[cat][key]
        TweenService:Create(tBg,TweenInfo.new(0.2),{BackgroundColor3=st and Theme.Accent or Color3.fromRGB(45,40,60)}):Play()
        TweenService:Create(tC,TweenInfo.new(0.2),{Position=st and UDim2.new(1,-16,0.5,0) or UDim2.new(0,2,0.5,0),BackgroundColor3=st and Color3.fromRGB(255,255,255) or Color3.fromRGB(150,130,180)}):Play()
    end)
    tab.Container.CanvasSize=UDim2.new(0,0,0,tab.YOff+10)
end

local function Slider(tid,text,cat,key,mn,mx,mult)
    mult=mult or 1; local tab=Tabs[tid]; local row=Instance.new("Frame",tab.Container)
    row.Size=UDim2.new(1,-10,0,50); row.Position=UDim2.new(0,0,0,tab.YOff); tab.YOff+=56
    row.BackgroundColor3=Theme.Surface; Instance.new("UICorner",row).CornerRadius=UDim.new(0,6)
    local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(0.5,0,0,20); lbl.Position=UDim2.new(0,15,0,5)
    lbl.BackgroundTransparency=1; lbl.Text=text; lbl.TextColor3=Theme.Text
    lbl.Font=Enum.Font.GothamMedium; lbl.TextSize=13; lbl.TextXAlignment=Enum.TextXAlignment.Left
    local vL=Instance.new("TextLabel",row); vL.Size=UDim2.new(0.5,-30,0,20); vL.Position=UDim2.new(0.5,0,0,5)
    vL.BackgroundTransparency=1; vL.Text=tostring(Settings[cat][key]*mult)
    vL.TextColor3=Theme.AccentLight; vL.Font=Enum.Font.GothamBold; vL.TextSize=13; vL.TextXAlignment=Enum.TextXAlignment.Right
    local sBg=Instance.new("Frame",row); sBg.Size=UDim2.new(1,-30,0,6); sBg.Position=UDim2.new(0,15,0,32)
    sBg.BackgroundColor3=Color3.fromRGB(15,15,20); Instance.new("UICorner",sBg).CornerRadius=UDim.new(1,0)
    local fill=Instance.new("Frame",sBg)
    fill.Size=UDim2.new(math.clamp((Settings[cat][key]*mult-mn)/(mx-mn),0,1),0,1,0)
    fill.BackgroundColor3=Theme.Accent; Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)
    local sb=Instance.new("TextButton",sBg); sb.Size=UDim2.new(1,0,1,10); sb.Position=UDim2.new(0,0,0,-5)
    sb.BackgroundTransparency=1; sb.Text=""
    local ds=false
    sb.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then ds=true end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then ds=false end end)
    UserInputService.InputChanged:Connect(function(i)
        if ds and i.UserInputType==Enum.UserInputType.MouseMovement then
            local pct=math.clamp((i.Position.X-sBg.AbsolutePosition.X)/sBg.AbsoluteSize.X,0,1)
            fill.Size=UDim2.new(pct,0,1,0)
            local val=math.floor(mn+((mx-mn)*pct)); vL.Text=tostring(val); Settings[cat][key]=val/mult
        end
    end)
    tab.Container.CanvasSize=UDim2.new(0,0,0,tab.YOff+10)
end

local function Btn(tid,text,cb)
    local tab=Tabs[tid]; local row=Instance.new("Frame",tab.Container)
    row.Size=UDim2.new(1,-10,0,40); row.Position=UDim2.new(0,0,0,tab.YOff); tab.YOff+=46
    row.BackgroundColor3=Theme.Surface; Instance.new("UICorner",row).CornerRadius=UDim.new(0,6)
    local btn=Instance.new("TextButton",row); btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1
    btn.Text="  "..text; btn.TextColor3=Theme.Text
    btn.Font=Enum.Font.GothamMedium; btn.TextSize=13; btn.TextXAlignment=Enum.TextXAlignment.Left
    btn.MouseEnter:Connect(function() TweenService:Create(row,TweenInfo.new(0.15),{BackgroundColor3=Theme.SurfaceLight}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(row,TweenInfo.new(0.15),{BackgroundColor3=Theme.Surface}):Play() end)
    btn.MouseButton1Click:Connect(function() cb(btn) end)
    tab.Container.CanvasSize=UDim2.new(0,0,0,tab.YOff+10)
end

local function Keybind(tid,text,cat,key)
    local tab=Tabs[tid]; local row=Instance.new("Frame",tab.Container)
    row.Size=UDim2.new(1,-10,0,40); row.Position=UDim2.new(0,0,0,tab.YOff); tab.YOff+=46
    row.BackgroundColor3=Theme.Surface; Instance.new("UICorner",row).CornerRadius=UDim.new(0,6)
    local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(0.5,0,1,0); lbl.Position=UDim2.new(0,15,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=text; lbl.TextColor3=Theme.Text
    lbl.Font=Enum.Font.GothamMedium; lbl.TextSize=13; lbl.TextXAlignment=Enum.TextXAlignment.Left
    local kbtn=Instance.new("TextButton",row); kbtn.Size=UDim2.new(0,80,0,24); kbtn.Position=UDim2.new(1,-95,0.5,-12)
    kbtn.BackgroundColor3=Color3.fromRGB(45,40,60)
    kbtn.Text=Settings[cat][key]==Enum.KeyCode.Unknown and "Aucune" or Settings[cat][key].Name
    kbtn.TextColor3=Theme.Text; kbtn.Font=Enum.Font.GothamBold; kbtn.TextSize=12
    Instance.new("UICorner",kbtn).CornerRadius=UDim.new(0,4)
    local li=false; kbtn.MouseButton1Click:Connect(function() li=true; kbtn.Text="..." end)
    UserInputService.InputBegan:Connect(function(i)
        if li and i.UserInputType==Enum.UserInputType.Keyboard then
            li=false; Settings[cat][key]=i.KeyCode; kbtn.Text=i.KeyCode.Name
        end
    end)
    tab.Container.CanvasSize=UDim2.new(0,0,0,tab.YOff+10)
end

local CLR={Color3.fromRGB(255,255,255),Color3.fromRGB(255,50,50),Color3.fromRGB(50,255,50),Color3.fromRGB(50,150,255),Color3.fromRGB(255,255,50),Color3.fromRGB(255,100,255),Color3.fromRGB(150,50,255),Color3.fromRGB(50,255,255),Color3.fromRGB(255,150,50)}
local function Clr(tid,text,cat,key)
    local tab=Tabs[tid]; local row=Instance.new("Frame",tab.Container)
    row.Size=UDim2.new(1,-10,0,40); row.Position=UDim2.new(0,0,0,tab.YOff); tab.YOff+=46
    row.BackgroundColor3=Theme.Surface; Instance.new("UICorner",row).CornerRadius=UDim.new(0,6)
    local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(0.5,0,1,0); lbl.Position=UDim2.new(0,15,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=text.." (Cliquer)"; lbl.TextColor3=Theme.Text
    lbl.Font=Enum.Font.GothamMedium; lbl.TextSize=13; lbl.TextXAlignment=Enum.TextXAlignment.Left
    local cbtn=Instance.new("TextButton",row); cbtn.Size=UDim2.new(0,40,0,20); cbtn.Position=UDim2.new(1,-55,0.5,-10)
    cbtn.BackgroundColor3=Settings[cat][key]; cbtn.Text=""
    Instance.new("UICorner",cbtn).CornerRadius=UDim.new(0,4); Instance.new("UIStroke",cbtn).Color=Theme.Accent
    local ci=1; for i,c in ipairs(CLR) do if c==Settings[cat][key] then ci=i break end end
    cbtn.MouseButton1Click:Connect(function() ci=(ci%#CLR)+1; Settings[cat][key]=CLR[ci]; cbtn.BackgroundColor3=CLR[ci] end)
    tab.Container.CanvasSize=UDim2.new(0,0,0,tab.YOff+10)
end

-- ONGLETS
CreateTab("Accueil","Home",0); Sec("Home","Bienvenue sur Noky Script Emden")
Btn("Home","Statut : Indétectable & Sûr",function()end)
Btn("Home","Version : V10 Édition Propre",function()end)
Btn("Home","Bon jeu et amuse-toi bien !",function()end)

CreateTab("Visuels","Vis",1)
Toggle("Vis","Activer l'ESP","Visuals","Enable")
Slider("Vis","Distance max de vue (m)","Visuals","MaxDistance",100,2000)
Toggle("Vis","ESP Boîte","Visuals","Box"); Clr("Vis","Couleur Boîte","ESPColors","Box")
Toggle("Vis","ESP Nom","Visuals","Name"); Toggle("Vis","ESP Santé","Visuals","Health")
Toggle("Vis","ESP Distance","Visuals","Distance"); Toggle("Vis","ESP Squelette","Visuals","Skeleton")
Toggle("Vis","Lignes de visée","Visuals","Snaplines"); Toggle("Vis","ESP Arme","Visuals","Weapon")

CreateTab("Mouvement","Mov",2)
Toggle("Mov","God mode local","Movement","GodMode")
Toggle("Mov","Énergie illimitée (détection auto)","Movement","UnlimitedEnergy")
Toggle("Mov","Traverser les murs (Noclip)","Movement","Noclip"); Toggle("Mov","Sans dégâts de chute","Movement","NoFallDamage")
Toggle("Mov","Téléportation Ctrl+Clic","Movement","ClickTP"); Sec("Mov","Vol du personnage")
Toggle("Mov","Activer le fly","Movement","Fly")
Slider("Mov","Vitesse du fly","Movement","FlySpeed",10,250)
Keybind("Mov","Monter avec","Movement","FlyUpKey")
Keybind("Mov","Descendre avec","Movement","FlyDownKey")
Sec("Mov","Utilitaires")
Btn("Mov","Mort rapide (Réapparition instantanée)",function()
    local c=LocalPlayer.Character; if c and c:FindFirstChild("Humanoid") then c.Humanoid.Health=0 end
end)
Btn("Mov","Sortir de la voiture de police",function()
    local c=LocalPlayer.Character; if c and c:FindFirstChild("Humanoid") then
        c.Humanoid.Sit=false; task.wait(0.1)
        local r=c:FindFirstChild("HumanoidRootPart"); if r then r.CFrame=r.CFrame*CFrame.new(0,5,0) end
    end
end)

local function TpCar(pos)
    local char=LocalPlayer.Character; if not char then return end
    local root=char:FindFirstChild("HumanoidRootPart"); local hum=char:FindFirstChild("Humanoid")
    if not root or not hum then return end
    local seat=hum.SeatPart; local inCar=seat and seat:IsA("VehicleSeat")
    local car=inCar and seat:FindFirstAncestorWhichIsA("Model") or nil
    if car then
        local pri=car.PrimaryPart or car:FindFirstChildOfClass("VehicleSeat") or car:FindFirstChildWhichIsA("BasePart")
        if pri then
            if car.PrimaryPart then car:SetPrimaryPartCFrame(CFrame.new(pos)) else pri.CFrame=CFrame.new(pos) end
            for _,p in pairs(car:GetDescendants()) do if p:IsA("BasePart") then p.AssemblyLinearVelocity=Vector3.zero; p.AssemblyAngularVelocity=Vector3.zero end end
            return
        end
    end
    root.CFrame=CFrame.new(pos)
end

local Dealers={Vector3.new(-2698,44,166),Vector3.new(23,72,231),Vector3.new(47,101,65),Vector3.new(75,44,1804)}
CreateTab("Téléportation","TP",3)
Btn("TP","Téléportation au concessionnaire le plus proche",function(b)
    local r=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not r then return end
    local best,bd=nil,math.huge
    for _,p in ipairs(Dealers) do local d=(r.Position-p).Magnitude; if d<bd then bd=d;best=p end end
    if best then TpCar(best); local o=b.Text; b.Text="  Téléportation..."; task.wait(1); b.Text=o
    else local o=b.Text; b.Text="  Introuvable !"; b.TextColor3=Theme.Danger; task.wait(2); b.Text=o; b.TextColor3=Theme.Text end
end)
local TPs={
    {"Téléports Braquage",{{"Bijoutier",Vector3.new(-473,44,303)},{"Banque",Vector3.new(-500,44,-1369)},{"Banque V2",Vector3.new(-414,44,-236)},{"Station-service 1",Vector3.new(-593,44,2431)},{"Station-service 2",Vector3.new(-1279,44,2135)},{"Station-service 3",Vector3.new(486,44,-2241)},{"Station Moon",Vector3.new(-1343,44,-1152)},{"Maison 1",Vector3.new(-1636,44,-800)},{"Maison 2",Vector3.new(-2112,44,-858)},{"Maison 3",Vector3.new(-2058,44,-632)}}},
    {"Point de livraison",{{"Armurier",Vector3.new(-223,44,-681)},{"Hôpital",Vector3.new(-491,44,-1761)},{"Station-service 3",Vector3.new(-462,44,-2210)},{"Station Moon",Vector3.new(-1319,44,-1104)},{"Commissariat",Vector3.new(106,72,891)},{"Spawn Voiture",Vector3.new(-954,44,225)},{"Pompiers",Vector3.new(-2081,44,421)},{"Maison",Vector3.new(-1894,44,-621)},{"D.A.C.E",Vector3.new(-1674,44,-1271)},{"OPI",Vector3.new(835,44,249)}}},
    {"Téléports Carte",{{"D.A.C.E",Vector3.new(-1707,44,-1407)},{"Spawn Voiture",Vector3.new(-1002,44,150)},{"Pompiers",Vector3.new(-1721,44,417)},{"Hôpital",Vector3.new(426,44,-1715)},{"Magasin de véhicules",Vector3.new(105,44,-2169)},{"Commissariat",Vector3.new(-70,71,769)}}}
}
for _,cat in ipairs(TPs) do Sec("TP",cat[1]); for _,loc in ipairs(cat[2]) do Btn("TP","→  "..loc[1],function() TpCar(loc[2]) end) end end

-- Boost Voiture
CreateTab("Boost Voiture","Car",4); Sec("Car","Réglages Voiture")
Toggle("Car","Vie illimitée (détection auto)","Vehicle","UnlimitedHealth")
Keybind("Car","Touche d'accélération","Vehicle","AccelKey")
Slider("Car","Multiplicateur d'accélération","Vehicle","SpeedMultiplier",0,50,1000)
Keybind("Car","Touche de frein","Vehicle","BrakeKey")
Slider("Car","Force de freinage","Vehicle","BrakeForce",0,300,1000)
Sec("Car","Vol du véhicule occupé")
Toggle("Car","Activer le véhicule fly","Vehicle","Fly")
Slider("Car","Vitesse du véhicule fly","Vehicle","FlySpeed",20,300)
Slider("Car","Lissage du véhicule fly","Vehicle","FlyResponsiveness",5,50,10)
Keybind("Car","Monter avec","Vehicle","FlyUpKey")
Keybind("Car","Descendre avec","Vehicle","FlyDownKey")

CreateTab("Divers","Misc",5)
Toggle("Misc","Afficher le compteur FPS","Misc","ShowFPS")
Btn("Misc","Boost FPS",function()
    local L=game:GetService("Lighting"); L.GlobalShadows=false; L.FogEnd=9e9
    for _,v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then v.Material=Enum.Material.SmoothPlastic; v.CastShadow=false
        elseif v:IsA("Decal") or v:IsA("Texture") or v:IsA("ParticleEmitter") or v:IsA("Trail") then pcall(function() v:Destroy() end) end
    end
end)

-- Paramètres du menu et récupération locale.
CreateTab("Paramètres","Settings",6)
Sec("Settings","Contrôles du menu")
Keybind("Settings","Touche ouvrir / fermer","Controls","MenuKey")
Sec("Settings","Récupération locale")
Btn("Settings","Ramener mon véhicule à moi",function(b)
    local char=LocalPlayer.Character
    local root=char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- Ne cible que le véhicule dans lequel le joueur local est assis.
    local hum=char:FindFirstChildWhichIsA("Humanoid")
    local seat=hum and hum.SeatPart
    if seat and seat:IsA("VehicleSeat") then
        local vehicle=seat:FindFirstAncestorWhichIsA("Model")
        local part=vehicle and (vehicle.PrimaryPart or vehicle:FindFirstChildWhichIsA("BasePart"))
        if part then
            local offset=root.CFrame*CFrame.new(0,0,-8)
            if vehicle.PrimaryPart then vehicle:SetPrimaryPartCFrame(offset) else part.CFrame=offset end
        end
    else
        local old=b.Text; b.Text="  Assieds-toi dans ton véhicule d'abord"; task.delay(2,function() if b.Parent then b.Text=old end end)
    end
end)
Btn("Settings","Me téléporter au véhicule le plus proche",function(b)
    local char=LocalPlayer.Character
    local root=char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local nearest,dist
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("VehicleSeat") and not obj.Occupant then
            local d=(obj.Position-root.Position).Magnitude
            if not dist or d<dist then nearest,dist=obj,d end
        end
    end
    if nearest then root.CFrame=nearest.CFrame*CFrame.new(0,2,0)
    else
        local old=b.Text; b.Text="  Aucun siège libre trouvé"; task.delay(2,function() if b.Parent then b.Text=old end end)
    end
end)
Btn("Misc","Changer de serveur",function()
    local req=request or http_request or (syn and syn.request); if not req then return end
    local r=req({Url=("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)})
    if r and r.Body then
        local b=HttpService:JSONDecode(r.Body)
        if b and b.data then for _,v in ipairs(b.data) do if type(v)=="table" and v.playing<v.maxPlayers and v.id~=game.JobId then TeleportService:TeleportToPlaceInstance(game.PlaceId,v.id,LocalPlayer); break end end end
    end
end)

SwitchTab("Home")

-- Cache Armes
local WCache={}
local function GetWpn(tool)
    if not tool then return "" end
    if WCache[tool] then return WCache[tool] end
    local n=(tool.ToolTip~="" and tool.ToolTip) or tool.Name
    if n:match("%x%x%x%x%x%x%x%x%-") then n="Équipé"
        for _,c in pairs(tool:GetChildren()) do if c:IsA("BasePart") and c.Name~="Handle" then n=c.Name break end end
    end
    WCache[tool]=n; return n
end

-- ESP
local function US(o,v,p,s,c) if o.Visible~=v then o.Visible=v end if not v then return end local px,py=math.floor(p.X),math.floor(p.Y); if math.floor(o.Position.X)~=px or math.floor(o.Position.Y)~=py then o.Position=Vector2.new(px,py) end local sx,sy=math.floor(s.X),math.floor(s.Y); if math.floor(o.Size.X)~=sx or math.floor(o.Size.Y)~=sy then o.Size=Vector2.new(sx,sy) end if o.Color~=c then o.Color=c end end
local function UT(o,v,t,p,c) if o.Visible~=v then o.Visible=v end if not v then return end if o.Text~=t then o.Text=t end local px,py=math.floor(p.X),math.floor(p.Y); if math.floor(o.Position.X)~=px or math.floor(o.Position.Y)~=py then o.Position=Vector2.new(px,py) end if o.Color~=c then o.Color=c end end
local function UL(o,v,f,t,c) if o.Visible~=v then o.Visible=v end if not v then return end local fx,fy=math.floor(f.X),math.floor(f.Y); if math.floor(o.From.X)~=fx or math.floor(o.From.Y)~=fy then o.From=Vector2.new(fx,fy) end local tx,ty=math.floor(t.X),math.floor(t.Y); if math.floor(o.To.X)~=tx or math.floor(o.To.Y)~=ty then o.To=Vector2.new(tx,ty) end if o.Color~=c then o.Color=c end end

local EC={}
local function NE()
    local e={Box=Drawing.new("Square"),BoxO=Drawing.new("Square"),HpBg=Drawing.new("Square"),Hp=Drawing.new("Square"),Name=Drawing.new("Text"),Wpn=Drawing.new("Text"),Snap=Drawing.new("Line"),Bones={}}
    for i=1,14 do e.Bones[i]=Drawing.new("Line"); e.Bones[i].Thickness=1.5 end
    e.Name.Center=true; e.Name.Outline=true; e.Name.Size=15; e.Name.Font=2
    e.Wpn.Center=true; e.Wpn.Outline=true; e.Wpn.Size=13; e.Wpn.Font=2
    e.Box.Filled=false; e.Box.Thickness=1; e.BoxO.Filled=false; e.BoxO.Thickness=3
    e.HpBg.Filled=true; e.HpBg.Color=Color3.fromRGB(0,0,0); e.Hp.Filled=true
    return e
end
local function HA(e) US(e.Box,false); US(e.BoxO,false); US(e.HpBg,false); US(e.Hp,false); UT(e.Name,false); UT(e.Wpn,false); UL(e.Snap,false); for i=1,14 do UL(e.Bones[i],false) end end
local R15={{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}}
local W=Color3.fromRGB(255,255,255); local BK=Color3.fromRGB(0,0,0)

RunService.RenderStepped:Connect(function()
    _ff+=1; local t=tick()
    if t-_fl>=1 then FPSLabel.Text="FPS: "..math.floor(_ff/(t-_fl)); _ff=0; _fl=t end
    FPSLabel.Visible=Settings.Misc.ShowFPS and UIVisible

    _frameCount+=1
    if _frameCount%2~=0 then return end

    if not Settings.Visuals.Enable then
        for _,e in pairs(EC) do HA(e) end return
    end

    local cam=workspace.CurrentCamera
    local camPos=cam.CFrame.Position; local vps=cam.ViewportSize

    for _,p in pairs(Players:GetPlayers()) do
        if p==LocalPlayer then continue end
        local e=EC[p.UserId]; if not e then e=NE(); EC[p.UserId]=e end
        local char=p.Character
        if not char then HA(e); continue end
        local root=char:FindFirstChild("HumanoidRootPart"); local hum=char:FindFirstChild("Humanoid")
        if not root or not hum or hum.Health<=0 then HA(e); continue end
        local dist=(camPos-root.Position).Magnitude
        if dist>Settings.Visuals.MaxDistance then HA(e); continue end
        local head=char:FindFirstChild("Head") or root
        local sc,on=cam:WorldToViewportPoint(root.Position)
        if not on then HA(e); continue end
        local hSc=cam:WorldToViewportPoint(head.Position+Vector3.new(0,0.5,0))
        local lSc=cam:WorldToViewportPoint(root.Position-Vector3.new(0,3,0))
        local top=math.min(hSc.Y,lSc.Y); local bot=math.max(hSc.Y,lSc.Y)
        local h=math.abs(hSc.Y-lSc.Y); local w=h/1.5; local col=Settings.ESPColors.Box
        US(e.Box,Settings.Visuals.Box,Vector2.new(sc.X-w/2,top),Vector2.new(w,h),col)
        US(e.BoxO,Settings.Visuals.Box,Vector2.new(sc.X-w/2-1,top-1),Vector2.new(w+2,h+2),BK)
        local hp=math.clamp(hum.Health/hum.MaxHealth,0,1)
        US(e.HpBg,Settings.Visuals.Health,Vector2.new(sc.X-w/2-6,top-1),Vector2.new(3,h+2),BK)
        US(e.Hp,Settings.Visuals.Health,Vector2.new(sc.X-w/2-5,top+(h*(1-hp))),Vector2.new(1,h*hp),Color3.fromHSV(hp*0.3,1,1))
        local nv=Settings.Visuals.Name or Settings.Visuals.Distance
        local nt=Settings.Visuals.Name and p.Name or ""
        if Settings.Visuals.Distance then nt=nt..(nt~="" and " [" or "[")..math.floor(dist).."m]" end
        UT(e.Name,nv,nt,Vector2.new(sc.X,top-18),W)
        UT(e.Wpn,Settings.Visuals.Weapon,GetWpn(char:FindFirstChildOfClass("Tool")),Vector2.new(sc.X,bot+4),Color3.fromRGB(200,200,200))
        UL(e.Snap,Settings.Visuals.Snaplines,Vector2.new(vps.X/2,vps.Y),Vector2.new(sc.X,lSc.Y),col)
        if Settings.Visuals.Skeleton then
            for i=1,14 do
                local pA=char:FindFirstChild(R15[i][1]); local pB=char:FindFirstChild(R15[i][2])
                if pA and pB then
                    local a,va=cam:WorldToViewportPoint(pA.Position); local b,vb=cam:WorldToViewportPoint(pB.Position)
                    if va or vb then UL(e.Bones[i],true,Vector2.new(a.X,a.Y),Vector2.new(b.X,b.Y),W) else UL(e.Bones[i],false) end
                else UL(e.Bones[i],false) end
            end
        else for i=1,14 do UL(e.Bones[i],false) end end
    end
end)

Players.PlayerRemoving:Connect(function(p)
    if EC[p.UserId] then
        for _,o in pairs(EC[p.UserId]) do
            if type(o)=="table" then for _,s in pairs(o) do pcall(function() s:Remove() end) end
            else pcall(function() o:Remove() end) end
        end; EC[p.UserId]=nil
    end
end)

-- MOUVEMENT ET VÉHICULE
RunService.Heartbeat:Connect(function(dt)
    local char=LocalPlayer.Character; if not char then return end
    local root=char:FindFirstChild("HumanoidRootPart")
    local hum=char:FindFirstChildWhichIsA("Humanoid")

    -- Restaure la santé locale tant que le personnage est vivant.
    if Settings.Movement.GodMode and hum and hum.Health>0 and hum.Health<hum.MaxHealth then
        hum.Health=hum.MaxHealth
    end
    if Settings.Movement.UnlimitedEnergy then
        RefillResource(LocalPlayer,ResourceBindings.Energy)
        if char then RefillResource(char,ResourceBindings.Energy) end
    end

    if Settings.Movement.Noclip then
        for _,p in pairs(char:GetChildren()) do
            if p:IsA("BasePart") and p.CanCollide then p.CanCollide=false end
        end
    end

    if Settings.Movement.NoFallDamage and root and root.AssemblyLinearVelocity.Y<-40 then
        local rp=RaycastParams.new(); rp.FilterDescendantsInstances={char}; rp.FilterType=Enum.RaycastFilterType.Blacklist
        local ray=workspace:Raycast(root.Position,Vector3.new(0,-25,0),rp)
        if ray then root.AssemblyLinearVelocity=Vector3.new(root.AssemblyLinearVelocity.X,0,root.AssemblyLinearVelocity.Z) end
    end

    if Settings.Movement.Fly and root and not (hum and hum.SeatPart) then
        local cam=workspace.CurrentCamera
        if cam then
            local direction=Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction+=cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction-=cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction+=cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction-=cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Settings.Movement.FlyUpKey) then direction+=Vector3.yAxis end
            if UserInputService:IsKeyDown(Settings.Movement.FlyDownKey) then direction-=Vector3.yAxis end
            root.AssemblyLinearVelocity=direction.Magnitude>0 and direction.Unit*Settings.Movement.FlySpeed or Vector3.zero
            root.AssemblyAngularVelocity=Vector3.zero
        end
    end

    if hum and hum.SeatPart and hum.SeatPart:IsA("VehicleSeat") then
        local seat=hum.SeatPart
        if Settings.Vehicle.UnlimitedHealth then
            RefillResource(seat:FindFirstAncestorWhichIsA("Model"),ResourceBindings.VehicleHealth)
        end
        if Settings.Vehicle.AccelKey~=Enum.KeyCode.Unknown and UserInputService:IsKeyDown(Settings.Vehicle.AccelKey) then
            seat.AssemblyLinearVelocity*=Vector3.new(1+Settings.Vehicle.SpeedMultiplier,1,1+Settings.Vehicle.SpeedMultiplier)
        end
        if Settings.Vehicle.BrakeKey~=Enum.KeyCode.Unknown and UserInputService:IsKeyDown(Settings.Vehicle.BrakeKey) then
            seat.AssemblyLinearVelocity*=Vector3.new(1-Settings.Vehicle.BrakeForce,1,1-Settings.Vehicle.BrakeForce)
        end
        if Settings.Vehicle.Fly then
            local vehicle=seat:FindFirstAncestorWhichIsA("Model")
            local part=vehicle and (vehicle.PrimaryPart or vehicle:FindFirstChildWhichIsA("BasePart")) or seat
            local cam=workspace.CurrentCamera
            if part and cam then
                local direction=Vector3.zero
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction+=cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction-=cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction+=cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction-=cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Settings.Vehicle.FlyUpKey) then direction+=Vector3.yAxis end
                if UserInputService:IsKeyDown(Settings.Vehicle.FlyDownKey) then direction-=Vector3.yAxis end
                -- Ease toward the requested velocity, preserving momentum on release.
                -- This avoids the abrupt zero-velocity change that can trigger crash logic.
                local currentVelocity=part.AssemblyLinearVelocity
                local targetVelocity=direction.Magnitude>0 and direction.Unit*Settings.Vehicle.FlySpeed or Vector3.zero
                local alpha=1-math.exp(-Settings.Vehicle.FlyResponsiveness*dt)
                part.AssemblyLinearVelocity=currentVelocity:Lerp(targetVelocity,alpha)
            end
        end
    end
end)

print("[+] Noky Script Emden V10 chargé avec succès !")
