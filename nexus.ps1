param(
	[Parameter(Position = 0)]
	[string]$Command = "status",

	[Parameter(ValueFromRemainingArguments = $true)]
	[string[]]$Rest
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$NexusRuntimeRoot = Join-Path $RepoRoot ".nexus"
$NexusPidRoot = Join-Path $NexusRuntimeRoot "pids"
$NexusLogRoot = Join-Path $NexusRuntimeRoot "logs"
$NexusJobNames = @(
	"NexusRojoServe",
	"NexusSourcemapWatch",
	"NexusAutomationLoop"
)
$ToolExeNames = @{
	"rojo" = "rojo.exe"
	"wally" = "wally.exe"
	"lune" = "lune.exe"
	"selene" = "selene.exe"
	"stylua" = "stylua.exe"
	"luau-lsp" = "luau-lsp.exe"
}

function Get-ToolPath {
	param([string]$Name)

	$manifestPath = Join-Path $RepoRoot "rokit.toml"
	foreach ($manifestLine in Get-Content -LiteralPath $manifestPath) {
		if ($manifestLine -match "^\s*$Name\s*=\s*`"([^/]+)/([^@]+)@([^`"]+)`"") {
			$owner = $Matches[1].ToLowerInvariant()
			$tool = $Matches[2].ToLowerInvariant()
			$version = $Matches[3]
			$exeName = $ToolExeNames[$Name]
			$directPath = Join-Path $env:USERPROFILE ".rokit\tool-storage\$owner\$tool\$version\$exeName"
			if (Test-Path -LiteralPath $directPath) {
				return $directPath
			}
		}
	}

	$commandInfo = Get-Command $Name -ErrorAction SilentlyContinue
	if ($commandInfo) {
		return $commandInfo.Source
	}

	throw "Tool '$Name' is not installed. Run 'rokit install' from $RepoRoot."
}

function Invoke-Tool {
	param(
		[string]$Name,
		[string[]]$ToolArgs = @()
	)

	$toolPath = Get-ToolPath $Name
	& $toolPath @ToolArgs
	if ($LASTEXITCODE -ne 0) {
		throw "$Name failed with exit code $LASTEXITCODE"
	}
}

function Ensure-BuildDirectory {
	$buildPath = Join-Path $RepoRoot "build"
	if (-not (Test-Path -LiteralPath $buildPath)) {
		New-Item -ItemType Directory -Path $buildPath | Out-Null
	}
}

function Ensure-NexusRuntime {
	foreach ($path in @($NexusRuntimeRoot, $NexusPidRoot, $NexusLogRoot)) {
		if (-not (Test-Path -LiteralPath $path)) {
			New-Item -ItemType Directory -Path $path | Out-Null
		}
	}
}

function Get-NexusPidPath {
	param([string]$Name)

	Join-Path $NexusPidRoot "$Name.pid"
}

function Get-NexusProcess {
	param([string]$Name)

	$pidPath = Get-NexusPidPath $Name
	if (-not (Test-Path -LiteralPath $pidPath)) {
		return $null
	}

	$processId = [int](Get-Content -LiteralPath $pidPath -Raw)
	$process = Get-Process -Id $processId -ErrorAction SilentlyContinue
	if (-not $process) {
		Remove-Item -LiteralPath $pidPath -Force
	}

	$process
}

function Start-NexusProcess {
	param(
		[string]$Name,
		[string]$FilePath,
		[string[]]$Arguments = @()
	)

	Ensure-NexusRuntime
	$existing = Get-NexusProcess $Name
	if ($existing) {
		return
	}

	$outPath = Join-Path $NexusLogRoot "$Name.out.log"
	$errPath = Join-Path $NexusLogRoot "$Name.err.log"
	foreach ($path in @($outPath, $errPath)) {
		if (Test-Path -LiteralPath $path) {
			Remove-Item -LiteralPath $path -Force
		}
	}

	$process = Start-Process -FilePath $FilePath `
		-ArgumentList $Arguments `
		-WorkingDirectory $RepoRoot `
		-WindowStyle Hidden `
		-RedirectStandardOutput $outPath `
		-RedirectStandardError $errPath `
		-PassThru
	Set-Content -LiteralPath (Get-NexusPidPath $Name) -Value $process.Id
}

function Stop-NexusJobs {
	foreach ($name in $NexusJobNames) {
		$process = Get-NexusProcess $name
		if ($process) {
			Stop-Process -Id $process.Id -Force
		}

		$pidPath = Get-NexusPidPath $name
		if (Test-Path -LiteralPath $pidPath) {
			Remove-Item -LiteralPath $pidPath -Force
		}
	}
}

function Write-NexusJobTable {
	$rows = foreach ($name in $NexusJobNames) {
		$process = Get-NexusProcess $name
		[pscustomobject]@{
			Name = $name
			State = if ($process) { "Running" } else { "Stopped" }
			Id = if ($process) { $process.Id } else { "" }
		}
	}

	$rows | Format-Table -AutoSize
}

function Refresh-NexusPath {
	$machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
	$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
	$parts = @()

	if ($machinePath) {
		$parts += $machinePath
	}

	if ($userPath) {
		$parts += $userPath
	}

	if ($parts.Count -gt 0) {
		$env:Path = $parts -join ";"
	}
}

Refresh-NexusPath
Set-Location $RepoRoot

switch ($Command.ToLowerInvariant()) {
	"up" {
		Ensure-BuildDirectory
		$rojoPath = Get-ToolPath "rojo"
		$powershellPath = (Get-Process -Id $PID).Path
		Invoke-Tool "lune" @("run", "tools/dev_log.luau", "start")
		Invoke-Tool "wally" @("install")

		Start-NexusProcess -Name "NexusRojoServe" -FilePath $rojoPath -Arguments @("serve", "default.project.json")
		Start-NexusProcess -Name "NexusSourcemapWatch" -FilePath $rojoPath -Arguments @("sourcemap", "default.project.json", "-o", "sourcemap.json", "--watch")
		Start-NexusProcess -Name "NexusAutomationLoop" -FilePath $powershellPath -Arguments @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $MyInvocation.MyCommand.Path, "loop")

		Write-NexusJobTable
	}
	"down" {
		Stop-NexusJobs
		Invoke-Tool "lune" @("run", "tools/dev_log.luau", "end")
		Write-NexusJobTable
	}
	"serve" {
		Invoke-Tool "rojo" @("serve", "default.project.json")
	}
	"build" {
		Ensure-BuildDirectory
		Invoke-Tool "rojo" @("build", "default.project.json", "-o", "build/nexus.rbxl")
	}
	"map" {
		if ($Rest -contains "--once") {
			Invoke-Tool "rojo" @("sourcemap", "default.project.json", "-o", "sourcemap.json")
		} else {
			Invoke-Tool "rojo" @("sourcemap", "default.project.json", "-o", "sourcemap.json", "--watch")
		}
	}
	"check" {
		Invoke-Tool "lune" @("run", "tools/quality_gate.luau")
	}
	"fix" {
		Invoke-Tool "stylua" @("src", "tools")
	}
	"sync" {
		Invoke-Tool "lune" @("run", "tools/vault_sync.luau")
	}
	"health" {
		Invoke-Tool "lune" @("run", "tools/build_health.luau")
	}
	"thumbnails" {
		$blender = Get-Command blender -ErrorAction SilentlyContinue
		if (-not $blender) {
			throw "Blender CLI is not available. Run ./nexus.ps1 gatecheck --gate G1 first."
		}

		& $blender.Source --background --python tools/render_asset_thumbnails.py -- assets_export/manifests/assets.json
		if ($LASTEXITCODE -ne 0) {
			throw "Blender thumbnail render failed with exit code $LASTEXITCODE"
		}

		Invoke-Tool "lune" @("run", "tools/asset_manifest.luau")
	}
	"gates" {
		Invoke-Tool "lune" @("run", "tools/gate_status.luau")
		Invoke-Tool "lune" @("run", "tools/human_gate_checklist.luau")
		Invoke-Tool "lune" @("run", "tools/human_gate_readiness.luau")
		Invoke-Tool "lune" @("run", "tools/human_gate_receipts.luau")
		Invoke-Tool "lune" @("run", "tools/g1_tool_closure.luau")
	}
	"gatecheck" {
		Invoke-Tool "lune" (@("run", "tools/human_gate_acceptance.luau") + $Rest)
	}
	"g1" {
		Invoke-Tool "lune" @("run", "tools/g1_tool_closure.luau")
	}
	"studio-bridge" {
		Invoke-Tool "lune" @("run", "tools/studio_bridge_bootstrap.luau")
	}
	"receipts" {
		Invoke-Tool "lune" @("run", "tools/human_gate_receipts.luau")
	}
	"obsidian-plugins" {
		Invoke-Tool "lune" @("run", "tools/obsidian_plugin_setup.luau")
	}
	"obsidian-rest" {
		Invoke-Tool "lune" @("run", "tools/obsidian_rest_bootstrap.luau")
	}
	"github-ci" {
		Invoke-Tool "lune" (@("run", "tools/github_ci_bootstrap.luau") + $Rest)
	}
	"open-cloud" {
		Invoke-Tool "lune" @("run", "tools/open_cloud_bootstrap.luau")
	}
	"audit" {
		Invoke-Tool "lune" @("run", "tools/founder_signoff_audit.luau")
	}
	"cold-boot" {
		Invoke-Tool "lune" @("run", "tools/cold_boot_readiness.luau")
	}
	"wo-audit" {
		Invoke-Tool "lune" @("run", "tools/work_order_acceptance_audit.luau")
	}
	"release" {
		Invoke-Tool "lune" (@("run", "tools/open_cloud_publish.luau") + $Rest)
	}
	"loop" {
		do {
			Invoke-Tool "lune" @("run", "tools/sourcemap_summary.luau")
			Invoke-Tool "lune" @("run", "tools/vault_sync.luau")
			Invoke-Tool "lune" @("run", "tools/command_registry.luau")
			Invoke-Tool "lune" @("run", "tools/asset_manifest.luau")
			Invoke-Tool "lune" @("run", "tools/gate_status.luau")
			Invoke-Tool "lune" @("run", "tools/human_gate_checklist.luau")
			Invoke-Tool "lune" @("run", "tools/human_gate_readiness.luau")
			Invoke-Tool "lune" @("run", "tools/human_gate_receipts.luau")
			if ($Rest -contains "--once") {
				Invoke-Tool "lune" @("run", "tools/build_health.luau")
			} else {
				Invoke-Tool "lune" @("run", "tools/build_health.luau", "--skip-install")
			}
			Invoke-Tool "lune" @("run", "tools/cold_boot_readiness.luau")
			Invoke-Tool "lune" @("run", "tools/work_order_acceptance_audit.luau")
			Invoke-Tool "lune" @("run", "tools/founder_signoff_audit.luau")

			if ($Rest -contains "--once") {
				break
			}

			Start-Sleep -Seconds 10
		} while ($true)
	}
	"status" {
		git status --short
		rokit list
		Write-Host ""
		Write-Host "Pinned tool versions:"
		Invoke-Tool "rojo" @("--version")
		Invoke-Tool "wally" @("--version")
		Invoke-Tool "lune" @("--version")
		Invoke-Tool "selene" @("--version")
		Invoke-Tool "stylua" @("--version")
		Invoke-Tool "luau-lsp" @("--version")
		if (Test-Path -LiteralPath "build/nexus.rbxl") {
			$item = Get-Item -LiteralPath "build/nexus.rbxl"
			Write-Host "Last build: $($item.Length) bytes at $($item.LastWriteTime)"
		} else {
			Write-Host "Last build: none"
		}
		Write-Host ""
		Write-NexusJobTable
	}
	default {
		throw "Unknown command '$Command'. Use up, down, serve, build, map, check, fix, sync, health, thumbnails, gates, gatecheck, g1, studio-bridge, receipts, obsidian-plugins, obsidian-rest, github-ci, open-cloud, audit, cold-boot, wo-audit, release, loop, or status."
	}
}
