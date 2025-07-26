--------------------------------------------------------------------
-- TutorialDebug.server.lua · 教程系统调试脚本
-- 用于诊断教程系统问题
--------------------------------------------------------------------

print("[TutorialDebug] 开始诊断教程系统...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 检查基础服务
local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
local rfFolder = ReplicatedStorage:FindFirstChild("RemoteFunctions")

print("[TutorialDebug] RemoteEvents存在:", remoteFolder ~= nil)
print("[TutorialDebug] RemoteFunctions存在:", rfFolder ~= nil)

if remoteFolder then
    local tutorialEvent = remoteFolder:FindFirstChild("TutorialEvent")
    print("[TutorialDebug] TutorialEvent存在:", tutorialEvent ~= nil)
end

if rfFolder then
    local tutorialFunction = rfFolder:FindFirstChild("TutorialFunction")
    print("[TutorialDebug] TutorialFunction存在:", tutorialFunction ~= nil)
end

-- 检查ServerModules
local ServerModules = script.Parent:FindFirstChild("ServerModules")
print("[TutorialDebug] ServerModules存在:", ServerModules ~= nil)

if ServerModules then
    local GameLogic = ServerModules:FindFirstChild("GameLogicServer")
    print("[TutorialDebug] GameLogicServer存在:", GameLogic ~= nil)
end

-- 检查TutorialManager是否存在
local TutorialManager = script.Parent:FindFirstChild("TutorialManager")
print("[TutorialDebug] TutorialManager脚本存在:", TutorialManager ~= nil)

print("[TutorialDebug] 诊断完成")