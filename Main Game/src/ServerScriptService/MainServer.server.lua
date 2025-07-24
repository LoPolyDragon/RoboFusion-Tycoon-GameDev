--========================================================
-- MainServer.lua   （ServerScriptService/MainServer.lua）
--========================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

----------------------------------------------------------
-- ① 统一后端服务  (★ Rojo 友好：全部用 script.Parent)
----------------------------------------------------------
local ServerModules = script.Parent:WaitForChild("ServerModules")

local GameLogic = require(ServerModules.GameLogicServer)
local SaveService = require(ServerModules.SaveService)
local ErrorHub = require(ServerModules.ErrorHub)
local DEFAULT_DATA = require(ReplicatedStorage.SharedModules.GameConstants).DEFAULT_DATA

local MineService = require(ServerModules.MineService) -- ★ 路径已对齐

-- 加载能量系统
local EnergyManager = require(ServerModules.EnergyManager)

----------------------------------------------------------
-- ② RemoteEvents / RemoteFunctions
----------------------------------------------------------
local RE = ReplicatedStorage:WaitForChild("RemoteEvents")
local RF = ReplicatedStorage:WaitForChild("RemoteFunctions")

-- Events
local CollectScrapEvt = RE:WaitForChild("CollectScrapEvent")
local GenerateBotEvt = RE:WaitForChild("GenerateBotEvent")
local ShipBotEvt = RE:WaitForChild("ShipBotEvent")
local UpgradeMachineEvt = RE:WaitForChild("UpgradeMachineEvent")
local GenShellEvt = RE:WaitForChild("GenerateShellEvent")
local HatchEggEvt = RE:WaitForChild("HatchEggEvent")
local FuseBotEvt = RE:WaitForChild("FuseBotEvent")
local AssembleShellEvt = RE:WaitForChild("AssembleShellEvent")
local AddItemEvt = RE:WaitForChild("AddItemEvent")
local UpdateInvEvt = RE:WaitForChild("UpdateInventoryEvent")
local DailySignEvt = RE:WaitForChild("DailySignInEvent")
local SkipDayEvt = RE:WaitForChild("SkipMissedDayEvent")
local OpenCrusherUIEvt = RE:WaitForChild("OpenCrusherUIEvent")
local CrushScrapEvt = RE:WaitForChild("CrushScrapEvent")
local PopupDailyEvt = RE:WaitForChild("DailySignInPopupEvent")
local DailyPopupEvt = RE:WaitForChild("DailySignInPopupEvent")
local DailyClaimEvt = RE:WaitForChild("DailySignInEvent")
local SkipMissEvt = RE:WaitForChild("SkipMissedDayEvent")
local TPEvent = RE:WaitForChild("TeleportToMineEvent")

-- 能量站事件
local EnergyStationEvt = RE:FindFirstChild("EnergyStationEvent")
if not EnergyStationEvt then
    EnergyStationEvt = Instance.new("RemoteEvent")
    EnergyStationEvt.Name = "EnergyStationEvent"
    EnergyStationEvt.Parent = RE
end

-- Functions
local GetUpgradeInfoF = RF:WaitForChild("GetUpgradeInfoFunction")
local GetInvFunc = RF:WaitForChild("GetInventoryFunction")
local GetPlayerDataF = RF:WaitForChild("GetPlayerDataFunction")

local DevProductId_SkipSign = 3302060423

----------------------------------------------------------
-- ③ 初始化业务模块
----------------------------------------------------------
GameLogic.Init(SaveService, ErrorHub)

-- 初始化能量系统
task.spawn(function()
    task.wait(2) -- 等待其他系统加载
    EnergyManager.Initialize()
    
    -- 自动注册现有机器人和能量站
    local function isRobotModel(obj)
        -- 检查多种可能的机器人标识方式
        if obj:GetAttribute("Type") == "Robot" then
            return true
        end
        
        -- 检查名称中是否包含机器人关键词
        local name = obj.Name:lower()
        if name:find("robot") or name:find("bot") or name:find("机器人") then
            return true
        end
        
        -- 检查是否有机器人相关的属性或子对象
        if obj:GetAttribute("RobotType") then
            return true
        end
        
        -- 检查是否有Owner属性（通常机器人会有Owner）
        if obj:GetAttribute("Owner") then
            return true
        end
        
        return false
    end
    
    for _, obj in pairs(workspace:GetChildren()) do
        if obj:IsA("Model") then
            if isRobotModel(obj) then
                local robotType = obj:GetAttribute("RobotType") or "MN"
                EnergyManager.RegisterRobot(obj, robotType)
                print("[MainServer] 发现并注册机器人:", obj.Name)
            elseif obj:GetAttribute("Type") == "EnergyStation" then
                local level = obj:GetAttribute("Level") or 1
                EnergyManager.RegisterEnergyStation(obj, level)
            end
        end
    end
    
    -- 监听新的机器人和能量站
    workspace.ChildAdded:Connect(function(child)
        if child:IsA("Model") then
            task.wait(0.1) -- 等待属性设置
            if isRobotModel(child) then
                local robotType = child:GetAttribute("RobotType") or "MN"
                EnergyManager.RegisterRobot(child, robotType)
                print("[MainServer] 新机器人加入:", child.Name)
            elseif child:GetAttribute("Type") == "EnergyStation" then
                local level = child:GetAttribute("Level") or 1
                EnergyManager.RegisterEnergyStation(child, level)
            end
        end
    end)
    
    workspace.ChildRemoved:Connect(function(child)
        if child:IsA("Model") then
            if isRobotModel(child) then
                EnergyManager.UnregisterRobot(child)
            elseif child:GetAttribute("Type") == "EnergyStation" then
                EnergyManager.UnregisterEnergyStation(child)
            end
        end
    end)
    
    print("[MainServer] 能量系统已启动")
end)

