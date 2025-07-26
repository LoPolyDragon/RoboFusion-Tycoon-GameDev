--------------------------------------------------------------------
-- BuildingUpgradeUI.client.lua · 通用建筑升级界面
-- 功能：
--   1) 显示详细的建筑升级信息
--   2) 支持所有建筑类型的10级升级系统
--   3) 显示队列上限和特定属性提升
--   4) 统一的升级确认界面
--------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 远程通讯
local rfFolder = ReplicatedStorage:WaitForChild("RemoteFunctions")
local getBuildingUpgradeInfoRF = rfFolder:WaitForChild("GetBuildingUpgradeInfoFunction")

local reFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local upgradeMachineEvent = reFolder:WaitForChild("UpgradeMachineEvent")

-- 加载配置
local GameConstants = require(ReplicatedStorage.SharedModules.GameConstants.main)

--------------------------------------------------------------------
-- 创建建筑升级详情UI
--------------------------------------------------------------------
local function createBuildingUpgradeUI()
    -- 主界面
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BuildingUpgradeUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui
    
    -- 主框架
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 500, 0, 600)
    mainFrame.Position = UDim2.new(0.5, -250, 0.5, -300)
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
    titleBar.BackgroundColor3 = Color3.fromRGB(60, 120, 180)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = titleBar
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -50, 1, 0)
    titleLabel.Position = UDim2.new(0, 15, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Building Upgrade"
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
    
    -- 内容布局
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 10)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Parent = contentFrame
    
    return screenGui, mainFrame, closeButton, contentFrame
end

--------------------------------------------------------------------
-- 创建升级信息卡片
--------------------------------------------------------------------
local function createUpgradeInfoCard(upgradeInfo, parent)
    -- 主卡片
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 120)
    card.BackgroundColor3 = Color3.fromRGB(250, 250, 250)
    card.BorderSizePixel = 1
    card.BorderColor3 = Color3.fromRGB(200, 200, 200)
    card.LayoutOrder = 1
    card.Parent = parent
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = card
    
    -- 当前等级信息
    local currentLevelLabel = Instance.new("TextLabel")
    currentLevelLabel.Size = UDim2.new(0.5, -10, 0, 30)
    currentLevelLabel.Position = UDim2.new(0, 10, 0, 10)
    currentLevelLabel.BackgroundTransparency = 1
    currentLevelLabel.Text = string.format("Current Level: %d", upgradeInfo.currentLevel)
    currentLevelLabel.TextColor3 = Color3.fromRGB(60, 60, 60)
    currentLevelLabel.TextScaled = true
    currentLevelLabel.Font = Enum.Font.GothamBold
    currentLevelLabel.TextXAlignment = Enum.TextXAlignment.Left
    currentLevelLabel.Parent = card
    
    -- 下一等级信息
    local nextLevelLabel = Instance.new("TextLabel")
    nextLevelLabel.Size = UDim2.new(0.5, -10, 0, 30)
    nextLevelLabel.Position = UDim2.new(0.5, 0, 0, 10)
    nextLevelLabel.BackgroundTransparency = 1
    nextLevelLabel.Text = string.format("Next Level: %d", upgradeInfo.nextLevel)
    nextLevelLabel.TextColor3 = Color3.fromRGB(60, 60, 60)
    nextLevelLabel.TextScaled = true
    nextLevelLabel.Font = Enum.Font.GothamBold
    nextLevelLabel.TextXAlignment = Enum.TextXAlignment.Left
    nextLevelLabel.Parent = card
    
    -- 升级费用
    local costLabel = Instance.new("TextLabel")
    costLabel.Size = UDim2.new(1, -20, 0, 25)
    costLabel.Position = UDim2.new(0, 10, 0, 45)
    costLabel.BackgroundTransparency = 1
    costLabel.Text = string.format("Upgrade Cost: %d Credits", upgradeInfo.cost)
    costLabel.TextColor3 = upgradeInfo.canAfford and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(200, 50, 50)
    costLabel.TextScaled = true
    costLabel.Font = Enum.Font.Gotham
    costLabel.TextXAlignment = Enum.TextXAlignment.Left
    costLabel.Parent = card
    
    -- 状态指示
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -20, 0, 20)
    statusLabel.Position = UDim2.new(0, 10, 0, 75)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = upgradeInfo.canAfford and "✓ Can afford upgrade" or "✗ Insufficient Credits"
    statusLabel.TextColor3 = upgradeInfo.canAfford and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(200, 50, 50)
    statusLabel.TextScaled = true
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = card
    
    return card
