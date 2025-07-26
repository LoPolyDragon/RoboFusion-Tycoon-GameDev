--------------------------------------------------------------------
-- TutorialService.lua · Tutorial Service Module
-- Functions:
--   1) Tutorial step validation logic
--   2) Integration with existing game systems
--   3) Tutorial progress tracking
--   4) Reward distribution
--------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Get existing game constants
local GameConstants = require(ReplicatedStorage.SharedModules.GameConstants.main)

local TutorialService = {}

-- Tutorial step validation functions
TutorialService.StepValidators = {}

-- Validate cutscene completion
function TutorialService.StepValidators.CUTSCENE(player, stepData, validationData)
	-- Cutscenes are time-based, validation handled by manager
	return true
end

-- Validate UI interaction
function TutorialService.StepValidators.UI_INTERACTION(player, stepData, validationData)
	if not validationData or not validationData.target then
		return false
	end

	return validationData.target == stepData.target
end

-- Validate building placement
function TutorialService.StepValidators.BUILDING_PLACEMENT(player, stepData, validationData)
	if not validationData or not validationData.buildingType then
		return false
	end

	return validationData.buildingType == stepData.target
end

-- Validate resource collection
function TutorialService.StepValidators.RESOURCE_COLLECTION(player, stepData, validationData)
	-- This would integrate with existing player data system
	-- For now, return true as placeholder
	return true
end

-- Validate machine interaction
function TutorialService.StepValidators.MACHINE_INTERACTION(player, stepData, validationData)
	if not validationData or not validationData.machineType then
		return false
	end

	return validationData.machineType == stepData.target
end

-- Validate teleportation
function TutorialService.StepValidators.TELEPORT(player, stepData, validationData)
	if not validationData or not validationData.destination then
		return false
	end

	return validationData.destination == "MINE"
end

-- Validate mining task
function TutorialService.StepValidators.MINING_TASK(player, stepData, validationData)
	if not validationData or not validationData.oreCount then
		return false
	end

	return validationData.oreCount >= (stepData.targetAmount or 8)
end

-- Validate completion
function TutorialService.StepValidators.COMPLETION(player, stepData, validationData)
	return true
end

-- Validate a tutorial step
function TutorialService.validateStep(player, stepData, validationData)
	local validator = TutorialService.StepValidators[stepData.type]

	if not validator then
		warn("[TutorialService] No validator found for step type:", stepData.type)
		return false
	end

	return validator(player, stepData, validationData)
end

-- Give tutorial rewards
function TutorialService.giveRewards(player, rewards)
	if not rewards then
		return
	end

	-- This would integrate with existing resource management system
	-- For now, just log the rewards
	for rewardType, amount in pairs(rewards) do
		print("[TutorialService] Giving reward to", player.Name, ":", rewardType, "x", amount)

		-- Example integration points:
		if rewardType == "Scrap" then
			-- Call existing scrap management system
		elseif rewardType == "Credits" then
			-- Call existing credits management system
		elseif rewardType == "RustyShell" then
			-- Call existing inventory system
		elseif rewardType == "MiningBot" then
			-- Call existing robot management system
		elseif rewardType == "BuilderBot" then
			-- Call existing robot management system
		elseif rewardType == "TierUnlock" then
			-- Call existing tier system
		end
	end
end

-- Check if player meets tutorial requirements
function TutorialService.checkRequirements(player, requirements)
	if not requirements then
		return true
	end

	-- This would integrate with existing player data system
	-- For now, return true as placeholder
	for reqType, reqValue in pairs(requirements) do
		print("[TutorialService] Checking requirement:", reqType, ">=", reqValue)

		-- Example integration points:
		if reqType == "Scrap" then
			-- Check player's scrap amount
		elseif reqType == "SameOreType" then
			-- Check mining progress
		end
	end

	return true
end

-- Get tutorial step by ID
function TutorialService.getStepById(stepId)
	-- This would reference the tutorial steps from TutorialManager
	-- For now, return nil as placeholder
	return nil
end

-- Calculate tutorial completion percentage
function TutorialService.calculateProgress(completedSteps, totalSteps)
	if totalSteps == 0 then
		return 0
	end
	return (completedSteps / totalSteps) * 100
end

-- Generate tutorial statistics
function TutorialService.generateStats(tutorialData)
	local stats = {
		totalTime = 0,
		averageStepTime = 0,
		stepsCompleted = #tutorialData.completedSteps,
		wasSkipped = tutorialData.skipRequested or false,
	}

	if tutorialData.completedSteps and #tutorialData.completedSteps > 0 then
		local totalStepTime = 0
		for _, stepInfo in pairs(tutorialData.completedSteps) do
			totalStepTime = totalStepTime + (stepInfo.duration or 0)
		end

		stats.totalTime = totalStepTime
		stats.averageStepTime = totalStepTime / #tutorialData.completedSteps
	end

	return stats
end

-- Check if tutorial should be offered to player
function TutorialService.shouldOfferTutorial(player)
	-- This would check player's existing progress
	-- For now, assume all new players need tutorial
	return true
end

-- Integration helpers for existing systems
TutorialService.Integration = {}

-- Helper to integrate with building system
function TutorialService.Integration.onBuildingPlaced(player, buildingType, position)
	-- This would be called by existing building system
	-- to notify tutorial system of building placement
	print("[TutorialService] Building placed:", player.Name, buildingType)
end

-- Helper to integrate with resource system
function TutorialService.Integration.onResourceCollected(player, resourceType, amount)
	-- This would be called by existing resource system
	-- to notify tutorial system of resource collection
	print("[TutorialService] Resource collected:", player.Name, resourceType, amount)
end

-- Helper to integrate with machine system
function TutorialService.Integration.onMachineUsed(player, machineType, action)
	-- This would be called by existing machine system
	-- to notify tutorial system of machine usage
	print("[TutorialService] Machine used:", player.Name, machineType, action)
end

-- Helper to integrate with teleport system
function TutorialService.Integration.onPlayerTeleported(player, destination)
	-- This would be called by existing teleport system
	-- to notify tutorial system of teleportation
	print("[TutorialService] Player teleported:", player.Name, destination)
end

-- Helper to integrate with mining system
function TutorialService.Integration.onOreMined(player, oreType, amount)
	-- This would be called by existing mining system
	-- to notify tutorial system of mining progress
	print("[TutorialService] Ore mined:", player.Name, oreType, amount)
end

print("[TutorialService] Tutorial service module loaded")

return TutorialService
