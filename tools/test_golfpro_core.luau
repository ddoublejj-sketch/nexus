--!strict

local fs = require("@lune/fs")

local Constants = require("../src/ReplicatedStorage/Shared/GolfPro/Constants")
local ClubRegistry = require("../src/ReplicatedStorage/Shared/GolfPro/Clubs/ClubRegistry")
local CourseRegistry = require("../src/ReplicatedStorage/Shared/GolfPro/Courses/CourseRegistry")
local PayloadValidators =
	require("../src/ReplicatedStorage/Shared/GolfPro/Network/PayloadValidators")
local GreenModel = require("../src/ReplicatedStorage/Shared/GolfPro/Simulation/GreenModel")
local SurfaceResolver =
	require("../src/ReplicatedStorage/Shared/GolfPro/Simulation/SurfaceResolver")
local ShotMath = require("../src/ReplicatedStorage/Shared/GolfPro/Simulation/ShotMath")
local WindModel = require("../src/ReplicatedStorage/Shared/GolfPro/Simulation/WindModel")
local RoundService = require("../src/ServerScriptService/Server/Services/RoundService")
local ScoreService = require("../src/ServerScriptService/Server/Services/ScoreService")
local ShotService = require("../src/ServerScriptService/Server/Services/ShotService")

local function assertTrue(condition: boolean, label: string)
	if not condition then
		error(label)
	end
end

local function assertFalse(condition: boolean, label: string)
	if condition then
		error(label)
	end
end

local function assertEqual(actual: any, expected: any, label: string)
	if actual ~= expected then
		error(("%s: expected %s, got %s"):format(label, tostring(expected), tostring(actual)))
	end
end

local function assertError(callback: () -> (), label: string)
	local ok = pcall(callback)
	if ok then
		error(label)
	end
end

local function baseIntent(roundId: string, userId: number, nonce: string)
	return {
		roundId = roundId,
		holeIndex = 1,
		playerUserId = userId,
		clubId = "driver",
		shotType = "normal",
		aimYawDeg = 0,
		aimPitchDeg = 0,
		power01 = 0.82,
		accuracy01 = 0.5,
		spin01 = 0,
		drawFade01 = 0,
		clientShotNonce = nonce,
		clientTimestamp = 0,
	}
end

ClubRegistry.validateAll()

