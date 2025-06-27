-- LocalTransparencyForBots.client.lua
local RS = game:GetService("ReplicatedStorage")
local BotsFolder = workspace -- 机器人都放 workspace 根

local function ghostify(model)
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.LocalTransparencyModifier = 0.6 -- 0=完全透明  1=完全实心
		end
	end
end

BotsFolder.ChildAdded:Connect(function(child)
	if child:IsA("Model") and child:FindFirstChild("Humanoid") then
		if child.Name:match("_Bot$") then -- 你在 spawnBot 里给机器人的命名规则
			ghostify(child)
		end
	end
end)
