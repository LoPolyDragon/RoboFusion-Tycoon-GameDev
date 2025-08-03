--------------------------------------------------------------------
--  MineMiningServer.lua  · 保证销毁 / 6 邻碰撞 / 去除 race
--------------------------------------------------------------------
local WS, RS = workspace, game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local Const = require(RS.SharedModules.GameConstants)

local Teleport = game:GetService("TeleportService")
local backRE = RS:WaitForChild("ReturnHomeEvent")

local GameLogic = require(game.ServerScriptService.ServerModules.GameLogicServer)

local RE = RS:FindFirstChild("MiningProgressEvent")
if not RE then
	RE = Instance.new("RemoteEvent")
	RE.Name = "MiningProgressEvent"
	RE.Parent = RS
end

local ACTIVE = {} -- [plr] = {mdl, finish}

local CELL = 3
local DIRECTIONS = {
	Vector3.new(CELL, 0, 0),
	Vector3.new(-CELL, 0, 0),
	Vector3.new(0, CELL, 0),
	Vector3.new(0, -CELL, 0),
	Vector3.new(0, 0, CELL),
	Vector3.new(0, 0, -CELL),
}

local function solid(model)
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.CanCollide = true
		end
	end
end

local function solidNeighbours(mdl)
	local pos = mdl:GetPivot().Position
	local parent = mdl.Parent
	for _, dir in ipairs(DIRECTIONS) do
		local hit = WS:FindPartOnRayWithWhitelist(Ray.new(pos, dir * 1.5), { parent })
		if hit then
			local neigh = hit:FindFirstAncestorWhichIsA("Model") or hit
			solid(neigh)
		end
	end
end

local function canMine(plr, ore)
	local tool = plr.Character and plr.Character:FindFirstChildWhichIsA("Tool")
	local pk = tool and Const.PICKAXE_INFO[tool.Name]
	local cfg = Const.ORE_INFO[ore]
	
	if not (pk and cfg) then
		return false, nil
	end
	
	-- 检查硬度是否足够
	if cfg.hardness > pk.maxHardness then
		return false, nil
	end
	
	return true, cfg.time
end

local function locateHit(p)
	if p and Const.ORE_INFO[p.Name] then
		return p
	end
	local mdl = p and p:FindFirstAncestorWhichIsA("Model")
	if not mdl then
		return
	end
	for _, d in ipairs(mdl:GetChildren()) do
		if d:IsA("BasePart") and Const.ORE_INFO[d.Name] then
			return d
		end
	end
end

---------------- Client Request ----------------
RE.OnServerEvent:Connect(function(plr, cmd, part)
	if cmd == "CANCEL" then
		ACTIVE[plr] = nil
		RE:FireClient(plr, "END")
		return
	end
	
	if cmd ~= "BEGIN" or ACTIVE[plr] or not part then
		return
	end

	-- 检查玩家是否存在且有角色
	if not (plr and plr.Character and plr.Character.PrimaryPart) then
		return
	end

	local hit = locateHit(part)
	if not hit then
		-- 没找到可挖掘的矿石
		RE:FireClient(plr, "ERROR", "无效的矿石")
		return
	end
	
	local ok, sec = canMine(plr, hit.Name)
	if not ok then
		-- 镐子不够硬或没有镐子
		RE:FireClient(plr, "ERROR", "需要更高级的镐子")
		return
	end

	-- 检查距离
	local distance = (plr.Character.PrimaryPart.Position - hit.Position).Magnitude
	if distance > 20 then -- 最大挖掘距离20格
		RE:FireClient(plr, "ERROR", "距离太远")
		return
	end

	local mdl = hit:FindFirstAncestorWhichIsA("Model") or hit
	ACTIVE[plr] = { mdl = mdl, finish = tick() + sec, oreName = hit.Name }
	RE:FireClient(plr, "BEGIN", sec)
	
	print(("[MineMiningServer] 玩家 %s 开始挖掘 %s，预计耗时 %.1f 秒"):format(plr.Name, hit.Name, sec))
end)

---------------- Heartbeat ---------------------
backRE.OnServerEvent:Connect(function(plr)
	local HOME_PLACE_ID = 82341741981647 -- ← 替换成主城 PlaceId
	Teleport:Teleport(HOME_PLACE_ID, plr)
end)

Run.Heartbeat:Connect(function()
	local now = tick()
	for plr, data in pairs(ACTIVE) do
		if now >= data.finish then
			local function findOrePart(mdl)
				for _, p in ipairs(mdl:GetDescendants()) do
					if p:IsA("BasePart") and Const.ORE_INFO[p.Name] then
						return p
					end
				end
			end

			-- 检查挖掘是否成功完成
			if data.mdl and data.mdl.Parent then
				local orePart = findOrePart(data.mdl)
				if orePart then
					-- 添加矿物到玩家背包
					local success = pcall(function()
						GameLogic.AddItem(plr, orePart.Name, 1)
					end)
					
					if success then
						print(("[MineMiningServer] 玩家 %s 成功挖掘了 %s"):format(plr.Name, orePart.Name))
						
						-- 使邻近方块变为可碰撞，创造更真实的挖掘体验
						solidNeighbours(data.mdl)
						
						-- 销毁挖掘的矿石
						data.mdl:Destroy()
						
						-- 通知客户端挖掘成功
						RE:FireClient(plr, "SUCCESS", data.oreName)
					else
						-- 挖掘失败，可能是背包满了等原因
						RE:FireClient(plr, "ERROR", "挖掘失败，检查背包空间")
					end
				else
					-- 找不到矿石部分
					RE:FireClient(plr, "ERROR", "矿石已消失")
				end
			else
				-- 矿石模型已被销毁
				RE:FireClient(plr, "ERROR", "矿石已消失")
			end
			
			-- 清理活动状态
			ACTIVE[plr] = nil
		end
	end
end)

Players.PlayerRemoving:Connect(function(p)
	ACTIVE[p] = nil
end)