local clubs = ClubRegistry.all()
assertEqual(#clubs, 14, "default club count")
assertTrue(ClubRegistry.get("driver") ~= nil, "driver missing")
assertTrue(ClubRegistry.get("putter") ~= nil, "putter missing")

local pinebrook = CourseRegistry.requireCourse(Constants.DEFAULT_COURSE_ID)
local practice = CourseRegistry.requireCourse(Constants.DEFAULT_PRACTICE_COURSE_ID)
CourseRegistry.validate(pinebrook)
CourseRegistry.validate(practice)

assertEqual(pinebrook.displayName, "Pinebrook National", "first course name")
assertEqual(pinebrook.legal.category, "fictional_premium", "legal category")
assertEqual(pinebrook.record, nil, "new course record must be unset internally")
assertEqual(
	CourseRegistry.recordDisplay(pinebrook),
	Constants.UNCLAIMED_RECORD_DISPLAY,
	"unclaimed record display"
)
assertTrue(#pinebrook.holes >= 3, "Pinebrook vertical slice needs at least 3 holes")
assertEqual(practice.displayName, "Pinebrook Practice Range", "practice range course")

local badLegalCourse: any = {
	id = "bad_course",
	displayName = "Bad Course",
	version = "1.0.0",
	category = "unlicensed_real_like",
	physicsVersion = Constants.PHYSICS_VERSION,
	teeSets = { Constants.DEFAULT_TEE_SET },
	pinSets = { Constants.DEFAULT_PIN_SET },
	rankedEnabled = false,
	record = nil,
	legal = {
		category = "unlicensed_real_like",
		approvedNameUsage = false,
		approvedLayoutUsage = false,
		approvedImageryUsage = false,
		sourceNotes = "invalid",
	},
	holes = { pinebrook.holes[1] },
}
assertError(function()
	CourseRegistry.validate(badLegalCourse)
end, "illegal course category must be rejected")

local badHoleCourse: any = {
	id = "bad_hole_course",
	displayName = "Bad Hole Course",
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
		sourceNotes = "Original invalid test course.",
	},
	holes = {
		{
			index = 1,
			name = "Bad Hole",
			par = 4,
			yardage = 1,
			tee = { x = 999, y = 999 },
			pin = { x = 0, y = 0 },
			zones = { pinebrook.holes[1].zones[1] },
		},
	},
}
assertError(function()
	CourseRegistry.validate(badHoleCourse)
end, "tee and pin must be covered by legal zones")

local hole1 = pinebrook.holes[1]
assertEqual(
	SurfaceResolver.resolve(hole1, { x = 12, y = 420 }),
	Constants.Surface.GREEN,
	"green resolution"
)
assertEqual(
	SurfaceResolver.resolve(hole1, { x = 64, y = 300 }),
	Constants.Surface.WATER,
	"water priority"
)
assertEqual(
	SurfaceResolver.resolve(hole1, { x = -100, y = 100 }),
	Constants.Surface.ROUGH,
	"default rough fallback"
)
assertTrue(GreenModel.isHoled(hole1, hole1.pin, 1), "pin-speed putt should hole")
assertFalse(GreenModel.isHoled(hole1, hole1.pin, 99), "fast putt should not hole")

local driver = ClubRegistry.requireClub("driver")
local intent = baseIntent("round_test", 1, "nonce")

local shotA =
	ShotMath.solve(driver, hole1, hole1.tee, Constants.Surface.TEE, intent, WindModel.calm())
local shotB =
	ShotMath.solve(driver, hole1, hole1.tee, Constants.Surface.TEE, intent, WindModel.calm())

assertEqual(shotA.totalYards, shotB.totalYards, "shot solver must be deterministic")
assertTrue(shotA.carryYards > 0, "shot carry must be positive")
assertTrue(shotA.totalYards <= driver.maxCarryYards * 1.25, "driver output bound")

local validShotIntent, shotReason = PayloadValidators.validateShotIntent(intent)
assertTrue(validShotIntent, "valid ShotIntent rejected: " .. tostring(shotReason))
local invalidPowerIntent = baseIntent("round_test", 1, "nonce_2")
invalidPowerIntent.power01 = 1.5
assertFalse(PayloadValidators.validateShotIntent(invalidPowerIntent), "invalid power accepted")
local roundPayload = {
	mode = Constants.Mode.SOLO_STROKE_3_DEBUG,
	courseId = Constants.DEFAULT_COURSE_ID,
	teeSet = Constants.DEFAULT_TEE_SET,
	pinSet = Constants.DEFAULT_PIN_SET,
	ranked = false,
}
assertTrue(
	PayloadValidators.validateRoundStartPayload(roundPayload),
	"round start payload rejected"
)
local rankedPayload: any = table.clone(roundPayload)
rankedPayload.ranked = true
assertFalse(
	PayloadValidators.validateRoundStartPayload(rankedPayload),
	"unranked slice accepted ranked start"
)

local scorecard = ScoreService.createScorecard(pinebrook, 3)
ScoreService.recordShot(scorecard, 1, Constants.Surface.FAIRWAY, false)
ScoreService.recordShot(scorecard, 1, Constants.Surface.WATER, false)
assertEqual(scorecard.totalStrokes, 2, "score strokes")
assertEqual(scorecard.totalPenaltyStrokes, 1, "score penalties")
assertEqual(ScoreService.total(scorecard), 3, "score total")
ScoreService.completeHole(scorecard, 1)
assertTrue(scorecard.holes[1].completed, "hole completion")

RoundService.resetForTests()
ShotService.resetForTests()
local player = { UserId = 101, Name = "Tester" }
local startedRound, roundOrReason = RoundService.startRound(player, roundPayload)
assertTrue(startedRound, "round start failed: " .. tostring(roundOrReason))
local round = roundOrReason
assertEqual(round.state, Constants.RoundState.PRE_SHOT, "round initial state")
assertFalse(
	select(1, RoundService.transition(round, Constants.RoundState.ROUND_COMPLETE)),
	"invalid transition accepted"
)
assertTrue(select(1, RoundService.beginShot(round)), "begin shot failed")
assertEqual(round.state, Constants.RoundState.BALL_IN_FLIGHT, "round ball in flight state")
assertTrue(
	select(
		1,
		RoundService.finishShot(round, {
			finalPosition = hole1.pin,
			finalSurface = Constants.Surface.GREEN,
			rollYards = 1,
		})
	),
	"finish shot failed"
)
assertEqual(round.holeIndex, 2, "holed shot should advance to hole 2")
assertEqual(round.state, Constants.RoundState.PRE_SHOT, "round should return to pre-shot")

RoundService.resetForTests()
ShotService.resetForTests()
local noRoundIntent = baseIntent("missing_round", 101, "missing")
assertEqual(
	select(2, ShotService.submitShot(player, noRoundIntent, 1)),
	Constants.Rejection.NO_ROUND,
	"missing round rejection"
)
local okRound, shotRoundOrReason = RoundService.startRound(player, roundPayload)
assertTrue(okRound, "shot round start failed: " .. tostring(shotRoundOrReason))
local shotRound = shotRoundOrReason
local accepted, acceptedPayload =
	ShotService.submitShot(player, baseIntent(shotRound.id, 101, "shot_1"), 1)
assertTrue(accepted, "valid shot rejected: " .. tostring(acceptedPayload))
assertTrue(#acceptedPayload.path.points == 3, "ball path points")
assertEqual(acceptedPayload.ballAtRest.roundId, shotRound.id, "ball at rest round id")
assertEqual(
	select(2, ShotService.submitShot(player, baseIntent(shotRound.id, 101, "shot_1"), 2)),
	Constants.Rejection.DUPLICATE_NONCE,
	"duplicate nonce rejection"
)
assertEqual(
	select(2, ShotService.submitShot(player, baseIntent(shotRound.id, 101, "shot_2"), 1.1)),
	Constants.Rejection.RATE_LIMIT,
	"rate rejection"
)
shotRound.state = Constants.RoundState.BALL_IN_FLIGHT
shotRound.ball.moving = true
assertEqual(
	select(2, ShotService.submitShot(player, baseIntent(shotRound.id, 101, "shot_3"), 3)),
	Constants.Rejection.BALL_MOVING,
	"moving ball rejection"
)
shotRound.state = Constants.RoundState.PRE_SHOT
shotRound.ball.moving = false
shotRound.ball.surface = Constants.Surface.WATER
assertEqual(
	select(2, ShotService.submitShot(player, baseIntent(shotRound.id, 101, "shot_4"), 3)),
	Constants.Rejection.INVALID_LIE,
	"invalid lie rejection"
)

local spec = fs.readFile("docs/product/GolfPro_Source_of_Truth.md")
assertTrue(
	spec:find("Pinebrook National", 1, true) ~= nil
		and spec:find("server-authoritative golf", 1, true) ~= nil,
	"source-of-truth doc must be copied into the repo"
)

local net = fs.readFile("src/ReplicatedStorage/Shared/Net/init.luau")
for _, remoteName in
	{
		"RequestStartPrivateRound",
		"SubmitShotIntent",
		"RequestScrambleBallVote",
		"ShotAccepted",
		"ShotRejected",
		"BallPath",
		"BallAtRest",
		"RoundStateUpdated",
		"ScorecardUpdated",
	}
do
	assertTrue(net:find(remoteName, 1, true) ~= nil, "missing Golf Pro remote: " .. remoteName)
end
assertTrue(
	net:find("PayloadValidators", 1, true) ~= nil,
	"Net must call Golf Pro payload validators"
)

print("Golf Pro core tests passed")
