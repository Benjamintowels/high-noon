extends GroyperActor

const WEAPON_RIG_SCRIPT := preload("res://characters/groyper/groyper_weapon_rig.gd")
const BaldwinBodyUtilsScript := preload("res://characters/baldwin/baldwin_body_utils.gd")
const BaldwinWeaponRigScript := preload("res://characters/baldwin/baldwin_weapon_rig.gd")
const GroyperWeapons := preload("res://characters/groyper/groyper_weapons.gd")
const LEFT_HIP_HOLSTER_MOUNT_SCENE := preload("res://characters/groyper/left_hip_holster_mount.tscn")
const DUEL_HITBOX_SCRIPT := preload("res://characters/groyper/groyper_hitbox.gd")
const DUEL_RAGDOLL_SCRIPT := preload("res://characters/groyper/groyper_ragdoll.gd")
const DUEL_HAT_SCRIPT := preload("res://characters/groyper/groyper_duel_hat.gd")
const DuelHitTest := preload("res://gameplay/duel/duel_hit_test.gd")
const BulletHitDamage := preload("res://gameplay/shooting/bullet_hit_damage.gd")
const SaddlePoseConfig := preload("res://characters/groyper/saddle_pose_config.gd")
const BonfirePoseConfig := preload("res://characters/groyper/bonfire_pose_config.gd")
const GroyperHitReactionConfig := preload("res://characters/groyper/groyper_hit_reaction_config.gd")
const CoverPoseExtractScript := preload("res://characters/groyper/cover_pose_extract.gd")
const VaultExtractScript := preload("res://characters/groyper/vault_extract.gd")
const VaultConfigScript := preload("res://characters/groyper/vault_config.gd")
const PunchPoseExtractScript := preload("res://characters/groyper/punch_pose_extract.gd")
const PunchPoseConfig := preload("res://characters/groyper/punch_pose_config.gd")
const MeleePunch := preload("res://gameplay/combat/melee_punch.gd")
const GameAudio := preload("res://gameplay/audio/game_audio.gd")
const LassoControllerScript := preload("res://gameplay/lasso/lasso_controller.gd")
const BowControllerScript := preload("res://gameplay/bow/bow_controller.gd")
const FactionIds := preload("res://gameplay/faction/faction_ids.gd")
const KNIFE_GRIP_SCENE := preload("res://characters/groyper/knife_grip.tscn")
const KNIFE_PROJECTILE_SCENE := preload("res://gameplay/combat/knife_projectile.tscn")
const GroyperMeleeAnimConfig := preload("res://characters/groyper/groyper_melee_anim_config.gd")
const BaldwinAnimUtilsScript := preload("res://characters/baldwin/baldwin_anim_utils.gd")
const BaldwinShieldConfigScript := preload("res://characters/baldwin/baldwin_shield_config.gd")
const CombatAnimTransitionsScript := preload("res://gameplay/combat/combat_anim_transitions.gd")
const CombatHitFlashScript := preload("res://gameplay/fx/combat_hit_flash.gd")
const MeleeClashScript := preload("res://gameplay/combat/melee_clash.gd")
const ShieldReflectScript := preload("res://gameplay/combat/shield_reflect.gd")
const MeleeSwordSlashScript := preload("res://gameplay/combat/melee_sword_slash.gd")
const CombatLockOnScript := preload("res://gameplay/combat/combat_lock_on.gd")
const LockOnIndicatorScript := preload("res://gameplay/combat/lock_on_indicator.gd")
const SwordCrescentFXScript := preload("res://gameplay/fx/sword_crescent_fx.gd")

const BODY_AIM_ZONES := {
	"head": {"bone": "Head", "offset": Vector3(0.0, 0.06, 0.05)},
	"chest": {"bone": "Spine02", "offset": Vector3(0.0, 0.1, 0.06)},
	"gut": {"bone": "Spine01", "offset": Vector3(0.0, 0.04, 0.05)},
	"left_shoulder": {"bone": "LeftShoulder", "offset": Vector3(-0.06, 0.02, 0.03)},
	"right_shoulder": {"bone": "RightShoulder", "offset": Vector3(0.06, 0.02, 0.03)},
}
const THREATEN_RANGE := 18.0
const LOCOMOTION_BLEND := &"LocomotionBlend"
const WALK_LOCOMOTION_BLEND := &"WalkLocomotionBlend"
const LOCOMOTION_IDLE_NODE := &"LocomotionIdle"
const LOCOMOTION_IDLE_BLEND := 0.0
const LOCOMOTION_WALK_REVERSE_BLEND := -0.5
const LOCOMOTION_WALK_BLEND := 0.5
const LOCOMOTION_RUN_BLEND := 1.0
const WALK_DIR_BACK_BLEND := 0.0
const WALK_DIR_WALK_BLEND := 0.5
const WALK_DIR_RUN_BLEND := 1.0
const BLOCK_LOCOMOTION_BLEND_SPEED := 12.0
const BLOCK_HOLD_BLEND_APPROACH := 4.605
const BLOCK_HOLD_BLEND_IN_TIME := 0.28
const BLOCK_HOLD_BLEND_OUT_TIME := 0.22
const BLOCK_HOLD_WALK_BLEND_IN_TIME := 0.22
const BLOCK_HOLD_WALK_BLEND_OUT_TIME := 0.22
const BLOCK_WALK_INPUT_HINT := 0.18
const COMBAT_IDLE_BLEND_IN_TIME := 0.38
const COMBAT_IDLE_BLEND_OUT_TIME := 0.18
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
const BONFIRE_BLEND_IN_SPEED := 8.0
const BONFIRE_POSE_BLEND_SPEED := 6.0
const BONFIRE_BLEND_OUT_SPEED := 7.0
const HIT_REACTION_BLEND_IN_SPEED := 6.0
const HIT_REACTION_BLEND_OUT_SPEED := 5.5
const HIT_REACTION_POSE_BLEND_SPEED := 5.0
const HIT_REACTION_GROUND_SINK_SPEED := 7.5
const AIM_WALK_REVERSE_DOT_THRESHOLD := 0.15
const MELEE_ATTACK_STRIKE_FRACTION := 0.35
const MELEE_SPIN_ATTACK_STRIKE_FRACTION := MeleeSwordSlashScript.SPIN_STRIKE_FRACTION
const MELEE_SPIN_ATTACK_VISUAL_FRACTION := MeleeSwordSlashScript.SPIN_VISUAL_FRACTION
const MELEE_SPIN_ATTACK_PLAYBACK_SPEED := 2.0
const MELEE_SPIN_RECOVERY_COMBO_FRACTION := 0.35
const MELEE_ATTACK_COOLDOWN := MeleeSwordSlashScript.COOLDOWN
const MELEE_SPIN_ATTACK_COOLDOWN := MeleeSwordSlashScript.SPIN_COOLDOWN
const MELEE_ATTACK_RANGE := MeleeSwordSlashScript.RANGE
const MELEE_SPIN_ATTACK_RANGE := MeleeSwordSlashScript.SPIN_RANGE
const MELEE_BLOCK_FACING_DOT_MIN := 0.32
const MELEE_COMBAT_IDLE_STOP_SPEED := 0.08
const MELEE_BLOCK_WALK_SPEED := 3.0
const MELEE_ATTACK_MOVE_SPEED := 2.65
const MELEE_SPIN_ATTACK_MOVE_SPEED := 4.8
const MELEE_ATTACK_MOVE_ACCEL := 14.0

const WALK_SPEED := 3.6
const RUN_SPEED := 7.2
const ROLL_SPEED_MULTIPLIER := 1.5
const RUN_ROLL_SPEED_MULTIPLIER := 1.05
const ROLL_INITIAL_IMPULSE_MULTIPLIER := 2.35
const RUN_ROLL_INITIAL_IMPULSE_MULTIPLIER := 1.35
const ROLL_IMPULSE_DECAY_TIME := 0.18
const ROLL_CONTROL_RETURN_FRACTION := 0.68
const ROLL_MIN_ACTIVE_TIME := 0.15
const ROLL_EXIT_BLEND_DURATION := 0.38
const ROLL_ANIM_FADEIN := 0.06
const ROLL_ANIM_FADEOUT := 0.52
const PUNCH_KEY := KEY_F
const KNIFE_THROW_SPEED := 20.0
const KNIFE_THROW_HIGH_AIM_BOOST := 1.32
const PUNCH_ANIM_NODE := &"PunchAnim"
const PUNCH_BLEND_IN_SPEED := 5.5
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
const BOW_AIM_CAMERA_OFFSET := Vector3(1.08, 0.06, 1.02)
const AIM_FOV_REDUCTION := 4.0
const BOW_AIM_FOV_REDUCTION := 9.0
## Close shoulder cam can raycast into the player capsule — ignore hits closer than this.
const BOW_MIN_AIM_DISTANCE := 8.0
const AIM_FOV_SMOOTH := 8.0
const RELOAD_FOV_REDUCTION := 2.5
const RELOAD_FOV_REDUCTION_AIMING := 0.9
const RELOAD_CAMERA_PULL_IN := Vector3(0.06, 0.015, -0.22)
const RELOAD_CAMERA_PULL_IN_AIMING := Vector3(0.025, 0.006, -0.1)
const RELOAD_CAMERA_SMOOTH := 2.8
const MELEE_CAMERA_OFFSET := Vector3(0.95, 0.04, 1.18)
const MELEE_FOV_REDUCTION := 9.0
const MELEE_CAMERA_WINDUP_BLEND := 0.34
const MELEE_CAMERA_HOLD_DURATION := 0.38
const MELEE_CAMERA_BLEND_IN := 8.5
const MELEE_CAMERA_BLEND_OUT := 2.6
const MELEE_CAMERA_RELEASE_DURATION := 0.72
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
const HORSE_DEATH_DISMOUNT_DURATION := 0.38
const HORSE_DEATH_DISMOUNT_ARC := 0.45
const HEALTH_REGEN_INTERVAL := 3.0

## Temporary caves physics debug — prints slide collisions while the player is moving.
const DEBUG_PHYSICS_COLLISIONS := false
const DEBUG_PHYSICS_COLLISION_MIN_SPEED := 0.35
const DEBUG_PHYSICS_COLLISION_COOLDOWN := 0.75
const DEBUG_PHYSICS_COLLISION_WALL_NORMAL_Y := 0.85

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
var _locomotion_move_blend := 0.0
var _locomotion_walk_blend := WALK_DIR_WALK_BLEND
var _weapon_rig: GroyperWeaponRig
var _melee_weapon_rig: BaldwinWeaponRig
var _nearby_interactables := {}
var _dialog_active := false
var _transition_locked := false
var _debug_physics_collision_times: Dictionary = {}

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
var _camera_shake_strength := 0.0
var _melee_camera_blend := 0.0
var _melee_camera_hold_timer := 0.0
var _melee_camera_releasing := false
var _melee_camera_release_timer := 0.0
var _melee_camera_release_from := 0.0
var _aim_fov_current := 80.0
var _aim_camera_blend := 0.0
var _reload_camera_blend := 0.0
var _roll_active := false
var _roll_timer := 0.0
var _roll_duration := 0.0
var _roll_move_duration := 0.0
var _roll_direction := Vector3.ZERO
var _roll_speed := 0.0
var _roll_speed_multiplier := ROLL_SPEED_MULTIPLIER
var _roll_is_run := false
var _roll_exit_active := false
var _roll_exit_timer := 0.0
var _roll_exit_start_velocity := Vector3.ZERO
var _roll_exit_start_yaw := 0.0
var _roll_exit_start_move_blend := 0.0
var _roll_exit_start_walk_blend := WALK_DIR_WALK_BLEND
var _roll_exit_blend_duration := ROLL_EXIT_BLEND_DURATION
var _roll_anim_node: AnimationNodeAnimation
var _punch_active := false
var _punch_timer := 0.0
var _punch_duration := 0.0
var _punch_direction := Vector3.ZERO
var _punch_strike_applied := false
var _punch_cooldown := 0.0
var _punch_exit_active := false
var _punch_exit_timer := 0.0
var _punch_blend := 0.0
var _punch_combo_step := MeleePunch.ComboStep.HOOK
var _punch_seek_base := 0.0
var _punch_combo_buffered := false
var _punch_blend_node: AnimationNodeBlend2
var _punch_anim_node: AnimationNodeAnimation
var _knife_hand_visual: Node3D
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

enum BonfireAnimPhase { NONE, SITTING_DOWN, SITTING, STANDING_UP }

var _bonfire_blend_node: AnimationNodeBlend2
var _bonfire_pose_blend_node: AnimationNodeBlend2
var _bonfire_stand_anim_node: AnimationNodeAnimation
var _bonfire_blend := 0.0
var _bonfire_pose_blend := 0.0
var _bonfire_timer := 0.0
var _bonfire_pose_timer := 0.0
var _bonfire_stand_duration := 0.0
var _bonfire_stand_up_pending := false
var _bonfire_anim_phase := BonfireAnimPhase.NONE
var _bonfire_interact_target: Node3D
var _bonfire_camera_blend := 0.0
var _bonfire_camera_target_blend := 0.0
var _bonfire_movement_unlocked := false
var _mount_spine_yaw := 0.0

var _mounted_horse: StupidHorse
var _model_mount_parent: Node3D
var _model_mount_transform: Transform3D
var _mounted_model_mount_offset := Transform3D.IDENTITY
var _mount_hop_tween: Tween
var _mount_transition_active := false
var _mount_hop_model_yaw_from := 0.0
var _mount_hop_model_yaw_to := 0.0
var _horse_death_dismount_callback: Callable
var _explore_camera_pivot_y := 1.1
var _collision_shape: CollisionShape3D

var _locomotion_audio: Node
var _reload_ready_for_tap := false
var _reload_pending_round := false
var _reload_last_phase: GroyperWeaponRig.OverworldReloadPhase = GroyperWeaponRig.OverworldReloadPhase.NONE
var _lasso_controller: LassoController
var _lasso_rmb_was_held := false
var _bow_controller: Node
var _bow_lmb_was_held := false
var _push_intent := Vector3.ZERO

var _idle_anim_node: AnimationNodeAnimation
var _walk_anim_node: AnimationNodeAnimation
var _walk_reverse_anim_node: AnimationNodeAnimation
var _peaceful_idle_path := StringName()
var _combat_idle_path := StringName()
var _block_walk_backward_path := StringName()
var _block_walk_forward_path := StringName()
var _combat_idle_blend := 0.0
var _melee_combat_idle_nodes_ready := false
var _melee_combat_nodes_ready := false
var _melee_block_walk_nodes_ready := false

var _attack_anim_name := StringName()
var _attack_reverse_anim_name := StringName()
var _spin_attack_anim_name := StringName()
var _spin_attack_reverse_anim_name := StringName()
var _melee_attack_anim_node: AnimationNodeAnimation
var _shield_block_clash_path := StringName()
var _shield_block_break_path := StringName()
var _combat_blocking := false
var _reflect_active := false
var _reflect_elapsed := 0.0
var _reflect_window_remaining := 0.0
var _reflect_cooldown := 0.0
var _combat_attacking := false
var _attack_elapsed := 0.0
var _attack_anim_time := 0.0
var _attack_timer := 0.0
var _attack_struck := false
var _attack_reverse := false
var _attack_spin := false
var _attack_spin_visual_applied := false
var _attack_spin_chained := false
var _attack_combo_used := false
var _attack_recovery_to_idle := false
var _attack_reverse_seek := 0.0
var _attack_direction := Vector3.FORWARD
var _attack_cooldown := 0.0
var _attack_seek_tween: Tween
var _melee_block_hold_blend := 0.0
var _block_walk_amount := 0.0
var _melee_hit_absorbed := false
var _melee_block_facing_lock_timer := 0.0
var _melee_facing_yaw_locked := INF
var _lock_on_active := false
var _lock_on_target: Node3D
var _lock_on_orbit_yaw := 0.0
var _lock_on_blend := 0.0
var _lock_on_indicator: Node3D

var _hit_reaction_nodes_ready := false
var _hit_reaction_active := false
var _hit_reaction_phase := GroyperHitReactionConfig.Phase.NONE
var _hit_reaction_blend := 0.0
var _hit_reaction_pose_blend := 0.0
var _hit_reaction_fall_timer := 0.0
var _hit_reaction_stand_timer := 0.0
var _hit_reaction_fall_duration := 0.0
var _hit_reaction_stand_duration := 0.0
var _hit_reaction_impulse_timer := 0.0
var _hit_reaction_control_unlocked := false
var _hit_reaction_model_sink := 0.0
var _hit_reaction_applied_body_sink := 0.0
var _hit_reaction_pose_tween: Tween
var _hit_reaction_blend_node: AnimationNodeBlend2
var _hit_reaction_pose_blend_node: AnimationNodeBlend2
var _hit_reaction_fall_anim_node: AnimationNodeAnimation
var _hit_reaction_stand_anim_node: AnimationNodeAnimation


func _on_actor_ready() -> void:
	add_to_group("overworld_player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")
	_setup_weapon_rig()
	_setup_lasso_controller()
	_setup_bow_controller()
	_setup_hat()
	_setup_locomotion_audio()
	_setup_locomotion_library()
	_setup_roll_dodge_library()
	_setup_punch_pose_library()
	_setup_vault_library()
	_setup_cover_pose_library()
	_setup_bonfire_pose_library()
	_setup_hit_reaction_library()
	_setup_melee_library()
	_setup_animation_tree()
	call_deferred("_rebind_animation_tree")
	_setup_knife_hand_visual()
	_setup_combat_ui()
	_setup_lock_on_indicator()
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
	PlayerInventory.inventory_changed.connect(refresh_knife_visual)
	PlayerInventory.inventory_changed.connect(refresh_melee_equipment)
	refresh_stowed_weapon_visuals()
	refresh_knife_visual()
	refresh_melee_equipment()


func _setup_lock_on_indicator() -> void:
	_lock_on_indicator = LockOnIndicatorScript.new()
	_lock_on_indicator.name = "LockOnIndicator"
	add_child(_lock_on_indicator)


func _setup_knife_hand_visual() -> void:
	if _skeleton == null:
		return
	var hand_mount := _skeleton.get_node_or_null("HandRevolverMount") as Node3D
	if hand_mount == null:
		return
	_knife_hand_visual = KNIFE_GRIP_SCENE.instantiate()
	_knife_hand_visual.name = "KnifeGrip"
	hand_mount.add_child(_knife_hand_visual)
	_knife_hand_visual.transform = Transform3D(
		Basis.from_euler(Vector3(deg_to_rad(-95.0), deg_to_rad(12.0), deg_to_rad(88.0))),
		Vector3(-0.04, 0.02, 0.1)
	)
	_knife_hand_visual.visible = false


func uses_knife_melee() -> bool:
	return PlayerInventory.has_knife


func refresh_knife_visual() -> void:
	_sync_knife_hand_visual()


func refresh_melee_equipment() -> void:
	if _skeleton == null:
		return
	PlayerInventory.reconcile_owned_sword_shield()
	if not PlayerInventory.has_sword_shield:
		if GroyperWeapons.is_sword_shield(_equipped_weapon):
			equip_weapon(GroyperWeapons.get_starting_weapon(), false)
		BaldwinBodyUtilsScript.sync_melee_equipment_owned(_skeleton, false)
		_teardown_melee_weapon_rig()
		return

	GroyperBodyUtils.ensure_melee_mounts(_skeleton)
	BaldwinBodyUtilsScript.sync_melee_equipment_owned(_skeleton, true)
	if _melee_weapon_rig != null:
		_melee_weapon_rig.reset_to_holster()


func _ensure_melee_weapon_rig() -> void:
	if _melee_weapon_rig != null or _skeleton == null:
		return
	GroyperBodyUtils.ensure_melee_mounts(_skeleton)
	BaldwinBodyUtilsScript.sync_melee_equipment_owned(_skeleton, true)
	_melee_weapon_rig = BaldwinWeaponRigScript.new()
	_melee_weapon_rig.name = "MeleeWeaponRig"
	add_child(_melee_weapon_rig)
	_melee_weapon_rig.setup(self, _skeleton)
	_melee_weapon_rig.set_release_arms_when_idle(false)


func _equip_melee_weapon() -> void:
	_ensure_melee_weapon_rig()
	if _melee_weapon_rig == null:
		return
	if _melee_weapon_rig.is_holstered() and not _melee_weapon_rig.is_transitioning():
		_melee_weapon_rig.begin_draw()


func _holster_melee_weapon() -> void:
	if _melee_weapon_rig == null:
		return
	_melee_weapon_rig.reset_to_holster()


func _teardown_melee_weapon_rig() -> void:
	if _melee_weapon_rig == null:
		return
	_melee_weapon_rig.queue_free()
	_melee_weapon_rig = null


func _sync_knife_hand_visual() -> void:
	if _knife_hand_visual == null:
		return
	_knife_hand_visual.visible = (
		PlayerInventory.has_knife
		and _punch_active
		and not _punch_exit_active
	)


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


