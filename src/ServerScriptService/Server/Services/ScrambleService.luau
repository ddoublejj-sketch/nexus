--!strict

local Constants = require("../../../ReplicatedStorage/Shared/GolfPro/Constants")
local CourseRegistry = require("../../../ReplicatedStorage/Shared/GolfPro/Courses/CourseRegistry")
local PayloadValidators =
	require("../../../ReplicatedStorage/Shared/GolfPro/Network/PayloadValidators")

local ScrambleService = {}

local roundsById: { [string]: any } = {}
local roundCounter = 0
local started = false
local net: any = nil
local playersService: any = nil

local function playerUserId(player: any): number
	local ok, value = pcall(function()
		return player.UserId
	end)

	if ok and type(value) == "number" then
		return value
	end

	return 0
end

local function copyPosition(position: any): any
	return {
		x = position.x,
		y = position.y,
	}
end

local function distance(a: any, b: any): number
	local dx = (a.x or 0) - (b.x or 0)
	local dy = (a.y or 0) - (b.y or 0)
	return math.sqrt(dx * dx + dy * dy)
end

local function nextRoundId(partyId: string): string
	roundCounter += 1
	return ("scramble_%s_%d"):format(partyId, roundCounter)
end

local function optionSnapshot(option: any): any
	return {
		ballId = option.ballId,
		playerUserId = option.playerUserId,
		teamId = option.teamId,
		position = copyPosition(option.position),
		surface = option.surface,
		holed = option.holed,
		penalty = option.penalty,
		distanceToPinYards = option.distanceToPinYards,
	}
end

local function voteSnapshot(voteState: any): any
	local options = {}
	for index, option in voteState.options do
		options[index] = optionSnapshot(option)
	end

	local votes = table.clone(voteState.votesByUserId)

	return {
		roundId = voteState.roundId,
		holeIndex = voteState.holeIndex,
		shotCycle = voteState.shotCycle,
		teamId = voteState.teamId,
		options = options,
		votesByUserId = votes,
		selectedBallId = voteState.selectedBallId,
		expiresAtUnix = voteState.expiresAtUnix,
	}
end

local function safeFireClient(remoteName: string, player: any, ...)
	if net == nil then
		return
	end

	pcall(function(...)
		net.fireClient(remoteName, player, ...)
	end, ...)
end

local function messagePlayer(player: any, reason: string)
	if net == nil then
		return
	end

	local ok = pcall(function()
		net.fireClient("SystemMessage", player, reason, { source = "ScrambleService" })
	end)
	if not ok then
		safeFireClient("ShotRejected", player, { reasonCode = reason })
	end
end

local function fireVotePayload(round: any, teamId: string, payload: any)
	if playersService == nil then
		return
	end

	for _, userId in round.teams[teamId] do
		local player = playersService:GetPlayerByUserId(userId)
		if player ~= nil then
			safeFireClient("ScrambleVoteUpdated", player, payload)
		end
	end
end

local function fireVoteState(round: any, teamId: string)
	local voteState = round.voteStatesByTeam[teamId]
	if voteState ~= nil then
		fireVotePayload(round, teamId, voteSnapshot(voteState))
	end
end

local function userTeam(round: any, userId: number): string?
	for _, teamId in { Constants.TeamId.RED, Constants.TeamId.BLUE } do
		for _, memberUserId in round.teams[teamId] do
			if memberUserId == userId then
				return teamId
			end
		end
	end

	return nil
end

local function optionById(options: { any }, ballId: string): any?
	for _, option in options do
		if option.ballId == ballId then
			return option
		end
	end

	return nil
end

local function currentHole(round: any): any
	return round.course.holes[round.holeIndex]
end

local function penaltyForSurface(surface: string): boolean
	return surface == Constants.Surface.WATER or surface == Constants.Surface.OUT_OF_BOUNDS
end

