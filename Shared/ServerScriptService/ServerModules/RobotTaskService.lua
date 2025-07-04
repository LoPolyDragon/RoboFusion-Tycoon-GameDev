----------------------------------------------------------------
-- ServerModules/RobotTaskService.lua · 单只机器人挖矿任务
----------------------------------------------------------------
local RS = game:GetService("ReplicatedStorage")
local PathSvc = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

-- ↓ 若不存在自动创建，避免 MineWorld 报 Infinite yield
local EVT_STATE = RS:FindFirstChild("RemoteEvents") and RS.RemoteEvents:FindFirstChild("RobotMissionStatus")
if not EVT_STATE then
	local reFolder = RS:FindFirstChild("RemoteEvents") or Instance.new("Folder", RS)
	reFolder.Name = "RemoteEvents"
	EVT_STATE = Instance.new("RemoteEvent", reFolder)
	EVT_STATE.Name = "RobotMissionStatus"
end

local Const = require(RS.SharedModules.GameConstants)
local GL = require(script.Parent.GameLogicServer)
local ActiveMgr = require(script.Parent.RobotActiveManager)

local TASK_POOL = ServerStorage:FindFirstChild("Tasks") or Instance.new("Folder", ServerStorage)
TASK_POOL.Name = "Tasks"

----------------------------------------------------------------
-- 内部工具
----------------------------------------------------------------
local function getMineTime(botId, pickId, oreName)
	local o = Const.ORE_INFO[oreName] or {}
	local b = (Const.BotStats or {})[botId] or {}
	local p = (Const.PICKAXE_INFO or {})[pickId] or {}
	if o.hardness and p.maxHardness and o.hardness > p.maxHardness then
		return nil
	end
	return math.max(0.4, (o.time or 2) * (p.speedMul or 1) / (b.interval or 2))
end

local function mineRoutine(plr, bot, ore, pick, qty)
	local hum = bot:WaitForChild("Humanoid")
	local root = bot:WaitForChild("HumanoidRootPart")
	local botId = bot:GetAttribute("BotId") or "UncommonBot"

	for _ = 1, qty do
		if not plr.Parent or not bot.Parent then
			break
		end
		local oreBlk = bot.Parent:FindFirstChild("OreFolder") and bot.Parent.OreFolder:FindFirstChild(ore)
		if not oreBlk then
			task.wait(1)
			continue
		end

		local path = PathSvc:CreatePath({ AgentRadius = 2 })
		local ok = pcall(path.ComputeAsync, path, root.Position, oreBlk.Position)
		if not ok or path.Status ~= Enum.PathStatus.Success then
			task.wait(1)
			continue
		end
		for _, wp in ipairs(path:GetWaypoints()) do
			hum:MoveTo(wp.Position)
			hum.MoveToFinished:Wait()
		end

		local dt = getMineTime(botId, pick, ore)
		if not dt then
			return
		end
		task.wait(dt)

		GL.AddItem(plr, ore, 1)
		if oreBlk.Parent then
			oreBlk:Destroy()
		end
	end

	EVT_STATE:FireClient(plr, botId, false) -- 熄灯
end

----------------------------------------------------------------
-- 运行时缓存
----------------------------------------------------------------
local MissionList = {} -- [player] = {[botId]={model,ore,pick,qty}}

----------------------------------------------------------------
-- 对外接口
----------------------------------------------------------------
local RTS = {}

local function playerHasPick(plr, pickId, needQty)
	local inv = GL.GetInventoryDict(plr)
	return (inv[pickId] or 0) >= (needQty or 1)
end

function RTS.StartMineTask(plr, data)
	--------------------------------------------------
	-- 新增合法性：库存里得有 pickaxe ≥ quantity
	--------------------------------------------------
	if not playerHasPick(plr, data.pickaxe, 1) then
		-- 同用 RobotMissionStatus 给前端回报失败原因
		EVT_STATE:FireClient(plr, data.botId, false, "缺少镐子 (" .. data.pickaxe .. ")")
		return
	end

	local ore, pick, qty = data.oreName, data.pickaxe, math.clamp(data.quantity, 1, 999)
	if not (Const.ORE_INFO[ore] and Const.PICKAXE_INFO[pick]) then
		EVT_STATE:FireClient(plr, data.botId, false)
		return
	end

	-- 只处理本次 botId
	for _, rec in ipairs(ActiveMgr.GetActiveList(plr)) do
		if rec.id == data.botId then
			local bot = rec.model

			if bot:FindFirstChild("__Follow") then
				bot.__Follow:Destroy()
			end
			bot.Parent = TASK_POOL

			MissionList[plr] = MissionList[plr] or {}
			MissionList[plr][rec.id] = { model = bot, ore = ore, pick = pick, qty = qty }

			EVT_STATE:FireClient(plr, rec.id, true) -- 亮灯
			break
		end
	end
end

function RTS.LoadMissionsForPlayer(plr, worldFolder)
	local list = MissionList[plr]
	if not list then
		return
	end
	for id, info in pairs(list) do
		local bot = info.model
		bot.Parent = worldFolder
		if bot:FindFirstChild("__Routine") then
			bot.__Routine:Destroy()
		end
		Instance.new("BoolValue", bot).Name = "__Routine"
		task.spawn(mineRoutine, plr, bot, info.ore, info.pick, info.qty)
	end
end

Players.PlayerRemoving:Connect(function(plr)
	MissionList[plr] = nil
end)

return RTS
