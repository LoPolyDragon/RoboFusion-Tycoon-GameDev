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

-- 调试：列出工作区中的所有排行榜
local function listAllLeaderboards()
    print("[LeaderboardManager] 检查工作区中的所有排行榜...")
    local found = false
    for _, child in pairs(Workspace:GetChildren()) do
        if child.Name:find("Leaderboard") or child.Name:find("LeaderboardEntity_") then
            print("[LeaderboardManager] 找到排行榜:", child.Name)
            found = true
        end
    end
    if not found then
        print("[LeaderboardManager] 工作区中没有找到任何排行榜！")
    end
end

-- 实体排行榜支持 - 新函数
local function updateEntityLeaderboard(entityName, dataKey, formatType)
    local entity = nil
    -- 查找排行榜实体
    for _, child in pairs(Workspace:GetChildren()) do
        if child:IsA("Model") and child.Name == "LeaderboardEntity_" .. entityName then
            entity = child
            break
        end
    end
    
    if not entity then
        warn("[LeaderboardManager] 找不到实体排行榜:", entityName)
        return
    end
    
    local mainBoard = entity:FindFirstChild("MainBoard")
    if not mainBoard then
        warn("[LeaderboardManager] 找不到MainBoard部件:", entityName)
        return
    end
    
    local contentGui = mainBoard:FindFirstChild("ContentGui")
    if not contentGui then
        warn("[LeaderboardManager] 找不到ContentGui:", entityName)
        return
    end
    
    local contentFrame = contentGui:FindFirstChild("ContentFrame")
    if not contentFrame then
        warn("[LeaderboardManager] 找不到ContentFrame:", entityName)
        return
    end
    
    print("[LeaderboardManager] 更新实体排行榜:", entityName, "数据键:", dataKey)
    
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
                if _G.GetPlayerCurrentPlayTime then
                    value = _G.GetPlayerCurrentPlayTime(player)
                else
                    value = data.PlayTime or 0
                end
            elseif dataKey == "BotCount" then
                value = calculateBotCount(data.Inventory)
            end
            
            print("[LeaderboardManager] 玩家数据:", player.Name, dataKey, "=", value)
            
            table.insert(playerData, {
                name = player.Name,
                value = value
            })
        else
            warn("[LeaderboardManager] 无法获取玩家数据:", player.Name)
        end
    end
    
    print("[LeaderboardManager] 排行榜", entityName, "收集到", #playerData, "个玩家数据")
    
    -- 排序数据
    table.sort(playerData, function(a, b) return a.value > b.value end)
    
    -- 更新显示
    for i = 1, 10 do
        local entry = contentFrame:FindFirstChild("Entry" .. i)
        if entry then
            local playerLabel = entry:FindFirstChild("PlayerLabel")
            local valueLabel = entry:FindFirstChild("ValueLabel")
            
            if playerLabel and valueLabel then
                if playerData[i] then
                    playerLabel.Text = playerData[i].name
                    valueLabel.Text = formatValue(playerData[i].value, formatType)
                    print("[LeaderboardManager] 设置第", i, "名:", playerData[i].name, "=", formatValue(playerData[i].value, formatType))
                else
                    playerLabel.Text = "---"
                    valueLabel.Text = "0"
                    print("[LeaderboardManager] 第", i, "名为空")
                end
            else
                warn("[LeaderboardManager] Entry" .. i .. "缺少标签组件")
            end
        end
    end
end

-- 更新所有排行榜
local function updateAllLeaderboards()
    listAllLeaderboards() -- 先列出所有排行榜
    
    local leaderboards = {
        {name = "最多金币", key = "Credits", format = "credits"},
        {name = "最长游戏时间", key = "PlayTime", format = "playTime"},
        {name = "最多机器人", key = "BotCount", format = "botCount"}
    }
    
    for _, lb in ipairs(leaderboards) do
        pcall(function()
            updateEntityLeaderboard(lb.name, lb.key, lb.format)
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
    
    -- 添加调试命令
    player.Chatted:Connect(function(message)
        if message == "/listboards" then
            listAllLeaderboards()
        elseif message == "/updateboards" then
            print("[LeaderboardManager] 手动更新排行榜...")
            updateAllLeaderboards()
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    task.wait(1)
    updateAllLeaderboards()
end)

print("[LeaderboardManager] 排行榜管理系统已加载")
print("[LeaderboardManager] 配置为使用3D实体排行榜")