local function ensureVoteState(round: any, teamId: string): any
	local existing = round.voteStatesByTeam[teamId]
	if existing ~= nil then
		existing.options = round.pendingOptionsByTeam[teamId]
		return existing
	end

	local voteState = {
		roundId = round.roundId,
		holeIndex = round.holeIndex,
		shotCycle = round.shotCycle,
		teamId = teamId,
		options = round.pendingOptionsByTeam[teamId],
		votesByUserId = {},
		selectedBallId = nil,
		expiresAtUnix = os.time() + Constants.SCRAMBLE_VOTE_SECONDS,
	}
	round.voteStatesByTeam[teamId] = voteState

	if task ~= nil and task.delay ~= nil then
		task.delay(Constants.SCRAMBLE_VOTE_SECONDS, function()
			local latest = roundsById[round.roundId]
			local current = latest and latest.voteStatesByTeam[teamId]
			if current == voteState and current.selectedBallId == nil then
				ScrambleService.autoSelectBestBall(round.roundId, teamId)
			end
		end)
	end

	return voteState
end

local function allTeamVotesSame(round: any, voteState: any, ballId: string): boolean
	for _, userId in round.teams[voteState.teamId] do
		if voteState.votesByUserId[userId] ~= ballId then
			return false
		end
	end

	return true
end

local function betterOption(option: any, best: any): boolean
	if option.holed ~= best.holed then
		return option.holed
	end
	if option.penalty ~= best.penalty then
		return not option.penalty
	end

	return option.distanceToPinYards < best.distanceToPinYards
end

local function chooseBest(options: { any }): any?
	local best = nil
	for _, option in options do
		if best == nil or betterOption(option, best) then
			best = option
		end
	end

	return best
end

local function bothTeamsHoled(round: any): boolean
	return round.teamBallPositions[Constants.TeamId.RED].holed == true
		and round.teamBallPositions[Constants.TeamId.BLUE].holed == true
end

local function resetTeamsToTee(round: any)
	local tee = currentHole(round).tee
	for _, teamId in { Constants.TeamId.RED, Constants.TeamId.BLUE } do
		round.teamBallPositions[teamId] = {
			position = copyPosition(tee),
			surface = Constants.Surface.TEE,
			holed = false,
		}
		round.pendingOptionsByTeam[teamId] = {}
		round.voteStatesByTeam[teamId] = nil
	end
end

local function advanceAfterSelection(round: any, teamId: string)
	if bothTeamsHoled(round) then
		if round.holeIndex < round.holeCount then
			round.holeIndex += 1
			round.shotCycle = 1
			round.currentTeamId = Constants.TeamId.RED
			resetTeamsToTee(round)
		else
			round.completed = true
		end
		return
	end

	if teamId == Constants.TeamId.RED then
		round.currentTeamId = Constants.TeamId.BLUE
	else
		round.currentTeamId = Constants.TeamId.RED
		round.shotCycle += 1
	end
end

local function selectBall(round: any, teamId: string, option: any): (boolean, any)
	local voteState = round.voteStatesByTeam[teamId]
	local payload = if voteState ~= nil
		then voteSnapshot(voteState)
		else {
			roundId = round.roundId,
			holeIndex = round.holeIndex,
			shotCycle = round.shotCycle,
			teamId = teamId,
			options = {},
			votesByUserId = {},
			selectedBallId = nil,
			expiresAtUnix = os.time(),
		}
	payload.selectedBallId = option.ballId
	round.lastSelectedByTeam[teamId] = optionSnapshot(option)
	round.teamBallPositions[teamId] = {
		position = copyPosition(option.position),
		surface = option.surface,
		holed = option.holed,
	}
	round.teamScores[teamId] += 1
	round.pendingOptionsByTeam[teamId] = {}
	round.voteStatesByTeam[teamId] = nil
	fireVotePayload(round, teamId, payload)
	advanceAfterSelection(round, teamId)

	return true, payload
end

