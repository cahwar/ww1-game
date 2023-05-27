local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Common.Packages.Knit)

local GunsSettings = require(ReplicatedStorage.Common.Settings.GunsSettings)
local GameParts = ReplicatedStorage.Common.GameParts

local GunEffectsFolder = Instance.new("Folder")
GunEffectsFolder.Name = "GunEffects"
GunEffectsFolder.Parent = workspace

local GunController = Knit.CreateController({ Name = "GunController" })

function GunController:ApplyShotEffects(gunInstance: Instance, gunSettings)
	local gunEffects = GameParts:FindFirstChild(gunSettings.Effects.Shot, true)
	if not gunEffects then
		warn("No gun effects for this type of gun:", gunInstance)
		return
	end

	gunEffects = gunEffects:Clone()
	local effectsPoint = gunInstance:FindFirstChild("Muzzle", true)
		or gunInstance:FindFirstChildWhichIsA("BasePart", true)

	gunEffects.Parent = GunEffectsFolder
	gunEffects.Position = effectsPoint.Position

	for _, v: Instance in gunEffects:GetChildren() do
		if v:IsA("Light") then
			v.Enabled = true
			task.delay(v:GetAttribute("LifeTime") or 0.3, function()
				v.Enabled = false
			end)
		elseif v:IsA("ParticleEmitter") then
			v:Emit(55)
		end
	end

	task.delay(5, gunEffects.Destroy, gunEffects)
end

-- // This one is used to handle events for every player excent the one that fired the gun
function GunController:OnGunShot(character: Model)
	local gunInstance = character:FindFirstChildWhichIsA("Tool")

	if not gunInstance then
		warn("This character does not have any tool that may be a gun instance equipped:", character or "|NULL|")
		return
	end

	local gunSettings = GunsSettings.Guns[gunInstance:GetAttribute("SettingsName") or gunInstance.Name]
	if not gunSettings then
		warn("The tool that was found does not have any gun settings binded to it:", gunInstance or "|NULL|")
		return
	end

	self:ApplyShotEffects(gunInstance, gunSettings)
end

function GunController:KnitStart() end

function GunController:KnitInit() end

return GunController
