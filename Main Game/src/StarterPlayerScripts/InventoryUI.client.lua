--------------------------------------------------------------------
-- InventoryUI.client.lua · Pet Simulator 99风格库存界面
-- 功能：
--   1) Items和Robots两个分类标签
--   2) Items页面显示所有物品
--   3) Robots页面显示机器人（前5个Active，其余Inactive）
--   4) 网格布局和现代UI设计
--------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 远程通讯
local rfFolder = ReplicatedStorage:WaitForChild("RemoteFunctions")
local getInventoryRF = rfFolder:WaitForChild("GetInventoryFunction")

-- 配置
local GameConstants = require(ReplicatedStorage.SharedModules.GameConstants.main)
local IconUtils = require(ReplicatedStorage.ClientUtils.IconUtils)

local BOT_SELL_PRICE = GameConstants.BOT_SELL_PRICE

-- 物品分类配置
local ITEM_TYPES = {
    Shell = {"RustyShell", "NeonCoreShell", "QuantumCapsuleShell", "EcoBoosterPodShell", "SecretPrototypeShell"},
    Material = {"Scrap", "Copper", "Crystal", "EcoCore", "BlackCore", "IronOre", "GoldOre", "DiamondOre", "TitaniumOre", "UraniumOre"},
    Tool = {"WoodPick", "IronPick", "BronzePick", "GoldPick", "DiamondPick", "WoodHammer", "IronHammer", "BronzeHammer", "GoldHammer", "DiamondHammer"}
}

local ROBOT_TYPES = {
    "Dig_UncommonBot", "Build_UncommonBot",
    "Dig_RareBot", "Build_RareBot", 
    "Dig_EpicBot", "Build_EpicBot",
    "Dig_SecretBot", "Build_SecretBot",
    "Dig_EcoBot", "Build_EcoBot"
}

