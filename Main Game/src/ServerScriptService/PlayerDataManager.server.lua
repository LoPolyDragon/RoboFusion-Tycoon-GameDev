--------------------------------------------------------------------
-- PlayerDataManager.server.lua · 玩家数据管理系统
-- 功能：
--   1) 存储玩家Active机器人状态
--   2) 管理机器人任务数据
--   3) 记录建筑位置和朝向
--   4) 数据持久化和同步
--------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

-- DataStore配置
local playerDataStore = DataStoreService:GetDataStore("PlayerGameData_v1")

-- 内存中的玩家数据
local playerData = {} -- [玩家] = 数据结构

-- 默认玩家数据结构
local function createDefaultPlayerData()
    return {
        -- Active机器人数据
        activeRobots = {
            -- [1-5] = {robotType = "Dig_UncommonBot", status = "FOLLOWING/WORKING", taskId = nil}
        },
        
        -- 机器人任务数据
        robotTasks = {
            -- [taskId] = {
            --     robotType = "Dig_UncommonBot",
            --     taskType = "MINING",
            --     oreType = "IronOre", 
            --     quantity = 10,
            --     completed = 0,
            --     startTime = tick(),
            --     estimatedEndTime = tick() + 300,
            --     status = "ASSIGNED/WORKING/COMPLETED"
            -- }
        },
        
        -- 建筑数据
        buildings = {
            -- [buildingId] = {
            --     buildingType = "Crusher",
            --     position = Vector3.new(0, 0, 0),
            --     rotation = Vector3.new(0, 0, 0), -- Euler angles
            --     level = 1,
            --     placedTime = tick()
            -- }
        },
        
        -- 数据版本和时间戳
        dataVersion = 1,
        lastSaved = tick(),
        lastLogin = tick()
    }
end

-- 获取玩家数据
local function getPlayerData(player)
    if not playerData[player] then
        -- 尝试从DataStore加载
        local success, data = pcall(function()
            return playerDataStore:GetAsync(player.UserId)
        end)
        
        if success and data then
            playerData[player] = data
            print("[PlayerDataManager] 为玩家加载数据:", player.Name)
        else
            playerData[player] = createDefaultPlayerData()
            print("[PlayerDataManager] 为玩家创建新数据:", player.Name)
        end
        
        playerData[player].lastLogin = tick()
    end
    
    return playerData[player]
end

-- 保存玩家数据
local function savePlayerData(player)
    local data = playerData[player]
    if not data then return false end
    
    data.lastSaved = tick()
    
    local success, err = pcall(function()
        playerDataStore:SetAsync(player.UserId, data)
    end)
    
    if success then
        print("[PlayerDataManager] 玩家数据保存成功:", player.Name)
        return true
    else
        warn("[PlayerDataManager] 玩家数据保存失败:", player.Name, err)
        return false
    end
end

--------------------------------------------------------------------
-- Active机器人管理
--------------------------------------------------------------------

-- 设置Active机器人
local function setActiveRobot(player, slotIndex, robotType)
    local data = getPlayerData(player)
    
    data.activeRobots[slotIndex] = {
        robotType = robotType,
        status = "FOLLOWING",
        taskId = nil,
        setTime = tick()
    }
    
    print("[PlayerDataManager] 设置Active机器人:", player.Name, "槽位", slotIndex, "机器人", robotType)
    return true
end

-- 移除Active机器人
local function removeActiveRobot(player, slotIndex)
    local data = getPlayerData(player)
    
    if data.activeRobots[slotIndex] then
        local robotType = data.activeRobots[slotIndex].robotType
        data.activeRobots[slotIndex] = nil
        print("[PlayerDataManager] 移除Active机器人:", player.Name, "槽位", slotIndex, "机器人", robotType)
        return true
    end
    
    return false
end

-- 获取Active机器人信息
local function getActiveRobots(player)
    local data = getPlayerData(player)
    return data.activeRobots or {}
