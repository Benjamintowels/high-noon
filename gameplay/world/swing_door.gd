extends Node3D
class_name SwingDoor
## Saloon-style batwing door. Purely visual: it has no collision at all, so it
## can never block a walker. Each leaf hangs on a simulated underdamped hinge
## spring — walkers push it open with their movement and it flaps back shut
## behind them, swinging both ways.

const GameAudioScript := preload("res://gameplay/audio/game_audio.gd")

const WALKER_GROUPS: Array[StringName] = [
	&"overworld_player",
	&"player",
	&"town_npc",
]

## door_4.tscn mesh footprint (origin at bottom center).
const MESH_NATIVE_WIDTH := 0.9913
const MESH_NATIVE_HEIGHT := 1.9969
const LEAF_THICKNESS := 0.08
const CENTER_GAP := 0.02

const OPEN_SOUND_ANGLE := 0.35
const FLAP_SOUND_SPEED := 1.6
const OPEN_SOUND_COOLDOWN := 0.7
const FLAP_SOUND_COOLDOWN := 0.3

## Two half-width leaves (classic saloon). Off = one full-width leaf.
@export var double_doors := true
@export var door_width := 1.5
@export var door_height := 1.35
@export var floor_offset_y := 0.55
## Single-leaf mode only: which side the hinge sits on.
@export var hinge_on_left := true
@export var max_open_degrees := 105.0
## Hinge spring pulling each leaf back to closed. Higher = snappier return.
@export_range(1.0, 100.0) var spring_stiffness := 26.0
## Below critical damping on purpose so the door flaps a few times settling.
@export_range(0.0, 20.0) var spring_damping := 3.0
## Torque per m/s of walker speed through the doorway.
@export var push_strength := 9.0
## While a walker stands inside this distance of the door plane, the leaves
## are held open so they never visually clip through the walker.
@export var hold_open_degrees := 80.0
@export var hold_clearance := 0.45
@export var zone_depth := 1.6
@export var play_swing_sounds := true

@onready var _leaf_left: Node3D = $LeafLeft
@onready var _leaf_right: Node3D = $LeafRight
@onready var _door_zone: Area3D = $DoorZone
@onready var _zone_shape: CollisionShape3D = $DoorZone/CollisionShape3D

var _walkers: Array[CharacterBody3D] = []
var _pivots: Array[Node3D] = []
## Converts a world open direction (sign of local +Z) into a leaf angle sign.
var _leaf_signs: Array[float] = []
var _angles: Array[float] = []
var _velocities: Array[float] = []
var _max_open_rad := 0.0
var _hold_rad := 0.0
var _last_hold_dir := 1.0
var _was_open := false
var _open_sound_cooldown := 0.0
var _flap_sound_cooldown := 0.0


func _enter_tree() -> void:
	add_to_group(&"swing_door")


func _ready() -> void:
	_max_open_rad = deg_to_rad(max_open_degrees)
	_hold_rad = deg_to_rad(hold_open_degrees)
	_build_leaves()
	_apply_layout()
	_door_zone.collision_layer = 0
	_door_zone.collision_mask = 1
	_door_zone.monitorable = false
	_door_zone.body_entered.connect(_on_body_entered)
	_door_zone.body_exited.connect(_on_body_exited)
	call_deferred("_strip_blocking_collision")


func _build_leaves() -> void:
	_pivots.clear()
	_leaf_signs.clear()
	if double_doors:
		_pivots = [_leaf_left, _leaf_right]
		_leaf_signs = [-1.0, 1.0]
		_leaf_right.visible = true
	elif hinge_on_left:
		_pivots = [_leaf_left]
		_leaf_signs = [-1.0]
		_leaf_right.visible = false
	else:
		_pivots = [_leaf_right]
		_leaf_signs = [1.0]
		_leaf_left.visible = false
	_angles.clear()
	_velocities.clear()
	for pivot in _pivots:
		_angles.append(0.0)
		_velocities.append(0.0)


func _apply_layout() -> void:
	var half_width := door_width * 0.5
	var leaf_width := (door_width - CENTER_GAP) * 0.5 if double_doors else door_width
	_leaf_left.position = Vector3(-half_width, 0.0, 0.0)
	_leaf_right.position = Vector3(half_width, 0.0, 0.0)
	_layout_leaf_visual(_leaf_left, leaf_width, 1.0)
	_layout_leaf_visual(_leaf_right, leaf_width, -1.0)

	_door_zone.position = Vector3.ZERO
	_zone_shape.position = Vector3(0.0, 1.1, 0.0)
	var box := _zone_shape.shape as BoxShape3D
	if box != null:
		box.size = Vector3(door_width + 0.6, 2.2, zone_depth)


