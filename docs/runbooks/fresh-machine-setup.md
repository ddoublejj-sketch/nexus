# Fresh Machine Setup

Use this when setting up Nexus on a new Windows machine.

## Install Human-Gate Tools

Complete G1 first:

- Git
- Rokit
- VS Code with `code` on PATH
- GitHub CLI
- Obsidian
- Blender

Then verify from a new terminal:

```powershell
git --version
rokit --version
code --version
gh --version
```

## Clone And Install

```powershell
cd C:\Users\jackw\Roblox
git clone <private-nexus-url> nexus
git clone <private-vault-url> RobloxGameVault
cd C:\Users\jackw\Roblox\nexus
rokit install
$env:ROKIT_PROBE='1'; wally install
$env:ROKIT_PROBE='1'; lune run tools/quality_gate.luau
```

Expected final line:

```text
Quality gate PASS
```

## Local Secrets

Create only the files needed for unlocked gates:

```text
secrets/obsidian.env
secrets/opencloud.env
```

Never commit either file. The release dry-run works before `secrets/opencloud.env` exists:

```powershell
$env:ROKIT_PROBE='1'; lune run tools/open_cloud_publish.luau --dry-run --fixture
```

## Studio And Vault

1. Install the Rojo Studio plugin.
2. Open the place in Studio.
3. Run Rojo serve from Nexus.
4. Connect the Studio plugin to the local server.
5. Open `C:\Users\jackw\Roblox\RobloxGameVault` as an Obsidian vault.
6. Enable the Local REST API, Obsidian Git, Dataview, Tasks, Kanban, Templater, QuickAdd, and Omnisearch plugins.

## PowerShell Launcher

`nexus.ps1` requires the local PowerShell execution-policy gate to be cleared. Until then, use the direct Lune/Rokit commands recorded in `docs/STATUS.md`.
