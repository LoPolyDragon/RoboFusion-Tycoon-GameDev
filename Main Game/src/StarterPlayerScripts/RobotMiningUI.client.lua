--------------------------------------------------------------------
-- RobotMiningUI.client.lua · 机器人挖矿管理界面
-- 功能：
--   1) 显示可用的挖矿机器人
--   2) 选择矿石类型和数量
--   3) 派遣机器人到矿区
--   4) 显示挖矿任务进度
--   5) 管理活跃的挖矿任务
--------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- RemoteEvents
local mineTaskEvent = ReplicatedStorage.RemoteEvents:WaitForChild("MineTaskEvent")
local botReturnEvent = ReplicatedStorage.RemoteEvents:WaitForChild("BotReturnEvent")

-- GameConstants
local GameConstants = require(ReplicatedStorage.SharedModules.GameConstants)

-- UI Variables
local screenGui = nil
local mainFrame = nil
local botListFrame = nil
local taskListFrame = nil
local isUIVisible = false

-- Data
local availableBots = {}
local activeTasks = {}
local selectedBot = nil

--------------------------------------------------------------------
-- 创建主UI
--------------------------------------------------------------------
local function createMainUI()
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "RobotMiningUI"
    screenGui.Parent = playerGui
    
    -- 主框架
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 800, 0, 600)
    mainFrame.Position = UDim2.new(0.5, -400, 0.5, -300)
    mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Parent = screenGui
    
    -- 圆角
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = mainFrame
    
    -- 标题
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, 0, 0, 50)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🤖 机器人挖矿管理"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.Parent = mainFrame
    
    -- 关闭按钮
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -50, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.Parent = mainFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton
    
    closeButton.Activated:Connect(function()
        toggleUI()
    end)
    
    -- 机器人列表区域
    createBotListSection()
    
    -- 任务列表区域  
    createTaskListSection()
    
    -- 控制按钮区域
    createControlSection()
end

--------------------------------------------------------------------
-- 创建机器人列表区域
--------------------------------------------------------------------
local function createBotListSection()
    local botSection = Instance.new("Frame")
    botSection.Name = "BotSection"
    botSection.Size = UDim2.new(0.45, 0, 0.7, 0)
    botSection.Position = UDim2.new(0.025, 0, 0.15, 0)
    botSection.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    botSection.BorderSizePixel = 0
    botSection.Parent = mainFrame
    
    local botCorner = Instance.new("UICorner")
    botCorner.CornerRadius = UDim.new(0, 10)
    botCorner.Parent = botSection
    
    -- 标题
    local botTitle = Instance.new("TextLabel")
    botTitle.Size = UDim2.new(1, 0, 0, 30)
    botTitle.Position = UDim2.new(0, 0, 0, 0)
    botTitle.BackgroundTransparency = 1
    botTitle.Text = "可用机器人"
    botTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    botTitle.TextScaled = true
    botTitle.Font = Enum.Font.SourceSansBold
    botTitle.Parent = botSection
    
    -- 机器人列表滚动框
    local botScrollFrame = Instance.new("ScrollingFrame")
    botScrollFrame.Name = "BotScrollFrame"
    botScrollFrame.Size = UDim2.new(1, -10, 1, -40)
    botScrollFrame.Position = UDim2.new(0, 5, 0, 35)
    botScrollFrame.BackgroundTransparency = 1
    botScrollFrame.BorderSizePixel = 0
    botScrollFrame.ScrollBarThickness = 8
    botScrollFrame.Parent = botSection
    
    local botListLayout = Instance.new("UIListLayout")
    botListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    botListLayout.Padding = UDim.new(0, 5)
    botListLayout.Parent = botScrollFrame
    
    botListFrame = botScrollFrame
end

