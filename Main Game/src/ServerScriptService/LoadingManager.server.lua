--------------------------------------------------------------------
-- LoadingManager.server.lua · 游戏加载管理系统
-- 功能：
--   1) 协调各个系统的初始化顺序
--   2) 报告加载进度给客户端
--   3) 确保所有系统就绪后才允许游戏开始
--   4) 管理加载状态和错误处理
--------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- 获取远程通信
local RE = ReplicatedStorage:WaitForChild("RemoteEvents")
local RF = ReplicatedStorage:WaitForChild("RemoteFunctions")

-- 创建加载进度事件
local loadingProgressEvent = RE:FindFirstChild("LoadingProgressEvent")
if not loadingProgressEvent then
    loadingProgressEvent = Instance.new("RemoteEvent")
    loadingProgressEvent.Name = "LoadingProgressEvent"
    loadingProgressEvent.Parent = RE
end

local loadingCompleteEvent = RE:FindFirstChild("LoadingCompleteEvent")
if not loadingCompleteEvent then
    loadingCompleteEvent = Instance.new("RemoteEvent")
    loadingCompleteEvent.Name = "LoadingCompleteEvent"
    loadingCompleteEvent.Parent = RE
end

-- 加载状态管理
local LoadingManager = {
    systems = {},
    playerLoadingStates = {}, -- [player] = loadingData
    isWorldReady = false,
}

-- 注册系统加载状态
function LoadingManager.registerSystem(systemName, isLoaded, loadFunction)
    LoadingManager.systems[systemName] = {
        name = systemName,
        isLoaded = isLoaded,
        loadFunction = loadFunction,
        progress = 0,
    }
    print("[LoadingManager] 注册系统:", systemName)
end

-- 更新系统进度
function LoadingManager.updateSystemProgress(systemName, progress, details)
    if LoadingManager.systems[systemName] then
        LoadingManager.systems[systemName].progress = progress
        
        -- 广播进度更新给所有客户端
        loadingProgressEvent:FireAllClients("SYSTEM_PROGRESS", systemName, progress, details)
        print("[LoadingManager] 系统进度更新:", systemName, progress .. "%", details or "")
    end
end

-- 标记系统加载完成
function LoadingManager.markSystemComplete(systemName)
    if LoadingManager.systems[systemName] then
        LoadingManager.systems[systemName].isLoaded = true
        LoadingManager.systems[systemName].progress = 100
        
        loadingProgressEvent:FireAllClients("SYSTEM_COMPLETE", systemName)
        print("[LoadingManager] 系统加载完成:", systemName)
        
        LoadingManager.checkAllSystemsReady()
    end
end

-- 检查所有系统是否就绪
function LoadingManager.checkAllSystemsReady()
    local allReady = true
    local totalProgress = 0
    local systemCount = 0
    
    for systemName, systemData in pairs(LoadingManager.systems) do
        systemCount = systemCount + 1
        totalProgress = totalProgress + systemData.progress
        
        if not systemData.isLoaded then
            allReady = false
        end
    end
    
    local overallProgress = systemCount > 0 and (totalProgress / systemCount) or 0
    
    if allReady and not LoadingManager.isWorldReady then
        LoadingManager.isWorldReady = true
        loadingProgressEvent:FireAllClients("WORLD_READY", overallProgress)
        print("[LoadingManager] 🎉 所有系统加载完成，世界就绪！")
    else
        loadingProgressEvent:FireAllClients("OVERALL_PROGRESS", overallProgress)
    end
end

-- 玩家加入时的处理
function LoadingManager.onPlayerAdded(player)
    LoadingManager.playerLoadingStates[player] = {
        isReady = false,
        joinTime = tick(),
    }
    
    print("[LoadingManager] 玩家加入:", player.Name)
    
    -- 发送当前加载状态给新玩家
    task.spawn(function()
        task.wait(1) -- 等待客户端加载界面准备
        
        for systemName, systemData in pairs(LoadingManager.systems) do
            loadingProgressEvent:FireClient(player, "SYSTEM_PROGRESS", systemName, systemData.progress)
            if systemData.isLoaded then
                loadingProgressEvent:FireClient(player, "SYSTEM_COMPLETE", systemName)
            end
        end
        
        if LoadingManager.isWorldReady then
            loadingProgressEvent:FireClient(player, "WORLD_READY", 100)
        end
    end)
