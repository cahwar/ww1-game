local ConflictingCharacterStates = {
	Sprint = { "Aim", "Crouch" },
	Crouch = { "Sprint" },
	Aim = { "Sprint" },
}

return ConflictingCharacterStates
