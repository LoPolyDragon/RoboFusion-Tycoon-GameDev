local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local RE = RS:WaitForChild("RemoteEvents") -- 必须等得到

local EVT = RE:WaitForChild("SpawnMiningBotEvent") -- 必须等得到

UIS.InputBegan:Connect(function(inp, gp)
	if gp then
		return
	end
	if inp.KeyCode == Enum.KeyCode.F then
		EVT:FireServer(1) -- 1 = Level 1；之后你要几级就改几
	end
end)
