--------------------------------------------------------------------
-- StarterPlayerScripts / MineTeleportClient  ★客户端
--------------------------------------------------------------------
local Players       = game:GetService("Players")
local RS            = game:GetService("ReplicatedStorage")
local TeleportEvent = RS.RemoteEvents:WaitForChild("TeleportToMineEvent")

local player   = Players.LocalPlayer
local char     = player.Character or player.CharacterAdded:Wait()
local Run      = game:GetService("RunService")

-- 教程系统集成
local tutorialEvent = RS.RemoteEvents:FindFirstChild("TutorialEvent")

----------------------------------------------------------------
-- 方式 A ："触碰即传送"——监听 MinePortal 的 Touched（简单）
----------------------------------------------------------------
-- 安全检查 MinePortal 是否存在
local minePortal = workspace:FindFirstChild("MinePortal")
if minePortal then
	local portalPart = minePortal:FindFirstChild("Teleport")
	
	if portalPart then
		portalPart.Touched:Connect(function(hit)
			-- 只响应自己的 HumanoidRootPart，避免小部件误触
			if hit ~= (char:FindFirstChild("HumanoidRootPart")) then return end
			
			-- 通知教程系统传送完成
			if tutorialEvent then
				tutorialEvent:FireServer("STEP_COMPLETED", "ENTER_MINE", {
					destination = "MINE"
				})
			end
			
			TeleportEvent:FireServer()        -- 无参数，交给服务器判定
		end)
		print("[MineTeleportClient] MinePortal 传送系统已启动")
	else
		warn("[MineTeleportClient] MinePortal 存在但找不到 Teleport 部件")
	end
else
	warn("[MineTeleportClient] 找不到 MinePortal，传送系统未启动")
end

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