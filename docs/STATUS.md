# Nexus Command Center Status

Last updated: 2026-07-03

## Current Phase

WO-0 G1 tool closure now passes locally: Git, Rokit, Rojo, VS Code `code`, GitHub CLI `gh`, Blender CLI, and Obsidian command are all available through refreshed PATH/shims. WO-1 exact local acceptance now passes through `./nexus.ps1 check`. WO-2 now has the sync-rules runbook and sourcemap-aware analyze proof, but live Studio sync remains blocked on **G2 - Studio connect**. WO-3 vault plugin preinstall now passes locally with all eight required Obsidian plugins downloaded and enabled in vault config; `./nexus.ps1 obsidian-rest` now records non-secret bootstrap evidence and will write `secrets/obsidian.env` only after Obsidian generates Local REST settings, but REST/dashboard acceptance remains blocked on **G3 - Obsidian REST key + dashboard proof**. WO-4 automation scripts now pass through exact `./nexus.ps1 loop --once` and include dummy-service/stale-note evidence, but dashboard rendering remains gated. WO-5 asset pipeline has direct-run proof with seed assets. WO-6 Cmdr integration has build/analyze proof, but in-Studio command execution remains gated. WO-7 data/networking baseline has direct local proof, but live ProfileStore session behavior remains Studio-gated. WO-8 CI workflow and shared local/CI gate are created, but remote GitHub auth/remote setup remains blocked on **G4 - GitHub auth**. WO-9 release-path dry-run now passes through `./nexus.ps1 release --dry-run --fixture`; live publish remains gated on **G5 - Open Cloud key**. WO-10 `up/status/down` now starts and stops watcher jobs cleanly; full cold-boot Studio acceptance remains blocked on G2/G3.

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
winget --version
v1.29.280
```

G1 install attempt:

```powershell
winget install --id Microsoft.VisualStudioCode --exact --silent --accept-package-agreements --accept-source-agreements
<blocked by safety review: GUI/tool install mutates the machine outside the repos and needs explicit user approval>
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

### Current Re-Audit - 2026-07-03

Run from `C:\Users\jackw\Roblox\nexus` after the project manifest existed:

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
Rojo 7.7.0
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
winget --version
v1.29.280
```

Pinned project tools resolved by Rokit:

```powershell
Get-Command wally,lune,stylua,selene,luau-lsp -ErrorAction SilentlyContinue | Select-Object Name,Source

Name         Source
----         ------
wally.exe    C:\Users\jackw\.rokit\bin\wally.exe
lune.exe     C:\Users\jackw\.rokit\bin\lune.exe
stylua.exe   C:\Users\jackw\.rokit\bin\stylua.exe
selene.exe   C:\Users\jackw\.rokit\bin\selene.exe
luau-lsp.exe C:\Users\jackw\.rokit\bin\luau-lsp.exe
```

Current installed-app checks:

```powershell
Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match 'Visual Studio Code|Obsidian|GitHub CLI|Blender' } | Select-Object DisplayName,DisplayVersion,InstallLocation,DisplayIcon
<no output>
```

```powershell
Get-AppxPackage BlenderFoundation.Blender | Select-Object Name,Version,InstallLocation

Name                      Version InstallLocation
----                      ------- ---------------
BlenderFoundation.Blender 5.1.2.0 C:\Program Files\WindowsApps\BlenderFoundation.Blender_5.1.2.0_x64__ppwjx1n5r4v9t
```

```powershell
Get-ChildItem -Path 'C:\Users\jackw\AppData\Local\Microsoft\WindowsApps' -Filter '*.exe' -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'code|obsidian|gh|blender' } | Select-Object Name,FullName

