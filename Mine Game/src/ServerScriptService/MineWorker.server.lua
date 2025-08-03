--------------------------------------------------------------------
-- MineWorker.server.lua · 改进的机器人挖矿系统
-- 功能：
--   1) 管理矿区中的挖矿机器人
--   2) 智能寻找和挖掘矿石
--   3) 与任务管理系统配合
--   4) 处理挖矿完成后的返回
--------------------------------------------------------------------
local RS = game:GetService("ReplicatedStorage")
local Path = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local GameConstants = require(RS.SharedModules.GameConstants)
local ORE_INFO = GameConstants.ORE_INFO

-- 配置
local MAIN_PLACE_ID = 82341741981647 -- 主场景PlaceId
local MAX_MINING_DISTANCE = 50 -- 最大挖矿距离
local MINING_COOLDOWN = 2 -- 挖矿冷却时间

-- 活跃的机器人状态 [botModel] = {state, target, progress, etc.}
local activeBots = {}

-- RemoteEvents
local botReturnEvent = RS:FindFirstChild("BotReturnEvent")
if not botReturnEvent then
    botReturnEvent = Instance.new("RemoteEvent")
    botReturnEvent.Name = "BotReturnEvent"
    botReturnEvent.Parent = RS
end

--------------------------------------------------------------------
-- 工具函数
--------------------------------------------------------------------

-- 查找最近的指定矿石
local function findNearestOre(bot, oreName, maxDistance)
    -- 查找机器人所在的矿区
    local playerMine = bot.Parent
    if not playerMine then return nil end
    
    local oreFolder = playerMine:FindFirstChild("OreFolder")
    if not oreFolder then return nil end
    
    local botPos = bot.PrimaryPart and bot.PrimaryPart.Position
    if not botPos then return nil end
    
    local best, bestDist = nil, math.huge
    
    for _, ore in ipairs(oreFolder:GetChildren()) do
        if ore:IsA("Model") then
            -- 查找模型中的矿石部分
            local orePart = nil
            for _, part in ipairs(ore:GetDescendants()) do
                if part:IsA("BasePart") and part.Name == oreName then
                    orePart = part
                    break
                end
            end
            
            if orePart then
                local distance = (botPos - orePart.Position).Magnitude
                if distance < bestDist and distance <= (maxDistance or MAX_MINING_DISTANCE) then
                    best, bestDist = ore, distance
                end
            end
        elseif ore:IsA("BasePart") and ore.Name == oreName then
            local distance = (botPos - ore.Position).Magnitude
            if distance < bestDist and distance <= (maxDistance or MAX_MINING_DISTANCE) then
                best, bestDist = ore, distance
            end
        end
    end
    
    return best, bestDist
end

-- 初始化机器人状态
local function initBot(bot)
    if activeBots[bot] then return end
    
    local botData = {
        state = "idle", -- idle, moving, mining, returning
        target = nil,
        startTime = tick(),
        lastMining = 0,
        minedCount = bot:GetAttribute("CompletedQuantity") or 0,
        targetQuantity = bot:GetAttribute("TargetQuantity") or 10,
        targetOre = bot:GetAttribute("TargetOre") or "Stone",
        ownerId = bot:GetAttribute("Owner"),
        taskId = bot:GetAttribute("TaskId")
    }
    
    activeBots[bot] = botData
    print(("[MineWorker] 初始化机器人: %s, 目标: %s, 数量: %d"):format(
        bot.Name, botData.targetOre, botData.targetQuantity))
end

-- 机器人移动到目标
local function moveBotTo(bot, target)
    local botData = activeBots[bot]
    if not botData then return false end
    
    local humanoid = bot:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    
    botData.state = "moving"
    
    -- 使用PathfindingService进行寻路
    local pathService = Path:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        WaypointSpacing = 4
    })
    
    local success, path = pcall(function()
        pathService:ComputeAsync(bot.PrimaryPart.Position, target.Position)
        return pathService:GetWaypoints()
    end)
    
    if not success or pathService.Status ~= Enum.PathStatus.Success then
        print(("[MineWorker] 机器人 %s 寻路失败"):format(bot.Name))
        return false
    end
    
    -- 沿路径移动
    for i, waypoint in ipairs(path) do
        if botData.state ~= "moving" then break end
        
        humanoid:MoveTo(waypoint.Position)
        
        -- 等待移动完成或超时
        local moveFinished = false
        local connection
        connection = humanoid.MoveToFinished:Connect(function()
            moveFinished = true
            connection:Disconnect()
        end)
        
        -- 超时检查
        local timeout = tick() + 5
        while not moveFinished and tick() < timeout and botData.state == "moving" do
            RunService.Heartbeat:Wait()
        end
        
        if connection then connection:Disconnect() end
        
        if not moveFinished then
            print(("[MineWorker] 机器人 %s 移动超时"):format(bot.Name))
            return false
        end
    end
    
    return true
