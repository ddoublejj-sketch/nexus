--!strict

local Constants = require("../../../ReplicatedStorage/Shared/GolfPro/Constants")
local Pinebrook = require("../../../ReplicatedStorage/Shared/GolfPro/Courses/course_pinebrook_v1")
local PracticeRange =
	require("../../../ReplicatedStorage/Shared/GolfPro/Courses/course_practice_range_v1")
local WorldConfig = require("../../../ReplicatedStorage/Shared/GolfPro/World/WorldConfig")

local MapService = {}

local DEFAULT_MAP_NAME = "Default"

local currentMapName = DEFAULT_MAP_NAME
local reloadVersion = 0

local function getServerStorage(): any?
	if game == nil then
		return nil
	end

	return game:GetService("ServerStorage")
end

local function getWorkspace(): any?
	if game == nil then
		return nil
	end

	return game:GetService("Workspace")
end

local function getTerrain(): any?
	local Workspace = getWorkspace()
	if Workspace == nil then
		return nil
	end

	return Workspace:FindFirstChildOfClass("Terrain")
end

local function getMapsFolder(): Folder?
	local ServerStorage = getServerStorage()
	if ServerStorage == nil then
		return nil
	end

	local maps = ServerStorage:FindFirstChild("Maps")
	if maps and maps:IsA("Folder") then
		return maps
	end

	return nil
end

local function hasPlayablePart(instance: Instance): boolean
	for _, descendant in instance:GetDescendants() do
		if descendant:IsA("BasePart") then
			return true
		end
	end

	return false
end

local function addDefaultPlaytestPad(map: Instance)
	local pad = Instance.new("Part")
	pad.Name = "PlaytestGround"
	pad.Anchored = true
	pad.Size = Vector3.new(220, 2, 360)
	pad.Position = Vector3.new(0, -1, 130)
	pad.Material = Enum.Material.Grass
	pad.Color = Color3.fromRGB(69, 137, 78)
	pad.Parent = map

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "PlaytestSpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.Position = Vector3.new(0, 2, 0)
	spawn.Duration = 0
	spawn.Neutral = true
	spawn.AllowTeamChangeOnTouch = false
	spawn.Material = Enum.Material.WoodPlanks
	spawn.Color = Color3.fromRGB(151, 112, 74)
	spawn.Parent = map
end

local function destinationPart(destinationName: string): BasePart?
	local Workspace = getWorkspace()
	if Workspace == nil then
		return nil
	end

	local map = Workspace:FindFirstChild("Map")
	local destinations = map and map:FindFirstChild("WorldDestinations")
	if destinations == nil then
		return nil
	end

	local destination = destinations:FindFirstChild(destinationName)
	if destination and destination:IsA("BasePart") then
		return destination
	end

	return nil
end

local function terrainMaterial(surface: string): Enum.Material
	if surface == Constants.Surface.BUNKER then
		return Enum.Material.Sand
	end
	if surface == Constants.Surface.WATER then
		return Enum.Material.Water
	end
	if surface == Constants.Surface.GREEN or surface == Constants.Surface.TEE then
		return Enum.Material.LeafyGrass
	end
	if surface == Constants.Surface.FAIRWAY then
		return Enum.Material.Grass
	end

	return Enum.Material.Ground
end

local function terrainLevel(surface: string): (number, number)
	if surface == Constants.Surface.WATER then
		return -3, 6
	end
	if surface == Constants.Surface.BUNKER then
		return -1, 5
	end

	return 0, 6
end

local function fillBounds(
	terrain: any,
	origin: any,
	bounds: any,
	y: number,
	height: number,
	material
)
	local scale = WorldConfig.STUDS_PER_YARD
	local width = math.max(8, (bounds.maxX - bounds.minX) * scale)
	local depth = math.max(8, (bounds.maxY - bounds.minY) * scale)
	local centerX = origin.x + (bounds.minX + bounds.maxX) * 0.5 * scale
	local centerZ = origin.z + (bounds.minY + bounds.maxY) * 0.5 * scale
	terrain:FillBlock(CFrame.new(centerX, y, centerZ), Vector3.new(width, height, depth), material)
end

local function fillHoleTerrain(terrain: any, course: any, mode: string, hole: any)
	local origin = WorldConfig.originFor(course.id, mode, hole.index)
	fillBounds(
		terrain,
		origin,
		{ minX = -150, maxX = 150, minY = -42, maxY = hole.yardage + 76 },
		-2,
		8,
		Enum.Material.Ground
	)

	for _, zone in hole.zones do
		local y, height = terrainLevel(zone.surface)
		fillBounds(terrain, origin, zone.bounds, y, height, terrainMaterial(zone.surface))
	end
end

local function fillCourseTerrain(terrain: any, course: any, mode: string, holeCount: number)
	for index = 1, holeCount do
		fillHoleTerrain(terrain, course, mode, course.holes[index])
	end
end

local function applyTerrain()
	local terrain = getTerrain()
	if terrain == nil then
		return
	end

	local ok, err = pcall(function()
		-- ponytail: one generated terrain layer; split by map when authored terrains exist.
		terrain:Clear()
		fillCourseTerrain(terrain, PracticeRange, Constants.Mode.PRACTICE, 1)
		fillCourseTerrain(terrain, Pinebrook, Constants.Mode.SOLO_STROKE_3_DEBUG, 3)
		fillCourseTerrain(terrain, Pinebrook, Constants.Mode.SOLO_STROKE_18, 18)
	end)
	if not ok then
		warn("[Nexus] Terrain generation failed: " .. tostring(err))
	end
