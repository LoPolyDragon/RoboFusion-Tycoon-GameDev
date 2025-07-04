-- GameConstants/mine.lua ⬇︎ Mine Scene 专用
local C = {}

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

-- 只保留矿场本身需要的常量
C.SHELL_COST = { RustyShell = 150, NeonCoreShell = 3000 }

C.ORE_INFO = {
	Scrap = { hardness = 0, time = 0.7 },
	IronOre = { hardness = 2, time = 1.2 },
	BronzeOre = { hardness = 3, time = 1.6 },
	GoldOre = { hardness = 4, time = 2.0 },
	DiamondOre = { hardness = 5, time = 3.0 },
	TitaniumOre = { hardness = 6, time = 4.0 },
	UraniumOre = { hardness = 6, time = 5.0 },
	Stone = { hardness = 1, time = 1.0 },
}

C.BotStats = {
	UncommonBot = { interval = 3 },
	RareBot = { interval = 2.5 },
	EpicBot = { interval = 2 },
	SecretBot = { interval = 1.5 },
	EcoBot = { interval = 1.2 },
}

C.PICKAXE_INFO = {
	WoodPick = { maxHardness = 2, speedMul = 1.0 },
	StonePick = { maxHardness = 3, speedMul = 0.9 },
	IronPick = { maxHardness = 4, speedMul = 0.8 },
	GoldPick = { maxHardness = 5, speedMul = 0.7 },
	DiamondPick = { maxHardness = 6, speedMul = 0.6 },
}

return C
