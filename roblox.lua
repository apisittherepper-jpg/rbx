-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

----------------------------------------------------------------
-- EXECUTOR COMPATIBILITY (Delta, Fluxus, Arceus X, etc.)
----------------------------------------------------------------
local ExecutorName = "Unknown"
local HasDrawing = Drawing and Drawing.new ~= nil

-- ตรวจสอบ Executor
if identifyexecutor then
    ExecutorName = identifyexecutor() or "Unknown"
elseif getexecutorname then
    ExecutorName = getexecutorname() or "Unknown"
elseif KRNL_LOADED then
    ExecutorName = "KRNL"
elseif syn then
    ExecutorName = "Synapse X"
end

-- แจ้งเตือนถ้าไม่รองรับ Drawing (บาง Executor เก่า)
if not HasDrawing then
    warn("[AdminHub] Drawing API not supported. ESP Box will be disabled.")
end

print("[AdminHub] Loaded on: " .. ExecutorName)
print("[AdminHub] Drawing API: " .. (HasDrawing and "Supported" or "Not Supported"))

----------------------------------------------------------------
-- SYSTEM CLEANUP (ป้องกัน Script รันซ้อน & Memory Leak)
----------------------------------------------------------------
if getgenv().AdminHubConnections then
    for _, conn in pairs(getgenv().AdminHubConnections) do
        if conn then conn:Disconnect() end
    end
end
getgenv().AdminHubConnections = {}

-- ล้าง UI เก่าออก
if game.CoreGui:FindFirstChild("DevHubClassic") then
    game.CoreGui.DevHubClassic:Destroy()
end

----------------------------------------------------------------
-- CONFIG (ค่าเริ่มต้น)
----------------------------------------------------------------
getgenv().Settings = {
    Aimbot = false,
    WallCheck = true,
    ShowFOV = true,
    FOVSize = 150,
    Smoothness = 0.2,
    ESP = false,
    ESPBox = false,
    ESPShowName = true,
    ESPShowHealth = true,
    ESPBoxColor = {R = 255, G = 0, B = 0},
    TeamCheck = false,
    NoReload = false,
    RapidFire = false,
    NoRecoil = false,
    NoClip = false,
    Invisible = false,
    -- SilentAim ถูกลบออกเพราะทำให้ lag
    SilentAimPart = "Head", -- Head, Torso, HumanoidRootPart
    Antilag = false, -- FPS Boost
    AutoFire = false, -- ยิงอัตโนมัติเมื่อเล็งเป้าหมายใน FOV
    Running = true
}

-- ESP Box Storage
getgenv().ESPBoxStorage = {}

----------------------------------------------------------------
-- GUI SETUP
----------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DevHubClassic"
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false

local success = pcall(function() ScreenGui.Parent = game.CoreGui end)
if not success then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- 1. FOV CIRCLE
local FOVCircle = Instance.new("Frame")
FOVCircle.Name = "FOVCircle"
FOVCircle.Parent = ScreenGui
FOVCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
FOVCircle.BackgroundTransparency = 1
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
FOVCircle.Visible = false
FOVCircle.ZIndex = 1

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(1, 0)
UICorner.Parent = FOVCircle

local UIStroke = Instance.new("UIStroke")
UIStroke.Parent = FOVCircle
UIStroke.Color = Color3.fromRGB(0, 255, 0)
UIStroke.Thickness = 2
UIStroke.Transparency = 0.3

-- 2. MAIN WINDOW
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MainFrame.Position = UDim2.new(0.1, 0, 0.2, 0)
MainFrame.Size = UDim2.new(0, 450, 0, 280)
MainFrame.Active = true
MainFrame.Draggable = true

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

-- SIDEBAR
local Sidebar = Instance.new("Frame")
Sidebar.Parent = MainFrame
Sidebar.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
Sidebar.Size = UDim2.new(0, 120, 1, 0)
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 5

local SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = UDim.new(0, 8)
SidebarCorner.Parent = Sidebar

local SidebarFix = Instance.new("Frame")
SidebarFix.Parent = Sidebar
SidebarFix.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
SidebarFix.BorderSizePixel = 0
SidebarFix.Position = UDim2.new(1, -5, 0, 0)
SidebarFix.Size = UDim2.new(0, 5, 1, 0)
SidebarFix.ZIndex = 5

-- TITLE
local AppTitle = Instance.new("TextLabel")
AppTitle.Parent = Sidebar
AppTitle.BackgroundTransparency = 1
AppTitle.Position = UDim2.new(0, 0, 0, 15)
AppTitle.Size = UDim2.new(1, 0, 0, 30)
AppTitle.Font = Enum.Font.GothamBold
AppTitle.Text = "AIMBOT HUB"
AppTitle.TextColor3 = Color3.fromRGB(0, 255, 150)
AppTitle.TextSize = 16
AppTitle.ZIndex = 6

-- PAGE CONTAINER
local PageContainer = Instance.new("Frame")
PageContainer.Parent = MainFrame
PageContainer.BackgroundTransparency = 1
PageContainer.Position = UDim2.new(0, 130, 0, 10)
PageContainer.Size = UDim2.new(1, -140, 1, -20)

----------------------------------------------------------------
-- TABS & PAGES SYSTEM (with Expandable Submenus)
----------------------------------------------------------------
local Tabs = {}
local TabButtons = {}
local SubMenus = {} -- เก็บ submenu items
local TabYOffset = 60 -- ตำแหน่ง Y เริ่มต้น

local function UpdateTabPositions()
    -- อัปเดตตำแหน่งปุ่มทั้งหมดหลังจากขยาย/ย่อ submenu
    local yPos = 60
    for _, data in ipairs(TabButtons) do
        if data.Btn then
            data.Btn.Position = UDim2.new(0.075, 0, 0, yPos)
            yPos = yPos + 40
            
            -- ถ้ามี submenu และกำลังขยายอยู่
            if data.SubItems and data.Expanded then
                for _, subBtn in ipairs(data.SubItems) do
                    subBtn.Position = UDim2.new(0.1, 0, 0, yPos)
                    subBtn.Visible = true
                    yPos = yPos + 35
                end
            elseif data.SubItems then
                for _, subBtn in ipairs(data.SubItems) do
                    subBtn.Visible = false
                end
            end
        end
    end
end

