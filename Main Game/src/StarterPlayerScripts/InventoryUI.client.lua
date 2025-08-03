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

-- Active机器人管理
local reFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local setActiveRobotEvent = reFolder:WaitForChild("SetActiveRobotEvent")

-- 任务管理RemoteEvents（如果不存在则等待）
local miningTaskEvent = nil
task.spawn(function()
    miningTaskEvent = reFolder:WaitForChild("MiningTaskEvent", 10)
    if not miningTaskEvent then
        warn("[InventoryUI] MiningTaskEvent不存在，任务功能将不可用")
    end
end)

-- 玩家的Active机器人状态
local activeRobots = {} -- [slotIndex] = robotType

-- UI组件
local inventoryUI = nil -- 主库存界面
local taskAssignmentUI = nil
local rightClickMenu = nil
local selectedOreType = nil
local currentTaskRobot = nil

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

-- 矿物类型配置（移除Scrap，它不是挖矿获得的）
local MINE_ORES = {
    "Stone", "IronOre", "BronzeOre", 
    "GoldOre", "DiamondOre", "TitaniumOre", "UraniumOre"
}

-- 矿物图标现在使用IconUtils.getItemIcon()获取

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
-- 创建机器人任务派发UI
--------------------------------------------------------------------
local function createTaskAssignmentUI(parent)
    -- 主任务窗口
    local taskFrame = Instance.new("Frame")
    taskFrame.Name = "TaskAssignmentFrame"
    taskFrame.Size = UDim2.new(0, 400, 0, 600)
    taskFrame.Position = UDim2.new(0.5, -200, 0.5, -300)
    taskFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    taskFrame.BorderSizePixel = 0
    taskFrame.Visible = false
    taskFrame.Parent = parent
    
    local taskCorner = Instance.new("UICorner")
    taskCorner.CornerRadius = UDim.new(0, 12)
    taskCorner.Parent = taskFrame
    
    -- 标题栏
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 50)
    titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = taskFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar
    
    local titleMask = Instance.new("Frame")
    titleMask.Size = UDim2.new(1, 0, 0, 12)
    titleMask.Position = UDim2.new(0, 0, 1, -12)
    titleMask.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    titleMask.BorderSizePixel = 0
    titleMask.Parent = titleBar
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -60, 1, 0)
    titleLabel.Position = UDim2.new(0, 15, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "ASSIGN MINING TASK"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar
    
    -- 关闭按钮
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -40, 0, 10)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    closeButton.Text = "×"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 18
    closeButton.Font = Enum.Font.GothamBold
    closeButton.BorderSizePixel = 0
    closeButton.Parent = titleBar
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeButton
    
    -- 机器人信息区域
    local robotInfoFrame = Instance.new("Frame")
    robotInfoFrame.Size = UDim2.new(1, -20, 0, 80)
    robotInfoFrame.Position = UDim2.new(0, 10, 0, 60)
    robotInfoFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    robotInfoFrame.BorderSizePixel = 0
    robotInfoFrame.Parent = taskFrame
    
    local robotInfoCorner = Instance.new("UICorner")
    robotInfoCorner.CornerRadius = UDim.new(0, 8)
    robotInfoCorner.Parent = robotInfoFrame
    
    local robotNameLabel = Instance.new("TextLabel")
    robotNameLabel.Name = "RobotNameLabel"
    robotNameLabel.Size = UDim2.new(1, -20, 0, 25)
    robotNameLabel.Position = UDim2.new(0, 10, 0, 10)
    robotNameLabel.BackgroundTransparency = 1
    robotNameLabel.Text = "Dig_UncommonBot"
    robotNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    robotNameLabel.TextSize = 16
    robotNameLabel.Font = Enum.Font.GothamBold
    robotNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    robotNameLabel.Parent = robotInfoFrame
    
    local robotStatsLabel = Instance.new("TextLabel")
    robotStatsLabel.Name = "RobotStatsLabel"
    robotStatsLabel.Size = UDim2.new(1, -20, 0, 20)
    robotStatsLabel.Position = UDim2.new(0, 10, 0, 35)
    robotStatsLabel.BackgroundTransparency = 1
    robotStatsLabel.Text = "Mining Speed: 3.0s per ore"
    robotStatsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    robotStatsLabel.TextSize = 12
    robotStatsLabel.Font = Enum.Font.Gotham
    robotStatsLabel.TextXAlignment = Enum.TextXAlignment.Left
    robotStatsLabel.Parent = robotInfoFrame
    
    -- 矿物选择区域
    local oreSelectionFrame = Instance.new("Frame")
    oreSelectionFrame.Size = UDim2.new(1, -20, 0, 200)
    oreSelectionFrame.Position = UDim2.new(0, 10, 0, 150)
    oreSelectionFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    oreSelectionFrame.BorderSizePixel = 0
    oreSelectionFrame.Parent = taskFrame
    
    local oreSelectionCorner = Instance.new("UICorner")
    oreSelectionCorner.CornerRadius = UDim.new(0, 8)
    oreSelectionCorner.Parent = oreSelectionFrame
    
    local oreLabel = Instance.new("TextLabel")
    oreLabel.Size = UDim2.new(1, -20, 0, 25)
    oreLabel.Position = UDim2.new(0, 10, 0, 5)
    oreLabel.BackgroundTransparency = 1
    oreLabel.Text = "Select Ore Type:"
    oreLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    oreLabel.TextSize = 14
    oreLabel.Font = Enum.Font.GothamBold
    oreLabel.TextXAlignment = Enum.TextXAlignment.Left
    oreLabel.Parent = oreSelectionFrame
    
    -- 矿物网格
    local oreScrollFrame = Instance.new("ScrollingFrame")
    oreScrollFrame.Size = UDim2.new(1, -20, 1, -60)
    oreScrollFrame.Position = UDim2.new(0, 10, 0, 30)
    oreScrollFrame.BackgroundTransparency = 1
    oreScrollFrame.ScrollBarThickness = 6
    oreScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    oreScrollFrame.Parent = oreSelectionFrame
    
    local oreGrid = Instance.new("UIGridLayout")
    oreGrid.CellSize = UDim2.new(0, 80, 0, 60)
    oreGrid.CellPadding = UDim2.new(0, 5, 0, 5)
    oreGrid.SortOrder = Enum.SortOrder.LayoutOrder
    oreGrid.Parent = oreScrollFrame
    
    -- 数量选择区域
    local quantityFrame = Instance.new("Frame")
    quantityFrame.Size = UDim2.new(1, -20, 0, 80)
    quantityFrame.Position = UDim2.new(0, 10, 0, 360)
    quantityFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    quantityFrame.BorderSizePixel = 0
    quantityFrame.Parent = taskFrame
    
    local quantityCorner = Instance.new("UICorner")
    quantityCorner.CornerRadius = UDim.new(0, 8)
    quantityCorner.Parent = quantityFrame
    
    local quantityLabel = Instance.new("TextLabel")
    quantityLabel.Size = UDim2.new(0, 100, 0, 25)
    quantityLabel.Position = UDim2.new(0, 10, 0, 10)
    quantityLabel.BackgroundTransparency = 1
    quantityLabel.Text = "Quantity:"
    quantityLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    quantityLabel.TextSize = 14
    quantityLabel.Font = Enum.Font.GothamBold
    quantityLabel.TextXAlignment = Enum.TextXAlignment.Left
    quantityLabel.Parent = quantityFrame
    
    local quantityTextBox = Instance.new("TextBox")
    quantityTextBox.Name = "QuantityTextBox"
    quantityTextBox.Size = UDim2.new(0, 100, 0, 30)
    quantityTextBox.Position = UDim2.new(0, 120, 0, 8)
    quantityTextBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    quantityTextBox.Text = "10"
    quantityTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    quantityTextBox.TextSize = 14
    quantityTextBox.Font = Enum.Font.Gotham
    quantityTextBox.BorderSizePixel = 0
    quantityTextBox.Parent = quantityFrame
    
    local quantityBoxCorner = Instance.new("UICorner")
    quantityBoxCorner.CornerRadius = UDim.new(0, 4)
    quantityBoxCorner.Parent = quantityTextBox
    
    -- 预计时间显示
    local timeLabel = Instance.new("TextLabel")
    timeLabel.Name = "TimeLabel"
    timeLabel.Size = UDim2.new(1, -240, 0, 30)
    timeLabel.Position = UDim2.new(0, 230, 0, 8)
    timeLabel.BackgroundTransparency = 1
    timeLabel.Text = "Est. Time: 30s"
    timeLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    timeLabel.TextSize = 12
    timeLabel.Font = Enum.Font.GothamBold
    timeLabel.TextXAlignment = Enum.TextXAlignment.Left
    timeLabel.Parent = quantityFrame
    
    -- 优先级设置区域
    local priorityFrame = Instance.new("Frame")
    priorityFrame.Size = UDim2.new(1, -20, 0, 60)
    priorityFrame.Position = UDim2.new(0, 10, 0, 450)
    priorityFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    priorityFrame.BorderSizePixel = 0
    priorityFrame.Parent = taskFrame
    
    local priorityCorner = Instance.new("UICorner")
    priorityCorner.CornerRadius = UDim.new(0, 8)
    priorityCorner.Parent = priorityFrame
    
    local priorityLabel = Instance.new("TextLabel")
    priorityLabel.Size = UDim2.new(0, 100, 0, 25)
    priorityLabel.Position = UDim2.new(0, 10, 0, 10)
    priorityLabel.BackgroundTransparency = 1
    priorityLabel.Text = "Priority:"
    priorityLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    priorityLabel.TextSize = 14
    priorityLabel.Font = Enum.Font.GothamBold
    priorityLabel.TextXAlignment = Enum.TextXAlignment.Left
    priorityLabel.Parent = priorityFrame
    
    -- 优先级滑块
    local prioritySlider = Instance.new("Frame")
    prioritySlider.Name = "PrioritySlider"
    prioritySlider.Size = UDim2.new(0, 200, 0, 20)
    prioritySlider.Position = UDim2.new(0, 120, 0, 12)
    prioritySlider.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    prioritySlider.BorderSizePixel = 0
    prioritySlider.Parent = priorityFrame
    
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 10)
    sliderCorner.Parent = prioritySlider
    
    local sliderButton = Instance.new("TextButton")
    sliderButton.Name = "SliderButton"
    sliderButton.Size = UDim2.new(0, 20, 0, 20)
    sliderButton.Position = UDim2.new(0.6, -10, 0, 0) -- 默认60%位置 (优先级3)
    sliderButton.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
    sliderButton.Text = ""
    sliderButton.BorderSizePixel = 0
    sliderButton.Parent = prioritySlider
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 10)
    buttonCorner.Parent = sliderButton
    
    local priorityValue = Instance.new("TextLabel")
    priorityValue.Name = "PriorityValue"
    priorityValue.Size = UDim2.new(0, 30, 0, 20)
    priorityValue.Position = UDim2.new(0, 330, 0, 12)
    priorityValue.BackgroundTransparency = 1
    priorityValue.Text = "3"
    priorityValue.TextColor3 = Color3.fromRGB(100, 180, 255)
    priorityValue.TextSize = 14
    priorityValue.Font = Enum.Font.GothamBold
    priorityValue.TextXAlignment = Enum.TextXAlignment.Center
    priorityValue.Parent = priorityFrame
    
    -- 自动返回开关
    local autoReturnLabel = Instance.new("TextLabel")
    autoReturnLabel.Size = UDim2.new(0, 120, 0, 20)
    autoReturnLabel.Position = UDim2.new(0, 10, 0, 35)
    autoReturnLabel.BackgroundTransparency = 1
    autoReturnLabel.Text = "Auto Return:"
    autoReturnLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoReturnLabel.TextSize = 12
    autoReturnLabel.Font = Enum.Font.Gotham
    autoReturnLabel.TextXAlignment = Enum.TextXAlignment.Left
    autoReturnLabel.Parent = priorityFrame
    
    local autoReturnToggle = Instance.new("TextButton")
    autoReturnToggle.Name = "AutoReturnToggle"
    autoReturnToggle.Size = UDim2.new(0, 80, 0, 20)
    autoReturnToggle.Position = UDim2.new(0, 140, 0, 35)
    autoReturnToggle.BackgroundColor3 = Color3.fromRGB(100, 180, 100)
    autoReturnToggle.Text = "ON"
    autoReturnToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoReturnToggle.TextSize = 12
    autoReturnToggle.Font = Enum.Font.GothamBold
    autoReturnToggle.BorderSizePixel = 0
    autoReturnToggle.Parent = priorityFrame
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 10)
    toggleCorner.Parent = autoReturnToggle
    
    -- 确认按钮
    local confirmButton = Instance.new("TextButton")
    confirmButton.Name = "ConfirmButton"
    confirmButton.Size = UDim2.new(0, 120, 0, 35)
    confirmButton.Position = UDim2.new(0.5, -60, 1, -50)
    confirmButton.BackgroundColor3 = Color3.fromRGB(100, 180, 100)
    confirmButton.Text = "ASSIGN TASK"
    confirmButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    confirmButton.TextSize = 14
    confirmButton.Font = Enum.Font.GothamBold
    confirmButton.BorderSizePixel = 0
    confirmButton.Parent = taskFrame
    
    local confirmCorner = Instance.new("UICorner")
    confirmCorner.CornerRadius = UDim.new(0, 8)
    confirmCorner.Parent = confirmButton
    
    return taskFrame, closeButton, oreScrollFrame, quantityTextBox, timeLabel, confirmButton, robotNameLabel, robotStatsLabel, prioritySlider, sliderButton, priorityValue, autoReturnToggle