Name                 FullName
----                 --------
blender-launcher.exe C:\Users\jackw\AppData\Local\Microsoft\WindowsApps\blender-launcher.exe
```

Windows Store launcher alias is present, but no reliable `blender.exe` CLI path is exposed yet.

### G1 Partial Progress - 2026-07-03

VS Code was installed with explicit approval through winget:

```powershell
winget install --id Microsoft.VisualStudioCode --source winget --accept-source-agreements --accept-package-agreements --silent
Found Microsoft Visual Studio Code [Microsoft.VisualStudioCode] Version 1.126.0
Successfully installed
```

The installed user PATH includes the VS Code command shim, and `nexus.ps1` now refreshes PATH from the current user/machine environment before running subcommands:

```powershell
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User'); code --version
1.126.0
7e7950df89d055b5a378379db9ee14290772148a
x64
```

GitHub CLI install attempt timed out and left an elevated `msiexec` process that this shell could not stop:

```powershell
winget install --id GitHub.cli --source winget --accept-source-agreements --accept-package-agreements --silent
command timed out after 124045 milliseconds
```

```powershell
gh --version
gh : The term 'gh' is not recognized as the name of a cmdlet, function, script file, or operable program.
```

Obsidian install attempt downloaded and verified the installer, but the installer failed and did not register the app:

```powershell
winget install --id Obsidian.Obsidian --source winget --accept-source-agreements --accept-package-agreements --silent
Found Obsidian [Obsidian.Obsidian] Version 1.12.7
Successfully verified installer hash
Starting package install...
Installer failed with exit code: 3221225477
```

```powershell
winget list --id Obsidian.Obsidian --source winget
No installed package found matching input criteria.
```

Current G1 probe after VS Code install and PATH refresh:

```powershell
./nexus.ps1 gatecheck --gate G1
| Gate | Check | Status | Detail |
| --- | --- | --- | --- |
| G1 | git available | PASS | git version 2.54.0.windows.1 |
| G1 | rokit available | PASS | rokit 1.2.0 |
| G1 | rojo available | PASS | Rojo 7.7.0 |
| G1 | code available | PASS | 1.126.0 7e7950df89d055b5a378379db9ee14290772148a x64 |
| G1 | gh available | FAIL | gh : The term 'gh' is not recognized as the name of a cmdlet, function, script file, or operable program. |
| G1 | blender CLI available | FAIL | blender not found on PATH |
| G1 | obsidian command available | FAIL | obsidian not found on PATH |
Human gate acceptance BLOCKED: 3 check(s) are not accepted.
```

### G1 Closure - 2026-07-03

GitHub CLI was installed as an official portable release in `C:\Users\jackw\.local\bin` after the MSI path stalled:

```powershell
gh --version
gh version 2.96.0 (2026-07-02)
https://github.com/cli/cli/releases/tag/v2.96.0
```

Portable Blender 5.1.2 was installed under `C:\Users\jackw\Tools\blender-5.1.2-windows-x64`, and the PATH shim now forwards CLI arguments correctly:

```powershell
blender --background --version
Blender 5.1.2 (hash ec6e62d40fa9 built 2026-05-19 01:37:34)
```

Obsidian was installed by running the cached Nullsoft installer directly after winget failed:

```powershell
Start-Process Obsidian-1.12.7.exe -ArgumentList '/S' -Wait -PassThru -WindowStyle Hidden
Obsidian installer exit code: 0
```

An `obsidian.cmd` shim was added to `C:\Users\jackw\.local\bin` because the installer registers the app but does not add an `obsidian` command.

Final G1 acceptance:

```powershell
./nexus.ps1 gatecheck --gate G1
| Gate | Check | Status | Detail |
| --- | --- | --- | --- |
| G1 | git available | PASS | git version 2.54.0.windows.1 |
| G1 | rokit available | PASS | rokit 1.2.0 |
| G1 | rojo available | PASS | Rojo 7.7.0 |
| G1 | code available | PASS | 1.126.0 7e7950df89d055b5a378379db9ee14290772148a x64 |
| G1 | gh available | PASS | gh version 2.96.0 (2026-07-02) https://github.com/cli/cli/releases/tag/v2.96.0 |
| G1 | blender CLI available | PASS | C:\Users\jackw\.local\bin\blender.cmd |
| G1 | obsidian command available | PASS | C:\Users\jackw\.local\bin\obsidian.cmd |
Human gate acceptance PASS
```

WO-0/G1 contract guard:

```powershell
lune run tools/test_tool_gap_contract.luau
Tool gap contract tests passed
```

Seed asset files confirmed for WO-5:

```text
C:\Users\jackw\Desktop\Claude Code\EnergyShard.fbx
C:\Users\jackw\Desktop\Claude Code\GlowRing_A.fbx
C:\Users\jackw\Desktop\Claude Code\GlowRing_B.fbx
C:\Users\jackw\Desktop\Claude Code\Greatsword.fbx
```

### Human Gate G1 Closure

G1 is closed locally. The tool closure path now uses a mix of normal installers and user-local shims:

1. **VS Code is installed**; `code --version` passes through refreshed PATH.
2. **GitHub CLI is installed** as a portable official release at `C:\Users\jackw\.local\bin\gh.exe`; `gh auth login` remains G4.
3. **Obsidian is installed** and exposed through `C:\Users\jackw\.local\bin\obsidian.cmd`; plugin/API setup remains G3.
4. **Blender CLI is installed** as a portable official Blender build exposed through `C:\Users\jackw\.local\bin\blender.cmd`.

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

- `rojo`, Wally, Lune, StyLua, Selene, and luau-lsp are now available through the Nexus Rokit project.
- VS Code CLI, GitHub CLI, Obsidian command, and Blender CLI are now available after PATH refresh/shims.
- WO-0 still has historical installer failure notes above, but the final G1 acceptance probe passes.

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

```powershell
wally install
<exit 0; no output>
```

```powershell
rojo build default.project.json -o build/nexus.rbxl
Building project 'Nexus'
Built project to nexus.rbxl
```

Build artifact:

```text
C:\Users\jackw\Roblox\nexus\build\nexus.rbxl
Length: 88295 bytes
```

```powershell
rojo sourcemap default.project.json -o sourcemap.json
Created sourcemap at sourcemap.json
```

```powershell
./nexus.ps1 check
[PASS] Wally Install (0.67s, exit 0)
[PASS] StyLua (0.05s, exit 0)
[PASS] Selene (0.08s, exit 0)
[PASS] Sourcemap (0.09s, exit 0)
[PASS] Migration Tests (0.03s, exit 0)
[PASS] Analyze (2.07s, exit 0)
[PASS] Build (0.08s, exit 0)
[PASS] Open Cloud Dry Run (0.03s, exit 0)
Quality gate PASS
```

Commit history:

```powershell
git log --oneline
4c82721 Track target layout placeholders
e3f0057 Document Studio sync rules and stale-note proof
a7d16c9 Add command center hardening tools
687f76b Add Open Cloud release dry run
b13f88a Add shared CI quality gate
```

### Open Blockers

- No local WO-1 acceptance blockers remain. The exact acceptance commands above ran and passed from `C:\Users\jackw\Roblox\nexus`.

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
- Added fail-soft pending queue behavior for missing or unavailable Obsidian REST writes:
  - pending writes go to `90_Automation/Logs/pending`
  - successful REST pings flush pending writes into Obsidian and copy flushed envelopes to `90_Automation/Logs/sent`
- Fixed the pending-flush acceptance path so successful REST flushes remove pending envelopes and sent receipts are not counted as unresolved work.
- Added `tools/obsidian_rest_bootstrap.luau` and `./nexus.ps1 obsidian-rest`; it reads the Obsidian-generated Local REST plugin settings, writes `secrets/obsidian.env` with the key hidden, probes the local REST root, and writes the non-secret `Obsidian REST Bootstrap` vault note.
- Added `tools/test_vault_scaffold.luau` to the shared quality gate. It verifies the vault folder layout, Templater frontmatter schema, dashboard Dataview/Tasks sections, dashboard embeds, gate-status note, build-health note, sourcemap note, stale-source note, and command registry note.

### Human Gate G3 Request

Please complete the remaining Obsidian setup when ready:

1. Open `C:\Users\jackw\Roblox\RobloxGameVault` as an Obsidian vault.
2. Confirm the preinstalled community plugins load:
   - Local REST API
   - Obsidian Git
   - Dataview
   - Tasks
   - Kanban
   - Templater
   - QuickAdd
   - Omnisearch
3. Re-run `./nexus.ps1 obsidian-rest`; once the Local REST plugin has generated `data.json`, this writes `C:\Users\jackw\Roblox\nexus\secrets\obsidian.env` without printing the key.

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

Vault ping fail-soft run without secrets:

```powershell
lune run tools/vault_ping.luau
Queued pending vault write: C:/Users/jackw/Roblox/RobloxGameVault/90_Automation/Logs/pending/20260703T033829Z_90_Automation_Generated_Ping.md.pending
This is not G3 acceptance; it will flush after Obsidian REST is configured.
```

Queued envelope proof:

```text
target_path: 90_Automation/Generated/Ping.md
queued_at: 2026-07-03T03:38:29Z
reason: Missing Obsidian REST config
---
# Ping
Last ping: 2026-07-03T03:38:29Z
```

Vault scaffold self-test:

```powershell
lune run tools/test_vault_scaffold.luau
Vault scaffold tests passed
```

Obsidian plugin preinstall:

```powershell
./nexus.ps1 obsidian-plugins
Installed Local REST API 4.1.3 (main.js, manifest.json, styles.css)
Installed Obsidian Git 2.38.5 (main.js, manifest.json, styles.css)
Installed Dataview 0.5.70 (main.js, manifest.json, styles.css)
Installed Tasks 8.2.2 (main.js, manifest.json, styles.css)
Installed Kanban 2.0.51 (main.js, manifest.json, styles.css)
Installed Templater 2.23.0 (main.js, manifest.json, styles.css)
Installed QuickAdd 2.14.1 (main.js, manifest.json, styles.css)
Installed Omnisearch 1.29.3 (main.js, manifest.json, styles.css)
Enabled 8 Obsidian plugins in .obsidian/community-plugins.json
Wrote Obsidian plugin setup evidence to C:/Users/jackw/Roblox/RobloxGameVault/00_Command_Center/Obsidian Plugin Setup.md
```

Plugin setup verifier:

```powershell
lune run tools/test_obsidian_plugin_setup.luau
Obsidian plugin setup tests passed
```

Obsidian REST bootstrap while Obsidian has not generated plugin settings yet:

```powershell
./nexus.ps1 obsidian-rest
Obsidian Local REST settings are not generated yet.
Open the vault in Obsidian, enable/trust plugins, then run ./nexus.ps1 obsidian-rest again.
Wrote Obsidian REST bootstrap evidence to C:/Users/jackw/Roblox/RobloxGameVault/00_Command_Center/Obsidian REST Bootstrap.md
```

Bootstrap verifier:

```powershell
lune run tools/test_obsidian_rest_bootstrap.luau
Obsidian REST bootstrap tests passed
```

G3 acceptance probe after plugin setup:

```powershell
./nexus.ps1 gatecheck --gate G3 --self-test
| Gate | Check | Status | Detail |
| --- | --- | --- | --- |
| G3 | Obsidian REST config present | FAIL | secrets/obsidian.env |
| G3 | Obsidian plugins preinstalled and enabled | PASS | 8 plugin(s) ready |
| G3 | pending Obsidian REST writes flushed | FAIL | 1 pending write(s) |
| G3 | Dashboard rendered in Obsidian | NEEDS HUMAN | receipt pending: docs/gate-proofs/G3-obsidian-dashboard.md needs `Dashboard rendered in Obsidian: PASS` |
Human gate acceptance probe self-test PASS; current blocked checks: 3
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

