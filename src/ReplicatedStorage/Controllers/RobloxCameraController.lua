local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Knit = require(ReplicatedStorage.Common.Packages.Knit)
local Trove = require(ReplicatedStorage.Common.Packages.Trove)
local Methods = require(ReplicatedStorage.Common.Modules.Methods)

local RobloxCameraController = Knit.CreateController({ Name = "RobloxCameraController" })

export type EasingInfo = { Duration: number, EasingStyle: Enum.EasingStyle, EasingDirection: Enum.EasingDirection }

local Settings = {
	DefaultLockedCameraOffset = Vector3.new(0, 0.5, 0),
}

function RobloxCameraController:Init()
	self.player = Players.LocalPlayer

	self.playerModule = self.player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")
	self.cameraModule = self.playerModule:WaitForChild("CameraModule")
	self.mouseLockController = self.cameraModule:WaitForChild("MouseLockController")

	self.requiredPlayerModule = require(self.playerModule)
	self.requiredCameraModule = require(self.cameraModule)
end

function RobloxCameraController:MouseLockControllerExists()
	if not self.requiredCameraModule.activeMouseLockController then
		warn("No active mouse lock controller")
		return false
	end

	return self.requiredCameraModule.activeMouseLockController
end

function RobloxCameraController:ToggleMouseLock()
	if not self:MouseLockControllerExists() then
		return
	end

	if self.requiredCameraModule.activeMouseLockController.isMouseLocked then
		self:DisableMouseLock()
	else
		self:EnableMouseLock()
	end
end

function RobloxCameraController:EnableMouseLock(cameraOffset: Vector3?, easingInfo: EasingInfo?)
	if not self:MouseLockControllerExists() then
		return
	end

	self.requiredCameraModule.activeMouseLockController.isMouseLocked = true
	self.requiredCameraModule.activeMouseLockController.mouseLockToggledEvent:Fire()

	self:SetMouseLockCameraOffset(
		cameraOffset or Settings.DefaultLockedCameraOffset,
		easingInfo and easingInfo.Duration,
		easingInfo and easingInfo.EasingStyle,
		easingInfo and easingInfo.EasingDirection
	).Promise
		:await()
end

function RobloxCameraController:DisableMouseLock(easingInfo: EasingInfo?)
	if not self:MouseLockControllerExists() then
		return
	end

	self:SetMouseLockCameraOffset(
		Vector3.new(0, 0, 0),
		easingInfo and easingInfo.Duration,
		easingInfo and easingInfo.EasingStyle,
		easingInfo and easingInfo.EasingDirection
	).Promise
		:await()

	self.requiredCameraModule.activeMouseLockController.isMouseLocked = false
	self.requiredCameraModule.activeMouseLockController.mouseLockToggledEvent:Fire()
end

function RobloxCameraController:SetMouseLockCameraOffset(
	cameraOffset: Vector3,
	changeDuration: number?,
	easingStyle: Enum.EasingStyle?,
	easingDirection: Enum.EasingDirection?
)
	if not self:MouseLockControllerExists() then
		return
	end

	if self.requiredCameraModule.activeMouseLockController:GetIsMouseLocked() == false then
		local offsetValueObj = Instance.new("Vector3Value")
		assert(offsetValueObj, "")
		offsetValueObj.Name = "CameraOffset"
		offsetValueObj.Value = cameraOffset -- Legacy Default Value
		offsetValueObj.Parent = self.mouseLockController

		return
	end

	self.mouseLockController:WaitForChild("CameraOffset").Value = cameraOffset

	if not self.requiredCameraModule.activeCameraController then
		warn("No active camera controller")
		return
	end

	local currentMouseLockOffset = self.requiredCameraModule.activeCameraController:GetMouseLockOffset()
	return Methods.StartLerpAction(0, 1, changeDuration or 0.15, function(stepValue: number)
		self.requiredCameraModule.activeCameraController:SetMouseLockOffset(
			currentMouseLockOffset:Lerp(
				cameraOffset,
				TweenService:GetValue(
					stepValue,
					easingStyle or Enum.EasingStyle.Linear,
					easingDirection or Enum.EasingDirection.Out
				)
			)
		)
	end)
end

function RobloxCameraController:LaunchController()
	self:Init()

	self:SetMouseLockCameraOffset(Vector3.new())

	self.trove = Trove.new()
end

function RobloxCameraController:StopController()
	if self.trove then
		self.trove:Destroy()
		self.trove = nil
	end
end

function RobloxCameraController:KnitInit()
	self:Init()

	self.ClientController = Knit.GetController("ClientController")

	self.ClientController.HumanoidSpawned:Connect(function()
		self:LaunchController()
	end)

	self.ClientController.HumanoidDied:Connect(function()
		self:StopController()
	end)
end

return RobloxCameraController
