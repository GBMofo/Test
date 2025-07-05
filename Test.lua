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
local AutoHarvest = false
local AutoSubmit = false
local AutoShovel = false
local AutoShovelSprinklers = false
local HarvestRate = 20  -- Default: 20 plants per second
local SubmitInterval = 5  -- seconds
local ShovelWeightThreshold = 200
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
        -- Try to find the controller in the game environment
        for _, module in pairs(getloadedmodules()) do
            if module.Name == "ProximityPromptController" then
                ProximityPromptController = require(module)
                break
            end
        end
        
        -- If not found, create a mock controller
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
    -- Throttle notifications to prevent spam
    if os.clock() - LastNotificationTime < 1 then return end
    LastNotificationTime = os.clock()
    
    local screenGui = LocalPlayer.PlayerGui:FindFirstChild("PunkTeamInfinite")
    if not screenGui then return end
    
    for _, obj in ipairs(screenGui:GetChildren()) do
        if obj.Name == "Notification" then
            obj:Destroy()
        end
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
    
    local fadeIn = TweenService:Create(
        notification,
        TweenInfo.new(0.5),
        {BackgroundTransparency = 0.3}
    )
    
    local textFadeIn = TweenService:Create(
        label,
        TweenInfo.new(0.5),
        {TextTransparency = 0}
    )
    
    fadeIn:Play()
    textFadeIn:Play()
    
    wait(3)
    
    local fadeOut = TweenService:Create(
        notification,
        TweenInfo.new(0.5),
        {BackgroundTransparency = 1}
    )
    
    local textFadeOut = TweenService:Create(
        label,
        TweenInfo.new(0.5),
        {TextTransparency = 1}
    )
    
    fadeOut:Play()
    textFadeOut:Play()
    
    fadeOut.Completed:Wait()
    notification:Destroy()
end

