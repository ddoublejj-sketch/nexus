# Rojo Sync Rules

WO-2 proves the daily Studio bridge. The command center treats disk-owned source as canonical and records Studio-only content separately.

## Source-Owned Content

| Content | Direction | Status | Rule |
| --- | --- | --- | --- |
| Luau modules and scripts under `src/` | Disk to Studio | Ready | Edit in Nexus, sync through Rojo. Do not edit these in Studio as the long-term source of truth. |
| Wally packages | Disk to Studio | Ready | Regenerate with `wally install`; never edit generated package folders. |
| Shared config modules | Disk to Studio | Ready | All tunable game numbers live in `src/ReplicatedStorage/Shared/Config`. |
| Cmdr command modules | Disk to Studio | Ready | Command docs are generated from file headers by `tools/command_registry.luau`. |
| Rojo-managed maps under `maps/` | Disk to Studio | Ready | Place reusable map models under `maps/`; `MapService.reload` clones them from `ServerStorage.Maps` into `Workspace.Map`. |

## Studio-Owned Or Snapshot Content

| Content | Direction | Status | Rule |
| --- | --- | --- | --- |
| Terrain | Studio snapshot | Pending G2 test | Save a dated `.rbxl` snapshot before and after major terrain edits. |
| CSG / unions | Studio snapshot | Pending G2 test | Keep source meshes in `assets_src` where possible; snapshot Studio-only unions. |
| MeshPart placement and tuned properties | Hybrid | Pending G2 test | Track reusable meshes in `assets_export/manifests/assets.json`; snapshot hand-placed scene layout. |
| Lighting and atmosphere tuning | Studio snapshot | Pending G2 test | Record important settings in a vault note and preserve a `.rbxl` snapshot. |
| Disposable syncback test object | Studio to disk test | Pending G2 test | Create only during G2, then record what survived round-trip and delete it. |

## G2 Test Steps

1. Start `./nexus.ps1 up` and leave it running between work orders unless the founder explicitly asks for shutdown. Use `./nexus.ps1 serve` only for a foreground Rojo-only session.
2. Run `./nexus.ps1 studio-bridge` to confirm the project, sourcemap, runbook, snapshot archive, local Rojo server, Studio process, and G2 receipt state.
3. Connect the Rojo Studio plugin to the local server.
4. Edit `src/ServerScriptService/Server/Services/NexusService.luau` on disk.
5. Confirm the change appears in Studio within seconds.
6. Create one disposable Studio object, attempt syncback/export, and record the result in this table.
7. Run:

```powershell
./nexus.ps1 map --once
luau-lsp analyze --definitions types/globalTypes.d.luau --sourcemap sourcemap.json src
```

Expected analyze result: exit 0 with no diagnostics.

## G2 Accepted Results

- 2026-07-05: Rojo 7.7.0 connected to `GOLF PRO - Roblox Studio` through the `Nexus` session at `localhost:34872`.
- 2026-07-05: Studio playtest loaded Rojo-managed Nexus services from disk. Output showed Nexus server/client startup, DataService mock mode, MapService, Cmdr service, and Cmdr client online.
- 2026-07-05: Disposable Studio-only syncback/export remains a project-content workflow, not a blocker for the command-center bridge.
- 2026-07-05: `MapService.start()` auto-loads `ServerStorage.Maps.Default` and creates a minimal starter pad/spawn if that default map is empty, so Studio Play mode has a safe surface before Phase 4 builds the full course.

## Snapshot Location

Studio-only snapshots live in:

```text
C:\Users\jackw\Roblox\RobloxGameVault\80_Archives\StudioSnapshots
```

Use filenames like:

```text
nexus_YYYY-MM-DD_HHMM_reason.rbxl
```
