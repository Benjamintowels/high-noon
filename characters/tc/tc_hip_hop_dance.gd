extends RefCounted
class_name TcHipHopDance

const TcFallingBoulderScript := preload("res://characters/tc/tc_falling_boulder.gd")
const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")

const COOLDOWN := 22.0
const LOOP_CHANCE := 0.45
const DROP_HEIGHT := 9.0
const BOULDER_INTERVAL := 0.55
const BOULDER_COUNT_MIN := 1
const BOULDER_COUNT_MAX := 2
const SPAWN_RADIUS_MIN := 3.5
const SPAWN_RADIUS_MAX := 11.0
const CAMERA_SHAKE := 0.58
const CAMERA_SHAKE_PULSE := 0.22


static func can_cast(cooldown: float) -> bool:
	return cooldown <= 0.0


static func apply_camera_shake_pulse(boss: Node) -> void:
	var tree := boss.get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group(&"overworld_player"):
		if node.has_method("apply_camera_shake"):
			node.apply_camera_shake(CAMERA_SHAKE_PULSE)


static func spawn_boulder_volley(boss: Node, aim_target: Node3D) -> void:
	var actor := boss as Node3D
	if actor == null:
		return

	var anchor := actor.global_position
	if aim_target != null and is_instance_valid(aim_target):
		anchor = aim_target.global_position

	var count := randi_range(BOULDER_COUNT_MIN, BOULDER_COUNT_MAX)
	var fx_parent := ImpactFXScript.parent_for(actor)
	for _i in count:
		var ground_point := _pick_drop_point(actor, anchor)
		var boulder := TcFallingBoulderScript.new()
		boulder.name = "TcFallingBoulder"
		fx_parent.add_child(boulder)
		boulder.setup(boss, ground_point)


static func _pick_drop_point(boss: Node3D, anchor: Vector3) -> Vector3:
	var angle := randf_range(0.0, TAU)
	var distance := randf_range(SPAWN_RADIUS_MIN, SPAWN_RADIUS_MAX)
	var offset := Vector3(cos(angle), 0.0, sin(angle)) * distance
	var point := anchor + offset
	point.y = boss.global_position.y
	return _snap_to_floor(boss, point)


static func _snap_to_floor(boss: Node3D, point: Vector3) -> Vector3:
	var space := boss.get_world_3d().direct_space_state
	if space == null:
		return point

	var from := point + Vector3(0.0, DROP_HEIGHT + 2.0, 0.0)
	var to := point - Vector3(0.0, 8.0, 0.0)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = boss.collision_mask
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return point
	return hit.get("position", point)
