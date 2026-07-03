--!strict

local fs = require("@lune/fs")

local VAULT_ROOT = "C:/Users/jackw/Roblox/RobloxGameVault"
local OUTPUT_PATH = VAULT_ROOT .. "/00_Command_Center/Work Order Acceptance Audit.md"
local STATUS_PATH = "docs/STATUS.md"

type Requirement = {
	label: string,
	path: string,
	needle: string,
}

type WorkOrder = {
	id: string,
	title: string,
	blocker: string?,
	requirements: { Requirement },
}

local WORK_ORDERS: { WorkOrder } = {
	{
		id = "WO-0",
		title = "Close the Tool Gaps",
		requirements = {
			{
				label = "git version pasted",
				path = STATUS_PATH,
				needle = "git version 2.54.0.windows.1",
			},
			{ label = "rokit version pasted", path = STATUS_PATH, needle = "rokit 1.2.0" },
			{ label = "rojo version pasted", path = STATUS_PATH, needle = "Rojo 7.7.0" },
			{ label = "code version pasted", path = STATUS_PATH, needle = "code available | PASS" },
			{ label = "gh version pasted", path = STATUS_PATH, needle = "gh version 2.96.0" },
			{ label = "blender command proof", path = STATUS_PATH, needle = "blender.cmd" },
		},
	},
	{
		id = "WO-1",
		title = "Bootstrap the Nexus Repo",
		requirements = {
			{ label = "rokit install output", path = STATUS_PATH, needle = "rokit install" },
			{ label = "wally install output", path = STATUS_PATH, needle = "wally install" },
			{
				label = "rojo build output",
				path = STATUS_PATH,
				needle = "Built project to nexus.rbxl",
			},
			{
				label = "rojo sourcemap output",
				path = STATUS_PATH,
				needle = "Created sourcemap at sourcemap.json",
			},
			{ label = "quality gate output", path = STATUS_PATH, needle = "Quality gate PASS" },
			{ label = "commit log output", path = STATUS_PATH, needle = "git log --oneline" },
		},
	},
	{
		id = "WO-2",
		title = "Studio Bridge",
		blocker = "G2 Studio connect and live sync proof",
		requirements = {
			{
				label = "sync runbook exists",
				path = "docs/runbooks/rojo-sync-rules.md",
				needle = "Pending G2 test",
			},
			{
				label = "sourcemap-aware analyze",
				path = STATUS_PATH,
				needle = "luau-lsp analyze --definitions types/globalTypes.d.luau --sourcemap sourcemap.json src",
			},
			{ label = "G2 request recorded", path = STATUS_PATH, needle = "Human Gate G2 Request" },
			{
				label = "G2 blocker preserved",
				path = STATUS_PATH,
				needle = "live disk-to-Studio and syncback behavior remains unverified",
			},
		},
	},
	{
		id = "WO-3",
		title = "Obsidian Command Vault",
		blocker = "G3 Local REST key, pending flush, dashboard render",
		requirements = {
			{
				label = "vault scaffold proof",
				path = STATUS_PATH,
				needle = "Vault scaffold tests passed",
			},
			{
				label = "vault ping proof",
				path = STATUS_PATH,
				needle = "lune run tools/vault_ping.luau",
			},
			{
				label = "plugin setup proof",
				path = STATUS_PATH,
				needle = "Obsidian plugin setup tests passed",
			},
			{
				label = "REST bootstrap proof",
				path = STATUS_PATH,
				needle = "Obsidian REST bootstrap tests passed",
			},
			{
				label = "G3 blocker preserved",
				path = STATUS_PATH,
				needle = "REST/dashboard acceptance remains blocked",
			},
		},
	},
	{
		id = "WO-4",
		title = "Live Project Indexer",
		blocker = "G3 dashboard render",
		requirements = {
			{
				label = "sourcemap generated",
				path = STATUS_PATH,
				needle = "Wrote 133 sourcemap rows",
			},
			{
				label = "module notes generated",
				path = STATUS_PATH,
				needle = "Wrote 13 module notes",
			},
			{
				label = "command registry generated",
				path = STATUS_PATH,
				needle = "Wrote 7 command rows",
			},
			{ label = "Build Health updated", path = STATUS_PATH, needle = "Build health PASS" },
			{
				label = "stale-source proof",
				path = STATUS_PATH,
				needle = "dummy-service/stale-note evidence",
			},
		},
	},
	{
		id = "WO-5",
		title = "Asset Pipeline",
		blocker = "G3 dashboard render",
		requirements = {
			{
				label = "seed catalog count",
				path = STATUS_PATH,
				needle = "Asset manifest reconciled 4 assets",
			},
			{ label = "asset manifest tests", path = STATUS_PATH, needle = "Asset Manifest Tests" },
			{
				label = "thumbnail proof",
				path = STATUS_PATH,
				needle = "Blender-rendered PNG thumbnails",
			},
			{
				label = "orphan detection proof",
				path = STATUS_PATH,
				needle = "Orphan repair demonstration",
			},
		},
	},
	{
		id = "WO-6",
		title = "In-Game Developer Console",
		blocker = "G2 Studio playtest",
		requirements = {
			{
				label = "Cmdr dependency",
				path = STATUS_PATH,
				needle = 'Cmdr = "evaera/cmdr@1.12.0"',
			},
			{
				label = "seven commands listed",
				path = STATUS_PATH,
				needle = "exactly seven command definition modules",
			},
			{ label = "command registry proof", path = STATUS_PATH, needle = "Commands.md rows" },
			{ label = "profilewipe guard proof", path = STATUS_PATH, needle = "CONFIRM_WIPE" },
			{
				label = "reloadmap MapService proof",
				path = STATUS_PATH,
				needle = "MapService contract tests passed",
			},
		},
	},
	{
		id = "WO-7",
		title = "Data & Networking Baseline",
		blocker = "G2 Studio runtime behavior",
		requirements = {
			{
				label = "ProfileStore dependency",
				path = STATUS_PATH,
				needle = 'ProfileStore = "lm-loleris/profilestore@1.0.3"',
			},
			{ label = "migration tests", path = STATUS_PATH, needle = "Migration fixtures passed" },
			{
				label = "DataService contract",
				path = STATUS_PATH,
				needle = "DataService contract tests passed",
			},
			{ label = "Net contract", path = STATUS_PATH, needle = "Net contract tests passed" },
			{
				label = "runtime blocker preserved",
				path = STATUS_PATH,
				needle = "Actual Studio/runtime observation is still pending G2",
			},
		},
	},
	{
		id = "WO-8",
		title = "CI",
		blocker = "G4 GitHub auth, remote, branch protection, real CI run",
		requirements = {
			{
				label = "workflow exists",
				path = ".github/workflows/ci.yml",
				needle = "tools/quality_gate.luau",
			},
			{
				label = "CI contract proof",
				path = STATUS_PATH,
				needle = "CI contract tests passed",
			},
			{
				label = "GitHub bootstrap proof",
				path = STATUS_PATH,
				needle = "GitHub CI bootstrap tests passed",
			},
			{
				label = "G4 blocker preserved",
				path = STATUS_PATH,
				needle = "GitHub auth, repo creation, push, and branch protection still require G4",
			},
		},
	},
	{
		id = "WO-9",
		title = "Release Path",
		blocker = "G5 Open Cloud key for live publish",
		requirements = {
			{
				label = "fixture dry run",
				path = STATUS_PATH,
				needle = "Open Cloud publish dry-run PASS",
			},
			{
				label = "release contract",
				path = STATUS_PATH,
				needle = "Release contract tests passed",
			},
			{ label = "secret scan", path = STATUS_PATH, needle = "Secret scan passed" },
			{
				label = "release checklist",
				path = "docs/runbooks/release-checklist.md",
				needle = "Complete G5",
			},
			{
				label = "G5 blocker preserved",
				path = STATUS_PATH,
				needle = "live publish was intentionally not attempted",
			},
		},
	},
	{
		id = "WO-10",
		title = "Command Center Hardening",
		blocker = "G2 Studio connect and G3 dashboard render for cold boot",
		requirements = {
			{
				label = "up/down proof",
				path = STATUS_PATH,
				needle = "./nexus.ps1 up; Start-Sleep -Seconds",
			},
			{
				label = "command-center contract",
				path = STATUS_PATH,
				needle = "Command center contract tests passed",
			},
			{
				label = "cold-boot readiness",
				path = STATUS_PATH,
				needle = "Cold boot readiness BLOCKED_ON_G2_G3",
			},
			{
				label = "founder sign-off audit",
				path = STATUS_PATH,
				needle = "Founder Sign-Off Audit Tests",
			},
			{
				label = "acceptance matrix",
				path = STATUS_PATH,
				needle = "Acceptance Matrix contract self-test",
			},
		},
	},
}

