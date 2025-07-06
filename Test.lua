local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local GameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local DeleteObject = GameEvents:WaitForChild("DeleteObject")

local GetFarm = require(ReplicatedStorage.Modules.GetFarm)

local DestructionThreshold = 100 -- Set weight threshold to 100

local Whitelisted_PlantsForDestruction = {
    ["Strawberry"] = true,
    ["Tomato"] = true,
    -- Add other plant names as needed
}

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
            local shouldDestroy = true
            
            if DestructionThreshold > 0 then
                shouldDestroy = false
                local fruitsFolder = plant:FindFirstChild("Fruits")
                if fruitsFolder then
                    for _, fruitPart in ipairs(fruitsFolder:GetChildren()) do
                        local fruitModel = fruitPart.Parent
                        local weightValue = fruitModel and fruitModel:FindFirstChild("Weight")
                        if weightValue and weightValue.Value < DestructionThreshold then
                            shouldDestroy = true
                            break
                        end
                    end
                end
            end
            
            if shouldDestroy then
                print("Destroying plant:", plant.Name)
                DeleteObject:FireServer(plant)
                destroyedCount = destroyedCount + 1
                task.wait(0.1)
            end
        end
    end
    
    if destroyedCount > 0 then
        warn("Destroyed " .. destroyedCount .. " plants")
        return true
    end
    
    return false
end

DestroyPlants()
