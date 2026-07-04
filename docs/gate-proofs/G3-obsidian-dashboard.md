# G3 - Obsidian Dashboard Proof Receipt

status: pass
gate: G3
updated: 2026-07-04T00:27:00Z

## Completion Rule

Change each required marker from `PENDING` to `PASS` only after the human action has actually been performed and verified. Do not paste secrets, tokens, API keys, universe IDs, or place IDs into this file.

## Required Markers

- Dashboard rendered in Obsidian: PASS

## Human Steps

- Open `C:\Users\jackw\Roblox\RobloxGameVault` as an Obsidian vault.
- Confirm the preinstalled plugins load: Local REST API, Obsidian Git, Dataview, Tasks, Kanban, Templater, QuickAdd, and Omnisearch.
- Create `secrets/obsidian.env`; never paste key values into this receipt.
- Confirm the dashboard renders Dataview and Tasks sections.

## Evidence Notes

- Verified Obsidian window title `Dashboard - RobloxGameVault - Obsidian 1.12.7`.
- Visual check showed the `00_Command_Center / Dashboard` note open in the real `RobloxGameVault` vault, with the command-center folder tree visible.
- Obsidian REST key values were not pasted into this receipt.

## Proof Commands

```powershell
lune run tools/vault_ping.luau
./nexus.ps1 loop --once
git -C C:\Users\jackw\Roblox\RobloxGameVault status --short
./nexus.ps1 gatecheck --gate G3
```
