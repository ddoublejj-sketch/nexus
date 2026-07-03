--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")

local QualityGate = require("./lib/QualityGate")

local VAULT_ROOT = "C:/Users/jackw/Roblox/RobloxGameVault"
local OUTPUT_PATH = VAULT_ROOT .. "/00_Command_Center/Build Health.md"

local function hasArg(name: string): boolean
	for _, arg in process.args do
		if arg == name then
			return true
		end
	end

	return false
end

local function isoTimestamp(): string
	return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

local function trim(value: string): string
	return value:match("^%s*(.-)%s*$") or ""
end

local function markdownFence(value: string): string
	if value == "" then
		return "<no output>"
	end

	local sanitized = value:gsub("```", "` ` `")
	return sanitized
end

local skipInstall = hasArg("--skip-install")
local checks = QualityGate.runAll({
	skipInstall = skipInstall,
})
local passed = QualityGate.allPassed(checks)

local timestamp = isoTimestamp()
local lines = {
	"---",
	"type: system",
	"status: active",
	"owner:",
	"source_path: C:\\Users\\jackw\\Roblox\\nexus\\tools\\build_health.luau",
	"roblox_asset_id:",
	"studio_instance_path:",
	"dependencies:",
	"last_synced: " .. timestamp,
	"tags:",
	"---",
	"",
	"# Build Health",
	"",
	"Generated: " .. timestamp,
	"",
	if skipInstall then "Mode: watcher-safe; Wally Install skipped" else "Mode: full",
	"",
	"Overall: " .. if passed then "PASS" else "FAIL",
	"",
	"| Check | Result | Seconds | Exit Code |",
	"| --- | --- | --- | --- |",
}

for _, check in checks do
	table.insert(
		lines,
		("| %s | %s | %.2f | %d |"):format(
			check.label,
			if check.ok then "PASS" else "FAIL",
			check.duration,
			check.code
		)
	)
end

for _, check in checks do
	table.insert(lines, "")
	table.insert(lines, "## " .. check.label)
	table.insert(lines, "")
	table.insert(lines, "Command:")
	table.insert(lines, "")
	table.insert(lines, "```powershell")
	table.insert(lines, check.command)
	table.insert(lines, "```")
	table.insert(lines, "")
	table.insert(lines, "Output:")
	table.insert(lines, "")
	table.insert(lines, "```text")
	table.insert(lines, markdownFence(trim(check.stdout)))
	table.insert(lines, "```")
	if trim(check.stderr) ~= "" then
		table.insert(lines, "")
		table.insert(lines, "Error:")
		table.insert(lines, "")
		table.insert(lines, "```text")
		table.insert(lines, markdownFence(trim(check.stderr)))
		table.insert(lines, "```")
	end
end

if not fs.isDir(VAULT_ROOT) then
	error("Missing vault directory: " .. VAULT_ROOT)
end

fs.writeFile(OUTPUT_PATH, table.concat(lines, "\n") .. "\n")

print(("Build health %s; wrote %s"):format(if passed then "PASS" else "FAIL", OUTPUT_PATH))
if not passed then
	process.exit(1)
end