- Obsidian and the required plugin bundles are installed locally, but dashboard rendering still cannot be accepted until the vault is opened and the plugin render is checked.
- Local REST API is preinstalled but has not generated settings/key data yet, so `./nexus.ps1 obsidian-rest` can only record the waiting state and `tools/vault_ping.luau` can only queue the write; the REST flush is not accepted yet.
- luau-lsp does not currently analyze `tools/*.luau` because it does not know Lune's `@lune/*` runtime imports yet; WO-1 analyzer scope remains `src`.
- WO-3 is **not complete** until `lune run tools/vault_ping.luau` exits 0, `Ping.md` exists with a fresh timestamp, dashboard Dataview tables render, and the vault has committed the generated proof.

## WO-2 - Studio Bridge

### Shipped So Far

- Added `docs/runbooks/rojo-sync-rules.md`.
- Documented disk-owned source, Studio-owned/snapshot content, the G2 test sequence, and the Studio snapshot location.
- The runbook marks live round-trip rows as pending G2 instead of pretending Studio confirmation has happened.
- Added `tools/test_rojo_bridge_contract.luau` to the shared quality gate. It verifies Rojo project mappings, sourcemap/luau-lsp wiring, launcher `serve`/`map` commands, snapshot archive location, and that STATUS/runbook still honestly mark live Studio proof as pending G2.

### Sourcemap-Aware Analyze Evidence

```powershell
$env:ROKIT_PROBE='1'; luau-lsp analyze --definitions types/globalTypes.d.luau --sourcemap sourcemap.json src
[INFO] Loading definitions file: @roblox - types/globalTypes.d.luau
[WARN] client does not allow didChangeWatchedFiles registration - automatic updating on sourcemap changes disabled
[INFO] Loading Luau configuration from c:\Users\jackw\Roblox\nexus\.luaurc
```

Rojo bridge contract self-test:

