--------------------------------------------------------------------
--  MineMiningServer.lua  · 保证销毁 / 6 邻碰撞 / 去除 race
--------------------------------------------------------------------
local WS, RS = workspace, game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Run     = game:GetService("RunService")
local Const   = require(RS.SharedModules.GameConstants)

local Teleport = game:GetService("TeleportService")
local backRE   = RS:WaitForChild("ReturnHomeEvent")

local GameLogic = require(game.ServerScriptService.ServerModules.GameLogicServer)

local RE = RS:FindFirstChild("MiningProgressEvent") or Instance.new("RemoteEvent", RS)
RE.Name  = "MiningProgressEvent"

local ACTIVE = {}     -- [plr] = {mdl, finish}

local CELL       = 3
local DIRECTIONS = {
	Vector3.new( CELL,0,0), Vector3.new(-CELL,0,0),
	Vector3.new( 0,CELL,0), Vector3.new( 0,-CELL,0),
	Vector3.new( 0,0,CELL), Vector3.new( 0,0,-CELL)
}

local function solid(model)
	for _,p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then p.CanCollide=true end
	end
end

local function solidNeighbours(mdl)
	local pos   = mdl:GetPivot().Position
	local parent= mdl.Parent
	for _,dir in ipairs(DIRECTIONS) do
		local hit = WS:FindPartOnRayWithWhitelist(
			Ray.new(pos, dir*1.5), {parent})
		if hit then
			local neigh = hit:FindFirstAncestorWhichIsA("Model") or hit
			solid(neigh)
		end
	end
end

local function canMine(plr, ore)
	local tool = plr.Character and plr.Character:FindFirstChildWhichIsA("Tool")
	local pk   = tool and Const.PICK_INFO[tool.Name]
	local cfg  = Const.ORE_INFO[ore]
	return pk and cfg and cfg.hardness<=pk.maxHardness, cfg and cfg.time
end

local function locateHit(p)
	if p and Const.ORE_INFO[p.Name] then return p end
	local mdl=p and p:FindFirstAncestorWhichIsA("Model")
	if not mdl then return end
	for _,d in ipairs(mdl:GetChildren()) do
		if d:IsA("BasePart") and Const.ORE_INFO[d.Name] then return d end
	end
end

---------------- Client Request ----------------
RE.OnServerEvent:Connect(function(plr,cmd,part)
	if cmd=="CANCEL" then ACTIVE[plr]=nil; RE:FireClient(plr,"END"); return end
	if cmd~="BEGIN" or ACTIVE[plr] or not part then return end

	local hit = locateHit(part); if not hit then return end
	local ok,sec = canMine(plr, hit.Name); if not ok then return end

	local mdl = hit:FindFirstAncestorWhichIsA("Model") or hit
	ACTIVE[plr] = {mdl=mdl, finish=tick()+sec}
	RE:FireClient(plr,"BEGIN",sec)
end)

---------------- Heartbeat ---------------------
Run.Heartbeat:Connect(function()
	local now=tick()
	for plr,data in pairs(ACTIVE) do
		if now >= data.finish then
			if data.mdl and data.mdl.Parent then
				solidNeighbours(data.mdl)
				data.mdl:Destroy()
			end
			RE:FireClient(plr,"END")
			ACTIVE[plr]=nil
		end
	end
end)

backRE.OnServerEvent:Connect(function(plr)
	local HOME_PLACE_ID = 82341741981647      -- ← 替换成主城 PlaceId
	Teleport:Teleport(HOME_PLACE_ID, plr)
end)

Run.Heartbeat:Connect(function()
	local now=tick()
	for plr,data in pairs(ACTIVE) do
		if now >= data.finish then
			local hit = data.mdl and data.mdl:FindFirstChildWhichIsA("BasePart")
			if hit and data.mdl.Parent then
				-- ★★★★★ ① 掉落到背包
				GameLogic.AddItem(plr, hit.Name, 1)

				-- ② 下层补碰撞+销毁
				solidNeighbours(data.mdl)
				data.mdl:Destroy()
			end
			RE:FireClient(plr,"END")
			ACTIVE[plr]=nil
		end
	end
end)

Players.PlayerRemoving:Connect(function(p) ACTIVE[p]=nil end)