function ScrambleService.start()
	if started then
		return
	end

	started = true
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	net = require(ReplicatedStorage.Shared.Net)
	playersService = game:GetService("Players")

	net.onServerEvent("RequestScrambleBallVote", function(player: Player, payload: any)
		local ok, voteOrReason = ScrambleService.submitVote(player, payload)
		if not ok then
			messagePlayer(player, tostring(voteOrReason))
		end
	end)
end

function ScrambleService.resetForTests()
	roundsById = {}
	roundCounter = 0
	started = false
	net = nil
	playersService = nil
end

function ScrambleService.startScrambleRound(party: any, payload: any): (boolean, any)
	if payload.ranked then
		return false, "ranked scramble disabled"
	end

	local course = CourseRegistry.get(payload.courseId)
	if course == nil then
		return false, "course not found"
	end

	local teams = {
		[Constants.TeamId.RED] = {},
		[Constants.TeamId.BLUE] = {},
	}
	for _, member in party.members do
		if member.teamId == Constants.TeamId.RED or member.teamId == Constants.TeamId.BLUE then
			table.insert(teams[member.teamId], member.userId)
		end
	end
	if
		#teams[Constants.TeamId.RED] ~= Constants.SCRAMBLE_TEAM_SIZE
		or #teams[Constants.TeamId.BLUE] ~= Constants.SCRAMBLE_TEAM_SIZE
	then
		return false, "scramble teams must be 2v2"
	end

	local round = {
		roundId = nextRoundId(party.partyId),
		partyId = party.partyId,
		courseId = course.id,
		course = course,
		holeIndex = 1,
		holeCount = math.min(18, #course.holes),
		shotCycle = 1,
		teams = teams,
		currentTeamId = Constants.TeamId.RED,
		teamBallPositions = {},
		teamScores = {
			[Constants.TeamId.RED] = 0,
			[Constants.TeamId.BLUE] = 0,
		},
		pendingOptionsByTeam = {
			[Constants.TeamId.RED] = {},
			[Constants.TeamId.BLUE] = {},
		},
		voteStatesByTeam = {},
		lastSelectedByTeam = {},
		completed = false,
	}
	resetTeamsToTee(round)
	roundsById[round.roundId] = round

	return true, ScrambleService.snapshot(round.roundId)
end

function ScrambleService.recordShotOption(
	roundId: string,
	player: any,
	shotPayload: any
): (boolean, any)
	local round = roundsById[roundId]
	if round == nil then
		return false, "round not found"
	end
	if round.completed then
		return false, "round complete"
	end

	local userId = playerUserId(player)
	local teamId = userTeam(round, userId)
	if teamId == nil then
		return false, "player not on team"
	end
	if teamId ~= round.currentTeamId then
		return false, "not team turn"
	end
	if round.teamBallPositions[teamId].holed then
		return false, "team holed"
	end

	local result = if type(shotPayload.result) == "table" then shotPayload.result else shotPayload
	local position = shotPayload.position or result.finalPosition
	local surface = shotPayload.surface or result.finalSurface or Constants.Surface.ROUGH
	if
		type(position) ~= "table"
		or type(position.x) ~= "number"
		or type(position.y) ~= "number"
	then
		return false, "position required"
	end

	local pending = round.pendingOptionsByTeam[teamId]
	for index = #pending, 1, -1 do
		if pending[index].playerUserId == userId then
			table.remove(pending, index)
		end
	end

	local hole = currentHole(round)
	local option = {
		ballId = tostring(
			shotPayload.ballId
				or shotPayload.shotId
				or ("ball_" .. userId .. "_" .. round.shotCycle)
		),
		playerUserId = userId,
		teamId = teamId,
		position = copyPosition(position),
		surface = surface,
		holed = shotPayload.holed == true,
		penalty = shotPayload.penalty == true or penaltyForSurface(surface),
		distanceToPinYards = if type(shotPayload.distanceToPinYards) == "number"
			then shotPayload.distanceToPinYards
			else distance(position, hole.pin),
	}
	table.insert(pending, option)
	ensureVoteState(round, teamId)
	fireVoteState(round, teamId)

	return true, optionSnapshot(option)
end

function ScrambleService.submitVote(player: any, payload: any): (boolean, any)
	local valid, reason = PayloadValidators.validateScrambleBallVotePayload(payload)
	if not valid then
		return false, reason
	end

	local round = roundsById[payload.roundId]
	if round == nil then
		return false, "round not found"
	end
	if payload.holeIndex ~= round.holeIndex or payload.shotCycle ~= round.shotCycle then
		return false, "stale vote"
	end

	local userId = playerUserId(player)
	local teamId = userTeam(round, userId)
	if teamId == nil then
		return false, "player not on team"
	end
	local voteState = round.voteStatesByTeam[teamId]
	if voteState == nil then
		return false, "no active vote"
	end
	if optionById(voteState.options, payload.selectedBallId) == nil then
		return false, "ball not available"
	end

	voteState.votesByUserId[userId] = payload.selectedBallId
	if allTeamVotesSame(round, voteState, payload.selectedBallId) then
		local option = optionById(voteState.options, payload.selectedBallId)
		return selectBall(round, teamId, option)
	end

	fireVoteState(round, teamId)
	return true, voteSnapshot(voteState)
end

function ScrambleService.autoSelectBestBall(roundId: string, teamId: string): (boolean, any)
	local round = roundsById[roundId]
	if round == nil then
		return false, "round not found"
	end
	if teamId ~= Constants.TeamId.RED and teamId ~= Constants.TeamId.BLUE then
		return false, "team invalid"
	end

	local option = chooseBest(round.pendingOptionsByTeam[teamId])
	if option == nil then
		return false, "no options"
	end

	return selectBall(round, teamId, option)
end

function ScrambleService.getVoteState(roundId: string, teamId: string): any?
	local round = roundsById[roundId]
	local voteState = round and round.voteStatesByTeam[teamId]
	return if voteState ~= nil then voteSnapshot(voteState) else nil
end

function ScrambleService.snapshot(roundId: string): any?
	local round = roundsById[roundId]
	if round == nil then
		return nil
	end

	local teamBallPositions = {}
	for _, teamId in { Constants.TeamId.RED, Constants.TeamId.BLUE } do
		local ball = round.teamBallPositions[teamId]
		teamBallPositions[teamId] = {
			position = copyPosition(ball.position),
			surface = ball.surface,
			holed = ball.holed,
		}
	end

	local pending = {}
	for _, teamId in { Constants.TeamId.RED, Constants.TeamId.BLUE } do
		pending[teamId] = {}
		for index, option in round.pendingOptionsByTeam[teamId] do
			pending[teamId][index] = optionSnapshot(option)
		end
	end

	local voteStates = {}
	for _, teamId in { Constants.TeamId.RED, Constants.TeamId.BLUE } do
		local voteState = round.voteStatesByTeam[teamId]
		if voteState ~= nil then
			voteStates[teamId] = voteSnapshot(voteState)
		end
	end

	return {
		roundId = round.roundId,
		partyId = round.partyId,
		courseId = round.courseId,
		holeIndex = round.holeIndex,
		holeCount = round.holeCount,
		shotCycle = round.shotCycle,
		teams = round.teams,
		currentTeamId = round.currentTeamId,
		teamBallPositions = teamBallPositions,
		teamScores = {
			[Constants.TeamId.RED] = round.teamScores[Constants.TeamId.RED],
			[Constants.TeamId.BLUE] = round.teamScores[Constants.TeamId.BLUE],
		},
		pendingOptionsByTeam = pending,
		voteStatesByTeam = voteStates,
		lastSelectedByTeam = round.lastSelectedByTeam,
		completed = round.completed,
	}
end

return ScrambleService