--------------------------------------------------------------------
-- 创建库存UI
--------------------------------------------------------------------
local function createInventoryUI()
    -- 主界面
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "InventoryUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui
    
    -- 主框架 (Pet Sim 99风格大窗口)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 900, 0, 650)
    mainFrame.Position = UDim2.new(0.5, -450, 0.5, -325)
    mainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = mainFrame
    
    -- 标题栏
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 60)
    titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 15)
    titleCorner.Parent = titleBar
    
    -- 遮罩标题栏下方圆角
    local titleMask = Instance.new("Frame")
    titleMask.Size = UDim2.new(1, 0, 0, 15)
    titleMask.Position = UDim2.new(0, 0, 1, -15)
    titleMask.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    titleMask.BorderSizePixel = 0
    titleMask.Parent = titleBar
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -80, 1, 0)
    titleLabel.Position = UDim2.new(0, 20, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "INVENTORY"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 28
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar
    
    -- 关闭按钮
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -50, 0, 10)
    closeButton.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
    closeButton.Text = "×"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 24
    closeButton.Font = Enum.Font.GothamBold
    closeButton.BorderSizePixel = 0
    closeButton.Active = true
    closeButton.Parent = titleBar
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton
    
    -- 分类标签栏
    local tabFrame = Instance.new("Frame")
    tabFrame.Size = UDim2.new(1, -40, 0, 50)
    tabFrame.Position = UDim2.new(0, 20, 0, 80)
    tabFrame.BackgroundTransparency = 1
    tabFrame.Parent = mainFrame
    
    -- Items标签
    local itemsTab = Instance.new("TextButton")
    itemsTab.Size = UDim2.new(0, 150, 1, 0)
    itemsTab.Position = UDim2.new(0, 0, 0, 0)
    itemsTab.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
    itemsTab.Text = "ITEMS"
    itemsTab.TextColor3 = Color3.fromRGB(255, 255, 255)
    itemsTab.TextSize = 18
    itemsTab.Font = Enum.Font.GothamBold
    itemsTab.BorderSizePixel = 0
    itemsTab.Active = true
    itemsTab.Parent = tabFrame
    
    local itemsTabCorner = Instance.new("UICorner")
    itemsTabCorner.CornerRadius = UDim.new(0, 8)
    itemsTabCorner.Parent = itemsTab
    
    -- Robots标签
    local robotsTab = Instance.new("TextButton")
    robotsTab.Size = UDim2.new(0, 150, 1, 0)
    robotsTab.Position = UDim2.new(0, 170, 0, 0)
    robotsTab.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    robotsTab.Text = "ROBOTS"
    robotsTab.TextColor3 = Color3.fromRGB(200, 200, 200)
    robotsTab.TextSize = 18
    robotsTab.Font = Enum.Font.GothamBold
    robotsTab.BorderSizePixel = 0
    robotsTab.Active = true
    robotsTab.Parent = tabFrame
    
    local robotsTabCorner = Instance.new("UICorner")
    robotsTabCorner.CornerRadius = UDim.new(0, 8)
    robotsTabCorner.Parent = robotsTab
    
    -- 内容区域
    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, -40, 1, -160)
    contentFrame.Position = UDim2.new(0, 20, 0, 140)
    contentFrame.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    contentFrame.BorderSizePixel = 0
    contentFrame.Parent = mainFrame
    
    local contentCorner = Instance.new("UICorner")
    contentCorner.CornerRadius = UDim.new(0, 10)
    contentCorner.Parent = contentFrame
    
    -- Items滚动框
    local itemsScrollFrame = Instance.new("ScrollingFrame")
    itemsScrollFrame.Name = "ItemsScrollFrame"
    itemsScrollFrame.Size = UDim2.new(1, -20, 1, -20)
    itemsScrollFrame.Position = UDim2.new(0, 10, 0, 10)
    itemsScrollFrame.BackgroundTransparency = 1
    itemsScrollFrame.ScrollBarThickness = 8
    itemsScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    itemsScrollFrame.Visible = true
    itemsScrollFrame.Parent = contentFrame
    
    local itemsGrid = Instance.new("UIGridLayout")
    itemsGrid.CellSize = UDim2.new(0, 120, 0, 140)
    itemsGrid.CellPadding = UDim2.new(0, 10, 0, 10)
    itemsGrid.SortOrder = Enum.SortOrder.LayoutOrder
    itemsGrid.Parent = itemsScrollFrame
    
    -- Robots滚动框
    local robotsScrollFrame = Instance.new("ScrollingFrame")
    robotsScrollFrame.Name = "RobotsScrollFrame"
    robotsScrollFrame.Size = UDim2.new(1, -20, 1, -20)
    robotsScrollFrame.Position = UDim2.new(0, 10, 0, 10)
    robotsScrollFrame.BackgroundTransparency = 1
    robotsScrollFrame.ScrollBarThickness = 8
    robotsScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    robotsScrollFrame.Visible = false
    robotsScrollFrame.Parent = contentFrame
    
    -- Active机器人区域标题
    local activeLabel = Instance.new("TextLabel")
    activeLabel.Size = UDim2.new(1, 0, 0, 30)
    activeLabel.Position = UDim2.new(0, 0, 0, 0)
    activeLabel.BackgroundTransparency = 1
    activeLabel.Text = "ACTIVE ROBOTS (5/5)"
    activeLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    activeLabel.TextSize = 16
    activeLabel.Font = Enum.Font.GothamBold
    activeLabel.TextXAlignment = Enum.TextXAlignment.Left
    activeLabel.LayoutOrder = 1
    activeLabel.Parent = robotsScrollFrame
    
    local robotsLayout = Instance.new("UIListLayout")
    robotsLayout.Padding = UDim.new(0, 15)
    robotsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    robotsLayout.Parent = robotsScrollFrame
    
    -- Active机器人网格容器
    local activeRobotsFrame = Instance.new("Frame")
    activeRobotsFrame.Size = UDim2.new(1, 0, 0, 160)
    activeRobotsFrame.BackgroundTransparency = 1
    activeRobotsFrame.LayoutOrder = 2
    activeRobotsFrame.Parent = robotsScrollFrame
    
    local activeGrid = Instance.new("UIGridLayout")
    activeGrid.CellSize = UDim2.new(0, 140, 0, 160)
    activeGrid.CellPadding = UDim2.new(0, 10, 0, 10)
    activeGrid.SortOrder = Enum.SortOrder.LayoutOrder
    activeGrid.Parent = activeRobotsFrame
    
    -- Inactive机器人区域标题
    local inactiveLabel = Instance.new("TextLabel")
    inactiveLabel.Size = UDim2.new(1, 0, 0, 30)
    inactiveLabel.BackgroundTransparency = 1
    inactiveLabel.Text = "INACTIVE ROBOTS"
    inactiveLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    inactiveLabel.TextSize = 16
    inactiveLabel.Font = Enum.Font.GothamBold
    inactiveLabel.TextXAlignment = Enum.TextXAlignment.Left
    inactiveLabel.LayoutOrder = 3
    inactiveLabel.Parent = robotsScrollFrame
    
    -- Inactive机器人网格容器
    local inactiveRobotsFrame = Instance.new("Frame")
    inactiveRobotsFrame.Size = UDim2.new(1, 0, 0, 300)  -- 初始高度
    inactiveRobotsFrame.BackgroundTransparency = 1
    inactiveRobotsFrame.LayoutOrder = 4
    inactiveRobotsFrame.Parent = robotsScrollFrame
    
    local inactiveGrid = Instance.new("UIGridLayout")
    inactiveGrid.CellSize = UDim2.new(0, 120, 0, 140)
    inactiveGrid.CellPadding = UDim2.new(0, 10, 0, 10)
    inactiveGrid.SortOrder = Enum.SortOrder.LayoutOrder
    inactiveGrid.Parent = inactiveRobotsFrame
    
    return screenGui, mainFrame, closeButton, itemsTab, robotsTab, 
           itemsScrollFrame, robotsScrollFrame, activeRobotsFrame, inactiveRobotsFrame,
           activeLabel, inactiveLabel
