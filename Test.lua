local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local backpack = localPlayer:WaitForChild("Backpack")
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- === CONFIGURATION ===
-- **EDIT THIS VALUE TO CHANGE THE WEIGHT THRESHOLD**
local targetWeightThreshold = 3.5 -- Change this number to destroy fruits lighter than this value
-- For example:
-- 3.5 will destroy fruits with weight 3.4, 3.0, 2.8, etc.
-- 4.0 will destroy fruits with weight 3.9, 3.5, 3.0, etc.


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

local plantsFolder = workspace:WaitForChild("Farm"):WaitForChild("Farm"):WaitForChild("Important"):WaitForChild("Plants_Physical")
local plantName = "Purple Dahlia"

-- Recursive function to remove fruit parts only if weight is less than targetWeightThreshold
local function removeFruitsBasedOnWeight(parent)
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("Model") then
            local weightValue = child:FindFirstChild("Weight")
            if weightValue and weightValue:IsA("NumberValue") then
                if weightValue.Value < targetWeightThreshold then
                    -- Remove all BaseParts inside this fruit model
                    for _, part in ipairs(child:GetChildren()) do
                        if part:IsA("BasePart") then
                            print("Removing fruit part:", part:GetFullName(), "Weight:", weightValue.Value)
                            Remove_Item:FireServer(part)
                        end
                    end
                else
                    print("Skipping fruit (weight >= threshold):", child.Name, "Weight:", weightValue.Value)
                end
            else
                print("Skipping fruit without weight NumberValue:", child.Name)
            end
            -- Recurse deeper if the child is a container for more fruits/parts
            removeFruitsBasedOnWeight(child)
        elseif child:IsA("BasePart") then
            -- This branch handles individual parts directly under 'parent'
            -- If these are fruit parts that need weight checks, they should be in a Model
        end
    end
end

print("Destroying fruits with weight less than:", targetWeightThreshold)

-- Run removal on all Purple Dahlia plants
for _, plant in ipairs(plantsFolder:GetChildren()) do
    if plant.Name == plantName then
        local fruitsFolder = plant:FindFirstChild("Fruits")
        if fruitsFolder then
            removeFruitsBasedOnWeight(fruitsFolder)
        else
            warn("Fruits folder not found in plant '" .. plant.Name .. "'!")
        end
    end
end
