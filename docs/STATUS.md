# Nexus Command Center Status

Last updated: 2026-07-03

## Current Phase

WO-0 is in progress and blocked on **G1 - GUI installs**. WO-1 bootstrap work is partially complete, but WO-1 cannot be marked complete until the exact `./nexus.ps1 check` acceptance command can run. WO-2 now has the sync-rules runbook and sourcemap-aware analyze proof, but live Studio sync remains blocked on **G2 - Studio connect**. WO-3 vault scaffolding has started and is blocked on **G3 - Obsidian plugins + REST key** for end-to-end REST verification. WO-4 automation scripts have direct-run proof including dummy-service and stale-note evidence, but exact launcher/dashboard acceptance remains gated. WO-5 asset pipeline has direct-run proof with seed assets, but remains downstream of the still-open WO-4 formal acceptance. WO-6 Cmdr integration has build/analyze proof, but in-Studio command execution remains gated. WO-7 data/networking baseline has direct local proof, but live ProfileStore session behavior remains Studio-gated. WO-8 CI workflow and shared local/CI gate are created, but remote GitHub setup is blocked on **G4 - GitHub auth**. WO-9 release-path dry-run tooling is created and locally verified; live publish remains gated on **G5 - Open Cloud key**. WO-10 daily-driver hardening is implemented locally; exact `./nexus.ps1 up/down` and cold-boot Studio acceptance remain blocked by PowerShell policy and G2.

## WO-0 - Close the Tool Gaps

### Audit Output

```powershell
git --version
git version 2.54.0.windows.1
```

```powershell
rokit --version
rokit 1.2.0
```

```powershell
rojo --version
command timed out after 10635 milliseconds
```

Direct Rokit shim check:

```powershell
C:\Users\jackw\.rokit\bin\rojo.exe --version
ERROR Failed to find tool 'rojo' in any project manifest file.
Add the tool to a project using 'rokit add' before running it.
```

```powershell
code --version
code : The term 'code' is not recognized as the name of a cmdlet, function, script file, or operable program.
```

```powershell
gh --version
gh : The term 'gh' is not recognized as the name of a cmdlet, function, script file, or operable program.
```

```powershell
Get-Command blender -ErrorAction SilentlyContinue
<no output>
```

```powershell
Get-Process blender -ErrorAction SilentlyContinue | Select-Object -Property Id,ProcessName,Path
<no output>
```

```powershell
winget --version
winget : The term 'winget' is not recognized as the name of a cmdlet, function, script file, or operable program.
```

```powershell
Get-AppxPackage Microsoft.DesktopAppInstaller
<no output>
```

Standard install location checks:

```text
C:\Users\jackw\AppData\Local\Programs\Microsoft VS Code\bin\code.cmd = False
C:\Program Files\Microsoft VS Code\bin\code.cmd = False
C:\Program Files\Blender Foundation = False
C:\Users\jackw\AppData\Local\Programs\Obsidian\Obsidian.exe = False
```

Seed asset files confirmed for WO-5:

```text
C:\Users\jackw\Desktop\Claude Code\EnergyShard.fbx
C:\Users\jackw\Desktop\Claude Code\GlowRing_A.fbx
C:\Users\jackw\Desktop\Claude Code\GlowRing_B.fbx
C:\Users\jackw\Desktop\Claude Code\Greatsword.fbx
```

### Human Gate G1 Request

Please install or repair the GUI/tooling prerequisites that cannot currently be completed from this shell:

1. Install **App Installer / winget**, or otherwise make `winget` available on PATH.
2. Install **Visual Studio Code** and enable the `code` command on PATH.
3. Install **GitHub CLI** and make `gh` available on PATH.
4. Install **Obsidian**.
5. Install **Blender**, or provide the absolute path to `blender.exe`.

After this, rerun WO-0 acceptance:

```powershell
git --version
rokit --version
rojo --version
code --version
gh --version
Get-Command blender -ErrorAction SilentlyContinue
```

### Open Notes

- `rojo` is present as a Rokit-managed shim, but it cannot report a version until the Nexus repo has a Rokit project manifest. WO-1 will create that manifest and rerun the check inside the repo.
- No WO-0 acceptance item is marked complete yet because the full command list has not passed.

## WO-1 - Bootstrap the Nexus Repo

### Shipped So Far

- Created `C:\Users\jackw\Roblox\nexus` as a Git repo.
- Added `rokit.toml`, `wally.toml`, `selene.toml`, `stylua.toml`, `.luaurc`, `.env.example`, `.gitignore`, and VS Code task/settings files.
- Added `nexus.ps1` launcher with subcommands: `serve`, `build`, `map`, `check`, `fix`, `sync`, `health`, `status`.
- Added tracked placeholders for empty target-layout lanes:
  - `maps/.gitkeep`
  - `src/ServerStorage/Assets/.gitkeep`
  - `src/StarterGui/UI/.gitkeep`
- Added minimal Roblox scaffold:
  - `Shared/Config/GameConfig.luau`
  - `Shared/Net/init.luau`
  - `Server/Services/NexusService.luau`
  - `Server/init.server.luau`
  - `Client/Controllers/NexusController.luau`
  - `Client/init.client.luau`
- Added upstream luau-lsp Roblox definitions at `types/globalTypes.d.luau` so standalone analyzer has Roblox API types.
- Recorded locked decisions and exact tool pins in `docs/architecture/DECISIONS.md`.

