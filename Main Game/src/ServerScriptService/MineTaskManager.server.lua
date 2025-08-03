--------------------------------------------------------------------
-- MineTaskManager.server.lua - 挖矿任务管理器
-- 功能：
--   1) 管理玩家的挖矿任务
--   2) 处理机器人挖矿逻辑
--   3) 计算挖矿时间和进度
--   4) 处理挖矿结果和奖励
--------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

local GameLogic = require(game.ServerScriptService.ServerModules.GameLogicServer)
local GameConstants = require(ReplicatedStorage.SharedModules.GameConstants)

-- 地图ID
local MINE_PLACE_ID = 101306428432235 -- 挖矿地图PlaceId
local MAIN_PLACE_ID = 82341741981647  -- 主地图PlaceId

-- RemoteEvents
local mineTaskEvent = ReplicatedStorage.RemoteEvents:FindFirstChild("MineTaskEvent")
if not mineTaskEvent then
    mineTaskEvent = Instance.new("RemoteEvent")
    mineTaskEvent.Name = "MineTaskEvent" 
    mineTaskEvent.Parent = ReplicatedStorage.RemoteEvents
end

local botReturnEvent = ReplicatedStorage.RemoteEvents:FindFirstChild("BotReturnEvent")
if not botReturnEvent then
    botReturnEvent = Instance.new("RemoteEvent")
    botReturnEvent.Name = "BotReturnEvent"
    botReturnEvent.Parent = ReplicatedStorage.RemoteEvents
end

local activeTasks = {}

local miningStats = {}

--------------------------------------------------------------------
-- 工具函数
--------------------------------------------------------------------

-- 获取玩家的机器人列表
local function getPlayerBots(player)
    local data = GameLogic.GetPlayerData(player)
    if not data then return {} end
    
    local bots = {}
    -- 这里应该从玩家数据中获取机器人
    -- 暂时返回测试数据
    return {
        {id = "bot1", type = "UncommonBot", category = "MN", level = 1},
        {id = "bot2", type = "RareBot", category = "MN", level = 2},
    }
end

-- 检查机器人是否能挖矿
local function canBotMine(bot, oreName) 
    local oreInfo = GameConstants.ORE_INFO[oreName]
    if not oreInfo then return false end
    
    -- 根据机器人等级计算最大硬度
    local maxHardness = bot.level or 1
    if bot.type == "RareBot" then maxHardness = maxHardness + 1 end
    if bot.type == "EpicBot" then maxHardness = maxHardness + 2 end
    if bot.type == "SecretBot" then maxHardness = maxHardness + 3 end
    
    return oreInfo.hardness <= maxHardness
end

-- 估算挖矿时间
local function estimateMiningTime(bot, oreName, quantity)
    local oreInfo = GameConstants.ORE_INFO[oreName]
    if not oreInfo then return 60 end
    
    local baseTime = oreInfo.time or 1
    local botSpeed = GameConstants.BotStats[bot.type] and GameConstants.BotStats[bot.type].interval or 3
    
    -- 挖矿时间 = 基础时间 * 数量 / 机器人速度
    return math.ceil(baseTime * quantity * botSpeed)
end

--------------------------------------------------------------------
-- 任务管理
--------------------------------------------------------------------

-- 创建挖矿任务
local function createMiningTask(player, botId, oreName, quantity)
    local playerId = player.UserId
    
    if not activeTasks[playerId] then
        activeTasks[playerId] = {tasks = {}}
    end
    
    local task = {
        id = #activeTasks[playerId].tasks + 1,
        botId = botId,
        oreName = oreName,
        quantity = quantity,
        startTime = tick(),
        estimatedTime = estimateMiningTime({type = "UncommonBot", level = 1}, oreName, quantity),
        status = "active", -- active, completed, failed
        progress = 0
    }
    
    table.insert(activeTasks[playerId].tasks, task)
    
    print(("[MineTaskManager] 创建任务 - 玩家: %s, 机器人: %s, 矿石: %s, 数量: %d"):format(
        player.Name, botId, oreName, quantity))
    
    return task
end

-- 完成挖矿任务
local function completeMiningTask(player, taskId, actualQuantity)
    local playerId = player.UserId
    local playerTasks = activeTasks[playerId]
    
    if not playerTasks then return false end
    
    local task = playerTasks.tasks[taskId]
    if not task then return false end
    
    task.status = "completed"
    task.progress = actualQuantity or task.quantity
    task.completedTime = tick()
    
    -- 添加奖励
    if task.oreName == "Scrap" then
        GameLogic.AddScrap(player, task.progress)
    else
        GameLogic.AddItem(player, task.oreName, task.progress)
    end
    
    -- 更新统计
    if not miningStats[playerId] then
        miningStats[playerId] = {}
    end
    miningStats[playerId][task.oreName] = (miningStats[playerId][task.oreName] or 0) + task.progress
    
    print(("[MineTaskManager] 完成任务 - 玩家: %s, 获得: %d %s"):format(
        player.Name, task.progress, task.oreName))
    
    -- 通知客户端
    mineTaskEvent:FireClient(player, "TASK_COMPLETED", {
        taskId = taskId,
        oreName = task.oreName,
        quantity = task.progress,
        botId = task.botId
    })
    
    return true