end

-- 玩家离开时的处理
function LoadingManager.onPlayerRemoving(player)
    LoadingManager.playerLoadingStates[player] = nil
    print("[LoadingManager] 玩家离开:", player.Name)
end

--------------------------------------------------------------------
-- 系统初始化
--------------------------------------------------------------------

-- 注册核心系统
LoadingManager.registerSystem("RemoteEvents", true) -- 已经加载
LoadingManager.registerSystem("GameLogic", false)
LoadingManager.registerSystem("WorldSetup", false)
LoadingManager.registerSystem("TutorialSystem", false)
LoadingManager.registerSystem("EnergySystem", false)

-- 监听世界设置进度
task.spawn(function()
    task.wait(1) -- 等待事件创建
    local worldSetupProgressEvent = RE:FindFirstChild("WorldSetupProgressEvent")
    if worldSetupProgressEvent then
        worldSetupProgressEvent.OnServerEvent:Connect(function(player, action, ...)
            if action == "FLOOR_PROGRESS" then
                local progress, completed, total = ...
                LoadingManager.updateSystemProgress("WorldSetup", progress, "地板生成: " .. completed .. "/" .. total)
                
                if progress >= 100 then
                    LoadingManager.markSystemComplete("WorldSetup")
                end
            end
        end)
    else
        -- 如果没有找到事件，标记WorldSetup为完成（兼容性）
        task.wait(5)
        LoadingManager.updateSystemProgress("WorldSetup", 100, "世界设置完成")
        LoadingManager.markSystemComplete("WorldSetup")
    end
end)

-- 检查GameLogic系统
task.spawn(function()
    task.wait(2)
    
    local ServerModules = ServerScriptService:FindFirstChild("ServerModules")
    if ServerModules then
        local GameLogic = ServerModules:FindFirstChild("GameLogicServer")
        if GameLogic then
            LoadingManager.updateSystemProgress("GameLogic", 100, "游戏逻辑系统已加载")
            LoadingManager.markSystemComplete("GameLogic")
        end
    end
end)

-- 检查教程系统
task.spawn(function()
    task.wait(3)
    
    local tutorialEvent = RE:FindFirstChild("TutorialEvent")
    local tutorialFunction = RF:FindFirstChild("TutorialFunction")
    
    if tutorialEvent and tutorialFunction then
        LoadingManager.updateSystemProgress("TutorialSystem", 100, "教程系统已加载")
        LoadingManager.markSystemComplete("TutorialSystem")
    end
end)

-- 检查能量系统
task.spawn(function()
    task.wait(4)
    
    local energyStationEvent = RE:FindFirstChild("EnergyStationEvent")
    if energyStationEvent then
        LoadingManager.updateSystemProgress("EnergySystem", 100, "能量系统已加载")
        LoadingManager.markSystemComplete("EnergySystem")
    end
end)

-- 玩家事件处理
Players.PlayerAdded:Connect(LoadingManager.onPlayerAdded)
Players.PlayerRemoving:Connect(LoadingManager.onPlayerRemoving)

-- 处理客户端加载完成
loadingCompleteEvent.OnServerEvent:Connect(function(player)
    if LoadingManager.playerLoadingStates[player] then
        LoadingManager.playerLoadingStates[player].isReady = true
        local loadTime = tick() - LoadingManager.playerLoadingStates[player].joinTime
        print("[LoadingManager] 玩家加载完成:", player.Name, "用时:", math.floor(loadTime), "秒")
    end
end)

print("[LoadingManager] 🚀 加载管理系统已启动")

return LoadingManager