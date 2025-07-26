--------------------------------------------------------------------
-- TutorialController.client.lua · 新手教程客户端控制器
-- 功能：
--   1) 接收服务器教程指令
--   2) 显示教程UI和引导
--   3) 处理玩家交互
--   4) 管理教程状态
--   5) 与现有UI系统协调
--------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 等待远程通信
local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local rfFolder = ReplicatedStorage:WaitForChild("RemoteFunctions")

local tutorialEvent = remoteFolder:WaitForChild("TutorialEvent")
local tutorialFunction = rfFolder:WaitForChild("TutorialFunction")

-- 教程状态
local tutorialState = {
	isActive = false,
	currentStep = 0,
	stepData = nil,
	ui = nil,
	overlays = {},
	connections = {},
}

-- 创建教程主UI
local function createTutorialUI()
	print("[TutorialController] 开始创建教程UI")
	
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "TutorialUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 100 -- 确保在最上层
	screenGui.Parent = playerGui
	
	print("[TutorialController] ScreenGui已创建并添加到PlayerGui")

	-- 半透明背景遮罩
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.3
	overlay.BorderSizePixel = 0
	overlay.Visible = false
	overlay.Parent = screenGui

	-- 教程面板 - 增大尺寸并调整位置
	local tutorialPanel = Instance.new("Frame")
	tutorialPanel.Name = "TutorialPanel"
	tutorialPanel.Size = UDim2.new(0, 500, 0, 250)
	tutorialPanel.Position = UDim2.new(0, 20, 1, -270)
	tutorialPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	tutorialPanel.BorderSizePixel = 0
	tutorialPanel.Visible = false
	tutorialPanel.Parent = screenGui
	
	-- 添加边框效果
	local border = Instance.new("UIStroke")
	border.Color = Color3.fromRGB(255, 215, 0)
	border.Thickness = 2
	border.Parent = tutorialPanel

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 12)
	panelCorner.Parent = tutorialPanel

	-- 渐变背景
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 35, 45)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 35)),
	})
	gradient.Rotation = 45
	gradient.Parent = tutorialPanel

	-- 步骤标题
	local stepTitle = Instance.new("TextLabel")
	stepTitle.Name = "StepTitle"
	stepTitle.Size = UDim2.new(1, -20, 0, 40)
	stepTitle.Position = UDim2.new(0, 10, 0, 10)
	stepTitle.BackgroundTransparency = 1
	stepTitle.Text = "教程步骤"
	stepTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
	stepTitle.TextScaled = true
	stepTitle.Font = Enum.Font.GothamBold
	stepTitle.TextXAlignment = Enum.TextXAlignment.Left
	stepTitle.Parent = tutorialPanel

	-- 步骤描述 - 增大尺寸
	local stepDescription = Instance.new("TextLabel")
	stepDescription.Name = "StepDescription"
	stepDescription.Size = UDim2.new(1, -20, 0, 120)
	stepDescription.Position = UDim2.new(0, 10, 0, 55)
	stepDescription.BackgroundTransparency = 1
	stepDescription.Text = "请按照指示完成操作"
	stepDescription.TextColor3 = Color3.fromRGB(255, 255, 255)
	stepDescription.TextSize = 16
	stepDescription.Font = Enum.Font.Gotham
	stepDescription.TextXAlignment = Enum.TextXAlignment.Left
	stepDescription.TextYAlignment = Enum.TextYAlignment.Top
	stepDescription.TextWrapped = true
	stepDescription.Parent = tutorialPanel

	-- 进度条背景
	local progressBg = Instance.new("Frame")
	progressBg.Name = "ProgressBg"
	progressBg.Size = UDim2.new(1, -20, 0, 10)
	progressBg.Position = UDim2.new(0, 10, 0, 185)
	progressBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	progressBg.BorderSizePixel = 0
	progressBg.Parent = tutorialPanel

	local progressBgCorner = Instance.new("UICorner")
	progressBgCorner.CornerRadius = UDim.new(0, 4)
	progressBgCorner.Parent = progressBg

	-- 进度条
	local progressBar = Instance.new("Frame")
	progressBar.Name = "ProgressBar"
	progressBar.Size = UDim2.new(0, 0, 1, 0)
	progressBar.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
	progressBar.BorderSizePixel = 0
	progressBar.Parent = progressBg

	local progressBarCorner = Instance.new("UICorner")
	progressBarCorner.CornerRadius = UDim.new(0, 4)
	progressBarCorner.Parent = progressBar

	-- 按钮容器
	local buttonContainer = Instance.new("Frame")
	buttonContainer.Name = "ButtonContainer"
	buttonContainer.Size = UDim2.new(1, -20, 0, 35)
	buttonContainer.Position = UDim2.new(0, 10, 0, 205)
	buttonContainer.BackgroundTransparency = 1
	buttonContainer.Parent = tutorialPanel

	-- 提示按钮
	local hintButton = Instance.new("TextButton")
	hintButton.Name = "HintButton"
	hintButton.Size = UDim2.new(0, 80, 1, 0)
	hintButton.Position = UDim2.new(0, 0, 0, 0)
	hintButton.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
	hintButton.Text = "提示"
	hintButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	hintButton.TextScaled = true
	hintButton.Font = Enum.Font.GothamBold
	hintButton.BorderSizePixel = 0
	hintButton.Parent = buttonContainer

	local hintCorner = Instance.new("UICorner")
	hintCorner.CornerRadius = UDim.new(0, 6)
	hintCorner.Parent = hintButton

	-- 跳过按钮
	local skipButton = Instance.new("TextButton")
	skipButton.Name = "SkipButton"
	skipButton.Size = UDim2.new(0, 80, 1, 0)
	skipButton.Position = UDim2.new(1, -80, 0, 0)
	skipButton.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
	skipButton.Text = "跳过"
	skipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	skipButton.TextScaled = true
	skipButton.Font = Enum.Font.GothamBold
	skipButton.BorderSizePixel = 0
	skipButton.Parent = buttonContainer

	local skipCorner = Instance.new("UICorner")
	skipCorner.CornerRadius = UDim.new(0, 6)
	skipCorner.Parent = skipButton

	return {
		gui = screenGui,
		overlay = overlay,
		panel = tutorialPanel,
		stepTitle = stepTitle,
		stepDescription = stepDescription,
		progressBar = progressBar,
		hintButton = hintButton,
		skipButton = skipButton,
	}
