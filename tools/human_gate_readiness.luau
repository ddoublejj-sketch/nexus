--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")

local VAULT_ROOT = "C:/Users/jackw/Roblox/RobloxGameVault"
local OUTPUT_PATH = VAULT_ROOT .. "/00_Command_Center/Human Gate Readiness.md"
local PENDING_ROOT = VAULT_ROOT .. "/90_Automation/Logs/pending"
local SENT_ROOT = VAULT_ROOT .. "/90_Automation/Logs/sent"
local COMMAND_CENTER_ROOT = VAULT_ROOT .. "/00_Command_Center"

local REQUIRED_OBSIDIAN_PLUGINS = {
	"obsidian-local-rest-api",
	"obsidian-git",
	"dataview",
	"obsidian-tasks-plugin",
	"obsidian-kanban",
	"templater-obsidian",
	"quickadd",
	"omnisearch",
}

type CheckRow = {
	gate: string,
	check: string,
	status: string,
	detail: string,
}

local function isoTimestamp(): string
	return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

local function oneLine(value: string): string
	local normalized = value:gsub("\r", "\n"):gsub("\n+", " "):gsub("|", "\\|")
	normalized = normalized:match("^%s*(.-)%s*$") or ""
	if #normalized > 140 then
		return normalized:sub(1, 137) .. "..."
	end

	return normalized
end

local function trim(value: string): string
	return value:match("^%s*(.-)%s*$") or ""
end

local function stripEnvQuotes(value: string): string
	local trimmed = trim(value)
	if #trimmed >= 2 then
		local first = trimmed:sub(1, 1)
		local last = trimmed:sub(-1)
		if (first == '"' and last == '"') or (first == "'" and last == "'") then
			return trimmed:sub(2, -2)
		end
	end

	return trimmed
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
				values[key] = stripEnvQuotes(value)
			end
		end
	end

	return values
end

local function looksPlaceholder(value: string): boolean
	local lower = value:lower()
	return lower == ""
		or lower:find("replace", 1, true) ~= nil
		or lower:find("fixture", 1, true) ~= nil
		or lower:find("placeholder", 1, true) ~= nil
		or lower:find("do_not_use", 1, true) ~= nil
end

local function numericIdOk(value: string): boolean
	return value:match("^%d+$") ~= nil and value:match("^0+$") == nil
end

local function commandCheck(
	gate: string,
	label: string,
	command: string,
	args: { string }
): CheckRow
	local ok, result = pcall(function()
		return process.exec(command, args)
	end)

	if not ok then
		local detail = oneLine(tostring(result))
		if detail:find("program not found", 1, true) then
			detail = "program not found"
		end

		return {
			gate = gate,
			check = label,
			status = "MISSING",
			detail = detail,
		}
	end

	local execResult = result :: any
	local output = oneLine((execResult.stdout or "") .. " " .. (execResult.stderr or ""))
	return {
		gate = gate,
		check = label,
		status = if execResult.ok then "PASS" else "BLOCKED",
		detail = if output ~= "" then output else "exit " .. tostring(execResult.code),
	}
end

local function powershellCommandCheck(gate: string, label: string, commandLine: string): CheckRow
	return commandCheck(gate, label, "powershell.exe", {
		"-NoProfile",
		"-Command",
		commandLine,
	})
end

local function commandOutputRequired(
	gate: string,
	label: string,
	command: string,
	args: { string },
	missingDetail: string
): CheckRow
	local row = commandCheck(gate, label, command, args)
	if row.status == "PASS" and row.detail == "exit 0" then
		row.status = "MISSING"
		row.detail = missingDetail
	end

	return row
end

local function fileCheck(gate: string, label: string, path: string, presentDetail: string): CheckRow
	local present = fs.isFile(path) or fs.isDir(path)
	return {
		gate = gate,
		check = label,
		status = if present then "PASS" else "MISSING",
		detail = if present then presentDetail else path,
	}
end

