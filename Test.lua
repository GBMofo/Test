local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local backpack = localPlayer:WaitForChild("Backpack")
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()

-- Equip and activate the shovel
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

local plantsToTarget = { "Tomato" }

local Remove_Item = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("Remove_Item")

for _, plantName in ipairs(plantsToTarget) do
    local plant = plantsFolder and plantsFolder:FindFirstChild(plantName)
    if plant then
        local fruitsFolder = plant:FindFirstChild("Fruits")
        if fruitsFolder then
            for _, fruit in ipairs(fruitsFolder:GetChildren()) do
                if fruit:IsA("Model") or fruit:IsA("BasePart") then
                    print("Shoveling fruit:", fruit.Name, "from plant:", plant.Name)
                    Remove_Item:FireServer(fruit)
                    task.wait(0.5)
                end
            end
        end
    end
end
