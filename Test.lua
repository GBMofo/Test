local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local GameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local DeleteObject = GameEvents:WaitForChild("DeleteObject")
local RemoveItem = GameEvents:WaitForChild("Remove_Item")
local ShovelPrompt = localPlayer.PlayerGui:WaitForChild("ShovelPrompt")
local ConfirmFrame = ShovelPrompt:WaitForChild("ConfirmFrame")

local GetFarm = require(ReplicatedStorage.Modules.GetFarm)

local function EquipShovel()
    local character = localPlayer.Character
    if not character then return false end
    local tool = character:FindFirstChild("Shovel [Destroy Plants]") or localPlayer.Backpack:FindFirstChild("Shovel [Destroy Plants]")
    if not tool then
        warn("Shovel tool not found")
        return false
    end
    tool.Parent = character
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid:EquipTool(tool)
        task.wait(0.1)
        tool:Activate()
        return true
    end
    return false
end

local function GetTargetPart(model)
    if model.PrimaryPart then return model.PrimaryPart end
    for _, child in ipairs(model:GetChildren()) do
        if child:IsA("BasePart") then return child end
    end
    return nil
end

local function SimulateShovelTargeting(plantPart)
    local screenPos, onScreen = camera:WorldToViewportPoint(plantPart.Position)
    if not onScreen then
        warn("Plant not on screen")
        return false
    end

    -- Simulate the shovel's input handler by firing the mouse click at the screen position
    -- The shovel listens to mouse clicks and calls handleShovelInput_upvr with mouse location
    -- We simulate this by invoking the mouse click event manually

    -- Move mouse cursor (if possible)
    UserInputService:SetMouseLocation(screenPos.X, screenPos.Y)
    -- Fire mouse button down event
    local mouse = localPlayer:GetMouse()
    mouse.Button1Down:Wait() -- wait for actual click or simulate if possible

    -- Alternatively, if you can access the shovel's input function, call it directly with screenPos

    -- Wait for the prompt to appear
    local timeout = 5
    while not ShovelPrompt.Enabled and timeout > 0 do
        task.wait(0.1)
        timeout -= 0.1
    end

    return ShovelPrompt.Enabled
end

local function ConfirmDestruction()
    if not ShovelPrompt.Enabled then
        warn("Shovel prompt not enabled")
        return false
    end

    -- Fire the confirm button click event programmatically
    ConfirmFrame.Confirm:CaptureFocus()
    ConfirmFrame.Confirm.MouseButton1Click:Fire()

    -- Wait for prompt to close
    local timeout = 5
    while ShovelPrompt.Enabled and timeout > 0 do
        task.wait(0.1)
        timeout -= 0.1
    end

    return not ShovelPrompt.Enabled
end

local function DestroyPlant(plant)
    local plantPart = GetTargetPart(plant)
    if not plantPart then
        warn("No valid part found for plant:", plant.Name)
        return false
    end

    -- Teleport near plant
    local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = plantPart.CFrame * CFrame.new(0, 0, 2)
        task.wait(0.3)
    end

    if not SimulateShovelTargeting(plantPart) then
        warn("Failed to target plant:", plant.Name)
        return false
    end

    if not ConfirmDestruction() then
        warn("Failed to confirm destruction for plant:", plant.Name)
        return false
    end

    print("Destroyed plant:", plant.Name)
    return true
end

if EquipShovel() then
    local farm = GetFarm(localPlayer)
    local important = farm and farm:FindFirstChild("Important")
    local plantsPhysical = important and important:FindFirstChild("Plants_Physical")
    if plantsPhysical then
        for _, plant in ipairs(plantsPhysical:GetChildren()) do
            -- Add your plant filtering logic here if needed
            DestroyPlant(plant)
            task.wait(0.5)
        end
    else
        warn("Plants_Physical folder not found")
    end
else
    warn("Failed to equip shovel")
end
