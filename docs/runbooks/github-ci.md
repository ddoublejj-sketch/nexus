# GitHub CI Runbook

Status: Nexus workflow, private remote, push, and CI are green. Remaining G4 items are the separate private vault remote and branch protection.

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

## Current G4 State

- GitHub CLI auth is complete.
- Nexus `origin` points to the private GitHub repo.
- Nexus CI is running the shared quality gate and the latest pushed run is green.
- `RobloxGameVault` is committed locally, but has no GitHub remote yet.
- Creating/pushing the vault repo exports Obsidian notes to GitHub and needs explicit founder approval.
- Branch protection cannot currently be enabled on the private Nexus repo unless the account has GitHub Pro or the repo is made public.

## G4 Remaining Work

Read-only readiness check:

```powershell
./nexus.ps1 github-ci
```

If GitHub auth is ever lost, restore it first:

```powershell
gh auth login
```

After explicit approval to export vault notes to GitHub:

```powershell
./nexus.ps1 github-ci --create-vault-private
```

If the Nexus remote ever needs to be recreated from scratch, the repeatable helper remains:

```powershell
./nexus.ps1 github-ci --create-private
```

Then enable branch protection on `master` so the `Nexus CI / Quality Gate` job is required before merge. If GitHub returns `Upgrade to GitHub Pro or make this repository public`, either upgrade the account or make the repo public before marking the G4 receipt.
