-- CharacterCollision.server.lua
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

-- 新 API：重复调用也没事，已存在会返回 false
PhysicsService:RegisterCollisionGroup("Players")

local function setGroup(model)
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.CollisionGroup = "Players"
		end
	end
end

Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(setGroup)
	if plr.Character then
		setGroup(plr.Character)
	end
end)
