param(
	[Parameter(Position = 0)]
	[string]$Command = "status",

	[Parameter(ValueFromRemainingArguments = $true)]
	[string[]]$Rest
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
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

function Start-NexusJob {
	param(
		[string]$Name,
		[scriptblock]$ScriptBlock,
		[object[]]$JobArgs = @()
	)

	$existing = Get-Job -Name $Name -ErrorAction SilentlyContinue | Select-Object -First 1
	if ($existing) {
		if ($existing.State -eq "Running") {
			return
		}

		Remove-Job -Job $existing -Force
	}

	Start-Job -Name $Name -ScriptBlock $ScriptBlock -ArgumentList $JobArgs | Out-Null
}

function Stop-NexusJobs {
	foreach ($name in $NexusJobNames) {
		$jobs = Get-Job -Name $name -ErrorAction SilentlyContinue
		foreach ($job in $jobs) {
			if ($job.State -eq "Running") {
				Stop-Job -Job $job
			}
			Remove-Job -Job $job -Force
		}
	}
}

function Write-NexusJobTable {
	$rows = foreach ($name in $NexusJobNames) {
		$job = Get-Job -Name $name -ErrorAction SilentlyContinue | Select-Object -First 1
		[pscustomobject]@{
			Name = $name
			State = if ($job) { $job.State } else { "Stopped" }
			Id = if ($job) { $job.Id } else { "" }
		}
	}

	$rows | Format-Table -AutoSize
}

Set-Location $RepoRoot

switch ($Command.ToLowerInvariant()) {
	"up" {
		Ensure-BuildDirectory
		$rojoPath = Get-ToolPath "rojo"
		$lunePath = Get-ToolPath "lune"
		Invoke-Tool "lune" @("run", "tools/dev_log.luau", "start")

		Start-NexusJob -Name "NexusRojoServe" -ScriptBlock {
			param($Root, $Rojo)
			Set-Location $Root
			& $Rojo serve default.project.json
		} -JobArgs @($RepoRoot, $rojoPath)

		Start-NexusJob -Name "NexusSourcemapWatch" -ScriptBlock {
			param($Root, $Rojo)
			Set-Location $Root
			& $Rojo sourcemap default.project.json -o sourcemap.json --watch
		} -JobArgs @($RepoRoot, $rojoPath)

		Start-NexusJob -Name "NexusAutomationLoop" -ScriptBlock {
			param($Root, $Lune)
			$ErrorActionPreference = "Stop"
			function Invoke-LoopScript {
				param([string]$ScriptPath)

				& $Lune run $ScriptPath
				if ($LASTEXITCODE -ne 0) {
					throw "$ScriptPath failed with exit code $LASTEXITCODE"
				}
			}

			Set-Location $Root
			while ($true) {
				Invoke-LoopScript "tools/sourcemap_summary.luau"
				Invoke-LoopScript "tools/vault_sync.luau"
				Invoke-LoopScript "tools/command_registry.luau"
				Invoke-LoopScript "tools/asset_manifest.luau"
				Invoke-LoopScript "tools/gate_status.luau"
				Invoke-LoopScript "tools/human_gate_checklist.luau"
				Invoke-LoopScript "tools/human_gate_readiness.luau"
				& $Lune run tools/build_health.luau --skip-install
				if ($LASTEXITCODE -ne 0) {
					throw "tools/build_health.luau --skip-install failed with exit code $LASTEXITCODE"
				}
				Start-Sleep -Seconds 10
			}
		} -JobArgs @($RepoRoot, $lunePath)

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
	"gates" {
		Invoke-Tool "lune" @("run", "tools/gate_status.luau")
		Invoke-Tool "lune" @("run", "tools/human_gate_checklist.luau")
		Invoke-Tool "lune" @("run", "tools/human_gate_readiness.luau")
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
			Invoke-Tool "lune" @("run", "tools/build_health.luau")

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
		throw "Unknown command '$Command'. Use up, down, serve, build, map, check, fix, sync, health, gates, release, loop, or status."
	}
}
