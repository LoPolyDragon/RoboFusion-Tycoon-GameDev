--------------------------------------------------------------------
-- BuildingUpgradeServer.server.lua · 建筑升级系统服务器端
-- 功能：
--   1) 处理建筑升级请求和验证
--   2) 管理建筑等级和属性数据
--   3) 支持所有建筑类型的10级升级系统
--   4) 计算升级成本和效果
--------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 等待共享模块
local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
local GameConstants = require(SharedModules.GameConstants.main)

-- 创建/获取RemoteEvents
local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteFolder then
    remoteFolder = Instance.new("Folder")
    remoteFolder.Name = "RemoteEvents"
    remoteFolder.Parent = ReplicatedStorage
end

local rfFolder = ReplicatedStorage:FindFirstChild("RemoteFunctions")
if not rfFolder then
    rfFolder = Instance.new("Folder")
    rfFolder.Name = "RemoteFunctions"
    rfFolder.Parent = ReplicatedStorage
end

local upgradeMachineEvent = Instance.new("RemoteEvent")
upgradeMachineEvent.Name = "UpgradeMachineEvent"
upgradeMachineEvent.Parent = remoteFolder

local getBuildingUpgradeInfoRF = Instance.new("RemoteFunction")
getBuildingUpgradeInfoRF.Name = "GetBuildingUpgradeInfoFunction"
getBuildingUpgradeInfoRF.Parent = rfFolder

-- 等待PlayerDataManager
local PlayerDataManager
task.spawn(function()
    PlayerDataManager = require(script.Parent:WaitForChild("PlayerDataManager"))
    print("[BuildingUpgradeServer] PlayerDataManager已加载")
end)

--------------------------------------------------------------------
-- 工具函数
--------------------------------------------------------------------

