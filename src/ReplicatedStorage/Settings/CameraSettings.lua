local CameraSettings = {
	FieldOfViews = {
		Idle = 70,
		Sprint = 85,
		Crawl = 65,
		Aim = 45,
	},

	CameraOffsets = {
		DefaultCameraOffset = Vector3.new(0, 0, 0),
		GunDefaultCameraOffset = Vector3.new(2.5, 0.8, 0),
		GunAimCameraOffset = Vector3.new(2.9, 1, 0),
		ShiftLockOffset = Vector3.new(0, 0.2, 0),
	},

	Cursors = {
		Crosshair = "rbxassetid://13574602425",
		Default = "rbxassetid://9947313248",
	},
}

return CameraSettings
