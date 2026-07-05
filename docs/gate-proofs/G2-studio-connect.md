# G2 - Studio Connect Proof Receipt

status: accepted
gate: G2
updated: 2026-07-05T14:33:09Z

## Completion Rule

Change each required marker from `PENDING` to `PASS` only after the human action has actually been performed and verified. Do not paste secrets, tokens, API keys, universe IDs, or place IDs into this file.

## Required Markers

- Studio plugin connected: PASS
- Studio playtest observed: PASS

## Human Steps

- Open the target place in Roblox Studio. Current target: Golf Pro.
- Run `./nexus.ps1 up` and connect the Rojo Studio plugin.
- Confirm a disk edit appears in Studio within seconds.
- Playtest Cmdr command execution and DataService mock-session behavior.

## Evidence Notes

- 2026-07-05: Rojo 7.7.0 plugin connected to `Nexus` at `localhost:34872` in `GOLF PRO - Roblox Studio`.
- 2026-07-05: Studio playtest observed Nexus server/client startup, DataService mock mode, MapService, Cmdr service, and Cmdr client online in Output.

## Proof Commands

```powershell
./nexus.ps1 up
luau-lsp analyze --definitions types/globalTypes.d.luau --sourcemap sourcemap.json src
./nexus.ps1 down
./nexus.ps1 gatecheck --gate G2
```
