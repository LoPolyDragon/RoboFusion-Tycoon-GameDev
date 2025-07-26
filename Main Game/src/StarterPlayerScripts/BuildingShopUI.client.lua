--------------------------------------------------------------------
-- BuildingShopUI.client.lua · 建筑商店UI系统
-- 功能：右上角建筑商店按钮、机器选择界面、虚影跟随和放置
--------------------------------------------------------------------

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mouse = player:GetMouse()

-- 等待共享模块
local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
local GameConstants = require(SharedModules.GameConstants)

-- 建筑配置
local BUILDINGS = {
    {
        id = "Crusher",
        name = "破碎机",
        icon = "🔨",
        price = 0,
        description = "将废料转换为积分",
        color = Color3.fromRGB(180, 90, 60)
    },
    {
        id = "Generator", 
        name = "生成器",
        icon = "⚡",
        price = 0,
        description = "生成机器人外壳",
        color = Color3.fromRGB(255, 215, 0)
    },
    {
        id = "Assembler",
        name = "组装器", 
        icon = "🔧",
        price = 0,
        description = "将外壳组装成机器人",
        color = Color3.fromRGB(70, 130, 255)
    },
    {
        id = "Shipper",
        name = "运输器",
        icon = "📦", 
        price = 0,
        description = "售卖机器人获得积分",
        color = Color3.fromRGB(100, 200, 100)
    },
    {
        id = "EnergyMachine",
        name = "能量站",
        icon = "🔋",
        price = 0, 
        description = "为机器人充电",
        color = Color3.fromRGB(255, 100, 255)
    }
}

-- UI状态
local buildingShopUI = nil
local ghostModel = nil
local selectedBuilding = nil
local isPlacingMode = false
local placementConnection = nil

-- 隐藏商店界面 (提前定义)
local function hideShop()
    if not buildingShopUI then return end
    
    print("[BuildingShopUI] 隐藏建筑商店界面")
    
    local tween = TweenService:Create(buildingShopUI.mainFrame,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }
    )
    tween:Play()
    
    tween.Completed:Connect(function()
        buildingShopUI.background.Visible = false
        buildingShopUI.mainFrame.Visible = false
        print("[BuildingShopUI] 建筑商店界面已隐藏")
    end)
end

-- 等待RemoteFunction
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local getMachineModelFunction = remoteFolder:WaitForChild("GetMachineModelFunction")
local placeBuildingEvent = remoteFolder:WaitForChild("PlaceBuildingEvent")

-- 获取机器模型 (通过服务器)
local function getMachineModel(buildingId)
    print("[BuildingShopUI] 请求机器模型:", buildingId)
    
    local success, result = pcall(function()
        return getMachineModelFunction:InvokeServer(buildingId)
    end)
    
    if success and result then
        print("[BuildingShopUI] 从服务器获得模型:", buildingId)
        return result:Clone() -- 服务器返回的是模型，客户端克隆
    else
        warn("[BuildingShopUI] 无法从服务器获取模型:", buildingId)
        return nil
    end
end

-- 创建虚影模型 (提前定义)
local function createGhostModel(building)
    print("[BuildingShopUI] 创建虚影模型:", building.name)
    
    -- 尝试获取真实机器模型
    local machineModel = getMachineModel(building.id)
    
    local ghost
    if machineModel then
        print("[BuildingShopUI] 使用真实机器模型:", building.id)
        ghost = machineModel
        ghost.Name = "GhostBuilding"
        
        -- 设置所有部件为虚影状态，避免移动问题
        local function setGhostProperties(obj)
            if obj:IsA("BasePart") then
                obj.Transparency = 0.5
                obj.CanCollide = false
                obj.Anchored = true
                obj.BrickColor = BrickColor.new("Bright green")
                -- 移除所有物理相关组件避免奇怪行为
                for _, component in pairs(obj:GetChildren()) do
                    if component:IsA("BodyVelocity") or component:IsA("BodyPosition") or component:IsA("BodyAngularVelocity") then
                        component:Destroy()
                    end
                end
            elseif obj:IsA("Script") or obj:IsA("LocalScript") then
                -- 禁用脚本避免干扰
                obj.Disabled = true
            end
            for _, child in pairs(obj:GetChildren()) do
                setGhostProperties(child)
            end
        end
        setGhostProperties(ghost)
        
        -- 如果是Model，设置PrimaryPart
        if ghost:IsA("Model") and not ghost.PrimaryPart then
            for _, part in pairs(ghost:GetChildren()) do
                if part:IsA("BasePart") then
                    ghost.PrimaryPart = part
                    break
                end
            end
        end
    else
        print("[BuildingShopUI] 使用备用立方体模型")
        -- 备用：创建简单立方体
        ghost = Instance.new("Part")
        ghost.Name = "GhostBuilding"
        ghost.Size = Vector3.new(8, 8, 8)
        ghost.Material = Enum.Material.ForceField
        ghost.BrickColor = BrickColor.new("Bright green")
        ghost.Transparency = 0.5
        ghost.CanCollide = false
        ghost.Anchored = true
    end
    
    ghost.Parent = workspace
    
    -- 添加发光效果
    local selectionBox = Instance.new("SelectionBox")
    selectionBox.Adornee = ghost
    selectionBox.Color3 = building.color
    selectionBox.LineThickness = 0.2
    selectionBox.Transparency = 0.3
    selectionBox.Parent = ghost
    
    -- 添加名称标签
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 100, 0, 30)
    billboardGui.Adornee = ghost
    billboardGui.Parent = ghost
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.BackgroundTransparency = 0.3
    nameLabel.Text = building.name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextSize = 14
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = billboardGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = nameLabel
    
    return ghost
