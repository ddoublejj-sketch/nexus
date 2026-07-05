--!strict

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local PROJECT_PATH = "default.project.json"
local MAP_SERVICE_PATH = "src/ServerScriptService/Server/Services/MapService.luau"
local RELOAD_COMMAND_PATH = "src/ServerScriptService/Server/Commands/reloadmap.luau"
local RELOAD_HANDLER_PATH = "src/ServerScriptService/Server/Commands/reloadmapServer.luau"
local INIT_PATH = "src/ServerScriptService/Server/init.server.luau"
local DEFAULT_MAP_PATH = "maps/Default.model.json"

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

local function childNamed(parent: any, name: string): any?
	local children = parent.Children or {}
	for _, child in children do
		if child.Name == name then
			return child
		end
	end

	return nil
end

local project = serde.decode("json", read(PROJECT_PATH)) :: any
local serverStorage = project.tree.ServerStorage
assertTrue(type(serverStorage) == "table", "Rojo project must define ServerStorage")
assertTrue(
	serverStorage.Maps["$path"] == "maps",
	"Rojo project must map ServerStorage.Maps to maps"
)

local defaultMap = serde.decode("json", read(DEFAULT_MAP_PATH)) :: any
assertTrue(defaultMap.ClassName == "Folder", "Default map must be a Rojo Folder model")
local pinebrookBlockout = childNamed(defaultMap, "PinebrookNational_Blockout_Phase4")
assertTrue(pinebrookBlockout ~= nil, "Default map must contain Pinebrook Phase 4 blockout")
assertTrue(
	childNamed(pinebrookBlockout, "PlaytestSpawn") ~= nil,
	"Default map must contain a playtest spawn"
)
for index = 1, 18 do
	local holeName = ("Hole%02d"):format(index)
	local hole = childNamed(pinebrookBlockout, holeName)
	assertTrue(hole ~= nil, "Default map missing " .. holeName)
	for _, surfaceName in { "Rough", "Tee", "Fairway", "Green", "Bunker", "Water" } do
		assertTrue(
			childNamed(hole, holeName .. "_" .. surfaceName) ~= nil,
			"Default map missing " .. holeName .. " " .. surfaceName
		)
	end
end
local debugCartPaths = childNamed(pinebrookBlockout, "DebugCartPaths")
assertTrue(debugCartPaths ~= nil, "Default map must contain debug cart path connectors")
assertTrue(
	childNamed(debugCartPaths, "Hole01_ToHole02_Path") ~= nil,
	"Default map missing opening connector path"
)
assertTrue(
	childNamed(debugCartPaths, "Hole17_ToHole18_Path") ~= nil,
	"Default map missing finishing connector path"
)

local mapService = read(MAP_SERVICE_PATH)
assertContains(
	mapService,
	'local DEFAULT_MAP_NAME = "Default"',
	"MapService must name the default map"
)
assertContains(
	mapService,
	"local currentMapName = DEFAULT_MAP_NAME",
	"MapService must default to Default"
)
assertContains(
	mapService,
	"MapService.reload(DEFAULT_MAP_NAME)",
	"MapService must load the default map on start"
)
assertContains(
	mapService,
	'ServerStorage:FindFirstChild("Maps")',
	"MapService must read ServerStorage.Maps"
)
assertContains(
	mapService,
	'Instance.new("Part")',
	"Default map fallback must create a playable ground part"
)
assertContains(
	mapService,
	'Instance.new("SpawnLocation")',
	"Default map fallback must create a spawn"
)
assertContains(
	mapService,
	'Workspace:FindFirstChild("Map")',
	"MapService must replace Workspace.Map"
)
assertContains(
	mapService,
	"clone.Parent = Workspace",
	"MapService must parent reloaded map to Workspace"
)
assertContains(mapService, "function MapService.reload", "MapService must expose reload")
assertContains(
	mapService,
	"function MapService.getCurrentMapName",
	"MapService must expose current map"
)
assertContains(
	mapService,
	"function MapService.getReloadVersion",
	"MapService must expose reload version"
)

local command = read(RELOAD_COMMAND_PATH)
assertContains(
	command,
	"Reload a Rojo-managed map from ServerStorage.Maps into Workspace.Map.",
	"reloadmap definition must describe real MapService behavior"
)

local handler = read(RELOAD_HANDLER_PATH)
assertContains(handler, "MapService.reload", "reloadmap handler must call MapService.reload")
assertTrue(
	handler:find("arrives after Studio bridge validation", 1, true) == nil,
	"reloadmap handler must not describe MapService as future work"
)

local init = read(INIT_PATH)
assertContains(
	init,
	"local MapService = require(script.Services.MapService)",
	"server init must require MapService"
)
assertContains(init, "MapService.start()", "server init must start MapService")

print("MapService contract tests passed")