end

-- 创建高亮覆盖层
local function createHighlightOverlay(targetGui)
	if not targetGui then
		return nil
	end

	local highlight = Instance.new("Frame")
	highlight.Name = "TutorialHighlight"
	highlight.Size = UDim2.new(1, 10, 1, 10)
	highlight.Position = UDim2.new(0, -5, 0, -5)
	highlight.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
	highlight.BackgroundTransparency = 0.7
	highlight.BorderSizePixel = 0
	highlight.ZIndex = targetGui.ZIndex + 1
	highlight.Parent = targetGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = highlight

	-- 脉冲动画
	local pulseInfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	local pulseTween = TweenService:Create(highlight, pulseInfo, {
		BackgroundTransparency = 0.3,
	})
	pulseTween:Play()

	return highlight
end

-- 创建指向箭头
local function createArrow(targetPosition, direction)
	direction = direction or "down"

	local arrow = Instance.new("ImageLabel")
	arrow.Name = "TutorialArrow"
	arrow.Size = UDim2.new(0, 40, 0, 40)
	arrow.BackgroundTransparency = 1
	arrow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png" -- 临时占位符
	arrow.ImageColor3 = Color3.fromRGB(255, 215, 0)
	arrow.ZIndex = 200

	-- 根据方向调整位置和旋转
	if direction == "down" then
		arrow.Position = UDim2.new(0, targetPosition.X - 20, 0, targetPosition.Y - 50)
		arrow.Rotation = 0
	elseif direction == "up" then
		arrow.Position = UDim2.new(0, targetPosition.X - 20, 0, targetPosition.Y + 10)
		arrow.Rotation = 180
	elseif direction == "left" then
		arrow.Position = UDim2.new(0, targetPosition.X + 10, 0, targetPosition.Y - 20)
		arrow.Rotation = 90
	elseif direction == "right" then
		arrow.Position = UDim2.new(0, targetPosition.X - 50, 0, targetPosition.Y - 20)
		arrow.Rotation = -90
	end

	arrow.Parent = tutorialState.ui.gui

	-- 弹跳动画
	local bounceInfo = TweenInfo.new(0.5, Enum.EasingStyle.Bounce, Enum.EasingDirection.InOut, -1, true)
	local bounceTween = TweenService:Create(arrow, bounceInfo, {
		Position = arrow.Position + UDim2.new(0, 0, 0, direction == "down" and -10 or 10),
	})
	bounceTween:Play()

	return arrow
