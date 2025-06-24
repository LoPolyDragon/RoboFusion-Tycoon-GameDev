--------------------------------------------------------------------
-- InventoryBridge.lua  · MineWorld ⇄ UI 背包通讯桥
--------------------------------------------------------------------

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- ★ 主城同款 GameLogicServer
local GameLogic = require(script.Parent.ServerModules.GameLogicServer)

-- RemoteFunction / RemoteEvent 若已存在则复用
local RF = RS:FindFirstChild("RemoteFunctions")
if not RF then
	RF = Instance.new("Folder", RS)
	RF.Name = "RemoteFunctions"
end
local RE = RS:FindFirstChild("RemoteEvents")
if not RE then
	RE = Instance.new("Folder", RS)
	RE.Name = "RemoteEvents"
end

local GET_INV = RF:FindFirstChild("GetInventoryFunction") or Instance.new("RemoteFunction", RF)
GET_INV.Name = "GetInventoryFunction"

local UPD_INV = RE:FindFirstChild("UpdateInventoryEvent") or Instance.new("RemoteEvent", RE)
UPD_INV.Name = "UpdateInventoryEvent"

----------------------------------------------------------------
-- ① GetInventoryFunction : 玩家拉取整包
----------------------------------------------------------------
GET_INV.OnServerInvoke = function(plr)
	return GameLogic.GetInventory(plr) -- 返回 array: { {itemId="", quantity=int}, ...}
end

----------------------------------------------------------------
-- ② 监听 GameLogic.AddItem 之后广播（若 GameLogic 已内置事件可替换）
--    这里简单在 GameLogicServer 暴露一个 callback 列表
----------------------------------------------------------------
local listeners = {} -- 额外监听列表

function GameLogic._emitInventory(plr)
	-- push 最新背包给客户端
	UPD_INV:FireClient(plr, GameLogic.GetInventory(plr))
	-- 触发附加监听
	for _, cb in ipairs(listeners) do
		cb(plr)
	end
end

----------------------------------------------------------------
-- ③ 让 MineMiningServer 调用 GameLogic.AddItem 后自动推送
--    只需给 GameLogic.AddItem 打一个 wrapper
----------------------------------------------------------------
local rawAdd = GameLogic.AddItem
function GameLogic.AddItem(plr, itemId, qty)
	rawAdd(plr, itemId, qty) -- 原逻辑：写存档
	GameLogic._emitInventory(plr) -- 推送
end

print("[InventoryBridge] Ready - RemoteFunction & RemoteEvent online")
