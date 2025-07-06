local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local backpack = localPlayer:WaitForChild("Backpack")
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Equip shovel
local shovelTool = character:FindFirstChild("Shovel [Destroy Plants]") or backpack:FindFirstChild("Shovel [Destroy Plants]")
if shovelTool and shovelTool.Parent == backpack then
    shovelTool.Parent = character
end

local humanoid = character:FindFirstChildOfClass("Humanoid")
if humanoid and shovelTool then
    humanoid:EquipTool(shovelTool)
else
    warn("Could not equip shovel tool")
    return
end

local Remove_Item = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("Remove_Item")

-- Configuration: weight threshold
local targetWeightThreshold = 200 -- Adjust as needed

local plantsFolder = workspace:WaitForChild("Farm"):WaitForChild("Farm"):WaitForChild("Important"):WaitForChild("Plants_Physical")
local plantName = "Tomato"

local function removeFruitsRecursively(parent)
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("BasePart") then
            local fruitModel = child.Parent
            local weightValue = fruitModel and fruitModel:FindFirstChild("Weight")
            local weight = (weightValue and weightValue:IsA("NumberValue")) and weightValue.Value or math.huge

            if weight < targetWeightThreshold then
                Remove_Item:FireServer(child)
            end
        elseif child:IsA("Model") or child:IsA("Folder") then
            removeFruitsRecursively(child)
        end
    end
end

for _, plant in ipairs(plantsFolder:GetChildren()) do
    if plant.Name == plantName then
        local fruitsFolder = plant:FindFirstChild("Fruits")
        if fruitsFolder then
            removeFruitsRecursively(fruitsFolder)
        else
            warn("Fruits folder not found in plant '" .. plant.Name .. "'!")
        end
    end
end 
