--------------------------------------------------------------------
-- TutorialOverlay.client.lua · Tutorial Overlay System
-- Functions:
--   1) Create and manage tutorial overlays
--   2) Highlight specific UI elements
--   3) Block non-tutorial interactions
--   4) Provide visual guidance effects
--------------------------------------------------------------------

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Overlay Manager
local TutorialOverlay = {}
TutorialOverlay.activeOverlays = {}
TutorialOverlay.blockedInputs = {}

-- Create full screen mask
function TutorialOverlay.createFullScreenMask()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "TutorialMask"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 90
	screenGui.Parent = playerGui

	-- Semi-transparent background
	local mask = Instance.new("Frame")
	mask.Name = "Mask"
	mask.Size = UDim2.new(1, 0, 1, 0)
	mask.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	mask.BackgroundTransparency = 0.4
	mask.BorderSizePixel = 0
	mask.Parent = screenGui

	return screenGui, mask
end

-- Create highlight for specific UI element
function TutorialOverlay.createHighlight(targetGui, highlightColor)
	if not targetGui then
		return nil
	end

	highlightColor = highlightColor or Color3.fromRGB(255, 215, 0)

	local highlight = Instance.new("Frame")
	highlight.Name = "TutorialHighlight"
	highlight.Size = UDim2.new(1, 8, 1, 8)
	highlight.Position = UDim2.new(0, -4, 0, -4)
	highlight.BackgroundColor3 = highlightColor
	highlight.BackgroundTransparency = 0.6
	highlight.BorderSizePixel = 0
	highlight.ZIndex = targetGui.ZIndex + 1
	highlight.Parent = targetGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = highlight

	-- Pulse animation
	local pulseInfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	local pulseTween = TweenService:Create(highlight, pulseInfo, {
		BackgroundTransparency = 0.2,
	})
	pulseTween:Play()

	table.insert(TutorialOverlay.activeOverlays, highlight)
	return highlight
end

-- Create cutout in mask for specific element
function TutorialOverlay.createCutout(maskFrame, targetGui, padding)
	if not targetGui or not maskFrame then
		return nil
	end

	padding = padding or 10

	-- Create cutout frame
	local cutout = Instance.new("Frame")
	cutout.Name = "Cutout"
	cutout.Size = UDim2.new(0, targetGui.AbsoluteSize.X + padding * 2, 0, targetGui.AbsoluteSize.Y + padding * 2)
	cutout.Position = UDim2.new(0, targetGui.AbsolutePosition.X - padding, 0, targetGui.AbsolutePosition.Y - padding)
	cutout.BackgroundTransparency = 1
	cutout.BorderSizePixel = 0
	cutout.Parent = maskFrame

	-- Create border highlight
	local border = Instance.new("UIStroke")
	border.Color = Color3.fromRGB(255, 215, 0)
	border.Thickness = 3
	border.Transparency = 0.3
	border.Parent = cutout

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = cutout

	-- Animate border
	local borderTween = TweenService:Create(
		border,
		TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Transparency = 0.1 }
	)
	borderTween:Play()

	table.insert(TutorialOverlay.activeOverlays, cutout)
	return cutout
end

-- Create arrow pointing to target
function TutorialOverlay.createArrow(targetPosition, direction, parent)
	direction = direction or "down"
	parent = parent or playerGui

	local arrow = Instance.new("ImageLabel")
	arrow.Name = "TutorialArrow"
	arrow.Size = UDim2.new(0, 40, 0, 40)
	arrow.BackgroundTransparency = 1
	arrow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
	arrow.ImageColor3 = Color3.fromRGB(255, 215, 0)
	arrow.ZIndex = 200

	-- Position based on direction
	local offset = 60
	if direction == "down" then
		arrow.Position = UDim2.new(0, targetPosition.X - 20, 0, targetPosition.Y - offset)
		arrow.Rotation = 180
	elseif direction == "up" then
		arrow.Position = UDim2.new(0, targetPosition.X - 20, 0, targetPosition.Y + offset)
		arrow.Rotation = 0
	elseif direction == "left" then
		arrow.Position = UDim2.new(0, targetPosition.X + offset, 0, targetPosition.Y - 20)
		arrow.Rotation = -90
	elseif direction == "right" then
		arrow.Position = UDim2.new(0, targetPosition.X - offset, 0, targetPosition.Y - 20)
		arrow.Rotation = 90
	end

	arrow.Parent = parent

	-- Bounce animation
	local originalPos = arrow.Position
	local bounceOffset = direction == "down" and UDim2.new(0, 0, 0, -15)
		or direction == "up" and UDim2.new(0, 0, 0, 15)
		or direction == "left" and UDim2.new(0, -15, 0, 0)
		or UDim2.new(0, 15, 0, 0)

	local bounceInfo = TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	local bounceTween = TweenService:Create(arrow, bounceInfo, {
		Position = originalPos + bounceOffset,
	})
	bounceTween:Play()

	table.insert(TutorialOverlay.activeOverlays, arrow)
	return arrow