--------------------------------------------------------------------
-- 创建任务列表区域
--------------------------------------------------------------------
local function createTaskListSection()
    local taskSection = Instance.new("Frame")
    taskSection.Name = "TaskSection"
    taskSection.Size = UDim2.new(0.45, 0, 0.7, 0)
    taskSection.Position = UDim2.new(0.525, 0, 0.15, 0)
    taskSection.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    taskSection.BorderSizePixel = 0
    taskSection.Parent = mainFrame
    
    local taskCorner = Instance.new("UICorner")
    taskCorner.CornerRadius = UDim.new(0, 10)
    taskCorner.Parent = taskSection
    
    -- 标题
    local taskTitle = Instance.new("TextLabel")
    taskTitle.Size = UDim2.new(1, 0, 0, 30)
    taskTitle.Position = UDim2.new(0, 0, 0, 0)
    taskTitle.BackgroundTransparency = 1
    taskTitle.Text = "活跃任务"
    taskTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    taskTitle.TextScaled = true
    taskTitle.Font = Enum.Font.SourceSansBold
    taskTitle.Parent = taskSection
    
    -- 任务列表滚动框
    local taskScrollFrame = Instance.new("ScrollingFrame")
    taskScrollFrame.Name = "TaskScrollFrame"
    taskScrollFrame.Size = UDim2.new(1, -10, 1, -40)
    taskScrollFrame.Position = UDim2.new(0, 5, 0, 35)
    taskScrollFrame.BackgroundTransparency = 1
    taskScrollFrame.BorderSizePixel = 0
    taskScrollFrame.ScrollBarThickness = 8
    taskScrollFrame.Parent = taskSection
    
    local taskListLayout = Instance.new("UIListLayout")
    taskListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    taskListLayout.Padding = UDim.new(0, 5)
    taskListLayout.Parent = taskScrollFrame
    
    taskListFrame = taskScrollFrame
end

--------------------------------------------------------------------
-- 创建控制区域
--------------------------------------------------------------------
local function createControlSection()
    local controlSection = Instance.new("Frame")
    controlSection.Name = "ControlSection"
    controlSection.Size = UDim2.new(1, -20, 0, 100)
    controlSection.Position = UDim2.new(0, 10, 0.88, 0)
    controlSection.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    controlSection.BorderSizePixel = 0
    controlSection.Parent = mainFrame
    
    local controlCorner = Instance.new("UICorner")
    controlCorner.CornerRadius = UDim.new(0, 10)
    controlCorner.Parent = controlSection
    
    -- 矿石选择
    local oreLabel = Instance.new("TextLabel")
    oreLabel.Size = UDim2.new(0, 100, 0, 30)
    oreLabel.Position = UDim2.new(0, 10, 0, 10)
    oreLabel.BackgroundTransparency = 1
    oreLabel.Text = "矿石类型:"
    oreLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    oreLabel.TextScaled = true
    oreLabel.Font = Enum.Font.SourceSans
    oreLabel.Parent = controlSection
    
    local oreDropdown = Instance.new("TextButton")
    oreDropdown.Name = "OreDropdown"
    oreDropdown.Size = UDim2.new(0, 120, 0, 30)
    oreDropdown.Position = UDim2.new(0, 120, 0, 10)
    oreDropdown.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
    oreDropdown.Text = "Scrap ▼"
    oreDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
    oreDropdown.TextScaled = true
    oreDropdown.Font = Enum.Font.SourceSans
    oreDropdown.Parent = controlSection
    
    local oreCorner = Instance.new("UICorner")
    oreCorner.CornerRadius = UDim.new(0, 5)
    oreCorner.Parent = oreDropdown
    
    -- 数量输入
    local quantityLabel = Instance.new("TextLabel")
    quantityLabel.Size = UDim2.new(0, 80, 0, 30)
    quantityLabel.Position = UDim2.new(0, 250, 0, 10)
    quantityLabel.BackgroundTransparency = 1
    quantityLabel.Text = "数量:"
    quantityLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    quantityLabel.TextScaled = true
    quantityLabel.Font = Enum.Font.SourceSans
    quantityLabel.Parent = controlSection
    
    local quantityInput = Instance.new("TextBox")
    quantityInput.Name = "QuantityInput"
    quantityInput.Size = UDim2.new(0, 80, 0, 30)
    quantityInput.Position = UDim2.new(0, 330, 0, 10)
    quantityInput.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
    quantityInput.Text = "10"
    quantityInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    quantityInput.TextScaled = true
    quantityInput.Font = Enum.Font.SourceSans
    quantityInput.Parent = controlSection
    
    local quantityCorner = Instance.new("UICorner")
    quantityCorner.CornerRadius = UDim.new(0, 5)
    quantityCorner.Parent = quantityInput
    
    -- 派遣按钮
    local dispatchButton = Instance.new("TextButton")
    dispatchButton.Name = "DispatchButton"
    dispatchButton.Size = UDim2.new(0, 120, 0, 40)
    dispatchButton.Position = UDim2.new(0, 430, 0, 5)
    dispatchButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
    dispatchButton.Text = "派遣挖矿"
    dispatchButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    dispatchButton.TextScaled = true
    dispatchButton.Font = Enum.Font.SourceSansBold
    dispatchButton.Parent = controlSection
    
    local dispatchCorner = Instance.new("UICorner")
    dispatchCorner.CornerRadius = UDim.new(0, 8)
    dispatchCorner.Parent = dispatchButton
    
    -- 刷新按钮
    local refreshButton = Instance.new("TextButton")
    refreshButton.Name = "RefreshButton"
    refreshButton.Size = UDim2.new(0, 80, 0, 40)
    refreshButton.Position = UDim2.new(0, 560, 0, 5)
    refreshButton.BackgroundColor3 = Color3.fromRGB(100, 150, 200)
    refreshButton.Text = "刷新"
    refreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    refreshButton.TextScaled = true
    refreshButton.Font = Enum.Font.SourceSansBold
    refreshButton.Parent = controlSection
    
    local refreshCorner = Instance.new("UICorner")
    refreshCorner.CornerRadius = UDim.new(0, 8)
    refreshCorner.Parent = refreshButton
    
    -- 事件连接
    dispatchButton.Activated:Connect(function()
        dispatchBot()
    end)
    
    refreshButton.Activated:Connect(function()
        refreshData()
    end)
