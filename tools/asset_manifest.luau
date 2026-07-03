--!strict

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local VAULT_ROOT = "C:/Users/jackw/Roblox/RobloxGameVault"
local MANIFEST_PATH = "assets_export/manifests/assets.json"
local ASSET_NOTE_ROOT = VAULT_ROOT .. "/04_Assets/Models"
local OUTPUT_PATH = VAULT_ROOT .. "/90_Automation/Generated/Asset Manifest.md"
local PLACEHOLDER_NOTE_PATH = VAULT_ROOT .. "/90_Automation/Generated/Asset Thumbnail Backlog.md"

type AssetRow = {
	id: string,
	name: string,
	source: string,
	export: string,
	roblox_asset_id: string?,
	tri_count: number,
	tags: { string },
	license: string,
	thumbnail: string,
	used_in: { string },
	updated: string,
}

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

local function writeIfChanged(path: string, contents: string)
	ensureParent(path)
	if fs.isFile(path) and fs.readFile(path) == contents then
		return
	end

	fs.writeFile(path, contents)
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

local function isAssetFile(path: string): boolean
	local lower = path:lower()
	return lower:match("%.fbx$") ~= nil
		or lower:match("%.obj$") ~= nil
		or lower:match("%.glb$") ~= nil
		or lower:match("%.gltf$") ~= nil
		or lower:match("%.bbmodel$") ~= nil
		or lower:match("%.blend$") ~= nil
end

local function isExportAsset(path: string): boolean
	return path:match("^assets_export/roblox/") ~= nil and isAssetFile(path)
end

local function basenameWithoutExtension(path: string): string
	local name = path:gsub("\\", "/"):match("([^/]+)$") or path
	return name:gsub("%.[^%.]+$", "")
end

local function toTitle(name: string): string
	local spaced = name:gsub("_", " "):gsub("%-", " ")
	return (spaced:gsub("(%a)([%w_']*)", function(first, rest)
		return first:upper() .. rest
	end))
end

local function slug(name: string): string
	local value = name:gsub("([a-z])([A-Z])", "%1_%2")
	value = value:gsub("[^%w]+", "_"):gsub("_+", "_"):gsub("^_", ""):gsub("_$", "")
	return value:lower()
end

local function assetIdForBase(baseName: string): string
	return slug(baseName) .. "_01"
end

local function thumbnailPathFor(id: string): string
	return "assets_export/thumbnails/" .. id .. ".placeholder.txt"
end

local function jsonString(value: string): string
	local replacements = {
		['"'] = '\\"',
		["\\"] = "\\\\",
		["\b"] = "\\b",
		["\f"] = "\\f",
		["\n"] = "\\n",
		["\r"] = "\\r",
		["\t"] = "\\t",
	}

	return '"' .. value:gsub('["\\\b\f\n\r\t]', replacements) .. '"'
end

local function jsonArray(values: { string }): string
	if #values == 0 then
		return "[]"
	end

	local encoded = {}
	for _, value in values do
		table.insert(encoded, jsonString(value))
	end

	return "[ " .. table.concat(encoded, ", ") .. " ]"
end

