--!strict

local MigrationLogic = {}

local function deepCopy(value: any): any
	if type(value) ~= "table" then
		return value
	end

	local copy = {}
	for key, child in value do
		copy[key] = deepCopy(child)
	end

	return copy
end

local function mergeDefaults(data: any, defaults: any)
	for key, defaultValue in defaults do
		if data[key] == nil then
			data[key] = deepCopy(defaultValue)
		elseif type(data[key]) == "table" and type(defaultValue) == "table" then
			mergeDefaults(data[key], defaultValue)
		end
	end
end

function MigrationLogic.migrate(rawData: any, defaults: any, currentVersion: number): any
	local data = if type(rawData) == "table" then rawData else {}

	mergeDefaults(data, defaults)

	local version = tonumber(data.schema_version) or 0
	if version < currentVersion then
		data.schema_version = currentVersion
	end

	return data
end

return MigrationLogic
