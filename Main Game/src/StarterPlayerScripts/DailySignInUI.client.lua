--------------------------------------------------------------------
-- DailySignInUI.client.lua · 每日签到系统界面
-- 功能：
--   1) 每日签到弹窗
--   2) 签到奖励显示
--   3) 连续签到天数显示
--   4) VIP奖励特殊处理
--------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 远程通讯
local reFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local dailySignInPopupEvent = reFolder:WaitForChild("DailySignInPopupEvent")
local dailySignInEvent = reFolder:WaitForChild("DailySignInEvent")
local skipMissedDayEvent = reFolder:WaitForChild("SkipMissedDayEvent")

-- 加载配置
local GameConstants = require(ReplicatedStorage.SharedModules.GameConstants.main)
local DAILY_REWARDS = GameConstants.DAILY_REWARDS

--------------------------------------------------------------------
-- 创建每日签到UI
--------------------------------------------------------------------
local function createDailySignInUI()
    -- 主界面
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DailySignInUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui
    
    -- 背景遮罩
    local backdrop = Instance.new("Frame")
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    backdrop.BackgroundTransparency = 0.5
    backdrop.BorderSizePixel = 0
    backdrop.Visible = false
    backdrop.Parent = screenGui
    
    -- 主框架
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 500, 0, 400)
    mainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = backdrop
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = mainFrame
    
    -- 渐变背景
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 0)),
        ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 165, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 40))
    }
    gradient.Rotation = 45
    gradient.Parent = mainFrame
    
    -- 标题
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 60)
    titleLabel.Position = UDim2.new(0, 10, 0, 15)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🎁 每日签到奖励"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = mainFrame
    
    -- 奖励显示区域
    local rewardFrame = Instance.new("Frame")
    rewardFrame.Size = UDim2.new(1, -30, 0, 200)
    rewardFrame.Position = UDim2.new(0, 15, 0, 85)
    rewardFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    rewardFrame.BorderSizePixel = 0
    rewardFrame.Parent = mainFrame
    
    local rewardCorner = Instance.new("UICorner")
    rewardCorner.CornerRadius = UDim.new(0, 10)
    rewardCorner.Parent = rewardFrame
    
    -- 今日奖励
    local todayRewardLabel = Instance.new("TextLabel")
    todayRewardLabel.Size = UDim2.new(1, -20, 0, 40)
    todayRewardLabel.Position = UDim2.new(0, 10, 0, 10)
    todayRewardLabel.BackgroundTransparency = 1
    todayRewardLabel.Text = "今日奖励："
    todayRewardLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    todayRewardLabel.TextScaled = true
    todayRewardLabel.Font = Enum.Font.GothamBold
    todayRewardLabel.TextXAlignment = Enum.TextXAlignment.Left
    todayRewardLabel.Parent = rewardFrame
    
    local rewardIconLabel = Instance.new("TextLabel")
    rewardIconLabel.Size = UDim2.new(0, 80, 0, 80)
    rewardIconLabel.Position = UDim2.new(0, 10, 0, 55)
    rewardIconLabel.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    rewardIconLabel.Text = "📦"
    rewardIconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    rewardIconLabel.TextScaled = true
    rewardIconLabel.Font = Enum.Font.GothamBold
    rewardIconLabel.BorderSizePixel = 0
    rewardIconLabel.Parent = rewardFrame
    
    local rewardIconCorner = Instance.new("UICorner")
    rewardIconCorner.CornerRadius = UDim.new(0, 10)
    rewardIconCorner.Parent = rewardIconLabel
    
    local rewardDescLabel = Instance.new("TextLabel")
    rewardDescLabel.Size = UDim2.new(1, -110, 0, 80)
    rewardDescLabel.Position = UDim2.new(0, 100, 0, 55)
    rewardDescLabel.BackgroundTransparency = 1
    rewardDescLabel.Text = "奖励信息"
    rewardDescLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    rewardDescLabel.TextScaled = true
    rewardDescLabel.Font = Enum.Font.Gotham
    rewardDescLabel.TextXAlignment = Enum.TextXAlignment.Left
    rewardDescLabel.TextWrapped = true
    rewardDescLabel.Parent = rewardFrame
    
    -- 连续签到天数
    local streakLabel = Instance.new("TextLabel")
    streakLabel.Size = UDim2.new(1, -20, 0, 30)
    streakLabel.Position = UDim2.new(0, 10, 0, 150)
    streakLabel.BackgroundTransparency = 1
    streakLabel.Text = "连续签到: 1 天"
    streakLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    streakLabel.TextScaled = true
    streakLabel.Font = Enum.Font.GothamSemibold
    streakLabel.TextXAlignment = Enum.TextXAlignment.Left
    streakLabel.Parent = rewardFrame
    
    -- 按钮区域
    local buttonFrame = Instance.new("Frame")
    buttonFrame.Size = UDim2.new(1, -30, 0, 80)
    buttonFrame.Position = UDim2.new(0, 15, 1, -95)
    buttonFrame.BackgroundTransparency = 1
    buttonFrame.Parent = mainFrame
    
    -- 签到按钮
    local signInButton = Instance.new("TextButton")
    signInButton.Size = UDim2.new(0.45, 0, 0, 50)
    signInButton.Position = UDim2.new(0, 0, 0, 15)
    signInButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    signInButton.Text = "立即签到"
    signInButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    signInButton.TextScaled = true
    signInButton.Font = Enum.Font.GothamBold
    signInButton.BorderSizePixel = 0
    signInButton.Active = true
    signInButton.Parent = buttonFrame
    
    local signInCorner = Instance.new("UICorner")
    signInCorner.CornerRadius = UDim.new(0, 10)
    signInCorner.Parent = signInButton
    
    -- 关闭按钮
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0.45, 0, 0, 50)
    closeButton.Position = UDim2.new(0.55, 0, 0, 15)
    closeButton.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
    closeButton.Text = "稍后再说"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.GothamBold
    closeButton.BorderSizePixel = 0
    closeButton.Active = true
    closeButton.Parent = buttonFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 10)
    closeCorner.Parent = closeButton
    
    -- 跳过错过天数按钮（可选）
    local skipButton = Instance.new("TextButton")
    skipButton.Size = UDim2.new(1, 0, 0, 25)
    skipButton.Position = UDim2.new(0, 0, 1, -10)
    skipButton.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
    skipButton.Text = "💎 花费金币跳过错过的天数"
    skipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    skipButton.TextScaled = true
    skipButton.Font = Enum.Font.Gotham
    skipButton.BorderSizePixel = 0
    skipButton.Active = true
    skipButton.Visible = false -- 默认隐藏
    skipButton.Parent = buttonFrame
    
    local skipCorner = Instance.new("UICorner")
    skipCorner.CornerRadius = UDim.new(0, 5)
    skipCorner.Parent = skipButton
    
    return {
        gui = screenGui,
        backdrop = backdrop,
        mainFrame = mainFrame,
        titleLabel = titleLabel,
        rewardIconLabel = rewardIconLabel,
        rewardDescLabel = rewardDescLabel,
        streakLabel = streakLabel,
        signInButton = signInButton,
        closeButton = closeButton,
        skipButton = skipButton
    }
