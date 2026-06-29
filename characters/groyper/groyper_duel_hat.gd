extends Node
class_name GroyperDuelHat

## Match-persistent cowboy hat — worn at round start until a defeat knocks it off.

const DROPPED_HAT := preload("res://characters/groyper/groyper_dropped_hat.gd")
const WORLD_PICKUP := preload("res://characters/groyper/groyper_hat_world_pickup.gd")
const HAT_MATERIAL := preload("res://characters/groyper/cowboy_hat_material.tres")

var _skeleton: Skeleton3D
var _mount: BoneAttachment3D
var _hat_offset: Node3D
var _hat_visual: Node3D
var _hat_material: Material = HAT_MATERIAL
var _round_had_hat := true
var _on_head := false
var _lasso_knocked_off := false
var _dropped_body: GroyperDroppedHat
var _world_pickup: GroyperHatWorldPickup
var _hat_restore: Dictionary = {}


func bind_skeleton(skeleton: Skeleton3D, hat_material: Material = null) -> void:
	if skeleton == null:
		return

	_skeleton = skeleton
	_hat_material = hat_material if hat_material != null else HAT_MATERIAL
	refresh_hat_nodes()


func refresh_hat_nodes(skeleton: Skeleton3D = null) -> void:
	if skeleton != null:
		_skeleton = skeleton
	if _skeleton == null:
		return

	_mount = _skeleton.get_node_or_null("CowboyHatMount") as BoneAttachment3D
	if _mount == null:
		push_warning("GroyperDuelHat: missing CowboyHatMount on skeleton.")
		return

	_hat_offset = _mount.get_node_or_null("HatOffset") as Node3D
	if _hat_visual == null or not _is_hat_on_mount():
		_hat_visual = _mount.get_node_or_null("HatOffset/CowboyHat") as Node3D
	if _hat_visual == null:
		push_warning("GroyperDuelHat: missing CowboyHat visual under mount.")
		return

	_apply_hat_materials(_hat_visual)
	if _is_hat_on_mount():
		_on_head = true


func _apply_hat_materials(hat_visual: Node3D) -> void:
	if hat_visual == null:
		return

	for mesh in hat_visual.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := mesh as MeshInstance3D
		if mesh_instance.mesh == null:
			continue

		mesh_instance.material_override = _hat_material
		for surface_idx in mesh_instance.mesh.get_surface_count():
			mesh_instance.set_surface_override_material(surface_idx, _hat_material)


func prepare_for_round(match_hat_lost: bool) -> void:
	_round_had_hat = not match_hat_lost
	if match_hat_lost:
		release_dropped_hat_to_world()
		_hide_head_hat()
	else:
		_cleanup_dropped_body()
		_equip_on_head()


func restore_for_replay() -> void:
	if not _round_had_hat:
		return
	_cleanup_dropped_body()
	_equip_on_head()


func can_drop() -> bool:
	if not _round_had_hat or _lasso_knocked_off:
		return false
	if _dropped_body != null and is_instance_valid(_dropped_body):
		return false
	refresh_hat_nodes()
	return _hat_visual != null and is_instance_valid(_hat_visual) and _is_hat_on_mount()


func drop_from_head(hit_info: Dictionary, world_parent: Node, actor: Node3D) -> void:
	if not can_drop():
		return

	_on_head = false
	_hat_restore = {
		"offset": _hat_offset,
		"local_transform": _hat_visual.transform,
	}

	_dropped_body = DROPPED_HAT.launch_from_visual(_hat_visual, hit_info, world_parent, actor)

	if _mount != null:
		_mount.visible = false


func knock_off_for_lasso(
	_hit_info: Dictionary,
	world_parent: Node,
	_actor: Node3D,
	hat_id: StringName,
	drop_anchor: Vector3
) -> void:
	if _lasso_knocked_off:
		return
	if not can_drop():
		return

	_lasso_knocked_off = true
	_round_had_hat = false
	_on_head = false
	if _mount != null:
		_mount.visible = false

	_world_pickup = WORLD_PICKUP.spawn_from_visual(
		_hat_visual,
		hat_id,
		drop_anchor,
		world_parent,
		_actor
	)
	_hat_visual = null
	_dropped_body = null


func should_restore_after_ragdoll() -> bool:
	return not _lasso_knocked_off


func release_dropped_hat_to_world() -> void:
	if is_instance_valid(_dropped_body):
		_dropped_body.add_to_group(GroyperDroppedHat.HAT_PROP_GROUP)
		_dropped_body = null
		_hat_visual = null
		_hat_restore.clear()
		_on_head = false
		return

	_hide_head_hat()


func restore_to_head_if_needed() -> void:
	if not _round_had_hat or _lasso_knocked_off:
		return
	_cleanup_dropped_body()
	_equip_on_head()


func _equip_on_head() -> void:
	if _mount == null:
		return

	if _hat_visual == null:
		_hat_visual = _mount.get_node_or_null("HatOffset/CowboyHat") as Node3D

	if _hat_visual != null:
		if not _hat_visual.is_inside_tree() and _hat_offset != null:
			_hat_offset.add_child(_hat_visual)
		if not _hat_restore.is_empty():
			_hat_visual.transform = _hat_restore.get("local_transform", _hat_visual.transform)
		_hat_visual.visible = true

	_mount.visible = true
	_on_head = _hat_visual != null


func _hide_head_hat() -> void:
	_on_head = false
	if _mount != null:
		_mount.visible = false
	if _hat_visual != null and is_instance_valid(_hat_visual):
		_hat_visual.visible = false


func _is_hat_on_mount() -> bool:
	if _hat_visual == null or _mount == null:
		return false
	var node: Node = _hat_visual
	while node != null:
		if node == _mount:
			return true
		node = node.get_parent()
	return false


func _cleanup_dropped_body() -> void:
	if not is_instance_valid(_dropped_body):
		_dropped_body = null
		_hat_restore.clear()
		return

	var restored_visual := _hat_visual
	if restored_visual == null or not is_instance_valid(restored_visual):
		restored_visual = _dropped_body.find_child("CowboyHat", true, false) as Node3D
	if restored_visual != null and _hat_offset != null and is_instance_valid(_hat_offset):
		var visual_global := restored_visual.global_transform
		_dropped_body.remove_child(restored_visual)
		_hat_offset.add_child(restored_visual)
		restored_visual.global_transform = visual_global
		if not _hat_restore.is_empty():
			restored_visual.transform = _hat_restore.get("local_transform", restored_visual.transform)
		_hat_visual = restored_visual
		_apply_hat_materials(_hat_visual)

	_dropped_body.queue_free()
	_dropped_body = null
	_hat_restore.clear()
