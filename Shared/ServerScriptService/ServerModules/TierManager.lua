--------------------------------------------------------------------
-- TierManager.lua · Tier解锁系统管理
-- 功能：
--   1) Tier进度跟踪
--   2) 解锁条件检查
--   3) 自动Tier升级
--   4) 建筑和工具限制管理
--------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 加载配置
local GameConstants = require(ReplicatedStorage.SharedModules.GameConstants.main)
local TIER_SYSTEM = GameConstants.TIER_SYSTEM

--------------------------------------------------------------------
-- Tier管理器
--------------------------------------------------------------------
local TierManager = {}

-- 依赖注入
local GameLogicServer = nil

--------------------------------------------------------------------
-- 初始化系统
--------------------------------------------------------------------
function TierManager.Init(gameLogicRef)
    GameLogicServer = gameLogicRef
    print("[TierManager] Tier解锁系统已初始化")
end

--------------------------------------------------------------------
-- 获取玩家当前Tier状态
--------------------------------------------------------------------
function TierManager.GetPlayerTierStatus(player)
    local data = GameLogicServer.GetPlayerData(player)
    if not data then
        return nil
    end
    
    return {
        currentTier = data.CurrentTier or 0,
        maxDepthReached = data.MaxDepthReached or 0,
        tierProgress = data.TierProgress or {}
    }
end

--------------------------------------------------------------------
-- 更新进度数据
--------------------------------------------------------------------

-- 更新收集进度
function TierManager.UpdateCollectionProgress(player, itemType, amount)
    local data = GameLogicServer.GetPlayerData(player)
    if not data or not data.TierProgress then
        return
    end
    
    -- 物品ID到进度键的映射
    local itemToProgressKey = {
        ["scrap"] = "scrapCollected",
        ["IronOre"] = "ironOreCollected",
        ["BronzeOre"] = "bronzeOreCollected", 
        ["GoldOre"] = "goldOreCollected",
        ["DiamondOre"] = "diamondOreCollected",
        ["TitaniumOre"] = "titaniumOreCollected"
    }
    
    local progressKey = itemToProgressKey[itemType]
    if progressKey and data.TierProgress[progressKey] then
        data.TierProgress[progressKey] = data.TierProgress[progressKey] + amount
        print(("[TierManager] 玩家 %s 收集进度更新: %s = %d"):format(
            player.Name, progressKey, data.TierProgress[progressKey]))
        
        -- 检查是否可以解锁新Tier
        TierManager._CheckTierUpgrade(player)
    end
end

-- 更新制作进度
function TierManager.UpdateCraftingProgress(player, itemType, amount)
    local data = GameLogicServer.GetPlayerData(player)
    if not data or not data.TierProgress then
        return
    end
    
    -- 物品ID到进度键的映射
    local itemToProgressKey = {
        ["IronBar"] = "ironBarCrafted",
        ["BronzeGear"] = "bronzeGearCrafted",
        ["GoldPlatedEdge"] = "goldPlatedEdgeCrafted"
    }
    
    local progressKey = itemToProgressKey[itemType]
    if progressKey and data.TierProgress[progressKey] then
        data.TierProgress[progressKey] = data.TierProgress[progressKey] + amount
        print(("[TierManager] 玩家 %s 制作进度更新: %s = %d"):format(
            player.Name, progressKey, data.TierProgress[progressKey]))
        
        -- 检查是否可以解锁新Tier
        TierManager._CheckTierUpgrade(player)
    end
end

-- 更新深度记录
function TierManager.UpdateDepthProgress(player, depth)
    local data = GameLogicServer.GetPlayerData(player)
    if not data then
        return
    end
    
    if depth > (data.MaxDepthReached or 0) then
        data.MaxDepthReached = depth
        print(("[TierManager] 玩家 %s 深度记录更新: %d"):format(player.Name, depth))
        
        -- 检查是否可以解锁新Tier
        TierManager._CheckTierUpgrade(player)
    end
end

-- 更新建筑等级记录
function TierManager.UpdateBuildingLevelProgress(player, level)
    local data = GameLogicServer.GetPlayerData(player)
    if not data or not data.TierProgress then
        return
    end
    
    if level > (data.TierProgress.maxBuildingLevel or 1) then
        data.TierProgress.maxBuildingLevel = level
        print(("[TierManager] 玩家 %s 建筑等级记录更新: %d"):format(player.Name, level))
        
        -- 检查是否可以解锁新Tier
        TierManager._CheckTierUpgrade(player)
    end
end

-- 更新建筑数量
function TierManager.UpdateBuildingCount(player, buildingType, count)
    local data = GameLogicServer.GetPlayerData(player)
    if not data or not data.TierProgress then
        return
    end
    
    if buildingType == "EnergyStation" then
        data.TierProgress.energyStationsBuilt = count
        print(("[TierManager] 玩家 %s 能量站数量更新: %d"):format(player.Name, count))
        
        -- 检查是否可以解锁新Tier
        TierManager._CheckTierUpgrade(player)
    end
