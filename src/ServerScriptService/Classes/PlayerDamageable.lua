local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local HumanoidDamageable = require(ServerScriptService.Server.Classes.HumanoidDamageable)

local PlayerDamageable = setmetatable({}, HumanoidDamageable)
PlayerDamageable.__index = PlayerDamageable

function PlayerDamageable.new(instance: Instance)
	local self = setmetatable(HumanoidDamageable.new(instance), PlayerDamageable)

	self.Player = Players:GetPlayerFromCharacter(instance)

	return self
end

function PlayerDamageable:TakeDamage(damage: number)
	HumanoidDamageable.TakeDamage(self, damage)
	print("Player damaged")
end

return PlayerDamageable
