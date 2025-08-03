--------------------------------------------------------------------
-- BuildingManager.lua · 建筑系统核心管理模块
-- 功能：
--   1) 建筑放置验证和网格对齐
--   2) 建筑数据管理和持久化
--   3) 建筑间关系和依赖管理
--   4) 美观度和效果计算
--   5) 电力网络管理
--------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local GameConstants = require(ReplicatedStorage.SharedModules.GameConstants)
local GameLogic = require(game.ServerScriptService.ServerModules.GameLogicServer)

local BuildingManager = {}

-- 建筑数据存储 [playerId] = {buildings = {}, grid = {}, beauty = {}, power = {}}
local playerBuildings = {}

-- 全局建筑网格大小
local GRID_SIZE = GameConstants.BUILDING_PLACEMENT_RULES.gridSize or 2

--------------------------------------------------------------------
-- 内部工具函数
--------------------------------------------------------------------

-- 世界坐标转网格坐标
local function worldToGrid(position)
    return Vector3.new(
        math.floor(position.X / GRID_SIZE + 0.5) * GRID_SIZE,
        position.Y,
        math.floor(position.Z / GRID_SIZE + 0.5) * GRID_SIZE
    )
end

-- 检查网格位置是否被占用
local function isGridOccupied(playerId, gridPos, buildingSize)
    local playerData = playerBuildings[playerId]
    if not playerData then return false end
    
    -- 计算建筑占用的网格范围
    local halfSize = Vector3.new(
        math.ceil(buildingSize.X / GRID_SIZE / 2),
        0,
        math.ceil(buildingSize.Z / GRID_SIZE / 2)
    )
    
    for x = gridPos.X - halfSize.X, gridPos.X + halfSize.X - 1 do
        for z = gridPos.Z - halfSize.Z, gridPos.Z + halfSize.Z - 1 do
            local gridKey = string.format("%d,%d", x, z)
            if playerData.grid[gridKey] then
                return true
            end
        end
    end
    
    return false
end

-- 占用网格位置
local function occupyGrid(playerId, gridPos, buildingSize, buildingId)
    local playerData = playerBuildings[playerId]
    if not playerData then return end
    
    local halfSize = Vector3.new(
        math.ceil(buildingSize.X / GRID_SIZE / 2),
        0,
        math.ceil(buildingSize.Z / GRID_SIZE / 2)
    )
    
    for x = gridPos.X - halfSize.X, gridPos.X + halfSize.X - 1 do
        for z = gridPos.Z - halfSize.Z, gridPos.Z + halfSize.Z - 1 do
            local gridKey = string.format("%d,%d", x, z)
            playerData.grid[gridKey] = buildingId
        end
    end
end

-- 释放网格位置
local function freeGrid(playerId, gridPos, buildingSize)
    local playerData = playerBuildings[playerId]
    if not playerData then return end
    
    local halfSize = Vector3.new(
        math.ceil(buildingSize.X / GRID_SIZE / 2),
        0,
        math.ceil(buildingSize.Z / GRID_SIZE / 2)
    )
    
    for x = gridPos.X - halfSize.X, gridPos.X + halfSize.X - 1 do
        for z = gridPos.Z - halfSize.Z, gridPos.Z + halfSize.Z - 1 do
            local gridKey = string.format("%d,%d", x, z)
            playerData.grid[gridKey] = nil
        end
    end
end

-- 获取建筑配置
local function getBuildingConfig(buildingType)
    for category, buildings in pairs(GameConstants.BUILDING_TYPES) do
        if buildings[buildingType] then
            return buildings[buildingType]
        end
    end
    return nil
end

-- 计算建筑成本
local function calculateBuildingCost(buildingType, level)
    local config = getBuildingConfig(buildingType)
    if not config then return nil end
    
    local baseCost = config.baseCost
    local multiplier = GameConstants.BUILDING_UPGRADE_FORMULA.costMultiplier
    
    return math.floor(baseCost * (multiplier ^ (level - 1)))
end

