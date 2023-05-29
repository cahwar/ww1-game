local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Common.Packages.Knit)
local Signal = require(ReplicatedStorage.Common.Packages.Signal)
local Trove = require(ReplicatedStorage.Common.Packages.Trove)

local StatesSettings = require(ReplicatedStorage.Common.Settings.StatesSettings)
local ConflictingCharacterStates = require(ReplicatedStorage.Common.Settings.ConflictingCharacterStates)

local Player = Players.LocalPlayer

local CharacterStateController = Knit.CreateController({
	Name = "CharacterStateController",
	Signals = {
		MovementStateChanged = Signal.new(),
		MainStateChanged = Signal.new(),
		TemporaryStateChanged = Signal.new(),
	},

	MainState = nil,
	TemporaryState = nil,
	MovementState = nil,
})

function CharacterStateController:Init()
	self.character = Player.Character or Player.CharacterAdded:Wait()
	self.humanoid = self.character:WaitForChild("Humanoid")
end

function CharacterStateController:CanChangeState(stateToSet: string)
	if
		(
			ConflictingCharacterStates[self.MainState]
			and table.find(ConflictingCharacterStates[self.MainState], stateToSet)
		)
		or (
			self.TemporaryState
			and ConflictingCharacterStates[self.TemporaryState]
			and table.find(ConflictingCharacterStates[self.TemporaryState], stateToSet)
		)
	then
		return false
	end

	return true
end

function CharacterStateController:SetMainStateIfPossible(stateName: string)
	if self:CanChangeState(stateName) then
		self:SetMainState(stateName)
		return true
	end

	return false
end

function CharacterStateController:SetTemporaryStateIfPossible(stateName: string)
	if self:CanChangeState(stateName) then
		self:SetTemporaryState(stateName)
		return true
	end

	return false
end

function CharacterStateController:SetMainState(stateName: string)
	self.MainState = stateName
	self.Signals.MainStateChanged:Fire(stateName, StatesSettings[stateName])
end

function CharacterStateController:SetTemporaryState(stateName: string)
	self.TemporaryState = stateName
	self.Signals.TemporaryStateChanged:Fire(stateName, StatesSettings[stateName])
end

function CharacterStateController:RemoveTemporaryState()
	self.TemporaryState = nil
	self.Signals.TemporaryStateChanged:Fire(nil)
end

function CharacterStateController:LaunchController()
	self:Init()

	self.trove = Trove.new()

	self.trove:Add(function()
		self:RemoveTemporaryState()
	end)

	self.trove:Connect(RunService.Heartbeat, function()
		local movementState = self.humanoid.MoveDirection.Magnitude >= 0.1 and "Move" or "Idle"
		if self.MovementState ~= movementState then
			self.MovementState = movementState
			self.Signals.MovementStateChanged:Fire(movementState)
		end
	end)

	self:SetMainState("Default")
	self:RemoveTemporaryState()
end

function CharacterStateController:StopController()
	if self.trove then
		self.trove:Destroy()
		self.trove = nil
	end
end

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