end

-- 显示跳过确认对话框 (moved up to fix undefined variable error)
local function showSkipConfirmation()
	local confirmGui = Instance.new("ScreenGui")
	confirmGui.Name = "SkipConfirmation"
	confirmGui.ResetOnSpawn = false
	confirmGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	confirmGui.DisplayOrder = 150
	confirmGui.Parent = playerGui

	-- 背景遮罩
	local backdrop = Instance.new("Frame")
	backdrop.Size = UDim2.new(1, 0, 1, 0)
	backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	backdrop.BackgroundTransparency = 0.5
	backdrop.BorderSizePixel = 0
	backdrop.Parent = confirmGui

	-- 确认对话框
	local dialog = Instance.new("Frame")
	dialog.Size = UDim2.new(0, 300, 0, 150)
	dialog.Position = UDim2.new(0.5, -150, 0.5, -75)
	dialog.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	dialog.BorderSizePixel = 0
	dialog.Parent = confirmGui

	local dialogCorner = Instance.new("UICorner")
	dialogCorner.CornerRadius = UDim.new(0, 12)
	dialogCorner.Parent = dialog

	-- 标题
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0, 40)
	title.Position = UDim2.new(0, 10, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "跳过教程"
	title.TextColor3 = Color3.fromRGB(255, 215, 0)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = dialog

	-- 内容
	local content = Instance.new("TextLabel")
	content.Size = UDim2.new(1, -20, 0, 50)
	content.Position = UDim2.new(0, 10, 0, 50)
	content.BackgroundTransparency = 1
	content.Text = "确定要跳过新手教程吗？\n您将错过重要的游戏指导。"
	content.TextColor3 = Color3.fromRGB(255, 255, 255)
	content.TextScaled = true
	content.Font = Enum.Font.Gotham
	content.TextWrapped = true
	content.Parent = dialog

	-- 按钮容器
	local buttonFrame = Instance.new("Frame")
	buttonFrame.Size = UDim2.new(1, -20, 0, 30)
	buttonFrame.Position = UDim2.new(0, 10, 1, -40)
	buttonFrame.BackgroundTransparency = 1
	buttonFrame.Parent = dialog

	-- 取消按钮
	local cancelButton = Instance.new("TextButton")
	cancelButton.Size = UDim2.new(0, 80, 1, 0)
	cancelButton.Position = UDim2.new(0, 0, 0, 0)
	cancelButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	cancelButton.Text = "取消"
	cancelButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	cancelButton.TextScaled = true
	cancelButton.Font = Enum.Font.GothamBold
	cancelButton.BorderSizePixel = 0
	cancelButton.Parent = buttonFrame

	local cancelCorner = Instance.new("UICorner")
	cancelCorner.CornerRadius = UDim.new(0, 6)
	cancelCorner.Parent = cancelButton

	-- 确认按钮
	local confirmButton = Instance.new("TextButton")
	confirmButton.Size = UDim2.new(0, 80, 1, 0)
	confirmButton.Position = UDim2.new(1, -80, 0, 0)
	confirmButton.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
	confirmButton.Text = "跳过"
	confirmButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	confirmButton.TextScaled = true
	confirmButton.Font = Enum.Font.GothamBold
	confirmButton.BorderSizePixel = 0
	confirmButton.Parent = buttonFrame

	local confirmCorner = Instance.new("UICorner")
	confirmCorner.CornerRadius = UDim.new(0, 6)
	confirmCorner.Parent = confirmButton

	-- 按钮事件
	cancelButton.MouseButton1Click:Connect(function()
		confirmGui:Destroy()
	end)

	confirmButton.MouseButton1Click:Connect(function()
		tutorialFunction:InvokeServer("SKIP_TUTORIAL")
		confirmGui:Destroy()
	end)

	-- 显示动画
	dialog.Size = UDim2.new(0, 0, 0, 0)
	dialog.Position = UDim2.new(0.5, 0, 0.5, 0)

	local showTween = TweenService:Create(dialog, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 300, 0, 150),
		Position = UDim2.new(0.5, -150, 0.5, -75),
	})
	showTween:Play()
