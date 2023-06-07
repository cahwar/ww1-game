local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Common.Packages.Component)
local Trove = require(ReplicatedStorage.Common.Packages.Trove)
local Knit = require(ReplicatedStorage.Common.Packages.Knit)
local Methods = require(ReplicatedStorage.Common.Modules.Methods)
local Sounds = require(ReplicatedStorage.Common.Modules.Sounds)
local Timer = require(ReplicatedStorage.Common.Packages.Timer)
local GunModule = require(ReplicatedStorage.Common.Modules.GunModule)
local GuiModule = require(ReplicatedStorage.Common.Modules.GuiModule)

local Animations = require(ReplicatedStorage.Common.Modules.Animations)
local GunsSettings = require(ReplicatedStorage.Common.Settings.GunsSettings)
local CameraSettings = require(ReplicatedStorage.Common.Settings.CameraSettings)

local Cooldown = require(ReplicatedStorage.Common.Classes.Cooldown)
local CameraShake = require(ReplicatedStorage.Common.Classes.CameraShake)

local Player = Players.LocalPlayer

local RobloxCameraController = Knit.GetController("RobloxCameraController")
local CharacterStateController = Knit.GetController("CharacterStateController")
local CameraController = Knit.GetController("CameraController")
local GunController = Knit.GetController("GunController")
local ClientController = Knit.GetController("ClientController")

local GunService = Knit.GetService("GunService")
local RunService = game:GetService("RunService")

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
	self.hitPointMarker = GuiModule.FindGui(Player, "HitPoint"):WaitForChild("Marker")
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

	if self.hitPointMarker and GunsSettings.General.DisplayHitPoint then
		self:StartDisplayingHitPoint()
		self.sessionTrove:Add(function()
			self:StopDisplayingHitPoint()
		end)
	end
end

function GunClient:OnUnequip()
	if self.sessionTrove then
		self.sessionTrove:Destroy()
	end
end

function GunClient:OnDestroy()
	self.trove:Destroy()
end

function GunClient:StartDisplayingHitPoint()
	self.hitPointTrove = self.sessionTrove:Extend()
	self.hitPointTrove:Add(function()
		self.hitPointTrove = nil
	end)

	self.hitPointTrove:Connect(RunService.Heartbeat, function()
		local viewportSize = workspace.CurrentCamera.ViewportSize
		local viewportCenter = Vector2.new(viewportSize.X - (viewportSize.X / 2), viewportSize.Y - (viewportSize.Y / 2))
		local viewportCenterWihoutInset = Vector2.new(viewportCenter.X, viewportCenter.Y - GuiService:GetGuiInset().Y)

		local raycastResult = GunModule.GetHitRaycastResult(
			self.character,
			self.Instance,
			workspace.CurrentCamera:ScreenPointToRay(viewportCenterWihoutInset.X, viewportCenterWihoutInset.Y)
		)

		if not raycastResult then
			if self.hitPointMarker.Visible then
				self.hitPointMarker.Visible = false
			end

			return
		end

		local screenPosition = workspace.CurrentCamera:WorldToScreenPoint(raycastResult.Position)
		local hitPointMarkerSize = self.hitPointMarker.AbsoluteSize
		local hitPointPositionToSet = UDim2.fromOffset(
			screenPosition.X - (hitPointMarkerSize.X / 2),
			screenPosition.Y - (hitPointMarkerSize.Y / 2)
		)

		local differenceVector = Vector2.new(
			viewportCenterWihoutInset.X - hitPointPositionToSet.X.Offset,
			viewportCenterWihoutInset.Y - hitPointPositionToSet.Y.Offset
		)

		if
			Methods.Approximately(differenceVector.X, hitPointMarkerSize.X / 2, 2)
			and Methods.Approximately(differenceVector.Y, hitPointMarkerSize.Y / 2, 2)
		then
			if self.hitPointMarker.Visible then
				self.hitPointMarker.Visible = false
			end

			return
		end

		if not self.hitPointMarker.Visible then
			self.hitPointMarker.Visible = true
		end

		self.hitPointMarker.Position = hitPointPositionToSet
	end)
end

function GunClient:StopDisplayingHitPoint()
	if self.hitPointTrove then
		self.hitPointTrove:Destroy()
	end
end

