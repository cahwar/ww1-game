local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Common.Packages.Trove)

local Damageable = {}
Damageable.Damageables = {}
Damageable.__index = Damageable

function Damageable.new(instance: Instance)
	local self = setmetatable({
		Instance = instance,
		Trove = Trove.new(),
		Alive = true,
	}, Damageable)

	self.Trove:AttachToInstance(instance)
	self.Trove:Add(function()
		Damageable.Damageables[instance] = nil
		self.Alive = false
	end)

	Damageable.Damageables[instance] = self

	return self
end

function Damageable:Destroy()
	self.Trove:Destroy()
end

return Damageable
