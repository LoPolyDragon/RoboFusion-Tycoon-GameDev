--------------------------------------------------------------------
-- BuildingShopUI.client.lua · 建筑商店界面
-- 功能：
--   1) 建筑分类浏览和购买
--   2) 已建造建筑管理
--   3) 建筑信息查看和升级
--   4) 与建筑放置系统集成
--------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- GameConstants
local GameConstants = require(ReplicatedStorage.SharedModules.GameConstants)

-- RemoteEvents
local buildingEvents = ReplicatedStorage:WaitForChild("BuildingEvents")
local placeBuildingEvent = buildingEvents:WaitForChild("PlaceBuildingEvent")
local manageBuildingEvent = buildingEvents:WaitForChild("ManageBuildingEvent")

-- 建筑商店UI状态
local BuildingShopUI = {
    gui = nil,
    isOpen = false,
    selectedCategory = "PRODUCTION",
    selectedBuilding = nil,
    currentTab = "shop", -- "shop" 或 "manage"
    playerBuildings = {},
    playerData = {}
}

--------------------------------------------------------------------
-- UI创建函数
--------------------------------------------------------------------

-- 创建主界面
local function createMainUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BuildingShopUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    -- 主框架
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0.8, 0, 0.8, 0)
    mainFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Parent = screenGui
    
    -- 圆角
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = mainFrame
    
    -- 标题栏
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 60)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 15)
    titleCorner.Parent = titleBar
    
    -- 修复标题栏底部圆角
    local titleBottom = Instance.new("Frame")
    titleBottom.Size = UDim2.new(1, 0, 0, 15)
    titleBottom.Position = UDim2.new(0, 0, 1, -15)
    titleBottom.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    titleBottom.BorderSizePixel = 0
    titleBottom.Parent = titleBar
    
    -- 标题文字
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(0, 300, 1, 0)
    titleLabel.Position = UDim2.new(0, 20, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🏗️ 建筑管理中心"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar
    
    -- 关闭按钮
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -50, 0, 10)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.Parent = titleBar
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton
    
    -- Tab切换按钮
    local tabFrame = Instance.new("Frame")
    tabFrame.Name = "TabFrame"
    tabFrame.Size = UDim2.new(0, 300, 0, 40)
    tabFrame.Position = UDim2.new(0, 350, 0, 10)
    tabFrame.BackgroundTransparency = 1
    tabFrame.Parent = titleBar
    
    local shopTab = Instance.new("TextButton")
    shopTab.Name = "ShopTab"
    shopTab.Size = UDim2.new(0, 145, 1, 0)
    shopTab.Position = UDim2.new(0, 0, 0, 0)
    shopTab.BackgroundColor3 = Color3.fromRGB(50, 120, 200)
    shopTab.BorderSizePixel = 0
    shopTab.Text = "🛒 建筑商店"
    shopTab.TextColor3 = Color3.fromRGB(255, 255, 255)
    shopTab.TextScaled = true
    shopTab.Font = Enum.Font.SourceSansBold
    shopTab.Parent = tabFrame
    
    local shopTabCorner = Instance.new("UICorner")
    shopTabCorner.CornerRadius = UDim.new(0, 8)
    shopTabCorner.Parent = shopTab
    
    local manageTab = Instance.new("TextButton")
    manageTab.Name = "ManageTab"
    manageTab.Size = UDim2.new(0, 145, 1, 0)
    manageTab.Position = UDim2.new(0, 155, 0, 0)
    manageTab.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
    manageTab.BorderSizePixel = 0
    manageTab.Text = "⚙️ 建筑管理"
    manageTab.TextColor3 = Color3.fromRGB(200, 200, 200)
    manageTab.TextScaled = true
    manageTab.Font = Enum.Font.SourceSans
    manageTab.Parent = tabFrame
    
    local manageTabCorner = Instance.new("UICorner")
    manageTabCorner.CornerRadius = UDim.new(0, 8)
    manageTabCorner.Parent = manageTab
    
    -- 内容区域
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, -20, 1, -80)
    contentFrame.Position = UDim2.new(0, 10, 0, 70)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame
    
    -- 创建商店内容
    createShopContent(contentFrame)
    
    -- 创建管理内容
    createManageContent(contentFrame)
    
    -- 绑定事件
    closeButton.MouseButton1Click:Connect(function()
        BuildingShopUI.CloseUI()
    end)
    
    shopTab.MouseButton1Click:Connect(function()
        BuildingShopUI.SwitchTab("shop")
    end)
    
    manageTab.MouseButton1Click:Connect(function()
        BuildingShopUI.SwitchTab("manage")
    end)
    
    return screenGui
