local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Common.Packages.Knit)
local CameraShake = require(ReplicatedStorage.Common.Classes.CameraShake)

local CameraController = Knit.CreateController({ Name = "CameraController" })

function CameraController:KnitStart()
	CameraShake.new({ SinSpeed = 10, SinHeight = 0, CosSpeed = 10, CosHeight = 5 })
end

function CameraController:KnitInit() end

return CameraController
