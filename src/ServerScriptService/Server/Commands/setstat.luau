--!strict
-- Command: setstat
-- Tier: Dev
-- Args: players targetPlayers, string statKey, number value
-- Description: Set a schema-backed profile stat on loaded player profiles.

return {
	Name = "setstat",
	Aliases = {},
	Description = "Set a schema-backed profile stat on loaded player profiles.",
	Group = "NexusDev",
	Args = {
		{
			Type = "players",
			Name = "targetPlayers",
			Description = "Players whose stat should change.",
		},
		{
			Type = "string",
			Name = "statKey",
			Description = "Profile stat key.",
		},
		{
			Type = "number",
			Name = "value",
			Description = "New stat value.",
		},
	},
}