end

--------------------------------------------------------------------
-- 获取奖励信息
--------------------------------------------------------------------
local function getRewardInfo(dayIndex, isVIP)
    if dayIndex < 1 or dayIndex > #DAILY_REWARDS then
        return "未知奖励", "📦"
    end
    
    local reward = DAILY_REWARDS[dayIndex]
    local rewardType = reward.type
    local amount = reward.amount
    
    -- VIP第8天特殊奖励
    if dayIndex == 8 and isVIP then
        return "BronzePick x1 (VIP奖励)", "⛏️"
    end
    
    -- 图标映射
    local iconMap = {
        Scrap = "🔩",
        Credits = "💰",
        RustyShell = "🥚",
        WoodPick = "⛏️",
        TitaniumOre = "💎",
        EnergyCoreS = "⚡",
        NeonCoreShell = "✨"
    }
    
    local icon = iconMap[rewardType] or "📦"
    local description = string.format("%s x%d", rewardType, amount)
    
    return description, icon
end

--------------------------------------------------------------------
-- 主UI控制
--------------------------------------------------------------------
local dailySignInUI = nil

-- 显示每日签到UI
local function showDailySignInUI(dayIndex, isVIP)
    if not dailySignInUI then
        dailySignInUI = createDailySignInUI()
        
        -- 签到按钮事件
        dailySignInUI.signInButton.MouseButton1Click:Connect(function()
            dailySignInEvent:FireServer()
            hideDailySignInUI()
        end)
        
        -- 关闭按钮事件
        dailySignInUI.closeButton.MouseButton1Click:Connect(function()
            hideDailySignInUI()
        end)
        
        -- 跳过按钮事件
        dailySignInUI.skipButton.MouseButton1Click:Connect(function()
            skipMissedDayEvent:FireServer()
            hideDailySignInUI()
        end)
        
        -- 背景点击关闭
        dailySignInUI.backdrop.MouseButton1Click:Connect(function()
            hideDailySignInUI()
        end)
    end
    
    -- 更新UI内容
    local rewardDesc, rewardIcon = getRewardInfo(dayIndex, isVIP or false)
    dailySignInUI.rewardIconLabel.Text = rewardIcon
    dailySignInUI.rewardDescLabel.Text = rewardDesc
    dailySignInUI.streakLabel.Text = string.format("连续签到: %d 天", dayIndex)
    
    -- 检查是否需要显示跳过按钮
    -- 这里可以根据具体逻辑判断是否显示跳过按钮
    dailySignInUI.skipButton.Visible = false
    
    -- 显示动画
    dailySignInUI.backdrop.Visible = true
    dailySignInUI.mainFrame.Size = UDim2.new(0, 0, 0, 0)
    dailySignInUI.mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    local tween = TweenService:Create(dailySignInUI.mainFrame,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0, 500, 0, 400),
            Position = UDim2.new(0.5, -250, 0.5, -200)
        }
    )
    tween:Play()
    
    -- 奖励图标动画
    local iconTween = TweenService:Create(dailySignInUI.rewardIconLabel,
        TweenInfo.new(0.8, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
        {
            Rotation = 360
        }
    )
    iconTween:Play()
    
    iconTween.Completed:Connect(function()
        dailySignInUI.rewardIconLabel.Rotation = 0
    end)
end

-- 隐藏每日签到UI
function hideDailySignInUI()
    if not dailySignInUI then return end
    
    local tween = TweenService:Create(dailySignInUI.mainFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }
    )
    tween:Play()
    
    tween.Completed:Connect(function()
        dailySignInUI.backdrop.Visible = false
    end)
