--------------------------------------------------------------------
-- AssemblerUI.client.lua · Assembler机器交互界面
-- 功能：
--   1) 选择Shell类型来组装机器人
--   2) 显示Shell消耗和机器人产出
--   3) 执行组装操作
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
local getInventoryRF = rfFolder:WaitForChild("GetInventoryFunction")

local reFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local assembleShellEvent = reFolder:WaitForChild("AssembleShellEvent")  -- 使用正确的事件名
local upgradeMachineEvent = reFolder:WaitForChild("UpgradeMachineEvent")

-- 加载配置和图标
local GameConstants = require(ReplicatedStorage.SharedModules.GameConstants.main)
local IconUtils = require(ReplicatedStorage.ClientUtils.IconUtils)
local RobotKey = GameConstants.RobotKey
local ShellRarity = GameConstants.ShellRarity

-- Shell到机器人映射配置
local SHELL_TO_ROBOT = {
    {
        shellId = "RustyShell",
        name = "Rusty Shell",
        rarity = "Uncommon",
        color = Color3.fromRGB(139, 69, 19),
        outputs = {
            {robotId = "Dig_UncommonBot", chance = 50},
            {robotId = "Build_UncommonBot", chance = 50}
        }
    },
    {
        shellId = "NeonCoreShell", 
        name = "Neon Core Shell",
        rarity = "Rare",
        color = Color3.fromRGB(0, 255, 255),
        outputs = {
            {robotId = "Dig_RareBot", chance = 50},
            {robotId = "Build_RareBot", chance = 50}
        }
    },
    {
        shellId = "QuantumCapsuleShell",
        name = "Quantum Capsule",
        rarity = "Epic", 
        color = Color3.fromRGB(128, 0, 128),
        outputs = {
            {robotId = "Dig_EpicBot", chance = 50},
            {robotId = "Build_EpicBot", chance = 50}
        }
    },
    {
        shellId = "EcoBoosterPodShell",
        name = "Eco Booster Pod",
        rarity = "Eco",
        color = Color3.fromRGB(0, 255, 0),
        outputs = {
            {robotId = "Dig_EcoBot", chance = 50},
            {robotId = "Build_EcoBot", chance = 50}
        }
    },
    {
        shellId = "SecretPrototypeShell",
        name = "Secret Prototype",
        rarity = "Secret",
        color = Color3.fromRGB(50, 50, 50),
        outputs = {
            {robotId = "Dig_SecretBot", chance = 50},
            {robotId = "Build_SecretBot", chance = 50}
        }
    }
}

