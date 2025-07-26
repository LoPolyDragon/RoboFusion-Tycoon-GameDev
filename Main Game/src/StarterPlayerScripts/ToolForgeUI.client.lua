--------------------------------------------------------------------
-- ToolForgeUI.client.lua · Tool Forge工具制作台界面
-- 功能：
--   1) 显示所有可制作的工具配方
--   2) 检查材料需求和库存
--   3) 启动制作队列
--   4) 显示制作进度
--   5) 支持升级系统
--------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 远程通讯
local rfFolder = ReplicatedStorage:WaitForChild("RemoteFunctions")
local getDataRF = rfFolder:WaitForChild("GetPlayerDataFunction")
local getUpgradeInfoRF = rfFolder:WaitForChild("GetUpgradeInfoFunction")
local getInventoryRF = rfFolder:WaitForChild("GetInventoryFunction")

local reFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local craftEvent = reFolder:FindFirstChild("CraftItemEvent")
local craftStatusEvent = reFolder:FindFirstChild("CraftStatusEvent")
local upgradeMachineEvent = reFolder:FindFirstChild("UpgradeMachineEvent")

-- 检查事件是否存在
if not craftEvent then
    warn("[ToolForgeUI] CraftItemEvent 不存在，ToolForgeUI将无法正常工作")
    return
end

-- 加载配置和图标
local GameConstants = require(ReplicatedStorage.SharedModules.GameConstants.main)
local IconUtils = require(ReplicatedStorage.ClientUtils.IconUtils)

-- 工具配方数据（与服务器端同步）
local TOOL_RECIPES = {
    -- 基础材料
    {
        id = "ScrapWood",
        name = "Scrap Wood",
        category = "Materials",
        materials = {Scrap = 5},
        output = {ScrapWood = 1},
        time = 3,
        description = "用废料制作木材",
        unlockLevel = 1
    },
    {
        id = "IronBar",
        name = "Iron Bar",
        category = "Materials",
        materials = {Scrap = 1, IronOre = 1},
        output = {IronBar = 1},
        time = 8,
        description = "熔炼铁锭：废料 + 铁矿",
        unlockLevel = 1
    },
    {
        id = "BronzeGear",
        name = "Bronze Gear", 
        category = "Materials",
        materials = {Scrap = 1, BronzeOre = 1},
        output = {BronzeGear = 1},
        time = 12,
        description = "制作青铜齿轮：废料 + 青铜矿",
        unlockLevel = 2
    },
    {
        id = "GoldPlatedEdge",
        name = "Gold-Plated Edge",
        category = "Materials",
        materials = {Scrap = 2, GoldOre = 1},
        output = {GoldPlatedEdge = 1},
        time = 18,
        description = "制作镀金边缘：废料 + 金矿",
        unlockLevel = 3
    },
    {
        id = "DiamondTip",
        name = "Diamond Tip",
        category = "Materials",
        materials = {Scrap = 3, DiamondOre = 1},
        output = {DiamondTip = 1},
        time = 25,
        description = "制作钻石尖端：废料 + 钻石矿",
        unlockLevel = 4
    },
    
    -- 挖掘镐子
    {
        id = "WoodPick",
        name = "Wood Pick",
        category = "Mining Tools",
        materials = {ScrapWood = 1},
        output = {WoodPick = 1},
        time = 5,
        description = "木镐 - 耐久50格，可挖硬度1-2",
        unlockLevel = 1
    },
    {
        id = "IronPick",
        name = "Iron Pick",
        category = "Mining Tools",
        materials = {WoodPick = 1, IronBar = 1},
        output = {IronPick = 1},
        time = 10,
        description = "铁镐 - 耐久120格，可挖硬度3",
        unlockLevel = 1
    },
    {
        id = "BronzePick",
        name = "Bronze Pick",
        category = "Mining Tools",
        materials = {IronPick = 1, BronzeGear = 1},
        output = {BronzePick = 1},
        time = 15,
        description = "青铜镐 - 耐久250格，可挖硬度4",
        unlockLevel = 2
    },
    {
        id = "GoldPick",
        name = "Gold Pick",
        category = "Mining Tools",
        materials = {BronzePick = 1, GoldPlatedEdge = 1},
        output = {GoldPick = 1},
        time = 20,
        description = "黄金镐 - 耐久400格，可挖硬度5",
        unlockLevel = 3
    },
    {
        id = "DiamondPick",
        name = "Diamond Pick",
        category = "Mining Tools",
        materials = {GoldPick = 1, DiamondTip = 1},
        output = {DiamondPick = 1},
        time = 30,
        description = "钻石镐 - 耐久800格，可挖硬度6",
        unlockLevel = 4
    },
    
    -- 建造锤子
    {
        id = "WoodHammer",
        name = "Wood Hammer",
        category = "Building Tools",
        materials = {ScrapWood = 1},
        output = {WoodHammer = 1},
        time = 5,
        description = "木锤 - 建造耐久5分钟",
        unlockLevel = 1
    },
    {
        id = "IronHammer",
        name = "Iron Hammer",
        category = "Building Tools",
        materials = {WoodHammer = 1, IronBar = 2},
        output = {IronHammer = 1},
        time = 12,
        description = "铁锤 - 建造耐久30分钟",
        unlockLevel = 1
    },
    {
        id = "BronzeHammer",
        name = "Bronze Hammer",
        category = "Building Tools", 
        materials = {IronHammer = 1, BronzeGear = 1},
        output = {BronzeHammer = 1},
        time = 20,
        description = "青铜锤 - 建造耐久5小时",
        unlockLevel = 2
    },
    {
        id = "GoldHammer",
        name = "Gold Hammer",
        category = "Building Tools",
        materials = {BronzeHammer = 1, GoldPlatedEdge = 1},
        output = {GoldHammer = 1},
        time = 25,
        description = "黄金锤 - 建造耐久10小时",
        unlockLevel = 3
    },
    {
        id = "DiamondHammer",
        name = "Diamond Hammer",
        category = "Building Tools",
        materials = {GoldHammer = 1, DiamondTip = 1},
        output = {DiamondHammer = 1},
        time = 35,
        description = "钻石锤 - 建造耐久100小时",
        unlockLevel = 4
    }
}