local function encodeManifest(rows: { AssetRow }): string
	local lines = { "[" }

	for index, row in rows do
		table.insert(lines, "  {")
		table.insert(lines, '    "id": ' .. jsonString(row.id) .. ",")
		table.insert(lines, '    "name": ' .. jsonString(row.name) .. ",")
		table.insert(lines, '    "source": ' .. jsonString(row.source) .. ",")
		table.insert(lines, '    "export": ' .. jsonString(row.export) .. ",")
		table.insert(
			lines,
			'    "roblox_asset_id": '
				.. if row.roblox_asset_id then jsonString(row.roblox_asset_id) else "null" .. ","
		)
		table.insert(lines, '    "tri_count": ' .. tostring(row.tri_count) .. ",")
		table.insert(lines, '    "tags": ' .. jsonArray(row.tags) .. ",")
		table.insert(lines, '    "license": ' .. jsonString(row.license) .. ",")
		table.insert(lines, '    "thumbnail": ' .. jsonString(row.thumbnail) .. ",")
		table.insert(lines, '    "used_in": ' .. jsonArray(row.used_in) .. ",")
		table.insert(lines, '    "updated": ' .. jsonString(row.updated))
		table.insert(lines, if index == #rows then "  }" else "  },")
	end

	table.insert(lines, "]")
	return table.concat(lines, "\n") .. "\n"
end

local function readManifest(): { AssetRow }
	if not fs.isFile(MANIFEST_PATH) then
		return {}
	end

	local decoded = serde.decode("json", fs.readFile(MANIFEST_PATH)) :: { any }
	local rows = {}

	for _, raw in decoded do
		table.insert(rows, {
			id = raw.id,
			name = raw.name,
			source = raw.source or "",
			export = raw.export or "",
			roblox_asset_id = raw.roblox_asset_id,
			tri_count = raw.tri_count or 0,
			tags = raw.tags or {},
			license = raw.license or "original",
			thumbnail = raw.thumbnail or thumbnailPathFor(raw.id),
			used_in = raw.used_in or {},
			updated = raw.updated or isoTimestamp(),
		})
	end

	return rows
end

local function findSourceForBase(baseName: string): string
	local preferred = "assets_src/imported/" .. baseName .. ".fbx"
	if fs.isFile(preferred) then
		return preferred
	end

	for _, filePath in listFiles("assets_src") do
		if basenameWithoutExtension(filePath) == baseName and isAssetFile(filePath) then
			return filePath
		end
	end

	return ""
end

local function sortRows(rows: { AssetRow })
	table.sort(rows, function(left, right)
		return left.id < right.id
	end)
end

local function buildRowForExport(exportPath: string, existing: AssetRow?): AssetRow
	local baseName = basenameWithoutExtension(exportPath)
	local id = assetIdForBase(baseName)
	local timestamp = if existing then existing.updated else isoTimestamp()

	return {
		id = id,
		name = if existing then existing.name else toTitle(baseName),
		source = if existing then existing.source else findSourceForBase(baseName),
		export = exportPath,
		roblox_asset_id = if existing then existing.roblox_asset_id else nil,
		tri_count = if existing then existing.tri_count else 0,
		tags = if existing then existing.tags else { "seed", "imported" },
		license = if existing then existing.license else "original",
		thumbnail = if existing then existing.thumbnail else thumbnailPathFor(id),
		used_in = if existing then existing.used_in else {},
		updated = timestamp,
	}
end

local function writeThumbnailPlaceholder(row: AssetRow)
	if row.thumbnail == "" then
		return
	end

	local contents = table.concat({
		"Placeholder thumbnail for " .. row.name,
		"",
		"Blender was not resolved during WO-0, so thumbnail rendering is backlogged.",
		"Source: " .. row.source,
		"Export: " .. row.export,
		"",
	}, "\n")

	writeIfChanged(row.thumbnail, contents)
end

local function writeAssetNote(row: AssetRow)
	local notePath = ASSET_NOTE_ROOT .. "/" .. row.name .. ".md"
	local assetId = row.roblox_asset_id or ""
	local tags = if #row.tags > 0 then table.concat(row.tags, ", ") else ""
	local usedIn = if #row.used_in > 0 then table.concat(row.used_in, ", ") else "Not placed yet."

	local contents = table.concat({
		"---",
		"type: asset",
		"status: active",
		"owner:",
		"source_path: C:\\Users\\jackw\\Roblox\\nexus\\" .. row.source:gsub("/", "\\"),
		"roblox_asset_id: " .. assetId,
		"studio_instance_path:",
		"dependencies:",
		"last_synced: " .. row.updated,
		"tags: " .. tags,
		"---",
		"",
		"# " .. row.name,
		"",
		"| Field | Value |",
		"| --- | --- |",
		"| Asset ID | `" .. row.id .. "` |",
		"| Source | `" .. row.source .. "` |",
		"| Export | `" .. row.export .. "` |",
		"| Thumbnail | `" .. row.thumbnail .. "` |",
		"| Roblox Asset ID | `" .. (row.roblox_asset_id or "not-published") .. "` |",
		"| Tri Count | " .. tostring(row.tri_count) .. " |",
		"| License | " .. row.license .. " |",
		"",
		"## Usage",
		"",
		usedIn,
		"",
	}, "\n")

	writeIfChanged(notePath, contents)
end

local function rowExistsById(rowsById: { [string]: AssetRow }, id: string): boolean
	return rowsById[id] ~= nil
end

local existingRows = readManifest()
local rowsById: { [string]: AssetRow } = {}

for _, row in existingRows do
	rowsById[row.id] = row
end

local restoredIds = {}
local exportFiles = {}
for _, filePath in listFiles("assets_export/roblox") do
	if isExportAsset(filePath) then
		table.insert(exportFiles, filePath)
	end
end

for _, exportPath in exportFiles do
	local id = assetIdForBase(basenameWithoutExtension(exportPath))
	local existing = rowsById[id]
	if not rowExistsById(rowsById, id) then
		table.insert(restoredIds, id)
	end
	rowsById[id] = buildRowForExport(exportPath, existing)
end

local rows = {}
local missingSourceRows = {}
local missingExportRows = {}

for _, row in rowsById do
	if row.source ~= "" and not fs.isFile(row.source) then
		table.insert(missingSourceRows, row.id)
	end
	if row.export ~= "" and not fs.isFile(row.export) then
		table.insert(missingExportRows, row.id)
	end
	table.insert(rows, row)
end

sortRows(rows)
table.sort(restoredIds)
table.sort(missingSourceRows)
table.sort(missingExportRows)

for _, row in rows do
	writeThumbnailPlaceholder(row)
	writeAssetNote(row)
end

ensureParent(MANIFEST_PATH)
writeIfChanged(MANIFEST_PATH, encodeManifest(rows))

local catalogVersion = if #rows > 0 then rows[#rows].updated else "not-yet-generated"
local lines = {
	"---",
	"type: asset",
	"status: active",
	"owner:",
	"source_path: C:\\Users\\jackw\\Roblox\\nexus\\assets_export\\manifests\\assets.json",
	"roblox_asset_id:",
	"studio_instance_path:",
	"dependencies:",
	"last_synced: " .. catalogVersion,
	"tags:",
	"---",
	"",
	"# Asset Manifest",
	"",
	"Catalog version: " .. catalogVersion,
	"",
	"| Asset | Source | Export | Thumbnail | Roblox ID |",
	"| --- | --- | --- | --- | --- |",
}

for _, row in rows do
	table.insert(
		lines,
		("| %s | `%s` | `%s` | `%s` | %s |"):format(
			row.name,
			row.source,
			row.export,
			row.thumbnail,
			row.roblox_asset_id or "not-published"
		)
	)
end

table.insert(lines, "")
table.insert(lines, "## Reconciliation")
table.insert(lines, "")
table.insert(lines, ("- Manifest rows: %d"):format(#rows))
table.insert(lines, ("- Auto-added missing manifest rows this run: %d"):format(#restoredIds))
table.insert(lines, ("- Rows with missing source files: %d"):format(#missingSourceRows))
table.insert(lines, ("- Rows with missing export files: %d"):format(#missingExportRows))

if #restoredIds > 0 then
	table.insert(lines, "")
	table.insert(lines, "### Auto-added Rows")
	for _, id in restoredIds do
		table.insert(lines, "- `" .. id .. "`")
	end
end

if #missingSourceRows > 0 then
	table.insert(lines, "")
	table.insert(lines, "### Missing Sources")
	for _, id in missingSourceRows do
		table.insert(lines, "- `" .. id .. "`")
	end
end

if #missingExportRows > 0 then
	table.insert(lines, "")
	table.insert(lines, "### Missing Exports")
	for _, id in missingExportRows do
		table.insert(lines, "- `" .. id .. "`")
	end
end

writeIfChanged(OUTPUT_PATH, table.concat(lines, "\n") .. "\n")

local backlogLines = {
	"---",
	"type: asset",
	"status: blocked",
	"owner:",
	"source_path: C:\\Users\\jackw\\Roblox\\nexus\\tools\\asset_manifest.luau",
	"roblox_asset_id:",
	"studio_instance_path:",
	"dependencies:",
	"last_synced: " .. catalogVersion,
	"tags: thumbnails, blender",
	"---",
	"",
	"# Asset Thumbnail Backlog",
	"",
	"Blender was not resolved in WO-0, so real thumbnail renders are pending.",
	"",
}

for _, row in rows do
	table.insert(backlogLines, "- `" .. row.thumbnail .. "` for " .. row.name)
end

writeIfChanged(PLACEHOLDER_NOTE_PATH, table.concat(backlogLines, "\n") .. "\n")

print(
	("Asset manifest reconciled %d assets; auto-added %d; missing sources %d; missing exports %d"):format(
		#rows,
		#restoredIds,
		#missingSourceRows,
		#missingExportRows
	)
)
