extends "res://characters/baldwin/baldwin_actor.gd"
class_name BaldwinOverworldPlayer

## Playable Baldwin — sword & shield melee with third-person camera.

const BaldwinAnimConfigScript := preload("res://characters/baldwin/baldwin_anim_config.gd")
const BaldwinAnimUtilsScript := preload("res://characters/baldwin/baldwin_anim_utils.gd")
const RigAnimUtilsScript := preload("res://characters/groyper/rig_anim_utils.gd")
const BaldwinBodyUtilsScript := preload("res://characters/baldwin/baldwin_body_utils.gd")
const BaldwinShieldConfigScript := preload("res://characters/baldwin/baldwin_shield_config.gd")
const BaldwinWeaponRigScript := preload("res://characters/baldwin/baldwin_weapon_rig.gd")
const CombatAnimTransitionsScript := preload("res://gameplay/combat/combat_anim_transitions.gd")
const CombatHitFlashScript := preload("res://gameplay/fx/combat_hit_flash.gd")
const FactionIdsScript := preload("res://gameplay/faction/faction_ids.gd")
const MeleeClashScript := preload("res://gameplay/combat/melee_clash.gd")
const MeleeSwordSlashScript := preload("res://gameplay/combat/melee_sword_slash.gd")
const SwordCrescentFXScript := preload("res://gameplay/fx/sword_crescent_fx.gd")
const BlockPoiseScript := preload("res://gameplay/combat/block_poise.gd")
const FloatingBlockPoiseBarScript := preload("res://gameplay/ui/floating_block_poise_bar.gd")
const GroyperWeaponsScript := preload("res://characters/groyper/groyper_weapons.gd")

const GRAVITY := 22.0
const WALK_SPEED := 3.2
const RUN_SPEED := 6.0
const FACING_SPEED := 12.0
const MOUSE_SENSITIVITY := 0.0025
const CAMERA_PITCH_MIN := deg_to_rad(-35.0)
const CAMERA_PITCH_MAX := deg_to_rad(55.0)
const CAMERA_YAW_OFFSET := PI
const LOCOMOTION_BLEND := BaldwinAnimConfigScript.LOCOMOTION_BLEND
# Prebuilt to avoid a per-physics-frame string format in _physics_process.
var _locomotion_blend_param := StringName("parameters/%s/blend_position" % LOCOMOTION_BLEND)
const LOCOMOTION_STOP_SPEED := 0.08
const ATTACK_RANGE := MeleeSwordSlashScript.RANGE
const ATTACK_STRIKE_FRACTION := 0.35
const ATTACK_COOLDOWN := MeleeSwordSlashScript.COOLDOWN
const BLOCK_FACING_DOT_MIN := 0.32

@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _camera_arm: OverworldCameraArm = $CameraPivot/CameraArm
@onready var _camera: Camera3D = $CameraPivot/CameraArm/Camera3D
@onready var _interact_hint: Label = $InteractHintLayer/HintLabel

var _weapon_rig: BaldwinWeaponRig
var _nearby_interactables := {}
var _camera_yaw := CAMERA_YAW_OFFSET
var _camera_pitch := 0.0
var _locomotion_blend := 0.0

var _attack_anim_name := StringName()
var _attack_reverse_anim_name := StringName()
var _melee_attack_anim_node: AnimationNodeAnimation
var _shield_block_hold_path := StringName()
var _shield_block_enter_path := StringName()
var _shield_block_clash_path := StringName()
var _shield_block_break_path := StringName()
var _parry_pose_anim_name := StringName()
var _peaceful_idle_path := StringName()
var _aggro_idle_path := StringName()
var _idle_anim_node: AnimationNodeAnimation
var _using_aggro_idle := false

var _combat_blocking := false
var _combat_attacking := false
var _attack_elapsed := 0.0
var _attack_anim_time := 0.0
var _attack_timer := 0.0
var _attack_struck := false
var _attack_reverse := false
var _attack_combo_used := false
var _attack_recovery_to_idle := false
var _attack_reverse_seek := 0.0
var _attack_direction := Vector3.FORWARD
var _attack_cooldown := 0.0
var _attack_seek_tween: Tween
var _block_hold_blend_tween: Tween
var _melee_hit_absorbed := false
var _draw_pending := false


func _ready() -> void:
	super()


func _on_actor_ready() -> void:
	add_to_group("overworld_player")
	add_to_group("player")
	add_to_group("duel_target")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_setup_animations()
	_setup_weapon_rig()
	_camera_arm.bind_owner(self)
	PlayerInventory.inventory_changed.connect(refresh_melee_equipment)
	refresh_melee_equipment()
	call_deferred("snap_to_floor")


func refresh_melee_equipment() -> void:
	BaldwinBodyUtilsScript.sync_melee_equipment_owned(
		_skeleton,
		PlayerInventory.has_sword_shield
	)
	if PlayerInventory.has_sword_shield:
		_ensure_weapon_rig()
		if _weapon_rig != null and _weapon_rig.is_holstered() and not _weapon_rig.is_transitioning():
			_draw_pending = true
			_weapon_rig.begin_draw()
	else:
		_combat_blocking = false
		_complete_attack()
		_set_block_hold_blend(0.0)
		if _weapon_rig != null:
			_weapon_rig.reset_to_holster()


