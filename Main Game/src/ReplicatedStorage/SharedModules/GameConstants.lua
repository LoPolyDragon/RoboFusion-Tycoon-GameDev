--------------------------------------------------------------------
--  GameConstants.lua   （客户端 / 服务器 通用常量与工具）
--------------------------------------------------------------------
local C = {}

--------------------------- 默认存档 -------------------------------
C.DEFAULT_DATA = {
	Scrap            = 0,
	Credits          = 0,
	RobotCount       = 0,
	SignInStreakDay  = 0,
	LastSignInTime   = 0,
	Upgrades         = {CrusherLevel=1,GeneratorLevel=1,AssemblerLevel=1,ShipperLevel=1},
	LastUseTime      = {Crusher=0,Generator=0, Assembler=0,Shipper=0},
	Inventory        = {},          -- 通用背包
	PrivateMine = {
		seed        = 0,          -- 整形随机种子
		lastRefresh = 0           -- 上次生成 UTC 秒
	}
}

------------------------ 机器等级 → 速度 ---------------------------
C.MachineInfo = {
	Crusher   = { [1]={speed=2}, [2]={speed=4}, [3]={speed=6}, [4]={speed=8}, [5]={speed=10} },
	Generator = { [1]={speed=1}, [2]={speed=2}, [3]={speed=3} },
	Assembler = { [1]={speed=1}, [2]={speed=2} },
	Shipper   = { [1]={speed=1}, [2]={speed=3}, [3]={speed=5} },
}

------------------------- 每日签到奖励 -----------------------------
C.DAILY_REWARDS = {
	[1]={type="Scrap",  amount=100},
	[2]={type="Silicon",amount=50},
	[3]={type="Credits",amount=20},
	[4]={type="Booster",amount=1},
	[5]={type="Decal",  amount=1},
	[6]={type="Eco",    amount=30},
	[7]={type="Ticket", amount=1},
}

------------------------ Shell 单价 -------------------------------
C.SHELL_COST = { RustyShell = 150, NeonCoreShell = 3000 }   -- 后续可继续补

--------------------------------------------------------------------
-- ★ 机器人类别系统
--------------------------------------------------------------------
--   缩写 → 中文/英文名称（UI 可用）
C.BOT_CATEGORIES = {
	MN = "Miner",
	TR = "Transporter",
	SM = "Smelter",
	BT = "Battle",
	SC = "Scout",
}

--   CommonBot 五种类别池（若有 Rare/Epic… 可再建表）
C.COMMON_CATS = { "MN","TR","SM","BT","SC" }

------------------------- 每日签到奖励（8 天循环） -------------------
C.DAILY_REWARDS = {
	[1]={type="Scrap",        amount=500 },
	[2]={type="Credits",      amount=1000},
	[3]={type="RustyShell",   amount=2   },
	[4]={type="WoodPick",     amount=1   },
	[5]={type="TitaniumOre",  amount=25  },
	[6]={type="EnergyCoreS",  amount=3   },
	[7]={type="NeonCoreShell",amount=1   },
	[8]={type="BONUS",        amount=0   },  -- VIP Bonus 占位
}

------------------------ 权重随机工具 ------------------------------
function C.pickByWeighted(list)
	local total = 0
	for _,o in ipairs(list) do total += o.weight end
	local r,acc = math.random(total),0
	for _,o in ipairs(list) do
		acc += o.weight
		if r <= acc then return o.value end
	end
end

return C