local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Promise = require(ReplicatedStorage.Common.Packages.Promise)

local LerpAction = {}
LerpAction.__index = LerpAction

function LerpAction.new(startValue: number, finalValue: number, lerpDuration: number, action: (number) -> nil)
	local self = setmetatable({
		loopStep = (finalValue - startValue) / lerpDuration / 60,
		stopped = false,
		startValue = startValue,
		finalValue = finalValue,
		action = action,
	}, LerpAction)

	self:_Start()

	return self
end

function LerpAction:_Start()
	self.Promise = Promise.new(function(resolve)
		for step = self.startValue, self.finalValue, self.loopStep do
			if self.stopped == true then
				break
			end

			self.action(step)

			task.wait()
		end

		if not self.stopped then
			self.action(self.finalValue)
		end

		resolve()
	end)
end

function LerpAction:Stop()
	if self.stopped then
		return
	end
	self.Promise:cancel()
	self.stopped = true
end

return LerpAction