func _layout_leaf_visual(pivot: Node3D, leaf_width: float, extend_sign: float) -> void:
	var visual := pivot.get_node_or_null("DoorVisual") as Node3D
	if visual == null:
		return
	visual.position = Vector3(extend_sign * leaf_width * 0.5, floor_offset_y, 0.0)
	visual.scale = Vector3(
		leaf_width / MESH_NATIVE_WIDTH,
		door_height / MESH_NATIVE_HEIGHT,
		LEAF_THICKNESS)


func _strip_blocking_collision() -> void:
	for child in find_children("*", "StaticBody3D", true, false):
		var body := child as StaticBody3D
		body.collision_layer = 0
		body.collision_mask = 0
	for child in find_children("PropCollision", "Node3D", true, false):
		child.queue_free()
	for child in find_children("BulletCover", "Node3D", true, false):
		child.queue_free()


func _physics_process(delta: float) -> void:
	_prune_walkers()
	_open_sound_cooldown = maxf(_open_sound_cooldown - delta, 0.0)
	_flap_sound_cooldown = maxf(_flap_sound_cooldown - delta, 0.0)

	var push := 0.0
	var holding := false
	var hold_dir := 0.0
	var inv := global_transform.affine_inverse()
	var basis_inv := global_transform.basis.inverse()
	var half_depth := maxf(zone_depth * 0.5, 0.001)
	for body in _walkers:
		var local_pos := inv * body.global_position
		if absf(local_pos.x) > door_width * 0.5 + 0.3:
			continue
		var local_motion := basis_inv * _walker_motion(body)
		var falloff := clampf(1.0 - absf(local_pos.z) / half_depth, 0.0, 1.0)
		push += local_motion.z * falloff
		if absf(local_pos.z) < hold_clearance:
			holding = true
			if absf(local_motion.z) > 0.2:
				hold_dir = signf(local_motion.z)
			elif hold_dir == 0.0:
				hold_dir = _last_hold_dir if absf(local_pos.z) < 0.05 else signf(local_pos.z)
	if holding and hold_dir != 0.0:
		_last_hold_dir = hold_dir

	var flap_leaf := 0
	for i in _pivots.size():
		var leaf_sign := _leaf_signs[i]
		var target := 0.0
		if holding:
			target = leaf_sign * hold_dir * _hold_rad
		var torque := -spring_stiffness * (_angles[i] - target) \
			- spring_damping * _velocities[i] \
			+ leaf_sign * push * push_strength
		_velocities[i] += torque * delta
		var prev_angle := _angles[i]
		_angles[i] += _velocities[i] * delta
		if absf(_angles[i]) >= _max_open_rad:
			_angles[i] = clampf(_angles[i], -_max_open_rad, _max_open_rad)
			_velocities[i] = 0.0
		_pivots[i].rotation.y = _angles[i]
		if i == flap_leaf:
			_update_swing_sounds(prev_angle, _angles[i], _velocities[i])


func _walker_motion(body: CharacterBody3D) -> Vector3:
	var motion := body.velocity
	if body.has_method("get_push_intent"):
		var intent: Variant = body.call("get_push_intent")
		if intent is Vector3 and (intent as Vector3).length_squared() > 0.0001:
			motion = intent
	motion.y = 0.0
	return motion


func _prune_walkers() -> void:
	for i in range(_walkers.size() - 1, -1, -1):
		var body := _walkers[i]
		if body == null or not is_instance_valid(body):
			_walkers.remove_at(i)


func _is_walker(body: Node) -> bool:
	for group_name in WALKER_GROUPS:
		if body.is_in_group(group_name):
			return true
	return false


func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and _is_walker(body):
		var walker := body as CharacterBody3D
		if walker not in _walkers:
			_walkers.append(walker)


func _on_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		_walkers.erase(body as CharacterBody3D)


func _update_swing_sounds(prev_angle: float, angle: float, angular_velocity: float) -> void:
	if not play_swing_sounds:
		return

	var is_open := absf(angle) > OPEN_SOUND_ANGLE
	if is_open and not _was_open and _open_sound_cooldown <= 0.0:
		GameAudioScript.play_door_open(self, global_position)
		_open_sound_cooldown = OPEN_SOUND_COOLDOWN
	_was_open = is_open

	# Each time a leaf whips back through center fast enough, it claps —
	# the classic saloon flap-flap that dies out as the spring settles.
	var crossed_center := signf(prev_angle) != signf(angle) and prev_angle != 0.0
	if crossed_center and absf(angular_velocity) > FLAP_SOUND_SPEED \
			and _flap_sound_cooldown <= 0.0:
		GameAudioScript.play_door_close(self, global_position)
		_flap_sound_cooldown = FLAP_SOUND_COOLDOWN
