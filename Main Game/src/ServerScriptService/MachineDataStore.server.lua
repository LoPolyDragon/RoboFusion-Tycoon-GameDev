-- 机器持久化存档系统
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- DataStore配置
local MachineDataStore = DataStoreService:GetDataStore("MachineData_v1")

-- 远程事件
local saveMachineEvent = Instance.new("RemoteEvent")
saveMachineEvent.Name = "SaveMachine"
saveMachineEvent.Parent = ReplicatedStorage

local loadMachinesEvent = Instance.new("RemoteEvent")
loadMachinesEvent.Name = "LoadMachines"
loadMachinesEvent.Parent = ReplicatedStorage

-- 机器类型映射
local MACHINE_TYPES = {
    Generator = "Generator",
    Crusher = "Crusher", 
    Assembler = "Assembler",
    Shipper = "Shipper",
    EnergyMachine = "EnergyMachine"
}

-- 玩家机器数据缓存
local playerMachineData = {}

-- 保存单个机器数据
local function saveMachineData(player, machineData)
    local userId = player.UserId
    local success, errorMessage = pcall(function()
        -- 获取当前数据
        local currentData = playerMachineData[userId] or {}
        
        -- 生成唯一ID
        local machineId = machineData.id or tostring(tick() .. "_" .. math.random(1000, 9999))
        
        -- 保存机器信息
        currentData[machineId] = {
            type = machineData.type,
            position = {
                x = machineData.position.X,
                y = machineData.position.Y, 
                z = machineData.position.Z
            },
            rotation = {
                x = machineData.rotation.X,
                y = machineData.rotation.Y,
                z = machineData.rotation.Z
            },
            scale = machineData.scale and {
                x = machineData.scale.X,
                y = machineData.scale.Y,
                z = machineData.scale.Z
            } or nil,
            timestamp = os.time()
        }
        
        -- 更新缓存
        playerMachineData[userId] = currentData
        
        -- 保存到DataStore
        MachineDataStore:SetAsync("machines_" .. userId, currentData)
        
        return machineId
    end)
    
    if success then
        return true, machineData.id or tostring(tick() .. "_" .. math.random(1000, 9999))
    else
        warn("保存机器数据失败:", errorMessage)
        return false, nil
    end
end

-- 加载玩家所有机器数据
local function loadPlayerMachines(player)
    local userId = player.UserId
    local success, data = pcall(function()
        return MachineDataStore:GetAsync("machines_" .. userId)
    end)
    
    if success and data then
        playerMachineData[userId] = data
        return data
    else
        playerMachineData[userId] = {}
        return {}
    end
end

-- 删除机器数据
local function removeMachineData(player, machineId)
    local userId = player.UserId
    local success, errorMessage = pcall(function()
        local currentData = playerMachineData[userId] or {}
        currentData[machineId] = nil
        
        playerMachineData[userId] = currentData
        MachineDataStore:SetAsync("machines_" .. userId, currentData)
    end)
    
    if not success then
        warn("删除机器数据失败:", errorMessage)
    end
    
    return success
end

-- 获取机器的实际尺寸（通过MeshPart的Size属性）
local function getMachineSize(machineType)
    local machineModel = ServerStorage.MachineModel:FindFirstChild(machineType)
    if not machineModel then
        return Vector3.new(50, 50, 50) -- 默认尺寸
    end
    
    local meshPart = machineModel:FindFirstChildOfClass("MeshPart")
    if meshPart then
        return meshPart.Size
    end
    
    -- 备用方案：使用模型的边界框
    local cf, size = machineModel:GetBoundingBox()
    return size
end

-- 在工作区创建机器
local function createMachineInWorkspace(machineData, playerId)
    local machineModel = ServerStorage.MachineModel:FindFirstChild(machineData.type)
    if not machineModel then
        warn("找不到机器模型:", machineData.type)
        return nil
    end
    
    local newMachine = machineModel:Clone()
    newMachine.Name = machineData.type .. "_" .. playerId
    
    -- 设置位置
    local position = Vector3.new(
        machineData.position.x,
        machineData.position.y,
        machineData.position.z
    )
    
    -- 设置旋转
    local rotation = CFrame.new()
    if machineData.rotation then
        rotation = CFrame.Angles(
            math.rad(machineData.rotation.x),
            math.rad(machineData.rotation.y), 
            math.rad(machineData.rotation.z)
        )
    end
    
    -- 使用PivotTo代替SetPrimaryPartCFrame（更现代的方法）
    newMachine:PivotTo(CFrame.new(position) * rotation)
    
    -- 应用缩放（如果保存了缩放信息）
    if machineData.scale then
        local meshPart = newMachine:FindFirstChildOfClass("MeshPart")
        if meshPart then
            meshPart.Size = Vector3.new(
                machineData.scale.x,
                machineData.scale.y,
                machineData.scale.z
            )
        end
    end
    
    -- 添加机器ID标识
    local stringValue = Instance.new("StringValue")
    stringValue.Name = "MachineId"
    stringValue.Value = machineData.id or (tostring(playerId) .. "_machine")
    stringValue.Parent = newMachine
    
    newMachine.Parent = workspace
    return newMachine
end

-- 处理保存机器事件
saveMachineEvent.OnServerEvent:Connect(function(player, machineData)
    local success, machineId = saveMachineData(player, machineData)
    if success then
        print("成功保存机器:", player.Name, machineData.type, "位置:", machineData.position)
    end
end)

-- 处理加载机器事件  
loadMachinesEvent.OnServerEvent:Connect(function(player)
    local machineData = loadPlayerMachines(player)
    
    -- 在工作区重建所有机器
    for machineId, data in pairs(machineData) do
        local machine = createMachineInWorkspace(data, player.UserId)
        if machine then
            print("重建机器:", player.Name, data.type, "位置:", data.position)
        end
    end
    
    -- 发送数据给客户端
    loadMachinesEvent:FireClient(player, machineData)
end)

-- 玩家离开时清理数据
Players.PlayerRemoving:Connect(function(player)
    local userId = player.UserId
    if playerMachineData[userId] then
        playerMachineData[userId] = nil
    end
end)

-- 玩家进入时自动加载
Players.PlayerAdded:Connect(function(player)
    -- 等待加载完成后再加载机器
    wait(3)
    
    local machineData = loadPlayerMachines(player)
    if next(machineData) then
        -- 在工作区重建所有机器
        for machineId, data in pairs(machineData) do
            local machine = createMachineInWorkspace(data, player.UserId)
            if machine then
                print("自动重建机器:", player.Name, data.type)
            end
        end
        
        -- 通知客户端
        loadMachinesEvent:FireClient(player, machineData)
    end
end)

print("机器数据存储系统已启动")