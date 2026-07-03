--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")

local VAULT_ROOT = "C:/Users/jackw/Roblox/RobloxGameVault"
local PENDING_ROOT = VAULT_ROOT .. "/90_Automation/Logs/pending"
local SENT_ROOT = VAULT_ROOT .. "/90_Automation/Logs/sent"
local RECEIPT_ROOT = "docs/gate-proofs"

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

type Options = {
	selfTest: boolean,
	gates: { [string]: boolean },
}

type Check = {
	gate: string,
	name: string,
	status: string,
	detail: string,
}

local VALID_GATES = {
	G1 = true,
	G2 = true,
	G3 = true,
	G4 = true,
	G5 = true,
}

local function oneLine(value: string): string
	local normalized = value:gsub("\r", "\n"):gsub("\n+", " "):gsub("|", "\\|")
	normalized = normalized:match("^%s*(.-)%s*$") or ""
	if #normalized > 120 then
		return normalized:sub(1, 117) .. "..."
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

local function usage(): string
	return table.concat({
		"Usage: lune run tools/human_gate_acceptance.luau [--gate G1] [--self-test]",
		"",
		"Default mode exits non-zero until selected gates are fully accepted.",
		"`--self-test` verifies the probe can run without claiming blocked gates are complete.",
	}, "\n")
end

local function parseArgs(args: { string }): Options
	local options: Options = {
		selfTest = false,
		gates = {},
	}

	local index = 1
	while index <= #args do
		local arg = args[index]
		if arg == "--help" or arg == "-h" then
			print(usage())
			process.exit(0)
		elseif arg == "--self-test" then
			options.selfTest = true
		elseif arg == "--gate" then
			index += 1
			if index > #args then
				error("--gate requires G1, G2, G3, G4, or G5")
			end
			local gate = args[index]:upper()
			if not VALID_GATES[gate] then
				error("Unknown gate " .. args[index])
			end
			options.gates[gate] = true
		elseif arg:match("^%-%-gate=") then
			local gate = arg:gsub("^%-%-gate=", ""):upper()
			if not VALID_GATES[gate] then
				error("Unknown gate " .. gate)
			end
			options.gates[gate] = true
		else
			error("Unknown argument " .. arg .. "\n" .. usage())
		end
		index += 1
	end

	if next(options.gates) == nil then
		for gate in VALID_GATES do
			options.gates[gate] = true
		end
	end

	return options
end

local function commandCheck(gate: string, name: string, command: string, args: { string }): Check
	local ok, result = pcall(function()
		return process.exec(command, args)
	end)

	if not ok then
		local detail = oneLine(tostring(result))
		if detail:find("program not found", 1, true) then
			detail = "program not found"
		end
		return { gate = gate, name = name, status = "FAIL", detail = detail }
	end

	local execResult = result :: any
	local output = oneLine((execResult.stdout or "") .. " " .. (execResult.stderr or ""))
	return {
		gate = gate,
		name = name,
		status = if execResult.ok then "PASS" else "FAIL",
		detail = if output ~= "" then output else "exit " .. tostring(execResult.code),
	}
end

local function powershellCommandCheck(gate: string, name: string, commandLine: string): Check
	return commandCheck(gate, name, "powershell.exe", {
		"-NoProfile",
		"-Command",
		commandLine,
	})
end

local function commandOutputRequired(
	gate: string,
	name: string,
	command: string,
	args: { string },
	missingDetail: string
): Check
	local check = commandCheck(gate, name, command, args)
	if check.status == "PASS" and check.detail == "exit 0" then
		check.status = "FAIL"
		check.detail = missingDetail
	end
	return check
end

local function fileCheck(gate: string, name: string, path: string, presentDetail: string): Check
	local present = fs.isFile(path) or fs.isDir(path)
	return {
		gate = gate,
		name = name,
		status = if present then "PASS" else "FAIL",
		detail = if present then presentDetail else path,
	}
end

