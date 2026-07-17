extends Node
class_name GroyperWeaponRig

const BULLET_SCENE := preload("res://gameplay/shooting/bullet.tscn")
const ARROW_SCENE := preload("res://gameplay/shooting/arrow_projectile.tscn")
const SHOTGUN_PELLET_SCENE := preload("res://gameplay/shooting/shotgun_pellet.tscn")
const SHOT_BEAM := preload("res://characters/groyper/shot_beam.gd")
const MuzzleFlashFXScript := preload("res://gameplay/fx/muzzle_flash_fx.gd")

const GroyperWeapons := preload("res://characters/groyper/groyper_weapons.gd")

const ARM_BONE := "RightArm"
const FOREARM_BONE := "RightForeArm"
const HAND_BONE := "RightHand"
const SHOULDER_BONE := "RightShoulder"
const AIM_IK_BONES := [ARM_BONE, FOREARM_BONE]
## Gun aim only twists the upper arm; forearm stays straight (identity) to avoid a bent elbow.
const GUN_AIM_IK_BONES := [ARM_BONE]
const AIM_BONES := [ARM_BONE, FOREARM_BONE, HAND_BONE]
const GUN_ARM_BONES := [SHOULDER_BONE, ARM_BONE, FOREARM_BONE, HAND_BONE]
const MOUNT_SPINE_BONES := ["Spine", "Spine01", "Spine02"]
const MOUNT_SPINE_TWIST_WEIGHTS := [0.2, 0.35, 0.45]
const ARM_AIM_MODIFIER_SCRIPT := preload("res://characters/groyper/groyper_arm_aim_modifier.gd")
const HipFireAimPoseConfig := preload("res://characters/groyper/hip_fire_aim_pose_config.gd")
const TwoHandAimPoseConfig := preload("res://characters/groyper/two_hand_aim_pose_config.gd")
const BowAimPoseConfig := preload("res://characters/groyper/bow_aim_pose_config.gd")
const ShellCasingFX := preload("res://gameplay/fx/shell_casing_fx.gd")
const GameAudio := preload("res://gameplay/audio/game_audio.gd")

const LEFT_SHOULDER_BONE := "LeftShoulder"
const LEFT_ARM_BONE := "LeftArm"
const LEFT_FOREARM_BONE := "LeftForeArm"
const LEFT_HAND_BONE := "LeftHand"
const LEFT_AIM_BONES := [LEFT_ARM_BONE, LEFT_FOREARM_BONE, LEFT_HAND_BONE]
const TWO_HAND_SHOULDER_BONES := [LEFT_SHOULDER_BONE, SHOULDER_BONE]
const TWO_HAND_AIM_BONES := [
	LEFT_SHOULDER_BONE,
	LEFT_ARM_BONE,
	LEFT_FOREARM_BONE,
	LEFT_HAND_BONE,
	SHOULDER_BONE,
	ARM_BONE,
	FOREARM_BONE,
	HAND_BONE,
	"Spine",
	"Spine01",
	"Spine02",
	"Head",
]

const RELOAD_RAISE_DURATION := 0.28
const RELOAD_EJECT_DURATION := 0.55
const RELOAD_LOAD_SWING_DURATION := 0.11
const RELOAD_HOLSTER_DURATION := 0.22
## Fade procedural holster arm poses into locomotion instead of snapping.
const HOLSTER_EXIT_BLEND_DURATION := 0.22
const BOW_MIN_SPEED := 1.5
const BOW_MAX_SPEED := 23.0
## Release: freeze BowAim scrub at the draw peak, then linear-reverse to hold (t=0).
const BOW_STRING_RELEASE_HOLD := 0.12
const BOW_STRING_REVERSE_DURATION := 0.4

enum DrawState { HOLSTERED, DRAWING, HOLSTERING, AIMING }

enum OverworldReloadPhase { NONE, RAISING, EJECTING, TAP_READY, LOADING, HOLSTERING }

signal draw_state_changed(new_state: DrawState)

@export var draw_duration := 0.48
@export var holster_duration := 0.32
@export var draw_grab_threshold := 0.68
@export var holster_reach_offset := Vector3(0.0, 0.06, 0.02)
@export_range(0.0, 0.8, 0.01) var holster_reach_outward := GroyperBodyUtils.DEFAULT_HOLSTER_REACH_OUTWARD
@export_range(0.0, 0.5, 0.01) var holster_reach_forward := GroyperBodyUtils.DEFAULT_HOLSTER_REACH_FORWARD
@export_range(0.0, 0.5, 0.01) var holster_reach_down := GroyperBodyUtils.DEFAULT_HOLSTER_REACH_DOWN
@export_range(0.0, 0.9, 0.01) var holster_reach_inward_start := GroyperBodyUtils.DEFAULT_HOLSTER_REACH_INWARD_START
@export_range(0.0, 60.0, 1.0) var holster_reach_abduct_deg := GroyperBodyUtils.DEFAULT_HOLSTER_REACH_ABDUCT_DEG
@export var hand_grip_position := Vector3(-0.1, -0.05, -0.08)
@export var hand_grip_rotation_deg := Vector3(-161.0, 13.0, -160.0)
@export var aim_arm_target_distance := 55.0
@export var aim_pose_smooth := 16.0
@export var holstered_arm_rotation_deg: Vector3 = GroyperBodyUtils.DEFAULT_HOLSTERED_ARM_ROTATION_DEG

var _owner: Node3D
var _skeleton: Skeleton3D
var _hip_holster_mount: BoneAttachment3D
var _hip_holster_socket: Node3D
var _back_holster_mount: BoneAttachment3D
var _back_holster_socket: Node3D
var _hand_revolver_mount: BoneAttachment3D
var _hand_socket: Node3D
var _revolver_grip: Node3D
var _hand_muzzle: Marker3D
var _support_hand: Marker3D

var _draw_state := DrawState.HOLSTERED
var _draw_progress := 0.0
var _draw_active := false
var _gun_in_hand := false
var _holster_grip_local := Transform3D.IDENTITY
var _raise_start_poses: Dictionary = {}
var _raise_aim_target := Vector3.ZERO
var _raise_grip_local_start := Transform3D.IDENTITY
## World pose of the grip on the holster at grab. Draw raise lerps in world space
## so parent scale (BowHandMount GripOffset) cannot pop the mesh.
var _grip_xfer_holster_global := Transform3D.IDENTITY
var _grip_xfer_active := false
## AIMING→HOLSTERING: reverse-raise only (no reach-IK). Avoids overhead arcs /
## left-arm bind flashes when progress crosses the grab threshold.
var _putaway_from_aim := false
## Frozen aim pose at put-away start (high end of the reverse raise).
var _raise_end_poses: Dictionary = {}
var _bone_aim_axes: Dictionary = {}
var _aim_target := Vector3.ZERO
var _smoothed_arm_aim_target := Vector3.ZERO
var _aim_bone_poses_smoothed: Dictionary = {}
var _muzzle_offset_cached := false
var _muzzle_offset_in_hand := Vector3.ZERO
var _forearm_recoil := 0.0
## Local euler kept for replay/legacy; visual kick uses world-space pitch below.
var _forearm_recoil_rotation_deg := Vector3(-22.0, 0.0, 0.0)
## Degrees of muzzle-up kick at full `_forearm_recoil` (world-space, not bone-local).
var _forearm_recoil_pitch_deg := 22.0
var _forearm_recoil_recovery := 16.0
var _prep_aim := false
var _draw_suppressed := false
var _overworld_hold_mode := false
var _always_drawn := false
var _cover_crouch_hold := false
var _cover_crouch_peek := false
var _saddle_aim_mode := false
var _mount_aim_spine_yaw := 0.0
var _equipped_weapon_id: GroyperWeapons.Id = GroyperWeapons.get_enemy_weapon()

var _reload_phase := OverworldReloadPhase.NONE
var _reload_timer := 0.0
var _reload_load_alpha := 0.0
var _reload_raise_poses: Dictionary = {}
var _reload_aim_target := Vector3.ZERO
var _reload_cylinder_target := Vector3.ZERO
var _reload_started_from_aim := false
var _reload_aim_stance := false
## Charge level from BowController / NPC timers (0..1). Drive fire power.
var _bow_draw_alpha := 0.0
## Visual BowAim scrub (0 = hold / first frame, 1 = full drawback).
var _bow_string_hand_alpha := 0.0
var _bow_nocked_visible := false
var _bow_string_recovering := false
var _bow_string_release_hold := 0.0
var _bow_string_reverse_from := 0.0
var _bow_string_reverse_elapsed := 0.0
var _gun_arm_released_for_pose := false
## 1 → hold captured holster poses; 0 → pure AnimationTree. Softens putaway exit.
var _holster_exit_blend := 0.0
var _holster_exit_poses: Dictionary = {}

## One-handed hip-fire: HipFireAim/neutral→ads locks Spine→RightHand as the
## straight-ahead rest; RightArm aim-corrects to keep the barrel on reticle.
var _hip_fire_aim_enabled := false
var _ads_aim_blend := 0.0
## 0 idle → 1 walk/run; scales shoulder damp + ADS torso lock while 1H aiming.
var _hip_fire_move_blend := 0.0
var _hip_fire_poses: Dictionary = {}
var _hip_fire_ads_poses: Dictionary = {}
var _hip_fire_poses_cached := false

## Runtime RightArm euler offsets (degrees) from in-game O-key debug tuner.
## Applied on top of authored HipFireAim hip / ADS arm rests.
const DEBUG_ARM_OFFSET_LOCK_PATH := "res://characters/groyper/hip_fire_arm_offset_lock.cfg"
var debug_hip_arm_offset_euler_deg := Vector3.ZERO
var debug_ads_arm_offset_euler_deg := Vector3.ZERO

## Two-handed firearms: TwoHandAim/neutral→ads rests + SupportHand left-arm IK.
var _two_hand_aim_enabled := false
var _two_hand_hip_poses: Dictionary = {}
var _two_hand_ads_poses: Dictionary = {}
var _two_hand_poses_cached := false

## RecurveBow: hold poses stay locked (bow seat); string-hand poses scrub by draw.
var _bow_hold_hip_poses: Dictionary = {}
var _bow_hold_ads_poses: Dictionary = {}
var _bow_draw_hip_poses: Dictionary = {}
var _bow_draw_ads_poses: Dictionary = {}
var _bow_poses_sample_alpha := -1.0
var _bow_hold_poses_cached := false
var _bow_missing_draw_keys_warned := false


func setup(
	owner_node: Node3D,
	skeleton: Skeleton3D,
	weapon_id: GroyperWeapons.Id = GroyperWeapons.get_enemy_weapon()
) -> void:
	_owner = owner_node
	_skeleton = skeleton
	_equipped_weapon_id = weapon_id
	_setup_weapon_mounts()
	_cache_bone_aim_axes()
	_cache_hip_fire_poses()
	_cache_two_hand_poses()
	_setup_arm_aim_modifier()
	_reset_debug_arm_offsets_to_baked()
	load_debug_arm_offsets_from_disk()


func _reset_debug_arm_offsets_to_baked() -> void:
	debug_hip_arm_offset_euler_deg = HipFireAimPoseConfig.HIP_ARM_OFFSET_EULER_DEG
	debug_ads_arm_offset_euler_deg = HipFireAimPoseConfig.ADS_ARM_OFFSET_EULER_DEG


func get_debug_arm_offset_euler_deg(ads: bool) -> Vector3:
	return debug_ads_arm_offset_euler_deg if ads else debug_hip_arm_offset_euler_deg


func set_debug_arm_offset_euler_deg(ads: bool, euler_deg: Vector3) -> void:
	if ads:
		debug_ads_arm_offset_euler_deg = euler_deg
	else:
		debug_hip_arm_offset_euler_deg = euler_deg


func load_debug_arm_offsets_from_disk() -> void:
	if not FileAccess.file_exists(DEBUG_ARM_OFFSET_LOCK_PATH):
		return
	var cfg := ConfigFile.new()
	if cfg.load(DEBUG_ARM_OFFSET_LOCK_PATH) != OK:
		return
	debug_hip_arm_offset_euler_deg = Vector3(
		float(cfg.get_value("right_arm", "hip_x", debug_hip_arm_offset_euler_deg.x)),
		float(cfg.get_value("right_arm", "hip_y", debug_hip_arm_offset_euler_deg.y)),
		float(cfg.get_value("right_arm", "hip_z", debug_hip_arm_offset_euler_deg.z))
	)
	debug_ads_arm_offset_euler_deg = Vector3(
		float(cfg.get_value("right_arm", "ads_x", debug_ads_arm_offset_euler_deg.x)),
		float(cfg.get_value("right_arm", "ads_y", debug_ads_arm_offset_euler_deg.y)),
		float(cfg.get_value("right_arm", "ads_z", debug_ads_arm_offset_euler_deg.z))
	)


func lock_debug_arm_offsets() -> String:
	var cfg := ConfigFile.new()
	cfg.set_value("right_arm", "hip_x", debug_hip_arm_offset_euler_deg.x)
	cfg.set_value("right_arm", "hip_y", debug_hip_arm_offset_euler_deg.y)
	cfg.set_value("right_arm", "hip_z", debug_hip_arm_offset_euler_deg.z)
	cfg.set_value("right_arm", "ads_x", debug_ads_arm_offset_euler_deg.x)
	cfg.set_value("right_arm", "ads_y", debug_ads_arm_offset_euler_deg.y)
	cfg.set_value("right_arm", "ads_z", debug_ads_arm_offset_euler_deg.z)
	var err := cfg.save(DEBUG_ARM_OFFSET_LOCK_PATH)
	var summary := (
		"LOCKED 1H RightArm offsets → %s\n"
		+ "hip_arm_offset_euler_deg = Vector3(%.2f, %.2f, %.2f)\n"
		+ "ads_arm_offset_euler_deg = Vector3(%.2f, %.2f, %.2f)"
	) % [
		DEBUG_ARM_OFFSET_LOCK_PATH,
		debug_hip_arm_offset_euler_deg.x,
		debug_hip_arm_offset_euler_deg.y,
		debug_hip_arm_offset_euler_deg.z,
		debug_ads_arm_offset_euler_deg.x,
		debug_ads_arm_offset_euler_deg.y,
		debug_ads_arm_offset_euler_deg.z,
	]
	if err != OK:
		summary = "FAILED to save arm offsets (%s)\n%s" % [error_string(err), summary]
	return summary


## Stamp authored 1H chain + RightArm offset for the debug tuner (no elevation tip).
func apply_debug_arm_pose_preview(ads: bool) -> void:
	if _skeleton == null:
		return
	if not _hip_fire_poses_cached:
		_cache_hip_fire_poses()
	var saved_ads := _ads_aim_blend
	var saved_move := _hip_fire_move_blend
	var saved_hip := _hip_fire_aim_enabled
	_hip_fire_aim_enabled = true
	_ads_aim_blend = 1.0 if ads else 0.0
	_hip_fire_move_blend = 0.0
	_apply_hip_fire_authored_rests(HipFireAimPoseConfig.AUTHORING_BONES)
	_ads_aim_blend = saved_ads
	_hip_fire_move_blend = saved_move
	_hip_fire_aim_enabled = saved_hip


func _debug_arm_offset_quat(ads: bool) -> Quaternion:
	return HipFireAimPoseConfig.arm_offset_quat(get_debug_arm_offset_euler_deg(ads))


func set_hip_fire_aim_enabled(enabled: bool) -> void:
	if enabled != _hip_fire_aim_enabled:
		_clear_hip_fire_aim_smoothing()
	_hip_fire_aim_enabled = enabled


func set_two_hand_aim_enabled(enabled: bool) -> void:
	if _two_hand_aim_enabled and not enabled:
		_clear_two_hand_aim_smoothing()
	_two_hand_aim_enabled = enabled


func set_ads_aim_blend(blend: float) -> void:
	_ads_aim_blend = clampf(blend, 0.0, 1.0)


func set_hip_fire_move_blend(blend: float) -> void:
	_hip_fire_move_blend = clampf(blend, 0.0, 1.0)


func _uses_two_hand_arm_aim() -> bool:
	return _two_hand_aim_enabled and _gun_in_hand and not GroyperWeapons.is_bow(_equipped_weapon_id)


## Draw/holster chain follows the equipped weapon immediately (not the lagged
## player two-hand flag), so 1H↔2H swaps don't flash the support arm to bind.
func _draw_uses_two_hand_chain() -> bool:
	return (
		GroyperWeapons.is_two_handed(_equipped_weapon_id)
		and not GroyperWeapons.is_bow(_equipped_weapon_id)
	)


