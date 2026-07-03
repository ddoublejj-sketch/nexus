--!strict

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local VAULT_ROOT = "C:/Users/jackw/Roblox/RobloxGameVault"
local SCRIPT_PATH = "tools/g1_tool_closure.luau"
local RUNBOOK_PATH = "docs/runbooks/g1-tool-closure.md"
local LAUNCHER_PATH = "nexus.ps1"
local TASKS_PATH = ".vscode/tasks.json"
local README_PATH = "README.md"
local DASHBOARD_PATH = VAULT_ROOT .. "/00_Command_Center/Dashboard.md"
local NOTE_PATH = VAULT_ROOT .. "/00_Command_Center/G1 Tool Closure.md"

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

local script = read(SCRIPT_PATH)
local runbook = read(RUNBOOK_PATH)
local launcher = read(LAUNCHER_PATH)
local readme = read(README_PATH)
local tasks = serde.decode("json", read(TASKS_PATH)) :: any

assertContains(script, "00_Command_Center/G1 Tool Closure.md", "script must write vault note")
assertContains(
	script,
	"Get-AppxPackage BlenderFoundation.Blender",
	"script must detect Store Blender"
)
assertContains(script, "Microsoft.VisualStudioCode", "script must include VS Code winget id")
assertContains(script, "GitHub.cli", "script must include GitHub CLI winget id")
assertContains(script, "Obsidian.Obsidian", "script must include Obsidian winget id")
assertContains(script, "./nexus.ps1 gatecheck --gate G1", "script must include G1 probe")
assertNotContains(script, "gh auth login", "G1 closure must not absorb G4 auth")

for _, command in
	{ "code --version", "gh --version", "Get-Command blender", "./nexus.ps1 gatecheck --gate G1" }
do
	assertContains(runbook, command, "runbook missing " .. command)
end
assertContains(runbook, "Restart the shell", "runbook must mention PATH refresh")
assertContains(runbook, "G4 still owns `gh auth login`", "runbook must keep G4 separate")
assertNotContains(runbook, "OBSIDIAN_API_KEY=", "runbook must not contain secret assignments")
assertNotContains(runbook, "OPEN_CLOUD_API_KEY=", "runbook must not contain secret assignments")

assertContains(launcher, '"g1" {', "launcher must expose g1 subcommand")
assertContains(
	launcher,
	'Invoke-Tool "lune" @("run", "tools/g1_tool_closure.luau")',
	"launcher g1 command must run generator"
)
assertContains(readme, "./nexus.ps1 g1", "README must document G1 command")

local foundTask = false
for _, task in tasks.tasks do
	if task.label == "Nexus: G1 Tool Closure" then
		foundTask = task.command == "./nexus.ps1 g1"
		break
	end
end
assertTrue(foundTask, "VS Code tasks must include Nexus: G1 Tool Closure")

if fs.isDir(VAULT_ROOT) then
	local dashboard = read(DASHBOARD_PATH)
	assertContains(dashboard, "![[G1 Tool Closure]]", "Dashboard must embed G1 Tool Closure")

	local note = read(NOTE_PATH)
	assertContains(note, "# G1 Tool Closure", "G1 note missing title")
	assertContains(note, "VS Code code CLI", "G1 note missing VS Code row")
	assertContains(note, "GitHub CLI", "G1 note missing gh row")
	assertContains(note, "Obsidian command", "G1 note missing Obsidian row")
	assertContains(note, "Blender CLI", "G1 note missing Blender CLI row")
	assertContains(note, "Blender Store Package", "G1 note missing Store Blender row")
	assertContains(note, "not found on PATH", "G1 note must show missing PATH state")
	assertContains(
		note,
		"winget install --id Microsoft.VisualStudioCode",
		"G1 note missing VS Code command"
	)
end

print("G1 tool closure tests passed")
