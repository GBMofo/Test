-- Global error handler
local function errorHandler(err)
    warn("[PunkTeamInfinite ERROR] " .. err)
    return true
end

local success, errorMsg = xpcall(function()
    -- Services
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local TweenService = game:GetService("TweenService")
    local ProximityPromptService = game:GetService("ProximityPromptService")
    local LocalPlayer = Players.LocalPlayer

    -- Game Folders
    local GameEvents = ReplicatedStorage:WaitForChild("GameEvents")
    local Farms = workspace:WaitForChild("Farm")

    -- Globals
    local Whitelisted_Plants = {}
    local Whitelisted_Sprinklers = {}
    local Whitelisted_PlantsForDestruction = {}
    local AutoShovel = false
    local AutoShovelSprinklers = false
    local AutoDestroyPlants = false
    local ShovelWeightThreshold = 200
    local DestructionThreshold = 0
    local ShovelDelay = 0
    local LastNotificationTime = 0

    -- Plant Data
    local PlantData = {
        Common = {"Carrot", "Strawberry", "Chocolate Carrot", "Pink Tulip"},
        Uncommon = {"Blueberry", "Wild Carrot", "Orange Tulip", "Rose", "Red Lollipop", "Nightshade", "Manuka Flower", "Lavender", "Crocus"},
        Rare = {"Tomato", "Cauliflower", "Delphinium", "Peace Lily", "Pear", "Raspberry", "Liberty Lily", "Corn", "Daffodil", "Candy Sunflower", "Mint", "Glowshroom", "Dandelion", "Nectarshade", "Foxglove", "Succulent", "Bee Balm"},
        Legendary = {"Watermelon", "Pumpkin", "Banana", "Aloe Vera", "Avocado", "Cantaloupe", "Rafflesia", "Green Apple", "Firework Flower", "Bamboo", "Cranberry", "Durian", "Moonflower", "Starfruit", "Papaya", "Lilac", "Lumira", "Violet Corn", "Nectar Thorn"},
        Mythical = {"Peach", "Pineapple", "Moon Melon", "Celestiberry", "Kiwi", "Guanabana", "Bell Pepper", "Prickly Pear", "Parasol Flower", "Cactus", "Lily Of The Valley", "Dragon Fruit", "Easter Egg", "Moon Mango", "Mango", "Coconut", "Blood Banana", "Moonglow", "Eggplant", "Passionfruit", "Lemon", "Honeysuckle", "Nectarine", "Pink Lily", "Purple Dahlia", "Bendboo", "Cocovine"},
        Divine = {"Loquat", "Feijoa", "Pitcher Plant", "Traveler's Fruit", "Rosy Delight", "Pepper", "Cacao", "Grape", "Mushroom", "Cherry Blossom", "Crimson Vine", "Candy Blossom", "Lotus", "Venus Fly Trap", "Cursed Fruit", "Soul Fruit", "Mega Mushroom", "Moon Blossom", "Hive Fruit", "Sunflower", "Dragon Pepper"},
        Prismatic = {"Sugar Apple", "Ember Lily", "Elephant Ears", "Beanstalk"}
    }

    -- Sprinkler Data
    local SprinklerTypes = {
        "Basic Sprinkler",
        "Advanced Sprinkler",
        "Godly Sprinkler",
        "Master Sprinkler",
        "Honey Sprinkler",
        "Chocolate Sprinkler",
        "Tropical Mist Sprinkler",
        "Berry Blusher Sprinkler",
        "Spice Spritzer Sprinkler",
        "Sweet Soaker Sprinkler",
        "Flower Froster Sprinkler",
        "Stalk Sprout Sprinkler"
    }

    -- Fixed rarity order for display
    local RarityOrder = {"Common", "Uncommon", "Rare", "Legendary", "Mythical", "Divine", "Prismatic"}

    local RarityColors = {
        Common = Color3.fromRGB(180, 180, 180),
        Uncommon = Color3.fromRGB(80, 200, 80),
        Rare = Color3.fromRGB(80, 120, 255),
        Legendary = Color3.fromRGB(255, 215, 0),
        Mythical = Color3.fromRGB(255, 100, 255),
        Divine = Color3.fromRGB(255, 90, 90),
        Prismatic = Color3.fromRGB(100, 255, 255)
    }
    -- Proximity Prompt Controller
    local ProximityPromptController
    local function GetProximityPromptController()
        if not ProximityPromptController then
            for _, module in pairs(getloadedmodules()) do
                if module.Name == "ProximityPromptController" then
                    ProximityPromptController = require(module)
                    break
                end
            end
            
            if not ProximityPromptController then
                ProximityPromptController = {
                    AddDisabler = function() end,
                    RemoveDisabler = function() end
                }
            end
        end
        return ProximityPromptController
    end

    -- Notification System
    local function showNotification(message)
        if os.clock() - LastNotificationTime < 1 then return end
        LastNotificationTime = os.clock()
        
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if not playerGui then return end
        
        local screenGui = playerGui:FindFirstChild("PunkTeamInfinite") or Instance.new("ScreenGui")
        screenGui.Name = "PunkTeamInfinite"
        screenGui.Parent = playerGui
        
        for _, obj in ipairs(screenGui:GetChildren()) do
            if obj.Name == "Notification" then obj:Destroy() end
        end
        
        local notification = Instance.new("Frame")
        notification.Name = "Notification"
        notification.Size = UDim2.new(0, 300, 0, 50)
        notification.Position = UDim2.new(0.5, -150, 0.3, 0)
        notification.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        notification.BackgroundTransparency = 0.3
        notification.BorderSizePixel = 0
        notification.ZIndex = 100
        notification.Parent = screenGui
        
        local corner = Instance.new("UICorner", notification)
        corner.CornerRadius = UDim.new(0, 8)
        
        local stroke = Instance.new("UIStroke", notification)
        stroke.Color = Color3.fromRGB(255, 50, 50)
        stroke.Thickness = 2
        
        local label = Instance.new("TextLabel", notification)
        label.Size = UDim2.new(1, -10, 1, -10)
        label.Position = UDim2.new(0, 5, 0, 5)
        label.BackgroundTransparency = 1
        label.Text = message
        label.TextColor3 = Color3.new(1, 1, 1)
        label.Font = Enum.Font.SourceSansBold
        label.TextSize = 18
        label.TextWrapped = true
        
        notification.BackgroundTransparency = 1
        label.TextTransparency = 1
        
        local fadeIn = TweenService:Create(notification, TweenInfo.new(0.5), {BackgroundTransparency = 0.3})
        local textFadeIn = TweenService:Create(label, TweenInfo.new(0.5), {TextTransparency = 0})
        fadeIn:Play()
        textFadeIn:Play()
        
        task.delay(3, function()
            local fadeOut = TweenService:Create(notification, TweenInfo.new(0.5), {BackgroundTransparency = 1})
            local textFadeOut = TweenService:Create(label, TweenInfo.new(0.5), {TextTransparency = 1})
            fadeOut:Play()
            textFadeOut:Play()
            fadeOut.Completed:Wait()
            notification:Destroy()
        end)
    end

    -- Farm Functions
    local function GetFarmOwner(Farm)
        return Farm and Farm:FindFirstChild("Important") and Farm.Important:FindFirstChild("Data") and Farm.Important.Data:FindFirstChild("Owner") and Farm.Important.Data.Owner.Value
    end

    local function GetFarm(PlayerName)
        if not Farms then
            warn("Farms folder not found!")
            return nil
        end
        
        for _, Farm in next, Farms:GetChildren() do
            if GetFarmOwner(Farm) == PlayerName then
                return Farm
            end
        end
        return nil
    end

    local MyFarm = GetFarm(LocalPlayer.Name)
    local PlantsPhysical = MyFarm and MyFarm.Important and MyFarm.Important:FindFirstChild("Plants_Physical")
    -- SHOVEL PLANTS FUNCTIONALITY
    local function EquipShovel()
        local character = LocalPlayer.Character
        if not character then return false end
        
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if not backpack then return false end
        
        local shovelTool = character:FindFirstChild("Shovel [Destroy Plants]") or backpack:FindFirstChild("Shovel [Destroy Plants]")
        if not shovelTool then
            showNotification("Shovel not found in inventory!")
            return false
        end
        
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
                    pcall(function()
                        if GameEvents:FindFirstChild("Remove_Item") then
                            GameEvents.Remove_Item:FireServer(child)
                        end
                    end)
                    task.wait(0.1)
                end
            elseif child:IsA("Model") or child:IsA("Folder") then
                RemoveFruitsRecursively(child, threshold)
            end
        end
    end

    -- FIXED: Now processes all plants of the same name
    local function ShovelPlants()
        local farm = GetFarm(LocalPlayer.Name)
        if not farm then
            showNotification("Farm not found!")
            return false
        end
        
        local important = farm:FindFirstChild("Important")
        if not important then
            showNotification("Important folder not found!")
            return false
        end
        
        local plantsPhysical = important:FindFirstChild("Plants_Physical")
        if not plantsPhysical then
            showNotification("Plants_Physical not found!")
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
            showNotification("Failed to equip shovel!")
            return false
        end
        
        local shoveledSomething = false
        
        -- Process all plants in the Plants_Physical folder
        for _, plant in ipairs(plantsPhysical:GetChildren()) do
            if Whitelisted_Plants[plant.Name] then
                local fruitsFolder = plant:FindFirstChild("Fruits")
                if fruitsFolder then
                    local fruitCount = #fruitsFolder:GetChildren()
                    pcall(RemoveFruitsRecursively, fruitsFolder, ShovelWeightThreshold)
                    
                    if fruitCount > 0 and #fruitsFolder:GetChildren() < fruitCount then
                        shoveledSomething = true
                    end
                end
            end
        end
        
        return shoveledSomething
    end

    -- Improved Auto-Shovel Loop with immediate stop
    local ShovelThread
    local function StartAutoShovel()
        if ShovelThread then
            task.cancel(ShovelThread)
            ShovelThread = nil
        end
        
        if AutoShovel then
            ShovelThread = task.spawn(function()
                while AutoShovel do
                    local success, shoveled = pcall(ShovelPlants)
                    
                    if not success or not shoveled then
                        task.wait(1)
                    else
                        task.wait(0.1)
                    end
                end
            end)
        end
    end
    -- SHOVEL SPRINKLER FUNCTIONALITY
    local function RemoveSprinklers()
        local farm = GetFarm(LocalPlayer.Name)
        if not farm then
            showNotification("Farm not found!")
            return
        end
        
        if not pcall(EquipShovel) then
            showNotification("Failed to equip shovel!")
            return
        end
        
        local removedCount = 0
        
        for _, obj in ipairs(farm:GetDescendants()) do
            if obj:IsA("Model") and Whitelisted_Sprinklers[obj.Name] then
                pcall(function()
                    if GameEvents:FindFirstChild("DeleteObject") then
                        GameEvents.DeleteObject:FireServer(obj)
                        removedCount = removedCount + 1
                    end
                end)
                task.wait(0.1)
            end
        end
        
        if removedCount > 0 then
            showNotification("Removed " .. removedCount .. " sprinklers")
        end
    end

    local ShovelSprinklerThread
    local function StartAutoShovelSprinklers()
        if ShovelSprinklerThread then
            task.cancel(ShovelSprinklerThread)
            ShovelSprinklerThread = nil
        end
        
        if AutoShovelSprinklers then
            ShovelSprinklerThread = task.spawn(function()
                while AutoShovelSprinklers do
                    pcall(RemoveSprinklers)
                    task.wait(ShovelDelay)
                end
            end)
        end
    end

    -- FIXED DESTROY PLANTS FUNCTIONALITY
    local function DestroyPlants()
        local farm = GetFarm(LocalPlayer.Name)
        if not farm then
            showNotification("Farm not found!")
            return false
        end
        
        local important = farm:FindFirstChild("Important")
        if not important then
            showNotification("Important folder not found!")
            return false
        end
        
        local plantsPhysical = important:FindFirstChild("Plants_Physical")
        if not plantsPhysical then
            showNotification("Plants_Physical not found!")
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
            showNotification("Failed to equip shovel!")
            return false
        end
        
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
                    pcall(function()
                        if GameEvents:FindFirstChild("DeleteObject") then
                            GameEvents.DeleteObject:FireServer(plant)
                            destroyedCount = destroyedCount + 1
                        end
                    end)
                    task.wait(0.1)
                end
            end
        end
        
        if destroyedCount > 0 then
            showNotification("Destroyed " .. destroyedCount .. " plants")
            return true
        end
        
        return false
    end

    local DestroyPlantsThread
    local function StartAutoDestroyPlants()
        if DestroyPlantsThread then
            task.cancel(DestroyPlantsThread)
            DestroyPlantsThread = nil
        end
        
        if AutoDestroyPlants then
            DestroyPlantsThread = task.spawn(function()
                while AutoDestroyPlants do
                    local success, destroyed = pcall(DestroyPlants)
                    
                    if not success or not destroyed then
                        task.wait(1)
                    else
                        task.wait(0.1)
                    end
                end
            end)
        end
    end
    -- UI Creation
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "PunkTeamInfinite"
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 390, 0, 280)
    MainFrame.Position = UDim2.new(0.5, -195, 0.5, -140)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    MainFrame.BackgroundTransparency = 0.2
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Visible = false
    MainFrame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner", MainFrame)
    UICorner.CornerRadius = UDim.new(0, 8)

    local UIStroke = Instance.new("UIStroke", MainFrame)
    UIStroke.Color = Color3.fromRGB(255, 50, 50)
    UIStroke.Thickness = 2

    -- Title Bar
    local TitleBar = Instance.new("Frame", MainFrame)
    TitleBar.Size = UDim2.new(1, 0, 0, 22)
    TitleBar.Position = UDim2.new(0, 0, 0, 0)
    TitleBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    TitleBar.BackgroundTransparency = 0.3
    TitleBar.BorderSizePixel = 0

    local Title = Instance.new("TextLabel", TitleBar)
    Title.Size = UDim2.new(1, -80, 1, 0)
    Title.Position = UDim2.new(0, 70, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "PUNK TEAM INFINITE"
    Title.TextColor3 = Color3.new(1, 1, 1)
    Title.Font = Enum.Font.SourceSansBold
    Title.TextSize = 14

    -- Discord Button
    local DiscordBtn = Instance.new("TextButton", TitleBar)
    DiscordBtn.Size = UDim2.new(0, 60, 0, 18)
    DiscordBtn.Position = UDim2.new(0, 4, 0.5, -9)
    DiscordBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    DiscordBtn.Text = "DISCORD"
    DiscordBtn.TextColor3 = Color3.new(1, 1, 1)
    DiscordBtn.Font = Enum.Font.SourceSansBold
    DiscordBtn.TextSize = 10
    DiscordBtn.AutoButtonColor = false

    local DiscordCorner = Instance.new("UICorner", DiscordBtn)
    DiscordCorner.CornerRadius = UDim.new(0, 4)

    local DiscordStroke = Instance.new("UIStroke", DiscordBtn)
    DiscordStroke.Color = Color3.fromRGB(255, 50, 50)
    DiscordStroke.Thickness = 2

    DiscordBtn.MouseButton1Click:Connect(function()
        pcall(function()
            setclipboard("https://discord.gg/JxEjAtdgWD")
            showNotification("Discord link copied to clipboard!")
        end)
    end)

    DiscordBtn.MouseEnter:Connect(function()
        DiscordBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    end)

    DiscordBtn.MouseLeave:Connect(function()
        DiscordBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    end)

    -- Rarity Column
    local RarityFrame = Instance.new("Frame", MainFrame)
    RarityFrame.Size = UDim2.new(0, 60, 0, 230)
    RarityFrame.Position = UDim2.new(0, 0, 0, 22)
    RarityFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    RarityFrame.BackgroundTransparency = 0.3
    RarityFrame.BorderSizePixel = 0

    local RarityCorner = Instance.new("UICorner", RarityFrame)
    RarityCorner.CornerRadius = UDim.new(0, 6)

    local RarityLabel = Instance.new("TextLabel", RarityFrame)
    RarityLabel.Size = UDim2.new(1, 0, 0, 16)
    RarityLabel.Position = UDim2.new(0, 0, 0, 0)
    RarityLabel.BackgroundTransparency = 1
    RarityLabel.Text = "RARITY"
    RarityLabel.TextColor3 = Color3.new(1, 1, 1)
    RarityLabel.Font = Enum.Font.SourceSansBold
    RarityLabel.TextSize = 12

    local RarityList = Instance.new("ScrollingFrame", RarityFrame)
    RarityList.Size = UDim2.new(1, 0, 1, -16)
    RarityList.Position = UDim2.new(0, 0, 0, 16)
    RarityList.BackgroundTransparency = 1
    RarityList.CanvasSize = UDim2.new(0, 0, 0, 0)
    RarityList.ScrollBarThickness = 4

    local RarityLayout = Instance.new("UIListLayout", RarityList)
    RarityLayout.Padding = UDim.new(0, 2)
    RarityLayout.SortOrder = Enum.SortOrder.LayoutOrder
    -- Fruits Column
    local FruitsFrame = Instance.new("Frame", MainFrame)
    FruitsFrame.Size = UDim2.new(0, 110, 0, 230)
    FruitsFrame.Position = UDim2.new(0, 60, 0, 22)
    FruitsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    FruitsFrame.BackgroundTransparency = 0.3
    FruitsFrame.BorderSizePixel = 0

    local FruitsCorner = Instance.new("UICorner", FruitsFrame)
    FruitsCorner.CornerRadius = UDim.new(0, 6)

    local FruitsLabel = Instance.new("TextLabel", FruitsFrame)
    FruitsLabel.Size = UDim2.new(1, 0, 0, 16)
    FruitsLabel.Position = UDim2.new(0, 0, 0, 0)
    FruitsLabel.BackgroundTransparency = 1
    FruitsLabel.Text = "FRUITS"
    FruitsLabel.TextColor3 = Color3.new(1, 1, 1)
    FruitsLabel.Font = Enum.Font.SourceSansBold
    FruitsLabel.TextSize = 12

    local SearchBox = Instance.new("TextBox", FruitsFrame)
    SearchBox.Size = UDim2.new(1, -10, 0, 20)
    SearchBox.Position = UDim2.new(0, 5, 0, 16)
    SearchBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    SearchBox.TextColor3 = Color3.new(1, 1, 1)
    SearchBox.PlaceholderText = "Search fruits..."
    SearchBox.Font = Enum.Font.SourceSans
    SearchBox.TextSize = 14
    SearchBox.ClearTextOnFocus = false

    -- Fruits List Container
    local FruitsListContainer = Instance.new("Frame", FruitsFrame)
    FruitsListContainer.Size = UDim2.new(1, 0, 0, 130)
    FruitsListContainer.Position = UDim2.new(0, 0, 0, 36)
    FruitsListContainer.BackgroundTransparency = 1
    FruitsListContainer.Name = "FruitsListContainer"

    local FruitsList = Instance.new("ScrollingFrame", FruitsListContainer)
    FruitsList.Size = UDim2.new(1, 0, 1, 0)
    FruitsList.BackgroundTransparency = 1
    FruitsList.CanvasSize = UDim2.new(0, 0, 0, 0)
    FruitsList.ScrollBarThickness = 4
    FruitsList.Parent = FruitsListContainer

    -- Connect Fruits Search Box
    local function PopulateFruitsList(filter)
        FruitsList:ClearAllChildren()
        local yPos = 0
        for rarity, fruits in pairs(PlantData) do
            for _, fruit in ipairs(fruits) do
                if not filter or fruit:lower():find(filter:lower()) then
                    local btn = CreatePlantButton(fruit, rarity, yPos)
                    btn.Parent = FruitsList
                    yPos = yPos + 20
                end
            end
        end
        FruitsList.CanvasSize = UDim2.new(0, 0, 0, yPos)
    end

    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        PopulateFruitsList(SearchBox.Text)
    end)

    PopulateFruitsList()

