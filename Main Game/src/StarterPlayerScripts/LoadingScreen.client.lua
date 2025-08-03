--------------------------------------------------------------------
-- LoadingScreen.client.lua · 游戏加载界面系统
-- 功能：
--   1) 显示NovaForge品牌加载界面
--   2) 实时显示加载进度
--   3) 播放加载动画
--   4) 等待所有系统初始化完成
--   5) 平滑过渡到游戏
--------------------------------------------------------------------

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 配置常量
local BACKGROUND_IMAGE_ID = "rbxassetid://130561589940679"
local ICON_IMAGE_ID = "rbxassetid://119892790145123"
local BRAND_NAME = "NovaForge"
local GAME_NAME = "RoboFusion Tycoon"

-- 加载状态
local LoadingScreen = {
    gui = nil,
    isActive = false,
    progress = 0,
    loadingTasks = {},
    currentTask = "初始化...",
}

-- 隐藏所有默认UI
local function hideDefaultUI()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
    print("[LoadingScreen] 已隐藏所有默认UI")
end

-- 恢复默认UI
local function showDefaultUI()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
    print("[LoadingScreen] 已恢复所有默认UI")
end

-- 创建加载界面
local function createLoadingUI()
    print("[LoadingScreen] 创建加载界面UI")
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "LoadingScreen"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    screenGui.DisplayOrder = 10 -- 最高优先级
    screenGui.IgnoreGuiInset = true -- 忽略顶部栏，真正全屏
    screenGui.Parent = playerGui

    -- 全屏黑色背景
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, 0, 1, 36) -- 多36像素确保完全覆盖
    background.Position = UDim2.new(0, 0, 0, -36)
    background.BackgroundColor3 = Color3.fromRGB(10, 15, 25) -- 深蓝黑色
    background.BorderSizePixel = 0
    background.ZIndex = 1
    background.Parent = screenGui
    
    -- 背景图片（虚化效果）
    local backgroundImage = Instance.new("ImageLabel")
    backgroundImage.Name = "BackgroundImage"
    backgroundImage.Size = UDim2.new(1.2, 0, 1.2, 0) -- 稍微放大
    backgroundImage.Position = UDim2.new(-0.1, 0, -0.1, 0)
    backgroundImage.Image = BACKGROUND_IMAGE_ID
    backgroundImage.ScaleType = Enum.ScaleType.Crop
    backgroundImage.BackgroundTransparency = 1
    backgroundImage.ImageTransparency = 0.5 -- 更强的虚化效果，只影响背景
    backgroundImage.ZIndex = 2
    backgroundImage.Parent = background
    
    -- 不再给lighting添加模糊效果，改为仅对背景图片使用ImageTransparency
    
    -- 背景遮罩（强化虚化效果，但不影响UI文字）
    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.6 -- 减少遮罩强度，让背景更虚化但UI清晰
    overlay.BorderSizePixel = 0
    overlay.ZIndex = 3
    overlay.Parent = background

    -- 主容器
    local mainContainer = Instance.new("Frame")
    mainContainer.Name = "MainContainer"
    mainContainer.Size = UDim2.new(0, 600, 0, 400)
    mainContainer.Position = UDim2.new(0.5, -300, 0.5, -200)
    mainContainer.BackgroundTransparency = 1
    mainContainer.ZIndex = 10 -- 确保在所有背景效果之上
    mainContainer.Parent = background

    -- 品牌图标
    local brandIcon = Instance.new("ImageLabel")
    brandIcon.Name = "BrandIcon"
    brandIcon.Size = UDim2.new(0, 120, 0, 120)
    brandIcon.Position = UDim2.new(0.5, -60, 0, 50)
    brandIcon.Image = ICON_IMAGE_ID
    brandIcon.BackgroundTransparency = 1
    brandIcon.ZIndex = 11 -- 确保可见
    brandIcon.Parent = mainContainer

    -- 添加图标发光效果
    local iconGlow = Instance.new("ImageLabel")
    iconGlow.Name = "IconGlow"
    iconGlow.Size = UDim2.new(1, 20, 1, 20)
    iconGlow.Position = UDim2.new(0, -10, 0, -10)
    iconGlow.Image = ICON_IMAGE_ID
    iconGlow.BackgroundTransparency = 1
    iconGlow.ImageColor3 = Color3.fromRGB(100, 200, 255)
    iconGlow.ImageTransparency = 0.7
    iconGlow.ZIndex = brandIcon.ZIndex - 1
    iconGlow.Parent = brandIcon

    -- 品牌名称
    local brandName = Instance.new("TextLabel")
    brandName.Name = "BrandName"
    brandName.Size = UDim2.new(1, 0, 0, 60)
    brandName.Position = UDim2.new(0, 0, 0, 180)
    brandName.Text = BRAND_NAME
    brandName.TextColor3 = Color3.fromRGB(255, 120, 50)
    brandName.TextSize = 48
    brandName.Font = Enum.Font.GothamBold
    brandName.TextXAlignment = Enum.TextXAlignment.Center
    brandName.BackgroundTransparency = 1
    brandName.ZIndex = 11 -- 确保文字可见
    brandName.Parent = mainContainer

    -- 添加文字描边
    local brandStroke = Instance.new("UIStroke")
    brandStroke.Color = Color3.fromRGB(0, 0, 0)
    brandStroke.Thickness = 3
    brandStroke.Parent = brandName

    -- 游戏名称
    local gameName = Instance.new("TextLabel")
    gameName.Name = "GameName"
    gameName.Size = UDim2.new(1, 0, 0, 30)
    gameName.Position = UDim2.new(0, 0, 0, 250)
    gameName.Text = GAME_NAME
    gameName.TextColor3 = Color3.fromRGB(255, 255, 255)
    gameName.TextSize = 24
    gameName.Font = Enum.Font.Gotham
    gameName.TextXAlignment = Enum.TextXAlignment.Center
    gameName.BackgroundTransparency = 1
    gameName.ZIndex = 11 -- 确保文字可见
    gameName.Parent = mainContainer

    -- 进度条背景
    local progressBg = Instance.new("Frame")
    progressBg.Name = "ProgressBackground"
    progressBg.Size = UDim2.new(0, 400, 0, 8)
    progressBg.Position = UDim2.new(0.5, -200, 0, 300)
    progressBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    progressBg.BorderSizePixel = 0
    progressBg.ZIndex = 11 -- 确保进度条可见
    progressBg.Parent = mainContainer

    local progressBgCorner = Instance.new("UICorner")
    progressBgCorner.CornerRadius = UDim.new(0, 4)
    progressBgCorner.Parent = progressBg

    -- 进度条
    local progressBar = Instance.new("Frame")
    progressBar.Name = "ProgressBar"
    progressBar.Size = UDim2.new(0, 0, 1, 0)
    progressBar.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
    progressBar.BorderSizePixel = 0
    progressBar.ZIndex = 12 -- 比背景稍高
    progressBar.Parent = progressBg

    local progressBarCorner = Instance.new("UICorner")
    progressBarCorner.CornerRadius = UDim.new(0, 4)
    progressBarCorner.Parent = progressBar

    -- 进度条发光效果
    local progressGlow = Instance.new("Frame")
    progressGlow.Name = "ProgressGlow"
    progressGlow.Size = UDim2.new(1, 10, 1, 10)
    progressGlow.Position = UDim2.new(0, -5, 0, -5)
    progressGlow.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
    progressGlow.BackgroundTransparency = 0.8
    progressGlow.BorderSizePixel = 0
    progressGlow.ZIndex = progressBar.ZIndex - 1
    progressGlow.Parent = progressBar

    local progressGlowCorner = Instance.new("UICorner")
    progressGlowCorner.CornerRadius = UDim.new(0, 8)
    progressGlowCorner.Parent = progressGlow

    -- 加载状态文本
    local loadingText = Instance.new("TextLabel")
    loadingText.Name = "LoadingText"
    loadingText.Size = UDim2.new(1, 0, 0, 25)
    loadingText.Position = UDim2.new(0, 0, 0, 320)
    loadingText.Text = "正在加载..."
    loadingText.TextColor3 = Color3.fromRGB(200, 200, 200)
    loadingText.TextSize = 16
    loadingText.Font = Enum.Font.Gotham
    loadingText.TextXAlignment = Enum.TextXAlignment.Center
    loadingText.BackgroundTransparency = 1
    loadingText.ZIndex = 11 -- 确保文字可见
    loadingText.Parent = mainContainer

    -- 进度百分比
    local progressPercent = Instance.new("TextLabel")
    progressPercent.Name = "ProgressPercent"
    progressPercent.Size = UDim2.new(0, 60, 0, 25)
    progressPercent.Position = UDim2.new(0.5, -30, 0, 350)
    progressPercent.Text = "0%"
    progressPercent.TextColor3 = Color3.fromRGB(255, 255, 255)
    progressPercent.TextSize = 18
    progressPercent.Font = Enum.Font.GothamBold
    progressPercent.TextXAlignment = Enum.TextXAlignment.Center
    progressPercent.BackgroundTransparency = 1
    progressPercent.ZIndex = 11 -- 确保文字可见
    progressPercent.Parent = mainContainer

    return {
        gui = screenGui,
        background = background,
        brandIcon = brandIcon,
        iconGlow = iconGlow,
        brandName = brandName,
        progressBar = progressBar,
        progressGlow = progressGlow,
        loadingText = loadingText,
        progressPercent = progressPercent,
    }
