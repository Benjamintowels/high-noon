extends CharacterBody3D
class_name StupidHorse

const HorseModelConfig := preload("res://characters/animals/horse_model_config.gd")
const AnimatorScript := preload("res://characters/animals/stupid_horse_animator.gd")

const GRAVITY := 22.0
const WALK_SPEED := 1.35
const FACING_SPEED := 5.5
const MODEL_YAW_OFFSET := PI * 0.5

enum AiState { IDLE, WANDER, STARE }

enum RoamMode { FREE, CORRAL, STREET }

@export var model_variant := ""
@export var model_scale := 0.0
@export var roam_mode := RoamMode.FREE
@export var roam_center := Vector3.ZERO
@export var roam_half_extents := Vector2(4.0, 4.0)
@export var personality_seed := -1

@onready var _model: Node3D = $Model
@onready var _anim_pivot: Node3D = $Model/AnimPivot

var _visual: Node3D
var _ai_state := AiState.IDLE
var _state_timer := 0.0
var _wander_target := Vector3.ZERO
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group("stupid_horse")
	if personality_seed >= 0:
		_rng.seed = personality_seed
	else:
		_rng.randomize()

	_spawn_visual()
	_begin_idle()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = minf(velocity.y, 0.0)

	_state_timer -= delta
	match _ai_state:
		AiState.IDLE:
			velocity.x = 0.0
			velocity.z = 0.0
			_anim_pivot.call("set_mode", AnimatorScript.Mode.IDLE)
			if _state_timer <= 0.0:
				_pick_next_behavior()
		AiState.WANDER:
			_do_wander(delta)
		AiState.STARE:
			_do_stare(delta)

	move_and_slide()

	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	_anim_pivot.call("update_animation", delta, horizontal_speed)


func _spawn_visual() -> void:
	var scene_path := model_variant
	if scene_path.is_empty():
		scene_path = HorseModelConfig.pick_variant(_rng.randi())

	var packed: PackedScene = load(scene_path)
	if packed == null:
		push_error("StupidHorse: failed to load model %s" % scene_path)
		return

	_visual = packed.instantiate() as Node3D
	_anim_pivot.add_child(_visual)

	var scale_factor := HorseModelConfig.fit_scale(_visual, model_scale)
	_visual.scale *= scale_factor
	var applied_scale := maxf(_visual.scale.x, maxf(_visual.scale.y, _visual.scale.z))
	_visual.position.y = HorseModelConfig.ground_offset(_visual, applied_scale)

	HorseModelConfig.apply_texture(_visual, scene_path)


func _pick_next_behavior() -> void:
	var roll := _rng.randf()
	if roll < 0.45:
		_begin_wander()
	elif roll < 0.65:
		_begin_stare()
	else:
		_begin_idle()


func _begin_idle() -> void:
	_ai_state = AiState.IDLE
	_state_timer = _rng.randf_range(3.0, 7.0)
	_anim_pivot.call("set_mode", AnimatorScript.Mode.IDLE)


func _begin_wander() -> void:
	_ai_state = AiState.WANDER
	_state_timer = _rng.randf_range(3.0, 6.0)
	_wander_target = _pick_roam_point()
	_anim_pivot.call("set_mode", AnimatorScript.Mode.WALK)


func _begin_stare() -> void:
	_ai_state = AiState.STARE
	_state_timer = _rng.randf_range(2.5, 5.0)
	_anim_pivot.call("set_mode", AnimatorScript.Mode.IDLE)


func _do_wander(delta: float) -> void:
	var to_target := _wander_target - global_position
	to_target.y = 0.0
	if to_target.length() < 0.45 or _state_timer <= 0.0:
		_begin_idle()
		return

	var direction := to_target.normalized()
	velocity.x = direction.x * WALK_SPEED
	velocity.z = direction.z * WALK_SPEED
	_face_direction(direction, delta)


func _do_stare(delta: float) -> void:
	velocity = Vector3.ZERO
	var player := _find_player()
	if player != null:
		var to_player := player.global_position - global_position
		to_player.y = 0.0
		if to_player.length_squared() > 0.001:
			_face_direction(to_player.normalized(), delta * 0.65)
	if _state_timer <= 0.0:
		_begin_idle()


func _face_direction(direction: Vector3, delta: float) -> void:
	if direction.length_squared() < 0.0001:
		return
	var target_yaw := atan2(direction.x, direction.z) + MODEL_YAW_OFFSET
	_model.rotation.y = lerp_angle(_model.rotation.y, target_yaw, FACING_SPEED * delta)


func _pick_roam_point() -> Vector3:
	var point := global_position
	match roam_mode:
		RoamMode.CORRAL:
			point = roam_center + Vector3(
				_rng.randf_range(-roam_half_extents.x, roam_half_extents.x),
				0.0,
				_rng.randf_range(-roam_half_extents.y, roam_half_extents.y)
			)
		RoamMode.STREET:
			point = roam_center + Vector3(
				_rng.randf_range(-1.8, 1.8),
				0.0,
				_rng.randf_range(-6.0, 6.0)
			)
		_:
			point += _random_horizontal_dir() * _rng.randf_range(2.0, 6.0)
	return point


func _random_horizontal_dir() -> Vector3:
	var angle := _rng.randf_range(0.0, TAU)
	return Vector3(sin(angle), 0.0, cos(angle))


func _find_player() -> Node3D:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	for child in scene.get_children():
		if child is CharacterBody3D and child.has_method("register_interactable"):
			return child as Node3D
	return null
