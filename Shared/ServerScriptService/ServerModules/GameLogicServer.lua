--------------------------------------------------------------------
--  Shared  ·  GameLogicServer.lua
--  兼容 Main / Mine 两个 place，自动选择数据源
--------------------------------------------------------------------
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local DSS = game:GetService("DataStoreService")

local Const = require(RS.SharedModules.GameConstants)

--► 若矿区 place 已加载 PlayerDataService，则引用之
local PlayerDataService = game.ServerScriptService:FindFirstChild("PlayerDataService")
local PlayerData = PlayerDataService and require(PlayerDataService) or nil

--------------------------------------------------------------------
-- 内部状态
--------------------------------------------------------------------
local GL = {} -- 导出表
local SaveBridge = { Save = function() end } -- 由 MainServer 注入
local pdata = {} -- 主城专用存档缓存
local store = DSS:GetDataStore("RobofusionTycoonData")

--------------------------------------------------------------------
-- 小工具
--------------------------------------------------------------------
local function D(plr)
	return pdata[plr.UserId]
end -- 主城存档
local function ensureFields(t, proto)
	for k, v in pairs(proto) do
		if t[k] == nil then
			t[k] = (typeof(v) == "table") and table.clone(v) or v
		end
	end
end

--------------------------------------------------------------------
-- 初始化（MainServer 调用一次）
--------------------------------------------------------------------
function GL.Init(saveSvc, _errHub)
	SaveBridge = saveSvc or SaveBridge

	Players.PlayerAdded:Connect(function(plr)
		-- Mine Game 走 PlayerDataService 管理，不需要存到 pdata
		if PlayerData then
			return
		end

		local data = table.clone(Const.DEFAULT_DATA)
		local ok, saved = pcall(store.GetAsync, store, "Player_" .. plr.UserId)
		if ok and saved then
			data = saved
		end
		ensureFields(data, Const.DEFAULT_DATA)
		pdata[plr.UserId] = data
	end)

	Players.PlayerRemoving:Connect(function(plr)
		if PlayerData then
			return
		end
		local d = pdata[plr.UserId]
		if d then
			SaveBridge:Save(plr.UserId, d)
			pdata[plr.UserId] = nil
		end
	end)
end

--------------------------------------------------------------------
-- 数据源选择 -------------------------------------------------------
local function getInvTable(plr)
	if PlayerData then
		local info = PlayerData[plr.UserId]
		return info and info.Inventory
	else
		local d = D(plr)
		return d and d.Inventory
	end
end

--------------------------------------------------------------------
-- 基础 API ---------------------------------------------------------
function GL.GetPlayerData(plr)
	return PlayerData and PlayerData[plr.UserId] or D(plr)
end

GL.GetInventoryData = getInvTable
GL.GetInventoryDict = getInvTable -- 兼容旧引用

function GL.AddItem(plr, id, amt)
	local inv = getInvTable(plr)
	if not inv then
		return false
	end
	for _, slot in ipairs(inv) do
		if slot.itemId == id then
			slot.quantity += amt
			return true
		end
	end
	table.insert(inv, { itemId = id, quantity = amt })
	return true
end

function GL.RemoveItem(plr, id, amt)
	local inv = getInvTable(plr)
	if not inv then
		return false
	end
	for i, slot in ipairs(inv) do
		if slot.itemId == id then
			if slot.quantity < amt then
				return false
			end
			slot.quantity -= amt
			if slot.quantity <= 0 then
				table.remove(inv, i)
			end
			return true
		end
	end
	return false
end

--------------------------------------------------------------------
-- 资源 & 升级 ------------------------------------------------------
function GL.AddScrap(plr, n)
	local d = GL.GetPlayerData(plr)
	if d then
		d.Scrap += n
	end
end

function GL.UpgradeMachine(plr, name)
	local d = GL.GetPlayerData(plr)
	if not d then
		return
	end
	local lv = d.Upgrades[name .. "Level"] or 1
	local cost = 50 * lv ^ 2
	if d.Credits >= cost then
		d.Credits -= cost
		d.Upgrades[name .. "Level"] = lv + 1
	end
