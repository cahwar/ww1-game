local Debris = game:GetService("Debris")
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
	elseif typeof(value1) == "Vector3" then
		return (value2 - value1).Magnitude <= range
	end

	return false
end

function Methods.CreateTemporaryPart(worldPosition: Vector3)
	local part = Instance.new("Part")
	part.Position = worldPosition
	part.Size = Vector3.new(0.1, 0.1, 0.1)
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.Transparency = 1
	return part
end

function Methods.spawnParticles(particlesReference, particlesParent: BasePart)
	if typeof(particlesReference) == "string" then
		particlesReference = ReplicatedStorage.Common.GameParts.Particles:FindFirstChild(particlesReference, true)
	end

	if particlesReference and particlesReference:IsA("BasePart") then
		particlesReference = particlesReference:FindFirstChildWhichIsA("Attachment")
			or particlesReference:FindFirstChildWhichIsA("ParticleEmitter")
	end

	if not particlesReference then
		return
	end

	particlesReference = particlesReference:Clone()
	particlesReference.Parent = particlesParent

	return particlesReference
end

function Methods.EmitParticlesOnce(particlesReference, particlesParent: BasePart, emitAmount: number)
	local particles = Methods.spawnParticles(particlesReference, particlesParent)

	if not particles then
		return
	end

	if particles:IsA("ParticleEmitter") then
		particles:Emit(emitAmount)
	else
		for _, v in particles:GetDescendants() do
			if v:IsA("ParticleEmitter") then
				v:Emit(emitAmount)
			end
		end
	end

	Debris:AddItem(particles, 5)
end

function Methods.EnableParticlesEmition(particlesReference, particlesParent: BasePart, duration: number?)
	local particles = Methods.spawnParticles(particlesReference, particlesParent)

	if not particles then
		return
	end

	if particles:IsA("ParticleEmitter") then
		particles.Enabled = true
	else
		for _, v in particles:GetDescendants() do
			if v:IsA("ParticleEmitter") then
				v.Enabled = true
			end
		end
	end

	if duration then
		task.delay(duration, Methods.StopParticlesEmition, particles)
	end

	return particles
end

function Methods.StopParticlesEmition(particles: Attachment | ParticleEmitter)
	if particles:IsA("ParticleEmitter") then
		particles.Enabled = false
	else
		for _, v in particles:GetDescendants() do
			if v:IsA("ParticleEmitter") then
				v.Enabled = false
			end
		end
	end
end

return Methods
