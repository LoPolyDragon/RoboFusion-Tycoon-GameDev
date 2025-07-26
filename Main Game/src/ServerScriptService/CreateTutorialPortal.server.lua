--------------------------------------------------------------------
-- CreateTutorialPortal.server.lua · 创建教程传送门
-- 功能：为教程系统创建一个简单的MinePortal（如果不存在）
--------------------------------------------------------------------

local workspace = game:GetService("Workspace")

-- 检查是否已经存在MinePortal
local existingPortal = workspace:FindFirstChild("MinePortal")

if not existingPortal then
    print("[CreateTutorialPortal] 创建教程用MinePortal")
    
    -- 创建MinePortal模型
    local minePortal = Instance.new("Model")
    minePortal.Name = "MinePortal"
    minePortal.Parent = workspace
    
    -- 创建传送部件
    local teleportPart = Instance.new("Part")
    teleportPart.Name = "Teleport"
    teleportPart.Size = Vector3.new(8, 8, 2)
    teleportPart.Position = Vector3.new(0, 4, 20) -- 放在玩家附近
    teleportPart.Material = Enum.Material.Neon
    teleportPart.BrickColor = BrickColor.new("Bright blue")
    teleportPart.Anchored = true
    teleportPart.CanCollide = false
    teleportPart.Parent = minePortal
    
    -- 添加发光效果
    local selectionBox = Instance.new("SelectionBox")
    selectionBox.Adornee = teleportPart
    selectionBox.Color3 = Color3.fromRGB(0, 255, 255)
    selectionBox.LineThickness = 0.3
    selectionBox.Transparency = 0.5
    selectionBox.Parent = teleportPart
    
    -- 添加标签
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 200, 0, 50)
    billboardGui.StudsOffset = Vector3.new(0, 4, 0)
    billboardGui.Parent = teleportPart
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 1, 0)
    titleLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    titleLabel.BackgroundTransparency = 0.3
    titleLabel.Text = "🌍 矿区传送门"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = billboardGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = titleLabel
    
    -- 添加旋转动画
    local RunService = game:GetService("RunService")
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if minePortal.Parent then
            teleportPart.Rotation = teleportPart.Rotation + Vector3.new(0, 1, 0)
        else
            connection:Disconnect()
        end
    end)
    
    print("[CreateTutorialPortal] MinePortal 创建完成，位置:", teleportPart.Position)
else
    print("[CreateTutorialPortal] MinePortal 已存在，跳过创建")
end