func _setup_bow_controller() -> void:
	_bow_controller = BowControllerScript.new()
	_bow_controller.name = "BowController"
	add_child(_bow_controller)
	_bow_controller.setup(
		self,
		_weapon_rig,
		_get_bow_fire_origin,
		_get_bow_fire_direction,
		_on_bow_arrow_fired
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
	_update_bow(delta)

	if _transition_locked or _dialog_active or DialogManager.is_showing():
		return

	_shot_cooldown = maxf(_shot_cooldown - delta, 0.0)
	_scope_recoil_yaw = lerpf(_scope_recoil_yaw, 0.0, 1.0 - exp(-RECOIL_RECOVERY * delta))
	_scope_recoil_pitch = lerpf(_scope_recoil_pitch, 0.0, 1.0 - exp(-RECOIL_RECOVERY * delta))

	if GroyperWeapons.is_sword_shield(_equipped_weapon):
		_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
		if _melee_weapon_rig != null:
			_melee_weapon_rig.update(delta)
			_melee_weapon_rig.apply_pose_overrides(delta)
		_update_melee_block_hold_blend_state(delta)
		_update_melee_input_hold()
		_update_combat_idle_blend(delta)
		_update_combat_ui()
		_update_overworld_health(delta)
		_punch_cooldown = maxf(_punch_cooldown - delta, 0.0)
		_reflect_cooldown = maxf(_reflect_cooldown - delta, 0.0)
		return

	if _melee_weapon_rig != null and _melee_weapon_rig.is_transitioning():
		_melee_weapon_rig.update(delta)
		_melee_weapon_rig.apply_pose_overrides(delta)

	if _weapon_rig == null:
		return

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
	_update_melee_camera(delta)
	_update_aim_camera(delta)
	_update_overworld_reload(delta)

	if _fire_held and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_fire_held = false
	if _fire_held and GroyperWeapons.is_full_auto(_equipped_weapon) \
			and not GroyperWeapons.is_bow(_equipped_weapon):
		_try_shoot()

	_punch_cooldown = maxf(_punch_cooldown - delta, 0.0)


func _input(event: InputEvent) -> void:
	if _transition_locked and not _bonfire_movement_unlocked and not BonfireMenuManager.is_showing():
		get_viewport().set_input_as_handled()
		return

	if InventoryMenuManager.is_open():
		return

	if TownMapManager.is_open():
		return

	if _dialog_active or DialogManager.is_showing() or ShopBuyManager.is_showing() \
			or BonfireMenuManager.is_showing():
		if (
			event is InputEventKey
			and event.pressed
			and event.keycode == KEY_E
		):
			_try_interact()
		return

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if _is_lock_on_engaged():
			_apply_lock_on_mouse_look(event.relative)
			get_viewport().set_input_as_handled()
			return
		var use_reticle := (
			_weapon_rig != null
			and _weapon_rig.can_use_reticle()
			and not _is_bow_free_aim()
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
			if _can_use_sword_shield_melee():
				if event.pressed:
					_try_begin_melee_attack()
			elif GroyperWeapons.is_bow(_equipped_weapon):
				if event.pressed and _ammo > 0:
					_bow_lmb_was_held = true
				elif not event.pressed:
					_bow_lmb_was_held = false
			elif event.pressed:
				_try_shoot()
				_fire_held = event.pressed
			else:
				_fire_held = event.pressed
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_MIDDLE
		and event.pressed
	):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			_try_toggle_lock_on()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		elif GroyperWeapons.is_sword_shield(_equipped_weapon):
			if event.pressed:
				_try_begin_melee_blocking()
			else:
				_try_end_melee_blocking()
		elif _try_interrupt_reload_with_aim():
			pass
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == RELOAD_KEY:
		if not _try_overworld_reload_tap():
			_try_begin_overworld_reload_eject()
	elif event is InputEventKey and not event.pressed and event.keycode == RELOAD_KEY:
		_on_reload_key_released()
	elif (
		event is InputEventKey
		and event.pressed
		and event.keycode == KEY_E
	):
		_try_interact()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_T:
		_try_teleport_companion()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		if _mounted_horse == null:
			_try_cover_or_roll_action()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == PUNCH_KEY:
		_try_punch()


func move_with_ground_snap(snap_floor: bool = true) -> bool:
	var moved := super.move_with_ground_snap(snap_floor)
	_debug_log_slide_collisions()
	return moved


func _move_and_slide_debug() -> void:
	move_and_slide()
	_debug_log_slide_collisions()


func _debug_log_slide_collisions() -> void:
	if not DEBUG_PHYSICS_COLLISIONS:
		return

	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	if horizontal.length_squared() < DEBUG_PHYSICS_COLLISION_MIN_SPEED * DEBUG_PHYSICS_COLLISION_MIN_SPEED:
		return

	var now := Time.get_ticks_msec() / 1000.0
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider == null or not (collider is Node):
			continue

		var normal := collision.get_normal()
		if absf(normal.y) > DEBUG_PHYSICS_COLLISION_WALL_NORMAL_Y:
			continue

		var collider_node := collider as Node
		var collider_id := collider_node.get_instance_id()
		var last_time: float = _debug_physics_collision_times.get(collider_id, -999.0)
		if now - last_time < DEBUG_PHYSICS_COLLISION_COOLDOWN:
			continue
		_debug_physics_collision_times[collider_id] = now

		var target_label := _debug_format_collision_target(collider_node, collision)
		print(
			"[PLAYER COLLISION] ",
			target_label,
			" | normal=",
			normal,
			" | hit_pos=",
			collision.get_position(),
			" | player_pos=",
			global_position,
			" | player_vel=",
			velocity
		)


func _debug_format_collision_target(collider: Node, collision: KinematicCollision3D) -> String:
	var parts: PackedStringArray = []
	parts.append("path=" + str(collider.get_path()))
	parts.append("class=" + collider.get_class())
	if collider is Node3D:
		parts.append("collider_global=" + str((collider as Node3D).global_position))
	parts.append("shape_idx=" + str(collision.get_collider_shape()))

	if collider is CollisionObject3D:
		for child in (collider as CollisionObject3D).get_children():
			if child is CollisionShape3D:
				var shape_node := child as CollisionShape3D
				var shape := shape_node.shape
				var shape_type := shape.get_class() if shape != null else "none"
				var shape_size := ""
				if shape is BoxShape3D:
					shape_size = " size=" + str((shape as BoxShape3D).size)
				elif shape is SphereShape3D:
					shape_size = " radius=" + str((shape as SphereShape3D).radius)
				elif shape is CapsuleShape3D:
					var capsule := shape as CapsuleShape3D
					shape_size = " radius=" + str(capsule.radius) + " height=" + str(capsule.height)
				elif shape is CylinderShape3D:
					var cylinder := shape as CylinderShape3D
					shape_size = " radius=" + str(cylinder.radius) + " height=" + str(cylinder.height)
				parts.append(
					"shape="
					+ str(shape_node.name)
					+ "("
					+ shape_type
					+ shape_size
					+ ") global="
					+ str(shape_node.global_position)
					+ " disabled="
					+ str(shape_node.disabled)
				)

	return ", ".join(parts)


func _physics_process(delta: float) -> void:
	if _overworld_defeated:
		velocity = Vector3.ZERO
		_move_and_slide_debug()
		return

	var freeze_player := (
		(_transition_locked and not _bonfire_movement_unlocked)
		or _dialog_active
		or DialogManager.is_showing()
		or InventoryMenuManager.is_open()
		or TownMapManager.is_open()
		or ShopBuyManager.is_showing()
		or BonfireMenuManager.is_showing()
	)
	if freeze_player:
		velocity = Vector3.ZERO
		_move_and_slide_debug()
		if _is_bonfire_pose_active():
			_update_bonfire_pose(delta)
		else:
			_update_locomotion_blend(delta, 0.0, WALK_SPEED, RUN_SPEED)
		_camera_pivot.rotation.y = _camera_yaw
		_camera_arm.rotation.x = _camera_pitch
		_update_interact_hint()
		return

	_update_lock_on(delta)

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

	if _hit_reaction_active:
		_update_hit_reaction(delta)
		if not _hit_reaction_control_unlocked:
			_camera_pivot.rotation.y = _camera_yaw
			_camera_arm.rotation.x = _camera_pitch
			_update_interact_hint()
			return

	if _mount_transition_active:
		velocity = Vector3.ZERO
		_move_and_slide_debug()
		_camera_pivot.rotation.y = _camera_yaw
		_camera_arm.rotation.x = _camera_pitch
		_update_interact_hint()
		return

	if GroyperWeapons.is_sword_shield(_equipped_weapon) and _melee_weapon_rig != null and _melee_weapon_rig.is_equipped():
		if _reflect_active:
			_process_shield_reflect(delta)
			return
		if _combat_attacking:
			_process_melee_attack(delta)
			return
		if _combat_blocking:
			_process_melee_blocking(delta)
			return

	if _is_fully_mounted():
		if _mounted_horse.has_method("is_horse_defeated") and _mounted_horse.is_horse_defeated():
			if not _mount_transition_active:
				_fall_off_dead_horse({})
			velocity = Vector3.ZERO
			_move_and_slide_debug()
			_camera_pivot.rotation.y = _camera_yaw
			_camera_arm.rotation.x = _camera_pitch
			_update_interact_hint()
			return
		velocity = Vector3.ZERO
		_locomotion_move_blend = lerpf(_locomotion_move_blend, 0.0, BLEND_SPEED * delta)
		_apply_locomotion_tree_blends()
		_update_saddle_pose_blend(delta)
		if _weapon_rig != null:
			_update_saddle_gun_arm_filter(_weapon_rig.get_draw_state())
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

	tick_melee_stun(delta)
	if _melee_block_facing_lock_timer > 0.0:
		_melee_block_facing_lock_timer = maxf(_melee_block_facing_lock_timer - delta, 0.0)
	if is_melee_stunned():
		move_with_ground_snap()
		var stunned_h := Vector3(velocity.x, 0.0, velocity.z)
		if _melee_block_facing_lock_timer > 0.0:
			_model.rotation.y = _melee_facing_yaw_locked
		elif stunned_h.length_squared() > 0.04:
			_update_facing(delta, stunned_h)
		_update_locomotion_blend(delta, stunned_h.length(), WALK_SPEED, RUN_SPEED)
		_camera_pivot.rotation.y = _camera_yaw
		_camera_arm.rotation.x = _camera_pitch
		_update_interact_hint()
		return

	if _punch_active:
		_update_punch_overlay(delta)

	if _is_bonfire_pose_active():
		_update_bonfire_pose(delta)

	var move_dir := _get_camera_relative_input()
	var in_gun_aim_stance := _is_in_gun_aim_stance()
	var wants_sprint := Input.is_key_pressed(KEY_SHIFT) and not in_gun_aim_stance
	var sprinting := wants_sprint and move_dir.length_squared() > 0.0001
	var walk_speed := AIM_WALK_SPEED if in_gun_aim_stance else WALK_SPEED
	var run_speed := AIM_RUN_SPEED if in_gun_aim_stance else RUN_SPEED
	if in_gun_aim_stance and move_dir.length_squared() > 0.0001:
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
	_push_intent = target_h
	velocity.x = new_h.x
	velocity.z = new_h.z
	_apply_punch_strike_if_ready()
	move_with_ground_snap()

	_update_facing(delta, move_dir)
	_update_locomotion_blend(delta, new_h.length(), walk_speed, run_speed, move_dir)
	_update_combat_idle_blend(delta)
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
	if _weapon_rig != null and _weapon_rig.is_overworld_reloading():
		saddle_owns_gun_arm = false
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
	if GroyperWeapons.is_bow(_equipped_weapon):
		weapon_fov_reduction = BOW_AIM_FOV_REDUCTION
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
	target_fov -= MELEE_FOV_REDUCTION * _melee_camera_blend
	var scoped_fov := GroyperWeapons.get_scope_fov(_equipped_weapon)
	target_fov = lerpf(target_fov, scoped_fov, _scope_blend)
	var fov_smooth := RELOAD_CAMERA_SMOOTH if reload_target > 0.01 else AIM_FOV_SMOOTH
	var fov_step := 1.0 - exp(-fov_smooth * delta)
	_aim_fov_current = lerpf(_aim_fov_current, target_fov, fov_step)

	var aim_offset := AIM_CAMERA_OFFSET
	if _is_mounted():
		aim_offset = MOUNT_AIM_CAMERA_OFFSET
	elif GroyperWeapons.is_bow(_equipped_weapon):
		aim_offset = BOW_AIM_CAMERA_OFFSET
	var shoulder_blend := maxf(aim_blend, _melee_camera_blend)
	var shoulder_offset := aim_offset.lerp(MELEE_CAMERA_OFFSET, _melee_camera_blend)
	var base_pos := _explore_camera_offset.lerp(shoulder_offset, shoulder_blend)
	var reload_pull := RELOAD_CAMERA_PULL_IN.lerp(RELOAD_CAMERA_PULL_IN_AIMING, aim_blend)
	_camera.position = base_pos + reload_pull * _reload_camera_blend + _sample_camera_shake(delta)
	_camera.fov = _aim_fov_current
	_apply_bonfire_cinematic_camera(delta)

	var scope_yaw := 0.0
	var scope_pitch := 0.0
	if _is_scope_aim_active():
		scope_yaw = _scope_yaw + _scope_recoil_yaw
		scope_pitch = _scope_pitch + _scope_recoil_pitch
	_camera_pivot.rotation.y = _camera_yaw + scope_yaw
	_camera_arm.rotation.x = _camera_pitch + scope_pitch


func _update_melee_camera(delta: float) -> void:
	var target := 0.0
	if _melee_camera_hold_timer > 0.0:
		_melee_camera_hold_timer = maxf(_melee_camera_hold_timer - delta, 0.0)
		target = 1.0
	elif _melee_camera_releasing:
		_melee_camera_release_timer += delta
		var progress := clampf(
			_melee_camera_release_timer / maxf(MELEE_CAMERA_RELEASE_DURATION, 0.001),
			0.0,
			1.0
		)
		var eased := 1.0 - pow(1.0 - progress, 2.4)
		target = lerpf(_melee_camera_release_from, 0.0, eased)
		if progress >= 1.0:
			_melee_camera_releasing = false
			target = 0.0
	elif _punch_active and not _punch_exit_active:
		target = MELEE_CAMERA_WINDUP_BLEND

	var blend_speed := MELEE_CAMERA_BLEND_IN if target > _melee_camera_blend else MELEE_CAMERA_BLEND_OUT
	var step := 1.0 - exp(-blend_speed * delta)
	_melee_camera_blend = lerpf(_melee_camera_blend, target, step)


func _begin_melee_camera_release() -> void:
	if _melee_camera_blend <= 0.001 and _melee_camera_hold_timer <= 0.0:
		return
	_melee_camera_release_from = _melee_camera_blend
	_melee_camera_releasing = true
	_melee_camera_release_timer = 0.0
	_melee_camera_hold_timer = 0.0


func _trigger_melee_impact_camera() -> void:
	_melee_camera_releasing = false
	_melee_camera_release_timer = 0.0
	_melee_camera_hold_timer = MELEE_CAMERA_HOLD_DURATION
	apply_camera_shake(0.38)


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
	if GroyperWeapons.is_sword_shield(_equipped_weapon):
		var melee_out := (
			_melee_weapon_rig != null
			and (
				not _melee_weapon_rig.is_holstered()
				or _melee_weapon_rig.is_transitioning()
			)
		)
		if _ammo_hud:
			_ammo_hud.visible = melee_out
		if _reticle_ui:
			_reticle_ui.visible = false
		return

	if _weapon_rig == null:
		return

	var weapon_out := not _weapon_rig.is_holstered()
	var reloading := _weapon_rig.is_overworld_reloading()
	if _ammo_hud:
		_ammo_hud.visible = weapon_out or reloading
	if _reticle_ui:
		_reticle_ui.visible = _weapon_rig.can_use_reticle() and not _is_bow_free_aim()


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
	if is_melee_stunned():
		return
	if GroyperWeapons.is_sword_shield(_equipped_weapon):
		return
	if _weapon_rig == null or not _weapon_rig.can_fire():
		return
	if _weapon_rig.is_overworld_reloading():
		return
	if GroyperWeapons.is_lasso(_equipped_weapon):
		if _lasso_controller != null:
			_lasso_controller.try_throw()
		return
	if GroyperWeapons.is_bow(_equipped_weapon):
		return
	if GroyperWeapons.is_shovel(_equipped_weapon):
		return
	if _shot_cooldown > 0.0 or _ammo <= 0:
		return

	enter_overworld_combat()
	_shot_cooldown = GroyperWeapons.get_shot_cooldown(_equipped_weapon)
	_weapon_rig.fire_at(_get_aim_world_target())
	_apply_shot_recoil()
	_notify_nearby_enemies_of_gunshot(_get_aim_world_target())
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
	if _is_bow_free_aim():
		return get_viewport().get_visible_rect().size * 0.5
	if _is_mounted() or _is_scope_aim_active():
		return get_viewport().get_visible_rect().size * 0.5
	return get_viewport().get_visible_rect().size * 0.5 + _reticle_offset


func _is_bow_free_aim() -> bool:
	if not GroyperWeapons.is_bow(_equipped_weapon) or _weapon_rig == null:
		return false
	return _weapon_rig.is_drawing()


func _get_aim_ray_origin() -> Vector3:
	return _camera.project_ray_origin(_get_reticle_screen_position())


func _get_aim_direction() -> Vector3:
	return _camera.project_ray_normal(_get_reticle_screen_position()).normalized()


func _get_aim_ray_exclude() -> Array[RID]:
	var exclude: Array[RID] = [get_rid()]
	if _combat_hitbox != null and is_instance_valid(_combat_hitbox):
		exclude.append(_combat_hitbox.get_rid())
	return exclude


func _raycast_aim_depth(origin: Vector3, direction: Vector3, min_depth: float = 0.0) -> float:
	var space_state := get_world_3d().direct_space_state
	if space_state == null:
		return SHOT_RANGE

	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * SHOT_RANGE)
	query.collide_with_areas = false
	query.exclude = _get_aim_ray_exclude()
	var hit := space_state.intersect_ray(query)
	if hit.is_empty():
		return SHOT_RANGE

	return maxf((hit.position - origin).dot(direction), min_depth)


func _get_aim_point_along_ray(origin: Vector3, direction: Vector3, min_depth: float = 0.0) -> Vector3:
	var depth := _raycast_aim_depth(origin, direction, min_depth)
	return origin + direction * depth


func _get_aim_world_target() -> Vector3:
	var origin := _get_aim_ray_origin()
	var direction := _get_aim_direction()
	return _get_aim_point_along_ray(origin, direction)


func _get_bow_aim_world_target() -> Vector3:
	var origin := _get_aim_ray_origin()
	var direction := _get_aim_direction()
	return _get_aim_point_along_ray(origin, direction, BOW_MIN_AIM_DISTANCE)


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


func _can_use_bow() -> bool:
	return (
		GroyperWeapons.is_bow(_equipped_weapon)
		and _weapon_rig != null
		and _weapon_rig.can_fire()
		and _ammo > 0
		and not _overworld_defeated
		and not _transition_locked
	)


func _update_bow(delta: float) -> void:
	if _bow_controller == null:
		return

	var lmb_held := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

	if not GroyperWeapons.is_bow(_equipped_weapon):
		if _bow_controller.is_charging():
			_bow_controller.reset()
		_bow_lmb_was_held = lmb_held
		return

	_bow_controller.update(delta, lmb_held, _can_use_bow())
	_bow_lmb_was_held = lmb_held


func _get_bow_fire_origin() -> Vector3:
	if _weapon_rig != null:
		return _weapon_rig.get_bow_string_release_position()
	return global_position + Vector3(0.0, 1.2, 0.0)


func _get_bow_fire_direction() -> Vector3:
	var bow_origin := _get_bow_fire_origin()
	var aim_point := _get_bow_aim_world_target()
	var to_target := aim_point - bow_origin
	if to_target.length_squared() < 0.0001:
		return _get_aim_direction()
	return to_target.normalized()


func _on_bow_arrow_fired() -> void:
	if _ammo <= 0:
		return
	enter_overworld_combat()
	_ammo -= 1
	_shot_cooldown = GroyperWeapons.get_shot_cooldown(_equipped_weapon)
	_notify_nearby_enemies_of_gunshot(_get_bow_fire_origin())
	if _ammo_hud:
		_ammo_hud.sync_rounds(_ammo, true)


func _get_arm_aim_world_target() -> Vector3:
	var origin := _get_aim_ray_origin()
	var direction := _get_aim_direction()
	if _is_bow_free_aim():
		var depth := maxf(
			_raycast_aim_depth(origin, direction, BOW_MIN_AIM_DISTANCE),
			AIM_ARM_TARGET_DISTANCE
		)
		return origin + direction * depth
	return origin + direction * AIM_ARM_TARGET_DISTANCE


func _should_update_reticle() -> bool:
	if _is_mounted() or _weapon_rig == null:
		return false
	if _is_bow_free_aim():
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


