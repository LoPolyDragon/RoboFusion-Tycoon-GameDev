--------------------------------------------------------------------
-- RobotInventoryServer.server.lua · 机器人库存管理服务器端
-- 功能：处理Active机器人的生成、跟随和移除
--------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

-- 获取PlayerDataManager的RemoteEvent
local playerDataEvent = nil
task.spawn(function()
    local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
    playerDataEvent = remoteFolder:WaitForChild("PlayerDataEvent", 10)
    if not playerDataEvent then
        warn("[RobotInventoryServer] PlayerDataEvent不可用，机器人状态将不被持久化")
    end
end)

-- 创建RemoteEvents
local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteFolder then
    remoteFolder = Instance.new("Folder")
    remoteFolder.Name = "RemoteEvents"
    remoteFolder.Parent = ReplicatedStorage
end

local setActiveRobotEvent = Instance.new("RemoteEvent")
setActiveRobotEvent.Name = "SetActiveRobotEvent"
setActiveRobotEvent.Parent = remoteFolder

-- 创建RemoteFunction用于任务系统查询和操作Active机器人
local manageActiveRobotFunction = Instance.new("RemoteFunction")
manageActiveRobotFunction.Name = "ManageActiveRobotFunction"
manageActiveRobotFunction.Parent = remoteFolder

-- 存储每个玩家的Active机器人
local playerActiveRobots = {} -- [玩家] = {robotModel1, robotModel2, ...}

-- 机器人类型映射到模板名称
local ROBOT_TEMPLATE_MAPPING = {
    ["Dig_UncommonBot"] = "UncommonBot",
    ["Dig_RareBot"] = "RareBot", 
    ["Dig_EpicBot"] = "EpicBot",
    ["Dig_SecretBot"] = "SecretBot",
    ["Dig_EcoBot"] = "EcoBot",
    ["Build_UncommonBot"] = "UncommonBot",
    ["Build_RareBot"] = "RareBot",
    ["Build_EpicBot"] = "EpicBot", 
    ["Build_SecretBot"] = "SecretBot",
    ["Build_EcoBot"] = "EcoBot"
}

-- 获取机器人模板
local function getRobotTemplate(robotType)
    local templateName = ROBOT_TEMPLATE_MAPPING[robotType]
    if not templateName then
        warn("[RobotInventoryServer] 未知的机器人类型:", robotType)
        return nil
    end
    
    local robotTemplates = ServerStorage:FindFirstChild("RobotTemplates")
    if not robotTemplates then
        warn("[RobotInventoryServer] ServerStorage/RobotTemplates 不存在")
        return nil
    end
    
    local template = robotTemplates:FindFirstChild(templateName)
    if not template then
        warn("[RobotInventoryServer] 找不到机器人模板:", templateName)
        return nil
    end
    
    return template
end

-- 生成Active机器人
local function spawnActiveRobot(player, robotType, slotIndex)
    print("[RobotInventoryServer] 为玩家生成Active机器人:", player.Name, robotType, "槽位:", slotIndex)
    
    local template = getRobotTemplate(robotType)
    if not template then
        return nil
    end
    
    -- 克隆机器人模板
    local robot = template:Clone()
    robot.Name = robotType .. "_Active_" .. slotIndex
    
    -- 设置机器人属性
    robot:SetAttribute("Type", "Robot")
    robot:SetAttribute("RobotType", robotType)
    robot:SetAttribute("Owner", player.Name)
    robot:SetAttribute("Active", true)
    robot:SetAttribute("SlotIndex", slotIndex)
    robot:SetAttribute("Energy", 60)
    robot:SetAttribute("MaxEnergy", 60)
    
    -- 设置初始位置（玩家附近）
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local playerPos = player.Character.HumanoidRootPart.Position
        local spawnPos = playerPos + Vector3.new(math.random(-5, 5), 0, math.random(-5, 5))
        
        if robot.PrimaryPart then
            robot:SetPrimaryPartCFrame(CFrame.new(spawnPos))
        elseif robot:FindFirstChild("HumanoidRootPart") then
            robot.HumanoidRootPart.Position = spawnPos
        end
    end
    
    robot.Parent = workspace
    
    -- 添加到玩家的Active机器人列表
    if not playerActiveRobots[player] then
        playerActiveRobots[player] = {}
    end
    playerActiveRobots[player][slotIndex] = robot
    
    -- 同步到PlayerDataManager
    if playerDataEvent then
        playerDataEvent:FireServer(player, "SET_ACTIVE_ROBOT", slotIndex, robotType)
    end
    
    print("[RobotInventoryServer] Active机器人生成成功:", robot.Name)
    return robot
