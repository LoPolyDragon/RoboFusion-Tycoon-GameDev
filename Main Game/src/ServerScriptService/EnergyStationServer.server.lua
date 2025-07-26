----------------------------------------------------------------
-- EnergyStationServer.server.lua · 能量站系统
----------------------------------------------------------------
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local GameLogic = require(script.Parent.ServerModules.GameLogicServer)

----------------------------------------------------------------
-- 能量站配置
----------------------------------------------------------------
local ENERGY_STATIONS = {
	[1] = { range = 30, efficiency = 1.0, cost = 500 },
	[2] = { range = 40, efficiency = 1.1, cost = 1000 },
	[3] = { range = 50, efficiency = 1.2, cost = 2000 },
	[4] = { range = 60, efficiency = 1.3, cost = 4000 },
	[5] = { range = 70, efficiency = 1.5, cost = 8000 },
}

local ENERGY_RECHARGE_RATE = 0.1 -- 每秒恢复的能量百分比
local ENERGY_WORK_COST = 0.05 -- 工作时每秒消耗的能量百分比

----------------------------------------------------------------
-- RemoteEvents
----------------------------------------------------------------
local ChargeRobotEvent = RS:FindFirstChild("ChargeRobotEvent")
if not ChargeRobotEvent then
	ChargeRobotEvent = Instance.new("RemoteEvent")
	ChargeRobotEvent.Name = "ChargeRobotEvent"
	ChargeRobotEvent.Parent = RS
end

local EnergyStationEvent = RS:FindFirstChild("EnergyStationEvent")
if not EnergyStationEvent then
	EnergyStationEvent = Instance.new("RemoteEvent")
	EnergyStationEvent.Name = "EnergyStationEvent"
	EnergyStationEvent.Parent = RS
end

----------------------------------------------------------------
-- 全局数据存储
----------------------------------------------------------------
local energyStations = {} -- [player] = {level, position, lastUpdate}
local robotEnergy = {} -- [player][robotId] = {energy, working, lastUpdate}

----------------------------------------------------------------
-- 工具函数
----------------------------------------------------------------
local function getDistance(pos1, pos2)
	return (pos1 - pos2).Magnitude
end

local function isInRange(robotPos, stationPos, range)
	return getDistance(robotPos, stationPos) <= range
end

----------------------------------------------------------------
-- 建造能量站
----------------------------------------------------------------
EnergyStationEvent.OnServerEvent:Connect(function(player, action, ...)
	local args = {...}
	
	if action == "BUILD" then
		local level = args[1] or 1
		local position = args[2] -- Vector3 位置
		
		if not level or not position then
			EnergyStationEvent:FireClient(player, false, "缺少建造参数")
			return
		end
		
		local config = ENERGY_STATIONS[level]
		if not config then
			EnergyStationEvent:FireClient(player, false, "无效的能量站等级")
			return
		end
		
		-- 检查Credits是否足够
		local playerData = GameLogic.GetPlayerData(player)
		if not playerData or playerData.Credits < config.cost then
			EnergyStationEvent:FireClient(player, false, string.format("需要 %d Credits", config.cost))
			return
		end
		
		-- 扣除Credits
		playerData.Credits = playerData.Credits - config.cost
		
		-- 建造能量站
		energyStations[player] = {
			level = level,
			position = position,
			lastUpdate = os.time()
		}
		
		EnergyStationEvent:FireClient(player, true, string.format("建造了 Lv%d 能量站", level))
		print(string.format("[Energy] %s 建造了 Lv%d 能量站", player.Name, level))
		
	elseif action == "UPGRADE" then
		local newLevel = args[1]
		local station = energyStations[player]
		
		if not station then
			EnergyStationEvent:FireClient(player, false, "没有能量站可升级")
			return
		end
		
		if newLevel <= station.level then
			EnergyStationEvent:FireClient(player, false, "等级必须高于当前等级")
			return
		end
		
		local config = ENERGY_STATIONS[newLevel]
		if not config then
			EnergyStationEvent:FireClient(player, false, "无效的升级等级")
			return
		end
		
		-- 检查Credits
		local playerData = GameLogic.GetPlayerData(player)
		local upgradeCost = config.cost - ENERGY_STATIONS[station.level].cost
		
		if not playerData or playerData.Credits < upgradeCost then
			EnergyStationEvent:FireClient(player, false, string.format("升级需要 %d Credits", upgradeCost))
			return
		end
		
		-- 升级
		playerData.Credits = playerData.Credits - upgradeCost
		station.level = newLevel
		
		EnergyStationEvent:FireClient(player, true, string.format("升级到 Lv%d 能量站", newLevel))
		print(string.format("[Energy] %s 升级到 Lv%d 能量站", player.Name, newLevel))
	end
end)

