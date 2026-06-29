extends Node3D

signal defeated(hit_info: Dictionary)
signal shot_fired

const WEAPON_RIG_SCRIPT := preload("res://characters/groyper/groyper_weapon_rig.gd")
const RAGDOLL_SCRIPT := preload("res://characters/groyper/groyper_ragdoll.gd")
const DUEL_HAT_SCRIPT := preload("res://characters/groyper/groyper_duel_hat.gd")
const ENEMY_HAT_MATERIAL := preload("res://characters/groyper/cowboy_hat_material_white.tres")
const DuelHitTest := preload("res://gameplay/duel/duel_hit_test.gd")
const DuelPacesScript := preload("res://gameplay/duel/duel_paces.gd")
const GameAudio := preload("res://gameplay/audio/game_audio.gd")
const BloodSplatterFXScript := preload("res://gameplay/fx/blood_splatter_fx.gd")

enum AiState { IDLE, WAITING_TO_DRAW, DRAWING, AIMING, FIRED }

@export var draw_duration := 0.48
@export var chest_aim_height := 1.25
@export var min_draw_delay := 0.0
@export var max_draw_delay := 0.2
@export var min_fire_delay := 0.3
@export var max_fire_delay := 2.0
@export_range(0.0, 1.0, 0.01) var centered_aim_spread := 0.05
@export var off_body_aim_spread := 1.25
@export_range(0.08, 0.65, 0.01) var far_pace_wobble_amplitude := 0.38
@export_range(0.04, 0.25, 0.01) var close_pace_wobble_amplitude := 0.11
@export_range(0.4, 3.0, 0.05) var far_pace_wobble_frequency := 0.95
@export_range(1.0, 6.0, 0.1) var close_pace_wobble_frequency := 2.4
@export_range(1.0, 10.0, 0.25) var far_pace_track_speed := 2.2
@export_range(3.0, 16.0, 0.25) var close_pace_track_speed := 5.5
@export_range(0.5, 6.0, 0.1) var wobble_follow_smooth := 2.0

var _body: Node3D
var _skeleton: Skeleton3D
var _animation_player: AnimationPlayer
var _animation_tree: AnimationTree
var _weapon_rig
var _ragdoll
var _duel_hat
var _hitbox: StaticBody3D
var _aim_target: Node3D
var _ai_state := AiState.IDLE
var _defeated := false
var _draw_wait_timer := 0.0
var _fire_timer := 0.0
var _committed_aim_zone := ""
var _aim_spread_offset := Vector3.ZERO
var _locked_world_aim_point := Vector3.ZERO
var _has_locked_aim := false
var _aim_miss_chance := 0.30
var _smoothed_aim_point := Vector3.ZERO
var _pace_separation := 30.0
var _wobble_phase := 0.0
var _fire_timer_duration := 0.0
var _wobble_offset := Vector3.ZERO
var _replay_mode := false
var _target_mode := false
var _target_objects: Array = []
var _target_ammo := 6
var _target_active := false
var _target_fire_cooldown := 0.0
const TARGET_FIRE_DELAY_MIN := 1.0
const TARGET_FIRE_DELAY_MAX := 2.5
const TARGET_MISS_CHANCE := 0.10
var _ragdoll_animations_suspended := false
var _saved_animation_player_active := true
var _saved_animation_player_process_mode: Node.ProcessMode = Node.PROCESS_MODE_INHERIT
var _saved_animation_tree_active := true
var _saved_animation_tree_process_mode: Node.ProcessMode = Node.PROCESS_MODE_INHERIT
var _replay_saved_tree_process_mode: Node.ProcessMode = Node.PROCESS_MODE_INHERIT


