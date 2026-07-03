--!strict
-- Command: give
-- Tier: Dev
-- Args: players targetPlayers, string itemKey, number amount
-- Description: Grant a schema-backed inventory item to loaded player profiles.

return {
	Name = "give",
	Aliases = {},
	Description = "Grant a schema-backed inventory item to loaded player profiles.",
	Group = "NexusDev",
	Args = {
		{
			Type = "players",
			Name = "targetPlayers",
			Description = "Players receiving the item.",
		},
		{
			Type = "string",
			Name = "itemKey",
			Description = "Inventory item key.",
		},
		{
			Type = "number",
			Name = "amount",
			Description = "Amount to grant.",
		},
	},
}
