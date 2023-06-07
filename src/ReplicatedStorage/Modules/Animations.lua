local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameParts = ReplicatedStorage.Common.GameParts

local Animations = {
	AnimationsInfo = {},
}

function Animations.GetAnimation(animationIndex: Animation | string)
	local animation

	if typeof(animationIndex) == "string" then
		animation = GameParts.Animations:FindFirstChild(animationIndex, true)
		if not animation then
			warn(`No animation found by index: {animationIndex or "|NULL|"}`)
		end
	else
		animation = animationIndex
	end

	return animation
end

function Animations:LoadAnimation(target: Instance, animationIndex: Animation | string)
	local humanoid = target:WaitForChild("Humanoid", 5)

	if not humanoid then
		warn("No humanoid to load the animation for:", target or "|NULL TARGET|")
		return
	end

	if not self.AnimationsInfo[target] then
		self.AnimationsInfo[target] = {}
	end

	local animation: Animation = nil

	if typeof(animationIndex) == "string" then
		animation = GameParts.Animations:FindFirstChild(animationIndex, true)
		if not animation then
			warn(`No animation found by index: {animationIndex or "|NULL|"}`)
			return
		end
	else
		animation = animationIndex
	end

	local animationInfo = {
		Track = humanoid:LoadAnimation(animation),
	}

	self.AnimationsInfo[target][animation.Name] = animationInfo

	return animationInfo
end

function Animations:LoadAnimationsPack(target: Instance, animationsIndexes: { [any?]: Animation | string })
	for _, v in animationsIndexes do
		self:LoadAnimation(target, v)
	end
end

-- // animationIndex - animation itself or it's name
function Animations:GetAnimationInfo(target: Instance, animationIndex: Animation | string)
	local animationsInfo = self.AnimationsInfo[target]

	if not animationsInfo or not animationsInfo[animationIndex] then
		return self:LoadAnimation(target, animationIndex)
	end

	return animationsInfo[animationIndex]
end

function Animations:PlayAnimation(
	target: Instance,
	animationIndex: Animation | string,
	fadeTime: number?,
	playbackSpeed: number?,
	eventsHandlers: { [string]: () -> nil }?
)
	local animationInfo = self:GetAnimationInfo(target, animationIndex)
	if not animationInfo then
		return
	end

	if eventsHandlers then
		for event, handler in eventsHandlers do
			animationInfo.Track:GetMarkerReachedSignal(event):Once(handler)
		end
	end

	animationInfo.Track:Play(fadeTime)

	if playbackSpeed then
		animationInfo.Track:AdjustSpeed(playbackSpeed)
	end
end

function Animations:StopAnimation(target: Instance, animationIndex: Animation | string, fadeTime: number?)
	local animationInfo = self:GetAnimationInfo(target, animationIndex)

	if not animationInfo then
		return
	end

	animationInfo.Track:Stop(fadeTime)
end

return Animations
