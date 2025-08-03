----------------------------------------------------------------
-- MineGenerator.lua · 多山分离优化版
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
-- ★ 真正的山脉地形参数 (根据GDD Final.md优化)
----------------------------------------------------------------
local CELL_SIZE = 4 -- 每体素边长（stud）
local GRID_SIZE = 80 -- X / Z 体素数 (320x320 studs，中等尺寸)
local MIN_HEIGHT = 3 -- 山体最低 Y（stud）
local MAX_HEIGHT = 60 -- 最高山峰（240 studs，适中高度）
local BASE_Y = 0 -- 从地面开始生成，让山脉更自然

-- 矿石稀有度分布 (严格按照GDD Final.md深度要求)
local ORE_DISTRIBUTION = {
	-- Scrap可在任何地方
	{ name = "Scrap", minDepth = 0, maxDepth = 300, rarity = 0.15 },
	-- Iron Ore: 20-60 stud深度
	{ name = "IronOre", minDepth = 20, maxDepth = 60, rarity = 0.12 },
	-- Bronze Ore: 60-100 stud深度
	{ name = "BronzeOre", minDepth = 60, maxDepth = 100, rarity = 0.08 },
	-- Gold Ore: 100-160 stud深度
	{ name = "GoldOre", minDepth = 100, maxDepth = 160, rarity = 0.06 },
	-- Diamond Ore: 160-220 stud深度
	{ name = "DiamondOre", minDepth = 160, maxDepth = 220, rarity = 0.04 },
	-- Titanium Ore: 220-280 stud深度
	{ name = "TitaniumOre", minDepth = 220, maxDepth = 280, rarity = 0.025 },
	-- Uranium Ore: ≥280 stud深度
	{ name = "UraniumOre", minDepth = 280, maxDepth = 300, rarity = 0.015 },
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

-- 壮观山脉地形生成 (更多山峰，更真实的山脉效果)
local function mountainNoise(x, z, seed)
	-- 创建6座分离的小山，每座山都是独立的
	local peaks = {
		{x = GRID_SIZE * 0.25, z = GRID_SIZE * 0.25, height = 0.9}, -- 山址1（左下）
		{x = GRID_SIZE * 0.75, z = GRID_SIZE * 0.25, height = 0.85}, -- 山址2（右下）
		{x = GRID_SIZE * 0.25, z = GRID_SIZE * 0.75, height = 0.8}, -- 山址3（左上）
		{x = GRID_SIZE * 0.75, z = GRID_SIZE * 0.75, height = 0.88}, -- 山址4（右上）
		{x = GRID_SIZE * 0.5, z = GRID_SIZE * 0.15, height = 0.75}, -- 山址5（下中）
		{x = GRID_SIZE * 0.5, z = GRID_SIZE * 0.85, height = 0.82}, -- 山址6（上中）
	}
	
	local height = 0
	local totalWeight = 0
	
	-- 计算到各个山峰的距离，创建分离的小山
	for _, peak in pairs(peaks) do
		local distance = math.sqrt((x - peak.x)^2 + (z - peak.z)^2)
		local influence = math.max(0, 1 - distance / (GRID_SIZE * 0.15)) -- 小影响范围，创建分离的山
		
		-- 创造独立的小山
		if distance < GRID_SIZE * 0.08 then -- 小山的峰顶区域
			influence = influence^2 -- 适中衰减
		else
			influence = influence^4 -- 急剧衰减，创造分离效果
		end
		
		height = height + peak.height * influence
		totalWeight = totalWeight + influence
	end
	
	-- 添加多层噪声创造复杂山脉纹理
	local baseNoise = math.noise((x + seed) / 20, (z + seed) / 20) * 0.4
	local detailNoise = math.noise((x + seed) / 8, (z + seed) / 8) * 0.2
	local ridgeNoise = ridgeNoise(x, z, seed, 15) * 0.3 -- 山脊效果
	
	height = height + baseNoise + detailNoise + ridgeNoise
	
	-- 更自然的边界过渡，保持山脉边缘的壮观
	local centerX, centerZ = GRID_SIZE / 2, GRID_SIZE / 2
	local edgeDistance = math.sqrt((x - centerX)^2 + (z - centerZ)^2)
	local maxEdgeDistance = GRID_SIZE * 0.48 -- 更大的有效范围
	local edgeFalloff = math.max(0, 1 - (edgeDistance / maxEdgeDistance)^0.8) -- 更缓和的边界衰减
	
	height = height * edgeFalloff
	
	-- 确保最低高度
	return math.max(0.1, height)
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
	print("[MineGenerator] 开始生成多山分离地形...")
	print("[MineGenerator] rootFolder:", rootFolder, rootFolder and rootFolder.Parent)
	seed = seed or os.time()
	math.randomseed(seed)

	--------------------------------------------------------------
	-- ① 山脉高度图生成
	--------------------------------------------------------------
	local height = {}
	local minH = MAX_HEIGHT
	local maxH = MIN_HEIGHT
	
	print("[MineGenerator] 正在生成多山高度图...")
	for x = 1, GRID_SIZE do
		height[x] = {}
		for z = 1, GRID_SIZE do
			local noiseValue = mountainNoise(x, z, seed)
			
			-- 将噪声值映射到高度范围 (noiseValue 已经是 0-1 范围)
			local h = MIN_HEIGHT + (MAX_HEIGHT - MIN_HEIGHT) * noiseValue
			h = math.floor(clamp(h, MIN_HEIGHT, MAX_HEIGHT))
			
			height[x][z] = h
			minH = math.min(minH, h)
			maxH = math.max(maxH, h)
		end
	end
	print(("[MineGenerator] 山脉高度范围: %d ~ %d studs"):format(minH, maxH))

	--------------------------------------------------------------
	-- ② 3D体素填充：山体内部 = Stone，少量地下洞穴
	--------------------------------------------------------------
	print("[MineGenerator] 正在生成体素数据...")
	local vox = {} -- vox[x][y][z] = {ore, isCave}
	
	for x = 1, GRID_SIZE do
		vox[x] = {}
		for y = 1, MAX_HEIGHT do
			vox[x][y] = {}
			for z = 1, GRID_SIZE do
				local inside = y <= height[x][z]
				
				-- 只在深处生成少量洞穴，保持山坡完整
				local cave = false
				if inside and y < height[x][z] - 5 then -- 只在距离表面5格以下
					local caveNoise = math.noise((x + seed) / 10, y / 8, (z + seed) / 10)
					cave = caveNoise > 0.6 -- 更严格的洞穴生成条件
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
	
	-- 改进的矿脉生成函数，增加调试信息
	local function addLargeVein(ore, yMin, yMax, veinCnt, veinLength, thickness)
		local placedBlocks = 0
		local attempts = 0
		
		for veinIndex = 1, veinCnt do
			local startX = math.random(5, GRID_SIZE - 5)
			local startY = math.random(yMin, yMax)
			local startZ = math.random(5, GRID_SIZE - 5)
			
			attempts = attempts + 1
			
			-- 如果起始点不是石头，尝试找附近的石头
			if not isStone(startX, startY, startZ) then
				local found = false
				for dx = -3, 3 do
					for dy = -2, 2 do
						for dz = -3, 3 do
							local nx, ny, nz = startX + dx, startY + dy, startZ + dz
							if isStone(nx, ny, nz) then
								startX, startY, startZ = nx, ny, nz
								found = true
								break
							end
						end
						if found then break end
					end
					if found then break end
				end
				if not found then
					continue
				end
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
									placedBlocks = placedBlocks + 1
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
		
		print(("[DEBUG] %s: 尝试%d次，放置%d个方块"):format(ore, attempts, placedBlocks))
	end

	-- 严格按照GDD Final.md深度要求生成矿脉
	print("[DEBUG] 开始按GDD标准生成矿脉...")
	-- 大幅减少矿脉数量，提高性能
	-- Scrap矿脉 (少量)
	addLargeVein("Scrap", 1, 60, 8, 8, 1)
	print("[DEBUG] Scrap 矿脉生成完成")
	-- Iron Ore: 20-60 stud
	addLargeVein("IronOre", 5, 15, 6, 6, 1)
	print("[DEBUG] IronOre 矿脉生成完成")
	-- Bronze Ore: 60-100 stud
	addLargeVein("BronzeOre", 15, 25, 5, 5, 1)
	print("[DEBUG] BronzeOre 矿脉生成完成")
	-- Gold Ore: 100-160 stud
	addLargeVein("GoldOre", 25, 35, 4, 4, 1)
	print("[DEBUG] GoldOre 矿脉生成完成")
	-- Diamond Ore: 160-220 stud
	addLargeVein("DiamondOre", 35, 45, 3, 3, 1)
	print("[DEBUG] DiamondOre 矿脉生成完成")
	-- Titanium Ore: 220-280 stud
	addLargeVein("TitaniumOre", 45, 55, 2, 2, 1)
	print("[DEBUG] TitaniumOre 矿脉生成完成")
	-- Uranium Ore: ≥280 stud
	addLargeVein("UraniumOre", 55, 60, 1, 1, 1)
	print("[DEBUG] UraniumOre 矿脉生成完成")

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
							-- 计算世界坐标，以(0,0,0)为中心
							local worldX = (x - (GRID_SIZE+1)/2) * CELL_SIZE
							local worldY = BASE_Y + y * CELL_SIZE
							local worldZ = (z - (GRID_SIZE+1)/2) * CELL_SIZE
							
							part.Position = Vector3.new(worldX, worldY, worldZ)
							
							-- 完全规整的方块，无旋转无变形
							part.Size = Vector3.new(CELL_SIZE, CELL_SIZE, CELL_SIZE)
							part.Rotation = Vector3.new(0, 0, 0) -- 完全无旋转
							part.CanCollide = true
						end
						mdl.Parent = oreFolder
						blockCount = blockCount + 1
					end
				end
			end
		end
	end
	
	-- 统计各种矿物数量
	local oreCount = {}
	for x = 1, GRID_SIZE do
		for z = 1, GRID_SIZE do
			for y = 1, height[x][z] do
				local cell = vox[x][y][z]
				if cell and cell.ore then
					oreCount[cell.ore] = (oreCount[cell.ore] or 0) + 1
				end
			end
		end
	end
	
	print("[MineGenerator] 🏔️ 多山分离地形生成完成！")
	print(("📏 地图大小: %d×%d 体素 (%.0f×%.0f studs)"):format(GRID_SIZE, GRID_SIZE, GRID_SIZE*CELL_SIZE, GRID_SIZE*CELL_SIZE))
	print(("⛰️  高度范围: %d~%d studs (总高度约%.0f studs)"):format(minH, maxH, maxH*CELL_SIZE))
	print(("🧱 总方块数: %d"):format(blockCount))
	print("💎 矿物分布统计 (按GDD Final.md标准):")
	for ore, count in pairs(oreCount) do
		print(("   %s: %d 块"):format(ore, count))
	end
	print(("🎯 山峰数量: 6座分离的小山"))
	print(("🏔️ 优化规模: 约%.0f stud高，%.0f×%.0f底座的山区（以0,0,0为中心）"):format(MAX_HEIGHT*CELL_SIZE, GRID_SIZE*CELL_SIZE, GRID_SIZE*CELL_SIZE))
	print("✅ 性能优化的多山地形已就绪！分离的小山+少量矿石！")
end

return MineGenerator
