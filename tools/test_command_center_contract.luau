--!strict

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local VAULT_ROOT = "C:/Users/jackw/Roblox/RobloxGameVault"
local LAUNCHER_PATH = "nexus.ps1"
local TASKS_PATH = ".vscode/tasks.json"
local SETTINGS_PATH = ".vscode/settings.json"
local EXTENSIONS_PATH = ".vscode/extensions.json"
local DEV_LOG_PATH = "tools/dev_log.luau"
local FRESH_SETUP_PATH = "docs/runbooks/fresh-machine-setup.md"
local DISASTER_RECOVERY_PATH = "docs/runbooks/disaster-recovery.md"

local EXPECTED_TASKS = {
	["Nexus: Up"] = "./nexus.ps1 up",
	["Nexus: Down"] = "./nexus.ps1 down",
	["Nexus: Serve"] = "./nexus.ps1 serve",
	["Nexus: Build"] = "./nexus.ps1 build",
	["Nexus: Sourcemap Watch"] = "./nexus.ps1 map",
	["Nexus: Check"] = "./nexus.ps1 check",
	["Nexus: Format"] = "./nexus.ps1 fix",
	["Nexus: Vault Sync"] = "./nexus.ps1 sync",
	["Nexus: Health"] = "./nexus.ps1 health",
	["Nexus: Render Thumbnails"] = "./nexus.ps1 thumbnails",
	["Nexus: Human Gates"] = "./nexus.ps1 gates",
	["Nexus: Gate Acceptance Probe"] = "./nexus.ps1 gatecheck --self-test",
	["Nexus: G1 Tool Closure"] = "./nexus.ps1 g1",
	["Nexus: Studio Bridge Bootstrap"] = "./nexus.ps1 studio-bridge",
	["Nexus: Human Gate Receipts"] = "./nexus.ps1 receipts",
	["Nexus: Obsidian Plugin Setup"] = "./nexus.ps1 obsidian-plugins",
	["Nexus: Obsidian REST Bootstrap"] = "./nexus.ps1 obsidian-rest",
	["Nexus: GitHub CI Bootstrap"] = "./nexus.ps1 github-ci",
	["Nexus: Open Cloud Bootstrap"] = "./nexus.ps1 open-cloud",
	["Nexus: Founder Sign-Off Audit"] = "./nexus.ps1 audit",
	["Nexus: Cold Boot Readiness"] = "./nexus.ps1 cold-boot",
	["Nexus: Work Order Acceptance Audit"] = "./nexus.ps1 wo-audit",
	["Nexus: Release Dry Run"] = "./nexus.ps1 release --dry-run --fixture",
	["Nexus: Loop Once"] = "./nexus.ps1 loop --once",
}

local REQUIRED_EXTENSIONS = {
	"evaera.vscode-rojo",
	"johnnymorganz.luau-lsp",
	"kampfkarren.selene-vscode",
	"johnnymorganz.stylua",
}

local LOOP_SCRIPTS = {
	"tools/sourcemap_summary.luau",
	"tools/vault_sync.luau",
	"tools/command_registry.luau",
	"tools/asset_manifest.luau",
	"tools/gate_status.luau",
	"tools/human_gate_checklist.luau",
	"tools/human_gate_readiness.luau",
	"tools/human_gate_receipts.luau",
	"tools/cold_boot_readiness.luau",
	"tools/work_order_acceptance_audit.luau",
	"tools/founder_signoff_audit.luau",
	"tools/build_health.luau",
}

local function assertTrue(condition: boolean, label: string)
	if not condition then
		error(label)
	end
end

local function assertEqual(actual: any, expected: any, label: string)
	if actual ~= expected then
		error(("%s: expected %s, got %s"):format(label, tostring(expected), tostring(actual)))
	end
end

local function read(path: string): string
	assertTrue(fs.isFile(path), "Missing file: " .. path)
	return fs.readFile(path)
end

local function assertContains(contents: string, needle: string, label: string)
	assertTrue(contents:find(needle, 1, true) ~= nil, label)
end

local launcher = read(LAUNCHER_PATH)
local devLog = read(DEV_LOG_PATH)
local freshSetup = read(FRESH_SETUP_PATH)
local disasterRecovery = read(DISASTER_RECOVERY_PATH)

for _, jobName in { "NexusRojoServe", "NexusSourcemapWatch", "NexusAutomationLoop" } do
	assertContains(launcher, '"' .. jobName .. '"', "Launcher missing job " .. jobName)
end

for _, command in
	{
		'"up"',
		'"down"',
		'"serve"',
		'"build"',
		'"map"',
		'"check"',
		'"fix"',
		'"sync"',
		'"health"',
		'"thumbnails"',
		'"gates"',
		'"gatecheck"',
		'"g1"',
		'"studio-bridge"',
		'"receipts"',
		'"obsidian-plugins"',
		'"obsidian-rest"',
		'"github-ci"',
		'"open-cloud"',
		'"audit"',
		'"cold-boot"',
		'"wo-audit"',
		'"release"',
		'"loop"',
		'"status"',
	}
do
	assertContains(launcher, command .. " {", "Launcher missing subcommand " .. command)
end