func _uses_bow_arm_aim() -> bool:
	return GroyperWeapons.is_bow(_equipped_weapon_id) and _gun_in_hand


func swap_equipped_weapon(weapon_id: GroyperWeapons.Id, soft_handoff: bool = false) -> void:
	if (
		weapon_id == _equipped_weapon_id
		and _revolver_grip != null
		and is_instance_valid(_revolver_grip)
	):
		return

	# Capture live arm poses BEFORE teardown — soft-swap used to reset_bone_pose
	# the left arm to bind/T-pose for a frame.
	var handoff_poses := {}
	if soft_handoff:
		handoff_poses = _capture_swap_handoff_poses()
		_clear_holster_exit_blend()
		_clear_reload_state()
		_reset_bow_draw_visual()
		_draw_state = DrawState.HOLSTERED
		_draw_progress = 0.0
		_draw_active = false
		_gun_in_hand = false
		_clear_raise_cache()
		_clear_arm_aim_smoothing()
		_set_hand_mount_visible_for_draw(false)
	else:
		reset_to_holster()

	if _revolver_grip != null and is_instance_valid(_revolver_grip):
		_revolver_grip.queue_free()
		_revolver_grip = null
	_equipped_weapon_id = weapon_id
	_resolve_hand_socket()

	var socket := _get_active_holster_socket()
	if socket:
		_revolver_grip = GroyperWeapons.install_holster_grip(
			socket,
			_equipped_weapon_id
		)
		_holster_grip_local = _revolver_grip.transform
		_apply_holster_grip_transform()
		_resolve_hand_muzzle()
		_resolve_support_hand()
		_invalidate_muzzle_cache()

	if soft_handoff and GroyperWeapons.uses_run_and_gun(_equipped_weapon_id):
		# Chain put-away → draw in the same frame so arms never drop to
		# locomotion (that one-frame release was the cycle glitch).
		begin_draw()
		if not handoff_poses.is_empty():
			_raise_start_poses = handoff_poses
			_restore_pose_dict(handoff_poses)

	draw_state_changed.emit(_draw_state)


func clear_holster_exit_blend() -> void:
	_clear_holster_exit_blend()


func get_active_holster_socket() -> Node3D:
	return _get_active_holster_socket()


func _get_active_holster_socket() -> Node3D:
	return _resolve_holster_socket(_equipped_weapon_id)


func _resolve_holster_socket(weapon_id: GroyperWeapons.Id) -> Node3D:
	if _skeleton != null:
		var mount_name := GroyperWeapons.holster_mount_name(weapon_id)
		var mount := _skeleton.get_node_or_null(NodePath(String(mount_name))) as Node3D
		if mount != null:
			var socket := mount.get_node_or_null("HolsterOffset") as Node3D
			if socket != null:
				return socket
	# Fallback to shared hip/back if a bespoke mount is missing.
	if GroyperWeapons.uses_back_holster(weapon_id):
		return _back_holster_socket
	return _hip_holster_socket


func _resolve_hand_socket(weapon_id: GroyperWeapons.Id = _equipped_weapon_id) -> Node3D:
	_hand_socket = GroyperBodyUtils.firearm_hand_socket(_skeleton, int(weapon_id))
	if _hand_socket == null and _hand_revolver_mount != null:
		var pose := _hand_revolver_mount.get_node_or_null("GripOffset/PoseOffset") as Node3D
		if pose != null:
			_hand_socket = pose
		else:
			var fallback := _hand_revolver_mount.get_node_or_null("GripOffset") as Node3D
			_hand_socket = fallback if fallback != null else _hand_revolver_mount
	return _hand_socket


func _get_active_hand_socket() -> Node3D:
	if _hand_socket != null and is_instance_valid(_hand_socket):
		return _hand_socket
	return _resolve_hand_socket()


func _set_hand_mount_visible_for_draw(drawn: bool) -> void:
	var mount := GroyperBodyUtils.firearm_hand_mount(_skeleton, int(_equipped_weapon_id))
	if mount != null:
		mount.visible = drawn


func reset_to_holster() -> void:
	_clear_reload_state()
	_reset_bow_draw_visual()
	_draw_state = DrawState.HOLSTERED
	_draw_progress = 0.0
	_draw_active = false
	_gun_in_hand = false
	_clear_raise_cache()
	_clear_arm_aim_smoothing()
	if _overworld_hold_mode or _saddle_aim_mode:
		if not _saddle_aim_mode:
			_release_arm_to_animation()
	else:
		_reset_aim_bone_poses()
	_ensure_revolver_grip()
	_set_hand_mount_visible_for_draw(false)
	var holster_socket := _get_active_holster_socket()
	if _revolver_grip != null and holster_socket != null and _revolver_grip.get_parent() != holster_socket:
		var grip_global := _revolver_grip.global_transform
		_revolver_grip.reparent(holster_socket, true)
		_revolver_grip.global_transform = grip_global
	_apply_holster_grip_transform()
	_invalidate_muzzle_cache()


func clear_weapon_visual() -> void:
	_clear_reload_state()
	_reset_bow_draw_visual()
	_draw_state = DrawState.HOLSTERED
	_draw_progress = 0.0
	_draw_active = false
	_gun_in_hand = false
	_clear_raise_cache()
	_clear_arm_aim_smoothing()
	_reset_aim_bone_poses()
	if _revolver_grip != null and is_instance_valid(_revolver_grip):
		_revolver_grip.queue_free()
		_revolver_grip = null
	_equipped_weapon_id = GroyperWeapons.get_enemy_weapon()
	_invalidate_muzzle_cache()


func has_holster_grip() -> bool:
	return _revolver_grip != null and is_instance_valid(_revolver_grip)


func on_revolver_dropped() -> void:
	_gun_in_hand = false
	_draw_active = false
	_revolver_grip = null


func begin_draw() -> void:
	if _draw_state != DrawState.HOLSTERED:
		return
	_putaway_from_aim = false
	_draw_state = DrawState.DRAWING
	_draw_progress = 0.0
	_draw_active = true


func begin_holster() -> void:
	if _draw_state == DrawState.HOLSTERED or _draw_state == DrawState.HOLSTERING:
		return
	if _draw_state == DrawState.DRAWING or _draw_state == DrawState.AIMING:
		if _draw_state == DrawState.AIMING:
			_prepare_aim_holster_putaway()
		else:
			_putaway_from_aim = false
			_prepare_mid_draw_holster_grip()
		_draw_state = DrawState.HOLSTERING
		_draw_active = true


func is_aiming() -> bool:
	return _draw_state == DrawState.AIMING


func get_draw_progress() -> float:
	return _draw_progress


func is_drawing() -> bool:
	return (
		_draw_state == DrawState.DRAWING
		or _draw_state == DrawState.AIMING
		or _draw_state == DrawState.HOLSTERING
	)


func is_holstered() -> bool:
	return _draw_state == DrawState.HOLSTERED


func is_holster_exit_blending() -> bool:
	return _holster_exit_blend > 0.001


func get_draw_state() -> DrawState:
	return _draw_state


func get_equipped_weapon_id() -> GroyperWeapons.Id:
	return _equipped_weapon_id


func can_fire() -> bool:
	return _draw_state == DrawState.AIMING and _reload_phase == OverworldReloadPhase.NONE


func can_use_reticle() -> bool:
	if _reload_phase != OverworldReloadPhase.NONE and _reload_aim_stance:
		return true
	return _draw_state == DrawState.AIMING and _reload_phase == OverworldReloadPhase.NONE


func is_overworld_reloading() -> bool:
	return _reload_phase != OverworldReloadPhase.NONE


func can_begin_overworld_reload() -> bool:
	if GroyperWeapons.is_lasso(_equipped_weapon_id) or GroyperWeapons.is_bow(_equipped_weapon_id) \
			or GroyperWeapons.is_shovel(_equipped_weapon_id):
		return false
	return (
		(_overworld_hold_mode or _saddle_aim_mode)
		and (
			_draw_state == DrawState.HOLSTERED
			or _draw_state == DrawState.AIMING
		)
		and _reload_phase == OverworldReloadPhase.NONE
	)


func did_overworld_reload_start_from_aim() -> bool:
	return _reload_started_from_aim


func set_overworld_reload_aim_stance(active: bool) -> void:
	_reload_aim_stance = active
	if active and _gun_in_hand:
		_draw_state = DrawState.AIMING
		_draw_progress = 1.0


func begin_overworld_reload_eject() -> void:
	if not can_begin_overworld_reload():
		return

	_reload_started_from_aim = _draw_state == DrawState.AIMING
	_reload_aim_stance = _reload_started_from_aim

	if not _gun_in_hand:
		_attach_gun_to_hand()
	elif _reload_started_from_aim:
		_snap_gun_grip_to_hand()

	_capture_reload_rest_poses()
	if _equipped_weapon_id == GroyperWeapons.Id.REVOLVER and _owner != null:
		var spin_pos := get_muzzle_global_position()
		GameAudio.play_revolver_eject_spin(_owner, spin_pos)
	_spawn_shell_casings()
	_reload_phase = OverworldReloadPhase.TAP_READY
	_reload_timer = 0.0
	_reload_load_alpha = 0.0


func try_overworld_reload_tap() -> bool:
	if _reload_phase != OverworldReloadPhase.TAP_READY:
		return false
	if _reload_load_alpha > 0.001:
		return false

	_reload_phase = OverworldReloadPhase.LOADING
	_reload_timer = 0.0
	_reload_load_alpha = 0.0
	return true


func finish_overworld_reload_holster() -> void:
	finish_overworld_reload(false)


func finish_overworld_reload(return_to_aim: bool) -> void:
	if _reload_phase == OverworldReloadPhase.NONE:
		return

	if return_to_aim and _gun_in_hand:
		_clear_reload_state()
		_draw_state = DrawState.AIMING
		_draw_progress = 1.0
		_snap_gun_grip_to_hand()
		_seed_arm_aim_smoothing()
		draw_state_changed.emit(_draw_state)
		return

	_reload_phase = OverworldReloadPhase.HOLSTERING
	_reload_timer = 0.0
	_reload_aim_stance = false


func cancel_overworld_reload_for_aim() -> void:
	if _reload_phase == OverworldReloadPhase.NONE:
		return
	_clear_reload_state()
	if not _gun_in_hand:
		return
	_draw_state = DrawState.AIMING
	_draw_progress = 1.0
	_snap_gun_grip_to_hand()
	_clear_raise_cache()
	_seed_arm_aim_smoothing()
	draw_state_changed.emit(_draw_state)


func get_overworld_reload_phase() -> OverworldReloadPhase:
	return _reload_phase


func notify_overworld_reload_eject_complete() -> void:
	_reload_phase = OverworldReloadPhase.TAP_READY
	_reload_timer = 0.0


func notify_overworld_reload_round_complete() -> void:
	_reload_phase = OverworldReloadPhase.TAP_READY
	_reload_timer = 0.0
	_reload_load_alpha = 0.0


func update_overworld_reload(delta: float) -> void:
	if _reload_phase == OverworldReloadPhase.NONE:
		return

	match _reload_phase:
		OverworldReloadPhase.RAISING:
			_reload_timer += delta
			if _reload_timer >= RELOAD_RAISE_DURATION:
				_begin_reload_eject()

		OverworldReloadPhase.EJECTING:
			_reload_timer += delta
			if _reload_timer >= RELOAD_EJECT_DURATION:
				_reload_phase = OverworldReloadPhase.TAP_READY
				_reload_timer = 0.0

		OverworldReloadPhase.LOADING:
			_reload_timer += delta
			_reload_load_alpha = clampf(_reload_timer / RELOAD_LOAD_SWING_DURATION, 0.0, 1.0)
			if _reload_timer >= RELOAD_LOAD_SWING_DURATION:
				_reload_phase = OverworldReloadPhase.TAP_READY
				_reload_timer = 0.0
				_reload_load_alpha = 0.0

		OverworldReloadPhase.HOLSTERING:
			_reload_timer += delta
			var alpha := 1.0 - clampf(_reload_timer / RELOAD_HOLSTER_DURATION, 0.0, 1.0)
			if _gun_in_hand and alpha < draw_grab_threshold:
				_detach_gun_to_holster()
			if _reload_timer >= RELOAD_HOLSTER_DURATION:
				_finish_overworld_reload()


func enable_overworld_hold_mode(enabled: bool) -> void:
	_overworld_hold_mode = enabled


func set_cover_crouch_hold(active: bool) -> void:
	_cover_crouch_hold = active
	if active:
		_cover_crouch_peek = false
		reset_to_holster()


func set_cover_crouch_peek(active: bool) -> void:
	if _cover_crouch_peek == active:
		return
	_cover_crouch_peek = active
	if not active:
		reset_to_holster()


func set_saddle_aim_mode(active: bool) -> void:
	_saddle_aim_mode = active
	if not active:
		_mount_aim_spine_yaw = 0.0


func is_saddle_aim_mode() -> bool:
	return _saddle_aim_mode


func set_mount_aim_spine_yaw(yaw: float) -> void:
	_mount_aim_spine_yaw = yaw


func release_arms_for_locomotion() -> void:
	if _overworld_hold_mode and not _saddle_aim_mode:
		_release_arm_to_animation()


func update(delta: float, aim_world_target: Vector3) -> void:
	if _skeleton == null:
		return

	_aim_target = aim_world_target
	_update_forearm_recoil(delta)
	update_overworld_reload(delta)
	if _overworld_hold_mode and _reload_phase == OverworldReloadPhase.NONE:
		var allow_cover_draw := not _cover_crouch_hold or _cover_crouch_peek
		if allow_cover_draw:
			var wants_drawn := (
				(Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or _always_drawn)
				and not _draw_suppressed
			)
			_update_overworld_draw(wants_drawn, delta)
	elif not _overworld_hold_mode:
		_update_draw(delta)


## While true, right-click never draws/aims the gun (Unarmed stance uses RMB
## for blocking instead).
func set_draw_suppressed(value: bool) -> void:
	_draw_suppressed = value


## Run-and-gun mode: the gun stays drawn without holding RMB. The player pushes
## this every frame (true for equipped firearms outside rolls/vaults/climbs) so
## the rig auto-draws to AIMING and only holsters when the flag drops.
func set_always_drawn(active: bool) -> void:
	_always_drawn = active


func set_prep_aim(active: bool) -> void:
	_prep_aim = active


## Let animation own the holstered gun arm (unarmed block / punch poses).
func set_gun_arm_released_for_pose(active: bool) -> void:
	if _gun_arm_released_for_pose == active:
		return
	_gun_arm_released_for_pose = active
	if active:
		_release_gun_arm_to_animation()


func set_bow_draw(alpha: float) -> void:
	var next := clampf(alpha, 0.0, 1.0)
	var was := _bow_draw_alpha
	_bow_draw_alpha = next
	if next > 0.001:
		# Charging — scrub BowAim forward (t=0 hold → t=1 full drawback).
		_bow_string_recovering = false
		_bow_string_release_hold = 0.0
		_bow_string_reverse_from = 0.0
		_bow_string_reverse_elapsed = 0.0
		_bow_string_hand_alpha = next
		_bow_nocked_visible = true
	elif was > 0.001 or _bow_string_hand_alpha > 0.001:
		# Released / cancelled: hide nocked arrow, pause at draw peak, reverse to hold.
		_bow_nocked_visible = false
		if not _bow_string_recovering:
			_begin_bow_string_reverse()
	else:
		_bow_nocked_visible = false
	_update_bow_nocked_arrow()


func get_bow_draw_alpha() -> float:
	# Threat / "raised" reads the visual scrub (includes post-release pause/reverse).
	return maxf(_bow_draw_alpha, _bow_string_hand_alpha)


func _begin_bow_string_reverse() -> void:
	# Freeze scrub at the peak of the pull (end of the drawback for this shot).
	_bow_string_recovering = true
	_bow_string_release_hold = BOW_STRING_RELEASE_HOLD
	_bow_string_reverse_from = maxf(_bow_string_hand_alpha, 0.001)
	_bow_string_reverse_elapsed = 0.0


func _reset_bow_draw_visual() -> void:
	_bow_draw_alpha = 0.0
	_bow_string_hand_alpha = 0.0
	_bow_nocked_visible = false
	_bow_string_recovering = false
	_bow_string_release_hold = 0.0
	_bow_string_reverse_from = 0.0
	_bow_string_reverse_elapsed = 0.0
	_bow_poses_sample_alpha = -1.0
	_bow_hold_poses_cached = false
	_bow_hold_hip_poses.clear()
	_bow_hold_ads_poses.clear()
	_bow_draw_hip_poses.clear()
	_bow_draw_ads_poses.clear()
	_update_bow_nocked_arrow()


