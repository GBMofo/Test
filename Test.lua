local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local GameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local DeleteObject = GameEvents:WaitForChild("DeleteObject")
local RemoveItem = GameEvents:WaitForChild("Remove_Item")

local GetFarm = require(ReplicatedStorage.Modules.GetFarm)

local DestructionThreshold = 100

local Whitelisted_PlantsForDestruction = {
    ["Tomato"] = true,
    ["Strawberry"] = true,
    ["Carrot"] = true,
}

local function EquipShovel()
    local character = localPlayer.Character
    if not character then
        warn("Character not found")
        return false
    end

    local tool = character:FindFirstChild("Shovel [Destroy Plants]")
    if not tool then
        local backpack = localPlayer:WaitForChild("Backpack")
        tool = backpack:FindFirstChild("Shovel [Destroy Plants]")
        if tool then
            tool.Parent = character
            print("Moved shovel to character")
        else
            warn("Shovel tool not found in backpack")
            return false
        end
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid and tool:IsA("Tool") then
        humanoid:EquipTool(tool)
        task.wait(0.1)
        tool:Activate()
        print("Shovel equipped and activated")
        return true
    else
        warn("Humanoid or tool invalid")
        return false
    end
end

local function hasFruitBelowThreshold(parent, threshold)
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("BasePart") then
            local fruitModel = child.Parent
            if fruitModel and fruitModel:IsA("Model") then
                local weightValue = fruitModel:FindFirstChild("Weight")
                if weightValue and weightValue:IsA("NumberValue") and weightValue.Value < threshold then
                    return true
                end
            end
        elseif child:IsA("Model") or child:IsA("Folder") then
            if hasFruitBelowThreshold(child, threshold) then
                return true
            end
        end
    end
    return false
end

local function GetTargetPart(model)
    if model.PrimaryPart then
        return model.PrimaryPart
    end

    local commonNames = {"Main", "Base", "Hitbox", "Root"}
    for _, name in ipairs(commonNames) do
        local part = model:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            return part
        end
    end

    for _, child in ipairs(model:GetChildren()) do
        if child:IsA("BasePart") then
            return child
        end
    end

    return nil
end

local function ClickPart(partCFrame)
    local player = Players.LocalPlayer
    local inputGateway1 = player:WaitForChild("PlayerScripts"):WaitForChild("InputGateway"):WaitForChild("Activation")
    local inputGateway2 = player.Character and player.Character:FindFirstChild("InputGateway") and player.Character.InputGateway:FindFirstChild("Activation")

    print("Clicking part at CFrame:", partCFrame)

    inputGateway1:FireServer(true, partCFrame)
    if inputGateway2 then inputGateway2:FireServer(true, partCFrame) end
    task.wait(0.1)

    inputGateway1:FireServer(false, partCFrame)
    if inputGateway2 then inputGateway2:FireServer(false, partCFrame) end
    task.wait(0.2)
end

local function DestroyPlants()
    if not EquipShovel() then
        warn("Failed to equip shovel")
        return false
    end

    local farm = GetFarm(localPlayer)
    if not farm then
        warn("Farm not found")
        return false
    end

    local important = farm:FindFirstChild("Important")
    if not important then
        warn("Important folder not found")
        return false
    end

    local plantsPhysical = important:FindFirstChild("Plants_Physical")
    if not plantsPhysical then
        warn("Plants_Physical not found")
        return false
    end

    local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
    local destroyedCount = 0

    for _, plant in ipairs(plantsPhysical:GetChildren()) do
        print("Checking plant:", plant.Name)
        if Whitelisted_PlantsForDestruction[plant.Name] then
            local fruitsFolder = plant:FindFirstChild("Fruits")
            local shouldDestroy = fruitsFolder and hasFruitBelowThreshold(fruitsFolder, DestructionThreshold)
            print("Has fruit below threshold:", shouldDestroy)

            if shouldDestroy then
                local targetPart = GetTargetPart(plant)
                if not targetPart then
                    warn("No valid target part found for plant: " .. plant.Name)
                    continue
                end

                print("Destroying plant:", plant.Name)

                if hrp then
                    hrp.CFrame = targetPart.CFrame * CFrame.new(0, 0, 0.5)
                    task.wait(0.3)
                    print("Teleported near plant:", plant.Name)
                end

                ClickPart(targetPart.CFrame)

                if fruitsFolder then
                    for _, fruit in ipairs(fruitsFolder:GetChildren()) do
                        local fruitPart = GetTargetPart(fruit) or (fruit:IsA("BasePart") and fruit or nil)
                        if fruitPart then
                            print("Clicking fruit:", fruit.Name)
                            ClickPart(fruitPart.CFrame)
                            task.wait(0.2)
                        end
                    end
                end

                DeleteObject:FireServer(plant)
                RemoveItem:FireServer(plant.Name)
                print("Fired DeleteObject and RemoveItem for plant:", plant.Name)

                if fruitsFolder then
                    for _, fruit in ipairs(fruitsFolder:GetChildren()) do
                        DeleteObject:FireServer(fruit)
                        RemoveItem:FireServer(fruit.Name)
                        print("Fired DeleteObject and RemoveItem for fruit:", fruit.Name)
                        task.wait(0.1)
                    end
                end

                destroyedCount = destroyedCount + 1
                task.wait(0.5)
            end
        else
            print("Plant not whitelisted:", plant.Name)
        end
    end

    if destroyedCount > 0 then
        warn("Destroyed " .. destroyedCount .. " plants")
        return true
    else
        print("No plants met destruction criteria.")
        return false
    end
end

DestroyPlants()