-- Auto Shovel Sprinklers Toggle
local ShovelSprinklerToggle = ShovelSprinklerFrame:FindFirstChild("ShovelSprinklerToggle") or Instance.new("TextButton", ShovelSprinklerFrame)
ShovelSprinklerToggle.Size = UDim2.new(0.3, -5, 0.4, -5)
ShovelSprinklerToggle.Position = UDim2.new(0, 5, 0.3, 5)
ShovelSprinklerToggle.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
ShovelSprinklerToggle.Text = "OFF"
ShovelSprinklerToggle.TextColor3 = Color3.new(1, 1, 1)
ShovelSprinklerToggle.Font = Enum.Font.SourceSansBold
ShovelSprinklerToggle.TextSize = 12

ShovelSprinklerToggle.MouseButton1Click:Connect(function()
    AutoShovelSprinklers = not AutoShovelSprinklers
    if AutoShovelSprinklers then
        ShovelSprinklerToggle.Text = "ON"
        ShovelSprinklerToggle.BackgroundColor3 = Color3.fromRGB(40, 150, 40)
        StartAutoShovelSprinklers()
    else
        ShovelSprinklerToggle.Text = "OFF"
        ShovelSprinklerToggle.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
        if ShovelSprinklerThread then
            task.cancel(ShovelSprinklerThread)
            ShovelSprinklerThread = nil
        end
    end
end)

