--!strict

local fs = require("@lune/fs")

local COMMANDS_ROOT = "src/ServerScriptService/Server/Commands"
local VAULT_ROOT = "C:/Users/jackw/Roblox/RobloxGameVault"
local OUTPUT_PATH = VAULT_ROOT .. "/02_Systems/Commands.md"

type CommandRow = {
	name: string,
	tier: string,
	args: string,
	description: string,
	sourcePath: string,
}

local function isoTimestamp(): string
	return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

local function trim(value: string): string
	return value:match("^%s*(.-)%s*$") or ""
end

local function markdownEscape(value: string): string
	return value:gsub("|", "\\|"):gsub("\n", " ")
end

local function listCommandFiles(root: string): { string }
	local files = {}

	if not fs.isDir(root) then
		return files
	end

	for _, entry in fs.readDir(root) do
		local path = root .. "/" .. entry
		if fs.isDir(path) then
			for _, nested in listCommandFiles(path) do
				table.insert(files, nested)
			end
		elseif
			(entry:match("%.luau$") or entry:match("%.lua$"))
			and not entry:match("Server%.lua[u]?$")
		then
			table.insert(files, path)
		end
	end

	table.sort(files)
	return files
end

local function readHeaderValue(contents: string, key: string): string?
	for line in contents:gmatch("[^\r\n]+") do
		local value = line:match("^%s*%-%-%s*" .. key .. ":%s*(.+)$")
		if value then
			return trim(value)
		end
	end

	return nil
end

local function parseCommand(path: string): CommandRow
	local contents = fs.readFile(path)
	local fallbackName = path:match("([^/\\]+)%.lua[u]?$") or path

	return {
		name = readHeaderValue(contents, "Command") or fallbackName,
		tier = readHeaderValue(contents, "Tier") or "Unspecified",
		args = readHeaderValue(contents, "Args") or "",
		description = readHeaderValue(contents, "Description") or "",
		sourcePath = path,
	}
end

if not fs.isDir(VAULT_ROOT) then
	error("Missing vault directory: " .. VAULT_ROOT)
end

local commands = {}
for _, filePath in listCommandFiles(COMMANDS_ROOT) do
	table.insert(commands, parseCommand(filePath))
end

table.sort(commands, function(left, right)
	return left.name < right.name
end)

local timestamp = isoTimestamp()
local lines = {
	"---",
	"type: system",
	"status: active",
	"owner:",
	"source_path: C:\\Users\\jackw\\Roblox\\nexus\\src\\ServerScriptService\\Server\\Commands",
	"roblox_asset_id:",
	"studio_instance_path: game.ServerScriptService.Server.Commands",
	"dependencies:",
	"last_synced: " .. timestamp,
	"tags:",
	"---",
	"",
	"# Commands",
	"",
	"Generated: " .. timestamp,
	"",
	"| Command | Tier | Args | Description | Source |",
	"| --- | --- | --- | --- | --- |",
}

for _, command in commands do
	table.insert(
		lines,
		("| %s | %s | %s | %s | `%s` |"):format(
			markdownEscape(command.name),
			markdownEscape(command.tier),
			markdownEscape(command.args),
			markdownEscape(command.description),
			markdownEscape(command.sourcePath)
		)
	)
end

if #commands == 0 then
	table.insert(lines, "")
	table.insert(lines, "No command modules found yet. Cmdr commands arrive in WO-6.")
end

fs.writeFile(OUTPUT_PATH, table.concat(lines, "\n") .. "\n")

print(("Wrote %d command rows to %s"):format(#commands, OUTPUT_PATH))
