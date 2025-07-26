--------------------------------------------------------------------
-- WorldSetup.server.lua · 世界环境设置
-- 功能：
--   1) 平铺地板（使用ServerStorage/Other中的BasePlate）
--   2) 设置出生点
--   3) 创建排行榜
--------------------------------------------------------------------

local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

--------------------------------------------------------------------
-- 地板平铺系统
--------------------------------------------------------------------
local function createFloorTiles()
    -- 获取地板模型
    local otherFolder = ServerStorage:FindFirstChild("Other")
    if not otherFolder then
        warn("[WorldSetup] 找不到 ServerStorage/Other 文件夹")
        return
    end
    
    local basePlateModel = otherFolder:FindFirstChild("BasePlate")
    if not basePlateModel then
        warn("[WorldSetup] 找不到 ServerStorage/Other/BasePlate 模型")
        return
    end
    
    print("[WorldSetup] 开始平铺地板...")
    
    -- 地板平铺配置
    local TILE_SIZE = 50  -- 每个地板块50x50 studs  
    local GRID_SIZE = 10  -- 10x10的网格，总共100块地板
    local START_OFFSET = -(GRID_SIZE * TILE_SIZE) / 2 + TILE_SIZE / 2
    
    print("[WorldSetup] 地板配置: TILE_SIZE=" .. TILE_SIZE .. ", GRID_SIZE=" .. GRID_SIZE .. ", START_OFFSET=" .. START_OFFSET)
    
    -- 创建地板容器
    local floorContainer = Instance.new("Model")
    floorContainer.Name = "FloorTiles"
    floorContainer.Parent = Workspace
    
    for x = 0, GRID_SIZE - 1 do
        for z = 0, GRID_SIZE - 1 do
            -- 克隆地板块
            local tile = basePlateModel:Clone()
            tile.Name = "FloorTile_" .. x .. "_" .. z
            
            -- 计算位置 - 确保无缝连接
            local posX = START_OFFSET + (x * TILE_SIZE)
            local posZ = START_OFFSET + (z * TILE_SIZE)
            local posY = -2 -- 地板在地面以下一点，调整高度避免遮挡
            
            -- 设置位置和属性
            if tile:IsA("Model") then
                -- 如果是模型，寻找主要部件
                if not tile.PrimaryPart then
                    for _, part in pairs(tile:GetChildren()) do
                        if part:IsA("BasePart") then
                            tile.PrimaryPart = part
                            break
                        end
                    end
                end
                
                if tile.PrimaryPart then
                    tile:SetPrimaryPartCFrame(CFrame.new(posX, posY, posZ))
                    -- 确保所有部件锚定并设置属性
                    for _, part in pairs(tile:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.Anchored = true
                            -- 设置地板材质和外观
                            part.Material = Enum.Material.Concrete
                            part.BrickColor = BrickColor.new("Medium stone grey")
                            -- 确保尺寸正确
                            if part.Name == "BasePlate" then
                                part.Size = Vector3.new(TILE_SIZE, 4, TILE_SIZE)
                            end
                        end
                    end
                end
            elseif tile:IsA("BasePart") then
                tile.Position = Vector3.new(posX, posY, posZ)
                tile.Anchored = true
                -- 设置地板材质和尺寸
                tile.Material = Enum.Material.Concrete
                tile.BrickColor = BrickColor.new("Medium stone grey")
                tile.Size = Vector3.new(TILE_SIZE, 4, TILE_SIZE)
            end
            
            tile.Parent = floorContainer
            
            print("[WorldSetup] 放置地板块:", tile.Name, "位置:", Vector3.new(posX, posY, posZ))
        end
    end
    
    print("[WorldSetup] 地板平铺完成，共", GRID_SIZE * GRID_SIZE, "块")
    print("[WorldSetup] 地板总覆盖范围:", (GRID_SIZE * TILE_SIZE) .. "x" .. (GRID_SIZE * TILE_SIZE), "studs")
    
    -- 检查地板连续性
    local actualFloorSize = GRID_SIZE * TILE_SIZE
    local expectedCoverage = actualFloorSize * actualFloorSize
    local actualTiles = GRID_SIZE * GRID_SIZE
    local tileArea = TILE_SIZE * TILE_SIZE
    local totalTileArea = actualTiles * tileArea
    
    print("[WorldSetup] 理论覆盖面积:" .. expectedCoverage .. " 实际瓦片面积:" .. totalTileArea)
    if expectedCoverage == totalTileArea then
        print("[WorldSetup] ✓ 地板无空隙，完美覆盖")
    else
        warn("[WorldSetup] ⚠ 地板可能有空隙或重叠")
    end
end

--------------------------------------------------------------------
-- 出生点设置
--------------------------------------------------------------------
local function setupSpawnPoint()
    -- 移除现有的出生点
    for _, obj in pairs(Workspace:GetChildren()) do
        if obj:IsA("SpawnLocation") then
            obj:Destroy()
        end
    end
    
    -- 创建新的出生点
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "MainSpawn"
    spawn.Size = Vector3.new(6, 1, 6)
    spawn.Position = Vector3.new(0, 0.5, 0) -- 在0,0,0上方一点
    spawn.Material = Enum.Material.Neon
    spawn.BrickColor = BrickColor.new("Bright green")
    spawn.Anchored = true
    spawn.CanCollide = true
    spawn.TopSurface = Enum.SurfaceType.Smooth
    spawn.BottomSurface = Enum.SurfaceType.Smooth
    spawn.Parent = Workspace
    
    -- 添加出生点标识
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 200, 0, 50)
    billboardGui.StudsOffset = Vector3.new(0, 3, 0)
    billboardGui.Parent = spawn
    
    local spawnLabel = Instance.new("TextLabel")
    spawnLabel.Size = UDim2.new(1, 0, 1, 0)
    spawnLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    spawnLabel.BackgroundTransparency = 0.3
    spawnLabel.Text = "🏠 出生点"
    spawnLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    spawnLabel.TextScaled = true
    spawnLabel.Font = Enum.Font.GothamBold
    spawnLabel.Parent = billboardGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = spawnLabel
    
    print("[WorldSetup] 出生点已设置在 (0, 0.5, 0)")