func _ready() -> void:
	GroyperBodyUtils.apply_model_baseline($Model)
	add_to_group("duel_target")
	add_to_group("duel_enemy")
	_body = $Model/GroyperRig/Body
	_animation_tree = $AnimationTree
	_skeleton = GroyperBodyUtils.find_skeleton(_body)
	_animation_player = GroyperBodyUtils.find_animation_player(_body)
	if _skeleton == null or _animation_player == null:
		push_error("GroyperDuelist: missing skeleton or animation player.")
		return

	_setup_idle_animation()

	_weapon_rig = WEAPON_RIG_SCRIPT.new()
	_weapon_rig.name = "WeaponRig"
	_weapon_rig.draw_duration = draw_duration
	add_child(_weapon_rig)
	_weapon_rig.setup(self, _skeleton)

	_ragdoll = RAGDOLL_SCRIPT.new()
	_ragdoll.name = "Ragdoll"
	add_child(_ragdoll)
	_ragdoll.skeleton_path = _ragdoll.get_path_to(_skeleton)
	_ragdoll.bind_skeleton()

	_duel_hat = DUEL_HAT_SCRIPT.new()
	_duel_hat.name = "DuelHat"
	add_child(_duel_hat)
	_duel_hat.bind_skeleton(_skeleton, ENEMY_HAT_MATERIAL)
	_duel_hat.prepare_for_round(false)

	_hitbox = $Hitbox as StaticBody3D
	_hitbox.owner_path = NodePath("..")
	_sync_hitbox_position()
	_ensure_idle_animating()


func set_aim_target(target: Node3D) -> void:
	_aim_target = target


func set_fire_delay_bounds(min_delay: float, max_delay: float) -> void:
	min_fire_delay = maxf(min_delay, 0.05)
	max_fire_delay = maxf(max_delay, min_fire_delay + 0.05)


func set_draw_delay_bounds(min_delay: float, max_delay: float) -> void:
	min_draw_delay = maxf(min_delay, 0.0)
	max_draw_delay = maxf(max_delay, min_draw_delay)


func set_aim_miss_chance(chance: float) -> void:
	_aim_miss_chance = clampf(chance, 0.0, 1.0)


func set_pace_separation(separation: float) -> void:
	_pace_separation = maxf(separation, DuelPacesScript.MIN_SEPARATION)


func set_duel_prep(_active: bool) -> void:
	pass


func get_duel_hat() -> GroyperDuelHat:
	return _duel_hat


func apply_match_hat_state(match_hat_lost: bool) -> void:
	if _duel_hat != null:
		_duel_hat.prepare_for_round(match_hat_lost)


func get_display_aim_point() -> Vector3:
	return _smoothed_aim_point


func get_aim_reticle_urgency() -> float:
	match _ai_state:
		AiState.WAITING_TO_DRAW:
			return 0.0
		AiState.DRAWING:
			if _weapon_rig != null and _weapon_rig.has_method("get_draw_progress"):
				return _weapon_rig.get_draw_progress() * 0.18
			return 0.0
		AiState.AIMING:
			if _fire_timer_duration <= 0.0:
				return 1.0
			return 1.0 - clampf(_fire_timer / _fire_timer_duration, 0.0, 1.0)
		_:
			return 0.0


func is_aim_reticle_visible() -> bool:
	return not _defeated and _has_locked_aim and (
		_ai_state == AiState.WAITING_TO_DRAW
		or _ai_state == AiState.DRAWING
		or _ai_state == AiState.AIMING
	)


func contains_bullet_hit(world_point: Vector3, margin: float) -> bool:
	if _defeated:
		return false
	var capsule := get_bullet_capsule()
	return DuelHitTest.point_in_capsule(
		world_point,
		capsule["center"],
		capsule["half_height"],
		capsule["radius"],
		capsule.get("axis", Vector3.UP),
		margin
	)


func get_bullet_capsule() -> Dictionary:
	_sync_hitbox_position()
	var torso := _get_torso_transform()
	var half_height := 0.48
	var radius := 0.28
	if _hitbox != null:
		var shape_node := _hitbox.get_node_or_null("CollisionShape3D") as CollisionShape3D
		var capsule := shape_node.shape as CapsuleShape3D if shape_node != null else null
		if capsule != null:
			half_height = capsule.height * 0.5
			radius = capsule.radius
	return {
		"center": torso.origin,
		"half_height": half_height,
		"radius": radius,
		"axis": torso.basis.y,
	}


