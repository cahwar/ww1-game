local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CameraSettings = require(ReplicatedStorage.Common.Settings.CameraSettings)
local HumanoidSettings = require(ReplicatedStorage.Common.Settings.HumanoidSettings)

local StatesSettings = {
	Default = {
		FieldOfView = CameraSettings.FieldOfViews.Idle,
		Speed = HumanoidSettings.IdleSpeed,
		Animations = {
			Idle = { Name = "PlayerIdle", Speed = 1.2 },
			Move = { Name = "PlayerWalk", Speed = 1.45 },
		},
	},

	Crawl = {
		FieldOfView = CameraSettings.FieldOfViews.Crawl,
		Speed = HumanoidSettings.CrawlSpeed,
		Animations = {
			Idle = { Name = "PlayerCrawlIdle", Speed = 1 },
			Move = { Name = "PlayerCrawlWalk", Speed = 1.45 },
		},
	},

	Sprint = {
		FieldOfView = CameraSettings.FieldOfViews.Sprint,
		Speed = HumanoidSettings.SprintSpeed,
		Animations = {
			Move = { Name = "PlayerRun", Speed = 1.3 },
		},
	},

	Aim = {
		FieldOfView = CameraSettings.FieldOfViews.Aim,
		SpeedMultipler = HumanoidSettings.AimSpeedMultipler,
	},
}

return StatesSettings
