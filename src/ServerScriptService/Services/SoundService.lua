local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Common.Packages.Knit)

local SoundService = Knit.CreateService({
	Name = "SoundService",
	Client = {
		PlaySoundOnce = Knit.CreateSignal(),
	},
})

function SoundService:PlaySoundOnceFor(
	playersTable: { [any?]: Player },
	soundReference: string | Sound,
	soundParent: Instance
)
	self.Client.PlaySoundOnce:FireFor(playersTable, soundReference, soundParent)
end

return SoundService
