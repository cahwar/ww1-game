local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Common.Packages.Component)
local Trove = require(ReplicatedStorage.Common.Packages.Trove)
local Knit = require(ReplicatedStorage.Common.Packages.Knit)
local Methods = require(ReplicatedStorage.Common.Modules.Methods)
local Sounds = require(ReplicatedStorage.Common.Modules.Sounds)
local Timer = require(ReplicatedStorage.Common.Packages.Timer)

local Animations = require(ReplicatedStorage.Common.Modules.Animations)
local GunsSettings = require(ReplicatedStorage.Common.Settings.GunsSettings)
local CameraSettings = require(ReplicatedStorage.Common.Settings.CameraSettings)
local HumanoidSettings = require(ReplicatedStorage.Common.Settings.HumanoidSettings)

local Cooldown = require(ReplicatedStorage.Common.Classes.Cooldown)
local CameraShake = require(ReplicatedStorage.Common.Classes.CameraShake)

local Player = Players.LocalPlayer

local RobloxCameraController = Knit.GetController("RobloxCameraController")
local CharacterStateController = Knit.GetController("CharacterStateController")
local CharacterMovementController = Knit.GetController("CharacterMovementController")
local CameraController = Knit.GetController("CameraController")
local GunController = Knit.GetController("GunController")
local ClientController = Knit.GetController("ClientController")

local OnlyLocalPlayer = {
	ShouldConstruct = function(component)
		local localCharacter = Player.Character or Player.CharacterAdded:Wait()
		return component.Instance:IsDescendantOf(localCharacter) or component.Instance:IsDescendantOf(Player)
	end,
}

local GunClient = Component.new({ Tag = "Gun", Extensions = { OnlyLocalPlayer } })

function GunClient:Start()
	self.shotCooldown = Cooldown.new()

	self.character = Player.Character or Player.CharacterAdded:Wait()
	self.trove = Trove.new()

	self.gunSettings = GunsSettings.Guns[self.Instance:GetAttribute("SettingsName") or self.Instance.Name]

	local animationsPackFormatted = {}
	for _, v in self.gunSettings.Animations do
		table.insert(animationsPackFormatted, v)
	end
	Animations:LoadAnimationsPack(self.character, animationsPackFormatted)

	self.trove:Connect(self.Instance.Equipped, function()
		self:OnEquip()
	end)
	self.trove:Connect(self.Instance.Unequipped, function()
		self:OnUnequip()
	end)
	self.trove:Connect(self.Instance.Destroying, function()
		self:OnDestroy()
	end)

	self.gunStats = {
		fireRate = self.gunSettings.PossibleFireRates[1],
	}
end

function GunClient:OnEquip()
	self.Equipped = true

	self.sessionTrove = self.trove:Extend()
	self.sessionTrove:Add(function()
		self.sessionTrove = nil
	end)

	Animations:PlayAnimation(self.character, self.gunSettings.Animations.Idle, 0.15)

	if RobloxCameraController.requiredCameraModule.activeMouseLockController.isMouseLocked == false then
		RobloxCameraController:EnableMouseLock(CameraSettings.CameraOffsets.GunDefaultCameraOffset)
	else
		RobloxCameraController:SetMouseLockCameraOffset(CameraSettings.CameraOffsets.GunDefaultCameraOffset)
	end

	ClientController:SetMouseCursor("Crosshair")
	self:BindPcInputs()

	self.sessionTrove:Add(function()
		ClientController:SetMouseCursor("Default")
		self.Equipped = false
		RobloxCameraController:DisableMouseLock()
		Animations:StopAnimation(self.character, self.gunSettings.Animations.Idle, 0.15)
	end)
end

function GunClient:OnUnequip()
	if self.sessionTrove then
		self.sessionTrove:Destroy()
	end
end

function GunClient:OnDestroy()
	self.trove:Destroy()
end

function GunClient:BindPcInputs()
	ContextActionService:BindAction("Aim", function(_, inputState: Enum.UserInputState)
		if inputState == Enum.UserInputState.Begin then
			if not CharacterStateController:TryChangeActionState(CharacterStateController.CharacterActionState.Aim) then
				return
			end

			self:StartAim()
		elseif inputState == Enum.UserInputState.End then
			self:StopAim()
		end

		return Enum.ContextActionResult.Pass
	end, false, Enum.UserInputType.MouseButton2)

	ContextActionService:BindAction("Shot", function(_, inputState: Enum.UserInputState)
		if inputState == Enum.UserInputState.Begin then
			if self.gunStats.fireRate == GunsSettings.FireRates.Semi then
				self:Shot()
			elseif self.gunStats.fireRate == GunsSettings.FireRates.Auto then
				local automaticShotTimer = Timer.new(self.gunSettings.ShotCooldown)
				automaticShotTimer.Tick:Connect(function()
					self:Shot()
				end)

				self.automaticShotTrove = self.sessionTrove:Extend()
				self.automaticShotTrove:Add(function()
					self.automaticShotTrove = nil
					automaticShotTimer:Destroy()
				end)

				automaticShotTimer:StartNow()
			end
		elseif inputState == Enum.UserInputState.End and self.automaticShotTrove then
			self.automaticShotTrove:Destroy()
		end

		return Enum.ContextActionResult.Pass
	end, false, Enum.UserInputType.MouseButton1)

	ContextActionService:BindAction("SwitchFireRate", function(_, inputState: Enum.UserInputState)
		if inputState == Enum.UserInputState.Begin then
			self:SwitchFireRate()
		end
	end, false, Enum.KeyCode.V)

	self.sessionTrove:Add(function()
		ContextActionService:UnbindAction("Aim")
		ContextActionService:UnbindAction("Shot")
		ContextActionService:UnbindAction("SwitchFireRate")
	end)
