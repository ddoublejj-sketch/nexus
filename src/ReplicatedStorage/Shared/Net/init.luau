--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PayloadValidators = require(ReplicatedStorage.Shared.GolfPro.Network.PayloadValidators)

export type RemoteKind = "RemoteEvent" | "RemoteFunction"
export type RemoteDirection = "ClientToServer" | "ServerToClient" | "Bidirectional"
export type TypeValidator = (value: any) -> boolean
export type RemoteDefinition = {
	name: string,
	kind: RemoteKind,
	direction: RemoteDirection,
	validators: { TypeValidator },
	description: string,
}

local REMOTES_FOLDER_NAME = "NexusRemotes"

local Net = {}

local function anyValue(_: any): boolean
	return true
end

local function stringValue(value: any): boolean
	return type(value) == "string"
end

local function booleanValue(value: any): boolean
	return type(value) == "boolean"
end

local function tableValue(value: any): boolean
	return type(value) == "table"
end

local function shotIntentValue(value: any): boolean
	local ok = PayloadValidators.validateShotIntent(value)
	return ok
end

local function roundStartValue(value: any): boolean
	local ok = PayloadValidators.validateRoundStartPayload(value)
	return ok
end

local remoteDefinitions: { [string]: RemoteDefinition } = {
	Ping = {
		name = "Ping",
		kind = "RemoteEvent",
		direction = "Bidirectional",
		validators = { stringValue },
		description = "Lightweight connectivity ping with a reason label.",
	},
	RequestProfileSnapshot = {
		name = "RequestProfileSnapshot",
		kind = "RemoteFunction",
		direction = "ClientToServer",
		validators = {},
		description = "Request a sanitized, read-only profile snapshot.",
	},
	RequestLeaderboardPage = {
		name = "RequestLeaderboardPage",
		kind = "RemoteFunction",
		direction = "ClientToServer",
		validators = { tableValue },
		description = "Golf Pro request for a ranked leaderboard page.",
	},
	RequestMysteryRangeSnapshot = {
		name = "RequestMysteryRangeSnapshot",
		kind = "RemoteFunction",
		direction = "ClientToServer",
		validators = {},
		description = "Golf Pro request for Mystery Range progress snapshot.",
	},
	RequestMysteryRangeDeposit = {
		name = "RequestMysteryRangeDeposit",
		kind = "RemoteEvent",
		direction = "ClientToServer",
		validators = { tableValue },
		description = "Golf Pro request to deposit a full Mystery Range meter.",
	},
	RequestMysteryRangeUpgrade = {
		name = "RequestMysteryRangeUpgrade",
		kind = "RemoteEvent",
		direction = "ClientToServer",
		validators = { tableValue },
		description = "Golf Pro request to buy a Mystery Range upgrade.",
	},
	SetDebugFlag = {
		name = "SetDebugFlag",
		kind = "RemoteEvent",
		direction = "ClientToServer",
		validators = { stringValue, booleanValue },
		description = "Toggle a server-authoritative debug flag.",
	},
	SystemMessage = {
		name = "SystemMessage",
		kind = "RemoteEvent",
		direction = "ServerToClient",
		validators = { stringValue, anyValue },
		description = "Deliver a server-authored UI/system message to a client.",
	},
	RequestCreateParty = {
		name = "RequestCreateParty",
		kind = "RemoteEvent",
		direction = "ClientToServer",
		validators = {},
		description = "Golf Pro request to create an in-memory private-round party.",
	},
	RequestInviteToParty = {
		name = "RequestInviteToParty",
		kind = "RemoteEvent",
		direction = "ClientToServer",
		validators = { tableValue },
		description = "Golf Pro request to invite a friend to the caller's party.",
	},
	RequestJoinPartyCode = {
		name = "RequestJoinPartyCode",
		kind = "RemoteEvent",
		direction = "ClientToServer",
		validators = { tableValue },
		description = "Golf Pro request to join an in-memory party by code.",
	},
	RequestLeaveParty = {
		name = "RequestLeaveParty",
		kind = "RemoteEvent",
		direction = "ClientToServer",
		validators = { tableValue },
		description = "Golf Pro request to leave the caller's current party.",
	},
	RequestPartyReady = {
		name = "RequestPartyReady",
		kind = "RemoteEvent",
		direction = "ClientToServer",
		validators = { tableValue },
		description = "Golf Pro request to set the caller's party ready state.",
	},
	RequestPartyConfigure = {
		name = "RequestPartyConfigure",
		kind = "RemoteEvent",
		direction = "ClientToServer",
		validators = { tableValue },
		description = "Golf Pro party leader request to configure private round settings.",
	},
	RequestPartyTeam = {
		name = "RequestPartyTeam",
		kind = "RemoteEvent",
		direction = "ClientToServer",
		validators = { tableValue },
		description = "Golf Pro request to choose a 2v2 scramble team.",
	},
	RequestQueue = {
		name = "RequestQueue",
		kind = "RemoteEvent",
		direction = "ClientToServer",
		validators = { tableValue },
		description = "Golf Pro request to queue or locally start a configured private match.",
	},
	RequestStartPrivateRound = {
		name = "RequestStartPrivateRound",
		kind = "RemoteEvent",
		direction = "ClientToServer",
		validators = { roundStartValue },
		description = "Golf Pro party leader request to start a private round.",
	},
	SubmitShotIntent = {
		name = "SubmitShotIntent",
		kind = "RemoteEvent",
		direction = "ClientToServer",
		validators = { shotIntentValue },
		description = "Golf Pro client shot request; server owns validation and result.",
	},
	RequestScrambleBallVote = {
		name = "RequestScrambleBallVote",
		kind = "RemoteEvent",
		direction = "ClientToServer",
		validators = { tableValue },
		description = "Golf Pro 2v2 scramble selected-ball vote.",
	},
	PartyUpdated = {
		name = "PartyUpdated",
		kind = "RemoteEvent",
		direction = "ServerToClient",
		validators = { tableValue },
		description = "Golf Pro authoritative party state update.",
	},
	MatchFound = {
		name = "MatchFound",
		kind = "RemoteEvent",
		direction = "ServerToClient",
		validators = { tableValue },
		description = "Golf Pro local/private match information for party members.",
	},
	ScrambleVoteUpdated = {
		name = "ScrambleVoteUpdated",
		kind = "RemoteEvent",
		direction = "ServerToClient",
		validators = { tableValue },
		description = "Golf Pro 2v2 scramble ball-vote state update.",
	},
	RoundStateUpdated = {
		name = "RoundStateUpdated",
		kind = "RemoteEvent",
		direction = "ServerToClient",
		validators = { tableValue },
		description = "Golf Pro authoritative round state snapshot.",
	},
	HoleStarted = {
		name = "HoleStarted",
		kind = "RemoteEvent",
		direction = "ServerToClient",
		validators = { tableValue },
		description = "Golf Pro hole intro snapshot.",
	},
	ShotAccepted = {
		name = "ShotAccepted",
		kind = "RemoteEvent",
		direction = "ServerToClient",
		validators = { tableValue },
		description = "Golf Pro accepted shot acknowledgement.",
	},
	ShotRejected = {
		name = "ShotRejected",
		kind = "RemoteEvent",
		direction = "ServerToClient",
		validators = { tableValue },
		description = "Golf Pro rejected shot or round request reason.",
	},
	BallPath = {
		name = "BallPath",
		kind = "RemoteEvent",
		direction = "ServerToClient",
		validators = { tableValue },
		description = "Golf Pro visual ball path generated from server shot result.",
	},
	BallAtRest = {
		name = "BallAtRest",
		kind = "RemoteEvent",
		direction = "ServerToClient",
		validators = { tableValue },
		description = "Golf Pro authoritative ball resting state.",
	},
	ScorecardUpdated = {
		name = "ScorecardUpdated",
		kind = "RemoteEvent",
		direction = "ServerToClient",
		validators = { tableValue },
		description = "Golf Pro scorecard update after an official server result.",
	},
	RoundCompleted = {
		name = "RoundCompleted",
		kind = "RemoteEvent",
		direction = "ServerToClient",
		validators = { tableValue },
		description = "Golf Pro final round result snapshot.",
	},
	CourseRecordUpdated = {
		name = "CourseRecordUpdated",
		kind = "RemoteEvent",
		direction = "ServerToClient",
		validators = { tableValue },
		description = "Golf Pro course record update celebration payload.",
	},
	MysteryRangeUpdated = {
		name = "MysteryRangeUpdated",
		kind = "RemoteEvent",
		direction = "ServerToClient",
		validators = { tableValue },
		description = "Golf Pro Mystery Range progress update.",
	},
	MysteryRangeRewardRevealed = {
		name = "MysteryRangeRewardRevealed",
		kind = "RemoteEvent",
		direction = "ServerToClient",
		validators = { tableValue },
		description = "Golf Pro Mystery Range deterministic reward reveal.",
	},
}

