--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")

local VAULT_ROOT = "C:/Users/jackw/Roblox/RobloxGameVault"

local REQUIRED_DIRECTORIES = {
	"00_Command_Center",
	"01_Game_Design",
	"02_Systems",
	"03_World_And_Maps",
	"04_Assets",
	"05_Playtests",
	"06_Engineering",
	"80_Archives/StudioSnapshots",
	"90_Automation/Generated",
	"90_Automation/Logs/pending",
	"99_Inbox",
	"Templates",
}

local REQUIRED_TEMPLATES = {
	"Asset.md",
	"Bug.md",
	"Decision.md",
	"Map.md",
	"Playtest.md",
	"System.md",
}

local FRONTMATTER_FIELDS = {
	"type",
	"status",
	"owner",
	"source_path",
	"roblox_asset_id",
	"studio_instance_path",
	"dependencies",
	"last_synced",
	"tags",
}

local REQUIRED_COMMANDS = {
	debugtag = true,
	give = true,
	profilewipe = true,
	reloadmap = true,
	setstat = true,
	spawn = true,
	tp = true,
}

local function assertTrue(condition: boolean, label: string)
	if not condition then
		error(label)
	end
end

local function pathJoin(...: string): string
	return table.concat({ ... }, "/")
end

local function read(relativePath: string): string
	local path = pathJoin(VAULT_ROOT, relativePath)
	assertTrue(fs.isFile(path), "Missing vault file: " .. relativePath)

	return fs.readFile(path)
end

local function assertContains(contents: string, needle: string, label: string)
	assertTrue(contents:find(needle, 1, true) ~= nil, label)
end

local function assertFrontmatter(contents: string, label: string)
	assertTrue(contents:find("---", 1, true) == 1, label .. " missing opening frontmatter")

	for _, field in FRONTMATTER_FIELDS do
		assertContains(contents, "\n" .. field .. ":", label .. " missing " .. field)
	end
end

local function countWorkOrderRows(contents: string): number
	local count = 0
	for line in contents:gmatch("[^\r\n]+") do
		if line:match("^| WO%-%d+") then
			count += 1
		end
	end

	return count
end

if not fs.isDir(VAULT_ROOT) then
	print("Vault scaffold tests skipped: vault repo not present")
