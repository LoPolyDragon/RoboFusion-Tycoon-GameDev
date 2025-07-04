----------------------------------------------------------------
-- ServerScriptService/AssignTaskManager.server.lua
----------------------------------------------------------------
local RS = game:GetService("ReplicatedStorage")
local EVT = RS.RemoteEvents:WaitForChild("AssignTaskEvent")

local Mod = require(script.Parent.ServerModules.AssignTaskManager)

EVT.OnServerEvent:Connect(function(plr, payload)
	Mod.HandlePayload(plr, payload)
end)