local function tryPopup(plr, data)
	local now = os.time()
	local last = data.LastSignInTime
	local function isNewUTCDate()
		if not last then
			return true
		end
		local a, b = os.date("!*t", last), os.date("!*t", now)
		return (a.year ~= b.year) or (a.yday ~= b.yday)
	end

	if isNewUTCDate() then
		local nextIdx = (data.SignInStreakDay % 8) + 1
		DailyPopupEvt:FireClient(plr, nextIdx) -- 客户端弹框
	end
end

----------------------------------------------------------
-- ④ 玩家进 / 出
----------------------------------------------------------
Players.PlayerAdded:Connect(function(plr)
	----------------------------------------------------------------
	-- ① 载档
	----------------------------------------------------------------
	local data, profile = SaveService:Load(plr, DEFAULT_DATA)
	if not data then
		plr:Kick("Data load failed, please re‑join.")
		return
	end

	----------------------------------------------------------------
	-- ② 数据迁移（一次性）
	--    把旧版 BotInventory / ShellInventory 合并进统一 Inventory
	----------------------------------------------------------------
	local inv = data.Inventory or {}
	-- ★ 如果是字典，就先转成数组，方便后面 UI 读取
	local function push(id, qty)
		if qty and qty > 0 then
			table.insert(inv, { itemId = id, quantity = qty })
		end
	end

	if type(data.BotInventory) == "table" then
		for id, qty in pairs(data.BotInventory) do
			push(id, qty)
		end
		data.BotInventory = nil -- 清掉旧字段
	end
	if type(data.ShellInventory) == "table" then
		for id, qty in pairs(data.ShellInventory) do
			push(id, qty)
		end
		data.ShellInventory = nil
	end
	data.Inventory = inv -- 写回

	------------------------------------------------------------
	-- ③‑b  如果 UTC 已跨天 ⇒ 弹签到 UI
	------------------------------------------------------------
	local function isNewUTCDate(last, now)
		if not last then
			return true
		end
		local a, b = os.date("!*t", last), os.date("!*t", now)
		return a.year ~= b.year or a.yday ~= b.yday
	end
	if isNewUTCDate(data.LastSignInTime, os.time()) then
		PopupDailyEvt:FireClient(plr, (data.SignInStreakDay % 8) + 1)
	end

	----------------------------------------------------------------
	-- ③ 正式绑定 & 推送背包
	----------------------------------------------------------------
	GameLogic.BindProfile(plr, data, profile)

	-- ★ 保证有矿 / 刷新
	MineService:EnsureMine(plr, data)

	ReplicatedStorage.RemoteEvents.UpdateInventoryEvent:FireClient(plr, GameLogic.GetInventoryDict(plr))
end)

Players.PlayerRemoving:Connect(function(plr)
	GameLogic.UnbindProfile(plr) -- 内部 SaveService:Save
end)

----------------------------------------------------------
-- ⑤ 轻量级冷却
----------------------------------------------------------
local cooldowns = {}
local function onCD(uid, key, gap)
	local now = os.clock()
	local t = cooldowns[uid] or {}
	cooldowns[uid] = t
	if (now - (t[key] or 0)) < gap then
		return false
	end
	t[key] = now
	return true
end

----------------------------------------------------------
-- ⑥ RemoteEvents 处理
----------------------------------------------------------
CollectScrapEvt.OnServerEvent:Connect(function(p, amt)
	if typeof(amt) ~= "number" or not onCD(p.UserId, "collect", 1) then
		return
	end
	GameLogic.AddScrap(p, math.clamp(amt, 1, 5))
end)

