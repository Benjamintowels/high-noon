class_name Stage1VisualSetup
extends RefCounted

const BUILDING_MATERIAL_APPLIER := preload("res://Assets/World/Buildings/building_material_applier.gd")
const STAGE_PROP_MATERIAL_APPLIER := preload("res://stages/stage1/stage_prop_material_applier.gd")
const WOOD_PROP_COLLISION := preload("res://gameplay/world/wood_prop_collision.gd")
const WALLS_MATERIAL := preload("res://Assets/World/Buildings/materials/building_walls.tres")
const ROCK_MATERIAL := preload("res://stages/stage1/materials/desert_rock.tres")

const SKIP_MESH_SWEEP_NAMES := {
	"BulletCover": true,
	"TerrainCollision": true,
	"PropCollision": true,
	"FloorTileCollision": true,
}

## Small/mid decorative props stop rendering (and shadow-casting) beyond
## these distances, with a dithered self-fade. Matched by node-name prefix
## (lowercased) on the prop root; mountains and buildings are never matched.
const DISTANCE_FADE_RULES := [
	{"prefixes": ["bush", "grass", "crop_"], "end": 100.0},
	{"prefixes": ["fence_planks", "box", "barrel_", "cart_"], "end": 130.0},
	{"prefixes": ["cactus"], "end": 150.0},
	{"prefixes": ["tree", "pine_tree", "deserttree"], "end": 180.0},
]


static func apply_materials(stage: Node) -> void:
	if stage == null:
		return

	var town := stage.get_node_or_null("Town") as Node
	if town != null:
		BUILDING_MATERIAL_APPLIER.apply_with_fallbacks(town)
		STAGE_PROP_MATERIAL_APPLIER.apply_to(town)

	BUILDING_MATERIAL_APPLIER.apply_with_fallbacks(stage)
	STAGE_PROP_MATERIAL_APPLIER.apply_to(stage)
	WOOD_PROP_COLLISION.disable_hidden_prop_physics(stage)
	_apply_untextured_mesh_sweep(stage)
	_apply_distance_fade_sweep(stage)


static func _apply_untextured_mesh_sweep(root: Node) -> void:
	if root == null:
		return
	_sweep_meshes(root)


static func _sweep_meshes(node: Node) -> void:
	if SKIP_MESH_SWEEP_NAMES.has(node.name):
		return

	if node is MeshInstance3D:
		var mesh_inst := node as MeshInstance3D
		if BUILDING_MATERIAL_APPLIER.mesh_needs_material_fix(mesh_inst):
			BUILDING_MATERIAL_APPLIER.apply_fallback_material(
				mesh_inst,
				_infer_material_for_mesh(mesh_inst)
			)

	for child in node.get_children():
		_sweep_meshes(child)


static func _apply_distance_fade_sweep(node: Node) -> void:
	var lower := String(node.name).to_lower()
	for rule: Dictionary in DISTANCE_FADE_RULES:
		var matched := false
		for prefix: String in rule.prefixes:
			if lower.begins_with(prefix):
				matched = true
				break
		if matched:
			_apply_fade_to_geometry(node, rule.end)
			return

	for child in node.get_children():
		_apply_distance_fade_sweep(child)


static func _apply_fade_to_geometry(root: Node, end_distance: float) -> void:
	if root is GeometryInstance3D:
		var geo := root as GeometryInstance3D
		geo.visibility_range_end = end_distance
		geo.visibility_range_end_margin = end_distance * 0.1
		geo.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	for child in root.get_children():
		_apply_fade_to_geometry(child, end_distance)


static func _infer_material_for_mesh(mesh_inst: MeshInstance3D) -> Material:
	var current: Node = mesh_inst
	while current != null:
		var prop_material := STAGE_PROP_MATERIAL_APPLIER.material_for_prop_name(current.name)
		if prop_material != null:
			return prop_material
		if current.name.begins_with("Build_") or current.name.begins_with("Signs_"):
			return WALLS_MATERIAL
		current = current.get_parent()
	return ROCK_MATERIAL
