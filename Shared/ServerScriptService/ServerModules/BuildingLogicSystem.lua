--------------------------------------------------------------------
-- BuildingLogicSystem.lua · 建筑逻辑系统
-- 功能：
--   1) 生产建筑的生产逻辑
--   2) 功能建筑的运行逻辑
--   3) 基础设施建筑的服务逻辑
--   4) 装饰建筑的美观度影响
--------------------------------------------------------------------

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConstants = require(ReplicatedStorage.SharedModules.GameConstants)

local BuildingLogicSystem = {}

-- 建筑生产状态
local buildingStates = {}
local productionTimers = {}

--------------------------------------------------------------------
-- 建筑状态管理
--------------------------------------------------------------------

-- 初始化建筑状态
function BuildingLogicSystem.InitializeBuilding(buildingId, buildingData)
    buildingStates[buildingId] = {
        id = buildingId,
        type = buildingData.type,
        level = buildingData.level or 1,
        status = "active", -- active, paused, disabled, broken
        energyConsumption = 0,
        energyProduction = 0,
        lastProductionTime = tick(),
        productionQueue = {},
        inventory = {},
        connections = {}, -- 连接的其他建筑
        efficiency = 1.0, -- 生产效率倍数
        beautyBonus = 0, -- 美观度加成
        position = buildingData.position,
        config = GameConstants.BUILDING_TYPES[buildingData.category][buildingData.type]
    }
    
    -- 设置生产计时器
    if buildingData.category == "PRODUCTION" then
        BuildingLogicSystem.StartProductionTimer(buildingId)
    end
    
    print("[BuildingLogicSystem] 初始化建筑:", buildingId, buildingData.type)
    return buildingStates[buildingId]
end

-- 获取建筑状态
function BuildingLogicSystem.GetBuildingState(buildingId)
    return buildingStates[buildingId]
end

-- 更新建筑状态
function BuildingLogicSystem.UpdateBuildingState(buildingId, updates)
    local state = buildingStates[buildingId]
    if not state then return false end
    
    for key, value in pairs(updates) do
        state[key] = value
    end
    
    return true
end

-- 移除建筑
function BuildingLogicSystem.RemoveBuilding(buildingId)
    -- 停止生产计时器
    if productionTimers[buildingId] then
        productionTimers[buildingId]:Disconnect()
        productionTimers[buildingId] = nil
    end
    
    -- 清除建筑状态
    buildingStates[buildingId] = nil
    
    print("[BuildingLogicSystem] 移除建筑:", buildingId)
end

--------------------------------------------------------------------
-- 生产建筑逻辑
--------------------------------------------------------------------

-- 开始生产计时器
function BuildingLogicSystem.StartProductionTimer(buildingId)
    local state = buildingStates[buildingId]
    if not state or not state.config.productionTime then return end
    
    -- 如果已经有计时器，先停止
    if productionTimers[buildingId] then
        productionTimers[buildingId]:Disconnect()
    end
    
    -- 创建新的生产计时器
    productionTimers[buildingId] = RunService.Heartbeat:Connect(function()
        BuildingLogicSystem.UpdateProduction(buildingId)
    end)
    
    print("[BuildingLogicSystem] 开始生产计时器:", buildingId)
end

-- 更新生产逻辑
function BuildingLogicSystem.UpdateProduction(buildingId)
    local state = buildingStates[buildingId]
    if not state or state.status ~= "active" then return end
    
    local currentTime = tick()
    local config = state.config
    
    -- 检查是否到达生产时间
    local productionInterval = config.productionTime * (1 / state.efficiency)
    if currentTime - state.lastProductionTime >= productionInterval then
        
        -- 检查能源需求
        if config.energyConsumption and config.energyConsumption > 0 then
            if not BuildingLogicSystem.ConsumeEnergy(buildingId, config.energyConsumption) then
                print("[BuildingLogicSystem] 建筑", buildingId, "能源不足，暂停生产")
                state.status = "disabled"
                return
            end
        end
        
        -- 检查生产需求
        if config.inputRequirements then
            if not BuildingLogicSystem.CheckProductionRequirements(buildingId, config.inputRequirements) then
                return -- 缺少原材料
            end
            -- 消耗原材料
            BuildingLogicSystem.ConsumeInputs(buildingId, config.inputRequirements)
        end
        
        -- 执行生产
        BuildingLogicSystem.ProduceItems(buildingId, config.outputs)
        
        -- 更新生产时间
        state.lastProductionTime = currentTime
        
        print("[BuildingLogicSystem] 建筑", buildingId, "完成一次生产")
    end
