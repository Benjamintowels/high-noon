extends GroyperActor

const WEAPON_RIG_SCRIPT := preload("res://characters/groyper/groyper_weapon_rig.gd")
const GroyperWeapons := preload("res://characters/groyper/groyper_weapons.gd")
const LEFT_HIP_HOLSTER_MOUNT_SCENE := preload("res://characters/groyper/left_hip_holster_mount.tscn")
const DUEL_HITBOX_SCRIPT := preload("res://characters/groyper/groyper_hitbox.gd")
const DUEL_RAGDOLL_SCRIPT := preload("res://characters/groyper/groyper_ragdoll.gd")
const DUEL_HAT_SCRIPT := preload("res://characters/groyper/groyper_duel_hat.gd")
const DuelHitTest := preload("res://gameplay/duel/duel_hit_test.gd")
const BulletHitDamage := preload("res://gameplay/shooting/bullet_hit_damage.gd")
const SaddlePoseConfig := preload("res://characters/groyper/saddle_pose_config.gd")
const CoverPoseExtractScript := preload("res://characters/groyper/cover_pose_extract.gd")
const VaultExtractScript := preload("res://characters/groyper/vault_extract.gd")
const VaultConfigScript := preload("res://characters/groyper/vault_config.gd")
const GameAudio := preload("res://gameplay/audio/game_audio.gd")
const LassoControllerScript := preload("res://gameplay/lasso/lasso_controller.gd")
const FactionIds := preload("res://gameplay/faction/faction_ids.gd")

const BODY_AIM_ZONES := {
	"head": {"bone": "Head", "offset": Vector3(0.0, 0.06, 0.05)},
	"chest": {"bone": "Spine02", "offset": Vector3(0.0, 0.1, 0.06)},
	"gut": {"bone": "Spine01", "offset": Vector3(0.0, 0.04, 0.05)},
	"left_shoulder": {"bone": "LeftShoulder", "offset": Vector3(-0.06, 0.02, 0.03)},
	"right_shoulder": {"bone": "RightShoulder", "offset": Vector3(0.06, 0.02, 0.03)},
}
const THREATEN_RANGE := 18.0

const LOCOMOTION_BLEND := &"LocomotionBlend"
const LOCOMOTION_IDLE_BLEND := 0.0
const LOCOMOTION_WALK_REVERSE_BLEND := -0.5
const LOCOMOTION_WALK_BLEND := 0.5
const LOCOMOTION_RUN_BLEND := 1.0
const ROLL_ANIM_NODE := &"RollAnim"
const ROLL_ONE_SHOT := &"RollOneShot"
const VAULT_ANIM_NODE := &"VaultAnim"
const VAULT_TIME_SEEK := &"VaultTimeSeek"
const VAULT_BLEND := &"VaultBlend"
const COVER_POSE_BLEND := &"CoverPoseBlend"
const CROUCH_COVER_ANIM_NODE := &"CrouchCoverAnim"
const COVER_PEEK_BLEND := &"CoverPeekBlend"
const COVER_PEEK_AIM_ANIM_NODE := &"CoverPeekAimAnim"
const COVER_PEEK_BLEND_SPEED := 8.0
const COVER_WALK_ENTER_DURATION := 0.4
const COVER_EXIT_DURATION := 0.4
const SADDLE_BLEND := &"SaddleBlend"
const SADDLE_ANIM_NODE := &"SaddleAnim"
const SADDLE_BLEND_SPEED := 10.0
const AIM_WALK_REVERSE_DOT_THRESHOLD := 0.15

const WALK_SPEED := 3.6
const RUN_SPEED := 7.2
const ROLL_SPEED_MULTIPLIER := 1.5
const RUN_ROLL_SPEED_MULTIPLIER := 1.05
const ROLL_ANIM_FADEIN := 0.06
const ROLL_ANIM_FADEOUT := 0.12
const VAULT_ANIM_FADEIN := 0.08
const VAULT_EXIT_BLEND_DURATION := 0.28
const VAULT_PEAK_HEIGHT := 0.85
const VAULT_MOVE_TIME_SCALE := 0.52
const VAULT_LOCOMOTION_BLEND_BOOST := 3.0
const RUN_VAULT_SPEED_THRESHOLD := RUN_SPEED * 0.65
const HITBOX_HALF_HEIGHT := 0.48
const HITBOX_RADIUS := 0.28
const ROLL_HITBOX_HALF_HEIGHT := 0.22
const ROLL_HITBOX_RADIUS := 0.12
const AIM_WALK_SPEED := 2.2
const AIM_WALK_BACK_SPEED := 1.3
const AIM_RUN_SPEED := 3.6
const GRAVITY := 22.0
const MOUSE_SENSITIVITY := 0.0025
const CAMERA_PITCH_MIN := deg_to_rad(-35.0)
const CAMERA_PITCH_MAX := deg_to_rad(55.0)
const FACING_SPEED := 12.0
const AIM_FACING_SPEED := 14.0
const BLEND_SPEED := 8.0
const MOVE_ACCEL := 18.0
const MOVE_DECEL := 6.5
const MOVE_STOP_DECEL := 9.0
const SHOT_RANGE := 140.0
const AIM_ARM_TARGET_DISTANCE := 55.0

const RELOAD_HOLD_DURATION := 0.5
const RELOAD_KEY := KEY_R

const RETICLE_MAX_SCREEN_FRACTION := 0.32
const RETICLE_MOUSE_ACCEL := 2.4
const RETICLE_DRAG := 4.8
const RETICLE_MAX_SPEED_PX := 280.0
const RETICLE_SMOOTH := 6.5
## Cover peek aim — fast whip, low drag so aim keeps sliding after you stop.
const COVER_RETICLE_MOUSE_ACCEL := 4.7
const COVER_RETICLE_DRAG := 1.85
const COVER_RETICLE_MAX_SPEED_PX := 425.0
const COVER_RETICLE_SMOOTH := 2.4
const COVER_AIM_CAMERA_RELEASE_SMOOTH := 2.75
const RECOIL_RECOVERY := 9.0

## Duel-style shoulder aim: player sits off-center so the reticle clears what's ahead.
const AIM_CAMERA_OFFSET := Vector3(0.85, 0.0, 1.45)
const AIM_FOV_REDUCTION := 4.0
const AIM_FOV_SMOOTH := 8.0
const RELOAD_FOV_REDUCTION := 2.5
const RELOAD_FOV_REDUCTION_AIMING := 0.9
const RELOAD_CAMERA_PULL_IN := Vector3(0.06, 0.015, -0.22)
const RELOAD_CAMERA_PULL_IN_AIMING := Vector3(0.025, 0.006, -0.1)
const RELOAD_CAMERA_SMOOTH := 2.8
const MOUNT_CAMERA_PIVOT_Y := 1.55
const MOUNT_HOP_DURATION := 0.5
const MOUNT_HOP_HEIGHT := 0.9
const DISMOUNT_HOP_DURATION := 0.46
const DISMOUNT_HOP_HEIGHT := 0.8
const MOUNT_SETTLE_DURATION := 0.32
const MOUNT_AIM_CAMERA_PITCH_MIN := deg_to_rad(-50.0)
const MOUNT_AIM_CAMERA_PITCH_MAX := deg_to_rad(65.0)
const MOUNT_AIM_CAMERA_OFFSET := Vector3(0.75, 0.05, 1.35)
## Max aim yaw from rider forward — PI allows shooting directly behind, not past.
const MOUNT_AIM_YAW_LIMIT := PI
## No torso twist while aiming within this arc in front of the horse.
const MOUNT_AIM_SPINE_DEAD_ZONE := deg_to_rad(32.0)
const MOUNT_AIM_SPINE_SMOOTH := 14.0
const MOUNT_DEFEAT_LAUNCH_SPEED := 8.0
const MOUNT_DEFEAT_LAUNCH_UP := 5.5
const HEALTH_REGEN_INTERVAL := 3.0

@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _camera_arm: Node3D = $CameraPivot/CameraArm
@onready var _camera: Camera3D = $CameraPivot/CameraArm/Camera3D
@onready var _interact_hint: Label = $InteractHintLayer/HintLabel
@onready var _reticle_ui: CanvasLayer = $ReticleUI
@onready var _reticle: Control = $ReticleUI/Reticle
@onready var _scope_overlay: Control = $ReticleUI/ScopeOverlay
@onready var _ammo_hud: AmmoHud = $AmmoHud
@onready var _weapon_select_hud: WeaponSelectHud = $WeaponSelectHud
@onready var _health_vignette: HealthVignetteOverlay = $HealthVignetteOverlay

var _camera_yaw := PI
var _camera_pitch := -0.15
var _locomotion_blend := 0.0
var _weapon_rig: GroyperWeaponRig
var _nearby_interactables := {}
var _dialog_active := false
var _transition_locked := false

var _equipped_weapon: GroyperWeapons.Id = GroyperWeapons.get_starting_weapon()
var _ammo := 6
var _shot_cooldown := 0.0
var _fire_held := false

var _reticle_offset := Vector2.ZERO
var _reticle_offset_target := Vector2.ZERO
var _reticle_velocity := Vector2.ZERO
var _reticle_limit_px := 180.0
var _scope_blend := 0.0
var _scope_yaw := 0.0
var _scope_pitch := 0.0
var _scope_recoil_yaw := 0.0
var _scope_recoil_pitch := 0.0

var _overworld_combat_active := false
var _overworld_defeated := false
var _health := BulletHitDamage.PLAYER_MAX_HEALTH
var _health_regen_timer := 0.0
var _combat_hitbox: StaticBody3D
var _combat_ragdoll
var _duel_hat: GroyperDuelHat

var _explore_camera_offset := Vector3(0.65, 0.15, 2.85)
var _explore_camera_fov := 80.0
var _aim_fov_current := 80.0
var _aim_camera_blend := 0.0
var _reload_camera_blend := 0.0

var _roll_active := false
var _roll_timer := 0.0
var _roll_duration := 0.0
var _roll_direction := Vector3.ZERO
var _roll_speed := 0.0
var _roll_speed_multiplier := ROLL_SPEED_MULTIPLIER
var _roll_is_run := false
var _roll_anim_node: AnimationNodeAnimation
var _vault_active := false
var _vault_timer := 0.0
var _vault_duration := 0.0
var _vault_move_duration := 0.0
var _vault_start := Vector3.ZERO
var _vault_end := Vector3.ZERO
var _vault_floor_y := 0.0
var _vault_facing_yaw := 0.0
var _vault_cross_direction := Vector3.FORWARD
var _vault_blend := 0.0
var _vault_exit_active := false
var _vault_exit_timer := 0.0
var _vault_anim_node: AnimationNodeAnimation
var _vault_blend_node: AnimationNodeBlend2
var _cover_walk_enter_active := false
var _cover_walk_enter_timer := 0.0
var _cover_walk_enter_from := Vector3.ZERO
var _cover_walk_enter_to := Vector3.ZERO
var _cover_walk_enter_from_facing := 0.0
var _cover_walk_enter_facing := 0.0
var _cover_exit_active := false
var _cover_exit_timer := 0.0
var _cover_floor_y := 0.0
var _cover_hold_position := Vector3.ZERO
var _cover_crouch_active := false
var _cover_peek_active := false
var _cover_crouch_blend := 0.0
var _active_cover: CoverPiece
var _cover_pose_blend_node: AnimationNodeBlend2
var _cover_peek_blend_node: AnimationNodeBlend2
var _cover_peek_blend := 0.0
var _saddle_blend_node: AnimationNodeBlend2
var _saddle_blend := 0.0
var _mount_spine_yaw := 0.0

var _mounted_horse: StupidHorse
var _model_mount_parent: Node3D
var _model_mount_transform: Transform3D
var _mounted_model_mount_offset := Transform3D.IDENTITY
var _mount_hop_tween: Tween
var _mount_transition_active := false
var _mount_hop_model_yaw_from := 0.0
var _mount_hop_model_yaw_to := 0.0
var _explore_camera_pivot_y := 1.1
var _collision_shape: CollisionShape3D

var _reload_hold_time := 0.0
var _reload_eject_started := false
var _locomotion_audio: Node
var _reload_ready_for_tap := false
var _reload_pending_round := false
var _reload_last_phase: GroyperWeaponRig.OverworldReloadPhase = GroyperWeaponRig.OverworldReloadPhase.NONE
var _lasso_controller: LassoController
var _lasso_rmb_was_held := false


func _on_actor_ready() -> void:
	add_to_group("overworld_player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")
	_setup_weapon_rig()
	_setup_lasso_controller()
	_setup_hat()
	_setup_locomotion_audio()
	_setup_locomotion_library()
	_setup_roll_dodge_library()
	_setup_vault_library()
	_setup_cover_pose_library()
	_setup_animation_tree()
	_setup_combat_ui()
	_collision_shape = $CollisionShape3D as CollisionShape3D
	_explore_camera_pivot_y = _camera_pivot.position.y
	_camera_pivot.rotation.y = _camera_yaw
	_camera_arm.rotation.x = _camera_pitch
	_explore_camera_offset = _camera.position
	_explore_camera_fov = _camera.fov
	_aim_fov_current = _explore_camera_fov
	_update_reticle_limit()
	get_viewport().size_changed.connect(_update_reticle_limit)
	PlayerInventory.inventory_changed.connect(refresh_stowed_weapon_visuals)
	refresh_stowed_weapon_visuals()


func _setup_hat() -> void:
	if _skeleton == null or _duel_hat != null:
		return

	_duel_hat = DUEL_HAT_SCRIPT.new()
	_duel_hat.name = "DuelHat"
	add_child(_duel_hat)
	_duel_hat.bind_skeleton(_skeleton)
	_duel_hat.prepare_for_round(false)


func get_duel_hat() -> GroyperDuelHat:
	return _duel_hat


