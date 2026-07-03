# G2 - Studio Connect Proof Receipt

status: pending
gate: G2
updated: TODO

## Completion Rule

Change each required marker from `PENDING` to `PASS` only after the human action has actually been performed and verified. Do not paste secrets, tokens, API keys, universe IDs, or place IDs into this file.

## Required Markers

- Studio plugin connected: PENDING
- Studio playtest observed: PENDING

## Human Steps

- Open the Nexus place in Roblox Studio.
- Run `./nexus.ps1 up` and connect the Rojo Studio plugin.
- Confirm a disk edit appears in Studio within seconds.
- Playtest Cmdr command execution and DataService mock-session behavior.

## Evidence Notes

- Paste non-secret observations here after the gate is complete.
- Include command output only if it does not reveal secrets or private IDs.

## Proof Commands

```powershell
./nexus.ps1 up
luau-lsp analyze --definitions types/globalTypes.d.luau --sourcemap sourcemap.json src
./nexus.ps1 down
./nexus.ps1 gatecheck --gate G2
```
