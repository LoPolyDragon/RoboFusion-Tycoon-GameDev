-- GameConstants/main.lua  ⬇︎ 主城常量
local C = {}

--------------------------- 默认存档 -------------------------------
C.DEFAULT_DATA = {
	Scrap = 0,
	Credits = 0,
	RobotCount = 0,
	SignInStreakDay = 0,
	LastSignInTime = 0,
	Upgrades = { CrusherLevel = 1, GeneratorLevel = 1, AssemblerLevel = 1, ShipperLevel = 1 },
	LastUseTime = { Crusher = 0, Generator = 0, Assembler = 0, Shipper = 0 },
	Inventory = {},
	PrivateMine = { seed = 0, lastRefresh = 0 },
}

------------------------ 机器等级 → 速度 ---------------------------
C.MachineInfo = {
	Crusher = { [1] = { speed = 2 }, [2] = { speed = 4 }, [3] = { speed = 6 }, [4] = { speed = 8 }, [5] = { speed = 10 } },
	Generator = { [1] = { speed = 1 }, [2] = { speed = 2 }, [3] = { speed = 3 } },
	Assembler = { [1] = { speed = 1 }, [2] = { speed = 2 } },
	Shipper = { [1] = { speed = 1 }, [2] = { speed = 3 }, [3] = { speed = 5 } },
}

------------------------ Shell 售价 / Bot 键 -----------------------
C.BOT_SELL_PRICE = {
	Dig_UncommonBot = 50,
	Dig_RareBot = 150,
	Dig_EpicBot = 450,
	Dig_SecretBot = 1200,
	Dig_EcoBot = 2000,
	Build_UncommonBot = 50,
	Build_RareBot = 150,
	Build_EpicBot = 450,
	Build_SecretBot = 1200,
	Build_EcoBot = 2000,
}
C.RUSTY_ROLL = { "Dig_UncommonBot", "Build_UncommonBot" }
C.SHELL_COST = { RustyShell = 150, NeonCoreShell = 3000 }

C.ShellRarity = {
	RustyShell = "Uncommon",
	NeonCoreShell = "Rare",
	QuantumCapsuleShell = "Epic",
	SecretPrototypeShell = "Secret",
	EcoBoosterPodShell = "Eco",
}

C.RobotKey = {
	Dig = {
		Uncommon = "Dig_UncommonBot",
		Rare = "Dig_RareBot",
		Epic = "Dig_EpicBot",
		Secret = "Dig_SecretBot",
		Eco = "Dig_EcoBot",
	},
	Build = {
		Uncommon = "Build_UncommonBot",
		Rare = "Build_RareBot",
		Epic = "Build_EpicBot",
		Secret = "Build_SecretBot",
		Eco = "Build_EcoBot",
	},
}

C.RARITY_ORDER = { Uncommon = 1, Rare = 2, Epic = 3, Eco = 4, Secret = 5 }

------------------------- 每日签到 ------------------------------
C.DAILY_REWARDS = {
	{ type = "Scrap", amount = 500 },
	{ type = "Credits", amount = 1000 },
	{ type = "RustyShell", amount = 2 },
	{ type = "WoodPick", amount = 1 },
	{ type = "TitaniumOre", amount = 25 },
	{ type = "EnergyCoreS", amount = 3 },
	{ type = "NeonCoreShell", amount = 1 },
}

return C
