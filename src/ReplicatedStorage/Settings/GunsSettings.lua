local GunsSettings = {}

GunsSettings.Guns = {
	Rifle = {
		Animations = {
			Idle = "RifleIdle",
			Aim = "RifleAim",
			AimShot = "RifleAimShot",
			NoAimShot = "RifleNoAimShot",
		},

		Sounds = {
			Shot = "GunShot_2",
		},

		Effects = {
			Shot = "SimpleShotEffect",
		},

		ShotCooldown = 0.7,

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
