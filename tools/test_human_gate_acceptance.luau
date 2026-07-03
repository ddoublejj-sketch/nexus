--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")

local SCRIPT_PATH = "tools/human_gate_acceptance.luau"
local LAUNCHER_PATH = "nexus.ps1"
local TASKS_PATH = ".vscode/tasks.json"
local README_PATH = "README.md"
local CHECKLIST_SCRIPT_PATH = "tools/human_gate_checklist.luau"
local READINESS_SCRIPT_PATH = "tools/human_gate_readiness.luau"
local STATUS_PATH = "docs/STATUS.md"

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
local launcher = read(LAUNCHER_PATH)
local readme = read(README_PATH)
local checklistScript = read(CHECKLIST_SCRIPT_PATH)
local readinessScript = read(READINESS_SCRIPT_PATH)
local status = read(STATUS_PATH)
local tasks = serde.decode("json", read(TASKS_PATH)) :: any

for _, gate in { "G1", "G2", "G3", "G4", "G5" } do
	assertContains(script, gate, "probe missing " .. gate)
end

assertContains(script, "--self-test", "probe must include self-test mode")
assertContains(script, "process.exit(1)", "probe must fail when gates are blocked")
assertContains(script, "values not printed", "probe must not print secret values")
assertContains(script, "NEEDS HUMAN", "probe must represent human-only checks")
assertContains(
	script,
	"Obsidian plugins preinstalled and enabled",
	"probe must verify Obsidian plugin preinstall separately from REST key proof"
)
assertContains(script, "Human gate acceptance BLOCKED", "probe must report blocked state")
assertContains(script, "Human gate acceptance PASS", "probe must report accepted state")

assertContains(launcher, '"gatecheck" {', "launcher must expose gatecheck subcommand")
assertContains(
	launcher,
	'Invoke-Tool "lune" (@("run", "tools/human_gate_acceptance.luau") + $Rest)',
	"launcher must forward gatecheck arguments"
)

local foundTask = false
for _, task in tasks.tasks do
	if task.label == "Nexus: Gate Acceptance Probe" then
		foundTask = task.command == "./nexus.ps1 gatecheck --self-test"
		break
	end
end
assertTrue(foundTask, "VS Code tasks must include Nexus: Gate Acceptance Probe")

assertContains(readme, "./nexus.ps1 gatecheck --self-test", "README must document gatecheck")
assertContains(
	checklistScript,
	"./nexus.ps1 gatecheck --gate G1",
	"checklist must document gate-specific probe usage"
)
assertContains(
	readinessScript,
	"./nexus.ps1 gatecheck --self-test",
	"readiness note must document probe self-test usage"
)
assertContains(
	status,
	"lune run tools/test_human_gate_acceptance.luau",
	"STATUS must include direct gate acceptance contract proof"
)

local selfTest = process.exec("lune", {
	"run",
	"tools/human_gate_acceptance.luau",
	"--self-test",
})
assertTrue(selfTest.ok, "gate acceptance self-test must exit 0")
assertContains(selfTest.stdout, "Human gate acceptance probe self-test PASS", "self-test output")

local normalProbe = process.exec("lune", {
	"run",
	"tools/human_gate_acceptance.luau",
	"--gate",
	"G2",
})
assertTrue(not normalProbe.ok, "normal G2 probe must remain blocked until human proof exists")
assertContains(normalProbe.stdout, "NEEDS HUMAN", "normal probe must show human blocker")

print("Human gate acceptance tests passed")
