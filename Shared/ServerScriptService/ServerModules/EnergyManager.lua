--------------------------------------------------------------------
-- EnergyManager.lua · 机器人能量系统管理
-- 功能：
--   1) 机器人能量跟踪和消耗
--   2) 能量站充能逻辑
--   3) Credits充能功能
--   4) 能量不足时机器人停工逻辑
--------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- 加载配置
local GameConstants = require(ReplicatedStorage.SharedModules.GameConstants.main)
local ENERGY_CONFIG = GameConstants.ENERGY_CONFIG
local ENERGY_STATIONS = GameConstants.ENERGY_STATIONS

-- 调试配置加载
print("[EnergyManager] ENERGY_CONFIG:", ENERGY_CONFIG)
print("[EnergyManager] ENERGY_STATIONS:", ENERGY_STATIONS)
if ENERGY_CONFIG then
    print("[EnergyManager] baseChargeRate:", ENERGY_CONFIG.baseChargeRate)
end
if ENERGY_STATIONS then
    print("[EnergyManager] ENERGY_STATIONS[1]:", ENERGY_STATIONS[1])
end

--------------------------------------------------------------------
-- 能量管理器
--------------------------------------------------------------------
local EnergyManager = {}

-- 机器人能量数据存储 {[robotModel] = {energy = number, maxEnergy = number, lastUpdate = tick()}}
local robotEnergyData = {}

-- 能量站数据存储 {[stationModel] = {level = number, range = number, chargeRate = number}}
local energyStations = {}

-- 是否已初始化
local initialized = false

--------------------------------------------------------------------
-- 初始化系统
--------------------------------------------------------------------
function EnergyManager.Initialize()
    if initialized then
        return
    end
    
    initialized = true
    
    -- 启动能量更新循环
    RunService.Heartbeat:Connect(function()
        EnergyManager._UpdateAllRobotEnergy()
    end)
    
    print("[EnergyManager] 能量系统已启动")
end

--------------------------------------------------------------------
-- 机器人能量管理
--------------------------------------------------------------------

-- 注册机器人到能量系统
function EnergyManager.RegisterRobot(robotModel, robotType)
    if not robotModel or not robotType then
        warn("[EnergyManager] RegisterRobot: 缺少参数")
        return
    end
    
    local maxEnergy = ENERGY_CONFIG.maxEnergy
    local currentEnergy = maxEnergy -- 新机器人满能量
    
    robotEnergyData[robotModel] = {
        energy = currentEnergy,
        maxEnergy = maxEnergy,
        robotType = robotType,
        lastUpdate = tick(),
        isWorking = false
    }
    
    -- 设置机器人属性用于UI显示
    robotModel:SetAttribute("Energy", currentEnergy)
    robotModel:SetAttribute("MaxEnergy", maxEnergy)
    robotModel:SetAttribute("RobotType", robotType)
    
    print(("[EnergyManager] 注册机器人: %s (类型: %s, 能量: %d/%d)"):format(
        robotModel.Name, robotType, currentEnergy, maxEnergy))
end

-- 注销机器人
function EnergyManager.UnregisterRobot(robotModel)
    if robotEnergyData[robotModel] then
        robotEnergyData[robotModel] = nil
        print(("[EnergyManager] 注销机器人: %s"):format(robotModel.Name))
    end
end

-- 获取机器人能量信息
function EnergyManager.GetRobotEnergy(robotModel)
    local data = robotEnergyData[robotModel]
    if not data then
        return nil
    end
    
    return {
        energy = data.energy,
        maxEnergy = data.maxEnergy,
        percentage = (data.energy / data.maxEnergy) * 100,
        isWorking = data.isWorking,
        robotType = data.robotType
    }
end

-- 设置机器人工作状态
function EnergyManager.SetRobotWorking(robotModel, isWorking)
    local data = robotEnergyData[robotModel]
    if not data then
        return false
    end
    
    data.isWorking = isWorking
    robotModel:SetAttribute("IsWorking", isWorking)
    
    return true
end

-- 检查机器人是否有足够能量工作
function EnergyManager.CanRobotWork(robotModel)
    local data = robotEnergyData[robotModel]
    if not data then
        return false
    end
    
    return data.energy > 0
end