local function SwitchTab(target)
    for name, page in pairs(Tabs) do
        page.Visible = false
    end
    if Tabs[target] then Tabs[target].Visible = true end
    
    -- อัปเดตสีปุ่ม Parent
    for _, data in ipairs(TabButtons) do
        if data.Name == target then
            data.Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            data.Btn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        else
            data.Btn.TextColor3 = Color3.fromRGB(150, 150, 150)
            data.Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
        end
        
        -- Reset สี Sub-buttons ทั้งหมด
        if data.SubItems then
            for _, subBtn in ipairs(data.SubItems) do
                subBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
                subBtn.TextColor3 = Color3.fromRGB(130, 130, 130)
            end
        end
    end
end

local function CreateTab(name, hasSubMenu)
    local tabData = {Name = name, Expanded = false, SubItems = {}}
    
    local Btn = Instance.new("TextButton")
    Btn.Parent = Sidebar
    Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    Btn.Size = UDim2.new(0.85, 0, 0, 35)
    Btn.Font = Enum.Font.GothamMedium
    Btn.Text = hasSubMenu and ("▶ " .. name) or name
    Btn.TextColor3 = Color3.fromRGB(150, 150, 150)
    Btn.TextSize = 14
    Btn.AutoButtonColor = false
    Btn.ZIndex = 6
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Btn
    
    tabData.Btn = Btn
    
    if hasSubMenu then
        -- คลิกเพื่อขยาย/ย่อ submenu
        Btn.MouseButton1Click:Connect(function()
            tabData.Expanded = not tabData.Expanded
            Btn.Text = (tabData.Expanded and "▼ " or "▶ ") .. name
            UpdateTabPositions()
            
            -- Auto-open first subtab if exists
            if tabData.Expanded and #tabData.SubItems > 0 and tabData.FirstSubItemCallback then
                tabData.FirstSubItemCallback()
            end
        end)
    else
        Btn.MouseButton1Click:Connect(function() SwitchTab(name) end)
    end
    
    local Page = Instance.new("ScrollingFrame")
    Page.Parent = PageContainer
    Page.BackgroundTransparency = 1
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.ScrollBarThickness = 2
    Page.Visible = false
    
    local List = Instance.new("UIListLayout")
    List.Parent = Page
    List.SortOrder = Enum.SortOrder.LayoutOrder
    List.Padding = UDim.new(0, 8)
    
    Tabs[name] = Page
    table.insert(TabButtons, tabData)
    
    UpdateTabPositions()
    
    return Page, tabData
end