func _tick_bow_string_hand(delta: float) -> void:
	if not GroyperWeapons.is_bow(_equipped_weapon_id):
		return
	if not _bow_string_recovering:
		return
	# Pause at the end of the drawback before reversing.
	if _bow_string_release_hold > 0.0:
		_bow_string_release_hold = maxf(_bow_string_release_hold - delta, 0.0)
		_bow_string_hand_alpha = _bow_string_reverse_from
		return
	# Linear reverse scrub back to the hold pose (first frame).
	_bow_string_reverse_elapsed += delta
	var t := clampf(
		_bow_string_reverse_elapsed / maxf(BOW_STRING_REVERSE_DURATION, 0.001),
		0.0,
		1.0
	)
	# Smoothstep so the reverse eases in/out like a tween.
	var eased := t * t * (3.0 - 2.0 * t)
	_bow_string_hand_alpha = lerpf(_bow_string_reverse_from, 0.0, eased)
	if t >= 1.0:
		_bow_string_hand_alpha = 0.0
		_bow_string_recovering = false
		_bow_string_reverse_from = 0.0
		_bow_string_reverse_elapsed = 0.0
	_update_bow_nocked_arrow()


func get_bow_fire_origin() -> Vector3:
	return get_muzzle_global_position()


func get_bow_string_release_position() -> Vector3:
	if _revolver_grip != null:
		var string_marker := _revolver_grip.get_node_or_null("StringGrip") as Node3D
		if string_marker != null:
			return string_marker.global_position
	return get_bow_fire_origin()


func get_aim_target() -> Vector3:
	return _aim_target


func apply_pose_overrides(delta: float) -> void:
	if _skeleton == null or _is_defeat_ragdoll_active():
		return

	if _reload_phase != OverworldReloadPhase.NONE:
		_apply_overworld_reload_pose(delta)
		return

	# Unarmed block/punch poses own the gun arm. Do not reset bones here — the
	# modifier runs after AnimationTree and reset_bone_pose would wipe the pose.
	if _gun_arm_released_for_pose:
		_clear_holster_exit_blend()
		return

	# Overworld / saddle: leave the right arm alone while holstered so animation can drive it.
	if (_overworld_hold_mode or _saddle_aim_mode) and _draw_state == DrawState.HOLSTERED:
		_apply_holster_exit_blend(delta)
		return

	if _saddle_aim_mode and _draw_state != DrawState.HOLSTERED:
		_apply_mount_spine_twist()

	_tick_bow_string_hand(delta)

	match _draw_state:
		DrawState.AIMING:
			_clear_holster_exit_blend()
			_apply_arm_aim(_aim_target, delta)
			# 1H: do NOT touch the free arm. reset_bone_pose here runs after
			# AnimationTree and forces bind/T-pose for a frame (or every frame).
		DrawState.DRAWING, DrawState.HOLSTERING:
			_clear_holster_exit_blend()
			_apply_draw_pose(_draw_progress)
		DrawState.HOLSTERED:
			if _prep_aim:
				_clear_holster_exit_blend()
				_apply_arm_aim(_aim_target, delta)
			else:
				_reset_aim_bone_poses()


func fire_at(target: Vector3) -> void:
	if _draw_state != DrawState.AIMING:
		return

	if GroyperWeapons.is_bow(_equipped_weapon_id):
		_fire_bow_arrow_at(target)
		return

	var origin := get_muzzle_global_position()
	var to_target := target - origin
	if to_target.length_squared() < 0.0001:
		return

	var direction := to_target.normalized()
	var scene_root := _owner.get_tree().current_scene
	if scene_root == null:
		return

	if GroyperWeapons.get_pellet_count(_equipped_weapon_id) > 1:
		_fire_shotgun_at(scene_root, origin, direction, -1.0)
		return

	var bullet: Node3D = BULLET_SCENE.instantiate()
	scene_root.add_child(bullet)
	var exclude: Array = [_owner]
	var hitbox := _owner.get_node_or_null("Hitbox")
	if hitbox is CollisionObject3D:
		exclude.append(hitbox)
	bullet.setup(origin, direction, exclude, _owner)
	SHOT_BEAM.spawn(scene_root, origin, origin + direction * 1.2)
	MuzzleFlashFXScript.spawn(
		scene_root,
		origin,
		GroyperWeapons.get_muzzle_flash_style(_equipped_weapon_id),
		-1.0,
		true
	)
	GameAudio.play_weapon_shot(_equipped_weapon_id, scene_root, origin)
	_begin_forearm_recoil()


## Overworld shotgun blast. `bloom_deg` widens the cone after recent shots
## (pass -1 to use the weapon's base pellet spread only).
func fire_shotgun_at(target: Vector3, bloom_deg: float = -1.0) -> void:
	if _draw_state != DrawState.AIMING:
		return
	var origin := get_muzzle_global_position()
	var to_target := target - origin
	if to_target.length_squared() < 0.0001:
		return
	var scene_root := _owner.get_tree().current_scene
	if scene_root == null:
		return
	_fire_shotgun_at(scene_root, origin, to_target.normalized(), bloom_deg)


func _fire_shotgun_at(
	scene_root: Node,
	origin: Vector3,
	base_direction: Vector3,
	bloom_deg: float
) -> void:
	var pellet_count := GroyperWeapons.get_pellet_count(_equipped_weapon_id)
	var spread_deg := GroyperWeapons.get_pellet_spread_max_deg(_equipped_weapon_id)
	if bloom_deg > 0.0:
		spread_deg = maxf(spread_deg, bloom_deg)
	var max_range := GroyperWeapons.get_pellet_max_range(_equipped_weapon_id)
	var chip := GroyperWeapons.get_pellet_chip_damage(_equipped_weapon_id)
	var offsets := GroyperWeapons.get_shotgun_pellet_offsets(base_direction, pellet_count)

	var exclude: Array = [_owner]
	var hitbox := _owner.get_node_or_null("Hitbox")
	if hitbox is CollisionObject3D:
		exclude.append(hitbox)

	for offset: Vector3 in offsets:
		var pellet: Node3D = SHOTGUN_PELLET_SCENE.instantiate()
		scene_root.add_child(pellet)
		pellet.setup(
			origin,
			base_direction,
			offset,
			spread_deg,
			0.0,
			exclude,
			_owner,
			int(_equipped_weapon_id),
			max_range,
			chip
		)

	SHOT_BEAM.spawn(scene_root, origin, origin + base_direction * 1.6)
	MuzzleFlashFXScript.spawn(
		scene_root,
		origin,
		GroyperWeapons.get_muzzle_flash_style(_equipped_weapon_id),
		-1.0,
		true,
		Color(0, 0, 0, 0),
		base_direction
	)
	GameAudio.play_weapon_shot(_equipped_weapon_id, scene_root, origin)
	_begin_forearm_recoil()


func _fire_bow_arrow_at(target: Vector3) -> void:
	var origin := get_bow_string_release_position()
	var to_target := target - origin
	if to_target.length_squared() < 0.0001:
		return

	var direction := to_target.normalized()
	var charge_alpha := clampf(_bow_draw_alpha, 0.0, 1.0)
	set_bow_draw(0.0)

	var scene_root := _owner.get_tree().current_scene
	if scene_root == null:
		return

	var exclude: Array = [_owner]
	var hitbox := _owner.get_node_or_null("Hitbox")
	if hitbox is CollisionObject3D:
		exclude.append(hitbox)

	var power := charge_alpha * charge_alpha
	var speed := lerpf(BOW_MIN_SPEED, BOW_MAX_SPEED, power)
	var arrow: Node3D = ARROW_SCENE.instantiate()
	scene_root.add_child(arrow)
	arrow.setup(origin, direction, speed, exclude, _owner)
	GameAudio.play_bow_release(scene_root, origin)


func capture_replay_state() -> Dictionary:
	return {
		"draw_state": _draw_state,
		"draw_progress": _draw_progress,
		"gun_in_hand": _gun_in_hand,
		"draw_active": _draw_active,
		"aim_target": _aim_target,
		"forearm_recoil": _forearm_recoil,
	}


func apply_replay_state(state: Dictionary) -> void:
	if state.is_empty():
		return

	_draw_state = state.get("draw_state", DrawState.HOLSTERED)
	_draw_progress = state.get("draw_progress", 0.0)
	_gun_in_hand = state.get("gun_in_hand", false)
	_draw_active = state.get("draw_active", false)
	_aim_target = state.get("aim_target", _aim_target)
	_forearm_recoil = state.get("forearm_recoil", 0.0)

	_sync_replay_weapon_mount()
	_ensure_replay_draw_cache()
	apply_pose_overrides(1.0)


func _sync_replay_weapon_mount() -> void:
	var hand_socket := _get_active_hand_socket()
	if _gun_in_hand and _revolver_grip != null and hand_socket != null \
			and _revolver_grip.get_parent() != hand_socket:
		GroyperBodyUtils.clear_firearm_hand_preview_grip(hand_socket, _revolver_grip)
		var grip_global := _revolver_grip.global_transform
		_revolver_grip.reparent(hand_socket, true)
		_revolver_grip.global_transform = grip_global
		_set_hand_mount_visible_for_draw(true)
		_invalidate_muzzle_cache()
	elif not _gun_in_hand and _revolver_grip != null:
		_set_hand_mount_visible_for_draw(false)
		var holster_socket := _get_active_holster_socket()
		if holster_socket != null and _revolver_grip.get_parent() != holster_socket:
			var holster_global := _revolver_grip.global_transform
			_revolver_grip.reparent(holster_socket, true)
			_revolver_grip.global_transform = holster_global
			_apply_holster_grip_transform()
			_invalidate_muzzle_cache()


func _ensure_replay_draw_cache() -> void:
	if _draw_state != DrawState.DRAWING or _draw_progress < draw_grab_threshold:
		return
	if not _raise_start_poses.is_empty():
		return
	if not _gun_in_hand:
		var hand_socket := _get_active_hand_socket()
		if _revolver_grip == null or hand_socket == null:
			return
		var holster_target := _get_holster_reach_target()
		var grip_global := _revolver_grip.global_transform
		_cache_raise_start_poses(holster_target)
		GroyperBodyUtils.clear_firearm_hand_preview_grip(hand_socket, _revolver_grip)
		_revolver_grip.reparent(hand_socket, true)
		_revolver_grip.global_transform = grip_global
		_raise_grip_local_start = _revolver_grip.transform
		_grip_xfer_holster_global = grip_global
		_grip_xfer_active = true
		_gun_in_hand = true
		_set_hand_mount_visible_for_draw(true)
		_invalidate_muzzle_cache()
		_resolve_hand_muzzle()
	else:
		_cache_raise_start_poses(_get_holster_reach_target())
		_raise_grip_local_start = _revolver_grip.transform if _revolver_grip else Transform3D.IDENTITY
		var holster_socket := _get_active_holster_socket()
		if holster_socket != null:
			_grip_xfer_holster_global = holster_socket.global_transform * _holster_grip_local
			_grip_xfer_active = true
	_raise_aim_target = _aim_target


func get_muzzle_global_position() -> Vector3:
	_resolve_hand_muzzle()
	if _hand_muzzle != null and is_instance_valid(_hand_muzzle):
		return _hand_muzzle.global_position

	if _skeleton == null:
		return _owner.global_position

	return _owner.global_position


func _setup_weapon_mounts() -> void:
	GroyperBodyUtils.ensure_weapon_mounts(_skeleton)
	_hip_holster_mount = _skeleton.get_node_or_null("HipHolsterMount") as BoneAttachment3D
	_hip_holster_socket = _hip_holster_mount.get_node_or_null("HolsterOffset") as Node3D if _hip_holster_mount else null
	_back_holster_mount = _skeleton.get_node_or_null("BackHolsterMount") as BoneAttachment3D
	_back_holster_socket = _back_holster_mount.get_node_or_null("HolsterOffset") as Node3D if _back_holster_mount else null
	_hand_revolver_mount = _skeleton.get_node_or_null("HandRevolverMount") as BoneAttachment3D
	_resolve_hand_socket()

	var socket := _get_active_holster_socket()
	if socket:
		_revolver_grip = GroyperWeapons.install_holster_grip(
			socket,
			_equipped_weapon_id
		)

	if _revolver_grip == null or _get_active_hand_socket() == null:
		push_error("GroyperWeaponRig: missing weapon mounts.")
		return

	_holster_grip_local = _revolver_grip.transform
	_apply_holster_grip_transform()
	_resolve_hand_muzzle()


func _ensure_revolver_grip() -> void:
	if _revolver_grip != null and is_instance_valid(_revolver_grip):
		return
	if _skeleton != null:
		GroyperBodyUtils.ensure_firearm_holster_mounts(_skeleton)
		GroyperBodyUtils.ensure_firearm_hand_mounts(_skeleton)
	if _hip_holster_socket == null and _skeleton != null:
		_hip_holster_mount = _skeleton.get_node_or_null("HipHolsterMount") as BoneAttachment3D
		_hip_holster_socket = _hip_holster_mount.get_node_or_null("HolsterOffset") as Node3D if _hip_holster_mount else null
	if _back_holster_socket == null and _skeleton != null:
		_back_holster_mount = _skeleton.get_node_or_null("BackHolsterMount") as BoneAttachment3D
		_back_holster_socket = _back_holster_mount.get_node_or_null("HolsterOffset") as Node3D if _back_holster_mount else null
	var socket := _get_active_holster_socket()
	if socket != null:
		_revolver_grip = socket.get_node_or_null("RevolverGrip") as Node3D


func _setup_arm_aim_modifier() -> void:
	if _skeleton == null:
		return
	var existing := _skeleton.get_node_or_null("ArmAimModifier")
	if existing != null:
		existing.queue_free()
	var modifier = ARM_AIM_MODIFIER_SCRIPT.new()
	modifier.name = "ArmAimModifier"
	modifier.apply_overrides = apply_pose_overrides
	_skeleton.add_child(modifier)


func _is_defeat_ragdoll_active() -> bool:
	if _owner == null:
		return false
	for child in _owner.get_children():
		if child is GroyperRagdoll and child.is_active():
			return true
	return false


func _resolve_hand_muzzle() -> void:
	if _revolver_grip:
		_hand_muzzle = _revolver_grip.find_child("Muzzle", true, false) as Marker3D


func _resolve_support_hand() -> Marker3D:
	_support_hand = null
	if _revolver_grip != null and is_instance_valid(_revolver_grip):
		_support_hand = _revolver_grip.find_child(
			String(TwoHandAimPoseConfig.SUPPORT_HAND_MARKER),
			true,
			false
		) as Marker3D
	return _support_hand


func _get_support_hand_world_target() -> Vector3:
	_resolve_support_hand()
	if _support_hand != null and is_instance_valid(_support_hand):
		return _support_hand.global_position
	# No marker: keep authored left rest (do not IK toward the reticle — that
	# yanks the support arm overhead when the grip has no SupportHand).
	return Vector3.ZERO


func _cache_muzzle_hand_offset() -> void:
	_resolve_hand_muzzle()
	var hand_id := _skeleton.find_bone(HAND_BONE)
	if hand_id < 0 or _hand_muzzle == null:
		return

	var hand_global := _skeleton.global_transform * _skeleton.get_bone_global_pose(hand_id)
	_muzzle_offset_in_hand = hand_global.basis.inverse() * (_hand_muzzle.global_position - hand_global.origin)
	_muzzle_offset_cached = true


func _invalidate_muzzle_cache() -> void:
	_muzzle_offset_cached = false


func _snap_gun_grip_to_hand() -> void:
	if _gun_in_hand and _revolver_grip != null:
		_revolver_grip.transform = _get_hand_grip_local()
		_invalidate_muzzle_cache()