local function isoTimestamp(): string
	return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

local function readOptional(path: string): string
	if not fs.isFile(path) then
		return ""
	end

	return fs.readFile(path)
end

local function markdownEscape(value: string): string
	return value:gsub("|", "\\|"):gsub("\r", " "):gsub("\n+", " ")
end

local function requirementPassed(requirement: Requirement): boolean
	return readOptional(requirement.path):find(requirement.needle, 1, true) ~= nil
end

local failures = {}
local rows = {}
local humanBlocked = false

for _, workOrder in WORK_ORDERS do
	local missing = {}
	for _, requirement in workOrder.requirements do
		if not requirementPassed(requirement) then
			table.insert(missing, requirement.label)
		end
	end

	if #missing > 0 then
		table.insert(failures, workOrder.id .. " missing " .. table.concat(missing, ", "))
	end

	local status = if #missing > 0
		then "LOCAL_EVIDENCE_MISSING"
		elseif workOrder.blocker ~= nil then "BLOCKED_ON_HUMAN_GATE"
		else "PASS"

	if workOrder.blocker ~= nil then
		humanBlocked = true
	end

	table.insert(rows, {
		id = workOrder.id,
		title = workOrder.title,
		status = status,
		evidence = if #missing > 0
			then "Missing: " .. table.concat(missing, ", ")
			else tostring(#workOrder.requirements) .. " evidence checks present",
		blocker = workOrder.blocker or "None",
	})
end

local overall = if #failures > 0
	then "LOCAL_EVIDENCE_MISSING"
	elseif humanBlocked then "BLOCKED_ON_HUMAN_GATES"
	else "PASS"

local now = isoTimestamp()
local lines = {
	"---",
	"type: system",
	"status: active",
	"owner:",
	"source_path: C:\\Users\\jackw\\Roblox\\nexus\\tools\\work_order_acceptance_audit.luau",
	"roblox_asset_id:",
	"studio_instance_path:",
	"dependencies:",
	"last_synced: " .. now,
	"tags: gates, acceptance, work-orders",
	"---",
	"",
	"# Work Order Acceptance Audit",
	"",
	"Generated: " .. now,
	"",
	"Overall: " .. overall,
	"",
	"This note maps the master plan Section 7 work-order acceptance evidence to current local proof. `BLOCKED_ON_HUMAN_GATE` is not completion evidence.",
	"",
	"| Work Order | Acceptance Status | Evidence | Remaining Blocker |",
	"| --- | --- | --- | --- |",
}

for _, row in rows do
	table.insert(
		lines,
		("| %s - %s | %s | %s | %s |"):format(
			row.id,
			markdownEscape(row.title),
			row.status,
			markdownEscape(row.evidence),
			markdownEscape(row.blocker)
		)
	)
end

table.insert(lines, "")
table.insert(lines, "## Audit Result")
table.insert(lines, "")

if #failures > 0 then
	table.insert(lines, "Local evidence gaps:")
	table.insert(lines, "")
	for _, failure in failures do
		table.insert(lines, "- " .. failure)
	end
else
	table.insert(
		lines,
		"All local evidence checks are present. Remaining non-pass rows require G2, G3, G4, or G5 human proof."
	)
end

if not fs.isDir(VAULT_ROOT .. "/00_Command_Center") then
	error("Missing vault command center folder: " .. VAULT_ROOT .. "/00_Command_Center")
end

fs.writeFile(OUTPUT_PATH, table.concat(lines, "\n") .. "\n")
print("Work order acceptance audit " .. overall .. "; wrote " .. OUTPUT_PATH)

if #failures > 0 then
	error("Work order acceptance audit has local evidence gaps")
end
