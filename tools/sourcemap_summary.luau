--!strict

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local SOURCEMAP_PATH = "sourcemap.json"
local VAULT_ROOT = "C:/Users/jackw/Roblox/RobloxGameVault"
local OUTPUT_PATH = VAULT_ROOT .. "/90_Automation/Generated/Sourcemap.md"

type SourcemapNode = {
	name: string,
	className: string?,
	filePaths: { string }?,
	children: { SourcemapNode }?,
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

local function markdownEscape(value: string): string
	return value:gsub("|", "\\|"):gsub("\n", " ")
end

local rows = {}

local function walk(node: SourcemapNode, studioPath: string)
	local className = node.className or ""
	local filePaths = node.filePaths or {}
	local joinedFiles = if #filePaths > 0 then table.concat(filePaths, "<br>") else ""

	table.insert(rows, {
		studioPath = studioPath,
		className = className,
		filePaths = joinedFiles,
	})

	for _, child in node.children or {} do
		walk(child, studioPath .. "." .. child.name)
	end
end

if not fs.isFile(SOURCEMAP_PATH) then
	error(
		"Missing sourcemap.json. Run `rojo sourcemap default.project.json -o sourcemap.json` first."
	)
end

if not fs.isDir(VAULT_ROOT) then
	error("Missing vault directory: " .. VAULT_ROOT)
end

local root = serde.decode("json", fs.readFile(SOURCEMAP_PATH)) :: SourcemapNode
walk(root, "game")

table.sort(rows, function(left, right)
	return left.studioPath < right.studioPath
end)

local timestamp = isoTimestamp()
local lines = {
	"---",
	"type: system",
	"status: active",
	"owner:",
	"source_path: C:\\Users\\jackw\\Roblox\\nexus\\sourcemap.json",
	"roblox_asset_id:",
	"studio_instance_path: game",
	"dependencies:",
	"last_synced: " .. timestamp,
	"tags:",
	"---",
	"",
	"# Sourcemap",
	"",
	"Generated: " .. timestamp,
	"",
	"| Studio Path | Class | File Paths |",
	"| --- | --- | --- |",
}

for _, row in rows do
	table.insert(
		lines,
		("| %s | %s | %s |"):format(
			markdownEscape(row.studioPath),
			markdownEscape(row.className),
			markdownEscape(row.filePaths)
		)
	)
end

ensureParent(OUTPUT_PATH)
fs.writeFile(OUTPUT_PATH, table.concat(lines, "\n") .. "\n")

print(("Wrote %d sourcemap rows to %s"):format(#rows, OUTPUT_PATH))
