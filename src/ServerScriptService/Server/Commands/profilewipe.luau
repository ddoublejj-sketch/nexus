--!strict
-- Command: profilewipe
-- Tier: Owner
-- Args: player targetPlayer, string confirm
-- Description: Reset a loaded profile to schema defaults after Owner confirmation.

return {
	Name = "profilewipe",
	Aliases = {},
	Description = "Reset a loaded profile to schema defaults after Owner confirmation.",
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
