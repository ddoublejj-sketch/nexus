# Nexus Command Center Status

Last updated: 2026-07-02

## Current Phase

WO-0 is in progress and blocked on **G1 - GUI installs**. Non-dependent WO-1 repo bootstrap work may continue.

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
