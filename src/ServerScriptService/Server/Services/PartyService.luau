--!strict

local Constants = require("../../../ReplicatedStorage/Shared/GolfPro/Constants")
local PayloadValidators =
	require("../../../ReplicatedStorage/Shared/GolfPro/Network/PayloadValidators")

local PartyService = {}

local CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

local partiesById: { [string]: any } = {}
local partyIdByUserId: { [number]: string } = {}
local partyCodeIndex: { [string]: string } = {}
local partyCounter = 0
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

local function playerDisplayName(player: any): string
	local ok, value = pcall(function()
		return player.DisplayName
	end)
	if ok and type(value) == "string" and value ~= "" then
		return value
	end

	local nameOk, name = pcall(function()
		return player.Name
	end)
	if nameOk and type(name) == "string" and name ~= "" then
		return name
	end

	return "Player"
end

local function trim(value: string): string
	return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function normalizeCode(code: string): string
	return string.upper(trim(code))
end

local function nextPartyId(leaderUserId: number): string
	partyCounter += 1
	return ("party_%d_%d"):format(leaderUserId, partyCounter)
end

local function randomCode(): string
	local chars = {}
	for index = 1, 6 do
		local offset = math.random(1, #CODE_ALPHABET)
		chars[index] = CODE_ALPHABET:sub(offset, offset)
	end

	return table.concat(chars)
end

local function createUniqueCode(): string
	for _ = 1, 100 do
		local code = randomCode()
		if partyCodeIndex[code] == nil then
			return code
		end
	end

	partyCounter += 1
	return ("P%05d"):format(partyCounter % 100000)
end

local function isSoloMode(mode: string): boolean
	return mode == Constants.Mode.PRACTICE
		or mode == Constants.Mode.SOLO_STROKE_3_DEBUG
		or mode == Constants.Mode.SOLO_STROKE_9
		or mode == Constants.Mode.SOLO_STROKE_18
end

local function memberForUserId(party: any, userId: number): any?
	return party.memberByUserId[userId]
end

local function countReady(party: any): number
	local count = 0
	for _, member in party.members do
		if member.ready then
			count += 1
		end
	end

	return count
end

local function teamCount(party: any, teamId: string, exceptUserId: number?): number
	local count = 0
	for _, member in party.members do
		if member.userId ~= exceptUserId and member.teamId == teamId then
			count += 1
		end
	end

	return count
end

local function refreshStatus(party: any)
	if party.status == Constants.PartyStatus.IN_MATCH then
		return
	end

	if #party.members > 0 and countReady(party) == #party.members then
		party.status = Constants.PartyStatus.READY
	elseif party.desiredMode ~= "" then
		party.status = Constants.PartyStatus.CONFIGURING
	else
		party.status = Constants.PartyStatus.IDLE
	end
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
		net.fireClient("SystemMessage", player, reason, { source = "PartyService" })
	end)
	if not ok then
		safeFireClient("ShotRejected", player, { reasonCode = reason })
	end
end

local function broadcastParty(party: any)
	if net == nil or playersService == nil then
		return
	end

	local snapshot = PartyService.snapshot(party)
	for _, member in party.members do
		local player = playersService:GetPlayerByUserId(member.userId)
		if player ~= nil then
			safeFireClient("PartyUpdated", player, snapshot)
		end
	end
end

function PartyService.start()
	if started then
		return
	end

	started = true
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	net = require(ReplicatedStorage.Shared.Net)
	playersService = game:GetService("Players")

	net.onServerEvent("RequestCreateParty", function(player: Player)
		PartyService.createParty(player)
	end)

	net.onServerEvent("RequestJoinPartyCode", function(player: Player, payload: any)
		local ok, partyOrReason = PartyService.joinByCode(player, tostring(payload.code or ""))
		if not ok then
			messagePlayer(player, tostring(partyOrReason))
		end
	end)

	net.onServerEvent("RequestLeaveParty", function(player: Player, _payload: any)
		local ok, reason = PartyService.leaveParty(player)
		if not ok then
			messagePlayer(player, tostring(reason))
		end
	end)

	net.onServerEvent("RequestPartyReady", function(player: Player, payload: any)
		local valid, reason = PayloadValidators.validatePartyReadyPayload(payload)
		if not valid then
			messagePlayer(player, reason or "invalid ready")
			return
		end

		local ok, partyOrReason = PartyService.setReady(player, payload.ready)
		if not ok then
			messagePlayer(player, tostring(partyOrReason))
		end
	end)

	net.onServerEvent("RequestPartyConfigure", function(player: Player, payload: any)
		local ok, partyOrReason = PartyService.configure(player, payload)
		if not ok then
			messagePlayer(player, tostring(partyOrReason))
		end
	end)

	net.onServerEvent("RequestPartyTeam", function(player: Player, payload: any)
		local valid, reason = PayloadValidators.validatePartyTeamPayload(payload)
		if not valid then
			messagePlayer(player, reason or "invalid team")
			return
		end

		local ok, partyOrReason = PartyService.setTeam(player, payload.teamId)
		if not ok then
			messagePlayer(player, tostring(partyOrReason))
		end
	end)
