--!strict

local Constants = require("../../../ReplicatedStorage/Shared/GolfPro/Constants")
local DataStoreKeys = require("../Data/DataStoreKeys")
local LeaderboardService = require("./LeaderboardService")
local RecordService = require("./RecordService")
local RoundAuditService = require("./RoundAuditService")
local AnalyticsService = require("./AnalyticsService")

local ResultsService = {}

local started = false

local function contextFromRound(roundState: any): any
	return {
		courseId = roundState.courseId,
		courseVersion = roundState.courseVersion or "v1",
		mode = roundState.mode,
		teeSet = roundState.teeSet or Constants.DEFAULT_TEE_SET,
		pinSet = roundState.pinSet or Constants.DEFAULT_PIN_SET,
		rulesetId = roundState.rulesetId or Constants.DEFAULT_RULESET_ID,
		physicsVersion = roundState.physicsVersion or Constants.PHYSICS_VERSION,
	}
end

local function fillPlayerFields(player: any?, result: any)
	if player == nil then
		return
	end

	if result.playerUserId == nil then
		local ok, value = pcall(function()
			return player.UserId
		end)
		if ok then
			result.playerUserId = value
		end
	end

	if result.playerName == nil then
		local ok, value = pcall(function()
			return player.Name
		end)
		if ok then
			result.playerName = value
		end
	end
end

local function updateProfile(player: any?, context: any, result: any, recordResult: any): boolean
	if player == nil then
		return false
	end

	local ok, DataService = pcall(function()
		return require(script.Parent.DataService)
	end)
	if not ok then
		return false
	end

	DataService.recordRoundCompleted(player, result)
	DataService.upsertBestRound(
		player,
		DataStoreKeys.playerBest(result.playerUserId or 0, context),
		result
	)
	if recordResult.changed == true and recordResult.current ~= nil then
		DataService.addCourseRecordHeld(player, recordResult.current.key)
	end

	return true
end

function ResultsService.start()
	if started then
		return
	end
	started = true
end

function ResultsService.resetForTests()
	started = false
end

function ResultsService.buildRoundResults(roundState: any): any
	local scorecard = roundState.scorecard or {}
	local totalScore = tonumber(scorecard.total or roundState.totalScore or roundState.score) or 0
	local par = 0
	for _, hole in scorecard.holes or {} do
		par += tonumber(hole.par) or 0
	end

	local completed = roundState.completed ~= false
	if scorecard.completed == false then
		completed = false
	end

	return {
		roundId = roundState.roundId or roundState.id,
		playerUserId = roundState.playerUserId,
		playerName = roundState.playerName,
		courseId = roundState.courseId,
		mode = roundState.mode,
		ranked = roundState.ranked == true,
		completed = completed,
		holeCount = roundState.holeCount,
		totalScore = totalScore,
		toPar = totalScore - par,
		completedAtUnix = roundState.completedAtUnix or os.time(),
	}
end

function ResultsService.completeRound(playerOrRoundState: any, maybeRoundState: any?): any
	local player = if maybeRoundState == nil then nil else playerOrRoundState
	local roundState = if maybeRoundState == nil then playerOrRoundState else maybeRoundState
	local context = contextFromRound(roundState)
	local result = ResultsService.buildRoundResults(roundState)
	fillPlayerFields(player, result)

	local auditCompleteOk = RoundAuditService.completeRound(result.roundId, result)
	local auditOk = result.ranked ~= true
		or (
			auditCompleteOk == true
			and RoundAuditService.isRankedCompletionAuditable(result.roundId)
		)
	local leaderboardOk, leaderboardResult
	local recordResult
	if auditOk then
		leaderboardOk, leaderboardResult = LeaderboardService.submitRound(context, result)
		recordResult = RecordService.tryUpdateCourseRecord(context, result)
	else
		leaderboardOk = false
		leaderboardResult = "audit_not_clean"
		recordResult = {
			changed = false,
			reason = "audit_not_clean",
			current = RecordService.getCourseRecord(context),
		}
	end
	local profileUpdated = updateProfile(player, context, result, recordResult)
	AnalyticsService.log(player, "round_completed", {
		roundId = result.roundId,
		courseId = result.courseId,
		mode = result.mode,
		totalScore = result.totalScore,
	})
	if result.ranked == true then
		AnalyticsService.log(player, "ranked_round_completed", {
			roundId = result.roundId,
			courseId = result.courseId,
			mode = result.mode,
			totalScore = result.totalScore,
		})
	end
	AnalyticsService.log(player, "leaderboard_submit", {
		roundId = result.roundId,
		accepted = leaderboardOk,
		reason = if leaderboardOk then nil else leaderboardResult,
	})
	if recordResult.changed == true then
		AnalyticsService.log(
			player,
			if recordResult.reason == "record_beaten"
				then "course_record_beaten"
				else "course_record_set",
			{
				roundId = result.roundId,
				score = result.totalScore,
				recordKey = recordResult.current and recordResult.current.key,
			}
		)
	end

	return {
		context = context,
		result = result,
		profileUpdated = profileUpdated,
		leaderboard = if leaderboardOk then leaderboardResult else nil,
		leaderboardAccepted = leaderboardOk,
		leaderboardRejectedReason = if leaderboardOk then nil else leaderboardResult,
		courseRecord = recordResult,
		courseRecordDisplay = RecordService.getDisplayRecord(context),
	}
end

return ResultsService
