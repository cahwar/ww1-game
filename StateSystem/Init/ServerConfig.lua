local module = {
	InitState = {
		Replicated = {
			Player = { -- PlayerGui
				--admin command
				ShowTestingButton = false,
				TestingCommandsResetPlayer = false,
				TestingCommandsSuperJump = false,
				TestingCommandsSuperSpeed = false,
				TestingCommandsGet1000SMoney = false,
				TestingCommandsSet0SMoney = false,
				SoundsOn = true,
				MusicOn = true,
				-----------------
				StopPlayer = false,
				ClothNumber = 0,
			},
			Global = { -- ReplicatedStorage
				
			},
		},
		Server = { -- ServerStorage
			Player = {
				
			},
			Global = {
				
			},
		},
		Persistent = { -- DataStore
			Player = {
				Point = 0,
				FirstTimePlay = true,
				
				ShoroomClothes = {},
				--cloth
				pants = 0,
				shirt = 0,
				
				FirstTypeEasterEggsCollected = {},
				FirstTypeEasterEggsCompleted = false,
				
				SecondTypeEasterEggsCollected = {},
				SecondTypeEasterEggsCompleted = false,
				
				NpcTypeEasterEggsCollected = {},
				NpcTypeEasterEggsCompleted = false,
				
				PlayerPromosToGet = {}, -- этот  стейт используется для обработки ситуаций, когда игрок вышел, находясь
				--..в очереди на получение промокода и свой промик так и не получил. При заходе он встанет в очередь снова.
			},
			Global = {
				PointsTable = {},
				GivenPromosType6 = {},
				ClaimedFirstTypeEasterEggsPromos = {},
				ClaimedSecondTypeEasterEggsPromos = {},
				ClaimedNpcPromos = {},
				
				--Dev
				BanPlayers = {},
			},
		},
	},
	PlaceAttributes = {},
	Badges = {
	},
	Products = {
		--AppPremiumPass = 999999999, example
	},
}

return module