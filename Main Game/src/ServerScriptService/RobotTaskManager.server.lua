--------------------------------------------------------------------
-- RobotTaskManager.server.lua · 机器人任务管理服务器端
-- 功能：
--   1) 处理机器人任务派发
--   2) 管理机器人工作状态
--   3) 在Mine world中创建工作机器人
--   4) 处理任务完成和奖励
--------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

-- 创建RemoteEvents
local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteFolder then
    remoteFolder = Instance.new("Folder")
    remoteFolder.Name = "RemoteEvents"
    remoteFolder.Parent = ReplicatedStorage
end

local miningTaskEvent = Instance.new("RemoteEvent")
miningTaskEvent.Name = "MiningTaskEvent"
miningTaskEvent.Parent = remoteFolder

-- 配置
local GameConstants = require(ReplicatedStorage.SharedModules.GameConstants.main)

-- 任务存储结构
local playerWorkingRobots = {} -- [玩家] = { [机器人ID] = 工作机器人模型 }
local taskIdCounter = 0

-- 获取PlayerDataManager的RemoteEvent
local playerDataEvent = nil
task.spawn(function()
    local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
    playerDataEvent = remoteFolder:WaitForChild("PlayerDataEvent", 10)
    if not playerDataEvent then
        warn("[RobotTaskManager] PlayerDataEvent不可用，数据将不被持久化")
    end
end)

-- 生成唯一任务ID
local function generateTaskId()
    taskIdCounter = taskIdCounter + 1
    return "task_" .. taskIdCounter .. "_" .. tick()
end

-- 获取机器人基础类型
local function getRobotBaseType(robotType)
    return robotType:gsub("Dig_", ""):gsub("Build_", "")
end

-- 计算任务预计完成时间
local function calculateTaskDuration(robotType, oreType, quantity)
    local baseType = getRobotBaseType(robotType)
    local robotStats = GameConstants.BotStats[baseType]
    local oreInfo = GameConstants.ORE_INFO[oreType]
    
    if not robotStats or not oreInfo then
        return 60 -- 默认1分钟
    end
    
    -- 机器人挖矿间隔 * 矿物挖掘时间 * 数量
    local totalTime = robotStats.interval * oreInfo.time * quantity
    return math.ceil(totalTime)
end

-- 创建任务数据结构
local function createMiningTask(player, robotType, oreType, quantity)
    local taskId = generateTaskId()
    local duration = calculateTaskDuration(robotType, oreType, quantity)
    local startTime = tick()
    
    local taskData = {
        taskId = taskId,
        player = player,
        robotType = robotType,
        taskType = "MINING",
        oreType = oreType,
        quantity = quantity,
        completed = 0,
        startTime = startTime,
        estimatedEndTime = startTime + duration,
        status = "ASSIGNED", -- ASSIGNED, WORKING, COMPLETED, CANCELLED
        location = "MAIN_WORLD" -- 当前所在世界
    }
    
    return taskData
end

-- 将机器人从main world移除（但保持Active状态）
local function removeActiveRobotFromMainWorld(player, robotType)
    print("[RobotTaskManager] 将机器人从main world移除:", robotType, "玩家:", player.Name)
    
    -- 找到并移除在main world跟随玩家的机器人
    -- 但保持在Active状态，只是暂时不跟随
    local Players = game:GetService("Players")
    
    -- 查找玩家的跟随机器人并移除
    for _, robot in pairs(workspace:GetChildren()) do
        if robot:IsA("Model") and robot:GetAttribute("Owner") == player.Name and 
           robot:GetAttribute("RobotType") == robotType and robot:GetAttribute("Type") == "Robot" then
            print("[RobotTaskManager] 找到main world中的机器人，移除:", robot.Name)
            robot:Destroy()
            return true
        end
    end
    
    print("[RobotTaskManager] 机器人已从main world移除，但保持Active状态")
    return true
end

