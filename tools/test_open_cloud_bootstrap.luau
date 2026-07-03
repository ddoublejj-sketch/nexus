--!strict

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local VAULT_ROOT = "C:/Users/jackw/Roblox/RobloxGameVault"
local SCRIPT_PATH = "tools/open_cloud_bootstrap.luau"
local LAUNCHER_PATH = "nexus.ps1"
local TASKS_PATH = ".vscode/tasks.json"
local DASHBOARD_PATH = VAULT_ROOT .. "/00_Command_Center/Dashboard.md"
local CHECKLIST_PATH = "docs/runbooks/release-checklist.md"

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
local checklist = read(CHECKLIST_PATH)

assertContains(script, 'SECRET_PATH = "secrets/opencloud.env"', "bootstrap must check secret file")
assertContains(
	script,
	'FIXTURE_PATH = "tools/fixtures/opencloud.env"',
	"bootstrap must check fixture"
)
assertContains(script, 'ARTIFACT_PATH = "build/nexus.rbxl"', "bootstrap must check artifact")
assertContains(script, "Live publish approval recorded: PASS", "bootstrap must honor G5 receipt")
assertContains(script, "output omitted", "bootstrap must omit dry-run output")
assertContains(script, "values hidden", "bootstrap must hide Open Cloud values")
assertContains(
	script,
	"without writing Open Cloud key, universe ID, place ID, endpoint, or dry-run output values",
	"bootstrap evidence must state secret-safe scope"
)
assertNotContains(script, "print(config.apiKey", "bootstrap must not print API keys")
assertNotContains(script, "print(values.ROBLOX", "bootstrap must not print Roblox IDs")

assertContains(launcher, '"open-cloud" {', "launcher must expose open-cloud")
assertContains(
	launcher,
	'Invoke-Tool "lune" @("run", "tools/open_cloud_bootstrap.luau")',
	"launcher must run Open Cloud bootstrap"
)

local foundTask = false
for _, task in tasks.tasks do
	if task.label == "Nexus: Open Cloud Bootstrap" then
		foundTask = task.command == "./nexus.ps1 open-cloud"
		break
	end
end
assertTrue(foundTask, "VS Code tasks must include Nexus: Open Cloud Bootstrap")

assertContains(
	checklist,
	"./nexus.ps1 open-cloud",
	"release checklist must mention Open Cloud bootstrap"
)

if fs.isDir(VAULT_ROOT) then
	local dashboard = read(DASHBOARD_PATH)
	assertContains(
		dashboard,
		"![[Open Cloud Bootstrap]]",
		"Dashboard must embed Open Cloud Bootstrap"
	)
end

print("Open Cloud bootstrap tests passed")
