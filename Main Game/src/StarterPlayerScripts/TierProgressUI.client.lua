--------------------------------------------------------------------
-- TierProgressUI.client.lua · Tier进度界面
-- 功能：
--   1) 显示当前Tier状态
--   2) 显示下一个Tier的进度要求
--   3) 显示所有Tier的概览
--   4) Tier升级通知
--------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 远程通讯
local rfFolder = ReplicatedStorage:WaitForChild("RemoteFunctions")
local getDataRF = rfFolder:WaitForChild("GetPlayerDataFunction")

local reFolder = ReplicatedStorage:WaitForChild("RemoteEvents")

-- 创建RemoteFunction用于获取Tier信息
local getTierInfoRF = rfFolder:FindFirstChild("GetTierInfoFunction")
if not getTierInfoRF then
    getTierInfoRF = Instance.new("RemoteFunction")
    getTierInfoRF.Name = "GetTierInfoFunction"
    getTierInfoRF.Parent = rfFolder
end

local getNextTierProgressRF = rfFolder:FindFirstChild("GetNextTierProgressFunction")
if not getNextTierProgressRF then
    getNextTierProgressRF = Instance.new("RemoteFunction")
    getNextTierProgressRF.Name = "GetNextTierProgressFunction"
    getNextTierProgressRF.Parent = rfFolder
end

local getAllTiersOverviewRF = rfFolder:FindFirstChild("GetAllTiersOverviewFunction")
if not getAllTiersOverviewRF then
    getAllTiersOverviewRF = Instance.new("RemoteFunction")
    getAllTiersOverviewRF.Name = "GetAllTiersOverviewFunction"
    getAllTiersOverviewRF.Parent = rfFolder
end

-- Tier升级事件
local tierUpgradeEvent = reFolder:FindFirstChild("TierUpgradeEvent")
if not tierUpgradeEvent then
    tierUpgradeEvent = Instance.new("RemoteEvent")
    tierUpgradeEvent.Name = "TierUpgradeEvent"
    tierUpgradeEvent.Parent = reFolder
end

-- 加载配置
local GameConstants = require(ReplicatedStorage.SharedModules.GameConstants.main)

--------------------------------------------------------------------
-- 创建Tier进度UI
--------------------------------------------------------------------
local function createTierProgressUI()
    -- 主界面
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TierProgressUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui
    
    -- 主框架
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 600, 0, 500)
    mainFrame.Position = UDim2.new(0.5, -300, 0.5, -250)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    -- 标题栏
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 50)
    titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -60, 1, 0)
    titleLabel.Position = UDim2.new(0, 20, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🏆 技术层级进度"
    titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar
    
    -- 关闭按钮
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -45, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
    closeButton.Text = "×"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.GothamBold
    closeButton.BorderSizePixel = 0
    closeButton.Active = true
    closeButton.Parent = titleBar
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton
    
    -- 内容区域
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Size = UDim2.new(1, -20, 1, -70)
    contentFrame.Position = UDim2.new(0, 10, 0, 60)
    contentFrame.BackgroundTransparency = 1
    contentFrame.ScrollBarThickness = 8
    contentFrame.BorderSizePixel = 0
    contentFrame.Parent = mainFrame
    
    -- 内容布局
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 15)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Parent = contentFrame
    
    return screenGui, mainFrame, closeButton, contentFrame, contentLayout
end

--------------------------------------------------------------------
-- 创建当前Tier状态卡片
--------------------------------------------------------------------
local function createCurrentTierCard(tierInfo, parent)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 100)
    card.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    card.BorderSizePixel = 0
    card.LayoutOrder = 1
    card.Parent = parent
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 10)
    cardCorner.Parent = card
    
    -- 渐变背景
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 80, 120)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(45, 45, 55))
    }
    gradient.Rotation = 45
    gradient.Parent = card
    
    -- Tier等级显示
    local tierLabel = Instance.new("TextLabel")
    tierLabel.Size = UDim2.new(0.3, 0, 0.6, 0)
    tierLabel.Position = UDim2.new(0, 15, 0, 10)
    tierLabel.BackgroundTransparency = 1
    tierLabel.Text = "Tier " .. (tierInfo.tier or 0)
    tierLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    tierLabel.TextScaled = true
    tierLabel.Font = Enum.Font.GothamBold
    tierLabel.TextXAlignment = Enum.TextXAlignment.Left
    tierLabel.Parent = card
    
    -- Tier名称
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.65, 0, 0.6, 0)
    nameLabel.Position = UDim2.new(0.3, 10, 0, 10)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = tierInfo.name or "未知"
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = card
    
    -- 描述
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, -20, 0.35, 0)
    descLabel.Position = UDim2.new(0, 15, 0.6, 5)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = tierInfo.description or ""
    descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    descLabel.TextScaled = true
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.TextWrapped = true
    descLabel.Parent = card
    
    return card
