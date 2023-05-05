local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Knit = require(ReplicatedStorage.Common.Packages.Knit)

local GameTeam = require(ServerScriptService.Server.Classes.Team)

local TeamsService = Knit.CreateService({
	Name = "TeamsService",
	Client = {
		TeamSelectionStarted = Knit.CreateSignal(),
		TeamSelectionStopped = Knit.CreateSignal(),
		TeamChanged = Knit.CreateSignal(),
	},

	GameTeams = {
		Entente = GameTeam.new({
			Color = BrickColor.Blue(),
			Name = "Entente",
			PlayersStatePath = "Replicated.Global.EntenteTeamPlayers",
		}),

		Axis = GameTeam.new({
			Color = BrickColor.Red(),
			Name = "Axis",
			PlayersStatePath = "Replicated.Global.AxisTeamPlayers",
		}),
	},
})

function TeamsService.Client:SelectTeam(player, teamName: string)
	if not player:GetAttribute("IsPickingTeam") then
		warn("Player is not selecting team at the moment:", player.Name)
		return
	end

	local selectSuccess = self.Server:SetPlayerTeam(player, teamName)

	if selectSuccess then
		self.Server:StopTeamSelection(player)
	end

	return selectSuccess
end

function TeamsService:SetPlayerTeam(player, teamName: string)
	local gameTeam = self.GameTeams[teamName]

	if not gameTeam then
		error(`No game team by this name: {teamName}`)
	end

	gameTeam:AssignPlayer(player)

	return true
end

function TeamsService:PackClientTeamInfo(team)
	return { Deaths = team.Deaths, Name = team.Name, PlayersAmount = #team.PlayersState:Get() }
end

function TeamsService:StopTeamSelection(player)
	if not player:GetAttribute("IsPickingTeam") then
		return
	end
	player:SetAttribute("IsPickingTeam", nil)
	self.Client.TeamSelectionStopped:Fire(player)
end

function TeamsService:StartTeamSelection(player)
	if player:GetAttribute("IsPickingTeam") then
		return
	end

	player:SetAttribute("IsPickingTeam", true)

	local teamsInfo = {}
	for _, v in self.GameTeams do
		table.insert(teamsInfo, self:PackClientTeamInfo(v))
	end
	self.Client.TeamSelectionStarted:Fire(player, teamsInfo)
end

function TeamsService:OnPlayerAdded(player)
	if self.GameService:GetRoundState() == self.GameService.RoundState.Started then
		self:StartTeamSelection(player)
	end
end

function TeamsService:OnTeamChanged(team)
	self.Client.TeamChanged:FireAll(self:PackClientTeamInfo(team))
end

function TeamsService:KnitStart()
	for _, v in game.Players:GetPlayers() do
		self:OnPlayerAdded(v)
	end

	game.Players.PlayerAdded:Connect(function(player)
		self:OnPlayerAdded(player)
	end)
end

function TeamsService:KnitInit()
	self.GameService = Knit.GetService("GameService")

	for _, v in self.GameTeams do
		v.TeamChanged:Connect(function()
			self:OnTeamChanged(v)
		end)
	end
end

return TeamsService
