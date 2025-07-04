----------------------------------------------------------------
-- ServerScriptService/AssignTaskManager.server.lua
----------------------------------------------------------------
local RS = game:GetService("ReplicatedStorage")

----------------------------------------------------------------
-- RemoteEvent：若不存在则自动创建
----------------------------------------------------------------
local EVT = RS:FindFirstChild("AssignMineTaskEvent")
if not EVT then
	EVT = Instance.new("RemoteEvent")
	EVT.Name = "AssignMineTaskEvent"
	EVT.Parent = RS
end

----------------------------------------------------------------
-- 依赖：RobotTaskService（负责真正派协程）
----------------------------------------------------------------
local RobotTaskService = require(script.Parent:WaitForChild("ServerModules").RobotTaskService)

----------------------------------------------------------------
-- 缓存：Tasks[player][botId] = { oreName=…, pickaxe=…, quantity=… }
----------------------------------------------------------------
local Tasks = {}

----------------------------------------------------------------
-- 小工具：安全复制（防止客户端 table 被后改动）
----------------------------------------------------------------
local function clone(t)
	local c = {}
	for k, v in pairs(t) do
		c[k] = v
	end
	return c
end

----------------------------------------------------------------
-- 收包 & 分发
----------------------------------------------------------------
EVT.OnServerEvent:Connect(function(plr, data)
	------------------------------------------------------------
	-- ① 基础校验
	------------------------------------------------------------
	if type(data) ~= "table" then
		warn("[AssignManager] Bad payload (not table) from", plr)
		return
	end
	local botId = data.botId
	local oreName = data.oreName
	local pickaxe = data.pickaxe
	local quantity = tonumber(data.quantity) or 1

	if type(botId) ~= "string" or type(oreName) ~= "string" or type(pickaxe) ~= "string" then
		warn("[AssignManager] Missing fields from", plr)
		return
	end
	quantity = math.clamp(quantity, 1, 999)

	------------------------------------------------------------
	-- ② 记录任务
	------------------------------------------------------------
	Tasks[plr] = Tasks[plr] or {}
	Tasks[plr][botId] = { oreName = oreName, pickaxe = pickaxe, quantity = quantity }
	print(string.format("[TASK] %s  %s → %s ×%d  (%s)", plr.Name, botId, oreName, quantity, pickaxe))

	------------------------------------------------------------
	-- ③ 立即执行（如只想缓存可注释掉）
	------------------------------------------------------------
	RobotTaskService.StartMineTask(plr, clone(data))
end)

----------------------------------------------------------------
-- 清理：玩家离开时移除缓存
----------------------------------------------------------------
game.Players.PlayerRemoving:Connect(function(plr)
	Tasks[plr] = nil
end)

----------------------------------------------------------------
-- （可选）对外查询接口
----------------------------------------------------------------
local AssignTaskManager = {}

function AssignTaskManager.GetTask(plr, botId)
	return Tasks[plr] and Tasks[plr][botId]
end

return AssignTaskManager
