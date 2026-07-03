--!strict

local fs = require("@lune/fs")
local net = require("@lune/net")
local process = require("@lune/process")

local SECRET_PATH = "secrets/opencloud.env"
local FIXTURE_PATH = "tools/fixtures/opencloud.env"
local DEFAULT_ARTIFACT = "build/nexus.rbxl"
local API_ROOT = "https://apis.roblox.com/universes/v1"

type Options = {
	artifactPath: string,
	dryRun: boolean,
	fixture: boolean,
}

type PublishConfig = {
	apiKey: string,
	universeId: string,
	placeId: string,
	source: string,
	fixture: boolean,
}

local function trim(value: string): string
	return value:match("^%s*(.-)%s*$") or ""
end

local function readEnvFile(path: string): { [string]: string }
	local values = {}

	if not fs.isFile(path) then
		return values
	end

	for line in fs.readFile(path):gmatch("[^\r\n]+") do
		local stripped = trim(line)
		if stripped ~= "" and not stripped:match("^#") then
			local key, value = stripped:match("^([%w_]+)%s*=%s*(.+)$")
			if key and value then
				values[key] = trim(value)
			end
		end
	end

	return values
end

local function usage(): string
	return table.concat({
		"Usage: lune run tools/open_cloud_publish.luau [--dry-run | --live] [--fixture] [--artifact path]",
		"",
		"Dry-run is the default. Live publish requires secrets/opencloud.env and --live.",
	}, "\n")
end

local function parseArgs(args: { string }): Options
	local options: Options = {
		artifactPath = DEFAULT_ARTIFACT,
		dryRun = true,
		fixture = false,
	}

	local sawDryRun = false
	local sawLive = false
	local index = 1

	while index <= #args do
		local arg = args[index]

		if arg == "--help" or arg == "-h" then
			print(usage())
			process.exit(0)
		elseif arg == "--dry-run" then
			sawDryRun = true
			options.dryRun = true
		elseif arg == "--live" then
			sawLive = true
			options.dryRun = false
		elseif arg == "--fixture" then
			options.fixture = true
		elseif arg == "--artifact" then
			index += 1
			if index > #args then
				error("--artifact requires a path")
			end
			options.artifactPath = args[index]
		elseif arg:match("^%-%-artifact=") then
			options.artifactPath = arg:gsub("^%-%-artifact=", "")
		else
			error("Unknown argument: " .. arg .. "\n" .. usage())
		end

		index += 1
	end

	if sawDryRun and sawLive then
		error("Choose either --dry-run or --live, not both.")
	end

	return options
end

local function hasEnvConfig(): boolean
	return process.env.OPEN_CLOUD_API_KEY ~= nil
		or process.env.ROBLOX_UNIVERSE_ID ~= nil
		or process.env.ROBLOX_PLACE_ID ~= nil
end

local function valueFor(values: { [string]: string }, key: string): string
	return process.env[key] or values[key] or ""
end

local function readConfig(options: Options): PublishConfig
	local useFixture = options.fixture
	if options.dryRun and not useFixture and not fs.isFile(SECRET_PATH) and not hasEnvConfig() then
		useFixture = true
	end

	if useFixture and not options.dryRun then
		error(
			"Fixture config is dry-run only. Remove --fixture and create "
				.. SECRET_PATH
				.. " for --live."
		)
	end

	local source = if useFixture then FIXTURE_PATH else SECRET_PATH
	local values = readEnvFile(source)

	return {
		apiKey = valueFor(values, "OPEN_CLOUD_API_KEY"),
		universeId = valueFor(values, "ROBLOX_UNIVERSE_ID"),
		placeId = valueFor(values, "ROBLOX_PLACE_ID"),
		source = source,
		fixture = useFixture,
	}
end

local function assertId(label: string, value: string)
	if value == "" then
		error(label .. " is missing.")
	end
	if not value:match("^%d+$") then
		error(label .. " must contain digits only.")
	end
	if value:match("^0+$") then
		error(label .. " must not be all zeroes.")
	end
end

local function looksPlaceholder(value: string): boolean
	local lower = value:lower()
	return lower == ""
		or lower:find("replace", 1, true) ~= nil
		or lower:find("fixture", 1, true) ~= nil
		or lower:find("placeholder", 1, true) ~= nil
		or lower:find("do_not_use", 1, true) ~= nil
end

local function readArtifact(path: string): (string, number)
	if not fs.isFile(path) then
		error(
			"Missing artifact: "
				.. path
				.. ". Run the quality gate or build before release dry-run."
		)
	end
	if not (path:match("%.rbxl$") or path:match("%.rbxlx$")) then
		error("Artifact must be a .rbxl or .rbxlx file.")
	end

	local contents = fs.readFile(path)
	if #contents <= 0 then
		error("Artifact is empty or unreadable: " .. path)
	end

	return contents, #contents
end

local function endpointFor(config: PublishConfig): string
	return ("%s/%s/places/%s/versions?versionType=Published"):format(
		API_ROOT,
		config.universeId,
		config.placeId
	)
end

local options = parseArgs(process.args)
local config = readConfig(options)
local artifactContents, artifactBytes = readArtifact(options.artifactPath)
assertId("ROBLOX_UNIVERSE_ID", config.universeId)
assertId("ROBLOX_PLACE_ID", config.placeId)

if not options.dryRun and looksPlaceholder(config.apiKey) then
	error("OPEN_CLOUD_API_KEY is missing or looks like a placeholder.")
end

local endpoint = endpointFor(config)

if options.dryRun then
	print("Open Cloud publish dry-run PASS")
	print("Mode: dry-run")
	print("Config source: " .. config.source .. (if config.fixture then " (fixture)" else ""))
	print(("Artifact: %s (%d bytes)"):format(options.artifactPath, artifactBytes))
	print("Universe ID: " .. config.universeId)
	print("Place ID: " .. config.placeId)
	print("Endpoint: " .. endpoint)
	print("Live request was not sent.")
else
	local response = net.request({
		url = endpoint,
		method = "POST",
		headers = {
			["x-api-key"] = config.apiKey,
			["Content-Type"] = "application/octet-stream",
		},
		body = artifactContents,
	})

	if not response.ok then
		error(
			("Open Cloud publish failed: %d %s\n%s"):format(
				response.statusCode,
				response.statusMessage,
				response.body
			)
		)
	end

	print("Open Cloud publish PASS")
	print(("Artifact: %s (%d bytes)"):format(options.artifactPath, artifactBytes))
	print("Universe ID: " .. config.universeId)
	print("Place ID: " .. config.placeId)
	print(response.body)
end
