--!strict

local Constants = {}

Constants.STUDS_PER_YARD = 3
Constants.PHYSICS_VERSION = "golfpro_physics_v1"
Constants.DEFAULT_RULESET_ID = "ranked_rules_v1"
Constants.DEFAULT_COURSE_ID = "course_pinebrook_v1"
Constants.UNCLAIMED_RECORD_DISPLAY = "Course Record: 0 / Unclaimed"

Constants.Surface = {
	TEE = "tee",
	FAIRWAY = "fairway",
	ROUGH = "rough",
	GREEN = "green",
	BUNKER = "bunker",
	WATER = "water",
	OUT_OF_BOUNDS = "out_of_bounds",
}

Constants.Mode = {
	PRACTICE = "practice",
	SOLO_STROKE_9 = "solo_stroke_9",
	SOLO_STROKE_18 = "solo_stroke_18",
	PRIVATE_STROKE = "private_stroke",
	SCRAMBLE_2V2 = "scramble_2v2",
}

Constants.ShotType = {
	NORMAL = "normal",
	PUNCH = "punch",
	FLOP = "flop",
	CHIP = "chip",
	PUTT = "putt",
}

return Constants
