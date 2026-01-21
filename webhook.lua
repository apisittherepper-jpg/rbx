-- [[ SECRET FISH SCANNER - V21 ANTI-DUPLICATE ]]
-- แก้ปัญหา Webhook ส่งซ้ำด้วยระบบ Cache ID
-- UI: V19 Style (Obsidian + Dropdown)

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Request = http_request or request or HttpPost or syn.request

local SettingsFile = "secret_v21.txt"
local Webhook_URL = ""
local Cooldown = 3

-- [[ 🚫 ระบบกันซ้ำ (Anti-Duplicate Cache) ]]
local SentCache = {} -- ตารางเก็บประวัติการส่ง

-- [[ 🎨 ตารางสี ]] 
local ColorOptions = {
    {Name = "🧪 MODE TEST ALL FISH", RGB = "ALL", Hex = 16777215, LabelColor = Color3.fromRGB(255, 255, 255)}, 
    {Name = "Secret", RGB = "rgb(24, 255, 152)", Hex = 16758827, LabelColor = Color3.fromRGB(24, 255, 152)},
    {Name = "Mythical",       RGB = "rgb(210, 40, 40)",    Hex = 13739048, LabelColor = Color3.fromRGB(210, 40, 40)},
    {Name = "Legendary",      RGB = "rgb(255, 170, 0)",    Hex = 16755200, LabelColor = Color3.fromRGB(255, 170, 0)},
    {Name = "Epic", RGB = "rgb(170, 85, 255)",   Hex = 11163135, LabelColor = Color3.fromRGB(170, 85, 255)}
}

local CurrentTarget = ColorOptions[2] -- Default: Secret
local MonitorEnabled = false
local LastPlayerList = {}

-- [[ GUI Setup ]]
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local UIStroke = Instance.new("UIStroke")
local TitleLabel = Instance.new("TextLabel")
local CloseBtn = Instance.new("TextButton")
local WebhookInput = Instance.new("TextBox")
local SaveBtn = Instance.new("TextButton")
local TestBtn = Instance.new("TextButton")
local MonitorBtn = Instance.new("TextButton")
local StatusLabel = Instance.new("TextLabel")
local ToggleBtn = Instance.new("TextButton")

local DropdownBtn = Instance.new("TextButton")
local DropdownFrame = Instance.new("ScrollingFrame")
local DropdownStroke = Instance.new("UIStroke")

pcall(function()
    if gethui then ScreenGui.Parent = gethui()
    elseif syn and syn.protect_gui then syn.protect_gui(ScreenGui) ScreenGui.Parent = CoreGui
    else ScreenGui.Parent = CoreGui end
end)

MainFrame.Name = "AntiDupFishUI"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.Position = UDim2.new(0.5, -120, 0.5, -145)
MainFrame.Size = UDim2.new(0, 240, 0, 290)
MainFrame.Active = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

UIStroke.Parent = MainFrame
UIStroke.Thickness = 2.5
UIStroke.Transparency = 0
UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

TitleLabel.Parent = MainFrame
TitleLabel.BackgroundTransparency = 1
TitleLabel.Position = UDim2.new(0, 15, 0, 10)
TitleLabel.Size = UDim2.new(1, -50, 0, 20)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "Fix"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 14
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

CloseBtn.Parent = MainFrame
CloseBtn.BackgroundTransparency = 1
CloseBtn.Position = UDim2.new(1, -30, 0, 5)
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Font = Enum.Font.GothamMedium
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
CloseBtn.TextSize = 14

WebhookInput.Parent = MainFrame
WebhookInput.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
WebhookInput.Position = UDim2.new(0, 15, 0, 40)
WebhookInput.Size = UDim2.new(1, -30, 0, 30)
WebhookInput.Font = Enum.Font.Gotham
WebhookInput.PlaceholderText = "Webhook URL"
WebhookInput.PlaceholderColor3 = Color3.fromRGB(80, 80, 80)
WebhookInput.Text = ""
WebhookInput.TextColor3 = Color3.fromRGB(24, 255, 152)
WebhookInput.TextSize = 11
WebhookInput.ClipsDescendants = true
Instance.new("UICorner", WebhookInput).CornerRadius = UDim.new(0, 6)

