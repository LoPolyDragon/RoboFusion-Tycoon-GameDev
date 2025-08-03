--------------------------------------------------------------------
-- BuildingPlacement.client.lua · 建筑放置客户端系统
-- 功能：
--   1) 3D建筑预览和鼠标跟随
--   2) 网格对齐和碰撞检测
--   3) 放置确认和取消
--   4) 视觉反馈和提示
--------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

-- GameConstants
local GameConstants = require(ReplicatedStorage.SharedModules.GameConstants)

-- RemoteEvents (创建如果不存在)
local buildingEvents = ReplicatedStorage:FindFirstChild("BuildingEvents")
if not buildingEvents then
    buildingEvents = Instance.new("Folder")
    buildingEvents.Name = "BuildingEvents"
    buildingEvents.Parent = ReplicatedStorage
end

local placeBuildingEvent = buildingEvents:FindFirstChild("PlaceBuildingEvent")
if not placeBuildingEvent then
    placeBuildingEvent = Instance.new("RemoteEvent")
    placeBuildingEvent.Name = "PlaceBuildingEvent"
    placeBuildingEvent.Parent = buildingEvents
end

-- 建筑放置状态
local BuildingPlacement = {
    isPlacing = false,
    selectedBuildingType = nil,
    previewModel = nil,
    gridSize = GameConstants.BUILDING_PLACEMENT_RULES.gridSize or 2,
    previewConnection = nil
}

--------------------------------------------------------------------
-- 网格系统
--------------------------------------------------------------------

-- 世界坐标转网格坐标
local function worldToGrid(position)
    return Vector3.new(
        math.floor(position.X / BuildingPlacement.gridSize + 0.5) * BuildingPlacement.gridSize,
        position.Y,
        math.floor(position.Z / BuildingPlacement.gridSize + 0.5) * BuildingPlacement.gridSize
    )
end

-- 创建网格显示
local function createGridDisplay(position, size)
    local gridModel = Instance.new("Model")
    gridModel.Name = "GridDisplay"
    gridModel.Parent = workspace
    
    local gridSize = BuildingPlacement.gridSize
    local halfSizeX = math.ceil(size.X / gridSize / 2)
    local halfSizeZ = math.ceil(size.Z / gridSize / 2)
    
    -- 创建网格线
    for x = -halfSizeX, halfSizeX do
        for z = -halfSizeZ, halfSizeZ do
            local gridPart = Instance.new("Part")
            gridPart.Name = "GridCell"
            gridPart.Size = Vector3.new(gridSize - 0.1, 0.1, gridSize - 0.1)
            gridPart.Position = position + Vector3.new(x * gridSize, 0, z * gridSize)
            gridPart.Material = Enum.Material.Neon
            gridPart.BrickColor = BrickColor.new("Bright green")
            gridPart.Transparency = 0.7
            gridPart.CanCollide = false
            gridPart.Anchored = true
            gridPart.Parent = gridModel
        end
    end
    
    return gridModel
end

--------------------------------------------------------------------
-- 预览模型管理
--------------------------------------------------------------------

-- 获取建筑配置
local function getBuildingConfig(buildingType)
    for category, buildings in pairs(GameConstants.BUILDING_TYPES) do
        if buildings[buildingType] then
            return buildings[buildingType]
        end
    end
    return nil
end

