--!strict

local process = require("@lune/process")

type PatternRule = {
	name: string,
	pattern: string,
}

type ScanTarget = {
	name: string,
	path: string,
	args: { string },
}

local TARGETS: { ScanTarget } = {
	{
		name = "Nexus secrets/.env history",
		path = ".",
		args = { "log", "-p", "--", "secrets", ".env" },
	},
	{
		name = "Nexus full history",
		path = ".",
		args = { "log", "-p" },
	},
	{
		name = "Vault full history",
		path = "C:/Users/jackw/Roblox/RobloxGameVault",
		args = { "log", "-p" },
	},
}

local RULES: { PatternRule } = {
	{
		name = "OpenAI key",
		pattern = "sk%-[%w_%-]{20,}",
	},
	{
		name = "GitHub classic token",
		pattern = "ghp_[%w_]{20,}",
	},
	{
		name = "GitHub fine-grained token",
		pattern = "github_pat_[%w_]{20,}",
	},
	{
		name = "Filled Obsidian API key",
		pattern = "OBSIDIAN_API_KEY=%s*[^%s\r\n#][^%r\n]*",
	},
	{
		name = "Filled Open Cloud API key",
		pattern = "OPEN_CLOUD_API_KEY=%s*[^%s\r\n#][^%r\n]*",
	},
}

local ALLOWED_VALUE_FRAGMENTS = {
	"replace_with",
	"fixture",
	"do_not_use",
}

local function trim(value: string): string
	return value:match("^%s*(.-)%s*$") or ""
end

local function isAllowed(line: string): boolean
	local lower = line:lower()

	for _, fragment in ALLOWED_VALUE_FRAGMENTS do
		if lower:find(fragment, 1, true) then
			return true
		end
	end

	return false
end

local function runGit(target: ScanTarget): string
	local args = { "-C", target.path }
	for _, arg in target.args do
		table.insert(args, arg)
	end

	local result = process.exec("git", args)
	if not result.ok then
		error(("git scan failed for %s: %s"):format(target.name, result.stderr))
	end

	return result.stdout
end

local findings = {}

for _, target in TARGETS do
	local output = runGit(target)
	local lineNumber = 0

	for line in output:gmatch("[^\r\n]+") do
		lineNumber += 1

		for _, rule in RULES do
			if line:find(rule.pattern) and not isAllowed(line) then
				table.insert(
					findings,
					("%s:%d [%s] %s"):format(target.name, lineNumber, rule.name, trim(line))
				)
			end
		end
	end
end

if #findings > 0 then
	error("Secret scan failed:\n" .. table.concat(findings, "\n"))
end

print("Secret scan passed")
