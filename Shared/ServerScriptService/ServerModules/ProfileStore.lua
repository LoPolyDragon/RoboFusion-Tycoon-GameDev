-- ServerModules/ProfileStore.lua
local ProfileStore = {}
local profiles = {} -- [userId] = table

function ProfileStore:Get(userId)
	return profiles[userId]
end
function ProfileStore:Set(userId, tbl)
	profiles[userId] = tbl
end

return ProfileStore
