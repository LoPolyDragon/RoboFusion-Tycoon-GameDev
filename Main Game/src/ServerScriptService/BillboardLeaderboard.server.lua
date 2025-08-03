--------------------------------------------------------------------
-- LeaderboardEntity.server.lua · 使用实体模型的排行榜系统
-- 功能：创建3D实体排行榜，替代原来的BillboardGui
--------------------------------------------------------------------

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

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

-- 创建3D实体排行榜
local function createEntityLeaderboard(title, position, dataKey, formatType, color)
    print("[EntityLeaderboard] 创建排行榜:", title)
    
    -- 清理旧的
    local existingBoard = Workspace:FindFirstChild("LeaderboardEntity_" .. title)
    if existingBoard then
        existingBoard:Destroy()
    end
    
    -- 创建排行榜根模型
    local boardModel = Instance.new("Model")
    boardModel.Name = "LeaderboardEntity_" .. title
    boardModel.Parent = Workspace
    
    -- 主体部分
    local mainBoard = Instance.new("Part")
    mainBoard.Name = "MainBoard"
    mainBoard.Size = Vector3.new(20, 26, 0.5) -- 再次加大尺寸，远处更清晰
    mainBoard.Position = position
    mainBoard.Material = Enum.Material.SmoothPlastic
    mainBoard.Color = color
    mainBoard.Transparency = 0 -- 完全不透明
    mainBoard.Anchored = true
    mainBoard.CanCollide = false
    mainBoard.Parent = boardModel
    
    -- 让排行榜朝向出生点
    local spawnPosition = Vector3.new(0, 5, 0)
    mainBoard.CFrame = CFrame.lookAt(position, Vector3.new(spawnPosition.X, position.Y, spawnPosition.Z))
    
    -- 标题板
    local titleBoard = Instance.new("Part")
    titleBoard.Name = "TitleBoard"
    titleBoard.Size = Vector3.new(20, 2.5, 0.3) -- 同步放大标题板
    titleBoard.Position = position + Vector3.new(0, mainBoard.Size.Y/2 - titleBoard.Size.Y/2 + 0.1, -0.2)
    titleBoard.CFrame = mainBoard.CFrame * CFrame.new(0, mainBoard.Size.Y/2 - titleBoard.Size.Y/2 + 0.1, -0.2)
    titleBoard.Material = Enum.Material.SmoothPlastic
    titleBoard.Color = color
    titleBoard.Transparency = 0 -- 不透明
    titleBoard.Anchored = true
    titleBoard.CanCollide = false
    titleBoard.Parent = boardModel
    
    -- 标题文字
    local titleText = Instance.new("SurfaceGui")
    titleText.Name = "TitleText"
    titleText.Face = Enum.NormalId.Front
    titleText.LightInfluence = 0
    titleText.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    titleText.PixelsPerStud = 50
    titleText.Parent = titleBoard
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 1, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🏆 " .. title
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = titleText
    
    -- 装饰边框
    local function createBorder(name, offset, size, transparency)
        local border = Instance.new("Part")
        border.Name = name
        border.Size = size
        border.CFrame = mainBoard.CFrame * CFrame.new(offset)
        border.Material = Enum.Material.Metal
        border.Color = color
        border.Transparency = transparency
        border.Anchored = true
        border.CanCollide = false
        border.Parent = boardModel
        return border
    end
    
    -- 四周边框设置为不透明
    createBorder("TopBorder", Vector3.new(0, mainBoard.Size.Y/2 + 0.1, 0), Vector3.new(mainBoard.Size.X + 0.4, 0.3, 0.6), 0)
    createBorder("BottomBorder", Vector3.new(0, -mainBoard.Size.Y/2 - 0.1, 0), Vector3.new(mainBoard.Size.X + 0.4, 0.3, 0.6), 0)
    createBorder("LeftBorder", Vector3.new(-mainBoard.Size.X/2 - 0.1, 0, 0), Vector3.new(0.3, mainBoard.Size.Y + 0.4, 0.6), 0)
    createBorder("RightBorder", Vector3.new(mainBoard.Size.X/2 + 0.1, 0, 0), Vector3.new(0.3, mainBoard.Size.Y + 0.4, 0.6), 0)
    
    -- 内容区域SurfaceGui
    local contentGui = Instance.new("SurfaceGui")
    contentGui.Name = "ContentGui"
    contentGui.Face = Enum.NormalId.Front
    contentGui.LightInfluence = 0
    contentGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    contentGui.PixelsPerStud = 100 -- 提高分辨率，字体更清晰
    contentGui.Parent = mainBoard
    
    -- 主框架
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(0.9, 0, 0.9, 0)
    contentFrame.Position = UDim2.new(0.05, 0, 0.05, 0)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = contentGui
    
    -- 创建排行条目
    for i = 1, 10 do
        local entryFrame = Instance.new("Frame")
        entryFrame.Name = "Entry" .. i
        entryFrame.Size = UDim2.new(1, 0, 0.08, 0)
        entryFrame.Position = UDim2.new(0, 0, 0.1 + (i-1) * 0.08, 0)
        entryFrame.BackgroundColor3 = i == 1 and Color3.fromRGB(255, 215, 0)
            or i == 2 and Color3.fromRGB(230, 230, 230)
            or i == 3 and Color3.fromRGB(180, 120, 70)
            or Color3.fromRGB(40, 40, 50)
        entryFrame.BackgroundTransparency = i <= 3 and 0.4 or 0.7
        entryFrame.BorderSizePixel = 0
        entryFrame.Parent = contentFrame
        
        -- 条目圆角
        local entryCorner = Instance.new("UICorner")
        entryCorner.CornerRadius = UDim.new(0.2, 0)
        entryCorner.Parent = entryFrame
        
        -- 排名
        local rankLabel = Instance.new("TextLabel")
        rankLabel.Name = "RankLabel"
        rankLabel.Size = UDim2.new(0.15, 0, 1, 0)
        rankLabel.Position = UDim2.new(0, 0, 0, 0)
        rankLabel.BackgroundTransparency = 1
        rankLabel.Text = "#" .. i
        rankLabel.TextColor3 = i == 1 and Color3.fromRGB(255, 215, 0)
            or i == 2 and Color3.fromRGB(230, 230, 230)
            or i == 3 and Color3.fromRGB(180, 120, 70)
            or Color3.fromRGB(255, 255, 255)
        rankLabel.TextStrokeTransparency = 0.5
        rankLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        rankLabel.TextScaled = true
        rankLabel.Font = i <= 3 and Enum.Font.GothamBold or Enum.Font.Gotham
        rankLabel.Parent = entryFrame
        
        -- 玩家名称
        local playerLabel = Instance.new("TextLabel")
        playerLabel.Name = "PlayerLabel"
        playerLabel.Size = UDim2.new(0.5, 0, 1, 0)
        playerLabel.Position = UDim2.new(0.15, 0, 0, 0)
        playerLabel.BackgroundTransparency = 1
        playerLabel.Text = "---"
        playerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        playerLabel.TextStrokeTransparency = 0.5
        playerLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        playerLabel.TextScaled = true
        playerLabel.Font = Enum.Font.Gotham
        playerLabel.TextXAlignment = Enum.TextXAlignment.Left
        playerLabel.Parent = entryFrame
        
        -- 数值
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Name = "ValueLabel"
        valueLabel.Size = UDim2.new(0.35, 0, 1, 0)
        valueLabel.Position = UDim2.new(0.65, 0, 0, 0)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = "0"
        valueLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        valueLabel.TextStrokeTransparency = 0.5
        valueLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        valueLabel.TextScaled = true
        valueLabel.Font = Enum.Font.GothamBold
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right
        valueLabel.Parent = entryFrame
    end
    
    -- 存储属性
    mainBoard:SetAttribute("DataKey", dataKey)
    mainBoard:SetAttribute("FormatType", formatType)
    
    -- 关闭发光特效（不创建Highlight）
    
    -- 不再创建粒子效果，移除附件
    
    print("[EntityLeaderboard] 排行榜", title, "创建完成")
    return boardModel
