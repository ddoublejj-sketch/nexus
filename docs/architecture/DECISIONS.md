# Architecture Decisions

These decisions mirror the founder-reviewed master plan and are locked unless the founder
explicitly opens a new decision.

| ID | Decision | Choice |
| --- | --- | --- |
| D1 | Game architecture | Simple services/modules |
| D2 | Networking | Thin typed Remote wrapper, server-authoritative |
| D3 | UI stack | Native Roblox UI plus small helper modules |
| D4 | Asset style | Hybrid modular kit |
| D5 | Map source of truth | Hybrid source with mandatory `.rbxm` snapshots for Studio-only content |
| D6 | Testing | StyLua, Selene, luau-lsp analyze, and Lune tests for pure logic |
| D7 | Package manager | Wally |
| D8 | Repo location | `C:\Users\jackw\Roblox\nexus` and `C:\Users\jackw\Roblox\RobloxGameVault` |
| D9 | Command center v1 | `nexus.ps1`, VS Code tasks, Lune loops, Obsidian dashboard |
| D10 | CI | GitHub Actions from WO-8, local quality gate from WO-1 |
| D11 | AI/API spend | No OpenAI API, `OPENAI_API_KEY`, or paid model API calls inside Nexus; Codex usage stays in the user's Codex plan outside this repo |

## WO-1 Tool Pins

Resolved by Rokit on 2026-07-03:

| Tool | Version |
| --- | --- |
| Rojo | 7.7.0 |
| Wally | 0.3.2 |
| Lune | 0.10.5 |
| Selene | 0.31.0 |
| StyLua | 2.5.2 |
| luau-lsp | 1.68.1 |

## Local Note

Rokit shims intermittently fail in the managed Codex shell with `os error 3` unless the
PowerShell process first sets an environment variable. `nexus.ps1` resolves tools directly
from the pinned Rokit tool-storage path to keep local commands stable.
