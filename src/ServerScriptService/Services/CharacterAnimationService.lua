local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Common.Packages.Knit)

local CharacterAnimationService = Knit.CreateService({
	Name = "CharacterAnimationService",
	Client = {
		ReplicateLookFollower = Knit.CreateSignal(),
	},
})

function CharacterAnimationService.Client:ReplicateCharacterLookFollower(player: Player, cFrameToAdd: CFrame)
	local character = player.Character
	if not character or character.Humanoid:GetState() == Enum.HumanoidStateType.Dead then
		return
	end

	local waistCFrame = character:FindFirstChild("Waist", true).C1 * cFrameToAdd

	self.ReplicateLookFollower:FireExcept(player, character, waistCFrame)
end

function CharacterAnimationService:KnitStart() end

function CharacterAnimationService:KnitInit() end

return CharacterAnimationService