-- 分类工具配方
local function categorizeRecipes()
    local categories = {}
    for _, recipe in ipairs(TOOL_RECIPES) do
        if not categories[recipe.category] then
            categories[recipe.category] = {}
        end
        table.insert(categories[recipe.category], recipe)
    end
    return categories
end

local RECIPE_CATEGORIES = categorizeRecipes()

--------------------------------------------------------------------
-- 创建Tool Forge UI
--------------------------------------------------------------------
local function createToolForgeUI()
    -- 主界面
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ToolForgeUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui
    
    -- 主框架
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 800, 0, 600)
    mainFrame.Position = UDim2.new(0.5, -400, 0.5, -300)
    mainFrame.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame
    
    -- 标题栏
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = titleBar
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -50, 1, 0)
    titleLabel.Position = UDim2.new(0, 15, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Tool Forge"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = titleBar
    
    -- 关闭按钮
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
    closeButton.Text = "×"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.GothamBold
    closeButton.BorderSizePixel = 0
    closeButton.Active = true
    closeButton.Parent = titleBar
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 5)
    closeCorner.Parent = closeButton
    
    -- 内容区域
    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, -30, 1, -70)
    contentFrame.Position = UDim2.new(0, 15, 0, 50)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame
    
    -- 左侧 - 分类选择
    local categoryFrame = Instance.new("Frame")
    categoryFrame.Size = UDim2.new(0.25, -10, 1, -120)
    categoryFrame.Position = UDim2.new(0, 0, 0, 0)
    categoryFrame.BackgroundColor3 = Color3.fromRGB(250, 250, 250)
    categoryFrame.BorderSizePixel = 1
    categoryFrame.BorderColor3 = Color3.fromRGB(200, 200, 200)
    categoryFrame.Parent = contentFrame
    
    local catCorner = Instance.new("UICorner")
    catCorner.CornerRadius = UDim.new(0, 5)
    catCorner.Parent = categoryFrame
    
    local categoryScroll = Instance.new("ScrollingFrame")
    categoryScroll.Size = UDim2.new(1, -10, 1, -10)
    categoryScroll.Position = UDim2.new(0, 5, 0, 5)
    categoryScroll.BackgroundTransparency = 1
    categoryScroll.ScrollBarThickness = 6
    categoryScroll.Parent = categoryFrame
    
    local categoryLayout = Instance.new("UIListLayout")
    categoryLayout.Padding = UDim.new(0, 2)
    categoryLayout.SortOrder = Enum.SortOrder.LayoutOrder
    categoryLayout.Parent = categoryScroll
    
    -- 中间 - 配方列表
    local recipeFrame = Instance.new("Frame")
    recipeFrame.Size = UDim2.new(0.45, -10, 1, -120)
    recipeFrame.Position = UDim2.new(0.25, 10, 0, 0)
    recipeFrame.BackgroundColor3 = Color3.fromRGB(250, 250, 250)
    recipeFrame.BorderSizePixel = 1
    recipeFrame.BorderColor3 = Color3.fromRGB(200, 200, 200)
    recipeFrame.Parent = contentFrame
    
    local recipeCorner = Instance.new("UICorner")
    recipeCorner.CornerRadius = UDim.new(0, 5)
    recipeCorner.Parent = recipeFrame
    
    local recipeScroll = Instance.new("ScrollingFrame")
    recipeScroll.Size = UDim2.new(1, -10, 1, -10)
    recipeScroll.Position = UDim2.new(0, 5, 0, 5)
    recipeScroll.BackgroundTransparency = 1
    recipeScroll.ScrollBarThickness = 6
    recipeScroll.Parent = recipeFrame
    
    local recipeLayout = Instance.new("UIListLayout")
    recipeLayout.Padding = UDim.new(0, 5)
    recipeLayout.SortOrder = Enum.SortOrder.LayoutOrder
    recipeLayout.Parent = recipeScroll
    
    -- 右侧 - 详情和制作
    local detailFrame = Instance.new("Frame")
    detailFrame.Size = UDim2.new(0.3, -10, 1, -120)
    detailFrame.Position = UDim2.new(0.7, 10, 0, 0)
    detailFrame.BackgroundColor3 = Color3.fromRGB(250, 250, 250)
    detailFrame.BorderSizePixel = 1
    detailFrame.BorderColor3 = Color3.fromRGB(200, 200, 200)
    detailFrame.Parent = contentFrame
    
    local detailCorner = Instance.new("UICorner")
    detailCorner.CornerRadius = UDim.new(0, 5)
    detailCorner.Parent = detailFrame
    
    -- 底部 - 制作进度和升级
    local bottomFrame = Instance.new("Frame")
    bottomFrame.Size = UDim2.new(1, 0, 0, 110)
    bottomFrame.Position = UDim2.new(0, 0, 1, -110)
    bottomFrame.BackgroundColor3 = Color3.fromRGB(250, 250, 250)
    bottomFrame.BorderSizePixel = 1
    bottomFrame.BorderColor3 = Color3.fromRGB(200, 200, 200)
    bottomFrame.Parent = contentFrame
    
    local bottomCorner = Instance.new("UICorner")
    bottomCorner.CornerRadius = UDim.new(0, 5)
    bottomCorner.Parent = bottomFrame
    
    return screenGui, mainFrame, closeButton, categoryScroll, recipeScroll, detailFrame, bottomFrame
