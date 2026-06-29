extends Node3D

signal defeated(hit_info: Dictionary)
signal duel_fault(reason: String)
signal duel_yeller()
signal duel_shot_fired(from: Vector3, to: Vector3)
signal duel_rpg_launched(from: Vector3, direction: Vector3)

## Third-person duel controller.
## Fixed shoulder camera. Hold RMB to draw from the hip holster; release early to cancel.
## Once drawn, mouse moves the reticle and the right arm points at it.
## WASD leans to dodge. Hold Shift + A/D to sidestep along the DuelStreet; tap W/S for a single step.
## Step off the street and you lose the round.
## Space performs a short hop with a leg spread dodge.
##
## Edit in the Godot editor:
##   Hip gun  -> HipHolsterMount / HolsterOffset / RevolverGrip (single weapon instance at rest)
##   Hand gun -> HandRevolverMount (empty socket; weapon reparents here on draw)
##   Camera   -> CameraRig / Camera3D (C = tune camera)
##   Gun grip -> draw weapon, then G = tune aim grip placement

enum CameraMode { FPS, THIRD_PERSON }

enum DrawState { HOLSTERED, DRAWING, HOLSTERING, AIMING }

const SHOT_BEAM := preload("res://characters/groyper/shot_beam.gd")
const BULLET_SCENE := preload("res://gameplay/shooting/bullet.tscn")
const SHOTGUN_PELLET_SCENE := preload("res://gameplay/shooting/shotgun_pellet.tscn")
const RPG_ROCKET_SCENE := preload("res://gameplay/shooting/rpg_rocket.tscn")
const MuzzleFlashFXScript := preload("res://gameplay/fx/muzzle_flash_fx.gd")
const BloodSplatterFXScript := preload("res://gameplay/fx/blood_splatter_fx.gd")
const GameAudio := preload("res://gameplay/audio/game_audio.gd")
const DUEL_RAGDOLL_SCRIPT := preload("res://characters/groyper/groyper_ragdoll.gd")
const DUEL_HAT_SCRIPT := preload("res://characters/groyper/groyper_duel_hat.gd")
const DROPPED_HAT_SCRIPT := preload("res://characters/groyper/groyper_dropped_hat.gd")
const DUEL_HITBOX_SCRIPT := preload("res://characters/groyper/groyper_hitbox.gd")
const DUEL_HIT_TEST := preload("res://gameplay/duel/duel_hit_test.gd")
const GroyperWeapons := preload("res://characters/groyper/groyper_weapons.gd")

const LEAN_BLEND_NODE := &"LeanBlend"
const IDLE_NODE := &"Idle"
const MIX_NODE := &"IdleLeanMix"

const JUMP_DODGE_LIBRARY := &"jump_dodge"
const JUMP_DODGE_ANIM_NODE := &"JumpDodgeAnim"
const JUMP_DODGE_ONE_SHOT := &"JumpDodgeOneShot"

const STEP_DODGE_LIBRARY := &"step_dodge"
const STEP_DODGE_BLEND_NODE := &"StepDodgeBlend"
const STEP_DODGE_ONE_SHOT := &"StepDodgeOneShot"

const LEAN_SMOOTH := 9.0
const LEAN_BLEND_SMOOTH := 10.0
const LEAN_RELEASE_SMOOTH := 5.5
const LEAN_OPPOSING_SMOOTH := 4.5
const LEAN_MIN_DEPTH := 0.22

const JUMP_DODGE_DURATION := 0.55
const JUMP_DODGE_COOLDOWN := 0.85
const JUMP_DODGE_HEIGHT := 0.28
const JUMP_DODGE_LEG_SPREAD_DEG := 42.0

const STEP_DODGE_DURATION := 0.38
const STEP_DODGE_COOLDOWN := 0.12
const STEP_DODGE_DISTANCE := 0.42
const STEP_LATERAL_LIMIT := 1.35
const STEP_FORWARD_LIMIT := 0.85

const ARM_BONE := "RightArm"
const FOREARM_BONE := "RightForeArm"
const HAND_BONE := "RightHand"
const AIM_IK_BONES := [ARM_BONE, FOREARM_BONE]
## Gun aim only twists the upper arm; forearm stays at neutral rest for a straight arm line.
const GUN_AIM_IK_BONES := [ARM_BONE]
const AIM_BONES := [ARM_BONE, FOREARM_BONE, HAND_BONE]
const ARM_AIM_MODIFIER_SCRIPT := preload("res://characters/groyper/groyper_arm_aim_modifier.gd")
const RigAnimConfig := preload("res://characters/groyper/rig_anim_config.gd")
const RigAnimUtils := preload("res://characters/groyper/rig_anim_utils.gd")
const TwoHandAimPoseConfig := preload("res://characters/groyper/two_hand_aim_pose_config.gd")

const FPS_MOUSE_SENSITIVITY := 0.0022
const FPS_PITCH_MIN := deg_to_rad(-78.0)
const FPS_PITCH_MAX := deg_to_rad(78.0)

const RETICLE_RECOIL_KICK_PX := 14.0

const SHOT_RANGE := 140.0

const DUEL_BODY_AIM_ZONES := {
	"head": {"bone": "Head", "offset": Vector3(0.0, 0.06, 0.05)},
	"chest": {"bone": "Spine02", "offset": Vector3(0.0, 0.1, 0.06)},
	"gut": {"bone": "Spine01", "offset": Vector3(0.0, 0.04, 0.05)},
	"left_shoulder": {"bone": "LeftShoulder", "offset": Vector3(-0.06, 0.02, 0.03)},
	"right_shoulder": {"bone": "RightShoulder", "offset": Vector3(0.06, 0.02, 0.03)},
}
const RECOIL_RECOVERY := 9.0

const DRAW_GRAB_THRESHOLD := 0.68

@export_group("Camera Mode")
@export var camera_mode: CameraMode = CameraMode.THIRD_PERSON

@export_group("Third Person Camera")
@export var tps_rig_offset: Vector3 = Vector3(0.0, 1.10, 0.0)
@export var tps_camera_offset: Vector3 = Vector3(0.85, 0.0, 1.45)
@export_range(-45.0, 45.0, 0.1) var tps_camera_pitch_deg: float = -7.5
@export_range(30.0, 110.0, 0.5) var tps_camera_fov: float = 80.0
@export var enable_camera_tuning: bool = true

const CAMERA_TUNE_STEP := 0.05
const CAMERA_TUNE_STEP_FAST := 0.2
const CAMERA_TUNE_STEP_FINE := 0.01
const CAMERA_TUNE_FOV_STEP := 1.0
const CAMERA_TUNE_PITCH_STEP := 0.5

const GUN_GRIP_TUNE_STEP := 0.005
const GUN_GRIP_TUNE_STEP_FAST := 0.02
const GUN_GRIP_TUNE_STEP_FINE := 0.001
const GUN_GRIP_ROT_STEP := 1.0

@export_group("Reticle")
@export_range(0.15, 0.45, 0.01) var reticle_max_screen_fraction: float = 0.32
@export_range(0.5, 8.0, 0.1) var reticle_mouse_accel: float = 2.4
@export_range(1.0, 12.0, 0.25) var reticle_drag: float = 4.8
@export_range(80.0, 800.0, 10.0) var reticle_max_speed_px: float = 280.0
@export_range(2.0, 24.0, 0.5) var reticle_smooth: float = 6.5

@export_group("Lean")
@export_range(0.1, 1.5, 0.05) var lean_hold_time_to_max: float = 0.75
@export_range(0.05, 0.5, 0.01) var lean_min_depth: float = LEAN_MIN_DEPTH

@export_group("Jump Dodge")
@export_range(0.25, 0.9, 0.05) var jump_dodge_duration: float = JUMP_DODGE_DURATION
@export_range(0.4, 1.5, 0.05) var jump_dodge_cooldown: float = JUMP_DODGE_COOLDOWN
@export_range(0.1, 0.6, 0.01) var jump_dodge_height: float = JUMP_DODGE_HEIGHT
@export_range(20.0, 70.0, 1.0) var jump_dodge_leg_spread_deg: float = JUMP_DODGE_LEG_SPREAD_DEG

@export_group("Step Dodge")
@export_range(0.2, 0.7, 0.02) var step_dodge_duration: float = STEP_DODGE_DURATION
@export_range(0.0, 0.4, 0.02) var step_dodge_cooldown: float = STEP_DODGE_COOLDOWN
@export_range(0.15, 0.9, 0.02) var step_dodge_distance: float = STEP_DODGE_DISTANCE
@export_range(0.5, 2.5, 0.05) var step_lateral_limit: float = STEP_LATERAL_LIMIT
@export_range(0.3, 1.5, 0.05) var step_forward_limit: float = STEP_FORWARD_LIMIT
@export_range(0.05, 0.35, 0.01) var step_anim_fadein_time: float = 0.14
@export_range(0.05, 0.35, 0.01) var step_anim_fadeout_time: float = 0.18
@export_range(0.0, 0.25, 0.01) var step_move_blend_in_time: float = 0.1

@export_group("Weapon Draw")
@export_range(0.2, 1.2, 0.05) var draw_duration: float = 0.48
@export_range(0.15, 0.8, 0.05) var holster_cancel_duration: float = 0.32
@export_range(0.4, 0.9, 0.01) var draw_grab_threshold: float = DRAW_GRAB_THRESHOLD
@export var holster_reach_offset: Vector3 = Vector3(0.0, 0.06, 0.02)
@export_range(0.0, 0.8, 0.01) var holster_reach_outward: float = GroyperBodyUtils.DEFAULT_HOLSTER_REACH_OUTWARD
@export_range(0.0, 0.5, 0.01) var holster_reach_forward: float = GroyperBodyUtils.DEFAULT_HOLSTER_REACH_FORWARD
@export_range(0.0, 0.5, 0.01) var holster_reach_down: float = GroyperBodyUtils.DEFAULT_HOLSTER_REACH_DOWN
@export_range(0.0, 0.9, 0.01) var holster_reach_inward_start: float = GroyperBodyUtils.DEFAULT_HOLSTER_REACH_INWARD_START
@export_range(0.0, 60.0, 1.0) var holster_reach_abduct_deg: float = GroyperBodyUtils.DEFAULT_HOLSTER_REACH_ABDUCT_DEG

@export_group("Hand Gun Grip (Aim)")
@export var enable_gun_grip_tuning: bool = true
@export var hand_grip_position: Vector3 = Vector3(-0.10, -0.05, -0.08)
@export var hand_grip_rotation_deg: Vector3 = Vector3(-161.0, 13.0, -160.0)

@export_group("Aim Camera Feel")
@export_range(0.0, 12.0, 0.25) var aim_fov_reduction: float = 4.0
@export_range(1.0, 24.0, 0.5) var aim_fov_smooth: float = 8.0
@export_range(0.0, 8.0, 0.1) var aim_camera_yaw_deg: float = 2.5
@export_range(0.0, 6.0, 0.1) var aim_camera_pitch_deg: float = 1.5
@export_range(1.0, 16.0, 0.5) var aim_camera_lag_smooth: float = 2.2
@export_range(0.0, 8.0, 0.1) var aim_lean_yaw_deg: float = 2.0
@export_range(0.0, 6.0, 0.1) var aim_lean_pitch_deg: float = 1.2
@export_range(0.0, 5.0, 0.1) var aim_lean_roll_deg: float = 1.5

@export_group("Arm Aim")
@export_range(20.0, 140.0, 1.0) var aim_arm_target_distance: float = 55.0
@export_range(4.0, 32.0, 0.5) var aim_pose_smooth: float = 16.0
@export var holstered_arm_rotation_deg: Vector3 = GroyperBodyUtils.DEFAULT_HOLSTERED_ARM_ROTATION_DEG
@export var holstered_left_arm_rotation_deg: Vector3 = GroyperBodyUtils.DEFAULT_HOLSTERED_LEFT_ARM_ROTATION_DEG
@export var forearm_recoil_rotation_deg: Vector3 = Vector3(-22.0, 0.0, 0.0)
@export_range(4.0, 32.0, 0.5) var forearm_recoil_recovery: float = 16.0

@export_group("Scene Nodes")
@export var rig: Node3D
@export var fps_rig: Node3D
@export var fps_camera: Camera3D
@export var tps_rig: Node3D
@export var tps_camera: Camera3D
@export var reticle_ui: CanvasLayer
@export var reticle: Control
@export var scope_overlay: Control
@export var ammo_hud: AmmoHud
@export var fps_muzzle: Marker3D
@export var hand_muzzle: Marker3D
@export var support_hand: Marker3D

@onready var _body: Node3D = $Model/GroyperRig/Body
@onready var _animation_tree: AnimationTree = $AnimationTree
@onready var _fps_yaw: Node3D = $FpsRig/Yaw
@onready var _fps_pitch: Node3D = $FpsRig/Yaw/Pitch

var _skeleton: Skeleton3D
var _animation_player: AnimationPlayer
var _skeleton_anim_path := NodePath()

var _look_yaw: float = 0.0
var _look_pitch: float = 0.0
var _look_yaw_target: float = 0.0
var _look_pitch_target: float = 0.0

var _reticle_offset_target := Vector2.ZERO
var _reticle_offset := Vector2.ZERO
var _reticle_velocity := Vector2.ZERO
var _reticle_recoil := Vector2.ZERO
var _reticle_limit_px: float = 180.0

var _lean_current: Vector2 = Vector2.ZERO
var _lean_target: Vector2 = Vector2.ZERO
var _lean_blend_amount: float = 0.0
var _lean_hold_time: float = 0.0
var _jump_dodge_active: bool = false
var _jump_dodge_timer: float = 0.0
var _jump_dodge_cooldown: float = 0.0
var _step_dodge_active: bool = false
var _step_dodge_timer: float = 0.0
var _step_dodge_cooldown: float = 0.0
var _step_dodge_duration_active: float = STEP_DODGE_DURATION
var _step_dodge_start: Vector3 = Vector3.ZERO
var _step_dodge_end: Vector3 = Vector3.ZERO
var _step_dodge_direction: Vector2 = Vector2.ZERO
var _replay_step_scrub_time: float = -1.0
var _stance_anchor: Vector3 = Vector3.ZERO
var _rig_base_y: float = 0.0
var _fps_rig_base_y: float = 0.0
var _shot_cooldown: float = 0.0
var _ammo: int = 6
var _equipped_weapon: GroyperWeapons.Id = GroyperWeapons.DEFAULT_WEAPON
var _fire_held := false
var _bone_aim_axes: Dictionary = {}
var _aim_target: Vector3 = Vector3.ZERO
var _smoothed_arm_aim_target: Vector3 = Vector3.ZERO
var _aim_bone_poses_smoothed: Dictionary = {}
var _lean_mix_filter_node: AnimationNodeBlend2
var _weapon_pose_filter_two_handed: bool = false
var _two_hand_neutral_poses: Dictionary = {}
var _forearm_recoil: float = 0.0
var _arm_recoil_angles_deg := Vector3.ZERO
var _arm_recoil_angles_target_deg := Vector3.ZERO
var _spray_spread_bonus_deg := 0.0
var _muzzle_offset_cached: bool = false
var _muzzle_offset_in_hand: Vector3 = Vector3.ZERO
var _pending_shot: bool = false
var _camera_tune_active: bool = false
var _camera_tune_ui: CanvasLayer
var _camera_tune_label: Label
var _gun_grip_tune_active: bool = false
var _gun_grip_tune_label: Label

var _draw_state: DrawState = DrawState.HOLSTERED
var _draw_progress: float = 0.0
var _gun_in_hand: bool = false
var _hip_holster_mount: BoneAttachment3D
var _holster_socket: Node3D
var _hand_revolver_mount: BoneAttachment3D
var _revolver_grip: Node3D
var _holster_grip_local: Transform3D = Transform3D.IDENTITY
var _raise_start_poses: Dictionary = {}
var _raise_aim_target: Vector3 = Vector3.ZERO
var _raise_grip_local_start: Transform3D = Transform3D.IDENTITY

var _tps_fov_current: float = 80.0
var _scope_blend: float = 0.0
var _scope_yaw: float = 0.0
var _scope_pitch: float = 0.0
var _scope_recoil_yaw: float = 0.0
var _scope_recoil_pitch: float = 0.0
var _camera_lag_yaw: float = 0.0
var _camera_lag_pitch: float = 0.0
var _camera_lag_roll: float = 0.0

var _duel_mode := false
var _duel_prep_allowed := false
var _duel_shoot_allowed := false
var _target_mode := false
var _target_prep_allowed := false
var _target_shoot_allowed := false
var _duel_defeated := false
var _duel_fault_pending := false
var _duel_yeller_reported := false
var _duel_street_center := Vector3.ZERO
var _duel_street_half_width := 0.0
var _duel_hitbox: StaticBody3D
var _duel_ragdoll
var _duel_hat
var _replay_mode := false
var _replay_force_rpg_loaded := false
var _ragdoll_animations_suspended := false
var _saved_animation_tree_active := true
var _saved_animation_player_active := true
var _saved_animation_tree_process_mode: Node.ProcessMode = Node.PROCESS_MODE_INHERIT
var _saved_animation_player_process_mode: Node.ProcessMode = Node.PROCESS_MODE_INHERIT
var _replay_saved_tree_process_mode: Node.ProcessMode = Node.PROCESS_MODE_INHERIT


func _get_hand_grip_local() -> Transform3D:
	var euler_rad := Vector3(
		deg_to_rad(hand_grip_rotation_deg.x),
		deg_to_rad(hand_grip_rotation_deg.y),
		deg_to_rad(hand_grip_rotation_deg.z)
	)
	return Transform3D(Basis.from_euler(euler_rad, EULER_ORDER_YXZ), hand_grip_position)


