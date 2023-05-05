local module = {
	InitState = {
		Replicated = {
			Player = { -- PlayerGui
			},
			Global = { -- ReplicatedStorage
				EntenteTeamPlayers = {},
				AxisTeamPlayers = {},
			},
		},
		Server = { -- ServerStorage
			Player = {},
			Global = {},
		},
		Persistent = { -- DataStore
			Player = {},
			Global = {},
		},
	},
	PlaceAttributes = {},
	Badges = {},
	Products = {
		--AppPremiumPass = 999999999, example
	},
}

return module
