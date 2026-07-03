--!strict
-- Command: profilewipe
-- Tier: Owner
-- Args: player targetPlayer, string confirm
-- Description: Refuse profile wipe unless caller is Owner and confirm is CONFIRM_WIPE.

return {
	Name = "profilewipe",
	Aliases = {},
	Description = "Refuse profile wipe unless caller is Owner and confirm is CONFIRM_WIPE.",
	Group = "NexusOwner",
	Args = {
		{
			Type = "player",
			Name = "targetPlayer",
			Description = "Player whose profile would be wiped.",
		},
		{
			Type = "string",
			Name = "confirm",
			Description = "Must be CONFIRM_WIPE.",
		},
	},
}
