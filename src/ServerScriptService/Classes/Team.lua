local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")

local State = require(ServerScriptService.Server.StateSystem.State.Main)
local Signal = require(ReplicatedStorage.Common.Packages.Signal)

local Team = {}
Team.__index = Team

export type TeamOptions = {
	PlayersStatePath: string,
	Name: string,
	Color: Color3,
}

function Team.new(teamOptions: TeamOptions)
	local teamInstance = Instance.new("Team")
	teamInstance.Name = teamOptions.Name
	teamInstance.AutoAssignable = false
	teamInstance.TeamColor = teamOptions.Color
	teamInstance.Parent = Teams

	local self = setmetatable({
		Deaths = 0,
		Name = teamOptions.Name,
		PlayersState = State.new(teamOptions.PlayersStatePath),
		TeamInstance = teamInstance,
		TeamChanged = Signal.new(),
	}, Team)

	task.spawn(function()
		while task.wait(math.random(3, 8)) do
			self:IncreaseDeathsCount()
		end
	end)

	return self
end

function Team:AssignPlayer(player: Player)
	self.PlayersState:Update(function(currentPlayers: {})
		table.insert(currentPlayers, player)
		player.Team = self.TeamInstance
		self.TeamChanged:Fire()
		return currentPlayers
	end)
end

function Team:IncreaseDeathsCount()
	self:_ChangeDeathsCount(self.Deaths + 1)
end

function Team:_ChangeDeathsCount(amountToSet)
	self.Deaths = amountToSet
	self.TeamChanged:Fire()
end

return Team
