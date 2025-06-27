-- ServerScriptService/AssignTaskManager.lua
local RS = game:GetService("ReplicatedStorage")
local EVT = RS:FindFirstChild("AssignMineTaskEvent") or Instance.new("RemoteEvent", RS)
EVT.Name = "AssignMineTaskEvent"

-- Tasks[player][botId] = { ores = {...}, tool = "IronPick" }
local Tasks = {}

EVT.OnServerEvent:Connect(function(plr, data)
	Tasks[plr] = Tasks[plr] or {}
	Tasks[plr][data.botId] = { ores = data.ores, tool = data.tool }
	print("[TASK]", plr.Name, data.botId, data.ores, data.tool)
end)
