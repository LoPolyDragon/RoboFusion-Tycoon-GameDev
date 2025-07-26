--------------------------------------------------------------------
-- WorldSetupTester.server.lua · 世界设置测试工具
-- 功能：测试地板、出生点和排行榜系统
--------------------------------------------------------------------

local Players = game:GetService("Players")

-- 添加测试命令
Players.PlayerAdded:Connect(function(player)
    -- 只为管理员添加命令
    if player.Name == "TheFuture1199" or player.UserId == game.CreatorId then
        player.Chatted:Connect(function(message)
            local args = message:lower():split(" ")
            local command = args[1]
            
            if command == "/testworld" then
                print("[WorldSetupTester] 测试世界设置...")
                
                -- 检查地板
                local floorTiles = workspace:FindFirstChild("FloorTiles")
                if floorTiles then
                    print("✅ 地板系统: 找到", #floorTiles:GetChildren(), "个地板块")
                else
                    print("❌ 地板系统: 未找到地板")
                end
                
                -- 检查出生点
                local spawn = workspace:FindFirstChild("MainSpawn")
                if spawn then
                    print("✅ 出生点: 位置", spawn.Position)
                else
                    print("❌ 出生点: 未找到")
                end
                
                -- 检查排行榜
                local leaderboards = {"最多金币Leaderboard", "最长游戏时间Leaderboard", "最多机器人Leaderboard"}
                for _, name in ipairs(leaderboards) do
                    local lb = workspace:FindFirstChild(name)
                    if lb then
                        print("✅ 排行榜:", name, "位置", lb.Position)
                    else
                        print("❌ 排行榜:", name, "未找到")
                    end
                end
                
            elseif command == "/addcredits" then
                local amount = tonumber(args[2]) or 1000
                local ServerModules = script.Parent:WaitForChild("ServerModules")
                local GameLogic = require(ServerModules.GameLogicServer)
                GameLogic.AddCredits(player, amount)
                print("[WorldSetupTester] 添加", amount, "金币给", player.Name)
                
            elseif command == "/addbots" then
                local amount = tonumber(args[2]) or 10
                local ServerModules = script.Parent:WaitForChild("ServerModules")
                local GameLogic = require(ServerModules.GameLogicServer)
                GameLogic.AddItem(player, "Dig_UncommonBot", amount)
                print("[WorldSetupTester] 添加", amount, "个机器人给", player.Name)
                
            elseif command == "/resetdata" then
                local ServerModules = script.Parent:WaitForChild("ServerModules")
                local GameLogic = require(ServerModules.GameLogicServer)
                local GameConstants = require(game.ReplicatedStorage.SharedModules.GameConstants.main)
                
                -- 重置玩家数据为默认值
                GameLogic.BindProfile(player, GameConstants.DEFAULT_DATA)
                print("[WorldSetupTester] 重置", player.Name, "的数据")
                
            elseif command == "/worldhelp" then
                print("[WorldSetupTester] 可用命令:")
                print("  /testworld - 测试世界设置")
                print("  /addcredits [数量] - 添加金币")
                print("  /addbots [数量] - 添加机器人")
                print("  /resetdata - 重置玩家数据")
            end
        end)
    end
end)

print("[WorldSetupTester] 世界设置测试工具已启动")
print("管理员可使用 /worldhelp 查看命令")