func _setup_melee_library() -> void:
	if _animation_player == null:
		return

	var library := AnimationLibrary.new()
	_add_melee_clip(library, GroyperMeleeAnimConfig.CLIP_COMBAT_IDLE, GroyperMeleeAnimConfig.COMBAT_IDLE_SCENE, Animation.LOOP_LINEAR)
	_add_melee_clip(library, GroyperMeleeAnimConfig.CLIP_SWORD_SLASH, GroyperMeleeAnimConfig.SWORD_SLASH_SCENE, Animation.LOOP_NONE)
	var slash := library.get_animation(GroyperMeleeAnimConfig.CLIP_SWORD_SLASH)
	if slash != null:
		var slash_reverse := RigAnimUtils.make_reversed_animation(slash)
		slash_reverse.loop_mode = Animation.LOOP_NONE
		library.add_animation(GroyperMeleeAnimConfig.CLIP_SWORD_SLASH_REVERSE, slash_reverse)
	_attack_reverse_anim_name = GroyperMeleeAnimConfig.clip_path(
		GroyperMeleeAnimConfig.CLIP_SWORD_SLASH_REVERSE
	)
	_add_melee_clip(
		library,
		GroyperMeleeAnimConfig.CLIP_SPIN_ATTACK,
		GroyperMeleeAnimConfig.SPIN_ATTACK_SCENE,
		Animation.LOOP_NONE
	)
	var spin := library.get_animation(GroyperMeleeAnimConfig.CLIP_SPIN_ATTACK)
	if spin != null:
		var spin_reverse := RigAnimUtils.make_reversed_animation(spin)
		spin_reverse.loop_mode = Animation.LOOP_NONE
		library.add_animation(GroyperMeleeAnimConfig.CLIP_SPIN_ATTACK_REVERSE, spin_reverse)
	_spin_attack_anim_name = GroyperMeleeAnimConfig.clip_path(
		GroyperMeleeAnimConfig.CLIP_SPIN_ATTACK
	)
	_spin_attack_reverse_anim_name = GroyperMeleeAnimConfig.clip_path(
		GroyperMeleeAnimConfig.CLIP_SPIN_ATTACK_REVERSE
	)
	_add_melee_clip(library, GroyperMeleeAnimConfig.CLIP_BLOCK_HOLD, GroyperMeleeAnimConfig.BLOCK_HOLD_SCENE, Animation.LOOP_LINEAR)
	_add_melee_clip(library, GroyperMeleeAnimConfig.CLIP_BLOCK_CLASH, GroyperMeleeAnimConfig.BLOCK_CLASH_SCENE, Animation.LOOP_NONE)
	_add_melee_clip(library, GroyperMeleeAnimConfig.CLIP_BLOCK_BREAK, GroyperMeleeAnimConfig.BLOCK_BREAK_SCENE, Animation.LOOP_NONE)
	_add_melee_clip(
		library,
		GroyperMeleeAnimConfig.CLIP_BLOCK_WALK_BACKWARD,
		GroyperMeleeAnimConfig.BLOCK_WALK_BACKWARD_SCENE,
		Animation.LOOP_LINEAR
	)

	if _animation_player.has_animation_library(GroyperMeleeAnimConfig.LIBRARY):
		_animation_player.remove_animation_library(GroyperMeleeAnimConfig.LIBRARY)
	_animation_player.add_animation_library(GroyperMeleeAnimConfig.LIBRARY, library)

	var block_walk_back := library.get_animation(GroyperMeleeAnimConfig.CLIP_BLOCK_WALK_BACKWARD)
	if block_walk_back != null:
		var block_walk_forward := RigAnimUtils.make_reversed_animation(block_walk_back)
		block_walk_forward.loop_mode = Animation.LOOP_LINEAR
		library.add_animation(GroyperMeleeAnimConfig.CLIP_BLOCK_WALK_FORWARD, block_walk_forward)

	_block_walk_backward_path = GroyperMeleeAnimConfig.clip_path(
		GroyperMeleeAnimConfig.CLIP_BLOCK_WALK_BACKWARD
	)
	_block_walk_forward_path = GroyperMeleeAnimConfig.clip_path(
		GroyperMeleeAnimConfig.CLIP_BLOCK_WALK_FORWARD
	)


func _add_melee_clip(
	library: AnimationLibrary,
	clip_name: StringName,
	scene_path: String,
	loop_mode: Animation.LoopMode
) -> void:
	var raw := RigAnimUtils.load_skeleton_animation(scene_path)
	if raw == null:
		push_error(
			"GroyperOverworldPlayer: failed to load melee clip '%s' from %s."
			% [clip_name, scene_path]
		)
		return
	var animation := RigAnimUtils.prepare_for_body_player(raw, false)
	RigAnimUtils.strip_root_motion(animation)
	animation.loop_mode = loop_mode
	library.add_animation(clip_name, animation)


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


func _setup_punch_pose_library() -> void:
	if _animation_player == null:
		push_error("GroyperOverworldPlayer: missing AnimationPlayer on body.")
		return

	var source := PunchPoseExtractScript.load_authored_library()
	if source == null:
		push_error(
			"GroyperOverworldPlayer: missing punch_pose.tres — "
			+ "author in groyper_body.tscn or run PunchPoseExtract."
		)
		return

	if _animation_player.has_animation_library(PunchPoseConfig.LIBRARY_NAME):
		_animation_player.remove_animation_library(PunchPoseConfig.LIBRARY_NAME)
	_animation_player.add_animation_library(PunchPoseConfig.LIBRARY_NAME, source.duplicate(true))


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
	_idle_anim_node = idle_node
	_peaceful_idle_path = idle_path
	_combat_idle_path = GroyperMeleeAnimConfig.clip_path(GroyperMeleeAnimConfig.CLIP_COMBAT_IDLE)

	var walk_node := AnimationNodeAnimation.new()
	walk_node.animation = walk_path
	_walk_anim_node = walk_node

	var run_node := AnimationNodeAnimation.new()
	run_node.animation = run_path

	var walk_reverse_node := AnimationNodeAnimation.new()
	walk_reverse_node.animation = walk_reverse_path
	_walk_reverse_anim_node = walk_reverse_node

	var walk_blend_space := AnimationNodeBlendSpace1D.new()
	walk_blend_space.add_blend_point(walk_reverse_node, WALK_DIR_BACK_BLEND)
	walk_blend_space.add_blend_point(walk_node, WALK_DIR_WALK_BLEND)
	walk_blend_space.add_blend_point(run_node, WALK_DIR_RUN_BLEND)
	walk_blend_space.min_space = WALK_DIR_BACK_BLEND
	walk_blend_space.max_space = WALK_DIR_RUN_BLEND
	walk_blend_space.sync = true
	walk_blend_space.snap = 0.0

	var move_blend := AnimationNodeBlend2.new()
	move_blend.sync = true

	var move_locomotion_node: StringName = WALK_LOCOMOTION_BLEND
	var block_walk_blend_space: AnimationNodeBlendSpace1D = null
	var block_walk_layer_blend: AnimationNodeBlend2 = null
	_melee_block_walk_nodes_ready = false
	if (
		_animation_player.has_animation(_block_walk_backward_path)
		and _animation_player.has_animation(_block_walk_forward_path)
	):
		_melee_block_walk_nodes_ready = true

		var block_walk_reverse_node := AnimationNodeAnimation.new()
		block_walk_reverse_node.animation = _block_walk_backward_path

		var block_walk_forward_node := AnimationNodeAnimation.new()
		block_walk_forward_node.animation = _block_walk_forward_path

		block_walk_blend_space = AnimationNodeBlendSpace1D.new()
		block_walk_blend_space.add_blend_point(block_walk_reverse_node, WALK_DIR_BACK_BLEND)
		block_walk_blend_space.add_blend_point(block_walk_forward_node, WALK_DIR_WALK_BLEND)
		block_walk_blend_space.min_space = WALK_DIR_BACK_BLEND
		block_walk_blend_space.max_space = WALK_DIR_WALK_BLEND
		block_walk_blend_space.sync = true
		block_walk_blend_space.snap = 0.0

		block_walk_layer_blend = AnimationNodeBlend2.new()
		block_walk_layer_blend.sync = true
		move_locomotion_node = GroyperMeleeAnimConfig.BLOCK_WALK_LOCOMOTION_BLEND

	var idle_locomotion_node: StringName = LOCOMOTION_IDLE_NODE
	var combat_idle_anim_node: AnimationNodeAnimation = null
	var combat_idle_layer_blend: AnimationNodeBlend2 = null
	_melee_combat_idle_nodes_ready = false
	if _animation_player.has_animation(_combat_idle_path):
		_melee_combat_idle_nodes_ready = true

		combat_idle_anim_node = AnimationNodeAnimation.new()
		combat_idle_anim_node.animation = _combat_idle_path
		var combat_idle_res := _animation_player.get_animation(_combat_idle_path)
		if combat_idle_res != null:
			combat_idle_res.loop_mode = Animation.LOOP_LINEAR

		combat_idle_layer_blend = AnimationNodeBlend2.new()
		combat_idle_layer_blend.sync = true
		idle_locomotion_node = GroyperMeleeAnimConfig.COMBAT_IDLE_BLEND

	_roll_anim_node = AnimationNodeAnimation.new()
	_roll_anim_node.animation = walk_roll_path

	var roll_one_shot := AnimationNodeOneShot.new()
	roll_one_shot.fadein_time = ROLL_ANIM_FADEIN
	roll_one_shot.fadeout_time = ROLL_ANIM_FADEOUT
	roll_one_shot.sync = true

	var punch_path := PunchPoseConfig.get_animation_path()
	var punch_has_clip := false
	if _animation_player.has_animation(punch_path):
		_punch_anim_node = AnimationNodeAnimation.new()
		_punch_anim_node.animation = punch_path
		punch_has_clip = true
	else:
		push_warning("GroyperOverworldPlayer: missing punch pose — author in groyper_body.tscn.")

	var punch_time_seek := AnimationNodeTimeSeek.new()
	_punch_blend_node = AnimationNodeBlend2.new()
	_punch_blend_node.sync = false
	if punch_has_clip:
		PunchPoseConfig.configure_punch_blend_filter(_punch_blend_node)

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

	var bonfire_has_clips := (
		_animation_player.has_animation(BonfirePoseConfig.get_stand_up3_path())
		and _animation_player.has_animation(BonfirePoseConfig.get_stand_up3_reverse_path())
		and _animation_player.has_animation(BonfirePoseConfig.get_sit_cross_path())
	)
	if not bonfire_has_clips:
		push_warning(
			"GroyperOverworldPlayer: missing bonfire pose clips — check Stand Up3 / Sit Cross Legged imports."
		)

	var blend_tree := AnimationNodeBlendTree.new()
	blend_tree.add_node(LOCOMOTION_IDLE_NODE, idle_node)
	if combat_idle_anim_node != null and combat_idle_layer_blend != null:
		blend_tree.add_node(GroyperMeleeAnimConfig.COMBAT_IDLE_ANIM, combat_idle_anim_node)
		blend_tree.add_node(GroyperMeleeAnimConfig.COMBAT_IDLE_BLEND, combat_idle_layer_blend)
		blend_tree.connect_node(GroyperMeleeAnimConfig.COMBAT_IDLE_BLEND, 0, LOCOMOTION_IDLE_NODE)
		blend_tree.connect_node(
			GroyperMeleeAnimConfig.COMBAT_IDLE_BLEND,
			1,
			GroyperMeleeAnimConfig.COMBAT_IDLE_ANIM
		)
	blend_tree.add_node(WALK_LOCOMOTION_BLEND, walk_blend_space)
	if block_walk_blend_space != null and block_walk_layer_blend != null:
		blend_tree.add_node(GroyperMeleeAnimConfig.BLOCK_WALK_LOCOMOTION_SPACE, block_walk_blend_space)
		blend_tree.add_node(GroyperMeleeAnimConfig.BLOCK_WALK_LOCOMOTION_BLEND, block_walk_layer_blend)
		blend_tree.connect_node(
			GroyperMeleeAnimConfig.BLOCK_WALK_LOCOMOTION_BLEND,
			0,
			WALK_LOCOMOTION_BLEND
		)
		blend_tree.connect_node(
			GroyperMeleeAnimConfig.BLOCK_WALK_LOCOMOTION_BLEND,
			1,
			GroyperMeleeAnimConfig.BLOCK_WALK_LOCOMOTION_SPACE
		)
	blend_tree.add_node(LOCOMOTION_BLEND, move_blend)
	blend_tree.connect_node(LOCOMOTION_BLEND, 0, idle_locomotion_node)
	blend_tree.connect_node(LOCOMOTION_BLEND, 1, move_locomotion_node)
	blend_tree.add_node(ROLL_ANIM_NODE, _roll_anim_node)
	blend_tree.add_node(ROLL_ONE_SHOT, roll_one_shot)
	if punch_has_clip:
		blend_tree.add_node(PUNCH_ANIM_NODE, _punch_anim_node)
		blend_tree.add_node(PunchPoseConfig.TIME_SEEK_NODE, punch_time_seek)
		blend_tree.add_node(PunchPoseConfig.BLEND_NODE, _punch_blend_node)
	blend_tree.add_node(VAULT_ANIM_NODE, _vault_anim_node)
	blend_tree.add_node(VAULT_TIME_SEEK, vault_time_seek)
	blend_tree.add_node(VAULT_BLEND, _vault_blend_node)
	blend_tree.add_node(CROUCH_COVER_ANIM_NODE, crouch_cover_anim)
	blend_tree.add_node(COVER_POSE_BLEND, _cover_pose_blend_node)
	blend_tree.add_node(COVER_PEEK_AIM_ANIM_NODE, cover_peek_aim_anim)
	blend_tree.add_node(COVER_PEEK_BLEND, _cover_peek_blend_node)
	blend_tree.add_node(SADDLE_ANIM_NODE, saddle_anim)
	blend_tree.add_node(SADDLE_BLEND, _saddle_blend_node)
	if bonfire_has_clips:
		_bonfire_stand_anim_node = AnimationNodeAnimation.new()
		_bonfire_stand_anim_node.animation = BonfirePoseConfig.get_stand_up3_reverse_path()

		var bonfire_stand_seek := AnimationNodeTimeSeek.new()

		var sit_cross_anim := AnimationNodeAnimation.new()
		sit_cross_anim.animation = BonfirePoseConfig.get_sit_cross_path()

		_bonfire_pose_blend_node = AnimationNodeBlend2.new()
		_bonfire_pose_blend_node.sync = false

		_bonfire_blend_node = AnimationNodeBlend2.new()
		_bonfire_blend_node.sync = false

		blend_tree.add_node(BonfirePoseConfig.STAND_ANIM_NODE, _bonfire_stand_anim_node)
		blend_tree.add_node(BonfirePoseConfig.STAND_TIME_SEEK, bonfire_stand_seek)
		blend_tree.add_node(BonfirePoseConfig.SIT_ANIM_NODE, sit_cross_anim)
		blend_tree.add_node(BonfirePoseConfig.BONFIRE_POSE_BLEND, _bonfire_pose_blend_node)
		blend_tree.add_node(BonfirePoseConfig.BONFIRE_BLEND, _bonfire_blend_node)
	blend_tree.connect_node(ROLL_ONE_SHOT, 0, LOCOMOTION_BLEND)
	blend_tree.connect_node(ROLL_ONE_SHOT, 1, ROLL_ANIM_NODE)
	if punch_has_clip:
		blend_tree.connect_node(PunchPoseConfig.TIME_SEEK_NODE, 0, PUNCH_ANIM_NODE)
		blend_tree.connect_node(PunchPoseConfig.BLEND_NODE, 0, ROLL_ONE_SHOT)
		blend_tree.connect_node(PunchPoseConfig.BLEND_NODE, 1, PunchPoseConfig.TIME_SEEK_NODE)
		blend_tree.connect_node(VAULT_BLEND, 0, PunchPoseConfig.BLEND_NODE)
	else:
		blend_tree.connect_node(VAULT_BLEND, 0, ROLL_ONE_SHOT)
	blend_tree.connect_node(VAULT_TIME_SEEK, 0, VAULT_ANIM_NODE)
	blend_tree.connect_node(VAULT_BLEND, 1, VAULT_TIME_SEEK)
	blend_tree.connect_node(COVER_POSE_BLEND, 0, VAULT_BLEND)
	blend_tree.connect_node(COVER_POSE_BLEND, 1, CROUCH_COVER_ANIM_NODE)
	blend_tree.connect_node(COVER_PEEK_BLEND, 0, COVER_POSE_BLEND)
	blend_tree.connect_node(COVER_PEEK_BLEND, 1, COVER_PEEK_AIM_ANIM_NODE)
	blend_tree.connect_node(SADDLE_BLEND, 0, COVER_PEEK_BLEND)
	blend_tree.connect_node(SADDLE_BLEND, 1, SADDLE_ANIM_NODE)
	if bonfire_has_clips:
		blend_tree.connect_node(BonfirePoseConfig.STAND_TIME_SEEK, 0, BonfirePoseConfig.STAND_ANIM_NODE)
		blend_tree.connect_node(BonfirePoseConfig.BONFIRE_POSE_BLEND, 0, BonfirePoseConfig.STAND_TIME_SEEK)
		blend_tree.connect_node(BonfirePoseConfig.BONFIRE_POSE_BLEND, 1, BonfirePoseConfig.SIT_ANIM_NODE)
		blend_tree.connect_node(BonfirePoseConfig.BONFIRE_BLEND, 0, SADDLE_BLEND)
		blend_tree.connect_node(BonfirePoseConfig.BONFIRE_BLEND, 1, BonfirePoseConfig.BONFIRE_POSE_BLEND)
		var melee_output := _attach_melee_combat_nodes(blend_tree, BonfirePoseConfig.BONFIRE_BLEND)
		var final_output := _attach_hit_reaction_nodes(blend_tree, melee_output)
		blend_tree.connect_node(&"output", 0, final_output)
	else:
		var melee_output := _attach_melee_combat_nodes(blend_tree, SADDLE_BLEND)
		var final_output := _attach_hit_reaction_nodes(blend_tree, melee_output)
		blend_tree.connect_node(&"output", 0, final_output)

	_animation_tree.tree_root = blend_tree
	_animation_tree.anim_player = _animation_tree.get_path_to(_animation_player)
	_animation_tree.process_priority = -100
	_animation_tree.active = true
	_apply_locomotion_tree_blends()
	if _melee_combat_nodes_ready:
		_animation_tree.set(
			"parameters/%s/blend_amount" % GroyperMeleeAnimConfig.BLOCK_HOLD_BLEND,
			0.0
		)
	if _melee_block_walk_nodes_ready:
		_animation_tree.set(
			"parameters/%s/blend_amount" % GroyperMeleeAnimConfig.BLOCK_WALK_LOCOMOTION_BLEND,
			0.0
		)
	if _melee_combat_idle_nodes_ready:
		_animation_tree.set(
			"parameters/%s/blend_amount" % GroyperMeleeAnimConfig.COMBAT_IDLE_BLEND,
			0.0
		)
	_init_vault_animation_tree_state()
	_init_punch_animation_tree_state()
	_init_bonfire_animation_tree_state()
	_init_hit_reaction_animation_tree_state()


func _init_punch_animation_tree_state() -> void:
	_punch_blend = 0.0
	PunchPoseConfig.set_tree_blend(_animation_tree, 0.0)
	PunchPoseConfig.set_tree_seek(_animation_tree, 0.0)


func _init_vault_animation_tree_state() -> void:
	_vault_blend = 0.0
	if _animation_tree == null:
		return
	_animation_tree.set("parameters/%s/blend_amount" % VAULT_BLEND, 0.0)
	_animation_tree.set("parameters/%s/seek_request" % VAULT_TIME_SEEK, -1.0)


func _init_bonfire_animation_tree_state() -> void:
	_bonfire_blend = 0.0
	_bonfire_pose_blend = 0.0
	_bonfire_timer = 0.0
	_bonfire_pose_timer = 0.0
	_bonfire_stand_duration = 0.0
	_bonfire_stand_up_pending = false
	_bonfire_anim_phase = BonfireAnimPhase.NONE
	_bonfire_interact_target = null
	_bonfire_camera_blend = 0.0
	_bonfire_camera_target_blend = 0.0
	_bonfire_movement_unlocked = false
	if _animation_tree == null:
		return
	BonfirePoseConfig.set_bonfire_blend(_animation_tree, 0.0)
	BonfirePoseConfig.set_pose_blend(_animation_tree, 0.0)
	BonfirePoseConfig.set_stand_seek(_animation_tree, -1.0)


func _attach_melee_combat_nodes(blend_tree: AnimationNodeBlendTree, input_node: StringName) -> StringName:
	var block_hold_path := GroyperMeleeAnimConfig.clip_path(GroyperMeleeAnimConfig.CLIP_BLOCK_HOLD)
	var attack_path := GroyperMeleeAnimConfig.clip_path(GroyperMeleeAnimConfig.CLIP_SWORD_SLASH)
	var clash_path := GroyperMeleeAnimConfig.clip_path(GroyperMeleeAnimConfig.CLIP_BLOCK_CLASH)
	var break_path := GroyperMeleeAnimConfig.clip_path(GroyperMeleeAnimConfig.CLIP_BLOCK_BREAK)

	if not _animation_player.has_animation(block_hold_path) or not _animation_player.has_animation(attack_path):
		_melee_combat_nodes_ready = false
		return input_node

	_melee_combat_nodes_ready = true
	_attack_anim_name = attack_path

	var block_hold_node := AnimationNodeAnimation.new()
	block_hold_node.animation = block_hold_path
	var block_hold_blend := AnimationNodeBlend2.new()
	BaldwinAnimUtilsScript.configure_block_hold_blend(block_hold_blend)

	var attack_node := AnimationNodeAnimation.new()
	attack_node.animation = attack_path
	_melee_attack_anim_node = attack_node
	var attack_time_seek := AnimationNodeTimeSeek.new()
	var attack_time_scale := AnimationNodeTimeScale.new()
	var attack_shot := AnimationNodeOneShot.new()
	CombatAnimTransitionsScript.configure_one_shot(
		attack_shot,
		CombatAnimTransitionsScript.ATTACK_FADEIN,
		CombatAnimTransitionsScript.ATTACK_FADEOUT
	)

	blend_tree.add_node(GroyperMeleeAnimConfig.BLOCK_HOLD_BLEND, block_hold_blend)
	blend_tree.add_node(GroyperMeleeAnimConfig.SHIELD_BLOCK_HOLD_ANIM, block_hold_node)
	blend_tree.add_node(GroyperMeleeAnimConfig.ATTACK_ONE_SHOT, attack_shot)
	blend_tree.add_node(GroyperMeleeAnimConfig.ATTACK_ANIM, attack_node)
	blend_tree.add_node(GroyperMeleeAnimConfig.ATTACK_TIME_SEEK, attack_time_seek)
	blend_tree.add_node(GroyperMeleeAnimConfig.ATTACK_TIME_SCALE, attack_time_scale)
	blend_tree.connect_node(GroyperMeleeAnimConfig.BLOCK_HOLD_BLEND, 0, input_node)
	blend_tree.connect_node(GroyperMeleeAnimConfig.BLOCK_HOLD_BLEND, 1, GroyperMeleeAnimConfig.SHIELD_BLOCK_HOLD_ANIM)
	blend_tree.connect_node(GroyperMeleeAnimConfig.ATTACK_ONE_SHOT, 0, GroyperMeleeAnimConfig.BLOCK_HOLD_BLEND)
	blend_tree.connect_node(GroyperMeleeAnimConfig.ATTACK_ONE_SHOT, 1, GroyperMeleeAnimConfig.ATTACK_TIME_SEEK)
	blend_tree.connect_node(GroyperMeleeAnimConfig.ATTACK_TIME_SEEK, 0, GroyperMeleeAnimConfig.ATTACK_TIME_SCALE)
	blend_tree.connect_node(GroyperMeleeAnimConfig.ATTACK_TIME_SCALE, 0, GroyperMeleeAnimConfig.ATTACK_ANIM)
	_set_melee_attack_playback_speed(1.0)

	var output_node: StringName = GroyperMeleeAnimConfig.ATTACK_ONE_SHOT

	if _animation_player.has_animation(clash_path):
		_shield_block_clash_path = clash_path
		var clash_node := AnimationNodeAnimation.new()
		clash_node.animation = clash_path
		var clash_shot := AnimationNodeOneShot.new()
		CombatAnimTransitionsScript.configure_one_shot(
			clash_shot,
			CombatAnimTransitionsScript.PARRY_CLASH_FADEIN,
			CombatAnimTransitionsScript.PARRY_CLASH_FADEOUT,
			true
		)
		blend_tree.add_node(GroyperMeleeAnimConfig.BLOCK_CLASH_ONE_SHOT, clash_shot)
		blend_tree.add_node(GroyperMeleeAnimConfig.SHIELD_BLOCK_CLASH_ANIM, clash_node)
		blend_tree.connect_node(GroyperMeleeAnimConfig.BLOCK_CLASH_ONE_SHOT, 0, output_node)
		blend_tree.connect_node(
			GroyperMeleeAnimConfig.BLOCK_CLASH_ONE_SHOT,
			1,
			GroyperMeleeAnimConfig.SHIELD_BLOCK_CLASH_ANIM
		)
		output_node = GroyperMeleeAnimConfig.BLOCK_CLASH_ONE_SHOT

	if _animation_player.has_animation(break_path):
		_shield_block_break_path = break_path
		var break_node := AnimationNodeAnimation.new()
		break_node.animation = break_path
		var break_shot := AnimationNodeOneShot.new()
		CombatAnimTransitionsScript.configure_one_shot(
			break_shot,
			CombatAnimTransitionsScript.BLOCK_BREAK_FADEIN,
			CombatAnimTransitionsScript.BLOCK_BREAK_FADEOUT,
			true
		)
		blend_tree.add_node(GroyperMeleeAnimConfig.BLOCK_BREAK_ONE_SHOT, break_shot)
		blend_tree.add_node(GroyperMeleeAnimConfig.SHIELD_BLOCK_BREAK_ANIM, break_node)
		blend_tree.connect_node(GroyperMeleeAnimConfig.BLOCK_BREAK_ONE_SHOT, 0, output_node)
		blend_tree.connect_node(
			GroyperMeleeAnimConfig.BLOCK_BREAK_ONE_SHOT,
			1,
			GroyperMeleeAnimConfig.SHIELD_BLOCK_BREAK_ANIM
		)
		output_node = GroyperMeleeAnimConfig.BLOCK_BREAK_ONE_SHOT

	return output_node


