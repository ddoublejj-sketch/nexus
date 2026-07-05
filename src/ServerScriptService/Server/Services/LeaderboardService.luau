--!strict

local Constants = require("../../../ReplicatedStorage/Shared/GolfPro/Constants")
local DataStoreKeys = require("../Data/DataStoreKeys")

local LeaderboardService = {}

local boards: { [string]: { any } } = {}
local started = false

local function sortedBoard(board: { any }): { any }
	table.sort(board, function(left, right)
		if left.score ~= right.score then
			return left.score < right.score
		end
		return left.completedAtUnix < right.completedAtUnix
	end)
	return board
end

local function contextFromRequest(payload: any): any
	payload = if type(payload) == "table" then payload else {}
	return {
		courseId = payload.courseId or Constants.DEFAULT_COURSE_ID,
		courseVersion = payload.courseVersion or "v1",
		mode = payload.mode or Constants.Mode.SOLO_STROKE_18,
		teeSet = payload.teeSet or Constants.DEFAULT_TEE_SET,
		pinSet = payload.pinSet or Constants.DEFAULT_PIN_SET,
		rulesetId = payload.rulesetId or Constants.DEFAULT_RULESET_ID,
		physicsVersion = payload.physicsVersion or Constants.PHYSICS_VERSION,
	}
end

function LeaderboardService.start()
	if started then
		return
	end
	started = true

	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Net = require(ReplicatedStorage.Shared.Net)
	Net.setServerInvoke("RequestLeaderboardPage", function(_player: Player, payload: any)
		payload = if type(payload) == "table" then payload else {}
		return LeaderboardService.getPage(contextFromRequest(payload), payload.cursor)
	end)
end

function LeaderboardService.resetForTests()
	boards = {}
	started = false
end

function LeaderboardService.packScore(roundResult: any): number
	local score = tonumber(roundResult.totalScore or roundResult.score or roundResult.total) or 9999
	local completedAtUnix = tonumber(roundResult.completedAtUnix) or 0
	return score * 1000000000 + math.min(completedAtUnix, 999999999)
end

function LeaderboardService.submitRound(context: any, roundResult: any): (boolean, any)
	if
		roundResult.ranked ~= true
		or roundResult.completed ~= true
		or roundResult.holeCount ~= 18
	then
		return false, "invalid_ranked_completion"
	end

	local key = DataStoreKeys.leaderboard(context)
	local board = boards[key] or {}
	boards[key] = board

	local row = {
		playerUserId = roundResult.playerUserId,
		playerName = roundResult.playerName or "Unknown",
		score = tonumber(roundResult.totalScore or roundResult.score or roundResult.total),
		packedScore = LeaderboardService.packScore(roundResult),
		roundId = roundResult.roundId,
		completedAtUnix = tonumber(roundResult.completedAtUnix) or os.time(),
	}
	table.insert(board, row)
	sortedBoard(board)

	return true, row
end

function LeaderboardService.getPage(context: any, cursor: any): any
	local key = DataStoreKeys.leaderboard(context)
	local pageSize = math.clamp(tonumber(cursor and cursor.pageSize) or 10, 1, 50)
	local startIndex = math.max(tonumber(cursor and cursor.startIndex) or 1, 1)
	local board = sortedBoard(boards[key] or {})
	local rows = {}

	for index = startIndex, math.min(#board, startIndex + pageSize - 1) do
		local row = board[index]
		table.insert(rows, {
			rank = index,
			playerUserId = row.playerUserId,
			playerName = row.playerName,
			score = row.score,
			roundId = row.roundId,
		})
	end

	return {
		key = key,
		rows = rows,
		nextCursor = if startIndex + pageSize <= #board
			then { startIndex = startIndex + pageSize, pageSize = pageSize }
			else nil,
	}
end

function LeaderboardService.getPlayerRank(context: any, playerUserId: number): number?
	local board = sortedBoard(boards[DataStoreKeys.leaderboard(context)] or {})
	for index, row in board do
		if row.playerUserId == playerUserId then
			return index
		end
	end
	return nil
end

return LeaderboardService
