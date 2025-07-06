local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Farms = workspace:WaitForChild("Farm")

-- Automatically equips the shovel tool
local function EquipShovel()
    local character = LocalPlayer.Character
    if not character then return false end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return false end
    local shovel = character:FindFirstChild("Shovel [Destroy Plants]") or backpack:FindFirstChild("Shovel [Destroy Plants]")
    if not shovel then
        warn("Shovel [Destroy Plants] not found!")
        return false
    end
    if shovel.Parent == backpack then
        shovel.Parent = character
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid:EquipTool(shovel)
        return true
    end
    return false
end

local function GetFarmOwner(farm)
    return farm:FindFirstChild("Important") 
       and farm.Important:FindFirstChild("Data") 
       and farm.Important.Data:FindFirstChild("Owner") 
       and farm.Important.Data.Owner.Value
end

local function GetFarm(playerName)
    for _, farm in pairs(Farms:GetChildren()) do
        if GetFarmOwner(farm) == playerName then
            return farm
        end
    end
    return nil
end

local function DestroyTomatoPlants()
    if not EquipShovel() then
        warn("Could not equip shovel!")
        return
    end

    local farm = GetFarm(LocalPlayer.Name)
    if not farm then
        warn("Farm not found!")
        return
    end
    local important = farm:FindFirstChild("Important")
    if not important then
        warn("Important folder not found!")
        return
    end
    local plantsPhysical = important:FindFirstChild("Plants_Physical")
    if not plantsPhysical then
        warn("Plants_Physical folder not found!")
        return
    end

    local destroyed = 0
    for _, plant in ipairs(plantsPhysical:GetChildren()) do
        if plant.Name == "Tomato" and plant:IsA("Model") then
            plant:SetAttribute("AB_FTUEShovel", true)
            destroyed = destroyed + 1
            task.wait(0.1)
        end
    end
    print("Destroyed "..destroyed.." Tomato plants.")
end

DestroyTomatoPlants()
