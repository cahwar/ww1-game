local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Common.Packages.Knit)
local Trove = require(ReplicatedStorage.Common.Packages.Trove)
local Methods = require(ReplicatedStorage.Common.Modules.Methods)

local Player = Players.LocalPlayer
local HumanoidSettings = require(ReplicatedStorage.Common.Settings.HumanoidSettings)

local Settings = {
	FovTweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	SprintKeyCode = Enum.KeyCode.LeftShift,
	CrawlKeyCode = Enum.KeyCode.LeftControl,
}

local CharacterMovementController = Knit.CreateController({ Name = "CharacterMovementController" })

function CharacterMovementController:Init()
	self.character = Player.Character or Player.CharacterAdded:Wait()
	self.humanoid = self.character:WaitForChild("Humanoid")
end

function CharacterMovementController:setSpeedWithStateCheck(speedToSet: number, requiredState)
	self.humanoid.WalkSpeed = speedToSet
	task.defer(function()
		if self.CharacterStateController.CurrentMovementState == requiredState then
			self.humanoid.WalkSpeed = speedToSet
		end
	end)
end

function CharacterMovementController:getHumanoidSpeedToSet()
	local currentStateSpeed = self:GetCurrentStateSpeed()
	return currentStateSpeed
end

function CharacterMovementController:GetCurrentStateSpeed()
	return HumanoidSettings[(self.CharacterStateController.CharacterMovementState.Name or "Idle") .. "Speed"]
end

function CharacterMovementController:StopCurrentState()
	if
		self.CharacterStateController.CurrentMovementState
		== self.CharacterStateController.CharacterMovementState.Sprint
	then
		self:StopSprint()
	elseif
		self.CharacterStateController.CurrentMovementState
		== self.CharacterStateController.CharacterMovementState.Crawl
	then
		self:StopCrawl()
	end
end

function CharacterMovementController:StartSprint()
	if
		not self.CharacterStateController:TryChangeState(self.CharacterStateController.CharacterMovementState.Sprint)
	then
		return
	end

	self:StopCurrentState()

	self.sprintTrove = self.trove:Extend()
	self.sprintTrove:Add(function()
		self.CharacterStateController.CurrentMovementState = self.CharacterStateController.CharacterMovementState.Idle
		self.humanoid.WalkSpeed = self:getHumanoidSpeedToSet()
		Methods.TweenNow(
			workspace.CurrentCamera,
			{ FieldOfView = self.CameraController:GetFovFromMovementState() },
			Settings.FovTweenInfo
		)
	end)

	Methods.TweenNow(
		workspace.CurrentCamera,
		{ FieldOfView = self.CameraController:GetFovFromMovementState() },
		Settings.FovTweenInfo
	)

	self:setSpeedWithStateCheck(
		HumanoidSettings.SprintSpeed,
		self.CharacterStateController.CharacterMovementState.Sprint
	)
end

function CharacterMovementController:StopSprint()
	if self.sprintTrove then
		self.sprintTrove:Destroy()
		self.sprintTrove = nil
	end
end

function CharacterMovementController:StartCrawl()
	if not self.CharacterStateController:TryChangeState(self.CharacterStateController.CharacterMovementState.Crawl) then
		return
	end

	self:StopCurrentState()

	self.crawlTrove = self.trove:Extend()
	self.crawlTrove:Add(function()
		self.CharacterStateController.CurrentMovementState = self.CharacterStateController.CharacterMovementState.Idle
		self.humanoid.WalkSpeed = self:getHumanoidSpeedToSet()
		Methods.TweenNow(
			workspace.CurrentCamera,
			{ FieldOfView = self.CameraController:GetFovFromMovementState() },
			Settings.FovTweenInfo
		)
	end)

	Methods.TweenNow(
		workspace.CurrentCamera,
		{ FieldOfView = self.CameraController:GetFovFromMovementState() },
		Settings.FovTweenInfo
	)

	self:setSpeedWithStateCheck(HumanoidSettings.CrawlSpeed, self.CharacterStateController.CharacterMovementState.Crawl)
end

function CharacterMovementController:StopCrawl()
	if self.crawlTrove then
		self.crawlTrove:Destroy()
		self.crawlTrove = nil
	end
end

function CharacterMovementController:LaunchController()
	self:Init()
	self.trove = Trove.new()

	ContextActionService:BindAction("Sprint", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			self:StartSprint()
		elseif inputState == Enum.UserInputState.End then
			self:StopSprint()
		end

		return Enum.ContextActionResult.Pass
	end, false, Settings.SprintKeyCode)

	ContextActionService:BindAction("Crawl", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			self:StartCrawl()
		elseif inputState == Enum.UserInputState.End then
			self:StopCrawl()
		end

		return Enum.ContextActionResult.Pass
	end, false, Settings.CrawlKeyCode)
end

function CharacterMovementController:StopController()
	if self.trove then
		self.trove:Destroy()
		self.trove = nil
	end
end

function CharacterMovementController:KnitStart() end

function CharacterMovementController:KnitInit()
	self.ClientController = Knit.GetController("ClientController")
	self.CharacterStateController = Knit.GetController("CharacterStateController")
	self.CameraController = Knit.GetController("CameraController")

	self.ClientController.HumanoidSpawned:Connect(function()
		self:LaunchController()
	end)
	self.ClientController.HumanoidDied:Connect(function()
		self:StopController()
	end)
end

return CharacterMovementController