end

--------------------------------------------------------------------
-- 签到成功提示
--------------------------------------------------------------------
local function showSignInSuccessNotification(dayIndex, rewardInfo)
    -- 创建成功通知
    local notificationGui = Instance.new("ScreenGui")
    notificationGui.Name = "SignInSuccessNotification"
    notificationGui.ResetOnSpawn = false
    notificationGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    notificationGui.Parent = playerGui
    
    local notificationFrame = Instance.new("Frame")
    notificationFrame.Size = UDim2.new(0, 350, 0, 120)
    notificationFrame.Position = UDim2.new(0.5, -175, 0, -150)
    notificationFrame.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    notificationFrame.BorderSizePixel = 0
    notificationFrame.Parent = notificationGui
    
    local notificationCorner = Instance.new("UICorner")
    notificationCorner.CornerRadius = UDim.new(0, 10)
    notificationCorner.Parent = notificationFrame
    
    local successLabel = Instance.new("TextLabel")
    successLabel.Size = UDim2.new(1, -20, 0.6, 0)
    successLabel.Position = UDim2.new(0, 10, 0, 10)
    successLabel.BackgroundTransparency = 1
    successLabel.Text = "✅ 签到成功！"
    successLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    successLabel.TextScaled = true
    successLabel.Font = Enum.Font.GothamBold
    successLabel.Parent = notificationFrame
    
    local rewardLabel = Instance.new("TextLabel")
    rewardLabel.Size = UDim2.new(1, -20, 0.4, 0)
    rewardLabel.Position = UDim2.new(0, 10, 0.6, 0)
    rewardLabel.BackgroundTransparency = 1
    rewardLabel.Text = "获得奖励: " .. (rewardInfo or "未知")
    rewardLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    rewardLabel.TextScaled = true
    rewardLabel.Font = Enum.Font.Gotham
    rewardLabel.Parent = notificationFrame
    
    -- 滑入动画
    local slideInTween = TweenService:Create(notificationFrame,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Position = UDim2.new(0.5, -175, 0, 50)
        }
    )
    slideInTween:Play()
    
    -- 自动消失
    task.spawn(function()
        task.wait(3)
        
        local slideOutTween = TweenService:Create(notificationFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {
                Position = UDim2.new(0.5, -175, 0, -150)
            }
        )
        slideOutTween:Play()
        
        slideOutTween.Completed:Connect(function()
            notificationGui:Destroy()
        end)
    end)
