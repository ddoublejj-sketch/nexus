--!strict

local Constants = require("../Constants")

local RankedRules = {
	id = Constants.DEFAULT_RULESET_ID,
	physicsVersion = Constants.PHYSICS_VERSION,
	allowedModes = {
		[Constants.Mode.SOLO_STROKE_18] = true,
		[Constants.Mode.SCRAMBLE_2V2] = true,
	},
	allowMulligans = false,
	allowAdminCommands = false,
	allowDebugTeleports = false,
	recordTiePolicy = "earliest_verified_keeps_record",
	prizePolicy = {
		type = "cosmetic_only",
		cashEnabled = false,
		robuxEnabled = false,
		entryFeeEnabled = false,
		legalApprovalId = nil,
	},
}

return RankedRules