end

--------------------------------------------------------------------
-- 创建右键菜单
--------------------------------------------------------------------
local function createRightClickMenu(parent)
    print("[InventoryUI] createRightClickMenu() 被调用，parent:", parent)
    
    local menuFrame = Instance.new("Frame")
    menuFrame.Name = "RightClickMenu"
    menuFrame.Size = UDim2.new(0, 150, 0, 80)
    menuFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    menuFrame.BorderSizePixel = 0
    menuFrame.Visible = false
    menuFrame.ZIndex = 100  -- 提高ZIndex确保在最上层
    menuFrame.Parent = parent
    
    print("[InventoryUI] 菜单Frame创建完成:", menuFrame)
    
    local menuCorner = Instance.new("UICorner")
    menuCorner.CornerRadius = UDim.new(0, 8)
    menuCorner.Parent = menuFrame
    
    local menuStroke = Instance.new("UIStroke")
    menuStroke.Color = Color3.fromRGB(80, 80, 80)
    menuStroke.Thickness = 1
    menuStroke.Parent = menuFrame
    
    -- 按钮布局
    local buttonLayout = Instance.new("UIListLayout")
    buttonLayout.Padding = UDim.new(0, 2)
    buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
    buttonLayout.Parent = menuFrame
    
    -- 派发任务按钮
    local assignTaskButton = Instance.new("TextButton")
    assignTaskButton.Name = "AssignTaskButton"
    assignTaskButton.Size = UDim2.new(1, 0, 0, 38)
    assignTaskButton.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
    assignTaskButton.Text = "📋 Assign Mining Task"
    assignTaskButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    assignTaskButton.TextSize = 12
    assignTaskButton.Font = Enum.Font.Gotham
    assignTaskButton.BorderSizePixel = 0
    assignTaskButton.LayoutOrder = 1
    assignTaskButton.ZIndex = 101
    assignTaskButton.Parent = menuFrame
    
    local assignCorner = Instance.new("UICorner")
    assignCorner.CornerRadius = UDim.new(0, 6)
    assignCorner.Parent = assignTaskButton
    
    -- 取消按钮
    local cancelButton = Instance.new("TextButton")
    cancelButton.Name = "CancelButton"
    cancelButton.Size = UDim2.new(1, 0, 0, 38)
    cancelButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    cancelButton.Text = "❌ Cancel"
    cancelButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    cancelButton.TextSize = 12
    cancelButton.Font = Enum.Font.Gotham
    cancelButton.BorderSizePixel = 0
    cancelButton.LayoutOrder = 2
    cancelButton.ZIndex = 101
    cancelButton.Parent = menuFrame
    
    local cancelCorner = Instance.new("UICorner")
    cancelCorner.CornerRadius = UDim.new(0, 6)
    cancelCorner.Parent = cancelButton
    
    return menuFrame, assignTaskButton, cancelButton
