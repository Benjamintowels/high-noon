extends CharacterBody3D
class_name StupidHorse

const HorseModelConfig := preload("res://characters/animals/horse_model_config.gd")
const HorseBodyUtils := preload("res://characters/animals/horse_body_utils.gd")
const AnimatorScript := preload("res://characters/animals/stupid_horse_animator.gd")
const HorseSkeletalAnimatorScript := preload("res://characters/animals/horse_skeletal_animator.gd")
const LocomotionAudioScript := preload("res://gameplay/audio/locomotion_audio.gd")
const GameAudio := preload("res://gameplay/audio/game_audio.gd")
const TownNpcShove := preload("res://gameplay/world/town_npc_shove.gd")
const BulletHitDamage := preload("res://gameplay/shooting/bullet_hit_damage.gd")

const GRAVITY := 22.0
const WALK_SPEED := 1.35
const FACING_SPEED := 5.5

const MOUNT_WALK_SPEED := 5.5
const MOUNT_SPRINT_SPEED := 20.0
const MOUNT_ACCEL := 14.0
const MOUNT_DECEL := 5.0
const MOUNT_TURN_RATE_FAST := 7.5
const MOUNT_TURN_RATE_SLOW := 0.65
const COAST_AI_RESUME_SPEED := 1.2
const COAST_DURATION := 5.0
const COAST_FRICTION_MIN := 1.5
const COAST_FRICTION_MAX := 22.0
const NEIGH_HIT_COOLDOWN := 0.55
const DEATH_LAY_FINISH_FALLBACK := 0.45
const HORSE_HITBOX_HALF_HEIGHT := 0.34
const HORSE_HITBOX_RADIUS := 0.42
const HORSE_HITBOX_CENTER_Y := 0.55
const DEATH_LAY_DURATION := 0.28
const DEATH_LAY_PITCH := deg_to_rad(-88.0)
const DEATH_LAY_DROP := 0.22

enum AiState { IDLE, WANDER, STARE, GRAZE, COAST }

enum RoamMode { FREE, CORRAL, STREET }

@export var model_variant := ""
@export var model_scale := 0.0
@export var roam_mode := RoamMode.FREE
@export var roam_center := Vector3.ZERO
@export var roam_half_extents := Vector2(4.0, 4.0)
@export var personality_seed := -1
@export var rider_mount: Node3D
## One-time yaw fix on the imported mesh (radians). Tweak in inspector if head/tail look swapped.
@export var mesh_yaw_offset := 0.0
@export var mount_height := 1.35

@onready var _facing: Node3D = $Facing
@onready var _anim_pivot: Node3D = $Facing/Model/AnimPivot
@onready var _interact_area: Area3D = $InteractArea

var _rider_mount: Node3D

var _visual: Node3D
var _model_scene_path := ""
var _skeletal_animator: Node
var _ai_state := AiState.IDLE
var _state_timer := 0.0
var _wander_target := Vector3.ZERO
var _rng := RandomNumberGenerator.new()
var _rider: CharacterBody3D
var _mounted := false
var _mount_sprinting := false
var _mount_has_input := false
var _locomotion_audio: Node
var _neigh_hit_cooldown := 0.0
var _health := BulletHitDamage.HORSE_MAX_HEALTH
var _horse_defeated := false
var _horse_dying := false
var _death_lay_tween: Tween
var _lasso_captured := false
var _lasso_player: Node3D
var _lasso_rope_length := 8.5


func _ready() -> void:
	add_to_group("stupid_horse")
	add_to_group("lassoable")
	if personality_seed >= 0:
		_rng.seed = personality_seed
	else:
		_rng.randomize()

	_interact_area.body_entered.connect(_on_interact_body_entered)
	_interact_area.body_exited.connect(_on_interact_body_exited)

	TownNpcShove.configure_horse_collision(self)

	_rider_mount = rider_mount if rider_mount != null else get_node_or_null("Facing/RiderMount") as Node3D
	if _rider_mount == null:
		push_error("StupidHorse: assign RiderMount (Facing/RiderMount) in the inspector.")

	_spawn_visual()
	_setup_locomotion_audio()
	_facing.rotation.y = atan2(HorseBodyUtils.DEFAULT_FORWARD.x, HorseBodyUtils.DEFAULT_FORWARD.z)
	_begin_idle()


