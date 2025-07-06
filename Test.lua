local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local backpack = localPlayer:WaitForChild("Backpack")
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()

-- Equip shovel using your existing EquipShovel function with pcall retry logic
local function EquipShovel()
    -- Your shovel equip logic here
    -- For example, equipping the shovel tool from backpack or character
    local shovelTool = character:FindFirstChild("Shovel [Destroy Plants]") or backpack:FindFirstChild("Shovel [Destroy Plants]")
    if shovelTool and shovelTool.Parent == backpack then
        shovelTool.Parent = character
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid and shovelTool then
        humanoid:EquipTool(shovelTool)
        return true
    end
    return false
end

-- Equip shovel with retry logic
local equipped = false
for i = 1, 3 do
    if pcall(EquipShovel) then
        equipped = true
        break
    end
    task.wait(0.5)
end

if not equipped then
    warn("Failed to equip shovel!")
    return
end

local GameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local Remove_Item = GameEvents:WaitForChild("Remove_Item")

-- Recursive function to remove all fruit parts without delay
local function removeFruitsRecursively(parent)
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("BasePart") then
            Remove_Item:FireServer(child)
        elseif child:IsA("Model") or child:IsA("Folder") then
            removeFruitsRecursively(child)
        end
    end
end

-- Farm path from your previous code
local plantsFolder = workspace:WaitForChild("Farm"):WaitForChild("Farm"):WaitForChild("Important"):WaitForChild("Plants_Physical")

local plantName = "Strawberry" -- Change to your target plant

for _, plant in ipairs(plantsFolder:GetChildren()) do
    if plant.Name == plantName then
        local fruitsFolder = plant:FindFirstChild("Fruits")
        if fruitsFolder then
            removeFruitsRecursively(fruitsFolder)
        else
            warn("Fruits folder not found in plant '" .. plant.Name .. "'!")
        end
    end
end
