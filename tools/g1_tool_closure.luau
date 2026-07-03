--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")

local VAULT_ROOT = "C:/Users/jackw/Roblox/RobloxGameVault"
local OUTPUT_PATH = VAULT_ROOT .. "/00_Command_Center/G1 Tool Closure.md"
local RUNBOOK_PATH = "docs/runbooks/g1-tool-closure.md"

type ToolRow = {
	tool: string,
	status: string,
	detail: string,
	closeAction: string,
}

local function isoTimestamp(): string
	return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

local function trim(value: string): string
	return value:match("^%s*(.-)%s*$") or ""
end

local function oneLine(value: string): string
	local normalized = trim(value:gsub("\r", "\n"):gsub("\n+", " "):gsub("|", "\\|"))
	if #normalized > 150 then
		return normalized:sub(1, 147) .. "..."
	end

	return normalized
end

local function powershell(command: string): string
	local result = process.exec("powershell.exe", {
		"-NoProfile",
		"-Command",
		command,
	})

	if not result.ok then
		return trim((result.stdout or "") .. " " .. (result.stderr or ""))
	end

	return trim(result.stdout)
end

local function commandSource(command: string): string
	return powershell(
		("Get-Command %s -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Source"):format(
			command
		)
	)
end

local function toolRow(tool: string, command: string, closeAction: string): ToolRow
	local source = commandSource(command)
	return {
		tool = tool,
		status = if source ~= "" then "FOUND" else "MISSING",
		detail = if source ~= "" then source else command .. " not found on PATH",
		closeAction = closeAction,
	}
end

local function blenderStoreRow(): ToolRow
	local detail = powershell(
		"Get-AppxPackage BlenderFoundation.Blender | Select-Object -First 1 Name,Version,InstallLocation,Status | Format-List"
	)

	return {
		tool = "Blender Store Package",
		status = if detail ~= "" then "FOUND" else "MISSING",
		detail = if detail ~= ""
			then detail
			else "BlenderFoundation.Blender Appx package not detected",
		closeAction = "Use a standard Blender install or PATH-visible blender.exe for CLI thumbnail rendering.",
	}
end

local function markdownEscape(value: string): string
	return value:gsub("|", "\\|")
end

local rows: { ToolRow } = {
	toolRow(
		"VS Code code CLI",
		"code",
		"Install Visual Studio Code and enable the `code` command on PATH."
	),
	toolRow("GitHub CLI", "gh", "Install GitHub CLI; auth remains G4."),
	toolRow("Obsidian command", "obsidian", "Install Obsidian and open the vault once."),
	toolRow(
		"Blender CLI",
		"blender",
		"Install a standard Blender build or provide a PATH-visible `blender.exe`."
	),
	blenderStoreRow(),
}

if not fs.isDir(VAULT_ROOT) then
	error("Missing vault directory: " .. VAULT_ROOT)
end

local timestamp = isoTimestamp()
local lines = {
	"---",
	"type: system",
	"status: active",
	"owner:",
	"source_path: C:\\Users\\jackw\\Roblox\\nexus\\tools\\g1_tool_closure.luau",
	"roblox_asset_id:",
	"studio_instance_path:",
	"dependencies:",
	"last_synced: " .. timestamp,
	"tags: gates, g1, tools",
	"---",
	"",
	"# G1 Tool Closure",
	"",
	"Generated: " .. timestamp,
	"",
	"This note records what the current shell can verify for G1. It does not run GUI installers; use it as the exact checklist before rerunning `./nexus.ps1 gatecheck --gate G1`.",
	"",
	"| Tool | Status | Detail | Close Action |",
	"| --- | --- | --- | --- |",
}

for _, row in rows do
	table.insert(
		lines,
		("| %s | %s | %s | %s |"):format(
			markdownEscape(row.tool),
			row.status,
			oneLine(row.detail),
			markdownEscape(row.closeAction)
		)
	)
end

table.insert(lines, "")
table.insert(lines, "## Human Install Commands")
table.insert(lines, "")
table.insert(lines, "Run these only with explicit approval and close any installer UI they open:")
table.insert(lines, "")
table.insert(lines, "```powershell")
table.insert(lines, "winget install --id Microsoft.VisualStudioCode --source winget")
table.insert(lines, "winget install --id GitHub.cli --source winget")
table.insert(lines, "winget install --id Obsidian.Obsidian --source winget")
table.insert(
	lines,
	"# Blender: install a standard build that exposes blender.exe on PATH, or provide the full blender.exe path."
)
table.insert(lines, "```")
table.insert(lines, "")
table.insert(lines, "## Verification")
table.insert(lines, "")
table.insert(lines, "```powershell")
table.insert(lines, "code --version")
table.insert(lines, "gh --version")
table.insert(lines, "Get-Command obsidian -ErrorAction SilentlyContinue")
table.insert(lines, "Get-Command blender -ErrorAction SilentlyContinue")
table.insert(lines, "./nexus.ps1 gatecheck --gate G1")
table.insert(lines, "```")
table.insert(lines, "")
table.insert(lines, "Runbook: `" .. RUNBOOK_PATH .. "`")

fs.writeFile(OUTPUT_PATH, table.concat(lines, "\n") .. "\n")
print("Wrote G1 tool closure note to " .. OUTPUT_PATH)
