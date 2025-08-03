local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local PathService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")

-- ★ 如果 ReplicatedStorage 里没有这个 Event 就创建一个
local SPAWN_EVT = RS:FindFirstChild("SpawnMiningBotEvent") or Instance.new("RemoteEvent", RS)
SPAWN_EVT.Name = "SpawnMiningBotEvent"

-- ★ 你的 5 个模型：
local BOT_MODEL = {
	[1] = ServerStorage.RobotTemplates.UncommonBot,  -- Uncommon Bot
	[2] = ServerStorage.RobotTemplates.RareBot,      -- Rare Bot  
	[3] = ServerStorage.RobotTemplates.EpicBot,      -- Epic Bot
	[4] = ServerStorage.RobotTemplates.SecretBot,    -- Secret Bot
	[5] = ServerStorage.RobotTemplates.EcoBot,       -- Eco Bot
}

local Active = {}

local function spawn(player, lvl)
	if Active[player] and Active[player].Parent then
		Active[player]:Destroy()
	end
	local src = BOT_MODEL[lvl] or BOT_MODEL[1]
	if not src then
		warn("No bot model level", lvl)
		return
	end
	if not player.Character or not player.Character.PrimaryPart then
		return
	end

	local bot = src:Clone()
	bot:SetPrimaryPartCFrame(player.Character.PrimaryPart.CFrame * CFrame.new(2, 0, 2))
	bot.Parent = workspace
	Active[player] = bot
end

SPAWN_EVT.OnServerEvent:Connect(spawn)
