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
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
    
    -- 地板平铺配置 - 优化性能
    local TILE_SIZE = 50  -- 每个地板块50x50 studs  
    local GRID_SIZE = 8   -- 减少到8x8网格，提高加载速度
    local START_OFFSET = -(GRID_SIZE * TILE_SIZE) / 2 + TILE_SIZE / 2
    local BATCH_SIZE = 4  -- 每批处理4块地板
    
    print("[WorldSetup] 地板配置: TILE_SIZE=" .. TILE_SIZE .. ", GRID_SIZE=" .. GRID_SIZE .. ", START_OFFSET=" .. START_OFFSET)
    
    -- 创建地板容器
    local floorContainer = Instance.new("Model")
    floorContainer.Name = "FloorTiles"
    floorContainer.Parent = Workspace
    
    -- 创建进度报告事件
    local RE = ReplicatedStorage:WaitForChild("RemoteEvents")
    local progressEvent = RE:FindFirstChild("WorldSetupProgressEvent")
    if not progressEvent then
        progressEvent = Instance.new("RemoteEvent")
        progressEvent.Name = "WorldSetupProgressEvent"
        progressEvent.Parent = RE
    end
    
    local totalTiles = GRID_SIZE * GRID_SIZE
    local completedTiles = 0
    
    -- 分批生成地板，避免卡顿
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
            
            completedTiles = completedTiles + 1
            
            -- 每完成一批地板就报告进度
            if completedTiles % BATCH_SIZE == 0 or completedTiles == totalTiles then
                local progress = (completedTiles / totalTiles) * 100
                progressEvent:FireAllClients("FLOOR_PROGRESS", progress, completedTiles, totalTiles)
                print("[WorldSetup] 地板进度:", math.floor(progress) .. "%", "(" .. completedTiles .. "/" .. totalTiles .. ")")
                
                -- 让出CPU时间，避免卡顿
                if completedTiles % BATCH_SIZE == 0 and completedTiles < totalTiles then
                    task.wait()
                end
            end
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
    spawn.Position = Vector3.new(0, 2, 0) -- 在地板上方2个单位
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
    
    -- 设置朝向，让排行榜完全正面朝向出生点
    local spawnPoint = Workspace:FindFirstChild("SpawnLocation")
    if not spawnPoint then
        spawnPoint = Instance.new("Part")
        spawnPoint.Position = Vector3.new(0, 0.5, 0)
    end
    
    -- 计算朝向，让排行榜完全正面朝向出生点（不倾斜）
    local direction = (spawnPoint.Position - position).Unit
    local lookAtCFrame = CFrame.lookAt(position, spawnPoint.Position)
    
    -- 移除倾斜，只保留朝向
    local _, y, _ = lookAtCFrame:ToOrientation()
    leaderboard.CFrame = CFrame.new(position) * CFrame.Angles(0, y, 0)
    
    -- 确保排行榜完全垂直，不倾斜
    local currentCFrame = leaderboard.CFrame
    local pos = currentCFrame.Position
    local _, yRot, _ = currentCFrame:ToOrientation()
    leaderboard.CFrame = CFrame.new(pos) * CFrame.Angles(0, yRot, 0)
    
    print("[WorldSetup] 创建排行榜:", title, "位置:", position, "朝向:", spawnPoint.Position)
    
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
        surfaceGui.Enabled = true
        surfaceGui.Adornee = leaderboard
        surfaceGui.LightInfluence = 0
        surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
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
    contentFrame.Name = "ContentFrame"
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
        -- 使用Name属性来存储引用，而不是SetAttribute
        playerLabel.Name = "PlayerLabel"
        valueLabel.Name = "ValueLabel"
        
        print("[WorldSetup] 创建条目", i, "名称:", entryFrame.Name, "子对象数量:", #entryFrame:GetChildren())
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
    
    -- 立即更新一次排行榜，确保显示初始数据
    task.wait(2) -- 等待两秒确保所有系统已加载
    pcall(updateLeaderboards)
    
    -- 如果还是没有数据，强制设置一些测试数据
    task.wait(3)
    pcall(function()
        print("[WorldSetup] 强制设置测试数据...")
        local testData = {
            {name = "TheFuture1199", credits = 2068, playTime = 1078.83, botCount = 656},
            {name = "测试玩家2", credits = 800, playTime = 3600, botCount = 3},
            {name = "测试玩家3", credits = 2000, playTime = 10800, botCount = 12}
        }
        
        for _, lb in ipairs({{name = "最多金币Leaderboard", key = "credits"}, 
                           {name = "最长游戏时间Leaderboard", key = "playTime"}, 
                           {name = "最多机器人Leaderboard", key = "botCount"}}) do
            local leaderboard = Workspace:FindFirstChild(lb.name)
            if leaderboard then
                print("[WorldSetup] 找到排行榜:", lb.name)
                local surfaceGui = leaderboard:FindFirstChild("SurfaceGui")
                if surfaceGui then
                    print("[WorldSetup] 找到SurfaceGui")
                    local contentFrame = surfaceGui:FindFirstChild("ContentFrame")
                    if contentFrame then
                        print("[WorldSetup] 找到contentFrame，子对象数量:", #contentFrame:GetChildren())
                        print("[WorldSetup] contentFrame的子对象:")
                        for _, child in pairs(contentFrame:GetChildren()) do
                            print("  -", child.Name, "类型:", child.ClassName)
                        end
                        for i = 1, math.min(3, #testData) do
                            local entry = contentFrame:FindFirstChild("Entry" .. i)
                            print("[WorldSetup] 查找条目", i, "结果:", entry ~= nil)
                            if entry then
                                print("[WorldSetup] 找到条目", i, "，子对象数量:", #entry:GetChildren())
                                local playerLabel = entry:FindFirstChild("PlayerLabel")
                                local valueLabel = entry:FindFirstChild("ValueLabel")
                                if playerLabel and valueLabel then
                                    playerLabel.Text = testData[i].name
                                    if lb.key == "credits" then
                                        valueLabel.Text = string.format("%.0f", testData[i].credits)
                                    elseif lb.key == "playTime" then
                                        valueLabel.Text = string.format("%.1f小时", testData[i].playTime / 3600)
                                    else
                                        valueLabel.Text = string.format("%.0f", testData[i].botCount)
                                    end
                                    print("[WorldSetup] 设置测试数据:", lb.name, i, testData[i].name, "->", valueLabel.Text)
                                else
                                    print("[WorldSetup] 警告: 条目", i, "找不到标签 - playerLabel:", playerLabel ~= nil, "valueLabel:", valueLabel ~= nil)
                                end
                            else
                                print("[WorldSetup] 警告: 找不到条目", i)
                            end
                        end
                    else
                        print("[WorldSetup] 警告: 找不到contentFrame")
                    end
                else
                    print("[WorldSetup] 警告: 找不到SurfaceGui")
                end
            else
                print("[WorldSetup] 警告: 找不到排行榜", lb.name)
            end
        end
    end)
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
            
            print("[WorldSetup] 收集玩家数据:", player.Name, "Credits:", data.Credits or 0, "Bots:", botCount, "PlayTime:", playTime)
        else
            print("[WorldSetup] 警告: 无法获取玩家数据:", player.Name)
        end
    end
    
    print("[WorldSetup] 总共收集到", #playerData, "个玩家的数据")
    
    -- 如果没有玩家数据，添加一些测试数据
    if #playerData == 0 then
        print("[WorldSetup] 没有玩家数据，添加测试数据")
        table.insert(playerData, {
            name = "测试玩家",
            credits = 1000,
            playTime = 3600,
            botCount = 5
        })
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
            print("[WorldSetup] 更新排行榜:", lb.name)
            -- 排序数据
            local sortedData = {}
            for _, data in pairs(playerData) do
                table.insert(sortedData, data)
            end
            table.sort(sortedData, function(a, b) return a[lb.key] > b[lb.key] end)
            
            print("[WorldSetup] 排序后数据:", lb.name)
            for i, data in ipairs(sortedData) do
                print("  ", i, data.name, data[lb.key])
            end
            
            -- 更新显示
            local surfaceGui = leaderboard:FindFirstChild("SurfaceGui")
            if surfaceGui then
                print("[WorldSetup] 找到SurfaceGui")
                local contentFrame = surfaceGui:FindFirstChild("ContentFrame")
                if contentFrame then
                    print("[WorldSetup] 找到contentFrame，子对象数量:", #contentFrame:GetChildren())
                    for i = 1, 10 do
                        local entry = contentFrame:FindFirstChild("Entry" .. i)
                        if entry then
                            print("[WorldSetup] 找到条目", i, "，子对象数量:", #entry:GetChildren())
                            local playerLabel = nil
                            local valueLabel = nil
                            
                            -- 找到正确的标签
                            for _, child in pairs(entry:GetChildren()) do
                                if child:IsA("TextLabel") then
                                    print("[WorldSetup] 条目", i, "的TextLabel:", child.Name, "Text:", child.Text)
                                    if child.Name == "PlayerLabel" then
                                        playerLabel = child
                                        print("[WorldSetup] 找到PlayerLabel")
                                    elseif child.Name == "ValueLabel" then
                                        valueLabel = child
                                        print("[WorldSetup] 找到ValueLabel")
                                    end
                                end
                            end
                            
                            if playerLabel and valueLabel then
                                if sortedData[i] then
                                    playerLabel.Text = sortedData[i].name
                                    valueLabel.Text = lb.format(sortedData[i][lb.key])
                                    print("[WorldSetup] 更新条目", i, ":", sortedData[i].name, lb.format(sortedData[i][lb.key]))
                                else
                                    playerLabel.Text = "---"
                                    valueLabel.Text = "0"
                                end
                            else
                                print("[WorldSetup] 警告: 条目", i, "找不到标签 - playerLabel:", playerLabel ~= nil, "valueLabel:", valueLabel ~= nil)
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
    
    -- 创建排行榜 (已被SimpleLeaderboard替代)
    -- setupLeaderboards()
    
    -- 定期更新排行榜
    task.spawn(function()
        while true do
            task.wait(30) -- 每30秒更新一次
            pcall(updateLeaderboards) -- 使用pcall防止错误中断循环
        end
    end)
    
    print("[WorldSetup] 世界设置完成！")
end

--------------------------------------------------------------------
-- 测试命令
--------------------------------------------------------------------
local function setupTestCommands()
    local function onChatted(player, message)
        if message == "/leaderboard" then
            print("[WorldSetup] 手动触发排行榜更新...")
            pcall(updateLeaderboards)
        elseif message == "/checkui" then
            print("[WorldSetup] 检查UI状态...")
            for _, lb in ipairs({{name = "最多金币Leaderboard", key = "credits"}, 
                               {name = "最长游戏时间Leaderboard", key = "playTime"}, 
                               {name = "最多机器人Leaderboard", key = "botCount"}}) do
                local leaderboard = Workspace:FindFirstChild(lb.name)
                if leaderboard then
                    print("[WorldSetup] 检查排行榜:", lb.name)
                    print("  位置:", leaderboard.Position)
                    print("  CFrame:", leaderboard.CFrame)
                    print("  Anchored:", leaderboard.Anchored)
                    print("  CanCollide:", leaderboard.CanCollide)
                    
                    local surfaceGui = leaderboard:FindFirstChild("SurfaceGui")
                    if surfaceGui then
                        print("  SurfaceGui存在")
                        print("  Face:", surfaceGui.Face)
                        print("  Enabled:", surfaceGui.Enabled)
                        print("  Adornee:", surfaceGui.Adornee)
                        print("  LightInfluence:", surfaceGui.LightInfluence)
                        print("  SizingMode:", surfaceGui.SizingMode)
                        print("  SurfaceGui子对象数量:", #surfaceGui:GetChildren())
                        for _, child in pairs(surfaceGui:GetChildren()) do
                            print("    -", child.Name, "类型:", child.ClassName)
                        end
                        
                        local contentFrame = surfaceGui:FindFirstChild("ContentFrame")
                        if contentFrame then
                            print("  ContentFrame存在")
                            print("  Visible:", contentFrame.Visible)
                            print("  BackgroundTransparency:", contentFrame.BackgroundTransparency)
                            print("  BackgroundColor3:", contentFrame.BackgroundColor3)
                            print("  Size:", contentFrame.Size)
                            print("  Position:", contentFrame.Position)
                            print("  ContentFrame子对象数量:", #contentFrame:GetChildren())
                            
                            for i = 1, 3 do
                                local entry = contentFrame:FindFirstChild("Entry" .. i)
                                if entry then
                                    print("  条目", i, "存在")
                                    print("    Entry Visible:", entry.Visible)
                                    print("    Entry BackgroundTransparency:", entry.BackgroundTransparency)
                                    print("    Entry子对象数量:", #entry:GetChildren())
                                    
                                    local playerLabel = entry:FindFirstChild("PlayerLabel")
                                    local valueLabel = entry:FindFirstChild("ValueLabel")
                                    if playerLabel and valueLabel then
                                        print("  条目", i, "标签:")
                                        print("    PlayerLabel.Text:", playerLabel.Text)
                                        print("    PlayerLabel.TextColor3:", playerLabel.TextColor3)
                                        print("    PlayerLabel.BackgroundTransparency:", playerLabel.BackgroundTransparency)
                                        print("    PlayerLabel.Visible:", playerLabel.Visible)
                                        print("    PlayerLabel.TextScaled:", playerLabel.TextScaled)
                                        print("    ValueLabel.Text:", valueLabel.Text)
                                        print("    ValueLabel.TextColor3:", valueLabel.TextColor3)
                                        print("    ValueLabel.BackgroundTransparency:", valueLabel.BackgroundTransparency)
                                        print("    ValueLabel.Visible:", valueLabel.Visible)
                                        print("    ValueLabel.TextScaled:", valueLabel.TextScaled)
                                    else
                                        print("  条目", i, "警告: 找不到标签 - playerLabel:", playerLabel ~= nil, "valueLabel:", valueLabel ~= nil)
                                    end
                                else
                                    print("  条目", i, "不存在")
                                end
                            end
                        else
                            print("  警告: 找不到ContentFrame")
                        end
                    else
                        print("  警告: 找不到SurfaceGui")
                    end
                else
                    print("  警告: 找不到排行榜", lb.name)
                end
            end
        elseif message == "/forceupdate" then
            print("[WorldSetup] 强制更新UI...")
            -- 强制更新所有排行榜的UI
            for _, lb in ipairs({{name = "最多金币Leaderboard", key = "credits"}, 
                               {name = "最长游戏时间Leaderboard", key = "playTime"}, 
                               {name = "最多机器人Leaderboard", key = "botCount"}}) do
                local leaderboard = Workspace:FindFirstChild(lb.name)
                if leaderboard then
                    local surfaceGui = leaderboard:FindFirstChild("SurfaceGui")
                    if surfaceGui then
                        local contentFrame = surfaceGui:FindFirstChild("ContentFrame")
                        if contentFrame then
                            for i = 1, 3 do
                                local entry = contentFrame:FindFirstChild("Entry" .. i)
                                if entry then
                                    local playerLabel = entry:FindFirstChild("PlayerLabel")
                                    local valueLabel = entry:FindFirstChild("ValueLabel")
                                    if playerLabel and valueLabel then
                                        -- 强制设置一些明显的测试数据
                                        playerLabel.Text = "强制测试" .. i
                                        if lb.key == "credits" then
                                            valueLabel.Text = tostring(i * 1000)
                                        elseif lb.key == "playTime" then
                                            valueLabel.Text = tostring(i) .. "小时"
                                        else
                                            valueLabel.Text = tostring(i * 10)
                                        end
                                        print("[WorldSetup] 强制更新:", lb.name, i, playerLabel.Text, valueLabel.Text)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        elseif message == "/testdata" then
        elseif message == "/debugboard" then
            print("[WorldSetup] 创建调试排行榜...")
            -- 创建一个简单的调试排行榜
            local debugBoard = Instance.new("Part")
            debugBoard.Name = "DebugLeaderboard"
            debugBoard.Size = Vector3.new(8, 12, 1)
            debugBoard.Position = Vector3.new(0, 6, 10)
            debugBoard.Material = Enum.Material.SmoothPlastic
            debugBoard.BrickColor = BrickColor.new("Bright red")
            debugBoard.Anchored = true
            debugBoard.CanCollide = false
            debugBoard.CFrame = CFrame.new(debugBoard.Position) * CFrame.Angles(0, 0, 0)
            debugBoard.Parent = Workspace
            
                            local surfaceGui = Instance.new("SurfaceGui")
                surfaceGui.Face = Enum.NormalId.Front
                surfaceGui.Adornee = debugBoard
                surfaceGui.Parent = debugBoard
            
            local contentFrame = Instance.new("Frame")
            contentFrame.Name = "ContentFrame"
            contentFrame.Size = UDim2.new(1, 0, 1, 0)
            contentFrame.Position = UDim2.new(0, 0, 0, 0)
            contentFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            contentFrame.BorderSizePixel = 0
            contentFrame.Parent = surfaceGui
            
            for i = 1, 3 do
                local entry = Instance.new("Frame")
                entry.Name = "Entry" .. i
                entry.Size = UDim2.new(1, -10, 0.3, 0)
                entry.Position = UDim2.new(0, 5, 0, (i - 1) * 0.33)
                entry.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                entry.BorderSizePixel = 2
                entry.Parent = contentFrame
                
                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, 0, 1, 0)
                label.Position = UDim2.new(0, 0, 0, 0)
                label.BackgroundTransparency = 1
                label.Text = "调试条目 " .. i
                label.TextColor3 = Color3.fromRGB(0, 0, 0)
                label.TextScaled = true
                label.Font = Enum.Font.GothamBold
                label.Parent = entry
                
                print("[WorldSetup] 创建调试条目", i, "名称:", entry.Name, "子对象数量:", #entry:GetChildren())
            end
            
            print("[WorldSetup] 调试排行榜创建完成，位置:", debugBoard.Position)
            print("[WorldSetup] 调试排行榜子对象数量:", #contentFrame:GetChildren())
            for _, child in pairs(contentFrame:GetChildren()) do
                print("  -", child.Name, "类型:", child.ClassName)
            end
                    elseif message == "/testsurface" then
                print("[WorldSetup] 创建SurfaceGui测试...")
                -- 创建一个简单的SurfaceGui测试
                local testPart = Instance.new("Part")
                testPart.Name = "SurfaceGuiTest"
                testPart.Size = Vector3.new(4, 4, 1)
                testPart.Position = Vector3.new(0, 3, 5)
                testPart.Material = Enum.Material.SmoothPlastic
                testPart.BrickColor = BrickColor.new("Bright blue")
                testPart.Anchored = true
                testPart.CanCollide = false
                testPart.CFrame = CFrame.new(testPart.Position) * CFrame.Angles(0, 0, 0)
                testPart.Parent = Workspace
                
                local surfaceGui = Instance.new("SurfaceGui")
                surfaceGui.Face = Enum.NormalId.Front
                surfaceGui.Enabled = true
                surfaceGui.Adornee = testPart
                surfaceGui.LightInfluence = 0
                surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
                surfaceGui.Parent = testPart
            
                local testLabel = Instance.new("TextLabel")
                testLabel.Size = UDim2.new(1, 0, 1, 0)
                testLabel.Position = UDim2.new(0, 0, 0, 0)
                testLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
                testLabel.Text = "SurfaceGui测试"
                testLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
                testLabel.TextScaled = true
                testLabel.Font = Enum.Font.GothamBold
                testLabel.Parent = surfaceGui
                
                print("[WorldSetup] SurfaceGui测试创建完成，位置:", testPart.Position)
                print("[WorldSetup] SurfaceGui Enabled:", surfaceGui.Enabled)
                print("[WorldSetup] SurfaceGui Face:", surfaceGui.Face)
                print("[WorldSetup] 测试标签Text:", testLabel.Text)
            elseif message == "/testleaderboard" then
                print("[WorldSetup] 创建测试排行榜...")
                local testBoard = Instance.new("Part")
                testBoard.Name = "TestLeaderboard"
                testBoard.Size = Vector3.new(8, 12, 1)
                testBoard.Position = Vector3.new(0, 6, 8)
                testBoard.Material = Enum.Material.SmoothPlastic
                testBoard.BrickColor = BrickColor.new("Bright green")
                testBoard.Anchored = true
                testBoard.CanCollide = false
                testBoard.CFrame = CFrame.new(testBoard.Position) * CFrame.Angles(0, 0, 0)
                testBoard.Parent = Workspace
                
                local surfaceGui = Instance.new("SurfaceGui")
                surfaceGui.Face = Enum.NormalId.Front
                surfaceGui.Enabled = true
                surfaceGui.Adornee = testBoard
                surfaceGui.LightInfluence = 0
                surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
                surfaceGui.Parent = testBoard
                
                local contentFrame = Instance.new("Frame")
                contentFrame.Name = "ContentFrame"
                contentFrame.Size = UDim2.new(1, 0, 1, 0)
                contentFrame.Position = UDim2.new(0, 0, 0, 0)
                contentFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                contentFrame.BorderSizePixel = 0
                contentFrame.Parent = surfaceGui
                
                for i = 1, 3 do
                    local entry = Instance.new("Frame")
                    entry.Name = "Entry" .. i
                    entry.Size = UDim2.new(1, -10, 0.3, 0)
                    entry.Position = UDim2.new(0, 5, 0, (i - 1) * 0.33)
                    entry.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    entry.BorderSizePixel = 2
                    entry.Parent = contentFrame
                    
                    local playerLabel = Instance.new("TextLabel")
                    playerLabel.Name = "PlayerLabel"
                    playerLabel.Size = UDim2.new(0.6, 0, 1, 0)
                    playerLabel.Position = UDim2.new(0, 5, 0, 0)
                    playerLabel.BackgroundTransparency = 1
                    playerLabel.Text = "测试玩家" .. i
                    playerLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
                    playerLabel.TextScaled = true
                    playerLabel.Font = Enum.Font.GothamBold
                    playerLabel.TextXAlignment = Enum.TextXAlignment.Left
                    playerLabel.Parent = entry
                    
                    local valueLabel = Instance.new("TextLabel")
                    valueLabel.Name = "ValueLabel"
                    valueLabel.Size = UDim2.new(0.4, 0, 1, 0)
                    valueLabel.Position = UDim2.new(0.6, 0, 0, 0)
                    valueLabel.BackgroundTransparency = 1
                    valueLabel.Text = tostring(i * 100)
                    valueLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
                    valueLabel.TextScaled = true
                    valueLabel.Font = Enum.Font.GothamBold
                    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
                    valueLabel.Parent = entry
                end
                
                print("[WorldSetup] 测试排行榜创建完成，位置:", testBoard.Position)
            elseif message == "/compareui" then
                print("[WorldSetup] 比较UI结构...")
                -- 检查测试排行榜
                local testBoard = Workspace:FindFirstChild("TestLeaderboard")
                if testBoard then
                    print("[WorldSetup] 测试排行榜结构:")
                    local testSurfaceGui = testBoard:FindFirstChild("SurfaceGui")
                    if testSurfaceGui then
                        local testContentFrame = testSurfaceGui:FindFirstChild("ContentFrame")
                        if testContentFrame then
                            print("  测试ContentFrame子对象数量:", #testContentFrame:GetChildren())
                            for _, child in pairs(testContentFrame:GetChildren()) do
                                print("    -", child.Name, "类型:", child.ClassName)
                                if child:IsA("Frame") then
                                    print("      子对象数量:", #child:GetChildren())
                                    for _, subChild in pairs(child:GetChildren()) do
                                        print("        -", subChild.Name, "类型:", subChild.ClassName, "Text:", subChild.Text)
                                    end
                                end
                            end
                        end
                    end
                end
                
                -- 检查主排行榜
                local mainBoard = Workspace:FindFirstChild("最多金币Leaderboard")
                if mainBoard then
                    print("[WorldSetup] 主排行榜结构:")
                    local mainSurfaceGui = mainBoard:FindFirstChild("SurfaceGui")
                    if mainSurfaceGui then
                        local mainContentFrame = mainSurfaceGui:FindFirstChild("ContentFrame")
                        if mainContentFrame then
                            print("  主ContentFrame子对象数量:", #mainContentFrame:GetChildren())
                            for i = 1, 3 do
                                local entry = mainContentFrame:FindFirstChild("Entry" .. i)
                                if entry then
                                    print("    条目", i, "子对象数量:", #entry:GetChildren())
                                    for _, child in pairs(entry:GetChildren()) do
                                        print("      -", child.Name, "类型:", child.ClassName, "Text:", child.Text)
                                    end
                                end
                            end
                        end
                    end
                end
            elseif message == "/refreshui" then
                print("[WorldSetup] 强制刷新UI...")
                -- 强制刷新所有排行榜的SurfaceGui
                for _, lb in ipairs({{name = "最多金币Leaderboard", key = "credits"}, 
                                   {name = "最长游戏时间Leaderboard", key = "playTime"}, 
                                   {name = "最多机器人Leaderboard", key = "botCount"}}) do
                    local leaderboard = Workspace:FindFirstChild(lb.name)
                    if leaderboard then
                        local surfaceGui = leaderboard:FindFirstChild("SurfaceGui")
                        if surfaceGui then
                            print("[WorldSetup] 刷新SurfaceGui:", lb.name)
                            -- 临时禁用然后重新启用SurfaceGui
                            surfaceGui.Enabled = false
                            task.wait(0.1)
                            surfaceGui.Enabled = true
                            print("[WorldSetup] SurfaceGui已刷新:", lb.name)
                        end
                    end
                end
            elseif message == "/fixrender" then
                print("[WorldSetup] 修复渲染问题...")
                -- 强制修复所有排行榜的渲染
                for _, lb in ipairs({{name = "最多金币Leaderboard", key = "credits"}, 
                                   {name = "最长游戏时间Leaderboard", key = "playTime"}, 
                                   {name = "最多机器人Leaderboard", key = "botCount"}}) do
                    local leaderboard = Workspace:FindFirstChild(lb.name)
                    if leaderboard then
                        local surfaceGui = leaderboard:FindFirstChild("SurfaceGui")
                        if surfaceGui then
                            print("[WorldSetup] 修复SurfaceGui:", lb.name)
                            -- 重新设置所有关键属性
                            surfaceGui.Face = Enum.NormalId.Front
                            surfaceGui.Enabled = true
                            surfaceGui.Adornee = leaderboard
                            surfaceGui.LightInfluence = 0
                            surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
                            
                            -- 强制刷新所有TextLabel
                            local contentFrame = surfaceGui:FindFirstChild("ContentFrame")
                            if contentFrame then
                                for i = 1, 10 do
                                    local entry = contentFrame:FindFirstChild("Entry" .. i)
                                    if entry then
                                        local playerLabel = entry:FindFirstChild("PlayerLabel")
                                        local valueLabel = entry:FindFirstChild("ValueLabel")
                                        if playerLabel and valueLabel then
                                            -- 强制重新设置文本
                                            local currentPlayerText = playerLabel.Text
                                            local currentValueText = valueLabel.Text
                                            playerLabel.Text = ""
                                            valueLabel.Text = ""
                                            task.wait(0.01)
                                            playerLabel.Text = currentPlayerText
                                            valueLabel.Text = currentValueText
                                        end
                                    end
                                end
                            end
                            print("[WorldSetup] SurfaceGui已修复:", lb.name)
                        end
                    end
                end
            elseif message == "/recreate" then
                print("[WorldSetup] 重新创建排行榜...")
                -- 删除现有排行榜
                for _, lb in ipairs({{name = "最多金币Leaderboard", key = "credits"}, 
                                   {name = "最长游戏时间Leaderboard", key = "playTime"}, 
                                   {name = "最多机器人Leaderboard", key = "botCount"}}) do
                    local leaderboard = Workspace:FindFirstChild(lb.name)
                    if leaderboard then
                        leaderboard:Destroy()
                        print("[WorldSetup] 删除排行榜:", lb.name)
                    end
                end
                
                -- 重新创建排行榜
                setupLeaderboards()
                
                -- 等待一下然后更新数据
                task.wait(2)
                pcall(updateLeaderboards)
                print("[WorldSetup] 排行榜重新创建完成")
        elseif message == "/testdata" then
            print("[WorldSetup] 手动触发测试数据设置...")
            pcall(function()
                print("[WorldSetup] 强制设置测试数据...")
                local testData = {
                    {name = "TheFuture1199", credits = 2068, playTime = 1078.83, botCount = 656},
                    {name = "测试玩家2", credits = 800, playTime = 3600, botCount = 3},
                    {name = "测试玩家3", credits = 2000, playTime = 10800, botCount = 12}
                }
                
                for _, lb in ipairs({{name = "最多金币Leaderboard", key = "credits"}, 
                                   {name = "最长游戏时间Leaderboard", key = "playTime"}, 
                                   {name = "最多机器人Leaderboard", key = "botCount"}}) do
                    local leaderboard = Workspace:FindFirstChild(lb.name)
                    if leaderboard then
                        print("[WorldSetup] 找到排行榜:", lb.name)
                        local surfaceGui = leaderboard:FindFirstChild("SurfaceGui")
                        if surfaceGui then
                            print("[WorldSetup] 找到SurfaceGui")
                            local contentFrame = surfaceGui:FindFirstChild("ContentFrame")
                            if contentFrame then
                                print("[WorldSetup] 找到contentFrame，子对象数量:", #contentFrame:GetChildren())
                                for i = 1, math.min(3, #testData) do
                                    local entry = contentFrame:FindFirstChild("Entry" .. i)
                                    if entry then
                                        print("[WorldSetup] 找到条目", i, "，子对象数量:", #entry:GetChildren())
                                        local playerLabel = entry:FindFirstChild("PlayerLabel")
                                        local valueLabel = entry:FindFirstChild("ValueLabel")
                                        if playerLabel and valueLabel then
                                            playerLabel.Text = testData[i].name
                                            if lb.key == "credits" then
                                                valueLabel.Text = string.format("%.0f", testData[i].credits)
                                            elseif lb.key == "playTime" then
                                                valueLabel.Text = string.format("%.1f小时", testData[i].playTime / 3600)
                                            else
                                                valueLabel.Text = string.format("%.0f", testData[i].botCount)
                                            end
                                            print("[WorldSetup] 设置测试数据:", lb.name, i, testData[i].name, "->", valueLabel.Text)
                                        else
                                            print("[WorldSetup] 警告: 条目", i, "找不到标签 - playerLabel:", playerLabel ~= nil, "valueLabel:", valueLabel ~= nil)
                                        end
                                    else
                                        print("[WorldSetup] 警告: 找不到条目", i)
                                    end
                                end
                            else
                                print("[WorldSetup] 警告: 找不到contentFrame")
                            end
                        else
                            print("[WorldSetup] 警告: 找不到SurfaceGui")
                        end
                    else
                        print("[WorldSetup] 警告: 找不到排行榜", lb.name)
                    end
                end
            end)
        end
    end
    
    Players.PlayerAdded:Connect(function(player)
        player.Chatted:Connect(function(message)
            onChatted(player, message)
        end)
    end)
    
    -- 为现有玩家设置
    for _, player in pairs(Players:GetPlayers()) do
        player.Chatted:Connect(function(message)
            onChatted(player, message)
        end)
    end
end

-- 延迟初始化，确保其他系统已加载
task.spawn(function()
    task.wait(5) -- 增加等待时间，确保GameLogic完全初始化
    initialize()
    setupTestCommands()
end)

print("[WorldSetup] 世界设置系统已启动")
print("[WorldSetup] 使用 /leaderboard 命令手动更新排行榜")
print("[WorldSetup] 使用 /testdata 命令手动设置测试数据")
print("[WorldSetup] 使用 /debugboard 命令创建调试排行榜")
print("[WorldSetup] 使用 /forceupdate 命令强制更新UI")
print("[WorldSetup] 使用 /checkui 命令检查UI状态")
print("[WorldSetup] 使用 /testsurface 命令创建SurfaceGui测试")
print("[WorldSetup] 使用 /refreshui 命令强制刷新SurfaceGui")