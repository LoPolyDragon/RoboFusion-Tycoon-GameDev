--------------------------------------------------------------------
-- TutorialCamera.client.lua · Tutorial Camera Control System
-- Functions:
--   1) Manage camera during tutorial sequences
--   2) Smooth camera transitions
--   3) Focus on tutorial targets
--   4) Cinematic camera movements
--------------------------------------------------------------------

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Tutorial Camera Manager
local TutorialCamera = {}
TutorialCamera.isActive = false
TutorialCamera.originalCameraType = nil
TutorialCamera.originalCFrame = nil
TutorialCamera.currentTween = nil

-- Store original camera settings
function TutorialCamera.storeOriginalSettings()
	TutorialCamera.originalCameraType = camera.CameraType
	TutorialCamera.originalCFrame = camera.CFrame
end

-- Restore original camera settings
function TutorialCamera.restoreOriginalSettings()
	if TutorialCamera.currentTween then
		TutorialCamera.currentTween:Cancel()
		TutorialCamera.currentTween = nil
	end

	camera.CameraType = TutorialCamera.originalCameraType or Enum.CameraType.Custom

	if TutorialCamera.originalCFrame then
		camera.CFrame = TutorialCamera.originalCFrame
	end

	TutorialCamera.isActive = false
end

-- Enable tutorial camera mode
function TutorialCamera.enable()
	if TutorialCamera.isActive then
		return
	end

	TutorialCamera.storeOriginalSettings()
	TutorialCamera.isActive = true
	camera.CameraType = Enum.CameraType.Scriptable

	print("[TutorialCamera] Tutorial camera mode enabled")
end

-- Disable tutorial camera mode
function TutorialCamera.disable()
	if not TutorialCamera.isActive then
		return
	end

	TutorialCamera.restoreOriginalSettings()
	print("[TutorialCamera] Tutorial camera mode disabled")
end

-- Smoothly move camera to target position
function TutorialCamera.moveTo(targetCFrame, duration, easingStyle, easingDirection)
	if not TutorialCamera.isActive then
		TutorialCamera.enable()
	end

	duration = duration or 2
	easingStyle = easingStyle or Enum.EasingStyle.Quad
	easingDirection = easingDirection or Enum.EasingDirection.Out

	-- Cancel any existing tween
	if TutorialCamera.currentTween then
		TutorialCamera.currentTween:Cancel()
	end

	-- Create new tween
	TutorialCamera.currentTween =
		TweenService:Create(camera, TweenInfo.new(duration, easingStyle, easingDirection), { CFrame = targetCFrame })

	TutorialCamera.currentTween:Play()

	return TutorialCamera.currentTween
end

-- Focus camera on a specific target
function TutorialCamera.focusOn(target, distance, height, duration)
	if not target then
		return
	end

	distance = distance or 20
	height = height or 10
	duration = duration or 2

	local targetPosition
	if typeof(target) == "Vector3" then
		targetPosition = target
	elseif typeof(target) == "Instance" and target:IsA("BasePart") then
		targetPosition = target.Position
	elseif typeof(target) == "Instance" and target:IsA("Model") and target.PrimaryPart then
		targetPosition = target.PrimaryPart.Position
	else
		warn("[TutorialCamera] Invalid target type for focusOn")
		return
	end

	-- Calculate camera position
	local cameraPosition = targetPosition + Vector3.new(distance, height, distance)
	local targetCFrame = CFrame.lookAt(cameraPosition, targetPosition)

	return TutorialCamera.moveTo(targetCFrame, duration)
end

-- Create a cinematic orbit around target
function TutorialCamera.orbitAround(target, radius, height, duration, rotations)
	if not target or not TutorialCamera.isActive then
		return
	end

	radius = radius or 15
	height = height or 8
	duration = duration or 5
	rotations = rotations or 1

	local targetPosition
	if typeof(target) == "Vector3" then
		targetPosition = target
	elseif typeof(target) == "Instance" and target:IsA("BasePart") then
		targetPosition = target.Position
	else
		warn("[TutorialCamera] Invalid target type for orbitAround")
		return
	end

	-- Create orbit animation
	local startTime = tick()
	local connection

	connection = RunService.Heartbeat:Connect(function()
		if not TutorialCamera.isActive then
			connection:Disconnect()
			return
		end

		local elapsed = tick() - startTime
		local progress = elapsed / duration

		if progress >= 1 then
			connection:Disconnect()
			return
		end

		-- Calculate orbit position
		local angle = progress * math.pi * 2 * rotations
		local x = targetPosition.X + math.cos(angle) * radius
		local z = targetPosition.Z + math.sin(angle) * radius
		local y = targetPosition.Y + height

		local cameraPosition = Vector3.new(x, y, z)
		camera.CFrame = CFrame.lookAt(cameraPosition, targetPosition)
	end)

	return connection
end

