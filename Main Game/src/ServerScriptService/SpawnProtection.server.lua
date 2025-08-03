--------------------------------------------------------------------
-- SpawnProtection.server.lua · 玩家出生保护系统
-- 功能：
--   1) 确保玩家在安全位置出生
--   2) 防止玩家在加载期间死亡
--   3) 设置合适的出生点
--------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 设置安全的出生点
local function setupSafeSpawnPoint()
    -- 查找或创建出生点
    local spawnLocation = workspace:FindFirstChild("SpawnLocation")
    if not spawnLocation then
        spawnLocation = Instance.new("SpawnLocation")
        spawnLocation.Name = "SpawnLocation"
        spawnLocation.Size = Vector3.new(10, 1, 10)
        spawnLocation.Position = Vector3.new(0, 5, 0) -- 在空中但不太高，安全位置
        spawnLocation.Material = Enum.Material.Neon
        spawnLocation.BrickColor = BrickColor.new("Bright green")
        spawnLocation.Anchored = true
        spawnLocation.CanCollide = true
        spawnLocation.Parent = workspace
        
        print("[SpawnProtection] 创建安全出生点")
    else
        -- 确保现有出生点在安全位置
        spawnLocation.Position = Vector3.new(0, 5, 0)
        spawnLocation.Anchored = true
        spawnLocation.CanCollide = true
        
        print("[SpawnProtection] 调整现有出生点到安全位置")
    end
    
    return spawnLocation
end

-- 保护新加入的玩家
local function protectNewPlayer(player)
    player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid")
        local rootPart = character:WaitForChild("HumanoidRootPart")
        
        -- 等待角色完全加载
        task.wait(0.5)
        
        -- 确保玩家在安全位置但可见
        rootPart.CFrame = CFrame.new(0, 8, 0)
        
        -- 暂时防止玩家移动，直到加载完成
        rootPart.Anchored = true
        humanoid.PlatformStand = true
        
        -- 确保角色完全可见
        for _, part in pairs(character:GetChildren()) do
            if part:IsA("BasePart") then
                part.Transparency = 0
            elseif part:IsA("Accessory") then
                local handle = part:FindFirstChild("Handle")
                if handle then
                    handle.Transparency = 0
                end
            end
        end
        
        -- 确保玩家不会死亡
        humanoid.Health = humanoid.MaxHealth
        
        print("[SpawnProtection] 玩家", player.Name, "已被保护在安全位置")
        
        -- 监听加载完成事件
        local loadingCompleteEvent = ReplicatedStorage.RemoteEvents:FindFirstChild("LoadingCompleteEvent")
        if loadingCompleteEvent then
            local connection
            connection = loadingCompleteEvent.OnServerEvent:Connect(function(clientPlayer)
                if clientPlayer == player then
                    -- 解除保护
                    if rootPart.Parent then
                        rootPart.Anchored = false
                    end
                    if humanoid.Parent then
                        humanoid.PlatformStand = false
                    end
                    
                    print("[SpawnProtection] 玩家", player.Name, "保护已解除")
                    connection:Disconnect()
                end
            end)
        end
    end)
end

-- 初始化出生保护系统
setupSafeSpawnPoint()

-- 监听玩家加入
Players.PlayerAdded:Connect(protectNewPlayer)

-- 对于已经在游戏中的玩家
for _, player in pairs(Players:GetPlayers()) do
    protectNewPlayer(player)
end

print("[SpawnProtection] 出生保护系统已启动")