func suspend_animations_for_ragdoll() -> void:
	if _ragdoll_animations_suspended:
		return
	_ragdoll_animations_suspended = true

	if _animation_tree != null:
		_saved_animation_tree_active = _animation_tree.active
		_saved_animation_tree_process_mode = _animation_tree.process_mode
		_animation_tree.set(
			"parameters/%s/blend_position" % GroyperBodyUtils.LEAN_BLEND_NODE,
			Vector2.ZERO
		)
		_animation_tree.set(
			"parameters/%s/blend_amount" % GroyperBodyUtils.MIX_NODE,
			0.0
		)
		_animation_tree.active = false
		_animation_tree.process_mode = Node.PROCESS_MODE_DISABLED

	if _animation_player == null:
		return
	_saved_animation_player_active = _animation_player.active
	_saved_animation_player_process_mode = _animation_player.process_mode
	_animation_player.active = false
	if _animation_player.is_playing():
		_animation_player.pause()
	_animation_player.speed_scale = 0.0
	_animation_player.process_mode = Node.PROCESS_MODE_DISABLED


func resume_animations_after_ragdoll() -> void:
	if not _ragdoll_animations_suspended:
		return
	_ragdoll_animations_suspended = false

	if _animation_player != null:
		_animation_player.process_mode = _saved_animation_player_process_mode
		_animation_player.speed_scale = 1.0
		_animation_player.active = _saved_animation_player_active

	if _animation_tree != null:
		_animation_tree.process_mode = _saved_animation_tree_process_mode
		_animation_tree.active = _saved_animation_tree_active


func prepare_for_round() -> void:
	if _ragdoll != null and _ragdoll.is_active():
		_ragdoll.deactivate()
	resume_animations_after_ragdoll()
	if _hitbox != null:
		_hitbox.collision_layer = 1
	_defeated = false
	_ai_state = AiState.IDLE
	_committed_aim_zone = ""
	_aim_spread_offset = Vector3.ZERO
	_locked_world_aim_point = Vector3.ZERO
	_has_locked_aim = false
	_draw_wait_timer = 0.0
	_fire_timer = 0.0
	_fire_timer_duration = 0.0
	_wobble_phase = 0.0
	_wobble_offset = Vector3.ZERO
	_smoothed_aim_point = _get_player_chest_point()
	_weapon_rig.reset_to_holster()
	_weapon_rig.set_prep_aim(false)
	_sync_hitbox_position()
	_ensure_idle_animating()
	set_process(true)


func is_defeated() -> bool:
	return _defeated


func begin_duel_sequence() -> void:
	if _defeated:
		return

	_committed_aim_zone = _pick_body_aim_zone()
	var body_point := _sample_body_aim_point(_committed_aim_zone)
	_aim_spread_offset = _resolve_aim_point(body_point) - body_point
	_has_locked_aim = true
	_smoothed_aim_point = body_point + _aim_spread_offset
	_wobble_phase = randf() * TAU
	_wobble_offset = Vector3.ZERO
	_draw_wait_timer = randf_range(min_draw_delay, max_draw_delay)
	_fire_timer = 0.0
	_fire_timer_duration = 0.0
	_ai_state = AiState.WAITING_TO_DRAW


func apply_bullet_hit(hit_info: Dictionary) -> void:
	receive_bullet_hit(hit_info)


func receive_bullet_hit(hit_info: Dictionary) -> void:
	if _defeated:
		return

	BloodSplatterFXScript.spawn_for_hit(self, hit_info)
	_activate_defeat_ragdoll(hit_info)
	defeated.emit(hit_info)


