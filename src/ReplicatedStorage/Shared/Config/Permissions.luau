--!strict

local RunService = game:GetService("RunService")

export type TierName = "Owner" | "Dev" | "Tester" | "Player"

local Permissions = {}

Permissions.Tiers = {
	Player = 0,
	Tester = 10,
	Dev = 20,
	Owner = 30,
}

Permissions.GroupTiers = {
	NexusPlayer = "Player",
	NexusTester = "Tester",
	NexusDev = "Dev",
	NexusOwner = "Owner",
	DefaultUtil = "Player",
	UserAlias = "Player",
} :: { [string]: TierName }

function Permissions.getTierRank(tier: string): number
	return Permissions.Tiers[tier] or Permissions.Tiers.Player
end

function Permissions.getRequiredTierForGroup(group: string?): TierName
	if group == nil then
		return "Player"
	end

	return Permissions.GroupTiers[group] or "Player"
end

function Permissions.getPlayerTier(player: Player?): TierName
	if player == nil then
		return "Owner"
	end

	if RunService:IsStudio() then
		return "Owner"
	end

	return "Player"
end

function Permissions.canRun(player: Player?, requiredTier: string): (boolean, string?)
	local actualTier = Permissions.getPlayerTier(player)
	local actualRank = Permissions.getTierRank(actualTier)
	local requiredRank = Permissions.getTierRank(requiredTier)

	if actualRank < requiredRank then
		return false,
			("Permission denied. Required tier: %s. Your tier: %s."):format(
				requiredTier,
				actualTier
			)
	end

	return true, nil
end

return Permissions