DropdownBtn.Parent = MainFrame
DropdownBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
DropdownBtn.Position = UDim2.new(0, 15, 0, 80)
DropdownBtn.Size = UDim2.new(1, -30, 0, 30)
DropdownBtn.Font = Enum.Font.GothamBold
DropdownBtn.Text = "Target: " .. CurrentTarget.Name .. " ▼"
DropdownBtn.TextColor3 = CurrentTarget.LabelColor
DropdownBtn.TextSize = 11
Instance.new("UICorner", DropdownBtn).CornerRadius = UDim.new(0, 6)

DropdownFrame.Parent = MainFrame
DropdownFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
DropdownFrame.Position = UDim2.new(0, 15, 0, 115)
DropdownFrame.Size = UDim2.new(1, -30, 0, 120)
DropdownFrame.Visible = false
DropdownFrame.ZIndex = 10
DropdownFrame.ScrollBarThickness = 4
DropdownFrame.BorderSizePixel = 0
Instance.new("UICorner", DropdownFrame).CornerRadius = UDim.new(0, 6)

DropdownStroke.Parent = DropdownFrame
DropdownStroke.Thickness = 1
DropdownStroke.Color = Color3.fromRGB(60, 60, 60)

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = DropdownFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

for i, colorData in ipairs(ColorOptions) do
    local OptionBtn = Instance.new("TextButton")
    OptionBtn.Parent = DropdownFrame
    OptionBtn.Size = UDim2.new(1, 0, 0, 30)
    OptionBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    OptionBtn.BackgroundTransparency = 1
    OptionBtn.Font = Enum.Font.Gotham
    OptionBtn.Text = "  " .. colorData.Name
    OptionBtn.TextColor3 = colorData.LabelColor
    OptionBtn.TextSize = 11
    OptionBtn.TextXAlignment = Enum.TextXAlignment.Left
    OptionBtn.ZIndex = 11
    OptionBtn.MouseButton1Click:Connect(function()
        CurrentTarget = colorData
        DropdownBtn.Text = "Target: " .. colorData.Name .. " ▼"
        DropdownBtn.TextColor3 = colorData.LabelColor
        DropdownFrame.Visible = false
    end)
end

SaveBtn.Parent = MainFrame
SaveBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
SaveBtn.Position = UDim2.new(0, 15, 0, 120)
SaveBtn.Size = UDim2.new(1, -30, 0, 30)
SaveBtn.Font = Enum.Font.GothamBold
SaveBtn.Text = " SAVE "
SaveBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
SaveBtn.TextSize = 11
Instance.new("UICorner", SaveBtn).CornerRadius = UDim.new(0, 6)

TestBtn.Parent = MainFrame
TestBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
TestBtn.Position = UDim2.new(0, 15, 0, 160)
TestBtn.Size = UDim2.new(1, -30, 0, 30)
TestBtn.Font = Enum.Font.GothamBold
TestBtn.Text = " TEST CONNECTION"
TestBtn.TextColor3 = Color3.fromRGB(255, 200, 0)
TestBtn.TextSize = 11
Instance.new("UICorner", TestBtn).CornerRadius = UDim.new(0, 6)

MonitorBtn.Parent = MainFrame
MonitorBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MonitorBtn.Position = UDim2.new(0, 15, 0, 200)
MonitorBtn.Size = UDim2.new(1, -30, 0, 30)
MonitorBtn.Font = Enum.Font.GothamBold
MonitorBtn.Text = "Player Check: OFF"
MonitorBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
MonitorBtn.TextSize = 11
Instance.new("UICorner", MonitorBtn).CornerRadius = UDim.new(0, 6)

StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 15, 0, 240)
StatusLabel.Size = UDim2.new(1, -30, 0, 40)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Text = "Ready to scan"
StatusLabel.TextColor3 = Color3.fromRGB(80, 80, 80)
StatusLabel.TextSize = 10
StatusLabel.TextXAlignment = Enum.TextXAlignment.Center

ToggleBtn.Parent = ScreenGui
ToggleBtn.BackgroundTransparency = 1
ToggleBtn.Position = UDim2.new(0.1, 0, 0.8, 0)
ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Text = "❌"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize = 40

-- Logic & RGB
task.spawn(function()
    while true do
        local t = tick()
        local hue = (t * 0.5) % 1
        UIStroke.Color = Color3.fromHSV(hue, 1, 1)
        task.wait()
    end
end)

local function MakeDraggable(guiObject)
    local dragging, dragInput, dragStart, startPos
    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = guiObject.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    guiObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            guiObject.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end
MakeDraggable(MainFrame); MakeDraggable(ToggleBtn)

local function AnimateBtn(btn)
    if btn.BackgroundTransparency ~= 1 then
        local oldColor = btn.BackgroundColor3
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60); wait(0.1); btn.BackgroundColor3 = oldColor
    end
end

DropdownBtn.MouseButton1Click:Connect(function()
    AnimateBtn(DropdownBtn)
    DropdownFrame.Visible = not DropdownFrame.Visible
end)

local function SaveConfig()
    AnimateBtn(SaveBtn)
    local url = WebhookInput.Text
    if url and url ~= "" then
        url = string.gsub(url, "%s+", "")
        Webhook_URL = url
        if writefile then writefile(SettingsFile, url); StatusLabel.Text = "Config Saved" end
    end
end

local function LoadConfig()
    if isfile and isfile(SettingsFile) then
        local content = readfile(SettingsFile)
        if content and content ~= "" then Webhook_URL = content; WebhookInput.Text = "Loaded (Hidden)" end
    end
end

local function SmartSend(payload, targetUrl)
    spawn(function()
        local jitter = math.random(50, 250) / 100
        task.wait(jitter)
        pcall(function() Request({Url=targetUrl, Method="POST", Headers={["content-type"]="application/json"}, Body=HttpService:JSONEncode(payload)}) end)
    end)
end

-- Monitor
task.spawn(function()
    while true do
        if MonitorEnabled then
            local CurrentList = {}
            local CurrentSet = {}
            for _, p in pairs(Players:GetPlayers()) do table.insert(CurrentList, p.Name); CurrentSet[p.Name] = true end
            if #LastPlayerList > 0 then
                for _, name in pairs(LastPlayerList) do
                    if not CurrentSet[name] and Webhook_URL ~= "" then
                        local payload = {["embeds"]={{["title"]="❌ DISCONNECTED",["description"]="**"..name.."** left.",["color"]=16711680,["footer"]={["text"]=os.date("%X")}}}}
                        SmartSend(payload, Webhook_URL)
                    end
                end
            end
            LastPlayerList = CurrentList
        end
        task.wait(30)
    end
end)

MonitorBtn.MouseButton1Click:Connect(function()
    AnimateBtn(MonitorBtn)
    MonitorEnabled = not MonitorEnabled
    if MonitorEnabled then
        MonitorBtn.Text = "Player Check: ON"
        MonitorBtn.TextColor3 = Color3.fromRGB(80, 255, 80)
        LastPlayerList = {}
        for _, p in pairs(Players:GetPlayers()) do table.insert(LastPlayerList, p.Name) end
    else
        MonitorBtn.Text = "Player Check: OFF"
        MonitorBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    end
end)

local ItemsFolder = ReplicatedStorage:WaitForChild("Items")
local FishDB = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ModelDownloader"):WaitForChild("Collection"):WaitForChild("Fish")

