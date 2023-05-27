local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Trove = require(ReplicatedStorage.Common.Packages.Trove)

local Camera = workspace.CurrentCamera
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

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

	self.trove:Connect(RunService.RenderStepped, function()
		local cameraX, _, _ = Camera.CFrame:ToOrientation()
		local waistC1 = waist.C1
		local _, waistY, waistZ = waistC1:ToOrientation()
		waist.C1 = CFrame.new(waistC1.Position) * CFrame.Angles(math.clamp(-cameraX, -45, 55), waistY, waistZ)
	end)
end

function CharacterLookFollower:Disable()
	if self.trove then
		self.trove:Destroy()
		self.trove = nil
	end
end

return CharacterLookFollower
