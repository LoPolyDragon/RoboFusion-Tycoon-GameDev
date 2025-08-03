--------------------------------------------------------------------
-- RobotStatusUI.client.lua · 机器人状态显示UI
-- 功能：显示机器人任务状态，标记在任务中的机器人
--------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 等待RemoteEvents
local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local miningTaskEvent = remoteFolder:WaitForChild("MiningTaskEvent")

-- Robot状态UI
local RobotStatusUI = {
    gui = nil,
    isVisible = false,
    robotCards = {},
    robotTasks = {}
}

--------------------------------------------------------------------
-- UI创建函数
--------------------------------------------------------------------

-- 创建机器人状态卡片
local function createRobotCard(robotType, parent)
    local cardFrame = Instance.new("Frame")
    cardFrame.Name = robotType .. "Card"
    cardFrame.Size = UDim2.new(0, 200, 0, 120)
    cardFrame.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
    cardFrame.BorderSizePixel = 0
    cardFrame.Parent = parent
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 10)
    cardCorner.Parent = cardFrame
    
    -- 机器人图标
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Name = "IconLabel"
    iconLabel.Size = UDim2.new(0, 60, 0, 60)
    iconLabel.Position = UDim2.new(0, 10, 0, 10)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = "🤖"
    iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    iconLabel.TextScaled = true
    iconLabel.Font = Enum.Font.SourceSansBold
    iconLabel.Parent = cardFrame
    
    -- 机器人名称
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(0, 120, 0, 25)
    nameLabel.Position = UDim2.new(0, 75, 0, 10)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = robotType
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = cardFrame
    
    -- 状态标签
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(0, 120, 0, 20)
    statusLabel.Position = UDim2.new(0, 75, 0, 35)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "空闲中"
    statusLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
    statusLabel.TextScaled = true
    statusLabel.Font = Enum.Font.SourceSans
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = cardFrame
    
    -- 任务进度条背景
    local progressBg = Instance.new("Frame")
    progressBg.Name = "ProgressBg"
    progressBg.Size = UDim2.new(1, -20, 0, 20)
    progressBg.Position = UDim2.new(0, 10, 0, 80)
    progressBg.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    progressBg.BorderSizePixel = 0
    progressBg.Visible = false
    progressBg.Parent = cardFrame
    
    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(0, 5)
    progressCorner.Parent = progressBg
    
    -- 任务进度条
    local progressBar = Instance.new("Frame")
    progressBar.Name = "ProgressBar"
    progressBar.Size = UDim2.new(0, 0, 1, 0)
    progressBar.Position = UDim2.new(0, 0, 0, 0)
    progressBar.BackgroundColor3 = Color3.fromRGB(50, 150, 200)
    progressBar.BorderSizePixel = 0
    progressBar.Parent = progressBg
    
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 5)
    barCorner.Parent = progressBar
    
    -- 进度文本
    local progressText = Instance.new("TextLabel")
    progressText.Name = "ProgressText"
    progressText.Size = UDim2.new(1, 0, 1, 0)
    progressText.Position = UDim2.new(0, 0, 0, 0)
    progressText.BackgroundTransparency = 1
    progressText.Text = ""
    progressText.TextColor3 = Color3.fromRGB(255, 255, 255)
    progressText.TextScaled = true
    progressText.Font = Enum.Font.SourceSansBold
    progressText.Parent = progressBg
    
    -- 在任务状态框
    local taskIndicator = Instance.new("Frame")
    taskIndicator.Name = "TaskIndicator"
    taskIndicator.Size = UDim2.new(0, 15, 0, 15)
    taskIndicator.Position = UDim2.new(1, -20, 0, 5)
    taskIndicator.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
    taskIndicator.BorderSizePixel = 0
    taskIndicator.Visible = false
    taskIndicator.Parent = cardFrame
    
    local indicatorCorner = Instance.new("UICorner")
    indicatorCorner.CornerRadius = UDim.new(0.5, 0)
    indicatorCorner.Parent = taskIndicator
    
    return cardFrame
