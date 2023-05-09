local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Knit = require(ReplicatedStorage.Common.Packages.Knit)
local Signal = require(ReplicatedStorage.Common.Packages.Signal)
local CustomShiftLock = require(ReplicatedStorage.Common.Classes.CustomShiftLock)

local ClientController = Knit.CreateController({
	Name = "ClientController",
	HumanoidSpawned = Signal.new(),
	HumanoidDied = Signal.new(),
})

function ClientController:Init()
	self.player = game:GetService("Players").LocalPlayer
	self.character = self.player.Character or self.player.CharacterAdded:Wait()
	self.humanoid = self.character:WaitForChild("Humanoid")
end

function ClientController:SetupController()
	self:Init()
	self.HumanoidSpawned:Fire()
	self.humanoid.Died:Connect(function()
		self.HumanoidDied:Fire()
		self.player.CharacterAdded:Wait()
		self:SetupController()
	end)
end

function ClientController:LaunchController()
	print("Humanoid spawned")

	self.shiftLock = CustomShiftLock.new()

	ContextActionService:BindAction("Shiftlock", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			self.shiftLock:Toggle()
		end
	end, false, Enum.KeyCode.LeftControl)
end

function ClientController:StopController()
	print("Humanoid died")
end

function ClientController:KnitStart()
	self:SetupController()
end

function ClientController:KnitInit()
	self.HumanoidSpawned:Connect(function()
		self:LaunchController()
	end)

	self.HumanoidDied:Connect(function()
		self:StopController()
	end)
end

return ClientController