end

-- 设置机器人工作状态
local function setRobotWorkingStatus(player, slotIndex, status, taskId)
    local data = getPlayerData(player)
    
    if data.activeRobots[slotIndex] then
        data.activeRobots[slotIndex].status = status
        data.activeRobots[slotIndex].taskId = taskId
        print("[PlayerDataManager] 更新机器人状态:", player.Name, "槽位", slotIndex, "状态", status)
        return true
    end
    
    return false
end

--------------------------------------------------------------------
-- 机器人任务管理
--------------------------------------------------------------------

-- 创建机器人任务
local function createRobotTask(player, taskId, taskData)
    local data = getPlayerData(player)
    
    data.robotTasks[taskId] = {
        robotType = taskData.robotType,
        taskType = taskData.taskType,
        oreType = taskData.oreType,
        quantity = taskData.quantity,
        completed = taskData.completed or 0,
        startTime = taskData.startTime or tick(),
        estimatedEndTime = taskData.estimatedEndTime,
        status = taskData.status or "ASSIGNED",
        location = taskData.location or "MAIN_WORLD"
    }
    
    print("[PlayerDataManager] 创建机器人任务:", player.Name, taskId, taskData.robotType, "->", taskData.oreType, "x" .. taskData.quantity)
    return true
end

-- 更新任务进度
local function updateTaskProgress(player, taskId, completed)
    local data = getPlayerData(player)
    
    if data.robotTasks[taskId] then
        data.robotTasks[taskId].completed = completed
        
        -- 检查任务是否完成
        if completed >= data.robotTasks[taskId].quantity then
            data.robotTasks[taskId].status = "COMPLETED"
            print("[PlayerDataManager] 任务完成:", player.Name, taskId)
        end
        
        return true
    end
    
    return false
end

-- 获取玩家所有任务
local function getPlayerTasks(player)
    local data = getPlayerData(player)
    return data.robotTasks or {}
end

-- 移除完成的任务
local function removeCompletedTask(player, taskId)
    local data = getPlayerData(player)
    
    if data.robotTasks[taskId] then
        data.robotTasks[taskId] = nil
        print("[PlayerDataManager] 移除完成任务:", player.Name, taskId)
        return true
    end
    
    return false
end

--------------------------------------------------------------------
-- 建筑管理
--------------------------------------------------------------------

-- 添加建筑
local function addBuilding(player, buildingId, buildingData)
    local data = getPlayerData(player)
    
    data.buildings[buildingId] = {
        buildingType = buildingData.buildingType,
        position = {
            x = buildingData.position.X,
            y = buildingData.position.Y,
            z = buildingData.position.Z
        },
        rotation = {
            x = buildingData.rotation.X or 0,
            y = buildingData.rotation.Y or 0,
            z = buildingData.rotation.Z or 0
        },
        level = buildingData.level or 1,
        placedTime = tick()
    }
    
    print("[PlayerDataManager] 添加建筑:", player.Name, buildingId, buildingData.buildingType, "位置:", buildingData.position)
    return true
end

-- 移除建筑
local function removeBuilding(player, buildingId)
    local data = getPlayerData(player)
    
    if data.buildings[buildingId] then
        local buildingType = data.buildings[buildingId].buildingType
        data.buildings[buildingId] = nil
        print("[PlayerDataManager] 移除建筑:", player.Name, buildingId, buildingType)
        return true
    end
    
    return false
end

-- 获取玩家所有建筑
local function getPlayerBuildings(player)
    local data = getPlayerData(player)
    return data.buildings or {}
end

-- 更新建筑属性
local function updateBuilding(player, buildingId, property, value)
    local data = getPlayerData(player)
    
    if data.buildings[buildingId] then
        data.buildings[buildingId][property] = value
        print("[PlayerDataManager] 更新建筑属性:", player.Name, buildingId, property, "->", value)
        return true
    end
    
    return false
end