```powershell
lune run tools/test_rojo_bridge_contract.luau
Rojo bridge contract tests passed
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
- `./nexus.ps1 up` starts the Rojo server locally, but live Studio plugin connection still requires G2.

## WO-4 - Live Project Indexer

### Shipped So Far

- Replaced placeholder automation scripts with runnable Lune scripts:
  - `tools/sourcemap_summary.luau`
  - `tools/vault_sync.luau`
  - `tools/command_registry.luau`
  - `tools/build_health.luau`
  - `tools/gate_status.luau`
  - `tools/asset_manifest.luau` skeleton
- Added `./nexus.ps1 loop` and VS Code `Nexus: Loop Once` task. The loop sequence refreshes sourcemap summary, module notes, command registry, asset manifest skeleton, and build health.
- Generated vault notes:
  - `90_Automation/Generated/Sourcemap.md`
  - `00_Command_Center/Gate Status.md`
  - `02_Systems/Generated Modules/...`
  - `02_Systems/Commands.md`
  - `90_Automation/Generated/Stale Sources.md`
  - `90_Automation/Generated/Asset Manifest.md`
  - `00_Command_Center/Build Health.md`
- Dashboard now embeds `Stale Sources`.
- Shared quality gate now includes `Vault Scaffold Tests`, which covers the local vault scaffold and generated command-center notes.

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

### Exact Launcher Loop Evidence

```powershell
./nexus.ps1 loop --once
Wrote 132 sourcemap rows to C:/Users/jackw/Roblox/RobloxGameVault/90_Automation/Generated/Sourcemap.md
Wrote 12 module notes under C:/Users/jackw/Roblox/RobloxGameVault/02_Systems/Generated Modules and refreshed stale-source report
Wrote 7 command rows to C:/Users/jackw/Roblox/RobloxGameVault/02_Systems/Commands.md
Asset manifest reconciled 4 assets; auto-added 0; missing sources 0; missing exports 0
Wrote gate status for 11 work orders to C:/Users/jackw/Roblox/RobloxGameVault/00_Command_Center/Gate Status.md
Build health PASS; wrote C:/Users/jackw/Roblox/RobloxGameVault/00_Command_Center/Build Health.md
```

Runtime: 3.9 seconds, under the 30-second target.

```powershell
./nexus.ps1 health
Build health PASS; wrote C:/Users/jackw/Roblox/RobloxGameVault/00_Command_Center/Build Health.md
```

### Open Blockers

- WO-4 depends on WO-2 and WO-3 in the master plan. Those are still gated by Studio/Obsidian setup.
- Dashboard rendering still cannot be visually verified until Obsidian is installed and G3 plugins are enabled.

WO-4 has local exact launcher proof, but final acceptance still needs the G3 dashboard render check.

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
- Added `tools/test_asset_manifest.luau` to the shared quality gate. It verifies seed manifest rows, real source/export files, placeholder thumbnails, generated vault asset notes, the generated asset index, and thumbnail backlog coverage.
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

Asset manifest self-test:

```powershell
lune run tools/test_asset_manifest.luau
Asset manifest tests passed
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
- Added `tools/test_commands.luau` to verify the command surface without Studio:
  - exactly seven command definition modules
  - every command has a matching server handler
  - every command header tier matches its Cmdr group
  - `profilewipe` is `Owner`/`NexusOwner`
  - `profilewipeServer` re-checks Owner permission and refuses without `CONFIRM_WIPE`

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

Command surface tests:

```powershell
lune run tools/test_commands.luau
Command surface tests passed
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
- Added Lune DataService contract test at `tools/test_data_service_contract.luau`, now part of the shared quality gate:
  - ProfileStore dependency and store name
  - `ProfileStore.Mock` in Studio
  - `StartSessionAsync` cancel guard and nil-session kick path
  - `AddUserId`, `Reconcile`, schema migration, `OnSessionEnd`, and `EndSession`
  - join/leave wiring and server-owned API surface
  - sanitized `RequestProfileSnapshot` exposure
  - Save Data vault note coverage and G2 honesty
- Added Lune Net contract test at `tools/test_net_contract.luau`, now part of the shared quality gate:
  - declared remotes, kinds, directions, validator counts
  - vault networking note coverage
  - `RequestProfileSnapshot` handler ownership
  - sanitized snapshot exposure
  - no unguarded `SetDebugFlag` client-to-server mutation handler
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

Net contract test:

```powershell
lune run tools/test_net_contract.luau
Net contract tests passed
```

DataService contract test:

```powershell
lune run tools/test_data_service_contract.luau
DataService contract tests passed
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
Wally Install: PASS
StyLua: PASS
Selene: PASS
Sourcemap: PASS
Tool Gap Contract Tests: PASS
Rojo Bridge Tests: PASS
Migration Tests: PASS
DataService Contract Tests: PASS
Command Surface Tests: PASS
Net Contract Tests: PASS
Secret Scan: PASS
Analyze: PASS
Build: PASS
Open Cloud Dry Run: PASS
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
- Added `tools/test_ci_contract.luau` to the shared gate. It verifies workflow/launcher/build-health parity, artifact upload settings, runbook G4 instructions, and that CI does not duplicate the quality checklist outside `tools/quality_gate.luau`.

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
[PASS] Wally Install (0.76s, exit 0)
[PASS] StyLua (0.06s, exit 0)
[PASS] Selene (0.10s, exit 0)
[PASS] Sourcemap (0.08s, exit 0)
[PASS] Tool Gap Contract Tests (0.03s, exit 0)
[PASS] Rojo Bridge Tests (0.03s, exit 0)
[PASS] Migration Tests (0.03s, exit 0)
[PASS] DataService Contract Tests (0.03s, exit 0)
[PASS] Vault Scaffold Tests (0.06s, exit 0)
[PASS] Asset Manifest Tests (0.03s, exit 0)
[PASS] Command Surface Tests (0.03s, exit 0)
[PASS] Net Contract Tests (0.03s, exit 0)
[PASS] CI Contract Tests (0.03s, exit 0)
[PASS] Command Center Contract Tests (0.03s, exit 0)
[PASS] Human Gate Checklist Tests (0.03s, exit 0)
[PASS] Human Gate Readiness Tests (0.03s, exit 0)
[PASS] Human Gate Acceptance Tests (0.03s, exit 0)
[PASS] Acceptance Matrix Contract Tests (0.03s, exit 0)
[PASS] Secret Scan (0.37s, exit 0)
[PASS] Analyze (2.04s, exit 0)
[PASS] Build (0.08s, exit 0)
[PASS] Open Cloud Dry Run (0.03s, exit 0)
Quality gate PASS
```

CI contract self-test:

```powershell
lune run tools/test_ci_contract.luau
CI contract tests passed
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
Tool Gap Contract Tests: PASS
Rojo Bridge Tests: PASS
Migration Tests: PASS
DataService Contract Tests: PASS
Vault Scaffold Tests: PASS
Asset Manifest Tests: PASS
Command Surface Tests: PASS
Net Contract Tests: PASS
CI Contract Tests: PASS
Command Center Contract Tests: PASS
Human Gate Checklist Tests: PASS
Human Gate Readiness Tests: PASS
Human Gate Acceptance Tests: PASS
Acceptance Matrix Contract Tests: PASS
Secret Scan: PASS
Analyze: PASS
Build: PASS
Open Cloud Dry Run: PASS
```

### Human Gate G4 Request

Please complete when ready:

1. Run `gh auth login`.
2. Create/push private repos for:
   - `nexus`
   - `RobloxGameVault`
3. Enable branch protection on `main` so the Nexus CI quality gate is required before merge.

### Open Blockers

- `gh` is installed, but GitHub auth, repo creation, push, and branch protection still require G4.
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
- Added `tools/secret_scan.luau` to the shared quality gate. It scans Nexus and vault Git history for common real credential patterns while allowing intentional placeholders/fixtures.
- Added `tools/test_release_contract.luau` to the shared quality gate. It verifies dry-run defaults, fixture/live separation, placeholder-key rejection, artifact validation, launcher forwarding, checklist requirements, and Open Cloud secret hygiene.

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

Exact launcher dry-run:

```powershell
./nexus.ps1 release --dry-run --fixture
Open Cloud publish dry-run PASS
Mode: dry-run
Config source: tools/fixtures/opencloud.env (fixture)
Artifact: build/nexus.rbxl (88295 bytes)
Universe ID: 1234567890
Place ID: 9876543210
Endpoint: https://apis.roblox.com/universes/v1/1234567890/places/9876543210/versions?versionType=Published
Live request was not sent.
```

Release contract self-test:

```powershell
lune run tools/test_release_contract.luau
Release contract tests passed
```

### Shared Gate Evidence After WO-9

```powershell
$env:ROKIT_PROBE='1'; lune run tools/quality_gate.luau
[PASS] Wally Install (0.71s, exit 0)
[PASS] StyLua (0.07s, exit 0)
[PASS] Selene (0.09s, exit 0)
[PASS] Sourcemap (0.09s, exit 0)
[PASS] Tool Gap Contract Tests (0.03s, exit 0)
[PASS] G1 Tool Closure Tests (0.03s, exit 0)
[PASS] Rojo Bridge Tests (0.03s, exit 0)
[PASS] Migration Tests (0.03s, exit 0)
[PASS] DataService Contract Tests (0.03s, exit 0)
[PASS] Vault Scaffold Tests (0.07s, exit 0)
[PASS] Asset Manifest Tests (0.03s, exit 0)
[PASS] Command Surface Tests (0.03s, exit 0)
[PASS] Net Contract Tests (0.03s, exit 0)
[PASS] CI Contract Tests (0.03s, exit 0)
[PASS] Command Center Contract Tests (0.03s, exit 0)
[PASS] Human Gate Checklist Tests (0.03s, exit 0)
[PASS] Human Gate Readiness Tests (0.03s, exit 0)
[PASS] Human Gate Acceptance Tests (0.03s, exit 0)
[PASS] Acceptance Matrix Contract Tests (0.03s, exit 0)
[PASS] Release Contract Tests (0.03s, exit 0)
[PASS] Secret Scan (0.40s, exit 0)
[PASS] Analyze (2.05s, exit 0)
[PASS] Build (0.08s, exit 0)
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
Tool Gap Contract Tests: PASS
Rojo Bridge Tests: PASS
Migration Tests: PASS
DataService Contract Tests: PASS
Vault Scaffold Tests: PASS
Asset Manifest Tests: PASS
Command Surface Tests: PASS
Net Contract Tests: PASS
CI Contract Tests: PASS
Command Center Contract Tests: PASS
Human Gate Checklist Tests: PASS
Human Gate Readiness Tests: PASS
Human Gate Acceptance Tests: PASS
Acceptance Matrix Contract Tests: PASS
Release Contract Tests: PASS
Secret Scan: PASS
Analyze: PASS
Build: PASS
Open Cloud Dry Run: PASS
```

### Secret History Scan

```powershell
git log -p -- secrets .env | Select-String -Pattern "key|token"
<no output>
```

Automated scan:

```powershell
lune run tools/secret_scan.luau
Secret scan passed
```

### Human Gate G5 Request

When ready to publish for real:

1. Create the minimally scoped Open Cloud key in Creator Hub.
2. Place it only in `C:\Users\jackw\Roblox\nexus\secrets\opencloud.env`.
3. Include numeric `ROBLOX_UNIVERSE_ID` and `ROBLOX_PLACE_ID` in that same local secret file.
4. Run the fixture dry-run first, then run `lune run tools/open_cloud_publish.luau --live`.

### Open Blockers

- G5 is not complete, so live publish was intentionally not attempted.

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
- Updated the `up` automation loop to run Build Health in watcher-safe mode so it does not run `wally install` while Rojo is serving `Packages/`.
- Added `tools/test_command_center_contract.luau` to the shared quality gate. It verifies launcher subcommands, background job names, watcher-safe health mode, VS Code tasks/settings/extensions, daily dev log behavior, and setup/recovery runbook requirements.
- Added `tools/human_gate_checklist.luau`, `./nexus.ps1 gates`, the `Nexus: Human Gates` VS Code task, and a dashboard embed for `00_Command_Center/Human Gate Checklist.md`.
- Added `tools/test_human_gate_checklist.luau` to the shared quality gate. It verifies G1-G5 actions, proof commands, launcher/task wiring, README visibility, dashboard embed, and generated vault note content.
- Added `tools/human_gate_readiness.luau` and a dashboard embed for `00_Command_Center/Human Gate Readiness.md`.
- Added `tools/test_human_gate_readiness.luau` to the shared quality gate. It verifies automatic G1-G5 readiness checks, secret-safe output, launcher/loop wiring, dashboard embed, and generated vault note content.
- Added `tools/human_gate_acceptance.luau`, `./nexus.ps1 gatecheck`, and a `Nexus: Gate Acceptance Probe` VS Code task.
- Added `tools/test_human_gate_acceptance.luau` to the shared quality gate. It verifies the on-demand acceptance probe, its self-test mode, and an honest blocked probe path for human-only gates.

### Verification Evidence

Launcher syntax parse:

```powershell
$errors = $null; [void][System.Management.Automation.PSParser]::Tokenize((Get-Content -LiteralPath ".\nexus.ps1" -Raw), [ref]$errors); if ($errors -and $errors.Count -gt 0) { $errors | ForEach-Object { "$($_.Message) at $($_.StartLine):$($_.StartColumn)" }; exit 1 } else { "PowerShell parse PASS" }
PowerShell parse PASS
```

VS Code task file parse:

```powershell
Get-Content -LiteralPath ".\.vscode\tasks.json" -Raw | ConvertFrom-Json | Out-Null; "tasks.json parse PASS"
tasks.json parse PASS
```

Command-center contract self-test:

```powershell
lune run tools/test_command_center_contract.luau
Command center contract tests passed
```

Human gate notes generation:

```powershell
./nexus.ps1 gates
Wrote gate status for 11 work orders to C:/Users/jackw/Roblox/RobloxGameVault/00_Command_Center/Gate Status.md
Wrote human gate checklist to C:/Users/jackw/Roblox/RobloxGameVault/00_Command_Center/Human Gate Checklist.md
Wrote human gate readiness to C:/Users/jackw/Roblox/RobloxGameVault/00_Command_Center/Human Gate Readiness.md
```

Human gate checklist contract self-test:

```powershell
lune run tools/test_human_gate_checklist.luau
Human gate checklist tests passed
```

Human gate readiness contract self-test:

```powershell
lune run tools/test_human_gate_readiness.luau
Human gate readiness tests passed
```

Human gate acceptance probe self-test:

```powershell
./nexus.ps1 gatecheck --self-test
| Gate | Check | Status | Detail |
| --- | --- | --- | --- |
| G1 | git available | PASS | git version 2.54.0.windows.1 |
| G1 | rokit available | PASS | rokit 1.2.0 |
| G1 | rojo available | PASS | Rojo 7.7.0 |
| G1 | code available | PASS | 1.126.0 7e7950df89d055b5a378379db9ee14290772148a x64 |
| G1 | gh available | PASS | gh version 2.96.0 (2026-07-02) https://github.com/cli/cli/releases/tag/v2.96.0 |
| G1 | blender CLI available | PASS | C:\Users\jackw\.local\bin\blender.cmd |
| G1 | obsidian command available | PASS | C:\Users\jackw\.local\bin\obsidian.cmd |
| G2 | Studio plugin connected | NEEDS HUMAN | receipt pending: docs/gate-proofs/G2-studio-connect.md needs `Studio plugin connected: PASS` |
| G2 | Studio playtest observed | NEEDS HUMAN | receipt pending: docs/gate-proofs/G2-studio-connect.md needs `Studio playtest observed: PASS` |
| G2 | Rojo sync runbook present | PASS | runbook present |
| G3 | Obsidian REST config present | FAIL | secrets/obsidian.env |
| G3 | Obsidian plugins preinstalled and enabled | PASS | 8 plugin(s) ready |
| G3 | pending Obsidian REST writes flushed | FAIL | 1 pending write(s) |
| G3 | Dashboard rendered in Obsidian | NEEDS HUMAN | receipt pending: docs/gate-proofs/G3-obsidian-dashboard.md needs `Dashboard rendered in Obsidian: PASS` |
| G4 | GitHub auth active | FAIL | You are not logged into any GitHub hosts. To log in, run: gh auth login |
| G4 | Git remote configured | FAIL | no remote |
| G4 | CI branch protection confirmed | NEEDS HUMAN | receipt pending: docs/gate-proofs/G4-github-ci.md needs `CI branch protection confirmed: PASS` |
| G5 | Open Cloud config present | FAIL | secrets/opencloud.env |
| G5 | Build artifact present | PASS | build artifact present |
| G5 | Live publish approval recorded | NEEDS HUMAN | receipt pending: docs/gate-proofs/G5-open-cloud-publish.md needs `Live publish approval recorded: PASS` |
Human gate acceptance probe self-test PASS; current blocked checks: 10
```

Human gate acceptance probe blocked-path sample:

```powershell
./nexus.ps1 gatecheck --gate G2
| Gate | Check | Status | Detail |
| --- | --- | --- | --- |
| G2 | Studio plugin connected | NEEDS HUMAN | Record G2 proof in docs/STATUS.md. |
| G2 | Studio playtest observed | NEEDS HUMAN | Record Cmdr/DataService runtime proof. |
| G2 | Rojo sync runbook present | PASS | runbook present |
Human gate acceptance BLOCKED: 2 check(s) are not accepted.
lune failed with exit code 1
```

Human gate acceptance contract self-test:

```powershell
lune run tools/test_human_gate_acceptance.luau
Human gate acceptance tests passed
```

One-shot automation loop after human-gate checklist/readiness wiring:

```powershell
./nexus.ps1 loop --once
Wrote 132 sourcemap rows to C:/Users/jackw/Roblox/RobloxGameVault/90_Automation/Generated/Sourcemap.md
Wrote 12 module notes under C:/Users/jackw/Roblox/RobloxGameVault/02_Systems/Generated Modules and refreshed stale-source report
Wrote 7 command rows to C:/Users/jackw/Roblox/RobloxGameVault/02_Systems/Commands.md
Asset manifest reconciled 4 assets; auto-added 0; missing sources 0; missing exports 0
Wrote gate status for 11 work orders to C:/Users/jackw/Roblox/RobloxGameVault/00_Command_Center/Gate Status.md
Wrote human gate checklist to C:/Users/jackw/Roblox/RobloxGameVault/00_Command_Center/Human Gate Checklist.md
Wrote human gate readiness to C:/Users/jackw/Roblox/RobloxGameVault/00_Command_Center/Human Gate Readiness.md
Build health PASS; wrote C:/Users/jackw/Roblox/RobloxGameVault/00_Command_Center/Build Health.md
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
[PASS] Wally Install (0.73s, exit 0)
[PASS] StyLua (0.06s, exit 0)
[PASS] Selene (0.10s, exit 0)
[PASS] Sourcemap (0.08s, exit 0)
[PASS] Tool Gap Contract Tests (0.03s, exit 0)
[PASS] Rojo Bridge Tests (0.03s, exit 0)
[PASS] Migration Tests (0.03s, exit 0)
[PASS] DataService Contract Tests (0.03s, exit 0)
[PASS] Vault Scaffold Tests (0.06s, exit 0)
[PASS] Asset Manifest Tests (0.03s, exit 0)
[PASS] Command Surface Tests (0.03s, exit 0)
[PASS] Net Contract Tests (0.03s, exit 0)
[PASS] CI Contract Tests (0.03s, exit 0)
[PASS] Command Center Contract Tests (0.03s, exit 0)
[PASS] Human Gate Checklist Tests (0.03s, exit 0)
[PASS] Human Gate Readiness Tests (0.03s, exit 0)
[PASS] Human Gate Acceptance Tests (0.03s, exit 0)
[PASS] Acceptance Matrix Contract Tests (0.03s, exit 0)
[PASS] Release Contract Tests (0.03s, exit 0)
[PASS] Secret Scan (0.37s, exit 0)
[PASS] Analyze (2.04s, exit 0)
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
Tool Gap Contract Tests: PASS
Rojo Bridge Tests: PASS
Migration Tests: PASS
DataService Contract Tests: PASS
Vault Scaffold Tests: PASS
Asset Manifest Tests: PASS
Command Surface Tests: PASS
Net Contract Tests: PASS
CI Contract Tests: PASS
Command Center Contract Tests: PASS
Human Gate Checklist Tests: PASS
Human Gate Readiness Tests: PASS
Human Gate Acceptance Tests: PASS
Acceptance Matrix Contract Tests: PASS
Release Contract Tests: PASS
Secret Scan: PASS
Analyze: PASS
Build: PASS
Open Cloud Dry Run: PASS
```

### Exact Up/Down Evidence

Initial `up/status/down` test showed Rojo serve and sourcemap-watch jobs crashing because the loop's Build Health step ran `wally install` while Rojo was watching `Packages/`. The launcher now uses `tools/build_health.luau --skip-install` only inside the continuous `up` loop; full `./nexus.ps1 check` and `./nexus.ps1 health` still run the complete gate with Wally install.

```powershell
./nexus.ps1 up; Start-Sleep -Seconds 5; ./nexus.ps1 status; Receive-Job -Name NexusRojoServe,NexusSourcemapWatch,NexusAutomationLoop -Keep; ./nexus.ps1 down
Dev log appended: C:/Users/jackw/Roblox/RobloxGameVault/00_Command_Center/Daily Dev Log.md (Session Start)

