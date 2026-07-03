--!strict
-- Command: debugtag
-- Tier: Tester
-- Args: player targetPlayer, string tagName, boolean enabled?
-- Description: Add or remove a CollectionService debug tag on a player's character.

return {
	Name = "debugtag",
	Aliases = {},
	Description = "Add or remove a CollectionService debug tag on a player's character.",
	Group = "NexusTester",
	Args = {
		{
			Type = "player",
			Name = "targetPlayer",
			Description = "Player whose character receives the tag.",
		},
		{
			Type = "string",
			Name = "tagName",
			Description = "Debug tag name.",
		},
		{
			Type = "boolean",
			Name = "enabled",
			Description = "Whether to add or remove the tag.",
			Optional = true,
		},
	},
}
