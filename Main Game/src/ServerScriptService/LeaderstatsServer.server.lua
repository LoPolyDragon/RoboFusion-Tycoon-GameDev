local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local VIP_PASS_ID = 1247751921  -- 你的 VIP GamePass ID

Players.PlayerAdded:Connect(function(player)
	-- 创建 leaderstats 容器
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	-- 创建 “VIP” 统计
	local vipStat = Instance.new("StringValue")
	vipStat.Name = "VIP"
	vipStat.Value = "No"  -- 默认为 No
	vipStat.Parent = leaderstats

	-- 检查是否拥有 VIP
	local success, ownsPass = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, VIP_PASS_ID)
	end)

	if success and ownsPass then
		vipStat.Value = "👑"
	else
		-- 也可以把错误或缺少pass的结果打印出来
		print("Player", player.Name, "ownsPass?=", ownsPass, "success?=", success)
	end
end)