-- Auto Destroy Plants Toggle
local DestroyPlantsToggle = DestroyPlantsFrame:FindFirstChild("DestroyPlantsToggle") or Instance.new("TextButton", DestroyPlantsFrame)
DestroyPlantsToggle.Size = UDim2.new(0.3, -5, 0.4, -5)
DestroyPlantsToggle.Position = UDim2.new(0, 5, 0.3, 5)
DestroyPlantsToggle.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
DestroyPlantsToggle.Text = "OFF"
DestroyPlantsToggle.TextColor3 = Color3.new(1, 1, 1)
DestroyPlantsToggle.Font = Enum.Font.SourceSansBold
DestroyPlantsToggle.TextSize = 12

DestroyPlantsToggle.MouseButton1Click:Connect(function()
    AutoDestroyPlants = not AutoDestroyPlants
    if AutoDestroyPlants then
        DestroyPlantsToggle.Text = "ON"
        DestroyPlantsToggle.BackgroundColor3 = Color3.fromRGB(40, 150, 40)
        StartAutoDestroyPlants()
    else
        DestroyPlantsToggle.Text = "OFF"
        DestroyPlantsToggle.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
        if DestroyPlantsThread then
            task.cancel(DestroyPlantsThread)
            DestroyPlantsThread = nil
        end
    end
end)

