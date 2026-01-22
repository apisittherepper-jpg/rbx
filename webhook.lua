
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Request = http_request or request or HttpPost or syn.request

-- 🖼️ [[ LOGO CONFIG ]] 🖼️
local LogoID = "rbxassetid://1767893962938"

local SettingsFile = "secret_nano_v32.txt"
local Webhook_URL = ""
local LastMessage = ""
local LastTime = 0
local SentCache = {}

-- ตัวแปร Monitor
local MonitorEnabled = false
local LastPlayerList = {}

local ColorOptions = {
    {Name = "Secret", RGB = "rgb(24, 255, 152)", Hex = 16758827, LabelColor = Color3.fromRGB(24, 255, 152)},
    {Name = "Mythic", RGB = "rgb(210, 40, 40)",    Hex = 13739048, LabelColor = Color3.fromRGB(210, 40, 40)},
    {Name = "Legendary", RGB = "rgb(255, 170, 0)",    Hex = 16755200, LabelColor = Color3.fromRGB(255, 170, 0)},
    {Name = "Epic", RGB = "rgb(170, 85, 255)",   Hex = 11163135, LabelColor = Color3.fromRGB(170, 85, 255)},
    {Name = "Rare",    RGB = "rgb(85, 255, 255)",   Hex = 5636095, LabelColor = Color3.fromRGB(85, 255, 255)}
}
local CurrentTarget = ColorOptions[1]

-- [[ 🛠️ GUI SETUP ]]
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local UIStroke = Instance.new("UIStroke")
local CloseBtn = Instance.new("TextButton")
local HeaderIcon = Instance.new("ImageLabel")
local HeaderText = Instance.new("TextLabel")
local WebhookInput = Instance.new("TextBox")
local DropdownBtn = Instance.new("TextButton")
local DropdownFrame = Instance.new("ScrollingFrame")
local SaveBtn = Instance.new("TextButton")
local TestBtn = Instance.new("TextButton")
local MonitorBtn = Instance.new("TextButton") -- ปุ่มใหม่
local ToggleBtn = Instance.new("ImageButton")

pcall(function()
    if gethui then ScreenGui.Parent = gethui()
    elseif syn and syn.protect_gui then syn.protect_gui(ScreenGui) ScreenGui.Parent = CoreGui
    else ScreenGui.Parent = CoreGui end
end)

-- Main Frame (ขยายความสูงเป็น 160)
MainFrame.Name = "NanoMonitorUI"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
MainFrame.Position = UDim2.new(0.5, -90, 0.5, -80)
MainFrame.Size = UDim2.new(0, 180, 0, 160) -- สูงขึ้นเพื่อใส่ Monitor
MainFrame.Active = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

UIStroke.Parent = MainFrame
UIStroke.Thickness = 1.5
UIStroke.Transparency = 0
UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

CloseBtn.Parent = MainFrame
CloseBtn.BackgroundTransparency = 1
CloseBtn.Position = UDim2.new(1, -20, 0, 2)
CloseBtn.Size = UDim2.new(0, 20, 0, 20)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(100, 100, 100)
CloseBtn.TextSize = 14

HeaderIcon.Parent = MainFrame
HeaderIcon.BackgroundTransparency = 1
HeaderIcon.Position = UDim2.new(0, 8, 0, 5)
HeaderIcon.Size = UDim2.new(0, 14, 0, 14)
HeaderIcon.Image = LogoID

HeaderText.Parent = MainFrame
HeaderText.BackgroundTransparency = 1
HeaderText.Position = UDim2.new(0, 28, 0, 2)
HeaderText.Size = UDim2.new(1, -40, 0, 20)
HeaderText.Font = Enum.Font.GothamBold
HeaderText.Text = "Webhook"
HeaderText.TextColor3 = Color3.fromRGB(200, 200, 200)
HeaderText.TextSize = 9
HeaderText.TextXAlignment = Enum.TextXAlignment.Left

WebhookInput.Parent = MainFrame
WebhookInput.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
WebhookInput.Position = UDim2.new(0, 10, 0, 25)
WebhookInput.Size = UDim2.new(1, -20, 0, 25)
WebhookInput.Font = Enum.Font.Gotham
WebhookInput.PlaceholderText = "Webhook URL..."
WebhookInput.PlaceholderColor3 = Color3.fromRGB(60, 60, 70)
WebhookInput.Text = ""
WebhookInput.TextColor3 = Color3.fromRGB(210, 210, 210)
WebhookInput.TextSize = 10
WebhookInput.ClipsDescendants = true
Instance.new("UICorner", WebhookInput).CornerRadius = UDim.new(0, 4)