end

-- 显示教程UI
local function showTutorialUI()
	print("[TutorialController] showTutorialUI 被调用")
	
	if not tutorialState.ui then
		print("[TutorialController] 创建新的教程UI")
		tutorialState.ui = createTutorialUI()

		-- 绑定按钮事件
		tutorialState.ui.hintButton.MouseButton1Click:Connect(function()
			tutorialEvent:FireServer("REQUEST_HINT")
		end)

		tutorialState.ui.skipButton.MouseButton1Click:Connect(function()
			showSkipConfirmation()
		end)
	end

	print("[TutorialController] 设置教程面板可见")
	tutorialState.ui.panel.Visible = true

	-- 滑入动画
	tutorialState.ui.panel.Position = UDim2.new(0, -500, 1, -270)
	local slideIn = TweenService:Create(
		tutorialState.ui.panel,
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0, 20, 1, -270) }
	)
	slideIn:Play()
end

-- 隐藏教程UI
local function hideTutorialUI()
	if not tutorialState.ui then
		return
	end

	local slideOut = TweenService:Create(
		tutorialState.ui.panel,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Position = UDim2.new(0, -500, 1, -270) }
	)
	slideOut:Play()

	slideOut.Completed:Connect(function()
		tutorialState.ui.panel.Visible = false
	end)
end

-- 更新教程UI内容
local function updateTutorialUI(stepData, currentStep, totalSteps)
	if not tutorialState.ui or not stepData then
		return
	end

	tutorialState.ui.stepTitle.Text = string.format("步骤 %d/%d: %s", currentStep, totalSteps, stepData.name)
	tutorialState.ui.stepDescription.Text = stepData.description

	-- 更新进度条
	local progress = currentStep / totalSteps
	local progressTween = TweenService:Create(
		tutorialState.ui.progressBar,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = UDim2.new(progress, 0, 1, 0) }
	)
	progressTween:Play()
end

-- 清理教程覆盖层
local function clearOverlays()
	for _, overlay in pairs(tutorialState.overlays) do
		if overlay and overlay.Parent then
			overlay:Destroy()
		end
	end
	tutorialState.overlays = {}
end

-- 处理特定步骤的UI交互
local function handleStepInteraction(stepData)
	clearOverlays()

	if stepData.type == "UI_INTERACTION" then
		-- 查找目标UI元素并高亮
		local targetGui = nil

		if stepData.target == "BuildingShopButton" then
			-- 查找建筑商店按钮
			local buildingShopButtonUI = playerGui:FindFirstChild("BuildingShopButtonUI")
			if buildingShopButtonUI then
				-- 查找TextButton类型的BUILD按钮
				for _, child in pairs(buildingShopButtonUI:GetChildren()) do
					if child:IsA("TextButton") and string.find(child.Text, "BUILD") then
						targetGui = child
						break
					end
				end
			end
		end

		if targetGui then
			local highlight = createHighlightOverlay(targetGui)
			if highlight then
				table.insert(tutorialState.overlays, highlight)
			end

			-- 创建指向箭头
			local arrow = createArrow(
				Vector2.new(
					targetGui.AbsolutePosition.X + targetGui.AbsoluteSize.X / 2,
					targetGui.AbsolutePosition.Y + targetGui.AbsoluteSize.Y / 2
				),
				"down"
			)
			if arrow then
				table.insert(tutorialState.overlays, arrow)
			end
		end
	end
