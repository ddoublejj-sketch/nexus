--!strict
-- Command: reloadmap
-- Tier: Dev
-- Args: string mapName?
-- Description: Reload a Rojo-managed map from ServerStorage.Maps into Workspace.Map.

return {
	Name = "reloadmap",
	Aliases = { "reload" },
	Description = "Reload a Rojo-managed map from ServerStorage.Maps into Workspace.Map.",
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