func _setup_locomotion_audio() -> void:
	_locomotion_audio = LocomotionAudioScript.new()
	_locomotion_audio.name = "LocomotionAudio"
	add_child(_locomotion_audio)
	_locomotion_audio.setup(self, LocomotionAudioScript.Kind.HORSE)


func _physics_process(delta: float) -> void:
	_neigh_hit_cooldown = maxf(_neigh_hit_cooldown - delta, 0.0)

	if _horse_defeated:
		_process_defeated(delta)
		return

	if _horse_dying:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = minf(velocity.y, 0.0)

	if _lasso_captured:
		if _lasso_player != null:
			apply_lasso_drag(_lasso_player, delta)
		move_and_slide()
		return

	if _mounted and _rider != null:
		_process_mounted(delta)
	elif _ai_state == AiState.COAST:
		_process_coast(delta)
	else:
		_process_ai(delta)

	move_and_slide()

	if _mounted and _rider != null:
		_sync_rider_position()

	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	_update_animation(delta, horizontal_speed)
	_update_locomotion_audio(delta, horizontal_speed)


func interact(player: Node3D) -> void:
	if player == null or _horse_defeated:
		return
	if _mounted:
		if player == _rider:
			dismount_rider()
		return
	if _rider != null:
		return
	if not player is CharacterBody3D:
		return
	mount_rider(player as CharacterBody3D)


func get_interact_hint() -> String:
	return "Dismount" if _mounted else "Mount"


func is_mounted() -> bool:
	return _mounted


func mount_rider(rider: CharacterBody3D) -> void:
	if rider == null or _mounted or _horse_defeated:
		return
	if not rider.has_method("mount_on_horse"):
		return

	_rider = rider
	_mounted = true
	_ai_state = AiState.IDLE
	_state_timer = 0.0
	_mount_sprinting = false
	_mount_has_input = false
	if _uses_skeletal_animation() and _skeletal_animator.has_method("set_mounted"):
		_skeletal_animator.set_mounted(true)
	GameAudio.play_horse_neigh(self, global_position)
	rider.mount_on_horse(self)


func dismount_rider() -> void:
	if not _mounted or _rider == null:
		return

	var rider := _rider
	release_rider()

	var side := _get_facing_direction().cross(Vector3.UP)
	if side.length_squared() < 0.0001:
		side = Vector3.RIGHT
	side = side.normalized()
	var exit_pos := global_position + side * 0.9 + Vector3(0.0, 0.15, 0.0)

	if rider.has_method("dismount_from_horse"):
		rider.dismount_from_horse(exit_pos)

	if _horse_defeated:
		return

	var h_speed := Vector2(velocity.x, velocity.z).length()
	if h_speed > COAST_AI_RESUME_SPEED:
		_ai_state = AiState.COAST
		_state_timer = COAST_DURATION
	else:
		_begin_idle()


func release_rider() -> void:
	_rider = null
	_mounted = false
	_mount_sprinting = false
	_mount_has_input = false
	if _uses_skeletal_animation() and _skeletal_animator.has_method("set_mounted"):
		_skeletal_animator.set_mounted(false)


func _update_locomotion_audio(delta: float, horizontal_speed: float) -> void:
	if _locomotion_audio == null:
		return

	var has_move_input := false
	var sprinting := false

	if _mounted:
		has_move_input = _mount_has_input
		sprinting = _mount_sprinting
	elif _ai_state == AiState.WANDER:
		has_move_input = horizontal_speed > 0.05
	elif _ai_state == AiState.COAST:
		sprinting = horizontal_speed > 2.0

	_locomotion_audio.update(
		delta,
		has_move_input,
		sprinting,
		horizontal_speed,
		is_on_floor()
	)