end

-- 更新排行榜数据
local function updateLeaderboard(boardModel)
    if not boardModel then return end
    
    local mainBoard = boardModel:FindFirstChild("MainBoard")
    if not mainBoard then return end
    
    local dataKey = mainBoard:GetAttribute("DataKey")
    local formatType = mainBoard:GetAttribute("FormatType")
    
    local contentGui = mainBoard:FindFirstChild("ContentGui")
    if not contentGui then return end
    
    local contentFrame = contentGui:FindFirstChild("ContentFrame")
    if not contentFrame then return end
    
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
            local playerLabel = entry:FindFirstChild("PlayerLabel")
            local valueLabel = entry:FindFirstChild("ValueLabel")
            
            if playerLabel and valueLabel then
                if playerData[i] then
                    -- 使用Tween动画更新文本
                    local formattedValue = formatValue(playerData[i].value, formatType)
                    
                    -- 先设置名称
                    playerLabel.Text = playerData[i].name
                    
                    -- 为数值添加动画
                    if valueLabel.Text ~= formattedValue then
                        local oldVal = tonumber(string.match(valueLabel.Text, "%d+")) or 0
                        local newVal = playerData[i].value
                        
                        -- 创建值变化动画
                        if oldVal < newVal and math.abs(oldVal - newVal) > 1 then
                            local startVal = oldVal
                            local goal = newVal
                            local duration = 0.8
                            local count = 0
                            local updateFreq = 0.05
                            
                            task.spawn(function()
                                while count < duration do
                                    count = count + updateFreq
                                    local alpha = count / duration
                                    local currentVal = startVal + (goal - startVal) * alpha
                                    valueLabel.Text = formatValue(currentVal, formatType)
                                    task.wait(updateFreq)
                                end
                                valueLabel.Text = formattedValue
                            end)
                        else
                            valueLabel.Text = formattedValue
                        end
                    end
                else
                    playerLabel.Text = "---"
                    valueLabel.Text = "0"
                end
            end
        end
    end
    
    -- 添加更新动画效果
    local highlight = boardModel:FindFirstChild("Highlight")
    if highlight then
        local originalTransparency = highlight.OutlineTransparency
        local tween = TweenService:Create(highlight, 
            TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {OutlineTransparency = 0.2}
        )
        tween:Play()
        
        tween.Completed:Connect(function()
            local revertTween = TweenService:Create(highlight,
                TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                {OutlineTransparency = originalTransparency}
            )
            revertTween:Play()
        end)
    end
