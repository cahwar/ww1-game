local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Common.Packages.Knit)
local EnumList = require(ReplicatedStorage.Common.Packages.EnumList)
local Trove = require(ReplicatedStorage.Common.Packages.Trove)
local Signal = require(ReplicatedStorage.Common.Packages.Signal)

local Player = Players.LocalPlayer

local CharacterMovementState = EnumList.new("CharacterMovementState", {
	"Idle",
	"Sprint",
	"Crouch",
})

local CharacterStateController = Knit.CreateController({
	Name = "CharacterStateController",
	CharacterMovementState = CharacterMovementState,

	Signals = {
		MovementStateChanged = Signal.new(),
	},
})

function CharacterStateController:Init()
	self.character = Player.Character or Player.CharacterAdded:Wait()
	self.humanoid = self.character:WaitForChild("Humanoid")
end

function CharacterStateController:ChangeState(stateToSet: typeof(CharacterMovementState))
	if self.CurrentMovementState == stateToSet then
		return
	end

	self.CurrentMovementState = stateToSet
	self.Signals.MovementStateChanged:Fire(self.CurrentMovementState)
end

function CharacterStateController:LaunchController()
	self.trove = Trove.new()
	self:ChangeState(CharacterMovementState.Idle)
end

function CharacterStateController:StopController()
	if self.trove then
		self.trove:Destroy()
		self.trove = nil
	end
end

function CharacterStateController:KnitStart() end

function CharacterStateController:KnitInit()
	self.ClientController = Knit.GetController("ClientController")

	self.ClientController.HumanoidSpawned:Connect(function()
		self:LaunchController()
	end)
	self.ClientController.HumanoidDied:Connect(function()
		self:StopController()
	end)
end

return CharacterStateController
