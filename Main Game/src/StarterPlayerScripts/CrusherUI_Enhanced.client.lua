--------------------------------------------------------------------
-- CrusherUI_Enhanced.client.lua · Crusher机器交互界面（增强版）
-- 功能：
--   1) 显示玩家Scrap数量和Crusher等级信息
--   2) 输入要粉碎的Scrap数量
--   3) 显示可获得的Credits
--   4) 执行粉碎操作
--   5) 集成新的10级建筑升级系统
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
local getBuildingUpgradeInfoRF = rfFolder:WaitForChild("GetBuildingUpgradeInfoFunction")

local reFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local crushScrapEvent = reFolder:WaitForChild("CrushScrapEvent")

-- 教程系统集成
local tutorialEvent = reFolder:FindFirstChild("TutorialEvent")

-- 等待共享模块
local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
local GameConstants = require(SharedModules.GameConstants.main)

--------------------------------------------------------------------
-- 工具函数
--------------------------------------------------------------------

-- 获取建筑当前等级数据
local function getBuildingLevelStats(buildingType, level)
    local upgradeData = GameConstants.BUILDING_UPGRADE_DATA
    local queueLimit = upgradeData.QueueLimit[level] or 1
    
    local stats = {
        level = level,
        queueLimit = queueLimit
    }
    
    -- 添加建筑特定属性
    local buildingData = upgradeData[buildingType]
    if buildingData then
        for statName, values in pairs(buildingData) do
            if statName ~= "description" and type(values) == "table" then
                stats[statName] = values[level] or values[1] or 1
            end
        end
    end
    
    return stats
end

-- 获取玩家建筑等级
local function getPlayerBuildingLevel(buildingType)
    local playerData = getDataRF:InvokeServer()
    if not playerData or not playerData.Upgrades then return 1 end
    
    local levelKey = buildingType .. "Level"
    return playerData.Upgrades[levelKey] or 1
end

