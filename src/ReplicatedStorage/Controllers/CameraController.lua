local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Knit = require(ReplicatedStorage.Common.Packages.Knit)
local Trove = require(ReplicatedStorage.Common.Packages.Trove)
local Methods = require(ReplicatedStorage.Common.Modules.Methods)

local CameraShake = require(ReplicatedStorage.Common.Classes.CameraShake)
local CameraSettings = require(ReplicatedStorage.Common.Settings.CameraSettings)

local Camera = workspace.CurrentCamera

local CameraController = Knit.CreateController({ Name = "CameraController" })

local Settings = {
	CameraShake = {
		MaxSinSpeed = 22,
		MaxSinHeight = 1,
		MaxCosSpeed = 11,
		MaxCosHeight = 4.125,

		DefaultSinSpeed = 5,
		DefaultSinHeight = 0.275,
		DefaultCosHeight = 0,

		SinHeightMultipler = 0.05,
		CosHeightMultipler = 0.35,
	},

	MouseCameraTilt = {
		TiltSensitivity = 0.05,
		LimitX = 8,
		LimitY = 10,
	},

	MoveCameraTilt = {
		TiltSensitivity = 0.1,
		LimtiX = 3.5,
	},
}

function CameraController:Init()
	self.player = game:GetService("Players").LocalPlayer
	self.character = self.player.Character or self.player.CharacterAdded:Wait()
	self.humanoid = self.character:WaitForChild("Humanoid")
end

function CameraController:EnableDefaultCameraShake()
	self.defaultCameraShakeTrove = self.trove:Extend()

	self.defaultCameraShakeTrove:Add(function()
		if self.defaultCameraShake then
			self.defaultCameraShake:DestroySmoothly(0.5)
		end
	end)

	self.defaultCameraShake = CameraShake.fromDynamicCalculations(
		{ RotationAxis = CameraShake.RotationAxis.XZ },
		function()
			local isCharacterMoving = self.humanoid.MoveDirection.Magnitude >= 0.1
			local walkSpeed = self.humanoid.WalkSpeed

			local sinSpeed = isCharacterMoving and (walkSpeed * 2) or Settings.CameraShake.DefaultSinSpeed
			local sinHeight = isCharacterMoving and (0.08 * walkSpeed) or Settings.CameraShake.DefaultSinHeight
			local cosSpeed = walkSpeed
			local cosHeight = isCharacterMoving and (0.41 * walkSpeed) or Settings.CameraShake.DefaultCosHeight

			return {
				SinSpeed = math.min(sinSpeed, Settings.CameraShake.MaxSinSpeed),
				SinHeight = math.min(sinHeight, Settings.CameraShake.MaxSinHeight),
				CosSpeed = math.min(cosSpeed, Settings.CameraShake.MaxCosSpeed),
				CosHeight = math.min(cosHeight, Settings.CameraShake.MaxCosHeight),
			}
		end
	)
end

function CameraController:EnableMouseCameraTilt()
	self.mouseCameraTiltTrove = self.trove:Extend()

	self.mouseTiltAngle = CFrame.Angles(0, 0, 0)

	self.mouseCameraTiltTrove:Connect(RunService.RenderStepped, function()
		local mouseDelta = UserInputService:GetMouseDelta()

		local xDelta, yDelta = mouseDelta.X, mouseDelta.Y / 8.5

		local horizontalAngle = math.clamp(xDelta, -Settings.MouseCameraTilt.LimitX, Settings.MouseCameraTilt.LimitX)
		local verticalAngle = math.clamp(yDelta, -Settings.MouseCameraTilt.LimitY, Settings.MouseCameraTilt.LimitY)

		local currentMouseTiltAngle = CFrame.Angles(math.rad(verticalAngle), 0, math.rad(horizontalAngle))
		local mouseTiltAngleToSet =
			self.mouseTiltAngle:Lerp(currentMouseTiltAngle, Settings.MouseCameraTilt.TiltSensitivity)

		Camera.CFrame = Camera.CFrame * mouseTiltAngleToSet

		self.mouseTiltAngle = mouseTiltAngleToSet
	end)
end

