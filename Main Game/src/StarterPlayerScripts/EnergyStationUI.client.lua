--------------------------------------------------------------------
-- EnergyStationUI.client.lua · 能量站交互界面
-- 功能：
--   1) 显示能量站信息
--   2) 显示附近机器人能量状态
--   3) Credits充能功能
--   4) 能量站升级功能
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

-- 创建能量站RemoteEvents（如果不存在）
local reFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local energyStationEvent = reFolder:FindFirstChild("EnergyStationEvent")
if not energyStationEvent then
    energyStationEvent = Instance.new("RemoteEvent")
    energyStationEvent.Name = "EnergyStationEvent"
    energyStationEvent.Parent = reFolder
end

--------------------------------------------------------------------
-- 创建能量站UI
--------------------------------------------------------------------
local function createEnergyStationUI()
    -- 主界面
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "EnergyStationUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui
    
    -- 主框架
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 500, 0, 400)
    mainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
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
    titleBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = titleBar
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -50, 1, 0)
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "能量站"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.Gotham
    titleLabel.Parent = titleBar
    
    -- 关闭按钮
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
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
    contentFrame.Size = UDim2.new(1, -20, 1, -60)
    contentFrame.Position = UDim2.new(0, 10, 0, 50)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame
    
    -- 左侧：能量站信息
    local stationInfoFrame = Instance.new("Frame")
    stationInfoFrame.Size = UDim2.new(0.5, -5, 1, 0)
    stationInfoFrame.Position = UDim2.new(0, 0, 0, 0)
    stationInfoFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    stationInfoFrame.BorderSizePixel = 0
    stationInfoFrame.Parent = contentFrame
    
    local infoCorner = Instance.new("UICorner")
    infoCorner.CornerRadius = UDim.new(0, 5)
    infoCorner.Parent = stationInfoFrame
    
    -- 能量站等级
    local levelLabel = Instance.new("TextLabel")
    levelLabel.Size = UDim2.new(1, -20, 0, 30)
    levelLabel.Position = UDim2.new(0, 10, 0, 10)
    levelLabel.BackgroundTransparency = 1
    levelLabel.Text = "等级: 1"
    levelLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    levelLabel.TextScaled = true
    levelLabel.Font = Enum.Font.GothamSemibold
    levelLabel.TextXAlignment = Enum.TextXAlignment.Left
    levelLabel.Parent = stationInfoFrame
    
    -- 充能范围
    local rangeLabel = Instance.new("TextLabel")
    rangeLabel.Size = UDim2.new(1, -20, 0, 25)
    rangeLabel.Position = UDim2.new(0, 10, 0, 50)
    rangeLabel.BackgroundTransparency = 1
    rangeLabel.Text = "充能范围: 20格"
    rangeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    rangeLabel.TextScaled = true
    rangeLabel.Font = Enum.Font.Gotham
    rangeLabel.TextXAlignment = Enum.TextXAlignment.Left
    rangeLabel.Parent = stationInfoFrame
    
    -- 充能速度
    local speedLabel = Instance.new("TextLabel")
    speedLabel.Size = UDim2.new(1, -20, 0, 25)
    speedLabel.Position = UDim2.new(0, 10, 0, 85)
    speedLabel.BackgroundTransparency = 1
    speedLabel.Text = "充能速度: 0.2/秒"
    speedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    speedLabel.TextScaled = true
    speedLabel.Font = Enum.Font.Gotham
    speedLabel.TextXAlignment = Enum.TextXAlignment.Left
    speedLabel.Parent = stationInfoFrame
    
    -- 覆盖机器人数
    local robotsLabel = Instance.new("TextLabel")
    robotsLabel.Size = UDim2.new(1, -20, 0, 25)
    robotsLabel.Position = UDim2.new(0, 10, 0, 120)
    robotsLabel.BackgroundTransparency = 1
    robotsLabel.Text = "覆盖机器人: 0个"
    robotsLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    robotsLabel.TextScaled = true
    robotsLabel.Font = Enum.Font.Gotham
    robotsLabel.TextXAlignment = Enum.TextXAlignment.Left
    robotsLabel.Parent = stationInfoFrame
    
    -- 升级按钮
    local upgradeButton = Instance.new("TextButton")
    upgradeButton.Size = UDim2.new(0.8, 0, 0, 40)
    upgradeButton.Position = UDim2.new(0.1, 0, 1, -50)
    upgradeButton.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    upgradeButton.Text = "升级 (500 Credits)"
    upgradeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    upgradeButton.TextScaled = true
    upgradeButton.Font = Enum.Font.GothamBold
    upgradeButton.BorderSizePixel = 0
    upgradeButton.Active = true
    upgradeButton.Parent = stationInfoFrame
    
    local upgradeCorner = Instance.new("UICorner")
    upgradeCorner.CornerRadius = UDim.new(0, 5)
    upgradeCorner.Parent = upgradeButton
    
    -- 右侧：机器人列表
    local robotListFrame = Instance.new("Frame")
    robotListFrame.Size = UDim2.new(0.5, -5, 1, 0)
    robotListFrame.Position = UDim2.new(0.5, 5, 0, 0)
    robotListFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    robotListFrame.BorderSizePixel = 0
    robotListFrame.Parent = contentFrame
    
    local listCorner = Instance.new("UICorner")
    listCorner.CornerRadius = UDim.new(0, 5)
    listCorner.Parent = robotListFrame
    
    -- 机器人列表标题
    local listTitle = Instance.new("TextLabel")
    listTitle.Size = UDim2.new(1, -20, 0, 30)
    listTitle.Position = UDim2.new(0, 10, 0, 10)
    listTitle.BackgroundTransparency = 1
    listTitle.Text = "附近机器人"
    listTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    listTitle.TextScaled = true
    listTitle.Font = Enum.Font.GothamSemibold
    listTitle.TextXAlignment = Enum.TextXAlignment.Left
    listTitle.Parent = robotListFrame
    
    -- 滚动列表
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -20, 1, -50)
    scrollFrame.Position = UDim2.new(0, 10, 0, 40)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.BorderSizePixel = 0
    scrollFrame.Parent = robotListFrame
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 5)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = scrollFrame
    
    return screenGui, mainFrame, closeButton, levelLabel, rangeLabel, speedLabel, robotsLabel, upgradeButton, scrollFrame, listLayout
