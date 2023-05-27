local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Trove = require(ReplicatedStorage.Common.Packages.Trove)
local Knit = require(ReplicatedStorage.Common.Packages.Knit)
local Timer = require(ReplicatedStorage.Common.Packages.Timer)

local Camera = workspace.CurrentCamera
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local CharacterAnimationService = Knit.GetService("CharacterAnimationService")

local Settings = {
	LookReplicationCooldown = 1,
}

local CharacterLookFollower = {}

CharacterLookFollower.__index = CharacterLookFollower

function CharacterLookFollower.new()
	local self = setmetatable({
		character = Player.Character or Player.CharacterAdded:Wait(),
	}, CharacterLookFollower)
	return self
end

function CharacterLookFollower:Enable()
	self.trove = Trove.new()
	-- -45; 55

	local waist = self.character:WaitForChild("UpperTorso"):WaitForChild("Waist")
	local lookReplicationTimer = Timer.new(Settings.LookReplicationCooldown)
	lookReplicationTimer.Tick:Connect(function()
		if not self.xRotationToAdd then
			return
		end

		if self.lastReplicatedXRotation and (math.abs(self.lastReplicatedXRotation - self.xRotationToAdd) < 5) then
			return
		end

		CharacterAnimationService:ReplicateCharacterLookFollower(CFrame.Angles(self.xRotationToAdd, 0, 0))
		self.lastReplicatedXRotation = self.xRotationToAddd
	end)

	self.trove:Add(function()
		lookReplicationTimer:Destroy()
	end)

	lookReplicationTimer:Start()

	self.trove:Connect(RunService.RenderStepped, function()
		local cameraX, _, _ = Camera.CFrame:ToOrientation()
		local waistC1 = waist.C1
		local _, waistY, waistZ = waistC1:ToOrientation()
		self.xRotationToAdd = math.clamp(-cameraX, -45, 55)
		waist.C1 = CFrame.new(waistC1.Position) * CFrame.Angles(self.xRotationToAdd, waistY, waistZ)
	end)
end

function CharacterLookFollower:Disable()
	if self.trove then
		self.trove:Destroy()
		self.trove = nil
	end
end

return CharacterLookFollower