end

--------------------------------------------------------------------
-- 服务器事件处理
--------------------------------------------------------------------

-- 处理教程事件
tutorialEvent.OnClientEvent:Connect(function(action, data)
	if action == "START_TUTORIAL" then
		print("[TutorialController] 开始教程")
		tutorialState.isActive = true
		tutorialState.currentStep = data.currentStep
		tutorialState.stepData = data.stepData

		-- 如果第一步是降落舱序列，启动降落舱动画
		if data.stepData and data.stepData.id == "LANDING_POD" then
			local landingPodModule = script.Parent:FindFirstChild("LandingPodSequenceModule")
			if landingPodModule then
				local success, LandingPodSequence = pcall(require, landingPodModule)
				if success and LandingPodSequence then
					task.spawn(function()
						task.wait(1) -- 稍微延迟启动
						LandingPodSequence.playSequence()
					end)
				else
					warn("[TutorialController] 加载LandingPodSequence模块失败:", LandingPodSequence)
				end
			else
				warn("[TutorialController] 找不到LandingPodSequenceModule脚本")
			end
		end

		print("[TutorialController] 准备显示教程UI...")
		showTutorialUI()
		print("[TutorialController] 更新教程UI内容...")
		updateTutorialUI(data.stepData, data.currentStep, 9)
		print("[TutorialController] 处理步骤交互...")
		handleStepInteraction(data.stepData)
		print("[TutorialController] 教程UI初始化完成")
	elseif action == "NEXT_STEP" then
		print("[TutorialController] 下一步:", data.currentStep)
		tutorialState.currentStep = data.currentStep
		tutorialState.stepData = data.stepData

		updateTutorialUI(data.stepData, data.currentStep, 9)
		handleStepInteraction(data.stepData)
	elseif action == "TUTORIAL_COMPLETE" then
		print("[TutorialController] 教程完成")
		tutorialState.isActive = false

		hideTutorialUI()
		clearOverlays()

		-- 显示完成通知
		showCompletionNotification(data)
	elseif action == "SHOW_HINT" then
		-- 显示提示信息
		if data.hintText then
			showHintMessage(data.hintText)
		end
	end
end)

-- 显示完成通知
function showCompletionNotification(data)
	local notificationGui = Instance.new("ScreenGui")
	notificationGui.Name = "TutorialComplete"
	notificationGui.ResetOnSpawn = false
	notificationGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	notificationGui.DisplayOrder = 200
	notificationGui.Parent = playerGui

	local notification = Instance.new("Frame")
	notification.Size = UDim2.new(0, 400, 0, 200)
	notification.Position = UDim2.new(0.5, -200, 0.5, -100)
	notification.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	notification.BorderSizePixel = 0
	notification.Parent = notificationGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 15)
	corner.Parent = notification

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 165, 0)),
	})
	gradient.Rotation = 45
	gradient.Parent = notification

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0, 50)
	title.Position = UDim2.new(0, 10, 0, 20)
	title.BackgroundTransparency = 1
	title.Text = "🎉 教程完成！"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = notification

	local timeText = Instance.new("TextLabel")
	timeText.Size = UDim2.new(1, -20, 0, 30)
	timeText.Position = UDim2.new(0, 10, 0, 80)
	timeText.BackgroundTransparency = 1
	timeText.Text = string.format("用时: %d 秒", math.floor(data.totalTime or 0))
	timeText.TextColor3 = Color3.fromRGB(255, 255, 255)
	timeText.TextScaled = true
	timeText.Font = Enum.Font.Gotham
	timeText.Parent = notification

	local continueButton = Instance.new("TextButton")
	continueButton.Size = UDim2.new(0, 120, 0, 40)
	continueButton.Position = UDim2.new(0.5, -60, 1, -60)
	continueButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	continueButton.Text = "开始游戏！"
	continueButton.TextColor3 = Color3.fromRGB(25, 25, 35)
	continueButton.TextScaled = true
	continueButton.Font = Enum.Font.GothamBold
	continueButton.BorderSizePixel = 0
	continueButton.Parent = notification

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = continueButton

	continueButton.MouseButton1Click:Connect(function()
		notificationGui:Destroy()
	end)

	-- 显示动画
	notification.Size = UDim2.new(0, 0, 0, 0)
	notification.Position = UDim2.new(0.5, 0, 0.5, 0)

	local showTween =
		TweenService:Create(notification, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 400, 0, 200),
			Position = UDim2.new(0.5, -200, 0.5, -100),
		})
	showTween:Play()

	-- 自动关闭
	task.spawn(function()
		task.wait(10)
		if notificationGui.Parent then
			notificationGui:Destroy()
		end
	end)
