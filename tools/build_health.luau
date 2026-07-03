--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")

local VAULT_ROOT = "C:/Users/jackw/Roblox/RobloxGameVault"
local OUTPUT_PATH = VAULT_ROOT .. "/00_Command_Center/Build Health.md"

type CommandResult = {
	label: string,
	command: string,
	ok: boolean,
	code: number,
	stdout: string,
	stderr: string,
	duration: number,
}

local TOOL_EXES = {
	["rojo"] = "rojo.exe",
	["stylua"] = "stylua.exe",
	["selene"] = "selene.exe",
	["luau-lsp"] = "luau-lsp.exe",
}

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

local function parseToolSpec(name: string): (string?, string?, string?)
	for line in fs.readFile("rokit.toml"):gmatch("[^\r\n]+") do
		local manifestName, owner, tool, version =
			line:match('^%s*([%w_%-]+)%s*=%s*"([^/]+)/([^@]+)@([^"]+)"')
		if manifestName == name and owner and tool and version then
			return owner:lower(), tool:lower(), version
		end
	end

	return nil
end

local function toolPath(name: string): string
	local owner, tool, version = parseToolSpec(name)
	if not owner or not tool or not version then
		error("Missing tool pin for " .. name)
	end

	local userProfile = (process.env.USERPROFILE or ""):gsub("\\", "/")
	return ("%s/.rokit/tool-storage/%s/%s/%s/%s"):format(
		userProfile,
		owner,
		tool,
		version,
		TOOL_EXES[name]
	)
end

local function runTool(label: string, name: string, args: { string }): CommandResult
	local started = os.clock()
	local exePath = toolPath(name)
	local result = process.exec(exePath, args)
	local duration = os.clock() - started

	return {
		label = label,
		command = exePath .. " " .. table.concat(args, " "),
		ok = result.ok,
		code = result.code,
		stdout = result.stdout,
		stderr = result.stderr,
		duration = duration,
	}
end

local checks = {
	runTool("StyLua", "stylua", { "--check", "src", "tools" }),
	runTool("Selene", "selene", { "src", "tools" }),
	runTool("Sourcemap", "rojo", { "sourcemap", "default.project.json", "-o", "sourcemap.json" }),
	runTool("Analyze", "luau-lsp", {
		"analyze",
		"--definitions",
		"types/globalTypes.d.luau",
		"--sourcemap",
		"sourcemap.json",
		"src",
	}),
	runTool("Build", "rojo", { "build", "default.project.json", "-o", "build/nexus.rbxl" }),
}

local passed = true
for _, check in checks do
	if not check.ok then
		passed = false
	end
end

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