-- 在Mine world中创建工作机器人
local function createWorkingRobotInMine(player, taskData)
    -- 检查Mine world是否存在
    local mineWorld = workspace:FindFirstChild("MineWorld")
    if not mineWorld then
        warn("[RobotTaskManager] MineWorld不存在，无法创建工作机器人")
        return nil
    end
    
    -- 获取机器人模板
    local robotTemplates = ServerStorage:FindFirstChild("RobotTemplates")
    if not robotTemplates then
        warn("[RobotTaskManager] ServerStorage/RobotTemplates不存在")
        return nil
    end
    
    local baseType = getRobotBaseType(taskData.robotType)
    local template = robotTemplates:FindFirstChild(baseType)
    if not template then
        warn("[RobotTaskManager] 找不到机器人模板:", baseType)
        return nil
    end
    
    -- 克隆机器人
    local workingRobot = template:Clone()
    workingRobot.Name = taskData.robotType .. "_Working_" .. taskData.taskId
    
    -- 设置机器人属性
    workingRobot:SetAttribute("Type", "WorkingRobot")
    workingRobot:SetAttribute("RobotType", taskData.robotType)
    workingRobot:SetAttribute("Owner", player.Name)
    workingRobot:SetAttribute("TaskId", taskData.taskId)
    workingRobot:SetAttribute("TaskType", taskData.taskType)
    workingRobot:SetAttribute("TargetOre", taskData.oreType)
    workingRobot:SetAttribute("TargetQuantity", taskData.quantity)
    workingRobot:SetAttribute("CompletedQuantity", 0)
    workingRobot:SetAttribute("Status", "WORKING")
    
    -- 设置初始位置（在Mine world的随机位置）
    local spawnArea = mineWorld:FindFirstChild("RobotSpawnArea")
    local spawnPos
    if spawnArea and spawnArea:IsA("Part") then
        local areaSize = spawnArea.Size
        spawnPos = spawnArea.Position + Vector3.new(
            math.random(-areaSize.X/2, areaSize.X/2),
            areaSize.Y/2 + 5,
            math.random(-areaSize.Z/2, areaSize.Z/2)
        )
    else
        -- 默认位置
        spawnPos = Vector3.new(0, 50, 0) + Vector3.new(
            math.random(-20, 20), 0, math.random(-20, 20)
        )
    end
    
    if workingRobot.PrimaryPart then
        workingRobot:SetPrimaryPartCFrame(CFrame.new(spawnPos))
    elseif workingRobot:FindFirstChild("HumanoidRootPart") then
        workingRobot.HumanoidRootPart.Position = spawnPos
    end
    
    workingRobot.Parent = mineWorld
    
    print("[RobotTaskManager] 在Mine world创建工作机器人:", workingRobot.Name, "位置:", spawnPos)
    return workingRobot
end

-- 派发挖矿任务
local function assignMiningTask(player, robotType, oreType, quantity)
    print("[RobotTaskManager] 收到挖矿任务:", player.Name, robotType, oreType, quantity)
    
    -- 验证参数
    if not robotType:find("Dig_") then
        warn("[RobotTaskManager] 只有挖矿机器人可以执行挖矿任务:", robotType)
        return false
    end
    
    if not GameConstants.ORE_INFO[oreType] then
        warn("[RobotTaskManager] 未知的矿物类型:", oreType)
        return false
    end
    
    if quantity <= 0 then
        warn("[RobotTaskManager] 无效的数量:", quantity)
        return false
    end
    
    -- 创建任务
    local taskData = createMiningTask(player, robotType, oreType, quantity)
    
    -- 存储任务到PlayerDataManager
    if playerDataEvent then
        playerDataEvent:FireServer(player, "CREATE_TASK", taskData.taskId, taskData)
    end
    
    -- 从main world移除机器人（但保持Active状态）
    removeActiveRobotFromMainWorld(player, robotType)
    
    -- 创建工作机器人（如果玩家在Mine world）
    if player.Character and player.Character:GetAttribute("CurrentWorld") == "MineWorld" then
        local workingRobot = createWorkingRobotInMine(player, taskData)
        if workingRobot then
            if not playerWorkingRobots[player] then
                playerWorkingRobots[player] = {}
            end
            playerWorkingRobots[player][taskData.taskId] = workingRobot
            taskData.status = "WORKING"
            taskData.location = "MINE_WORLD"
        end
    end
    
    print("[RobotTaskManager] 任务创建成功:", taskData.taskId)
    return true
end

