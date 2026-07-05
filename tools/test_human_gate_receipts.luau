--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")

local VAULT_ROOT = "C:/Users/jackw/Roblox/RobloxGameVault"
local SCRIPT_PATH = "tools/human_gate_receipts.luau"
local ACCEPTANCE_PATH = "tools/human_gate_acceptance.luau"
local LAUNCHER_PATH = "nexus.ps1"
local TASKS_PATH = ".vscode/tasks.json"
local README_PATH = "README.md"
local DASHBOARD_PATH = VAULT_ROOT .. "/00_Command_Center/Dashboard.md"
local VAULT_NOTE_PATH = VAULT_ROOT .. "/00_Command_Center/Human Gate Proof Receipts.md"

local RECEIPTS = {
	{
		path = "docs/gate-proofs/G2-studio-connect.md",
		markers = {
			"Studio plugin connected",
			"Studio playtest observed",
		},
	},
	{
		path = "docs/gate-proofs/G3-obsidian-dashboard.md",
		markers = {
			"Dashboard rendered in Obsidian",
		},
	},
	{
		path = "docs/gate-proofs/G4-github-ci.md",
		markers = {
			"CI branch protection confirmed",
		},
	},
	{
		path = "docs/gate-proofs/G5-open-cloud-publish.md",
		markers = {
			"Live publish approval recorded",
		},
	},
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

local script = read(SCRIPT_PATH)
local acceptance = read(ACCEPTANCE_PATH)
local launcher = read(LAUNCHER_PATH)
local readme = read(README_PATH)
local tasks = serde.decode("json", read(TASKS_PATH)) :: any

assertContains(
	script,
	"00_Command_Center/Human Gate Proof Receipts.md",
	"receipt generator must write vault note"
)
assertContains(script, "PENDING", "receipt templates must start pending")
assertContains(script, 'marker .. ": PASS"', "receipt generator must detect accepted markers")
assertContains(acceptance, "receiptCheck", "gatecheck must support proof receipts")
assertContains(acceptance, "receipt pending", "gatecheck must report pending receipts")
assertContains(acceptance, "accepted by", "gatecheck must report accepted receipts")

for _, receipt in RECEIPTS do
	local fileName = receipt.path:match("([^/]+)$") or receipt.path
	assertContains(script, fileName, "generator missing receipt " .. fileName)
	assertContains(acceptance, fileName, "gatecheck missing receipt " .. fileName)

	local contents = read(receipt.path)
	assertTrue(
		contents:find("status: pending", 1, true) ~= nil
			or contents:find("status: pass", 1, true) ~= nil
			or contents:find("status: accepted", 1, true) ~= nil,
		receipt.path .. " missing receipt status"
	)
	assertContains(contents, "## Required Markers", receipt.path .. " missing marker section")
	assertContains(contents, "Do not paste secrets", receipt.path .. " missing secret warning")
	assertNotContains(
		contents,
		"OBSIDIAN_API_KEY=",
		receipt.path .. " must not include key assignment"
	)
	assertNotContains(
		contents,
		"OPEN_CLOUD_API_KEY=",
		receipt.path .. " must not include key assignment"
	)
	for _, marker in receipt.markers do
		assertTrue(
			contents:find(marker .. ": PENDING", 1, true) ~= nil
				or contents:find(marker .. ": PASS", 1, true) ~= nil,
			receipt.path .. " missing marker " .. marker
		)
	end
end

assertContains(launcher, '"receipts" {', "launcher must expose receipts subcommand")
assertContains(
	launcher,
	'Invoke-Tool "lune" @("run", "tools/human_gate_receipts.luau")',
	"launcher receipts command must run generator"
)
assertContains(readme, "./nexus.ps1 receipts", "README must document receipts command")

local foundTask = false
for _, task in tasks.tasks do
	if task.label == "Nexus: Human Gate Receipts" then
		foundTask = task.command == "./nexus.ps1 receipts"
		break
	end
end
assertTrue(foundTask, "VS Code tasks must include Nexus: Human Gate Receipts")

if fs.isDir(VAULT_ROOT) then
	local dashboard = read(DASHBOARD_PATH)
	assertContains(
		dashboard,
		"![[Human Gate Proof Receipts]]",
		"Dashboard must embed Human Gate Proof Receipts"
	)

	local note = read(VAULT_NOTE_PATH)
	assertContains(note, "# Human Gate Proof Receipts", "receipt vault note missing title")
	assertContains(note, "PENDING", "receipt vault note must show pending receipts")
	assertContains(note, "not completion evidence", "receipt vault note must reject pending proof")
	for _, receipt in RECEIPTS do
		assertContains(note, receipt.path, "receipt vault note missing " .. receipt.path)
	end
end

local g2Probe = process.exec("lune", {
	"run",
	"tools/human_gate_acceptance.luau",
	"--gate",
	"G2",
})
assertTrue(g2Probe.ok, "G2 probe must pass after receipt markers are accepted")
assertContains(
	g2Probe.stdout,
	"Human gate acceptance PASS",
	"G2 probe must show accepted receipt state"
)

local g5Probe = process.exec("lune", {
	"run",
	"tools/human_gate_acceptance.luau",
	"--gate",
	"G5",
})
assertTrue(not g5Probe.ok, "G5 probe must stay blocked while receipt markers are pending")
assertContains(g5Probe.stdout, "receipt pending", "G5 probe must name pending receipt state")

print("Human gate receipt tests passed")