func _setup_weapon_rig() -> void:
	if _skeleton == null:
		return

	GroyperBodyUtils.ensure_weapon_mounts(_skeleton)

	_weapon_rig = WEAPON_RIG_SCRIPT.new()
	_weapon_rig.name = "WeaponRig"
	_weapon_rig.enable_overworld_hold_mode(true)
	add_child(_weapon_rig)
	_weapon_rig.setup(self, _skeleton, _equipped_weapon)
	_weapon_rig.draw_state_changed.connect(_on_weapon_draw_state_changed)


func _setup_lasso_controller() -> void:
	_lasso_controller = LassoControllerScript.new()
	_lasso_controller.name = "LassoController"
	_lasso_controller.max_range = GroyperWeapons.get_effective_range(GroyperWeapons.Id.LASSO)
	add_child(_lasso_controller)
	_lasso_controller.setup(
		self,
		_get_lasso_throw_anchor,
		_get_aim_world_target
	)


func _setup_locomotion_audio() -> void:
	_locomotion_audio = LocomotionAudioScript.new()
	_locomotion_audio.name = "LocomotionAudio"
	add_child(_locomotion_audio)
	_locomotion_audio.setup(self)


func _setup_combat_ui() -> void:
	_ammo = GroyperWeapons.get_max_ammo(_equipped_weapon)
	if _ammo_hud:
		_ammo_hud.configure_for_weapon(_equipped_weapon)
		_ammo_hud.sync_rounds(_ammo)
		_ammo_hud.visible = false
	if _reticle_ui:
		_reticle_ui.visible = false
	_update_health_vignette()


func _process(delta: float) -> void:
	if _overworld_defeated:
		return

	if _overworld_combat_active and not _overworld_defeated:
		_sync_combat_hitbox_position()

	if _is_fully_mounted():
		_follow_mounted_horse()

	_update_lasso(delta)

	if _transition_locked or _dialog_active or DialogManager.is_showing() or _weapon_rig == null:
		return

	_shot_cooldown = maxf(_shot_cooldown - delta, 0.0)
	_scope_recoil_yaw = lerpf(_scope_recoil_yaw, 0.0, 1.0 - exp(-RECOIL_RECOVERY * delta))
	_scope_recoil_pitch = lerpf(_scope_recoil_pitch, 0.0, 1.0 - exp(-RECOIL_RECOVERY * delta))

	_update_mount_aim_spine(delta)

	var aim_target := _get_arm_aim_world_target()
	_weapon_rig.update(delta, aim_target)

	if _should_update_reticle():
		_update_reticle(delta)
	elif _reticle:
		_reset_reticle_state()
		_reticle.set_screen_offset(Vector2.ZERO)

	_update_scope_blend(delta)
	_update_combat_ui()
	_update_overworld_health(delta)
	_update_aim_camera(delta)
	_update_overworld_reload(delta)

	if _fire_held and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_fire_held = false
	if _fire_held and GroyperWeapons.is_full_auto(_equipped_weapon):
		_try_shoot()


func _input(event: InputEvent) -> void:
	if _transition_locked:
		get_viewport().set_input_as_handled()
		return

	if InventoryMenuManager.is_open():
		return

	if _dialog_active or DialogManager.is_showing() or ShopBuyManager.is_showing():
		if (
			event is InputEventKey
			and event.pressed
			and event.keycode == KEY_E
		):
			_try_interact()
		return

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var use_reticle := (
			_weapon_rig != null
			and _weapon_rig.can_use_reticle()
			and not _is_mounted()
		)
		if use_reticle:
			if _is_scope_aim_active():
				_apply_scope_look(event.relative)
			else:
				_reticle_velocity += event.relative * _get_reticle_mouse_accel()
		else:
			_camera_yaw -= event.relative.x * MOUSE_SENSITIVITY
			var pitch_min := CAMERA_PITCH_MIN
			var pitch_max := CAMERA_PITCH_MAX
			if _is_saddle_aim_mode():
				pitch_min = MOUNT_AIM_CAMERA_PITCH_MIN
				pitch_max = MOUNT_AIM_CAMERA_PITCH_MAX
				_clamp_mount_aim_camera_yaw()
			_camera_pitch = clampf(
				_camera_pitch - event.relative.y * MOUSE_SENSITIVITY,
				pitch_min,
				pitch_max
			)
	elif (
		event is InputEventMouseButton
		and event.pressed
		and (
			event.button_index == MOUSE_BUTTON_WHEEL_UP
			or event.button_index == MOUSE_BUTTON_WHEEL_DOWN
		)
	):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_try_cycle_weapon(1)
			else:
				_try_cycle_weapon(-1)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			if event.pressed:
				_try_shoot()
			_fire_held = event.pressed
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		elif _try_interrupt_reload_with_aim():
			pass
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == RELOAD_KEY:
		_try_overworld_reload_tap()
	elif event is InputEventKey and not event.pressed and event.keycode == RELOAD_KEY:
		_on_reload_key_released()
	elif (
		event is InputEventKey
		and event.pressed
		and event.keycode == KEY_E
	):
		_try_interact()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		if _mounted_horse == null:
			_try_cover_or_roll_action()


func _physics_process(delta: float) -> void:
	if _overworld_defeated:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	if _transition_locked or _dialog_active or DialogManager.is_showing() \
			or InventoryMenuManager.is_open() or ShopBuyManager.is_showing():
		velocity = Vector3.ZERO
		move_and_slide()
		_update_locomotion_blend(delta, 0.0, WALK_SPEED, RUN_SPEED)
		_update_interact_hint()
		return

	if _cover_walk_enter_active:
		_update_cover_walk_enter(delta)
		_camera_pivot.rotation.y = _camera_yaw
		_camera_arm.rotation.x = _camera_pitch
		_update_interact_hint()
		return

	if _cover_exit_active:
		_update_cover_exit(delta)
		_camera_pivot.rotation.y = _camera_yaw
		_camera_arm.rotation.x = _camera_pitch
		_update_interact_hint()
		return

	if _cover_crouch_active:
		_update_cover_crouch(delta)
		_camera_pivot.rotation.y = _camera_yaw
		_camera_arm.rotation.x = _camera_pitch
		_update_interact_hint()
		return

	if _vault_active:
		_update_vault(delta)
		_camera_pivot.rotation.y = _camera_yaw
		_camera_arm.rotation.x = _camera_pitch
		_update_interact_hint()
		return

	if _roll_active:
		_update_roll_dodge(delta)
		_camera_pivot.rotation.y = _camera_yaw
		_camera_arm.rotation.x = _camera_pitch
		_update_interact_hint()
		return

	if _mount_transition_active:
		velocity = Vector3.ZERO
		move_and_slide()
		_camera_pivot.rotation.y = _camera_yaw
		_camera_arm.rotation.x = _camera_pitch
		_update_interact_hint()
		return

	if _is_fully_mounted():
		velocity = Vector3.ZERO
		_locomotion_blend = lerpf(_locomotion_blend, 0.0, BLEND_SPEED * delta)
		if _animation_tree:
			_animation_tree.set("parameters/LocomotionBlend/blend_position", _locomotion_blend)
		_update_saddle_pose_blend(delta)
		_sync_mounted_model_to_mount()
		if _is_saddle_aim_mode():
			_clamp_mount_aim_camera_yaw()
		_camera_pivot.rotation.y = _camera_yaw
		_camera_arm.rotation.x = _camera_pitch
		_update_interact_hint()
		return

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = minf(velocity.y, 0.0)

	var move_dir := _get_camera_relative_input()
	var in_combat_stance := _weapon_rig != null and not _weapon_rig.is_holstered()
	var sprinting := (
		Input.is_key_pressed(KEY_SHIFT)
		and move_dir.length_squared() > 0.0001
		and not in_combat_stance
	)
	var walk_speed := AIM_WALK_SPEED if in_combat_stance else WALK_SPEED
	var run_speed := AIM_RUN_SPEED if in_combat_stance else RUN_SPEED
	if in_combat_stance and move_dir.length_squared() > 0.0001:
		walk_speed = _get_aim_walk_speed_for_direction(move_dir, walk_speed)
	var target_speed := run_speed if sprinting else walk_speed
	var current_h := Vector3(velocity.x, 0.0, velocity.z)
	var target_h := (
		move_dir * target_speed
		if move_dir.length_squared() > 0.0001
		else Vector3.ZERO
	)

	var move_rate := MOVE_ACCEL
	if target_h.length_squared() <= 0.0001:
		move_rate = MOVE_STOP_DECEL
	elif target_h.length_squared() < current_h.length_squared():
		move_rate = MOVE_DECEL

	var new_h := current_h.move_toward(target_h, move_rate * delta)
	velocity.x = new_h.x
	velocity.z = new_h.z
	move_and_slide()

	_update_facing(delta, move_dir)
	_update_locomotion_blend(delta, new_h.length(), walk_speed, run_speed, move_dir)
	if _locomotion_audio != null:
		_locomotion_audio.update(
			delta,
			move_dir.length_squared() > 0.0001,
			sprinting,
			new_h.length(),
			is_on_floor()
		)

	_camera_pivot.rotation.y = _camera_yaw
	_camera_arm.rotation.x = _camera_pitch
	_update_saddle_pose_blend(delta)
	_update_interact_hint()


func _update_saddle_pose_blend(delta: float) -> void:
	if _animation_tree == null:
		return
	var target := 1.0 if _mounted_horse != null else 0.0
	_saddle_blend = lerpf(_saddle_blend, target, SADDLE_BLEND_SPEED * delta)
	_animation_tree.set("parameters/SaddleBlend/blend_amount", _saddle_blend)


func _on_weapon_draw_state_changed(new_state: GroyperWeaponRig.DrawState) -> void:
	_update_combat_ui()
	_update_saddle_gun_arm_filter(new_state)
	_update_cover_peek_gun_arm_filter(new_state)
	refresh_stowed_weapon_visuals()
	if new_state == GroyperWeaponRig.DrawState.AIMING:
		if GroyperWeapons.has_scope_aim(_equipped_weapon):
			_seed_scope_aim_from_reticle()
	elif new_state != GroyperWeaponRig.DrawState.AIMING:
		_reset_scope_aim()
	if _is_mounted() and new_state == GroyperWeaponRig.DrawState.DRAWING:
		_mount_spine_yaw = 0.0
		if _weapon_rig != null:
			_weapon_rig.set_mount_aim_spine_yaw(0.0)


func _update_saddle_gun_arm_filter(draw_state: GroyperWeaponRig.DrawState) -> void:
	if _saddle_blend_node == null or _mounted_horse == null:
		return
	var saddle_owns_gun_arm := draw_state == GroyperWeaponRig.DrawState.HOLSTERED
	SaddlePoseConfig.set_gun_arm_blend_filtered(_saddle_blend_node, saddle_owns_gun_arm)


func _update_cover_peek_gun_arm_filter(draw_state: GroyperWeaponRig.DrawState) -> void:
	if _cover_peek_blend_node == null or not _cover_crouch_active:
		return
	var peek_owns_gun_arm := draw_state == GroyperWeaponRig.DrawState.HOLSTERED
	CoverPoseConfig.set_gun_aim_blend_filtered(_cover_peek_blend_node, peek_owns_gun_arm)


func _get_aim_camera_blend() -> float:
	if _weapon_rig == null:
		return 0.0

	match _weapon_rig.get_draw_state():
		GroyperWeaponRig.DrawState.AIMING:
			return 1.0
		GroyperWeaponRig.DrawState.DRAWING, GroyperWeaponRig.DrawState.HOLSTERING:
			return _weapon_rig.get_draw_progress()
		_:
			return 0.0


func _get_reload_camera_blend() -> float:
	if _weapon_rig == null:
		return 0.0

	var phase := _weapon_rig.get_overworld_reload_phase()
	match phase:
		GroyperWeaponRig.OverworldReloadPhase.EJECTING:
			return 1.0
		GroyperWeaponRig.OverworldReloadPhase.TAP_READY:
			return 1.0
		GroyperWeaponRig.OverworldReloadPhase.LOADING:
			return 1.0
		_:
			return 0.0


func _update_aim_camera(delta: float) -> void:
	if _camera == null:
		return

	var aim_target := _get_aim_camera_blend()
	var aim_smooth := AIM_FOV_SMOOTH
	if _cover_crouch_active and aim_target < _aim_camera_blend:
		aim_smooth = COVER_AIM_CAMERA_RELEASE_SMOOTH
	var aim_step := 1.0 - exp(-aim_smooth * delta)
	_aim_camera_blend = lerpf(_aim_camera_blend, aim_target, aim_step)
	var aim_blend := _aim_camera_blend
	var reload_target := _get_reload_camera_blend()
	var reload_step := 1.0 - exp(-RELOAD_CAMERA_SMOOTH * delta)
	_reload_camera_blend = lerpf(_reload_camera_blend, reload_target, reload_step)

	var weapon_fov_reduction := GroyperWeapons.get_aim_fov_reduction(
		_equipped_weapon,
		AIM_FOV_REDUCTION
	)
	var base_fov := lerpf(
		_explore_camera_fov,
		_explore_camera_fov - weapon_fov_reduction,
		aim_blend
	)
	var reload_fov_reduction := lerpf(
		RELOAD_FOV_REDUCTION,
		RELOAD_FOV_REDUCTION_AIMING,
		aim_blend
	)
	var target_fov := base_fov - reload_fov_reduction * _reload_camera_blend
	var scoped_fov := GroyperWeapons.get_scope_fov(_equipped_weapon)
	target_fov = lerpf(target_fov, scoped_fov, _scope_blend)
	var fov_smooth := RELOAD_CAMERA_SMOOTH if reload_target > 0.01 else AIM_FOV_SMOOTH
	var fov_step := 1.0 - exp(-fov_smooth * delta)
	_aim_fov_current = lerpf(_aim_fov_current, target_fov, fov_step)

	var aim_offset := AIM_CAMERA_OFFSET
	if _is_mounted():
		aim_offset = MOUNT_AIM_CAMERA_OFFSET
	var base_pos := _explore_camera_offset.lerp(aim_offset, aim_blend)
	var reload_pull := RELOAD_CAMERA_PULL_IN.lerp(RELOAD_CAMERA_PULL_IN_AIMING, aim_blend)
	_camera.position = base_pos + reload_pull * _reload_camera_blend
	_camera.fov = _aim_fov_current

	var scope_yaw := 0.0
	var scope_pitch := 0.0
	if _is_scope_aim_active():
		scope_yaw = _scope_yaw + _scope_recoil_yaw
		scope_pitch = _scope_pitch + _scope_recoil_pitch
	_camera_pivot.rotation.y = _camera_yaw + scope_yaw
	_camera_arm.rotation.x = _camera_pitch + scope_pitch


