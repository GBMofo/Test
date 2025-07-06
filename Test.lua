-- SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")

-- REMOTES
local GameEvents = ReplicatedStorage:WaitForChild("GameEvents")

-- NOTIFICATION FUNCTION
local function showNotification(message)
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return end
    local screenGui = playerGui:FindFirstChild("PunkTeamInfinite") or Instance.new("ScreenGui")
    screenGui.Name = "PunkTeamInfinite"
    screenGui.Parent = playerGui
    for _, obj in ipairs(screenGui:GetChildren()) do
        if obj.Name == "Notification" then obj:Destroy() end
    end
    local notification = Instance.new("Frame")
    notification.Name = "Notification"
    notification.Size = UDim2.new(0, 300, 0, 50)
    notification.Position = UDim2.new(0.5, -150, 0.3, 0)
    notification.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    notification.BackgroundTransparency = 0.3
    notification.BorderSizePixel = 0
    notification.ZIndex = 100
    notification.Parent = screenGui
    local corner = Instance.new("UICorner", notification)
    corner.CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", notification)
    stroke.Color = Color3.fromRGB(255, 50, 50)
    stroke.Thickness = 2
    local label = Instance.new("TextLabel", notification)
    label.Size = UDim2.new(1, -10, 1, -10)
    label.Position = UDim2.new(0, 5, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = message
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 18
    label.TextWrapped = true
    notification.BackgroundTransparency = 1
    label.TextTransparency = 1
    local fadeIn = TweenService:Create(notification, TweenInfo.new(0.5), {BackgroundTransparency = 0.3})
    local textFadeIn = TweenService:Create(label, TweenInfo.new(0.5), {TextTransparency = 0})
    fadeIn:Play()
    textFadeIn:Play()
    task.delay(3, function()
        local fadeOut = TweenService:Create(notification, TweenInfo.new(0.5), {BackgroundTransparency = 1})
        local textFadeOut = TweenService:Create(label, TweenInfo.new(0.5), {TextTransparency = 1})
        fadeOut:Play()
        textFadeOut:Play()
        fadeOut.Completed:Wait()
        notification:Destroy()
    end)
end

-- WHITELIST: Add plant names you want to destroy here
local Whitelisted_PlantsForDestruction = {
    ["Tomato"] = true,
    ["Strawberry"] = true,
    -- Add more plant names as needed
}

-- EQUIP SHOVEL FUNCTION
local function EquipShovel()
    local character = LocalPlayer.Character
    if not character then return false end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return false end
    local shovelTool = character:FindFirstChild("Shovel [Destroy Plants]") or backpack:FindFirstChild("Shovel [Destroy Plants]")
    if not shovelTool then
        showNotification("Shovel not found in inventory!")
        return false
    end
    if shovelTool.Parent == backpack then
        shovelTool.Parent = character
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid:EquipTool(shovelTool)
        return true
    end
    return false
end

-- MAIN DESTROY FUNCTION
local function DestroyPlants()
    local Farms = workspace:FindFirstChild("Farm")
    if not Farms then showNotification("Farms folder not found!") return false end

    -- Find your own farm
    local function GetFarmOwner(Farm)
        return Farm and Farm:FindFirstChild("Important") and Farm.Important:FindFirstChild("Data") and Farm.Important.Data:FindFirstChild("Owner") and Farm.Important.Data.Owner.Value
    end
    local function GetFarm(PlayerName)
        for _, Farm in next, Farms:GetChildren() do
            if GetFarmOwner(Farm) == PlayerName then
                return Farm
            end
        end
        return nil
    end

    local farm = GetFarm(LocalPlayer.Name)
    if not farm then showNotification("Farm not found!") return false end
    local important = farm:FindFirstChild("Important")
    if not important then showNotification("Important folder not found!") return false end
    local plantsPhysical = important:FindFirstChild("Plants_Physical")
    if not plantsPhysical then showNotification("Plants_Physical not found!") return false end

    -- Equip shovel with retry logic
    local equipped = false
    for i = 1, 3 do
        if pcall(EquipShovel) then
            equipped = true
            break
        end
        task.wait(0.5)
    end
    if not equipped then showNotification("Failed to equip shovel!") return false end

    local destroyedCount = 0
    for _, plant in ipairs(plantsPhysical:GetChildren()) do
        if Whitelisted_PlantsForDestruction[plant.Name] then
            pcall(function()
                if GameEvents:FindFirstChild("DeleteObject") then
                    GameEvents.DeleteObject:FireServer(plant)
                    destroyedCount = destroyedCount + 1
                end
            end)
            task.wait(0.1)
        end
    end

    if destroyedCount > 0 then
        showNotification("Destroyed " .. destroyedCount .. " plants")
        return true
    else
        showNotification("No whitelisted plants found to destroy.")
    end
    return false
end

-- RUN IT ONCE
DestroyPlants()
