-- 客户端机器管理系统
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- 等待远程事件
local saveMachineEvent = ReplicatedStorage:WaitForChild("SaveMachine")
local loadMachinesEvent = ReplicatedStorage:WaitForChild("LoadMachines")

-- 机器管理状态
local isBuildMode = false
local selectedMachineType = nil
local previewMachine = nil
local placedMachines = {}

-- 机器类型配置
local MACHINE_TYPES = {
    "Generator",
    "Crusher", 
    "Assembler",
    "Shipper",
    "EnergyMachine"
}

-- 创建建造模式UI
local function createBuildUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MachineBuilderUI"
    screenGui.Parent = player.PlayerGui
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 300, 0, 400)
    mainFrame.Position = UDim2.new(0, 10, 0.5, -200)
    mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    -- 标题
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    title.BorderSizePixel = 0
    title.Text = "机器建造面板"
    title.TextColor3 = Color3.white
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.Parent = mainFrame
    
    -- 机器按钮容器
    local buttonContainer = Instance.new("ScrollingFrame")
    buttonContainer.Size = UDim2.new(1, -20, 1, -60)
    buttonContainer.Position = UDim2.new(0, 10, 0, 50)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.BorderSizePixel = 0
    buttonContainer.CanvasSize = UDim2.new(0, 0, 0, #MACHINE_TYPES * 60)
    buttonContainer.Parent = mainFrame
    
    -- 创建机器按钮
    for i, machineType in ipairs(MACHINE_TYPES) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, -10, 0, 50)
        button.Position = UDim2.new(0, 5, 0, (i-1) * 60)
        button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        button.BorderSizePixel = 0
        button.Text = machineType
        button.TextColor3 = Color3.white
        button.TextScaled = true
        button.Font = Enum.Font.SourceSans
        button.Parent = buttonContainer
        
        -- 按钮点击事件
        button.MouseButton1Click:Connect(function()
            selectedMachineType = machineType
            startBuildMode(machineType)
        end)
    end
    
    return screenGui
end

-- 获取机器的实际尺寸
local function getMachineSize(machineType)
    -- 这些是基于MeshPart的InitialSize计算出的实际尺寸
    local machineSizes = {
        Generator = Vector3.new(50, 38.68, 50),
        Crusher = Vector3.new(50, 42.28, 50), 
        Assembler = Vector3.new(41.86, 42.99, 41.86),
        Shipper = Vector3.new(47.85, 50, 47.85),
        EnergyMachine = Vector3.new(50, 34.59, 50)
    }
    
    return machineSizes[machineType] or Vector3.new(50, 50, 50)
end

-- 获取建议框架尺寸（留2 studs边距）
local function getFrameworkSize(machineType)
    local machineSize = getMachineSize(machineType)
    return Vector3.new(
        machineSize.X + 2,
        machineSize.Y + 2, 
        machineSize.Z + 2
    )
end

-- 开始建造模式
function startBuildMode(machineType)
    isBuildMode = true
    selectedMachineType = machineType
    
    print("开始建造模式:", machineType)
    
    -- 创建预览模型（显示框架尺寸）
    if previewMachine then
        previewMachine:Destroy()
    end
    
    previewMachine = Instance.new("Part")
    previewMachine.Name = "PreviewMachine"
    previewMachine.Material = Enum.Material.ForceField
    previewMachine.BrickColor = BrickColor.new("Bright green")
    previewMachine.CanCollide = false
    previewMachine.Anchored = true
    previewMachine.Transparency = 0.5
    
    -- 使用框架尺寸作为预览
    previewMachine.Size = getFrameworkSize(machineType)
    
    -- 添加机器名称标签
    local gui = Instance.new("BillboardGui")
    gui.Size = UDim2.new(0, 100, 0, 50)
    gui.Parent = previewMachine
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = machineType
    label.TextColor3 = Color3.white
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansBold
    label.Parent = gui
    
    previewMachine.Parent = workspace
end

-- 停止建造模式
function stopBuildMode()
    isBuildMode = false
    selectedMachineType = nil
    
    if previewMachine then
        previewMachine:Destroy()
        previewMachine = nil
    end
end

-- 放置机器
function placeMachine(position, rotation, scale)
    if not selectedMachineType then return end
    
    local machineSize = getMachineSize(selectedMachineType)
    
    local machineData = {
        type = selectedMachineType,
        position = position,
        rotation = rotation or Vector3.new(0, 0, 0),
        scale = scale or machineSize, -- 保存实际mesh尺寸
        id = tostring(tick() .. "_" .. math.random(1000, 9999))
    }
    
    -- 保存到服务器
    saveMachineEvent:FireServer(machineData)
    
    -- 本地记录
    placedMachines[machineData.id] = machineData
    
    print("放置机器:", selectedMachineType, "位置:", position, "尺寸:", machineSize)
    stopBuildMode()
end

-- 更新预览机器位置
local function updatePreviewPosition()
    if not isBuildMode or not previewMachine then return end
    
    local hit = mouse.Hit
    if hit then
        local position = hit.Position
        -- 对齐到网格
        local gridSize = 5
        position = Vector3.new(
            math.floor(position.X / gridSize + 0.5) * gridSize,
            position.Y,
            math.floor(position.Z / gridSize + 0.5) * gridSize
        )
        
        previewMachine.Position = position + Vector3.new(0, previewMachine.Size.Y/2, 0)
    end
end

-- 输入处理
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.M then
        -- 切换机器建造模式UI
        local ui = player.PlayerGui:FindFirstChild("MachineBuilderUI")
        if ui then
            ui:Destroy()
        else
            createBuildUI()
        end
    elseif input.KeyCode == Enum.KeyCode.Escape then
        -- 退出建造模式
        stopBuildMode()
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 and isBuildMode then
        -- 放置机器
        local hit = mouse.Hit
        if hit then
            local position = hit.Position
            -- 对齐到网格
            local gridSize = 5
            position = Vector3.new(
                math.floor(position.X / gridSize + 0.5) * gridSize,
                hit.Position.Y,
                math.floor(position.Z / gridSize + 0.5) * gridSize
            )
            placeMachine(position)
        end
    elseif input.KeyCode == Enum.KeyCode.R and isBuildMode then
        -- 旋转预览机器
        if previewMachine then
            local currentRotation = previewMachine.Rotation
            previewMachine.Rotation = Vector3.new(currentRotation.X, currentRotation.Y + 90, currentRotation.Z)
        end
    end
end)

-- 运行时更新
RunService.Heartbeat:Connect(function()
    updatePreviewPosition()
end)

-- 处理机器加载
loadMachinesEvent.OnClientEvent:Connect(function(machineData)
    placedMachines = machineData or {}
    print("收到机器数据:", #placedMachines, "个机器")
end)

-- 启动时请求加载机器
wait(2)
loadMachinesEvent:FireServer()

print("机器管理客户端已启动 - 按M键打开机器建造面板")