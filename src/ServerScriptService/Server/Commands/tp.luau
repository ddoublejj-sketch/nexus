--!strict
-- Command: tp
-- Tier: Dev
-- Args: players fromPlayers, player @ vector3 destination
-- Description: Teleport one or more players to a player or Vector3 destination.

return {
	Name = "tp",
	Aliases = { "teleport" },
	Description = "Teleport one or more players to a player or Vector3 destination.",
	Group = "NexusDev",
	Args = {
		{
			Type = "players",
			Name = "fromPlayers",
			Description = "Players to teleport.",
		},
		{
			Type = "player @ vector3",
			Name = "destination",
			Description = "Target player or position.",
		},
	},
}
