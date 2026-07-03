--!strict

local fs = require("@lune/fs")

local STATUS_PATH = "docs/STATUS.md"
local FRESH_SETUP_PATH = "docs/runbooks/fresh-machine-setup.md"
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
local blenderRunbook = read(BLENDER_RUNBOOK_PATH)
local gateStatus = read(GATE_STATUS_PATH)

assertContains(
	status,
	"WO-0 is in progress and blocked on **G1 - GUI installs**",
	"Current phase must keep WO-0/G1 visible"
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
	"code : The term 'code' is not recognized",
	"STATUS must not pretend code is available"
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
assertContains(status, "### Human Gate G1 Request", "Missing G1 request")
assertContains(status, "Install **Visual Studio Code**", "Missing VS Code G1 request")
assertContains(status, "Install **GitHub CLI**", "Missing GitHub CLI G1 request")
assertContains(status, "Install **Obsidian**", "Missing Obsidian G1 request")
assertContains(status, "standard Blender build", "Missing Blender G1 wording")
assertContains(
	status,
	"lune run tools/test_tool_gap_contract.luau",
	"STATUS must include direct WO-0 contract proof"
)
assertContains(status, "Tool gap contract tests passed", "Missing WO-0 contract output")
assertContains(
	status,
	"| WO-0 Tool Gaps | Partial | Audit output and tool-gap contract tests under WO-0 | G1:",
	"Acceptance matrix must keep WO-0 partial and G1-gated"
)

assertContains(freshSetup, "rojo --version", "Fresh setup must verify Rojo")
assertContains(freshSetup, "Get-Command blender", "Fresh setup must verify Blender command")
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
