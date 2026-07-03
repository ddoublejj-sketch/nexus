--!strict

local fs = require("@lune/fs")

local VAULT_ROOT = "C:/Users/jackw/Roblox/RobloxGameVault"
local OUTPUT_PATH = VAULT_ROOT .. "/00_Command_Center/Cold Boot Readiness.md"
local DASHBOARD_PATH = VAULT_ROOT .. "/00_Command_Center/Dashboard.md"
local BUILD_HEALTH_PATH = VAULT_ROOT .. "/00_Command_Center/Build Health.md"
local DEV_LOG_PATH = VAULT_ROOT .. "/00_Command_Center/Daily Dev Log.md"
local G2_RECEIPT_PATH = "docs/gate-proofs/G2-studio-connect.md"
local G3_RECEIPT_PATH = "docs/gate-proofs/G3-obsidian-dashboard.md"

type Check = {
	area: string,
	name: string,
	status: string,
	detail: string,
}

local checks: { Check } = {}

local function isoTimestamp(): string
	return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

local function readOptional(path: string): string?
	if not fs.isFile(path) then
		return nil
	end

	return fs.readFile(path)
end

local function addCheck(area: string, name: string, status: string, detail: string)
	table.insert(checks, {
		area = area,
		name = name,
		status = status,
		detail = detail,
	})
end

local function checkFileContains(area: string, name: string, path: string, needle: string)
	local contents = readOptional(path)
	if contents == nil then
		addCheck(area, name, "FAIL", "missing file: " .. path)
		return
	end

	if contents:find(needle, 1, true) == nil then
		addCheck(area, name, "FAIL", "missing expected marker: " .. needle)
		return
	end

	addCheck(area, name, "PASS", path)
end

local function receiptAccepted(path: string, markers: { string }): (boolean, string)
	local contents = readOptional(path)
	if contents == nil then
		return false, "missing receipt: " .. path
	end

	local pending = {}
	for _, marker in markers do
		if contents:find(marker .. ": PASS", 1, true) == nil then
			table.insert(pending, marker)
		end
	end

	if #pending > 0 then
		return false, "pending markers: " .. table.concat(pending, ", ")
	end

	return true, "receipt markers accepted"
end

checkFileContains("Launcher", "Rojo serve job", "nexus.ps1", "NexusRojoServe")
checkFileContains("Launcher", "Sourcemap watch job", "nexus.ps1", "NexusSourcemapWatch")
checkFileContains("Launcher", "Automation loop job", "nexus.ps1", "NexusAutomationLoop")
checkFileContains("Launcher", "Cold boot command", "nexus.ps1", "tools/cold_boot_readiness.luau")
checkFileContains("Automation", "Sourcemap generated", "sourcemap.json", '"name":"Nexus"')
checkFileContains("Automation", "Build Health green", BUILD_HEALTH_PATH, "Overall: PASS")
checkFileContains("Automation", "Daily Dev Log present", DEV_LOG_PATH, "# Daily Dev Log")
checkFileContains("Dashboard", "Build Health embed", DASHBOARD_PATH, "![[Build Health]]")
checkFileContains("Dashboard", "Gate Status embed", DASHBOARD_PATH, "![[Gate Status]]")
checkFileContains(
	"Dashboard",
	"Cold Boot Readiness embed",
	DASHBOARD_PATH,
	"![[Cold Boot Readiness]]"
)

local g2Ready, g2Detail = receiptAccepted(G2_RECEIPT_PATH, {
	"Studio plugin connected",
	"Studio playtest observed",
})
addCheck("Human Gate", "G2 Studio Connect", if g2Ready then "PASS" else "NEEDS HUMAN", g2Detail)

local g3Ready, g3Detail = receiptAccepted(G3_RECEIPT_PATH, {
	"Dashboard rendered in Obsidian",
})
addCheck("Human Gate", "G3 Obsidian Dashboard", if g3Ready then "PASS" else "NEEDS HUMAN", g3Detail)

local hasLocalFailure = false
for _, check in checks do
	if check.status == "FAIL" then
		hasLocalFailure = true
		break
	end
end

local overall = if hasLocalFailure
	then "LOCAL_CHECKS_FAIL"
	elseif g2Ready and g3Ready then "READY_FOR_COLD_BOOT_ACCEPTANCE"
	else "BLOCKED_ON_G2_G3"

local now = isoTimestamp()
local lines = {
	"---",
	"type: system",
	"status: active",
	"owner:",
	"source_path: C:\\Users\\jackw\\Roblox\\nexus\\tools\\cold_boot_readiness.luau",
	"roblox_asset_id:",
	"studio_instance_path:",
	"dependencies:",
	"last_synced: " .. now,
	"tags:",
	"---",
	"",
	"# Cold Boot Readiness",
	"",
	"Generated: " .. now,
	"",
	"Overall: " .. overall,
	"",
	"This note does not replace G2/G3 proof. It only keeps the local daily-driver readiness checks and remaining human proof in one place.",
	"",
	"| Area | Check | Status | Detail |",
	"| --- | --- | --- | --- |",
}

for _, check in checks do
	table.insert(
		lines,
		("| %s | %s | %s | %s |"):format(check.area, check.name, check.status, check.detail)
	)
end

table.insert(lines, "")
table.insert(lines, "## Final Cold-Boot Proof Path")
table.insert(lines, "")
table.insert(lines, "Run this only after G2 and G3 receipts are real:")
table.insert(lines, "")
table.insert(lines, "```powershell")
table.insert(lines, "./nexus.ps1 up")
table.insert(lines, "# Edit one disk-owned source file and confirm Studio updates.")
table.insert(lines, "./nexus.ps1 status")
table.insert(lines, "./nexus.ps1 loop --once")
table.insert(lines, "./nexus.ps1 health")
table.insert(lines, "./nexus.ps1 down")
table.insert(lines, "./nexus.ps1 gatecheck --gate G2")
table.insert(lines, "./nexus.ps1 gatecheck --gate G3")
table.insert(lines, "```")

if not fs.isDir(VAULT_ROOT .. "/00_Command_Center") then
	error("Missing vault command center folder: " .. VAULT_ROOT .. "/00_Command_Center")
end

fs.writeFile(OUTPUT_PATH, table.concat(lines, "\n") .. "\n")

print("Cold boot readiness " .. overall .. "; wrote " .. OUTPUT_PATH)

if hasLocalFailure then
	error("Cold boot readiness local checks failed")
end
