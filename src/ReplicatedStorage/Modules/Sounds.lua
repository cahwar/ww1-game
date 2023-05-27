local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SoundsFolder = ReplicatedStorage.Common.GameParts.Sounds

local Methods = require(ReplicatedStorage.Common.Modules.Methods)

local SoundParts = Instance.new("Folder")
SoundParts.Parent = workspace
SoundParts.Name = "SoundParts"

local Sounds = {
	SoundsPlaying = {},
}

function Sounds:basePlaySound(soundReference: Sound | string, soundParent: Instance)
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

	sound = sound:Clone()
	sound.Parent = soundParent
	sound:Play()

	return sound
end

function Sounds.CreateSoundPart(worldPosition: Vector3)
	local part = Instance.new("Part")
	part.ChildRemoved:Once(function()
		part:Destroy()
	end)
	part.Position = worldPosition
	part.Size = Vector3.new(0.1, 0.1, 0.1)
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Parent = SoundParts
	return part
end

function Sounds:PlaySoundOnce(soundReference: Sound | string, soundParent: Instance)
	local sound = self:basePlaySound(soundReference, soundParent)
	sound.Ended:Once(function()
		sound:Destroy()
	end)
end

function Sounds:PlaySoundLooped(soundReference: Sound | string, soundParent: Instance, soundTableName: string)
	local sound = self:basePlaySound(soundReference, soundParent)
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