end

-- 创建商店内容
local function createShopContent(parent)
    local shopFrame = Instance.new("Frame")
    shopFrame.Name = "ShopFrame"
    shopFrame.Size = UDim2.new(1, 0, 1, 0)
    shopFrame.Position = UDim2.new(0, 0, 0, 0)
    shopFrame.BackgroundTransparency = 1
    shopFrame.Visible = true
    shopFrame.Parent = parent
    
    -- 左侧分类栏
    local categoryFrame = Instance.new("Frame")
    categoryFrame.Name = "CategoryFrame"
    categoryFrame.Size = UDim2.new(0, 200, 1, 0)
    categoryFrame.Position = UDim2.new(0, 0, 0, 0)
    categoryFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    categoryFrame.BorderSizePixel = 0
    categoryFrame.Parent = shopFrame
    
    local categoryCorner = Instance.new("UICorner")
    categoryCorner.CornerRadius = UDim.new(0, 10)
    categoryCorner.Parent = categoryFrame
    
    -- 分类按钮
    local categories = {
        {key = "PRODUCTION", name = "🏭 生产建筑", color = Color3.fromRGB(200, 100, 50)},
        {key = "FUNCTIONAL", name = "⚙️ 功能建筑", color = Color3.fromRGB(50, 150, 200)},
        {key = "INFRASTRUCTURE", name = "🔧 基础设施", color = Color3.fromRGB(100, 200, 50)},
        {key = "DECORATIVE", name = "🎨 装饰建筑", color = Color3.fromRGB(200, 50, 150)}
    }
    
    for i, category in ipairs(categories) do
        local categoryButton = Instance.new("TextButton")
        categoryButton.Name = category.key .. "Button"
        categoryButton.Size = UDim2.new(1, -20, 0, 50)
        categoryButton.Position = UDim2.new(0, 10, 0, 10 + (i-1) * 60)
        categoryButton.BackgroundColor3 = category.color
        categoryButton.BorderSizePixel = 0
        categoryButton.Text = category.name
        categoryButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        categoryButton.TextScaled = true
        categoryButton.Font = Enum.Font.SourceSansBold
        categoryButton.Parent = categoryFrame
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 8)
        buttonCorner.Parent = categoryButton
        
        categoryButton.MouseButton1Click:Connect(function()
            BuildingShopUI.SelectCategory(category.key)
        end)
    end
    
    -- 右侧建筑展示区
    local buildingFrame = Instance.new("Frame")
    buildingFrame.Name = "BuildingFrame"
    buildingFrame.Size = UDim2.new(1, -220, 1, 0)
    buildingFrame.Position = UDim2.new(0, 210, 0, 0)
    buildingFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    buildingFrame.BorderSizePixel = 0
    buildingFrame.Parent = shopFrame
    
    local buildingCorner = Instance.new("UICorner")
    buildingCorner.CornerRadius = UDim.new(0, 10)
    buildingCorner.Parent = buildingFrame
    
    -- 建筑网格
    local buildingScrollFrame = Instance.new("ScrollingFrame")
    buildingScrollFrame.Name = "BuildingScrollFrame"
    buildingScrollFrame.Size = UDim2.new(1, -20, 0.7, -10)
    buildingScrollFrame.Position = UDim2.new(0, 10, 0, 10)
    buildingScrollFrame.BackgroundTransparency = 1
    buildingScrollFrame.BorderSizePixel = 0
    buildingScrollFrame.ScrollBarThickness = 10
    buildingScrollFrame.Parent = buildingFrame
    
    local buildingGrid = Instance.new("UIGridLayout")
    buildingGrid.CellSize = UDim2.new(0, 150, 0, 180)
    buildingGrid.CellPadding = UDim2.new(0, 10, 0, 10)
    buildingGrid.SortOrder = Enum.SortOrder.Name
    buildingGrid.Parent = buildingScrollFrame
    
    -- 建筑详情面板
    local detailFrame = Instance.new("Frame")
    detailFrame.Name = "DetailFrame"
    detailFrame.Size = UDim2.new(1, -20, 0.3, -20)
    detailFrame.Position = UDim2.new(0, 10, 0.7, 10)
    detailFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    detailFrame.BorderSizePixel = 0
    detailFrame.Parent = buildingFrame
    
    local detailCorner = Instance.new("UICorner")
    detailCorner.CornerRadius = UDim.new(0, 8)
    detailCorner.Parent = detailFrame
    
    -- 详情内容
    local detailLabel = Instance.new("TextLabel")
    detailLabel.Name = "DetailLabel"
    detailLabel.Size = UDim2.new(0.7, -20, 1, -20)
    detailLabel.Position = UDim2.new(0, 10, 0, 10)
    detailLabel.BackgroundTransparency = 1
    detailLabel.Text = "选择一个建筑查看详情"
    detailLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    detailLabel.TextScaled = true
    detailLabel.Font = Enum.Font.SourceSans
    detailLabel.TextXAlignment = Enum.TextXAlignment.Left
    detailLabel.TextYAlignment = Enum.TextYAlignment.Top
    detailLabel.Parent = detailFrame
    
    -- 购买按钮
    local purchaseButton = Instance.new("TextButton")
    purchaseButton.Name = "PurchaseButton"
    purchaseButton.Size = UDim2.new(0.3, -20, 0, 50)
    purchaseButton.Position = UDim2.new(0.7, 10, 0, 10)
    purchaseButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    purchaseButton.BorderSizePixel = 0
    purchaseButton.Text = "💰 购买建筑"
    purchaseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    purchaseButton.TextScaled = true
    purchaseButton.Font = Enum.Font.SourceSansBold
    purchaseButton.Visible = false
    purchaseButton.Parent = detailFrame
    
    local purchaseCorner = Instance.new("UICorner")
    purchaseCorner.CornerRadius = UDim.new(0, 8)
    purchaseCorner.Parent = purchaseButton
    
    purchaseButton.MouseButton1Click:Connect(function()
        BuildingShopUI.PurchaseBuilding()
    end)
