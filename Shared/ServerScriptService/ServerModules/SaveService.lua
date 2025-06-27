--------------------------------------------------------------------
-- ServerModules / SaveService.lua      ★ 仅保留这一份！
--------------------------------------------------------------------
local DataStoreService = game:GetService("DataStoreService")
local store = DataStoreService:GetDataStore("RobofusionTycoonData")

local M, sessions = {}, {} -- { [uid] = {data,key,last} }
local AUTO_INT = 60 -- 自动保存秒

----------------------------------------------------------------
function M:Load(plr, defaultData)
	local key = "Player_" .. plr.UserId
	local ok, d = pcall(store.GetAsync, store, key)
	if not ok or not d then
		d = table.clone(defaultData)
	end
	sessions[plr.UserId] = { data = d, key = key, last = 0 }
	return d, key
end

----------------------------------------------------------------
function M:Save(uid, dataTbl)
	local s = sessions[uid]
	if not s then
		return
	end
	s.data = dataTbl or s.data
	if os.clock() - s.last < 6 then
		return
	end -- 防洪
	pcall(store.SetAsync, store, s.key, s.data)
	s.last = os.clock()
end

----------------------------------------------------------------
-- 自动循环
----------------------------------------------------------------
task.spawn(function()
	while true do
		for uid in pairs(sessions) do
			M:Save(uid)
		end
		task.wait(AUTO_INT)
	end
end)

return M