DropdownBtn.Parent = MainFrame
DropdownBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
DropdownBtn.Position = UDim2.new(0, 10, 0, 55)
DropdownBtn.Size = UDim2.new(1, -20, 0, 25)
DropdownBtn.Font = Enum.Font.GothamBold
DropdownBtn.Text = CurrentTarget.Name .. " ▼"
DropdownBtn.TextColor3 = CurrentTarget.LabelColor
DropdownBtn.TextSize = 10
Instance.new("UICorner", DropdownBtn).CornerRadius = UDim.new(0, 4)

DropdownFrame.Parent = MainFrame
DropdownFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
DropdownFrame.Position = UDim2.new(0, 10, 0, 82)
DropdownFrame.Size = UDim2.new(1, -20, 0, 100)
DropdownFrame.Visible = false
DropdownFrame.ZIndex = 20
DropdownFrame.BorderSizePixel = 0
DropdownFrame.ScrollBarThickness = 2
Instance.new("UICorner", DropdownFrame).CornerRadius = UDim.new(0, 4)

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = DropdownFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

for i, colorData in ipairs(ColorOptions) do
    local OptionBtn = Instance.new("TextButton")
    OptionBtn.Parent = DropdownFrame
    OptionBtn.Size = UDim2.new(1, 0, 0, 20)
    OptionBtn.BackgroundTransparency = 1
    OptionBtn.Font = Enum.Font.Gotham
    OptionBtn.Text = "  " .. colorData.Name
    OptionBtn.TextColor3 = colorData.LabelColor
    OptionBtn.TextSize = 9
    OptionBtn.TextXAlignment = Enum.TextXAlignment.Left
    OptionBtn.ZIndex = 21
    OptionBtn.MouseButton1Click:Connect(function()
        CurrentTarget = colorData
        DropdownBtn.Text = CurrentTarget.Name .. " ▼"
        DropdownBtn.TextColor3 = CurrentTarget.LabelColor
        DropdownFrame.Visible = false
    end)
end

-- Save Button
SaveBtn.Parent = MainFrame
SaveBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
SaveBtn.Position = UDim2.new(0, 10, 0, 90)
SaveBtn.Size = UDim2.new(0.30, 0, 0, 25)
SaveBtn.Font = Enum.Font.GothamBold
SaveBtn.Text = "SAVE"
SaveBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
SaveBtn.TextSize = 9
Instance.new("UICorner", SaveBtn).CornerRadius = UDim.new(0, 4)

-- Test Button
TestBtn.Parent = MainFrame
TestBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
TestBtn.AnchorPoint = Vector2.new(1, 0)
TestBtn.Position = UDim2.new(1, -10, 0, 90)
TestBtn.Size = UDim2.new(0.30, 0, 0, 25)
TestBtn.Font = Enum.Font.GothamBold
TestBtn.Text = "TEST"
TestBtn.TextColor3 = Color3.fromRGB(255, 200, 50)
TestBtn.TextSize = 9
Instance.new("UICorner", TestBtn).CornerRadius = UDim.new(0, 4)

-- Monitor Button (ใหม่)
MonitorBtn.Parent = MainFrame
MonitorBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MonitorBtn.Position = UDim2.new(0, 10, 0, 125)
MonitorBtn.Size = UDim2.new(1, -20, 0, 25)
MonitorBtn.Font = Enum.Font.GothamBold
MonitorBtn.Text = "Player Check: OFF"
MonitorBtn.TextColor3 = Color3.fromRGB(255, 80, 80) -- แดง
MonitorBtn.TextSize = 9
Instance.new("UICorner", MonitorBtn).CornerRadius = UDim.new(0, 4)

ToggleBtn.Parent = ScreenGui
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ToggleBtn.BackgroundTransparency = 0
ToggleBtn.Position = UDim2.new(0.05, 0, 0.85, 0)
ToggleBtn.Size = UDim2.new(0, 35, 0, 35)
ToggleBtn.Image = LogoID
ToggleBtn.ScaleType = Enum.ScaleType.Fit
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)
local TogStroke = Instance.new("UIStroke")
TogStroke.Parent = ToggleBtn; TogStroke.Thickness = 2; TogStroke.Color = Color3.fromRGB(255, 255, 255)

