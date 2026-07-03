# Nexus Command Center

Nexus is the Rojo-first command center for Roblox projects. The v1 interface is this repo:
`nexus.ps1`, VS Code tasks, Lune automation loops, and the Obsidian vault.

## Setup

```powershell
cd C:\Users\jackw\Roblox\nexus
rokit install
wally install
./nexus.ps1 serve
```

## Daily Commands

```powershell
./nexus.ps1 build
./nexus.ps1 check
./nexus.ps1 fix
./nexus.ps1 gates
./nexus.ps1 gatecheck --self-test
./nexus.ps1 g1
./nexus.ps1 receipts
./nexus.ps1 audit
./nexus.ps1 cold-boot
./nexus.ps1 up
./nexus.ps1 down
./nexus.ps1 release --dry-run --fixture
./nexus.ps1 status
```

## Human Gates

The full gate list lives in `docs/STATUS.md`. Secrets belong only in `secrets/*.env`;
never commit keys, tokens, universe IDs, or place IDs.
