local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Common.Packages.Knit)
local Trove = require(ReplicatedStorage.Common.Packages.Trove)

local HumanoidSettings = require(ReplicatedStorage.Common.Settings.HumanoidSettings)

local Player = Players.LocalPlayer

local CharacterMovementController = Knit.CreateController({ Name = "CharacterMovementController" })

function CharacterMovementController:Init()
	self.character = Player.Character or Player.CharacterAdded:Wait()
	self.humanoid = self.character:WaitForChild("Humanoid")
end

function CharacterMovementController:LaunchController()
	self:Init()

	self.trove = Trove.new()
	self.trove:Connect(self.CharacterStateController.Signals.MainStateChanged, function(stateName, stateSettings)
		self.CurrentMainStateSettings = stateSettings
		if self.CharacterStateController.TemporaryState == nil then
			self.humanoid.WalkSpeed = stateSettings and stateSettings.Speed or HumanoidSettings.IdleSpeed
		else
			local speedMultipler = self.TemporaryStateSettings and self.TemporaryStateSettings.SpeedMultipler or 1
			self.humanoid.WalkSpeed = (stateSettings and stateSettings.Speed or HumanoidSettings.IdleSpeed)
				* speedMultipler
		end
	end)

	self.trove:Connect(self.CharacterStateController.Signals.TemporaryStateChanged, function(stateName, stateSettings)
		if stateName == nil then
			self.humanoid.WalkSpeed = self.CurrentMainStateSettings and self.CurrentMainStateSettings.Speed
				or HumanoidSettings.IdleSpeed
			self.TemporaryStateSettings = nil
			return
		end

		if stateSettings and stateSettings.SpeedMultipler then
			self.TemporaryStateSettings = stateSettings

			self.humanoid.WalkSpeed = (
				self.CurrentMainStateSettings and self.CurrentMainStateSettings.Speed or HumanoidSettings.IdleSpeed
			) * stateSettings.SpeedMultipler
		end
	end)

	ContextActionService:BindAction("Sprint", function(_, inputState: Enum.UserInputState)
		if inputState == Enum.UserInputState.Begin then
			self.CharacterStateController:SetMainStateIfPossible("Sprint")
		elseif inputState == Enum.UserInputState.End and self.CharacterStateController.MainState == "Sprint" then
			self.CharacterStateController:SetMainState("Default")
		end

		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.LeftShift)

	ContextActionService:BindAction("HoldCrawl", function(_, inputState: Enum.UserInputState)
		if inputState == Enum.UserInputState.Begin then
			self.CharacterStateController:SetMainStateIfPossible("Crawl")
		elseif inputState == Enum.UserInputState.End and self.CharacterStateController.MainState == "Crawl" then
			self.CharacterStateController:SetMainState("Default")
		end

		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.LeftControl)

	ContextActionService:BindAction("ToggleCrawl", function(_, inputState: Enum.UserInputState)
		if inputState == Enum.UserInputState.Begin then
			if self.CharacterStateController.MainState == "Crawl" then
				self.CharacterStateController:SetMainStateIfPossible("Default")
			else
				self.CharacterStateController:SetMainStateIfPossible("Crawl")
			end
		end

		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.C)
end

function CharacterMovementController:StopController()
	if self.trove then
		self.trove:Destroy()
		self.trove = nil
	end
end

function CharacterMovementController:KnitInit()
	self.ClientController = Knit.GetController("ClientController")
	self.CharacterStateController = Knit.GetController("CharacterStateController")

	self.ClientController.HumanoidSpawned:Connect(function()
		self:LaunchController()
	end)

	self.ClientController.HumanoidDied:Connect(function()
		self:StopController()
	end)
end

return CharacterMovementController