-- 初始化玩家建筑数据
local function initPlayerData(playerId)
    if not playerBuildings[playerId] then
        playerBuildings[playerId] = {
            buildings = {},      -- [buildingId] = buildingData
            grid = {},          -- [gridKey] = buildingId
            beauty = {},        -- 美观度缓存
            power = {           -- 电力网络
                generators = {},
                consumers = {},
                connections = {}
            },
            nextBuildingId = 1
        }
    end
end

--------------------------------------------------------------------
-- 建筑放置验证
--------------------------------------------------------------------

-- 检查建筑是否可以放置
function BuildingManager.CanPlaceBuilding(player, buildingType, position)
    if not player or not buildingType or not position then
        return false, "无效参数"
    end
    
    local playerId = tostring(player.UserId)
    initPlayerData(playerId)
    
    local config = getBuildingConfig(buildingType)
    if not config then
        return false, "未知建筑类型"
    end
    
    -- 检查解锁条件
    local unlockCondition = GameConstants.BUILDING_UNLOCK_CONDITIONS[buildingType]
    if unlockCondition then
        local playerData = GameLogic.GetPlayerData(player)
        if playerData.CurrentTier < unlockCondition.tier then
            return false, string.format("需要达到Tier %d才能解锁", unlockCondition.tier)
        end
        if playerData.Credits < unlockCondition.credits then
            return false, string.format("需要%d Credits才能解锁", unlockCondition.credits)
        end
    end
    
    -- 检查玩家资金
    local cost = calculateBuildingCost(buildingType, 1)
    local playerData = GameLogic.GetPlayerData(player)
    if playerData.Credits < cost then
        return false, string.format("资金不足，需要%d Credits", cost)
    end
    
    -- 网格对齐
    local gridPos = worldToGrid(position)
    
    -- 检查网格占用
    if isGridOccupied(playerId, gridPos, config.baseSize) then
        return false, "该位置已被占用"
    end
    
    -- 检查与其他建筑的距离
    local minDistance = GameConstants.BUILDING_PLACEMENT_RULES.minDistanceFromOthers
    local playerData = playerBuildings[playerId]
    for _, building in pairs(playerData.buildings) do
        local distance = (gridPos - building.position).Magnitude
        if distance < minDistance then
            return false, string.format("距离其他建筑太近，最小距离%d格", minDistance)
        end
    end
    
    -- 检查电力连接（如果需要）
    if config.energyConsumption > 0 then
        local hasNearbyPower = BuildingManager.CheckPowerConnection(playerId, gridPos)
        if not hasNearbyPower then
            local maxDistance = GameConstants.BUILDING_PLACEMENT_RULES.maxDistanceFromPower
            return false, string.format("距离电力源太远，最大距离%d格", maxDistance)
        end
    end
    
    return true, "可以放置", {
        cost = cost,
        gridPosition = gridPos,
        config = config
    }
end

-- 检查电力连接
function BuildingManager.CheckPowerConnection(playerId, position)
    local playerData = playerBuildings[playerId]
    if not playerData then return false end
    
    local maxDistance = GameConstants.BUILDING_PLACEMENT_RULES.maxDistanceFromPower
    
    -- 检查是否在发电机范围内
    for _, generator in pairs(playerData.power.generators) do
        local distance = (position - generator.position).Magnitude
        if distance <= maxDistance then
            return true
        end
    end
    
    -- 检查是否在电力线网络中
    for _, connection in pairs(playerData.power.connections) do
        local distance = (position - connection.position).Magnitude
        if distance <= GRID_SIZE * 2 then -- 电力线连接范围
            return true
        end
    end
    
    return false
end

--------------------------------------------------------------------
-- 建筑放置和移除
--------------------------------------------------------------------

