--!strict

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local VAULT_ROOT = "C:/Users/jackw/Roblox/RobloxGameVault"
local SCRIPT_PATH = "tools/github_ci_bootstrap.luau"
local LAUNCHER_PATH = "nexus.ps1"
local TASKS_PATH = ".vscode/tasks.json"
local DASHBOARD_PATH = VAULT_ROOT .. "/00_Command_Center/Dashboard.md"
local RUNBOOK_PATH = "docs/runbooks/github-ci.md"

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
local launcher = read(LAUNCHER_PATH)
local tasks = serde.decode("json", read(TASKS_PATH)) :: any
local runbook = read(RUNBOOK_PATH)

assertContains(script, '"auth", "status"', "bootstrap must check gh auth")
assertContains(script, '"remote", "get-url", "origin"', "bootstrap must check origin")
assertContains(script, "CI branch protection confirmed: PASS", "bootstrap must honor G4 receipt")
assertContains(script, "--create-private", "bootstrap must require an explicit remote-create flag")
assertContains(
	script,
	"Remote URLs and tokens are not written",
	"bootstrap must avoid remote/token leakage"
)
assertContains(script, "URL intentionally hidden", "bootstrap evidence must hide remote URLs")
assertNotContains(script, "ghp_", "bootstrap must not contain a GitHub token prefix")
assertNotContains(script, "github_pat_", "bootstrap must not contain a fine-grained token prefix")

assertContains(launcher, '"github-ci" {', "launcher must expose github-ci")
assertContains(
	launcher,
	'Invoke-Tool "lune" (@("run", "tools/github_ci_bootstrap.luau") + $Rest)',
	"launcher must run GitHub CI bootstrap and forward flags"
)

local foundTask = false
for _, task in tasks.tasks do
	if task.label == "Nexus: GitHub CI Bootstrap" then
		foundTask = task.command == "./nexus.ps1 github-ci"
		break
	end
end
assertTrue(foundTask, "VS Code tasks must include Nexus: GitHub CI Bootstrap")

assertContains(runbook, "./nexus.ps1 github-ci", "CI runbook must mention GitHub CI bootstrap")

if fs.isDir(VAULT_ROOT) then
	local dashboard = read(DASHBOARD_PATH)
	assertContains(
		dashboard,
		"![[GitHub CI Bootstrap]]",
		"Dashboard must embed GitHub CI Bootstrap"
	)
end

print("GitHub CI bootstrap tests passed")