end

-- 创建管理内容
local function createManageContent(parent)
    local manageFrame = Instance.new("Frame")
    manageFrame.Name = "ManageFrame"
    manageFrame.Size = UDim2.new(1, 0, 1, 0)
    manageFrame.Position = UDim2.new(0, 0, 0, 0)
    manageFrame.BackgroundTransparency = 1
    manageFrame.Visible = false
    manageFrame.Parent = parent
    
    -- 已建造建筑列表
    local buildingListFrame = Instance.new("Frame")
    buildingListFrame.Name = "BuildingListFrame"
    buildingListFrame.Size = UDim2.new(0.6, -10, 1, 0)
    buildingListFrame.Position = UDim2.new(0, 0, 0, 0)
    buildingListFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    buildingListFrame.BorderSizePixel = 0
    buildingListFrame.Parent = manageFrame
    
    local listCorner = Instance.new("UICorner")
    listCorner.CornerRadius = UDim.new(0, 10)
    listCorner.Parent = buildingListFrame
    
    -- 列表标题
    local listTitle = Instance.new("TextLabel")
    listTitle.Name = "ListTitle"
    listTitle.Size = UDim2.new(1, -20, 0, 40)
    listTitle.Position = UDim2.new(0, 10, 0, 10)
    listTitle.BackgroundTransparency = 1
    listTitle.Text = "📋 已建造建筑列表"
    listTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    listTitle.TextScaled = true
    listTitle.Font = Enum.Font.SourceSansBold
    listTitle.TextXAlignment = Enum.TextXAlignment.Left
    listTitle.Parent = buildingListFrame
    
    -- 建筑列表滚动框
    local listScrollFrame = Instance.new("ScrollingFrame")
    listScrollFrame.Name = "ListScrollFrame"
    listScrollFrame.Size = UDim2.new(1, -20, 1, -60)
    listScrollFrame.Position = UDim2.new(0, 10, 0, 50)
    listScrollFrame.BackgroundTransparency = 1
    listScrollFrame.BorderSizePixel = 0
    listScrollFrame.ScrollBarThickness = 8
    listScrollFrame.Parent = buildingListFrame
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.Name
    listLayout.Padding = UDim.new(0, 5)
    listLayout.Parent = listScrollFrame
    
    -- 右侧操作面板
    local operationFrame = Instance.new("Frame")
    operationFrame.Name = "OperationFrame"
    operationFrame.Size = UDim2.new(0.4, -10, 1, 0)
    operationFrame.Position = UDim2.new(0.6, 10, 0, 0)
    operationFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    operationFrame.BorderSizePixel = 0
    operationFrame.Parent = manageFrame
    
    local operationCorner = Instance.new("UICorner")
    operationCorner.CornerRadius = UDim.new(0, 10)
    operationCorner.Parent = operationFrame
    
    -- 操作面板内容
    local operationTitle = Instance.new("TextLabel")
    operationTitle.Name = "OperationTitle"
    operationTitle.Size = UDim2.new(1, -20, 0, 40)
    operationTitle.Position = UDim2.new(0, 10, 0, 10)
    operationTitle.BackgroundTransparency = 1
    operationTitle.Text = "⚙️ 建筑操作"
    operationTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    operationTitle.TextScaled = true
    operationTitle.Font = Enum.Font.SourceSansBold
    operationTitle.TextXAlignment = Enum.TextXAlignment.Left
    operationTitle.Parent = operationFrame
    
    -- 建筑信息显示
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Name = "InfoLabel"
    infoLabel.Size = UDim2.new(1, -20, 0, 200)
    infoLabel.Position = UDim2.new(0, 10, 0, 60)
    infoLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    infoLabel.BorderSizePixel = 0
    infoLabel.Text = "选择一个建筑查看详情"
    infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    infoLabel.TextScaled = true
    infoLabel.Font = Enum.Font.SourceSans
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.TextYAlignment = Enum.TextYAlignment.Top
    infoLabel.Parent = operationFrame
    
    local infoCorner = Instance.new("UICorner")
    infoCorner.CornerRadius = UDim.new(0, 8)
    infoCorner.Parent = infoLabel
    
    -- 操作按钮
    local buttonFrame = Instance.new("Frame")
    buttonFrame.Name = "ButtonFrame"
    buttonFrame.Size = UDim2.new(1, -20, 0, 150)
    buttonFrame.Position = UDim2.new(0, 10, 0, 280)
    buttonFrame.BackgroundTransparency = 1
    buttonFrame.Parent = operationFrame
    
    local upgradeButton = Instance.new("TextButton")
    upgradeButton.Name = "UpgradeButton"
    upgradeButton.Size = UDim2.new(1, 0, 0, 45)
    upgradeButton.Position = UDim2.new(0, 0, 0, 0)
    upgradeButton.BackgroundColor3 = Color3.fromRGB(50, 150, 200)
    upgradeButton.BorderSizePixel = 0
    upgradeButton.Text = "⬆️ 升级建筑"
    upgradeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    upgradeButton.TextScaled = true
    upgradeButton.Font = Enum.Font.SourceSansBold
    upgradeButton.Parent = buttonFrame
    
    local upgradeCorner = Instance.new("UICorner")
    upgradeCorner.CornerRadius = UDim.new(0, 8)
    upgradeCorner.Parent = upgradeButton
    
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = UDim2.new(1, 0, 0, 45)
    toggleButton.Position = UDim2.new(0, 0, 0, 55)
    toggleButton.BackgroundColor3 = Color3.fromRGB(200, 150, 50)
    toggleButton.BorderSizePixel = 0
    toggleButton.Text = "⏸️ 暂停/启动"
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.TextScaled = true
    toggleButton.Font = Enum.Font.SourceSansBold
    toggleButton.Parent = buttonFrame
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 8)
    toggleCorner.Parent = toggleButton
    
    local removeButton = Instance.new("TextButton")
    removeButton.Name = "RemoveButton"
    removeButton.Size = UDim2.new(1, 0, 0, 45)
    removeButton.Position = UDim2.new(0, 0, 0, 110)
    removeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    removeButton.BorderSizePixel = 0
    removeButton.Text = "🗑️ 拆除建筑"
    removeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    removeButton.TextScaled = true
    removeButton.Font = Enum.Font.SourceSansBold
    removeButton.Parent = buttonFrame
    
    local removeCorner = Instance.new("UICorner")
    removeCorner.CornerRadius = UDim.new(0, 8)
    removeCorner.Parent = removeButton
    
    -- 绑定操作按钮事件
    upgradeButton.MouseButton1Click:Connect(function()
        BuildingShopUI.UpgradeSelectedBuilding()
    end)
    
    toggleButton.MouseButton1Click:Connect(function()
        BuildingShopUI.ToggleSelectedBuilding()
    end)
    
    removeButton.MouseButton1Click:Connect(function()
        BuildingShopUI.RemoveSelectedBuilding()
    end)
