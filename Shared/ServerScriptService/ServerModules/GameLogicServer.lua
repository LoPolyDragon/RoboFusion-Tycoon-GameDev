--------------------------------------------------------------------
--  Shared · GameLogicServer.lua
--  同时兼容 Main‑Game 与 Mine‑Game 的存档 / 背包接口
--------------------------------------------------------------------
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local DSS = game:GetService("DataStoreService")

--★ 常量文件夹结构：SharedModules/GameConstants/{init,main,mine}.lua
local Const = require(RS.SharedModules.GameConstants)

--------------------------------------------------------------------
-- Mine‑Game 判定（是否存在 PlayerDataService）
--------------------------------------------------------------------
local PDScript = game.ServerScriptService:FindFirstChild("PlayerDataService")
local PlayerData = PDScript and require(PDScript) or nil

--------------------------------------------------------------------
-- 主城专用存档缓冲；矿区走 PlayerDataService，不进此表
--------------------------------------------------------------------
local GL = {} -- 本模块最终导出
local SaveBridge = { Save = function() end } -- MainServer 注入
local pdata = {} -- [uid] = 保存表
local store = DSS:GetDataStore("RobofusionTycoonData")

--------------------------------------------------------------------
-- ◇◇ 工具：clone / ensure / 数据选择 ◇◇ --------------------------
--------------------------------------------------------------------
local function cloneTab(t)
	if table.clone then
		return table.clone(t)
	end
	local c = {}
	for k, v in pairs(t) do
		c[k] = (typeof(v) == "table") and cloneTab(v) or v
	end
	return c
end

local function ensureFields(dst, proto)
	for k, v in pairs(proto) do
		if dst[k] == nil then
			dst[k] = (typeof(v) == "table") and cloneTab(v) or v
		end
	end
end

--- 当前 place 的"玩家总表"
local function D(plr)
	return PlayerData and PlayerData[plr.UserId] or pdata[plr.UserId]
end

--------------------------------------------------------------------
-- ◇◇ Init / Bind / Unbind ◇◇ -------------------------------------
--------------------------------------------------------------------
-- Tier管理器延迟加载
local TierManager = nil

function GL.Init(saveSvc)
	SaveBridge = saveSvc or SaveBridge
	if PlayerData then
		return
	end -- Mine‑Game 不再自行保存
	
	-- 初始化Tier管理器
	TierManager = require(script.Parent.TierManager)
	TierManager.Init(GL)

	Players.PlayerAdded:Connect(function(p)
		local data = cloneTab(Const.DEFAULT_DATA)
		local ok, saved = pcall(store.GetAsync, store, ("Player_%d"):format(p.UserId))
		if ok and saved then
			data = saved
		end
		ensureFields(data, Const.DEFAULT_DATA)
		pdata[p.UserId] = data
	end)

	Players.PlayerRemoving:Connect(function(p)
		local d = pdata[p.UserId]
		if d then
			SaveBridge:Save(p.UserId, d)
			pdata[p.UserId] = nil
		end
	end)
end

function GL.BindProfile(plr, tbl)
	pdata[plr.UserId] = tbl
end
function GL.UnbindProfile(plr)
	local d = pdata[plr.UserId]
	if d then
		SaveBridge:Save(plr.UserId, d)
	end
	pdata[plr.UserId] = nil
end

--------------------------------------------------------------------
-- ◇◇ Inventory helpers ◇◇ ----------------------------------------
--------------------------------------------------------------------
local function ensureInv(plr) -- 始终返回一张表
	local d = D(plr)
	if not d then
		return nil
	end
	if not d.Inventory then
		d.Inventory = {}
	end
	return d.Inventory
end

local function internalGetInv(plr) -- 旧接口引用
	return ensureInv(plr)
end

--------------------------------------------------------------------
-- ◇◇ 对外查询接口 (向后兼容三种名字) ◇◇ --------------------------
--------------------------------------------------------------------
function GL.GetPlayerData(plr)
	return D(plr)