func _process(delta: float) -> void:
	if _replay_mode:
		return
	if _defeated or _weapon_rig == null:
		return

	_sync_hitbox_position()
	if _has_locked_aim:
		_update_aim_tracking(delta)
	_weapon_rig.update(delta, _smoothed_aim_point)
	_update_ai(delta)


func _update_ai(delta: float) -> void:
	if _target_mode and _target_active:
		_update_target_ai(delta)
		return

	match _ai_state:
		AiState.WAITING_TO_DRAW:
			_draw_wait_timer = maxf(_draw_wait_timer - delta, 0.0)
			if _draw_wait_timer <= 0.0:
				_start_draw()
		AiState.DRAWING:
			if _weapon_rig.is_aiming():
				_begin_aiming_phase()
		AiState.AIMING:
			_fire_timer = maxf(_fire_timer - delta, 0.0)
			if _fire_timer <= 0.0:
				_fire_at_target()


func _start_draw() -> void:
	_ai_state = AiState.DRAWING
	_weapon_rig.set_prep_aim(false)
	_weapon_rig.begin_draw()


func _begin_aiming_phase() -> void:
	_ai_state = AiState.AIMING
	_fire_timer_duration = randf_range(min_fire_delay, max_fire_delay)
	_fire_timer = _fire_timer_duration


func _fire_at_target() -> void:
	if _ai_state == AiState.FIRED or _weapon_rig == null:
		return
	if not _weapon_rig.is_aiming():
		return

	_weapon_rig.fire_at(_smoothed_aim_point)
	_ai_state = AiState.FIRED
	shot_fired.emit()


func _pick_body_aim_zone() -> String:
	if _aim_target != null and _aim_target.has_method("get_duel_body_aim_point"):
		return _pick_weighted_aim_zone()
	return "chest"


func _pick_weighted_aim_zone() -> String:
	var roll := randf()
	if roll < 0.58:
		return "chest"
	if roll < 0.82:
		return "head"
	if roll < 0.93:
		return "gut"
	if roll < 0.97:
		return "left_shoulder"
	return "right_shoulder"


func _sample_body_aim_point(zone_id: String) -> Vector3:
	if _aim_target != null and _aim_target.has_method("get_duel_body_aim_point"):
		return _aim_target.get_duel_body_aim_point(zone_id)
	return _get_player_chest_point()


func _resolve_aim_point(body_point: Vector3) -> Vector3:
	var spread := off_body_aim_spread if randf() < _aim_miss_chance else centered_aim_spread
	return body_point + Vector3(
		randf_range(-spread, spread),
		randf_range(-spread * 0.45, spread * 0.45),
		randf_range(-spread, spread)
	)


func _get_pace_tightness() -> float:
	return DuelPacesScript.pace_progress_from_separation(_pace_separation)


func _update_aim_tracking(delta: float) -> void:
	var pace_t := _get_pace_tightness()
	var wobble_freq := lerpf(far_pace_wobble_frequency, close_pace_wobble_frequency, pace_t)
	_wobble_phase += delta * wobble_freq * TAU

	var wobble_amplitude := lerpf(far_pace_wobble_amplitude, close_pace_wobble_amplitude, pace_t)
	var target_wobble := Vector3(
		sin(_wobble_phase) * wobble_amplitude,
		sin(_wobble_phase * 1.37 + 0.8) * wobble_amplitude * 0.22,
		cos(_wobble_phase * 0.91 + 0.35) * wobble_amplitude * 0.55
	)
	var wobble_step := 1.0 - exp(-wobble_follow_smooth * delta)
	_wobble_offset = _wobble_offset.lerp(target_wobble, wobble_step)

	var zone_point := _sample_body_aim_point(_committed_aim_zone)
	var target := zone_point + _aim_spread_offset + _wobble_offset
	var track_speed := lerpf(far_pace_track_speed, close_pace_track_speed, pace_t)
	var track_step := 1.0 - exp(-track_speed * delta)
	_smoothed_aim_point = _smoothed_aim_point.lerp(target, track_step)


