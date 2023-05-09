local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Common.Packages.Knit)
local Trove = require(ReplicatedStorage.Common.Packages.Trove)
local Methods = require(ReplicatedStorage.Common.Modules.Methods)

local Camera = workspace.CurrentCamera
local Player = Players.LocalPlayer

local CharacterMovementController = Knit.CreateController({ Name = "CharacterMovementController" })

function CharacterMovementController:Init()
	self.character = Player.Character or self.player.CharacterAdded:Wait()
	self.humanoid = self.character:WaitForChild("Humanoid")
end

function CharacterMovementController:EnableRootPartTilts()
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
		humanoidRootPart.RootJoint.C1 = defaultC1 * CFrame.Angles(tiltX, tiltY, tiltZ)
	end)
end

function CharacterMovementController:LaunchController()
	self:Init()
	self.trove = Trove.new()
	self:EnableRootPartTilts()
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

	self.ClientController.HumanoidSpawned:Connect(function()
		self:LaunchController()
	end)

	self.ClientController.HumanoidDied:Connect(function()
		self:StopController()
	end)
end

return CharacterMovementController