end

--------------------------------------------------------------------
-- 创建下一Tier进度卡片
--------------------------------------------------------------------
local function createNextTierCard(nextTierInfo, parent)
    if not nextTierInfo then
        -- 已达最高Tier
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, 80)
        card.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        card.BorderSizePixel = 0
        card.LayoutOrder = 2
        card.Parent = parent
        
        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, 10)
        cardCorner.Parent = card
        
        local maxLabel = Instance.new("TextLabel")
        maxLabel.Size = UDim2.new(1, -20, 1, 0)
        maxLabel.Position = UDim2.new(0, 10, 0, 0)
        maxLabel.BackgroundTransparency = 1
        maxLabel.Text = "🎉 恭喜！您已达到最高技术层级！"
        maxLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
        maxLabel.TextScaled = true
        maxLabel.Font = Enum.Font.GothamBold
        maxLabel.Parent = card
        
        return card
    end
    
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 250)
    card.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    card.BorderSizePixel = 0
    card.LayoutOrder = 2
    card.Parent = parent
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 10)
    cardCorner.Parent = card
    
    -- 标题
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 30)
    titleLabel.Position = UDim2.new(0, 10, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = string.format("🎯 下一层级: Tier %d - %s", nextTierInfo.tier, nextTierInfo.name)
    titleLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = card
    
    -- 描述
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, -20, 0, 25)
    descLabel.Position = UDim2.new(0, 10, 0, 45)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = nextTierInfo.description
    descLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    descLabel.TextScaled = true
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.TextWrapped = true
    descLabel.Parent = card
    
    -- 进度条容器
    local progressContainer = Instance.new("Frame")
    progressContainer.Size = UDim2.new(1, -20, 1, -90)
    progressContainer.Position = UDim2.new(0, 10, 0, 80)
    progressContainer.BackgroundTransparency = 1
    progressContainer.Parent = card
    
    local progressLayout = Instance.new("UIListLayout")
    progressLayout.Padding = UDim.new(0, 8)
    progressLayout.SortOrder = Enum.SortOrder.LayoutOrder
    progressLayout.Parent = progressContainer
    
    -- 进度条
    local orderCounter = 0
    for reqType, progressInfo in pairs(nextTierInfo.progress) do
        orderCounter = orderCounter + 1
        
        local progressFrame = Instance.new("Frame")
        progressFrame.Size = UDim2.new(1, 0, 0, 25)
        progressFrame.BackgroundTransparency = 1
        progressFrame.LayoutOrder = orderCounter
        progressFrame.Parent = progressContainer
        
        -- 需求名称
        local reqNameMap = {
            scrap = "废料收集",
            tutorialComplete = "完成教程",
            ironOre = "铁矿收集",
            bronzeOre = "青铜矿收集", 
            goldOre = "黄金矿收集",
            diamondOre = "钻石矿收集",
            titaniumOre = "钛矿收集",
            ironBar = "铁锭制作",
            bronzeGear = "青铜齿轮制作",
            goldPlatedEdge = "镀金边缘制作",
            depth = "探索深度",
            buildingLevel = "建筑等级",
            energyStation = "能量站建造"
        }
        
        local reqLabel = Instance.new("TextLabel")
        reqLabel.Size = UDim2.new(0.4, 0, 1, 0)
        reqLabel.BackgroundTransparency = 1
        reqLabel.Text = reqNameMap[reqType] or reqType
        reqLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        reqLabel.TextScaled = true
        reqLabel.Font = Enum.Font.Gotham
        reqLabel.TextXAlignment = Enum.TextXAlignment.Left
        reqLabel.Parent = progressFrame
        
        -- 进度条背景
        local progressBg = Instance.new("Frame")
        progressBg.Size = UDim2.new(0.45, 0, 0.6, 0)
        progressBg.Position = UDim2.new(0.4, 5, 0.2, 0)
        progressBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        progressBg.BorderSizePixel = 0
        progressBg.Parent = progressFrame
        
        local progressBgCorner = Instance.new("UICorner")
        progressBgCorner.CornerRadius = UDim.new(0, 3)
        progressBgCorner.Parent = progressBg
        
        -- 进度条
        local progress = math.min(progressInfo.current / progressInfo.required, 1)
        local progressBar = Instance.new("Frame")
        progressBar.Size = UDim2.new(progress, 0, 1, 0)
        progressBar.BackgroundColor3 = progressInfo.completed and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(100, 150, 255)
        progressBar.BorderSizePixel = 0
        progressBar.Parent = progressBg
        
        local progressBarCorner = Instance.new("UICorner")
        progressBarCorner.CornerRadius = UDim.new(0, 3)
        progressBarCorner.Parent = progressBar
        
        -- 进度文本
        local progressText = Instance.new("TextLabel")
        progressText.Size = UDim2.new(0.15, 0, 1, 0)
        progressText.Position = UDim2.new(0.85, 5, 0, 0)
        progressText.BackgroundTransparency = 1
        progressText.Text = string.format("%d/%d", progressInfo.current, progressInfo.required)
        progressText.TextColor3 = progressInfo.completed and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 255, 255)
        progressText.TextScaled = true
        progressText.Font = Enum.Font.GothamBold
        progressText.Parent = progressFrame
    end
    
    return card
