local RS        = game:GetService("ReplicatedStorage")
local Players   = game:GetService("Players")
local player    = Players.LocalPlayer

-- 创建返回主城的RemoteEvent
local returnEvent = RS:FindFirstChild("ReturnHomeEvent") or Instance.new("RemoteEvent", RS)
returnEvent.Name = "ReturnHomeEvent"

-- 创建简单的返回按钮UI
local function createReturnUI()
    local screenGui = player:WaitForChild("PlayerGui"):FindFirstChild("MineReturnGui")
    if not screenGui then
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "MineReturnGui"
        screenGui.Parent = player.PlayerGui
    end
    
    local returnBtn = screenGui:FindFirstChild("ReturnBtn")
    if not returnBtn then
        returnBtn = Instance.new("TextButton")
        returnBtn.Name = "ReturnBtn"
        returnBtn.Size = UDim2.new(0, 120, 0, 40)
        returnBtn.Position = UDim2.new(1, -130, 0, 10)
        returnBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
        returnBtn.Text = "返回主城"
        returnBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        returnBtn.TextScaled = true
        returnBtn.Font = Enum.Font.SourceSansBold
        returnBtn.Parent = screenGui
        
        -- 添加按钮点击效果
        returnBtn.Activated:Connect(function()
            returnEvent:FireServer()
        end)
    end
end

-- 在玩家加载后创建UI
if player.Character then
    createReturnUI()
else
    player.CharacterAdded:Connect(createReturnUI)
end