end

-- 标记教程完成
function TierManager.MarkTutorialComplete(player)
    local data = GameLogicServer.GetPlayerData(player)
    if not data or not data.TierProgress then
        return
    end
    
    data.TierProgress.tutorialComplete = true
    print(("[TierManager] 玩家 %s 教程完成"):format(player.Name))
    
    -- 检查是否可以解锁新Tier
    TierManager._CheckTierUpgrade(player)
end

--------------------------------------------------------------------
-- Tier检查和升级
--------------------------------------------------------------------

-- 内部函数：检查Tier升级
function TierManager._CheckTierUpgrade(player)
    local data = GameLogicServer.GetPlayerData(player)
    if not data then
        return
    end
    
    local currentTier = data.CurrentTier or 0
    local nextTier = currentTier + 1
    
    -- 检查是否有下一个Tier
    if not TIER_SYSTEM.REQUIREMENTS[nextTier] then
        return
    end
    
    -- 检查解锁条件
    if TierManager._CheckTierRequirements(player, nextTier) then
        TierManager._UpgradePlayerTier(player, nextTier)
    end
end

-- 检查特定Tier的解锁条件
function TierManager._CheckTierRequirements(player, tier)
    local data = GameLogicServer.GetPlayerData(player)
    if not data or not TIER_SYSTEM.REQUIREMENTS[tier] then
        return false
    end
    
    local requirements = TIER_SYSTEM.REQUIREMENTS[tier].requirements
    local progress = data.TierProgress or {}
    
    -- 检查每个要求
    for reqType, reqValue in pairs(requirements) do
        if reqType == "scrap" then
            if (data.Scrap or 0) + (progress.scrapCollected or 0) < reqValue then
                return false
            end
        elseif reqType == "tutorialComplete" then
            if not progress.tutorialComplete then
                return false
            end
        elseif reqType == "ironOre" then
            if (progress.ironOreCollected or 0) < reqValue then
                return false
            end
        elseif reqType == "bronzeOre" then
            if (progress.bronzeOreCollected or 0) < reqValue then
                return false
            end
        elseif reqType == "goldOre" then
            if (progress.goldOreCollected or 0) < reqValue then
                return false
            end
        elseif reqType == "diamondOre" then
            if (progress.diamondOreCollected or 0) < reqValue then
                return false
            end
        elseif reqType == "titaniumOre" then
            if (progress.titaniumOreCollected or 0) < reqValue then
                return false
            end
        elseif reqType == "ironBar" then
            if (progress.ironBarCrafted or 0) < reqValue then
                return false
            end
        elseif reqType == "bronzeGear" then
            if (progress.bronzeGearCrafted or 0) < reqValue then
                return false
            end
        elseif reqType == "goldPlatedEdge" then
            if (progress.goldPlatedEdgeCrafted or 0) < reqValue then
                return false
            end
        elseif reqType == "depth" then
            if (data.MaxDepthReached or 0) < reqValue then
                return false
            end
        elseif reqType == "buildingLevel" then
            if (progress.maxBuildingLevel or 1) < reqValue then
                return false
            end
        elseif reqType == "energyStation" then
            if (progress.energyStationsBuilt or 0) < reqValue then
                return false
            end
        end
    end
    
    return true
end

-- 升级玩家Tier
function TierManager._UpgradePlayerTier(player, newTier)
    local data = GameLogicServer.GetPlayerData(player)
    if not data then
        return
    end
    
    local oldTier = data.CurrentTier or 0
    data.CurrentTier = newTier
    
    local tierInfo = TIER_SYSTEM.REQUIREMENTS[newTier]
    
    print(("[TierManager] 🎉 玩家 %s Tier升级: %d → %d (%s)"):format(
        player.Name, oldTier, newTier, tierInfo.name))
    
    -- 发送升级通知给客户端
    local RE = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if RE then
        local tierUpgradeEvent = RE:FindFirstChild("TierUpgradeEvent")
        if not tierUpgradeEvent then
            tierUpgradeEvent = Instance.new("RemoteEvent")
            tierUpgradeEvent.Name = "TierUpgradeEvent"
            tierUpgradeEvent.Parent = RE
        end
        
        tierUpgradeEvent:FireClient(player, {
            oldTier = oldTier,
            newTier = newTier,
            tierName = tierInfo.name,
            tierDescription = tierInfo.description,
            unlocks = tierInfo.unlocks
        })
    end
end

--------------------------------------------------------------------
-- 限制检查函数
--------------------------------------------------------------------

-- 检查建筑是否可以升级到指定等级
function TierManager.CanUpgradeBuilding(player, buildingType, targetLevel)
    local data = GameLogicServer.GetPlayerData(player)
    if not data then
        return false, "玩家数据不存在"
    end
    
    local currentTier = data.CurrentTier or 0
    local maxLevel = TIER_SYSTEM.BUILDING_LEVEL_LIMITS[currentTier] or 1
    
    if targetLevel > maxLevel then
        local tierInfo = TIER_SYSTEM.REQUIREMENTS[currentTier + 1]
        local tierName = tierInfo and tierInfo.name or ("Tier " .. (currentTier + 1))
        return false, ("需要解锁 %s 才能升级到Lv%d"):format(tierName, targetLevel)
    end
    
    return true, "可以升级"
