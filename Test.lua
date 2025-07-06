local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function GetFarmOwner(farm)
    return farm:FindFirstChild("Important") 
       and farm.Important:FindFirstChild("Data") 
       and farm.Important.Data:FindFirstChild("Owner") 
       and farm.Important.Data.Owner.Value
end

local function GetFarm(playerName)
    for _, farm in pairs(workspace.Farm:GetChildren()) do
        if GetFarmOwner(farm) == playerName then
            return farm
        end
    end
    return nil
end

local farm = GetFarm(LocalPlayer.Name)
local plantsPhysical = farm and farm:FindFirstChild("Important") and farm.Important:FindFirstChild("Plants_Physical")
if plantsPhysical then
    for _, plant in ipairs(plantsPhysical:GetChildren()) do
        if plant.Name == "Tomato" and plant:IsA("Model") then
            local mainPart = plant:FindFirstChildWhichIsA("BasePart", true)
            if mainPart and GameEvents:FindFirstChild("Remove_Item") then
                GameEvents.Remove_Item:FireServer(mainPart)
                print("Tried to remove", plant.Name, mainPart.Name)
            end
        end
    end
end
