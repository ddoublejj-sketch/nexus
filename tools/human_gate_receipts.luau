--!strict

local fs = require("@lune/fs")

local VAULT_ROOT = "C:/Users/jackw/Roblox/RobloxGameVault"
local RECEIPT_ROOT = "docs/gate-proofs"
local OUTPUT_PATH = VAULT_ROOT .. "/00_Command_Center/Human Gate Proof Receipts.md"

type Receipt = {
	gate: string,
	title: string,
	path: string,
	requiredMarkers: { string },
	humanSteps: { string },
	proofCommands: { string },
}

local RECEIPTS: { Receipt } = {
	{
		gate = "G2",
		title = "Studio Connect",
		path = RECEIPT_ROOT .. "/G2-studio-connect.md",
		requiredMarkers = {
			"Studio plugin connected",
			"Studio playtest observed",
		},
		humanSteps = {
			"Open the Nexus place in Roblox Studio.",
			"Run `./nexus.ps1 up` and connect the Rojo Studio plugin.",
			"Confirm a disk edit appears in Studio within seconds.",
			"Playtest Cmdr command execution and DataService mock-session behavior.",
		},
		proofCommands = {
			"./nexus.ps1 up",
			"luau-lsp analyze --definitions types/globalTypes.d.luau --sourcemap sourcemap.json src",
			"./nexus.ps1 down",
			"./nexus.ps1 gatecheck --gate G2",
		},
	},
	{
		gate = "G3",
		title = "Obsidian Dashboard",
		path = RECEIPT_ROOT .. "/G3-obsidian-dashboard.md",
		requiredMarkers = {
			"Dashboard rendered in Obsidian",
		},
		humanSteps = {
			"Open `C:\\Users\\jackw\\Roblox\\RobloxGameVault` as an Obsidian vault.",
			"Enable Local REST API, Obsidian Git, Dataview, Tasks, Kanban, Templater, QuickAdd, and Omnisearch.",
			"Create `secrets/obsidian.env`; never paste key values into this receipt.",
			"Confirm the dashboard renders Dataview and Tasks sections.",
		},
		proofCommands = {
			"lune run tools/vault_ping.luau",
			"./nexus.ps1 loop --once",
			"git -C C:\\Users\\jackw\\Roblox\\RobloxGameVault status --short",
			"./nexus.ps1 gatecheck --gate G3",
		},
	},
	{
		gate = "G4",
		title = "GitHub CI",
		path = RECEIPT_ROOT .. "/G4-github-ci.md",
		requiredMarkers = {
			"CI branch protection confirmed",
		},
		humanSteps = {
			"Complete `gh auth login`.",
			"Approve private repo creation for Nexus and RobloxGameVault.",
			"Confirm branch protection requires the Nexus CI quality gate.",
		},
		proofCommands = {
			"gh auth status",
			"gh pr checks",
			"./nexus.ps1 gatecheck --gate G4",
		},
	},
	{
		gate = "G5",
		title = "Open Cloud Publish Approval",
		path = RECEIPT_ROOT .. "/G5-open-cloud-publish.md",
		requiredMarkers = {
			"Live publish approval recorded",
		},
		humanSteps = {
			"Create the smallest-scope Open Cloud key needed to publish the target place.",
			"Create `secrets/opencloud.env`; never paste key, universe ID, or place ID values into this receipt.",
			"Approve live publish only after fixture and real dry-runs pass.",
		},
		proofCommands = {
			"./nexus.ps1 release --dry-run --fixture",
			"lune run tools/open_cloud_publish.luau --dry-run",
			"lune run tools/secret_scan.luau",
			"./nexus.ps1 gatecheck --gate G5",
		},
	},
}

local function isoTimestamp(): string
	return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

local function ensureDir(path: string)
	if not fs.isDir(path) then
		fs.writeDir(path)
	end
end

local function markerLine(marker: string, status: string): string
	return ("- %s: %s"):format(marker, status)
end

local function receiptTemplate(receipt: Receipt): string
	local lines = {
		"# " .. receipt.gate .. " - " .. receipt.title .. " Proof Receipt",
		"",
		"status: pending",
		"gate: " .. receipt.gate,
		"updated: TODO",
		"",
		"## Completion Rule",
		"",
		"Change each required marker from `PENDING` to `PASS` only after the human action has actually been performed and verified. Do not paste secrets, tokens, API keys, universe IDs, or place IDs into this file.",
		"",
		"## Required Markers",
		"",
	}

	for _, marker in receipt.requiredMarkers do
		table.insert(lines, markerLine(marker, "PENDING"))
	end

	table.insert(lines, "")
	table.insert(lines, "## Human Steps")
	table.insert(lines, "")
	for _, step in receipt.humanSteps do
		table.insert(lines, "- " .. step)
	end

	table.insert(lines, "")
	table.insert(lines, "## Evidence Notes")
	table.insert(lines, "")
	table.insert(lines, "- Paste non-secret observations here after the gate is complete.")
	table.insert(
		lines,
		"- Include command output only if it does not reveal secrets or private IDs."
	)

	table.insert(lines, "")
	table.insert(lines, "## Proof Commands")
	table.insert(lines, "")
	table.insert(lines, "```powershell")
	for _, command in receipt.proofCommands do
		table.insert(lines, command)
	end
	table.insert(lines, "```")

	return table.concat(lines, "\n") .. "\n"
end

local function receiptStatus(receipt: Receipt): string
	if not fs.isFile(receipt.path) then
		return "MISSING"
	end

	local contents = fs.readFile(receipt.path)
	for _, marker in receipt.requiredMarkers do
		if not contents:find(marker .. ": PASS", 1, true) then
			return "PENDING"
		end
	end

	return "ACCEPTED"
end

local function markerSummary(receipt: Receipt): string
	local values = {}
	for _, marker in receipt.requiredMarkers do
		table.insert(values, "`" .. marker .. ": PASS`")
	end

	return table.concat(values, "<br>")
end

local function markdownEscape(value: string): string
	return value:gsub("|", "\\|")
end

ensureDir(RECEIPT_ROOT)

for _, receipt in RECEIPTS do
	if not fs.isFile(receipt.path) then
		fs.writeFile(receipt.path, receiptTemplate(receipt))
	end
end

local timestamp = isoTimestamp()
local lines = {
	"---",
	"type: system",
	"status: active",
	"owner:",
	"source_path: C:\\Users\\jackw\\Roblox\\nexus\\tools\\human_gate_receipts.luau",
	"roblox_asset_id:",
	"studio_instance_path:",
	"dependencies:",
	"last_synced: " .. timestamp,
	"tags: gates, receipts",
	"---",
	"",
	"# Human Gate Proof Receipts",
	"",
	"Generated: " .. timestamp,
	"",
	"These receipts let `./nexus.ps1 gatecheck --gate G2` through `--gate G5` convert human-only checks into `PASS` after the matching real-world action is complete. Pending receipts are not completion evidence.",
	"",
	"| Gate | Receipt | Status | Required Accepted Markers |",
	"| --- | --- | --- | --- |",
}

for _, receipt in RECEIPTS do
	table.insert(
		lines,
		("| %s | `%s` | %s | %s |"):format(
			receipt.gate,
			markdownEscape(receipt.path),
			receiptStatus(receipt),
			markerSummary(receipt)
		)
	)
end

fs.writeFile(OUTPUT_PATH, table.concat(lines, "\n") .. "\n")
print("Wrote human gate proof receipts to " .. OUTPUT_PATH)