--------------------------------------------------------------------
-- 创建Crusher UI
--------------------------------------------------------------------
local function createCrusherUI()
    -- 主界面
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CrusherUI_Enhanced"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui
    
    -- 主框架
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 400, 0, 380)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -190)
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
    titleLabel.Text = "Crusher"
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
    
    -- 建筑等级信息
    local levelInfoLabel = Instance.new("TextLabel")
    levelInfoLabel.Size = UDim2.new(1, 0, 0, 25)
    levelInfoLabel.Position = UDim2.new(0, 0, 0, 5)
    levelInfoLabel.BackgroundTransparency = 1
    levelInfoLabel.Text = "Level 1 - Speed: x1.0 - Queue: 1"
    levelInfoLabel.TextColor3 = Color3.fromRGB(80, 80, 80)
    levelInfoLabel.TextScaled = true
    levelInfoLabel.Font = Enum.Font.GothamBold
    levelInfoLabel.TextXAlignment = Enum.TextXAlignment.Center
    levelInfoLabel.Parent = contentFrame
    
    -- 玩家Scrap信息
    local scrapInfoLabel = Instance.new("TextLabel")
    scrapInfoLabel.Size = UDim2.new(1, 0, 0, 25)
    scrapInfoLabel.Position = UDim2.new(0, 0, 0, 35)
    scrapInfoLabel.BackgroundTransparency = 1
    scrapInfoLabel.Text = "You have: 0 Scrap"
    scrapInfoLabel.TextColor3 = Color3.fromRGB(60, 60, 60)
    scrapInfoLabel.TextScaled = true
    scrapInfoLabel.Font = Enum.Font.Gotham
    scrapInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
    scrapInfoLabel.Parent = contentFrame
    
    -- Credits显示
    local creditsLabel = Instance.new("TextLabel")
    creditsLabel.Size = UDim2.new(1, 0, 0, 25)
    creditsLabel.Position = UDim2.new(0, 0, 0, 65)
    creditsLabel.BackgroundTransparency = 1
    creditsLabel.Text = "Credits +0"
    creditsLabel.TextColor3 = Color3.fromRGB(60, 60, 60)
    creditsLabel.TextScaled = true
    creditsLabel.Font = Enum.Font.GothamSemibold
    creditsLabel.TextXAlignment = Enum.TextXAlignment.Right
    creditsLabel.Parent = contentFrame
    
    -- 输入框容器
    local inputContainer = Instance.new("Frame")
    inputContainer.Size = UDim2.new(0.8, 0, 0, 50)
    inputContainer.Position = UDim2.new(0.1, 0, 0, 110)
    inputContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    inputContainer.BorderSizePixel = 1
    inputContainer.BorderColor3 = Color3.fromRGB(200, 200, 200)
    inputContainer.Parent = contentFrame
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 5)
    inputCorner.Parent = inputContainer
    
    -- 输入框
    local amountInput = Instance.new("TextBox")
    amountInput.Size = UDim2.new(1, -20, 1, -10)
    amountInput.Position = UDim2.new(0, 10, 0, 5)
    amountInput.BackgroundTransparency = 1
    amountInput.Text = ""
    amountInput.PlaceholderText = "Enter amount to crush..."
    amountInput.TextColor3 = Color3.fromRGB(60, 60, 60)
    amountInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    amountInput.TextScaled = true
    amountInput.Font = Enum.Font.Gotham
    amountInput.ClearTextOnFocus = false
    amountInput.Parent = inputContainer
    
    -- Crush按钮
    local crushButton = Instance.new("TextButton")
    crushButton.Size = UDim2.new(0.6, 0, 0, 45)
    crushButton.Position = UDim2.new(0.2, 0, 0, 180)
    crushButton.BackgroundColor3 = Color3.fromRGB(100, 180, 100)
    crushButton.Text = "Crush"
    crushButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    crushButton.TextScaled = true
    crushButton.Font = Enum.Font.GothamBold
    crushButton.BorderSizePixel = 0
    crushButton.Active = true
    crushButton.Parent = contentFrame
    
    local crushCorner = Instance.new("UICorner")
    crushCorner.CornerRadius = UDim.new(0, 8)
    crushCorner.Parent = crushButton
    
    -- 分隔线
    local separator = Instance.new("Frame")
    separator.Size = UDim2.new(0.9, 0, 0, 2)
    separator.Position = UDim2.new(0.05, 0, 0, 240)
    separator.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    separator.BorderSizePixel = 0
    separator.Parent = contentFrame
    
    -- 升级信息标签
    local upgradeInfoLabel = Instance.new("TextLabel")
    upgradeInfoLabel.Size = UDim2.new(1, 0, 0, 25)
    upgradeInfoLabel.Position = UDim2.new(0, 0, 0, 255)
    upgradeInfoLabel.BackgroundTransparency = 1
    upgradeInfoLabel.Text = "Upgrade Available!"
    upgradeInfoLabel.TextColor3 = Color3.fromRGB(60, 60, 60)
    upgradeInfoLabel.TextScaled = true
    upgradeInfoLabel.Font = Enum.Font.Gotham
    upgradeInfoLabel.TextXAlignment = Enum.TextXAlignment.Center
    upgradeInfoLabel.Parent = contentFrame
    
    -- 升级按钮
    local upgradeButton = Instance.new("TextButton")
    upgradeButton.Size = UDim2.new(0.6, 0, 0, 40)
    upgradeButton.Position = UDim2.new(0.2, 0, 0, 295)
    upgradeButton.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    upgradeButton.Text = "Upgrade Details"
    upgradeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    upgradeButton.TextScaled = true
    upgradeButton.Font = Enum.Font.GothamBold
    upgradeButton.BorderSizePixel = 0
    upgradeButton.Active = true
    upgradeButton.Parent = contentFrame
    
    local upgradeCorner = Instance.new("UICorner")
    upgradeCorner.CornerRadius = UDim.new(0, 8)
    upgradeCorner.Parent = upgradeButton
    
    return screenGui, mainFrame, closeButton, levelInfoLabel, scrapInfoLabel, creditsLabel, amountInput, crushButton, upgradeInfoLabel, upgradeButton
end

--------------------------------------------------------------------
-- 主UI控制
--------------------------------------------------------------------
local crusherUI = nil
local currentCrusher = nil

