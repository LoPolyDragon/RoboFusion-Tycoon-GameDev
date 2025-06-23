local Players            = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local GameLogic = require(
	game.ServerScriptService.ServerModules:WaitForChild("GameLogicServer"))

local AUTO_PASS_ID = 1249719442

local function hasPass(plr)
	local ok,own = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService,
		plr.UserId, AUTO_PASS_ID)
	return ok and own
end

local function getRate(data)
	local sum = (data.Upgrades.CrusherLevel or 1) +
		(data.Upgrades.GeneratorLevel or 1) +
		(data.Upgrades.AssemblerLevel or 1) +
		(data.Upgrades.ShipperLevel  or 1)
	return math.max(1, math.floor(sum/4)*2)
end

task.spawn(function()
	while true do
		for _,plr in ipairs(Players:GetPlayers()) do
			if hasPass(plr) then
				local d = GameLogic.GetPlayerData(plr)
				if d then d.Scrap += getRate(d) end
			end
		end
		task.wait(1)
	end
end)