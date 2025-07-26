--------------------------------------------------------------------
-- PlayTimeTracker.server.lua · 游戏时间追踪系统
-- 功能：
--   1) 追踪玩家的游戏时间
--   2) 自动保存游戏时长
--   3) 为排行榜提供数据
--------------------------------------------------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- 玩家会话数据
local playerSessions = {} -- [player] = {startTime = tick(), totalTime = 0}

-- 获取GameLogic系统
local function getGameLogic()
    local ServerModules = script.Parent:WaitForChild("ServerModules")
    return require(ServerModules.GameLogicServer)
end

-- 玩家加入时开始追踪
Players.PlayerAdded:Connect(function(player)
    task.wait(2) -- 等待数据加载
    
    local GameLogic = getGameLogic()
    local playerData = GameLogic.GetPlayerData(player)
    
    if playerData then
        playerSessions[player] = {
            startTime = tick(),
            totalTime = playerData.PlayTime or 0
        }
        
        -- 设置会话开始时间（用于排行榜计算）
        playerData.SessionStartTime = tick()
        
        print("[PlayTimeTracker] 开始追踪玩家游戏时间:", player.Name)
    end
end)

-- 玩家离开时保存数据
Players.PlayerRemoving:Connect(function(player)
    local session = playerSessions[player]
    if session then
        local sessionTime = tick() - session.startTime
        local totalTime = session.totalTime + sessionTime
        
        -- 保存到玩家数据
        local GameLogic = getGameLogic()
        local playerData = GameLogic.GetPlayerData(player)
        if playerData then
            playerData.PlayTime = totalTime
            print("[PlayTimeTracker] 保存玩家游戏时间:", player.Name, "本次:", math.floor(sessionTime/60), "分钟", "总计:", math.floor(totalTime/3600), "小时")
        end
        
        playerSessions[player] = nil
    end
end)

-- 定期保存游戏时间（防止数据丢失）
task.spawn(function()
    while true do
        task.wait(300) -- 每5分钟保存一次
        
        for player, session in pairs(playerSessions) do
            if player and player.Parent then
                local sessionTime = tick() - session.startTime
                local totalTime = session.totalTime + sessionTime
                
                local GameLogic = getGameLogic()
                local playerData = GameLogic.GetPlayerData(player)
                if playerData then
                    playerData.PlayTime = totalTime
                end
                
                -- 重置会话计时器
                session.startTime = tick()
                session.totalTime = totalTime
            end
        end
    end
end)

-- 提供获取当前游戏时间的函数
function getPlayerCurrentPlayTime(player)
    local session = playerSessions[player]
    if session then
        local sessionTime = tick() - session.startTime
        return session.totalTime + sessionTime
    end
    
    local GameLogic = getGameLogic()
    local playerData = GameLogic.GetPlayerData(player)
    return playerData and playerData.PlayTime or 0
end

-- 将函数暴露给其他系统使用
_G.GetPlayerCurrentPlayTime = getPlayerCurrentPlayTime

print("[PlayTimeTracker] 游戏时间追踪系统已启动")