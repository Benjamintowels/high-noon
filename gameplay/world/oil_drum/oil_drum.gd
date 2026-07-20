extends RigidBody3D

const OilDrumExplosionFXScript := preload("res://gameplay/world/oil_drum/oil_drum_explosion_fx.gd")
const GameAudioScript := preload("res://gameplay/audio/game_audio.gd")
const BodyUtils := preload("res://characters/groyper/groyper_body_utils.gd")

const DRUM_TEXTURE := preload("res://Assets/World/OilDrum.png")

const WORLD_COLLISION_LAYER := 1
const PUSHABLE_COLLISION_LAYER := 2

const MAX_HITS := 4
const EXPLODE_CHANCES := [0.5, 0.8, 0.95, 1.0]
const BLAST_RADIUS := 2.44
const BLAST_FORCE := 22.0
const BLAST_DAMAGE := 3

const KNOCKBACK_FORCE := 9.0
const KNOCKBACK_TORQUE := 4.5

const PUSHER_GROUPS: Array[StringName] = [
	&"overworld_player",
	&"player",
	&"town_npc",
]
const PLAYER_CONTACT_RADIUS := 0.36
const DRUM_CONTACT_RADIUS := 0.26
const CONTACT_SLACK := 0.14
const PUSH_SPEED_SCALE := 0.55

@export var drum_pixel_size := 0.011
@export var drum_mass := 28.0

var _hits := 0
var _detonated := false
var _collision_height := 0.72

@onready var _sprite: Sprite3D = $Sprite


func _ready() -> void:
	add_to_group("oil_drum")
	mass = drum_mass
	linear_damp = 1.2
	angular_damp = 1.4
	axis_lock_angular_x = true
	axis_lock_angular_z = true
	collision_layer = PUSHABLE_COLLISION_LAYER
	collision_mask = WORLD_COLLISION_LAYER | PUSHABLE_COLLISION_LAYER
	can_sleep = false
	sleeping = false
	continuous_cd = true
	_apply_visual()
	call_deferred("_snap_to_floor")


func snap_to_floor() -> void:
	_snap_to_floor()


func _snap_to_floor() -> void:
	global_position = BodyUtils.snap_position_to_floor(get_world_3d(), global_position, 0.0)


func _physics_process(delta: float) -> void:
	if _detonated or freeze:
		return
	_apply_character_pushes(delta)


func _apply_character_pushes(delta: float) -> void:
	var tree := get_tree()
	if tree == null:
		return

	for group_name in PUSHER_GROUPS:
		for node in tree.get_nodes_in_group(group_name):
			if node == null or not is_instance_valid(node):
				continue
			if not node is CharacterBody3D:
				continue
			_apply_push_from_mover(node as CharacterBody3D, delta)


func _apply_push_from_mover(mover: CharacterBody3D, delta: float) -> void:
	var offset := global_position - mover.global_position
	offset.y = 0.0
	var dist := offset.length()
	var touch_dist := PLAYER_CONTACT_RADIUS + DRUM_CONTACT_RADIUS + CONTACT_SLACK
	if dist > touch_dist or dist < 0.001:
		return

	var push_dir := offset.normalized()
	var intent := _get_mover_push_intent(mover)
	intent.y = 0.0
	if intent.length_squared() < 0.04:
		return

	var alignment := intent.normalized().dot(push_dir)
	if alignment < 0.2:
		return

	var penetration := clampf((touch_dist - dist) / (CONTACT_SLACK + DRUM_CONTACT_RADIUS), 0.0, 1.0)
	var push_speed := intent.length() * lerpf(PUSH_SPEED_SCALE, 1.0, penetration) * maxf(alignment, 0.35)
	var motion := push_dir * push_speed * delta
	_apply_push_motion(motion, delta)


func _get_mover_push_intent(mover: CharacterBody3D) -> Vector3:
	if mover.has_method("get_push_intent"):
		return mover.call("get_push_intent")
	return Vector3(mover.velocity.x, 0.0, mover.velocity.z)


