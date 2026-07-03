--!strict

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local VAULT_ROOT = "C:/Users/jackw/Roblox/RobloxGameVault"
local SCRIPT_PATH = "tools/obsidian_plugin_setup.luau"
local LAUNCHER_PATH = "nexus.ps1"
local TASKS_PATH = ".vscode/tasks.json"
local DASHBOARD_PATH = VAULT_ROOT .. "/00_Command_Center/Dashboard.md"
local NOTE_PATH = VAULT_ROOT .. "/00_Command_Center/Obsidian Plugin Setup.md"
local COMMUNITY_PLUGINS_PATH = VAULT_ROOT .. "/.obsidian/community-plugins.json"
local VAULT_GITIGNORE_PATH = VAULT_ROOT .. "/.gitignore"

local REQUIRED_PLUGINS = {
	["obsidian-local-rest-api"] = "Local REST API",
	["obsidian-git"] = "Obsidian Git",
	dataview = "Dataview",
	["obsidian-tasks-plugin"] = "Tasks",
	["obsidian-kanban"] = "Kanban",
	["templater-obsidian"] = "Templater",
	quickadd = "QuickAdd",
	omnisearch = "Omnisearch",
}

local REQUIRED_ASSETS = {
	"main.js",
	"manifest.json",
	"styles.css",
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
local launcher = read(LAUNCHER_PATH)
local tasks = serde.decode("json", read(TASKS_PATH)) :: any

assertContains(
	script,
	"00_Command_Center/Obsidian Plugin Setup.md",
	"plugin setup script must write a vault evidence note"
)
assertContains(
	script,
	".obsidian/community-plugins.json",
	"plugin setup script must enable plugins in Obsidian config"
)
assertContains(
	script,
	"no API key or plugin secret is recorded here",
	"plugin setup evidence must explicitly avoid secrets"
)

for pluginId, pluginName in REQUIRED_PLUGINS do
	assertContains(script, pluginId, "plugin setup script missing plugin id " .. pluginId)
	assertContains(script, pluginName, "plugin setup script missing plugin name " .. pluginName)
end

assertContains(launcher, '"obsidian-plugins" {', "launcher must expose obsidian-plugins")
assertContains(
	launcher,
	'Invoke-Tool "lune" @("run", "tools/obsidian_plugin_setup.luau")',
	"launcher must run Obsidian plugin setup"
)

local foundTask = false
for _, task in tasks.tasks do
	if task.label == "Nexus: Obsidian Plugin Setup" then
		foundTask = task.command == "./nexus.ps1 obsidian-plugins"
		break
	end
end
assertTrue(foundTask, "VS Code tasks must include Nexus: Obsidian Plugin Setup")

if fs.isDir(VAULT_ROOT) then
	local dashboard = read(DASHBOARD_PATH)
	assertContains(
		dashboard,
		"![[Obsidian Plugin Setup]]",
		"Dashboard must embed Obsidian Plugin Setup"
	)

	local gitignore = read(VAULT_GITIGNORE_PATH)
	assertContains(
		gitignore,
		".obsidian/plugins/",
		"Vault gitignore must keep downloaded plugin bundles out of Git"
	)
	assertContains(
		gitignore,
		".obsidian/plugins/*/data.json",
		"Vault gitignore must keep plugin data files out of Git"
	)

	local enabled = serde.decode("json", read(COMMUNITY_PLUGINS_PATH)) :: { string }
	local enabledMap = {}
	for _, pluginId in enabled do
		enabledMap[pluginId] = true
	end

	local note = read(NOTE_PATH)
	assertContains(note, "# Obsidian Plugin Setup", "Plugin setup note missing title")
	assertContains(note, "Remaining G3 Human Proof", "Plugin setup note missing remaining proof")
	assertNotContains(note, "OBSIDIAN_API_KEY=", "Plugin setup note must not expose key assignment")
	assertNotContains(note, "Bearer ", "Plugin setup note must not expose bearer tokens")

	for pluginId, pluginName in REQUIRED_PLUGINS do
		assertTrue(enabledMap[pluginId] == true, "community-plugins.json missing " .. pluginId)
		assertContains(note, pluginName, "Plugin setup note missing " .. pluginName)

		local pluginPath = VAULT_ROOT .. "/.obsidian/plugins/" .. pluginId
		for _, asset in REQUIRED_ASSETS do
			assertTrue(
				fs.isFile(pluginPath .. "/" .. asset),
				"Missing " .. pluginId .. "/" .. asset
			)
		end

		local manifest = serde.decode("json", fs.readFile(pluginPath .. "/manifest.json")) :: any
		assertTrue(manifest.id == pluginId, "Manifest id mismatch for " .. pluginId)
	end
end

print("Obsidian plugin setup tests passed")