func _is_scope_aim_active() -> bool:
	if _weapon_rig == null or _is_mounted():
		return false
	return (
		GroyperWeapons.has_scope_aim(_equipped_weapon)
		and _weapon_rig.can_use_reticle()
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
	_scope_blend = 0.0
	if _scope_overlay and _scope_overlay.has_method("set_scope_blend"):
		_scope_overlay.set_scope_blend(0.0)
	if _reticle:
		_reticle.visible = true


func _update_scope_blend(delta: float) -> void:
	var target := 0.0
	if _is_scope_aim_active():
		target = 1.0

	var smooth := GroyperWeapons.get_scope_transition_smooth(_equipped_weapon)
	var step := 1.0 - exp(-smooth * delta)
	_scope_blend = lerpf(_scope_blend, target, step)

	if _scope_overlay and _scope_overlay.has_method("set_scope_blend"):
		_scope_overlay.set_scope_blend(_scope_blend)


func _is_mounted() -> bool:
	return _is_fully_mounted()


func _is_fully_mounted() -> bool:
	return _mounted_horse != null and not _mount_transition_active


func _is_saddle_aim_mode() -> bool:
	return _is_mounted() and _weapon_rig != null and not _weapon_rig.is_holstered()


func _get_mounted_rider_forward_dir() -> Vector3:
	if _model == null:
		return Vector3.FORWARD
	var forward := -_model.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		return Vector3.FORWARD
	return forward.normalized()


func _get_mount_aim_relative_yaw() -> float:
	var camera_forward := _get_camera_horizontal_forward()
	var rider_forward := _get_mounted_rider_forward_dir()
	if camera_forward.length_squared() < 0.0001 or rider_forward.length_squared() < 0.0001:
		return 0.0
	return atan2(
		rider_forward.cross(camera_forward).y,
		rider_forward.dot(camera_forward)
	)


func _clamp_mount_aim_camera_yaw() -> void:
	if not _is_saddle_aim_mode():
		return
	var relative_yaw := _get_mount_aim_relative_yaw()
	var clamped_yaw := clampf(relative_yaw, -MOUNT_AIM_YAW_LIMIT, MOUNT_AIM_YAW_LIMIT)
	if absf(clamped_yaw - relative_yaw) > 0.0001:
		_camera_yaw += clamped_yaw - relative_yaw


func _compute_mount_spine_yaw_target(relative_aim_yaw: float) -> float:
	var abs_yaw := absf(relative_aim_yaw)
	if abs_yaw <= MOUNT_AIM_SPINE_DEAD_ZONE:
		return 0.0
	return signf(relative_aim_yaw) * (abs_yaw - MOUNT_AIM_SPINE_DEAD_ZONE)


func _update_mount_aim_spine(delta: float) -> void:
	if _weapon_rig == null:
		return

	var target := 0.0
	if _is_saddle_aim_mode():
		_clamp_mount_aim_camera_yaw()
		target = _compute_mount_spine_yaw_target(_get_mount_aim_relative_yaw())

	var step := 1.0 - exp(-MOUNT_AIM_SPINE_SMOOTH * delta)
	_mount_spine_yaw = lerpf(_mount_spine_yaw, target, step)
	_weapon_rig.set_mount_aim_spine_yaw(_mount_spine_yaw)


func _update_combat_ui() -> void:
	if _weapon_rig == null:
		return

	var weapon_out := not _weapon_rig.is_holstered()
	var reloading := _weapon_rig.is_overworld_reloading()
	if _ammo_hud:
		_ammo_hud.visible = weapon_out or reloading
	if _reticle_ui:
		_reticle_ui.visible = _weapon_rig.can_use_reticle()


func _update_health_vignette() -> void:
	if _health_vignette == null:
		return
	_health_vignette.set_health(_health, BulletHitDamage.PLAYER_MAX_HEALTH)


func _update_overworld_health(delta: float) -> void:
	if not _overworld_combat_active or _overworld_defeated:
		return
	if _health >= BulletHitDamage.PLAYER_MAX_HEALTH:
		_health_regen_timer = 0.0
		return

	_health_regen_timer += delta
	while (
		_health_regen_timer >= HEALTH_REGEN_INTERVAL
		and _health < BulletHitDamage.PLAYER_MAX_HEALTH
	):
		_health_regen_timer -= HEALTH_REGEN_INTERVAL
		_health += 1
		_update_health_vignette()


func _try_shoot() -> void:
	if _weapon_rig == null or not _weapon_rig.can_fire():
		return
	if _weapon_rig.is_overworld_reloading():
		return
	if GroyperWeapons.is_lasso(_equipped_weapon):
		if _lasso_controller != null:
			_lasso_controller.try_throw()
		return
	if _shot_cooldown > 0.0 or _ammo <= 0:
		return

	_shot_cooldown = GroyperWeapons.get_shot_cooldown(_equipped_weapon)
	_weapon_rig.fire_at(_get_aim_world_target())
	_apply_shot_recoil()
	_ammo -= 1
	if _ammo_hud:
		_ammo_hud.sync_rounds(_ammo, true)


func _apply_shot_recoil() -> void:
	if not _is_scope_aim_active():
		return

	var stats := GroyperWeapons.get_stats(_equipped_weapon)
	var kick := float(stats.get("reticle_recoil_kick", 14.0))
	var randomness := float(stats.get("reticle_recoil_randomness", 0.18))
	var kick_rad := deg_to_rad(kick * 0.035)

	if randomness >= 0.95:
		var angle := randf() * TAU
		var magnitude := kick_rad * randf_range(0.8, 1.45)
		_scope_recoil_yaw += cos(angle) * magnitude
		_scope_recoil_pitch += sin(angle) * magnitude
	else:
		_scope_recoil_pitch += kick_rad
		_scope_recoil_yaw += deg_to_rad(randf_range(-kick * randomness, kick * randomness) * 0.035)


func _get_reticle_screen_position() -> Vector2:
	if _is_mounted() or _is_scope_aim_active():
		return get_viewport().get_visible_rect().size * 0.5
	return get_viewport().get_visible_rect().size * 0.5 + _reticle_offset


func _get_aim_ray_origin() -> Vector3:
	return _camera.project_ray_origin(_get_reticle_screen_position())


func _get_aim_direction() -> Vector3:
	return _camera.project_ray_normal(_get_reticle_screen_position()).normalized()


func _get_aim_world_target() -> Vector3:
	var origin := _get_aim_ray_origin()
	var direction := _get_aim_direction()

	var space_state := get_world_3d().direct_space_state
	if space_state:
		var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * SHOT_RANGE)
		query.collide_with_areas = false
		var hit := space_state.intersect_ray(query)
		if not hit.is_empty():
			return hit.position

	return origin + direction * SHOT_RANGE


func _get_lasso_throw_anchor() -> Vector3:
	if _weapon_rig != null:
		return _weapon_rig.get_muzzle_global_position()
	return global_position + Vector3(0.0, 1.2, 0.0)


func get_lasso_throw_anchor() -> Vector3:
	return _get_lasso_throw_anchor()


func get_lasso_leader_velocity() -> Vector3:
	if _mounted_horse != null and is_instance_valid(_mounted_horse):
		return Vector3(_mounted_horse.velocity.x, 0.0, _mounted_horse.velocity.z)
	return Vector3(velocity.x, 0.0, velocity.z)


func _can_use_lasso() -> bool:
	return (
		GroyperWeapons.is_lasso(_equipped_weapon)
		and _weapon_rig != null
		and _weapon_rig.can_fire()
		and not _overworld_defeated
		and not _transition_locked
	)


func _update_lasso(delta: float) -> void:
	if _lasso_controller == null:
		return

	var rmb_held := Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)

	if not GroyperWeapons.is_lasso(_equipped_weapon):
		if _lasso_controller.is_active():
			_lasso_controller.reset()
		_lasso_rmb_was_held = rmb_held
		return

	if _lasso_controller.is_dragging():
		if rmb_held and not _lasso_rmb_was_held:
			_lasso_controller.try_release_capture()
	elif (
		_lasso_rmb_was_held
		and not rmb_held
		and not _lasso_controller.is_holding_captive()
	):
		_lasso_controller.on_aim_released()

	_lasso_rmb_was_held = rmb_held

	var can_use := _can_use_lasso() or _lasso_controller.is_holding_captive()
	_lasso_controller.update(delta, rmb_held, can_use)


func _get_arm_aim_world_target() -> Vector3:
	var origin := _get_aim_ray_origin()
	var direction := _get_aim_direction()
	return origin + direction * AIM_ARM_TARGET_DISTANCE


func _should_update_reticle() -> bool:
	if _is_mounted() or _weapon_rig == null:
		return false
	if _weapon_rig.can_use_reticle():
		return true
	if not _cover_crouch_active:
		return false
	if _weapon_rig.get_draw_state() == GroyperWeaponRig.DrawState.HOLSTERING:
		return true
	return _aim_camera_blend > 0.02


func _get_cover_reticle_blend() -> float:
	if not _cover_crouch_active:
		return 0.0
	var cover := _cover_peek_blend
	if _weapon_rig != null and _weapon_rig.get_draw_state() == GroyperWeaponRig.DrawState.HOLSTERING:
		cover = maxf(cover, _aim_camera_blend)
	elif _aim_camera_blend > _cover_peek_blend:
		cover = _aim_camera_blend
	return cover


func _get_reticle_mouse_accel() -> float:
	var cover := _get_cover_reticle_blend()
	return lerpf(RETICLE_MOUSE_ACCEL, COVER_RETICLE_MOUSE_ACCEL, cover)


func _get_reticle_drag() -> float:
	var cover := _get_cover_reticle_blend()
	return lerpf(RETICLE_DRAG, COVER_RETICLE_DRAG, cover)


func _get_reticle_max_speed_px() -> float:
	var cover := _get_cover_reticle_blend()
	return lerpf(RETICLE_MAX_SPEED_PX, COVER_RETICLE_MAX_SPEED_PX, cover)


func _get_reticle_smooth() -> float:
	var cover := _get_cover_reticle_blend()
	return lerpf(RETICLE_SMOOTH, COVER_RETICLE_SMOOTH, cover)


func _update_reticle_limit() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	_reticle_limit_px = minf(viewport_size.x, viewport_size.y) * RETICLE_MAX_SCREEN_FRACTION


func _reset_reticle_state() -> void:
	_reticle_offset = Vector2.ZERO
	_reticle_offset_target = Vector2.ZERO
	_reticle_velocity = Vector2.ZERO


func _clamp_reticle_offset(offset: Vector2) -> Vector2:
	if offset.length() <= _reticle_limit_px:
		return offset
	return offset.normalized() * _reticle_limit_px


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
		var scope_step := 1.0 - exp(-_get_reticle_smooth() * delta)
		_reticle_offset = _reticle_offset.lerp(Vector2.ZERO, scope_step)
		if _reticle:
			_reticle.visible = false
			_reticle.set_screen_offset(Vector2.ZERO)
		return

	if _reticle:
		_reticle.visible = true

	var reticle_drag := _get_reticle_drag()
	var reticle_max_speed := _get_reticle_max_speed_px()
	var reticle_smooth := _get_reticle_smooth()

	_reticle_velocity *= exp(-reticle_drag * delta)
	var speed := _reticle_velocity.length()
	if speed > reticle_max_speed:
		_reticle_velocity = _reticle_velocity * (reticle_max_speed / speed)

	_reticle_offset_target += _reticle_velocity * delta
	_apply_reticle_boundary_velocity()

	var step := 1.0 - exp(-reticle_smooth * delta)
	var target := _clamp_reticle_offset(_reticle_offset_target)
	_reticle_offset = _reticle_offset.lerp(target, step)

	if _reticle and _reticle.has_method("set_screen_offset"):
		_reticle.set_screen_offset(_reticle_offset)


func _update_interact_hint() -> void:
	if _interact_hint == null:
		return

	if _mounted_horse != null:
		_interact_hint.text = "[E] Dismount"
		_interact_hint.visible = true
		return

	var target := _get_nearest_interactable()
	var mount_hint: bool = (
		target != null
		and target.has_method("get_interact_hint")
		and target.get_interact_hint() == "Mount"
	)
	var show_hint := (
		not _dialog_active
		and not DialogManager.is_showing()
		and target != null
		and (_weapon_rig == null or _weapon_rig.is_holstered() or mount_hint)
	)
	if show_hint and target.has_method("get_interact_hint"):
		_interact_hint.text = "[E] %s" % target.get_interact_hint()
	else:
		_interact_hint.text = "[E] Talk"
	_interact_hint.visible = show_hint


