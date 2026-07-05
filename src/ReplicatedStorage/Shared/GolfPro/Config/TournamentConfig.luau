--!strict

local Constants = require("../Constants")

local TournamentConfig = {}

TournamentConfig.events = {
	weekend_open_001 = {
		id = "weekend_open_001",
		displayName = "Weekend Open",
		courseId = Constants.DEFAULT_COURSE_ID,
		courseName = "Pinebrook National",
		mode = Constants.Mode.SOLO_STROKE_18,
		ranked = true,
		maxAttempts = 3,
		rewardCosmeticId = "pin_seeker_title",
		rewardDescription = "Pin Seeker title",
		prizePolicy = {
			type = "cosmetic_only",
			realMoneyEnabled = false,
			platformCurrencyEnabled = false,
			paidEntryEnabled = false,
			stakeEnabled = false,
			paidChanceRewardEnabled = false,
		},
	},
}

function TournamentConfig.get(eventId: string): any?
	return (TournamentConfig.events :: any)[eventId]
end

function TournamentConfig.activeEvents(): { any }
	local list = {}
	for _, event: any in TournamentConfig.events :: any do
		table.insert(list, event)
	end
	table.sort(list, function(left: any, right: any): boolean
		return left.id < right.id
	end)
	return list
end

return TournamentConfig