local function CreateSubTab(parentData, name)
    local SubBtn = Instance.new("TextButton")
    SubBtn.Parent = Sidebar
    SubBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    SubBtn.Size = UDim2.new(0.75, 0, 0, 30)
    SubBtn.Font = Enum.Font.Gotham
    SubBtn.Text = "  • " .. name
    SubBtn.TextColor3 = Color3.fromRGB(130, 130, 130)
    SubBtn.TextSize = 12
    SubBtn.TextXAlignment = Enum.TextXAlignment.Left
    SubBtn.AutoButtonColor = false
    SubBtn.Visible = false
    SubBtn.ZIndex = 6
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 4)
    Corner.Parent = SubBtn
    
    SubBtn.MouseButton1Click:Connect(function()
        SwitchTab(name)
        -- ไฮไลท์ sub-item
        for _, sub in ipairs(parentData.SubItems) do
            sub.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
            sub.TextColor3 = Color3.fromRGB(130, 130, 130)
        end
        SubBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
        SubBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
    
    table.insert(parentData.SubItems, SubBtn)
    
    -- ถ้าเป็น subitem แรก ให้เก็บ callback ไว้ที่ parent
    if #parentData.SubItems == 1 then
        parentData.FirstSubItemCallback = function()
            SwitchTab(name)
            for _, sub in ipairs(parentData.SubItems) do
                sub.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
                sub.TextColor3 = Color3.fromRGB(130, 130, 130)
            end
            SubBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
            SubBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end
    
    -- สร้าง Page สำหรับ sub-tab
    local Page = Instance.new("ScrollingFrame")
    Page.Parent = PageContainer
    Page.BackgroundTransparency = 1
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.ScrollBarThickness = 2
    Page.Visible = false
    
    local List = Instance.new("UIListLayout")
    List.Parent = Page
    List.SortOrder = Enum.SortOrder.LayoutOrder
    List.Padding = UDim.new(0, 8)
    
    Tabs[name] = Page
    
    UpdateTabPositions()
    
    return Page
end

----------------------------------------------------------------
-- UI COMPONENTS (Toggle, Adjuster)
----------------------------------------------------------------
local function CreateToggle(parent, text, callback)
    local Frame = Instance.new("Frame")
    Frame.Parent = parent
    Frame.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    Frame.Size = UDim2.new(1, 0, 0, 40)
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Frame
    
    local Label = Instance.new("TextLabel")
    Label.Parent = Frame
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.Size = UDim2.new(0.6, 0, 1, 0)
    Label.Font = Enum.Font.Gotham
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(220, 220, 220)
    Label.TextSize = 14
    Label.TextXAlignment = Enum.TextXAlignment.Left
    
    local Switch = Instance.new("Frame")
    Switch.Parent = Frame
    Switch.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    Switch.Position = UDim2.new(1, -50, 0.5, -10)
    Switch.Size = UDim2.new(0, 40, 0, 20)
    
    local SWCorner = Instance.new("UICorner")
    SWCorner.CornerRadius = UDim.new(1, 0)
    SWCorner.Parent = Switch
    
    local Circle = Instance.new("Frame")
    Circle.Parent = Switch
    Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Circle.Position = UDim2.new(0, 2, 0.5, -8)
    Circle.Size = UDim2.new(0, 16, 0, 16)
    
    local CirCorner = Instance.new("UICorner")
    CirCorner.CornerRadius = UDim.new(1, 0)
    CirCorner.Parent = Circle
    
    local Btn = Instance.new("TextButton")
    Btn.Parent = Frame
    Btn.BackgroundTransparency = 1
    Btn.Size = UDim2.new(1, 0, 1, 0)
    Btn.Text = ""
    
    local on = false
    Btn.MouseButton1Click:Connect(function()
        on = not on
        if on then
            Switch.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
            Circle:TweenPosition(UDim2.new(1, -18, 0.5, -8), "Out", "Sine", 0.1)
        else
            Switch.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
            Circle:TweenPosition(UDim2.new(0, 2, 0.5, -8), "Out", "Sine", 0.1)
        end
        callback(on)
    end)
end

local function CreateStepper(parent, text, default, min, max, step, callback)
    local Frame = Instance.new("Frame")
    Frame.Parent = parent
    Frame.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    Frame.Size = UDim2.new(1, 0, 0, 50)
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Frame
    
    local Label = Instance.new("TextLabel")
    Label.Parent = Frame
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.Size = UDim2.new(1, 0, 0, 25)
    Label.Font = Enum.Font.Gotham
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(220, 220, 220)
    Label.TextSize = 14
    Label.TextXAlignment = Enum.TextXAlignment.Left
    
    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Parent = Frame
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Position = UDim2.new(0, 10, 0, 25)
    ValueLabel.Size = UDim2.new(1, -20, 0, 20)
    ValueLabel.Font = Enum.Font.GothamBold
    ValueLabel.Text = tostring(default)
    ValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    ValueLabel.TextSize = 14
    
    local Minus = Instance.new("TextButton")
    Minus.Parent = Frame
    Minus.BackgroundColor3 = Color3.fromRGB(70, 40, 40)
    Minus.Position = UDim2.new(0, 10, 0, 25)
    Minus.Size = UDim2.new(0, 30, 0, 20)
    Minus.Text = "-"
    Minus.TextColor3 = Color3.fromRGB(255, 255, 255)
    local MCorner = Instance.new("UICorner"); MCorner.CornerRadius = UDim.new(0,4); MCorner.Parent = Minus
    
    local Plus = Instance.new("TextButton")
    Plus.Parent = Frame
    Plus.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
    Plus.Position = UDim2.new(1, -40, 0, 25)
    Plus.Size = UDim2.new(0, 30, 0, 20)
    Plus.Text = "+"
    Plus.TextColor3 = Color3.fromRGB(255, 255, 255)
    local PCorner = Instance.new("UICorner"); PCorner.CornerRadius = UDim.new(0,4); PCorner.Parent = Plus
    
    local val = default
    Minus.MouseButton1Click:Connect(function()
        val = math.clamp(val - step, min, max)
        val = math.floor(val * 100) / 100
        ValueLabel.Text = tostring(val)
        callback(val)
    end)
    Plus.MouseButton1Click:Connect(function()
        val = math.clamp(val + step, min, max)
        val = math.floor(val * 100) / 100
        ValueLabel.Text = tostring(val)
        callback(val)
    end)
end

local function CreateSlider(parent, text, default, min, max, decimals, callback)
    local Frame = Instance.new("Frame")
    Frame.Parent = parent
    Frame.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    Frame.Size = UDim2.new(1, 0, 0, 55)
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Frame
    
    local Label = Instance.new("TextLabel")
    Label.Parent = Frame
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.new(0, 10, 0, 5)
    Label.Size = UDim2.new(0.6, 0, 0, 20)
    Label.Font = Enum.Font.Gotham
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(220, 220, 220)
    Label.TextSize = 14
    Label.TextXAlignment = Enum.TextXAlignment.Left
    
    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Parent = Frame
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Position = UDim2.new(0.6, 0, 0, 5)
    ValueLabel.Size = UDim2.new(0.35, 0, 0, 20)
    ValueLabel.Font = Enum.Font.GothamBold
    ValueLabel.Text = tostring(default)
    ValueLabel.TextColor3 = Color3.fromRGB(0, 200, 100)
    ValueLabel.TextSize = 14
    ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    
    -- Slider Background
    local SliderBG = Instance.new("Frame")
    SliderBG.Parent = Frame
    SliderBG.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    SliderBG.Position = UDim2.new(0, 10, 0, 30)
    SliderBG.Size = UDim2.new(1, -20, 0, 16)
    SliderBG.BorderSizePixel = 0
    
    local SliderBGCorner = Instance.new("UICorner")
    SliderBGCorner.CornerRadius = UDim.new(0, 8)
    SliderBGCorner.Parent = SliderBG
    
    -- Slider Fill
    local SliderFill = Instance.new("Frame")
    SliderFill.Parent = SliderBG
    SliderFill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    SliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    SliderFill.BorderSizePixel = 0
    
    local SliderFillCorner = Instance.new("UICorner")
    SliderFillCorner.CornerRadius = UDim.new(0, 8)
    SliderFillCorner.Parent = SliderFill
    
    -- Slider Knob
    local Knob = Instance.new("Frame")
    Knob.Parent = SliderBG
    Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Knob.AnchorPoint = Vector2.new(0.5, 0.5)
    Knob.Position = UDim2.new((default - min) / (max - min), 0, 0.5, 0)
    Knob.Size = UDim2.new(0, 14, 0, 14)
    Knob.ZIndex = 2
    
    local KnobCorner = Instance.new("UICorner")
    KnobCorner.CornerRadius = UDim.new(1, 0)
    KnobCorner.Parent = Knob
    
    -- Slider Button (Invisible, for interaction)
    local SliderBtn = Instance.new("TextButton")
    SliderBtn.Parent = SliderBG
    SliderBtn.BackgroundTransparency = 1
    SliderBtn.Size = UDim2.new(1, 0, 1, 0)
    SliderBtn.Text = ""
    SliderBtn.ZIndex = 3
    
    local dragging = false
    local val = default
    
    local function UpdateSlider(input)
        local pos = math.clamp((input.Position.X - SliderBG.AbsolutePosition.X) / SliderBG.AbsoluteSize.X, 0, 1)
        val = min + (max - min) * pos
        
        -- Round to decimals
        local multiplier = 10 ^ decimals
        val = math.floor(val * multiplier + 0.5) / multiplier
        val = math.clamp(val, min, max)
        
        SliderFill.Size = UDim2.new(pos, 0, 1, 0)
        Knob.Position = UDim2.new(pos, 0, 0.5, 0)
        ValueLabel.Text = tostring(val)
        callback(val)
    end
    
    SliderBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            UpdateSlider(input)
        end
    end)
    
    SliderBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            UpdateSlider(input)
        end
    end)
end

