--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")

local VAULT_ROOT = "C:/Users/jackw/Roblox/RobloxGameVault"
local OUTPUT_PATH = VAULT_ROOT .. "/00_Command_Center/Studio Bridge Bootstrap.md"
local RUNBOOK_PATH = "docs/runbooks/rojo-sync-rules.md"
local RECEIPT_PATH = "docs/gate-proofs/G2-studio-connect.md"
local PROJECT_PATH = "default.project.json"
local SOURCEMAP_PATH = "sourcemap.json"
local SNAPSHOT_ROOT = VAULT_ROOT .. "/80_Archives/StudioSnapshots"
local ROJO_SERVER_URL = "http://127.0.0.1:34872/"

type Check = {
	state: string,
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

local function runPowerShell(commandLine: string): Check
	local ok, result = pcall(function()
		return process.exec("powershell.exe", {
			"-NoProfile",
			"-Command",
			commandLine,
		})
	end)

	if not ok then
		return {
			state = "WAITING",
			detail = oneLine(tostring(result)),
		}
	end

	local execResult = result :: any
	local output = oneLine((execResult.stdout or "") .. " " .. (execResult.stderr or ""))
	return {
		state = if execResult.ok then "PASS" else "WAITING",
		detail = if output ~= "" then output else "exit " .. tostring(execResult.code),
	}
end

local function fileCheck(path: string, presentDetail: string): Check
	return {
		state = if fs.isFile(path) or fs.isDir(path) then "PASS" else "MISSING",
		detail = if fs.isFile(path) or fs.isDir(path) then presentDetail else path,
	}
end

local function sourcemapCheck(): Check
	if not fs.isFile(SOURCEMAP_PATH) then
		return {
			state = "MISSING",
			detail = SOURCEMAP_PATH,
		}
	end

	local contents = fs.readFile(SOURCEMAP_PATH)
	if not contents:find('"name":"Nexus"', 1, true) then
		return {
			state = "STALE",
			detail = "sourcemap exists but does not name Nexus",
		}
	end

	return {
		state = "PASS",
		detail = "Nexus sourcemap present",
	}
end

local function rojoServerCheck(): Check
	return runPowerShell(
		"try { "
			.. "(Invoke-WebRequest -UseBasicParsing -TimeoutSec 2 -Uri '"
			.. ROJO_SERVER_URL
			.. "').StatusCode; exit 0 "
			.. "} catch { Write-Output 'Rojo server not reachable on 127.0.0.1:34872'; exit 1 }"
	)
end

local function studioProcessCheck(): Check
	return runPowerShell(
		"$p = Get-Process RobloxStudioBeta -ErrorAction SilentlyContinue | Select-Object -First 1; "
			.. "if ($p) { Write-Output ('Roblox Studio running pid ' + $p.Id); exit 0 } "
			.. "else { Write-Output 'Roblox Studio process not running'; exit 1 }"
	)
end

local function receiptCheck(): Check
	if not fs.isFile(RECEIPT_PATH) then
		return {
			state = "NEEDS HUMAN",
			detail = "missing receipt: " .. RECEIPT_PATH,
		}
	end

	local contents = fs.readFile(RECEIPT_PATH)
	local connected = contents:find("Studio plugin connected: PASS", 1, true) ~= nil
	local playtest = contents:find("Studio playtest observed: PASS", 1, true) ~= nil
	if connected and playtest then
		return {
			state = "PASS",
			detail = "accepted by " .. RECEIPT_PATH,
		}
	end

	return {
		state = "NEEDS HUMAN",
		detail = "receipt needs Studio plugin connected/playtest PASS markers",
	}
end

local function nextAction(rojo: Check, studio: Check, receipt: Check): string
	if rojo.state ~= "PASS" then
		return "- Run `./nexus.ps1 up`, then re-run `./nexus.ps1 studio-bridge` before opening the Rojo plugin."
	end

	if studio.state ~= "PASS" then
		return "- Open Roblox Studio, open the Nexus place, connect the Rojo plugin to `127.0.0.1:34872`, then re-run this helper."
	end

	if receipt.state ~= "PASS" then
		return "- Confirm a disk edit syncs into Studio, run the playtest, then mark the G2 receipt markers as `PASS`."
	end

	return "- G2 evidence is locally ready. Run `./nexus.ps1 gatecheck --gate G2`."
end

local function writeEvidence(
	timestamp: string,
	project: Check,
	sourcemap: Check,
	runbook: Check,
	snapshot: Check,
	rojo: Check,
	studio: Check,
	receipt: Check
)
	local lines = {
		"---",
		"type: system",
		"status: active",
		"owner:",
		"source_path: C:\\Users\\jackw\\Roblox\\nexus\\tools\\studio_bridge_bootstrap.luau",
		"roblox_asset_id:",
		"studio_instance_path:",
		"dependencies:",
		"last_synced: " .. timestamp,
		"tags: gates, g2, studio, rojo",
		"---",
		"",
		"# Studio Bridge Bootstrap",
		"",
		"Generated: " .. timestamp,
		"",
		"This note records local machine readiness for G2. It does not replace the human Studio plugin and playtest receipt.",
		"",
		"| Item | State | Detail |",
		"| --- | --- | --- |",
		"| Rojo project | " .. project.state .. " | " .. project.detail .. " |",
		"| Sourcemap | " .. sourcemap.state .. " | " .. sourcemap.detail .. " |",
		"| Sync runbook | " .. runbook.state .. " | " .. runbook.detail .. " |",
		"| Studio snapshot archive | " .. snapshot.state .. " | " .. snapshot.detail .. " |",
		"| Rojo local server | " .. rojo.state .. " | " .. rojo.detail .. " |",
		"| Roblox Studio process | " .. studio.state .. " | " .. studio.detail .. " |",
		"| G2 human receipt | " .. receipt.state .. " | " .. receipt.detail .. " |",
		"",
		"## Next Action",
		"",
		nextAction(rojo, studio, receipt),
		"",
		"After Studio plugin connect and playtest proof are real, update the G2 receipt and run `./nexus.ps1 gatecheck --gate G2`.",
	}

	fs.writeFile(OUTPUT_PATH, table.concat(lines, "\n") .. "\n")
end

if not fs.isDir(VAULT_ROOT) then
	error("Missing vault directory: " .. VAULT_ROOT)
end

local project = fileCheck(PROJECT_PATH, "Rojo project present")
local sourcemap = sourcemapCheck()
local runbook = fileCheck(RUNBOOK_PATH, "sync runbook present")
local snapshot = fileCheck(SNAPSHOT_ROOT, "snapshot archive present")
local rojo = rojoServerCheck()
local studio = studioProcessCheck()
local receipt = receiptCheck()

writeEvidence(isoTimestamp(), project, sourcemap, runbook, snapshot, rojo, studio, receipt)

print("Rojo project: " .. project.state)
print("Sourcemap: " .. sourcemap.state)
print("Sync runbook: " .. runbook.state)
print("Snapshot archive: " .. snapshot.state)
print("Rojo local server: " .. rojo.state)
print("Roblox Studio process: " .. studio.state)
print("G2 human receipt: " .. receipt.state)
print("Wrote Studio bridge bootstrap evidence to " .. OUTPUT_PATH)
