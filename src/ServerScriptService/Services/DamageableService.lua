local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Knit = require(ReplicatedStorage.Common.Packages.Knit)

local GeneralDamageable = require(ServerScriptService.Server.Classes.Damageable)
local HumanoidDamageable = require(ServerScriptService.Server.Classes.HumanoidDamageable)
local PlayerDamageable = require(ServerScriptService.Server.Classes.PlayerDamageable)

local DamageableService = Knit.CreateService({
	Name = "DamageableService",
	Client = {},
})

function DamageableService:GetDamageable(instance: Instance)
	return GeneralDamageable.Damageables[instance]
end

function DamageableService:InitPlayerDamageable(player: Player)
	local character = player.Character or player.CharacterAdded:Wait()

	repeat
		task.wait()
	until character:IsDescendantOf(workspace)

	PlayerDamageable.new(character)

	local humanoid = character:WaitForChild("Humanoid")
	humanoid.Died:Once(function()
		player.CharacterAdded:Wait()
		self:InitPlayerDamageable(player)
	end)
end

function DamageableService:InitDamageablesByTag(tag: string, callback: (Instance) -> nil)
	for _, v in CollectionService:GetTagged(tag) do
		callback(v)
	end

	CollectionService:GetInstanceAddedSignal(tag):Connect(function(instance: Instance)
		callback(instance)
	end)
end

function DamageableService:KnitStart()
	for _, v in Players:GetPlayers() do
		task.spawn(self.InitPlayerDamageable, self, v)
	end

	Players.PlayerAdded:Connect(function(player)
		task.spawn(self.InitPlayerDamageable, self, player)
	end)

	self:InitDamageablesByTag("Humanoid", function(instance: Instance)
		HumanoidDamageable.new(instance)
	end)
end

return DamageableService
