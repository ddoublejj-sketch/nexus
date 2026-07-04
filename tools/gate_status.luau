--!strict

local fs = require("@lune/fs")

local STATUS_PATH = "docs/STATUS.md"
local VAULT_ROOT = "C:/Users/jackw/Roblox/RobloxGameVault"
local OUTPUT_PATH = VAULT_ROOT .. "/00_Command_Center/Gate Status.md"

type MatrixRow = {
	workOrder: string,
	localStatus: string,
	evidence: string,
	blocker: string,
}

local function trim(value: string): string
	return value:match("^%s*(.-)%s*$") or ""
end

local function isoTimestamp(): string
	return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

local function markdownEscape(value: string): string
	return value:gsub("|", "\\|")
end

local function currentPhase(status: string): string
	local phase = status:match("## Current Phase%s*(.-)%s*## ")
	if not phase then
		return "Current phase section not found."
	end

	return trim(phase):gsub("\n+", " ")
end

local function acceptanceMatrix(status: string): { MatrixRow }
	local rows = {}
	local matrix =
		status:match("## Acceptance Matrix%s*(.-)%s*## Previous Whole%-Repo Verification")
	if not matrix then
		return rows
	end

	for line in matrix:gmatch("[^\r\n]+") do
		if line:match("^| WO%-") then
			local workOrder, localStatus, evidence, blocker =
				line:match("^|%s*(.-)%s*|%s*(.-)%s*|%s*(.-)%s*|%s*(.-)%s*|%s*$")
			if workOrder and localStatus and evidence and blocker then
				table.insert(rows, {
					workOrder = workOrder,
					localStatus = localStatus,
					evidence = evidence,
					blocker = blocker,
				})
			end
		end
	end

	return rows
end

local function gateRows(rows: { MatrixRow }): { { string } }
	local gates = {
		{ id = "G1", area = "GUI installs", blockers = {} },
		{ id = "G2", area = "Studio connect", blockers = {} },
		{ id = "G3", area = "Obsidian REST/dashboard", blockers = {} },
		{ id = "G4", area = "GitHub auth/remote CI", blockers = {} },
		{ id = "G5", area = "Open Cloud live publish", blockers = {} },
	}

	for _, row in rows do
		for _, gate in gates do
			if row.blocker:find(gate.id, 1, true) then
				table.insert(gate.blockers, row.workOrder .. " - " .. row.blocker)
			end
		end
	end

	local rendered = {}
	for _, gate in gates do
		table.insert(rendered, {
			gate.id,
			gate.area,
			if #gate.blockers == 0
				then "No matrix blocker"
				else table.concat(gate.blockers, "<br>"),
		})
	end

	return rendered
end

if not fs.isFile(STATUS_PATH) then
	error("Missing " .. STATUS_PATH)
end

if not fs.isDir(VAULT_ROOT) then
	error("Missing vault directory: " .. VAULT_ROOT)
end

local status = fs.readFile(STATUS_PATH)
local rows = acceptanceMatrix(status)
local timestamp = isoTimestamp()
local lines = {
	"---",
	"type: system",
	"status: active",
	"owner:",
	"source_path: C:\\Users\\jackw\\Roblox\\nexus\\docs\\STATUS.md",
	"roblox_asset_id:",
	"studio_instance_path:",
	"dependencies:",
	"last_synced: " .. timestamp,
	"tags: gates, status",
	"---",
	"",
	"# Gate Status",
	"",
	"Generated: " .. timestamp,
	"",
	"## Current Phase",
	"",
	currentPhase(status),
	"",
	"## Human Gates",
	"",
	"| Gate | Area | Blocking Work |",
	"| --- | --- | --- |",
}

for _, row in gateRows(rows) do
	table.insert(
		lines,
		("| %s | %s | %s |"):format(
			markdownEscape(row[1]),
			markdownEscape(row[2]),
			markdownEscape(row[3])
		)
	)
end

table.insert(lines, "")
table.insert(lines, "## Work Orders")
table.insert(lines, "")
table.insert(lines, "| Work Order | Local Status | Remaining Gate / Blocker |")
table.insert(lines, "| --- | --- | --- |")

for _, row in rows do
	table.insert(
		lines,
		("| %s | %s | %s |"):format(
			markdownEscape(row.workOrder),
			markdownEscape(row.localStatus),
			markdownEscape(row.blocker)
		)
	)
end

fs.writeFile(OUTPUT_PATH, table.concat(lines, "\n") .. "\n")
print(("Wrote gate status for %d work orders to %s"):format(#rows, OUTPUT_PATH))
