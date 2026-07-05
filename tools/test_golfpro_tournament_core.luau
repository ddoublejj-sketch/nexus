--!strict

local Constants = require("../src/ReplicatedStorage/Shared/GolfPro/Constants")
local TournamentConfig = require("../src/ReplicatedStorage/Shared/GolfPro/Config/TournamentConfig")
local CosmeticService = require("../src/ServerScriptService/Server/Services/CosmeticService")
local TournamentService = require("../src/ServerScriptService/Server/Services/TournamentService")

local function assertEqual(actual: any, expected: any, label: string)
	if actual ~= expected then
		error(("%s: expected %s, got %s"):format(label, tostring(expected), tostring(actual)))
	end
end

local function assertTrue(condition: boolean, label: string)
	if not condition then
		error(label)
	end
end

local function result(score: number, overrides: any?): any
	local out = {
		roundId = "round_" .. tostring(score),
		courseId = Constants.DEFAULT_COURSE_ID,
		mode = Constants.Mode.SOLO_STROKE_18,
		ranked = true,
		completed = true,
		holeCount = 18,
		totalScore = score,
		completedAtUnix = 1000 + score,
	}
	for key, value in overrides or {} do
		out[key] = value
	end
	return out
end

local eventId = "weekend_open_001"
local playerA = { UserId = 8101, Name = "Alpha" }
local playerB = { UserId = 8102, Name = "Beta" }

CosmeticService.resetForTests()
TournamentService.resetForTests()

local events = TournamentService.getActiveEvents(playerA)
assertEqual(#events, 1, "one active event")
assertEqual(events[1].id, eventId, "active event id")
assertEqual(events[1].courseId, Constants.DEFAULT_COURSE_ID, "event course")
assertEqual(events[1].mode, Constants.Mode.SOLO_STROKE_18, "event mode")
assertEqual(events[1].ranked, true, "event ranked")
assertEqual(events[1].maxAttempts, 3, "event max attempts")
assertEqual(events[1].prizePolicy.type, "cosmetic_only", "cosmetic-only policy")
assertEqual(events[1].prizePolicy.realMoneyEnabled, false, "real-money rewards disabled")
assertEqual(
	events[1].prizePolicy.platformCurrencyEnabled,
	false,
	"platform-currency rewards disabled"
)
assertEqual(events[1].prizePolicy.paidEntryEnabled, false, "paid entry disabled")
assertEqual(events[1].prizePolicy.stakeEnabled, false, "stake mechanics disabled")
assertEqual(events[1].prizePolicy.paidChanceRewardEnabled, false, "paid chance rewards disabled")

local unrankedOk, unrankedReason =
	TournamentService.submitAttempt(playerA, eventId, result(72, { ranked = false }))
assertEqual(unrankedOk, false, "unranked result rejected")
assertEqual(unrankedReason, "invalid_ranked_completion", "unranked reason")
local debugOk, debugReason =
	TournamentService.submitAttempt(playerA, eventId, result(72, { debug = true }))
assertEqual(debugOk, false, "debug result rejected")
assertEqual(debugReason, "debug_result", "debug reason")

local ok1, attempt1 = TournamentService.submitAttempt(playerA, eventId, result(72))
assertEqual(ok1, true, "first attempt accepted")
assertEqual(attempt1.attemptsUsed, 1, "first attempt count")
assertTrue(
	CosmeticService.ownsCosmetic(playerA, TournamentConfig.events.weekend_open_001.rewardCosmeticId),
	"reward granted"
)
local ok2 = TournamentService.submitAttempt(playerA, eventId, result(71))
local ok3 = TournamentService.submitAttempt(playerA, eventId, result(70))
assertEqual(ok2, true, "second attempt accepted")
assertEqual(ok3, true, "third attempt accepted")
local ok4, reason4 = TournamentService.submitAttempt(playerA, eventId, result(69))
assertEqual(ok4, false, "fourth attempt rejected")
assertEqual(reason4, "max_attempts", "max attempts reason")

local okB = TournamentService.submitAttempt(playerB, eventId, result(68))
assertEqual(okB, true, "other player valid attempt accepted")
local leaderboard = TournamentService.getEventLeaderboard(eventId)
assertEqual(leaderboard.rows[1].playerName, "Beta", "lower score ranks first")
assertEqual(leaderboard.rows[1].score, 68, "top score")
assertEqual(leaderboard.rows[2].score, 70, "second score")
assertEqual(
	TournamentService.getActiveEvents(playerA)[1].attemptsUsed,
	3,
	"attempts shown in event snapshot"
)

print("Golf Pro tournament core tests passed")
