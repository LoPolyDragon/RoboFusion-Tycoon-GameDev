--------------------------------------------------------------------
-- GeneratorUI.client.lua · Generator机器交互界面
-- 功能：
--   1) 显示所有可生成的Shell类型
--   2) 显示每种Shell的材料需求
--   3) 选择Shell类型和数量进行生成
--   4) 包含升级功能
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
local getUpgradeInfoRF = rfFolder:WaitForChild("GetUpgradeInfoFunction")

local reFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local generateShellEvent = reFolder:WaitForChild("GenerateShellEvent") -- 使用正确的GenerateShellEvent
local upgradeMachineEvent = reFolder:WaitForChild("UpgradeMachineEvent")

-- 教程系统集成
local tutorialEvent = reFolder:FindFirstChild("TutorialEvent")

-- 加载IconUtils
local IconUtils = require(ReplicatedStorage.ClientUtils.IconUtils)

-- Shell配置 (基于截图和IconUtils)
local SHELL_INFO = {
    {
        id = "RustyShell",
        name = "RustyShell",
        cost = {
            {type = "Scrap", amount = 150}
        },
        rarity = "Uncommon",
        color = Color3.fromRGB(139, 69, 19)
    },
    {
        id = "NeonCoreShell", 
        name = "Neon Core Shell",
        cost = {
            {type = "Scrap", amount = 500},
            {type = "Copper", amount = 1}
        },
        rarity = "Rare",
        color = Color3.fromRGB(0, 255, 255)
    },
    {
        id = "QuantumCapsuleShell",
        name = "Quantum Capsule", 
        cost = {
            {type = "Scrap", amount = 1000},
            {type = "Crystal", amount = 1}
        },
        rarity = "Epic",
        color = Color3.fromRGB(128, 0, 128)
    },
    {
        id = "EcoBoosterPodShell",
        name = "Eco Booster Pod",
        cost = {
            {type = "Scrap", amount = 1500},
            {type = "EcoCore", amount = 1}
        },
        rarity = "Eco", 
        color = Color3.fromRGB(0, 255, 0)
    },
    {
        id = "SecretPrototypeShell",
        name = "Secret Prototype",
        cost = {
            {type = "Scrap", amount = 2000},
            {type = "BlackCore", amount = 1}
        },
        rarity = "Secret",
        color = Color3.fromRGB(50, 50, 50)
    }
}