--------------------------------------------------------------------
-- 创建Assembler UI
--------------------------------------------------------------------
local function createAssemblerUI()
    -- 主界面
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AssemblerUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui
    
    -- 主框架 (较大尺寸)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 650, 0, 500)
    mainFrame.Position = UDim2.new(0.5, -325, 0.5, -250)
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
    titleLabel.Text = "Assembler"
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
    
    -- Shell选择区域
    local shellGridFrame = Instance.new("Frame")
    shellGridFrame.Size = UDim2.new(1, 0, 0.7, 0)
    shellGridFrame.Position = UDim2.new(0, 0, 0, 0)
    shellGridFrame.BackgroundTransparency = 1
    shellGridFrame.Parent = contentFrame
    
    -- 网格布局 (5个Shell，排成一行或两行)
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0.18, 0, 0.8, 0)
    gridLayout.CellPadding = UDim2.new(0.025, 0, 0.1, 0)
    gridLayout.Parent = shellGridFrame
    
    -- 操作区域 (底部)
    local actionFrame = Instance.new("Frame")
    actionFrame.Size = UDim2.new(1, 0, 0.25, -10)
    actionFrame.Position = UDim2.new(0, 0, 0.75, 10)
    actionFrame.BackgroundColor3 = Color3.fromRGB(250, 250, 250)
    actionFrame.BorderSizePixel = 1
    actionFrame.BorderColor3 = Color3.fromRGB(200, 200, 200)
    actionFrame.Parent = contentFrame
    
    local actionCorner = Instance.new("UICorner")
    actionCorner.CornerRadius = UDim.new(0, 5)
    actionCorner.Parent = actionFrame
    
    -- 选中Shell信息
    local selectedInfoLabel = Instance.new("TextLabel")
    selectedInfoLabel.Size = UDim2.new(0.5, -10, 0.4, 0)
    selectedInfoLabel.Position = UDim2.new(0, 10, 0, 5)
    selectedInfoLabel.BackgroundTransparency = 1
    selectedInfoLabel.Text = "Select a shell to assemble"
    selectedInfoLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
    selectedInfoLabel.TextScaled = true
    selectedInfoLabel.Font = Enum.Font.Gotham
    selectedInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
    selectedInfoLabel.Parent = actionFrame
    
    -- 数量输入
    local quantityContainer = Instance.new("Frame")
    quantityContainer.Size = UDim2.new(0.15, 0, 0.35, 0)
    quantityContainer.Position = UDim2.new(0.5, 10, 0.05, 0)
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
    
    -- Assemble按钮
    local assembleButton = Instance.new("TextButton")
    assembleButton.Size = UDim2.new(0.25, -10, 0.35, 0)
    assembleButton.Position = UDim2.new(0.7, 10, 0.05, 0)
    assembleButton.BackgroundColor3 = Color3.fromRGB(100, 180, 100)
    assembleButton.Text = "Assemble"
    assembleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    assembleButton.TextScaled = true
    assembleButton.Font = Enum.Font.GothamBold
    assembleButton.BorderSizePixel = 0
    assembleButton.Active = true
    assembleButton.Parent = actionFrame
    
    local assembleCorner = Instance.new("UICorner")
    assembleCorner.CornerRadius = UDim.new(0, 5)
    assembleCorner.Parent = assembleButton
    
    -- 升级信息
    local upgradeInfoLabel = Instance.new("TextLabel")
    upgradeInfoLabel.Size = UDim2.new(0.6, 0, 0.4, 0)
    upgradeInfoLabel.Position = UDim2.new(0, 10, 0.5, 0)
    upgradeInfoLabel.BackgroundTransparency = 1
    upgradeInfoLabel.Text = "Assembler Lv.1 → Lv.2 (Speed: 1 → 2)"
    upgradeInfoLabel.TextColor3 = Color3.fromRGB(80, 80, 80)
    upgradeInfoLabel.TextScaled = true
    upgradeInfoLabel.Font = Enum.Font.Gotham
    upgradeInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
    upgradeInfoLabel.Parent = actionFrame
    
    -- 升级按钮
    local upgradeButton = Instance.new("TextButton")
    upgradeButton.Size = UDim2.new(0.25, -10, 0.4, 0)
    upgradeButton.Position = UDim2.new(0.7, 10, 0.5, 0)
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
    
    return screenGui, mainFrame, closeButton, shellGridFrame, selectedInfoLabel, quantityInput, 
           assembleButton, upgradeInfoLabel, upgradeButton
end