--------------------------------------------------------------------
-- RemoteFunction/Event接口
--------------------------------------------------------------------

-- 创建RemoteEvents和Functions
local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteFolder then
    remoteFolder = Instance.new("Folder")
    remoteFolder.Name = "RemoteEvents"
    remoteFolder.Parent = ReplicatedStorage
end

local playerDataFunction = Instance.new("RemoteFunction")
playerDataFunction.Name = "PlayerDataFunction"
playerDataFunction.Parent = remoteFolder

local playerDataEvent = Instance.new("RemoteEvent")
playerDataEvent.Name = "PlayerDataEvent"
playerDataEvent.Parent = remoteFolder

-- 处理数据请求
playerDataFunction.OnServerInvoke = function(player, action, ...)
    local args = {...}
    
    if action == "GET_ACTIVE_ROBOTS" then
        return getActiveRobots(player)
        
    elseif action == "GET_TASKS" then
        return getPlayerTasks(player)
        
    elseif action == "GET_BUILDINGS" then
        return getPlayerBuildings(player)
        
    elseif action == "GET_ALL_DATA" then
        return getPlayerData(player)
        
    else
        warn("[PlayerDataManager] 未知的数据请求:", action)
        return nil
    end
end

-- 处理数据更新事件
playerDataEvent.OnServerEvent:Connect(function(player, action, ...)
    local args = {...}
    
    if action == "SET_ACTIVE_ROBOT" then
        local slotIndex, robotType = args[1], args[2]
        setActiveRobot(player, slotIndex, robotType)
        
    elseif action == "REMOVE_ACTIVE_ROBOT" then
        local slotIndex = args[1]
        removeActiveRobot(player, slotIndex)
        
    elseif action == "UPDATE_ROBOT_STATUS" then
        local slotIndex, status, taskId = args[1], args[2], args[3]
        setRobotWorkingStatus(player, slotIndex, status, taskId)
        
    elseif action == "CREATE_TASK" then
        local taskId, taskData = args[1], args[2]
        createRobotTask(player, taskId, taskData)
        
    elseif action == "UPDATE_TASK_PROGRESS" then
        local taskId, completed = args[1], args[2]
        updateTaskProgress(player, taskId, completed)
        
    elseif action == "ADD_BUILDING" then
        local buildingId, buildingData = args[1], args[2]
        addBuilding(player, buildingId, buildingData)
        
    elseif action == "REMOVE_BUILDING" then
        local buildingId = args[1]
        removeBuilding(player, buildingId)
        
    elseif action == "SAVE_DATA" then
        savePlayerData(player)
        
    else
        warn("[PlayerDataManager] 未知的数据更新:", action)
    end
end)

--------------------------------------------------------------------
-- 玩家连接/断开处理
--------------------------------------------------------------------

-- 玩家加入时初始化数据
Players.PlayerAdded:Connect(function(player)
    print("[PlayerDataManager] 玩家加入:", player.Name)
    getPlayerData(player) -- 初始化数据
end)

-- 玩家离开时保存数据
Players.PlayerRemoving:Connect(function(player)
    print("[PlayerDataManager] 玩家离开:", player.Name, "保存数据...")
    
    if playerData[player] then
        savePlayerData(player)
        playerData[player] = nil
    end
end)

-- 定期自动保存（每5分钟）
task.spawn(function()
    while true do
        task.wait(300) -- 5分钟
        
        for player, data in pairs(playerData) do
            if player.Parent then -- 确保玩家还在游戏中
                savePlayerData(player)
            end
        end
    end
end)

-- 游戏关闭时保存所有数据
game:BindToClose(function()
    print("[PlayerDataManager] 游戏关闭，保存所有玩家数据...")
    
    for player, data in pairs(playerData) do
        savePlayerData(player)
    end
    
    -- 等待保存完成
    task.wait(2)
end)

print("[PlayerDataManager] 玩家数据管理系统已启动")