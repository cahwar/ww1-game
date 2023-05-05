local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Common.Packages.Knit)
local Trove = require(ReplicatedStorage.Common.Packages.Trove)
local GuiModule = require(ReplicatedStorage.Common.Modules.GuiModule)
local Cooldown = require(ReplicatedStorage.Common.Modules.Cooldown)

local TeamSelectionController = Knit.CreateController({ Name = "TeamSelectionController" })

function TeamSelectionController:Init()
	self.player = game:GetService("Players").LocalPlayer
	self.teamSelectionGui = GuiModule.FindGui(self.player, "TeamSelection")
	self.teamsList = self.teamSelectionGui.MainFrame.TeamsFrame.Inner
end

function TeamSelectionController:UpdateTeamSelector(selector, teamInfo)
	selector.TeamName.Text = teamInfo.Name
	selector.DeathsCount.Text = `Deaths: {teamInfo.Deaths}`
	selector.SoldiersCount.Text = `Soldiers: {teamInfo.PlayersAmount}`
end

function TeamSelectionController:TrySelectTeam(teamName)
	local selectionSuccess = self.TeamsService:SelectTeam(teamName):await()

	if not selectionSuccess then
		warn("Selection fail")
	end
end

function TeamSelectionController:CreateTeamSelector(teamInfo)
	local prefab = self.teamsList.Prefab

	local selector = prefab:Clone()
	selector.Visible = true
	selector.Parent = self.teamsList
	selector.Name = teamInfo.Name

	self.teamSelectionTrove:Connect(selector.MouseButton1Click, function()
		if self.TeamSelectCooldown:IsActive() then
			return
		end

		self.TeamSelectCooldown:SetActive(2)
		self:TrySelectTeam(teamInfo.Name)
	end)

	self:UpdateTeamSelector(selector, teamInfo)
end

function TeamSelectionController:StartTeamSelection(teams)
	self.teamSelectionTrove = Trove.new()
	self.teamSelectionGui.Enabled = true

	for _, v in teams do
		self:CreateTeamSelector(v)
	end

	self.teamSelectionTrove:Connect(self.TeamsService.TeamChanged, function(teamInfo)
		local selector = self.teamsList:FindFirstChild(teamInfo.Name)
		if not selector then
			error("No team selector UI by this team's name:", teamInfo.Name or "|NULL|")
		end
		self:UpdateTeamSelector(selector, teamInfo)
	end)

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

	self.TeamSelectCooldown = Cooldown.new()

	self.ClientController = Knit.GetController("ClientController")
	self.ClientController.HumanoidSpawned:Connect(function()
		self:LaunchController()
	end)

	self.TeamsService = Knit.GetService("TeamsService")
	self.TeamsService.TeamSelectionStarted:Connect(function(...)
		self:StartTeamSelection(...)
	end)

	self.TeamsService.TeamSelectionStopped:Connect(function()
		self:StopTeamSelection()
	end)
end

return TeamSelectionController
