param(
	[Parameter(Position = 0)]
	[string]$Command = "status",

	[Parameter(ValueFromRemainingArguments = $true)]
	[string[]]$Rest
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
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
		[string[]]$Args = @()
	)

	$toolPath = Get-ToolPath $Name
	& $toolPath @Args
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

Set-Location $RepoRoot

switch ($Command.ToLowerInvariant()) {
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
		Invoke-Tool "stylua" @("--check", "src", "tools")
		Invoke-Tool "selene" @("src")
		Invoke-Tool "rojo" @("sourcemap", "default.project.json", "-o", "sourcemap.json")
		Invoke-Tool "luau-lsp" @(
			"analyze",
			"--definitions",
			"types/globalTypes.d.luau",
			"--sourcemap",
			"sourcemap.json",
			"src"
		)
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
	}
	default {
		throw "Unknown command '$Command'. Use serve, build, map, check, fix, sync, health, or status."
	}
}
