local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Damageable = require(ServerScriptService.Server.Classes.Damageable)
local Methods = require(ReplicatedStorage.Common.Modules.Methods)

local HumanoidDamageable = setmetatable({}, Damageable)
HumanoidDamageable.__index = HumanoidDamageable

function HumanoidDamageable.new(instance: Instance)
	local self = setmetatable(Damageable.new(instance), HumanoidDamageable)

	self.Humanoid = instance:FindFirstChildWhichIsA("Humanoid", true)

	return self
end

function HumanoidDamageable:TakeDamage(damage: number, damagedPart: BasePart?)
	if not self.Alive then
		return
	end

	self.Humanoid:TakeDamage(damage)

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
