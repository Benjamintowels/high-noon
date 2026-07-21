#!/usr/bin/env python3
"""Generate nature instancer PackedScenes and register them on stage1_terrain_assets.tres."""

from __future__ import annotations

import random
import re
import string
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GLTF_DIR = ROOT / "Assets" / "World" / "nature" / "glTF"
OUT_DIR = ROOT / "Assets" / "World" / "nature" / "instancer"
ASSETS_TRES = ROOT / "stages" / "stage1" / "terrain" / "stage1_terrain_assets.tres"
FOLIAGE_SCRIPT = "res://gameplay/world/decorative_foliage.gd"
FOLIAGE_UID = "uid://dbuwi628dyxkx"

# Ground cover / mid / trees — matches plan LOD defaults.
GROUND_COVER_PREFIXES = (
	"Pebble_",
	"Petal_",
	"Clover_",
	"Grass_",
	"Mushroom_",
	"Flower_",
)
MID_PROP_PREFIXES = (
	"Bush_",
	"Plant_",
	"Fern_",
	"Rock_Medium_",
	"RockPath_",
)
TREE_PREFIXES = (
	"CommonTree_",
	"DeadTree_",
	"Pine_",
	"TwistedTree_",
)


def godot_uid() -> str:
	chars = string.ascii_lowercase + string.digits
	return "uid://" + "".join(random.choices(chars, k=13))


def read_import_uid(gltf_path: Path) -> str | None:
	import_path = Path(str(gltf_path) + ".import")
	if not import_path.is_file():
		return None
	text = import_path.read_text(encoding="utf-8")
	match = re.search(r'^uid="(uid://[^"]+)"', text, re.MULTILINE)
	return match.group(1) if match else None


def lod_range_for(name: str) -> float:
	if name.startswith(TREE_PREFIXES):
		return 256.0
	if name.startswith(MID_PROP_PREFIXES):
		return 128.0
	if name.startswith(GROUND_COVER_PREFIXES):
		return 96.0
	return 128.0


def make_wrapper_scene(name: str, gltf_uid: str | None, scene_uid: str) -> str:
	gltf_res = f"res://Assets/World/nature/glTF/{name}.gltf"
	uid_attr = f' uid="{gltf_uid}"' if gltf_uid else ""
	return "\n".join(
		[
			f'[gd_scene load_steps=3 format=3 uid="{scene_uid}"]',
			"",
			f'[ext_resource type="PackedScene"{uid_attr} path="{gltf_res}" id="1_gltf"]',
			f'[ext_resource type="Script" uid="{FOLIAGE_UID}" path="{FOLIAGE_SCRIPT}" id="2_foliage"]',
			"",
			f'[node name="{name}" instance=ExtResource("1_gltf")]',
			"script = ExtResource(\"2_foliage\")",
			"",
		]
	)


def rebuild_assets_tres(entries: list[dict]) -> None:
	text = ASSETS_TRES.read_text(encoding="utf-8")

	# Drop any prior nature instancer ext_resources / mesh subresources we may have added.
	text = re.sub(
		r'\n\[ext_resource type="PackedScene"[^\]]*path="res://Assets/World/nature/instancer/[^"]+"[^\]]*\]\n?',
		"\n",
		text,
	)
	text = re.sub(
		r'\n\[sub_resource type="Terrain3DMeshAsset" id="Terrain3DMeshAsset_nature_[^"]+"\]\n(?:[^\[]*\n)*',
		"\n",
		text,
	)

	ext_lines: list[str] = []
	sub_lines: list[str] = []
	mesh_refs = [
		'SubResource("Terrain3DMeshAsset_qifc2")',
		'SubResource("Terrain3DMeshAsset_higfk")',
		'SubResource("Terrain3DMeshAsset_uiefx")',
	]

	for entry in entries:
		ext_id = entry["ext_id"]
		sub_id = entry["sub_id"]
		uid_attr = f' uid="{entry["scene_uid"]}"'
		ext_lines.append(
			f'[ext_resource type="PackedScene"{uid_attr} path="{entry["scene_path"]}" id="{ext_id}"]'
		)
		sub_lines.extend(
			[
				f'[sub_resource type="Terrain3DMeshAsset" id="{sub_id}"]',
				f'name = "{entry["name"]}"',
				f'id = {entry["mesh_id"]}',
				f'scene_file = ExtResource("{ext_id}")',
				"last_lod = 0",
				"last_shadow_lod = 0",
				f'lod0_range = {entry["lod0_range"]}',
				"",
			]
		)
		mesh_refs.append(f'SubResource("{sub_id}")')

	# Insert ext_resources after the last existing ext_resource block.
	last_ext = None
	for match in re.finditer(r'^\[ext_resource[^\]]*\]\n', text, re.MULTILINE):
		last_ext = match
	if last_ext is None:
		raise RuntimeError("No ext_resource blocks found in terrain assets")
	insert_at = last_ext.end()
	text = text[:insert_at] + "\n".join(ext_lines) + "\n" + text[insert_at:]

	# Insert mesh subresources just before the generated-card StandardMaterial3D
	# (keeps original grass mesh assets first, nature meshes after id 2 setup).
	# Prefer inserting right before [resource] so texture subresources stay grouped.
	resource_match = re.search(r'^\[resource\]\n', text, re.MULTILINE)
	if resource_match is None:
		raise RuntimeError("No [resource] block found in terrain assets")
	text = (
		text[: resource_match.start()]
		+ "\n".join(sub_lines)
		+ "\n"
		+ text[resource_match.start() :]
	)

	mesh_list_value = "Array[Terrain3DMeshAsset]([" + ", ".join(mesh_refs) + "])"
	text, count = re.subn(
		r'^mesh_list = Array\[Terrain3DMeshAsset\]\(\[[^\]]*\]\)\s*$',
		f"mesh_list = {mesh_list_value}",
		text,
		count=1,
		flags=re.MULTILINE,
	)
	if count != 1:
		raise RuntimeError("Failed to rewrite mesh_list")

	ASSETS_TRES.write_text(text, encoding="utf-8", newline="\n")


def main() -> None:
	gltf_files = sorted(GLTF_DIR.glob("*.gltf"))
	if not gltf_files:
		raise SystemExit(f"No glTF files in {GLTF_DIR}")

	OUT_DIR.mkdir(parents=True, exist_ok=True)

	entries: list[dict] = []
	for index, gltf_path in enumerate(gltf_files):
		name = gltf_path.stem
		gltf_uid = read_import_uid(gltf_path)
		scene_uid = godot_uid()
		scene_path = f"res://Assets/World/nature/instancer/{name}.tscn"
		out_path = OUT_DIR / f"{name}.tscn"
		out_path.write_text(
			make_wrapper_scene(name, gltf_uid, scene_uid),
			encoding="utf-8",
			newline="\n",
		)
		uid_path = Path(str(out_path) + ".uid")
		uid_path.write_text(scene_uid + "\n", encoding="utf-8", newline="\n")
		mesh_id = 3 + index
		safe = name.lower()
		entries.append(
			{
				"name": name,
				"mesh_id": mesh_id,
				"scene_uid": scene_uid,
				"scene_path": scene_path,
				"ext_id": f"n_{safe}",
				"sub_id": f"Terrain3DMeshAsset_nature_{safe}",
				"lod0_range": lod_range_for(name),
			}
		)
		print(f"Wrote {out_path.relative_to(ROOT)} (mesh id {mesh_id})")

	rebuild_assets_tres(entries)
	print(f"Updated {ASSETS_TRES.relative_to(ROOT)} with {len(entries)} nature mesh assets")


if __name__ == "__main__":
	main()