-- 获取玩家当前积分
local function getPlayerCredits(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local credits = leaderstats:FindFirstChild("Credits")
        if credits then
            return credits.Value
        end
    end
    return 0
end

-- 扣除玩家积分
local function deductPlayerCredits(player, amount)
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local credits = leaderstats:FindFirstChild("Credits")
        if credits and credits.Value >= amount then
            credits.Value = credits.Value - amount
            return true
        end
    end
    return false
end

-- 获取玩家建筑等级数据
local function getPlayerBuildingLevel(player, buildingType)
    if not PlayerDataManager then return 1 end
    
    local playerData = PlayerDataManager.GetPlayerData(player)
    if not playerData then return 1 end
    
    local upgrades = playerData.Upgrades or {}
    local levelKey = buildingType .. "Level"
    return upgrades[levelKey] or 1
end

-- 设置玩家建筑等级
local function setPlayerBuildingLevel(player, buildingType, level)
    if not PlayerDataManager then return false end
    
    local playerData = PlayerDataManager.GetPlayerData(player)
    if not playerData then return false end
    
    if not playerData.Upgrades then
        playerData.Upgrades = {}
    end
    
    local levelKey = buildingType .. "Level"
    playerData.Upgrades[levelKey] = level
    
    -- 保存数据
    PlayerDataManager.SavePlayerData(player)
    
    print("[BuildingUpgradeServer] 玩家", player.Name, "的", buildingType, "升级到等级", level)
    return true
end

-- 获取建筑升级成本
local function getBuildingUpgradeCost(buildingType, currentLevel)
    local costs = GameConstants.BUILDING_UPGRADE_COST[buildingType]
    if not costs then 
        warn("[BuildingUpgradeServer] 未找到建筑类型的升级成本:", buildingType)
        return nil 
    end
    
    if currentLevel >= 10 then
        return nil -- 已达最高等级
    end
    
    return costs[currentLevel + 1] or nil
end

-- 获取建筑升级后的属性
local function getBuildingUpgradeStats(buildingType, level)
    local upgradeData = GameConstants.BUILDING_UPGRADE_DATA
    local queueLimit = upgradeData.QueueLimit[level] or 1
    
    local stats = {
        level = level,
        queueLimit = queueLimit
    }
    
    -- 添加建筑特定属性
    local buildingData = upgradeData[buildingType]
    if buildingData then
        for statName, values in pairs(buildingData) do
            if statName ~= "description" and type(values) == "table" then
                stats[statName] = values[level] or values[1] or 1
            end
        end
    end
    
    return stats
end

-- 验证建筑类型
local function isValidBuildingType(buildingType)
    local validTypes = {
        "Crusher", "Generator", "Assembler", "Shipper",
        "ToolForge", "Smelter", "EnergyStation"
    }
    
    for _, validType in ipairs(validTypes) do
        if buildingType == validType then
            return true
        end
    end
    
    return false
end

--------------------------------------------------------------------
-- 核心升级系统
--------------------------------------------------------------------

-- 获取建筑升级信息
local function getBuildingUpgradeInfo(player, buildingType)
    print("[BuildingUpgradeServer] 获取建筑升级信息:", player.Name, buildingType)
    
    if not isValidBuildingType(buildingType) then
        warn("[BuildingUpgradeServer] 无效的建筑类型:", buildingType)
        return nil
    end
    
    local currentLevel = getPlayerBuildingLevel(player, buildingType)
    local nextLevel = currentLevel + 1
    
    -- 检查是否已达最高等级
    if currentLevel >= 10 then
        print("[BuildingUpgradeServer] 建筑已达最高等级:", buildingType, "等级:", currentLevel)
        return nil
    end
    
    local upgradeCost = getBuildingUpgradeCost(buildingType, currentLevel)
    if not upgradeCost then
        print("[BuildingUpgradeServer] 无法获取升级成本:", buildingType, "等级:", currentLevel)
        return nil
    end
    
    local playerCredits = getPlayerCredits(player)
    local canAfford = playerCredits >= upgradeCost
    
    local currentStats = getBuildingUpgradeStats(buildingType, currentLevel)
    local nextStats = getBuildingUpgradeStats(buildingType, nextLevel)
    
    local upgradeInfo = {
        buildingType = buildingType,
        currentLevel = currentLevel,
        nextLevel = nextLevel,
        cost = upgradeCost,
        canAfford = canAfford,
        playerCredits = playerCredits,
        currentStats = currentStats,
        nextStats = nextStats
    }
    
    print("[BuildingUpgradeServer] 升级信息:", upgradeInfo.buildingType, "等级", upgradeInfo.currentLevel, "->", upgradeInfo.nextLevel, "成本:", upgradeInfo.cost)
    return upgradeInfo
end

-- 执行建筑升级
local function upgradeBuildingMachine(player, buildingType)
    print("[BuildingUpgradeServer] 处理升级请求:", player.Name, buildingType)
    
    if not isValidBuildingType(buildingType) then
        warn("[BuildingUpgradeServer] 无效的建筑类型:", buildingType)
        return false
    end
    
    local currentLevel = getPlayerBuildingLevel(player, buildingType)
    
    -- 检查是否已达最高等级
    if currentLevel >= 10 then
        warn("[BuildingUpgradeServer] 建筑已达最高等级:", buildingType, "等级:", currentLevel)
        return false
    end
    
    local upgradeCost = getBuildingUpgradeCost(buildingType, currentLevel)
    if not upgradeCost then
        warn("[BuildingUpgradeServer] 无法获取升级成本:", buildingType, "等级:", currentLevel)
        return false
    end
    
    -- 验证玩家是否有足够积分
    local playerCredits = getPlayerCredits(player)
    if playerCredits < upgradeCost then
        warn("[BuildingUpgradeServer] 积分不足:", player.Name, "需要:", upgradeCost, "当前:", playerCredits)
        return false
    end
    
    -- 扣除积分
    if not deductPlayerCredits(player, upgradeCost) then
        warn("[BuildingUpgradeServer] 扣除积分失败:", player.Name, "金额:", upgradeCost)
        return false
    end
    
    -- 升级建筑
    local newLevel = currentLevel + 1
    if not setPlayerBuildingLevel(player, buildingType, newLevel) then
        -- 升级失败，退还积分
        local leaderstats = player:FindFirstChild("leaderstats")
        if leaderstats then
            local credits = leaderstats:FindFirstChild("Credits")
            if credits then
                credits.Value = credits.Value + upgradeCost
            end
        end
        warn("[BuildingUpgradeServer] 设置建筑等级失败:", player.Name, buildingType)
        return false
    end
    
    -- 更新Tier进度（如果需要）
    if PlayerDataManager then
        local playerData = PlayerDataManager.GetPlayerData(player)
        if playerData and playerData.TierProgress then
            local maxLevel = playerData.TierProgress.maxBuildingLevel or 1
            if newLevel > maxLevel then
                playerData.TierProgress.maxBuildingLevel = newLevel
                PlayerDataManager.SavePlayerData(player)
                print("[BuildingUpgradeServer] 更新Tier进度 - 最高建筑等级:", newLevel)
            end
        end
    end
    
    print("[BuildingUpgradeServer] 升级成功:", player.Name, buildingType, "等级", currentLevel, "->", newLevel, "花费:", upgradeCost)
    return true
end

--------------------------------------------------------------------
-- 事件处理
--------------------------------------------------------------------

-- 处理升级请求
upgradeMachineEvent.OnServerEvent:Connect(function(player, buildingType)
    print("[BuildingUpgradeServer] 收到升级请求:", player.Name, buildingType)
    
    local success = upgradeBuildingMachine(player, buildingType)
    
    if success then
        print("[BuildingUpgradeServer] 升级成功通知客户端")
        -- 可以在这里发送成功通知给客户端
    else
        print("[BuildingUpgradeServer] 升级失败")
        -- 可以在这里发送失败通知给客户端
    end
end)

-- 处理升级信息请求
getBuildingUpgradeInfoRF.OnServerInvoke = function(player, buildingType)
    return getBuildingUpgradeInfo(player, buildingType)
end

--------------------------------------------------------------------
-- 导出函数供其他脚本使用
--------------------------------------------------------------------
local BuildingUpgradeServer = {}
BuildingUpgradeServer.getBuildingUpgradeInfo = getBuildingUpgradeInfo
BuildingUpgradeServer.upgradeBuildingMachine = upgradeBuildingMachine
BuildingUpgradeServer.getPlayerBuildingLevel = getPlayerBuildingLevel
BuildingUpgradeServer.setPlayerBuildingLevel = setPlayerBuildingLevel
BuildingUpgradeServer.getBuildingUpgradeStats = getBuildingUpgradeStats

-- 将模块导出到全局供其他服务器脚本使用
_G.BuildingUpgradeServer = BuildingUpgradeServer

print("[BuildingUpgradeServer] 建筑升级系统服务器端已启动")