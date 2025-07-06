local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local backpack = localPlayer:WaitForChild("Backpack")
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local GameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local Remove_Item = GameEvents:WaitForChild("Remove_Item")

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

-- List of plant names you want to remove (case-insensitive)
local plantsToRemove = {
    ["tomato"] = true,
    ["corn"] = true,
    -- Add more plant names here as needed, all lowercase
}

-- Function to check if plant is in removal list
local function shouldRemovePlant(plantName)
    return plantsToRemove[string.lower(plantName)] == true
end

local function autoRemovePlants()
    local shovel = equipShovel()
    if not shovel then
        warn("Shovel tool not found!")
        return
    end

    local plantsFolder = workspace:WaitForChild("Farm"):WaitForChild("Farm"):WaitForChild("Important"):WaitForChild("Plants_Physical")

    local plants = plantsFolder:GetChildren()
    if #plants == 0 then
        warn("No plants found to remove!")
        return
    end

    for _, plant in ipairs(plants) do
        if shouldRemovePlant(plant.Name) then
            print("Removing plant:", plant.Name)
            Remove_Item:FireServer(plant)
            task.wait(0.5) -- avoid spamming server
        else
            print("Skipping plant:", plant.Name)
        end
    end
end

autoRemovePlants()
