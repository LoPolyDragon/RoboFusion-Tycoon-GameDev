-- MineWorldServer.lua
local MG = require(script.Parent:WaitForChild("MineGenerator"))

local function ensurePrivateMineFolder(plr)
	local mines = workspace:FindFirstChild("PrivateMines")
	if not mines then
		mines = Instance.new("Folder")
		mines.Name = "PrivateMines"
		mines.Parent = workspace
	end
	local mineFolder = mines:FindFirstChild(plr.Name)
	if not mineFolder then
		mineFolder = Instance.new("Folder")
		mineFolder.Name = plr.Name
		mineFolder.Parent = mines
	end
	return mineFolder
end

game.Players.PlayerAdded:Connect(function(plr)
	local rootFolder = ensurePrivateMineFolder(plr)
	MG.Generate(rootFolder)
end)