end

--------------------------------------------------------------------
-- 建筑卡片创建
--------------------------------------------------------------------

-- 创建建筑卡片
local function createBuildingCard(buildingType, config, parent)
    local cardFrame = Instance.new("Frame")
    cardFrame.Name = buildingType .. "Card"
    cardFrame.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
    cardFrame.BorderSizePixel = 0
    cardFrame.Parent = parent
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 10)
    cardCorner.Parent = cardFrame
    
    -- 建筑图标
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Name = "IconLabel"
    iconLabel.Size = UDim2.new(1, -10, 0, 60)
    iconLabel.Position = UDim2.new(0, 5, 0, 5)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = config.icon
    iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    iconLabel.TextScaled = true
    iconLabel.Font = Enum.Font.SourceSansBold
    iconLabel.Parent = cardFrame
    
    -- 建筑名称
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, -10, 0, 25)
    nameLabel.Position = UDim2.new(0, 5, 0, 70)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = config.name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.Parent = cardFrame
    
    -- 价格标签
    local priceLabel = Instance.new("TextLabel")
    priceLabel.Name = "PriceLabel"
    priceLabel.Size = UDim2.new(1, -10, 0, 20)
    priceLabel.Position = UDim2.new(0, 5, 0, 100)
    priceLabel.BackgroundTransparency = 1
    priceLabel.Text = "💰 " .. config.baseCost .. " Credits"
    priceLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    priceLabel.TextScaled = true
    priceLabel.Font = Enum.Font.SourceSans
    priceLabel.Parent = cardFrame
    
    -- 解锁状态
    local unlockCondition = GameConstants.BUILDING_UNLOCK_CONDITIONS[buildingType]
    local isUnlocked = true -- 这里应该根据玩家数据判断
    
    if not isUnlocked then
        cardFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        
        local lockLabel = Instance.new("TextLabel")
        lockLabel.Name = "LockLabel"
        lockLabel.Size = UDim2.new(1, -10, 0, 20)
        lockLabel.Position = UDim2.new(0, 5, 0, 125)
        lockLabel.BackgroundTransparency = 1
        lockLabel.Text = string.format("🔒 需要Tier %d", unlockCondition.tier)
        lockLabel.TextColor3 = Color3.fromRGB(200, 100, 100)
        lockLabel.TextScaled = true
        lockLabel.Font = Enum.Font.SourceSans
        lockLabel.Parent = cardFrame
    end
    
    -- 选择状态
    local selectFrame = Instance.new("Frame")
    selectFrame.Name = "SelectFrame"
    selectFrame.Size = UDim2.new(1, 0, 1, 0)
    selectFrame.Position = UDim2.new(0, 0, 0, 0)
    selectFrame.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
    selectFrame.BackgroundTransparency = 0.8
    selectFrame.BorderSizePixel = 0
    selectFrame.Visible = false
    selectFrame.Parent = cardFrame
    
    local selectCorner = Instance.new("UICorner")
    selectCorner.CornerRadius = UDim.new(0, 10)
    selectCorner.Parent = selectFrame
    
    -- 点击事件
    local clickDetector = Instance.new("TextButton")
    clickDetector.Name = "ClickDetector"
    clickDetector.Size = UDim2.new(1, 0, 1, 0)
    clickDetector.Position = UDim2.new(0, 0, 0, 0)
    clickDetector.BackgroundTransparency = 1
    clickDetector.Text = ""
    clickDetector.Parent = cardFrame
    
    clickDetector.MouseButton1Click:Connect(function()
        if isUnlocked then
            BuildingShopUI.SelectBuilding(buildingType, config)
        end
    end)
    
    return cardFrame