func register_interactable(interactable: Node) -> void:
	if interactable == null:
		return
	_nearby_interactables[interactable.get_instance_id()] = interactable


func unregister_interactable(interactable: Node) -> void:
	if interactable == null:
		return
	_nearby_interactables.erase(interactable.get_instance_id())


func get_faction_id() -> StringName:
	return FactionIdsScript.PLAYER


func get_punch_facing_direction() -> Vector3:
	if _attack_direction.length_squared() > 0.0001 and _combat_attacking:
		return _attack_direction
	return _get_flat_forward()


func is_blocking() -> bool:
	return _combat_blocking


func was_melee_hit_absorbed() -> bool:
	return _melee_hit_absorbed


func receive_bullet_hit(hit_info: Dictionary) -> void:
	_melee_hit_absorbed = false
	if _can_block_melee(hit_info):
		_melee_hit_absorbed = true
		_on_attack_blocked(hit_info)
		return
	if bool(hit_info.get("melee", false)) and hit_info.has("melee_stun_duration"):
		apply_melee_stun(float(hit_info.get("melee_stun_duration", 0.55)))


func _physics_process(delta: float) -> void:
	tick_melee_stun(delta)
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)

	if _weapon_rig != null:
		_weapon_rig.update(delta)
		_weapon_rig.apply_pose_overrides(delta)
		if _draw_pending and _weapon_rig.is_equipped():
			_draw_pending = false
		_update_combat_idle_blend()

	if is_melee_stunned():
		velocity.x = 0.0
		velocity.z = 0.0
		if not is_on_floor():
			velocity.y -= GRAVITY * delta
		move_and_slide()
		_update_camera_transform()
		_update_interact_hint()
		return

	if _combat_attacking:
		_process_attack(delta)
		if not is_on_floor():
			velocity.y -= GRAVITY * delta
		else:
			velocity.y = minf(velocity.y, 0.0)
		move_and_slide()
		_update_camera_transform()
		_update_interact_hint()
		return

	if _combat_blocking:
		_process_blocking(delta)
		if not is_on_floor():
			velocity.y -= GRAVITY * delta
		else:
			velocity.y = minf(velocity.y, 0.0)
		move_and_slide()
		_update_camera_transform()
		_update_interact_hint()
		return

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = minf(velocity.y, 0.0)

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var cam_basis := _camera_pivot.global_transform.basis
	var forward := -cam_basis.z
	forward.y = 0.0
	var right := cam_basis.x
	right.y = 0.0
	if forward.length_squared() > 0.0001:
		forward = forward.normalized()
	if right.length_squared() > 0.0001:
		right = right.normalized()
	var move_dir := forward * input_dir.y + right * input_dir.x

	if move_dir.length_squared() > 0.0001:
		move_dir = move_dir.normalized()
		var speed := RUN_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED
		velocity.x = move_dir.x * speed
		velocity.z = move_dir.z * speed
		_model.rotation.y = lerp_angle(
			_model.rotation.y,
			atan2(move_dir.x, move_dir.z),
			FACING_SPEED * delta
		)
		var blend := 0.5 if speed <= WALK_SPEED + 0.01 else 1.0
		_locomotion_blend = lerpf(_locomotion_blend, blend, 8.0 * delta)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		_locomotion_blend = lerpf(_locomotion_blend, 0.0, 8.0 * delta)

	if _animation_tree != null and _animation_tree.active:
		_animation_tree.set(_locomotion_blend_param, _locomotion_blend)

	move_and_slide()
	_update_camera_transform()
	_update_interact_hint()
	_update_melee_input_hold()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_camera_yaw -= event.relative.x * MOUSE_SENSITIVITY
		_camera_pitch = clampf(
			_camera_pitch - event.relative.y * MOUSE_SENSITIVITY,
			CAMERA_PITCH_MIN,
			CAMERA_PITCH_MAX
		)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_try_begin_attack()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_try_begin_blocking()
	elif event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_try_end_blocking()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_T:
		CompanionManager.request_companion_teleport(self)


func _update_melee_input_hold() -> void:
	if not _can_use_melee():
		if _combat_blocking:
			_end_blocking()
		return
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		if not _combat_blocking and not _combat_attacking:
			_try_begin_blocking()
	elif _combat_blocking:
		_try_end_blocking()


func _can_use_melee() -> bool:
	return (
		PlayerInventory.has_sword_shield
		and _weapon_rig != null
		and _weapon_rig.is_equipped()
		and not _weapon_rig.is_transitioning()
		and not is_melee_stunned()
	)


func _try_begin_blocking() -> void:
	if not _can_use_melee() or _combat_attacking or _combat_blocking:
		return
	_begin_blocking()


func _try_end_blocking() -> void:
	if not _combat_blocking:
		return
	_end_blocking()