end

--------------------------------------------------------------------
-- 排行榜系统
--------------------------------------------------------------------
local function createLeaderboard(title, position, dataKey, icon, color)
    -- 创建排行榜主体
    local leaderboard = Instance.new("Part")
    leaderboard.Name = title .. "Leaderboard"
    leaderboard.Size = Vector3.new(8, 12, 1)
    leaderboard.Position = position
    leaderboard.Material = Enum.Material.SmoothPlastic
    leaderboard.BrickColor = BrickColor.new("Dark stone grey")
    leaderboard.Anchored = true
    leaderboard.CanCollide = false
    leaderboard.Parent = Workspace
    
    -- 添加边框效果
    local selectionBox = Instance.new("SelectionBox")
    selectionBox.Adornee = leaderboard
    selectionBox.Color3 = color
    selectionBox.LineThickness = 0.2
    selectionBox.Transparency = 0.5
    selectionBox.Parent = leaderboard
    
    -- 创建排行榜界面
    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Face = Enum.NormalId.Front
    surfaceGui.Parent = leaderboard
    
    -- 标题栏
    local titleFrame = Instance.new("Frame")
    titleFrame.Size = UDim2.new(1, 0, 0.15, 0)
    titleFrame.Position = UDim2.new(0, 0, 0, 0)
    titleFrame.BackgroundColor3 = color
    titleFrame.BorderSizePixel = 0
    titleFrame.Parent = surfaceGui
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -10, 1, 0)
    titleLabel.Position = UDim2.new(0, 5, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = icon .. " " .. title
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = titleFrame
    
    -- 排行榜内容区域
    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, 0, 0.85, 0)
    contentFrame.Position = UDim2.new(0, 0, 0.15, 0)
    contentFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    contentFrame.BorderSizePixel = 0
    contentFrame.Parent = surfaceGui
    
    -- 创建排行榜条目
    for i = 1, 10 do
        local entryFrame = Instance.new("Frame")
        entryFrame.Size = UDim2.new(1, -10, 0.08, 0)
        entryFrame.Position = UDim2.new(0, 5, 0, (i - 1) * 0.085)
        entryFrame.BackgroundColor3 = i <= 3 and Color3.fromRGB(60, 60, 60) or Color3.fromRGB(50, 50, 50)
        entryFrame.BorderSizePixel = 0
        entryFrame.Parent = contentFrame
        
        local entryCorner = Instance.new("UICorner")
        entryCorner.CornerRadius = UDim.new(0, 4)
        entryCorner.Parent = entryFrame
        
        -- 排名
        local rankLabel = Instance.new("TextLabel")
        rankLabel.Size = UDim2.new(0.15, 0, 1, 0)
        rankLabel.Position = UDim2.new(0, 0, 0, 0)
        rankLabel.BackgroundTransparency = 1
        rankLabel.Text = "#" .. i
        rankLabel.TextColor3 = i <= 3 and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(200, 200, 200)
        rankLabel.TextScaled = true
        rankLabel.Font = Enum.Font.GothamBold
        rankLabel.Parent = entryFrame
        
        -- 玩家名
        local playerLabel = Instance.new("TextLabel")
        playerLabel.Size = UDim2.new(0.5, 0, 1, 0)
        playerLabel.Position = UDim2.new(0.15, 0, 0, 0)
        playerLabel.BackgroundTransparency = 1
        playerLabel.Text = "---"
        playerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        playerLabel.TextScaled = true
        playerLabel.Font = Enum.Font.Gotham
        playerLabel.TextXAlignment = Enum.TextXAlignment.Left
        playerLabel.Parent = entryFrame
        
        -- 数值
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(0.35, 0, 1, 0)
        valueLabel.Position = UDim2.new(0.65, 0, 0, 0)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = "0"
        valueLabel.TextColor3 = color
        valueLabel.TextScaled = true
        valueLabel.Font = Enum.Font.GothamBold
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right
        valueLabel.Parent = entryFrame
        
        -- 存储引用以便更新
        entryFrame.Name = "Entry" .. i
        entryFrame:SetAttribute("PlayerLabel", playerLabel)
        entryFrame:SetAttribute("ValueLabel", valueLabel)
    end
    
    return leaderboard