func _attach_hit_reaction_nodes(
	blend_tree: AnimationNodeBlendTree,
	input_node: StringName
) -> StringName:
	var fall_path := GroyperHitReactionConfig.get_falling_down_path()
	var stand_path := BonfirePoseConfig.get_stand_up3_path()
	if (
		not _animation_player.has_animation(fall_path)
		or not _animation_player.has_animation(stand_path)
	):
		_hit_reaction_nodes_ready = false
		return input_node

	_hit_reaction_nodes_ready = true

	var fall_anim := AnimationNodeAnimation.new()
	fall_anim.animation = fall_path
	_hit_reaction_fall_anim_node = fall_anim

	var fall_seek := AnimationNodeTimeSeek.new()

	var stand_anim := AnimationNodeAnimation.new()
	stand_anim.animation = stand_path
	_hit_reaction_stand_anim_node = stand_anim

	var stand_seek := AnimationNodeTimeSeek.new()
	var stand_scale := AnimationNodeTimeScale.new()

	var pose_blend := AnimationNodeBlend2.new()
	pose_blend.sync = false
	_hit_reaction_pose_blend_node = pose_blend

	var reaction_blend := AnimationNodeBlend2.new()
	reaction_blend.sync = false
	_hit_reaction_blend_node = reaction_blend

	blend_tree.add_node(GroyperHitReactionConfig.FALL_ANIM_NODE, fall_anim)
	blend_tree.add_node(GroyperHitReactionConfig.FALL_TIME_SEEK, fall_seek)
	blend_tree.add_node(GroyperHitReactionConfig.STAND_ANIM_NODE, stand_anim)
	blend_tree.add_node(GroyperHitReactionConfig.STAND_TIME_SEEK, stand_seek)
	blend_tree.add_node(GroyperHitReactionConfig.STAND_TIME_SCALE, stand_scale)
	blend_tree.add_node(GroyperHitReactionConfig.HIT_REACTION_POSE_BLEND, pose_blend)
	blend_tree.add_node(GroyperHitReactionConfig.HIT_REACTION_BLEND, reaction_blend)

	blend_tree.connect_node(GroyperHitReactionConfig.FALL_TIME_SEEK, 0, GroyperHitReactionConfig.FALL_ANIM_NODE)
	blend_tree.connect_node(GroyperHitReactionConfig.STAND_TIME_SEEK, 0, GroyperHitReactionConfig.STAND_TIME_SCALE)
	blend_tree.connect_node(GroyperHitReactionConfig.STAND_TIME_SCALE, 0, GroyperHitReactionConfig.STAND_ANIM_NODE)
	blend_tree.connect_node(GroyperHitReactionConfig.HIT_REACTION_POSE_BLEND, 0, GroyperHitReactionConfig.FALL_TIME_SEEK)
	blend_tree.connect_node(GroyperHitReactionConfig.HIT_REACTION_POSE_BLEND, 1, GroyperHitReactionConfig.STAND_TIME_SEEK)
	blend_tree.connect_node(GroyperHitReactionConfig.HIT_REACTION_BLEND, 0, input_node)
	blend_tree.connect_node(GroyperHitReactionConfig.HIT_REACTION_BLEND, 1, GroyperHitReactionConfig.HIT_REACTION_POSE_BLEND)

	return GroyperHitReactionConfig.HIT_REACTION_BLEND


func _init_hit_reaction_animation_tree_state() -> void:
	_hit_reaction_active = false
	_hit_reaction_phase = GroyperHitReactionConfig.Phase.NONE
	_hit_reaction_blend = 0.0
	_hit_reaction_pose_blend = 0.0
	_hit_reaction_fall_timer = 0.0
	_hit_reaction_stand_timer = 0.0
	_hit_reaction_impulse_timer = 0.0
	_hit_reaction_control_unlocked = false
	_hit_reaction_model_sink = 0.0
	_hit_reaction_applied_body_sink = 0.0
	if _animation_tree == null:
		return
	GroyperHitReactionConfig.set_reaction_blend(_animation_tree, 0.0)
	GroyperHitReactionConfig.set_pose_blend(_animation_tree, 0.0)
	GroyperHitReactionConfig.set_fall_seek(_animation_tree, -1.0)
	GroyperHitReactionConfig.set_stand_seek(_animation_tree, -1.0)
	GroyperHitReactionConfig.set_stand_playback_speed(_animation_tree, 1.0)


func _can_use_sword_shield_melee() -> bool:
	return (
		GroyperWeapons.is_sword_shield(_equipped_weapon)
		and _melee_weapon_rig != null
		and _melee_weapon_rig.is_equipped()
		and not _melee_weapon_rig.is_transitioning()
		and not is_melee_stunned()
		and not _hit_reaction_active
	)


func _is_in_gun_aim_stance() -> bool:
	return _weapon_rig != null and not _weapon_rig.is_holstered()


func _is_in_combat_weapon_stance() -> bool:
	return _is_in_gun_aim_stance()


func _update_melee_input_hold() -> void:
	if _reflect_active:
		return
	if not _can_use_sword_shield_melee():
		if _combat_blocking:
			_end_melee_blocking()
		return
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		if not _combat_blocking and not _combat_attacking:
			_begin_melee_blocking()
	elif _combat_blocking:
		_end_melee_blocking()


func _can_use_melee_combat_idle() -> bool:
	if _idle_anim_node == null or not GroyperWeapons.is_sword_shield(_equipped_weapon):
		return false
	if _melee_weapon_rig == null or not _melee_weapon_rig.is_equipped():
		return false
	return _animation_player.has_animation(_combat_idle_path)


func _get_combat_idle_blend_target() -> float:
	if not _can_use_melee_combat_idle():
		return 0.0
	if _combat_attacking:
		return 0.0
	# Keep combat idle on the idle branch whenever the sword is out so stopping
	# crossfades walk -> combat idle instead of walk -> peaceful -> combat idle.
	return 1.0


func _uses_melee_combat_locomotion_blend() -> bool:
	return (
		_can_use_melee_combat_idle()
		and _melee_combat_idle_nodes_ready
		and not _combat_attacking
		and not _combat_blocking
		and not _reflect_active
	)


func _apply_combat_idle_tree_blend() -> void:
	if not _melee_combat_idle_nodes_ready or _animation_tree == null or not _animation_tree.active:
		return
	_animation_tree.set(
		"parameters/%s/blend_amount" % GroyperMeleeAnimConfig.COMBAT_IDLE_BLEND,
		_combat_idle_blend
	)


func _set_combat_idle_blend_instant(value: float) -> void:
	_combat_idle_blend = clampf(value, 0.0, 1.0)
	_apply_combat_idle_tree_blend()


func _update_combat_idle_blend(delta: float) -> void:
	var target := _get_combat_idle_blend_target()
	if is_equal_approx(_combat_idle_blend, target):
		return
	var blend_time := (
		COMBAT_IDLE_BLEND_IN_TIME
		if target > _combat_idle_blend
		else COMBAT_IDLE_BLEND_OUT_TIME
	)
	var step := _block_hold_blend_step(delta, blend_time)
	_combat_idle_blend = lerpf(_combat_idle_blend, target, step)
	_apply_combat_idle_tree_blend()


func _block_hold_blend_step(delta: float, blend_time: float) -> float:
	return 1.0 - exp(
		-BLOCK_HOLD_BLEND_APPROACH * delta / maxf(blend_time, 0.001)
	)


func _apply_block_walk_locomotion_blend() -> void:
	if not _melee_block_walk_nodes_ready or _animation_tree == null or not _animation_tree.active:
		return
	_animation_tree.set(
		"parameters/%s/blend_amount" % GroyperMeleeAnimConfig.BLOCK_WALK_LOCOMOTION_BLEND,
		_block_walk_amount
	)


func _update_block_walk_amount(
	delta: float,
	speed: float,
	walk_speed: float,
	move_dir: Vector3
) -> void:
	if not _combat_blocking:
		if _block_walk_amount <= 0.001:
			return
		var reset_step := _block_hold_blend_step(delta, BLOCK_HOLD_BLEND_OUT_TIME)
		_block_walk_amount = lerpf(_block_walk_amount, 0.0, reset_step)
		_apply_block_walk_locomotion_blend()
		return

	var target := 0.0
	if move_dir.length_squared() > 0.0001:
		target = maxf(target, BLOCK_WALK_INPUT_HINT)
	if speed > MELEE_COMBAT_IDLE_STOP_SPEED:
		target = maxf(
			target,
			clampf(speed / maxf(walk_speed, 0.001), 0.0, 1.0)
		)

	var blend_time := (
		BLOCK_HOLD_WALK_BLEND_IN_TIME
		if target > _block_walk_amount
		else BLOCK_HOLD_WALK_BLEND_OUT_TIME
	)
	var step := _block_hold_blend_step(delta, blend_time)
	_block_walk_amount = lerpf(_block_walk_amount, target, step)
	_apply_block_walk_locomotion_blend()


func _uses_block_locomotion_visual() -> bool:
	if not GroyperWeapons.is_sword_shield(_equipped_weapon):
		return false
	return (
		_combat_blocking
		or _reflect_active
		or _melee_block_hold_blend > 0.001
		or _block_walk_amount > 0.001
	)


func _prepare_block_parry_visual() -> void:
	if not _melee_combat_nodes_ready:
		return
	_set_melee_block_hold_blend(1.0)


func _fire_block_parry_one_shot() -> void:
	if not _melee_combat_nodes_ready or _animation_tree == null or not _animation_tree.active:
		return
	if _shield_block_clash_path.is_empty():
		return
	_prepare_block_parry_visual()
	_animation_tree.set(
		"parameters/%s/request" % GroyperMeleeAnimConfig.BLOCK_CLASH_ONE_SHOT,
		AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	)


func _set_melee_block_hold_blend(value: float) -> void:
	_melee_block_hold_blend = clampf(value, 0.0, 1.0)
	if not _melee_combat_nodes_ready or _animation_tree == null or not _animation_tree.active:
		return
	_animation_tree.set(
		"parameters/%s/blend_amount" % GroyperMeleeAnimConfig.BLOCK_HOLD_BLEND,
		_melee_block_hold_blend
	)


func _update_melee_block_hold_blend_state(delta: float) -> void:
	if not _melee_combat_nodes_ready:
		return

	if _reflect_active:
		_set_melee_block_hold_blend(1.0)
		return

	if not _combat_blocking:
		var release_speed := Vector2(velocity.x, velocity.z).length()
		var release_move_dir := _get_block_locomotion_anim_direction(_get_camera_relative_input())
		_update_block_walk_amount(delta, release_speed, WALK_SPEED, release_move_dir)

		if _melee_block_hold_blend > 0.001:
			var fade_step := _block_hold_blend_step(delta, BLOCK_HOLD_BLEND_OUT_TIME)
			_set_melee_block_hold_blend(lerpf(_melee_block_hold_blend, 0.0, fade_step))
		return

	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var move_dir := _get_block_locomotion_anim_direction(_get_camera_relative_input())
	_update_block_walk_amount(delta, horizontal_speed, MELEE_BLOCK_WALK_SPEED, move_dir)
	var target := 1.0 - _block_walk_amount
	if is_equal_approx(_melee_block_hold_blend, target):
		return

	var blend_time: float
	if _block_walk_amount <= 0.001 and target > _melee_block_hold_blend:
		blend_time = BLOCK_HOLD_BLEND_IN_TIME
	elif _block_walk_amount <= 0.001 and target < _melee_block_hold_blend:
		blend_time = BLOCK_HOLD_BLEND_OUT_TIME
	elif target < _melee_block_hold_blend:
		blend_time = BLOCK_HOLD_WALK_BLEND_OUT_TIME
	else:
		blend_time = BLOCK_HOLD_WALK_BLEND_IN_TIME
	var step := _block_hold_blend_step(delta, blend_time)
	_set_melee_block_hold_blend(lerpf(_melee_block_hold_blend, target, step))


func _update_melee_block_hold_for_locomotion(delta: float) -> void:
	_update_melee_block_hold_blend_state(delta)


func _try_begin_melee_blocking() -> void:
	if not _can_use_sword_shield_melee() or _combat_attacking or _combat_blocking:
		return
	_begin_melee_blocking()


func _try_end_melee_blocking() -> void:
	if not _combat_blocking:
		return
	_end_melee_blocking()


func _begin_melee_blocking() -> void:
	_combat_blocking = true


func _end_melee_blocking(instant := false) -> void:
	_combat_blocking = false
	if instant:
		_set_melee_block_hold_blend(0.0)
		_block_walk_amount = 0.0
		_apply_block_walk_locomotion_blend()


func _is_sprint_melee_attack_ready() -> bool:
	if _is_in_gun_aim_stance():
		return false
	var move_dir := _get_camera_relative_input()
	return Input.is_key_pressed(KEY_SHIFT) and move_dir.length_squared() > 0.0001


func _get_active_attack_anim_name() -> StringName:
	return _spin_attack_anim_name if _attack_spin else _attack_anim_name


func _get_active_attack_reverse_anim_name() -> StringName:
	return _spin_attack_reverse_anim_name if _attack_spin else _attack_reverse_anim_name


func _get_melee_attack_strike_fraction() -> float:
	return (
		MELEE_SPIN_ATTACK_STRIKE_FRACTION
		if _attack_spin
		else MELEE_ATTACK_STRIKE_FRACTION
	)


func _get_melee_attack_visual_fraction() -> float:
	return MELEE_SPIN_ATTACK_VISUAL_FRACTION if _attack_spin else _get_melee_attack_strike_fraction()


func _get_melee_attack_playback_speed() -> float:
	if _attack_spin:
		return MELEE_SPIN_ATTACK_PLAYBACK_SPEED
	return MeleeSwordSlashScript.get_playback_speed(
		_animation_tree,
		GroyperMeleeAnimConfig.ATTACK_TIME_SCALE
	)


func _set_melee_attack_playback_speed(speed: float) -> void:
	if not _melee_combat_nodes_ready or _animation_tree == null or not _animation_tree.active:
		return
	_animation_tree.set(
		"parameters/%s/scale" % GroyperMeleeAnimConfig.ATTACK_TIME_SCALE,
		maxf(speed, 0.001)
	)


func _get_melee_attack_move_speed() -> float:
	return MELEE_SPIN_ATTACK_MOVE_SPEED if _attack_spin else MELEE_ATTACK_MOVE_SPEED


func _get_melee_attack_range() -> float:
	return MELEE_SPIN_ATTACK_RANGE if _attack_spin else MELEE_ATTACK_RANGE


func _try_begin_melee_attack() -> void:
	if not _can_use_sword_shield_melee() or _combat_blocking:
		return
	if _combat_attacking:
		if _can_queue_spin_to_slash_combo():
			_begin_melee_spin_to_slash_chain()
		elif _can_queue_melee_combo():
			_begin_melee_attack_reverse()
		return
	if _attack_cooldown > 0.0:
		return
	if _is_sprint_melee_attack_ready() and _animation_player.has_animation(_spin_attack_anim_name):
		_begin_melee_spin_attack()
	else:
		_begin_melee_attack()


func _can_queue_spin_to_slash_combo() -> bool:
	if not _attack_spin or _attack_spin_chained or not _attack_struck:
		return false
	if MeleeSwordSlashScript.is_in_spin_combo_input_window(_attack_anim_time):
		return true
	if _attack_recovery_to_idle:
		var anim_length := _get_melee_attack_length()
		return _attack_reverse_seek <= anim_length * MELEE_SPIN_RECOVERY_COMBO_FRACTION
	return false


func _can_queue_melee_combo() -> bool:
	return (
		not _attack_spin
		and _attack_struck
		and not _attack_reverse
		and not _attack_combo_used
		and not _attack_recovery_to_idle
		and MeleeSwordSlashScript.is_in_combo_input_window(_attack_anim_time)
	)


func _update_melee_attack_anim_time(delta: float) -> void:
	if _attack_reverse or _attack_recovery_to_idle:
		_attack_anim_time = _attack_reverse_seek
		return
	var one_shot_time := MeleeSwordSlashScript.read_one_shot_time(
		_animation_tree,
		GroyperMeleeAnimConfig.ATTACK_ONE_SHOT
	)
	if one_shot_time >= 0.0:
		_attack_anim_time = one_shot_time
	else:
		_attack_anim_time += MeleeSwordSlashScript.anim_time_step(
			delta,
			_get_melee_attack_playback_speed()
		)


func _begin_melee_attack() -> void:
	_begin_melee_attack_internal(false)


func _begin_melee_spin_attack() -> void:
	_begin_melee_attack_internal(true)


func _begin_melee_attack_internal(spin: bool) -> void:
	_cancel_melee_attack_seek_tween()
	_combat_attacking = true
	_attack_spin = spin
	_attack_spin_visual_applied = false
	_attack_spin_chained = false
	_attack_elapsed = 0.0
	_attack_anim_time = 0.0
	_set_melee_attack_playback_speed(MELEE_SPIN_ATTACK_PLAYBACK_SPEED if spin else 1.0)
	_attack_timer = _get_melee_attack_length() / _get_melee_attack_playback_speed()
	_attack_struck = false
	_attack_reverse = false
	_attack_combo_used = false
	_attack_recovery_to_idle = false
	_attack_reverse_seek = 0.0
	_attack_cooldown = MELEE_SPIN_ATTACK_COOLDOWN if spin else MELEE_ATTACK_COOLDOWN
	_face_melee_camera_direction(999.0)
	_attack_direction = _get_melee_flat_forward()
	_reset_locomotion_tree_blends()
	if _melee_attack_anim_node != null:
		_melee_attack_anim_node.animation = _get_active_attack_anim_name()
	_sync_melee_attack_seek(-1.0)
	if _animation_tree != null and _animation_tree.active and _melee_combat_nodes_ready:
		_reset_locomotion_tree_blends()
		_animation_tree.set(
			"parameters/%s/request" % GroyperMeleeAnimConfig.ATTACK_ONE_SHOT,
			AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
		)


func _begin_melee_attack_reverse() -> void:
	_cancel_melee_attack_seek_tween()
	_attack_combo_used = true
	_attack_reverse = true
	_attack_struck = false
	_attack_recovery_to_idle = false
	var anim_length := _get_melee_attack_length()
	var playback_speed := _get_melee_attack_playback_speed()
	var seek_start := clampf(_attack_anim_time, 0.0, anim_length)
	var seek_end := anim_length
	var reverse_duration := maxf((seek_end - seek_start) / playback_speed, 0.001)
	_attack_elapsed = 0.0
	_attack_timer = reverse_duration
	_face_melee_camera_direction(999.0)
	_attack_direction = _get_melee_flat_forward()
	var reverse_anim := _get_active_attack_reverse_anim_name()
	if _melee_attack_anim_node != null and _animation_player.has_animation(reverse_anim):
		_melee_attack_anim_node.animation = reverse_anim
	_tween_melee_attack_reverse_seek(seek_start, seek_end, reverse_duration)