end

--------------------------------------------------------------------
-- 创建分类按钮
--------------------------------------------------------------------
local function createCategoryButton(categoryName, parent, isSelected)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 30)
    button.BackgroundColor3 = isSelected and Color3.fromRGB(200, 230, 255) or Color3.fromRGB(255, 255, 255)
    button.BorderSizePixel = 1
    button.BorderColor3 = isSelected and Color3.fromRGB(100, 150, 255) or Color3.fromRGB(220, 220, 220)
    button.Text = categoryName
    button.TextColor3 = Color3.fromRGB(60, 60, 60)
    button.TextScaled = true
    button.Font = Enum.Font.Gotham
    button.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 3)
    corner.Parent = button
    
    return button
end

--------------------------------------------------------------------
-- 创建配方卡片
--------------------------------------------------------------------
local function createRecipeCard(recipe, parent, inventory, playerLevel)
    local card = Instance.new("TextButton")
    card.Size = UDim2.new(1, 0, 0, 80)
    card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    card.BorderSizePixel = 1
    card.BorderColor3 = Color3.fromRGB(220, 220, 220)
    card.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = card
    
    -- 工具图标
    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 50, 0, 50)
    icon.Position = UDim2.new(0, 10, 0, 15)
    icon.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
    icon.Image = IconUtils.getItemIcon(recipe.id)
    icon.ScaleType = Enum.ScaleType.Fit
    icon.BorderSizePixel = 0
    icon.Parent = card
    
    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 25)
    iconCorner.Parent = icon
    
    -- 工具名称
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -70, 0, 20)
    nameLabel.Position = UDim2.new(0, 70, 0, 10)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = recipe.name
    nameLabel.TextColor3 = Color3.fromRGB(60, 60, 60)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = card
    
    -- 制作时间
    local timeLabel = Instance.new("TextLabel")
    timeLabel.Size = UDim2.new(1, -70, 0, 15)
    timeLabel.Position = UDim2.new(0, 70, 0, 30)
    timeLabel.BackgroundTransparency = 1
    timeLabel.Text = string.format("Time: %ds", recipe.time)
    timeLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
    timeLabel.TextScaled = true
    timeLabel.Font = Enum.Font.Gotham
    timeLabel.TextXAlignment = Enum.TextXAlignment.Left
    timeLabel.Parent = card
    
    -- 材料需求
    local materialsText = ""
    local canCraft = true
    for material, amount in pairs(recipe.materials) do
        if materialsText ~= "" then materialsText = materialsText .. ", " end
        local have = inventory[material] or 0
        local hasEnough = have >= amount
        if not hasEnough then canCraft = false end
        materialsText = materialsText .. string.format("%s: %d/%d", material, have, amount)
    end
    
    local materialLabel = Instance.new("TextLabel")
    materialLabel.Size = UDim2.new(1, -70, 0, 15)
    materialLabel.Position = UDim2.new(0, 70, 0, 45)
    materialLabel.BackgroundTransparency = 1
    materialLabel.Text = materialsText
    materialLabel.TextColor3 = canCraft and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(200, 50, 50)
    materialLabel.TextScaled = true
    materialLabel.Font = Enum.Font.Gotham
    materialLabel.TextXAlignment = Enum.TextXAlignment.Left
    materialLabel.Parent = card
    
    -- 解锁等级检查
    local isUnlocked = playerLevel >= recipe.unlockLevel
    if not isUnlocked then
        canCraft = false
        card.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
        icon.ImageTransparency = 0.5
        nameLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        materialLabel.Text = string.format("Requires Level %d", recipe.unlockLevel)
        materialLabel.TextColor3 = Color3.fromRGB(200, 50, 50)
    end
    
    return card, canCraft
