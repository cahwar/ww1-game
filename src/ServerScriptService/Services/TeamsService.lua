local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Knit = require(ReplicatedStorage.Common.Packages.Knit)

local GameTeam = require(ServerScriptService.Server.Classes.Team)

local TeamsService = Knit.CreateService({
	Name = "TeamsService",
	Client = {
		StartTeamSelection = Knit.CreateSignal(),
		TeamInfoChanged = Knit.CreateSignal(),
	},

	GameTeams = {
		EntenteTeam = GameTeam.new({
			Color = BrickColor.Blue(),
			Name = "Entente",
			PlayersStatePath = "Replicated.Global.EntenteTeamPlayers",
		}),

		AxisTeam = GameTeam.new({
			Color = BrickColor.Red(),
			Name = "Axis",
			PlayersStatePath = "Replicated.Global.AxisTeamPlayers",
		}),
	},
})

function TeamsService:SetPlayerTeam(player, teamName: string)
	local gameTeam = self.GameTeams[teamName]

	if not gameTeam then
		error(`No game team by this name: {teamName}`)
	end

	gameTeam:AssignPlayer(player)
end

function TeamsService:PackClientTeamInfo(team)
	return { Deaths = team.Deaths, Name = team.Name, PlayersAmount = #team.PlayersState:Get() }
end

function TeamsService:OnPlayerAdded(player)
	local teamsInfo = {}
	for _, v in self.GameTeams do
		table.insert(teamsInfo, self:PackClientTeamInfo(v))
	end
	self.Client.StartTeamSelection:Fire(player, teamsInfo)
end

function TeamsService:KnitStart()
	for _, v in game.Players:GetPlayers() do
		self:OnPlayerAdded(v)
	end

	game.Players.PlayerAdded:Connect(function(player)
		self:OnPlayerAdded(player)
	end)
end

function TeamsService:KnitInit() end

return TeamsService