-- Countdown Notification System
local function showCountdownNotification(count)
    local screenGui = LocalPlayer.PlayerGui:FindFirstChild("PunkTeamInfinite")
    if not screenGui then return end
    
    -- Remove any existing countdown notification
    for _, obj in ipairs(screenGui:GetChildren()) do
        if obj.Name == "CountdownNotification" then
            obj:Destroy()
        end
    end
    
    -- Create the notification frame
    local notification = Instance.new("Frame")
    notification.Name = "CountdownNotification"
    notification.Size = UDim2.new(0, 300, 0, 50)
    notification.Position = UDim2.new(0.5, -150, 0.3, 0)
    notification.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    notification.BackgroundTransparency = 0.3
    notification.BorderSizePixel = 0
    notification.ZIndex = 100
    notification.Parent = screenGui
    
    -- Rounded corners
    local corner = Instance.new("UICorner", notification)
    corner.CornerRadius = UDim.new(0, 8)
    
    -- Red border stroke
    local stroke = Instance.new("UIStroke", notification)
    stroke.Color = Color3.fromRGB(255, 50, 50)
    stroke.Thickness = 2
    
    -- Text label inside notification
    local label = Instance.new("TextLabel", notification)
    label.Size = UDim2.new(1, -10, 1, -10)
    label.Position = UDim2.new(0, 5, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = "Loading plant data... " .. count .. " seconds remaining"
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 18
    label.TextWrapped = true
    
    -- Start fully transparent for fade-in effect
    notification.BackgroundTransparency = 1
    label.TextTransparency = 1
    
    -- Tween to fade in background and text
    local fadeIn = TweenService:Create(notification, TweenInfo.new(0.5), {BackgroundTransparency = 0.3})
    local textFadeIn = TweenService:Create(label, TweenInfo.new(0.5), {TextTransparency = 0})
    fadeIn:Play()
    textFadeIn:Play()
    
    return notification, label
end

-- Farm Functions
local function GetFarmOwner(Farm)
    local Important = Farm:FindFirstChild("Important")
    if not Important then return end
    local Data = Important:FindFirstChild("Data")
    if not Data then return end
    local Owner = Data:FindFirstChild("Owner")
    if not Owner then return end
    return Owner.Value
end

local function GetFarm(PlayerName)
    local Farms = Farms:GetChildren()
    for _, Farm in next, Farms do
        local Owner = GetFarmOwner(Farm)
        if Owner == PlayerName then
            return Farm
        end
    end
    return nil
end

local MyFarm = GetFarm(LocalPlayer.Name)
local PlantsPhysical = MyFarm and MyFarm.Important:FindFirstChild("Plants_Physical")

-- Plant Harvesting Functions
local function CanHarvest(Plant)
    local Prompt = Plant:FindFirstChild("ProximityPrompt", true)
    if not Prompt then return false end
    if not Prompt.Enabled then return false end
    return true
end

-- ULTIMATE HARVEST FIX: Works from any distance
local function HarvestPlant(Plant)
    if not Whitelisted_Plants[Plant.Name] then return end
    
    local controller = GetProximityPromptController()
    local disabler = {}  -- Unique disabler object
    
    -- Disable proximity prompts globally
    controller.AddDisabler("AutoHarvest", disabler)
    
    -- Harvest the plant
    local Prompt = Plant:FindFirstChild("ProximityPrompt", true)
    if Prompt then
        fireproximityprompt(Prompt)
    end
    
    -- Re-enable proximity prompts
    controller.RemoveDisabler("AutoHarvest", disabler)
end

local function CollectHarvestable(Parent, Plants)
    for _, Plant in next, Parent:GetChildren() do
        if Plant:IsA("Model") then
            if CanHarvest(Plant) then
                table.insert(Plants, Plant)
            end
            
            local Fruits = Plant:FindFirstChild("Fruits")
            if Fruits then
                CollectHarvestable(Fruits, Plants)
            end
        end
    end
    return Plants
end

local function GetHarvestablePlants()
    local Plants = {}
    if PlantsPhysical then
        CollectHarvestable(PlantsPhysical, Plants)
    end
    return Plants
end

local function HarvestPlants()
    if not PlantsPhysical then return end
    
    local Plants = GetHarvestablePlants()
    if #Plants == 0 then return end
    
    for _, Plant in next, Plants do
        HarvestPlant(Plant)
        task.wait(1 / HarvestRate)
    end
end

-- Improved auto systems with dedicated threads
local HarvestThread
local SubmitThread
local ShovelThread
local ShovelSprinklerThread

local function StartAutoHarvest()
    if HarvestThread then
        task.cancel(HarvestThread)
        HarvestThread = nil
    end
    
    if AutoHarvest then
        HarvestThread = task.spawn(function()
            while AutoHarvest do
                pcall(HarvestPlants)
                task.wait(0.05)  -- Faster polling for immediate response
            end
        end)
    end
end

-- Auto submit without notification
local function StartAutoSubmit()
    if SubmitThread then
        task.cancel(SubmitThread)
        SubmitThread = nil
    end
    
    if AutoSubmit then
        SubmitThread = task.spawn(function()
            while AutoSubmit do
                pcall(function()
                    GameEvents.SummerHarvestRemoteEvent:FireServer("SubmitAllPlants")
                end)
                task.wait(SubmitInterval)
            end
        end)
    end
end

-- SHOVEL PLANTS FUNCTIONALITY
local function EquipShovel()
    local character = LocalPlayer.Character
    if not character then return false end
    
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return false end
    
    -- Find shovel in character or backpack
    local shovelTool = character:FindFirstChild("Shovel [Destroy Plants]") or backpack:FindFirstChild("Shovel [Destroy Plants]")
    if not shovelTool then
        showNotification("Shovel not found in inventory!")
        return false
    end
    
    -- Move to character if in backpack
    if shovelTool.Parent == backpack then
        shovelTool.Parent = character
    end
    
    -- Equip the shovel
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid:EquipTool(shovelTool)
        return true
    end
    
    return false
end

-- Function to remove fruits below weight threshold
local function RemoveFruitsRecursively(parent, threshold)
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("BasePart") then
            local fruitModel = child.Parent
            local weightValue = fruitModel and fruitModel:FindFirstChild("Weight")
            local weight = (weightValue and weightValue:IsA("NumberValue")) and weightValue.Value or math.huge

            if weight < threshold then
                -- Fire the removal event
                GameEvents.Remove_Item:FireServer(child)
                task.wait(0.1)  -- Small delay between removals
            end
        elseif child:IsA("Model") or child:IsA("Folder") then
            RemoveFruitsRecursively(child, threshold)
        end
    end
end

-- Main shovel function
local function ShovelPlants()
    -- Get player's farm
    local farm = GetFarm(LocalPlayer.Name)
    if not farm then
        showNotification("Farm not found!")
        return
    end
    
    local important = farm:FindFirstChild("Important")
    if not important then
        showNotification("Important folder not found!")
        return
    end
    
    local plantsPhysical = important:FindFirstChild("Plants_Physical")
    if not plantsPhysical then
        showNotification("Plants_Physical not found!")
        return
    end
    
    -- Equip shovel first
    if not EquipShovel() then return end
    
    -- Process all whitelisted plants
    for plantName in pairs(Whitelisted_Plants) do
        local plant = plantsPhysical:FindFirstChild(plantName)
        if plant then
            local fruitsFolder = plant:FindFirstChild("Fruits")
            if fruitsFolder then
                RemoveFruitsRecursively(fruitsFolder, ShovelWeightThreshold)
            end
        end
    end
end

-- Start/stop auto shovel
local function StartAutoShovel()
    if ShovelThread then
        task.cancel(ShovelThread)
        ShovelThread = nil
    end
    
    if AutoShovel then
        ShovelThread = task.spawn(function()
            while AutoShovel do
                pcall(ShovelPlants)
                task.wait(SubmitInterval)  -- Use SubmitInterval for shovel plants
            end
        end)
    end
end

-- SHOVEL SPRINKLER FUNCTIONALITY
local function RemoveSprinklers()
    -- Get player's farm
    local farm = GetFarm(LocalPlayer.Name)
    if not farm then
        showNotification("Farm not found!")
        return
    end
    
    -- Equip shovel first
    if not EquipShovel() then return end
    
    local removedCount = 0
    
    -- Search for sprinklers in the farm
    for _, obj in ipairs(farm:GetDescendants()) do
        if obj:IsA("Model") and Whitelisted_Sprinklers[obj.Name] then
            GameEvents.DeleteObject:FireServer(obj)
            removedCount = removedCount + 1
            task.wait(0.1)  -- Small delay between removals
        end
    end
    
    if removedCount > 0 then
        showNotification("Removed " .. removedCount .. " sprinklers")
    end
end

-- Start/stop auto shovel sprinklers
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

-- UI Creation
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PunkTeamInfinite"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Smaller UI size as requested
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 280)  -- Smaller size
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -140)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BackgroundTransparency = 0.2
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Visible = false  -- Start hidden
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
Title.Text = "PUNK TEAM INFINITE SPRINKLER"
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
    setclipboard("https://discord.gg/JxEjAtdgWD")
    showNotification("Discord link copied to clipboard!")
