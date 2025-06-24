local RS = game:GetService("ReplicatedStorage")
local GameLogic = require(script.Parent.ServerModules.GameLogicServer)
local Const = require(RS.SharedModules.GameConstants)

local EVT = RS.RemoteEvents:WaitForChild("AssembleRequestEvent")

EVT.OnServerEvent:Connect(function(plr, payload)
	if typeof(payload) ~= "table" then
		return
	end
	local shellId, target = payload.shellId, payload.target
	local rarity = Const.ShellRarity[shellId]
	local map = Const.RobotKey[target or "Dig"]
	local botId = map and map[rarity]
	if not rarity or not botId then
		EVT:FireClient(plr, false, "invalid")
		return
	end
	if not GameLogic.RemoveItem(plr, shellId, 1) then
		EVT:FireClient(plr, false, "no shell")
		return
	end
	GameLogic.AddItem(plr, botId, 1)
	EVT:FireClient(plr, true)
end)
