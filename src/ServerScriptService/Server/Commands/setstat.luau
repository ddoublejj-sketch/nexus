--!strict
-- Command: setstat
-- Tier: Dev
-- Args: players targetPlayers, string statKey, number value
-- Description: Queue a profile stat set request for later data-service integration.

return {
	Name = "setstat",
	Aliases = {},
	Description = "Queue a profile stat set request for later data-service integration.",
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