-- 处理玩家世界切换
local function onPlayerWorldChange(player, newWorld)
    print("[RobotTaskManager] 玩家世界切换:", player.Name, "->", newWorld)
    
    if newWorld == "MineWorld" then
        -- 玩家进入Mine world，激活所有ASSIGNED状态的任务
        local tasks = playerTasks[player]
        if tasks then
            for taskId, taskData in pairs(tasks) do
                if taskData.status == "ASSIGNED" and taskData.taskType == "MINING" then
                    local workingRobot = createWorkingRobotInMine(player, taskData)
                    if workingRobot then
                        if not playerWorkingRobots[player] then
                            playerWorkingRobots[player] = {}
                        end
                        playerWorkingRobots[player][taskId] = workingRobot
                        taskData.status = "WORKING"
                        taskData.location = "MINE_WORLD"
                        print("[RobotTaskManager] 激活任务:", taskId)
                    end
                end
            end
        end
    elseif newWorld == "MainWorld" then
        -- 玩家离开Mine world，暂停工作机器人
        local workingRobots = playerWorkingRobots[player]
        if workingRobots then
            for taskId, robot in pairs(workingRobots) do
                if robot and robot.Parent then
                    robot:Destroy()
                    print("[RobotTaskManager] 移除工作机器人:", robot.Name)
                end
                workingRobots[taskId] = nil
                
                -- 更新任务状态
                local taskData = playerTasks[player] and playerTasks[player][taskId]
                if taskData then
                    taskData.status = "ASSIGNED"
                    taskData.location = "MAIN_WORLD"
                end
            end
        end
    end
end

-- 寻找最近的目标矿物
local function findNearestOre(robot, oreType)
    local robotPos = robot.PrimaryPart and robot.PrimaryPart.Position or robot:FindFirstChild("HumanoidRootPart") and robot.HumanoidRootPart.Position
    if not robotPos then return nil end
    
    local mineWorld = robot.Parent
    local nearestOre = nil
    local minDistance = math.huge
    
    -- 搜索Mine world中的矿物
    local function searchInFolder(folder)
        for _, child in pairs(folder:GetChildren()) do
            if child:IsA("Model") and child.Name:find(oreType) then
                -- 查找模型中的Part
                for _, part in pairs(child:GetChildren()) do
                    if part:IsA("Part") and part.Name == oreType then
                        local distance = (part.Position - robotPos).Magnitude
                        if distance < minDistance then
                            nearestOre = part
                            minDistance = distance
                        end
                    end
                end
            elseif child:IsA("Part") and child.Name == oreType then
                local distance = (child.Position - robotPos).Magnitude
                if distance < minDistance then
                    nearestOre = child
                    minDistance = distance
                end
            elseif child:IsA("Folder") then
                searchInFolder(child)
            end
        end
    end
    
    -- 搜索PrivateMines文件夹
    local privateMines = workspace:FindFirstChild("PrivateMines")
    if privateMines then
        local playerMine = privateMines:FindFirstChild(robot:GetAttribute("Owner"))
        if playerMine then
            searchInFolder(playerMine)
        end
    end
    
    -- 也搜索MineWorld（如果存在）
    if mineWorld then
        searchInFolder(mineWorld)
    end
    
    return nearestOre, minDistance
end

-- 让机器人移动到目标位置
local function moveRobotToTarget(robot, targetPosition)
    local humanoid = robot:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid:MoveTo(targetPosition)
        return true
    end
    return false
end