assertContains(launcher, "& $Rojo serve default.project.json", "up must start Rojo serve")
assertContains(
	launcher,
	"& $Rojo sourcemap default.project.json -o sourcemap.json --watch",
	"up must start sourcemap watch"
)
assertContains(
	launcher,
	"tools/build_health.luau --skip-install",
	"up loop must use watcher-safe Build Health"
)
assertContains(
	launcher,
	'Invoke-Tool "lune" @("run", "tools/dev_log.luau", "start")',
	"up must append a session-start dev log"
)
assertContains(
	launcher,
	'Invoke-Tool "lune" @("run", "tools/dev_log.luau", "end")',
	"down must append a session-end dev log"
)
assertContains(launcher, "Stop-NexusJobs", "down must stop background jobs")
assertContains(launcher, "Write-NexusJobTable", "status/up/down must print job table")
assertContains(
	launcher,
	"Refresh-NexusPath",
	"launcher must refresh PATH for newly installed tools"
)
assertContains(
	launcher,
	'[Environment]::GetEnvironmentVariable("Path", "User")',
	"launcher must include user PATH entries"
)
assertContains(launcher, "git status --short", "status must show Git status")
assertContains(launcher, "rokit list", "status must show pinned tools")
assertContains(
	launcher,
	'Invoke-Tool "lune" @("run", "tools/cold_boot_readiness.luau")',
	"cold-boot must write readiness evidence"
)
assertContains(
	launcher,
	'Invoke-Tool "lune" @("run", "tools/work_order_acceptance_audit.luau")',
	"wo-audit must write work-order acceptance evidence"
)

for _, scriptPath in LOOP_SCRIPTS do
	assertContains(launcher, scriptPath, "Launcher loop missing " .. scriptPath)
end

local tasks = serde.decode("json", read(TASKS_PATH)) :: any
assertEqual(tasks.version, "2.0.0", "VS Code task schema version")

local taskCommands: { [string]: string } = {}
for _, task in tasks.tasks do
	taskCommands[task.label] = task.command
end

for label, command in EXPECTED_TASKS do
	assertEqual(taskCommands[label], command, "VS Code task " .. label)
end

local settings = serde.decode("json", read(SETTINGS_PATH)) :: any
assertEqual(settings["luau-lsp.sourcemap.enabled"], true, "luau-lsp sourcemap enabled")
assertEqual(settings["luau-lsp.sourcemap.autogenerate"], false, "luau-lsp sourcemap autogen")
assertEqual(
	settings["luau-lsp.sourcemap.rojoProjectFile"],
	"default.project.json",
	"luau-lsp Rojo project"
)
assertEqual(
	settings["luau-lsp.types.definitionFiles"][1],
	"types/globalTypes.d.luau",
	"luau-lsp Roblox definitions"
)

local extensions = serde.decode("json", read(EXTENSIONS_PATH)) :: any
for _, extension in REQUIRED_EXTENSIONS do
	local found = false
	for _, recommendation in extensions.recommendations do
		if recommendation == extension then
			found = true
			break
		end
	end
	assertTrue(found, "Missing VS Code extension recommendation: " .. extension)
end

for event, snippet in
	{
		start = 'start = "Session Start"',
		["end"] = '["end"] = "Session End"',
		snapshot = 'snapshot = "Snapshot"',
	}
do
	assertContains(devLog, snippet, "dev_log missing event " .. event)
end
assertContains(devLog, "00_Command_Center/Daily Dev Log.md", "dev_log must write to vault")
assertContains(devLog, 'runGit({ "status", "--short" })', "dev_log must record changed files")
assertContains(devLog, 'runGit({ "log", "--oneline", "-5" })', "dev_log must record commits")
assertContains(devLog, "collectOpenTasks", "dev_log must capture open gates/tasks")

assertContains(freshSetup, "Complete G1 first", "fresh setup must call out G1")
assertContains(freshSetup, "g1-tool-closure.md", "fresh setup must link G1 closure runbook")
assertContains(freshSetup, "rokit install", "fresh setup must install Rokit tools")
assertContains(freshSetup, "wally install", "fresh setup must install Wally packages")
assertContains(freshSetup, "./nexus.ps1 check", "fresh setup must run the quality gate")
assertContains(
	freshSetup,
	"./nexus.ps1 release --dry-run --fixture",
	"fresh setup must mention release dry-run"
)
assertContains(freshSetup, "Local REST API", "fresh setup must include Obsidian REST plugin")
assertContains(freshSetup, "./nexus.ps1 cold-boot", "fresh setup must include cold-boot readiness")

assertContains(disasterRecovery, "File > Save to File", "recovery must document Studio save")
assertContains(
	disasterRecovery,
	"80_Archives\\StudioSnapshots",
	"recovery must point to Studio snapshot archive"
)
assertContains(disasterRecovery, "./nexus.ps1 sync", "recovery must regenerate vault notes")
assertContains(disasterRecovery, "./nexus.ps1 health", "recovery must refresh Build Health")

if fs.isDir(VAULT_ROOT) then
	assertTrue(
		fs.isDir(VAULT_ROOT .. "/80_Archives/StudioSnapshots"),
		"Vault Studio snapshot archive directory must exist"
	)
	assertTrue(
		fs.isFile(VAULT_ROOT .. "/00_Command_Center/Daily Dev Log.md"),
		"Vault Daily Dev Log must exist"
	)
end

print("Command center contract tests passed")
