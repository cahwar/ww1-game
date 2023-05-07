local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TriWave = require(ReplicatedStorage.Common.Classes.TriWave)

local Camera = workspace.CurrentCamera

local CameraShake = {}
CameraShake.__index = CameraShake

function CameraShake.new(calculations: TriWave.TriWaveCalculations)
	local self = setmetatable({
		triWave = TriWave.new(calculations),
	}, CameraShake)

	self.triWave:ConnectAction(function(sinWave: number, cosWave: number)
		sinWave = math.rad(sinWave / 10)
		cosWave = math.rad(cosWave / 10)

		local angle = CFrame.Angles(sinWave, 0, cosWave)
		Camera.CFrame = Camera.CFrame * angle
	end)

	self.triWave:StartRenderStepped()

	return self
end

function CameraShake:DestroySmoothly(stopDuration: number)
	self.triWave:DestroySmoothly(stopDuration)
end

function CameraShake:Destroy()
	self.triWave:Destroy()
end

return CameraShake
