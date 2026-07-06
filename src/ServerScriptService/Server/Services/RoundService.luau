--!strict

local Constants = require("../../../ReplicatedStorage/Shared/GolfPro/Constants")
local CourseRegistry = require("../../../ReplicatedStorage/Shared/GolfPro/Courses/CourseRegistry")
local GreenModel = require("../../../ReplicatedStorage/Shared/GolfPro/Simulation/GreenModel")
local PayloadValidators =
	require("../../../ReplicatedStorage/Shared/GolfPro/Network/PayloadValidators")
local RoundAuditService = require("./RoundAuditService")
local ScoreService = require("./ScoreService")
local AnalyticsService = require("./AnalyticsService")

local RoundService = {}

local rounds: { [string]: any } = {}
local playerRounds: { [number]: string } = {}
local roundCounter = 0
local dataServiceOverride: any? = nil

local function playerUserId(player: any): number
	local ok, value = pcall(function()
		return player.UserId
	end)

	if ok and type(value) == "number" then
		return value
	end

	return 0
end

local function nextRoundId(userId: number): string
	roundCounter += 1
	return ("round_%d_%d"):format(userId, roundCounter)
end

local function copyPosition(position)
	return {
		x = position.x,
		y = position.y,
	}
end

local function holeCountForMode(mode: string, course): number
	if mode == Constants.Mode.PRACTICE then
		return 1
	end
	if mode == Constants.Mode.SOLO_STROKE_18 or mode == Constants.Mode.PRIVATE_STROKE then
		return math.min(18, #course.holes)
	end
	if mode == Constants.Mode.SOLO_STROKE_9 then
		return math.min(9, #course.holes)
	end

	return math.min(3, #course.holes)
end

local function dataService(): any?
	if dataServiceOverride ~= nil then
		return dataServiceOverride
	end
	if game == nil then
		return nil
	end

	local ok, service = pcall(function()
		return require(script.Parent.DataService)
	end)
	return if ok then service else nil
end

function RoundService.resetForTests()
	rounds = {}
	playerRounds = {}
	roundCounter = 0
	dataServiceOverride = nil
end

function RoundService.setDataServiceForTests(service: any?)
	dataServiceOverride = service
end

function RoundService.startRound(player: any, payload: any): (boolean, any)
	local ok, reason = PayloadValidators.validateRoundStartPayload(payload)
	if not ok then
		return false, reason
	end

	local userId = playerUserId(player)
	if userId <= 0 then
		return false, "player UserId is required"
	end

	local course = CourseRegistry.requireCourse(payload.courseId)
	local holeCount = holeCountForMode(payload.mode, course)
	local firstHole = course.holes[1]
	local round = {
		id = nextRoundId(userId),
		courseId = course.id,
		courseVersion = course.version or "v1",
		physicsVersion = course.physicsVersion or Constants.PHYSICS_VERSION,
		course = course,
		mode = payload.mode,
		teeSet = payload.teeSet or Constants.DEFAULT_TEE_SET,
		pinSet = payload.pinSet or Constants.DEFAULT_PIN_SET,
		ranked = payload.ranked,
		playerUserId = userId,
		currentTurnUserId = userId,
		holeIndex = 1,
		holeCount = holeCount,
		state = Constants.RoundState.PRE_SHOT,
		ball = {
			position = copyPosition(firstHole.tee),
			surface = Constants.Surface.TEE,
			moving = false,
		},
		nonces = {},
		lastShotAt = 0,
		scorecard = ScoreService.createScorecard(course, holeCount),
	}

	rounds[round.id] = round
	playerRounds[userId] = round.id
	RoundAuditService.beginRound(round)
	local service = dataService()
	if service ~= nil then
		service.recordRoundStarted(player, round)
	end
	AnalyticsService.log(player, "round_started", {
		roundId = round.id,
		courseId = round.courseId,
		mode = round.mode,
		ranked = round.ranked,
		holeCount = round.holeCount,
	})

	return true, round
end

function RoundService.startSoloDebug(player: any): (boolean, any)
	return RoundService.startRound(player, {
		mode = Constants.Mode.SOLO_STROKE_3_DEBUG,
		courseId = Constants.DEFAULT_COURSE_ID,
		teeSet = Constants.DEFAULT_TEE_SET,
		pinSet = Constants.DEFAULT_PIN_SET,
		ranked = false,
	})
end

function RoundService.getRound(roundId: string): any?
	return rounds[roundId]
end

function RoundService.getPlayerRound(player: any): any?
	local roundId = playerRounds[playerUserId(player)]
	if roundId == nil then
		return nil
	end

	return rounds[roundId]
end

function RoundService.currentHole(round: any): any
	return round.course.holes[round.holeIndex]
end

function RoundService.transition(round: any, nextState: string): (boolean, string?)
	local state = round.state
	local valid = (
		state == Constants.RoundState.PRE_SHOT
		and nextState == Constants.RoundState.BALL_IN_FLIGHT
	)
		or (state == Constants.RoundState.BALL_IN_FLIGHT and nextState == Constants.RoundState.PRE_SHOT)
		or (state == Constants.RoundState.BALL_IN_FLIGHT and nextState == Constants.RoundState.HOLE_COMPLETE)
		or (state == Constants.RoundState.BALL_IN_FLIGHT and nextState == Constants.RoundState.ROUND_COMPLETE)
		or (state == Constants.RoundState.HOLE_COMPLETE and nextState == Constants.RoundState.PRE_SHOT)
		or (
			state == Constants.RoundState.HOLE_COMPLETE
			and nextState == Constants.RoundState.ROUND_COMPLETE
		)

	if not valid then
		return false, ("invalid transition %s -> %s"):format(state, nextState)
	end

	round.state = nextState
	return true, nil
end

function RoundService.beginShot(round: any): (boolean, string?)
	if round.ball.moving or round.state == Constants.RoundState.BALL_IN_FLIGHT then
		return false, Constants.Rejection.BALL_MOVING
	end
	if round.state ~= Constants.RoundState.PRE_SHOT then
		return false, Constants.Rejection.INVALID_ROUND
	end

	local ok, reason = RoundService.transition(round, Constants.RoundState.BALL_IN_FLIGHT)
	if not ok then
		return false, reason
	end

	round.ball.moving = true
	return true, nil
end

function RoundService.finishShot(round: any, shotResult: any): (boolean, any)
	if round.state ~= Constants.RoundState.BALL_IN_FLIGHT then
		return false, Constants.Rejection.INVALID_ROUND
	end

	local hole = RoundService.currentHole(round)
	local holed =
		GreenModel.isHoled(hole, shotResult.finalPosition, math.max(0, shotResult.rollYards))
	local score =
		ScoreService.recordShot(round.scorecard, round.holeIndex, shotResult.finalSurface, holed)
	local penaltyLie = shotResult.finalSurface == Constants.Surface.WATER
		or shotResult.finalSurface == Constants.Surface.OUT_OF_BOUNDS
	local ballAtRest = {
		roundId = round.id,
		holeIndex = round.holeIndex,
		position = copyPosition(shotResult.finalPosition),
		surface = shotResult.finalSurface,
		moving = false,
		holed = holed,
	}

	if holed then
		ScoreService.completeHole(round.scorecard, round.holeIndex)
		RoundAuditService.recordHoleCompleted(round.id, {
			holeIndex = round.holeIndex,
			par = hole.par,
			total = ScoreService.holeTotal(score),
			scorecardTotal = ScoreService.total(round.scorecard),
		})
		AnalyticsService.log(nil, "hole_completed", {
			roundId = round.id,
			playerUserId = round.playerUserId,
			holeIndex = round.holeIndex,
			par = hole.par,
			total = ScoreService.holeTotal(score),
			scorecardTotal = ScoreService.total(round.scorecard),
		})
		if round.holeIndex >= round.holeCount then
			round.ball = {
				position = copyPosition(hole.pin),
				surface = Constants.Surface.GREEN,
				moving = false,
			}
			round.state = Constants.RoundState.ROUND_COMPLETE
			round.completed = true
			round.completedAtUnix = os.time()
		else
			round.state = Constants.RoundState.HOLE_COMPLETE
			round.holeIndex += 1
			local nextHole = RoundService.currentHole(round)
			round.ball = {
				position = copyPosition(nextHole.tee),
				surface = Constants.Surface.TEE,
				moving = false,
			}
			round.state = Constants.RoundState.PRE_SHOT
		end
	elseif penaltyLie then
		round.ball = {
			position = copyPosition(round.ball.position),
			surface = Constants.Surface.ROUGH,
			moving = false,
		}
		round.state = Constants.RoundState.PRE_SHOT
	else
		round.ball = {
			position = copyPosition(shotResult.finalPosition),
			surface = shotResult.finalSurface,
			moving = false,
		}
		round.state = Constants.RoundState.PRE_SHOT
	end

	return true,
		{
			holed = holed,
			score = score,
			ballAtRest = ballAtRest,
			scorecard = ScoreService.snapshot(round.scorecard),
			round = RoundService.snapshot(round),
		}
end

function RoundService.holeSnapshot(round: any)
	local hole = RoundService.currentHole(round)
	return {
		roundId = round.id,
		holeIndex = round.holeIndex,
		par = hole.par,
		yardage = hole.yardage,
		pin = copyPosition(hole.pin),
		tee = copyPosition(hole.tee),
	}
end

function RoundService.snapshot(round: any)
	return {
		roundId = round.id,
		courseId = round.courseId,
		mode = round.mode,
		ranked = round.ranked,
		state = round.state,
		holeIndex = round.holeIndex,
		holeCount = round.holeCount,
		currentTurnUserId = round.currentTurnUserId,
		ball = {
			position = copyPosition(round.ball.position),
			surface = round.ball.surface,
			moving = round.ball.moving,
		},
		scorecard = ScoreService.snapshot(round.scorecard),
	}
end

return RoundService