end

--------------------------------------------------------------------
-- 机器人能量条UI
--------------------------------------------------------------------
local function createRobotEnergyBar(robotName, energy, maxEnergy, parent, layoutOrder)
    local robotFrame = Instance.new("Frame")
    robotFrame.Size = UDim2.new(1, 0, 0, 60)
    robotFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    robotFrame.BorderSizePixel = 0
    robotFrame.LayoutOrder = layoutOrder
    robotFrame.Parent = parent
    
    local robotCorner = Instance.new("UICorner")
    robotCorner.CornerRadius = UDim.new(0, 3)
    robotCorner.Parent = robotFrame
    
    -- 机器人名称
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -10, 0, 20)
    nameLabel.Position = UDim2.new(0, 5, 0, 5)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = robotName
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = robotFrame
    
    -- 能量条背景
    local energyBarBg = Instance.new("Frame")
    energyBarBg.Size = UDim2.new(1, -10, 0, 15)
    energyBarBg.Position = UDim2.new(0, 5, 0, 30)
    energyBarBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    energyBarBg.BorderSizePixel = 0
    energyBarBg.Parent = robotFrame
    
    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(0, 2)
    bgCorner.Parent = energyBarBg
    
    -- 能量条
    local energyBar = Instance.new("Frame")
    energyBar.Size = UDim2.new(energy / maxEnergy, 0, 1, 0)
    energyBar.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
    energyBar.BorderSizePixel = 0
    energyBar.Parent = energyBarBg
    
    if energy / maxEnergy < 0.3 then
        energyBar.BackgroundColor3 = Color3.fromRGB(255, 50, 50) -- 低能量红色
    elseif energy / maxEnergy < 0.6 then
        energyBar.BackgroundColor3 = Color3.fromRGB(255, 200, 0) -- 中等能量黄色
    end
    
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 2)
    barCorner.Parent = energyBar
    
    -- 能量文本
    local energyText = Instance.new("TextLabel") 
    energyText.Size = UDim2.new(1, 0, 1, 0)
    energyText.BackgroundTransparency = 1
    energyText.Text = string.format("%.0f/%.0f", energy, maxEnergy)
    energyText.TextColor3 = Color3.fromRGB(255, 255, 255)
    energyText.TextScaled = true
    energyText.Font = Enum.Font.GothamBold
    energyText.Parent = energyBarBg
    
    return robotFrame
