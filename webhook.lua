local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Request = http_request or request or HttpPost or syn.request

local SettingsFile = "secret.txt"
local Webhook_URL = ""
local LastMessage = ""
local LastTime = 0
local Cooldown = 3
local TargetRGB = "rgb(24, 255, 152)"

local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local TitleLabel = Instance.new("TextLabel")
local CloseBtn = Instance.new("TextButton")
local WebhookInput = Instance.new("TextBox")
local SaveBtn = Instance.new("TextButton")
local TestBtn = Instance.new("TextButton")
local SimBtn = Instance.new("TextButton")
local StatusLabel = Instance.new("TextLabel")
local ToggleBtn = Instance.new("TextButton") 

pcall(function()
    if gethui then ScreenGui.Parent = gethui()
    elseif syn and syn.protect_gui then syn.protect_gui(ScreenGui) ScreenGui.Parent = CoreGui
    else ScreenGui.Parent = CoreGui end
end)

MainFrame.Name = "CleanFishUI"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.Position = UDim2.new(0.5, -130, 0.5, -95)
MainFrame.Size = UDim2.new(0, 260, 0, 190)
MainFrame.Active = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

TitleLabel.Parent = MainFrame
TitleLabel.BackgroundTransparency = 1
TitleLabel.Position = UDim2.new(0, 10, 0, 10)
TitleLabel.Size = UDim2.new(1, -40, 0, 20)
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.Text = "Webhook Secret"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 14
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

CloseBtn.Parent = MainFrame
CloseBtn.BackgroundTransparency = 1
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
CloseBtn.TextSize = 16

WebhookInput.Parent = MainFrame
WebhookInput.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
WebhookInput.Position = UDim2.new(0, 15, 0, 40)
WebhookInput.Size = UDim2.new(1, -30, 0, 35)
WebhookInput.Font = Enum.Font.GothamMedium
WebhookInput.PlaceholderText = "Paste Webhook URL..."
WebhookInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
WebhookInput.Text = ""
WebhookInput.TextColor3 = Color3.fromRGB(24, 255, 152)
WebhookInput.TextSize = 11
WebhookInput.ClipsDescendants = true
Instance.new("UICorner", WebhookInput).CornerRadius = UDim.new(0, 8)

SaveBtn.Parent = MainFrame
SaveBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
SaveBtn.Position = UDim2.new(0, 15, 0, 85)
SaveBtn.Size = UDim2.new(0.42, 0, 0, 30)
SaveBtn.Font = Enum.Font.GothamBold
SaveBtn.Text = "SAVE"
SaveBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
SaveBtn.TextSize = 11
Instance.new("UICorner", SaveBtn).CornerRadius = UDim.new(0, 6)

TestBtn.Parent = MainFrame
TestBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
TestBtn.AnchorPoint = Vector2.new(1, 0)
TestBtn.Position = UDim2.new(1, -15, 0, 85)
TestBtn.Size = UDim2.new(0.42, 0, 0, 30)
TestBtn.Font = Enum.Font.GothamBold
TestBtn.Text = "TEST"
TestBtn.TextColor3 = Color3.fromRGB(255, 200, 0)
TestBtn.TextSize = 11
Instance.new("UICorner", TestBtn).CornerRadius = UDim.new(0, 6)

StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 15, 0, 165)
StatusLabel.Size = UDim2.new(1, -30, 0, 20)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Text = "Status: Idle"
StatusLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
StatusLabel.TextSize = 10

ToggleBtn.Parent = ScreenGui
ToggleBtn.BackgroundTransparency = 1 -- พื้นหลังใส
ToggleBtn.Position = UDim2.new(0.1, 0, 0.8, 0)
ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Text = "❌" -- ตัว Emoji ลอยๆ
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize = 40

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
    local oldSize = btn.TextSize
    btn.TextSize = oldSize - 2
    wait(0.05)
    btn.TextSize = oldSize
end

local function SaveConfig()
    AnimateBtn(SaveBtn)
    local url = WebhookInput.Text
    if url and url ~= "" then
        url = string.gsub(url, "%s+", "")
        Webhook_URL = url
        if writefile then
            writefile(SettingsFile, url)
            StatusLabel.Text = "✅ Saved!"
            StatusLabel.TextColor3 = Color3.fromRGB(24, 255, 152)
            wait(2)
            StatusLabel.Text = "Status: Active"
            StatusLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
        end
    end
end

local function LoadConfig()
    if isfile and isfile(SettingsFile) then
        local content = readfile(SettingsFile)
        if content and content ~= "" then
            Webhook_URL = content
            WebhookInput.Text = "Loaded (Hidden)"
            StatusLabel.Text = "Status: Ready"
        end
    end
end

