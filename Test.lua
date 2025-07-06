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

    -- Enhanced Countdown Notification
    local function showCountdownNotification(count)
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if not playerGui then return nil, nil end
        
        local screenGui = playerGui:FindFirstChild("PunkTeamInfinite") or Instance.new("ScreenGui")
        screenGui.Name = "PunkTeamInfinite"
        screenGui.Parent = playerGui
        
        for _, obj in ipairs(screenGui:GetChildren()) do
            if obj.Name == "CountdownNotification" then obj:Destroy() end
        end
        
        local notification = Instance.new("Frame")
        notification.Name = "CountdownNotification"
        notification.Size = UDim2.new(0, 400, 0, 80)
        notification.Position = UDim2.new(0.5, -200, 0.5, -40)
        notification.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        notification.BackgroundTransparency = 0.3
        notification.BorderSizePixel = 0
        notification.ZIndex = 100
        notification.Parent = screenGui
        
        local corner = Instance.new("UICorner", notification)
        corner.CornerRadius = UDim.new(0, 12)
        
        local stroke = Instance.new("UIStroke", notification)
        stroke.Color = Color3.fromRGB(255, 50, 50)
        stroke.Thickness = 3
        
        local label = Instance.new("TextLabel", notification)
        label.Size = UDim2.new(1, -20, 1, -20)
        label.Position = UDim2.new(0, 10, 0, 10)
        label.BackgroundTransparency = 1
        label.Text = "Loading plant data...\n" .. count .. " seconds remaining"
        label.TextColor3 = Color3.new(1, 1, 1)
        label.Font = Enum.Font.SourceSansBold
        label.TextSize = 24
        label.TextWrapped = true
        label.TextYAlignment = Enum.TextYAlignment.Center
        
        notification.BackgroundTransparency = 1
        label.TextTransparency = 1
        
        local fadeIn = TweenService:Create(notification, TweenInfo.new(0.5), {BackgroundTransparency = 0.3})
        local textFadeIn = TweenService:Create(label, TweenInfo.new(0.5), {TextTransparency = 0})
        fadeIn:Play()
        textFadeIn:Play()
        
        return notification, label
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
        
        -- FIX: Process all plants in the Plants_Physical folder
        for _, plant in ipairs(plantsPhysical:GetChildren()) do
            -- Check if this plant is in our whitelist
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

    -- FIXED DESTROY PLANTS FUNCTIONALITY (merged logic, using Remove_Item event on whole plants)
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
            
            -- Only check fruits if we have a destruction threshold
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
                    if GameEvents:FindFirstChild("Remove_Item") then
                        GameEvents.Remove_Item:FireServer(plant)
                        destroyedCount = destroyedCount + 1
                    end
                end)
                task.wait(0.1)
            end
        end
    end
    
    if destroyedCount > 0 then
        showNotification("Removed " .. destroyedCount .. " plants")
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

    -- Shovel Fruits Section
    local ShovelFruitsFrame = Instance.new("Frame", FruitsFrame)
    ShovelFruitsFrame.Size = UDim2.new(1, 0, 0, 64)
    ShovelFruitsFrame.Position = UDim2.new(0, 0, 0, 166)
    ShovelFruitsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    ShovelFruitsFrame.BackgroundTransparency = 0.5
    ShovelFruitsFrame.BorderSizePixel = 0
    ShovelFruitsFrame.Name = "ShovelFruits"

    local ShovelFruitsCorner = Instance.new("UICorner", ShovelFruitsFrame)
    ShovelFruitsCorner.CornerRadius = UDim.new(0, 6)

    local ShovelFruitsLabel = Instance.new("TextLabel", ShovelFruitsFrame)
    ShovelFruitsLabel.Size = UDim2.new(1, 0, 0.3, 0)
    ShovelFruitsLabel.Position = UDim2.new(0, 0, 0, 0)
    ShovelFruitsLabel.BackgroundTransparency = 1
    ShovelFruitsLabel.Text = "SHOVEL FRUITS"
    ShovelFruitsLabel.TextColor3 = Color3.new(1, 1, 1)
    ShovelFruitsLabel.Font = Enum.Font.SourceSansBold
    ShovelFruitsLabel.TextSize = 12

    local ShovelFruitsToggle = Instance.new("TextButton", ShovelFruitsFrame)
    ShovelFruitsToggle.Size = UDim2.new(0.3, -5, 0.4, -5)
    ShovelFruitsToggle.Position = UDim2.new(0, 5, 0.3, 5)
    ShovelFruitsToggle.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
    ShovelFruitsToggle.Text = "OFF"
    ShovelFruitsToggle.TextColor3 = Color3.new(1, 1, 1)
    ShovelFruitsToggle.Font = Enum.Font.SourceSansBold
    ShovelFruitsToggle.TextSize = 12

    local ThresholdLabel = Instance.new("TextLabel", ShovelFruitsFrame)
    ThresholdLabel.Size = UDim2.new(0.3, -5, 0.4, -5)
    ThresholdLabel.Position = UDim2.new(0.35, 5, 0.3, 5)
    ThresholdLabel.BackgroundTransparency = 1
    ThresholdLabel.Text = "Min/kg:"
    ThresholdLabel.TextColor3 = Color3.new(1, 1, 1)
    ThresholdLabel.Font = Enum.Font.SourceSans
    ThresholdLabel.TextSize = 12
    ThresholdLabel.TextXAlignment = Enum.TextXAlignment.Left

    local ThresholdBox = Instance.new("TextBox", ShovelFruitsFrame)
    ThresholdBox.Size = UDim2.new(0.3, -10, 0.4, -5)
    ThresholdBox.Position = UDim2.new(0.7, 5, 0.3, 5)
    ThresholdBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    ThresholdBox.Text = "200"
    ThresholdBox.TextColor3 = Color3.new(1, 1, 1)
    ThresholdBox.Font = Enum.Font.SourceSansBold
    ThresholdBox.TextSize = 12

    -- SPRINKLER Column
    local SettingsFrame = Instance.new("Frame", MainFrame)
    SettingsFrame.Size = UDim2.new(0, 110, 0, 230)
    SettingsFrame.Position = UDim2.new(0, 170, 0, 22)
    SettingsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    SettingsFrame.BackgroundTransparency = 0.3
    SettingsFrame.BorderSizePixel = 0

    local SettingsCorner = Instance.new("UICorner", SettingsFrame)
    SettingsCorner.CornerRadius = UDim.new(0, 6)

    local SettingsLabel = Instance.new("TextLabel", SettingsFrame)
    SettingsLabel.Size = UDim2.new(1, 0, 0, 16)
    SettingsLabel.Position = UDim2.new(0, 0, 0, 0)
    SettingsLabel.BackgroundTransparency = 1
    SettingsLabel.Text = "SPRINKLER"
    SettingsLabel.TextColor3 = Color3.new(1, 1, 1)
    SettingsLabel.Font = Enum.Font.SourceSansBold
    SettingsLabel.TextSize = 12

    local SprinklerSearchBox = Instance.new("TextBox", SettingsFrame)
    SprinklerSearchBox.Size = UDim2.new(1, -10, 0, 20)
    SprinklerSearchBox.Position = UDim2.new(0, 5, 0, 16)
    SprinklerSearchBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    SprinklerSearchBox.TextColor3 = Color3.new(1, 1, 1)
    SprinklerSearchBox.PlaceholderText = "Search sprinklers..."
    SprinklerSearchBox.Font = Enum.Font.SourceSans
    SprinklerSearchBox.TextSize = 14
    SprinklerSearchBox.ClearTextOnFocus = false

    -- Sprinkler List
    local SprinklerList = Instance.new("ScrollingFrame", SettingsFrame)
    SprinklerList.Size = UDim2.new(1, 0, 0, 130)
    SprinklerList.Position = UDim2.new(0, 0, 0, 36)
    SprinklerList.BackgroundTransparency = 1
    SprinklerList.CanvasSize = UDim2.new(0, 0, 0, 0)
    SprinklerList.ScrollBarThickness = 4

    -- Shovel Sprinkler Section
    local ShovelSprinklerFrame = Instance.new("Frame", SettingsFrame)
    ShovelSprinklerFrame.Size = UDim2.new(1, 0, 0, 64)
    ShovelSprinklerFrame.Position = UDim2.new(0, 0, 0, 166)
    ShovelSprinklerFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    ShovelSprinklerFrame.BackgroundTransparency = 0.5
    ShovelSprinklerFrame.BorderSizePixel = 0
    ShovelSprinklerFrame.Name = "ShovelSprinkler"

    local ShovelSprinklerCorner = Instance.new("UICorner", ShovelSprinklerFrame)
    ShovelSprinklerCorner.CornerRadius = UDim.new(0, 6)

    local ShovelSprinklerLabel = Instance.new("TextLabel", ShovelSprinklerFrame)
    ShovelSprinklerLabel.Size = UDim2.new(1, 0, 0.3, 0)
    ShovelSprinklerLabel.Position = UDim2.new(0, 0, 0, 0)
    ShovelSprinklerLabel.BackgroundTransparency = 1
    ShovelSprinklerLabel.Text = "SHOVEL SPRINKLER"
    ShovelSprinklerLabel.TextColor3 = Color3.new(1, 1, 1)
    ShovelSprinklerLabel.Font = Enum.Font.SourceSansBold
    ShovelSprinklerLabel.TextSize = 12

    local ShovelSprinklerToggle = Instance.new("TextButton", ShovelSprinklerFrame)
    ShovelSprinklerToggle.Size = UDim2.new(0.3, -5, 0.4, -5)
    ShovelSprinklerToggle.Position = UDim2.new(0, 5, 0.3, 5)
    ShovelSprinklerToggle.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
    ShovelSprinklerToggle.Text = "OFF"
    ShovelSprinklerToggle.TextColor3 = Color3.new(1, 1, 1)
    ShovelSprinklerToggle.Font = Enum.Font.SourceSansBold
    ShovelSprinklerToggle.TextSize = 12

    local DelayLabel = Instance.new("TextLabel", ShovelSprinklerFrame)
    DelayLabel.Size = UDim2.new(0.3, -5, 0.4, -5)
    DelayLabel.Position = UDim2.new(0.35, 5, 0.3, 5)
    DelayLabel.BackgroundTransparency = 1
    DelayLabel.Text = "Delay/s:"
    DelayLabel.TextColor3 = Color3.new(1, 1, 1)
    DelayLabel.Font = Enum.Font.SourceSans
    DelayLabel.TextSize = 12
    DelayLabel.TextXAlignment = Enum.TextXAlignment.Left

    local DelayBox = Instance.new("TextBox", ShovelSprinklerFrame)
    DelayBox.Size = UDim2.new(0.3, -10, 0.4, -5)
    DelayBox.Position = UDim2.new(0.7, 5, 0.3, 5)
    DelayBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    DelayBox.Text = "0"
    DelayBox.TextColor3 = Color3.new(1, 1, 1)
    DelayBox.Font = Enum.Font.SourceSansBold
    DelayBox.TextSize = 12

    -- PLANTS Column (for destroying entire plants)
    local PlantsFrame = Instance.new("Frame", MainFrame)
    PlantsFrame.Size = UDim2.new(0, 110, 0, 230)
    PlantsFrame.Position = UDim2.new(0, 280, 0, 22)
    PlantsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    PlantsFrame.BackgroundTransparency = 0.3
    PlantsFrame.BorderSizePixel = 0

    local PlantsCorner = Instance.new("UICorner", PlantsFrame)
    PlantsCorner.CornerRadius = UDim.new(0, 6)

    local PlantsLabel = Instance.new("TextLabel", PlantsFrame)
    PlantsLabel.Size = UDim2.new(1, 0, 0, 16)
    PlantsLabel.Position = UDim2.new(0, 0, 0, 0)
    PlantsLabel.BackgroundTransparency = 1
    PlantsLabel.Text = "PLANTS"
    PlantsLabel.TextColor3 = Color3.new(1, 1, 1)
    PlantsLabel.Font = Enum.Font.SourceSansBold
    PlantsLabel.TextSize = 12

    local PlantsSearchBox = Instance.new("TextBox", PlantsFrame)
    PlantsSearchBox.Size = UDim2.new(1, -10, 0, 20)
    PlantsSearchBox.Position = UDim2.new(0, 5, 0, 16)
    PlantsSearchBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    PlantsSearchBox.TextColor3 = Color3.new(1, 1, 1)
    PlantsSearchBox.PlaceholderText = "Search plants..."
    PlantsSearchBox.Font = Enum.Font.SourceSans
    PlantsSearchBox.TextSize = 14
    PlantsSearchBox.ClearTextOnFocus = false

    -- Plants List Container
    local PlantsListContainer = Instance.new("Frame", PlantsFrame)
    PlantsListContainer.Size = UDim2.new(1, 0, 0, 130)
    PlantsListContainer.Position = UDim2.new(0, 0, 0, 36)
    PlantsListContainer.BackgroundTransparency = 1
    PlantsListContainer.Name = "PlantsListContainer"

    local PlantsList = Instance.new("ScrollingFrame", PlantsListContainer)
    PlantsList.Size = UDim2.new(1, 0, 1, 0)
    PlantsList.BackgroundTransparency = 1
    PlantsList.CanvasSize = UDim2.new(0, 0, 0, 0)
    PlantsList.ScrollBarThickness = 4
    PlantsList.Parent = PlantsListContainer

    -- Destroy Plants Section (FIXED)
    local DestroyPlantsFrame = Instance.new("Frame", PlantsFrame)
    DestroyPlantsFrame.Size = UDim2.new(1, 0, 0, 64)
    DestroyPlantsFrame.Position = UDim2.new(0, 0, 0, 166)
    DestroyPlantsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    DestroyPlantsFrame.BackgroundTransparency = 0.5
    DestroyPlantsFrame.BorderSizePixel = 0
    DestroyPlantsFrame.Name = "DestroyPlants"

    local DestroyPlantsCorner = Instance.new("UICorner", DestroyPlantsFrame)
    DestroyPlantsCorner.CornerRadius = UDim.new(0, 6)

    local DestroyPlantsLabel = Instance.new("TextLabel", DestroyPlantsFrame)
    DestroyPlantsLabel.Size = UDim2.new(1, 0, 0.3, 0)
    DestroyPlantsLabel.Position = UDim2.new(0, 0, 0, 0)
    DestroyPlantsLabel.BackgroundTransparency = 1
    DestroyPlantsLabel.Text = "DESTROY PLANTS"
    DestroyPlantsLabel.TextColor3 = Color3.new(1, 1, 1)
    DestroyPlantsLabel.Font = Enum.Font.SourceSansBold
    DestroyPlantsLabel.TextSize = 12

    local DestroyPlantsToggle = Instance.new("TextButton", DestroyPlantsFrame)
    DestroyPlantsToggle.Size = UDim2.new(0.3, -5, 0.4, -5)
    DestroyPlantsToggle.Position = UDim2.new(0, 5, 0.3, 5)
    DestroyPlantsToggle.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
    DestroyPlantsToggle.Text = "OFF"
    DestroyPlantsToggle.TextColor3 = Color3.new(1, 1, 1)
    DestroyPlantsToggle.Font = Enum.Font.SourceSansBold
    DestroyPlantsToggle.TextSize = 12

    -- Min/kg input for destruction threshold
    local DestroyThresholdLabel = Instance.new("TextLabel", DestroyPlantsFrame)
    DestroyThresholdLabel.Size = UDim2.new(0.3, -5, 0.4, -5)
    DestroyThresholdLabel.Position = UDim2.new(0.35, 5, 0.3, 5)
    DestroyThresholdLabel.BackgroundTransparency = 1
    DestroyThresholdLabel.Text = "Min/kg:"
    DestroyThresholdLabel.TextColor3 = Color3.new(1, 1, 1)
    DestroyThresholdLabel.Font = Enum.Font.SourceSans
    DestroyThresholdLabel.TextSize = 12
    DestroyThresholdLabel.TextXAlignment = Enum.TextXAlignment.Left

    local DestroyThresholdBox = Instance.new("TextBox", DestroyPlantsFrame)
    DestroyThresholdBox.Size = UDim2.new(0.3, -10, 0.4, -5)
    DestroyThresholdBox.Position = UDim2.new(0.7, 5, 0.3, 5)
    DestroyThresholdBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    DestroyThresholdBox.Text = "0"
    DestroyThresholdBox.TextColor3 = Color3.new(1, 1, 1)
    DestroyThresholdBox.Font = Enum.Font.SourceSansBold
    DestroyThresholdBox.TextSize = 12

    -- Toggle UI Button
    local ToggleBtn = Instance.new("ImageButton", ScreenGui)
    ToggleBtn.Name = "ShowHideESPBtn"
    ToggleBtn.Size = UDim2.new(0, 38, 0, 38)
    ToggleBtn.Position = UDim2.new(0, 6, 0, 6)
    ToggleBtn.BackgroundTransparency = 1
    ToggleBtn.Image = "rbxassetid://131613009113138"
    ToggleBtn.ZIndex = 100

    local bg = Instance.new("Frame", ToggleBtn)
    bg.Name = "Background"
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bg.BackgroundTransparency = 0.15
    bg.ZIndex = 99

    local corner = Instance.new("UICorner", bg)
    corner.CornerRadius = UDim.new(1, 0)

    local stroke = Instance.new("UIStroke", bg)
    stroke.Color = Color3.fromRGB(255, 50, 50)
    stroke.Thickness = 2

    local glow = Instance.new("ImageLabel", ToggleBtn)
    glow.Name = "Glow"
    glow.Size = UDim2.new(1, 20, 1, 20)
    glow.Position = UDim2.new(0, -10, 0, -10)
    glow.Image = "rbxassetid://5028857084"
    glow.ImageColor3 = Color3.fromRGB(255, 50, 50)
    glow.ScaleType = Enum.ScaleType.Slice
    glow.SliceCenter = Rect.new(24, 24, 276, 276)
    glow.BackgroundTransparency = 1
    glow.ZIndex = 98
    glow.Visible = false

    -- Plant Button Creation (for fruits)
    local function CreatePlantButton(plant, rarity, yPosition)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 18)
        btn.Position = UDim2.new(0, 5, 0, yPosition)
        btn.BackgroundColor3 = RarityColors[rarity]
        btn.Text = plant
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.SourceSansBold
        btn.TextSize = 12
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.AutoButtonColor = false
        
        local padding = Instance.new("UIPadding", btn)
        padding.PaddingLeft = UDim.new(0, 5)
        
        if Whitelisted_Plants[plant] then
            btn.BackgroundTransparency = 0.3
        else
            btn.BackgroundTransparency = 0.7
        end
        
        btn.MouseButton1Click:Connect(function()
            Whitelisted_Plants[plant] = not Whitelisted_Plants[plant]
            
            if Whitelisted_Plants[plant] then
                btn.BackgroundTransparency = 0.3
                showNotification(plant .. " selected for shovel")
            else
                btn.BackgroundTransparency = 0.7
                showNotification(plant .. " removed from shovel list")
            end
        end)
        
        return btn
    end

    -- Plant Button Creation (for destroying plants)
    local function CreatePlantDestructionButton(plant, rarity, yPosition)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 18)
        btn.Position = UDim2.new(0, 5, 0, yPosition)
        btn.BackgroundColor3 = RarityColors[rarity]
        btn.Text = plant
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.SourceSansBold
        btn.TextSize = 12
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.AutoButtonColor = false
        
        local padding = Instance.new("UIPadding", btn)
        padding.PaddingLeft = UDim.new(0, 5)
        
        if Whitelisted_PlantsForDestruction[plant] then
            btn.BackgroundTransparency = 0.3
        else
            btn.BackgroundTransparency = 0.7
        end
        
        btn.MouseButton1Click:Connect(function()
            Whitelisted_PlantsForDestruction[plant] = not Whitelisted_PlantsForDestruction[plant]
            
            if Whitelisted_PlantsForDestruction[plant] then
                btn.BackgroundTransparency = 0.3
                showNotification(plant .. " selected for destruction")
            else
                btn.BackgroundTransparency = 0.7
                showNotification(plant .. " removed from destruction list")
            end
        end)
        
        return btn
    end

    -- Sprinkler Button Creation
    local function CreateSprinklerButton(sprinkler, yPosition)
        local displayName = sprinkler:gsub(" Sprinkler", "")
        
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 18)
        btn.Position = UDim2.new(0, 5, 0, yPosition)
        btn.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
        btn.Text = displayName
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.SourceSansBold
        btn.TextSize = 12
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.AutoButtonColor = false
        
        local padding = Instance.new("UIPadding", btn)
        padding.PaddingLeft = UDim.new(0, 5)
        
        if Whitelisted_Sprinklers[sprinkler] then
            btn.BackgroundTransparency = 0.3
        else
            btn.BackgroundTransparency = 0.7
        end
        
        btn.MouseButton1Click:Connect(function()
            Whitelisted_Sprinklers[sprinkler] = not Whitelisted_Sprinklers[sprinkler]
            
            if Whitelisted_Sprinklers[sprinkler] then
                btn.BackgroundTransparency = 0.3
                showNotification(displayName .. " selected for removal")
            else
                btn.BackgroundTransparency = 0.7
                showNotification(displayName .. " removed from removal list")
            end
        end)
        
        return btn
    end

    -- Plant Display Functions for fruits
    local function ShowAllFruits()
        FruitsList:ClearAllChildren()
        local yPosition = 0
        local rowHeight = 20
        
        for _, rarity in ipairs(RarityOrder) do
            local plants = PlantData[rarity]
            for _, plant in ipairs(plants) do
                local btn = CreatePlantButton(plant, rarity, yPosition)
                btn.Parent = FruitsList
                yPosition = yPosition + rowHeight
            end
        end
        
        FruitsList.CanvasSize = UDim2.new(0, 0, 0, yPosition)
    end

    -- FIXED: Added rarity filtering for FRUITS column
    local function ShowFruitsByRarity(rarity)
        FruitsList:ClearAllChildren()
        local yPosition = 0
        local rowHeight = 20
        
        local plants = PlantData[rarity] or {}
        for _, plant in ipairs(plants) do
            local btn = CreatePlantButton(plant, rarity, yPosition)
            btn.Parent = FruitsList
            yPosition = yPosition + rowHeight
        end
        
        FruitsList.CanvasSize = UDim2.new(0, 0, 0, yPosition)
    end

    -- FIXED: Added search for FRUITS column
    local function SearchFruits(searchTerm)
        FruitsList:ClearAllChildren()
        local yPosition = 0
        local rowHeight = 20
        
        if searchTerm == "" then
            for _, btn in ipairs(RarityList:GetChildren()) do
                if btn:IsA("TextButton") and btn.BackgroundTransparency == 0.1 then
                    ShowFruitsByRarity(btn.Text)
                    return
                end
            end
            ShowAllFruits()
            return
        end
        
        for _, rarity in ipairs(RarityOrder) do
            local plants = PlantData[rarity]
            for _, plant in ipairs(plants) do
                if string.find(string.lower(plant), string.lower(searchTerm)) then
                    local btn = CreatePlantButton(plant, rarity, yPosition)
                    btn.Parent = FruitsList
                    yPosition = yPosition + rowHeight
                end
            end
        end
        
        FruitsList.CanvasSize = UDim2.new(0, 0, 0, yPosition)
    end

    -- Plant Display Functions for plant destruction
    local function ShowAllPlantsForDestruction()
        PlantsList:ClearAllChildren()
        local yPosition = 0
        local rowHeight = 20
        
        for _, rarity in ipairs(RarityOrder) do
            local plants = PlantData[rarity]
            for _, plant in ipairs(plants) do
                local btn = CreatePlantDestructionButton(plant, rarity, yPosition)
                btn.Parent = PlantsList
                yPosition = yPosition + rowHeight
            end
        end
        
        PlantsList.CanvasSize = UDim2.new(0, 0, 0, yPosition)
    end

    local function ShowPlantsByRarityForDestruction(rarity)
        PlantsList:ClearAllChildren()
        local yPosition = 0
        local rowHeight = 20
        
        local plants = PlantData[rarity] or {}
        for _, plant in ipairs(plants) do
            local btn = CreatePlantDestructionButton(plant, rarity, yPosition)
            btn.Parent = PlantsList
            yPosition = yPosition + rowHeight
        end
        
        PlantsList.CanvasSize = UDim2.new(0, 0, 0, yPosition)
    end

    local function SearchPlantsForDestruction(searchTerm)
        PlantsList:ClearAllChildren()
        local yPosition = 0
        local rowHeight = 20
        
        if searchTerm == "" then
            for _, btn in ipairs(RarityList:GetChildren()) do
                if btn:IsA("TextButton") and btn.BackgroundTransparency == 0.1 then
                    ShowPlantsByRarityForDestruction(btn.Text)
                    return
                end
            end
            ShowAllPlantsForDestruction()
            return
        end
        
        for _, rarity in ipairs(RarityOrder) do
            local plants = PlantData[rarity]
            for _, plant in ipairs(plants) do
                if string.find(string.lower(plant), string.lower(searchTerm)) then
                    local btn = CreatePlantDestructionButton(plant, rarity, yPosition)
                    btn.Parent = PlantsList
                    yPosition = yPosition + rowHeight
                end
            end
        end
        
        PlantsList.CanvasSize = UDim2.new(0, 0, 0, yPosition)
    end

    -- Populate sprinkler list
    local function PopulateSprinklerList()
        SprinklerList:ClearAllChildren()
        local yPosition = 0
        local rowHeight = 20
        
        for _, sprinkler in ipairs(SprinklerTypes) do
            local btn = CreateSprinklerButton(sprinkler, yPosition)
            btn.Parent = SprinklerList
            yPosition = yPosition + rowHeight
        end
        
        SprinklerList.CanvasSize = UDim2.new(0, 0, 0, yPosition)
    end

    -- Search handler for sprinklers
    SprinklerSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local searchTerm = string.lower(SprinklerSearchBox.Text)
        SprinklerList:ClearAllChildren()
        local yPosition = 0
        local rowHeight = 20
        
        for _, sprinkler in ipairs(SprinklerTypes) do
            if searchTerm == "" or string.find(string.lower(sprinkler), searchTerm) then
                local btn = CreateSprinklerButton(sprinkler, yPosition)
                btn.Parent = SprinklerList
                yPosition = yPosition + rowHeight
            end
        end
        
        SprinklerList.CanvasSize = UDim2.new(0, 0, 0, yPosition)
    end)

    -- FIXED: Added search handler for fruits
    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        SearchFruits(SearchBox.Text)
    end)

    -- Search handler for plant destruction
    PlantsSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        SearchPlantsForDestruction(PlantsSearchBox.Text)
    end)

    -- Populate Rarity List
    for _, rarity in ipairs(RarityOrder) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 20)
        btn.BackgroundColor3 = RarityColors[rarity]
        btn.BackgroundTransparency = 0.3
        btn.Text = rarity
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.SourceSansBold
        btn.TextSize = 12
        btn.Parent = RarityList
        
        local padding = Instance.new("UIPadding", btn)
        padding.PaddingLeft = UDim.new(0, 5)
    end

    -- Rarity selection handler (UPDATED to handle both columns)
    for _, btn in ipairs(RarityList:GetChildren()) do
        if btn:IsA("TextButton") then
            btn.MouseButton1Click:Connect(function()
                for _, otherBtn in ipairs(RarityList:GetChildren()) do
                    if otherBtn:IsA("TextButton") then
                        otherBtn.BackgroundTransparency = 0.3
                    end
                end
                
                btn.BackgroundTransparency = 0.1
                -- Update both columns
                ShowPlantsByRarityForDestruction(btn.Text)
                ShowFruitsByRarity(btn.Text)
            end)
        end
    end

    -- Shovel Fruits Toggle
    ShovelFruitsToggle.MouseButton1Click:Connect(function()
        AutoShovel = not AutoShovel
        
        if AutoShovel then
            ShovelFruitsToggle.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
            ShovelFruitsToggle.Text = "ON"
            showNotification("Auto Shovel: ON")
            StartAutoShovel()
        else
            ShovelFruitsToggle.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
            ShovelFruitsToggle.Text = "OFF"
            showNotification("Auto Shovel: OFF")
            -- Immediately stop shovel thread
            if ShovelThread then
                task.cancel(ShovelThread)
                ShovelThread = nil
            end
        end
    end)

    -- Shovel Sprinkler Toggle
    ShovelSprinklerToggle.MouseButton1Click:Connect(function()
        AutoShovelSprinklers = not AutoShovelSprinklers
        
        if AutoShovelSprinklers then
            ShovelSprinklerToggle.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
            ShovelSprinklerToggle.Text = "ON"
            showNotification("Auto Shovel Sprinklers: ON")
            StartAutoShovelSprinklers()
        else
            ShovelSprinklerToggle.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
            ShovelSprinklerToggle.Text = "OFF"
            showNotification("Auto Shovel Sprinklers: OFF")
            -- Immediately stop shovel sprinkler thread
            if ShovelSprinklerThread then
                task.cancel(ShovelSprinklerThread)
                ShovelSprinklerThread = nil
            end
        end
    end)

    -- Destroy Plants Toggle
    DestroyPlantsToggle.MouseButton1Click:Connect(function()
        AutoDestroyPlants = not AutoDestroyPlants
        
        if AutoDestroyPlants then
            DestroyPlantsToggle.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
            DestroyPlantsToggle.Text = "ON"
            showNotification("Auto Destroy Plants: ON")
            StartAutoDestroyPlants()
        else
            DestroyPlantsToggle.BackgroundColor3 = Color3.fromRGB(150, 40, 80)
            DestroyPlantsToggle.Text = "OFF"
            showNotification("Auto Destroy Plants: OFF")
            -- Immediately stop destroy plants thread
            if DestroyPlantsThread then
                task.cancel(DestroyPlantsThread)
                DestroyPlantsThread = nil
            end
        end
    end)

    -- Threshold box handler
    ThresholdBox.FocusLost:Connect(function()
        local threshold = tonumber(ThresholdBox.Text)
        if threshold and threshold >= 0 then
            ShovelWeightThreshold = threshold
            ThresholdBox.Text = tostring(threshold)
            showNotification("Min weight set to: " .. threshold)
        else
            ThresholdBox.Text = tostring(ShovelWeightThreshold)
        end
    end)

    -- FIXED: Added threshold handler for destruction
    DestroyThresholdBox.FocusLost:Connect(function()
        local threshold = tonumber(DestroyThresholdBox.Text)
        if threshold and threshold >= 0 then
            DestructionThreshold = threshold
            DestroyThresholdBox.Text = tostring(threshold)
            showNotification("Destruction threshold set to: " .. threshold)
        else
            DestroyThresholdBox.Text = tostring(DestructionThreshold)
        end
    end)

    -- Delay box handler
    DelayBox.FocusLost:Connect(function()
        local delay = tonumber(DelayBox.Text)
        if delay and delay >= 0 then
            ShovelDelay = delay
            DelayBox.Text = tostring(delay)
            showNotification("Delay set to: " .. delay .. " seconds")
            if AutoShovelSprinklers then
                StartAutoShovelSprinklers()
            end
        else
            DelayBox.Text = tostring(ShovelDelay)
        end
    end)

    -- Toggle UI Visibility
    local uiVisible = false
    local firstTimeOpen = true

    ToggleBtn.MouseButton1Click:Connect(function()
        uiVisible = not uiVisible
        MainFrame.Visible = uiVisible
        
        glow.Visible = true
        local pulse = TweenService:Create(
            glow,
            TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, true),
            {ImageTransparency = 0.5}
        )
        pulse:Play()
        
        local rotationTween = TweenService:Create(
            ToggleBtn,
            TweenInfo.new(0.3, Enum.EasingStyle.Quint),
            {Rotation = uiVisible and 0 or 180}
        )
        rotationTween:Play()
        
        task.delay(0.6, function()
            glow.Visible = false
        end)
        
        if uiVisible and firstTimeOpen then
            firstTimeOpen = false
            
            local count = 10
            local notification, label = showCountdownNotification(count)
            
            task.spawn(function()
                while count > 0 and uiVisible do
                    task.wait(1)
                    count = count - 1
                    if count > 0 then
                        label.Text = "Loading plant data... " .. count .. " seconds remaining"
                    else
                        label.Text = "Plant data loaded!"
                    end
                end
                
                task.wait(2)
                
                local fadeOut = TweenService:Create(notification, TweenInfo.new(0.5), {BackgroundTransparency = 1})
                local textFadeOut = TweenService:Create(label, TweenInfo.new(0.5), {TextTransparency = 1})
                fadeOut:Play()
                textFadeOut:Play()
                
                fadeOut.Completed:Wait()
                notification:Destroy()
            end)
        end
    end)

    -- Initialize
    ShowAllFruits()
    ShowAllPlantsForDestruction()
    PopulateSprinklerList()
    showNotification("Punk Team Infinite Script Loaded!")

end, errorHandler)

if not success then
    warn("[PunkTeamInfinite CRITICAL ERROR] Script failed to initialize: " .. tostring(errorMsg))
end
