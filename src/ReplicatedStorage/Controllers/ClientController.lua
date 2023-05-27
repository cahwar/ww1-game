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
	self:DefineCharacterType()
	self.HumanoidSpawned:Fire()
	self.humanoid.Died:Connect(function()
		self.HumanoidDied:Fire()
		self.player.CharacterAdded:Wait()
		self:SetupController()
	end)
end

-- // Is character that we're playing R15 or R6
function ClientController:DefineCharacterType()
	if self.character:WaitForChild("UpperTorso", 3) then
		self.CharacterType = "R15"
	else
		self.CharacterType = "R6"
	end
end

function ClientController:LaunchController()
	print("Humanoid spawned")

	require(ReplicatedStorage.Common.Classes.CharacterLookFollower).new():Enable()

	ContextActionService:BindAction("Shiftlock", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			self.RobloxCameraController:ToggleMouseLock()
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
	self.RobloxCameraController = Knit.GetController("RobloxCameraController")

	self.HumanoidSpawned:Connect(function()
		self:LaunchController()
	end)

	self.HumanoidDied:Connect(function()
		self:StopController()
	end)
end

return ClientController
