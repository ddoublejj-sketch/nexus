--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")

local VAULT_ROOT = "C:/Users/jackw/Roblox/RobloxGameVault"
local DAILY_LOG_PATH = VAULT_ROOT .. "/00_Command_Center/Daily Dev Log.md"
local STATUS_PATH = "docs/STATUS.md"

local EVENT_LABELS = {
	start = "Session Start",
	["end"] = "Session End",
	snapshot = "Snapshot",
}

local function trim(value: string): string
	return value:match("^%s*(.-)%s*$") or ""
end

local function trimTrailing(value: string): string
	return (value:gsub("%s+$", ""))
end

local function markdownFence(value: string): string
	if trim(value) == "" then
		return "<no output>"
	end

	return value:gsub("```", "` ` `")
end

local function runGit(args: { string }): string
	local result = process.exec("git", args)
	local output = trimTrailing(result.stdout)

	if not result.ok then
		local errorOutput = trimTrailing(result.stderr)
		return ("git %s failed with exit %d\n%s"):format(
			table.concat(args, " "),
			result.code,
			if errorOutput ~= "" then errorOutput else output
		)
	end

	return output
end

local function collectOpenTasks(): { string }
	local tasks = {}

	if not fs.isFile(STATUS_PATH) then
		return tasks
	end

	for line in fs.readFile(STATUS_PATH):gmatch("[^\r\n]+") do
		local stripped = trim(line)
		local lower = stripped:lower()
		if
			stripped:match("^%- ")
			and (
				lower:find("blocked", 1, true) ~= nil
				or lower:find("cannot", 1, true) ~= nil
				or lower:find("not complete", 1, true) ~= nil
				or stripped:find("G%d") ~= nil
			)
		then
			table.insert(tasks, stripped)
		end

		if #tasks >= 12 then
			break
		end
	end

	return tasks
end

local function baseDailyLog(): string
	return table.concat({
		"---",
		"type: task",
		"status: active",
		"owner:",
		"source_path:",
		"roblox_asset_id:",
		"studio_instance_path:",
		"dependencies:",
		"last_synced:",
		"tags:",
		"---",
		"",
		"# Daily Dev Log",
		"",
	}, "\n")
end

local function appendSection(path: string, section: string)
	local contents = if fs.isFile(path) then fs.readFile(path) else baseDailyLog()
	local dateHeader = "## " .. os.date("!%Y-%m-%d")

	if not contents:find(dateHeader, 1, true) then
		if not contents:match("\n$") then
			contents ..= "\n"
		end
		contents ..= "\n" .. dateHeader .. "\n"
	end

	if not contents:match("\n$") then
		contents ..= "\n"
	end

	fs.writeFile(path, contents .. "\n" .. section .. "\n")
end

local function renderList(items: { string }): { string }
	if #items == 0 then
		return { "- None" }
	end

	return items
end

local event = process.args[1] or "snapshot"
local label = EVENT_LABELS[event]
if label == nil then
	error("Unknown dev log event '" .. event .. "'. Use start, end, or snapshot.")
end

if not fs.isDir(VAULT_ROOT) then
	error("Missing vault directory: " .. VAULT_ROOT)
end

local changedFiles = runGit({ "status", "--short" })
local recentCommits = runGit({ "log", "--oneline", "-5" })
local openTasks = collectOpenTasks()
local timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
local sectionLines = {
	("### %s - %s"):format(os.date("!%H:%MZ"), label),
	"",
	"Timestamp: " .. timestamp,
	"",
	"Changed files:",
	"",
	"```text",
	markdownFence(changedFiles),
	"```",
	"",
	"Recent commits:",
	"",
	"```text",
	markdownFence(recentCommits),
	"```",
	"",
	"Open gates and tasks:",
	"",
}

for _, item in renderList(openTasks) do
	table.insert(sectionLines, item)
end

appendSection(DAILY_LOG_PATH, table.concat(sectionLines, "\n"))
print(("Dev log appended: %s (%s)"):format(DAILY_LOG_PATH, label))
