local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Concur = require(ReplicatedStorage.Common.Packages.Concur)

local Cooldown = {}
Cooldown.__index = Cooldown

function Cooldown.new()
	local self = setmetatable({
		Enabled = false,
	}, Cooldown)
	return self
end

function Cooldown:SetActive(duration)
	if self.Enabled then
		return
	end

	self.Enabled = true

	Concur.delay(duration, function()
		self.Enabled = false
	end)
end

function Cooldown:IsActive()
	return self.Enabled
end

return Cooldown