Name                State   Id
----                -----   --
NexusRojoServe      Running  1
NexusSourcemapWatch Running  3
NexusAutomationLoop Running  5

Name                State   Id
----                -----   --
NexusRojoServe      Running  1
NexusSourcemapWatch Running  3
NexusAutomationLoop Running  5

Rojo server listening:
  Address: localhost
  Port:    34872
Visit http://localhost:34872/ in your browser for more information.
Created sourcemap at sourcemap.json
Wrote 132 sourcemap rows to C:/Users/jackw/Roblox/RobloxGameVault/90_Automation/Generated/Sourcemap.md
Wrote 12 module notes under C:/Users/jackw/Roblox/RobloxGameVault/02_Systems/Generated Modules and refreshed stale-source report
Wrote 7 command rows to C:/Users/jackw/Roblox/RobloxGameVault/02_Systems/Commands.md
Asset manifest reconciled 4 assets; auto-added 0; missing sources 0; missing exports 0
Build health PASS; wrote C:/Users/jackw/Roblox/RobloxGameVault/00_Command_Center/Build Health.md
Dev log appended: C:/Users/jackw/Roblox/RobloxGameVault/00_Command_Center/Daily Dev Log.md (Session End)

Name                State   Id
----                -----   --
NexusRojoServe      Stopped
NexusSourcemapWatch Stopped
NexusAutomationLoop Stopped
```

### Exact Acceptance Blockers

- The cold-boot flow cannot prove Studio updates until G2 Studio plugin connect is complete.
- Vault dashboard rendering still needs G3 Obsidian plugins.

## Acceptance Matrix

| Work Order | Local Status | Evidence In This File | Remaining Gate / Blocker |
| --- | --- | --- | --- |
| WO-0 Tool Gaps | Exact G1 acceptance passed | Audit output, VS Code install proof, portable gh/Blender/Obsidian shim proof, G1 Tool Closure note/runbook, and tool-gap contract tests under WO-0 | None locally |
| WO-1 Bootstrap | Exact local acceptance passed | Repo scaffold, tool pins, `rokit install`, `wally install`, `rojo build`, `rojo sourcemap`, `./nexus.ps1 check` | None locally |
| WO-2 Studio Bridge | Runbook added, live bridge blocked | Sourcemap-aware analyze output, Rojo bridge tests, and `docs/runbooks/rojo-sync-rules.md` | G2: Studio plugin connect and live sync proof |
| WO-3 Vault | Scaffolded, REST blocked | Vault repo, templates, vault scaffold tests, pending queue output, Obsidian plugin setup proof | G3: Local REST API key, pending flush, dashboard render |
| WO-4 Automation Loop | Exact local launcher proof passed | Sourcemap, vault sync, dummy/stale-note demo, command registry, gate status, vault scaffold tests, asset manifest, `./nexus.ps1 loop --once`, Build Health outputs | Dashboard render needs G3 |
| WO-5 Asset Pipeline | Implemented with seed assets | Manifest, orphan repair, asset manifest tests, vault asset notes, Blender CLI-ready seed catalog | Dashboard render needs G3 |
| WO-6 Cmdr | Implemented and analyzed | Cmdr service/controller, commands, generated command docs | G2 Studio playtest for command execution |
| WO-7 Data/Networking | Implemented and tested locally | ProfileStore wrapper, migration tests, DataService contract tests, Net contract tests, typed Net, Build Health | G2 Studio playtest for session/runtime behavior |
| WO-8 CI | Local workflow committed | Shared gate output, CI contract tests, workflow, runbook | G4: `gh auth`, remote repo, branch protection, real CI run |
| WO-9 Release Path | Dry-run accepted locally | Fixture dry-run, `./nexus.ps1 release --dry-run --fixture`, release contract tests, secret-history scan, release checklist | G5 for live publish only |
| WO-10 Hardening | Up/down smoke test passed locally | Task JSON parse, command-center contract tests, human gate checklist/readiness/acceptance/receipt/founder sign-off tests, dev log writes, Gate Status, Human Gate Proof Receipts, and Founder Sign-Off dashboard embeds, `./nexus.ps1 up/status/down`, full gate | G2 Studio connect and G3 dashboard render for cold-boot acceptance |

Acceptance Matrix contract self-test:

```powershell
lune run tools/test_acceptance_matrix_contract.luau
Acceptance matrix contract tests passed
```

## Latest Whole-Repo Verification

```powershell
./nexus.ps1 check
[PASS] Wally Install (0.73s, exit 0)
[PASS] StyLua (0.08s, exit 0)
[PASS] Selene (0.10s, exit 0)
[PASS] Sourcemap (0.09s, exit 0)
[PASS] Tool Gap Contract Tests (0.02s, exit 0)
[PASS] G1 Tool Closure Tests (0.03s, exit 0)
[PASS] Rojo Bridge Tests (0.03s, exit 0)
[PASS] Migration Tests (0.03s, exit 0)
[PASS] DataService Contract Tests (0.03s, exit 0)
[PASS] Vault Scaffold Tests (0.06s, exit 0)
[PASS] Obsidian Plugin Setup Tests (0.03s, exit 0)
[PASS] Obsidian REST Bootstrap Tests (0.03s, exit 0)
[PASS] Asset Manifest Tests (0.03s, exit 0)
[PASS] Command Surface Tests (0.03s, exit 0)
[PASS] Net Contract Tests (0.03s, exit 0)
[PASS] CI Contract Tests (0.03s, exit 0)
[PASS] Command Center Contract Tests (0.03s, exit 0)
[PASS] Human Gate Checklist Tests (0.03s, exit 0)
[PASS] Human Gate Readiness Tests (0.03s, exit 0)
[PASS] Human Gate Acceptance Tests (2.14s, exit 0)
[PASS] Human Gate Receipt Tests (1.11s, exit 0)
[PASS] Founder Sign-Off Audit Tests (0.03s, exit 0)
[PASS] Acceptance Matrix Contract Tests (0.03s, exit 0)
[PASS] Release Contract Tests (0.02s, exit 0)
[PASS] Secret Scan (0.47s, exit 0)
[PASS] Analyze (1.98s, exit 0)
[PASS] Build (0.08s, exit 0)
[PASS] Open Cloud Dry Run (0.03s, exit 0)
Quality gate PASS
```

```powershell
./nexus.ps1 gates
Wrote gate status for 11 work orders to C:/Users/jackw/Roblox/RobloxGameVault/00_Command_Center/Gate Status.md
Wrote human gate checklist to C:/Users/jackw/Roblox/RobloxGameVault/00_Command_Center/Human Gate Checklist.md
Wrote human gate readiness to C:/Users/jackw/Roblox/RobloxGameVault/00_Command_Center/Human Gate Readiness.md
Wrote human gate proof receipts to C:/Users/jackw/Roblox/RobloxGameVault/00_Command_Center/Human Gate Proof Receipts.md
Wrote G1 tool closure note to C:/Users/jackw/Roblox/RobloxGameVault/00_Command_Center/G1 Tool Closure.md
```

```powershell
./nexus.ps1 loop --once
Wrote 132 sourcemap rows to C:/Users/jackw/Roblox/RobloxGameVault/90_Automation/Generated/Sourcemap.md
Wrote 12 module notes under C:/Users/jackw/Roblox/RobloxGameVault/02_Systems/Generated Modules and refreshed stale-source report
Wrote 7 command rows to C:/Users/jackw/Roblox/RobloxGameVault/02_Systems/Commands.md
Asset manifest reconciled 4 assets; auto-added 0; missing sources 0; missing exports 0
Wrote gate status for 11 work orders to C:/Users/jackw/Roblox/RobloxGameVault/00_Command_Center/Gate Status.md
Wrote human gate checklist to C:/Users/jackw/Roblox/RobloxGameVault/00_Command_Center/Human Gate Checklist.md
Wrote human gate readiness to C:/Users/jackw/Roblox/RobloxGameVault/00_Command_Center/Human Gate Readiness.md
Wrote human gate proof receipts to C:/Users/jackw/Roblox/RobloxGameVault/00_Command_Center/Human Gate Proof Receipts.md
Build health PASS; wrote C:/Users/jackw/Roblox/RobloxGameVault/00_Command_Center/Build Health.md
Wrote founder sign-off audit to C:/Users/jackw/Roblox/RobloxGameVault/00_Command_Center/Founder Sign-Off Audit.md
```

```powershell
./nexus.ps1 receipts
Wrote human gate proof receipts to C:/Users/jackw/Roblox/RobloxGameVault/00_Command_Center/Human Gate Proof Receipts.md
```

```powershell
./nexus.ps1 health
Build health PASS; wrote C:/Users/jackw/Roblox/RobloxGameVault/00_Command_Center/Build Health.md
```

```powershell
./nexus.ps1 audit
Wrote founder sign-off audit to C:/Users/jackw/Roblox/RobloxGameVault/00_Command_Center/Founder Sign-Off Audit.md
```
