--------------------------------------------------------------------
-- LandingPodSequenceModule.lua · Landing Pod Cutscene System Module
-- Functions:
--   1) Handle landing pod arrival cutscene
--   2) Camera control during sequence
--   3) Visual and audio effects
--   4) Smooth transition to tutorial
--------------------------------------------------------------------

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Landing Pod Sequence Manager
local LandingPodSequence = {}

-- Create landing pod model
local function createLandingPod()
    local pod = Instance.new("Model")
    pod.Name = "LandingPod"
    pod.Parent = Workspace
    
    -- Main pod body
    local body = Instance.new("Part")
    body.Name = "Body"
    body.Size = Vector3.new(4, 6, 4)
    body.Material = Enum.Material.Metal
    body.BrickColor = BrickColor.new("Dark stone grey")
    body.Shape = Enum.PartType.Cylinder
    body.TopSurface = Enum.SurfaceType.Smooth
    body.BottomSurface = Enum.SurfaceType.Smooth
    body.CanCollide = true
    body.Parent = pod
    
    -- Add some details
    local window = Instance.new("Part")
    window.Name = "Window"
    window.Size = Vector3.new(0.2, 2, 2)
    window.Material = Enum.Material.Glass
    window.BrickColor = BrickColor.new("Bright blue")
    window.Transparency = 0.3
    window.CanCollide = false
    window.Parent = pod
    
    local windowWeld = Instance.new("WeldConstraint")
    windowWeld.Part0 = body
    windowWeld.Part1 = window
    windowWeld.Parent = body
    
    window.CFrame = body.CFrame * CFrame.new(2.1, 0, 0)
    
    -- Thruster effects
    local thruster1 = Instance.new("Part")
    thruster1.Name = "Thruster1"
    thruster1.Size = Vector3.new(1, 1, 1)
    thruster1.Material = Enum.Material.Neon
    thruster1.BrickColor = BrickColor.new("Bright orange")
    thruster1.Shape = Enum.PartType.Cylinder
    thruster1.CanCollide = false
    thruster1.Parent = pod
    
    local thruster1Weld = Instance.new("WeldConstraint")
    thruster1Weld.Part0 = body
    thruster1Weld.Part1 = thruster1
    thruster1Weld.Parent = body
    
    thruster1.CFrame = body.CFrame * CFrame.new(0, -3.5, 0)
    
    -- Add primary part
    pod.PrimaryPart = body
    
    return pod
end

-- Create particle effects
local function createParticleEffects(pod)
    local body = pod:FindFirstChild("Body")
    if not body then return end
    
    -- Smoke effect
    local smoke = Instance.new("Smoke")
    smoke.Size = 10
    smoke.Opacity = 0.8
    smoke.RiseVelocity = 5
    smoke.Color = Color3.fromRGB(100, 100, 100)
    smoke.Parent = body
    
    -- Fire effect for thrusters
    local thruster = pod:FindFirstChild("Thruster1")
    if thruster then
        local fire = Instance.new("Fire")
        fire.Size = 8
        fire.Heat = 15
        fire.Color = Color3.fromRGB(255, 140, 0)
        fire.SecondaryColor = Color3.fromRGB(255, 69, 0)
        fire.Parent = thruster
        
        -- Remove fire after landing
        Debris:AddItem(fire, 8)
    end
    
    -- Remove smoke after some time
    Debris:AddItem(smoke, 12)
end

-- Create impact effects
local function createImpactEffects(position)
    -- Dust cloud
    local dustPart = Instance.new("Part")
    dustPart.Name = "DustCloud"
    dustPart.Size = Vector3.new(1, 1, 1)
    dustPart.Transparency = 1
    dustPart.CanCollide = false
    dustPart.Anchored = true
    dustPart.Position = position
    dustPart.Parent = Workspace
    
    local smoke = Instance.new("Smoke")
    smoke.Size = 15
    smoke.Opacity = 0.6
    smoke.RiseVelocity = 3
    smoke.Color = Color3.fromRGB(139, 69, 19)
    smoke.Parent = dustPart
    
    -- Remove dust cloud after some time
    Debris:AddItem(dustPart, 10)
end

-- Play landing sequence
function LandingPodSequence.playSequence()
    print("[LandingPodSequence] 开始播放降落舱序列")
    
    local player = Players.LocalPlayer
    local camera = Workspace.CurrentCamera
    
    -- Save original camera settings
    local originalCameraType = camera.CameraType
    local originalCFrame = camera.CFrame
    
    -- Set camera to scriptable for cutscene
    camera.CameraType = Enum.CameraType.Scriptable
    
    -- Create landing pod
    local landingPod = createLandingPod()
    
    -- Position pod high in the sky
    local landingSpot = Vector3.new(0, 200, 0)
    landingPod:SetPrimaryPartCFrame(CFrame.new(landingSpot))
    
    -- Position camera to watch the landing
    local cameraPosition = landingSpot + Vector3.new(20, -50, 20)
    camera.CFrame = CFrame.lookAt(cameraPosition, landingSpot)
    
    -- Create particle effects
    createParticleEffects(landingPod)
    
    -- Animate landing
    local landingTarget = Vector3.new(0, 5, 0)
    local landingTween = TweenService:Create(
        landingPod.PrimaryPart,
        TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { CFrame = CFrame.new(landingTarget) }
    )
    
    -- Camera follows the pod
    local cameraFollow = TweenService:Create(
        camera,
        TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { CFrame = CFrame.lookAt(landingTarget + Vector3.new(15, 10, 15), landingTarget) }
    )
    
    landingTween:Play()
    cameraFollow:Play()
    
    -- Create impact effects when landing
    landingTween.Completed:Connect(function()
        createImpactEffects(landingTarget)
        
        -- Camera shake effect
        for i = 1, 10 do
            local offset = Vector3.new(
                math.random(-2, 2),
                math.random(-1, 1), 
                math.random(-2, 2)
            )
            camera.CFrame = camera.CFrame + offset
            task.wait(0.05)
        end
        
        -- Wait a moment, then restore camera
        task.wait(2)
        
        -- Restore original camera
        camera.CameraType = originalCameraType
        camera.CFrame = originalCFrame
        
        -- Clean up landing pod after sequence
        task.wait(3)
        if landingPod and landingPod.Parent then
            landingPod:Destroy()
        end
        
        -- Notify tutorial system that cutscene is complete
        local tutorialEvent = ReplicatedStorage.RemoteEvents:FindFirstChild("TutorialEvent")
        if tutorialEvent then
            tutorialEvent:FireServer("STEP_COMPLETED", "LANDING_POD", {})
            print("[LandingPodSequence] 降落舱序列完成，通知教程系统")
        end
    end)
end

return LandingPodSequence