-- 放置建筑
function BuildingManager.PlaceBuilding(player, buildingType, position, rotation)
    local canPlace, reason, data = BuildingManager.CanPlaceBuilding(player, buildingType, position)
    if not canPlace then
        return false, reason
    end
    
    local playerId = tostring(player.UserId)
    local playerData = playerBuildings[playerId]
    local buildingId = "building_" .. playerData.nextBuildingId
    playerData.nextBuildingId = playerData.nextBuildingId + 1
    
    -- 扣除资金
    GameLogic.AddCredits(player, -data.cost)
    
    -- 创建建筑数据
    local buildingData = {
        id = buildingId,
        type = buildingType,
        position = data.gridPosition,
        rotation = rotation or 0,
        level = 1,
        config = data.config,
        status = "active", -- active, inactive, upgrading, damaged
        lastProduction = 0,
        inventory = {},
        connections = {},
        placedTime = tick()
    }
    
    -- 存储建筑数据
    playerData.buildings[buildingId] = buildingData
    
    -- 占用网格
    occupyGrid(playerId, data.gridPosition, data.config.baseSize, buildingId)
    
    -- 更新电力网络
    if data.config.energyProduction and data.config.energyProduction > 0 then
        playerData.power.generators[buildingId] = buildingData
    elseif data.config.energyConsumption and data.config.energyConsumption > 0 then
        playerData.power.consumers[buildingId] = buildingData
    end
    
    -- 创建3D模型
    local success = BuildingManager.CreateBuildingModel(player, buildingData)
    if not success then
        -- 回滚操作
        BuildingManager.RemoveBuilding(player, buildingId)
        return false, "创建建筑模型失败"
    end
    
    print(string.format("[BuildingManager] 玩家 %s 放置了 %s (ID: %s)", 
        player.Name, buildingType, buildingId))
    
    return true, "建筑放置成功", buildingData
end

-- 移除建筑
function BuildingManager.RemoveBuilding(player, buildingId)
    local playerId = tostring(player.UserId)
    local playerData = playerBuildings[playerId]
    if not playerData then return false, "玩家数据不存在" end
    
    local building = playerData.buildings[buildingId]
    if not building then return false, "建筑不存在" end
    
    -- 释放网格
    freeGrid(playerId, building.position, building.config.baseSize)
    
    -- 从电力网络移除
    playerData.power.generators[buildingId] = nil
    playerData.power.consumers[buildingId] = nil
    
    -- 移除3D模型
    BuildingManager.DestroyBuildingModel(player, buildingId)
    
    -- 返还部分资金
    local refund = math.floor(calculateBuildingCost(building.type, building.level) * 0.7)
    GameLogic.AddCredits(player, refund)
    
    -- 移除建筑数据
    playerData.buildings[buildingId] = nil
    
    print(string.format("[BuildingManager] 玩家 %s 移除了建筑 %s，返还 %d Credits", 
        player.Name, buildingId, refund))
    
    return true, "建筑移除成功"
end

--------------------------------------------------------------------
-- 3D模型管理
--------------------------------------------------------------------

-- 创建建筑3D模型
function BuildingManager.CreateBuildingModel(player, buildingData)
    local success, model = pcall(function()
        -- 查找建筑模型
        local modelName = buildingData.type
        local modelTemplate = game.ServerStorage:FindFirstChild("BuildingModels")
        if modelTemplate then
            modelTemplate = modelTemplate:FindFirstChild(modelName)
        end
        
        -- 如果没有预制模型，创建简单的占位符
        local buildingModel
        if modelTemplate then
            buildingModel = modelTemplate:Clone()
        else
            buildingModel = Instance.new("Model")
            buildingModel.Name = modelName
            
            -- 创建主体部分
            local mainPart = Instance.new("Part")
            mainPart.Name = "MainPart"
            mainPart.Size = buildingData.config.baseSize
            mainPart.Material = Enum.Material.Concrete
            mainPart.BrickColor = BrickColor.new("Medium stone grey")
            mainPart.TopSurface = Enum.SurfaceType.Smooth
            mainPart.BottomSurface = Enum.SurfaceType.Smooth
            mainPart.CanCollide = true
            mainPart.Anchored = true
            mainPart.Parent = buildingModel
            
            -- 添加标识文字
            local surfaceGui = Instance.new("SurfaceGui")
            surfaceGui.Face = Enum.NormalId.Top
            surfaceGui.Parent = mainPart
            
            local textLabel = Instance.new("TextLabel")
            textLabel.Size = UDim2.new(1, 0, 1, 0)
            textLabel.BackgroundTransparency = 1
            textLabel.Text = buildingData.config.icon .. "\\n" .. buildingData.config.name
            textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            textLabel.TextScaled = true
            textLabel.Font = Enum.Font.SourceSansBold
            textLabel.Parent = surfaceGui
        end
        
        -- 设置建筑属性
        buildingModel:SetAttribute("BuildingId", buildingData.id)
        buildingModel:SetAttribute("BuildingType", buildingData.type)
        buildingModel:SetAttribute("Owner", player.UserId)
        buildingModel:SetAttribute("Level", buildingData.level)
        
        -- 设置位置和旋转
        local cf = CFrame.new(buildingData.position) * CFrame.Angles(0, math.rad(buildingData.rotation), 0)
        buildingModel:SetPrimaryPartCFrame(cf)
        
        -- 放置到工作区
        local playerFolder = workspace:FindFirstChild("PlayerBuildings_" .. player.UserId)
        if not playerFolder then
            playerFolder = Instance.new("Folder")
            playerFolder.Name = "PlayerBuildings_" .. player.UserId
            playerFolder.Parent = workspace
        end
        
        buildingModel.Parent = playerFolder
        
        return buildingModel
    end)
    
    if success then
        print(string.format("[BuildingManager] 成功创建建筑模型: %s", buildingData.id))
        return true
    else
        warn(string.format("[BuildingManager] 创建建筑模型失败: %s - %s", buildingData.id, tostring(model)))
        return false
    end