func _update_draw(delta: float) -> void:
	if not _draw_active:
		return

	var previous_state := _draw_state

	match _draw_state:
		DrawState.DRAWING:
			_draw_progress = minf(_draw_progress + delta / draw_duration, 1.0)
			if not _gun_in_hand and _draw_progress >= draw_grab_threshold:
				_attach_gun_to_hand()
			if _draw_progress >= 1.0:
				_draw_state = DrawState.AIMING
				_snap_gun_grip_to_hand()
				_clear_raise_cache()
				_seed_arm_aim_smoothing()
		DrawState.AIMING:
			pass
		DrawState.HOLSTERING:
			_draw_progress = maxf(_draw_progress - delta / holster_duration, 0.0)
			if _gun_in_hand and _draw_progress < draw_grab_threshold:
				_detach_gun_to_holster()
			if _draw_progress <= 0.0:
				_draw_state = DrawState.HOLSTERED
				_draw_progress = 0.0
				_draw_active = false
				_clear_raise_cache()
				_clear_arm_aim_smoothing()

	if previous_state != _draw_state:
		if _draw_state == DrawState.HOLSTERING:
			if previous_state == DrawState.DRAWING:
				_putaway_from_aim = false
				_prepare_mid_draw_holster_grip()
			elif previous_state == DrawState.AIMING:
				_prepare_aim_holster_putaway()
		if _draw_state == DrawState.AIMING and previous_state != DrawState.AIMING:
			_play_aim_enter_sound()


func _update_overworld_draw(rmb_held: bool, delta: float) -> void:
	var previous_state := _draw_state

	match _draw_state:
		DrawState.HOLSTERED:
			if rmb_held:
				_draw_state = DrawState.DRAWING
				_draw_progress = 0.0

		DrawState.DRAWING:
			if rmb_held:
				_draw_progress = minf(_draw_progress + delta / draw_duration, 1.0)
				if not _gun_in_hand and _draw_progress >= draw_grab_threshold:
					_attach_gun_to_hand()
				if _draw_progress >= 1.0:
					_draw_state = DrawState.AIMING
					_snap_gun_grip_to_hand()
					_clear_raise_cache()
					_seed_arm_aim_smoothing()
			else:
				_draw_state = DrawState.HOLSTERING

		DrawState.AIMING:
			if not rmb_held:
				_draw_state = DrawState.HOLSTERING

		DrawState.HOLSTERING:
			_draw_progress = maxf(_draw_progress - delta / holster_duration, 0.0)
			if _gun_in_hand and _draw_progress < draw_grab_threshold:
				_detach_gun_to_holster()
			if _draw_progress <= 0.0:
				_draw_state = DrawState.HOLSTERED
				_draw_progress = 0.0
				_clear_raise_cache()
				_clear_arm_aim_smoothing()

	if previous_state != _draw_state:
		if _draw_state == DrawState.HOLSTERING:
			if previous_state == DrawState.DRAWING:
				_putaway_from_aim = false
				_prepare_mid_draw_holster_grip()
			elif previous_state == DrawState.AIMING:
				_prepare_aim_holster_putaway()
		if (
			_saddle_aim_mode
			and previous_state == DrawState.HOLSTERED
			and _draw_state != DrawState.HOLSTERED
		):
			_clear_holster_exit_blend()
			_release_arm_to_animation()
		elif _overworld_hold_mode and not _saddle_aim_mode and _draw_state == DrawState.HOLSTERED:
			# Soft handoff into locomotion — hard reset_bone_pose snaps the gun arm.
			_begin_holster_exit_blend()
		if _draw_state == DrawState.AIMING and previous_state != DrawState.AIMING:
			_play_aim_enter_sound()
		draw_state_changed.emit(_draw_state)


func _play_aim_enter_sound() -> void:
	if _owner == null or GroyperWeapons.is_lasso(_equipped_weapon_id):
		return
	if GroyperWeapons.is_bow(_equipped_weapon_id):
		return
	GameAudio.play_revolver_aim(_owner, get_muzzle_global_position())


func _detach_gun_to_holster() -> void:
	if not _gun_in_hand or _revolver_grip == null:
		return
	var holster_socket := _get_active_holster_socket()
	if holster_socket == null:
		return

	var grip_global := _revolver_grip.global_transform
	_revolver_grip.reparent(holster_socket, true)
	_revolver_grip.global_transform = grip_global
	_apply_holster_grip_transform()
	_gun_in_hand = false
	_set_hand_mount_visible_for_draw(false)
	if _putaway_from_aim:
		# Keep reverse-raise seeds so we never fall into reach-IK mid-putaway.
		_grip_xfer_active = false
	else:
		_clear_raise_cache()
	_invalidate_muzzle_cache()


func _attach_gun_to_hand() -> void:
	var hand_socket := _get_active_hand_socket()
	if _gun_in_hand or _revolver_grip == null or hand_socket == null:
		return

	var holster_target := _get_holster_reach_target()
	var grip_global := _revolver_grip.global_transform
	_cache_raise_start_poses(holster_target)

	GroyperBodyUtils.clear_firearm_hand_preview_grip(hand_socket, _revolver_grip)
	_revolver_grip.reparent(hand_socket, true)
	_revolver_grip.global_transform = grip_global
	_raise_grip_local_start = _revolver_grip.transform
	# Fixed holster-side world pose for the raise lerp (scale-safe).
	_grip_xfer_holster_global = grip_global
	_grip_xfer_active = true
	_gun_in_hand = true
	_set_hand_mount_visible_for_draw(true)
	_invalidate_muzzle_cache()
	_resolve_hand_muzzle()
	_resolve_support_hand()
	_raise_aim_target = _aim_target


func _prepare_mid_draw_holster_grip() -> void:
	## Cancelling mid-DRAW (raise poses already cached): keep world grip xfer.
	if not _gun_in_hand or _revolver_grip == null or _raise_start_poses.is_empty():
		return
	var holster_socket := _get_active_holster_socket()
	if holster_socket != null:
		_grip_xfer_holster_global = holster_socket.global_transform * _holster_grip_local
	_grip_xfer_active = true


func _should_animate_back_holster_putaway() -> bool:
	## Back-slung 2H / bow need an animated return. 1H hip keeps the old put-away.
	return (
		GroyperWeapons.uses_back_holster(_equipped_weapon_id)
		or GroyperWeapons.is_two_handed(_equipped_weapon_id)
		or GroyperWeapons.is_bow(_equipped_weapon_id)
	)


func _prepare_aim_holster_putaway() -> void:
	## From AIMING: seed reverse of the draw. 1H uses the same raise/reach path
	## as draw (progress 1→0). 2H/bow keep a frozen calm return (no overhead).
	if not _gun_in_hand or _revolver_grip == null:
		return
	_raise_aim_target = _aim_target
	_raise_grip_local_start = _revolver_grip.transform
	var holster_socket := _get_active_holster_socket()
	if holster_socket != null:
		_grip_xfer_holster_global = holster_socket.global_transform * _holster_grip_local
	else:
		_grip_xfer_holster_global = _revolver_grip.global_transform
	_grip_xfer_active = true

	if _should_animate_back_holster_putaway():
		_putaway_from_aim = true
		_raise_end_poses = _capture_swap_handoff_poses()
		_raise_start_poses = _get_calm_back_putaway_start(_raise_end_poses)
	else:
		# 1H: identical to a finished draw grab cache — holster just plays it back.
		_putaway_from_aim = false
		_raise_end_poses.clear()
		_raise_start_poses = _compute_raise_start_poses_preserved(_get_holster_reach_target())


func _get_calm_back_putaway_start(end_poses: Dictionary) -> Dictionary:
	## Ease toward a low back-holster reach without the abducted overhead arc.
	var saved_abduct := holster_reach_abduct_deg
	holster_reach_abduct_deg = minf(holster_reach_abduct_deg, 4.0)
	var reach_poses := _compute_raise_start_poses_preserved(_get_holster_reach_target())
	holster_reach_abduct_deg = saved_abduct
	var poses := end_poses.duplicate()
	for bone_name: String in AIM_BONES:
		if reach_poses.has(bone_name):
			poses[bone_name] = reach_poses[bone_name]
	if reach_poses.has(SHOULDER_BONE):
		poses[SHOULDER_BONE] = reach_poses[SHOULDER_BONE]
	# Support arm eases from aim toward its live pose (not bind).
	for bone_name: String in [LEFT_SHOULDER_BONE, LEFT_ARM_BONE, LEFT_FOREARM_BONE, LEFT_HAND_BONE]:
		if end_poses.has(bone_name):
			poses[bone_name] = end_poses[bone_name]
	return poses


func _capture_swap_handoff_poses() -> Dictionary:
	var poses := {}
	if _skeleton == null:
		return poses
	var bones: Array = AIM_BONES.duplicate()
	bones.append(SHOULDER_BONE)
	for bone_name: String in LEFT_AIM_BONES:
		bones.append(bone_name)
	bones.append(LEFT_SHOULDER_BONE)
	for bone_name: String in bones:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id >= 0:
			poses[bone_name] = _skeleton.get_bone_pose_rotation(bone_id)
	return poses


func _restore_pose_dict(poses: Dictionary) -> void:
	if _skeleton == null:
		return
	for bone_name: Variant in poses.keys():
		var bone_id := _skeleton.find_bone(String(bone_name))
		if bone_id >= 0:
			_skeleton.set_bone_pose_rotation(bone_id, poses[bone_name])


func _apply_frozen_putaway_pose(alpha: float) -> void:
	if _raise_start_poses.is_empty() or _raise_end_poses.is_empty():
		return
	var eased := alpha * alpha * (3.0 - 2.0 * alpha)
	var bone_names: Dictionary = {}
	for bone_name: Variant in _raise_start_poses.keys():
		bone_names[bone_name] = true
	for bone_name: Variant in _raise_end_poses.keys():
		bone_names[bone_name] = true
	for bone_name: Variant in bone_names.keys():
		var name_str := String(bone_name)
		var bone_id := _skeleton.find_bone(name_str)
		if bone_id < 0:
			continue
		var current := _skeleton.get_bone_pose_rotation(bone_id)
		var from_q: Quaternion = _raise_start_poses.get(name_str, current)
		var to_q: Quaternion = _raise_end_poses.get(name_str, current)
		_skeleton.set_bone_pose_rotation(bone_id, _slerp_quat_short(from_q, to_q, eased))
	if _gun_in_hand:
		_apply_gun_grip_raise(eased)


func _apply_draw_pose(progress: float) -> void:
	var clamped := clampf(progress, 0.0, 1.0)
	# 2H/bow aim put-away only — 1H holsters through the normal draw pose path
	# in reverse (do not add a custom 1H lower tween).
	if _putaway_from_aim and _draw_state == DrawState.HOLSTERING:
		var putaway_alpha := clamped * clamped * (3.0 - 2.0 * clamped)
		_apply_frozen_putaway_pose(putaway_alpha)
		return
	if clamped < draw_grab_threshold:
		var reach_alpha := clamped / draw_grab_threshold
		reach_alpha = reach_alpha * reach_alpha * (3.0 - 2.0 * reach_alpha)
		if GroyperWeapons.is_bow(_equipped_weapon_id):
			_apply_bow_reach_toward_holster(reach_alpha)
		else:
			_apply_reach_toward_holster(reach_alpha)
			_apply_support_arm_during_reach(reach_alpha)
	else:
		var raise_alpha := inverse_lerp(draw_grab_threshold, 1.0, clamped)
		raise_alpha = raise_alpha * raise_alpha * (3.0 - 2.0 * raise_alpha)
		_apply_raise_pose(raise_alpha)


func _get_holster_reach_target() -> Vector3:
	if _revolver_grip == null:
		return _owner.global_position
	return _revolver_grip.global_position + _revolver_grip.global_transform.basis * holster_reach_offset


func _apply_reach_toward_holster(alpha: float) -> void:
	_apply_reach_toward_target(alpha, _get_holster_reach_target())


func _apply_reach_toward_target(alpha: float, target: Vector3) -> void:
	var reach_weights := {
		ARM_BONE: clampf(alpha * 1.15, 0.0, 1.0),
		FOREARM_BONE: clampf((alpha - 0.12) * 1.2, 0.0, 1.0),
		HAND_BONE: clampf((alpha - 0.28) * 1.25, 0.0, 1.0),
	}
	var rest_fade := 1.0 - clampf(
		alpha / GroyperBodyUtils.HOLSTER_REST_FADE_REACH,
		0.0,
		1.0
	)
	var ik_targets := _compute_reach_chain_poses(target, alpha)

	for bone_name: String in AIM_BONES:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id < 0:
			continue

		var bone_alpha: float = reach_weights.get(bone_name, alpha)
		if bone_alpha <= 0.0:
			_skeleton.set_bone_pose_rotation(bone_id, _get_reach_rest_pose(bone_name, rest_fade))
			continue

		var rest_pose := _get_reach_rest_pose(bone_name, rest_fade)
		var target_pose: Quaternion = ik_targets.get(bone_name, Quaternion.IDENTITY)
		_skeleton.set_bone_pose_rotation(
			bone_id,
			_slerp_quat_short(rest_pose, target_pose, bone_alpha)
		)


func _get_reach_rest_pose(bone_name: String, rest_fade: float) -> Quaternion:
	if _saddle_owns_gun_arm():
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id >= 0:
			return _skeleton.get_bone_pose_rotation(bone_id)
	var holstered := _get_holstered_bone_pose(bone_name)
	return _slerp_quat_short(holstered, Quaternion.IDENTITY, 1.0 - rest_fade)


func _set_aim_bones_to_identity() -> void:
	if _saddle_owns_gun_arm():
		return
	for bone_name in AIM_BONES:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id >= 0:
			_skeleton.set_bone_pose_rotation(bone_id, Quaternion.IDENTITY)


func _compute_chain_bone_poses_toward(target: Vector3, bone_names: Array) -> Dictionary:
	_set_aim_bones_to_identity()
	var poses := {}

	for bone_name: String in bone_names:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id < 0:
			continue

		var local_axis: Vector3 = _bone_aim_axes.get(bone_name, Vector3(-1.0, 0.0, 0.0))
		if bone_name == ARM_BONE:
			local_axis = _get_gun_arm_aim_axis()
		var pose := _compute_bone_pose_toward(bone_id, target, local_axis)
		poses[bone_name] = pose
		_skeleton.set_bone_pose_rotation(bone_id, pose)

	return poses


func _get_holster_arm_guide_target(holster_target: Vector3, reach_alpha: float) -> Vector3:
	return GroyperBodyUtils.compute_holster_arm_guide_target(
		_skeleton,
		holster_target,
		reach_alpha,
		holster_reach_outward,
		holster_reach_forward,
		holster_reach_down,
		holster_reach_inward_start
	)


func _compute_reach_chain_poses(holster_target: Vector3, reach_alpha: float) -> Dictionary:
	# Save/restore so the temporary bind write never sticks as a visible T-pose.
	var saved: Dictionary = {}
	for bone_name: String in AIM_BONES:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id >= 0:
			saved[bone_name] = _skeleton.get_bone_pose_rotation(bone_id)
	_set_aim_bones_to_identity()
	var poses := {}
	var arm_guide := _get_holster_arm_guide_target(holster_target, reach_alpha)

	var arm_id := _skeleton.find_bone(ARM_BONE)
	if arm_id >= 0:
		var arm_axis: Vector3 = _bone_aim_axes.get(ARM_BONE, Vector3(-1.0, 0.0, 0.0))
		var arm_pose := _compute_bone_pose_toward(arm_id, arm_guide, arm_axis)
		arm_pose = (
			arm_pose
			* GroyperBodyUtils.reach_abduction_offset(reach_alpha, holster_reach_abduct_deg)
		).normalized()
		poses[ARM_BONE] = arm_pose
		_skeleton.set_bone_pose_rotation(arm_id, arm_pose)

	var forearm_id := _skeleton.find_bone(FOREARM_BONE)
	if forearm_id >= 0:
		var forearm_axis: Vector3 = _bone_aim_axes.get(FOREARM_BONE, Vector3(-1.0, 0.0, 0.0))
		var forearm_guide_blend := clampf(1.0 - reach_alpha * 1.35, 0.0, 0.5)
		var forearm_target := holster_target.lerp(arm_guide, forearm_guide_blend)
		var forearm_pose := _compute_bone_pose_toward(forearm_id, forearm_target, forearm_axis)
		poses[FOREARM_BONE] = forearm_pose
		_skeleton.set_bone_pose_rotation(forearm_id, forearm_pose)

	# Keep the live hand bend — IDENTITY here was a straight-arm T-pose flash.
	var hand_id := _skeleton.find_bone(HAND_BONE)
	if hand_id >= 0:
		poses[HAND_BONE] = saved.get(HAND_BONE, _skeleton.get_bone_pose_rotation(hand_id))
	else:
		poses[HAND_BONE] = Quaternion.IDENTITY

	for bone_name: Variant in saved.keys():
		var restore_id := _skeleton.find_bone(String(bone_name))
		if restore_id >= 0:
			_skeleton.set_bone_pose_rotation(restore_id, saved[bone_name])
	return poses


