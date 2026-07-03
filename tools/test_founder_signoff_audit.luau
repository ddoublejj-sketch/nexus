--!strict

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local VAULT_ROOT = "C:/Users/jackw/Roblox/RobloxGameVault"
local AUDIT_NOTE_PATH = VAULT_ROOT .. "/00_Command_Center/Founder Sign-Off Audit.md"
local SCRIPT_PATH = "tools/founder_signoff_audit.luau"
local LAUNCHER_PATH = "nexus.ps1"
local TASKS_PATH = ".vscode/tasks.json"
local DASHBOARD_PATH = VAULT_ROOT .. "/00_Command_Center/Dashboard.md"

local FRONTMATTER_FIELDS = {
	"type",
	"status",
	"owner",
	"source_path",
	"roblox_asset_id",
	"studio_instance_path",
	"dependencies",
	"last_synced",
	"tags",
}

local CRITERIA = {
	"Every WO acceptance command has real pasted output in STATUS.md",
	"Cold-boot test passes",
	"Zero secrets in either Git history",
	"Vault dashboard answers systems, assets, commands, and last build",
	"A fresh machine can reach setup from README + runbooks alone",
}

local function assertTrue(condition: boolean, label: string)
	if not condition then
		error(label)
	end
end

local function read(path: string): string
	assertTrue(fs.isFile(path), "Missing file: " .. path)
	return fs.readFile(path)
end

local function assertContains(contents: string, needle: string, label: string)
	assertTrue(contents:find(needle, 1, true) ~= nil, label)
end

local function assertNotContains(contents: string, needle: string, label: string)
	assertTrue(contents:find(needle, 1, true) == nil, label)
end

local function assertFrontmatter(contents: string, label: string)
	assertTrue(contents:find("---", 1, true) == 1, label .. " missing opening frontmatter")

	for _, field in FRONTMATTER_FIELDS do
		assertContains(contents, "\n" .. field .. ":", label .. " missing " .. field)
	end
end

local script = read(SCRIPT_PATH)
local launcher = read(LAUNCHER_PATH)
local tasks = serde.decode("json", read(TASKS_PATH)) :: any

assertContains(
	script,
	"00_Command_Center/Founder Sign-Off Audit.md",
	"Audit generator must write the founder sign-off note"
)
assertContains(
	script,
	"master plan Section 10",
	"Audit generator must name the source sign-off criteria"
)
assertContains(script, "Overall: ", "Audit generator must compute an overall status")
assertContains(script, "BLOCKED", "Audit generator must preserve blocked sign-off states")
assertContains(script, "PARTIAL", "Audit generator must preserve partial sign-off states")
assertContains(script, "Secret Scan", "Audit generator must cite secret-scan evidence")

for _, criterion in CRITERIA do
	assertContains(script, criterion, "Audit generator missing criterion: " .. criterion)
end

for _, gate in { "G1", "G2", "G3", "G4", "G5" } do
	assertContains(script, gate .. ":", "Audit generator missing human gate " .. gate)
end

assertContains(launcher, '"audit" {', "Launcher must expose audit subcommand")
assertContains(
	launcher,
	'Invoke-Tool "lune" @("run", "tools/founder_signoff_audit.luau")',
	"Launcher audit command must run the generator"
)
assertContains(
	launcher,
	"tools/founder_signoff_audit.luau",
	"Launcher loop must refresh founder sign-off audit"
)

local foundTask = false
for _, task in tasks.tasks do
	if task.label == "Nexus: Founder Sign-Off Audit" then
		foundTask = task.command == "./nexus.ps1 audit"
		break
	end
end
assertTrue(foundTask, "VS Code tasks must include Nexus: Founder Sign-Off Audit")

if fs.isDir(VAULT_ROOT) then
	local dashboard = read(DASHBOARD_PATH)
	assertContains(
		dashboard,
		"![[Founder Sign-Off Audit]]",
		"Dashboard must embed Founder Sign-Off Audit"
	)

	local audit = read(AUDIT_NOTE_PATH)
	assertFrontmatter(audit, "Founder Sign-Off Audit")
	assertContains(audit, "# Founder Sign-Off Audit", "Audit note missing title")
	assertContains(audit, "Overall: BLOCKED", "Audit note must not claim final sign-off yet")
	assertContains(audit, "PARTIAL", "Audit note must show partial criteria")
	assertContains(audit, "BLOCKED", "Audit note must show blocked criteria")
	assertContains(
		audit,
		"| 3 | Zero secrets in either Git history | PASS |",
		"Audit must pass secret criterion"
	)
	for _, criterion in CRITERIA do
		assertContains(audit, criterion, "Audit note missing criterion: " .. criterion)
	end
	for _, gate in { "G1:", "G2:", "G3:", "G4:", "G5:" } do
		assertContains(audit, gate, "Audit note missing gate blocker " .. gate)
	end
	assertNotContains(audit, "OBSIDIAN_API_KEY=", "Audit note must not expose Obsidian key values")
	assertNotContains(
		audit,
		"OPEN_CLOUD_API_KEY=",
		"Audit note must not expose Open Cloud key values"
	)
	assertNotContains(audit, "sk-", "Audit note must not expose API keys")
end

print("Founder sign-off audit tests passed")
