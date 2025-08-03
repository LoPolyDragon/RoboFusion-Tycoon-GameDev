--------------------------------------------------------------------
-- MiningClient.client.lua · 完善的挖掘交互系统
-- 功能：
--   1) 检测玩家点击矿石方块
--   2) 显示挖掘进度条
--   3) 与MineMiningServer配合工作
--   4) 提供视觉和音效反馈
--------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- 等待RemoteEvent
local miningProgressEvent = ReplicatedStorage:WaitForChild("MiningProgressEvent")

-- GameConstants
local GameConstants = require(ReplicatedStorage.SharedModules.GameConstants)

-- UI Variables
local screenGui = nil
local progressFrame = nil
local progressBar = nil
local progressText = nil
local oreIcon = nil

-- Mining state
local isMining = false
local currentOre = nil
local miningTween = nil

--------------------------------------------------------------------
-- 创建挖掘进度UI
--------------------------------------------------------------------
local function createMiningUI()
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MiningUI"
    screenGui.Parent = player:WaitForChild("PlayerGui")
    
    -- 主框架
    progressFrame = Instance.new("Frame")
    progressFrame.Name = "ProgressFrame"
    progressFrame.Size = UDim2.new(0, 300, 0, 80)
    progressFrame.Position = UDim2.new(0.5, -150, 0.8, -40)
    progressFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    progressFrame.BackgroundTransparency = 0.2
    progressFrame.BorderSizePixel = 0
    progressFrame.Visible = false
    progressFrame.Parent = screenGui
    
    -- 圆角
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = progressFrame
    
    -- 矿石图标
    oreIcon = Instance.new("ImageLabel")
    oreIcon.Name = "OreIcon"
    oreIcon.Size = UDim2.new(0, 60, 0, 60)
    oreIcon.Position = UDim2.new(0, 10, 0.5, -30)
    oreIcon.BackgroundTransparency = 1
    oreIcon.Image = "rbxasset://textures/face.png" -- 默认图标
    oreIcon.Parent = progressFrame
    
    -- 进度条背景
    local progressBg = Instance.new("Frame")
    progressBg.Name = "ProgressBg"
    progressBg.Size = UDim2.new(0, 200, 0, 20)
    progressBg.Position = UDim2.new(0, 80, 0, 20)
    progressBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    progressBg.BorderSizePixel = 0
    progressBg.Parent = progressFrame
    
    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(0, 10)
    progressCorner.Parent = progressBg
    
    -- 进度条
    progressBar = Instance.new("Frame")
    progressBar.Name = "ProgressBar"
    progressBar.Size = UDim2.new(0, 0, 1, 0)
    progressBar.Position = UDim2.new(0, 0, 0, 0)
    progressBar.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
    progressBar.BorderSizePixel = 0
    progressBar.Parent = progressBg
    
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 10)
    barCorner.Parent = progressBar
    
    -- 进度文本
    progressText = Instance.new("TextLabel")
    progressText.Name = "ProgressText"
    progressText.Size = UDim2.new(0, 200, 0, 30)
    progressText.Position = UDim2.new(0, 80, 0, 45)
    progressText.BackgroundTransparency = 1
    progressText.Text = "挖掘中..."
    progressText.TextColor3 = Color3.fromRGB(255, 255, 255)
    progressText.TextScaled = true
    progressText.Font = Enum.Font.SourceSansBold
    progressText.Parent = progressFrame
end

--------------------------------------------------------------------
-- 获取矿石信息和图标
--------------------------------------------------------------------
local function getOreInfo(oreName)
    local oreInfo = GameConstants.ORE_INFO[oreName]
    if not oreInfo then
        return nil
    end
    
    -- 矿石图标映射
    local oreIcons = {
        Scrap = "rbxasset://textures/face.png",
        Stone = "rbxasset://textures/face.png",
        IronOre = "rbxasset://textures/face.png",
        BronzeOre = "rbxasset://textures/face.png",
        GoldOre = "rbxasset://textures/face.png",
        DiamondOre = "rbxasset://textures/face.png",
        TitaniumOre = "rbxasset://textures/face.png",
        UraniumOre = "rbxasset://textures/face.png"
    }
    
    return {
        hardness = oreInfo.hardness,
        time = oreInfo.time,
        icon = oreIcons[oreName] or "rbxasset://textures/face.png",
        displayName = oreName
    }
end

--------------------------------------------------------------------
-- 显示挖掘进度
--------------------------------------------------------------------
local function showMiningProgress(oreName, duration)
    if not progressFrame then return end
    
    local oreInfo = getOreInfo(oreName)
    if not oreInfo then return end
    
    -- 设置矿石信息
    oreIcon.Image = oreInfo.icon
    progressText.Text = "正在挖掘 " .. oreInfo.displayName .. "..."
    
    -- 显示UI
    progressFrame.Visible = true
    progressBar.Size = UDim2.new(0, 0, 1, 0)
    
    -- 进度条动画
    miningTween = TweenService:Create(progressBar, 
        TweenInfo.new(duration, Enum.EasingStyle.Linear), 
        {Size = UDim2.new(1, 0, 1, 0)}
    )
    miningTween:Play()
    
    -- 呼吸效果
    local breatheTween = TweenService:Create(progressFrame,
        TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {BackgroundTransparency = 0.1}
    )
    breatheTween:Play()