----------------------------------------------------------------
-- BUILD PAGES
----------------------------------------------------------------
----------------------------------------------------------------
-- BUILD PAGES
----------------------------------------------------------------
local AimbotTab = CreateTab("Aimbot")
local WeaponTab = CreateTab("Weapon")
local ESPTab = CreateTab("ESP")
local SettingsTab = CreateTab("Settings")

-- PAGE 1: AIMBOT (การเล็ง)
CreateToggle(AimbotTab, "Aimbot", function(v) getgenv().Settings.Aimbot = v end)
CreateToggle(AimbotTab, "Wall Check", function(v) getgenv().Settings.WallCheck = v end)
CreateToggle(AimbotTab, "Team Check", function(v) getgenv().Settings.TeamCheck = v end)
-- Silent Aim ถูกลบเนื่องจากทำให้ระบบค้าง
CreateToggle(AimbotTab, "Show FOV", function(v) getgenv().Settings.ShowFOV = v end)
CreateStepper(AimbotTab, "Smoothness", 0.2, 0.1, 1, 0.1, function(v) getgenv().Settings.Smoothness = v end)
CreateStepper(AimbotTab, "FOV Radius", 150, 10, 800, 10, function(v) getgenv().Settings.FOVSize = v end)

-- PAGE 2: WEAPON (อาวุธ)
CreateToggle(WeaponTab, "No Reload", function(v) getgenv().Settings.NoReload = v end)
CreateToggle(WeaponTab, "Rapid Fire", function(v) getgenv().Settings.RapidFire = v end)
CreateToggle(WeaponTab, "No Recoil", function(v) getgenv().Settings.NoRecoil = v end)
CreateToggle(WeaponTab, "Auto Fire (ยิงอัตโนมัติ)", function(v) getgenv().Settings.AutoFire = v end)

-- PAGE: PLAYER (NoClip + Invisible)
CreateToggle(SettingsTab, "NoClip (ทะลุกำแพง)", function(v) 
    getgenv().Settings.NoClip = v 
end)

CreateToggle(SettingsTab, "Invisible (ล่องหน)", function(v) 
    getgenv().Settings.Invisible = v
    local char = LocalPlayer.Character
    if not char then return end
    
    if v then
        -- ทำให้ล่องหน
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") or part:IsA("MeshPart") then
                part.Transparency = 1
            elseif part:IsA("Decal") or part:IsA("Texture") then
                part.Transparency = 1
            elseif part:IsA("BillboardGui") or part:IsA("SurfaceGui") then
                part.Enabled = false
            end
        end
        -- ซ่อน accessories
        for _, acc in pairs(char:GetChildren()) do
            if acc:IsA("Accessory") then
                local handle = acc:FindFirstChild("Handle")
                if handle then handle.Transparency = 1 end
            end
        end
        -- ซ่อน face
        local head = char:FindFirstChild("Head")
        if head then
            local face = head:FindFirstChild("face") or head:FindFirstChild("Face")
            if face then face.Transparency = 1 end
        end
    else
        -- กลับมาปกติ
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") or part:IsA("MeshPart") then
                if part.Name ~= "HumanoidRootPart" then
                    part.Transparency = 0
                end
            elseif part:IsA("Decal") or part:IsA("Texture") then
                part.Transparency = 0
            elseif part:IsA("BillboardGui") or part:IsA("SurfaceGui") then
                part.Enabled = true
            end
        end
        for _, acc in pairs(char:GetChildren()) do
            if acc:IsA("Accessory") then
                local handle = acc:FindFirstChild("Handle")
                if handle then handle.Transparency = 0 end
            end
        end
        local head = char:FindFirstChild("Head")
        if head then
            local face = head:FindFirstChild("face") or head:FindFirstChild("Face")
            if face then face.Transparency = 0 end
        end
    end
end)

-- PAGE 3: ESP (มองทะลุ)
CreateToggle(ESPTab, "ESP Highlight", function(v) 
    getgenv().Settings.ESP = v
    if not v then
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("DevESP") then
                p.Character.DevESP:Destroy()
            end
        end
    end
end)

CreateToggle(ESPTab, "ESP Box", function(v) 
    getgenv().Settings.ESPBox = v
    if not v then
        for _, data in pairs(getgenv().ESPBoxStorage) do
            if data.Box then data.Box:Remove() end
            if data.Name then data.Name:Remove() end
            if data.Health then data.Health:Remove() end
            if data.HealthBG then data.HealthBG:Remove() end
        end
        getgenv().ESPBoxStorage = {}
    end
end)
CreateToggle(ESPTab, "Show Name", function(v) getgenv().Settings.ESPShowName = v end)
CreateToggle(ESPTab, "Show Health", function(v) getgenv().Settings.ESPShowHealth = v end)

-- Colors
CreateSlider(ESPTab, "Box Red", 255, 0, 255, 0, function(v) getgenv().Settings.ESPBoxColor.R = v end)
CreateSlider(ESPTab, "Box Green", 0, 0, 255, 0, function(v) getgenv().Settings.ESPBoxColor.G = v end)
CreateSlider(ESPTab, "Box Blue", 0, 0, 255, 0, function(v) getgenv().Settings.ESPBoxColor.B = v end)

-- PAGE 4: SETTINGS (ตั้งค่า)
CreateToggle(SettingsTab, "FPS Boost (Anti Lag)", function(v) 
    getgenv().Settings.Antilag = v
end)

-- [[ ANTI-LAG FUNCTION - ใช้ซ้ำได้ ]]
local function ApplyAntiLag()
    pcall(function()
        local Terrain = workspace:FindFirstChildOfClass("Terrain")
        if Terrain then
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
            Terrain.WaterReflectance = 0
            Terrain.WaterTransparency = 0
        end
        
        game.Lighting.GlobalShadows = false
        game.Lighting.FogEnd = 9e9
        settings().Rendering.QualityLevel = 1
    end)
end

local function ApplyAntiLagToObject(obj)
    if not getgenv().Settings.Antilag then return end
    pcall(function()
        if obj:IsA("Part") or obj:IsA("UnionOperation") or obj:IsA("MeshPart") then
            obj.Material = Enum.Material.SmoothPlastic
            obj.Reflectance = 0
        elseif obj:IsA("Decal") and obj.Name ~= "DevHubIcon" then
            obj.Transparency = 1
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
            obj.Lifetime = NumberRange.new(0)
        end
    end)
end