else
	assertTrue(fs.isDir(pathJoin(VAULT_ROOT, ".git")), "Vault must be its own Git repo")

	local gitLog = process.exec("git", {
		"-C",
		VAULT_ROOT,
		"log",
		"--oneline",
		"-1",
	})
	assertTrue(gitLog.ok and gitLog.stdout ~= "", "Vault repo must have at least one commit")

	for _, relativePath in REQUIRED_DIRECTORIES do
		assertTrue(
			fs.isDir(pathJoin(VAULT_ROOT, relativePath)),
			"Missing vault directory: " .. relativePath
		)
	end

	for _, templateName in REQUIRED_TEMPLATES do
		local contents = read("Templates/" .. templateName)
		assertFrontmatter(contents, "Template " .. templateName)
		assertContains(
			contents,
			"# <% tp.file.title %>",
			templateName .. " missing Templater title"
		)
	end

	local dashboard = read("00_Command_Center/Dashboard.md")
	assertFrontmatter(dashboard, "Dashboard")
	assertContains(dashboard, "## Active Systems", "Dashboard missing Active Systems")
	assertContains(dashboard, 'FROM "02_Systems"', "Dashboard missing systems Dataview query")
	assertContains(dashboard, "## Assets By Status", "Dashboard missing Assets By Status")
	assertContains(dashboard, 'FROM "04_Assets"', "Dashboard missing assets Dataview query")
	assertContains(dashboard, "## Open Tasks", "Dashboard missing Open Tasks")
	assertContains(dashboard, "```tasks", "Dashboard missing Tasks query")
	assertContains(dashboard, "![[Gate Status]]", "Dashboard missing Gate Status embed")
	assertContains(
		dashboard,
		"![[Human Gate Checklist]]",
		"Dashboard missing Human Gate Checklist embed"
	)
	assertContains(
		dashboard,
		"![[Human Gate Readiness]]",
		"Dashboard missing Human Gate Readiness embed"
	)
	assertContains(dashboard, "![[G1 Tool Closure]]", "Dashboard missing G1 Tool Closure embed")
	assertContains(
		dashboard,
		"![[Human Gate Proof Receipts]]",
		"Dashboard missing Human Gate Proof Receipts embed"
	)
	assertContains(
		dashboard,
		"![[Studio Bridge Bootstrap]]",
		"Dashboard missing Studio Bridge Bootstrap embed"
	)
	assertContains(
		dashboard,
		"![[Obsidian Plugin Setup]]",
		"Dashboard missing Obsidian Plugin Setup embed"
	)
	assertContains(
		dashboard,
		"![[GitHub CI Bootstrap]]",
		"Dashboard missing GitHub CI Bootstrap embed"
	)
	assertContains(
		dashboard,
		"![[Open Cloud Bootstrap]]",
		"Dashboard missing Open Cloud Bootstrap embed"
	)
	assertContains(
		dashboard,
		"![[Founder Sign-Off Audit]]",
		"Dashboard missing Founder Sign-Off Audit embed"
	)
	assertContains(dashboard, "![[Build Health]]", "Dashboard missing Build Health embed")
	assertContains(dashboard, "![[Stale Sources]]", "Dashboard missing Stale Sources embed")

	local gateStatus = read("00_Command_Center/Gate Status.md")
	assertFrontmatter(gateStatus, "Gate Status")
	for gateNumber = 1, 5 do
		assertContains(
			gateStatus,
			"G" .. tostring(gateNumber),
			"Gate Status missing G" .. tostring(gateNumber)
		)
	end
	assertTrue(countWorkOrderRows(gateStatus) == 11, "Gate Status must list WO-0 through WO-10")

	local humanGateChecklist = read("00_Command_Center/Human Gate Checklist.md")
	assertFrontmatter(humanGateChecklist, "Human Gate Checklist")
	assertContains(humanGateChecklist, "## G1 - GUI Installs", "Checklist missing G1")
	assertContains(humanGateChecklist, "## G2 - Studio Connect", "Checklist missing G2")
	assertContains(humanGateChecklist, "## G3 - Obsidian REST And Plugins", "Checklist missing G3")
	assertContains(humanGateChecklist, "## G4 - GitHub Auth And CI", "Checklist missing G4")
	assertContains(humanGateChecklist, "## G5 - Open Cloud Key", "Checklist missing G5")

	local humanGateReadiness = read("00_Command_Center/Human Gate Readiness.md")
	assertFrontmatter(humanGateReadiness, "Human Gate Readiness")
	assertContains(
		humanGateReadiness,
		"| Gate | Check | Status | Detail |",
		"Readiness missing table"
	)
	assertContains(humanGateReadiness, "code --version", "Readiness missing code audit")
	assertContains(humanGateReadiness, "gh auth status", "Readiness missing gh auth audit")
	assertContains(
		humanGateReadiness,
		"Open Cloud config",
		"Readiness missing Open Cloud config audit"
	)

	local g1ToolClosure = read("00_Command_Center/G1 Tool Closure.md")
	assertFrontmatter(g1ToolClosure, "G1 Tool Closure")
	assertContains(g1ToolClosure, "VS Code code CLI", "G1 Tool Closure missing VS Code row")
	assertContains(g1ToolClosure, "GitHub CLI", "G1 Tool Closure missing GitHub CLI row")
	assertContains(
		g1ToolClosure,
		"Blender Store Package",
		"G1 Tool Closure missing Store Blender row"
	)

	local humanGateReceipts = read("00_Command_Center/Human Gate Proof Receipts.md")
	assertFrontmatter(humanGateReceipts, "Human Gate Proof Receipts")
	assertContains(
		humanGateReceipts,
		"Pending receipts are not completion evidence.",
		"Human Gate Proof Receipts must reject pending proof"
	)
	assertContains(
		humanGateReceipts,
		"docs/gate-proofs/G2-studio-connect.md",
		"Human Gate Proof Receipts missing G2 receipt"
	)

	local obsidianPluginSetup = read("00_Command_Center/Obsidian Plugin Setup.md")
	assertFrontmatter(obsidianPluginSetup, "Obsidian Plugin Setup")
	assertContains(
		obsidianPluginSetup,
		"Local REST API",
		"Obsidian Plugin Setup missing Local REST API"
	)
	assertContains(
		obsidianPluginSetup,
		"Remaining G3 Human Proof",
		"Obsidian Plugin Setup missing remaining G3 proof"
	)

	local founderSignoffAudit = read("00_Command_Center/Founder Sign-Off Audit.md")
	assertFrontmatter(founderSignoffAudit, "Founder Sign-Off Audit")
	assertContains(
		founderSignoffAudit,
		"Overall: BLOCKED",
		"Founder Sign-Off Audit must not claim final completion before gates close"
	)
	assertContains(
		founderSignoffAudit,
		"Every WO acceptance command has real pasted output in STATUS.md",
		"Founder Sign-Off Audit missing Section 10 criteria"
	)

	local buildHealth = read("00_Command_Center/Build Health.md")
	assertFrontmatter(buildHealth, "Build Health")
	assertContains(buildHealth, "# Build Health", "Build Health missing title")
	assertContains(buildHealth, "Vault Scaffold Tests", "Build Health missing vault verifier row")
	assertContains(buildHealth, "Asset Manifest Tests", "Build Health missing asset verifier row")
	assertContains(
		buildHealth,
		"Command Surface Tests",
		"Build Health missing command verifier row"
	)
	assertContains(buildHealth, "Net Contract Tests", "Build Health missing Net verifier row")
	assertContains(buildHealth, "Secret Scan", "Build Health missing secret scan row")

	local sourcemap = read("90_Automation/Generated/Sourcemap.md")
	assertFrontmatter(sourcemap, "Sourcemap")
	assertContains(sourcemap, "game.ReplicatedStorage.Shared.Net", "Sourcemap missing Shared.Net")
	assertContains(
		sourcemap,
		"game.ServerScriptService.Server.Services.DataService",
		"Sourcemap missing DataService"
	)
	assertContains(
		sourcemap,
		"game.StarterPlayer.StarterPlayerScripts.Client.Controllers.NexusController",
		"Sourcemap missing NexusController"
	)

	local staleSources = read("90_Automation/Generated/Stale Sources.md")
	assertFrontmatter(staleSources, "Stale Sources")
	assertContains(
		staleSources,
		"No stale generated module notes found.",
		"Stale Sources should be clean"
	)

	local commands = read("02_Systems/Commands.md")
	assertFrontmatter(commands, "Commands")
	for commandName in REQUIRED_COMMANDS do
		assertContains(
			commands,
			"| " .. commandName .. " |",
			"Commands note missing " .. commandName
		)
	end

	print("Vault scaffold tests passed")
end
