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
	Crusher = {
		[1] = { speed = 2 },
		[2] = { speed = 4 },
		[3] = { speed = 6 },
		[4] = { speed = 8 },
		[5] = { speed = 10 },
	},
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
	[1] = { type = "Scrap", amount = 500 },
	[2] = { type = "Credits", amount = 1000 },
	[3] = { type = "RustyShell", amount = 2 },
	[4] = { type = "WoodPick", amount = 1 },
	[5] = { type = "TitaniumOre", amount = 25 },
	[6] = { type = "EnergyCoreS", amount = 3 },
	[7] = { type = "NeonCoreShell", amount = 1 },
}

C.ORE_INFO = {
	Scrap = { hardness = 0, time = 0.7 },
	Stone = { hardness = 1, time = 1.0 },
	IronOre = { hardness = 2, time = 1.2 },
	BronzeOre = { hardness = 3, time = 1.6 },
	GoldOre = { hardness = 4, time = 2.0 },
	DiamondOre = { hardness = 5, time = 3.0 },
	TitaniumOre = { hardness = 6, time = 4.0 },
	UraniumOre = { hardness = 6, time = 5.0 },
}

C.BotStats = {
	UncommonBot = { interval = 3 },
	RareBot = { interval = 2.5 },
	EpicBot = { interval = 2 },
	SecretBot = { interval = 1.5 },
	EcoBot = { interval = 1.2 },
}

-- 镐子信息 (根据GDD精确数值)
C.PICKAXE_INFO = {
	WoodPick = { 
		maxHardness = 2, 
		durability = 50, 
		material = "ScrapWood",
		description = "木镐 - 耐久50格，可挖硬度1-2" 
	},
	IronPick = { 
		maxHardness = 3, 
		durability = 120, 
		material = "IronBar",
		description = "铁镐 - 耐久120格，可挖硬度3" 
	},
	BronzePick = { 
		maxHardness = 4, 
		durability = 250, 
		material = "BronzeGear",
		description = "青铜镐 - 耐久250格，可挖硬度4" 
	},
	GoldPick = { 
		maxHardness = 5, 
		durability = 400, 
		material = "GoldPlatedEdge",
		description = "黄金镐 - 耐久400格，可挖硬度5" 
	},
	DiamondPick = { 
		maxHardness = 6, 
		durability = 800, 
		material = "DiamondTip",
		description = "钻石镐 - 耐久800格，可挖硬度6（所有矿物）" 
	},
}

-- 锤子信息 (根据GDD精确数值)
C.HAMMER_INFO = {
	WoodHammer = { 
		minutes = 5, 
		material = "ScrapWood",
		description = "木锤 - 建造耐久5分钟" 
	},
	IronHammer = { 
		minutes = 30, 
		material = "IronBar", 
		materialCount = 2,
		description = "铁锤 - 建造耐久30分钟" 
	},
	BronzeHammer = { 
		minutes = 300, 
		material = "BronzeGear",
		description = "青铜锤 - 建造耐久5小时" 
	},
	GoldHammer = { 
		minutes = 600, 
		material = "GoldPlatedEdge",
		description = "黄金锤 - 建造耐久10小时" 
	},
	DiamondHammer = { 
		minutes = 6000, 
		material = "DiamondTip",
		description = "钻石锤 - 建造耐久100小时" 
	},
}

-- 制作材料信息
C.CRAFT_MATERIALS = {
	IronBar = { description = "铁锭，用于制作铁制工具" },
	BronzeGear = { description = "青铜齿轮，用于制作青铜工具" },
	GoldPlatedEdge = { description = "镀金边缘，用于制作黄金工具" },
	DiamondTip = { description = "钻石尖端，用于制作钻石工具" },
}

C.BUILDING_UPGRADE_COST = {
	Crusher = { 0, 100, 250, 500, 900, 1400, 2000, 3000, 4500, 6000 },
	Generator = { 0, 100, 250, 500, 900, 1400, 2000, 3000, 4500, 6000 },
	Assembler = { 0, 100, 250, 500, 900, 1400, 2000, 3000, 4500, 6000 },
	Shipper = { 0, 100, 250, 500, 900, 1400, 2000, 3000, 4500, 6000 },
}
C.BUILDING_QUEUE_LIMIT = { 1, 5, 12, 25, 40, 60, 90, 130, 190, 250 }

return C