--------------------------------------------------------------------
-- 创建Shell卡片
--------------------------------------------------------------------
local function createShellCard(shellInfo, parent, inventory)
    local cardFrame = Instance.new("TextButton")
    cardFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    cardFrame.BorderSizePixel = 2
    cardFrame.BorderColor3 = Color3.fromRGB(220, 220, 220)
    cardFrame.Parent = parent
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = cardFrame
    
    -- Shell图标 (使用IconUtils)
    local iconLabel = Instance.new("ImageLabel")
    iconLabel.Size = UDim2.new(0, 50, 0, 50)
    iconLabel.Position = UDim2.new(0.5, -25, 0, 10)
    iconLabel.BackgroundColor3 = shellInfo.color
    iconLabel.Image = IconUtils.getItemIcon(shellInfo.shellId)
    iconLabel.ScaleType = Enum.ScaleType.Fit
    iconLabel.BorderSizePixel = 0
    iconLabel.Parent = cardFrame
    
    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 25)
    iconCorner.Parent = iconLabel
    
    -- Shell名称
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -10, 0, 25)
    nameLabel.Position = UDim2.new(0, 5, 0, 65)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = shellInfo.name
    nameLabel.TextColor3 = Color3.fromRGB(60, 60, 60)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = cardFrame
    
    -- 库存数量
    local availableCount = 0
    for _, item in pairs(inventory) do
        if item.itemId == shellInfo.shellId then
            availableCount = item.quantity
            break
        end
    end
    
    local countLabel = Instance.new("TextLabel")
    countLabel.Size = UDim2.new(1, -10, 0, 20)
    countLabel.Position = UDim2.new(0, 5, 0, 90)
    countLabel.BackgroundTransparency = 1
    countLabel.Text = string.format("Available: %d", availableCount)
    countLabel.TextColor3 = availableCount > 0 and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(200, 50, 50)
    countLabel.TextScaled = true
    countLabel.Font = Enum.Font.Gotham
    countLabel.Parent = cardFrame
    
    -- 输出机器人信息
    local outputFrame = Instance.new("Frame")
    outputFrame.Size = UDim2.new(1, -10, 1, -115)
    outputFrame.Position = UDim2.new(0, 5, 0, 115)
    outputFrame.BackgroundTransparency = 1
    outputFrame.Parent = cardFrame
    
    local outputLayout = Instance.new("UIListLayout")
    outputLayout.Padding = UDim.new(0, 2)
    outputLayout.SortOrder = Enum.SortOrder.LayoutOrder
    outputLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    outputLayout.Parent = outputFrame
    
    -- 显示输出机器人
    for i, output in ipairs(shellInfo.outputs) do
        local outputLabel = Instance.new("TextLabel")
        outputLabel.Size = UDim2.new(1, 0, 0, 15)
        outputLabel.BackgroundTransparency = 1
        outputLabel.Text = string.format("%s (%d%%)", output.robotId:gsub("_", " "), output.chance)
        outputLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
        outputLabel.TextScaled = true
        outputLabel.Font = Enum.Font.Gotham
        outputLabel.LayoutOrder = i
        outputLabel.Parent = outputFrame
    end
    
    -- 如果没有库存，使卡片变灰
    if availableCount <= 0 then
        cardFrame.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
        iconLabel.ImageTransparency = 0.5
        nameLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
    
    return cardFrame, availableCount
end

--------------------------------------------------------------------
-- 主UI控制
--------------------------------------------------------------------
local assemblerUI = nil
local currentAssembler = nil
local selectedShell = nil

-- 显示Assembler UI
local function showAssemblerUI(assemblerModel)
    if not assemblerUI then
        local ui, mainFrame, closeButton, shellGridFrame, selectedInfoLabel, quantityInput, 
              assembleButton, upgradeInfoLabel, upgradeButton = createAssemblerUI()
        
        assemblerUI = {
            gui = ui,
            mainFrame = mainFrame,
            closeButton = closeButton,
            shellGridFrame = shellGridFrame,
            selectedInfoLabel = selectedInfoLabel,
            quantityInput = quantityInput,
            assembleButton = assembleButton,
            upgradeInfoLabel = upgradeInfoLabel,
            upgradeButton = upgradeButton,
            shellCards = {}
        }
        
        -- 关闭按钮事件
        closeButton.MouseButton1Click:Connect(function()
            hideAssemblerUI()
        end)
        
        -- Assemble按钮事件
        assembleButton.MouseButton1Click:Connect(function()
            performAssemble()
        end)
        
        -- 升级按钮事件
        upgradeButton.MouseButton1Click:Connect(function()
            performUpgrade()
        end)
    end
    
    currentAssembler = assemblerModel
    
    -- 添加AssembleShellEvent响应处理
    if not assemblerUI.eventConnection then
        assemblerUI.eventConnection = assembleShellEvent.OnClientEvent:Connect(function(ok, msg)
            if assemblerUI and assemblerUI.selectedInfoLabel then
                assemblerUI.selectedInfoLabel.Text = msg or (ok and "Assembly completed!" or "Assembly failed!")
                assemblerUI.selectedInfoLabel.TextColor3 = ok and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(200, 50, 50)
                
                if ok then
                    -- 成功后更新UI
                    updateAssemblerUI()
                end
            end
        end)
    end
    
    updateAssemblerUI()
    
    -- 显示动画
    assemblerUI.mainFrame.Visible = true
    assemblerUI.mainFrame.Size = UDim2.new(0, 0, 0, 0)
    assemblerUI.mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    local tween = TweenService:Create(assemblerUI.mainFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0, 650, 0, 500),
            Position = UDim2.new(0.5, -325, 0.5, -250)
        }
    )
    tween:Play()