end

-- 开始放置模式 (提前定义)
local function startPlacementMode()
    if isPlacingMode then return end
    
    print("[BuildingShopUI] 开始放置模式:", selectedBuilding.name)
    isPlacingMode = true
    
    -- 创建虚影
    ghostModel = createGhostModel(selectedBuilding)
    
    -- 更新虚影位置的连接 (限制在地面) - 针对Model+MeshPart结构
    placementConnection = RunService.Heartbeat:Connect(function()
        if ghostModel and mouse.Hit then
            local targetPosition = mouse.Hit.Position
            
            -- 针对Model+MeshPart结构的移动
            if ghostModel:IsA("Model") then
                -- 找到Model中的MeshPart
                local meshPart = nil
                for _, child in pairs(ghostModel:GetChildren()) do
                    if child:IsA("MeshPart") or child:IsA("Part") then
                        meshPart = child
                        break
                    end
                end
                
                if meshPart then
                    -- 直接移动MeshPart，让它贴地
                    local meshSize = meshPart.Size
                    meshPart.Position = Vector3.new(targetPosition.X, meshSize.Y/2, targetPosition.Z)
                end
            elseif ghostModel:IsA("Part") or ghostModel:IsA("MeshPart") then
                ghostModel.Position = Vector3.new(targetPosition.X, ghostModel.Size.Y/2, targetPosition.Z)
            end
        end
    end)
    
    print("[BuildingShopUI] 左键放置建筑，右键取消")
end

-- 创建右上角建筑商店按钮
local function createBuildingShopButton()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BuildingShopButtonUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    local shopButton = Instance.new("TextButton")
    shopButton.Size = UDim2.new(0, 80, 0, 70)
    shopButton.Position = UDim2.new(1, -100, 0, 20)
    shopButton.BackgroundColor3 = Color3.fromRGB(85, 170, 85)
    shopButton.Text = "🏗️\\nBUILD"
    shopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    shopButton.TextSize = 14
    shopButton.Font = Enum.Font.GothamBold
    shopButton.BorderSizePixel = 0
    shopButton.Active = true
    shopButton.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = shopButton
    
    return screenGui, shopButton
end

-- 创建建筑商店界面
local function createBuildingShopUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BuildingShopUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    -- 背景遮罩
    local background = Instance.new("Frame")
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    background.BackgroundTransparency = 0.5
    background.BorderSizePixel = 0
    background.Visible = false
    background.Parent = screenGui
    
    -- 主框架
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 700, 0, 500)
    mainFrame.Position = UDim2.new(0.5, -350, 0.5, -250)
    mainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = mainFrame
    
    -- 标题栏
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -60, 0, 50)
    titleLabel.Position = UDim2.new(0, 20, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🏗️ 建筑商店"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 24
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = mainFrame
    
    -- 关闭按钮
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 35, 0, 35)
    closeButton.Position = UDim2.new(1, -45, 0, 10)
    closeButton.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
    closeButton.Text = "×"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 20
    closeButton.Font = Enum.Font.GothamBold
    closeButton.BorderSizePixel = 0
    closeButton.Active = true
    closeButton.Parent = mainFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton
    
    -- 内容区域
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Size = UDim2.new(1, -40, 1, -80)
    contentFrame.Position = UDim2.new(0, 20, 0, 70)
    contentFrame.BackgroundTransparency = 1
    contentFrame.ScrollBarThickness = 8
    contentFrame.Parent = mainFrame
    
    local layout = Instance.new("UIGridLayout")
    layout.CellSize = UDim2.new(0, 200, 0, 120)
    layout.CellPadding = UDim2.new(0, 20, 0, 20)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = contentFrame
    
    return screenGui, background, mainFrame, closeButton, contentFrame