func _setup_locomotion_library() -> void:
	if _animation_player == null:
		push_error("GroyperOverworldPlayer: missing AnimationPlayer on body.")
		return

	if _animation_tree.active:
		_animation_tree.active = false

	var library := AnimationLibrary.new()
	_add_locomotion_clip(library, RigAnimConfig.LOCOMOTION_IDLE, RigAnimConfig.IDLE_SCENE)
	_add_locomotion_clip(library, RigAnimConfig.LOCOMOTION_WALK, RigAnimConfig.WALK_SCENE)
	_add_locomotion_clip(library, RigAnimConfig.LOCOMOTION_RUN, RigAnimConfig.RUN_SCENE)
	_add_reversed_walk_clip(library)

	if _animation_player.has_animation_library(RigAnimConfig.LOCOMOTION_LIBRARY):
		_animation_player.remove_animation_library(RigAnimConfig.LOCOMOTION_LIBRARY)
	_animation_player.add_animation_library(RigAnimConfig.LOCOMOTION_LIBRARY, library)


func _add_locomotion_clip(
	library: AnimationLibrary,
	clip_name: StringName,
	scene_path: String
) -> void:
	var raw := RigAnimUtils.load_skeleton_animation(scene_path)
	if raw == null:
		push_error(
			"GroyperOverworldPlayer: failed to load locomotion clip '%s' from %s."
			% [clip_name, scene_path]
		)
		return
	var animation := RigAnimUtils.prepare_for_body_player(raw, false)
	RigAnimUtils.strip_root_motion(animation)
	animation.loop_mode = Animation.LOOP_LINEAR
	library.add_animation(clip_name, animation)


func _add_reversed_walk_clip(library: AnimationLibrary) -> void:
	var walk := library.get_animation(RigAnimConfig.LOCOMOTION_WALK)
	if walk == null:
		push_error("GroyperOverworldPlayer: missing walk clip for walk_reverse.")
		return

	var reversed := RigAnimUtils.make_reversed_animation(walk)
	reversed.loop_mode = Animation.LOOP_LINEAR
	library.add_animation(RigAnimConfig.LOCOMOTION_WALK_REVERSE, reversed)


func _setup_roll_dodge_library() -> void:
	if _animation_player == null:
		push_error("GroyperOverworldPlayer: missing AnimationPlayer on body.")
		return

	var source := RollDodgeExtract.load_authored_library()
	if source == null:
		push_error("GroyperOverworldPlayer: missing roll_dodge.tres — run RollDodgeExtract.")
		return

	if _animation_player.has_animation_library(RollDodgeConfig.LIBRARY_NAME):
		_animation_player.remove_animation_library(RollDodgeConfig.LIBRARY_NAME)
	_animation_player.add_animation_library(RollDodgeConfig.LIBRARY_NAME, source.duplicate(true))


func _setup_vault_library() -> void:
	if _animation_player == null:
		push_error("GroyperOverworldPlayer: missing AnimationPlayer on body.")
		return

	var source := VaultExtractScript.load_authored_library()
	if source == null:
		push_error("GroyperOverworldPlayer: missing vault.tres — run VaultExtract.")
		return

	if _animation_player.has_animation_library(VaultConfigScript.LIBRARY_NAME):
		_animation_player.remove_animation_library(VaultConfigScript.LIBRARY_NAME)
	_animation_player.add_animation_library(VaultConfigScript.LIBRARY_NAME, source.duplicate(true))


func _setup_animation_tree() -> void:
	if _animation_player == null:
		return

	var idle_path := StringName(
		"%s/%s" % [RigAnimConfig.LOCOMOTION_LIBRARY, RigAnimConfig.LOCOMOTION_IDLE]
	)
	var walk_path := StringName(
		"%s/%s" % [RigAnimConfig.LOCOMOTION_LIBRARY, RigAnimConfig.LOCOMOTION_WALK]
	)
	var run_path := StringName(
		"%s/%s" % [RigAnimConfig.LOCOMOTION_LIBRARY, RigAnimConfig.LOCOMOTION_RUN]
	)
	var walk_reverse_path := StringName(
		"%s/%s" % [RigAnimConfig.LOCOMOTION_LIBRARY, RigAnimConfig.LOCOMOTION_WALK_REVERSE]
	)

	if (
		not _animation_player.has_animation(idle_path)
		or not _animation_player.has_animation(walk_path)
		or not _animation_player.has_animation(run_path)
		or not _animation_player.has_animation(walk_reverse_path)
	):
		push_error("GroyperOverworldPlayer: locomotion clips missing on AnimationPlayer.")
		return

	var walk_roll_path := StringName(
		"%s/%s" % [RollDodgeConfig.LIBRARY_NAME, RollDodgeConfig.WALK_ROLL]
	)
	if not _animation_player.has_animation(walk_roll_path):
		push_error("GroyperOverworldPlayer: roll dodge clips missing on AnimationPlayer.")
		return

	var walk_vault_path := StringName(
		"%s/%s" % [VaultConfigScript.LIBRARY_NAME, VaultConfigScript.WALK_VAULT]
	)
	if not _animation_player.has_animation(walk_vault_path):
		push_error("GroyperOverworldPlayer: vault clips missing on AnimationPlayer.")
		return

	var crouch_cover_path := CoverPoseConfig.get_crouch_cover_path()
	if not _animation_player.has_animation(crouch_cover_path):
		push_error("GroyperOverworldPlayer: cover pose clips missing on AnimationPlayer.")
		return

	var cover_peek_aim_path := CoverPoseConfig.get_cover_peek_aim_path()
	if not _animation_player.has_animation(cover_peek_aim_path):
		push_error("GroyperOverworldPlayer: cover_peek_aim missing on AnimationPlayer.")
		return

	var saddle_path := SaddlePoseConfig.get_animation_path()
	if not _animation_player.has_animation(saddle_path):
		push_warning(
			"GroyperOverworldPlayer: missing %s — author in groyper_body.tscn."
			% saddle_path
		)

	var idle_node := AnimationNodeAnimation.new()
	idle_node.animation = idle_path

	var walk_node := AnimationNodeAnimation.new()
	walk_node.animation = walk_path

	var run_node := AnimationNodeAnimation.new()
	run_node.animation = run_path

	var walk_reverse_node := AnimationNodeAnimation.new()
	walk_reverse_node.animation = walk_reverse_path

	var blend_space := AnimationNodeBlendSpace1D.new()
	blend_space.add_blend_point(walk_reverse_node, LOCOMOTION_WALK_REVERSE_BLEND)
	blend_space.add_blend_point(idle_node, LOCOMOTION_IDLE_BLEND)
	blend_space.add_blend_point(walk_node, LOCOMOTION_WALK_BLEND)
	blend_space.add_blend_point(run_node, LOCOMOTION_RUN_BLEND)
	blend_space.min_space = LOCOMOTION_WALK_REVERSE_BLEND
	blend_space.max_space = LOCOMOTION_RUN_BLEND
	blend_space.sync = true
	blend_space.snap = 0.0

	_roll_anim_node = AnimationNodeAnimation.new()
	_roll_anim_node.animation = walk_roll_path

	var roll_one_shot := AnimationNodeOneShot.new()
	roll_one_shot.fadein_time = ROLL_ANIM_FADEIN
	roll_one_shot.fadeout_time = ROLL_ANIM_FADEOUT
	roll_one_shot.sync = true

	_vault_anim_node = AnimationNodeAnimation.new()
	_vault_anim_node.animation = walk_vault_path

	var vault_time_seek := AnimationNodeTimeSeek.new()

	_vault_blend_node = AnimationNodeBlend2.new()
	_vault_blend_node.sync = false

	var crouch_cover_anim := AnimationNodeAnimation.new()
	crouch_cover_anim.animation = crouch_cover_path

	_cover_pose_blend_node = AnimationNodeBlend2.new()
	_cover_pose_blend_node.sync = false
	CoverPoseConfig.configure_cover_pose_blend(_cover_pose_blend_node)

	var cover_peek_aim_anim := AnimationNodeAnimation.new()
	cover_peek_aim_anim.animation = cover_peek_aim_path

	_cover_peek_blend_node = AnimationNodeBlend2.new()
	_cover_peek_blend_node.sync = false
	CoverPoseConfig.configure_cover_peek_blend(_cover_peek_blend_node)

	var saddle_anim := AnimationNodeAnimation.new()
	saddle_anim.animation = saddle_path

	_saddle_blend_node = AnimationNodeBlend2.new()
	_saddle_blend_node.sync = false
	SaddlePoseConfig.configure_saddle_blend_filter(_saddle_blend_node)

	var blend_tree := AnimationNodeBlendTree.new()
	blend_tree.add_node(LOCOMOTION_BLEND, blend_space)
	blend_tree.add_node(ROLL_ANIM_NODE, _roll_anim_node)
	blend_tree.add_node(ROLL_ONE_SHOT, roll_one_shot)
	blend_tree.add_node(VAULT_ANIM_NODE, _vault_anim_node)
	blend_tree.add_node(VAULT_TIME_SEEK, vault_time_seek)
	blend_tree.add_node(VAULT_BLEND, _vault_blend_node)
	blend_tree.add_node(CROUCH_COVER_ANIM_NODE, crouch_cover_anim)
	blend_tree.add_node(COVER_POSE_BLEND, _cover_pose_blend_node)
	blend_tree.add_node(COVER_PEEK_AIM_ANIM_NODE, cover_peek_aim_anim)
	blend_tree.add_node(COVER_PEEK_BLEND, _cover_peek_blend_node)
	blend_tree.add_node(SADDLE_ANIM_NODE, saddle_anim)
	blend_tree.add_node(SADDLE_BLEND, _saddle_blend_node)
	blend_tree.connect_node(ROLL_ONE_SHOT, 0, LOCOMOTION_BLEND)
	blend_tree.connect_node(ROLL_ONE_SHOT, 1, ROLL_ANIM_NODE)
	blend_tree.connect_node(VAULT_BLEND, 0, ROLL_ONE_SHOT)
	blend_tree.connect_node(VAULT_TIME_SEEK, 0, VAULT_ANIM_NODE)
	blend_tree.connect_node(VAULT_BLEND, 1, VAULT_TIME_SEEK)
	blend_tree.connect_node(COVER_POSE_BLEND, 0, VAULT_BLEND)
	blend_tree.connect_node(COVER_POSE_BLEND, 1, CROUCH_COVER_ANIM_NODE)
	blend_tree.connect_node(COVER_PEEK_BLEND, 0, COVER_POSE_BLEND)
	blend_tree.connect_node(COVER_PEEK_BLEND, 1, COVER_PEEK_AIM_ANIM_NODE)
	blend_tree.connect_node(SADDLE_BLEND, 0, COVER_PEEK_BLEND)
	blend_tree.connect_node(SADDLE_BLEND, 1, SADDLE_ANIM_NODE)
	blend_tree.connect_node(&"output", 0, SADDLE_BLEND)

	_animation_tree.tree_root = blend_tree
	_animation_tree.anim_player = _animation_tree.get_path_to(_animation_player)
	_animation_tree.process_priority = -100
	_animation_tree.active = true
	_init_vault_animation_tree_state()


func _init_vault_animation_tree_state() -> void:
	_vault_blend = 0.0
	if _animation_tree == null:
		return
	_animation_tree.set("parameters/%s/blend_amount" % VAULT_BLEND, 0.0)
	_animation_tree.set("parameters/%s/seek_request" % VAULT_TIME_SEEK, -1.0)


func _setup_cover_pose_library() -> void:
	if _animation_player == null:
		push_error("GroyperOverworldPlayer: missing AnimationPlayer on body.")
		return

	var source := CoverPoseExtractScript.load_authored_library()
	if source == null:
		push_error(
			"GroyperOverworldPlayer: missing cover_pose.tres — "
			+ "toggle CoverPoseCapture on groyper_body.tscn or run CoverPoseExtract."
		)
		return

	if _animation_player.has_animation_library(CoverPoseConfig.LIBRARY_NAME):
		_animation_player.remove_animation_library(CoverPoseConfig.LIBRARY_NAME)
	_animation_player.add_animation_library(
		CoverPoseConfig.LIBRARY_NAME,
		source.duplicate(true)
	)

	_setup_cover_peek_pose_library()


func _setup_cover_peek_pose_library() -> void:
	if _animation_player == null:
		return

	var source := CoverPoseExtractScript.load_cover_peek_library()
	if source == null:
		push_error(
			"GroyperOverworldPlayer: missing cover_peek_aim.tres — "
			+ "author in groyper_body.tscn or run CoverPoseExtract."
		)
		return

	if _animation_player.has_animation_library(CoverPoseConfig.COVER_PEEK_LIBRARY_NAME):
		_animation_player.remove_animation_library(CoverPoseConfig.COVER_PEEK_LIBRARY_NAME)
	_animation_player.add_animation_library(
		CoverPoseConfig.COVER_PEEK_LIBRARY_NAME,
		source.duplicate(true)
	)


func _try_cover_or_roll_action() -> void:
	var vault := _find_nearby_vault()
	if vault != null:
		_try_vault(vault)
		return
	var cover := _find_nearby_cover()
	if cover != null:
		_try_use_cover(cover)
	else:
		_try_roll_dodge()


func _can_use_cover() -> bool:
	if (
		_cover_walk_enter_active
		or _cover_exit_active
		or _cover_crouch_active
		or _vault_active
		or _roll_active
		or _overworld_defeated
		or _dialog_active
		or DialogManager.is_showing()
	):
		return false
	if _weapon_rig != null and (_weapon_rig.is_overworld_reloading() or not _weapon_rig.is_holstered()):
		return false
	return true


func _try_use_cover(cover: CoverPiece) -> void:
	if not _can_use_cover():
		return
	_start_walk_into_cover(cover)


func _start_walk_into_cover(cover: CoverPiece) -> void:
	var near_spot: Dictionary = cover.get_crouch_spot(self, false)

	_cover_floor_y = global_position.y
	_active_cover = cover
	_cover_walk_enter_active = true
	_cover_walk_enter_timer = 0.0
	_cover_walk_enter_from = global_position
	_cover_walk_enter_to = _flat_cover_position(near_spot["position"])
	_cover_walk_enter_from_facing = _model.rotation.y if _model != null else 0.0
	_cover_walk_enter_facing = near_spot["facing_yaw"]
	_cover_crouch_blend = 0.0
	velocity = Vector3.ZERO

	if _animation_tree != null:
		_animation_tree.set("parameters/%s/blend_amount" % COVER_POSE_BLEND, 0.0)


