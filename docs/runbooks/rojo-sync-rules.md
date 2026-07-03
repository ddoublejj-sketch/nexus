# Rojo Sync Rules

WO-2 proves the daily Studio bridge. The command center treats disk-owned source as canonical and records Studio-only content separately.

## Source-Owned Content

| Content | Direction | Status | Rule |
| --- | --- | --- | --- |
| Luau modules and scripts under `src/` | Disk to Studio | Ready | Edit in Nexus, sync through Rojo. Do not edit these in Studio as the long-term source of truth. |
| Wally packages | Disk to Studio | Ready | Regenerate with `wally install`; never edit generated package folders. |
| Shared config modules | Disk to Studio | Ready | All tunable game numbers live in `src/ReplicatedStorage/Shared/Config`. |
| Cmdr command modules | Disk to Studio | Ready | Command docs are generated from file headers by `tools/command_registry.luau`. |

## Studio-Owned Or Snapshot Content

| Content | Direction | Status | Rule |
| --- | --- | --- | --- |
| Terrain | Studio snapshot | Pending G2 test | Save a dated `.rbxl` snapshot before and after major terrain edits. |
| CSG / unions | Studio snapshot | Pending G2 test | Keep source meshes in `assets_src` where possible; snapshot Studio-only unions. |
| MeshPart placement and tuned properties | Hybrid | Pending G2 test | Track reusable meshes in `assets_export/manifests/assets.json`; snapshot hand-placed scene layout. |
| Lighting and atmosphere tuning | Studio snapshot | Pending G2 test | Record important settings in a vault note and preserve a `.rbxl` snapshot. |
| Disposable syncback test object | Studio to disk test | Pending G2 test | Create only during G2, then record what survived round-trip and delete it. |

## G2 Test Steps

1. Start `./nexus.ps1 serve`.
2. Connect the Rojo Studio plugin to the local server.
3. Edit `src/ServerScriptService/Server/Services/NexusService.luau` on disk.
4. Confirm the change appears in Studio within seconds.
5. Create one disposable Studio object, attempt syncback/export, and record the result in this table.
6. Run:

```powershell
$env:ROKIT_PROBE='1'; rojo sourcemap default.project.json -o sourcemap.json
$env:ROKIT_PROBE='1'; luau-lsp analyze --definitions types/globalTypes.d.luau --sourcemap sourcemap.json src
```

Expected analyze result: exit 0 with no diagnostics.

## Snapshot Location

Studio-only snapshots live in:

```text
C:\Users\jackw\Roblox\RobloxGameVault\80_Archives\StudioSnapshots
```

Use filenames like:

```text
nexus_YYYY-MM-DD_HHMM_reason.rbxl
```
