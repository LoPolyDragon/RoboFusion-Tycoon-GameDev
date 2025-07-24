--------------------------------------------------------------------
-- SimpleShopUI.client.lua · 简化的Game Pass商店界面
-- 功能：右下角Shop按钮和Game Pass购买界面
--------------------------------------------------------------------

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Game Pass配置
local SHOP_GAME_PASSES = {
    {
        id = 1247751921,  -- VIP
        name = "VIP",
        price = 99,
        icon = "rbxassetid://139418003070407",
        description = "Unlock VIP privileges and exclusive benefits"
    },
    {
        id = 1249719442,  -- AutoCollect
        name = "Auto Collect",
        price = 229,
        icon = "rbxassetid://112718136991722", 
        description = "Automatically collect all resources"
    }
}

-- 创建右下角Shop按钮
local function createShopButton()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SimpleShopButtonUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    local shopButton = Instance.new("TextButton")
    shopButton.Size = UDim2.new(0, 70, 0, 70)
    shopButton.Position = UDim2.new(1, -90, 1, -90)
    shopButton.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
    shopButton.Text = "🛒\nSHOP"
    shopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    shopButton.TextSize = 14
    shopButton.Font = Enum.Font.GothamBold
    shopButton.BorderSizePixel = 0
    shopButton.Active = true
    shopButton.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 35)
    corner.Parent = shopButton
    
    return screenGui, shopButton
end

-- 创建Shop界面
local function createShopUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SimpleShopUI"
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
    mainFrame.Size = UDim2.new(0, 600, 0, 400)
    mainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
    mainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = mainFrame
    
    -- 标题栏
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -60, 0, 40)
    titleLabel.Position = UDim2.new(0, 20, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🛒 GAME PASS SHOP"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 20
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = mainFrame
    
    -- 关闭按钮
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -40, 0, 10)
    closeButton.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
    closeButton.Text = "×"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 18
    closeButton.Font = Enum.Font.GothamBold
    closeButton.BorderSizePixel = 0
    closeButton.Active = true
    closeButton.Parent = mainFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeButton
    
    -- 内容区域
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Size = UDim2.new(1, -40, 1, -70)
    contentFrame.Position = UDim2.new(0, 20, 0, 60)
    contentFrame.BackgroundTransparency = 1
    contentFrame.ScrollBarThickness = 6
    contentFrame.Parent = mainFrame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 15)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = contentFrame
    
    return screenGui, background, mainFrame, closeButton, contentFrame
end

-- 创建Game Pass卡片 (简化版)
local function createGamePassCard(gamePassInfo, parent, layoutOrder)
    local cardFrame = Instance.new("Frame")
    cardFrame.Size = UDim2.new(1, 0, 0, 80)
    cardFrame.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    cardFrame.BorderSizePixel = 0
    cardFrame.LayoutOrder = layoutOrder
    cardFrame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = cardFrame
    
    -- 图标
    local iconLabel = Instance.new("ImageLabel")
    iconLabel.Size = UDim2.new(0, 50, 0, 50)
    iconLabel.Position = UDim2.new(0, 15, 0, 15)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Image = gamePassInfo.icon
    iconLabel.ScaleType = Enum.ScaleType.Fit
    iconLabel.Parent = cardFrame
    
    -- 名称
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.4, 0, 0, 25)
    nameLabel.Position = UDim2.new(0, 75, 0, 10)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = gamePassInfo.name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextSize = 18
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = cardFrame
    
    -- 描述
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(0.4, 0, 0, 35)
    descLabel.Position = UDim2.new(0, 75, 0, 35)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = gamePassInfo.description
    descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    descLabel.TextSize = 12
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.TextWrapped = true
    descLabel.Parent = cardFrame
    
    -- 价格
    local priceLabel = Instance.new("TextLabel")
    priceLabel.Size = UDim2.new(0, 80, 0, 20)
    priceLabel.Position = UDim2.new(1, -100, 0, 10)
    priceLabel.BackgroundTransparency = 1
    priceLabel.Text = gamePassInfo.price .. " R$"
    priceLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    priceLabel.TextSize = 16
    priceLabel.Font = Enum.Font.GothamBold
    priceLabel.TextXAlignment = Enum.TextXAlignment.Right
    priceLabel.Parent = cardFrame
    
    -- 检查是否已拥有
    local hasPass = false
    if RunService:IsStudio() then
        hasPass = false  -- Studio中显示为未拥有，便于测试
    else
        local success = pcall(function()
            hasPass = MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamePassInfo.id)
        end)
    end
    
    -- 购买按钮
    local buyButton = Instance.new("TextButton")
    buyButton.Size = UDim2.new(0, 80, 0, 30)
    buyButton.Position = UDim2.new(1, -100, 0, 40)
    buyButton.BackgroundColor3 = hasPass and Color3.fromRGB(100, 100, 100) or Color3.fromRGB(0, 162, 255)
    buyButton.Text = hasPass and "✓ OWNED" or "BUY NOW"
    buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    buyButton.TextSize = 12
    buyButton.Font = Enum.Font.GothamBold
    buyButton.BorderSizePixel = 0
    buyButton.Active = not hasPass
    buyButton.Parent = cardFrame
    
    local buyCorner = Instance.new("UICorner")
    buyCorner.CornerRadius = UDim.new(0, 8)
    buyCorner.Parent = buyButton
    
    -- 购买事件
    if not hasPass then
        buyButton.MouseButton1Click:Connect(function()
            print("[SimpleShopUI] 尝试购买Game Pass:", gamePassInfo.name, "ID:", gamePassInfo.id)
            local success = pcall(function()
                MarketplaceService:PromptGamePassPurchase(player, gamePassInfo.id)
            end)
            if not success then
                print("[SimpleShopUI] 购买提示失败")
            end
        end)
    end
