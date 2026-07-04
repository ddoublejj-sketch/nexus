--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")

local VAULT_ROOT = "C:/Users/jackw/Roblox/RobloxGameVault"
local OUTPUT_PATH = VAULT_ROOT .. "/00_Command_Center/GitHub CI Bootstrap.md"
local WORKFLOW_PATH = ".github/workflows/ci.yml"
local RECEIPT_PATH = "docs/gate-proofs/G4-github-ci.md"
local DEFAULT_REPO_NAME = "nexus"
local DEFAULT_VAULT_REPO_NAME = "RobloxGameVault"

type Options = {
	createPrivate: boolean,
	createVaultPrivate: boolean,
	repoName: string,
	vaultRepoName: string,
}

type CommandResult = {
	ok: boolean,
	code: number,
	output: string,
	rawOutput: string,
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

local function usage(): string
	return table.concat({
		"Usage: lune run tools/github_ci_bootstrap.luau [--create-private] [--repo name] [--create-vault-private] [--vault-repo name]",
		"",
		"Default mode is read-only and writes non-secret G4 readiness evidence.",
		"`--create-private` requires an authenticated GitHub CLI session and creates/pushes the private remote.",
		"`--create-vault-private` requires explicit founder approval because it exports Obsidian vault notes to GitHub.",
	}, "\n")
end

local function parseArgs(args: { string }): Options
	local options: Options = {
		createPrivate = false,
		createVaultPrivate = false,
		repoName = DEFAULT_REPO_NAME,
		vaultRepoName = DEFAULT_VAULT_REPO_NAME,
	}

	local index = 1
	while index <= #args do
		local arg = args[index]

		if arg == "--help" or arg == "-h" then
			print(usage())
			process.exit(0)
		elseif arg == "--create-private" then
			options.createPrivate = true
		elseif arg == "--create-vault-private" then
			options.createVaultPrivate = true
		elseif arg == "--repo" then
			index += 1
			if index > #args then
				error("--repo requires a name")
			end
			options.repoName = args[index]
		elseif arg == "--vault-repo" then
			index += 1
			if index > #args then
				error("--vault-repo requires a name")
			end
			options.vaultRepoName = args[index]
		elseif arg:match("^%-%-repo=") then
			options.repoName = arg:gsub("^%-%-repo=", "")
		elseif arg:match("^%-%-vault%-repo=") then
			options.vaultRepoName = arg:gsub("^%-%-vault%-repo=", "")
		else
			error("Unknown argument: " .. arg .. "\n" .. usage())
		end

		index += 1
	end

	if not options.repoName:match("^[%w_.%-]+$") then
		error("Repo name must contain only letters, numbers, dots, underscores, or hyphens.")
	end
	if not options.vaultRepoName:match("^[%w_.%-]+$") then
		error("Vault repo name must contain only letters, numbers, dots, underscores, or hyphens.")
	end

	return options
end

local function run(command: string, args: { string }): CommandResult
	local ok, result = pcall(function()
		return process.exec(command, args)
	end)

	if not ok then
		return {
			ok = false,
			code = -1,
			output = oneLine(tostring(result)),
			rawOutput = tostring(result),
		}
	end

	local execResult = result :: any
	local rawOutput = (execResult.stdout or "") .. " " .. (execResult.stderr or "")
	return {
		ok = execResult.ok,
		code = execResult.code,
		output = oneLine(rawOutput),
		rawOutput = rawOutput,
	}
end

local function hasOriginRemote(): boolean
	local result = run("git", { "remote", "get-url", "origin" })
	return result.ok and result.output ~= ""
end

local function vaultHasOriginRemote(): boolean
	local result = run("git", { "-C", VAULT_ROOT, "remote", "get-url", "origin" })
	return result.ok and result.output ~= ""
end

local function receiptAccepted(): boolean
	if not fs.isFile(RECEIPT_PATH) then
		return false
	end

	return fs.readFile(RECEIPT_PATH):find("CI branch protection confirmed: PASS", 1, true) ~= nil
end

local function workflowReady(): boolean
	return fs.isFile(WORKFLOW_PATH)
end

local function remoteSummary(): string
	if not hasOriginRemote() then
		return "no origin remote configured"
	end

	return "origin remote configured; URL intentionally hidden"
end

local function vaultRemoteSummary(): string
	if not fs.isDir(VAULT_ROOT) then
		return "vault directory missing"
	end
	if not fs.isDir(VAULT_ROOT .. "/.git") then
		return "vault Git repo missing"
	end
	if not vaultHasOriginRemote() then
		return "vault origin remote not configured"
	end

	return "vault origin remote configured; URL intentionally hidden"
end

local function ghRepoView(): string
	if not hasOriginRemote() then
		return "not checked; no origin remote"
	end

	local result = run("gh", {
		"repo",
		"view",
		"--json",
		"nameWithOwner,visibility,defaultBranchRef,url",
	})

	if not result.ok then
		return "not available: " .. result.output
	end

	local ok, decoded = pcall(function()
		return serde.decode("json", result.rawOutput)
	end)

	if not ok or type(decoded) ~= "table" then
		return "repo view returned unparsed output"
	end

	local repo = decoded :: any
	local branch = if type(repo.defaultBranchRef) == "table"
		then tostring(repo.defaultBranchRef.name or "unknown")
		else "unknown"
	return ("%s, %s, default branch %s"):format(
		tostring(repo.nameWithOwner or "unknown"),
		tostring(repo.visibility or "unknown"),
		branch
	)
end

local function createPrivateRemote(repoName: string): string
	if hasOriginRemote() then
		return "skipped; origin remote already exists"
	end

	local result = run("gh", {
		"repo",
		"create",
		repoName,
		"--private",
		"--source",
		".",
		"--remote",
		"origin",
		"--push",
	})

	if not result.ok then
		error("Failed to create/push private GitHub remote: " .. result.output)
	end

	return "created private remote and pushed current branch"
end

local function createVaultPrivateRemote(repoName: string): string
	if not fs.isDir(VAULT_ROOT) then
		error("Missing vault directory: " .. VAULT_ROOT)
	end
	if not fs.isDir(VAULT_ROOT .. "/.git") then
		error("Vault is not a Git repo: " .. VAULT_ROOT)
	end
	if vaultHasOriginRemote() then
		return "skipped; vault origin remote already exists"
	end

	local result = run("gh", {
		"repo",
		"create",
		repoName,
		"--private",
		"--source",
		VAULT_ROOT,
		"--remote",
		"origin",
		"--push",
	})

	if not result.ok then
		error("Failed to create/push private vault GitHub remote: " .. result.output)
	end

	return "created private vault remote and pushed current branch"
end

local function writeEvidence(
	timestamp: string,
	authState: string,
	remoteState: string,
	workflowState: string,
	repoState: string,
	vaultRemoteState: string,
	branchProtectionState: string,
	createState: string,
	vaultCreateState: string,
	nextAction: string
)
	local lines = {
		"---",
		"type: system",
		"status: active",
		"owner:",
		"source_path: C:\\Users\\jackw\\Roblox\\nexus\\tools\\github_ci_bootstrap.luau",
		"roblox_asset_id:",
		"studio_instance_path:",
		"dependencies:",
		"last_synced: " .. timestamp,
		"tags: gates, g4, github, ci",
		"---",
		"",
		"# GitHub CI Bootstrap",
		"",
		"Generated: " .. timestamp,
		"",
		"This note records non-secret GitHub CI readiness. Remote URLs and tokens are not written into the vault.",
		"",
		"| Item | State | Detail |",
		"| --- | --- | --- |",
		"| GitHub CLI auth | " .. authState .. " | `gh auth status` |",
		"| Origin remote | " .. remoteState .. " | " .. remoteSummary() .. " |",
		"| CI workflow | " .. workflowState .. " | " .. WORKFLOW_PATH .. " |",
		"| GitHub repo view | " .. repoState .. " | " .. repoState .. " |",
		"| Vault origin remote | " .. vaultRemoteState .. " | " .. vaultRemoteSummary() .. " |",
		"| Branch protection receipt | " .. branchProtectionState .. " | " .. RECEIPT_PATH .. " |",
		"| Remote create action | " .. createState .. " | requires `--create-private` |",
		"| Vault create action | "
			.. vaultCreateState
			.. " | requires explicit approval and `--create-vault-private` |",
		"",
		"## Next Action",
		"",
		nextAction,
		"",
		"After GitHub auth, Nexus remote push, vault remote push, and branch protection are real, update the G4 receipt and run `./nexus.ps1 gatecheck --gate G4`.",
	}

	fs.writeFile(OUTPUT_PATH, table.concat(lines, "\n") .. "\n")
end

if not fs.isDir(VAULT_ROOT) then
	error("Missing vault directory: " .. VAULT_ROOT)
end

local options = parseArgs(process.args)
local timestamp = isoTimestamp()
local auth = run("gh", { "auth", "status" })
local authState = if auth.ok then "PASS" else "WAITING"
local workflowState = if workflowReady() then "PASS" else "MISSING"
local createState = "not requested"
local vaultCreateState = "not requested"

if options.createPrivate then
	if not auth.ok then
		error("Cannot create GitHub remote until `gh auth status` passes.")
	end
	createState = createPrivateRemote(options.repoName)
end

if options.createVaultPrivate then
	if not auth.ok then
		error("Cannot create GitHub vault remote until `gh auth status` passes.")
	end
	vaultCreateState = createVaultPrivateRemote(options.vaultRepoName)
end

local remoteState = if hasOriginRemote() then "PASS" else "WAITING"
local vaultRemoteState = if vaultHasOriginRemote() then "PASS" else "WAITING"
local repoState = if auth.ok then ghRepoView() else "not checked; GitHub CLI not authenticated"
local branchProtectionState = if receiptAccepted() then "PASS" else "NEEDS HUMAN"

local nextAction: string
if not auth.ok then
	nextAction =
		"- Run `gh auth login`, complete the browser/device flow, then re-run `./nexus.ps1 github-ci`."
elseif not hasOriginRemote() then
	nextAction =
		"- Run `./nexus.ps1 github-ci --create-private` to create/push the private remote, or configure `origin` manually."
elseif not vaultHasOriginRemote() then
	nextAction =
		"- After explicit founder approval, run `./nexus.ps1 github-ci --create-vault-private` to create/push the private vault remote."
elseif not receiptAccepted() then
	nextAction =
		"- Confirm the GitHub Actions run is green, enable branch protection requiring `Nexus CI / Quality Gate`, then mark the G4 receipt. Private-repo branch protection may require GitHub Pro or a public repo."
else
	nextAction = "- G4 evidence is locally ready. Run `./nexus.ps1 gatecheck --gate G4`."
end

writeEvidence(
	timestamp,
	authState,
	remoteState,
	workflowState,
	repoState,
	vaultRemoteState,
	branchProtectionState,
	createState,
	vaultCreateState,
	nextAction
)

print("GitHub auth: " .. authState)
print("Origin remote: " .. remoteState)
print("CI workflow: " .. workflowState)
print("Vault remote: " .. vaultRemoteState)
print("Branch protection receipt: " .. branchProtectionState)
print("Remote create action: " .. createState)
print("Vault create action: " .. vaultCreateState)
print("Wrote GitHub CI bootstrap evidence to " .. OUTPUT_PATH)