end)

DiscordBtn.MouseEnter:Connect(function()
    DiscordBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
end)

DiscordBtn.MouseLeave:Connect(function()
    DiscordBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
end)

-- Rarity Column
local RarityFrame = Instance.new("Frame", MainFrame)
RarityFrame.Size = UDim2.new(0, 60, 0, 230)  -- Adjusted size
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

-- Plants Column
local PlantsFrame = Instance.new("Frame", MainFrame)
PlantsFrame.Size = UDim2.new(0, 100, 0, 230)  -- Adjusted size
PlantsFrame.Position = UDim2.new(0, 60, 0, 22)
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

local SearchBox = Instance.new("TextBox", PlantsFrame)
SearchBox.Size = UDim2.new(1, -10, 0, 20)
SearchBox.Position = UDim2.new(0, 5, 0, 16)
SearchBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
SearchBox.TextColor3 = Color3.new(1, 1, 1)
SearchBox.PlaceholderText = "Search plants..."
SearchBox.Font = Enum.Font.SourceSans
SearchBox.TextSize = 14
SearchBox.ClearTextOnFocus = false

-- Plants List Container (top half)
local PlantsListContainer = Instance.new("Frame", PlantsFrame)
PlantsListContainer.Size = UDim2.new(1, 0, 0.65, -5)  -- Adjusted to prevent overlap
PlantsListContainer.Position = UDim2.new(0, 0, 0, 36)
PlantsListContainer.BackgroundTransparency = 1
PlantsListContainer.Name = "PlantsListContainer"

