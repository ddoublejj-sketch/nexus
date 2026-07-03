# G3 - Obsidian Dashboard Proof Receipt

status: pending
gate: G3
updated: TODO

## Completion Rule

Change each required marker from `PENDING` to `PASS` only after the human action has actually been performed and verified. Do not paste secrets, tokens, API keys, universe IDs, or place IDs into this file.

## Required Markers

- Dashboard rendered in Obsidian: PENDING

## Human Steps

- Open `C:\Users\jackw\Roblox\RobloxGameVault` as an Obsidian vault.
- Enable Local REST API, Obsidian Git, Dataview, Tasks, Kanban, Templater, QuickAdd, and Omnisearch.
- Create `secrets/obsidian.env`; never paste key values into this receipt.
- Confirm the dashboard renders Dataview and Tasks sections.

## Evidence Notes

- Paste non-secret observations here after the gate is complete.
- Include command output only if it does not reveal secrets or private IDs.

## Proof Commands

```powershell
lune run tools/vault_ping.luau
./nexus.ps1 loop --once
git -C C:\Users\jackw\Roblox\RobloxGameVault status --short
./nexus.ps1 gatecheck --gate G3
```
