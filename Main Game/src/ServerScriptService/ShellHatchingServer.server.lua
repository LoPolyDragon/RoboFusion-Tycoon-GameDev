--------------------------------------------------------------------
-- ShellHatchingServer.server.lua · Shell孵化系统服务器端
-- 功能：
--   1) 处理Shell组装请求
--   2) 根据概率确定输出机器人类型  
--   3) 实现成功率机制
--   4) 播放孵化动画效果
--   5) 提供组装队列支持
--------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- 加载配置和服务
local GameConstants = require(ReplicatedStorage.SharedModules.GameConstants.main)
local GameLogic = require(script.Parent.ServerModules.GameLogicServer)

-- 创建RemoteEvents
local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteFolder then
    remoteFolder = Instance.new("Folder")
    remoteFolder.Name = "RemoteEvents"
    remoteFolder.Parent = ReplicatedStorage
end

local assembleShellEvent = remoteFolder:FindFirstChild("AssembleShellEvent")
if not assembleShellEvent then
    assembleShellEvent = Instance.new("RemoteEvent")
    assembleShellEvent.Name = "AssembleShellEvent"
    assembleShellEvent.Parent = remoteFolder
end

-- Shell配置数据
local SHELL_CONFIG = {
    RustyShell = {
        name = "Rusty Shell",
        rarity = "Uncommon",
        scrapCost = 10,
        outputs = {
            {robotId = "Dig_UncommonBot", chance = 50, type = "Dig"},
            {robotId = "Build_UncommonBot", chance = 50, type = "Build"}
        },
        successRate = 95, -- 95%成功率
        assemblyTime = 3.0 -- 3秒组装时间
    },
    NeonCoreShell = {
        name = "Neon Core Shell", 
        rarity = "Rare",
        scrapCost = 100,
        outputs = {
            {robotId = "Dig_RareBot", chance = 50, type = "Dig"},
            {robotId = "Build_RareBot", chance = 50, type = "Build"}
        },
        successRate = 85, -- 85%成功率
        assemblyTime = 10.0
    },
    QuantumCapsuleShell = {
        name = "Quantum Capsule",
        rarity = "Epic",
        scrapCost = 500,
        outputs = {
            {robotId = "Dig_EpicBot", chance = 45, type = "Dig"},
            {robotId = "Build_EpicBot", chance = 45, type = "Build"},
            {robotId = "Dig_SecretBot", chance = 5, type = "Dig"}, -- 5%概率获得Secret
            {robotId = "Build_SecretBot", chance = 5, type = "Build"}
        },
        successRate = 75, -- 75%成功率
        assemblyTime = 60.0
    },
    EcoBoosterPodShell = {
        name = "Eco Booster Pod",
        rarity = "Eco",
        scrapCost = 200,
        outputs = {
            {robotId = "Dig_EcoBot", chance = 50, type = "Dig"},
            {robotId = "Build_EcoBot", chance = 50, type = "Build"}
        },
        successRate = 90, -- 90%成功率
        assemblyTime = 20.0
    },
    SecretPrototypeShell = {
        name = "Secret Prototype",
        rarity = "Secret",
        scrapCost = 1000,
        outputs = {
            {robotId = "Dig_SecretBot", chance = 40, type = "Dig"},
            {robotId = "Build_SecretBot", chance = 40, type = "Build"},
            {robotId = "Dig_EpicBot", chance = 10, type = "Dig"}, -- 降级概率
            {robotId = "Build_EpicBot", chance = 10, type = "Build"}
        },
        successRate = 60, -- 60%成功率
        assemblyTime = 45.0
    }
}

-- 组装队列管理
local playerAssemblyQueues = {} -- [玩家] = {正在组装的任务列表}
local activeAssemblyTasks = {} -- [taskId] = 任务数据

-- 生成唯一任务ID
local taskIdCounter = 0
local function generateTaskId()
    taskIdCounter = taskIdCounter + 1
    return "assembly_task_" .. taskIdCounter .. "_" .. tick()
end

-- 获取建筑队列上限
local function getBuildingQueueLimit(player, buildingType)
    local playerData = GameLogic.GetPlayerData(player)
    if not playerData then return 1 end
    
    local upgrades = playerData.Upgrades or {}
    local level = upgrades[buildingType .. "Level"] or 1
    
    -- 根据GDD，各等级的队列上限
    local queueLimits = {1, 5, 12, 25, 40, 60, 90, 130, 190, 250}
    return queueLimits[level] or 1
end

-- 检查玩家是否有足够的Shell
local function hasEnoughShells(player, shellId, quantity)
    local inventory = GameLogic.GetInventoryDict(player)
    if not inventory then return false end
    
    local shellCount = inventory[shellId] or 0
    return shellCount >= quantity
end