end

-- 主控制
local shopButtonUI = nil
local shopUI = nil

-- 隐藏Shop界面 (提前定义)
local function hideShop()
    if not shopUI then return end
    
    print("[SimpleShopUI] 隐藏Shop界面")
    
    local tween = TweenService:Create(shopUI.mainFrame,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }
    )
    tween:Play()
    
    tween.Completed:Connect(function()
        shopUI.background.Visible = false
        shopUI.mainFrame.Visible = false
        print("[SimpleShopUI] Shop界面已隐藏")
    end)
end

-- 显示Shop界面
local function showShop()
    print("[SimpleShopUI] 显示Shop界面")
    
    if not shopUI then
        print("[SimpleShopUI] 创建新的Shop UI")
        local ui, background, mainFrame, closeButton, contentFrame = createShopUI()
        
        shopUI = {
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
        
        -- 背景点击关闭 (创建透明按钮)
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
        
        -- 创建Game Pass卡片
        print("[SimpleShopUI] 创建Game Pass卡片")
        for i, gamePassInfo in ipairs(SHOP_GAME_PASSES) do
            print("[SimpleShopUI] 创建卡片:", gamePassInfo.name)
            createGamePassCard(gamePassInfo, contentFrame, i)
        end
        
        -- 设置滚动区域大小 (简化卡片高度80)
        task.wait(0.1)
        contentFrame.CanvasSize = UDim2.new(0, 0, 0, #SHOP_GAME_PASSES * 95)
        print("[SimpleShopUI] 设置滚动区域大小:", #SHOP_GAME_PASSES * 95)
    end
    
    -- 显示动画
    shopUI.background.Visible = true
    shopUI.mainFrame.Visible = true
    shopUI.mainFrame.Size = UDim2.new(0, 0, 0, 0)
    shopUI.mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    local tween = TweenService:Create(shopUI.mainFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0, 600, 0, 400),
            Position = UDim2.new(0.5, -300, 0.5, -200)
        }
    )
    tween:Play()
end


-- 初始化
local function initializeShop()
    local buttonUI, shopButton = createShopButton()
    shopButtonUI = { gui = buttonUI, button = shopButton }
    
    shopButton.MouseButton1Click:Connect(function()
        showShop()
    end)
    
    print("[SimpleShopUI] Shop按钮创建完成")
end

-- ESC键关闭
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end
    
    if input.KeyCode == Enum.KeyCode.Escape and shopUI and shopUI.mainFrame.Visible then
        hideShop()
    end
end)

-- 启动
task.spawn(function()
    task.wait(2)
    initializeShop()
    print("[SimpleShopUI] 简化Shop系统已加载")
end)

print("[SimpleShopUI] 简化Shop UI系统已启动")