end

--------------------------------------------------------------------
-- 创建详情面板
--------------------------------------------------------------------
local function createDetailPanel(recipe, parent, inventory, canCraft)
    -- 清除现有内容
    for _, child in pairs(parent:GetChildren()) do
        child:Destroy()
    end
    
    -- 工具图标（大）
    local bigIcon = Instance.new("ImageLabel")
    bigIcon.Size = UDim2.new(0, 80, 0, 80)
    bigIcon.Position = UDim2.new(0.5, -40, 0, 10)
    bigIcon.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
    bigIcon.Image = IconUtils.getItemIcon(recipe.id)
    bigIcon.ScaleType = Enum.ScaleType.Fit
    bigIcon.BorderSizePixel = 0
    bigIcon.Parent = parent
    
    local bigIconCorner = Instance.new("UICorner")
    bigIconCorner.CornerRadius = UDim.new(0, 40)
    bigIconCorner.Parent = bigIcon
    
    -- 工具名称
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -10, 0, 25)
    nameLabel.Position = UDim2.new(0, 5, 0, 95)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = recipe.name
    nameLabel.TextColor3 = Color3.fromRGB(60, 60, 60)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = parent
    
    -- 描述
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, -10, 0, 40)
    descLabel.Position = UDim2.new(0, 5, 0, 125)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = recipe.description
    descLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
    descLabel.TextScaled = true
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextWrapped = true
    descLabel.Parent = parent
    
    -- 材料列表
    local materialsFrame = Instance.new("Frame")
    materialsFrame.Size = UDim2.new(1, -10, 0, 150)
    materialsFrame.Position = UDim2.new(0, 5, 0, 175)
    materialsFrame.BackgroundTransparency = 1
    materialsFrame.Parent = parent
    
    local materialsLayout = Instance.new("UIListLayout")
    materialsLayout.Padding = UDim.new(0, 3)
    materialsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    materialsLayout.Parent = materialsFrame
    
    -- 材料标题
    local materialsTitle = Instance.new("TextLabel")
    materialsTitle.Size = UDim2.new(1, 0, 0, 20)
    materialsTitle.BackgroundTransparency = 1
    materialsTitle.Text = "Required Materials:"
    materialsTitle.TextColor3 = Color3.fromRGB(80, 80, 80)
    materialsTitle.TextScaled = true
    materialsTitle.Font = Enum.Font.GothamBold
    materialsTitle.TextXAlignment = Enum.TextXAlignment.Left
    materialsTitle.LayoutOrder = 1
    materialsTitle.Parent = materialsFrame
    
    -- 每种材料
    local layoutOrder = 2
    for material, amount in pairs(recipe.materials) do
        local have = inventory[material] or 0
        local hasEnough = have >= amount
        
        local materialItem = Instance.new("Frame")
        materialItem.Size = UDim2.new(1, 0, 0, 25)
        materialItem.BackgroundTransparency = 1
        materialItem.LayoutOrder = layoutOrder
        materialItem.Parent = materialsFrame
        
        local matIcon = Instance.new("ImageLabel")
        matIcon.Size = UDim2.new(0, 20, 0, 20)
        matIcon.Position = UDim2.new(0, 0, 0, 2)
        matIcon.BackgroundTransparency = 1
        matIcon.Image = IconUtils.getItemIcon(material)
        matIcon.ScaleType = Enum.ScaleType.Fit
        matIcon.Parent = materialItem
        
        local matLabel = Instance.new("TextLabel")
        matLabel.Size = UDim2.new(1, -25, 1, 0)
        matLabel.Position = UDim2.new(0, 25, 0, 0)
        matLabel.BackgroundTransparency = 1
        matLabel.Text = string.format("%s: %d/%d", material, have, amount)
        matLabel.TextColor3 = hasEnough and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(200, 50, 50)
        matLabel.TextScaled = true
        matLabel.Font = Enum.Font.Gotham
        matLabel.TextXAlignment = Enum.TextXAlignment.Left
        matLabel.Parent = materialItem
        
        layoutOrder = layoutOrder + 1
    end
    
    -- 制作按钮
    local craftButton = Instance.new("TextButton")
    craftButton.Size = UDim2.new(1, -10, 0, 40)
    craftButton.Position = UDim2.new(0, 5, 1, -45)
    craftButton.BackgroundColor3 = canCraft and Color3.fromRGB(100, 180, 100) or Color3.fromRGB(150, 150, 150)
    craftButton.Text = canCraft and "Craft" or "Cannot Craft"
    craftButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    craftButton.TextScaled = true
    craftButton.Font = Enum.Font.GothamBold
    craftButton.BorderSizePixel = 0
    craftButton.Active = canCraft
    craftButton.Parent = parent
    
    local craftCorner = Instance.new("UICorner")
    craftCorner.CornerRadius = UDim.new(0, 5)
    craftCorner.Parent = craftButton
    
    return craftButton
