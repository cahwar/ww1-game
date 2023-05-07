local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Common.Packages.Knit)
local CameraShake = require(ReplicatedStorage.Common.Classes.CameraShake)

local CameraController = Knit.CreateController({ Name = "CameraController" })

function CameraController:KnitStart() end

function CameraController:KnitInit() end

return CameraController