-- 打开建筑升级UI
local function openBuildingUpgradeUI()
    if _G.BuildingUpgradeUI and _G.BuildingUpgradeUI.showUpgradeUI then
        _G.BuildingUpgradeUI.showUpgradeUI("Crusher", "Crusher")
        hideCrusherUI()
    else
        warn("[CrusherUI] BuildingUpgradeUI系统未加载")
    end
end

-- 显示Crusher UI
local function showCrusherUI(crusherModel)
    if not crusherUI then
        local ui, mainFrame, closeButton, levelInfoLabel, scrapInfoLabel, creditsLabel, amountInput, crushButton, upgradeInfoLabel, upgradeButton = createCrusherUI()
        crusherUI = {
            gui = ui,
            mainFrame = mainFrame,
            closeButton = closeButton,
            levelInfoLabel = levelInfoLabel,
            scrapInfoLabel = scrapInfoLabel,
            creditsLabel = creditsLabel,
            amountInput = amountInput,
            crushButton = crushButton,
            upgradeInfoLabel = upgradeInfoLabel,
            upgradeButton = upgradeButton
        }
        
        -- 关闭按钮事件
        closeButton.MouseButton1Click:Connect(function()
            hideCrusherUI()
        end)
        
        -- 输入框变化事件
        amountInput:GetPropertyChangedSignal("Text"):Connect(function()
            updateCreditsDisplay()
        end)
        
        -- Crush按钮事件
        crushButton.MouseButton1Click:Connect(function()
            performCrush()
        end)
        
        -- 升级按钮事件
        upgradeButton.MouseButton1Click:Connect(function()
            openBuildingUpgradeUI()
        end)
    end
    
    currentCrusher = crusherModel
    updateCrusherUI()
    
    -- 显示动画
    crusherUI.mainFrame.Visible = true
    crusherUI.mainFrame.Size = UDim2.new(0, 0, 0, 0)
    crusherUI.mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    local tween = TweenService:Create(crusherUI.mainFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0, 400, 0, 380),
            Position = UDim2.new(0.5, -200, 0.5, -190)
        }
    )
    tween:Play()
end

-- 隐藏Crusher UI
function hideCrusherUI()
    if not crusherUI then return end
    
    local tween = TweenService:Create(crusherUI.mainFrame,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }
    )
    tween:Play()
    
    tween.Completed:Connect(function()
        crusherUI.mainFrame.Visible = false
        currentCrusher = nil
    end)
end

-- 更新Crusher UI信息
function updateCrusherUI()
    if not crusherUI or not currentCrusher then return end
    
    -- 获取玩家数据
    local playerData = getDataRF:InvokeServer()
    if not playerData then return end
    
    local scrapAmount = playerData.Scrap or 0
    local currentLevel = getPlayerBuildingLevel("Crusher")
    local levelStats = getBuildingLevelStats("Crusher", currentLevel)
    
    -- 更新等级信息
    crusherUI.levelInfoLabel.Text = string.format("Level %d - Speed: x%.1f - Queue: %d", 
        currentLevel, levelStats.speed or 1, levelStats.queueLimit or 1)
    
    -- 更新Scrap信息
    crusherUI.scrapInfoLabel.Text = string.format("You have: %d Scrap", scrapAmount)
    
    -- 更新升级信息
    if currentLevel >= 10 then
        crusherUI.upgradeInfoLabel.Text = "Maximum Level Reached!"
        crusherUI.upgradeButton.Text = "Max Level"
        crusherUI.upgradeButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    else
        crusherUI.upgradeInfoLabel.Text = "Upgrade Available!"
        crusherUI.upgradeButton.Text = "Upgrade Details"
        crusherUI.upgradeButton.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    end
    
    -- 更新Credits显示
    updateCreditsDisplay()
end

