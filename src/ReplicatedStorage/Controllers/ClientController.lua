local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Common.Packages.Knit)
local Signal = require(ReplicatedStorage.Common.Packages.Signal)
local Trove = require(ReplicatedStorage.Common.Packages.Trove)

local CameraSettings = require(ReplicatedStorage.Common.Settings.CameraSettings)

local CharacterLookFollower = require(ReplicatedStorage.Common.Classes.CharacterLookFollower)

local ClientController = Knit.CreateController({
	Name = "ClientController",
	HumanoidSpawned = Signal.new(),
	HumanoidDied = Signal.new(),
})

function ClientController:Init()
	self.player = game:GetService("Players").LocalPlayer
	self.mouse = self.player:GetMouse()
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

function ClientController:SetMouseCursor(cursorName: string)
	self.mouse.Icon = CameraSettings.Cursors[cursorName] or CameraSettings.Cursors.Default
end

function ClientController:LaunchController()
	self.trove = Trove.new()
	self.CharacterLookFollower = CharacterLookFollower.new()
	self.CharacterLookFollower:Enable()
	self.trove:Add(function()
		self.CharacterLookFollower:Disable()
	end)
end

function ClientController:StopController()
	print("Humanoid died")
end

function ClientController:KnitStart()
	self:SetupController()
	self:SetMouseCursor("Default")
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
