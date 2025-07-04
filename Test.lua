-- Configuration: Change this to your desired weight threshold
local targetWeightThreshold = 3.5 -- Destroy fruits with weight less than this

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Get LocalPlayer safely (executor might have different environment)
local localPlayer = Players.LocalPlayer or Players:GetPlayers()[1]
if not localPlayer then
    warn("[FruitRemoval] Could not find LocalPlayer!")
    return
end

-- Try to get Backpack and Character
local backpack = localPlayer:FindFirstChild("Backpack")
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
if not backpack or not character then
    warn("[FruitRemoval] Could not find Backpack or Character!")
    return
end

-- Equip shovel tool if found
local shovelTool = character:FindFirstChild("Shovel [Destroy Plants]") or backpack:FindFirstChild("Shovel [Destroy Plants]")
if shovelTool and shovelTool.Parent == backpack then
    shovelTool.Parent = character
end

local humanoid = character:FindFirstChildOfClass("Humanoid")
if humanoid and shovelTool then
    humanoid:EquipTool(shovelTool)
    print("[FruitRemoval] Shovel tool equipped.")
else
    warn("[FruitRemoval] Could not equip shovel tool.")
    -- Not returning here in case you want to proceed anyway
end

-- Get the remote event for removing items
local Remove_Item = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("Remove_Item")

-- Plants folder and target plant name
local plantsFolder = Workspace:WaitForChild("Farm"):WaitForChild("Farm"):WaitForChild("Important"):WaitForChild("Plants_Physical")
local plantName = "Purple Dahlia"

-- Recursive function to remove fruit parts if weight < threshold
local function removeFruitsBasedOnWeight(parent)
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("Model") then
            local weightValue = child:FindFirstChild("Weight")
            if weightValue and weightValue:IsA("NumberValue") then
                if weightValue.Value < targetWeightThreshold then
                    for _, part in ipairs(child:GetChildren()) do
                        if part:IsA("BasePart") then
                            print("[FruitRemoval] Removing fruit part:", part:GetFullName(), "Weight:", weightValue.Value)
                            Remove_Item:FireServer(part)
                        end
                    end
                else
                    print("[FruitRemoval] Skipping fruit (weight >= threshold):", child.Name, "Weight:", weightValue.Value)
                end
            else
                print("[FruitRemoval] Skipping fruit without Weight NumberValue:", child.Name)
            end
            -- Recurse deeper if necessary
            removeFruitsBasedOnWeight(child)
        end
    end
end

-- Main execution: iterate plants and remove fruits below threshold
for _, plant in ipairs(plantsFolder:GetChildren()) do
    if plant.Name == plantName then
        local fruitsFolder = plant:FindFirstChild("Fruits")
        if fruitsFolder then
            removeFruitsBasedOnWeight(fruitsFolder)
        else
            warn("[FruitRemoval] Fruits folder not found in plant '" .. plant.Name .. "'!")
        end
    end
end

print("[FruitRemoval] Finished processing fruits with weight below " .. targetWeightThreshold)
