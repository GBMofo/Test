local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Farms = workspace:WaitForChild("Farm")

-- Helper to get your farm
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

-- Destroy all Tomato plants by setting the shovel attribute
local function DestroyTomatoPlants()
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
