--------------------------------------------------------------------
-- MineHandler.lua   ★ 只处理"挖矿请求" + 物品掉落
--------------------------------------------------------------------
local RS = game:GetService("ReplicatedStorage")
local RE = RS:WaitForChild("RemoteEvents"):WaitForChild("MineRequestEvent")
local GameLogic = require(game.ServerScriptService.ServerModules.GameLogicServer)

local Const = require(RS.SharedModules.GameConstants)

-- 矿石 → 硬度
local ORE_HARD = {
	Scrap = 1,
	Stone = 1, -- 添加Stone支持
	IronOre = 2,
	BronzeOre = 3,
	GoldOre = 4,
	DiamondOre = 5,
	TitaniumOre = 6,
	UraniumOre = 6,
}

----------------------------------------------------------------
local function findBestPickaxe(inv, oreHardness)
	local best, minDur = nil, math.huge
	for _, slot in ipairs(inv) do
		local info = Const.PICKAXE_INFO[slot.itemId]
		if
			info
			and info.maxHardness >= oreHardness
			and slot.quantity > 0
			and (slot.durability or info.durability) > 0
		then
			local dur = slot.durability or info.durability
			if dur < minDur then
				best, minDur = slot, dur
			end
		end
	end
	return best
end

----------------------------------------------------------------
RE.OnServerEvent:Connect(function(plr, part)
	-- 0) 基本合法性
	if not (plr and plr.Character and part and part:IsDescendantOf(workspace)) then
		return
	end

	local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
	local tool = humanoid and humanoid:FindFirstChildOfClass("Tool")
	if not tool then
		return
	end

	local info = Const.PICKAXE_INFO[tool.Name]
	if not info then
		return
	end -- 非白名单工具

	local oreType = part.Name
	local needHard = ORE_HARD[oreType] or 1
	if needHard > info.maxHardness then
		-- 硬度不足
		RE:FireClient(plr, false, 0)
		return
	end

	-- 1) 扣耐久
	local inv = GameLogic.GetInventoryDict(plr)
	local pickSlot = findBestPickaxe(inv, needHard)
	if not pickSlot then
		RE:FireClient(plr, false, 0) -- 没有可用镐子
		return
	end
	if pickSlot.durability == nil then
		pickSlot.durability = Const.PICKAXE_INFO[pickSlot.itemId].durability
	end
	if pickSlot.durability <= 0 then
		GameLogic.RemoveItem(plr, pickSlot.itemId, 1)
		RE:FireClient(plr, false, 0)
		return
	end
	pickSlot.durability = pickSlot.durability - 1
	if pickSlot.durability <= 0 then
		GameLogic.RemoveItem(plr, pickSlot.itemId, 1)
	end
	GameLogic.UpdateInventorySlot(plr, pickSlot)

	-- 2) 计算掉落
	local val = part:FindFirstChild("OreAmount")
	local qty = val and val.Value or 1
	if oreType == "Scrap" then
		GameLogic.AddScrap(plr, qty)
	else
		GameLogic.AddItem(plr, oreType, qty)
	end

	-- 3) 销毁方块
	part:Destroy()

	-- 4) 回包：true + 剩余耐久
	RE:FireClient(plr, true, pickSlot.durability > 0 and pickSlot.durability or 0)
end)

-- 添加这个函数来清除所有石头
function MineHandler:ClearAllStones()
	-- 遍历所有 mine 区域
	for _, mine in pairs(self.mines) do
		-- 清除该 mine 中的所有石头
		if mine.stones then
			for _, stone in pairs(mine.stones) do
				if stone and stone.Parent then
					stone:Destroy()
				end
			end
			mine.stones = {}
		end
	end
	print("All stones cleared from all mines")
end
