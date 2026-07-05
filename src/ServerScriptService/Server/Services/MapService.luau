--!strict

local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local MapService = {}

local DEFAULT_MAP_NAME = "Default"

local currentMapName = DEFAULT_MAP_NAME
local reloadVersion = 0

local function getMapsFolder(): Folder?
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

return MapService
