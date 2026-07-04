# G4 - GitHub CI Proof Receipt

status: pending
gate: G4
updated: TODO

## Completion Rule

Change each required marker from `PENDING` to `PASS` only after the human action has actually been performed and verified. Do not paste secrets, tokens, API keys, universe IDs, or place IDs into this file.

## Required Markers

- CI branch protection confirmed: PENDING

## Human Steps

- Approve exporting `RobloxGameVault` vault notes to a private GitHub repo before the vault push runs.
- Upgrade GitHub to Pro or make `ddoublejj-sketch/nexus` public if GitHub blocks branch protection on the private repo.
- Confirm branch protection requires the Nexus CI quality gate.

## Evidence Notes

- Paste non-secret observations here after the gate is complete.
- Include command output only if it does not reveal secrets or private IDs.

## Proof Commands

```powershell
gh auth status
./nexus.ps1 github-ci
./nexus.ps1 github-ci --create-vault-private
gh pr checks
./nexus.ps1 gatecheck --gate G4
```
