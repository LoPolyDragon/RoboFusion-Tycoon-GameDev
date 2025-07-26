--------------------------------------------------------------------
-- TinyGamePassUI.client.lua · 超小Game Pass图标显示
-- 功能：左下角只显示Game Pass图标，不占用空间
--------------------------------------------------------------------

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Game Pass配置
local GAME_PASSES = {
    {
        id = 1247751921,  -- VIP
        name = "VIP",
        icon = "👑"  -- 皇冠图标
    },
    {
        id = 1249719442,  -- AutoCollect
        name = "Auto Collect", 
        icon = "🤖"  -- 机器人图标
    }
}

-- 检查Game Pass所有权
local function checkGamePassOwnership(gamePassId)
    if RunService:IsStudio() then
        return true  -- Studio中显示为拥有
    end
    
    local success, hasPass = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamePassId)
    end)
    
    return success and hasPass
end

-- 创建超小Game Pass图标UI
local function createTinyGamePassUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TinyGamePassUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    -- 容器 - 左下角
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, 80, 0, 40)
    container.Position = UDim2.new(0, 10, 1, -50)
    container.BackgroundTransparency = 1
    container.Parent = screenGui
    
    -- 水平布局
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 5)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Parent = container
    
    local ownedCount = 0
    
    -- 创建Game Pass图标
    for i, gamePassInfo in ipairs(GAME_PASSES) do
        local hasPass = checkGamePassOwnership(gamePassInfo.id)
        
        if hasPass then
            ownedCount = ownedCount + 1
            
            -- 图标容器
            local iconFrame = Instance.new("Frame")
            iconFrame.Size = UDim2.new(0, 35, 0, 35)
            iconFrame.BackgroundColor3 = Color3.fromRGB(70, 130, 70)
            iconFrame.BorderSizePixel = 0
            iconFrame.LayoutOrder = i
            iconFrame.Parent = container
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = iconFrame
            
            -- 发光边框
            local stroke = Instance.new("UIStroke")
            stroke.Color = Color3.fromRGB(100, 255, 100)
            stroke.Thickness = 2
            stroke.Parent = iconFrame
            
            -- 图标
            local iconLabel = Instance.new("TextLabel")
            iconLabel.Size = UDim2.new(1, 0, 1, 0)
            iconLabel.BackgroundTransparency = 1
            iconLabel.Text = gamePassInfo.icon
            iconLabel.TextSize = 20
            iconLabel.Font = Enum.Font.GothamBold
            iconLabel.Parent = iconFrame
            
            -- 工具提示（悬停显示名称）
            local tooltip = Instance.new("TextLabel")
            tooltip.Size = UDim2.new(0, 80, 0, 25)
            tooltip.Position = UDim2.new(0.5, -40, 0, -30)
            tooltip.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            tooltip.BackgroundTransparency = 0.3
            tooltip.Text = gamePassInfo.name
            tooltip.TextColor3 = Color3.fromRGB(255, 255, 255)
            tooltip.TextSize = 12
            tooltip.Font = Enum.Font.Gotham
            tooltip.BorderSizePixel = 0
            tooltip.Visible = false
            tooltip.Parent = iconFrame
            
            local tooltipCorner = Instance.new("UICorner")
            tooltipCorner.CornerRadius = UDim.new(0, 4)
            tooltipCorner.Parent = tooltip
            
            -- 悬停事件
            iconFrame.MouseEnter:Connect(function()
                tooltip.Visible = true
            end)
            
            iconFrame.MouseLeave:Connect(function()
                tooltip.Visible = false
            end)
        end
    end
    
    print("[TinyGamePassUI] 显示", ownedCount, "个拥有的Game Pass图标")
    
    -- 如果没有拥有任何Game Pass，隐藏整个UI
    if ownedCount == 0 then
        container.Visible = false
        print("[TinyGamePassUI] 没有拥有的Game Pass，隐藏UI")
    end
end

-- 启动
task.spawn(function()
    task.wait(3)  -- 等待其他系统加载
    createTinyGamePassUI()
end)

print("[TinyGamePassUI] 超小Game Pass图标UI系统已启动")