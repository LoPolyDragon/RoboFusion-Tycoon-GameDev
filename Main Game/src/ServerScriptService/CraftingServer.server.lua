----------------------------------------------------------------
-- CraftingServer.server.lua · 工具制作系统
----------------------------------------------------------------
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameLogic = require(script.Parent.ServerModules.GameLogicServer)
local Const = require(RS.SharedModules.GameConstants)

----------------------------------------------------------------
-- 制作配方定义 (根据GDD Final.md)
----------------------------------------------------------------
local RECIPES = {
	-- 基础材料制作 (熔炼)
	ScrapWood = {
		materials = { Scrap = 5 },
		output = { ScrapWood = 1 },
		time = 3,
		building = "Crusher", -- 粉碎机处理废料
		description = "用废料制作木材"
	},
	IronBar = {
		materials = { Scrap = 1, IronOre = 1 },
		output = { IronBar = 1 },
		time = 8,
		building = "Smelter", -- 熔炉
		description = "熔炼铁锭：废料 + 铁矿"
	},
	BronzeGear = {
		materials = { Scrap = 1, BronzeOre = 1 },
		output = { BronzeGear = 1 },
		time = 12,
		building = "Smelter", -- 合金炉
		description = "制作青铜齿轮：废料 + 青铜矿"
	},
	GoldPlatedEdge = {
		materials = { Scrap = 2, GoldOre = 1 },
		output = { GoldPlatedEdge = 1 },
		time = 18,
		building = "Smelter",
		description = "制作镀金边缘：废料 + 金矿"
	},
	DiamondTip = {
		materials = { Scrap = 3, DiamondOre = 1 },
		output = { DiamondTip = 1 },
		time = 25,
		building = "Smelter",
		description = "制作钻石尖端：废料 + 钻石矿"
	},
	
	-- 挖掘镐子制作链 (按GDD耐久度)
	WoodPick = {
		materials = { ScrapWood = 1 },
		output = { WoodPick = 1 },
		time = 5,
		building = "ToolForge", -- 工具台
		description = "木镐 - 耐久50格，可挖硬度1-2"
	},
	IronPick = {
		materials = { WoodPick = 1, IronBar = 1 },
		output = { IronPick = 1 },
		time = 10,
		building = "ToolForge",
		description = "铁镐 - 耐久120格，可挖硬度3"
	},
	BronzePick = {
		materials = { IronPick = 1, BronzeGear = 1 },
		output = { BronzePick = 1 },
		time = 15,
		building = "ToolForge",
		description = "青铜镐 - 耐久250格，可挖硬度4"
	},
	GoldPick = {
		materials = { BronzePick = 1, GoldPlatedEdge = 1 },
		output = { GoldPick = 1 },
		time = 20,
		building = "ToolForge",
		description = "黄金镐 - 耐久400格，可挖硬度5"
	},
	DiamondPick = {
		materials = { GoldPick = 1, DiamondTip = 1 },
		output = { DiamondPick = 1 },
		time = 30,
		building = "ToolForge",
		description = "钻石镐 - 耐久800格，可挖硬度6"
	},
	
	-- 建造锤子制作链 (按GDD工作时长)
	WoodHammer = {
		materials = { ScrapWood = 1 },
		output = { WoodHammer = 1 },
		time = 5,
		building = "ToolForge",
		description = "木锤 - 建造耐久5分钟"
	},
	IronHammer = {
		materials = { WoodHammer = 1, IronBar = 2 },
		output = { IronHammer = 1 },
		time = 12,
		building = "ToolForge",
		description = "铁锤 - 建造耐久30分钟"
	},
	BronzeHammer = {
		materials = { IronHammer = 1, BronzeGear = 1 },
		output = { BronzeHammer = 1 },
		time = 20,
		building = "ToolForge",
		description = "青铜锤 - 建造耐久5小时"
	},
	GoldHammer = {
		materials = { BronzeHammer = 1, GoldPlatedEdge = 1 },
		output = { GoldHammer = 1 },
		time = 25,
		building = "ToolForge",
		description = "黄金锤 - 建造耐久10小时"
	},
	DiamondHammer = {
		materials = { GoldHammer = 1, DiamondTip = 1 },
		output = { DiamondHammer = 1 },
		time = 35,
		building = "ToolForge",
		description = "钻石锤 - 建造耐久100小时"
	}
}

----------------------------------------------------------------
-- RemoteEvents 设置
----------------------------------------------------------------
local CraftEvent = RS:FindFirstChild("CraftItemEvent")
if not CraftEvent then
	CraftEvent = Instance.new("RemoteEvent")
	CraftEvent.Name = "CraftItemEvent"
	CraftEvent.Parent = RS