end

-- 更新所有排行榜
local function updateAllLeaderboards()
    local boards = {}
    
    -- 查找所有的实体排行榜
    for _, child in pairs(Workspace:GetChildren()) do
        if child:IsA("Model") and string.find(child.Name, "LeaderboardEntity_") then
            table.insert(boards, child)
        end
    end
    
    for _, board in pairs(boards) do
        pcall(function()
            updateLeaderboard(board)
        end)
    end
end

-- 创建所有排行榜
local function createAllLeaderboards()
    print("[EntityLeaderboard] 开始创建所有排行榜...")
    -- 清理所有旧排行榜
    for _, child in pairs(Workspace:GetChildren()) do
        if (child:IsA("Part") and (
                string.find(child.Name, "Leaderboard") or 
                string.find(child.Name, "Board") or
                string.find(child.Name, "Billboard")
            )) or 
            (child:IsA("Model") and string.find(child.Name, "LeaderboardEntity_")) 
        then
            print("[EntityLeaderboard] 删除旧排行榜:", child.Name)
            child:Destroy()
        end
    end
    task.wait(1)
    -- 创建新排行榜
    local configs = {
        {
            title = "最多金币",
            position = Vector3.new(-20, 10, 0),
            dataKey = "Credits",
            formatType = "credits",
            color = Color3.fromRGB(255, 215, 0)
        },
        {
            title = "最长游戏时间",
            position = Vector3.new(0, 10, -20),
            dataKey = "PlayTime",
            formatType = "playTime",
            color = Color3.fromRGB(100, 255, 100)
        },
        {
            title = "最多机器人",
            position = Vector3.new(20, 10, 0),
            dataKey = "BotCount",
            formatType = "botCount",
            color = Color3.fromRGB(100, 200, 255)
        }
    }
    for _, config in pairs(configs) do
        createEntityLeaderboard(
            config.title,
            config.position,
            config.dataKey,
            config.formatType,
            config.color
        )
    end
    task.wait(2)
    updateAllLeaderboards()
end

-- 启动系统
local initialized = false
local function ensureLeaderboards()
    if not initialized then
        initialized = true
        createAllLeaderboards()
        -- 定期刷新
        task.spawn(function()
            while true do
                task.wait(15)
                updateAllLeaderboards()
            end
        end)
    end
end

Players.PlayerAdded:Connect(function(player)
    task.wait(2)
    ensureLeaderboards()
    updateAllLeaderboards()
    
    -- 添加管理员指令
    if player:GetAttribute("IsAdmin") then
        player.Chatted:Connect(function(msg)
            if msg == "/refreshboards" then
                updateAllLeaderboards()
                return
            elseif msg == "/resetboards" then
                createAllLeaderboards()
                return
            end
        end)
    end
end)

-- 游戏启动时也确保排行榜存在
task.delay(5, ensureLeaderboards)

print("[EntityLeaderboard] 3D实体排行榜系统已加载")