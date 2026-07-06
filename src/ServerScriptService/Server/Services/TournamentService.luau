--!strict

local TournamentConfig =
	require("../../../ReplicatedStorage/Shared/GolfPro/Config/TournamentConfig")
local DurableStore = require("../Data/DurableStore")
local CosmeticService = require("./CosmeticService")
local LeaderboardService = require("./LeaderboardService")
local AnalyticsService = require("./AnalyticsService")

local TournamentService = {}

local TOURNAMENT_ATTEMPT_STORE_NAME = "GolfProTournamentAttempts_v1"
local TOURNAMENT_BOARD_STORE_NAME = "GolfProTournamentBoards_v1"
local TOURNAMENT_BOARD_META_STORE_NAME = "GolfProTournamentRows_v1"
local started = false
local attempts: { [string]: { [number]: number } } = {}
local leaderboards: { [string]: { any } } = {}

local function copy(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local out = {}
	for key, child in value do
		out[key] = copy(child)
	end
	return out
end

local function playerUserId(player: any): number
	local ok, value = pcall(function()
		return player.UserId
	end)
	return if ok and type(value) == "number" then value else 0
end

local function playerName(player: any): string
	local ok, value = pcall(function()
		return player.Name
	end)
	return if ok and type(value) == "string" then value else "Unknown"
end

local function net(): any?
	if game == nil then
		return nil
	end
	local ok, service = pcall(function()
		return require("../../../ReplicatedStorage/Shared/Net")
	end)
	return if ok then service else nil
end

local function attemptStore(): any?
	return DurableStore.getDataStore(TOURNAMENT_ATTEMPT_STORE_NAME)
end

local function boardStore(eventId: string): any?
	return DurableStore.getOrderedDataStore(
		(TOURNAMENT_BOARD_STORE_NAME .. "_" .. eventId):sub(1, 50)
	)
end

local function boardMetaStore(): any?
	return DurableStore.getDataStore(TOURNAMENT_BOARD_META_STORE_NAME)
end

local function attemptKey(eventId: string, userId: number): string
	return ("%s|%d"):format(eventId, userId)
end

local function rowKey(eventId: string, row: any): string
	return ("%s|%s|%s"):format(
		eventId,
		tostring(row.playerUserId or 0),
		tostring(row.roundId or "round")
	)
end

local function attemptsUsed(eventId: string, player: any): number
	local byEvent = attempts[eventId]
	local userId = playerUserId(player)
	if byEvent ~= nil and byEvent[userId] ~= nil then
		return byEvent[userId]
	end

	local store = attemptStore()
	if store ~= nil then
		local ok, stored = pcall(function()
			return store:GetAsync(attemptKey(eventId, userId))
		end)
		if ok and type(stored) == "number" then
			attempts[eventId] = attempts[eventId] or {}
			attempts[eventId][userId] = stored
			return stored
		end
	end

	return 0
end

local function eventSnapshot(event: any, player: any?): any
	return {
		id = event.id,
		displayName = event.displayName,
		courseId = event.courseId,
		courseName = event.courseName,
		mode = event.mode,
		ranked = event.ranked == true,
		maxAttempts = event.maxAttempts,
		attemptsUsed = if player ~= nil then attemptsUsed(event.id, player) else 0,
		rewardCosmeticId = event.rewardCosmeticId,
		rewardDescription = event.rewardDescription,
		prizePolicy = copy(event.prizePolicy),
	}
end

local function sortedRows(eventId: string): { any }
	local rows = leaderboards[eventId] or {}
	table.sort(rows, function(left: any, right: any): boolean
		if left.score ~= right.score then
			return left.score < right.score
		end
		return left.packedScore < right.packedScore
	end)
	return rows
end

local function emitUpdate(player: any)
	local service = net()
	if service ~= nil and typeof(player) == "Instance" and player:IsA("Player") then
		service.fireClient("TournamentUpdated", player, {
			events = TournamentService.getActiveEvents(player),
		})
	end
end

function TournamentService.start()
	if started then
		return
	end
	started = true

	local service = net()
	assert(service ~= nil, "Net is required")

	service.setServerInvoke("RequestTournamentEvents", function(player: Player)
		return TournamentService.getActiveEvents(player)
	end)
	service.setServerInvoke("RequestTournamentLeaderboard", function(_player: Player, payload: any)
		payload = if type(payload) == "table" then payload else {}
		return TournamentService.getEventLeaderboard(
			payload.eventId or "weekend_open_001",
			payload.cursor
		)
	end)
end

function TournamentService.resetForTests()
	started = false
	attempts = {}
	leaderboards = {}
end

function TournamentService.getActiveEvents(player: any?): { any }
	local events = {}
	for _, event: any in TournamentConfig.activeEvents() do
		table.insert(events, eventSnapshot(event, player))
	end
	return events
end

function TournamentService.canSubmitAttempt(
	player: any,
	eventId: string,
	result: any
): (boolean, any)
	local event = TournamentConfig.get(eventId)
	if event == nil then
		return false, "unknown_event"
	end
	if type(result) ~= "table" then
		return false, "invalid_result"
	end
	if result.debug == true or result.debugMode == true then
		return false, "debug_result"
	end
	if result.ranked ~= true or result.completed ~= true or result.holeCount ~= 18 then
		return false, "invalid_ranked_completion"
	end
	if result.courseId ~= nil and result.courseId ~= event.courseId then
		return false, "wrong_course"
	end
	if result.mode ~= nil and result.mode ~= event.mode then
		return false, "wrong_mode"
	end
	if attemptsUsed(eventId, player) >= event.maxAttempts then
		return false, "max_attempts"
	end
	return true, event
end

function TournamentService.submitAttempt(player: any, eventId: string, result: any): (boolean, any)
	local ok, eventOrReason = TournamentService.canSubmitAttempt(player, eventId, result)
	if not ok then
		return false, eventOrReason
	end
	attempts[eventId] = attempts[eventId] or {}
	local userId = playerUserId(player)
	attempts[eventId][userId] = (attempts[eventId][userId] or 0) + 1

	local score = tonumber(result.totalScore or result.score or result.total) or 9999
	local row = {
		playerUserId = result.playerUserId or userId,
		playerName = result.playerName or playerName(player),
		score = score,
		packedScore = LeaderboardService.packScore({
			totalScore = score,
			completedAtUnix = result.completedAtUnix or os.time(),
		}),
		roundId = result.roundId,
		completedAtUnix = result.completedAtUnix or os.time(),
		attemptNumber = attempts[eventId][userId],
	}
	leaderboards[eventId] = leaderboards[eventId] or {}
	local orderedStore = boardStore(eventId)
	local metaStore = boardMetaStore()
	if orderedStore ~= nil and metaStore ~= nil then
		local keyForRow = rowKey(eventId, row)
		local storeOk = pcall(function()
			orderedStore:SetAsync(keyForRow, row.packedScore)
			metaStore:SetAsync(keyForRow, row)
			local store = attemptStore()
			if store ~= nil then
				store:SetAsync(attemptKey(eventId, userId), attempts[eventId][userId])
			end
		end)
		if not storeOk then
			attempts[eventId][userId] -= 1
			return false, "tournament_store_failed"
		end
	end
	table.insert(leaderboards[eventId], row)
	sortedRows(eventId)
	local rewardOk, reward = TournamentService.grantEventRewards(player, eventId)
	AnalyticsService.log(player, "tournament_attempt_submitted", {
		eventId = eventId,
		roundId = row.roundId,
		score = row.score,
		attemptNumber = row.attemptNumber,
		rewardGranted = rewardOk,
	})
	emitUpdate(player)
	return true,
		{
			row = row,
			attemptsUsed = attempts[eventId][userId],
			rewardGranted = rewardOk,
			reward = reward,
		}
end

function TournamentService.getEventLeaderboard(eventId: string, cursor: any?): any
	local pageSize = math.clamp(tonumber(cursor and cursor.pageSize) or 10, 1, 50)
	local startIndex = math.max(tonumber(cursor and cursor.startIndex) or 1, 1)
	local orderedStore = boardStore(eventId)
	local metaStore = boardMetaStore()
	if orderedStore ~= nil and metaStore ~= nil then
		local ok, page = pcall(function()
			return orderedStore:GetSortedAsync(true, pageSize)
		end)
		if ok and page ~= nil then
			local pageRows = {}
			for index, entry in page:GetCurrentPage() do
				local metaOk, meta = pcall(function()
					return metaStore:GetAsync(entry.key)
				end)
				local row = if metaOk and type(meta) == "table" then meta else {}
				table.insert(pageRows, {
					rank = index,
					playerUserId = row.playerUserId,
					playerName = row.playerName or "Unknown",
					score = row.score or math.floor((tonumber(entry.value) or 0) / 1000000000),
					roundId = row.roundId,
					attemptNumber = row.attemptNumber,
				})
			end
			return {
				eventId = eventId,
				rows = pageRows,
				nextCursor = nil,
			}
		end
	end

	local rows = sortedRows(eventId)
	local pageRows = {}
	for index = startIndex, math.min(#rows, startIndex + pageSize - 1) do
		local row = rows[index]
		table.insert(pageRows, {
			rank = index,
			playerUserId = row.playerUserId,
			playerName = row.playerName,
			score = row.score,
			roundId = row.roundId,
			attemptNumber = row.attemptNumber,
		})
	end
	return {
		eventId = eventId,
		rows = pageRows,
		nextCursor = if startIndex + pageSize <= #rows
			then { startIndex = startIndex + pageSize, pageSize = pageSize }
			else nil,
	}
end

function TournamentService.grantEventRewards(player: any, eventId: string): (boolean, any)
	local event = TournamentConfig.get(eventId)
	if event == nil then
		return false, "unknown_event"
	end
	if event.rewardCosmeticId == nil then
		return false, "no_reward"
	end
	return CosmeticService.grantCosmetic(player, event.rewardCosmeticId, "tournament_" .. eventId)
end

return TournamentService
