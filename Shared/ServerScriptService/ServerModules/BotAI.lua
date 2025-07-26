--------------------------------------------------------------------
-- BotAI · 纯服务器逻辑（不信任客户端）
--------------------------------------------------------------------
local PathService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")

local BotAI = {}

function BotAI.init(bot, owner)
	----------------------------------------------------------------
	-- 属性
	bot:SetAttribute("Owner", owner.UserId)
	bot:SetAttribute("State", "Follow") -- 或 Mining / Return

	----------------------------------------------------------------
	-- 内部运行时
	local hum = bot:WaitForChild("Humanoid")
	local root = bot.PrimaryPart
	local nextHop = nil

	----------------------------------------------------------------
	-- ··· 每 0.3 s 重算跟随路径
	----------------------------------------------------------------
	local lastPath = 0
	RunService.Heartbeat:Connect(function(dt)
		local state = bot:GetAttribute("State")

		if state == "Follow" then
			if not owner.Character or not owner.Character.PrimaryPart then
				return
			end
			local targetPos = owner.Character.PrimaryPart.Position + Vector3.new(2, 0, 2)
			if (root.Position - targetPos).Magnitude < 4 then
				return
			end
			if tick() - lastPath < 0.3 then
				return
			end

			lastPath = tick()
			local path = PathService:CreatePath({ AgentRadius = 2, AgentCanJump = true })
			if
				pcall(function()
					path:ComputeAsync(root.Position, targetPos)
				end) and path.Status == Enum.PathStatus.Success
			then
				local way = path:GetWaypoints()
				local i = 1
				hum:MoveTo(way[1].Position)

				hum.MoveToFinished:Connect(function()
					i += 1
					if way[i] then
						hum:MoveTo(way[i].Position)
					end
				end)
			end
		elseif state == "Mining" then
			-- 在 MineWorld 由 MineWorker.lua 接管，这里 idle
		elseif state == "Return" then
			-- 回到主世界后立即切回 Follow
			bot:SetAttribute("State", "Follow")
		end
	end)
end

return BotAI