GenerateBotEvt.OnServerEvent:Connect(function(p, cost)
	if typeof(cost) ~= "number" or not onCD(p.UserId, "genShell", 1.5) then
		return
	end
	GameLogic.GenerateBotShell(p, math.clamp(cost, 1, 50))
end)

ShipBotEvt.OnServerEvent:Connect(function(p, botId, qty)
	if typeof(botId) ~= "string" or typeof(qty) ~= "number" then
		return
	end
	qty = math.floor(qty)
	if qty <= 0 or qty > 1000 or not onCD(p.UserId, "ship", 2) then
		return
	end

	local ok, msg = GameLogic.ShipBots(p, botId, qty)
	ShipBotEvt:FireClient(p, ok, msg)
	if ok then
		UpdateInvEvt:FireClient(p, GameLogic.GetInventoryDict(p))
	end
end)

UpgradeMachineEvt.OnServerEvent:Connect(function(plr, name)
	local ok, msg = GameLogic.UpgradeMachine(plr, name)
	UpgradeMachineEvt:FireClient(plr, ok, msg)
end)

SkipDayEvt.OnServerEvent:Connect(GameLogic.SkipMissedDay)

------------------------------------------------------------------
-- GenerateShellEvent  (客户端传 shellId, qty)
------------------------------------------------------------------
GenShellEvt.OnServerEvent:Connect(function(plr, shellId, qty)
	local ok, msg = GameLogic.GenerateShellBatch(plr, shellId, qty)
	GenShellEvt:FireClient(plr, ok, msg)
	if ok then
		UpdateInvEvt:FireClient(plr, GameLogic.GetInventoryDict(plr))
	end
end)

HatchEggEvt.OnServerEvent:Connect(function(p, id)
	local ok, res = GameLogic.HatchEgg(p, id)
	HatchEggEvt:FireClient(p, ok, res)
	UpdateInvEvt:FireClient(p, GameLogic.GetInventoryDict(p))
end)

FuseBotEvt.OnServerEvent:Connect(function(p, ids)
	local ok, msg, bot = GameLogic.FuseBot(p, ids)
	FuseBotEvt:FireClient(p, ok, msg, bot)
	UpdateInvEvt:FireClient(p, GameLogic.GetInventoryDict(p))
end)

AddItemEvt.OnServerEvent:Connect(function(p, id, n)
	if GameLogic.AddItem(p, id, n) then
		UpdateInvEvt:FireClient(p, GameLogic.GetInventoryDict(p))
	end
end)

AssembleShellEvt.OnServerEvent:Connect(function(p, shell, qty)
	qty = math.max(1, math.floor(qty or 1))
	local results = {}
	local totalSuccess = 0
	
	for i = 1, qty do
		-- 随机选择Dig或Build (50/50概率)
		local robotType = (math.random() < 0.5) and "Dig" or "Build"
		local ok, msg = GameLogic.AssembleShell(p, shell, robotType)
		if ok then
			totalSuccess = totalSuccess + 1
			table.insert(results, msg)  -- msg是机器人 ID
		else
			break  -- 如果失败就停止
		end
	end
	
	local success = totalSuccess > 0
	local message = success and string.format("Assembled %d robots: %s", totalSuccess, table.concat(results, ", ")) or "Failed to assemble"
	AssembleShellEvt:FireClient(p, success, message)
	UpdateInvEvt:FireClient(p, GameLogic.GetInventoryDict(p))
end)

DailySignEvt.OnServerEvent:Connect(function(p)
	local ok, day = GameLogic.ClaimDailySignIn(p)
	DailySignEvt:FireClient(p, ok, day)
	if ok then
		UpdateInvEvt:FireClient(p, GameLogic.GetInventoryDict(p))
	end
end)

SkipDayEvt.OnServerEvent:Connect(function(p)
	local ok = GameLogic.SkipMissedDay(p)
	SkipDayEvt:FireClient(p, ok)
end)

------------------------------------------------------------------
-- Daily Sign‑in
------------------------------------------------------------------
DailySignEvt.OnServerEvent:Connect(function(plr)
	local ok, idx = GameLogic.ClaimDailySignIn(plr)
	DailySignEvt:FireClient(plr, ok, idx)
	if ok then
		UpdateInvEvt:FireClient(plr, GameLogic.GetInventoryDict(plr))
	end
end)

SkipDayEvt.OnServerEvent:Connect(function(plr)
	local ok = GameLogic.SkipMissedDay(plr)
	SkipDayEvt:FireClient(plr, ok)
	if ok then
		UpdateInvEvt:FireClient(plr, GameLogic.GetInventoryDict(plr))
	end
end)

