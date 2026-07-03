--!strict

local fs = require("@lune/fs")
local net = require("@lune/net")
local serde = require("@lune/serde")

local VAULT_ROOT = "C:/Users/jackw/Roblox/RobloxGameVault"
local OBSIDIAN_ROOT = VAULT_ROOT .. "/.obsidian"
local PLUGIN_ROOT = OBSIDIAN_ROOT .. "/plugins"
local OUTPUT_PATH = VAULT_ROOT .. "/00_Command_Center/Obsidian Plugin Setup.md"

type Asset = {
	name: string,
	url: string,
}

type Plugin = {
	id: string,
	name: string,
	version: string,
	repository: string,
	assets: { Asset },
}

local PLUGINS: { Plugin } = {
	{
		id = "obsidian-local-rest-api",
		name = "Local REST API",
		version = "4.1.3",
		repository = "https://github.com/coddingtonbear/obsidian-local-rest-api",
		assets = {
			{
				name = "main.js",
				url = "https://github.com/coddingtonbear/obsidian-local-rest-api/releases/download/4.1.3/main.js",
			},
			{
				name = "manifest.json",
				url = "https://github.com/coddingtonbear/obsidian-local-rest-api/releases/download/4.1.3/manifest.json",
			},
			{
				name = "styles.css",
				url = "https://github.com/coddingtonbear/obsidian-local-rest-api/releases/download/4.1.3/styles.css",
			},
		},
	},
	{
		id = "obsidian-git",
		name = "Obsidian Git",
		version = "2.38.5",
		repository = "https://github.com/Vinzent03/obsidian-git",
		assets = {
			{
				name = "main.js",
				url = "https://github.com/Vinzent03/obsidian-git/releases/download/2.38.5/main.js",
			},
			{
				name = "manifest.json",
				url = "https://github.com/Vinzent03/obsidian-git/releases/download/2.38.5/manifest.json",
			},
			{
				name = "styles.css",
				url = "https://github.com/Vinzent03/obsidian-git/releases/download/2.38.5/styles.css",
			},
		},
	},
	{
		id = "dataview",
		name = "Dataview",
		version = "0.5.70",
		repository = "https://github.com/blacksmithgu/obsidian-dataview",
		assets = {
			{
				name = "main.js",
				url = "https://github.com/blacksmithgu/obsidian-dataview/releases/download/0.5.70/main.js",
			},
			{
				name = "manifest.json",
				url = "https://github.com/blacksmithgu/obsidian-dataview/releases/download/0.5.70/manifest.json",
			},
			{
				name = "styles.css",
				url = "https://github.com/blacksmithgu/obsidian-dataview/releases/download/0.5.70/styles.css",
			},
		},
	},
	{
		id = "obsidian-tasks-plugin",
		name = "Tasks",
		version = "8.2.2",
		repository = "https://github.com/obsidian-tasks-group/obsidian-tasks",
		assets = {
			{
				name = "main.js",
				url = "https://github.com/obsidian-tasks-group/obsidian-tasks/releases/download/8.2.2/main.js",
			},
			{
				name = "manifest.json",
				url = "https://github.com/obsidian-tasks-group/obsidian-tasks/releases/download/8.2.2/manifest.json",
			},
			{
				name = "styles.css",
				url = "https://github.com/obsidian-tasks-group/obsidian-tasks/releases/download/8.2.2/styles.css",
			},
		},
	},
	{
		id = "obsidian-kanban",
		name = "Kanban",
		version = "2.0.51",
		repository = "https://github.com/obsidian-community/obsidian-kanban",
		assets = {
			{
				name = "main.js",
				url = "https://github.com/obsidian-community/obsidian-kanban/releases/download/2.0.51/main.js",
			},
			{
				name = "manifest.json",
				url = "https://github.com/obsidian-community/obsidian-kanban/releases/download/2.0.51/manifest.json",
			},
			{
				name = "styles.css",
				url = "https://github.com/obsidian-community/obsidian-kanban/releases/download/2.0.51/styles.css",
			},
		},
	},
	{
		id = "templater-obsidian",
		name = "Templater",
		version = "2.23.0",
		repository = "https://github.com/SilentVoid13/Templater",
		assets = {
			{
				name = "main.js",
				url = "https://github.com/SilentVoid13/Templater/releases/download/2.23.0/main.js",
			},
			{
				name = "manifest.json",
				url = "https://github.com/SilentVoid13/Templater/releases/download/2.23.0/manifest.json",
			},
			{
				name = "styles.css",
				url = "https://github.com/SilentVoid13/Templater/releases/download/2.23.0/styles.css",
			},
		},
	},
	{
		id = "quickadd",
		name = "QuickAdd",
		version = "2.14.1",
		repository = "https://github.com/chhoumann/quickadd",
		assets = {
			{
				name = "main.js",
				url = "https://github.com/chhoumann/quickadd/releases/download/2.14.1/main.js",
			},
			{
				name = "manifest.json",
				url = "https://github.com/chhoumann/quickadd/releases/download/2.14.1/manifest.json",
			},
			{
				name = "styles.css",
				url = "https://github.com/chhoumann/quickadd/releases/download/2.14.1/styles.css",
			},
		},
	},
	{
		id = "omnisearch",
		name = "Omnisearch",
		version = "1.29.3",
		repository = "https://github.com/scambier/obsidian-omnisearch",
		assets = {
			{
				name = "main.js",
				url = "https://github.com/scambier/obsidian-omnisearch/releases/download/1.29.3/main.js",
			},
			{
				name = "manifest.json",
				url = "https://github.com/scambier/obsidian-omnisearch/releases/download/1.29.3/manifest.json",
			},
			{
				name = "styles.css",
				url = "https://github.com/scambier/obsidian-omnisearch/releases/download/1.29.3/styles.css",
			},
		},
	},
}