end

--------------------------------------------------------------------
-- 任务系统辅助函数
--------------------------------------------------------------------

-- 获取机器人类型的基础信息（不包含前缀）
local function getRobotBaseType(robotType)
    local baseType = robotType:gsub("Dig_", ""):gsub("Build_", "")
    return baseType
end

-- 计算预计挖矿时间
local function calculateMiningTime(robotType, oreType, quantity)
    local baseType = getRobotBaseType(robotType)
    local robotStats = GameConstants.BotStats[baseType]
    local oreInfo = GameConstants.ORE_INFO[oreType]
    
    if not robotStats or not oreInfo then
        return 0
    end
    
    -- 机器人挖矿间隔 * 矿物挖掘时间 * 数量
    local totalTime = robotStats.interval * oreInfo.time * quantity
    return math.ceil(totalTime)
end

-- 格式化时间显示
local function formatTime(seconds)
    if seconds < 60 then
        return string.format("%ds", seconds)
    elseif seconds < 3600 then
        return string.format("%dm %ds", math.floor(seconds / 60), seconds % 60)
    else
        return string.format("%dh %dm", math.floor(seconds / 3600), math.floor((seconds % 3600) / 60))
    end
end

-- 创建矿物选择按钮
local function createOreButton(oreType, parent, layoutOrder)
    local oreButton = Instance.new("TextButton")
    oreButton.Name = oreType .. "Button"
    oreButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    oreButton.BorderSizePixel = 0
    oreButton.LayoutOrder = layoutOrder
    oreButton.Parent = parent
    
    local oreCorner = Instance.new("UICorner")
    oreCorner.CornerRadius = UDim.new(0, 6)
    oreCorner.Parent = oreButton
    
    -- 矿物图标（使用IconUtils）
    local oreIcon = Instance.new("ImageLabel")
    oreIcon.Size = UDim2.new(0, 40, 0, 40)
    oreIcon.Position = UDim2.new(0.5, -20, 0, 5)
    oreIcon.BackgroundTransparency = 1
    oreIcon.Image = IconUtils.getItemIcon(oreType)
    oreIcon.ScaleType = Enum.ScaleType.Fit
    oreIcon.Parent = oreButton
    
    -- 矿物名称
    local oreName = Instance.new("TextLabel")
    oreName.Size = UDim2.new(1, -4, 0, 15)
    oreName.Position = UDim2.new(0, 2, 0, 45)
    oreName.BackgroundTransparency = 1
    oreName.Text = oreType
    oreName.TextColor3 = Color3.fromRGB(255, 255, 255)
    oreName.TextSize = 8
    oreName.Font = Enum.Font.Gotham
    oreName.TextScaled = true
    oreName.Parent = oreButton
    
    -- 点击事件
    oreButton.MouseButton1Click:Connect(function()
        -- 取消之前选择的按钮
        for _, child in pairs(parent:GetChildren()) do
            if child:IsA("TextButton") and child ~= oreButton then
                child.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            end
        end
        
        -- 选择当前按钮
        oreButton.BackgroundColor3 = Color3.fromRGB(100, 150, 100)
        selectedOreType = oreType
        
        -- 更新预计时间
        updateEstimatedTime()
    end)
    
    return oreButton