func _cache_raise_start_poses(holster_target: Vector3) -> void:
	# Preserve live poses while sampling reach — writing identity mid-frame was
	# flashing the support arm into bind/T-pose on 1H↔2H grabs.
	_raise_start_poses = _compute_raise_start_poses_preserved(holster_target)


func _compute_raise_start_poses_preserved(holster_target: Vector3) -> Dictionary:
	## Reach snapshot for put-away without flashing the arm into reach.
	var bones: Array = _raise_capture_bones()
	var saved: Dictionary = {}
	for bone_name: String in bones:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id >= 0:
			saved[bone_name] = _skeleton.get_bone_pose_rotation(bone_id)
	if GroyperWeapons.is_bow(_equipped_weapon_id):
		_apply_bow_reach_toward_holster(1.0)
	else:
		_apply_reach_toward_target(1.0, holster_target)
	var poses := _capture_aim_bone_rotations()
	for bone_name: String in saved.keys():
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id >= 0:
			_skeleton.set_bone_pose_rotation(bone_id, saved[bone_name])
	return poses


func _raise_capture_bones() -> Array:
	var bones: Array = AIM_BONES.duplicate()
	if _draw_uses_two_hand_chain() or GroyperWeapons.is_bow(_equipped_weapon_id):
		for bone_name: String in TWO_HAND_AIM_BONES:
			if bone_name not in bones:
				bones.append(bone_name)
	if GroyperWeapons.is_bow(_equipped_weapon_id):
		for bone_name: String in [
			LEFT_SHOULDER_BONE,
			LEFT_ARM_BONE,
			LEFT_FOREARM_BONE,
			LEFT_HAND_BONE,
		]:
			if bone_name not in bones:
				bones.append(bone_name)
	return bones


func _apply_raise_pose(alpha: float) -> void:
	if _raise_start_poses.is_empty():
		return

	var eased := alpha * alpha * (3.0 - 2.0 * alpha)

	if GroyperWeapons.is_bow(_equipped_weapon_id) and (_gun_in_hand or _putaway_from_aim):
		_apply_bow_raise_pose(eased)
		if _gun_in_hand:
			_apply_gun_grip_raise(eased)
		return

	if _draw_uses_two_hand_chain():
		# Raise into authored hip rest (ads=0); live aim IK takes over at AIMING.
		# Skip bones the clips don't key — slerping to identity = T-pose mid-draw.
		# Authored torso wins when keyed; otherwise procedural stance fades in.
		# Use weapon-id chain (not gun_in_hand) so put-away keeps the left arm
		# after the grip reparents to the holster.
		if _has_authored_two_hand_torso():
			pass
		else:
			_apply_two_hand_stance_twist(eased)
		for bone_name: String in TWO_HAND_AIM_BONES:
			if not _has_two_hand_authored_pose(bone_name):
				continue
			var bone_id := _skeleton.find_bone(bone_name)
			if bone_id < 0:
				continue
			var from_q: Quaternion = _raise_start_poses.get(
				bone_name,
				_skeleton.get_bone_pose_rotation(bone_id)
			)
			var to_q := _get_two_hand_blended_pose(bone_name)
			_skeleton.set_bone_pose_rotation(bone_id, _slerp_quat_short(from_q, to_q, eased))
		TwoHandAimPoseConfig.apply_aim_pitch_to_skeleton(
			_skeleton,
			_raise_aim_target,
			eased
		)
	else:
		# Ease gun-arm (+ optional shoulder) into the authored 1H rest, then
		# fade in Spine02 pitch — same recipe as the two-hand raise.
		var aim_poses := _compute_aim_bone_rotations_for_raise(_raise_aim_target)
		var raise_bones: Array = AIM_BONES.duplicate()
		if aim_poses.has(SHOULDER_BONE):
			raise_bones.append(SHOULDER_BONE)
		for bone_name: String in raise_bones:
			var bone_id := _skeleton.find_bone(bone_name)
			if bone_id < 0:
				continue

			var from_q: Quaternion = _raise_start_poses.get(
				bone_name,
				_skeleton.get_bone_pose_rotation(bone_id)
			)
			var to_q: Quaternion = aim_poses.get(
				bone_name,
				_skeleton.get_bone_pose_rotation(bone_id)
			)
			_skeleton.set_bone_pose_rotation(bone_id, _slerp_quat_short(from_q, to_q, eased))
		TwoHandAimPoseConfig.apply_aim_pitch_to_skeleton(
			_skeleton,
			_raise_aim_target,
			eased
		)

	if _gun_in_hand:
		_apply_gun_grip_raise(eased)


func _apply_bow_raise_pose(eased: float) -> void:
	_refresh_bow_aim_poses()
	for bone_name: String in BowAimPoseConfig.AUTHORING_BONES:
		if not _has_bow_authored_pose(bone_name):
			continue
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id < 0:
			continue
		var from_q: Quaternion = _raise_start_poses.get(
			bone_name,
			_skeleton.get_bone_pose_rotation(bone_id)
		)
		# Hold frame (draw scrub stays 0 during equip raise).
		var to_q := BowAimPoseConfig.blended_pose_rotation(
			_bow_hold_hip_poses,
			_bow_hold_ads_poses,
			bone_name,
			_ads_aim_blend
		)
		_skeleton.set_bone_pose_rotation(bone_id, _slerp_quat_short(from_q, to_q, eased))
	BowAimPoseConfig.apply_aim_pitch_to_skeleton(_skeleton, _raise_aim_target, eased)


func _apply_bow_reach_toward_holster(alpha: float) -> void:
	## Left hand draws the bow off the back; right arm eases toward hold (no overhead).
	var target := _get_holster_reach_target()
	var left_weights := {
		LEFT_ARM_BONE: clampf(alpha * 1.15, 0.0, 1.0),
		LEFT_FOREARM_BONE: clampf((alpha - 0.12) * 1.2, 0.0, 1.0),
		LEFT_HAND_BONE: clampf((alpha - 0.28) * 1.25, 0.0, 1.0),
	}
	var left_ik := _compute_left_reach_poses(target, alpha)
	for bone_name: String in LEFT_AIM_BONES:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id < 0:
			continue
		var bone_alpha: float = left_weights.get(bone_name, alpha)
		var target_pose: Quaternion = left_ik.get(bone_name, Quaternion.IDENTITY)
		if bone_alpha <= 0.0:
			continue
		var current := _skeleton.get_bone_pose_rotation(bone_id)
		_skeleton.set_bone_pose_rotation(
			bone_id,
			_slerp_quat_short(current, target_pose, bone_alpha)
		)
	# Soft right-arm settle toward undrawn hold — avoid the hip-draw overhead arc.
	_refresh_bow_aim_poses()
	var right_alpha := clampf(alpha * 0.65, 0.0, 1.0)
	for bone_name: String in BowAimPoseConfig.STRING_HAND_BONES:
		if not _has_bow_authored_pose(bone_name):
			continue
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id < 0:
			continue
		var hold_q := BowAimPoseConfig.blended_pose_rotation(
			_bow_hold_hip_poses,
			_bow_hold_ads_poses,
			bone_name,
			_ads_aim_blend
		)
		var current_r := _skeleton.get_bone_pose_rotation(bone_id)
		_skeleton.set_bone_pose_rotation(bone_id, current_r.slerp(hold_q, right_alpha))


func _apply_gun_grip_raise(alpha: float) -> void:
	if _revolver_grip == null or not _gun_in_hand:
		return

	var target_local := _get_hand_grip_local()
	if alpha >= 0.999 or not _grip_xfer_active:
		_revolver_grip.transform = target_local
		return

	var hand_socket := _get_active_hand_socket()
	if hand_socket == null:
		_revolver_grip.transform = _lerp_transform(
			_raise_grip_local_start,
			target_local,
			alpha
		)
		return

	# World-space transfer preserves holster/hand parent scale (no tiny blip).
	# Refresh holster end while unequipping so the socket can move with the body.
	var holster_end := _grip_xfer_holster_global
	if _draw_state == DrawState.HOLSTERING:
		var holster_socket := _get_active_holster_socket()
		if holster_socket != null:
			holster_end = holster_socket.global_transform * _holster_grip_local
	var hand_end := hand_socket.global_transform * target_local
	_revolver_grip.global_transform = _lerp_transform(holster_end, hand_end, alpha)


func _apply_arm_aim(world_target: Vector3, delta: float) -> void:
	if _uses_bow_arm_aim():
		_apply_bow_arm_aim(world_target, delta)
		return
	if _uses_two_hand_arm_aim():
		_apply_two_hand_arm_aim(world_target, delta)
		return

	# 1H: stamp HipFireAim/neutral→ads verbatim (WYSIWYG with the editor), then
	# pitch Spine02 for look elevation — same recipe as two-hand firearms.
	var arm_id := _skeleton.find_bone(ARM_BONE)
	if arm_id < 0:
		return

	var smooth_step := 1.0 - exp(-aim_pose_smooth * delta)
	if _smoothed_arm_aim_target == Vector3.ZERO:
		_smoothed_arm_aim_target = world_target
	_smoothed_arm_aim_target = _smoothed_arm_aim_target.lerp(world_target, smooth_step)

	_apply_hip_fire_authored_rests(HipFireAimPoseConfig.AUTHORING_BONES)
	_apply_hip_fire_walk_torso_stabilizer()
	if not _has_hip_fire_authored_pose(SHOULDER_BONE):
		_apply_hip_fire_shoulder_clearance()
	TwoHandAimPoseConfig.apply_aim_pitch_to_skeleton(
		_skeleton,
		_smoothed_arm_aim_target,
		1.0
	)
	var aim_poses := _compute_hip_fire_aim_poses(_smoothed_arm_aim_target)

	for bone_name: String in HipFireAimPoseConfig.GUN_ARM_SMOOTH_BONES:
		if (
			bone_name == SHOULDER_BONE
			and not _should_apply_optional_hip_fire_bone(bone_name)
		):
			continue
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id < 0:
			continue
		var rest: Quaternion = aim_poses.get(bone_name, _get_hip_fire_blended_pose(bone_name))
		var pose: Quaternion = _aim_bone_poses_smoothed.get(bone_name, rest)
		pose = _slerp_quaternion(pose, rest, smooth_step)
		_aim_bone_poses_smoothed[bone_name] = pose
		if bone_name == FOREARM_BONE:
			_skeleton.set_bone_pose_rotation(bone_id, _apply_forearm_recoil_offset(pose))
		else:
			_skeleton.set_bone_pose_rotation(bone_id, pose)


## Authored hip→ADS hold applied verbatim (same WYSIWYG recipe as two-hand).
## Elevation comes from Spine02 pitch, not an arm aim-correct — the arms keep
## the exact silhouette authored in the editor; legs stay on locomotion.
func _compute_hip_fire_aim_poses(_world_target: Vector3) -> Dictionary:
	var poses := {}
	var arm_id := _skeleton.find_bone(ARM_BONE)
	if arm_id < 0:
		return poses

	var forearm_id := _skeleton.find_bone(FOREARM_BONE)
	var hand_id := _skeleton.find_bone(HAND_BONE)

	var arm_pose := _get_hip_fire_blended_pose(ARM_BONE)
	var forearm_pose := _get_hip_fire_blended_pose(FOREARM_BONE)
	var hand_pose := _get_hip_fire_blended_pose(HAND_BONE)

	if _should_apply_optional_hip_fire_bone(SHOULDER_BONE):
		poses[SHOULDER_BONE] = _get_hip_fire_blended_pose(SHOULDER_BONE)

	poses[ARM_BONE] = arm_pose
	poses[FOREARM_BONE] = forearm_pose
	poses[HAND_BONE] = hand_pose
	_skeleton.set_bone_pose_rotation(arm_id, arm_pose)
	if forearm_id >= 0:
		_skeleton.set_bone_pose_rotation(forearm_id, forearm_pose)
	if hand_id >= 0:
		_skeleton.set_bone_pose_rotation(hand_id, hand_pose)
	return poses


## Freeze locomotion sway on torso bones the HipFireAim clips don't key while
## walking with a 1H gun — the stamped arm rests ride on the spine, so walk
## sway would bob the gun off the reticle. Keyed bones are stamped already.
func _apply_hip_fire_walk_torso_stabilizer() -> void:
	if not _hip_fire_aim_enabled:
		return
	var weight := HipFireAimPoseConfig.move_stability_weight(_hip_fire_move_blend)
	if weight <= 0.0001:
		return
	for bone_name: String in HipFireAimPoseConfig.TORSO_BONES:
		if _has_hip_fire_authored_pose(bone_name):
			continue
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id < 0:
			continue
		var current := _skeleton.get_bone_pose_rotation(bone_id)
		_skeleton.set_bone_pose_rotation(
			bone_id,
			current.slerp(Quaternion.IDENTITY, weight).normalized()
		)


## Soften locomotion RightShoulder while walking/running with a 1H gun (hip+ADS).
## Skipped when HipFireAim keys RightShoulder (authored rest owns the bone).
func _apply_hip_fire_shoulder_clearance() -> void:
	if not _hip_fire_aim_enabled:
		return
	if _has_hip_fire_authored_pose(SHOULDER_BONE):
		return
	var weight := (
		HipFireAimPoseConfig.body_clearance_weight(_hip_fire_move_blend)
		* HipFireAimPoseConfig.BODY_CLEARANCE_SHOULDER_DAMP
	)
	if weight <= 0.0001:
		return
	var shoulder_id := _skeleton.find_bone(SHOULDER_BONE)
	if shoulder_id < 0:
		return
	var current := _skeleton.get_bone_pose_rotation(shoulder_id)
	_skeleton.set_bone_pose_rotation(
		shoulder_id,
		current.slerp(Quaternion.IDENTITY, weight).normalized()
	)


## Two-hand rifle stance: authored TwoHandAim/neutral→ads upper-body chain, then
## Spine02 pitch for look elevation. No arm aim-correct / SupportHand IK — left
## hand stays on the authored foregrip; left/right is body yaw.
func _apply_two_hand_arm_aim(world_target: Vector3, delta: float) -> void:
	var arm_id := _skeleton.find_bone(ARM_BONE)
	var forearm_id := _skeleton.find_bone(FOREARM_BONE)
	if arm_id < 0:
		return

	var smooth_step := 1.0 - exp(-aim_pose_smooth * delta)
	if _smoothed_arm_aim_target == Vector3.ZERO:
		_smoothed_arm_aim_target = world_target
	_smoothed_arm_aim_target = _smoothed_arm_aim_target.lerp(world_target, smooth_step)

	_apply_two_hand_torso_pose(1.0)
	_apply_two_hand_authored_rests(TWO_HAND_AIM_BONES)
	TwoHandAimPoseConfig.apply_aim_pitch_to_skeleton(
		_skeleton,
		_smoothed_arm_aim_target,
		1.0
	)

	# Smooth gun-arm keys + recoil so ADS blend / shots don't pop.
	for bone_name: String in [ARM_BONE, FOREARM_BONE, HAND_BONE]:
		if not _has_two_hand_authored_pose(bone_name):
			continue
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id < 0:
			continue
		var rest := _get_two_hand_blended_pose(bone_name)
		var pose: Quaternion = _aim_bone_poses_smoothed.get(bone_name, rest)
		pose = _slerp_quaternion(pose, rest, smooth_step)
		_aim_bone_poses_smoothed[bone_name] = pose
		if bone_name == FOREARM_BONE:
			_skeleton.set_bone_pose_rotation(bone_id, _apply_forearm_recoil_offset(pose))
		else:
			_skeleton.set_bone_pose_rotation(bone_id, pose)

	# Left arm: authored only (no SupportHand push).
	_apply_two_hand_authored_rests([
		LEFT_SHOULDER_BONE, LEFT_ARM_BONE, LEFT_FOREARM_BONE, LEFT_HAND_BONE
	])