local PlantsList = Instance.new("ScrollingFrame", PlantsListContainer)
PlantsList.Size = UDim2.new(1, 0, 1, 0)
PlantsList.BackgroundTransparency = 1
PlantsList.CanvasSize = UDim2.new(0, 0, 0, 0)
PlantsList.ScrollBarThickness = 4
PlantsList.Parent = PlantsListContainer

-- Shovel Plants Section (bottom half)
local ShovelPlantsFrame = Instance.new("Frame", PlantsFrame)
ShovelPlantsFrame.Size = UDim2.new(1, 0, 0.35, -5)  -- Adjusted to prevent overlap
ShovelPlantsFrame.Position = UDim2.new(0, 0, 0.65, 5)
ShovelPlantsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ShovelPlantsFrame.BackgroundTransparency = 0.5
ShovelPlantsFrame.BorderSizePixel = 0
ShovelPlantsFrame.Name = "ShovelPlants"

local ShovelPlantsCorner = Instance.new("UICorner", ShovelPlantsFrame)
ShovelPlantsCorner.CornerRadius = UDim.new(0, 6)

local ShovelPlantsLabel = Instance.new("TextLabel", ShovelPlantsFrame)
ShovelPlantsLabel.Size = UDim2.new(1, 0, 0.3, 0)
ShovelPlantsLabel.Position = UDim2.new(0, 0, 0, 0)
ShovelPlantsLabel.BackgroundTransparency = 1
ShovelPlantsLabel.Text = "SHOVEL PLANTS"
ShovelPlantsLabel.TextColor3 = Color3.new(1, 1, 1)
ShovelPlantsLabel.Font = Enum.Font.SourceSansBold
ShovelPlantsLabel.TextSize = 12

local ShovelPlantsToggle = Instance.new("TextButton", ShovelPlantsFrame)
ShovelPlantsToggle.Size = UDim2.new(0.3, -5, 0.4, -5)  -- Smaller size
ShovelPlantsToggle.Position = UDim2.new(0, 5, 0.3, 5)
ShovelPlantsToggle.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
ShovelPlantsToggle.Text = "OFF"
ShovelPlantsToggle.TextColor3 = Color3.new(1, 1, 1)
ShovelPlantsToggle.Font = Enum.Font.SourceSansBold
ShovelPlantsToggle.TextSize = 12

local ThresholdLabel = Instance.new("TextLabel", ShovelPlantsFrame)
ThresholdLabel.Size = UDim2.new(0.3, -5, 0.4, -5)  -- Smaller size
ThresholdLabel.Position = UDim2.new(0.35, 5, 0.3, 5)
ThresholdLabel.BackgroundTransparency = 1
ThresholdLabel.Text = "Min/kg:"
ThresholdLabel.TextColor3 = Color3.new(1, 1, 1)
ThresholdLabel.Font = Enum.Font.SourceSans
ThresholdLabel.TextSize = 12
ThresholdLabel.TextXAlignment = Enum.TextXAlignment.Left

local ThresholdBox = Instance.new("TextBox", ShovelPlantsFrame)
ThresholdBox.Size = UDim2.new(0.3, -10, 0.4, -5)  -- Smaller size
ThresholdBox.Position = UDim2.new(0.7, 5, 0.3, 5)
ThresholdBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ThresholdBox.Text = "200"  -- Default threshold
ThresholdBox.TextColor3 = Color3.new(1, 1, 1)
ThresholdBox.Font = Enum.Font.SourceSansBold
ThresholdBox.TextSize = 12

-- Settings Column
local SettingsFrame = Instance.new("Frame", MainFrame)
SettingsFrame.Size = UDim2.new(0, 100, 0, 230)  -- Adjusted size
SettingsFrame.Position = UDim2.new(0, 160, 0, 22)
SettingsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
SettingsFrame.BackgroundTransparency = 0.3
SettingsFrame.BorderSizePixel = 0

local SettingsCorner = Instance.new("UICorner", SettingsFrame)
SettingsCorner.CornerRadius = UDim.new(0, 6)

