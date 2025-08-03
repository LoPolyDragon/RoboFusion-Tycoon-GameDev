--------------------------------------------------------------------
-- BuildingPlacementServer.server.lua · 建筑放置服务器处理
-- 功能：
--   1) 处理客户端建筑放置请求
--   2) 验证放置合法性
--   3) 管理建筑生命周期
--   4) 同步建筑状态
--------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- 依赖模块
local BuildingManager = require(game.ServerScriptService.ServerModules.BuildingManager)
local CooldownManager = require(game.ServerScriptService.ServerModules.CooldownManager)
local GameLogic = require(game.ServerScriptService.ServerModules.GameLogicServer)

-- RemoteEvents设置
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

local manageBuildingEvent = buildingEvents:FindFirstChild("ManageBuildingEvent")
if not manageBuildingEvent then
    manageBuildingEvent = Instance.new("RemoteEvent")
    manageBuildingEvent.Name = "ManageBuildingEvent"
    manageBuildingEvent.Parent = buildingEvents
end

--------------------------------------------------------------------
-- 建筑放置处理
--------------------------------------------------------------------

placeBuildingEvent.OnServerEvent:Connect(function(player, action, data)
    if not player or not action or not data then return end
    
    if action == "PLACE" then
        -- 检查系统冷却
        local canUse, remainingTime = CooldownManager.TryUseSystem(player, "BUILDING_PLACEMENT", 1)
        if not canUse then
            placeBuildingEvent:FireClient(player, "PLACE_FAILED", {
                reason = string.format("操作太频繁，请等待 %.1f 秒", remainingTime)
            })
            return
        end
        
        -- 验证数据
        if not data.buildingType or not data.position then
            placeBuildingEvent:FireClient(player, "PLACE_FAILED", {
                reason = "无效的放置数据"
            })
            return
        end
        
        -- 尝试放置建筑
        local success, message, buildingData = BuildingManager.PlaceBuilding(
            player, 
            data.buildingType, 
            data.position, 
            data.rotation
        )
        
        if success then
            placeBuildingEvent:FireClient(player, "PLACE_SUCCESS", {
                buildingType = data.buildingType,
                buildingId = buildingData.id,
                position = buildingData.position
            })
            
            -- 通知其他相关系统
            manageBuildingEvent:FireClient(player, "BUILDING_ADDED", buildingData)
            
        else
            placeBuildingEvent:FireClient(player, "PLACE_FAILED", {
                reason = message
            })
        end
        
    elseif action == "REMOVE" then
        -- 移除建筑
        if not data.buildingId then
            placeBuildingEvent:FireClient(player, "REMOVE_FAILED", {
                reason = "无效的建筑ID"
            })
            return
        end
        
        local success, message = BuildingManager.RemoveBuilding(player, data.buildingId)
        
        if success then
            placeBuildingEvent:FireClient(player, "REMOVE_SUCCESS", {
                buildingId = data.buildingId
            })
            
            manageBuildingEvent:FireClient(player, "BUILDING_REMOVED", {
                buildingId = data.buildingId
            })
        else
            placeBuildingEvent:FireClient(player, "REMOVE_FAILED", {
                reason = message
            })
        end
        
    elseif action == "GET_BUILDINGS" then
        -- 获取玩家所有建筑
        local buildings = BuildingManager.GetPlayerBuildings(player)
        placeBuildingEvent:FireClient(player, "BUILDINGS_LIST", buildings)
        
    elseif action == "UPGRADE" then
        -- 升级建筑
        if not data.buildingId then
            placeBuildingEvent:FireClient(player, "UPGRADE_FAILED", {
                reason = "无效的建筑ID"
            })
            return
        end
        
        -- 检查升级冷却
        local canUpgrade, remainingTime = CooldownManager.TryUseSystem(player, "BUILDING_UPGRADE")
        if not canUpgrade then
            placeBuildingEvent:FireClient(player, "UPGRADE_FAILED", {
                reason = string.format("升级冷却中，请等待 %.1f 秒", remainingTime)
            })
            return
        end
        
        local success, message = BuildingManager.UpgradeBuilding(player, data.buildingId)
        
        if success then
            local buildingData = BuildingManager.GetBuilding(player, data.buildingId)
            placeBuildingEvent:FireClient(player, "UPGRADE_SUCCESS", {
                buildingId = data.buildingId,
                newLevel = buildingData.level
            })
            
            manageBuildingEvent:FireClient(player, "BUILDING_UPGRADED", buildingData)
        else
            placeBuildingEvent:FireClient(player, "UPGRADE_FAILED", {
                reason = message
            })
        end
    end
end)

