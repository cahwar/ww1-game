local Players = game:GetService("Players")
local GunModule = {}

function GunModule.AttachGunToCharacter(character, gun: Tool)
	local bodyAttach = gun:FindFirstChild("BodyAttach", true)

	if not bodyAttach then
		return
	end

	local motor6d = character.RightHand:FindFirstChild("Weapon")
	if not motor6d then
		motor6d = Instance.new("Motor6D")
		motor6d.Name = "Weapon"
		motor6d.Parent = character.RightHand
		motor6d.Part0 = character.RightHand
	end

	motor6d.Part1 = bodyAttach
end

function GunModule._getFromCameraRaycastResult(
	fromCameraOrigin: Vector3,
	fromCameraDirection: Vector3,
	character,
	ignoreTable
)
	ignoreTable = #ignoreTable > 0 and ignoreTable or { character }

	local raycastParams = GunModule.CreateDefaultRaycastParams(ignoreTable)

	local raycastResult = workspace:Raycast(fromCameraOrigin, fromCameraDirection * 2000, raycastParams)

	if not raycastResult or not raycastResult.Instance then
		return false
	end

	local characterCFrame = character.HumanoidRootPart.CFrame
	local characterLookVector = characterCFrame.LookVector
	local toRaycastDirection = (raycastResult.Position - characterCFrame.Position).Unit

	local dotProduct = characterLookVector:Dot(toRaycastDirection)
	if dotProduct >= 0.7 then
		return raycastResult
	end

	local model = raycastResult.Instance:FindFirstAncestorWhichIsA("Model")
	table.insert(ignoreTable, model or raycastResult.Instance)

	return GunModule._getFromCameraRaycastResult(fromCameraOrigin, fromCameraDirection, character, ignoreTable)
end

function GunModule.CreateDefaultRaycastParams(ignoreTable)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = ignoreTable
	return raycastParams
end

function GunModule.GetHitRayPoints(character, gun: Tool, centerRay: Ray)
	local fromCameraOrigin = centerRay.Origin
	local fromCameraDirection = centerRay.Direction

	local fromCameraRaycastResult =
		GunModule._getFromCameraRaycastResult(fromCameraOrigin, fromCameraDirection, character, { character })

	local gunPart = gun:FindFirstChild("Muzzle", true) or gun:FindFirstChildWhichIsA("BasePart", true)
	if not gunPart then
		return
	end

	local hitSource = gunPart.Position
	local hitDirection

	if fromCameraRaycastResult then
		hitDirection = (fromCameraRaycastResult.Position - hitSource).Unit
	else
		hitDirection = fromCameraDirection
	end

	return hitSource, hitDirection
end

function GunModule.GetHitRaycastResult(character, gun: Tool, centerRay: Ray)
	local hitSource, hitDirection = GunModule.GetHitRayPoints(character, gun, centerRay)

	if not hitSource or not hitDirection then
		return
	end

	local raycastResult =
		workspace:Raycast(hitSource, hitDirection * 1000, GunModule.CreateDefaultRaycastParams({ character }))

	return raycastResult
end

function GunModule.GetToolOwnerPlayer(tool: Tool)
	if not tool.Parent then
		warn("Tool has no parent:", tool)
		return false
	end

	local player = tool.Parent:FindFirstAncestorWhichIsA("Player")

	if player then
		return player
	end

	player = Players:GetPlayerFromCharacter(tool.Parent)

	if not player then
		warn("No player from provided character:", tool.Parent)
		return false
	end

	return player
end

function GunModule.GetToolOwnerCharacter(tool: Tool)
	if not tool.Parent then
		warn("Tool has no parent:", tool)
		return false
	end

	if tool.Parent:IsA("Model") then
		return tool.Parent
	end

	local player = tool.Parent:FindFirstAncestorWhichIsA("Player")

	if not player then
		warn("Can't get character from tool:", tool)
		return false
	end

	return player.Character
end

return GunModule
