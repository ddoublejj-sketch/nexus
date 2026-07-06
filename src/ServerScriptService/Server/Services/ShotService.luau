--!strict

local ClubRegistry = require("../../../ReplicatedStorage/Shared/GolfPro/Clubs/ClubRegistry")
local Constants = require("../../../ReplicatedStorage/Shared/GolfPro/Constants")
local PayloadValidators =
	require("../../../ReplicatedStorage/Shared/GolfPro/Network/PayloadValidators")
local GreenModel = require("../../../ReplicatedStorage/Shared/GolfPro/Simulation/GreenModel")
local ShotMath = require("../../../ReplicatedStorage/Shared/GolfPro/Simulation/ShotMath")
local Types = require("../../../ReplicatedStorage/Shared/GolfPro/Types")
local WindModel = require("../../../ReplicatedStorage/Shared/GolfPro/Simulation/WindModel")
local MysteryRangeService = require("./MysteryRangeService")
local ResultsService = require("./ResultsService")
local RoundAuditService = require("./RoundAuditService")
local RoundService = require("./RoundService")
local ScrambleService = require("./ScrambleService")
local AnalyticsService = require("./AnalyticsService")

type ShotResult = Types.ShotResult
type Vector2Yards = Types.Vector2Yards

local ShotService = {}

local RATE_LIMIT_SECONDS = 0.25
local started = false

local function playerUserId(player: any): number
	local ok, value = pcall(function()
		return player.UserId
	end)

	if ok and type(value) == "number" then
		return value
	end

	return 0
end

local function copyPosition(position: Vector2Yards): Vector2Yards
	return {
		x = position.x,
		y = position.y,
	}
end

local function buildPath(shotId: string, startPosition: Vector2Yards, result: ShotResult)
	local endPosition = result.finalPosition
	local mid = {
		x = (startPosition.x + endPosition.x) * 0.5,
		y = (startPosition.y + endPosition.y) * 0.5,
		z = math.max(8, result.carryYards * 0.12),
	}

	return {
		shotId = shotId,
		points = {
			{ x = startPosition.x, y = startPosition.y, z = 0 },
			mid,
			{ x = endPosition.x, y = endPosition.y, z = 0 },
		},
		result = result,
	}
end

local function clubAllowedFromLie(club, surface: string, shotType: string): (boolean, string?)
	if surface == Constants.Surface.WATER or surface == Constants.Surface.OUT_OF_BOUNDS then
		return false, Constants.Rejection.INVALID_LIE
	end
	if
		surface == Constants.Surface.GREEN
		and club.category ~= "putter"
		and shotType ~= Constants.ShotType.CHIP
	then
		return false, Constants.Rejection.INVALID_LIE
	end
	if surface == Constants.Surface.BUNKER and club.category == "putter" then
		return false, Constants.Rejection.INVALID_CLUB
	end

	return true, nil
end

local function submitScrambleShot(
	player: any,
	intent: any,
	userId: number,
	now: number?
): (boolean, any)
	local contextOk, context = ScrambleService.getShotContext(player, intent.roundId)
	if not contextOk then
		return false, if context == "round not found" then Constants.Rejection.NO_ROUND else context
	end
	if intent.holeIndex ~= context.holeIndex then
		return false, Constants.Rejection.NOT_TURN
	end
	if context.shotState.nonces[intent.clientShotNonce] then
		return false, Constants.Rejection.DUPLICATE_NONCE
	end

	local shotTime = now or os.clock()
	if
		context.shotState.lastShotAt > 0
		and shotTime - context.shotState.lastShotAt < RATE_LIMIT_SECONDS
	then
		return false, Constants.Rejection.RATE_LIMIT
	end

	local club = ClubRegistry.get(intent.clubId)
	if club == nil then
		return false, Constants.Rejection.INVALID_CLUB
	end

	local lieOk, lieReason = clubAllowedFromLie(club, context.ball.surface, intent.shotType)
	if not lieOk then
		return false, lieReason or Constants.Rejection.INVALID_LIE
	end

	local startPosition = copyPosition(context.ball.position)
	local result = ShotMath.solve(
		club :: any,
		context.hole,
		startPosition,
		context.ball.surface,
		intent,
		WindModel.daily(context.courseId, context.holeIndex)
	)
	local shotId = ("%s:%s"):format(context.roundId, intent.clientShotNonce)
	context.shotState.nonces[intent.clientShotNonce] = true
	context.shotState.lastShotAt = shotTime
	local holed =
		GreenModel.isHoled(context.hole, result.finalPosition, math.max(0, result.rollYards))
	local optionOk, optionOrReason = ScrambleService.recordShotOption(context.roundId, player, {
		shotId = shotId,
		result = result,
		position = result.finalPosition,
		surface = result.finalSurface,
		holed = holed,
	})
	if not optionOk then
		return false, optionOrReason
	end

	return true,
		{
			shotId = shotId,
			result = result,
			path = buildPath(shotId, startPosition, result),
			ballAtRest = {
				roundId = context.roundId,
				holeIndex = context.holeIndex,
				position = copyPosition(result.finalPosition),
				surface = result.finalSurface,
				moving = false,
				holed = holed,
			},
			round = {
				roundId = context.roundId,
				courseId = context.courseId,
				mode = Constants.Mode.SCRAMBLE_2V2,
				state = Constants.RoundState.PRE_SHOT,
				holeIndex = context.holeIndex,
				holeCount = context.holeCount,
				currentTurnUserId = userId,
				ball = {
					position = copyPosition(result.finalPosition),
					surface = result.finalSurface,
					moving = false,
				},
			},
			scorecard = { holes = {}, total = 0, completed = false },
			holed = false,
			scrambleOption = optionOrReason,
		}
