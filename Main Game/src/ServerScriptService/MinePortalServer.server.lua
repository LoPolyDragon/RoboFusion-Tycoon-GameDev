--------------------------------------------------------------------
-- MinePortalServer.lua   ★放在 ServerScriptService
--------------------------------------------------------------------
local Players          = game:GetService("Players")
local TeleportService  = game:GetService("TeleportService")
local DataStoreService = game:GetService("DataStoreService")
local RunService       = game:GetService("RunService")

----------------------------------------------------------------
local MINE_PLACE_ID  = 101306428432235        -- 你的 MineWorld PlaceId
local MAP_STORE      = DataStoreService:GetDataStore("MineServerMap")
local LIFE_SEC       = 6 * 60 * 60            -- 6 小时
----------------------------------------------------------------

local function dsKey(uid)
	return "UID_" .. tostring(uid)
end

----------------------------------------------------------------
-- 预留 / 复用玩家自己的服务器
----------------------------------------------------------------
local function ensureReserved(uid)
	local now = os.time()

	local ok, info = pcall(MAP_STORE.GetAsync, MAP_STORE, dsKey(uid))
	if ok and info and info.expires > now then
		return info.serverId, info.seed
	end

	-- 重新预订
	local serverId = TeleportService:ReserveServer(MINE_PLACE_ID)
	local seed     = Random.new():NextInteger(1, 2147483647)

	local data = {serverId = serverId, seed = seed, expires = now + LIFE_SEC}
	pcall(MAP_STORE.SetAsync, MAP_STORE, dsKey(uid), data)

	return serverId, seed
end

----------------------------------------------------------------
-- 1) 玩家加入主城时，后台预订一台私服
----------------------------------------------------------------
Players.PlayerAdded:Connect(function(plr)
	if RunService:IsStudio() then return end   -- Studio 不 reserve

	task.defer(function()
		ensureReserved(plr.UserId)             -- 异步，避免卡加载
	end)
end)

----------------------------------------------------------------
-- 2) 触碰传送门立即搬运（0.2 s 防抖）
----------------------------------------------------------------
local portalPart = workspace:WaitForChild("MinePortal"):WaitForChild("Teleport")
local debounce   = {}   -- [player] = true

portalPart.Touched:Connect(function(hit)
	local plr = Players:GetPlayerFromCharacter(hit.Parent)
	if not plr or debounce[plr] then return end
	debounce[plr] = true

	-- Studio 直接回本场
	if RunService:IsStudio() then
		TeleportService:Teleport(game.PlaceId, plr)
		task.delay(0.2, function() debounce[plr] = nil end)
		return
	end

	local serverId, seed = ensureReserved(plr.UserId)
	if not serverId then
		task.delay(0.2, function() debounce[plr] = nil end)
		return
	end

	local tpData = {
		uid      = plr.UserId,
		seed     = seed,
		returnTo = game.PlaceId
	}

	TeleportService:TeleportToPrivateServer(
		MINE_PLACE_ID,
		serverId,
		{plr},
		nil,         -- spawnName
		tpData
	)

	task.delay(0.2, function() debounce[plr] = nil end)
end)