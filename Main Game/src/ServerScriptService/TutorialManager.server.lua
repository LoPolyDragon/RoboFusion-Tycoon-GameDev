--------------------------------------------------------------------
-- TutorialManager.server.lua · 新手教程管理系统
-- 功能：
--   1) 管理玩家教程进度
--   2) 验证教程步骤完成
--   3) 触发下一步教程
--   4) 处理教程奖励
--   5) 与现有系统集成
--------------------------------------------------------------------

print("[TutorialManager] 开始加载教程管理系统...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

-- 获取现有的远程通信文件夹
local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local rfFolder = ReplicatedStorage:WaitForChild("RemoteFunctions")

-- 创建教程专用的远程通信
local tutorialEvent = Instance.new("RemoteEvent")
tutorialEvent.Name = "TutorialEvent"
tutorialEvent.Parent = remoteFolder
print("[TutorialManager] TutorialEvent 已创建")

local tutorialFunction = Instance.new("RemoteFunction")
tutorialFunction.Name = "TutorialFunction"
tutorialFunction.Parent = rfFolder
print("[TutorialManager] TutorialFunction 已创建")

-- 获取现有的玩家数据系统
local getDataRF = rfFolder:WaitForChild("GetPlayerDataFunction")

-- 加载游戏常量
local GameConstants = require(ReplicatedStorage.SharedModules.GameConstants.main)

-- 教程步骤配置
local TUTORIAL_STEPS = {
    [1] = {
        id = "LANDING_POD",
        name = "降落舱着陆",
        description = "观看降落舱着陆序列",
        type = "CUTSCENE",
        duration = 10,
        requirements = {},
        rewards = {},
        nextStep = 2
    },
    [2] = {
        id = "OPEN_SHOP",
        name = "打开建筑商店",
        description = "点击右下角的Sho按钮打开建筑商店",
        type = "UI_INTERACTION",
        target = "BuildingShopButton",
        requirements = {},
        rewards = {},
        nextStep = 3
    },
    [3] = {
        id = "PLACE_CRUSHER",
        name = "放置粉碎机",
        description = "从商店中选择并放置Crusher Lv1",
        type = "BUILDING_PLACEMENT",
        target = "Crusher",
        requirements = {},
        rewards = { Scrap = 0 }, -- 教程期间免费
        nextStep = 4
    },
    [4] = {
        id = "COLLECT_SCRAP",
        name = "收集废料",
        description = "使用粉碎机收集150个Scrap",
        type = "RESOURCE_COLLECTION",
        target = "Scrap",
        targetAmount = 150,
        requirements = { Scrap = 150 },
        rewards = {},
        nextStep = 5
    },
    [5] = {
        id = "OPEN_GENERATOR",
        name = "打开生成器",
        description = "点击Generator并生成Rusty Shell",
        type = "MACHINE_INTERACTION",
        target = "Generator",
        requirements = { Scrap = 150 },
        rewards = { RustyShell = 1 },
        nextStep = 6
    },
    [6] = {
        id = "USE_ASSEMBLER",
        name = "使用组装器",
        description = "在Assembler中将Rusty Shell组装成Mining Bot",
        type = "MACHINE_INTERACTION",
        target = "Assembler",
        requirements = { RustyShell = 1, Scrap = 10 },
        rewards = { MiningBot = 1 },
        nextStep = 7
    },
    [7] = {
        id = "ENTER_MINE",
        name = "进入矿区",
        description = "通过传送门进入您的私人矿区",
        type = "TELEPORT",
        target = "MinePortal",
        requirements = {},
        rewards = {},
        nextStep = 8
    },
    [8] = {
        id = "MINING_TUTORIAL",
        name = "挖矿教学",
        description = "操作Mining Bot挖取8块同类矿石",
        type = "MINING_TASK",
        target = "AnyOre",
        targetAmount = 8,
        requirements = { SameOreType = 8 },
        rewards = { BuilderBot = 1 },
        nextStep = 9
    },
    [9] = {
        id = "TUTORIAL_COMPLETE",
        name = "教程完成",
        description = "返回主基地，教程完成！",
        type = "COMPLETION",
        requirements = {},
        rewards = { 
            Credits = 500,
            TierUnlock = 1
        },
        nextStep = nil
    }
}

-- 玩家教程数据存储
local playerTutorialData = {} -- [player] = tutorialData

-- 声明函数（将在后面定义）
local startAutoValidation

-- 默认教程数据结构
local function createDefaultTutorialData()
    return {
        isActive = false,
        currentStep = 0,
        completedSteps = {},
        startTime = 0,
        skipRequested = false,
        tutorialComplete = false,
        lastStepTime = 0
    }
end

-- 获取玩家教程数据
local function getPlayerTutorialData(player)
    if not playerTutorialData[player] then
        playerTutorialData[player] = createDefaultTutorialData()
    end
    return playerTutorialData[player]
end

-- 开始教程
local function startTutorial(player)
    local tutorialData = getPlayerTutorialData(player)
    
    -- 允许手动重新启动教程（用于测试和调试）
    if tutorialData.tutorialComplete then
        print("[TutorialManager] 玩家已完成教程，但允许重新开始:", player.Name)
        -- 重置教程数据
        tutorialData.tutorialComplete = false
        tutorialData.isActive = false
        tutorialData.currentStep = 0
        tutorialData.completedSteps = {}
    end
    
    tutorialData.isActive = true
    tutorialData.currentStep = 1
    tutorialData.startTime = tick()
    tutorialData.lastStepTime = tick()
    
    print("[TutorialManager] 开始教程:", player.Name)
    
    -- 通知客户端开始教程
    tutorialEvent:FireClient(player, "START_TUTORIAL", {
        currentStep = 1,
        stepData = TUTORIAL_STEPS[1]
    })
    
    -- 启动自动验证
    startAutoValidation(player)
    
    return true
end

-- 验证步骤完成
local function validateStepCompletion(player, stepId, data)
    local tutorialData = getPlayerTutorialData(player)
    
    if not tutorialData.isActive then
        return false
    end
    
    local currentStep = TUTORIAL_STEPS[tutorialData.currentStep]
    if not currentStep or currentStep.id ~= stepId then
        warn("[TutorialManager] 步骤不匹配:", player.Name, stepId, "期望:", currentStep and currentStep.id or "nil")
        return false
    end
    
    -- 根据步骤类型验证完成条件
    local isValid = false
    
    if currentStep.type == "CUTSCENE" then
        -- 过场动画验证 - 如果客户端发送了完成信号，直接认为有效
        -- 否则使用时间验证作为备选
        isValid = (data ~= nil) or ((tick() - tutorialData.lastStepTime) >= (currentStep.duration or 5))
        
    elseif currentStep.type == "UI_INTERACTION" then
        -- UI交互验证
        isValid = data and data.target == currentStep.target
        
    elseif currentStep.type == "BUILDING_PLACEMENT" then
        -- 建筑放置验证
        isValid = data and data.buildingType == currentStep.target
        
    elseif currentStep.type == "RESOURCE_COLLECTION" then
        -- 资源收集验证（使用服务器端GameLogic）
        local ServerModules = script.Parent:WaitForChild("ServerModules")
        local GameLogic = require(ServerModules.GameLogicServer)
        local playerData = GameLogic.GetPlayerData(player)
        if playerData and currentStep.target == "Scrap" then
            local currentScrap = playerData.Scrap or 0
            local targetAmount = currentStep.targetAmount or 0
            isValid = currentScrap >= targetAmount
            print("[TutorialManager] 验证Scrap收集:", player.Name, "当前:", currentScrap, "目标:", targetAmount, "通过:", isValid)
        end
        
    elseif currentStep.type == "MACHINE_INTERACTION" then
        -- 机器交互验证
        isValid = data and data.machineType == currentStep.target
        
    elseif currentStep.type == "TELEPORT" then
        -- 传送验证
        isValid = data and data.destination == "MINE"
        
    elseif currentStep.type == "MINING_TASK" then
        -- 挖矿任务验证
        isValid = data and (data.oreCount or 0) >= (currentStep.targetAmount or 0)
        
    elseif currentStep.type == "COMPLETION" then
        -- 完成验证
        isValid = true
    end
    
    return isValid
end

-- 完成当前步骤
local function completeCurrentStep(player)
    local tutorialData = getPlayerTutorialData(player)
    
    if not tutorialData.isActive then
        return false
    end
    
    local currentStep = TUTORIAL_STEPS[tutorialData.currentStep]
    if not currentStep then
        return false
    end
    
    -- 记录完成的步骤
    table.insert(tutorialData.completedSteps, {
        stepId = currentStep.id,
        completedTime = tick(),
        duration = tick() - tutorialData.lastStepTime
    })
    
    -- 给予奖励
    if currentStep.rewards then
        giveStepRewards(player, currentStep.rewards)
    end
    
    print("[TutorialManager] 步骤完成:", player.Name, currentStep.id)
    
    -- 检查是否有下一步
    if currentStep.nextStep then
        tutorialData.currentStep = currentStep.nextStep
        tutorialData.lastStepTime = tick()
        
        local nextStep = TUTORIAL_STEPS[currentStep.nextStep]
        
        -- 通知客户端进入下一步
        tutorialEvent:FireClient(player, "NEXT_STEP", {
            currentStep = currentStep.nextStep,
            stepData = nextStep,
            completedStep = currentStep
        })
        
        -- 重新启动自动验证
        startAutoValidation(player)
        
    else
        -- 教程完成
        completeTutorial(player)
    end
    
    return true
end

-- 给予步骤奖励
function giveStepRewards(player, rewards)
    if not rewards then return end
    
    -- 加载现有的游戏逻辑系统
    local ServerModules = script.Parent:WaitForChild("ServerModules")
    local GameLogic = require(ServerModules.GameLogicServer)
    
    for rewardType, amount in pairs(rewards) do
        print("[TutorialManager] 给予奖励:", player.Name, rewardType, amount)
        
        if rewardType == "Credits" then
            GameLogic.AddCredits(player, amount)
        elseif rewardType == "Scrap" then
            GameLogic.AddScrap(player, amount)
        elseif rewardType == "TierUnlock" then
            -- 解锁Tier系统 - 标记教程完成
            if GameLogic.MarkTutorialComplete then
                GameLogic.MarkTutorialComplete(player)
            else
                warn("[TutorialManager] GameLogic.MarkTutorialComplete 方法不存在")
            end
        else
            -- 其他物品奖励
            GameLogic.AddItem(player, rewardType, amount)
        end
    end
    
    -- 刷新玩家背包
    local UpdateInvEvt = ReplicatedStorage.RemoteEvents:FindFirstChild("UpdateInventoryEvent")
    if UpdateInvEvt then
        UpdateInvEvt:FireClient(player, GameLogic.GetInventoryDict(player))
    end
end

-- 完成整个教程
function completeTutorial(player)
    local tutorialData = getPlayerTutorialData(player)
    
    tutorialData.isActive = false
    tutorialData.tutorialComplete = true
    tutorialData.currentStep = 0
    
    local totalTime = tick() - tutorialData.startTime
    
    print("[TutorialManager] 教程完成:", player.Name, "总用时:", math.floor(totalTime), "秒")
    
    -- 给予完成奖励
    giveStepRewards(player, TUTORIAL_STEPS[9].rewards)
    
    -- 通知客户端教程完成
    tutorialEvent:FireClient(player, "TUTORIAL_COMPLETE", {
        totalTime = totalTime,
        completedSteps = tutorialData.completedSteps
    })
    
    -- 更新玩家数据中的教程完成状态
    local ServerModules = script.Parent:WaitForChild("ServerModules")
    local GameLogic = require(ServerModules.GameLogicServer)
    local playerData = GameLogic.GetPlayerData(player)
    
    if playerData then
        playerData.TutorialComplete = true
        print("[TutorialManager] 已保存教程完成状态到玩家数据:", player.Name)
    end
end

-- 跳过教程
local function skipTutorial(player)
    local tutorialData = getPlayerTutorialData(player)
    
    if not tutorialData.isActive then
        return false
    end
    
    tutorialData.skipRequested = true
    
    print("[TutorialManager] 玩家请求跳过教程:", player.Name)
    
    -- 直接完成教程，但不给予所有奖励
    completeTutorial(player)
    
    return true
end

-- 获取教程进度
local function getTutorialProgress(player)
    local tutorialData = getPlayerTutorialData(player)
    
    return {
        isActive = tutorialData.isActive,
        currentStep = tutorialData.currentStep,
        totalSteps = #TUTORIAL_STEPS,
        completedSteps = #tutorialData.completedSteps,
        tutorialComplete = tutorialData.tutorialComplete,
        currentStepData = tutorialData.isActive and TUTORIAL_STEPS[tutorialData.currentStep] or nil
    }
end

-- 自动检查需要周期性验证的步骤
startAutoValidation = function(player)
    local tutorialData = getPlayerTutorialData(player)
    if not tutorialData.isActive then
        return
    end
    
    task.spawn(function()
        while tutorialData.isActive and Players:FindFirstChild(player.Name) do
            local currentStep = TUTORIAL_STEPS[tutorialData.currentStep]
            if currentStep then
                -- 对资源收集步骤进行自动验证
                if currentStep.type == "RESOURCE_COLLECTION" then
                    if validateStepCompletion(player, currentStep.id, nil) then
                        print("[TutorialManager] 自动检测到步骤完成:", player.Name, currentStep.id)
                        completeCurrentStep(player)
                        break
                    end
                end
            end
            task.wait(2) -- 每2秒检查一次
        end
    end)
end

--------------------------------------------------------------------
-- 远程通信处理
--------------------------------------------------------------------

-- 处理客户端请求
tutorialFunction.OnServerInvoke = function(player, action, ...)
    local args = {...}
    
    if action == "GET_TUTORIAL_PROGRESS" then
        return getTutorialProgress(player)
        
    elseif action == "START_TUTORIAL" then
        return startTutorial(player)
        
    elseif action == "SKIP_TUTORIAL" then
        return skipTutorial(player)
        
    else
        warn("[TutorialManager] 未知请求:", action)
        return nil
    end
end

-- 处理客户端事件
tutorialEvent.OnServerEvent:Connect(function(player, action, ...)
    local args = {...}
    
    if action == "STEP_COMPLETED" then
        local stepId, data = args[1], args[2]
        
        if validateStepCompletion(player, stepId, data) then
            completeCurrentStep(player)
        else
            warn("[TutorialManager] 步骤验证失败:", player.Name, stepId)
        end
        
    elseif action == "REQUEST_HINT" then
        -- 请求提示
        local tutorialData = getPlayerTutorialData(player)
        if tutorialData.isActive then
            local currentStep = TUTORIAL_STEPS[tutorialData.currentStep]
            tutorialEvent:FireClient(player, "SHOW_HINT", {
                stepData = currentStep,
                hintText = currentStep.description
            })
        end
        
    else
        warn("[TutorialManager] 未知事件:", action)
    end
end)

--------------------------------------------------------------------
-- 玩家连接处理
--------------------------------------------------------------------

-- 玩家加入时检查是否需要开始教程
Players.PlayerAdded:Connect(function(player)
    task.spawn(function()
        -- 等待玩家数据加载
        task.wait(3)
        
        -- 检查玩家数据（服务器端直接访问）
        local ServerModules = script.Parent:WaitForChild("ServerModules")
        local GameLogic = require(ServerModules.GameLogicServer)
        local playerData = GameLogic.GetPlayerData(player)
        
        if playerData then
            -- 检查玩家是否是新玩家（放宽条件便于测试）
            local isNewPlayer = true -- 默认为新玩家
            
            -- 只有明确标记完成教程的玩家才不启动
            if playerData.TutorialComplete then
                isNewPlayer = false
            end
            
            -- 额外检查：如果玩家有很多资源和机器人，可能是老玩家
            local scrapCount = playerData.Scrap or 0
            local creditsCount = playerData.Credits or 0
            local hasRobots = false
            
            if playerData.Inventory then
                for _, item in pairs(playerData.Inventory) do
                    if item.itemId and (string.find(item.itemId, "Bot") or string.find(item.itemId, "Robot")) then
                        hasRobots = true
                        break
                    end
                end
            end
            
            -- 如果玩家资源很多且有机器人，可能不是新玩家（但仍允许手动启动）
            if scrapCount > 2000 and creditsCount > 5000 and hasRobots then
                print("[TutorialManager] 玩家可能是老玩家，不自动启动教程（但可手动启动）")
                isNewPlayer = false
            end
            
            print("[TutorialManager] 玩家检查结果:", player.Name, "新玩家:", isNewPlayer)
            
            if isNewPlayer then
                print("[TutorialManager] 准备开始教程:", player.Name)
                
                -- 延迟5秒开始教程，让玩家完全加载
                task.wait(2)
                
                -- 确认玩家还在线
                if player.Parent and Players:FindFirstChild(player.Name) then
                    startTutorial(player)
                else
                    print("[TutorialManager] 玩家已离线，取消教程:", player.Name)
                end
            else
                print("[TutorialManager] 玩家已完成教程或不是新玩家:", player.Name)
            end
        else
            warn("[TutorialManager] 无法获取玩家数据:", player.Name)
        end
    end)
end)

-- 玩家离开时清理数据
Players.PlayerRemoving:Connect(function(player)
    if playerTutorialData[player] then
        print("[TutorialManager] 清理玩家教程数据:", player.Name)
        playerTutorialData[player] = nil
    end
end)

print("[TutorialManager] 新手教程管理系统已启动")
print("[TutorialManager] 支持的教程步骤:", #TUTORIAL_STEPS, "个")
print("[TutorialManager] 远程事件已注册，可以使用F键启动教程")