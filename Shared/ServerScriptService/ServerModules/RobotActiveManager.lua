--------------------------------------------------------------------
-- RobotActiveManager  · 激活/取消 + 跟随
--------------------------------------------------------------------
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")

local EVT = RS.RemoteEvents:WaitForChild("RobotToggleEvent")
local TPL = SS:WaitForChild("RobotTemplates") -- 模板：UncommonBot 等

--------------------------------------------------------------------
-- 碰撞组：Bots 不撞 Bots/Players
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
-- 运行时缓存
--------------------------------------------------------------------
local Active = {} -- Active[player] = { {id,model,slot}, … }

--------------------------------------------------------------------
-- 跟随逻辑
--------------------------------------------------------------------
local POS_OFF = {
	Vector3.new(0, 0, 6),
	Vector3.new(-4, 0, 6),
	Vector3.new(4, 0, 6),
	Vector3.new(-6, 0, 8),
	Vector3.new(6, 0, 8),
}
local function targetPos(root, slot)
	local rel = POS_OFF[slot] or POS_OFF[1]
	return root.Position + root.CFrame:VectorToWorldSpace(rel)
end

local function follow(plr, bot, slot)
	-- 跟随标记，任务派发时由 RobotTaskService 销毁
	local flag = Instance.new("BoolValue", bot)
	flag.Name = "__Follow"

	local hum = bot:WaitForChild("Humanoid")
	local root = bot:WaitForChild("HumanoidRootPart")
	RunService.Heartbeat:Connect(function()
		if not flag.Parent then
			return
		end -- 任务派发后退出
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
-- 生成 / 移除
--------------------------------------------------------------------
local RARITY_TPL =
	{ Uncommon = "UncommonBot", Rare = "RareBot", Epic = "EpicBot", Secret = "SecretBot", Eco = "EcoBot" }
local function templateFor(botId)
	local _, r = botId:match("^[%w]+_(%w+)Bot$")
	return RARITY_TPL[r] or "UncommonBot"
end

local function spawn(plr, botId)
	Active[plr] = Active[plr] or {}
	if #Active[plr] >= 5 then
		return
	end
	local tpl = TPL:FindFirstChild(templateFor(botId))
	if not tpl then
		warn("缺模板", botId)
		return
	end

	local model = tpl:Clone()
	applyBotGroup(model)
	model:SetAttribute("BotId", botId)

	local slot = #Active[plr] + 1
	local chrR = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	if chrR then
		model:PivotTo(CFrame.new(targetPos(chrR, slot)))
	end
	model.Parent = workspace

	table.insert(Active[plr], { id = botId, model = model, slot = slot })
	follow(plr, model, slot)
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
	-- 重新排位
	local chrR = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	for idx, rec in ipairs(list) do
		rec.slot = idx
		if rec.model and rec.model.Parent and chrR then
			rec.model:PivotTo(CFrame.new(targetPos(chrR, idx)))
		end
	end
end

--------------------------------------------------------------------
-- 客户端事件
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

Players.PlayerRemoving:Connect(function(plr)
	for _, rec in ipairs(Active[plr] or {}) do
		if rec.model and rec.model.Parent then
			rec.model:Destroy()
		end
	end
	Active[plr] = nil
end)

--------------------------------------------------------------------
-- 对外接口
--------------------------------------------------------------------
local M = {}
function M.GetActiveList(plr)
	return Active[plr] or {}
end
return M