end

function GunClient:SwitchFireRate()
	local currentFireRateIndex = table.find(self.gunSettings.PossibleFireRates, self.gunStats.fireRate)
	if not currentFireRateIndex then
		print("no fire rate index")
		self.gunStats.fireRate = self.gunSettings.PossibleFireRates[1]
	else
		local selectedFireRate = self.gunSettings.PossibleFireRates[currentFireRateIndex + 1] ~= nil
				and self.gunSettings.PossibleFireRates[currentFireRateIndex + 1]
			or self.gunSettings.PossibleFireRates[1]

		self.gunStats.fireRate = selectedFireRate
	end
end

function GunClient:ShakeCameraOnShot()
	local shakeCalculationsToApply = CharacterStateController.CurrentActionState
				== CharacterStateController.CharacterActionState.Aim
			and self.gunSettings.AimShakeCalculations
		or self.gunSettings.NoAimShakeCalculations

	CameraShake.fromStaticCalculations({ RotationAxis = "XZ" }, shakeCalculationsToApply):DestroySmoothly(0.2)
end

function GunClient:BlurCameraOnShot()
	local blur = Instance.new("BlurEffect")
	blur.Size = 0
	blur.Parent = workspace.CurrentCamera
	Methods.TweenNow(
		blur,
		{ Size = 12 },
		TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true, 0)
	).Promise
		:andThen(function()
			blur:Destroy()
		end)
end

-- // Applies quick bright color correction
function GunClient:HighlightCameraOnShot()
	local colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Parent = workspace.CurrentCamera
	Methods.TweenNow(
		colorCorrection,
		{ Brightness = 0.1 },
		TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true, 0)
	).Promise
		:andThen(function()
			colorCorrection:Destroy()
		end)
end

function GunClient:Shot()
	if self.gunStats.fireRate ~= GunsSettings.FireRates.Auto then
		if self.shotCooldown:IsActive() then
			return
		end

		self.shotCooldown:SetActive(self.gunSettings.ShotCooldown)
	end

	-- Aim shot or common shot
	local shotAnimationName = nil

	if CharacterStateController.CurrentActionState == CharacterStateController.CharacterActionState.Aim then
		shotAnimationName = self.gunSettings.Animations.AimShot
	else
		shotAnimationName = self.gunSettings.Animations.NoAimShot
	end

	Sounds:PlaySoundOnce(self.gunSettings.Sounds.Shot, Sounds.CreateSoundPart(self.character.HumanoidRootPart.Position))
	Animations:PlayAnimation(self.character, shotAnimationName, 0, nil)
	self:ShakeCameraOnShot()
	self:BlurCameraOnShot()
	self:HighlightCameraOnShot()
	GunController:ApplyShotEffects(self.Instance, self.gunSettings)
end

function GunClient:StartAim()
	self.aimTrove = self.sessionTrove:Extend()
	self.aimTrove:Add(function()
		self.aimTrove = nil
	end)

	self.aimTrove:Connect(CharacterStateController.Signals.MovementStateChanged, function()
		self.character.Humanoid.WalkSpeed = HumanoidSettings.AimSpeedMultipler
			* CharacterMovementController:GetCurrentStateSpeed()
	end)

	self.character.Humanoid.WalkSpeed = HumanoidSettings.AimSpeedMultipler
		* CharacterMovementController:GetCurrentStateSpeed()

	RobloxCameraController:SetMouseLockCameraOffset(CameraSettings.CameraOffsets.GunAimCameraOffset)
	Animations:PlayAnimation(self.character, self.gunSettings.Animations.Aim, 0.15, 0)

	self.AimAnimationTrack = Animations:GetAnimationInfo(self.character, self.gunSettings.Animations.Aim).Track

	Methods.TweenNow(
		workspace.CurrentCamera,
		{ FieldOfView = CameraSettings.FieldOfViews.Aim },
		TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	)

	self.aimTrove:Add(function()
		if CharacterStateController.CurrentActionState == CharacterStateController.CharacterActionState.Aim then
			CharacterStateController:ChangeActionState(nil)
		end

		self.character.Humanoid.WalkSpeed = CharacterMovementController:GetCurrentStateSpeed()

		if self.Equipped then
			RobloxCameraController:SetMouseLockCameraOffset(CameraSettings.CameraOffsets.GunDefaultCameraOffset)
		end

		Methods.TweenNow(
			workspace.CurrentCamera,
			{ FieldOfView = CameraController:GetFovFromMovementState() },
			TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		)

		Animations:StopAnimation(self.character, self.gunSettings.Animations.Aim, 0.15)
	end)
end

function GunClient:StopAim()
	if self.aimTrove then
		self.aimTrove:Destroy()
	end
end

return GunClient
