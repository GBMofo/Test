local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local GameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local DeleteObject = GameEvents:WaitForChild("DeleteObject")

local GetFarm = require(ReplicatedStorage.Modules.GetFarm)

local DestructionThreshold = 100 -- Weight threshold for destruction

local Whitelisted_PlantsForDestruction = {
    ["Tomato"] = true,
    ["Strawberry"] = true,
    ["Carrot"] = true,
}

-- Equip shovel tool function
local function EquipShovel()
    local character = localPlayer.Character
    if not character then return false end

    if character:FindFirstChild("Shovel [Destroy Plants]") then
        return true
    end

    local backpack = localPlayer:WaitForChild("Backpack")
    local shovelTool = backpack:FindFirstChild("Shovel [Destroy Plants]")
    if shovelTool then
        shovelTool.Parent = character
        return true
    end

    return false
end

-- Recursive function to check if any fruit part/model under 'parent' has weight below threshold
local function hasFruitBelowThreshold(parent, threshold)
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("BasePart") then
            local fruitModel = child.Parent
            if fruitModel and fruitModel:IsA("Model") then
                local weightValue = fruitModel:FindFirstChild("Weight")
                if weightValue and weightValue:IsA("NumberValue") then
                    print(string.format("Checking fruit '%s' weight: %d", fruitModel.Name, weightValue.Value))
                    if weightValue.Value < threshold then
                        return true
                    end
                else
                    print("Weight value missing or invalid for fruit:", fruitModel.Name)
                end
            end
        elseif child:IsA("Model") or child:IsA("Folder") then
            if hasFruitBelowThreshold(child, threshold) then
                return true
            end
        end
    end
    return false
end

local function DestroyPlants()
    if not EquipShovel() then
        warn("Failed to equip shovel!")
        return false
    end

    local farm = GetFarm(localPlayer)
    if not farm then
        warn("Farm not found!")
        return false
    end

    local important = farm:FindFirstChild("Important")
    if not important then
        warn("Important folder not found!")
        return false
    end

    local plantsPhysical = important:FindFirstChild("Plants_Physical")
    if not plantsPhysical then
        warn("Plants_Physical not found!")
        return false
    end

    local destroyedCount = 0

    for _, plant in ipairs(plantsPhysical:GetChildren()) do
        if Whitelisted_PlantsForDestruction[plant.Name] then
            local fruitsFolder = plant:FindFirstChild("Fruits")
            local shouldDestroy = false
            if fruitsFolder then
                shouldDestroy = hasFruitBelowThreshold(fruitsFolder, DestructionThreshold)
            else
                print("No fruits folder found in plant:", plant.Name)
            end

            if shouldDestroy then
                print("Destroying plant:", plant.Name)
                DeleteObject:FireServer(plant)
                destroyedCount = destroyedCount + 1
                task.wait(0.1) -- small delay to avoid spamming
            end
        end
    end

    if destroyedCount > 0 then
        warn("Destroyed " .. destroyedCount .. " plants")
        return true
    else
        print("No plants met destruction criteria.")
        return false
    end
end

DestroyPlants()