-- [[ ANTI-LAG LOOP - ทำงานตลอดเวลาเมื่อเปิด ]]
task.spawn(function()
    while getgenv().Settings.Running and task.wait(3) do
        if getgenv().Settings.Antilag then
            ApplyAntiLag()
            -- Apply กับ objects ทั้งหมดใน game
            for _, obj in pairs(game:GetDescendants()) do
                ApplyAntiLagToObject(obj)
            end
        end
    end
end)

-- [[ ANTI-LAG สำหรับ OBJECTS ใหม่ (เมื่อด่านเปลี่ยน) ]]
local AntiLagConn = game.DescendantAdded:Connect(function(obj)
    if getgenv().Settings.Antilag then
        task.wait(0.1) -- รอให้ object โหลดเสร็จ
        ApplyAntiLagToObject(obj)
    end
end)
table.insert(getgenv().AdminHubConnections, AntiLagConn)

-- [[ WORKSPACE CHILDREN ADDED (จับเมื่อด่านเปลี่ยน) ]]
local MapChangeConn = workspace.ChildAdded:Connect(function(child)
    if getgenv().Settings.Antilag then
        task.wait(0.5) -- รอให้แมพโหลดเสร็จ
        ApplyAntiLag()
        for _, obj in pairs(child:GetDescendants()) do
            ApplyAntiLagToObject(obj)
        end
    end
end)
table.insert(getgenv().AdminHubConnections, MapChangeConn)
local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = SettingsTab
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Size = UDim2.new(1, 0, 0, 45)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "DESTROY UI (ปิดโปร)"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 14
local CC = Instance.new("UICorner"); CC.CornerRadius = UDim.new(0,6); CC.Parent = CloseBtn

SwitchTab("Aimbot")

----------------------------------------------------------------
-- LOGIC FUNCTIONS
----------------------------------------------------------------

local function GetCamera()
    return workspace.CurrentCamera
end

local function CheckWall(targetPart)
    if not getgenv().Settings.WallCheck then return true end
    
    -- Safety check: ถ้า LocalPlayer ไม่มี Character ให้ return true
    if not LocalPlayer.Character then return true end
    
    local Cam = GetCamera()
    local Params = RaycastParams.new()
    Params.FilterDescendantsInstances = {LocalPlayer.Character, Cam}
    Params.FilterType = Enum.RaycastFilterType.Exclude
    Params.IgnoreWater = true
    
    -- Raycast จากกล้องไปหาหัวเป้าหมาย
    local Direction = targetPart.Position - Cam.CFrame.Position
    local Result = workspace:Raycast(Cam.CFrame.Position, Direction, Params)
    
    if Result then
        -- ถ้าชนอะไรสักอย่างที่ 'ไม่ใช่' ตัวละครเป้าหมาย = มีกำแพงบัง
        if Result.Instance:IsDescendantOf(targetPart.Parent) then return true end -- ชนเป้าหมาย = มองเห็น
        if Result.Instance.Transparency > 0.5 or Result.Instance.CanCollide == false then return true end -- กระจก/ทะลุได้ = มองเห็น
        return false -- ติดกำแพง
    end
    return true
end

----------------------------------------------------------------
-- MAIN LOOPS
----------------------------------------------------------------

-- [[ AIMBOT LOOP ]]
local AimbotConnection = RunService.RenderStepped:Connect(function()
    if not getgenv().Settings.Running then return end
    
    -- ครอบ pcall เพื่อป้องกัน error ทำให้ script หยุดทำงาน
    local success, err = pcall(function()
        FOVCircle.Visible = getgenv().Settings.ShowFOV
        FOVCircle.Size = UDim2.new(0, getgenv().Settings.FOVSize * 2, 0, getgenv().Settings.FOVSize * 2)

        if getgenv().Settings.Aimbot then
            local Cam = GetCamera()
            if not Cam then return end
            
            local BestTarget = nil
            local MinDist = getgenv().Settings.FOVSize
            local ScreenCenter = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y / 2)
            
            for _, plr in pairs(Players:GetPlayers()) do
                -- เพิ่มการเช็ค HumanoidRootPart เพื่อความชัวร์
                if plr ~= LocalPlayer and plr.Character then
                    local char = plr.Character
                    local head = char:FindFirstChild("Head")
                    local humanoid = char:FindFirstChild("Humanoid")
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    
                    if head and humanoid and hrp and humanoid.Health > 0 then
                        if getgenv().Settings.TeamCheck and plr.Team == LocalPlayer.Team then continue end
                        
                        local Pos, OnScreen = Cam:WorldToViewportPoint(head.Position)
                        
                        if OnScreen then
                            local Dist = (ScreenCenter - Vector2.new(Pos.X, Pos.Y)).Magnitude
                            if Dist < MinDist and CheckWall(head) then
                                MinDist = Dist
                                BestTarget = head
                            end
                        end
                    end
                end
            end
            
            if BestTarget then
                local CurrentCF = Cam.CFrame
                local TargetCF = CFrame.new(CurrentCF.Position, BestTarget.Position)
                -- เล็งไปที่เป้าหมายด้วยความลื่นไหล
                Cam.CFrame = CurrentCF:Lerp(TargetCF, getgenv().Settings.Smoothness)
            end
        end
    end)
    
    if not success then
        warn("[AdminHub] Aimbot Error: " .. tostring(err))
    end
end)
table.insert(getgenv().AdminHubConnections, AimbotConnection)

