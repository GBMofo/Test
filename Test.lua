local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FruitDestroyTestUI"
ScreenGui.Parent = PlayerGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 300, 0, 150)
Frame.Position = UDim2.new(0, 10, 0, 100)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BackgroundTransparency = 0.3
Frame.Parent = ScreenGui

local UICorner = Instance.new("UICorner", Frame)
UICorner.CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 25)
Title.Position = UDim2.new(0, 0, 0, 5)
Title.BackgroundTransparency = 1
Title.Text = "Destroy Fruits Below Weight"
Title.TextColor3 = Color3.fromRGB(255, 50, 50)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 18
Title.Parent = Frame

local InputBox = Instance.new("TextBox")
InputBox.Size = UDim2.new(0, 260, 0, 30)
InputBox.Position = UDim2.new(0, 20, 0, 40)
InputBox.PlaceholderText = "Enter weight threshold (e.g., 3.0)"
InputBox.ClearTextOnFocus = false
InputBox.Text = ""
InputBox.TextColor3 = Color3.new(1,1,1)
InputBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
InputBox.Parent = Frame

local Button = Instance.new("TextButton")
Button.Size = UDim2.new(0, 260, 0, 30)
Button.Position = UDim2.new(0, 20, 0, 80)
Button.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
Button.TextColor3 = Color3.new(1,1,1)
Button.Font = Enum.Font.SourceSansBold
Button.TextSize = 16
Button.Text = "Destroy Fruits"
Button.Parent = Frame

local Feedback = Instance.new("TextLabel")
Feedback.Size = UDim2.new(1, 0, 0, 20)
Feedback.Position = UDim2.new(0, 0, 1, -20)
Feedback.BackgroundTransparency = 1
Feedback.TextColor3 = Color3.fromRGB(255, 255, 255)
Feedback.Font = Enum.Font.SourceSans
Feedback.TextSize = 14
Feedback.Text = ""
Feedback.Parent = Frame

local Remove_Item = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("Remove_Item")
local plantsFolder = workspace:WaitForChild("Farm"):WaitForChild("Farm"):WaitForChild("Important"):WaitForChild("Plants_Physical")
local targetPlantName = "Purple Dahlia"
local espBillboards = {}

local function getPrimaryPart(model)
    if model.PrimaryPart then return model.PrimaryPart end
    for _, part in ipairs(model:GetChildren()) do
        if part:IsA("BasePart") then
            model.PrimaryPart = part
            return part
        end
    end
    return nil
end

local function createOrUpdateESP(plant)
    if plant.Name ~= targetPlantName then return end
    local primaryPart = getPrimaryPart(plant)
    if not primaryPart then return end

    local weightValue = plant:FindFirstChild("Weight")
    local weightText = weightValue and string.format("%.1f kg", weightValue.Value) or "Weight ?"
    local labelText = plant.Name .. " - " .. weightText

    local billboard = espBillboards[plant]
    if not billboard then
        billboard = Instance.new("BillboardGui")
        billboard.Name = "PlantESP"
        billboard.Adornee = primaryPart
        billboard.Size = UDim2.new(0, 150, 0, 40)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = plant

        local textLabel = Instance.new("TextLabel")
        textLabel.Name = "Label"
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
        textLabel.Font = Enum.Font.SourceSansBold
        textLabel.TextSize = 16
        textLabel.TextStrokeTransparency = 0.5
        textLabel.Parent = billboard

        espBillboards[plant] = billboard
    end

    billboard.Label.Text = labelText
end

local function removeFruitParts(fruitModel)
    for _, child in ipairs(fruitModel:GetChildren()) do
        if child:IsA("BasePart") then
            Remove_Item:FireServer(child)
        elseif child:IsA("Model") or child:IsA("Folder") then
            removeFruitParts(child)
        end
    end
end

local function removeFruitsBelowWeight(plantModel, weightThreshold)
    local fruitsFolder = plantModel:FindFirstChild("Fruits")
    if not fruitsFolder then return end

    for _, fruit in ipairs(fruitsFolder:GetChildren()) do
        if fruit:IsA("Model") then
            local weightValue = fruit:FindFirstChild("Weight")
            if weightValue and weightValue:IsA("NumberValue") then
                if weightValue.Value < weightThreshold then
                    removeFruitParts(fruit)
                end
            end
        end
    end
end

Button.MouseButton1Click:Connect(function()
    local input = tonumber(InputBox.Text)
    if not input then
        Feedback.Text = "Please enter a valid number!"
        return
    end

    local count = 0
    for _, plant in ipairs(plantsFolder:GetChildren()) do
        if plant.Name == targetPlantName then
            removeFruitsBelowWeight(plant, input)
            count = count + 1
        end
    end

    Feedback.Text = "Processed " .. count .. " plants with weight < " .. input
end)

RunService.Heartbeat:Connect(function()
    for _, plant in ipairs(plantsFolder:GetChildren()) do
        if plant.Name == targetPlantName then
            createOrUpdateESP(plant)
        end
    end
end)
