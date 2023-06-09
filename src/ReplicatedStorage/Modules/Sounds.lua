local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SoundsFolder = ReplicatedStorage.Common.GameParts.Sounds

local Methods = require(ReplicatedStorage.Common.Modules.Methods)

local SoundParts = Instance.new("Folder")
SoundParts.Parent = workspace
SoundParts.Name = "SoundParts"

local Sounds = {
	SoundsPlaying = {},
}

function Sounds:basePlaySound(soundReference: Sound | string, soundParent: Instance, soundSpeed: number?)
	local sound

	if typeof(soundReference) == "string" then
		sound = SoundsFolder:FindFirstChild(soundReference, true)
	else
		sound = soundReference
	end

	if not sound then
		warn("No sound provided:", soundReference or "|NULL|")
		return
	end

	if soundSpeed then
		sound.PlaybackSpeed = soundSpeed
	end
	sound = sound:Clone()
	sound.Parent = soundParent
	sound:Play()

	return sound
end

function Sounds.CreateSoundPart(worldPosition: Vector3)
	local part = Methods.CreateTemporaryPart(worldPosition)
	part.Parent = SoundParts
	part.ChildRemoved:Once(function()
		part:Destroy()
	end)
	return part
end

function Sounds:PlaySoundOnce(soundReference: Sound | string, soundParent: Instance, soundSpeed: number?)
	local sound = self:basePlaySound(soundReference, soundParent, soundSpeed)

	sound.Ended:Once(function()
		sound:Destroy()
	end)
end

function Sounds:PlaySoundLooped(
	soundReference: Sound | string,
	soundParent: Instance,
	soundTableName: string,
	soundSpeed: number?
)
	local sound = self:basePlaySound(soundReference, soundParent, soundSpeed)
	self.SoundsPlaying[soundTableName] = sound
end

function Sounds:StopSoundSmoothly(soundTableName: string, stopDuration: number)
	local sound = self.SoundsPlaying[soundTableName]
	assert(sound ~= nil, `Couldn't find sound by table name: {soundTableName}`)

	Methods.StartLerpAction(sound.Volume, 0, stopDuration, function(stepValue: number)
		sound.Volume = stepValue
	end).Promise
		:andThen(function()
			sound:Stop()
			sound:Destroy()
		end)
end

function Sounds:StopSoundNow(soundTableName: string)
	local sound = self.SoundsPlaying[soundTableName]
	assert(sound ~= nil, `Couldn't find sound by table name: {soundTableName}`)
	sound:Stop()
	sound:Destroy()
end

return Sounds