end

--------------------------------------------------------------------
-- UI管理函数
--------------------------------------------------------------------

-- 打开建筑商店UI
function BuildingShopUI.OpenUI()
    if BuildingShopUI.isOpen then return end
    
    if not BuildingShopUI.gui then
        BuildingShopUI.gui = createMainUI()
    end
    
    BuildingShopUI.isOpen = true
    BuildingShopUI.gui.MainFrame.Visible = true
    
    -- 更新数据
    BuildingShopUI.RefreshData()
    
    -- 默认选择生产类建筑
    BuildingShopUI.SelectCategory("PRODUCTION")
    
    print("[BuildingShopUI] 建筑商店界面已打开")
end

-- 关闭建筑商店UI
function BuildingShopUI.CloseUI()
    if not BuildingShopUI.isOpen then return end
    
    BuildingShopUI.isOpen = false
    if BuildingShopUI.gui then
        BuildingShopUI.gui.MainFrame.Visible = false
    end
    
    print("[BuildingShopUI] 建筑商店界面已关闭")
end

-- 切换Tab
function BuildingShopUI.SwitchTab(tabName)
    if BuildingShopUI.currentTab == tabName then return end
    
    BuildingShopUI.currentTab = tabName
    
    local shopFrame = BuildingShopUI.gui.MainFrame.ContentFrame.ShopFrame
    local manageFrame = BuildingShopUI.gui.MainFrame.ContentFrame.ManageFrame
    local shopTab = BuildingShopUI.gui.MainFrame.TitleBar.TabFrame.ShopTab
    local manageTab = BuildingShopUI.gui.MainFrame.TitleBar.TabFrame.ManageTab
    
    if tabName == "shop" then
        shopFrame.Visible = true
        manageFrame.Visible = false
        
        shopTab.BackgroundColor3 = Color3.fromRGB(50, 120, 200)
        shopTab.TextColor3 = Color3.fromRGB(255, 255, 255)
        shopTab.Font = Enum.Font.SourceSansBold
        
        manageTab.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
        manageTab.TextColor3 = Color3.fromRGB(200, 200, 200)
        manageTab.Font = Enum.Font.SourceSans
        
    elseif tabName == "manage" then
        shopFrame.Visible = false
        manageFrame.Visible = true
        
        shopTab.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
        shopTab.TextColor3 = Color3.fromRGB(200, 200, 200)
        shopTab.Font = Enum.Font.SourceSans
        
        manageTab.BackgroundColor3 = Color3.fromRGB(50, 120, 200)
        manageTab.TextColor3 = Color3.fromRGB(255, 255, 255)
        manageTab.Font = Enum.Font.SourceSansBold
        
        -- 刷新管理页面数据
        BuildingShopUI.RefreshManageData()
    end
    
    print("[BuildingShopUI] 切换到标签: " .. tabName)