local FishDB = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ModelDownloader"):WaitForChild("Collection"):WaitForChild("Fish")
local function GetFishImage(fishName)
    local fishData = FishDB:FindFirstChild(fishName)
    local imageId = ""
    if fishData then
        if fishData:FindFirstChild("Image") then imageId = fishData.Image.Value end
        if fishData:FindFirstChild("Texture") then imageId = fishData.Texture.Value end
        if imageId == "" and fishData:IsA("MeshPart") then imageId = fishData.TextureID end
        if imageId ~= "" then
            local idNumber = string.match(imageId, "%d+")
            if idNumber then return "https://www.roblox.com/asset-thumbnail/image?assetId="..idNumber.."&width=420&height=420&format=png" end
        end
    end
    return nil
end

local function SendRealWebhook(data, isSimulated, forceUrl)
    local targetUrl = forceUrl or Webhook_URL
    if targetUrl == "" then
        StatusLabel.Text = "⚠️ No URL!"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        return 
    end
    
    local fishImageUrl = GetFishImage(data.Fish) or ""
    local titleText = "🌟 SECRET CATCH! 🌟"
    local descText = "Someone caught a **Secret Fish**!"
    local embedColor = 16758827

    local payload = {
        ["embeds"] = {{
            ["title"] = titleText,
            ["description"] = descText,
            ["color"] = embedColor,
            ["fields"] = {
                {["name"] = "Player", ["value"] = "```"..data.Player.."```", ["inline"] = true},
                {["name"] = "Weight", ["value"] = "```"..data.Weight.."```", ["inline"] = true},
                {["name"] = "Fish Name", ["value"] = "# ["..data.Fish.."]", ["inline"] = false}
            },
            ["image"] = {["url"] = fishImageUrl},
            ["thumbnail"] = {["url"] = "https://www.roblox.com/headshot-thumbnail/image?userId="..data.UserId.."&width=420&height=420&format=png"},
            ["footer"] = {["text"] = "Clean Hunter | " .. os.date("%X")}
        }}
    }
    
    spawn(function()
        local success, err = pcall(function()
            Request({Url = targetUrl, Method = "POST", Headers = {["content-type"] = "application/json"}, Body = HttpService:JSONEncode(payload)})
        end)
        if success then
            StatusLabel.Text = "🚀 SENT!"
            StatusLabel.TextColor3 = Color3.fromRGB(24, 255, 152)
        else
            StatusLabel.Text = "❌ FAIL"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end)
end

local function TestLink()
    AnimateBtn(TestBtn)
    local inputUrl = WebhookInput.Text
    inputUrl = string.gsub(inputUrl, "%s+", "")
    local urlToUse = (inputUrl ~= "" and string.find(inputUrl, "http")) and inputUrl or Webhook_URL
    if urlToUse == "" then
        StatusLabel.Text = "⚠️ Paste URL first!"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
        return
    end
    StatusLabel.Text = "Testing..."
    StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    
    local payload = {["embeds"] = {{["title"] = "🔔 SYSTEM CONNECTED", ["description"] = "Instant Test Successful!", ["color"] = 65280}}}
    spawn(function()
        local success = pcall(function()
            Request({Url = urlToUse, Method = "POST", Headers = {["content-type"] = "application/json"}, Body = HttpService:JSONEncode(payload)})
        end)
        if success then
            StatusLabel.Text = "✅ WORKED!"
            StatusLabel.TextColor3 = Color3.fromRGB(24, 255, 152)
        else
            StatusLabel.Text = "❌ Invalid Link"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end)
end


local function Analyze(msg)
    if msg == LastMessage and (os.time() - LastTime < 5) then return end
    if not string.find(msg, TargetRGB, 1, true) then return end
    local cleanMsg = string.gsub(msg, "<.->", "")
    if string.find(cleanMsg, "%[Global%]:") then return end
    if not string.find(cleanMsg, "%[Server%]:") then return end

    LastMessage = msg
    local player, fish, weight = string.match(cleanMsg, ":%s*(.-)%s+obtained an?%s+(.-)%s+%((.-)%)")
    
    if player and fish then
        if os.time() - LastTime < Cooldown then return end
        LastTime = os.time()
        local userId = 1
        pcall(function() if Players:FindFirstChild(player) then userId = Players[player].UserId end end)
        SendRealWebhook({Player = player, Fish = fish, Weight = weight, UserId = userId}, false, nil)
    end
end

SaveBtn.MouseButton1Click:Connect(SaveConfig)
TestBtn.MouseButton1Click:Connect(TestLink)
SimBtn.MouseButton1Click:Connect(SimulateCatch)

ToggleBtn.MouseButton1Click:Connect(function() 
    MainFrame.Visible = not MainFrame.Visible 
end)

CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

LoadConfig()

TextChatService.MessageReceived:Connect(function(data) Analyze(data.Text) end)
if ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents") then
    ReplicatedStorage.DefaultChatSystemChatEvents.OnMessageDoneFiltering.OnClientEvent:Connect(function(data) Analyze(data.Message) end)
end
