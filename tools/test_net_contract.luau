--!strict

local fs = require("@lune/fs")

local NET_PATH = "src/ReplicatedStorage/Shared/Net/init.luau"
local DATA_SERVICE_PATH = "src/ServerScriptService/Server/Services/DataService.luau"
local NETWORKING_NOTE_PATH = "C:/Users/jackw/Roblox/RobloxGameVault/02_Systems/Networking.md"

type ExpectedRemote = {
	kind: string,
	direction: string,
	validatorCount: number,
	descriptionFragment: string,
}

local EXPECTED_REMOTES: { [string]: ExpectedRemote } = {
	Ping = {
		kind = "RemoteEvent",
		direction = "Bidirectional",
		validatorCount = 1,
		descriptionFragment = "connectivity ping",
	},
	RequestProfileSnapshot = {
		kind = "RemoteFunction",
		direction = "ClientToServer",
		validatorCount = 0,
		descriptionFragment = "read-only profile snapshot",
	},
	SetDebugFlag = {
		kind = "RemoteEvent",
		direction = "ClientToServer",
		validatorCount = 2,
		descriptionFragment = "server-authoritative debug flag",
	},
	SystemMessage = {
		kind = "RemoteEvent",
		direction = "ServerToClient",
		validatorCount = 2,
		descriptionFragment = "server-authored UI/system message",
	},
}

local function assertTrue(condition: boolean, label: string)
	if not condition then
		error(label)
	end
end

local function assertEqual(actual: any, expected: any, label: string)
	if actual ~= expected then
		error(("%s: expected %s, got %s"):format(label, tostring(expected), tostring(actual)))
	end
end

local function read(path: string): string
	assertTrue(fs.isFile(path), "Missing file: " .. path)
	return fs.readFile(path)
end

local function remoteBlock(contents: string, remoteName: string): string
	local keyStart, keyEnd = contents:find(remoteName .. "%s*=%s*{")
	assertTrue(keyStart ~= nil and keyEnd ~= nil, "Missing remote definition: " .. remoteName)

	local depth = 0
	local blockEnd = nil
	for index = keyEnd :: number, #contents do
		local char = contents:sub(index, index)
		if char == "{" then
			depth += 1
		elseif char == "}" then
			depth -= 1
			if depth == 0 then
				blockEnd = index
				break
			end
		end
	end

	assertTrue(blockEnd ~= nil, "Unclosed remote definition: " .. remoteName)

	return contents:sub((keyEnd :: number) + 1, (blockEnd :: number) - 1)
end

local function countValidators(block: string): number
	local validators = block:match("validators%s*=%s*{%s*(.-)%s*}")
	assertTrue(validators ~= nil, "Missing validators list")

	local count = 0
	for value in (validators :: string):gmatch("[%w_]+") do
		if value ~= "" then
			count += 1
		end
	end

	return count
end

local net = read(NET_PATH)
local dataService = read(DATA_SERVICE_PATH)
local networkingNote = read(NETWORKING_NOTE_PATH)

for remoteName, expected in EXPECTED_REMOTES do
	local block = remoteBlock(net, remoteName)

	assertTrue(
		block:find('name = "' .. remoteName .. '"', 1, true) ~= nil,
		remoteName .. " name must match its table key"
	)
	assertTrue(
		block:find('kind = "' .. expected.kind .. '"', 1, true) ~= nil,
		remoteName .. " kind mismatch"
	)
	assertTrue(
		block:find('direction = "' .. expected.direction .. '"', 1, true) ~= nil,
		remoteName .. " direction mismatch"
	)
	assertEqual(countValidators(block), expected.validatorCount, remoteName .. " validator count")
	assertTrue(
		block:find(expected.descriptionFragment, 1, true) ~= nil,
		remoteName .. " description should explain intent"
	)
	assertTrue(
		networkingNote:find(remoteName, 1, true) ~= nil,
		remoteName .. " must be documented in the vault networking note"
	)
end

assertTrue(
	net:find("function Net.validate", 1, true) ~= nil
		and net:find("Remote %s expected %d argument", 1, true) ~= nil
		and net:find("failed validation", 1, true) ~= nil,
	"Net.validate must reject wrong arity and invalid argument types"
)
assertTrue(
	net:find("function Net.onServerEvent", 1, true) ~= nil
		and net:find("Net.validate(name, ...)", 1, true) ~= nil,
	"client-to-server events must validate payloads before invoking callbacks"
)
assertTrue(
	net:find("function Net.setServerInvoke", 1, true) ~= nil
		and net:find("remote.OnServerInvoke = function", 1, true) ~= nil,
	"client-to-server invokes must be registered through the Net wrapper"
)
assertTrue(
	net:find("function Net.fireClient", 1, true) ~= nil
		and net:find("Net.getRemoteEvent(name):FireClient(player, ...)", 1, true) ~= nil,
	"server-to-client sends must use the Net wrapper"
)

assertTrue(
	dataService:find('Net.setServerInvoke("RequestProfileSnapshot", snapshotProfile)', 1, true)
		~= nil,
	"DataService must own the profile snapshot remote handler"
)
assertTrue(
	dataService:find("schema_version = data.schema_version", 1, true) ~= nil
		and dataService:find("currencies = data.currencies", 1, true) ~= nil
		and dataService:find("stats = data.stats", 1, true) ~= nil,
	"profile snapshots must expose only the approved read-only fields"
)
assertTrue(
	dataService:find("inventory = data.inventory", 1, true) == nil
		and dataService:find("flags = data.flags", 1, true) == nil,
	"profile snapshots must not expose inventory or internal flags by default"
)
assertTrue(
	dataService:find("function DataService.setKey", 1, true) ~= nil
		and dataService:find('Net.onServerEvent("SetDebugFlag"', 1, true) == nil,
	"mutating profile APIs must stay server-owned until a guarded handler exists"
)

print("Net contract tests passed")