end

-- Block input to specific UI elements
function TutorialOverlay.blockInput(targetGui)
	if not targetGui then
		return
	end

	local blocker = Instance.new("Frame")
	blocker.Name = "InputBlocker"
	blocker.Size = UDim2.new(1, 0, 1, 0)
	blocker.BackgroundTransparency = 1
	blocker.ZIndex = targetGui.ZIndex + 10
	blocker.Parent = targetGui

	table.insert(TutorialOverlay.blockedInputs, blocker)
	table.insert(TutorialOverlay.activeOverlays, blocker)

	return blocker
end

-- Clear all overlays
function TutorialOverlay.clearAll()
	for _, overlay in pairs(TutorialOverlay.activeOverlays) do
		if overlay and overlay.Parent then
			overlay:Destroy()
		end
	end
	TutorialOverlay.activeOverlays = {}

	for _, blocker in pairs(TutorialOverlay.blockedInputs) do
		if blocker and blocker.Parent then
			blocker:Destroy()
		end
	end
	TutorialOverlay.blockedInputs = {}
end

-- Create text bubble
function TutorialOverlay.createTextBubble(text, position, parent)
	parent = parent or playerGui

	local bubble = Instance.new("Frame")
	bubble.Name = "TextBubble"
	bubble.Size = UDim2.new(0, 250, 0, 80)
	bubble.Position = position or UDim2.new(0.5, -125, 0.3, 0)
	bubble.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	bubble.BorderSizePixel = 0
	bubble.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = bubble

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, -20, 1, -20)
	textLabel.Position = UDim2.new(0, 10, 0, 10)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = text
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.Gotham
	textLabel.TextWrapped = true
	textLabel.Parent = bubble

	-- Fade in animation
	bubble.BackgroundTransparency = 1
	textLabel.TextTransparency = 1

	local fadeIn = TweenService:Create(bubble, TweenInfo.new(0.3), { BackgroundTransparency = 0 })
	local textFadeIn = TweenService:Create(textLabel, TweenInfo.new(0.3), { TextTransparency = 0 })

	fadeIn:Play()
	textFadeIn:Play()

	table.insert(TutorialOverlay.activeOverlays, bubble)
	return bubble
end

-- Highlight specific UI with cutout effect
function TutorialOverlay.highlightWithCutout(targetGui, hintText)
	if not targetGui then
		return
	end

	-- Create mask
	local maskGui, maskFrame = TutorialOverlay.createFullScreenMask()

	-- Create cutout for target
	local cutout = TutorialOverlay.createCutout(maskFrame, targetGui, 15)

	-- Create arrow pointing to target
	local arrow = TutorialOverlay.createArrow(
		Vector2.new(
			targetGui.AbsolutePosition.X + targetGui.AbsoluteSize.X / 2,
			targetGui.AbsolutePosition.Y + targetGui.AbsoluteSize.Y / 2
		),
		"down",
		maskGui
	)

	-- Create hint text if provided
	if hintText then
		local bubble = TutorialOverlay.createTextBubble(
			hintText,
			UDim2.new(0, targetGui.AbsolutePosition.X, 0, targetGui.AbsolutePosition.Y - 100),
			maskGui
		)
	end

	table.insert(TutorialOverlay.activeOverlays, maskGui)

	return maskGui
end

-- Export the overlay system
_G.TutorialOverlay = TutorialOverlay

print("[TutorialOverlay] Tutorial overlay system loaded")

return TutorialOverlay