end

function PartyService.resetForTests()
	partiesById = {}
	partyIdByUserId = {}
	partyCodeIndex = {}
	partyCounter = 0
	started = false
	net = nil
	playersService = nil
end

function PartyService.createParty(player: any): any
	local userId = playerUserId(player)
	assert(userId > 0, "player UserId is required")

	local existing = PartyService.getPartyForPlayer(player)
	if existing ~= nil then
		return existing
	end

	local partyId = nextPartyId(userId)
	local code = createUniqueCode()
	local party = {
		partyId = partyId,
		code = code,
		leaderUserId = userId,
		status = Constants.PartyStatus.IDLE,
		desiredMode = Constants.Mode.PRIVATE_STROKE,
		courseId = Constants.DEFAULT_COURSE_ID,
		teeSet = Constants.DEFAULT_TEE_SET,
		pinSet = Constants.DEFAULT_PIN_SET,
		ranked = false,
		members = {
			{
				userId = userId,
				displayName = playerDisplayName(player),
				role = Constants.PartyRole.LEADER,
				ready = true,
				teamId = nil,
			},
		},
		memberByUserId = {},
	}
	party.memberByUserId[userId] = party.members[1]
	partiesById[partyId] = party
	partyIdByUserId[userId] = partyId
	partyCodeIndex[code] = partyId
	refreshStatus(party)
	broadcastParty(party)

	return party
end

function PartyService.joinByCode(player: any, code: string): (boolean, any)
	local valid, reason = PayloadValidators.validatePartyCodePayload({ code = code })
	if not valid then
		return false, reason
	end

	local userId = playerUserId(player)
	if userId <= 0 then
		return false, "player UserId required"
	end
	if partyIdByUserId[userId] ~= nil then
		return false, "already in party"
	end

	local partyId = partyCodeIndex[normalizeCode(code)]
	local party = if partyId ~= nil then partiesById[partyId] else nil
	if party == nil then
		return false, "party not found"
	end
	if #party.members >= Constants.MAX_PARTY_SIZE then
		return false, "party full"
	end

	local member = {
		userId = userId,
		displayName = playerDisplayName(player),
		role = Constants.PartyRole.MEMBER,
		ready = false,
		teamId = nil,
	}
	table.insert(party.members, member)
	party.memberByUserId[userId] = member
	partyIdByUserId[userId] = party.partyId
	refreshStatus(party)
	broadcastParty(party)

	return true, party
end

function PartyService.leaveParty(player: any): (boolean, any)
	local userId = playerUserId(player)
	local party = PartyService.getPartyForPlayer(player)
	if party == nil then
		return false, "not in party"
	end

	local removedIndex = nil
	for index, member in party.members do
		if member.userId == userId then
			removedIndex = index
			break
		end
	end
	if removedIndex == nil then
		return false, "not in party"
	end

	table.remove(party.members, removedIndex :: number)
	party.memberByUserId[userId] = nil
	partyIdByUserId[userId] = nil

	if #party.members == 0 then
		partiesById[party.partyId] = nil
		partyCodeIndex[party.code] = nil
		return true, nil
	end

	if party.leaderUserId == userId then
		party.leaderUserId = party.members[1].userId
	end
	for _, member in party.members do
		member.role = if member.userId == party.leaderUserId
			then Constants.PartyRole.LEADER
			else Constants.PartyRole.MEMBER
	end

	refreshStatus(party)
	broadcastParty(party)
	return true, party
end