func _ready() -> void:
	_bind_scene_nodes()
	GroyperBodyUtils.apply_model_baseline($Model)
	process_priority = 100
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_update_reticle_limit()

	get_viewport().size_changed.connect(_update_reticle_limit)

	_skeleton = GroyperBodyUtils.find_skeleton(_body)
	_animation_player = GroyperBodyUtils.find_animation_player(_body)
	if _skeleton == null or _animation_player == null:
		push_error("GroyperPlayer: missing skeleton or animation player on GroyperRig/Body.")
		return

	_skeleton_anim_path = _animation_player.get_node(_animation_player.root_node).get_path_to(_skeleton)
	_setup_weapon_mounts()
	_cache_bone_aim_axes()
	_build_jump_dodge_library()
	_build_step_dodge_library()
	_setup_animation_tree()
	_cache_two_hand_neutral_poses()
	_update_weapon_pose_filters()
	_rig_base_y = rig.position.y if rig else 0.0
	_fps_rig_base_y = fps_rig.position.y if fps_rig else 0.0
	_apply_tps_camera_settings()
	_tps_fov_current = tps_camera_fov
	_setup_camera_tune_ui()
	_apply_camera_mode()
	_equipped_weapon = GroyperWeapons.get_starting_weapon()
	_ammo = _get_max_ammo()
	if ammo_hud:
		ammo_hud.configure_for_weapon(_equipped_weapon)
		ammo_hud.sync_rounds(_ammo)
	_setup_arm_aim_modifier()
	_setup_duel_hat()


func _setup_duel_hat() -> void:
	if _skeleton == null or _duel_hat != null:
		return
	_duel_hat = DUEL_HAT_SCRIPT.new()
	_duel_hat.name = "DuelHat"
	add_child(_duel_hat)
	_duel_hat.bind_skeleton(_skeleton)
	_duel_hat.prepare_for_round(false)


func _bind_scene_nodes() -> void:
	if rig == null:
		rig = $Model/GroyperRig
	if fps_rig == null:
		fps_rig = $FpsRig
	if fps_camera == null:
		fps_camera = $FpsRig/Yaw/Pitch/FpsCamera
	if tps_rig == null:
		tps_rig = $CameraRig
	if tps_camera == null:
		tps_camera = $CameraRig/Camera3D
	if reticle_ui == null:
		reticle_ui = $ReticleUI
	if reticle == null:
		reticle = $ReticleUI/Reticle
	if scope_overlay == null:
		scope_overlay = $ReticleUI/ScopeOverlay
	if ammo_hud == null:
		ammo_hud = $AmmoHud as AmmoHud
	if fps_muzzle == null:
		_resolve_fps_muzzle()
	_resolve_hand_muzzle()
	_resolve_support_hand()


func _resolve_hand_muzzle() -> Marker3D:
	if _revolver_grip:
		hand_muzzle = _revolver_grip.find_child("Muzzle", true, false) as Marker3D

	if hand_muzzle == null:
		var holster_grip := get_node_or_null(
			"Model/GroyperRig/Body/Armature/Skeleton3D/HipHolsterMount/HolsterOffset/RevolverGrip"
		) as Node3D
		if holster_grip:
			hand_muzzle = holster_grip.find_child("Muzzle", true, false) as Marker3D

	if hand_muzzle == null:
		push_error("GroyperPlayer: could not find hand muzzle marker under GroyperRig.")

	return hand_muzzle


func _resolve_support_hand() -> Marker3D:
	if _revolver_grip != null:
		support_hand = _revolver_grip.find_child(
			String(TwoHandAimPoseConfig.SUPPORT_HAND_MARKER),
			true,
			false
		) as Marker3D
	return support_hand


func _resolve_fps_muzzle() -> Marker3D:
	var fps_viewmodel := get_node_or_null(
		"FpsRig/Yaw/Pitch/FpsCamera/ViewModel/FpsRevolverViewModel"
	) as Node3D
	if fps_viewmodel:
		fps_muzzle = fps_viewmodel.find_child("Muzzle", true, false) as Marker3D
	return fps_muzzle


func _setup_weapon_mounts() -> void:
	if _skeleton == null:
		return

	_hip_holster_mount = _skeleton.get_node_or_null("HipHolsterMount") as BoneAttachment3D
	_holster_socket = _hip_holster_mount.get_node_or_null("HolsterOffset") as Node3D if _hip_holster_mount else null
	_hand_revolver_mount = _skeleton.get_node_or_null("HandRevolverMount") as BoneAttachment3D

	if _holster_socket:
		_revolver_grip = GroyperWeapons.install_holster_grip(
			_holster_socket,
			GroyperWeapons.get_starting_weapon()
		)
	if _revolver_grip == null:
		push_error("GroyperPlayer: could not equip starting weapon on HipHolsterMount.")
		return
	if _hand_revolver_mount == null:
		push_error("GroyperPlayer: could not find HandRevolverMount on skeleton.")
		return

	var fps_viewmodel := get_node_or_null(
		"FpsRig/Yaw/Pitch/FpsCamera/ViewModel/FpsRevolverViewModel"
	) as Node3D
	if fps_viewmodel != null:
		GroyperWeapons.install_fps_grip(fps_viewmodel, GroyperWeapons.get_starting_weapon())
		_resolve_fps_muzzle()

	_holster_grip_local = _revolver_grip.transform
	_gun_in_hand = false
	_draw_state = DrawState.HOLSTERED
	_draw_progress = 0.0
	_apply_holster_grip_transform()
	_resolve_hand_muzzle()
	_sync_rpg_grip_rocket()


func _update_reticle_limit() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	_reticle_limit_px = minf(viewport_size.x, viewport_size.y) * reticle_max_screen_fraction


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_handle_mouse_motion(event.relative)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if _camera_tune_active or _gun_grip_tune_active:
			get_viewport().set_input_as_handled()
		elif Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			if event.pressed:
				_try_shoot()
			_fire_held = event.pressed
			get_viewport().set_input_as_handled()
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			if _camera_tune_active:
				_set_camera_tune_active(false)
				get_viewport().set_input_as_handled()
			elif _gun_grip_tune_active:
				_set_gun_grip_tune_active(false)
				get_viewport().set_input_as_handled()
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		elif event.keycode == KEY_V:
			camera_mode = CameraMode.THIRD_PERSON if camera_mode == CameraMode.FPS else CameraMode.FPS
			_apply_camera_mode()
		elif enable_camera_tuning and event.keycode == KEY_C and camera_mode == CameraMode.THIRD_PERSON:
			_set_camera_tune_active(not _camera_tune_active)
			get_viewport().set_input_as_handled()
		elif enable_gun_grip_tuning and event.keycode == KEY_G and _can_tune_gun_grip():
			_set_gun_grip_tune_active(not _gun_grip_tune_active)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_SPACE and not _camera_tune_active and not _gun_grip_tune_active:
			_try_jump_dodge()
			get_viewport().set_input_as_handled()
		elif not event.echo and Input.is_key_pressed(KEY_SHIFT) and not _camera_tune_active \
				and not _gun_grip_tune_active:
			var step_direction := _keycode_to_lean_direction(event.keycode)
			if step_direction != Vector2.ZERO and _try_step_dodge(step_direction):
				get_viewport().set_input_as_handled()
		elif _camera_tune_active and event.keycode == KEY_P:
			_print_camera_tune_values()
			get_viewport().set_input_as_handled()
		elif _gun_grip_tune_active and event.keycode == KEY_P:
			_print_gun_grip_tune_values()
			get_viewport().set_input_as_handled()
	elif _camera_tune_active and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			tps_camera_offset.z -= _get_camera_tune_step()
			_apply_tps_camera_settings()
			_update_camera_tune_label()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			tps_camera_offset.z += _get_camera_tune_step()
			_apply_tps_camera_settings()
			_update_camera_tune_label()
			get_viewport().set_input_as_handled()


func _handle_mouse_motion(relative: Vector2) -> void:
	if _camera_tune_active or _gun_grip_tune_active:
		return
	if camera_mode == CameraMode.FPS:
		_look_yaw_target -= relative.x * FPS_MOUSE_SENSITIVITY
		_look_pitch_target = clamp(
			_look_pitch_target - relative.y * FPS_MOUSE_SENSITIVITY,
			FPS_PITCH_MIN,
			FPS_PITCH_MAX
		)
	else:
		if _can_use_reticle():
			if _is_scope_aim_active():
				_apply_scope_look(relative)
			else:
				_reticle_velocity += relative * reticle_mouse_accel


func _is_scope_aim_active() -> bool:
	return (
		GroyperWeapons.has_scope_aim(_equipped_weapon)
		and _is_weapon_aim_ready()
		and _gun_in_hand
	)


func _apply_scope_look(relative: Vector2) -> void:
	var sens := GroyperWeapons.get_scope_mouse_sensitivity(_equipped_weapon)
	var yaw_max := deg_to_rad(GroyperWeapons.get_scope_yaw_max_deg(_equipped_weapon))
	var pitch_max := deg_to_rad(GroyperWeapons.get_scope_pitch_max_deg(_equipped_weapon))
	_scope_yaw = clampf(_scope_yaw - relative.x * sens, -yaw_max, yaw_max)
	_scope_pitch = clampf(_scope_pitch - relative.y * sens, -pitch_max, pitch_max)


func _seed_scope_aim_from_reticle() -> void:
	if _reticle_limit_px <= 0.0:
		_reset_reticle_state()
		return

	var yaw_max := GroyperWeapons.get_scope_yaw_max_deg(_equipped_weapon)
	var pitch_max := GroyperWeapons.get_scope_pitch_max_deg(_equipped_weapon)
	_scope_yaw = deg_to_rad(_reticle_offset.x / _reticle_limit_px * yaw_max)
	_scope_pitch = deg_to_rad(-_reticle_offset.y / _reticle_limit_px * pitch_max)
	_reset_reticle_state()


func _reset_scope_aim() -> void:
	_scope_yaw = 0.0
	_scope_pitch = 0.0
	_scope_recoil_yaw = 0.0
	_scope_recoil_pitch = 0.0
	if reticle:
		reticle.visible = true


func _clamp_reticle_offset(offset: Vector2) -> Vector2:
	if offset.length() <= _reticle_limit_px:
		return offset
	return offset.normalized() * _reticle_limit_px


func _process(delta: float) -> void:
	if _replay_mode:
		return
	if _skeleton == null or _duel_defeated:
		return

	_shot_cooldown = maxf(_shot_cooldown - delta, 0.0)
	_jump_dodge_cooldown = maxf(_jump_dodge_cooldown - delta, 0.0)
	_step_dodge_cooldown = maxf(_step_dodge_cooldown - delta, 0.0)
	_reticle_recoil = _reticle_recoil.lerp(Vector2.ZERO, 1.0 - exp(-RECOIL_RECOVERY * delta))
	_scope_recoil_yaw = lerpf(_scope_recoil_yaw, 0.0, 1.0 - exp(-RECOIL_RECOVERY * delta))
	_scope_recoil_pitch = lerpf(_scope_recoil_pitch, 0.0, 1.0 - exp(-RECOIL_RECOVERY * delta))
	_update_forearm_recoil(delta)
	_update_spray_spread(delta)

	_update_jump_dodge(delta)
	_update_step_dodge(delta)
	_try_continue_lateral_step_walk()
	_check_duel_street_bounds()
	_update_lean(delta)
	_update_weapon_pose_filters_if_needed()
	_apply_lean_animation_tree()
	_update_weapon_draw(delta)

	if _fire_held and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_fire_held = false
	if _fire_held and _can_hold_full_auto():
		_try_shoot()

	if _camera_tune_active:
		_update_camera_tune(delta)

	if _gun_grip_tune_active:
		_update_gun_grip_tune(delta)

	if camera_mode == CameraMode.THIRD_PERSON and not _camera_tune_active and not _gun_grip_tune_active:
		_update_scope_blend(delta)
		_update_aim_camera_feel(delta)

	if camera_mode == CameraMode.FPS:
		_update_fps_look(delta)
	else:
		if _can_use_reticle():
			_update_reticle(delta)
			_aim_target = get_arm_aim_world_target()
		elif _is_weapon_raising():
			_aim_target = _raise_aim_target
		elif reticle and reticle.has_method("set_screen_offset"):
			_reset_reticle_state()
			reticle.set_screen_offset(Vector2.ZERO)


func _setup_arm_aim_modifier() -> void:
	if _skeleton == null:
		return
	var existing := _skeleton.get_node_or_null("ArmAimModifier")
	if existing != null:
		existing.queue_free()
	var modifier = ARM_AIM_MODIFIER_SCRIPT.new()
	modifier.name = "ArmAimModifier"
	modifier.apply_overrides = _late_apply_pose_overrides
	_skeleton.add_child(modifier)


func _late_apply_pose_overrides(delta: float) -> void:
	if _replay_mode:
		return
	if _skeleton == null or camera_mode != CameraMode.THIRD_PERSON:
		return
	if is_ragdoll_pose_active() or _duel_defeated:
		return

	if _duel_mode and not _duel_defeated:
		_sync_duel_hitbox_position()

	match _draw_state:
		DrawState.AIMING:
			_apply_arm_aim(_aim_target, delta)
		DrawState.DRAWING, DrawState.HOLSTERING:
			_apply_draw_pose(_draw_progress)
			if _needs_holstered_support_arm():
				_apply_holstered_support_arm_pose()
		DrawState.HOLSTERED:
			if _should_hold_holstered_arm_pose():
				_reset_aim_bone_poses()
			else:
				_clear_holstered_arm_overrides()

	if _pending_shot:
		_pending_shot = false
		_fire_shot()


func _update_fps_look(delta: float) -> void:
	var step := 1.0 - exp(-20.0 * delta)
	_look_yaw = lerpf(_look_yaw, _look_yaw_target, step)
	_look_pitch = lerpf(_look_pitch, _look_pitch_target, step)

	_fps_yaw.rotation.y = _look_yaw
	_fps_pitch.rotation.x = _look_pitch


func _reset_reticle_state() -> void:
	_reticle_offset = Vector2.ZERO
	_reticle_offset_target = Vector2.ZERO
	_reticle_velocity = Vector2.ZERO


func _apply_reticle_boundary_velocity() -> void:
	var clamped := _clamp_reticle_offset(_reticle_offset_target)
	if clamped.is_equal_approx(_reticle_offset_target):
		return
	var push := _reticle_offset_target - clamped
	if push.length_squared() < 0.001:
		return
	var boundary_normal := push.normalized()
	var outward := _reticle_velocity.dot(boundary_normal)
	if outward > 0.0:
		_reticle_velocity -= boundary_normal * outward
	_reticle_offset_target = clamped


func _update_reticle(delta: float) -> void:
	if _is_scope_aim_active():
		_reticle_velocity = Vector2.ZERO
		_reticle_offset_target = Vector2.ZERO
		var step := 1.0 - exp(-reticle_smooth * delta)
		_reticle_offset = _reticle_offset.lerp(Vector2.ZERO, step)
		if reticle:
			reticle.visible = false
			reticle.set_screen_offset(Vector2.ZERO)
		return

	if reticle:
		reticle.visible = true

	_reticle_velocity *= exp(-reticle_drag * delta)
	var speed := _reticle_velocity.length()
	if speed > reticle_max_speed_px:
		_reticle_velocity = _reticle_velocity * (reticle_max_speed_px / speed)

	_reticle_offset_target += _reticle_velocity * delta
	_apply_reticle_boundary_velocity()

	var step := 1.0 - exp(-reticle_smooth * delta)
	var target := _clamp_reticle_offset(_reticle_offset_target + _reticle_recoil)
	_reticle_offset = _reticle_offset.lerp(target, step)

	if reticle and reticle.has_method("set_screen_offset"):
		reticle.set_screen_offset(_reticle_offset)


func _apply_camera_mode() -> void:
	var fps := camera_mode == CameraMode.FPS

	if fps and _camera_tune_active:
		_set_camera_tune_active(false)

	if fps and _gun_grip_tune_active:
		_set_gun_grip_tune_active(false)

	fps_rig.visible = fps
	fps_camera.current = fps
	tps_camera.current = not fps
	tps_rig.visible = not fps
	rig.visible = not fps
	reticle_ui.visible = not fps and _can_use_reticle()

	if not fps:
		_reset_reticle_state()
		_reset_scope_aim()
		_scope_blend = 0.0
		if scope_overlay and scope_overlay.has_method("set_scope_blend"):
			scope_overlay.set_scope_blend(0.0)
		_camera_lag_yaw = 0.0
		_camera_lag_pitch = 0.0
		_camera_lag_roll = 0.0
		_tps_fov_current = tps_camera_fov
		_update_reticle(1.0)


func _get_aim_camera_blend() -> float:
	if _can_dodge_lean():
		return maxf(_get_weapon_aim_camera_blend(), _lean_blend_amount)
	return _get_weapon_aim_camera_blend()


func _get_weapon_aim_camera_blend() -> float:
	match _draw_state:
		DrawState.AIMING:
			return 1.0
		DrawState.DRAWING, DrawState.HOLSTERING:
			return _draw_progress
		_:
			return 0.0


func _can_dodge_lean() -> bool:
	return _duel_mode and _duel_shoot_allowed and not _duel_defeated


func _get_aim_lean_camera_offset() -> Vector3:
	if not _is_weapon_aim_ready() and not _can_dodge_lean():
		return Vector3.ZERO

	var applied := _lean_current * _lean_blend_amount
	return Vector3(
		-applied.x * aim_lean_yaw_deg,
		-applied.y * aim_lean_pitch_deg,
		applied.x * aim_lean_roll_deg
	)


