--------------------------------------------------------------------
-- CooldownManager.lua · 统一冷却时间管理系统
-- 功能：
--   1) 管理所有机器和系统的冷却时间
--   2) 提供统一的CD检查和设置接口
--   3) 支持不同等级机器的不同CD
--   4) 提供剩余CD时间查询
--   5) 自动清理过期数据
--------------------------------------------------------------------

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConstants = require(ReplicatedStorage.SharedModules.GameConstants)

local CooldownManager = {}

-- 冷却数据存储 [playerId][machineType][instanceId] = endTime
local cooldownData = {}

-- 系统冷却数据 [playerId][systemName] = endTime  
local systemCooldowns = {}

-- RemoteEvent for client synchronization
local cooldownUpdateEvent = ReplicatedStorage:FindFirstChild("CooldownUpdateEvent")
if not cooldownUpdateEvent then
    cooldownUpdateEvent = Instance.new("RemoteEvent")
    cooldownUpdateEvent.Name = "CooldownUpdateEvent"
    cooldownUpdateEvent.Parent = ReplicatedStorage
end

--------------------------------------------------------------------
-- 内部工具函数
--------------------------------------------------------------------

-- 获取当前时间戳
local function getCurrentTime()
    return tick()
end

-- 清理过期的冷却数据
local function cleanupExpiredCooldowns()
    local currentTime = getCurrentTime()
    
    -- 清理机器冷却
    for playerId, playerData in pairs(cooldownData) do
        for machineType, machines in pairs(playerData) do
            for instanceId, endTime in pairs(machines) do
                if currentTime >= endTime then
                    machines[instanceId] = nil
                end
            end
            -- 如果机器类型下没有冷却了，清理空表
            if next(machines) == nil then
                playerData[machineType] = nil
            end
        end
        -- 如果玩家没有任何冷却了，清理空表
        if next(playerData) == nil then
            cooldownData[playerId] = nil
        end
    end
    
    -- 清理系统冷却
    for playerId, systems in pairs(systemCooldowns) do
        for systemName, endTime in pairs(systems) do
            if currentTime >= endTime then
                systems[systemName] = nil
            end
        end
        if next(systems) == nil then
            systemCooldowns[playerId] = nil
        end
    end
end

-- 通知客户端冷却状态更新
local function notifyClient(player, cooldownType, machineType, instanceId, remainingTime)
    if not player or not player.Parent then return end
    
    cooldownUpdateEvent:FireClient(player, {
        type = cooldownType, -- "machine" or "system"
        machineType = machineType,
        instanceId = instanceId,
        remainingTime = remainingTime
    })
end

--------------------------------------------------------------------
-- 机器冷却管理
--------------------------------------------------------------------

-- 设置机器冷却时间
function CooldownManager.SetMachineCooldown(player, machineType, instanceId, level)
    if not player or not machineType then return false end
    
    local playerId = tostring(player.UserId)
    level = level or 1
    
    -- 获取冷却时间配置
    local machineConfig = GameConstants.MACHINE_COOLDOWNS[machineType]
    if not machineConfig then
        warn("[CooldownManager] 未找到机器类型的冷却配置: " .. machineType)
        return false
    end
    
    local cooldownTime = machineConfig[level] or machineConfig[1] or 5
    local endTime = getCurrentTime() + cooldownTime
    
    -- 初始化数据结构
    if not cooldownData[playerId] then
        cooldownData[playerId] = {}
    end
    if not cooldownData[playerId][machineType] then
        cooldownData[playerId][machineType] = {}
    end
    
    -- 设置冷却
    cooldownData[playerId][machineType][instanceId] = endTime
    
    -- 通知客户端
    notifyClient(player, "machine", machineType, instanceId, cooldownTime)
    
    print(("[CooldownManager] 设置 %s 的 %s Lv%d 冷却: %.1f秒"):format(
        player.Name, machineType, level, cooldownTime))
    
    return true
end

-- 检查机器是否在冷却中
function CooldownManager.IsMachineOnCooldown(player, machineType, instanceId)
    if not player or not machineType then return false end
    
    local playerId = tostring(player.UserId)
    local currentTime = getCurrentTime()
    
    local playerData = cooldownData[playerId]
    if not playerData then return false end
    
    local machineData = playerData[machineType]
    if not machineData then return false end
    
    local endTime = machineData[instanceId]
    if not endTime then return false end
    
    return currentTime < endTime
end

-- 获取机器剩余冷却时间
function CooldownManager.GetMachineRemainingCooldown(player, machineType, instanceId)
    if not player or not machineType then return 0 end
    
    local playerId = tostring(player.UserId)
    local currentTime = getCurrentTime()
    
    local playerData = cooldownData[playerId]
    if not playerData then return 0 end
    
    local machineData = playerData[machineType]
    if not machineData then return 0 end
    
    local endTime = machineData[instanceId]
    if not endTime then return 0 end
    
    return math.max(0, endTime - currentTime)
end

-- 强制清除机器冷却
function CooldownManager.ClearMachineCooldown(player, machineType, instanceId)
    if not player or not machineType then return false end
    
    local playerId = tostring(player.UserId)
    
    local playerData = cooldownData[playerId]
    if not playerData then return false end
    
    local machineData = playerData[machineType]
    if not machineData then return false end
    
    machineData[instanceId] = nil
    
    -- 通知客户端冷却结束
    notifyClient(player, "machine", machineType, instanceId, 0)
    
    return true