end

-- 不再播放图标旋转动画（根据用户要求）
local function playIconAnimation(iconGlow)
    -- 移除旋转动画，只保留发光效果
    local glowTween = TweenService:Create(
        iconGlow,
        TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        { ImageTransparency = 0.9 }
    )
    glowTween:Play()
    return glowTween
end

-- 播放品牌名称脉冲动画
local function playBrandPulseAnimation(brandName)
    local pulseTween = TweenService:Create(
        brandName,
        TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        { TextTransparency = 0.3 }
    )
    pulseTween:Play()
    return pulseTween
end

-- 更新加载进度
local function updateProgress(progress, taskName)
    if not LoadingScreen.gui then return end
    
    LoadingScreen.progress = math.clamp(progress, 0, 100)
    LoadingScreen.currentTask = taskName or LoadingScreen.currentTask
    
    -- 更新进度条
    local progressTween = TweenService:Create(
        LoadingScreen.gui.progressBar,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad),
        { Size = UDim2.new(LoadingScreen.progress / 100, 0, 1, 0) }
    )
    progressTween:Play()
    
    -- 更新文本
    LoadingScreen.gui.loadingText.Text = LoadingScreen.currentTask
    LoadingScreen.gui.progressPercent.Text = math.floor(LoadingScreen.progress) .. "%"
    
    print("[LoadingScreen] 进度更新:", LoadingScreen.progress .. "%", LoadingScreen.currentTask)
