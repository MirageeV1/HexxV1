-- UI
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wall%20v3"))()
local w = library:CreateWindow("HexV1")
local Tabs = w:CreateFolder("Combat")


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local VirtualUser = game:GetService("VirtualUser")

-- VARIABLES
_G.TriggerBot = false
_G.TriggerLoop = nil
local ESPEnabled = false
local ESPs = {}

-- TRIGGERBOT
local function setTriggerBotState(state)
    _G.TriggerBot = state

    if _G.TriggerLoop then
        _G.TriggerLoop:Disconnect()
        _G.TriggerLoop = nil
    end

    if not state then return end

    _G.TriggerLoop = RunService.RenderStepped:Connect(function()
        local character = LocalPlayer.Character
        if not character then return end

        local mouse = LocalPlayer:GetMouse()
        local target = mouse.Target
        if not target then return end

        local model = target.Parent
        if not model or not model:IsA("Model") or model == character then return end

        local humanoid = model:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return end

        local hrp = model:FindFirstChild("HumanoidRootPart")
        local head = model:FindFirstChild("Head")

        local mousePos = UserInputService:GetMouseLocation()
        local boxSize = 50

        local function checkPart(part)
            if not part then return false end
            local pos2D, onScreen = Camera:WorldToViewportPoint(part.Position)
            if not onScreen then return false end

            return mousePos.X >= pos2D.X - boxSize/2 and mousePos.X <= pos2D.X + boxSize/2 and
                   mousePos.Y >= pos2D.Y - boxSize/2 and mousePos.Y <= pos2D.Y + boxSize/2
        end

        if checkPart(hrp) or checkPart(head) then
            pcall(function()
                if mouse1click then
                    mouse1click()
                elseif mouse1press and mouse1release then
                    mouse1press()''
                    task.wait(0.02)
                    mouse1release()
                else
                    VirtualUser:Button1Down(Vector2.new())
                    task.wait(0.02)
                    VirtualUser:Button1Up(Vector2.new())
                end
            end)
        end
    end)
end


-- Toggle for the UI
Tabs:Toggle("TriggerBot", function(Value)
    setTriggerBotState(Value)
end)

-- Bind X for triggerbot
Tabs:Bind("Trigger Key", Enum.KeyCode.X, function()
    setTriggerBotState(not _G.TriggerBot)
end)

-- ESP
local function createESP(player)
    if player == LocalPlayer then return end

    local espData = { NameText = nil, BoxLines = {}, HealthBar = nil }

    espData.NameText = Drawing.new("Text")
    espData.NameText.Size = 18
    espData.NameText.Center = true
    espData.NameText.Outline = true
    espData.NameText.Color = Color3.new(1,1,1)

    for i = 1, 4 do
        local line = Drawing.new("Line")
        line.Thickness = 2
        line.Color = Color3.new(1,1,1)
        espData.BoxLines[i] = line
    end

    espData.HealthBar = Drawing.new("Line")
    espData.HealthBar.Thickness = 4
    espData.HealthBar.Color = Color3.fromRGB(0, 255, 0)

    ESPs[player] = espData

    player.CharacterAdded:Connect(function()
        task.wait(0.1)
    end)
end

local function removeESP(player)
    local data = ESPs[player]
    if not data then return end
    pcall(function()
        if data.NameText then data.NameText:Remove() end
        if data.HealthBar then data.HealthBar:Remove() end
        for i = 1, 4 do
            if data.BoxLines[i] then data.BoxLines[i]:Remove() end
        end
    end)
    ESPs[player] = nil
end

for _, p in pairs(Players:GetPlayers()) do
    createESP(p)
end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(removeESP)

--RENDER ESP AND BOX SIZE
RunService.RenderStepped:Connect(function()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end

    if not ESPEnabled then
        for _, d in pairs(ESPs) do
            d.NameText.Visible = false
            d.HealthBar.Visible = false
            for i=1,4 do d.BoxLines[i].Visible = false end
        end
        return
    end

    for player, data in pairs(ESPs) do
        local character = player.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChild("Humanoid")
        if hrp and humanoid then
            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            local distance = (hrp.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude

            -- Name and distance
            data.NameText.Text = player.Name.." ["..math.floor(distance).."m]"
            data.NameText.Position = Vector2.new(pos.X, pos.Y - 50)
            data.NameText.Visible = onScreen

            -- box size
            local size = 50
            local half = size / 2
            local x, y = pos.X, pos.Y

            local corners = {
                Vector2.new(x - half, y - half),
                Vector2.new(x + half, y - half),
                Vector2.new(x + half, y + half),
                Vector2.new(x - half, y + half)
            }

            -- Box lines
            for i=1,4 do
                local line = data.BoxLines[i]
                line.From = corners[i]
                line.To = corners[i%4 + 1]
                line.Color = Color3.new(1,1,1)
                line.Visible = onScreen
            end

            -- HealthBar
            local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
            data.HealthBar.From = Vector2.new(x - half - 6, y + half)
            data.HealthBar.To = Vector2.new(x - half - 6, y + half - size * healthPercent)
            data.HealthBar.Color = Color3.fromHSV(healthPercent / 3, 1, 1)
            data.HealthBar.Visible = onScreen
        else
            data.NameText.Visible = false
            data.HealthBar.Visible = false
            for i=1,4 do data.BoxLines[i].Visible = false end
        end
    end
end)

-- TOGGLE ESP 
local function setESPState(state)
    ESPEnabled = state
end

Tabs:Toggle("ESP", function(Value)
    setESPState(Value)
end)
Tabs:Bind("ESP Key", Enum.KeyCode.B, function() end)


UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end

    if input.KeyCode == Enum.KeyCode.B then
        setESPState(not ESPEnabled)
    elseif input.KeyCode == Enum.KeyCode.LeftAlt then
        w:Toggle()
    end
end)