end

--------------------------------------------------------------------
-- 事件处理
--------------------------------------------------------------------

-- 处理服务器发送的签到弹窗请求
dailySignInPopupEvent.OnClientEvent:Connect(function(dayIndex, isVIP)
    showDailySignInUI(dayIndex, isVIP)
end)

-- 处理签到结果
dailySignInEvent.OnClientEvent:Connect(function(success, dayIndex)
    if success then
        local rewardDesc, _ = getRewardInfo(dayIndex)
        showSignInSuccessNotification(dayIndex, rewardDesc)
    else
        -- 显示失败提示
        local errorGui = Instance.new("ScreenGui")
        errorGui.Name = "SignInError"
        errorGui.ResetOnSpawn = false
        errorGui.Parent = playerGui
        
        local errorFrame = Instance.new("Frame")
        errorFrame.Size = UDim2.new(0, 300, 0, 80)
        errorFrame.Position = UDim2.new(0.5, -150, 0, 50)
        errorFrame.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
        errorFrame.BorderSizePixel = 0
        errorFrame.Parent = errorGui
        
        local errorCorner = Instance.new("UICorner")
        errorCorner.CornerRadius = UDim.new(0, 8)
        errorCorner.Parent = errorFrame
        
        local errorLabel = Instance.new("TextLabel")
        errorLabel.Size = UDim2.new(1, -20, 1, 0)
        errorLabel.Position = UDim2.new(0, 10, 0, 0)
        errorLabel.BackgroundTransparency = 1
        errorLabel.Text = "❌ 今日已签到或签到失败"
        errorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        errorLabel.TextScaled = true
        errorLabel.Font = Enum.Font.GothamBold
        errorLabel.Parent = errorFrame
        
        task.spawn(function()
            task.wait(2)
            errorGui:Destroy()
        end)
    end
end)

-- 键盘快捷键 - 手动打开签到界面（测试用）
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end
    
    if input.KeyCode == Enum.KeyCode.F1 then
        -- 测试签到界面
        showDailySignInUI(1, false)
    end
end)

--------------------------------------------------------------------
-- 导出函数给其他UI使用
--------------------------------------------------------------------
local DailySignInUI = {}
DailySignInUI.showSignInUI = showDailySignInUI
DailySignInUI.hideSignInUI = hideDailySignInUI

-- 将函数暴露到全局作用域
_G.DailySignInUI = DailySignInUI

print("[DailySignInUI] 每日签到UI系统已加载")
print("按 F1 键测试签到界面")