### Tool Pins

```toml
rojo = "rojo-rbx/rojo@7.7.0"
wally = "UpliftGames/wally@0.3.2"
lune = "lune-org/lune@0.10.5"
selene = "Kampfkarren/selene@0.31.0"
stylua = "JohnnyMorganz/StyLua@2.5.2"
luau-lsp = "JohnnyMorganz/luau-lsp@1.68.1"
```

### Acceptance Evidence

```powershell
rokit install
<exit 0; no output>
```

Exact command currently fails in the managed shell because the Rokit shims intermittently fail with `os error 3`:

```powershell
wally install
ERROR The system cannot find the path specified. (os error 3)
```

Same pinned project tool succeeds when the Rokit shim resolves in a PowerShell process with an environment variable set:

```powershell
$env:ROKIT_PROBE='1'; wally install
<exit 0; no output>
```

```powershell
$env:ROKIT_PROBE='1'; rojo build default.project.json -o build/nexus.rbxl
Building project 'Nexus'
Built project to nexus.rbxl
```

Build artifact:

```text
C:\Users\jackw\Roblox\nexus\build\nexus.rbxl
Length: 3089 bytes
```

```powershell
$env:ROKIT_PROBE='1'; rojo sourcemap default.project.json -o sourcemap.json
Created sourcemap at sourcemap.json
```

Quality gate components:

```powershell
$env:ROKIT_PROBE='1'; stylua --check src tools
<exit 0; no output>
```

```powershell
$env:ROKIT_PROBE='1'; selene src
Results:
0 errors
0 warnings
0 parse errors
```

```powershell
$env:ROKIT_PROBE='1'; luau-lsp analyze --definitions types/globalTypes.d.luau --sourcemap sourcemap.json src
[INFO] Loading definitions file: @roblox - types/globalTypes.d.luau
[WARN] client does not allow didChangeWatchedFiles registration - automatic updating on sourcemap changes disabled
[INFO] Loading Luau configuration from c:\Users\jackw\Roblox\nexus\.luaurc
```

Exact launcher command is blocked by Windows script execution policy:

```powershell
./nexus.ps1 check
./nexus.ps1 : File C:\Users\jackw\Roblox\nexus\nexus.ps1 cannot be loaded because running scripts is disabled on this system.
FullyQualifiedErrorId : UnauthorizedAccess
```

Commit history:

```powershell
git log --oneline
3909c51 Add Nexus hello world service scaffold
d0e69e1 Bootstrap Nexus command center scaffold
```

### Open Blockers

- **PowerShell execution policy:** `./nexus.ps1` cannot run until the user explicitly approves a user-level policy change such as `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned -Force`, or chooses another approved launcher strategy. A request to change it was rejected by the safety layer because the user has not explicitly approved that exact persistent security change.
- **Rokit shim behavior in managed shell:** bare `wally`, `rojo`, `stylua`, `selene`, `lune`, and `luau-lsp` commands can fail with `os error 3` in this shell. The pinned binaries are installed and work; `nexus.ps1` resolves them directly once script execution is allowed.

WO-1 is **not complete** until the exact acceptance commands pass, especially `./nexus.ps1 check`.

## WO-3 - Obsidian Command Vault

### Shipped So Far

- Created vault repo at `C:\Users\jackw\Roblox\RobloxGameVault`.
- Created the source-report folder layout:
  - `00_Command_Center`
  - `01_Game_Design`
  - `02_Systems`
  - `03_World_And_Maps`
  - `04_Assets`
  - `05_Playtests`
  - `06_Engineering`
  - `90_Automation`
  - `99_Inbox`
- Added dashboard, current sprint, daily dev log, build health stub, system notes, map/asset indexes, package inventory, sourcemap note, and architecture decision mirror.
- Added templates for asset, map, system, decision, bug, and playtest notes using the approved frontmatter schema.
- Initialized the vault as a separate Git repo and made its first commit.
- Added `tools/vault_ping.luau`, which writes `90_Automation/Generated/Ping.md` through Obsidian Local REST API once `secrets/obsidian.env` exists.

### Human Gate G3 Request

Please complete Obsidian setup when G1 installs are done:

1. Open `C:\Users\jackw\Roblox\RobloxGameVault` as an Obsidian vault.
2. Enable community plugins.
3. Install and enable:
   - Local REST API
   - Obsidian Git
   - Dataview
   - Tasks
   - Kanban
   - Templater
   - QuickAdd
   - Omnisearch
4. Copy the Local REST API key into `C:\Users\jackw\Roblox\nexus\secrets\obsidian.env`.

Expected local secret file shape:

```env
OBSIDIAN_API_URL=https://127.0.0.1:27124
OBSIDIAN_API_KEY=replace_with_real_key
```

### Evidence

Vault commit:

```powershell
git log --oneline
558bc31 Initialize Roblox game vault
```

Vault status:

```powershell
git status --short
<clean>
```

Vault ping script dry run without secrets:

```powershell
$env:ROKIT_PROBE='1'; lune run tools/vault_ping.luau
C:\Users\jackw\Roblox\nexus\tools/vault_ping:40: Missing Obsidian REST config. Create secrets/obsidian.env with OBSIDIAN_API_URL and OBSIDIAN_API_KEY.
```

Script style/lint:

```powershell
$env:ROKIT_PROBE='1'; stylua --check src tools
<exit 0; no output>
```

```powershell
$env:ROKIT_PROBE='1'; selene src tools
Results:
0 errors
0 warnings
0 parse errors
```

Nexus status after logging:

```powershell
git status --short
<clean before this STATUS update>
```

### Open Blockers

- Obsidian is not installed yet from WO-0/G1, so dashboard rendering cannot be verified.
- Local REST API is not installed or keyed yet, so `tools/vault_ping.luau` cannot be completed or accepted.
- luau-lsp does not currently analyze `tools/*.luau` because it does not know Lune's `@lune/*` runtime imports yet; WO-1 analyzer scope remains `src`.
- WO-3 is **not complete** until `lune run tools/vault_ping.luau` exits 0, `Ping.md` exists with a fresh timestamp, dashboard Dataview tables render, and the vault has committed the generated proof.

## WO-2 - Studio Bridge

### Shipped So Far

- Added `docs/runbooks/rojo-sync-rules.md`.
- Documented disk-owned source, Studio-owned/snapshot content, the G2 test sequence, and the Studio snapshot location.
- The runbook marks live round-trip rows as pending G2 instead of pretending Studio confirmation has happened.

### Sourcemap-Aware Analyze Evidence

```powershell
$env:ROKIT_PROBE='1'; luau-lsp analyze --definitions types/globalTypes.d.luau --sourcemap sourcemap.json src
[INFO] Loading definitions file: @roblox - types/globalTypes.d.luau
[WARN] client does not allow didChangeWatchedFiles registration - automatic updating on sourcemap changes disabled
[INFO] Loading Luau configuration from c:\Users\jackw\Roblox\nexus\.luaurc
```

### Human Gate G2 Request

Please complete when ready:

1. Open the Nexus place in Roblox Studio.
2. Start Rojo serve from Nexus.
3. Click the Rojo Studio plugin and connect to the local server.
4. Confirm a disk edit appears in Studio within seconds.
5. Create one disposable Studio object, test what syncback/export preserves, and record the observed result in `docs/runbooks/rojo-sync-rules.md`.

### Open Blockers

- G2 is not complete, so live disk-to-Studio and syncback behavior remains unverified.
- `./nexus.ps1 serve` cannot be run exactly until the PowerShell execution-policy blocker from WO-1 is cleared.

## WO-4 - Live Project Indexer

### Shipped So Far

- Replaced placeholder automation scripts with runnable Lune scripts:
  - `tools/sourcemap_summary.luau`
  - `tools/vault_sync.luau`
  - `tools/command_registry.luau`
  - `tools/build_health.luau`
  - `tools/asset_manifest.luau` skeleton
- Added `./nexus.ps1 loop` and VS Code `Nexus: Loop Once` task. The loop sequence refreshes sourcemap summary, module notes, command registry, asset manifest skeleton, and build health.
- Generated vault notes:
  - `90_Automation/Generated/Sourcemap.md`
  - `02_Systems/Generated Modules/...`
  - `02_Systems/Commands.md`
  - `90_Automation/Generated/Stale Sources.md`
  - `90_Automation/Generated/Asset Manifest.md`
  - `00_Command_Center/Build Health.md`
- Dashboard now embeds `Stale Sources`.

### Direct-Run Evidence

```powershell
$env:ROKIT_PROBE='1'; lune run tools/sourcemap_summary.luau
Wrote 17 sourcemap rows to C:/Users/jackw/Roblox/RobloxGameVault/90_Automation/Generated/Sourcemap.md
```

```powershell
$env:ROKIT_PROBE='1'; lune run tools/command_registry.luau
Wrote 0 command rows to C:/Users/jackw/Roblox/RobloxGameVault/02_Systems/Commands.md
```

```powershell
$env:ROKIT_PROBE='1'; lune run tools/vault_sync.luau
Wrote 5 module notes under C:/Users/jackw/Roblox/RobloxGameVault/02_Systems/Generated Modules and refreshed stale-source report
```

```powershell
$env:ROKIT_PROBE='1'; lune run tools/asset_manifest.luau
Asset manifest skeleton wrote C:/Users/jackw/Roblox/RobloxGameVault/90_Automation/Generated/Asset Manifest.md with 0 manifest rows
```

```powershell
$env:ROKIT_PROBE='1'; lune run tools/build_health.luau
Build health PASS; wrote C:/Users/jackw/Roblox/RobloxGameVault/00_Command_Center/Build Health.md
```

Quality checks after script work:

```powershell
$env:ROKIT_PROBE='1'; stylua --check src tools
<exit 0; no output>
```

```powershell
$env:ROKIT_PROBE='1'; selene src tools
Results:
0 errors
0 warnings
0 parse errors
```

```powershell
$env:ROKIT_PROBE='1'; luau-lsp analyze --definitions types/globalTypes.d.luau --sourcemap sourcemap.json src
[INFO] Loading definitions file: @roblox - types/globalTypes.d.luau
[WARN] client does not allow didChangeWatchedFiles registration - automatic updating on sourcemap changes disabled
[INFO] Loading Luau configuration from c:\Users\jackw\Roblox\nexus\.luaurc
```

Build Health vault note reports:

```text
Overall: PASS
StyLua: PASS
Selene: PASS
Sourcemap: PASS
Analyze: PASS
Build: PASS
```