--------------------------------------------------------------------
-- 创建Generator UI
--------------------------------------------------------------------
local function createGeneratorUI()
    -- 主界面
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GeneratorUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui
    
    -- 主框架 (再次加大解决拥挤)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 750, 0, 550)
    mainFrame.Position = UDim2.new(0.5, -375, 0.5, -275)
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
    titleLabel.Text = "Generator"
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
    
    -- Shell选择区域 (使用ScrollingFrame)
    local shellScrollFrame = Instance.new("ScrollingFrame")
    shellScrollFrame.Size = UDim2.new(1, 0, 0.75, 0)
    shellScrollFrame.Position = UDim2.new(0, 0, 0, 0)
    shellScrollFrame.BackgroundColor3 = Color3.fromRGB(250, 250, 250)
    shellScrollFrame.BorderSizePixel = 1
    shellScrollFrame.BorderColor3 = Color3.fromRGB(200, 200, 200)
    shellScrollFrame.ScrollBarThickness = 6
    shellScrollFrame.Parent = contentFrame
    
    local scrollCorner = Instance.new("UICorner")
    scrollCorner.CornerRadius = UDim.new(0, 5)
    scrollCorner.Parent = shellScrollFrame
    
    -- 网格布局 (在ScrollingFrame内，更大卡片)
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 220, 0, 240)  -- 更大的卡片尺寸
    gridLayout.CellPadding = UDim2.new(0, 15, 0, 15)  -- 更大间距
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = shellScrollFrame
    
    -- 操作区域 (底部)
    local actionFrame = Instance.new("Frame")
    actionFrame.Size = UDim2.new(1, 0, 0.2, -20)
    actionFrame.Position = UDim2.new(0, 0, 0.8, 10)
    actionFrame.BackgroundColor3 = Color3.fromRGB(250, 250, 250)
    actionFrame.BorderSizePixel = 1
    actionFrame.BorderColor3 = Color3.fromRGB(200, 200, 200)
    actionFrame.Parent = contentFrame
    
    local actionCorner = Instance.new("UICorner")
    actionCorner.CornerRadius = UDim.new(0, 5)
    actionCorner.Parent = actionFrame
    
    -- 选中Shell信息
    local selectedInfoLabel = Instance.new("TextLabel")
    selectedInfoLabel.Size = UDim2.new(0.5, -10, 0.5, 0)
    selectedInfoLabel.Position = UDim2.new(0, 10, 0, 5)
    selectedInfoLabel.BackgroundTransparency = 1
    selectedInfoLabel.Text = "Select a shell to generate"
    selectedInfoLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
    selectedInfoLabel.TextScaled = true
    selectedInfoLabel.Font = Enum.Font.Gotham
    selectedInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
    selectedInfoLabel.Parent = actionFrame
    
    -- 数量输入
    local quantityContainer = Instance.new("Frame")
    quantityContainer.Size = UDim2.new(0.15, 0, 0.6, 0)
    quantityContainer.Position = UDim2.new(0.5, 10, 0.2, 0)
    quantityContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    quantityContainer.BorderSizePixel = 1
    quantityContainer.BorderColor3 = Color3.fromRGB(200, 200, 200)
    quantityContainer.Parent = actionFrame
    
    local qtyCorner = Instance.new("UICorner")
    qtyCorner.CornerRadius = UDim.new(0, 3)
    qtyCorner.Parent = quantityContainer
    
    local quantityInput = Instance.new("TextBox")
    quantityInput.Size = UDim2.new(1, -10, 1, -5)
    quantityInput.Position = UDim2.new(0, 5, 0, 2)
    quantityInput.BackgroundTransparency = 1
    quantityInput.Text = "1"
    quantityInput.PlaceholderText = "Qty"
    quantityInput.TextColor3 = Color3.fromRGB(60, 60, 60)
    quantityInput.TextScaled = true
    quantityInput.Font = Enum.Font.Gotham
    quantityInput.Parent = quantityContainer
    
    -- Generate按钮
    local generateButton = Instance.new("TextButton")
    generateButton.Size = UDim2.new(0.25, -10, 0.6, 0)
    generateButton.Position = UDim2.new(0.7, 10, 0.2, 0)
    generateButton.BackgroundColor3 = Color3.fromRGB(100, 180, 100)
    generateButton.Text = "Generate"
    generateButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    generateButton.TextScaled = true
    generateButton.Font = Enum.Font.GothamBold
    generateButton.BorderSizePixel = 0
    generateButton.Active = true
    generateButton.Parent = actionFrame
    
    local generateCorner = Instance.new("UICorner")
    generateCorner.CornerRadius = UDim.new(0, 5)
    generateCorner.Parent = generateButton
    
    -- 升级信息
    local upgradeInfoLabel = Instance.new("TextLabel")
    upgradeInfoLabel.Size = UDim2.new(0.6, 0, 0.4, 0)
    upgradeInfoLabel.Position = UDim2.new(0, 10, 0.55, 0)
    upgradeInfoLabel.BackgroundTransparency = 1
    upgradeInfoLabel.Text = "Generator Lv.1 → Lv.2 (Speed: 1 → 2)"
    upgradeInfoLabel.TextColor3 = Color3.fromRGB(80, 80, 80)
    upgradeInfoLabel.TextScaled = true
    upgradeInfoLabel.Font = Enum.Font.Gotham
    upgradeInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
    upgradeInfoLabel.Parent = actionFrame
    
    -- 升级按钮
    local upgradeButton = Instance.new("TextButton")
    upgradeButton.Size = UDim2.new(0.25, -10, 0.35, 0)
    upgradeButton.Position = UDim2.new(0.7, 10, 0.6, 0)
    upgradeButton.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    upgradeButton.Text = "Upgrade (500¢)"
    upgradeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    upgradeButton.TextScaled = true
    upgradeButton.Font = Enum.Font.GothamBold
    upgradeButton.BorderSizePixel = 0
    upgradeButton.Active = true
    upgradeButton.Parent = actionFrame
    
    local upgradeCorner = Instance.new("UICorner")
    upgradeCorner.CornerRadius = UDim.new(0, 5)
    upgradeCorner.Parent = upgradeButton
    
    return screenGui, mainFrame, closeButton, shellScrollFrame, selectedInfoLabel, quantityInput, 
           generateButton, upgradeInfoLabel, upgradeButton
