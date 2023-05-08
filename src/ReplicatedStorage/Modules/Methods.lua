local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LerpAction = require(ReplicatedStorage.Common.Classes.LerpAction)

local Methods = {}

function Methods.StartLerpAction(startValue: number, finalValue: number, lerpDuration: number, action: (number) -> nil)
	return LerpAction.new(startValue, finalValue, lerpDuration, action)
end

function Methods.LerpValue(valueA, valueB, ratio)
	return valueA * (1 - ratio) + valueB * ratio
end

return Methods
