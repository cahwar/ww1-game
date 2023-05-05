local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Common.Packages.Knit)
local GuiModule = require(ReplicatedStorage.Common.Modules.GuiModule)
local Trove = require(ReplicatedStorage.Common.Packages.Trove)

local TeamSelectionController = Knit.CreateController({ Name = "TeamSelectionController" })

function TeamSelectionController:Init()
	self.player = game:GetService("Players").LocalPlayer
	self.teamSelectionGui = GuiModule.FindGui(self.player, "TeamSelection")
end

function TeamSelectionController:LoadTeamSelector(teamInfo)
	local teamsList = self.teamSelectionGui.MainFrame.TeamsFrame.Inner
	local prefab = teamsList.Prefab

	local selector = prefab:Clone()
	selector.Visible = true
	selector.Parent = teamsList
	selector.TeamName.Text = teamInfo.Name
	selector.DeathsCount.Text = `Deaths: {teamInfo.Deaths}`
	selector.SoldiersCount.Text = `Soldiers: {teamInfo.PlayersAmount}`
end

function TeamSelectionController:StartTeamSelection(teams)
	self.teamSelectionTrove = Trove.new()
	self.teamSelectionGui.Enabled = true

	for _, v in teams do
		self:LoadTeamSelector(v)
	end

	self.teamSelectionTrove:Add(function()
		self.teamSelectionGui.Enabled = false
	end)
end

function TeamSelectionController:StopTeamSelection()
	if self.teamSelectionTrove then
		self.teamSelectionTrove:Destroy()
		self.teamSelectionTrove = nil
	end
end

function TeamSelectionController:LaunchController()
	self:Init()
end

function TeamSelectionController:KnitInit()
	self:Init()
	self.ClientController = Knit.GetController("ClientController")
	self.ClientController.HumanoidSpawned:Connect(function()
		self:LaunchController()
	end)

	self.TeamsService = Knit.GetService("TeamsService")
	self.TeamsService.StartTeamSelection:Connect(function(...)
		self:StartTeamSelection(...)
	end)
end

return TeamSelectionController