end

-- 显示提示消息
function showHintMessage(hintText)
	-- 简单的提示消息实现
	print("[TutorialController] 提示:", hintText)
end

--------------------------------------------------------------------
-- 初始化
--------------------------------------------------------------------

-- 等待游戏加载完成后检查教程状态
task.spawn(function()
	task.wait(3) -- 等待其他系统加载

	local progress = tutorialFunction:InvokeServer("GET_TUTORIAL_PROGRESS")
	if progress and progress.isActive then
		print("[TutorialController] 恢复教程状态")
		tutorialState.isActive = true
		tutorialState.currentStep = progress.currentStep
		tutorialState.stepData = progress.currentStepData

		if tutorialState.stepData then
			showTutorialUI()
			updateTutorialUI(tutorialState.stepData, progress.currentStep, progress.totalSteps)
			handleStepInteraction(tutorialState.stepData)
		end
	end
end)

print("[TutorialController] 新手教程客户端控制器已加载")

-- 显示欢迎提示
task.spawn(function()
    task.wait(2)
    local welcomeGui = Instance.new("ScreenGui")
    welcomeGui.Name = "WelcomeMessage"
    welcomeGui.ResetOnSpawn = false
    welcomeGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    welcomeGui.DisplayOrder = 50
    welcomeGui.Parent = playerGui

    local welcomeFrame = Instance.new("Frame")
    welcomeFrame.Size = UDim2.new(0, 350, 0, 100)
    welcomeFrame.Position = UDim2.new(0.5, -175, 0, 20)
    welcomeFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    welcomeFrame.BorderSizePixel = 0
    welcomeFrame.Parent = welcomeGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = welcomeFrame

    local border = Instance.new("UIStroke")
    border.Color = Color3.fromRGB(100, 200, 255)
    border.Thickness = 2
    border.Parent = welcomeFrame

    local welcomeText = Instance.new("TextLabel")
    welcomeText.Size = UDim2.new(1, -20, 1, -20)
    welcomeText.Position = UDim2.new(0, 10, 0, 10)
    welcomeText.BackgroundTransparency = 1
    welcomeText.Text = "欢迎来到 RoboFusion Tycoon!\n按 F 键开始教程"
    welcomeText.TextColor3 = Color3.fromRGB(255, 255, 255)
    welcomeText.TextSize = 16
    welcomeText.Font = Enum.Font.GothamBold
    welcomeText.TextWrapped = true
    welcomeText.Parent = welcomeFrame

    -- 淡入动画
    welcomeFrame.BackgroundTransparency = 1
    welcomeText.TextTransparency = 1
    border.Transparency = 1

    local fadeIn = TweenService:Create(welcomeFrame, TweenInfo.new(0.5), {BackgroundTransparency = 0})
    local textFadeIn = TweenService:Create(welcomeText, TweenInfo.new(0.5), {TextTransparency = 0})
    local borderFadeIn = TweenService:Create(border, TweenInfo.new(0.5), {Transparency = 0})

    fadeIn:Play()
    textFadeIn:Play()
    borderFadeIn:Play()

    -- 5秒后自动消失
    task.wait(8)
    if welcomeGui.Parent then
        local fadeOut = TweenService:Create(welcomeGui, TweenInfo.new(0.5), {})
        fadeOut:Play()
        task.wait(0.5)
        welcomeGui:Destroy()
    end
end)