--------------------------------------------------------------------
-- 建筑管理处理
--------------------------------------------------------------------

manageBuildingEvent.OnServerEvent:Connect(function(player, action, data)
    if not player or not action then return end
    
    if action == "GET_BUILDING_INFO" then
        -- 获取特定建筑信息
        if not data or not data.buildingId then return end
        
        local buildingData = BuildingManager.GetBuilding(player, data.buildingId)
        if buildingData then
            manageBuildingEvent:FireClient(player, "BUILDING_INFO", buildingData)
        end
        
    elseif action == "TOGGLE_BUILDING" then
        -- 切换建筑开关状态
        if not data or not data.buildingId then return end
        
        local buildingData = BuildingManager.GetBuilding(player, data.buildingId)
        if buildingData then
            buildingData.status = buildingData.status == "active" and "inactive" or "active"
            manageBuildingEvent:FireClient(player, "BUILDING_TOGGLED", {
                buildingId = data.buildingId,
                status = buildingData.status
            })
            
            print(string.format("[BuildingServer] 建筑 %s 状态切换为: %s", 
                data.buildingId, buildingData.status))
        end
        
    elseif action == "GET_BUILDING_STATS" then
        -- 获取建筑统计信息
        local buildings = BuildingManager.GetPlayerBuildings(player)
        local stats = {
            totalBuildings = 0,
            buildingsByType = {},
            totalPowerConsumption = 0,
            totalPowerProduction = 0
        }
        
        for _, building in pairs(buildings) do
            stats.totalBuildings = stats.totalBuildings + 1
            stats.buildingsByType[building.type] = (stats.buildingsByType[building.type] or 0) + 1
            
            if building.config.energyConsumption then
                stats.totalPowerConsumption = stats.totalPowerConsumption + building.config.energyConsumption
            end
            if building.config.energyProduction then
                stats.totalPowerProduction = stats.totalPowerProduction + building.config.energyProduction
            end
        end
        
        manageBuildingEvent:FireClient(player, "BUILDING_STATS", stats)
    end
end)

--------------------------------------------------------------------
-- 建筑功能处理循环
--------------------------------------------------------------------

-- 建筑生产和功能更新
local lastUpdate = 0
RunService.Heartbeat:Connect(function()
    local currentTime = tick()
    if currentTime - lastUpdate < 1 then return end -- 每秒更新一次
    lastUpdate = currentTime
    
    for _, player in ipairs(Players:GetPlayers()) do
        local buildings = BuildingManager.GetPlayerBuildings(player)
        
        for buildingId, building in pairs(buildings) do
            if building.status == "active" then
                -- 处理不同类型建筑的功能
                processBuildingFunction(player, building)
            end
        end
    end
end)

-- 处理建筑功能
function processBuildingFunction(player, building)
    local currentTime = tick()
    
    -- 检查是否到了生产时间
    if currentTime - building.lastProduction < 5 then -- 每5秒生产一次
        return
    end
    
    building.lastProduction = currentTime
    
    -- 根据建筑类型处理不同功能
    if building.type == "Generator" then
        -- 发电机产生电力（这里简化为给玩家加Credits）
        local energyProduced = building.config.energyProduction * building.level
        GameLogic.AddCredits(player, energyProduced)
        
    elseif building.type == "Crusher" then
        -- 粉碎机处理废料
        local playerData = GameLogic.GetPlayerData(player)
        if playerData.Scrap >= 10 then
            GameLogic.AddScrap(player, -10)
            GameLogic.AddCredits(player, 5 * building.level)
        end
        
    elseif building.type == "StorageWarehouse" then
        -- 仓库增加存储容量（被动效果，这里不需要处理）
        
    elseif building.type == "ResearchLab" then
        -- 研究实验室产生研究点数
        -- TODO: 实现研究系统后添加
        
    elseif building.type == "EnergyStation" then
        -- 能量站充能机器人
        -- TODO: 与机器人系统集成
    end
    
    -- 通知客户端建筑状态更新
    manageBuildingEvent:FireClient(player, "BUILDING_PRODUCED", {
        buildingId = building.id,
        buildingType = building.type,
        production = building.lastProduction
    })
end

--------------------------------------------------------------------
-- 玩家连接处理
--------------------------------------------------------------------

Players.PlayerAdded:Connect(function(player)
    -- 玩家加入时发送建筑列表
    player.CharacterAdded:Connect(function()
        task.wait(2) -- 等待客户端加载完成
        
        local buildings = BuildingManager.GetPlayerBuildings(player)
        placeBuildingEvent:FireClient(player, "BUILDINGS_LIST", buildings)
    end)
end)

print("[BuildingPlacementServer] 建筑放置服务器已启动")