end

--------------------------------------------------------------------
-- 创建物品卡片
--------------------------------------------------------------------
local function createItemCard(itemId, quantity, parent, layoutOrder)
    local cardFrame = Instance.new("Frame")
    cardFrame.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    cardFrame.BorderSizePixel = 0
    cardFrame.LayoutOrder = layoutOrder
    cardFrame.Parent = parent
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 10)
    cardCorner.Parent = cardFrame
    
    -- 物品图标
    local iconLabel = Instance.new("ImageLabel")
    iconLabel.Size = UDim2.new(0, 60, 0, 60)
    iconLabel.Position = UDim2.new(0.5, -30, 0, 15)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Image = IconUtils.getItemIcon(itemId)
    iconLabel.ScaleType = Enum.ScaleType.Fit
    iconLabel.Parent = cardFrame
    
    -- 物品名称
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -10, 0, 25)
    nameLabel.Position = UDim2.new(0, 5, 0, 80)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = itemId
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextSize = 12
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextScaled = true
    nameLabel.Parent = cardFrame
    
    -- 数量标签
    local quantityLabel = Instance.new("TextLabel")
    quantityLabel.Size = UDim2.new(1, -10, 0, 20)
    quantityLabel.Position = UDim2.new(0, 5, 0, 110)
    quantityLabel.BackgroundTransparency = 1
    quantityLabel.Text = "×" .. quantity
    quantityLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    quantityLabel.TextSize = 14
    quantityLabel.Font = Enum.Font.Gotham
    quantityLabel.TextScaled = true
    quantityLabel.Parent = cardFrame
    
    return cardFrame
end

--------------------------------------------------------------------
-- 创建机器人卡片
--------------------------------------------------------------------
local function createRobotCard(robotId, quantity, isActive, parent, layoutOrder)
    local cardFrame = Instance.new("TextButton")
    cardFrame.BackgroundColor3 = isActive and Color3.fromRGB(100, 180, 100) or Color3.fromRGB(70, 70, 70)
    cardFrame.BorderSizePixel = 0
    cardFrame.LayoutOrder = layoutOrder
    cardFrame.Parent = parent
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 10)
    cardCorner.Parent = cardFrame
    
    -- Active状态边框
    if isActive then
        local activeBorder = Instance.new("UIStroke")
        activeBorder.Color = Color3.fromRGB(150, 255, 150)
        activeBorder.Thickness = 2
        activeBorder.Parent = cardFrame
    end
    
    -- 机器人图标
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(0, 60, 0, 60)
    iconLabel.Position = UDim2.new(0.5, -30, 0, 15)
    iconLabel.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
    iconLabel.Text = "🤖"
    iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    iconLabel.TextSize = 36
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.BorderSizePixel = 0
    iconLabel.Parent = cardFrame
    
    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 8)
    iconCorner.Parent = iconLabel
    
    -- 机器人名称
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -10, 0, 25)
    nameLabel.Position = UDim2.new(0, 5, 0, 80)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = robotId:gsub("_", " ")
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextSize = 10
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextScaled = true
    nameLabel.Parent = cardFrame
    
    -- 数量/状态标签
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -10, 0, 20)
    statusLabel.Position = UDim2.new(0, 5, 0, 110)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = isActive and "ACTIVE" or ("×" .. quantity)
    statusLabel.TextColor3 = isActive and Color3.fromRGB(150, 255, 150) or Color3.fromRGB(200, 200, 200)
    statusLabel.TextSize = 12
    statusLabel.Font = isActive and Enum.Font.GothamBold or Enum.Font.Gotham
    statusLabel.TextScaled = true
    statusLabel.Parent = cardFrame
    
    return cardFrame