func _try_begin_attack() -> void:
	if not _can_use_melee() or _combat_blocking:
		return
	if _combat_attacking:
		if _can_queue_attack_combo():
			_begin_attack_reverse()
		return
	if _attack_cooldown > 0.0:
		return
	_begin_attack()


func _can_queue_attack_combo() -> bool:
	return (
		_attack_struck
		and not _attack_reverse
		and not _attack_combo_used
		and not _attack_recovery_to_idle
		and MeleeSwordSlashScript.is_in_combo_input_window(_attack_anim_time)
	)


func _get_attack_playback_speed() -> float:
	return MeleeSwordSlashScript.get_playback_speed(_animation_tree)


func _update_attack_anim_time(delta: float) -> void:
	if _attack_reverse or _attack_recovery_to_idle:
		_attack_anim_time = _attack_reverse_seek
		return
	var one_shot_time := MeleeSwordSlashScript.read_one_shot_time(
		_animation_tree,
		BaldwinAnimConfigScript.ATTACK_ONE_SHOT
	)
	if one_shot_time >= 0.0:
		_attack_anim_time = one_shot_time
	else:
		_attack_anim_time += MeleeSwordSlashScript.anim_time_step(
			delta,
			_get_attack_playback_speed()
		)


func _begin_blocking() -> void:
	_combat_blocking = true
	_locomotion_blend = 0.0
	FloatingBlockPoiseBarScript.attach_to(self)
	if _animation_tree != null and _animation_tree.active:
		_animation_tree.set(_locomotion_blend_param, 0.0)
	_tween_block_hold_blend(1.0, CombatAnimTransitionsScript.BLOCK_HOLD_BLEND_IN)
	if (
		_animation_tree != null
		and _animation_tree.active
		and _animation_player.has_animation(_shield_block_enter_path)
	):
		_animation_tree.set(
			"parameters/%s/request" % BaldwinAnimConfigScript.BLOCK_ENTER_ONE_SHOT,
			AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
		)


func _end_blocking(fade_duration := CombatAnimTransitionsScript.BLOCK_HOLD_BLEND_OUT) -> void:
	_combat_blocking = false
	if fade_duration > 0.0:
		_tween_block_hold_blend(0.0, fade_duration)
	else:
		_set_block_hold_blend(0.0)