-- Shake camera for impact effects
function TutorialCamera.shake(intensity, duration)
	if not TutorialCamera.isActive then
		return
	end

	intensity = intensity or 2
	duration = duration or 1

	local originalCFrame = camera.CFrame
	local startTime = tick()
	local connection

	connection = RunService.Heartbeat:Connect(function()
		local elapsed = tick() - startTime
		local progress = elapsed / duration

		if progress >= 1 then
			camera.CFrame = originalCFrame
			connection:Disconnect()
			return
		end

		-- Calculate shake offset with decreasing intensity
		local currentIntensity = intensity * (1 - progress)
		local shakeOffset = Vector3.new(
			math.random(-currentIntensity, currentIntensity),
			math.random(-currentIntensity, currentIntensity),
			math.random(-currentIntensity, currentIntensity)
		)

		camera.CFrame = originalCFrame + shakeOffset
	end)

	return connection
end

-- Zoom in/out effect
function TutorialCamera.zoom(targetFOV, duration)
	if not TutorialCamera.isActive then
		return
	end

	duration = duration or 1

	local zoomTween = TweenService:Create(
		camera,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ FieldOfView = targetFOV }
	)

	zoomTween:Play()
	return zoomTween
end

-- Create dramatic camera sequence for landing pod
function TutorialCamera.landingPodSequence(podPosition, onComplete)
	if not TutorialCamera.isActive then
		TutorialCamera.enable()
	end

	-- Phase 1: Wide shot of sky
	local skyPosition = podPosition + Vector3.new(50, 100, 50)
	local skyTarget = podPosition + Vector3.new(0, 200, 0)
	local skyShot = CFrame.lookAt(skyPosition, skyTarget)

	local phase1 = TutorialCamera.moveTo(skyShot, 2)

	phase1.Completed:Connect(function()
		-- Phase 2: Follow pod descent
		task.wait(1)

		local followPosition = podPosition + Vector3.new(30, 50, 30)
		local followShot = CFrame.lookAt(followPosition, podPosition + Vector3.new(0, 100, 0))

		local phase2 = TutorialCamera.moveTo(followShot, 3)

		phase2.Completed:Connect(function()
			-- Phase 3: Close-up of landing
			task.wait(1)

			local closePosition = podPosition + Vector3.new(10, 5, 10)
			local closeShot = CFrame.lookAt(closePosition, podPosition)

			local phase3 = TutorialCamera.moveTo(closeShot, 2)

			phase3.Completed:Connect(function()
				-- Shake effect for impact
				TutorialCamera.shake(3, 0.5)

				task.wait(2)

				if onComplete then
					onComplete()
				end
			end)
		end)
	end)
end

-- Create smooth transition between tutorial steps
function TutorialCamera.transitionToStep(stepData, targetElement)
	if not TutorialCamera.isActive then
		return
	end

	if stepData.type == "UI_INTERACTION" and targetElement then
		-- Focus on UI element
		local elementPosition = Vector3.new(targetElement.AbsolutePosition.X, targetElement.AbsolutePosition.Y, 0)
		-- For UI elements, we might want a different approach
		-- This is a placeholder for UI-focused camera work
	elseif stepData.type == "BUILDING_PLACEMENT" then
		-- Focus on building area
		local buildingArea = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if buildingArea then
			TutorialCamera.focusOn(buildingArea.Position, 15, 8, 1.5)
		end
	elseif stepData.type == "MACHINE_INTERACTION" and targetElement then
		-- Focus on machine
		TutorialCamera.focusOn(targetElement, 12, 6, 1.5)
	elseif stepData.type == "TELEPORT" then
		-- Focus on teleport portal
		-- This would need to find the portal in the world
	end
end

-- Handle tutorial camera events
function TutorialCamera.handleTutorialEvent(eventType, data)
	if eventType == "STEP_START" then
		TutorialCamera.transitionToStep(data.stepData, data.targetElement)
	elseif eventType == "LANDING_POD" then
		TutorialCamera.landingPodSequence(data.position, data.onComplete)
	elseif eventType == "TUTORIAL_END" then
		-- Smooth transition back to normal camera
		local restoreTween = TweenService:Create(
			camera,
			TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ CFrame = TutorialCamera.originalCFrame or camera.CFrame }
		)

		restoreTween:Play()
		restoreTween.Completed:Connect(function()
			TutorialCamera.disable()
		end)
	end
end

-- Prevent player input during tutorial camera sequences
local inputConnections = {}

function TutorialCamera.blockPlayerInput()
	-- Block camera movement inputs
	inputConnections.mouseMove = UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement and TutorialCamera.isActive then
			-- Block mouse camera movement
		end
	end)

	inputConnections.touch = UserInputService.TouchMoved:Connect(function(touch, gameProcessed)
		if TutorialCamera.isActive then
			-- Block touch camera movement
		end
	end)
end

function TutorialCamera.unblockPlayerInput()
	for _, connection in pairs(inputConnections) do
		if connection then
			connection:Disconnect()
		end
	end
	inputConnections = {}
end

-- Auto-cleanup when tutorial camera is disabled
local originalDisable = TutorialCamera.disable
TutorialCamera.disable = function()
	TutorialCamera.unblockPlayerInput()
	originalDisable()
end

-- Export the camera system
_G.TutorialCamera = TutorialCamera

print("[TutorialCamera] Tutorial camera system loaded")

return TutorialCamera
