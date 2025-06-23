--------------------------------------------------------------------
--  ServerModules / MineService.lua     ★ 最小可用生成 + 刷新
--------------------------------------------------------------------
local Workspace        = game:GetService("Workspace")
local Players          = game:GetService("Players")
local ReplicatedStorage= game:GetService("ReplicatedStorage")

local Const            = require(ReplicatedStorage.SharedModules.GameConstants)

----------------------------------------------------------------
-- 参数（可以后调）
----------------------------------------------------------------
local CHUNK   = 20                       -- 每格 20 stud
local SIZE_XZ = 150                      -- 基座
local HEIGHT  = 300

local ORE_BY_DEPTH = {                   -- 深度阈值 → “矿石名”
	{ y =   0, ore = "Scrap"      },     -- 表面
	{ y = -40, ore = "IronOre"    },
	{ y = -80, ore = "BronzeOre"  },
	{ y =-140, ore = "GoldOre"    },
	{ y =-200, ore = "DiamondOre" },
	{ y =-250, ore = "TitaniumOre"},
	{ y =-280, ore = "UraniumOre" }
}

----------------------------------------------------------------
local MineService = {}
local mineFolder  = Instance.new("Folder")
mineFolder.Name   = "PrivateMines"
mineFolder.Parent = Workspace

----------------------------------------------------------------
-- 工具：给一个深度返回应当生成的矿石名
----------------------------------------------------------------
local function pickOre(y)
	for i = #ORE_BY_DEPTH, 1, -1 do
		if y <= ORE_BY_DEPTH[i].y then
			return ORE_BY_DEPTH[i].ore
		end
	end
	return "Scrap"
end

----------------------------------------------------------------
-- 生成单个矿区（全部 Part 直接塞进 model）
----------------------------------------------------------------
local function generateMine(plr, seed)
	local model = Instance.new("Model")
	model.Name  = plr.Name.."_Mine"
	model.Parent= mineFolder

	local rng   = Random.new(seed)
	local base  = Vector3.new(-SIZE_XZ/2, 0, -SIZE_XZ/2)

	for x = 0, SIZE_XZ, CHUNK do
		for z = 0, SIZE_XZ, CHUNK do
			-- 用噪声决定顶面高度（简单起步：扁平，后续换 Perlin）
			local top = 0
			-- 向下堆方块
			for y = 0, -HEIGHT, -CHUNK do
				-- 简化：30% 空洞
				if rng:NextNumber() < 0.3 then continue end

				local part = Instance.new("Part")
				part.Size          = Vector3.new(CHUNK, CHUNK, CHUNK)
				part.Anchored      = true
				part.Material      = Enum.Material.Slate
				part.Color         = Color3.fromRGB(90, 90, 90)
				part.Position      = base + Vector3.new(x + CHUNK/2, y - CHUNK/2, z + CHUNK/2)

				-- 矿石贴图 / 值
				local oreName      = pickOre(y)
				part.Name          = oreName
				local val          = Instance.new("IntValue")
				val.Name, val.Value= "OreAmount", 50
				val.Parent         = part

				part.Parent        = model
			end
		end
	end
	return model
end

----------------------------------------------------------------
-- Public：确保玩家有矿 & 如有需要刷新
----------------------------------------------------------------
function MineService:EnsureMine(plr, pdata)
	local mineData = pdata.PrivateMine or { seed = 0, lastRefresh = 0 }
	pdata.PrivateMine = mineData

	if mineData.seed == 0 then
		mineData.seed = math.random(1, 2^31-1)
	end

	------------------------------------------------------------
	-- 若离线 ≥ 5 min → 整块重新生成
	------------------------------------------------------------
	local NEED = (os.time() - (mineData.lastRefresh or 0)) >= 5*60
	local model = mineFolder:FindFirstChild(plr.Name.."_Mine")

	if NEED or not model then
		-- 删旧
		if model then model:Destroy() end
		model = generateMine(plr, mineData.seed)
		mineData.lastRefresh = os.time()
	end
end

----------------------------------------------------------------
-- 玩家退出时可选清理（省内存；不删也行）
----------------------------------------------------------------
Players.PlayerRemoving:Connect(function(plr)
	local m = mineFolder:FindFirstChild(plr.Name.."_Mine")
	if m then m:Destroy() end
end)

return MineService