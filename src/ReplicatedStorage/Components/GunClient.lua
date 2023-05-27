local ContextActionService = game:GetService("ContextActionService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Component = require(ReplicatedStorage.Common.Packages.Component)
local Trove = require(ReplicatedStorage.Common.Packages.Trove)
local Knit = require(ReplicatedStorage.Common.Packages.Knit)
local Methods = require(ReplicatedStorage.Common.Modules.Methods)

local Animations = require(ReplicatedStorage.Common.Modules.Animations)
local GunsSettings = require(ReplicatedStorage.Common.Settings.GunsSettings)
local CameraSettings = require(ReplicatedStorage.Common.Settings.CameraSettings)

local Cooldown = require(ReplicatedStorage.Common.Classes.Cooldown)

local Player = Players.LocalPlayer

local RobloxCameraController = Knit.GetController("RobloxCameraController")
local CharacterStateController = Knit.GetController("CharacterStateController")
local CameraController = Knit.GetController("CameraController")

local Settings = {
	MinCameraAngle = -70,
	MaxCameraAngle = 70,
}

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

	self:BindPcInputs()

	self.sessionTrove:Add(function()
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
			self:Shot()
		end

		return Enum.ContextActionResult.Pass
	end, false, Enum.UserInputType.MouseButton1)

	self.sessionTrove:Add(function()
		ContextActionService:UnbindAction("Aim")
		ContextActionService:UnbindAction("Shot")
	end)
end

function GunClient:ShakeCameraOnShot() end

function GunClient:Shot()
	if self.shotCooldown:IsActive() then
		return
	end

	self.shotCooldown:SetActive(self.gunSettings.ShotCooldown)

	-- Aim shot or common shot
	local shotAnimationName = nil

	if CharacterStateController.CurrentActionState == CharacterStateController.CharacterActionState.Aim then
		shotAnimationName = self.gunSettings.Animations.AimShot
	else
		shotAnimationName = self.gunSettings.Animations.NoAimShot
	end

	Animations:PlayAnimation(self.character, shotAnimationName, 0, nil)
end

function GunClient:StartAim()
	self.aimTrove = self.sessionTrove:Extend()
	self.aimTrove:Add(function()
		self.aimTrove = nil
	end)

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
