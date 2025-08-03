--------------------------------------------------------------------
-- BotAI · 增强机器人AI系统
-- 功能：
--   1) 智能路径规划和跟随
--   2) 任务执行状态机
--   3) 能量管理和自动充能
--   4) 建筑交互和自动化
--------------------------------------------------------------------
local PathService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConstants = require(ReplicatedStorage.SharedModules.GameConstants.main)

local BotAI = {}

-- 机器人状态枚举
local BotStates = {
    FOLLOW = "Follow",           -- 跟随主人
    IDLE = "Idle",              -- 闲置等待
    WORKING = "Working",         -- 执行任务中
    MINING = "Mining",           -- 挖矿中
    BUILDING = "Building",       -- 建造中
    TRANSPORTING = "Transporting", -- 运输中
    CHARGING = "Charging",       -- 充能中
    RETURNING = "Returning",     -- 返回中
    ERROR = "Error"              -- 错误状态
}

-- 创建机器人AI实例
function BotAI.init(bot, owner)
    ----------------------------------------------------------------
    -- 基础属性初始化
    ----------------------------------------------------------------
    bot:SetAttribute("Owner", owner.UserId)
    bot:SetAttribute("State", BotStates.FOLLOW)
    bot:SetAttribute("Energy", 100) -- 能量值 0-100
    bot:SetAttribute("MaxEnergy", 100)
    bot:SetAttribute("WorkingTask", nil) -- 当前任务ID
    bot:SetAttribute("LastActivity", tick())
    
    ----------------------------------------------------------------
    -- 组件初始化
    ----------------------------------------------------------------
    local humanoid = bot:WaitForChild("Humanoid")
    local rootPart = bot.PrimaryPart or bot:WaitForChild("HumanoidRootPart")
    
    -- 内部状态
    local aiState = {
        lastPath = 0,
        pathUpdateInterval = 0.5,
        stuckTimer = 0,
        stuckThreshold = 3,
        lastPosition = rootPart.Position,
        currentPath = nil,
        waypointIndex = 1,
        taskTarget = nil,
        energyDrainRate = 1, -- 每秒消耗的能量
        energyDrainTimer = 0
    }
    
    ----------------------------------------------------------------
    -- 路径规划系统
    ----------------------------------------------------------------
    local function computePath(startPos, endPos)
        local path = PathService:CreatePath({
            AgentRadius = 2,
            AgentCanJump = true,
            AgentCanClimb = false,
            WaypointSpacing = 4
        })
        
        local success, error = pcall(function()
            path:ComputeAsync(startPos, endPos)
        end)
        
        if success and path.Status == Enum.PathStatus.Success then
            return path:GetWaypoints()
        end
        return nil
    end
    
    -- 移动到目标位置
    local function moveToTarget(targetPos, tolerance)
        tolerance = tolerance or 4
        local distance = (rootPart.Position - targetPos).Magnitude
        
        if distance <= tolerance then
            return true -- 已到达
        end
        
        -- 检查是否需要重新规划路径
        if tick() - aiState.lastPath > aiState.pathUpdateInterval then
            aiState.lastPath = tick()
            local waypoints = computePath(rootPart.Position, targetPos)
            
            if waypoints then
                aiState.currentPath = waypoints
                aiState.waypointIndex = 1
            end
        end
        
        -- 执行路径跟随
        if aiState.currentPath and aiState.waypointIndex <= #aiState.currentPath then
            local currentWaypoint = aiState.currentPath[aiState.waypointIndex]
            humanoid:MoveTo(currentWaypoint.Position)
            
            -- 检查是否到达当前路径点
            if (rootPart.Position - currentWaypoint.Position).Magnitude < 3 then
                aiState.waypointIndex = aiState.waypointIndex + 1
            end
        else
            -- 直接移动（后备方案）
            humanoid:MoveTo(targetPos)
        end
        
        return false
    end
    
    -- 检测机器人是否卡住
    local function checkIfStuck()
        local currentPos = rootPart.Position
        local distanceMoved = (currentPos - aiState.lastPosition).Magnitude
        
        if distanceMoved < 0.5 then
            aiState.stuckTimer = aiState.stuckTimer + 1
        else
            aiState.stuckTimer = 0
        end
        
        aiState.lastPosition = currentPos
        
        -- 如果卡住太久，尝试随机移动
        if aiState.stuckTimer > aiState.stuckThreshold then
            local randomOffset = Vector3.new(
                math.random(-10, 10),
                0,
                math.random(-10, 10)
            )
            humanoid:MoveTo(currentPos + randomOffset)
            aiState.stuckTimer = 0
        end
    end
    
    ----------------------------------------------------------------
    -- 能量管理系统
    ----------------------------------------------------------------
    local function updateEnergy(deltaTime)
        aiState.energyDrainTimer = aiState.energyDrainTimer + deltaTime
        
        -- 每秒消耗能量
        if aiState.energyDrainTimer >= 1 then
            aiState.energyDrainTimer = 0
            local currentEnergy = bot:GetAttribute("Energy")
            local state = bot:GetAttribute("State")
            
            -- 根据状态调整能量消耗
            local drainRate = aiState.energyDrainRate
            if state == BotStates.WORKING or state == BotStates.MINING then
                drainRate = drainRate * 2 -- 工作时消耗更多能量
            elseif state == BotStates.IDLE then
                drainRate = drainRate * 0.1 -- 闲置时消耗很少
            end
            
            local newEnergy = math.max(0, currentEnergy - drainRate)
            bot:SetAttribute("Energy", newEnergy)
            
            -- 能量不足时进入充能状态
            if newEnergy < 20 and state ~= BotStates.CHARGING then
                bot:SetAttribute("State", BotStates.CHARGING)
                print("[BotAI] 机器人能量不足，进入充能状态")
            end
        end
    end
    
    -- 寻找最近的能量站
    local function findNearestEnergyStation()
        local nearestStation = nil
        local nearestDistance = math.huge
        
        -- 在工作区中寻找能量站
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:GetAttribute("BuildingType") == "EnergyStation" and 
               obj:GetAttribute("Owner") == owner.UserId then
                local distance = (rootPart.Position - obj.Position).Magnitude
                if distance < nearestDistance then
                    nearestDistance = distance
                    nearestStation = obj
                end
            end
        end
        
        return nearestStation, nearestDistance
    end
    
    ----------------------------------------------------------------
    -- 状态机处理器
    ----------------------------------------------------------------
    local stateHandlers = {
        [BotStates.FOLLOW] = function()
            if not owner.Character or not owner.Character.PrimaryPart then
                return
            end
            
            local targetPos = owner.Character.PrimaryPart.Position + Vector3.new(3, 0, 3)
            moveToTarget(targetPos, 6)
        end,
        
        [BotStates.IDLE] = function()
            -- 闲置状态，等待指令
            -- 可以添加一些闲置动画或巡逻行为
        end,
        
        [BotStates.WORKING] = function()
            local taskId = bot:GetAttribute("WorkingTask")
            if not taskId then
                bot:SetAttribute("State", BotStates.FOLLOW)
                return
            end
            
            -- 执行任务逻辑
            -- 这里由具体的任务管理器处理
        end,
        
        [BotStates.MINING] = function()
            -- 挖矿状态由MineWorker处理
        end,
        
        [BotStates.BUILDING] = function()
            -- 建造状态处理
            if aiState.taskTarget then
                local reached = moveToTarget(aiState.taskTarget, 5)
                if reached then
                    -- 执行建造动作
                    print("[BotAI] 开始建造")
                end
            end
        end,
        
        [BotStates.TRANSPORTING] = function()
            -- 运输状态处理
            if aiState.taskTarget then
                moveToTarget(aiState.taskTarget, 3)
            end
        end,
        
        [BotStates.CHARGING] = function()
            local energyStation, distance = findNearestEnergyStation()
            
            if energyStation then
                local reached = moveToTarget(energyStation.Position, 8)
                if reached then
                    -- 在能量站范围内，开始充能
                    local currentEnergy = bot:GetAttribute("Energy")
                    local maxEnergy = bot:GetAttribute("MaxEnergy")
                    
                    if currentEnergy < maxEnergy then
                        bot:SetAttribute("Energy", math.min(maxEnergy, currentEnergy + 5))
                    else
                        -- 充能完成，返回跟随状态
                        bot:SetAttribute("State", BotStates.FOLLOW)
                        print("[BotAI] 充能完成，返回跟随状态")
                    end
                end
            else
                -- 没有能量站，回到主人身边等待
                bot:SetAttribute("State", BotStates.FOLLOW)
                print("[BotAI] 找不到能量站，返回跟随状态")
            end
        end,
        
        [BotStates.RETURNING] = function()
            if owner.Character and owner.Character.PrimaryPart then
                local reached = moveToTarget(owner.Character.PrimaryPart.Position, 5)
                if reached then
                    bot:SetAttribute("State", BotStates.FOLLOW)
                end
            end
        end,
        
        [BotStates.ERROR] = function()
            -- 错误状态处理，尝试恢复
            wait(1)
            bot:SetAttribute("State", BotStates.FOLLOW)
        end
    }
    
    ----------------------------------------------------------------
    -- 主更新循环
    ----------------------------------------------------------------
    local lastUpdate = tick()
    RunService.Heartbeat:Connect(function()
        if not bot.Parent then return end -- 机器人已被销毁
        
        local currentTime = tick()
        local deltaTime = currentTime - lastUpdate
        lastUpdate = currentTime
        
        -- 更新能量
        updateEnergy(deltaTime)
        
        -- 检测卡住
        checkIfStuck()
        
        -- 执行状态处理
        local state = bot:GetAttribute("State")
        local handler = stateHandlers[state]
        if handler then
            pcall(handler) -- 使用pcall防止错误导致AI停止
        end
        
        -- 更新活动时间
        bot:SetAttribute("LastActivity", currentTime)
    end)
    
    ----------------------------------------------------------------
    -- 对外接口
    ----------------------------------------------------------------
    bot.SetTask = function(taskId, taskType, target)
        bot:SetAttribute("WorkingTask", taskId)
        bot:SetAttribute("State", BotStates.WORKING)
        aiState.taskTarget = target
        print("[BotAI] 机器人接受任务:", taskId, taskType)
    end
    
    bot.CancelTask = function()
        bot:SetAttribute("WorkingTask", nil)
        bot:SetAttribute("State", BotStates.FOLLOW)
        aiState.taskTarget = nil
        print("[BotAI] 任务已取消")
    end
    
    bot.ReturnToOwner = function()
        bot:SetAttribute("State", BotStates.RETURNING)
    end
    
    print("[BotAI] 机器人AI系统已初始化:", bot.Name)
end

-- 获取机器人状态信息
function BotAI.getStatus(bot)
    return {
        state = bot:GetAttribute("State"),
        energy = bot:GetAttribute("Energy"),
        maxEnergy = bot:GetAttribute("MaxEnergy"),
        workingTask = bot:GetAttribute("WorkingTask"),
        lastActivity = bot:GetAttribute("LastActivity")
    }
end

return BotAI