-- Delay input for Shovel Sprinklers
DelayBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local val = tonumber(DelayBox.Text)
        if val and val >= 0 then
            ShovelDelay = val
            showNotification("Shovel delay set to " .. val .. " seconds")
        else
            DelayBox.Text = tostring(ShovelDelay)
            showNotification("Invalid delay value")
        end
    end
end)

-- Destruction threshold input
DestroyThresholdBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local val = tonumber(DestroyThresholdBox.Text)
        if val and val >= 0 then
            DestructionThreshold = val
            showNotification("Destroy threshold set to " .. val)
        else
            DestroyThresholdBox.Text = tostring(DestructionThreshold)
            showNotification("Invalid destroy threshold")
        end
    end
end)

-- Populate Sprinkler List
local function PopulateSprinklerList(filter)
    SprinklerList:ClearAllChildren()
    local yPos = 0
    for _, sprinkler in ipairs(SprinklerTypes) do
        if not filter or sprinkler:lower():find(filter:lower()) then
            local btn = CreateSprinklerButton(sprinkler, yPos)
            btn.Parent = SprinklerList
            yPos = yPos + 20
        end
    end
    SprinklerList.CanvasSize = UDim2.new(0, 0, 0, yPos)
end

SprinklerSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    PopulateSprinklerList(SprinklerSearchBox.Text)
end)

PopulateSprinklerList()

-- Populate Plants List
local function PopulatePlantsList(filter)
    PlantsList:ClearAllChildren()
    local yPos = 0
    for rarity, plants in pairs(PlantData) do
        for _, plant in ipairs(plants) do
            if not filter or plant:lower():find(filter:lower()) then
                local btn = CreatePlantDestructionButton(plant, rarity, yPos)
                btn.Parent = PlantsList
                yPos = yPos + 20
            end
        end
    end
    PlantsList.CanvasSize = UDim2.new(0, 0, 0, yPos)
end

PlantsSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    PopulatePlantsList(PlantsSearchBox.Text)
end)

PopulatePlantsList()

end, errorHandler)

if not success then
    warn("[PunkTeamInfinite] Script failed to run: " .. tostring(errorMsg))
end