end

--------------------------------------------------------------------
-- 创建Shell卡片
--------------------------------------------------------------------
local function createShellCard(shellInfo, parent)
    local cardFrame = Instance.new("TextButton")
    cardFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    cardFrame.BorderSizePixel = 2
    cardFrame.BorderColor3 = Color3.fromRGB(220, 220, 220)
    cardFrame.Parent = parent
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = cardFrame
    
    -- Shell图标 (使用IconUtils，更大图标)
    local iconLabel = Instance.new("ImageLabel")
    iconLabel.Size = UDim2.new(0, 60, 0, 60)
    iconLabel.Position = UDim2.new(0.5, -30, 0, 15)
    iconLabel.BackgroundColor3 = shellInfo.color
    iconLabel.Image = IconUtils.getItemIcon(shellInfo.id)
    iconLabel.ScaleType = Enum.ScaleType.Fit
    iconLabel.BorderSizePixel = 0
    iconLabel.Parent = cardFrame
    
    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 20)
    iconCorner.Parent = iconLabel
    
    -- Shell名称 (调整位置和大小)
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -10, 0, 35)
    nameLabel.Position = UDim2.new(0, 5, 0, 80)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = shellInfo.name
    nameLabel.TextColor3 = Color3.fromRGB(60, 60, 60)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = cardFrame
    
    -- 材料需求 (调整位置和大小)
    local costFrame = Instance.new("Frame")
    costFrame.Size = UDim2.new(1, -10, 1, -120)
    costFrame.Position = UDim2.new(0, 5, 0, 120)
    costFrame.BackgroundTransparency = 1
    costFrame.Parent = cardFrame
    
    local costLayout = Instance.new("UIListLayout")
    costLayout.Padding = UDim.new(0, 2)
    costLayout.SortOrder = Enum.SortOrder.LayoutOrder
    costLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    costLayout.Parent = costFrame
    
    -- 创建材料需求标签 (更大字体和间距)
    for i, cost in ipairs(shellInfo.cost) do
        local costLabel = Instance.new("TextLabel")
        costLabel.Size = UDim2.new(1, 0, 0, 25)
        costLabel.BackgroundTransparency = 1
        costLabel.Text = string.format("%s×%d", cost.type, cost.amount)
        costLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
        costLabel.TextScaled = true
        costLabel.Font = Enum.Font.Gotham
        costLabel.LayoutOrder = i
        costLabel.Parent = costFrame
    end
    
    return cardFrame
end

--------------------------------------------------------------------
-- 主UI控制
--------------------------------------------------------------------
local generatorUI = nil
local currentGenerator = nil
local selectedShell = nil