end

-- 显示加载界面
local function showLoadingScreen()
    if LoadingScreen.isActive then return end
    
    print("[LoadingScreen] 显示加载界面")
    
    -- 立即隐藏默认UI
    hideDefaultUI()
    
    LoadingScreen.isActive = true
    LoadingScreen.gui = createLoadingUI()
    
    -- 初始化动画
    LoadingScreen.gui.background.BackgroundColor3 = Color3.fromRGB(10, 15, 25)
    LoadingScreen.gui.brandIcon.ImageTransparency = 1
    LoadingScreen.gui.brandName.TextTransparency = 1
    
    -- 淡入动画
    local fadeInTween = TweenService:Create(
        LoadingScreen.gui.background,
        TweenInfo.new(0.5),
        { BackgroundTransparency = 0 }
    )
    
    local iconFadeIn = TweenService:Create(
        LoadingScreen.gui.brandIcon,
        TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { ImageTransparency = 0 }
    )
    
    local nameFadeIn = TweenService:Create(
        LoadingScreen.gui.brandName,
        TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { TextTransparency = 0 }
    )
    
    fadeInTween:Play()
    task.wait(0.3)
    iconFadeIn:Play()
    task.wait(0.2)
    nameFadeIn:Play()
    
    -- 启动动画
    playIconAnimation(LoadingScreen.gui.iconGlow)
    playBrandPulseAnimation(LoadingScreen.gui.brandName)
    
    updateProgress(0, "初始化游戏系统...")
end

-- 隐藏加载界面
local function hideLoadingScreen()
    if not LoadingScreen.isActive or not LoadingScreen.gui then return end
    
    print("[LoadingScreen] 隐藏加载界面")
    
    -- 恢复默认UI
    showDefaultUI()
    
    -- 重置摄像机
    local camera = workspace.CurrentCamera
    if camera then
        camera.CameraType = Enum.CameraType.Custom
        print("[LoadingScreen] 摄像机已重置为正常模式")
    end
    
    -- 无需移除模糊效果，因为我们没有添加任何lighting效果
    
    -- 直接销毁整个GUI（无需动画，避免透明问题）
    local screenGui = LoadingScreen.gui.gui
    
    task.spawn(function()
        task.wait(0.5) -- 短暂延迟让玩家看到100%
        screenGui:Destroy()
        LoadingScreen.gui = nil
        LoadingScreen.isActive = false
        
        -- 通知服务器客户端加载完成
        local loadingCompleteEvent = ReplicatedStorage.RemoteEvents:FindFirstChild("LoadingCompleteEvent")
        if loadingCompleteEvent then
            loadingCompleteEvent:FireServer() -- 通知服务器
        end
        
        print("[LoadingScreen] 加载界面已关闭，游戏准备就绪")
    end)
end

-- 等待远程事件准备
local function waitForRemoteEvents()
    updateProgress(10, "等待网络连接...")
    
    local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
    local rfFolder = ReplicatedStorage:WaitForChild("RemoteFunctions", 10)
    
    if remoteFolder and rfFolder then
        updateProgress(20, "网络连接已建立")
        return true
    else
        updateProgress(15, "网络连接超时")
        return false
    end
end