local function obsidianRestConfigCheck(): CheckRow
	local path = "secrets/obsidian.env"
	if not fs.isFile(path) then
		return {
			gate = "G3",
			check = "Obsidian REST config",
			status = "MISSING",
			detail = path,
		}
	end

	local values = readEnvFile(path)
	local apiUrl = values.OBSIDIAN_API_URL or ""
	local apiKey = values.OBSIDIAN_API_KEY or ""

	if not apiUrl:match("^https?://") then
		return {
			gate = "G3",
			check = "Obsidian REST config",
			status = "BLOCKED",
			detail = "OBSIDIAN_API_URL missing or invalid; values not printed",
		}
	end

	if looksPlaceholder(apiKey) then
		return {
			gate = "G3",
			check = "Obsidian REST config",
			status = "BLOCKED",
			detail = "OBSIDIAN_API_KEY missing or placeholder; values not printed",
		}
	end

	return {
		gate = "G3",
		check = "Obsidian REST config",
		status = "PASS",
		detail = "required keys present; values not printed",
	}
end

local function openCloudConfigCheck(): CheckRow
	local path = "secrets/opencloud.env"
	if not fs.isFile(path) then
		return {
			gate = "G5",
			check = "Open Cloud config",
			status = "MISSING",
			detail = path,
		}
	end

	local values = readEnvFile(path)
	if looksPlaceholder(values.OPEN_CLOUD_API_KEY or "") then
		return {
			gate = "G5",
			check = "Open Cloud config",
			status = "BLOCKED",
			detail = "OPEN_CLOUD_API_KEY missing or placeholder; values not printed",
		}
	end

	if not numericIdOk(values.ROBLOX_UNIVERSE_ID or "") then
		return {
			gate = "G5",
			check = "Open Cloud config",
			status = "BLOCKED",
			detail = "ROBLOX_UNIVERSE_ID missing or invalid; values not printed",
		}
	end

	if not numericIdOk(values.ROBLOX_PLACE_ID or "") then
		return {
			gate = "G5",
			check = "Open Cloud config",
			status = "BLOCKED",
			detail = "ROBLOX_PLACE_ID missing or invalid; values not printed",
		}
	end

	return {
		gate = "G5",
		check = "Open Cloud config",
		status = "PASS",
		detail = "required keys present; values not printed",
	}
end

local function humanCheck(gate: string, label: string, detail: string): CheckRow
	return {
		gate = gate,
		check = label,
		status = "NEEDS HUMAN",
		detail = detail,
	}
end

local function pendingCount(): number
	if not fs.isDir(PENDING_ROOT) then
		return 0
	end

	local count = 0
	for _, entry in fs.readDir(PENDING_ROOT) do
		if entry:match("%.pending$") then
			local sentPath = SENT_ROOT .. "/" .. entry:gsub("%.pending$", ".sent")
			if not fs.isFile(sentPath) then
				count += 1
			end
		end
	end

	return count
end

local function commandSource(label: string, command: string): CheckRow
	return commandOutputRequired("G1", label, "powershell.exe", {
		"-NoProfile",
		"-Command",
		("(Get-Command %s -ErrorAction SilentlyContinue).Source"):format(command),
	}, command .. " not found on PATH")
end

