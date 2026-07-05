--!strict

local Constants = require("../Constants")

local LieModel = {}

local LIES = {
	[Constants.Surface.TEE] = {
		carryMultiplier = 1,
		rollMultiplier = 1,
		penaltyStrokes = 0,
	},
	[Constants.Surface.FAIRWAY] = {
		carryMultiplier = 1,
		rollMultiplier = 1,
		penaltyStrokes = 0,
	},
	[Constants.Surface.ROUGH] = {
		carryMultiplier = 0.86,
		rollMultiplier = 0.55,
		penaltyStrokes = 0,
	},
	[Constants.Surface.GREEN] = {
		carryMultiplier = 0.35,
		rollMultiplier = 0.85,
		penaltyStrokes = 0,
	},
	[Constants.Surface.BUNKER] = {
		carryMultiplier = 0.62,
		rollMultiplier = 0.25,
		penaltyStrokes = 0,
	},
	[Constants.Surface.WATER] = {
		carryMultiplier = 0,
		rollMultiplier = 0,
		penaltyStrokes = 1,
	},
	[Constants.Surface.OUT_OF_BOUNDS] = {
		carryMultiplier = 0,
		rollMultiplier = 0,
		penaltyStrokes = 1,
	},
}

function LieModel.get(surface: string)
	return LIES[surface] or LIES[Constants.Surface.ROUGH]
end

return LieModel
