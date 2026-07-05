--!strict

export type ProfileData = {
	schema_version: number,
	currencies: {
		coins: number,
		gems: number,
	},
	inventory: {
		items: { [string]: number },
	},
	stats: {
		level: number,
		xp: number,
		roundsStarted: number,
		roundsCompleted: number,
		rankedRoundsCompleted: number,
		totalStrokes: number,
		bestScoreToPar: number?,
		longestDriveYards: number,
	},
	flags: { [string]: boolean },
	golf: {
		bestRounds: { [string]: any },
		courseRecordsHeld: { [string]: boolean },
		cosmetics: {
			owned: { [string]: boolean },
			equipped: { [string]: string },
		},
		mysteryRange: {
			rangeTokens: number,
			discoveryMeter: number,
			depositCount: number,
			unlockedZones: { [string]: boolean },
			upgrades: { [string]: boolean },
			cosmeticShards: { [string]: number },
		},
	},
}

local ProfileSchema = {}

ProfileSchema.CURRENT_VERSION = 3

function ProfileSchema.createDefaultProfile(): ProfileData
	return {
		schema_version = ProfileSchema.CURRENT_VERSION,
		currencies = {
			coins = 0,
			gems = 0,
		},
		inventory = {
			items = {},
		},
		stats = {
			level = 1,
			xp = 0,
			roundsStarted = 0,
			roundsCompleted = 0,
			rankedRoundsCompleted = 0,
			totalStrokes = 0,
			bestScoreToPar = nil,
			longestDriveYards = 0,
		},
		flags = {},
		golf = {
			bestRounds = {},
			courseRecordsHeld = {},
			cosmetics = {
				owned = {},
				equipped = {},
			},
			mysteryRange = {
				rangeTokens = 0,
				discoveryMeter = 0,
				depositCount = 0,
				unlockedZones = { starter = true },
				upgrades = {},
				cosmeticShards = {},
			},
		},
	}
end

return ProfileSchema