local SettingsLabel = Instance.new("TextLabel", SettingsFrame)
SettingsLabel.Size = UDim2.new(1, 0, 0, 16)
SettingsLabel.Position = UDim2.new(0, 0, 0, 0)
SettingsLabel.BackgroundTransparency = 1
SettingsLabel.Text = "INFINITE SPRINKLER"
SettingsLabel.TextColor3 = Color3.new(1, 1, 1)
SettingsLabel.Font = Enum.Font.SourceSansBold
SettingsLabel.TextSize = 12

-- Search Box for sprinklers
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
SprinklerList.Size = UDim2.new(1, 0, 0.65, -5)  -- Adjusted to prevent overlap
SprinklerList.Position = UDim2.new(0, 0, 0, 36)
SprinklerList.BackgroundTransparency = 1
SprinklerList.CanvasSize = UDim2.new(0, 0, 0, 0)
SprinklerList.ScrollBarThickness = 4

-- Shovel Sprinkler Section
local ShovelSprinklerFrame = Instance.new("Frame", SettingsFrame)
ShovelSprinklerFrame.Size = UDim2.new(1, 0, 0.35, -5)  -- Adjusted to prevent overlap
ShovelSprinklerFrame.Position = UDim2.new(0, 0, 0.65, 5)
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
ShovelSprinklerToggle.Size = UDim2.new(0.3, -5, 0.4, -5)  -- Smaller size
ShovelSprinklerToggle.Position = UDim2.new(0, 5, 0.3, 5)
ShovelSprinklerToggle.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
ShovelSprinklerToggle.Text = "OFF"
ShovelSprinklerToggle.TextColor3 = Color3.new(1, 1, 1)
ShovelSprinklerToggle.Font = Enum.Font.SourceSansBold
ShovelSprinklerToggle.TextSize = 12

local DelayLabel = Instance.new("TextLabel", ShovelSprinklerFrame)
DelayLabel.Size = UDim2.new(0.3, -5, 0.4, -5)  -- Smaller size
DelayLabel.Position = UDim2.new(0.35, 5, 0.3, 5)
DelayLabel.BackgroundTransparency = 1
DelayLabel.Text = "Delay/s:"
DelayLabel.TextColor3 = Color3.new(1, 1, 1)
DelayLabel.Font = Enum.Font.SourceSans
DelayLabel.TextSize = 12
DelayLabel.TextXAlignment = Enum.TextXAlignment.Left

local DelayBox = Instance.new("TextBox", ShovelSprinklerFrame)
DelayBox.Size = UDim2.new(0.3, -10, 0.4, -5)  -- Smaller size
DelayBox.Position = UDim2.new(0.7, 5, 0.3, 5)
DelayBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
DelayBox.Text = "0"  -- Default delay
DelayBox.TextColor3 = Color3.new(1, 1, 1)
DelayBox.Font = Enum.Font.SourceSansBold
DelayBox.TextSize = 12

-- Toggle UI Button
local ToggleBtn = Instance.new("ImageButton", ScreenGui)
ToggleBtn.Name = "ShowHideESPBtn"
ToggleBtn.Size = UDim2.new(0, 38, 0, 38)
ToggleBtn.Position = UDim2.new(0, 6, 0, 6)
ToggleBtn.BackgroundTransparency = 1
ToggleBtn.Image = "rbxassetid://131613009113138"
ToggleBtn.ZIndex = 100

-- Add circular background
local bg = Instance.new("Frame", ToggleBtn)
bg.Name = "Background"
bg.Size = UDim2.new(1, 0, 1, 0)
bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
bg.BackgroundTransparency = 0.15
bg.ZIndex = 99

-- Make background circular
local corner = Instance.new("UICorner", bg)
corner.CornerRadius = UDim.new(1, 0)

-- Add border to background
local stroke = Instance.new("UIStroke", bg)
stroke.Color = Color3.fromRGB(255, 50, 50)
stroke.Thickness = 2

-- Add glow effect
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