## RecurveBow: left hand / torso locked on hold pose (bow seat). Right arm
## scrubs BowAim drawback keys by draw alpha — no procedural IK.
func _apply_bow_arm_aim(world_target: Vector3, delta: float) -> void:
	var arm_id := _skeleton.find_bone(ARM_BONE)
	if arm_id < 0:
		return

	if _smoothed_arm_aim_target == Vector3.ZERO:
		_smoothed_arm_aim_target = world_target
	var smooth_step := 1.0 - exp(-aim_pose_smooth * delta)
	_smoothed_arm_aim_target = _smoothed_arm_aim_target.lerp(world_target, smooth_step)

	_refresh_bow_aim_poses()

	# Bow stay put: left arm + torso always use the hold frame (hip↔ADS only).
	_apply_bow_hold_locked_rests()
	BowAimPoseConfig.apply_aim_pitch_to_skeleton(
		_skeleton,
		_smoothed_arm_aim_target,
		1.0
	)

	# String hand: authored drawback scrub, applied directly so keys read 1:1.
	for bone_name: String in BowAimPoseConfig.STRING_HAND_BONES:
		if not _has_bow_authored_pose(bone_name):
			continue
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id < 0:
			continue
		var pose := _get_bow_blended_pose(bone_name)
		_aim_bone_poses_smoothed[bone_name] = pose
		_skeleton.set_bone_pose_rotation(bone_id, pose)


func _refresh_bow_aim_poses() -> void:
	var animation_player := _find_body_animation_player()
	if not _bow_hold_poses_cached:
		_bow_hold_hip_poses = BowAimPoseConfig.sample_pose_rotations(
			animation_player,
			BowAimPoseConfig.POSE_NAME_NEUTRAL,
			0.0
		)
		_bow_hold_ads_poses = BowAimPoseConfig.sample_pose_rotations(
			animation_player,
			BowAimPoseConfig.POSE_NAME_ADS,
			0.0
		)
		_fill_bow_pose_gaps(_bow_hold_hip_poses, _bow_hold_ads_poses)
		_bow_hold_poses_cached = true
		if _bow_hold_hip_poses.is_empty():
			push_warning(
				"GroyperWeaponRig: no BowAim/neutral pose loaded — bow aim falls back to identity rests."
			)

	var draw_t := clampf(_bow_string_hand_alpha, 0.0, 1.0)
	if is_equal_approx(_bow_poses_sample_alpha, draw_t) and not _bow_draw_hip_poses.is_empty():
		return
	_bow_poses_sample_alpha = draw_t
	_bow_draw_hip_poses = BowAimPoseConfig.sample_pose_rotations(
		animation_player,
		BowAimPoseConfig.POSE_NAME_NEUTRAL,
		draw_t
	)
	_bow_draw_ads_poses = BowAimPoseConfig.sample_pose_rotations(
		animation_player,
		BowAimPoseConfig.POSE_NAME_ADS,
		draw_t
	)
	_fill_bow_pose_gaps(_bow_draw_hip_poses, _bow_draw_ads_poses)
	_warn_if_bow_drawback_keys_missing(draw_t)


func _fill_bow_pose_gaps(hip_poses: Dictionary, ads_poses: Dictionary) -> void:
	if ads_poses.is_empty() and not hip_poses.is_empty():
		for key: Variant in hip_poses.keys():
			ads_poses[key] = hip_poses[key]
	for bone_name: String in BowAimPoseConfig.AUTHORING_BONES:
		if not hip_poses.has(bone_name) and ads_poses.has(bone_name):
			hip_poses[bone_name] = ads_poses[bone_name]
		if not ads_poses.has(bone_name) and hip_poses.has(bone_name):
			ads_poses[bone_name] = hip_poses[bone_name]


func _warn_if_bow_drawback_keys_missing(draw_t: float) -> void:
	if _bow_missing_draw_keys_warned or draw_t < 0.2:
		return
	if _bow_hold_hip_poses.is_empty() or _bow_draw_hip_poses.is_empty():
		return
	var hold_q: Quaternion = _bow_hold_hip_poses.get(
		BowAimPoseConfig.RIGHT_ARM_BONE,
		Quaternion.IDENTITY
	) as Quaternion
	var draw_q: Quaternion = _bow_draw_hip_poses.get(
		BowAimPoseConfig.RIGHT_ARM_BONE,
		hold_q
	) as Quaternion
	if hold_q.is_equal_approx(draw_q):
		_bow_missing_draw_keys_warned = true
		push_warning(
			"GroyperWeaponRig: BowAim/neutral RightArm is identical at hold and full draw. "
			+ "Add rotation keys along the clip timeline and save res://characters/groyper/bow_aim.tres."
		)


func _apply_bow_hold_locked_rests() -> void:
	# Left arm + torso from hold frame only — BowHandMount (LeftHand) never drifts
	# with the string-hand scrub. No rifle blade stance twist (pinches at hip).
	_apply_bow_authored_rests(BowAimPoseConfig.HOLD_LOCK_BONES)
	_rest_bow_arm_bone_positions([
		LEFT_SHOULDER_BONE,
		LEFT_ARM_BONE,
		LEFT_FOREARM_BONE,
		LEFT_HAND_BONE,
	])
	_rest_bow_arm_bone_positions(BowAimPoseConfig.STRING_HAND_BONES)


func _rest_bow_arm_bone_positions(bone_names: Array) -> void:
	# BowAim clones sometimes bake position keys that collapse the arm into the
	# torso. Runtime only samples rotations — force rest positions so those
	# keys (and locomotion) cannot pinch the bow seat.
	for bone_name in bone_names:
		var bone_id := _skeleton.find_bone(String(bone_name))
		if bone_id < 0:
			continue
		var rest := _skeleton.get_bone_rest(bone_id)
		_skeleton.set_bone_pose_position(bone_id, rest.origin)
		_skeleton.set_bone_pose_scale(bone_id, Vector3.ONE)


func _apply_bow_authored_rests(bone_names: Array) -> void:
	for bone_name in bone_names:
		if not _has_bow_authored_pose(String(bone_name)):
			continue
		var bone_id := _skeleton.find_bone(String(bone_name))
		if bone_id >= 0:
			_skeleton.set_bone_pose_rotation(bone_id, _get_bow_blended_pose(String(bone_name)))


func _get_bow_blended_pose(bone_name: String) -> Quaternion:
	_refresh_bow_aim_poses()
	var hip_poses := _bow_hold_hip_poses
	var ads_poses := _bow_hold_ads_poses
	if BowAimPoseConfig.is_string_hand_bone(bone_name):
		hip_poses = _bow_draw_hip_poses
		ads_poses = _bow_draw_ads_poses
	return BowAimPoseConfig.blended_pose_rotation(
		hip_poses,
		ads_poses,
		bone_name,
		_ads_aim_blend
	)


func _has_bow_authored_pose(bone_name: String) -> bool:
	_refresh_bow_aim_poses()
	if BowAimPoseConfig.is_string_hand_bone(bone_name):
		return BowAimPoseConfig.has_authored_pose(
			_bow_draw_hip_poses,
			_bow_draw_ads_poses,
			bone_name
		)
	return BowAimPoseConfig.has_authored_pose(
		_bow_hold_hip_poses,
		_bow_hold_ads_poses,
		bone_name
	)


func _compute_bow_aim_bone_rotations(world_target: Vector3) -> Dictionary:
	_refresh_bow_aim_poses()
	_apply_bow_hold_locked_rests()
	for bone_name: String in BowAimPoseConfig.STRING_HAND_BONES:
		if not _has_bow_authored_pose(bone_name):
			continue
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id >= 0:
			_skeleton.set_bone_pose_rotation(bone_id, _get_bow_blended_pose(bone_name))
	BowAimPoseConfig.apply_aim_pitch_to_skeleton(_skeleton, world_target, 1.0)
	var poses := {}
	for bone_name: String in TWO_HAND_AIM_BONES:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id < 0:
			continue
		if bone_name == BowAimPoseConfig.AIM_PITCH_BONE or _has_bow_authored_pose(bone_name):
			poses[bone_name] = _skeleton.get_bone_pose_rotation(bone_id)
	return poses


## Apply authored Spine/Head rests when keyed; otherwise procedural blade stance.
func _apply_two_hand_torso_pose(weight: float) -> void:
	if _has_authored_two_hand_torso():
		_apply_two_hand_authored_rests(TwoHandAimPoseConfig.UPPER_BODY_BONES)
		return
	_apply_two_hand_stance_twist(weight)


func _has_authored_two_hand_torso() -> bool:
	if not _two_hand_poses_cached:
		_cache_two_hand_poses()
	return TwoHandAimPoseConfig.has_authored_torso(_two_hand_hip_poses, _two_hand_ads_poses)


## Bladed rifle stance: yaw the torso toward the gun side and counter-twist the
## head so the face stays on the aim direction. Fallback when TwoHandAim clips
## omit spine keys. Multiplied onto the current animated pose each frame.
func _apply_two_hand_stance_twist(weight: float) -> void:
	if _saddle_aim_mode:
		# Mount aiming already owns spine twist; don't stack.
		return
	var yaw := TwoHandAimPoseConfig.stance_yaw(_ads_aim_blend) * clampf(weight, 0.0, 1.0)
	if absf(yaw) <= 0.0001:
		return
	var applied_total := 0.0
	for i in TwoHandAimPoseConfig.STANCE_SPINE_BONES.size():
		var bone_name: String = TwoHandAimPoseConfig.STANCE_SPINE_BONES[i]
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id < 0:
			continue
		var bone_weight: float = TwoHandAimPoseConfig.STANCE_SPINE_WEIGHTS[i]
		applied_total += bone_weight
		var twist := Quaternion(Vector3.UP, yaw * bone_weight)
		var current := _skeleton.get_bone_pose_rotation(bone_id)
		_skeleton.set_bone_pose_rotation(bone_id, (current * twist).normalized())
	if applied_total <= 0.0:
		return
	var head_id := _skeleton.find_bone(TwoHandAimPoseConfig.STANCE_HEAD_BONE)
	if head_id >= 0:
		var counter := Quaternion(
			Vector3.UP,
			-yaw * applied_total * TwoHandAimPoseConfig.STANCE_HEAD_COUNTER
		)
		var head_current := _skeleton.get_bone_pose_rotation(head_id)
		_skeleton.set_bone_pose_rotation(head_id, (head_current * counter).normalized())


## Apply authored shoulder (or other) rests only when the clip actually keys them.
## Missing keys must NOT become identity — that forces bind/T-pose after AnimTree.
func _apply_two_hand_authored_rests(bone_names: Array) -> void:
	for bone_name in bone_names:
		if not _has_two_hand_authored_pose(String(bone_name)):
			continue
		var bone_id := _skeleton.find_bone(String(bone_name))
		if bone_id >= 0:
			_skeleton.set_bone_pose_rotation(bone_id, _get_two_hand_blended_pose(String(bone_name)))


func _apply_support_arm_aim(
	world_target: Vector3, delta: float, correct_weight: float = 1.0
) -> void:
	var arm_id := _skeleton.find_bone(LEFT_ARM_BONE)
	var forearm_id := _skeleton.find_bone(LEFT_FOREARM_BONE)
	var hand_id := _skeleton.find_bone(LEFT_HAND_BONE)
	if arm_id < 0:
		return

	var smooth_step := 1.0 - exp(-aim_pose_smooth * delta)

	# Authored left rest first. SupportHand only aim-corrects the upper arm from
	# that rest (same recipe as the gun arm) so the elbow silhouette survives.
	_apply_two_hand_authored_rests(
		[LEFT_SHOULDER_BONE, LEFT_ARM_BONE, LEFT_FOREARM_BONE, LEFT_HAND_BONE]
	)

	# No SupportHand / hip-neutral: leave authored rest.
	if world_target == Vector3.ZERO or correct_weight <= 0.0001:
		return

	var arm_axis: Vector3 = _bone_aim_axes.get(LEFT_ARM_BONE, Vector3(-1.0, 0.0, 0.0))
	var arm_base := (
		_get_two_hand_blended_pose(LEFT_ARM_BONE)
		if _has_two_hand_authored_pose(LEFT_ARM_BONE)
		else Quaternion.IDENTITY
	)
	var arm_corrected := _aim_correct_bone_from_base(arm_id, world_target, arm_axis, arm_base)
	var arm_target := _slerp_quaternion(arm_base, arm_corrected, correct_weight)
	var arm_pose: Quaternion = _aim_bone_poses_smoothed.get(LEFT_ARM_BONE, arm_target)
	arm_pose = _slerp_quaternion(arm_pose, arm_target, smooth_step)
	_aim_bone_poses_smoothed[LEFT_ARM_BONE] = arm_pose
	_skeleton.set_bone_pose_rotation(arm_id, arm_pose)

	if forearm_id >= 0 and _has_two_hand_authored_pose(LEFT_FOREARM_BONE):
		var forearm_rest := _get_two_hand_blended_pose(LEFT_FOREARM_BONE)
		var forearm_pose: Quaternion = _aim_bone_poses_smoothed.get(
			LEFT_FOREARM_BONE,
			forearm_rest
		)
		forearm_pose = _slerp_quaternion(forearm_pose, forearm_rest, smooth_step)
		_aim_bone_poses_smoothed[LEFT_FOREARM_BONE] = forearm_pose
		_skeleton.set_bone_pose_rotation(forearm_id, forearm_pose)

	if hand_id >= 0 and _has_two_hand_authored_pose(LEFT_HAND_BONE):
		_skeleton.set_bone_pose_rotation(hand_id, _get_two_hand_blended_pose(LEFT_HAND_BONE))


func _apply_mount_spine_twist() -> void:
	if absf(_mount_aim_spine_yaw) <= 0.0001:
		return

	for i in MOUNT_SPINE_BONES.size():
		var bone_name: String = MOUNT_SPINE_BONES[i]
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id < 0:
			continue
		var twist := Quaternion(
			Vector3.UP,
			_mount_aim_spine_yaw * MOUNT_SPINE_TWIST_WEIGHTS[i]
		)
		var current := _skeleton.get_bone_pose_rotation(bone_id)
		_skeleton.set_bone_pose_rotation(bone_id, current * twist)


func _compute_aim_bone_rotations(world_target: Vector3) -> Dictionary:
	if _uses_bow_arm_aim():
		return _compute_bow_aim_bone_rotations(world_target)
	if _uses_two_hand_arm_aim():
		return _compute_two_hand_aim_bone_rotations(world_target)

	# Mirror of the 1H aim pose: authored chain verbatim. Spine02 pitch is
	# applied by callers (raise fades it in; reload stays level).
	_apply_hip_fire_authored_rests(HipFireAimPoseConfig.AUTHORING_BONES)
	_apply_hip_fire_walk_torso_stabilizer()
	if not _has_hip_fire_authored_pose(SHOULDER_BONE):
		_apply_hip_fire_shoulder_clearance()
	return _compute_hip_fire_aim_poses(world_target)


func _compute_aim_bone_rotations_for_raise(world_target: Vector3) -> Dictionary:
	## Like _compute_aim_bone_rotations but keyed off equipped weapon so a lagged
	## two-hand flag during soft-swap can't pull 1H raise into rifle poses.
	if GroyperWeapons.is_bow(_equipped_weapon_id):
		return _compute_bow_aim_bone_rotations(world_target)
	if _draw_uses_two_hand_chain():
		return _compute_two_hand_aim_bone_rotations(world_target)
	_apply_hip_fire_authored_rests(HipFireAimPoseConfig.AUTHORING_BONES)
	_apply_hip_fire_walk_torso_stabilizer()
	if not _has_hip_fire_authored_pose(SHOULDER_BONE):
		_apply_hip_fire_shoulder_clearance()
	return _compute_hip_fire_aim_poses(world_target)


func _apply_support_arm_during_reach(reach_alpha: float) -> void:
	## Keep the left arm under our control during reach so it never falls through
	## to bind/T-pose between put-away and the next draw.
	if _raise_start_poses.is_empty() and not _draw_uses_two_hand_chain():
		return
	var support_bones: Array = [
		LEFT_SHOULDER_BONE,
		LEFT_ARM_BONE,
		LEFT_FOREARM_BONE,
		LEFT_HAND_BONE,
	]
	var weight := clampf(reach_alpha, 0.0, 1.0)
	weight = weight * weight * (3.0 - 2.0 * weight)
	for bone_name: String in support_bones:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id < 0:
			continue
		var current := _skeleton.get_bone_pose_rotation(bone_id)
		var from_q: Quaternion = _raise_start_poses.get(bone_name, current)
		var to_q := current
		if _draw_uses_two_hand_chain() and _has_two_hand_authored_pose(bone_name):
			to_q = _get_two_hand_blended_pose(bone_name)
		elif not _raise_start_poses.has(bone_name):
			continue
		_skeleton.set_bone_pose_rotation(bone_id, _slerp_quat_short(from_q, to_q, weight))