----------------------------------------------------------------
-- 机器人充能请求
----------------------------------------------------------------
ChargeRobotEvent.OnServerEvent:Connect(function(player, robotId, creditsToSpend)
	if not robotId or not creditsToSpend or creditsToSpend <= 0 then
		return
	end
	
	local playerData = GameLogic.GetPlayerData(player)
	if not playerData or playerData.Credits < creditsToSpend then
		ChargeRobotEvent:FireClient(player, false, "Credits不足")
		return
	end
	
	-- 初始化机器人能量数据
	if not robotEnergy[player] then
		robotEnergy[player] = {}
	end
	
	if not robotEnergy[player][robotId] then
		robotEnergy[player][robotId] = {
			energy = 50, -- 默认50%能量
			working = false,
			lastUpdate = os.time()
		}
	end
	
	-- 计算充能量 (100 Credits = 1小时工作时间 = 约33%能量)
	local energyToAdd = creditsToSpend / 3 -- 简化计算
	energyToAdd = math.min(energyToAdd, 100 - robotEnergy[player][robotId].energy)
	
	-- 扣除Credits并充能
	playerData.Credits = playerData.Credits - creditsToSpend
	robotEnergy[player][robotId].energy = robotEnergy[player][robotId].energy + energyToAdd
	robotEnergy[player][robotId].lastUpdate = os.time()
	
	ChargeRobotEvent:FireClient(player, true, string.format("机器人充能至 %.1f%%", robotEnergy[player][robotId].energy))
	
	-- 更新背包
	RS.RemoteEvents.UpdateInventoryEvent:FireClient(player, GameLogic.GetInventoryDict(player))
	
	print(string.format("[Energy] %s 给机器人 %s 充能 %.1f%%", player.Name, robotId, energyToAdd))
end)

----------------------------------------------------------------
-- 能量系统更新循环
----------------------------------------------------------------
local lastUpdate = os.time()

RunService.Heartbeat:Connect(function()
	local now = os.time()
	local deltaTime = now - lastUpdate
	
	if deltaTime < 1 then return end -- 每秒更新一次
	
	lastUpdate = now
	
	for player, playerRobots in pairs(robotEnergy) do
		local station = energyStations[player]
		
		for robotId, robotData in pairs(playerRobots) do
			-- 如果机器人在工作，消耗能量
			if robotData.working then
				robotData.energy = math.max(0, robotData.energy - ENERGY_WORK_COST * 100 * deltaTime)
				
				-- 能量耗尽时停止工作
				if robotData.energy <= 0 then
					robotData.working = false
					-- 通知客户端机器人停止工作
					ChargeRobotEvent:FireClient(player, "STOP_WORK", robotId)
				end
			else
				-- 在能量站范围内自动充能
				if station then
					local config = ENERGY_STATIONS[station.level]
					if config then
						-- 这里应该检查机器人是否在范围内，简化为自动充能
						local rechargeRate = ENERGY_RECHARGE_RATE * config.efficiency * 100 * deltaTime
						robotData.energy = math.min(100, robotData.energy + rechargeRate)
					end
				end
			end
			
			robotData.lastUpdate = now
		end
	end
end)

----------------------------------------------------------------
-- 获取能量状态函数
----------------------------------------------------------------
local GetEnergyStatusFunc = RS:FindFirstChild("GetEnergyStatusFunction")
if not GetEnergyStatusFunc then
	GetEnergyStatusFunc = Instance.new("RemoteFunction")
	GetEnergyStatusFunc.Name = "GetEnergyStatusFunction"
	GetEnergyStatusFunc.Parent = RS
end

GetEnergyStatusFunc.OnServerInvoke = function(player, robotId)
	if not robotEnergy[player] or not robotEnergy[player][robotId] then
		return { energy = 100, working = false } -- 默认满能量
	end
	
	return {
		energy = robotEnergy[player][robotId].energy,
		working = robotEnergy[player][robotId].working
	}
end

----------------------------------------------------------------
-- 玩家离开清理
----------------------------------------------------------------
Players.PlayerRemoving:Connect(function(player)
	energyStations[player] = nil
	robotEnergy[player] = nil
end)

print("[EnergyStationServer] 能量站系统已启动！")