-- [[ SECRET FISH SCANNER - V15 RGB SPLIT ]]
-- ปุ่ม Save/Test แยกบรรทัด (ไม่ทับกัน) + กรอบ RGB

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Request = http_request or request or HttpPost or syn.request

local SettingsFile = "secret_v15.txt"
local Webhook_URL = ""
local LastMessage = ""
local LastTime = 0
local Cooldown = 3
local TargetRGB = "rgb(24, 255, 152)"

local MonitorEnabled = false
local LastPlayerList = {}

-- [[ 1. สร้าง GUI ]]
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local UIStroke = Instance.new("UIStroke") -- เส้นขอบ RGB
local TitleLabel = Instance.new("TextLabel")
local CloseBtn = Instance.new("TextButton")
local WebhookInput = Instance.new("TextBox")
local SaveBtn = Instance.new("TextButton")
local TestBtn = Instance.new("TextButton")
local MonitorBtn = Instance.new("TextButton")
local StatusLabel = Instance.new("TextLabel")
local ToggleBtn = Instance.new("TextButton")

pcall(function()
    if gethui then ScreenGui.Parent = gethui()
    elseif syn and syn.protect_gui then syn.protect_gui(ScreenGui) ScreenGui.Parent = CoreGui
    else ScreenGui.Parent = CoreGui end
end)

-- Main Frame (ขยายความสูงเป็น 250 เพื่อแยกปุ่ม)
MainFrame.Name = "RGBSplitUI"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.Position = UDim2.new(0.5, -120, 0.5, -125)
MainFrame.Size = UDim2.new(0, 240, 0, 250) -- สูงขึ้น
MainFrame.Active = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

-- 🌈 RGB Border 🌈
UIStroke.Parent = MainFrame
UIStroke.Thickness = 2.5
UIStroke.Transparency = 0
UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

-- หัวข้อ
TitleLabel.Parent = MainFrame
TitleLabel.BackgroundTransparency = 1
TitleLabel.Position = UDim2.new(0, 15, 0, 10)
TitleLabel.Size = UDim2.new(1, -50, 0, 20)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "Webhook by @maxqi_i"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 14
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

-- ปุ่มปิด X
CloseBtn.Parent = MainFrame
CloseBtn.BackgroundTransparency = 1
CloseBtn.Position = UDim2.new(1, -30, 0, 5)
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Font = Enum.Font.GothamMedium
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
CloseBtn.TextSize = 14

-- ช่อง Input
WebhookInput.Parent = MainFrame
WebhookInput.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
WebhookInput.Position = UDim2.new(0, 15, 0, 40)
WebhookInput.Size = UDim2.new(1, -30, 0, 30)
WebhookInput.Font = Enum.Font.Gotham
WebhookInput.PlaceholderText = "Webhook URL"
WebhookInput.PlaceholderColor3 = Color3.fromRGB(80, 80, 80)
WebhookInput.Text = ""
WebhookInput.TextColor3 = Color3.fromRGB(210, 210, 210)
WebhookInput.TextSize = 11
WebhookInput.ClipsDescendants = true
Instance.new("UICorner", WebhookInput).CornerRadius = UDim.new(0, 6)

-- [[ แยกปุ่มเป็นคนละบรรทัด ]]

-- บรรทัด 1: SAVE
SaveBtn.Parent = MainFrame
SaveBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
SaveBtn.Position = UDim2.new(0, 15, 0, 80)
SaveBtn.Size = UDim2.new(1, -30, 0, 30) -- เต็มความกว้าง
SaveBtn.Font = Enum.Font.GothamBold
SaveBtn.Text = "SAVE"
SaveBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
SaveBtn.TextSize = 11
Instance.new("UICorner", SaveBtn).CornerRadius = UDim.new(0, 6)

-- บรรทัด 2: TEST (แยกออกมาแล้ว)
TestBtn.Parent = MainFrame
TestBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
TestBtn.Position = UDim2.new(0, 15, 0, 120) -- ขยับลงมา
TestBtn.Size = UDim2.new(1, -30, 0, 30) -- เต็มความกว้าง
TestBtn.Font = Enum.Font.GothamBold
TestBtn.Text = "TEST CONNECTION"
TestBtn.TextColor3 = Color3.fromRGB(255, 200, 0)
TestBtn.TextSize = 11
Instance.new("UICorner", TestBtn).CornerRadius = UDim.new(0, 6)

-- บรรทัด 3: MONITOR
MonitorBtn.Parent = MainFrame
MonitorBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MonitorBtn.Position = UDim2.new(0, 15, 0, 160) -- ขยับลงมา
MonitorBtn.Size = UDim2.new(1, -30, 0, 30) -- เต็มความกว้าง
MonitorBtn.Font = Enum.Font.GothamBold
MonitorBtn.Text = "Player Check: OFF"
MonitorBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
MonitorBtn.TextSize = 11
Instance.new("UICorner", MonitorBtn).CornerRadius = UDim.new(0, 6)

-- Status
StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 15, 0, 200) -- ขยับลงมาท้ายสุด
StatusLabel.Size = UDim2.new(1, -30, 0, 40)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Text = "Ready to scan"
StatusLabel.TextColor3 = Color3.fromRGB(80, 80, 80)
StatusLabel.TextSize = 10
StatusLabel.TextXAlignment = Enum.TextXAlignment.Center

