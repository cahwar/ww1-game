local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnumList = require(ReplicatedStorage.Common.Packages.EnumList)

local GunsSettings = {}

GunsSettings.General = {
	DisplayHitPoint = true,
	Acceleration = Vector3.new(0, -5, 0),
}

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
			RackGun = "RifleBetweenShotReload",
			Reload = "RifleReload",
		},

		Sounds = {
			Reload = nil,
			Shot = "GunShot_2",
			EmptyClick = "EmptyClick_1",
			BetweenShotReload = nil,
			GeneralReload = "RifleReload",
		},

		Effects = {
			Shot = "SimpleShotEffect",
		},

		PossibleFireRates = {
			GunsSettings.FireRates.Semi,
			GunsSettings.FireRates.Auto,
		},

		NoAimShakeCalculations = {
			SinHeight = 20,
			CosHeight = 3,
			CosSpeed = 5,
			SinSpeed = 35,
		},

		AimShakeCalculations = {
			SinSpeed = 36,
			CosSpeed = 32,
			SinHeight = 15,
			CosHeight = 5.5,
		},

		Stats = {
			ShotDamage = 10,
			ClipsStorage = 5,
			ShotCooldown = 0.2,
			ClipSize = 10,
			ReloadTime = 4,
		},
	},
}

return GunsSettings
