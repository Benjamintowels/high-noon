extends RigidBody3D
class_name SitChair
## Physics chair: walkers shove it around, punches and bullets fling it.
## Characters can sit on it (interact) only while it stands upright and still.

const GameAudioScript := preload("res://gameplay/audio/game_audio.gd")
const TownNpcShoveScript := preload("res://gameplay/world/town_npc_shove.gd")

const WORLD_COLLISION_LAYER := 1
const PUSHABLE_COLLISION_LAYER := 2
const PUSHER_GROUPS: Array[StringName] = [
	&"overworld_player",
	&"player",
	&"town_npc",
]

const PUSHER_RADIUS := 0.36
const CHAIR_CONTACT_RADIUS := 0.34
const CONTACT_SLACK := 0.16
const PUSH_ALIGNMENT_MIN := 0.2
const PUSH_FORCE := 62.0
const PUNCH_IMPULSE := 26.0
const PUNCH_HIT_HEIGHT := 0.42
const PUNCH_TORQUE := 3.4
const BULLET_IMPULSE := 8.0
const BULLET_TORQUE := 1.2
const UPRIGHT_DOT_MIN := 0.82
const SETTLED_SPEED_SQ := 0.12
const MOVE_SOUND_SPEED := 0.55
const MOVE_SOUND_COOLDOWN := 0.42

@export var chair_mass := 7.0

var _occupant: Node3D
var _hit_cooldown := 0.0
var _move_sound_cooldown := 0.0

@onready var _sit_marker: Marker3D = $SitMarker
@onready var _interact_area: Area3D = $InteractArea


func _ready() -> void:
	add_to_group(&"sit_chair")
	add_to_group(&"punchable_prop")
	mass = chair_mass
	collision_layer = PUSHABLE_COLLISION_LAYER
	collision_mask = TownNpcShoveScript.PUSHABLE_COLLISION_MASK
	linear_damp = 1.0
	angular_damp = 1.2
	continuous_cd = true
	_interact_area.body_entered.connect(_on_interact_body_entered)
	_interact_area.body_exited.connect(_on_interact_body_exited)
	call_deferred("_strip_static_collision")


func _strip_static_collision() -> void:
	# The extracted chair visual ships its own static PropCollision.
	for child in find_children("PropCollision", "Node3D", true, false):
		child.queue_free()
	for child in find_children("*", "StaticBody3D", true, false):
		var body := child as StaticBody3D
		body.collision_layer = 0
		body.collision_mask = 0


func _physics_process(delta: float) -> void:
	_hit_cooldown = maxf(_hit_cooldown - delta, 0.0)
	_move_sound_cooldown = maxf(_move_sound_cooldown - delta, 0.0)
	if freeze or _occupant != null:
		return
	_try_play_move_sound()
	_apply_character_pushes()


func _try_play_move_sound() -> void:
	if _move_sound_cooldown > 0.0:
		return
	if linear_velocity.length() < MOVE_SOUND_SPEED:
		return
	_move_sound_cooldown = MOVE_SOUND_COOLDOWN
	GameAudioScript.play_table_move(self, global_position)


func _apply_character_pushes() -> void:
	for group_name in PUSHER_GROUPS:
		for node in get_tree().get_nodes_in_group(group_name):
			if node is CharacterBody3D:
				_apply_push_from_mover(node as CharacterBody3D)


func _apply_push_from_mover(mover: CharacterBody3D) -> void:
	var offset := global_position - mover.global_position
	offset.y = 0.0
	var contact_range := PUSHER_RADIUS + CHAIR_CONTACT_RADIUS + CONTACT_SLACK
	if offset.length_squared() > contact_range * contact_range:
		return

	var intent := _get_mover_push_intent(mover)
	intent.y = 0.0
	if intent.length_squared() < 0.04:
		return
	var push_dir := offset.normalized()
	if intent.normalized().dot(push_dir) < PUSH_ALIGNMENT_MIN:
		return

	sleeping = false
	# Push low so the chair slides ahead of the walker instead of toppling.
	apply_force(push_dir * PUSH_FORCE, Vector3(0.0, 0.1, 0.0))


func _get_mover_push_intent(mover: CharacterBody3D) -> Vector3:
	if mover.has_method("get_push_intent"):
		return mover.get_push_intent()
	return Vector3(mover.velocity.x, 0.0, mover.velocity.z)


func is_upright() -> bool:
	return global_transform.basis.y.dot(Vector3.UP) > UPRIGHT_DOT_MIN


func can_be_sat_on() -> bool:
	return (
		_occupant == null
		and _hit_cooldown <= 0.0
		and is_upright()
		and linear_velocity.length_squared() < SETTLED_SPEED_SQ
	)


func get_sit_transform() -> Transform3D:
	return _sit_marker.global_transform


func get_interact_hint() -> String:
	return "Sit"


func interact(player: Node3D) -> void:
	if not can_be_sat_on() or player == null:
		return
	if player.has_method("begin_chair_sit"):
		player.begin_chair_sit(self)


func begin_occupied(occupant: Node3D) -> void:
	_occupant = occupant
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	freeze = true


func end_occupied(occupant: Node3D) -> void:
	if _occupant != occupant:
		return
	_occupant = null
	freeze = false


func get_occupant() -> Node3D:
	return _occupant


func receive_punch(hit_info: Dictionary) -> void:
	if _occupant != null:
		return
	_hit_cooldown = 0.5
	sleeping = false
	var dir: Vector3 = hit_info.get("direction", Vector3.ZERO)
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		dir = -global_transform.basis.z
	dir = dir.normalized()
	dir.y = 0.35
	dir = dir.normalized()
	apply_impulse(dir * PUNCH_IMPULSE, Vector3(0.0, PUNCH_HIT_HEIGHT, 0.0))
	apply_torque_impulse(Vector3(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	) * PUNCH_TORQUE)
	GameAudioScript.play_knife_thud(self, global_position)


func apply_bullet_hit(hit_info: Dictionary) -> void:
	if _occupant != null:
		return
	sleeping = false
	var dir: Vector3 = hit_info.get("direction", Vector3.ZERO)
	if dir.length_squared() < 0.0001:
		return
	dir = dir.normalized()
	var hit_position: Vector3 = hit_info.get("position", global_position)
	apply_impulse(dir * BULLET_IMPULSE, hit_position - global_position)
	apply_torque_impulse(Vector3(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	) * BULLET_TORQUE)
	GameAudioScript.play_knife_thud(self, hit_position)


func _on_interact_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and body.has_method("register_interactable"):
		body.register_interactable(self)


func _on_interact_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D and body.has_method("unregister_interactable"):
		body.unregister_interactable(self)
