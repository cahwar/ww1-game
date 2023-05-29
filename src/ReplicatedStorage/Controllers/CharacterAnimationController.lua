local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Common.Packages.Knit)
local Trove = require(ReplicatedStorage.Common.Packages.Trove)
local Methods = require(ReplicatedStorage.Common.Modules.Methods)
local Animations = require(ReplicatedStorage.Common.Modules.Animations)

local StatesSettings = require(ReplicatedStorage.Common.Settings.StatesSettings)

local Player = Players.LocalPlayer

local CharacterAnimationController = Knit.CreateController({ Name = "CharacterAnimationController" })

function CharacterAnimationController:Init()
	self.character = Player.Character or self.player.CharacterAdded:Wait()
	self.humanoid = self.character:WaitForChild("Humanoid")
end

function CharacterAnimationController:EnableRootPartTiltsR6()
	self.rootPartTiltsTrove = self.trove:Extend()

	local humanoidRootPart = self.humanoid.RootPart
	local rootJoint: Motor6D = humanoidRootPart:WaitForChild("RootJoint")
	local defaultC1 = rootJoint.C1

	local tiltX, tiltY, tiltZ = 0, 0, 0

	self.rootPartTilt = CFrame.Angles(0, 0, 0)

	self.rootPartTiltsTrove:Connect(RunService.RenderStepped, function()
		local movementVector = humanoidRootPart.CFrame:VectorToObjectSpace(
			humanoidRootPart.AssemblyLinearVelocity / math.max(self.humanoid.WalkSpeed, 0.01)
		)
		tiltX = math.clamp(Methods.LerpValue(tiltX, movementVector.Z, 0.05), -0.1, 0.1)
		tiltY = math.clamp(Methods.LerpValue(tiltY, movementVector.X, 0.05), -0.1, 0.1)
		tiltZ = math.clamp(Methods.LerpValue(tiltZ, movementVector.X, 0.05), -0.25, 0.25)
		humanoidRootPart.RootJoint.C1 = defaultC1 * CFrame.Angles(tiltX, tiltY, 0)
	end)
end

function CharacterAnimationController:EnableRootPartTiltsR15()
	self.rootPartTiltsTrove = self.trove:Extend()

	local humanoidRootPart = self.humanoid.RootPart
	local waist: Motor6D = self.character:WaitForChild("UpperTorso"):WaitForChild("Waist")
	local defaultC1 = waist.C1

	local tiltX, tiltY, tiltZ = 0, 0, 0

	self.rootPartTilt = CFrame.Angles(0, 0, 0)

	-- For movement vector:
	-- L/R - X
	-- F/B - Z

	self.rootPartTiltsTrove:Connect(RunService.RenderStepped, function()
		local movementVector = humanoidRootPart.CFrame:VectorToObjectSpace(
			humanoidRootPart.AssemblyLinearVelocity / math.max(self.humanoid.WalkSpeed, 0.01)
		)

		tiltZ = math.clamp(Methods.LerpValue(tiltZ, movementVector.X, 0.05), -math.rad(10), math.rad(10)) -- Left/Right
		-- tiltX = math.clamp(Methods.LerpValue(tiltX, movementVector.Z, 0.05), -0.1, 0.1) -- Forward/Back
		waist.C1 = defaultC1 * CFrame.Angles(tiltX, tiltY, tiltZ)
	end)
end

function CharacterAnimationController:OnCharacterStateChanged()
	local mainState = self.CharacterStateController.MainState
	local movementState = self.CharacterStateController.MovementState

	local animationToPlaySettings = StatesSettings[mainState] and StatesSettings[mainState].Animations[movementState]
		or StatesSettings.Default.Animations.Idle

	if self.animationPlaying then
		Animations:StopAnimation(self.character, self.animationPlaying.Name, 0.1)
	end

	self.animationPlaying = animationToPlaySettings
	Animations:PlayAnimation(self.character, animationToPlaySettings.Name, 0.1, animationToPlaySettings.Speed)
end

function CharacterAnimationController:LaunchController()
	self:Init()
	self.trove = Trove.new()

	if self.ClientController.CharacterType == "R15" then
		self:EnableRootPartTiltsR15()
	elseif self.ClientController.CharacterType == "R6" then
		self:EnableRootPartTiltsR6()
	end

	self.character:WaitForChild("Animate"):Destroy()
	for _, v in self.humanoid:GetPlayingAnimationTracks() do
		v:Stop()
	end

	for _, v in ReplicatedStorage.Common.GameParts.Animations.Movement:GetChildren() do
		Animations:LoadAnimation(self.character, v)
	end

	self:OnCharacterStateChanged()

	self.trove:Connect(self.CharacterStateController.Signals.MovementStateChanged, function()
		self:OnCharacterStateChanged()
	end)

	self.trove:Connect(self.CharacterStateController.Signals.MainStateChanged, function()
		self:OnCharacterStateChanged()
	end)
end

function CharacterAnimationController:StopController()
	if self.trove then
		self.trove:Destroy()
		self.trove = nil
	end
end

function CharacterAnimationController:SetLookFollower(character: Model, waistCFrame: CFrame)
	Methods.TweenNow(
		character:FindFirstChild("Waist", true),
		{ C1 = waistCFrame },
		TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	)
end

function CharacterAnimationController:KnitStart()
	self.CharacterAnimationService.ReplicateLookFollower:Connect(function(character: Model, waistCFrame: CFrame)
		self:SetLookFollower(character, waistCFrame)
	end)
end

function CharacterAnimationController:KnitInit()
	self.ClientController = Knit.GetController("ClientController")
	self.CharacterAnimationService = Knit.GetService("CharacterAnimationService")
	self.CharacterStateController = Knit.GetController("CharacterStateController")

	self.ClientController.HumanoidSpawned:Connect(function()
		self:LaunchController()
	end)

	self.ClientController.HumanoidDied:Connect(function()
		self:StopController()
	end)
end

return CharacterAnimationController
