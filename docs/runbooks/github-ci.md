# GitHub CI Runbook

Status: workflow created; remote repository and branch protection are blocked on G4.

## Local And CI Gate

The shared gate is `tools/quality_gate.luau`.

Local launcher path:

```powershell
./nexus.ps1 check
```

Direct path for CI and troubleshooting: `lune run tools/quality_gate.luau`.

CI path:

```yaml
- run: lune run tools/quality_gate.luau
```

## CI Steps

The workflow at `.github/workflows/ci.yml` runs on Windows and:

1. Checks out the repo.
2. Installs Rokit from the official Rokit PowerShell installer.
3. Trusts the six pinned project tool providers.
4. Runs `rokit install`.
5. Runs the shared quality gate.
6. Uploads `build/nexus.rbxl`.

## G4 Remaining Work

After GitHub CLI is installed and authenticated:

```powershell
gh auth login
./nexus.ps1 github-ci
gh repo create nexus --private --source . --remote origin --push
./nexus.ps1 github-ci
```

Then enable branch protection on `main` so `Nexus CI / Quality Gate` is required before merge.
The repeatable helper is read-only by default; after auth, `./nexus.ps1 github-ci --create-private`
can create and push the private `origin` remote explicitly.