end

-- 隐藏Assembler UI
function hideAssemblerUI()
    if not assemblerUI then return end
    
    local tween = TweenService:Create(assemblerUI.mainFrame,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }
    )
    tween:Play()
    
    tween.Completed:Connect(function()
        assemblerUI.mainFrame.Visible = false
        currentAssembler = nil
        selectedShell = nil
    end)
end

-- 选择Shell
function selectShell(shellInfo, availableCount)
    if availableCount <= 0 then
        assemblerUI.selectedInfoLabel.Text = "No shells available!"
        assemblerUI.selectedInfoLabel.TextColor3 = Color3.fromRGB(200, 50, 50)
        task.wait(1)
        assemblerUI.selectedInfoLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
        return
    end
    
    selectedShell = shellInfo
    
    -- 构建输出信息文本
    local outputText = ""
    for i, output in ipairs(shellInfo.outputs) do
        if i > 1 then outputText = outputText .. " / " end
        outputText = outputText .. output.robotId:gsub("_", " ") .. " (" .. output.chance .. "%)"
    end
    
    assemblerUI.selectedInfoLabel.Text = string.format("Selected: %s → %s", 
        shellInfo.name, outputText)
    assemblerUI.selectedInfoLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
end

-- 更新Assembler UI信息
function updateAssemblerUI()
    if not assemblerUI or not currentAssembler then return end
    
    local playerData = getDataRF:InvokeServer()
    local upgradeInfo = getUpgradeInfoRF:InvokeServer("Assembler")
    local inventory = getInventoryRF:InvokeServer()
    
    if playerData and upgradeInfo and inventory then
        local credits = playerData.Credits or 0
        local level = upgradeInfo.level or 1
        local speed = upgradeInfo.speed or 1
        local nextSpeed = upgradeInfo.nextSpeed or speed
        
        -- 更新升级信息
        if nextSpeed > speed then
            assemblerUI.upgradeInfoLabel.Text = string.format("Assembler Lv.%d → Lv.%d (Speed: %d → %d)", 
                level, level + 1, speed, nextSpeed)
            
            local upgradeCost = level * 500
            assemblerUI.upgradeButton.Text = string.format("Upgrade (%d¢)", upgradeCost)
            
            if credits >= upgradeCost then
                assemblerUI.upgradeButton.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
            else
                assemblerUI.upgradeButton.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
                assemblerUI.upgradeButton.Text = "Need Credits"
            end
        else
            assemblerUI.upgradeInfoLabel.Text = string.format("Max Level! (Lv.%d Speed: %d)", level, speed)
            assemblerUI.upgradeButton.Text = "Max Level"
            assemblerUI.upgradeButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        end
        
        -- 清除旧的Shell卡片
        for _, card in pairs(assemblerUI.shellCards) do
            card:Destroy()
        end
        assemblerUI.shellCards = {}
        
        -- 创建Shell卡片
        for _, shellInfo in ipairs(SHELL_TO_ROBOT) do
            local card, availableCount = createShellCard(shellInfo, assemblerUI.shellGridFrame, inventory)
            assemblerUI.shellCards[shellInfo.shellId] = card
            
            card.MouseButton1Click:Connect(function()
                selectShell(shellInfo, availableCount)
                
                -- 视觉反馈
                for _, otherCard in pairs(assemblerUI.shellCards) do
                    if otherCard.BackgroundColor3 ~= Color3.fromRGB(240, 240, 240) then -- 不是禁用状态
                        otherCard.BorderColor3 = Color3.fromRGB(220, 220, 220)
                        otherCard.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    end
                end
                
                if availableCount > 0 then
                    card.BorderColor3 = Color3.fromRGB(100, 180, 255)
                    card.BackgroundColor3 = Color3.fromRGB(240, 250, 255)
                end
            end)
        end
    end
end