func _compute_two_hand_aim_bone_rotations(world_target: Vector3) -> Dictionary:
	# Mirror of _apply_two_hand_arm_aim without smoothing: authored chain + pitch.
	_apply_two_hand_torso_pose(1.0)
	_apply_two_hand_authored_rests(TWO_HAND_AIM_BONES)
	TwoHandAimPoseConfig.apply_aim_pitch_to_skeleton(_skeleton, world_target, 1.0)
	var poses := {}
	for bone_name: String in TWO_HAND_AIM_BONES:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id < 0:
			continue
		if bone_name == TwoHandAimPoseConfig.AIM_PITCH_BONE or _has_two_hand_authored_pose(bone_name):
			poses[bone_name] = _skeleton.get_bone_pose_rotation(bone_id)
	return poses


func _saddle_owns_gun_arm() -> bool:
	return _saddle_aim_mode and is_holstered()


func _compute_bone_pose_toward(bone_id: int, world_target: Vector3, local_aim_axis: Vector3) -> Quaternion:
	var bone_global := _skeleton.global_transform * _skeleton.get_bone_global_pose(bone_id)
	var to_target := world_target - bone_global.origin
	if to_target.length_squared() < 0.04:
		to_target = -_owner.global_transform.basis.z
	else:
		to_target = to_target.normalized()

	var parent_id := _skeleton.get_bone_parent(bone_id)
	var parent_global := _skeleton.global_transform
	if parent_id >= 0:
		parent_global = _skeleton.global_transform * _skeleton.get_bone_global_pose(parent_id)

	var bone_rest := _skeleton.get_bone_rest(bone_id)
	var rest_global_basis := parent_global.basis * bone_rest.basis
	var aim_vector := (rest_global_basis * local_aim_axis).normalized()
	var twist := _safe_quat_between(aim_vector, to_target)

	# Aim from bind rest, not the animated arm pose (idle clips can raise the gun arm).
	var rest_global_rot := rest_global_basis.get_rotation_quaternion()
	var new_global_rot := twist * rest_global_rot
	var parent_rot := parent_global.basis.get_rotation_quaternion()
	var rest_rot := bone_rest.basis.get_rotation_quaternion()
	return rest_rot.inverse() * parent_rot.inverse() * new_global_rot


func _capture_aim_bone_rotations() -> Dictionary:
	var poses := {}
	for bone_name: String in _raise_capture_bones():
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id >= 0:
			poses[bone_name] = _skeleton.get_bone_pose_rotation(bone_id)
	return poses


func _get_holstered_bone_pose(bone_name: String) -> Quaternion:
	return GroyperBodyUtils.holstered_bone_pose_rotation(bone_name, holstered_arm_rotation_deg)


func _reset_aim_bone_poses() -> void:
	for bone_name in AIM_BONES:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id >= 0:
			_skeleton.set_bone_pose_rotation(bone_id, _get_holstered_bone_pose(bone_name))


func _release_arm_to_animation() -> void:
	_clear_holster_exit_blend()
	_release_bones_to_animation(AIM_BONES)


func _release_gun_arm_to_animation() -> void:
	_clear_holster_exit_blend()
	_release_bones_to_animation(GUN_ARM_BONES)


func _release_bones_to_animation(_bone_names: Array) -> void:
	# Do NOT reset_bone_pose. ArmAimModifier runs after AnimationTree; a reset
	# forces bind/T-pose for a frame (visible on weapon swaps / put-away).
	# Stopping our overrides is enough — the next AnimTree tick owns the bones.
	pass


func _holster_exit_bone_names() -> Array:
	var bones: Array = AIM_BONES.duplicate()
	bones.append(SHOULDER_BONE)
	for bone_name: String in LEFT_AIM_BONES:
		bones.append(bone_name)
	bones.append(LEFT_SHOULDER_BONE)
	for bone_name: String in ["Spine", "Spine01", "Spine02", "Head"]:
		bones.append(bone_name)
	return bones


func _begin_holster_exit_blend() -> void:
	if _skeleton == null:
		_clear_holster_exit_blend()
		return
	_holster_exit_poses.clear()
	for bone_name: String in _holster_exit_bone_names():
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id < 0:
			continue
		_holster_exit_poses[bone_name] = _skeleton.get_bone_pose_rotation(bone_id)
	_holster_exit_blend = 1.0 if not _holster_exit_poses.is_empty() else 0.0


func _clear_holster_exit_blend() -> void:
	_holster_exit_blend = 0.0
	_holster_exit_poses.clear()


## Modifier runs after AnimationTree: slerp anim pose → captured holster pose by blend.
func _apply_holster_exit_blend(delta: float) -> void:
	if _holster_exit_blend <= 0.0 or _skeleton == null or _holster_exit_poses.is_empty():
		return
	for bone_name: String in _holster_exit_poses.keys():
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id < 0:
			continue
		var anim_q := _skeleton.get_bone_pose_rotation(bone_id)
		var holster_q: Quaternion = _holster_exit_poses[bone_name]
		_skeleton.set_bone_pose_rotation(bone_id, anim_q.slerp(holster_q, _holster_exit_blend))
	_holster_exit_blend = maxf(0.0, _holster_exit_blend - delta / HOLSTER_EXIT_BLEND_DURATION)
	if _holster_exit_blend <= 0.001:
		_clear_holster_exit_blend()


func _clear_raise_cache() -> void:
	_raise_start_poses.clear()
	_raise_end_poses.clear()
	_raise_aim_target = Vector3.ZERO
	_raise_grip_local_start = Transform3D.IDENTITY
	_grip_xfer_holster_global = Transform3D.IDENTITY
	_grip_xfer_active = false
	_putaway_from_aim = false


func _clear_arm_aim_smoothing() -> void:
	_smoothed_arm_aim_target = Vector3.ZERO
	_aim_bone_poses_smoothed.clear()


func _seed_arm_aim_smoothing() -> void:
	_aim_bone_poses_smoothed.clear()
	var bones_to_seed: Array = AIM_IK_BONES.duplicate()
	if _uses_two_hand_arm_aim():
		for bone_name: String in TwoHandAimPoseConfig.SUPPORT_IK_BONES:
			if bone_name not in bones_to_seed:
				bones_to_seed.append(bone_name)
	for bone_name: String in bones_to_seed:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id >= 0:
			_aim_bone_poses_smoothed[bone_name] = _skeleton.get_bone_pose_rotation(bone_id)
	_smoothed_arm_aim_target = _aim_target


func _apply_holster_grip_transform() -> void:
	if _revolver_grip:
		_revolver_grip.transform = _holster_grip_local


func _get_hand_grip_local() -> Transform3D:
	# Placement lives on GripOffset when present; grip sits at identity under it.
	# BowHandMount owns the vertical seat — no extra PI/2 here.
	if GroyperBodyUtils.firearm_hand_uses_grip_offset(_skeleton, int(_equipped_weapon_id)):
		return Transform3D.IDENTITY
	return Transform3D(
		Basis.from_euler(hand_grip_rotation_deg * (PI / 180.0)),
		hand_grip_position
	)


func _cache_bone_aim_axes() -> void:
	_bone_aim_axes.clear()
	for bone_name in AIM_BONES + LEFT_AIM_BONES:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id >= 0:
			_bone_aim_axes[bone_name] = GroyperBodyUtils.detect_bone_child_aim_axis(_skeleton, bone_id)
	if _skeleton.find_bone(ARM_BONE) >= 0:
		_bone_aim_axes[ARM_BONE] = _get_gun_arm_aim_axis()


func _get_gun_arm_aim_axis() -> Vector3:
	var forearm_pose := _get_hip_fire_blended_pose(FOREARM_BONE)
	var hand_pose := _get_hip_fire_blended_pose(HAND_BONE)
	if _uses_two_hand_arm_aim():
		forearm_pose = _get_two_hand_blended_pose(FOREARM_BONE)
		hand_pose = _get_two_hand_blended_pose(HAND_BONE)
	return GroyperBodyUtils.detect_gun_arm_aim_axis(
		_skeleton,
		ARM_BONE,
		FOREARM_BONE,
		HAND_BONE,
		forearm_pose,
		hand_pose
	)


## Rotate an authored base pose so its local aim axis points at the target.
## Preserves the authored shape (elbow bend); only swings the chain to aim.
## With tuned hip/ADS rests this is the walk/run reticle stabilizer.
func _aim_correct_bone_from_base(
	bone_id: int,
	world_target: Vector3,
	local_aim_axis: Vector3,
	base_pose: Quaternion
) -> Quaternion:
	_skeleton.set_bone_pose_rotation(bone_id, base_pose)

	var bone_global := _skeleton.global_transform * _skeleton.get_bone_global_pose(bone_id)
	var to_target := world_target - bone_global.origin
	if to_target.length_squared() < 0.04:
		to_target = -_owner.global_transform.basis.z
	else:
		to_target = to_target.normalized()

	var parent_id := _skeleton.get_bone_parent(bone_id)
	var parent_global := _skeleton.global_transform
	if parent_id >= 0:
		parent_global = _skeleton.global_transform * _skeleton.get_bone_global_pose(parent_id)

	var bone_rest := _skeleton.get_bone_rest(bone_id)
	var posed_global_basis := parent_global.basis * bone_rest.basis * Basis(base_pose)
	var aim_vector := (posed_global_basis * local_aim_axis).normalized()
	if aim_vector.length_squared() < 0.0001:
		return base_pose

	var twist := _safe_quat_between(aim_vector, to_target)
	var posed_global_rot := posed_global_basis.get_rotation_quaternion()
	var new_global_rot := twist * posed_global_rot
	var parent_rot := parent_global.basis.get_rotation_quaternion()
	var rest_rot := bone_rest.basis.get_rotation_quaternion()
	return (rest_rot.inverse() * parent_rot.inverse() * new_global_rot).normalized()


func _cache_hip_fire_poses() -> void:
	_hip_fire_poses_cached = true
	_hip_fire_poses.clear()
	_hip_fire_ads_poses.clear()
	var animation_player := _find_body_animation_player()
	_hip_fire_poses = HipFireAimPoseConfig.load_pose_rotations(
		animation_player,
		HipFireAimPoseConfig.POSE_NAME_NEUTRAL
	)
	_hip_fire_ads_poses = HipFireAimPoseConfig.load_pose_rotations(
		animation_player,
		HipFireAimPoseConfig.POSE_NAME_ADS
	)
	# Required gun-arm bones get euler / identity fallbacks. Optional bones
	# (spine / shoulder) are left missing when unkeyed — never invent identity
	# and never copy ADS shoulder into hip (that pinched the hip hold inward).
	for bone_name: String in HipFireAimPoseConfig.REQUIRED_BONES:
		if not _hip_fire_poses.has(bone_name):
			_hip_fire_poses[bone_name] = HipFireAimPoseConfig.fallback_pose_rotation(bone_name)
		if not _hip_fire_ads_poses.has(bone_name):
			_hip_fire_ads_poses[bone_name] = HipFireAimPoseConfig.fallback_ads_pose_rotation(
				bone_name
			)
	# Gap-fill only required gun-arm bones across incomplete captures.
	for bone_name: String in HipFireAimPoseConfig.REQUIRED_BONES:
		if not _hip_fire_poses.has(bone_name) and _hip_fire_ads_poses.has(bone_name):
			_hip_fire_poses[bone_name] = _hip_fire_ads_poses[bone_name]
		if not _hip_fire_ads_poses.has(bone_name) and _hip_fire_poses.has(bone_name):
			_hip_fire_ads_poses[bone_name] = _hip_fire_poses[bone_name]


func _cache_two_hand_poses() -> void:
	_two_hand_poses_cached = true
	_two_hand_hip_poses.clear()
	_two_hand_ads_poses.clear()
	var animation_player := _find_body_animation_player()
	_two_hand_hip_poses = TwoHandAimPoseConfig.load_pose_rotations(
		animation_player,
		TwoHandAimPoseConfig.POSE_NAME_NEUTRAL
	)
	_two_hand_ads_poses = TwoHandAimPoseConfig.load_pose_rotations(
		animation_player,
		TwoHandAimPoseConfig.POSE_NAME_ADS
	)
	if _two_hand_hip_poses.is_empty():
		push_warning(
			"GroyperWeaponRig: no TwoHandAim/neutral pose loaded — two-hand aim falls back to identity rests."
		)
	if _two_hand_ads_poses.is_empty() and not _two_hand_hip_poses.is_empty():
		# ADS clip missing: keep hip as both endpoints so ads_blend still works.
		_two_hand_ads_poses = _two_hand_hip_poses.duplicate()
	# Neutral is an older full-body capture and often omits RightShoulder/RightHand.
	# Fill gaps from ads so hip-fire (ads=0) never applies bind identity to those bones.
	for bone_name: String in TwoHandAimPoseConfig.AUTHORING_BONES:
		if not _two_hand_hip_poses.has(bone_name) and _two_hand_ads_poses.has(bone_name):
			_two_hand_hip_poses[bone_name] = _two_hand_ads_poses[bone_name]
		if not _two_hand_ads_poses.has(bone_name) and _two_hand_hip_poses.has(bone_name):
			_two_hand_ads_poses[bone_name] = _two_hand_hip_poses[bone_name]


func _get_two_hand_blended_pose(bone_name: String) -> Quaternion:
	if not _two_hand_poses_cached:
		_cache_two_hand_poses()
	return TwoHandAimPoseConfig.blended_pose_rotation(
		_two_hand_hip_poses,
		_two_hand_ads_poses,
		bone_name,
		_ads_aim_blend
	)


func _has_two_hand_authored_pose(bone_name: String) -> bool:
	if not _two_hand_poses_cached:
		_cache_two_hand_poses()
	return TwoHandAimPoseConfig.has_authored_pose(
		_two_hand_hip_poses,
		_two_hand_ads_poses,
		bone_name
	)


## Stop overriding left-arm smoothing when leaving two-hand aim. Do NOT
## reset_bone_pose — the modifier runs after AnimationTree, so a reset would
## force bind/T-pose for that frame.
func _clear_two_hand_aim_smoothing() -> void:
	for bone_name: String in TwoHandAimPoseConfig.SUPPORT_AIM_BONES:
		_aim_bone_poses_smoothed.erase(bone_name)
	_aim_bone_poses_smoothed.erase(LEFT_SHOULDER_BONE)


func _clear_hip_fire_aim_smoothing() -> void:
	for bone_name: String in HipFireAimPoseConfig.GUN_ARM_SMOOTH_BONES:
		_aim_bone_poses_smoothed.erase(bone_name)
	_aim_bone_poses_smoothed.erase(SHOULDER_BONE)


func _find_body_animation_player() -> AnimationPlayer:
	if _skeleton == null:
		return null
	var armature := _skeleton.get_parent()
	if armature == null:
		return null
	var body := armature.get_parent()
	if body == null:
		return null
	return body.get_node_or_null("AnimationPlayer") as AnimationPlayer


## Apply authored HipFireAim rests only when the clip keys them.
## Missing keys must NOT become identity — that forces bind/T-pose after AnimTree.
## ADS-only torso/shoulder keys fade from the live AnimTree pose → ads rest.
## Rotations only — position keys break rotation-only rests (see authoring doc).
func _apply_hip_fire_authored_rests(bone_names: Array) -> void:
	for bone_name in bone_names:
		var name_str := String(bone_name)
		if name_str not in HipFireAimPoseConfig.REQUIRED_BONES:
			if not _should_apply_optional_hip_fire_bone(name_str):
				continue
		var bone_id := _skeleton.find_bone(name_str)
		if bone_id < 0:
			continue
		_skeleton.set_bone_pose_rotation(bone_id, _get_hip_fire_blended_pose(name_str))


## Optional bones keyed on only one clip: apply when the blend is on that side,
## or when walking (ADS-only torso locks in for hip-walk stability).
func _should_apply_optional_hip_fire_bone(bone_name: String) -> bool:
	if not _hip_fire_poses_cached:
		_cache_hip_fire_poses()
	var has_hip := _hip_fire_poses.has(bone_name)
	var has_ads := _hip_fire_ads_poses.has(bone_name)
	if not has_hip and not has_ads:
		return false
	if has_hip and has_ads:
		return true
	if has_hip:
		return _ads_aim_blend < 0.999
	# ADS-only: ADS blend, or walk lock toward ADS while hip-firing.
	return (
		_ads_aim_blend > 0.001
		or HipFireAimPoseConfig.move_stability_weight(_hip_fire_move_blend) > 0.001
	)


