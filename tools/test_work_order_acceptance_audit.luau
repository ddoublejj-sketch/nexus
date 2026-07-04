--!strict

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local VAULT_ROOT = "C:/Users/jackw/Roblox/RobloxGameVault"
local SCRIPT_PATH = "tools/work_order_acceptance_audit.luau"
local LAUNCHER_PATH = "nexus.ps1"
local TASKS_PATH = ".vscode/tasks.json"
local DASHBOARD_PATH = VAULT_ROOT .. "/00_Command_Center/Dashboard.md"
local NOTE_PATH = VAULT_ROOT .. "/00_Command_Center/Work Order Acceptance Audit.md"

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
assertContains(script, "master plan Section 7", "audit must cite Section 7")
assertContains(script, "BLOCKED_ON_HUMAN_GATE", "audit must preserve human-gate blockers")
assertContains(script, "LOCAL_EVIDENCE_MISSING", "audit must fail on missing local evidence")

for index = 0, 10 do
	assertContains(script, "WO-" .. tostring(index), "audit script missing WO-" .. tostring(index))
end

for _, gate in { "G2", "G3", "G4", "G5" } do
	assertContains(script, gate, "audit script missing " .. gate)
end

local launcher = read(LAUNCHER_PATH)
assertContains(launcher, '"wo-audit" {', "launcher must expose wo-audit command")
assertContains(
	launcher,
	'Invoke-Tool "lune" @("run", "tools/work_order_acceptance_audit.luau")',
	"launcher must run work_order_acceptance_audit"
)
assertContains(launcher, '"loop" {', "launcher must expose loop command")
assertContains(
	launcher,
	'"tools/work_order_acceptance_audit.luau"',
	"launcher loop must refresh work-order acceptance audit"
)

local tasks = serde.decode("json", read(TASKS_PATH)) :: any
local foundTask = false
for _, task in tasks.tasks do
	if task.label == "Nexus: Work Order Acceptance Audit" then
		assertTrue(
			task.command == "./nexus.ps1 wo-audit",
			"Work Order Acceptance Audit task command mismatch"
		)
		foundTask = true
		break
	end
end
assertTrue(foundTask, "VS Code tasks must expose Work Order Acceptance Audit")

local dashboard = read(DASHBOARD_PATH)
assertContains(
	dashboard,
	"![[Work Order Acceptance Audit]]",
	"dashboard must embed Work Order Acceptance Audit"
)

if fs.isFile(NOTE_PATH) then
	local note = read(NOTE_PATH)
	assertContains(note, "# Work Order Acceptance Audit", "note missing title")
	assertContains(note, "Overall: BLOCKED_ON_HUMAN_GATES", "note must preserve human blockers")
	assertContains(note, "not completion evidence", "note must reject blocked rows as completion")
	for index = 0, 10 do
		assertContains(note, "WO-" .. tostring(index), "note missing WO-" .. tostring(index))
	end
	assertContains(
		note,
		"All local evidence checks are present",
		"note must summarize local evidence state"
	)
end

print("Work order acceptance audit tests passed")