end

local function cartPart(
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material,
	parent: Instance
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = false
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.Parent = parent
	return part
end

local function weldTo(root: BasePart, child: BasePart)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = child
	weld.Parent = root
end

local function spawnGolfCart(parent: Instance, spawnPart: BasePart)
	local model = Instance.new("Model")
	model.Name = spawnPart.Name:gsub("Spawn", "")
	model.Parent = parent

	local baseCFrame = spawnPart.CFrame + Vector3.new(0, 3, 0)
	local body = cartPart(
		"Body",
		Vector3.new(9, 1.2, 11),
		baseCFrame,
		Color3.fromRGB(34, 93, 67),
		Enum.Material.Metal,
		model
	)
	local seat = Instance.new("VehicleSeat")
	seat.Name = "DriverSeat"
	seat.Anchored = false
	seat.Size = Vector3.new(4, 1, 4)
	seat.CFrame = baseCFrame + Vector3.new(0, 1.5, -1)
	seat.Color = Color3.fromRGB(24, 24, 24)
	seat.Material = Enum.Material.SmoothPlastic
	seat.MaxSpeed = 42
	seat.Torque = 18000
	seat.TurnSpeed = 2
	seat.Parent = model
	weldTo(body, seat)

	local roof = cartPart(
		"Roof",
		Vector3.new(9, 0.6, 10),
		baseCFrame + Vector3.new(0, 5, 0),
		Color3.fromRGB(235, 237, 219),
		Enum.Material.SmoothPlastic,
		model
	)
	weldTo(body, roof)

	for index, offset in
		{
			Vector3.new(-4.6, -0.8, -3.8),
			Vector3.new(4.6, -0.8, -3.8),
			Vector3.new(-4.6, -0.8, 3.8),
			Vector3.new(4.6, -0.8, 3.8),
		}
	do
		local wheel = cartPart(
			("Wheel%02d"):format(index),
			Vector3.new(2, 2, 1.2),
			baseCFrame * CFrame.new(offset) * CFrame.Angles(0, 0, math.rad(90)),
			Color3.fromRGB(18, 18, 18),
			Enum.Material.SmoothPlastic,
			model
		)
		wheel.Shape = Enum.PartType.Cylinder
		weldTo(body, wheel)
	end

	model.PrimaryPart = body
end

local function spawnGolfCarts(map: Instance)
	local spawns = map:FindFirstChild("WorldCartSpawns")
	if spawns == nil then
		return
	end

	local carts = Instance.new("Folder")
	carts.Name = "GolfCarts"
	carts.Parent = map
	for _, spawnPart in spawns:GetChildren() do
		if spawnPart:IsA("BasePart") then
			spawnGolfCart(carts, spawnPart)
		end
	end
end

function MapService.start()
	local ok, message = MapService.reload(DEFAULT_MAP_NAME)
	if not ok then
		warn("[Nexus] " .. message)
	end

	print("[Nexus] MapService online")
end

function MapService.reload(mapName: string?): (boolean, string)
	local requestedMapName = if mapName and mapName ~= "" then mapName else currentMapName
	local maps = getMapsFolder()
	if maps == nil then
		return false, "ServerStorage.Maps is missing; cannot reload map."
	end
	local Workspace = getWorkspace()
	if Workspace == nil then
		return false, "Workspace is unavailable; cannot reload map."
	end

	local template = maps:FindFirstChild(requestedMapName)
	if template == nil then
		return false, ("No map named %q exists under ServerStorage.Maps."):format(requestedMapName)
	end

	local previous = Workspace:FindFirstChild("Map")
	if previous then
		previous:Destroy()
	end

	local clone = template:Clone()
	clone.Name = "Map"
	if requestedMapName == DEFAULT_MAP_NAME and not hasPlayablePart(clone) then
		addDefaultPlaytestPad(clone)
	end
	clone.Parent = Workspace
	applyTerrain()
	spawnGolfCarts(clone)

	currentMapName = requestedMapName
	reloadVersion += 1

	return true,
		("Reloaded map %q into Workspace.Map (version %d)."):format(requestedMapName, reloadVersion)
end

function MapService.getCurrentMapName(): string
	return currentMapName
end

function MapService.getReloadVersion(): number
	return reloadVersion
end

function MapService.teleportPlayerToDestination(
	player: any,
	destinationName: string
): (boolean, string)
	local destination = destinationPart(destinationName)
	if destination == nil then
		return false, "missing destination " .. destinationName
	end

	local character = player.Character
	if character == nil then
		return false, "character missing"
	end

	character:PivotTo(destination.CFrame + Vector3.new(0, 5, 0))
	return true, destinationName
end

function MapService.teleportPlayerToRound(player: any, round: any): (boolean, string)
	local destinationName = WorldConfig.destinationName(round.courseId, round.mode, round.holeIndex)
	return MapService.teleportPlayerToDestination(player, destinationName)
end

return MapService