-- 显示Generator UI
local function showGeneratorUI(generatorModel)
    if not generatorUI then
        local ui, mainFrame, closeButton, shellScrollFrame, selectedInfoLabel, quantityInput, 
              generateButton, upgradeInfoLabel, upgradeButton = createGeneratorUI()
        
        generatorUI = {
            gui = ui,
            mainFrame = mainFrame,
            closeButton = closeButton,
            shellScrollFrame = shellScrollFrame,  -- 更改为shellScrollFrame
            selectedInfoLabel = selectedInfoLabel,
            quantityInput = quantityInput,
            generateButton = generateButton,
            upgradeInfoLabel = upgradeInfoLabel,
            upgradeButton = upgradeButton,
            shellCards = {}
        }
        
        -- 创建Shell卡片
        for i, shellInfo in ipairs(SHELL_INFO) do
            local card = createShellCard(shellInfo, shellScrollFrame)  -- 使用shellScrollFrame
            card.LayoutOrder = i
            generatorUI.shellCards[shellInfo.id] = card
            
            card.MouseButton1Click:Connect(function()
                selectShell(shellInfo)
                
                -- 视觉反馈
                for _, otherCard in pairs(generatorUI.shellCards) do
                    otherCard.BorderColor3 = Color3.fromRGB(220, 220, 220)
                    otherCard.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                end
                card.BorderColor3 = Color3.fromRGB(100, 180, 255)
                card.BackgroundColor3 = Color3.fromRGB(240, 250, 255)
            end)
        end
        
        -- 设置ScrollingFrame的Canvas大小
        local cardCount = #SHELL_INFO
        local columns = 3  -- 每行3个
        local rows = math.ceil(cardCount / columns)
        shellScrollFrame.CanvasSize = UDim2.new(0, 0, 0, rows * (240 + 15) + 15)
        
        -- 关闭按钮事件
        closeButton.MouseButton1Click:Connect(function()
            hideGeneratorUI()
        end)
        
        -- Generate按钮事件
        generateButton.MouseButton1Click:Connect(function()
            performGenerate()
        end)
        
        -- 升级按钮事件
        upgradeButton.MouseButton1Click:Connect(function()
            performUpgrade()
        end)
    end
    
    currentGenerator = generatorModel
    
    -- 添加GenerateShellEvent响应处理
    if not generatorUI.eventConnection then
        generatorUI.eventConnection = generateShellEvent.OnClientEvent:Connect(function(ok, msg)
            if generatorUI and generatorUI.selectedInfoLabel then
                generatorUI.selectedInfoLabel.Text = msg or (ok and "Generation completed!" or "Generation failed!")
                generatorUI.selectedInfoLabel.TextColor3 = ok and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(200, 50, 50)
                
                if ok then
                    -- 成功后更新UI
                    updateGeneratorUI()
                end
            end
        end)
    end
    
    updateGeneratorUI()
    
    -- 显示动画
    generatorUI.mainFrame.Visible = true
    generatorUI.mainFrame.Size = UDim2.new(0, 0, 0, 0)
    generatorUI.mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    local tween = TweenService:Create(generatorUI.mainFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0, 750, 0, 550),
            Position = UDim2.new(0.5, -375, 0.5, -275)
        }
    )
    tween:Play()
end

-- 隐藏Generator UI
function hideGeneratorUI()
    if not generatorUI then return end
    
    local tween = TweenService:Create(generatorUI.mainFrame,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }
    )
    tween:Play()
    
    tween.Completed:Connect(function()
        generatorUI.mainFrame.Visible = false
        currentGenerator = nil
        selectedShell = nil
    end)
end

-- 选择Shell
function selectShell(shellInfo)
    selectedShell = shellInfo
    
    -- 构建材料需求文本
    local costText = ""
    for i, cost in ipairs(shellInfo.cost) do
        if i > 1 then costText = costText .. " + " end
        costText = costText .. cost.type .. "×" .. cost.amount
    end
    
    generatorUI.selectedInfoLabel.Text = string.format("Selected: %s (Cost: %s)", 
        shellInfo.name, costText)
end

-- 更新Generator UI信息
function updateGeneratorUI()
    if not generatorUI or not currentGenerator then return end
    
    local playerData = getDataRF:InvokeServer()
    local upgradeInfo = getUpgradeInfoRF:InvokeServer("Generator")
    
    if playerData and upgradeInfo then
        local credits = playerData.Credits or 0
        local level = upgradeInfo.level or 1
        local speed = upgradeInfo.speed or 1
        local nextSpeed = upgradeInfo.nextSpeed or speed
        
        -- 更新升级信息
        if nextSpeed > speed then
            generatorUI.upgradeInfoLabel.Text = string.format("Generator Lv.%d → Lv.%d (Speed: %d → %d)", 
                level, level + 1, speed, nextSpeed)
            
            local upgradeCost = level * 500
            generatorUI.upgradeButton.Text = string.format("Upgrade (%d¢)", upgradeCost)
            
            if credits >= upgradeCost then
                generatorUI.upgradeButton.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
            else
                generatorUI.upgradeButton.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
                generatorUI.upgradeButton.Text = "Need Credits"
            end
        else
            generatorUI.upgradeInfoLabel.Text = string.format("Max Level! (Lv.%d Speed: %d)", level, speed)
            generatorUI.upgradeButton.Text = "Max Level"
            generatorUI.upgradeButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        end
    end
end