end

--------------------------------------------------------------------
-- 创建属性对比表
--------------------------------------------------------------------
local function createStatsComparison(upgradeInfo, parent)
    local statsFrame = Instance.new("Frame")
    statsFrame.Size = UDim2.new(1, 0, 0, 200)
    statsFrame.BackgroundColor3 = Color3.fromRGB(250, 250, 250)
    statsFrame.BorderSizePixel = 1
    statsFrame.BorderColor3 = Color3.fromRGB(200, 200, 200)
    statsFrame.LayoutOrder = 2
    statsFrame.Parent = parent
    
    local statsCorner = Instance.new("UICorner")
    statsCorner.CornerRadius = UDim.new(0, 8)
    statsCorner.Parent = statsFrame
    
    -- 标题
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 30)
    titleLabel.Position = UDim2.new(0, 10, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Upgrade Benefits"
    titleLabel.TextColor3 = Color3.fromRGB(60, 60, 60)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = statsFrame
    
    -- 表头
    local headerFrame = Instance.new("Frame")
    headerFrame.Size = UDim2.new(1, -20, 0, 25)
    headerFrame.Position = UDim2.new(0, 10, 0, 45)
    headerFrame.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
    headerFrame.BorderSizePixel = 0
    headerFrame.Parent = statsFrame
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 5)
    headerCorner.Parent = headerFrame
    
    local statHeader = Instance.new("TextLabel")
    statHeader.Size = UDim2.new(0.4, 0, 1, 0)
    statHeader.Position = UDim2.new(0, 5, 0, 0)
    statHeader.BackgroundTransparency = 1
    statHeader.Text = "Attribute"
    statHeader.TextColor3 = Color3.fromRGB(60, 60, 60)
    statHeader.TextScaled = true
    statHeader.Font = Enum.Font.GothamBold
    statHeader.TextXAlignment = Enum.TextXAlignment.Left
    statHeader.Parent = headerFrame
    
    local currentHeader = Instance.new("TextLabel")
    currentHeader.Size = UDim2.new(0.3, 0, 1, 0)
    currentHeader.Position = UDim2.new(0.4, 0, 0, 0)
    currentHeader.BackgroundTransparency = 1
    currentHeader.Text = "Current"
    currentHeader.TextColor3 = Color3.fromRGB(60, 60, 60)
    currentHeader.TextScaled = true
    currentHeader.Font = Enum.Font.GothamBold
    currentHeader.Parent = headerFrame
    
    local nextHeader = Instance.new("TextLabel")
    nextHeader.Size = UDim2.new(0.3, 0, 1, 0)
    nextHeader.Position = UDim2.new(0.7, 0, 0, 0)
    nextHeader.BackgroundTransparency = 1
    nextHeader.Text = "After Upgrade"
    nextHeader.TextColor3 = Color3.fromRGB(60, 60, 60)
    nextHeader.TextScaled = true
    nextHeader.Font = Enum.Font.GothamBold
    nextHeader.Parent = headerFrame
    
    -- 统计行
    local yOffset = 75
    local rowHeight = 20
    
    -- 队列上限
    local queueRow = Instance.new("Frame")
    queueRow.Size = UDim2.new(1, -20, 0, rowHeight)
    queueRow.Position = UDim2.new(0, 10, 0, yOffset)
    queueRow.BackgroundTransparency = 1
    queueRow.Parent = statsFrame
    
    local queueLabel = Instance.new("TextLabel")
    queueLabel.Size = UDim2.new(0.4, 0, 1, 0)
    queueLabel.BackgroundTransparency = 1
    queueLabel.Text = "Queue Limit"
    queueLabel.TextColor3 = Color3.fromRGB(80, 80, 80)
    queueLabel.TextScaled = true
    queueLabel.Font = Enum.Font.Gotham
    queueLabel.TextXAlignment = Enum.TextXAlignment.Left
    queueLabel.Parent = queueRow
    
    local currentQueue = Instance.new("TextLabel")
    currentQueue.Size = UDim2.new(0.3, 0, 1, 0)
    currentQueue.Position = UDim2.new(0.4, 0, 0, 0)
    currentQueue.BackgroundTransparency = 1
    currentQueue.Text = tostring(upgradeInfo.currentStats.queueLimit or 1)
    currentQueue.TextColor3 = Color3.fromRGB(80, 80, 80)
    currentQueue.TextScaled = true
    currentQueue.Font = Enum.Font.Gotham
    currentQueue.Parent = queueRow
    
    local nextQueue = Instance.new("TextLabel")
    nextQueue.Size = UDim2.new(0.3, 0, 1, 0)
    nextQueue.Position = UDim2.new(0.7, 0, 0, 0)
    nextQueue.BackgroundTransparency = 1
    nextQueue.Text = tostring(upgradeInfo.nextStats.queueLimit or 1)
    nextQueue.TextColor3 = Color3.fromRGB(0, 150, 0)
    nextQueue.TextScaled = true
    nextQueue.Font = Enum.Font.GothamBold
    nextQueue.Parent = queueRow
    
    yOffset = yOffset + rowHeight + 5
    
    -- 其他属性
    for statName, nextValue in pairs(upgradeInfo.nextStats) do
        if statName ~= "queueLimit" and statName ~= "level" then
            local currentValue = upgradeInfo.currentStats[statName] or 0
            
            local statRow = Instance.new("Frame")
            statRow.Size = UDim2.new(1, -20, 0, rowHeight)
            statRow.Position = UDim2.new(0, 10, 0, yOffset)
            statRow.BackgroundTransparency = 1
            statRow.Parent = statsFrame
            
            local statNameLabel = Instance.new("TextLabel")
            statNameLabel.Size = UDim2.new(0.4, 0, 1, 0)
            statNameLabel.BackgroundTransparency = 1
            statNameLabel.Text = statName:sub(1, 1):upper() .. statName:sub(2)
            statNameLabel.TextColor3 = Color3.fromRGB(80, 80, 80)
            statNameLabel.TextScaled = true
            statNameLabel.Font = Enum.Font.Gotham
            statNameLabel.TextXAlignment = Enum.TextXAlignment.Left
            statNameLabel.Parent = statRow
            
            local currentValueLabel = Instance.new("TextLabel")
            currentValueLabel.Size = UDim2.new(0.3, 0, 1, 0)
            currentValueLabel.Position = UDim2.new(0.4, 0, 0, 0)
            currentValueLabel.BackgroundTransparency = 1
            currentValueLabel.Text = string.format("%.1f", currentValue)
            currentValueLabel.TextColor3 = Color3.fromRGB(80, 80, 80)
            currentValueLabel.TextScaled = true
            currentValueLabel.Font = Enum.Font.Gotham
            currentValueLabel.Parent = statRow
            
            local nextValueLabel = Instance.new("TextLabel")
            nextValueLabel.Size = UDim2.new(0.3, 0, 1, 0)
            nextValueLabel.Position = UDim2.new(0.7, 0, 0, 0)
            nextValueLabel.BackgroundTransparency = 1
            nextValueLabel.Text = string.format("%.1f", nextValue)
            nextValueLabel.TextColor3 = Color3.fromRGB(0, 150, 0)
            nextValueLabel.TextScaled = true
            nextValueLabel.Font = Enum.Font.GothamBold
            nextValueLabel.Parent = statRow
            
            yOffset = yOffset + rowHeight + 5
        end
    end
    
    -- 调整frame大小
    statsFrame.Size = UDim2.new(1, 0, 0, math.max(200, yOffset + 10))
    
    return statsFrame
