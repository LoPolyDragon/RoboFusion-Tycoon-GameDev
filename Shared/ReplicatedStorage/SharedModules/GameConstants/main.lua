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

--------------------------------------------------------------------
-- 机器冷却时间配置 (秒)
--------------------------------------------------------------------
C.MACHINE_COOLDOWNS = {
	-- 基础机器冷却时间
	Crusher = {
		[1] = 5,   -- 1级: 5秒
		[2] = 4,   -- 2级: 4秒  
		[3] = 3,   -- 3级: 3秒
		[4] = 2.5, -- 4级: 2.5秒
		[5] = 2,   -- 5级: 2秒
		[6] = 1.8, -- 6级: 1.8秒
		[7] = 1.6, -- 7级: 1.6秒
		[8] = 1.4, -- 8级: 1.4秒
		[9] = 1.2, -- 9级: 1.2秒
		[10] = 1   -- 10级: 1秒
	},
	Generator = {
		[1] = 8,   -- 1级: 8秒
		[2] = 7,   -- 2级: 7秒
		[3] = 6,   -- 3级: 6秒
		[4] = 5.5, -- 4级: 5.5秒
		[5] = 5,   -- 5级: 5秒
		[6] = 4.5, -- 6级: 4.5秒
		[7] = 4,   -- 7级: 4秒
		[8] = 3.5, -- 8级: 3.5秒
		[9] = 3,   -- 9级: 3秒
		[10] = 2.5 -- 10级: 2.5秒
	},
	Assembler = {
		[1] = 10,  -- 1级: 10秒
		[2] = 9,   -- 2级: 9秒
		[3] = 8,   -- 3级: 8秒
		[4] = 7.5, -- 4级: 7.5秒
		[5] = 7,   -- 5级: 7秒
		[6] = 6.5, -- 6级: 6.5秒
		[7] = 6,   -- 7级: 6秒
		[8] = 5.5, -- 8级: 5.5秒
		[9] = 5,   -- 9级: 5秒
		[10] = 4   -- 10级: 4秒
	},
	Shipper = {
		[1] = 15,  -- 1级: 15秒
		[2] = 13,  -- 2级: 13秒
		[3] = 11,  -- 3级: 11秒
		[4] = 10,  -- 4级: 10秒
		[5] = 9,   -- 5级: 9秒
		[6] = 8,   -- 6级: 8秒
		[7] = 7.5, -- 7级: 7.5秒
		[8] = 7,   -- 8级: 7秒
		[9] = 6.5, -- 9级: 6.5秒
		[10] = 6   -- 10级: 6秒
	},
	Smelter = {
		[1] = 12,  -- 1级: 12秒
		[2] = 11,  -- 2级: 11秒
		[3] = 10,  -- 3级: 10秒
		[4] = 9.5, -- 4级: 9.5秒
		[5] = 9,   -- 5级: 9秒
		[6] = 8.5, -- 6级: 8.5秒
		[7] = 8,   -- 7级: 8秒
		[8] = 7.5, -- 8级: 7.5秒
		[9] = 7,   -- 9级: 7秒
		[10] = 6   -- 10级: 6秒
	},
	ToolForge = {
		[1] = 20,  -- 1级: 20秒 (工具制作较慢)
		[2] = 18,  -- 2级: 18秒
		[3] = 16,  -- 3级: 16秒
		[4] = 15,  -- 4级: 15秒
		[5] = 14,  -- 5级: 14秒
		[6] = 13,  -- 6级: 13秒
		[7] = 12,  -- 7级: 12秒
		[8] = 11,  -- 8级: 11秒
		[9] = 10,  -- 9级: 10秒
		[10] = 8   -- 10级: 8秒
	},
	EnergyStation = {
		[1] = 30,  -- 1级: 30秒 (能量站充能间隔)
		[2] = 28,  -- 2级: 28秒
		[3] = 26,  -- 3级: 26秒
		[4] = 24,  -- 4级: 24秒
		[5] = 22,  -- 5级: 22秒
		[6] = 20,  -- 6级: 20秒
		[7] = 18,  -- 7级: 18秒
		[8] = 16,  -- 8级: 16秒
		[9] = 14,  -- 9级: 14秒
		[10] = 12  -- 10级: 12秒
	}
}

