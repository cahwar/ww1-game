local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LerpAction = require(ReplicatedStorage.Common.Classes.LerpAction)
local Promise = require(ReplicatedStorage.Common.Packages.Promise)

local Methods = {}

function Methods.StartLerpAction(startValue: number, finalValue: number, lerpDuration: number, action: (number) -> nil)
	return LerpAction.new(startValue, finalValue, lerpDuration, action)
end

function Methods.LerpValue(valueA, valueB, ratio)
	return valueA * (1 - ratio) + valueB * ratio
end

function Methods.CreateTween(tweenObject, tweenPoint, tweenInfo)
	if not tweenInfo then
		tweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	end

	local tween = TweenService:Create(tweenObject, tweenInfo, tweenPoint)

	return {
		Promise = Promise.new(function(resolve)
			tween.Completed:Once(resolve)
		end),

		Tween = tween,
	}
end

function Methods.TweenNow(tweenObject, tweenPoint, tweenInfo)
	local tweenTable = Methods.CreateTween(tweenObject, tweenPoint, tweenInfo)
	tweenTable.Tween:Play()
	return tweenTable
end

function Methods.Approximately(value1, value2, range: number?)
	assert(typeof(value1) == typeof(value2), "Values have different types")

	if typeof(value1) == "number" then
		return math.abs(value2 - value1) <= range
	end
end

return Methods
