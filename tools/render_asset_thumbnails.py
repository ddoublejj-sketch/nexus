"""Render asset thumbnails from the Nexus asset manifest.

Run through Blender:
    blender --background --python tools/render_asset_thumbnails.py -- assets_export/manifests/assets.json
"""

from __future__ import annotations

import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path.cwd()
DEFAULT_MANIFEST = ROOT / "assets_export" / "manifests" / "assets.json"
DEFAULT_OUTPUT_ROOT = ROOT / "assets_export" / "thumbnails"


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()


def import_asset(path: Path) -> None:
    suffix = path.suffix.lower()
    if suffix == ".fbx":
        bpy.ops.import_scene.fbx(filepath=str(path))
    elif suffix in { ".glb", ".gltf" }:
        bpy.ops.import_scene.gltf(filepath=str(path))
    elif suffix == ".obj":
        bpy.ops.wm.obj_import(filepath=str(path))
    elif suffix == ".blend":
        with bpy.data.libraries.load(str(path), link=False) as (data_from, data_to):
            data_to.objects = data_from.objects
        for obj in data_to.objects:
            if obj is not None:
                bpy.context.collection.objects.link(obj)
    else:
        raise RuntimeError(f"Unsupported thumbnail source: {path}")


def mesh_objects() -> list[bpy.types.Object]:
    return [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]


def scene_bounds(objects: list[bpy.types.Object]) -> tuple[Vector, float]:
    corners: list[Vector] = []
    for obj in objects:
        corners.extend(obj.matrix_world @ Vector(corner) for corner in obj.bound_box)

    if not corners:
        return Vector((0.0, 0.0, 0.0)), 1.0

    minimum = Vector((min(point[i] for point in corners) for i in range(3)))
    maximum = Vector((max(point[i] for point in corners) for i in range(3)))
    center = (minimum + maximum) * 0.5
    extent = max((maximum - minimum).length, 1.0)
    return center, extent


def look_at(obj: bpy.types.Object, target: Vector) -> None:
    direction = target - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def setup_materials(objects: list[bpy.types.Object]) -> None:
    fallback = bpy.data.materials.new("Nexus thumbnail clay")
    fallback.diffuse_color = (0.74, 0.78, 0.82, 1.0)

    for obj in objects:
        if not obj.data.materials:
            obj.data.materials.append(fallback)


def setup_scene(center: Vector, extent: float) -> None:
    scene = bpy.context.scene
    scene.render.resolution_x = 512
    scene.render.resolution_y = 512
    scene.render.film_transparent = False
    scene.world = bpy.data.worlds.new("Nexus thumbnail world")
    scene.world.color = (0.04, 0.045, 0.055)

    for engine in ("BLENDER_EEVEE_NEXT", "BLENDER_EEVEE", "BLENDER_WORKBENCH"):
        try:
            scene.render.engine = engine
            break
        except TypeError:
            continue

    light_data = bpy.data.lights.new("Key Light", type="AREA")
    light_data.energy = 550
    light_data.size = max(extent, 2.0)
    light = bpy.data.objects.new("Key Light", light_data)
    light.location = center + Vector((extent * 0.7, -extent * 1.1, extent * 1.4))
    bpy.context.collection.objects.link(light)

    camera_data = bpy.data.cameras.new("Thumbnail Camera")
    camera_data.lens = 70
    camera = bpy.data.objects.new("Thumbnail Camera", camera_data)
    camera.location = center + Vector((extent * 1.15, -extent * 2.1, extent * 0.95))
    look_at(camera, center)
    bpy.context.collection.objects.link(camera)
    scene.camera = camera


def render_row(row: dict[str, object], output_root: Path) -> Path:
    asset_id = str(row["id"])
    source = ROOT / str(row.get("export") or row.get("source") or "")
    if not source.is_file():
        raise RuntimeError(f"{asset_id}: missing source/export file {source}")

    clear_scene()
    import_asset(source)
    objects = mesh_objects()
    if not objects:
        raise RuntimeError(f"{asset_id}: imported asset has no mesh objects")

    setup_materials(objects)
    center, extent = scene_bounds(objects)
    setup_scene(center, extent)

    output_root.mkdir(parents=True, exist_ok=True)
    output_path = output_root / f"{asset_id}.png"
    bpy.context.scene.render.filepath = str(output_path)
    bpy.ops.render.render(write_still=True)
    return output_path


def main() -> int:
    args = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    manifest_path = Path(args[0]) if args else DEFAULT_MANIFEST
    output_root = Path(args[1]) if len(args) > 1 else DEFAULT_OUTPUT_ROOT

    rows = json.loads(manifest_path.read_text(encoding="utf-8"))
    rendered: list[Path] = []
    for row in rows:
        rendered.append(render_row(row, output_root))

    for path in rendered:
        print(path.as_posix())

    print(f"Rendered {len(rendered)} asset thumbnail(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