local function obsidianRestConfigCheck(): Check
	local path = "secrets/obsidian.env"
	if not fs.isFile(path) then
		return {
			gate = "G3",
			name = "Obsidian REST config present",
			status = "FAIL",
			detail = path,
		}
	end

	local values = readEnvFile(path)
	local apiUrl = values.OBSIDIAN_API_URL or ""
	local apiKey = values.OBSIDIAN_API_KEY or ""

	if not apiUrl:match("^https?://") then
		return {
			gate = "G3",
			name = "Obsidian REST config present",
			status = "FAIL",
			detail = "OBSIDIAN_API_URL missing or invalid; values not printed",
		}
	end

	if looksPlaceholder(apiKey) then
		return {
			gate = "G3",
			name = "Obsidian REST config present",
			status = "FAIL",
			detail = "OBSIDIAN_API_KEY missing or placeholder; values not printed",
		}
	end

	return {
		gate = "G3",
		name = "Obsidian REST config present",
		status = "PASS",
		detail = "required keys present; values not printed",
	}
end

local function openCloudConfigCheck(): Check
	local path = "secrets/opencloud.env"
	if not fs.isFile(path) then
		return {
			gate = "G5",
			name = "Open Cloud config present",
			status = "FAIL",
			detail = path,
		}
	end

	local values = readEnvFile(path)
	if looksPlaceholder(values.OPEN_CLOUD_API_KEY or "") then
		return {
			gate = "G5",
			name = "Open Cloud config present",
			status = "FAIL",
			detail = "OPEN_CLOUD_API_KEY missing or placeholder; values not printed",
		}
	end

	if not numericIdOk(values.ROBLOX_UNIVERSE_ID or "") then
		return {
			gate = "G5",
			name = "Open Cloud config present",
			status = "FAIL",
			detail = "ROBLOX_UNIVERSE_ID missing or invalid; values not printed",
		}
	end

	if not numericIdOk(values.ROBLOX_PLACE_ID or "") then
		return {
			gate = "G5",
			name = "Open Cloud config present",
			status = "FAIL",
			detail = "ROBLOX_PLACE_ID missing or invalid; values not printed",
		}
	end

	return {
		gate = "G5",
		name = "Open Cloud config present",
		status = "PASS",
		detail = "required keys present; values not printed",
	}
end

local function receiptCheck(gate: string, name: string, receiptPath: string, marker: string): Check
	if not fs.isFile(receiptPath) then
		return {
			gate = gate,
			name = name,
			status = "NEEDS HUMAN",
			detail = "missing receipt: " .. receiptPath,
		}
	end

	local contents = fs.readFile(receiptPath)
	if contents:find(marker .. ": PASS", 1, true) then
		return {
			gate = gate,
			name = name,
			status = "PASS",
			detail = "accepted by " .. receiptPath,
		}
	end

	return {
		gate = gate,
		name = name,
		status = "NEEDS HUMAN",
		detail = "receipt pending: " .. receiptPath .. " needs `" .. marker .. ": PASS`",
	}
end

local function pathCommandCheck(gate: string, name: string, command: string): Check
	return commandOutputRequired(gate, name, "powershell.exe", {
		"-NoProfile",
		"-Command",
		("(Get-Command %s -ErrorAction SilentlyContinue).Source"):format(command),
	}, command .. " not found on PATH")
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

local function pendingCheck(): Check
	local count = pendingCount()
	return {
		gate = "G3",
		name = "pending Obsidian REST writes flushed",
		status = if count == 0 then "PASS" else "FAIL",
		detail = tostring(count) .. " pending write(s)",
	}
end