func _update_scope_blend(delta: float) -> void:
	var target := 0.0
	if GroyperWeapons.has_scope_aim(_equipped_weapon) and _is_weapon_aim_ready() and _gun_in_hand:
		target = 1.0

	var smooth := GroyperWeapons.get_scope_transition_smooth(_equipped_weapon)
	var step := 1.0 - exp(-smooth * delta)
	_scope_blend = lerpf(_scope_blend, target, step)

	if scope_overlay and scope_overlay.has_method("set_scope_blend"):
		scope_overlay.set_scope_blend(_scope_blend)


func _update_aim_camera_feel(delta: float) -> void:
	var blend := _get_aim_camera_blend()
	var weapon_fov_reduction := GroyperWeapons.get_aim_fov_reduction(_equipped_weapon, aim_fov_reduction)
	var normal_aim_fov := tps_camera_fov - weapon_fov_reduction
	var scoped_fov := GroyperWeapons.get_scope_fov(_equipped_weapon)
	var aim_fov := lerpf(tps_camera_fov, normal_aim_fov, blend)
	var target_fov := lerpf(aim_fov, scoped_fov, _scope_blend)
	var fov_step := 1.0 - exp(-aim_fov_smooth * delta)
	_tps_fov_current = lerpf(_tps_fov_current, target_fov, fov_step)

	var target_yaw := 0.0
	var target_pitch := 0.0
	var target_roll := 0.0
	if _is_weapon_aim_ready():
		if _is_scope_aim_active():
			target_yaw = rad_to_deg(_scope_yaw + _scope_recoil_yaw)
			target_pitch = rad_to_deg(_scope_pitch + _scope_recoil_pitch)
		else:
			var inv_limit := 1.0 / maxf(_reticle_limit_px, 1.0)
			target_yaw = _reticle_offset.x * inv_limit * aim_camera_yaw_deg
			target_pitch = -_reticle_offset.y * inv_limit * aim_camera_pitch_deg

	if _is_weapon_aim_ready() or _can_dodge_lean():
		var lean_offset := _get_aim_lean_camera_offset()
		target_yaw += lean_offset.x
		target_pitch += lean_offset.y
		target_roll = lean_offset.z

	var lag_step := 1.0 - exp(-aim_camera_lag_smooth * delta)
	_camera_lag_yaw = lerpf(_camera_lag_yaw, target_yaw * blend, lag_step)
	_camera_lag_pitch = lerpf(_camera_lag_pitch, target_pitch * blend, lag_step)
	_camera_lag_roll = lerpf(_camera_lag_roll, target_roll * blend, lag_step)

	_apply_tps_camera_settings()


func _apply_tps_camera_settings() -> void:
	if tps_rig:
		tps_rig.position = tps_rig_offset
		tps_rig.rotation_degrees.y = _camera_lag_yaw
	if tps_camera:
		tps_camera.position = tps_camera_offset
		tps_camera.rotation_degrees.x = tps_camera_pitch_deg + _camera_lag_pitch
		tps_camera.rotation_degrees.z = _camera_lag_roll
		tps_camera.fov = _tps_fov_current if camera_mode == CameraMode.THIRD_PERSON else tps_camera_fov


func _setup_camera_tune_ui() -> void:
	_camera_tune_ui = CanvasLayer.new()
	_camera_tune_ui.name = "CameraTuneUI"
	_camera_tune_ui.layer = 100
	add_child(_camera_tune_ui)

	_camera_tune_label = Label.new()
	_camera_tune_label.name = "CameraTuneLabel"
	_camera_tune_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_camera_tune_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_camera_tune_label.add_theme_font_size_override("font_size", 14)
	_camera_tune_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
	_camera_tune_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	_camera_tune_label.add_theme_constant_override("shadow_offset_x", 1)
	_camera_tune_label.add_theme_constant_override("shadow_offset_y", 1)
	_camera_tune_ui.add_child(_camera_tune_label)

	_gun_grip_tune_label = Label.new()
	_gun_grip_tune_label.name = "GunGripTuneLabel"
	_gun_grip_tune_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_gun_grip_tune_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_gun_grip_tune_label.add_theme_font_size_override("font_size", 14)
	_gun_grip_tune_label.add_theme_color_override("font_color", Color(0.85, 1.0, 0.75))
	_gun_grip_tune_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	_gun_grip_tune_label.add_theme_constant_override("shadow_offset_x", 1)
	_gun_grip_tune_label.add_theme_constant_override("shadow_offset_y", 1)
	_camera_tune_ui.add_child(_gun_grip_tune_label)

	_camera_tune_ui.visible = false
	_update_camera_tune_label()
	_update_gun_grip_tune_label()


func _set_camera_tune_active(active: bool) -> void:
	if active:
		_set_gun_grip_tune_active(false)
		_camera_lag_yaw = 0.0
		_camera_lag_pitch = 0.0
		_camera_lag_roll = 0.0
	_camera_tune_active = active
	if _camera_tune_ui:
		_camera_tune_ui.visible = active or _gun_grip_tune_active
		_camera_tune_label.visible = active
		_gun_grip_tune_label.visible = _gun_grip_tune_active
	if active:
		_update_camera_tune_label()
		print("Camera tuning enabled. Press P to print values, Esc to exit.")


func _can_tune_gun_grip() -> bool:
	return (
		camera_mode == CameraMode.THIRD_PERSON
		and _draw_state == DrawState.AIMING
		and _gun_in_hand
	)


func _set_gun_grip_tune_active(active: bool) -> void:
	if active and not _can_tune_gun_grip():
		return
	if active:
		_set_camera_tune_active(false)
	_gun_grip_tune_active = active
	if _camera_tune_ui:
		_camera_tune_ui.visible = active or _camera_tune_active
		_camera_tune_label.visible = _camera_tune_active
		_gun_grip_tune_label.visible = active
	if active:
		_update_gun_grip_tune_label()
		print("Gun grip tuning enabled. Press P to print values, Esc to exit.")


func _get_gun_grip_tune_step() -> float:
	if Input.is_key_pressed(KEY_SHIFT):
		return GUN_GRIP_TUNE_STEP_FINE
	if Input.is_key_pressed(KEY_CTRL):
		return GUN_GRIP_TUNE_STEP_FAST
	return GUN_GRIP_TUNE_STEP


func _get_gun_grip_rot_step() -> float:
	var step := GUN_GRIP_ROT_STEP
	if Input.is_key_pressed(KEY_SHIFT):
		step = 0.25
	elif Input.is_key_pressed(KEY_CTRL):
		step = 3.0
	return step


func _update_gun_grip_tune(_delta: float) -> void:
	var pos_step := _get_gun_grip_tune_step()
	var rot_step := _get_gun_grip_rot_step()
	var changed := false

	if Input.is_key_pressed(KEY_LEFT):
		hand_grip_position.x -= pos_step
		changed = true
	if Input.is_key_pressed(KEY_RIGHT):
		hand_grip_position.x += pos_step
		changed = true
	if Input.is_key_pressed(KEY_UP):
		hand_grip_position.z -= pos_step
		changed = true
	if Input.is_key_pressed(KEY_DOWN):
		hand_grip_position.z += pos_step
		changed = true
	if Input.is_key_pressed(KEY_PAGEUP):
		hand_grip_position.y += pos_step
		changed = true
	if Input.is_key_pressed(KEY_PAGEDOWN):
		hand_grip_position.y -= pos_step
		changed = true
	if Input.is_key_pressed(KEY_BRACKETLEFT):
		hand_grip_rotation_deg.x -= rot_step
		changed = true
	if Input.is_key_pressed(KEY_BRACKETRIGHT):
		hand_grip_rotation_deg.x += rot_step
		changed = true
	if Input.is_key_pressed(KEY_MINUS):
		hand_grip_rotation_deg.y -= rot_step
		changed = true
	if Input.is_key_pressed(KEY_EQUAL):
		hand_grip_rotation_deg.y += rot_step
		changed = true
	if Input.is_key_pressed(KEY_Q):
		hand_grip_rotation_deg.z -= rot_step
		changed = true
	if Input.is_key_pressed(KEY_E):
		hand_grip_rotation_deg.z += rot_step
		changed = true

	if changed:
		_apply_hand_grip_transform()
		_invalidate_muzzle_cache()
		_update_gun_grip_tune_label()


func _update_gun_grip_tune_label() -> void:
	if _gun_grip_tune_label == null:
		return

	_gun_grip_tune_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_gun_grip_tune_label.position = Vector2(16.0, 16.0)
	_gun_grip_tune_label.text = """Gun Grip Tuning (G toggle, Esc exit, P print)
Arrows: grip offset X/Z
PgUp/PgDn: grip offset Y
[/]: rotation X
-/=: rotation Y
Q/E: rotation Z
Shift/Ctrl: fine/fast steps

hand_grip_position = %s
hand_grip_rotation_deg = %s""" % [
		_format_vector3(hand_grip_position),
		_format_vector3(hand_grip_rotation_deg),
	]


func _print_gun_grip_tune_values() -> void:
	var grip := _get_hand_grip_local()
	print("--- Hand Gun Grip Defaults (Aim) ---")
	print("hand_grip_position = Vector3%s" % _format_vector3(hand_grip_position))
	print("hand_grip_rotation_deg = Vector3%s" % _format_vector3(hand_grip_rotation_deg))
	print("hand_grip_transform = Transform3D%s" % _format_transform3d(grip))
	print("Copy these into GroyperPlayer inspector exports or groyper_player.tscn.")


func _format_transform3d(value: Transform3D) -> String:
	var bx := value.basis.x
	var by := value.basis.y
	var bz := value.basis.z
	return "(%.7f, %.7f, %.7f, %.7f, %.7f, %.7f, %.7f, %.7f, %.7f, %.2f, %.2f, %.2f)" % [
		bx.x, by.x, bz.x,
		bx.y, by.y, bz.y,
		bx.z, by.z, bz.z,
		value.origin.x, value.origin.y, value.origin.z,
	]


func _apply_hand_grip_transform() -> void:
	if _revolver_grip == null or not _gun_in_hand:
		return

	_revolver_grip.transform = _get_hand_grip_local()


func _apply_holster_grip_transform() -> void:
	if _revolver_grip == null or _gun_in_hand:
		return

	_revolver_grip.transform = _holster_grip_local


func _get_camera_tune_step() -> float:
	if Input.is_key_pressed(KEY_SHIFT):
		return CAMERA_TUNE_STEP_FINE
	if Input.is_key_pressed(KEY_CTRL):
		return CAMERA_TUNE_STEP_FAST
	return CAMERA_TUNE_STEP


func _update_camera_tune(_delta: float) -> void:
	var step := _get_camera_tune_step()
	var changed := false

	if Input.is_key_pressed(KEY_LEFT):
		tps_camera_offset.x -= step
		changed = true
	if Input.is_key_pressed(KEY_RIGHT):
		tps_camera_offset.x += step
		changed = true
	if Input.is_key_pressed(KEY_UP):
		tps_camera_offset.z -= step
		changed = true
	if Input.is_key_pressed(KEY_DOWN):
		tps_camera_offset.z += step
		changed = true
	if Input.is_key_pressed(KEY_PAGEUP):
		tps_camera_offset.y += step
		changed = true
	if Input.is_key_pressed(KEY_PAGEDOWN):
		tps_camera_offset.y -= step
		changed = true
	if Input.is_key_pressed(KEY_Q):
		tps_rig_offset.y += step
		changed = true
	if Input.is_key_pressed(KEY_E):
		tps_rig_offset.y -= step
		changed = true

	var pitch_step := CAMERA_TUNE_PITCH_STEP
	if Input.is_key_pressed(KEY_SHIFT):
		pitch_step = 0.1
	elif Input.is_key_pressed(KEY_CTRL):
		pitch_step = 2.0
	if Input.is_key_pressed(KEY_BRACKETLEFT):
		tps_camera_pitch_deg -= pitch_step
		changed = true
	if Input.is_key_pressed(KEY_BRACKETRIGHT):
		tps_camera_pitch_deg += pitch_step
		changed = true

	var fov_step := CAMERA_TUNE_FOV_STEP
	if Input.is_key_pressed(KEY_SHIFT):
		fov_step = 0.25
	elif Input.is_key_pressed(KEY_CTRL):
		fov_step = 3.0
	if Input.is_key_pressed(KEY_MINUS):
		tps_camera_fov = maxf(tps_camera_fov - fov_step, 30.0)
		changed = true
	if Input.is_key_pressed(KEY_EQUAL):
		tps_camera_fov = minf(tps_camera_fov + fov_step, 110.0)
		changed = true

	if changed:
		_tps_fov_current = tps_camera_fov
		_apply_tps_camera_settings()
		_update_camera_tune_label()


func _update_camera_tune_label() -> void:
	if _camera_tune_label == null:
		return

	_camera_tune_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_camera_tune_label.position = Vector2(16.0, 16.0)
	_camera_tune_label.text = """Camera Tuning (C toggle, Esc exit, P print)
Arrows: shoulder offset X/Z
PgUp/PgDn: shoulder offset Y
Q/E: rig height
[/]: pitch (%.1f deg)
-/=: FOV (%.1f)
Wheel: distance (Z)
Shift/Ctrl: fine/fast steps

Rig offset: %s
Camera offset: %s""" % [
		tps_camera_pitch_deg,
		tps_camera_fov,
		_format_vector3(tps_rig_offset),
		_format_vector3(tps_camera_offset),
	]


func _format_vector3(value: Vector3) -> String:
	return "(%.2f, %.2f, %.2f)" % [value.x, value.y, value.z]


func _print_camera_tune_values() -> void:
	print("--- Third Person Camera Defaults ---")
	print("tps_rig_offset = Vector3%s" % _format_vector3(tps_rig_offset))
	print("tps_camera_offset = Vector3%s" % _format_vector3(tps_camera_offset))
	print("tps_camera_pitch_deg = %.1f" % tps_camera_pitch_deg)
	print("tps_camera_fov = %.1f" % tps_camera_fov)
	print("Copy these into GroyperPlayer inspector exports or groyper_player.tscn.")


func get_active_camera() -> Camera3D:
	return fps_camera if camera_mode == CameraMode.FPS else tps_camera


func get_reticle_screen_position() -> Vector2:
	if _is_scope_aim_active():
		return get_viewport().get_visible_rect().size * 0.5
	return get_viewport().get_visible_rect().size * 0.5 + _reticle_offset


func get_aim_ray_origin() -> Vector3:
	return get_active_camera().project_ray_origin(get_reticle_screen_position())


func get_aim_direction() -> Vector3:
	return get_active_camera().project_ray_normal(get_reticle_screen_position()).normalized()


func get_aim_world_target() -> Vector3:
	var origin := get_aim_ray_origin()
	var direction := get_aim_direction()

	var space_state := get_world_3d().direct_space_state
	if space_state:
		var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * SHOT_RANGE)
		query.collide_with_areas = false
		var hit := space_state.intersect_ray(query)
		if not hit.is_empty():
			return hit.position

	return origin + direction * SHOT_RANGE


func get_duel_aim_point() -> Vector3:
	return get_duel_body_aim_point("chest")


func get_random_duel_body_aim_zone() -> String:
	var zone_ids := DUEL_BODY_AIM_ZONES.keys()
	if zone_ids.is_empty():
		return "chest"
	return zone_ids[randi() % zone_ids.size()]


func get_duel_body_aim_point(zone_id: String) -> Vector3:
	var zone: Dictionary = DUEL_BODY_AIM_ZONES.get(zone_id, DUEL_BODY_AIM_ZONES["chest"])
	var bone_name: String = zone.get("bone", "Spine02")
	var offset: Vector3 = zone.get("offset", Vector3.ZERO)

	if _skeleton == null:
		return global_position + Vector3(0.0, 1.25, 0.0) + offset

	var bone_id := _skeleton.find_bone(bone_name)
	if bone_id < 0:
		return global_position + Vector3(0.0, 1.25, 0.0) + offset

	var bone_global := _skeleton.global_transform * _skeleton.get_bone_global_pose(bone_id)
	return bone_global.origin + bone_global.basis * offset


func _sync_duel_hitbox_position() -> void:
	if _duel_hitbox == null:
		return
	_duel_hitbox.global_transform = _get_duel_hurtbox_transform()


func _get_duel_hurtbox_transform() -> Transform3D:
	if _skeleton == null:
		var no_skeleton := global_transform
		no_skeleton.origin = global_position + Vector3(0.0, 1.05, 0.0)
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
	fallback.origin = global_position + Vector3(0.0, 1.05, 0.0)
	return fallback


func _get_duel_hurtbox_center() -> Vector3:
	return _get_duel_hurtbox_transform().origin


func get_arm_aim_world_target() -> Vector3:
	var origin := get_aim_ray_origin()
	var direction := get_aim_direction()
	return origin + direction * aim_arm_target_distance


func get_muzzle_global_position() -> Vector3:
	if camera_mode == CameraMode.FPS and fps_muzzle:
		return fps_muzzle.global_position

	_resolve_hand_muzzle()
	if hand_muzzle != null and is_instance_valid(hand_muzzle):
		return hand_muzzle.global_position

	if _skeleton == null:
		push_error("GroyperPlayer: muzzle unavailable for third-person shot.")
		return global_position

	push_error("GroyperPlayer: muzzle unavailable for third-person shot.")
	return global_position


func get_muzzle_forward_direction() -> Vector3:
	_resolve_hand_muzzle()
	if hand_muzzle != null and is_instance_valid(hand_muzzle):
		var forward := hand_muzzle.global_transform.basis.x
		if forward.length_squared() > 0.0001:
			return forward.normalized()
	return get_aim_direction()


func _cache_muzzle_hand_offset() -> void:
	_resolve_hand_muzzle()
	var hand_id := _skeleton.find_bone(HAND_BONE)
	if hand_id < 0 or hand_muzzle == null:
		return

	var hand_global := _skeleton.global_transform * _skeleton.get_bone_global_pose(hand_id)
	_muzzle_offset_in_hand = hand_global.basis.inverse() * (hand_muzzle.global_position - hand_global.origin)
	_muzzle_offset_cached = true