Stale source report:

```text
No stale generated module notes found.
```

### Dummy Service And Stale-Note Demo

Temporary source created:

```text
src/ServerScriptService/Server/Services/TempIndexerProbeService.luau
```

First sync:

```powershell
$env:ROKIT_PROBE='1'; lune run tools/vault_sync.luau
Wrote 13 module notes under C:/Users/jackw/Roblox/RobloxGameVault/02_Systems/Generated Modules and refreshed stale-source report
```

Generated note proof:

```text
source_path: C:\Users\jackw\Roblox\nexus\src\ServerScriptService\Server\Services\TempIndexerProbeService.luau
studio_instance_path: game.ServerScriptService.Server.Services.TempIndexerProbeService
Public Functions:
- TempIndexerProbeService.start
```

After deleting the temporary source and rerunning sync:

```powershell
$env:ROKIT_PROBE='1'; lune run tools/vault_sync.luau
Wrote 12 module notes under C:/Users/jackw/Roblox/RobloxGameVault/02_Systems/Generated Modules and refreshed stale-source report
```

Stale report proof:

```text
| Note | Missing Source |
| --- | --- |
| `02_Systems/Generated Modules/Services/TempIndexerProbeService.md` | `src/ServerScriptService/Server/Services/TempIndexerProbeService.luau` |
```

Cleanup sync after removing the disposable generated note:

```powershell
$env:ROKIT_PROBE='1'; lune run tools/vault_sync.luau
Wrote 12 module notes under C:/Users/jackw/Roblox/RobloxGameVault/02_Systems/Generated Modules and refreshed stale-source report
```

Final stale-source state:

```text
No stale generated module notes found.
```

### Open Blockers

- WO-4 depends on WO-2 and WO-3 in the master plan. Those are still gated by Studio/Obsidian setup.
- `./nexus.ps1 loop --once` cannot be run until the PowerShell execution policy blocker from WO-1 is cleared.
- The acceptance dummy-service add/rename stale-note demonstration has not been run yet.
- Dashboard rendering still cannot be visually verified until Obsidian is installed and G3 plugins are enabled.

WO-4 is **not complete** until its exact acceptance tests run and pass.

## WO-5 - Asset Pipeline

### Shipped So Far

- Migrated four seed assets from `C:\Users\jackw\Desktop\Claude Code` into Nexus:
  - `EnergyShard.fbx`
  - `GlowRing_A.fbx`
  - `GlowRing_B.fbx`
  - `Greatsword.fbx`
- Added source copies under `assets_src/imported`.
- Added Roblox export copies under `assets_export/roblox`.
- Added placeholder thumbnails under `assets_export/thumbnails`.
- Upgraded `tools/asset_manifest.luau` from a skeleton into a deterministic reconciler that:
  - scans `assets_export/roblox`
  - pairs exports with `assets_src/imported`
  - preserves existing manifest metadata
  - writes `assets_export/manifests/assets.json`
  - writes one vault note per asset in `04_Assets/Models`
  - writes `90_Automation/Generated/Asset Manifest.md`
  - writes `90_Automation/Generated/Asset Thumbnail Backlog.md`
  - repairs missing manifest rows
- Added `docs/runbooks/blender-export.md` with scale, origin, collision proxy, material, and tri-budget conventions.

### Direct-Run Evidence

Seed asset file sizes:

```text
assets_src/imported/EnergyShard.fbx   12524
assets_src/imported/GlowRing_A.fbx    24972
assets_src/imported/GlowRing_B.fbx    22636
assets_src/imported/Greatsword.fbx   165852
assets_export/roblox/EnergyShard.fbx  12524
assets_export/roblox/GlowRing_A.fbx   24972
assets_export/roblox/GlowRing_B.fbx   22636
assets_export/roblox/Greatsword.fbx  165852
```

Manifest reconciliation:

```powershell
$env:ROKIT_PROBE='1'; lune run tools/asset_manifest.luau
Asset manifest reconciled 4 assets; auto-added 4; missing sources 0; missing exports 0
```

Second steady-state run:

```powershell
$env:ROKIT_PROBE='1'; lune run tools/asset_manifest.luau
Asset manifest reconciled 4 assets; auto-added 0; missing sources 0; missing exports 0
```

Manifest rows:

```text
energy_shard_01
glow_ring_a_01
glow_ring_b_01
greatsword_01
```

Vault asset notes:

```text
04_Assets/Models/EnergyShard.md
04_Assets/Models/GlowRing A.md
04_Assets/Models/GlowRing B.md
04_Assets/Models/Greatsword.md
```

Placeholder thumbnails:

```text
assets_export/thumbnails/energy_shard_01.placeholder.txt
assets_export/thumbnails/glow_ring_a_01.placeholder.txt
assets_export/thumbnails/glow_ring_b_01.placeholder.txt
assets_export/thumbnails/greatsword_01.placeholder.txt
```

Orphan repair demonstration:

```powershell
# Temporarily removed the energy_shard_01 row from assets_export/manifests/assets.json, then ran:
$env:ROKIT_PROBE='1'; lune run tools/asset_manifest.luau
Asset manifest reconciled 4 assets; auto-added 1; missing sources 0; missing exports 0
```

Idempotence hash check after the repair settled:

```text
Before and after hashes matched for:
assets_export/manifests/assets.json
90_Automation/Generated/Asset Manifest.md
90_Automation/Generated/Asset Thumbnail Backlog.md
04_Assets/Models/EnergyShard.md
04_Assets/Models/GlowRing A.md
04_Assets/Models/GlowRing B.md
04_Assets/Models/Greatsword.md
```

Quality checks after asset pipeline work:

```powershell
$env:ROKIT_PROBE='1'; stylua --check src tools
<exit 0; no output>
```

```powershell
$env:ROKIT_PROBE='1'; selene src tools
Results:
0 errors
0 warnings
0 parse errors
```

```powershell
$env:ROKIT_PROBE='1'; luau-lsp analyze --definitions types/globalTypes.d.luau --sourcemap sourcemap.json src
[INFO] Loading definitions file: @roblox - types/globalTypes.d.luau
[WARN] client does not allow didChangeWatchedFiles registration - automatic updating on sourcemap changes disabled
[INFO] Loading Luau configuration from c:\Users\jackw\Roblox\nexus\.luaurc
```

```powershell
$env:ROKIT_PROBE='1'; lune run tools/build_health.luau
Build health PASS; wrote C:/Users/jackw/Roblox/RobloxGameVault/00_Command_Center/Build Health.md
```

### Open Blockers

- Blender is still not resolved from WO-0, so real thumbnail rendering is replaced with placeholder thumbnail notes and `Asset Thumbnail Backlog.md`.
- WO-5 is downstream of WO-4 in the master dependency graph. The asset pipeline evidence above is present, but the work order is **not marked complete** until WO-4 formal acceptance clears.

## WO-6 - In-Game Developer Console

### Shipped So Far

- Added Cmdr through Wally:
  - `Cmdr = "evaera/cmdr@1.12.0"`
- Restored Rojo mapping for `ReplicatedStorage.Packages` now that `wally install` creates real package files.
- Added `Shared/Config/Permissions.luau` with tiers:
  - `Owner > Dev > Tester > Player`
- Added `CmdrService` server bootstrap:
  - requires Cmdr
  - registers default utility commands
  - installs a `BeforeRun` permission hook
  - registers command modules from `Server/Commands`
- Added `CmdrController` client bootstrap:
  - waits for replicated `CmdrClient`
  - binds Cmdr to `F2`
  - labels the console `Nexus`
- Added seven command definition/server-handler pairs:
  - `tp`
  - `spawn`
  - `give`
  - `setstat`
  - `reloadmap`
  - `profilewipe`
  - `debugtag`
- `profilewipe` is Owner-tier and also refuses unless the confirm argument is `CONFIRM_WIPE`.
- Updated `tools/command_registry.luau` so it skips `*Server` implementation modules and documents only command definitions.

### Direct-Run Evidence

```powershell
$env:ROKIT_PROBE='1'; wally install
<exit 0; no output>
```

Wally lock:

```toml
[[package]]
name = "evaera/cmdr"
version = "1.12.0"
dependencies = []
```

```powershell
$env:ROKIT_PROBE='1'; rojo build default.project.json -o build/nexus.rbxl
Building project 'Nexus'
Built project to nexus.rbxl
```

Build artifact:

```text
C:\Users\jackw\Roblox\nexus\build\nexus.rbxl
Length: 60268 bytes
```

```powershell
$env:ROKIT_PROBE='1'; lune run tools/command_registry.luau
Wrote 7 command rows to C:/Users/jackw/Roblox/RobloxGameVault/02_Systems/Commands.md
```

Commands.md rows:

```text
debugtag | Tester | player targetPlayer, string tagName, boolean enabled?
give | Dev | players targetPlayers, string itemKey, number amount
profilewipe | Owner | player targetPlayer, string confirm
reloadmap | Dev | string mapName?
setstat | Dev | players targetPlayers, string statKey, number value
spawn | Dev | string assetName, vector3 position?
tp | Dev | players fromPlayers, player @ vector3 destination
```

Quality checks:

```powershell
$env:ROKIT_PROBE='1'; stylua --check src tools
<exit 0; no output>
```

```powershell
$env:ROKIT_PROBE='1'; selene src tools
Results:
0 errors
0 warnings
0 parse errors
```

```powershell
$env:ROKIT_PROBE='1'; luau-lsp analyze --definitions types/globalTypes.d.luau --sourcemap sourcemap.json src
[INFO] Loading definitions file: @roblox - types/globalTypes.d.luau
[WARN] client does not allow didChangeWatchedFiles registration - automatic updating on sourcemap changes disabled
[INFO] Loading Luau configuration from c:\Users\jackw\Roblox\nexus\.luaurc
```

```powershell
$env:ROKIT_PROBE='1'; lune run tools/build_health.luau
Build health PASS; wrote C:/Users/jackw/Roblox/RobloxGameVault/00_Command_Center/Build Health.md
```

### Open Blockers

- Studio playtest execution is still blocked by G2 / Studio connect. Command execution has not been human-verified in a local playtest.
- `profilewipe` permission and confirm behavior is implemented in code, but runtime refusal still needs Studio playtest proof.
- WO-6 is downstream of the still-open formal WO-4/WO-5 acceptance chain, so it is **not marked complete** yet.

## WO-7 - Data & Networking Baseline

### Shipped So Far

- Added ProfileStore through Wally as a server dependency:
  - `ProfileStore = "lm-loleris/profilestore@1.0.3"`
