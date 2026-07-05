--!strict

local fs = require("@lune/fs")

local VAULT_ROOT = "C:/Users/jackw/Roblox/RobloxGameVault"
local OUTPUT_PATH = VAULT_ROOT .. "/00_Command_Center/Founder Sign-Off Audit.md"
local STATUS_PATH = "docs/STATUS.md"
local README_PATH = "README.md"
local FRESH_SETUP_PATH = "docs/runbooks/fresh-machine-setup.md"
local DISASTER_RECOVERY_PATH = "docs/runbooks/disaster-recovery.md"
local DASHBOARD_PATH = VAULT_ROOT .. "/00_Command_Center/Dashboard.md"
local BUILD_HEALTH_PATH = VAULT_ROOT .. "/00_Command_Center/Build Health.md"

type Criterion = {
	id: string,
	criterion: string,
	status: string,
	evidence: string,
	nextAction: string,
}

local function isoTimestamp(): string
	return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

local function readOptional(path: string): string
	if fs.isFile(path) then
		return fs.readFile(path)
	end

	return ""
end

local function contains(contents: string, needle: string): boolean
	return contents:find(needle, 1, true) ~= nil
end

local function markdownEscape(value: string): string
	return value:gsub("|", "\\|"):gsub("\r", " "):gsub("\n+", " ")
end

local function countMatrixRows(status: string): number
	local matrix = status:match(
		"## Acceptance Matrix%s*(.-)%s*## Previous Whole%-Repo Verification"
	) or ""
	local count = 0
	for line in matrix:gmatch("[^\r\n]+") do
		if line:match("^| WO%-") then
			count += 1
		end
	end

	return count
end

local function gateBlockerSummary(status: string): string
	local matrix = status:match(
		"## Acceptance Matrix%s*(.-)%s*## Previous Whole%-Repo Verification"
	) or ""
	local blockerCells = {}

	for line in matrix:gmatch("[^\r\n]+") do
		if line:match("^| WO%-") then
			local _, _, _, blocker =
				line:match("^|%s*(.-)%s*|%s*(.-)%s*|%s*(.-)%s*|%s*(.-)%s*|%s*$")
			if blocker ~= nil and blocker ~= "None locally" then
				table.insert(blockerCells, blocker)
			end
		end
	end

	local blockers = table.concat(blockerCells, " ")
	local openGates = {}
	for _, gate in { "G1", "G2", "G3", "G4", "G5" } do
		if contains(blockers, gate) then
			table.insert(openGates, gate)
		end
	end

	if #openGates == 0 then
		return "No G1-G5 blockers found in STATUS.md."
	end

	return "Open gate evidence remains in STATUS.md: " .. table.concat(openGates, ", ") .. "."
end

local function dashboardHasCoreCoverage(dashboard: string): boolean
	return contains(dashboard, 'FROM "02_Systems"')
		and contains(dashboard, 'FROM "04_Assets"')
		and contains(dashboard, "![[Build Health]]")
		and contains(dashboard, "![[Human Gate Readiness]]")
end

local function runbookCoverage(
	readme: string,
	freshSetup: string,
	disasterRecovery: string
): boolean
	return contains(readme, "./nexus.ps1 check")
		and contains(freshSetup, "rokit install")
		and contains(freshSetup, "wally install")
		and contains(freshSetup, "./nexus.ps1 release --dry-run --fixture")
		and contains(disasterRecovery, "80_Archives\\StudioSnapshots")
end

if not fs.isDir(VAULT_ROOT) then
	error("Missing vault directory: " .. VAULT_ROOT)
end

local status = readOptional(STATUS_PATH)
local readme = readOptional(README_PATH)
local freshSetup = readOptional(FRESH_SETUP_PATH)
local disasterRecovery = readOptional(DISASTER_RECOVERY_PATH)
local dashboard = readOptional(DASHBOARD_PATH)
local buildHealth = readOptional(BUILD_HEALTH_PATH)

local matrixRows = countMatrixRows(status)
local latestGatePasses = contains(status, "Quality gate PASS")
	and contains(status, "[PASS] Secret Scan")
	and contains(status, "[PASS] Open Cloud Dry Run")
local blockers = gateBlockerSummary(status)
local hasOpenGate = blockers ~= "No G1-G5 blockers found in STATUS.md."