end

--------------------------------------------------------------------
-- 创建升级按钮
--------------------------------------------------------------------
local function createUpgradeButton(upgradeInfo, buildingType, parent)
    local buttonFrame = Instance.new("Frame")
    buttonFrame.Size = UDim2.new(1, 0, 0, 60)
    buttonFrame.BackgroundTransparency = 1
    buttonFrame.LayoutOrder = 3
    buttonFrame.Parent = parent
    
    local upgradeButton = Instance.new("TextButton")
    upgradeButton.Size = UDim2.new(1, -20, 0, 45)
    upgradeButton.Position = UDim2.new(0, 10, 0, 7)
    upgradeButton.BackgroundColor3 = upgradeInfo.canAfford and Color3.fromRGB(60, 120, 180) or Color3.fromRGB(150, 150, 150)
    upgradeButton.Text = upgradeInfo.canAfford and 
        string.format("Upgrade to Level %d", upgradeInfo.nextLevel) or 
        "Insufficient Credits"
    upgradeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    upgradeButton.TextScaled = true
    upgradeButton.Font = Enum.Font.GothamBold
    upgradeButton.BorderSizePixel = 0
    upgradeButton.Active = upgradeInfo.canAfford
    upgradeButton.Parent = buttonFrame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = upgradeButton
    
    return upgradeButton
