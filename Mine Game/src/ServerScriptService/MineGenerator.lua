----------------------------------------------------------------
-- MineGenerator.lua · 震撼山脉生成版
-- 生成逻辑：
--   1) 使用多层噪声生成壮观的山脉地形
--   2) 创建连续的山峰和山谷
--   3) 按高度层分布矿脉
--   4) 将所有矿石 Model 放入 mineFolder/OreFolder
--
-- 调用：MineGenerator.Generate(workspaceFolder , seed?)
----------------------------------------------------------------
local RS = game:GetService("ReplicatedStorage")

----------------------------------------------------------------
-- ★ 优化的地形生成参数
----------------------------------------------------------------
local CELL_SIZE = 3 -- 每体素边长（stud）
local GRID_SIZE = 50 -- X / Z 体素数 (平衡性能和效果)
local MIN_HEIGHT = 8 -- 山体最低 Y（stud）
local MAX_HEIGHT = 35 -- 最高山峰（stud，降低避免卡顿）
local BASE_Y = 0 -- 整体抬升

-- 每层矿石分布 (优化高度层级)
local ORE_LAYERS = {
	{ min = 8, max = 15, ores = { "Stone", "IronOre" } },
	{ min = 15, max = 22, ores = { "Stone", "BronzeOre" } },
	{ min = 22, max = 28, ores = { "Stone", "GoldOre" } },
	{ min = 28, max = 32, ores = { "Stone", "DiamondOre" } },
	{ min = 32, max = 35, ores = { "Stone", "TitaniumOre", "UraniumOre" } },
}

local PREFABS = RS:WaitForChild("OrePrefabs")

----------------------------------------------------------------
-- 山脉生成工具
----------------------------------------------------------------
local function clamp(v, a, b)
	return math.max(a, math.min(b, v))
end

-- 基础噪声函数
local function ridgeNoise(x, z, seed, scale)
	local noise = math.noise((x + seed * 0.1) / scale, (z + seed * 0.1) / scale)
	return math.abs(noise * 2 - 1) -- 产生山脊效果
end

-- 优化的连绵地形噪声
local function mountainNoise(x, z, seed)
	local height = 0
	
	-- 连绵的低起伏地形
	local base = math.noise((x + seed) / 20, (z + seed) / 20) * 0.4
	local hills = math.noise((x + seed) / 12, (z + seed) / 12) * 0.3
	local detail = math.noise((x + seed) / 6, (z + seed) / 6) * 0.2
	local fine = math.noise((x + seed) / 3, (z + seed) / 3) * 0.1
	
	height = base + hills + detail + fine
	
	-- 更温和的边界软化，创造自然过渡
	local centerX, centerZ = GRID_SIZE / 2, GRID_SIZE / 2
	local distance = math.sqrt((x - centerX)^2 + (z - centerZ)^2)
	local maxDistance = GRID_SIZE * 0.45
	local falloff = clamp(1 - (distance / maxDistance), 0, 1)
	
	return height * falloff
end

-- 创建矿物方块（确保Part名称正确）
local function buildCube(ore)
	local src = PREFABS:FindFirstChild(ore)
	if not src then
		-- 如果没有预制件，创建简单方块
		local mdl = Instance.new("Model")
		mdl.Name = ore .. "_Block"
		
		local part = Instance.new("Part")
		part.Name = ore -- 重要：客户端依赖这个名称
		part.Size = Vector3.new(CELL_SIZE, CELL_SIZE, CELL_SIZE)
		part.Material = Enum.Material.Rock
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		
		-- 根据矿物类型设置颜色
		if ore == "Stone" then
			part.Color = Color3.fromRGB(120, 120, 120)
		elseif ore == "IronOre" then
			part.Color = Color3.fromRGB(150, 130, 100)
		elseif ore == "BronzeOre" then
			part.Color = Color3.fromRGB(180, 140, 80)
		elseif ore == "GoldOre" then
			part.Color = Color3.fromRGB(255, 215, 0)
		elseif ore == "DiamondOre" then
			part.Color = Color3.fromRGB(150, 200, 255)
			part.Material = Enum.Material.Diamond
		elseif ore == "TitaniumOre" then
			part.Color = Color3.fromRGB(200, 200, 220)
			part.Material = Enum.Material.Metal
		elseif ore == "UraniumOre" then
			part.Color = Color3.fromRGB(100, 255, 100)
			part.Material = Enum.Material.Neon
		end
		
		part.Parent = mdl
		return mdl
	else
		local mdl = src:Clone()
		-- 确保模型中的Part有正确的名称
		local part = mdl:FindFirstChildWhichIsA("BasePart")
		if part then
			part.Name = ore
		end
		return mdl
	end
