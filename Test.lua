local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local GameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local DeleteObject = GameEvents:WaitForChild("DeleteObject")
local RemoveItem = GameEvents:WaitForChild("Remove_Item")

local GetFarm = require(ReplicatedStorage.Modules.GetFarm)

local DestructionThreshold = 100 -- Weight threshold for destruction

local Whitelisted_PlantsForDestruction = {
    ["Tomato"] = true,
    ["Strawberry"] = true,
    ["Carrot"] = true,
}

local function EquipAndActivateShovel()
    local character = localPlayer.Character
    if not character then 
        warn("Character not found")
        return false 
    end

    local tool = character:FindFirstChild("Shovel [Destroy Plants]")
    if not tool then
        local backpack = localPlayer:WaitForChild("Backpack")
        tool = backpack:FindFirstChild("Shovel [Destroy Plants]")
        if tool then
            tool.Parent = character
            print("Moved shovel to character")
        else
            warn("Shovel tool not found in backpack")
            return false
        end
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid and tool:IsA("Tool") then
        humanoid:EquipTool(tool)
        task.wait(0.1) -- small wait to ensure equip
        tool:Activate() -- simulate tool activation
        print("Shovel equipped and activated")
        return true
    else
        warn("Humanoid or tool invalid")
        return false
    end
end

local function hasFruitBelowThreshold(parent, threshold)
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("BasePart") then
            local fruitModel = child.Parent
            if fruitModel and fruitModel:IsA("Model") then
                local weightValue = fruitModel:FindFirstChild("Weight")
                if weightValue and weightValue:IsA("NumberValue") then
                    if weightValue.Value < threshold then
                        return true
                    end
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
    if not EquipAndActivateShovel() then
        warn("Failed to equip and activate shovel!")
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
    local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")

    print("Checking plants for destruction... Total plants:", #plantsPhysical:GetChildren())

    for _, plant in ipairs(plantsPhysical:GetChildren()) do
        print("Checking plant:", plant.Name)
        if Whitelisted_PlantsForDestruction[plant.Name] then
            local fruitsFolder = plant:FindFirstChild("Fruits")
            local shouldDestroy = false
            if fruitsFolder then
                shouldDestroy = hasFruitBelowThreshold(fruitsFolder, DestructionThreshold)
                print("Has fruit below threshold:", shouldDestroy)
            end

            if shouldDestroy then
                print("Destroying plant:", plant.Name)

                -- Teleport player near the plant (if possible)
                if hrp and plant.PrimaryPart then
                    hrp.CFrame = plant.PrimaryPart.CFrame * CFrame.new(0, 0, 3)
                    task.wait(0.3)
                end

                -- Fire destruction and inventory removal events
                DeleteObject:FireServer(plant)
                RemoveItem:FireServer(plant.Name)

                destroyedCount = destroyedCount + 1
                task.wait(0.3) -- delay to avoid spamming server
            end
        else
            print("Plant not whitelisted:", plant.Name)
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
