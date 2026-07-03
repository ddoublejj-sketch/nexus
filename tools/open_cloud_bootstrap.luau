--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")

local VAULT_ROOT = "C:/Users/jackw/Roblox/RobloxGameVault"
local OUTPUT_PATH = VAULT_ROOT .. "/00_Command_Center/Open Cloud Bootstrap.md"
local SECRET_PATH = "secrets/opencloud.env"
local FIXTURE_PATH = "tools/fixtures/opencloud.env"
local ARTIFACT_PATH = "build/nexus.rbxl"
local CHECKLIST_PATH = "docs/runbooks/release-checklist.md"
local RECEIPT_PATH = "docs/gate-proofs/G5-open-cloud-publish.md"
local BUILD_HEALTH_PATH = VAULT_ROOT .. "/00_Command_Center/Build Health.md"

type Check = {
	state: string,
	detail: string,
}

local function trim(value: string): string
	return value:match("^%s*(.-)%s*$") or ""
end

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
				values[key] = trim(value)
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

local function fileCheck(path: string, presentDetail: string): Check
	local present = fs.isFile(path) or fs.isDir(path)
	return {
		state = if present then "PASS" else "MISSING",
		detail = if present then presentDetail else path,
	}
end

local function artifactCheck(): Check
	if not fs.isFile(ARTIFACT_PATH) then
		return {
			state = "MISSING",
			detail = ARTIFACT_PATH,
		}
	end

	local bytes = #fs.readFile(ARTIFACT_PATH)
	if bytes <= 0 then
		return {
			state = "FAIL",
			detail = "artifact is empty",
		}
	end

	return {
		state = "PASS",
		detail = ("artifact exists; %d bytes"):format(bytes),
	}
end

local function buildHealthCheck(): Check
	if not fs.isFile(BUILD_HEALTH_PATH) then
		return {
			state = "MISSING",
			detail = BUILD_HEALTH_PATH,
		}
	end

	local contents = fs.readFile(BUILD_HEALTH_PATH)
	if not contents:find("Overall: PASS", 1, true) then
		return {
			state = "WAITING",
			detail = "Build Health exists but is not PASS",
		}
	end

	return {
		state = "PASS",
		detail = "Build Health overall PASS",
	}
end

local function secretCheck(): Check
	if not fs.isFile(SECRET_PATH) then
		return {
			state = "WAITING",
			detail = SECRET_PATH .. " missing",
		}
	end

	local values = readEnvFile(SECRET_PATH)
	if looksPlaceholder(values.OPEN_CLOUD_API_KEY or "") then
		return {
			state = "WAITING",
			detail = "OPEN_CLOUD_API_KEY missing or placeholder; value hidden",
		}
	end

	if not numericIdOk(values.ROBLOX_UNIVERSE_ID or "") then
		return {
			state = "WAITING",
			detail = "ROBLOX_UNIVERSE_ID missing or invalid; value hidden",
		}
	end

	if not numericIdOk(values.ROBLOX_PLACE_ID or "") then
		return {
			state = "WAITING",
			detail = "ROBLOX_PLACE_ID missing or invalid; value hidden",
		}
	end

	return {
		state = "PASS",
		detail = "secret file present; values hidden",
	}
end

local function releaseDryRun(args: { string }, label: string): Check
	local ok, result = pcall(function()
		return process.exec("lune", args)
	end)

	if not ok then
		return {
			state = "WAITING",
			detail = label .. " could not run: " .. oneLine(tostring(result)),
		}
	end

	local execResult = result :: any
	return {
		state = if execResult.ok then "PASS" else "WAITING",
		detail = if execResult.ok
			then label .. " passed; output omitted"
			else label .. " failed; output omitted",
	}
end

local function receiptCheck(): Check
	if not fs.isFile(RECEIPT_PATH) then
		return {
			state = "NEEDS HUMAN",
			detail = "missing receipt: " .. RECEIPT_PATH,
		}
	end

	local contents = fs.readFile(RECEIPT_PATH)
	if contents:find("Live publish approval recorded: PASS", 1, true) then
		return {
			state = "PASS",
			detail = "accepted by " .. RECEIPT_PATH,
		}
	end

	return {
		state = "NEEDS HUMAN",
		detail = "receipt needs live publish approval PASS marker",
	}
