--------------------------------------------------------------------
-- MineGenerator.lua · 2025‑06‑20  FINAL
--------------------------------------------------------------------
local WS , RS = workspace, game:GetService("ReplicatedStorage")
local Run      = game:GetService("RunService")

local CELL   = 3
local SIZE   = 60          -- XZ
local LAYERS = 5           -- ±5 = 11 层
local BATCH  = 1000

local HALFW = SIZE*0.5
local STEP  = SIZE/CELL
local Prefabs = RS:WaitForChild("OrePrefabs")
local rng     = Random.new()

----------- 层 → 随机矿 ------------------------------------------
local function pickOre(layer)
	if layer>=4  then return "Stone"
	elseif layer==3 then return rng:NextNumber()<.15 and "IronOre" or "Stone"
	elseif layer==2 then return rng:NextNumber()<.30 and "BronzeOre" or "Stone"
	elseif layer==1 then return rng:NextNumber()<.18 and "GoldOre"   or "Stone"
	elseif layer==0 then return rng:NextNumber()<.10 and "DiamondOre" or "Stone"
	else                 return rng:NextNumber()<.15 and "DiamondOre" or "Stone"
	end
end

----------- Prefab → 校正成 3×3×3 Model --------------------------
local function buildCube(ore, collide)
	local src = Prefabs[ore]
	local mdl = src:Clone()

	-- ① 移动到原点
	local bbCF, bbSize = mdl:GetBoundingBox()
	mdl:PivotTo(CFrame.new(-bbCF.Position))

	-- ② 强裁包围盒
	for _,p in ipairs(mdl:GetDescendants()) do
		if p:IsA("BasePart") then
			local off = p.Position
			p.Position = Vector3.new(
				math.clamp(off.X, -1.49, 1.49),
				math.clamp(off.Y, -1.49, 1.49),
				math.clamp(off.Z, -1.49, 1.49))
			p.Anchored   = true
			p.CanCollide = false
			p.CanTouch   = false
			p.CanQuery   = false
		end
	end

	-- ③ 插 Hit
	local hit = Instance.new("Part")
	hit.Name         = ore
	hit.Size         = Vector3.new(2.9,2.9,2.9)
	hit.Transparency = 1
	hit.Anchored     = true
	hit.CanCollide   = collide
	hit.Parent       = mdl
	mdl.PrimaryPart  = hit
	return mdl
end

----------------------------------------------------------------
local M = {}
function M.Generate(plr)
	local tag = plr.Name.."_Mine"
	local old = WS:FindFirstChild(tag) if old then old:Destroy() end
	local root= Instance.new("Model", WS) root.Name = tag

	local buf, cf = {}, {}
	for layer = LAYERS, -LAYERS, -1 do
		local coll = (layer == LAYERS)
		for xi=0, STEP-1 do
			for zi=0, STEP-1 do
				local cube = buildCube(pickOre(layer), coll)
				buf[#buf+1], cf[#cf+1] =
					cube,
				CFrame.new(
					xi*CELL - HALFW + 1.5,
					layer*CELL + 1.5,
					zi*CELL - HALFW + 1.5)
				if #buf >= BATCH then
					for k,m in ipairs(buf) do m:PivotTo(cf[k]); m.Parent=root end
					buf,cf={},{};
					Run.Heartbeat:Wait()
				end
			end
		end
	end
	for k,m in ipairs(buf) do m:PivotTo(cf[k]); m.Parent=root end

	-- 出生到顶层
	local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	if hrp then hrp.CFrame = CFrame.new(0, CELL*(LAYERS+1), 0) end
end
return M