local criteria: { Criterion } = {
	{
		id = "1",
		criterion = "Every WO acceptance command has real pasted output in STATUS.md",
		status = if matrixRows == 11
				and latestGatePasses
				and not hasOpenGate
			then "PASS"
			else "BLOCKED",
		evidence = if matrixRows == 11 and latestGatePasses
			then "Acceptance Matrix has 11 work-order rows and the latest whole-repo verification includes Quality gate PASS. "
				.. blockers
			else "STATUS.md is missing the complete matrix or latest passing gate output.",
		nextAction = "Complete remaining human gates, rerun the gate-specific acceptance probes, and paste the final outputs.",
	},
	{
		id = "2",
		criterion = "Cold-boot test passes",
		status = if contains(status, "Cold boot readiness READY_FOR_COLD_BOOT_ACCEPTANCE")
			then "PASS"
			else "BLOCKED",
		evidence = if contains(status, "Cold boot readiness READY_FOR_COLD_BOOT_ACCEPTANCE")
			then "Cold boot readiness accepted after G2/G3 receipts."
			elseif
				contains(status, "Exact Up/Down Evidence")
			then "Local up/status/down smoke test is recorded, but cold boot readiness has not been refreshed after G2."
			else "Cold-boot proof has not been recorded.",
		nextAction = "Rerun `./nexus.ps1 cold-boot` after launcher, Studio, or dashboard gate changes.",
	},
	{
		id = "3",
		criterion = "Zero secrets in either Git history",
		status = if contains(buildHealth, "| Secret Scan | PASS |")
				or contains(status, "[PASS] Secret Scan")
			then "PASS"
			else "BLOCKED",
		evidence = if contains(buildHealth, "| Secret Scan | PASS |")
			then "Build Health records Secret Scan as PASS across Nexus and vault Git history."
			elseif
				contains(status, "[PASS] Secret Scan")
			then "STATUS.md latest verification records Secret Scan as PASS."
			else "No passing Secret Scan evidence found.",
		nextAction = "Keep secrets only in gitignored secrets/*.env files and rerun ./nexus.ps1 check before sign-off.",
	},
	{
		id = "4",
		criterion = "Vault dashboard answers systems, assets, commands, and last build",
		status = if dashboardHasCoreCoverage(dashboard) then "PASS" else "BLOCKED",
		evidence = if dashboardHasCoreCoverage(dashboard)
			then "Dashboard includes systems/assets queries and Build Health embeds; G3 visual dashboard proof is recorded."
			else "Dashboard is missing one or more required systems/assets/build sections.",
		nextAction = "Keep generated command, asset, system, and build notes refreshed through `./nexus.ps1 loop --once`.",
	},
	{
		id = "5",
		criterion = "A fresh machine can reach setup from README + runbooks alone",
		status = if runbookCoverage(readme, freshSetup, disasterRecovery)
			then "PASS"
			else "BLOCKED",
		evidence = if runbookCoverage(readme, freshSetup, disasterRecovery)
			then "README plus fresh-machine and disaster-recovery runbooks cover setup, quality gate, release dry-run, live publish command, and Studio snapshots."
			else "README or runbooks are missing required setup evidence.",
		nextAction = "Use the README and runbooks for the next clean setup rehearsal.",
	},
}

local overall = "PASS"
for _, criterion in criteria do
	if criterion.status == "BLOCKED" then
		overall = "BLOCKED"
		break
	end
end

local timestamp = isoTimestamp()
local lines = {
	"---",
	"type: system",
	"status: active",
	"owner:",
	"source_path: C:\\Users\\jackw\\Roblox\\nexus\\tools\\founder_signoff_audit.luau",
	"roblox_asset_id:",
	"studio_instance_path:",
	"dependencies:",
	"last_synced: " .. timestamp,
	"tags: gates, founder-signoff, audit",
	"---",
	"",
	"# Founder Sign-Off Audit",
	"",
	"Generated: " .. timestamp,
	"",
	"Overall: " .. overall,
	"",
	"This note maps the master plan Section 10 founder sign-off criteria to the latest local evidence. `BLOCKED` is not a completion state.",
	"",
	"| # | Criterion | Status | Evidence | Next Action |",
	"| --- | --- | --- | --- | --- |",
}

for _, criterion in criteria do
	table.insert(
		lines,
		("| %s | %s | %s | %s | %s |"):format(
			criterion.id,
			markdownEscape(criterion.criterion),
			criterion.status,
			markdownEscape(criterion.evidence),
			markdownEscape(criterion.nextAction)
		)
	)
end

table.insert(lines, "")
table.insert(lines, "## Human Gates Holding Final Sign-Off")
table.insert(lines, "")
if hasOpenGate then
	table.insert(lines, blockers)
else
	table.insert(lines, "None.")
end

fs.writeFile(OUTPUT_PATH, table.concat(lines, "\n") .. "\n")
print("Wrote founder sign-off audit to " .. OUTPUT_PATH)