-- 检查玩家是否有足够的Scrap（额外消耗）
local function hasEnoughScrap(player, shellId, quantity)
    local shellConfig = SHELL_CONFIG[shellId]
    if not shellConfig then return false end
    
    local playerData = GameLogic.GetPlayerData(player)
    if not playerData then return false end
    
    local scrapRequired = shellConfig.scrapCost * quantity
    local currentScrap = playerData.Scrap or 0
    
    return currentScrap >= scrapRequired
end

-- 根据概率选择输出机器人
local function selectOutputRobot(shellConfig)
    local totalChance = 0
    for _, output in ipairs(shellConfig.outputs) do
        totalChance = totalChance + output.chance
    end
    
    local randomValue = math.random(1, totalChance)
    local accumulatedChance = 0
    
    for _, output in ipairs(shellConfig.outputs) do
        accumulatedChance = accumulatedChance + output.chance
        if randomValue <= accumulatedChance then
            return output.robotId, output.type
        end
    end
    
    -- 默认返回第一个
    return shellConfig.outputs[1].robotId, shellConfig.outputs[1].type
end

-- 检查组装成功
local function isAssemblySuccessful(shellConfig)
    local randomValue = math.random(1, 100)
    return randomValue <= shellConfig.successRate
end

-- 创建组装任务
local function createAssemblyTask(player, shellId, quantity)
    local shellConfig = SHELL_CONFIG[shellId]
    if not shellConfig then
        return nil, "未知的Shell类型"
    end
    
    -- 检查资源
    if not hasEnoughShells(player, shellId, quantity) then
        return nil, "Shell数量不足"
    end
    
    if not hasEnoughScrap(player, shellId, quantity) then
        return nil, string.format("Scrap不足，需要 %d", shellConfig.scrapCost * quantity)
    end
    
    -- 检查队列上限
    local queueLimit = getBuildingQueueLimit(player, "Assembler")
    local currentQueue = playerAssemblyQueues[player] or {}
    
    if #currentQueue >= queueLimit then
        return nil, string.format("队列已满 (%d/%d)", #currentQueue, queueLimit)
    end
    
    -- 扣除资源
    if not GameLogic.RemoveItem(player, shellId, quantity) then
        return nil, "扣除Shell失败"
    end
    
    local scrapCost = shellConfig.scrapCost * quantity
    if not GameLogic.AddScrap(player, -scrapCost) then
        -- 如果扣除Scrap失败，退还Shell
        GameLogic.AddItem(player, shellId, quantity)
        return nil, "扣除Scrap失败"
    end
    
    -- 创建任务
    local taskId = generateTaskId()
    local startTime = tick()
    
    local taskData = {
        taskId = taskId,
        player = player,
        shellId = shellId,
        shellConfig = shellConfig,
        quantity = quantity,
        completed = 0,
        startTime = startTime,
        assemblyTime = shellConfig.assemblyTime,
        estimatedEndTime = startTime + (shellConfig.assemblyTime * quantity),
        status = "QUEUED", -- QUEUED, ASSEMBLING, COMPLETED, FAILED
        results = {} -- 存储组装结果
    }
    
    return taskData, "任务创建成功"
end

-- 开始组装任务
local function startAssemblyTask(taskData)
    taskData.status = "ASSEMBLING"
    taskData.currentStartTime = tick()
    taskData.currentItemIndex = 1
    
    print(string.format("[ShellHatching] 开始组装任务 %s: %s x%d", 
          taskData.taskId, taskData.shellConfig.name, taskData.quantity))
end

-- 完成单个组装
local function completeAssemblyItem(taskData)
    local shellConfig = taskData.shellConfig
    local success = isAssemblySuccessful(shellConfig)
    
    if success then
        local robotId, robotType = selectOutputRobot(shellConfig)
        
        -- 添加机器人到库存
        GameLogic.AddItem(taskData.player, robotId, 1)
        
        table.insert(taskData.results, {
            success = true,
            robotId = robotId,
            robotType = robotType
        })
        
        print(string.format("[ShellHatching] 组装成功: %s -> %s", 
              shellConfig.name, robotId))
    else
        table.insert(taskData.results, {
            success = false,
            reason = "组装失败"
        })
        
        print(string.format("[ShellHatching] 组装失败: %s", shellConfig.name))
    end
    
    taskData.completed = taskData.completed + 1
end

-- 完成整个组装任务
local function completeAssemblyTask(taskData)
    taskData.status = "COMPLETED"
    
    -- 统计结果
    local successCount = 0
    local failureCount = 0
    local resultSummary = {}
    
    for _, result in ipairs(taskData.results) do
        if result.success then
            successCount = successCount + 1
            local robotId = result.robotId
            if not resultSummary[robotId] then
                resultSummary[robotId] = 0
            end
            resultSummary[robotId] = resultSummary[robotId] + 1
        else
            failureCount = failureCount + 1
        end
    end
    
    -- 构建结果消息
    local resultText = {}
    for robotId, count in pairs(resultSummary) do
        table.insert(resultText, string.format("%s x%d", robotId:gsub("_", " "), count))
    end
    
    local message
    if successCount > 0 then
        message = string.format("组装完成! 获得: %s", table.concat(resultText, ", "))
        if failureCount > 0 then
            message = message .. string.format(" (失败: %d)", failureCount)
        end
    else
        message = string.format("组装失败! 所有 %d 次尝试都失败了", taskData.quantity)
    end
    
    print(string.format("[ShellHatching] 任务完成 %s: %s", taskData.taskId, message))
    
    -- 发送结果给客户端
    assembleShellEvent:FireClient(taskData.player, successCount > 0, message)
    
    -- 更新库存
    local updateInventoryEvent = remoteFolder:FindFirstChild("UpdateInventoryEvent")
    if updateInventoryEvent then
        updateInventoryEvent:FireClient(taskData.player, GameLogic.GetInventoryDict(taskData.player))
    end
    
    -- 从队列中移除任务
    local playerQueue = playerAssemblyQueues[taskData.player]
    if playerQueue then
        for i, queuedTask in ipairs(playerQueue) do
            if queuedTask.taskId == taskData.taskId then
                table.remove(playerQueue, i)
                break
            end
        end
    end
    
    activeAssemblyTasks[taskData.taskId] = nil
end

-- 更新组装进度
local function updateAssemblyProgress()
    for taskId, taskData in pairs(activeAssemblyTasks) do
        if taskData.status == "ASSEMBLING" then
            local currentTime = tick()
            local timePerItem = taskData.assemblyTime
            local itemStartTime = taskData.currentStartTime or taskData.startTime
            
            -- 检查当前项目是否完成
            if currentTime - itemStartTime >= timePerItem then
                completeAssemblyItem(taskData)
                
                -- 检查是否还有更多项目要组装
                if taskData.completed < taskData.quantity then
                    taskData.currentStartTime = currentTime
                    taskData.currentItemIndex = taskData.completed + 1
                else
                    -- 所有项目完成
                    completeAssemblyTask(taskData)
                end
            end
        end
    end
    
    -- 启动排队的任务
    for player, queue in pairs(playerAssemblyQueues) do
        if #queue > 0 then
            local nextTask = queue[1]
            if nextTask.status == "QUEUED" then
                -- 检查是否有其他正在进行的任务
                local hasActiveTask = false
                for _, task in ipairs(queue) do
                    if task.status == "ASSEMBLING" then
                        hasActiveTask = true
                        break
                    end
                end
                
                if not hasActiveTask then
                    startAssemblyTask(nextTask)
                    activeAssemblyTasks[nextTask.taskId] = nextTask
                end
            end
        end
    end
end

-- 处理Shell组装请求
assembleShellEvent.OnServerEvent:Connect(function(player, shellId, quantity)
    print(string.format("[ShellHatching] 收到组装请求: %s, Shell: %s, 数量: %d", 
          player.Name, shellId, quantity))
    
    -- 验证参数
    quantity = math.max(1, math.floor(quantity or 1))
    if quantity > 100 then -- 限制最大数量
        quantity = 100
    end
    
    if not SHELL_CONFIG[shellId] then
        assembleShellEvent:FireClient(player, false, "未知的Shell类型: " .. tostring(shellId))
        return
    end
    
    -- 创建组装任务
    local taskData, errorMsg = createAssemblyTask(player, shellId, quantity)
    if not taskData then
        assembleShellEvent:FireClient(player, false, errorMsg)
        return
    end
    
    -- 添加到玩家队列
    if not playerAssemblyQueues[player] then
        playerAssemblyQueues[player] = {}
    end
    
    table.insert(playerAssemblyQueues[player], taskData)
    
    -- 发送确认消息
    local queuePosition = #playerAssemblyQueues[player]
    local message = string.format("已加入队列 (%d/%d): %s x%d", 
                                  queuePosition, getBuildingQueueLimit(player, "Assembler"),
                                  SHELL_CONFIG[shellId].name, quantity)
    
    assembleShellEvent:FireClient(player, true, message)
    
    print(string.format("[ShellHatching] 任务已创建: %s", taskData.taskId))
end)

-- 玩家离开时清理
Players.PlayerRemoving:Connect(function(player)
    -- 清理玩家的组装队列
    local queue = playerAssemblyQueues[player]
    if queue then
        for _, taskData in ipairs(queue) do
            activeAssemblyTasks[taskData.taskId] = nil
        end
        playerAssemblyQueues[player] = nil
    end
    
    print(string.format("[ShellHatching] 清理玩家数据: %s", player.Name))
end)

-- 启动更新循环
local lastUpdate = 0
RunService.Heartbeat:Connect(function()
    local currentTime = tick()
    if currentTime - lastUpdate >= 0.1 then -- 每0.1秒更新一次
        updateAssemblyProgress()
        lastUpdate = currentTime
    end
end)

print("[ShellHatching] Shell孵化系统已启动")