end

--------------------------------------------------------------------
-- 主UI控制
--------------------------------------------------------------------
local energyStationUI = nil
local currentStation = nil

-- 显示能量站UI
local function showEnergyStationUI(stationModel)
    if not energyStationUI then
        local ui, mainFrame, closeButton, levelLabel, rangeLabel, speedLabel, robotsLabel, upgradeButton, scrollFrame, listLayout = createEnergyStationUI()
        energyStationUI = {
            gui = ui,
            mainFrame = mainFrame,
            closeButton = closeButton,
            levelLabel = levelLabel,
            rangeLabel = rangeLabel,
            speedLabel = speedLabel,
            robotsLabel = robotsLabel,
            upgradeButton = upgradeButton,
            scrollFrame = scrollFrame,
            listLayout = listLayout
        }
        
        -- 关闭按钮事件
        closeButton.MouseButton1Click:Connect(function()
            hideEnergyStationUI()
        end)
        
        -- 升级按钮事件
        upgradeButton.MouseButton1Click:Connect(function()
            if currentStation then
                energyStationEvent:FireServer("UPGRADE_STATION", currentStation)
            end
        end)
    end
    
    currentStation = stationModel
    updateEnergyStationUI()
    
    -- 显示动画
    energyStationUI.mainFrame.Visible = true
    energyStationUI.mainFrame.Size = UDim2.new(0, 0, 0, 0)
    energyStationUI.mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    local tween = TweenService:Create(energyStationUI.mainFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0, 500, 0, 400),
            Position = UDim2.new(0.5, -250, 0.5, -200)
        }
    )
    tween:Play()
end

-- 隐藏能量站UI
function hideEnergyStationUI()
    if not energyStationUI then return end
    
    local tween = TweenService:Create(energyStationUI.mainFrame,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }
    )
    tween:Play()
    
    tween.Completed:Connect(function()
        energyStationUI.mainFrame.Visible = false
        currentStation = nil
    end)
end

