# Release Checklist

WO-9 keeps publish one explicit step away. Dry-run is safe to run without an Open Cloud key; live publish requires G5.

## Dry Run

```powershell
$env:ROKIT_PROBE='1'; lune run tools/quality_gate.luau
$env:ROKIT_PROBE='1'; lune run tools/build_health.luau
$env:ROKIT_PROBE='1'; lune run tools/open_cloud_publish.luau --dry-run --fixture
```

Expected result:

```text
Open Cloud publish dry-run PASS
Live request was not sent.
```

## Before Live

1. Confirm GitHub CI is green after G4.
2. Confirm `docs/CHANGELOG.md` and `docs/STATUS.md` describe the release.
3. Confirm `RobloxGameVault/00_Command_Center/Build Health.md` says `Overall: PASS`.
4. Complete G5 in Creator Hub with the smallest Open Cloud scope needed to publish the target place.
5. Create `secrets/opencloud.env` locally:

```text
OPEN_CLOUD_API_KEY=replace_with_open_cloud_key
ROBLOX_UNIVERSE_ID=replace_with_numeric_universe_id
ROBLOX_PLACE_ID=replace_with_numeric_place_id
```

6. Run the live command only after a fixture dry-run passes:

```powershell
$env:ROKIT_PROBE='1'; lune run tools/open_cloud_publish.luau --live
```

## Secret Safety Check

```powershell
git log -p -- secrets .env | Select-String -Pattern "key|token"
```

Expected result: no output.