end

-- 创建主UI
local function createMainUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "RobotStatusUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    -- 主容器（默认隐藏）
    local mainContainer = Instance.new("Frame")
    mainContainer.Name = "MainContainer"
    mainContainer.Size = UDim2.new(0, 250, 0, 400)
    mainContainer.Position = UDim2.new(0, 20, 0.5, -200)
    mainContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    mainContainer.BorderSizePixel = 0
    mainContainer.Visible = false
    mainContainer.Parent = screenGui
    
    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 15)
    containerCorner.Parent = mainContainer
    
    -- 标题栏
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 50)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainContainer
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 15)
    titleCorner.Parent = titleBar
    
    -- 修复标题栏底部
    local titleFix = Instance.new("Frame")
    titleFix.Size = UDim2.new(1, 0, 0, 15)
    titleFix.Position = UDim2.new(0, 0, 1, -15)
    titleFix.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    titleFix.BorderSizePixel = 0
    titleFix.Parent = titleBar
    
    -- 标题文字
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -60, 1, 0)
    titleLabel.Position = UDim2.new(0, 15, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🤖 机器人状态"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar
    
    -- 关闭按钮
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 35, 0, 35)
    closeButton.Position = UDim2.new(1, -42, 0, 7)
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
    
    -- 机器人列表滚动框
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "RobotScrollFrame"
    scrollFrame.Size = UDim2.new(1, -20, 1, -70)
    scrollFrame.Position = UDim2.new(0, 10, 0, 60)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.Parent = mainContainer
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.Name
    listLayout.Padding = UDim.new(0, 10)
    listLayout.Parent = scrollFrame
    
    -- 绑定关闭按钮
    closeButton.MouseButton1Click:Connect(function()
        RobotStatusUI.Hide()
    end)
    
    return screenGui
end

-- 创建显示/隐藏按钮
local function createToggleButton()
    local buttonGui = Instance.new("ScreenGui")
    buttonGui.Name = "RobotStatusToggle"
    buttonGui.ResetOnSpawn = false
    buttonGui.Parent = playerGui
    
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = UDim2.new(0, 80, 0, 40)
    toggleButton.Position = UDim2.new(0, 20, 0, 80) -- 在资源显示下方
    toggleButton.BackgroundColor3 = Color3.fromRGB(100, 50, 150)
    toggleButton.BorderSizePixel = 0
    toggleButton.Text = "🤖 机器人"
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.TextScaled = true
    toggleButton.Font = Enum.Font.SourceSansBold
    toggleButton.Parent = buttonGui
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = toggleButton
    
    toggleButton.MouseButton1Click:Connect(function()
        if RobotStatusUI.isVisible then
            RobotStatusUI.Hide()
        else
            RobotStatusUI.Show()
        end
    end)
    
    return buttonGui
end

--------------------------------------------------------------------
-- UI管理函数
--------------------------------------------------------------------

function RobotStatusUI.Show()
    if not RobotStatusUI.gui then
        RobotStatusUI.gui = createMainUI()
    end
    
    RobotStatusUI.isVisible = true
    RobotStatusUI.gui.MainContainer.Visible = true
    RobotStatusUI.RefreshRobotList()
    
    print("[RobotStatusUI] 机器人状态界面已显示")
end

function RobotStatusUI.Hide()
    RobotStatusUI.isVisible = false
    if RobotStatusUI.gui then
        RobotStatusUI.gui.MainContainer.Visible = false
    end
    
    print("[RobotStatusUI] 机器人状态界面已隐藏")
end