end

--------------------------------------------------------------------
-- 主UI控制
--------------------------------------------------------------------
local buildingUpgradeUI = nil
local currentBuildingType = nil

-- 显示建筑升级UI
local function showBuildingUpgradeUI(buildingType, buildingName)
    currentBuildingType = buildingType
    
    if not buildingUpgradeUI then
        local ui, mainFrame, closeButton, contentFrame = createBuildingUpgradeUI()
        
        buildingUpgradeUI = {
            gui = ui,
            mainFrame = mainFrame,
            closeButton = closeButton,
            contentFrame = contentFrame
        }
        
        -- 关闭按钮事件
        closeButton.MouseButton1Click:Connect(function()
            hideBuildingUpgradeUI()
        end)
    end
    
    -- 更新标题
    buildingUpgradeUI.mainFrame.TitleBar.TextLabel.Text = string.format("%s Upgrade", buildingName or buildingType)
    
    -- 清除现有内容
    for _, child in pairs(buildingUpgradeUI.contentFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- 获取升级信息
    local upgradeInfo = getBuildingUpgradeInfoRF:InvokeServer(buildingType)
    
    if not upgradeInfo then
        -- 已达最高等级或无效建筑
        local maxLevelLabel = Instance.new("TextLabel")
        maxLevelLabel.Size = UDim2.new(1, 0, 0, 100)
        maxLevelLabel.BackgroundTransparency = 1
        maxLevelLabel.Text = "Building is already at maximum level!"
        maxLevelLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
        maxLevelLabel.TextScaled = true
        maxLevelLabel.Font = Enum.Font.GothamBold
        maxLevelLabel.LayoutOrder = 1
        maxLevelLabel.Parent = buildingUpgradeUI.contentFrame
        
        -- 显示动画
        buildingUpgradeUI.mainFrame.Visible = true
        local tween = TweenService:Create(buildingUpgradeUI.mainFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            { Size = UDim2.new(0, 500, 0, 200) }
        )
        tween:Play()
        return
    end
    
    -- 创建UI组件
    createUpgradeInfoCard(upgradeInfo, buildingUpgradeUI.contentFrame)
    createStatsComparison(upgradeInfo, buildingUpgradeUI.contentFrame)
    local upgradeButton = createUpgradeButton(upgradeInfo, buildingType, buildingUpgradeUI.contentFrame)
    
    -- 升级按钮事件
    if upgradeInfo.canAfford then
        upgradeButton.MouseButton1Click:Connect(function()
            upgradeMachineEvent:FireServer(buildingType)
            hideBuildingUpgradeUI()
        end)
    end
    
    -- 显示动画
    buildingUpgradeUI.mainFrame.Visible = true
    buildingUpgradeUI.mainFrame.Size = UDim2.new(0, 0, 0, 0)
    buildingUpgradeUI.mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    local tween = TweenService:Create(buildingUpgradeUI.mainFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0, 500, 0, 600),
            Position = UDim2.new(0.5, -250, 0.5, -300)
        }
    )
    tween:Play()
end

-- 隐藏建筑升级UI
local function hideBuildingUpgradeUI()
    if not buildingUpgradeUI then return end
    
    local tween = TweenService:Create(buildingUpgradeUI.mainFrame,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }
    )
    tween:Play()
    
    tween.Completed:Connect(function()
        buildingUpgradeUI.mainFrame.Visible = false
        currentBuildingType = nil
    end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end
    
    if input.KeyCode == Enum.KeyCode.Escape and buildingUpgradeUI and buildingUpgradeUI.mainFrame.Visible then
        hideBuildingUpgradeUI()
    end
end)

--------------------------------------------------------------------
-- 导出函数给其他UI使用
--------------------------------------------------------------------
local BuildingUpgradeUI = {}
BuildingUpgradeUI.showUpgradeUI = showBuildingUpgradeUI
BuildingUpgradeUI.hideUpgradeUI = hideBuildingUpgradeUI

-- 将函数暴露到全局作用域，供其他UI脚本调用
_G.BuildingUpgradeUI = BuildingUpgradeUI

print("[BuildingUpgradeUI] 通用建筑升级UI系统已加载")