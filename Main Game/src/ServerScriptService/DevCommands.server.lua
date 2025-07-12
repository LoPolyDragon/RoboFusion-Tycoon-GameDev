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
		elseif msg == "/give materials" then
			local GameLogic = require(game.ServerScriptService.ServerModules.GameLogicServer)
			-- 给予制作材料
			GameLogic.AddItem(plr, "IronOre", 20)
			GameLogic.AddItem(plr, "BronzeOre", 15)
			GameLogic.AddItem(plr, "GoldOre", 10)
			GameLogic.AddItem(plr, "DiamondOre", 5)
			GameLogic.AddItem(plr, "Scrap", 1000)
			GameLogic.AddItem(plr, "WoodPick", 1)
			GameLogic.AddItem(plr, "WoodHammer", 1)
			print("已给你制作材料和基础工具")
		elseif msg:sub(1, 7) == "/craft " then
			local item = msg:sub(8)
			local CraftEvent = game.ReplicatedStorage:FindFirstChild("CraftItemEvent")
			if CraftEvent then
				CraftEvent:FireServer(item)
			else
				print("制作系统未启动")
			end
		elseif msg == "/build energy" then
			local EnergyStationEvent = game.ReplicatedStorage:FindFirstChild("EnergyStationEvent")
			if EnergyStationEvent then
				local position = plr.Character and plr.Character.HumanoidRootPart and plr.Character.HumanoidRootPart.Position
				if position then
					EnergyStationEvent:FireServer("BUILD", 1, position)
				end
			else
				print("能量站系统未启动")
			end
		elseif msg == "/give credits" then
			local GameLogic = require(game.ServerScriptService.ServerModules.GameLogicServer)
			local data = GameLogic.GetPlayerData(plr)
			if data then
				data.Credits = (data.Credits or 0) + 10000
				print("已给你10000 Credits")
			end
		elseif msg == "/help" then
			print("=== 开发者命令 ===")
			print("/give pickaxe - 获得各种镐子")
			print("/give materials - 获得制作材料")
			print("/give credits - 获得10000 Credits")
			print("/craft [物品名] - 制作物品")
			print("/build energy - 在当前位置建造能量站")
			print("/goto mine - 传送到矿区")
			print("/addpick [镐子名] - 添加特定镐子")
			print("/removeitem [物品名] - 移除物品")
			print("")
			print("=== 制作系统 (根据GDD) ===")
			print("基础材料:")
			print("  /craft ScrapWood - 废料×5 → 废木×1")
			print("  /craft IronBar - 废料×1 + 铁矿×1 → 铁锭×1")
			print("  /craft BronzeGear - 废料×1 + 青铜矿×1 → 青铜齿轮×1")
			print("  /craft GoldPlatedEdge - 废料×2 + 金矿×1 → 镀金边缘×1")
			print("  /craft DiamondTip - 废料×3 + 钻石矿×1 → 钻石尖端×1")
			print("")
			print("镐子升级链:")
			print("  /craft WoodPick - 废木×1 → 木镐(耐久50)")
			print("  /craft IronPick - 木镐×1 + 铁锭×1 → 铁镐(耐久120)")
			print("  /craft BronzePick - 铁镐×1 + 青铜齿轮×1 → 青铜镐(耐久250)")
			print("  /craft GoldPick - 青铜镐×1 + 镀金边缘×1 → 黄金镐(耐久400)")
			print("  /craft DiamondPick - 黄金镐×1 + 钻石尖端×1 → 钻石镐(耐久800)")
			print("")
			print("锤子升级链:")
			print("  /craft WoodHammer - 废木×1 → 木锤(5分钟)")
			print("  /craft IronHammer - 木锤×1 + 铁锭×2 → 铁锤(30分钟)")
			print("  /craft BronzeHammer - 铁锤×1 + 青铜齿轮×1 → 青铜锤(5小时)")
			print("  /craft GoldHammer - 青铜锤×1 + 镀金边缘×1 → 黄金锤(10小时)")
			print("  /craft DiamondHammer - 黄金锤×1 + 钻石尖端×1 → 钻石锤(100小时)")
		end
	end)
end)
