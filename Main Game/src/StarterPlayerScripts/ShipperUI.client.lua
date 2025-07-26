--------------------------------------------------------------------
-- ShipperUI.client.lua · Shipper机器交互界面
-- 功能：
--   1) 显示玩家拥有的机器人
--   2) 选择要出售的机器人类型和数量
--   3) 显示可获得的Credits
--   4) 执行出售操作
--   5) 包含升级功能
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
local getInventoryRF = rfFolder:WaitForChild("GetInventoryFunction")

local reFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local shipBotEvent = reFolder:WaitForChild("ShipBotEvent")
local upgradeMachineEvent = reFolder:WaitForChild("UpgradeMachineEvent")

-- 加载配置
local GameConstants = require(ReplicatedStorage.SharedModules.GameConstants.main)
local BOT_SELL_PRICE = GameConstants.BOT_SELL_PRICE

--------------------------------------------------------------------
-- 创建Shipper UI
--------------------------------------------------------------------
local function createShipperUI()
    -- 主界面
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ShipperUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui
    
    -- 主框架
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 500, 0, 450)
    mainFrame.Position = UDim2.new(0.5, -250, 0.5, -225)
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
    titleLabel.Text = "Shipper"
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
    
    -- 左侧：机器人展示区域
    local robotDisplayFrame = Instance.new("Frame")
    robotDisplayFrame.Size = UDim2.new(0.6, -10, 0.7, 0)
    robotDisplayFrame.Position = UDim2.new(0, 0, 0, 0)
    robotDisplayFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    robotDisplayFrame.BorderSizePixel = 2
    robotDisplayFrame.BorderColor3 = Color3.fromRGB(200, 200, 200)
    robotDisplayFrame.Parent = contentFrame
    
    local displayCorner = Instance.new("UICorner")
    displayCorner.CornerRadius = UDim.new(0, 5)
    displayCorner.Parent = robotDisplayFrame
    
    -- 机器人图标（占位）
    local robotIconLabel = Instance.new("TextLabel")
    robotIconLabel.Size = UDim2.new(0, 80, 0, 80)
    robotIconLabel.Position = UDim2.new(0.5, -40, 0.5, -40)
    robotIconLabel.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
    robotIconLabel.Text = "🤖"
    robotIconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    robotIconLabel.TextScaled = true
    robotIconLabel.Font = Enum.Font.GothamBold
    robotIconLabel.BorderSizePixel = 0
    robotIconLabel.Parent = robotDisplayFrame
    
    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 8)
    iconCorner.Parent = robotIconLabel
    
    -- 机器人信息
    local robotInfoLabel = Instance.new("TextLabel")
    robotInfoLabel.Size = UDim2.new(1, -20, 0, 30)
    robotInfoLabel.Position = UDim2.new(0, 10, 1, -40)
    robotInfoLabel.BackgroundTransparency = 1
    robotInfoLabel.Text = "Select a robot to ship"
    robotInfoLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
    robotInfoLabel.TextScaled = true
    robotInfoLabel.Font = Enum.Font.Gotham
    robotInfoLabel.Parent = robotDisplayFrame
    
    -- 右侧：控制区域
    local controlFrame = Instance.new("Frame")
    controlFrame.Size = UDim2.new(0.4, -10, 0.7, 0)
    controlFrame.Position = UDim2.new(0.6, 10, 0, 0)
    controlFrame.BackgroundTransparency = 1
    controlFrame.Parent = contentFrame
    
    -- 数量输入框
    local amountContainer = Instance.new("Frame")
    amountContainer.Size = UDim2.new(1, 0, 0, 50)
    amountContainer.Position = UDim2.new(0, 0, 0, 20)
    amountContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    amountContainer.BorderSizePixel = 1
    amountContainer.BorderColor3 = Color3.fromRGB(200, 200, 200)
    amountContainer.Parent = controlFrame
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 5)
    inputCorner.Parent = amountContainer
    
    local amountInput = Instance.new("TextBox")
    amountInput.Size = UDim2.new(1, -20, 1, -10)
    amountInput.Position = UDim2.new(0, 10, 0, 5)
    amountInput.BackgroundTransparency = 1
    amountInput.Text = "1"
    amountInput.PlaceholderText = "Amount..."
    amountInput.TextColor3 = Color3.fromRGB(60, 60, 60)
    amountInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    amountInput.TextScaled = true
    amountInput.Font = Enum.Font.Gotham
    amountInput.ClearTextOnFocus = false
    amountInput.Parent = amountContainer
    
    -- Credits显示
    local creditsLabel = Instance.new("TextLabel")
    creditsLabel.Size = UDim2.new(1, 0, 0, 40)
    creditsLabel.Position = UDim2.new(0, 0, 0, 90)
    creditsLabel.BackgroundTransparency = 1
    creditsLabel.Text = "Credits +0"
    creditsLabel.TextColor3 = Color3.fromRGB(60, 60, 60)
    creditsLabel.TextScaled = true
    creditsLabel.Font = Enum.Font.GothamSemibold
    creditsLabel.Parent = controlFrame
    
    -- Ship按钮
    local shipButton = Instance.new("TextButton")
    shipButton.Size = UDim2.new(1, 0, 0, 45)
    shipButton.Position = UDim2.new(0, 0, 0, 150)
    shipButton.BackgroundColor3 = Color3.fromRGB(100, 180, 100)
    shipButton.Text = "Ship"
    shipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    shipButton.TextScaled = true
    shipButton.Font = Enum.Font.GothamBold
    shipButton.BorderSizePixel = 0
    shipButton.Active = true
    shipButton.Parent = controlFrame
    
    local shipCorner = Instance.new("UICorner")
    shipCorner.CornerRadius = UDim.new(0, 8)
    shipCorner.Parent = shipButton
    
    -- 机器人选择滚动列表
    local robotListFrame = Instance.new("ScrollingFrame")
    robotListFrame.Size = UDim2.new(1, 0, 0.25, -10)
    robotListFrame.Position = UDim2.new(0, 0, 0.75, 10)
    robotListFrame.BackgroundColor3 = Color3.fromRGB(250, 250, 250)
    robotListFrame.BorderSizePixel = 1
    robotListFrame.BorderColor3 = Color3.fromRGB(200, 200, 200)
    robotListFrame.ScrollBarThickness = 6
    robotListFrame.Parent = contentFrame
    
    local listCorner = Instance.new("UICorner")
    listCorner.CornerRadius = UDim.new(0, 5)
    listCorner.Parent = robotListFrame
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 2)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = robotListFrame
    
    -- 升级区域（底部）
    local separator = Instance.new("Frame")
    separator.Size = UDim2.new(0.9, 0, 0, 2)
    separator.Position = UDim2.new(0.05, 0, 0.85, 0)
    separator.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    separator.BorderSizePixel = 0
    separator.Parent = contentFrame
    
    local upgradeInfoLabel = Instance.new("TextLabel")
    upgradeInfoLabel.Size = UDim2.new(0.6, 0, 0, 25)
    upgradeInfoLabel.Position = UDim2.new(0, 0, 0.88, 0)
    upgradeInfoLabel.BackgroundTransparency = 1
    upgradeInfoLabel.Text = "Current: Lv.1 → Next: Lv.2 (Speed: 1 → 3)"
    upgradeInfoLabel.TextColor3 = Color3.fromRGB(60, 60, 60)
    upgradeInfoLabel.TextScaled = true
    upgradeInfoLabel.Font = Enum.Font.Gotham
    upgradeInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
    upgradeInfoLabel.Parent = contentFrame
    
    local upgradeCostLabel = Instance.new("TextLabel")
    upgradeCostLabel.Size = UDim2.new(0.4, 0, 0, 20)
    upgradeCostLabel.Position = UDim2.new(0.6, 0, 0.88, 5)
    upgradeCostLabel.BackgroundTransparency = 1
    upgradeCostLabel.Text = "Cost: 500 Credits"
    upgradeCostLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
    upgradeCostLabel.TextScaled = true
    upgradeCostLabel.Font = Enum.Font.Gotham
    upgradeCostLabel.TextXAlignment = Enum.TextXAlignment.Right
    upgradeCostLabel.Parent = contentFrame
    
    local upgradeButton = Instance.new("TextButton")
    upgradeButton.Size = UDim2.new(0.3, 0, 0, 35)
    upgradeButton.Position = UDim2.new(0.7, 0, 0.91, 5)
    upgradeButton.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    upgradeButton.Text = "Upgrade"
    upgradeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    upgradeButton.TextScaled = true
    upgradeButton.Font = Enum.Font.GothamBold
    upgradeButton.BorderSizePixel = 0
    upgradeButton.Active = true
    upgradeButton.Parent = contentFrame
    
    local upgradeCorner = Instance.new("UICorner")
    upgradeCorner.CornerRadius = UDim.new(0, 5)
    upgradeCorner.Parent = upgradeButton
    
    return screenGui, mainFrame, closeButton, robotDisplayFrame, robotIconLabel, robotInfoLabel, 
           amountInput, creditsLabel, shipButton, robotListFrame, listLayout,
           upgradeInfoLabel, upgradeCostLabel, upgradeButton
