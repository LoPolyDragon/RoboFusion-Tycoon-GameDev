local Cmd = {}
local Admins = { 5383359631 } -- 你的 Roblox UserId

local function isAdmin(plr)
	for _, id in ipairs(Admins) do
		if plr.UserId == id then
			return true
		end
	end
end

game.Players.PlayerAdded:Connect(function(plr)
	plr.Chatted:Connect(function(msg)
		if not isAdmin(plr) then
			return
		end
		if msg == "/log" then
			local ok, log = pcall(function()
				return game:GetService("DataStoreService"):GetDataStore("RF_ErrorHub"):GetAsync("Log")
			end)
			if ok and log then
				print("=== Last Logs ===")
				for _, l in ipairs(log) do
					print(l)
				end
			end
		elseif msg == "/profile" then
			local ProfileStore = require(game.ServerScriptService.ServerModules.ProfileStore)
			print(ProfileStore.Get(plr.UserId))
		elseif msg:sub(1, 9) == "/addpick " then
			local pick = msg:sub(10)
			local GameLogic = require(game.ServerScriptService.ServerModules.GameLogicServer)
			GameLogic.AddItem(plr, pick, 1)
			print("已给你1把", pick)
		elseif msg:sub(1, 12) == "/removeitem " then
			local item = msg:sub(13)
			local GameLogic = require(game.ServerScriptService.ServerModules.GameLogicServer)
			GameLogic.RemoveItem(plr, item, 9999) -- 一次性删光
			print("已移除所有", item)
		elseif msg == "/give pickaxe" then
			local GameLogic = require(game.ServerScriptService.ServerModules.GameLogicServer)
			GameLogic.AddItem(plr, "WoodPick", 1)
			GameLogic.AddItem(plr, "IronPick", 1)
			GameLogic.AddItem(plr, "DiamondPick", 1)
			print("已给你各种镐子")
		elseif msg == "/goto mine" then
			local TeleportService = game:GetService("TeleportService")
			local MINE_PLACE_ID = 140740196969845 -- 替换为你的矿区PlaceId
			TeleportService:Teleport(MINE_PLACE_ID, plr)
		end
	end)
end)