-- 其他系统冷却时间
C.SYSTEM_COOLDOWNS = {
	ROBOT_MINING = 2,      -- 机器人挖矿冷却 2秒
	DAILY_SIGNIN = 86400,  -- 每日签到 24小时
	SHELL_HATCHING = 5,    -- 孵化蛋冷却 5秒
	BUILDING_UPGRADE = 3,  -- 建筑升级冷却 3秒
	INVENTORY_OPERATION = 0.5, -- 背包操作冷却 0.5秒
	TELEPORT = 10,         -- 传送冷却 10秒
}

--------------------------------------------------------------------
-- 建筑系统配置
--------------------------------------------------------------------

-- 建筑类型定义
C.BUILDING_TYPES = {
	-- 生产类建筑
	PRODUCTION = {
		Crusher = {
			name = "粉碎机",
			description = "将废料粉碎成可用材料",
			category = "生产",
			icon = "⚒️",
			baseSize = Vector3.new(4, 4, 4),
			maxLevel = 10,
			baseCost = 100,
			energyConsumption = 5, -- 每分钟能耗
			functionality = "process_scrap"
		},
		Generator = {
			name = "发电机",
			description = "生成电力供其他建筑使用",
			category = "生产",
			icon = "⚡",
			baseSize = Vector3.new(4, 4, 4),
			maxLevel = 10,
			baseCost = 150,
			energyConsumption = 0,
			energyProduction = 10, -- 每分钟发电量
			functionality = "generate_energy"
		},
		Assembler = {
			name = "组装机",
			description = "组装复杂的机器零件",
			category = "生产",
			icon = "🔧",
			baseSize = Vector3.new(4, 4, 4),
			maxLevel = 10,
			baseCost = 200,
			energyConsumption = 8,
			functionality = "assemble_parts"
		},
		Smelter = {
			name = "熔炉",
			description = "熔炼矿石制造金属锭",
			category = "生产",
			icon = "🔥",
			baseSize = Vector3.new(4, 4, 4),
			maxLevel = 10,
			baseCost = 250,
			energyConsumption = 12,
			functionality = "smelt_ores"
		},
		ToolForge = {
			name = "工具铺",
			description = "制作各种工具和装备",
			category = "生产",
			icon = "🛠️",
			baseSize = Vector3.new(4, 4, 4),
			maxLevel = 10,
			baseCost = 300,
			energyConsumption = 10,
			functionality = "craft_tools"
		}
	},
	
	-- 功能类建筑
	FUNCTIONAL = {
		EnergyStation = {
			name = "能量站",
			description = "为机器人充电和能量传输",
			category = "功能",
			icon = "🔋",
			baseSize = Vector3.new(6, 6, 6),
			maxLevel = 10,
			baseCost = 500,
			energyConsumption = 3,
			functionality = "charge_robots"
		},
		StorageWarehouse = {
			name = "储存仓库",
			description = "大容量物品存储设施",
			category = "功能",
			icon = "📦",
			baseSize = Vector3.new(8, 6, 8),
			maxLevel = 5,
			baseCost = 400,
			energyConsumption = 2,
			functionality = "store_items"
		},
		ResearchLab = {
			name = "研究实验室",
			description = "研发新技术和升级",
			category = "功能",
			icon = "🔬",
			baseSize = Vector3.new(6, 6, 6),
			maxLevel = 8,
			baseCost = 800,
			energyConsumption = 15,
			functionality = "research_tech"
		},
		RobotFactory = {
			name = "机器人工厂",
			description = "生产和升级机器人",
			category = "功能",
			icon = "🤖",
			baseSize = Vector3.new(8, 6, 8),
			maxLevel = 10,
			baseCost = 1000,
			energyConsumption = 20,
			functionality = "build_robots"
		},
		TeleportPad = {
			name = "传送台",
			description = "快速传送到不同区域",
			category = "功能",
			icon = "🌀",
			baseSize = Vector3.new(4, 2, 4),
			maxLevel = 3,
			baseCost = 1500,
			energyConsumption = 25,
			functionality = "teleport"
		}
	},
	
	-- 基础设施建筑
	INFRASTRUCTURE = {
		PowerLine = {
			name = "电力线",
			description = "连接建筑传输电力",
			category = "基础设施",
			icon = "⚡",
			baseSize = Vector3.new(1, 4, 1),
			maxLevel = 3,
			baseCost = 50,
			energyConsumption = 0,
			functionality = "power_transmission"
		},
		ConveyorBelt = {
			name = "传送带",
			description = "自动运输物品",
			category = "基础设施",
			icon = "➡️",
			baseSize = Vector3.new(4, 1, 1),
			maxLevel = 5,
			baseCost = 100,
			energyConsumption = 1,
			functionality = "transport_items"
		},
		Bridge = {
			name = "桥梁",
			description = "跨越地形障碍",
			category = "基础设施",
			icon = "🌉",
			baseSize = Vector3.new(8, 2, 4),
			maxLevel = 3,
			baseCost = 300,
			energyConsumption = 0,
			functionality = "terrain_bridge"
		}
	},
	
	-- 装饰建筑
	DECORATIVE = {
		Fountain = {
			name = "喷泉",
			description = "美丽的装饰喷泉",
			category = "装饰",
			icon = "⛲",
			baseSize = Vector3.new(4, 4, 4),
			maxLevel = 3,
			baseCost = 200,
			energyConsumption = 1,
			functionality = "decoration",
			beautyValue = 10
		},
		Garden = {
			name = "花园",
			description = "绿色植物装饰区域",
			category = "装饰",
			icon = "🌳",
			baseSize = Vector3.new(6, 2, 6),
			maxLevel = 5,
			baseCost = 150,
			energyConsumption = 0,
			functionality = "decoration",
			beautyValue = 8
		},
		Statue = {
			name = "雕像",
			description = "威严的纪念雕像",
			category = "装饰",
			icon = "🗿",
			baseSize = Vector3.new(2, 6, 2),
			maxLevel = 3,
			baseCost = 500,
			energyConsumption = 0,
			functionality = "decoration",
			beautyValue = 15
		},
		LightTower = {
			name = "照明塔",
			description = "提供区域照明",
			category = "装饰",
			icon = "💡",
			baseSize = Vector3.new(2, 8, 2),
			maxLevel = 5,
			baseCost = 100,
			energyConsumption = 2,
			functionality = "lighting",
			beautyValue = 5
		}
	}
}

