local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Trove = require(ReplicatedStorage.Common.Packages.Trove)
local Methods = require(ReplicatedStorage.Common.Modules.Methods)
local Promise = require(ReplicatedStorage.Common.Packages.Promise)
local EnumList = require(ReplicatedStorage.Common.Packages.EnumList)

local TriWaveType = EnumList.new("TriWaveType", {
	"Dynamic",
	"Static",
})

local TriWave = {}
TriWave.__index = TriWave

export type TriWaveCalculations = { SinSpeed: number, SinHeight: number, CosSpeed: number, CosHeight: number }

function TriWave._new()
	local self = setmetatable({
		trove = Trove.new(),
		actions = {},

		heightMultiplers = { sin = 1, cos = 1 },
		intensityMultiplers = { sin = 1, cos = 1 },
	}, TriWave)
	return self
end

function TriWave.fromDynamicCalculations(calculationFunction: () -> TriWaveCalculations)
	local self = TriWave._new()
	self.calculationFunction = calculationFunction
	self.triWaveType = TriWaveType.Dynamic
	return self
end

function TriWave.fromStaticCalculations(calculations: TriWaveCalculations)
	local self = TriWave._new()
	self.calculations = calculations
	self.triWaveType = TriWaveType.Static
	return self
end

function TriWave:_GetSinWave()
	local calculations = self.triWaveType == TriWaveType.Dynamic and self.calculationFunction() or self.calculations
	return math.sin(tick() * (calculations.SinSpeed * self.intensityMultiplers.sin))
		* (calculations.SinHeight * self.heightMultiplers.sin)
end

function TriWave:_GetCosWave()
	local calculations = self.triWaveType == TriWaveType.Dynamic and self.calculationFunction() or self.calculations
	return math.cos(tick() * (calculations.CosSpeed * self.intensityMultiplers.cos))
		* (calculations.CosHeight * self.heightMultiplers.cos)
end

function TriWave:ConnectAction(action: (number, number) -> nil)
	local randomId = math.random(1, math.pow(10, 9))
	self.actions[randomId] = action
	return randomId
end

function TriWave:DisconnectAction(actionId: number)
	self.actions[actionId] = nil
end

function TriWave:_BaseStart()
	if self.Started then
		warn("TriWave has already been started\n Stopping")
		self.processTrove:Destroy()
	end

	self.processTrove = self.trove:Extend()
end

function TriWave:_ProcessAction()
	self.SinWave = self:_GetSinWave()
	self.CosWave = self:_GetCosWave()

	for _, v in self.actions do
		v(self.SinWave, self.CosWave)
	end
end

function TriWave:StartHeartbeat()
	self:_BaseStart()
	self.processTrove:Connect(RunService.Heartbeat, function()
		self:_ProcessAction()
	end)
end

function TriWave:StartRenderStepped()
	self:_BaseStart()
	self.processTrove:Connect(RunService.RenderStepped, function()
		self:_ProcessAction()
	end)
end

function TriWave:DestroySmoothly(stopDuration: number)
	if not stopDuration then
		warn("No stop duration passed, setting to defaults")
		stopDuration = 0.4
	end

	local sinStopPromise = Methods.StartLerpAction(self.heightMultiplers.sin, 0, stopDuration, function(step: number)
		self.heightMultiplers.sin = step
	end).Promise

	local cosStopPromise = Methods.StartLerpAction(self.heightMultiplers.cos, 0, stopDuration, function(step: number)
		self.heightMultiplers.cos = step
	end).Promise

	Promise.allSettled({ sinStopPromise, cosStopPromise }):andThenCall(self.Destroy, self)
end

function TriWave:Destroy()
	if self.trove then
		self.trove:Destroy()
	end
end

return TriWave