func _cache_bone_aim_axes() -> void:
	_bone_aim_axes.clear()
	var bones_to_cache: Array[String] = []
	bones_to_cache.append_array(AIM_BONES)
	for bone_name: String in TwoHandAimPoseConfig.SUPPORT_AIM_BONES:
		if bone_name not in bones_to_cache:
			bones_to_cache.append(bone_name)
	for bone_name: String in bones_to_cache:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id >= 0:
			_bone_aim_axes[bone_name] = GroyperBodyUtils.detect_bone_child_aim_axis(_skeleton, bone_id)


func _get_gun_arm_aim_axis() -> Vector3:
	var forearm_pose := Quaternion.IDENTITY
	var hand_pose := Quaternion.IDENTITY
	if _uses_two_hand_arm_aim():
		forearm_pose = _get_authored_neutral_pose(FOREARM_BONE)
		hand_pose = _get_authored_neutral_pose(HAND_BONE)
	return GroyperBodyUtils.detect_gun_arm_aim_axis(
		_skeleton,
		ARM_BONE,
		FOREARM_BONE,
		HAND_BONE,
		forearm_pose,
		hand_pose
	)


func _detect_bone_aim_axis(bone_id: int) -> Vector3:
	return GroyperBodyUtils.detect_bone_child_aim_axis(_skeleton, bone_id)


func _is_weapon_aim_ready() -> bool:
	return camera_mode == CameraMode.FPS or _draw_state == DrawState.AIMING


func _is_two_handed_weapon_equipped() -> bool:
	return GroyperWeapons.is_two_handed(_equipped_weapon)


func _uses_two_hand_arm_aim() -> bool:
	return _is_two_handed_weapon_equipped() and _gun_in_hand


func _get_support_hand_world_target() -> Vector3:
	_resolve_support_hand()
	if support_hand != null and is_instance_valid(support_hand):
		return support_hand.global_position
	return _smoothed_arm_aim_target


func _cache_two_hand_neutral_poses() -> void:
	_two_hand_neutral_poses = _load_authored_pose_rotations(
		TwoHandAimPoseConfig.get_animation_path()
	)
	if _two_hand_neutral_poses.is_empty():
		push_warning(
			"GroyperPlayer: no TwoHandAim/neutral pose loaded — two-hand draw will fall back to straight arm IK."
		)


func _load_authored_pose_rotations(animation_path: StringName) -> Dictionary:
	var poses := {}
	if _animation_player == null or not _animation_player.has_animation(animation_path):
		return poses

	var animation := _animation_player.get_animation(animation_path)
	if animation == null:
		return poses

	for track_idx in animation.get_track_count():
		if animation.track_get_type(track_idx) != Animation.TYPE_ROTATION_3D:
			continue
		var node_path := String(animation.track_get_path(track_idx))
		var bone_name := node_path
		if ":" in node_path:
			bone_name = node_path.substr(node_path.rfind(":") + 1)
		if animation.track_get_key_count(track_idx) <= 0:
			continue
		var key_value: Variant = animation.track_get_key_value(track_idx, 0)
		if key_value is Quaternion:
			poses[bone_name] = key_value
	return poses


func _get_authored_neutral_pose(bone_name: String) -> Quaternion:
	return _two_hand_neutral_poses.get(bone_name, Quaternion.IDENTITY) as Quaternion


func _apply_gun_arm_neutral_rest() -> void:
	for bone_name in AIM_BONES:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id < 0:
			continue
		var rest_pose := Quaternion.IDENTITY
		if _uses_two_hand_arm_aim():
			rest_pose = _get_authored_neutral_pose(bone_name)
		_skeleton.set_bone_pose_rotation(bone_id, rest_pose)


func _apply_support_arm_neutral_rest() -> void:
	for bone_name: String in TwoHandAimPoseConfig.SUPPORT_AIM_BONES:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id >= 0:
			_skeleton.set_bone_pose_rotation(bone_id, _get_authored_neutral_pose(bone_name))


func _update_weapon_pose_filters() -> void:
	if _lean_mix_filter_node == null:
		return
	TwoHandAimPoseConfig.configure_lean_mix_filter(
		_lean_mix_filter_node,
		_uses_two_hand_arm_aim()
	)


func _update_weapon_pose_filters_if_needed() -> void:
	var active := _uses_two_hand_arm_aim()
	if active == _weapon_pose_filter_two_handed:
		return
	_weapon_pose_filter_two_handed = active
	_update_weapon_pose_filters()


func _needs_holstered_support_arm() -> bool:
	if not _is_two_handed_weapon_equipped():
		return false
	if not _gun_in_hand:
		return true
	if _draw_state == DrawState.DRAWING and _draw_progress < draw_grab_threshold:
		return true
	if _draw_state == DrawState.HOLSTERING and _draw_progress < draw_grab_threshold:
		return true
	return false


func _get_holstered_support_bone_pose(bone_name: String) -> Quaternion:
	return GroyperBodyUtils.holstered_support_arm_pose_rotation(
		bone_name,
		holstered_left_arm_rotation_deg
	)


func _apply_holstered_support_arm_pose() -> void:
	for bone_name: String in TwoHandAimPoseConfig.SUPPORT_AIM_BONES:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id >= 0:
			_skeleton.set_bone_pose_rotation(bone_id, _get_holstered_support_bone_pose(bone_name))


func _can_fire_weapon() -> bool:
	if camera_mode == CameraMode.FPS:
		return true
	return _draw_state == DrawState.AIMING or _draw_state == DrawState.DRAWING


func _is_duel_prep_active() -> bool:
	return _duel_mode and _duel_prep_allowed and not _duel_shoot_allowed


func _is_target_prep_active() -> bool:
	return _target_mode and _target_prep_allowed and not _target_shoot_allowed


func _is_countdown_prep_active() -> bool:
	return _is_duel_prep_active() or _is_target_prep_active()


func _can_use_reticle() -> bool:
	return _is_weapon_aim_ready()


func _is_weapon_raising() -> bool:
	return (
		camera_mode == CameraMode.THIRD_PERSON
		and _draw_state == DrawState.DRAWING
		and _draw_progress >= draw_grab_threshold
	)


func _update_weapon_draw(delta: float) -> void:
	if _duel_mode:
		if not _duel_prep_allowed and not _duel_shoot_allowed:
			return
		if _duel_prep_allowed and not _duel_shoot_allowed:
			_update_weapon_draw_prep(delta)
			return
	elif _target_mode:
		if not _target_prep_allowed and not _target_shoot_allowed:
			return
		if _target_prep_allowed and not _target_shoot_allowed:
			_update_weapon_draw_prep(delta)
			return

	if camera_mode != CameraMode.THIRD_PERSON or _revolver_grip == null:
		return

	var rmb_held := (
		Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
		and not _camera_tune_active
		and not _gun_grip_tune_active
	)
	var previous_state := _draw_state

	match _draw_state:
		DrawState.HOLSTERED:
			if rmb_held:
				_draw_state = DrawState.DRAWING

		DrawState.DRAWING:
			if rmb_held:
				_draw_progress = minf(_draw_progress + delta / draw_duration, 1.0)
				if not _gun_in_hand and _draw_progress >= draw_grab_threshold:
					_attach_gun_to_hand()
				if _draw_progress >= 1.0:
					_draw_state = DrawState.AIMING
					_snap_gun_grip_to_hand()
					_clear_raise_cache()
			elif _draw_progress < draw_grab_threshold:
				_draw_state = DrawState.HOLSTERING
			else:
				_draw_state = DrawState.AIMING
				_draw_progress = 1.0
				_snap_gun_grip_to_hand()

		DrawState.HOLSTERING:
			_draw_progress = maxf(_draw_progress - delta / holster_cancel_duration, 0.0)
			if _draw_progress <= 0.0:
				_draw_state = DrawState.HOLSTERED
				_draw_progress = 0.0
				_clear_raise_cache()

		DrawState.AIMING:
			pass

	if previous_state != _draw_state:
		_update_draw_ui()
		if _draw_state == DrawState.AIMING and previous_state != DrawState.AIMING:
			_seed_arm_aim_smoothing()
			GameAudio.play_revolver_aim(self, get_muzzle_global_position())
			if GroyperWeapons.has_scope_aim(_equipped_weapon):
				_seed_scope_aim_from_reticle()
		elif _draw_state != DrawState.AIMING:
			_clear_arm_aim_smoothing()
			_reset_scope_aim()
			_scope_blend = 0.0
			if scope_overlay and scope_overlay.has_method("set_scope_blend"):
				scope_overlay.set_scope_blend(0.0)


func _update_weapon_draw_prep(delta: float) -> void:
	if camera_mode != CameraMode.THIRD_PERSON or _revolver_grip == null:
		return

	var rmb_held := (
		Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
		and not _camera_tune_active
		and not _gun_grip_tune_active
	)
	var max_reach := maxf(draw_grab_threshold - 0.04, 0.1)
	var previous_state := _draw_state

	match _draw_state:
		DrawState.HOLSTERED:
			if rmb_held:
				_draw_state = DrawState.DRAWING
		DrawState.DRAWING:
			if rmb_held:
				var next_progress := _draw_progress + delta / draw_duration
				if next_progress >= draw_grab_threshold:
					_report_duel_fault("early_draw")
					_draw_state = DrawState.HOLSTERING
				else:
					_draw_progress = minf(next_progress, max_reach)
			else:
				_draw_state = DrawState.HOLSTERING
		DrawState.HOLSTERING:
			_draw_progress = maxf(_draw_progress - delta / holster_cancel_duration, 0.0)
			if _draw_progress <= 0.0:
				_draw_state = DrawState.HOLSTERED
				_draw_progress = 0.0
				_clear_raise_cache()
		DrawState.AIMING:
			_draw_state = DrawState.HOLSTERING

	if previous_state != _draw_state:
		_update_draw_ui()


func _update_draw_ui() -> void:
	if reticle_ui:
		reticle_ui.visible = camera_mode == CameraMode.THIRD_PERSON and _can_use_reticle()


func _attach_gun_to_hand() -> void:
	if _duel_mode and _duel_prep_allowed and not _duel_shoot_allowed:
		_report_duel_fault("early_draw")
		return
	if _gun_in_hand or _revolver_grip == null or _hand_revolver_mount == null:
		return

	var holster_target := _get_holster_reach_target()
	var grip_global := _revolver_grip.global_transform
	_cache_raise_start_poses(holster_target)

	_revolver_grip.reparent(_hand_revolver_mount, true)
	_revolver_grip.global_transform = grip_global
	_raise_grip_local_start = _revolver_grip.transform
	_gun_in_hand = true
	_invalidate_muzzle_cache()
	_resolve_hand_muzzle()
	_resolve_support_hand()
	_weapon_pose_filter_two_handed = not _uses_two_hand_arm_aim()
	_raise_aim_target = get_aim_world_target()


func _clear_raise_cache() -> void:
	_raise_start_poses.clear()
	_raise_aim_target = Vector3.ZERO
	_raise_grip_local_start = Transform3D.IDENTITY


func _invalidate_muzzle_cache() -> void:
	_muzzle_offset_cached = false


func _snap_gun_grip_to_hand() -> void:
	if _gun_in_hand and _revolver_grip != null:
		_revolver_grip.transform = _get_hand_grip_local()
		_invalidate_muzzle_cache()


func _apply_draw_pose(progress: float) -> void:
	var clamped := clampf(progress, 0.0, 1.0)
	if clamped < draw_grab_threshold:
		var reach_alpha := clamped / draw_grab_threshold
		reach_alpha = reach_alpha * reach_alpha * (3.0 - 2.0 * reach_alpha)
		_apply_reach_toward_holster(reach_alpha)
	else:
		var raise_alpha := inverse_lerp(draw_grab_threshold, 1.0, clamped)
		raise_alpha = raise_alpha * raise_alpha * (3.0 - 2.0 * raise_alpha)
		_apply_raise_pose(raise_alpha)


func _get_holster_reach_target() -> Vector3:
	if _revolver_grip == null or not is_instance_valid(_revolver_grip):
		return global_position

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
			rest_pose.slerp(target_pose, bone_alpha)
		)


func _get_reach_rest_pose(bone_name: String, rest_fade: float) -> Quaternion:
	var holstered := _get_holstered_bone_pose(bone_name)
	return holstered.slerp(Quaternion.IDENTITY, 1.0 - rest_fade)


func _set_aim_bones_to_identity() -> void:
	_apply_gun_arm_neutral_rest()


func _compute_chain_bone_poses_toward(target: Vector3, bone_names: Array) -> Dictionary:
	_apply_gun_arm_neutral_rest()
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

	poses[HAND_BONE] = Quaternion.IDENTITY
	return poses


func _cache_raise_start_poses(holster_target: Vector3) -> void:
	_apply_reach_toward_target(1.0, holster_target)
	_raise_start_poses = _capture_raise_arm_poses()


func _capture_raise_arm_poses() -> Dictionary:
	var poses := _capture_aim_bone_rotations()
	if not _is_two_handed_weapon_equipped():
		return poses
	for bone_name: String in TwoHandAimPoseConfig.SUPPORT_AIM_BONES:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id >= 0:
			poses[bone_name] = _skeleton.get_bone_pose_rotation(bone_id)
	return poses


func _apply_raise_pose(alpha: float) -> void:
	if _raise_start_poses.is_empty():
		return

	var eased := alpha * alpha * (3.0 - 2.0 * alpha)

	if _is_two_handed_weapon_equipped() and _gun_in_hand:
		var bone_names: Array[String] = []
		bone_names.append_array(AIM_BONES)
		for bone_name: String in TwoHandAimPoseConfig.SUPPORT_AIM_BONES:
			if bone_name not in bone_names:
				bone_names.append(bone_name)
		for bone_name: String in bone_names:
			var bone_id := _skeleton.find_bone(bone_name)
			if bone_id < 0:
				continue
			var from_q: Quaternion = _raise_start_poses.get(bone_name, Quaternion.IDENTITY)
			var to_q := _get_authored_neutral_pose(bone_name)
			_skeleton.set_bone_pose_rotation(bone_id, from_q.slerp(to_q, eased))
	else:
		var aim_poses := _compute_aim_bone_rotations(_raise_aim_target)
		for bone_name: String in AIM_BONES:
			var bone_id := _skeleton.find_bone(bone_name)
			if bone_id < 0:
				continue
			var from_q: Quaternion = _raise_start_poses.get(bone_name, Quaternion.IDENTITY)
			var to_q: Quaternion
			if bone_name == HAND_BONE:
				to_q = Quaternion.IDENTITY
			else:
				to_q = aim_poses.get(bone_name, Quaternion.IDENTITY)
			_skeleton.set_bone_pose_rotation(bone_id, from_q.slerp(to_q, eased))

	_apply_gun_grip_raise(eased)


func _apply_gun_grip_raise(alpha: float) -> void:
	if _revolver_grip == null or not _gun_in_hand:
		return

	var target := _get_hand_grip_local()
	if alpha >= 0.999:
		_revolver_grip.transform = target
	else:
		_revolver_grip.transform = _lerp_transform(_raise_grip_local_start, target, alpha)


func _lerp_transform(from: Transform3D, to: Transform3D, alpha: float) -> Transform3D:
	return Transform3D(
		from.basis.slerp(to.basis, alpha).orthonormalized(),
		from.origin.lerp(to.origin, alpha)
	)


func _compute_aim_bone_rotations(world_target: Vector3) -> Dictionary:
	var poses := _compute_chain_bone_poses_toward(world_target, GUN_AIM_IK_BONES)
	poses[FOREARM_BONE] = _get_authored_neutral_pose(FOREARM_BONE) if _uses_two_hand_arm_aim() else Quaternion.IDENTITY
	_set_aim_bones_to_identity()
	return poses


func _capture_aim_bone_rotations() -> Dictionary:
	var poses := {}
	for bone_name: String in AIM_BONES:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id >= 0:
			poses[bone_name] = _skeleton.get_bone_pose_rotation(bone_id)
	return poses


func _compute_bone_pose_toward(bone_id: int, world_target: Vector3, local_aim_axis: Vector3) -> Quaternion:
	var bone_global := _skeleton.global_transform * _skeleton.get_bone_global_pose(bone_id)
	var to_target := world_target - bone_global.origin
	if to_target.length_squared() < 0.04:
		to_target = get_aim_direction()
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

	var rest_global_rot := rest_global_basis.get_rotation_quaternion()
	var new_global_rot := twist * rest_global_rot
	var parent_rot := parent_global.basis.get_rotation_quaternion()
	var rest_rot := bone_rest.basis.get_rotation_quaternion()
	return rest_rot.inverse() * parent_rot.inverse() * new_global_rot


func _clear_arm_aim_smoothing() -> void:
	_smoothed_arm_aim_target = Vector3.ZERO
	_aim_bone_poses_smoothed.clear()


func _seed_arm_aim_smoothing() -> void:
	_aim_bone_poses_smoothed.clear()
	var bones_to_seed: Array[String] = []
	bones_to_seed.append_array(AIM_IK_BONES)
	if _uses_two_hand_arm_aim():
		bones_to_seed.append_array(TwoHandAimPoseConfig.SUPPORT_IK_BONES)
	for bone_name: String in bones_to_seed:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id >= 0:
			_aim_bone_poses_smoothed[bone_name] = _skeleton.get_bone_pose_rotation(bone_id)
	_smoothed_arm_aim_target = get_arm_aim_world_target()


func _get_holstered_bone_pose(bone_name: String) -> Quaternion:
	return GroyperBodyUtils.holstered_bone_pose_rotation(bone_name, holstered_arm_rotation_deg)


func _should_hold_holstered_arm_pose() -> bool:
	return _duel_mode or _target_mode


