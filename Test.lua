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

local GameEvents = ReplicatedStorage:WaitForChild("GameEvents", 5)
if not GameEvents then
    warn("GameEvents folder not found in ReplicatedStorage")
    return
end

local Remove_Item = GameEvents:WaitForChild("Remove_Item", 5)
if not Remove_Item then
    warn("Remove_Item event not found in GameEvents")
    return
end

-- Configuration: Change this to your desired weight threshold
local targetWeightThreshold = 3.5 -- Destroy fruits with weight less than this

-- Helper function to get the weight of a fruit part
local function getFruitWeight(fruitPart)
    -- Try to get weight from an attribute first
    local weight = fruitPart:GetAttribute("Weight")
    if weight then
        return weight
    end

    -- Alternatively, try to find a NumberValue child named "Weight"
    local weightValue = fruitPart:FindFirstChild("Weight")
    if weightValue and weightValue:IsA("NumberValue") then
        return weightValue.Value
    end

    -- If no weight found, assume infinite weight (do not remove)
    return math.huge
end

-- Recursive function to remove all fruit parts with weight less than threshold
local function removeFruitsRecursively(parent)
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("BasePart") then
            local fruitWeight = getFruitWeight(child)
            if fruitWeight < targetWeightThreshold then
                print("Removing fruit part:", child:GetFullName(), "Weight:", fruitWeight)
                Remove_Item:FireServer(child)
            else
                print("Skipping fruit part (weight too high):", child:GetFullName(), "Weight:", fruitWeight)
            end
        elseif child:IsA("Model") or child:IsA("Folder") then
            removeFruitsRecursively(child)
        else
            print("Skipping non-part, non-model:", child:GetFullName(), child.ClassName)
        end
    end
end

local plantsFolder = workspace:WaitForChild("Farm"):WaitForChild("Farm"):WaitForChild("Important"):WaitForChild("Plants_Physical")
local plantName = "Purple Dahlia"

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
