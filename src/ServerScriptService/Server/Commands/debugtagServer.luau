--!strict

local CollectionService = game:GetService("CollectionService")

return function(_, targetPlayer: Player, tagName: string, enabled: boolean?): string
	local character = targetPlayer.Character
	if character == nil then
		return ("Player %s has no character."):format(targetPlayer.Name)
	end

	local shouldEnable = if enabled == nil then true else enabled
	if shouldEnable then
		CollectionService:AddTag(character, tagName)
		return ("Added tag %q to %s."):format(tagName, targetPlayer.Name)
	end

	CollectionService:RemoveTag(character, tagName)
	return ("Removed tag %q from %s."):format(tagName, targetPlayer.Name)
end