-- [[ NO RELOAD LOOP - UNIVERSAL VERSION ]]
task.spawn(function()
    while getgenv().Settings.Running and task.wait(0.05) do
        if getgenv().Settings.NoReload then
            pcall(function()
                local char = LocalPlayer.Character
                if not char then return end
                
                -- หา Tool ที่ถืออยู่
                for _, tool in pairs(char:GetChildren()) do
                    if tool:IsA("Tool") then
                        -- วิธีที่ 1: หา Ammo/Magazine values (IntValue/NumberValue)
                        for _, desc in pairs(tool:GetDescendants()) do
                            if desc:IsA("IntValue") or desc:IsA("NumberValue") then
                                local name = desc.Name:lower()
                                if name:find("ammo") or name:find("mag") or name:find("clip") or name:find("bullet") or name:find("round") or name:find("current") or name:find("load") then
                                    if desc.Value < 999 then
                                        desc.Value = 999
                                    end
                                end
                            end
                        end
                        
                        -- วิธีที่ 2: หา Configuration
                        local config = tool:FindFirstChild("Configuration") or tool:FindFirstChild("Config") or tool:FindFirstChild("Settings") or tool:FindFirstChild("GunStats") or tool:FindFirstChild("Stats")
                        if config then
                            for _, v in pairs(config:GetDescendants()) do
                                if v:IsA("IntValue") or v:IsA("NumberValue") then
                                    local name = v.Name:lower()
                                    if name:find("ammo") or name:find("mag") or name:find("clip") or name:find("current") then
                                        if v.Value < 999 then
                                            v.Value = 999
                                        end
                                    end
                                end
                            end
                        end
                        
                        -- วิธีที่ 3: Attributes (เกมใหม่ๆ ใช้)
                        pcall(function()
                            local attrs = tool:GetAttributes()
                            for attrName, attrValue in pairs(attrs) do
                                local nameLower = attrName:lower()
                                if (nameLower:find("ammo") or nameLower:find("mag") or nameLower:find("clip") or nameLower:find("bullet") or nameLower:find("current")) then
                                    if type(attrValue) == "number" and attrValue < 999 then
                                        tool:SetAttribute(attrName, 999)
                                    end
                                end
                            end
                            -- Check descendants attributes too
                            for _, desc in pairs(tool:GetDescendants()) do
                                local descAttrs = desc:GetAttributes()
                                for attrName, attrValue in pairs(descAttrs) do
                                    local nameLower = attrName:lower()
                                    if (nameLower:find("ammo") or nameLower:find("mag") or nameLower:find("clip") or nameLower:find("bullet")) then
                                        if type(attrValue) == "number" and attrValue < 999 then
                                            desc:SetAttribute(attrName, 999)
                                        end
                                    end
                                end
                            end
                        end)
                        
                        -- วิธีที่ 4: Block reload animation
                        pcall(function()
                            local humanoid = char:FindFirstChildOfClass("Humanoid")
                            if humanoid then
                                for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                                    local animName = track.Name:lower()
                                    if animName:find("reload") or animName:find("load") then
                                        track:Stop()
                                        track:AdjustSpeed(9999) -- Skip animation instantly
                                    end
                                end
                            end
                            -- Check Animator too
                            local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
                            if animator then
                                for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                                    local animName = track.Name:lower()
                                    if animName:find("reload") or animName:find("load") then
                                        track:Stop()
                                        track:AdjustSpeed(9999)
                                    end
                                end
                            end
                        end)
                    end
                end
                
                -- วิธีที่ 5: หาใน PlayerGui (บาง game เก็บ ammo ใน GUI)
                local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
                if playerGui then
                    for _, gui in pairs(playerGui:GetDescendants()) do
                        if (gui:IsA("IntValue") or gui:IsA("NumberValue")) then
                            local name = gui.Name:lower()
                            if name:find("ammo") or name:find("mag") or name:find("clip") or name:find("current") then
                                if gui.Value < 999 then
                                    gui.Value = 999
                                end
                            end
                        end
                    end
                end
                
                -- วิธีที่ 6: หาใน Backpack (ปืนอื่นๆ ที่ยังไม่ได้ถือ)
                local backpack = LocalPlayer:FindFirstChild("Backpack")
                if backpack then
                    for _, tool in pairs(backpack:GetChildren()) do
                        if tool:IsA("Tool") then
                            for _, desc in pairs(tool:GetDescendants()) do
                                if desc:IsA("IntValue") or desc:IsA("NumberValue") then
                                    local name = desc.Name:lower()
                                    if name:find("ammo") or name:find("mag") or name:find("clip") or name:find("bullet") or name:find("round") then
                                        if desc.Value < 999 then
                                            desc.Value = 999
                                        end
                                    end
                                end
                            end
                            -- Attributes for backpack tools
                            pcall(function()
                                local attrs = tool:GetAttributes()
                                for attrName, attrValue in pairs(attrs) do
                                    local nameLower = attrName:lower()
                                    if (nameLower:find("ammo") or nameLower:find("mag") or nameLower:find("clip")) then
                                        if type(attrValue) == "number" and attrValue < 999 then
                                            tool:SetAttribute(attrName, 999)
                                        end
                                    end
                                end
                            end)
                        end
                    end
                end
                
                -- วิธีที่ 7: ReplicatedStorage weapon data (บางเกมเก็บไว้ที่นี่)
                pcall(function()
                    local repStorage = game:GetService("ReplicatedStorage")
                    for _, item in pairs(repStorage:GetDescendants()) do
                        if item:IsA("IntValue") or item:IsA("NumberValue") then
                            local name = item.Name:lower()
                            if name:find("ammo") or name:find("mag") or name:find("clip") then
                                if item.Value < 999 then
                                    item.Value = 999
                                end
                            end
                        end
                    end
                end)
            end)
        end
    end
end)

-- [[ ESP LOOP ]]
task.spawn(function()
    while getgenv().Settings.Running and task.wait(0.5) do
        if getgenv().Settings.ESP then
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
                    
                    -- TEAM CHECK
                    if getgenv().Settings.TeamCheck and plr.Team == LocalPlayer.Team then 
                        if plr.Character:FindFirstChild("DevESP") then plr.Character.DevESP:Destroy() end
                        continue 
                    end
                    
                    -- CREATE ESP
                    if not plr.Character:FindFirstChild("DevESP") then
                        local hl = Instance.new("Highlight")
                        hl.Name = "DevESP"
                        hl.Adornee = plr.Character
                        hl.FillColor = Color3.fromRGB(255, 0, 0)
                        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                        hl.FillTransparency = 0.5
                        hl.OutlineTransparency = 0
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Parent = plr.Character
                    end
                else
                    -- ลบ ESP ถ้าผู้เล่นตายหรือไม่มีตัวละคร
                    if plr.Character and plr.Character:FindFirstChild("DevESP") then
                        plr.Character.DevESP:Destroy()
                    end
                end
            end
        else
            -- ถ้าปิด ESP ในขณะที่ลูปรันอยู่
            for _, plr in pairs(Players:GetPlayers()) do
                if plr.Character and plr.Character:FindFirstChild("DevESP") then
                    plr.Character.DevESP:Destroy()
                end
            end
        end
    end
end)

