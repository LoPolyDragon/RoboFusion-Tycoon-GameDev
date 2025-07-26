-- GameConstants/main.lua  ⬇︎ 主城常量
local C = {}

--------------------------- 默认存档 -------------------------------
C.DEFAULT_DATA = {
	Scrap = 0,
	Credits = 0,
	RobotCount = 0,
	SignInStreakDay = 0,
	LastSignInTime = 0,
	PlayTime = 0, -- 总游戏时间（秒）
	SessionStartTime = 0, -- 本次会话开始时间
	Upgrades = { CrusherLevel = 1, GeneratorLevel = 1, AssemblerLevel = 1, ShipperLevel = 1 },
	LastUseTime = { Crusher = 0, Generator = 0, Assembler = 0, Shipper = 0 },
	Inventory = {},
	PrivateMine = { seed = 0, lastRefresh = 0 },
	-- Tier系统数据
	CurrentTier = 0,  -- 当前解锁的Tier等级
	MaxDepthReached = 0,  -- 到达的最大深度
	TierProgress = {  -- 各Tier的进度跟踪
		tutorialComplete = false,
		scrapCollected = 0,
		ironOreCollected = 0,
		bronzeOreCollected = 0,
		goldOreCollected = 0,
		diamondOreCollected = 0,
		titaniumOreCollected = 0,
		ironBarCrafted = 0,
		bronzeGearCrafted = 0,
		goldPlatedEdgeCrafted = 0,
		energyStationsBuilt = 0,
		maxBuildingLevel = 1
	}
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
	ToolForge = { 0, 100, 250, 500, 900, 1400, 2000, 3000, 4500, 6000 },
	Smelter = { 0, 100, 250, 500, 900, 1400, 2000, 3000, 4500, 6000 },
	EnergyStation = { 0, 150, 350, 700, 1200, 1800, 2500, 3500, 5000, 7000 },
}

-- 建筑升级数据（根据GDD Final.md）
C.BUILDING_UPGRADE_DATA = {
	-- 队列上限（所有建筑通用）
	QueueLimit = { 1, 5, 12, 25, 40, 60, 90, 130, 190, 250 },
	
	-- 各建筑特定属性
	Crusher = {
		speed = { 1, 1.3, 1.6, 2.0, 2.4, 2.8, 3.2, 3.6, 4.0, 4.5 },
		description = "粉碎速度提升"
	},
	Generator = {
		speed = { 1, 1.2, 1.4, 1.7, 2.0, 2.3, 2.6, 3.0, 3.4, 3.8 },
		description = "生成速度提升"
	},
	Assembler = {
		speed = { 1, 1.2, 1.4, 1.7, 2.0, 2.3, 2.6, 3.0, 3.4, 3.8 },
		description = "组装速度提升"
	},
	Shipper = {
		speed = { 1, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0, 6.0 },
		description = "出货速度提升"
	},
	ToolForge = {
		speed = { 1, 1.2, 1.4, 1.7, 2.0, 2.3, 2.6, 3.0, 3.4, 3.8 },
		description = "制作速度提升"
	},
	Smelter = {
		speed = { 1, 1.2, 1.4, 1.7, 2.0, 2.3, 2.6, 3.0, 3.4, 3.8 },
		description = "熔炼速度提升"
	},
	EnergyStation = {
		range = { 20, 25, 30, 35, 40, 45, 50, 55, 60, 70 },
		chargeRate = { 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.6, 0.7, 0.8 },
		description = "充能范围和速度提升"
	}
}

-- 兼容性保持
C.BUILDING_QUEUE_LIMIT = C.BUILDING_UPGRADE_DATA.QueueLimit

