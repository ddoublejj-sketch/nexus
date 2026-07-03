# G1 Tool Closure Runbook

G1 closes only when this shell can verify the missing command-line tools. Do not mark G1 complete from installer intent alone.

## Current Required Tools

G1 requires these commands to work from a new Nexus shell:

```powershell
code --version
gh --version
Get-Command obsidian -ErrorAction SilentlyContinue
Get-Command blender -ErrorAction SilentlyContinue
./nexus.ps1 gatecheck --gate G1
```

Git, Rokit, Rojo, VS Code `code`, GitHub CLI `gh`, Obsidian, and a PATH-visible Blender CLI are passing on the current machine.

## Human Install Commands

Run installer commands only with explicit approval:

```powershell
winget install --id Microsoft.VisualStudioCode --source winget
winget install --id GitHub.cli --source winget
winget install --id Obsidian.Obsidian --source winget
```

Blender thumbnail rendering requires a real CLI path, not only the Microsoft Store launcher alias. The current machine exposes Blender through `C:\Users\jackw\.local\bin\blender.cmd`; if that disappears, install a standard Blender build that exposes `blender.exe` or restore the shim.

## After Installation

1. Restart the shell so PATH changes are visible.
2. Run `./nexus.ps1 g1` to refresh PATH from the current user/machine environment and update the vault audit note.
3. Run `./nexus.ps1 gatecheck --gate G1`.
4. Paste the passing output into `docs/STATUS.md`.

G4 still owns `gh auth login`; G1 only requires the `gh` command to exist.
