local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Common.Packages.Knit)
local Trove = require(ReplicatedStorage.Common.Packages.Trove)
local Methods = require(ReplicatedStorage.Common.Modules.Methods)

local Player = Players.LocalPlayer
local HumanoidSettings = require(ReplicatedStorage.Common.Settings.HumanoidSettings)

local function getHumanoidSpeedToSet()
	return HumanoidSettings.DefaultSpeed
end

local Settings = {
	FovTweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	SprintKeyCode = Enum.KeyCode.LeftShift,
}

local CharacterMovementController = Knit.CreateController({ Name = "CharacterMovementController" })

function CharacterMovementController:Init()
	self.character = Player.Character or Player.CharacterAdded:Wait()
	self.humanoid = self.character:WaitForChild("Humanoid")
end

function CharacterMovementController:StopCurrentState()
	if
		self.CharacterStateController.CurrentMovementState
		== self.CharacterStateController.CharacterMovementState.Sprint
	then
		self:StopSprint()
	end
end

function CharacterMovementController:StartSprint()
	self.CharacterStateController.CurrentMovementState = self.CharacterStateController.CharacterMovementState.Sprint
	self:StopCurrentState()

	self.sprintTrove = self.trove:Extend()
	self.sprintTrove:Add(function()
		self.CharacterStateController.CurrentMovementState = self.CharacterStateController.CharacterMovementState.Idle
		self.humanoid.WalkSpeed = getHumanoidSpeedToSet()
		Methods.TweenNow(
			workspace.CurrentCamera,
			{ FieldOfView = self.CameraController:GetFovFromMovementState() },
			Settings.FovTweenInfo
		)
	end)

	self.humanoid.WalkSpeed = HumanoidSettings.SprintSpeed
	Methods.TweenNow(
		workspace.CurrentCamera,
		{ FieldOfView = self.CameraController:GetFovFromMovementState() },
		Settings.FovTweenInfo
	)
end

function CharacterMovementController:StopSprint()
	if self.sprintTrove then
		self.sprintTrove:Destroy()
		self.sprintTrove = nil
	end
end

function CharacterMovementController:LaunchController()
	self:Init()
	self.trove = Trove.new()

	ContextActionService:BindAction("Sprint", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			self:StartSprint()
		elseif inputState == Enum.UserInputState.End then
			self:StopSprint()
		end
	end, false, Settings.SprintKeyCode)

	ContextActionService:BindAction("A", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			self.CameraController:TweenFov(85, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
		end
	end, false, Enum.UserInputType.MouseButton1)
end

function CharacterMovementController:StopController()
	if self.trove then
		self.trove:Destroy()
		self.trove = nil
	end
end

function CharacterMovementController:KnitStart() end

function CharacterMovementController:KnitInit()
	self.ClientController = Knit.GetController("ClientController")
	self.CharacterStateController = Knit.GetController("CharacterStateController")
	self.CameraController = Knit.GetController("CameraController")

	self.ClientController.HumanoidSpawned:Connect(function()
		self:LaunchController()
	end)
	self.ClientController.HumanoidDied:Connect(function()
		self:StopController()
	end)
end

return CharacterMovementController
