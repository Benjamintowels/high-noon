extends RigidBody3D
class_name TabletopProp
## Small physics props (bottles, cans) that rest frozen on tables until bumped.
## Uses the pushable collision layer so walkers shove them instead of snagging
## on world-layer colliders, then wakes on contact so they tumble or ride along.

const TownNpcShoveScript := preload("res://gameplay/world/town_npc_shove.gd")

const PUSHABLE_COLLISION_LAYER := 2
const PUSHER_GROUPS: Array[StringName] = [
	&"overworld_player",
	&"player",
	&"town_npc",
]

const PUSHER_RADIUS := 0.36
const PROP_CONTACT_RADIUS := 0.11
const CONTACT_SLACK := 0.14
const PUSH_ALIGNMENT_MIN := 0.2
const PUSH_FORCE := 34.0
const PUNCH_IMPULSE := 7.0
const PUNCH_TORQUE := 2.2
const MOVING_PUSHABLE_WAKE_RADIUS := 0.5
const MOVING_PUSHABLE_MIN_SPEED_SQ := 0.3


func _ready() -> void:
	add_to_group(&"tabletop_prop")
	add_to_group(&"punchable_prop")
	collision_layer = PUSHABLE_COLLISION_LAYER
	collision_mask = TownNpcShoveScript.WORLD_COLLISION_LAYER
	continuous_cd = true


func _physics_process(_delta: float) -> void:
	if freeze:
		_check_nearby_moving_pushables()
	_apply_character_pushes()


func _check_nearby_moving_pushables() -> void:
	for node in get_tree().get_nodes_in_group(&"punchable_prop"):
		if node == self or not (node is RigidBody3D):
			continue
		var mover := node as RigidBody3D
		if mover.freeze:
			continue
		var speed_sq := mover.linear_velocity.length_squared()
		if speed_sq < MOVING_PUSHABLE_MIN_SPEED_SQ and mover.angular_velocity.length_squared() < 0.08:
			continue

		var mover_center := mover.global_position
		if mover.has_method("get_prop_center"):
			mover_center = mover.get_prop_center()
		var reach := MOVING_PUSHABLE_WAKE_RADIUS
		if mover.has_method("get_prop_contact_radius"):
			reach += mover.get_prop_contact_radius()
		if global_position.distance_squared_to(mover_center) > reach * reach:
			continue

		wake_from_table(mover)
		return


func wake_from_table(table: RigidBody3D = null) -> void:
	if not freeze:
		return
	collision_mask = collision_mask | TownNpcShoveScript.PUSHABLE_COLLISION_MASK
	freeze = false
	sleeping = false
	if table == null:
		return
	if table.linear_velocity.length_squared() > 0.0001:
		linear_velocity += table.linear_velocity
	if table.angular_velocity.length_squared() > 0.0001:
		angular_velocity += table.angular_velocity * 0.35

	var knock_dir := global_position - table.global_position
	if knock_dir.length_squared() < 0.0001:
		knock_dir = table.linear_velocity
	if knock_dir.length_squared() < 0.0001:
		knock_dir = Vector3.UP
	knock_dir = knock_dir.normalized()
	var table_speed := table.linear_velocity.length()
	if table_speed > 0.05:
		apply_impulse(
			(knock_dir + Vector3.UP * 0.18).normalized() * clampf(table_speed * mass * 0.4, 1.2, 8.0)
		)


func receive_punch(hit_info: Dictionary) -> void:
	wake_from_table()
	sleeping = false
	var dir: Vector3 = hit_info.get("direction", Vector3.ZERO)
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		dir = -global_transform.basis.z
	dir = dir.normalized()
	dir.y = 0.25
	apply_impulse(dir * PUNCH_IMPULSE * mass)
	apply_torque_impulse(Vector3(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	).normalized() * PUNCH_TORQUE)


func _apply_character_pushes() -> void:
	for group_name in PUSHER_GROUPS:
		for node in get_tree().get_nodes_in_group(group_name):
			if node is CharacterBody3D:
				_apply_push_from_mover(node as CharacterBody3D)


func _apply_push_from_mover(mover: CharacterBody3D) -> void:
	var offset := global_position - mover.global_position
	offset.y = 0.0
	var contact_range := PUSHER_RADIUS + PROP_CONTACT_RADIUS + CONTACT_SLACK
	if offset.length_squared() > contact_range * contact_range:
		return

	var intent := _get_mover_push_intent(mover)
	intent.y = 0.0
	if intent.length_squared() < 0.04:
		return
	var push_dir := offset.normalized()
	if intent.normalized().dot(push_dir) < PUSH_ALIGNMENT_MIN:
		return

	wake_from_table()
	sleeping = false
	apply_force(push_dir * PUSH_FORCE, Vector3(0.0, 0.05, 0.0))


func _get_mover_push_intent(mover: CharacterBody3D) -> Vector3:
	if mover.has_method("get_push_intent"):
		return mover.get_push_intent()
	return Vector3(mover.velocity.x, 0.0, mover.velocity.z)