- Added `ServerPackages` Rojo mapping and `.gitignore` rules so Wally regenerates server packages while `wally.lock` stays tracked.
- Added shared data modules:
  - `Shared/Data/ProfileSchema.luau`
  - `Shared/Data/MigrationLogic.luau`
  - `Shared/Data/Migrations.luau`
- Added `DataService`:
  - `StartSessionAsync(tostring(player.UserId), { Cancel = ... })`
  - `AddUserId`
  - `Reconcile`
  - schema migration
  - `OnSessionEnd` cleanup/kick path
  - `PlayerRemoving` release with `EndSession`
  - `getProfile`, `setKey`, `release`, `isMockMode`
  - `ProfileStore.Mock` in Studio
- Upgraded `Shared/Net` into a declared remote boundary with argument validators:
  - `Ping`
  - `RequestProfileSnapshot`
  - `SetDebugFlag`
  - `SystemMessage`
- `DataService` handles `RequestProfileSnapshot` with a sanitized read-only profile snapshot.
- Added Lune migration fixture test at `tools/test_migrations.luau`.
- Updated vault notes:
  - `02_Systems/Save Data.md`
  - `02_Systems/Networking.md`

### Direct-Run Evidence

```powershell
$env:ROKIT_PROBE='1'; wally install
<exit 0; no output>
```

Wally lock:

```toml
[[package]]
name = "lm-loleris/profilestore"
version = "1.0.3"
dependencies = []
```

Migration fixture test:

```powershell
$env:ROKIT_PROBE='1'; lune run tools/test_migrations.luau
Migration fixtures passed
```

```powershell
$env:ROKIT_PROBE='1'; rojo build default.project.json -o build/nexus.rbxl
Building project 'Nexus'
Built project to nexus.rbxl
```

Build artifact:

```text
C:\Users\jackw\Roblox\nexus\build\nexus.rbxl
Length: 88295 bytes
```

```powershell
$env:ROKIT_PROBE='1'; lune run tools/vault_sync.luau
Wrote 12 module notes under C:/Users/jackw/Roblox/RobloxGameVault/02_Systems/Generated Modules and refreshed stale-source report
```

Generated module notes include:

```text
Services/DataService.md
Shared/MigrationLogic.md
Shared/Migrations.md
Shared/Net.md
Shared/ProfileSchema.md
```

Quality checks:

```powershell
$env:ROKIT_PROBE='1'; stylua --check src tools
<exit 0; no output>
```

```powershell
$env:ROKIT_PROBE='1'; selene src tools
Results:
0 errors
0 warnings
0 parse errors
```

```powershell
$env:ROKIT_PROBE='1'; luau-lsp analyze --definitions types/globalTypes.d.luau --sourcemap sourcemap.json src
[INFO] Loading definitions file: @roblox - types/globalTypes.d.luau
[WARN] client does not allow didChangeWatchedFiles registration - automatic updating on sourcemap changes disabled
[INFO] Loading Luau configuration from c:\Users\jackw\Roblox\nexus\.luaurc
```

```powershell
$env:ROKIT_PROBE='1'; lune run tools/build_health.luau
Build health PASS; wrote C:/Users/jackw/Roblox/RobloxGameVault/00_Command_Center/Build Health.md
```

Build Health vault note reports:

```text
Overall: PASS
StyLua: PASS
Selene: PASS
Sourcemap: PASS
Analyze: PASS
Build: PASS
```

### Session Lock Notes

ProfileStore docs state `StartSessionAsync()` can return `nil` if another remote server attempts to start a session for the same profile at the same time. Nexus handles that case by kicking with a rejoin message instead of exposing unsafe shared profile access.

Actual Studio/runtime observation is still pending G2.

### Open Blockers

- Profile load/save and duplicate-session behavior need a Studio/server playtest after G2.
- Live DataStore access is intentionally not used in Studio because `DataService` selects `ProfileStore.Mock`.
- WO-7 is downstream of still-open formal WO-4/WO-5/WO-6 acceptance, so it is **not marked complete** yet.

## WO-8 - CI

### Shipped So Far

- Added shared local/CI gate:
  - `tools/lib/QualityGate.luau`
  - `tools/quality_gate.luau`
- The shared gate creates `build/` before the Rojo build so fresh CI checkouts do not rely on a local output directory.
- Updated `./nexus.ps1 check` so it calls the same shared gate.
- Refactored `tools/build_health.luau` so Build Health also uses the shared gate.
- Added `.github/workflows/ci.yml`.
- Added `docs/runbooks/github-ci.md`.

### Workflow Shape

`.github/workflows/ci.yml` runs on `windows-latest` and:

1. Checks out the repo.
2. Installs Rokit from the official Rokit PowerShell installer.
3. Trusts the pinned project tool providers.
4. Runs `rokit install`.
5. Runs `lune run tools/quality_gate.luau`.
6. Uploads `build/nexus.rbxl`.

### Shared Gate Evidence

```powershell
$env:ROKIT_PROBE='1'; lune run tools/quality_gate.luau
[PASS] Wally Install (0.86s, exit 0)
[PASS] StyLua (0.04s, exit 0)
[PASS] Selene (0.08s, exit 0)
[PASS] Sourcemap (0.08s, exit 0)
[PASS] Migration Tests (0.03s, exit 0)
[PASS] Analyze (1.98s, exit 0)
[PASS] Build (0.08s, exit 0)
Quality gate PASS
```