end

-- 选择建筑分类
function BuildingShopUI.SelectCategory(categoryKey)
    if BuildingShopUI.selectedCategory == categoryKey then return end
    
    BuildingShopUI.selectedCategory = categoryKey
    
    -- 更新分类按钮样式
    local categoryFrame = BuildingShopUI.gui.MainFrame.ContentFrame.ShopFrame.CategoryFrame
    for _, button in ipairs(categoryFrame:GetChildren()) do
        if button:IsA("TextButton") then
            if button.Name == categoryKey .. "Button" then
                button.BackgroundTransparency = 0
                button.TextColor3 = Color3.fromRGB(255, 255, 255)
            else
                button.BackgroundTransparency = 0.3
                button.TextColor3 = Color3.fromRGB(200, 200, 200)
            end
        end
    end
    
    -- 刷新建筑列表
    BuildingShopUI.RefreshBuildingList(categoryKey)
    
    print("[BuildingShopUI] 选择分类: " .. categoryKey)
end

-- 刷新建筑列表
function BuildingShopUI.RefreshBuildingList(categoryKey)
    local scrollFrame = BuildingShopUI.gui.MainFrame.ContentFrame.ShopFrame.BuildingFrame.BuildingScrollFrame
    
    -- 清空现有建筑
    for _, child in ipairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- 添加该分类的建筑
    local buildings = GameConstants.BUILDING_TYPES[categoryKey]
    if buildings then
        for buildingType, config in pairs(buildings) do
            createBuildingCard(buildingType, config, scrollFrame)
        end
    end
    
    -- 更新滚动框大小
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, scrollFrame.UIGridLayout.AbsoluteContentSize.Y + 20)
end

-- 选择建筑
function BuildingShopUI.SelectBuilding(buildingType, config)
    BuildingShopUI.selectedBuilding = {
        type = buildingType,
        config = config
    }
    
    -- 更新建筑详情
    local detailFrame = BuildingShopUI.gui.MainFrame.ContentFrame.ShopFrame.BuildingFrame.DetailFrame
    local detailLabel = detailFrame.DetailLabel
    local purchaseButton = detailFrame.PurchaseButton
    
    local detailText = string.format(
        "%s %s\n\n📖 %s\n\n💰 基础费用: %d Credits\n⚡ 能耗: %d/分钟\n📏 尺寸: %.0fx%.0fx%.0f",
        config.icon, config.name,
        config.description,
        config.baseCost,
        config.energyConsumption or 0,
        config.baseSize.X, config.baseSize.Y, config.baseSize.Z
    )
    
    if config.energyProduction then
        detailText = detailText .. string.format("\n⚡ 发电: %d/分钟", config.energyProduction)
    end
    
    if config.beautyValue then
        detailText = detailText .. string.format("\n✨ 美观度: %d", config.beautyValue)
    end
    
    detailLabel.Text = detailText
    purchaseButton.Visible = true
    
    -- 更新选择状态
    local scrollFrame = BuildingShopUI.gui.MainFrame.ContentFrame.ShopFrame.BuildingFrame.BuildingScrollFrame
    for _, card in ipairs(scrollFrame:GetChildren()) do
        if card:IsA("Frame") then
            local selectFrame = card:FindFirstChild("SelectFrame")
            if selectFrame then
                selectFrame.Visible = (card.Name == buildingType .. "Card")
            end
        end
    end
    
    print("[BuildingShopUI] 选择建筑: " .. buildingType)