end

----------------------------------------------------------------
-- 生成入口
----------------------------------------------------------------
local MineGenerator = {}

function MineGenerator.Generate(rootFolder, seed)
	print("[MineGenerator] 开始生成震撼山脉地形...")
	print("[MineGenerator] rootFolder:", rootFolder, rootFolder and rootFolder.Parent)
	seed = seed or os.time()
	math.randomseed(seed)

	--------------------------------------------------------------
	-- ① 山脉高度图生成
	--------------------------------------------------------------
	local height = {}
	local minH = MAX_HEIGHT
	local maxH = MIN_HEIGHT
	
	print("[MineGenerator] 正在生成山脉高度图...")
	for x = 1, GRID_SIZE do
		height[x] = {}
		for z = 1, GRID_SIZE do
			local noiseValue = mountainNoise(x, z, seed)
			
			-- 将噪声值映射到高度范围
			local h = MIN_HEIGHT + (MAX_HEIGHT - MIN_HEIGHT) * (noiseValue + 1) / 2
			h = math.floor(clamp(h, MIN_HEIGHT, MAX_HEIGHT))
			
			height[x][z] = h
			minH = math.min(minH, h)
			maxH = math.max(maxH, h)
		end
	end
	print(("[MineGenerator] 山脉高度范围: %d ~ %d studs"):format(minH, maxH))

	--------------------------------------------------------------
	-- ② 3D体素填充：山体内部 = Stone，洞穴系统
	--------------------------------------------------------------
	print("[MineGenerator] 正在生成体素数据...")
	local vox = {} -- vox[x][y][z] = {ore, isCave}
	
	for x = 1, GRID_SIZE do
		vox[x] = {}
		for y = 1, MAX_HEIGHT do
			vox[x][y] = {}
			for z = 1, GRID_SIZE do
				local inside = y <= height[x][z]
				
				-- 更复杂的洞穴系统
				local caveNoise1 = math.noise((x + seed) / 8, y / 6, (z + seed) / 8)
				local caveNoise2 = math.noise((x + seed * 2) / 12, y / 10, (z + seed * 2) / 12)
				local cave = inside and (caveNoise1 > 0.5 or caveNoise2 > 0.55)
				
				-- 避免表面洞穴过多
				if y > height[x][z] - 3 then
					cave = cave and caveNoise1 > 0.7
				end
				
				vox[x][y][z] = { 
					ore = inside and not cave and "Stone" or nil, 
					isCave = cave 
				}
			end
		end
	end

	--------------------------------------------------------------
	-- ③ 大规模矿脉生成系统
	--------------------------------------------------------------
	print("[MineGenerator] 正在布置矿脉...")
	
	local function isStone(x, y, z)
		return vox[x] and vox[x][y] and vox[x][y][z] and vox[x][y][z].ore == "Stone"
	end
	
	-- 更大规模的矿脉生成
	local function addLargeVein(ore, yMin, yMax, veinCnt, veinLength, thickness)
		for _ = 1, veinCnt do
			local startX = math.random(5, GRID_SIZE - 5)
			local startY = math.random(yMin, yMax)
			local startZ = math.random(5, GRID_SIZE - 5)
			
			-- 确保起始点有效
			if not isStone(startX, startY, startZ) then
				continue
			end
			
			-- 生成主矿脉
			local x, y, z = startX, startY, startZ
			for step = 1, veinLength do
				-- 在当前位置周围生成矿块团
				for dx = -thickness, thickness do
					for dy = -thickness, thickness do
						for dz = -thickness, thickness do
							local nx, ny, nz = x + dx, y + dy, z + dz
							local distance = math.sqrt(dx*dx + dy*dy + dz*dz)
							
							-- 球形分布，边缘概率递减
							if distance <= thickness and math.random() < (1 - distance/thickness) then
								if isStone(nx, ny, nz) then
									vox[nx][ny][nz].ore = ore
								end
							end
						end
					end
				end
				
				-- 矿脉延伸方向（带随机性）
				x = x + math.random(-2, 2)
				y = y + math.random(-1, 1)
				z = z + math.random(-2, 2)
				
				-- 边界检查
				x = clamp(x, 2, GRID_SIZE - 1)
				y = clamp(y, yMin, yMax)
				z = clamp(z, 2, GRID_SIZE - 1)
			end
		end
	end

	-- 按高度层分布不同矿物，优化数量和范围
	addLargeVein("IronOre", 8, 18, 8, 15, 1)
	addLargeVein("BronzeOre", 15, 25, 6, 12, 1)
	addLargeVein("GoldOre", 22, 30, 5, 10, 1)
	addLargeVein("DiamondOre", 28, 33, 4, 8, 1)
	addLargeVein("TitaniumOre", 30, 35, 3, 6, 1)
	addLargeVein("UraniumOre", 32, 35, 2, 5, 1)

	--------------------------------------------------------------
	-- ④ OreFolder（★机器人脚本依赖）
	--------------------------------------------------------------
	local oreFolder = rootFolder:FindFirstChild("OreFolder")
	if not oreFolder then
		oreFolder = Instance.new("Folder")
		oreFolder.Name = "OreFolder"
		oreFolder.Parent = rootFolder
	end

	--------------------------------------------------------------
	-- ⑤ 体素 → 3D模型实例化 (优化为自然地形)
	--------------------------------------------------------------
	print("[MineGenerator] 正在实例化地形模型...")
	local blockCount = 0
	
	for x = 1, GRID_SIZE do
		for z = 1, GRID_SIZE do
			for y = 1, height[x][z] do
				local cell = vox[x][y][z]
				if cell and cell.ore then
					local mdl = buildCube(cell.ore)
					if mdl then
						-- 取出唯一的 Part
						local part = mdl:FindFirstChildWhichIsA("BasePart")
						if part then
							-- 计算世界坐标，中心对齐
							local worldX = (x - GRID_SIZE/2) * CELL_SIZE
							local worldY = BASE_Y + y * CELL_SIZE
							local worldZ = (z - GRID_SIZE/2) * CELL_SIZE
							
							part.Position = Vector3.new(worldX, worldY, worldZ)
							
							-- 添加随机变化让地形更自然
							local sizeVariation = 0.8 + math.random() * 0.4 -- 0.8-1.2倍
							local newSize = CELL_SIZE * sizeVariation
							part.Size = Vector3.new(newSize, newSize, newSize)
							
							-- 给表面方块添加随机旋转
							if y >= height[x][z] - 2 then
								part.Rotation = Vector3.new(
									math.random(-10, 10),
									math.random(-180, 180),
									math.random(-10, 10)
								)
							end
							
							-- 降低碰撞检测以减少性能影响
							if math.random() < 0.7 then -- 70%的方块有碰撞
								part.CanCollide = true
							else
								part.CanCollide = false
								part.Transparency = 0.1
							end
						end
						mdl.Parent = oreFolder
						blockCount = blockCount + 1
					end
				end
			end
		end
	end
	
	print("[MineGenerator] 连绵地形生成完成！")
	print(("- 地图大小: %d×%d 体素"):format(GRID_SIZE, GRID_SIZE))
	print(("- 高度范围: %d~%d studs"):format(minH, maxH))
	print(("- 总方块数: %d"):format(blockCount))
	print("- 优化的连绵地形已就绪！")
end

return MineGenerator