local function obsidianPluginSetupCheck(): Check
	local enabledPath = VAULT_ROOT .. "/.obsidian/community-plugins.json"
	if not fs.isFile(enabledPath) then
		return {
			gate = "G3",
			name = "Obsidian plugins preinstalled and enabled",
			status = "FAIL",
			detail = ".obsidian/community-plugins.json",
		}
	end

	local enabled = fs.readFile(enabledPath)
	for _, pluginId in REQUIRED_OBSIDIAN_PLUGINS do
		if not enabled:find('"' .. pluginId .. '"', 1, true) then
			return {
				gate = "G3",
				name = "Obsidian plugins preinstalled and enabled",
				status = "FAIL",
				detail = "missing enabled plugin " .. pluginId,
			}
		end

		local pluginPath = VAULT_ROOT .. "/.obsidian/plugins/" .. pluginId
		for _, asset in { "main.js", "manifest.json", "styles.css" } do
			if not fs.isFile(pluginPath .. "/" .. asset) then
				return {
					gate = "G3",
					name = "Obsidian plugins preinstalled and enabled",
					status = "FAIL",
					detail = "missing " .. pluginId .. "/" .. asset,
				}
			end
		end
	end

	return {
		gate = "G3",
		name = "Obsidian plugins preinstalled and enabled",
		status = "PASS",
		detail = tostring(#REQUIRED_OBSIDIAN_PLUGINS) .. " plugin(s) ready",
	}
end

local function allChecks(): { Check }
	return {
		commandCheck("G1", "git available", "git", { "--version" }),
		commandCheck("G1", "rokit available", "rokit", { "--version" }),
		commandCheck("G1", "rojo available", "rojo", { "--version" }),
		powershellCommandCheck("G1", "code available", "code --version"),
		powershellCommandCheck("G1", "gh available", "gh --version"),
		pathCommandCheck("G1", "blender CLI available", "blender"),
		pathCommandCheck("G1", "obsidian command available", "obsidian"),
		receiptCheck(
			"G2",
			"Studio plugin connected",
			RECEIPT_ROOT .. "/G2-studio-connect.md",
			"Studio plugin connected"
		),
		receiptCheck(
			"G2",
			"Studio playtest observed",
			RECEIPT_ROOT .. "/G2-studio-connect.md",
			"Studio playtest observed"
		),
		fileCheck(
			"G2",
			"Rojo sync runbook present",
			"docs/runbooks/rojo-sync-rules.md",
			"runbook present"
		),
		obsidianRestConfigCheck(),
		obsidianPluginSetupCheck(),
		pendingCheck(),
		receiptCheck(
			"G3",
			"Dashboard rendered in Obsidian",
			RECEIPT_ROOT .. "/G3-obsidian-dashboard.md",
			"Dashboard rendered in Obsidian"
		),
		commandCheck("G4", "GitHub auth active", "gh", { "auth", "status" }),
		commandOutputRequired(
			"G4",
			"Git remote configured",
			"git",
			{ "remote", "-v" },
			"no remote"
		),
		receiptCheck(
			"G4",
			"CI branch protection confirmed",
			RECEIPT_ROOT .. "/G4-github-ci.md",
			"CI branch protection confirmed"
		),
		openCloudConfigCheck(),
		fileCheck("G5", "Build artifact present", "build/nexus.rbxl", "build artifact present"),
		receiptCheck(
			"G5",
			"Live publish approval recorded",
			RECEIPT_ROOT .. "/G5-open-cloud-publish.md",
			"Live publish approval recorded"
		),
	}
end

local options = parseArgs(process.args)
local selected = {}
local failed = 0
local blocked = 0

for _, check in allChecks() do
	if options.gates[check.gate] then
		table.insert(selected, check)
		if check.status == "FAIL" or check.status == "NEEDS HUMAN" then
			blocked += 1
		end
	end
end

print("| Gate | Check | Status | Detail |")
print("| --- | --- | --- | --- |")
for _, check in selected do
	print(
		("| %s | %s | %s | %s |"):format(
			check.gate,
			oneLine(check.name),
			check.status,
			oneLine(check.detail)
		)
	)
	if check.status == "FAIL" or check.status == "NEEDS HUMAN" then
		failed += 1
	end
end

if options.selfTest then
	if #selected == 0 then
		error("self-test selected no checks")
	end
	print(
		("Human gate acceptance probe self-test PASS; current blocked checks: %d"):format(blocked)
	)
	process.exit(0)
end

if failed > 0 then
	print(("Human gate acceptance BLOCKED: %d check(s) are not accepted."):format(failed))
	process.exit(1)
end

print("Human gate acceptance PASS")