-- [[ 🚀 LOGIC ]]
task.spawn(function()
    while true do
        local t = tick()
        local hue = (t * 0.2) % 1
        local rgb = Color3.fromHSV(hue, 0.8, 1)
        UIStroke.Color = rgb; TogStroke.Color = rgb
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

local function SaveConfig()
    SaveBtn.Text = "..."
    local url = WebhookInput.Text
    if url and url ~= "" then
        url = string.gsub(url, "%s+", "")
        Webhook_URL = url
        if writefile then writefile(SettingsFile, url); SaveBtn.Text = "Done" end
    else SaveBtn.Text = "❌" end
    wait(1); SaveBtn.Text = "SAVE"
end

local function LoadConfig()
    if isfile and isfile(SettingsFile) then
        local content = readfile(SettingsFile)
        if content and content ~= "" then Webhook_URL = content; WebhookInput.Text = "Loaded" end
    end
end

-- [[ 🔥 DYNAMIC CACHE ]]
local ItemsFolder = ReplicatedStorage:WaitForChild("Items")
local AllFishNames = {}
for _, item in pairs(ItemsFolder:GetChildren()) do
    if item:IsA("ModuleScript") then table.insert(AllFishNames, item.Name) end
end
table.sort(AllFishNames, function(a, b) return #a > #b end)

-- [[ 🧠 PARSER ]]
local function ParseFishData(fullString)
    local fishName = "Unknown"
    local status = "-"
    for _, name in ipairs(AllFishNames) do
        if string.sub(fullString, -#name) == name then
            fishName = name
            local prefix = string.sub(fullString, 1, -#name - 2)
            if prefix and prefix ~= "" then status = prefix end
            break
        end
    end
    if fishName == "Unknown" then fishName = fullString end
    return fishName, status
end

-- [[ 🖼️ ASYNC IMAGE FETCHER ]] 
local FishDB = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ModelDownloader"):WaitForChild("Collection"):WaitForChild("Fish")
local ManualFishDB = { ["Zombie Megalodon"] = "110861329686146", ["Zombie Shark"] = "118840558184490" }

local function GetRealImageLink(idString)
    local idNumber = string.match(idString, "%d+")
    if not idNumber then return "" end
    local proxyUrl = "https://thumbnails.roproxy.com/v1/assets?assetIds="..idNumber.."&size=420x420&format=Png"
    local success, response = pcall(function() return Request({Url = proxyUrl, Method = "GET"}) end)
    if success and response.StatusCode == 200 then
        local data = HttpService:JSONDecode(response.Body)
        if data and data.data and data.data[1] and data.data[1].imageUrl then return data.data[1].imageUrl end
    end
    return "https://www.roblox.com/asset-thumbnail/image?assetId="..idNumber.."&width=420&height=420&format=png"
end

local function GetFishImage(fishName)
    local imageId = ""
    if ManualFishDB[fishName] then return GetRealImageLink(ManualFishDB[fishName]) end
    pcall(function()
        local mod = ItemsFolder:FindFirstChild(fishName)
        if mod and mod:IsA("ModuleScript") then
            local data = require(mod)
            if data and data.Data and data.Data.Icon then imageId = data.Data.Icon end
        end
    end)
    if imageId == "" then
        local fd = FishDB:FindFirstChild(fishName)
        if fd then
            if fd:FindFirstChild("Image") then imageId = fd.Image.Value
            elseif fd:FindFirstChild("Texture") then imageId = fd.Texture.Value
            elseif fd:IsA("MeshPart") then imageId = fd.TextureID end
        end
    end
    if imageId ~= "" then return GetRealImageLink(imageId) end
    return "https://tr.rbxcdn.com/565d787095594e0941551064299b844b/420/420/Image/Png"
end

-- Events
SaveBtn.MouseButton1Click:Connect(SaveConfig)
DropdownBtn.MouseButton1Click:Connect(function() DropdownFrame.Visible = not DropdownFrame.Visible end)
CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false end)
ToggleBtn.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)

TestBtn.MouseButton1Click:Connect(function()
    task.spawn(function()
        TestBtn.Text = "..."
        local url = WebhookInput.Text ~= "" and WebhookInput.Text or Webhook_URL
        if url == "" then TestBtn.Text = "❌"; task.wait(1); TestBtn.Text = "TEST" return end
        pcall(function()
            Request({Url=url, Method="POST", Headers={["content-type"]="application/json"}, Body=HttpService:JSONEncode({["embeds"]={{["title"]="🔔 CONNECTED",["color"]=65280}}})})
        end)
        TestBtn.Text = "✅"; task.wait(1); TestBtn.Text = "TEST"
    end)
end)

-- Monitor Logic
MonitorBtn.MouseButton1Click:Connect(function()
    MonitorEnabled = not MonitorEnabled
    if MonitorEnabled then
        MonitorBtn.Text = "Player Check: ON"
        MonitorBtn.TextColor3 = Color3.fromRGB(80, 255, 80) -- เขียว
        LastPlayerList = {}
        for _, p in pairs(Players:GetPlayers()) do table.insert(LastPlayerList, p.Name) end
    else
        MonitorBtn.Text = "player Check: OFF"
        MonitorBtn.TextColor3 = Color3.fromRGB(255, 80, 80) -- แดง
    end
end)

task.spawn(function()
    while true do
        if MonitorEnabled then
            local CurrentList = {}
            local CurrentSet = {}
            for _, p in pairs(Players:GetPlayers()) do table.insert(CurrentList, p.Name); CurrentSet[p.Name] = true end
            if #LastPlayerList > 0 then
                for _, name in pairs(LastPlayerList) do
                    if not CurrentSet[name] and Webhook_URL ~= "" then
                        pcall(function()
                            Request({
                                Url=Webhook_URL, Method="POST", Headers={["content-type"]="application/json"},
                                Body=HttpService:JSONEncode({["embeds"]={{["title"]="❌ DISCONNECTED",["description"]="**"..name.."** left.",["color"]=16711680,["footer"]={["text"]=os.date("%X")}}}})
                            })
                        end)
                    end
                end
            end
            LastPlayerList = CurrentList
        end
        task.wait(10) -- เช็คทุก 10 วิ
    end
end)

-- [[ ⚡ CORE LOGIC (THREADED) ⚡ ]]
local function Analyze(msg)
    if msg == LastMessage and (os.time() - LastTime < 5) then return end
    if CurrentTarget.RGB ~= "ALL" and not string.find(msg, CurrentTarget.RGB, 1, true) then return end
    
    local clean = string.gsub(msg, "<.->", "")
    if string.find(clean, "%[Global%]:") then return end
    if not string.find(clean, "%[Server%]:") then return end

    local p, rawFishName, w = string.match(clean, ":%s*(.-)%s+obtained an?%s+(.-)%s+%((.-)%)")
    
    if p and rawFishName then
        task.spawn(function()
            local dupKey = p.."|"..rawFishName.."|"..w
            if SentCache[dupKey] and (os.time() - SentCache[dupKey] < 10) then return end
            SentCache[dupKey] = os.time()
            LastMessage = msg; LastTime = os.time()

            local uid = 1
            pcall(function() if Players:FindFirstChild(p) then uid = Players[p].UserId end end)
            
            local realName, status = ParseFishData(rawFishName)
            local img = GetFishImage(realName)
            
            local payload = {
                ["embeds"] = {{
                    ["title"] = "🌟 " .. CurrentTarget.Name .. " CATCH! 🌟",
                    ["color"] = CurrentTarget.Hex,
                    ["fields"] = {
                        {["name"]="Player", ["value"]="`"..p.."`", ["inline"]=true},
                        {["name"]="Weight", ["value"]="`"..w.."`", ["inline"]=true},
                        {["name"]="Mutations", ["value"]=status, ["inline"]=true},
                        {["name"]="Fish", ["value"]="#"..realName, ["inline"]=true}
                    },
                    ["image"] = {["url"]=img},
                    ["thumbnail"] = {["url"]="https://www.roblox.com/headshot-thumbnail/image?userId="..uid.."&width=420&height=420&format=png"},
                    ["footer"] = {["text"]=os.date("%X")}
                }}
            }
            
            pcall(function()
                Request({Url=Webhook_URL, Method="POST", Headers={["content-type"]="application/json"}, Body=HttpService:JSONEncode(payload)})
            end)
        end)
    end
end

LoadConfig()
TextChatService.MessageReceived:Connect(function(data) Analyze(data.Text) end)
if ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents") then
    ReplicatedStorage.DefaultChatSystemChatEvents.OnMessageDoneFiltering.OnClientEvent:Connect(function(data) Analyze(data.Message) end)
end
