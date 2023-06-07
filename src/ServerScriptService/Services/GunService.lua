local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Common.Packages.Knit)
local GunsSettings = require(ReplicatedStorage.Common.Settings.GunsSettings)
local GunModule = require(ReplicatedStorage.Common.Modules.GunModule)

local GunService = Knit.CreateService({
	Name = "GunService",
	Client = {},
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

function GunService.Client:Shot(player: Player)
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

	print("Bang")
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

function GunService:InitGun(gunInstance: Tool)
	gunInstance.Equipped:Connect(function()
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
end

return GunService
