import json
import random
import string
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GLTF_PATH = "res://Assets/World/WoodObjects/Gltf/WoodenObjects.gltf"
GLTF_UID = "uid://c38nq054y6jng"
MATERIAL_PATH = "res://Assets/World/WoodObjects/materials/wood_prop.tres"
MATERIAL_UID = "uid://cwoodprop01mat"
OUT_DIR = ROOT / "Assets/World/WoodObjects/Scenes/objects"


def godot_uid() -> str:
	chars = string.ascii_lowercase + string.digits
	return "uid://" + "".join(random.choices(chars, k=13))


def fmt_float(value: float) -> str:
	text = f"{value:.6f}".rstrip("0").rstrip(".")
	return text if text else "0"


def mesh_local_offset(gltf: dict, mesh_index: int) -> tuple[float, float, float]:
	mesh = gltf["meshes"][mesh_index]
	min_bounds = [float("inf"), float("inf"), float("inf")]
	max_bounds = [-float("inf"), -float("inf"), -float("inf")]

	for primitive in mesh["primitives"]:
		position_index = primitive["attributes"]["POSITION"]
		accessor = gltf["accessors"][position_index]
		for axis in range(3):
			min_bounds[axis] = min(min_bounds[axis], accessor["min"][axis])
			max_bounds[axis] = max(max_bounds[axis], accessor["max"][axis])

	center_x = (min_bounds[0] + max_bounds[0]) * 0.5
	center_z = (min_bounds[2] + max_bounds[2]) * 0.5
	return (-center_x, -min_bounds[1], -center_z)


def make_scene(obj: dict, objects: list[dict]) -> str:
	name = obj["name"]
	idx = obj["index"]
	offset_x, offset_y, offset_z = obj["offset"]
	lines = [
		f'[gd_scene load_steps=3 format=3 uid="{godot_uid()}"]',
		"",
		f'[ext_resource type="PackedScene" uid="{GLTF_UID}" path="{GLTF_PATH}" id="1_gltf"]',
		f'[ext_resource type="Material" uid="{MATERIAL_UID}" path="{MATERIAL_PATH}" id="2_mat"]',
		"",
		f'[node name="{name}" type="Node3D"]',
		"",
		f'[node name="WoodenObjects" parent="." instance=ExtResource("1_gltf")]',
	]

	for other in objects:
		if other["index"] == idx:
			continue
		lines.extend([
			"",
			f'[node name="{other["name"]}" parent="WoodenObjects" index="{other["index"]}"]',
			"visible = false",
		])

	lines.extend([
		"",
		f'[node name="{name}" parent="WoodenObjects" index="{idx}"]',
		(
			f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, "
			f"{fmt_float(offset_x)}, {fmt_float(offset_y)}, {fmt_float(offset_z)})"
		),
		'surface_material_override/0 = ExtResource("2_mat")',
	])

	for child in obj["colonly_children"]:
		lines.extend([
			"",
			f'[node name="{child}" parent="WoodenObjects/{name}" index="0"]',
			"visible = false",
		])

	return "\n".join(lines) + "\n"


def main() -> None:
	with open(ROOT / "Assets/World/WoodObjects/Gltf/WoodenObjects.gltf", encoding="utf-8") as file:
		gltf = json.load(file)

	nodes = gltf["nodes"]
	objects: list[dict] = []
	for index, node_index in enumerate(gltf["scenes"][0]["nodes"]):
		node = nodes[node_index]
		child_names = [nodes[child_index]["name"] for child_index in node.get("children", [])]
		mesh_index = node["mesh"]
		objects.append({
			"index": index,
			"name": node["name"],
			"offset": mesh_local_offset(gltf, mesh_index),
			"colonly_children": [child_name for child_name in child_names if "colonly" in child_name.lower()],
		})

	OUT_DIR.mkdir(parents=True, exist_ok=True)
	for obj in objects:
		path = OUT_DIR / f"{obj['name']}.tscn"
		path.write_text(make_scene(obj, objects), encoding="utf-8")
		print(f"Wrote {path.name}")

	print(f"Generated {len(objects)} scenes in {OUT_DIR}")


if __name__ == "__main__":
	main()