-- [[ NOCLIP LOOP ]]
local NoClipConnection = RunService.Stepped:Connect(function()
    if not getgenv().Settings.Running then return end
    
    if getgenv().Settings.NoClip then
        pcall(function()
            local char = LocalPlayer.Character
            if not char then return end
            
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    end
end)
table.insert(getgenv().AdminHubConnections, NoClipConnection)

-- [[ INVISIBLE RESPAWN FIX - รักษาสถานะล่องหนหลัง respawn ]]
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if getgenv().Settings.Invisible then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") or part:IsA("MeshPart") then
                part.Transparency = 1
            elseif part:IsA("Decal") or part:IsA("Texture") then
                part.Transparency = 1
            end
        end
        for _, acc in pairs(char:GetChildren()) do
            if acc:IsA("Accessory") then
                local handle = acc:FindFirstChild("Handle")
                if handle then handle.Transparency = 1 end
            end
        end
        local head = char:FindFirstChild("Head")
        if head then
            local face = head:FindFirstChild("face") or head:FindFirstChild("Face")
            if face then face.Transparency = 1 end
        end
    end
end)

-- [[ AUTO FIRE LOOP - ยิงอัตโนมัติแบบมี Cooldown + Wall Check ]]
local LastAutoFireTime = 0
local AutoFireCooldown = 0.15 -- ยิงได้ทุก 0.15 วินาที (ป้องกันยิงมั่ว)

task.spawn(function()
    while getgenv().Settings.Running and task.wait(0.05) do
        if getgenv().Settings.AutoFire and getgenv().Settings.Aimbot then
            pcall(function()
                local Cam = workspace.CurrentCamera
                if not Cam then return end
                
                local currentTime = tick()
                
                -- เช็ค Cooldown ก่อนยิง
                if currentTime - LastAutoFireTime < AutoFireCooldown then return end
                
                -- หาเป้าหมายที่ใกล้ที่สุดใน FOV
                local BestTarget = nil
                local MinDist = getgenv().Settings.FOVSize
                local ScreenCenter = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y / 2)
                
                for _, plr in pairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character then
                        local char = plr.Character
                        local head = char:FindFirstChild("Head")
                        local humanoid = char:FindFirstChild("Humanoid")
                        
                        if head and humanoid and humanoid.Health > 0 then
                            -- Team Check
                            if getgenv().Settings.TeamCheck and plr.Team == LocalPlayer.Team then continue end
                            
                            local Pos, OnScreen = Cam:WorldToViewportPoint(head.Position)
                            
                            if OnScreen then
                                local Dist = (ScreenCenter - Vector2.new(Pos.X, Pos.Y)).Magnitude
                                
                                -- Wall Check - เช็คว่าเห็นเป้าหมายจริงหรือไม่ (ไม่ตดกำแพง)
                                if Dist < MinDist then
                                    if getgenv().Settings.WallCheck then
                                        if CheckWall(head) then
                                            MinDist = Dist
                                            BestTarget = head
                                        end
                                    else
                                        MinDist = Dist
                                        BestTarget = head
                                    end
                                end
                            end
                        end
                    end
                end
                
                -- ยิงถ้ามีเป้าหมายและผ่าน Wall Check
                if BestTarget then
                    local mouse = LocalPlayer:GetMouse()
                    if mouse then
                        local vim = game:GetService("VirtualInputManager")
                        vim:SendMouseButtonEvent(mouse.X, mouse.Y, 0, true, game, 1)
                        task.wait(0.02)
                        vim:SendMouseButtonEvent(mouse.X, mouse.Y, 0, false, game, 1)
                        LastAutoFireTime = currentTime
                    end
                end
            end)
        end
    end
end)

print("[AdminHub] Auto Fire with Cooldown + Wall Check Loaded!")

-- [[ CLEANUP ON LEAVE ]]
local RemoveConn = Players.PlayerRemoving:Connect(function(plr)
    if plr.Character and plr.Character:FindFirstChild("DevESP") then
        plr.Character.DevESP:Destroy()
    end
    -- ล้าง ESP Box ด้วย
    if getgenv().ESPBoxStorage[plr.Name] then
        local data = getgenv().ESPBoxStorage[plr.Name]
        if data.Box then data.Box:Remove() end
        if data.Name then data.Name:Remove() end
        if data.Health then data.Health:Remove() end
        if data.HealthBG then data.HealthBG:Remove() end
        getgenv().ESPBoxStorage[plr.Name] = nil
    end
end)
table.insert(getgenv().AdminHubConnections, RemoveConn)

