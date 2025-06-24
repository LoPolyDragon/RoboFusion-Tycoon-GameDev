--------------------------------------------------------------------
-- IconUtils.lua  · 两系机器人（Dig / Build）× 5 稀有度
--------------------------------------------------------------------

local iconMap = {
	----------------------------------------------------------------
	-- 资源 / 矿石（示例，若已有可不用动）
	----------------------------------------------------------------
	Scrap = "rbxassetid://12345678",
	Credits = "rbxassetid://23456789",
	Stone = "rbxassetid://78621405658201", -- TODO
	IronOre = "rbxassetid://137200348791768",
	BronzeOre = "rbxassetid://106645704563011",
	GoldOre = "rbxassetid://72211076717554",
	DiamondOre = "rbxassetid://97898564796367",
	TitaniumOre = "rbxassetid://121090152420192",
	UraniumOre = "rbxassetid://92801874781162",

	-- 工具
	WoodPick = "rbxassetid://119320263773595",
	IronPick = "rbxassetid://127059172002416",
	BronzePick = "rbxassetid://122053711514996",
	GoldPick = "rbxassetid://76285695150805",
	DiamondPick = "rbxassetid://96638336667121",

	----------------------------------------------------------------
	-- Shell（如需）
	----------------------------------------------------------------
	RustyShell = "rbxassetid://90449420021223",
	NeonCoreShell = "rbxassetid://101883593804867",
	QuantumCapsuleShell = "rbxassetid://100995796711411",
	EcoBoosterPodShell = "rbxassetid://120615246024049",
	SecretPrototypeShell = "rbxassetid://80932229317989",

	----------------------------------------------------------------
	-- 机器人  ▶ 只有 Dig / Build 两条线 × 5 稀有度
	----------------------------------------------------------------
	Dig_UncommonBot = "rbxassetid://0", -- TODO 上传后替换
	Dig_RareBot = "rbxassetid://0",
	Dig_EpicBot = "rbxassetid://0",
	Dig_MythicBot = "rbxassetid://0",
	Dig_SecretBot = "rbxassetid://0",

	Build_UncommonBot = "rbxassetid://0",
	Build_RareBot = "rbxassetid://0",
	Build_EpicBot = "rbxassetid://0",
	Build_MythicBot = "rbxassetid://0",
	Build_SecretBot = "rbxassetid://0",

	----------------------------------------------------------------
	_default = "rbxasset://textures/ui/GuiImagePlaceholder.png",
}

--------------------------------------------------------------------
-- 外部接口
--------------------------------------------------------------------
local IconUtils = {}

function IconUtils.getItemIcon(itemId: string): string
	return iconMap[itemId] or iconMap._default
end

return IconUtils