-- 更新能量站UI信息
function updateEnergyStationUI()
    if not energyStationUI or not currentStation then return end
    
    -- 获取能量站属性
    local level = currentStation:GetAttribute("Level") or 1
    local range = currentStation:GetAttribute("Range") or 20
    local chargeRate = currentStation:GetAttribute("ChargeRate") or 0.2
    
    -- 更新UI信息
    energyStationUI.levelLabel.Text = "等级: " .. level
    energyStationUI.rangeLabel.Text = "充能范围: " .. range .. "格"
    energyStationUI.speedLabel.Text = string.format("充能速度: %.1f/秒", chargeRate)
    
    -- 清除旧的机器人列表
    for _, child in pairs(energyStationUI.scrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- 查找附近的机器人
    local robotsInRange = {}
    
    -- 获取能量站位置
    local stationPos
    if currentStation.PrimaryPart then
        stationPos = currentStation.PrimaryPart.Position
    else
        -- 如果没有PrimaryPart，找第一个Part
        for _, child in pairs(currentStation:GetChildren()) do
            if child:IsA("BasePart") then
                stationPos = child.Position
                break
            end
        end
    end
    
    if not stationPos then
        print("[EnergyStationUI] 错误: 能量站没有可用的位置")
        energyStationUI.robotsLabel.Text = "覆盖机器人: 0个 (位置错误)"
        return
    end
    
    local function isRobotModel(obj)
        -- 检查多种可能的机器人标识方式
        if obj:GetAttribute("Type") == "Robot" then
            return true
        end
        
        -- 检查名称中是否包含机器人关键词
        local name = obj.Name:lower()
        if name:find("robot") or name:find("bot") or name:find("机器人") then
            return true
        end
        
        -- 检查是否有机器人相关的属性
        if obj:GetAttribute("RobotType") then
            return true
        end
        
        -- 检查是否有Owner属性（通常机器人会有Owner）
        if obj:GetAttribute("Owner") then
            return true
        end
        
        return false
    end
    
    -- 获取机器人位置的辅助函数
    local function getRobotPosition(robotModel)
        if robotModel.PrimaryPart then
            return robotModel.PrimaryPart.Position
        end
        
        -- 如果没有PrimaryPart，找第一个Part
        for _, child in pairs(robotModel:GetChildren()) do
            if child:IsA("BasePart") then
                return child.Position
            end
        end
        
        return nil
    end
    
    for _, obj in pairs(workspace:GetChildren()) do
        if obj:IsA("Model") and isRobotModel(obj) then
            local robotPos = getRobotPosition(obj)
            if robotPos then
                local distance = (robotPos - stationPos).Magnitude
                if distance <= range then
                    local energy = obj:GetAttribute("Energy") or 0
                    local maxEnergy = obj:GetAttribute("MaxEnergy") or 60
                    table.insert(robotsInRange, {
                        model = obj,
                        name = obj.Name,
                        energy = energy,
                        maxEnergy = maxEnergy
                    })
                end
            end
        end
    end
    
    -- 更新机器人数量
    energyStationUI.robotsLabel.Text = "覆盖机器人: " .. #robotsInRange .. "个"
    
    -- 创建机器人能量条
    for i, robotData in ipairs(robotsInRange) do
        createRobotEnergyBar(robotData.name, robotData.energy, robotData.maxEnergy, 
                           energyStationUI.scrollFrame, i)
    end
    
    -- 更新滚动区域大小
    energyStationUI.scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #robotsInRange * 65)
    
    -- 更新升级按钮
    local upgradeCost = (level * 500) -- 简单的费用计算
    energyStationUI.upgradeButton.Text = string.format("升级 (%d Credits)", upgradeCost)
    
    -- 检查是否可以升级
    if level >= 5 then
        energyStationUI.upgradeButton.Text = "已达最高等级"
        energyStationUI.upgradeButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    else
        local playerData = getDataRF:InvokeServer()
        if playerData and (playerData.Credits or 0) >= upgradeCost then
            energyStationUI.upgradeButton.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
        else
            energyStationUI.upgradeButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        end
    end
end

--------------------------------------------------------------------
-- 能量站交互设置
--------------------------------------------------------------------
-- 为现有能量站添加交互提示
local function setupEnergyStationInteractions()
    for _, obj in pairs(workspace:GetChildren()) do
        if obj:IsA("Model") and obj:GetAttribute("Type") == "EnergyStation" then
            -- 查找合适的Part来添加ProximityPrompt
            local targetPart = obj.PrimaryPart
            if not targetPart then
                -- 如果没有PrimaryPart，找第一个Part
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
                    prompt.ObjectText = "能量站"
                    prompt.ActionText = "打开"
                    prompt.HoldDuration = 0.5
                    prompt.MaxActivationDistance = 10
                    prompt.RequiresLineOfSight = false
                    prompt.Parent = targetPart
                    
                    prompt.Triggered:Connect(function(triggerPlayer)
                        if triggerPlayer == player then
                            showEnergyStationUI(obj)
                        end
                    end)
                    
                    print("[EnergyStationUI] 为能量站添加ProximityPrompt:", obj.Name)
                end
            else
                print("[EnergyStationUI] 警告: 能量站没有可用的Part:", obj.Name)
            end
        end
    end
end

-- 监听新的能量站
workspace.ChildAdded:Connect(function(child)
    if child:IsA("Model") and child:GetAttribute("Type") == "EnergyStation" then
        task.wait(0.1) -- 等待属性设置
        
        -- 查找合适的Part来添加ProximityPrompt
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
            prompt.ObjectText = "能量站"
            prompt.ActionText = "打开"
            prompt.HoldDuration = 0.5
            prompt.MaxActivationDistance = 10
            prompt.RequiresLineOfSight = false
            prompt.Parent = targetPart
            
            prompt.Triggered:Connect(function(triggerPlayer)
                if triggerPlayer == player then
                    showEnergyStationUI(child)
                end
            end)
            
            print("[EnergyStationUI] 为新能量站添加ProximityPrompt:", child.Name)
        else
            print("[EnergyStationUI] 警告: 新能量站没有可用的Part:", child.Name)
        end
    end
end)

-- 键盘快捷键
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end
    
    if input.KeyCode == Enum.KeyCode.E and energyStationUI and energyStationUI.mainFrame.Visible then
        hideEnergyStationUI()
    end
end)

-- 定期更新UI（如果打开状态）
task.spawn(function()
    while true do
        task.wait(1)
        if energyStationUI and energyStationUI.mainFrame.Visible then
            updateEnergyStationUI()
        end
    end
end)

-- 初始化
setupEnergyStationInteractions()

print("[EnergyStationUI] 能量站UI系统已加载")