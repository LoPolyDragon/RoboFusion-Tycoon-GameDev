--------------------------------------------------------------------
-- TierTestCommands.server.lua · Tier系统测试命令
-- 功能：提供测试命令来验证Tier解锁系统功能
--------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 加载模块
local ServerModules = script.Parent:WaitForChild("ServerModules")
local GameLogic = require(ServerModules.GameLogicServer)
local TierManager = require(ServerModules.TierManager)

-- 管理员用户ID列表
local ADMIN_IDS = {5383359631} -- 替换为你的Roblox用户ID

-- 检查是否为管理员
local function isAdmin(player)
    for _, id in ipairs(ADMIN_IDS) do
        if player.UserId == id then
            return true
        end
    end
    return false
end

-- 等待系统初始化
task.wait(3)

-- 处理聊天命令
local function handleCommand(player, message)
    if not isAdmin(player) then return end
    
    local args = string.split(message, " ")
    local command = args[1]:lower()
    
    if command == "/tierinfo" then
        -- 显示当前Tier信息
        local tierInfo = GameLogic.GetTierInfo(player)
        if tierInfo then
            print("=== 当前Tier信息 ===")
            print(("玩家: %s"):format(player.Name))
            print(("Tier: %d"):format(tierInfo.tier))
            print(("名称: %s"):format(tierInfo.name))
            print(("描述: %s"):format(tierInfo.description))
            print("解锁内容:", table.concat(tierInfo.unlocks, ", "))
        else
            print("[TierTest] 无法获取Tier信息")
        end
        
    elseif command == "/nexttierprogress" then
        -- 显示下一Tier进度
        local nextTier = GameLogic.GetNextTierProgress(player)
        if nextTier then
            print("=== 下一Tier进度 ===")
            print(("目标Tier: %d - %s"):format(nextTier.tier, nextTier.name))
            print(("描述: %s"):format(nextTier.description))
            print("进度要求:")
            for reqType, progressInfo in pairs(nextTier.progress) do
                local status = progressInfo.completed and "✅" or "❌"
                print(("  %s %s: %d/%d"):format(status, reqType, progressInfo.current, progressInfo.required))
            end
        else
            print("[TierTest] 已达最高Tier或无法获取进度")
        end
        
    elseif command == "/alltiers" then
        -- 显示所有Tier概览
        local allTiers = GameLogic.GetAllTiersOverview(player)
        print("=== 所有Tier概览 ===")
        for _, tierInfo in ipairs(allTiers) do
            local status = tierInfo.isCurrent and "🔸当前" or 
                          tierInfo.isUnlocked and "✅已解锁" or "🔒锁定"
            print(("Tier %d: %s %s"):format(tierInfo.tier, tierInfo.name, status))
        end
        
    elseif command == "/addscrap" and args[2] then
        -- 添加Scrap来测试进度
        local amount = tonumber(args[2]) or 100
        GameLogic.AddScrap(player, amount)
        print(("[TierTest] 添加了 %d Scrap"):format(amount))
        
    elseif command == "/additem" and args[2] and args[3] then
        -- 添加指定物品
        local itemId = args[2]
        local amount = tonumber(args[3]) or 1
        GameLogic.AddItem(player, itemId, amount)
        print(("[TierTest] 添加了 %d x %s"):format(amount, itemId))
        
    elseif command == "/setdepth" and args[2] then
        -- 设置深度记录
        local depth = tonumber(args[2]) or 0
        local playerData = GameLogic.GetPlayerData(player)
        if playerData then
            playerData.MaxDepthReached = depth
            print(("[TierTest] 设置最大深度为 %d"):format(depth))
        end
        
    elseif command == "/completetutorial" then
        -- 标记教程完成
        GameLogic.MarkTutorialComplete(player)
        print(("[TierTest] 玩家 %s 教程已标记为完成"):format(player.Name))
        
    elseif command == "/upgradebuilding" and args[2] then
        -- 升级建筑
        local buildingType = args[2]
        local success, message = GameLogic.UpgradeMachine(player, buildingType)
        print(("[TierTest] 升级 %s: %s - %s"):format(buildingType, success and "成功" or "失败", message))
        
    elseif command == "/forcetierupgrade" and args[2] then
        -- 强制升级到指定Tier (仅用于测试)
        local targetTier = tonumber(args[2])
        if targetTier and targetTier >= 0 and targetTier <= 4 then
            local playerData = GameLogic.GetPlayerData(player)
            if playerData then
                playerData.CurrentTier = targetTier
                print(("[TierTest] 强制升级玩家 %s 到 Tier %d"):format(player.Name, targetTier))
            end
        else
            print("[TierTest] 无效的Tier等级 (0-4)")
        end
        
    elseif command == "/simulatemining" then
        -- 模拟挖矿进度
        print("[TierTest] 模拟挖矿进度...")
        
        -- 添加各种矿物
        GameLogic.AddItem(player, "IronOre", 50)
        GameLogic.AddItem(player, "BronzeOre", 30) 
        GameLogic.AddItem(player, "GoldOre", 20)
        GameLogic.AddItem(player, "DiamondOre", 10)
        GameLogic.AddItem(player, "TitaniumOre", 5)
        
        -- 添加制作材料
        GameLogic.AddItem(player, "IronBar", 20)
        GameLogic.AddItem(player, "BronzeGear", 15)
        GameLogic.AddItem(player, "GoldPlatedEdge", 10)
        
        -- 设置深度和Scrap
        local playerData = GameLogic.GetPlayerData(player)
        if playerData then
            playerData.MaxDepthReached = 200
            playerData.TierProgress.energyStationsBuilt = 2
            playerData.TierProgress.maxBuildingLevel = 10
        end
        
        GameLogic.AddScrap(player, 500)
        GameLogic.MarkTutorialComplete(player)
        
        print("[TierTest] 挖矿进度模拟完成")
        
    elseif command == "/resetprogress" then
        -- 重置进度
        local playerData = GameLogic.GetPlayerData(player)
        if playerData then
            playerData.CurrentTier = 0
            playerData.MaxDepthReached = 0
            playerData.TierProgress = {
                tutorialComplete = false,
                scrapCollected = 0,
                ironOreCollected = 0,
                bronzeOreCollected = 0,
                goldOreCollected = 0,
                diamondOreCollected = 0,
                titaniumOreCollected = 0,
                ironBarCrafted = 0,
                bronzeGearCrafted = 0,
                goldPlatedEdgeCrafted = 0,
                energyStationsBuilt = 0,
                maxBuildingLevel = 1
            }
            playerData.Scrap = 0
            playerData.Inventory = {}
            print(("[TierTest] 重置了玩家 %s 的所有进度"):format(player.Name))
        end
        
    elseif command == "/tierhelp" then
        -- 显示帮助信息
        print("=== Tier系统测试命令 ===")
        print("/tierinfo - 查看当前Tier信息")
        print("/nexttierprogress - 查看下一Tier进度")
        print("/alltiers - 查看所有Tier概览")
        print("/addscrap [数量] - 添加Scrap")
        print("/additem [物品ID] [数量] - 添加指定物品")
        print("/setdepth [深度] - 设置最大深度记录")
        print("/completetutorial - 标记教程完成")
        print("/upgradebuilding [建筑类型] - 升级建筑")
        print("/forcetierupgrade [Tier] - 强制升级到指定Tier (0-4)")
        print("/simulatemining - 模拟完整的挖矿进度")
        print("/resetprogress - 重置所有进度")
        print("/tierhelp - 显示此帮助")
        
    elseif command == "/testunlocks" then
        -- 测试解锁状态
        local tools = {"WoodPick", "IronPick", "BronzePick", "GoldPick", "DiamondPick"}
        local buildings = {"Crusher", "Generator", "Assembler", "Shipper", "ToolForge", "Smelter", "EnergyStation"}
        
        print("=== 工具解锁状态 ===")
        for _, tool in ipairs(tools) do
            local unlocked = GameLogic.IsToolUnlocked(player, tool)
            print(("  %s: %s"):format(tool, unlocked and "✅解锁" or "🔒锁定"))
        end
        
        print("=== 建筑解锁状态 ===")
        for _, building in ipairs(buildings) do
            local unlocked = GameLogic.IsBuildingUnlocked(player, building)
            print(("  %s: %s"):format(building, unlocked and "✅解锁" or "🔒锁定"))
        end
        
    elseif command == "/testupgradelimit" and args[2] and args[3] then
        -- 测试建筑升级限制
        local buildingType = args[2]
        local targetLevel = tonumber(args[3])
        
        if targetLevel then
            local canUpgrade, message = TierManager.CanUpgradeBuilding(player, buildingType, targetLevel)
            print(("[TierTest] 升级 %s 到 Lv%d: %s - %s"):format(
                buildingType, targetLevel, canUpgrade and "可以" or "不可以", message))
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(message)
        if message:sub(1, 1) == "/" then
            handleCommand(player, message)
        end
    end)
end)

-- 为已经在游戏中的玩家连接
for _, player in pairs(Players:GetPlayers()) do
    player.Chatted:Connect(function(message)
        if message:sub(1, 1) == "/" then
            handleCommand(player, message)
        end
    end)
end

print("[TierTestCommands] Tier系统测试命令已加载")
print("管理员命令: /tierhelp 查看所有可用命令")