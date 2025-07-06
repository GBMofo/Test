local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local GameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local Farms = workspace:WaitForChild("Farm")

-- Only Tomato plants whitelisted
local Whitelisted_Plants = {
    ["Tomato"] = true,
}
local Whitelisted_PlantsForDestruction = {
    ["Tomato"] = true,
}

local AutoShovel = true
local AutoDestroyPlants = true

local ShovelWeightThreshold = 200 -- Min fruit weight to shovel
local DestructionThreshold = 0    -- 0 means destroy regardless of fruit weight

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

local function EquipShovel()
    local character = LocalPlayer.Character
    if not character then return false end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return false end
    local shovelTool = character:FindFirstChild("Shovel [Destroy Plants]") or backpack:FindFirstChild("Shovel [Destroy Plants]")
    if not shovelTool then return false end
    if shovelTool.Parent == backpack then
        shovelTool.Parent = character
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid:EquipTool(shovelTool)
        return true
    end
    return false
end

local function RemoveFruitsRecursively(parent, threshold)
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("BasePart") then
            local fruitModel = child.Parent
            local weightValue = fruitModel and fruitModel:FindFirstChild("Weight")
            local weight = (weightValue and weightValue:IsA("NumberValue")) and weightValue.Value or math.huge
            if weight < threshold then
                if GameEvents:FindFirstChild("Remove_Item") then
                    GameEvents.Remove_Item:FireServer(child)
                end
                task.wait(0.1)
            end
        elseif child:IsA("Model") or child:IsA("Folder") then
            RemoveFruitsRecursively(child, threshold)
        end
    end
end

local function ShovelPlants()
    local farm = GetFarm(LocalPlayer.Name)
    if not farm then return false end
    local important = farm:FindFirstChild("Important")
    if not important then return false end
    local plantsPhysical = important:FindFirstChild("Plants_Physical")
    if not plantsPhysical then return false end

    if not EquipShovel() then return false end

    local shoveledSomething = false
    for _, plant in ipairs(plantsPhysical:GetChildren()) do
        if Whitelisted_Plants[plant.Name] then
            local fruitsFolder = plant:FindFirstChild("Fruits")
            if fruitsFolder then
                local fruitCount = #fruitsFolder:GetChildren()
                RemoveFruitsRecursively(fruitsFolder, ShovelWeightThreshold)
                if fruitCount > 0 and #fruitsFolder:GetChildren() < fruitCount then
                    shoveledSomething = true
                end
            end
        end
    end
    return shoveledSomething
end

local function DestroyPlants()
    local farm = GetFarm(LocalPlayer.Name)
    if not farm then return false end
    local important = farm:FindFirstChild("Important")
    if not important then return false end
    local plantsPhysical = important:FindFirstChild("Plants_Physical")
    if not plantsPhysical then return false end

    if not EquipShovel() then return false end

    local destroyedCount = 0
    for _, plant in ipairs(plantsPhysical:GetChildren()) do
        if Whitelisted_PlantsForDestruction[plant.Name] then
            local shouldDestroy = true
            if DestructionThreshold > 0 then
                shouldDestroy = false
                local fruitsFolder = plant:FindFirstChild("Fruits")
                if fruitsFolder then
                    for _, fruit in ipairs(fruitsFolder:GetChildren()) do
                        local weightValue = fruit:FindFirstChild("Weight")
                        if weightValue and weightValue.Value < DestructionThreshold then
                            shouldDestroy = true
                            break
                        end
                    end
                end
            end
            if shouldDestroy then
                if GameEvents:FindFirstChild("DeleteObject") then
                    GameEvents.DeleteObject:FireServer(plant)
                    destroyedCount = destroyedCount + 1
                end
                task.wait(0.1)
            end
        end
    end
    return destroyedCount > 0
end

-- Run loops for auto shoveling and destroying tomatoes
task.spawn(function()
    while AutoShovel do
        local success, shoveled = pcall(ShovelPlants)
        if not success or not shoveled then
            task.wait(1)
        else
            task.wait(0.1)
        end
    end
end)

task.spawn(function()
    while AutoDestroyPlants do
        local success, destroyed = pcall(DestroyPlants)
        if not success or not destroyed then
            task.wait(1)
        else
            task.wait(0.1)
        end
    end
end)