local function getOrCreateFolder(): Folder
	local existing = ReplicatedStorage:FindFirstChild(REMOTES_FOLDER_NAME)
	if existing and existing:IsA("Folder") then
		return existing
	end

	local folder = Instance.new("Folder")
	folder.Name = REMOTES_FOLDER_NAME
	folder.Parent = ReplicatedStorage

	return folder
end

local function getDefinition(name: string): RemoteDefinition
	local definition = remoteDefinitions[name]
	assert(definition ~= nil, ("Unknown remote %q"):format(name))

	return definition
end

local function validateArgs(definition: RemoteDefinition, args: { any }): (boolean, string?)
	if #args ~= #definition.validators then
		return false,
			("Remote %s expected %d argument(s), got %d."):format(
				definition.name,
				#definition.validators,
				#args
			)
	end

	for index, validator in definition.validators do
		if not validator(args[index]) then
			return false,
				("Remote %s argument %d failed validation."):format(definition.name, index)
		end
	end

	return true, nil
end

function Net.getDefinitions(): { [string]: RemoteDefinition }
	return remoteDefinitions
end

function Net.ensureRemotes(): Folder
	local folder = getOrCreateFolder()

	for _, definition in remoteDefinitions do
		local existing = folder:FindFirstChild(definition.name)
		if existing == nil then
			local remote = Instance.new(definition.kind)
			remote.Name = definition.name
			remote.Parent = folder
		elseif existing.ClassName ~= definition.kind then
			error(
				("Remote %s exists as %s, expected %s."):format(
					definition.name,
					existing.ClassName,
					definition.kind
				)
			)
		end
	end

	return folder
