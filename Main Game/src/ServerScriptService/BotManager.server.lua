-- ServerScriptService/BotManager.server.lua
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local PathService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")

---------------------------------------------------------------
-- ① RemoteEvents
---------------------------------------------------------------
local EVT = RS:FindFirstChild("RobotToggleEvent") or Instance.new("RemoteEvent", RS)
EVT.Name = "RobotToggleEvent" -- 客户端发 {botLevel = 3, on = true/false}

---------------------------------------------------------------
-- ② Bot 模板（5 个等级）
---------------------------------------------------------------
local BOT_TEMPLATE = {
	[1] = ServerStorage.RobotTemplates.UncommonBot,  -- Uncommon Bot
	[2] = ServerStorage.RobotTemplates.RareBot,      -- Rare Bot  
	[3] = ServerStorage.RobotTemplates.EpicBot,      -- Epic Bot
	[4] = ServerStorage.RobotTemplates.SecretBot,    -- Secret Bot
	[5] = ServerStorage.RobotTemplates.EcoBot,       -- Eco Bot
}

---------------------------------------------------------------
-- ③ 内存表：Active[player] = { [level]=botModel, … }
---------------------------------------------------------------
local Active = {}

---------------------------------------------------------------
-- ④ 跟随逻辑（复用一个函数给所有 bot）
---------------------------------------------------------------
local function attachFollowAI(bot, player)
	local hum = bot:WaitForChild("Humanoid")
	local root = bot.PrimaryPart
	local replan = 0
	RunService.Heartbeat:Connect(function(dt)
		if not root.Parent then
			return
		end
		if not player.Character or not player.Character.PrimaryPart then
			return
		end
		replan -= dt
		if replan > 0 then
			return
		end
		replan = 0.25

		local dist = (root.Position - player.Character.PrimaryPart.Position).Magnitude
		if dist < 4 then
			return
		end
		pcall(function()
			hum:MoveTo(player.Character.PrimaryPart.Position + Vector3.new(2, 0, 2))
		end)
	end)
end

---------------------------------------------------------------
-- ⑤ 开 / 关 指定等级 bot
---------------------------------------------------------------
local function toggleBot(player, level, on)
	Active[player] = Active[player] or {}

	if on then
		-- 开：不存在才生成
		if Active[player][level] and Active[player][level].Parent then
			return
		end
		local src = BOT_TEMPLATE[level]
		if not src then
			return
		end
		local char = player.Character or player.CharacterAdded:Wait()
		if not char.PrimaryPart then
			return
		end

		local bot = src:Clone()
		bot:SetPrimaryPartCFrame(char.PrimaryPart.CFrame * CFrame.new(2, 0, 2))
		bot.Parent = workspace
		Active[player][level] = bot
		attachFollowAI(bot, player)
	else
		-- 关：销毁并移除表
		if Active[player][level] and Active[player][level].Parent then
			Active[player][level]:Destroy()
		end
		Active[player][level] = nil
	end
end

EVT.OnServerEvent:Connect(toggleBot)

Players.PlayerRemoving:Connect(function(plr)
	if Active[plr] then
		for _, bot in pairs(Active[plr]) do
			if bot and bot.Parent then
				bot:Destroy()
			end
		end
		Active[plr] = nil
	end
end)