end

function ShotService.resetForTests()
	started = false
end

function ShotService.submitShot(player: any, intent: any, now: number?): (boolean, any)
	local validPayload, payloadReason = PayloadValidators.validateShotIntent(intent)
	if not validPayload then
		return false, Constants.Rejection.INVALID_PAYLOAD .. ":" .. (payloadReason or "invalid")
	end

	local userId = playerUserId(player)
	if intent.playerUserId ~= userId then
		return false, Constants.Rejection.NOT_TURN
	end

	local round = RoundService.getRound(intent.roundId)
	if round == nil or round.playerUserId ~= userId then
		if round == nil then
			return submitScrambleShot(player, intent, userId, now)
		end
		return false, Constants.Rejection.NO_ROUND
	end
	if round.ball.moving or round.state == Constants.RoundState.BALL_IN_FLIGHT then
		return false, Constants.Rejection.BALL_MOVING
	end
	if round.currentTurnUserId ~= userId or intent.holeIndex ~= round.holeIndex then
		return false, Constants.Rejection.NOT_TURN
	end
	if round.nonces[intent.clientShotNonce] then
		return false, Constants.Rejection.DUPLICATE_NONCE
	end

	local shotTime = now or os.clock()
	if round.lastShotAt > 0 and shotTime - round.lastShotAt < RATE_LIMIT_SECONDS then
		return false, Constants.Rejection.RATE_LIMIT
	end

	local club = ClubRegistry.get(intent.clubId)
	if club == nil then
		return false, Constants.Rejection.INVALID_CLUB
	end

	local lieOk, lieReason = clubAllowedFromLie(club, round.ball.surface, intent.shotType)
	if not lieOk then
		return false, lieReason or Constants.Rejection.INVALID_LIE
	end

	local startPosition = copyPosition(round.ball.position)
	local begun, beginReason = RoundService.beginShot(round)
	if not begun then
		return false, beginReason or Constants.Rejection.INVALID_ROUND
	end

	local result = ShotMath.solve(
		club :: any,
		RoundService.currentHole(round),
		startPosition,
		round.ball.surface,
		intent,
		WindModel.daily(round.courseId, round.holeIndex)
	)
	local shotId = ("%s:%s"):format(round.id, intent.clientShotNonce)
	round.nonces[intent.clientShotNonce] = true
	round.lastShotAt = shotTime

	local finished, finishPayload = RoundService.finishShot(round, result)
	if not finished then
		return false, finishPayload
	end

	if round.courseId == Constants.DEFAULT_PRACTICE_COURSE_ID then
		local rangeOk, rangeResult = MysteryRangeService.recordPracticeShot(player, result)
		if rangeOk then
			AnalyticsService.log(player, "practice_shot_hit", {
				roundId = round.id,
				holeIndex = round.holeIndex,
				targetId = rangeResult and rangeResult.targetId,
				zoneId = rangeResult and rangeResult.zoneId,
			})
		end
	end

	RoundAuditService.recordShot(round.id, {
		shotId = shotId,
		holeIndex = intent.holeIndex,
		playerUserId = userId,
		clubId = intent.clubId,
		shotType = intent.shotType,
		power01 = intent.power01,
		accuracy01 = intent.accuracy01,
		startPosition = startPosition,
		finalPosition = copyPosition(result.finalPosition),
		finalSurface = result.finalSurface,
		holed = finishPayload.holed,
		totalScore = finishPayload.scorecard.total,
	})

	local completionPayload = nil
	if finishPayload.round.state == Constants.RoundState.ROUND_COMPLETE then
		completionPayload = ResultsService.completeRound(player, round)
	end

	return true,
		{
			shotId = shotId,
			result = result,
			path = buildPath(shotId, startPosition, result),
			ballAtRest = finishPayload.ballAtRest,
			round = finishPayload.round,
			scorecard = finishPayload.scorecard,
			holed = finishPayload.holed,
			completion = completionPayload,
		}
end

function ShotService.start()
	if started then
		return
	end

	started = true
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Net = require(ReplicatedStorage.Shared.Net)

	Net.onServerEvent("SubmitShotIntent", function(player: Player, intent: any)
		local ok, payload = ShotService.submitShot(player, intent, os.clock())
		if not ok then
			Net.fireClient("ShotRejected", player, {
				reasonCode = payload,
				roundId = intent.roundId,
			})
			return
		end

		Net.fireClient("ShotAccepted", player, { shotId = payload.shotId })
		Net.fireClient("BallPath", player, payload.path)
		Net.fireClient("BallAtRest", player, payload.ballAtRest)
		Net.fireClient("RoundStateUpdated", player, payload.round)
		Net.fireClient("ScorecardUpdated", player, payload.scorecard)
		if payload.round.state == Constants.RoundState.ROUND_COMPLETE then
			Net.fireClient("RoundCompleted", player, payload.completion)
			if payload.completion.courseRecord.changed then
				Net.fireClient("CourseRecordUpdated", player, payload.completion.courseRecord)
			end
		elseif payload.holed then
			local round = RoundService.getRound(payload.round.roundId)
			if round ~= nil then
				Net.fireClient("HoleStarted", player, RoundService.holeSnapshot(round))
			end
		end
	end)

	print("[Nexus] Golf Pro ShotService online")
end

return ShotService
