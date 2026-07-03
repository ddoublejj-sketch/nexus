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
		state = "Blocked on local app/tool installation",
		human = {
			"Install Visual Studio Code and enable the `code` command on PATH.",
			"Install GitHub CLI and make `gh` available on PATH.",
			"Install Obsidian and open the vault once.",
			"Install a standard Blender build or provide the absolute path to `blender.exe`.",
		},
		codex = {
			"Run `./nexus.ps1 receipts` to refresh the pending proof receipt templates.",
			"Rerun WO-0 acceptance from the Nexus repo.",
			"Replace the placeholder thumbnail backlog with real Blender thumbnail renders if `blender.exe` is available.",
		},
		proof = {
			"git --version",
			"rokit --version",
			"rojo --version",
			"code --version",
			"gh --version",
			"Get-Command blender -ErrorAction SilentlyContinue",
			"./nexus.ps1 gatecheck --gate G1",
		},
	},
	{
		id = "G2",
		title = "Studio Connect",
		state = "Blocked on Roblox Studio plugin connection and playtest proof",
		human = {
			"Open the Nexus place in Roblox Studio.",
			"Run `./nexus.ps1 up` from the Nexus repo.",
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
			"luau-lsp analyze --definitions types/globalTypes.d.luau --sourcemap sourcemap.json src",
			"./nexus.ps1 down",
			"./nexus.ps1 gatecheck --gate G2",
		},
	},
	{
		id = "G3",
		title = "Obsidian REST And Plugins",
		state = "Blocked on Obsidian installation, plugins, and Local REST API key",
		human = {
			"Open `C:\\Users\\jackw\\Roblox\\RobloxGameVault` as an Obsidian vault.",
			"Enable Local REST API, Obsidian Git, Dataview, Tasks, Kanban, Templater, QuickAdd, and Omnisearch.",
			"Create `secrets/obsidian.env` with `OBSIDIAN_API_URL` and `OBSIDIAN_API_KEY`.",
		},
		codex = {
			"Mark the required marker in `docs/gate-proofs/G3-obsidian-dashboard.md` as `PASS` after the dashboard render is confirmed.",
			"Run the REST ping and flush queued pending writes.",
			"Verify Dataview and Tasks sections render in the Dashboard.",
			"Commit vault proof after the REST ping and dashboard render are confirmed.",
		},
		proof = {
			"./nexus.ps1 receipts",
			"lune run tools/vault_ping.luau",
			"./nexus.ps1 loop --once",
			"git -C C:\\Users\\jackw\\Roblox\\RobloxGameVault status --short",
			"./nexus.ps1 gatecheck --gate G3",
		},
	},
	{
		id = "G4",
		title = "GitHub Auth And CI",
		state = "Blocked on GitHub CLI installation/authentication and remote repository setup",
		human = {
			"Install GitHub CLI if G1 has not already provided it.",
			"Run `gh auth login` and complete the browser/device flow.",
			"Approve private repo creation for Nexus and RobloxGameVault.",
		},
		codex = {
			"Mark the required marker in `docs/gate-proofs/G4-github-ci.md` as `PASS` after branch protection is confirmed.",
			"Create/push private remotes.",
			"Enable branch protection requiring the Nexus CI quality gate.",
			"Demonstrate a failing formatting PR and a fixed passing PR.",
		},
		proof = {
			"./nexus.ps1 receipts",
			"gh auth status",
			"gh repo create nexus --private --source . --remote origin --push",
			"gh pr checks",
			"./nexus.ps1 gatecheck --gate G4",
		},
	},
	{
		id = "G5",
		title = "Open Cloud Key",
		state = "Blocked on live publish credentials; dry-run path is ready",
		human = {
			"Create the smallest-scope Open Cloud key needed to publish the target place.",
			"Create `secrets/opencloud.env` with key, universe ID, and place ID.",
		},
		codex = {
			"Mark the required marker in `docs/gate-proofs/G5-open-cloud-publish.md` as `PASS` after explicit live publish approval.",
			"Run fixture dry-run first, then real dry-run with the secret file.",
			"Attempt live publish only after explicit approval and green release checklist.",
		},
		proof = {
			"./nexus.ps1 receipts",
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