end

-- 购买建筑
function BuildingShopUI.PurchaseBuilding()
    if not BuildingShopUI.selectedBuilding then
        print("[BuildingShopUI] 没有选择建筑")
        return
    end
    
    local buildingType = BuildingShopUI.selectedBuilding.type
    
    -- 关闭商店界面
    BuildingShopUI.CloseUI()
    
    -- 启动建筑放置模式
    if _G.BuildingPlacement then
        _G.BuildingPlacement.StartPlacing(buildingType)
        print("[BuildingShopUI] 开始放置建筑: " .. buildingType)
    else
        warn("[BuildingShopUI] BuildingPlacement系统未找到")
    end
end

-- 刷新数据
function BuildingShopUI.RefreshData()
    -- 请求玩家建筑数据
    placeBuildingEvent:FireServer("GET_BUILDINGS")
    
    -- TODO: 获取玩家游戏数据
    
    print("[BuildingShopUI] 数据已刷新")
end

-- 刷新管理数据
function BuildingShopUI.RefreshManageData()
    if BuildingShopUI.currentTab ~= "manage" then return end
    
    local listScrollFrame = BuildingShopUI.gui.MainFrame.ContentFrame.ManageFrame.BuildingListFrame.ListScrollFrame
    
    -- 清空现有列表
    for _, child in ipairs(listScrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- 添加已建造建筑
    for buildingId, building in pairs(BuildingShopUI.playerBuildings) do
        local listItem = Instance.new("Frame")
        listItem.Name = buildingId
        listItem.Size = UDim2.new(1, -10, 0, 60)
        listItem.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        listItem.BorderSizePixel = 0
        listItem.Parent = listScrollFrame
        
        local itemCorner = Instance.new("UICorner")
        itemCorner.CornerRadius = UDim.new(0, 8)
        itemCorner.Parent = listItem
        
        local iconLabel = Instance.new("TextLabel")
        iconLabel.Size = UDim2.new(0, 50, 1, 0)
        iconLabel.Position = UDim2.new(0, 5, 0, 0)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Text = building.config.icon
        iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        iconLabel.TextScaled = true
        iconLabel.Font = Enum.Font.SourceSansBold
        iconLabel.Parent = listItem
        
        local infoLabel = Instance.new("TextLabel")
        infoLabel.Size = UDim2.new(1, -120, 1, -10)
        infoLabel.Position = UDim2.new(0, 60, 0, 5)
        infoLabel.BackgroundTransparency = 1
        infoLabel.Text = string.format("%s (Lv%d)\n状态: %s", 
            building.config.name, building.level, 
            building.status == "active" and "运行中" or "已暂停")
        infoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        infoLabel.TextScaled = true
        infoLabel.Font = Enum.Font.SourceSans
        infoLabel.TextXAlignment = Enum.TextXAlignment.Left
        infoLabel.Parent = listItem
        
        local selectButton = Instance.new("TextButton")
        selectButton.Size = UDim2.new(0, 50, 0, 40)
        selectButton.Position = UDim2.new(1, -55, 0, 10)
        selectButton.BackgroundColor3 = Color3.fromRGB(50, 120, 200)
        selectButton.BorderSizePixel = 0
        selectButton.Text = "选择"
        selectButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        selectButton.TextScaled = true
        selectButton.Font = Enum.Font.SourceSansBold
        selectButton.Parent = listItem
        
        local selectCorner = Instance.new("UICorner")
        selectCorner.CornerRadius = UDim.new(0, 6)
        selectCorner.Parent = selectButton
        
        selectButton.MouseButton1Click:Connect(function()
            BuildingShopUI.SelectBuildingForManage(buildingId, building)
        end)
    end
    
    -- 更新滚动框大小
    listScrollFrame.CanvasSize = UDim2.new(0, 0, 0, listScrollFrame.UIListLayout.AbsoluteContentSize.Y + 20)
    
    print("[BuildingShopUI] 管理数据已刷新")
end

-- 选择要管理的建筑
function BuildingShopUI.SelectBuildingForManage(buildingId, building)
    BuildingShopUI.selectedBuildingForManage = {
        id = buildingId,
        data = building
    }
    
    -- 更新操作面板
    local operationFrame = BuildingShopUI.gui.MainFrame.ContentFrame.ManageFrame.OperationFrame
    local infoLabel = operationFrame.InfoLabel
    
    local infoText = string.format(
        "%s %s (Lv%d)\n\n📍 位置: %.1f, %.1f, %.1f\n⚡ 状态: %s\n🔧 建造时间: %s\n\n📊 统计:\n- 能耗: %d/分钟\n- 最大等级: %d",
        building.config.icon, building.config.name, building.level,
        building.position.X, building.position.Y, building.position.Z,
        building.status == "active" and "运行中" or "已暂停",
        os.date("%Y-%m-%d %H:%M", building.placedTime),
        building.config.energyConsumption or 0,
        building.config.maxLevel
    )
    
    infoLabel.Text = infoText
    
    print("[BuildingShopUI] 选择管理建筑: " .. buildingId)
end

-- 升级选中建筑
function BuildingShopUI.UpgradeSelectedBuilding()
    if not BuildingShopUI.selectedBuildingForManage then
        print("[BuildingShopUI] 没有选择要升级的建筑")
        return
    end
    
    local buildingId = BuildingShopUI.selectedBuildingForManage.id
    placeBuildingEvent:FireServer("UPGRADE", { buildingId = buildingId })
    
    print("[BuildingShopUI] 发送升级请求: " .. buildingId)
end

-- 切换选中建筑状态
function BuildingShopUI.ToggleSelectedBuilding()
    if not BuildingShopUI.selectedBuildingForManage then
        print("[BuildingShopUI] 没有选择要切换的建筑")
        return
    end
    
    local buildingId = BuildingShopUI.selectedBuildingForManage.id
    manageBuildingEvent:FireServer("TOGGLE_BUILDING", { buildingId = buildingId })
    
    print("[BuildingShopUI] 发送状态切换请求: " .. buildingId)
end

-- 移除选中建筑
function BuildingShopUI.RemoveSelectedBuilding()
    if not BuildingShopUI.selectedBuildingForManage then
        print("[BuildingShopUI] 没有选择要移除的建筑")
        return
    end
    
    local buildingId = BuildingShopUI.selectedBuildingForManage.id
    placeBuildingEvent:FireServer("REMOVE", { buildingId = buildingId })
    
    print("[BuildingShopUI] 发送移除请求: " .. buildingId)
end

--------------------------------------------------------------------
-- 键盘控制
--------------------------------------------------------------------

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.B then
        -- B键切换建筑商店界面
        if BuildingShopUI.isOpen then
            BuildingShopUI.CloseUI()
        else
            BuildingShopUI.OpenUI()
        end
    end
end)