end

--------------------------------------------------------------------
-- 创建机器人选择按钮
--------------------------------------------------------------------
local function createRobotButton(botId, quantity, price, parent, layoutOrder)
    local buttonFrame = Instance.new("TextButton")
    buttonFrame.Size = UDim2.new(1, -10, 0, 30)
    buttonFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    buttonFrame.BorderSizePixel = 1
    buttonFrame.BorderColor3 = Color3.fromRGB(200, 200, 200)
    buttonFrame.LayoutOrder = layoutOrder
    buttonFrame.Parent = parent
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 3)
    buttonCorner.Parent = buttonFrame
    
    -- 显示完整名称以区分Dig/Build
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.5, 0, 1, 0)
    nameLabel.Position = UDim2.new(0, 5, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = botId  -- 保留完整名称
    nameLabel.TextColor3 = Color3.fromRGB(60, 60, 60)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = buttonFrame
    
    local quantityLabel = Instance.new("TextLabel")
    quantityLabel.Size = UDim2.new(0.25, 0, 1, 0)
    quantityLabel.Position = UDim2.new(0.5, 0, 0, 0)
    quantityLabel.BackgroundTransparency = 1
    quantityLabel.Text = "×" .. quantity
    quantityLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
    quantityLabel.TextScaled = true
    quantityLabel.Font = Enum.Font.Gotham
    quantityLabel.Parent = buttonFrame
    
    local priceLabel = Instance.new("TextLabel")
    priceLabel.Size = UDim2.new(0.25, 0, 1, 0)
    priceLabel.Position = UDim2.new(0.75, 0, 0, 0)
    priceLabel.BackgroundTransparency = 1
    priceLabel.Text = price .. "¢"
    priceLabel.TextColor3 = Color3.fromRGB(0, 150, 0)
    priceLabel.TextScaled = true
    priceLabel.Font = Enum.Font.GothamSemibold
    priceLabel.TextXAlignment = Enum.TextXAlignment.Right
    priceLabel.Parent = buttonFrame
    
    return buttonFrame
end

--------------------------------------------------------------------
-- 主UI控制
--------------------------------------------------------------------
local shipperUI = nil
local currentShipper = nil
local selectedBotId = nil
local selectedBotPrice = 0

-- 显示Shipper UI
local function showShipperUI(shipperModel)
    if not shipperUI then
        local ui, mainFrame, closeButton, robotDisplayFrame, robotIconLabel, robotInfoLabel, 
              amountInput, creditsLabel, shipButton, robotListFrame, listLayout,
              upgradeInfoLabel, upgradeCostLabel, upgradeButton = createShipperUI()
        
        shipperUI = {
            gui = ui,
            mainFrame = mainFrame,
            closeButton = closeButton,
            robotDisplayFrame = robotDisplayFrame,
            robotIconLabel = robotIconLabel,
            robotInfoLabel = robotInfoLabel,
            amountInput = amountInput,
            creditsLabel = creditsLabel,
            shipButton = shipButton,
            robotListFrame = robotListFrame,
            listLayout = listLayout,
            upgradeInfoLabel = upgradeInfoLabel,
            upgradeCostLabel = upgradeCostLabel,
            upgradeButton = upgradeButton
        }
        
        -- 关闭按钮事件
        closeButton.MouseButton1Click:Connect(function()
            hideShipperUI()
        end)
        
        -- 输入框变化事件
        amountInput:GetPropertyChangedSignal("Text"):Connect(function()
            updateCreditsDisplay()
        end)
        
        -- Ship按钮事件
        shipButton.MouseButton1Click:Connect(function()
            performShip()
        end)
        
        -- 升级按钮事件
        upgradeButton.MouseButton1Click:Connect(function()
            performUpgrade()
        end)
    end
    
    currentShipper = shipperModel
    updateShipperUI()
    
    -- 显示动画
    shipperUI.mainFrame.Visible = true
    shipperUI.mainFrame.Size = UDim2.new(0, 0, 0, 0)
    shipperUI.mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    local tween = TweenService:Create(shipperUI.mainFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0, 500, 0, 450),
            Position = UDim2.new(0.5, -250, 0.5, -225)
        }
    )
    tween:Play()
