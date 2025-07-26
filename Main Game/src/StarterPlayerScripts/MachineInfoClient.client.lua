--------------------------------------------------------------------
-- MachineInfoClient  (Client-side)
-- 每秒询问服务器四台机器的 Lv / Speed 并更新 BillboardGui
--------------------------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local rf                = ReplicatedStorage.RemoteFunctions:WaitForChild("GetUpgradeInfoFunction")

-- workspace 对应部件名称 → Remote 参数
local cfg = {
	{station = "CrusherStation"  , key = "Crusher"},
	{station = "GeneratorStation", key = "Generator"},
	{station = "AssemblerStation", key = "Assembler"},
	{station = "ShipperStation"  , key = "Shipper"},
}

local function loop()
	for _,info in ipairs(cfg) do
		local station = workspace:FindFirstChild(info.station)
		if station then
			local gui = station:FindFirstChild("MachineInfo")
			local lbl = gui and gui:FindFirstChild("InfoLabel")
			if lbl then
				local ok,data = pcall(rf.InvokeServer, rf, info.key)
				if ok and data then
					lbl.Text = ("%s\nLv.%d (Speed=%d)\nNext: Lv.%d (Speed=%d)")
						:format(info.key, data.level, data.speed,
							data.level+1, data.nextSpeed)
				end
			end
		end
	end
end

while true do
	loop()
	RunService.Stepped:Wait()
	task.wait(1)
end