--------------------------------------------------------------------
-- CooldownUI.client.lua · 冷却时间显示界面
-- 功能：
--   1) 显示所有机器的冷却状态
--   2) 实时更新剩余冷却时间
--   3) 视觉提示冷却完成
--   4) 紧凑的界面设计
--------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- RemoteEvent
local cooldownUpdateEvent = ReplicatedStorage:WaitForChild("CooldownUpdateEvent")

-- GameConstants
local GameConstants = require(ReplicatedStorage.SharedModules.GameConstants)

-- UI Variables
local screenGui = nil
local mainFrame = nil
local cooldownList = nil
local isUIVisible = true

-- Data
local activeCooldowns = {
    machines = {},
    systems = {}
}

-- 机器图标映射
local machineIcons = {
    Crusher = "⚒️",
    Generator = "⚡",
    Assembler = "🔧",
    Shipper = "📦",
    Smelter = "🔥",
    ToolForge = "🛠️",
    EnergyStation = "🔋"
}

-- 系统图标映射
local systemIcons = {
    ROBOT_MINING = "⛏️",
    DAILY_SIGNIN = "📅",
    SHELL_HATCHING = "🥚",
    BUILDING_UPGRADE = "🏗️",
    INVENTORY_OPERATION = "🎒",
    TELEPORT = "🌀"
}

--------------------------------------------------------------------
-- 创建UI
--------------------------------------------------------------------
local function createCooldownUI()
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CooldownUI"
    screenGui.Parent = playerGui
    
    -- 主框架 - 紧凑设计
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 280, 0, 400)
    mainFrame.Position = UDim2.new(1, -290, 0, 100)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    mainFrame.BackgroundTransparency = 0.15
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = isUIVisible
    mainFrame.Parent = screenGui
    
    -- 圆角
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    -- 标题栏
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 35)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar
    
    -- 标题文本
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -60, 1, 0)
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "⏱️ 冷却状态"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar
    
    -- 切换按钮
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = UDim2.new(0, 25, 0, 25)
    toggleButton.Position = UDim2.new(1, -30, 0, 5)
    toggleButton.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
    toggleButton.Text = "_"
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.TextScaled = true
    toggleButton.Font = Enum.Font.SourceSansBold
    toggleButton.Parent = titleBar
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 6)
    toggleCorner.Parent = toggleButton
    
    -- 冷却列表容器
    local listContainer = Instance.new("Frame")
    listContainer.Name = "ListContainer"
    listContainer.Size = UDim2.new(1, -10, 1, -45)
    listContainer.Position = UDim2.new(0, 5, 0, 40)
    listContainer.BackgroundTransparency = 1
    listContainer.Parent = mainFrame
    
    -- 滚动框
    cooldownList = Instance.new("ScrollingFrame")
    cooldownList.Name = "CooldownList"
    cooldownList.Size = UDim2.new(1, 0, 1, 0)
    cooldownList.Position = UDim2.new(0, 0, 0, 0)
    cooldownList.BackgroundTransparency = 1
    cooldownList.BorderSizePixel = 0
    cooldownList.ScrollBarThickness = 6
    cooldownList.Parent = listContainer
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 3)
    listLayout.Parent = cooldownList
    
    -- 事件连接
    toggleButton.Activated:Connect(function()
        toggleCooldownList()
    end)
end