end

-- 检查生产需求
function BuildingLogicSystem.CheckProductionRequirements(buildingId, requirements)
    local state = buildingStates[buildingId]
    if not state then return false end
    
    for itemType, amount in pairs(requirements) do
        if not state.inventory[itemType] or state.inventory[itemType] < amount then
            return false
        end
    end
    
    return true
end

-- 消耗生产原料
function BuildingLogicSystem.ConsumeInputs(buildingId, requirements)
    local state = buildingStates[buildingId]
    if not state then return end
    
    for itemType, amount in pairs(requirements) do
        state.inventory[itemType] = (state.inventory[itemType] or 0) - amount
        if state.inventory[itemType] <= 0 then
            state.inventory[itemType] = nil
        end
    end
end

-- 生产物品
function BuildingLogicSystem.ProduceItems(buildingId, outputs)
    local state = buildingStates[buildingId]
    if not state then return end
    
    for itemType, amount in pairs(outputs) do
        local actualAmount = math.floor(amount * state.efficiency * (1 + state.beautyBonus))
        state.inventory[itemType] = (state.inventory[itemType] or 0) + actualAmount
        
        print("[BuildingLogicSystem] 建筑", buildingId, "生产了", actualAmount, "个", itemType)
    end
end

--------------------------------------------------------------------
-- 能源系统
--------------------------------------------------------------------

-- 消耗能源
function BuildingLogicSystem.ConsumeEnergy(buildingId, amount)
    -- TODO: 实现全局能源网络
    -- 暂时总是返回true，后续实现能源网络后会真实检查
    return true
end

-- 生产能源
function BuildingLogicSystem.ProduceEnergy(buildingId, amount)
    local state = buildingStates[buildingId]
    if not state then return end
    
    state.energyProduction = amount
    print("[BuildingLogicSystem] 建筑", buildingId, "生产能源:", amount)
end

-- 计算能源平衡
function BuildingLogicSystem.CalculateEnergyBalance(playerBuildings)
    local totalProduction = 0
    local totalConsumption = 0
    
    for buildingId, building in pairs(playerBuildings) do
        local state = buildingStates[buildingId]
        if state and state.status == "active" then
            totalProduction = totalProduction + (state.energyProduction or 0)
            totalConsumption = totalConsumption + (state.config.energyConsumption or 0)
        end
    end
    
    return {
        production = totalProduction,
        consumption = totalConsumption,
        balance = totalProduction - totalConsumption,
        efficiency = totalProduction > 0 and math.min(1, totalProduction / totalConsumption) or 0
    }
end

--------------------------------------------------------------------
-- 功能建筑逻辑
--------------------------------------------------------------------

-- 研究建筑逻辑
function BuildingLogicSystem.UpdateResearchBuilding(buildingId)
    local state = buildingStates[buildingId]
    if not state or state.status ~= "active" then return end
    
    -- TODO: 实现研究逻辑
    -- 研究新技术、解锁新建筑等
end

-- 存储建筑逻辑
function BuildingLogicSystem.UpdateStorageBuilding(buildingId)
    local state = buildingStates[buildingId]
    if not state then return end
    
    -- 扩展存储容量
    local config = state.config
    local storageCapacity = config.storageCapacity * state.level
    
    -- TODO: 实现存储逻辑
    print("[BuildingLogicSystem] 存储建筑", buildingId, "容量:", storageCapacity)
end

-- 交通建筑逻辑
function BuildingLogicSystem.UpdateTransportBuilding(buildingId)
    local state = buildingStates[buildingId]
    if not state or state.status ~= "active" then return end
    
    -- TODO: 实现物品运输逻辑
    -- 在连接的建筑间运输物品
end

--------------------------------------------------------------------
-- 基础设施建筑逻辑
--------------------------------------------------------------------

-- 发电厂逻辑
function BuildingLogicSystem.UpdatePowerPlant(buildingId)
    local state = buildingStates[buildingId]
    if not state or state.status ~= "active" then return end
    
    local config = state.config
    local energyProduction = config.energyProduction * state.level * state.efficiency
    
    BuildingLogicSystem.ProduceEnergy(buildingId, energyProduction)
end

-- 水处理厂逻辑
function BuildingLogicSystem.UpdateWaterTreatment(buildingId)
    local state = buildingStates[buildingId]
    if not state or state.status ~= "active" then return end
    
    -- TODO: 实现水资源处理逻辑