-- [[ ESP BOX LOOP (Drawing API) ]]
if HasDrawing then
    local ESPBoxConnection = RunService.RenderStepped:Connect(function()
        if not getgenv().Settings.Running then return end
        
        local Cam = workspace.CurrentCamera
        if not Cam then return end
    
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = plr.Character
            local data = getgenv().ESPBoxStorage[plr.Name]
            
            -- สร้าง ESP Box storage ถ้ายังไม่มี
            if not data then
                data = {}
                
                data.Box = Drawing.new("Square")
                data.Box.Thickness = 1
                data.Box.Filled = false
                data.Box.Color = Color3.fromRGB(255, 0, 0)
                data.Box.Visible = false
                
                data.Name = Drawing.new("Text")
                data.Name.Size = 14
                data.Name.Center = true
                data.Name.Outline = true
                data.Name.Color = Color3.fromRGB(255, 255, 255)
                data.Name.Visible = false
                
                data.HealthBG = Drawing.new("Square")
                data.HealthBG.Thickness = 1
                data.HealthBG.Filled = true
                data.HealthBG.Color = Color3.fromRGB(0, 0, 0)
                data.HealthBG.Visible = false
                
                data.Health = Drawing.new("Square")
                data.Health.Thickness = 1
                data.Health.Filled = true
                data.Health.Color = Color3.fromRGB(0, 255, 0)
                data.Health.Visible = false
                
                getgenv().ESPBoxStorage[plr.Name] = data
            end
            
            -- ช่อน/แสดง ESP Box
            if getgenv().Settings.ESPBox and char then
                local humanoid = char:FindFirstChild("Humanoid")
                local hrp = char:FindFirstChild("HumanoidRootPart")
                
                if humanoid and hrp and humanoid.Health > 0 then
                    -- Team Check
                    if getgenv().Settings.TeamCheck and plr.Team == LocalPlayer.Team then
                        data.Box.Visible = false
                        data.Name.Visible = false
                        data.Health.Visible = false
                        data.HealthBG.Visible = false
                        continue
                    end
                    
                    local pos, onScreen = Cam:WorldToViewportPoint(hrp.Position)
                    
                    if onScreen then
                        -- คำนวณขนาด Box ตามระยะห่าง
                        local scaleFactor = 1 / (pos.Z * math.tan(math.rad(Cam.FieldOfView / 2)) * 2) * 1000
                        local boxWidth = math.clamp(scaleFactor * 4, 10, 100)
                        local boxHeight = math.clamp(scaleFactor * 5.5, 15, 150)
                        
                        -- Box (ใช้สีจาก Settings)
                        local boxColor = getgenv().Settings.ESPBoxColor
                        data.Box.Color = Color3.fromRGB(boxColor.R, boxColor.G, boxColor.B)
                        data.Box.Size = Vector2.new(boxWidth, boxHeight)
                        data.Box.Position = Vector2.new(pos.X - boxWidth / 2, pos.Y - boxHeight / 2)
                        data.Box.Visible = true
                        
                        -- Name (เช็ค Show Name setting)
                        if getgenv().Settings.ESPShowName then
                            data.Name.Text = plr.Name
                            data.Name.Position = Vector2.new(pos.X, pos.Y - boxHeight / 2 - 18)
                            data.Name.Visible = true
                        else
                            data.Name.Visible = false
                        end
                        
                        -- Health Bar (เช็ค Show Health setting)
                        if getgenv().Settings.ESPShowHealth then
                            local healthPercent = humanoid.Health / humanoid.MaxHealth
                            local healthHeight = boxHeight * healthPercent
                            
                            data.HealthBG.Size = Vector2.new(3, boxHeight)
                            data.HealthBG.Position = Vector2.new(pos.X - boxWidth / 2 - 6, pos.Y - boxHeight / 2)
                            data.HealthBG.Visible = true
                            
                            data.Health.Size = Vector2.new(3, healthHeight)
                            data.Health.Position = Vector2.new(pos.X - boxWidth / 2 - 6, pos.Y - boxHeight / 2 + (boxHeight - healthHeight))
                            data.Health.Color = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
                            data.Health.Visible = true
                        else
                            data.Health.Visible = false
                            data.HealthBG.Visible = false
                        end
                    else
                        data.Box.Visible = false
                        data.Name.Visible = false
                        data.Health.Visible = false
                        data.HealthBG.Visible = false
                    end
                else
                    data.Box.Visible = false
                    data.Name.Visible = false
                    data.Health.Visible = false
                    data.HealthBG.Visible = false
                end
            else
                data.Box.Visible = false
                data.Name.Visible = false
                data.Health.Visible = false
                data.HealthBG.Visible = false
            end
        end
    end
end)
    table.insert(getgenv().AdminHubConnections, ESPBoxConnection)
end -- End HasDrawing check

-- [[ MINIMIZE BUTTON ]]
local MiniBtn = Instance.new("ImageButton")
MiniBtn.Name = "ToggleUI"
MiniBtn.Parent = ScreenGui
MiniBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MiniBtn.Position = UDim2.new(0, 50, 0.4, 0)
MiniBtn.Size = UDim2.new(0, 45, 0, 45)
MiniBtn.Active = true
MiniBtn.Draggable = true
MiniBtn.ZIndex = 10
local MB_Corner = Instance.new("UICorner"); MB_Corner.CornerRadius = UDim.new(1,0); MB_Corner.Parent = MiniBtn
local MB_Stroke = Instance.new("UIStroke"); MB_Stroke.Parent = MiniBtn; MB_Stroke.Color = Color3.fromRGB(0,150,255); MB_Stroke.Thickness = 2
local MB_Icon = Instance.new("ImageLabel"); MB_Icon.Parent = MiniBtn; MB_Icon.BackgroundTransparency = 1
MB_Icon.Size = UDim2.new(0.6,0,0.6,0); MB_Icon.Position = UDim2.new(0.2,0,0.2,0)
MB_Icon.Image = "rbxassetid://3926305904"; MB_Icon.ImageColor3 = Color3.fromRGB(255,255,255); MB_Icon.ZIndex = 11
MB_Icon.ImageRectOffset = Vector2.new(764, 244); MB_Icon.ImageRectSize = Vector2.new(36, 36) -- Crosshair icon

MiniBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

----------------------------------------------------------------
-- KEYBIND TOGGLE (กดปุ่มเปิด/ปิด Menu)
----------------------------------------------------------------
local ToggleKey = Enum.KeyCode.RightShift -- กด Right Shift เพื่อเปิด/ปิด

local KeybindConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == ToggleKey then
        MainFrame.Visible = not MainFrame.Visible
        MiniBtn.Visible = not MiniBtn.Visible -- ซ่อนปุ่มด้วย
    end
end)
table.insert(getgenv().AdminHubConnections, KeybindConn)

print("[AdminHub] Press RIGHT SHIFT to toggle menu")

----------------------------------------------------------------
-- DESTROY FUNCTION
----------------------------------------------------------------
CloseBtn.MouseButton1Click:Connect(function()
    getgenv().Settings.Running = false -- หยุด Loop ทั้งหมด
    ScreenGui:Destroy()
    
    -- ตัดการเชื่อมต่อ Events
    for _, conn in pairs(getgenv().AdminHubConnections) do
        if conn then conn:Disconnect() end
    end
    getgenv().AdminHubConnections = {}
    
    -- ล้าง ESP Highlight ทั้งหมด
    for _, plr in pairs(Players:GetPlayers()) do
        if plr.Character and plr.Character:FindFirstChild("DevESP") then
            plr.Character.DevESP:Destroy()
        end
    end
    
    -- ล้าง ESP Box ทั้งหมด
    if getgenv().ESPBoxStorage then
        for _, data in pairs(getgenv().ESPBoxStorage) do
            if data.Box then data.Box:Remove() end
            if data.Name then data.Name:Remove() end
            if data.Health then data.Health:Remove() end
            if data.HealthBG then data.HealthBG:Remove() end
        end
        getgenv().ESPBoxStorage = {}
    end
end)