func _sync_hitbox_position() -> void:
	if _hitbox == null:
		return
	_hitbox.global_transform = _get_torso_transform()


func _get_torso_transform() -> Transform3D:
	if _skeleton == null:
		var no_skeleton := global_transform
		no_skeleton.origin = global_position + Vector3(0.0, chest_aim_height, 0.0)
		return no_skeleton

	for bone_name in ["Spine02", "Spine01", "Spine"]:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id < 0:
			continue
		var bone_global := _skeleton.global_transform * _skeleton.get_bone_global_pose(bone_id)
		return Transform3D(
			bone_global.basis,
			bone_global.origin + bone_global.basis * Vector3(0.0, 0.04, 0.02)
		)

	var fallback := global_transform
	fallback.origin = global_position + Vector3(0.0, chest_aim_height, 0.0)
	return fallback


func _get_torso_point() -> Vector3:
	return _get_torso_transform().origin


func _get_player_chest_point() -> Vector3:
	if _aim_target != null and _aim_target.has_method("get_duel_aim_point"):
		return _aim_target.get_duel_aim_point()
	if _aim_target != null:
		return _aim_target.global_position + Vector3(0.0, chest_aim_height, 0.0)
	return global_position + Vector3(0.0, chest_aim_height, -8.0)


func _setup_idle_animation() -> void:
	if not GroyperBodyUtils.setup_idle_animation_tree(_animation_tree, _animation_player):
		push_error("GroyperDuelist: failed to set up idle AnimationTree.")


func _ensure_idle_animating() -> void:
	if _animation_tree != null and not _animation_tree.active:
		_animation_tree.active = true
	if _animation_player != null and _animation_player.speed_scale <= 0.0:
		_animation_player.speed_scale = 1.0
		_animation_player.active = true


func apply_replay_ragdoll(hit_info: Dictionary) -> void:
	_activate_defeat_ragdoll(hit_info)


func _activate_defeat_ragdoll(hit_info: Dictionary) -> void:
	print("[GroyperDuelist] _activate_defeat_ragdoll ragdoll=%s active=%s" % [
		_ragdoll,
		_ragdoll.is_active() if _ragdoll != null else false,
	])
	var hit_position: Vector3 = hit_info.get("position", global_position)
	GameAudio.play_death_sound(self, hit_position)
	_defeated = true
	_ai_state = AiState.FIRED
	set_process(false)
	if _hitbox != null:
		_hitbox.collision_layer = 0
	if _ragdoll != null and not _ragdoll.is_active():
		_ragdoll.activate(hit_info, _animation_player)


func get_replay_shot_points() -> Dictionary:
	if _weapon_rig == null:
		return {}
	var from: Vector3 = _weapon_rig.get_muzzle_global_position()
	return {"from": from, "to": _smoothed_aim_point}


func set_replay_mode(active: bool) -> void:
	_replay_mode = active
	if active:
		if _animation_tree != null:
			_replay_saved_tree_process_mode = _animation_tree.process_mode
			_animation_tree.active = true
			_animation_tree.process_mode = Node.PROCESS_MODE_DISABLED
		if _animation_player != null:
			_animation_player.pause()
	elif not _defeated and (_ragdoll == null or not _ragdoll.is_active()):
		if _animation_tree != null:
			_animation_tree.process_mode = _replay_saved_tree_process_mode
			_animation_tree.active = true
		_ensure_idle_animating()


func reset_visual_for_replay() -> void:
	if _ragdoll != null and _ragdoll.is_active():
		print("[GroyperDuelist] reset_visual_for_replay deactivating ragdoll")
		_ragdoll.deactivate()
	if _duel_hat != null:
		_duel_hat.restore_for_replay()
	_defeated = false
	_ai_state = AiState.IDLE
	set_process(false)
	if _animation_tree != null:
		_animation_tree.active = false
	if _animation_player != null:
		_animation_player.stop()


