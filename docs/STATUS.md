# Nexus Command Center Status

Last updated: 2026-07-03

## Current Phase

WO-0 is in progress and blocked on **G1 - GUI installs**. WO-1 bootstrap work is partially complete, but WO-1 cannot be marked complete until the exact `./nexus.ps1 check` acceptance command can run. WO-3 vault scaffolding has started and is blocked on **G3 - Obsidian plugins + REST key** for end-to-end REST verification. WO-4 automation scripts have partial direct-run proof, but WO-4 remains incomplete until dependency gates and exact acceptance tests clear. WO-5 asset pipeline has direct-run proof with seed assets, but remains downstream of the still-open WO-4 formal acceptance. WO-6 Cmdr integration has build/analyze proof, but in-Studio command execution remains gated.

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