func _begin_melee_spin_to_slash_chain() -> void:
	_cancel_melee_attack_seek_tween()
	_attack_spin_chained = true
	_attack_spin = false
	_attack_spin_visual_applied = false
	_attack_struck = false
	_attack_reverse = false
	_attack_recovery_to_idle = false
	_attack_combo_used = false
	_set_melee_attack_playback_speed(1.0)
	_face_melee_camera_direction(999.0)
	_attack_direction = _get_melee_flat_forward()

	if _melee_attack_anim_node != null:
		_melee_attack_anim_node.animation = _attack_anim_name

	var anim_length := _get_melee_attack_length()
	var playback_speed := _get_melee_attack_playback_speed()
	_attack_elapsed = 0.0
	_attack_anim_time = 0.0
	_attack_timer = anim_length / playback_speed
	_sync_melee_attack_seek(-1.0)
	if _animation_tree != null and _animation_tree.active and _melee_combat_nodes_ready:
		_animation_tree.set(
			"parameters/%s/request" % GroyperMeleeAnimConfig.ATTACK_ONE_SHOT,
			AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
		)


func _process_melee_attack(delta: float) -> void:
	_attack_elapsed += delta
	_attack_timer -= delta
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = minf(velocity.y, 0.0)

	var move_dir := _get_camera_relative_input()
	var target_h := Vector3.ZERO
	if move_dir.length_squared() > 0.0001:
		target_h = move_dir * _get_melee_attack_move_speed()
	var current_h := Vector3(velocity.x, 0.0, velocity.z)
	var new_h := current_h.move_toward(target_h, MELEE_ATTACK_MOVE_ACCEL * delta)
	velocity.x = new_h.x
	velocity.z = new_h.z

	_face_melee_camera_direction(delta)
	_attack_direction = _get_melee_flat_forward()
	_update_melee_attack_anim_time(delta)

	var anim_length := _get_melee_attack_length()
	var strike_fraction := _get_melee_attack_strike_fraction()
	var visual_fraction := _get_melee_attack_visual_fraction()
	if not _attack_recovery_to_idle:
		if _attack_reverse:
			var strike_seek := anim_length * (1.0 - strike_fraction)
			if not _attack_struck and _attack_reverse_seek >= strike_seek:
				_apply_melee_strike()
		else:
			if _attack_spin:
				var visual_time := anim_length * visual_fraction
				if not _attack_spin_visual_applied and _attack_anim_time >= visual_time:
					_apply_spin_attack_visual()
				var strike_time := anim_length * strike_fraction
				if not _attack_struck and _attack_anim_time >= strike_time:
					_apply_melee_strike()
			else:
				var strike_time := anim_length * strike_fraction
				if not _attack_struck and _attack_anim_time >= strike_time:
					_apply_melee_strike()

	move_with_ground_snap()
	_update_locomotion_blend(delta, new_h.length(), WALK_SPEED, RUN_SPEED, move_dir)
	_camera_pivot.rotation.y = _camera_yaw
	_camera_arm.rotation.x = _camera_pitch
	_update_interact_hint()

	if _attack_timer <= 0.0:
		_finish_melee_attack()


func _apply_spin_attack_visual() -> void:
	_attack_spin_visual_applied = true
	SwordCrescentFXScript.spawn_spin_preview(self, _attack_direction, _get_melee_attack_range())


func _apply_melee_strike() -> void:
	_attack_struck = true
	var attack_range := _get_melee_attack_range()
	if _attack_spin:
		MeleeSwordSlashScript.apply_spin_strike(self, _attack_direction)
	else:
		var strike_target: Node = _lock_on_target if _is_lock_on_facing_ready() else null
		if strike_target == null:
			strike_target = MeleeSwordSlashScript.find_strike_target(self, _attack_direction)
		MeleeSwordSlashScript.apply_strike(self, _attack_direction, strike_target)
		SwordCrescentFXScript.spawn_preview(self, _attack_direction, attack_range)


func _finish_melee_attack() -> void:
	if _attack_recovery_to_idle:
		_complete_melee_attack()
		return
	if not _begin_melee_attack_return_to_idle():
		_complete_melee_attack()


func _begin_melee_attack_return_to_idle() -> bool:
	_cancel_melee_attack_seek_tween()
	var anim_length := _get_melee_attack_length()
	var playback_speed := _get_melee_attack_playback_speed()
	var seek_start := 0.0
	if _attack_reverse:
		seek_start = clampf(_attack_reverse_seek, 0.0, anim_length)
	if seek_start >= anim_length - 0.03:
		return false

	_attack_recovery_to_idle = true
	_attack_reverse = true
	var duration := maxf((anim_length - seek_start) / playback_speed, 0.001)
	_attack_timer = duration
	var reverse_anim := _get_active_attack_reverse_anim_name()
	if _melee_attack_anim_node != null and _animation_player.has_animation(reverse_anim):
		_melee_attack_anim_node.animation = reverse_anim
	_tween_melee_attack_reverse_seek(seek_start, anim_length, duration)
	return true


func _complete_melee_attack() -> void:
	_cancel_melee_attack_seek_tween()
	_combat_attacking = false
	_attack_struck = false
	_attack_reverse = false
	_attack_spin = false
	_attack_spin_visual_applied = false
	_attack_spin_chained = false
	_attack_combo_used = false
	_attack_recovery_to_idle = false
	_attack_anim_time = 0.0
	_attack_reverse_seek = 0.0
	if _melee_attack_anim_node != null:
		_melee_attack_anim_node.animation = _attack_anim_name
	_sync_melee_attack_seek(-1.0)
	if _animation_tree != null and _animation_tree.active and _melee_combat_nodes_ready:
		_set_melee_attack_playback_speed(1.0)
		_restore_combat_idle_after_attack()
		_animation_tree.set(
			"parameters/%s/request" % GroyperMeleeAnimConfig.ATTACK_ONE_SHOT,
			AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT
		)
	_sync_locomotion_after_melee_attack()


func _restore_combat_idle_after_attack() -> void:
	pass


func _sync_locomotion_after_melee_attack() -> void:
	if _animation_tree == null or not _animation_tree.active:
		return
	var move_dir := _get_camera_relative_input()
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var in_gun_aim_stance := _is_in_gun_aim_stance()
	var wants_sprint := Input.is_key_pressed(KEY_SHIFT) and not in_gun_aim_stance
	var sprinting := wants_sprint and move_dir.length_squared() > 0.0001
	var walk_speed := AIM_WALK_SPEED if in_gun_aim_stance else WALK_SPEED
	var run_speed := AIM_RUN_SPEED if in_gun_aim_stance else RUN_SPEED
	var speed := horizontal_speed
	if speed <= MELEE_COMBAT_IDLE_STOP_SPEED and move_dir.length_squared() > 0.0001:
		speed = run_speed if sprinting else walk_speed
	var targets := _compute_locomotion_blend_targets(speed, walk_speed, run_speed, move_dir)
	_set_locomotion_tree_blends(targets.x, targets.y)


func _sync_melee_attack_seek(time: float) -> void:
	if not _melee_combat_nodes_ready or _animation_tree == null or not _animation_tree.active:
		return
	_animation_tree.set(
		"parameters/%s/seek_request" % GroyperMeleeAnimConfig.ATTACK_TIME_SEEK,
		time
	)
	if time >= 0.0:
		_attack_reverse_seek = time


func _cancel_melee_attack_seek_tween() -> void:
	if _attack_seek_tween != null and _attack_seek_tween.is_valid():
		_attack_seek_tween.kill()
	_attack_seek_tween = null


func _tween_melee_attack_reverse_seek(from_time: float, to_time: float, duration: float) -> void:
	_cancel_melee_attack_seek_tween()
	_sync_melee_attack_seek(from_time)
	if duration <= 0.0 or is_equal_approx(from_time, to_time):
		_sync_melee_attack_seek(to_time)
		return
	_attack_seek_tween = create_tween()
	_attack_seek_tween.set_trans(Tween.TRANS_CUBIC)
	_attack_seek_tween.set_ease(Tween.EASE_IN_OUT)
	_attack_seek_tween.tween_method(_sync_melee_attack_seek, from_time, to_time, duration)