func _clear_holstered_arm_overrides() -> void:
	for bone_name in AIM_BONES:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id >= 0:
			_skeleton.set_bone_pose_rotation(bone_id, Quaternion.IDENTITY)
	for bone_name: String in TwoHandAimPoseConfig.SUPPORT_AIM_BONES:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id >= 0:
			_skeleton.set_bone_pose_rotation(bone_id, Quaternion.IDENTITY)


func _reset_aim_bone_poses() -> void:
	for bone_name in AIM_BONES:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id >= 0:
			_skeleton.set_bone_pose_rotation(bone_id, _get_holstered_bone_pose(bone_name))
	if _is_two_handed_weapon_equipped():
		_apply_holstered_support_arm_pose()
	else:
		for bone_name: String in TwoHandAimPoseConfig.SUPPORT_AIM_BONES:
			var bone_id := _skeleton.find_bone(bone_name)
			if bone_id >= 0:
				_skeleton.set_bone_pose_rotation(bone_id, Quaternion.IDENTITY)


func _apply_arm_aim(world_target: Vector3, delta: float) -> void:
	var arm_id := _skeleton.find_bone(ARM_BONE)
	var forearm_id := _skeleton.find_bone(FOREARM_BONE)
	if arm_id < 0:
		return

	var smooth_step := 1.0 - exp(-aim_pose_smooth * delta)
	if _smoothed_arm_aim_target == Vector3.ZERO:
		_smoothed_arm_aim_target = world_target
	_smoothed_arm_aim_target = _smoothed_arm_aim_target.lerp(world_target, smooth_step)

	_apply_gun_arm_neutral_rest()

	var aim_point := _smoothed_arm_aim_target
	if arm_id >= 0:
		var arm_axis := _get_gun_arm_aim_axis()
		var arm_target := _compute_bone_pose_toward(arm_id, aim_point, arm_axis)
		var arm_pose: Quaternion = _aim_bone_poses_smoothed.get(ARM_BONE, Quaternion.IDENTITY)
		arm_pose = _slerp_quaternion(arm_pose, arm_target, smooth_step)
		_aim_bone_poses_smoothed[ARM_BONE] = arm_pose
		_skeleton.set_bone_pose_rotation(arm_id, _apply_arm_recoil_offset(arm_pose))

	if forearm_id >= 0:
		var forearm_rest := Quaternion.IDENTITY
		if _uses_two_hand_arm_aim():
			forearm_rest = _get_authored_neutral_pose(FOREARM_BONE)
		var forearm_pose: Quaternion = _aim_bone_poses_smoothed.get(FOREARM_BONE, forearm_rest)
		forearm_pose = _slerp_quaternion(forearm_pose, forearm_rest, smooth_step)
		_aim_bone_poses_smoothed[FOREARM_BONE] = forearm_pose
		_skeleton.set_bone_pose_rotation(forearm_id, _apply_arm_recoil_offset(forearm_pose))

	_lock_hand_aim_pose()
	if _uses_two_hand_arm_aim():
		_apply_support_arm_aim(_get_support_hand_world_target(), delta)


func _apply_support_arm_aim(world_target: Vector3, delta: float) -> void:
	var arm_id := _skeleton.find_bone(TwoHandAimPoseConfig.LEFT_ARM_BONE)
	var forearm_id := _skeleton.find_bone(TwoHandAimPoseConfig.LEFT_FOREARM_BONE)
	if arm_id < 0:
		return

	var smooth_step := 1.0 - exp(-aim_pose_smooth * delta)
	_apply_support_arm_neutral_rest()

	if arm_id >= 0:
		var arm_axis: Vector3 = _bone_aim_axes.get(
			TwoHandAimPoseConfig.LEFT_ARM_BONE,
			Vector3(-1.0, 0.0, 0.0)
		)
		var arm_target := _compute_bone_pose_toward(arm_id, world_target, arm_axis)
		var arm_pose: Quaternion = _aim_bone_poses_smoothed.get(
			TwoHandAimPoseConfig.LEFT_ARM_BONE,
			Quaternion.IDENTITY
		)
		arm_pose = _slerp_quaternion(arm_pose, arm_target, smooth_step)
		_aim_bone_poses_smoothed[TwoHandAimPoseConfig.LEFT_ARM_BONE] = arm_pose
		_skeleton.set_bone_pose_rotation(arm_id, arm_pose)

	if forearm_id >= 0:
		var forearm_axis: Vector3 = _bone_aim_axes.get(
			TwoHandAimPoseConfig.LEFT_FOREARM_BONE,
			Vector3(-1.0, 0.0, 0.0)
		)
		var forearm_target := _compute_bone_pose_toward(forearm_id, world_target, forearm_axis)
		var forearm_pose: Quaternion = _aim_bone_poses_smoothed.get(
			TwoHandAimPoseConfig.LEFT_FOREARM_BONE,
			Quaternion.IDENTITY
		)
		forearm_pose = _slerp_quaternion(forearm_pose, forearm_target, smooth_step)
		_aim_bone_poses_smoothed[TwoHandAimPoseConfig.LEFT_FOREARM_BONE] = forearm_pose
		_skeleton.set_bone_pose_rotation(forearm_id, forearm_pose)

	var hand_id := _skeleton.find_bone(TwoHandAimPoseConfig.LEFT_HAND_BONE)
	if hand_id >= 0:
		_skeleton.set_bone_pose_rotation(hand_id, _get_authored_neutral_pose(TwoHandAimPoseConfig.LEFT_HAND_BONE))


func _lock_hand_aim_pose() -> void:
	var hand_id := _skeleton.find_bone(HAND_BONE)
	if hand_id >= 0:
		var hand_pose := Quaternion.IDENTITY
		if _uses_two_hand_arm_aim():
			hand_pose = _get_authored_neutral_pose(HAND_BONE)
		_skeleton.set_bone_pose_rotation(hand_id, hand_pose)


func _trigger_forearm_recoil() -> void:
	var stats := GroyperWeapons.get_stats(_equipped_weapon)
	var pitch_kick := float(stats.get("arm_recoil_pitch_deg", -1.0))
	var yaw_jitter := float(stats.get("arm_recoil_yaw_jitter_deg", -1.0))

	if pitch_kick < 0.0:
		var strength := float(stats.get("forearm_recoil_strength", 1.0))
		pitch_kick = absf(forearm_recoil_rotation_deg.x) * strength
		if yaw_jitter < 0.0:
			yaw_jitter = float(stats.get("forearm_recoil_wobble_deg", 0.0)) * strength

	if yaw_jitter < 0.0:
		yaw_jitter = 0.0

	var impulse := Vector3(
		-pitch_kick,
		randf_range(-yaw_jitter, yaw_jitter),
		randf_range(-yaw_jitter * 0.35, yaw_jitter * 0.35)
	)
	_arm_recoil_angles_target_deg += impulse

	var max_recoil := float(stats.get("arm_recoil_max_deg", 28.0))
	if _arm_recoil_angles_target_deg.length() > max_recoil:
		_arm_recoil_angles_target_deg = _arm_recoil_angles_target_deg.normalized() * max_recoil

	# Legacy replay scalar — magnitude of current arm recoil stack.
	_forearm_recoil = clampf(_arm_recoil_angles_target_deg.length() / maxf(max_recoil, 1.0), 0.0, 1.0)


func _update_forearm_recoil(delta: float) -> void:
	var stats := GroyperWeapons.get_stats(_equipped_weapon)
	var recovery := float(stats.get("arm_recoil_recovery", forearm_recoil_recovery))
	var smooth := float(stats.get("arm_recoil_smooth", 18.0))

	var decay_step := 1.0 - exp(-recovery * delta)
	_arm_recoil_angles_target_deg = _arm_recoil_angles_target_deg.lerp(Vector3.ZERO, decay_step)

	var follow_step := 1.0 - exp(-smooth * delta)
	_arm_recoil_angles_deg = _arm_recoil_angles_deg.lerp(_arm_recoil_angles_target_deg, follow_step)

	var max_recoil := float(stats.get("arm_recoil_max_deg", 28.0))
	_forearm_recoil = clampf(_arm_recoil_angles_deg.length() / maxf(max_recoil, 1.0), 0.0, 1.0)


func _apply_arm_recoil_offset(pose: Quaternion) -> Quaternion:
	if _arm_recoil_angles_deg.length_squared() < 0.0001:
		return pose

	var recoil_q := Quaternion.from_euler(Vector3(
		deg_to_rad(_arm_recoil_angles_deg.x),
		deg_to_rad(_arm_recoil_angles_deg.y),
		deg_to_rad(_arm_recoil_angles_deg.z)
	))
	return pose * recoil_q


func _apply_shot_recoil() -> void:
	var stats := GroyperWeapons.get_stats(_equipped_weapon)
	if bool(stats.get("arm_driven_recoil", false)):
		var spread_build := float(stats.get("aim_spread_build_per_shot", 0.0))
		if spread_build > 0.0:
			var spread_max := float(stats.get("aim_spread_max_bonus_deg", 0.0))
			_spray_spread_bonus_deg = minf(spread_max, _spray_spread_bonus_deg + spread_build)
		return

	var kick := float(stats.get("reticle_recoil_kick", RETICLE_RECOIL_KICK_PX))
	var randomness := float(stats.get("reticle_recoil_randomness", 0.25))

	if _is_scope_aim_active():
		var kick_rad := deg_to_rad(kick * 0.035)
		if randomness >= 0.95:
			var angle := randf() * TAU
			var magnitude := kick_rad * randf_range(0.8, 1.45)
			_scope_recoil_yaw += cos(angle) * magnitude
			_scope_recoil_pitch += sin(angle) * magnitude
		else:
			_scope_recoil_pitch += kick_rad
			_scope_recoil_yaw += deg_to_rad(randf_range(-kick * randomness, kick * randomness) * 0.035)
	elif randomness >= 0.95:
		var angle := randf() * TAU
		var magnitude := kick * randf_range(0.8, 1.45)
		_reticle_recoil += Vector2(cos(angle), sin(angle)) * magnitude
	else:
		_reticle_recoil.y += kick
		_reticle_recoil.x += randf_range(-kick * randomness, kick * randomness)

	var spread_build := float(stats.get("aim_spread_build_per_shot", 0.0))
	if spread_build > 0.0:
		var spread_max := float(stats.get("aim_spread_max_bonus_deg", 0.0))
		_spray_spread_bonus_deg = minf(spread_max, _spray_spread_bonus_deg + spread_build)


func _update_spray_spread(delta: float) -> void:
	if _spray_spread_bonus_deg <= 0.0001:
		_spray_spread_bonus_deg = 0.0
		return
	if _fire_held and GroyperWeapons.is_full_auto(_equipped_weapon):
		return

	var decay_step := 1.0 - exp(-10.0 * delta)
	_spray_spread_bonus_deg = lerpf(_spray_spread_bonus_deg, 0.0, decay_step)


func _get_effective_aim_spread_deg() -> float:
	var stats := GroyperWeapons.get_stats(_equipped_weapon)
	return float(stats.get("aim_spread_deg", 0.0)) + _spray_spread_bonus_deg


func _apply_aim_spread(direction: Vector3) -> Vector3:
	var spread_deg := _get_effective_aim_spread_deg()
	if spread_deg <= 0.001:
		return direction.normalized()

	var spread_rad := deg_to_rad(spread_deg)
	var forward := direction.normalized()
	var right := forward.cross(Vector3.UP)
	if right.length_squared() < 0.0001:
		right = forward.cross(Vector3.RIGHT)
	right = right.normalized()
	var up := right.cross(forward).normalized()

	var twist := randf() * TAU
	var radius := sqrt(randf()) * spread_rad
	var offset := right * cos(twist) * sin(radius) + up * sin(twist) * sin(radius)
	return (forward + offset).normalized()


func _point_bone_at(bone_id: int, world_target: Vector3, local_aim_axis: Vector3) -> void:
	var pose_rot := _compute_bone_pose_toward(bone_id, world_target, local_aim_axis)
	_skeleton.set_bone_pose_rotation(bone_id, pose_rot)


func _slerp_quaternion(from_q: Quaternion, to_q: Quaternion, weight: float) -> Quaternion:
	if from_q.dot(to_q) < 0.0:
		to_q = Quaternion(-to_q.x, -to_q.y, -to_q.z, -to_q.w)
	return from_q.slerp(to_q, weight)


func _safe_quat_between(from_dir: Vector3, to_dir: Vector3) -> Quaternion:
	var from := from_dir.normalized()
	var to := to_dir.normalized()
	var dot := clampf(from.dot(to), -1.0, 1.0)
	if dot > 0.99999:
		return Quaternion.IDENTITY
	if dot < -0.99999:
		var axis := from.cross(Vector3.UP)
		if axis.length_squared() < 0.0001:
			axis = from.cross(Vector3.RIGHT)
		return Quaternion(axis.normalized(), PI)
	return Quaternion(from, to)


func _update_lean(delta: float) -> void:
	if _skeleton == null:
		return

	if _is_duel_prep_active():
		_lean_current = Vector2.ZERO
		_lean_target = Vector2.ZERO
		_lean_blend_amount = 0.0
		_lean_hold_time = 0.0
		return

	var lean_input := _read_lean_input()
	_update_lean_hold(lean_input, delta)

	var lean_direction := lean_input
	if lean_direction.length_squared() > 0.0001:
		lean_direction = lean_direction.normalized()

	var hold_depth := _get_lean_hold_depth()
	_lean_target = lean_direction

	if lean_input.length_squared() < 0.0001:
		var release_step := 1.0 - exp(-LEAN_RELEASE_SMOOTH * delta)
		_lean_current = _lean_current.lerp(Vector2.ZERO, release_step)
		_lean_blend_amount = lerpf(_lean_blend_amount, 0.0, release_step)
		if _lean_current.length_squared() < 0.0001:
			_lean_current = Vector2.ZERO
		if _lean_blend_amount < 0.01:
			_lean_blend_amount = 0.0
	else:
		var opposing := (
			_lean_target.length_squared() > 0.0001
			and _lean_current.length_squared() > 0.0001
			and _lean_current.dot(_lean_target) < -0.01
		)
		var direction_lerp_speed := lerpf(LEAN_SMOOTH, LEAN_SMOOTH * 1.6, _lean_blend_amount)
		if opposing:
			direction_lerp_speed = LEAN_OPPOSING_SMOOTH
		var blend_step := 1.0 - exp(-direction_lerp_speed * delta)
		_lean_current = _lean_current.lerp(_lean_target, blend_step)

		var target_blend := hold_depth
		target_blend = maxf(target_blend, _lean_blend_amount)
		var blend_amount_step := 1.0 - exp(-LEAN_BLEND_SMOOTH * delta)
		_lean_blend_amount = lerpf(_lean_blend_amount, target_blend, blend_amount_step)


func _apply_lean_animation_tree() -> void:
	if is_ragdoll_pose_active() or _duel_defeated:
		return
	if _animation_tree == null or not _animation_tree.active:
		return

	var lean_position := _lean_current * _lean_blend_amount
	_animation_tree.set("parameters/%s/blend_position" % LEAN_BLEND_NODE, lean_position)
	_animation_tree.set("parameters/%s/blend_amount" % MIX_NODE, _lean_blend_amount)


func _advance_replay_animation_tree(delta: float) -> void:
	if not _replay_mode or _animation_tree == null or not _animation_tree.active:
		return
	if is_ragdoll_pose_active() or _duel_defeated:
		return
	_animation_tree.advance(delta)


func is_jump_dodging() -> bool:
	return _jump_dodge_active


func is_step_dodging() -> bool:
	return _step_dodge_active


func is_dodging() -> bool:
	return is_jump_dodging() or is_step_dodging() or _lean_blend_amount > lean_min_depth * 0.75


func get_jump_dodge_height_offset() -> float:
	if not _jump_dodge_active:
		return 0.0
	var progress := clampf(_jump_dodge_timer / jump_dodge_duration, 0.0, 1.0)
	return jump_dodge_height * 4.0 * progress * (1.0 - progress)


func _read_lean_input() -> Vector2:
	if _camera_tune_active or _gun_grip_tune_active or _jump_dodge_active or _step_dodge_active:
		return Vector2.ZERO
	if Input.is_key_pressed(KEY_SHIFT):
		return Vector2.ZERO

	var lean := Vector2.ZERO
	if Input.is_key_pressed(KEY_A):
		lean.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		lean.x += 1.0
	if Input.is_key_pressed(KEY_W):
		lean.y += 1.0
	if Input.is_key_pressed(KEY_S):
		lean.y -= 1.0
	if lean.length_squared() > 1.0:
		lean = lean.normalized()
	return lean


func _update_lean_hold(lean_input: Vector2, delta: float) -> void:
	if lean_input.length_squared() < 0.0001:
		var release_step := 1.0 - exp(-LEAN_RELEASE_SMOOTH * delta)
		_lean_hold_time = lerpf(_lean_hold_time, 0.0, release_step)
		if _lean_hold_time < 0.01:
			_lean_hold_time = 0.0
		return

	_lean_hold_time = minf(_lean_hold_time + delta, lean_hold_time_to_max)


func _get_lean_hold_depth() -> float:
	if _lean_hold_time <= 0.0:
		return 0.0

	var hold_progress := clampf(_lean_hold_time / lean_hold_time_to_max, 0.0, 1.0)
	var eased := hold_progress * hold_progress * (3.0 - 2.0 * hold_progress)
	return lerpf(0.0, 1.0, eased)


func _try_shoot() -> void:
	if _duel_mode and not _duel_shoot_allowed:
		return
	if _target_mode and not _target_shoot_allowed:
		return
	if _duel_defeated:
		return
	if _shot_cooldown > 0.0 or _jump_dodge_active or _step_dodge_active:
		return
	if _ammo <= 0:
		return
	if camera_mode == CameraMode.THIRD_PERSON and not _can_fire_weapon():
		return

	_shot_cooldown = GroyperWeapons.get_shot_cooldown(_equipped_weapon)
	_apply_shot_recoil()
	if camera_mode == CameraMode.FPS:
		_fire_shot()
	else:
		_pending_shot = true


