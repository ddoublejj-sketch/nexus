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
		state = "Closed locally; Rojo connected to Golf Pro and Studio playtest proof is accepted",
		human = {
			"No current G2 action remains.",
			"Keep Golf Pro connected through Rojo 7.7.0 when doing Studio-facing work.",
		},
		codex = {
			"Run `./nexus.ps1 up` before Studio-facing work if the local Rojo server is stopped.",
			"Run `./nexus.ps1 studio-bridge` after Studio or Rojo changes.",
			"Rerun `./nexus.ps1 gatecheck --gate G2` if the receipt or target place changes.",
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
		state = "Closed locally; GitHub auth, branch protection, and vault remote proof are accepted",
		human = {
			"No current G4 action remains.",
			"Keep `ddoublejj-sketch/nexus` public unless GitHub Pro branch protection is later available for a private repo.",
		},
		codex = {
			"Use PRs so `master` stays behind the required `Quality Gate` branch protection.",
			"Run `./nexus.ps1 github-ci` if GitHub auth, remotes, or branch protection need to be rechecked.",
			"Run `./nexus.ps1 github-ci --create-vault-private` only if the separate vault remote needs to be recreated.",
			"Rerun `./nexus.ps1 gatecheck --gate G4` after GitHub settings change.",
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
		state = "Closed locally; Open Cloud live publish to Golf Pro is accepted",
		human = {
			"No current G5 action remains.",
			"Keep the Open Cloud key scoped only to the Golf Pro place-publishing permission needed for releases.",
		},
		codex = {
			"Keep the G5 approval receipt accepted.",
			"Run fixture dry-run first, then real dry-run with the secret file.",
			"Run `./nexus.ps1 release --live` only after explicit founder approval for the target place.",
		},
		proof = {
			"./nexus.ps1 receipts",
			"./nexus.ps1 open-cloud",
			"./nexus.ps1 release --dry-run --fixture",
			"lune run tools/open_cloud_publish.luau --dry-run",
			"lune run tools/secret_scan.luau",
			"./nexus.ps1 gatecheck --gate G5",
			"./nexus.ps1 release --live",
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
