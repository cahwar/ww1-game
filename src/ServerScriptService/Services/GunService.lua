local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Common.Packages.Knit)
local Trove = require(ReplicatedStorage.Common.Packages.Trove)

local GunsSettings = require(ReplicatedStorage.Common.Settings.GunsSettings)
local GunModule = require(ReplicatedStorage.Common.Modules.GunModule)
local FastCast = require(ReplicatedStorage.Common.Modules.FastCastRedux)

local GunService = Knit.CreateService({
	Name = "GunService",
	Client = {
		DrawShotCast = Knit.CreateSignal(),
	},
	CastersInfo = {},
})

function GunService.Client:Reload(player)
	local playerGun = self.Server:GetPlayerGun(player)
	if not playerGun then
		return
	end

	local clipSize = playerGun:GetAttribute("ClipSize")

	if playerGun:GetAttribute("AmmoLoaded") >= clipSize then
		return
	end

	local clipsStorage = playerGun:GetAttribute("ClipsStorage")
	if clipsStorage <= 0 then
		return
	end

	if playerGun:GetAttribute("Reloading") then
		return
	end

	print("started reloading")

	playerGun:SetAttribute("Reloading", true)
	playerGun:SetAttribute("ClipsStorage", clipsStorage - 1)
	task.delay(playerGun:GetAttribute("ReloadTime"), function()
		print("reloaded")
		playerGun:SetAttribute("AmmoLoaded", clipSize)
		playerGun:SetAttribute("Reloading", nil)
	end)
end

function GunService.Client:Shot(player: Player, centerRay: Ray)
	local playerGun = self.Server:GetPlayerGun(player)
	if not playerGun then
		return
	end

	if tick() - playerGun:GetAttribute("LastTimeFired") < playerGun:GetAttribute("ShotCooldown") then
		return
	end

	local ammoLoaded = playerGun:GetAttribute("AmmoLoaded")
	if ammoLoaded <= 0 then
		return
	end

	playerGun:SetAttribute("LastTimeFired", tick())
	playerGun:SetAttribute("AmmoLoaded", ammoLoaded - 1)

	local casterInfo = self.Server.CastersInfo[playerGun]
	if not casterInfo then
		return
	end

	local hitSource, hitDirection = GunModule.GetHitRayPoints(player.Character, playerGun, centerRay)
	if not hitSource or not hitDirection then
		return
	end

	casterInfo.Caster:Fire(hitSource, hitDirection, 1000, casterInfo.Behavior)
	self.DrawShotCast:FireAll(playerGun, hitSource, hitDirection, 1000, GunsSettings.General.Acceleration)
end

function GunService:GetPlayerGun(player)
	local character = player.Character
	if not character or character.Humanoid:GetState() == Enum.HumanoidStateType.Dead then
		return false
	end

	local tool = character:FindFirstChildWhichIsA("Tool")
	if not tool or not CollectionService:HasTag(tool, "Gun") then
		return false
	end

	return tool
end

function GunService:GetCasterInfo(gunInstance: Tool)
	return self.Casters[gunInstance]
end

function GunService:OnHit(instanceHit: Instance, gunInstance: Tool)
	local damageable =
		self.DamageableService:GetDamageable(instanceHit:FindFirstAncestorWhichIsA("Model") or instanceHit)

	if not damageable then
		return
	end

	damageable:TakeDamage(gunInstance:GetAttribute("ShotDamage") or 0, instanceHit)
end

function GunService:InitCaster(gunInstance: Tool)
	local toolCharacter = GunModule.GetToolOwnerCharacter(gunInstance)
	if not toolCharacter then
		return
	end

	if self.CastersInfo[gunInstance] then
		self.CastersInfo[gunInstance].Trove:Destroy()
	end

	local casterInfo = {
		Caster = FastCast.new(),
		Behavior = FastCast.newBehavior(),
		Trove = Trove.new(),
	}

	casterInfo.Caster.RayHit:Connect(function(_, raycastResult)
		if not raycastResult or not raycastResult.Instance then
			return
		end

		self:OnHit(raycastResult.Instance, gunInstance)
	end)

	casterInfo.Behavior.RaycastParams = GunModule.CreateDefaultRaycastParams({ toolCharacter })
	casterInfo.Behavior.Acceleration = GunsSettings.General.Acceleration

	self.CastersInfo[gunInstance] = casterInfo

	return casterInfo
end

function GunService:InitGun(gunInstance: Tool)
	local gunTrove = Trove.new()
	gunTrove:AttachToInstance(gunInstance)
	gunTrove:Connect(gunInstance.Equipped, function()
		local character = gunInstance:FindFirstAncestorWhichIsA("Model")
		if not character then
			return
		end
		GunModule.AttachGunToCharacter(character, gunInstance)
	end)

	local gunSettings = GunsSettings.Guns[gunInstance:GetAttribute("SettingsName") or gunInstance.Name]
	if not gunSettings then
		warn("No gun settings for this tool:", gunInstance or "|NULL|")
		return false
	end

	for i, v in gunSettings.Stats do
		gunInstance:SetAttribute(i, v)
	end

	gunInstance:SetAttribute("LastTimeFired", 0)
	gunInstance:SetAttribute("ShotCooldown", gunSettings.Stats.ShotCooldown)
	gunInstance:SetAttribute("ClipsStorage", gunSettings.Stats.ClipsStorage)
	gunInstance:SetAttribute("AmmoLoaded", gunSettings.Stats.ClipSize)
	gunInstance:SetAttribute("ClipSize", gunSettings.Stats.ClipSize)
	gunInstance:SetAttribute("ReloadTime", gunSettings.Stats.ReloadTime)
	gunInstance:SetAttribute("ShotDamage", gunSettings.Stats.ShotDamage)

	if not self:InitCaster(gunInstance) then
		return false
	end

	return true
end

function GunService:KnitStart()
	for _, v in CollectionService:GetTagged("Gun") do
		self:InitGun(v)
	end

	CollectionService:GetInstanceAddedSignal("Gun"):Connect(function(gunInstance: Tool)
		self:InitGun(gunInstance)
	end)
end

function GunService:KnitInit()
	self.SoundService = Knit.GetService("SoundService")
	self.DamageableService = Knit.GetService("DamageableService")
end

return GunService