func _fire_shot() -> void:
	var origin := get_muzzle_global_position()
	var aim_point := get_aim_world_target()
	var to_reticle := aim_point - origin
	if to_reticle.length_squared() < 0.0001:
		return

	var scene_root := get_tree().current_scene
	if scene_root == null:
		return

	_spawn_muzzle_flash(scene_root, origin)
	GameAudio.play_weapon_shot(_equipped_weapon, scene_root, origin)

	if GroyperWeapons.is_rpg(_equipped_weapon):
		_fire_rpg_rocket(scene_root)
		return

	if GroyperWeapons.get_pellet_count(_equipped_weapon) > 1:
		_fire_shotgun_blast(scene_root, origin, _get_shot_direction(origin, to_reticle))
		return

	var direction := _apply_aim_spread(_get_shot_direction(origin, to_reticle))
	var max_dist := minf(to_reticle.length(), SHOT_RANGE)

	if _duel_mode and _duel_shoot_allowed:
		# Match the reticle/crosshair ray — not the muzzle-to-ground physics ray.
		var aim_origin := get_aim_ray_origin()
		var aim_direction := _apply_aim_spread(get_aim_direction())
		var duel_hit := _cast_duel_shot_hit(aim_origin, aim_direction, SHOT_RANGE)
		if not duel_hit.is_empty():
			var hit_info: Dictionary = duel_hit.hit_info
			var hit_pos: Vector3 = hit_info.position
			SHOT_BEAM.spawn(scene_root, origin, hit_pos)
			duel_shot_fired.emit(origin, hit_pos)
			var target: Node = duel_hit.target
			if target.has_method("receive_bullet_hit"):
				target.receive_bullet_hit(hit_info)
			elif target.has_method("apply_bullet_hit"):
				target.apply_bullet_hit(hit_info)
			_consume_ammo_after_shot()
			return

		var miss_end := origin + aim_direction * minf(max_dist, 12.0)
		SHOT_BEAM.spawn(scene_root, origin, miss_end)
		duel_shot_fired.emit(origin, miss_end)
		_consume_ammo_after_shot()
		return

	var bullet: Node3D = BULLET_SCENE.instantiate()
	scene_root.add_child(bullet)
	var exclude: Array = [self]
	if _duel_hitbox != null:
		exclude.append(_duel_hitbox)
	bullet.setup(
		origin,
		direction,
		exclude,
		self,
		GroyperWeapons.get_bullet_speed(_equipped_weapon),
		GroyperWeapons.get_bullet_scale(_equipped_weapon)
	)

	SHOT_BEAM.spawn(scene_root, origin, origin + direction * 1.2)
	_consume_ammo_after_shot()


func _get_shot_direction(origin: Vector3, to_aim: Vector3) -> Vector3:
	if GroyperWeapons.uses_muzzle_aim(_equipped_weapon) or not _is_weapon_aim_ready():
		var muzzle_dir := get_muzzle_forward_direction()
		if muzzle_dir.length_squared() > 0.0001:
			return muzzle_dir
	if to_aim.length_squared() < 0.0001:
		return get_aim_direction()
	return to_aim.normalized()


func _spawn_muzzle_flash(parent: Node, origin: Vector3) -> void:
	MuzzleFlashFXScript.spawn(parent, origin, GroyperWeapons.get_muzzle_flash_style(_equipped_weapon))


func _consume_ammo_after_shot() -> void:
	_trigger_forearm_recoil()
	_ammo -= 1
	if ammo_hud:
		ammo_hud.sync_rounds(_ammo, true)
	_sync_rpg_grip_rocket()


func _sync_rpg_grip_rocket() -> void:
	if not GroyperWeapons.is_rpg(_equipped_weapon) or _revolver_grip == null:
		return
	const RpgRocketScript := preload("res://gameplay/shooting/rpg_rocket.gd")
	var rocket_visual := RpgRocketScript._find_rocketbullet_node(_revolver_grip)
	if rocket_visual != null:
		rocket_visual.visible = _ammo > 0 or (_replay_mode and _replay_force_rpg_loaded)
		RpgRocketScript.apply_grip_rocket_scale(rocket_visual)


func hide_rpg_grip_rocket_for_replay() -> void:
	_replay_force_rpg_loaded = false
	_sync_rpg_grip_rocket()


func _fire_rpg_rocket(scene_root: Node) -> void:
	var launch := _get_rpg_launch_params()
	if launch.is_empty():
		return

	var origin: Vector3 = launch.origin
	var direction: Vector3 = launch.direction

	var rocket: Node3D = RPG_ROCKET_SCENE.instantiate()
	scene_root.add_child(rocket)

	var exclude: Array = [self]
	if _duel_hitbox != null:
		exclude.append(_duel_hitbox)

	var on_exploded := Callable()
	if _duel_mode and _duel_shoot_allowed:
		duel_rpg_launched.emit(origin, direction)
		on_exploded = Callable(self, "_on_rpg_exploded")

	rocket.setup(origin, direction, exclude, self, on_exploded)
	_consume_ammo_after_shot()


func _get_rpg_launch_params() -> Dictionary:
	var muzzle := get_muzzle_global_position()
	var aim_point := _resolve_rpg_aim_point()

	var to_target := aim_point - muzzle
	if to_target.length_squared() < 0.0001:
		return {}

	return {
		"origin": muzzle,
		"direction": to_target.normalized(),
	}


func _resolve_rpg_aim_point() -> Vector3:
	var aim_origin := get_aim_ray_origin()
	var aim_direction := get_aim_direction()
	var best_t := SHOT_RANGE + 1.0
	var best_point := aim_origin + aim_direction * SHOT_RANGE

	var space_state := get_world_3d().direct_space_state
	if space_state != null:
		var query := PhysicsRayQueryParameters3D.create(
			aim_origin,
			aim_origin + aim_direction * SHOT_RANGE
		)
		query.collide_with_areas = false
		query.collide_with_bodies = true
		if _duel_hitbox != null:
			query.exclude = [_duel_hitbox.get_rid()]
		var world_hit := space_state.intersect_ray(query)
		if not world_hit.is_empty():
			var hit_t := aim_origin.distance_to(world_hit.position)
			if hit_t < best_t:
				best_t = hit_t
				best_point = world_hit.position

	if _duel_mode and _duel_shoot_allowed:
		var duel_hit := _cast_duel_shot_hit(aim_origin, aim_direction, SHOT_RANGE)
		if not duel_hit.is_empty():
			var duel_pos: Vector3 = duel_hit.hit_info.position
			var duel_t := aim_origin.distance_to(duel_pos)
			if duel_t < best_t:
				best_point = duel_pos

	return best_point


func _on_rpg_exploded(from: Vector3, impact: Vector3) -> void:
	SHOT_BEAM.spawn(get_tree().current_scene, from, impact)
	duel_shot_fired.emit(from, impact)


func _fire_shotgun_blast(scene_root: Node, origin: Vector3, base_direction: Vector3) -> void:
	var stats := GroyperWeapons.get_stats(_equipped_weapon)
	var pellet_count := int(stats.get("pellet_count", 6))
	var spread_max_deg := float(stats.get("pellet_spread_max_deg", 14.0))
	var spread_distance := float(stats.get("pellet_spread_distance", 22.0))
	var pellet_offsets := _get_shotgun_pellet_offsets(base_direction, pellet_count)

	if _duel_mode and _duel_shoot_allowed:
		_fire_shotgun_duel(
			scene_root,
			origin,
			base_direction,
			pellet_offsets,
			spread_max_deg
		)
		_consume_ammo_after_shot()
		return

	var exclude: Array = [self]
	if _duel_hitbox != null:
		exclude.append(_duel_hitbox)

	for offset: Vector3 in pellet_offsets:
		var pellet: Node3D = SHOTGUN_PELLET_SCENE.instantiate()
		scene_root.add_child(pellet)
		pellet.setup(
			origin,
			base_direction,
			offset,
			spread_max_deg,
			spread_distance,
			exclude,
			self
		)

	SHOT_BEAM.spawn(scene_root, origin, origin + base_direction * 1.6)
	_consume_ammo_after_shot()


func _fire_shotgun_duel(
	scene_root: Node,
	origin: Vector3,
	base_direction: Vector3,
	pellet_offsets: Array[Vector3],
	spread_max_deg: float
) -> void:
	var aim_origin := get_aim_ray_origin()
	var duel_hits: Array[Dictionary] = []
	var duel_spread_rad := deg_to_rad(spread_max_deg * 0.42)

	for offset: Vector3 in pellet_offsets:
		var pellet_direction := (base_direction + offset * duel_spread_rad).normalized()
		var duel_hit := _cast_duel_shot_hit(aim_origin, pellet_direction, SHOT_RANGE)
		if duel_hit.is_empty():
			continue
		duel_hits.append(duel_hit)

	if duel_hits.is_empty():
		var miss_end := origin + base_direction * 12.0
		SHOT_BEAM.spawn(scene_root, origin, miss_end)
		duel_shot_fired.emit(origin, miss_end)
		return

	var primary_hit: Dictionary = duel_hits[0]
	var primary_pos: Vector3 = primary_hit.hit_info.position
	var primary_dist_sq := aim_origin.distance_squared_to(primary_pos)

	for duel_hit: Dictionary in duel_hits:
		var hit_info: Dictionary = duel_hit.hit_info
		var hit_pos: Vector3 = hit_info.position
		SHOT_BEAM.spawn(scene_root, origin, hit_pos)

		var target: Node = duel_hit.target
		if target.has_method("receive_bullet_hit"):
			target.receive_bullet_hit(hit_info)
		elif target.has_method("apply_bullet_hit"):
			target.apply_bullet_hit(hit_info)

		var dist_sq := aim_origin.distance_squared_to(hit_pos)
		if dist_sq < primary_dist_sq:
			primary_hit = duel_hit
			primary_pos = hit_pos
			primary_dist_sq = dist_sq

	duel_shot_fired.emit(origin, primary_pos)


func _get_shotgun_pellet_offsets(base_direction: Vector3, pellet_count: int) -> Array[Vector3]:
	var offsets: Array[Vector3] = []
	var right := base_direction.cross(Vector3.UP)
	if right.length_squared() < 0.0001:
		right = base_direction.cross(Vector3.RIGHT)
	right = right.normalized()
	var up := right.cross(base_direction).normalized()

	for i in pellet_count:
		var angle := TAU * float(i) / float(pellet_count)
		var ring := randf_range(0.55, 1.0)
		offsets.append((right * cos(angle) + up * sin(angle)) * ring)

	return offsets


func _cast_duel_shot_hit(origin: Vector3, direction: Vector3, max_distance: float) -> Dictionary:
	var best_t := max_distance + 1.0
	var best: Dictionary = {}

	for enemy in get_tree().get_nodes_in_group("duel_enemy"):
		if enemy == null or not is_instance_valid(enemy):
			continue
		if enemy.has_method("is_defeated") and enemy.is_defeated():
			continue
		if not enemy.has_method("get_bullet_capsule"):
			continue

		var capsule: Dictionary = enemy.get_bullet_capsule()
		var center: Vector3 = capsule["center"]
		var half_height: float = capsule["half_height"]
		var radius: float = capsule["radius"] + 0.08
		var axis: Vector3 = capsule.get("axis", Vector3.UP)
		var hit_t := DUEL_HIT_TEST.raycast_capsule(
			origin, direction, max_distance, center, half_height, radius, axis
		)
		if hit_t < 0.0 or hit_t >= best_t:
			continue

		best_t = hit_t
		best = {
			"target": enemy,
			"hit_info": {
				"position": origin + direction * hit_t,
				"normal": -direction,
				"direction": direction,
				"collider": enemy,
				"speed": 185.0,
			},
		}

	var hat_hit := DUEL_HIT_TEST.closest_group_sphere_hit(
		origin,
		direction,
		max_distance,
		DROPPED_HAT_SCRIPT.HAT_PROP_GROUP,
		0.18,
		get_tree()
	)
	if not hat_hit.is_empty():
		var hat_t: float = hat_hit.get("distance", max_distance + 1.0)
		if hat_t < best_t:
			best = {
				"target": hat_hit.collider,
				"hit_info": {
					"position": hat_hit.position,
					"normal": hat_hit.normal,
					"direction": direction,
					"collider": hat_hit.collider,
					"speed": 185.0,
				},
			}

	return best


func _play_idle() -> void:
	var idle_name := _find_idle_animation_name()
	if idle_name.is_empty():
		return
	_animation_player.play(idle_name)


func _try_jump_dodge() -> void:
	if _jump_dodge_active or _jump_dodge_cooldown > 0.0 or _skeleton == null:
		return
	_start_jump_dodge()


func _start_jump_dodge() -> void:
	_jump_dodge_active = true
	_jump_dodge_timer = 0.0
	_jump_dodge_cooldown = jump_dodge_cooldown

	if _animation_tree and _animation_tree.active:
		_animation_tree.set(
			"parameters/%s/request" % JUMP_DODGE_ONE_SHOT,
			AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
		)


func _update_jump_dodge(delta: float) -> void:
	if not _jump_dodge_active:
		return

	_jump_dodge_timer += delta
	var height := get_jump_dodge_height_offset()

	if rig:
		rig.position.y = _rig_base_y + height
	if fps_rig:
		fps_rig.position.y = _fps_rig_base_y + height * 0.35

	if _jump_dodge_timer >= jump_dodge_duration:
		_finish_jump_dodge()


func _finish_jump_dodge() -> void:
	_jump_dodge_active = false
	_jump_dodge_timer = 0.0
	if rig:
		rig.position.y = _rig_base_y
	if fps_rig:
		fps_rig.position.y = _fps_rig_base_y


func _keycode_to_lean_direction(keycode: Key) -> Vector2:
	match keycode:
		KEY_A:
			return Vector2(-1.0, 0.0)
		KEY_D:
			return Vector2(1.0, 0.0)
		KEY_W:
			return Vector2(0.0, 1.0)
		KEY_S:
			return Vector2(0.0, -1.0)
		_:
			return Vector2.ZERO


func _can_step_dodge() -> bool:
	if _skeleton == null or _duel_defeated:
		return false
	if _camera_tune_active or _gun_grip_tune_active:
		return false
	if _jump_dodge_active or _step_dodge_active or _step_dodge_cooldown > 0.0:
		return false
	return true


func _read_lateral_step_input() -> Vector2:
	if not Input.is_key_pressed(KEY_SHIFT):
		return Vector2.ZERO
	if _camera_tune_active or _gun_grip_tune_active or _jump_dodge_active:
		return Vector2.ZERO

	var step := Vector2.ZERO
	if Input.is_key_pressed(KEY_A):
		step.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		step.x += 1.0
	if step.length_squared() < 0.0001:
		return Vector2.ZERO
	return step.normalized()


func _try_continue_lateral_step_walk() -> void:
	if _step_dodge_active:
		return
	var direction := _read_lateral_step_input()
	if direction.length_squared() < 0.0001:
		return
	_try_step_dodge(direction)


func _try_step_dodge(direction: Vector2) -> bool:
	if not _can_step_dodge() or direction.length_squared() < 0.0001:
		return false

	direction = direction.normalized()
	var world_direction := global_transform.basis * Vector3(direction.x, 0.0, direction.y)
	world_direction.y = 0.0
	if world_direction.length_squared() < 0.0001:
		return false
	world_direction = world_direction.normalized()

	var travel_duration := _get_step_travel_duration(direction)
	var travel_distance := step_dodge_distance * (travel_duration / step_dodge_duration)
	var target := global_position + world_direction * travel_distance
	target = _clamp_step_destination(target)
	if target.distance_squared_to(global_position) < 0.0004:
		return false

	_start_step_dodge(direction, target, travel_duration)
	return true


func _start_step_dodge(direction: Vector2, target: Vector3, travel_duration: float) -> void:
	_step_dodge_active = true
	_step_dodge_timer = 0.0
	_step_dodge_duration_active = travel_duration
	_step_dodge_cooldown = step_dodge_cooldown
	_step_dodge_start = global_position
	_step_dodge_end = target
	_step_dodge_direction = direction

	if _animation_tree and _animation_tree.active:
		_animation_tree.set("parameters/%s/blend_position" % STEP_DODGE_BLEND_NODE, direction)
		_animation_tree.set(
			"parameters/%s/request" % STEP_DODGE_ONE_SHOT,
			AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
		)


func _update_step_dodge(delta: float) -> void:
	if not _step_dodge_active:
		return

	_step_dodge_timer += delta
	var path_progress := _smoothstep01(_step_dodge_timer / _step_dodge_duration_active)
	var move_blend := 1.0
	if step_move_blend_in_time > 0.0:
		move_blend = _smoothstep01(_step_dodge_timer / step_move_blend_in_time)
	global_position = _step_dodge_start.lerp(_step_dodge_end, path_progress * move_blend)

	if _step_dodge_timer >= _step_dodge_duration_active:
		_finish_step_dodge()

	_check_duel_street_bounds()


func _finish_step_dodge() -> void:
	if not _step_dodge_active:
		return
	_step_dodge_active = false
	_step_dodge_timer = 0.0
	global_position = _step_dodge_end


func sync_stance_anchor() -> void:
	_stance_anchor = global_position


func _clamp_step_destination(target: Vector3) -> Vector3:
	var offset := global_transform.basis.inverse() * (target - _stance_anchor)
	if not _duel_mode:
		offset.x = clampf(offset.x, -step_lateral_limit, step_lateral_limit)
	offset.z = clampf(offset.z, -step_forward_limit, step_forward_limit)
	return _stance_anchor + global_transform.basis * offset


