--!strict

local fs = require("@lune/fs")

local WORKFLOW_PATH = ".github/workflows/ci.yml"
local LAUNCHER_PATH = "nexus.ps1"
local BUILD_HEALTH_PATH = "tools/build_health.luau"
local QUALITY_GATE_PATH = "tools/lib/QualityGate.luau"
local RUNBOOK_PATH = "docs/runbooks/github-ci.md"

local REQUIRED_GATE_LABELS = {
	"Wally Install",
	"StyLua",
	"Selene",
	"Sourcemap",
	"Tool Gap Contract Tests",
	"Rojo Bridge Tests",
	"Migration Tests",
	"DataService Contract Tests",
	"Vault Scaffold Tests",
	"Asset Manifest Tests",
	"Command Surface Tests",
	"Net Contract Tests",
	"CI Contract Tests",
	"Command Center Contract Tests",
	"Human Gate Checklist Tests",
	"Human Gate Readiness Tests",
	"Acceptance Matrix Contract Tests",
	"Release Contract Tests",
	"Secret Scan",
	"Analyze",
	"Build",
	"Open Cloud Dry Run",
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

local workflow = read(WORKFLOW_PATH)
local launcher = read(LAUNCHER_PATH)
local buildHealth = read(BUILD_HEALTH_PATH)
local qualityGate = read(QUALITY_GATE_PATH)
local runbook = read(RUNBOOK_PATH)

assertContains(workflow, "runs-on: windows-latest", "CI must run on Windows")
assertContains(workflow, "actions/checkout@v4", "CI must checkout the repo")
assertContains(workflow, "rokit install", "CI must install pinned project tools")
assertContains(workflow, "lune run tools/quality_gate.luau", "CI must call the shared quality gate")
assertContains(workflow, "actions/upload-artifact@v4", "CI must upload the place artifact")
assertContains(workflow, "path: build/nexus.rbxl", "CI artifact path must be build/nexus.rbxl")
assertContains(
	workflow,
	"if-no-files-found: error",
	"CI artifact upload must fail on missing build"
)
assertNotContains(
	workflow,
	"stylua --check",
	"CI must not duplicate StyLua outside the shared gate"
)
assertNotContains(workflow, "selene src", "CI must not duplicate Selene outside the shared gate")
assertNotContains(
	workflow,
	"luau-lsp analyze",
	"CI must not duplicate analyzer outside the shared gate"
)
assertNotContains(workflow, "rojo build", "CI must not duplicate build outside the shared gate")

assertContains(
	launcher,
	'Invoke-Tool "lune" @("run", "tools/quality_gate.luau")',
	"nexus.ps1 check must call the shared quality gate"
)
assertContains(buildHealth, "local QualityGate = require", "Build Health must require QualityGate")
assertContains(buildHealth, "QualityGate.runAll", "Build Health must run the shared gate")
assertContains(buildHealth, "QualityGate.allPassed", "Build Health must use shared pass/fail logic")

for _, label in REQUIRED_GATE_LABELS do
	assertContains(qualityGate, '"' .. label .. '"', "Shared gate missing " .. label)
end

assertContains(runbook, "tools/quality_gate.luau", "CI runbook must name the shared gate")
assertContains(runbook, "./nexus.ps1 check", "CI runbook must document local launcher parity")
assertContains(runbook, "lune run tools/quality_gate.luau", "CI runbook must document direct gate")
assertContains(runbook, "gh auth login", "CI runbook must document G4 authentication")
assertContains(runbook, "branch protection", "CI runbook must document branch protection")
assertContains(runbook, "Nexus CI / Quality Gate", "CI runbook must name the required check")

print("CI contract tests passed")
