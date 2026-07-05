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

local Pinebrook = {
	id = Constants.DEFAULT_COURSE_ID,
	displayName = "Pinebrook National",
	version = "1.0.0",
	category = "fictional_premium",
	physicsVersion = Constants.PHYSICS_VERSION,
	record = nil,
	legal = {
		category = "fictional_premium",
		approvedNameUsage = false,
		approvedLayoutUsage = false,
		approvedImageryUsage = false,
		sourceNotes = "Original championship-style course. No Google imagery, protected course branding, or real-course layout source.",
	},
	holes = {
		{
			index = 1,
			name = "Opening Pines",
			par = 4,
			yardage = 426,
			tee = { x = 0, y = 0 },
			pin = { x = 18, y = 426 },
			zones = {
				zone("h1_tee", Constants.Surface.TEE, 60, -18, 18, -8, 18),
				zone("h1_fairway", Constants.Surface.FAIRWAY, 20, -26, 42, 40, 340),
				zone("h1_green", Constants.Surface.GREEN, 50, 0, 36, 398, 444),
				zone("h1_left_bunker", Constants.Surface.BUNKER, 70, -34, -10, 284, 326),
				zone("h1_water", Constants.Surface.WATER, 90, 50, 92, 260, 360),
			},
		},
		{
			index = 2,
			name = "Brook Crossing",
			par = 5,
			yardage = 552,
			tee = { x = 0, y = 0 },
			pin = { x = -24, y = 552 },
			zones = {
				zone("h2_tee", Constants.Surface.TEE, 60, -20, 20, -8, 18),
				zone("h2_fairway", Constants.Surface.FAIRWAY, 20, -54, 30, 42, 448),
				zone("h2_layup_fairway", Constants.Surface.FAIRWAY, 20, -78, 2, 448, 520),
				zone("h2_green", Constants.Surface.GREEN, 50, -48, 0, 526, 578),
				zone("h2_cross_water", Constants.Surface.WATER, 90, -90, 44, 318, 346),
				zone("h2_green_bunker", Constants.Surface.BUNKER, 70, -72, -42, 500, 538),
			},
		},
		{
			index = 3,
			name = "Ridge Par Three",
			par = 3,
			yardage = 184,
			tee = { x = 0, y = 0 },
			pin = { x = 8, y = 184 },
			zones = {
				zone("h3_tee", Constants.Surface.TEE, 60, -16, 16, -8, 14),
				zone("h3_short_rough", Constants.Surface.ROUGH, 10, -40, 48, 20, 146),
				zone("h3_green", Constants.Surface.GREEN, 50, -18, 34, 158, 208),
				zone("h3_front_bunker", Constants.Surface.BUNKER, 70, -34, -4, 134, 164),
				zone("h3_right_water", Constants.Surface.WATER, 90, 42, 88, 110, 216),
			},
		},
	},
}

return Pinebrook