local function obsidianPluginSetupCheck(): CheckRow
	local enabledPath = VAULT_ROOT .. "/.obsidian/community-plugins.json"
	if not fs.isFile(enabledPath) then
		return {
			gate = "G3",
			check = "Obsidian plugins preinstalled",
			status = "MISSING",
			detail = ".obsidian/community-plugins.json",
		}
	end

	local enabled = fs.readFile(enabledPath)
	for _, pluginId in REQUIRED_OBSIDIAN_PLUGINS do
		if not enabled:find('"' .. pluginId .. '"', 1, true) then
			return {
				gate = "G3",
				check = "Obsidian plugins preinstalled",
				status = "MISSING",
				detail = "missing enabled plugin " .. pluginId,
			}
		end

		local pluginPath = VAULT_ROOT .. "/.obsidian/plugins/" .. pluginId
		for _, asset in { "main.js", "manifest.json", "styles.css" } do
			if not fs.isFile(pluginPath .. "/" .. asset) then
				return {
					gate = "G3",
					check = "Obsidian plugins preinstalled",
					status = "MISSING",
					detail = "missing " .. pluginId .. "/" .. asset,
				}
			end
		end
	end

	return {
		gate = "G3",
		check = "Obsidian plugins preinstalled",
		status = "PASS",
		detail = tostring(#REQUIRED_OBSIDIAN_PLUGINS) .. " plugin(s) ready",
	}
end

local rows: { CheckRow } = {
	commandCheck("G1", "git --version", "git", { "--version" }),
	commandCheck("G1", "rokit --version", "rokit", { "--version" }),
	commandCheck("G1", "rojo --version", "rojo", { "--version" }),
	powershellCommandCheck("G1", "code --version", "code --version"),
	powershellCommandCheck("G1", "gh --version", "gh --version"),
	commandSource("blender command", "blender"),
	commandSource("obsidian command", "obsidian"),
	humanCheck(
		"G2",
		"Studio plugin connected",
		"Requires Roblox Studio and Rojo plugin confirmation."
	),
	fileCheck(
		"G2",
		"Studio bridge bootstrap",
		COMMAND_CENTER_ROOT .. "/Studio Bridge Bootstrap.md",
		"bootstrap evidence present"
	),
	fileCheck("G2", "Rojo sync runbook", "docs/runbooks/rojo-sync-rules.md", "runbook present"),
	fileCheck(
		"G2",
		"Studio snapshot archive",
		VAULT_ROOT .. "/80_Archives/StudioSnapshots",
		"archive present"
	),
	obsidianRestConfigCheck(),
	fileCheck(
		"G3",
		"Vault dashboard",
		VAULT_ROOT .. "/00_Command_Center/Dashboard.md",
		"dashboard present"
	),
	fileCheck(
		"G3",
		"Obsidian REST bootstrap",
		COMMAND_CENTER_ROOT .. "/Obsidian REST Bootstrap.md",
		"bootstrap evidence present"
	),
	obsidianPluginSetupCheck(),
	{
		gate = "G3",
		check = "Pending REST writes",
		status = if pendingCount() == 0 then "PASS" else "BLOCKED",
		detail = tostring(pendingCount()) .. " pending write(s)",
	},
	commandCheck("G4", "gh auth status", "gh", { "auth", "status" }),
	fileCheck(
		"G4",
		"GitHub CI bootstrap",
		COMMAND_CENTER_ROOT .. "/GitHub CI Bootstrap.md",
		"bootstrap evidence present"
	),
	commandOutputRequired(
		"G4",
		"git remote -v",
		"git",
		{ "remote", "-v" },
		"no Git remote configured"
	),
	openCloudConfigCheck(),
	fileCheck("G5", "Open Cloud fixture", "tools/fixtures/opencloud.env", "fixture present"),
	fileCheck(
		"G5",
		"Open Cloud bootstrap",
		COMMAND_CENTER_ROOT .. "/Open Cloud Bootstrap.md",
		"bootstrap evidence present"
	),
	fileCheck("G5", "Build artifact", "build/nexus.rbxl", "build artifact present"),
	humanCheck(
		"G5",
		"Live publish approval",
		"Requires explicit human approval and real Open Cloud key."
	),
}

local timestamp = isoTimestamp()
local lines = {
	"---",
	"type: system",
	"status: active",
	"owner:",
	"source_path: C:\\Users\\jackw\\Roblox\\nexus\\tools\\human_gate_readiness.luau",
	"roblox_asset_id:",
	"studio_instance_path:",
	"dependencies:",
	"last_synced: " .. timestamp,
	"tags: gates, readiness",
	"---",
	"",
	"# Human Gate Readiness",
	"",
	"Generated: " .. timestamp,
	"",
	"This note is an automatic audit. `PASS` means Codex can verify the item from this shell; `MISSING`, `BLOCKED`, and `NEEDS HUMAN` are not completion states.",
	"",
	"To enforce gate acceptance after a human action, run `./nexus.ps1 gatecheck --gate G1` through `./nexus.ps1 gatecheck --gate G5`. To verify the probe itself without claiming completion, run `./nexus.ps1 gatecheck --self-test`.",
	"",
	"| Gate | Check | Status | Detail |",
	"| --- | --- | --- | --- |",
}

for _, row in rows do
	table.insert(
		lines,
		("| %s | %s | %s | %s |"):format(
			row.gate,
			oneLine(row.check),
			row.status,
			oneLine(row.detail)
		)
	)
end

fs.writeFile(OUTPUT_PATH, table.concat(lines, "\n") .. "\n")
print("Wrote human gate readiness to " .. OUTPUT_PATH)