function GunClient:BindPcInputs()
	ContextActionService:BindAction("Aim", function(_, inputState: Enum.UserInputState)
		if inputState == Enum.UserInputState.Begin then
			if not self:CanAim() then
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
			if not CharacterStateController:CanChangeState("Shot") then
				return
			end

			if self.gunStats.fireRate == GunsSettings.FireRates.Semi then
				if not self:CanFire() then
					return
				end

				self:Shot()
			elseif self.gunStats.fireRate == GunsSettings.FireRates.Auto then
				if not self:CanFire() then
					return
				end

				self:StartAutomaticFire()
			end
		elseif inputState == Enum.UserInputState.End then
			if self.automaticShotTrove then
				self.automaticShotTrove:Destroy()
			end
		end

		return Enum.ContextActionResult.Pass
	end, false, Enum.UserInputType.MouseButton1)

	ContextActionService:BindAction("SwitchFireRate", function(_, inputState: Enum.UserInputState)
		if inputState == Enum.UserInputState.Begin then
			self:SwitchFireRate()
		end
	end, false, Enum.KeyCode.V)

	ContextActionService:BindAction("Reload", function(_, inputState: Enum.UserInputState)
		if inputState == Enum.UserInputState.Begin then
			if not self:CanReload() then
				return
			end

			self:ReloadIfPossible()
		end
	end, false, Enum.KeyCode.R)

	self.sessionTrove:Add(function()
		ContextActionService:UnbindAction("Aim")
		ContextActionService:UnbindAction("Shot")
		ContextActionService:UnbindAction("SwitchFireRate")
		ContextActionService:UnbindAction("Reload")
	end)
end

function GunClient:SwitchFireRate()
	if #self.gunSettings.PossibleFireRates == 1 then
		return
	end

	if self.gunStats.fireRate == GunsSettings.FireRates.Auto then
		self:StopAutomaticFire()
	end

	local currentFireRateIndex = table.find(self.gunSettings.PossibleFireRates, self.gunStats.fireRate)
	if not currentFireRateIndex then
		print("No fire rate index")
		self.gunStats.fireRate = self.gunSettings.PossibleFireRates[1]
	else
		local selectedFireRate = self.gunSettings.PossibleFireRates[currentFireRateIndex + 1] ~= nil
				and self.gunSettings.PossibleFireRates[currentFireRateIndex + 1]
			or self.gunSettings.PossibleFireRates[1]

		self.gunStats.fireRate = selectedFireRate
	end
end

function GunClient:ShakeCameraOnShot()
	local shakeCalculationsToApply = CharacterStateController.TemporaryState == "Aim"
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

function GunClient:CanFire()
	if not CharacterStateController:CanChangeState("Shot") then
		return false
	end

	if self.Instance:GetAttribute("AmmoLoaded") <= 0 then
		Sounds:PlaySoundOnce("EmptyClick_1", workspace.CurrentCamera)
		return
	end

	if self.reloading then
		return false
	end

	return true
end

function GunClient:StartAutomaticFire()
	local automaticShotTimer =
		Timer.new(self.gunSettings.Stats.ShotCooldown + (self.gunSettings.Stats.ShotCooldown / 10))

	automaticShotTimer.Tick:Connect(function()
		if not self:CanFire() then
			self:StopAutomaticFire()
			return
		end

		self:Shot()
	end)

	self.automaticShotTrove = self.sessionTrove:Extend()
	self.automaticShotTrove:Add(function()
		automaticShotTimer:Destroy()
		self.automaticShotTrove = nil
	end)

	automaticShotTimer:StartNow()
end

function GunClient:StopAutomaticFire()
	if self.automaticShotTrove then
		self.automaticShotTrove:Destroy()
	end
end

function GunClient:Shot()
	if self.shotCooldown:IsActive() then
		return
	end

	self.shotCooldown:SetActive(self.gunSettings.Stats.ShotCooldown)

	-- Aim shot or common shot
	local shotAnimationName = nil

	if CharacterStateController.TemporaryState == "Aim" then
		shotAnimationName = self.gunSettings.Animations.AimShot
	else
		shotAnimationName = self.gunSettings.Animations.NoAimShot
	end

	GunService:Shot()

	Sounds:PlaySoundOnce(self.gunSettings.Sounds.Shot, Sounds.CreateSoundPart(self.character.HumanoidRootPart.Position))
	Animations:PlayAnimation(self.character, shotAnimationName, 0, nil)
	self:ShakeCameraOnShot()
	self:BlurCameraOnShot()
	self:HighlightCameraOnShot()
	GunController:ApplyShotEffects(self.Instance, self.gunSettings)
