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

local function countClass(parent: any, className: string): number
	local count = if parent.ClassName == className then 1 else 0
	for _, child in parent.Children or {} do
		count += countClass(child, className)
	end

	return count
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
assertTrue(
	childNamed(defaultMap, "WorldHub_UltraPass") ~= nil,
	"Default map must contain the upgraded clubhouse hub"
)
assertTrue(
	childNamed(defaultMap, "DrivingRange_UltraPass") ~= nil,
	"Default map must contain a separated driving range"
)
assertTrue(
	childNamed(defaultMap, "PracticeHoles_UltraPass") ~= nil,
	"Default map must contain separated practice holes"
)
local pinebrookBlockout = childNamed(defaultMap, "PinebrookNational_Blockout_Phase4")
assertTrue(pinebrookBlockout ~= nil, "Default map must contain Pinebrook championship course")
assertTrue(
	childNamed(pinebrookBlockout, "PlaytestSpawn") ~= nil,
	"Default map must contain a playtest spawn"
)
local destinations = childNamed(defaultMap, "WorldDestinations")
assertTrue(destinations ~= nil, "Default map must contain world destinations")
for _, destinationName in
	{
		"ClubhouseSpawn",
		"DrivingRange_Hole01_Spawn",
		"PracticeHoles_Hole01_Spawn",
		"PracticeHoles_Hole03_Spawn",
		"Pinebrook18_Hole01_Spawn",
		"Pinebrook18_Hole18_Spawn",
	}
do
	assertTrue(
		childNamed(destinations, destinationName) ~= nil,
		"Default map missing destination " .. destinationName
	)
end
assertTrue(countClass(defaultMap, "Part") >= 300, "Default map must be a dense playable world")
assertTrue(
	countClass(defaultMap, "SpawnLocation") >= 24,
	"Default map must contain every route spawn"
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
assertContains(
	mapService,
	"function MapService.teleportPlayerToDestination",
	"MapService must expose destination teleport"
)
assertContains(
	mapService,
	"function MapService.teleportPlayerToRound",
	"MapService must expose round teleport"
)
assertContains(
	mapService,
	"WorldConfig.destinationName",
	"MapService must route rounds through WorldConfig destinations"
)
assertContains(
	mapService,
	'Workspace:FindFirstChild("Map")',
	"MapService destination lookup must read Workspace.Map"
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
