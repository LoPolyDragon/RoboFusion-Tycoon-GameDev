--------------------------------------------------------------------
-- PlayerDataService.lua    生产版 · DataStore 直读
--------------------------------------------------------------------
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local PROFILE_DS = DataStoreService:GetDataStore("RobofusionTycoonData")

local DEFAULT = require(game.ReplicatedStorage.SharedModules.GameConstants).DEFAULT_DATA

local Data = {} -- [uid] = profile table  (同主城)

local function deepFill(t, proto)
	for k, v in pairs(proto) do
		if t[k] == nil then
			t[k] = (typeof(v) == "table") and table.clone(v) or v
		elseif typeof(v) == "table" then
			deepFill(t[k], v)
		end
	end
end

Players.PlayerAdded:Connect(function(plr)
	local ok, saved = pcall(PROFILE_DS.GetAsync, PROFILE_DS, "Player_" .. plr.UserId)
	local profile = ok and saved or table.clone(DEFAULT)
	deepFill(profile, DEFAULT)
	Data[plr.UserId] = profile
end)

Players.PlayerRemoving:Connect(function(plr)
	local prof = Data[plr.UserId]
	if prof then
		pcall(PROFILE_DS.SetAsync, PROFILE_DS, "Player_" .. plr.UserId, prof)
		Data[plr.UserId] = nil
	end
end)

return Data -- 供 GameLogicServer 直接 require
