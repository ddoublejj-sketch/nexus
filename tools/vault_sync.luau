--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")

local VAULT_ROOT = "C:/Users/jackw/Roblox/RobloxGameVault"
local GENERATED_ROOT = VAULT_ROOT .. "/02_Systems/Generated Modules"
local STALE_REPORT_PATH = VAULT_ROOT .. "/90_Automation/Generated/Stale Sources.md"

type ModuleInfo = {
	name: string,
	category: string,
	sourcePath: string,
	studioPath: string,
	notePath: string,
	publicFunctions: { string },
	requires: { string },
	todos: { string },
	lastCommit: string,
}

local function isoTimestamp(): string
	return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

local function trim(value: string): string
	return value:match("^%s*(.-)%s*$") or ""
end

local function ensureDir(path: string)
	if not fs.isDir(path) then
		fs.writeDir(path)
	end
end

local function ensureParent(path: string)
	local parent = path:match("^(.*)/[^/]+$")
	if parent then
		ensureDir(parent)
	end
end

local function sanitizeFileName(value: string): string
	return value:gsub("[^%w%._%- ]", "_")
end

local function listLuauFiles(root: string): { string }
	local files = {}

	if not fs.isDir(root) then
		return files
	end

	for _, entry in fs.readDir(root) do
		local path = root .. "/" .. entry
		if fs.isDir(path) then
			for _, nested in listLuauFiles(path) do
				table.insert(files, nested)
			end
		elseif entry:match("%.luau$") then
			table.insert(files, path)
		end
	end

	table.sort(files)
	return files
end

local function listMarkdownFiles(root: string): { string }
	local files = {}

	if not fs.isDir(root) then
		return files
	end

	for _, entry in fs.readDir(root) do
		local path = root .. "/" .. entry
		if fs.isDir(path) then
			for _, nested in listMarkdownFiles(path) do
				table.insert(files, nested)
			end
		elseif entry:match("%.md$") then
			table.insert(files, path)
		end
	end

	table.sort(files)
	return files
end

local function toStudioPath(sourcePath: string): string
	local path = sourcePath:gsub("\\", "/")
	path = path:gsub("^src/", "")
	path = path:gsub("%.luau$", "")
	path = path:gsub("/init%.server$", "")
	path = path:gsub("/init%.client$", "")
	path = path:gsub("/init$", "")
	path = path:gsub("/", ".")

	return "game." .. path
end

local function classify(sourcePath: string): string?
	local path = sourcePath:gsub("\\", "/")

	if path:match("^src/ServerScriptService/Server/Services/") then
		return "Services"
	elseif path:match("^src/StarterPlayer/StarterPlayerScripts/Client/Controllers/") then
		return "Controllers"
	elseif path:match("^src/ReplicatedStorage/Shared/") then
		return "Shared"
	end

	return nil
end

local function moduleName(sourcePath: string): string
	local path = sourcePath:gsub("\\", "/")
	local name = path:match("([^/]+)%.luau$") or path
	if name == "init" then
		name = path:match("([^/]+)/init%.luau$") or name
	end

	return name
end

local function parsePublicFunctions(contents: string): { string }
	local functions = {}

	for tableName, functionName in contents:gmatch("function%s+([%w_]+)%.([%w_]+)%s*%(") do
		table.insert(functions, tableName .. "." .. functionName)
	end

	table.sort(functions)
	return functions
end

local function parseRequires(contents: string): { string }
	local requires = {}

	for required in contents:gmatch("require%s*%((.-)%)") do
		table.insert(requires, trim(required:gsub("\n", " ")))
	end

	table.sort(requires)
	return requires
end

local function parseTodos(contents: string): { string }
	local todos = {}

	for line in contents:gmatch("[^\r\n]+") do
		if line:lower():find("todo", 1, true) then
			table.insert(todos, trim(line))
		end
	end

	return todos
end

local function lastCommitFor(sourcePath: string): string
	local result = process.exec("git", {
		"log",
		"-n",
		"1",
		"--pretty=format:%h",
		"--",
		sourcePath,
	})

	if result.ok and result.stdout ~= "" then
		return trim(result.stdout)
	end

	return "uncommitted"
end