func _process_mounted(delta: float) -> void:
	if _rider == null or not is_instance_valid(_rider):
		_mounted = false
		_rider = null
		_mount_has_input = false
		_begin_idle()
		return

	var wish_dir := Vector3.ZERO
	var sprinting := false
	if _rider.has_method("get_ride_move_input"):
		wish_dir = _rider.get_ride_move_input()
	if _rider.has_method("is_ride_sprinting"):
		sprinting = _rider.is_ride_sprinting()
	_mount_sprinting = sprinting

	var input_strength := clampf(wish_dir.length(), 0.0, 1.0)
	_mount_has_input = input_strength > 0.05
	var h_vel := Vector3(velocity.x, 0.0, velocity.z)
	var h_speed := h_vel.length()

	if input_strength > 0.05:
		var move_dir := wish_dir.normalized()
		var speed_ratio := clampf(h_speed / MOUNT_SPRINT_SPEED, 0.0, 1.0)
		var turn_rate := lerpf(
			MOUNT_TURN_RATE_FAST,
			MOUNT_TURN_RATE_SLOW,
			speed_ratio * speed_ratio
		)
		_turn_facing_toward(move_dir, delta, turn_rate)

		var target_speed := MOUNT_SPRINT_SPEED if sprinting else MOUNT_WALK_SPEED
		var target_h := move_dir * target_speed * input_strength
		h_vel = h_vel.move_toward(target_h, MOUNT_ACCEL * delta)
	else:
		h_vel = h_vel.move_toward(Vector3.ZERO, MOUNT_DECEL * delta)

	velocity.x = h_vel.x
	velocity.z = h_vel.z

	var anim_mode := AnimatorScript.Mode.WALK
	if sprinting and h_vel.length() > MOUNT_WALK_SPEED * 0.55:
		anim_mode = AnimatorScript.Mode.RUN
	elif h_vel.length() > 0.08:
		anim_mode = AnimatorScript.Mode.WALK
	else:
		anim_mode = AnimatorScript.Mode.IDLE
	_set_anim_mode(anim_mode)


func _process_coast(delta: float) -> void:
	_state_timer = maxf(_state_timer - delta, 0.0)

	var h_vel := Vector3(velocity.x, 0.0, velocity.z)
	var h_speed := h_vel.length()
	if h_speed > 0.2:
		_face_direction(h_vel.normalized(), delta * 0.5)

	var coast_progress := 1.0 - clampf(_state_timer / COAST_DURATION, 0.0, 1.0)
	var friction := lerpf(COAST_FRICTION_MIN, COAST_FRICTION_MAX, coast_progress * coast_progress)
	friction += h_speed * 0.4
	h_vel = h_vel.move_toward(Vector3.ZERO, friction * delta)
	velocity.x = h_vel.x
	velocity.z = h_vel.z
	h_speed = h_vel.length()

	_set_anim_mode(AnimatorScript.Mode.RUN if h_speed > 2.0 else AnimatorScript.Mode.IDLE)

	if h_speed <= COAST_AI_RESUME_SPEED or _state_timer <= 0.0:
		_begin_idle()


func _process_ai(delta: float) -> void:
	_state_timer -= delta
	match _ai_state:
		AiState.IDLE:
			velocity.x = 0.0
			velocity.z = 0.0
			_set_anim_mode(AnimatorScript.Mode.IDLE)
			if _state_timer <= 0.0:
				_pick_next_behavior()
		AiState.WANDER:
			_do_wander(delta)
		AiState.STARE:
			_do_stare(delta)
		AiState.GRAZE:
			_do_graze(delta)


func get_facing_node() -> Node3D:
	return _facing


func get_rider_mount_node() -> Node3D:
	return _rider_mount


func get_facing_direction() -> Vector3:
	return Vector3(sin(_facing.rotation.y), 0.0, cos(_facing.rotation.y))


func get_push_intent() -> Vector3:
	return Vector3(velocity.x, 0.0, velocity.z)


func get_shove_shooter() -> Node:
	if _mounted and _rider != null and is_instance_valid(_rider):
		return _rider
	return self


func get_mounted_rider() -> CharacterBody3D:
	return _rider if _mounted else null


func is_horse_defeated() -> bool:
	return _horse_defeated or _horse_dying


func get_bullet_capsule() -> Dictionary:
	var center_y := HORSE_HITBOX_CENTER_Y
	var half_height := HORSE_HITBOX_HALF_HEIGHT
	var radius := HORSE_HITBOX_RADIUS
	if _mounted and _rider != null:
		center_y = 0.42
		half_height = 0.26
		radius = 0.36
	return {
		"center": global_position + Vector3(0.0, center_y, 0.0),
		"half_height": half_height,
		"radius": radius,
		"axis": Vector3.UP,
	}


