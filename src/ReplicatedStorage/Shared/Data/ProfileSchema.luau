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
	},
	flags: { [string]: boolean },
}

local ProfileSchema = {}

ProfileSchema.CURRENT_VERSION = 1

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
		},
		flags = {},
	}
end

return ProfileSchema
