local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Common.Packages.Knit)
local Trove = require(ReplicatedStorage.Common.Packages.Trove)

local GunsSettings = require(ReplicatedStorage.Common.Settings.GunsSettings)
local GameParts = ReplicatedStorage.Common.GameParts

local GunModule = require(ReplicatedStorage.Common.Modules.GunModule)
local FastCast = require(ReplicatedStorage.Common.Modules.FastCastRedux)

local GunEffectsFolder = Instance.new("Folder")
GunEffectsFolder.Name = "GunEffects"
GunEffectsFolder.Parent = workspace

local GunController = Knit.CreateController({
	Name = "GunController",
	CastersInfo = {},
})

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

-- // This one is used to handle event for every player excent the one that fired the gun
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

function GunController:InitCaster(gunInstance: Tool)
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

	casterInfo.Behavior.RaycastParams = GunModule.CreateDefaultRaycastParams({ toolCharacter })
	casterInfo.Behavior.Acceleration = GunsSettings.General.Acceleration
	casterInfo.Behavior.CosmeticBulletTemplate = ReplicatedStorage.Common.GameParts.Other.BulletTracer
	casterInfo.Behavior.CosmeticBulletContainer = workspace:FindFirstChild("Tracers")
		or (function()
			local folder = Instance.new("Folder")
			folder.Name = "Tracers"
			folder.Parent = workspace
			return folder
		end)()

	casterInfo.Caster.CastTerminating:Connect(function(activeCast)
		if activeCast.RayInfo.CosmeticBulletObject then
			activeCast.RayInfo.CosmeticBulletObject:Destroy()
		end
	end)

	casterInfo.Caster.LengthChanged:Connect(function(_, lastPoint, direction, length, _, bullet)
		if not bullet then
			return
		end

		if not bullet.Trail.Enabled then
			bullet.Trail.Enabled = true
		end

		local bulletLength = bullet.Size.Z / 2
		local offset = CFrame.new(0, 0, -(length - bulletLength))
		bullet.CFrame = CFrame.lookAt(lastPoint, lastPoint + direction):ToWorldSpace(offset)
	end)

	self.CastersInfo[gunInstance] = casterInfo

	return casterInfo
end

function GunController:OnDrawShotCast(
	gunInstance: Tool,
	origin: Vector3,
	direction: Vector3,
	velocity: number,
	acceleration: Vector3?
)
	local casterInfo = self.CastersInfo[gunInstance]

	if not casterInfo then
		return
	end

	if acceleration then
		casterInfo.Behavior.Acceleration = acceleration
	end

	local gunPart = gunInstance:FindFirstChild("Muzzle", true) or gunInstance:FindFirstChildWhichIsA("BasePart", true)
	if gunPart then
		origin = gunPart.Position
	end

	casterInfo.Caster:Fire(origin, direction, velocity, casterInfo.Behavior)
end

function GunController:KnitStart()
	for _, v in CollectionService:GetTagged("Gun") do
		self:InitCaster(v)
	end

	CollectionService:GetInstanceAddedSignal("Gun"):Connect(function(instance)
		self:InitCaster(instance)
	end)

	self.GunService.DrawShotCast:Connect(function(...)
		self:OnDrawShotCast(...)
	end)
end

function GunController:KnitInit()
	self.GunService = Knit.GetService("GunService")
end

return GunController
