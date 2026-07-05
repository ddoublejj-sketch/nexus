--!strict

local Constants = require("../../../ReplicatedStorage/Shared/GolfPro/Constants")
local RoundService = require("./RoundService")
local ScoreService = require("./ScoreService")
local PartyService = require("./PartyService")
local ScrambleService = require("./ScrambleService")

local MatchService = {}

local matchesById: { [string]: any } = {}
local matchCounter = 0
local started = false
local net: any = nil
local playersService: any = nil

local function nextMatchId(partyId: string): string
	matchCounter += 1
	return ("match_%s_%d"):format(partyId, matchCounter)
end

local function playerUserIds(party: any): { number }
	local ids = {}
	for index, member in party.members do
		ids[index] = member.userId
	end

	return ids
end

local function teamsForParty(party: any): any?
	if party.desiredMode ~= Constants.Mode.SCRAMBLE_2V2 then
		return nil
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

	return teams
end

local function partyPayload(party: any): any
	return {
		mode = party.desiredMode,
		courseId = party.courseId,
		teeSet = party.teeSet,
		pinSet = party.pinSet,
		ranked = party.ranked,
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
		net.fireClient("SystemMessage", player, reason, { source = "MatchService" })
	end)
	if not ok then
		safeFireClient("ShotRejected", player, { reasonCode = reason })
	end
end

local function fireRoundStart(player: any, round: any)
	safeFireClient("RoundStateUpdated", player, RoundService.snapshot(round))
	safeFireClient("HoleStarted", player, RoundService.holeSnapshot(round))
	safeFireClient("ScorecardUpdated", player, ScoreService.snapshot(round.scorecard))
end

local function broadcastMatch(party: any, matchInfo: any)
	if net == nil or playersService == nil then
		return
	end

	for _, member in party.members do
		local player = playersService:GetPlayerByUserId(member.userId)
		if player ~= nil then
			safeFireClient("MatchFound", player, matchInfo)
		end
	end
end

function MatchService.start()
	if started then
		return
	end

	started = true
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	net = require(ReplicatedStorage.Shared.Net)
	playersService = game:GetService("Players")

	net.onServerEvent("RequestStartPrivateRound", function(player: Player, payload: any)
		local ok, matchOrReason = MatchService.startPrivateRound(player, payload)
		if not ok then
			messagePlayer(player, tostring(matchOrReason))
		end
	end)

	net.onServerEvent("RequestQueue", function(player: Player, payload: any)
		local ok, matchOrReason = MatchService.startPrivateRound(player, payload)
		if not ok then
			messagePlayer(player, tostring(matchOrReason))
		end
	end)
end

function MatchService.resetForTests()
	matchesById = {}
	matchCounter = 0
	started = false
	net = nil
	playersService = nil
end

function MatchService.buildMatchInfo(party: any): any
	return {
		matchId = nextMatchId(party.partyId),
		partyId = party.partyId,
		mode = party.desiredMode,
		courseId = party.courseId,
		transport = Constants.MatchTransport.LOCAL,
		accessCode = nil,
		placeId = nil,
		playerUserIds = playerUserIds(party),
		teams = teamsForParty(party),
	}
end

function MatchService.startPrivateRound(player: any, payload: any): (boolean, any)
	local party = PartyService.getPartyForPlayer(player)
	if party == nil then
		if type(payload) == "table" and payload.mode == Constants.Mode.SCRAMBLE_2V2 then
			return false, "scramble party required"
		end

		local ok, roundOrReason = RoundService.startRound(player, payload)
		if not ok then
			return false, roundOrReason
		end

		fireRoundStart(player, roundOrReason)
		return true, roundOrReason
	end

	local canStart, reason = PartyService.canStartRound(player)
	if not canStart then
		return false, reason or "party cannot start"
	end

	local roundPayload = partyPayload(party)
	local matchInfo = MatchService.buildMatchInfo(party)
	if roundPayload.mode == Constants.Mode.SCRAMBLE_2V2 then
		local ok, scrambleOrReason = ScrambleService.startScrambleRound(party, roundPayload)
		if not ok then
			return false, scrambleOrReason
		end

		matchInfo.roundId = scrambleOrReason.roundId
		matchesById[matchInfo.matchId] = matchInfo
		broadcastMatch(party, matchInfo)
		return true, matchInfo
	end

	local ok, roundOrReason = RoundService.startRound(player, roundPayload)
	if not ok then
		return false, roundOrReason
	end

	matchInfo.roundId = roundOrReason.id
	matchesById[matchInfo.matchId] = matchInfo
	fireRoundStart(player, roundOrReason)
	broadcastMatch(party, matchInfo)
	return true, matchInfo
end

function MatchService.getMatch(matchId: string): any?
	return matchesById[matchId]
end

return MatchService
