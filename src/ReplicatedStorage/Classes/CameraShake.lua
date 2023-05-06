local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TriWave = require(ReplicatedStorage.Common.Classes.TriWave)

local CameraShake = {}
CameraShake.__index = CameraShake

function CameraShake.new(calculations: TriWave.TriWaveCalculations)
	local self = setmetatable({
		triWave = TriWave.new(calculations),
	}, CameraShake)

	local camera = workspace.CurrentCamera

	self.triWave:ConnectAction(function(sinWave: number, cosWave: number)
		sinWave /= math.rad(sinWave / 10)
		cosWave /= math.rad(cosWave / 10)
		local angles = CFrame.Angles(sinWave, 0, cosWave)
		camera.CFrame = camera.CFrame * angles
	end)

	self.triWave:Start()

	return self
end

function CameraShake:DestroySmoothly(stopDuration: number)
	self.triWave:DestroySmoothly(stopDuration)
end

function CameraShake:Destroy()
	self.triWave:Destroy()
end

return CameraShake
