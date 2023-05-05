local ServerScriptService = game:GetService("ServerScriptService")
local TeamsService = game:GetService("Teams")

local State = require(ServerScriptService.Server.StateSystem.State.Main)

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
	teamInstance.Parent = TeamsService

	local self = setmetatable({
		Deaths = 0,
		Name = teamOptions.Name,
		PlayersState = State.new(teamOptions.PlayersStatePath),
		TeamInstance = teamInstance,
	}, Team)

	return self
end

function Team:AssignPlayer(player: Player)
	self.PlayersState:Update(function(currentPlayers: {})
		table.insert(currentPlayers, player)
		player.Team = self.TeamInstance
		return currentPlayers
	end)
end

return Team
