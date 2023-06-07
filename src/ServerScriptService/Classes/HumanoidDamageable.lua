local ServerScriptService = game:GetService("ServerScriptService")

local Damageable = require(ServerScriptService.Server.Classes.Damageable)

local HumanoidDamageable = setmetatable({}, Damageable)
HumanoidDamageable.__index = HumanoidDamageable

function HumanoidDamageable.new(instance: Instance)
	local self = setmetatable(Damageable.new(instance), HumanoidDamageable)

	self.Humanoid = instance:FindFirstChildWhichIsA("Humanoid", true)

	return self
end

function HumanoidDamageable:TakeDamage(damage: number)
	if not self.Alive then
		return
	end

	self.Humanoid:TakeDamage(damage)
	if self.Humanoid.Health <= 0 then
		self:Destroy()
	end
end

return HumanoidDamageable
