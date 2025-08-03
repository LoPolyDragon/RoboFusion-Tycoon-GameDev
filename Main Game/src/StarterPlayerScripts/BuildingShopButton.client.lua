--------------------------------------------------------------------
-- BuildingShopButton.client.lua · 建筑商店按钮
-- 功能：在右上角显示建筑商店按钮，点击打开建筑商店
--------------------------------------------------------------------

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 创建Building Shop按钮UI
local function createBuildingShopButton()
    -- 创建ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BuildingShopButtonUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    -- 主按钮框架
    local buttonFrame = Instance.new("Frame")
    buttonFrame.Name = "ButtonFrame"
    buttonFrame.Size = UDim2.new(0, 120, 0, 50)
    buttonFrame.Position = UDim2.new(1, -140, 0, 20) -- 右上角位置
    buttonFrame.BackgroundTransparency = 1
    buttonFrame.Parent = screenGui
    
    -- Building Shop按钮
    local buildingShopButton = Instance.new("TextButton")
    buildingShopButton.Name = "BuildingShopButton"
    buildingShopButton.Size = UDim2.new(1, 0, 1, 0)
    buildingShopButton.Position = UDim2.new(0, 0, 0, 0)
    buildingShopButton.BackgroundColor3 = Color3.fromRGB(50, 120, 200)
    buildingShopButton.BorderSizePixel = 0
    buildingShopButton.Text = "🏗️ 建筑"
    buildingShopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    buildingShopButton.TextScaled = true
    buildingShopButton.Font = Enum.Font.SourceSansBold
    buildingShopButton.Parent = buttonFrame
    
    -- 圆角
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = buildingShopButton
    
    -- 添加阴影效果
    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 4, 1, 4)
    shadow.Position = UDim2.new(0, 2, 0, 2)
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.5
    shadow.BorderSizePixel = 0
    shadow.ZIndex = buildingShopButton.ZIndex - 1
    shadow.Parent = buttonFrame
    
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, 10)
    shadowCorner.Parent = shadow
    
    -- 悬停效果
    local hoverTween = TweenService:Create(
        buildingShopButton,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundColor3 = Color3.fromRGB(70, 140, 220)}
    )
    
    local normalTween = TweenService:Create(
        buildingShopButton,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundColor3 = Color3.fromRGB(50, 120, 200)}
    )
    
    buildingShopButton.MouseEnter:Connect(function()
        hoverTween:Play()
    end)
    
    buildingShopButton.MouseLeave:Connect(function()
        normalTween:Play()
    end)
    
    -- 点击事件
    buildingShopButton.MouseButton1Click:Connect(function()
        -- 播放点击动画
        local clickTween = TweenService:Create(
            buildingShopButton,
            TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
            {Size = UDim2.new(0.95, 0, 0.95, 0)}
        )
        
        local backTween = TweenService:Create(
            buildingShopButton,
            TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
            {Size = UDim2.new(1, 0, 1, 0)}
        )
        
        clickTween:Play()
        clickTween.Completed:Connect(function()
            backTween:Play()
        end)
        
        -- 打开Building Shop UI
        if _G.BuildingShopUI then
            if _G.BuildingShopUI.isOpen then
                _G.BuildingShopUI.CloseUI()
            else
                _G.BuildingShopUI.OpenUI()
            end
        else
            warn("[BuildingShopButton] BuildingShopUI未找到，请确保BuildingShopUI.client.lua已加载")
        end
    end)
    
    print("[BuildingShopButton] Building Shop按钮已创建")
    return screenGui
end

-- 等待一下确保其他UI脚本已加载
task.wait(2)

-- 创建按钮
createBuildingShopButton()

print("[BuildingShopButton] Building Shop按钮系统已启动")