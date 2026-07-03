# Fresh Machine Setup

Use this when setting up Nexus on a new Windows machine.

## Install Human-Gate Tools

Complete G1 first:

Use `docs/runbooks/g1-tool-closure.md` and `./nexus.ps1 g1` for the exact
local audit and closeout commands.

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
rojo --version
code --version
gh --version
Get-Command blender -ErrorAction SilentlyContinue
```

For Blender automation, a Windows Store launcher alias is not enough. Nexus needs
`blender.exe` on PATH or the local `C:\Users\jackw\.local\bin\blender.cmd` shim
restored for CLI thumbnail rendering.

## Clone And Install

```powershell
cd C:\Users\jackw\Roblox
git clone <private-nexus-url> nexus
git clone <private-vault-url> RobloxGameVault
cd C:\Users\jackw\Roblox\nexus
rokit install
wally install
./nexus.ps1 obsidian-plugins
./nexus.ps1 thumbnails
./nexus.ps1 check
./nexus.ps1 cold-boot
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
./nexus.ps1 release --dry-run --fixture
```

## Studio And Vault

1. Install the Rojo Studio plugin.
2. Open the place in Studio.
3. Run Rojo serve from Nexus.
4. Connect the Studio plugin to the local server.
5. Open `C:\Users\jackw\Roblox\RobloxGameVault` as an Obsidian vault.
6. Confirm the preinstalled Local REST API, Obsidian Git, Dataview, Tasks, Kanban, Templater, QuickAdd, and Omnisearch plugins load.
7. Copy the Local REST API key into `secrets/obsidian.env`, then run `lune run tools/vault_ping.luau`.

## Launcher Check

Run `./nexus.ps1 status` after setup. It should print Git status, pinned tool versions, the last build, and the command-center job table.

Run `./nexus.ps1 cold-boot` after the first green check. It should write
`00_Command_Center/Cold Boot Readiness.md` and preserve G2/G3 as human proof
until Studio sync and the Obsidian dashboard are actually verified.