------------------------- Tier解锁系统 ------------------------------
C.TIER_SYSTEM = {
	-- Tier要求配置
	REQUIREMENTS = {
		[0] = { -- Tier 0 - 教程阶段
			name = "新手探索者",
			description = "完成基础教学，开始你的工业之旅",
			requirements = {
				scrap = 150,  -- 收集150 Scrap
				tutorialComplete = true  -- 完成教学
			},
			unlocks = {
				"Builder Bot", "基础商店", "简单工具制作"
			}
		},
		[1] = { -- Tier 1 - 铁器时代 
			name = "铁器开拓者",
			description = "深入地下，开启铁器文明",
			requirements = {
				ironOre = 50,    -- 收集50个Iron Ore
				depth = 20,      -- 达到20 stud深度
				buildingLevel = 2  -- 至少一个建筑达到Lv2
			},
			unlocks = {
				"Research Bench", "建筑Lv2解锁", "铁制工具", "Iron Bar制作"
			}
		},
		[2] = { -- Tier 2 - 青铜扩展
			name = "青铜工程师", 
			description = "掌握合金技术，建设高效工厂",
			requirements = {
				bronzeOre = 30,      -- 收集30个Bronze Ore
				ironBar = 20,        -- 制作20个Iron Bar
				depth = 60,          -- 达到60 stud深度
				buildingLevel = 5    -- 至少一个建筑达到Lv5
			},
			unlocks = {
				"Energy Station", "建筑Lv5解锁", "青铜工具", "Bronze Gear制作", "高级制作系统"
			}
		},
		[3] = { -- Tier 3 - 黄金核心
			name = "黄金大师",
			description = "掌握贵金属技术，进入核心时代",
			requirements = {
				goldOre = 20,         -- 收集20个Gold Ore 
				bronzeGear = 15,      -- 制作15个Bronze Gear
				depth = 100,          -- 达到100 stud深度
				energyStation = 1     -- 建造至少1个Energy Station
			},
			unlocks = {
				"核能链系统", "Eco-Core", "黄金工具", "Gold-Plated Edge制作", "高级能量管理"
			}
		},
		[4] = { -- Tier 4 - 终极阶段
			name = "钻石传奇",
			description = "征服最深层，成为工业霸主",
			requirements = {
				diamondOre = 10,      -- 收集10个Diamond Ore
				titaniumOre = 5,      -- 收集5个Titanium Ore
				depth = 160,          -- 达到160 stud深度
				goldPlatedEdge = 10   -- 制作10个Gold-Plated Edge
			},
			unlocks = {
				"火箭装配链", "星际地图", "钻石工具", "Diamond Tip制作", "Prestige系统"
			}
		}
	},
	
	-- 建筑等级限制
	BUILDING_LEVEL_LIMITS = {
		[0] = 1,  -- Tier 0: 建筑最高Lv1
		[1] = 2,  -- Tier 1: 建筑最高Lv2
		[2] = 5,  -- Tier 2: 建筑最高Lv5
		[3] = 8,  -- Tier 3: 建筑最高Lv8
		[4] = 10  -- Tier 4: 建筑最高Lv10
	},
	
	-- 工具解锁要求
	TOOL_UNLOCKS = {
		WoodPick = 0,     -- Tier 0解锁
		IronPick = 1,     -- Tier 1解锁
		BronzePick = 2,   -- Tier 2解锁
		GoldPick = 3,     -- Tier 3解锁
		DiamondPick = 4,  -- Tier 4解锁
	},
	
	-- 建筑解锁要求
	BUILDING_UNLOCKS = {
		Crusher = 0,       -- Tier 0解锁
		Generator = 0,     -- Tier 0解锁
		Assembler = 0,     -- Tier 0解锁
		Shipper = 0,       -- Tier 0解锁
		ToolForge = 1,     -- Tier 1解锁
		Smelter = 1,       -- Tier 1解锁
		EnergyStation = 2, -- Tier 2解锁
	}
}

------------------------- 能量系统配置 ------------------------------
C.ENERGY_CONFIG = {
	maxEnergy = 60,                    -- 机器人最大能量
	baseChargeRate = 0.2,              -- 基础充能速度（每秒）
	creditsChargeRatio = 100/60,       -- Credits充能比率（100 Credits = 60能量）
	
	-- 机器人能量消耗（每分钟）
	robotConsumption = {
		TR = 0.8,  -- Transport 运输机器人
		SM = 0.5,  -- Small 小型机器人
		SC = 1.5,  -- Scanner 扫描机器人
		MN = 1.0,  -- Mining 挖矿机器人
		BT = 2.0,  -- Battle 战斗机器人
	}
}

-- 能量站配置
C.ENERGY_STATIONS = {
	[1] = { range = 20, chargeMultiplier = 1.0 },   -- Level 1: 范围20，速度1.0x
	[2] = { range = 25, chargeMultiplier = 1.25 },  -- Level 2: 范围25，速度1.25x
	[3] = { range = 30, chargeMultiplier = 1.5 },   -- Level 3: 范围30，速度1.5x
	[4] = { range = 35, chargeMultiplier = 1.75 },  -- Level 4: 范围35，速度1.75x
	[5] = { range = 40, chargeMultiplier = 2.0 },   -- Level 5: 范围40，速度2.0x
}

return C
