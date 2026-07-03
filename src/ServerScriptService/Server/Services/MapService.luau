--!strict

local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local MapService = {}

local currentMapName = "Default"
local reloadVersion = 0

local function getMapsFolder(): Folder?
	local maps = ServerStorage:FindFirstChild("Maps")
	if maps and maps:IsA("Folder") then
		return maps
	end

	return nil
end

function MapService.start()
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
