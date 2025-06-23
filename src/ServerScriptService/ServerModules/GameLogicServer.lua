--------------------------------------------------------------------
--  ServerModules/GameLogicServer.lua     ★ 完整功能版
--  兼容：Crusher / Generator / Assembler / Shipper / DailySign
--------------------------------------------------------------------
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService  = game:GetService("DataStoreService")

local Const             = require(ReplicatedStorage.SharedModules.GameConstants)

--------------------------------------------------------------------
-- 内部状态
--------------------------------------------------------------------
local GL            = {}                -- 唯一导出表
local SaveBridge    = { Save = function() end }  -- 由 MainServer 注入
local pdata         = {}                -- [uid] = 存档表
local store         = DataStoreService:GetDataStore("RobofusionTycoonData")

--------------------------------------------------------------------
-- 小工具
--------------------------------------------------------------------
local function D(p)  return pdata[p.UserId] end  -- 快捷取存档

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
		local data = table.clone(Const.DEFAULT_DATA)

		local ok, saved = pcall(store.GetAsync, store, "Player_" .. plr.UserId)
		if ok and saved then data = saved end
		ensureFields(data, Const.DEFAULT_DATA)

		pdata[plr.UserId] = data
	end)

	Players.PlayerRemoving:Connect(function(plr)
		local d = pdata[plr.UserId]
		if d then
			SaveBridge:Save(plr.UserId, d)
			pdata[plr.UserId] = nil
		end
	end)
end

--------------------------------------------------------------------
-- Bind / Unbind  (MainServer 在数据迁移后调用)
--------------------------------------------------------------------
function GL.BindProfile(plr, data)  pdata[plr.UserId] = data end
function GL.UnbindProfile(plr)
	local d = pdata[plr.UserId]
	if d then SaveBridge:Save(plr.UserId, d) end
	pdata[plr.UserId] = nil
end

--------------------------------------------------------------------
-- 基础背包 / 查询
--------------------------------------------------------------------
function GL.GetPlayerData(plr)     return D(plr) end
function GL.GetInventoryData(plr)  local d=D(plr); return d and d.Inventory end
GL.GetInventoryDict = GL.GetInventoryData  -- MainServer 直接引用

function GL.AddItem(plr, id, amt)
	local inv = GL.GetInventoryData(plr); if not inv then return false end
	for _, slot in ipairs(inv) do
		if slot.itemId == id then
			slot.quantity += amt;  return true
		end
	end
	table.insert(inv, { itemId = id, quantity = amt })
	return true
end

function GL.RemoveItem(plr, id, amt)
	local inv = GL.GetInventoryData(plr); if not inv then return false end
	for i, slot in ipairs(inv) do
		if slot.itemId == id then
			if slot.quantity < amt then return false end
			slot.quantity -= amt
			if slot.quantity <= 0 then table.remove(inv, i) end
			return true
		end
	end
	return false
end

--------------------------------------------------------------------
-- 基础资源
--------------------------------------------------------------------
function GL.AddScrap(plr, n)
	local d = D(plr); if d then d.Scrap += n end
end

--------------------------------------------------------------------
-- 升级机器
--------------------------------------------------------------------
function GL.UpgradeMachine(plr, name)
	local d = D(plr); if not d then return end
	local lv   = d.Upgrades[name .. "Level"] or 1
	local cost = 50 * lv ^ 2
	if d.Credits >= cost then
		d.Credits -= cost
		d.Upgrades[name .. "Level"] = lv + 1
	end
end

--------------------------------------------------------------------
-- Crusher
--------------------------------------------------------------------
function GL.RunCrusher(plr, qty)
	local d = D(plr); if not d then return false, "no data" end
	d.Scrap   -= qty
	local gain = qty * 2
	d.Credits += gain
	return true, "+" .. gain
end

--------------------------------------------------------------------
-- Shell 批量购买  (RustyShell ⇒ 随机五类 CommonBot)
--------------------------------------------------------------------
local SHELL_COST = Const.SHELL_COST          -- { RustyShell = 150, … }
local function getRandomCat()
	return Const.COMMON_CATS[ math.random(#Const.COMMON_CATS) ]
end

function GL.GenerateShellBatch(plr, shellId, qty)
	local d = D(plr); if not d then return false, "no data" end

	local unit = SHELL_COST[shellId]
	if not unit then return false, "unknown shell" end

	qty = math.max(1, math.floor(tonumber(qty) or 1))
	local need = unit * qty
	if d.Scrap < need then return false, "Not enough scrap" end

	d.Scrap -= need
	if shellId == "RustyShell" then
		for _ = 1, qty do
			local cat = getRandomCat()
			GL.AddItem(plr, cat .. "_CommonBot", 1)
		end
	else
		GL.AddItem(plr, shellId, qty)
	end
	return true, "+" .. qty
end

--------------------------------------------------------------------
-- Ship Bots
--------------------------------------------------------------------
local BOT_PRICE = {}               -- 价格字典，用 CommonBot 50 基准
for _, cat in ipairs(Const.COMMON_CATS) do
	BOT_PRICE[cat .. "_CommonBot"] = 50
end

function GL.ShipBots(plr, botId, qty)
	local d = D(plr); if not d then return false, "no data" end
	local price = BOT_PRICE[botId]
	if not price then return false, "unknown bot" end
	if not GL.RemoveItem(plr, botId, qty) then return false, "not enough" end
	d.Credits += price * qty
	return true, "+" .. price * qty .. " Credits"
end

--------------------------------------------------------------------
-- Daily Sign‑in  (UTC)
--------------------------------------------------------------------
local function isNewUTCDate(last, now)
	if not last then return true end
	local lt, nt = os.date("!*t", last), os.date("!*t", now)
	return (lt.year ~= nt.year) or (lt.yday ~= nt.yday)
end

function GL.ClaimDailySignIn(plr)
	local d = D(plr); if not d then return false end

	local now = os.time()
	if not isNewUTCDate(d.LastSignInTime, now) then
		return false, d.SignInStreakDay   -- 今天已领
	end

	local idx   = (d.SignInStreakDay % 8) + 1        -- 8 天循环
	local cfg   = Const.DAILY_REWARDS[idx]
	local typ   = cfg.type
	local amt   = cfg.amount

	-- VIP Bonus 例子（第 8 天）
	if idx == 8 and d.IsVIP then
		typ, amt = "BronzePick", 1
	end

	if typ == "Credits" or typ == "Scrap" then
		d[typ] = (d[typ] or 0) + amt
	else
		GL.AddItem(plr, typ, amt)
	end

	d.SignInStreakDay = idx
	d.LastSignInTime  = now
	
	print(("[DailySign] %s +%d %s"):format(plr.Name, cfg.amount, cfg.type))
	
	return true, idx
end

function GL.SkipMissedDay(plr)    -- 占位：付费补签
	local d = D(plr); if not d then return false end
	d.SignInStreakDay = (d.SignInStreakDay % 8) + 1
	return true
end

--------------------------------------------------------------------
-- 其它占位函数（防止 MainServer 报 nil）
--------------------------------------------------------------------
function GL.GenerateBotShell() end
function GL.HatchEgg()      return false, "no egg"    end
function GL.FuseBot()       return false, "no fuse", nil end
function GL.AssembleShell() return false, "no asm"    end

--------------------------------------------------------------------
return GL