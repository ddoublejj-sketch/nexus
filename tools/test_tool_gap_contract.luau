--!strict

local fs = require("@lune/fs")

local STATUS_PATH = "docs/STATUS.md"
local FRESH_SETUP_PATH = "docs/runbooks/fresh-machine-setup.md"
local G1_RUNBOOK_PATH = "docs/runbooks/g1-tool-closure.md"
local BLENDER_RUNBOOK_PATH = "docs/runbooks/blender-export.md"
local GATE_STATUS_PATH = "tools/gate_status.luau"

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

local status = read(STATUS_PATH)
local freshSetup = read(FRESH_SETUP_PATH)
local g1Runbook = read(G1_RUNBOOK_PATH)
local blenderRunbook = read(BLENDER_RUNBOOK_PATH)
local gateStatus = read(GATE_STATUS_PATH)

assertContains(
	status,
	"WO-0 G1 tool closure now passes locally",
	"Current phase must show WO-0/G1 closed"
)
assertContains(status, "### Current Re-Audit - 2026-07-03", "Missing current audit")
assertContains(status, "git version 2.54.0.windows.1", "Missing Git audit output")
assertContains(status, "rokit 1.2.0", "Missing Rokit audit output")
assertContains(status, "Rojo 7.7.0", "Missing Rojo audit output")
assertContains(status, "wally.exe", "Missing pinned Wally command evidence")
assertContains(status, "lune.exe", "Missing pinned Lune command evidence")
assertContains(status, "luau-lsp.exe", "Missing pinned luau-lsp command evidence")
assertContains(status, "v1.29.280", "Missing winget audit output")
assertContains(
	status,
	"VS Code was installed with explicit approval",
	"Missing VS Code install proof"
)
assertContains(status, "1.126.0", "Missing VS Code version proof")
assertContains(status, "| G1 | code available | PASS |", "G1 probe must show code passing")
assertContains(status, "| G1 | gh available | PASS |", "G1 probe must show gh passing")
assertContains(
	status,
	"| G1 | blender CLI available | PASS |",
	"G1 probe must show Blender passing"
)
assertContains(
	status,
	"| G1 | obsidian command available | PASS |",
	"G1 probe must show Obsidian passing"
)
assertContains(
	status,
	"gh : The term 'gh' is not recognized",
	"STATUS must not pretend gh is available"
)
assertContains(status, "BlenderFoundation.Blender", "Missing Blender package evidence")
assertContains(status, "blender-launcher.exe", "Missing Blender launcher-alias evidence")
assertContains(
	status,
	"Windows Store launcher alias is present, but no reliable `blender.exe` CLI path is exposed yet.",
	"STATUS must distinguish Blender app presence from CLI readiness"
)
assertContains(status, "### Human Gate G1 Closure", "Missing G1 closure section")
assertContains(status, "**VS Code is installed**", "Missing VS Code installed G1 evidence")
assertContains(status, "**GitHub CLI is installed**", "Missing GitHub CLI G1 closure")
assertContains(status, "**Obsidian is installed**", "Missing Obsidian G1 closure")
assertContains(status, "**Blender CLI is installed**", "Missing Blender G1 closure")
assertContains(
	status,
	"lune run tools/test_tool_gap_contract.luau",
	"STATUS must include direct WO-0 contract proof"
)
assertContains(status, "Tool gap contract tests passed", "Missing WO-0 contract output")
assertContains(
	status,
	"| WO-0 Tool Gaps | Exact G1 acceptance passed | Audit output, VS Code install proof, portable gh/Blender/Obsidian shim proof, G1 Tool Closure note/runbook, and tool-gap contract tests under WO-0 | None locally |",
	"Acceptance matrix must mark WO-0 locally accepted"
)

assertContains(freshSetup, "rojo --version", "Fresh setup must verify Rojo")
assertContains(freshSetup, "Get-Command blender", "Fresh setup must verify Blender command")
assertContains(freshSetup, "g1-tool-closure.md", "Fresh setup must link G1 closure runbook")
assertContains(g1Runbook, "./nexus.ps1 gatecheck --gate G1", "G1 runbook must verify gate")
assertContains(g1Runbook, "G4 still owns `gh auth login`", "G1 runbook must not absorb G4")
assertContains(
	freshSetup,
	"Windows Store launcher alias is not enough",
	"Fresh setup must warn about Blender launcher aliases"
)
assertContains(
	blenderRunbook,
	"Blender is not on PATH yet",
	"Blender export runbook must preserve thumbnail blocker"
)
assertContains(gateStatus, '{ id = "G1"', "Gate status generator must track G1")

print("Tool gap contract tests passed")
