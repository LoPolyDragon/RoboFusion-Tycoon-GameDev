--------------------------------------------------------------------
-- RobotActiveManager  · 激活/取消 + 跟随
--------------------------------------------------------------------
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")

local EVT = RS:FindFirstChild("RobotToggleEvent") or Instance.new("RemoteEvent", RS)
EVT.Name = "RobotToggleEvent"
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
	
	-- 检查是否已经存在相同的机器人
	for _, rec in ipairs(Active[plr]) do
		if rec.id == botId then
			print("[RobotActiveManager] 机器人已存在:", botId)
			return
		end
	end
	
	local tpl = TPL:FindFirstChild(templateFor(botId))
	if not tpl then
		warn("缺模板", botId)
		return
	end

	local model = tpl:Clone()
	applyBotGroup(model)
	model:SetAttribute("BotId", botId)
	model:SetAttribute("Owner", plr.UserId)

	local slot = #Active[plr] + 1
	local chrR = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	if chrR then
		model:PivotTo(CFrame.new(targetPos(chrR, slot)))
	end
	model.Parent = workspace

	table.insert(Active[plr], { id = botId, model = model, slot = slot })
	follow(plr, model, slot)
	print("[RobotActiveManager] 机器人已激活:", botId, "槽位:", slot)
end

local function remove(plr, botId)
	local list = Active[plr]
	if not list then
		print("[RobotActiveManager] 玩家无激活机器人列表:", plr.Name)
		return
	end
	
	local found = false
	for i, rec in ipairs(list) do
		if rec.id == botId then
			print("[RobotActiveManager] 移除机器人:", botId, "玩家:", plr.Name)
			if rec.model and rec.model.Parent then
				rec.model:Destroy()
				print("[RobotActiveManager] 机器人模型已销毁")
			end
			table.remove(list, i)
			found = true
			break
		end
	end
	
	if not found then
		print("[RobotActiveManager] 未找到要移除的机器人:", botId)
	end
	
	-- 重新排位
	local chrR = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	for idx, rec in ipairs(list) do
		rec.slot = idx
		if rec.model and rec.model.Parent and chrR then
			rec.model:PivotTo(CFrame.new(targetPos(chrR, idx)))
		end
	end
	
	print("[RobotActiveManager] 当前激活机器人数量:", #list)
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

-- 直接移除机器人（供其他系统调用）
function M.RemoveRobot(plr, botId)
	print("[RobotActiveManager] API调用移除机器人:", botId, "玩家:", plr.Name)
	remove(plr, botId)
end

-- 直接激活机器人（供其他系统调用）
function M.SpawnRobot(plr, botId)
	print("[RobotActiveManager] API调用激活机器人:", botId, "玩家:", plr.Name)
	spawn(plr, botId)
end

-- 检查机器人是否已激活
function M.IsRobotActive(plr, botId)
	local list = Active[plr] or {}
	for _, rec in ipairs(list) do
		if rec.id == botId then
			return true, rec
		end
	end
	return false, nil
end

return M