-- 更新Credits显示
function updateCreditsDisplay()
    if not crusherUI then return end
    
    local inputText = crusherUI.amountInput.Text
    local amount = tonumber(inputText) or 0
    
    if amount > 0 then
        local currentLevel = getPlayerBuildingLevel("Crusher")
        local levelStats = getBuildingLevelStats("Crusher", currentLevel)
        
        -- Credits转换比例基于等级：Level 1 = 1:1, Level 2 = 1:2, 等等
        local creditsPerScrap = currentLevel
        local credits = amount * creditsPerScrap
        
        crusherUI.creditsLabel.Text = string.format("Credits +%d (1:%d)", credits, creditsPerScrap)
        crusherUI.creditsLabel.TextColor3 = Color3.fromRGB(0, 150, 0)
    else
        crusherUI.creditsLabel.Text = "Credits +0"
        crusherUI.creditsLabel.TextColor3 = Color3.fromRGB(60, 60, 60)
    end
end

-- 执行Crush操作
function performCrush()
    if not crusherUI or not currentCrusher then return end
    
    local inputText = crusherUI.amountInput.Text
    local amount = tonumber(inputText)
    
    if not amount or amount <= 0 then
        -- 显示错误提示
        crusherUI.amountInput.TextColor3 = Color3.fromRGB(200, 50, 50)
        task.wait(0.5)
        crusherUI.amountInput.TextColor3 = Color3.fromRGB(60, 60, 60)
        return
    end
    
    -- 获取玩家数据检查是否有足够的Scrap
    local playerData = getDataRF:InvokeServer()
    if not playerData or (playerData.Scrap or 0) < amount then
        -- 显示Scrap不足提示
        crusherUI.scrapInfoLabel.TextColor3 = Color3.fromRGB(200, 50, 50)
        task.wait(1)
        crusherUI.scrapInfoLabel.TextColor3 = Color3.fromRGB(60, 60, 60)
        return
    end
    
    -- 发送粉碎请求
    crushScrapEvent:FireServer(amount)
    
    -- 通知教程系统收集废料任务进度
    if tutorialEvent then
        tutorialEvent:FireServer("STEP_COMPLETED", "COLLECT_SCRAP", {
            target = "Scrap",
            amount = amount
        })
    end
    
    -- 清空输入框
    crusherUI.amountInput.Text = ""
    
    -- 更新UI
    updateCrusherUI()
end

--------------------------------------------------------------------
-- Crusher交互设置
--------------------------------------------------------------------
-- 为现有Crusher添加交互提示
local function setupCrusherInteractions()
    for _, obj in pairs(workspace:GetChildren()) do
        if obj:IsA("Model") and obj.Name:lower():find("crusher") then
            -- 查找合适的Part来添加ProximityPrompt
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
                    prompt.ObjectText = "Crusher"
                    prompt.ActionText = "打开"
                    prompt.HoldDuration = 0.5
                    prompt.MaxActivationDistance = 10
                    prompt.RequiresLineOfSight = false
                    prompt.Parent = targetPart
                    
                    prompt.Triggered:Connect(function(triggerPlayer)
                        if triggerPlayer == player then
                            showCrusherUI(obj)
                        end
                    end)
                    
                    print("[CrusherUI] 为Crusher添加ProximityPrompt:", obj.Name)
                end
            end
        end
    end
end

-- 监听新的Crusher
workspace.ChildAdded:Connect(function(child)
    if child:IsA("Model") and child.Name:lower():find("crusher") then
        task.wait(0.1) -- 等待属性设置
        
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
            prompt.ObjectText = "Crusher"
            prompt.ActionText = "打开"
            prompt.HoldDuration = 0.5
            prompt.MaxActivationDistance = 10
            prompt.RequiresLineOfSight = false
            prompt.Parent = targetPart
            
            prompt.Triggered:Connect(function(triggerPlayer)
                if triggerPlayer == player then
                    showCrusherUI(child)
                end
            end)
            
            print("[CrusherUI] 为新Crusher添加ProximityPrompt:", child.Name)
        end
    end
end)

-- 键盘快捷键
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end
    
    if input.KeyCode == Enum.KeyCode.E and crusherUI and crusherUI.mainFrame.Visible then
        hideCrusherUI()
    end
end)

-- 定期更新UI（如果打开状态）
task.spawn(function()
    while true do
        task.wait(1)
        if crusherUI and crusherUI.mainFrame.Visible then
            updateCrusherUI()
        end
    end
end)

-- 初始化
setupCrusherInteractions()

print("[CrusherUI_Enhanced] 增强版Crusher UI系统已加载")