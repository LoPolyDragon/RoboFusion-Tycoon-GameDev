--------------------------------------------------------------------
-- LeaderboardManager.server.lua · 排行榜管理系统
-- 功能：
--   1) 管理所有排行榜数据
--   2) 定期更新排行榜显示
--   3) 处理玩家数据统计
--------------------------------------------------------------------

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- 获取GameLogic系统
local function getGameLogic()
    local ServerModules = script.Parent:WaitForChild("ServerModules")
    return require(ServerModules.GameLogicServer)
end

-- 计算玩家机器人总数
local function calculateBotCount(inventory)
    local botCount = 0
    if inventory then
        for _, item in pairs(inventory) do
            -- 检查物品ID是否包含"Bot"
            if item.itemId and string.find(item.itemId:lower(), "bot") then
                botCount = botCount + (item.quantity or 0)
            end
        end
    end
    return botCount
end

-- 格式化数值显示
local function formatValue(value, type)
    if type == "credits" then
        if value >= 1000000 then
            return string.format("%.1fM", value / 1000000)
        elseif value >= 1000 then
            return string.format("%.1fK", value / 1000)
        else
            return string.format("%.0f", value)
        end
    elseif type == "playTime" then
        local hours = value / 3600
        if hours >= 1 then
            return string.format("%.1f小时", hours)
        else
            return string.format("%.0f分钟", value / 60)
        end
    elseif type == "botCount" then
        return string.format("%.0f", value)
    end
    return tostring(value)
end

-- 更新单个排行榜
local function updateSingleLeaderboard(leaderboardName, dataKey, formatType)
    local leaderboard = Workspace:FindFirstChild(leaderboardName)
    if not leaderboard then
        return
    end
    
    local surfaceGui = leaderboard:FindFirstChild("SurfaceGui")
    if not surfaceGui then
        return
    end
    
    local contentFrame = surfaceGui:FindFirstChild("Frame")
    if not contentFrame then
        return
    end
    
    -- 收集玩家数据
    local GameLogic = getGameLogic()
    local playerData = {}
    
    for _, player in pairs(Players:GetPlayers()) do
        local data = GameLogic.GetPlayerData(player)
        if data then
            local value = 0
            
            if dataKey == "Credits" then
                value = data.Credits or 0
            elseif dataKey == "PlayTime" then
                -- 使用全局函数获取当前游戏时间
                if _G.GetPlayerCurrentPlayTime then
                    value = _G.GetPlayerCurrentPlayTime(player)
                else
                    value = data.PlayTime or 0
                end
            elseif dataKey == "BotCount" then
                value = calculateBotCount(data.Inventory)
            end
            
            table.insert(playerData, {
                name = player.Name,
                value = value
            })
        end
    end
    
    -- 排序数据
    table.sort(playerData, function(a, b) return a.value > b.value end)
    
    -- 更新显示
    for i = 1, 10 do
        local entry = contentFrame:FindFirstChild("Entry" .. i)
        if entry then
            local playerLabel = nil
            local valueLabel = nil
            
            -- 找到正确的标签
            for _, child in pairs(entry:GetChildren()) do
                if child:IsA("TextLabel") then
                    if child.TextXAlignment == Enum.TextXAlignment.Left then
                        playerLabel = child
                    elseif child.TextXAlignment == Enum.TextXAlignment.Right then
                        valueLabel = child
                    end
                end
            end
            
            if playerLabel and valueLabel then
                if playerData[i] then
                    playerLabel.Text = playerData[i].name
                    valueLabel.Text = formatValue(playerData[i].value, formatType)
                else
                    playerLabel.Text = "---"
                    valueLabel.Text = "0"
                end
            end
        end
    end
end

-- 更新所有排行榜
local function updateAllLeaderboards()
    local leaderboards = {
        {name = "最多金币Leaderboard", key = "Credits", format = "credits"},
        {name = "最长游戏时间Leaderboard", key = "PlayTime", format = "playTime"},
        {name = "最多机器人Leaderboard", key = "BotCount", format = "botCount"}
    }
    
    for _, lb in ipairs(leaderboards) do
        pcall(function()
            updateSingleLeaderboard(lb.name, lb.key, lb.format)
        end)
    end
end

-- 定期更新排行榜
task.spawn(function()
    -- 等待世界设置完成
    task.wait(10)
    
    while true do
        updateAllLeaderboards()
        task.wait(15) -- 每15秒更新一次
    end
end)

-- 当玩家加入/离开时立即更新
Players.PlayerAdded:Connect(function(player)
    task.wait(3) -- 等待数据加载
    updateAllLeaderboards()
end)

Players.PlayerRemoving:Connect(function(player)
    task.wait(1)
    updateAllLeaderboards()
end)

print("[LeaderboardManager] 排行榜管理系统已启动")