end

function GunClient:CanAim()
	if not CharacterStateController:SetTemporaryStateIfPossible("Aim") then
		return false
	end

	if self.reloading then
		return false
	end

	return true
end

function GunClient:StartAim()
	self.aimTrove = self.sessionTrove:Extend()
	self.aimTrove:Add(function()
		self.aimTrove = nil
	end)

	RobloxCameraController:SetMouseLockCameraOffset(CameraSettings.CameraOffsets.GunAimCameraOffset)
	Animations:PlayAnimation(self.character, self.gunSettings.Animations.Aim, 0.15, 0)

	self.AimAnimationTrack = Animations:GetAnimationInfo(self.character, self.gunSettings.Animations.Aim).Track

	CameraController:SetTemporaryFOV(
		CameraSettings.FieldOfViews.Aim,
		TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	)

	self.aimTrove:Add(function()
		if CharacterStateController.TemporaryState == "Aim" then
			CharacterStateController:RemoveTemporaryState()
		end

		if self.Equipped then
			RobloxCameraController:SetMouseLockCameraOffset(CameraSettings.CameraOffsets.GunDefaultCameraOffset)
		end

		CameraController:RemoveTemporaryFOV(TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))

		Animations:StopAnimation(self.character, self.gunSettings.Animations.Aim, 0.15)
	end)
end

function GunClient:StopAim()
	if self.aimTrove then
		self.aimTrove:Destroy()
	end
end

function GunClient:CanReload()
	if self.gunStats.reloading then
		return false
	end

	if self.Instance:GetAttribute("AmmoLoaded") >= self.gunSettings.Stats.ClipSize then
		return
	end

	if self.Instance:GetAttribute("ClipsStorage") <= 0 then
		return
	end

	if not CharacterStateController:SetTemporaryStateIfPossible("Reload") then
		return false
	end

	return true
end

function GunClient:ApplyRackGunVisualsIfPossible()
	if not self.gunSettings.Animations.RackGun then
		return
	end

	Animations:PlayAnimation(self.character, self.gunSettings.Animations.RackGun, 0.1, nil, {
		Pull = function()
			print("Pull")
		end,
	})
end

function GunClient:ApplyReloadVisualsIfPossible()
	local reloadAnimationInfo = Animations:GetAnimationInfo(self.character, self.gunSettings.Animations.Reload)
	local rackAnimationInfo = Animations:GetAnimationInfo(self.character, self.gunSettings.Animations.RackGun)

	if not reloadAnimationInfo then
		return
	end

	local offset = 0.1
	if rackAnimationInfo then
		offset += rackAnimationInfo.Track.Length
	end

	self.sessionTrove:Add(reloadAnimationInfo.Track.Ended:Once(function()
		self:ApplyRackGunVisualsIfPossible()
	end))

	if self.gunSettings.Sounds.GeneralReload then
		local sound: Sound =
			ReplicatedStorage.Common.GameParts.Sounds:FindFirstChild(self.gunSettings.Sounds.GeneralReload, true)
		if sound then
			Sounds:PlaySoundOnce(
				self.gunSettings.Sounds.GeneralReload,
				workspace.CurrentCamera,
				sound.TimeLength / self.gunSettings.Stats.ReloadTime
			)
		end
	end

	Animations:PlayAnimation(
		self.character,
		self.gunSettings.Animations.Reload,
		0.1,
		reloadAnimationInfo.Track.Length / (self.gunSettings.Stats.ReloadTime - offset),
		{
			ClipDeattach = function()
				print("Clip revmoed")
			end,

			ClipSearchStarted = function()
				print("Search started")
			end,

			ClipSearchEnded = function()
				print("Search ended")
			end,

			ClipAttach = function()
				print("Clip attached")
			end,
		}
	)
end

function GunClient:ReloadIfPossible()
	self.gunStats.reloading = true

	GunService:Reload()
	self:ApplyReloadVisualsIfPossible()

	task.delay(self.gunSettings.Stats.ReloadTime, function()
		self.gunStats.reloading = false
		if CharacterStateController.TemporaryState == "Reload" then
			CharacterStateController:RemoveTemporaryState()
		end
	end)
end

return GunClient
