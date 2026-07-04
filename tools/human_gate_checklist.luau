--!strict

local fs = require("@lune/fs")

local STATUS_PATH = "docs/STATUS.md"
local VAULT_ROOT = "C:/Users/jackw/Roblox/RobloxGameVault"
local OUTPUT_PATH = VAULT_ROOT .. "/00_Command_Center/Human Gate Checklist.md"

type Gate = {
	id: string,
	title: string,
	state: string,
	human: { string },
	codex: { string },
	proof: { string },
}

local GATES: { Gate } = {
	{
		id = "G1",
		title = "GUI Installs",
		state = "Closed locally; tool install and PATH repair proof is recorded",
		human = {
			"No current G1 install action remains.",
			"Use `docs/runbooks/g1-tool-closure.md` if this machine loses `code`, `gh`, `obsidian`, or `blender` on PATH.",
		},
		codex = {
			"Run `./nexus.ps1 g1` to refresh the exact local tool audit and install/PATH repair note.",
			"Run `./nexus.ps1 receipts` to refresh the pending proof receipt templates.",
			"Rerun WO-0 acceptance from the Nexus repo if a tool path changes.",
			"Run `./nexus.ps1 thumbnails` after adding or changing exported model assets.",
		},
		proof = {
			"git --version",
			"rokit --version",
			"rojo --version",
			"code --version",
			"gh --version",
			"./nexus.ps1 g1",
			"Get-Command blender -ErrorAction SilentlyContinue",
			"./nexus.ps1 gatecheck --gate G1",
		},
	},
	{
		id = "G2",
		title = "Studio Connect",
		state = "Blocked on Roblox Studio plugin connection and playtest proof",
		human = {
			"Open the target place in Roblox Studio. Current target: Golf Pro.",
			"Run `./nexus.ps1 up` from the Nexus repo.",
			"Run `./nexus.ps1 studio-bridge` to confirm local bridge readiness.",
			"Connect the Rojo Studio plugin to the local server.",
			"Confirm a disk edit appears in Studio within seconds.",
			"Run the disposable syncback/export test from `docs/runbooks/rojo-sync-rules.md`.",
			"Playtest Cmdr command execution and DataService mock-session behavior.",
		},
		codex = {
			"Mark the required markers in `docs/gate-proofs/G2-studio-connect.md` as `PASS` after the live proof exists.",
			"Record observed Studio bridge results in `docs/STATUS.md` and `docs/runbooks/rojo-sync-rules.md`.",
			"Update WO-2, WO-6, WO-7, and WO-10 acceptance evidence after the live proof exists.",
		},
		proof = {
			"./nexus.ps1 receipts",
			"./nexus.ps1 up",
			"./nexus.ps1 studio-bridge",
			"luau-lsp analyze --definitions types/globalTypes.d.luau --sourcemap sourcemap.json src",
			"./nexus.ps1 down",
			"./nexus.ps1 gatecheck --gate G2",
		},
	},
	{
		id = "G3",
		title = "Obsidian REST And Plugins",
		state = "Closed locally; Obsidian REST, plugins, pending flush, and dashboard proof are accepted",
		human = {
			"No current G3 action remains.",
			"Keep Obsidian opened on `C:\\Users\\jackw\\Roblox\\RobloxGameVault` when using REST-backed dashboard refreshes.",
		},
		codex = {
			"Run `./nexus.ps1 obsidian-plugins` if the local plugin bundle files need to be restored.",
			"Run `./nexus.ps1 obsidian-rest` and `lune run tools/vault_ping.luau` if Obsidian REST settings are regenerated.",
			"Rerun `./nexus.ps1 gatecheck --gate G3` after Obsidian or plugin changes.",
		},
		proof = {
			"./nexus.ps1 receipts",
			"./nexus.ps1 obsidian-plugins",
			"./nexus.ps1 obsidian-rest",
			"lune run tools/vault_ping.luau",
			"./nexus.ps1 loop --once",
			"git -C C:\\Users\\jackw\\Roblox\\RobloxGameVault status --short",
			"./nexus.ps1 gatecheck --gate G3",
		},
	},
	{
		id = "G4",
		title = "GitHub Auth And CI",
		state = "Blocked on Nexus branch protection and explicit approval to export the vault repo",
		human = {
			"Approve exporting the separate `RobloxGameVault` Obsidian repo to private GitHub before Codex runs the vault push.",
			"Either upgrade GitHub to Pro or make `ddoublejj-sketch/nexus` public so branch protection can be enabled on the repo.",
		},
		codex = {
			"Run `./nexus.ps1 github-ci --create-vault-private` only after explicit approval.",
			"Enable branch protection requiring the Nexus CI quality gate after GitHub allows it.",
			"Mark the required marker in `docs/gate-proofs/G4-github-ci.md` as `PASS` after branch protection is confirmed.",
			"Demonstrate a failing formatting PR and a fixed passing PR if founder still wants that proof path.",
		},
		proof = {
			"./nexus.ps1 receipts",
			"gh auth status",
			"./nexus.ps1 github-ci",
			"./nexus.ps1 github-ci --create-vault-private",
			"gh pr checks",
			"./nexus.ps1 gatecheck --gate G4",
		},
	},
	{
		id = "G5",
		title = "Open Cloud Key",
		state = "Config and dry-run accepted; blocked only on explicit live publish approval",
		human = {
			"Give explicit live publish approval only when ready to publish the target place.",
		},
		codex = {
			"Mark the required marker in `docs/gate-proofs/G5-open-cloud-publish.md` as `PASS` after explicit live publish approval.",
			"Run fixture dry-run first, then real dry-run with the secret file.",
			"Attempt live publish only after explicit approval and green release checklist.",
		},
		proof = {
			"./nexus.ps1 receipts",
			"./nexus.ps1 open-cloud",
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

local function currentPhase(): string
	if not fs.isFile(STATUS_PATH) then
		return "STATUS.md not found."
	end

	local status = fs.readFile(STATUS_PATH)
	local phase = status:match("## Current Phase%s*(.-)%s*## ")
	if not phase then
		return "Current phase section not found."
	end

	return (phase:match("^%s*(.-)%s*$") or phase):gsub("\n+", " ")
end

local function appendBullets(lines: { string }, items: { string })
	for _, item in items do
		table.insert(lines, "- " .. item)
	end
end

local timestamp = isoTimestamp()
local lines = {
	"---",
	"type: system",
	"status: active",
	"owner:",
	"source_path: C:\\Users\\jackw\\Roblox\\nexus\\tools\\human_gate_checklist.luau",
	"roblox_asset_id:",
	"studio_instance_path:",
	"dependencies:",
	"last_synced: " .. timestamp,
	"tags: gates, checklist",
	"---",
	"",
	"# Human Gate Checklist",
	"",
	"Generated: " .. timestamp,
	"",
	"## Current Phase",
	"",
	currentPhase(),
	"",
	"## Gate Summary",
	"",
	"| Gate | State | Human Action | Codex Follow-Up |",
	"| --- | --- | --- | --- |",
}

for _, gate in GATES do
	table.insert(
		lines,
		("| %s | %s | %d items | %d items |"):format(gate.id, gate.state, #gate.human, #gate.codex)
	)
end

for _, gate in GATES do
	table.insert(lines, "")
	table.insert(lines, ("## %s - %s"):format(gate.id, gate.title))
	table.insert(lines, "")
	table.insert(lines, "**State:** " .. gate.state)
	table.insert(lines, "")
	table.insert(lines, "### Human Action")
	table.insert(lines, "")
	appendBullets(lines, gate.human)
	table.insert(lines, "")
	table.insert(lines, "### Codex Follow-Up")
	table.insert(lines, "")
	appendBullets(lines, gate.codex)
	table.insert(lines, "")
	table.insert(lines, "### Proof Commands")
	table.insert(lines, "")
	table.insert(lines, "```powershell")
	for _, command in gate.proof do
		table.insert(lines, command)
	end
	table.insert(lines, "```")
end

fs.writeFile(OUTPUT_PATH, table.concat(lines, "\n") .. "\n")
print("Wrote human gate checklist to " .. OUTPUT_PATH)
