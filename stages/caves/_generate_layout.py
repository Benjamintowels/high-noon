"""One-off generator for caves_ruins_layout.tscn — run from repo root if layout needs rebaking."""
import math
from pathlib import Path

TILE = 6.6
RESOURCES = {
	"block_md": "res://Assets/World/RuinsGR/BlocksScenes/BlockNormalMD.tscn",
	"block_moss": "res://Assets/World/RuinsGR/BlocksScenes/BlockMossMD.tscn",
	"block_crack": "res://Assets/World/RuinsGR/BlocksScenes/BlockCrackMD.tscn",
	"wall_md": "res://Assets/World/RuinsGR/WallScenes/WallNormalMD.tscn",
	"wall_broken": "res://Assets/World/RuinsGR/WallScenes/WallBrokenMD.tscn",
	"pillar_round": "res://Assets/World/RuinsGR/PillarsScenes/PillarRound.tscn",
	"pillar_square": "res://Assets/World/RuinsGR/PillarsScenes/PillarSquare.tscn",
	"wall_light": "res://Assets/World/RuinsGR/AccessoriesScenes/WallLightFire.tscn",
	"chest": "res://Assets/World/RuinsGR/AccessoriesScenes/ChestBase.tscn",
	"skull": "res://Assets/World/RuinsGR/AccessoriesScenes/Skull.tscn",
	"stairs": "res://Assets/World/RuinsGR/StairsScenes/StairsMD.tscn",
}


def transform(tx: float, tz: float, yaw: float = 0.0) -> str:
	c = math.cos(yaw)
	s = math.sin(yaw)
	x = tx * TILE
	z = tz * TILE
	return f"Transform3D({c}, 0, {s}, 0, 1, 0, {-s}, 0, {c}, {x}, 0, {z})"


nodes: list[tuple[str, str, str, float, float, float]] = []
counter = 0


def add_node(parent: str, res_key: str, name_prefix: str, tx: float, tz: float, yaw: float = 0.0) -> None:
	global counter
	counter += 1
	nodes.append((parent, res_key, f"{name_prefix}_{counter}", tx, tz, yaw))


for x in range(-3, 4):
	for z in range(-2, 5):
		key = "block_moss" if (x + z) % 2 == 0 else "block_md"
		add_node("Floor", key, key, x, z)

for z in range(0, 4):
	add_node("Floor", "block_crack", "block_crack", -1, z)
	add_node("Floor", "block_crack", "block_crack", 1, z)

for x in range(-3, 4):
	add_node("Structures", "wall_md", "wall_md", x, -3)
	add_node("Structures", "wall_broken", "wall_broken", x, 5)

for z in range(-2, 5):
	add_node("Structures", "wall_md", "wall_md", -4, z, math.pi * 0.5)
	add_node("Structures", "wall_md", "wall_md", 4, z, math.pi * 0.5)

add_node("Structures", "stairs", "stairs", 0, 4, math.pi)
add_node("Structures", "pillar_round", "pillar_round", -2, 1)
add_node("Structures", "pillar_square", "pillar_square", 2, 2)
add_node("Structures", "pillar_round", "pillar_round", -2, 3)
add_node("Structures", "chest", "chest", 2, 0, math.pi * 0.25)
add_node("Structures", "skull", "skull", -2, 0)
add_node("Structures", "wall_light", "wall_light", -3, 1, math.pi * 0.5)
add_node("Structures", "wall_light", "wall_light", 3, 3, -math.pi * 0.5)
add_node("Structures", "wall_light", "wall_light", 0, -2)

used_keys = sorted({n[1] for n in nodes})
key_to_id = {k: i + 1 for i, k in enumerate(used_keys)}

lines: list[str] = []
lines.append(f"[gd_scene load_steps={len(used_keys) + 1} format=3 uid=\"uid://ccavesruinslayout01\"]")
lines.append("")
for key in used_keys:
	rid = key_to_id[key]
	lines.append(f'[ext_resource type="PackedScene" path="{RESOURCES[key]}" id="{rid}_{key}"]')
lines.append("")
lines.append('[node name="CavesRuinsLayout" type="Node3D"]')
lines.append("")
lines.append('[node name="Floor" type="Node3D" parent="."]')
lines.append("")
lines.append('[node name="Structures" type="Node3D" parent="."]')
lines.append("")
lines.append('[node name="Obstacles" type="Node3D" parent="."]')
lines.append("")

for parent, res_key, name, tx, tz, yaw in nodes:
	rid = key_to_id[res_key]
	tf = transform(tx, tz, yaw)
	lines.append(f'[node name="{name}" parent="{parent}" instance=ExtResource("{rid}_{res_key}")]')
	lines.append(f"transform = {tf}")
	lines.append("")

out_path = Path(__file__).with_name("caves_ruins_layout.tscn")
out_path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8", newline="\n")
print(f"Wrote {len(nodes)} nodes to {out_path}")
