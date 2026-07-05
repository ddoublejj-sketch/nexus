--!strict

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local VAULT_ROOT = "C:/Users/jackw/Roblox/RobloxGameVault"
local PROJECT_PATH = "default.project.json"
local SOURCEMAP_PATH = "sourcemap.json"
local SETTINGS_PATH = ".vscode/settings.json"
local LAUNCHER_PATH = "nexus.ps1"
local RUNBOOK_PATH = "docs/runbooks/rojo-sync-rules.md"
local STATUS_PATH = "docs/STATUS.md"

type ProjectNode = { [string]: any }

local EXPECTED_MAPPINGS: { { label: string, className: string?, path: string? } } = {
	{
		label = "ReplicatedStorage.Shared",
		className = nil,
		path = "src/ReplicatedStorage/Shared",
	},
	{
		label = "ReplicatedStorage.Packages",
		className = nil,
		path = "Packages",
	},
	{
		label = "ServerScriptService.Server",
		className = nil,
		path = "src/ServerScriptService/Server",
	},
	{
		label = "ServerScriptService.ServerPackages",
		className = nil,
		path = "ServerPackages",
	},
	{
		label = "ServerStorage.Assets",
		className = nil,
		path = "src/ServerStorage/Assets",
	},
	{
		label = "ServerStorage.Maps",
		className = nil,
		path = "maps",
	},
	{
		label = "StarterPlayer.StarterPlayerScripts.Client",
		className = nil,
		path = "src/StarterPlayer/StarterPlayerScripts/Client",
	},
	{
		label = "StarterGui.UI",
		className = nil,
		path = "src/StarterGui/UI",
	},
	{
		label = "Workspace",
		className = "Workspace",
		path = nil,
	},
	{
		label = "Lighting",
		className = "Lighting",
		path = nil,
	},
}

local SOURCEMAP_ANCHORS = {
	"src/ReplicatedStorage/Shared/Net/init.luau",
	"src/ServerScriptService/Server/Services/NexusService.luau",
	"src/ServerScriptService/Server/Services/DataService.luau",
	"src/ServerScriptService/Server/Services/MapService.luau",
	"src/StarterPlayer/StarterPlayerScripts/Client/Controllers/NexusController.luau",
}

local function assertTrue(condition: boolean, label: string)
	if not condition then
		error(label)
	end
end

local function assertEqual(actual: any, expected: any, label: string)
	if actual ~= expected then
		error(("%s: expected %s, got %s"):format(label, tostring(expected), tostring(actual)))
	end
end

local function read(path: string): string
	assertTrue(fs.isFile(path), "Missing file: " .. path)
	return fs.readFile(path)
end

local function assertContains(contents: string, needle: string, label: string)
	assertTrue(contents:find(needle, 1, true) ~= nil, label)
end

local function childAtPath(root: ProjectNode, dottedPath: string): ProjectNode
	local node = root
	for segment in dottedPath:gmatch("[^%.]+") do
		local child = node[segment]
		assertTrue(type(child) == "table", "Missing Rojo node: " .. dottedPath)
		node = child :: ProjectNode
	end

	return node
end

local project = serde.decode("json", read(PROJECT_PATH)) :: any
assertEqual(project.name, "Nexus", "Rojo project name")
assertEqual(project.tree["$className"], "DataModel", "Rojo root class")

for _, mapping in EXPECTED_MAPPINGS do
	local node = childAtPath(project.tree, mapping.label)
	if mapping.className ~= nil then
		assertEqual(node["$className"], mapping.className, mapping.label .. " class")
	end
	if mapping.path ~= nil then
		assertEqual(node["$path"], mapping.path, mapping.label .. " path")
		assertTrue(
			fs.isDir(mapping.path :: string),
			mapping.label .. " mapped path must exist: " .. (mapping.path :: string)
		)
	end
end

local settings = serde.decode("json", read(SETTINGS_PATH)) :: any
assertEqual(settings["luau-lsp.sourcemap.enabled"], true, "luau-lsp sourcemap enabled")
assertEqual(settings["luau-lsp.sourcemap.rojoProjectFile"], PROJECT_PATH, "luau-lsp project")
assertEqual(
	settings["luau-lsp.types.definitionFiles"][1],
	"types/globalTypes.d.luau",
	"luau-lsp Roblox definitions"
)

local launcher = read(LAUNCHER_PATH)
assertContains(
	launcher,
	'Invoke-Tool "rojo" @("serve", "default.project.json")',
	"launcher serve must use Rojo"
)
assertContains(
	launcher,
	'Invoke-Tool "rojo" @("sourcemap", "default.project.json", "-o", "sourcemap.json")',
	"launcher map --once must generate sourcemap"
)
assertContains(
	launcher,
	'Invoke-Tool "rojo" @("sourcemap", "default.project.json", "-o", "sourcemap.json", "--watch")',
	"launcher map must support sourcemap watch"
)

local sourcemap = read(SOURCEMAP_PATH)
assertContains(sourcemap, '"name":"Nexus"', "sourcemap must be generated for Nexus")
for _, anchor in SOURCEMAP_ANCHORS do
	assertContains(sourcemap, anchor, "sourcemap missing " .. anchor)
end

local runbook = read(RUNBOOK_PATH)
assertContains(runbook, "G2 Accepted Results", "sync runbook must record accepted G2 proof")
assertContains(runbook, "./nexus.ps1 serve", "sync runbook must include serve step")
assertContains(runbook, "./nexus.ps1 map --once", "sync runbook must include map acceptance")
assertContains(
	runbook,
	"luau-lsp analyze --definitions types/globalTypes.d.luau --sourcemap sourcemap.json src",
	"sync runbook must include sourcemap-aware analyze"
)
assertContains(
	runbook,
	"C:\\Users\\jackw\\Roblox\\RobloxGameVault\\80_Archives\\StudioSnapshots",
	"sync runbook must document snapshot archive"
)
assertContains(
	runbook,
	"Disposable syncback test object",
	"sync runbook must require a disposable syncback test"
)

local status = read(STATUS_PATH)
assertContains(status, "WO-2/G2 is now accepted", "STATUS must record accepted G2 gate")
assertContains(
	status,
	"DataService online (mock mode)",
	"STATUS must include Studio playtest runtime proof"
)

if fs.isDir(VAULT_ROOT) then
	assertTrue(
		fs.isDir(VAULT_ROOT .. "/80_Archives/StudioSnapshots"),
		"Studio snapshot archive directory must exist in the vault"
	)
end

print("Rojo bridge contract tests passed")