Individual checks after CI work:

```powershell
$env:ROKIT_PROBE='1'; stylua --check src tools
<exit 0; no output>
```

```powershell
$env:ROKIT_PROBE='1'; selene src tools
Results:
0 errors
0 warnings
0 parse errors
```

```powershell
$env:ROKIT_PROBE='1'; luau-lsp analyze --definitions types/globalTypes.d.luau --sourcemap sourcemap.json src
[INFO] Loading definitions file: @roblox - types/globalTypes.d.luau
[WARN] client does not allow didChangeWatchedFiles registration - automatic updating on sourcemap changes disabled
[INFO] Loading Luau configuration from c:\Users\jackw\Roblox\nexus\.luaurc
```

Build artifact after shared gate:

```text
C:\Users\jackw\Roblox\nexus\build\nexus.rbxl
Length: 88295 bytes
```

Build Health vault note now reports:

```text
Overall: PASS
Wally Install: PASS
StyLua: PASS
Selene: PASS
Sourcemap: PASS
Migration Tests: PASS
Analyze: PASS
Build: PASS
```

### Human Gate G4 Request

Please complete when ready:

1. Install GitHub CLI from G1 if it is not yet available.
2. Run `gh auth login`.
3. Create/push private repos for:
   - `nexus`
   - `RobloxGameVault`
4. Enable branch protection on `main` so the Nexus CI quality gate is required before merge.

### Open Blockers

- `gh` is still unavailable from WO-0/G1, so GitHub auth, repo creation, push, and branch protection cannot be completed.
- The workflow has not run on GitHub yet.
- The deliberate failing/fixed PR acceptance check cannot be demonstrated until the remote repo exists and G4 is complete.
- WO-8 is **not marked complete** until CI has a real GitHub run and branch protection evidence.

## WO-9 - Release Path

### Shipped So Far

- Added `tools/open_cloud_publish.luau`.
- Added fixture config at `tools/fixtures/opencloud.env`.
- Added `docs/runbooks/release-checklist.md`.
- Added `./nexus.ps1 release`.
- Added `Open Cloud Dry Run` to the shared quality gate, so local checks, CI, and Build Health verify the release path without a real key.

### Dry-Run Evidence

```powershell
$env:ROKIT_PROBE='1'; lune run tools/open_cloud_publish.luau --dry-run --fixture
Open Cloud publish dry-run PASS
Mode: dry-run
Config source: tools/fixtures/opencloud.env (fixture)
Artifact: build/nexus.rbxl (88295 bytes)
Universe ID: 1234567890
Place ID: 9876543210
Endpoint: https://apis.roblox.com/universes/v1/1234567890/places/9876543210/versions?versionType=Published
Live request was not sent.
```

### Shared Gate Evidence After WO-9

```powershell
$env:ROKIT_PROBE='1'; lune run tools/quality_gate.luau
[PASS] Wally Install (0.70s, exit 0)
[PASS] StyLua (0.05s, exit 0)
[PASS] Selene (0.08s, exit 0)
[PASS] Sourcemap (0.09s, exit 0)
[PASS] Migration Tests (0.03s, exit 0)
[PASS] Analyze (2.01s, exit 0)
[PASS] Build (0.10s, exit 0)
[PASS] Open Cloud Dry Run (0.03s, exit 0)
Quality gate PASS
```

Build Health vault note now reports:

```text
Overall: PASS
Wally Install: PASS
StyLua: PASS
Selene: PASS
Sourcemap: PASS
Migration Tests: PASS
Analyze: PASS
Build: PASS
Open Cloud Dry Run: PASS
```

### Secret History Scan

```powershell
git log -p -- secrets .env | Select-String -Pattern "key|token"
<no output>
```

### Human Gate G5 Request

When ready to publish for real:

1. Create the minimally scoped Open Cloud key in Creator Hub.
2. Place it only in `C:\Users\jackw\Roblox\nexus\secrets\opencloud.env`.
3. Include numeric `ROBLOX_UNIVERSE_ID` and `ROBLOX_PLACE_ID` in that same local secret file.
4. Run the fixture dry-run first, then run `lune run tools/open_cloud_publish.luau --live`.

### Open Blockers

- G5 is not complete, so live publish was intentionally not attempted.
- `./nexus.ps1 release` cannot be run exactly until the PowerShell execution-policy blocker from WO-1 is cleared.

## WO-10 - Command Center Hardening

### Shipped So Far

- Added `./nexus.ps1 up`.
- Added `./nexus.ps1 down`.
- Added job status table output to `./nexus.ps1 status`.
- Added `tools/dev_log.luau` for session start/end/snapshot logging into the vault Daily Dev Log.
- Added VS Code tasks for Up, Down, and Release Dry Run.
- Added `docs/runbooks/fresh-machine-setup.md`.
- Added `docs/runbooks/disaster-recovery.md`.
- Added vault snapshot archive placeholder at `80_Archives/StudioSnapshots/.gitkeep`.

### Verification Evidence

PowerShell syntax parse only, without executing the blocked launcher:

```powershell
$errors = $null; [void][System.Management.Automation.PSParser]::Tokenize((Get-Content -LiteralPath ".\nexus.ps1" -Raw), [ref]$errors); if ($errors -and $errors.Count -gt 0) { $errors | ForEach-Object { "$($_.Message) at $($_.StartLine):$($_.StartColumn)" }; exit 1 } else { "PowerShell parse PASS" }
PowerShell parse PASS
```

VS Code task file parse:

```powershell
Get-Content -LiteralPath ".\.vscode\tasks.json" -Raw | ConvertFrom-Json | Out-Null; "tasks.json parse PASS"
tasks.json parse PASS
```

Direct daily log verification:

```powershell
$env:ROKIT_PROBE='1'; lune run tools/dev_log.luau start
Dev log appended: C:/Users/jackw/Roblox/RobloxGameVault/00_Command_Center/Daily Dev Log.md (Session Start)
```

```powershell
$env:ROKIT_PROBE='1'; lune run tools/dev_log.luau end
Dev log appended: C:/Users/jackw/Roblox/RobloxGameVault/00_Command_Center/Daily Dev Log.md (Session End)
```

```powershell
$env:ROKIT_PROBE='1'; lune run tools/dev_log.luau snapshot
Dev log appended: C:/Users/jackw/Roblox/RobloxGameVault/00_Command_Center/Daily Dev Log.md (Snapshot)
```

Full gate after WO-10:

```powershell
$env:ROKIT_PROBE='1'; lune run tools/quality_gate.luau
[PASS] Wally Install (0.72s, exit 0)
[PASS] StyLua (0.05s, exit 0)
[PASS] Selene (0.08s, exit 0)
[PASS] Sourcemap (0.09s, exit 0)
[PASS] Migration Tests (0.03s, exit 0)
[PASS] Analyze (1.99s, exit 0)
[PASS] Build (0.08s, exit 0)
[PASS] Open Cloud Dry Run (0.03s, exit 0)
Quality gate PASS
```

Build Health vault note after WO-10:

```text
Overall: PASS
Wally Install: PASS
StyLua: PASS
Selene: PASS
Sourcemap: PASS
Migration Tests: PASS
Analyze: PASS
Build: PASS
Open Cloud Dry Run: PASS
```

### Exact Acceptance Blockers

- `./nexus.ps1 up` and `./nexus.ps1 down` cannot be executed exactly until the PowerShell execution-policy blocker from WO-1 is cleared.
- The cold-boot flow cannot prove Studio updates until G2 Studio plugin connect is complete.
- Vault dashboard rendering still needs G3 Obsidian plugins.

## Acceptance Matrix

| Work Order | Local Status | Evidence In This File | Remaining Gate / Blocker |
| --- | --- | --- | --- |
| WO-0 Tool Gaps | Partial | Audit output under WO-0 | G1: `winget`, `code`, `gh`, Obsidian, Blender on PATH/install path |
| WO-1 Bootstrap | Implemented, exact launcher blocked | Repo scaffold, tool pins, direct quality outputs | PowerShell execution policy blocks exact `./nexus.ps1 check` |
| WO-2 Studio Bridge | Runbook added, live bridge blocked | Sourcemap-aware analyze output and `docs/runbooks/rojo-sync-rules.md` | G2: Studio plugin connect and live sync proof |
| WO-3 Vault | Scaffolded, REST blocked | Vault repo, templates, dry-run failure output | G3: Obsidian install, plugins, Local REST API key |
| WO-4 Automation Loop | Implemented with direct-run proof | Sourcemap, vault sync, dummy/stale-note demo, command registry, asset manifest, Build Health outputs | Exact `./nexus.ps1 loop --once` blocked by PowerShell policy; dashboard render needs G3 |
| WO-5 Asset Pipeline | Implemented with seed assets | Manifest, orphan repair, vault asset notes | Formal acceptance downstream of WO-4/G3 visual checks |
| WO-6 Cmdr | Implemented and analyzed | Cmdr service/controller, commands, generated command docs | G2 Studio playtest for command execution |
| WO-7 Data/Networking | Implemented and tested locally | ProfileStore wrapper, migration tests, typed Net, Build Health | G2 Studio playtest for session/runtime behavior |
| WO-8 CI | Local workflow committed | Shared gate output, workflow, runbook | G4: `gh auth`, remote repo, branch protection, real CI run |
| WO-9 Release Path | Dry-run accepted locally | Fixture dry-run, secret-history scan, release checklist | G5 for live publish only |
| WO-10 Hardening | Implemented locally | Parse check, task JSON parse, dev log writes, full gate | PowerShell policy, G2 Studio connect, G3 dashboard render for cold-boot acceptance |

## Latest Whole-Repo Verification

```powershell
$env:ROKIT_PROBE='1'; lune run tools/quality_gate.luau
[PASS] Wally Install (0.76s, exit 0)
[PASS] StyLua (0.05s, exit 0)
[PASS] Selene (0.08s, exit 0)
[PASS] Sourcemap (0.09s, exit 0)
[PASS] Migration Tests (0.03s, exit 0)
[PASS] Analyze (1.99s, exit 0)
[PASS] Build (0.08s, exit 0)
[PASS] Open Cloud Dry Run (0.03s, exit 0)
Quality gate PASS
```

```powershell
$env:ROKIT_PROBE='1'; lune run tools/build_health.luau
Build health PASS; wrote C:/Users/jackw/Roblox/RobloxGameVault/00_Command_Center/Build Health.md
```