end

-- 检查玩家积分
local function getPlayerCredits()
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local credits = leaderstats:FindFirstChild("Credits")
        if credits then
            return credits.Value
        end
    end
    return 0
end

-- 创建建筑卡片
local function createBuildingCard(building, parent, layoutOrder)
    local cardFrame = Instance.new("Frame")
    cardFrame.Size = UDim2.new(0, 200, 0, 120)
    cardFrame.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    cardFrame.BorderSizePixel = 0
    cardFrame.LayoutOrder = layoutOrder
    cardFrame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = cardFrame
    
    -- 彩色顶部条
    local colorStrip = Instance.new("Frame")
    colorStrip.Size = UDim2.new(1, 0, 0, 6)
    colorStrip.Position = UDim2.new(0, 0, 0, 0)
    colorStrip.BackgroundColor3 = building.color
    colorStrip.BorderSizePixel = 0
    colorStrip.Parent = cardFrame
    
    local stripCorner = Instance.new("UICorner")
    stripCorner.CornerRadius = UDim.new(0, 12)
    stripCorner.Parent = colorStrip
    
    -- 遮盖底部圆角
    local stripCover = Instance.new("Frame")
    stripCover.Size = UDim2.new(1, 0, 0, 6)
    stripCover.Position = UDim2.new(0, 0, 0, 3)
    stripCover.BackgroundColor3 = building.color
    stripCover.BorderSizePixel = 0
    stripCover.Parent = colorStrip
    
    -- 图标
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(0, 40, 0, 40)
    iconLabel.Position = UDim2.new(0, 15, 0, 15)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = building.icon
    iconLabel.TextSize = 30
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.Parent = cardFrame
    
    -- 名称
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0, 130, 0, 25)
    nameLabel.Position = UDim2.new(0, 60, 0, 15)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = building.name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextSize = 16
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = cardFrame
    
    -- 描述
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, -20, 0, 35)
    descLabel.Position = UDim2.new(0, 10, 0, 40)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = building.description
    descLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    descLabel.TextSize = 12
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextWrapped = true
    descLabel.Parent = cardFrame
    
    -- 价格和购买按钮
    local priceLabel = Instance.new("TextLabel")
    priceLabel.Size = UDim2.new(0, 80, 0, 20)
    priceLabel.Position = UDim2.new(0, 15, 0, 85)
    priceLabel.BackgroundTransparency = 1
    priceLabel.Text = building.price .. " Credits"
    priceLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    priceLabel.TextSize = 14
    priceLabel.Font = Enum.Font.GothamBold
    priceLabel.TextXAlignment = Enum.TextXAlignment.Left
    priceLabel.Parent = cardFrame
    
    local buyButton = Instance.new("TextButton")
    buyButton.Size = UDim2.new(0, 80, 0, 25)
    buyButton.Position = UDim2.new(1, -95, 0, 80)
    buyButton.BackgroundColor3 = building.color
    buyButton.Text = "购买"
    buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    buyButton.TextSize = 12
    buyButton.Font = Enum.Font.GothamBold
    buyButton.BorderSizePixel = 0
    buyButton.Active = true
    buyButton.Parent = cardFrame
    
    local buyCorner = Instance.new("UICorner")
    buyCorner.CornerRadius = UDim.new(0, 6)
    buyCorner.Parent = buyButton
    
    -- 购买按钮事件
    buyButton.MouseButton1Click:Connect(function()
        local playerCredits = getPlayerCredits()
        if playerCredits >= building.price then
            print("[BuildingShopUI] 购买建筑:", building.name)
            selectedBuilding = building
            hideShop()
            startPlacementMode()
        else
            print("[BuildingShopUI] 积分不足，需要:", building.price, "当前:", playerCredits)
            -- TODO: 显示积分不足提示
        end
    end)
    
    return cardFrame
end