-- 机器人挖矿行为
local function robotMining(robot, taskData)
    local oreType = taskData.oreType
    local robotPos = robot.PrimaryPart and robot.PrimaryPart.Position or robot:FindFirstChild("HumanoidRootPart") and robot.HumanoidRootPart.Position
    
    if not robotPos then return false end
    
    -- 寻找最近的目标矿物
    local targetOre, distance = findNearestOre(robot, oreType)
    
    if not targetOre or not targetOre.Parent then
        -- 没有找到目标矿物，等待重新生成或完成任务
        print("[RobotTaskManager] 机器人未找到目标矿物:", oreType)
        return false
    end
    
    -- 如果距离太远，移动到目标附近
    if distance > 8 then
        local targetPos = targetOre.Position + Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))
        moveRobotToTarget(robot, targetPos)
        return false -- 等待移动完成
    end
    
    -- 在挖矿范围内，执行挖矿
    if distance <= 8 then
        local currentTime = tick()
        local lastMinigTime = robotMiningTimes[robot] or 0
        
        -- 获取机器人挖矿间隔
        local baseType = getRobotBaseType(taskData.robotType)
        local robotStats = GameConstants.BotStats[baseType]
        local miningInterval = robotStats and robotStats.interval or 3.0
        
        -- 检查是否到了挖矿时间
        if currentTime - lastMinigTime >= miningInterval then
            -- 模拟挖矿：销毁矿物并增加进度
            local oreAmount = targetOre:FindFirstChild("OreAmount")
            local quantity = oreAmount and oreAmount.Value or 1
            
            -- 增加完成数量
            taskData.completed = taskData.completed + quantity
            robot:SetAttribute("CompletedQuantity", taskData.completed)
            
            -- 记录挖矿时间
            robotMiningTimes[robot] = currentTime
            
            -- 销毁矿物
            if targetOre.Parent then
                targetOre.Parent:Destroy()  -- 销毁整个模型
            end
            
            print("[RobotTaskManager] 机器人挖到矿物:", oreType, "x" .. quantity, "进度:", taskData.completed, "/", taskData.quantity)
            
            -- 给机器人主人添加矿物到库存
            local player = Players:FindFirstChild(robot:GetAttribute("Owner"))
            if player then
                -- 使用现有的GameLogic系统添加物品
                local GameLogic = require(game.ServerScriptService.ServerModules.GameLogicServer)
                if oreType == "Scrap" then
                    GameLogic.AddScrap(player, quantity)
                else
                    GameLogic.AddItem(player, oreType, quantity)
                end
            end
            
            return true
        else
            -- 等待挖矿冷却
            return false
        end
    end
    
    return false
end

-- 更新工作机器人（智能挖矿版本）
local function updateWorkingRobots()
    for player, workingRobots in pairs(playerWorkingRobots) do
        for taskId, robot in pairs(workingRobots) do
            if robot and robot.Parent then
                local taskData = playerTasks[player] and playerTasks[player][taskId]
                if taskData and taskData.status == "WORKING" then
                    
                    -- 检查任务是否完成
                    if taskData.completed >= taskData.quantity then
                        print("[RobotTaskManager] 任务完成:", taskId, "共挖掘", taskData.completed, "个", taskData.oreType)
                        taskData.status = "COMPLETED"
                        
                        -- 清理挖矿记录并移除工作机器人
                        robotMiningTimes[robot] = nil
                        robot:Destroy()
                        workingRobots[taskId] = nil
                        
                        -- TODO: 将机器人返回到库存中（可选）
                        
                        continue
                    end
                    
                    -- 执行智能挖矿
                    robotMining(robot, taskData)
                end
            end
        end
    end
end

-- 处理任务管理请求
miningTaskEvent.OnServerEvent:Connect(function(player, action, ...)
    print("[RobotTaskManager] 收到请求:", player.Name, action)
    
    if action == "ASSIGN" then
        local robotType, oreType, quantity = ...
        assignMiningTask(player, robotType, oreType, quantity)
    elseif action == "CANCEL" then
        local taskId = ...
        -- TODO: 取消任务
    elseif action == "GET_TASKS" then
        -- TODO: 返回玩家的所有任务
    end
end)

-- 玩家离开时清理
Players.PlayerRemoving:Connect(function(player)
    -- 清理工作机器人
    local workingRobots = playerWorkingRobots[player]
    if workingRobots then
        for taskId, robot in pairs(workingRobots) do
            if robot and robot.Parent then
                -- 清理挖矿时间记录
                robotMiningTimes[robot] = nil
                robot:Destroy()
            end
        end
        playerWorkingRobots[player] = nil
    end
    
    -- 清理任务数据
    playerTasks[player] = nil
    
    print("[RobotTaskManager] 清理玩家数据:", player.Name)
end)

-- 监听角色属性变化（世界切换）
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        -- 监听世界切换属性
        character.AttributeChanged:Connect(function(attributeName)
            if attributeName == "CurrentWorld" then
                local newWorld = character:GetAttribute("CurrentWorld")
                if newWorld then
                    onPlayerWorldChange(player, newWorld)
                end
            end
        end)
    end)
end)

-- 机器人挖矿时间跟踪
local robotMiningTimes = {} -- [机器人] = 上次挖矿时间

-- 工作机器人更新循环
local lastUpdate = 0
RunService.Heartbeat:Connect(function()
    local currentTime = tick()
    if currentTime - lastUpdate >= 0.5 then  -- 每0.5秒更新一次，让机器人移动更流畅
        updateWorkingRobots()
        lastUpdate = currentTime
    end
end)

print("[RobotTaskManager] 机器人任务管理系统已启动")