func _update_cover_walk_enter(delta: float) -> void:
	velocity = Vector3.ZERO

	_cover_walk_enter_timer += delta
	var progress := clampf(
		_cover_walk_enter_timer / maxf(COVER_WALK_ENTER_DURATION, 0.001),
		0.0,
		1.0
	)
	var eased := progress * progress * (3.0 - 2.0 * progress)
	var pos := _cover_walk_enter_from.lerp(_cover_walk_enter_to, eased)
	pos.y = _cover_floor_y
	global_position = pos
	_set_model_facing_yaw(
		lerp_angle(_cover_walk_enter_from_facing, _cover_walk_enter_facing, eased)
	)

	_cover_crouch_blend = eased
	if _animation_tree != null:
		_animation_tree.set("parameters/%s/blend_amount" % COVER_POSE_BLEND, _cover_crouch_blend)

	_update_locomotion_blend(delta, 0.0, WALK_SPEED, RUN_SPEED)

	if progress >= 1.0:
		_cover_walk_enter_active = false
		_cover_walk_enter_timer = 0.0
		_enter_crouch_cover_state(_cover_crouch_blend)


func _enter_crouch_cover_state(blend: float) -> void:
	_cover_crouch_active = true
	_cover_peek_active = false
	_cover_peek_blend = 0.0
	_cover_crouch_blend = blend
	velocity = Vector3.ZERO
	global_position.y = _cover_floor_y
	_cover_hold_position = global_position
	if _weapon_rig != null:
		_weapon_rig.set_cover_crouch_hold(true)
	if _animation_tree != null:
		_animation_tree.set("parameters/%s/blend_amount" % COVER_POSE_BLEND, blend)
		_animation_tree.set("parameters/%s/blend_amount" % COVER_PEEK_BLEND, 0.0)
	if _cover_peek_blend_node != null and _weapon_rig != null:
		_update_cover_peek_gun_arm_filter(_weapon_rig.get_draw_state())


func _find_nearby_cover() -> CoverPiece:
	var nearest: CoverPiece
	var nearest_dist_sq := INF
	for node in get_tree().get_nodes_in_group("cover_piece"):
		if not node is CoverPiece:
			continue
		var cover := node as CoverPiece
		if not cover.is_player_in_range(self):
			continue
		var dist_sq := global_position.distance_squared_to(cover.get_cover_anchor())
		if dist_sq < nearest_dist_sq:
			nearest_dist_sq = dist_sq
			nearest = cover
	return nearest


func _find_nearby_vault() -> VaultPiece:
	var nearest: VaultPiece
	var nearest_dist_sq := INF
	for node in get_tree().get_nodes_in_group("vault_piece"):
		if not node is VaultPiece:
			continue
		var vault := node as VaultPiece
		if not vault.is_player_in_range(self) or not vault.is_player_touching(self):
			continue
		var dist_sq := global_position.distance_squared_to(vault.get_vault_anchor())
		if dist_sq < nearest_dist_sq:
			nearest_dist_sq = dist_sq
			nearest = vault
	return nearest


func _can_vault() -> bool:
	if (
		_vault_active
		or _roll_active
		or _cover_walk_enter_active
		or _cover_exit_active
		or _cover_crouch_active
		or _overworld_defeated
		or _dialog_active
		or DialogManager.is_showing()
	):
		return false
	if _weapon_rig != null and (_weapon_rig.is_overworld_reloading() or not _weapon_rig.is_holstered()):
		return false
	return true


func _is_running_for_vault() -> bool:
	var move_dir := _get_camera_relative_input()
	var in_combat_stance := _weapon_rig != null and not _weapon_rig.is_holstered()
	var sprinting := (
		Input.is_key_pressed(KEY_SHIFT)
		and move_dir.length_squared() > 0.0001
		and not in_combat_stance
	)
	if sprinting:
		return true
	return Vector2(velocity.x, velocity.z).length() >= RUN_VAULT_SPEED_THRESHOLD


func _try_vault(vault: VaultPiece) -> void:
	if not _can_vault():
		return
	var spot := vault.get_vault_spot(self)
	var clip_name := (
		VaultConfigScript.RUN_VAULT if _is_running_for_vault() else VaultConfigScript.WALK_VAULT
	)
	_start_vault(clip_name, spot)


func _start_vault(clip_name: StringName, spot: Dictionary) -> void:
	var anim_path := StringName("%s/%s" % [VaultConfigScript.LIBRARY_NAME, clip_name])
	if _animation_player == null or not _animation_player.has_animation(anim_path):
		push_error("GroyperOverworldPlayer: missing vault clip '%s'." % clip_name)
		return

	var animation := _animation_player.get_animation(anim_path)
	_vault_duration = animation.length
	_vault_move_duration = maxf(_vault_duration * VAULT_MOVE_TIME_SCALE, 0.001)
	_vault_timer = 0.0
	_vault_exit_active = false
	_vault_exit_timer = 0.0
	_vault_blend = 0.0
	_vault_active = true
	_vault_start = spot["start"]
	_vault_end = spot["end"]
	_vault_floor_y = global_position.y
	_vault_facing_yaw = spot["facing_yaw"]
	_vault_cross_direction = spot["cross_direction"]
	velocity = Vector3.ZERO

	global_position = Vector3(_vault_start.x, _vault_floor_y, _vault_start.z)
	_set_model_facing_yaw(_vault_facing_yaw)

	if _vault_anim_node != null:
		_vault_anim_node.animation = anim_path
	_restart_vault_animation()
	_set_vault_tree_blend(0.0)


func _restart_vault_animation() -> void:
	if _animation_tree == null:
		return
	_animation_tree.set("parameters/%s/seek_request" % VAULT_TIME_SEEK, 0.0)


func _set_vault_tree_blend(amount: float) -> void:
	_vault_blend = clampf(amount, 0.0, 1.0)
	if _animation_tree != null:
		_animation_tree.set("parameters/%s/blend_amount" % VAULT_BLEND, _vault_blend)


func _update_vault(delta: float) -> void:
	if _vault_exit_active:
		_update_vault_exit(delta)
		return

	_vault_timer += delta
	var move_progress := clampf(_vault_timer / _vault_move_duration, 0.0, 1.0)
	var eased := move_progress * move_progress * (3.0 - 2.0 * move_progress)
	var pos := _vault_start.lerp(_vault_end, eased)
	pos.y = _vault_floor_y + sin(move_progress * PI) * VAULT_PEAK_HEIGHT
	global_position = pos
	velocity = Vector3.ZERO

	if move_progress >= 1.0:
		var exit_yaw := atan2(_vault_cross_direction.x, _vault_cross_direction.z)
		_set_model_facing_yaw(exit_yaw)
	else:
		_set_model_facing_yaw(_vault_facing_yaw)

	var enter_t := clampf(_vault_timer / maxf(VAULT_ANIM_FADEIN, 0.001), 0.0, 1.0)
	var enter_eased := enter_t * enter_t * (3.0 - 2.0 * enter_t)
	_set_vault_tree_blend(enter_eased)
	_update_vault_locomotion_blend(delta, move_progress)

	if move_progress >= 1.0:
		_begin_vault_exit()


func _begin_vault_exit() -> void:
	if _vault_exit_active:
		return
	global_position = Vector3(_vault_end.x, _vault_floor_y, _vault_end.z)
	var ctx := _get_vault_move_context()
	if ctx.move_dir.length_squared() > 0.0001:
		var exit_yaw := atan2(ctx.move_dir.x, ctx.move_dir.z)
		_set_model_facing_yaw(exit_yaw)
		velocity.x = ctx.move_dir.x * ctx.target_speed
		velocity.z = ctx.move_dir.z * ctx.target_speed
	else:
		velocity = Vector3.ZERO
	_vault_exit_active = true
	_vault_exit_timer = 0.0


func _update_vault_exit(delta: float) -> void:
	_vault_exit_timer += delta
	var progress := clampf(
		_vault_exit_timer / maxf(VAULT_EXIT_BLEND_DURATION, 0.001),
		0.0,
		1.0
	)
	var eased := progress * progress * (3.0 - 2.0 * progress)
	_set_vault_tree_blend(1.0 - eased)

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = minf(velocity.y, 0.0)

	var ctx := _get_vault_move_context()
	var move_dir: Vector3 = ctx.get("move_dir", Vector3.ZERO)
	var walk_speed: float = float(ctx.get("walk_speed", WALK_SPEED))
	var run_speed: float = float(ctx.get("run_speed", RUN_SPEED))
	var current_h := Vector3(velocity.x, 0.0, velocity.z)
	var target_h: Vector3 = (
		move_dir * float(ctx.get("target_speed", 0.0))
		if move_dir.length_squared() > 0.0001
		else Vector3.ZERO
	)
	var move_rate := MOVE_ACCEL if target_h.length_squared() > 0.0001 else MOVE_STOP_DECEL
	var new_h := current_h.move_toward(target_h, move_rate * delta)
	velocity.x = new_h.x
	velocity.z = new_h.z
	move_and_slide()

	_update_facing(delta, move_dir)
	_update_locomotion_blend(delta, new_h.length(), walk_speed, run_speed, move_dir)

	if progress >= 1.0:
		_finish_vault()


func _get_vault_move_context() -> Dictionary:
	var move_dir := _get_camera_relative_input()
	var in_combat_stance := _weapon_rig != null and not _weapon_rig.is_holstered()
	var sprinting := (
		Input.is_key_pressed(KEY_SHIFT)
		and move_dir.length_squared() > 0.0001
		and not in_combat_stance
	)
	var walk_speed := AIM_WALK_SPEED if in_combat_stance else WALK_SPEED
	var run_speed := AIM_RUN_SPEED if in_combat_stance else RUN_SPEED
	if in_combat_stance and move_dir.length_squared() > 0.0001:
		walk_speed = _get_aim_walk_speed_for_direction(move_dir, walk_speed)
	var target_speed := 0.0
	if move_dir.length_squared() > 0.0001:
		target_speed = run_speed if sprinting else walk_speed
	return {
		"move_dir": move_dir,
		"walk_speed": walk_speed,
		"run_speed": run_speed,
		"target_speed": target_speed,
	}


func _update_vault_locomotion_blend(delta: float, move_progress: float) -> void:
	var ctx := _get_vault_move_context()
	var target := _compute_locomotion_blend_target(
		ctx.target_speed,
		ctx.walk_speed,
		ctx.run_speed,
		ctx.move_dir
	)
	var blend_speed := BLEND_SPEED
	if move_progress >= 0.35:
		blend_speed *= VAULT_LOCOMOTION_BLEND_BOOST
	_locomotion_blend = lerpf(_locomotion_blend, target, blend_speed * delta)
	if _animation_tree != null:
		_animation_tree.set("parameters/LocomotionBlend/blend_position", _locomotion_blend)


func _finish_vault() -> void:
	if not _vault_active:
		return
	_set_vault_tree_blend(0.0)
	_vault_active = false
	_vault_exit_active = false
	_vault_exit_timer = 0.0
	_vault_timer = 0.0
	_vault_duration = 0.0
	_vault_move_duration = 0.0
	_vault_start = Vector3.ZERO
	_vault_end = Vector3.ZERO
	_vault_facing_yaw = 0.0
	_vault_cross_direction = Vector3.FORWARD


func _update_cover_crouch(delta: float) -> void:
	velocity.y = 0.0

	var want_peek := Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	if want_peek != _cover_peek_active:
		_cover_peek_active = want_peek
		if _weapon_rig != null:
			_weapon_rig.set_cover_crouch_peek(want_peek)

	_cover_crouch_blend = 1.0
	var peek_target := 1.0 if _cover_peek_active else 0.0
	var peek_step := 1.0 - exp(-COVER_PEEK_BLEND_SPEED * delta)
	_cover_peek_blend = lerpf(_cover_peek_blend, peek_target, peek_step)
	if _animation_tree != null:
		_animation_tree.set("parameters/%s/blend_amount" % COVER_POSE_BLEND, _cover_crouch_blend)
		_animation_tree.set("parameters/%s/blend_amount" % COVER_PEEK_BLEND, _cover_peek_blend)
	if _weapon_rig != null:
		_update_cover_peek_gun_arm_filter(_weapon_rig.get_draw_state())

	if _cover_peek_active:
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		var move_dir := _get_camera_relative_input()
		if move_dir.length_squared() > 0.0001:
			velocity.x = move_dir.x * WALK_SPEED
			velocity.z = move_dir.z * WALK_SPEED
			_update_facing(delta, move_dir)
		else:
			velocity.x = 0.0
			velocity.z = 0.0

	move_and_slide()
	_pin_cover_floor_height()
	_update_locomotion_blend(delta, Vector2(velocity.x, velocity.z).length(), WALK_SPEED, RUN_SPEED)

	if (
		_active_cover == null
		or not _active_cover.is_player_holding_cover(self, _cover_hold_position)
	):
		_begin_cover_exit()


func _begin_cover_exit() -> void:
	if _cover_exit_active:
		return

	_cover_exit_active = true
	_cover_exit_timer = 0.0
	_cover_peek_active = false
	_cover_peek_blend = 0.0
	velocity = Vector3.ZERO

	if _animation_tree != null:
		_animation_tree.set("parameters/%s/blend_amount" % COVER_PEEK_BLEND, 0.0)

	if _weapon_rig != null:
		if not _weapon_rig.is_holstered():
			_weapon_rig.reset_to_holster()
		_weapon_rig.set_cover_crouch_peek(false)
		_weapon_rig.set_cover_crouch_hold(false)