end

--------------------------------------------------------------------
-- 创建进度面板
--------------------------------------------------------------------
local function createProgressPanel(parent)
    -- 清除现有内容
    for _, child in pairs(parent:GetChildren()) do
        if child.Name ~= "UICorner" then
            child:Destroy()
        end
    end
    
    -- 进度信息
    local progressLabel = Instance.new("TextLabel")
    progressLabel.Size = UDim2.new(0.7, -10, 0, 25)
    progressLabel.Position = UDim2.new(0, 10, 0, 10)
    progressLabel.BackgroundTransparency = 1
    progressLabel.Text = "No active crafting"
    progressLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
    progressLabel.TextScaled = true
    progressLabel.Font = Enum.Font.Gotham
    progressLabel.TextXAlignment = Enum.TextXAlignment.Left
    progressLabel.Parent = parent
    
    -- 进度条
    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(0.7, -10, 0, 10)
    progressBar.Position = UDim2.new(0, 10, 0, 40)
    progressBar.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
    progressBar.BorderSizePixel = 0
    progressBar.Parent = parent
    
    local progressBarCorner = Instance.new("UICorner")
    progressBarCorner.CornerRadius = UDim.new(0, 5)
    progressBarCorner.Parent = progressBar
    
    local progressFill = Instance.new("Frame")
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    progressFill.Position = UDim2.new(0, 0, 0, 0)
    progressFill.BackgroundColor3 = Color3.fromRGB(100, 180, 100)
    progressFill.BorderSizePixel = 0
    progressFill.Parent = progressBar
    
    local progressFillCorner = Instance.new("UICorner")
    progressFillCorner.CornerRadius = UDim.new(0, 5)
    progressFillCorner.Parent = progressFill
    
    -- 升级信息
    local upgradeLabel = Instance.new("TextLabel")
    upgradeLabel.Size = UDim2.new(0.5, -10, 0, 25)
    upgradeLabel.Position = UDim2.new(0, 10, 0, 60)
    upgradeLabel.BackgroundTransparency = 1
    upgradeLabel.Text = "Tool Forge Lv.1 → Lv.2"
    upgradeLabel.TextColor3 = Color3.fromRGB(80, 80, 80)
    upgradeLabel.TextScaled = true
    upgradeLabel.Font = Enum.Font.Gotham
    upgradeLabel.TextXAlignment = Enum.TextXAlignment.Left
    upgradeLabel.Parent = parent
    
    -- 升级按钮
    local upgradeButton = Instance.new("TextButton")
    upgradeButton.Size = UDim2.new(0.3, -10, 0, 30)
    upgradeButton.Position = UDim2.new(0.7, 10, 0, 60)
    upgradeButton.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    upgradeButton.Text = "Upgrade (500¢)"
    upgradeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    upgradeButton.TextScaled = true
    upgradeButton.Font = Enum.Font.GothamBold
    upgradeButton.BorderSizePixel = 0
    upgradeButton.Active = true
    upgradeButton.Parent = parent
    
    local upgradeCorner = Instance.new("UICorner")
    upgradeCorner.CornerRadius = UDim.new(0, 5)
    upgradeCorner.Parent = upgradeButton
    
    return progressLabel, progressFill, upgradeLabel, upgradeButton