function PartyService.setReady(player: any, ready: boolean): (boolean, any)
	local party = PartyService.getPartyForPlayer(player)
	if party == nil then
		return false, "not in party"
	end

	local member = memberForUserId(party, playerUserId(player))
	if member == nil then
		return false, "not in party"
	end

	member.ready = ready
	refreshStatus(party)
	broadcastParty(party)
	return true, party
end

function PartyService.configure(player: any, payload: any): (boolean, any)
	local party = PartyService.getPartyForPlayer(player)
	if party == nil then
		return false, "not in party"
	end
	if party.leaderUserId ~= playerUserId(player) then
		return false, "leader only"
	end

	local valid, reason = PayloadValidators.validatePartyConfigurePayload(payload)
	if not valid then
		return false, reason
	end

	party.desiredMode = payload.mode
	party.courseId = trim(payload.courseId)
	party.teeSet = trim(payload.teeSet)
	party.pinSet = trim(payload.pinSet)
	party.ranked = payload.ranked
	for _, member in party.members do
		if member.userId ~= party.leaderUserId then
			member.ready = false
		end
		if party.desiredMode ~= Constants.Mode.SCRAMBLE_2V2 then
			member.teamId = nil
		end
	end

	refreshStatus(party)
	broadcastParty(party)
	return true, party
end

function PartyService.setTeam(player: any, teamId: string): (boolean, any)
	local party = PartyService.getPartyForPlayer(player)
	if party == nil then
		return false, "not in party"
	end
	if party.desiredMode ~= Constants.Mode.SCRAMBLE_2V2 then
		return false, "scramble only"
	end
	if teamId ~= Constants.TeamId.RED and teamId ~= Constants.TeamId.BLUE then
		return false, "team invalid"
	end

	local userId = playerUserId(player)
	local member = memberForUserId(party, userId)
	if member == nil then
		return false, "not in party"
	end
	if teamCount(party, teamId, userId) >= Constants.SCRAMBLE_TEAM_SIZE then
		return false, "team full"
	end

	member.teamId = teamId
	broadcastParty(party)
	return true, party
end

function PartyService.getPartyForPlayer(player: any): any?
	local partyId = partyIdByUserId[playerUserId(player)]
	return if partyId ~= nil then partiesById[partyId] else nil
end

function PartyService.getPartyById(partyId: string): any?
	return partiesById[partyId]
end

function PartyService.snapshot(party: any): any
	local members = {}
	for index, member in party.members do
		members[index] = {
			userId = member.userId,
			displayName = member.displayName,
			role = member.role,
			ready = member.ready,
			teamId = member.teamId,
		}
	end

	return {
		partyId = party.partyId,
		code = party.code,
		leaderUserId = party.leaderUserId,
		status = party.status,
		desiredMode = party.desiredMode,
		courseId = party.courseId,
		teeSet = party.teeSet,
		pinSet = party.pinSet,
		ranked = party.ranked,
		members = members,
	}
end

function PartyService.canStartRound(player: any): (boolean, string?)
	local party = PartyService.getPartyForPlayer(player)
	if party == nil then
		return false, "not in party"
	end
	if party.leaderUserId ~= playerUserId(player) then
		return false, "leader only"
	end
	if countReady(party) ~= #party.members then
		return false, "not all ready"
	end

	local mode = party.desiredMode
	if mode == Constants.Mode.PRIVATE_STROKE then
		if
			#party.members < Constants.MIN_PRIVATE_ROUND_PLAYERS
			or #party.members > Constants.MAX_PARTY_SIZE
		then
			return false, "invalid party size"
		end
		return true, nil
	end

	if isSoloMode(mode) then
		if #party.members ~= 1 then
			return false, "solo modes need one player"
		end
		return true, nil
	end

	if mode == Constants.Mode.SCRAMBLE_2V2 then
		if party.ranked then
			return false, "ranked scramble disabled"
		end
		if #party.members ~= Constants.SCRAMBLE_PLAYER_COUNT then
			return false, "scramble needs four players"
		end
		if
			teamCount(party, Constants.TeamId.RED) ~= Constants.SCRAMBLE_TEAM_SIZE
			or teamCount(party, Constants.TeamId.BLUE) ~= Constants.SCRAMBLE_TEAM_SIZE
		then
			return false, "scramble teams must be 2v2"
		end
		return true, nil
	end

	return false, "mode unsupported"
end

return PartyService