func apply_bullet_hit(hit_info: Dictionary) -> void:
	if _horse_defeated or _horse_dying:
		return

	var result := BulletHitDamage.process_hit(
		self,
		hit_info,
		_health,
		BulletHitDamage.HORSE_MAX_HEALTH
	)
	_health = result.health

	var hit_position: Vector3 = hit_info.get("position", global_position)

	if result.killed:
		GameAudio.play_horse_neigh(self, hit_position)
		if _rider != null and is_instance_valid(_rider) and _rider.has_method("notify_mounted_horse_shot"):
			_rider.notify_mounted_horse_shot(hit_info)
		_kill_and_fling_rider(hit_info)
		return

	if _rider != null and is_instance_valid(_rider) and _rider.has_method("notify_mounted_horse_shot"):
		_rider.notify_mounted_horse_shot(hit_info)

	if _neigh_hit_cooldown > 0.0:
		return
	_neigh_hit_cooldown = NEIGH_HIT_COOLDOWN
	GameAudio.play_horse_neigh(self, hit_position)


func get_death_dismount_position_for_rider(hit_info: Dictionary) -> Vector3:
	return _get_horse_death_dismount_position(hit_info)


func _kill_and_fling_rider(hit_info: Dictionary) -> void:
	if _horse_defeated or _horse_dying:
		return

	_horse_dying = true
	velocity = Vector3.ZERO
	_mount_sprinting = false
	_mount_has_input = false

	var rider_source := "horse._rider"
	var rider: Node = _rider if _mounted else null
	if rider == null or not is_instance_valid(rider):
		rider_source = "find_mounted_rider_for_horse"
		rider = BulletHitDamage.find_mounted_rider_for_horse(self, get_tree())
	elif not rider.has_method("dismount_from_dead_horse"):
		var fallback := BulletHitDamage.find_mounted_rider_for_horse(self, get_tree())
		if fallback != null and fallback != rider:
			rider_source = "find_mounted_rider_for_horse(fallback)"
			rider = fallback

	# Stop horse<->rider sync before the rider reparents off the mount.
	release_rider()

	var exit_pos := _get_horse_death_dismount_position(hit_info)
	var on_death_lay_done := Callable(self, "_finalize_horse_death_after_rider")
	_begin_death_lay(on_death_lay_done)
	get_tree().create_timer(DEATH_LAY_FINISH_FALLBACK).timeout.connect(
		_finalize_horse_death_after_rider,
		CONNECT_ONE_SHOT
	)

	if rider != null and is_instance_valid(rider):
		if rider.has_method("dismount_from_dead_horse"):
			rider.dismount_from_dead_horse(exit_pos, hit_info)
		elif rider.has_method("dismount_from_horse"):
			rider.dismount_from_horse(exit_pos, false, true)
func _finalize_horse_death_after_rider() -> void:
	if _horse_defeated:
		return
	_horse_defeated = true
	_horse_dying = false
	_interact_area.monitorable = false
	_interact_area.monitoring = false
func _get_horse_death_dismount_position(hit_info: Dictionary) -> Vector3:
	var mount_pos := global_position + Vector3(0.0, mount_height, 0.0)
	if _rider_mount != null:
		mount_pos = _rider_mount.global_position

	var shot_dir: Vector3 = hit_info.get("direction", -get_facing_direction())
	shot_dir.y = 0.0
	if shot_dir.length_squared() < 0.0001:
		shot_dir = -get_facing_direction()
	shot_dir = shot_dir.normalized() if shot_dir.length_squared() > 0.0001 else Vector3.FORWARD

	var side := shot_dir.cross(Vector3.UP)
	if side.length_squared() < 0.0001:
		side = get_facing_direction().cross(Vector3.UP)
	if side.length_squared() < 0.0001:
		side = Vector3.RIGHT
	side = side.normalized()
	return Vector3(
		mount_pos.x + side.x * 0.75,
		global_position.y,
		mount_pos.z + side.z * 0.75
	)


