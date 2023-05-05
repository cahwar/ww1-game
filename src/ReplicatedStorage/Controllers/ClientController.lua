local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Common.Packages.Knit)
local Signal = require(ReplicatedStorage.Common.Packages.Signal)

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