-- 消耗机器人能量（手动调用，用于特殊消耗）
function EnergyManager.ConsumeRobotEnergy(robotModel, amount)
    local data = robotEnergyData[robotModel]
    if not data then
        return false
    end
    
    data.energy = math.max(0, data.energy - amount)
    robotModel:SetAttribute("Energy", data.energy)
    
    -- 如果能量不足,停止工作
    if data.energy <= 0 and data.isWorking then
        EnergyManager.SetRobotWorking(robotModel, false)
        print(("[EnergyManager] 机器人 %s 能量耗尽，停止工作"):format(robotModel.Name))
    end
    
    return true
end

-- 为机器人充能
function EnergyManager.ChargeRobot(robotModel, amount)
    local data = robotEnergyData[robotModel]
    if not data then
        return false
    end
    
    local oldEnergy = data.energy
    data.energy = math.min(data.maxEnergy, data.energy + amount)
    robotModel:SetAttribute("Energy", data.energy)
    
    local actualCharged = data.energy - oldEnergy
    if actualCharged > 0 then
        print(("[EnergyManager] 机器人 %s 充能 %.1f，当前能量: %.1f/%.1f"):format(
            robotModel.Name, actualCharged, data.energy, data.maxEnergy))
    end
    
    return actualCharged
end

--------------------------------------------------------------------
-- 能量站管理
--------------------------------------------------------------------

-- 注册能量站
function EnergyManager.RegisterEnergyStation(stationModel, level)
    if not stationModel or not level then
        warn("[EnergyManager] RegisterEnergyStation: 缺少参数")
        return
    end
    
    local config = ENERGY_STATIONS[level]
    if not config then
        warn("[EnergyManager] RegisterEnergyStation: 无效的能量站等级", level)
        return
    end
    
    energyStations[stationModel] = {
        level = level,
        range = config.range,
        chargeRate = ENERGY_CONFIG.baseChargeRate * config.chargeMultiplier
    }
    
    -- 设置能量站属性
    stationModel:SetAttribute("Level", level)
    stationModel:SetAttribute("Range", config.range)
    stationModel:SetAttribute("ChargeRate", energyStations[stationModel].chargeRate)
    
    -- 调试输出
    print("[Debug] stationModel.Name:", stationModel.Name)
    print("[Debug] level:", level)
    print("[Debug] config.range:", config.range)
    print("[Debug] energyStations[stationModel].chargeRate:", energyStations[stationModel].chargeRate)
    
    print(("[EnergyManager] 注册能量站: %s (等级: %d, 范围: %d, 充能速度: %.2f/秒)"):format(
        stationModel.Name, level, config.range, energyStations[stationModel].chargeRate))
end

-- 注销能量站
function EnergyManager.UnregisterEnergyStation(stationModel)
    if energyStations[stationModel] then
        energyStations[stationModel] = nil
        print(("[EnergyManager] 注销能量站: %s"):format(stationModel.Name))
    end
end

-- 获取机器人位置（优先PrimaryPart，否则使用第一个Part）
local function getRobotPosition(robotModel)
    if robotModel.PrimaryPart then
        return robotModel.PrimaryPart.Position
    end
    
    -- 如果没有PrimaryPart，找第一个Part
    for _, child in pairs(robotModel:GetChildren()) do
        if child:IsA("BasePart") then
            return child.Position
        end
    end
    
    return nil
end

-- 获取范围内的机器人
function EnergyManager.GetRobotsInRange(position, range)
    local robotsInRange = {}
    
    for robotModel, data in pairs(robotEnergyData) do
        if robotModel.Parent then
            local robotPos = getRobotPosition(robotModel)
            if robotPos then
                local distance = (robotPos - position).Magnitude
                if distance <= range then
                    table.insert(robotsInRange, robotModel)
                end
            end
        end
    end
    
    return robotsInRange
end

--------------------------------------------------------------------
-- Credits充能功能
--------------------------------------------------------------------