func _process_blocking(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	_face_camera_direction(delta)
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_end_blocking()


func _begin_attack() -> void:
	_cancel_attack_seek_tween()
	_combat_attacking = true
	_attack_elapsed = 0.0
	_attack_anim_time = 0.0
	_attack_timer = _get_attack_length()
	_attack_struck = false
	_attack_reverse = false
	_attack_combo_used = false
	_attack_recovery_to_idle = false
	_attack_reverse_seek = 0.0
	_attack_cooldown = ATTACK_COOLDOWN
	_attack_direction = MeleeSwordSlashScript.get_strike_direction(self)
	_locomotion_blend = 0.0
	if _melee_attack_anim_node != null:
		_melee_attack_anim_node.animation = _attack_anim_name
	_sync_attack_seek(-1.0)
	if _animation_tree != null and _animation_tree.active:
		_animation_tree.set(_locomotion_blend_param, 0.0)
		_animation_tree.set(
			"parameters/%s/request" % BaldwinAnimConfigScript.ATTACK_ONE_SHOT,
			AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
		)


func _begin_attack_reverse() -> void:
	_cancel_attack_seek_tween()
	_attack_combo_used = true
	_attack_reverse = true
	_attack_struck = false
	_attack_recovery_to_idle = false
	var anim_length := _get_attack_length()
	var playback_speed := _get_attack_playback_speed()
	var seek_start := clampf(_attack_anim_time, 0.0, anim_length)
	var seek_end := anim_length
	var reverse_duration := maxf((seek_end - seek_start) / playback_speed, 0.001)
	_attack_elapsed = 0.0
	_attack_timer = reverse_duration
	_attack_direction = MeleeSwordSlashScript.get_strike_direction(self)
	if _melee_attack_anim_node != null and _animation_player.has_animation(_attack_reverse_anim_name):
		_melee_attack_anim_node.animation = _attack_reverse_anim_name
	_tween_attack_reverse_seek(seek_start, seek_end, reverse_duration)


func _process_attack(delta: float) -> void:
	_attack_elapsed += delta
	_attack_timer -= delta
	velocity.x = 0.0
	velocity.z = 0.0
	_face_camera_direction(delta)
	_attack_direction = MeleeSwordSlashScript.get_strike_direction(self)
	_update_attack_anim_time(delta)

	var anim_length := _get_attack_length()
	if not _attack_recovery_to_idle:
		if _attack_reverse:
			var strike_seek := anim_length * (1.0 - ATTACK_STRIKE_FRACTION)
			if not _attack_struck and _attack_reverse_seek >= strike_seek:
				_apply_attack_strike()
		else:
			var strike_time := anim_length * ATTACK_STRIKE_FRACTION
			if not _attack_struck and _attack_anim_time >= strike_time:
				_apply_attack_strike()

	if _attack_timer <= 0.0:
		_finish_attack()


func _apply_attack_strike() -> void:
	_attack_struck = true
	var strike_target := MeleeSwordSlashScript.find_strike_target(
		self,
		_attack_direction
	) as Node3D
	MeleeSwordSlashScript.apply_strike(self, _attack_direction, strike_target)
	SwordCrescentFXScript.spawn_preview(self, _attack_direction, ATTACK_RANGE)


func _finish_attack() -> void:
	if _attack_recovery_to_idle:
		_complete_attack()
		return
	if not _begin_attack_return_to_idle():
		_complete_attack()


func _begin_attack_return_to_idle() -> bool:
	_cancel_attack_seek_tween()
	var anim_length := _get_attack_length()
	var playback_speed := _get_attack_playback_speed()
	var seek_start := 0.0
	if _attack_reverse:
		seek_start = clampf(_attack_reverse_seek, 0.0, anim_length)
	if seek_start >= anim_length - 0.03:
		return false

	_attack_recovery_to_idle = true
	_attack_reverse = true
	var duration := maxf((anim_length - seek_start) / playback_speed, 0.001)
	_attack_timer = duration
	if _melee_attack_anim_node != null and _animation_player.has_animation(_attack_reverse_anim_name):
		_melee_attack_anim_node.animation = _attack_reverse_anim_name
	_tween_attack_reverse_seek(seek_start, anim_length, duration)
	return true


func _complete_attack() -> void:
	_cancel_attack_seek_tween()
	_combat_attacking = false
	_attack_struck = false
	_attack_reverse = false
	_attack_combo_used = false
	_attack_recovery_to_idle = false
	_attack_anim_time = 0.0
	_attack_reverse_seek = 0.0
	if _melee_attack_anim_node != null:
		_melee_attack_anim_node.animation = _attack_anim_name
	_sync_attack_seek(-1.0)
	if _can_use_melee():
		_set_combat_idle(true)


func _sync_attack_seek(time: float) -> void:
	if _animation_tree == null or not _animation_tree.active:
		return
	_animation_tree.set(
		"parameters/%s/seek_request" % BaldwinAnimConfigScript.ATTACK_TIME_SEEK,
		time
	)
	if time >= 0.0:
		_attack_reverse_seek = time


func _cancel_attack_seek_tween() -> void:
	if _attack_seek_tween != null and _attack_seek_tween.is_valid():
		_attack_seek_tween.kill()
	_attack_seek_tween = null


func _tween_attack_reverse_seek(from_time: float, to_time: float, duration: float) -> void:
	_cancel_attack_seek_tween()
	_sync_attack_seek(from_time)
	if duration <= 0.0 or is_equal_approx(from_time, to_time):
		_sync_attack_seek(to_time)
		return
	_attack_seek_tween = create_tween()
	_attack_seek_tween.set_trans(Tween.TRANS_CUBIC)
	_attack_seek_tween.set_ease(Tween.EASE_IN_OUT)
	_attack_seek_tween.tween_method(_sync_attack_seek, from_time, to_time, duration)


func _can_block_melee(hit_info: Dictionary) -> bool:
	return (
		_combat_blocking
		and bool(hit_info.get("melee", false))
		and _is_facing_attack(hit_info)
	)


func _on_attack_blocked(hit_info: Dictionary) -> void:
	var attacker: Node = hit_info.get("shooter")
	var result := BlockPoiseScript.apply_hit(self, hit_info)
	if result == BlockPoiseScript.Result.BROKEN:
		BlockPoiseScript.break_block(self, attacker, hit_info)
		return
	MeleeClashScript.resolve(self, attacker, hit_info)


func get_block_poise_bonus() -> float:
	return GroyperWeaponsScript.get_block_poise(GroyperWeaponsScript.Id.SWORD_SHIELD)


func on_block_poise_broken(_attacker: Node, hit_info: Dictionary) -> void:
	_on_shield_block_broken(hit_info)


func _on_shield_block_broken(_hit_info: Dictionary) -> void:
	_end_blocking(0.0)
	apply_melee_stun(BlockPoiseScript.BREAK_STUN)
	if _animation_tree != null and _animation_tree.active \
			and _animation_player.has_animation(_shield_block_break_path):
		_animation_tree.set(
			"parameters/%s/request" % BaldwinAnimConfigScript.BLOCK_BREAK_ONE_SHOT,
			AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
		)


func _is_facing_attack(hit_info: Dictionary) -> bool:
	var attacker: Node = hit_info.get("shooter")
	if attacker is Node3D:
		var to_attacker := (attacker as Node3D).global_position - global_position
		to_attacker.y = 0.0
		if to_attacker.length_squared() > 0.0001:
			return _get_flat_forward().dot(to_attacker.normalized()) >= BLOCK_FACING_DOT_MIN

	var attack_dir: Vector3 = hit_info.get("direction", Vector3.FORWARD)
	attack_dir.y = 0.0
	if attack_dir.length_squared() < 0.0001:
		attack_dir = _get_flat_forward()
	return _get_flat_forward().dot(attack_dir.normalized()) <= -BLOCK_FACING_DOT_MIN


func _get_flat_forward() -> Vector3:
	var forward := -_model.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		return Vector3.FORWARD
	return forward.normalized()


func _face_camera_direction(delta: float) -> void:
	var cam_forward := -_camera_pivot.global_transform.basis.z
	cam_forward.y = 0.0
	if cam_forward.length_squared() < 0.0001:
		return
	cam_forward = cam_forward.normalized()
	_model.rotation.y = lerp_angle(
		_model.rotation.y,
		atan2(cam_forward.x, cam_forward.z),
		FACING_SPEED * delta
	)


func _update_camera_transform() -> void:
	_camera_pivot.rotation.y = _camera_yaw
	_set_camera_arm_pitch()


func _set_camera_arm_pitch(extra_pitch: float = 0.0) -> void:
	if _camera_arm == null:
		return
	_camera_arm.rotation.x = _camera_pitch + extra_pitch + _camera_arm.get_occlusion_pitch()


func _try_interact() -> void:
	var target := _get_nearest_interactable()
	if target != null and target.has_method("interact"):
		target.interact(self)


func _get_nearest_interactable() -> Node:
	var nearest: Node = null
	var nearest_dist_sq := INF
	for interactable: Node in _nearby_interactables.values():
		if interactable == null or not is_instance_valid(interactable):
			continue
		var dist_sq := global_position.distance_squared_to(interactable.global_position)
		if dist_sq < nearest_dist_sq:
			nearest_dist_sq = dist_sq
			nearest = interactable
	return nearest


func _update_interact_hint() -> void:
	if _interact_hint == null:
		return
	var target := _get_nearest_interactable()
	var show_hint := target != null
	if show_hint and target.has_method("get_interact_hint"):
		var hint: String = target.get_interact_hint()
		if hint.is_empty():
			show_hint = false
		else:
			_interact_hint.text = "[E] %s" % hint
	elif show_hint:
		_interact_hint.text = "[E] Interact"
	_interact_hint.visible = show_hint


func _ensure_weapon_rig() -> void:
	if _weapon_rig != null or _skeleton == null:
		return
	_weapon_rig = BaldwinWeaponRigScript.new()
	_weapon_rig.name = "BaldwinWeaponRig"
	add_child(_weapon_rig)
	_weapon_rig.setup(self, _skeleton)
	_weapon_rig.set_release_arms_when_idle(false)


func _setup_weapon_rig() -> void:
	_ensure_weapon_rig()
	if _weapon_rig != null:
		_weapon_rig.reset_to_holster()


func _setup_animations() -> void:
	if _animation_player == null:
		push_error("BaldwinOverworldPlayer: missing AnimationPlayer.")
		return
	if _animation_tree == null:
		push_error("BaldwinOverworldPlayer: missing AnimationTree.")
		return

	if _animation_tree.active:
		_animation_tree.active = false

	var library := AnimationLibrary.new()
	_add_merged_clip(library, BaldwinAnimConfigScript.CLIP_IDLE, BaldwinAnimConfigScript.MESHY_IDLE, Animation.LOOP_LINEAR)
	_add_merged_clip(library, BaldwinAnimConfigScript.CLIP_AGGRO_IDLE, BaldwinAnimConfigScript.MESHY_AGGRO_IDLE, Animation.LOOP_LINEAR)
	_add_merged_clip(library, BaldwinAnimConfigScript.CLIP_WALK, BaldwinAnimConfigScript.MESHY_WALK, Animation.LOOP_LINEAR)
	_add_merged_clip(library, BaldwinAnimConfigScript.CLIP_RUN, BaldwinAnimConfigScript.MESHY_RUN, Animation.LOOP_LINEAR)
	_add_merged_clip(library, BaldwinAnimConfigScript.CLIP_SWORD_SLASH, BaldwinAnimConfigScript.MESHY_SWORD_SLASH, Animation.LOOP_NONE)
	var slash := library.get_animation(BaldwinAnimConfigScript.CLIP_SWORD_SLASH)
	if slash != null:
		var slash_reverse := RigAnimUtilsScript.make_reversed_animation(slash)
		slash_reverse.loop_mode = Animation.LOOP_NONE
		library.add_animation(BaldwinAnimConfigScript.CLIP_SWORD_SLASH_REVERSE, slash_reverse)
	_add_shield_block_clips(library)

	if _animation_player.has_animation_library(BaldwinAnimConfigScript.LIBRARY):
		_animation_player.remove_animation_library(BaldwinAnimConfigScript.LIBRARY)
	_animation_player.add_animation_library(BaldwinAnimConfigScript.LIBRARY, library)

	_attack_anim_name = _clip_path(BaldwinAnimConfigScript.CLIP_SWORD_SLASH)
	_attack_reverse_anim_name = _clip_path(BaldwinAnimConfigScript.CLIP_SWORD_SLASH_REVERSE)
	_parry_pose_anim_name = _clip_path(BaldwinAnimConfigScript.CLIP_PARRY_POSE)
	_shield_block_hold_path = _clip_path(BaldwinAnimConfigScript.CLIP_SHIELD_BLOCK_HOLD)
	_shield_block_enter_path = _clip_path(BaldwinAnimConfigScript.CLIP_SHIELD_BLOCK_ENTER)
	_shield_block_clash_path = _clip_path(BaldwinAnimConfigScript.CLIP_SHIELD_BLOCK_CLASH)
	_shield_block_break_path = _clip_path(BaldwinAnimConfigScript.CLIP_SHIELD_BLOCK_BREAK)
	_setup_animation_tree()
	call_deferred("_rebind_animation_tree")


func _add_shield_block_clips(library: AnimationLibrary) -> void:
	var hold := BaldwinAnimUtilsScript.load_merged_clip(
		BaldwinAnimConfigScript.MESHY_SHIELD_BLOCK_HOLD,
		Animation.LOOP_LINEAR
	)
	if hold != null:
		hold.resource_name = "shield_block_hold"
		library.add_animation(BaldwinAnimConfigScript.CLIP_SHIELD_BLOCK_HOLD, hold)
	else:
		_add_legacy_parry_hold_clip(library)

	var enter := BaldwinAnimUtilsScript.load_merged_clip(
		BaldwinAnimConfigScript.MESHY_SHIELD_BLOCK_ENTER,
		Animation.LOOP_NONE
	)
	if enter != null:
		enter.resource_name = "shield_block_enter"
		library.add_animation(BaldwinAnimConfigScript.CLIP_SHIELD_BLOCK_ENTER, enter)

	var clash := BaldwinAnimUtilsScript.load_merged_clip(
		BaldwinAnimConfigScript.MESHY_SHIELD_BLOCK_CLASH,
		Animation.LOOP_NONE
	)
	if clash != null:
		clash.resource_name = "shield_block_clash"
		library.add_animation(BaldwinAnimConfigScript.CLIP_SHIELD_BLOCK_CLASH, clash)
	else:
		_add_legacy_parry_clash_clip(library)

	var block_break := BaldwinAnimUtilsScript.load_merged_clip(
		BaldwinAnimConfigScript.MESHY_SHIELD_BLOCK_BREAK,
		Animation.LOOP_NONE
	)
	if block_break != null:
		block_break.resource_name = "shield_block_break"
		library.add_animation(BaldwinAnimConfigScript.CLIP_SHIELD_BLOCK_BREAK, block_break)


func _add_legacy_parry_hold_clip(library: AnimationLibrary) -> void:
	var parry_source := RigAnimUtilsScript.load_skeleton_animation(
		BaldwinAnimConfigScript.MERGED_SCENE,
		BaldwinAnimConfigScript.MESHY_SWORD_PARRY
	)
	if parry_source != null:
		var hold_pose := RigAnimUtilsScript.extract_pose_at_time(parry_source, 0.0)
		hold_pose.loop_mode = Animation.LOOP_LINEAR
		library.add_animation(BaldwinAnimConfigScript.CLIP_SHIELD_BLOCK_HOLD, hold_pose)
		library.add_animation(BaldwinAnimConfigScript.CLIP_PARRY_POSE, hold_pose)


func _add_legacy_parry_clash_clip(library: AnimationLibrary) -> void:
	var clash_raw := RigAnimUtilsScript.load_skeleton_animation(
		BaldwinAnimConfigScript.MERGED_SCENE,
		BaldwinAnimConfigScript.MESHY_SWORD_PARRY_BACKWARD
	)
	if clash_raw != null:
		var clash := RigAnimUtilsScript.prepare_meshy_merged_clip(clash_raw, false)
		clash.loop_mode = Animation.LOOP_NONE
		library.add_animation(BaldwinAnimConfigScript.CLIP_SHIELD_BLOCK_CLASH, clash)
		library.add_animation(BaldwinAnimConfigScript.CLIP_PARRY_BACKWARD, clash)


func _setup_animation_tree() -> void:
	var idle_path := _clip_path(BaldwinAnimConfigScript.CLIP_IDLE)
	var aggro_idle_path := _clip_path(BaldwinAnimConfigScript.CLIP_AGGRO_IDLE)
	var walk_path := _clip_path(BaldwinAnimConfigScript.CLIP_WALK)
	var run_path := _clip_path(BaldwinAnimConfigScript.CLIP_RUN)
	var attack_path := _clip_path(BaldwinAnimConfigScript.CLIP_SWORD_SLASH)
	var block_hold_path := _clip_path(BaldwinAnimConfigScript.CLIP_SHIELD_BLOCK_HOLD)
	var block_enter_path := _clip_path(BaldwinAnimConfigScript.CLIP_SHIELD_BLOCK_ENTER)
	var block_clash_path := _clip_path(BaldwinAnimConfigScript.CLIP_SHIELD_BLOCK_CLASH)
	var block_break_path := _clip_path(BaldwinAnimConfigScript.CLIP_SHIELD_BLOCK_BREAK)

	if (
		not _animation_player.has_animation(idle_path)
		or not _animation_player.has_animation(aggro_idle_path)
		or not _animation_player.has_animation(walk_path)
		or not _animation_player.has_animation(run_path)
		or not _animation_player.has_animation(attack_path)
	):
		push_error("BaldwinOverworldPlayer: locomotion clips missing.")
		return

	var peaceful_idle_node := AnimationNodeAnimation.new()
	peaceful_idle_node.animation = idle_path
	_idle_anim_node = peaceful_idle_node
	_peaceful_idle_path = idle_path
	_aggro_idle_path = aggro_idle_path

	var walk_node := AnimationNodeAnimation.new()
	walk_node.animation = walk_path
	var run_node := AnimationNodeAnimation.new()
	run_node.animation = run_path

	var blend_space := AnimationNodeBlendSpace1D.new()
	blend_space.add_blend_point(peaceful_idle_node, 0.0)
	blend_space.add_blend_point(walk_node, 0.5)
	blend_space.add_blend_point(run_node, 1.0)
	blend_space.min_space = 0.0
	blend_space.max_space = 1.0

	var attack_node := AnimationNodeAnimation.new()
	attack_node.animation = attack_path
	_melee_attack_anim_node = attack_node
	var attack_time_seek := AnimationNodeTimeSeek.new()
	var attack_shot := AnimationNodeOneShot.new()
	CombatAnimTransitionsScript.configure_one_shot(
		attack_shot,
		CombatAnimTransitionsScript.ATTACK_FADEIN,
		CombatAnimTransitionsScript.ATTACK_FADEOUT
	)

	var block_hold_node := AnimationNodeAnimation.new()
	if _animation_player.has_animation(block_hold_path):
		block_hold_node.animation = block_hold_path
	elif _animation_player.has_animation(_parry_pose_anim_name):
		block_hold_node.animation = _parry_pose_anim_name
	var block_hold_blend := AnimationNodeBlend2.new()
	BaldwinAnimUtilsScript.configure_block_hold_blend(block_hold_blend)

	var blend_tree := AnimationNodeBlendTree.new()
	blend_tree.add_node(LOCOMOTION_BLEND, blend_space)
	blend_tree.add_node(BaldwinAnimConfigScript.BLOCK_HOLD_BLEND, block_hold_blend)
	blend_tree.add_node(&"ShieldBlockHoldAnim", block_hold_node)
	blend_tree.add_node(BaldwinAnimConfigScript.ATTACK_ONE_SHOT, attack_shot)
	blend_tree.add_node(&"AttackAnim", attack_node)
	blend_tree.add_node(BaldwinAnimConfigScript.ATTACK_TIME_SEEK, attack_time_seek)
	blend_tree.connect_node(BaldwinAnimConfigScript.BLOCK_HOLD_BLEND, 0, LOCOMOTION_BLEND)
	blend_tree.connect_node(BaldwinAnimConfigScript.BLOCK_HOLD_BLEND, 1, &"ShieldBlockHoldAnim")
	blend_tree.connect_node(BaldwinAnimConfigScript.ATTACK_ONE_SHOT, 0, BaldwinAnimConfigScript.BLOCK_HOLD_BLEND)
	blend_tree.connect_node(BaldwinAnimConfigScript.ATTACK_ONE_SHOT, 1, BaldwinAnimConfigScript.ATTACK_TIME_SEEK)
	blend_tree.connect_node(BaldwinAnimConfigScript.ATTACK_TIME_SEEK, 0, &"AttackAnim")

	var output_node: StringName = BaldwinAnimConfigScript.ATTACK_ONE_SHOT
	if _animation_player.has_animation(block_enter_path):
		var block_enter_node := AnimationNodeAnimation.new()
		block_enter_node.animation = block_enter_path
		var block_enter_shot := AnimationNodeOneShot.new()
		CombatAnimTransitionsScript.configure_one_shot(
			block_enter_shot,
			CombatAnimTransitionsScript.BLOCK_ENTER_FADEIN,
			CombatAnimTransitionsScript.BLOCK_ENTER_FADEOUT
		)
		blend_tree.add_node(BaldwinAnimConfigScript.BLOCK_ENTER_ONE_SHOT, block_enter_shot)
		blend_tree.add_node(&"ShieldBlockEnterAnim", block_enter_node)
		blend_tree.connect_node(BaldwinAnimConfigScript.BLOCK_ENTER_ONE_SHOT, 0, BaldwinAnimConfigScript.ATTACK_ONE_SHOT)
		blend_tree.connect_node(BaldwinAnimConfigScript.BLOCK_ENTER_ONE_SHOT, 1, &"ShieldBlockEnterAnim")
		output_node = BaldwinAnimConfigScript.BLOCK_ENTER_ONE_SHOT

	if _animation_player.has_animation(block_clash_path):
		var block_clash_node := AnimationNodeAnimation.new()
		block_clash_node.animation = block_clash_path
		var block_clash_shot := AnimationNodeOneShot.new()
		CombatAnimTransitionsScript.configure_one_shot(
			block_clash_shot,
			CombatAnimTransitionsScript.PARRY_CLASH_FADEIN,
			CombatAnimTransitionsScript.PARRY_CLASH_FADEOUT,
			true
		)
		blend_tree.add_node(BaldwinAnimConfigScript.BLOCK_CLASH_ONE_SHOT, block_clash_shot)
		blend_tree.add_node(&"ShieldBlockClashAnim", block_clash_node)
		blend_tree.connect_node(BaldwinAnimConfigScript.BLOCK_CLASH_ONE_SHOT, 0, output_node)
		blend_tree.connect_node(BaldwinAnimConfigScript.BLOCK_CLASH_ONE_SHOT, 1, &"ShieldBlockClashAnim")
		output_node = BaldwinAnimConfigScript.BLOCK_CLASH_ONE_SHOT

	if _animation_player.has_animation(block_break_path):
		var block_break_node := AnimationNodeAnimation.new()
		block_break_node.animation = block_break_path
		var block_break_shot := AnimationNodeOneShot.new()
		CombatAnimTransitionsScript.configure_one_shot(
			block_break_shot,
			CombatAnimTransitionsScript.BLOCK_BREAK_FADEIN,
			CombatAnimTransitionsScript.BLOCK_BREAK_FADEOUT,
			true
		)
		blend_tree.add_node(BaldwinAnimConfigScript.BLOCK_BREAK_ONE_SHOT, block_break_shot)
		blend_tree.add_node(&"ShieldBlockBreakAnim", block_break_node)
		blend_tree.connect_node(BaldwinAnimConfigScript.BLOCK_BREAK_ONE_SHOT, 0, output_node)
		blend_tree.connect_node(BaldwinAnimConfigScript.BLOCK_BREAK_ONE_SHOT, 1, &"ShieldBlockBreakAnim")
		output_node = BaldwinAnimConfigScript.BLOCK_BREAK_ONE_SHOT

	blend_tree.connect_node(&"output", 0, output_node)

	_animation_tree.tree_root = blend_tree
	_animation_tree.anim_player = _animation_tree.get_path_to(_animation_player)
	_animation_tree.process_priority = -100
	_animation_tree.active = true
	_animation_tree.set(_locomotion_blend_param, 0.0)
	_animation_tree.set("parameters/%s/blend_amount" % BaldwinAnimConfigScript.BLOCK_HOLD_BLEND, 0.0)


func _rebind_animation_tree() -> void:
	if _animation_tree == null or _animation_player == null:
		return
	_animation_tree.anim_player = _animation_tree.get_path_to(_animation_player)


func _update_combat_idle_blend() -> void:
	if _idle_anim_node == null or _weapon_rig == null:
		return
	var use_aggro := _weapon_rig.is_equipped()
	if use_aggro:
		var horizontal_speed := Vector2(velocity.x, velocity.z).length()
		use_aggro = horizontal_speed <= LOCOMOTION_STOP_SPEED and not _combat_attacking
	_set_combat_idle(use_aggro)


func _set_combat_idle(active: bool) -> void:
	if _using_aggro_idle == active or _idle_anim_node == null:
		return
	_using_aggro_idle = active
	_idle_anim_node.animation = _aggro_idle_path if active else _peaceful_idle_path


func _set_block_hold_blend(value: float) -> void:
	if _animation_tree == null or not _animation_tree.active:
		return
	_animation_tree.set(
		"parameters/%s/blend_amount" % BaldwinAnimConfigScript.BLOCK_HOLD_BLEND,
		clampf(value, 0.0, 1.0)
	)


func _tween_block_hold_blend(target: float, duration: float) -> void:
	if _animation_tree == null or not _animation_tree.active:
		return
	if _block_hold_blend_tween != null and _block_hold_blend_tween.is_valid():
		_block_hold_blend_tween.kill()
	if duration <= 0.0:
		_set_block_hold_blend(target)
		return
	_block_hold_blend_tween = CombatAnimTransitionsScript.tween_tree_float(
		self,
		_animation_tree,
		"%s/blend_amount" % BaldwinAnimConfigScript.BLOCK_HOLD_BLEND,
		target,
		duration
	)


func _get_attack_length() -> float:
	if _animation_player == null or _attack_anim_name.is_empty():
		return 0.8
	if _animation_player.has_animation(_attack_anim_name):
		return _animation_player.get_animation(_attack_anim_name).length
	return 0.8


func _add_merged_clip(
	library: AnimationLibrary,
	clip_name: StringName,
	meshy_clip: StringName,
	loop_mode: Animation.LoopMode
) -> void:
	var raw := RigAnimUtilsScript.load_skeleton_animation(
		BaldwinAnimConfigScript.MERGED_SCENE,
		meshy_clip
	)
	if raw == null:
		push_error("BaldwinOverworldPlayer: failed to load clip '%s'." % meshy_clip)
		return
	var animation := RigAnimUtilsScript.prepare_meshy_merged_clip(raw, false)
	animation.loop_mode = loop_mode
	library.add_animation(clip_name, animation)


func _clip_path(clip_name: StringName) -> StringName:
	return StringName("%s/%s" % [BaldwinAnimConfigScript.LIBRARY, clip_name])