func _update_cover_exit(delta: float) -> void:
	velocity.y = 0.0
	_cover_exit_timer += delta

	var progress := clampf(
		_cover_exit_timer / maxf(COVER_EXIT_DURATION, 0.001),
		0.0,
		1.0
	)
	var eased := progress * progress * (3.0 - 2.0 * progress)

	_cover_crouch_blend = 1.0 - eased
	if _animation_tree != null:
		_animation_tree.set("parameters/%s/blend_amount" % COVER_POSE_BLEND, _cover_crouch_blend)

	var move_dir := _get_camera_relative_input()
	var move_scale := eased
	if move_dir.length_squared() > 0.0001:
		velocity.x = move_dir.x * WALK_SPEED * move_scale
		velocity.z = move_dir.z * WALK_SPEED * move_scale
		_update_facing(delta, move_dir)
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()
	_pin_cover_floor_height()
	_update_locomotion_blend(
		delta,
		Vector2(velocity.x, velocity.z).length(),
		WALK_SPEED,
		RUN_SPEED
	)

	if progress >= 1.0:
		_finish_cover_exit()


func _finish_cover_exit() -> void:
	_cover_exit_active = false
	_cover_crouch_active = false
	_cover_peek_active = false
	_cover_peek_blend = 0.0
	_cover_walk_enter_active = false
	_cover_exit_timer = 0.0
	_cover_crouch_blend = 0.0
	_cover_hold_position = Vector3.ZERO
	_active_cover = null
	velocity = Vector3.ZERO
	if _animation_tree != null:
		_animation_tree.set("parameters/%s/blend_amount" % COVER_POSE_BLEND, 0.0)
		_animation_tree.set("parameters/%s/blend_amount" % COVER_PEEK_BLEND, 0.0)
	_update_combat_ui()


func _flat_cover_position(spot: Vector3) -> Vector3:
	return Vector3(spot.x, _cover_floor_y, spot.z)


func _pin_cover_floor_height() -> void:
	global_position.y = _cover_floor_y
	velocity.y = 0.0


func _exit_cover_crouch() -> void:
	_begin_cover_exit()


func _set_model_facing_yaw(yaw: float) -> void:
	if _model != null:
		_model.rotation.y = yaw


func _try_roll_dodge() -> void:
	if _cover_crouch_active or _cover_walk_enter_active or _cover_exit_active or _vault_active:
		return
	if (
		_roll_active
		or _overworld_defeated
		or _dialog_active
		or DialogManager.is_showing()
	):
		return
	if _weapon_rig != null and (_weapon_rig.is_overworld_reloading() or not _weapon_rig.is_holstered()):
		return

	var move_dir := _get_camera_relative_input()
	if move_dir.length_squared() < 0.0001:
		return

	var in_combat_stance := _weapon_rig != null and not _weapon_rig.is_holstered()
	var sprinting := (
		Input.is_key_pressed(KEY_SHIFT)
		and not in_combat_stance
	)
	var walk_speed := WALK_SPEED
	var run_speed := RUN_SPEED
	var clip_name := RollDodgeConfig.RUN_ROLL if sprinting else RollDodgeConfig.WALK_ROLL
	var base_speed := run_speed if sprinting else walk_speed

	_start_roll_dodge(clip_name, move_dir, base_speed)


func _start_roll_dodge(clip_name: StringName, direction: Vector3, base_speed: float) -> void:
	var anim_path := StringName("%s/%s" % [RollDodgeConfig.LIBRARY_NAME, clip_name])
	if _animation_player == null or not _animation_player.has_animation(anim_path):
		push_error("GroyperOverworldPlayer: missing roll clip '%s'." % clip_name)
		return

	var animation := _animation_player.get_animation(anim_path)
	_roll_duration = animation.length
	_roll_timer = 0.0
	_roll_active = true
	_roll_direction = direction.normalized()
	_roll_speed = base_speed
	_roll_is_run = clip_name == RollDodgeConfig.RUN_ROLL
	_roll_speed_multiplier = (
		RUN_ROLL_SPEED_MULTIPLIER if _roll_is_run else ROLL_SPEED_MULTIPLIER
	)

	var boosted := Vector3(velocity.x, 0.0, velocity.z)
	if boosted.length_squared() < 0.0001:
		boosted = _roll_direction * base_speed
	else:
		boosted = boosted.normalized() * maxf(boosted.length(), base_speed)
	boosted *= _roll_speed_multiplier
	velocity.x = boosted.x
	velocity.z = boosted.z

	if _roll_anim_node != null:
		_roll_anim_node.animation = anim_path
	if _animation_tree != null:
		_animation_tree.set(
			"parameters/%s/request" % ROLL_ONE_SHOT,
			AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
		)


