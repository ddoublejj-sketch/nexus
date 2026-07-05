--!strict

local Constants = require("../Constants")

local function zone(
	id: string,
	surface: string,
	priority: number,
	minX: number,
	maxX: number,
	minY: number,
	maxY: number
)
	return {
		id = id,
		surface = surface,
		priority = priority,
		bounds = {
			minX = minX,
			maxX = maxX,
			minY = minY,
			maxY = maxY,
		},
	}
end

local PracticeRange = {
	id = Constants.DEFAULT_PRACTICE_COURSE_ID,
	displayName = "Pinebrook Practice Range",
	version = "1.0.0",
	category = "fictional_premium",
	physicsVersion = Constants.PHYSICS_VERSION,
	teeSets = { Constants.DEFAULT_TEE_SET },
	pinSets = { Constants.DEFAULT_PIN_SET },
	rankedEnabled = false,
	record = nil,
	legal = {
		category = "fictional_premium",
		approvedNameUsage = false,
		approvedLayoutUsage = false,
		approvedImageryUsage = false,
		sourceNotes = "Original practice range lane. No Google imagery, protected course branding, or real-course layout source.",
	},
	holes = {
		{
			index = 1,
			name = "Range Lane",
			par = 3,
			yardage = 320,
			tee = { x = 0, y = 0 },
			pin = { x = 0, y = 300 },
			zones = {
				zone("range_tee", Constants.Surface.TEE, 60, -22, 22, -10, 18),
				zone("range_fairway", Constants.Surface.FAIRWAY, 20, -48, 48, 20, 280),
				zone("range_green", Constants.Surface.GREEN, 50, -24, 24, 280, 326),
				zone("range_bunker", Constants.Surface.BUNKER, 70, -46, -24, 244, 288),
				zone("range_water", Constants.Surface.WATER, 90, 58, 88, 180, 270),
			},
		},
	},
}

return PracticeRange