--------------------------------------------------------------------
-- 创建冷却项目
--------------------------------------------------------------------
local function createCooldownItem(itemType, itemName, instanceId, remainingTime)
    local itemFrame = Instance.new("Frame")
    itemFrame.Name = itemType .. "_" .. itemName .. "_" .. (instanceId or "main")
    itemFrame.Size = UDim2.new(1, -5, 0, 35)
    itemFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    itemFrame.BorderSizePixel = 0
    itemFrame.Parent = cooldownList
    
    local itemCorner = Instance.new("UICorner")
    itemCorner.CornerRadius = UDim.new(0, 8)
    itemCorner.Parent = itemFrame
    
    -- 图标
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(0, 25, 0, 25)
    iconLabel.Position = UDim2.new(0, 5, 0.5, -12.5)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = (itemType == "machine" and machineIcons[itemName]) or systemIcons[itemName] or "⚙️"
    iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    iconLabel.TextScaled = true
    iconLabel.Font = Enum.Font.SourceSans
    iconLabel.Parent = itemFrame
    
    -- 名称标签
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0, 100, 1, 0)
    nameLabel.Position = UDim2.new(0, 35, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = itemName
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.SourceSans
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = itemFrame
    
    -- 时间标签
    local timeLabel = Instance.new("TextLabel")
    timeLabel.Name = "TimeLabel"
    timeLabel.Size = UDim2.new(0, 60, 1, 0)
    timeLabel.Position = UDim2.new(1, -65, 0, 0)
    timeLabel.BackgroundTransparency = 1
    timeLabel.Text = string.format("%.1fs", remainingTime)
    timeLabel.TextColor3 = remainingTime > 0 and Color3.fromRGB(255, 150, 150) or Color3.fromRGB(150, 255, 150)
    timeLabel.TextScaled = true
    timeLabel.Font = Enum.Font.SourceSansBold
    timeLabel.TextXAlignment = Enum.TextXAlignment.Right
    timeLabel.Parent = itemFrame
    
    -- 进度条背景
    local progressBg = Instance.new("Frame")
    progressBg.Size = UDim2.new(1, -10, 0, 3)
    progressBg.Position = UDim2.new(0, 5, 1, -8)
    progressBg.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    progressBg.BorderSizePixel = 0
    progressBg.Parent = itemFrame
    
    -- 进度条
    local progressBar = Instance.new("Frame")
    progressBar.Name = "ProgressBar"
    progressBar.Size = UDim2.new(0, 0, 1, 0)
    progressBar.Position = UDim2.new(0, 0, 0, 0)
    progressBar.BackgroundColor3 = remainingTime > 0 and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 255, 100)
    progressBar.BorderSizePixel = 0
    progressBar.Parent = progressBg
    
    local progressCorner1 = Instance.new("UICorner")
    progressCorner1.CornerRadius = UDim.new(0, 2)
    progressCorner1.Parent = progressBg
    
    local progressCorner2 = Instance.new("UICorner")
    progressCorner2.CornerRadius = UDim.new(0, 2)
    progressCorner2.Parent = progressBar
    
    return itemFrame
end

--------------------------------------------------------------------
-- 更新冷却显示
--------------------------------------------------------------------
local function updateCooldownDisplay()
    -- 清除现有项目
    for _, child in ipairs(cooldownList:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    local itemCount = 0
    
    -- 显示机器冷却
    for machineType, machines in pairs(activeCooldowns.machines) do
        for instanceId, data in pairs(machines) do
            if data.remaining > 0 then
                createCooldownItem("machine", machineType, instanceId, data.remaining)
                itemCount = itemCount + 1
            end
        end
    end
    
    -- 显示系统冷却
    for systemName, data in pairs(activeCooldowns.systems) do
        if data.remaining > 0 then
            createCooldownItem("system", systemName, nil, data.remaining)
            itemCount = itemCount + 1
        end
    end
    
    -- 更新滚动框大小
    cooldownList.CanvasSize = UDim2.new(0, 0, 0, itemCount * 38)
    
    -- 如果没有冷却项目，显示提示
    if itemCount == 0 then
        local noItemsLabel = Instance.new("TextLabel")
        noItemsLabel.Size = UDim2.new(1, 0, 0, 40)
        noItemsLabel.Position = UDim2.new(0, 0, 0, 0)
        noItemsLabel.BackgroundTransparency = 1
        noItemsLabel.Text = "暂无冷却中的机器"
        noItemsLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        noItemsLabel.TextScaled = true
        noItemsLabel.Font = Enum.Font.SourceSans
        noItemsLabel.Parent = cooldownList
    end
end

--------------------------------------------------------------------
-- 更新单个项目的时间
--------------------------------------------------------------------
local function updateItemTime(itemFrame, remainingTime, maxTime)
    local timeLabel = itemFrame:FindFirstChild("TimeLabel")
    local progressBar = itemFrame:FindFirstChild("ProgressBar")
    
    if timeLabel then
        timeLabel.Text = string.format("%.1fs", remainingTime)
        timeLabel.TextColor3 = remainingTime > 0 and Color3.fromRGB(255, 150, 150) or Color3.fromRGB(150, 255, 150)
    end
    
    if progressBar then
        local progress = remainingTime > 0 and (1 - remainingTime / maxTime) or 1
        progressBar.Size = UDim2.new(progress, 0, 1, 0)
        progressBar.BackgroundColor3 = remainingTime > 0 and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 255, 100)
    end