-- 建筑解锁条件
C.BUILDING_UNLOCK_CONDITIONS = {
	-- 生产建筑解锁条件
	Crusher = { tier = 0, credits = 0 },
	Generator = { tier = 0, credits = 100 },
	Assembler = { tier = 1, credits = 500 },
	Smelter = { tier = 1, credits = 800 },
	ToolForge = { tier = 1, credits = 1000 },
	
	-- 功能建筑解锁条件
	EnergyStation = { tier = 2, credits = 2000 },
	StorageWarehouse = { tier = 1, credits = 1500 },
	ResearchLab = { tier = 2, credits = 3000 },
	RobotFactory = { tier = 3, credits = 5000 },
	TeleportPad = { tier = 4, credits = 10000 },
	
	-- 基础设施解锁条件
	PowerLine = { tier = 1, credits = 200 },
	ConveyorBelt = { tier = 1, credits = 500 },
	Bridge = { tier = 2, credits = 1000 },
	
	-- 装饰建筑解锁条件
	Fountain = { tier = 1, credits = 800 },
	Garden = { tier = 0, credits = 300 },
	Statue = { tier = 2, credits = 2000 },
	LightTower = { tier = 1, credits = 400 }
}

-- 建筑升级成本公式
C.BUILDING_UPGRADE_FORMULA = {
	costMultiplier = 1.5, -- 每级成本增长倍数
	energyMultiplier = 1.2, -- 每级能耗增长倍数
	outputMultiplier = 1.3, -- 每级产出增长倍数
	beautyMultiplier = 1.1  -- 每级美观度增长倍数
}

-- 建筑放置规则
C.BUILDING_PLACEMENT_RULES = {
	minDistanceFromOthers = 2, -- 与其他建筑的最小距离
	maxDistanceFromPower = 20, -- 与电力源的最大距离
	requiresFlatGround = true, -- 是否需要平坦地面
	canOverlapTerrain = false, -- 是否可以重叠地形
	snapToGrid = true,         -- 是否对齐网格
	gridSize = 2               -- 网格大小
}

return C
