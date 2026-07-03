# Blender Export Runbook

Status: active. Blender CLI is available through the Nexus G1 tool closure.

## Scale And Orientation

- Author at Roblox scale: 1 Blender unit equals 1 Roblox stud.
- Keep the object origin at the intended Roblox pivot.
- Use a documented forward convention per asset family. Default for new assets: positive Z forward, positive Y up before export conversion.

## Mesh Hygiene

- Name meshes clearly by asset and role.
- Collision proxy meshes use the `_col` suffix.
- Keep separate material slots named for the intended Roblox material pass.
- Apply transforms before export.

## Tri Budget Tiers

| Tier | Use | Target |
| --- | --- | --- |
| Tiny | pickups, simple props | under 500 tris |
| Small | weapons, interactables | under 2,500 tris |
| Medium | hero props, kit pieces | under 8,000 tris |
| Large | rare set pieces | document case-by-case |

## Export

- Export Roblox-ready files to `assets_export/roblox`.
- Keep source files under `assets_src`.
- Generate thumbnails into `assets_export/thumbnails` with `./nexus.ps1 thumbnails`.
- Every export must have a manifest row in `assets_export/manifests/assets.json`.

## Thumbnail Rendering

Run this after adding or changing exported model files:

```powershell
./nexus.ps1 thumbnails
```

The command runs Blender headless through `tools/render_asset_thumbnails.py`, writes PNG thumbnails, and refreshes the asset manifest plus generated vault asset notes.
