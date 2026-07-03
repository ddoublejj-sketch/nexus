--!strict

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local VAULT_ROOT = "C:/Users/jackw/Roblox/RobloxGameVault"
local MANIFEST_PATH = "assets_export/manifests/assets.json"
local OUTPUT_PATH = VAULT_ROOT .. "/90_Automation/Generated/Asset Manifest.md"

local function isoTimestamp(): string
	return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

local function ensureDir(path: string)
	if not fs.isDir(path) then
		fs.writeDir(path)
	end
end

local function ensureParent(path: string)
	local parent = path:match("^(.*)/[^/]+$")
	if parent then
		ensureDir(parent)
	end
end

local function listFiles(root: string): { string }
	local files = {}

	if not fs.isDir(root) then
		return files
	end

	for _, entry in fs.readDir(root) do
		local path = root .. "/" .. entry
		if fs.isDir(path) then
			for _, nested in listFiles(path) do
				table.insert(files, nested)
			end
		else
			table.insert(files, path)
		end
	end

	table.sort(files)
	return files
end

ensureParent(MANIFEST_PATH)

if not fs.isFile(MANIFEST_PATH) then
	fs.writeFile(MANIFEST_PATH, serde.encode("json", {}))
end

local manifestRows = serde.decode("json", fs.readFile(MANIFEST_PATH)) :: { any }
local sourceFiles = listFiles("assets_src")
local exportFiles = listFiles("assets_export")
local timestamp = isoTimestamp()

local lines = {
	"---",
	"type: asset",
	"status: active",
	"owner:",
	"source_path: C:\\Users\\jackw\\Roblox\\nexus\\assets_export\\manifests\\assets.json",
	"roblox_asset_id:",
	"studio_instance_path:",
	"dependencies:",
	"last_synced: " .. timestamp,
	"tags:",
	"---",
	"",
	"# Asset Manifest",
	"",
	"Generated: " .. timestamp,
	"",
	"WO-4 skeleton only. Full source/export reconciliation starts in WO-5.",
	"",
	"| Area | Count |",
	"| --- | --- |",
	("| Manifest rows | %d |"):format(#manifestRows),
	("| Source files | %d |"):format(#sourceFiles),
	("| Export files | %d |"):format(#exportFiles),
	"",
	"## Source Files",
}

if #sourceFiles == 0 then
	table.insert(lines, "- None yet.")
else
	for _, filePath in sourceFiles do
		table.insert(lines, "- `" .. filePath .. "`")
	end
end

table.insert(lines, "")
table.insert(lines, "## Export Files")

if #exportFiles == 0 then
	table.insert(lines, "- None yet.")
else
	for _, filePath in exportFiles do
		table.insert(lines, "- `" .. filePath .. "`")
	end
end

ensureParent(OUTPUT_PATH)
fs.writeFile(OUTPUT_PATH, table.concat(lines, "\n") .. "\n")

print(("Asset manifest skeleton wrote %s with %d manifest rows"):format(OUTPUT_PATH, #manifestRows))
