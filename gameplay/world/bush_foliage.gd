extends Node3D

const GameAudio := preload("res://gameplay/audio/game_audio.gd")
const LeafBurstFX := preload("res://gameplay/fx/leaf_burst_fx.gd")

const PLAYER_GROUPS: Array[StringName] = [&"overworld_player", &"player"]
const RUSTLE_COOLDOWN := 0.6
const DEFAULT_TRIGGER_SIZE := Vector3(1.35, 1.1, 1.35)

var _rustle_cooldown := 0.0
var _trigger_area: Area3D


func _ready() -> void:
	add_to_group("decorative_foliage")
	_disable_physics_recursive(self)
	_remove_prop_collision()
	_setup_trigger_area()


func _process(delta: float) -> void:
	_rustle_cooldown = maxf(_rustle_cooldown - delta, 0.0)


func _setup_trigger_area() -> void:
	_trigger_area = Area3D.new()
	_trigger_area.name = "RustleTrigger"
	_trigger_area.collision_layer = 0
	_trigger_area.collision_mask = 1
	_trigger_area.monitoring = true
	_trigger_area.monitorable = false
	add_child(_trigger_area)
	_trigger_area.body_entered.connect(_on_body_entered)

	var shape_node := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = _estimate_trigger_size()
	shape_node.shape = box
	shape_node.position = Vector3(0.0, box.size.y * 0.42, 0.0)
	_trigger_area.add_child(shape_node)


func _estimate_trigger_size() -> Vector3:
	var local_aabb := AABB()
	var found := false

	for mesh_inst: MeshInstance3D in find_children("*", "MeshInstance3D", true, false):
		if mesh_inst.mesh == null:
			continue
		var mesh_aabb := mesh_inst.mesh.get_aabb()
		var mesh_xform := mesh_inst.transform
		for corner in _aabb_corners(mesh_aabb):
			var point := mesh_xform * corner
			if not found:
				local_aabb = AABB(point, Vector3.ZERO)
				found = true
			else:
				local_aabb = local_aabb.expand(point)

	if not found:
		return DEFAULT_TRIGGER_SIZE

	var size := local_aabb.size
	return Vector3(
		maxf(size.x, 0.8),
		maxf(size.y, 0.7),
		maxf(size.z, 0.8)
	)


static func _aabb_corners(aabb: AABB) -> Array[Vector3]:
	return [
		aabb.position,
		aabb.position + Vector3(aabb.size.x, 0.0, 0.0),
		aabb.position + Vector3(0.0, aabb.size.y, 0.0),
		aabb.position + Vector3(0.0, 0.0, aabb.size.z),
		aabb.position + Vector3(aabb.size.x, aabb.size.y, 0.0),
		aabb.position + Vector3(aabb.size.x, 0.0, aabb.size.z),
		aabb.position + Vector3(0.0, aabb.size.y, aabb.size.z),
		aabb.end,
	]


func _on_body_entered(body: Node3D) -> void:
	if not _is_walker(body) or _rustle_cooldown > 0.0:
		return

	_rustle_cooldown = RUSTLE_COOLDOWN
	var effect_position := _trigger_area.global_position
	var trigger_shape := _trigger_area.get_child(0) as CollisionShape3D
	if trigger_shape != null:
		effect_position += trigger_shape.position
	GameAudio.play_leaves_rustle(self, effect_position)

	var shove_dir := body.global_position - global_position
	shove_dir.y = 0.0
	LeafBurstFX.spawn(self, effect_position, shove_dir)


func _is_walker(body: Node) -> bool:
	for group_name: StringName in PLAYER_GROUPS:
		if body.is_in_group(group_name):
			return true
	return false


func _remove_prop_collision() -> void:
	var prop_collision := get_node_or_null("PropCollision")
	if prop_collision != null:
		prop_collision.queue_free()


func _disable_physics_recursive(node: Node) -> void:
	if node is CollisionObject3D:
		var body := node as CollisionObject3D
		body.collision_layer = 0
		body.collision_mask = 0
		body.add_to_group("camera_ray_exclude")
	elif node is CollisionShape3D:
		(node as CollisionShape3D).disabled = true
	for child in node.get_children():
		_disable_physics_recursive(child)