-- 执行Generate操作 (参考原始代码)
function performGenerate()
    if not generatorUI or not currentGenerator or not selectedShell then
        generatorUI.selectedInfoLabel.Text = "Please select a shell first!"
        generatorUI.selectedInfoLabel.TextColor3 = Color3.fromRGB(200, 50, 50)
        task.wait(1)
        generatorUI.selectedInfoLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
        return
    end
    
    local inputText = generatorUI.quantityInput.Text
    local quantity = tonumber(inputText)
    
    if not quantity or quantity <= 0 then
        generatorUI.quantityInput.TextColor3 = Color3.fromRGB(200, 50, 50)
        task.wait(0.5)
        generatorUI.quantityInput.TextColor3 = Color3.fromRGB(60, 60, 60)
        return
    end
    
    -- 显示处理状态
    generatorUI.selectedInfoLabel.Text = "Processing..."
    generatorUI.selectedInfoLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
    
    -- 发送生成请求 (使用GenerateShellEvent)
    generateShellEvent:FireServer(selectedShell.id, quantity)
    
    -- 通知教程系统生成器交互完成
    if tutorialEvent then
        tutorialEvent:FireServer("STEP_COMPLETED", "OPEN_GENERATOR", {
            machineType = "Generator",
            shellType = selectedShell.id
        })
    end
    
    -- 重置输入
    generatorUI.quantityInput.Text = "1"
end

-- 执行升级操作
function performUpgrade()
    if not generatorUI or not currentGenerator then return end
    
    local playerData = getDataRF:InvokeServer()
    local upgradeInfo = getUpgradeInfoRF:InvokeServer("Generator")
    
    if not playerData or not upgradeInfo then return end
    
    local credits = playerData.Credits or 0
    local level = upgradeInfo.level or 1
    local nextSpeed = upgradeInfo.nextSpeed or upgradeInfo.speed
    
    if nextSpeed <= (upgradeInfo.speed or 1) then
        return
    end
    
    local upgradeCost = level * 500
    if credits < upgradeCost then
        generatorUI.upgradeButton.Text = "Not Enough!"
        generatorUI.upgradeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        task.wait(1)
        updateGeneratorUI()
        return
    end
    
    upgradeMachineEvent:FireServer("Generator")
    
    generatorUI.upgradeButton.Text = "Upgrading..."
    generatorUI.upgradeButton.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
    
    task.wait(0.5)
    updateGeneratorUI()
end

--------------------------------------------------------------------
-- Generator交互设置
--------------------------------------------------------------------
local function setupGeneratorInteractions()
    for _, obj in pairs(workspace:GetChildren()) do
        if obj:IsA("Model") and obj.Name:lower():find("generator") then
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
                    prompt.ObjectText = "Generator"
                    prompt.ActionText = "打开"
                    prompt.HoldDuration = 0.5
                    prompt.MaxActivationDistance = 10
                    prompt.RequiresLineOfSight = false
                    prompt.Parent = targetPart
                    
                    prompt.Triggered:Connect(function(triggerPlayer)
                        if triggerPlayer == player then
                            showGeneratorUI(obj)
                        end
                    end)
                    
                    print("[GeneratorUI] 为Generator添加ProximityPrompt:", obj.Name)
                end
            end
        end
    end
end

workspace.ChildAdded:Connect(function(child)
    if child:IsA("Model") and child.Name:lower():find("generator") then
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
            prompt.ObjectText = "Generator"
            prompt.ActionText = "打开"
            prompt.HoldDuration = 0.5
            prompt.MaxActivationDistance = 10
            prompt.RequiresLineOfSight = false
            prompt.Parent = targetPart
            
            prompt.Triggered:Connect(function(triggerPlayer)
                if triggerPlayer == player then
                    showGeneratorUI(child)
                end
            end)
            
            print("[GeneratorUI] 为新Generator添加ProximityPrompt:", child.Name)
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end
    
    if input.KeyCode == Enum.KeyCode.E and generatorUI and generatorUI.mainFrame.Visible then
        hideGeneratorUI()
    end
end)

task.spawn(function()
    while true do
        task.wait(2)
        if generatorUI and generatorUI.mainFrame.Visible then
            updateGeneratorUI()
        end
    end
end)

setupGeneratorInteractions()

print("[GeneratorUI] Generator UI系统已加载")