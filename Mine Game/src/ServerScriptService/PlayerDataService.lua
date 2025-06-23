--------------------------------------------------------------------
-- PlayerDataService.lua  · demo 版，仅存于内存，不写 DataStore
--------------------------------------------------------------------
local Players = game:GetService("Players")
local Data = {}      -- [uid] = {Inventory = {...}, gold = 0, ...}

local DEFAULT_INV = {}       -- 空包
local DEFAULT_OTHER = 0

Players.PlayerAdded:Connect(function(plr)
	-- 真正项目这里应从 DataStore/ProfileService 载档
	Data[plr.UserId] = {
		Inventory = table.clone(DEFAULT_INV),
		gold      = DEFAULT_OTHER,
	}
end)

Players.PlayerRemoving:Connect(function(plr)
	-- 真正项目这里应保存 Data[plr.UserId] 到 DataStore
	Data[plr.UserId] = nil
end)

return Data