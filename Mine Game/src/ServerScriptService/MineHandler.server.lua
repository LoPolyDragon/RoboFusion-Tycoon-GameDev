--------------------------------------------------------------------
-- MineHandler.lua   ★ 只处理“挖矿请求” + 物品掉落
--------------------------------------------------------------------
local RS           = game:GetService("ReplicatedStorage")
local RE         = game:GetService("ReplicatedStorage")
	:WaitForChild("RemoteEvents"):WaitForChild("MineRequestEvent")
local GameLogic  = require(game.ServerScriptService.ServerModules.GameLogicServer)


local Const             = require(RS.SharedModules.GameConstants)

-- 工具参数表（后续可扩）
local TOOL_INFO = {
	["Wood Pick"] = { durability = 50, hardness = 2 },
}

-- 矿石 → 硬度
local ORE_HARD = {
	Scrap       = 1,
	IronOre     = 2,
	BronzeOre   = 3,
	GoldOre     = 4,
	DiamondOre  = 5,
	TitaniumOre = 6,
	UraniumOre  = 6,
}

-- 每个玩家的耐久缓存（存到存档也行，这里简单放内存）
local durCache = {}      -- [uid] = {["Wood Pick"]=剩余}

----------------------------------------------------------------
local function getDur(plr, toolName)
	durCache[plr.UserId] = durCache[plr.UserId] or {}
	local tbl = durCache[plr.UserId]
	if tbl[toolName] == nil then
		tbl[toolName] = TOOL_INFO[toolName].durability
	end
	return tbl
end

----------------------------------------------------------------
RE.OnServerEvent:Connect(function(plr, part)
	-- 0) 基本合法性
	if not (plr and plr.Character and part and part:IsDescendantOf(workspace)) then return end

	local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
	local tool     = humanoid and humanoid:FindFirstChildOfClass("Tool")
	if not tool    then return end

	local info     = TOOL_INFO[tool.Name]
	if not info    then return end                      -- 非白名单工具

	local oreType  = part.Name
	local needHard = ORE_HARD[oreType] or 1
	if needHard > info.hardness then
		-- 硬度不足
		RE:FireClient(plr, false, getDur(plr, tool.Name)[tool.Name])
		return
	end

	-- 1) 扣耐久
	local cache = getDur(plr, tool.Name)
	if cache[tool.Name] <= 0 then
		RE:FireClient(plr, false, 0);  return
	end
	cache[tool.Name] -= 1
	local left = cache[tool.Name]

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
	RE:FireClient(plr, true, left)
end)