-- 等待玩家数据加载
local function waitForPlayerData()
    updateProgress(25, "加载玩家数据...")
    
    local attempts = 0
    while attempts < 30 do -- 最多等待30秒
        local rfFolder = ReplicatedStorage:FindFirstChild("RemoteFunctions")
        if rfFolder then
            local getDataRF = rfFolder:FindFirstChild("GetPlayerDataFunction")
            if getDataRF then
                local success, playerData = pcall(function()
                    return getDataRF:InvokeServer()
                end)
                
                if success and playerData then
                    updateProgress(40, "玩家数据加载完成")
                    return true
                end
            end
        end
        
        attempts = attempts + 1
        task.wait(1)
        updateProgress(25 + attempts, "等待玩家数据... (" .. attempts .. "/30)")
    end
    
    updateProgress(35, "玩家数据加载超时")
    return false
end

-- 监听服务器加载进度
local function setupServerProgressListener()
    local loadingProgressEvent = ReplicatedStorage.RemoteEvents:WaitForChild("LoadingProgressEvent")
    
    loadingProgressEvent.OnClientEvent:Connect(function(action, ...)
        local args = {...}
        
        if action == "SYSTEM_PROGRESS" then
            local systemName, progress, details = args[1], args[2], args[3]
            
            if systemName == "WorldSetup" then
                updateProgress(20 + (progress * 0.5), details or ("正在设置" .. systemName .. "..."))
            elseif systemName == "GameLogic" then
                updateProgress(10 + (progress * 0.1), details or ("正在加载" .. systemName .. "..."))
            elseif systemName == "TutorialSystem" then
                updateProgress(75 + (progress * 0.1), details or ("正在初始化" .. systemName .. "..."))
            elseif systemName == "EnergySystem" then
                updateProgress(85 + (progress * 0.05), details or ("正在启动" .. systemName .. "..."))
            end
            
        elseif action == "SYSTEM_COMPLETE" then
            local systemName = args[1]
            print("[LoadingScreen] 系统加载完成:", systemName)
            
        elseif action == "WORLD_READY" then
            updateProgress(100, "世界准备完成")
            LoadingScreen.worldReady = true -- 设置标志
            print("[LoadingScreen] 收到世界就绪信号，立即完成加载")
            
            -- 收到世界就绪信号立即隐藏加载界面
            task.spawn(function()
                task.wait(0.3) -- 短暂延迟显示100%
                hideLoadingScreen()
            end)
            
        elseif action == "OVERALL_PROGRESS" then
            local overallProgress = args[1]
            if overallProgress > LoadingScreen.progress then
                updateProgress(overallProgress, "系统初始化中...")
            end
        end
    end)
end

-- 等待UI系统加载
local function waitForUISystems()
    updateProgress(75, "初始化用户界面...")
    
    task.wait(2) -- 等待UI脚本加载
    
    -- 检查主要UI元素
    local buildShopUI = playerGui:FindFirstChild("BuildingShopButtonUI")
    if buildShopUI then
        updateProgress(85, "用户界面加载完成")
    else
        updateProgress(80, "用户界面部分加载")
    end
    
    return true
end

-- 预加载资源
local function preloadAssets()
    updateProgress(90, "预加载游戏资源...")
    
    local assetsToLoad = {
        BACKGROUND_IMAGE_ID,
        ICON_IMAGE_ID,
    }
    
    task.spawn(function()
        ContentProvider:PreloadAsync(assetsToLoad)
    end)
    
    task.wait(1)
    updateProgress(95, "资源预加载完成")
end

-- 主加载流程
local function startLoadingSequence()
    task.spawn(function()
        showLoadingScreen()
        
        -- 设置服务器进度监听
        setupServerProgressListener()
        
        -- 等待基础系统
        waitForRemoteEvents()
        
        -- 等待玩家数据
        waitForPlayerData()
        
        -- 等待UI系统
        waitForUISystems()
        
        -- 预加载资源
        preloadAssets()
        
        -- 等待服务器确认所有系统就绪
        LoadingScreen.worldReady = false
        local maxWaitTime = 30 -- 最多等待30秒
        local waitStart = tick()
        
        while not LoadingScreen.worldReady and (tick() - waitStart) < maxWaitTime do
            task.wait(0.1)
            -- worldReady状态会通过setupServerProgressListener设置
        end
        
        if not LoadingScreen.worldReady then
            print("[LoadingScreen] 等待超时，强制完成加载")
            updateProgress(95, "系统加载超时，继续进入游戏")
        end
        
        -- 完成加载
        updateProgress(100, "加载完成！")
        print("[LoadingScreen] 达到100%，准备隐藏加载界面")
        
        -- 立即隐藏加载界面
        hideLoadingScreen()
    end)
end

-- 启动加载
print("[LoadingScreen] 加载屏幕系统已初始化")
startLoadingSequence()

-- 导出接口
return LoadingScreen