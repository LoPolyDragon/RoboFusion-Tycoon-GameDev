--------------------------------------------------------------------
-- MiningProgressTracker.client.lua · 挖矿进度跟踪（教程集成）
-- 功能：
--   1) 监听挖矿活动
--   2) 追踪挖取的矿石类型和数量
--   3) 通知教程系统挖矿进度
--------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- 教程系统集成
local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local tutorialEvent = remoteFolder:FindFirstChild("TutorialEvent")

-- 挖矿进度追踪
local miningProgress = {
    oreCount = 0,
    oreTypes = {},
    lastOreType = nil
}

-- 模拟挖矿活动（当玩家在矿区时）
local function simulateMiningActivity()
    -- 这里应该连接到实际的挖矿系统
    -- 目前创建一个简单的模拟系统供教程使用
    
    if not tutorialEvent then
        return
    end
    
    -- 检查玩家是否在矿区（通过判断游戏地点）
    local currentPlace = game.PlaceId
    
    -- 简单的键盘输入模拟挖矿（仅用于测试教程）
    local UserInputService = game:GetService("UserInputService")
    
    UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent then return end
        
        -- M键模拟挖矿（仅用于教程测试）
        if input.KeyCode == Enum.KeyCode.M then
            miningProgress.oreCount = miningProgress.oreCount + 1
            miningProgress.lastOreType = "Copper" -- 模拟铜矿
            
            if not miningProgress.oreTypes["Copper"] then
                miningProgress.oreTypes["Copper"] = 0
            end
            miningProgress.oreTypes["Copper"] = miningProgress.oreTypes["Copper"] + 1
            
            print("[MiningProgressTracker] 模拟挖矿 - 总数:", miningProgress.oreCount, "类型:", miningProgress.lastOreType)
            
            -- 检查是否达到教程要求（挖取8块同类矿石）
            if miningProgress.oreTypes["Copper"] >= 8 then
                tutorialEvent:FireServer("STEP_COMPLETED", "MINING_TUTORIAL", {
                    oreCount = miningProgress.oreTypes["Copper"],
                    oreType = "Copper"
                })
                print("[MiningProgressTracker] 教程挖矿任务完成！")
            end
        end
    end)
end

-- 初始化
task.spawn(function()
    task.wait(2) -- 等待其他系统加载
    simulateMiningActivity()
    print("[MiningProgressTracker] 挖矿进度追踪系统已启动")
    print("按 M 键模拟挖矿（教程测试用）")
end)

-- 当实际的挖矿系统可用时，应该替换上面的模拟代码
-- 连接到真实的挖矿事件
--[[
local realMiningEvent = remoteFolder:FindFirstChild("MiningResultEvent")
if realMiningEvent then
    realMiningEvent.OnClientEvent:Connect(function(oreType, quantity)
        miningProgress.oreCount = miningProgress.oreCount + quantity
        miningProgress.lastOreType = oreType
        
        if not miningProgress.oreTypes[oreType] then
            miningProgress.oreTypes[oreType] = 0
        end
        miningProgress.oreTypes[oreType] = miningProgress.oreTypes[oreType] + quantity
        
        -- 检查教程进度
        if tutorialEvent and miningProgress.oreTypes[oreType] >= 8 then
            tutorialEvent:FireServer("STEP_COMPLETED", "MINING_TUTORIAL", {
                oreCount = miningProgress.oreTypes[oreType],
                oreType = oreType
            })
        end
    end)
end
]]

print("[MiningProgressTracker] 挖矿进度追踪器已加载")