func capture_replay_snapshot() -> Dictionary:
	var weapon_state := {}
	if _weapon_rig != null and _weapon_rig.has_method("capture_replay_state"):
		weapon_state = _weapon_rig.capture_replay_state()

	return {
		"pos": global_position,
		"rot_y": rotation.y,
		"aim_target": _smoothed_aim_point,
		"weapon": weapon_state,
	}


func apply_replay_snapshot(snap: Dictionary) -> void:
	if snap.is_empty():
		return
	if _ragdoll != null and _ragdoll.is_active():
		return
	if _defeated:
		return

	global_position = snap["pos"]
	rotation.y = snap.get("rot_y", rotation.y)
	_smoothed_aim_point = snap.get("aim_target", _smoothed_aim_point)

	if _weapon_rig != null and _weapon_rig.has_method("apply_replay_state"):
		_weapon_rig.apply_replay_state(snap.get("weapon", {}))

	_sync_hitbox_position()


func enable_target_mode(enabled: bool) -> void:
	_target_mode = enabled
	if enabled:
		remove_from_group("duel_enemy")
		remove_from_group("duel_target")
		add_to_group("target_rival")


func set_target_objects(objects: Array) -> void:
	_target_objects = objects


func prepare_for_target_round() -> void:
	prepare_for_round()
	_target_ammo = 6
	_target_active = false
	_target_fire_cooldown = 0.0


func begin_target_sequence() -> void:
	if _defeated:
		return

	_target_active = true
	_target_ammo = 6
	_target_fire_cooldown = randf_range(TARGET_FIRE_DELAY_MIN, TARGET_FIRE_DELAY_MAX)
	_ai_state = AiState.DRAWING
	_has_locked_aim = true
	_locked_world_aim_point = _pick_target_aim_point()
	_smoothed_aim_point = _locked_world_aim_point
	_weapon_rig.set_prep_aim(false)
	_weapon_rig.begin_draw()


func stop_target_sequence() -> void:
	_target_active = false


func _update_target_ai(delta: float) -> void:
	_target_fire_cooldown = maxf(_target_fire_cooldown - delta, 0.0)
	_locked_world_aim_point = _pick_target_aim_point()
	_smoothed_aim_point = _smoothed_aim_point.lerp(_locked_world_aim_point, delta * 14.0)

	match _ai_state:
		AiState.DRAWING:
			if _weapon_rig.is_aiming():
				_ai_state = AiState.AIMING
				if _target_fire_cooldown <= 0.0:
					_fire_at_target_object()
		AiState.AIMING:
			if _target_fire_cooldown <= 0.0:
				_fire_at_target_object()


func _fire_at_target_object() -> void:
	if _target_ammo <= 0 or _weapon_rig == null:
		return
	if not _weapon_rig.is_aiming():
		return

	_locked_world_aim_point = _pick_target_aim_point()
	_smoothed_aim_point = _locked_world_aim_point
	_weapon_rig.fire_at(_smoothed_aim_point)
	_target_ammo -= 1
	_target_fire_cooldown = randf_range(TARGET_FIRE_DELAY_MIN, TARGET_FIRE_DELAY_MAX)
	_ai_state = AiState.AIMING
	shot_fired.emit()


func _pick_target_aim_point() -> Vector3:
	var available: Array[Node3D] = []
	for obj in _target_objects:
		if not is_instance_valid(obj):
			continue
		if obj.has_method("is_scored") and obj.is_scored():
			continue
		available.append(obj)

	if available.is_empty():
		return global_position + Vector3(0.0, 1.2, -10.0)

	var pick: Node3D = available[randi() % available.size()]
	var base := pick.global_position

	if randf() < TARGET_MISS_CHANCE:
		return base + Vector3(
			randf_range(-0.85, 0.85),
			randf_range(-0.35, 0.55),
			randf_range(-0.55, 0.55)
		)

	return base + Vector3(
		randf_range(-0.05, 0.05),
		randf_range(-0.02, 0.08),
		randf_range(-0.02, 0.02)
	)
