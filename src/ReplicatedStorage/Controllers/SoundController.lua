local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Common.Packages.Knit)
local Sounds = require(ReplicatedStorage.Common.Modules.Sounds)

local SoundController = Knit.CreateController({ Name = "SoundController" })

function SoundController:KnitStart()
	self.SoundService.PlaySoundOnce:Connect(function(soundReference: string | Sound, soundParent: Instance)
		Sounds:PlaySoundOnce(soundReference, soundParent)
	end)
end

function SoundController:KnitInit()
	self.SoundService = Knit.GetService("SoundService")
end

return SoundController