end

-- 更新预计时间显示
function updateEstimatedTime()
    if not taskAssignmentUI or not selectedOreType or not currentTaskRobot then
        return
    end
    
    local quantityText = taskAssignmentUI.quantityTextBox.Text
    local quantity = tonumber(quantityText) or 0
    
    if quantity <= 0 then
        taskAssignmentUI.timeLabel.Text = "Est. Time: --"
        return
    end
    
    local estimatedTime = calculateMiningTime(currentTaskRobot, selectedOreType, quantity)
    taskAssignmentUI.timeLabel.Text = "Est. Time: " .. formatTime(estimatedTime)
end

-- 显示任务派发UI
local function showTaskAssignmentUI(robotType)
    print("[InventoryUI] showTaskAssignmentUI() 被调用，机器人:", robotType)
    
    -- 确保inventoryUI存在
    if not inventoryUI then 
        print("[InventoryUI] inventoryUI不存在，先创建库存UI")
        showInventoryUI()
        if not inventoryUI then
            print("[InventoryUI] 创建inventoryUI失败，无法显示任务界面")
            return
        else
            print("[InventoryUI] inventoryUI创建成功")
            -- 隐藏库存界面，只保留UI组件
            hideInventoryUI()
        end
    end
    
    currentTaskRobot = robotType
    selectedOreType = nil
    
    -- 创建任务UI（如果不存在）
    if not taskAssignmentUI then
        local taskFrame, closeButton, oreScrollFrame, quantityTextBox, timeLabel, confirmButton, robotNameLabel, robotStatsLabel, prioritySlider, sliderButton, priorityValue, autoReturnToggle = createTaskAssignmentUI(inventoryUI.gui)
        
        taskAssignmentUI = {
            frame = taskFrame,
            closeButton = closeButton,
            oreScrollFrame = oreScrollFrame,
            quantityTextBox = quantityTextBox,
            timeLabel = timeLabel,
            confirmButton = confirmButton,
            robotNameLabel = robotNameLabel,
            robotStatsLabel = robotStatsLabel,
            prioritySlider = prioritySlider,
            sliderButton = sliderButton, 
            priorityValue = priorityValue,
            autoReturnToggle = autoReturnToggle
        }
        
        -- 关闭按钮事件
        closeButton.MouseButton1Click:Connect(function()
            hideTaskAssignmentUI()
        end)
        
        -- 优先级滑块逻辑
        local dragging = false
        local function updatePriority(position)
            local sliderSize = prioritySlider.AbsoluteSize.X
            local relativePos = math.clamp(position / sliderSize, 0, 1)
            local priority = math.floor(relativePos * 4) + 1 -- 1-5级优先级
            
            sliderButton.Position = UDim2.new(relativePos, -10, 0, 0)
            priorityValue.Text = tostring(priority)
            
            -- 根据优先级改变颜色
            if priority <= 2 then
                priorityValue.TextColor3 = Color3.fromRGB(255, 100, 100) -- 低优先级-红色
            elseif priority == 3 then
                priorityValue.TextColor3 = Color3.fromRGB(255, 255, 100) -- 中优先级-黄色  
            else
                priorityValue.TextColor3 = Color3.fromRGB(100, 255, 100) -- 高优先级-绿色
            end
            
            return priority
        end
        
        sliderButton.MouseButton1Down:Connect(function()
            dragging = true
        end)
        
        game:GetService("UserInputService").InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        
        game:GetService("UserInputService").InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local mousePos = input.Position
                local sliderPos = prioritySlider.AbsolutePosition
                local relativePos = mousePos.X - sliderPos.X
                updatePriority(relativePos)
            end
        end)
        
        -- 自动返回开关逻辑
        local autoReturn = true
        autoReturnToggle.MouseButton1Click:Connect(function()
            autoReturn = not autoReturn
            if autoReturn then
                autoReturnToggle.Text = "ON"
                autoReturnToggle.BackgroundColor3 = Color3.fromRGB(100, 180, 100)
            else
                autoReturnToggle.Text = "OFF"
                autoReturnToggle.BackgroundColor3 = Color3.fromRGB(180, 100, 100)
            end
        end)
        
        -- 数量输入事件
        quantityTextBox.Changed:Connect(function(property)
            if property == "Text" then
                updateEstimatedTime()
            end
        end)
        
        -- 确认按钮事件
        confirmButton.MouseButton1Click:Connect(function()
            assignMiningTask()
        end)
        
        -- 创建矿物选择按钮
        for i, oreType in ipairs(MINE_ORES) do
            createOreButton(oreType, oreScrollFrame, i)
        end
        
        -- 设置矿物网格大小
        local orePerRow = 4
        local oreRows = math.ceil(#MINE_ORES / orePerRow)
        oreScrollFrame.CanvasSize = UDim2.new(0, 0, 0, oreRows * 65)
    end
    
    -- 更新机器人信息
    local baseType = getRobotBaseType(robotType)
    local robotStats = GameConstants.BotStats[baseType]
    
    taskAssignmentUI.robotNameLabel.Text = robotType:gsub("_", " ")
    taskAssignmentUI.robotStatsLabel.Text = string.format("Mining Speed: %.1fs per ore", robotStats and robotStats.interval or 3.0)
    
    -- 重置选择状态
    for _, child in pairs(taskAssignmentUI.oreScrollFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        end
    end
    
    taskAssignmentUI.quantityTextBox.Text = "10"
    taskAssignmentUI.timeLabel.Text = "Est. Time: --"
    
    -- 显示UI
    taskAssignmentUI.frame.Visible = true
end

-- 隐藏任务派发UI
local function hideTaskAssignmentUI()
    if taskAssignmentUI then
        taskAssignmentUI.frame.Visible = false
    end
    currentTaskRobot = nil
    selectedOreType = nil
end

-- 派发挖矿任务
local function assignMiningTask()
    print("[InventoryUI] assignMiningTask() 被调用")
    print("[InventoryUI] currentTaskRobot:", currentTaskRobot, "selectedOreType:", selectedOreType)
    print("[InventoryUI] miningTaskEvent:", miningTaskEvent)
    
    if not currentTaskRobot or not selectedOreType then
        print("[InventoryUI] 请选择矿物类型")
        return
    end
    
    local quantity = tonumber(taskAssignmentUI.quantityTextBox.Text) or 0
    if quantity <= 0 then
        print("[InventoryUI] 请输入有效的数量")
        return
    end
    
    -- 检查机器人是否为挖矿类型
    if not currentTaskRobot:find("Dig_") then
        print("[InventoryUI] 只有挖矿机器人可以执行挖矿任务")
        return
    end
    
    -- 获取优先级和自动返回设置
    local priority = tonumber(taskAssignmentUI.priorityValue.Text) or 3
    local autoReturn = taskAssignmentUI.autoReturnToggle.Text == "ON"
    
    print(string.format("[InventoryUI] 派发挖矿任务: %s -> %s x%d (优先级:%d, 自动返回:%s)", 
          currentTaskRobot, selectedOreType, quantity, priority, tostring(autoReturn)))
    
    -- 发送任务到服务器（包含新参数）
    if miningTaskEvent then
        print("[InventoryUI] 发送任务到服务器...")
        miningTaskEvent:FireServer("ASSIGN", currentTaskRobot, selectedOreType, quantity, priority, autoReturn)
        print("[InventoryUI] 任务已发送")
    else
        warn("[InventoryUI] 无法发送任务：MiningTaskEvent未就绪")
        return
    end
    
    -- 先保存当前机器人信息，然后再关闭界面
    local robotToRemove = currentTaskRobot
    
    -- 关闭任务界面（独立界面或普通界面）
    if taskAssignmentUI.screenGui then
        -- 独立任务界面
        print("[InventoryUI] 关闭独立任务界面")
        taskAssignmentUI.screenGui:Destroy()
        taskAssignmentUI = nil
        currentTaskRobot = nil
        selectedOreType = nil
    else
        -- 普通任务界面
        hideTaskAssignmentUI()
    end
    
    -- 机器人派发任务后保持Active状态，只是去Mine world工作
    if robotToRemove then
        print("[InventoryUI] 机器人已派发任务，前往Mine world工作:", robotToRemove)
        print("[InventoryUI] 机器人保持Active状态，但从main world消失")
        
        -- 不需要从activeRobots中移除，机器人保持Active状态
        -- 服务器端会处理机器人从main world的移除和在mine world的创建
    end
end

-- 显示右键菜单
local function showRightClickMenu(position, robotType)
    print("[InventoryUI] showRightClickMenu() 被调用，位置:", position, "机器人:", robotType)
    
    -- 确保inventoryUI存在，如果不存在就创建
    if not inventoryUI then 
        print("[InventoryUI] inventoryUI不存在，先创建库存UI")
        showInventoryUI()  -- 这会创建inventoryUI
        print("[InventoryUI] showInventoryUI调用完成，inventoryUI:", inventoryUI)
        if not inventoryUI then
            print("[InventoryUI] 创建inventoryUI失败")
            return
        else
            print("[InventoryUI] inventoryUI创建成功")
            -- 先隐藏刚打开的库存界面，因为我们只是为了创建UI组件
            hideInventoryUI()
        end
    end
    
    -- 创建右键菜单（如果不存在）
    if not rightClickMenu then
        print("[InventoryUI] 创建右键菜单")
        local menuFrame, assignTaskButton, cancelButton = createRightClickMenu(inventoryUI.gui)
        
        rightClickMenu = {
            frame = menuFrame,
            assignTaskButton = assignTaskButton,
            cancelButton = cancelButton
        }
        
        print("[InventoryUI] 右键菜单创建完成，frame:", rightClickMenu.frame)
        
        -- 派发任务按钮事件
        assignTaskButton.MouseButton1Click:Connect(function()
            print("[InventoryUI] 派发任务按钮被点击")
            hideRightClickMenu()
            if currentTaskRobot and currentTaskRobot:find("Dig_") then
                showTaskAssignmentUI(currentTaskRobot)
            else
                print("[InventoryUI] 只有挖矿机器人可以派发挖矿任务")
            end
        end)
        
        -- 取消按钮事件
        cancelButton.MouseButton1Click:Connect(function()
            print("[InventoryUI] 取消按钮被点击")
            hideRightClickMenu()
        end)
    else
        print("[InventoryUI] 右键菜单已存在")
    end
    
    -- 设置当前选择的机器人
    currentTaskRobot = robotType
    print("[InventoryUI] 设置当前任务机器人:", currentTaskRobot)
    
    -- 根据机器人类型调整菜单
    if robotType:find("Dig_") then
        rightClickMenu.assignTaskButton.Text = "📋 Assign Mining Task"
        rightClickMenu.assignTaskButton.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
    else
        rightClickMenu.assignTaskButton.Text = "🔨 Assign Building Task"
        rightClickMenu.assignTaskButton.BackgroundColor3 = Color3.fromRGB(120, 60, 200)
    end
    
    -- 设置菜单位置并显示（使用固定位置测试）
    print("[InventoryUI] 设置菜单位置:", position)
    -- 临时使用屏幕中央位置测试
    rightClickMenu.frame.Position = UDim2.new(0.5, -75, 0.5, -40)  -- 屏幕中央
    rightClickMenu.frame.Visible = true
    print("[InventoryUI] 菜单应该显示了，Visible:", rightClickMenu.frame.Visible)
    print("[InventoryUI] 菜单实际位置:", rightClickMenu.frame.Position)
    print("[InventoryUI] 菜单大小:", rightClickMenu.frame.Size)
    print("[InventoryUI] 菜单ZIndex:", rightClickMenu.frame.ZIndex)
    print("[InventoryUI] 菜单父级:", rightClickMenu.frame.Parent)
    
    -- 等待一帧确保UI更新
    task.wait()
    print("[InventoryUI] 等待一帧后，菜单Visible:", rightClickMenu.frame.Visible)
end

-- 隐藏右键菜单
local function hideRightClickMenu()
    if rightClickMenu then
        rightClickMenu.frame.Visible = false
    end
    currentTaskRobot = nil
end

--------------------------------------------------------------------
-- 创建独立的任务派发界面（不依赖inventoryUI）
--------------------------------------------------------------------
local function createStandaloneTaskUI(robotType)
    print("[InventoryUI] 创建独立任务派发界面，机器人:", robotType)
    
    -- 创建独立的ScreenGui
    local taskScreenGui = Instance.new("ScreenGui")
    taskScreenGui.Name = "StandaloneTaskUI"
    taskScreenGui.ResetOnSpawn = false
    taskScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    taskScreenGui.Parent = playerGui
    
    -- 创建任务派发窗口
    local taskFrame, closeButton, oreScrollFrame, quantityTextBox, timeLabel, confirmButton, robotNameLabel, robotStatsLabel, prioritySlider, sliderButton, priorityValue, autoReturnToggle = createTaskAssignmentUI(taskScreenGui)
    
    -- 设置全局任务UI引用
    taskAssignmentUI = {
        frame = taskFrame,
        closeButton = closeButton,
        oreScrollFrame = oreScrollFrame,
        quantityTextBox = quantityTextBox,
        timeLabel = timeLabel,
        confirmButton = confirmButton,
        robotNameLabel = robotNameLabel,
        robotStatsLabel = robotStatsLabel,
        prioritySlider = prioritySlider,
        sliderButton = sliderButton,
        priorityValue = priorityValue,
        autoReturnToggle = autoReturnToggle,
        screenGui = taskScreenGui  -- 保存ScreenGui引用
    }
    
    -- 设置机器人信息
    currentTaskRobot = robotType
    selectedOreType = nil
    
    local baseType = getRobotBaseType(robotType)
    local robotStats = GameConstants.BotStats[baseType]
    
    robotNameLabel.Text = robotType:gsub("_", " ")
    robotStatsLabel.Text = string.format("Mining Speed: %.1fs per ore", robotStats and robotStats.interval or 3.0)
    
    -- 关闭按钮事件
    closeButton.MouseButton1Click:Connect(function()
        print("[InventoryUI] 关闭独立任务界面")
        if taskAssignmentUI.screenGui then
            taskAssignmentUI.screenGui:Destroy()
        end
        taskAssignmentUI = nil
        currentTaskRobot = nil
        selectedOreType = nil
    end)
    
    -- 数量输入事件
    quantityTextBox.Changed:Connect(function(property)
        if property == "Text" then
            updateEstimatedTime()
        end
    end)
    
    -- 确认按钮事件
    confirmButton.MouseButton1Click:Connect(function()
        assignMiningTask()
    end)
    
    -- 创建矿物选择按钮
    for i, oreType in ipairs(MINE_ORES) do
        createOreButton(oreType, oreScrollFrame, i)
    end
    
    -- 设置矿物网格大小
    local orePerRow = 4
    local oreRows = math.ceil(#MINE_ORES / orePerRow)
    oreScrollFrame.CanvasSize = UDim2.new(0, 0, 0, oreRows * 65)
    
    -- 重置UI状态
    quantityTextBox.Text = "10"
    timeLabel.Text = "Est. Time: --"
    
    -- 显示界面
    taskFrame.Visible = true
    
    print("[InventoryUI] 独立任务界面创建完成并显示")
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

-- 设置机器人为Active
local function setRobotActive(robotType, slotIndex)
    print("[InventoryUI] 设置机器人为Active:", robotType, "槽位:", slotIndex)
    activeRobots[slotIndex] = robotType
    setActiveRobotEvent:FireServer("ACTIVATE", robotType, slotIndex)
    updateInventoryUI() -- 刷新UI
end

-- 设置机器人为Inactive
local function setRobotInactive(slotIndex)
    print("[InventoryUI] 设置机器人为Inactive, 槽位:", slotIndex)
    local robotType = activeRobots[slotIndex]
    if robotType then
        activeRobots[slotIndex] = nil
        setActiveRobotEvent:FireServer("DEACTIVATE", robotType, slotIndex)
        updateInventoryUI() -- 刷新UI
    end
end

-- 获取下一个可用的Active槽位
local function getNextAvailableSlot()
    for i = 1, 5 do
        if not activeRobots[i] then
            return i
        end
    end
    return nil
end

-- 检查机器人是否已经Active
local function isRobotActive(robotType)
    for slotIndex, activeType in pairs(activeRobots) do
        if activeType == robotType then
            return slotIndex
        end
    end
    return nil
end

--------------------------------------------------------------------
-- 创建机器人卡片
--------------------------------------------------------------------
local function createRobotCard(robotId, quantity, isActive, parent, layoutOrder, slotIndex)
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
    
    -- 机器人图标（使用IconUtils）
    local iconLabel = Instance.new("ImageLabel")
    iconLabel.Size = UDim2.new(0, 60, 0, 60)
    iconLabel.Position = UDim2.new(0.5, -30, 0, 15)
    iconLabel.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
    iconLabel.Image = IconUtils.getItemIcon(robotId)
    iconLabel.ScaleType = Enum.ScaleType.Fit
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
    statusLabel.Text = isActive and ("ACTIVE " .. (slotIndex or "")) or ("×" .. quantity)
    statusLabel.TextColor3 = isActive and Color3.fromRGB(150, 255, 150) or Color3.fromRGB(200, 200, 200)
    statusLabel.TextSize = 12
    statusLabel.Font = isActive and Enum.Font.GothamBold or Enum.Font.Gotham
    statusLabel.TextScaled = true
    statusLabel.Parent = cardFrame
    
    -- 左键点击事件
    cardFrame.MouseButton1Click:Connect(function()
        if isActive then
            -- 如果是Active，点击变为Inactive
            setRobotInactive(slotIndex)
        else
            -- 如果是Inactive，点击变为Active
            local availableSlot = getNextAvailableSlot()
            if availableSlot then
                setRobotActive(robotId, availableSlot)
            else
                print("[InventoryUI] 没有可用的Active槽位")
            end
        end
    end)
    
    -- 右键点击事件
    cardFrame.MouseButton2Click:Connect(function()
        print("[InventoryUI] 右键点击机器人:", robotId, "isActive:", isActive, "isDig:", robotId:find("Dig_"))
        -- 只有Active的挖矿机器人可以派发任务
        if isActive and robotId:find("Dig_") then
            print("[InventoryUI] 直接打开任务派发界面")
            -- 直接创建独立任务界面，不用右键菜单
            createStandaloneTaskUI(robotId)
        else
            print("[InventoryUI] 只有Active的挖矿机器人可以派发任务 - isActive:", isActive, "isDig:", robotId:find("Dig_"))
        end
    end)
    
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
    
    -- 创建机器人卡片 (基于Active状态管理)
    local activeCount = 0
    local robotInventory = {} -- [robotType] = totalQuantity
    
    -- 统计每种机器人的总数量
    for _, robot in ipairs(robots) do
        robotInventory[robot.itemId] = robot.quantity
    end
    
    -- 创建Active机器人卡片
    for slotIndex = 1, 5 do
        if activeRobots[slotIndex] then
            activeCount = activeCount + 1
            createRobotCard(activeRobots[slotIndex], 1, true, inventoryUI.activeRobotsFrame, slotIndex, slotIndex)
        end
    end
    
    -- 创建Inactive机器人卡片 (堆叠显示)
    local inactiveCardCount = 0
    local totalInactiveCount = 0
    
    for robotType, totalQuantity in pairs(robotInventory) do
        -- 计算这种机器人有多少是inactive的
        local inactiveQuantity = totalQuantity
        
        -- 减去已经active的数量
        for slotIndex, activeType in pairs(activeRobots) do
            if activeType == robotType then
                inactiveQuantity = inactiveQuantity - 1
            end
        end
        
        -- 如果还有inactive的，创建卡片
        if inactiveQuantity > 0 then
            inactiveCardCount = inactiveCardCount + 1
            totalInactiveCount = totalInactiveCount + inactiveQuantity
            createRobotCard(robotType, inactiveQuantity, false, inventoryUI.inactiveRobotsFrame, inactiveCardCount)
        end
    end
    
    -- 更新标签
    inventoryUI.activeLabel.Text = string.format("ACTIVE ROBOTS (%d/5)", activeCount)
    inventoryUI.inactiveLabel.Text = string.format("INACTIVE ROBOTS (%d)", totalInactiveCount)
    
    -- 设置Inactive机器人区域大小 (基于卡片数量，不是机器人总数)
    local inactivePerRow = 6
    local inactiveRows = math.ceil(inactiveCardCount / inactivePerRow)
    inventoryUI.inactiveRobotsFrame.Size = UDim2.new(1, 0, 0, math.max(140, inactiveRows * 150))
    
    -- 设置Robots滚动框大小
    inventoryUI.robotsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 30 + 160 + 15 + 30 + math.max(140, inactiveRows * 150) + 20)
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
    
    -- I键打开/关闭库存
    if input.KeyCode == Enum.KeyCode.I then
        print("[InventoryUI] I键被按下!")  -- 调试信息
        if inventoryUI and inventoryUI.mainFrame.Visible then
            print("[InventoryUI] 关闭库存")
            hideInventoryUI()
        else
            print("[InventoryUI] 打开库存")
            showInventoryUI()
        end
    -- T键测试任务派发（临时快捷键）
    elseif input.KeyCode == Enum.KeyCode.T then
        print("[InventoryUI] T键被按下，测试任务派发")
        -- 找到第一个Active的挖矿机器人
        for slotIndex, robotType in pairs(activeRobots) do
            if robotType and robotType:find("Dig_") then
                print("[InventoryUI] 找到Active挖矿机器人:", robotType)
                -- 直接创建独立的任务派发界面
                createStandaloneTaskUI(robotType)
                return
            end
        end
        print("[InventoryUI] 没有找到Active的挖矿机器人")
    -- ESC关闭所有UI
    elseif input.KeyCode == Enum.KeyCode.Escape then
        if taskAssignmentUI and taskAssignmentUI.frame and taskAssignmentUI.frame.Visible then
            -- 如果是独立任务界面，直接销毁
            if taskAssignmentUI.screenGui then
                print("[InventoryUI] ESC关闭独立任务界面")
                taskAssignmentUI.screenGui:Destroy()
                taskAssignmentUI = nil
                currentTaskRobot = nil
                selectedOreType = nil
            else
                hideTaskAssignmentUI()
            end
        elseif rightClickMenu and rightClickMenu.frame.Visible then
            hideRightClickMenu()
        elseif inventoryUI and inventoryUI.mainFrame.Visible then
            hideInventoryUI()
        end
    end
end)

-- 全局点击处理（隐藏右键菜单）
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and not gameProcessedEvent then
        -- 左键点击时隐藏右键菜单
        if rightClickMenu and rightClickMenu.frame.Visible then
            hideRightClickMenu()
        end
    end
end)

-- 初始化系统
task.spawn(function()
    task.wait(1)  -- 等待1秒确保系统启动
    setupOpenButton()  -- 设置StarterGui按钮
    print("[InventoryUI] 系统准备就绪 - 按I键或点击按钮打开库存")
end)

print("[InventoryUI] Pet Simulator 99风格库存UI系统已加载 - 按I键或点击按钮打开")