end

--------------------------------------------------------------------
-- 主UI控制
--------------------------------------------------------------------
local inventoryUI = nil
local currentTab = "Items"  -- "Items" or "Robots"

-- 显示库存UI
function showInventoryUI()
    print("[InventoryUI] showInventoryUI() 被调用")
    if not inventoryUI then
        print("[InventoryUI] 创建新的库存UI")
        local ui, mainFrame, closeButton, itemsTab, robotsTab, 
              itemsScrollFrame, robotsScrollFrame, activeRobotsFrame, inactiveRobotsFrame,
              activeLabel, inactiveLabel = createInventoryUI()
        
        print("[InventoryUI] UI组件创建完成")
        
        inventoryUI = {
            gui = ui,
            mainFrame = mainFrame,
            closeButton = closeButton,
            itemsTab = itemsTab,
            robotsTab = robotsTab,
            itemsScrollFrame = itemsScrollFrame,
            robotsScrollFrame = robotsScrollFrame,
            activeRobotsFrame = activeRobotsFrame,
            inactiveRobotsFrame = inactiveRobotsFrame,
            activeLabel = activeLabel,
            inactiveLabel = inactiveLabel
        }
        
        -- 关闭按钮事件
        closeButton.MouseButton1Click:Connect(function()
            hideInventoryUI()
        end)
        
        -- 标签切换事件
        itemsTab.MouseButton1Click:Connect(function()
            switchTab("Items")
        end)
        
        robotsTab.MouseButton1Click:Connect(function()
            switchTab("Robots")
        end)
    end
    
    print("[InventoryUI] 开始更新UI数据")
    updateInventoryUI()
    
    print("[InventoryUI] 开始显示动画")
    -- 显示动画
    inventoryUI.mainFrame.Visible = true
    inventoryUI.mainFrame.Size = UDim2.new(0, 0, 0, 0)
    inventoryUI.mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    local tween = TweenService:Create(inventoryUI.mainFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0, 900, 0, 650),
            Position = UDim2.new(0.5, -450, 0.5, -325)
        }
    )
    tween:Play()
    print("[InventoryUI] 动画播放完成")
end

-- 隐藏库存UI
function hideInventoryUI()
    if not inventoryUI then return end
    
    local tween = TweenService:Create(inventoryUI.mainFrame,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }
    )
    tween:Play()
    
    tween.Completed:Connect(function()
        inventoryUI.mainFrame.Visible = false
    end)
end

-- 切换标签
function switchTab(tabName)
    currentTab = tabName
    
    if tabName == "Items" then
        -- 激活Items标签
        inventoryUI.itemsTab.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
        inventoryUI.itemsTab.TextColor3 = Color3.fromRGB(255, 255, 255)
        inventoryUI.robotsTab.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        inventoryUI.robotsTab.TextColor3 = Color3.fromRGB(200, 200, 200)
        
        -- 显示Items内容
        inventoryUI.itemsScrollFrame.Visible = true
        inventoryUI.robotsScrollFrame.Visible = false
    else
        -- 激活Robots标签
        inventoryUI.robotsTab.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
        inventoryUI.robotsTab.TextColor3 = Color3.fromRGB(255, 255, 255)
        inventoryUI.itemsTab.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        inventoryUI.itemsTab.TextColor3 = Color3.fromRGB(200, 200, 200)
        
        -- 显示Robots内容
        inventoryUI.itemsScrollFrame.Visible = false
        inventoryUI.robotsScrollFrame.Visible = true
    end
end

