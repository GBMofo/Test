local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local backpack = localPlayer:WaitForChild("Backpack")
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local GameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local Remove_Item = GameEvents:WaitForChild("Remove_Item")
local DeleteObject = GameEvents:WaitForChild("DeleteObject") -- for placeable objects if needed

-- Equip shovel tool
local function equipShovel()
    local shovel = character:FindFirstChild("Shovel [Destroy Plants]") or backpack:FindFirstChild("Shovel [Destroy Plants]")
    if shovel then
        if shovel.Parent == backpack then
            shovel.Parent = character
        end
        humanoid:EquipTool(shovel)
        return shovel
    end
    return nil
end

-- Automatically remove plants by firing the remote event
local function autoRemovePlants(plantNames)
    local shovel = equipShovel()
    if not shovel then
        warn("Shovel tool not found!")
        return
    end

    local workspaceFarm = workspace:FindFirstChild("Farm")
    local farm = workspaceFarm and workspaceFarm:FindFirstChild("Farm")
    local importantFolder = farm and farm:FindFirstChild("Important")
    local plantsFolder = importantFolder and importantFolder:FindFirstChild("Plants_Physical")

    for _, plantName in ipairs(plantNames) do
        local plant = plantsFolder and plantsFolder:FindFirstChild(plantName)
        if plant then
            print("Requesting removal of plant:", plant.Name)
            -- Fire Remove_Item event to simulate shovel confirmation
            Remove_Item:FireServer(plant)
            task.wait(0.5) -- wait to avoid spamming server
        else
            print("Plant not found:", plantName)
        end
    end
end

-- Call with your target plants
autoRemovePlants({"Tomato", "Corn"})
