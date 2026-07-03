--!strict

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local VAULT_ROOT = "C:/Users/jackw/Roblox/RobloxGameVault"
local SCRIPT_PATH = "tools/human_gate_readiness.luau"
local LAUNCHER_PATH = "nexus.ps1"
local TASKS_PATH = ".vscode/tasks.json"
local DASHBOARD_PATH = VAULT_ROOT .. "/00_Command_Center/Dashboard.md"
local READINESS_PATH = VAULT_ROOT .. "/00_Command_Center/Human Gate Readiness.md"

local REQUIRED_CHECKS = {
	"git --version",
	"rokit --version",
	"rojo --version",
	"code --version",
	"gh --version",
	"blender command",
	"obsidian command",
	"Studio plugin connected",
	"Studio bridge bootstrap",
	"Obsidian REST config",
	"Obsidian REST bootstrap",
	"Obsidian plugins preinstalled",
	"Pending REST writes",
	"gh auth status",
	"GitHub CI bootstrap",
	"git remote -v",
	"Open Cloud config",
	"Open Cloud fixture",
	"Open Cloud bootstrap",
	"Build artifact",
	"Live publish approval",
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

local function assertFrontmatter(contents: string, label: string)
	assertTrue(contents:find("---", 1, true) == 1, label .. " missing frontmatter")
	for _, field in { "type", "status", "source_path", "last_synced", "tags" } do
		assertContains(contents, "\n" .. field .. ":", label .. " missing " .. field)
	end
end

local script = read(SCRIPT_PATH)
local launcher = read(LAUNCHER_PATH)
local tasks = serde.decode("json", read(TASKS_PATH)) :: any

assertContains(
	script,
	"00_Command_Center/Human Gate Readiness.md",
	"script must write Human Gate Readiness"
)
assertContains(script, "values not printed", "script must not print secret values")
assertContains(script, "readEnvFile", "script must parse secret env files before readiness PASS")
assertContains(script, "stripEnvQuotes", "script must accept quoted env values")
assertContains(script, "looksPlaceholder", "script must reject placeholder secret values")
assertContains(script, "numericIdOk", "script must validate Open Cloud numeric IDs")
assertContains(script, "NEEDS HUMAN", "script must preserve human-only checks")
assertContains(script, "./nexus.ps1 gatecheck --self-test", "script must document probe self-test")
for _, check in REQUIRED_CHECKS do
	assertContains(script, check, "script missing check " .. check)
end

assertContains(
	launcher,
	"tools/human_gate_readiness.luau",
	"launcher must run human gate readiness generator"
)

local foundTask = false
for _, task in tasks.tasks do
	if task.label == "Nexus: Human Gates" then
		foundTask = task.command == "./nexus.ps1 gates"
		break
	end
end
assertTrue(foundTask, "VS Code tasks must include Nexus: Human Gates")

if fs.isDir(VAULT_ROOT) then
	local dashboard = read(DASHBOARD_PATH)
	assertContains(
		dashboard,
		"![[Human Gate Readiness]]",
		"Dashboard must embed Human Gate Readiness"
	)

	local readiness = read(READINESS_PATH)
	assertFrontmatter(readiness, "Human Gate Readiness")
	assertContains(readiness, "# Human Gate Readiness", "Readiness note missing title")
	assertContains(readiness, "automatic audit", "Readiness note must explain audit scope")
	assertContains(readiness, "| Gate | Check | Status | Detail |", "Readiness note missing table")
	for _, gate in { "G1", "G2", "G3", "G4", "G5" } do
		assertContains(readiness, "| " .. gate .. " |", "Readiness note missing " .. gate)
	end
	for _, check in REQUIRED_CHECKS do
		assertContains(readiness, check, "Readiness note missing check " .. check)
	end
	assertTrue(
		readiness:find("sk%-proj", 1, false) == nil,
		"Readiness note must not expose OpenAI-style secrets"
	)
	assertTrue(
		readiness:find("ghp_", 1, true) == nil,
		"Readiness note must not expose GitHub tokens"
	)
end

print("Human gate readiness tests passed")
