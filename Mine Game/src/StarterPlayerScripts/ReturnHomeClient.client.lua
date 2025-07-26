local RS        = game:GetService("ReplicatedStorage")
local Players   = game:GetService("Players")
local player    = Players.LocalPlayer

-- UI 中的 “Return” 按钮
local GUI = game.StarterGui.ScreenGui
local btn = GUI:WaitForChild("ReturnBtn")   -- 按实际层级改

btn.Activated:Connect(function()
	local data   = player:GetJoinData().TeleportData
	local homeId = data and data.returnTo
	if not homeId then return end

	RS.RemoteEvents.ReturnHomeEvent:FireServer(homeId)
end)