end

-- 获取玩家任务列表
local function getPlayerTasks(player)
    local playerId = player.UserId
    return activeTasks[playerId] and activeTasks[playerId].tasks or {}
end

--------------------------------------------------------------------
-- RemoteEvent 处理
--------------------------------------------------------------------

-- 处理客户端请求
mineTaskEvent.OnServerEvent:Connect(function(player, action, data)
    if action == "START_MINING" then
        local botId = data.botId
        local oreName = data.oreName  
        local quantity = data.quantity or 10
        
        -- 参数验证
        if not botId or not oreName or not GameConstants.ORE_INFO[oreName] then
            mineTaskEvent:FireClient(player, "ERROR", "参数错误")
            return
        end
        
        -- 检查机器人是否存在
        local playerBots = getPlayerBots(player)
        local selectedBot = nil
        for _, bot in ipairs(playerBots) do
            if bot.id == botId then
                selectedBot = bot
                break
            end
        end
        
        if not selectedBot then
            mineTaskEvent:FireClient(player, "ERROR", "机器人不存在")
            return
        end
        
        -- 检查机器人是否能挖矿
        if not canBotMine(selectedBot, oreName) then
            mineTaskEvent:FireClient(player, "ERROR", "机器人等级不足")
            return
        end
        
        -- 创建任务
        local task = createMiningTask(player, botId, oreName, quantity)
        
        -- 通知客户端
        mineTaskEvent:FireClient(player, "TASK_STARTED", {
            taskId = task.id,
            estimatedTime = task.estimatedTime,
            botId = botId,
            oreName = oreName,
            quantity = quantity
        })
        
    elseif action == "GET_TASKS" then
        -- 获取任务列表
        local tasks = getPlayerTasks(player)
        mineTaskEvent:FireClient(player, "TASKS_LIST", tasks)
        
    elseif action == "CANCEL_TASK" then
        local taskId = data.taskId
        local playerId = player.UserId
        
        if activeTasks[playerId] and activeTasks[playerId].tasks[taskId] then
            activeTasks[playerId].tasks[taskId].status = "cancelled"
            mineTaskEvent:FireClient(player, "TASK_CANCELLED", {taskId = taskId})
        end
        
    elseif action == "GET_BOTS" then
        -- 获取机器人列表
        local bots = getPlayerBots(player)
        mineTaskEvent:FireClient(player, "BOTS_LIST", bots)
        
    elseif action == "GET_STATS" then
        -- 获取挖矿统计
        local playerId = player.UserId
        local stats = miningStats[playerId] or {}
        mineTaskEvent:FireClient(player, "MINING_STATS", stats)
    end
end)

-- 处理机器人返回
botReturnEvent.OnServerEvent:Connect(function(player, botId, results)
    if not results then return end
    
    local playerId = player.UserId
    local playerTasks = activeTasks[playerId]
    
    if not playerTasks then return end
    
    -- 查找对应任务
    for i, task in ipairs(playerTasks.tasks) do
        if task.botId == botId and task.status == "active" then
            completeMiningTask(player, i, results.quantity)
            break
        end
    end
end)

--------------------------------------------------------------------
-- 定时更新
--------------------------------------------------------------------
RunService.Heartbeat:Connect(function()
    local currentTime = tick()
    
    for playerId, playerTasks in pairs(activeTasks) do
        local player = Players:GetPlayerByUserId(playerId)
        if not player then
            -- 清理离线玩家
            activeTasks[playerId] = nil
        else
            -- 更新进度
            for i, task in ipairs(playerTasks.tasks) do
                if task.status == "active" then
                    local elapsed = currentTime - task.startTime
                    local progress = math.min(elapsed / task.estimatedTime, 1)
                    task.progress = math.floor(progress * task.quantity)
                    
                    -- 检查是否完成
                    if elapsed >= task.estimatedTime then
                        completeMiningTask(player, i, task.quantity)
                    end
                end
            end
        end
    end
end)

--------------------------------------------------------------------
-- 玩家离开
--------------------------------------------------------------------
Players.PlayerRemoving:Connect(function(player)
    local playerId = player.UserId
    activeTasks[playerId] = nil
    miningStats[playerId] = nil
end)

print("[MineTaskManager] 挖矿任务管理器已启动")