local function GetFishImage(fishName)
    local imageId = ""
    pcall(function()
        local targetModule = ItemsFolder:FindFirstChild(fishName)
        if targetModule and targetModule:IsA("ModuleScript") then
            local moduleData = require(targetModule)
            if moduleData and moduleData.Data and moduleData.Data.Icon then imageId = moduleData.Data.Icon end
        end
    end)
    if imageId == "" then
        local fishData = FishDB:FindFirstChild(fishName)
        if fishData then
            if fishData:FindFirstChild("Image") then imageId = fishData.Image.Value end
            if fishData:FindFirstChild("Texture") then imageId = fishData.Texture.Value end
            if imageId == "" and fishData:IsA("MeshPart") then imageId = fishData.TextureID end
        end
    end
    if imageId ~= "" then
        local idNumber = string.match(imageId, "%d+")
        if idNumber then return "https://www.roblox.com/asset-thumbnail/image?assetId="..idNumber.."&width=420&height=420&format=png" end
    end
    return "https://tr.rbxcdn.com/565d787095594e0941551064299b844b/420/420/Image/Png"
end

TestBtn.MouseButton1Click:Connect(function()
    AnimateBtn(TestBtn)
    local url = WebhookInput.Text ~= "" and WebhookInput.Text or Webhook_URL
    if url == "" then StatusLabel.Text = "No URL" return end
    SmartSend({["embeds"]={{["title"]="🔔 CONNECTED",["color"]=65280}}}, url)
    StatusLabel.Text = "Test Sent"
end)

local function Analyze(msg)
    if CurrentTarget.RGB ~= "ALL" and not string.find(msg, CurrentTarget.RGB, 1, true) then return end
    
    local clean = string.gsub(msg, "<.->", "")
    if string.find(clean, "%[Global%]:") then return end
    if not string.find(clean, "%[Server%]:") then return end

    local p, f, w = string.match(clean, ":%s*(.-)%s+obtained an?%s+(.-)%s+%((.-)%)")
    if p and f then
        -- 🔥 Anti-Duplicate Logic 🔥
        -- สร้าง Key: ชื่อคน|ชื่อปลา|น้ำหนัก
        local duplicateKey = p .. "|" .. f .. "|" .. w
        
        -- ถ้าเคยส่ง Key นี้ไปแล้วภายใน 10 วินาที ให้หยุด (return)
        if SentCache[duplicateKey] and (os.time() - SentCache[duplicateKey] < 10) then
            print("🚫 Duplicate skipped: " .. f)
            return 
        end
        
        -- ถ้าไม่ซ้ำ ให้บันทึกเวลาล่าสุด
        SentCache[duplicateKey] = os.time()

        local uid = 1
        pcall(function() if Players:FindFirstChild(p) then uid = Players[p].UserId end end)
        
        local img = GetFishImage(f)
        local payload = {
            ["embeds"] = {{
                ["title"] = "🌟 " .. CurrentTarget.Name .. " CATCH! 🌟",
                ["color"] = CurrentTarget.Hex,
                ["fields"] = {
                    {["name"]="Player", ["value"]="`"..p.."`", ["inline"]=true},
                    {["name"]="Weight", ["value"]="`"..w.."`", ["inline"]=true},
                    {["name"]="Fish", ["value"]="#"..f, ["inline"]=false}
                },
                ["image"] = {["url"]=img},
                ["thumbnail"] = {["url"]="https://www.roblox.com/headshot-thumbnail/image?userId="..uid.."&width=420&height=420&format=png"},
                ["footer"] = {["text"]=os.date("%X")}
            }}
        }
        SmartSend(payload, Webhook_URL)
    end
end

SaveBtn.MouseButton1Click:Connect(SaveConfig)
ToggleBtn.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)
CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false end)
LoadConfig()

TextChatService.MessageReceived:Connect(function(data) Analyze(data.Text) end)
if ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents") then
    ReplicatedStorage.DefaultChatSystemChatEvents.OnMessageDoneFiltering.OnClientEvent:Connect(function(data) Analyze(data.Message) end)
end