-- 使用Credits为机器人充能
function EnergyManager.ChargeRobotWithCredits(player, robotModel, energyAmount)
    if not player or not robotModel or not energyAmount then
        return false, "参数错误"
    end
    
    local data = robotEnergyData[robotModel]
    if not data then
        return false, "机器人未注册到能量系统"
    end
    
    -- 计算需要的Credits
    local creditsNeeded = math.ceil(energyAmount * ENERGY_CONFIG.creditsChargeRatio)
    
    -- 检查玩家是否有足够的Credits（这里需要调用GameLogicServer）
    local GameLogicServer = require(script.Parent.GameLogicServer)
    local playerData = GameLogicServer.GetPlayerData(player)
    
    if not playerData or (playerData.Credits or 0) < creditsNeeded then
        return false, "Credits不足"
    end
    
    -- 扣除Credits
    GameLogicServer.AddCredits(player, -creditsNeeded)
    
    -- 充能
    local actualCharged = EnergyManager.ChargeRobot(robotModel, energyAmount)
    
    if actualCharged > 0 then
        print(("[EnergyManager] 玩家 %s 使用 %d Credits 为机器人 %s 充能 %.1f"):format(
            player.Name, creditsNeeded, robotModel.Name, actualCharged))
        return true, ("充能成功! 消耗 %d Credits"):format(creditsNeeded)
    else
        -- 如果没有实际充能，退还Credits
        GameLogicServer.AddCredits(player, creditsNeeded)
        return false, "机器人已满能量"
    end
end

--------------------------------------------------------------------
-- 内部更新函数
--------------------------------------------------------------------

-- 更新所有机器人能量
function EnergyManager._UpdateAllRobotEnergy()
    local currentTime = tick()
    
    for robotModel, data in pairs(robotEnergyData) do
        -- 检查机器人是否仍然存在
        if not robotModel.Parent then
            robotEnergyData[robotModel] = nil
            continue
        end
        
        local deltaTime = currentTime - data.lastUpdate
        data.lastUpdate = currentTime
        
        -- 如果机器人在工作，消耗能量
        if data.isWorking and data.energy > 0 then
            local consumptionRate = ENERGY_CONFIG.robotConsumption[data.robotType] or 1.0
            local energyConsumed = (consumptionRate / 60) * deltaTime -- 每分钟消耗转换为每秒
            
            data.energy = math.max(0, data.energy - energyConsumed)
            robotModel:SetAttribute("Energy", data.energy)
            
            -- 能量耗尽时停止工作
            if data.energy <= 0 then
                EnergyManager.SetRobotWorking(robotModel, false)
                print(("[EnergyManager] 机器人 %s 能量耗尽，自动停止工作"):format(robotModel.Name))
            end
        end
        
        -- 检查附近的能量站进行充能
        if data.energy < data.maxEnergy then
            local robotPosition = getRobotPosition(robotModel)
            
            if robotPosition then
                for stationModel, stationData in pairs(energyStations) do
                    if stationModel.Parent and stationModel.PrimaryPart then
                        local distance = (stationModel.PrimaryPart.Position - robotPosition).Magnitude
                        
                        if distance <= stationData.range then
                            local chargeAmount = stationData.chargeRate * deltaTime
                            local actualCharged = math.min(chargeAmount, data.maxEnergy - data.energy)
                            
                            if actualCharged > 0 then
                                data.energy = data.energy + actualCharged
                                robotModel:SetAttribute("Energy", data.energy)
                            end
                            
                            break -- 只能被一个能量站充能
                        end
                    end
                end
            end
        end
    end
end

--------------------------------------------------------------------
-- 调试和管理功能
--------------------------------------------------------------------

-- 获取所有机器人能量状态
function EnergyManager.GetAllRobotStatus()
    local status = {}
    
    for robotModel, data in pairs(robotEnergyData) do
        table.insert(status, {
            name = robotModel.Name,
            energy = data.energy,
            maxEnergy = data.maxEnergy,
            percentage = math.floor((data.energy / data.maxEnergy) * 100),
            robotType = data.robotType,
            isWorking = data.isWorking
        })
    end
    
    return status
end

-- 获取所有能量站状态
function EnergyManager.GetAllStationStatus()
    local status = {}
    
    for stationModel, data in pairs(energyStations) do
        local robotsInRange = EnergyManager.GetRobotsInRange(
            stationModel.PrimaryPart.Position, data.range)
        
        table.insert(status, {
            name = stationModel.Name,
            level = data.level,
            range = data.range,
            chargeRate = data.chargeRate,
            robotsInRange = #robotsInRange
        })
    end
    
    return status
end

-- 强制充满所有机器人（调试用）
function EnergyManager.ChargeAllRobots()
    for robotModel, data in pairs(robotEnergyData) do
        data.energy = data.maxEnergy
        robotModel:SetAttribute("Energy", data.energy)
    end
    
    print("[EnergyManager] 所有机器人已充满能量")
end

return EnergyManager