end

--------------------------------------------------------------------
-- 切换冷却列表显示
--------------------------------------------------------------------
function toggleCooldownList()
    local listContainer = mainFrame:FindFirstChild("ListContainer")
    local toggleButton = mainFrame.TitleBar.ToggleButton
    
    if listContainer.Visible then
        -- 隐藏列表
        listContainer.Visible = false
        toggleButton.Text = "+"
        mainFrame.Size = UDim2.new(0, 280, 0, 35)
    else
        -- 显示列表
        listContainer.Visible = true
        toggleButton.Text = "_"
        mainFrame.Size = UDim2.new(0, 280, 0, 400)
    end
end

--------------------------------------------------------------------
-- 事件处理
--------------------------------------------------------------------

-- 监听冷却更新
cooldownUpdateEvent.OnClientEvent:Connect(function(data)
    if type(data) == "table" then
        if data.machines or data.systems then
            -- 完整冷却数据更新
            activeCooldowns = data
            updateCooldownDisplay()
        elseif data.type then
            -- 单个冷却更新
            if data.type == "machine" then
                if not activeCooldowns.machines[data.machineType] then
                    activeCooldowns.machines[data.machineType] = {}
                end
                activeCooldowns.machines[data.machineType][data.instanceId] = {
                    remaining = data.remainingTime,
                    maxTime = data.remainingTime
                }
            elseif data.type == "system" then
                activeCooldowns.systems[data.machineType] = {
                    remaining = data.remainingTime,
                    maxTime = data.remainingTime
                }
            end
            updateCooldownDisplay()
        end
    end
end)

-- 实时更新剩余时间
local lastUpdate = 0
RunService.Heartbeat:Connect(function()
    local currentTime = tick()
    if currentTime - lastUpdate >= 0.1 then -- 每0.1秒更新一次
        lastUpdate = currentTime
        
        local needsUpdate = false
        
        -- 更新机器冷却
        for machineType, machines in pairs(activeCooldowns.machines) do
            for instanceId, data in pairs(machines) do
                if data.remaining > 0 then
                    data.remaining = data.remaining - 0.1
                    if data.remaining <= 0 then
                        data.remaining = 0
                        needsUpdate = true
                    end
                end
            end
        end
        
        -- 更新系统冷却
        for systemName, data in pairs(activeCooldowns.systems) do
            if data.remaining > 0 then
                data.remaining = data.remaining - 0.1
                if data.remaining <= 0 then
                    data.remaining = 0
                    needsUpdate = true
                end
            end
        end
        
        -- 更新显示中的时间
        for _, itemFrame in ipairs(cooldownList:GetChildren()) do
            if itemFrame:IsA("Frame") and itemFrame.Name:match("_") then
                local parts = string.split(itemFrame.Name, "_")
                local itemType = parts[1]
                local itemName = parts[2]
                local instanceId = parts[3]
                
                local remainingTime = 0
                local maxTime = 1
                
                if itemType == "machine" then
                    local machineData = activeCooldowns.machines[itemName]
                    if machineData and machineData[instanceId] then
                        remainingTime = machineData[instanceId].remaining
                        maxTime = machineData[instanceId].maxTime or 1
                    end
                elseif itemType == "system" then
                    local systemData = activeCooldowns.systems[itemName]
                    if systemData then
                        remainingTime = systemData.remaining
                        maxTime = systemData.maxTime or 1
                    end
                end
                
                updateItemTime(itemFrame, remainingTime, maxTime)
            end
        end
        
        -- 如果有冷却完成，重新生成显示
        if needsUpdate then
            updateCooldownDisplay()
        end
    end
end)

-- 键盘快捷键
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.C then -- C键切换显示
        mainFrame.Visible = not mainFrame.Visible
        isUIVisible = mainFrame.Visible
    end
end)

--------------------------------------------------------------------
-- 初始化
--------------------------------------------------------------------
createCooldownUI()

-- 请求当前冷却状态
task.wait(1) -- 等待服务器准备就绪
cooldownUpdateEvent:FireServer("GET_ALL_COOLDOWNS")

print("[CooldownUI] 冷却状态界面已加载")
print("按 C 键切换冷却状态显示")