function RobotStatusUI.RefreshRobotList()
    if not RobotStatusUI.gui or not RobotStatusUI.isVisible then return end
    
    local scrollFrame = RobotStatusUI.gui.MainContainer.RobotScrollFrame
    
    -- 清空现有卡片
    for _, child in ipairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    RobotStatusUI.robotCards = {}
    
    -- TODO: 获取玩家的机器人列表
    -- 这里应该从RobotActiveManager或其他系统获取激活的机器人
    local robotTypes = {
        "Dig_UncommonBot",
        "Dig_RareBot", 
        "Dig_EpicBot",
        "Dig_SecretBot"
    }
    
    -- 创建机器人卡片
    for _, robotType in ipairs(robotTypes) do
        local card = createRobotCard(robotType, scrollFrame)
        RobotStatusUI.robotCards[robotType] = card
    end
    
    -- 更新滚动框大小
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, scrollFrame.UIListLayout.AbsoluteContentSize.Y + 20)
    
    -- 刷新任务状态
    RobotStatusUI.UpdateTaskStatus()
end

function RobotStatusUI.UpdateTaskStatus()
    -- 更新所有机器人卡片的任务状态
    for robotType, card in pairs(RobotStatusUI.robotCards) do
        local taskData = RobotStatusUI.robotTasks[robotType]
        
        local statusLabel = card:FindFirstChild("StatusLabel")
        local progressBg = card:FindFirstChild("ProgressBg")
        local progressBar = progressBg and progressBg:FindFirstChild("ProgressBar")
        local progressText = progressBg and progressBg:FindFirstChild("ProgressText")
        local taskIndicator = card:FindFirstChild("TaskIndicator")
        
        if taskData then
            -- 在任务中
            statusLabel.Text = "挖矿中: " .. taskData.oreType
            statusLabel.TextColor3 = Color3.fromRGB(200, 150, 50)
            
            progressBg.Visible = true
            taskIndicator.Visible = true
            
            -- 更新进度条
            local progress = math.min(taskData.completed / taskData.quantity, 1)
            progressBar.Size = UDim2.new(progress, 0, 1, 0)
            progressText.Text = string.format("%d/%d", taskData.completed, taskData.quantity)
            
            -- 闪烁效果
            local blinkTween = TweenService:Create(
                taskIndicator,
                TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                {BackgroundTransparency = 0.5}
            )
            blinkTween:Play()
            
        else
            -- 空闲状态
            statusLabel.Text = "空闲中"
            statusLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
            
            progressBg.Visible = false
            taskIndicator.Visible = false
        end
    end
end

function RobotStatusUI.UpdateRobotTask(robotType, taskData)
    RobotStatusUI.robotTasks[robotType] = taskData
    RobotStatusUI.UpdateTaskStatus()
    
    print("[RobotStatusUI] 更新机器人任务状态:", robotType, taskData and "任务中" or "空闲")
end

function RobotStatusUI.RemoveRobotTask(robotType)
    RobotStatusUI.robotTasks[robotType] = nil
    RobotStatusUI.UpdateTaskStatus()
    
    print("[RobotStatusUI] 移除机器人任务:", robotType)
end

--------------------------------------------------------------------
-- 事件处理
--------------------------------------------------------------------

-- 监听任务事件
miningTaskEvent.OnClientEvent:Connect(function(action, data)
    if action == "TASK_CREATED" then
        RobotStatusUI.UpdateRobotTask(data.robotType, data)
        
    elseif action == "TASK_COMPLETED" then
        RobotStatusUI.RemoveRobotTask(data.robotType)
        
    elseif action == "TASK_PROGRESS" then
        local taskData = RobotStatusUI.robotTasks[data.robotType]
        if taskData then
            taskData.completed = data.completed
            RobotStatusUI.UpdateTaskStatus()
        end
    end
end)

--------------------------------------------------------------------
-- 初始化
--------------------------------------------------------------------

-- 等待一下确保其他UI脚本已加载
task.wait(2)

-- 创建切换按钮
createToggleButton()

-- 暴露到全局
_G.RobotStatusUI = RobotStatusUI

print("[RobotStatusUI] 机器人状态UI系统已启动")
print("点击左侧🤖按钮查看机器人状态")