func _process_melee_blocking(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = minf(velocity.y, 0.0)

	if is_melee_stunned():
		if _melee_block_facing_lock_timer > 0.0:
			_melee_block_facing_lock_timer = maxf(_melee_block_facing_lock_timer - delta, 0.0)
			_model.rotation.y = _melee_facing_yaw_locked
		else:
			_face_melee_camera_direction(delta)
		move_with_ground_snap()
		var stunned_h := Vector3(velocity.x, 0.0, velocity.z)
		_update_melee_block_hold_for_locomotion(delta)
		_update_locomotion_blend(
			delta,
			stunned_h.length(),
			MELEE_BLOCK_WALK_SPEED,
			MELEE_BLOCK_WALK_SPEED
		)
		_camera_pivot.rotation.y = _camera_yaw
		_camera_arm.rotation.x = _camera_pitch
		_update_interact_hint()
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			_end_melee_blocking()
		return

	_face_melee_camera_direction(delta)
	var move_dir := _get_camera_relative_input()
	var anim_move_dir := _get_block_locomotion_anim_direction(move_dir)
	var target_h := Vector3.ZERO
	if move_dir.length_squared() > 0.0001:
		target_h = move_dir.normalized() * MELEE_BLOCK_WALK_SPEED
	var current_h := Vector3(velocity.x, 0.0, velocity.z)
	var move_rate := MOVE_ACCEL if target_h.length_squared() > 0.0001 else MOVE_STOP_DECEL
	var new_h := current_h.move_toward(target_h, move_rate * delta)
	velocity.x = new_h.x
	velocity.z = new_h.z
	move_with_ground_snap()
	_update_melee_block_hold_for_locomotion(delta)
	_update_locomotion_blend(
		delta,
		new_h.length(),
		MELEE_BLOCK_WALK_SPEED,
		MELEE_BLOCK_WALK_SPEED,
		anim_move_dir
	)
	_camera_pivot.rotation.y = _camera_yaw
	_camera_arm.rotation.x = _camera_pitch
	_update_interact_hint()

	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_end_melee_blocking()


func _get_melee_attack_length() -> float:
	var anim_name := _get_active_attack_anim_name()
	if _animation_player == null or anim_name.is_empty():
		return 0.8
	if _animation_player.has_animation(anim_name):
		return _animation_player.get_animation(anim_name).length
	return 0.8


func _get_block_locomotion_anim_direction(input_dir: Vector3) -> Vector3:
	if input_dir.length_squared() > 0.0001:
		return input_dir
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	if horizontal.length_squared() > MELEE_COMBAT_IDLE_STOP_SPEED * MELEE_COMBAT_IDLE_STOP_SPEED:
		return horizontal.normalized()
	return Vector3.ZERO


func _get_melee_flat_forward() -> Vector3:
	var lock_facing := _get_lock_on_facing_dir()
	if lock_facing.length_squared() > 0.0001:
		return lock_facing

	var forward := -_camera_pivot.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		forward = _get_camera_horizontal_forward()
	if forward.length_squared() < 0.0001:
		return Vector3.FORWARD
	return forward.normalized()


func _face_melee_camera_direction(delta: float) -> void:
	if _face_lock_on_target(delta):
		return

	var cam_forward := _get_melee_flat_forward()
	if cam_forward.length_squared() < 0.0001:
		return
	var target_yaw := atan2(cam_forward.x, cam_forward.z)
	var turn := clampf(FACING_SPEED * delta, 0.0, 1.0)
	_model.rotation.y = lerp_angle(_model.rotation.y, target_yaw, turn)


func _can_block_melee_hit(hit_info: Dictionary) -> bool:
	return (
		_can_use_sword_shield_melee()
		and _combat_blocking
		and bool(hit_info.get("melee", false))
		and _is_facing_melee_attack(hit_info)
	)


func _is_facing_melee_attack(hit_info: Dictionary) -> bool:
	var attacker: Node = hit_info.get("shooter")
	if attacker is Node3D:
		var to_attacker := (attacker as Node3D).global_position - global_position
		to_attacker.y = 0.0
		if to_attacker.length_squared() > 0.0001:
			return _get_melee_flat_forward().dot(to_attacker.normalized()) >= MELEE_BLOCK_FACING_DOT_MIN

	var attack_dir: Vector3 = hit_info.get("direction", Vector3.FORWARD)
	attack_dir.y = 0.0
	if attack_dir.length_squared() < 0.0001:
		attack_dir = _get_melee_flat_forward()
	return _get_melee_flat_forward().dot(attack_dir.normalized()) <= -MELEE_BLOCK_FACING_DOT_MIN


func _on_melee_attack_blocked(hit_info: Dictionary) -> void:
	var attacker: Node = hit_info.get("shooter")
	_melee_facing_yaw_locked = _model.rotation.y
	var stun_duration := MeleeClashScript.resolve(self, attacker, hit_info)
	_melee_block_facing_lock_timer = stun_duration
	_fire_block_parry_one_shot()


func _on_melee_shield_block_broken(_hit_info: Dictionary) -> void:
	_combat_blocking = false
	_block_walk_amount = 0.0
	_apply_block_walk_locomotion_blend()
	_prepare_block_parry_visual()
	apply_melee_stun(0.85)
	CombatHitFlashScript.flash_damage(self)
	if _melee_combat_nodes_ready and not _shield_block_break_path.is_empty():
		_animation_tree.set(
			"parameters/%s/request" % GroyperMeleeAnimConfig.BLOCK_BREAK_ONE_SHOT,
			AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
		)


func _can_begin_shield_reflect() -> bool:
	return (
		_can_use_sword_shield_melee()
		and _combat_blocking
		and not _reflect_active
		and not _combat_attacking
		and not is_melee_stunned()
		and not _hit_reaction_active
		and not _punch_active
		and not _roll_active
		and _reflect_cooldown <= 0.0
	)


func _try_begin_shield_reflect() -> void:
	if not _can_begin_shield_reflect():
		return
	_begin_shield_reflect()


func _begin_shield_reflect() -> void:
	_reflect_active = true
	_reflect_elapsed = 0.0
	_reflect_window_remaining = ShieldReflectScript.WINDOW_DURATION
	_reflect_cooldown = ShieldReflectScript.COOLDOWN
	_melee_facing_yaw_locked = _model.rotation.y if _model != null else 0.0
	_combat_blocking = false
	_fire_block_parry_one_shot()


func _process_shield_reflect(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = minf(velocity.y, 0.0)
	velocity.x = 0.0
	velocity.z = 0.0
	_reflect_elapsed += delta
	_reflect_window_remaining = maxf(_reflect_window_remaining - delta, 0.0)
	_face_melee_camera_direction(delta)
	_melee_facing_yaw_locked = _model.rotation.y if _model != null else 0.0
	move_with_ground_snap()
	_prepare_block_parry_visual()
	_camera_pivot.rotation.y = _camera_yaw
	_camera_arm.rotation.x = _camera_pitch
	_update_interact_hint()
	if _reflect_elapsed >= ShieldReflectScript.TOTAL_DURATION:
		_finish_shield_reflect()


func _finish_shield_reflect() -> void:
	_reflect_active = false
	_reflect_elapsed = 0.0
	_reflect_window_remaining = 0.0
	_melee_block_facing_lock_timer = 0.0
	if (
		Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
		and _can_use_sword_shield_melee()
		and not _combat_attacking
	):
		_begin_melee_blocking()
	else:
		_end_melee_blocking()


func _can_reflect_hit(hit_info: Dictionary) -> bool:
	return (
		_reflect_active
		and _reflect_window_remaining > 0.0
		and ShieldReflectScript.is_facing_attack(self, hit_info)
	)


func _on_shield_reflect_success(hit_info: Dictionary) -> void:
	_melee_hit_absorbed = true
	_reflect_window_remaining = 0.0
	CombatHitFlashScript.flash_reflect(self)
	ShieldReflectScript.resolve_hit(self, hit_info)


func is_shield_reflect_active() -> bool:
	return _reflect_active


func was_melee_hit_absorbed() -> bool:
	return _melee_hit_absorbed


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


func _setup_bonfire_pose_library() -> void:
	if _animation_player == null:
		push_error("GroyperOverworldPlayer: missing AnimationPlayer on body.")
		return

	var library := AnimationLibrary.new()
	_add_bonfire_clip(library, BonfirePoseConfig.STAND_UP3, BonfirePoseConfig.STAND_UP3_SCENE, Animation.LOOP_NONE)
	_add_bonfire_clip(
		library,
		BonfirePoseConfig.SIT_CROSS_LEGGED,
		BonfirePoseConfig.SIT_CROSS_SCENE,
		Animation.LOOP_LINEAR
	)

	var stand_up := library.get_animation(BonfirePoseConfig.STAND_UP3)
	if stand_up != null:
		var reversed := RigAnimUtils.make_reversed_animation(stand_up)
		reversed.loop_mode = Animation.LOOP_NONE
		library.add_animation(BonfirePoseConfig.STAND_UP3_REVERSE, reversed)

	if _animation_player.has_animation_library(BonfirePoseConfig.LIBRARY_NAME):
		_animation_player.remove_animation_library(BonfirePoseConfig.LIBRARY_NAME)
	_animation_player.add_animation_library(BonfirePoseConfig.LIBRARY_NAME, library)


func _setup_hit_reaction_library() -> void:
	if _animation_player == null:
		push_error("GroyperOverworldPlayer: missing AnimationPlayer on body.")
		return

	var library := AnimationLibrary.new()
	_add_hit_reaction_clip(
		library,
		GroyperHitReactionConfig.CLIP_FALLING_DOWN,
		GroyperHitReactionConfig.FALLING_DOWN_SCENE,
		Animation.LOOP_NONE
	)

	if _animation_player.has_animation_library(GroyperHitReactionConfig.LIBRARY):
		_animation_player.remove_animation_library(GroyperHitReactionConfig.LIBRARY)
	_animation_player.add_animation_library(GroyperHitReactionConfig.LIBRARY, library)


func _add_hit_reaction_clip(
	library: AnimationLibrary,
	clip_name: StringName,
	scene_path: String,
	loop_mode: Animation.LoopMode
) -> void:
	var raw := RigAnimUtils.load_skeleton_animation(scene_path)
	if raw == null:
		push_error(
			"GroyperOverworldPlayer: failed to load hit reaction clip '%s' from %s."
			% [clip_name, scene_path]
		)
		return
	var animation := RigAnimUtils.prepare_for_body_player(raw, false)
	RigAnimUtils.strip_root_motion(animation)
	animation.loop_mode = loop_mode
	library.add_animation(clip_name, animation)


func _add_bonfire_clip(
	library: AnimationLibrary,
	clip_name: StringName,
	scene_path: String,
	loop_mode: Animation.LoopMode
) -> void:
	var raw := RigAnimUtils.load_skeleton_animation(scene_path)
	if raw == null:
		push_error(
			"GroyperOverworldPlayer: failed to load bonfire clip '%s' from %s."
			% [clip_name, scene_path]
		)
		return
	var animation := RigAnimUtils.prepare_for_body_player(raw, false)
	RigAnimUtils.strip_root_motion(animation)
	animation.loop_mode = loop_mode
	library.add_animation(clip_name, animation)


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
		if not cover.is_player_in_range(self) or not cover.is_player_touching(self):
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
	_push_intent = target_h
	velocity.x = new_h.x
	velocity.z = new_h.z
	_move_and_slide_debug()

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
	var targets := _compute_locomotion_blend_targets(
		ctx.target_speed,
		ctx.walk_speed,
		ctx.run_speed,
		ctx.move_dir
	)
	var blend_speed := BLEND_SPEED
	if move_progress >= 0.35:
		blend_speed *= VAULT_LOCOMOTION_BLEND_BOOST
	_lerp_locomotion_tree_blends(targets, blend_speed * delta, delta)


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

	_move_and_slide_debug()
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

	_move_and_slide_debug()
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
	var base_speed := RUN_SPEED if sprinting else WALK_SPEED

	_start_roll_dodge(move_dir, base_speed, sprinting)


func _start_roll_dodge(direction: Vector3, base_speed: float, sprinting: bool) -> void:
	var anim_path := StringName(
		"%s/%s" % [RollDodgeConfig.LIBRARY_NAME, RollDodgeConfig.WALK_ROLL]
	)
	if _animation_player == null or not _animation_player.has_animation(anim_path):
		push_error("GroyperOverworldPlayer: missing roll clip '%s'." % RollDodgeConfig.WALK_ROLL)
		return

	var animation := _animation_player.get_animation(anim_path)
	_roll_duration = animation.length
	_roll_timer = 0.0
	_roll_active = true
	_roll_exit_active = false
	_roll_exit_timer = 0.0
	_roll_exit_blend_duration = ROLL_EXIT_BLEND_DURATION
	_roll_direction = direction.normalized()
	_roll_speed = base_speed
	_roll_is_run = sprinting
	_roll_speed_multiplier = (
		RUN_ROLL_SPEED_MULTIPLIER if _roll_is_run else ROLL_SPEED_MULTIPLIER
	)
	var fraction_exit := _roll_duration * ROLL_CONTROL_RETURN_FRACTION
	var timed_exit := _roll_duration - ROLL_EXIT_BLEND_DURATION
	_roll_move_duration = minf(fraction_exit, timed_exit)
	_roll_move_duration = maxf(_roll_move_duration, ROLL_MIN_ACTIVE_TIME)

	var impulse_multiplier := (
		RUN_ROLL_INITIAL_IMPULSE_MULTIPLIER
		if _roll_is_run
		else ROLL_INITIAL_IMPULSE_MULTIPLIER
	)
	var boosted := Vector3(velocity.x, 0.0, velocity.z)
	if boosted.length_squared() < 0.0001:
		boosted = _roll_direction * base_speed
	else:
		boosted = boosted.normalized() * maxf(boosted.length(), base_speed)
	boosted *= impulse_multiplier
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
	if _roll_exit_active:
		_update_roll_exit(delta)
		return

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = minf(velocity.y, 0.0)

	var speed_multiplier := _compute_roll_speed_multiplier()
	velocity.x = _roll_direction.x * _roll_speed * speed_multiplier
	velocity.z = _roll_direction.z * _roll_speed * speed_multiplier
	_move_and_slide_debug()

	_roll_timer += delta
	_update_facing(delta, _roll_direction)
	_update_locomotion_blend(delta, 0.0, WALK_SPEED, RUN_SPEED)

	if _roll_timer >= _roll_move_duration:
		_begin_roll_exit()
	elif _roll_timer >= _roll_duration:
		_finish_roll_dodge()


func _compute_roll_speed_multiplier() -> float:
	var impulse_multiplier := (
		RUN_ROLL_INITIAL_IMPULSE_MULTIPLIER
		if _roll_is_run
		else ROLL_INITIAL_IMPULSE_MULTIPLIER
	)
	var cruise_multiplier := (
		RUN_ROLL_SPEED_MULTIPLIER if _roll_is_run else ROLL_SPEED_MULTIPLIER
	)
	if ROLL_IMPULSE_DECAY_TIME <= 0.001:
		return cruise_multiplier
	var decay_t := clampf(_roll_timer / ROLL_IMPULSE_DECAY_TIME, 0.0, 1.0)
	return lerpf(impulse_multiplier, cruise_multiplier, _smoothstep(decay_t))


func _begin_roll_exit() -> void:
	if _roll_exit_active:
		return
	_roll_exit_active = true
	_roll_exit_timer = 0.0
	_roll_exit_start_velocity = Vector3(velocity.x, 0.0, velocity.z)
	_roll_exit_start_yaw = _model.rotation.y if _model != null else 0.0
	_roll_exit_start_move_blend = _locomotion_move_blend
	_roll_exit_start_walk_blend = _locomotion_walk_blend
	var remaining_anim := maxf(_roll_duration - _roll_timer, 0.0)
	_roll_exit_blend_duration = maxf(
		remaining_anim + ROLL_ANIM_FADEOUT,
		ROLL_EXIT_BLEND_DURATION
	)


func _roll_exit_ease(t: float) -> float:
	var clamped := clampf(t, 0.0, 1.0)
	return clamped * clamped * (3.0 - 2.0 * clamped)


func _update_roll_exit(delta: float) -> void:
	_roll_exit_timer += delta
	_roll_timer += delta

	var progress := clampf(
		_roll_exit_timer / maxf(_roll_exit_blend_duration, 0.001),
		0.0,
		1.0
	)
	var eased := _roll_exit_ease(progress)

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = minf(velocity.y, 0.0)

	var ctx := _get_vault_move_context()
	var move_dir: Vector3 = ctx.get("move_dir", Vector3.ZERO)
	var walk_speed: float = float(ctx.get("walk_speed", WALK_SPEED))
	var run_speed: float = float(ctx.get("run_speed", RUN_SPEED))
	var target_h: Vector3 = (
		move_dir * float(ctx.get("target_speed", 0.0))
		if move_dir.length_squared() > 0.0001
		else Vector3.ZERO
	)
	var blended_h := _roll_exit_start_velocity.lerp(target_h, eased)
	_push_intent = target_h
	velocity.x = blended_h.x
	velocity.z = blended_h.z
	_move_and_slide_debug()

	var target_yaw := _roll_exit_start_yaw
	if move_dir.length_squared() > 0.0001:
		target_yaw = atan2(move_dir.x, move_dir.z)
	if _model != null:
		_model.rotation.y = lerp_angle(_roll_exit_start_yaw, target_yaw, eased)

	var locomotion_targets := _compute_locomotion_blend_targets(
		blended_h.length(),
		walk_speed,
		run_speed,
		move_dir
	)
	_locomotion_move_blend = lerpf(_roll_exit_start_move_blend, locomotion_targets.x, eased)
	_locomotion_walk_blend = lerpf(_roll_exit_start_walk_blend, locomotion_targets.y, eased)
	_apply_locomotion_tree_blends()

	if progress >= 1.0:
		_finish_roll_dodge()


func _finish_roll_dodge() -> void:
	_roll_active = false
	_roll_exit_active = false
	_roll_timer = 0.0
	_roll_exit_timer = 0.0
	_roll_duration = 0.0
	_roll_move_duration = 0.0
	_roll_direction = Vector3.ZERO
	_roll_speed = 0.0
	_roll_speed_multiplier = ROLL_SPEED_MULTIPLIER
	_roll_is_run = false
	_roll_exit_start_velocity = Vector3.ZERO
	_roll_exit_start_yaw = 0.0
	_roll_exit_start_move_blend = 0.0
	_roll_exit_start_walk_blend = WALK_DIR_WALK_BLEND
	_roll_exit_blend_duration = ROLL_EXIT_BLEND_DURATION
	if _animation_tree != null:
		_animation_tree.set(
			"parameters/%s/request" % ROLL_ONE_SHOT,
			AnimationNodeOneShot.ONE_SHOT_REQUEST_NONE
		)


func _can_punch() -> bool:
	return (
		not _overworld_defeated
		and not is_melee_stunned()
		and not _transition_locked
		and not _dialog_active
		and not DialogManager.is_showing()
		and not InventoryMenuManager.is_open()
		and not TownMapManager.is_open()
		and not ShopBuyManager.is_showing()
		and not BonfireMenuManager.is_showing()
		and not _punch_active
		and not _roll_active
		and not _vault_active
		and not _cover_crouch_active
		and not _cover_walk_enter_active
		and not _cover_exit_active
		and not _mount_transition_active
		and not _is_fully_mounted()
		and not _hit_reaction_active
		and not _reflect_active
		and _punch_cooldown <= 0.0
	)


func _try_punch() -> void:
	if _combat_blocking and _can_use_sword_shield_melee() and not _reflect_active:
		_try_begin_shield_reflect()
		return
	if _punch_active and PlayerInventory.has_knife and not _punch_strike_applied:
		_throw_knife()
		return
	if _punch_active and _can_queue_punch_combo():
		_punch_combo_buffered = false
		_begin_punch_combo_next()
		return
	if _punch_active and _can_buffer_punch_combo():
		_punch_combo_buffered = true
		return
	if not _can_punch():
		return
	_start_punch(MeleePunch.get_player_strike_direction(self))


func get_punch_facing_direction() -> Vector3:
	if _combat_attacking and _attack_direction.length_squared() > 0.0001:
		return _attack_direction
	var lock_facing := _get_lock_on_facing_dir()
	if lock_facing.length_squared() > 0.0001:
		return lock_facing
	if _combat_blocking or _can_use_sword_shield_melee():
		return _get_melee_flat_forward()
	if _weapon_rig != null and not _weapon_rig.is_holstered():
		return _get_aim_facing_direction()
	if _model != null:
		var forward := -_model.global_transform.basis.z
		forward.y = 0.0
		if forward.length_squared() > 0.0001:
			return forward.normalized()
	return _get_camera_relative_input()


func _start_punch(direction: Vector3) -> void:
	if direction.length_squared() < 0.0001:
		return

	var anim_path := PunchPoseConfig.get_animation_path()
	if _animation_player == null or not _animation_player.has_animation(anim_path):
		push_error("GroyperOverworldPlayer: missing punch clip.")
		return

	var animation := _animation_player.get_animation(anim_path)
	_punch_combo_step = MeleePunch.ComboStep.HOOK
	_punch_seek_base = 0.0
	_punch_combo_buffered = false
	_punch_duration = MeleePunch.get_attack_duration_for_step(_punch_combo_step, animation.length)
	_punch_timer = 0.0
	_punch_active = true
	_punch_strike_applied = false
	_punch_direction = direction.normalized()
	_punch_cooldown = MeleePunch.COOLDOWN
	_punch_blend = 0.0
	_punch_exit_active = false
	_punch_exit_timer = 0.0

	if _punch_anim_node != null:
		_punch_anim_node.animation = anim_path
	_init_punch_animation_tree_state()
	_sync_knife_hand_visual()


func _get_punch_anim_path_for_step(step: MeleePunch.ComboStep) -> StringName:
	if step == MeleePunch.ComboStep.HOOK:
		return PunchPoseConfig.get_animation_path()
	return PunchPoseConfig.get_elbow_strike_path()


func _get_punch_anim_length_for_step(step: MeleePunch.ComboStep) -> float:
	if _animation_player == null:
		return 0.0
	var anim_path := _get_punch_anim_path_for_step(step)
	if not _animation_player.has_animation(anim_path):
		return 0.0
	return _animation_player.get_animation(anim_path).length


func _get_punch_anim_time() -> float:
	return _punch_seek_base + MeleePunch.get_anim_time(_punch_timer)


func _can_queue_punch_combo() -> bool:
	if (
		_punch_exit_active
		or not _punch_strike_applied
		or PlayerInventory.has_knife
		or not MeleePunch.can_chain_combo(_punch_combo_step)
	):
		return false
	return MeleePunch.is_in_combo_input_window(_punch_combo_step, _get_punch_anim_time())


func _can_buffer_punch_combo() -> bool:
	if (
		_punch_exit_active
		or PlayerInventory.has_knife
		or not MeleePunch.can_chain_combo(_punch_combo_step)
	):
		return false
	return MeleePunch.can_accept_combo_buffer(_punch_combo_step, _get_punch_anim_time())


func _consume_buffered_punch_combo() -> void:
	if not _punch_combo_buffered or not _can_queue_punch_combo():
		return
	_punch_combo_buffered = false
	_begin_punch_combo_next()


func _begin_punch_combo_next() -> void:
	_punch_combo_step = MeleePunch.get_next_combo_step(_punch_combo_step)
	_punch_seek_base = MeleePunch.get_step_seek_base(_punch_combo_step)
	var anim_path := _get_punch_anim_path_for_step(_punch_combo_step)
	var anim_length := _get_punch_anim_length_for_step(_punch_combo_step)
	if anim_length <= 0.0:
		_begin_punch_exit()
		return

	_punch_duration = MeleePunch.get_attack_duration_for_step(_punch_combo_step, anim_length)
	_punch_timer = 0.0
	_punch_strike_applied = false
	_punch_exit_active = false
	_punch_exit_timer = 0.0
	_punch_combo_buffered = false
	_punch_blend = 1.0
	_punch_direction = MeleePunch.get_player_strike_direction(self)
	_set_punch_tree_blend(1.0)

	if _punch_anim_node != null:
		_punch_anim_node.animation = anim_path
	_sync_punch_anim_time(0.0)
	_sync_knife_hand_visual()


func _get_knife_throw_direction() -> Vector3:
	return _get_aim_direction()


func _get_knife_throw_speed(direction: Vector3) -> float:
	var upward := clampf(direction.y, 0.0, 1.0)
	return KNIFE_THROW_SPEED * lerpf(1.0, KNIFE_THROW_HIGH_AIM_BOOST, upward / 0.72)


func _throw_knife() -> void:
	if not PlayerInventory.has_knife:
		return

	var direction := _get_knife_throw_direction()
	if direction.length_squared() < 0.0001:
		direction = get_punch_facing_direction()
	if direction.length_squared() < 0.0001:
		return
	direction = direction.normalized()
	var throw_speed := _get_knife_throw_speed(direction)

	var origin := global_position + Vector3(0.0, 1.05, 0.0)
	if _knife_hand_visual != null and _knife_hand_visual.visible:
		origin = _knife_hand_visual.global_position
	elif _weapon_rig != null:
		origin = _weapon_rig.get_muzzle_global_position()

	PlayerInventory.set_has_knife(false)
	_sync_knife_hand_visual()
	_finish_punch()

	var scene_root := get_tree().current_scene
	if scene_root == null:
		return

	var exclude: Array = [self]
	var hitbox := get_node_or_null("Hitbox")
	if hitbox is CollisionObject3D:
		exclude.append(hitbox)

	var knife: Node3D = KNIFE_PROJECTILE_SCENE.instantiate()
	scene_root.add_child(knife)
	knife.setup(origin, direction, throw_speed, exclude, self)
	GameAudio.play_knife_throw_whoosh(scene_root, origin)


func _set_punch_tree_blend(amount: float) -> void:
	_punch_blend = amount
	PunchPoseConfig.set_tree_blend(_animation_tree, amount)


func _sync_punch_anim_time(time: float) -> void:
	PunchPoseConfig.set_tree_seek(
		_animation_tree,
		_punch_seek_base + MeleePunch.get_anim_time(time)
	)


func _update_punch_overlay(delta: float) -> void:
	if _punch_exit_active:
		_punch_exit_timer += delta
		var progress := clampf(
			_punch_exit_timer / maxf(MeleePunch.get_exit_blend_duration(), 0.001),
			0.0,
			1.0
		)
		var eased := 1.0 - pow(1.0 - progress, 2.6)
		_set_punch_tree_blend(lerpf(1.0, 0.0, eased))
		_sync_punch_anim_time(_punch_timer)
		_sync_knife_hand_visual()
		if progress >= 1.0:
			_finish_punch()
		return

	_punch_timer += delta
	var fade_progress := clampf(
		_punch_timer / maxf(MeleePunch.get_anim_fadein(), 0.001),
		0.0,
		1.0
	)
	var blend_target := fade_progress * fade_progress * (3.0 - 2.0 * fade_progress)
	var blend_step := 1.0 - exp(-PUNCH_BLEND_IN_SPEED * delta)
	_set_punch_tree_blend(lerpf(_punch_blend, blend_target, blend_step))
	_sync_punch_anim_time(_punch_timer)
	_sync_knife_hand_visual()
	_consume_buffered_punch_combo()

	if _punch_timer >= _punch_duration:
		_begin_punch_exit()


func _apply_punch_strike_if_ready() -> void:
	if not _punch_active or _punch_exit_active or _punch_strike_applied:
		return
	if _punch_timer < MeleePunch.get_strike_real_duration(_punch_combo_step):
		return

	var nearest := MeleePunch.find_nearest_strike_target(self)
	if nearest != null:
		_punch_direction = MeleePunch.get_strike_direction(self, nearest)

	_punch_strike_applied = true
	var struck := MeleePunch.apply_strike(self, _punch_direction, nearest)
	if struck:
		_trigger_melee_impact_camera()
		velocity.x += _punch_direction.x * MeleePunch.PLAYER_HIT_LUNGE_SPEED
		velocity.z += _punch_direction.z * MeleePunch.PLAYER_HIT_LUNGE_SPEED
		velocity.x -= _punch_direction.x * MeleePunch.PLAYER_HIT_BOUNCE_SPEED
		velocity.z -= _punch_direction.z * MeleePunch.PLAYER_HIT_BOUNCE_SPEED
	else:
		var lunge_speed := MeleePunch.get_lunge_speed_for_attacker(self)
		velocity.x += _punch_direction.x * lunge_speed
		velocity.z += _punch_direction.z * lunge_speed

	_consume_buffered_punch_combo()


func _begin_punch_exit() -> void:
	if _punch_exit_active:
		return

	_punch_exit_active = true
	_punch_exit_timer = 0.0
	_sync_knife_hand_visual()
	_begin_melee_camera_release()


func _finish_punch() -> void:
	_punch_active = false
	_punch_exit_active = false
	_punch_timer = 0.0
	_punch_exit_timer = 0.0
	_punch_duration = 0.0
	_punch_direction = Vector3.ZERO
	_punch_strike_applied = false
	_punch_combo_step = MeleePunch.ComboStep.HOOK
	_punch_seek_base = 0.0
	_punch_combo_buffered = false
	_init_punch_animation_tree_state()
	_sync_knife_hand_visual()


func apply_camera_shake(strength: float) -> void:
	_camera_shake_strength = maxf(_camera_shake_strength, strength)


func _sample_camera_shake(delta: float) -> Vector3:
	if _camera_shake_strength <= 0.001:
		_camera_shake_strength = 0.0
		return Vector3.ZERO

	_camera_shake_strength = maxf(0.0, _camera_shake_strength - delta * 5.5)
	return Vector3(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0),
		randf_range(-0.35, 0.35)
	) * _camera_shake_strength * 0.11


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
	if _face_lock_on_target(delta):
		return

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


func _is_lock_on_engaged() -> bool:
	return _lock_on_active and is_instance_valid(_lock_on_target)


func _is_lock_on_facing_ready() -> bool:
	return _is_lock_on_engaged() and _lock_on_blend > 0.25


func _can_use_lock_on() -> bool:
	return (
		not _overworld_defeated
		and not _transition_locked
		and not _dialog_active
		and not DialogManager.is_showing()
		and not InventoryMenuManager.is_open()
		and not TownMapManager.is_open()
		and not ShopBuyManager.is_showing()
		and not BonfireMenuManager.is_showing()
		and not _is_fully_mounted()
		and not _is_scope_aim_active()
		and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)


func _try_toggle_lock_on() -> void:
	if not _can_use_lock_on():
		return
	if _lock_on_active:
		_clear_lock_on()
		return

	var look_forward := _get_camera_horizontal_forward()
	if look_forward.length_squared() < 0.0001:
		return
	var target := CombatLockOnScript.find_best_target(self, look_forward)
	if target == null:
		return

	_lock_on_active = true
	_lock_on_target = target
	_lock_on_orbit_yaw = 0.0
	if _lock_on_indicator != null:
		_lock_on_indicator.set_target(target)


func _clear_lock_on() -> void:
	_lock_on_active = false
	_lock_on_target = null
	_lock_on_orbit_yaw = 0.0
	if _lock_on_indicator != null:
		_lock_on_indicator.clear()


func _update_lock_on(delta: float) -> void:
	if _is_scope_aim_active() and _lock_on_active:
		_clear_lock_on()

	_lock_on_blend = CombatLockOnScript.advance_blend(_lock_on_blend, _lock_on_active, delta)
	if _lock_on_blend <= 0.001 and not _lock_on_active:
		return

	if _lock_on_active:
		if not CombatLockOnScript.is_valid_target(self, _lock_on_target):
			_clear_lock_on()
			return

		var aim_point := CombatLockOnScript.get_aim_point(_lock_on_target)
		var focus := CombatLockOnScript.compute_focus_angles(
			_camera_pivot.global_position,
			aim_point,
			_lock_on_orbit_yaw
		)
		var tracked := CombatLockOnScript.track_camera_angles(
			_camera_yaw,
			_camera_pitch,
			focus.x,
			focus.y,
			delta
		)
		_camera_yaw = tracked.x
		_camera_pitch = tracked.y


func _apply_lock_on_mouse_look(relative: Vector2) -> void:
	_lock_on_orbit_yaw = clampf(
		_lock_on_orbit_yaw - relative.x * MOUSE_SENSITIVITY,
		-CombatLockOnScript.MAX_ORBIT_YAW,
		CombatLockOnScript.MAX_ORBIT_YAW
	)
	var pitch_step := relative.y * MOUSE_SENSITIVITY * 0.35
	_camera_pitch = clampf(
		_camera_pitch - pitch_step,
		CombatLockOnScript.LOCK_PITCH_MIN,
		CombatLockOnScript.LOCK_PITCH_MAX
	)


func _get_lock_on_facing_dir() -> Vector3:
	if not _is_lock_on_facing_ready():
		return Vector3.ZERO
	return CombatLockOnScript.get_flat_facing(self, _lock_on_target)


func _face_lock_on_target(delta: float, turn_speed: float = FACING_SPEED) -> bool:
	if not _is_lock_on_facing_ready():
		return false
	var facing := CombatLockOnScript.get_flat_facing(self, _lock_on_target)
	if facing.length_squared() < 0.0001:
		return false
	var target_yaw := atan2(facing.x, facing.z)
	var turn := clampf(turn_speed * delta * _lock_on_blend, 0.0, 1.0)
	_model.rotation.y = lerp_angle(_model.rotation.y, target_yaw, turn)
	return true


func _get_aim_facing_direction() -> Vector3:
	var lock_facing := _get_lock_on_facing_dir()
	if lock_facing.length_squared() > 0.0001:
		return lock_facing

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


func _get_move_backwardness(move_dir: Vector3) -> float:
	if move_dir.length_squared() <= 0.0001:
		return 0.0

	if _combat_blocking and GroyperWeapons.is_sword_shield(_equipped_weapon):
		var melee_facing := _get_melee_flat_forward()
		if melee_facing.length_squared() <= 0.0001:
			return 0.0
		return maxf(-move_dir.normalized().dot(melee_facing.normalized()), 0.0)

	return _get_aim_backwardness(move_dir)


func _get_locomotion_walk_direction_blend(move_dir: Vector3) -> float:
	if move_dir.length_squared() <= 0.0001:
		return WALK_DIR_WALK_BLEND

	var backwardness := _get_move_backwardness(move_dir)
	if backwardness <= AIM_WALK_REVERSE_DOT_THRESHOLD:
		return WALK_DIR_WALK_BLEND

	var back_t := clampf(
		(backwardness - AIM_WALK_REVERSE_DOT_THRESHOLD)
		/ maxf(1.0 - AIM_WALK_REVERSE_DOT_THRESHOLD, 0.001),
		0.0,
		1.0
	)
	return lerpf(WALK_DIR_WALK_BLEND, WALK_DIR_BACK_BLEND, back_t)


func _compute_locomotion_blend_targets(
	speed: float,
	walk_speed: float,
	run_speed: float,
	move_dir: Vector3 = Vector3.ZERO
) -> Vector2:
	if speed <= 0.05:
		return Vector2(0.0, WALK_DIR_WALK_BLEND)

	if speed <= walk_speed:
		var move_amount := clampf(speed / maxf(walk_speed, 0.001), 0.0, 1.0)
		return Vector2(move_amount, _get_locomotion_walk_direction_blend(move_dir))

	var run_t := (speed - walk_speed) / maxf(run_speed - walk_speed, 0.001)
	var run_walk := lerpf(
		WALK_DIR_WALK_BLEND,
		WALK_DIR_RUN_BLEND,
		clampf(run_t, 0.0, 1.0)
	)
	return Vector2(1.0, run_walk)


func _get_locomotion_blend_speed() -> float:
	if _uses_block_locomotion_visual():
		return BLOCK_LOCOMOTION_BLEND_SPEED
	return BLEND_SPEED


func _apply_locomotion_tree_blends() -> void:
	if _animation_tree == null:
		return
	_animation_tree.set(
		"parameters/%s/blend_amount" % LOCOMOTION_BLEND,
		_locomotion_move_blend
	)
	_animation_tree.set(
		"parameters/%s/blend_position" % WALK_LOCOMOTION_BLEND,
		_locomotion_walk_blend
	)
	if _melee_block_walk_nodes_ready:
		_animation_tree.set(
			"parameters/%s/blend_position" % GroyperMeleeAnimConfig.BLOCK_WALK_LOCOMOTION_SPACE,
			_locomotion_walk_blend
		)


func _set_locomotion_tree_blends(move_blend: float, walk_blend: float) -> void:
	_locomotion_move_blend = move_blend
	_locomotion_walk_blend = walk_blend
	_apply_locomotion_tree_blends()


func _reset_locomotion_tree_blends() -> void:
	_set_locomotion_tree_blends(0.0, WALK_DIR_WALK_BLEND)


func _lerp_locomotion_tree_blends(
	targets: Vector2,
	step: float,
	delta: float = -1.0
) -> void:
	var move_step := step
	if delta > 0.0 and _uses_melee_combat_locomotion_blend():
		var blend_time := (
			COMBAT_IDLE_BLEND_IN_TIME
			if targets.x < _locomotion_move_blend
			else COMBAT_IDLE_BLEND_OUT_TIME
		)
		move_step = _block_hold_blend_step(delta, blend_time)
	if _should_pin_block_walk_layer():
		_locomotion_move_blend = maxf(_locomotion_move_blend, targets.x)
	else:
		_locomotion_move_blend = lerpf(_locomotion_move_blend, targets.x, move_step)
	_locomotion_walk_blend = lerpf(_locomotion_walk_blend, targets.y, step)
	_apply_locomotion_tree_blends()


func _should_pin_block_walk_layer() -> bool:
	return _combat_blocking and _block_walk_amount > 0.001


func _apply_block_locomotion_sync(
	targets: Vector2,
	_speed: float,
	_walk_speed: float,
	move_dir: Vector3
) -> Vector2:
	if _combat_blocking and not _reflect_active:
		if _block_walk_amount <= 0.001:
			return targets
		targets.x = maxf(targets.x, _block_walk_amount)
		if move_dir.length_squared() > 0.0001:
			targets.y = _get_locomotion_walk_direction_blend(move_dir)
		elif _block_walk_amount < 0.999:
			targets.y = _locomotion_walk_blend
	return targets


func _update_locomotion_blend(
	delta: float,
	speed: float,
	walk_speed: float,
	run_speed: float,
	move_dir: Vector3 = Vector3.ZERO
) -> void:
	var targets := _compute_locomotion_blend_targets(speed, walk_speed, run_speed, move_dir)
	targets = _apply_block_locomotion_sync(targets, speed, walk_speed, move_dir)
	_lerp_locomotion_tree_blends(targets, _get_locomotion_blend_speed() * delta, delta)


func register_interactable(interactable: Node) -> void:
	if interactable == null:
		return
	_nearby_interactables[interactable.get_instance_id()] = interactable


func unregister_interactable(interactable: Node) -> void:
	if interactable == null:
		return
	_nearby_interactables.erase(interactable.get_instance_id())


func is_inventory_menu_blocked() -> bool:
	return _transition_locked or _dialog_active or DialogManager.is_showing() \
			or BonfireMenuManager.is_showing()


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


func begin_bonfire_interaction(bonfire: Node3D) -> void:
	set_transition_locked(true)
	_bonfire_interact_target = bonfire
	_bonfire_movement_unlocked = false
	if _weapon_rig != null and not _weapon_rig.is_holstered():
		_weapon_rig.reset_to_holster()
		_reset_reload_input()
		_update_combat_ui()
	if bonfire != null:
		var to_bonfire := bonfire.global_position - global_position
		to_bonfire.y = 0.0
		if to_bonfire.length_squared() > 0.0001:
			_model.rotation.y = atan2(to_bonfire.x, to_bonfire.z)
	_start_bonfire_sit_down()


func begin_bonfire_cinematic_camera(bonfire: Node3D) -> void:
	if bonfire != null:
		_bonfire_interact_target = bonfire
	_bonfire_camera_target_blend = 1.0


func begin_bonfire_cinematic_camera_exit() -> void:
	_bonfire_camera_target_blend = 0.0


func end_bonfire_interaction() -> void:
	if _is_bonfire_pose_active():
		_request_bonfire_stand_up()
	else:
		set_transition_locked(false)


func _is_bonfire_pose_active() -> bool:
	return _bonfire_anim_phase != BonfireAnimPhase.NONE


func _get_bonfire_stand_duration(anim_path: StringName) -> float:
	if _animation_player == null:
		return 1.5
	var animation := _animation_player.get_animation(anim_path)
	if animation == null:
		return 1.5
	return maxf(animation.length, 0.001)


func _start_bonfire_sit_down() -> void:
	if _bonfire_stand_anim_node == null or _animation_tree == null:
		return
	if _bonfire_anim_phase != BonfireAnimPhase.NONE:
		return

	_reset_locomotion_tree_blends()
	_bonfire_stand_anim_node.animation = BonfirePoseConfig.get_stand_up3_reverse_path()
	_bonfire_stand_duration = _get_bonfire_stand_duration(_bonfire_stand_anim_node.animation)
	_bonfire_timer = 0.0
	_bonfire_pose_timer = 0.0
	_bonfire_blend = 0.0
	_bonfire_pose_blend = 0.0
	_bonfire_stand_up_pending = false
	_bonfire_movement_unlocked = false
	_bonfire_anim_phase = BonfireAnimPhase.SITTING_DOWN
	_apply_bonfire_tree_blends()
	BonfirePoseConfig.set_stand_seek(_animation_tree, 0.0)


func _request_bonfire_stand_up() -> void:
	match _bonfire_anim_phase:
		BonfireAnimPhase.SITTING:
			_start_bonfire_stand_up()
		BonfireAnimPhase.SITTING_DOWN:
			_bonfire_stand_up_pending = true
		BonfireAnimPhase.STANDING_UP:
			pass
		_:
			set_transition_locked(false)


func _start_bonfire_stand_up() -> void:
	if _bonfire_stand_anim_node == null or _animation_tree == null:
		_finish_bonfire_interaction()
		return

	_bonfire_stand_anim_node.animation = BonfirePoseConfig.get_stand_up3_path()
	_bonfire_stand_duration = _get_bonfire_stand_duration(_bonfire_stand_anim_node.animation)
	_bonfire_timer = 0.0
	_bonfire_pose_timer = 0.0
	_bonfire_pose_blend = 0.0
	_bonfire_stand_up_pending = false
	_bonfire_movement_unlocked = false
	_bonfire_anim_phase = BonfireAnimPhase.STANDING_UP
	_apply_bonfire_tree_blends()
	BonfirePoseConfig.set_stand_seek(_animation_tree, 0.0)


func _apply_bonfire_tree_blends() -> void:
	BonfirePoseConfig.set_bonfire_blend(_animation_tree, _bonfire_blend)
	BonfirePoseConfig.set_pose_blend(_animation_tree, _bonfire_pose_blend)


func _sync_bonfire_stand_seek(time: float) -> void:
	BonfirePoseConfig.set_stand_seek(_animation_tree, clampf(time, 0.0, _bonfire_stand_duration))


func _update_bonfire_pose(delta: float) -> void:
	if _animation_tree == null:
		return

	match _bonfire_anim_phase:
		BonfireAnimPhase.SITTING_DOWN:
			_update_bonfire_sit_down(delta)
		BonfireAnimPhase.SITTING:
			_update_bonfire_sitting(delta)
		BonfireAnimPhase.STANDING_UP:
			_update_bonfire_stand_up(delta)


func _update_bonfire_sit_down(delta: float) -> void:
	_bonfire_timer += delta
	var blend_t := clampf(
		_bonfire_timer / maxf(BonfirePoseConfig.BLEND_IN_DURATION, 0.001),
		0.0,
		1.0
	)
	var blend_target := blend_t * blend_t * (3.0 - 2.0 * blend_t)
	var blend_step := 1.0 - exp(-BONFIRE_BLEND_IN_SPEED * delta)
	_bonfire_blend = lerpf(_bonfire_blend, blend_target, blend_step)
	_sync_bonfire_stand_seek(_bonfire_timer)
	_apply_bonfire_tree_blends()

	if _bonfire_timer >= _bonfire_stand_duration:
		_finish_bonfire_sit_down()


func _finish_bonfire_sit_down() -> void:
	_bonfire_blend = 1.0
	_bonfire_pose_timer = 0.0
	_bonfire_pose_blend = 0.0
	_bonfire_anim_phase = BonfireAnimPhase.SITTING
	_apply_bonfire_tree_blends()
	if _bonfire_stand_up_pending:
		_start_bonfire_stand_up()


func _update_bonfire_sitting(delta: float) -> void:
	_bonfire_blend = 1.0
	_bonfire_pose_timer += delta
	var pose_t := clampf(
		_bonfire_pose_timer / maxf(BonfirePoseConfig.POSE_BLEND_DURATION, 0.001),
		0.0,
		1.0
	)
	var pose_target := pose_t * pose_t * (3.0 - 2.0 * pose_t)
	var pose_step := 1.0 - exp(-BONFIRE_POSE_BLEND_SPEED * delta)
	_bonfire_pose_blend = lerpf(_bonfire_pose_blend, pose_target, pose_step)
	_apply_bonfire_tree_blends()


func _update_bonfire_stand_up(delta: float) -> void:
	_bonfire_timer += delta * BonfirePoseConfig.STAND_UP_SPEED
	var progress := clampf(_bonfire_timer / maxf(_bonfire_stand_duration, 0.001), 0.0, 1.0)
	_bonfire_pose_blend = 0.0
	_sync_bonfire_stand_seek(_bonfire_timer)

	if progress >= BonfirePoseConfig.STAND_UP_MOVE_UNLOCK_FRACTION and not _bonfire_movement_unlocked:
		_bonfire_movement_unlocked = true
		set_transition_locked(false)

	if progress >= BonfirePoseConfig.STAND_UP_BLEND_OUT_START:
		var out_t := clampf(
			(progress - BonfirePoseConfig.STAND_UP_BLEND_OUT_START)
			/ maxf(1.0 - BonfirePoseConfig.STAND_UP_BLEND_OUT_START, 0.001),
			0.0,
			1.0
		)
		var eased := out_t * out_t * (3.0 - 2.0 * out_t)
		_bonfire_blend = lerpf(1.0, 0.0, eased)
	else:
		_bonfire_blend = 1.0

	_apply_bonfire_tree_blends()

	if progress >= 1.0:
		_finish_bonfire_interaction()


func _apply_bonfire_cinematic_camera(delta: float) -> void:
	if _camera == null:
		return

	var step := 1.0 - exp(-BonfirePoseConfig.CAMERA_BLEND_SPEED * delta)
	_bonfire_camera_blend = lerpf(_bonfire_camera_blend, _bonfire_camera_target_blend, step)
	if _bonfire_camera_blend <= 0.001:
		return
	if _bonfire_interact_target == null or not is_instance_valid(_bonfire_interact_target):
		return

	var base_pos := _camera.position
	var base_fov := _camera.fov
	var base_yaw := _camera_yaw
	var base_pitch := _camera_pitch
	var shot := _compute_bonfire_cinematic_shot()
	var eased := _bonfire_camera_blend * _bonfire_camera_blend * (3.0 - 2.0 * _bonfire_camera_blend)
	_camera_yaw = lerpf(base_yaw, shot.yaw, eased)
	_camera_pitch = lerpf(base_pitch, shot.pitch, eased)
	_camera_pivot.rotation.y = _camera_yaw
	_camera_arm.rotation.x = _camera_pitch
	_camera.position = base_pos.lerp(shot.offset, eased)
	_camera.fov = lerpf(base_fov, shot.fov, eased)
	_aim_fov_current = _camera.fov


func _compute_bonfire_cinematic_shot() -> Dictionary:
	var bonfire_pos := _bonfire_interact_target.global_position
	var player_pos := global_position
	var focus := (player_pos + bonfire_pos) * 0.5
	focus.y += BonfirePoseConfig.CINEMATIC_FOCUS_HEIGHT

	var pair_dir := bonfire_pos - player_pos
	pair_dir.y = 0.0
	if pair_dir.length_squared() < 0.0001:
		pair_dir = -_model.global_transform.basis.z
	pair_dir = pair_dir.normalized()

	var pivot_pos := _camera_pivot.global_position
	var to_focus := focus - pivot_pos
	var target_yaw := atan2(to_focus.x, to_focus.z)
	var horiz := Vector2(to_focus.x, to_focus.z).length()
	var target_pitch := clampf(
		-atan2(to_focus.y, maxf(horiz, 0.001)),
		CAMERA_PITCH_MIN,
		CAMERA_PITCH_MAX
	)

	return {
		"yaw": target_yaw,
		"pitch": target_pitch,
		"offset": Vector3(
			BonfirePoseConfig.CINEMATIC_CAMERA_SIDE,
			BonfirePoseConfig.CINEMATIC_CAMERA_HEIGHT,
			BonfirePoseConfig.CINEMATIC_CAMERA_DISTANCE
		),
		"fov": BonfirePoseConfig.CINEMATIC_FOV,
	}


func _finish_bonfire_interaction() -> void:
	_init_bonfire_animation_tree_state()
	set_transition_locked(false)


func rest_at_bonfire() -> void:
	_health = BulletHitDamage.PLAYER_MAX_HEALTH
	_health_regen_timer = 0.0
	_update_health_vignette()
	_ammo = GroyperWeapons.get_max_ammo(_equipped_weapon)
	if _ammo_hud:
		_ammo_hud.sync_rounds(_ammo)


func _notify_nearby_enemies_of_gunshot(origin: Vector3) -> void:
	for node in get_tree().get_nodes_in_group("cave_enemy"):
		if node.has_method("alert_to_gunshot"):
			node.alert_to_gunshot(origin)


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

	var switching_to_melee := GroyperWeapons.is_sword_shield(weapon_id)
	var switching_from_melee := GroyperWeapons.is_sword_shield(_equipped_weapon)

	if weapon_id == _equipped_weapon:
		if switching_to_melee:
			if _melee_weapon_rig != null and _melee_weapon_rig.is_equipped():
				return
		elif _weapon_rig != null and _weapon_rig.get_equipped_weapon_id() == weapon_id:
			return

	if _lasso_controller != null:
		_lasso_controller.reset()

	if _bow_controller != null:
		_bow_controller.reset()

	if switching_from_melee and not switching_to_melee:
		_combat_blocking = false
		_complete_melee_attack()
		_set_melee_block_hold_blend(0.0)
		_block_walk_amount = 0.0
		_apply_block_walk_locomotion_blend()
		_set_combat_idle_blend_instant(0.0)
		_holster_melee_weapon()

	if switching_to_melee:
		if _weapon_rig != null:
			_weapon_rig.reset_to_holster()
		_equipped_weapon = weapon_id
		_shot_cooldown = 0.0
		_fire_held = false
		_reset_reload_input()
		_reset_reticle_state()
		if _ammo_hud:
			_ammo_hud.configure_for_weapon(_equipped_weapon)
			_ammo_hud.sync_rounds(_ammo)
		_equip_melee_weapon()
		_update_combat_ui()
		refresh_stowed_weapon_visuals()
		return

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


func notify_weapon_inventory_changed() -> void:
	_show_weapon_select_hud()


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
	if PlayerInventory.owns_weapon_type(GroyperWeapons.Id.BOW) \
			and _equipped_weapon != GroyperWeapons.Id.BOW:
		return GroyperWeapons.Id.BOW
	for weapon_id in [GroyperWeapons.Id.AWP, GroyperWeapons.Id.SHOTGUN, GroyperWeapons.Id.SHOVEL]:
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


func get_push_intent() -> Vector3:
	return _push_intent


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


func _try_teleport_companion() -> void:
	CompanionManager.request_companion_teleport(self)


func is_mounted_on_horse() -> bool:
	if _mount_transition_active:
		return false
	if _mounted_horse == null:
		return false
	if _mounted_horse.has_method("is_horse_defeated") and _mounted_horse.is_horse_defeated():
		return false
	return true


func notify_mounted_horse_killed(hit_info: Dictionary) -> void:
	if _mount_transition_active:
		return
	if _mounted_horse == null and not _is_model_parented_to_horse():
		return
	var horse := _mounted_horse
	if horse == null:
		horse = _find_horse_from_model_parent() as StupidHorse
	var exit_pos := global_position
	if horse != null and horse.has_method("get_death_dismount_position_for_rider"):
		exit_pos = horse.get_death_dismount_position_for_rider(hit_info)
	dismount_from_dead_horse(exit_pos, hit_info)


func get_mounted_horse() -> StupidHorse:
	return _mounted_horse


func mount_on_horse(horse: StupidHorse) -> void:
	if horse == null or _mounted_horse != null or _mount_transition_active:
		return

	_clear_lock_on()
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
	if _mounted_horse.has_method("is_horse_defeated") and _mounted_horse.is_horse_defeated():
		return
	if mount == null:
		mount = _mounted_horse.get_rider_mount_node()
	if mount == null:
		return
	global_position = mount.global_position
	velocity = Vector3.ZERO
	_sync_mounted_model_to_mount(mount)


func _sync_mounted_model_to_mount(mount: Node3D = null) -> void:
	if _mounted_horse == null or _model == null or _mount_transition_active:
		return
	if _mounted_horse.has_method("is_horse_defeated") and _mounted_horse.is_horse_defeated():
		return
	if mount == null:
		mount = _mounted_horse.get_rider_mount_node()
	if mount == null:
		return
	if _model.get_parent() != mount:
		GroyperBodyUtils.attach_model_to_rider_mount(_model, mount)
	_model.global_transform = mount.global_transform * _mounted_model_mount_offset


func _follow_mounted_horse() -> void:
	follow_mounted_horse()


func dismount_from_horse(spawn_pos: Vector3, for_defeat: bool = false, for_horse_death: bool = false) -> void:
	if _mounted_horse == null and not _is_model_parented_to_horse():
		return
	if _mount_transition_active and not for_horse_death:
		return

	if for_horse_death:
		dismount_from_dead_horse(spawn_pos, {})
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


func dismount_from_dead_horse(
	exit_xz: Vector3,
	_hit_info: Dictionary,
	on_complete: Callable = Callable()
) -> void:
	if _mount_transition_active:
		return
	if _mounted_horse == null and not _is_model_parented_to_horse():
		if on_complete.is_valid():
			on_complete.call()
		return

	var horse := _mounted_horse
	if horse == null:
		horse = _find_horse_from_model_parent() as StupidHorse

	var mount_pos := global_position
	if horse != null:
		var mount := horse.get_rider_mount_node()
		if mount != null:
			mount_pos = mount.global_position

	_kill_mount_hop_tween()
	_mount_transition_active = true
	_horse_death_dismount_callback = on_complete
	_force_detach_model_to_player()
	_ensure_model_detached_for_horse_dismount()
	_rebind_animation_tree()

	var ground_hint := mount_pos.y - 1.2
	if horse != null:
		ground_hint = horse.global_position.y

	var landing := GroyperBodyUtils.resolve_horse_death_landing(
		self,
		Vector3(exit_xz.x, ground_hint, exit_xz.z),
		ground_hint
	)

	if _mounted_horse != null:
		unregister_interactable(_mounted_horse)
	_mounted_horse = null
	_mounted_model_mount_offset = Transform3D.IDENTITY
	_mount_spine_yaw = 0.0

	if _weapon_rig != null:
		_weapon_rig.set_saddle_aim_mode(false)
		_weapon_rig.set_mount_aim_spine_yaw(0.0)

	global_position = mount_pos
	velocity = Vector3.ZERO

	if _model != null:
		_mount_hop_model_yaw_from = _model.rotation.y
		_mount_hop_model_yaw_to = GroyperBodyUtils.MODEL_YAW_OFFSET

	_mount_hop_tween = create_tween()
	_mount_hop_tween.tween_method(
		func(t: float) -> void:
			global_position = GroyperBodyUtils.hop_world_position(
				mount_pos,
				landing,
				t,
				HORSE_DEATH_DISMOUNT_ARC
			)
			_ensure_model_detached_for_horse_dismount()
			_apply_mount_hop_model_pose(t, HORSE_DEATH_DISMOUNT_ARC),
		0.0,
		1.0,
		HORSE_DEATH_DISMOUNT_DURATION
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_mount_hop_tween.tween_callback(func() -> void:
		_tween_mount_settle(false, Callable(self, "_finish_dismount_after_settle").bind(landing))
	)


func _compute_horse_death_launch(hit_info: Dictionary, horse: StupidHorse) -> Vector3:
	var shot_dir: Vector3 = hit_info.get("direction", Vector3.FORWARD)
	shot_dir.y = 0.0
	if shot_dir.length_squared() < 0.0001 and horse != null:
		shot_dir = -horse.get_facing_direction()
	shot_dir = shot_dir.normalized() if shot_dir.length_squared() > 0.0001 else Vector3.FORWARD
	return shot_dir * 3.5 + Vector3.UP * 2.5


func _finish_dismount_after_settle(landing: Vector3) -> void:
	_force_detach_model_to_player()
	_ensure_model_detached_for_horse_dismount()
	GroyperBodyUtils.apply_model_baseline(_model)
	_apply_dismount_cleanup(landing, false)
	var callback := _horse_death_dismount_callback
	_horse_death_dismount_callback = Callable()
	if callback.is_valid():
		callback.call()


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
	return GroyperBodyUtils.hop_world_position(start, end, t, height)


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
	_notify_companion_defenders()


func _notify_companion_defenders() -> void:
	for node in get_tree().get_nodes_in_group("baldwin_npc"):
		if node.has_method("notify_companion_defend_player"):
			node.notify_companion_defend_player()


func get_faction_id() -> StringName:
	return FactionIds.PLAYER


## Call after placing the actor at a spawn marker.
## Marker yaw spins the CharacterBody3D root; CameraPivot keeps its default PI explore offset.
func sync_overworld_spawn_orientation() -> void:
	_camera_yaw = PI
	_camera_pivot.rotation.y = _camera_yaw
	_camera_arm.rotation.x = _camera_pitch
	_model.rotation.y = GroyperBodyUtils.MODEL_YAW_OFFSET


func get_weapon_aim_ray() -> Dictionary:
	return {
		"origin": _get_aim_ray_origin(),
		"direction": _get_aim_direction(),
	}


func is_weapon_raised() -> bool:
	if _weapon_rig == null or GroyperWeapons.is_lasso(_equipped_weapon):
		return false
	if GroyperWeapons.is_bow(_equipped_weapon):
		return _is_bow_free_aim() or _weapon_rig.get_bow_draw_alpha() > 0.05
	return not _weapon_rig.is_holstered()


func is_weapon_drawn() -> bool:
	return is_weapon_raised()


func _get_threat_aim_point(target: Node3D) -> Vector3:
	if target.has_method("get_threat_aim_point"):
		return target.get_threat_aim_point()
	if target.has_method("get_duel_body_aim_point"):
		return target.get_duel_body_aim_point("chest")
	if target.has_method("get_bullet_capsule"):
		var capsule: Dictionary = target.get_bullet_capsule()
		return capsule.get("center", target.global_position + Vector3(0.0, 1.25, 0.0))
	return target.global_position + Vector3(0.0, 1.25, 0.0)


func is_weapon_aimed_at(target: Node3D, max_range: float = THREATEN_RANGE) -> bool:
	if target == null or _weapon_rig == null:
		return false
	if GroyperWeapons.is_lasso(_equipped_weapon):
		return false
	if GroyperWeapons.is_bow(_equipped_weapon):
		if not (_is_bow_free_aim() or _weapon_rig.get_bow_draw_alpha() > 0.05):
			return false
	elif not _weapon_rig.is_aiming():
		return false

	var origin := _get_aim_ray_origin()
	var direction := _get_aim_direction()
	if target.has_method("get_bullet_capsule"):
		var capsule: Dictionary = target.get_bullet_capsule()
		var hit_t := DuelHitTest.raycast_capsule(
			origin,
			direction,
			max_range,
			capsule.get("center", Vector3.ZERO),
			capsule.get("half_height", 0.75),
			capsule.get("radius", 0.5) + 0.12,
			capsule.get("axis", Vector3.UP)
		)
		if hit_t >= 0.0:
			return true

	var aim_point := _get_threat_aim_point(target)
	var to_target := aim_point - origin
	var dist := to_target.length()
	if dist < 0.0001 or dist > max_range:
		return false
	return direction.dot(to_target / dist) > cos(deg_to_rad(55.0))


func is_weapon_threatening(target: Node3D, max_range: float = THREATEN_RANGE) -> bool:
	if not is_weapon_raised():
		return false
	if target == null:
		return false

	var horizontal := target.global_position - global_position
	horizontal.y = 0.0
	if horizontal.length() > max_range:
		return false

	var origin := _get_aim_ray_origin()
	var aim_point := _get_threat_aim_point(target)
	var to_target := aim_point - origin
	var dist := to_target.length()
	if dist < 0.0001 or dist > max_range:
		return false

	var aim_dir := _get_aim_direction()
	if aim_dir.dot(to_target / dist) > cos(deg_to_rad(60.0)):
		return true

	var flat_aim := aim_dir
	flat_aim.y = 0.0
	var flat_to := aim_point - global_position
	flat_to.y = 0.0
	if flat_aim.length_squared() > 0.0001 and flat_to.length_squared() > 0.0001:
		if flat_aim.normalized().dot(flat_to.normalized()) > cos(deg_to_rad(45.0)):
			return true

	return is_weapon_aimed_at(target, max_range)


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


func receive_bullet_hit(hit_info: Dictionary) -> void:
	if _overworld_defeated:
		return
	_melee_hit_absorbed = false
	if _can_reflect_hit(hit_info):
		_on_shield_reflect_success(hit_info)
		return
	if _can_block_melee_hit(hit_info):
		var damage := int(hit_info.get("damage", 1))
		if damage >= BaldwinShieldConfigScript.DEFAULT_BLOCK_BREAK_DAMAGE:
			_melee_hit_absorbed = true
			_on_melee_shield_block_broken(hit_info)
			return
		_melee_hit_absorbed = true
		_on_melee_attack_blocked(hit_info)
		return
	if bool(hit_info.get("melee", false)):
		enter_overworld_combat()
	elif not _overworld_combat_active:
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
		return
	if GroyperHitReactionConfig.should_knockdown(hit_info, bool(result.knockback_applied)):
		_try_start_hit_reaction(hit_info)
	elif bool(result.knockback_applied):
		_apply_light_hit_reaction(hit_info)
	else:
		CombatHitFlashScript.flash_damage(self)


func _apply_light_hit_reaction(hit_info: Dictionary) -> void:
	if _hit_reaction_active or _overworld_defeated:
		return
	CombatHitFlashScript.flash_damage(self)
	var stun_duration := GroyperHitReactionConfig.LIGHT_HIT_STUN_DURATION
	if bool(hit_info.get("melee", false)):
		var melee_stun := float(hit_info.get("melee_stun_duration", 0.0))
		if melee_stun > 0.0:
			stun_duration = melee_stun
	apply_melee_stun(stun_duration)
	_melee_facing_yaw_locked = _model.rotation.y if _model != null else 0.0
	_melee_block_facing_lock_timer = stun_duration
	hold_knockback_velocity(stun_duration)


func is_defeated() -> bool:
	return _overworld_defeated


func _try_start_hit_reaction(hit_info: Dictionary) -> void:
	if (
		not _hit_reaction_nodes_ready
		or _hit_reaction_active
		or _overworld_defeated
		or _is_fully_mounted()
		or _is_bonfire_pose_active()
	):
		return

	if _combat_attacking:
		_complete_melee_attack()
	if _combat_blocking:
		_end_melee_blocking(true)
	if _punch_active:
		_finish_punch()
	if _roll_active:
		_finish_roll_dodge()
	_clear_lock_on()

	apply_melee_stun(GroyperHitReactionConfig.get_knockdown_stun_duration())
	CombatHitFlashScript.flash_damage(self)

	var hit_dir: Vector3 = hit_info.get("direction", Vector3.FORWARD)
	hit_dir.y = 0.0
	if hit_dir.length_squared() > 0.0001:
		var face_dir := -hit_dir.normalized()
		_model.rotation.y = atan2(face_dir.x, face_dir.z)

	_apply_knockdown_impulse(hit_info)
	_reset_locomotion_tree_blends()

	_hit_reaction_fall_duration = _get_hit_reaction_anim_length(
		GroyperHitReactionConfig.get_falling_down_path(),
		0.85
	)
	_hit_reaction_stand_duration = _get_hit_reaction_anim_length(
		BonfirePoseConfig.get_stand_up3_path(),
		1.2
	)
	_hit_reaction_active = true
	_hit_reaction_control_unlocked = false
	_hit_reaction_model_sink = 0.0
	_hit_reaction_applied_body_sink = 0.0
	_hit_reaction_phase = GroyperHitReactionConfig.Phase.FALLING
	_hit_reaction_fall_timer = 0.0
	_hit_reaction_stand_timer = 0.0
	_hit_reaction_blend = 0.0
	_hit_reaction_pose_blend = 0.0
	_cancel_hit_reaction_pose_tween()
	_apply_hit_reaction_tree_blends()
	GroyperHitReactionConfig.set_fall_seek(_animation_tree, 0.0)
	GroyperHitReactionConfig.set_stand_seek(_animation_tree, -1.0)
	GroyperHitReactionConfig.set_stand_playback_speed(_animation_tree, 1.0)


func _apply_knockdown_impulse(hit_info: Dictionary) -> void:
	var hit_dir: Vector3 = hit_info.get("direction", Vector3.FORWARD)
	hit_dir.y = 0.0
	if hit_dir.length_squared() < 0.0001:
		hit_dir = -global_transform.basis.z
		hit_dir.y = 0.0
	if hit_dir.length_squared() < 0.0001:
		hit_dir = Vector3.FORWARD
	hit_dir = hit_dir.normalized()

	var speed := GroyperHitReactionConfig.get_knockdown_impulse_speed(hit_info)
	var up := GroyperHitReactionConfig.get_knockdown_impulse_up(hit_info)
	velocity.x = hit_dir.x * speed
	velocity.z = hit_dir.z * speed
	velocity.y = maxf(velocity.y, up)
	_hit_reaction_impulse_timer = GroyperHitReactionConfig.get_knockdown_impulse_hold()
	hold_knockback_velocity(_hit_reaction_impulse_timer)


func _get_hit_reaction_anim_length(anim_path: StringName, fallback: float) -> float:
	if _animation_player == null or not _animation_player.has_animation(anim_path):
		return fallback
	return maxf(_animation_player.get_animation(anim_path).length, 0.001)


func _update_hit_reaction(delta: float) -> void:
	if not _hit_reaction_active:
		return

	if not _hit_reaction_control_unlocked:
		tick_melee_stun(delta)

		if not is_on_floor():
			velocity.y -= GRAVITY * delta
		else:
			velocity.y = minf(velocity.y, 0.0)

		if _hit_reaction_impulse_timer > 0.0:
			_hit_reaction_impulse_timer = maxf(_hit_reaction_impulse_timer - delta, 0.0)
			hold_knockback_velocity(_hit_reaction_impulse_timer)
		else:
			var damp := 18.0 if _hit_reaction_phase == GroyperHitReactionConfig.Phase.FALLING else 28.0
			velocity.x = move_toward(velocity.x, 0.0, damp * delta)
			velocity.z = move_toward(velocity.z, 0.0, damp * delta)

		move_with_ground_snap()

	match _hit_reaction_phase:
		GroyperHitReactionConfig.Phase.FALLING:
			_update_hit_reaction_falling(delta)
		GroyperHitReactionConfig.Phase.STANDING_UP:
			_update_hit_reaction_stand_up(delta)

	_update_hit_reaction_ground_sink(delta)


func _update_hit_reaction_ground_sink(delta: float) -> void:
	if _model == null:
		return

	var sink_weight := 0.0
	match _hit_reaction_phase:
		GroyperHitReactionConfig.Phase.FALLING:
			sink_weight = GroyperHitReactionConfig.get_fall_ground_sink_weight(
				_hit_reaction_fall_timer,
				_hit_reaction_fall_duration,
				is_on_floor()
			)
		GroyperHitReactionConfig.Phase.STANDING_UP:
			var stand_progress := clampf(
				_hit_reaction_stand_timer / maxf(_hit_reaction_stand_duration, 0.001),
				0.0,
				1.0
			)
			sink_weight = GroyperHitReactionConfig.get_stand_ground_sink_weight(stand_progress)

	var target_model_sink := (
		sink_weight * GroyperHitReactionConfig.FALL_GROUND_MODEL_Y_OFFSET
	)
	var target_body_sink := 0.0
	if not _hit_reaction_control_unlocked:
		target_body_sink = sink_weight * GroyperHitReactionConfig.FALL_GROUND_BODY_Y_OFFSET
	var sink_step := 1.0 - exp(-HIT_REACTION_GROUND_SINK_SPEED * delta)
	_hit_reaction_model_sink = lerpf(_hit_reaction_model_sink, target_model_sink, sink_step)
	_model.position.y = GroyperBodyUtils.ACTOR_MODEL_Y + _hit_reaction_model_sink
	_apply_hit_reaction_body_sink(target_body_sink)


func _apply_hit_reaction_body_sink(target_sink: float) -> void:
	var delta_sink := target_sink - _hit_reaction_applied_body_sink
	if absf(delta_sink) <= 0.00001:
		return
	global_position.y -= delta_sink
	_hit_reaction_applied_body_sink = target_sink


func _restore_hit_reaction_body_sink() -> void:
	if absf(_hit_reaction_applied_body_sink) <= 0.00001:
		return
	global_position.y += _hit_reaction_applied_body_sink
	_hit_reaction_applied_body_sink = 0.0


func _reset_hit_reaction_ground_sink() -> void:
	_restore_hit_reaction_body_sink()
	_hit_reaction_model_sink = 0.0
	if _model != null:
		GroyperBodyUtils.apply_model_baseline(_model)


func _update_hit_reaction_falling(delta: float) -> void:
	var playback := GroyperHitReactionConfig.SEQUENCE_PLAYBACK_SPEED
	_hit_reaction_fall_timer += delta * playback
	var blend_t := clampf(
		_hit_reaction_fall_timer / maxf(GroyperHitReactionConfig.get_sequence_blend_in_duration(), 0.001),
		0.0,
		1.0
	)
	var blend_target := _smoothstep(blend_t)
	var blend_step := 1.0 - exp(-HIT_REACTION_BLEND_IN_SPEED * delta)
	_hit_reaction_blend = lerpf(_hit_reaction_blend, blend_target, blend_step)
	GroyperHitReactionConfig.set_fall_seek(_animation_tree, _hit_reaction_fall_timer)
	_apply_hit_reaction_tree_blends()

	if (
		_hit_reaction_fall_timer >= _hit_reaction_fall_duration
		and not is_melee_stunned()
	):
		_begin_hit_reaction_stand_up()


func _smoothstep(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)


func _begin_hit_reaction_stand_up() -> void:
	if _hit_reaction_phase == GroyperHitReactionConfig.Phase.STANDING_UP:
		return

	_hit_reaction_phase = GroyperHitReactionConfig.Phase.STANDING_UP
	_hit_reaction_stand_timer = 0.0
	GroyperHitReactionConfig.set_stand_seek(_animation_tree, 0.0)
	GroyperHitReactionConfig.set_stand_playback_speed(
		_animation_tree,
		GroyperHitReactionConfig.get_stand_playback_speed()
	)
	_cancel_hit_reaction_pose_tween()
	var pose_blend_duration := GroyperHitReactionConfig.get_fall_to_stand_blend_duration()
	if pose_blend_duration <= 0.001:
		_set_hit_reaction_pose_blend(1.0)
	else:
		_hit_reaction_pose_tween = create_tween()
		_hit_reaction_pose_tween.set_trans(Tween.TRANS_SINE)
		_hit_reaction_pose_tween.set_ease(Tween.EASE_IN_OUT)
		_hit_reaction_pose_tween.tween_method(
			_set_hit_reaction_pose_blend,
			_hit_reaction_pose_blend,
			1.0,
			pose_blend_duration
		)


func _unlock_hit_reaction_control() -> void:
	if _hit_reaction_control_unlocked:
		return
	_hit_reaction_control_unlocked = true
	_melee_stun_timer = 0.0
	_hit_reaction_impulse_timer = 0.0
	_restore_hit_reaction_body_sink()
	_sync_locomotion_after_melee_attack()


func _update_hit_reaction_stand_up(delta: float) -> void:
	_hit_reaction_stand_timer += delta * GroyperHitReactionConfig.get_stand_playback_speed()
	var progress := clampf(
		_hit_reaction_stand_timer / maxf(_hit_reaction_stand_duration, 0.001),
		0.0,
		1.0
	)
	GroyperHitReactionConfig.set_stand_seek(_animation_tree, _hit_reaction_stand_timer)

	if progress >= GroyperHitReactionConfig.STAND_CONTROL_UNLOCK_FRACTION:
		_unlock_hit_reaction_control()

	var target_blend := 1.0
	if progress >= GroyperHitReactionConfig.STAND_BLEND_OUT_START:
		var out_t := clampf(
			(progress - GroyperHitReactionConfig.STAND_BLEND_OUT_START)
			/ maxf(1.0 - GroyperHitReactionConfig.STAND_BLEND_OUT_START, 0.001),
			0.0,
			1.0
		)
		target_blend = 1.0 - _smoothstep(out_t)

	var blend_step := 1.0 - exp(-HIT_REACTION_BLEND_OUT_SPEED * delta)
	_hit_reaction_blend = lerpf(_hit_reaction_blend, target_blend, blend_step)
	_apply_hit_reaction_tree_blends()

	if progress >= 1.0:
		_finish_hit_reaction()


func _finish_hit_reaction() -> void:
	_cancel_hit_reaction_pose_tween()
	_reset_hit_reaction_ground_sink()
	_hit_reaction_active = false
	_hit_reaction_control_unlocked = false
	_hit_reaction_phase = GroyperHitReactionConfig.Phase.NONE
	_hit_reaction_blend = 0.0
	_hit_reaction_pose_blend = 0.0
	_hit_reaction_fall_timer = 0.0
	_hit_reaction_stand_timer = 0.0
	_hit_reaction_impulse_timer = 0.0
	if _animation_tree != null:
		GroyperHitReactionConfig.set_reaction_blend(_animation_tree, 0.0)
		GroyperHitReactionConfig.set_pose_blend(_animation_tree, 0.0)
		GroyperHitReactionConfig.set_fall_seek(_animation_tree, -1.0)
		GroyperHitReactionConfig.set_stand_seek(_animation_tree, -1.0)
		GroyperHitReactionConfig.set_stand_playback_speed(_animation_tree, 1.0)
	_sync_locomotion_after_melee_attack()


func _apply_hit_reaction_tree_blends() -> void:
	GroyperHitReactionConfig.set_reaction_blend(_animation_tree, _hit_reaction_blend)
	GroyperHitReactionConfig.set_pose_blend(_animation_tree, _hit_reaction_pose_blend)


func _set_hit_reaction_pose_blend(value: float) -> void:
	_hit_reaction_pose_blend = clampf(value, 0.0, 1.0)
	GroyperHitReactionConfig.set_pose_blend(_animation_tree, _hit_reaction_pose_blend)


func _cancel_hit_reaction_pose_tween() -> void:
	if _hit_reaction_pose_tween != null and _hit_reaction_pose_tween.is_valid():
		_hit_reaction_pose_tween.kill()
	_hit_reaction_pose_tween = null


func get_bullet_capsule() -> Dictionary:
	if _is_fully_mounted():
		_sync_mounted_combat_origin()
		if _model != null:
			_model.force_update_transform()
		if _skeleton != null:
			_skeleton.force_update_transform()
	_sync_combat_hitbox_position()
	var torso := _get_combat_hurtbox_transform()
	var mounted := _is_fully_mounted()
	return {
		"center": torso.origin,
		"half_height": _get_projectile_hitbox_half_height() + (0.18 if mounted else 0.0),
		"radius": _get_projectile_hitbox_radius() + (0.14 if mounted else 0.0),
		"axis": Vector3.UP if mounted else torso.basis.y,
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
	if _model == null:
		return false
	var node := _model.get_parent()
	while node != null:
		if node.is_in_group("stupid_horse"):
			return true
		node = node.get_parent()
	return false


func _find_horse_from_model_parent() -> StupidHorse:
	if _model == null:
		return null
	var node := _model.get_parent()
	while node != null:
		if node is StupidHorse:
			return node as StupidHorse
		if node.is_in_group("stupid_horse"):
			return node as StupidHorse
		node = node.get_parent()
	return null


func _fall_off_dead_horse(hit_info: Dictionary) -> void:
	if _mount_transition_active:
		return
	var horse := _mounted_horse
	if horse == null:
		horse = _find_horse_from_model_parent()
	var exit_pos := global_position
	if horse != null and horse.has_method("get_death_dismount_position_for_rider"):
		exit_pos = horse.get_death_dismount_position_for_rider(hit_info)
	dismount_from_dead_horse(exit_pos, hit_info)


func _force_detach_model_to_player() -> void:
	GroyperBodyUtils.detach_model_to_actor(_model, self)
	_model_mount_parent = null


func _ensure_model_detached_for_horse_dismount() -> void:
	if _model == null:
		return
	if _model.get_parent() != self:
		_force_detach_model_to_player()
	if _model.get_parent() == self:
		GroyperBodyUtils.apply_model_baseline(_model)


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
		not _roll_active
		and not _cover_walk_enter_active
		and not _cover_exit_active
		and not _cover_crouch_active
		and not _overworld_defeated
		and not _mount_transition_active
	)


func _update_overworld_reload(_delta: float) -> void:
	if _weapon_rig == null or not _can_use_overworld_reload():
		_reset_reload_input()
		return

	var phase := _weapon_rig.get_overworld_reload_phase()
	if phase == GroyperWeaponRig.OverworldReloadPhase.NONE:
		if _reload_last_phase == GroyperWeaponRig.OverworldReloadPhase.HOLSTERING:
			_reset_reload_input()
	else:
		_update_active_reload(phase)

	_reload_last_phase = phase


func _try_begin_overworld_reload_eject() -> void:
	if _weapon_rig == null or not _can_use_overworld_reload():
		return
	if not _weapon_rig.can_begin_overworld_reload():
		return

	var max_ammo := GroyperWeapons.get_max_ammo(_equipped_weapon)
	if _ammo >= max_ammo:
		return

	_ammo = 0
	if _ammo_hud:
		_ammo_hud.eject_all_casings()
	_weapon_rig.begin_overworld_reload_eject()
	if _mounted_horse != null:
		_update_saddle_gun_arm_filter(_weapon_rig.get_draw_state())


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


func _try_overworld_reload_tap() -> bool:
	if _weapon_rig == null or not _reload_ready_for_tap:
		return false
	if not _weapon_rig.try_overworld_reload_tap():
		return false

	_reload_ready_for_tap = false
	_reload_pending_round = true
	return true


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
	_reload_ready_for_tap = false
	_reload_pending_round = false
	_reload_last_phase = GroyperWeaponRig.OverworldReloadPhase.NONE


func _sync_combat_hitbox_position() -> void:
	if _combat_hitbox == null:
		return
	_combat_hitbox.global_transform = _get_combat_hurtbox_transform()


func _sync_mounted_combat_origin() -> void:
	if _mounted_horse == null:
		return
	var mount := _mounted_horse.get_rider_mount_node()
	if mount != null:
		global_position = mount.global_position


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