end

--------------------------------------------------------------------
-- Crusher / 其它机器 ----------------------------------------------
function GL.RunCrusher(plr, qty)
	local d = GL.GetPlayerData(plr)
	if not d then
		return false, "no data"
	end
	d.Scrap -= qty
	local gain = qty * 2
	d.Credits += gain
	return true, "+" .. gain
end

--------------------------------------------------------------------
-- Shell 购买 & 机器人出售 -----------------------------------------
local SHELL_COST = Const.SHELL_COST
local BOT_PRICE = Const.BOT_SELL_PRICE or {} -- Mine Game 用动态表时可能为空

local function randRusty()
	if Const.RUSTY_ROLL then
		return Const.RUSTY_ROLL[math.random(#Const.RUSTY_ROLL)]
	else -- 回退到 CommonBot 逻辑
		local cat = Const.COMMON_CATS[math.random(#Const.COMMON_CATS)]
		return cat .. "_CommonBot"
	end
end

function GL.GenerateShellBatch(plr, shellId, qty)
	local d = GL.GetPlayerData(plr)
	if not d then
		return false, "no data"
	end
	local unit = SHELL_COST[shellId]
	if not unit then
		return false, "unknown shell"
	end
	qty = math.max(1, math.floor(tonumber(qty) or 1))
	local need = unit * qty
	if d.Scrap < need then
		return false, "Not enough scrap"
	end
	d.Scrap -= need
	for _ = 1, qty do
		local id = (shellId == "RustyShell") and randRusty() or shellId
		GL.AddItem(plr, id, 1)
	end
	return true, "+" .. qty
end

function GL.ShipBots(plr, botId, qty)
	local price = BOT_PRICE[botId]
	if not price then
		return false, "unknown bot"
	end
	local d = GL.GetPlayerData(plr)
	if not d then
		return false, "no data"
	end
	if not GL.RemoveItem(plr, botId, qty) then
		return false, "not enough"
	end
	d.Credits += price * qty
	return true, "+" .. price * qty .. " Credits"
end

--------------------------------------------------------------------
-- Daily Sign‑in ---------------------------------------------------
local function isNewUTC(last, now)
	if not last then
		return true
	end
	local a, b = os.date("!*t", last), os.date("!*t", now)
	return a.year ~= b.year or a.yday ~= b.yday
end

function GL.ClaimDailySignIn(plr)
	local d = GL.GetPlayerData(plr)
	if not d then
		return false
	end
	local now = os.time()
	if not isNewUTC(d.LastSignInTime, now) then
		return false, d.SignInStreakDay
	end
	local cycle = #Const.DAILY_REWARDS
	local idx = (d.SignInStreakDay % cycle) + 1
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
	local d = GL.GetPlayerData(plr)
	if not d then
		return false
	end
	d.SignInStreakDay = (d.SignInStreakDay % #Const.DAILY_REWARDS) + 1
	return true
end

--------------------------------------------------------------------
-- Shell → Bot 组装 ------------------------------------------------
function GL.AssembleShell(plr, shellId, robotType)
	local rarity = Const.ShellRarity[shellId]
	if not rarity then
		return false, "unknown shell"
	end
	local map = Const.RobotKey[robotType or "Dig"]
	if not map then
		return false, "invalid type"
	end
	local botId = map[rarity]
	if not botId then
		return false, "invalid rarity"
	end
	if not GL.RemoveItem(plr, shellId, 1) then
		return false, "no shell"
	end
	GL.AddItem(plr, botId, 1)
	return true, botId
end

--------------------------------------------------------------------
-- 其它占位 ---------------------------------------------------------
function GL.GenerateBotShell() end
function GL.HatchEgg()
	return false, "no egg"
end
function GL.FuseBot()
	return false, "no fuse", nil
end

return GL