-- Manual plant row creation
local function CreatePlantButton(plant, rarity, yPosition)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 18)  -- Fixed size
    btn.Position = UDim2.new(0, 5, 0, yPosition) -- Manual positioning
    btn.BackgroundColor3 = RarityColors[rarity]
    btn.Text = plant
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 12
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.AutoButtonColor = false
    
    -- Add padding to text
    local padding = Instance.new("UIPadding", btn)
    padding.PaddingLeft = UDim.new(0, 5)
    
    -- Update button appearance based on selection
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

-- Create sprinkler buttons
local function CreateSprinklerButton(sprinkler, yPosition)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 18)
    btn.Position = UDim2.new(0, 5, 0, yPosition)
    btn.BackgroundColor3 = Color3.fromRGB(180, 180, 180)  -- Grey color
    btn.Text = sprinkler
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 12
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.AutoButtonColor = false
    
    -- Add padding to text
    local padding = Instance.new("UIPadding", btn)
    padding.PaddingLeft = UDim.new(0, 5)
    
    -- Update button appearance based on selection
    if Whitelisted_Sprinklers[sprinkler] then
        btn.BackgroundTransparency = 0.3
    else
        btn.BackgroundTransparency = 0.7
    end
    
    btn.MouseButton1Click:Connect(function()
        Whitelisted_Sprinklers[sprinkler] = not Whitelisted_Sprinklers[sprinkler]
        
        if Whitelisted_Sprinklers[sprinkler] then
            btn.BackgroundTransparency = 0.3
            showNotification(sprinkler .. " selected for removal")
        else
            btn.BackgroundTransparency = 0.7
            showNotification(sprinkler .. " removed from removal list")
        end
    end)
    
    return btn
end

-- Functions to manage plant display with manual positioning
local function ShowAllPlants()
    PlantsList:ClearAllChildren()
    local yPosition = 0
    local rowHeight = 20  -- Height + padding
    
    -- Use fixed rarity order instead of pairs
    for _, rarity in ipairs(RarityOrder) do
        local plants = PlantData[rarity]
        for _, plant in ipairs(plants) do
            local btn = CreatePlantButton(plant, rarity, yPosition)
            btn.Parent = PlantsList
            yPosition = yPosition + rowHeight
        end
    end
    
    -- Update canvas size
    PlantsList.CanvasSize = UDim2.new(0, 0, 0, yPosition)
end

local function ShowPlantsByRarity(rarity)
    PlantsList:ClearAllChildren()
    local yPosition = 0
    local rowHeight = 20  -- Height + padding
    
    local plants = PlantData[rarity] or {}
    for _, plant in ipairs(plants) do
        local btn = CreatePlantButton(plant, rarity, yPosition)
        btn.Parent = PlantsList
        yPosition = yPosition + rowHeight
    end
    
    -- Update canvas size
    PlantsList.CanvasSize = UDim2.new(0, 0, 0, yPosition)
end

local function SearchPlants(searchTerm)
    PlantsList:ClearAllChildren()
    local yPosition = 0
    local rowHeight = 20  -- Height + padding
    
    if searchTerm == "" then
        for _, btn in ipairs(RarityList:GetChildren()) do
            if btn:IsA("TextButton") and btn.BackgroundTransparency == 0.1 then
                ShowPlantsByRarity(btn.Text)
                return
            end
        end
        ShowAllPlants()
        return
    end
    
    for _, rarity in ipairs(RarityOrder) do
        local plants = PlantData[rarity]
        for _, plant in ipairs(plants) do
            if string.find(string.lower(plant), string.lower(searchTerm)) then
                local btn = CreatePlantButton(plant, rarity, yPosition)
                btn.Parent = PlantsList
                yPosition = yPosition + rowHeight
            end
        end
    end
    
    -- Update canvas size
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
end

-- Populate Rarity List in fixed order
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
    
    -- Add padding to text
    local padding = Instance.new("UIPadding", btn)
    padding.PaddingLeft = UDim.new(0, 5)
end

-- Rarity selection handler
for _, btn in ipairs(RarityList:GetChildren()) do
    if btn:IsA("TextButton") then
        btn.MouseButton1Click:Connect(function()
            -- Reset all buttons
            for _, otherBtn in ipairs(RarityList:GetChildren()) do
                if otherBtn:IsA("TextButton") then
                    otherBtn.BackgroundTransparency = 0.3
                end
            end
            
            -- Highlight selected button
            btn.BackgroundTransparency = 0.1
            
            -- Show plants for this rarity
            ShowPlantsByRarity(btn.Text)
        end)
    end
