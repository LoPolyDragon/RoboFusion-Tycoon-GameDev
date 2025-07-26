-- ReplicatedStorage/SharedModules/BotTasks.lua
local Tasks = {}

----------------------------------------------------------------
-- 任务类型枚举
----------------------------------------------------------------
Tasks.Type = {
	-- 挖矿
	MINE = "MINE",
	-- 运货 / 采集 等后续可扩展
}

Tasks.AllPickaxes = { "WoodPick", "StonePick", "IronPick", "GoldPick", "DiamondPick" }

----------------------------------------------------------------
-- 简易工具：把 Ore Part → 名称
----------------------------------------------------------------
function Tasks.getOreName(part)
	return part and part.Name
end

return Tasks
