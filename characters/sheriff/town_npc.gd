extends CharacterBody3D
class_name TownNpc

const SHERIFF_RIG_SCENE := preload("res://characters/sheriff/sheriff_rig.tscn")

const WALK_SPEED := 2.2
const GRAVITY := 22.0
const FACING_SPEED := 10.0
const BLEND_SPEED := 8.0
const INTERACT_RANGE := 2.75

enum AiState { IDLE, WALKING, TALKING }

@export var speaker_name := "Sheriff Money Bags"
@export var dialog_lines: PackedStringArray = PackedStringArray([
	"You're not from around here are you?",
	"Welp, don't go causin' any trouble now",
])
@export var idle_duration_min := 5.0
@export var idle_duration_max := 10.0
@export var walk_duration_min := 2.0
@export var walk_duration_max := 5.0

@onready var _model: Node3D = $Model
@onready var _animation_tree: AnimationTree = $AnimationTree
@onready var _interact_area: Area3D = $InteractArea

var _body: Node3D
var _animation_player: AnimationPlayer
var _ai_state := AiState.IDLE
var _state_timer := 0.0
var _walk_direction := Vector3.ZERO
var _locomotion_blend := 0.0
var _player_in_range: Node3D
var _talking := false


func _ready() -> void:
	add_to_group("town_npc")
	_spawn_rig()
	_setup_locomotion()
	_model.rotation.y = MeshyLocomotionUtils.MODEL_YAW_OFFSET
	_interact_area.body_entered.connect(_on_interact_body_entered)
	_interact_area.body_exited.connect(_on_interact_body_exited)
	_begin_idle()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = minf(velocity.y, 0.0)

	if _talking:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		if _player_in_range != null:
			_face_position(_player_in_range.global_position, delta)
		_update_locomotion_blend(delta, 0.0)
		return

	_state_timer -= delta
	match _ai_state:
		AiState.IDLE:
			velocity.x = 0.0
			velocity.z = 0.0
			if _state_timer <= 0.0:
				_begin_walk()
		AiState.WALKING:
			velocity.x = _walk_direction.x * WALK_SPEED
			velocity.z = _walk_direction.z * WALK_SPEED
			_face_position(global_position + _walk_direction, delta)
			if _state_timer <= 0.0:
				_begin_idle()

	move_and_slide()
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	_update_locomotion_blend(delta, horizontal_speed)


func interact(player: Node3D) -> void:
	if _talking or player == null:
		return

	_talking = true
	_ai_state = AiState.TALKING
	velocity = Vector3.ZERO
	_player_in_range = player

	if player.has_method("set_dialog_active"):
		player.set_dialog_active(true)

	DialogManager.show_dialog_sequence(
		dialog_lines,
		func() -> void:
			_end_dialog(player)
	)


func is_talking() -> bool:
	return _talking


func _end_dialog(player: Node3D) -> void:
	_talking = false
	if player != null and player.has_method("set_dialog_active"):
		player.set_dialog_active(false)
	_begin_idle()


func _spawn_rig() -> void:
	var rig: Node3D = SHERIFF_RIG_SCENE.instantiate()
	_model.add_child(rig)
	_body = rig.get_node("Body") as Node3D
	_animation_player = MeshyLocomotionUtils.find_body_animation_player(_body)


func _setup_locomotion() -> void:
	if _animation_player == null:
		push_error("TownNpc: missing AnimationPlayer on sheriff body.")
		return

	if _animation_tree.active:
		_animation_tree.active = false

	if not MeshyLocomotionUtils.setup_locomotion_library(
		_animation_player,
		SheriffAnimConfig.IDLE_SCENE,
		SheriffAnimConfig.WALK_SCENE
	):
		push_error("TownNpc: failed to build locomotion library.")
		return

	if not MeshyLocomotionUtils.setup_idle_walk_animation_tree(_animation_tree, _animation_player):
		push_error("TownNpc: failed to set up AnimationTree.")


func _begin_idle() -> void:
	_ai_state = AiState.IDLE
	_state_timer = randf_range(idle_duration_min, idle_duration_max)
	_walk_direction = Vector3.ZERO


func _begin_walk() -> void:
	_ai_state = AiState.WALKING
	_state_timer = randf_range(walk_duration_min, walk_duration_max)
	var angle := randf_range(0.0, TAU)
	_walk_direction = Vector3(sin(angle), 0.0, cos(angle)).normalized()


func _face_position(target_pos: Vector3, delta: float) -> void:
	var flat_target := Vector3(target_pos.x, global_position.y, target_pos.z)
	var to_target := flat_target - global_position
	if to_target.length_squared() < 0.0001:
		return
	var target_yaw := MeshyLocomotionUtils.facing_yaw_for_direction(to_target.normalized())
	_model.rotation.y = lerp_angle(_model.rotation.y, target_yaw, FACING_SPEED * delta)


func _update_locomotion_blend(delta: float, speed: float) -> void:
	var target := 1.0 if speed > 0.05 else 0.0
	_locomotion_blend = lerpf(_locomotion_blend, target, BLEND_SPEED * delta)
	MeshyLocomotionUtils.set_locomotion_blend(_animation_tree, _locomotion_blend)


func _on_interact_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and body.has_method("register_interactable"):
		_player_in_range = body
		body.register_interactable(self)


func _on_interact_body_exited(body: Node3D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		if body.has_method("unregister_interactable"):
			body.unregister_interactable(self)
