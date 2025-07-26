--[[-----------------------------------------------------------------
【StarterPlayerScripts/ClientUIControl】 
用来每秒更新左上角的资源数 + 监听服务器推送
-------------------------------------------------------------------]]

----------------- ① 服务 & 路径 -----------------
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")

local player             = Players.LocalPlayer
local playerGui          = player:WaitForChild("PlayerGui")

-- 主 HUD：查找或创建 MainHUD
local mainHUD = playerGui:FindFirstChild("MainHUD")
local resourcesLabel

if not mainHUD then
    print("[ClientUIControl] MainHUD不存在，创建一个简单的")
    -- 创建一个简单的HUD
    mainHUD = Instance.new("ScreenGui")
    mainHUD.Name = "MainHUD"
    mainHUD.ResetOnSpawn = false
    mainHUD.Parent = playerGui
    
    -- 创建资源显示文本
    resourcesLabel = Instance.new("TextLabel")
    resourcesLabel.Name = "ResourcesText"
    resourcesLabel.Size = UDim2.new(0, 400, 0, 30)
    resourcesLabel.Position = UDim2.new(0, 20, 0, 20)
    resourcesLabel.BackgroundTransparency = 1
    resourcesLabel.Text = "Scrap: 0 | Credits: 0"
    resourcesLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    resourcesLabel.TextSize = 18
    resourcesLabel.Font = Enum.Font.GothamBold
    resourcesLabel.TextXAlignment = Enum.TextXAlignment.Left
    resourcesLabel.Parent = mainHUD
else
    resourcesLabel = mainHUD:WaitForChild("ResourcesText")
end

-- 远程通讯
local rfFolder           = ReplicatedStorage:WaitForChild("RemoteFunctions")
local getDataRF          = rfFolder:WaitForChild("GetPlayerDataFunction")

local reFolder           = ReplicatedStorage:WaitForChild("RemoteEvents")
local updateInvRE        = reFolder:WaitForChild("UpdateInventoryEvent")  -- 背包变化推送

----------------- ② 统计背包里 Shell 的数量 -----------------
local function countShell(inv)
	local total = 0
	for _, slot in ipairs(inv or {}) do
		if slot.itemId:match("Shell") then
			total += slot.quantity
		end
	end
	return total
end

----------------- ③ 主刷新函数 -----------------
local function refresh()
	local data = getDataRF:InvokeServer()   -- 向服务器同步一份完整数据
	if not data then
		resourcesLabel.Text = "Loading..."
		return
	end

	-- 取字段（都加上 or 0，防止 nil 报错）
	local scrap       = data.Scrap       or 0
	local credits     = data.Credits     or 0
	local robotCount  = data.RobotCount  or 0
	local shellTotal  = countShell(data.Inventory)   -- 现在 Shell 存在 Inventory 里

	resourcesLabel.Text = string.format(
		"Scrap: %d | Shell: %d | Robot: %d | Credits: %d",
		scrap, shellTotal, robotCount, credits)
end

----------------- ④ 首次加载 & 定时刷新 -----------------
refresh()                -- 进入游戏第一次就刷新

-- 背包有变化时服务器会推送，让 UI 立即同步
updateInvRE.OnClientEvent:Connect(refresh)

-- 保险起见，每 3 秒再拉一次，防掉包
while true do
	task.wait(3)
	refresh()
end