end

--------------------------------------------------------------------
-- 创建Tier概览卡片
--------------------------------------------------------------------
local function createTierOverviewCard(tiersOverview, parent)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 300)
    card.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    card.BorderSizePixel = 0
    card.LayoutOrder = 3
    card.Parent = parent
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 10)
    cardCorner.Parent = card
    
    -- 标题
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 30)
    titleLabel.Position = UDim2.new(0, 10, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "📊 所有技术层级"
    titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = card
    
    -- Tier列表容器
    local tierListContainer = Instance.new("ScrollingFrame")
    tierListContainer.Size = UDim2.new(1, -20, 1, -50)
    tierListContainer.Position = UDim2.new(0, 10, 0, 40)
    tierListContainer.BackgroundTransparency = 1
    tierListContainer.ScrollBarThickness = 6
    tierListContainer.BorderSizePixel = 0
    tierListContainer.Parent = card
    
    local tierListLayout = Instance.new("UIListLayout")
    tierListLayout.Padding = UDim.new(0, 5)
    tierListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tierListLayout.Parent = tierListContainer
    
    -- 创建每个Tier的条目
    for _, tierInfo in ipairs(tiersOverview) do
        local tierItem = Instance.new("Frame")
        tierItem.Size = UDim2.new(1, -10, 0, 45)
        tierItem.BackgroundColor3 = tierInfo.isCurrent and Color3.fromRGB(80, 100, 140) or 
                                    tierInfo.isUnlocked and Color3.fromRGB(60, 80, 60) or 
                                    Color3.fromRGB(60, 60, 70)
        tierItem.BorderSizePixel = 0
        tierItem.LayoutOrder = tierInfo.tier
        tierItem.Parent = tierListContainer
        
        local tierItemCorner = Instance.new("UICorner")
        tierItemCorner.CornerRadius = UDim.new(0, 5)
        tierItemCorner.Parent = tierItem
        
        -- 状态图标
        local statusIcon = Instance.new("TextLabel")
        statusIcon.Size = UDim2.new(0, 30, 1, 0)
        statusIcon.Position = UDim2.new(0, 5, 0, 0)
        statusIcon.BackgroundTransparency = 1
        statusIcon.Text = tierInfo.isCurrent and "🔸" or 
                         tierInfo.isUnlocked and "✅" or "🔒"
        statusIcon.TextScaled = true
        statusIcon.Font = Enum.Font.Gotham
        statusIcon.Parent = tierItem
        
        -- Tier信息
        local tierInfoLabel = Instance.new("TextLabel")
        tierInfoLabel.Size = UDim2.new(1, -40, 1, 0)
        tierInfoLabel.Position = UDim2.new(0, 35, 0, 0)
        tierInfoLabel.BackgroundTransparency = 1
        tierInfoLabel.Text = string.format("Tier %d: %s", tierInfo.tier, tierInfo.name)
        tierInfoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        tierInfoLabel.TextScaled = true
        tierInfoLabel.Font = Enum.Font.GothamSemibold
        tierInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
        tierInfoLabel.Parent = tierItem
    end
    
    -- 更新滚动区域大小
    tierListContainer.CanvasSize = UDim2.new(0, 0, 0, #tiersOverview * 50)
    
    return card
end

--------------------------------------------------------------------
-- 主UI控制
--------------------------------------------------------------------
local tierProgressUI = nil

-- 显示Tier进度UI
local function showTierProgressUI()
    if not tierProgressUI then
        local ui, mainFrame, closeButton, contentFrame, contentLayout = createTierProgressUI()
        tierProgressUI = {
            gui = ui,
            mainFrame = mainFrame,
            closeButton = closeButton,
            contentFrame = contentFrame,
            contentLayout = contentLayout
        }
        
        -- 关闭按钮事件
        closeButton.MouseButton1Click:Connect(function()
            hideTierProgressUI()
        end)
    end
    
    -- 清除现有内容
    for _, child in pairs(tierProgressUI.contentFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- 获取Tier信息
    local currentTierInfo = getTierInfoRF:InvokeServer()
    local nextTierProgress = getNextTierProgressRF:InvokeServer()
    local allTiersOverview = getAllTiersOverviewRF:InvokeServer()
    
    -- 创建UI内容
    if currentTierInfo then
        createCurrentTierCard(currentTierInfo, tierProgressUI.contentFrame)
    end
    
    createNextTierCard(nextTierProgress, tierProgressUI.contentFrame)
    
    if allTiersOverview and #allTiersOverview > 0 then
        createTierOverviewCard(allTiersOverview, tierProgressUI.contentFrame)
    end
    
    -- 更新滚动区域大小
    local totalHeight = 0
    for _, child in pairs(tierProgressUI.contentFrame:GetChildren()) do
        if child:IsA("Frame") then
            totalHeight = totalHeight + child.Size.Y.Offset + 15
        end
    end
    tierProgressUI.contentFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
    
    -- 显示动画
    tierProgressUI.mainFrame.Visible = true
    tierProgressUI.mainFrame.Size = UDim2.new(0, 0, 0, 0)
    tierProgressUI.mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    local tween = TweenService:Create(tierProgressUI.mainFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0, 600, 0, 500),
            Position = UDim2.new(0.5, -300, 0.5, -250)
        }
    )
    tween:Play()
end

-- 隐藏Tier进度UI
function hideTierProgressUI()
    if not tierProgressUI then return end
    
    local tween = TweenService:Create(tierProgressUI.mainFrame,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }
    )
    tween:Play()
    
    tween.Completed:Connect(function()
        tierProgressUI.mainFrame.Visible = false
    end)
