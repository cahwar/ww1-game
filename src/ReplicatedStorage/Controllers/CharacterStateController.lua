local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Common.Packages.Knit)
local EnumList = require(ReplicatedStorage.Common.Packages.EnumList)
local Trove = require(ReplicatedStorage.Common.Packages.Trove)
local Signal = require(ReplicatedStorage.Common.Packages.Signal)

local ConflictingCharacterStates = require(ReplicatedStorage.Common.Settings.ConflictingCharacterStates)

local Player = Players.LocalPlayer

local CharacterMovementState = EnumList.new("CharacterMovementState", {
	"Idle",
	"Sprint",
	"Crawl",
	"Dead",
})

local CharacterActionState = EnumList.new("CharacterActionState", {
	"Aim",
	"Healing", -- Placeholder
	"Vaulting", -- Placeholder
})

local CharacterStateController = Knit.CreateController({
	Name = "CharacterStateController",

	CharacterMovementState = CharacterMovementState,
	CharacterActionState = CharacterActionState,

	Signals = {
		MovementStateChanged = Signal.new(),
		ActionStateChanged = Signal.new(),
	},
})

function CharacterStateController:Init()
	self.character = Player.Character or Player.CharacterAdded:Wait()
	self.humanoid = self.character:WaitForChild("Humanoid")
end

function CharacterStateController:CanChangeState(newStateName: string)
	return table.find(ConflictingCharacterStates[newStateName], self.CurrentMovementState.Name) == nil
		and (
			self.CurrentActionState == nil
			or table.find(ConflictingCharacterStates[newStateName], self.CurrentActionState.Name) == nil
		)
end

function CharacterStateController:TryChangeState(stateToSet: typeof(CharacterMovementState)): boolean
	if not self:CanChangeState(stateToSet.Name) then
		return false
	end

	self:ChangeState(stateToSet)

	return true
end

function CharacterStateController:ChangeState(stateToSet: typeof(CharacterMovementState))
	if self.CurrentMovementState == stateToSet then
		return
	end

	self.CurrentMovementState = stateToSet
	self.Signals.MovementStateChanged:Fire(self.CurrentMovementState)
end

function CharacterStateController:TryChangeActionState(stateToSet: typeof(CharacterActionState)): boolean
	if not self:CanChangeState(stateToSet.Name) then
		return false
	end

	self:ChangeActionState(stateToSet)

	return true
end

function CharacterStateController:ChangeActionState(stateToSet: typeof(CharacterActionState) | nil)
	if self.CurrentActionState == stateToSet then
		return
	end

	self.CurrentActionState = stateToSet
	self.Signals.ActionStateChanged:Fire(self.CurrentActionState)
end

function CharacterStateController:LaunchController()
	self.trove = Trove.new()
	self:ChangeState(CharacterMovementState.Idle)
	self:ChangeActionState(nil)

	self.trove:Add(function()
		self:ChangeState(CharacterMovementState.Dead)
		self:ChangeActionState(nil)
	end)
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
