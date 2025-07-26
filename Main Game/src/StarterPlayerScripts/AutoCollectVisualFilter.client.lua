-- StarterPlayerScripts / AutoCollectVisualFilter (LocalScript)
local Players            = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local player             = Players.LocalPlayer

local AUTO_PASS_ID = 1249719442
local SCRAP_FOLDER = "ScrapNodes"

-------------------------------------------------------------
-- 判定是否拥有 Auto-Collect
-------------------------------------------------------------
local function hasAutoCollect()
	local ok, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, AUTO_PASS_ID)
	end)
	return ok and owns
end

-------------------------------------------------------------
-- 过滤单个节点（安全写法）
-------------------------------------------------------------
local function filterOneNode(node)
	if typeof(node) ~= "Instance" then return end

	------------------------------------------------------------------
	-- 1️⃣ 删除 ProximityPrompt（手动收集的交互）
	------------------------------------------------------------------
	local prompt = node:FindFirstChildOfClass("ProximityPrompt")
	if prompt then prompt:Destroy() end

	------------------------------------------------------------------
	-- 2️⃣ 隐藏 / 移除原来的 Scrap 信息 GUI
	------------------------------------------------------------------
	local oldGui = node:FindFirstChild("ScrapInfo")   -- ← 你的原 GUI 名
	if oldGui then
		-- ***两种做法选一***
		-- oldGui.Enabled = false          -- A. 只是隐藏
		oldGui:Destroy()                   -- B. 直接删掉
	end

	------------------------------------------------------------------
	-- 3️⃣ 显示黄字提示（只给买了 Pass 的人看）
	------------------------------------------------------------------
	local tag = node:FindFirstChild("AutoCollectInfo")
	if not tag then
		tag = Instance.new("BillboardGui")
		tag.Name = "AutoCollectInfo"
		tag.Size = UDim2.new(0,200,0,50)
		tag.StudsOffset = Vector3.new(0,2.5,0)
		tag.AlwaysOnTop = true
		tag.Parent = node

		local lbl = Instance.new("TextLabel")
		lbl.Name = "Msg"
		lbl.Size = UDim2.new(1,0,1,0)
		lbl.BackgroundTransparency = 1
		lbl.TextScaled = true
		lbl.TextColor3 = Color3.fromRGB(255,255,0)
		lbl.Font = Enum.Font.GothamBold
		lbl.Parent = tag
	end
	tag.Msg.Text = "You already own\nAuto-Collect!"
end

-------------------------------------------------------------
-- 主入口：仅当买了 Pass 时生效
-------------------------------------------------------------
if hasAutoCollect() then
	local folder = workspace:WaitForChild(SCRAP_FOLDER)

	-- 先过滤现有节点
	for _,node in ipairs(folder:GetChildren()) do
		filterOneNode(node)
	end

	-- 再监听后续新节点
	folder.ChildAdded:Connect(function(child)
		filterOneNode(child)
	end)
end