local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local backpack = localPlayer:WaitForChild("Backpack")
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Wait for shovel client to be ready (as per your rspy snippet)
local ShovelClient = localPlayer:WaitForChild("Shovel_Client")

-- Equip shovel tool
local shovelTool = character:FindFirstChild("Shovel [Destroy Plants]") or backpack:FindFirstChild("Shovel [Destroy Plants]")
if shovelTool and shovelTool.Parent == backpack then
    shovelTool.Parent = character
end

local humanoid = character:FindFirstChildOfClass("Humanoid")
if humanoid and shovelTool then
    humanoid:EquipTool(shovelTool)
else
    warn("Could not equip shovel tool")
    return
end

local GameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local Remove_Item = GameEvents:WaitForChild("Remove_Item")

-- Recursive function to remove all fruit parts without delay
local function removeFruitsRecursively(parent)
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("BasePart") then
            print("Removing fruit part:", child:GetFullName())
            -- Fire Remove_Item event with the fruit part as argument, matching rspy usage
            Remove_Item:FireServer(child)
            -- No delay for fastest removal
        elseif child:IsA("Model") or child:IsA("Folder") then
            removeFruitsRecursively(child)
        else
            print("Skipping non-part, non-model:", child:GetFullName(), child.ClassName)
        end
    end
end

-- Farm path from your previous codes
local plantsFolder = workspace:WaitForChild("Farm"):WaitForChild("Farm"):WaitForChild("Important"):WaitForChild("Plants_Physical")

local plantName = "Strawberry"  -- Change this to target other plants like "Tomato"

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