func _is_off_duel_street() -> bool:
	if _duel_street_half_width <= 0.0:
		return false
	return absf(global_position.x - _duel_street_center.x) > _duel_street_half_width


func _is_duel_street_check_active() -> bool:
	return (
		_duel_mode
		and not _duel_defeated
		and not _duel_yeller_reported
		and _duel_street_half_width > 0.0
		and (_duel_shoot_allowed or _duel_prep_allowed or _step_dodge_active)
	)


func _check_duel_street_bounds() -> void:
	if not _is_duel_street_check_active():
		return
	if _is_off_duel_street():
		_report_duel_yeller()


func set_duel_street_bounds(street_center: Vector3, half_width: float) -> void:
	_duel_street_center = street_center
	_duel_street_half_width = maxf(half_width, 0.0)
	_duel_yeller_reported = false


func clear_duel_street_bounds() -> void:
	_duel_street_half_width = 0.0
	_duel_yeller_reported = false


func _build_step_dodge_library() -> void:
	if _animation_player.has_animation_library(STEP_DODGE_LIBRARY):
		_animation_player.remove_animation_library(STEP_DODGE_LIBRARY)

	var library := AnimationLibrary.new()
	for pose_name: String in RigAnimConfig.AUTHORED_SIDESTEP_POSES.keys():
		var scene_path: String = RigAnimConfig.AUTHORED_SIDESTEP_POSES[pose_name]
		var source := RigAnimUtils.load_skeleton_animation(scene_path)
		if source == null:
			push_error("GroyperPlayer: failed to load sidestep animation '%s'." % pose_name)
			continue
		library.add_animation(StringName(pose_name), RigAnimUtils.prepare_for_body_player(source))

	for pose_name: String in ["forwards", "back"]:
		var direction: Vector2 = LeanPoseConfig.POSE_BLEND_POSITIONS[pose_name]
		library.add_animation(
			StringName(pose_name),
			_make_step_dodge_animation(_step_dodge_keyframes_for_direction(direction))
		)

	if library.get_animation_list().is_empty():
		push_error("GroyperPlayer: step_dodge library has no animations.")
		return

	_animation_player.add_animation_library(STEP_DODGE_LIBRARY, library)