-- 更新库存UI
function updateInventoryUI()
    if not inventoryUI then return end
    
    local inventory
    
    -- 先尝试从服务器获取数据
    local success = pcall(function()
        inventory = getInventoryRF:InvokeServer()
    end)
    
    if not success or not inventory then 
        print("[InventoryUI] 无法获取库存数据，使用测试数据")
        -- 使用测试数据显示UI功能
        inventory = {
            {itemId = "RustyShell", quantity = 5},
            {itemId = "NeonCoreShell", quantity = 2}, 
            {itemId = "Scrap", quantity = 150},
            {itemId = "Copper", quantity = 10},
            {itemId = "WoodPick", quantity = 1},
            {itemId = "Dig_UncommonBot", quantity = 3},
            {itemId = "Build_UncommonBot", quantity = 2},
            {itemId = "Dig_RareBot", quantity = 1}
        }
    end
    
    print("[InventoryUI] 库存数据:", inventory and #inventory or "nil")
    
    -- 清除旧内容
    for _, child in pairs(inventoryUI.itemsScrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    for _, child in pairs(inventoryUI.activeRobotsFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    for _, child in pairs(inventoryUI.inactiveRobotsFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    -- 分类物品和机器人
    local items = {}
    local robots = {}
    
    for _, item in pairs(inventory) do
        if BOT_SELL_PRICE[item.itemId] then
            -- 这是机器人
            table.insert(robots, item)
        else
            -- 这是物品
            table.insert(items, item)
        end
    end
    
    -- 创建物品卡片
    for i, item in ipairs(items) do
        createItemCard(item.itemId, item.quantity, inventoryUI.itemsScrollFrame, i)
    end
    
    -- 设置Items滚动框大小
    local itemsPerRow = 7
    local itemRows = math.ceil(#items / itemsPerRow)
    inventoryUI.itemsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, itemRows * 150)
    
    -- 创建机器人卡片 (前5个Active，其余Inactive)
    local activeCount = 0
    local inactiveCount = 0
    
    for i, robot in ipairs(robots) do
        for j = 1, robot.quantity do
            if activeCount < 5 then
                -- Active机器人
                activeCount = activeCount + 1
                createRobotCard(robot.itemId, 1, true, inventoryUI.activeRobotsFrame, activeCount)
            else
                -- Inactive机器人
                inactiveCount = inactiveCount + 1
                createRobotCard(robot.itemId, 1, false, inventoryUI.inactiveRobotsFrame, inactiveCount)
            end
        end
    end
    
    -- 更新标签
    inventoryUI.activeLabel.Text = string.format("ACTIVE ROBOTS (%d/5)", activeCount)
    inventoryUI.inactiveLabel.Text = string.format("INACTIVE ROBOTS (%d)", inactiveCount)
    
    -- 设置Inactive机器人区域大小
    local inactivePerRow = 6
    local inactiveRows = math.ceil(inactiveCount / inactivePerRow)
    inventoryUI.inactiveRobotsFrame.Size = UDim2.new(1, 0, 0, math.max(150, inactiveRows * 150))
    
    -- 设置Robots滚动框大小
    inventoryUI.robotsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 30 + 160 + 15 + 30 + math.max(150, inactiveRows * 150) + 20)
end

-- 设置StarterGui中的打开按钮
local function setupOpenButton()
    local starterGui = player:WaitForChild("PlayerGui")
    
    -- 等待StarterGui中的InventoryUI
    task.spawn(function()
        local inventoryUIGui = starterGui:WaitForChild("InventoryUI", 10)
        if inventoryUIGui then
            local openButton = inventoryUIGui:WaitForChild("OpenButton", 5)
            if openButton then
                print("[InventoryUI] 找到StarterGui中的OpenButton")
                openButton.MouseButton1Click:Connect(function()
                    print("[InventoryUI] OpenButton被点击")
                    if inventoryUI and inventoryUI.mainFrame.Visible then
                        hideInventoryUI()
                    else
                        showInventoryUI()
                    end
                end)
            else
                print("[InventoryUI] 未找到OpenButton")
            end
        else
            print("[InventoryUI] 未找到StarterGui中的InventoryUI")
        end
    end)
end

-- 键盘快捷键
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end
    
    -- B键打开/关闭库存
    if input.KeyCode == Enum.KeyCode.B then
        print("[InventoryUI] B键被按下!")  -- 调试信息
        if inventoryUI and inventoryUI.mainFrame.Visible then
            print("[InventoryUI] 关闭库存")
            hideInventoryUI()
        else
            print("[InventoryUI] 打开库存")
            showInventoryUI()
        end
    -- ESC关闭库存
    elseif input.KeyCode == Enum.KeyCode.Escape and inventoryUI and inventoryUI.mainFrame.Visible then
        hideInventoryUI()
    end
end)

-- 初始化系统
task.spawn(function()
    task.wait(1)  -- 等待1秒确保系统启动
    setupOpenButton()  -- 设置StarterGui按钮
    print("[InventoryUI] 系统准备就绪 - 按B键或点击按钮打开库存")
end)

print("[InventoryUI] Pet Simulator 99风格库存UI系统已加载 - 按B键或点击按钮打开")