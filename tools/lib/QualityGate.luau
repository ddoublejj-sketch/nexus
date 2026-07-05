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

export type RunOptions = {
	skipInstall: boolean?,
}

local QualityGate = {}
local LOCAL_VAULT_ROOT = "C:/Users/jackw/Roblox/RobloxGameVault"

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

function QualityGate.skip(label: string, reason: string): CommandResult
	return {
		label = label,
		command = "skipped",
		ok = true,
		code = 0,
		stdout = reason,
		stderr = "",
		duration = 0,
	}
end

local function runningCiWithoutLocalVault(): boolean
	return process.env.GITHUB_ACTIONS == "true" and not fs.isDir(LOCAL_VAULT_ROOT)
end

local function localVaultTest(label: string, scriptPath: string): CommandResult
	if runningCiWithoutLocalVault() then
		return QualityGate.skip(
			label,
			"Skipped in GitHub Actions because the local RobloxGameVault checkout is not present."
		)
	end

	return QualityGate.runTool(label, "lune", { "run", scriptPath })
end

function QualityGate.runAll(options: RunOptions?): { CommandResult }
	if not fs.isDir("build") then
		fs.writeDir("build")
	end

	local results = {}

	if not (options and options.skipInstall) then
		table.insert(results, QualityGate.runTool("Wally Install", "wally", { "install" }))
	end

	table.insert(results, QualityGate.runTool("StyLua", "stylua", { "--check", "src", "tools" }))
	table.insert(results, QualityGate.runTool("Selene", "selene", { "src", "tools" }))
	table.insert(
		results,
		QualityGate.runTool("Sourcemap", "rojo", {
			"sourcemap",
			"default.project.json",
			"-o",
			"sourcemap.json",
		})
	)
	table.insert(
		results,
		QualityGate.runTool(
			"Tool Gap Contract Tests",
			"lune",
			{ "run", "tools/test_tool_gap_contract.luau" }
		)
	)
	table.insert(
		results,
		QualityGate.runTool(
			"G1 Tool Closure Tests",
			"lune",
			{ "run", "tools/test_g1_tool_closure.luau" }
		)
	)
	table.insert(
		results,
		QualityGate.runTool(
			"Rojo Bridge Tests",
			"lune",
			{ "run", "tools/test_rojo_bridge_contract.luau" }
		)
	)
	table.insert(
		results,
		QualityGate.runTool(
			"Studio Bridge Bootstrap Tests",
			"lune",
			{ "run", "tools/test_studio_bridge_bootstrap.luau" }
		)
	)
	table.insert(
		results,
		QualityGate.runTool("Migration Tests", "lune", { "run", "tools/test_migrations.luau" })
	)
	table.insert(
		results,
		localVaultTest("DataService Contract Tests", "tools/test_data_service_contract.luau")
	)
	table.insert(
		results,
		QualityGate.runTool(
			"Vault Scaffold Tests",
			"lune",
			{ "run", "tools/test_vault_scaffold.luau" }
		)
	)
	table.insert(
		results,
		QualityGate.runTool(
			"Obsidian Plugin Setup Tests",
			"lune",
			{ "run", "tools/test_obsidian_plugin_setup.luau" }
		)
	)
	table.insert(
		results,
		QualityGate.runTool(
			"Obsidian REST Bootstrap Tests",
			"lune",
			{ "run", "tools/test_obsidian_rest_bootstrap.luau" }
		)
	)
	table.insert(
		results,
		QualityGate.runTool(
			"GitHub CI Bootstrap Tests",
			"lune",
			{ "run", "tools/test_github_ci_bootstrap.luau" }
		)
	)
	table.insert(
		results,
		QualityGate.runTool(
			"Asset Manifest Tests",
			"lune",
			{ "run", "tools/test_asset_manifest.luau" }
		)
	)
	table.insert(
		results,
		QualityGate.runTool("Command Surface Tests", "lune", { "run", "tools/test_commands.luau" })
	)
	table.insert(
		results,
		QualityGate.runTool(
			"MapService Contract Tests",
			"lune",
			{ "run", "tools/test_map_service_contract.luau" }
		)
	)
	table.insert(results, localVaultTest("Net Contract Tests", "tools/test_net_contract.luau"))
	table.insert(
		results,
		QualityGate.runTool(
			"Golf Pro Core Tests",
			"lune",
			{ "run", "tools/test_golfpro_core.luau" }
		)
	)
	table.insert(
		results,
		QualityGate.runTool(
			"Golf Pro Multiplayer Core Tests",
			"lune",
			{ "run", "tools/test_golfpro_multiplayer_core.luau" }
		)
	)
	table.insert(
		results,
		QualityGate.runTool(
			"Golf Pro Phase 5 Contract Tests",
			"lune",
			{ "run", "tools/test_golfpro_phase5_contract.luau" }
		)
	)
	table.insert(
		results,
		QualityGate.runTool(
			"Golf Pro Presentation Contract Tests",
			"lune",
			{ "run", "tools/test_golfpro_presentation_contract.luau" }
		)
	)
	table.insert(
		results,
		QualityGate.runTool("CI Contract Tests", "lune", { "run", "tools/test_ci_contract.luau" })
	)
	table.insert(
		results,
		QualityGate.runTool(
			"Command Center Contract Tests",
			"lune",
			{ "run", "tools/test_command_center_contract.luau" }
		)
	)
	table.insert(
		results,
		localVaultTest("Cold Boot Readiness Tests", "tools/test_cold_boot_readiness.luau")
	)
	table.insert(
		results,
		localVaultTest(
			"Work Order Acceptance Audit Tests",
			"tools/test_work_order_acceptance_audit.luau"
		)
	)
	table.insert(
		results,
		QualityGate.runTool(
			"Human Gate Checklist Tests",
			"lune",
			{ "run", "tools/test_human_gate_checklist.luau" }
		)
	)
	table.insert(
		results,
		QualityGate.runTool(
			"Human Gate Readiness Tests",
			"lune",
			{ "run", "tools/test_human_gate_readiness.luau" }
		)
	)
	table.insert(
		results,
		QualityGate.runTool(
			"Human Gate Acceptance Tests",
			"lune",
			{ "run", "tools/test_human_gate_acceptance.luau" }
		)
	)
	table.insert(
		results,
		QualityGate.runTool(
			"Human Gate Receipt Tests",
			"lune",
			{ "run", "tools/test_human_gate_receipts.luau" }
		)
	)
	table.insert(
		results,
		QualityGate.runTool(
			"Founder Sign-Off Audit Tests",
			"lune",
			{ "run", "tools/test_founder_signoff_audit.luau" }
		)
	)
	table.insert(
		results,
		QualityGate.runTool(
			"Acceptance Matrix Contract Tests",
			"lune",
			{ "run", "tools/test_acceptance_matrix_contract.luau" }
		)
	)
	table.insert(
		results,
		QualityGate.runTool(
			"Release Contract Tests",
			"lune",
			{ "run", "tools/test_release_contract.luau" }
		)
	)
	table.insert(
		results,
		QualityGate.runTool(
			"Open Cloud Bootstrap Tests",
			"lune",
			{ "run", "tools/test_open_cloud_bootstrap.luau" }
		)
	)
	table.insert(
		results,
		QualityGate.runTool("Secret Scan", "lune", { "run", "tools/secret_scan.luau" })
	)
	table.insert(
		results,
		QualityGate.runTool("Analyze", "luau-lsp", {
			"analyze",
			"--definitions",
			"types/globalTypes.d.luau",
			"--sourcemap",
			"sourcemap.json",
			"src",
		})
	)
	table.insert(
		results,
		QualityGate.runTool(
			"Build",
			"rojo",
			{ "build", "default.project.json", "-o", "build/nexus.rbxl" }
		)
	)
	table.insert(
		results,
		QualityGate.runTool(
			"Open Cloud Dry Run",
			"lune",
			{ "run", "tools/open_cloud_publish.luau", "--dry-run", "--fixture" }
		)
	)

	return results
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
