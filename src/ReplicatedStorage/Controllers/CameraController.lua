local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Common.Packages.Knit)
local CameraShake = require(ReplicatedStorage.Common.Classes.CameraShake)

local CameraController = Knit.CreateController({ Name = "CameraController" })

function CameraController:KnitStart()
	-- CameraShake.new(
	-- 	{ SinSpeed = 5, SinHeight = 5, CosSpeed = 5, CosHeight = 15 },
	-- 	{ RotationAxis = CameraShake.RotationAxis.XZ }
	-- )
end

function CameraController:KnitInit() end

return CameraController
