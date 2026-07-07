class_name StagePropMaterialApplier
extends RefCounted

const BUILDING_MATERIAL_APPLIER := preload("res://Assets/World/Buildings/building_material_applier.gd")
const ROCK_MATERIAL := preload("res://stages/stage1/materials/desert_rock.tres")
const CACTUS_MATERIAL := preload("res://stages/stage1/materials/desert_cactus.tres")
const TREE_MATERIAL := preload("res://stages/stage1/materials/desert_tree.tres")
const WOOD_PROP_MATERIAL := preload("res://Assets/World/WoodObjects/materials/wood_prop.tres")
const FENCE_MATERIAL := preload("res://stages/stage1/materials/fence_planks.tres")


static func apply_to(root: Node) -> void:
	if root == null:
		return
	_walk(root)


static func _walk(node: Node) -> void:
	_apply_node(node)
	for child in node.get_children():
		_walk(child)


static func _apply_node(node: Node) -> void:
	if node.name.begins_with("Build_"):
		return

	if node.name.begins_with("Signs_"):
		BUILDING_MATERIAL_APPLIER.apply_with_fallbacks(node)
		return

	var material := material_for_prop_name(node.name)
	if material != null:
		_apply_material_to_untextured_meshes(node, material)


static func material_for_prop_name(node_name: String) -> Material:
	var lower := node_name.to_lower()
	if lower.begins_with("cactus") or lower.begins_with("desertcactus"):
		return CACTUS_MATERIAL
	if lower.begins_with("deserttree"):
		return TREE_MATERIAL
	if lower.begins_with("desertrock") or lower.begins_with("desertlarge"):
		return ROCK_MATERIAL
	if lower.begins_with("tree") or lower.begins_with("pine_tree"):
		return TREE_MATERIAL
	if lower.contains("mountain") or lower.contains("cliff") or lower == "desert_plane":
		return ROCK_MATERIAL
	if lower.begins_with("fence_planks"):
		return FENCE_MATERIAL
	if lower.begins_with("cart_") or lower.begins_with("barrel_") or lower.begins_with("box"):
		return WOOD_PROP_MATERIAL
	return null


static func _apply_material_to_untextured_meshes(root: Node, material: Material) -> void:
	if root is MeshInstance3D:
		BUILDING_MATERIAL_APPLIER.apply_fallback_material(root as MeshInstance3D, material)
	for child in root.get_children():
		_apply_material_to_untextured_meshes(child, material)