-- 创建建筑预览模型
local function createPreviewModel(buildingType)
    local config = getBuildingConfig(buildingType)
    if not config then return nil end
    
    -- 查找预制模型
    local modelTemplate = game.ReplicatedStorage:FindFirstChild("BuildingPreviews")
    if modelTemplate then
        modelTemplate = modelTemplate:FindFirstChild(buildingType)
    end
    
    local previewModel
    if modelTemplate then
        previewModel = modelTemplate:Clone()
    else
        -- 创建简单预览模型
        previewModel = Instance.new("Model")
        previewModel.Name = buildingType .. "_Preview"
        
        local mainPart = Instance.new("Part")
        mainPart.Name = "MainPart"
        mainPart.Size = config.baseSize
        mainPart.Material = Enum.Material.ForceField
        mainPart.BrickColor = BrickColor.new("Bright blue")
        mainPart.Transparency = 0.5
        mainPart.CanCollide = false
        mainPart.Anchored = true
        mainPart.Parent = previewModel
        
        -- 添加建筑信息显示
        local billboardGui = Instance.new("BillboardGui")
        billboardGui.Size = UDim2.new(0, 200, 0, 50)
        billboardGui.StudsOffset = Vector3.new(0, config.baseSize.Y/2 + 2, 0)
        billboardGui.Parent = mainPart
        
        local infoFrame = Instance.new("Frame")
        infoFrame.Size = UDim2.new(1, 0, 1, 0)
        infoFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        infoFrame.BackgroundTransparency = 0.3
        infoFrame.BorderSizePixel = 0
        infoFrame.Parent = billboardGui
        
        local cornerRadius = Instance.new("UICorner")
        cornerRadius.CornerRadius = UDim.new(0, 8)
        cornerRadius.Parent = infoFrame
        
        local infoLabel = Instance.new("TextLabel")
        infoLabel.Size = UDim2.new(1, 0, 1, 0)
        infoLabel.BackgroundTransparency = 1
        infoLabel.Text = config.icon .. " " .. config.name
        infoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        infoLabel.TextScaled = true
        infoLabel.Font = Enum.Font.SourceSansBold
        infoLabel.Parent = infoFrame
    end
    
    -- 设置预览模型属性
    for _, part in ipairs(previewModel:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
            part.Anchored = true
        end
    end
    
    previewModel.Parent = workspace
    return previewModel
end

-- 更新预览模型位置
local function updatePreviewPosition()
    if not BuildingPlacement.previewModel then return end
    
    -- 获取鼠标射线
    local ray = camera:ScreenPointToRay(mouse.X, mouse.Y)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {BuildingPlacement.previewModel}
    
    local raycastResult = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
    
    if raycastResult then
        local hitPosition = raycastResult.Position
        local gridPosition = worldToGrid(hitPosition)
        
        -- 确保建筑在地面上
        gridPosition = Vector3.new(gridPosition.X, hitPosition.Y, gridPosition.Z)
        
        -- 设置预览模型位置
        local config = getBuildingConfig(BuildingPlacement.selectedBuildingType)
        if config then
            gridPosition = gridPosition + Vector3.new(0, config.baseSize.Y/2, 0)
        end
        
        BuildingPlacement.previewModel:SetPrimaryPartCFrame(CFrame.new(gridPosition))
        
        -- 检查是否可以放置（这里可以添加颜色变化来指示）
        -- 绿色 = 可以放置，红色 = 不能放置
        local canPlace = true -- 这里应该调用服务器验证，但为了性能可以做本地粗略检查
        
        for _, part in ipairs(BuildingPlacement.previewModel:GetDescendants()) do
            if part:IsA("BasePart") and part.Material == Enum.Material.ForceField then
                part.BrickColor = canPlace and BrickColor.new("Bright green") or BrickColor.new("Bright red")
            end
        end
    end
end

--------------------------------------------------------------------
-- 建筑放置控制
--------------------------------------------------------------------

-- 开始放置建筑
function BuildingPlacement.StartPlacing(buildingType)
    if BuildingPlacement.isPlacing then
        BuildingPlacement.StopPlacing()
    end
    
    local config = getBuildingConfig(buildingType)
    if not config then
        warn("[BuildingPlacement] 未找到建筑配置: " .. buildingType)
        return false
    end
    
    BuildingPlacement.isPlacing = true
    BuildingPlacement.selectedBuildingType = buildingType
    
    -- 创建预览模型
    BuildingPlacement.previewModel = createPreviewModel(buildingType)
    if not BuildingPlacement.previewModel then
        warn("[BuildingPlacement] 创建预览模型失败")
        BuildingPlacement.StopPlacing()
        return false
    end
    
    -- 开始位置更新循环
    BuildingPlacement.previewConnection = RunService.Heartbeat:Connect(updatePreviewPosition)
    
    -- 改变鼠标图标
    mouse.Icon = "rbxasset://textures/ArrowCursor.png"
    
    print("[BuildingPlacement] 开始放置建筑: " .. buildingType)
    return true
end

-- 停止放置建筑
function BuildingPlacement.StopPlacing()
    BuildingPlacement.isPlacing = false
    BuildingPlacement.selectedBuildingType = nil
    
    -- 清理预览模型
    if BuildingPlacement.previewModel then
        BuildingPlacement.previewModel:Destroy()
        BuildingPlacement.previewModel = nil
    end
    
    -- 停止位置更新
    if BuildingPlacement.previewConnection then
        BuildingPlacement.previewConnection:Disconnect()
        BuildingPlacement.previewConnection = nil
    end
    
    -- 恢复鼠标图标
    mouse.Icon = ""
    
    print("[BuildingPlacement] 停止放置建筑")
end

-- 确认放置建筑
function BuildingPlacement.ConfirmPlacement()
    if not BuildingPlacement.isPlacing or not BuildingPlacement.previewModel then
        return false
    end
    
    local position = BuildingPlacement.previewModel.PrimaryPart.Position
    local buildingType = BuildingPlacement.selectedBuildingType
    
    -- 发送放置请求到服务器
    placeBuildingEvent:FireServer("PLACE", {
        buildingType = buildingType,
        position = position,
        rotation = 0
    })
    
    -- 停止放置模式
    BuildingPlacement.StopPlacing()
    
    print("[BuildingPlacement] 确认放置建筑: " .. buildingType)
    return true
end

-- 旋转预览建筑
function BuildingPlacement.RotatePreview(angle)
    if not BuildingPlacement.previewModel then return end
    
    local currentCFrame = BuildingPlacement.previewModel.PrimaryPart.CFrame
    local newCFrame = currentCFrame * CFrame.Angles(0, math.rad(angle), 0)
    BuildingPlacement.previewModel:SetPrimaryPartCFrame(newCFrame)
end

--------------------------------------------------------------------
-- 输入处理
--------------------------------------------------------------------

-- 鼠标点击处理
mouse.Button1Down:Connect(function()
    if BuildingPlacement.isPlacing then
        BuildingPlacement.ConfirmPlacement()
    end
end)

-- 键盘输入处理
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.Escape then
        -- ESC键取消放置
        if BuildingPlacement.isPlacing then
            BuildingPlacement.StopPlacing()
        end
    elseif input.KeyCode == Enum.KeyCode.R then
        -- R键旋转建筑
        if BuildingPlacement.isPlacing then
            BuildingPlacement.RotatePreview(90)
        end
    end
end)