end

--------------------------------------------------------------------
-- 系统冷却管理
--------------------------------------------------------------------

-- 设置系统冷却时间
function CooldownManager.SetSystemCooldown(player, systemName, customTime)
    if not player or not systemName then return false end
    
    local playerId = tostring(player.UserId)
    
    -- 获取冷却时间
    local cooldownTime = customTime or GameConstants.SYSTEM_COOLDOWNS[systemName] or 5
    local endTime = getCurrentTime() + cooldownTime
    
    -- 初始化数据结构
    if not systemCooldowns[playerId] then
        systemCooldowns[playerId] = {}
    end
    
    -- 设置冷却
    systemCooldowns[playerId][systemName] = endTime
    
    -- 通知客户端
    notifyClient(player, "system", systemName, nil, cooldownTime)
    
    print(("[CooldownManager] 设置 %s 的系统冷却 %s: %.1f秒"):format(
        player.Name, systemName, cooldownTime))
    
    return true
end

-- 检查系统是否在冷却中
function CooldownManager.IsSystemOnCooldown(player, systemName)
    if not player or not systemName then return false end
    
    local playerId = tostring(player.UserId)
    local currentTime = getCurrentTime()
    
    local playerSystems = systemCooldowns[playerId]
    if not playerSystems then return false end
    
    local endTime = playerSystems[systemName]
    if not endTime then return false end
    
    return currentTime < endTime
end

-- 获取系统剩余冷却时间
function CooldownManager.GetSystemRemainingCooldown(player, systemName)
    if not player or not systemName then return 0 end
    
    local playerId = tostring(player.UserId)
    local currentTime = getCurrentTime()
    
    local playerSystems = systemCooldowns[playerId]
    if not playerSystems then return 0 end
    
    local endTime = playerSystems[systemName]
    if not endTime then return 0 end
    
    return math.max(0, endTime - currentTime)
end

-- 清除系统冷却
function CooldownManager.ClearSystemCooldown(player, systemName)
    if not player or not systemName then return false end
    
    local playerId = tostring(player.UserId)
    
    local playerSystems = systemCooldowns[playerId]
    if not playerSystems then return false end
    
    playerSystems[systemName] = nil
    
    -- 通知客户端冷却结束
    notifyClient(player, "system", systemName, nil, 0)
    
    return true
end

--------------------------------------------------------------------
-- 便捷函数
--------------------------------------------------------------------

-- 检查并设置机器冷却（如果不在冷却中则设置，返回是否可以使用）
function CooldownManager.TryUseMachine(player, machineType, instanceId, level)
    if CooldownManager.IsMachineOnCooldown(player, machineType, instanceId) then
        return false, CooldownManager.GetMachineRemainingCooldown(player, machineType, instanceId)
    end
    
    CooldownManager.SetMachineCooldown(player, machineType, instanceId, level)
    return true, 0
end

-- 检查并设置系统冷却
function CooldownManager.TryUseSystem(player, systemName, customTime)
    if CooldownManager.IsSystemOnCooldown(player, systemName) then
        return false, CooldownManager.GetSystemRemainingCooldown(player, systemName)
    end
    
    CooldownManager.SetSystemCooldown(player, systemName, customTime)
    return true, 0
end

-- 获取玩家所有冷却状态
function CooldownManager.GetPlayerCooldowns(player)
    if not player then return {} end
    
    local playerId = tostring(player.UserId)
    local result = {
        machines = {},
        systems = {}
    }
    
    -- 机器冷却
    local playerData = cooldownData[playerId]
    if playerData then
        for machineType, machines in pairs(playerData) do
            result.machines[machineType] = {}
            for instanceId, endTime in pairs(machines) do
                result.machines[machineType][instanceId] = {
                    remaining = math.max(0, endTime - getCurrentTime())
                }
            end
        end
    end
    
    -- 系统冷却
    local playerSystems = systemCooldowns[playerId]
    if playerSystems then
        for systemName, endTime in pairs(playerSystems) do
            result.systems[systemName] = {
                remaining = math.max(0, endTime - getCurrentTime())
            }
        end
    end
    
    return result
end

--------------------------------------------------------------------
-- 事件处理
--------------------------------------------------------------------

-- 玩家离开时清理数据
Players.PlayerRemoving:Connect(function(player)
    local playerId = tostring(player.UserId)
    cooldownData[playerId] = nil
    systemCooldowns[playerId] = nil
end)

-- 定期清理过期数据（每10秒）
local lastCleanup = 0
RunService.Heartbeat:Connect(function()
    local currentTime = getCurrentTime()
    if currentTime - lastCleanup >= 10 then
        cleanupExpiredCooldowns()
        lastCleanup = currentTime
    end
end)

-- 处理客户端请求
cooldownUpdateEvent.OnServerEvent:Connect(function(player, action)
    if action == "GET_ALL_COOLDOWNS" then
        local cooldowns = CooldownManager.GetPlayerCooldowns(player)
        cooldownUpdateEvent:FireClient(player, cooldowns)
    end
end)

print("[CooldownManager] 冷却时间管理系统已启动")

return CooldownManager