end

function Net.getRemote(name: string): Instance?
	local folder = ReplicatedStorage:FindFirstChild(REMOTES_FOLDER_NAME)
	if folder == nil then
		return nil
	end

	return folder:FindFirstChild(name)
end

function Net.getRemoteEvent(name: string): RemoteEvent
	local definition = getDefinition(name)
	assert(definition.kind == "RemoteEvent", ("Remote %s is not a RemoteEvent."):format(name))

	local remote = Net.ensureRemotes():FindFirstChild(name)
	assert(remote and remote:IsA("RemoteEvent"), ("RemoteEvent %s was not created."):format(name))

	return remote
end

function Net.getRemoteFunction(name: string): RemoteFunction
	local definition = getDefinition(name)
	assert(definition.kind == "RemoteFunction", ("Remote %s is not a RemoteFunction."):format(name))

	local remote = Net.ensureRemotes():FindFirstChild(name)
	assert(
		remote and remote:IsA("RemoteFunction"),
		("RemoteFunction %s was not created."):format(name)
	)

	return remote
end

function Net.validate(name: string, ...): (boolean, string?)
	local definition = getDefinition(name)
	local args = { ... }

	return validateArgs(definition, args)
end

function Net.onServerEvent(name: string, callback: (player: Player, ...any) -> ())
	local remote = Net.getRemoteEvent(name)

	remote.OnServerEvent:Connect(function(player: Player, ...)
		local ok, reason = Net.validate(name, ...)
		if not ok then
			warn(
				("[Nexus] Rejected remote %s from %s: %s"):format(
					name,
					player.Name,
					reason or "invalid"
				)
			)
			return
		end

		callback(player, ...)
	end)
end

function Net.setServerInvoke(name: string, callback: (player: Player, ...any) -> any)
	local remote = Net.getRemoteFunction(name)

	remote.OnServerInvoke = function(player: Player, ...)
		local ok, reason = Net.validate(name, ...)
		if not ok then
			warn(
				("[Nexus] Rejected remote %s from %s: %s"):format(
					name,
					player.Name,
					reason or "invalid"
				)
			)
			return nil
		end

		return callback(player, ...)
	end
end

function Net.fireClient(name: string, player: Player, ...)
	local ok, reason = Net.validate(name, ...)
	if not ok then
		error(reason)
	end

	Net.getRemoteEvent(name):FireClient(player, ...)
end

return Net
