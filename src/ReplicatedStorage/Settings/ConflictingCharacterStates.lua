local ConflictingCharacterStates = {
	Sprint = { "Aim", "Crawl", "Shot" },
	Crawl = { "Sprint" },
	Aim = { "Sprint" },
	Shot = { "Sprint" },
}

return ConflictingCharacterStates
