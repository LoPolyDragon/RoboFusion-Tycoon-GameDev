--------------------------------------------------------------------
-- RobotActiveManager · 单玩家最多 5 只 · 5 种等级模型
-- 模型目录：ServerStorage/RobotTemplates
--   UncommonBot  RareBot  EpicBot  SecretBot  EcoBot
--------------------------------------------------------------------
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")

local EVT = RS.RemoteEvents:WaitForChild("RobotToggleEvent")
local TPL = SS:WaitForChild("RobotTemplates") -- 仅需上面 5 个模型

--------------------------------------------------------------------
-- ① 碰撞组：Bots 不撞 Bots / Players，仍撞 Default（地形）
--------------------------------------------------------------------
pcall(function()
	PhysicsService:RegisterCollisionGroup("Bots")
end)
pcall(function()
	PhysicsService:RegisterCollisionGroup("Players")
end)
PhysicsService:CollisionGroupSetCollidable("Bots", "Bots", false)
PhysicsService:CollisionGroupSetCollidable("Bots", "Players", false)

local function applyBotGroup(model)
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.CollisionGroup = "Bots"
		end
	end
end

--------------------------------------------------------------------
-- ② 运行时表
--------------------------------------------------------------------
local Active = {} -- Active[player] = { {id,model,slot}, … }

--------------------------------------------------------------------
-- ③ 位置队形（两排，离玩家 4~6 stud，宽一点不挡视野）
--------------------------------------------------------------------
local POS_OFF = {
	Vector3.new(0, 0, 6),
	Vector3.new(-4, 0, 6),
	Vector3.new(4, 0, 6),
	Vector3.new(-6, 0, 8),
	Vector3.new(6, 0, 8),
}

local function targetPos(charRoot, slot)
	local rel = POS_OFF[slot] or POS_OFF[1]
	return charRoot.Position + charRoot.CFrame:VectorToWorldSpace(rel)
end

local function follow(plr, bot, slot)
	local hum = bot:WaitForChild("Humanoid")
	local root = bot:WaitForChild("HumanoidRootPart")
	RunService.Heartbeat:Connect(function(dt)
		local chr = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
		if not chr or not bot.Parent then
			return
		end
		local goal = targetPos(chr, slot)
		if (root.Position - goal).Magnitude > 1.5 then
			hum:MoveTo(goal)
		end
	end)
end

--------------------------------------------------------------------
-- ④ 生成 / 移除
--------------------------------------------------------------------
local RARITY_TO_TEMPLATE =
	{ Uncommon = "UncommonBot", Rare = "RareBot", Epic = "EpicBot", Secret = "SecretBot", Eco = "EcoBot" }

local function templateFor(botId)
	local _, r = botId:match("^[%w]+_(%w+)Bot$")
	return RARITY_TO_TEMPLATE[r] or "UncommonBot"
end

local function spawn(plr, botId)
	Active[plr] = Active[plr] or {}
	if #Active[plr] >= 5 then
		return
	end

	local tplName = templateFor(botId)
	local template = TPL:FindFirstChild(tplName)
	if not template then
		warn("模板缺失:", tplName)
		return
	end

	local model = template:Clone()
	applyBotGroup(model)

	local slot = #Active[plr] + 1
	local chrRoot = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	if chrRoot then
		model:PivotTo(CFrame.new(targetPos(chrRoot, slot)))
	end
	model.Parent = workspace

	follow(plr, model, slot)
	table.insert(Active[plr], { id = botId, model = model, slot = slot })
end

local function remove(plr, botId)
	local list = Active[plr]
	if not list then
		return
	end
	for i, rec in ipairs(list) do
		if rec.id == botId then
			if rec.model and rec.model.Parent then
				rec.model:Destroy()
			end
			table.remove(list, i)
			break
		end
	end
	-- 重新编号 & 排队
	local chrRoot = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	for idx, rec in ipairs(list) do
		rec.slot = idx
		if rec.model and rec.model.Parent and chrRoot then
			rec.model:PivotTo(CFrame.new(targetPos(chrRoot, idx)))
		end
	end
end

--------------------------------------------------------------------
-- ⑤ 客户端事件
--------------------------------------------------------------------
EVT.OnServerEvent:Connect(function(plr, botId, on)
	if type(botId) ~= "string" then
		return
	end
	if on then
		spawn(plr, botId)
	else
		remove(plr, botId)
	end
end)

--------------------------------------------------------------------
-- ⑥ 玩家离开时清理
--------------------------------------------------------------------
Players.PlayerRemoving:Connect(function(plr)
	for _, rec in ipairs(Active[plr] or {}) do
		if rec.model and rec.model.Parent then
			rec.model:Destroy()
		end
	end
	Active[plr] = nil
end)
