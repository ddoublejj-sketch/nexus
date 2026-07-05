# Release Checklist

WO-9 keeps publish one explicit step away. Dry-run is safe to run without an Open Cloud key; live publish requires G5.

## Dry Run

```powershell
./nexus.ps1 check
./nexus.ps1 health
./nexus.ps1 open-cloud
./nexus.ps1 release --dry-run --fixture
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

6. Run `./nexus.ps1 open-cloud` again; it records readiness without writing key, universe, place, endpoint, or dry-run output values into the vault.
7. Run the live command only after a fixture dry-run passes:

```powershell
./nexus.ps1 release --live
```

If Roblox returns `401 Unauthorized` with insufficient scopes, edit the Open Cloud API key in Creator Hub and add the place-publishing write permission for the Golf Pro experience/place, then rerun the same live command.

## Secret Safety Check

```powershell
git log -p -- secrets .env | Select-String -Pattern "key|token"
```

Expected result: no output.
