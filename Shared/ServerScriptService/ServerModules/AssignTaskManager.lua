----------------------------------------------------------------
-- ServerModules/AssignTaskManager.lua
----------------------------------------------------------------
local RTS = require(script.Parent.RobotTaskService)

local function clone(t)
	local c = {}
	for k, v in pairs(t) do
		c[k] = v
	end
	return c
end

local M = {}

function M.HandlePayload(plr, data)
	if typeof(plr) ~= "Instance" or not plr:IsA("Player") then
		return
	end
	if type(data) ~= "table" then
		return
	end

	local ok = type(data.botId) == "string" and type(data.oreName) == "string" and type(data.pickaxe) == "string"

	if not ok then
		return
	end

	data.quantity = math.clamp(tonumber(data.quantity) or 1, 1, 999)

	RTS.StartMineTask(plr, clone(data))
end

return M
