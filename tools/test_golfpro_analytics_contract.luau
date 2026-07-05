--!strict

local Constants = require("../src/ReplicatedStorage/Shared/GolfPro/Constants")
local AnalyticsService = require("../src/ServerScriptService/Server/Services/AnalyticsService")
local CosmeticService = require("../src/ServerScriptService/Server/Services/CosmeticService")
local LeaderboardService = require("../src/ServerScriptService/Server/Services/LeaderboardService")
local MysteryRangeService =
	require("../src/ServerScriptService/Server/Services/MysteryRangeService")
local RecordService = require("../src/ServerScriptService/Server/Services/RecordService")
local ResultsService = require("../src/ServerScriptService/Server/Services/ResultsService")
local RoundService = require("../src/ServerScriptService/Server/Services/RoundService")
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

local function assertEvent(eventName: string, label: string)
	assertTrue(AnalyticsService.count(eventName) > 0, label)
end

local function result(score: number): any
	return {
		roundId = "analytics_round_" .. tostring(score),
		playerUserId = 9201,
		playerName = "AnalyticPlayer",
		courseId = Constants.DEFAULT_COURSE_ID,
		mode = Constants.Mode.SOLO_STROKE_18,
		ranked = true,
		completed = true,
		holeCount = 18,
		totalScore = score,
		completedAtUnix = 2000 + score,
	}
end

local expectedEvents = {
	"menu_opened",
	"practice_shot_hit",
	"round_started",
	"hole_completed",
	"round_completed",
	"round_abandoned",
	"ranked_round_completed",
	"course_record_set",
	"course_record_beaten",
	"leaderboard_submit",
	"mystery_range_deposit",
	"cosmetic_equipped",
	"tournament_attempt_submitted",
}

AnalyticsService.resetForTests()
RoundService.resetForTests()
LeaderboardService.resetForTests()
RecordService.resetForTests()
CosmeticService.resetForTests()
MysteryRangeService.resetForTests()
TournamentService.resetForTests()

for _, eventName in expectedEvents do
	assertTrue(AnalyticsService.isKnownEvent(eventName), "missing analytics event " .. eventName)
end
assertEqual(
	select(1, AnalyticsService.log(nil, "unknown_event", {})),
	false,
	"unknown event rejected"
)

local player = { UserId = 9201, Name = "AnalyticPlayer" }
local startOk, round = RoundService.startRound(player, {
	mode = Constants.Mode.SOLO_STROKE_18,
	courseId = Constants.DEFAULT_COURSE_ID,
	teeSet = Constants.DEFAULT_TEE_SET,
	pinSet = Constants.DEFAULT_PIN_SET,
	ranked = false,
})
assertEqual(startOk, true, "round starts")
assertEvent("round_started", "round_started logged")

assertEqual(select(1, RoundService.beginShot(round)), true, "begin shot for hole analytics")
assertEqual(
	select(
		1,
		RoundService.finishShot(round, {
			finalPosition = round.course.holes[1].pin,
			finalSurface = Constants.Surface.GREEN,
			carryYards = 120,
			rollYards = 0,
			totalYards = 120,
			lateralOffsetYards = 0,
		})
	),
	true,
	"finish shot for hole analytics"
)
assertEvent("hole_completed", "hole_completed logged")

ResultsService.completeRound(result(72))
assertEvent("round_completed", "round_completed logged")
assertEvent("ranked_round_completed", "ranked_round_completed logged")
assertEvent("leaderboard_submit", "leaderboard_submit logged")
assertEvent("course_record_set", "course_record_set logged")
ResultsService.completeRound(result(70))
assertEvent("course_record_beaten", "course_record_beaten logged")

CosmeticService.grantCosmetic(player, "sunrise_gold_ball", "analytics_test")
assertEqual(
	select(1, CosmeticService.equipCosmetic(player, "sunrise_gold_ball")),
	true,
	"cosmetic equips"
)
assertEvent("cosmetic_equipped", "cosmetic_equipped logged")

MysteryRangeService.resetForTests(player, {
	rangeTokens = 0,
	discoveryMeter = 100,
	depositCount = 0,
	unlockedZones = { starter = true },
	upgrades = {},
	cosmeticShards = {},
})
assertEqual(select(1, MysteryRangeService.deposit(player)), true, "deposit succeeds")
assertEvent("mystery_range_deposit", "mystery_range_deposit logged")

local tournamentResult = result(69)
tournamentResult.roundId = "analytics_tournament"
assertEqual(
	select(1, TournamentService.submitAttempt(player, "weekend_open_001", tournamentResult)),
	true,
	"tournament submit succeeds"
)
assertEvent("tournament_attempt_submitted", "tournament_attempt_submitted logged")

AnalyticsService.log(player, "practice_shot_hit", { targetId = "starter_flag" })
AnalyticsService.log(player, "menu_opened", { menu = "main" })
AnalyticsService.log(player, "round_abandoned", { roundId = "abandoned_round" })
assertEvent("practice_shot_hit", "practice_shot_hit supported")
assertEvent("menu_opened", "menu_opened supported")
assertEvent("round_abandoned", "round_abandoned supported")

print("Golf Pro analytics contract tests passed")
