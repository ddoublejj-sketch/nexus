--!strict

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local VAULT_ROOT = "C:/Users/jackw/Roblox/RobloxGameVault"
local SCRIPT_PATH = "tools/cold_boot_readiness.luau"
local LAUNCHER_PATH = "nexus.ps1"
local TASKS_PATH = ".vscode/tasks.json"
local DASHBOARD_PATH = VAULT_ROOT .. "/00_Command_Center/Dashboard.md"
local NOTE_PATH = VAULT_ROOT .. "/00_Command_Center/Cold Boot Readiness.md"

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

local script = read(SCRIPT_PATH)
assertContains(script, "Cold Boot Readiness", "script must write the Cold Boot Readiness note")
assertContains(script, "BLOCKED_ON_G2_G3", "script must preserve G2/G3 blocker status")
assertContains(script, "Studio plugin connected", "script must inspect G2 receipt markers")
assertContains(script, "Dashboard rendered in Obsidian", "script must inspect G3 receipt markers")
assertContains(
	script,
	"This note does not replace G2/G3 proof",
	"script must reject using readiness as human proof"
)

local launcher = read(LAUNCHER_PATH)
assertContains(launcher, '"cold-boot" {', "launcher must expose cold-boot command")
assertContains(
	launcher,
	'Invoke-Tool "lune" @("run", "tools/cold_boot_readiness.luau")',
	"launcher must run cold_boot_readiness"
)
assertContains(
	launcher,
	'Invoke-LoopScript "tools/cold_boot_readiness.luau"',
	"launcher loop must refresh cold-boot readiness"
)

local tasks = serde.decode("json", read(TASKS_PATH)) :: any
local foundTask = false
for _, task in tasks.tasks do
	if task.label == "Nexus: Cold Boot Readiness" then
		assertTrue(
			task.command == "./nexus.ps1 cold-boot",
			"Cold Boot Readiness task command mismatch"
		)
		foundTask = true
		break
	end
end
assertTrue(foundTask, "VS Code tasks must expose cold-boot readiness")

local dashboard = read(DASHBOARD_PATH)
assertContains(dashboard, "![[Cold Boot Readiness]]", "dashboard must embed Cold Boot Readiness")

if fs.isFile(NOTE_PATH) then
	local note = read(NOTE_PATH)
	assertContains(note, "# Cold Boot Readiness", "note missing title")
	assertContains(note, "| Area | Check | Status | Detail |", "note missing readiness table")
	assertContains(note, "G2 Studio Connect", "note missing G2 readiness row")
	assertContains(note, "G3 Obsidian Dashboard", "note missing G3 readiness row")
	assertContains(
		note,
		"This note does not replace G2/G3 proof",
		"note must not replace human proof"
	)
end

print("Cold boot readiness tests passed")