func _smoothstep01(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


func _dominant_step_pose(direction: Vector2) -> String:
	if direction.length_squared() < 0.0001:
		return "forwards"
	if absf(direction.x) >= absf(direction.y):
		return "left" if direction.x < 0.0 else "right"
	return "forwards" if direction.y > 0.0 else "back"


func _get_step_travel_duration(direction: Vector2) -> float:
	var pose_name := _dominant_step_pose(direction)
	if not RigAnimConfig.AUTHORED_SIDESTEP_POSES.has(pose_name):
		return step_dodge_duration

	var anim_path := StringName("%s/%s" % [STEP_DODGE_LIBRARY, pose_name])
	if _animation_player == null or not _animation_player.has_animation(anim_path):
		return step_dodge_duration

	return _animation_player.get_animation(anim_path).length


func _step_dodge_keyframes_for_direction(direction: Vector2) -> Array:
	if direction.y > 0.5:
		return [
			{"time": 0.0, "poses": {}},
			{
				"time": 0.24,
				"poses": {
					"Hips": Vector3(-10.0, 0.0, 0.0),
					"LeftUpLeg": Vector3(30.0, 0.0, 10.0),
					"LeftLeg": Vector3(40.0, 0.0, 6.0),
					"RightUpLeg": Vector3(-6.0, 0.0, -10.0),
					"RightLeg": Vector3(10.0, 0.0, 0.0),
				},
			},
			{
				"time": 0.58,
				"poses": {
					"Hips": Vector3(-5.0, 0.0, 0.0),
					"LeftUpLeg": Vector3(10.0, 0.0, 6.0),
					"LeftLeg": Vector3(16.0, 0.0, 4.0),
					"RightUpLeg": Vector3(20.0, 0.0, -6.0),
					"RightLeg": Vector3(24.0, 0.0, 0.0),
				},
			},
			{"time": 1.0, "poses": {}},
		]
	return [
		{"time": 0.0, "poses": {}},
		{
			"time": 0.24,
			"poses": {
				"Hips": Vector3(8.0, 0.0, 0.0),
				"RightUpLeg": Vector3(24.0, 0.0, -8.0),
				"RightLeg": Vector3(32.0, 0.0, 0.0),
				"LeftUpLeg": Vector3(6.0, 0.0, 6.0),
				"LeftLeg": Vector3(12.0, 0.0, 0.0),
			},
		},
		{
			"time": 0.58,
			"poses": {
				"Hips": Vector3(4.0, 0.0, 0.0),
				"RightUpLeg": Vector3(10.0, 0.0, -4.0),
				"RightLeg": Vector3(16.0, 0.0, 0.0),
				"LeftUpLeg": Vector3(18.0, 0.0, 4.0),
				"LeftLeg": Vector3(22.0, 0.0, 0.0),
			},
		},
		{"time": 1.0, "poses": {}},
	]


func _make_step_dodge_animation(keyframes: Array) -> Animation:
	var animation := Animation.new()
	animation.length = step_dodge_duration
	animation.loop_mode = Animation.LOOP_NONE

	var bone_tracks: Dictionary = {}
	for keyframe in keyframes:
		var time: float = keyframe["time"] * step_dodge_duration
		var poses: Dictionary = keyframe.get("poses", {})
		for bone_name: String in poses:
			var bone_id := _skeleton.find_bone(bone_name)
			if bone_id < 0:
				continue

			if not bone_tracks.has(bone_name):
				var track := animation.add_track(Animation.TYPE_ROTATION_3D)
				animation.track_set_path(track, NodePath("%s:%s" % [_skeleton_anim_path, bone_name]))
				bone_tracks[bone_name] = track

			var euler_deg: Vector3 = poses[bone_name]
			var euler_rad := Vector3(
				deg_to_rad(euler_deg.x),
				deg_to_rad(euler_deg.y),
				deg_to_rad(euler_deg.z)
			)
			var rest_basis := _skeleton.get_bone_rest(bone_id).basis
			var target_rotation := (rest_basis * Basis.from_euler(euler_rad)).get_rotation_quaternion()
			animation.rotation_track_insert_key(bone_tracks[bone_name], time, target_rotation)

	return animation


func _build_jump_dodge_library() -> void:
	if _animation_player.has_animation_library(JUMP_DODGE_LIBRARY):
		_animation_player.remove_animation_library(JUMP_DODGE_LIBRARY)

	var spread := jump_dodge_leg_spread_deg
	var library := AnimationLibrary.new()
	library.add_animation(&"jump", _make_jump_dodge_animation([
		{
			"time": 0.0,
			"poses": {},
		},
		{
			"time": 0.14,
			"poses": {
				"Hips": Vector3(-14.0, 0.0, 0.0),
				"LeftUpLeg": Vector3(18.0, 0.0, 6.0),
				"RightUpLeg": Vector3(18.0, 0.0, -6.0),
				"LeftLeg": Vector3(22.0, 0.0, 0.0),
				"RightLeg": Vector3(22.0, 0.0, 0.0),
			},
		},
		{
			"time": 0.36,
			"poses": {
				"Hips": Vector3(6.0, 0.0, 0.0),
				"LeftUpLeg": Vector3(-12.0, 0.0, spread),
				"RightUpLeg": Vector3(-12.0, 0.0, -spread),
				"LeftLeg": Vector3(28.0, 0.0, spread * 0.35),
				"RightLeg": Vector3(28.0, 0.0, -spread * 0.35),
			},
		},
		{
			"time": 0.58,
			"poses": {
				"Hips": Vector3(-10.0, 0.0, 0.0),
				"LeftUpLeg": Vector3(12.0, 0.0, spread * 0.25),
				"RightUpLeg": Vector3(12.0, 0.0, -spread * 0.25),
				"LeftLeg": Vector3(18.0, 0.0, 0.0),
				"RightLeg": Vector3(18.0, 0.0, 0.0),
			},
		},
		{
			"time": 1.0,
			"poses": {},
		},
	]))
	_animation_player.add_animation_library(JUMP_DODGE_LIBRARY, library)


func _make_jump_dodge_animation(keyframes: Array) -> Animation:
	var animation := Animation.new()
	animation.length = jump_dodge_duration
	animation.loop_mode = Animation.LOOP_NONE

	var bone_tracks: Dictionary = {}
	for keyframe in keyframes:
		var time: float = keyframe["time"] * jump_dodge_duration
		var poses: Dictionary = keyframe.get("poses", {})
		for bone_name: String in poses:
			var bone_id := _skeleton.find_bone(bone_name)
			if bone_id < 0:
				continue

			if not bone_tracks.has(bone_name):
				var track := animation.add_track(Animation.TYPE_ROTATION_3D)
				animation.track_set_path(track, NodePath("%s:%s" % [_skeleton_anim_path, bone_name]))
				bone_tracks[bone_name] = track

			var euler_deg: Vector3 = poses[bone_name]
			var euler_rad := Vector3(
				deg_to_rad(euler_deg.x),
				deg_to_rad(euler_deg.y),
				deg_to_rad(euler_deg.z)
			)
			var rest_basis := _skeleton.get_bone_rest(bone_id).basis
			var target_rotation := (rest_basis * Basis.from_euler(euler_rad)).get_rotation_quaternion()
			animation.rotation_track_insert_key(bone_tracks[bone_name], time, target_rotation)

	return animation


func _setup_animation_tree() -> void:
	var idle_animation_name := GroyperBodyUtils.find_idle_animation_name(_animation_player)
	if idle_animation_name.is_empty():
		push_error("GroyperPlayer: could not find idle animation.")
		return

	if not _animation_player.has_animation_library(LeanPoseConfig.LIBRARY_NAME):
		push_error(
			"GroyperPlayer: missing authored lean library '%s' on Body."
			% LeanPoseConfig.LIBRARY_NAME
		)
		return

	var idle_node := AnimationNodeAnimation.new()
	idle_node.animation = idle_animation_name
	if _animation_player.has_animation(idle_animation_name):
		var idle_anim := _animation_player.get_animation(idle_animation_name)
		if idle_anim != null:
			idle_anim.loop_mode = Animation.LOOP_LINEAR

	var lean_blend := AnimationNodeBlendSpace2D.new()
	lean_blend.min_space = Vector2(-1.0, -1.0)
	lean_blend.max_space = Vector2(1.0, 1.0)
	lean_blend.sync = true
	lean_blend.blend_mode = AnimationNodeBlendSpace2D.BLEND_MODE_INTERPOLATED

	for pose_name: String in LeanPoseConfig.POSE_BLEND_POSITIONS.keys():
		var pose_node := AnimationNodeAnimation.new()
		pose_node.animation = LeanPoseConfig.get_animation_path(pose_name)
		lean_blend.add_blend_point(pose_node, LeanPoseConfig.POSE_BLEND_POSITIONS[pose_name])

	var mix_node := AnimationNodeBlend2.new()
	mix_node.sync = true
	_lean_mix_filter_node = mix_node
	LeanPoseConfig.configure_idle_lean_mix_filter(mix_node)

	var jump_anim := AnimationNodeAnimation.new()
	jump_anim.animation = StringName("%s/jump" % JUMP_DODGE_LIBRARY)

	var jump_one_shot := AnimationNodeOneShot.new()
	jump_one_shot.fadein_time = 0.04
	jump_one_shot.fadeout_time = 0.08
	jump_one_shot.sync = true

	var step_blend := AnimationNodeBlendSpace2D.new()
	step_blend.min_space = Vector2(-1.0, -1.0)
	step_blend.max_space = Vector2(1.0, 1.0)
	step_blend.sync = true
	step_blend.blend_mode = AnimationNodeBlendSpace2D.BLEND_MODE_INTERPOLATED
	for pose_name: String in LeanPoseConfig.POSE_BLEND_POSITIONS.keys():
		if pose_name == "neutral":
			continue
		var step_node := AnimationNodeAnimation.new()
		step_node.animation = StringName("%s/%s" % [STEP_DODGE_LIBRARY, pose_name])
		step_blend.add_blend_point(step_node, LeanPoseConfig.POSE_BLEND_POSITIONS[pose_name])

	var step_one_shot := AnimationNodeOneShot.new()
	step_one_shot.fadein_time = step_anim_fadein_time
	step_one_shot.fadeout_time = step_anim_fadeout_time
	step_one_shot.sync = true

	var blend_tree := AnimationNodeBlendTree.new()
	blend_tree.add_node(IDLE_NODE, idle_node)
	blend_tree.add_node(LEAN_BLEND_NODE, lean_blend)
	blend_tree.add_node(MIX_NODE, mix_node)
	blend_tree.add_node(STEP_DODGE_BLEND_NODE, step_blend)
	blend_tree.add_node(STEP_DODGE_ONE_SHOT, step_one_shot)
	blend_tree.add_node(JUMP_DODGE_ANIM_NODE, jump_anim)
	blend_tree.add_node(JUMP_DODGE_ONE_SHOT, jump_one_shot)
	blend_tree.connect_node(MIX_NODE, 0, IDLE_NODE)
	blend_tree.connect_node(MIX_NODE, 1, LEAN_BLEND_NODE)
	blend_tree.connect_node(STEP_DODGE_ONE_SHOT, 0, MIX_NODE)
	blend_tree.connect_node(STEP_DODGE_ONE_SHOT, 1, STEP_DODGE_BLEND_NODE)
	blend_tree.connect_node(JUMP_DODGE_ONE_SHOT, 0, STEP_DODGE_ONE_SHOT)
	blend_tree.connect_node(JUMP_DODGE_ONE_SHOT, 1, JUMP_DODGE_ANIM_NODE)
	blend_tree.connect_node(&"output", 0, JUMP_DODGE_ONE_SHOT)

	_animation_tree.tree_root = blend_tree
	_animation_tree.anim_player = _animation_tree.get_path_to(_animation_player)
	_animation_tree.process_priority = -100
	_animation_tree.active = true


func _find_idle_animation_name() -> StringName:
	return GroyperBodyUtils.find_idle_animation_name(_animation_player)


func suspend_animations_for_ragdoll() -> void:
	if _ragdoll_animations_suspended:
		return
	_ragdoll_animations_suspended = true

	if _animation_tree != null:
		_saved_animation_tree_active = _animation_tree.active
		_saved_animation_tree_process_mode = _animation_tree.process_mode
		_animation_tree.set("parameters/%s/blend_position" % LEAN_BLEND_NODE, Vector2.ZERO)
		_animation_tree.set("parameters/%s/blend_amount" % MIX_NODE, 0.0)
		_animation_tree.active = false
		_animation_tree.process_mode = Node.PROCESS_MODE_DISABLED

	if _animation_player != null:
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


func is_ragdoll_pose_active() -> bool:
	return _duel_ragdoll != null and _duel_ragdoll.is_active()


func on_revolver_dropped() -> void:
	_gun_in_hand = false
	_revolver_grip = null
	var fps_viewmodel := get_node_or_null(
		"FpsRig/Yaw/Pitch/FpsCamera/ViewModel/FpsRevolverViewModel"
	) as Node3D
	if fps_viewmodel != null:
		fps_viewmodel.visible = false


func _ensure_revolver_grip() -> void:
	if _revolver_grip != null and is_instance_valid(_revolver_grip):
		return
	if _holster_socket == null and _skeleton != null:
		var hip_mount := _skeleton.get_node_or_null("HipHolsterMount") as Node3D
		if hip_mount != null:
			_holster_socket = hip_mount.get_node_or_null("HolsterOffset") as Node3D
	if _holster_socket != null:
		_revolver_grip = _holster_socket.get_node_or_null("RevolverGrip") as Node3D


func enable_duel_mode(enabled: bool) -> void:
	_duel_mode = enabled
	if enabled:
		add_to_group("duel_target")
		_ensure_duel_hitbox()
		_ensure_duel_ragdoll()
	elif _duel_hitbox != null:
		remove_from_group("duel_target")
		_duel_hitbox.queue_free()
		_duel_hitbox = null
		clear_duel_street_bounds()


func set_duel_prep_allowed(allowed: bool) -> void:
	_duel_prep_allowed = allowed
	if allowed:
		_update_draw_ui()
		if _draw_state == DrawState.HOLSTERED:
			_clear_arm_aim_smoothing()
	else:
		_update_draw_ui()


func set_duel_shoot_allowed(allowed: bool) -> void:
	_duel_shoot_allowed = allowed
	if allowed:
		_duel_prep_allowed = false
	_update_draw_ui()


func get_duel_hat() -> GroyperDuelHat:
	return _duel_hat


func apply_match_hat_state(match_hat_lost: bool) -> void:
	if _duel_hat != null:
		_duel_hat.prepare_for_round(match_hat_lost)


func prepare_for_duel_round() -> void:
	if _duel_ragdoll != null and _duel_ragdoll.is_active():
		_duel_ragdoll.deactivate()
	resume_animations_after_ragdoll()
	if _duel_hitbox != null:
		_duel_hitbox.collision_layer = 1
	if _animation_tree != null:
		_animation_tree.active = true
	_duel_defeated = false
	_duel_prep_allowed = false
	_duel_shoot_allowed = false
	_duel_fault_pending = false
	_duel_yeller_reported = false
	_draw_state = DrawState.HOLSTERED
	_draw_progress = 0.0
	_gun_in_hand = false
	_pending_shot = false
	_shot_cooldown = 0.0
	_spray_spread_bonus_deg = 0.0
	_step_dodge_active = false
	_step_dodge_timer = 0.0
	_step_dodge_duration_active = step_dodge_duration
	_step_dodge_cooldown = 0.0
	_step_dodge_direction = Vector2.ZERO
	_clear_raise_cache()
	_clear_arm_aim_smoothing()
	_reset_aim_bone_poses()

	_ensure_revolver_grip()
	if _revolver_grip != null and _holster_socket != null and _revolver_grip.get_parent() != _holster_socket:
		var grip_global := _revolver_grip.global_transform
		_revolver_grip.reparent(_holster_socket, true)
		_revolver_grip.global_transform = grip_global

	_apply_holster_grip_transform()
	_invalidate_muzzle_cache()
	var fps_viewmodel := get_node_or_null(
		"FpsRig/Yaw/Pitch/FpsCamera/ViewModel/FpsRevolverViewModel"
	) as Node3D
	if fps_viewmodel != null:
		fps_viewmodel.visible = camera_mode == CameraMode.FPS
	_ammo = _get_duel_ammo()
	if ammo_hud:
		ammo_hud.sync_rounds(_ammo, false, true)
	set_process(true)


func _get_duel_ammo() -> int:
	return GroyperWeapons.get_duel_ammo(_equipped_weapon)


func enable_target_mode(enabled: bool) -> void:
	_target_mode = enabled
	if enabled:
		add_to_group("target_player")


func set_target_prep_allowed(allowed: bool) -> void:
	_target_prep_allowed = allowed
	if allowed:
		_update_draw_ui()
		if _draw_state == DrawState.HOLSTERED:
			_clear_arm_aim_smoothing()
	else:
		_update_draw_ui()


func set_target_shoot_allowed(allowed: bool) -> void:
	_target_shoot_allowed = allowed
	if allowed:
		_target_prep_allowed = false
	_update_draw_ui()


func prepare_for_target_round() -> void:
	if _duel_ragdoll != null and _duel_ragdoll.is_active():
		_duel_ragdoll.deactivate()
	resume_animations_after_ragdoll()
	if _animation_tree != null:
		_animation_tree.active = true
	_target_prep_allowed = false
	_target_shoot_allowed = false
	_draw_state = DrawState.HOLSTERED
	_draw_progress = 0.0
	_gun_in_hand = false
	_pending_shot = false
	_shot_cooldown = 0.0
	_spray_spread_bonus_deg = 0.0
	_step_dodge_active = false
	_step_dodge_timer = 0.0
	_step_dodge_duration_active = step_dodge_duration
	_step_dodge_cooldown = 0.0
	_step_dodge_direction = Vector2.ZERO
	_clear_raise_cache()
	_clear_arm_aim_smoothing()
	_reset_aim_bone_poses()

	_ensure_revolver_grip()
	if _revolver_grip != null and _holster_socket != null and _revolver_grip.get_parent() != _holster_socket:
		var grip_global := _revolver_grip.global_transform
		_revolver_grip.reparent(_holster_socket, true)
		_revolver_grip.global_transform = grip_global

	_apply_holster_grip_transform()
	_invalidate_muzzle_cache()
	_ammo = _get_max_ammo()
	if ammo_hud:
		ammo_hud.sync_rounds(_ammo)
	set_process(true)


func _get_max_ammo() -> int:
	return GroyperWeapons.get_max_ammo(_equipped_weapon)


func _can_hold_full_auto() -> bool:
	if _camera_tune_active or _gun_grip_tune_active:
		return false
	if _duel_defeated:
		return false
	if _duel_mode and not _duel_shoot_allowed:
		return false
	if _target_mode and not _target_shoot_allowed:
		return false
	return GroyperWeapons.is_full_auto(_equipped_weapon)


func is_duel_defeated() -> bool:
	return _duel_defeated


func contains_bullet_hit(world_point: Vector3, margin: float) -> bool:
	if not _duel_mode or _duel_defeated:
		return false
	var capsule := get_bullet_capsule()
	return DUEL_HIT_TEST.point_in_capsule(
		world_point,
		capsule["center"],
		capsule["half_height"],
		capsule["radius"],
		capsule.get("axis", Vector3.UP),
		margin
	)


func get_bullet_capsule() -> Dictionary:
	_sync_duel_hitbox_position()
	var hurtbox := _get_duel_hurtbox_transform()
	var half_height := 0.48
	var radius := 0.28
	if _duel_hitbox != null:
		var shape_node := _duel_hitbox.get_node_or_null("CollisionShape3D") as CollisionShape3D
		var capsule := shape_node.shape as CapsuleShape3D if shape_node != null else null
		if capsule != null:
			half_height = capsule.height * 0.5
			radius = capsule.radius
	return {
		"center": hurtbox.origin,
		"half_height": half_height,
		"radius": radius,
		"axis": hurtbox.basis.y,
	}


func _report_duel_fault(reason: String) -> void:
	if not _duel_mode or _duel_shoot_allowed or _duel_fault_pending:
		return

	_duel_fault_pending = true
	_draw_state = DrawState.HOLSTERING
	duel_fault.emit(reason)


func _report_duel_yeller() -> void:
	if not _duel_mode or _duel_defeated or _duel_yeller_reported:
		return

	_duel_yeller_reported = true
	_finish_step_dodge()
	_duel_shoot_allowed = false
	_duel_prep_allowed = false
	_update_draw_ui()
	duel_yeller.emit()


func apply_bullet_hit(hit_info: Dictionary) -> void:
	receive_bullet_hit(hit_info)


func receive_bullet_hit(hit_info: Dictionary) -> void:
	if not _duel_mode or _duel_defeated:
		return

	BloodSplatterFXScript.spawn_for_hit(self, hit_info)
	_activate_duel_defeat_ragdoll(hit_info)
	defeated.emit(hit_info)


func _ensure_duel_hitbox() -> void:
	if _duel_hitbox != null:
		return

	_duel_hitbox = StaticBody3D.new()
	_duel_hitbox.name = "DuelHitbox"
	_duel_hitbox.collision_layer = 1
	_duel_hitbox.transform = Transform3D(Basis.IDENTITY, Vector3(0.0, 1.05, 0.0))
	_duel_hitbox.script = DUEL_HITBOX_SCRIPT
	add_child(_duel_hitbox)
	_duel_hitbox.owner_path = NodePath("..")

	var shape := CapsuleShape3D.new()
	shape.radius = 0.28
	shape.height = 0.96

	var collision := CollisionShape3D.new()
	collision.shape = shape
	_duel_hitbox.add_child(collision)


func _ensure_duel_ragdoll() -> void:
	if _duel_ragdoll != null or _skeleton == null:
		return

	_duel_ragdoll = DUEL_RAGDOLL_SCRIPT.new()
	_duel_ragdoll.name = "DuelRagdoll"
	add_child(_duel_ragdoll)
	_duel_ragdoll.skeleton_path = _duel_ragdoll.get_path_to(_skeleton)
	_duel_ragdoll.bind_skeleton()


func apply_replay_ragdoll(hit_info: Dictionary) -> void:
	_activate_duel_defeat_ragdoll(hit_info)


func _activate_duel_defeat_ragdoll(hit_info: Dictionary) -> void:
	print("[GroyperPlayer] _activate_duel_defeat_ragdoll duel_mode=%s defeated=%s" % [
		_duel_mode,
		_duel_defeated,
	])
	_ensure_duel_ragdoll()
	var hit_position: Vector3 = hit_info.get("position", global_position)
	GameAudio.play_death_sound(self, hit_position)
	_duel_defeated = true
	_duel_shoot_allowed = false
	if _duel_hitbox != null:
		_duel_hitbox.collision_layer = 0
	if _duel_ragdoll != null and not _duel_ragdoll.is_active():
		_duel_ragdoll.activate(hit_info, _animation_player)


func set_replay_mode(active: bool) -> void:
	_replay_mode = active
	set_process_input(not active)
	if active:
		set_duel_shoot_allowed(false)
		set_duel_prep_allowed(false)
		_replay_step_scrub_time = -1.0
		if _animation_tree != null:
			_replay_saved_tree_process_mode = _animation_tree.process_mode
			_animation_tree.active = true
			_animation_tree.process_mode = Node.PROCESS_MODE_DISABLED
		if tps_camera:
			tps_camera.current = false
		if fps_camera:
			fps_camera.current = false
		if reticle_ui:
			reticle_ui.visible = false
		if ammo_hud:
			ammo_hud.visible = false
	else:
		_replay_force_rpg_loaded = false
		_sync_rpg_grip_rocket()
		if not is_ragdoll_pose_active():
			if _ragdoll_animations_suspended:
				resume_animations_after_ragdoll()
			elif _animation_tree != null:
				_animation_tree.process_mode = _replay_saved_tree_process_mode
				_animation_tree.active = true
		if reticle_ui:
			reticle_ui.visible = true
		if ammo_hud:
			ammo_hud.visible = true
		if camera_mode == CameraMode.THIRD_PERSON and tps_camera:
			tps_camera.current = true
		elif fps_camera:
			fps_camera.current = true


func reset_visual_for_replay() -> void:
	if _duel_ragdoll != null and _duel_ragdoll.is_active():
		print("[GroyperPlayer] reset_visual_for_replay deactivating ragdoll")
		_duel_ragdoll.deactivate()
	if _duel_hat != null:
		_duel_hat.restore_for_replay()
	_duel_defeated = false
	_replay_step_scrub_time = -1.0
	_replay_force_rpg_loaded = GroyperWeapons.is_rpg(_equipped_weapon)
	_sync_rpg_grip_rocket()


func capture_replay_snapshot() -> Dictionary:
	return {
		"pos": global_position,
		"rot_y": rotation.y,
		"rig_y": rig.position.y if rig else 0.0,
		"lean_current": _lean_current,
		"lean_blend": _lean_blend_amount,
		"lean_hold": _lean_hold_time,
		"draw_state": _draw_state,
		"draw_progress": _draw_progress,
		"gun_in_hand": _gun_in_hand,
		"aim_target": _aim_target,
		"jump_active": _jump_dodge_active,
		"jump_timer": _jump_dodge_timer,
		"step_active": _step_dodge_active,
		"step_timer": _step_dodge_timer,
		"step_duration": _step_dodge_duration_active,
		"step_start": _step_dodge_start,
		"step_end": _step_dodge_end,
		"step_direction": _step_dodge_direction,
		"forearm_recoil": _forearm_recoil,
		"arm_recoil_angles": _arm_recoil_angles_deg,
	}


func apply_replay_snapshot(snap: Dictionary) -> void:
	if snap.is_empty():
		return
	if is_ragdoll_pose_active() or _duel_defeated:
		return

	global_position = snap["pos"]
	rotation.y = snap["rot_y"]
	if rig:
		rig.position.y = snap.get("rig_y", _rig_base_y)
	_lean_current = snap["lean_current"]
	_lean_blend_amount = snap["lean_blend"]
	_lean_hold_time = snap.get("lean_hold", 0.0)
	_draw_state = snap["draw_state"]
	_draw_progress = snap["draw_progress"]
	_gun_in_hand = snap["gun_in_hand"]
	_aim_target = snap["aim_target"]
	_jump_dodge_active = snap.get("jump_active", false)
	_jump_dodge_timer = snap.get("jump_timer", 0.0)
	_step_dodge_active = snap.get("step_active", false)
	_step_dodge_timer = snap.get("step_timer", 0.0)
	_step_dodge_duration_active = snap.get("step_duration", step_dodge_duration)
	_step_dodge_start = snap.get("step_start", global_position)
	_step_dodge_end = snap.get("step_end", global_position)
	_step_dodge_direction = snap.get("step_direction", _step_direction_from_snap(snap))
	_forearm_recoil = snap.get("forearm_recoil", 0.0)
	_arm_recoil_angles_deg = snap.get("arm_recoil_angles", Vector3.ZERO)
	_arm_recoil_angles_target_deg = _arm_recoil_angles_deg

	_sync_replay_weapon_mount()
	_ensure_replay_draw_cache()

	if _skeleton == null:
		return

	_apply_lean_animation_tree()
	var step_advanced := _apply_replay_step_animation(snap)
	if step_advanced < 0.0:
		_advance_replay_animation_tree(get_process_delta_time())
	match _draw_state:
		DrawState.AIMING:
			_apply_arm_aim_for_replay(_aim_target)
		DrawState.DRAWING, DrawState.HOLSTERING:
			_apply_draw_pose(_draw_progress)
		DrawState.HOLSTERED:
			if _should_hold_holstered_arm_pose():
				_reset_aim_bone_poses()
			else:
				_clear_holstered_arm_overrides()
	_sync_duel_hitbox_position()


func _sync_replay_weapon_mount() -> void:
	if _gun_in_hand and _revolver_grip != null and _hand_revolver_mount != null \
			and _revolver_grip.get_parent() != _hand_revolver_mount:
		var grip_global := _revolver_grip.global_transform
		_revolver_grip.reparent(_hand_revolver_mount, true)
		_revolver_grip.global_transform = grip_global
		_invalidate_muzzle_cache()
	elif not _gun_in_hand and _revolver_grip != null and _holster_socket != null \
			and _revolver_grip.get_parent() != _holster_socket:
		var holster_global := _revolver_grip.global_transform
		_revolver_grip.reparent(_holster_socket, true)
		_revolver_grip.global_transform = holster_global
		_apply_holster_grip_transform()
		_invalidate_muzzle_cache()


func _ensure_replay_draw_cache() -> void:
	if _draw_state != DrawState.DRAWING or _draw_progress < draw_grab_threshold:
		return
	if not _raise_start_poses.is_empty():
		return
	if not _gun_in_hand:
		if _revolver_grip == null or _hand_revolver_mount == null:
			return
		var holster_target := _get_holster_reach_target()
		var grip_global := _revolver_grip.global_transform
		_cache_raise_start_poses(holster_target)
		_revolver_grip.reparent(_hand_revolver_mount, true)
		_revolver_grip.global_transform = grip_global
		_raise_grip_local_start = _revolver_grip.transform
		_invalidate_muzzle_cache()
		_resolve_hand_muzzle()
	else:
		_cache_raise_start_poses(_get_holster_reach_target())
		_raise_grip_local_start = _revolver_grip.transform if _revolver_grip else Transform3D.IDENTITY
	_raise_aim_target = _aim_target


func _step_direction_from_snap(snap: Dictionary) -> Vector2:
	var direction: Vector2 = snap.get("step_direction", Vector2.ZERO)
	if direction.length_squared() > 0.0001:
		return direction.normalized()

	var start: Vector3 = snap.get("step_start", global_position)
	var end: Vector3 = snap.get("step_end", global_position)
	var world_direction := end - start
	world_direction.y = 0.0
	if world_direction.length_squared() < 0.0001:
		return Vector2.ZERO
	var local_direction := global_transform.basis.inverse() * world_direction.normalized()
	return Vector2(local_direction.x, local_direction.z).normalized()


func _apply_replay_step_animation(snap: Dictionary) -> float:
	if not _replay_mode or _animation_tree == null or not _animation_tree.active:
		return -1.0
	if is_ragdoll_pose_active() or _duel_defeated:
		return -1.0

	var step_timer: float = snap.get("step_timer", 0.0)
	var stepping: bool = snap.get("step_active", false) or step_timer > 0.001
	if not stepping:
		_replay_step_scrub_time = -1.0
		return -1.0

	var direction := _step_direction_from_snap(snap)
	if direction.length_squared() > 0.0001:
		_animation_tree.set("parameters/%s/blend_position" % STEP_DODGE_BLEND_NODE, direction)

	if _replay_step_scrub_time < 0.0 or step_timer + 0.02 < _replay_step_scrub_time:
		_animation_tree.set(
			"parameters/%s/request" % STEP_DODGE_ONE_SHOT,
			AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
		)
		_replay_step_scrub_time = 0.0

	var advance_by := step_timer - _replay_step_scrub_time
	if advance_by > 0.0:
		_animation_tree.advance(advance_by)
		_replay_step_scrub_time = step_timer
	elif advance_by < -0.02:
		_replay_step_scrub_time = step_timer

	return maxf(advance_by, 0.0)


func _apply_arm_aim_for_replay(world_target: Vector3) -> void:
	_smoothed_arm_aim_target = world_target
	_aim_bone_poses_smoothed.clear()
	_apply_gun_arm_neutral_rest()

	var arm_id := _skeleton.find_bone(ARM_BONE)
	if arm_id >= 0:
		var arm_axis := _get_gun_arm_aim_axis()
		var arm_pose := _compute_bone_pose_toward(arm_id, world_target, arm_axis)
		_skeleton.set_bone_pose_rotation(arm_id, _apply_arm_recoil_offset(arm_pose))

	var forearm_id := _skeleton.find_bone(FOREARM_BONE)
	if forearm_id >= 0:
		var forearm_rest := Quaternion.IDENTITY
		if _uses_two_hand_arm_aim():
			forearm_rest = _get_authored_neutral_pose(FOREARM_BONE)
		_skeleton.set_bone_pose_rotation(forearm_id, _apply_arm_recoil_offset(forearm_rest))

	_lock_hand_aim_pose()

	if _uses_two_hand_arm_aim():
		_apply_support_arm_neutral_rest()
		var support_target := _get_support_hand_world_target()
		for bone_name: String in TwoHandAimPoseConfig.SUPPORT_IK_BONES:
			var bone_id := _skeleton.find_bone(bone_name)
			if bone_id < 0:
				continue
			var local_axis: Vector3 = _bone_aim_axes.get(bone_name, Vector3(-1.0, 0.0, 0.0))
			var pose := _compute_bone_pose_toward(bone_id, support_target, local_axis)
			_skeleton.set_bone_pose_rotation(bone_id, pose)
		var left_hand_id := _skeleton.find_bone(TwoHandAimPoseConfig.LEFT_HAND_BONE)
		if left_hand_id >= 0:
			_skeleton.set_bone_pose_rotation(
				left_hand_id,
				_get_authored_neutral_pose(TwoHandAimPoseConfig.LEFT_HAND_BONE)
			)