end

-- Search handler
SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    SearchPlants(SearchBox.Text)
end)

-- Auto Collect Toggle
local AutoCollectToggle = Instance.new("TextButton") -- This was missing in the original settings
AutoCollectToggle.Name = "AutoCollectToggle"

AutoCollectToggle.MouseButton1Click:Connect(function()
    AutoHarvest = not AutoHarvest
    
    if AutoHarvest then
        AutoCollectToggle.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
        AutoCollectToggle.Text = "ON"
        showNotification("Auto Harvest: ON")
        -- Start harvesting immediately
        task.spawn(function()
            pcall(HarvestPlants)
            StartAutoHarvest()
        end)
    else
        AutoCollectToggle.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
        AutoCollectToggle.Text = "OFF"
        showNotification("Auto Harvest: OFF")
    end
end)

-- Auto Submit Toggle
AutoSubmitToggle.MouseButton1Click:Connect(function()
    AutoSubmit = not AutoSubmit
    
    if AutoSubmit then
        AutoSubmitToggle.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
        AutoSubmitToggle.Text = "ON"
        showNotification("Auto Submit: ON")
        StartAutoSubmit()
    else
        AutoSubmitToggle.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
        AutoSubmitToggle.Text = "OFF"
        showNotification("Auto Submit: OFF")
    end
end)

-- Shovel Plants Toggle
ShovelPlantsToggle.MouseButton1Click:Connect(function()
    AutoShovel = not AutoShovel
    
    if AutoShovel then
        ShovelPlantsToggle.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
        ShovelPlantsToggle.Text = "ON"
        showNotification("Auto Shovel: ON")
        StartAutoShovel()
    else
        ShovelPlantsToggle.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
        ShovelPlantsToggle.Text = "OFF"
        showNotification("Auto Shovel: OFF")
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
    end
end)

-- Rate Box Handler
RateBox.FocusLost:Connect(function()
    local rate = tonumber(RateBox.Text)
    if rate and rate > 0 and rate <= 100 then -- Max rate: 100
        HarvestRate = rate
        RateBox.Text = tostring(rate)
        if AutoHarvest then
            StartAutoHarvest()
        end
    else
        RateBox.Text = tostring(HarvestRate)
    end
end)

-- Interval Box Handler
IntervalBox.FocusLost:Connect(function()
    local interval = tonumber(IntervalBox.Text)
    if interval and interval >= 1 and interval <= 60 then
        SubmitInterval = interval
        IntervalBox.Text = tostring(interval)
        if AutoSubmit then
            StartAutoSubmit()
        end
    else
        IntervalBox.Text = tostring(SubmitInterval)
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

-- Toggle UI Visibility with animation
local uiVisible = false  -- Start with UI hidden
local firstTimeOpen = true

ToggleBtn.MouseButton1Click:Connect(function()
    uiVisible = not uiVisible
    MainFrame.Visible = uiVisible
    
    -- Glow animation
    glow.Visible = true
    local pulse = TweenService:Create(
        glow,
        TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, true),
        {ImageTransparency = 0.5}
    )
    pulse:Play()
    
    -- Rotation animation
    local rotationTween = TweenService:Create(
        ToggleBtn,
        TweenInfo.new(0.3, Enum.EasingStyle.Quint),
        {Rotation = uiVisible and 0 or 180}
    )
    rotationTween:Play()
    
    -- Hide glow after animation
    task.delay(0.6, function()
        glow.Visible = false
    end)
    
    -- Countdown on first open
    if uiVisible and firstTimeOpen then
        firstTimeOpen = false
        
        -- Show initial notification
        local count = 10
        local notification, label = showCountdownNotification(count)
        
        -- Start countdown
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
            
            -- After countdown completes
            task.wait(2)
            
            -- Fade out and destroy
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
ShowAllPlants()  -- Show all plants by default in fixed order
PopulateSprinklerList() -- Populate sprinkler list
showNotification("Punk Team Infinite Sprinkler Loaded!")