-- 执行Assemble操作
function performAssemble()
    if not assemblerUI or not currentAssembler or not selectedShell then
        assemblerUI.selectedInfoLabel.Text = "Please select a shell first!"
        assemblerUI.selectedInfoLabel.TextColor3 = Color3.fromRGB(200, 50, 50)
        task.wait(1)
        assemblerUI.selectedInfoLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
        return
    end
    
    local inputText = assemblerUI.quantityInput.Text
    local quantity = tonumber(inputText)
    
    if not quantity or quantity <= 0 then
        assemblerUI.quantityInput.TextColor3 = Color3.fromRGB(200, 50, 50)
        task.wait(0.5)
        assemblerUI.quantityInput.TextColor3 = Color3.fromRGB(60, 60, 60)
        return
    end
    
    -- 显示处理状态
    assemblerUI.selectedInfoLabel.Text = "Processing..."
    assemblerUI.selectedInfoLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
    
    -- 显示反馈
    assemblerUI.assembleButton.Text = "Assembling..."
    assemblerUI.assembleButton.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
    
    -- 发送组装请求
    assembleShellEvent:FireServer(selectedShell.shellId, quantity)
    
    -- 重置输入和按钮
    assemblerUI.quantityInput.Text = "1"
    task.wait(0.5)
    assemblerUI.assembleButton.Text = "Assemble"
    assemblerUI.assembleButton.BackgroundColor3 = Color3.fromRGB(100, 180, 100)
end

-- 执行升级操作
function performUpgrade()
    if not assemblerUI or not currentAssembler then return end
    
    local playerData = getDataRF:InvokeServer()
    local upgradeInfo = getUpgradeInfoRF:InvokeServer("Assembler")
    
    if not playerData or not upgradeInfo then return end
    
    local credits = playerData.Credits or 0
    local level = upgradeInfo.level or 1
    local nextSpeed = upgradeInfo.nextSpeed or upgradeInfo.speed
    
    if nextSpeed <= (upgradeInfo.speed or 1) then
        return
    end
    
    local upgradeCost = level * 500
    if credits < upgradeCost then
        assemblerUI.upgradeButton.Text = "Not Enough!"
        assemblerUI.upgradeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        task.wait(1)
        updateAssemblerUI()
        return
    end
    
    upgradeMachineEvent:FireServer("Assembler")
    
    assemblerUI.upgradeButton.Text = "Upgrading..."
    assemblerUI.upgradeButton.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
    
    task.wait(0.5)
    updateAssemblerUI()
end

--------------------------------------------------------------------
-- Assembler交互设置
--------------------------------------------------------------------
local function setupAssemblerInteractions()
    for _, obj in pairs(workspace:GetChildren()) do
        if obj:IsA("Model") and obj.Name:lower():find("assembler") then
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
                    prompt.ObjectText = "Assembler"
                    prompt.ActionText = "打开"
                    prompt.HoldDuration = 0.5
                    prompt.MaxActivationDistance = 10
                    prompt.RequiresLineOfSight = false
                    prompt.Parent = targetPart
                    
                    prompt.Triggered:Connect(function(triggerPlayer)
                        if triggerPlayer == player then
                            showAssemblerUI(obj)
                        end
                    end)
                    
                    print("[AssemblerUI] 为Assembler添加ProximityPrompt:", obj.Name)
                end
            end
        end
    end
end

workspace.ChildAdded:Connect(function(child)
    if child:IsA("Model") and child.Name:lower():find("assembler") then
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
            prompt.ObjectText = "Assembler"
            prompt.ActionText = "打开"
            prompt.HoldDuration = 0.5
            prompt.MaxActivationDistance = 10
            prompt.RequiresLineOfSight = false
            prompt.Parent = targetPart
            
            prompt.Triggered:Connect(function(triggerPlayer)
                if triggerPlayer == player then
                    showAssemblerUI(child)
                end
            end)
            
            print("[AssemblerUI] 为新Assembler添加ProximityPrompt:", child.Name)
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end
    
    if input.KeyCode == Enum.KeyCode.E and assemblerUI and assemblerUI.mainFrame.Visible then
        hideAssemblerUI()
    end
end)

-- 定期更新UI
task.spawn(function()
    while true do
        task.wait(1)
        if assemblerUI and assemblerUI.mainFrame.Visible then
            updateAssemblerUI()
        end
    end
end)

setupAssemblerInteractions()

print("[AssemblerUI] Assembler UI系统已加载")