end

--------------------------------------------------------------------
-- 主UI控制
--------------------------------------------------------------------
local toolForgeUI = nil
local currentToolForge = nil
local selectedCategory = "Materials"
local selectedRecipe = nil
local craftStatus = nil

-- 显示Tool Forge UI
local function showToolForgeUI(toolForgeModel)
    if not toolForgeUI then
        local ui, mainFrame, closeButton, categoryScroll, recipeScroll, detailFrame, bottomFrame = createToolForgeUI()
        
        toolForgeUI = {
            gui = ui,
            mainFrame = mainFrame,
            closeButton = closeButton,
            categoryScroll = categoryScroll,
            recipeScroll = recipeScroll,
            detailFrame = detailFrame,
            bottomFrame = bottomFrame,
            categoryButtons = {},
            recipeCards = {}
        }
        
        -- 关闭按钮事件
        closeButton.MouseButton1Click:Connect(function()
            hideToolForgeUI()
        end)
    end
    
    currentToolForge = toolForgeModel
    updateToolForgeUI()
    
    -- 显示动画
    toolForgeUI.mainFrame.Visible = true
    toolForgeUI.mainFrame.Size = UDim2.new(0, 0, 0, 0)
    toolForgeUI.mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    local tween = TweenService:Create(toolForgeUI.mainFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0, 800, 0, 600),
            Position = UDim2.new(0.5, -400, 0.5, -300)
        }
    )
    tween:Play()
end

