--!strict
-- Command: give
-- Tier: Dev
-- Args: players targetPlayers, string itemKey, number amount
-- Description: Queue a grant request for later inventory integration.

return {
	Name = "give",
	Aliases = {},
	Description = "Queue a grant request for later inventory integration.",
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
