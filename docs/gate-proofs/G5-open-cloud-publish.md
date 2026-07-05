# G5 - Open Cloud Publish Approval Proof Receipt

status: accepted
gate: G5
updated: 2026-07-05T15:04:00Z

## Completion Rule

Change each required marker from `PENDING` to `PASS` only after the human action has actually been performed and verified. Do not paste secrets, tokens, API keys, universe IDs, or place IDs into this file.

## Required Markers

- Live publish approval recorded: PASS

## Human Steps

- Create the smallest-scope Open Cloud key needed to publish the target place.
- Create `secrets/opencloud.env`; never paste key, universe ID, or place ID values into this receipt.
- Approve live publish only after fixture and real dry-runs pass.

## Evidence Notes

- 2026-07-05: Founder explicitly approved G5 live publish to Golf Pro in Codex chat.
- 2026-07-05: Fixture dry-run and full local quality gate passed immediately before the live publish attempt.
- 2026-07-05: Live publish request reached Roblox Open Cloud but was rejected with `401 Unauthorized` because the API key has insufficient scopes. No secret, universe ID, or place ID was written here.
- 2026-07-05: Rewrote the local Open Cloud env file as UTF-8 without BOM after the Golf Pro key swap; G5 config, real dry-run, and approval checks then passed, but the live retry still returned `401 Unauthorized` for insufficient API key scopes.
- 2026-07-05: After the Open Cloud key scope was corrected and Roblox Studio was closed, `./nexus.ps1 release --live` returned `Open Cloud publish PASS` for Golf Pro. Secrets, universe ID, place ID, and response body were not written here.

## Proof Commands

```powershell
./nexus.ps1 release --dry-run --fixture
lune run tools/open_cloud_publish.luau --dry-run
lune run tools/secret_scan.luau
./nexus.ps1 gatecheck --gate G5
./nexus.ps1 release --live
```
