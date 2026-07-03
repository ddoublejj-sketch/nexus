--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")

local VAULT_ROOT = "C:/Users/jackw/Roblox/RobloxGameVault"
local OUTPUT_PATH = VAULT_ROOT .. "/00_Command_Center/Human Gate Readiness.md"
local PENDING_ROOT = VAULT_ROOT .. "/90_Automation/Logs/pending"

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
			count += 1
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
	fileCheck("G2", "Rojo sync runbook", "docs/runbooks/rojo-sync-rules.md", "runbook present"),
	fileCheck(
		"G2",
		"Studio snapshot archive",
		VAULT_ROOT .. "/80_Archives/StudioSnapshots",
		"archive present"
	),
	fileCheck(
		"G3",
		"Obsidian REST config",
		"secrets/obsidian.env",
		"file exists; values not printed"
	),
	fileCheck(
		"G3",
		"Vault dashboard",
		VAULT_ROOT .. "/00_Command_Center/Dashboard.md",
		"dashboard present"
	),
	{
		gate = "G3",
		check = "Pending REST writes",
		status = if pendingCount() == 0 then "PASS" else "BLOCKED",
		detail = tostring(pendingCount()) .. " pending write(s)",
	},
	commandCheck("G4", "gh auth status", "gh", { "auth", "status" }),
	commandOutputRequired(
		"G4",
		"git remote -v",
		"git",
		{ "remote", "-v" },
		"no Git remote configured"
	),
	fileCheck(
		"G5",
		"Open Cloud config",
		"secrets/opencloud.env",
		"file exists; values not printed"
	),
	fileCheck("G5", "Open Cloud fixture", "tools/fixtures/opencloud.env", "fixture present"),
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
