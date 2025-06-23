--------------------------------------------------------------------
-- StarterPlayerScripts / MineTeleportClient  ★客户端
--------------------------------------------------------------------
local Players       = game:GetService("Players")
local RS            = game:GetService("ReplicatedStorage")
local TeleportEvent = RS.RemoteEvents:WaitForChild("TeleportToMineEvent")

local player   = Players.LocalPlayer
local char     = player.Character or player.CharacterAdded:Wait()
local Run      = game:GetService("RunService")

----------------------------------------------------------------
-- 方式 A ：“触碰即传送”——监听 MinePortal 的 Touched（简单）
----------------------------------------------------------------
local portalPart = workspace:WaitForChild("MinePortal"):WaitForChild("Teleport")

portalPart.Touched:Connect(function(hit)
	-- 只响应自己的 HumanoidRootPart，避免小部件误触
	if hit ~= (char:FindFirstChild("HumanoidRootPart")) then return end
	TeleportEvent:FireServer()        -- 无参数，交给服务器判定
end)

----------------------------------------------------------------
-- 方式 B ：ProximityPrompt（推荐 UX 更好，自动防连点）
-- ① 在 MinePortal Part 里插入 ProximityPrompt ，设 ActionText = "Enter Mine"
-- ② 把下面代码取消注释即可
----------------------------------------------------------------
--[[
local prompt = portalPart:WaitForChild("ProximityPrompt")
prompt.Triggered:Connect(function(plr)
    if plr == player then
        TeleportEvent:FireServer()
    end
end)
]]