end

-- 移除Active机器人
local function removeActiveRobot(player, slotIndex)
    print("[RobotInventoryServer] 移除玩家Active机器人:", player.Name, "槽位:", slotIndex)
    
    if not playerActiveRobots[player] then
        return
    end
    
    local robot = playerActiveRobots[player][slotIndex]
    if robot and robot.Parent then
        robot:Destroy()
        print("[RobotInventoryServer] Active机器人已移除:", robot.Name)
    end
    
    playerActiveRobots[player][slotIndex] = nil
    
    -- 同步到PlayerDataManager
    if playerDataEvent then
        playerDataEvent:FireServer(player, "REMOVE_ACTIVE_ROBOT", slotIndex)
    end
end

-- 处理Active机器人设置请求
setActiveRobotEvent.OnServerEvent:Connect(function(player, action, robotType, slotIndex)
    print("[RobotInventoryServer] 收到请求:", player.Name, action, robotType, slotIndex)
    
    if action == "ACTIVATE" then
        -- 激活机器人
        spawnActiveRobot(player, robotType, slotIndex)
    elseif action == "DEACTIVATE" then
        -- 停用机器人
        removeActiveRobot(player, slotIndex)
    end
end)

-- 处理Active机器人管理请求（供其他服务器脚本使用）
manageActiveRobotFunction.OnServerInvoke = function(player, action, robotType, slotIndex)
    print("[RobotInventoryServer] 收到管理请求:", player.Name, action, robotType, slotIndex)
    
    if action == "FIND_SLOT" then
        -- 查找指定机器人类型的Active槽位
        if not playerActiveRobots[player] then
            return nil
        end
        
        for slot, robot in pairs(playerActiveRobots[player]) do
            if robot and robot:GetAttribute("RobotType") == robotType then
                return slot
            end
        end
        return nil
        
    elseif action == "REMOVE_BY_TYPE" then
        -- 根据机器人类型移除Active机器人
        if not playerActiveRobots[player] then
            return false
        end
        
        for slot, robot in pairs(playerActiveRobots[player]) do
            if robot and robot:GetAttribute("RobotType") == robotType then
                print("[RobotInventoryServer] 移除Active机器人:", robot.Name, "槽位:", slot)
                robot:Destroy()
                playerActiveRobots[player][slot] = nil
                return true
            end
        end
        return false
        
    elseif action == "GET_ACTIVE_ROBOTS" then
        -- 获取所有Active机器人信息
        local activeInfo = {}
        if playerActiveRobots[player] then
            for slot, robot in pairs(playerActiveRobots[player]) do
                if robot and robot.Parent then
                    activeInfo[slot] = robot:GetAttribute("RobotType")
                end
            end
        end
        return activeInfo
    end
    
    return nil
end

-- 机器人跟随逻辑 (跟在后面，不是围成圈)
local function updateRobotFollowing()
    for player, robots in pairs(playerActiveRobots) do
        if player.Parent and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local playerPos = player.Character.HumanoidRootPart.Position
            local playerLookDirection = player.Character.HumanoidRootPart.CFrame.LookVector
            
            -- 计算玩家后方的基准位置
            local behindPlayer = playerPos - playerLookDirection * 6
            
            for slotIndex, robot in pairs(robots) do
                if robot and robot.Parent and robot:FindFirstChild("Humanoid") then
                    -- 计算每个机器人的跟随位置（排成一列）
                    local offsetDistance = (slotIndex - 1) * 3 -- 每个机器人间隔3格
                    local sideOffset = ((slotIndex - 1) % 2 == 0) and -1.5 or 1.5 -- 左右错开
                    
                    -- 计算目标位置：在玩家后方排成之字形
                    local targetPos = behindPlayer - playerLookDirection * offsetDistance + 
                                     (player.Character.HumanoidRootPart.CFrame.RightVector * sideOffset)
                    
                    -- 让机器人走向目标位置
                    if robot:FindFirstChild("Humanoid") then
                        robot.Humanoid:MoveTo(targetPos)
                    end
                end
            end
        end
    end
end

-- 开始跟随更新循环
RunService.Heartbeat:Connect(updateRobotFollowing)

-- 玩家离开时清理
Players.PlayerRemoving:Connect(function(player)
    if playerActiveRobots[player] then
        for slotIndex, robot in pairs(playerActiveRobots[player]) do
            if robot and robot.Parent then
                robot:Destroy()
            end
        end
        playerActiveRobots[player] = nil
    end
    print("[RobotInventoryServer] 清理玩家机器人:", player.Name)
end)

print("[RobotInventoryServer] 机器人库存管理服务器已启动")