--!strict

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local VAULT_ROOT = "C:/Users/jackw/Roblox/RobloxGameVault"
local SCRIPT_PATH = "tools/human_gate_checklist.luau"
local LAUNCHER_PATH = "nexus.ps1"
local TASKS_PATH = ".vscode/tasks.json"
local README_PATH = "README.md"
local DASHBOARD_PATH = VAULT_ROOT .. "/00_Command_Center/Dashboard.md"
local CHECKLIST_PATH = VAULT_ROOT .. "/00_Command_Center/Human Gate Checklist.md"

local REQUIRED_GATE_HEADINGS = {
	"## G1 - GUI Installs",
	"## G2 - Studio Connect",
	"## G3 - Obsidian REST And Plugins",
	"## G4 - GitHub Auth And CI",
	"## G5 - Open Cloud Key",
}

local REQUIRED_PROOF_COMMANDS = {
	"code --version",
	"gh --version",
	"Get-Command blender -ErrorAction SilentlyContinue",
	"./nexus.ps1 g1",
	"./nexus.ps1 up",
	"./nexus.ps1 studio-bridge",
	"./nexus.ps1 obsidian-plugins",
	"./nexus.ps1 obsidian-rest",
	"lune run tools/vault_ping.luau",
	"gh auth status",
	"./nexus.ps1 github-ci",
	"./nexus.ps1 github-ci --create-vault-private",
	"./nexus.ps1 open-cloud",
	"./nexus.ps1 gatecheck --gate G1",
	"./nexus.ps1 release --dry-run --fixture",
	"./nexus.ps1 release --live",
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
local readme = read(README_PATH)
local tasks = serde.decode("json", read(TASKS_PATH)) :: any

assertContains(
	script,
	"00_Command_Center/Human Gate Checklist.md",
	"script must write Human Gate Checklist"
)
for _, gateId in { "G1", "G2", "G3", "G4", "G5" } do
	assertContains(script, 'id = "' .. gateId .. '"', "script missing " .. gateId)
end
for _, command in REQUIRED_PROOF_COMMANDS do
	assertContains(script, command, "script missing proof command " .. command)
end

assertContains(launcher, '"gates" {', "launcher must expose gates subcommand")
assertContains(
	launcher,
	"tools/human_gate_checklist.luau",
	"launcher must run human gate checklist generator"
)
assertContains(readme, "./nexus.ps1 gates", "README must document gates command")

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
		"![[Human Gate Checklist]]",
		"Dashboard must embed Human Gate Checklist"
	)

	local checklist = read(CHECKLIST_PATH)
	assertFrontmatter(checklist, "Human Gate Checklist")
	assertContains(checklist, "# Human Gate Checklist", "Checklist missing title")
	assertContains(checklist, "## Current Phase", "Checklist missing Current Phase")
	assertContains(checklist, "## Gate Summary", "Checklist missing Gate Summary")
	for _, heading in REQUIRED_GATE_HEADINGS do
		assertContains(checklist, heading, "Checklist missing " .. heading)
	end
	for _, command in REQUIRED_PROOF_COMMANDS do
		assertContains(checklist, command, "Checklist missing proof command " .. command)
	end
end

print("Human gate checklist tests passed")
