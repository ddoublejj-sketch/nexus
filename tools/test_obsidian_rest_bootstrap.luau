--!strict

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local VAULT_ROOT = "C:/Users/jackw/Roblox/RobloxGameVault"
local SCRIPT_PATH = "tools/obsidian_rest_bootstrap.luau"
local VAULT_PING_PATH = "tools/vault_ping.luau"
local ACCEPTANCE_PATH = "tools/human_gate_acceptance.luau"
local READINESS_PATH = "tools/human_gate_readiness.luau"
local LAUNCHER_PATH = "nexus.ps1"
local TASKS_PATH = ".vscode/tasks.json"
local DASHBOARD_PATH = VAULT_ROOT .. "/00_Command_Center/Dashboard.md"

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
local vaultPing = read(VAULT_PING_PATH)
local acceptance = read(ACCEPTANCE_PATH)
local readiness = read(READINESS_PATH)
local launcher = read(LAUNCHER_PATH)
local tasks = serde.decode("json", read(TASKS_PATH)) :: any

assertContains(
	script,
	".obsidian/plugins/obsidian-local-rest-api/data.json",
	"bootstrap must read generated Local REST plugin settings"
)
assertContains(script, "secrets/obsidian.env", "bootstrap must write the local env file")
assertContains(script, "key hidden", "bootstrap output must hide the API key")
assertContains(
	script,
	"API key is written only to `secrets/obsidian.env` and is never printed here",
	"bootstrap evidence must explain secret handling"
)
assertContains(script, "restProbe", "bootstrap must probe the live REST endpoint")
assertContains(script, "Open the vault in Obsidian", "bootstrap must give human next steps")
assertNotContains(script, "print(settings.apiKey", "bootstrap must not print settings.apiKey")
assertNotContains(script, "print(apiKey", "bootstrap must not print apiKey")

assertContains(
	vaultPing,
	"fs.removeFile(pendingPath)",
	"vault ping must remove flushed pending files"
)
assertContains(acceptance, "SENT_ROOT", "acceptance pending count must account for sent receipts")
assertContains(readiness, "SENT_ROOT", "readiness pending count must account for sent receipts")

assertContains(launcher, '"obsidian-rest" {', "launcher must expose obsidian-rest")
assertContains(
	launcher,
	'Invoke-Tool "lune" @("run", "tools/obsidian_rest_bootstrap.luau")',
	"launcher must run Obsidian REST bootstrap"
)

local foundTask = false
for _, task in tasks.tasks do
	if task.label == "Nexus: Obsidian REST Bootstrap" then
		foundTask = task.command == "./nexus.ps1 obsidian-rest"
		break
	end
end
assertTrue(foundTask, "VS Code tasks must include Nexus: Obsidian REST Bootstrap")

if fs.isDir(VAULT_ROOT) then
	local dashboard = read(DASHBOARD_PATH)
	assertContains(
		dashboard,
		"![[Obsidian REST Bootstrap]]",
		"Dashboard must embed Obsidian REST Bootstrap"
	)
end

print("Obsidian REST bootstrap tests passed")