function CameraController:EnableMoveCameraTilt()
	self.moveCameraTiltTrove = self.trove:Extend()

	self.moveTiltAngle = CFrame.Angles(0, 0, 0)

	self.moveCameraTiltTrove:Connect(RunService.RenderStepped, function()
		local moveDirection = self.humanoid.MoveDirection
		local sideDirectionDotProduct = Camera.CFrame.RightVector:Dot(moveDirection)
		local horizontalAngle = math.clamp(
			sideDirectionDotProduct * -1,
			math.rad(-Settings.MoveCameraTilt.LimtiX),
			math.rad(Settings.MoveCameraTilt.LimtiX)
		)

		local currentMoveTiltAngle = CFrame.Angles(0, 0, horizontalAngle)
		local moveTiltAngleToSet =
			self.moveTiltAngle:Lerp(currentMoveTiltAngle, Settings.MoveCameraTilt.TiltSensitivity)

		Camera.CFrame = Camera.CFrame * moveTiltAngleToSet

		self.moveTiltAngle = moveTiltAngleToSet
	end)
end

function CameraController:TweenFovAndRevert(fovToSet, tweenInfo: TweenInfo?)
	self:TweenFOV(fovToSet, tweenInfo):andThen(function()
		self:TweenFOV(self.TemporaryFOV or self.StaticFOV, tweenInfo)
	end)
end

function CameraController:TweenFOV(fovValue, tweenInfo: TweenInfo?)
	if self.fovTweenInfo then
		self.fovTweenInfo.Tween:Pause()
	end

	local fovTweenInfo = Methods.TweenNow(
		Camera,
		{ FieldOfView = fovValue },
		tweenInfo or TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	)

	self.fovTweenInfo = fovTweenInfo

	return fovTweenInfo.Promise:andThen(function()
		if self.fovTweenInfo == fovTweenInfo then
			self.fovTweenInfo = nil
		end
	end)
end

-- The ones that will be applied for a long time: idle, sprint, crawl
function CameraController:SetStaticFOV(fovValue: number, tweenInfo: TweenInfo?)
	self.StaticFOV = fovValue
	if not self.TemporaryFOV then
		self:TweenFOV(fovValue, tweenInfo)
	end
end

-- // The ones that should override the satic FOVs, but they're active for short amount of time, while some statement
-- is true. For for example: aim
function CameraController:SetTemporaryFOV(fovValue: number, tweenInfo: TweenInfo?)
	self.TemporaryFOV = fovValue
	self:TweenFOV(fovValue, tweenInfo)
end

function CameraController:RemoveTemporaryFOV(tweenInfo: TweenInfo?)
	self.TemporaryFOV = nil
	local fovToSet = self.StaticFOV or CameraSettings.FieldOfViews.Idle
	self:TweenFOV(fovToSet, tweenInfo)
end

function CameraController:LaunchController()
	self:Init()

	self:SetStaticFOV(CameraSettings.FieldOfViews.Idle)
	self.trove = Trove.new()

	self:EnableDefaultCameraShake()
	self:EnableMouseCameraTilt()
	self:EnableMoveCameraTilt()

	self.trove:Connect(self.CharacterStateController.Signals.MainStateChanged, function(stateName, stateSettings)
		self:SetStaticFOV(stateSettings and stateSettings.FieldOfView or CameraSettings.FieldOfViews.Idle)
	end)

	self.trove:Connect(self.CharacterStateController.Signals.TemporaryStateChanged, function(stateName, stateSettings)
		if stateName == nil then
			self:RemoveTemporaryFOV()
		end

		if not stateSettings then
			return
		end

		self:SetTemporaryFOV(stateSettings and stateSettings.FieldOfView or CameraSettings.FieldOfViews.Idle)
	end)
end

function CameraController:StopController()
	if self.trove then
		self.trove:Destroy()
	end
end

function CameraController:KnitStart() end

function CameraController:KnitInit()
	self.ClientController = Knit.GetController("ClientController")
	self.CharacterStateController = Knit.GetController("CharacterStateController")

	self.ClientController.HumanoidSpawned:Connect(function()
		self:LaunchController()
	end)

	self.ClientController.HumanoidDied:Connect(function()
		self:StopController()
	end)
end

return CameraController
