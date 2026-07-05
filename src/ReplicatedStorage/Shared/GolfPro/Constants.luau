--!strict

local Constants = {}

Constants.STUDS_PER_YARD = 3
Constants.PHYSICS_VERSION = "golfpro_physics_v1"
Constants.DEFAULT_RULESET_ID = "ranked_rules_v1"
Constants.DEFAULT_COURSE_ID = "course_pinebrook_v1"
Constants.DEFAULT_PRACTICE_COURSE_ID = "course_practice_range_v1"
Constants.DEFAULT_TEE_SET = "debug"
Constants.DEFAULT_PIN_SET = "debug"
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
	SOLO_STROKE_3_DEBUG = "solo_stroke_3_debug",
	SOLO_STROKE_9 = "solo_stroke_9",
	SOLO_STROKE_18 = "solo_stroke_18",
	PRIVATE_STROKE = "private_stroke",
	SCRAMBLE_2V2 = "scramble_2v2",
}

Constants.RoundState = {
	PRE_SHOT = "pre_shot",
	BALL_IN_FLIGHT = "ball_in_flight",
	HOLE_COMPLETE = "hole_complete",
	ROUND_COMPLETE = "round_complete",
}

Constants.Rejection = {
	INVALID_PAYLOAD = "invalid_payload",
	NO_ROUND = "no_round",
	NOT_TURN = "not_turn",
	BALL_MOVING = "ball_moving",
	INVALID_CLUB = "invalid_club",
	INVALID_LIE = "invalid_lie",
	RATE_LIMIT = "rate_limit",
	DUPLICATE_NONCE = "duplicate_nonce",
	INVALID_ROUND = "invalid_round",
}

Constants.ShotType = {
	NORMAL = "normal",
	PUNCH = "punch",
	FLOP = "flop",
	CHIP = "chip",
	PUTT = "putt",
}

return Constants