end

--------------------------------------------------------------------
-- Tier升级通知
--------------------------------------------------------------------
local function showTierUpgradeNotification(upgradeInfo)
    -- 创建升级通知界面
    local notificationGui = Instance.new("ScreenGui")
    notificationGui.Name = "TierUpgradeNotification"
    notificationGui.ResetOnSpawn = false
    notificationGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    notificationGui.Parent = playerGui
    
    -- 通知框架
    local notificationFrame = Instance.new("Frame")
    notificationFrame.Size = UDim2.new(0, 400, 0, 300)
    notificationFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
    notificationFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    notificationFrame.BorderSizePixel = 0
    notificationFrame.Parent = notificationGui
    
    local notificationCorner = Instance.new("UICorner")
    notificationCorner.CornerRadius = UDim.new(0, 15)
    notificationCorner.Parent = notificationFrame
    
    -- 渐变背景
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 165, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 140, 0))
    }
    gradient.Rotation = 45
    gradient.Parent = notificationFrame
    
    -- 升级标题
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 50)
    titleLabel.Position = UDim2.new(0, 10, 0, 15)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🎉 技术层级升级！"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = notificationFrame
    
    -- Tier信息
    local tierInfoLabel = Instance.new("TextLabel")
    tierInfoLabel.Size = UDim2.new(1, -20, 0, 40)
    tierInfoLabel.Position = UDim2.new(0, 10, 0, 70)
    tierInfoLabel.BackgroundTransparency = 1
    tierInfoLabel.Text = string.format("Tier %d → Tier %d", upgradeInfo.oldTier, upgradeInfo.newTier)
    tierInfoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    tierInfoLabel.TextScaled = true
    tierInfoLabel.Font = Enum.Font.GothamBold
    tierInfoLabel.Parent = notificationFrame
    
    -- 新Tier名称
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -20, 0, 30)
    nameLabel.Position = UDim2.new(0, 10, 0, 115)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = upgradeInfo.tierName
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamSemibold
    nameLabel.Parent = notificationFrame
    
    -- 解锁内容
    local unlocksLabel = Instance.new("TextLabel")
    unlocksLabel.Size = UDim2.new(1, -20, 0, 80)
    unlocksLabel.Position = UDim2.new(0, 10, 0, 150)
    unlocksLabel.BackgroundTransparency = 1
    unlocksLabel.Text = "解锁内容：\n" .. table.concat(upgradeInfo.unlocks, "、")
    unlocksLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    unlocksLabel.TextScaled = true
    unlocksLabel.Font = Enum.Font.Gotham
    unlocksLabel.TextWrapped = true
    unlocksLabel.Parent = notificationFrame
    
    -- 确认按钮
    local confirmButton = Instance.new("TextButton")
    confirmButton.Size = UDim2.new(0, 120, 0, 40)
    confirmButton.Position = UDim2.new(0.5, -60, 1, -50)
    confirmButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    confirmButton.Text = "太棒了！"
    confirmButton.TextColor3 = Color3.fromRGB(25, 25, 35)
    confirmButton.TextScaled = true
    confirmButton.Font = Enum.Font.GothamBold
    confirmButton.BorderSizePixel = 0
    confirmButton.Active = true
    confirmButton.Parent = notificationFrame
    
    local confirmCorner = Instance.new("UICorner")
    confirmCorner.CornerRadius = UDim.new(0, 8)
    confirmCorner.Parent = confirmButton
    
    -- 确认按钮事件
    confirmButton.MouseButton1Click:Connect(function()
        notificationGui:Destroy()
    end)
    
    -- 显示动画
    notificationFrame.Size = UDim2.new(0, 0, 0, 0)
    notificationFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    local showTween = TweenService:Create(notificationFrame,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0, 400, 0, 300),
            Position = UDim2.new(0.5, -200, 0.5, -150)
        }
    )
    showTween:Play()
    
    -- 自动关闭
    task.spawn(function()
        task.wait(8)
        if notificationGui.Parent then
            notificationGui:Destroy()
        end
    end)
end

--------------------------------------------------------------------
-- 事件处理
--------------------------------------------------------------------

-- 处理Tier升级事件
tierUpgradeEvent.OnClientEvent:Connect(function(upgradeInfo)
    showTierUpgradeNotification(upgradeInfo)
end)

-- 键盘快捷键
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end
    
    if input.KeyCode == Enum.KeyCode.T then
        if tierProgressUI and tierProgressUI.mainFrame.Visible then
            hideTierProgressUI()
        else
            showTierProgressUI()
        end
    elseif input.KeyCode == Enum.KeyCode.Escape and tierProgressUI and tierProgressUI.mainFrame.Visible then
        hideTierProgressUI()
    end
end)

--------------------------------------------------------------------
-- 导出函数给其他UI使用
--------------------------------------------------------------------
local TierProgressUI = {}
TierProgressUI.showTierUI = showTierProgressUI
TierProgressUI.hideTierUI = hideTierProgressUI

-- 将函数暴露到全局作用域
_G.TierProgressUI = TierProgressUI

print("[TierProgressUI] Tier进度UI系统已加载")
print("按 T 键打开/关闭 Tier进度界面")