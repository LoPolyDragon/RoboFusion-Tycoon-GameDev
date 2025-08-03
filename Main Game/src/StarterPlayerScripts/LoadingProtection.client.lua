--------------------------------------------------------------------
-- LoadingProtection.client.lua · 加载期间玩家保护系统
-- 功能：
--   1) 防止玩家在加载期间死亡
--   2) 冻结玩家角色直到加载完成
--   3) 确保玩家安全加载进入游戏
--------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local isLoadingComplete = false

-- 保护玩家角色
local function protectPlayer()
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    local rootPart = character:WaitForChild("HumanoidRootPart")
    
    -- 防止玩家死亡
    humanoid.Health = humanoid.MaxHealth
    humanoid.PlatformStand = true -- 防止移动
    
    -- 锚定玩家，防止掉落
    rootPart.Anchored = true
    
    -- 不隐藏角色，保持可见性（移除隐藏逻辑）
    -- 角色在加载期间保持可见，只锁定位置
    
    print("[LoadingProtection] 玩家已被保护，防止加载期间死亡")
end

-- 解除玩家保护
local function unprotectPlayer()
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if humanoid then
        humanoid.PlatformStand = false
    end
    
    if rootPart then
        rootPart.Anchored = false
    end
    
    -- 角色已经可见，无需恢复透明度
    
    print("[LoadingProtection] 玩家保护已解除")
end

-- 监听角色重生
player.CharacterAdded:Connect(function(character)
    if not isLoadingComplete then
        task.wait(0.1) -- 等待角色完全加载
        protectPlayer()
    end
end)

-- 监听加载完成
local loadingCompleteEvent = ReplicatedStorage.RemoteEvents:WaitForChild("LoadingCompleteEvent")
loadingCompleteEvent.OnClientEvent:Connect(function()
    isLoadingComplete = true
    unprotectPlayer()
end)

-- 如果角色已经存在，立即保护
if player.Character then
    protectPlayer()
end

print("[LoadingProtection] 加载保护系统已启动")