end

-- 隐藏Shipper UI
function hideShipperUI()
    if not shipperUI then return end
    
    local tween = TweenService:Create(shipperUI.mainFrame,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }
    )
    tween:Play()
    
    tween.Completed:Connect(function()
        shipperUI.mainFrame.Visible = false
        currentShipper = nil
        selectedBotId = nil
        selectedBotPrice = 0
    end)
end

-- 更新Shipper UI信息
function updateShipperUI()
    if not shipperUI or not currentShipper then return end
    
    -- 获取玩家数据和升级信息
    local playerData = getDataRF:InvokeServer()
    local upgradeInfo = getUpgradeInfoRF:InvokeServer("Shipper")
    local inventory = getInventoryRF:InvokeServer()
    
    if playerData and upgradeInfo and inventory then
        local credits = playerData.Credits or 0
        local level = upgradeInfo.level or 1
        local speed = upgradeInfo.speed or 1
        local nextSpeed = upgradeInfo.nextSpeed or speed
        
        -- 更新升级信息
        if nextSpeed > speed then
            shipperUI.upgradeInfoLabel.Text = string.format("Current: Lv.%d → Next: Lv.%d (Speed: %d → %d)", 
                level, level + 1, speed, nextSpeed)
            
            local upgradeCost = level * 500
            shipperUI.upgradeCostLabel.Text = string.format("Cost: %d Credits", upgradeCost)
            
            if credits >= upgradeCost then
                shipperUI.upgradeButton.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
                shipperUI.upgradeButton.Text = "Upgrade"
                shipperUI.upgradeCostLabel.TextColor3 = Color3.fromRGB(0, 150, 0)
            else
                shipperUI.upgradeButton.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
                shipperUI.upgradeButton.Text = "Need Credits"
                shipperUI.upgradeCostLabel.TextColor3 = Color3.fromRGB(200, 50, 50)
            end
        else
            shipperUI.upgradeInfoLabel.Text = string.format("Max Level! (Lv.%d Speed: %d)", level, speed)
            shipperUI.upgradeCostLabel.Text = "Max Level"
            shipperUI.upgradeButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            shipperUI.upgradeButton.Text = "Max Level"
            shipperUI.upgradeCostLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
        end
        
        -- 清除旧的机器人列表
        for _, child in pairs(shipperUI.robotListFrame:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        -- 创建机器人列表（过滤数量为0的机器人）
        local robotCount = 0
        for _, item in pairs(inventory) do
            if BOT_SELL_PRICE[item.itemId] and item.quantity > 0 then
                robotCount = robotCount + 1
                local button = createRobotButton(item.itemId, item.quantity, BOT_SELL_PRICE[item.itemId], 
                                               shipperUI.robotListFrame, robotCount)
                
                -- 点击选择机器人
                button.MouseButton1Click:Connect(function()
                    selectRobot(item.itemId, BOT_SELL_PRICE[item.itemId])
                    
                    -- 视觉反馈
                    for _, child in pairs(shipperUI.robotListFrame:GetChildren()) do
                        if child:IsA("TextButton") then
                            child.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        end
                    end
                    button.BackgroundColor3 = Color3.fromRGB(200, 255, 200)
                end)
            end
        end
        
        -- 更新滚动区域大小
        shipperUI.robotListFrame.CanvasSize = UDim2.new(0, 0, 0, robotCount * 32)
        
        updateCreditsDisplay()
    end
end

-- 选择机器人
function selectRobot(botId, price)
    selectedBotId = botId
    selectedBotPrice = price
    
    -- 更新显示区域（显示完整名称）
    shipperUI.robotInfoLabel.Text = botId .. " - " .. price .. " Credits each"
    shipperUI.robotIconLabel.Text = "🤖"
    
    updateCreditsDisplay()
end

-- 更新Credits显示
function updateCreditsDisplay()
    if not shipperUI then return end
    
    local inputText = shipperUI.amountInput.Text
    local amount = tonumber(inputText) or 0
    
    if amount > 0 and selectedBotId then
        local credits = amount * selectedBotPrice
        shipperUI.creditsLabel.Text = string.format("Credits +%d", credits)
        shipperUI.creditsLabel.TextColor3 = Color3.fromRGB(0, 150, 0)
    else
        shipperUI.creditsLabel.Text = "Credits +0"
        shipperUI.creditsLabel.TextColor3 = Color3.fromRGB(60, 60, 60)
    end
end

-- 执行Ship操作
function performShip()
    if not shipperUI or not currentShipper or not selectedBotId then
        shipperUI.robotInfoLabel.Text = "Please select a robot first!"
        shipperUI.robotInfoLabel.TextColor3 = Color3.fromRGB(200, 50, 50)
        task.wait(1)
        shipperUI.robotInfoLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
        return
    end
    
    local inputText = shipperUI.amountInput.Text
    local amount = tonumber(inputText)
    
    if not amount or amount <= 0 then
        shipperUI.amountInput.TextColor3 = Color3.fromRGB(200, 50, 50)
        task.wait(0.5)
        shipperUI.amountInput.TextColor3 = Color3.fromRGB(60, 60, 60)
        return
    end
    
    -- 发送出售请求
    shipBotEvent:FireServer(selectedBotId, amount)
    
    -- 立即显示反馈
    shipperUI.shipButton.Text = "Shipping..."
    shipperUI.shipButton.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
    
    -- 清空输入框
    shipperUI.amountInput.Text = "1"
    
    -- 等待0.5秒后更新UI（确保服务器处理完成）
    task.wait(0.5)
    shipperUI.shipButton.Text = "Ship"
    shipperUI.shipButton.BackgroundColor3 = Color3.fromRGB(100, 180, 100)
    
    -- 更新UI
    updateShipperUI()
end

-- 执行升级操作
function performUpgrade()
    if not shipperUI or not currentShipper then return end
    
    local playerData = getDataRF:InvokeServer()
    local upgradeInfo = getUpgradeInfoRF:InvokeServer("Shipper")
    
    if not playerData or not upgradeInfo then return end
    
    local credits = playerData.Credits or 0
    local level = upgradeInfo.level or 1
    local nextSpeed = upgradeInfo.nextSpeed or upgradeInfo.speed
    
    if nextSpeed <= (upgradeInfo.speed or 1) then
        shipperUI.upgradeInfoLabel.TextColor3 = Color3.fromRGB(200, 50, 50)
        task.wait(1)
        shipperUI.upgradeInfoLabel.TextColor3 = Color3.fromRGB(60, 60, 60)
        return
    end
    
    local upgradeCost = level * 500
    if credits < upgradeCost then
        shipperUI.upgradeCostLabel.TextColor3 = Color3.fromRGB(200, 50, 50)
        shipperUI.upgradeButton.Text = "Not Enough!"
        task.wait(1)
        shipperUI.upgradeCostLabel.TextColor3 = Color3.fromRGB(200, 50, 50)
        shipperUI.upgradeButton.Text = "Need Credits"
        return
    end
    
    upgradeMachineEvent:FireServer("Shipper")
    
    shipperUI.upgradeButton.Text = "Upgrading..."
    shipperUI.upgradeButton.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
    
    task.wait(0.5)
    updateShipperUI()
end

--------------------------------------------------------------------
-- Shipper交互设置
--------------------------------------------------------------------
local function setupShipperInteractions()
    for _, obj in pairs(workspace:GetChildren()) do
        if obj:IsA("Model") and obj.Name:lower():find("shipper") then
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
                    prompt.ObjectText = "Shipper"
                    prompt.ActionText = "打开"
                    prompt.HoldDuration = 0.5
                    prompt.MaxActivationDistance = 10
                    prompt.RequiresLineOfSight = false
                    prompt.Parent = targetPart
                    
                    prompt.Triggered:Connect(function(triggerPlayer)
                        if triggerPlayer == player then
                            showShipperUI(obj)
                        end
                    end)
                    
                    print("[ShipperUI] 为Shipper添加ProximityPrompt:", obj.Name)
                end
            end
        end
    end
end

workspace.ChildAdded:Connect(function(child)
    if child:IsA("Model") and child.Name:lower():find("shipper") then
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
            prompt.ObjectText = "Shipper"
            prompt.ActionText = "打开"
            prompt.HoldDuration = 0.5
            prompt.MaxActivationDistance = 10
            prompt.RequiresLineOfSight = false
            prompt.Parent = targetPart
            
            prompt.Triggered:Connect(function(triggerPlayer)
                if triggerPlayer == player then
                    showShipperUI(child)
                end
            end)
            
            print("[ShipperUI] 为新Shipper添加ProximityPrompt:", child.Name)
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end
    
    if input.KeyCode == Enum.KeyCode.E and shipperUI and shipperUI.mainFrame.Visible then
        hideShipperUI()
    end
end)

-- 更频繁的UI更新，确保实时显示库存变化
task.spawn(function()
    while true do
        task.wait(1)  -- 从2秒改为1秒
        if shipperUI and shipperUI.mainFrame.Visible then
            updateShipperUI()
        end
    end
end)

setupShipperInteractions()

print("[ShipperUI] Shipper UI系统已加载")