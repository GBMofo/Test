local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local backpack = localPlayer:WaitForChild("Backpack")
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()

-- Equip the shovel tool
local shovelTool = character:FindFirstChild("Shovel [Destroy Plants]") or backpack:FindFirstChild("Shovel [Destroy Plants]")
if shovelTool and shovelTool.Parent == backpack then
    shovelTool.Parent = character
end
local humanoid = character:FindFirstChildOfClass("Humanoid")
if humanoid and shovelTool then
    humanoid:EquipTool(shovelTool)
end

local workspaceFarm = workspace:FindFirstChild("Farm")
local farm = workspaceFarm and workspaceFarm:FindFirstChild("Farm")
local importantFolder = farm and farm:FindFirstChild("Important")
local plantsFolder = importantFolder and importantFolder:FindFirstChild("Plants_Physical")

local Remove_Item = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("Remove_Item")

local plantsToRemove = {
    ["Carrot"] = true,
    ["Strawberry"] = true,
}

local function removeAllTargetPlants()
    while true do
        local targetPlants = {}

        if plantsFolder then
            for _, plant in ipairs(plantsFolder:GetChildren()) do
                if plantsToRemove[plant.Name] then
                    table.insert(targetPlants, plant)
                end
            end
        end

        if #targetPlants == 0 then
            print("No more target plants found. Stopping.")
            break
        end

        -- Remove fruits of each target plant
        for _, plant in ipairs(targetPlants) do
            local fruitsFolder = plant:FindFirstChild("Fruits")
            if fruitsFolder then
                for _, fruit in ipairs(fruitsFolder:GetChildren()) do
                    if fruit:IsA("Model") or fruit:IsA("BasePart") then
                        print("Shoveling fruit:", fruit.Name, "from plant:", plant.Name)
                        Remove_Item:FireServer(fruit)
                    end
                end
            end
        end

        -- Remove the plants themselves
        for _, plant in ipairs(targetPlants) do
            print("Shoveling plant:", plant.Name)
            Remove_Item:FireServer(plant)
        end

        task.wait() -- yield to avoid freezing
    end
end

removeAllTargetPlants()
