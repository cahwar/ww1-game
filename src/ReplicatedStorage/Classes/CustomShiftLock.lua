local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Trove = require(ReplicatedStorage.Common.Packages.Trove)
local Methods = require(ReplicatedStorage.Common.Modules.Methods)

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Settings = {
	CameraOffsetTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	CameraOffset = Vector3.new(0, 0.2, 0),

	RotationUpdateSensitivity = 0.75,
}

local CustomShiftLock = {}
CustomShiftLock.__index = CustomShiftLock

function CustomShiftLock.new()
	local self = setmetatable({
		enabled = false,
	}, CustomShiftLock)

	self.character = Player.Character or Player.CharacterAdded:Wait()
	self.humanoid = self.character:WaitForChild("Humanoid")

	return self
end

function CustomShiftLock:_ChangeHumanoidCameraOffset(cameraOffset: Vector3)
	if self.cameraOffsetTween then
		self.cameraOffsetTween:Pause()
	end

	local tweenTable =
		Methods.CreateTween(self.humanoid, { CameraOffset = cameraOffset }, Settings.CameraOffsetTweenInfo)
	tweenTable.Promise:andThen(function()
		self.cameraOffsetTween = nil
	end)
	tweenTable.Tween:Play()
end

function CustomShiftLock:Toggle()
	if self.enabled then
		self:Disable()
	else
		self:Enable()
	end
end

function CustomShiftLock:Enable()
	if self.enabled then
		warn("Shift lock is already enabled")
		return
	end

	self.trove = Trove.new()
	self.enabled = true

	local currentCameeraOffset = self.humanoid.CameraOffset
	self.trove:Add(function()
		self:_ChangeHumanoidCameraOffset(currentCameeraOffset)
		self.enabled = false
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end)

	self:_ChangeHumanoidCameraOffset(Settings.CameraOffset)

	self.trove:Connect(RunService.RenderStepped, function()
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	end)

	self.trove:Connect(RunService.RenderStepped, function()
		local _, y, _ = Camera.CFrame:ToOrientation()

		local currentCFrame = self.character.HumanoidRootPart.CFrame
		local x, _, z = currentCFrame:ToOrientation()

		local orientationToSet = CFrame.Angles(x, y, z)
		if self.orientation then
			orientationToSet = self.orientation:Lerp(orientationToSet, Settings.RotationUpdateSensitivity)
		end

		self.character.HumanoidRootPart.CFrame = CFrame.new(currentCFrame.Position) * orientationToSet
	end)
end

function CustomShiftLock:Disable()
	if self.trove then
		self.trove:Destroy()
		self.trove = nil
	end
end

return CustomShiftLock
