--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