--------------------------------------------------------------------
-- 服务器事件处理
--------------------------------------------------------------------

-- 处理建筑放置事件响应
placeBuildingEvent.OnClientEvent:Connect(function(action, data)
    if action == "BUILDINGS_LIST" then
        BuildingShopUI.playerBuildings = data
        if BuildingShopUI.isOpen and BuildingShopUI.currentTab == "manage" then
            BuildingShopUI.RefreshManageData()
        end
        
    elseif action == "PLACE_SUCCESS" then
        -- 建筑放置成功，刷新数据
        BuildingShopUI.RefreshData()
        
    elseif action == "REMOVE_SUCCESS" then
        -- 建筑移除成功，刷新数据
        BuildingShopUI.RefreshData()
        BuildingShopUI.selectedBuildingForManage = nil
        
    elseif action == "UPGRADE_SUCCESS" then
        -- 建筑升级成功，刷新数据
        BuildingShopUI.RefreshData()
    end
end)

-- 处理建筑管理事件响应
manageBuildingEvent.OnClientEvent:Connect(function(action, data)
    if action == "BUILDING_TOGGLED" then
        -- 建筑状态切换成功，刷新数据
        if BuildingShopUI.selectedBuildingForManage and 
           BuildingShopUI.selectedBuildingForManage.id == data.buildingId then
            BuildingShopUI.selectedBuildingForManage.data.status = data.status
            BuildingShopUI.SelectBuildingForManage(
                BuildingShopUI.selectedBuildingForManage.id,
                BuildingShopUI.selectedBuildingForManage.data
            )
        end
        BuildingShopUI.RefreshData()
        
    elseif action == "BUILDING_ADDED" or action == "BUILDING_REMOVED" or action == "BUILDING_UPGRADED" then
        -- 建筑变更，刷新数据
        BuildingShopUI.RefreshData()
    end
end)

-- 将BuildingShopUI暴露给全局，以便其他脚本调用
_G.BuildingShopUI = BuildingShopUI

print("[BuildingShopUI] 建筑商店界面系统已启动")
print("按B键打开/关闭建筑商店界面")