end

--------------------------------------------------------------------
-- 创建机器人项目
--------------------------------------------------------------------
local function createBotItem(botData, index)
    local botItem = Instance.new("Frame")
    botItem.Name = "BotItem_" .. index
    botItem.Size = UDim2.new(1, -5, 0, 60)
    botItem.BackgroundColor3 = selectedBot == botData.id and Color3.fromRGB(100, 100, 120) or Color3.fromRGB(60, 60, 70)
    botItem.BorderSizePixel = 0
    botItem.Parent = botListFrame
    
    local itemCorner = Instance.new("UICorner")
    itemCorner.CornerRadius = UDim.new(0, 8)
    itemCorner.Parent = botItem
    
    -- 机器人图标
    local botIcon = Instance.new("TextLabel")
    botIcon.Size = UDim2.new(0, 40, 0, 40)
    botIcon.Position = UDim2.new(0, 10, 0.5, -20)
    botIcon.BackgroundTransparency = 1
    botIcon.Text = "🤖"
    botIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
    botIcon.TextScaled = true
    botIcon.Font = Enum.Font.SourceSans
    botIcon.Parent = botItem
    
    -- 机器人信息
    local botInfo = Instance.new("TextLabel")
    botInfo.Size = UDim2.new(1, -60, 1, 0)
    botInfo.Position = UDim2.new(0, 55, 0, 0)
    botInfo.BackgroundTransparency = 1
    botInfo.Text = string.format("%s\n等级: %d | 类型: %s", botData.type, botData.level or 1, botData.category or "MN")
    botInfo.TextColor3 = Color3.fromRGB(255, 255, 255)
    botInfo.TextScaled = true
    botInfo.Font = Enum.Font.SourceSans
    botInfo.TextXAlignment = Enum.TextXAlignment.Left
    botInfo.Parent = botItem
    
    -- 点击选择
    local selectButton = Instance.new("TextButton")
    selectButton.Size = UDim2.new(1, 0, 1, 0)
    selectButton.Position = UDim2.new(0, 0, 0, 0)
    selectButton.BackgroundTransparency = 1
    selectButton.Text = ""
    selectButton.Parent = botItem
    
    selectButton.Activated:Connect(function()
        selectBot(botData)
    end)
    
    return botItem
end

