----------------------------------------------------------------
-- MineWorldLoader · 玩家进入矿洞时加载任务机器人
----------------------------------------------------------------
local RTS = require(game:GetService("ServerScriptService").ServerModules.RobotTaskService)
print("[MineWorldLoader] RTS:", RTS, "LoadMissionsForPlayer:", RTS and RTS.LoadMissionsForPlayer)

local mineFolder = workspace -- 若你的矿石都放在 workspace.OreFolder，可直接用 workspace
-- 也可单独创建  workspace.MineWorld  作为统一父级

game.Players.PlayerAdded:Connect(function(plr)
	RTS.LoadMissionsForPlayer(plr, mineFolder)
end)
