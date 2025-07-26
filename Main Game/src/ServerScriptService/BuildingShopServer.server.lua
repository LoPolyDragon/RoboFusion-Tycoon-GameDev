--------------------------------------------------------------------
-- BuildingShopServer.server.lua · 建筑商店服务器端
-- 功能：处理建筑购买和放置请求
--------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- 获取PlayerDataManager的RemoteEvent
local playerDataEvent = nil
task.spawn(function()
    local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
    playerDataEvent = remoteFolder:WaitForChild("PlayerDataEvent", 10)
    if not playerDataEvent then
        warn("[BuildingShopServer] PlayerDataEvent不可用，建筑数据将不被持久化")
    end
end)

-- 创建RemoteFunction用于获取机器模型
local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteFolder then
    remoteFolder = Instance.new("Folder")
    remoteFolder.Name = "RemoteEvents"
    remoteFolder.Parent = ReplicatedStorage
end

local getMachineModelFunction = Instance.new("RemoteFunction")
getMachineModelFunction.Name = "GetMachineModelFunction"
getMachineModelFunction.Parent = remoteFolder

-- 获取机器模型的服务器函数
getMachineModelFunction.OnServerInvoke = function(player, buildingId)
    print("[BuildingShopServer] 收到获取模型请求:", buildingId, "来自:", player.Name)
    
    local MachineModel = ServerStorage:FindFirstChild("MachineModel")
    if not MachineModel then
        warn("[BuildingShopServer] ServerStorage/MachineModel 文件夹不存在")
        return nil
    end
    
    local originalModel = MachineModel:FindFirstChild(buildingId)
    if not originalModel then
        warn("[BuildingShopServer] 找不到机器模型:", buildingId)
        print("[BuildingShopServer] 可用的模型:")
        for _, child in pairs(MachineModel:GetChildren()) do
            print("  -", child.Name)
        end
        return nil
    end
    
    print("[BuildingShopServer] 找到模型:", buildingId, "发送给客户端")
    return originalModel -- 直接返回模型，客户端会自动接收克隆
end

-- 创建RemoteEvent用于放置建筑
local placeBuildingEvent = Instance.new("RemoteEvent")
placeBuildingEvent.Name = "PlaceBuildingEvent"
placeBuildingEvent.Parent = remoteFolder

-- 处理建筑放置请求
placeBuildingEvent.OnServerEvent:Connect(function(player, buildingId, position)
    print("[BuildingShopServer] 收到放置建筑请求:", buildingId, "位置:", position, "来自:", player.Name)
    
    local MachineModel = ServerStorage:FindFirstChild("MachineModel")
    if not MachineModel then
        warn("[BuildingShopServer] ServerStorage/MachineModel 文件夹不存在")
        return
    end
    
    local originalModel = MachineModel:FindFirstChild(buildingId)
    if not originalModel then
        warn("[BuildingShopServer] 找不到机器模型:", buildingId)
        return
    end
    
    -- 克隆模型
    local newMachine = originalModel:Clone()
    newMachine.Name = buildingId .. "_" .. tick()
    
    -- 设置机器类型属性
    if buildingId == "EnergyMachine" then
        newMachine:SetAttribute("Type", "EnergyStation")
        newMachine:SetAttribute("Level", 1)
        newMachine:SetAttribute("Range", 20)
        newMachine:SetAttribute("ChargeRate", 0.2)
    elseif buildingId == "Crusher" then
        newMachine:SetAttribute("Type", "Crusher")
        newMachine:SetAttribute("Level", 1)
    elseif buildingId == "Generator" then
        newMachine:SetAttribute("Type", "Generator") 
        newMachine:SetAttribute("Level", 1)
    elseif buildingId == "Assembler" then
        newMachine:SetAttribute("Type", "Assembler")
        newMachine:SetAttribute("Level", 1)
    elseif buildingId == "Shipper" then
        newMachine:SetAttribute("Type", "Shipper")
        newMachine:SetAttribute("Level", 1)
    elseif buildingId == "ToolForge" then
        newMachine:SetAttribute("Type", "ToolForge")
        newMachine:SetAttribute("Level", 1)
    elseif buildingId == "Smelter" then
        newMachine:SetAttribute("Type", "Smelter")
        newMachine:SetAttribute("Level", 1)
    end
    
    newMachine.Parent = workspace
    
    -- 设置位置并锚定所有部件
    local function anchorAllParts(obj)
        if obj:IsA("BasePart") then
            obj.Anchored = true
            obj.CanCollide = true
        end
        for _, child in pairs(obj:GetChildren()) do
            anchorAllParts(child)
        end
    end
    
    if newMachine:IsA("Model") then
        -- 找到Model中的MeshPart或Part
        for _, child in pairs(newMachine:GetChildren()) do
            if child:IsA("MeshPart") or child:IsA("Part") then
                local meshSize = child.Size
                child.Position = Vector3.new(position.X, meshSize.Y/2, position.Z)
                
                -- 设置为PrimaryPart如果没有的话
                if not newMachine.PrimaryPart then
                    newMachine.PrimaryPart = child
                end
                break
            end
        end
        
        -- 锚定所有部件
        anchorAllParts(newMachine)
    else
        -- 单个Part的情况
        newMachine.Position = Vector3.new(position.X, newMachine.Size.Y/2, position.Z)
        newMachine.Anchored = true
        newMachine.CanCollide = true
    end
    
    -- 记录建筑到PlayerDataManager
    if playerDataEvent then
        local buildingData = {
            buildingType = buildingId,
            position = Vector3.new(position.X, position.Y, position.Z),
            rotation = Vector3.new(0, 0, 0), -- 默认朝向
            level = 1
        }
        playerDataEvent:FireServer(player, "ADD_BUILDING", newMachine.Name, buildingData)
    end
    
    print("[BuildingShopServer] 建筑放置成功:", newMachine.Name, "位置:", position)
end)

print("[BuildingShopServer] 建筑商店服务器已启动")