-- 显示商店界面
local function showShop()
    print("[BuildingShopUI] 显示建筑商店界面")
    
    -- 通知教程系统商店已打开
    local tutorialEvent = remoteFolder:FindFirstChild("TutorialEvent")
    if tutorialEvent then
        tutorialEvent:FireServer("STEP_COMPLETED", "OPEN_SHOP", {
            target = "BuildingShopButton"
        })
    end
    
    if not buildingShopUI then
        print("[BuildingShopUI] 创建新的建筑商店UI")
        local ui, background, mainFrame, closeButton, contentFrame = createBuildingShopUI()
        
        buildingShopUI = {
            gui = ui,
            background = background,
            mainFrame = mainFrame,
            closeButton = closeButton,
            contentFrame = contentFrame
        }
        
        -- 关闭按钮
        closeButton.MouseButton1Click:Connect(function()
            hideShop()
        end)
        
        -- 背景点击关闭
        local backgroundButton = Instance.new("TextButton")
        backgroundButton.Size = UDim2.new(1, 0, 1, 0)
        backgroundButton.BackgroundTransparency = 1
        backgroundButton.Text = ""
        backgroundButton.Parent = background
        
        backgroundButton.MouseButton1Click:Connect(function()
            hideShop()
        end)
        
        -- 等待布局组件加载
        task.wait(0.1)
        
        -- 创建建筑卡片
        print("[BuildingShopUI] 创建建筑卡片")
        for i, building in ipairs(BUILDINGS) do
            print("[BuildingShopUI] 创建卡片:", building.name)
            createBuildingCard(building, contentFrame, i)
        end
        
        -- 设置滚动区域大小
        task.wait(0.1)
        local rows = math.ceil(#BUILDINGS / 3)
        contentFrame.CanvasSize = UDim2.new(0, 0, 0, rows * 140)
        print("[BuildingShopUI] 设置滚动区域大小:", rows * 140)
    end
    
    -- 显示动画
    buildingShopUI.background.Visible = true
    buildingShopUI.mainFrame.Visible = true
    buildingShopUI.mainFrame.Size = UDim2.new(0, 0, 0, 0)
    buildingShopUI.mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    local tween = TweenService:Create(buildingShopUI.mainFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0, 700, 0, 500),
            Position = UDim2.new(0.5, -350, 0.5, -250)
        }
    )
    tween:Play()
end


-- 停止放置模式
local function stopPlacementMode()
    if not isPlacingMode then return end
    
    print("[BuildingShopUI] 停止放置模式")
    isPlacingMode = false
    
    if placementConnection then
        placementConnection:Disconnect()
        placementConnection = nil
    end
    
    if ghostModel then
        ghostModel:Destroy()
        ghostModel = nil
    end
    
    selectedBuilding = nil
end

-- 放置建筑
local function placeBuilding()
    if not isPlacingMode or not selectedBuilding or not ghostModel then return end
    
    -- 获取虚影当前位置 - 针对Model+MeshPart结构
    local ghostPosition
    if ghostModel:IsA("Model") then
        -- 找到Model中的MeshPart或Part
        for _, child in pairs(ghostModel:GetChildren()) do
            if child:IsA("MeshPart") or child:IsA("Part") then
                ghostPosition = child.Position
                break
            end
        end
    else
        ghostPosition = ghostModel.Position
    end
    print("[BuildingShopUI] 放置建筑:", selectedBuilding.name, "在位置:", ghostPosition)
    
    -- 发送放置请求到服务器
    print("[BuildingShopUI] 发送放置请求到服务器:", selectedBuilding.id, "位置:", ghostPosition)
    
    local success = pcall(function()
        placeBuildingEvent:FireServer(selectedBuilding.id, ghostPosition)
    end)
    
    if success then
        print("[BuildingShopUI] 放置请求已发送")
        
        -- 通知教程系统建筑已放置
        local tutorialEvent = remoteFolder:FindFirstChild("TutorialEvent")
        if tutorialEvent then
            tutorialEvent:FireServer("STEP_COMPLETED", "PLACE_CRUSHER", {
                buildingType = selectedBuilding.id
            })
        end
    else
        warn("[BuildingShopUI] 发送放置请求失败")
    end
    
    stopPlacementMode()
end

-- 输入处理
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end
    
    if isPlacingMode then
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            placeBuilding()
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            stopPlacementMode()
        end
    end
    
    -- ESC键关闭商店
    if input.KeyCode == Enum.KeyCode.Escape and buildingShopUI and buildingShopUI.mainFrame.Visible then
        hideShop()
    end
end)

-- 初始化
local function initializeBuildingShop()
    local buttonUI, shopButton = createBuildingShopButton()
    
    shopButton.MouseButton1Click:Connect(function()
        showShop()
    end)
    
    print("[BuildingShopUI] 建筑商店按钮创建完成")
end

-- 启动
task.spawn(function()
    task.wait(2)
    initializeBuildingShop()
    print("[BuildingShopUI] 建筑商店系统已加载")
end)

print("[BuildingShopUI] 建筑商店UI系统已启动")