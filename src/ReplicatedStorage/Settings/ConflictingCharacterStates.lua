local ConflictingCharacterStates = {
	Sprint = { "Aim", "Crawl", "Shot", "Reload" },
	Crawl = { "Sprint" },
	Aim = { "Sprint", "Reload" },
	Shot = { "Sprint", "Reload" },
	Reload = { "Sprint", "Aim", "Shot" },
}

return ConflictingCharacterStates
