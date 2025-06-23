-- ReplicatedStorage.ClientUtils.IconUtils  (ModuleScript)

--------------------------------------------------------------------
-- ► 物品 → 图片 ID 对照表
--   ▸ 只改这一张表即可；别动下面函数
--------------------------------------------------------------------

local iconMap = {
	-- 基础资源
	Scrap       = "rbxassetid://12345678",
	Credits     = "rbxassetid://23456789",

	-- Shell
	RustyShell          = "rbxassetid://90449420021223",
	NeonCoreShell       = "rbxassetid://101883593804867",
	QuantumCapsuleShell = "rbxassetid://100995796711411",
	EcoBoosterPodShell  = "rbxassetid://120615246024049",
	SecretPrototypeShell= "rbxassetid://80932229317989",

	-- 机器人（务必与上表键名一致！）
	-- Common Bot
	
	MN_CommonBot = "rbxassetid://138744279947480",
	TR_CommonBot = "rbxassetid://106249178527129",
	SM_CommonBot = "rbxassetid://71757853661955",
	BT_CommonBot = "rbxassetid://119020607548689",
	SC_CommonBot = "rbxassetid://89373671481731",
	
	
	UncommonBot    = "rbxassetid://110122446519504",
	RareBot        = "rbxassetid://85738689687088",
	EpicBot        = "rbxassetid://106794358421035",
	MythicBot      = "rbxassetid://72394785201479",
	SecretBot      = "rbxassetid://76865773721387",

	_default    = "rbxasset://textures/ui/GuiImagePlaceholder.png",
}


--------------------------------------------------------------------
-- ► 对外接口
--------------------------------------------------------------------
local IconUtils = {}

-- 传入 itemId（区分大小写），返回对应 ImageId
function IconUtils.getItemIcon(itemId : string) : string
	return iconMap[itemId] or iconMap._default
end

return IconUtils