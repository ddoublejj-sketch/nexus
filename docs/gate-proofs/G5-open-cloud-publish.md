# G5 - Open Cloud Publish Approval Proof Receipt

status: pending
gate: G5
updated: TODO

## Completion Rule

Change each required marker from `PENDING` to `PASS` only after the human action has actually been performed and verified. Do not paste secrets, tokens, API keys, universe IDs, or place IDs into this file.

## Required Markers

- Live publish approval recorded: PENDING

## Human Steps

- Create the smallest-scope Open Cloud key needed to publish the target place.
- Create `secrets/opencloud.env`; never paste key, universe ID, or place ID values into this receipt.
- Approve live publish only after fixture and real dry-runs pass.

## Evidence Notes

- Paste non-secret observations here after the gate is complete.
- Include command output only if it does not reveal secrets or private IDs.

## Proof Commands

```powershell
./nexus.ps1 release --dry-run --fixture
lune run tools/open_cloud_publish.luau --dry-run
lune run tools/secret_scan.luau
./nexus.ps1 gatecheck --gate G5
```
