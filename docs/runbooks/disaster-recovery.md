# Disaster Recovery

This runbook protects Studio-only content and restores the command center after local damage.

## Studio-Only Snapshots

Rojo owns source files, but Studio can still contain terrain, lighting edits, plugin-created instances, and other content that does not sync back cleanly.

Before large Studio edits:

1. Stop Nexus watchers.
2. In Studio, use `File > Save to File`.
3. Save a dated snapshot under:

```text
C:\Users\jackw\Roblox\RobloxGameVault\80_Archives\StudioSnapshots
```

Recommended filename:

```text
nexus_YYYY-MM-DD_HHMM_before-change.rbxl
```

## If Studio Content Is Lost

1. Stop Rojo serve and automation loops.
2. Copy the latest known-good `.rbxl` snapshot to a recovery folder.
3. Open the copy in Studio.
4. Reconnect Rojo only after confirming the Studio-only content is present.
5. Export any source-owned scripts back into Nexus intentionally, then run the quality gate.

## If The Nexus Repo Is Damaged

```powershell
cd C:\Users\jackw\Roblox
git clone <private-nexus-url> nexus-recovery
cd nexus-recovery
rokit install
wally install
./nexus.ps1 check
```

Do not copy files from a damaged repo until `git status --short` has been reviewed.

## If The Vault Is Damaged

```powershell
cd C:\Users\jackw\Roblox
git clone <private-vault-url> RobloxGameVault-recovery
```

Copy generated notes only after rerunning:

```powershell
./nexus.ps1 sync
./nexus.ps1 health
```
