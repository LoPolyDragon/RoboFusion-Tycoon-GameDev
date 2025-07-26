--------------------------------------------------------------------
-- TutorialTester.client.lua · 教程系统测试工具
-- 功能：
--   1) 提供手动触发教程的按键
--   2) 测试教程系统的各个步骤
--   3) 提供调试信息显示
--------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- 远程通信
local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local rfFolder = ReplicatedStorage:WaitForChild("RemoteFunctions")

local tutorialEvent = remoteFolder:WaitForChild("TutorialEvent")
local tutorialFunction = rfFolder:WaitForChild("TutorialFunction")

-- 测试快捷键
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end
    
    if input.KeyCode == Enum.KeyCode.F then
        -- F: 开始教程
        print("[TutorialTester] F键被按下，尝试启动教程")
        if tutorialFunction then
            local success, errorMsg = pcall(function()
                return tutorialFunction:InvokeServer("START_TUTORIAL")
            end)
            if success then
                print("[TutorialTester] 手动启动教程:", errorMsg)
            else
                warn("[TutorialTester] 启动教程失败:", errorMsg)
            end
        else
            warn("[TutorialTester] tutorialFunction 不存在")
        end
        
    elseif input.KeyCode == Enum.KeyCode.F6 then
        -- F6: 跳过教程
        if tutorialFunction then
            local success = tutorialFunction:InvokeServer("SKIP_TUTORIAL")
            print("[TutorialTester] 跳过教程:", success)
        end
        
    elseif input.KeyCode == Enum.KeyCode.F7 then
        -- F7: 获取教程进度
        if tutorialFunction then
            local progress = tutorialFunction:InvokeServer("GET_TUTORIAL_PROGRESS")
            print("[TutorialTester] 教程进度:")
            if progress then
                for key, value in pairs(progress) do
                    print("  ", key, ":", value)
                end
            else
                print("  无进度数据")
            end
        end
        
    elseif input.KeyCode == Enum.KeyCode.F8 then
        -- F8: 显示帮助
        print("[TutorialTester] 教程测试工具帮助:")
        print("  F   - 开始教程")
        print("  F6  - 跳过教程") 
        print("  F7  - 查看教程进度")
        print("  F8  - 显示帮助")
        print("  M   - 模拟挖矿（在MiningProgressTracker中）")
    end
end)

-- 启动时显示帮助
task.spawn(function()
    task.wait(3)
    print("[TutorialTester] 教程测试工具已加载")
    print("按 F8 查看可用快捷键")
end)