end

-- 道路逻辑
function BuildingLogicSystem.UpdateRoad(buildingId)
    local state = buildingStates[buildingId]
    if not state then return end
    
    -- 道路提供连接性和运输速度加成
    -- TODO: 实现道路网络逻辑
end

--------------------------------------------------------------------
-- 装饰建筑逻辑
--------------------------------------------------------------------

-- 更新美观度影响
function BuildingLogicSystem.UpdateBeautyInfluence(buildingId)
    local state = buildingStates[buildingId]
    if not state then return end
    
    local config = state.config
    if not config.beautyValue then return end
    
    local beautyValue = config.beautyValue * state.level
    local influenceRadius = config.beautyRadius or 50
    
    -- 计算影响范围内的建筑
    local affectedBuildings = BuildingLogicSystem.GetBuildingsInRadius(
        state.position, influenceRadius
    )
    
    -- 为每个受影响的建筑添加美观度加成
    for _, targetBuildingId in ipairs(affectedBuildings) do
        if targetBuildingId ~= buildingId then
            BuildingLogicSystem.ApplyBeautyBonus(targetBuildingId, buildingId, beautyValue)
        end
    end
    
    print("[BuildingLogicSystem] 装饰建筑", buildingId, "影响", #affectedBuildings, "个建筑")
end

-- 获取半径内的建筑
function BuildingLogicSystem.GetBuildingsInRadius(centerPosition, radius)
    local affectedBuildings = {}
    
    for buildingId, state in pairs(buildingStates) do
        local distance = (state.position - centerPosition).Magnitude
        if distance <= radius then
            table.insert(affectedBuildings, buildingId)
        end
    end
    
    return affectedBuildings
end

-- 应用美观度加成
function BuildingLogicSystem.ApplyBeautyBonus(targetBuildingId, sourceBuildingId, beautyValue)
    local state = buildingStates[targetBuildingId]
    if not state then return end
    
    -- 计算美观度加成（最大20%）
    local beautyBonus = math.min(0.2, beautyValue * 0.01)
    state.beautyBonus = math.max(state.beautyBonus, beautyBonus)
    
    print("[BuildingLogicSystem] 建筑", targetBuildingId, "获得美观度加成:", beautyBonus)
end

--------------------------------------------------------------------
-- 建筑升级逻辑
--------------------------------------------------------------------

-- 升级建筑
function BuildingLogicSystem.UpgradeBuilding(buildingId, newLevel)
    local state = buildingStates[buildingId]
    if not state then return false end
    
    local config = state.config
    if newLevel > config.maxLevel then return false end
    
    -- 更新建筑等级
    state.level = newLevel
    
    -- 重新计算属性
    if config.energyProduction then
        state.energyProduction = config.energyProduction * newLevel
    end
    
    -- 更新生产效率
    state.efficiency = 1.0 + (newLevel - 1) * 0.1 -- 每级增加10%效率
    
    print("[BuildingLogicSystem] 建筑", buildingId, "升级到等级", newLevel)
    return true
end

--------------------------------------------------------------------
-- 建筑连接系统
--------------------------------------------------------------------

-- 连接两个建筑
function BuildingLogicSystem.ConnectBuildings(buildingId1, buildingId2, connectionType)
    local state1 = buildingStates[buildingId1]
    local state2 = buildingStates[buildingId2]
    
    if not state1 or not state2 then return false end
    
    -- 添加连接
    if not state1.connections[connectionType] then
        state1.connections[connectionType] = {}
    end
    if not state2.connections[connectionType] then
        state2.connections[connectionType] = {}
    end
    
    table.insert(state1.connections[connectionType], buildingId2)
    table.insert(state2.connections[connectionType], buildingId1)
    
    print("[BuildingLogicSystem] 连接建筑:", buildingId1, "->", buildingId2, "类型:", connectionType)
    return true
end

-- 断开建筑连接
function BuildingLogicSystem.DisconnectBuildings(buildingId1, buildingId2, connectionType)
    local state1 = buildingStates[buildingId1]
    local state2 = buildingStates[buildingId2]
    
    if not state1 or not state2 then return false end
    
    -- 移除连接
    if state1.connections[connectionType] then
        for i, id in ipairs(state1.connections[connectionType]) do
            if id == buildingId2 then
                table.remove(state1.connections[connectionType], i)
                break
            end
        end
    end
    
    if state2.connections[connectionType] then
        for i, id in ipairs(state2.connections[connectionType]) do
            if id == buildingId1 then
                table.remove(state2.connections[connectionType], i)
                break
            end
        end
    end
    
    print("[BuildingLogicSystem] 断开建筑连接:", buildingId1, "->", buildingId2)
    return true
end

--------------------------------------------------------------------
-- 物品传输系统
--------------------------------------------------------------------

-- 在建筑间传输物品
function BuildingLogicSystem.TransferItems(fromBuildingId, toBuildingId, itemType, amount)
    local fromState = buildingStates[fromBuildingId]
    local toState = buildingStates[toBuildingId]
    
    if not fromState or not toState then return false end
    
    -- 检查来源建筑是否有足够物品
    if not fromState.inventory[itemType] or fromState.inventory[itemType] < amount then
        return false
    end
    
    -- 传输物品
    fromState.inventory[itemType] = fromState.inventory[itemType] - amount
    if fromState.inventory[itemType] <= 0 then
        fromState.inventory[itemType] = nil
    end
    
    toState.inventory[itemType] = (toState.inventory[itemType] or 0) + amount
    
    print("[BuildingLogicSystem] 传输物品:", amount, itemType, "从", fromBuildingId, "到", toBuildingId)
    return true
end

-- 自动物品分配
function BuildingLogicSystem.AutoDistributeItems(sourceBuildingId)
    local sourceState = buildingStates[sourceBuildingId]
    if not sourceState then return end
    
    -- 查找需要物品的连接建筑
    for connectionType, connectedBuildings in pairs(sourceState.connections) do
        if connectionType == "transport" then
            for _, targetBuildingId in ipairs(connectedBuildings) do
                local targetState = buildingStates[targetBuildingId]
                if targetState and targetState.config.inputRequirements then
                    
                    -- 尝试传输需要的物品
                    for itemType, requiredAmount in pairs(targetState.config.inputRequirements) do
                        if sourceState.inventory[itemType] and sourceState.inventory[itemType] > 0 then
                            local transferAmount = math.min(
                                sourceState.inventory[itemType],
                                requiredAmount
                            )
                            BuildingLogicSystem.TransferItems(
                                sourceBuildingId, targetBuildingId, itemType, transferAmount
                            )
                        end
                    end
                end
            end
        end
    end
end

--------------------------------------------------------------------
-- 主更新循环
--------------------------------------------------------------------

-- 更新所有建筑逻辑
function BuildingLogicSystem.UpdateAll()
    for buildingId, state in pairs(buildingStates) do
        if state.status == "active" then
            local buildingType = state.type
            local category = nil
            
            -- 确定建筑分类
            for cat, buildings in pairs(GameConstants.BUILDING_TYPES) do
                if buildings[buildingType] then
                    category = cat
                    break
                end
            end
            
            -- 根据分类执行相应逻辑
            if category == "PRODUCTION" then
                -- 生产建筑已通过生产计时器处理
            elseif category == "FUNCTIONAL" then
                if buildingType == "RESEARCH_LAB" then
                    BuildingLogicSystem.UpdateResearchBuilding(buildingId)
                elseif buildingType == "WAREHOUSE" then
                    BuildingLogicSystem.UpdateStorageBuilding(buildingId)
                elseif buildingType == "TRANSPORT_HUB" then
                    BuildingLogicSystem.UpdateTransportBuilding(buildingId)
                end
            elseif category == "INFRASTRUCTURE" then
                if buildingType == "POWER_PLANT" then
                    BuildingLogicSystem.UpdatePowerPlant(buildingId)
                elseif buildingType == "WATER_TREATMENT" then
                    BuildingLogicSystem.UpdateWaterTreatment(buildingId)
                elseif buildingType == "ROAD" then
                    BuildingLogicSystem.UpdateRoad(buildingId)
                end
            elseif category == "DECORATIVE" then
                BuildingLogicSystem.UpdateBeautyInfluence(buildingId)
            end
            
            -- 自动物品分配
            BuildingLogicSystem.AutoDistributeItems(buildingId)
        end
    end
end

-- 启动主更新循环
function BuildingLogicSystem.Start()
    -- 每5秒更新一次所有建筑逻辑
    RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        if not BuildingLogicSystem.lastUpdate or currentTime - BuildingLogicSystem.lastUpdate >= 5 then
            BuildingLogicSystem.UpdateAll()
            BuildingLogicSystem.lastUpdate = currentTime
        end
    end)
    
    print("[BuildingLogicSystem] 建筑逻辑系统已启动")
end

return BuildingLogicSystem