end
GL.GetInventoryData = internalGetInv
GL.GetInventoryDict = internalGetInv
GL.GetInventory = internalGetInv -- legacy

--------------------------------------------------------------------
-- ◇◇ 背包增删 ◇◇ -------------------------------------------------
--------------------------------------------------------------------
function GL.AddItem(plr, id, n)
	local inv = ensureInv(plr)
	if not inv then
		return false
	end
	for _, slot in ipairs(inv) do
		if slot.itemId == id then
			slot.quantity += n
			-- 主动推送背包刷新
			RS.RemoteEvents.UpdateInventoryEvent:FireClient(plr, GL.GetInventoryDict(plr))
			
			-- 更新Tier进度
			if TierManager then
				TierManager.UpdateCollectionProgress(plr, id, n)
			end
			
			return true
		end
	end
	table.insert(inv, { itemId = id, quantity = n })
	-- 主动推送背包刷新
	RS.RemoteEvents.UpdateInventoryEvent:FireClient(plr, GL.GetInventoryDict(plr))
	
	-- 更新Tier进度
	if TierManager then
		TierManager.UpdateCollectionProgress(plr, id, n)
	end
	
	return true
end

function GL.RemoveItem(plr, id, n)
	local inv = internalGetInv(plr)
	if not inv then
		return false
	end
	for i, slot in ipairs(inv) do
		if slot.itemId == id then
			if slot.quantity < n then
				return false
			end
			slot.quantity -= n
			if slot.quantity <= 0 then
				table.remove(inv, i)
			end
			-- 主动推送背包刷新
			RS.RemoteEvents.UpdateInventoryEvent:FireClient(plr, GL.GetInventoryDict(plr))
			return true
		end
	end
	return false
end

function GL.UpdateInventorySlot(plr, slot)
	local inv = ensureInv(plr)
	for _, s in ipairs(inv) do
		if s == slot then
			-- slot 已经是引用，直接修改即可
			return true
		end
	end
	return false
end

--------------------------------------------------------------------
-- ◇◇ 资源 / 升级 & 机器 ◇◇ ---------------------------------------
--------------------------------------------------------------------

function GL.AddCredits(plr, n)
	local d = D(plr)
	if d then
		d.Credits += n
	end
end

function GL.UpgradeMachine(plr, name)
	local save = GL.GetPlayerData(plr)
	local up = save.Upgrades or {}
	local level = up[name .. "Level"] or 1
	local targetLevel = level + 1
	
	if level >= 10 then
		return false, "Max level"
	end

	-- 检查Tier限制
	if TierManager then
		local canUpgrade, message = TierManager.CanUpgradeBuilding(plr, name, targetLevel)
		if not canUpgrade then
			return false, message
		end
	end

	local cost = Const.BUILDING_UPGRADE_COST[name] and Const.BUILDING_UPGRADE_COST[name][level + 1]
	if not cost then
		return false, "Invalid building"
	end
	if save.Credits < cost then
		return false, "Not enough Credits"
	end

	save.Credits = save.Credits - cost
	up[name .. "Level"] = targetLevel
	
	-- 更新Tier进度
	if TierManager then
		TierManager.UpdateBuildingLevelProgress(plr, targetLevel)
	end
	
	return true, "Upgraded to Lv." .. targetLevel
end

function GL.RunCrusher(plr, qty)
	local d = D(plr)
	if not d then
		return false, "no data"
	end
	d.Scrap -= qty
	local gain = qty * 2
	d.Credits += gain
	return true, "+" .. gain
end

--------------------------------------------------------------------
-- ◇◇ Shell 购买 / Bot 出售 ◇◇ ------------------------------------
--------------------------------------------------------------------
local SHELL_COST = Const.SHELL_COST
local BOT_PRICE = Const.BOT_SELL_PRICE or {}