end

-- 机器人挖掘矿石
local function mineBotOre(bot, oreModel)
    local botData = activeBots[bot]
    if not botData then return false end
    
    -- 检查冷却时间
    if tick() - botData.lastMining < MINING_COOLDOWN then
        return false
    end
    
    botData.state = "mining"
    botData.lastMining = tick()
    
    -- 查找矿石部分
    local orePart = nil
    if oreModel:IsA("Model") then
        for _, part in ipairs(oreModel:GetDescendants()) do
            if part:IsA("BasePart") and part.Name == botData.targetOre then
                orePart = part
                break
            end
        end
    else
        orePart = oreModel
    end
    
    if not orePart then
        print(("[MineWorker] 机器人 %s 找不到矿石部分"):format(bot.Name))
        return false
    end
    
    -- 模拟挖掘时间
    local miningTime = ORE_INFO[botData.targetOre] and ORE_INFO[botData.targetOre].time or 1
    task.wait(miningTime)
    
    -- 销毁矿石
    oreModel:Destroy()
    
    -- 更新进度
    botData.minedCount = botData.minedCount + 1
    bot:SetAttribute("TaskLeft", botData.targetQuantity - botData.minedCount)
    
    print(("[MineWorker] 机器人 %s 挖掘了 %s, 进度: %d/%d"):format(
        bot.Name, botData.targetOre, botData.minedCount, botData.targetQuantity))
    
    return true
end

-- 机器人返回主城
local function returnBot(bot)
    local botData = activeBots[bot]
    if not botData then return end
    
    botData.state = "returning"
    
    -- 通知主城任务完成
    if botData.ownerId then
        local owner = Players:GetPlayerByUserId(botData.ownerId)
        if owner then
            botReturnEvent:FireClient(owner, bot.Name, {
                oreName = botData.targetOre,
                quantity = botData.minedCount
            })
        end
    end
    
    -- 传送回主城
    if botData.ownerId then
        local owner = Players:GetPlayerByUserId(botData.ownerId)
        if owner then
            TeleportService:Teleport(MAIN_PLACE_ID, owner)
        end
    end
    
    -- 清理机器人状态
    activeBots[bot] = nil
    
    print(("[MineWorker] 机器人 %s 返回主城，挖掘了 %d 个 %s"):format(
        bot.Name, botData.minedCount, botData.targetOre))
end

--------------------------------------------------------------------
-- 主循环：机器人AI系统
--------------------------------------------------------------------
RunService.Heartbeat:Connect(function()
    -- 扫描所有玩家矿区中的工作机器人
    local privateMines = workspace:FindFirstChild("PrivateMines")
    if not privateMines then return end
    
    for _, playerMine in ipairs(privateMines:GetChildren()) do
        for _, obj in ipairs(playerMine:GetChildren()) do
            if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and 
               obj:GetAttribute("Type") == "WorkingRobot" and obj:GetAttribute("Status") == "WORKING" then
                -- 初始化新发现的机器人
                if not activeBots[obj] then
                    initBot(obj)
                end
            
            local botData = activeBots[obj]
            if not botData then continue end
            
            -- 检查任务是否完成
            if botData.minedCount >= botData.targetQuantity then
                returnBot(obj)
                continue
            end
            
            -- 根据状态执行相应行为
            if botData.state == "idle" then
                local nearestOre = findNearestOre(obj, botData.targetOre)
                if nearestOre then
                    botData.target = nearestOre
                    task.spawn(function()
                        if moveBotTo(obj, nearestOre) then
                            mineBotOre(obj, nearestOre)
                        end
                        if activeBots[obj] then
                            activeBots[obj].state = "idle"
                            activeBots[obj].target = nil
                        end
                    end)
                else
                    -- 找不到矿石，返回主城
                    print(("[MineWorker] 机器人 %s 找不到 %s 矿石，返回主城"):format(obj.Name, botData.targetOre))
                    returnBot(obj)
                end
            end
        end
    end
    
    -- 清理无效的机器人引用
    for bot, _ in pairs(activeBots) do
        if not bot.Parent then
            activeBots[bot] = nil
        end
    end
end)

print("[MineWorker] 改进的机器人挖矿系统已启动")
