local CameraSettings = {
	FieldOfViews = {
		Idle = 70,
		Sprint = 85,
		Crouch = 65,
		Aim = 45,
	},

	CameraOffsets = {
		DefaultCameraOffset = Vector3.new(0, 0, 0),
		GunDefaultCameraOffset = Vector3.new(2.5, 0.8, 0),
		GunAimCameraOffset = Vector3.new(2.9, 1, 0),
		ShiftLockOffset = Vector3.new(0, 0.2, 0),
	},
}

return CameraSettings