-- 隐藏Tool Forge UI
local function hideToolForgeUI()
    if not toolForgeUI then return end
    
    local tween = TweenService:Create(toolForgeUI.mainFrame,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }
    )
    tween:Play()
    
    tween.Completed:Connect(function()
        toolForgeUI.mainFrame.Visible = false
        currentToolForge = nil
        selectedRecipe = nil
    end)
end

-- 更新Tool Forge UI
local function updateToolForgeUI()
    if not toolForgeUI or not currentToolForge then return end
    
    local playerData = getDataRF:InvokeServer()
    local upgradeInfo = getUpgradeInfoRF:InvokeServer("ToolForge")
    local inventory = getInventoryRF:InvokeServer()
    
    if not playerData or not inventory then return end
    
    local playerLevel = upgradeInfo and upgradeInfo.level or 1
    
    -- 更新分类按钮
    for _, button in pairs(toolForgeUI.categoryButtons) do
        button:Destroy()
    end
    toolForgeUI.categoryButtons = {}
    
    for categoryName, _ in pairs(RECIPE_CATEGORIES) do
        local button = createCategoryButton(categoryName, toolForgeUI.categoryScroll, categoryName == selectedCategory)
        toolForgeUI.categoryButtons[categoryName] = button
        
        button.MouseButton1Click:Connect(function()
            selectedCategory = categoryName
            updateToolForgeUI()
        end)
    end
    
    -- 更新配方列表
    for _, card in pairs(toolForgeUI.recipeCards) do
        card:Destroy()
    end
    toolForgeUI.recipeCards = {}
    
    local recipes = RECIPE_CATEGORIES[selectedCategory] or {}
    for _, recipe in ipairs(recipes) do
        local card, canCraft = createRecipeCard(recipe, toolForgeUI.recipeScroll, inventory, playerLevel)
        toolForgeUI.recipeCards[recipe.id] = card
        
        card.MouseButton1Click:Connect(function()
            selectedRecipe = recipe
            local craftButton = createDetailPanel(recipe, toolForgeUI.detailFrame, inventory, canCraft)
            
            if canCraft then
                craftButton.MouseButton1Click:Connect(function()
                    craftEvent:FireServer(recipe.id)
                end)
            end
        end)
    end
    
    -- 如果有选中的配方，更新详情面板
    if selectedRecipe then
        local canCraft = true
        for material, amount in pairs(selectedRecipe.materials) do
            local have = inventory[material] or 0
            if have < amount then
                canCraft = false
                break
            end
        end
        
        if playerLevel < selectedRecipe.unlockLevel then
            canCraft = false
        end
        
        local craftButton = createDetailPanel(selectedRecipe, toolForgeUI.detailFrame, inventory, canCraft)
        if canCraft then
            craftButton.MouseButton1Click:Connect(function()
                craftEvent:FireServer(selectedRecipe.id)
            end)
        end
    end
    
    -- 更新底部面板
    local progressLabel, progressFill, upgradeLabel, upgradeButton = createProgressPanel(toolForgeUI.bottomFrame)
    
    -- 升级按钮事件
    if upgradeInfo then
        local level = upgradeInfo.level or 1
        local credits = playerData.Credits or 0
        local upgradeCost = level * 500
        
        upgradeLabel.Text = string.format("Tool Forge Lv.%d → Lv.%d", level, level + 1)
        upgradeButton.Text = string.format("Upgrade (%d¢)", upgradeCost)
        
        if credits >= upgradeCost then
            upgradeButton.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
            upgradeButton.MouseButton1Click:Connect(function()
                upgradeMachineEvent:FireServer("ToolForge")
            end)
        else
            upgradeButton.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
            upgradeButton.Text = "Need Credits"
        end
    end
    
    -- 更新制作进度
    updateCraftProgress(progressLabel, progressFill)
end

-- 更新制作进度
local function updateCraftProgress(progressLabel, progressFill)
    local getCraftStatusFunc = ReplicatedStorage:FindFirstChild("GetCraftStatusFunction")
    if not getCraftStatusFunc then return end
    
    local status = getCraftStatusFunc:InvokeServer()
    if status then
        local progress = (status.total - status.remaining) / status.total
        progressLabel.Text = string.format("Crafting %s... %ds remaining", status.itemName, status.remaining)
        progressFill.Size = UDim2.new(progress, 0, 1, 0)
        progressFill.Parent.BackgroundColor3 = Color3.fromRGB(100, 180, 100)
    else
        progressLabel.Text = "No active crafting"
        progressFill.Size = UDim2.new(0, 0, 1, 0)
        progressFill.Parent.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
    end
