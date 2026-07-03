--!strict

local fs = require("@lune/fs")

local STATUS_PATH = "docs/STATUS.md"
local QUALITY_GATE_PATH = "tools/lib/QualityGate.luau"

local REQUIRED_GATE_LABELS = {
	"Wally Install",
	"StyLua",
	"Selene",
	"Sourcemap",
	"Tool Gap Contract Tests",
	"G1 Tool Closure Tests",
	"Rojo Bridge Tests",
	"Migration Tests",
	"DataService Contract Tests",
	"Vault Scaffold Tests",
	"Obsidian Plugin Setup Tests",
	"Asset Manifest Tests",
	"Command Surface Tests",
	"Net Contract Tests",
	"CI Contract Tests",
	"Command Center Contract Tests",
	"Human Gate Checklist Tests",
	"Human Gate Readiness Tests",
	"Human Gate Acceptance Tests",
	"Human Gate Receipt Tests",
	"Founder Sign-Off Audit Tests",
	"Acceptance Matrix Contract Tests",
	"Release Contract Tests",
	"Secret Scan",
	"Analyze",
	"Build",
	"Open Cloud Dry Run",
}

local EXPECTED_ROWS = {
	{
		id = "WO-0 Tool Gaps",
		status = "Exact G1 acceptance passed",
		evidence = "portable gh/Blender/Obsidian shim proof",
		blocker = "None locally",
	},
	{
		id = "WO-1 Bootstrap",
		status = "Exact local acceptance passed",
		evidence = "`./nexus.ps1 check`",
		blocker = "None locally",
	},
	{
		id = "WO-2 Studio Bridge",
		status = "Runbook added, live bridge blocked",
		evidence = "Rojo bridge tests",
		blocker = "G2:",
	},
	{
		id = "WO-3 Vault",
		status = "Scaffolded, REST blocked",
		evidence = "vault scaffold tests",
		blocker = "G3:",
	},
	{
		id = "WO-4 Automation Loop",
		status = "Exact local launcher proof passed",
		evidence = "`./nexus.ps1 loop --once`",
		blocker = "Dashboard render needs G3",
	},
	{
		id = "WO-5 Asset Pipeline",
		status = "Implemented with seed assets",
		evidence = "asset manifest tests",
		blocker = "Dashboard render needs G3",
	},
	{
		id = "WO-6 Cmdr",
		status = "Implemented and analyzed",
		evidence = "generated command docs",
		blocker = "G2 Studio playtest",
	},
	{
		id = "WO-7 Data/Networking",
		status = "Implemented and tested locally",
		evidence = "DataService contract tests",
		blocker = "G2 Studio playtest",
	},
	{
		id = "WO-8 CI",
		status = "Local workflow committed",
		evidence = "CI contract tests",
		blocker = "G4:",
	},
	{
		id = "WO-9 Release Path",
		status = "Dry-run accepted locally",
		evidence = "release contract tests",
		blocker = "G5",
	},
	{
		id = "WO-10 Hardening",
		status = "Up/down smoke test passed locally",
		evidence = "`./nexus.ps1 up/status/down`",
		blocker = "G2 Studio connect and G3 dashboard render",
	},
}

local WORK_ORDER_HEADINGS = {
	"## WO-0 - Close the Tool Gaps",
	"## WO-1 - Bootstrap the Nexus Repo",
	"## WO-2 - Studio Bridge",
	"## WO-3 - Obsidian Command Vault",
	"## WO-4 - Live Project Indexer",
	"## WO-5 - Asset Pipeline",
	"## WO-6 - In-Game Developer Console",
	"## WO-7 - Data & Networking Baseline",
	"## WO-8 - CI",
	"## WO-9 - Release Path",
	"## WO-10 - Command Center Hardening",
}

type MatrixRow = {
	status: string,
	evidence: string,
	blocker: string,
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

local function section(contents: string, heading: string, nextHeading: string?): string
	local escapedHeading = heading:gsub("([^%w])", "%%%1")
	if nextHeading then
		local escapedNext = nextHeading:gsub("([^%w])", "%%%1")
		return contents:match(escapedHeading .. "%s*(.-)%s*" .. escapedNext) or ""
	end

	return contents:match(escapedHeading .. "%s*(.*)") or ""
end

local status = read(STATUS_PATH)
local qualityGate = read(QUALITY_GATE_PATH)

for _, heading in WORK_ORDER_HEADINGS do
	assertContains(status, heading, "Missing section " .. heading)
end

local matrix = section(status, "## Acceptance Matrix", "## Latest Whole-Repo Verification")
assertTrue(matrix ~= "", "Missing Acceptance Matrix section")

local rows: { [string]: MatrixRow } = {}
local rowCount = 0
for line in matrix:gmatch("[^\r\n]+") do
	if line:match("^| WO%-") then
		local id, rowStatus, evidence, blocker =
			line:match("^|%s*(.-)%s*|%s*(.-)%s*|%s*(.-)%s*|%s*(.-)%s*|%s*$")
		if id and rowStatus and evidence and blocker then
			rows[id] = {
				status = rowStatus,
				evidence = evidence,
				blocker = blocker,
			}
			rowCount += 1
		end
	end
end

assertTrue(rowCount == #EXPECTED_ROWS, "Acceptance Matrix must have one row per WO-0 through WO-10")

for _, expected in EXPECTED_ROWS do
	local row = rows[expected.id]
	assertTrue(row ~= nil, "Missing matrix row " .. expected.id)
	assertContains(row.status, expected.status, "Wrong local status for " .. expected.id)
	assertContains(row.evidence, expected.evidence, "Missing evidence in " .. expected.id)
	assertContains(row.blocker, expected.blocker, "Missing blocker in " .. expected.id)
end

assertContains(status, "WO-0 G1 tool closure now passes locally", "Current phase must close G1")
assertContains(status, "blocked on **G2 - Studio connect**", "Current phase must preserve G2")
assertContains(
	status,
	"blocked on **G3 - Obsidian REST key + dashboard proof**",
	"Current phase must preserve G3"
)
assertContains(status, "blocked on **G4 - GitHub auth**", "Current phase must preserve G4")
assertContains(status, "gated on **G5 - Open Cloud key**", "Current phase must preserve G5")
assertContains(
	status,
	"not complete",
	"STATUS must explicitly mark gate-dependent work as incomplete"
)

local latest = section(status, "## Latest Whole-Repo Verification", nil)
assertTrue(latest ~= "", "Missing Latest Whole-Repo Verification section")
assertContains(latest, "./nexus.ps1 check", "Latest verification must run launcher check")
assertContains(latest, "Quality gate PASS", "Latest verification must include gate pass")
assertContains(
	latest,
	"./nexus.ps1 health",
	"Latest verification must include Build Health refresh"
)

for _, label in REQUIRED_GATE_LABELS do
	assertContains(qualityGate, '"' .. label .. '"', "Shared gate missing label " .. label)
	assertContains(latest, "[PASS] " .. label, "Latest verification missing PASS for " .. label)
end

assertContains(
	matrix,
	"lune run tools/test_acceptance_matrix_contract.luau",
	"Acceptance Matrix must include direct contract command"
)
assertContains(
	matrix,
	"Acceptance matrix contract tests passed",
	"Acceptance Matrix must include direct contract output"
)

print("Acceptance matrix contract tests passed")
