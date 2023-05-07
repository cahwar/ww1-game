local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TriWave = require(ReplicatedStorage.Common.Classes.TriWave)
local EnumList = require(ReplicatedStorage.Common.Packages.EnumList)

local Camera = workspace.CurrentCamera
local RotationAxis = EnumList.new("RotationAxis", {
	"XY",
	"XZ",
	"YZ",
	"XYZ",
})

export type ShakeOptions = { RotationAxis: typeof(RotationAxis) }

local CameraShake = {
	RotationAxis = RotationAxis,
}

CameraShake.__index = CameraShake

function CameraShake:_GetAngle(sinWave: number, cosWave: number)
	if self.shakeOptions.RotationAxis == RotationAxis.XY then
		return CFrame.Angles(sinWave, cosWave, 0)
	elseif self.shakeOptions.RotationAxis == RotationAxis.XZ then
		return CFrame.Angles(sinWave, 0, cosWave)
	elseif self.shakeOptions.RotationAxis == RotationAxis.YZ then
		return CFrame.Angles(0, sinWave, cosWave)
	elseif self.shakeOptions.RotationAxis == RotationAxis.XYZ then
		return CFrame.Angles(sinWave, cosWave, sinWave)
	end

	return CFrame.Angles(sinWave, cosWave, 0)
end

function CameraShake._new(shakeOptions: ShakeOptions)
	local self = setmetatable({
		shakeOptions = shakeOptions,
	}, CameraShake)

	return self
end

function CameraShake:_StartShake()
	self.triWave:ConnectAction(function(sinWave: number, cosWave: number)
		sinWave = math.rad(sinWave / 10)
		cosWave = math.rad(cosWave / 10)
		Camera.CFrame = Camera.CFrame * self:_GetAngle(sinWave, cosWave)
	end)

	self.triWave:StartRenderStepped()
end

function CameraShake.fromDynamicCalculations(
	shakeOptions: ShakeOptions,
	calculationFunction: () -> TriWave.TriWaveCalculations
)
	local self = CameraShake._new(shakeOptions)
	self.triWave = TriWave.fromDynamicCalculations(calculationFunction)
	self:_StartShake()
	return self
end

function CameraShake.fromStaticCalculations(shakeOptions: ShakeOptions, calculations: TriWave.TriWaveCalculations)
	local self = CameraShake._new(shakeOptions)
	self.triWave = TriWave.fromStaticCalculations(calculations)
	self:_StartShake()
	return self
end

function CameraShake:DestroySmoothly(stopDuration: number)
	self.triWave:DestroySmoothly(stopDuration)
end

function CameraShake:Destroy()
	self.triWave:Destroy()
end

return CameraShake
