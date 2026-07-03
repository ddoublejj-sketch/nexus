--!strict
-- Command: reloadmap
-- Tier: Dev
-- Args: string mapName?
-- Description: Queue a map reload request for later map-service integration.

return {
	Name = "reloadmap",
	Aliases = { "reload" },
	Description = "Queue a map reload request for later map-service integration.",
	Group = "NexusDev",
	Args = {
		{
			Type = "string",
			Name = "mapName",
			Description = "Optional map name.",
			Optional = true,
		},
	},
}
