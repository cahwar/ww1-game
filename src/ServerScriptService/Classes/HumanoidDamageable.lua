local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Damageable = require(ServerScriptService.Server.Classes.Damageable)
local Methods = require(ReplicatedStorage.Common.Modules.Methods)

local HumanoidDamageable = setmetatable({}, Damageable)
HumanoidDamageable.__index = HumanoidDamageable

local DamageMultiplers = {
	Head = 2,
	UpperTorso = 1.1,
	LowerTorso = 1.3,
	RightFoot = 0.4,
	LeftFoot = 0.4,
	RightHand = 0.5,
	LeftHand = 0.5,
}

function HumanoidDamageable.new(instance: Instance)
	local self = setmetatable(Damageable.new(instance), HumanoidDamageable)

	self.Humanoid = instance:FindFirstChildWhichIsA("Humanoid", true)

	return self
end

function HumanoidDamageable:TakeDamage(damage: number, damagedPart: BasePart?)
	if not self.Alive then
		return
	end

	local damageMultipler = damagedPart and DamageMultiplers[damagedPart.Name] or 1

	self.Humanoid:TakeDamage(damage * damageMultipler)

	Methods.EmitParticlesOnce(
		"BloodFog",
		damagedPart or self.Instance:FindFirstChildWhichIsA("BasePart", true),
		math.random(10, 15)
	)

	Methods.EnableParticlesEmition(
		"BloodDrops",
		damagedPart or self.Instance:FindFirstChildWhichIsA("BasePart", true),
		math.random(0.6, 1.8)
	)

	if self.Humanoid.Health <= 0 then
		self:Destroy()
	end
end

return HumanoidDamageable
