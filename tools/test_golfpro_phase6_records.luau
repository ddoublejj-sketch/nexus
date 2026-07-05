--!strict

local Constants = require("../src/ReplicatedStorage/Shared/GolfPro/Constants")
local DataStoreKeys = require("../src/ServerScriptService/Server/Data/DataStoreKeys")
local LeaderboardService = require("../src/ServerScriptService/Server/Services/LeaderboardService")
local MigrationLogic = require("../src/ReplicatedStorage/Shared/Data/MigrationLogic")
local ProfileSchema = require("../src/ReplicatedStorage/Shared/Data/ProfileSchema")
local RecordService = require("../src/ServerScriptService/Server/Services/RecordService")
local ResultsService = require("../src/ServerScriptService/Server/Services/ResultsService")

local function assertTrue(condition: boolean, label: string)
	if not condition then
		error(label)
	end
end

local function assertEqual(actual: any, expected: any, label: string)
	if actual ~= expected then
		error(("%s: expected %s, got %s"):format(label, tostring(expected), tostring(actual)))
	end
end

local function context(mode: string?): any
	return {
		courseId = Constants.DEFAULT_COURSE_ID,
		courseVersion = "v1",
		mode = mode or Constants.Mode.SOLO_STROKE_18,
		teeSet = Constants.DEFAULT_TEE_SET,
		pinSet = Constants.DEFAULT_PIN_SET,
		rulesetId = Constants.DEFAULT_RULESET_ID,
		physicsVersion = Constants.PHYSICS_VERSION,
	}
end

local function result(score: number, userId: number, extra: any?): any
	local data = {
		roundId = "round_" .. tostring(userId) .. "_" .. tostring(score),
		playerUserId = userId,
		playerName = "Player" .. tostring(userId),
		totalScore = score,
		ranked = true,
		completed = true,
		holeCount = 18,
		completedAtUnix = 1000 + userId,
	}
	for key, value in extra or {} do
		data[key] = value
	end
	return data
end

RecordService.resetForTests()
LeaderboardService.resetForTests()

local recordContext = context()
local display = RecordService.getDisplayRecord(recordContext)
assertEqual(display.score, 0, "unclaimed display score")
assertEqual(display.holderName, "Unclaimed", "unclaimed holder")
assertEqual(display.unclaimed, true, "unclaimed flag")
assertEqual(RecordService.getCourseRecord(recordContext), nil, "internal record nil")

local first = RecordService.tryUpdateCourseRecord(recordContext, result(72, 101))
assertEqual(first.changed, true, "first record changed")
assertEqual(first.reason, "first_record", "first record reason")
assertEqual((RecordService.getCourseRecord(recordContext) :: any).score, 72, "first record score")

local tie = RecordService.tryUpdateCourseRecord(recordContext, result(72, 202))
assertEqual(tie.changed, false, "tie rejected")
assertEqual(tie.reason, "tie_kept_existing", "tie reason")
assertEqual(
	(RecordService.getCourseRecord(recordContext) :: any).holderUserId,
	101,
	"tie holder kept"
)

local worse = RecordService.tryUpdateCourseRecord(recordContext, result(73, 303))
assertEqual(worse.changed, false, "worse rejected")

local better = RecordService.tryUpdateCourseRecord(recordContext, result(70, 404))
assertEqual(better.changed, true, "better changed")
assertEqual(better.reason, "record_beaten", "better reason")
assertEqual(
	(RecordService.getCourseRecord(recordContext) :: any).holderUserId,
	404,
	"better holder"
)

local unranked = RecordService.tryUpdateCourseRecord(context(), result(65, 505, { ranked = false }))
assertEqual(unranked.changed, false, "unranked rejected")
local debugRound = RecordService.tryUpdateCourseRecord(
	context(Constants.Mode.SOLO_STROKE_3_DEBUG),
	result(9, 606, { holeCount = 3 })
)
assertEqual(debugRound.changed, false, "debug rejected")
local nineHole = RecordService.tryUpdateCourseRecord(
	context(Constants.Mode.SOLO_STROKE_9),
	result(33, 707, { holeCount = 9 })
)
assertEqual(nineHole.changed, false, "nine hole rejected")

local scrambleContext = context(Constants.Mode.SCRAMBLE_2V2)
local scramble = RecordService.tryUpdateCourseRecord(scrambleContext, result(65, 808))
assertEqual(scramble.changed, true, "scramble separate record")
assertTrue(
	DataStoreKeys.courseRecord(scrambleContext) ~= DataStoreKeys.courseRecord(recordContext),
	"scramble key separate"
)

assertEqual(
	LeaderboardService.packScore(result(68, 1)) < LeaderboardService.packScore(result(70, 2)),
	true,
	"lower packed better"
)
assertTrue(select(1, LeaderboardService.submitRound(recordContext, result(70, 1))), "submit 70")
assertTrue(select(1, LeaderboardService.submitRound(recordContext, result(68, 2))), "submit 68")
local page = LeaderboardService.getPage(recordContext, { pageSize = 10 })
assertEqual(page.rows[1].score, 68, "leaderboard lower first")
assertEqual(LeaderboardService.getPlayerRank(recordContext, 2), 1, "player rank")

local migrated = MigrationLogic.migrate({
	schema_version = 1,
	currencies = { coins = 12, gems = 3 },
	inventory = { items = { old_item = 1 } },
	stats = { level = 4, xp = 50 },
	flags = { old = true },
}, ProfileSchema.createDefaultProfile(), ProfileSchema.CURRENT_VERSION)
assertEqual(migrated.schema_version, 2, "schema version")
assertEqual(migrated.currencies.coins, 12, "coins preserved")
assertEqual(migrated.inventory.items.old_item, 1, "item preserved")
assertEqual(migrated.stats.roundsCompleted, 0, "new stat default")
assertTrue(migrated.golf.bestRounds ~= nil, "best rounds added")

local completion = ResultsService.completeRound({
	roundId = "round_complete",
	playerUserId = 999,
	playerName = "Finisher",
	courseId = Constants.DEFAULT_COURSE_ID,
	mode = Constants.Mode.SOLO_STROKE_18,
	ranked = true,
	completed = true,
	holeCount = 18,
	scorecard = {
		total = 66,
		holes = {
			{ par = 4 },
			{ par = 4 },
		},
	},
})
assertEqual(completion.result.totalScore, 66, "results total score")
assertTrue(completion.courseRecord ~= nil, "results record payload")

print("Golf Pro phase 6 record tests passed")