func _apply_push_motion(motion: Vector3, delta: float) -> void:
	if motion.length_squared() < 0.000001:
		return

	sleeping = false
	var safe_motion := _clip_motion_against_world(motion)
	if safe_motion.length_squared() < 0.000001:
		linear_velocity.x = 0.0
		linear_velocity.z = 0.0
		return

	global_position += safe_motion
	var inv_delta := 1.0 / maxf(delta, 0.001)
	linear_velocity.x = safe_motion.x * inv_delta
	linear_velocity.z = safe_motion.z * inv_delta
	linear_velocity.y = 0.0
	angular_velocity.y = clampf(angular_velocity.y, -1.5, 1.5)


func _clip_motion_against_world(motion: Vector3) -> Vector3:
	var space_state := get_world_3d().direct_space_state
	if space_state == null:
		return motion

	var center_y := _collision_height * 0.5
	var from := global_position + Vector3(0.0, center_y, 0.0)
	var to := from + motion
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = WORLD_COLLISION_LAYER
	query.exclude = [get_rid()]
	var hit := space_state.intersect_ray(query)
	if hit.is_empty():
		return motion

	var travel := from.distance_to(hit.position) - DRUM_CONTACT_RADIUS - 0.04
	if travel <= 0.0:
		return Vector3.ZERO
	return motion.normalized() * minf(motion.length(), travel)


func receive_push(push_normal: Vector3, strength: float) -> void:
	if _detonated or freeze:
		return

	var flat := Vector3(push_normal.x, 0.0, push_normal.z)
	if flat.length_squared() < 0.0001:
		return

	var delta := get_physics_process_delta_time()
	_apply_push_motion(flat.normalized() * clampf(strength, 0.5, 7.0) * PUSH_SPEED_SCALE * delta, delta)


func _apply_visual() -> void:
	if _sprite == null or DRUM_TEXTURE == null:
		return

	_sprite.texture = DRUM_TEXTURE
	_sprite.pixel_size = drum_pixel_size
	_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_sprite.double_sided = true
	_sprite.centered = true
	_sprite.transparent = true

	var world_height := DRUM_TEXTURE.get_height() * drum_pixel_size
	_sprite.position.y = world_height * 0.5

	var shape_node := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node != null:
		var shape := CylinderShape3D.new()
		shape.height = maxf(world_height * 0.88, 0.55)
		shape.radius = maxf(DRUM_TEXTURE.get_width() * drum_pixel_size * 0.42, 0.22)
		shape_node.shape = shape
		shape_node.position.y = shape.height * 0.5
		_collision_height = shape.height


func apply_bullet_hit(hit_info: Dictionary) -> void:
	receive_bullet_hit(hit_info)


func receive_bullet_hit(hit_info: Dictionary) -> void:
	if _detonated:
		return

	var hit_position: Vector3 = hit_info.get("position", global_position)
	var direction: Vector3 = hit_info.get("direction", Vector3.FORWARD)
	var shooter: Node3D = hit_info.get("shooter")

	GameAudioScript.play_oil_drum_hit(self, hit_position)
	_apply_hit_knockback(hit_position, direction)

	_hits += 1
	var chance_index := mini(_hits - 1, EXPLODE_CHANCES.size() - 1)
	if randf() <= EXPLODE_CHANCES[chance_index]:
		_detonate(shooter, hit_position)


func _apply_hit_knockback(hit_position: Vector3, direction: Vector3) -> void:
	if freeze:
		freeze = false

	var push_dir := direction
	if push_dir.length_squared() < 0.0001:
		push_dir = Vector3.FORWARD
	else:
		push_dir = push_dir.normalized()

	var offset := hit_position - global_position
	apply_impulse(push_dir * KNOCKBACK_FORCE, offset)
	apply_torque_impulse(Vector3(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	).normalized() * KNOCKBACK_TORQUE)


func is_detonated() -> bool:
	return _detonated


func clear_attached_arrows() -> void:
	for child in get_children():
		if child.is_in_group("stuck_arrow"):
			child.queue_free()


func _detonate(shooter: Node3D, center: Vector3) -> void:
	if _detonated:
		return
	_detonated = true

	clear_attached_arrows()

	collision_layer = 0
	collision_mask = 0
	freeze = true
	_sprite.visible = false

	var fx_parent := get_tree().current_scene
	if fx_parent == null:
		fx_parent = get_parent()
	OilDrumExplosionFXScript.detonate(
		fx_parent, center, shooter, BLAST_RADIUS, BLAST_FORCE, BLAST_DAMAGE
	)
	queue_free()