--------------------------------------------------------------------
-- 创建任务项目
--------------------------------------------------------------------
local function createTaskItem(taskData, index)
    local taskItem = Instance.new("Frame")
    taskItem.Name = "TaskItem_" .. index
    taskItem.Size = UDim2.new(1, -5, 0, 80)
    taskItem.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    taskItem.BorderSizePixel = 0
    taskItem.Parent = taskListFrame
    
    local taskCorner = Instance.new("UICorner")
    taskCorner.CornerRadius = UDim.new(0, 8)
    taskCorner.Parent = taskItem
    
    -- 任务信息
    local taskInfo = Instance.new("TextLabel")
    taskInfo.Size = UDim2.new(1, -10, 0, 40)
    taskInfo.Position = UDim2.new(0, 5, 0, 5)
    taskInfo.BackgroundTransparency = 1
    taskInfo.Text = string.format("机器人: %s\n矿石: %s | 数量: %d", taskData.botId, taskData.oreName, taskData.quantity)
    taskInfo.TextColor3 = Color3.fromRGB(255, 255, 255)
    taskInfo.TextScaled = true
    taskInfo.Font = Enum.Font.SourceSans
    taskInfo.TextXAlignment = Enum.TextXAlignment.Left
    taskInfo.Parent = taskItem
    
    -- 进度条
    local progressBg = Instance.new("Frame")
    progressBg.Size = UDim2.new(1, -10, 0, 20)
    progressBg.Position = UDim2.new(0, 5, 0, 50)
    progressBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    progressBg.BorderSizePixel = 0
    progressBg.Parent = taskItem
    
    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(taskData.progress / taskData.quantity, 0, 1, 0)
    progressBar.Position = UDim2.new(0, 0, 0, 0)
    progressBar.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
    progressBar.BorderSizePixel = 0
    progressBar.Parent = progressBg
    
    local progressCorner1 = Instance.new("UICorner")
    progressCorner1.CornerRadius = UDim.new(0, 5)
    progressCorner1.Parent = progressBg
    
    local progressCorner2 = Instance.new("UICorner")
    progressCorner2.CornerRadius = UDim.new(0, 5)
    progressCorner2.Parent = progressBar
    
    return taskItem
end

--------------------------------------------------------------------
-- 核心功能
--------------------------------------------------------------------

-- 切换UI显示
function toggleUI()
    isUIVisible = not isUIVisible
    mainFrame.Visible = isUIVisible
    
    if isUIVisible then
        refreshData()
        -- 显示动画
        mainFrame.Size = UDim2.new(0, 0, 0, 0)
        local showTween = TweenService:Create(mainFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 800, 0, 600)}
        )
        showTween:Play()
    end
end

-- 选择机器人
function selectBot(botData)
    selectedBot = botData.id
    updateBotList()
end

-- 派遣机器人
function dispatchBot()
    if not selectedBot then
        -- 显示错误提示
        print("请先选择一个机器人")
        return
    end
    
    local oreDropdown = mainFrame.ControlSection.OreDropdown
    local quantityInput = mainFrame.ControlSection.QuantityInput
    
    local oreName = string.split(oreDropdown.Text, " ")[1] -- 提取矿石名称
    local quantity = tonumber(quantityInput.Text) or 10
    
    -- 发送派遣请求
    mineTaskEvent:FireServer("START_MINING", {
        botId = selectedBot,
        oreName = oreName,
        quantity = quantity
    })
end

-- 刷新数据
function refreshData()
    mineTaskEvent:FireServer("GET_BOTS")
    mineTaskEvent:FireServer("GET_TASKS")
end

-- 更新机器人列表
function updateBotList()
    -- 清除现有项目
    for _, child in ipairs(botListFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- 创建新项目
    for i, botData in ipairs(availableBots) do
        createBotItem(botData, i)
    end
    
    -- 更新滚动框大小
    botListFrame.CanvasSize = UDim2.new(0, 0, 0, #availableBots * 65)
end

-- 更新任务列表
function updateTaskList()
    -- 清除现有项目
    for _, child in ipairs(taskListFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- 创建新项目
    for i, taskData in ipairs(activeTasks) do
        createTaskItem(taskData, i)
    end
    
    -- 更新滚动框大小
    taskListFrame.CanvasSize = UDim2.new(0, 0, 0, #activeTasks * 85)
end

--------------------------------------------------------------------
-- RemoteEvent 处理
--------------------------------------------------------------------
mineTaskEvent.OnClientEvent:Connect(function(action, data)
    if action == "BOTS_LIST" then
        availableBots = data or {}
        updateBotList()
    elseif action == "TASKS_LIST" then
        activeTasks = data or {}
        updateTaskList()
    elseif action == "TASK_STARTED" then
        print("任务开始:", data.oreName, data.quantity)
        refreshData()
    elseif action == "TASK_COMPLETED" then
        print("任务完成:", data.oreName, data.quantity)
        refreshData()
    elseif action == "ERROR" then
        print("错误:", data)
        -- 可以在这里显示错误提示UI
    end
end)

botReturnEvent.OnClientEvent:Connect(function(botId, results)
    print("机器人返回:", botId, "挖掘结果:", results)
    refreshData()
end)

--------------------------------------------------------------------
-- 输入处理
--------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.B then -- B键打开/关闭UI
        toggleUI()
    end
end)

--------------------------------------------------------------------
-- 初始化
--------------------------------------------------------------------
createMainUI()
print("[RobotMiningUI] 机器人挖矿管理界面已加载")
print("按 B 键打开/关闭机器人挖矿界面")