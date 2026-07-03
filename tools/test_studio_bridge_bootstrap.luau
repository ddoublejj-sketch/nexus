--!strict

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local VAULT_ROOT = "C:/Users/jackw/Roblox/RobloxGameVault"
local SCRIPT_PATH = "tools/studio_bridge_bootstrap.luau"
local LAUNCHER_PATH = "nexus.ps1"
local TASKS_PATH = ".vscode/tasks.json"
local DASHBOARD_PATH = VAULT_ROOT .. "/00_Command_Center/Dashboard.md"
local RUNBOOK_PATH = "docs/runbooks/rojo-sync-rules.md"

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

local script = read(SCRIPT_PATH)
local launcher = read(LAUNCHER_PATH)
local tasks = serde.decode("json", read(TASKS_PATH)) :: any
local runbook = read(RUNBOOK_PATH)

assertContains(script, "RobloxStudioBeta", "bootstrap must check Roblox Studio process")
assertContains(script, "127.0.0.1:34872", "bootstrap must check local Rojo server")
assertContains(script, "Studio plugin connected: PASS", "bootstrap must honor connected receipt")
assertContains(script, "Studio playtest observed: PASS", "bootstrap must honor playtest receipt")
assertContains(
	script,
	"does not replace the human Studio plugin and playtest receipt",
	"bootstrap must not claim human proof"
)
assertContains(script, "80_Archives/StudioSnapshots", "bootstrap must check snapshot archive")

assertContains(launcher, '"studio-bridge" {', "launcher must expose studio-bridge")
assertContains(
	launcher,
	'Invoke-Tool "lune" @("run", "tools/studio_bridge_bootstrap.luau")',
	"launcher must run Studio bridge bootstrap"
)

local foundTask = false
for _, task in tasks.tasks do
	if task.label == "Nexus: Studio Bridge Bootstrap" then
		foundTask = task.command == "./nexus.ps1 studio-bridge"
		break
	end
end
assertTrue(foundTask, "VS Code tasks must include Nexus: Studio Bridge Bootstrap")

assertContains(
	runbook,
	"./nexus.ps1 studio-bridge",
	"Rojo sync runbook must mention Studio bridge bootstrap"
)

if fs.isDir(VAULT_ROOT) then
	local dashboard = read(DASHBOARD_PATH)
	assertContains(
		dashboard,
		"![[Studio Bridge Bootstrap]]",
		"Dashboard must embed Studio Bridge Bootstrap"
	)
end

print("Studio bridge bootstrap tests passed")