------------------------------------------------------------------
-- 能量站事件处理
------------------------------------------------------------------
EnergyStationEvt.OnServerEvent:Connect(function(plr, action, stationModel, ...)
	if action == "CHARGE_ROBOT" then
		local robotModel, energyAmount = ...
		if EnergyManager then
			local success, message = EnergyManager.ChargeRobotWithCredits(plr, robotModel, energyAmount)
			EnergyStationEvt:FireClient(plr, "CHARGE_RESULT", success, message)
		end
	elseif action == "UPGRADE_STATION" then
		-- 能量站升级逻辑（简化版）
		if stationModel and stationModel:GetAttribute("Type") == "EnergyStation" then
			local currentLevel = stationModel:GetAttribute("Level") or 1
			if currentLevel < 5 then
				local upgradeCost = currentLevel * 500
				local playerData = GameLogic.GetPlayerData(plr)
				
				if playerData and (playerData.Credits or 0) >= upgradeCost then
					-- 扣除费用
					GameLogic.AddCredits(plr, -upgradeCost)
					
					-- 升级能量站
					local newLevel = currentLevel + 1
					stationModel:SetAttribute("Level", newLevel)
					
					-- 重新注册到能量系统
					if EnergyManager then
						EnergyManager.UnregisterEnergyStation(stationModel)
						EnergyManager.RegisterEnergyStation(stationModel, newLevel)
					end
					
					EnergyStationEvt:FireClient(plr, "UPGRADE_RESULT", true, "升级成功!")
				else
					EnergyStationEvt:FireClient(plr, "UPGRADE_RESULT", false, "Credits不足")
				end
			else
				EnergyStationEvt:FireClient(plr, "UPGRADE_RESULT", false, "已达最高等级")
			end
		end
	end
end)
------------------------------------------------------------------
-- Crusher UI：粉碎 Scrap
------------------------------------------------------------------
CrushScrapEvt.OnServerEvent:Connect(function(plr, qty)
	qty = tonumber(qty) or 0
	if qty <= 0 then
		return
	end

	local ok, msg = GameLogic.RunCrusher(plr, qty)
	CrushScrapEvt:FireClient(plr, ok, msg or (ok and "Done" or "Failed"))

	if ok then
		UpdateInvEvt:FireClient(plr, GameLogic.GetInventoryDict(plr))
	end
	print("[DEBUG] Crusher result", plr.Name, ok, msg)
end)

----------------------------------------------------------
-- ⑦ RemoteFunctions
----------------------------------------------------------
-- ★ 修补：加载未完成时返回空表而非 nil，避免客户端报空
GetInvFunc.OnServerInvoke = function(p)
	return GameLogic.GetInventoryDict(p) or {}
end

local speedTbl = {
	Crusher = { 2, 4, 6, 8 },
	Generator = { 1, 2, 3, 5 },
	Assembler = { 1, 2, 4 },
	Shipper = { 2, 5, 10 },
}

local function getSp(t, l)
	return t[l] or t[#t]
end

GetUpgradeInfoF.OnServerInvoke = function(p, machine)
	local d = GameLogic.GetPlayerData(p)
	if not d then
		return
	end
	local lv = d.Upgrades[machine .. "Level"] or 1
	local t = speedTbl[machine]
	if not t then
		return
	end
	return {
		level = lv,
		speed = getSp(t, lv),
		nextSpeed = getSp(t, lv + 1),
	}
end

GetPlayerDataF.OnServerInvoke = GameLogic.GetPlayerData

----------------------------------------------------------
-- ⑧ 可选：Auto‑Collect GamePass
----------------------------------------------------------
local AUTO_PASS_ID = 1249719442
local scrapFolder = workspace:WaitForChild("ScrapNodes")

local function ownsPass(plr)
	local ok, res = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, plr.UserId, AUTO_PASS_ID)
	return ok and res
end

task.spawn(function()
	while true do
		for _, p in ipairs(Players:GetPlayers()) do
			if ownsPass(p) then
				for _, node in ipairs(scrapFolder:GetChildren()) do
					local v = node:FindFirstChild("ScrapAmount")
					if v and v:IsA("IntValue") and v.Value > 0 then
						GameLogic.AddScrap(p, v.Value)
						v.Value = 0
					end
				end
			end
		end
		task.wait(10)
	end
end)

local function processReceipt(receiptInfo)
	local plr = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not plr then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if receiptInfo.ProductId == DevProductId_SkipSign then
		local ok = GameLogic.SkipMissedDay(plr)
		if ok then
			-- 可选：推送签到奖励、背包刷新等
			ReplicatedStorage.RemoteEvents.UpdateInventoryEvent:FireClient(plr, GameLogic.GetInventoryDict(plr))
		end
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- 其他DevProduct处理...
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

MarketplaceService.ProcessReceipt = processReceipt