end

local CraftStatusEvent = RS:FindFirstChild("CraftStatusEvent")
if not CraftStatusEvent then
	CraftStatusEvent = Instance.new("RemoteEvent")
	CraftStatusEvent.Name = "CraftStatusEvent"
	CraftStatusEvent.Parent = RS
end

----------------------------------------------------------------
-- 制作队列管理
----------------------------------------------------------------
local craftQueues = {} -- [player] = {recipe, startTime, endTime}

----------------------------------------------------------------
-- 检查材料是否足够
----------------------------------------------------------------
local function hasEnoughMaterials(player, recipe)
	local inventory = GameLogic.GetInventoryDict(player)
	
	for material, needed in pairs(recipe.materials) do
		local have = inventory[material] or 0
		if have < needed then
			return false, string.format("需要 %s x%d，当前只有 x%d", material, needed, have)
		end
	end
	
	return true
end

----------------------------------------------------------------
-- 消耗材料
----------------------------------------------------------------
local function consumeMaterials(player, recipe)
	for material, amount in pairs(recipe.materials) do
		GameLogic.RemoveItem(player, material, amount)
	end
end

----------------------------------------------------------------
-- 给予产出物品
----------------------------------------------------------------
local function giveOutputItems(player, recipe)
	for item, amount in pairs(recipe.output) do
		GameLogic.AddItem(player, item, amount)
	end
end

----------------------------------------------------------------
-- 处理制作请求
----------------------------------------------------------------
CraftEvent.OnServerEvent:Connect(function(player, itemName)
	local recipe = RECIPES[itemName]
	if not recipe then
		CraftEvent:FireClient(player, false, "未知的制作配方: " .. itemName)
		return
	end
	
	-- 检查是否已在制作中
	if craftQueues[player] then
		CraftEvent:FireClient(player, false, "已有物品在制作中，请等待完成")
		return
	end
	
	-- 检查材料
	local hasEnough, errorMsg = hasEnoughMaterials(player, recipe)
	if not hasEnough then
		CraftEvent:FireClient(player, false, errorMsg)
		return
	end
	
	-- 消耗材料
	consumeMaterials(player, recipe)
	
	-- 开始制作
	local now = os.time()
	craftQueues[player] = {
		recipe = recipe,
		itemName = itemName,
		startTime = now,
		endTime = now + recipe.time
	}
	
	-- 通知客户端开始制作
	CraftEvent:FireClient(player, true, string.format("开始制作 %s，预计 %d 秒完成", itemName, recipe.time))
	CraftStatusEvent:FireClient(player, "START", itemName, recipe.time)
	
	print(string.format("[Crafting] %s 开始制作 %s", player.Name, itemName))
end)

----------------------------------------------------------------
-- 制作进度检查 (每秒检查一次)
----------------------------------------------------------------
game:GetService("RunService").Heartbeat:Connect(function()
	local now = os.time()
	
	for player, craftData in pairs(craftQueues) do
		if now >= craftData.endTime then
			-- 制作完成
			giveOutputItems(player, craftData.recipe)
			
			-- 通知客户端完成
			CraftStatusEvent:FireClient(player, "COMPLETE", craftData.itemName)
			
			print(string.format("[Crafting] %s 完成制作 %s", player.Name, craftData.itemName))
			
			-- 更新背包
			RS.RemoteEvents.UpdateInventoryEvent:FireClient(player, GameLogic.GetInventoryDict(player))
			
			-- 清除队列
			craftQueues[player] = nil
		end
	end
end)

----------------------------------------------------------------
-- 玩家离开时清理
----------------------------------------------------------------
Players.PlayerRemoving:Connect(function(player)
	craftQueues[player] = nil
end)

----------------------------------------------------------------
-- 查询制作状态的函数
----------------------------------------------------------------
local GetCraftStatusFunc = RS:FindFirstChild("GetCraftStatusFunction")
if not GetCraftStatusFunc then
	GetCraftStatusFunc = Instance.new("RemoteFunction")
	GetCraftStatusFunc.Name = "GetCraftStatusFunction"
	GetCraftStatusFunc.Parent = RS
end

GetCraftStatusFunc.OnServerInvoke = function(player)
	local craftData = craftQueues[player]
	if not craftData then
		return nil
	end
	
	local now = os.time()
	local remaining = craftData.endTime - now
	
	return {
		itemName = craftData.itemName,
		remaining = math.max(0, remaining),
		total = craftData.recipe.time
	}
end

print("[CraftingServer] 工具制作系统已启动！")