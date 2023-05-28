local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnumList = require(ReplicatedStorage.Common.Packages.EnumList)

local GunsSettings = {}

GunsSettings.FireRates = EnumList.new("FireRates", {
	"Semi",
	"Auto",
})

GunsSettings.Guns = {
	Rifle = {
		Animations = {
			Idle = "RifleIdle",
			Aim = "RifleAim",
			AimShot = "RifleAimShot",
			NoAimShot = "RifleNoAimShot",
			BetweenShotReload = "RifleBetweenShotReload",
		},

		Sounds = {
			Shot = "GunShot_2",
			BetweenShotReload = nil,
		},

		Effects = {
			Shot = "SimpleShotEffect",
		},

		PossibleFireRates = {
			GunsSettings.FireRates.Semi,
			GunsSettings.FireRates.Auto,
		},

		ShotCooldown = 0.2,

		NoAimShakeCalculations = {
			SinHeight = 45,
			CosHeight = 3,
			CosSpeed = 5,
			SinSpeed = 35,
		},

		AimShakeCalculations = {
			SinSpeed = 26,
			CosSpeed = 16,
			SinHeight = 24,
			CosHeight = 5.5,
		},
	},
}

return GunsSettings