end

-- 检查工具是否已解锁
function TierManager.IsToolUnlocked(player, toolType)
    local data = GameLogicServer.GetPlayerData(player)
    if not data then
        return false
    end
    
    local currentTier = data.CurrentTier or 0
    local requiredTier = TIER_SYSTEM.TOOL_UNLOCKS[toolType]
    
    if not requiredTier then
        return true -- 未配置的工具默认解锁
    end
    
    return currentTier >= requiredTier
end

-- 检查建筑是否已解锁
function TierManager.IsBuildingUnlocked(player, buildingType)
    local data = GameLogicServer.GetPlayerData(player)
    if not data then
        return false
    end
    
    local currentTier = data.CurrentTier or 0
    local requiredTier = TIER_SYSTEM.BUILDING_UNLOCKS[buildingType]
    
    if not requiredTier then
        return true -- 未配置的建筑默认解锁
    end
    
    return currentTier >= requiredTier
end

--------------------------------------------------------------------
-- 查询函数
--------------------------------------------------------------------

-- 获取当前Tier信息
function TierManager.GetCurrentTierInfo(player)
    local data = GameLogicServer.GetPlayerData(player)
    if not data then
        return nil
    end
    
    local currentTier = data.CurrentTier or 0
    local tierInfo = TIER_SYSTEM.REQUIREMENTS[currentTier]
    
    return {
        tier = currentTier,
        name = tierInfo and tierInfo.name or "未知Tier",
        description = tierInfo and tierInfo.description or "",
        unlocks = tierInfo and tierInfo.unlocks or {}
    }
end

-- 获取下一个Tier的进度
function TierManager.GetNextTierProgress(player)
    local data = GameLogicServer.GetPlayerData(player)
    if not data then
        return nil
    end
    
    local currentTier = data.CurrentTier or 0
    local nextTier = currentTier + 1
    local nextTierInfo = TIER_SYSTEM.REQUIREMENTS[nextTier]
    
    if not nextTierInfo then
        return nil -- 已达最高Tier
    end
    
    local progress = data.TierProgress or {}
    local requirements = nextTierInfo.requirements
    local progressData = {}
    
    -- 计算各项进度
    for reqType, reqValue in pairs(requirements) do
        local currentValue = 0
        
        if reqType == "scrap" then
            currentValue = (data.Scrap or 0) + (progress.scrapCollected or 0)
        elseif reqType == "tutorialComplete" then
            currentValue = progress.tutorialComplete and 1 or 0
            reqValue = 1
        elseif reqType == "ironOre" then
            currentValue = progress.ironOreCollected or 0
        elseif reqType == "bronzeOre" then
            currentValue = progress.bronzeOreCollected or 0
        elseif reqType == "goldOre" then
            currentValue = progress.goldOreCollected or 0
        elseif reqType == "diamondOre" then
            currentValue = progress.diamondOreCollected or 0
        elseif reqType == "titaniumOre" then
            currentValue = progress.titaniumOreCollected or 0
        elseif reqType == "ironBar" then
            currentValue = progress.ironBarCrafted or 0
        elseif reqType == "bronzeGear" then
            currentValue = progress.bronzeGearCrafted or 0
        elseif reqType == "goldPlatedEdge" then
            currentValue = progress.goldPlatedEdgeCrafted or 0
        elseif reqType == "depth" then
            currentValue = data.MaxDepthReached or 0
        elseif reqType == "buildingLevel" then
            currentValue = progress.maxBuildingLevel or 1
        elseif reqType == "energyStation" then
            currentValue = progress.energyStationsBuilt or 0
        end
        
        progressData[reqType] = {
            current = currentValue,
            required = reqValue,
            completed = currentValue >= reqValue
        }
    end
    
    return {
        tier = nextTier,
        name = nextTierInfo.name,
        description = nextTierInfo.description,
        unlocks = nextTierInfo.unlocks,
        progress = progressData
    }
end

-- 获取所有Tier的概览信息
function TierManager.GetAllTiersOverview(player)
    local data = GameLogicServer.GetPlayerData(player)
    if not data then
        return {}
    end
    
    local currentTier = data.CurrentTier or 0
    local overview = {}
    
    for tier = 0, 4 do
        local tierInfo = TIER_SYSTEM.REQUIREMENTS[tier]
        if tierInfo then
            table.insert(overview, {
                tier = tier,
                name = tierInfo.name,
                description = tierInfo.description,
                unlocks = tierInfo.unlocks,
                isUnlocked = tier <= currentTier,
                isCurrent = tier == currentTier
            })
        end
    end
    
    return overview
end

return TierManager