func _process_defeated(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity = Vector3.ZERO
	move_and_slide()


func _begin_death_lay(on_finished: Callable = Callable()) -> void:
	if _anim_pivot == null:
		if on_finished.is_valid():
			on_finished.call()
		return

	if _anim_pivot.has_method("freeze_for_death"):
		_anim_pivot.call("freeze_for_death")
	if _skeletal_animator != null and _skeletal_animator.has_method("freeze_for_death"):
		_skeletal_animator.call("freeze_for_death")

	if _death_lay_tween != null and _death_lay_tween.is_valid():
		_death_lay_tween.kill()

	var model_root := _anim_pivot.get_parent() as Node3D
	var start_pitch := _anim_pivot.rotation.x
	var start_model_y := model_root.position.y if model_root != null else 0.0

	_death_lay_tween = create_tween()
	_death_lay_tween.set_parallel(true)
	_death_lay_tween.tween_property(
		_anim_pivot,
		"rotation:x",
		DEATH_LAY_PITCH,
		DEATH_LAY_DURATION
	).from(start_pitch).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	_death_lay_tween.tween_property(
		_anim_pivot,
		"rotation:z",
		0.0,
		DEATH_LAY_DURATION
	).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	if model_root != null:
		_death_lay_tween.tween_property(
			model_root,
			"position:y",
			start_model_y - DEATH_LAY_DROP,
			DEATH_LAY_DURATION
		).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	if on_finished.is_valid():
		_death_lay_tween.chain().tween_callback(on_finished)


func _turn_facing_toward(direction: Vector3, delta: float, turn_rate: float) -> void:
	if direction.length_squared() < 0.0001:
		return
	var target_yaw := atan2(direction.x, direction.z)
	_facing.rotation.y = lerp_angle(_facing.rotation.y, target_yaw, turn_rate * delta)


func _sync_rider_position() -> void:
	if _rider == null or _rider_mount == null:
		return
	if _rider.has_method("follow_mounted_horse"):
		_rider.follow_mounted_horse(_rider_mount)
	else:
		_rider.global_position = _rider_mount.global_position
		_rider.velocity = Vector3.ZERO


func _get_facing_direction() -> Vector3:
	return get_facing_direction()


func _spawn_visual() -> void:
	var scene_path := model_variant
	if scene_path.is_empty():
		scene_path = HorseModelConfig.pick_variant(_rng.randi())
	_model_scene_path = scene_path

	var packed: PackedScene = load(scene_path)
	if packed == null:
		push_error("StupidHorse: failed to load model %s" % scene_path)
		return

	_visual = packed.instantiate() as Node3D
	_anim_pivot.add_child(_visual)
	_visual.rotation.y = mesh_yaw_offset

	var model_root := _anim_pivot.get_parent() as Node3D
	var requested_scale := model_scale
	if requested_scale <= 0.0:
		requested_scale = HorseModelConfig.default_model_scale(scene_path)
	var scale_factor := HorseModelConfig.fit_scale(_visual, requested_scale)
	_visual.scale *= scale_factor
	var visual_scale := _visual.scale
	var reference_mount := HorseModelConfig.reference_mount_position(mount_height)
	if HorseModelConfig.is_rigged_variant(scene_path):
		_visual.position = HorseModelConfig.align_rigged_visual_to_ground(_visual, visual_scale)
	else:
		_visual.position = HorseModelConfig.align_visual_to_reference_mount(
			_visual,
			visual_scale,
			model_root.scale,
			reference_mount
		)

	if _rider_mount != null:
		var mount_rot := _rider_mount.rotation
		_rider_mount.position = reference_mount
		_rider_mount.rotation = mount_rot

	HorseModelConfig.apply_texture(_visual, scene_path)
	_setup_skeletal_animation()


func _setup_skeletal_animation() -> void:
	_skeletal_animator = null
	if _visual == null or not HorseModelConfig.is_rigged_variant(_model_scene_path):
		return
	_skeletal_animator = HorseSkeletalAnimatorScript.attach(_visual)
	if _skeletal_animator != null and _skeletal_animator.has_method("uses_skeletal"):
		if _skeletal_animator.uses_skeletal() and _anim_pivot.has_method("freeze_for_death"):
			_anim_pivot.call("freeze_for_death")


func _uses_skeletal_animation() -> bool:
	return (
		_skeletal_animator != null
		and _skeletal_animator.has_method("uses_skeletal")
		and _skeletal_animator.uses_skeletal()
	)


func _set_anim_mode(mode: int) -> void:
	if _uses_skeletal_animation():
		_skeletal_animator.set_mode(mode)
	else:
		_anim_pivot.call("set_mode", mode)


func _update_animation(
	delta: float,
	horizontal_speed: float,
	sprinting_override: Variant = null
) -> void:
	var sprinting := _mount_sprinting and _mounted
	if sprinting_override != null:
		sprinting = bool(sprinting_override)
	if _uses_skeletal_animation():
		_skeletal_animator.update_animation(delta, horizontal_speed, sprinting, _mounted)
	else:
		_anim_pivot.call("update_animation", delta, horizontal_speed, sprinting)


func play_head_bow(on_finished: Callable = Callable()) -> bool:
	if _uses_skeletal_animation() and _skeletal_animator.has_method("play_bow"):
		return _skeletal_animator.play_bow(on_finished)
	if on_finished.is_valid():
		on_finished.call()
	return false


func can_play_head_bow() -> bool:
	return (
		not _mounted
		and _uses_skeletal_animation()
		and _skeletal_animator.has_method("can_bow")
		and _skeletal_animator.can_bow()
	)


func _pick_next_behavior() -> void:
	var roll := _rng.randf()
	if _uses_skeletal_animation() and roll < 0.22:
		_begin_graze()
	elif roll < 0.45:
		_begin_wander()
	elif roll < 0.65:
		_begin_stare()
	else:
		_begin_idle()


func _begin_idle() -> void:
	_ai_state = AiState.IDLE
	_state_timer = _rng.randf_range(3.0, 7.0)
	velocity.x = 0.0
	velocity.z = 0.0
	_set_anim_mode(AnimatorScript.Mode.IDLE)


func _begin_wander() -> void:
	_ai_state = AiState.WANDER
	_state_timer = _rng.randf_range(3.0, 6.0)
	_wander_target = _pick_roam_point()
	_set_anim_mode(AnimatorScript.Mode.WALK)


func _begin_stare() -> void:
	_ai_state = AiState.STARE
	_state_timer = _rng.randf_range(2.5, 5.0)
	_set_anim_mode(AnimatorScript.Mode.IDLE)


func _begin_graze() -> void:
	if not can_play_head_bow():
		_begin_idle()
		return
	_ai_state = AiState.GRAZE
	_state_timer = _rng.randf_range(6.0, 9.0)
	velocity.x = 0.0
	velocity.z = 0.0
	_set_anim_mode(AnimatorScript.Mode.IDLE)
	play_head_bow(func() -> void:
		if _ai_state == AiState.GRAZE:
			_begin_idle()
	)


func _do_graze(_delta: float) -> void:
	velocity = Vector3.ZERO
	if _state_timer <= 0.0:
		_begin_idle()


func _do_wander(delta: float) -> void:
	var to_target := _wander_target - global_position
	to_target.y = 0.0
	if to_target.length() < 0.45 or _state_timer <= 0.0:
		_begin_idle()
		return

	var direction := to_target.normalized()
	_face_direction(direction, delta)

	var move_dir := _get_facing_direction()
	var alignment := clampf(move_dir.dot(direction), 0.0, 1.0)
	var speed := WALK_SPEED * lerpf(0.3, 1.0, alignment)
	velocity.x = move_dir.x * speed
	velocity.z = move_dir.z * speed


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
	_turn_facing_toward(direction, delta, FACING_SPEED)


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


func _on_interact_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and body.has_method("register_interactable"):
		body.register_interactable(self)


func _on_interact_body_exited(body: Node3D) -> void:
	if body == _rider:
		return
	if body.has_method("unregister_interactable"):
		body.unregister_interactable(self)


func is_lassoable() -> bool:
	return not _mounted and _rider == null and not _lasso_captured and not _horse_defeated


func get_lasso_attach_point() -> Vector3:
	return global_position + Vector3(0.0, 1.15, 0.0)


func get_lasso_rope_length() -> float:
	return _lasso_rope_length


func get_lasso_max_match_speed() -> float:
	return MOUNT_SPRINT_SPEED


func get_lasso_drag_visual() -> Node3D:
	return _visual


func begin_lasso_capture(player: Node3D, rope_length: float, _ring: LassoRing = null) -> void:
	_lasso_captured = true
	_lasso_player = player
	_lasso_rope_length = rope_length
	velocity = Vector3.ZERO
	_ai_state = AiState.IDLE


func end_lasso_capture() -> void:
	_lasso_captured = false
	_lasso_player = null
	velocity = Vector3.ZERO
	_begin_idle()


func apply_lasso_drag(player: Node3D, delta: float) -> void:
	if not _lasso_captured or player == null:
		return
	const LassoTargetUtils := preload("res://gameplay/lasso/lasso_target_utils.gd")
	var info: Dictionary = LassoTargetUtils.apply_taut_drag(
		self,
		self,
		player,
		_lasso_rope_length,
		delta
	)
	var h_speed := float(info.get("speed", 0.0))
	var sprinting := bool(info.get("sprinting", false))
	_update_animation(delta, h_speed, sprinting)