func _update_roll_dodge(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = minf(velocity.y, 0.0)

	velocity.x = _roll_direction.x * _roll_speed * _roll_speed_multiplier
	velocity.z = _roll_direction.z * _roll_speed * _roll_speed_multiplier
	move_and_slide()

	_roll_timer += delta
	_update_facing(delta, _roll_direction)
	_update_locomotion_blend(delta, 0.0, WALK_SPEED, RUN_SPEED)

	if _roll_timer >= _roll_duration:
		_finish_roll_dodge()


func _finish_roll_dodge() -> void:
	if _roll_is_run:
		_snap_run_roll_exit_velocity()
	_roll_active = false
	_roll_timer = 0.0
	_roll_duration = 0.0
	_roll_direction = Vector3.ZERO
	_roll_speed = 0.0
	_roll_speed_multiplier = ROLL_SPEED_MULTIPLIER
	_roll_is_run = false


func _snap_run_roll_exit_velocity() -> void:
	var move_dir := _get_camera_relative_input()
	if move_dir.length_squared() < 0.0001:
		velocity.x = 0.0
		velocity.z = 0.0
		return

	var target_speed := RUN_SPEED if Input.is_key_pressed(KEY_SHIFT) else WALK_SPEED
	var target_h := move_dir * target_speed
	velocity.x = target_h.x
	velocity.z = target_h.z


func _get_camera_relative_input() -> Vector3:
	var input := Vector2.ZERO
	if Input.is_key_pressed(KEY_W):
		input.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		input.y += 1.0
	if Input.is_key_pressed(KEY_A):
		input.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		input.x += 1.0
	if input.length_squared() < 0.0001:
		return Vector3.ZERO

	var cam_basis := _camera.global_transform.basis
	var forward := -cam_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := cam_basis.x
	right.y = 0.0
	right = right.normalized()
	return (forward * -input.y + right * input.x).normalized()


func _update_facing(delta: float, move_dir: Vector3) -> void:
	var weapon_out := _weapon_rig != null and not _weapon_rig.is_holstered()
	var facing_dir := Vector3.ZERO

	if weapon_out:
		facing_dir = _get_aim_facing_direction()
	elif move_dir.length_squared() > 0.0001:
		facing_dir = move_dir

	if facing_dir.length_squared() < 0.0001:
		return

	# Camera pivot already carries yaw; model uses raw atan2 (not facing_yaw_for_direction).
	var target_yaw := atan2(facing_dir.x, facing_dir.z)
	var turn_speed := AIM_FACING_SPEED if weapon_out else FACING_SPEED
	_model.rotation.y = lerp_angle(_model.rotation.y, target_yaw, turn_speed * delta)


func _get_camera_horizontal_forward() -> Vector3:
	var forward := -_camera.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		return Vector3.ZERO
	return forward.normalized()


func _get_aim_facing_direction() -> Vector3:
	if _weapon_rig != null and _weapon_rig.can_use_reticle():
		var aim_dir := _get_aim_direction()
		aim_dir.y = 0.0
		if aim_dir.length_squared() > 0.0001:
			return aim_dir.normalized()

	return _get_camera_horizontal_forward()


func _get_aim_backwardness(move_dir: Vector3) -> float:
	if (
		_weapon_rig == null
		or _weapon_rig.get_draw_state() != GroyperWeaponRig.DrawState.AIMING
		or move_dir.length_squared() <= 0.0001
	):
		return 0.0

	var facing := _get_aim_facing_direction()
	if facing.length_squared() <= 0.0001:
		return 0.0

	return maxf(-move_dir.normalized().dot(facing.normalized()), 0.0)


func _get_aim_walk_speed_for_direction(move_dir: Vector3, base_walk_speed: float) -> float:
	var backwardness := _get_aim_backwardness(move_dir)
	if backwardness <= AIM_WALK_REVERSE_DOT_THRESHOLD:
		return base_walk_speed

	var back_t := clampf(
		(backwardness - AIM_WALK_REVERSE_DOT_THRESHOLD)
		/ maxf(1.0 - AIM_WALK_REVERSE_DOT_THRESHOLD, 0.001),
		0.0,
		1.0
	)
	return lerpf(base_walk_speed, AIM_WALK_BACK_SPEED, back_t)


func _get_locomotion_walk_blend_position(move_dir: Vector3) -> float:
	if (
		_weapon_rig == null
		or _weapon_rig.get_draw_state() != GroyperWeaponRig.DrawState.AIMING
		or move_dir.length_squared() <= 0.0001
	):
		return LOCOMOTION_WALK_BLEND

	var facing := _get_aim_facing_direction()
	if facing.length_squared() <= 0.0001:
		return LOCOMOTION_WALK_BLEND

	var backwardness := _get_aim_backwardness(move_dir)
	if backwardness <= AIM_WALK_REVERSE_DOT_THRESHOLD:
		return LOCOMOTION_WALK_BLEND

	var back_t := clampf(
		(backwardness - AIM_WALK_REVERSE_DOT_THRESHOLD)
		/ maxf(1.0 - AIM_WALK_REVERSE_DOT_THRESHOLD, 0.001),
		0.0,
		1.0
	)
	return lerpf(LOCOMOTION_WALK_BLEND, LOCOMOTION_WALK_REVERSE_BLEND, back_t)


func _compute_locomotion_blend_target(
	speed: float,
	walk_speed: float,
	run_speed: float,
	move_dir: Vector3 = Vector3.ZERO
) -> float:
	if speed <= 0.05:
		return 0.0

	var magnitude := 0.0
	if speed <= walk_speed:
		magnitude = lerpf(
			LOCOMOTION_IDLE_BLEND,
			LOCOMOTION_WALK_BLEND,
			speed / maxf(walk_speed, 0.001)
		)
	else:
		var run_t := (speed - walk_speed) / maxf(run_speed - walk_speed, 0.001)
		magnitude = lerpf(
			LOCOMOTION_WALK_BLEND,
			LOCOMOTION_RUN_BLEND,
			clampf(run_t, 0.0, 1.0)
		)

	if magnitude <= LOCOMOTION_WALK_BLEND:
		var walk_pos := _get_locomotion_walk_blend_position(move_dir)
		return walk_pos * (magnitude / LOCOMOTION_WALK_BLEND)
	return magnitude


func _update_locomotion_blend(
	delta: float,
	speed: float,
	walk_speed: float,
	run_speed: float,
	move_dir: Vector3 = Vector3.ZERO
) -> void:
	var target := _compute_locomotion_blend_target(speed, walk_speed, run_speed, move_dir)
	_locomotion_blend = lerpf(_locomotion_blend, target, BLEND_SPEED * delta)
	if _animation_tree != null:
		_animation_tree.set("parameters/LocomotionBlend/blend_position", _locomotion_blend)


func register_interactable(interactable: Node) -> void:
	if interactable == null:
		return
	_nearby_interactables[interactable.get_instance_id()] = interactable


func unregister_interactable(interactable: Node) -> void:
	if interactable == null:
		return
	_nearby_interactables.erase(interactable.get_instance_id())


func is_inventory_menu_blocked() -> bool:
	return _transition_locked or _dialog_active or DialogManager.is_showing()


func set_dialog_active(active: bool) -> void:
	_dialog_active = active
	if active:
		velocity = Vector3.ZERO
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		if _weapon_rig != null:
			_weapon_rig.reset_to_holster()
			_reset_reload_input()
			_reset_reticle_state()
			_update_combat_ui()
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func release_lasso_capture() -> void:
	if _lasso_controller != null:
		_lasso_controller.try_release_capture()


func set_transition_locked(active: bool) -> void:
	_transition_locked = active
	if active:
		velocity = Vector3.ZERO


func capture_overworld_snapshot() -> Dictionary:
	return {
		"transform": {
			"position": global_position,
			"body_rotation": global_rotation,
			"camera_yaw": _camera_yaw,
			"camera_pitch": _camera_pitch,
			"model_rotation_y": _model.rotation.y,
			"velocity": velocity,
		},
		"inventory": {
			"equipped_weapon": _equipped_weapon,
			"ammo": _ammo,
			"player_inventory": PlayerInventory.capture_snapshot(),
		},
	}


func apply_overworld_transform_snapshot(transform_state: Dictionary) -> void:
	if transform_state.is_empty():
		return

	global_position = transform_state.get("position", global_position)
	global_rotation = transform_state.get("body_rotation", global_rotation)
	_camera_yaw = transform_state.get("camera_yaw", _camera_yaw)
	_camera_pitch = transform_state.get("camera_pitch", _camera_pitch)
	_camera_pivot.rotation.y = _camera_yaw
	_camera_arm.rotation.x = _camera_pitch
	_model.rotation.y = transform_state.get("model_rotation_y", _model.rotation.y)
	velocity = transform_state.get("velocity", Vector3.ZERO)


func apply_overworld_snapshot(snapshot: Dictionary) -> void:
	apply_overworld_transform_snapshot(snapshot.get("transform", {}))

	var inventory: Dictionary = snapshot.get("inventory", {})
	if inventory.has("player_inventory"):
		PlayerInventory.apply_snapshot(inventory["player_inventory"])
	if inventory.has("equipped_weapon"):
		equip_weapon(inventory["equipped_weapon"], false)
	if inventory.has("ammo"):
		_ammo = inventory["ammo"]
	if _ammo_hud:
		_ammo_hud.configure_for_weapon(_equipped_weapon)
		_ammo_hud.sync_rounds(_ammo)
	refresh_stowed_weapon_visuals()


func equip_weapon(weapon_id: GroyperWeapons.Id, refill_ammo: bool = true) -> void:
	if not PlayerInventory.owns_weapon_type(weapon_id):
		return
	if weapon_id == _equipped_weapon and _weapon_rig != null \
			and _weapon_rig.get_equipped_weapon_id() == weapon_id:
		return

	if _lasso_controller != null:
		_lasso_controller.reset()

	if _weapon_rig != null:
		_weapon_rig.swap_equipped_weapon(weapon_id)

	_equipped_weapon = weapon_id
	if refill_ammo:
		_ammo = GroyperWeapons.get_max_ammo(_equipped_weapon)
	_shot_cooldown = 0.0
	_fire_held = false
	_reset_reload_input()
	_reset_reticle_state()
	if _ammo_hud:
		_ammo_hud.configure_for_weapon(_equipped_weapon)
		_ammo_hud.sync_rounds(_ammo)
	_update_combat_ui()
	refresh_stowed_weapon_visuals()


func _try_cycle_weapon(direction: int) -> void:
	if direction == 0:
		return

	var weapons := PlayerInventory.get_unique_owned_weapons()
	if weapons.size() <= 1:
		return

	var current_index := weapons.find(_equipped_weapon)
	if current_index < 0:
		current_index = 0

	var next_index := (current_index + direction) % weapons.size()
	if next_index < 0:
		next_index += weapons.size()

	equip_weapon(weapons[next_index])
	_show_weapon_select_hud()


func _show_weapon_select_hud() -> void:
	if _weapon_select_hud == null:
		return
	_weapon_select_hud.show_weapons(
		PlayerInventory.get_unique_owned_weapons(),
		_equipped_weapon
	)


func refresh_stowed_weapon_visuals() -> void:
	if _skeleton == null:
		return

	_clear_extra_holsters()

	if GroyperWeapons.uses_back_holster(_equipped_weapon):
		_clear_socket_grip(_hip_holster_socket())
	else:
		_clear_socket_grip(_back_holster_socket())

	var revolvers_on_body := 0
	if _equipped_weapon == GroyperWeapons.Id.REVOLVER:
		revolvers_on_body += 1
	elif PlayerInventory.owns_weapon_type(GroyperWeapons.Id.REVOLVER):
		revolvers_on_body += 1

	var extra_revolvers := PlayerInventory.count_weapon(GroyperWeapons.Id.REVOLVER) - revolvers_on_body
	if extra_revolvers >= 1:
		_ensure_left_hip_holster(GroyperWeapons.Id.REVOLVER)

	if PlayerInventory.owns_weapon_type(GroyperWeapons.Id.REVOLVER) \
			and GroyperWeapons.uses_back_holster(_equipped_weapon):
		_install_stowed_weapon(_hip_holster_socket(), GroyperWeapons.Id.REVOLVER)

	var stowed_back_weapon := _get_stowed_back_weapon()
	if stowed_back_weapon >= 0:
		_install_stowed_weapon(_back_holster_socket(), stowed_back_weapon)


func _get_stowed_back_weapon() -> int:
	for weapon_id in [GroyperWeapons.Id.AWP, GroyperWeapons.Id.SHOTGUN]:
		if PlayerInventory.owns_weapon_type(weapon_id) and _equipped_weapon != weapon_id:
			return weapon_id
	return -1


func _hip_holster_socket() -> Node3D:
	if _skeleton == null:
		return null
	var mount := _skeleton.get_node_or_null("HipHolsterMount") as Node3D
	if mount == null:
		return null
	return mount.get_node_or_null("HolsterOffset") as Node3D


func _back_holster_socket() -> Node3D:
	if _skeleton == null:
		return null
	var mount := _skeleton.get_node_or_null("BackHolsterMount") as Node3D
	if mount == null:
		return null
	return mount.get_node_or_null("HolsterOffset") as Node3D


func _clear_socket_grip(socket: Node3D) -> void:
	if socket == null:
		return
	if _weapon_rig != null and socket == _weapon_rig.get_active_holster_socket():
		return
	var grip := socket.get_node_or_null("RevolverGrip")
	if grip != null:
		grip.free()


func _install_stowed_weapon(socket: Node3D, weapon_id: GroyperWeapons.Id) -> void:
	if socket == null:
		return
	if _weapon_rig != null and socket == _weapon_rig.get_active_holster_socket():
		return
	GroyperWeapons.install_holster_grip(socket, weapon_id)


func _clear_extra_holsters() -> void:
	var left_mount := _skeleton.get_node_or_null("LeftHipHolsterMount")
	if left_mount != null:
		left_mount.free()


func _ensure_left_hip_holster(weapon_id: GroyperWeapons.Id) -> void:
	if _skeleton == null:
		return
	if _skeleton.get_node_or_null("LeftHipHolsterMount") != null:
		return

	var mount: BoneAttachment3D = LEFT_HIP_HOLSTER_MOUNT_SCENE.instantiate()
	_skeleton.add_child(mount)
	var holster_socket := mount.get_node_or_null("HolsterOffset") as Node3D
	if holster_socket != null:
		GroyperWeapons.install_holster_grip(holster_socket, weapon_id)
	mount.force_update_transform()


func teleport_to_position_only(world_pos: Vector3, snap_to_floor := true) -> void:
	if snap_to_floor:
		global_position = _snap_spawn_to_floor(world_pos)
	else:
		global_position = world_pos
	velocity = Vector3.ZERO


func teleport_to_marker(spawn: Marker3D, _forward_offset := 0.0) -> void:
	if spawn == null:
		return
	teleport_to_position_only(spawn.global_position)


func _snap_spawn_to_floor(pos: Vector3) -> Vector3:
	return GroyperBodyUtils.snap_position_to_floor(
		get_world_3d(),
		pos,
		GroyperBodyUtils.get_collision_feet_offset(self)
	)


func _try_interact() -> void:
	if _mounted_horse != null:
		if _mount_transition_active:
			return
		_mounted_horse.dismount_rider()
		return

	var target := _get_nearest_interactable()
	if target != null and target.has_method("interact"):
		target.interact(self)


func is_mounted_on_horse() -> bool:
	return _mounted_horse != null


func mount_on_horse(horse: StupidHorse) -> void:
	if horse == null or _mounted_horse != null or _mount_transition_active:
		return

	_mounted_horse = horse
	velocity = Vector3.ZERO
	_mount_transition_active = true

	if _collision_shape:
		_collision_shape.disabled = true

	var mount := horse.get_rider_mount_node()
	var start := global_position
	if _model != null:
		_mount_hop_model_yaw_from = _model.rotation.y
		var horse_forward := horse.get_facing_direction()
		_mount_hop_model_yaw_to = (
			atan2(horse_forward.x, horse_forward.z)
			if horse_forward.length_squared() > 0.0001
			else _mount_hop_model_yaw_from
		)

	_kill_mount_hop_tween()
	_mount_hop_tween = create_tween()
	_mount_hop_tween.tween_method(
		func(t: float) -> void:
			var end := mount.global_position if mount != null else start
			global_position = _hop_world_position(start, end, t, MOUNT_HOP_HEIGHT)
			_apply_mount_hop_model_pose(t, MOUNT_HOP_HEIGHT),
		0.0,
		1.0,
		MOUNT_HOP_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_mount_hop_tween.tween_callback(_finish_mount_on_horse)


func _finish_mount_on_horse() -> void:
	_mount_hop_tween = null
	if _mounted_horse == null:
		_mount_transition_active = false
		return

	var horse := _mounted_horse
	var mount := horse.get_rider_mount_node()

	if _weapon_rig != null:
		_weapon_rig.set_saddle_aim_mode(true)
		if not _weapon_rig.is_holstered():
			_weapon_rig.reset_to_holster()
		_reset_reticle_state()
		_update_combat_ui()

	if mount != null and _model != null:
		_model_mount_parent = _model.get_parent() as Node3D
		_model_mount_transform = _model.transform
		var preserved_global := _model.global_transform
		mount.add_child(_model)
		_model.global_transform = preserved_global
		_mounted_model_mount_offset = mount.global_transform.affine_inverse() * _model.global_transform
		_model.visible = true
		_rebind_animation_tree()

	follow_mounted_horse(mount)
	_sync_mount_camera_yaw(horse)
	if _weapon_rig != null:
		_update_saddle_gun_arm_filter(_weapon_rig.get_draw_state())
	register_interactable(horse)
	_tween_mount_settle(true, Callable(self, "_end_mount_transition"))


func follow_mounted_horse(mount: Node3D = null) -> void:
	if _mounted_horse == null or _mount_transition_active:
		return
	if mount == null:
		mount = _mounted_horse.get_rider_mount_node()
	if mount == null:
		return
	global_position = mount.global_position
	velocity = Vector3.ZERO
	_sync_mounted_model_to_mount(mount)


func _sync_mounted_model_to_mount(mount: Node3D = null) -> void:
	if _mounted_horse == null or _model == null:
		return
	if mount == null:
		mount = _mounted_horse.get_rider_mount_node()
	if mount == null:
		return
	if _model.get_parent() != mount:
		mount.add_child(_model)
	_model.global_transform = mount.global_transform * _mounted_model_mount_offset


func _follow_mounted_horse() -> void:
	follow_mounted_horse()


func dismount_from_horse(spawn_pos: Vector3, for_defeat: bool = false) -> void:
	if _mounted_horse == null and not _is_model_parented_to_horse():
		return
	if _mount_transition_active:
		return

	if for_defeat:
		_force_detach_model_to_player()
		GroyperBodyUtils.apply_model_baseline(_model)
		_rebind_animation_tree()
		_apply_dismount_cleanup(spawn_pos, true)
		return

	_force_detach_model_to_player()
	_rebind_animation_tree()

	var start := global_position
	var landing := spawn_pos
	landing.y = start.y
	if _model != null:
		_mount_hop_model_yaw_from = _model.rotation.y
		_mount_hop_model_yaw_to = GroyperBodyUtils.MODEL_YAW_OFFSET

	_mount_transition_active = true
	_kill_mount_hop_tween()
	_mount_hop_tween = create_tween()
	_mount_hop_tween.tween_method(
		func(t: float) -> void:
			global_position = _hop_world_position(start, landing, t, DISMOUNT_HOP_HEIGHT)
			_apply_mount_hop_model_pose(t, DISMOUNT_HOP_HEIGHT),
		0.0,
		1.0,
		DISMOUNT_HOP_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_mount_hop_tween.tween_callback(func() -> void:
		_tween_mount_settle(false, Callable(self, "_finish_dismount_after_settle").bind(landing))
	)


func _finish_dismount_after_settle(landing: Vector3) -> void:
	_apply_dismount_cleanup(landing, false)


func _apply_dismount_cleanup(spawn_pos: Vector3, for_defeat: bool) -> void:
	_kill_mount_hop_tween()
	_mount_transition_active = false

	if _mounted_horse != null:
		unregister_interactable(_mounted_horse)
	_mounted_horse = null
	global_position = spawn_pos
	velocity = Vector3.ZERO
	_mounted_model_mount_offset = Transform3D.IDENTITY

	_mount_spine_yaw = 0.0
	if _weapon_rig != null:
		_weapon_rig.set_saddle_aim_mode(false)
		_weapon_rig.set_mount_aim_spine_yaw(0.0)
		if _saddle_blend_node != null:
			SaddlePoseConfig.set_gun_arm_blend_filtered(_saddle_blend_node, true)
		if _cover_peek_blend_node != null:
			CoverPoseConfig.set_gun_aim_blend_filtered(_cover_peek_blend_node, true)
		if not for_defeat:
			if _weapon_rig.is_holstered():
				_weapon_rig.release_arms_for_locomotion()
			else:
				_weapon_rig.reset_to_holster()
			_reset_reticle_state()
			_update_combat_ui()

	if _collision_shape and not for_defeat:
		_collision_shape.disabled = false

	GroyperBodyUtils.apply_model_baseline(_model)
	_model.visible = true

	if for_defeat:
		_saddle_blend = 0.0
		if _animation_tree:
			_animation_tree.set("parameters/SaddleBlend/blend_amount", 0.0)


func _hop_world_position(start: Vector3, end: Vector3, t: float, height: float) -> Vector3:
	var flat := start.lerp(end, t)
	var arc := 4.0 * t * (1.0 - t) * height
	return flat + Vector3(0.0, arc, 0.0)


func _apply_mount_hop_model_pose(t: float, height: float) -> void:
	if _model == null or _model.get_parent() != self:
		return
	var arc := 4.0 * t * (1.0 - t) * height
	_model.position.y = GroyperBodyUtils.ACTOR_MODEL_Y + arc * 0.35
	_model.rotation.y = lerp_angle(_mount_hop_model_yaw_from, _mount_hop_model_yaw_to, t)


func _sync_mount_camera_yaw(horse: StupidHorse) -> void:
	var forward := horse.get_facing_direction()
	if forward.length_squared() < 0.0001:
		return
	_camera_yaw = atan2(forward.x, forward.z) + PI
	_camera_pivot.rotation.y = _camera_yaw


func _tween_mount_settle(on_mount: bool, on_complete: Callable) -> void:
	_kill_mount_hop_tween()
	var target_cam_y := MOUNT_CAMERA_PIVOT_Y if on_mount else _explore_camera_pivot_y
	var target_saddle := 1.0 if on_mount else 0.0
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(_camera_pivot, "position:y", target_cam_y, MOUNT_SETTLE_DURATION)
	tween.tween_method(
		func(value: float) -> void:
			_saddle_blend = value
			if _animation_tree:
				_animation_tree.set("parameters/SaddleBlend/blend_amount", value),
		_saddle_blend,
		target_saddle,
		MOUNT_SETTLE_DURATION
	)
	tween.chain().tween_callback(on_complete)


func _end_mount_transition() -> void:
	_mount_transition_active = false
	_mount_hop_tween = null


func _kill_mount_hop_tween() -> void:
	if _mount_hop_tween != null and _mount_hop_tween.is_valid():
		_mount_hop_tween.kill()
	_mount_hop_tween = null


func _rebind_animation_tree() -> void:
	if _animation_tree == null or _animation_player == null:
		return
	_animation_tree.anim_player = _animation_tree.get_path_to(_animation_player)


func get_ride_move_input() -> Vector3:
	return _get_camera_relative_input()


func is_ride_sprinting() -> bool:
	return Input.is_key_pressed(KEY_SHIFT)


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


func enter_overworld_combat() -> void:
	if _overworld_combat_active:
		return
	_overworld_combat_active = true
	_health = BulletHitDamage.PLAYER_MAX_HEALTH
	_health_regen_timer = 0.0
	_update_health_vignette()
	add_to_group("duel_target")
	_ensure_combat_hitbox()


func get_faction_id() -> StringName:
	return FactionIds.PLAYER


## Call after placing the actor at a spawn marker.
## Marker yaw spins the CharacterBody3D root; CameraPivot keeps its default PI explore offset.
func sync_overworld_spawn_orientation() -> void:
	_camera_yaw = PI
	_camera_pivot.rotation.y = _camera_yaw
	_camera_arm.rotation.x = _camera_pitch
	_model.rotation.y = GroyperBodyUtils.MODEL_YAW_OFFSET


func is_weapon_drawn() -> bool:
	return _weapon_rig != null and not _weapon_rig.is_holstered()


func is_weapon_aimed_at(target: Node3D, max_range: float = THREATEN_RANGE) -> bool:
	if GroyperWeapons.is_lasso(_equipped_weapon):
		return false
	if _weapon_rig == null or _weapon_rig.is_holstered():
		return false
	if target == null or not target.has_method("get_bullet_capsule"):
		return false

	var capsule: Dictionary = target.get_bullet_capsule()
	var origin := _get_aim_ray_origin()
	var direction := _get_aim_direction()
	var hit_t := DuelHitTest.raycast_capsule(
		origin,
		direction,
		max_range,
		capsule.get("center", Vector3.ZERO),
		capsule.get("half_height", 0.75),
		capsule.get("radius", 0.5) + 0.05,
		capsule.get("axis", Vector3.UP)
	)
	return hit_t >= 0.0


func get_duel_aim_point() -> Vector3:
	return get_duel_body_aim_point("chest")


func get_duel_body_aim_point(zone_id: String) -> Vector3:
	var zone: Dictionary = BODY_AIM_ZONES.get(zone_id, BODY_AIM_ZONES["chest"])
	var bone_name: String = zone.get("bone", "Spine02")
	var offset: Vector3 = zone.get("offset", Vector3.ZERO)

	if _skeleton == null:
		return global_position + Vector3(0.0, 1.25, 0.0) + offset

	var bone_id := _skeleton.find_bone(bone_name)
	if bone_id < 0:
		return global_position + Vector3(0.0, 1.25, 0.0) + offset

	var bone_global := _skeleton.global_transform * _skeleton.get_bone_global_pose(bone_id)
	return bone_global.origin + bone_global.basis * offset


func is_defeated() -> bool:
	return _overworld_defeated


func receive_bullet_hit(hit_info: Dictionary) -> void:
	if not _overworld_combat_active or _overworld_defeated:
		return

	var result := BulletHitDamage.process_hit(
		self,
		hit_info,
		_health,
		BulletHitDamage.PLAYER_MAX_HEALTH
	)
	_health = result.health
	_update_health_vignette()
	if result.killed:
		_activate_overworld_defeat_ragdoll(hit_info)


func get_bullet_capsule() -> Dictionary:
	_sync_combat_hitbox_position()
	var torso := _get_combat_hurtbox_transform()
	return {
		"center": torso.origin,
		"half_height": _get_projectile_hitbox_half_height(),
		"radius": _get_projectile_hitbox_radius(),
		"axis": torso.basis.y,
	}


func get_head_hit_sphere() -> Dictionary:
	return GroyperBodyUtils.get_head_hit_sphere(
		_skeleton,
		global_position + Vector3(0.0, 1.25, 0.0)
	)


func _get_projectile_hitbox_half_height() -> float:
	if _roll_active or _cover_crouch_active:
		return ROLL_HITBOX_HALF_HEIGHT
	return HITBOX_HALF_HEIGHT


func _get_projectile_hitbox_radius() -> float:
	if _roll_active or _cover_crouch_active:
		return ROLL_HITBOX_RADIUS
	return HITBOX_RADIUS


func _ensure_combat_hitbox() -> void:
	if _combat_hitbox != null:
		return

	_combat_hitbox = StaticBody3D.new()
	_combat_hitbox.name = "CombatHitbox"
	_combat_hitbox.collision_layer = 0
	_combat_hitbox.collision_mask = 0
	_combat_hitbox.script = DUEL_HITBOX_SCRIPT
	add_child(_combat_hitbox)
	_combat_hitbox.owner_path = NodePath("..")

	var shape := CapsuleShape3D.new()
	shape.radius = HITBOX_RADIUS
	shape.height = HITBOX_HALF_HEIGHT * 2.0

	var collision := CollisionShape3D.new()
	collision.shape = shape
	_combat_hitbox.add_child(collision)


func _ensure_combat_ragdoll() -> void:
	if _combat_ragdoll != null or _skeleton == null:
		return

	_combat_ragdoll = DUEL_RAGDOLL_SCRIPT.new()
	_combat_ragdoll.name = "CombatRagdoll"
	add_child(_combat_ragdoll)
	_combat_ragdoll.skeleton_path = _combat_ragdoll.get_path_to(_skeleton)
	_combat_ragdoll.bind_skeleton()


func _rebind_combat_ragdoll() -> void:
	if _combat_ragdoll == null or _skeleton == null:
		return
	_combat_ragdoll.skeleton_path = _combat_ragdoll.get_path_to(_skeleton)
	_combat_ragdoll.bind_skeleton()


func _activate_overworld_defeat_ragdoll(hit_info: Dictionary) -> void:
	var was_mounted := _mounted_horse != null or _is_model_parented_to_horse()
	if was_mounted:
		hit_info["mounted_dismount"] = true
		_dismount_for_defeat(hit_info)
	_ensure_combat_ragdoll()
	_rebind_combat_ragdoll()
	var hit_position: Vector3 = hit_info.get("position", global_position)
	GameAudio.play_death_sound(self, hit_position)
	_overworld_defeated = true
	if _combat_hitbox != null:
		_combat_hitbox.collision_layer = 0
	if _animation_tree != null:
		_animation_tree.active = false
	if _combat_ragdoll != null and not _combat_ragdoll.is_active():
		_combat_ragdoll.activate(hit_info, _animation_player)


func _dismount_for_defeat(hit_info: Dictionary) -> void:
	var horse := _mounted_horse
	var spawn_pos := _get_defeat_dismount_position(hit_info)
	hit_info["mounted_launch_velocity"] = _get_defeat_launch_velocity(hit_info)
	if horse != null and horse.has_method("release_rider"):
		horse.release_rider()
	dismount_from_horse(spawn_pos, true)


func _is_model_parented_to_horse() -> bool:
	if _model == null or _mounted_horse == null:
		return false
	var mount := _mounted_horse.get_rider_mount_node()
	return mount != null and _model.get_parent() == mount


func _force_detach_model_to_player() -> void:
	if _model == null or _model.get_parent() == self:
		return
	var world_transform := _model.global_transform
	add_child(_model)
	_model.global_transform = world_transform
	_model_mount_parent = null


func _get_defeat_launch_velocity(hit_info: Dictionary) -> Vector3:
	var shot_dir: Vector3 = hit_info.get("direction", Vector3.FORWARD)
	shot_dir.y = 0.0
	if shot_dir.length_squared() < 0.0001 and _mounted_horse != null:
		shot_dir = -_mounted_horse.get_facing_direction()
	shot_dir = shot_dir.normalized() if shot_dir.length_squared() > 0.0001 else Vector3.FORWARD
	return shot_dir * MOUNT_DEFEAT_LAUNCH_SPEED + Vector3.UP * MOUNT_DEFEAT_LAUNCH_UP


func _get_defeat_dismount_position(hit_info: Dictionary) -> Vector3:
	var mount: Node3D = null
	if _mounted_horse != null:
		mount = _mounted_horse.get_rider_mount_node()
	var base_pos := mount.global_position if mount != null else global_position
	var launch_vel := _get_defeat_launch_velocity(hit_info)
	var horizontal := Vector3(launch_vel.x, 0.0, launch_vel.z)
	if horizontal.length_squared() > 0.0001:
		return base_pos + horizontal.normalized() * 0.35 + Vector3(0.0, 0.2, 0.0)
	if _mounted_horse != null:
		var side := _mounted_horse.get_facing_direction().cross(Vector3.UP)
		if side.length_squared() < 0.0001:
			side = Vector3.RIGHT
		return base_pos + side.normalized() * 0.9 + Vector3(0.0, 0.15, 0.0)
	return base_pos + Vector3(0.0, 0.15, 0.0)


func _can_use_overworld_reload() -> bool:
	return (
		_mounted_horse == null
		and not _roll_active
		and not _cover_walk_enter_active
		and not _cover_exit_active
		and not _cover_crouch_active
		and not _overworld_defeated
	)


func _update_overworld_reload(delta: float) -> void:
	if _weapon_rig == null or not _can_use_overworld_reload():
		_reset_reload_input()
		return

	var phase := _weapon_rig.get_overworld_reload_phase()
	if phase == GroyperWeaponRig.OverworldReloadPhase.NONE:
		if _reload_last_phase == GroyperWeaponRig.OverworldReloadPhase.HOLSTERING:
			_reset_reload_input()
		_update_reload_hold(delta)
	else:
		_update_active_reload(phase)

	_reload_last_phase = phase


func _update_reload_hold(delta: float) -> void:
	if not _weapon_rig.can_begin_overworld_reload():
		if not Input.is_key_pressed(RELOAD_KEY):
			_reload_hold_time = 0.0
			_reload_eject_started = false
		return

	var max_ammo := GroyperWeapons.get_max_ammo(_equipped_weapon)
	if _ammo >= max_ammo:
		_reload_hold_time = 0.0
		return

	if not Input.is_key_pressed(RELOAD_KEY):
		_reload_hold_time = 0.0
		_reload_eject_started = false
		return

	_reload_hold_time += delta
	if _reload_hold_time < RELOAD_HOLD_DURATION or _reload_eject_started:
		return

	_reload_eject_started = true
	_ammo = 0
	if _ammo_hud:
		_ammo_hud.eject_all_casings()
	_weapon_rig.begin_overworld_reload_eject()


func _update_active_reload(phase: GroyperWeaponRig.OverworldReloadPhase) -> void:
	if phase == GroyperWeaponRig.OverworldReloadPhase.TAP_READY:
		if not Input.is_key_pressed(RELOAD_KEY):
			_reload_ready_for_tap = true

	if phase in [
		GroyperWeaponRig.OverworldReloadPhase.TAP_READY,
		GroyperWeaponRig.OverworldReloadPhase.LOADING,
	]:
		var want_aim_stance := Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and (
			_ammo > 0 or _weapon_rig.did_overworld_reload_start_from_aim()
		)
		_weapon_rig.set_overworld_reload_aim_stance(want_aim_stance)

	if _reload_pending_round and phase == GroyperWeaponRig.OverworldReloadPhase.TAP_READY:
		_finish_reload_round()


func _try_overworld_reload_tap() -> void:
	if _weapon_rig == null or not _reload_ready_for_tap:
		return
	if not _weapon_rig.try_overworld_reload_tap():
		return

	_reload_ready_for_tap = false
	_reload_pending_round = true


func _finish_reload_round() -> void:
	_reload_pending_round = false
	var max_ammo := GroyperWeapons.get_max_ammo(_equipped_weapon)

	if GroyperWeapons.uses_per_round_overworld_reload(_equipped_weapon):
		_ammo = mini(_ammo + 1, max_ammo)
		if _ammo_hud:
			_ammo_hud.animate_reload_round(_ammo)
	else:
		_ammo = max_ammo
		if _ammo_hud:
			_ammo_hud.animate_reload_magazine(_ammo)

	if _ammo >= max_ammo:
		var return_to_aim := Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
		_weapon_rig.finish_overworld_reload(return_to_aim)
		_reset_reload_input()
	else:
		_reload_ready_for_tap = false


func _on_reload_key_released() -> void:
	if _weapon_rig == null:
		return
	if _weapon_rig.get_overworld_reload_phase() == GroyperWeaponRig.OverworldReloadPhase.TAP_READY:
		_reload_ready_for_tap = true


func _try_interrupt_reload_with_aim() -> bool:
	if _weapon_rig == null or not _weapon_rig.is_overworld_reloading():
		return false
	if _ammo <= 0:
		return false

	_weapon_rig.cancel_overworld_reload_for_aim()
	_reset_reload_input()
	_update_combat_ui()
	return true


func _reset_reload_input() -> void:
	_reload_hold_time = 0.0
	_reload_eject_started = false
	_reload_ready_for_tap = false
	_reload_pending_round = false
	_reload_last_phase = GroyperWeaponRig.OverworldReloadPhase.NONE


func _sync_combat_hitbox_position() -> void:
	if _combat_hitbox == null:
		return
	_combat_hitbox.global_transform = _get_combat_hurtbox_transform()


func _get_combat_hurtbox_transform() -> Transform3D:
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