end

local function nextAction(secret: Check, realDryRun: Check, receipt: Check): string
	if secret.state ~= "PASS" then
		return "- Create `secrets/opencloud.env` locally with the Open Cloud key, universe ID, and place ID; do not commit or paste the values."
	end

	if realDryRun.state ~= "PASS" then
		return "- Run `lune run tools/open_cloud_publish.luau --dry-run`; keep the output local because it can include universe/place IDs."
	end

	if receipt.state ~= "PASS" then
		return "- After explicit live publish approval, update the G5 receipt marker to `PASS` before running live publish."
	end

	return "- G5 evidence is locally ready. Run `./nexus.ps1 gatecheck --gate G5`."
end

local function writeEvidence(
	timestamp: string,
	artifact: Check,
	buildHealth: Check,
	fixture: Check,
	checklist: Check,
	secret: Check,
	fixtureDryRun: Check,
	realDryRun: Check,
	receipt: Check
)
	local lines = {
		"---",
		"type: system",
		"status: active",
		"owner:",
		"source_path: C:\\Users\\jackw\\Roblox\\nexus\\tools\\open_cloud_bootstrap.luau",
		"roblox_asset_id:",
		"studio_instance_path:",
		"dependencies:",
		"last_synced: " .. timestamp,
		"tags: gates, g5, release, open-cloud",
		"---",
		"",
		"# Open Cloud Bootstrap",
		"",
		"Generated: " .. timestamp,
		"",
		"This note records release readiness without writing Open Cloud key, universe ID, place ID, endpoint, or dry-run output values into the vault.",
		"",
		"| Item | State | Detail |",
		"| --- | --- | --- |",
		"| Build artifact | " .. artifact.state .. " | " .. artifact.detail .. " |",
		"| Build Health | " .. buildHealth.state .. " | " .. buildHealth.detail .. " |",
		"| Fixture config | " .. fixture.state .. " | " .. fixture.detail .. " |",
		"| Release checklist | " .. checklist.state .. " | " .. checklist.detail .. " |",
		"| Open Cloud secret file | " .. secret.state .. " | " .. secret.detail .. " |",
		"| Fixture dry-run | " .. fixtureDryRun.state .. " | " .. fixtureDryRun.detail .. " |",
		"| Real dry-run | " .. realDryRun.state .. " | " .. realDryRun.detail .. " |",
		"| Live approval receipt | " .. receipt.state .. " | " .. receipt.detail .. " |",
		"",
		"## Next Action",
		"",
		nextAction(secret, realDryRun, receipt),
		"",
		"Live publish remains gated on explicit G5 approval and `./nexus.ps1 release --live`.",
	}

	fs.writeFile(OUTPUT_PATH, table.concat(lines, "\n") .. "\n")
end

if not fs.isDir(VAULT_ROOT) then
	error("Missing vault directory: " .. VAULT_ROOT)
end

local artifact = artifactCheck()
local buildHealth = buildHealthCheck()
local fixture = fileCheck(FIXTURE_PATH, "fixture config present")
local checklist = fileCheck(CHECKLIST_PATH, "release checklist present")
local secret = secretCheck()
local fixtureDryRun = releaseDryRun({
	"run",
	"tools/open_cloud_publish.luau",
	"--dry-run",
	"--fixture",
}, "fixture dry-run")
local realDryRun = if secret.state == "PASS"
	then releaseDryRun({ "run", "tools/open_cloud_publish.luau", "--dry-run" }, "real dry-run")
	else {
		state = "WAITING",
		detail = "not run until secret file is valid; values hidden",
	}
local receipt = receiptCheck()

writeEvidence(
	isoTimestamp(),
	artifact,
	buildHealth,
	fixture,
	checklist,
	secret,
	fixtureDryRun,
	realDryRun,
	receipt
)

print("Build artifact: " .. artifact.state)
print("Build Health: " .. buildHealth.state)
print("Fixture config: " .. fixture.state)
print("Release checklist: " .. checklist.state)
print("Open Cloud secret file: " .. secret.state)
print("Fixture dry-run: " .. fixtureDryRun.state)
print("Real dry-run: " .. realDryRun.state)
print("Live approval receipt: " .. receipt.state)
print("Wrote Open Cloud bootstrap evidence to " .. OUTPUT_PATH)
