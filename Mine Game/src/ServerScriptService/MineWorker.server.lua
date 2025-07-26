--------------------------------------------------------------------
-- MineWorker · 监听场景内所有机器人，主动找矿 & 开采
--------------------------------------------------------------------
local RS = game:GetService("ReplicatedStorage")
local Path = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")

local ORE_INFO = require(RS.SharedModules.GameConstants).ORE_INFO

----------------------------------------------------------------
-- 给整张矿区加 tag “Ore” 方便查找；这里假设已经完成
----------------------------------------------------------------
local function nearestOre(bot, oreName)
	local best, dist
	for _, ore in ipairs(workspace.OreFolder:GetChildren()) do
		if ore.Name == oreName then
			local d = (bot.PrimaryPart.Position - ore.Position).Magnitude
			if not dist or d < dist then
				best, dist = ore, d
			end
		end
	end
	return best
end

----------------------------------------------------------------
-- 主循环：给每个 Mining 状态的机器人分配目标
----------------------------------------------------------------
RunService.Heartbeat:Connect(function()
	for _, bot in ipairs(workspace:GetChildren()) do
		if bot:IsA("Model") and bot:GetAttribute("State") == "Mining" then
			local oreName = bot:GetAttribute("TaskOre")
			if not oreName then
				bot:SetAttribute("State", "Return")
				return
			end

			local goal = nearestOre(bot, oreName)
			if not goal then
				bot:SetAttribute("State", "Return")
				return
			end

			----------------------------------------------------------------
			-- 路径 & 开采
			local hum = bot.Humanoid
			local pth = Path:CreatePath({ AgentRadius = 2, AgentCanJump = true })
			pcall(function()
				pth:ComputeAsync(bot.PrimaryPart.Position, goal.Position)
			end)
			if pth.Status ~= Enum.PathStatus.Success then
				return
			end

			for _, wp in ipairs(pth:GetWaypoints()) do
				hum:MoveTo(wp.Position)
				hum.MoveToFinished:Wait()
			end

			-- 简化：直接破坏方块 + 更新计数
			local left = bot:GetAttribute("TaskLeft") - 1
			bot:SetAttribute("TaskLeft", left)
			goal:Destroy()

			if left <= 0 then
				-- 任务完成 → 传送回玩家身边
				local ownerId = bot:GetAttribute("Owner")
				local plr = game.Players:GetPlayerByUserId(ownerId)
				if plr and plr.Character and plr.Character.PrimaryPart then
					bot:PivotTo(plr.Character.PrimaryPart.CFrame * CFrame.new(2, 0, 2))
					bot:SetAttribute("State", "Return")
				end
			end
		end
	end
end)
