--!strict
-- Command: spawn
-- Tier: Dev
-- Args: string assetName, vector3 position?
-- Description: Spawn a named ServerStorage asset near a position when available.

return {
	Name = "spawn",
	Aliases = {},
	Description = "Spawn a named ServerStorage asset near a position when available.",
	Group = "NexusDev",
	Args = {
		{
			Type = "string",
			Name = "assetName",
			Description = "Name of the asset under ServerStorage.Assets.",
		},
		{
			Type = "vector3",
			Name = "position",
			Description = "Optional spawn position.",
			Optional = true,
		},
	},
}