end

local function setupLeaderboards()
    print("[WorldSetup] 创建排行榜...")
    
    -- 排行榜位置（围绕出生点）
    local positions = {
        Vector3.new(-15, 6, 0),  -- 左侧 - Credits
        Vector3.new(0, 6, -15),  -- 前方 - Playtime  
        Vector3.new(15, 6, 0),   -- 右侧 - Bots
    }
    
    local configs = {
        {
            title = "最多金币",
            position = positions[1],
            dataKey = "Credits",
            icon = "💰",
            color = Color3.fromRGB(255, 215, 0)
        },
        {
            title = "最长游戏时间",
            position = positions[2], 
            dataKey = "PlayTime",
            icon = "⏱️",
            color = Color3.fromRGB(100, 255, 100)
        },
        {
            title = "最多机器人",
            position = positions[3],
            dataKey = "BotCount", 
            icon = "🤖",
            color = Color3.fromRGB(100, 200, 255)
        }
    }
    
    -- 创建排行榜
    for _, config in ipairs(configs) do
        createLeaderboard(config.title, config.position, config.dataKey, config.icon, config.color)
    end
    
    print("[WorldSetup] 排行榜创建完成")
end

--------------------------------------------------------------------
-- 排行榜数据更新系统
--------------------------------------------------------------------
local function updateLeaderboards()
    -- 获取所有玩家数据
    local ServerModules = script.Parent:WaitForChild("ServerModules")
    local GameLogic = require(ServerModules.GameLogicServer)
    
    local playerData = {}
    
    -- 收集在线玩家数据
    for _, player in pairs(Players:GetPlayers()) do
        local data = GameLogic.GetPlayerData(player)
        if data then
            -- 计算机器人总数
            local botCount = 0
            if data.Inventory then
                for _, item in pairs(data.Inventory) do
                    if string.find(item.itemId:lower(), "bot") then
                        botCount = botCount + item.quantity
                    end
                end
            end
            
            -- 计算游戏时间（简化版）
            local playTime = (data.PlayTime or 0) + (tick() - (data.SessionStartTime or tick()))
            
            table.insert(playerData, {
                name = player.Name,
                credits = data.Credits or 0,
                playTime = playTime,
                botCount = botCount
            })
        end
    end
    
    -- 更新各个排行榜
    local leaderboards = {
        {name = "最多金币Leaderboard", key = "credits", format = function(val) return string.format("%.0f", val) end},
        {name = "最长游戏时间Leaderboard", key = "playTime", format = function(val) return string.format("%.1f小时", val / 3600) end},
        {name = "最多机器人Leaderboard", key = "botCount", format = function(val) return string.format("%.0f", val) end}
    }
    
    for _, lb in ipairs(leaderboards) do
        local leaderboard = Workspace:FindFirstChild(lb.name)
        if leaderboard then
            -- 排序数据
            local sortedData = {}
            for _, data in pairs(playerData) do
                table.insert(sortedData, data)
            end
            table.sort(sortedData, function(a, b) return a[lb.key] > b[lb.key] end)
            
            -- 更新显示
            local surfaceGui = leaderboard:FindFirstChild("SurfaceGui")
            if surfaceGui then
                local contentFrame = surfaceGui:FindFirstChild("Frame")
                if contentFrame then
                    for i = 1, 10 do
                        local entry = contentFrame:FindFirstChild("Entry" .. i)
                        if entry then
                            local playerLabel = entry:FindFirstChild("TextLabel")
                            local valueLabel = entry:FindFirstChild("TextLabel")
                            
                            -- 找到正确的标签
                            for _, child in pairs(entry:GetChildren()) do
                                if child:IsA("TextLabel") and child.TextXAlignment == Enum.TextXAlignment.Left then
                                    playerLabel = child
                                elseif child:IsA("TextLabel") and child.TextXAlignment == Enum.TextXAlignment.Right then
                                    valueLabel = child
                                end
                            end
                            
                            if sortedData[i] then
                                playerLabel.Text = sortedData[i].name
                                valueLabel.Text = lb.format(sortedData[i][lb.key])
                            else
                                playerLabel.Text = "---"
                                valueLabel.Text = "0"
                            end
                        end
                    end
                end
            end
        end
    end
end

--------------------------------------------------------------------
-- 初始化
--------------------------------------------------------------------
local function initialize()
    print("[WorldSetup] 开始世界设置...")
    
    -- 设置地板
    createFloorTiles()
    
    -- 设置出生点
    setupSpawnPoint()
    
    -- 创建排行榜
    setupLeaderboards()
    
    -- 定期更新排行榜
    task.spawn(function()
        while true do
            task.wait(30) -- 每30秒更新一次
            pcall(updateLeaderboards) -- 使用pcall防止错误中断循环
        end
    end)
    
    print("[WorldSetup] 世界设置完成！")
end

-- 延迟初始化，确保其他系统已加载
task.spawn(function()
    task.wait(3)
    initialize()
end)

print("[WorldSetup] 世界设置系统已启动")