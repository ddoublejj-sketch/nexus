--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")

export type CommandResult = {
	label: string,
	command: string,
	ok: boolean,
	code: number,
	stdout: string,
	stderr: string,
	duration: number,
}

local QualityGate = {}

local TOOL_EXES = {
	["rojo"] = "rojo.exe",
	["wally"] = "wally.exe",
	["lune"] = "lune.exe",
	["stylua"] = "stylua.exe",
	["selene"] = "selene.exe",
	["luau-lsp"] = "luau-lsp.exe",
}

local function parseToolSpec(name: string): (string?, string?, string?)
	for line in fs.readFile("rokit.toml"):gmatch("[^\r\n]+") do
		local manifestName, owner, tool, version =
			line:match('^%s*([%w_%-]+)%s*=%s*"([^/]+)/([^@]+)@([^"]+)"')
		if manifestName == name and owner and tool and version then
			return owner:lower(), tool:lower(), version
		end
	end

	return nil
end

local function pathJoin(...: string): string
	local parts = { ... }
	return table.concat(parts, "/"):gsub("//+", "/")
end

function QualityGate.toolPath(name: string): string
	local owner, tool, version = parseToolSpec(name)
	if not owner or not tool or not version then
		error("Missing tool pin for " .. name)
	end

	local home = (process.env.USERPROFILE or process.env.HOME or ""):gsub("\\", "/")
	local exeName = TOOL_EXES[name]
	local directPath = pathJoin(home, ".rokit", "tool-storage", owner, tool, version, exeName)

	if fs.isFile(directPath) then
		return directPath
	end

	return name
end

function QualityGate.runTool(label: string, name: string, args: { string }): CommandResult
	local started = os.clock()
	local exePath = QualityGate.toolPath(name)
	local result = process.exec(exePath, args)
	local duration = os.clock() - started

	return {
		label = label,
		command = exePath .. " " .. table.concat(args, " "),
		ok = result.ok,
		code = result.code,
		stdout = result.stdout,
		stderr = result.stderr,
		duration = duration,
	}
end

function QualityGate.runAll(): { CommandResult }
	if not fs.isDir("build") then
		fs.writeDir("build")
	end

	return {
		QualityGate.runTool("Wally Install", "wally", { "install" }),
		QualityGate.runTool("StyLua", "stylua", { "--check", "src", "tools" }),
		QualityGate.runTool("Selene", "selene", { "src", "tools" }),
		QualityGate.runTool(
			"Sourcemap",
			"rojo",
			{ "sourcemap", "default.project.json", "-o", "sourcemap.json" }
		),
		QualityGate.runTool("Migration Tests", "lune", { "run", "tools/test_migrations.luau" }),
		QualityGate.runTool("Analyze", "luau-lsp", {
			"analyze",
			"--definitions",
			"types/globalTypes.d.luau",
			"--sourcemap",
			"sourcemap.json",
			"src",
		}),
		QualityGate.runTool(
			"Build",
			"rojo",
			{ "build", "default.project.json", "-o", "build/nexus.rbxl" }
		),
		QualityGate.runTool(
			"Open Cloud Dry Run",
			"lune",
			{ "run", "tools/open_cloud_publish.luau", "--dry-run", "--fixture" }
		),
	}
end

function QualityGate.allPassed(results: { CommandResult }): boolean
	for _, result in results do
		if not result.ok then
			return false
		end
	end

	return true
end

return QualityGate