end

-- 制作事件处理
craftEvent.OnClientEvent:Connect(function(success, message)
    if toolForgeUI and toolForgeUI.mainFrame.Visible then
        -- 显示制作结果
        print("[ToolForge]", message)
        task.wait(1)
        updateToolForgeUI()
    end
end)

craftStatusEvent.OnClientEvent:Connect(function(status, itemName, duration)
    if toolForgeUI and toolForgeUI.mainFrame.Visible then
        if status == "START" then
            print("[ToolForge] Started crafting", itemName)
        elseif status == "COMPLETE" then
            print("[ToolForge] Completed crafting", itemName)
            updateToolForgeUI()
        end
    end
end)

--------------------------------------------------------------------
-- Tool Forge交互设置
--------------------------------------------------------------------
local function setupToolForgeInteractions()
    for _, obj in pairs(workspace:GetChildren()) do
        if obj:IsA("Model") and obj.Name:lower():find("toolforge") then
            local targetPart = obj.PrimaryPart
            if not targetPart then
                for _, child in pairs(obj:GetChildren()) do
                    if child:IsA("BasePart") then
                        targetPart = child
                        break
                    end
                end
            end
            
            if targetPart then
                local existingPrompt = targetPart:FindFirstChild("ProximityPrompt")
                if not existingPrompt then
                    local prompt = Instance.new("ProximityPrompt")
                    prompt.ObjectText = "Tool Forge"
                    prompt.ActionText = "打开"
                    prompt.HoldDuration = 0.5
                    prompt.MaxActivationDistance = 10
                    prompt.RequiresLineOfSight = false
                    prompt.Parent = targetPart
                    
                    prompt.Triggered:Connect(function(triggerPlayer)
                        if triggerPlayer == player then
                            showToolForgeUI(obj)
                        end
                    end)
                    
                    print("[ToolForgeUI] 为Tool Forge添加ProximityPrompt:", obj.Name)
                end
            end
        end
    end
end

workspace.ChildAdded:Connect(function(child)
    if child:IsA("Model") and child.Name:lower():find("toolforge") then
        task.wait(0.1)
        
        local targetPart = child.PrimaryPart
        if not targetPart then
            for _, grandChild in pairs(child:GetChildren()) do
                if grandChild:IsA("BasePart") then
                    targetPart = grandChild
                    break
                end
            end
        end
        
        if targetPart then
            local prompt = Instance.new("ProximityPrompt")
            prompt.ObjectText = "Tool Forge"
            prompt.ActionText = "打开"
            prompt.HoldDuration = 0.5
            prompt.MaxActivationDistance = 10
            prompt.RequiresLineOfSight = false
            prompt.Parent = targetPart
            
            prompt.Triggered:Connect(function(triggerPlayer)
                if triggerPlayer == player then
                    showToolForgeUI(child)
                end
            end)
            
            print("[ToolForgeUI] 为新Tool Forge添加ProximityPrompt:", child.Name)
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end
    
    if input.KeyCode == Enum.KeyCode.E and toolForgeUI and toolForgeUI.mainFrame.Visible then
        hideToolForgeUI()
    end
end)

-- 定期更新进度
task.spawn(function()
    while true do
        task.wait(1)
        if toolForgeUI and toolForgeUI.mainFrame.Visible then
            local progressLabel = toolForgeUI.bottomFrame:FindFirstChild("TextLabel")
            local progressBar = toolForgeUI.bottomFrame:FindFirstChild("Frame")
            if progressLabel and progressBar then
                local progressFill = progressBar:FindFirstChild("Frame")
                if progressFill then
                    updateCraftProgress(progressLabel, progressFill)
                end
            end
        end
    end
end)

setupToolForgeInteractions()

print("[ToolForgeUI] Tool Forge UI系统已加载")