end

-- 销毁建筑3D模型
function BuildingManager.DestroyBuildingModel(player, buildingId)
    local playerFolder = workspace:FindFirstChild("PlayerBuildings_" .. player.UserId)
    if not playerFolder then return end
    
    for _, model in ipairs(playerFolder:GetChildren()) do
        if model:GetAttribute("BuildingId") == buildingId then
            model:Destroy()
            break
        end
    end
end

--------------------------------------------------------------------
-- 数据管理
--------------------------------------------------------------------

-- 获取玩家所有建筑
function BuildingManager.GetPlayerBuildings(player)
    local playerId = tostring(player.UserId)
    initPlayerData(playerId)
    return playerBuildings[playerId].buildings
end

-- 获取特定建筑数据
function BuildingManager.GetBuilding(player, buildingId)
    local playerId = tostring(player.UserId)
    local playerData = playerBuildings[playerId]
    if not playerData then return nil end
    
    return playerData.buildings[buildingId]
end

-- 升级建筑
function BuildingManager.UpgradeBuilding(player, buildingId)
    local playerId = tostring(player.UserId)
    local playerData = playerBuildings[playerId]
    if not playerData then return false, "玩家数据不存在" end
    
    local building = playerData.buildings[buildingId]
    if not building then return false, "建筑不存在" end
    
    if building.level >= building.config.maxLevel then
        return false, "建筑已达到最高级"
    end
    
    local upgradeCost = calculateBuildingCost(building.type, building.level + 1)
    local playerGameData = GameLogic.GetPlayerData(player)
    if playerGameData.Credits < upgradeCost then
        return false, string.format("资金不足，需要%d Credits", upgradeCost)
    end
    
    -- 扣除资金
    GameLogic.AddCredits(player, -upgradeCost)
    
    -- 升级建筑
    building.level = building.level + 1
    
    -- 更新3D模型属性
    local playerFolder = workspace:FindFirstChild("PlayerBuildings_" .. player.UserId)
    if playerFolder then
        for _, model in ipairs(playerFolder:GetChildren()) do
            if model:GetAttribute("BuildingId") == buildingId then
                model:SetAttribute("Level", building.level)
                break
            end
        end
    end
    
    print(string.format("[BuildingManager] 玩家 %s 将建筑 %s 升级到 Lv%d", 
        player.Name, buildingId, building.level))
    
    return true, "建筑升级成功"
end

--------------------------------------------------------------------
-- 事件处理
--------------------------------------------------------------------

-- 玩家离开时清理数据
Players.PlayerRemoving:Connect(function(player)
    local playerId = tostring(player.UserId)
    playerBuildings[playerId] = nil
    
    -- 清理工作区中的建筑模型
    local playerFolder = workspace:FindFirstChild("PlayerBuildings_" .. player.UserId)
    if playerFolder then
        playerFolder:Destroy()
    end
end)

print("[BuildingManager] 建筑管理系统已启动")

return BuildingManager