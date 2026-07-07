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