-- Toggle Button (Emoji ❌)
ToggleBtn.Parent = ScreenGui
ToggleBtn.BackgroundTransparency = 1
ToggleBtn.Position = UDim2.new(0.1, 0, 0.8, 0)
ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Text = "❌"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize = 40

-- [[ 2. ระบบ RGB Loop ]]
task.spawn(function()
    while true do
        local t = tick()
        local hue = (t * 0.5) % 1 -- ความเร็วสีรุ้ง
        local color = Color3.fromHSV(hue, 1, 1)
        UIStroke.Color = color -- เปลี่ยนสีขอบ
        task.wait()
    end
end)

-- [[ 3. ระบบลาก ]]
local function MakeDraggable(guiObject)
    local dragging, dragInput, dragStart, startPos
    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = guiObject.Position
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
MakeDraggable(MainFrame)
MakeDraggable(ToggleBtn)

local function AnimateBtn(btn)
    local oldColor = btn.BackgroundColor3
    if btn.BackgroundTransparency == 1 then
        local oldSize = btn.TextSize
        btn.TextSize = oldSize - 5
        wait(0.1)
        btn.TextSize = oldSize
    else
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        wait(0.1)
        btn.BackgroundColor3 = oldColor
    end
end

-- [[ 4. Functions ]]
local function SaveConfig()
    AnimateBtn(SaveBtn)
    local url = WebhookInput.Text
    if url and url ~= "" then
        url = string.gsub(url, "%s+", "")
        Webhook_URL = url
        if writefile then
            writefile(SettingsFile, url)
            StatusLabel.Text = "Config Saved"
            wait(1)
            StatusLabel.Text = "Ready"
        end
    end
end

local function LoadConfig()
    if isfile and isfile(SettingsFile) then
        local content = readfile(SettingsFile)
        if content and content ~= "" then
            Webhook_URL = content
            WebhookInput.Text = "Loaded (Hidden)"
        end
    end
end

task.spawn(function()
    while true do
        if MonitorEnabled then
            local CurrentList = {}
            local CurrentSet = {}
            for _, p in pairs(Players:GetPlayers()) do
                table.insert(CurrentList, p.Name)
                CurrentSet[p.Name] = true
            end
            if #LastPlayerList > 0 then
                for _, name in pairs(LastPlayerList) do
                    if not CurrentSet[name] then
                        if Webhook_URL ~= "" then
                            local payload = {["embeds"]={{["title"]="❌ DISCONNECTED",["description"]="**"..name.."** left.",["color"]=16711680,["footer"]={["text"]=os.date("%X")}}}}
                            Request({Url=Webhook_URL, Method="POST", Headers={["content-type"]="application/json"}, Body=HttpService:JSONEncode(payload)})
                        end
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
        MonitorBtn.Text = "Player Monitor: ON"
        MonitorBtn.TextColor3 = Color3.fromRGB(80, 255, 80)
        LastPlayerList = {}
        for _, p in pairs(Players:GetPlayers()) do table.insert(LastPlayerList, p.Name) end
    else
        MonitorBtn.Text = "Player Monitor: OFF"
        MonitorBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    end
end)

-- Hybrid Image Search
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

local function SendWebhook(data, forceUrl)
    local targetUrl = forceUrl or Webhook_URL
    if targetUrl == "" then return end
    
    local img = GetFishImage(data.Fish)
    local payload = {
        ["embeds"] = {{
            ["title"] = "🌟 SECRET CATCH! 🌟",
            ["color"] = 16758827,
            ["fields"] = {
                {["name"]="Player", ["value"]="`"..data.Player.."`", ["inline"]=true},
                {["name"]="Weight", ["value"]="`"..data.Weight.."`", ["inline"]=true},
                {["name"]="Fish", ["value"]="#"..data.Fish, ["inline"]=false}
            },
            ["image"] = {["url"]=img},
            ["thumbnail"] = {["url"]="https://www.roblox.com/headshot-thumbnail/image?userId="..data.UserId.."&width=420&height=420&format=png"},
            ["footer"] = {["text"]=os.date("%X")}
        }}
    }
    spawn(function() Request({Url=targetUrl, Method="POST", Headers={["content-type"]="application/json"}, Body=HttpService:JSONEncode(payload)}) end)
end

TestBtn.MouseButton1Click:Connect(function()
    AnimateBtn(TestBtn)
    local url = WebhookInput.Text ~= "" and WebhookInput.Text or Webhook_URL
    if url == "" then StatusLabel.Text = "No URL" return end
    spawn(function() Request({Url=url, Method="POST", Headers={["content-type"]="application/json"}, Body=HttpService:JSONEncode({["embeds"]={{["title"]="Connected", ["color"]=65280}}})}) end)
    StatusLabel.Text = "Test Sent"
end)

local function Analyze(msg)
    if msg == LastMessage and (os.time() - LastTime < 5) then return end
    if not string.find(msg, TargetRGB, 1, true) then return end
    local clean = string.gsub(msg, "<.->", "")
    if string.find(clean, "%[Global%]:") then return end
    if not string.find(clean, "%[Server%]:") then return end

    LastMessage = msg
    local p, f, w = string.match(clean, ":%s*(.-)%s+obtained an?%s+(.-)%s+%((.-)%)")
    if p and f then
        if os.time() - LastTime < Cooldown then return end
        LastTime = os.time()
        local uid = 1
        pcall(function() if Players:FindFirstChild(p) then uid = Players[p].UserId end end)
        SendWebhook({Player=p, Fish=f, Weight=w, UserId=uid}, nil)
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
