local ConflictingCharacterStates = {
	Sprint = { "Aim", "Crawl" },
	Crawl = { "Sprint" },
	Aim = { "Sprint" },
}

return ConflictingCharacterStates
