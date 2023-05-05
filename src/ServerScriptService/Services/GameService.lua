local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Common.Packages.Knit)
local EnumList = require(ReplicatedStorage.Common.Packages.EnumList)

local GameService = Knit.CreateService({
	Name = "GameService",
	Client = {},

	RoundState = EnumList.new("RoundState", {
		"NotStarted",
		"Started",
	}),
})

function GameService:SetRoundState(state)
	self.CurrentRoundState = state
end

function GameService:GetRoundState()
	return self.CurrentRoundState
end

function GameService:KnitStart() end

function GameService:KnitInit()
	self:SetRoundState(self.RoundState.Started)
end

return GameService
