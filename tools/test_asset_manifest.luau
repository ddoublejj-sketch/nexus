--!strict

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local MANIFEST_PATH = "assets_export/manifests/assets.json"
local VAULT_ROOT = "C:/Users/jackw/Roblox/RobloxGameVault"
local ASSET_INDEX_PATH = VAULT_ROOT .. "/90_Automation/Generated/Asset Manifest.md"
local THUMBNAIL_BACKLOG_PATH = VAULT_ROOT .. "/90_Automation/Generated/Asset Thumbnail Backlog.md"
local ASSET_NOTE_ROOT = VAULT_ROOT .. "/04_Assets/Models"
local RENDER_SCRIPT_PATH = "tools/render_asset_thumbnails.py"
local LAUNCHER_PATH = "nexus.ps1"
local TASKS_PATH = ".vscode/tasks.json"

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

local EXPECTED_IDS = {
	energy_shard_01 = true,
	glow_ring_a_01 = true,
	glow_ring_b_01 = true,
	greatsword_01 = true,
}

local function assertTrue(condition: boolean, label: string)
	if not condition then
		error(label)
	end
end

local function assertEqual(actual: any, expected: any, label: string)
	if actual ~= expected then
		error(("%s: expected %s, got %s"):format(label, tostring(expected), tostring(actual)))
	end
end

local function read(path: string): string
	assertTrue(fs.isFile(path), "Missing file: " .. path)
	return fs.readFile(path)
end

local function contains(values: { string }, expected: string): boolean
	for _, value in values do
		if value == expected then
			return true
		end
	end

	return false
end

local function notePathFor(row: AssetRow): string
	return ASSET_NOTE_ROOT .. "/" .. row.name .. ".md"
end

local manifest = serde.decode("json", read(MANIFEST_PATH)) :: { AssetRow }
assertTrue(#manifest >= 4, "Manifest must contain at least four real seed assets")

local idsSeen: { [string]: boolean } = {}
local vaultExists = fs.isDir(VAULT_ROOT)
local assetIndex = if vaultExists then read(ASSET_INDEX_PATH) else ""
local thumbnailBacklog = if vaultExists then read(THUMBNAIL_BACKLOG_PATH) else ""
local renderScript = read(RENDER_SCRIPT_PATH)
local launcher = read(LAUNCHER_PATH)
local tasksJson = read(TASKS_PATH)

assertTrue(
	renderScript:find("bpy.ops.import_scene.fbx", 1, true) ~= nil,
	"thumbnail renderer must import FBX seed assets"
)
assertTrue(
	launcher:find('"thumbnails"', 1, true) ~= nil,
	"launcher must expose thumbnail rendering"
)
assertTrue(
	tasksJson:find("Nexus: Render Thumbnails", 1, true) ~= nil,
	"VS Code tasks must expose thumbnail rendering"
)

for _, row in manifest do
	assertTrue(row.id ~= nil and row.id ~= "", "Asset row missing id")
	assertTrue(idsSeen[row.id] ~= true, "Duplicate asset id: " .. row.id)
	idsSeen[row.id] = true

	assertTrue(row.name ~= nil and row.name ~= "", row.id .. " missing name")
	assertTrue(row.source ~= nil and row.source ~= "", row.id .. " missing source")
	assertTrue(row.export ~= nil and row.export ~= "", row.id .. " missing export")
	assertTrue(row.thumbnail ~= nil and row.thumbnail ~= "", row.id .. " missing thumbnail")
	assertEqual(row.license, "original", row.id .. " license")
	assertTrue(contains(row.tags, "seed"), row.id .. " missing seed tag")
	assertTrue(contains(row.tags, "imported"), row.id .. " missing imported tag")
	assertTrue(
		row.updated:match("^%d%d%d%d%-%d%d%-%d%dT%d%d:%d%d:%d%dZ$") ~= nil,
		row.id .. " updated timestamp"
	)

	assertTrue(fs.isFile(row.source), row.id .. " source file missing: " .. row.source)
	assertTrue(#read(row.source) > 0, row.id .. " source file is empty")
	assertTrue(fs.isFile(row.export), row.id .. " export file missing: " .. row.export)
	assertTrue(#read(row.export) > 0, row.id .. " export file is empty")
	assertTrue(fs.isFile(row.thumbnail), row.id .. " thumbnail missing: " .. row.thumbnail)
	local thumbnail = read(row.thumbnail)
	assertTrue(
		row.thumbnail:match("%.png$") ~= nil,
		row.id .. " thumbnail should be a rendered PNG"
	)
	local b1, b2, b3, b4 = thumbnail:byte(1, 4)
	assertTrue(
		b1 == 137 and b2 == 80 and b3 == 78 and b4 == 71,
		row.id .. " thumbnail must have PNG signature"
	)

	if vaultExists then
		local note = read(notePathFor(row))
		assertTrue(
			note:find("type: asset", 1, true) ~= nil,
			row.id .. " vault note missing asset frontmatter"
		)
		assertTrue(
			note:find("| Asset ID | `" .. row.id .. "` |", 1, true) ~= nil,
			row.id .. " vault note missing asset id"
		)
		assertTrue(
			note:find("| Source | `" .. row.source .. "` |", 1, true) ~= nil,
			row.id .. " vault note missing source"
		)
		assertTrue(
			note:find("| Export | `" .. row.export .. "` |", 1, true) ~= nil,
			row.id .. " vault note missing export"
		)
		assertTrue(
			assetIndex:find(row.name, 1, true) ~= nil,
			row.id .. " missing from generated asset index"
		)
		assertTrue(
			thumbnailBacklog:find(
				"All manifest assets currently have rendered PNG thumbnails.",
				1,
				true
			) ~= nil,
			"thumbnail backlog should report all rendered"
		)
	end
end

for expectedId in EXPECTED_IDS do
	assertTrue(idsSeen[expectedId] == true, "Missing seed asset: " .. expectedId)
end

if vaultExists then
	assertTrue(
		assetIndex:find("- Manifest rows: 4", 1, true) ~= nil,
		"Asset index must report four manifest rows"
	)
	assertTrue(
		assetIndex:find("- Rows with missing source files: 0", 1, true) ~= nil,
		"Asset index must report zero missing sources"
	)
	assertTrue(
		assetIndex:find("- Rows with missing export files: 0", 1, true) ~= nil,
		"Asset index must report zero missing exports"
	)
end

print("Asset manifest tests passed")