local function isoTimestamp(): string
	return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

local function ensureDir(path: string)
	if not fs.isDir(path) then
		fs.writeDir(path)
	end
end

local function readJsonArray(path: string): { string }
	if not fs.isFile(path) then
		return {}
	end

	local ok, decoded = pcall(function()
		return serde.decode("json", fs.readFile(path))
	end)

	if not ok or type(decoded) ~= "table" then
		return {}
	end

	return decoded :: { string }
end

local function contains(list: { string }, value: string): boolean
	for _, item in list do
		if item == value then
			return true
		end
	end

	return false
end

local function writeJson(path: string, value: any)
	fs.writeFile(path, serde.encode("json", value, true) .. "\n")
end

local function downloadAsset(url: string): string
	local response = net.request({
		url = url,
		method = "GET",
		headers = {
			["User-Agent"] = "nexus-command-center",
		},
	})

	if not response.ok then
		error(
			("Failed to download %s: %d %s"):format(
				url,
				response.statusCode,
				response.statusMessage
			)
		)
	end

	return response.body
end

local function installPlugin(plugin: Plugin): { string }
	local pluginPath = PLUGIN_ROOT .. "/" .. plugin.id
	ensureDir(pluginPath)

	local installed = {}
	for _, asset in plugin.assets do
		local targetPath = pluginPath .. "/" .. asset.name
		if not fs.isFile(targetPath) then
			fs.writeFile(targetPath, downloadAsset(asset.url))
		end
		table.insert(installed, asset.name)
	end

	local manifestPath = pluginPath .. "/manifest.json"
	if not fs.isFile(manifestPath) then
		error("Missing manifest for " .. plugin.id)
	end

	local manifest = serde.decode("json", fs.readFile(manifestPath)) :: any
	if manifest.id ~= plugin.id then
		error(("Manifest id mismatch for %s: got %s"):format(plugin.id, tostring(manifest.id)))
	end

	return installed
end

local function writeEnablement()
	local enabled = readJsonArray(OBSIDIAN_ROOT .. "/community-plugins.json")
	for _, plugin in PLUGINS do
		if not contains(enabled, plugin.id) then
			table.insert(enabled, plugin.id)
		end
	end
	table.sort(enabled)
	writeJson(OBSIDIAN_ROOT .. "/community-plugins.json", enabled)

	if not fs.isFile(OBSIDIAN_ROOT .. "/app.json") then
		writeJson(OBSIDIAN_ROOT .. "/app.json", {
			promptDelete = false,
		})
	end

	if not fs.isFile(OBSIDIAN_ROOT .. "/appearance.json") then
		writeJson(OBSIDIAN_ROOT .. "/appearance.json", {})
	end
end

local function writeEvidence(timestamp: string)
	local lines = {
		"---",
		"type: system",
		"status: active",
		"owner:",
		"source_path: C:\\Users\\jackw\\Roblox\\nexus\\tools\\obsidian_plugin_setup.luau",
		"roblox_asset_id:",
		"studio_instance_path:",
		"dependencies:",
		"last_synced: " .. timestamp,
		"tags: gates, g3, obsidian",
		"---",
		"",
		"# Obsidian Plugin Setup",
		"",
		"Generated: " .. timestamp,
		"",
		"This note records the local vault plugin preinstall. Plugin bundle files live in `.obsidian/plugins/` and are intentionally ignored by Git; no API key or plugin secret is recorded here.",
		"",
		"| Plugin | Version | Vault Plugin ID | Source |",
		"| --- | --- | --- | --- |",
	}

	for _, plugin in PLUGINS do
		table.insert(
			lines,
			("| %s | %s | `%s` | %s |"):format(
				plugin.name,
				plugin.version,
				plugin.id,
				plugin.repository
			)
		)
	end

	table.insert(lines, "")
	table.insert(lines, "## Remaining G3 Human Proof")
	table.insert(lines, "")
	table.insert(lines, "- Open the vault in Obsidian so the enabled plugins load.")
	table.insert(
		lines,
		"- Copy the Local REST API key into `secrets/obsidian.env` without committing it."
	)
	table.insert(
		lines,
		"- Confirm the dashboard renders Dataview and Tasks sections, then mark the G3 receipt only after that visual check is real."
	)

	fs.writeFile(OUTPUT_PATH, table.concat(lines, "\n") .. "\n")
end

if not fs.isDir(VAULT_ROOT) then
	error("Missing vault directory: " .. VAULT_ROOT)
end

ensureDir(OBSIDIAN_ROOT)
ensureDir(PLUGIN_ROOT)

local timestamp = isoTimestamp()
for _, plugin in PLUGINS do
	local assets = installPlugin(plugin)
	print(("Installed %s %s (%s)"):format(plugin.name, plugin.version, table.concat(assets, ", ")))
end

writeEnablement()
writeEvidence(timestamp)
print("Enabled " .. tostring(#PLUGINS) .. " Obsidian plugins in .obsidian/community-plugins.json")
print("Wrote Obsidian plugin setup evidence to " .. OUTPUT_PATH)