local function randRusty()
	return (Const.RUSTY_ROLL and Const.RUSTY_ROLL[math.random(#Const.RUSTY_ROLL)])
		or (Const.COMMON_CATS[math.random(#Const.COMMON_CATS)] .. "_CommonBot")
end

function GL.GenerateShellBatch(plr, shellId, qty)
	local d = D(plr)
	if not d then
		return false, "no data"
	end
	local unit = SHELL_COST[shellId]
	if not unit then
		return false, "unknown"
	end
	qty = math.max(1, math.floor(tonumber(qty) or 1))
	local need = unit * qty
	if d.Scrap < need then
		return false, "no scrap"
	end
	d.Scrap -= need
	for _ = 1, qty do
		-- 所有Shell都应该添加Shell到库存，符合GDD设计
		GL.AddItem(plr, shellId, 1)
	end
	return true, "+" .. qty .. " " .. shellId
end

function GL.ShipBots(plr, botId, qty)
	local price = BOT_PRICE[botId]
	if not price then
		return false, "unknown"
	end
	local d = D(plr)
	if not d then
		return false, "no data"
	end
	if not GL.RemoveItem(plr, botId, qty) then
		return false, "no stock"
	end
	d.Credits += price * qty
	return true, "+" .. price * qty
end

--------------------------------------------------------------------
-- ◇◇ Daily Sign‑in ◇◇ -------------------------------------------
--------------------------------------------------------------------
local function isUTCNew(last, now)
	if not last then
		return true
	end
	local a, b = os.date("!*t", last), os.date("!*t", now)
	return a.year ~= b.year or a.yday ~= b.yday
end

function GL.ClaimDailySignIn(plr)
	local d = D(plr)
	if not d then
		return false
	end
	local now = os.time()
	if not isUTCNew(d.LastSignInTime, now) then
		return false, d.SignInStreakDay
	end
	local idx = (d.SignInStreakDay % #Const.DAILY_REWARDS) + 1
	local cfg = Const.DAILY_REWARDS[idx]
	local typ, amt = cfg.type, cfg.amount
	if idx == 8 and d.IsVIP then
		typ, amt = "BronzePick", 1
	end
	if typ == "Credits" or typ == "Scrap" then
		d[typ] += amt
	else
		GL.AddItem(plr, typ, amt)
	end
	d.SignInStreakDay, d.LastSignInTime = idx, now
	return true, idx
end
function GL.SkipMissedDay(plr)
	local d = D(plr)
	if not d then
		return false
	end
	d.SignInStreakDay = (d.SignInStreakDay % #Const.DAILY_REWARDS) + 1
	return true
end

--------------------------------------------------------------------
-- ◇◇ Shell → Bot 组装 ◇◇ ----------------------------------------
--------------------------------------------------------------------
function GL.AssembleShell(plr, shellId, robotType)
	local rarity = Const.ShellRarity[shellId]
	if not rarity then
		return false, "unk shell"
	end
	local map = Const.RobotKey[robotType or "Dig"]
	local botId = map and map[rarity]
	if not botId then
		return false, "bad type"
	end
	if not GL.RemoveItem(plr, shellId, 1) then
		return false, "no shell"
	end
	GL.AddItem(plr, botId, 1)
	return true, botId
end

--------------------------------------------------------------------
-- ◇◇ 占位 (兼容旧脚本) ◇◇ ----------------------------------------
--------------------------------------------------------------------
function GL.GenerateBotShell() end
function GL.HatchEgg()
	return false, "no egg"
end
function GL.FuseBot()
	return false, "no fuse", nil
end

function GL.GetBuildingQueueLimit(plr, name)
	local save = GL.GetPlayerData(plr)
	local up = save.Upgrades or {}
	local level = up[name .. "Level"] or 1
	return Const.BUILDING_UPGRADE_DATA.QueueLimit[level] or 1
end

-- 获取建筑属性（速度、范围等）
function GL.GetBuildingStats(plr, buildingType)
	local save = GL.GetPlayerData(plr)
	local up = save.Upgrades or {}
	local level = up[buildingType .. "Level"] or 1
	
	local buildingData = Const.BUILDING_UPGRADE_DATA[buildingType]
	if not buildingData then
		return { level = level, queueLimit = Const.BUILDING_UPGRADE_DATA.QueueLimit[level] or 1 }
	end
	
	local stats = { level = level, queueLimit = Const.BUILDING_UPGRADE_DATA.QueueLimit[level] or 1 }
	
	-- 添加建筑特定属性
	for statName, statArray in pairs(buildingData) do
		if statName ~= "description" and type(statArray) == "table" then
			stats[statName] = statArray[level] or statArray[#statArray]
		end
	end
	
	return stats
end

-- 获取建筑升级预览信息
function GL.GetBuildingUpgradePreview(plr, buildingType)
	local save = GL.GetPlayerData(plr)
	local up = save.Upgrades or {}
	local currentLevel = up[buildingType .. "Level"] or 1
	local nextLevel = currentLevel + 1
	
	if nextLevel > 10 then
		return nil -- 已达最高等级
	end
	
	local cost = Const.BUILDING_UPGRADE_COST[buildingType] and Const.BUILDING_UPGRADE_COST[buildingType][nextLevel]
	if not cost then
		return nil -- 无效建筑类型
	end
	
	local currentStats = GL.GetBuildingStats(plr, buildingType)
	local buildingData = Const.BUILDING_UPGRADE_DATA[buildingType]
	
	local preview = {
		currentLevel = currentLevel,
		nextLevel = nextLevel,
		cost = cost,
		canAfford = (save.Credits or 0) >= cost,
		currentStats = currentStats,
		nextStats = {}
	}
	
	-- 计算下一级的属性
	if buildingData then
		for statName, statArray in pairs(buildingData) do
			if statName ~= "description" and type(statArray) == "table" then
				preview.nextStats[statName] = statArray[nextLevel] or statArray[#statArray]
			end
		end
	end
	
	-- 下一级队列上限
	preview.nextStats.queueLimit = Const.BUILDING_UPGRADE_DATA.QueueLimit[nextLevel] or Const.BUILDING_UPGRADE_DATA.QueueLimit[#Const.BUILDING_UPGRADE_DATA.QueueLimit]
	
	return preview
end

--------------------------------------------------------------------
-- ◇◇ Tier系统集成 ◇◇ -------------------------------------------
--------------------------------------------------------------------

-- 添加Scrap时更新Tier进度
function GL.AddScrap(plr, n)
	local d = D(plr)
	if d then
		d.Scrap += n
		-- 更新Tier进度
		if TierManager then
			TierManager.UpdateCollectionProgress(plr, "scrap", n)
		end
	end
end


-- 获取Tier相关信息的函数
function GL.GetTierInfo(plr)
	if not TierManager then
		return nil
	end
	return TierManager.GetCurrentTierInfo(plr)
end

function GL.GetNextTierProgress(plr)
	if not TierManager then
		return nil
	end
	return TierManager.GetNextTierProgress(plr)
end

function GL.GetAllTiersOverview(plr)
	if not TierManager then
		return {}
	end
	return TierManager.GetAllTiersOverview(plr)
end

-- 检查工具和建筑解锁状态
function GL.IsToolUnlocked(plr, toolType)
	if not TierManager then
		return true
	end
	return TierManager.IsToolUnlocked(plr, toolType)
end

function GL.IsBuildingUnlocked(plr, buildingType)
	if not TierManager then
		return true
	end
	return TierManager.IsBuildingUnlocked(plr, buildingType)
end

-- 手动标记教程完成
function GL.MarkTutorialComplete(plr)
	if TierManager then
		TierManager.MarkTutorialComplete(plr)
	end
end

-- 更新制作进度
function GL.UpdateCraftingProgress(plr, itemType, amount)
	if TierManager then
		TierManager.UpdateCraftingProgress(plr, itemType, amount)
	end
end

return GL