end

--------------------------------------------------------------------
-- 隐藏挖掘进度
--------------------------------------------------------------------
local function hideMiningProgress()
    if not progressFrame then return end
    
    progressFrame.Visible = false
    if miningTween then
        miningTween:Cancel()
        miningTween = nil
    end
end

--------------------------------------------------------------------
-- 检查是否可以挖掘
--------------------------------------------------------------------
local function canMineOre(oreName)
    if not player.Character then return false end
    
    local tool = player.Character:FindFirstChildWhichIsA("Tool")
    if not tool then return false end
    
    local pickInfo = GameConstants.PICKAXE_INFO and GameConstants.PICKAXE_INFO[tool.Name]
    local oreInfo = GameConstants.ORE_INFO[oreName]
    
    if not pickInfo or not oreInfo then return false end
    
    return pickInfo.maxHardness >= oreInfo.hardness
end

--------------------------------------------------------------------
-- 处理矿石点击
--------------------------------------------------------------------
local function onOreClicked(part)
    if isMining then return end
    if not part or not part.Parent then return end
    
    -- 检查是否是矿石
    local oreName = part.Name
    local oreInfo = GameConstants.ORE_INFO[oreName]
    if not oreInfo then return end
    
    -- 检查是否可以挖掘
    if not canMineOre(oreName) then
        showError("需要更高级的镐子!")
        return
    end
    
    -- 开始挖掘
    currentOre = part
    isMining = true
    miningProgressEvent:FireServer("BEGIN", part)
end

--------------------------------------------------------------------
-- 监听鼠标点击
--------------------------------------------------------------------
mouse.Button1Down:Connect(function()
    if not mouse.Target then return end
    onOreClicked(mouse.Target)
end)

--------------------------------------------------------------------
-- 显示错误信息
--------------------------------------------------------------------
local function showError(message)
	if not progressFrame then return end
	
	progressFrame.Visible = true
	progressText.Text = message or "发生错误"
	progressBar.BackgroundColor3 = Color3.fromRGB(255, 100, 100) -- 红色表示错误
	progressBar.Size = UDim2.new(1, 0, 1, 0)
	
	-- 2秒后隐藏
	task.spawn(function()
		task.wait(2)
		hideMiningProgress()
		progressBar.BackgroundColor3 = Color3.fromRGB(100, 200, 100) -- 恢复正常颜色
	end)
end

--------------------------------------------------------------------
-- 显示成功信息
--------------------------------------------------------------------
local function showSuccess(oreName)
	if not progressFrame then return end
	
	progressFrame.Visible = true
	progressText.Text = "成功挖掘 " .. (oreName or "矿石") .. "!"
	progressBar.BackgroundColor3 = Color3.fromRGB(100, 255, 100) -- 绿色表示成功
	progressBar.Size = UDim2.new(1, 0, 1, 0)
	
	-- 添加成功动画效果
	local successTween = TweenService:Create(progressFrame,
		TweenInfo.new(0.3, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
		{Size = UDim2.new(0, 320, 0, 90)}
	)
	successTween:Play()
	
	-- 2秒后隐藏
	task.spawn(function()
		task.wait(2)
		hideMiningProgress()
		progressBar.BackgroundColor3 = Color3.fromRGB(100, 200, 100) -- 恢复正常颜色
		progressFrame.Size = UDim2.new(0, 300, 0, 80) -- 恢复原始大小
	end)
end

--------------------------------------------------------------------
-- 监听服务器响应
--------------------------------------------------------------------
miningProgressEvent.OnClientEvent:Connect(function(cmd, data)
    if cmd == "BEGIN" then
        local duration = data or 1
        if currentOre then
            showMiningProgress(currentOre.Name, duration)
        end
    elseif cmd == "END" then
        -- 旧版本的结束信号，保持兼容性
        hideMiningProgress()
        isMining = false
        currentOre = nil
    elseif cmd == "SUCCESS" then
        -- 挖掘成功
        hideMiningProgress()
        showSuccess(data)
        isMining = false
        currentOre = nil
    elseif cmd == "ERROR" then
        -- 挖掘错误
        showError(data)
        isMining = false
        currentOre = nil
    end
end)

--------------------------------------------------------------------
-- 取消挖掘 (右键或移动)
--------------------------------------------------------------------
mouse.Button2Down:Connect(function()
    if isMining then
        miningProgressEvent:FireServer("CANCEL")
        hideMiningProgress()
        isMining = false
        currentOre = nil
    end
end)

-- 监听玩家移动取消挖掘
local lastPosition = nil
RunService.Heartbeat:Connect(function()
    if not isMining or not player.Character or not player.Character.PrimaryPart then
        return
    end
    
    local currentPos = player.Character.PrimaryPart.Position
    if lastPosition then
        local distance = (currentPos - lastPosition).Magnitude
        if distance > 5 then -- 如果移动超过5格，取消挖掘
            miningProgressEvent:FireServer("CANCEL")
            hideMiningProgress()
            isMining = false
            currentOre = nil
        end
    end
    lastPosition = currentPos
end)

--------------------------------------------------------------------
-- 初始化
--------------------------------------------------------------------
createMiningUI()
print("[MiningClient] 挖掘系统已启动")
print("左键点击矿石开始挖掘，右键取消挖掘")