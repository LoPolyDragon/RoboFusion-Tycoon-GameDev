--------------------------------------------------------------------
-- MineService.lua · 主城 & MineWorld 共用
--   Main Game  : 没有 MineGenerator ⇒ 只建文件夹，不生成方块
--   MineWorld : 有 MineGenerator   ⇒ 调用 Generate 真正铺矿
--------------------------------------------------------------------
local Workspace = game:GetService("Workspace")

------------------------------------------------------------------
-- ① 尝试获取 MineGenerator（仅 MineWorld 有）
------------------------------------------------------------------
local hasGen = script.Parent:FindFirstChild("MineGenerator")
local MineGenerator = hasGen and require(hasGen) or nil -- ← 条件 require

local MineService = {}

local function ensureMineTable(save)
	save.PrivateMine = save.PrivateMine or { seed = 0, lastRefresh = 0 }
	if save.PrivateMine.seed == 0 then
		save.PrivateMine.seed = math.random(1, 2 ^ 31 - 1)
	end
end

------------------------------------------------------------------
-- public · EnsureMine(player, saveTable)
------------------------------------------------------------------
function MineService:EnsureMine(plr, save)
	if type(save) ~= "table" then
		return
	end
	ensureMineTable(save)

	-- 1) Workspace.PrivateMines/Mine_<userId>
	local root = Workspace:FindFirstChild("PrivateMines")
	if not root then
		root = Instance.new("Folder")
		root.Name = "PrivateMines"
		root.Parent = Workspace
	end
	local folderName = ("Mine_%d"):format(plr.UserId)
	local mineFolder = root:FindFirstChild(folderName) or Instance.new("Folder", root)
	mineFolder.Name = folderName

	-- 2) 判定是否要刷新
	local needRefresh = (#mineFolder:GetChildren() == 0)
	local now = os.time()
	if now - (save.PrivateMine.lastRefresh or 0) > 5 * 60 then
		needRefresh = true
	end

	if not needRefresh then
		return
	end

	----------------------------------------------------------------
	-- 3) 生成 / 占位
	----------------------------------------------------------------
	mineFolder:ClearAllChildren()

	if MineGenerator then
		-- ★ MineWorld 环境：真正生成
		MineGenerator.Generate(mineFolder, save.PrivateMine.seed)
	else
		-- ★ Main Game 环境：只放一个占位 Folder，避免机器人报错
		local oreFolder = Instance.new("Folder")
		oreFolder.Name = "OreFolder"
		oreFolder.Parent = mineFolder
	end

	save.PrivateMine.lastRefresh = now
end

return MineService
