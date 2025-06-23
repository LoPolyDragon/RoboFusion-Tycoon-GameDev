-- MineWorldServer.lua
local MG = require(script.Parent:WaitForChild("MineGenerator"))
game.Players.PlayerAdded:Connect(function(plr) MG.Generate(plr) end)