func _get_hip_fire_blended_pose(bone_name: String) -> Quaternion:
	if not _hip_fire_poses_cached:
		_cache_hip_fire_poses()
	var ads_blend := _ads_aim_blend if _hip_fire_aim_enabled else 1.0
	var has_hip := _hip_fire_poses.has(bone_name)
	var has_ads := _hip_fire_ads_poses.has(bone_name)
	# ADS-only optional (Spine etc.): fade AnimTree → authored ads. While
	# hip-walking, also lock toward ADS by move blend (same stable torso as ADS walk).
	if (
		not has_hip
		and has_ads
		and bone_name not in HipFireAimPoseConfig.REQUIRED_BONES
		and _skeleton != null
	):
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id >= 0:
			var from_q := _skeleton.get_bone_pose_rotation(bone_id)
			var to_q: Quaternion = _hip_fire_ads_poses[bone_name] as Quaternion
			var lock_w := HipFireAimPoseConfig.walk_torso_lock_weight(
				_hip_fire_move_blend,
				ads_blend
			)
			return from_q.slerp(to_q, lock_w).normalized()
	var pose := HipFireAimPoseConfig.blended_pose_rotation(
		_hip_fire_poses,
		_hip_fire_ads_poses,
		bone_name,
		ads_blend
	)
	if bone_name == ARM_BONE:
		var offset := _debug_arm_offset_quat(false).slerp(
			_debug_arm_offset_quat(true),
			clampf(ads_blend, 0.0, 1.0)
		)
		pose = (pose * offset).normalized()
	return pose


func _has_hip_fire_authored_pose(bone_name: String) -> bool:
	if not _hip_fire_poses_cached:
		_cache_hip_fire_poses()
	return HipFireAimPoseConfig.has_authored_pose(
		_hip_fire_poses,
		_hip_fire_ads_poses,
		bone_name
	)


func _detect_bone_aim_axis(bone_id: int) -> Vector3:
	return GroyperBodyUtils.detect_bone_child_aim_axis(_skeleton, bone_id)


func _begin_forearm_recoil() -> void:
	var stats := GroyperWeapons.get_stats(_equipped_weapon_id)
	if bool(stats.get("arm_driven_recoil", false)):
		_forearm_recoil_pitch_deg = maxf(float(stats.get("arm_recoil_pitch_deg", 4.2)), 0.0)
		_forearm_recoil_recovery = float(stats.get("arm_recoil_recovery", 5.0))
	else:
		_forearm_recoil_pitch_deg = absf(_forearm_recoil_rotation_deg.x)
		_forearm_recoil_recovery = 16.0
	_forearm_recoil = 1.0


func _update_forearm_recoil(delta: float) -> void:
	if _forearm_recoil <= 0.0001:
		_forearm_recoil = 0.0
		return
	var recovery_step := 1.0 - exp(-_forearm_recoil_recovery * delta)
	_forearm_recoil = lerpf(_forearm_recoil, 0.0, recovery_step)


## World-space muzzle-up kick. Bone-local euler X reads as left/right yaw once the
## two-hand aim pose reorients the forearm, so compose against the aim axis instead.
func _apply_forearm_recoil_offset(pose: Quaternion) -> Quaternion:
	if _forearm_recoil <= 0.0001 or _skeleton == null:
		return pose
	var kick_rad := deg_to_rad(_forearm_recoil_pitch_deg * _forearm_recoil)
	if absf(kick_rad) <= 0.0001:
		return pose
	var bone_id := _skeleton.find_bone(FOREARM_BONE)
	if bone_id < 0:
		return pose

	_skeleton.set_bone_pose_rotation(bone_id, pose)

	var parent_id := _skeleton.get_bone_parent(bone_id)
	var parent_global := _skeleton.global_transform
	if parent_id >= 0:
		parent_global = _skeleton.global_transform * _skeleton.get_bone_global_pose(parent_id)

	var bone_rest := _skeleton.get_bone_rest(bone_id)
	var posed_global_basis := parent_global.basis * bone_rest.basis * Basis(pose)
	var posed_global_rot := posed_global_basis.get_rotation_quaternion()

	var bone_origin := (_skeleton.global_transform * _skeleton.get_bone_global_pose(bone_id)).origin
	var aim_dir := Vector3.ZERO
	if _smoothed_arm_aim_target != Vector3.ZERO:
		aim_dir = _smoothed_arm_aim_target - bone_origin
	if aim_dir.length_squared() < 0.0001 and _owner != null:
		aim_dir = -_owner.global_transform.basis.z
	elif aim_dir.length_squared() >= 0.0001:
		aim_dir = aim_dir.normalized()
	else:
		aim_dir = Vector3.FORWARD

	var pitch_axis := aim_dir.cross(Vector3.UP)
	if pitch_axis.length_squared() < 0.0001:
		pitch_axis = (
			_owner.global_transform.basis.x if _owner != null else Vector3.RIGHT
		)
	else:
		pitch_axis = pitch_axis.normalized()

	# Positive rotation around (aim × up) lifts the muzzle for -Z-forward aim.
	var world_kick := Quaternion(pitch_axis, kick_rad)
	var new_global_rot := world_kick * posed_global_rot
	var parent_rot := parent_global.basis.get_rotation_quaternion()
	var rest_rot := bone_rest.basis.get_rotation_quaternion()
	return (rest_rot.inverse() * parent_rot.inverse() * new_global_rot).normalized()


func _lerp_transform(from: Transform3D, to: Transform3D, alpha: float) -> Transform3D:
	# interpolate_with keeps scale — orthonormalized Basis.slerp was popping
	# GripOffset seats (bow ~1.8×) down to unit mid-transfer.
	return from.interpolate_with(to, clampf(alpha, 0.0, 1.0))


func _slerp_quaternion(from_q: Quaternion, to_q: Quaternion, weight: float) -> Quaternion:
	return from_q.slerp(to_q, weight).normalized()


func _slerp_quat_short(from_q: Quaternion, to_q: Quaternion, weight: float) -> Quaternion:
	## Prefer the shorter arc so raise/holster doesn't swing over the head.
	var a := from_q.normalized()
	var b := to_q.normalized()
	if a.dot(b) < 0.0:
		b = -b
	return a.slerp(b, weight).normalized()


func _safe_quat_between(from_dir: Vector3, to_dir: Vector3) -> Quaternion:
	if from_dir.length_squared() < 0.0001 or to_dir.length_squared() < 0.0001:
		return Quaternion.IDENTITY
	var axis := from_dir.cross(to_dir)
	if axis.length_squared() < 0.0001:
		if from_dir.dot(to_dir) > 0.0:
			return Quaternion.IDENTITY
		axis = from_dir.cross(Vector3.UP)
		if axis.length_squared() < 0.0001:
			axis = from_dir.cross(Vector3.RIGHT)
	return Quaternion(axis.normalized(), from_dir.angle_to(to_dir))


func _clear_reload_state() -> void:
	_reload_phase = OverworldReloadPhase.NONE
	_reload_timer = 0.0
	_reload_load_alpha = 0.0
	_reload_raise_poses.clear()
	_reload_started_from_aim = false
	_reload_aim_stance = false
	# Never reset_bone_pose the left arm here — soft weapon swaps call this and
	# a bind/T-pose flash was visible every 1H↔2H handoff.


func _finish_overworld_reload() -> void:
	_clear_reload_state()
	_draw_state = DrawState.HOLSTERED
	_draw_progress = 0.0
	_clear_raise_cache()
	_clear_arm_aim_smoothing()
	_release_arm_to_animation()
	draw_state_changed.emit(_draw_state)


func _begin_reload_eject() -> void:
	_reload_phase = OverworldReloadPhase.EJECTING
	_reload_timer = 0.0
	if _equipped_weapon_id == GroyperWeapons.Id.REVOLVER and _owner != null:
		var spin_pos := get_muzzle_global_position()
		GameAudio.play_revolver_eject_spin(_owner, spin_pos)
	_spawn_shell_casings()


func _capture_reload_rest_poses() -> void:
	_reload_aim_target = _get_reload_aim_target()
	_reload_cylinder_target = _get_reload_cylinder_target()
	_reload_raise_poses.clear()
	for bone_name: String in AIM_BONES:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id >= 0:
			_reload_raise_poses[bone_name] = _skeleton.get_bone_pose_rotation(bone_id)


func _apply_overworld_reload_pose(delta: float) -> void:
	if (
		_reload_aim_stance
		and _reload_phase in [
			OverworldReloadPhase.TAP_READY,
			OverworldReloadPhase.LOADING,
		]
	):
		_apply_arm_aim(_aim_target, delta)
		if _reload_phase == OverworldReloadPhase.LOADING:
			var swing := sin(_reload_load_alpha * PI)
			_apply_reload_left_arm_swing(swing)
		else:
			# Leave left arm to AnimationTree — reset_bone_pose = bind/T-pose flash.
			pass
		return

	match _reload_phase:
		OverworldReloadPhase.RAISING:
			var alpha := clampf(_reload_timer / RELOAD_RAISE_DURATION, 0.0, 1.0)
			alpha = alpha * alpha * (3.0 - 2.0 * alpha)
			_apply_reload_gun_pose(alpha, 0.0)
		OverworldReloadPhase.EJECTING, OverworldReloadPhase.TAP_READY:
			_apply_reload_gun_pose(1.0, 0.0)
		OverworldReloadPhase.LOADING:
			var swing := sin(_reload_load_alpha * PI)
			_apply_reload_gun_pose(1.0, swing)
		OverworldReloadPhase.HOLSTERING:
			var alpha := 1.0 - clampf(_reload_timer / RELOAD_HOLSTER_DURATION, 0.0, 1.0)
			alpha = alpha * alpha * (3.0 - 2.0 * alpha)
			_apply_reload_gun_pose(alpha, 0.0)


func _apply_reload_gun_pose(gun_alpha: float, left_swing: float) -> void:
	if _reload_raise_poses.is_empty():
		_capture_reload_rest_poses()

	_reload_aim_target = _get_reload_aim_target()
	_reload_cylinder_target = _get_reload_cylinder_target()

	var target_poses := _compute_aim_bone_rotations(_reload_aim_target)
	var eased := gun_alpha * gun_alpha * (3.0 - 2.0 * gun_alpha)
	for bone_name: String in AIM_BONES:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id < 0:
			continue

		var from_q: Quaternion = _reload_raise_poses.get(bone_name, Quaternion.IDENTITY)
		var to_q: Quaternion = target_poses.get(bone_name, Quaternion.IDENTITY)
		if bone_name == HAND_BONE:
			to_q = Quaternion.IDENTITY
		_skeleton.set_bone_pose_rotation(bone_id, from_q.slerp(to_q, eased))

	if left_swing > 0.001:
		_apply_reload_left_arm_swing(left_swing)


func _apply_reload_left_arm_swing(swing: float) -> void:
	var reach_weights := {
		LEFT_ARM_BONE: clampf(swing * 1.15, 0.0, 1.0),
		LEFT_FOREARM_BONE: clampf((swing - 0.08) * 1.2, 0.0, 1.0),
		LEFT_HAND_BONE: clampf((swing - 0.18) * 1.25, 0.0, 1.0),
	}
	var ik_targets := _compute_left_reach_poses(_reload_cylinder_target, swing)

	for bone_name: String in LEFT_AIM_BONES:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id < 0:
			continue

		var bone_alpha: float = reach_weights.get(bone_name, swing)
		if bone_alpha <= 0.0:
			continue

		var current := _skeleton.get_bone_pose_rotation(bone_id)
		var target_pose: Quaternion = ik_targets.get(bone_name, current)
		_skeleton.set_bone_pose_rotation(
			bone_id,
			_slerp_quat_short(current, target_pose, bone_alpha)
		)


func _update_bow_nocked_arrow() -> void:
	if _revolver_grip == null or not GroyperWeapons.is_bow(_equipped_weapon_id):
		return
	var nocked := _revolver_grip.get_node_or_null("NockedArrow") as Node3D
	if nocked == null:
		return
	nocked.visible = _bow_nocked_visible
	# Prop pull tracks draw scrub (arm pose comes from BowAim keys).
	nocked.position.x = lerpf(-0.12, -0.22, _bow_string_hand_alpha)


func _compute_left_reach_poses(target: Vector3, _reach_alpha: float) -> Dictionary:
	var saved: Dictionary = {}
	for bone_name: String in LEFT_AIM_BONES:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id >= 0:
			saved[bone_name] = _skeleton.get_bone_pose_rotation(bone_id)
	_set_left_aim_bones_to_identity()
	var poses := {}
	var arm_id := _skeleton.find_bone(LEFT_ARM_BONE)
	if arm_id >= 0:
		var arm_axis: Vector3 = _bone_aim_axes.get(LEFT_ARM_BONE, Vector3(-1.0, 0.0, 0.0))
		var arm_pose := _compute_bone_pose_toward(arm_id, target, arm_axis)
		poses[LEFT_ARM_BONE] = arm_pose
		_skeleton.set_bone_pose_rotation(arm_id, arm_pose)

	var forearm_id := _skeleton.find_bone(LEFT_FOREARM_BONE)
	if forearm_id >= 0:
		var forearm_axis: Vector3 = _bone_aim_axes.get(LEFT_FOREARM_BONE, Vector3(-1.0, 0.0, 0.0))
		var forearm_pose := _compute_bone_pose_toward(forearm_id, target, forearm_axis)
		poses[LEFT_FOREARM_BONE] = forearm_pose
		_skeleton.set_bone_pose_rotation(forearm_id, forearm_pose)

	var hand_id := _skeleton.find_bone(LEFT_HAND_BONE)
	if hand_id >= 0:
		poses[LEFT_HAND_BONE] = saved.get(LEFT_HAND_BONE, _skeleton.get_bone_pose_rotation(hand_id))
	else:
		poses[LEFT_HAND_BONE] = Quaternion.IDENTITY
	for bone_name: Variant in saved.keys():
		var restore_id := _skeleton.find_bone(String(bone_name))
		if restore_id >= 0:
			_skeleton.set_bone_pose_rotation(restore_id, saved[bone_name])
	return poses


func _set_left_aim_bones_to_identity() -> void:
	for bone_name: String in LEFT_AIM_BONES:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id >= 0:
			_skeleton.set_bone_pose_rotation(bone_id, Quaternion.IDENTITY)


func _get_reload_shoulder_origin() -> Vector3:
	if _skeleton != null:
		var shoulder_id := _skeleton.find_bone(SHOULDER_BONE)
		if shoulder_id >= 0:
			return (
				_skeleton.global_transform * _skeleton.get_bone_global_pose(shoulder_id)
			).origin
	return _owner.global_position + Vector3(0.0, 1.15, 0.0) if _owner != null else Vector3.ZERO


func _get_reload_forward_direction() -> Vector3:
	# Overworld player rotates Model, not the CharacterBody3D root — never use _owner.basis.
	if _aim_target.length_squared() > 0.0001:
		var from_shoulder := _aim_target - _get_reload_shoulder_origin()
		if from_shoulder.length_squared() > 0.0001:
			return from_shoulder.normalized()

	if _skeleton != null:
		var skeleton_forward := -_skeleton.global_transform.basis.z
		skeleton_forward.y = 0.0
		if skeleton_forward.length_squared() > 0.0001:
			return skeleton_forward.normalized()

	return Vector3.FORWARD


func _get_reload_aim_target() -> Vector3:
	var origin := _get_reload_shoulder_origin()
	return origin + _get_reload_forward_direction() * 0.42 + Vector3(0.0, 0.06, 0.0)


func _get_reload_cylinder_target() -> Vector3:
	if _revolver_grip != null and is_instance_valid(_revolver_grip):
		var grip := _revolver_grip.global_transform
		return grip.origin + grip.basis * Vector3(0.0, 0.07, 0.03)
	return _get_reload_aim_target()


func _spawn_shell_casings() -> void:
	if _revolver_grip == null or _owner == null:
		return

	var scene_root := _owner.get_tree().current_scene
	if scene_root == null:
		return

	var eject_origin := _revolver_grip.global_transform
	eject_origin.origin += eject_origin.basis * Vector3(0.0, 0.08, 0.04)
	var eject_count := _get_reload_eject_particle_count()
	ShellCasingFX.spawn_burst(scene_root, eject_origin, eject_count)


func _get_reload_eject_particle_count() -> int:
	var max_ammo := GroyperWeapons.get_max_ammo(_equipped_weapon_id)
	if GroyperWeapons.uses_per_round_overworld_reload(_equipped_weapon_id):
		return max_ammo
	return clampi(maxi(max_ammo / 3, 4), 4, 10)
