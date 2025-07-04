-- Updated Fruit Removal LocalScript
-- Place this script inside StarterPlayerScripts or a LocalScript running on the client

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration: Change this weight threshold to your desired value
local targetWeightThreshold = 3.5 -- Destroy fruits with weight less than this

-- Get LocalPlayer safely
local localPlayer = Players.LocalPlayer
if not localPlayer then
    warn("[FruitRemoval] LocalPlayer not found! Make sure this script is a LocalScript running on the client.")
    return
end

-- Wait for Backpack and Character
local backpack = localPlayer:WaitForChild("Backpack")
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

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
    return
end

-- Get the remote event for removing items
local Remove_Item = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("Remove_Item")

-- Reference to plants folder and target plant name
local plantsFolder = workspace:WaitForChild("Farm"):WaitForChild("Farm"):WaitForChild("Important"):WaitForChild("Plants_Physical")
local plantName = "Purple Dahlia"

-- Recursive function to remove fruit parts only if weight < targetWeightThreshold
local function removeFruitsBasedOnWeight(parent)
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("Model") then
            local weightValue = child:FindFirstChild("Weight")
            if weightValue and weightValue:IsA("NumberValue") then
                if weightValue.Value < targetWeightThreshold then
                    -- Remove all BaseParts inside this fruit model
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
            -- Recurse in case fruits have nested models/folders
            removeFruitsBasedOnWeight(child)
        elseif child:IsA("BasePart") then
            -- If needed, handle BaseParts directly under the parent here
        end
    end
end

-- Main loop: Iterate plants and remove fruits below threshold
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
