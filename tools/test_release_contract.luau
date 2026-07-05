--!strict

local fs = require("@lune/fs")

local RELEASE_SCRIPT_PATH = "tools/open_cloud_publish.luau"
local FIXTURE_PATH = "tools/fixtures/opencloud.env"
local CHECKLIST_PATH = "docs/runbooks/release-checklist.md"
local GITIGNORE_PATH = ".gitignore"
local ENV_EXAMPLE_PATH = ".env.example"
local LAUNCHER_PATH = "nexus.ps1"
local SECRET_SCAN_PATH = "tools/secret_scan.luau"

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

local releaseScript = read(RELEASE_SCRIPT_PATH)
local fixture = read(FIXTURE_PATH)
local checklist = read(CHECKLIST_PATH)
local gitignore = read(GITIGNORE_PATH)
local envExample = read(ENV_EXAMPLE_PATH)
local launcher = read(LAUNCHER_PATH)
local secretScan = read(SECRET_SCAN_PATH)

assertContains(
	releaseScript,
	'local SECRET_PATH = "secrets/opencloud.env"',
	"release must read local secret path"
)
assertContains(
	releaseScript,
	'local FIXTURE_PATH = "tools/fixtures/opencloud.env"',
	"release must support fixture config"
)
assertContains(
	releaseScript,
	'local DEFAULT_ARTIFACT = "build/nexus.rbxl"',
	"release must default to build artifact"
)
assertContains(releaseScript, "dryRun = true", "release must default to dry-run")
assertContains(
	releaseScript,
	"if sawDryRun and sawLive then",
	"release must reject --dry-run with --live"
)
assertContains(
	releaseScript,
	"Fixture config is dry-run only",
	"fixture config must be rejected for live publish"
)
assertContains(
	releaseScript,
	"if not options.dryRun and looksPlaceholder(config.apiKey) then",
	"live publish must reject placeholder API keys"
)
assertContains(
	releaseScript,
	"Live request was not sent.",
	"dry-run output must state no live request"
)
assertContains(releaseScript, "Universe ID: values hidden", "live output must hide universe id")
assertContains(
	releaseScript,
	"Response body: output omitted",
	"live output must omit response body"
)
assertContains(releaseScript, 'method = "POST"', "live publish must use POST")
assertContains(
	releaseScript,
	'["x-api-key"] = config.apiKey',
	"live publish must send the Open Cloud key only as a header"
)
assertContains(
	releaseScript,
	"versions?versionType=Published",
	"release endpoint must publish a place version"
)
assertContains(
	releaseScript,
	"Artifact must be a .rbxl or .rbxlx file.",
	"release must validate artifact extension"
)
assertContains(
	releaseScript,
	"Artifact is empty or unreadable",
	"release must reject empty artifacts"
)

assertContains(
	fixture,
	"OPEN_CLOUD_API_KEY=fixture_open_cloud_key_do_not_use",
	"fixture key must be clearly fake"
)
assertContains(fixture, "ROBLOX_UNIVERSE_ID=1234567890", "fixture universe id must be numeric")
assertContains(fixture, "ROBLOX_PLACE_ID=9876543210", "fixture place id must be numeric")

assertContains(gitignore, "secrets/*", "secrets directory must be ignored")
assertContains(gitignore, "!secrets/.gitkeep", "secrets .gitkeep must stay tracked")
assertContains(gitignore, ".env", ".env must be ignored")
assertContains(gitignore, "*.rbxl", "rbxl artifacts must be ignored")
assertContains(gitignore, "*.rbxlx", "rbxlx artifacts must be ignored")

assertContains(
	envExample,
	"OPEN_CLOUD_API_KEY=replace_with_open_cloud_key",
	"env example must use placeholder Open Cloud key"
)
assertContains(
	envExample,
	"ROBLOX_UNIVERSE_ID=0000000000",
	"env example must use placeholder universe id"
)
assertContains(
	envExample,
	"ROBLOX_PLACE_ID=0000000000",
	"env example must use placeholder place id"
)
assertNotContains(
	envExample,
	"fixture_open_cloud_key_do_not_use",
	"env example must not use fixture key as real guidance"
)

assertContains(
	launcher,
	'Invoke-Tool "lune" (@("run", "tools/open_cloud_publish.luau") + $Rest)',
	"launcher release command must forward args to release script"
)

assertContains(
	checklist,
	"./nexus.ps1 release --dry-run --fixture",
	"checklist must require fixture dry-run"
)
assertContains(
	checklist,
	"./nexus.ps1 release --live",
	"checklist must document explicit live command"
)
assertContains(checklist, "Complete G5", "checklist must keep live publish behind G5")
assertContains(checklist, "Overall: PASS", "checklist must require green Build Health")
assertContains(
	checklist,
	"git log -p -- secrets .env",
	"checklist must include secret-history check"
)
assertContains(
	checklist,
	"Expected result: no output.",
	"checklist must state secret scan expected output"
)

assertContains(
	secretScan,
	"Filled Open Cloud API key",
	"secret scan must include Open Cloud key rule"
)
assertContains(secretScan, "OPEN_CLOUD_API_KEY", "secret scan must scan Open Cloud key names")
assertContains(secretScan, "do_not_use", "secret scan must allow explicit fake fixture values")

print("Release contract tests passed")