--------------------------------------------------------------------
-- 服务器响应处理
--------------------------------------------------------------------

placeBuildingEvent.OnClientEvent:Connect(function(action, data)
    if action == "PLACE_SUCCESS" then
        print("[BuildingPlacement] 建筑放置成功: " .. (data.buildingType or "Unknown"))
        
        -- 可以在这里添加成功效果
        local successSound = Instance.new("Sound")
        successSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
        successSound.Volume = 0.5
        successSound.Parent = workspace
        successSound:Play()
        successSound.Ended:Connect(function()
            successSound:Destroy()
        end)
        
    elseif action == "PLACE_FAILED" then
        print("[BuildingPlacement] 建筑放置失败: " .. (data.reason or "Unknown error"))
        
        -- 显示错误提示
        local errorGui = Instance.new("ScreenGui")
        errorGui.Name = "ErrorMessage"
        errorGui.Parent = player:WaitForChild("PlayerGui")
        
        local errorFrame = Instance.new("Frame")
        errorFrame.Size = UDim2.new(0, 300, 0, 60)
        errorFrame.Position = UDim2.new(0.5, -150, 0, 50)
        errorFrame.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        errorFrame.BorderSizePixel = 0
        errorFrame.Parent = errorGui
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = errorFrame
        
        local errorLabel = Instance.new("TextLabel")
        errorLabel.Size = UDim2.new(1, -20, 1, 0)
        errorLabel.Position = UDim2.new(0, 10, 0, 0)
        errorLabel.BackgroundTransparency = 1
        errorLabel.Text = "❌ " .. (data.reason or "建筑放置失败")
        errorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        errorLabel.TextScaled = true
        errorLabel.Font = Enum.Font.SourceSansBold
        errorLabel.Parent = errorFrame
        
        -- 3秒后自动消失
        task.wait(3)
        errorGui:Destroy()
    end
end)

--------------------------------------------------------------------
-- 公开API
--------------------------------------------------------------------

-- 将BuildingPlacement暴露给全局，以便其他脚本调用
_G.BuildingPlacement = BuildingPlacement

print("[BuildingPlacement] 建筑放置客户端系统已启动")
print("使用 _G.BuildingPlacement.StartPlacing(buildingType) 开始放置建筑")
print("ESC键取消放置，R键旋转建筑，左键确认放置")