--!strict

local fs = require("@lune/fs")

local COMMAND_ROOT = "src/ServerScriptService/Server/Commands"

type ExpectedCommand = {
	tier: string,
	group: string,
}

local EXPECTED: { [string]: ExpectedCommand } = {
	debugtag = {
		tier = "Tester",
		group = "NexusTester",
	},
	give = {
		tier = "Dev",
		group = "NexusDev",
	},
	profilewipe = {
		tier = "Owner",
		group = "NexusOwner",
	},
	reloadmap = {
		tier = "Dev",
		group = "NexusDev",
	},
	setstat = {
		tier = "Dev",
		group = "NexusDev",
	},
	spawn = {
		tier = "Dev",
		group = "NexusDev",
	},
	tp = {
		tier = "Dev",
		group = "NexusDev",
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

local function header(contents: string, key: string): string
	local value = contents:match("%-%- " .. key .. ":%s*([^\r\n]+)")
	assertTrue(value ~= nil and value ~= "", "Missing header " .. key)
	return value :: string
end

local definitions = {}

for _, entry in fs.readDir(COMMAND_ROOT) do
	if entry:match("%.luau$") and not entry:match("Server%.luau$") then
		local commandName = entry:gsub("%.luau$", "")
		table.insert(definitions, commandName)
	end
end

table.sort(definitions)
assertEqual(#definitions, 7, "command definition count")

for _, commandName in definitions do
	local expected = EXPECTED[commandName]
	assertTrue(expected ~= nil, "Unexpected command definition: " .. commandName)

	local definitionPath = COMMAND_ROOT .. "/" .. commandName .. ".luau"
	local handlerPath = COMMAND_ROOT .. "/" .. commandName .. "Server.luau"
	local definition = read(definitionPath)

	assertTrue(fs.isFile(handlerPath), "Missing command handler: " .. handlerPath)
	assertEqual(header(definition, "Command"), commandName, commandName .. " command header")
	assertEqual(header(definition, "Tier"), expected.tier, commandName .. " tier header")
	assertTrue(header(definition, "Args") ~= "", commandName .. " args header")
	assertTrue(header(definition, "Description") ~= "", commandName .. " description header")
	assertTrue(
		definition:find('Name = "' .. commandName .. '"', 1, true) ~= nil,
		commandName .. " definition Name mismatch"
	)
	assertTrue(
		definition:find('Group = "' .. expected.group .. '"', 1, true) ~= nil,
		commandName .. " definition Group mismatch"
	)
end

local profilewipeHandler = read(COMMAND_ROOT .. "/profilewipeServer.luau")
local giveDefinition = read(COMMAND_ROOT .. "/give.luau")
local giveHandler = read(COMMAND_ROOT .. "/giveServer.luau")
local setstatDefinition = read(COMMAND_ROOT .. "/setstat.luau")
local setstatHandler = read(COMMAND_ROOT .. "/setstatServer.luau")

for _, contents in
	{ giveDefinition, giveHandler, setstatDefinition, setstatHandler, profilewipeHandler }
do
	assertTrue(
		contents:find("arrives in WO-7", 1, true) == nil,
		"Cmdr command surfaces must not describe WO-7 data integration as future work"
	)
end

assertTrue(
	giveHandler:find("DataService.addInventoryItem", 1, true) ~= nil,
	"give must write through DataService.addInventoryItem"
)
assertTrue(
	setstatHandler:find("DataService.setStat", 1, true) ~= nil,
	"setstat must write through DataService.setStat"
)
assertTrue(
	profilewipeHandler:find('Permissions.canRun(context.Executor, "Owner")', 1, true) ~= nil,
	"profilewipe must re-check Owner permission in the server handler"
)
assertTrue(
	profilewipeHandler:find('confirm ~= "CONFIRM_WIPE"', 1, true) ~= nil,
	"profilewipe must require CONFIRM_WIPE"
)
assertTrue(
	profilewipeHandler:find("Refused. Re-run with confirm value CONFIRM_WIPE.", 1, true) ~= nil,
	"profilewipe must return a refusal message before confirmation"
)
assertTrue(
	profilewipeHandler:find("DataService.resetProfile", 1, true) ~= nil,
	"profilewipe must reset through DataService after confirmation"
)

print("Command surface tests passed")