local function bulletList(items: { string }, emptyText: string): { string }
	if #items == 0 then
		return { "- " .. emptyText }
	end

	local lines = {}
	for _, item in items do
		table.insert(lines, "- `" .. item .. "`")
	end

	return lines
end

local function buildNote(info: ModuleInfo, timestamp: string): string
	local lines = {
		"---",
		"type: system",
		"status: active",
		"owner:",
		"source_path: C:\\Users\\jackw\\Roblox\\nexus\\" .. info.sourcePath:gsub("/", "\\"),
		"roblox_asset_id:",
		"studio_instance_path: " .. info.studioPath,
		"dependencies:",
		"last_synced: " .. timestamp,
		"tags:",
		"---",
		"",
		"# " .. info.name,
		"",
		"Category: " .. info.category,
		"",
		"Last commit: `" .. info.lastCommit .. "`",
		"",
		"## Public Functions",
	}

	for _, line in bulletList(info.publicFunctions, "No public functions found.") do
		table.insert(lines, line)
	end

	table.insert(lines, "")
	table.insert(lines, "## Requires")
	for _, line in bulletList(info.requires, "No requires found.") do
		table.insert(lines, line)
	end

	table.insert(lines, "")
	table.insert(lines, "## TODOs")
	for _, line in bulletList(info.todos, "No TODOs found.") do
		table.insert(lines, line)
	end

	return table.concat(lines, "\n") .. "\n"
end

local function toRepoRelative(path: string): string
	local normalized = path:gsub("\\", "/")
	normalized = normalized:gsub("^C:/Users/jackw/Roblox/nexus/", "")

	return normalized
end

local function writeStaleReport(timestamp: string)
	local staleRows = {}

	for _, notePath in listMarkdownFiles(GENERATED_ROOT) do
		local contents = fs.readFile(notePath)
		local sourcePath = contents:match("\nsource_path:%s*([^\r\n]+)")
		if sourcePath then
			local relativeSource = toRepoRelative(trim(sourcePath))
			if not fs.isFile(relativeSource) then
				table.insert(staleRows, {
					note = notePath:gsub("^" .. VAULT_ROOT .. "/", ""),
					source = relativeSource,
				})
			end
		end
	end

	local lines = {
		"---",
		"type: system",
		"status: active",
		"owner:",
		"source_path: C:\\Users\\jackw\\Roblox\\nexus\\tools\\vault_sync.luau",
		"roblox_asset_id:",
		"studio_instance_path:",
		"dependencies:",
		"last_synced: " .. timestamp,
		"tags:",
		"---",
		"",
		"# Stale Sources",
		"",
		"Generated: " .. timestamp,
		"",
	}

	if #staleRows == 0 then
		table.insert(lines, "No stale generated module notes found.")
	else
		table.insert(lines, "| Note | Missing Source |")
		table.insert(lines, "| --- | --- |")
		for _, row in staleRows do
			table.insert(lines, ("| `%s` | `%s` |"):format(row.note, row.source))
		end
	end

	ensureParent(STALE_REPORT_PATH)
	fs.writeFile(STALE_REPORT_PATH, table.concat(lines, "\n") .. "\n")
end

if not fs.isDir(VAULT_ROOT) then
	error("Missing vault directory: " .. VAULT_ROOT)
end

ensureDir(GENERATED_ROOT)

local timestamp = isoTimestamp()
local modules = {}

for _, filePath in listLuauFiles("src") do
	local category = classify(filePath)
	if category then
		local contents = fs.readFile(filePath)
		local name = moduleName(filePath)
		local notePath = GENERATED_ROOT .. "/" .. category .. "/" .. sanitizeFileName(name) .. ".md"

		table.insert(modules, {
			name = name,
			category = category,
			sourcePath = filePath,
			studioPath = toStudioPath(filePath),
			notePath = notePath,
			publicFunctions = parsePublicFunctions(contents),
			requires = parseRequires(contents),
			todos = parseTodos(contents),
			lastCommit = lastCommitFor(filePath),
		})
	end
end

for _, moduleInfo in modules do
	ensureParent(moduleInfo.notePath)
	fs.writeFile(moduleInfo.notePath, buildNote(moduleInfo, timestamp))
end

writeStaleReport(timestamp)

print(
	("Wrote %d module notes under %s and refreshed stale-source report"):format(
		#modules,
		GENERATED_ROOT
	)
)
