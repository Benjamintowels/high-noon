extends GroyperActor

const WEAPON_RIG_SCRIPT := preload("res://characters/groyper/groyper_weapon_rig.gd")
const ChairSitConfigScript := preload("res://characters/groyper/chair_sit_config.gd")
const BaldwinBodyUtilsScript := preload("res://characters/baldwin/baldwin_body_utils.gd")
const BaldwinWeaponRigScript := preload("res://characters/baldwin/baldwin_weapon_rig.gd")
const GroyperWeapons := preload("res://characters/groyper/groyper_weapons.gd")
const DUEL_HITBOX_SCRIPT := preload("res://characters/groyper/groyper_hitbox.gd")
const DUEL_RAGDOLL_SCRIPT := preload("res://characters/groyper/groyper_ragdoll.gd")
const DUEL_HAT_SCRIPT := preload("res://characters/groyper/groyper_duel_hat.gd")
const HatCatalogScript := preload("res://characters/groyper/groyper_hat_catalog.gd")
const DEPUTY_BADGE_SCRIPT := preload("res://characters/groyper/groyper_deputy_badge.gd")
const DuelHitTest := preload("res://gameplay/duel/duel_hit_test.gd")
const BulletHitDamage := preload("res://gameplay/shooting/bullet_hit_damage.gd")
const SaddlePoseConfig := preload("res://characters/groyper/saddle_pose_config.gd")
const BonfirePoseConfig := preload("res://characters/groyper/bonfire_pose_config.gd")
const CometCinematicConfig := preload("res://gameplay/world/comet_cinematic_config.gd")
const GroyperHitReactionConfig := preload("res://characters/groyper/groyper_hit_reaction_config.gd")
const GroyperFacePunchReactionScript := preload("res://characters/groyper/groyper_face_punch_reaction.gd")
const CoverPoseExtractScript := preload("res://characters/groyper/cover_pose_extract.gd")
const VaultConfigScript := preload("res://characters/groyper/vault_config.gd")
const LassoSwingConfigScript := preload("res://characters/groyper/lasso_swing_config.gd")
const ClimbFallConfigScript := preload("res://characters/groyper/climb_fall_config.gd")
const LadderClimbConfigScript := preload("res://characters/groyper/ladder_climb_config.gd")
const TwoHandedConfigScript := preload("res://characters/groyper/two_handed_config.gd")
const FlyingKickConfigScript := preload("res://characters/groyper/flying_kick_config.gd")
const FlyingKickFXScript := preload("res://gameplay/fx/flying_kick_fx.gd")
const UnarmedPunchBlockScript := preload("res://gameplay/combat/unarmed_punch_block.gd")
const PunchPoseConfig := preload("res://characters/groyper/punch_pose_config.gd")
const UnarmedBlockPoseConfig := preload("res://characters/groyper/unarmed_block_pose_config.gd")
const MeleePunch := preload("res://gameplay/combat/melee_punch.gd")
const GameAudio := preload("res://gameplay/audio/game_audio.gd")
const LassoAudioScript := preload("res://gameplay/audio/lasso_audio.gd")
const LassoControllerScript := preload("res://gameplay/lasso/lasso_controller.gd")
const LassoSwingPhysicsScript := preload("res://gameplay/lasso/lasso_swing_physics.gd")
const BowControllerScript := preload("res://gameplay/bow/bow_controller.gd")
const BowTrajectoryPreviewScript := preload("res://gameplay/bow/bow_trajectory_preview.gd")
const FactionIds := preload("res://gameplay/faction/faction_ids.gd")
const KNIFE_GRIP_SCENE := preload("res://characters/groyper/knife_grip.tscn")
const DYNAMITE_GRIP_SCENE := preload("res://characters/groyper/dynamite_grip.tscn")
const DynamiteProjectileScript := preload("res://gameplay/combat/dynamite_projectile.gd")
const TorchProjectileScript := preload("res://gameplay/combat/torch_projectile.gd")
const KNIFE_PROJECTILE_SCENE := preload("res://gameplay/combat/knife_projectile.tscn")
const GroyperMeleeAnimConfig := preload("res://characters/groyper/groyper_melee_anim_config.gd")
const BaldwinShieldConfigScript := preload("res://characters/baldwin/baldwin_shield_config.gd")
const CombatHitFlashScript := preload("res://gameplay/fx/combat_hit_flash.gd")
const MeleeClashScript := preload("res://gameplay/combat/melee_clash.gd")
const BlockPoiseScript := preload("res://gameplay/combat/block_poise.gd")
const RigAnimConfigScript := preload("res://characters/groyper/rig_anim_config.gd")
const ShieldReflectScript := preload("res://gameplay/combat/shield_reflect.gd")
const MeleeSwordSlashScript := preload("res://gameplay/combat/melee_sword_slash.gd")
const CombatLockOnScript := preload("res://gameplay/combat/combat_lock_on.gd")
const LockOnIndicatorScript := preload("res://gameplay/combat/lock_on_indicator.gd")
const SwordCrescentFXScript := preload("res://gameplay/fx/sword_crescent_fx.gd")
const ElementalAttackFXScript := preload("res://gameplay/fx/elemental_attack_fx.gd")
const LightningGemCombatScript := preload("res://gameplay/combat/lightning_gem_combat.gd")
const ElementalGemStaminaScript := preload("res://gameplay/combat/elemental_gem_stamina.gd")
const TwoHandImpactFXScript := preload("res://gameplay/fx/two_hand_impact_fx.gd")
const TwoHandHammerSlamScript := preload("res://gameplay/combat/two_hand_hammer_slam.gd")
const HammerSpinStrikeScript := preload("res://gameplay/combat/hammer_spin_strike.gd")
const WeaponThrowConfigScript := preload("res://characters/groyper/weapon_throw_config.gd")
const ThrownWeaponProjectileScript := preload("res://gameplay/combat/thrown_weapon_projectile.gd")
const RevolverAmmoPickupScript := preload("res://gameplay/world/revolver_ammo_pickup.gd")
const OverworldAnimBuilder := preload("res://characters/groyper/groyper_overworld_anim_builder.gd")
const PlayerReticleState := preload("res://characters/groyper/player_reticle_state.gd")
const PlayerClimbFallState := preload("res://characters/groyper/player_climb_fall_state.gd")
const PlayerLadderState := preload("res://characters/groyper/player_ladder_state.gd")
const PlayerLassoSwingState := preload("res://characters/groyper/player_lasso_swing_state.gd")

const BODY_AIM_ZONES := {
	"head": {"bone": "Head", "offset": Vector3(0.0, 0.06, 0.05)},
	"chest": {"bone": "Spine02", "offset": Vector3(0.0, 0.1, 0.06)},
	"gut": {"bone": "Spine01", "offset": Vector3(0.0, 0.04, 0.05)},
	"left_shoulder": {"bone": "LeftShoulder", "offset": Vector3(-0.06, 0.02, 0.03)},
	"right_shoulder": {"bone": "RightShoulder", "offset": Vector3(0.06, 0.02, 0.03)},
}
const THREATEN_RANGE := 18.0
## Always-drawn firearms only threaten NPCs while ADS or shortly after firing.
const THREAT_RECENT_SHOT_WINDOW_MS := 2500
const LOCOMOTION_BLEND := &"LocomotionBlend"
const WALK_LOCOMOTION_BLEND := &"WalkLocomotionBlend"
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
const BLOCK_REFLECT_HOLD_BLEND_IN_TIME := 0.20
const BLOCK_REFLECT_WALK_BLEND_OUT_TIME := 0.26
const BLOCK_WALK_INPUT_HINT := 0.18
## Player-only: cancel any attack into block with a snappy but smooth blend.
const ATTACK_CANCEL_INTO_BLOCK_BLEND := 0.06
const COMBAT_IDLE_BLEND_IN_TIME := 0.38
const COMBAT_IDLE_BLEND_OUT_TIME := 0.18
const ROLL_ONE_SHOT := &"RollOneShot"
const VAULT_TIME_SEEK := &"VaultTimeSeek"
const VAULT_TIME_SCALE := &"VaultTimeScale"
const VAULT_BLEND := &"VaultBlend"
const COVER_POSE_BLEND := &"CoverPoseBlend"
const COVER_PEEK_BLEND := &"CoverPeekBlend"
const COVER_PEEK_BLEND_SPEED := 8.0
const COVER_WALK_ENTER_DURATION := 0.4
const COVER_EXIT_DURATION := 0.4
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
const MELEE_ATTACK_COOLDOWN := 0.55
const MELEE_SPIN_ATTACK_COOLDOWN := 0.8
const MELEE_ATTACK_RANGE := MeleeSwordSlashScript.RANGE
const MELEE_SPIN_ATTACK_RANGE := MeleeSwordSlashScript.SPIN_RANGE
const MELEE_BLOCK_FACING_DOT_MIN := 0.32
const MELEE_COMBAT_IDLE_STOP_SPEED := 0.08
const MELEE_BLOCK_WALK_SPEED := 3.0
const MELEE_ATTACK_MOVE_SPEED := 1.325
const MELEE_SPIN_ATTACK_MOVE_SPEED := 4.8
const MELEE_ATTACK_MOVE_ACCEL := 14.0

## Two-handed melee tuning. Carry weight (WEAPON_STATS.weight) slows explore
## movement; this leftover mult still scales block-walk when a 2H is drawn.
## Dedicated idle/walk/sprint clips blend over the base locomotion.
const TWO_HAND_MOVE_SPEED_MULT := 0.82
## Brief connection linger on a landed melee strike to sell impact weight.
const MELEE_HITSTOP_DURATION := 0.09
const MELEE_HITSTOP_PLAYBACK_SPEED := 0.05
## Two-handers linger a hair longer than punches / one-hand swings.
const TWO_HAND_HITSTOP_DURATION := 0.11
## Invulnerability after any successful melee contact (punch, sword, kick, etc.).
const MELEE_HIT_INVULN_DURATION := 0.5
## Punch exit yaw ease matches the punch overlay fade (see MeleePunch exit blend).
const PUNCH_FACING_RETURN_EASE := 2.6
## War hammer sprint spin: dust trail cadence while the continuous hitbox is live.
const HAMMER_SPIN_TRAIL_INTERVAL := 0.09
## F-jab with a two-hander in hand plays slightly slower to sell the weight.
const TWO_HAND_PUNCH_SPEED_MULT := 0.85

## How hard the player can throw. Measured against a weapon's throw_weight stat
## for projectile speed; later this will gate throwing heavier items entirely.
var throw_strength := 3.0
const TWO_HAND_LOCOMOTION_BLEND_IN := 0.28
const TWO_HAND_LOCOMOTION_BLEND_OUT := 0.2
const TWO_HAND_LOCOMOTION_BLEND := &"TwoHandLocomotionBlend"
const TWO_HAND_LOCOMOTION_SPACE := &"TwoHandLocomotionSpace"

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
const UNARMED_GRAB_KEY := KEY_Q
const FLYING_KICK_FORWARD_SPEED := 8.6
const FLYING_KICK_RISE_SPEED := 3.4
const FLYING_KICK_PLAYBACK_SPEED := 1.25
const FLYING_KICK_COOLDOWN := 0.9
const FLYING_KICK_CONTACT_RANGE := 1.7
const FLYING_KICK_STRIKE_START_FRACTION := 0.12
const FLYING_KICK_BOUNCE_BACK_SPEED := 4.6
const FLYING_KICK_BOUNCE_UP_SPEED := 6.2
const FLYING_KICK_BLOCK_KNOCKBACK_SPEED := 5.2
const FLYING_KICK_MIN_AIR_TIME := 0.12
const FLYING_KICK_BLEND_IN_SPEED := 14.0
const FLYING_KICK_EXIT_BLEND := 0.22
const FLYING_KICK_TRAIL_INTERVAL := 0.07
const FLYING_KICK_CAMERA_SHAKE := 0.5
const UNARMED_BLOCK_WALK_SPEED := 2.8
const UNARMED_GRAB_COOLDOWN := 1.4
## Q grab reach / counter window — attacks that land here become a spin throw.
const UNARMED_GRAB_WINDOW := 0.75
const PARRY_SPIN_SCENE := (
	"res://Assets/CharacterModels/Groyper/GroyperSDanimations/Meshy_AI_Emerald_Embrace_biped/"
	+ "Meshy_AI_Emerald_Embrace_biped_Animation_Skill_02_frame_rate_60.fbx"
)
const PARRY_LIBRARY := &"parry_throw"
const PARRY_SPIN_CLIP := &"skill2_spin"
const PARRY_SPIN_FADEIN := 0.25
const UnarmedParryThrowScript := preload("res://gameplay/combat/unarmed_parry_throw.gd")
const UnarmedHostageTakeScript := preload("res://gameplay/combat/unarmed_hostage_take.gd")
const PropHostageTakeScript := preload("res://gameplay/combat/prop_hostage_take.gd")
const HOSTAGE_MOVE_SPEED_MULT := 0.5
## Movement authority kept while the punched reaction stun plays (not knockdown).
const FACE_PUNCH_STUN_MOVE_MULT := 0.5
const DEBUG_COLLISION_PRINT_KEY := KEY_U
const DEBUG_CAMERA_PRINT_KEY := KEY_I
const DEBUG_ARM_OFFSET_KEY := KEY_O
const HipFireArmOffsetDebugScript := preload(
	"res://gameplay/debug/hip_fire_arm_offset_debug.gd"
)
const KNIFE_THROW_SPEED := 20.0
const KNIFE_THROW_HIGH_AIM_BOOST := 1.32
const PUNCH_BLEND_IN_SPEED := 5.5
const VAULT_ANIM_FADEIN := 0.08
const VAULT_EXIT_BLEND_DURATION := 0.28
const VAULT_DROP_FLOOR_PROBE_DEPTH := 1.25
const VAULT_PEAK_HEIGHT := 0.85
const VAULT_MOVE_TIME_SCALE := 0.52
const VAULT_PLAYBACK_SPEED := 1.5
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
const MOVE_DECEL := 12.0
const MOVE_STOP_DECEL := 26.0
const SHOT_RANGE := 140.0
const AIM_ARM_TARGET_DISTANCE := 55.0

const RELOAD_KEY := KEY_R

const RETICLE_MAX_SCREEN_FRACTION := 0.32
const RETICLE_MOUSE_ACCEL := 2.4
const RETICLE_DRAG := 4.8
const RETICLE_MAX_SPEED_PX := 280.0
const RETICLE_SMOOTH := 6.5
## Cover peek aim â€” fast whip, low drag so aim keeps sliding after you stop.
const COVER_RETICLE_MOUSE_ACCEL := 4.7
const COVER_RETICLE_DRAG := 1.85
const COVER_RETICLE_MAX_SPEED_PX := 425.0
const COVER_RETICLE_SMOOTH := 2.4
const COVER_AIM_CAMERA_RELEASE_SMOOTH := 2.75

## Duel-style shoulder aim: player sits off-center so the reticle clears what's ahead.
const AIM_CAMERA_OFFSET := Vector3(0.85, 0.0, 1.45)
const BOW_AIM_CAMERA_OFFSET := Vector3(1.08, 0.06, 1.02)
const AIM_FOV_REDUCTION := 4.0
## Run-and-gun ADS: RMB zoom pulls the camera in tight over the shoulder.
const ADS_CAMERA_OFFSET := Vector3(0.72, 0.02, 1.05)
const ADS_CAMERA_BLEND_SPEED := 10.0
## Hip stance for always-drawn firearms sits between explore and the old
## RMB-aim shoulder cam so free roaming doesn't feel claustrophobic.
const RUN_AND_GUN_HIP_CAMERA_OFFSET := Vector3(0.75, 0.1, 2.1)
const RUN_AND_GUN_HIP_FOV_REDUCTION := 2.0
## Degrees of camera kick per unit of the weapon camera_recoil_kick stat.
const CAMERA_RECOIL_DEG_PER_KICK := 0.06
const BOW_AIM_FOV_REDUCTION := 9.0
## Close shoulder cam can raycast into the player capsule â€” ignore hits closer than this.
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
const MOUNT_VAULT_PLAYBACK_SPEED := 2.0
const DISMOUNT_VAULT_PLAYBACK_SPEED := 2.0
const DISMOUNT_HOP_DURATION := 0.46
const DISMOUNT_HOP_HEIGHT := 0.8
const MOUNT_SETTLE_DURATION := 0.32
const MOUNT_AIM_CAMERA_PITCH_MIN := deg_to_rad(-50.0)
const MOUNT_AIM_CAMERA_PITCH_MAX := deg_to_rad(65.0)
const MOUNT_AIM_CAMERA_OFFSET := Vector3(0.75, 0.05, 1.35)
const INTERIOR_EXPLORE_CAMERA_OFFSET := Vector3(0.65, 0.18, 1.385)
const INTERIOR_EXPLORE_CAMERA_PIVOT_Y := 1.1
const INTERIOR_EXPLORE_CAMERA_FOV := 80.0
const LOCK_ON_CAMERA_OFFSET := Vector3(0.905, 0.41, 2.18)
const LOCK_ON_CAMERA_PIVOT_Y := 1.1
const LOCK_ON_CAMERA_FOV := 80.0
const LOCK_ON_CAMERA_PITCH := deg_to_rad(-15.5)
const LOCK_ON_CAMERA_BLEND_IN := 8.5
const LOCK_ON_CAMERA_BLEND_OUT := 4.0
const INTERIOR_CAMERA_BLEND_SPEED := 5.0
const INTERIOR_CAMERA_COMBAT_RETURN_SPEED := 2.0
const INTERIOR_CAMERA_EXIT_SPEED := 0.65
## Max aim yaw from rider forward â€” PI allows shooting directly behind, not past.
const MOUNT_AIM_YAW_LIMIT := PI
## No torso twist while aiming within this arc in front of the horse.
const MOUNT_AIM_SPINE_DEAD_ZONE := deg_to_rad(32.0)
const MOUNT_AIM_SPINE_SMOOTH := 14.0
const MOUNT_DEFEAT_LAUNCH_SPEED := 8.0
const MOUNT_DEFEAT_LAUNCH_UP := 5.5
const HORSE_DEATH_DISMOUNT_DURATION := 0.38
const HORSE_DEATH_DISMOUNT_ARC := 0.45
const HEALTH_REGEN_INTERVAL := 3.0

@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _camera_arm: OverworldCameraArm = $CameraPivot/CameraArm
@onready var _camera: Camera3D = $CameraPivot/CameraArm/Camera3D
@onready var _interact_hint: Label = $InteractHintLayer/HintLabel
@onready var _debug_camera_hud_layer: CanvasLayer = $DebugCameraHudLayer
@onready var _reticle_ui: CanvasLayer = $ReticleUI
@onready var _reticle: Control = $ReticleUI/Reticle
@onready var _scope_overlay: Control = $ReticleUI/ScopeOverlay
@onready var _ammo_hud: AmmoHud = $AmmoHud
@onready var _weapon_select_hud: WeaponSelectHud = $WeaponSelectHud
@onready var _health_vignette: HealthVignetteOverlay = $HealthVignetteOverlay
@onready var _raid_hud: RaidHud = $RaidHud

const AMMO_HUD_SCENE := preload("res://ui/scenes/ammo_hud.tscn")

var _camera_yaw := PI
var _camera_pitch := -0.15
var _locomotion_move_blend := 0.0
var _locomotion_walk_blend := WALK_DIR_WALK_BLEND
var _weapon_rig: GroyperWeaponRig
var _melee_weapon_rig: BaldwinWeaponRig
var _hip_fire_arm_offset_debug: CanvasLayer
var _nearby_interactables := {}
var _dialog_active := false
var _transition_locked := false
var _practice_locked := false
var _practice_saved_ammo := -1
var _practice_infinite_ammo := false

var _equipped_weapon: GroyperWeapons.Id = GroyperWeapons.get_starting_weapon()
var _ammo := 6
## Left dual-wield cylinder (only used while Dual Revolvers are equipped).
var _left_ammo := 6
var _left_ammo_hud: AmmoHud
## Chambered/magazine rounds kept when cycling firearms (not inventory-backed).
var _loaded_ammo_by_weapon: Dictionary = {}
## Persisted left-chamber count for Dual Revolvers (-1 = unset / full on first equip).
var _loaded_left_ammo := -1
## True while a drawn gun is animating into the holster before Unarmed equips.
var _pending_unarmed_equip := false
## Drawn 2H/bow put-away before swapping to another firearm (avoids instant back snap).
var _pending_weapon_equip := false
var _pending_weapon_equip_id: GroyperWeapons.Id = GroyperWeapons.Id.UNARMED
var _pending_weapon_equip_refill := false
## Drawn melee put-away (reverse draw) before swapping off melee.
var _pending_melee_holster := false
var _pending_melee_holster_weapon: GroyperWeapons.Id = GroyperWeapons.Id.UNARMED
var _pending_melee_holster_refill := false
var _shot_cooldown := 0.0
var _left_shot_cooldown := 0.0
var _fire_held := false
var _last_gunshot_msec := -100000

var _reticle_state: RefCounted = PlayerReticleState.new()

var _overworld_combat_active := false
var _overworld_defeated := false
var _death_sequence_active := false
## Boss outro / portal handoff — blocks damage while dialog locks movement.
var _cinematic_invulnerable := false
## Combat i-frames granted on a landed melee strike (see MELEE_HIT_INVULN_DURATION).
var _melee_hit_invuln_timer := 0.0
var _health := BulletHitDamage.PLAYER_MAX_HEALTH
var _health_regen_timer := 0.0
var _combat_hitbox: StaticBody3D
var _aim_ray_exclude_cache: Array[RID] = []
var _aim_ray_exclude_hitbox := RID()
var _aim_ray_query: PhysicsRayQueryParameters3D
var _combat_hurtbox_bone_id := -2  # -2 = not yet resolved against the skeleton
var _interact_hint_last_hint := ""
var _combat_ragdoll
var _duel_hat: GroyperDuelHat
var _deputy_badge: GroyperDeputyBadge

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
var _ads_blend := 0.0
var _scope_was_active := false
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
var _unarmed_blocking := false
var _unarmed_block_blend := 0.0
var _unarmed_block_hold_ready := false
var _unarmed_block_hold_path := StringName()
var _punch_combo_step := MeleePunch.ComboStep.HOOK
var _punch_seek_base := 0.0
var _punch_combo_buffered := false
## Dual-slot crossfade between combo clips (0 = PunchAnim A, 1 = PunchAnim B).
var _punch_cross_slot := 0
var _punch_cross_blend := 0.0
var _punch_crossfade_active := false
var _punch_crossfade_timer := 0.0
var _punch_crossfade_from := 0.0
var _punch_crossfade_to := 0.0
var _punch_crossfade_duration := PunchPoseConfig.COMBO_CROSSFADE
var _punch_hold_seek := 0.0
## True while blending into block after canceling an attack (uses faster blend-in).
var _attack_cancel_into_block := false
## After the punch clip ends, ease model yaw from the strike facing back to
## camera-front / move / lock-on ("face front normally").
var _punch_facing_return_active := false
var _punch_facing_return_from_yaw := 0.0
var _punch_blend_node: AnimationNodeBlend2
var _punch_cross_blend_node: AnimationNodeBlend2
var _punch_anim_node: AnimationNodeAnimation
var _punch_anim_node_b: AnimationNodeAnimation
var _knife_hand_visual: Node3D
var _dynamite_hand_visual: Node3D
var _torch_hand_visual: Node3D
var _flying_kick_active := false
var _flying_kick_timer := 0.0
var _flying_kick_duration := 0.0
var _flying_kick_direction := Vector3.FORWARD
var _flying_kick_struck := false
var _flying_kick_cooldown := 0.0
var _flying_kick_blend := 0.0
var _flying_kick_exit_active := false
var _flying_kick_exit_timer := 0.0
var _flying_kick_trail_timer := 0.0
var _flying_kick_nodes_ready := false
var _flying_kick_blend_node: AnimationNodeBlend2
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
var _vault_for_mount := false
var _vault_for_dismount := false
var _mount_vault_yaw_from := 0.0
var _mount_vault_yaw_to := 0.0
var _dismount_vault_landing := Vector3.ZERO
var _vault_exit_active := false
var _vault_exit_timer := 0.0
var _vault_drop_exit := false
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
var _bonfire_sit_anim_node: AnimationNodeAnimation
# The bonfire pose machine doubles as the chair-sit machine: these paths pick
# which clips it plays, and _sit_chair marks a chair-sit session.
var _pose_sit_down_path: StringName = BonfirePoseConfig.get_stand_up3_reverse_path()
var _pose_stand_up_path: StringName = BonfirePoseConfig.get_stand_up3_path()
var _sit_chair: Node3D
var _chair_sit_library_ready := false
var _bonfire_model_sink := 0.0
var _comet_camera_blend := 0.0
var _comet_camera_target_blend := 0.0
var _comet_camera_target: Node3D
var _comet_cinematic_active := false
var _comet_skip_callback: Callable = Callable()
var _cinematic_walk_active := false
var _cinematic_walk_dir := Vector3.ZERO
var _cinematic_walk_speed := WALK_SPEED
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
var _interior_camera_blend := 0.0
var _interior_camera_slow_return := false
var _debug_camera_remote_edit := false
var _collision_shape: CollisionShape3D

var _locomotion_audio: Node
var _ladder_audio: Node
var _reload_ready_for_tap := false
var _reload_pending_round := false
var _reload_last_phase: GroyperWeaponRig.OverworldReloadPhase = GroyperWeaponRig.OverworldReloadPhase.NONE
var _lasso_controller: LassoController
var _lasso_audio: LassoAudio
var _lasso_rmb_was_held := false
var _lasso_release_float_timer := 0.0
var _lasso_swing_nodes_ready := false
var _lasso_swing_state: RefCounted = PlayerLassoSwingState.new()
var _lasso_swing_blend_node: AnimationNodeBlend2
var _lasso_swing_pose_blend_node: AnimationNodeBlend2
var _lasso_swing_land_blend_node: AnimationNodeBlend2
var _climb_fall_nodes_ready := false
var _climb_fall_state: RefCounted = PlayerClimbFallState.new()
var _climb_fall_blend_node: AnimationNodeBlend2
var _climb_fall_pose_blend_node: AnimationNodeBlend2
var _climb_fall_land_blend_node: AnimationNodeBlend2
var _ladder_climb_nodes_ready := false
var _ladder_state: RefCounted = PlayerLadderState.new()
var _ladder_blend_node: AnimationNodeBlend2
var _ladder_finish_blend_node: AnimationNodeBlend2
var _bow_controller: Node
var _bow_trajectory_preview: MeshInstance3D
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
## Blocks new punches/melee until guard-break stumble/break anim finishes.
var _guard_break_lock_timer := 0.0
var _combat_blocking := false
var _reflect_active := false
var _unarmed_grab_cooldown := 0.0
var _unarmed_grab_window_timer := 0.0
var _unarmed_grab_reach_active := false
var _parry_throw_active := false
var _hostage_take_active := false
var _hostage_controller: Node
var _parry_spin_ready := false
var _parry_spin_duration := 1.4
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
## Two-handed melee support. Swappable combat clips share the melee tree nodes.
var _melee_block_hold_anim_node: AnimationNodeAnimation
var _melee_block_clash_anim_node: AnimationNodeAnimation
var _two_hand_combo_anim_name := StringName()
var _two_hand_combo_active := false
var _melee_hitstop_remaining := 0.0
## True while hitstop is slowing the weapon attack AnimationTree (not punch seek).
var _melee_hitstop_weapon := false
var _hammer_spin_hit_ids: Dictionary = {}
var _hammer_spin_trail_timer := 0.0
var _weapon_throw_nodes_ready := false
var _weapon_throw_active := false
var _weapon_throw_timer := 0.0
var _weapon_throw_duration := 0.0
var _weapon_throw_released := false
var _weapon_throw_exit_active := false
var _weapon_throw_exit_timer := 0.0
var _weapon_throw_blend := 0.0
var _weapon_throw_direction := Vector3.FORWARD
var _weapon_throw_weapon_id: int = GroyperWeapons.Id.UNARMED
var _two_hand_locomotion_nodes_ready := false
var _two_hand_locomotion_blend := 0.0
var _two_hand_locomotion_pos := 0.0
var _knockback_facing_yaw_locked := INF
var _lock_on_active := false
var _lock_on_target: Node3D
var _lock_on_orbit_yaw := 0.0
var _lock_on_blend := 0.0
var _lock_on_camera_blend := 0.0
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
var _face_punch_reaction_active := false
var _face_punch_timer := 0.0
var _face_punch_duration := 0.0
var _face_punch_blend := 0.0
var _face_punch_nodes_ready := false
var _hit_reaction_pose_blend_node: AnimationNodeBlend2
var _hit_reaction_fall_anim_node: AnimationNodeAnimation
var _hit_reaction_stand_anim_node: AnimationNodeAnimation


func _on_actor_ready() -> void:
	add_to_group("overworld_player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")
	_setup_weapon_rig()
	_setup_hip_fire_arm_offset_debug()
	_setup_lasso_controller()
	_setup_bow_controller()
	_setup_hat()
	_setup_deputy_badge()
	_setup_locomotion_audio()
	_setup_ladder_audio()
	OverworldAnimBuilder._setup_locomotion_library(self)
	OverworldAnimBuilder._setup_roll_dodge_library(self)
	OverworldAnimBuilder._setup_punch_pose_library(self)
	OverworldAnimBuilder._setup_flying_kick_library(self)
	OverworldAnimBuilder._setup_unarmed_block_pose_library(self)
	OverworldAnimBuilder._setup_vault_library(self)
	OverworldAnimBuilder._setup_lasso_swing_library(self)
	OverworldAnimBuilder._setup_climb_fall_library(self)
	OverworldAnimBuilder._setup_ladder_climb_library(self)
	_setup_cover_pose_library()
	_setup_bonfire_pose_library()
	_chair_sit_library_ready = ChairSitConfigScript.install_library(_animation_player)
	_setup_parry_throw_library()
	_setup_hit_reaction_library()
	OverworldAnimBuilder._setup_melee_library(self)
	OverworldAnimBuilder._setup_weapon_throw_library(self)
	_unarmed_block_hold_path = UnarmedBlockPoseConfig.get_animation_path()
	_unarmed_block_hold_ready = (
		_animation_player != null
		and _animation_player.has_animation(_unarmed_block_hold_path)
	)
	OverworldAnimBuilder._setup_animation_tree(self)
	call_deferred("_rebind_animation_tree")
	_setup_knife_hand_visual()
	_setup_dynamite_hand_visual()
	_setup_torch_hand_visual()
	_setup_combat_ui()
	_setup_lock_on_indicator()
	_collision_shape = $CollisionShape3D as CollisionShape3D
	_explore_camera_pivot_y = _camera_pivot.position.y
	_camera_arm.bind_owner(self)
	_sync_camera_pivot_yaw()
	_set_camera_arm_pitch()
	_explore_camera_offset = _camera.position
	_explore_camera_fov = _camera.fov
	_aim_fov_current = _explore_camera_fov
	if _debug_camera_hud_layer != null:
		_debug_camera_hud_layer.visible = false
	_update_reticle_limit()
	get_viewport().size_changed.connect(_update_reticle_limit)
	PlayerInventory.inventory_changed.connect(refresh_stowed_weapon_visuals)
	PlayerInventory.inventory_changed.connect(refresh_knife_visual)
	PlayerInventory.inventory_changed.connect(refresh_deputy_badge_visual)
	PlayerInventory.inventory_changed.connect(refresh_melee_equipment)
	PlayerInventory.inventory_changed.connect(_sync_reserve_ammo_hud)
	refresh_stowed_weapon_visuals()
	refresh_knife_visual()
	refresh_deputy_badge_visual()
	refresh_melee_equipment()
	_sync_reserve_ammo_hud()


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


func _setup_dynamite_hand_visual() -> void:
	if _skeleton == null:
		return
	GroyperBodyUtils.ensure_melee_mounts(_skeleton)
	var hand_mount := _skeleton.get_node_or_null("HandSwordMount") as Node3D
	if hand_mount == null:
		return
	var socket := hand_mount.get_node_or_null("GripOffset") as Node3D
	if socket == null:
		socket = hand_mount
	if _dynamite_hand_visual != null and is_instance_valid(_dynamite_hand_visual):
		return
	_dynamite_hand_visual = DYNAMITE_GRIP_SCENE.instantiate()
	_dynamite_hand_visual.name = "DynamiteGrip"
	socket.add_child(_dynamite_hand_visual)
	# Stick sits in the fist similar to the 1H axe seat.
	_dynamite_hand_visual.transform = Transform3D(
		Basis.from_euler(Vector3(PI * 0.5, 0.0, deg_to_rad(-20.0))).scaled(Vector3(0.9, 0.9, 0.9)),
		Vector3(0.01, 0.04, 0.07)
	)
	_dynamite_hand_visual.visible = false


func _sync_dynamite_hand_visual() -> void:
	if _dynamite_hand_visual == null:
		return
	_dynamite_hand_visual.visible = (
		GroyperWeapons.is_dynamite(_equipped_weapon)
		and PlayerInventory.count_weapon(GroyperWeapons.Id.DYNAMITE) > 0
		and not (_weapon_throw_active and _weapon_throw_released)
	)


func _setup_torch_hand_visual() -> void:
	if _skeleton == null:
		return
	GroyperBodyUtils.ensure_melee_mounts(_skeleton)
	var hand_mount := _skeleton.get_node_or_null("HandTorchMount") as Node3D
	if hand_mount == null:
		return
	_torch_hand_visual = hand_mount.get_node_or_null("GripOffset/TorchGrip") as Node3D
	if _torch_hand_visual == null:
		_torch_hand_visual = hand_mount.get_node_or_null("TorchGrip") as Node3D
	if _torch_hand_visual != null:
		_torch_hand_visual.visible = false


func _sync_torch_hand_visual() -> void:
	if _torch_hand_visual == null:
		_setup_torch_hand_visual()
	if _torch_hand_visual == null:
		return
	_torch_hand_visual.visible = (
		GroyperWeapons.is_torch(_equipped_weapon)
		and not (_weapon_throw_active and _weapon_throw_released)
	)


func _apply_torch_melee_anim_set() -> void:
	_two_hand_combo_active = false
	_attack_anim_name = GroyperMeleeAnimConfig.clip_path(GroyperMeleeAnimConfig.CLIP_SWORD_SLASH)
	_attack_reverse_anim_name = GroyperMeleeAnimConfig.clip_path(
		GroyperMeleeAnimConfig.CLIP_SWORD_SLASH_REVERSE
	)
	_spin_attack_anim_name = GroyperMeleeAnimConfig.clip_path(
		GroyperMeleeAnimConfig.CLIP_SPIN_ATTACK
	)
	_spin_attack_reverse_anim_name = GroyperMeleeAnimConfig.clip_path(
		GroyperMeleeAnimConfig.CLIP_SPIN_ATTACK_REVERSE
	)
	if _melee_attack_anim_node != null:
		_melee_attack_anim_node.animation = _attack_anim_name


func sync_dynamite_ammo_hud() -> void:
	_ammo = PlayerInventory.count_weapon(GroyperWeapons.Id.DYNAMITE)
	if _ammo_hud and GroyperWeapons.is_dynamite(_equipped_weapon):
		_ammo_hud.configure_for_weapon(_equipped_weapon)
		_ammo_hud.sync_rounds(_ammo)


func _sync_rpg_grip_rocket() -> void:
	if _weapon_rig == null:
		return
	_weapon_rig.sync_rpg_grip_rocket(_ammo > 0)


func _can_use_dynamite() -> bool:
	return (
		GroyperWeapons.is_dynamite(_equipped_weapon)
		and PlayerInventory.count_weapon(GroyperWeapons.Id.DYNAMITE) > 0
		and not is_melee_stunned()
		and not _hit_reaction_active
		and not _weapon_throw_active
	)


func uses_knife_melee() -> bool:
	return PlayerInventory.has_knife


func refresh_knife_visual() -> void:
	_sync_knife_hand_visual()


func refresh_melee_equipment() -> void:
	if _skeleton == null:
		return
	PlayerInventory.reconcile_owned_sword_shield()

	var equipped_melee := GroyperWeapons.is_melee(_equipped_weapon)
	if equipped_melee and not PlayerInventory.owns_weapon_type(_equipped_weapon):
		# Lost the equipped melee weapon (e.g. new-game reset) — fall back to a gun/fists.
		var fallback := GroyperWeapons.get_starting_weapon()
		if not PlayerInventory.owns_weapon_type(fallback):
			fallback = GroyperWeapons.Id.UNARMED
		equip_weapon(fallback, false)
		return

	GroyperBodyUtils.ensure_melee_mounts(_skeleton)
	# Owned one-handed weapons hang on their own hip holsters whenever owned.
	_sync_melee_holsters()

	if not equipped_melee:
		# Sword & shield leaves the back when nothing melee is in hand; the hip
		# holsters keep displaying any owned one-handed weapons.
		BaldwinBodyUtilsScript.sync_melee_equipment_owned(_skeleton, false)
		_teardown_melee_weapon_rig()
		return

	# The weapon is in hand (or mid-draw): leave it there. Inventory changes fire
	# for unrelated reasons (loot/ammo pickups, drops from defeated enemies) and
	# yanking the weapon back to the holster mid-fight forces a re-draw. The
	# back-grip rebuild below is skipped too — with the grip in hand it would
	# spawn a duplicate at the empty holster socket.
	if (
		_melee_weapon_rig != null
		and (not _melee_weapon_rig.is_holstered() or _melee_weapon_rig.is_transitioning())
	):
		return

	# The equipped weapon's grip is drawn from its own holster by the rig. Only
	# the sword & shield keeps its back grips managed here.
	BaldwinBodyUtilsScript.sync_melee_equipment_owned(
		_skeleton,
		_equipped_weapon == GroyperWeapons.Id.SWORD_SHIELD,
		_equipped_weapon
	)
	if _melee_weapon_rig != null:
		_melee_weapon_rig.reset_to_holster()


## Shows every owned one-handed melee weapon on its own body holster. The equipped
## weapon is carried in-hand by the rig, so its holster sits empty.
func _sync_melee_holsters() -> void:
	if _skeleton == null:
		return
	GroyperBodyUtils.ensure_melee_mounts(_skeleton)
	var owned: Array[int] = []
	for weapon_id in PlayerInventory.get_unique_owned_weapons():
		if GroyperWeapons.is_melee(weapon_id):
			owned.append(weapon_id)
	BaldwinBodyUtilsScript.sync_melee_holsters(_skeleton, owned)


func _ensure_melee_weapon_rig() -> void:
	if _skeleton == null:
		return
	var holster_name := BaldwinBodyUtilsScript.melee_holster_mount_name(_equipped_weapon)
	# Stale rig reuse after gun/fists kept the previous 1H holster mount, so
	# draw pulled the wrong SwordGrip (e.g. bat when Buster Sword was selected).
	if _melee_weapon_rig != null:
		if _melee_weapon_rig.sword_holster_mount_name == holster_name:
			return
		_melee_weapon_rig.reset_to_holster()
		_teardown_melee_weapon_rig()
	GroyperBodyUtils.ensure_melee_mounts(_skeleton)
	if _equipped_weapon == GroyperWeapons.Id.SWORD_SHIELD:
		BaldwinBodyUtilsScript.sync_melee_equipment_owned(_skeleton, true, _equipped_weapon)
	_melee_weapon_rig = BaldwinWeaponRigScript.new()
	_melee_weapon_rig.name = "MeleeWeaponRig"
	add_child(_melee_weapon_rig)
	# Point the rig at the equipped weapon's own holster mount so it draws from
	# (and returns to) the correct body location.
	_melee_weapon_rig.sword_holster_mount_name = holster_name
	_melee_weapon_rig.shield_holster_mount_name = (
		BaldwinBodyUtilsScript.melee_shield_holster_mount_name(_equipped_weapon)
	)
	# One-handed melee weapons share the sword hand mount; two-handers use theirs.
	_melee_weapon_rig.sword_hand_mount_name = BaldwinBodyUtilsScript.melee_hand_mount_name(
		_equipped_weapon
	)
	_melee_weapon_rig.sword_hand_grip_local = BaldwinBodyUtilsScript.melee_hand_grip_local(
		_equipped_weapon
	)
	_melee_weapon_rig.setup(self, _skeleton)
	_melee_weapon_rig.set_release_arms_when_idle(false)
	_apply_melee_weapon_anim_set()


func _equip_melee_weapon() -> void:
	_ensure_melee_weapon_rig()
	if _melee_weapon_rig == null:
		return
	if _melee_weapon_rig.is_holstered() and not _melee_weapon_rig.is_transitioning():
		_melee_weapon_rig.begin_draw()


## Points the shared melee tree nodes at the equipped weapon's clip set. One-handed
## weapons use the sword-slash animations; two-handers use the two_handed library.
func _apply_melee_weapon_anim_set() -> void:
	_two_hand_combo_active = false
	if GroyperWeapons.is_two_handed_melee(_equipped_weapon):
		_attack_anim_name = TwoHandedConfigScript.clip_path(TwoHandedConfigScript.CLIP_ATTACK)
		_two_hand_combo_anim_name = TwoHandedConfigScript.clip_path(TwoHandedConfigScript.CLIP_COMBO)
		_attack_reverse_anim_name = _attack_anim_name
		_spin_attack_anim_name = TwoHandedConfigScript.clip_path(TwoHandedConfigScript.CLIP_SPIN_ATTACK)
		_spin_attack_reverse_anim_name = _spin_attack_anim_name
		if _melee_block_hold_anim_node != null:
			_melee_block_hold_anim_node.animation = TwoHandedConfigScript.clip_path(
				TwoHandedConfigScript.CLIP_BLOCK_HOLD
			)
		if _melee_block_clash_anim_node != null:
			_melee_block_clash_anim_node.animation = TwoHandedConfigScript.clip_path(
				TwoHandedConfigScript.CLIP_PARRY
			)
	else:
		_attack_anim_name = GroyperMeleeAnimConfig.clip_path(GroyperMeleeAnimConfig.CLIP_SWORD_SLASH)
		_attack_reverse_anim_name = GroyperMeleeAnimConfig.clip_path(
			GroyperMeleeAnimConfig.CLIP_SWORD_SLASH_REVERSE
		)
		_spin_attack_anim_name = GroyperMeleeAnimConfig.clip_path(
			GroyperMeleeAnimConfig.CLIP_SPIN_ATTACK
		)
		_spin_attack_reverse_anim_name = GroyperMeleeAnimConfig.clip_path(
			GroyperMeleeAnimConfig.CLIP_SPIN_ATTACK_REVERSE
		)
		if _melee_block_hold_anim_node != null:
			_melee_block_hold_anim_node.animation = _get_one_hand_block_hold_path()
		if _melee_block_clash_anim_node != null:
			_melee_block_clash_anim_node.animation = GroyperMeleeAnimConfig.clip_path(
				GroyperMeleeAnimConfig.CLIP_BLOCK_CLASH
			)
	if _melee_attack_anim_node != null:
		_melee_attack_anim_node.animation = _attack_anim_name


## Sword & shield blocks behind the shield; the shieldless one-handers (axe,
## sword) hold block with the two-hander's brace pose, extracted to its own
## editable clip (two_handed/block_hold_1h).
func _get_one_hand_block_hold_path() -> StringName:
	if not GroyperWeapons.melee_uses_shield(_equipped_weapon):
		var no_shield_path := TwoHandedConfigScript.clip_path(
			TwoHandedConfigScript.CLIP_BLOCK_HOLD_1H
		)
		if _animation_player != null and _animation_player.has_animation(no_shield_path):
			return no_shield_path
	return GroyperMeleeAnimConfig.clip_path(GroyperMeleeAnimConfig.CLIP_BLOCK_HOLD)


func _holster_melee_weapon() -> void:
	if _melee_weapon_rig == null:
		return
	# Instant snap — used for teardown / home reset. Animated put-away goes
	# through begin_holster() via the pending-melee-holster equip path.
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

	_apply_worn_hat(false)
	PlayerInventory.worn_hat_changed.connect(_on_worn_hat_changed)


func _on_worn_hat_changed(hat_id: StringName) -> void:
	# Equip feedback only when gaining a hat outside the paused inventory menu.
	_apply_worn_hat(not hat_id.is_empty() and not get_tree().paused)


## Rebuilds the head mount + duel-hat controller to match the worn hat.
## Unique hats swap in their own mount scene; the runtime node keeps the
## "CowboyHatMount" name that GroyperDuelHat and the ragdoll look up.
func _apply_worn_hat(play_equip_sound: bool) -> void:
	if _skeleton == null:
		return

	var worn: StringName = PlayerInventory.get_worn_hat()
	_swap_hat_mount(worn)

	if _duel_hat != null:
		_duel_hat.queue_free()
	_duel_hat = DUEL_HAT_SCRIPT.new()
	_duel_hat.name = "DuelHat"
	add_child(_duel_hat)

	var material: Material = null
	var override_materials := true
	if not worn.is_empty():
		material = HatCatalogScript.create_worn_material(worn)
		override_materials = material != null
	_duel_hat.bind_skeleton(_skeleton, material, override_materials)
	_duel_hat.prepare_for_round(worn.is_empty(), play_equip_sound)


func _swap_hat_mount(hat_id: StringName) -> void:
	var old_mount := _skeleton.get_node_or_null("CowboyHatMount")
	if old_mount != null:
		_skeleton.remove_child(old_mount)
		old_mount.queue_free()

	var mount_id := hat_id if not hat_id.is_empty() else PlayerInventory.COWBOY_HAT_ID
	var packed := load(HatCatalogScript.get_mount_scene_path(mount_id)) as PackedScene
	if packed == null:
		push_warning("GroyperOverworldPlayer: missing hat mount scene for %s." % mount_id)
		return
	var mount := packed.instantiate()
	mount.name = "CowboyHatMount"
	_skeleton.add_child(mount)


func get_duel_hat() -> GroyperDuelHat:
	return _duel_hat


## Worn hat id for the ragdoll's collectible hat drop (empty = bareheaded).
func get_hat_collectible_id() -> StringName:
	return PlayerInventory.get_worn_hat()


## Ragdoll knocked the worn hat into the world — it leaves inventory until
## the auto-pickup on the ground returns it to the hat mount.
func on_hat_knocked_off(hat_id: StringName) -> void:
	if hat_id.is_empty():
		return
	PlayerInventory.remove_hat(hat_id)


func get_raid_hud() -> RaidHud:
	return _raid_hud


func _setup_deputy_badge() -> void:
	if _skeleton == null or _deputy_badge != null:
		return

	_deputy_badge = DEPUTY_BADGE_SCRIPT.new()
	_deputy_badge.name = "DeputyBadge"
	add_child(_deputy_badge)
	_deputy_badge.bind_skeleton(_skeleton)


func refresh_deputy_badge_visual() -> void:
	if _deputy_badge == null and _skeleton != null:
		_setup_deputy_badge()
	if _deputy_badge != null:
		_deputy_badge.refresh_badge_visual()


func _setup_weapon_rig() -> void:
	if _skeleton == null:
		return

	GroyperBodyUtils.ensure_weapon_mounts(_skeleton)
	GroyperBodyUtils.ensure_bow_back_mounts(_skeleton)

	_weapon_rig = WEAPON_RIG_SCRIPT.new()
	_weapon_rig.name = "WeaponRig"
	_weapon_rig.enable_overworld_hold_mode(true)
	add_child(_weapon_rig)
	_weapon_rig.setup(self, _skeleton, _equipped_weapon)
	_weapon_rig.draw_state_changed.connect(_on_weapon_draw_state_changed)


func _setup_hip_fire_arm_offset_debug() -> void:
	_hip_fire_arm_offset_debug = HipFireArmOffsetDebugScript.new()
	_hip_fire_arm_offset_debug.name = "HipFireArmOffsetDebug"
	add_child(_hip_fire_arm_offset_debug)
	_hip_fire_arm_offset_debug.setup(self)


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
	_lasso_audio = LassoAudioScript.new()
	_lasso_audio.name = "LassoAudio"
	add_child(_lasso_audio)
	_lasso_audio.setup(self, _lasso_controller)


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
	_bow_trajectory_preview = BowTrajectoryPreviewScript.new()
	_bow_trajectory_preview.name = "BowTrajectoryPreview"
	add_child(_bow_trajectory_preview)


func _setup_locomotion_audio() -> void:
	_locomotion_audio = LocomotionAudioScript.new()
	_locomotion_audio.name = "LocomotionAudio"
	add_child(_locomotion_audio)
	_locomotion_audio.setup(self)


func _setup_ladder_audio() -> void:
	_ladder_audio = LadderAudio.new()
	_ladder_audio.name = "LadderAudio"
	add_child(_ladder_audio)
	_ladder_audio.setup(self)


func _update_ladder_audio(climbing: bool, sprint_climb: bool, sliding: bool) -> void:
	if _ladder_audio != null:
		_ladder_audio.update(climbing, sprint_climb, sliding)


func _stop_ladder_audio() -> void:
	if _ladder_audio != null:
		_ladder_audio.stop()


## Initial round count when a weapon becomes active. The bow draws from its
## persistent arrow reserve instead of refilling to max like other weapons.
func _initial_ammo_for(weapon_id: int) -> int:
	if weapon_id == GroyperWeapons.Id.BOW:
		return PlayerInventory.get_bow_ammo()
	if weapon_id == GroyperWeapons.Id.DYNAMITE:
		return PlayerInventory.count_weapon(GroyperWeapons.Id.DYNAMITE)
	return GroyperWeapons.get_max_ammo(weapon_id)


## True when chambered rounds live on the player (not bow/dynamite inventory).
func _tracks_loaded_ammo(weapon_id: int) -> bool:
	if not GroyperWeapons.uses_ammo(weapon_id):
		return false
	if weapon_id == GroyperWeapons.Id.BOW or weapon_id == GroyperWeapons.Id.DYNAMITE:
		return false
	return true


func _store_current_loaded_ammo() -> void:
	if not _tracks_loaded_ammo(_equipped_weapon):
		return
	_loaded_ammo_by_weapon[int(_equipped_weapon)] = _ammo
	if GroyperWeapons.is_dual_wield(_equipped_weapon):
		_loaded_left_ammo = _left_ammo


func _resolve_ammo_on_equip(weapon_id: int, refill_ammo: bool) -> int:
	if weapon_id == GroyperWeapons.Id.BOW:
		return PlayerInventory.get_bow_ammo()
	if weapon_id == GroyperWeapons.Id.DYNAMITE:
		return PlayerInventory.count_weapon(GroyperWeapons.Id.DYNAMITE)
	if not _tracks_loaded_ammo(weapon_id):
		return 0
	if refill_ammo:
		var full := GroyperWeapons.get_max_ammo(weapon_id)
		_loaded_ammo_by_weapon[weapon_id] = full
		return full
	if _loaded_ammo_by_weapon.has(weapon_id):
		return clampi(
			int(_loaded_ammo_by_weapon[weapon_id]),
			0,
			GroyperWeapons.get_max_ammo(weapon_id)
		)
	# First time equipping this firearm: start loaded; remember for later swaps.
	var initial := GroyperWeapons.get_max_ammo(weapon_id)
	_loaded_ammo_by_weapon[weapon_id] = initial
	return initial


func _resolve_left_ammo_on_equip(refill_ammo: bool) -> int:
	var max_ammo := GroyperWeapons.get_max_ammo(GroyperWeapons.Id.DUAL_REVOLVER)
	if refill_ammo or _loaded_left_ammo < 0:
		_loaded_left_ammo = max_ammo
		return max_ammo
	return clampi(_loaded_left_ammo, 0, max_ammo)


func _is_dual_wield_equipped() -> bool:
	return GroyperWeapons.is_dual_wield(_equipped_weapon)


func _setup_left_ammo_hud() -> void:
	if _left_ammo_hud != null:
		return
	_left_ammo_hud = AMMO_HUD_SCENE.instantiate() as AmmoHud
	_left_ammo_hud.name = "LeftAmmoHud"
	add_child(_left_ammo_hud)
	_left_ammo_hud.anchor_bottom_left()
	_left_ammo_hud.visible = false


func _sync_left_ammo_hud(animate_shot: bool = false, reset_display: bool = false) -> void:
	if _left_ammo_hud == null:
		return
	if not _is_dual_wield_equipped():
		_left_ammo_hud.visible = false
		return
	if reset_display:
		_left_ammo_hud.configure_for_weapon(GroyperWeapons.Id.DUAL_REVOLVER)
		_left_ammo_hud.set_show_reserve(false)
	_left_ammo_hud.sync_rounds(_left_ammo, animate_shot, reset_display)
	_left_ammo_hud.sync_gem_stamina(false, 0.0, Color.WHITE)


func _setup_combat_ui() -> void:
	_setup_left_ammo_hud()
	_ammo = _initial_ammo_for(_equipped_weapon)
	if _tracks_loaded_ammo(_equipped_weapon):
		_loaded_ammo_by_weapon[int(_equipped_weapon)] = _ammo
	if _is_dual_wield_equipped():
		_left_ammo = _resolve_left_ammo_on_equip(true)
	if _ammo_hud:
		_ammo_hud.configure_for_weapon(_equipped_weapon)
		_ammo_hud.sync_rounds(_ammo)
		_ammo_hud.sync_reserve_ammo(PlayerInventory.get_weapon_reserve_ammo(_equipped_weapon))
		_ammo_hud.visible = false
	_sync_left_ammo_hud(false, true)
	if _left_ammo_hud:
		_left_ammo_hud.visible = false
	if _reticle_ui:
		_reticle_ui.visible = false
	_update_health_vignette()


func _process(delta: float) -> void:
	if _overworld_defeated:
		return

	ElementalGemStaminaScript.tick(delta)
	_sync_gem_stamina_hud()

	if _overworld_combat_active and not _overworld_defeated:
		_sync_combat_hitbox_position()

	if _is_fully_mounted():
		_follow_mounted_horse()

	_update_lasso(delta)
	_update_bow(delta)

	if (_transition_locked or _is_dialog_frozen()) and not _practice_locked:
		# Keep aim/comet camera live while blending out even after the cinematic
		# flag clears — otherwise transition-locked shots freeze mid-return.
		if _is_dialog_frozen() or _comet_cinematic_active or _comet_camera_blend > 0.001:
			_update_aim_camera(delta)
		if _parry_throw_active:
			_sync_camera_pivot_yaw()
			_set_camera_arm_pitch()
		return

	_shot_cooldown = maxf(_shot_cooldown - delta, 0.0)
	_left_shot_cooldown = maxf(_left_shot_cooldown - delta, 0.0)
	_reticle_state.decay_recoil(delta)
	_update_melee_camera(delta)
	_update_aim_camera(delta)
	_update_two_hand_locomotion(delta)

	if GroyperWeapons.is_melee(_equipped_weapon):
		_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
		if _melee_weapon_rig != null:
			_melee_weapon_rig.update(delta)
			_melee_weapon_rig.apply_pose_overrides(delta)
		_try_finish_pending_melee_holster()
		if _pending_melee_holster:
			_update_combat_ui()
			_update_overworld_health(delta)
			return
		_update_melee_block_hold_blend_state(delta)
		_update_melee_input_hold()
		_update_combat_idle_blend(delta)
		_update_combat_ui()
		_update_overworld_health(delta)
		_punch_cooldown = maxf(_punch_cooldown - delta, 0.0)
		_reflect_cooldown = maxf(_reflect_cooldown - delta, 0.0)
		return

	if GroyperWeapons.is_torch(_equipped_weapon):
		_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
		# Dynamite-style brace uses the sword block-hold blend as throw windup.
		_update_melee_block_hold_blend_state(delta)
		_update_melee_input_hold()
		_update_combat_ui()
		_update_overworld_health(delta)
		_punch_cooldown = maxf(_punch_cooldown - delta, 0.0)
		if _weapon_rig != null:
			_weapon_rig.update(delta, _get_arm_aim_world_target())
		return

	if GroyperWeapons.is_dynamite(_equipped_weapon):
		# Sword & shield block-hold blend (pose only) — right arm back as throw windup.
		_update_melee_block_hold_blend_state(delta)
		_update_melee_input_hold()
		_update_combat_ui()
		_update_overworld_health(delta)
		_punch_cooldown = maxf(_punch_cooldown - delta, 0.0)
		_unarmed_grab_cooldown = maxf(_unarmed_grab_cooldown - delta, 0.0)
		_unarmed_grab_window_timer = maxf(_unarmed_grab_window_timer - delta, 0.0)
		_flying_kick_cooldown = maxf(_flying_kick_cooldown - delta, 0.0)
		_guard_break_lock_timer = maxf(_guard_break_lock_timer - delta, 0.0)
		if _weapon_rig != null:
			# Keep guns holstered while dynamite is out.
			_weapon_rig.update(delta, _get_arm_aim_world_target())
		return

	if _melee_weapon_rig != null and _melee_weapon_rig.is_transitioning():
		_melee_weapon_rig.update(delta)
		_melee_weapon_rig.apply_pose_overrides(delta)

	if _weapon_rig == null:
		return

	_update_mount_aim_spine(delta)

	var aim_target := _get_arm_aim_world_target()
	_update_run_and_gun(delta)
	_weapon_rig.update(delta, aim_target)

	if _should_update_reticle():
		_update_reticle(delta)
	elif _reticle:
		_reset_reticle_state()
		_reticle.set_screen_offset(Vector2.ZERO)

	_update_scope_blend(delta)
	_update_combat_ui()
	_update_overworld_health(delta)
	_update_overworld_reload(delta)

	if _fire_held and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_fire_held = false
	if _fire_held and GroyperWeapons.is_full_auto(_equipped_weapon) \
			and not GroyperWeapons.is_bow(_equipped_weapon):
		_try_shoot()

	_punch_cooldown = maxf(_punch_cooldown - delta, 0.0)
	_unarmed_grab_cooldown = maxf(_unarmed_grab_cooldown - delta, 0.0)
	_unarmed_grab_window_timer = maxf(_unarmed_grab_window_timer - delta, 0.0)
	_flying_kick_cooldown = maxf(_flying_kick_cooldown - delta, 0.0)
	_guard_break_lock_timer = maxf(_guard_break_lock_timer - delta, 0.0)
	if _hostage_take_active or _melee_block_hold_blend > 0.001 or _block_walk_amount > 0.001:
		_update_melee_block_hold_blend_state(delta)
	if not _can_use_sword_shield_melee():
		_update_unarmed_block_input_hold()
		_update_unarmed_block_blend_state(delta)


func _input(event: InputEvent) -> void:
	if (
		_comet_cinematic_active
		and event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_MIDDLE
		and event.pressed
	):
		if _comet_skip_callback.is_valid():
			_comet_skip_callback.call()
		get_viewport().set_input_as_handled()
		return

	if _transition_locked and not _bonfire_movement_unlocked and not BonfireMenuManager.is_showing():
		# Armory / extract / hub chest menus open while portal extract keeps the
		# player transition-locked. Swallowing input here starves Control buttons
		# and soft-locks those pickers — let GUI + their _input through.
		if _is_debug_ui_blocking():
			return
		# During the parry throw spin the player steers the toss with the
		# camera, so mouse look stays live while everything else is locked.
		if (
			_parry_throw_active
			and event is InputEventMouseMotion
			and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
		):
			_apply_explore_mouse_look(event.relative)
		# Cutscenes (comet narration, town intro) show dialog while
		# transition-locked; marking clicks handled here would also starve the
		# dialog box's GUI, soft-locking the sequence. Advance lines directly
		# and let mouse events fall through to choice buttons.
		if DialogManager.is_showing():
			_sync_dialog_mouse_mode()
			if (
				DialogManager.is_showing_choices()
				and (event is InputEventMouseButton or event is InputEventMouseMotion)
			):
				return
			if (
				event is InputEventMouseButton
				and event.pressed
				and event.button_index == MOUSE_BUTTON_LEFT
				and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
			):
				DialogManager.advance_line()
		get_viewport().set_input_as_handled()
		return

	if InventoryMenuManager.is_open():
		return

	if TownMapManager.is_open():
		return

	# Debug armory chest / terminal: keep cursor free for click + scroll.
	if _is_debug_ui_blocking():
		return

	if _is_dialog_frozen() or ShopBuyManager.is_showing() or BonfireMenuManager.is_showing():
		if _is_dialog_frozen():
			_sync_dialog_mouse_mode()
			if (
				event is InputEventMouseMotion
				and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
			):
				_apply_explore_mouse_look(event.relative)
				get_viewport().set_input_as_handled()
			elif (
				event is InputEventMouseButton
				and event.pressed
				and event.button_index == MOUSE_BUTTON_LEFT
				and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
			):
				DialogManager.advance_line()
				get_viewport().set_input_as_handled()
		if (
			event is InputEventKey
			and event.pressed
			and event.keycode == KEY_E
		):
			_try_interact()
		return

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if _comet_cinematic_active:
			get_viewport().set_input_as_handled()
			return
		if _is_lock_on_engaged():
			_apply_lock_on_mouse_look(event.relative)
			get_viewport().set_input_as_handled()
			return
		var use_reticle := (
			_weapon_rig != null
			and _weapon_rig.can_use_reticle()
			and not _is_mounted()
		)
		if use_reticle:
			if _is_scope_aim_active():
				_apply_scope_look(event.relative)
			elif _is_run_and_gun_weapon():
				# Run-and-gun: the crosshair stays centered; mouse turns the camera.
				_apply_explore_mouse_look(event.relative)
			else:
				_reticle_state.add_mouse_motion(event.relative, _get_reticle_mouse_accel())
		else:
			_apply_explore_mouse_look(event.relative)
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
			# Default sprint attack when the equipped weapon has no sprint move of its own.
			if event.pressed and _can_punch() and _can_start_flying_kick():
				_start_flying_kick()
				get_viewport().set_input_as_handled()
			elif _can_use_sword_shield_melee():
				if event.pressed:
					_try_begin_melee_attack()
			elif _can_use_dynamite():
				if event.pressed:
					if _combat_blocking:
						_try_begin_weapon_throw()
					else:
						_try_drop_lit_dynamite()
			elif GroyperWeapons.is_bow(_equipped_weapon):
				if event.pressed and _ammo > 0:
					_bow_lmb_was_held = true
				elif not event.pressed:
					_bow_lmb_was_held = false
			elif GroyperWeapons.is_unarmed(_equipped_weapon):
				if event.pressed:
					if _hostage_take_active:
						_try_hostage_shove()
					else:
						_try_punch()
			elif _is_dual_wield_equipped():
				# Dual: LMB = left gun (no hold-to-fire / full-auto).
				if event.pressed:
					_try_shoot_hand(true)
				_fire_held = false
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
		if _comet_cinematic_active:
			if _comet_skip_callback.is_valid():
				_comet_skip_callback.call()
			get_viewport().set_input_as_handled()
		elif Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			# Holster whatever is out and switch the weapon wheel to fists.
			equip_weapon(GroyperWeapons.Id.UNARMED, false)
			_show_weapon_select_hud()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		elif GroyperWeapons.is_melee(_equipped_weapon):
			if event.pressed:
				_try_begin_melee_blocking()
			else:
				_try_end_melee_blocking()
		elif GroyperWeapons.is_dynamite(_equipped_weapon):
			if event.pressed:
				_try_begin_dynamite_brace()
			else:
				_try_end_melee_blocking()
		elif GroyperWeapons.is_torch(_equipped_weapon):
			if event.pressed:
				_try_begin_torch_brace()
			else:
				_try_end_melee_blocking()
		elif GroyperWeapons.is_unarmed(_equipped_weapon):
			pass  # RMB block-hold is polled in _update_unarmed_block_input_hold.
		elif _is_dual_wield_equipped():
			# Dual: RMB = right gun (no ADS).
			if event.pressed:
				_try_shoot_hand(false)
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
	elif (
		event is InputEventKey
		and event.pressed
		and not event.echo
		and event.keycode == DEBUG_COLLISION_PRINT_KEY
	):
		_debug_print_current_collisions()
		get_viewport().set_input_as_handled()
	elif (
		event is InputEventKey
		and event.pressed
		and not event.echo
		and event.keycode == DEBUG_CAMERA_PRINT_KEY
	):
		if event.shift_pressed:
			_set_debug_camera_remote_edit(not _debug_camera_remote_edit)
		else:
			_debug_print_camera_state()
		get_viewport().set_input_as_handled()
	elif (
		event is InputEventKey
		and event.pressed
		and not event.echo
		and event.keycode == DEBUG_ARM_OFFSET_KEY
	):
		if _hip_fire_arm_offset_debug != null:
			_hip_fire_arm_offset_debug.toggle()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		if _ladder_state.active:
			_ladder_state.try_jump_off(self)
		elif _mounted_horse == null:
			_try_cover_or_roll_action()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == PUNCH_KEY:
		_try_punch()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == UNARMED_GRAB_KEY and not _can_use_sword_shield_melee():
		_try_begin_unarmed_grab()


func _physics_process(delta: float) -> void:
	if _overworld_defeated:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	_melee_hit_invuln_timer = maxf(_melee_hit_invuln_timer - delta, 0.0)

	# Purely visual fade on the kick overlay — must keep ticking through every
	# early-return state (stun, dialog, hit reaction) or the pose freezes.
	if _flying_kick_exit_active:
		_update_flying_kick_exit(delta)

	# Same for the weapon-throw pitch overlay: it must keep advancing (and
	# release the projectile) no matter what locomotion state the body is in.
	if _weapon_throw_active or _weapon_throw_exit_active:
		_update_weapon_throw(delta)

	var freeze_player := (
		(_transition_locked and not _bonfire_movement_unlocked)
		or _practice_locked
		or _dialog_active
		or DialogManager.is_showing()
		or InventoryMenuManager.is_open()
		or TownMapManager.is_open()
		or ShopBuyManager.is_showing()
		or BonfireMenuManager.is_showing()
		or _is_debug_ui_blocking()
	)

	# Always advance knockdown recovery first. Menus / other early returns used to
	# leave HitReactionBlend stuck, which breaks walk + punch until aiming overrides
	# the skeleton pose.
	if _hit_reaction_active:
		if freeze_player and _hit_reaction_control_unlocked:
			_finish_hit_reaction()
		else:
			_update_hit_reaction(delta)
			if not _hit_reaction_control_unlocked:
				_sync_camera_pivot_yaw()
				_set_camera_arm_pitch()
				_update_interact_hint()
				return

	if _face_punch_reaction_active:
		_update_face_punch_reaction(delta)
		velocity = Vector3.ZERO
		move_and_slide()
		_sync_camera_pivot_yaw()
		_set_camera_arm_pitch()
		_update_interact_hint()
		return

	if freeze_player:
		if _cinematic_walk_active:
			_apply_cinematic_walk(delta)
			_update_interact_hint()
			return
		if _is_dialog_frozen():
			_sync_dialog_mouse_mode()
		velocity = Vector3.ZERO
		move_and_slide()
		if _is_bonfire_pose_active():
			_update_bonfire_pose(delta)
		else:
			_update_locomotion_blend(delta, 0.0, WALK_SPEED, RUN_SPEED)
		_sync_camera_pivot_yaw()
		_set_camera_arm_pitch()
		if _is_dialog_frozen():
			_apply_camera_offset(_get_active_explore_camera_offset())
		_update_interact_hint()
		return

	_update_lock_on(delta)

	if _lasso_controller != null:
		_update_lasso_controller(delta)

	if _cover_walk_enter_active:
		_update_cover_walk_enter(delta)
		_sync_camera_pivot_yaw()
		_set_camera_arm_pitch()
		_update_interact_hint()
		return

	if _cover_exit_active:
		_update_cover_exit(delta)
		_sync_camera_pivot_yaw()
		_set_camera_arm_pitch()
		_update_interact_hint()
		return

	if _cover_crouch_active:
		_update_cover_crouch(delta)
		_sync_camera_pivot_yaw()
		_set_camera_arm_pitch()
		_update_interact_hint()
		return

	if _vault_active:
		_update_vault(delta)
		_sync_camera_pivot_yaw()
		_set_camera_arm_pitch()
		_update_interact_hint()
		return

	if _roll_active:
		_update_roll_dodge(delta)
		_sync_camera_pivot_yaw()
		_set_camera_arm_pitch()
		_update_interact_hint()
		return

	if _flying_kick_active:
		_update_flying_kick(delta)
		_sync_camera_pivot_yaw()
		_set_camera_arm_pitch()
		_update_interact_hint()
		return

	if _ladder_state.active:
		_ladder_state.update(self, delta)
		return

	if _lasso_controller != null and _lasso_controller.is_tightening():
		_lasso_swing_state.update_tighten(self, delta)
		_sync_camera_pivot_yaw()
		_set_camera_arm_pitch()
		_update_interact_hint()
		return

	if _mount_transition_active:
		velocity = Vector3.ZERO
		move_and_slide()
		_sync_camera_pivot_yaw()
		_set_camera_arm_pitch()
		_update_interact_hint()
		return

	if GroyperWeapons.is_melee(_equipped_weapon) and _melee_weapon_rig != null and _melee_weapon_rig.is_equipped():
		if _reflect_active:
			_process_shield_reflect(delta)
			return
		if _combat_attacking:
			_process_melee_attack(delta)
			return
		if _combat_blocking:
			_process_melee_blocking(delta)
			return

	if GroyperWeapons.is_torch(_equipped_weapon) and _combat_attacking:
		_process_melee_attack(delta)
		return

	if GroyperWeapons.is_torch(_equipped_weapon) and _combat_blocking and not _weapon_throw_active:
		_process_melee_blocking(delta)
		return

	# Dynamite brace reuses sword & shield block-hold locomotion (pose only).
	if GroyperWeapons.is_dynamite(_equipped_weapon) and _combat_blocking and not _weapon_throw_active:
		_process_melee_blocking(delta)
		return

	if _is_fully_mounted():
		if _mounted_horse.has_method("is_horse_defeated") and _mounted_horse.is_horse_defeated():
			if not _mount_transition_active:
				_fall_off_dead_horse({})
			velocity = Vector3.ZERO
			move_and_slide()
			_sync_camera_pivot_yaw()
			_set_camera_arm_pitch()
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
		_sync_camera_pivot_yaw()
		_set_camera_arm_pitch()
		_update_interact_hint()
		return

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = minf(velocity.y, 0.0)

	tick_melee_stun(delta)
	if is_melee_stunned():
		# Blocked punch: keep the swing/combo ticking through knockback instead
		# of freezing the overlay (and missing the strike) on the early-return.
		if _punch_active:
			_update_punch_overlay(delta)
			_apply_punch_strike_if_ready()
		apply_knockback_friction(delta)
		# Punched (not knocked down): the player keeps slow steering through
		# the reaction. Knockback preservation still wins while it holds.
		if _face_punch_reaction_active and not should_preserve_knockback_velocity():
			var stun_input := _get_camera_relative_input()
			var stun_target := stun_input * WALK_SPEED * FACE_PUNCH_STUN_MOVE_MULT
			var stun_h := Vector3(velocity.x, 0.0, velocity.z)
			stun_h = stun_h.move_toward(stun_target, MOVE_ACCEL * FACE_PUNCH_STUN_MOVE_MULT * delta)
			velocity.x = stun_h.x
			velocity.z = stun_h.z
		move_with_ground_snap()
		_update_climb_fall(delta)
		var stunned_h := Vector3(velocity.x, 0.0, velocity.z)
		# Keep pre-shove facing through the whole knockback slide (clash, hits).
		# Facing into momentum spins the player away from the enemy they struck.
		# Punch-exit yaw return is owned by _update_punch_overlay — don't fight it.
		if _punch_facing_return_active or _is_punch_finisher_aiming():
			pass
		elif _should_preserve_knockback_facing(stunned_h):
			_preserve_knockback_facing()
		elif _punch_active and not _punch_exit_active and _model != null:
			# Clash shove can be brief; hold punch facing even after the hold ends.
			_preserve_knockback_facing()
		_update_locomotion_blend(delta, stunned_h.length(), WALK_SPEED, RUN_SPEED)
		_sync_camera_pivot_yaw()
		_set_camera_arm_pitch()
		_update_interact_hint()
		return

	if _hostage_take_active:
		_process_hostage_locomotion(delta)
		return

	if _is_unarmed_block_pose_active():
		_process_unarmed_blocking(delta)
		return

	if _punch_active:
		_update_punch_overlay(delta)

	if _is_bonfire_pose_active():
		_update_bonfire_pose(delta)

	var move_dir := _get_camera_relative_input()
	if _weapon_throw_active:
		# Feet plant for the pitch: WASD is ignored (the player decelerates to a
		# stop) while mouse look stays live so the throw can still be aimed.
		move_dir = Vector3.ZERO
	# Run-and-gun: firearms move at full speed while hip-aiming; only ADS (and
	# the legacy hold-to-aim weapons like bow/lasso) slows the player down.
	var slow_aim_stance := _is_slow_aim_stance()
	var wants_sprint := Input.is_key_pressed(KEY_SHIFT) and not slow_aim_stance and not _hostage_take_active
	var sprinting := wants_sprint and move_dir.length_squared() > 0.0001
	var walk_speed := AIM_WALK_SPEED if slow_aim_stance else WALK_SPEED
	var run_speed := AIM_RUN_SPEED if slow_aim_stance else RUN_SPEED
	if slow_aim_stance and move_dir.length_squared() > 0.0001:
		walk_speed = _get_aim_walk_speed_for_direction(move_dir, walk_speed)
	var carry_mult := GroyperWeapons.get_carry_move_speed_mult(
		_equipped_weapon,
		PlayerInventory.get_strength()
	)
	walk_speed *= carry_mult
	run_speed *= carry_mult
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

	var new_h := current_h
	if not should_preserve_knockback_velocity():
		new_h = current_h.move_toward(target_h, move_rate * delta)
		velocity.x = new_h.x
		velocity.z = new_h.z
	_push_intent = target_h
	_apply_punch_strike_if_ready()
	move_with_ground_snap()
	_update_climb_fall(delta)

	if _punch_facing_return_active or _is_punch_finisher_aiming():
		# Punch-exit yaw return / finisher aim are advanced in _update_punch_overlay.
		pass
	elif _should_preserve_knockback_facing(new_h):
		_preserve_knockback_facing()
	elif _weapon_throw_active:
		# Mid-pitch: stay square to the throw line even while backpedaling, or
		# the pitch plays facing the camera when walking backwards.
		_face_flat_direction(delta, _weapon_throw_direction)
	else:
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

	_sync_camera_pivot_yaw()
	_set_camera_arm_pitch()
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
	# Scope aim (AWP) is seeded from the RMB/ADS transition in
	# _update_run_and_gun; leaving the aim state just clears it.
	if new_state != GroyperWeaponRig.DrawState.AIMING:
		_reset_scope_aim()
		_scope_was_active = false
	if _is_mounted() and new_state == GroyperWeaponRig.DrawState.DRAWING:
		_mount_spine_yaw = 0.0
		if _weapon_rig != null:
			_weapon_rig.set_mount_aim_spine_yaw(0.0)
	_try_finish_pending_unarmed_equip()
	_try_finish_pending_weapon_equip()
	_try_finish_pending_melee_holster()


func _update_saddle_gun_arm_filter(draw_state: GroyperWeaponRig.DrawState) -> void:
	if _saddle_blend_node == null or _mounted_horse == null:
		return
	var saddle_owns_gun_arm := draw_state == GroyperWeaponRig.DrawState.HOLSTERED
	if _weapon_rig != null and _weapon_rig.is_overworld_reloading():
		saddle_owns_gun_arm = false
	SaddlePoseConfig.set_gun_arm_blend_filtered(_saddle_blend_node, saddle_owns_gun_arm)


func _update_cover_peek_gun_arm_filter(_draw_state: GroyperWeaponRig.DrawState) -> void:
	if _cover_peek_blend_node == null or not _cover_crouch_active:
		return
	# Keep cover_peek_aim on the full gun-arm chain while in cover. The rig
	# aim-corrects RightArm after AnimationTree; releasing these bones used to
	# wipe the raise and leave bind-rest IK folding into the torso.
	CoverPoseConfig.set_gun_aim_blend_filtered(_cover_peek_blend_node, true)


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
	if _debug_camera_remote_edit:
		return

	_update_lock_on_camera_blend(delta)
	_update_interior_explore_camera_blend(delta)

	var aim_target := _get_aim_camera_blend()
	var aim_smooth := AIM_FOV_SMOOTH
	if _cover_crouch_active and aim_target < _aim_camera_blend:
		aim_smooth = COVER_AIM_CAMERA_RELEASE_SMOOTH
	var aim_step := 1.0 - exp(-aim_smooth * delta)
	_aim_camera_blend = lerpf(_aim_camera_blend, aim_target, aim_step)
	var aim_blend := _aim_camera_blend
	var ads_target := 1.0 if _is_ads_active() else 0.0
	var ads_step := 1.0 - exp(-ADS_CAMERA_BLEND_SPEED * delta)
	_ads_blend = lerpf(_ads_blend, ads_target, ads_step)
	var reload_target := _get_reload_camera_blend()
	var reload_step := 1.0 - exp(-RELOAD_CAMERA_SMOOTH * delta)
	_reload_camera_blend = lerpf(_reload_camera_blend, reload_target, reload_step)

	var weapon_fov_reduction := GroyperWeapons.get_aim_fov_reduction(
		_equipped_weapon,
		AIM_FOV_REDUCTION
	)
	if _is_run_and_gun_weapon():
		# Hip stance is permanent now; per-weapon zoom happens via ads_fov instead.
		weapon_fov_reduction = RUN_AND_GUN_HIP_FOV_REDUCTION
	var active_explore_fov := _get_active_explore_camera_fov()
	var base_fov := lerpf(
		active_explore_fov,
		active_explore_fov - weapon_fov_reduction,
		aim_blend
	)
	var reload_fov_reduction := lerpf(
		RELOAD_FOV_REDUCTION,
		RELOAD_FOV_REDUCTION_AIMING,
		aim_blend
	)
	var target_fov := base_fov - reload_fov_reduction * _reload_camera_blend
	target_fov -= MELEE_FOV_REDUCTION * _melee_camera_blend
	if _is_run_and_gun_weapon() and not GroyperWeapons.has_scope_aim(_equipped_weapon):
		target_fov = lerpf(target_fov, GroyperWeapons.get_ads_fov(_equipped_weapon), _ads_blend)
	var scoped_fov := GroyperWeapons.get_scope_fov(_equipped_weapon)
	target_fov = lerpf(target_fov, scoped_fov, _reticle_state.scope_blend)
	if _lock_on_camera_blend > 0.001:
		target_fov = lerpf(target_fov, LOCK_ON_CAMERA_FOV, _lock_on_camera_blend)
	var fov_smooth := RELOAD_CAMERA_SMOOTH if reload_target > 0.01 else AIM_FOV_SMOOTH
	var fov_step := 1.0 - exp(-fov_smooth * delta)
	_aim_fov_current = lerpf(_aim_fov_current, target_fov, fov_step)

	var aim_offset := AIM_CAMERA_OFFSET
	if _is_mounted():
		aim_offset = MOUNT_AIM_CAMERA_OFFSET
	elif _is_run_and_gun_weapon():
		aim_offset = RUN_AND_GUN_HIP_CAMERA_OFFSET.lerp(ADS_CAMERA_OFFSET, _ads_blend)
	var shoulder_blend := maxf(aim_blend, _melee_camera_blend)
	var shoulder_offset := aim_offset.lerp(MELEE_CAMERA_OFFSET, _melee_camera_blend)
	var base_pos := _get_active_explore_camera_offset().lerp(shoulder_offset, shoulder_blend)
	var reload_pull := RELOAD_CAMERA_PULL_IN.lerp(RELOAD_CAMERA_PULL_IN_AIMING, aim_blend)
	var final_offset := base_pos + reload_pull * _reload_camera_blend
	if _lock_on_camera_blend > 0.001:
		final_offset = final_offset.lerp(LOCK_ON_CAMERA_OFFSET, _lock_on_camera_blend)
	_apply_camera_offset(
		final_offset,
		_sample_camera_shake(delta)
	)
	_camera.fov = _aim_fov_current
	_apply_bonfire_cinematic_camera(delta)
	_apply_comet_cinematic_camera(delta)

	var scope_yaw := 0.0
	var scope_pitch := 0.0
	if _is_scope_aim_active():
		scope_yaw = _reticle_state.scope_yaw + _reticle_state.scope_recoil_yaw
		scope_pitch = _reticle_state.scope_pitch + _reticle_state.scope_recoil_pitch
	_sync_camera_pivot_yaw(scope_yaw)
	_set_camera_arm_pitch(scope_pitch)


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
	if not GroyperWeapons.has_scope_aim(_equipped_weapon) or not _weapon_rig.can_use_reticle():
		return false
	# Run-and-gun: the scope is the AWP's RMB zoom, not a permanent aim state.
	if _is_run_and_gun_weapon():
		return _is_ads_held()
	return true


func _apply_scope_look(relative: Vector2) -> void:
	if _debug_camera_remote_edit:
		return
	_reticle_state.apply_scope_look(
		relative,
		GroyperWeapons.get_scope_mouse_sensitivity(_equipped_weapon),
		deg_to_rad(GroyperWeapons.get_scope_yaw_max_deg(_equipped_weapon)),
		deg_to_rad(GroyperWeapons.get_scope_pitch_max_deg(_equipped_weapon))
	)


func _seed_scope_aim_from_reticle() -> void:
	_reticle_state.seed_scope_from_reticle(
		GroyperWeapons.get_scope_yaw_max_deg(_equipped_weapon),
		GroyperWeapons.get_scope_pitch_max_deg(_equipped_weapon)
	)


func _reset_scope_aim() -> void:
	_reticle_state.reset_scope()
	_reticle_state.scope_blend = 0.0
	if _scope_overlay and _scope_overlay.has_method("set_scope_blend"):
		_scope_overlay.set_scope_blend(0.0)
	if _reticle:
		_reticle.visible = true


func _update_scope_blend(delta: float) -> void:
	var target := 0.0
	if _is_scope_aim_active():
		target = 1.0

	var smooth := GroyperWeapons.get_scope_transition_smooth(_equipped_weapon)
	var blend: float = _reticle_state.update_scope_blend(delta, target, smooth)

	if _scope_overlay and _scope_overlay.has_method("set_scope_blend"):
		_scope_overlay.set_scope_blend(blend)


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
	if GroyperWeapons.is_melee(_equipped_weapon):
		var melee_out := (
			_melee_weapon_rig != null
			and (
				not _melee_weapon_rig.is_holstered()
				or _melee_weapon_rig.is_transitioning()
			)
		)
		if _ammo_hud:
			_ammo_hud.visible = melee_out
		if _left_ammo_hud:
			_left_ammo_hud.visible = false
		if _reticle_ui:
			_reticle_ui.visible = false
		_sync_gem_stamina_hud()
		return

	if GroyperWeapons.is_torch(_equipped_weapon):
		if _ammo_hud:
			_ammo_hud.visible = false
		if _left_ammo_hud:
			_left_ammo_hud.visible = false
		if _reticle_ui:
			_reticle_ui.visible = false
		return

	if _weapon_rig == null:
		return

	var weapon_out := not _weapon_rig.is_holstered()
	var reloading := _weapon_rig.is_overworld_reloading()
	if _ammo_hud:
		_ammo_hud.visible = weapon_out or reloading
	if _left_ammo_hud:
		_left_ammo_hud.visible = _is_dual_wield_equipped() and (weapon_out or reloading)
	if _reticle_ui:
		_reticle_ui.visible = _weapon_rig.can_use_reticle()
	_sync_gem_stamina_hud()


func _sync_gem_stamina_hud() -> void:
	if _ammo_hud == null:
		return
	var has_gem := ElementalGemStaminaScript.has_embedded_gem(_equipped_weapon)
	_ammo_hud.sync_gem_stamina(
		has_gem,
		ElementalGemStaminaScript.get_ratio(_equipped_weapon),
		ElementalGemStaminaScript.get_display_color(_equipped_weapon)
	)


func _update_health_vignette() -> void:
	if _health_vignette == null:
		return
	_health_vignette.set_health(_health, BulletHitDamage.PLAYER_MAX_HEALTH)


func get_health() -> int:
	return _health


func get_max_health() -> int:
	return BulletHitDamage.PLAYER_MAX_HEALTH


## Returns the amount actually healed (0 if already full).
func heal(amount: int) -> int:
	if amount <= 0 or _overworld_defeated:
		return 0
	var before := _health
	_health = mini(_health + amount, BulletHitDamage.PLAYER_MAX_HEALTH)
	var healed := _health - before
	if healed > 0:
		_health_regen_timer = 0.0
		_update_health_vignette()
	return healed


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
	if _is_dual_wield_equipped():
		_try_shoot_hand(false)
		return
	if is_melee_stunned():
		return
	if GroyperWeapons.is_melee(_equipped_weapon):
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
	if _shot_cooldown > 0.0:
		return
	if _ammo <= 0:
		_try_revolver_empty_click(false)
		return

	enter_overworld_combat()
	_shot_cooldown = (
		GroyperWeapons.get_shot_cooldown(_equipped_weapon)
		/ LightningGemCombatScript.get_speed_mult(_equipped_weapon)
	)
	_last_gunshot_msec = Time.get_ticks_msec()
	# Shotgun aims at reticle center; pellet cone (widened by bloom) is the spread.
	# RPG rockets also fire toward reticle center (no bloom cone).
	if GroyperWeapons.get_pellet_count(_equipped_weapon) > 1:
		_weapon_rig.fire_shotgun_at(_get_aim_world_target(), _reticle_state.bloom_deg)
	elif (
		GroyperWeapons.is_rpg(_equipped_weapon)
		or GroyperWeapons.is_grenade_launcher(_equipped_weapon)
	):
		_weapon_rig.fire_at(_get_aim_world_target())
	else:
		_weapon_rig.fire_at(_get_spread_adjusted_aim_target())
	_apply_shot_recoil()
	_notify_nearby_enemies_of_gunshot(_get_aim_world_target())
	_ammo -= 1
	ElementalGemStaminaScript.consume_on_attack(_equipped_weapon)
	if _ammo_hud:
		_ammo_hud.sync_rounds(_ammo, true)
	_sync_gem_stamina_hud()
	_sync_rpg_grip_rocket()


## Dual revolvers: left hand = LMB, right hand = RMB. Independent chambers/cooldowns.
func _try_shoot_hand(use_left: bool) -> void:
	if not _is_dual_wield_equipped():
		return
	if is_melee_stunned():
		return
	if _weapon_rig == null or not _weapon_rig.can_fire():
		return
	if _weapon_rig.is_overworld_reloading():
		return
	var cooldown := _left_shot_cooldown if use_left else _shot_cooldown
	var chamber := _left_ammo if use_left else _ammo
	if cooldown > 0.0:
		return
	if chamber <= 0:
		_try_revolver_empty_click(use_left)
		return

	enter_overworld_combat()
	var shot_cd := (
		GroyperWeapons.get_shot_cooldown(_equipped_weapon)
		/ LightningGemCombatScript.get_speed_mult(_equipped_weapon)
	)
	if use_left:
		_left_shot_cooldown = shot_cd
	else:
		_shot_cooldown = shot_cd
	_last_gunshot_msec = Time.get_ticks_msec()
	_weapon_rig.fire_at_from_hand(_get_spread_adjusted_aim_target(), use_left)
	_apply_shot_recoil()
	_notify_nearby_enemies_of_gunshot(_get_aim_world_target())
	if use_left:
		_left_ammo -= 1
		_sync_left_ammo_hud(true)
	else:
		_ammo -= 1
		if _ammo_hud:
			_ammo_hud.sync_rounds(_ammo, true)
	ElementalGemStaminaScript.consume_on_attack(_equipped_weapon)
	_sync_gem_stamina_hud()


## Dry-fire click for empty revolver / dual chambers (first half of RevolverAim).
func _try_revolver_empty_click(use_left: bool) -> void:
	var is_revolver := (
		_equipped_weapon == GroyperWeapons.Id.REVOLVER
		or GroyperWeapons.is_dual_wield(_equipped_weapon)
	)
	if not is_revolver:
		return
	var click_cd := (
		GroyperWeapons.get_shot_cooldown(_equipped_weapon)
		/ LightningGemCombatScript.get_speed_mult(_equipped_weapon)
	)
	if use_left:
		_left_shot_cooldown = click_cd
	else:
		_shot_cooldown = click_cd
	var origin := global_position + Vector3(0.0, 1.2, 0.0)
	if _weapon_rig != null:
		origin = (
			_weapon_rig.get_left_muzzle_global_position()
			if use_left
			else _weapon_rig.get_muzzle_global_position()
		)
	GameAudio.play_revolver_empty(self, origin)


## Deviates the aim point by a random direction inside the current bloom cone.
func _get_spread_adjusted_aim_target() -> Vector3:
	var target := _get_aim_world_target()
	if not _is_run_and_gun_weapon():
		return target

	var bloom: float = _reticle_state.bloom_deg
	if bloom <= 0.01:
		return target

	var origin := _get_aim_ray_origin()
	var to_target := target - origin
	var distance := to_target.length()
	if distance < 0.01:
		return target

	var direction := to_target / distance
	# sqrt keeps hits uniformly distributed over the cone's area.
	var deviation := deg_to_rad(bloom) * sqrt(randf())
	var side := direction.cross(Vector3.UP)
	if side.length_squared() < 0.0001:
		side = direction.cross(Vector3.RIGHT)
	side = side.normalized()
	var deviated := direction.rotated(side, deviation).rotated(direction, randf() * TAU)
	return origin + deviated * distance


func _apply_shot_recoil() -> void:
	var stats := GroyperWeapons.get_stats(_equipped_weapon)
	var kick := float(stats.get("reticle_recoil_kick", 14.0))
	var randomness := float(stats.get("reticle_recoil_randomness", 0.18))

	if _is_scope_aim_active():
		_reticle_state.apply_scope_shot_recoil(kick, randomness)
		return

	if _is_run_and_gun_weapon():
		_reticle_state.add_shot_bloom(
			GroyperWeapons.get_bloom_shot_deg(_equipped_weapon),
			GroyperWeapons.get_bloom_max_deg(_equipped_weapon)
		)
		_apply_camera_shot_kick()
		return

	_reticle_state.apply_reticle_shot_recoil(kick, randomness)


## Small permanent camera kick per shot (pitch up + horizontal jitter) — the
## run-and-gun replacement for the old wandering-reticle recoil.
func _apply_camera_shot_kick() -> void:
	var kick := GroyperWeapons.get_camera_recoil_kick(_equipped_weapon)
	if kick <= 0.0:
		return
	var randomness := GroyperWeapons.get_camera_recoil_randomness(_equipped_weapon)
	var kick_rad := deg_to_rad(kick * CAMERA_RECOIL_DEG_PER_KICK)
	_camera_pitch = clampf(
		_camera_pitch + kick_rad * randf_range(0.85, 1.15),
		CAMERA_PITCH_MIN,
		CAMERA_PITCH_MAX
	)
	_camera_yaw += kick_rad * randf_range(-randomness, randomness)


func _get_reticle_screen_position() -> Vector2:
	if _is_mounted() or _is_scope_aim_active() or _is_run_and_gun_weapon():
		return get_viewport().get_visible_rect().size * 0.5
	return get_viewport().get_visible_rect().size * 0.5 + _reticle_state.reticle_offset


func _get_aim_ray_origin() -> Vector3:
	return _camera.project_ray_origin(_get_reticle_screen_position())


func _get_aim_direction() -> Vector3:
	return _camera.project_ray_normal(_get_reticle_screen_position()).normalized()


func _get_aim_ray_exclude() -> Array[RID]:
	# Called every frame while aiming; rebuild only when the hitbox changes.
	var hitbox_rid := RID()
	if _combat_hitbox != null and is_instance_valid(_combat_hitbox):
		hitbox_rid = _combat_hitbox.get_rid()
	if _aim_ray_exclude_cache.is_empty() or _aim_ray_exclude_hitbox != hitbox_rid:
		_aim_ray_exclude_cache = [get_rid()]
		if hitbox_rid.is_valid():
			_aim_ray_exclude_cache.append(hitbox_rid)
		_aim_ray_exclude_hitbox = hitbox_rid
	return _aim_ray_exclude_cache


func _raycast_aim_depth(origin: Vector3, direction: Vector3, min_depth: float = 0.0) -> float:
	var space_state := get_world_3d().direct_space_state
	if space_state == null:
		return SHOT_RANGE

	if _aim_ray_query == null:
		_aim_ray_query = PhysicsRayQueryParameters3D.new()
		_aim_ray_query.collide_with_areas = false
	_aim_ray_query.from = origin
	_aim_ray_query.to = origin + direction * SHOT_RANGE
	_aim_ray_query.exclude = _get_aim_ray_exclude()
	var hit := space_state.intersect_ray(_aim_ray_query)
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
	# Same centered bloom cone as firearms (hip loose, ADS tight).
	if _is_run_and_gun_weapon():
		return _get_spread_adjusted_aim_target()
	var origin := _get_aim_ray_origin()
	var direction := _get_aim_direction()
	return _get_aim_point_along_ray(origin, direction, BOW_MIN_AIM_DISTANCE)


func _get_lasso_throw_anchor() -> Vector3:
	if _weapon_rig != null:
		return _weapon_rig.get_muzzle_global_position()
	return global_position + Vector3(0.0, 1.2, 0.0)


func get_lasso_throw_anchor() -> Vector3:
	return _get_lasso_throw_anchor()


func get_lasso_swing_attach() -> Vector3:
	return global_position + Vector3(0.0, 1.15, 0.0)


func get_lasso_leader_velocity() -> Vector3:
	if _mounted_horse != null and is_instance_valid(_mounted_horse):
		return Vector3(_mounted_horse.velocity.x, 0.0, _mounted_horse.velocity.z)
	return Vector3(velocity.x, 0.0, velocity.z)


func begin_lasso_rope_climb(anchor: Node3D, rope_length: float, _max_rope_length: float) -> void:
	_lasso_release_float_timer = 0.0
	_lasso_swing_state.saved_motion_mode = motion_mode
	velocity = Vector3.ZERO
	if anchor != null and is_instance_valid(anchor):
		LassoSwingPhysicsScript.enforce_rope_constraint(self, anchor, rope_length)


func begin_lasso_rope_vertical_climb(anchor: Node3D, rope_length: float) -> void:
	_lasso_release_float_timer = 0.0
	_lasso_swing_state.saved_motion_mode = motion_mode
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	if anchor != null and is_instance_valid(anchor):
		LassoSwingPhysicsScript.enforce_rope_constraint(self, anchor, rope_length)
	velocity = Vector3.ZERO
	_lasso_swing_state.begin_hold(self)


func launch_lasso_grapple_swing(anchor: Node3D, rope_length: float) -> void:
	begin_lasso_rope_climb(anchor, rope_length, rope_length)


func begin_lasso_grapple_swing(anchor: Node3D, rope_length: float) -> void:
	begin_lasso_rope_climb(anchor, rope_length, rope_length)


func end_lasso_grapple_swing() -> void:
	LassoSwingPhysicsScript.clear_swing_state(self)
	_lasso_release_float_timer = 0.0
	motion_mode = _lasso_swing_state.saved_motion_mode
	_lasso_swing_state.reset_body_pose(self)
	if _is_lasso_swing_sequence_active():
		_lasso_swing_state.finish(self)


func release_lasso_rope_hop(anchor: Node3D) -> void:
	if anchor == null or not is_instance_valid(anchor):
		return
	LassoSwingPhysicsScript.clear_swing_state(self)
	motion_mode = _lasso_swing_state.saved_motion_mode
	var move_dir := _get_camera_relative_input()
	velocity = LassoSwingPhysicsScript.compute_release_jump_velocity(self, move_dir, RUN_SPEED)
	_lasso_release_float_timer = 0.0
	_lasso_swing_state.release_air_control = false
	_lasso_swing_state.begin_air(self)


func release_lasso_grapple_swing(anchor: Node3D) -> void:
	release_lasso_rope_hop(anchor)


func is_lasso_rope_climbing() -> bool:
	return _lasso_controller != null and _lasso_controller.is_rope_vertical_climbing()


func is_lasso_rope_walking() -> bool:
	return _lasso_controller != null and _lasso_controller.is_rope_walking()


func is_lasso_grapple_swinging() -> bool:
	return is_lasso_rope_climbing()


func is_lasso_grapple_attached() -> bool:
	return _lasso_controller != null and (
		_lasso_controller.is_rope_walking() or _lasso_controller.is_rope_vertical_climbing()
	)


func _is_lasso_swing_sequence_active() -> bool:
	return _lasso_swing_state.is_sequence_active(self)


func _init_lasso_swing_animation_tree_state() -> void:
	_lasso_swing_state.init_animation_tree_state(self)


func _init_climb_fall_animation_tree_state() -> void:
	_climb_fall_state.init_animation_tree_state(self)


func _is_climb_fall_sequence_active() -> bool:
	return _climb_fall_state.is_sequence_active()


func _cancel_climb_fall_sequence() -> void:
	_climb_fall_state.cancel(self)


func _update_climb_fall(delta: float) -> void:
	_climb_fall_state.update(self, delta)


func can_mount_ladder() -> bool:
	return (
		not _ladder_state.active
		and not _vault_active
		and not _roll_active
		and not _mount_transition_active
		and not _is_fully_mounted()
		and not _transition_locked
		and not _is_bonfire_pose_active()
		and not _hit_reaction_active
		and not _face_punch_reaction_active
		and (_lasso_controller == null or not _lasso_controller.is_active())
	)


func is_ladder_climbing() -> bool:
	return _ladder_state.active


func mount_ladder(ladder: LadderPiece) -> void:
	_ladder_state.mount(self, ladder)


func _init_ladder_climb_animation_tree_state() -> void:
	_ladder_state.init_animation_tree_state(self)


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
		and _lasso_controller.get_state() != LassoController.State.THROWING
	):
		_lasso_controller.on_aim_released()

	_lasso_rmb_was_held = rmb_held


func _update_lasso_controller(delta: float) -> void:
	if _lasso_controller == null:
		return

	var rmb_held := Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	var can_use := _can_use_lasso() or _lasso_controller.is_active()
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
		_clear_bow_trajectory_preview()
		_bow_lmb_was_held = lmb_held
		return

	var can_use := _can_use_bow()
	_bow_controller.update(delta, lmb_held, can_use)
	_bow_lmb_was_held = lmb_held
	_sync_bow_trajectory_preview(can_use)


func _sync_bow_trajectory_preview(can_use: bool) -> void:
	if _bow_trajectory_preview == null:
		return
	if can_use and _bow_controller.is_charging():
		var exclude: Array = [self]
		if _combat_hitbox != null:
			exclude.append(_combat_hitbox)
		_bow_trajectory_preview.update_preview(
			_get_bow_fire_origin(),
			_get_bow_fire_direction(),
			_bow_controller.get_charge_alpha(),
			exclude
		)
	else:
		_bow_trajectory_preview.clear()


func _clear_bow_trajectory_preview() -> void:
	if _bow_trajectory_preview != null:
		_bow_trajectory_preview.clear()


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
	# Arrows are a persistent reserve; write it back (silent — we refresh the
	# quiver ourselves below, no need to emit inventory_changed per shot).
	PlayerInventory.set_bow_ammo(_ammo, false)
	_shot_cooldown = (
		GroyperWeapons.get_shot_cooldown(_equipped_weapon)
		/ LightningGemCombatScript.get_speed_mult(_equipped_weapon)
	)
	_last_gunshot_msec = Time.get_ticks_msec()
	if _is_run_and_gun_weapon():
		_reticle_state.add_shot_bloom(
			GroyperWeapons.get_bloom_shot_deg(_equipped_weapon),
			GroyperWeapons.get_bloom_max_deg(_equipped_weapon)
		)
	_notify_nearby_enemies_of_gunshot(_get_bow_fire_origin())
	ElementalGemStaminaScript.consume_on_attack(_equipped_weapon)
	if _ammo_hud:
		_ammo_hud.sync_rounds(_ammo, true)
	_sync_gem_stamina_hud()
	_refresh_bow_back_visuals()


## Arrow pickups: room left in the persistent arrow reserve (collectible any
## time, whether or not the bow is currently in hand).
func get_bow_ammo_space() -> int:
	return PlayerInventory.get_bow_ammo_space()


func add_bow_ammo(amount: int) -> int:
	var added := PlayerInventory.add_bow_ammo(amount)  # emits inventory_changed
	if added <= 0:
		return 0
	# Keep the live working copy in sync while the bow is equipped; the quiver
	# refresh is already handled by the inventory_changed signal.
	if _equipped_weapon == GroyperWeapons.Id.BOW:
		_ammo = PlayerInventory.get_bow_ammo()
		if _ammo_hud:
			_ammo_hud.sync_rounds(_ammo, true)
	return added


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
	_reticle_state.update_limit(
		get_viewport().get_visible_rect().size,
		RETICLE_MAX_SCREEN_FRACTION
	)


func _reset_reticle_state() -> void:
	_reticle_state.reset_reticle()
	_reticle_state.reset_bloom(GroyperWeapons.get_bloom_base_deg(_equipped_weapon))


func _update_reticle(delta: float) -> void:
	if _is_scope_aim_active():
		_reticle_state.update_reticle_scoped(delta, _get_reticle_smooth())
		if _reticle:
			_reticle.visible = false
			_reticle.set_screen_offset(Vector2.ZERO)
		return

	if _reticle:
		_reticle.visible = true

	if _is_run_and_gun_weapon():
		# Centered spread crosshair — driven by _update_run_and_gun.
		return

	if _reticle and _reticle.has_method("clear_spread_mode"):
		_reticle.clear_spread_mode()

	var offset: Vector2 = _reticle_state.update_reticle(
		delta,
		_get_reticle_drag(),
		_get_reticle_max_speed_px(),
		_get_reticle_smooth()
	)

	if _reticle and _reticle.has_method("set_screen_offset"):
		_reticle.set_screen_offset(offset)


func _update_interact_hint() -> void:
	if _interact_hint == null:
		return

	if _ladder_state.active:
		_interact_hint.visible = false
		return

	if _mounted_horse != null:
		if _interact_hint_last_hint != "Dismount":
			_interact_hint_last_hint = "Dismount"
			_interact_hint.text = "[E] Dismount"
		_interact_hint.visible = true
		return

	var target := _get_nearest_interactable()
	var hint_text := "Talk"
	if target != null and target.has_method("get_interact_hint"):
		hint_text = str(target.get_interact_hint())
	var mount_hint := hint_text == "Mount"
	var combat_ok := (
		target != null
		and target.has_method("allows_combat_interact")
		and bool(target.call("allows_combat_interact"))
	)
	var show_hint := (
		not _dialog_active
		and not DialogManager.is_showing()
		and target != null
		and hint_text != ""
		and (
			_weapon_rig == null
			or _weapon_rig.is_holstered()
			or _is_run_and_gun_weapon()
			or mount_hint
			or combat_ok
		)
	)
	if show_hint and hint_text != _interact_hint_last_hint:
		_interact_hint_last_hint = hint_text
		_interact_hint.text = "[E] %s" % hint_text
	_interact_hint.visible = show_hint


func _init_punch_animation_tree_state() -> void:
	_punch_blend = 0.0
	_punch_cross_slot = 0
	_punch_cross_blend = 0.0
	_punch_crossfade_active = false
	_punch_crossfade_timer = 0.0
	_punch_crossfade_duration = PunchPoseConfig.COMBO_CROSSFADE
	_punch_hold_seek = 0.0
	PunchPoseConfig.set_tree_blend(_animation_tree, 0.0)
	PunchPoseConfig.set_cross_blend(_animation_tree, 0.0)
	PunchPoseConfig.set_slot_seek(_animation_tree, 0, 0.0)
	PunchPoseConfig.set_slot_seek(_animation_tree, 1, 0.0)


func _init_flying_kick_animation_tree_state() -> void:
	_flying_kick_blend = 0.0
	_flying_kick_exit_active = false
	_flying_kick_exit_timer = 0.0
	if _animation_tree == null or not _flying_kick_nodes_ready:
		return
	FlyingKickConfigScript.set_tree_blend(_animation_tree, 0.0)
	FlyingKickConfigScript.set_tree_seek(_animation_tree, -1.0)
	FlyingKickConfigScript.set_tree_scale(_animation_tree, FLYING_KICK_PLAYBACK_SPEED)


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
	_clear_bonfire_model_sink()
	if _animation_tree == null:
		return
	BonfirePoseConfig.set_bonfire_blend(_animation_tree, 0.0)
	BonfirePoseConfig.set_pose_blend(_animation_tree, 0.0)
	BonfirePoseConfig.set_stand_seek(_animation_tree, -1.0)


func _can_use_sword_shield_melee() -> bool:
	if GroyperWeapons.is_torch(_equipped_weapon):
		return (
			_torch_hand_visual != null
			and is_instance_valid(_torch_hand_visual)
			and _torch_hand_visual.visible
			and not is_melee_stunned()
			and not _hit_reaction_active
		)
	return (
		GroyperWeapons.is_melee(_equipped_weapon)
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


## Firearms + RecurveBow use the run-and-gun controller: always drawn, centered
## bloom crosshair, camera-driven aim, RMB = ADS zoom. Bow still charges on LMB.
func _is_run_and_gun_weapon() -> bool:
	return GroyperWeapons.uses_run_and_gun(_equipped_weapon)


## Pushed to the rig every frame. False during traversal moves so the rig
## holsters (animation owns the arms) and auto-redraws afterwards.
## Cover: gun stays holstered until RMB peek draws it (not always-drawn).
func _should_gun_stay_drawn() -> bool:
	return (
		_is_run_and_gun_weapon()
		and not _cover_crouch_active
		and not _roll_active
		and not _vault_active
		and not _ladder_state.active
		and not _is_climb_fall_sequence_active()
		and not _hostage_take_active
		and not _flying_kick_active
		and not _punch_active
		and not _is_lasso_swing_sequence_active()
		and not is_lasso_grapple_swinging()
		and not _mount_transition_active
	)


func _is_ads_held() -> bool:
	if _is_dual_wield_equipped():
		return false
	return (
		Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
		and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
		and _is_run_and_gun_weapon()
	)


## RMB zoom. Disabled in cover (RMB peeks there), on horseback, and while dual-wielding.
func _is_ads_active() -> bool:
	if _is_dual_wield_equipped():
		return false
	return (
		_is_ads_held()
		and not _is_mounted()
		and not _cover_crouch_active
		and _weapon_rig != null
		and _weapon_rig.can_use_reticle()
	)


## Slowed aim-walk applies while ADS (run-and-gun) or whenever a legacy
## hold-to-aim weapon (lasso/bow/shovel) is out.
func _is_slow_aim_stance() -> bool:
	if not _is_in_gun_aim_stance():
		return false
	if not _is_run_and_gun_weapon():
		return true
	return _is_ads_active()


## Per-frame run-and-gun upkeep: rig always-drawn flag, scope (AWP) RMB
## transitions, bloom simulation, and the spread crosshair.
func _update_run_and_gun(delta: float) -> void:
	if _weapon_rig == null:
		return
	_weapon_rig.set_always_drawn(_should_gun_stay_drawn())
	_try_finish_pending_unarmed_equip()
	_try_finish_pending_weapon_equip()
	_try_finish_pending_melee_holster()
	if not _is_run_and_gun_weapon():
		_weapon_rig.sync_run_and_gun_aim_mode(0.0, 0.0)
		if _reticle != null and _reticle.has_method("clear_spread_mode"):
			_reticle.clear_spread_mode()
		return

	# Cover peek owns aim pose (arm aim-correct). Keep hipfire/ADS flags off.
	if _cover_crouch_active:
		_weapon_rig.sync_run_and_gun_aim_mode(0.0, 0.0)
		_weapon_rig.set_hip_fire_aim_enabled(false)
		_weapon_rig.set_two_hand_aim_enabled(false)
	else:
		# 1H: HipFireAim/neutral→ads + RightArm reticle stabilizer (hip walk = ADS walk).
		# 2H: TwoHandAim/neutral→ads + Spine02 pitch. Bow: BowAim + draw scrub.
		_weapon_rig.sync_run_and_gun_aim_mode(_ads_blend, _locomotion_move_blend)

	var scope_active := _is_scope_aim_active()
	if scope_active and not _scope_was_active:
		_seed_scope_aim_from_reticle()
	elif not scope_active and _scope_was_active:
		# Fold the scope offset into the camera so leaving ADS doesn't snap aim.
		_camera_yaw += _reticle_state.scope_yaw
		_camera_pitch = clampf(
			_camera_pitch + _reticle_state.scope_pitch,
			CAMERA_PITCH_MIN,
			CAMERA_PITCH_MAX
		)
		_reticle_state.reset_scope()
	_scope_was_active = scope_active

	var speed := Vector3(velocity.x, 0.0, velocity.z).length()
	if _is_mounted() and _mounted_horse != null and is_instance_valid(_mounted_horse):
		speed = Vector3(_mounted_horse.velocity.x, 0.0, _mounted_horse.velocity.z).length()
	var move_fraction := clampf(speed / RUN_SPEED, 0.0, 1.0)
	var ads_scale := lerpf(
		1.0,
		GroyperWeapons.get_ads_bloom_scale(_equipped_weapon),
		_ads_blend
	)
	_reticle_state.update_bloom(
		delta,
		GroyperWeapons.get_bloom_base_deg(_equipped_weapon),
		GroyperWeapons.get_bloom_move_deg(_equipped_weapon),
		move_fraction,
		ads_scale,
		GroyperWeapons.get_handling(_equipped_weapon),
		GroyperWeapons.get_bloom_max_deg(_equipped_weapon)
	)

	if _reticle != null and not scope_active:
		_reticle.set_screen_offset(Vector2.ZERO)
		_reticle.set_spread_px(
			_get_bloom_spread_px(),
			GroyperWeapons.get_reticle_style(_equipped_weapon)
		)


func _get_bloom_spread_px() -> float:
	var viewport_height := get_viewport().get_visible_rect().size.y
	return PlayerReticleState.bloom_deg_to_px(
		_reticle_state.bloom_deg,
		_aim_fov_current,
		viewport_height
	)


func _update_melee_input_hold() -> void:
	if _reflect_active or _weapon_throw_active:
		return
	if _can_use_dynamite():
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			if not _combat_blocking and not _combat_attacking:
				_begin_dynamite_brace()
		elif _combat_blocking:
			_end_melee_blocking()
		return
	if GroyperWeapons.is_torch(_equipped_weapon) and _can_use_sword_shield_melee():
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			if not _combat_blocking and not _combat_attacking:
				_begin_torch_brace()
		elif _combat_blocking:
			_end_melee_blocking()
		return
	if not _can_use_sword_shield_melee():
		if _combat_blocking:
			_end_melee_blocking()
		return
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		if not _combat_blocking:
			if _combat_attacking:
				_cancel_melee_attack_for_block()
			_begin_melee_blocking()
	elif _combat_blocking:
		_end_melee_blocking()


func _try_begin_dynamite_brace() -> void:
	if not _can_use_dynamite() or _combat_attacking or _combat_blocking:
		return
	_begin_dynamite_brace()


func _begin_dynamite_brace() -> void:
	# Pose-only: sword & shield block hold (right arm pulled back = throw windup).
	if _melee_block_hold_anim_node != null:
		var path := GroyperMeleeAnimConfig.clip_path(GroyperMeleeAnimConfig.CLIP_BLOCK_HOLD)
		if _animation_player != null and _animation_player.has_animation(path):
			_melee_block_hold_anim_node.animation = path
	_combat_blocking = true


func _try_begin_torch_brace() -> void:
	if not _can_use_sword_shield_melee() or _combat_attacking or _combat_blocking:
		return
	if not GroyperWeapons.is_torch(_equipped_weapon):
		return
	_begin_torch_brace()


func _begin_torch_brace() -> void:
	# Same pre-throw pose as dynamite (sword block-hold windup).
	if _melee_block_hold_anim_node != null:
		var path := GroyperMeleeAnimConfig.clip_path(GroyperMeleeAnimConfig.CLIP_BLOCK_HOLD)
		if _animation_player != null and _animation_player.has_animation(path):
			_melee_block_hold_anim_node.animation = path
	_combat_blocking = true


func _try_drop_lit_dynamite() -> void:
	if not _can_use_dynamite():
		return
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return
	var drop_pos := global_position + Vector3(0.0, 0.15, 0.0)
	var forward := _get_melee_flat_forward()
	if forward.length_squared() > 0.0001:
		drop_pos += forward * 0.45
	if _dynamite_hand_visual != null and _dynamite_hand_visual.visible:
		drop_pos = _dynamite_hand_visual.global_position
		_dynamite_hand_visual.visible = false
	DynamiteProjectileScript.spawn_dropped(scene_root, drop_pos, self)
	_consume_one_dynamite()


func _consume_one_dynamite() -> void:
	PlayerInventory.remove_one_weapon(GroyperWeapons.Id.DYNAMITE)
	_ammo = PlayerInventory.count_weapon(GroyperWeapons.Id.DYNAMITE)
	if _ammo_hud:
		_ammo_hud.sync_rounds(_ammo)
	if _ammo <= 0:
		_sync_dynamite_hand_visual()
		equip_weapon(GroyperWeapons.Id.UNARMED, false)
	else:
		_sync_dynamite_hand_visual()


func _can_use_melee_combat_idle() -> bool:
	if _idle_anim_node == null or not GroyperWeapons.is_melee(_equipped_weapon):
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
		and not _hostage_take_active
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


## Crossfades the dedicated two-handed idle/walk/sprint locomotion over the base
## tree whenever a two-handed melee weapon is drawn, and tracks the blend-space
## position to the character's ground speed.
func _update_two_hand_locomotion(delta: float) -> void:
	if not _two_hand_locomotion_nodes_ready or _animation_tree == null or not _animation_tree.active:
		return
	var want := (
		GroyperWeapons.is_two_handed_melee(_equipped_weapon)
		and _melee_weapon_rig != null
		and _melee_weapon_rig.is_equipped()
	)
	var target := 1.0 if want else 0.0
	if not is_equal_approx(_two_hand_locomotion_blend, target):
		var blend_time := (
			TWO_HAND_LOCOMOTION_BLEND_IN
			if target > _two_hand_locomotion_blend
			else TWO_HAND_LOCOMOTION_BLEND_OUT
		)
		var step := _block_hold_blend_step(delta, blend_time)
		_two_hand_locomotion_blend = lerpf(_two_hand_locomotion_blend, target, step)
	var speed := Vector2(velocity.x, velocity.z).length()
	_two_hand_locomotion_pos = lerpf(_two_hand_locomotion_pos, speed, clampf(delta * 12.0, 0.0, 1.0))
	_animation_tree.set(
		"parameters/%s/blend_amount" % TWO_HAND_LOCOMOTION_BLEND,
		_two_hand_locomotion_blend
	)
	_animation_tree.set(
		"parameters/%s/blend_position" % TWO_HAND_LOCOMOTION_SPACE,
		_two_hand_locomotion_pos
	)


func _apply_block_walk_locomotion_blend() -> void:
	if not _melee_block_walk_nodes_ready or _animation_tree == null or not _animation_tree.active:
		return
	_animation_tree.set(
		"parameters/%s/blend_amount" % GroyperMeleeAnimConfig.BLOCK_WALK_LOCOMOTION_BLEND,
		_block_walk_amount
	)


func _fade_block_walk_amount(delta: float, blend_time: float) -> void:
	if _block_walk_amount <= 0.001:
		return
	var step := _block_hold_blend_step(delta, blend_time)
	_block_walk_amount = lerpf(_block_walk_amount, 0.0, step)
	_apply_block_walk_locomotion_blend()


func _update_block_walk_amount(
	delta: float,
	speed: float,
	walk_speed: float,
	move_dir: Vector3
) -> void:
	var block_pose_active := _combat_blocking or _hostage_take_active
	if not block_pose_active:
		if _block_walk_amount <= 0.001:
			return
		_fade_block_walk_amount(delta, BLOCK_HOLD_BLEND_OUT_TIME)
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
	if _hostage_take_active:
		return _melee_block_hold_blend > 0.001 or _block_walk_amount > 0.001
	if not (
		GroyperWeapons.is_melee(_equipped_weapon)
		or GroyperWeapons.is_dynamite(_equipped_weapon)
	):
		return false
	return (
		_combat_blocking
		or _reflect_active
		or _melee_block_hold_blend > 0.001
		or _block_walk_amount > 0.001
	)


func _fire_block_parry_one_shot() -> void:
	if not _melee_combat_nodes_ready or _animation_tree == null or not _animation_tree.active:
		return
	if _shield_block_clash_path.is_empty():
		return
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
		_fade_block_walk_amount(delta, BLOCK_REFLECT_WALK_BLEND_OUT_TIME)
		var reflect_target := 1.0 - _block_walk_amount
		if is_equal_approx(_melee_block_hold_blend, reflect_target):
			return
		var reflect_blend_time := (
			BLOCK_REFLECT_HOLD_BLEND_IN_TIME
			if reflect_target > _melee_block_hold_blend
			else BLOCK_REFLECT_WALK_BLEND_OUT_TIME
		)
		var reflect_step := _block_hold_blend_step(delta, reflect_blend_time)
		_set_melee_block_hold_blend(lerpf(_melee_block_hold_blend, reflect_target, reflect_step))
		return

	if not _combat_blocking and not _hostage_take_active:
		var release_speed := Vector2(velocity.x, velocity.z).length()
		var release_move_dir := _get_block_locomotion_anim_direction(_get_camera_relative_input())
		_update_block_walk_amount(delta, release_speed, WALK_SPEED, release_move_dir)

		if _melee_block_hold_blend > 0.001:
			var fade_step := _block_hold_blend_step(delta, BLOCK_HOLD_BLEND_OUT_TIME)
			_set_melee_block_hold_blend(lerpf(_melee_block_hold_blend, 0.0, fade_step))
		return

	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var move_dir := _get_block_locomotion_anim_direction(_get_camera_relative_input())
	var block_reference_speed := _get_block_walk_speed()
	if _hostage_take_active:
		block_reference_speed = WALK_SPEED * HOSTAGE_MOVE_SPEED_MULT
	_update_block_walk_amount(delta, horizontal_speed, block_reference_speed, move_dir)
	var target := 1.0 - _block_walk_amount
	if is_equal_approx(_melee_block_hold_blend, target):
		return

	var blend_time: float
	if _block_walk_amount <= 0.001 and target > _melee_block_hold_blend:
		blend_time = (
			ATTACK_CANCEL_INTO_BLOCK_BLEND
			if _attack_cancel_into_block
			else BLOCK_HOLD_BLEND_IN_TIME
		)
	elif _block_walk_amount <= 0.001 and target < _melee_block_hold_blend:
		blend_time = BLOCK_HOLD_BLEND_OUT_TIME
	elif target < _melee_block_hold_blend:
		blend_time = BLOCK_HOLD_WALK_BLEND_OUT_TIME
	else:
		blend_time = BLOCK_HOLD_WALK_BLEND_IN_TIME
	var step := _block_hold_blend_step(delta, blend_time)
	_set_melee_block_hold_blend(lerpf(_melee_block_hold_blend, target, step))
	if _attack_cancel_into_block and _melee_block_hold_blend >= target - 0.01:
		_attack_cancel_into_block = false


func _update_melee_block_hold_for_locomotion(delta: float) -> void:
	_update_melee_block_hold_blend_state(delta)


func _is_unarmed_block_pose_active() -> bool:
	return (_unarmed_blocking or _unarmed_block_blend > 0.02) and not _punch_active


func _can_begin_unarmed_blocking() -> bool:
	return (
		_unarmed_block_hold_ready
		and not _overworld_defeated
		# A held block during the punched reaction is a buffered block: it
		# starts immediately and the fading reaction layer crossfades into it.
		# Knockdown stuns (hit reaction) stay locked out.
		and (not is_melee_stunned() or _face_punch_reaction_active)
		# Attacks (punch / flying kick) can cancel into block immediately.
		and not _transition_locked
		and not _dialog_active
		and not DialogManager.is_showing()
		and not InventoryMenuManager.is_open()
		and not TownMapManager.is_open()
		and not ShopBuyManager.is_showing()
		and not BonfireMenuManager.is_showing()
		and not _roll_active
		and not _vault_active
		and not _cover_crouch_active
		and not _cover_walk_enter_active
		and not _cover_exit_active
		and not _mount_transition_active
		and not _is_fully_mounted()
		and not _reflect_active
		and not _hostage_take_active
		and not _parry_throw_active
		and not _can_use_sword_shield_melee()
	)


func _try_begin_unarmed_blocking() -> void:
	if _unarmed_blocking or not _can_begin_unarmed_blocking():
		return
	_begin_unarmed_blocking()


func _try_end_unarmed_blocking() -> void:
	if not _unarmed_blocking:
		return
	_end_unarmed_blocking()


func _begin_unarmed_blocking() -> void:
	_cancel_active_attack_for_unarmed_block()
	# Punch→block dual-slot crossfade already owns the anim slots.
	if not _punch_crossfade_active:
		_prep_unarmed_block_hold_anim()
	_unarmed_blocking = true


## Abort punch / flying kick and crossfade into the unarmed block pose.
## Returns true when an attack was canceled (blend already set up).
func _cancel_active_attack_for_unarmed_block() -> bool:
	var canceled := false
	if _flying_kick_active or _flying_kick_exit_active:
		_abort_flying_kick_for_block()
		canceled = true
	if _punch_active or _punch_exit_active or _punch_blend > 0.05:
		_cancel_punch_into_block_pose()
		canceled = true
	if canceled:
		_attack_cancel_into_block = true
	return canceled


func _abort_flying_kick_for_block() -> void:
	_flying_kick_active = false
	_flying_kick_exit_active = false
	_flying_kick_timer = 0.0
	_flying_kick_exit_timer = 0.0
	_flying_kick_struck = false
	_init_flying_kick_animation_tree_state()


func _soft_clear_punch_combat_state() -> void:
	if _unarmed_grab_reach_active:
		_clear_unarmed_grab_window()
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
	_melee_hitstop_remaining = 0.0
	_melee_hitstop_weapon = false
	_cancel_punch_facing_return()
	_knockback_facing_yaw_locked = INF
	_sync_knife_hand_visual()


func _cancel_punch_into_block_pose() -> void:
	var hold_seek := 0.0
	if _punch_active:
		hold_seek = _get_punch_anim_time()
	elif _punch_hold_seek > 0.0:
		hold_seek = _punch_hold_seek
	var preserved_blend := maxf(_punch_blend, 0.85)
	_soft_clear_punch_combat_state()
	if not _unarmed_block_hold_ready or _punch_anim_node == null:
		_unarmed_block_blend = preserved_blend
		_set_punch_tree_blend(preserved_blend)
		return

	# Dual-slot crossfade: hold the attack pose, blend quickly into block hold.
	var to_slot := 1 - _punch_cross_slot
	_set_punch_slot_animation(to_slot, _unarmed_block_hold_path)
	PunchPoseConfig.set_slot_seek(_animation_tree, _punch_cross_slot, hold_seek)
	PunchPoseConfig.set_slot_seek(_animation_tree, to_slot, 0.0)
	_punch_hold_seek = hold_seek
	_punch_crossfade_from = float(_punch_cross_slot)
	_punch_crossfade_to = float(to_slot)
	_punch_cross_slot = to_slot
	_punch_crossfade_timer = 0.0
	_punch_crossfade_active = true
	_punch_crossfade_duration = ATTACK_CANCEL_INTO_BLOCK_BLEND
	_punch_blend = preserved_blend
	_unarmed_block_blend = preserved_blend
	_set_punch_tree_blend(_punch_blend)


func _normalize_unarmed_block_to_slot_a() -> void:
	if not _unarmed_block_hold_ready or _punch_anim_node == null:
		return
	_set_punch_slot_animation(0, _unarmed_block_hold_path)
	_punch_cross_slot = 0
	_punch_cross_blend = 0.0
	_punch_crossfade_active = false
	_punch_crossfade_timer = 0.0
	_punch_crossfade_duration = PunchPoseConfig.COMBO_CROSSFADE
	PunchPoseConfig.set_cross_blend(_animation_tree, 0.0)
	PunchPoseConfig.set_slot_seek(_animation_tree, 0, 0.0)


func _prep_unarmed_block_hold_anim() -> void:
	if _punch_anim_node == null or not _unarmed_block_hold_ready:
		return
	# Attack-cancel crossfade owns the punch slots until it finishes.
	if _punch_crossfade_active:
		return
	# Block shares slot A — pin the crossfade so PunchAnimB can't leak through.
	_normalize_unarmed_block_to_slot_a()
	UnarmedBlockPoseConfig.set_tree_seek(_animation_tree, 0.0)


func _end_unarmed_blocking() -> void:
	_unarmed_blocking = false
	_attack_cancel_into_block = false


func _update_unarmed_block_input_hold() -> void:
	if _can_use_sword_shield_melee():
		if _unarmed_blocking:
			_end_unarmed_blocking()
		return
	# RMB holds the block while Unarmed is equipped.
	var want_block := (
		GroyperWeapons.is_unarmed(_equipped_weapon)
		and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
		and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)
	if want_block:
		if not _unarmed_blocking:
			_try_begin_unarmed_blocking()
	elif _unarmed_blocking:
		_try_end_unarmed_blocking()


func _update_unarmed_block_blend_state(delta: float) -> void:
	if not _unarmed_block_hold_ready or _punch_active:
		return
	# Keep attack→block slot crossfade ticking after the punch state clears.
	_update_punch_combo_crossfade(delta)
	var target := 1.0 if _unarmed_blocking else 0.0
	if not is_equal_approx(_unarmed_block_blend, target):
		var blend_time := BLOCK_HOLD_BLEND_OUT_TIME
		if target > _unarmed_block_blend:
			blend_time = (
				ATTACK_CANCEL_INTO_BLOCK_BLEND
				if _attack_cancel_into_block
				else BLOCK_HOLD_BLEND_IN_TIME
			)
		_unarmed_block_blend = lerpf(
			_unarmed_block_blend,
			target,
			_block_hold_blend_step(delta, blend_time)
		)
		if _attack_cancel_into_block and _unarmed_block_blend >= 0.99:
			_attack_cancel_into_block = false
	if _unarmed_block_blend <= 0.001 and not _unarmed_blocking:
		_attack_cancel_into_block = false
		_init_punch_animation_tree_state()
		return
	if _unarmed_block_blend > 0.001:
		_prep_unarmed_block_hold_anim()
		_apply_unarmed_block_tree_blend(_unarmed_block_blend)


func _apply_unarmed_block_tree_blend(amount: float) -> void:
	_punch_blend = amount
	UnarmedBlockPoseConfig.set_tree_blend(_animation_tree, amount)


func _process_unarmed_blocking(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = minf(velocity.y, 0.0)

	if is_melee_stunned():
		apply_knockback_friction(delta)
		var stunned_h := Vector3(velocity.x, 0.0, velocity.z)
		if _should_preserve_knockback_facing(stunned_h):
			_preserve_knockback_facing()
		else:
			_face_unarmed_block_facing(delta)
		move_with_ground_snap()
		var stunned_anim_dir := _get_block_locomotion_anim_direction(
			_get_camera_relative_input()
		)
		_update_locomotion_blend(
			delta,
			stunned_h.length(),
			UNARMED_BLOCK_WALK_SPEED,
			UNARMED_BLOCK_WALK_SPEED,
			stunned_anim_dir
		)
		_sync_camera_pivot_yaw()
		_set_camera_arm_pitch()
		_update_interact_hint()
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			_end_unarmed_blocking()
		return

	var move_dir := _get_camera_relative_input()
	var anim_move_dir := _get_block_locomotion_anim_direction(move_dir)
	var target_h := Vector3.ZERO
	if move_dir.length_squared() > 0.0001:
		target_h = move_dir.normalized() * UNARMED_BLOCK_WALK_SPEED
	var current_h := Vector3(velocity.x, 0.0, velocity.z)
	var new_h := current_h
	if not should_preserve_knockback_velocity():
		var move_rate := MOVE_ACCEL if target_h.length_squared() > 0.0001 else MOVE_STOP_DECEL
		new_h = current_h.move_toward(target_h, move_rate * delta)
		velocity.x = new_h.x
		velocity.z = new_h.z
	if _should_preserve_knockback_facing(new_h):
		_preserve_knockback_facing()
	else:
		_face_unarmed_block_facing(delta)
	move_with_ground_snap()
	_update_locomotion_blend(
		delta,
		new_h.length(),
		UNARMED_BLOCK_WALK_SPEED,
		UNARMED_BLOCK_WALK_SPEED,
		anim_move_dir
	)
	_sync_camera_pivot_yaw()
	_set_camera_arm_pitch()
	_update_interact_hint()

	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_end_unarmed_blocking()


func is_unarmed_blocking() -> bool:
	return _unarmed_blocking


func is_facing_punch_block(hit_info: Dictionary) -> bool:
	return _is_facing_melee_attack(hit_info)


func _try_begin_melee_blocking() -> void:
	if not _can_use_sword_shield_melee() or _combat_blocking:
		return
	if _combat_attacking:
		_cancel_melee_attack_for_block()
	_begin_melee_blocking()


func _try_end_melee_blocking() -> void:
	if not _combat_blocking:
		return
	_end_melee_blocking()


func _begin_melee_blocking() -> void:
	_combat_blocking = true


func _cancel_melee_attack_for_block() -> void:
	if not _combat_attacking:
		return
	_complete_melee_attack()
	_attack_cancel_into_block = true


func _end_melee_blocking(instant := false) -> void:
	_combat_blocking = false
	_attack_cancel_into_block = false
	if instant:
		_set_melee_block_hold_blend(0.0)
		_block_walk_amount = 0.0
		_apply_block_walk_locomotion_blend()


func _is_sprint_melee_attack_ready() -> bool:
	if _is_in_gun_aim_stance():
		return false
	var move_dir := _get_camera_relative_input()
	return Input.is_key_pressed(KEY_SHIFT) and move_dir.length_squared() > 0.0001


## True when the drawn weapon should use its own sprint+LMB attack (e.g. melee
## spin) instead of the default unarmed flying kick.
func _has_weapon_sprint_attack() -> bool:
	return (
		GroyperWeapons.has_sprint_attack(_equipped_weapon)
		and _can_use_sword_shield_melee()
		and _animation_player != null
		and _animation_player.has_animation(_spin_attack_anim_name)
	)


func _get_active_attack_anim_name() -> StringName:
	if _attack_spin:
		return _spin_attack_anim_name
	if _two_hand_combo_active:
		return _two_hand_combo_anim_name
	return _attack_anim_name


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


func _is_two_handed_melee_out() -> bool:
	return (
		GroyperWeapons.is_two_handed_melee(_equipped_weapon)
		and _melee_weapon_rig != null
		and _melee_weapon_rig.is_equipped()
	)


## Blocking walk speed, scaled down further by the two-hander weight penalty so a
## two-handed block walk is slower than a one-handed (or unarmed) block walk.
func _get_block_walk_speed() -> float:
	var speed := MELEE_BLOCK_WALK_SPEED
	if _is_two_handed_melee_out():
		speed *= TWO_HAND_MOVE_SPEED_MULT
	return speed


func _get_melee_attack_range() -> float:
	if _attack_spin:
		return MELEE_SPIN_ATTACK_RANGE
	return GroyperWeapons.get_melee_range(_equipped_weapon)


func _get_melee_base_attack_speed() -> float:
	return (
		GroyperWeapons.get_melee_attack_speed(_equipped_weapon)
		* LightningGemCombatScript.get_speed_mult(_equipped_weapon)
	)


func _try_begin_melee_attack() -> void:
	if not _can_use_sword_shield_melee() or _weapon_throw_active:
		return
	if _guard_break_lock_timer > 0.0 or is_melee_stunned():
		return
	if _combat_blocking:
		# LMB while holding block: throwable one-handers pitch the weapon.
		_try_begin_weapon_throw()
		return
	if _combat_attacking:
		# Torch is a single slash only — no reverse / spin combo chains.
		if GroyperWeapons.is_torch(_equipped_weapon):
			return
		if _can_queue_spin_to_slash_combo():
			_begin_melee_spin_to_slash_chain()
		elif _can_queue_melee_combo():
			if GroyperWeapons.is_two_handed_melee(_equipped_weapon):
				_begin_two_hand_combo()
			else:
				_begin_melee_attack_reverse()
		return
	if _attack_cooldown > 0.0:
		return
	if (
		not GroyperWeapons.is_torch(_equipped_weapon)
		and _is_sprint_melee_attack_ready()
		and _animation_player.has_animation(_spin_attack_anim_name)
	):
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
	ElementalGemStaminaScript.consume_on_attack(_equipped_weapon)
	_sync_gem_stamina_hud()
	_attack_spin = spin
	_two_hand_combo_active = false
	_melee_hitstop_remaining = 0.0
	_melee_hitstop_weapon = false
	_hammer_spin_hit_ids.clear()
	_hammer_spin_trail_timer = 0.0
	_attack_spin_visual_applied = false
	_attack_spin_chained = false
	_attack_elapsed = 0.0
	_attack_anim_time = 0.0
	_set_melee_attack_playback_speed(
		MELEE_SPIN_ATTACK_PLAYBACK_SPEED if spin else _get_melee_base_attack_speed()
	)
	_attack_timer = _get_melee_attack_length() / _get_melee_attack_playback_speed()
	_attack_struck = false
	_attack_reverse = false
	_attack_combo_used = false
	_attack_recovery_to_idle = false
	_attack_reverse_seek = 0.0
	_attack_cooldown = MELEE_SPIN_ATTACK_COOLDOWN if spin else MELEE_ATTACK_COOLDOWN
	_aim_melee_attack_at_nearest_target()
	_sync_melee_attack_entry_locomotion()
	if _melee_attack_anim_node != null:
		_melee_attack_anim_node.animation = _get_active_attack_anim_name()
	_sync_melee_attack_seek(-1.0)
	_fire_melee_attack_one_shot()


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
	_aim_melee_attack_at_nearest_target()
	var reverse_anim := _get_active_attack_reverse_anim_name()
	if _melee_attack_anim_node != null and _animation_player.has_animation(reverse_anim):
		_melee_attack_anim_node.animation = reverse_anim
	_tween_melee_attack_reverse_seek(seek_start, seek_end, reverse_duration)


## Two-handed combo: a fresh forward swing using the heavy hammer clip, rather than
## the reversed back-swing used by the one-handed weapons.
func _begin_two_hand_combo() -> void:
	_cancel_melee_attack_seek_tween()
	_two_hand_combo_active = true
	_melee_hitstop_remaining = 0.0
	_melee_hitstop_weapon = false
	_attack_combo_used = true
	_attack_spin = false
	_attack_spin_visual_applied = false
	_attack_spin_chained = false
	_attack_reverse = false
	_attack_recovery_to_idle = false
	_attack_struck = false
	_attack_elapsed = 0.0
	_attack_anim_time = 0.0
	_set_melee_attack_playback_speed(_get_melee_base_attack_speed())
	_attack_timer = _get_melee_attack_length() / _get_melee_attack_playback_speed()
	_aim_melee_attack_at_nearest_target()
	if _melee_attack_anim_node != null:
		_melee_attack_anim_node.animation = _two_hand_combo_anim_name
	_sync_melee_attack_seek(-1.0)
	_fire_melee_attack_one_shot()


func _begin_melee_spin_to_slash_chain() -> void:
	_cancel_melee_attack_seek_tween()
	_attack_spin_chained = true
	_attack_spin = false
	_attack_spin_visual_applied = false
	_attack_struck = false
	_attack_reverse = false
	_attack_recovery_to_idle = false
	_attack_combo_used = false
	_set_melee_attack_playback_speed(_get_melee_base_attack_speed())
	_aim_melee_attack_at_nearest_target()

	if _melee_attack_anim_node != null:
		_melee_attack_anim_node.animation = _attack_anim_name

	var anim_length := _get_melee_attack_length()
	var playback_speed := _get_melee_attack_playback_speed()
	_attack_elapsed = 0.0
	_attack_anim_time = 0.0
	_attack_timer = anim_length / playback_speed
	_sync_melee_attack_seek(-1.0)
	_fire_melee_attack_one_shot()


## Freeze the active punch seek or slow the weapon attack clip for a beat on connect.
func begin_melee_hitstop(duration: float = MELEE_HITSTOP_DURATION) -> void:
	if _melee_hitstop_remaining > 0.0:
		return
	var linger := maxf(duration, 0.0)
	if linger <= 0.0:
		return

	_melee_hitstop_remaining = linger
	if _punch_active and not _punch_exit_active:
		_melee_hitstop_weapon = false
		_punch_duration += linger
		return

	if _combat_attacking:
		_melee_hitstop_weapon = true
		_attack_timer += linger
		_set_melee_attack_playback_speed(MELEE_HITSTOP_PLAYBACK_SPEED)


func _update_melee_hitstop(delta: float) -> void:
	if _melee_hitstop_remaining <= 0.0:
		return
	_melee_hitstop_remaining -= delta
	if _melee_hitstop_remaining > 0.0:
		return
	_melee_hitstop_remaining = 0.0
	if _melee_hitstop_weapon and _combat_attacking:
		_set_melee_attack_playback_speed(_get_melee_base_attack_speed())
	_melee_hitstop_weapon = false


func _process_melee_attack(delta: float) -> void:
	_attack_elapsed += delta
	_attack_timer -= delta
	_update_melee_hitstop(delta)
	# This state returns before the main path's tick_melee_stun — without
	# ticking here, a mid-swing hit freezes the stun/knockback-hold timers (and
	# therefore velocity) for the entire rest of the attack.
	tick_melee_stun(delta)
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = minf(velocity.y, 0.0)

	var move_dir := _get_camera_relative_input()
	if (
		_attack_recovery_to_idle
		and move_dir.length_squared() > 0.0001
		and not is_melee_stunned()
		and not should_preserve_knockback_velocity()
	):
		# The return-to-idle reverse play is purely cosmetic — the swing's
		# damage is already resolved. Movement intent cancels into locomotion.
		_complete_melee_attack()
		return
	var target_h := Vector3.ZERO
	if move_dir.length_squared() > 0.0001:
		target_h = move_dir * _get_melee_attack_move_speed()
	var current_h := Vector3(velocity.x, 0.0, velocity.z)
	if not should_preserve_knockback_velocity():
		# Attacks don't interrupt on hits, so knockback residue rides through the
		# whole swing — MELEE_ATTACK_MOVE_ACCEL alone brakes it far too slowly.
		# Burn off anything above the attack's own move-speed budget first.
		var attack_speed_cap := _get_melee_attack_move_speed() + 0.1
		if current_h.length_squared() > attack_speed_cap * attack_speed_cap:
			apply_knockback_friction(delta)
			current_h = Vector3(velocity.x, 0.0, velocity.z)
		var new_h := current_h.move_toward(target_h, MELEE_ATTACK_MOVE_ACCEL * delta)
		velocity.x = new_h.x
		velocity.z = new_h.z
		current_h = new_h

	if _should_preserve_knockback_facing(current_h):
		_preserve_knockback_facing()
	elif _attack_recovery_to_idle:
		# Swing resolved — ease back toward camera-front / lock-on.
		_face_melee_camera_direction(delta)
		_attack_direction = _get_melee_flat_forward()
	else:
		# Hold the nearest-target facing chosen at attack start.
		_face_flat_direction(delta, _attack_direction)
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
				if _is_hammer_spin_attack():
					if _update_hammer_spin_attack(delta, anim_length):
						return
				else:
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
	_sync_camera_pivot_yaw()
	_set_camera_arm_pitch()
	_update_interact_hint()

	if _attack_timer <= 0.0:
		_finish_melee_attack()


func _apply_spin_attack_visual() -> void:
	_attack_spin_visual_applied = true
	SwordCrescentFXScript.spawn_spin_preview(self, _attack_direction, _get_melee_attack_range())
	_maybe_spawn_elemental_swing_dust()


func _maybe_spawn_elemental_swing_dust() -> void:
	if not ElementalAttackFXScript.weapon_has_elemental_trail(_equipped_weapon):
		return
	var fx_parent := get_parent()
	if fx_parent == null:
		fx_parent = self
	ElementalAttackFXScript.spawn_swing_dust(
		fx_parent,
		global_position,
		_attack_direction,
		ElementalAttackFXScript.get_trail_color(_equipped_weapon)
	)


## The war hammer's sprint attack replaces the one-moment spin slash with a
## continuous hitbox: live from early in the swing until the end, each enemy
## struck once, bodies launched as projectiles, and a blocked contact clashes
## and cuts the swing short.
func _is_hammer_spin_attack() -> bool:
	return (
		_attack_spin
		and GroyperWeapons.is_two_handed_melee(_equipped_weapon)
		and not GroyperWeapons.is_bladed_melee(_equipped_weapon)
	)


## Returns true when a clash interrupted the attack (the caller must bail out).
func _update_hammer_spin_attack(delta: float, anim_length: float) -> bool:
	if _attack_anim_time < anim_length * HammerSpinStrikeScript.STRIKE_START_FRACTION:
		return false

	_hammer_spin_trail_timer -= delta
	if _hammer_spin_trail_timer <= 0.0:
		_hammer_spin_trail_timer = HAMMER_SPIN_TRAIL_INTERVAL
		FlyingKickFXScript.spawn_trail_puff(
			get_parent(),
			global_position + Vector3(0.0, 0.9, 0.0)
		)

	for target in MeleeSwordSlashScript.find_spin_strike_targets(self):
		var target_id := target.get_instance_id()
		if _hammer_spin_hit_ids.has(target_id):
			continue
		_hammer_spin_hit_ids[target_id] = true
		var result: int = HammerSpinStrikeScript.resolve_contact(self, target)
		if result == HammerSpinStrikeScript.ContactResult.MISSED:
			continue
		_attack_struck = true
		begin_melee_hit_invulnerability()
		if result == HammerSpinStrikeScript.ContactResult.CLASHED:
			# The defender's block already stunned and shoved us via MeleeClash:
			# abort the rest of the swing.
			_complete_melee_attack()
			return true
	return false


func _apply_melee_strike() -> void:
	_attack_struck = true
	var attack_range := _get_melee_attack_range()
	var damage := GroyperWeapons.get_melee_damage(_equipped_weapon)
	if _attack_spin:
		var spin_hits := MeleeSwordSlashScript.apply_spin_strike(
			self, _attack_direction, damage
		)
		if spin_hits > 0:
			begin_melee_hit_invulnerability()
	else:
		var strike_target: Node = null
		if (
			_is_lock_on_facing_ready()
			and is_instance_valid(_lock_on_target)
			and MeleeSwordSlashScript.is_target_in_strike_range(
				self,
				_lock_on_target,
				attack_range
			)
		):
			strike_target = _lock_on_target
		if strike_target == null:
			strike_target = MeleeSwordSlashScript.find_strike_target(
				self,
				_attack_direction,
				attack_range
			)
		var two_handed := GroyperWeapons.is_two_handed_melee(_equipped_weapon)
		var struck := MeleeSwordSlashScript.apply_strike(
			self,
			_attack_direction,
			strike_target,
			attack_range,
			damage,
			two_handed
		)
		if two_handed:
			if GroyperWeapons.is_bladed_melee(_equipped_weapon):
				SwordCrescentFXScript.spawn_downward_slash(self, _attack_direction, attack_range)
				_maybe_spawn_elemental_swing_dust()
			else:
				# War hammer: the overhead slam detonates a mini explosion AOE
				# (1 damage + large knockback) whether or not the swing connects.
				var slam_hits: int = TwoHandHammerSlamScript.apply_slam(
					self,
					_attack_direction,
					attack_range
				)
				if slam_hits > 0:
					begin_melee_hitstop(TWO_HAND_HITSTOP_DURATION)
					begin_melee_hit_invulnerability()
				_maybe_spawn_elemental_swing_dust()
			if struck:
				TwoHandImpactFXScript.play_hit(self, strike_target, _attack_direction)
				begin_melee_hitstop(TWO_HAND_HITSTOP_DURATION)
				_trigger_melee_impact_camera()
				begin_melee_hit_invulnerability()
		else:
			if struck:
				_trigger_melee_impact_camera()
				begin_melee_hit_invulnerability()
			if not GroyperWeapons.is_torch(_equipped_weapon):
				SwordCrescentFXScript.spawn_preview(self, _attack_direction, attack_range)
				_maybe_spawn_elemental_swing_dust()


func _finish_melee_attack() -> void:
	if _attack_recovery_to_idle:
		_complete_melee_attack()
		return
	if _attack_reverse:
		_complete_melee_attack()
		return
	if _attack_spin:
		if not _begin_melee_attack_return_to_idle():
			_complete_melee_attack()
		return
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
	_two_hand_combo_active = false
	_melee_hitstop_remaining = 0.0
	_melee_hitstop_weapon = false
	_hammer_spin_hit_ids.clear()
	_attack_anim_time = 0.0
	_attack_reverse_seek = 0.0
	if _melee_attack_anim_node != null:
		_melee_attack_anim_node.animation = _attack_anim_name
	_sync_melee_attack_seek(-1.0)
	if _animation_tree != null and _animation_tree.active and _melee_combat_nodes_ready:
		_set_melee_attack_playback_speed(1.0)
		_restore_combat_idle_after_attack()
		_clear_melee_attack_one_shot()
	_sync_locomotion_after_melee_attack()


func _get_melee_locomotion_sync_speed(horizontal_speed: float, move_dir: Vector3) -> float:
	if horizontal_speed <= MELEE_COMBAT_IDLE_STOP_SPEED and move_dir.length_squared() > 0.0001:
		var in_gun_aim_stance := _is_in_gun_aim_stance()
		var wants_sprint := Input.is_key_pressed(KEY_SHIFT) and not in_gun_aim_stance
		var sprinting := wants_sprint and move_dir.length_squared() > 0.0001
		return RUN_SPEED if sprinting else WALK_SPEED
	return horizontal_speed


func _sync_melee_attack_entry_locomotion() -> void:
	_set_combat_idle_blend_instant(0.0)
	if _animation_tree == null or not _animation_tree.active:
		return
	var move_dir := _get_camera_relative_input()
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var speed := _get_melee_locomotion_sync_speed(horizontal_speed, move_dir)
	var targets := _compute_locomotion_blend_targets(speed, WALK_SPEED, RUN_SPEED, move_dir)
	_set_locomotion_tree_blends(targets.x, targets.y)


func _fire_melee_attack_one_shot() -> void:
	if not _melee_combat_nodes_ready or _animation_tree == null or not _animation_tree.active:
		return
	var request_path := "parameters/%s/request" % GroyperMeleeAnimConfig.ATTACK_ONE_SHOT
	_animation_tree.set(request_path, AnimationNodeOneShot.ONE_SHOT_REQUEST_NONE)
	_animation_tree.set(request_path, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	GameAudio.play_sword_swing(self, global_position)


func _clear_melee_attack_one_shot() -> void:
	if not _melee_combat_nodes_ready or _animation_tree == null or not _animation_tree.active:
		return
	var request_path := "parameters/%s/request" % GroyperMeleeAnimConfig.ATTACK_ONE_SHOT
	_animation_tree.set(request_path, AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
	_animation_tree.set(request_path, AnimationNodeOneShot.ONE_SHOT_REQUEST_NONE)


func _restore_combat_idle_after_attack() -> void:
	pass


func _sync_locomotion_after_melee_attack() -> void:
	if _animation_tree == null or not _animation_tree.active:
		return
	var move_dir := _get_camera_relative_input()
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var in_gun_aim_stance := _is_in_gun_aim_stance()
	var walk_speed := AIM_WALK_SPEED if in_gun_aim_stance else WALK_SPEED
	var run_speed := AIM_RUN_SPEED if in_gun_aim_stance else RUN_SPEED
	var speed := _get_melee_locomotion_sync_speed(horizontal_speed, move_dir)
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
	# Same as _process_melee_attack: this state bypasses the main path's
	# tick_melee_stun, so the stun/hold timers must tick here.
	tick_melee_stun(delta)
	var block_walk_speed := _get_block_walk_speed()
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = minf(velocity.y, 0.0)

	if is_melee_stunned():
		apply_knockback_friction(delta)
		var stunned_h := Vector3(velocity.x, 0.0, velocity.z)
		if _should_preserve_knockback_facing(stunned_h):
			_preserve_knockback_facing()
		else:
			_face_melee_camera_direction(delta)
		move_with_ground_snap()
		_update_melee_block_hold_for_locomotion(delta)
		_update_locomotion_blend(
			delta,
			stunned_h.length(),
			block_walk_speed,
			block_walk_speed
		)
		_sync_camera_pivot_yaw()
		_set_camera_arm_pitch()
		_update_interact_hint()
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			_end_melee_blocking()
		return

	var move_dir := _get_camera_relative_input()
	var anim_move_dir := _get_block_locomotion_anim_direction(move_dir)
	var target_h := Vector3.ZERO
	if move_dir.length_squared() > 0.0001:
		target_h = move_dir.normalized() * block_walk_speed
	var current_h := Vector3(velocity.x, 0.0, velocity.z)
	var new_h := current_h
	if not should_preserve_knockback_velocity():
		var move_rate := MOVE_ACCEL if target_h.length_squared() > 0.0001 else MOVE_STOP_DECEL
		new_h = current_h.move_toward(target_h, move_rate * delta)
		velocity.x = new_h.x
		velocity.z = new_h.z
	if _should_preserve_knockback_facing(new_h):
		_preserve_knockback_facing()
	else:
		_face_melee_camera_direction(delta)
	move_with_ground_snap()
	_update_melee_block_hold_for_locomotion(delta)
	_update_locomotion_blend(
		delta,
		new_h.length(),
		block_walk_speed,
		block_walk_speed,
		anim_move_dir
	)
	_sync_camera_pivot_yaw()
	_set_camera_arm_pitch()
	_update_interact_hint()

	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_end_melee_blocking()


func _get_hostage_walk_speed() -> float:
	return WALK_SPEED * HOSTAGE_MOVE_SPEED_MULT


func _process_hostage_locomotion(delta: float) -> void:
	var hostage_walk_speed := _get_hostage_walk_speed()

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = minf(velocity.y, 0.0)

	if is_melee_stunned():
		apply_knockback_friction(delta)
		var stunned_h := Vector3(velocity.x, 0.0, velocity.z)
		if _should_preserve_knockback_facing(stunned_h):
			_preserve_knockback_facing()
		else:
			_face_melee_camera_direction(delta)
		move_with_ground_snap()
		_update_melee_block_hold_for_locomotion(delta)
		_update_locomotion_blend(
			delta,
			stunned_h.length(),
			hostage_walk_speed,
			hostage_walk_speed
		)
		_sync_camera_pivot_yaw()
		_set_camera_arm_pitch()
		_update_interact_hint()
		return

	var move_dir := _get_camera_relative_input()
	var anim_move_dir := _get_block_locomotion_anim_direction(move_dir)
	var target_h := Vector3.ZERO
	if move_dir.length_squared() > 0.0001:
		target_h = move_dir.normalized() * hostage_walk_speed
	var current_h := Vector3(velocity.x, 0.0, velocity.z)
	var new_h := current_h
	if not should_preserve_knockback_velocity():
		var move_rate := MOVE_ACCEL if target_h.length_squared() > 0.0001 else MOVE_STOP_DECEL
		new_h = current_h.move_toward(target_h, move_rate * delta)
		velocity.x = new_h.x
		velocity.z = new_h.z
	if _should_preserve_knockback_facing(new_h):
		_preserve_knockback_facing()
	else:
		_face_melee_camera_direction(delta)
	move_with_ground_snap()
	_update_melee_block_hold_for_locomotion(delta)
	_update_locomotion_blend(
		delta,
		new_h.length(),
		hostage_walk_speed,
		hostage_walk_speed,
		anim_move_dir
	)
	_sync_camera_pivot_yaw()
	_set_camera_arm_pitch()
	_update_interact_hint()


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


## Snap onto the nearest in-range melee target (lock-on wins); else camera-forward.
func _aim_melee_attack_at_nearest_target() -> void:
	var attack_range := _get_melee_attack_range()
	var target: Node = null
	if (
		_is_lock_on_facing_ready()
		and is_instance_valid(_lock_on_target)
		and MeleeSwordSlashScript.is_target_in_strike_range(
			self, _lock_on_target, attack_range
		)
	):
		target = _lock_on_target
	if target == null:
		var probe := _get_melee_flat_forward()
		if probe.length_squared() < 0.0001:
			probe = Vector3.FORWARD
		# arc_dot_min -1: pick the nearest target in range, any direction.
		target = MeleeSwordSlashScript.find_strike_target(
			self, probe, attack_range, -1.0
		)
	if target != null:
		_attack_direction = MeleeSwordSlashScript.get_strike_direction(self, target)
	else:
		_attack_direction = _get_melee_flat_forward()
	if _model != null and _attack_direction.length_squared() > 0.0001:
		_model.rotation.y = atan2(_attack_direction.x, _attack_direction.z)


func _face_unarmed_block_facing(delta: float) -> void:
	if _is_lock_on_engaged():
		var facing := CombatLockOnScript.get_flat_facing(self, _lock_on_target)
		if facing.length_squared() > 0.0001:
			var turn_speed := AIM_FACING_SPEED * maxf(_lock_on_blend, 0.35)
			_face_flat_direction(delta, facing, turn_speed)
			return
	_face_melee_camera_direction(delta)


func _can_block_melee_hit(hit_info: Dictionary) -> bool:
	var melee := bool(hit_info.get("melee", false)) or bool(hit_info.get("punch_hit", false))
	if (
		_unarmed_blocking
		and melee
		and not bool(hit_info.get("knife_hit", false))
		and not bool(hit_info.get("sword_hit", false))
		and not bool(hit_info.get("hammer_hit", false))
		and _is_facing_melee_attack(hit_info)
	):
		return true
	return (
		_can_use_sword_shield_melee()
		and _combat_blocking
		and melee
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
	var result := BlockPoiseScript.apply_hit(self, hit_info)
	if result == BlockPoiseScript.Result.BROKEN:
		BlockPoiseScript.break_block(self, attacker, hit_info)
		return
	MeleeClashScript.resolve(self, attacker, hit_info)
	if _can_use_sword_shield_melee():
		_fire_block_parry_one_shot()


func get_block_poise_bonus() -> float:
	if not GroyperWeapons.is_melee(_equipped_weapon):
		return 0.0
	return GroyperWeapons.get_block_poise(_equipped_weapon)


func on_block_poise_broken(_attacker: Node, hit_info: Dictionary) -> void:
	_on_melee_shield_block_broken(hit_info)


func hold_knockback_velocity(duration: float) -> void:
	super.hold_knockback_velocity(duration)
	_capture_knockback_facing()


func tick_melee_stun(delta: float) -> void:
	super.tick_melee_stun(delta)
	# Keep punch-facing locked through a blocked-swing knockback even after the
	# short velocity hold expires.
	if (
		not _punch_active
		and not is_melee_stunned()
		and not should_preserve_knockback_velocity()
	):
		_knockback_facing_yaw_locked = INF


## Hook / elbow / flying-kick contacts that land on a block keep playing.
func keeps_melee_attack_through_block(hit_info: Dictionary) -> bool:
	if bool(hit_info.get("punch_hit", false)):
		return true
	return (_punch_active and not _punch_exit_active) or _flying_kick_active


## Called from the punch-into-block clash path — facing lock only, no anim swaps.
func on_punch_blocked_knockback(_defender: Node, _hit_info: Dictionary) -> void:
	# Never let a blocked contact leave us in melee stun — that early-returns
	# physics and reads as a stumble even when the punch clip keeps seeking.
	_melee_stun_timer = 0.0
	_clear_melee_clash_overlays()
	if _punch_active:
		_restore_punch_overlay_clip()
		_lock_punch_facing()
	elif _flying_kick_active and _model != null and _flying_kick_direction.length_squared() > 0.0001:
		_knockback_facing_yaw_locked = atan2(_flying_kick_direction.x, _flying_kick_direction.z)


func _restore_punch_overlay_clip() -> void:
	if not _punch_active or _get_active_punch_anim_node() == null:
		return
	var anim_path := _get_punch_anim_path_for_step(_punch_combo_step)
	if _animation_player != null and _animation_player.has_animation(anim_path):
		_set_punch_slot_animation(_punch_cross_slot, anim_path)
	# MeleeBlockHold sits above PunchBlend — keep the punch layer fully up so a
	# lingering block-hold fade can't peek through as Sword_Parry.
	if not _punch_exit_active:
		_set_punch_tree_blend(1.0)
	_sync_punch_anim_time(_punch_timer)


func _clear_melee_clash_overlays() -> void:
	# MeleeBlockHold / clash / attack one-shots sit above the punch layer and
	# use the Sword_Parry_Backward family — any leftover blend looks like a clash.
	_set_melee_block_hold_blend(0.0)
	_block_walk_amount = 0.0
	_apply_block_walk_locomotion_blend()
	if not _melee_combat_nodes_ready or _animation_tree == null or not _animation_tree.active:
		return
	for one_shot_name: StringName in [
		GroyperMeleeAnimConfig.BLOCK_CLASH_ONE_SHOT,
		GroyperMeleeAnimConfig.BLOCK_BREAK_ONE_SHOT,
		GroyperMeleeAnimConfig.ATTACK_ONE_SHOT,
	]:
		_animation_tree.set(
			"parameters/%s/request" % one_shot_name,
			AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT
		)


func _lock_punch_facing() -> void:
	if _model == null:
		return
	if _punch_direction.length_squared() > 0.0001:
		_knockback_facing_yaw_locked = atan2(_punch_direction.x, _punch_direction.z)
	else:
		_capture_knockback_facing()


## Snap the model onto the punch strike line and freeze yaw for the swing.
func _face_and_lock_punch_direction() -> void:
	_cancel_punch_facing_return()
	if _model != null and _punch_direction.length_squared() > 0.0001:
		_model.rotation.y = atan2(_punch_direction.x, _punch_direction.z)
	_lock_punch_facing()


## Retarget every combo hit toward the nearest enemy (wider than strike range).
func _retarget_punch_facing_to_nearest() -> void:
	var face_target := MeleePunch.find_nearest_face_target(self)
	if face_target != null:
		_punch_direction = MeleePunch.get_strike_direction(self, face_target)
	else:
		_punch_direction = MeleePunch.get_player_strike_direction(self)
	_face_and_lock_punch_direction()


## Finisher windup: unlock yaw so mouse look aims the launch.
func _is_punch_finisher_aiming() -> bool:
	return (
		_punch_active
		and not _punch_exit_active
		and not _punch_strike_applied
		and MeleePunch.is_combo_finisher_step(_punch_combo_step)
	)


func _begin_punch_finisher_aim() -> void:
	_cancel_punch_facing_return()
	_knockback_facing_yaw_locked = INF
	_sync_punch_finisher_aim_direction()
	if _model != null and _punch_direction.length_squared() > 0.0001:
		_model.rotation.y = atan2(_punch_direction.x, _punch_direction.z)


func _sync_punch_finisher_aim_direction() -> void:
	var cam_forward := Vector3.ZERO
	if _camera_pivot != null:
		cam_forward = -_camera_pivot.global_transform.basis.z
		cam_forward.y = 0.0
	if cam_forward.length_squared() < 0.0001:
		cam_forward = _get_melee_flat_forward()
	if cam_forward.length_squared() < 0.0001:
		return
	_punch_direction = cam_forward.normalized()


func _aim_punch_finisher_with_mouse_look(delta: float) -> void:
	if not _is_punch_finisher_aiming() or _model == null:
		return
	_sync_punch_finisher_aim_direction()
	if _punch_direction.length_squared() < 0.0001:
		return
	var target_yaw := atan2(_punch_direction.x, _punch_direction.z)
	var turn := clampf(AIM_FACING_SPEED * delta, 0.0, 1.0)
	_model.rotation.y = lerp_angle(_model.rotation.y, target_yaw, turn)
	_knockback_facing_yaw_locked = INF


func _begin_punch_facing_return() -> void:
	if _model == null:
		_cancel_punch_facing_return()
		return
	_punch_facing_return_active = true
	_punch_facing_return_from_yaw = _model.rotation.y
	# Release the hard lock so the exit ease owns yaw.
	_knockback_facing_yaw_locked = INF


func _cancel_punch_facing_return() -> void:
	_punch_facing_return_active = false
	_punch_facing_return_from_yaw = 0.0


## Prefer lock-on, else move intent, else camera-forward ("front").
func _get_punch_facing_return_target_yaw() -> float:
	var lock_facing := _get_lock_on_facing_dir()
	if lock_facing.length_squared() > 0.0001:
		return atan2(lock_facing.x, lock_facing.z)
	var move_dir := _get_camera_relative_input()
	if move_dir.length_squared() > 0.0001:
		return atan2(move_dir.x, move_dir.z)
	var front := _get_melee_flat_forward()
	if front.length_squared() > 0.0001:
		return atan2(front.x, front.z)
	if _model != null:
		return _model.rotation.y
	return 0.0


func _apply_punch_facing_return(eased: float) -> void:
	if not _punch_facing_return_active or _model == null:
		return
	var target_yaw := _get_punch_facing_return_target_yaw()
	_model.rotation.y = lerp_angle(_punch_facing_return_from_yaw, target_yaw, eased)


func _capture_knockback_facing() -> void:
	if _model != null:
		_knockback_facing_yaw_locked = _model.rotation.y


func _should_preserve_knockback_facing(horizontal_velocity: Vector3) -> bool:
	if _is_punch_finisher_aiming():
		return false
	if _punch_active and _knockback_facing_yaw_locked != INF:
		return true
	if horizontal_velocity.length_squared() <= 0.04:
		return false
	if should_preserve_knockback_velocity():
		return true
	# Hold is capped below stun length; keep facing through the residual slide.
	return is_melee_stunned() and _knockback_facing_yaw_locked != INF


func _preserve_knockback_facing() -> void:
	if _model == null:
		return
	if _knockback_facing_yaw_locked == INF:
		_knockback_facing_yaw_locked = _model.rotation.y
	_model.rotation.y = _knockback_facing_yaw_locked


func _on_melee_shield_block_broken(_hit_info: Dictionary) -> void:
	if _unarmed_blocking:
		_end_unarmed_blocking()
	if _punch_active:
		_finish_punch()
	_combat_blocking = false
	_block_walk_amount = 0.0
	_apply_block_walk_locomotion_blend()
	_set_melee_block_hold_blend(1.0)
	apply_melee_stun(BlockPoiseScript.BREAK_STUN)
	var lock_duration := BlockPoiseScript.BREAK_STUN
	# Flash is played by BlockPoise.break_block; keep break anim for armed/unarmed.
	if _melee_combat_nodes_ready and not _shield_block_break_path.is_empty():
		_animation_tree.set(
			"parameters/%s/request" % GroyperMeleeAnimConfig.BLOCK_BREAK_ONE_SHOT,
			AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
		)
		if _animation_player != null and _animation_player.has_animation(_shield_block_break_path):
			var break_anim := _animation_player.get_animation(_shield_block_break_path)
			if break_anim != null:
				lock_duration = maxf(lock_duration, break_anim.length)
	elif _animation_player != null:
		var stumble_path := StringName(
			"%s/%s"
			% [RigAnimConfigScript.LOCOMOTION_LIBRARY, RigAnimConfigScript.LOCOMOTION_STUMBLE]
		)
		if _animation_player.has_animation(stumble_path):
			var stumble_anim := _animation_player.get_animation(stumble_path)
			if stumble_anim != null:
				lock_duration = maxf(lock_duration, stumble_anim.length)
			_animation_player.play(stumble_path)
	_guard_break_lock_timer = lock_duration


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
	_knockback_facing_yaw_locked = _model.rotation.y if _model != null else 0.0
	_combat_blocking = false
	_fire_block_parry_one_shot()


func _process_shield_reflect(delta: float) -> void:
	tick_melee_stun(delta)
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = minf(velocity.y, 0.0)
	velocity.x = 0.0
	velocity.z = 0.0
	_reflect_elapsed += delta
	_reflect_window_remaining = maxf(_reflect_window_remaining - delta, 0.0)
	_face_melee_camera_direction(delta)
	_knockback_facing_yaw_locked = _model.rotation.y if _model != null else 0.0
	move_with_ground_snap()
	var reflect_move_dir := _get_block_locomotion_anim_direction(_get_camera_relative_input())
	_update_locomotion_blend(
		delta,
		MELEE_BLOCK_WALK_SPEED * _block_walk_amount,
		MELEE_BLOCK_WALK_SPEED,
		MELEE_BLOCK_WALK_SPEED,
		reflect_move_dir
	)
	_sync_camera_pivot_yaw()
	_set_camera_arm_pitch()
	_update_interact_hint()
	if _reflect_elapsed >= ShieldReflectScript.TOTAL_DURATION:
		_finish_shield_reflect()


func _finish_shield_reflect() -> void:
	_reflect_active = false
	_reflect_elapsed = 0.0
	_reflect_window_remaining = 0.0
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


func _setup_parry_throw_library() -> void:
	if _animation_player == null:
		return
	var raw := RigAnimUtils.load_skeleton_animation(PARRY_SPIN_SCENE)
	if raw == null:
		push_warning("GroyperOverworldPlayer: missing Skill 2 parry spin clip.")
		return
	var animation := RigAnimUtils.prepare_for_body_player(raw, false)
	RigAnimUtils.strip_root_motion(animation)
	# No half-time rescale: the doubled Meshy import timeline plays the
	# spin at half the authored speed, which is the intended pacing.
	animation.loop_mode = Animation.LOOP_NONE
	var library := AnimationLibrary.new()
	library.add_animation(PARRY_SPIN_CLIP, animation)
	if _animation_player.has_animation_library(PARRY_LIBRARY):
		_animation_player.remove_animation_library(PARRY_LIBRARY)
	_animation_player.add_animation_library(PARRY_LIBRARY, library)
	_parry_spin_duration = maxf(animation.length, 0.5)
	_parry_spin_ready = true


func _try_begin_unarmed_grab() -> void:
	if _hostage_take_active:
		_release_hostage()
		return
	if (
		_unarmed_grab_cooldown > 0.0
		or _unarmed_grab_window_timer > 0.0
		or _parry_throw_active
		or _overworld_defeated
		or is_melee_stunned()
		or _transition_locked
		or _dialog_active
		or _punch_active
		or _roll_active
		or _flying_kick_active
		or _is_fully_mounted()
		or _hit_reaction_active
		or _unarmed_blocking
		or not GroyperWeapons.is_unarmed(_equipped_weapon)
	):
		return
	_unarmed_grab_cooldown = UNARMED_GRAB_COOLDOWN
	_begin_unarmed_grab_window()

	var direction := get_punch_facing_direction()
	var target := UnarmedParryThrowScript.find_grab_target(self, direction)
	if target == null:
		var chair := _find_grab_chair(direction)
		if chair != null:
			_end_unarmed_grab_reach_for_capture()
			_begin_prop_hostage_take(chair)
		return
	# Blocking enemies cannot be grabbed. Window stays open for a counter spin.
	if UnarmedHostageTakeScript.is_blocking_grab_target(target):
		return
	# Non-blocking + hostage-capable → human shield. Spin throw is counter-only.
	if target.has_method("begin_hostage_capture"):
		_end_unarmed_grab_reach_for_capture()
		_begin_hostage_take(target)


## Opens the grab-reach / counter window. Incoming melee during this window
## becomes a spin throw via try_unarmed_parry instead of damage.
func _begin_unarmed_grab_window() -> void:
	_unarmed_grab_window_timer = UNARMED_GRAB_WINDOW
	_unarmed_grab_reach_active = true
	CombatHitFlashScript.flash_block(self)
	GameAudio.play_punch_throw(self, global_position)
	_play_unarmed_grab_reach_anim()


func _clear_unarmed_grab_window() -> void:
	_unarmed_grab_window_timer = 0.0
	_unarmed_grab_reach_active = false


func _end_unarmed_grab_reach_for_capture() -> void:
	_clear_unarmed_grab_window()
	if _punch_active:
		_finish_punch()


## Grab reach uses the jab clip with strike disabled — readable "reaching" pose
## that also defines the counter window visually.
func _play_unarmed_grab_reach_anim() -> void:
	if _punch_active or not _punch_nodes_ready():
		return
	var anim_path := PunchPoseConfig.get_animation_path()
	if _animation_player.get_animation(anim_path) == null:
		return
	var direction := get_punch_facing_direction()
	if direction.length_squared() < 0.0001:
		direction = Vector3.FORWARD
	_clear_melee_clash_overlays()
	_punch_combo_step = MeleePunch.ComboStep.HOOK
	_punch_seek_base = 0.0
	_punch_combo_buffered = false
	_melee_hitstop_remaining = 0.0
	_melee_hitstop_weapon = false
	_punch_duration = UNARMED_GRAB_WINDOW
	_punch_timer = 0.0
	_punch_active = true
	_punch_strike_applied = true
	_punch_direction = direction.normalized()
	_punch_cooldown = 0.0
	_punch_blend = 0.0
	_punch_exit_active = false
	_punch_exit_timer = 0.0
	_unarmed_blocking = false
	_unarmed_block_blend = 0.0
	_face_and_lock_punch_direction()
	_punch_cross_slot = 0
	_punch_cross_blend = 0.0
	_punch_crossfade_active = false
	_set_punch_slot_animation(0, anim_path)
	PunchPoseConfig.set_cross_blend(_animation_tree, 0.0)
	_init_punch_animation_tree_state()
	_sync_knife_hand_visual()


## Counter-grab: if Q grab reach is active and a melee hit lands, spin-throw
## the attacker instead of taking damage.
func try_unarmed_parry(attacker: Node, _hit_info: Dictionary) -> bool:
	if _unarmed_grab_window_timer <= 0.0 and not _unarmed_grab_reach_active:
		return false
	if (
		_parry_throw_active
		or _hostage_take_active
		or _overworld_defeated
		or not GroyperWeapons.is_unarmed(_equipped_weapon)
	):
		return false
	if not UnarmedParryThrowScript.is_counter_grab_victim_eligible(self, attacker):
		return false
	_clear_unarmed_grab_window()
	if _punch_active:
		_finish_punch()
	_begin_parry_throw(attacker as CharacterBody3D)
	return true


func _begin_parry_throw(victim: CharacterBody3D) -> void:
	_parry_throw_active = true
	if _unarmed_blocking:
		_try_end_unarmed_blocking()
	# Lock-on would orbit the camera around the victim being spun and hijack
	# the toss direction — free look steers the throw instead.
	_clear_lock_on()
	set_transition_locked(true)
	if _weapon_rig != null and not _weapon_rig.is_holstered():
		_weapon_rig.reset_to_holster()
		_reset_reload_input()
		_update_combat_ui()

	CombatHitFlashScript.flash_parry(victim)
	GameAudio.play_punch_throw(self, global_position)

	if _parry_spin_ready and _roll_anim_node != null and _animation_tree != null:
		_roll_anim_node.animation = StringName("%s/%s" % [PARRY_LIBRARY, PARRY_SPIN_CLIP])
		# Longer fade so the grab tweens smoothly into the spin.
		var one_shot := _get_roll_one_shot_node()
		if one_shot != null:
			one_shot.fadein_time = PARRY_SPIN_FADEIN
		_animation_tree.set(
			"parameters/%s/request" % ROLL_ONE_SHOT,
			AnimationNodeOneShot.ONE_SHOT_REQUEST_NONE
		)
		_animation_tree.set(
			"parameters/%s/request" % ROLL_ONE_SHOT,
			AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
		)

	var controller := UnarmedParryThrowScript.new()
	controller.name = "UnarmedParryThrow"
	get_parent().add_child(controller)
	controller.begin(self, victim, _parry_spin_duration)


## Toss aim for the parry throw: wherever the camera is looking, flattened.
func get_parry_throw_direction() -> Vector3:
	var forward := -_camera_pivot.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		return Vector3.FORWARD
	return forward.normalized()


## The throw controller releases the player the moment the victim is tossed.
func notify_parry_throw_released() -> void:
	if not _parry_throw_active:
		return
	_parry_throw_active = false
	set_transition_locked(false)
	var one_shot := _get_roll_one_shot_node()
	if one_shot != null:
		one_shot.fadein_time = ROLL_ANIM_FADEIN


func _begin_hostage_take(victim: CharacterBody3D) -> void:
	_hostage_take_active = true
	_clear_lock_on()
	_block_walk_amount = 0.0
	_apply_block_walk_locomotion_blend()
	_set_melee_block_hold_blend(1.0)
	CombatHitFlashScript.flash_parry(victim)
	GameAudio.play_punch_throw(self, global_position)

	var controller := UnarmedHostageTakeScript.new()
	controller.name = "UnarmedHostageTake"
	get_parent().add_child(controller)
	controller.begin(self, victim)
	_hostage_controller = controller


## Fallback grab when no NPC is in reach: the nearest loose SitChair in the
## punch arc. Same carry/shield/shove loop, driven by PropHostageTake.
func _find_grab_chair(direction: Vector3) -> RigidBody3D:
	var grab_dir := direction.normalized()
	var best: RigidBody3D = null
	var best_dist_sq := INF
	for node in get_tree().get_nodes_in_group(&"sit_chair"):
		var chair := node as RigidBody3D
		if chair == null or not is_instance_valid(chair):
			continue
		if chair.has_method("can_be_hostage_held") and not chair.can_be_hostage_held():
			continue
		var to_chair := chair.global_position - global_position
		to_chair.y = 0.0
		var dist_sq := to_chair.length_squared()
		if dist_sq > MeleePunch.RANGE * MeleePunch.RANGE or dist_sq < 0.0001:
			continue
		if to_chair.normalized().dot(grab_dir) < MeleePunch.ARC_DOT_MIN:
			continue
		if dist_sq < best_dist_sq:
			best_dist_sq = dist_sq
			best = chair
	return best


func _begin_prop_hostage_take(prop: RigidBody3D) -> void:
	_hostage_take_active = true
	_clear_lock_on()
	_block_walk_amount = 0.0
	_apply_block_walk_locomotion_blend()
	_set_melee_block_hold_blend(1.0)
	GameAudio.play_punch_throw(self, global_position)

	var controller := PropHostageTakeScript.new()
	controller.name = "PropHostageTake"
	get_parent().add_child(controller)
	controller.begin(self, prop)
	_hostage_controller = controller


func _release_hostage(enter_aggro := true) -> void:
	if not _hostage_take_active:
		return
	if _hostage_controller != null and is_instance_valid(_hostage_controller):
		_hostage_controller.release(enter_aggro)
	else:
		notify_hostage_take_ended()


func _try_hostage_shove() -> void:
	if not _hostage_take_active or _hostage_controller == null:
		return
	if not is_instance_valid(_hostage_controller):
		notify_hostage_take_ended()
		return
	_hostage_controller.shove()


func _end_hostage_pose() -> void:
	_set_melee_block_hold_blend(0.0)
	_block_walk_amount = 0.0
	_apply_block_walk_locomotion_blend()
	_sync_locomotion_after_melee_attack()


func notify_hostage_take_ended() -> void:
	_hostage_take_active = false
	_hostage_controller = null
	_end_hostage_pose()


func is_hostage_take_active() -> bool:
	return _hostage_take_active


func get_hostage_victim() -> Node3D:
	if not _hostage_take_active or _hostage_controller == null:
		return null
	if not is_instance_valid(_hostage_controller):
		return null
	return _hostage_controller.get_victim()


func _get_roll_one_shot_node() -> AnimationNodeOneShot:
	if _animation_tree == null:
		return null
	var blend_tree := _animation_tree.tree_root as AnimationNodeBlendTree
	if blend_tree == null or not blend_tree.has_node(ROLL_ONE_SHOT):
		return null
	return blend_tree.get_node(ROLL_ONE_SHOT) as AnimationNodeOneShot


func _setup_cover_pose_library() -> void:
	if _animation_player == null:
		push_error("GroyperOverworldPlayer: missing AnimationPlayer on body.")
		return

	var source := CoverPoseExtractScript.load_authored_library()
	if source == null:
		push_error(
			"GroyperOverworldPlayer: missing cover_pose.tres â€” "
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
			"GroyperOverworldPlayer: missing cover_peek_aim.tres â€” "
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
	if _flying_kick_active:
		return
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
		or _hit_reaction_active
		or _is_lasso_swing_sequence_active()
		or is_lasso_grapple_swinging()
		or _overworld_defeated
		or _dialog_active
		or DialogManager.is_showing()
	):
		return false
	if _weapon_rig != null:
		if _weapon_rig.is_overworld_reloading():
			return false
		# Always-drawn firearms may enter cover (the rig holsters on entry).
		if not _weapon_rig.is_holstered() and not _is_run_and_gun_weapon():
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
		or _hit_reaction_active
		or _is_lasso_swing_sequence_active()
		or is_lasso_grapple_swinging()
		or _cover_walk_enter_active
		or _cover_exit_active
		or _cover_crouch_active
		or _overworld_defeated
		or _dialog_active
		or DialogManager.is_showing()
	):
		return false
	if _weapon_rig != null:
		if _weapon_rig.is_overworld_reloading():
			return false
		# Always-drawn firearms may vault (the rig holsters during the move).
		if not _weapon_rig.is_holstered() and not _is_run_and_gun_weapon():
			return false
	return true


func _is_running_for_vault() -> bool:
	var move_dir := _get_camera_relative_input()
	var sprinting := (
		Input.is_key_pressed(KEY_SHIFT)
		and move_dir.length_squared() > 0.0001
		and not _is_slow_aim_stance()
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
	_start_vault(clip_name, spot, VAULT_PLAYBACK_SPEED)


func _start_vault(clip_name: StringName, spot: Dictionary, playback_speed: float = 1.0) -> void:
	var anim_path := StringName("%s/%s" % [VaultConfigScript.LIBRARY_NAME, clip_name])
	if _animation_player == null or not _animation_player.has_animation(anim_path):
		push_error("GroyperOverworldPlayer: missing vault clip '%s'." % clip_name)
		return

	var safe_speed := maxf(playback_speed, 0.001)
	var animation := _animation_player.get_animation(anim_path)
	_vault_duration = animation.length / safe_speed
	_vault_move_duration = maxf(_vault_duration * VAULT_MOVE_TIME_SCALE, 0.001)
	_vault_timer = 0.0
	_vault_exit_active = false
	_vault_exit_timer = 0.0
	_vault_drop_exit = false
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
	_set_vault_playback_speed(safe_speed)
	_restart_vault_animation()
	_set_vault_tree_blend(0.0)


func _set_vault_playback_speed(speed: float) -> void:
	if _animation_tree == null:
		return
	var path := "parameters/%s/scale" % VAULT_TIME_SCALE
	if _animation_tree.get(path) != null:
		_animation_tree.set(path, maxf(speed, 0.001))


func _get_mount_model_yaw_for_horse(horse: StupidHorse) -> float:
	var horse_forward := horse.get_facing_direction()
	horse_forward.y = 0.0
	if horse_forward.length_squared() > 0.0001:
		return atan2(horse_forward.x, horse_forward.z)
	return _model.rotation.y if _model != null else 0.0


func _build_mount_vault_spot(horse: StupidHorse) -> Dictionary:
	var mount := horse.get_rider_mount_node()
	var start := global_position
	var end := mount.global_position if mount != null else start
	var approach := Vector3(end.x - start.x, 0.0, end.z - start.z)
	var mount_yaw := _get_mount_model_yaw_for_horse(horse)
	var travel_facing := (
		atan2(approach.x, approach.z)
		if approach.length_squared() > 0.0001
		else mount_yaw
	)
	var horse_forward := horse.get_facing_direction()
	horse_forward.y = 0.0
	if horse_forward.length_squared() < 0.0001:
		horse_forward = approach
	if horse_forward.length_squared() < 0.0001:
		horse_forward = Vector3.FORWARD
	return {
		"start": start,
		"end": end,
		"facing_yaw": travel_facing,
		"cross_direction": horse_forward.normalized(),
	}


func _build_dismount_vault_spot(start: Vector3, landing: Vector3) -> Dictionary:
	var end := landing
	end.y = start.y
	var travel := Vector3(end.x - start.x, 0.0, end.z - start.z)
	var travel_facing := (
		atan2(travel.x, travel.z)
		if travel.length_squared() > 0.0001
		else GroyperBodyUtils.MODEL_YAW_OFFSET
	)
	var exit_dir := travel
	if exit_dir.length_squared() < 0.0001:
		exit_dir = Vector3.FORWARD
	return {
		"start": start,
		"end": end,
		"facing_yaw": travel_facing,
		"cross_direction": exit_dir.normalized(),
	}


func _start_dismount_vault(landing: Vector3) -> bool:
	var anim_path := StringName(
		"%s/%s" % [VaultConfigScript.LIBRARY_NAME, VaultConfigScript.WALK_VAULT]
	)
	if _animation_player == null or not _animation_player.has_animation(anim_path):
		return false

	var start := global_position
	var flat_landing := landing
	flat_landing.y = start.y
	_dismount_vault_landing = flat_landing
	if _mounted_horse != null:
		_mount_vault_yaw_from = _get_mount_model_yaw_for_horse(_mounted_horse)
	elif _model != null:
		_mount_vault_yaw_from = _model.rotation.y
	else:
		_mount_vault_yaw_from = 0.0
	_mount_vault_yaw_to = GroyperBodyUtils.MODEL_YAW_OFFSET
	_vault_for_dismount = true
	_start_vault(
		VaultConfigScript.WALK_VAULT,
		_build_dismount_vault_spot(start, flat_landing),
		DISMOUNT_VAULT_PLAYBACK_SPEED
	)
	return _vault_active


func _complete_dismount_vault() -> void:
	global_position = _dismount_vault_landing
	_set_model_facing_yaw(_mount_vault_yaw_to)
	_set_vault_tree_blend(0.0)
	_vault_active = false
	_vault_for_dismount = false
	_vault_exit_active = false
	_vault_exit_timer = 0.0
	_vault_timer = 0.0
	_vault_duration = 0.0
	_vault_move_duration = 0.0
	_set_vault_playback_speed(1.0)
	call_deferred("_begin_dismount_settle_after_vault")


func _begin_dismount_settle_after_vault() -> void:
	_tween_mount_settle(
		false,
		Callable(self, "_finish_dismount_after_settle").bind(_dismount_vault_landing)
	)


func _start_mount_vault(horse: StupidHorse) -> bool:
	var anim_path := StringName(
		"%s/%s" % [VaultConfigScript.LIBRARY_NAME, VaultConfigScript.WALK_VAULT]
	)
	if _animation_player == null or not _animation_player.has_animation(anim_path):
		return false
	_mount_vault_yaw_from = _model.rotation.y if _model != null else 0.0
	_mount_vault_yaw_to = _get_mount_model_yaw_for_horse(horse)
	_vault_for_mount = true
	_start_vault(
		VaultConfigScript.WALK_VAULT,
		_build_mount_vault_spot(horse),
		MOUNT_VAULT_PLAYBACK_SPEED
	)
	return _vault_active


func _complete_mount_vault() -> void:
	global_position = _vault_end
	_set_model_facing_yaw(_mount_vault_yaw_to)
	_set_vault_tree_blend(0.0)
	_vault_active = false
	_vault_for_mount = false
	_vault_exit_active = false
	_vault_exit_timer = 0.0
	_vault_timer = 0.0
	_vault_duration = 0.0
	_vault_move_duration = 0.0
	_set_vault_playback_speed(1.0)
	call_deferred("_finish_mount_on_horse")


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
	var pos: Vector3
	var hop_height := MOUNT_HOP_HEIGHT if _vault_for_mount else DISMOUNT_HOP_HEIGHT
	if _vault_for_mount or _vault_for_dismount:
		pos = _hop_world_position(_vault_start, _vault_end, eased, hop_height)
	else:
		pos = _vault_start.lerp(_vault_end, eased)
		pos.y = _vault_floor_y + sin(move_progress * PI) * VAULT_PEAK_HEIGHT
	global_position = pos
	velocity = Vector3.ZERO

	if _vault_for_mount or _vault_for_dismount:
		_set_model_facing_yaw(
			lerp_angle(_mount_vault_yaw_from, _mount_vault_yaw_to, eased)
		)
	elif move_progress >= 1.0:
		var exit_yaw := atan2(_vault_cross_direction.x, _vault_cross_direction.z)
		_set_model_facing_yaw(exit_yaw)
	else:
		_set_model_facing_yaw(_vault_facing_yaw)

	var enter_t := clampf(_vault_timer / maxf(VAULT_ANIM_FADEIN, 0.001), 0.0, 1.0)
	var enter_eased := enter_t * enter_t * (3.0 - 2.0 * enter_t)
	_set_vault_tree_blend(enter_eased)
	_update_vault_locomotion_blend(delta, move_progress)

	if move_progress >= 1.0:
		if _vault_for_mount:
			_complete_mount_vault()
		elif _vault_for_dismount:
			_complete_dismount_vault()
		else:
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
	_vault_drop_exit = _will_drop_after_vault_at(global_position)
	if _vault_drop_exit:
		_begin_vault_drop_fall_handoff()


func _will_drop_after_vault_at(world_pos: Vector3) -> bool:
	return not _has_floor_below_world_position(world_pos)


func _has_floor_below_world_position(world_pos: Vector3) -> bool:
	var space_state := get_world_3d().direct_space_state
	if space_state == null:
		return true
	var from := world_pos + Vector3(0.0, 0.2, 0.0)
	var to := world_pos + Vector3(0.0, -VAULT_DROP_FLOOR_PROBE_DEPTH, 0.0)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	return not space_state.intersect_ray(query).is_empty()


func _begin_vault_drop_fall_handoff() -> void:
	_climb_fall_state.begin_vault_drop_fall_handoff(self)


func _update_vault_exit(delta: float) -> void:
	_vault_exit_timer += delta
	var progress := clampf(
		_vault_exit_timer / maxf(VAULT_EXIT_BLEND_DURATION, 0.001),
		0.0,
		1.0
	)
	var eased := progress * progress * (3.0 - 2.0 * progress)
	if _vault_drop_exit:
		_set_vault_tree_blend(1.0 - eased)
		_climb_fall_state.set_master_blend(self, eased)
	else:
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
	move_and_slide()
	_update_climb_fall(delta)

	_update_facing(delta, move_dir)
	if _vault_drop_exit:
		_reset_locomotion_tree_blends()
	else:
		_update_locomotion_blend(delta, new_h.length(), walk_speed, run_speed, move_dir)

	if progress >= 1.0:
		_finish_vault()


func _get_vault_move_context() -> Dictionary:
	var move_dir := _get_camera_relative_input()
	var slow_aim_stance := _is_slow_aim_stance()
	var sprinting := (
		Input.is_key_pressed(KEY_SHIFT)
		and move_dir.length_squared() > 0.0001
		and not slow_aim_stance
	)
	var walk_speed := AIM_WALK_SPEED if slow_aim_stance else WALK_SPEED
	var run_speed := AIM_RUN_SPEED if slow_aim_stance else RUN_SPEED
	if slow_aim_stance and move_dir.length_squared() > 0.0001:
		walk_speed = _get_aim_walk_speed_for_direction(move_dir, walk_speed)
	var carry_mult := GroyperWeapons.get_carry_move_speed_mult(
		_equipped_weapon,
		PlayerInventory.get_strength()
	)
	walk_speed *= carry_mult
	run_speed *= carry_mult
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
	_set_vault_playback_speed(1.0)
	_vault_active = false
	_vault_for_mount = false
	_vault_for_dismount = false
	_mount_vault_yaw_from = 0.0
	_mount_vault_yaw_to = 0.0
	_dismount_vault_landing = Vector3.ZERO
	_vault_exit_active = false
	_vault_exit_timer = 0.0
	_vault_drop_exit = false
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
		var reloading := _weapon_rig.is_overworld_reloading()
		_weapon_rig.set_cover_crouch_peek(false)
		_weapon_rig.set_cover_crouch_hold(false)
		# Leaving cover mid-reload keeps the reload going standing — do not
		# reset_to_holster (that clears reload after ammo was already ejected).
		if not reloading and not _weapon_rig.is_holstered():
			_weapon_rig.reset_to_holster()


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
	if (
		_cover_crouch_active
		or _cover_walk_enter_active
		or _cover_exit_active
		or _vault_active
		or _hit_reaction_active
		or _is_lasso_swing_sequence_active()
		or is_lasso_grapple_swinging()
	):
		return
	if (
		_roll_active
		or _overworld_defeated
		or _dialog_active
		or DialogManager.is_showing()
	):
		return
	if _weapon_rig != null:
		if _weapon_rig.is_overworld_reloading():
			return
		# Always-drawn firearms may roll (the rig holsters during the dodge).
		if not _weapon_rig.is_holstered() and not _is_run_and_gun_weapon():
			return

	var move_dir := _get_camera_relative_input()
	if move_dir.length_squared() < 0.0001:
		return

	var sprinting := (
		Input.is_key_pressed(KEY_SHIFT)
		and not _is_slow_aim_stance()
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
	move_and_slide()

	_roll_timer += delta
	_face_flat_direction(delta, _roll_direction)
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
	move_and_slide()

	var target_yaw := _roll_exit_start_yaw
	var lock_facing := _get_lock_on_facing_dir()
	if lock_facing.length_squared() > 0.0001:
		target_yaw = atan2(lock_facing.x, lock_facing.z)
	elif move_dir.length_squared() > 0.0001:
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
		and _guard_break_lock_timer <= 0.0
		and not _transition_locked
		and not _dialog_active
		and not DialogManager.is_showing()
		and not InventoryMenuManager.is_open()
		and not TownMapManager.is_open()
		and not ShopBuyManager.is_showing()
		and not BonfireMenuManager.is_showing()
		and not _punch_active
		and not _combat_attacking
		and not _weapon_throw_active
		and not _roll_active
		and not _vault_active
		and not _cover_crouch_active
		and not _cover_walk_enter_active
		and not _cover_exit_active
		and not _mount_transition_active
		and not _is_fully_mounted()
		and not _hit_reaction_active
		and not _face_punch_reaction_active
		and not _reflect_active
		and _punch_cooldown <= 0.0
		and not _unarmed_blocking
		and _unarmed_block_blend < 0.05
		and not _hostage_take_active
		and not _flying_kick_active
		and _punch_nodes_ready()
	)


func _punch_nodes_ready() -> bool:
	if _animation_tree == null or not _animation_tree.active:
		return false
	if (
		_punch_anim_node == null
		or _punch_anim_node_b == null
		or _punch_blend_node == null
		or _punch_cross_blend_node == null
	):
		return false
	var anim_path := PunchPoseConfig.get_animation_path()
	return _animation_player != null and _animation_player.has_animation(anim_path)


func _get_active_punch_anim_node() -> AnimationNodeAnimation:
	return _punch_anim_node_b if _punch_cross_slot == 1 else _punch_anim_node


func _set_punch_slot_animation(slot: int, anim_path: StringName) -> void:
	var node := _punch_anim_node_b if slot == 1 else _punch_anim_node
	if node != null:
		node.animation = anim_path


func _update_punch_combo_crossfade(delta: float) -> void:
	if not _punch_crossfade_active:
		return
	_punch_crossfade_timer += delta
	var progress := clampf(
		_punch_crossfade_timer / maxf(_punch_crossfade_duration, 0.001),
		0.0,
		1.0
	)
	var eased := progress * progress * (3.0 - 2.0 * progress)
	_punch_cross_blend = lerpf(_punch_crossfade_from, _punch_crossfade_to, eased)
	PunchPoseConfig.set_cross_blend(_animation_tree, _punch_cross_blend)
	# Hold the outgoing clip on its end pose while the new hit fades in.
	var from_slot := 1 - _punch_cross_slot
	PunchPoseConfig.set_slot_seek(_animation_tree, from_slot, _punch_hold_seek)
	if progress >= 1.0:
		_punch_crossfade_active = false
		_punch_cross_blend = _punch_crossfade_to
		PunchPoseConfig.set_cross_blend(_animation_tree, _punch_cross_blend)
		_punch_crossfade_duration = PunchPoseConfig.COMBO_CROSSFADE
		# Attack→block: settle onto slot A so the normal block prep path stays simple.
		if _unarmed_blocking and not _punch_active:
			_normalize_unarmed_block_to_slot_a()


func _try_punch() -> void:
	if _combat_blocking and _can_use_sword_shield_melee() and not _reflect_active:
		_try_begin_shield_reflect()
		return
	# Punch exit is interruptible so a new jab can start with no post-swing wait.
	if _punch_exit_active:
		_finish_punch()
	if _punch_active and PlayerInventory.has_knife and not _punch_strike_applied:
		_throw_knife()
		return
	# Combo follow-ups only buffer here — next step starts after this clip finishes.
	if _punch_active and _can_buffer_punch_combo():
		_punch_combo_buffered = true
		return
	if not _can_punch():
		return
	if _can_start_flying_kick():
		_start_flying_kick()
		return
	_start_punch(MeleePunch.get_player_strike_direction(self))


func get_punch_facing_direction() -> Vector3:
	if _combat_attacking and _attack_direction.length_squared() > 0.0001:
		return _attack_direction
	var lock_facing := _get_lock_on_facing_dir()
	if lock_facing.length_squared() > 0.0001:
		return lock_facing
	if _combat_blocking or _hostage_take_active or _can_use_sword_shield_melee():
		return _get_melee_flat_forward()
	if _unarmed_blocking or _unarmed_block_blend > 0.35:
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
	if not _punch_nodes_ready():
		return

	var anim_path := PunchPoseConfig.get_animation_path()
	var animation := _animation_player.get_animation(anim_path)
	if animation == null:
		push_error("GroyperOverworldPlayer: missing punch clip.")
		return

	# Hit times come from Animation markers on the punch clips.
	PunchPoseConfig.ensure_strike_timing()

	# Clear any leftover shield-clash / block-hold layer before the punch owns
	# the upper body — those clips are Sword_Parry_Backward and read as a clash.
	_clear_melee_clash_overlays()

	_punch_combo_step = MeleePunch.ComboStep.HOOK
	_punch_seek_base = 0.0
	_punch_combo_buffered = false
	_melee_hitstop_remaining = 0.0
	_melee_hitstop_weapon = false
	var punch_speed := LightningGemCombatScript.get_speed_mult(GroyperWeapons.Id.UNARMED)
	_punch_duration = (
		MeleePunch.get_attack_duration_for_step(_punch_combo_step, animation.length) / punch_speed
	)
	_punch_timer = 0.0
	_punch_active = true
	ElementalGemStaminaScript.consume_on_attack(GroyperWeapons.Id.UNARMED)
	_sync_gem_stamina_hud()
	_punch_strike_applied = false
	_punch_direction = direction.normalized()
	_punch_cooldown = MeleePunch.PLAYER_COOLDOWN / punch_speed
	_punch_blend = 0.0
	_punch_exit_active = false
	_punch_exit_timer = 0.0
	_unarmed_blocking = false
	_unarmed_block_blend = 0.0
	# Turn onto the nearest target (or fallback strike line) for the whole jab.
	_retarget_punch_facing_to_nearest()

	_punch_cross_slot = 0
	_punch_cross_blend = 0.0
	_punch_crossfade_active = false
	_set_punch_slot_animation(0, anim_path)
	_init_punch_animation_tree_state()
	PunchPoseConfig.set_cross_blend(_animation_tree, 0.0)
	_sync_knife_hand_visual()
	GameAudio.play_punch_throw(self, global_position)


## Punch playback pacing: the F jab keeps whatever weapon is out in hand, and a
## two-hander slows the jab slightly (0.85x).
func _get_punch_speed_mult() -> float:
	if _is_two_handed_melee_out():
		return TWO_HAND_PUNCH_SPEED_MULT
	return 1.0


func _get_punch_anim_path_for_step(step: MeleePunch.ComboStep) -> StringName:
	match step:
		MeleePunch.ComboStep.HOOK:
			return PunchPoseConfig.get_animation_path()
		MeleePunch.ComboStep.ELBOW_FIRST, MeleePunch.ComboStep.ELBOW_SECOND:
			return PunchPoseConfig.get_elbow_strike_path()
		_:
			return PunchPoseConfig.get_double_combo_path()


func _get_punch_anim_length_for_step(step: MeleePunch.ComboStep) -> float:
	if _animation_player == null:
		return 0.0
	var anim_path := _get_punch_anim_path_for_step(step)
	if not _animation_player.has_animation(anim_path):
		return 0.0
	return _animation_player.get_animation(anim_path).length


func _get_punch_anim_time() -> float:
	return _punch_seek_base + MeleePunch.get_anim_time(_punch_timer, _punch_combo_step)


func _get_active_punch_timer_speed() -> float:
	var speed := _get_punch_speed_mult()
	if MeleePunch.uses_snappy_player_speed(_punch_combo_step):
		speed *= MeleePunch.PLAYER_ATTACK_SPEED_MULT
	return speed


func _can_buffer_punch_combo() -> bool:
	if (
		not _punch_active
		or _punch_exit_active
		or PlayerInventory.has_knife
		or not MeleePunch.can_chain_combo(_punch_combo_step)
	):
		return false
	return MeleePunch.can_accept_combo_buffer(
		_punch_combo_step,
		_get_punch_anim_time(),
		_get_punch_anim_length_for_step(_punch_combo_step)
	)


## Start a buffered follow-up only after the current step clip has finished.
func _try_start_buffered_punch_combo() -> bool:
	if not _punch_combo_buffered:
		return false
	if (
		PlayerInventory.has_knife
		or not _punch_strike_applied
		or not MeleePunch.can_chain_combo(_punch_combo_step)
	):
		return false
	_punch_combo_buffered = false
	_begin_punch_combo_next()
	return true


func _begin_punch_combo_next() -> void:
	var previous_step := _punch_combo_step
	var previous_path := _get_punch_anim_path_for_step(previous_step)
	var hold_seek := _get_punch_anim_time()
	_punch_combo_step = MeleePunch.get_next_combo_step(_punch_combo_step)
	_punch_seek_base = MeleePunch.get_step_seek_base(_punch_combo_step)
	var anim_path := _get_punch_anim_path_for_step(_punch_combo_step)
	var anim_length := _get_punch_anim_length_for_step(_punch_combo_step)
	if anim_length <= 0.0:
		_begin_punch_exit()
		return

	# Same as opening hook: never let a prior blocked-hit clash layer ride into
	# elbow / double-combo follow-ups.
	_clear_melee_clash_overlays()

	var punch_speed := LightningGemCombatScript.get_speed_mult(GroyperWeapons.Id.UNARMED)
	_punch_duration = (
		MeleePunch.get_attack_duration_for_step(_punch_combo_step, anim_length) / punch_speed
	)
	_punch_timer = 0.0
	ElementalGemStaminaScript.consume_on_attack(GroyperWeapons.Id.UNARMED)
	_sync_gem_stamina_hud()
	_punch_strike_applied = false
	_melee_hitstop_remaining = 0.0
	_melee_hitstop_weapon = false
	GameAudio.play_punch_throw(self, global_position)
	_punch_exit_active = false
	_punch_exit_timer = 0.0
	_punch_combo_buffered = false
	# Stay fully punched-in so clip swaps don't dip through locomotion.
	_punch_blend = 1.0
	if MeleePunch.is_combo_finisher_step(_punch_combo_step):
		# Last hit: free mouse-look aim instead of snapping to nearest enemy.
		_begin_punch_finisher_aim()
	else:
		_retarget_punch_facing_to_nearest()
	_set_punch_tree_blend(1.0)

	if previous_path == anim_path:
		# Same-clip segments (double hit 1 → 2): continue the seek, no swap.
		_sync_punch_anim_time(0.0)
	else:
		# Crossfade into the next clip on the inactive punch slot.
		var to_slot := 1 - _punch_cross_slot
		_punch_hold_seek = hold_seek
		_set_punch_slot_animation(to_slot, anim_path)
		PunchPoseConfig.set_slot_seek(_animation_tree, _punch_cross_slot, hold_seek)
		PunchPoseConfig.set_slot_seek(_animation_tree, to_slot, _punch_seek_base)
		_punch_crossfade_from = float(_punch_cross_slot)
		_punch_crossfade_to = float(to_slot)
		_punch_cross_slot = to_slot
		_punch_crossfade_timer = 0.0
		_punch_crossfade_active = true
		_punch_crossfade_duration = PunchPoseConfig.COMBO_CROSSFADE
		_sync_punch_anim_time(0.0)
	_sync_knife_hand_visual()


func _get_knife_throw_direction() -> Vector3:
	return _get_aim_direction()


func _get_knife_throw_speed(direction: Vector3) -> float:
	var upward := clampf(direction.y, 0.0, 1.0)
	return KNIFE_THROW_SPEED * lerpf(1.0, KNIFE_THROW_HIGH_AIM_BOOST, upward / 0.72)


func _try_begin_weapon_throw() -> void:
	if _weapon_throw_active or _weapon_throw_exit_active or not _weapon_throw_nodes_ready:
		return
	if not GroyperWeapons.is_throwable(_equipped_weapon):
		return
	if GroyperWeapons.is_dynamite(_equipped_weapon):
		if not _can_use_dynamite() or _combat_attacking:
			return
		_begin_weapon_throw()
		return
	if not _can_use_sword_shield_melee() or _combat_attacking:
		return
	_begin_weapon_throw()


func _begin_weapon_throw() -> void:
	_try_end_melee_blocking()
	_weapon_throw_active = true
	_weapon_throw_released = false
	_weapon_throw_exit_active = false
	_weapon_throw_exit_timer = 0.0
	_weapon_throw_timer = 0.0
	_weapon_throw_blend = 0.0
	_weapon_throw_weapon_id = _equipped_weapon
	_face_melee_camera_direction(999.0)
	_weapon_throw_direction = _get_melee_flat_forward()
	if GroyperWeapons.is_dynamite(_equipped_weapon):
		_sync_dynamite_hand_visual()
	elif GroyperWeapons.is_torch(_equipped_weapon):
		_sync_torch_hand_visual()

	var anim_length := 0.8
	var pitch_path := WeaponThrowConfigScript.get_animation_path()
	if _animation_player != null and _animation_player.has_animation(pitch_path):
		anim_length = _animation_player.get_animation(pitch_path).length
	_weapon_throw_duration = anim_length / WeaponThrowConfigScript.PLAYBACK_SPEED
	WeaponThrowConfigScript.set_tree_scale(
		_animation_tree,
		WeaponThrowConfigScript.PLAYBACK_SPEED
	)
	WeaponThrowConfigScript.set_tree_seek(_animation_tree, 0.0)


func _update_weapon_throw(delta: float) -> void:
	if _weapon_throw_exit_active:
		_weapon_throw_exit_timer += delta
		var progress := clampf(
			_weapon_throw_exit_timer / maxf(WeaponThrowConfigScript.EXIT_BLEND_DURATION, 0.001),
			0.0,
			1.0
		)
		var eased := 1.0 - pow(1.0 - progress, 2.6)
		WeaponThrowConfigScript.set_tree_blend(_animation_tree, lerpf(_weapon_throw_blend, 0.0, eased))
		if progress >= 1.0:
			_weapon_throw_exit_active = false
			_weapon_throw_blend = 0.0
			WeaponThrowConfigScript.set_tree_blend(_animation_tree, 0.0)
		return

	_weapon_throw_timer += delta
	_weapon_throw_blend = move_toward(
		_weapon_throw_blend,
		1.0,
		WeaponThrowConfigScript.BLEND_IN_SPEED * delta
	)
	WeaponThrowConfigScript.set_tree_blend(_animation_tree, _weapon_throw_blend)

	# Until the weapon leaves the hand, the throw line tracks the camera so the
	# player can adjust their aim during the wind-up.
	if not _weapon_throw_released:
		var aim_dir := _get_melee_flat_forward()
		if aim_dir.length_squared() > 0.0001:
			_weapon_throw_direction = aim_dir

	if (
		not _weapon_throw_released
		and _weapon_throw_timer >= _weapon_throw_duration * WeaponThrowConfigScript.RELEASE_FRACTION
	):
		_release_thrown_weapon()

	if _weapon_throw_timer >= _weapon_throw_duration:
		# Pitch finished: fade the overlay out onto the (now unarmed) locomotion.
		_weapon_throw_active = false
		_weapon_throw_exit_active = true
		_weapon_throw_exit_timer = 0.0


func _release_thrown_weapon() -> void:
	_weapon_throw_released = true
	var weapon_id := _weapon_throw_weapon_id
	var direction := _weapon_throw_direction
	if direction.length_squared() < 0.0001:
		direction = _get_melee_flat_forward()
	direction = direction.normalized()

	var scene_root := get_tree().current_scene
	if scene_root != null:
		var exclude: Array = [self]
		var hitbox := get_node_or_null("Hitbox")
		if hitbox is CollisionObject3D:
			exclude.append(hitbox)
		var speed := WeaponThrowConfigScript.get_throw_speed(
			throw_strength,
			GroyperWeapons.get_throw_weight(weapon_id)
		)
		var origin := global_position + Vector3(0.0, 1.35, 0.0) + direction * 0.55
		if GroyperWeapons.is_dynamite(weapon_id):
			if _dynamite_hand_visual != null and _dynamite_hand_visual.visible:
				origin = _dynamite_hand_visual.global_position
			if _dynamite_hand_visual != null:
				_dynamite_hand_visual.visible = false
			DynamiteProjectileScript.spawn_thrown(
				scene_root,
				origin,
				direction,
				speed,
				exclude,
				self
			)
			GameAudio.play_knife_throw_whoosh(scene_root, origin)
			_sync_dynamite_hand_visual()
			PlayerInventory.remove_one_weapon(weapon_id)
			_ammo = PlayerInventory.count_weapon(GroyperWeapons.Id.DYNAMITE)
			if _ammo_hud:
				_ammo_hud.sync_rounds(_ammo)
			if _ammo <= 0:
				equip_weapon(GroyperWeapons.Id.UNARMED, false)
			else:
				# Next stick pops back into the hand after the pitch.
				call_deferred("_sync_dynamite_hand_visual")
			return

		if GroyperWeapons.is_torch(weapon_id):
			if _torch_hand_visual != null and _torch_hand_visual.visible:
				origin = _torch_hand_visual.global_position
			if _torch_hand_visual != null:
				_torch_hand_visual.visible = false
			TorchProjectileScript.spawn_thrown(
				scene_root,
				origin,
				direction,
				speed,
				exclude,
				self
			)
			GameAudio.play_knife_throw_whoosh(scene_root, origin)
			equip_weapon(GroyperWeapons.Id.UNARMED, false)
			PlayerInventory.remove_one_weapon(weapon_id)
			return

		ThrownWeaponProjectileScript.spawn(
			scene_root,
			weapon_id,
			origin,
			direction,
			speed,
			exclude,
			self
		)
		GameAudio.play_knife_throw_whoosh(scene_root, origin)

	# Hand is empty now: swap to fists first (instant holster of the melee rig),
	# then pull the thrown weapon out of the inventory so its hip holster
	# empties too. The overlay fade-out lands on the unarmed idle.
	equip_weapon(GroyperWeapons.Id.UNARMED, false)
	PlayerInventory.remove_one_weapon(weapon_id)


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
	PunchPoseConfig.set_slot_seek(
		_animation_tree,
		_punch_cross_slot,
		_punch_seek_base + MeleePunch.get_anim_time(time, _punch_combo_step)
	)


func _update_punch_overlay(delta: float) -> void:
	if _punch_exit_active:
		_punch_exit_timer += delta
		var progress := clampf(
			_punch_exit_timer / maxf(MeleePunch.get_exit_blend_duration(), 0.001),
			0.0,
			1.0
		)
		var eased := 1.0 - pow(1.0 - progress, PUNCH_FACING_RETURN_EASE)
		_set_punch_tree_blend(lerpf(1.0, 0.0, eased))
		# Ease yaw back to camera-front / move / lock-on with the overlay fade.
		_apply_punch_facing_return(eased)
		_sync_punch_anim_time(_punch_timer)
		_sync_knife_hand_visual()
		if progress >= 1.0:
			_finish_punch()
		return

	# Connection linger: hold the strike seek pose without advancing the punch timeline.
	if _melee_hitstop_remaining > 0.0 and not _melee_hitstop_weapon:
		_update_melee_hitstop(delta)
		if _is_punch_finisher_aiming():
			_aim_punch_finisher_with_mouse_look(delta)
		_sync_punch_anim_time(_punch_timer)
		_update_punch_combo_crossfade(delta)
		_sync_knife_hand_visual()
		return

	_punch_timer += delta * _get_active_punch_timer_speed()
	# Opening hook fades in; combo follow-ups stay fully blended so clip swaps
	# never dip through locomotion between hits.
	if _punch_combo_step == MeleePunch.ComboStep.HOOK:
		var fade_progress := clampf(
			_punch_timer / maxf(MeleePunch.get_anim_fadein(), 0.001),
			0.0,
			1.0
		)
		var blend_target := fade_progress * fade_progress * (3.0 - 2.0 * fade_progress)
		var blend_step := 1.0 - exp(-PUNCH_BLEND_IN_SPEED * delta)
		_set_punch_tree_blend(lerpf(_punch_blend, blend_target, blend_step))
	else:
		_set_punch_tree_blend(1.0)
	if _is_punch_finisher_aiming():
		_aim_punch_finisher_with_mouse_look(delta)
	_sync_punch_anim_time(_punch_timer)
	_update_punch_combo_crossfade(delta)
	_sync_knife_hand_visual()

	if _punch_timer >= _punch_duration:
		if not _try_start_buffered_punch_combo():
			_begin_punch_exit()


func _apply_punch_strike_if_ready() -> void:
	if not _punch_active or _punch_exit_active or _punch_strike_applied:
		return
	if _punch_timer < MeleePunch.get_strike_real_duration(_punch_combo_step):
		return

	# Finisher keeps mouse-look aim; earlier hits retarget to the nearest enemy.
	if MeleePunch.is_combo_finisher_step(_punch_combo_step):
		_sync_punch_finisher_aim_direction()
		if _model != null and _punch_direction.length_squared() > 0.0001:
			_model.rotation.y = atan2(_punch_direction.x, _punch_direction.z)
	else:
		_retarget_punch_facing_to_nearest()
	var nearest := MeleePunch.find_nearest_strike_target(self)

	_punch_strike_applied = true
	if ElementalAttackFXScript.weapon_has_elemental_trail(GroyperWeapons.Id.UNARMED):
		var fx_parent := get_parent()
		if fx_parent == null:
			fx_parent = self
		ElementalAttackFXScript.spawn_swing_dust(
			fx_parent,
			global_position,
			_punch_direction,
			ElementalAttackFXScript.get_trail_color(GroyperWeapons.Id.UNARMED)
		)

	# Finisher (combo hit 4): same launch as a sprint flying kick.
	if MeleePunch.is_combo_finisher_step(_punch_combo_step):
		if nearest != null:
			_resolve_punch_combo_finisher(nearest)
		else:
			var lunge_speed := MeleePunch.get_lunge_speed_for_attacker(self)
			velocity.x += _punch_direction.x * lunge_speed
			velocity.z += _punch_direction.z * lunge_speed
		return

	var struck := MeleePunch.apply_strike(self, _punch_direction, nearest, {
		"melee_stun_duration": MeleePunch.get_stun_duration_for_step(_punch_combo_step),
	})
	var blocked_swing := struck and should_preserve_knockback_velocity()
	if struck:
		begin_melee_hit_invulnerability()
		# Blocked punches (hook or elbow) already got separation knockback —
		# keep the swing/combo clean: no impact camera / hit-lunge/bounce.
		if blocked_swing:
			_clear_melee_clash_overlays()
			_restore_punch_overlay_clip()
			_lock_punch_facing()
		else:
			_trigger_melee_impact_camera()
			velocity.x += _punch_direction.x * MeleePunch.PLAYER_HIT_LUNGE_SPEED
			velocity.z += _punch_direction.z * MeleePunch.PLAYER_HIT_LUNGE_SPEED
			velocity.x -= _punch_direction.x * MeleePunch.PLAYER_HIT_BOUNCE_SPEED
			velocity.z -= _punch_direction.z * MeleePunch.PLAYER_HIT_BOUNCE_SPEED
	else:
		var miss_lunge := MeleePunch.get_lunge_speed_for_attacker(self)
		velocity.x += _punch_direction.x * miss_lunge
		velocity.z += _punch_direction.z * miss_lunge


## Combo finisher: launch the victim like a flying-kick contact (ragdoll toss).
func _resolve_punch_combo_finisher(target: Node) -> void:
	begin_melee_hit_invulnerability()
	var direction := _punch_direction
	var contact := global_position + Vector3(0.0, 1.05, 0.0)
	if target is Node3D:
		contact = (target as Node3D).global_position + Vector3(0.0, 1.05, 0.0)
	var fx_parent: Node = get_parent()
	if fx_parent == null:
		fx_parent = self

	var hit_info := {
		"position": contact,
		"direction": direction,
		"shooter": self,
		"melee": true,
		"punch_hit": true,
		"chip_damage": 1.0,
		"knockback_speed": FLYING_KICK_BLOCK_KNOCKBACK_SPEED,
		"knockback_up": 0.9,
	}

	if UnarmedPunchBlockScript.can_block_punch(target, hit_info):
		UnarmedPunchBlockScript.resolve(self, target, hit_info)
		FlyingKickFXScript.spawn_blocked(fx_parent, contact)
		GameAudio.play_punch(self, contact)
		_clear_melee_clash_overlays()
		_restore_punch_overlay_clip()
		_lock_punch_facing()
	elif _is_flying_kick_toss_eligible(target):
		if target.has_method("enter_overworld_combat"):
			target.enter_overworld_combat()
		var controller := UnarmedParryThrowScript.new()
		controller.name = "UnarmedParryThrow"
		fx_parent.add_child(controller)
		controller.begin_shove(self, target as CharacterBody3D, direction)
		FlyingKickFXScript.spawn_impact(fx_parent, contact, direction)
		GameAudio.play_punch(self, contact)
		_trigger_melee_impact_camera()
		apply_camera_shake(FLYING_KICK_CAMERA_SHAKE)
	else:
		MeleePunch.apply_strike(self, direction, target, {
			"damage": 1.0,
			"knockdown": true,
			"kill_launch_velocity": (
				direction * UnarmedParryThrowScript.TOSS_FORWARD_SPEED
				+ Vector3.UP * UnarmedParryThrowScript.TOSS_UP_SPEED
			),
		})
		if (
			target is CharacterBody3D
			and target.has_method("is_defeated")
			and target.is_defeated()
		):
			var corpse_watch := UnarmedParryThrowScript.new()
			corpse_watch.name = "UnarmedParryThrow"
			fx_parent.add_child(corpse_watch)
			corpse_watch.begin_corpse_flight(self, target as CharacterBody3D, direction)
		FlyingKickFXScript.spawn_impact(fx_parent, contact, direction)
		_trigger_melee_impact_camera()
		apply_camera_shake(FLYING_KICK_CAMERA_SHAKE)


func _begin_punch_exit() -> void:
	if _punch_exit_active:
		return

	# Grab reach ended without a counter — close the counter window with the pose.
	if _unarmed_grab_reach_active:
		_clear_unarmed_grab_window()
	_punch_exit_active = true
	_punch_exit_timer = 0.0
	_begin_punch_facing_return()
	_sync_knife_hand_visual()
	_begin_melee_camera_release()


func _finish_punch() -> void:
	if _unarmed_grab_reach_active:
		_clear_unarmed_grab_window()
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
	_melee_hitstop_remaining = 0.0
	_melee_hitstop_weapon = false
	_cancel_punch_facing_return()
	_init_punch_animation_tree_state()
	_sync_knife_hand_visual()


func _can_start_flying_kick() -> bool:
	return (
		_flying_kick_nodes_ready
		and not _flying_kick_active
		and _flying_kick_cooldown <= 0.0
		and is_on_floor()
		and _is_sprint_melee_attack_ready()
		and not _has_weapon_sprint_attack()
	)


func _start_flying_kick() -> void:
	var direction := _get_camera_relative_input()
	if direction.length_squared() < 0.0001:
		direction = get_punch_facing_direction()
	if direction.length_squared() < 0.0001:
		return
	direction = direction.normalized()
	# Snap onto a target already inside the kick arc at takeoff; after this the
	# direction is locked for the whole attack.
	var snap_target := MeleePunch.find_strike_target(self, direction)
	if snap_target != null:
		direction = MeleePunch.get_strike_direction(self, snap_target)

	var anim_length := _animation_player.get_animation(
		FlyingKickConfigScript.get_animation_path()
	).length

	_flying_kick_active = true
	_flying_kick_timer = 0.0
	_flying_kick_duration = anim_length / FLYING_KICK_PLAYBACK_SPEED
	_flying_kick_direction = direction
	_flying_kick_struck = false
	_flying_kick_cooldown = FLYING_KICK_COOLDOWN
	_flying_kick_blend = 0.0
	_flying_kick_exit_active = false
	_flying_kick_exit_timer = 0.0
	_flying_kick_trail_timer = FLYING_KICK_TRAIL_INTERVAL

	velocity.x = direction.x * FLYING_KICK_FORWARD_SPEED
	velocity.z = direction.z * FLYING_KICK_FORWARD_SPEED
	velocity.y = FLYING_KICK_RISE_SPEED
	_model.rotation.y = atan2(direction.x, direction.z)

	FlyingKickConfigScript.set_tree_scale(_animation_tree, FLYING_KICK_PLAYBACK_SPEED)
	FlyingKickConfigScript.set_tree_seek(_animation_tree, 0.0)
	GameAudio.play_sword_swing(self, global_position)
	FlyingKickFXScript.spawn_launch_burst(
		get_parent(),
		global_position + Vector3(0.0, 0.35, 0.0),
		direction
	)


func _update_flying_kick(delta: float) -> void:
	_flying_kick_timer += delta
	_flying_kick_blend = move_toward(_flying_kick_blend, 1.0, FLYING_KICK_BLEND_IN_SPEED * delta)
	FlyingKickConfigScript.set_tree_blend(_animation_tree, _flying_kick_blend)

	# Direction is locked at input: horizontal velocity stays on the takeoff line.
	velocity.x = _flying_kick_direction.x * FLYING_KICK_FORWARD_SPEED
	velocity.z = _flying_kick_direction.z * FLYING_KICK_FORWARD_SPEED
	velocity.y -= GRAVITY * delta
	move_and_slide()

	_flying_kick_trail_timer -= delta
	if _flying_kick_trail_timer <= 0.0:
		_flying_kick_trail_timer = FLYING_KICK_TRAIL_INTERVAL
		FlyingKickFXScript.spawn_trail_puff(
			get_parent(),
			global_position + Vector3(0.0, 0.9, 0.0)
		)

	if (
		not _flying_kick_struck
		and _flying_kick_timer >= _flying_kick_duration * FLYING_KICK_STRIKE_START_FRACTION
	):
		var target := MeleePunch.find_strike_target(self, _flying_kick_direction)
		if target is Node3D:
			var to_target: Vector3 = (target as Node3D).global_position - global_position
			to_target.y = 0.0
			if to_target.length() <= FLYING_KICK_CONTACT_RANGE:
				_resolve_flying_kick_contact(target)
				return

	if _flying_kick_timer >= _flying_kick_duration or (
		_flying_kick_timer > FLYING_KICK_MIN_AIR_TIME and is_on_floor()
	):
		_finish_flying_kick()


func _resolve_flying_kick_contact(target: Node) -> void:
	_flying_kick_struck = true
	begin_melee_hit_invulnerability()
	var direction := _flying_kick_direction
	var contact := global_position + Vector3(0.0, 1.05, 0.0)
	if target is Node3D:
		contact = (target as Node3D).global_position + Vector3(0.0, 1.05, 0.0)
	var fx_parent: Node = get_parent()

	var hit_info := {
		"position": contact,
		"direction": direction,
		"shooter": self,
		"melee": true,
		"punch_hit": true,
		"chip_damage": 1.0,
		"knockback_speed": FLYING_KICK_BLOCK_KNOCKBACK_SPEED,
		"knockback_up": 0.9,
	}

	if UnarmedPunchBlockScript.can_block_punch(target, hit_info):
		# Blocked: poise chip / possible break via shared UnarmedPunchBlock.
		UnarmedPunchBlockScript.resolve(self, target, hit_info)
		FlyingKickFXScript.spawn_blocked(fx_parent, contact)
		GameAudio.play_punch(self, contact)
	elif _is_flying_kick_toss_eligible(target):
		# Clean hit: launch the victim with the same flight the grab throw uses
		# (begin_shove deals its 1 base damage when the body lands).
		if target.has_method("enter_overworld_combat"):
			target.enter_overworld_combat()
		var controller := UnarmedParryThrowScript.new()
		controller.name = "UnarmedParryThrow"
		get_parent().add_child(controller)
		controller.begin_shove(self, target as CharacterBody3D, direction)
		FlyingKickFXScript.spawn_impact(fx_parent, contact, direction)
		GameAudio.play_punch(self, contact)
	else:
		# Target can't ragdoll-fly via the throw (skeletons, bosses): standard
		# strike, but a killing blow launches the defeat ragdoll on the same
		# toss arc so the body still flies instead of dying at the spot.
		MeleePunch.apply_strike(self, direction, target, {
			"kill_launch_velocity": (
				direction * UnarmedParryThrowScript.TOSS_FORWARD_SPEED
				+ Vector3.UP * UnarmedParryThrowScript.TOSS_UP_SPEED
			),
		})
		if (
			target is CharacterBody3D
			and target.has_method("is_defeated")
			and target.is_defeated()
		):
			# The launched corpse is a weapon too: bowl over anything it clips,
			# same as a tossed townsperson in the hotel brawl.
			var corpse_watch := UnarmedParryThrowScript.new()
			corpse_watch.name = "UnarmedParryThrow"
			get_parent().add_child(corpse_watch)
			corpse_watch.begin_corpse_flight(self, target as CharacterBody3D, direction)
		FlyingKickFXScript.spawn_impact(fx_parent, contact, direction)

	apply_camera_shake(FLYING_KICK_CAMERA_SHAKE)
	_bounce_off_flying_kick()


## Like UnarmedParryThrow.is_grab_victim_eligible, minus the mid-punch
## exclusion: that gate keeps the proactive Q grab honest, but a flying kick
## should launch aggro NPCs even while they're swinging — otherwise fighting
## targets always fall through to the flat knockdown instead of the toss.
func _is_flying_kick_toss_eligible(target: Node) -> bool:
	if target == null or not is_instance_valid(target) or target == self:
		return false
	if not (target is CharacterBody3D):
		return false
	if target.has_method("is_defeated") and target.is_defeated():
		return false
	if not target.has_method("begin_lasso_capture") or not target.has_method("get_lasso_ragdoll"):
		return false
	if target.has_method("is_lassoable") and not target.is_lassoable():
		return false
	if target.has_method("is_hostage_captured") and target.is_hostage_captured():
		return false
	return true


func _bounce_off_flying_kick() -> void:
	# Pop up and away from the target; facing stays on the kick direction and
	# movement control returns immediately. The airborne arc hands off to the
	# climb-fall (Fall 2) animation on its own.
	velocity.x = -_flying_kick_direction.x * FLYING_KICK_BOUNCE_BACK_SPEED
	velocity.z = -_flying_kick_direction.z * FLYING_KICK_BOUNCE_BACK_SPEED
	velocity.y = FLYING_KICK_BOUNCE_UP_SPEED
	_finish_flying_kick()


func _finish_flying_kick() -> void:
	_flying_kick_active = false
	_flying_kick_exit_active = true
	_flying_kick_exit_timer = 0.0


func _update_flying_kick_exit(delta: float) -> void:
	if not _flying_kick_exit_active:
		return
	_flying_kick_exit_timer += delta
	var progress := clampf(
		_flying_kick_exit_timer / maxf(FLYING_KICK_EXIT_BLEND, 0.001),
		0.0,
		1.0
	)
	var eased := 1.0 - pow(1.0 - progress, 2.0)
	FlyingKickConfigScript.set_tree_blend(_animation_tree, _flying_kick_blend * (1.0 - eased))
	if progress >= 1.0:
		_init_flying_kick_animation_tree_state()


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


func _wants_interior_explore_camera() -> bool:
	return (
		ShopSession.is_interior_space()
		and not _overworld_combat_active
		and _mounted_horse == null
	)


func _update_interior_explore_camera_blend(delta: float) -> void:
	var target := 1.0 if _wants_interior_explore_camera() else 0.0
	var blend_speed := _get_interior_camera_blend_speed(target)
	var step := 1.0 - exp(-blend_speed * delta)
	_interior_camera_blend = lerpf(_interior_camera_blend, target, step)
	if target <= 0.001:
		_interior_camera_slow_return = false
	elif _interior_camera_slow_return and _interior_camera_blend >= 0.995 and target >= 0.995:
		_interior_camera_slow_return = false
	if _camera_pivot == null or _debug_camera_remote_edit or _mount_transition_active:
		return
	var active_pivot_y := lerpf(
		_explore_camera_pivot_y,
		INTERIOR_EXPLORE_CAMERA_PIVOT_Y,
		_interior_camera_blend
	)
	if _lock_on_camera_blend > 0.001:
		active_pivot_y = lerpf(active_pivot_y, LOCK_ON_CAMERA_PIVOT_Y, _lock_on_camera_blend)
	_camera_pivot.position.y = active_pivot_y


func _get_active_explore_camera_offset() -> Vector3:
	return _explore_camera_offset.lerp(INTERIOR_EXPLORE_CAMERA_OFFSET, _interior_camera_blend)


func _get_active_explore_camera_fov() -> float:
	return lerpf(_explore_camera_fov, INTERIOR_EXPLORE_CAMERA_FOV, _interior_camera_blend)


func _get_interior_camera_blend_speed(target: float) -> float:
	if target < _interior_camera_blend:
		if ShopSession.is_interior_space():
			return INTERIOR_CAMERA_BLEND_SPEED
		return INTERIOR_CAMERA_EXIT_SPEED
	if target > _interior_camera_blend and _interior_camera_slow_return:
		return INTERIOR_CAMERA_COMBAT_RETURN_SPEED
	return INTERIOR_CAMERA_BLEND_SPEED


func _update_lock_on_camera_blend(delta: float) -> void:
	var target := 1.0 if _lock_on_active else 0.0
	var speed := LOCK_ON_CAMERA_BLEND_IN if target > _lock_on_camera_blend else LOCK_ON_CAMERA_BLEND_OUT
	var step := 1.0 - exp(-speed * delta)
	_lock_on_camera_blend = lerpf(_lock_on_camera_blend, target, step)


func _get_lock_on_camera_pitch() -> float:
	return lerpf(_camera_pitch, LOCK_ON_CAMERA_PITCH, _lock_on_camera_blend)


func _set_camera_arm_pitch(extra_pitch: float = 0.0) -> void:
	if _camera_arm == null or _debug_camera_remote_edit:
		return
	_camera_arm.rotation.x = (
		_get_lock_on_camera_pitch()
		+ extra_pitch
		+ _camera_arm.get_occlusion_pitch()
	)


func _apply_camera_offset(offset: Vector3, extra: Vector3 = Vector3.ZERO) -> void:
	if _camera_arm == null or _debug_camera_remote_edit:
		return
	_camera_arm.apply_desired_offset(offset, extra)


func _sync_camera_pivot_yaw(extra_yaw: float = 0.0) -> void:
	if _debug_camera_remote_edit:
		return
	_camera_pivot.rotation.y = _camera_yaw + extra_yaw


func _set_debug_camera_remote_edit(enabled: bool) -> void:
	_debug_camera_remote_edit = enabled
	if _debug_camera_hud_layer != null:
		_debug_camera_hud_layer.visible = enabled
	if _camera_arm != null:
		_camera_arm.set_physics_process(not enabled)
	if enabled:
		print(
			"[CAMERA DEBUG] Remote edit ON — tweak CameraPivot / CameraArm / Camera3D in Remote,"
			+ " press I to print, Shift+I to exit."
		)
	else:
		print("[CAMERA DEBUG] Remote edit OFF — gameplay camera drive resumed.")


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
		and not _comet_cinematic_active
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
	if _comet_cinematic_active:
		return
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
	if _debug_camera_remote_edit:
		return
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


func _face_flat_direction(delta: float, direction: Vector3, turn_speed: float = FACING_SPEED) -> void:
	if direction.length_squared() < 0.0001 or _model == null:
		return
	var target_yaw := atan2(direction.x, direction.z)
	var turn := clampf(turn_speed * delta, 0.0, 1.0)
	_model.rotation.y = lerp_angle(_model.rotation.y, target_yaw, turn)


func _face_lock_on_target(delta: float, turn_speed: float = FACING_SPEED) -> bool:
	if not _is_lock_on_facing_ready():
		return false
	var facing := CombatLockOnScript.get_flat_facing(self, _lock_on_target)
	if facing.length_squared() < 0.0001:
		return false
	_face_flat_direction(delta, facing, turn_speed * _lock_on_blend)
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

	if (
		(_combat_blocking or _reflect_active or _is_unarmed_block_pose_active())
		and (
			GroyperWeapons.is_melee(_equipped_weapon)
			or GroyperWeapons.is_dynamite(_equipped_weapon)
			or GroyperWeapons.is_unarmed(_equipped_weapon)
		)
	):
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
	return (
		(_combat_blocking or _reflect_active or _hostage_take_active)
		and _block_walk_amount > 0.001
	)


func _apply_block_locomotion_sync(
	targets: Vector2,
	_speed: float,
	_walk_speed: float,
	move_dir: Vector3
) -> Vector2:
	if not (_combat_blocking or _reflect_active or _hostage_take_active):
		return targets
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
	if _combat_attacking:
		return
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
			or BonfireMenuManager.is_showing() or _is_debug_ui_blocking()


func _is_debug_ui_blocking() -> bool:
	return not get_tree().get_nodes_in_group(&"debug_ui_blocking").is_empty()


func _is_dialog_frozen() -> bool:
	return _dialog_active or DialogManager.is_showing()


func _sync_dialog_mouse_mode() -> void:
	if ShopBuyManager.is_showing() or BonfireMenuManager.is_showing():
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return
	if not _is_dialog_frozen():
		return
	if DialogManager.is_showing_choices():
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _apply_explore_mouse_look(relative: Vector2) -> void:
	if _debug_camera_remote_edit:
		return
	var sensitivity := MOUSE_SENSITIVITY * _get_ads_sensitivity_scale()
	_camera_yaw -= relative.x * sensitivity
	var pitch_min := CAMERA_PITCH_MIN
	var pitch_max := CAMERA_PITCH_MAX
	if _is_saddle_aim_mode():
		pitch_min = MOUNT_AIM_CAMERA_PITCH_MIN
		pitch_max = MOUNT_AIM_CAMERA_PITCH_MAX
		_clamp_mount_aim_camera_yaw()
	_camera_pitch = clampf(
		_camera_pitch - relative.y * sensitivity,
		pitch_min,
		pitch_max
	)


## ADS zoom lowers look sensitivity in proportion to the FOV change so the
## zoomed view doesn't feel twitchy.
func _get_ads_sensitivity_scale() -> float:
	if _ads_blend <= 0.001:
		return 1.0
	var explore_fov := _get_active_explore_camera_fov()
	if explore_fov <= 0.01:
		return 1.0
	return lerpf(1.0, clampf(_aim_fov_current / explore_fov, 0.2, 1.0), _ads_blend)


func set_cinematic_invulnerable(active: bool) -> void:
	_cinematic_invulnerable = active


func is_cinematic_invulnerable() -> bool:
	return _cinematic_invulnerable


func begin_melee_hit_invulnerability(duration: float = MELEE_HIT_INVULN_DURATION) -> void:
	_melee_hit_invuln_timer = maxf(_melee_hit_invuln_timer, duration)


func is_melee_hit_invulnerable() -> bool:
	return _melee_hit_invuln_timer > 0.0


func set_dialog_active(active: bool) -> void:
	_dialog_active = active
	if active:
		velocity = Vector3.ZERO
		if _weapon_rig != null:
			_weapon_rig.reset_to_holster()
			_reset_reload_input()
			_reset_reticle_state()
			_update_combat_ui()
	if _is_dialog_frozen():
		_sync_dialog_mouse_mode()
	elif not active:
		restore_explore_camera_control()
	elif not InventoryMenuManager.is_open() and not TownMapManager.is_open():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func release_lasso_capture() -> void:
	if _lasso_controller != null:
		_lasso_controller.try_release_capture()


func set_transition_locked(active: bool) -> void:
	_transition_locked = active
	if active and not _cinematic_walk_active:
		velocity = Vector3.ZERO


## Lock input but keep walking along direction (e.g. canyon gate cinematic).
## Speed is clamped between walk and run so a sprinting approach stays brisk.
func begin_cinematic_walk(direction: Vector3, speed: float = WALK_SPEED) -> void:
	var flat := Vector3(direction.x, 0.0, direction.z)
	if flat.length_squared() < 0.0001:
		return
	_cinematic_walk_dir = flat.normalized()
	_cinematic_walk_speed = clampf(speed, WALK_SPEED, RUN_SPEED)
	_cinematic_walk_active = true
	set_transition_locked(true)


func end_cinematic_walk() -> void:
	_cinematic_walk_active = false
	_cinematic_walk_dir = Vector3.ZERO
	_cinematic_walk_speed = WALK_SPEED
	set_transition_locked(false)


func _apply_cinematic_walk(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = minf(velocity.y, 0.0)
	velocity.x = _cinematic_walk_dir.x * _cinematic_walk_speed
	velocity.z = _cinematic_walk_dir.z * _cinematic_walk_speed
	move_with_ground_snap()
	_update_facing(delta, _cinematic_walk_dir)
	_update_locomotion_blend(delta, _cinematic_walk_speed, WALK_SPEED, RUN_SPEED)
	_sync_camera_pivot_yaw()
	_set_camera_arm_pitch()


func begin_practice_session() -> void:
	_practice_locked = true
	_practice_infinite_ammo = true
	_practice_saved_ammo = _ammo
	velocity = Vector3.ZERO
	_refill_practice_ammo()


func end_practice_session() -> void:
	_practice_locked = false
	_practice_infinite_ammo = false
	if _practice_saved_ammo >= 0:
		_ammo = _practice_saved_ammo
		_practice_saved_ammo = -1
	if _ammo_hud:
		_ammo_hud.sync_rounds(_ammo)
		_ammo_hud.sync_reserve_ammo(PlayerInventory.get_weapon_reserve_ammo(_equipped_weapon))
	if not InventoryMenuManager.is_open() and not TownMapManager.is_open():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _refill_practice_ammo() -> void:
	if not _practice_infinite_ammo:
		return
	_ammo = GroyperWeapons.get_max_ammo(_equipped_weapon)
	if _tracks_loaded_ammo(_equipped_weapon):
		_loaded_ammo_by_weapon[int(_equipped_weapon)] = _ammo
	if _ammo_hud:
		_ammo_hud.sync_rounds(_ammo, false, true)
		_ammo_hud.sync_reserve_ammo(PlayerInventory.get_weapon_reserve_ammo(_equipped_weapon))
	_sync_rpg_grip_rocket()


func is_practice_infinite_ammo() -> bool:
	return _practice_infinite_ammo


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


func begin_comet_cinematic_camera(target: Node3D, on_skip: Callable = Callable()) -> void:
	_comet_camera_target = target
	_comet_camera_target_blend = 1.0
	_comet_cinematic_active = true
	_comet_skip_callback = on_skip


func begin_comet_cinematic_camera_exit() -> void:
	_comet_camera_target_blend = 0.0
	_comet_cinematic_active = false
	_comet_skip_callback = Callable()


func end_comet_cinematic() -> void:
	_comet_camera_target = null
	_comet_camera_target_blend = 0.0
	_comet_camera_blend = 0.0
	restore_explore_camera_control()


func restore_explore_camera_control() -> void:
	if _camera != null:
		_camera.fov = _get_active_explore_camera_fov()
	_aim_fov_current = _get_active_explore_camera_fov()
	if (
		not InventoryMenuManager.is_open()
		and not TownMapManager.is_open()
		and not DialogManager.is_showing()
		and not ShopBuyManager.is_showing()
		and not BonfireMenuManager.is_showing()
	):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func is_comet_cinematic_active() -> bool:
	return _comet_cinematic_active


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
	_bonfire_stand_anim_node.animation = _pose_sit_down_path
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

	_bonfire_stand_anim_node.animation = _pose_stand_up_path
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
	_update_bonfire_model_sink(delta)


func _update_bonfire_model_sink(delta: float) -> void:
	if _model == null:
		return
	# Chair sits already place the body on the seat — only floor/bonfire sit needs sink.
	if _sit_chair != null:
		if absf(_bonfire_model_sink) > 0.0001:
			_clear_bonfire_model_sink()
		return
	var target_sink := 0.0
	var sit_progress := clampf(
		_bonfire_timer / maxf(_bonfire_stand_duration, 0.001),
		0.0,
		1.0
	)
	match _bonfire_anim_phase:
		BonfireAnimPhase.SITTING_DOWN:
			# Reverse stand-up: progress 0 = upright, 1 = seated.
			target_sink = BonfirePoseConfig.SIT_MODEL_Y_OFFSET * sit_progress
		BonfireAnimPhase.SITTING:
			target_sink = BonfirePoseConfig.SIT_MODEL_Y_OFFSET
		BonfireAnimPhase.STANDING_UP:
			target_sink = BonfirePoseConfig.SIT_MODEL_Y_OFFSET * (1.0 - sit_progress)
		_:
			target_sink = 0.0
	var step := 1.0 - exp(-BonfirePoseConfig.SIT_MODEL_SINK_SPEED * delta)
	_bonfire_model_sink = lerpf(_bonfire_model_sink, target_sink, step)
	_model.position.y = GroyperBodyUtils.ACTOR_MODEL_Y + _bonfire_model_sink


func _clear_bonfire_model_sink() -> void:
	_bonfire_model_sink = 0.0
	if _model != null:
		_model.position.y = GroyperBodyUtils.ACTOR_MODEL_Y


func _update_bonfire_sit_down(delta: float) -> void:
	_bonfire_timer += delta * BonfirePoseConfig.SIT_DOWN_SPEED
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
	if _sit_chair != null and _get_camera_relative_input().length_squared() > 0.04:
		_request_bonfire_stand_up()
		return
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
	_sync_camera_pivot_yaw()
	_set_camera_arm_pitch()
	_apply_camera_offset(base_pos.lerp(shot.offset, eased))
	_camera.fov = lerpf(base_fov, shot.fov, eased)
	_aim_fov_current = _camera.fov


func _apply_comet_cinematic_camera(delta: float) -> void:
	if _camera == null:
		return

	var step := 1.0 - exp(-CometCinematicConfig.CAMERA_BLEND_SPEED * delta)
	_comet_camera_blend = lerpf(_comet_camera_blend, _comet_camera_target_blend, step)
	if _comet_camera_blend <= 0.001:
		return

	var focus := Vector3.INF
	if _comet_camera_target != null and is_instance_valid(_comet_camera_target):
		focus = _get_comet_focus_point()
	elif _comet_camera_target_blend > 0.01:
		return
	var angles := _compute_comet_focus_angles(focus)
	var eased := _comet_camera_blend * _comet_camera_blend * (3.0 - 2.0 * _comet_camera_blend)
	if focus != Vector3.INF:
		var follow := maxf(eased, 0.2)
		var track_step := 1.0 - exp(-14.0 * delta)
		_camera_yaw = lerp_angle(_camera_yaw, angles.x, follow * track_step)
		_camera_pitch = lerpf(_camera_pitch, angles.y, follow * track_step)

	var base_fov := _get_active_explore_camera_fov()
	_camera.fov = lerpf(base_fov, CometCinematicConfig.CINEMATIC_FOV, eased)
	_aim_fov_current = _camera.fov


func _get_comet_focus_point() -> Vector3:
	if _comet_camera_target == null or not is_instance_valid(_comet_camera_target):
		return Vector3.INF
	return _comet_camera_target.global_position


func _compute_comet_focus_angles(focus: Vector3) -> Vector2:
	var pivot_pos := _camera_pivot.global_position
	var to_focus := focus - pivot_pos
	var flat := Vector3(to_focus.x, 0.0, to_focus.z)
	var yaw := _camera_yaw
	if flat.length_squared() > 0.0001:
		yaw = atan2(flat.x, flat.z)
	var horiz := flat.length()
	# Overworld camera: positive pitch looks up (see OverworldCameraArm.look_up_pitch_threshold).
	var pitch := clampf(
		atan2(to_focus.y, maxf(horiz, 0.001)),
		CAMERA_PITCH_MIN,
		CometCinematicConfig.SKY_PITCH_MAX
	)
	return Vector2(yaw, pitch)


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
	_release_sit_chair()


func _release_sit_chair() -> void:
	if _sit_chair != null and is_instance_valid(_sit_chair) and _sit_chair.has_method("end_occupied"):
		_sit_chair.end_occupied(self)
	_sit_chair = null
	_pose_sit_down_path = BonfirePoseConfig.get_stand_up3_reverse_path()
	_pose_stand_up_path = BonfirePoseConfig.get_stand_up3_path()
	if _bonfire_sit_anim_node != null:
		_bonfire_sit_anim_node.animation = BonfirePoseConfig.get_sit_cross_path()


func begin_chair_sit(chair: Node3D) -> void:
	if chair == null or not _chair_sit_library_ready:
		return
	if _bonfire_anim_phase != BonfireAnimPhase.NONE:
		return
	if _is_mounted() or _punch_active or _transition_locked:
		return

	_sit_chair = chair
	if chair.has_method("begin_occupied"):
		chair.begin_occupied(self)

	set_transition_locked(true)
	velocity = Vector3.ZERO
	if _weapon_rig != null and not _weapon_rig.is_holstered():
		_weapon_rig.reset_to_holster()
		_reset_reload_input()
		_update_combat_ui()

	_pose_sit_down_path = ChairSitConfigScript.get_stand_to_sit_path()
	_pose_stand_up_path = ChairSitConfigScript.get_random_sit_to_stand_path()
	if _bonfire_sit_anim_node != null:
		_bonfire_sit_anim_node.animation = ChairSitConfigScript.get_random_sit_idle_path()

	if chair.has_method("get_sit_transform"):
		var seat: Transform3D = chair.get_sit_transform()
		var face_dir := -seat.basis.z
		face_dir.y = 0.0
		if face_dir.length_squared() > 0.0001:
			face_dir = face_dir.normalized()
			_model.rotation.y = atan2(face_dir.x, face_dir.z)
		var seat_tween := create_tween()
		seat_tween.tween_property(self, "global_position", seat.origin, ChairSitConfigScript.SEAT_ALIGN_DURATION)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	_start_bonfire_sit_down()


func is_chair_seated() -> bool:
	return _sit_chair != null


func rest_at_bonfire() -> void:
	_health = BulletHitDamage.PLAYER_MAX_HEALTH
	_health_regen_timer = 0.0
	_update_health_vignette()
	_ammo = GroyperWeapons.get_max_ammo(_equipped_weapon)
	if _tracks_loaded_ammo(_equipped_weapon):
		_loaded_ammo_by_weapon[int(_equipped_weapon)] = _ammo
	if _ammo_hud:
		_ammo_hud.sync_rounds(_ammo)
	_sync_rpg_grip_rocket()


func apply_post_bonfire_respawn() -> void:
	_reset_from_overworld_defeat()
	if _weapon_rig != null:
		_weapon_rig.reset_to_holster()
	if _melee_weapon_rig != null:
		_melee_weapon_rig.reset_to_holster()
	refresh_stowed_weapon_visuals()
	exit_overworld_combat()
	rest_at_bonfire()
	Bonfire.apply_rest_world_effects(self)
	set_transition_locked(false)


func _begin_death_respawn_sequence() -> void:
	if _death_sequence_active or not _overworld_defeated:
		return
	_death_sequence_active = true
	set_transition_locked(true)
	_clear_lock_on()
	DeathOverlayManager.play_death_sequence(_on_death_cinematic_complete)


func _on_death_cinematic_complete() -> void:
	# Roguelike mode: death always returns to the hub town, never a bonfire
	# checkpoint, and never touches Story Mode's adventure save.
	if RunState.roguelike_active:
		# Results screen + extract + hub load are owned by RunState.
		await RunState.handle_player_death()
		return

	# Always reload the checkpoint stage — even when already on it. Soft in-place
	# respawn left enemies/quest world state live and skipped death-checkpoint
	# restore (quests, loadout, currency rules).
	var target_stage_path := AdventureSave.get_bonfire_stage_path()
	if target_stage_path == "":
		target_stage_path = GameState.STAGE1_PATH
	# Fix shared Environment saturation before the stage swap — the old
	# WorldEnvironment node dies with the scene, but the resource often persists.
	DeathOverlayManager.prepare_for_scene_reload()
	AdventureSave.begin_bonfire_respawn()
	get_tree().change_scene_to_file(target_stage_path)


func _respawn_at_bonfire_in_scene() -> void:
	var spawn_transform := AdventureSave.get_bonfire_spawn_transform(get_tree().current_scene)
	if spawn_transform == Transform3D.IDENTITY:
		push_warning("GroyperOverworldPlayer: no bonfire spawn available for in-scene respawn.")
		spawn_transform = global_transform
	global_transform = spawn_transform
	if has_method("sync_overworld_spawn_orientation"):
		sync_overworld_spawn_orientation()
	if has_method("snap_to_floor"):
		snap_to_floor()
	AdventureSave.apply_death_checkpoint(self)
	apply_post_bonfire_respawn()
	if AdventureSave.is_bonfire_checkpoint_interior():
		prepare_interior_spawn_camera()
		ShopSession.start_home_music()


func _reset_from_overworld_defeat() -> void:
	if _combat_ragdoll != null and _combat_ragdoll.is_active():
		_combat_ragdoll.deactivate()
	if _animation_player != null:
		_animation_player.active = true
		_animation_player.speed_scale = 1.0
		_animation_player.process_mode = Node.PROCESS_MODE_INHERIT
	if _animation_tree != null:
		_animation_tree.process_mode = Node.PROCESS_MODE_INHERIT
		_animation_tree.active = true
	_overworld_defeated = false
	_death_sequence_active = false
	BulletHitDamage.clear_chip_damage(self)
	velocity = Vector3.ZERO
	if _combat_hitbox != null:
		_combat_hitbox.collision_layer = 0


func _finish_death_respawn() -> void:
	_death_sequence_active = false
	set_transition_locked(false)


## Comfortably above the widest hear range (civilians 42m, skeletons ~16m) so
## the distance gate can never mute someone who would have reacted.
const GUNSHOT_ALERT_RANGE_SQ := 64.0 * 64.0


func _notify_nearby_enemies_of_gunshot(origin: Vector3) -> void:
	if _practice_locked:
		return
	for group_name in ["cave_enemy", "civilian"]:
		for node in get_tree().get_nodes_in_group(group_name):
			if node is Node3D \
					and origin.distance_squared_to((node as Node3D).global_position) > GUNSHOT_ALERT_RANGE_SQ:
				continue
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
	_sync_camera_pivot_yaw()
	_set_camera_arm_pitch()
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
		if _tracks_loaded_ammo(_equipped_weapon):
			_loaded_ammo_by_weapon[int(_equipped_weapon)] = _ammo
	if _ammo_hud:
		_ammo_hud.configure_for_weapon(_equipped_weapon)
		_ammo_hud.sync_rounds(_ammo)
		_ammo_hud.sync_reserve_ammo(PlayerInventory.get_weapon_reserve_ammo(_equipped_weapon))
	refresh_stowed_weapon_visuals()


func on_revolver_ammo_picked_up(_amount: int) -> void:
	_sync_reserve_ammo_hud()


func _sync_reserve_ammo_hud() -> void:
	if _ammo_hud:
		_ammo_hud.sync_reserve_ammo(PlayerInventory.get_weapon_reserve_ammo(_equipped_weapon))


func equip_weapon(weapon_id: GroyperWeapons.Id, refill_ammo: bool = true) -> void:
	if not PlayerInventory.owns_weapon_type(weapon_id):
		return

	# Cancel a queued fists swap if the player picks something else mid-holster.
	if _pending_unarmed_equip and not GroyperWeapons.is_unarmed(weapon_id):
		_pending_unarmed_equip = false
	# Retarget / cancel a queued firearm swap if the player picks again mid-holster.
	if _pending_weapon_equip and weapon_id != _pending_weapon_equip_id:
		if weapon_id == _equipped_weapon:
			_pending_weapon_equip = false
			if _weapon_rig != null:
				_weapon_rig.set_draw_suppressed(false)
			return
		# Soft-swap queue is firearms-only — fists/melee need the normal equip path.
		if not _is_weapon_rig_firearm(weapon_id):
			_pending_weapon_equip = false
		else:
			_pending_weapon_equip_id = weapon_id
			_pending_weapon_equip_refill = refill_ammo
			_show_weapon_select_hud()
			return
	# Retarget / cancel a queued melee put-away if the player picks again mid-holster.
	if _pending_melee_holster and weapon_id != _pending_melee_holster_weapon:
		if weapon_id == _equipped_weapon:
			_pending_melee_holster = false
			if _melee_weapon_rig != null and _melee_weapon_rig.is_holstered():
				_melee_weapon_rig.begin_draw()
			return
		_pending_melee_holster_weapon = weapon_id
		_pending_melee_holster_refill = refill_ammo
		_show_weapon_select_hud()
		return

	var switching_to_melee := GroyperWeapons.is_melee(weapon_id)
	var switching_from_melee := GroyperWeapons.is_melee(_equipped_weapon)
	var swapping_melee_weapon := switching_to_melee and switching_from_melee and weapon_id != _equipped_weapon
	var switching_to_dynamite := GroyperWeapons.is_dynamite(weapon_id)
	var switching_from_dynamite := GroyperWeapons.is_dynamite(_equipped_weapon)
	var switching_to_torch := GroyperWeapons.is_torch(weapon_id)
	var switching_from_torch := GroyperWeapons.is_torch(_equipped_weapon)

	if weapon_id != _equipped_weapon:
		_store_current_loaded_ammo()

	if weapon_id == _equipped_weapon:
		if switching_to_dynamite:
			_sync_dynamite_hand_visual()
			sync_dynamite_ammo_hud()
			return
		if switching_to_torch:
			_sync_torch_hand_visual()
			return
		if switching_to_melee:
			if _melee_weapon_rig != null and _melee_weapon_rig.is_equipped():
				return
		elif _weapon_rig != null and _weapon_rig.get_equipped_weapon_id() == weapon_id:
			# Armory / pickups can ask for a fresh mag without swapping weapons.
			if refill_ammo and _tracks_loaded_ammo(weapon_id):
				_ammo = _resolve_ammo_on_equip(weapon_id, true)
				if GroyperWeapons.is_dual_wield(weapon_id):
					_left_ammo = _resolve_left_ammo_on_equip(true)
				if _ammo_hud:
					_ammo_hud.configure_for_weapon(_equipped_weapon)
					_ammo_hud.sync_rounds(_ammo)
					_ammo_hud.sync_reserve_ammo(PlayerInventory.get_weapon_reserve_ammo(_equipped_weapon))
				_sync_left_ammo_hud(false, true)
				_sync_rpg_grip_rocket()
			if _weapon_rig.has_holster_grip() or _weapon_rig.is_drawing() or not _weapon_rig.is_holstered():
				return

	if _lasso_controller != null:
		_lasso_controller.reset()
	end_lasso_grapple_swing()

	if _bow_controller != null:
		_bow_controller.reset()
	_clear_bow_trajectory_preview()

	if switching_from_dynamite and not switching_to_dynamite:
		_combat_blocking = false
		_set_melee_block_hold_blend(0.0)
		if _dynamite_hand_visual != null:
			_dynamite_hand_visual.visible = false

	if switching_from_torch and not switching_to_torch:
		_combat_blocking = false
		_complete_melee_attack()
		_set_melee_block_hold_blend(0.0)
		if _torch_hand_visual != null:
			_torch_hand_visual.visible = false

	if switching_from_melee and not switching_to_melee:
		_combat_blocking = false
		_complete_melee_attack()
		_set_melee_block_hold_blend(0.0)
		_block_walk_amount = 0.0
		_apply_block_walk_locomotion_blend()
		_set_combat_idle_blend_instant(0.0)
		# Reverse-draw put-away (same progress 1→0 curve as guns). Keep melee
		# equipped until HOLSTERED so pose overrides keep ticking.
		if _melee_weapon_rig != null and not _melee_weapon_rig.is_holstered():
			_pending_melee_holster = true
			_pending_melee_holster_weapon = weapon_id
			_pending_melee_holster_refill = refill_ammo
			_melee_weapon_rig.begin_holster()
			_show_weapon_select_hud()
			_try_finish_pending_melee_holster()
			return
		if _melee_weapon_rig != null:
			_melee_weapon_rig.reset_to_holster()
			_teardown_melee_weapon_rig()

	if switching_to_dynamite:
		if _weapon_rig != null:
			_weapon_rig.reset_to_holster()
			_weapon_rig.set_draw_suppressed(true)
		if _melee_weapon_rig != null:
			_melee_weapon_rig.reset_to_holster()
			_teardown_melee_weapon_rig()
		_equipped_weapon = weapon_id
		_shot_cooldown = 0.0
		_fire_held = false
		_reset_reload_input()
		_reset_reticle_state()
		_setup_dynamite_hand_visual()
		if _melee_block_hold_anim_node != null:
			var path := GroyperMeleeAnimConfig.clip_path(GroyperMeleeAnimConfig.CLIP_BLOCK_HOLD)
			if _animation_player != null and _animation_player.has_animation(path):
				_melee_block_hold_anim_node.animation = path
		_ammo = _initial_ammo_for(_equipped_weapon)
		if _ammo_hud:
			_ammo_hud.configure_for_weapon(_equipped_weapon)
			_ammo_hud.sync_rounds(_ammo)
		_sync_dynamite_hand_visual()
		_update_combat_ui()
		refresh_stowed_weapon_visuals()
		return

	if switching_to_torch:
		if _weapon_rig != null:
			_weapon_rig.reset_to_holster()
			_weapon_rig.set_draw_suppressed(true)
		if _melee_weapon_rig != null:
			_melee_weapon_rig.reset_to_holster()
			_teardown_melee_weapon_rig()
		_equipped_weapon = weapon_id
		_shot_cooldown = 0.0
		_fire_held = false
		_reset_reload_input()
		_reset_reticle_state()
		_setup_torch_hand_visual()
		_apply_torch_melee_anim_set()
		if _melee_block_hold_anim_node != null:
			var torch_block_path := GroyperMeleeAnimConfig.clip_path(
				GroyperMeleeAnimConfig.CLIP_BLOCK_HOLD
			)
			if _animation_player != null and _animation_player.has_animation(torch_block_path):
				_melee_block_hold_anim_node.animation = torch_block_path
		_ammo = 0
		if _ammo_hud:
			_ammo_hud.configure_for_weapon(_equipped_weapon)
			_ammo_hud.sync_rounds(_ammo)
		_sync_torch_hand_visual()
		_update_combat_ui()
		refresh_stowed_weapon_visuals()
		return

	if switching_to_melee:
		if _weapon_rig != null:
			_weapon_rig.reset_to_holster()
		if swapping_melee_weapon:
			# Rebuild the melee rig so it mounts the new weapon at its own holster
			# and hand pose. reset_to_holster returns the previous weapon's grip to
			# its holster before teardown, so no manual grip cleanup is needed.
			if _melee_weapon_rig != null:
				_melee_weapon_rig.reset_to_holster()
			_teardown_melee_weapon_rig()
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

	if GroyperWeapons.is_unarmed(weapon_id):
		_begin_unarmed_equip()
		return

	# Any drawn firearm: holster first, then soft-swap into the next draw.
	# (1H→2H, 2H→1H, AK→next, etc.) Avoids instant holster pops / draw snaps.
	if (
		_weapon_rig != null
		and weapon_id != _equipped_weapon
		and not _weapon_rig.is_holstered()
		and _is_weapon_rig_firearm(_equipped_weapon)
		and _is_weapon_rig_firearm(weapon_id)
	):
		_begin_weapon_equip(weapon_id, refill_ammo)
		return

	_apply_firearm_equip(weapon_id, refill_ammo, false)


func _is_weapon_rig_firearm(weapon_id: GroyperWeapons.Id) -> bool:
	# Firearms + bow share the always-drawn put-away / soft-swap handoff.
	return GroyperWeapons.uses_run_and_gun(weapon_id)


func _begin_weapon_equip(weapon_id: GroyperWeapons.Id, refill_ammo: bool) -> void:
	if _pending_weapon_equip:
		_pending_weapon_equip_id = weapon_id
		_pending_weapon_equip_refill = refill_ammo
		_show_weapon_select_hud()
		return
	_fire_held = false
	_reset_reload_input()
	_pending_weapon_equip = true
	_pending_weapon_equip_id = weapon_id
	_pending_weapon_equip_refill = refill_ammo
	if _weapon_rig != null:
		if _weapon_rig.is_overworld_reloading():
			_weapon_rig.cancel_overworld_reload_for_aim()
		_weapon_rig.set_draw_suppressed(true)
		_weapon_rig.begin_holster()
	_show_weapon_select_hud()
	_try_finish_pending_weapon_equip()


func _try_finish_pending_weapon_equip() -> void:
	if not _pending_weapon_equip:
		return
	if _weapon_rig != null and not _weapon_rig.is_holstered():
		return
	# Do not wait for holster-exit→locomotion blend — that gap then snap-draws.
	_pending_weapon_equip = false
	var next_id := _pending_weapon_equip_id
	var refill := _pending_weapon_equip_refill
	_apply_firearm_equip(next_id, refill, true)


func _apply_firearm_equip(
	weapon_id: GroyperWeapons.Id,
	refill_ammo: bool,
	soft_handoff: bool = false
) -> void:
	# Set before swap: soft-handoff emits draw_state_changed which refreshes
	# stowed visuals, and that path must already see the new equipped id.
	_equipped_weapon = weapon_id
	if _weapon_rig != null:
		_weapon_rig.clear_holster_exit_blend()
		_weapon_rig.set_draw_suppressed(false)
		_weapon_rig.swap_equipped_weapon(weapon_id, soft_handoff)
		# Sync aim mode immediately so the next draw frame doesn't use the
		# previous weapon's 1H/2H chain for a tick (left-arm T-pose flash).
		_weapon_rig.sync_run_and_gun_aim_mode(_ads_blend, _locomotion_move_blend)

	_ammo = _resolve_ammo_on_equip(_equipped_weapon, refill_ammo)
	if GroyperWeapons.is_dual_wield(_equipped_weapon):
		_left_ammo = _resolve_left_ammo_on_equip(refill_ammo)
	else:
		_left_ammo = 0
	_shot_cooldown = 0.0
	_left_shot_cooldown = 0.0
	_fire_held = false
	_reset_reload_input()
	_reset_reticle_state()
	if _ammo_hud:
		_ammo_hud.configure_for_weapon(_equipped_weapon)
		_ammo_hud.sync_rounds(_ammo)
		_ammo_hud.sync_reserve_ammo(PlayerInventory.get_weapon_reserve_ammo(_equipped_weapon))
	_sync_left_ammo_hud(false, true)
	_sync_rpg_grip_rocket()
	_update_combat_ui()
	refresh_stowed_weapon_visuals()


func _try_cycle_weapon(direction: int) -> void:
	if direction == 0:
		return

	var weapons := PlayerInventory.get_unique_owned_weapons()
	if weapons.is_empty():
		return

	# During a gun→fists / 2H / melee putaway, the wheel already shows the pending pick.
	var cycle_from: GroyperWeapons.Id = _equipped_weapon
	if _pending_unarmed_equip:
		cycle_from = GroyperWeapons.Id.UNARMED
	elif _pending_weapon_equip:
		cycle_from = _pending_weapon_equip_id
	elif _pending_melee_holster:
		cycle_from = _pending_melee_holster_weapon
	var current_index := weapons.find(cycle_from)
	if current_index < 0:
		current_index = 0

	var next_index := (current_index + direction) % weapons.size()
	if next_index < 0:
		next_index += weapons.size()

	# Never free-refill the magazine on cycle — restore chambered rounds.
	equip_weapon(weapons[next_index], false)
	_show_weapon_select_hud()


func _show_weapon_select_hud() -> void:
	if _weapon_select_hud == null:
		return
	var active_weapon := _equipped_weapon
	if _pending_unarmed_equip:
		active_weapon = GroyperWeapons.Id.UNARMED
	elif _pending_weapon_equip:
		active_weapon = _pending_weapon_equip_id
	_weapon_select_hud.show_weapons(
		PlayerInventory.get_unique_owned_weapons(),
		active_weapon
	)


## Put the drawn gun away first, then finish the Unarmed swap. Already-holstered
## guns (dynamite empty, throws, etc.) complete immediately.
func _begin_unarmed_equip() -> void:
	if _pending_unarmed_equip:
		return
	_pending_weapon_equip = false
	_fire_held = false
	_reset_reload_input()
	if _weapon_rig != null and not _weapon_rig.is_holstered():
		if _weapon_rig.is_overworld_reloading():
			_weapon_rig.cancel_overworld_reload_for_aim()
		_pending_unarmed_equip = true
		# Suppress always-drawn so the existing holster anim can play; keep the
		# firearm equipped until HOLSTERED so aim poses don't snap off mid-putaway.
		_weapon_rig.set_draw_suppressed(true)
		_weapon_rig.begin_holster()
		_show_weapon_select_hud()
		_try_finish_pending_unarmed_equip()
		return
	_apply_unarmed_equip()


func _try_finish_pending_unarmed_equip() -> void:
	if not _pending_unarmed_equip:
		return
	if _weapon_rig != null and not _weapon_rig.is_holstered():
		return
	# Wait out the holster→locomotion arm fade so fists don't pop mid-handoff.
	if _weapon_rig != null and _weapon_rig.is_holster_exit_blending():
		return
	_pending_unarmed_equip = false
	_apply_unarmed_equip()


## Finish melee reverse-draw put-away, then equip the queued weapon.
func _try_finish_pending_melee_holster() -> void:
	if not _pending_melee_holster:
		return
	if _melee_weapon_rig != null and not _melee_weapon_rig.is_holstered():
		return
	var next_id := _pending_melee_holster_weapon
	var refill := _pending_melee_holster_refill
	_pending_melee_holster = false
	if _melee_weapon_rig != null:
		_melee_weapon_rig.reset_to_holster()
		_teardown_melee_weapon_rig()
	equip_weapon(next_id, refill)


## Fists: gun stays holstered on the hip, RMB becomes block.
func _apply_unarmed_equip() -> void:
	if _weapon_rig != null:
		if not _weapon_rig.is_holstered():
			_weapon_rig.reset_to_holster()
		_weapon_rig.set_draw_suppressed(true)
	_equipped_weapon = GroyperWeapons.Id.UNARMED
	_ammo = 0
	_shot_cooldown = 0.0
	_fire_held = false
	_reset_reload_input()
	_reset_reticle_state()
	if _ammo_hud:
		_ammo_hud.configure_for_weapon(_equipped_weapon)
		_ammo_hud.sync_rounds(_ammo)
	_update_combat_ui()
	refresh_stowed_weapon_visuals()


func notify_weapon_inventory_changed() -> void:
	_show_weapon_select_hud()


func refresh_stowed_weapon_visuals() -> void:
	if _skeleton == null:
		return

	_clear_extra_holsters()
	GroyperBodyUtils.ensure_firearm_holster_mounts(_skeleton)

	# Shared hip/back sockets: only clear when they aren't the equipped gun's mount.
	var equipped_mount := String(GroyperWeapons.holster_mount_name(_equipped_weapon))
	if equipped_mount != "HipHolsterMount":
		_clear_socket_grip(_hip_holster_socket())
	if equipped_mount != "BackHolsterMount":
		_clear_socket_grip(_back_holster_socket())

	var owns_dual := PlayerInventory.owns_weapon_type(GroyperWeapons.Id.DUAL_REVOLVER)
	var revolvers_on_body := 0
	if (
		_equipped_weapon == GroyperWeapons.Id.REVOLVER
		or _equipped_weapon == GroyperWeapons.Id.DUAL_REVOLVER
	):
		revolvers_on_body += 1
	elif PlayerInventory.owns_weapon_type(GroyperWeapons.Id.REVOLVER) or owns_dual:
		revolvers_on_body += 1

	# Dual left hip: rig owns it while dual is equipped; otherwise show a stowed
	# left gun whenever dual is in inventory (fists / other weapon).
	if owns_dual:
		_sync_owned_dual_left_holster()
	else:
		var extra_revolvers := (
			PlayerInventory.count_weapon(GroyperWeapons.Id.REVOLVER) - revolvers_on_body
		)
		if extra_revolvers >= 1:
			_ensure_left_hip_holster(GroyperWeapons.Id.REVOLVER)

	# Revolver / dual right gun on shared hip when another mount owns the active seat.
	if (
		(
			PlayerInventory.owns_weapon_type(GroyperWeapons.Id.REVOLVER)
			or owns_dual
		)
		and _equipped_weapon != GroyperWeapons.Id.REVOLVER
		and _equipped_weapon != GroyperWeapons.Id.DUAL_REVOLVER
		and equipped_mount != "HipHolsterMount"
	):
		_install_stowed_weapon(_hip_holster_socket(), GroyperWeapons.Id.REVOLVER)

	# Shovel (and any other shared-back weapon) on BackHolsterMount.
	var stowed_back_weapon := _get_stowed_back_weapon()
	if stowed_back_weapon >= 0:
		_install_stowed_weapon(_back_holster_socket(), stowed_back_weapon)

	var owned_ids: Array = PlayerInventory.get_unique_owned_weapons()
	# Prefer the rig's equipped id / live grip so mid-swap draw_state_changed
	# refreshes cannot treat the new gun as stowed and leave a holster ghost.
	var equipped_for_sync := int(_equipped_weapon)
	var keep_grip: Node3D = null
	if _weapon_rig != null:
		equipped_for_sync = int(_weapon_rig.get_equipped_weapon_id())
		keep_grip = _weapon_rig.get_revolver_grip()
	GroyperBodyUtils.sync_firearm_holsters(
		_skeleton,
		owned_ids,
		equipped_for_sync,
		keep_grip
	)

	_sync_melee_holsters()
	_refresh_bow_back_visuals()


## Visual-only: the quiver shows whenever the bow is owned; the slung back-bow
## shows when the bow is owned but is NOT the active (equipped) weapon — while the
## bow IS equipped, the weapon rig's own holster grip handles its on-back/in-hand
## display, so the dedicated back-bow stays hidden to avoid a double bow. The
## rough arrow count lights Arrow0..Arrow{n-1}. Event-driven only (no polling).
func _refresh_bow_back_visuals() -> void:
	if _skeleton == null:
		return
	var quiver_mount := _skeleton.get_node_or_null("QuiverBackMount") as Node3D
	var bow_mount := _skeleton.get_node_or_null("BowBackMount") as Node3D
	if quiver_mount == null or bow_mount == null:
		return

	var owns_bow := PlayerInventory.owns_weapon_type(GroyperWeapons.Id.BOW)
	quiver_mount.visible = owns_bow
	bow_mount.visible = owns_bow and _equipped_weapon != GroyperWeapons.Id.BOW

	var shown := GroyperBodyUtils.quiver_visible_arrow_count(_current_quiver_arrow_count())
	var adjust := quiver_mount.get_node_or_null("QuiverAdjust")
	if adjust != null:
		for i in GroyperBodyUtils.QUIVER_MAX_SHOWN_ARROWS:
			var arrow := adjust.get_node_or_null("Arrow%d" % i) as Node3D
			if arrow != null:
				arrow.visible = i < shown


## Current arrow total driving the quiver display. The bow's arrows are a
## persistent reserve, so this reflects the true remaining count whether the bow
## is in hand (live working copy) or stowed (the reserve). VISUAL ONLY.
func _current_quiver_arrow_count() -> int:
	if not PlayerInventory.owns_weapon_type(GroyperWeapons.Id.BOW):
		return 0
	if _equipped_weapon == GroyperWeapons.Id.BOW:
		return _ammo
	return PlayerInventory.get_bow_ammo()


func _get_stowed_back_weapon() -> int:
	# AWP/Shotgun use bespoke mounts; bow uses BowBackMount. Shared back is shovel.
	if (
		PlayerInventory.owns_weapon_type(GroyperWeapons.Id.SHOVEL)
		and _equipped_weapon != GroyperWeapons.Id.SHOVEL
	):
		return GroyperWeapons.Id.SHOVEL
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
	# LeftHipHolsterMount is permanent. Dual inventory owns that seat (rig while
	# equipped, stowed visual otherwise) — never strip it for fists/other guns.
	if (
		_is_dual_wield_equipped()
		or PlayerInventory.owns_weapon_type(GroyperWeapons.Id.DUAL_REVOLVER)
	):
		return
	var socket := GroyperBodyUtils.left_hip_holster_socket(_skeleton)
	_clear_socket_grip(socket)


func _sync_owned_dual_left_holster() -> void:
	if _skeleton == null:
		return
	if _is_dual_wield_equipped() and _weapon_rig != null:
		_weapon_rig.sync_dual_left_grip()
		return
	# Dual owned but not the active firearm (unarmed / other weapon): left hip gun.
	_ensure_left_hip_holster(GroyperWeapons.Id.REVOLVER)


func _ensure_left_hip_holster(weapon_id: GroyperWeapons.Id) -> void:
	if _skeleton == null:
		return
	GroyperBodyUtils.ensure_weapon_mounts(_skeleton)
	var left_mount := GroyperBodyUtils.left_hip_holster_mount(_skeleton)
	if left_mount != null:
		left_mount.visible = true
	var holster_socket := GroyperBodyUtils.left_hip_holster_socket(_skeleton)
	if holster_socket == null:
		return
	if holster_socket.get_node_or_null("RevolverGrip") != null:
		return
	GroyperWeapons.install_left_holster_grip(holster_socket, weapon_id)


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
	if _practice_locked or _ladder_state.active:
		return
	if _mounted_horse != null:
		if _mount_transition_active:
			return
		_mounted_horse.dismount_rider()
		return

	var target := _get_nearest_interactable()
	if target != null and target.has_method("interact"):
		target.interact(self)
		return

	# No usable interactable nearby — E toggles combat lock-on when a target is in view.
	_try_toggle_lock_on()


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

	if _start_mount_vault(horse):
		return

	var mount := horse.get_rider_mount_node()
	var start := global_position
	if _model != null:
		_mount_hop_model_yaw_from = _model.rotation.y
		_mount_hop_model_yaw_to = _get_mount_model_yaw_for_horse(horse)

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

	if _model != null and _model.get_parent() == self:
		_set_model_facing_yaw(_get_mount_model_yaw_for_horse(horse))

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

	_mount_transition_active = true
	_kill_mount_hop_tween()

	if _start_dismount_vault(landing):
		return

	if _model != null:
		_mount_hop_model_yaw_from = _model.rotation.y
		_mount_hop_model_yaw_to = GroyperBodyUtils.MODEL_YAW_OFFSET

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
	_sync_camera_pivot_yaw()


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
	_interior_camera_slow_return = false
	_health = BulletHitDamage.PLAYER_MAX_HEALTH
	_health_regen_timer = 0.0
	_update_health_vignette()
	add_to_group("duel_target")
	_ensure_combat_hitbox()
	_notify_companion_defenders()


func exit_overworld_combat() -> void:
	if not _overworld_combat_active:
		return
	_overworld_combat_active = false
	_health_regen_timer = 0.0
	if is_in_group("duel_target"):
		remove_from_group("duel_target")
	if ShopSession.is_interior_space():
		_interior_camera_slow_return = true


func _notify_companion_defenders() -> void:
	for node in get_tree().get_nodes_in_group("baldwin_npc"):
		if node.has_method("notify_companion_defend_player"):
			node.notify_companion_defend_player()


func get_faction_id() -> StringName:
	# During roguelike runs every combat faction (incl. Becker Boys / Sheriff)
	# treats RUN as hostile — Story Mode keeps the normal PLAYER identity.
	if RunState.run_active:
		return FactionIds.RUN
	return FactionIds.PLAYER


## Call after placing the actor at a spawn marker.
## Marker yaw spins the CharacterBody3D root; CameraPivot keeps its default PI explore offset.
func sync_overworld_spawn_orientation() -> void:
	_camera_yaw = PI
	_sync_camera_pivot_yaw()
	_set_camera_arm_pitch()
	_model.rotation.y = GroyperBodyUtils.MODEL_YAW_OFFSET
	prepare_outdoor_spawn_camera()


## When spawning outdoors, clear stale interior session state and ease the explore
## camera back to the default outdoor offset/FOV/pivot.
func prepare_outdoor_spawn_camera() -> void:
	if ShopSession.is_interior_space():
		_interior_camera_blend = maxf(_interior_camera_blend, 1.0)
	ShopSession.reset_for_outdoor_spawn()
	_interior_camera_slow_return = false


## Call after placing the actor at a spawn inside an interior (fast travel,
## death respawn, new-game start) so the interior explore camera engages.
## Door entries activate the session via ShopSession.save_before_enter instead.
func prepare_interior_spawn_camera() -> void:
	ShopSession.begin_interior_space()
	_interior_camera_slow_return = false


func orient_toward_world_position(target_position: Vector3) -> void:
	var to_target := target_position - global_position
	to_target.y = 0.0
	if to_target.length_squared() < 0.0001:
		return
	_model.rotation.y = atan2(to_target.x, to_target.z)


func prepare_for_home_start() -> void:
	if _lasso_controller != null:
		_lasso_controller.reset()
	end_lasso_grapple_swing()
	if _bow_controller != null:
		_bow_controller.reset()
	_clear_bow_trajectory_preview()

	if _duel_hat != null:
		_duel_hat.prepare_for_round(true)

	if GroyperWeapons.is_melee(_equipped_weapon):
		_holster_melee_weapon()
	_teardown_melee_weapon_rig()
	BaldwinBodyUtilsScript.sync_melee_equipment_owned(_skeleton, false)
	BaldwinBodyUtilsScript.sync_melee_holsters(_skeleton, [])

	if _weapon_rig != null:
		_weapon_rig.clear_weapon_visual()
		_weapon_rig.set_draw_suppressed(true)

	# Fresh starts own no guns yet — begin bare-fisted.
	_equipped_weapon = GroyperWeapons.Id.UNARMED
	_ammo = 0
	_shot_cooldown = 0.0
	_fire_held = false
	_reset_reload_input()
	_reset_reticle_state()

	refresh_stowed_weapon_visuals()
	refresh_knife_visual()
	refresh_deputy_badge_visual()
	if _ammo_hud != null:
		_ammo_hud.configure_for_weapon(_equipped_weapon)
		_ammo_hud.sync_rounds(_ammo)
	_update_combat_ui()


func get_weapon_aim_ray() -> Dictionary:
	return {
		"origin": _get_aim_ray_origin(),
		"direction": _get_aim_direction(),
	}


func is_weapon_raised() -> bool:
	if _weapon_rig == null or GroyperWeapons.is_lasso(_equipped_weapon):
		return false
	# Run-and-gun weapons are always drawn — only deliberate aiming (ADS,
	# charging the bow, or a recent shot) reads as raised/threatening to NPCs.
	if _is_run_and_gun_weapon() and not _is_deliberately_aiming():
		return false
	return not _weapon_rig.is_holstered()


func _is_deliberately_aiming() -> bool:
	if not _is_run_and_gun_weapon():
		return true
	if _is_ads_held():
		return true
	if (
		GroyperWeapons.is_bow(_equipped_weapon)
		and _weapon_rig != null
		and _weapon_rig.get_bow_draw_alpha() > 0.05
	):
		return true
	return Time.get_ticks_msec() - _last_gunshot_msec < THREAT_RECENT_SHOT_WINDOW_MS


func is_weapon_drawn() -> bool:
	return is_weapon_raised()


func _get_threat_aim_point(target: Node3D) -> Vector3:
	if target.has_method("get_threat_aim_point"):
		return target.get_threat_aim_point()
	if target.has_method("get_duel_body_aim_point"):
		return target.get_duel_body_aim_point("chest")
	if target.has_method("get_bullet_capsule"):
		var capsule: Dictionary = BulletHitDamage.get_cached_bullet_capsule(target)
		return capsule.get("center", target.global_position + Vector3(0.0, 1.25, 0.0))
	return target.global_position + Vector3(0.0, 1.25, 0.0)


func is_weapon_aimed_at(target: Node3D, max_range: float = THREATEN_RANGE) -> bool:
	if target == null or _weapon_rig == null:
		return false
	if GroyperWeapons.is_lasso(_equipped_weapon):
		return false
	if not _weapon_rig.is_aiming():
		return false
	if not _is_deliberately_aiming():
		return false
	if not target.has_method("get_bullet_capsule"):
		return false

	var capsule: Dictionary = BulletHitDamage.get_cached_bullet_capsule(target)
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


func is_weapon_threatening(target: Node3D, max_range: float = THREATEN_RANGE) -> bool:
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
	if _overworld_defeated or _cinematic_invulnerable or _melee_hit_invuln_timer > 0.0:
		return
	if _hostage_take_active:
		var hostage := get_hostage_victim()
		if hostage != null and is_instance_valid(hostage):
			if not hostage.has_method("is_defeated") or not hostage.is_defeated():
				hostage.receive_bullet_hit(hit_info)
				if hostage.has_method("is_defeated") and hostage.is_defeated():
					_release_hostage(false)
				return
		_release_hostage(false)
	_melee_hit_absorbed = false
	# Q grab reach counters melee: spin-throw the attacker, absorb the hit.
	if bool(hit_info.get("melee", false)) and try_unarmed_parry(hit_info.get("shooter"), hit_info):
		_melee_hit_absorbed = true
		return
	if _can_reflect_hit(hit_info):
		_on_shield_reflect_success(hit_info)
		return
	if _can_block_melee_hit(hit_info):
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
	if bool(hit_info.get("skip_stun", false)):
		# Damage/knockback already applied — no control lock or hit-react stun.
		pass
	elif GroyperHitReactionConfig.should_knockdown(hit_info, bool(result.knockback_applied)):
		_try_start_hit_reaction(hit_info)
	elif bool(hit_info.get("face_punch_reaction", false)) and bool(hit_info.get("melee", false)):
		_try_begin_face_punch_reaction(hit_info)
	elif bool(result.knockback_applied):
		_apply_light_hit_reaction(hit_info)
	elif not bool(hit_info.get("punch_hit", false)):
		CombatHitFlashScript.flash_damage(self)


func _apply_light_hit_reaction(hit_info: Dictionary) -> void:
	if _hit_reaction_active or _overworld_defeated:
		return
	if bool(hit_info.get("skip_stun", false)):
		return
	if not bool(hit_info.get("punch_hit", false)):
		CombatHitFlashScript.flash_damage(self)
	var stun_duration := GroyperHitReactionConfig.LIGHT_HIT_STUN_DURATION
	if bool(hit_info.get("melee", false)) and hit_info.has("melee_stun_duration"):
		stun_duration = float(hit_info["melee_stun_duration"])
	if stun_duration <= 0.0:
		return
	apply_melee_stun(stun_duration)
	hold_knockback_velocity(stun_duration)



func _try_begin_face_punch_reaction(hit_info: Dictionary) -> void:
	if not _face_punch_nodes_ready or _face_punch_reaction_active or _overworld_defeated:
		return
	if _punch_active:
		_finish_punch()
	if _roll_active:
		_finish_roll_dodge()
	if _combat_attacking:
		_complete_melee_attack()
	if _combat_blocking:
		_end_melee_blocking(true)

	var hit_dir: Vector3 = hit_info.get("direction", Vector3.FORWARD)
	hit_dir.y = 0.0
	if hit_dir.length_squared() > 0.0001 and _model != null:
		var face_dir := -hit_dir.normalized()
		_model.rotation.y = atan2(face_dir.x, face_dir.z)

	_face_punch_duration = GroyperFacePunchReactionScript.get_duration(_animation_player)
	_face_punch_timer = 0.0
	_face_punch_blend = 0.0
	_face_punch_reaction_active = true
	GroyperFacePunchReactionScript.set_blend(_animation_tree, 0.0)
	GroyperFacePunchReactionScript.set_seek(_animation_tree, 0.0)
	GroyperFacePunchReactionScript.set_playback_speed(
		_animation_tree,
		GroyperFacePunchReactionScript.PLAYBACK_SPEED
	)
	# Lock controls for a hit-stop beat only — the reaction animation keeps
	# playing while the player regains movement, instead of the full clip.
	apply_melee_stun(minf(
		GroyperFacePunchReactionScript.CONTROL_LOCK_SECONDS,
		_face_punch_duration
	))
	# The hit's knockback hold (set just before this in receive_bullet_hit)
	# would pin steering longer than the whole reaction — shorten the ride.
	_knockback_hold_timer = minf(
		_knockback_hold_timer,
		GroyperFacePunchReactionScript.KNOCKBACK_HOLD_CAP
	)
	CombatHitFlashScript.flash_damage(self)


func _update_face_punch_reaction(delta: float) -> void:
	if not _face_punch_reaction_active:
		return
	_face_punch_timer += delta
	var blend_in := clampf(
		_face_punch_timer / maxf(GroyperFacePunchReactionScript.BLEND_IN, 0.001),
		0.0,
		1.0
	)
	var remaining := maxf(_face_punch_duration - _face_punch_timer, 0.0)
	var blend_out := clampf(
		remaining / maxf(GroyperFacePunchReactionScript.BLEND_OUT, 0.001),
		0.0,
		1.0
	)
	_face_punch_blend = minf(blend_in, blend_out)
	GroyperFacePunchReactionScript.set_blend(_animation_tree, _face_punch_blend)
	# The forced per-frame scrub bypasses the TimeScale node, so the playback
	# speed must be baked into the seek time (same idiom as the knockdown fall).
	GroyperFacePunchReactionScript.set_seek(
		_animation_tree,
		_face_punch_timer * GroyperFacePunchReactionScript.PLAYBACK_SPEED
	)
	if _face_punch_timer >= _face_punch_duration:
		_finish_face_punch_reaction()


func _finish_face_punch_reaction() -> void:
	_face_punch_reaction_active = false
	_face_punch_timer = 0.0
	_face_punch_duration = 0.0
	_face_punch_blend = 0.0
	GroyperFacePunchReactionScript.set_blend(_animation_tree, 0.0)


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
	# A knockdown overrides the punched reaction — and with it the slow
	# steering and block buffering that reaction allows.
	if _face_punch_reaction_active:
		_finish_face_punch_reaction()
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
	_cancel_climb_fall_sequence()

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
	_restore_locomotion_after_hit_reaction()


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

	var target_blend := GroyperHitReactionConfig.compute_stand_reaction_blend(progress)
	# Match lasso stand-up: once blend-out begins, track the clip directly so the
	# reaction weight can't lag past the end and leave HitReactionBlend stuck on.
	if progress >= GroyperHitReactionConfig.STAND_BLEND_OUT_START:
		_hit_reaction_blend = target_blend
	else:
		var blend_step := 1.0 - exp(-HIT_REACTION_BLEND_OUT_SPEED * delta)
		_hit_reaction_blend = lerpf(_hit_reaction_blend, target_blend, blend_step)
	_apply_hit_reaction_tree_blends()

	if GroyperHitReactionConfig.should_finish_stand_up(progress, _hit_reaction_blend):
		_finish_hit_reaction()


func _restore_locomotion_after_hit_reaction() -> void:
	_init_punch_animation_tree_state()
	_clear_melee_attack_one_shot()
	_set_melee_block_hold_blend(0.0)
	_block_walk_amount = 0.0
	_apply_block_walk_locomotion_blend()
	_set_combat_idle_blend_instant(_get_combat_idle_blend_target())
	_sync_locomotion_after_melee_attack()


func _finish_hit_reaction() -> void:
	if not _hit_reaction_active and _hit_reaction_phase == GroyperHitReactionConfig.Phase.NONE:
		return
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
	_melee_stun_timer = 0.0
	if _animation_tree != null:
		GroyperHitReactionConfig.set_reaction_blend(_animation_tree, 0.0)
		GroyperHitReactionConfig.set_pose_blend(_animation_tree, 0.0)
		GroyperHitReactionConfig.set_fall_seek(_animation_tree, -1.0)
		GroyperHitReactionConfig.set_stand_seek(_animation_tree, -1.0)
		GroyperHitReactionConfig.set_stand_playback_speed(_animation_tree, 1.0)
	_restore_locomotion_after_hit_reaction()


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
	# Capture live poses first; activate() stops anim sources after capture.
	if _combat_ragdoll != null and not _combat_ragdoll.is_active():
		_combat_ragdoll.activate(hit_info, _animation_player)
	PlayerDeathLoot.drop_player_loot(get_tree().current_scene, hit_position)
	if not _death_sequence_active:
		call_deferred("_begin_death_respawn_sequence")


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
	# Crouch cover allows reload in place; walk-in / exit blends still block.
	return (
		not _roll_active
		and not _cover_walk_enter_active
		and not _cover_exit_active
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
	var dual := _is_dual_wield_equipped()
	if dual:
		if _ammo >= max_ammo and _left_ammo >= max_ammo:
			return
	elif _ammo >= max_ammo:
		return

	var uses_reserve := PlayerInventory.uses_firearm_reserve_ammo(_equipped_weapon)
	if uses_reserve and not _practice_infinite_ammo and PlayerInventory.get_weapon_reserve_ammo(_equipped_weapon) <= 0:
		return

	# Shotgun tops up in-tube shells; revolver dumps the cylinder then speed-loads.
	var keep_chambered := _equipped_weapon == GroyperWeapons.Id.SHOTGUN
	if not keep_chambered:
		var leftover := _ammo
		var left_leftover := _left_ammo if dual else 0
		_ammo = 0
		if dual:
			_left_ammo = 0
		if (
			(
				_equipped_weapon == GroyperWeapons.Id.REVOLVER
				or dual
			)
			and (leftover + left_leftover) > 0
			and not _practice_infinite_ammo
		):
			_spawn_revolver_ammo_eject_drop(leftover + left_leftover)
		if _ammo_hud:
			_ammo_hud.eject_all_casings()
		if dual and _left_ammo_hud:
			_left_ammo_hud.eject_all_casings()

	_weapon_rig.begin_overworld_reload_eject(not keep_chambered)
	if _mounted_horse != null:
		_update_saddle_gun_arm_filter(_weapon_rig.get_draw_state())

	# Revolver / dual speed-load: one press ejects and fills the cylinder(s).
	if _equipped_weapon == GroyperWeapons.Id.REVOLVER or dual:
		if _weapon_rig.try_overworld_reload_tap():
			_reload_ready_for_tap = false
			_reload_pending_round = true


func _spawn_revolver_ammo_eject_drop(amount: int) -> void:
	var parent := get_parent()
	if parent == null:
		parent = self
	var drop_from := global_position + Vector3(0.0, 0.95, 0.0)
	RevolverAmmoPickupScript.spawn_eject_drop(parent, drop_from, amount)


func _update_active_reload(phase: GroyperWeaponRig.OverworldReloadPhase) -> void:
	if phase == GroyperWeaponRig.OverworldReloadPhase.TAP_READY:
		if not Input.is_key_pressed(RELOAD_KEY):
			_reload_ready_for_tap = true

	if phase in [
		GroyperWeaponRig.OverworldReloadPhase.TAP_READY,
		GroyperWeaponRig.OverworldReloadPhase.LOADING,
	]:
		var want_aim_stance := false
		if not _is_dual_wield_equipped():
			want_aim_stance = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and (
				_ammo > 0 or _weapon_rig.did_overworld_reload_start_from_aim()
			)
		_weapon_rig.set_overworld_reload_aim_stance(want_aim_stance)

	if _reload_pending_round and phase == GroyperWeaponRig.OverworldReloadPhase.TAP_READY:
		_finish_reload_round()


func _try_overworld_reload_tap() -> bool:
	if _weapon_rig == null or not _reload_ready_for_tap:
		return false
	if (
		PlayerInventory.uses_firearm_reserve_ammo(_equipped_weapon)
		and not _practice_infinite_ammo
		and PlayerInventory.get_weapon_reserve_ammo(_equipped_weapon) <= 0
	):
		return false
	if not _weapon_rig.try_overworld_reload_tap():
		return false

	_reload_ready_for_tap = false
	_reload_pending_round = true
	return true


func _finish_reload_round() -> void:
	_reload_pending_round = false
	var max_ammo := GroyperWeapons.get_max_ammo(_equipped_weapon)
	var uses_reserve := PlayerInventory.uses_firearm_reserve_ammo(_equipped_weapon)
	var per_round := GroyperWeapons.uses_per_round_overworld_reload(_equipped_weapon)
	var dual := _is_dual_wield_equipped()

	if per_round:
		if uses_reserve and not _practice_infinite_ammo:
			if PlayerInventory.get_weapon_reserve_ammo(_equipped_weapon) <= 0:
				_end_reload_for_empty_reserve()
				return
			PlayerInventory.try_consume_weapon_reserve_ammo(_equipped_weapon, 1)
		_ammo = mini(_ammo + 1, max_ammo)
		if _ammo_hud:
			_ammo_hud.animate_reload_round(_ammo)
			if uses_reserve:
				_ammo_hud.sync_reserve_ammo(PlayerInventory.get_weapon_reserve_ammo(_equipped_weapon))
		if _equipped_weapon == GroyperWeapons.Id.SHOTGUN:
			GameAudio.play_shotgun_reload(self, global_position + Vector3(0.0, 1.0, 0.0))
	elif dual:
		# Fill right cylinder first, then left, from the shared revolver reserve.
		var available := (
			999 if _practice_infinite_ammo
			else PlayerInventory.get_weapon_reserve_ammo(_equipped_weapon)
		)
		if uses_reserve and available <= 0 and not _practice_infinite_ammo:
			_end_reload_for_empty_reserve()
			return
		var right_need := max_ammo
		var right_load := mini(right_need, available)
		if uses_reserve and not _practice_infinite_ammo and right_load > 0:
			PlayerInventory.try_consume_weapon_reserve_ammo(_equipped_weapon, right_load)
			available -= right_load
		_ammo = right_load
		var left_load := mini(max_ammo, available)
		if uses_reserve and not _practice_infinite_ammo and left_load > 0:
			PlayerInventory.try_consume_weapon_reserve_ammo(_equipped_weapon, left_load)
		elif _practice_infinite_ammo:
			left_load = max_ammo
		_left_ammo = left_load
		if _ammo_hud:
			_ammo_hud.animate_reload_round(_ammo)
			if uses_reserve:
				_ammo_hud.sync_reserve_ammo(PlayerInventory.get_weapon_reserve_ammo(_equipped_weapon))
		if _left_ammo_hud:
			_left_ammo_hud.configure_for_weapon(GroyperWeapons.Id.DUAL_REVOLVER)
			_left_ammo_hud.set_show_reserve(false)
			_left_ammo_hud.animate_reload_round(_left_ammo)
	else:
		var loaded := max_ammo
		if uses_reserve and not _practice_infinite_ammo:
			var available := PlayerInventory.get_weapon_reserve_ammo(_equipped_weapon)
			loaded = mini(max_ammo, available)
			if loaded <= 0:
				_end_reload_for_empty_reserve()
				return
			PlayerInventory.try_consume_weapon_reserve_ammo(_equipped_weapon, loaded)
		_ammo = loaded
		if _ammo_hud:
			if _equipped_weapon == GroyperWeapons.Id.REVOLVER:
				_ammo_hud.animate_reload_round(_ammo)
			else:
				_ammo_hud.animate_reload_magazine(_ammo)
			if uses_reserve:
				_ammo_hud.sync_reserve_ammo(PlayerInventory.get_weapon_reserve_ammo(_equipped_weapon))

	_sync_rpg_grip_rocket()

	if not per_round or _ammo >= max_ammo:
		var return_to_aim := (
			(not dual and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT))
			or _should_gun_stay_drawn()
		)
		_weapon_rig.finish_overworld_reload(return_to_aim)
		_reset_reload_input()
	elif (
		uses_reserve
		and not _practice_infinite_ammo
		and PlayerInventory.get_weapon_reserve_ammo(_equipped_weapon) <= 0
	):
		_end_reload_for_empty_reserve()
	else:
		_reload_ready_for_tap = false


func _end_reload_for_empty_reserve() -> void:
	if _weapon_rig == null:
		_reset_reload_input()
		return
	var has_chambered := _ammo > 0 or (_is_dual_wield_equipped() and _left_ammo > 0)
	var return_to_aim := (
		(
			_is_dual_wield_equipped()
			or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
			or _should_gun_stay_drawn()
		)
		and has_chambered
	)
	if return_to_aim:
		_weapon_rig.cancel_overworld_reload_for_aim()
	else:
		_weapon_rig.finish_overworld_reload(false)
	_reset_reload_input()
	_update_combat_ui()


func _on_reload_key_released() -> void:
	if _weapon_rig == null:
		return
	if _weapon_rig.get_overworld_reload_phase() == GroyperWeaponRig.OverworldReloadPhase.TAP_READY:
		_reload_ready_for_tap = true


func _try_interrupt_reload_with_aim() -> bool:
	if _is_dual_wield_equipped():
		return false
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

	if _combat_hurtbox_bone_id == -2:
		_combat_hurtbox_bone_id = -1
		for bone_name in ["Spine02", "Spine01", "Spine"]:
			var bone_id := _skeleton.find_bone(bone_name)
			if bone_id >= 0:
				_combat_hurtbox_bone_id = bone_id
				break

	if _combat_hurtbox_bone_id >= 0:
		var bone_global := _skeleton.global_transform * _skeleton.get_bone_global_pose(_combat_hurtbox_bone_id)
		return Transform3D(
			bone_global.basis,
			bone_global.origin + bone_global.basis * Vector3(0.0, 0.04, 0.02)
		)

	var fallback := global_transform
	fallback.origin = global_position + Vector3(0.0, 1.05, 0.0)
	return fallback


func _debug_print_camera_state() -> void:
	if _camera == null:
		print("[CAMERA DEBUG] Camera3D node is missing.")
		return

	var local_offset := _camera.position
	var pivot_pos := _camera_pivot.position
	var arm_pitch := _camera_arm.rotation.x if _camera_arm != null else 0.0
	var occlusion_pitch := _camera_arm.get_occlusion_pitch() if _camera_arm != null else 0.0
	var logical_pitch := _camera_pitch

	print("[CAMERA DEBUG] Copy-paste camera reference:")
	if _debug_camera_remote_edit:
		print("\t# remote edit ON — values reflect Remote scene tree transforms")
	print("\tconst CAMERA_OFFSET := Vector3(%.4f, %.4f, %.4f)" % [local_offset.x, local_offset.y, local_offset.z])
	print("\tconst CAMERA_PIVOT_Y := %.4f" % pivot_pos.y)
	print("\tconst CAMERA_FOV := %.2f" % _camera.fov)
	print(
		"\tconst CAMERA_PITCH := %.4f  # %.2f deg (lock-on arm X blends to %.1f deg)"
		% [logical_pitch, rad_to_deg(logical_pitch), rad_to_deg(LOCK_ON_CAMERA_PITCH)]
	)
	print(
		"\t# yaw=%.4f rad (%.1f deg) blends aim=%.2f melee=%.2f reload=%.2f interior=%.2f lock_on=%.2f slow_return=%s"
		% [
			_camera_yaw,
			rad_to_deg(_camera_yaw),
			_aim_camera_blend,
			_melee_camera_blend,
			_reload_camera_blend,
			_interior_camera_blend,
			_lock_on_camera_blend,
			_interior_camera_slow_return,
		]
	)
	print(
		"\t# arm_pitch=%.4f occlusion_pitch=%.4f global_position=%s"
		% [arm_pitch, occlusion_pitch, _camera.global_position]
	)
	print(
		"\t# explore baseline offset=%s pivot_y=%.4f fov=%.2f active_offset=%s"
		% [
			_explore_camera_offset,
			_explore_camera_pivot_y,
			_explore_camera_fov,
			_get_active_explore_camera_offset(),
		]
	)


func _debug_print_current_collisions() -> void:
	var count := get_slide_collision_count()
	if count == 0:
		print(
			"[COLLISION DEBUG] No slide collisions. Walk into a wall and press U again. player=",
			global_position,
			" velocity=",
			velocity
		)
		return

	print(
		"[COLLISION DEBUG] ",
		count,
		" contact(s) player=",
		global_position,
		" velocity=",
		velocity
	)
	for i in count:
		_debug_print_slide_collision(i)


func _debug_print_slide_collision(index: int) -> void:
	var collision := get_slide_collision(index)
	var collider := collision.get_collider()
	if collider == null:
		print(
			"  [",
			index,
			"] collider=null normal=",
			collision.get_normal(),
			" pos=",
			collision.get_position()
		)
		return

	var collider_path := str(collider.get_path()) if collider is Node else str(collider)
	var collider_class := collider.get_class()
	var collider_global := ""
	if collider is Node3D:
		collider_global = str((collider as Node3D).global_position)

	print(
		"  [",
		index,
		"] ",
		collider_path,
		" (",
		collider_class,
		") normal=",
		collision.get_normal(),
		" pos=",
		collision.get_position(),
		" depth=",
		collision.get_depth(),
		" collider_global=",
		collider_global,
		" shape=",
		_debug_collision_shape_label(collider)
	)


func _debug_collision_shape_label(collider: Object) -> String:
	if collider is CollisionShape3D:
		return _debug_shape_resource_label((collider as CollisionShape3D).shape)
	if not collider is CollisionObject3D:
		return "n/a"

	var body := collider as CollisionObject3D
	for child in body.get_children():
		if child is CollisionShape3D:
			return _debug_shape_resource_label((child as CollisionShape3D).shape)
	return "unknown"


func _debug_shape_resource_label(shape: Shape3D) -> String:
	if shape == null:
		return "null"
	if shape is BoxShape3D:
		return "Box3D size=" + str((shape as BoxShape3D).size)
	if shape is CapsuleShape3D:
		var capsule := shape as CapsuleShape3D
		return "Capsule3D r=" + str(capsule.radius) + " h=" + str(capsule.height)
	if shape is SphereShape3D:
		return "Sphere3D r=" + str((shape as SphereShape3D).radius)
	if shape is CylinderShape3D:
		var cylinder := shape as CylinderShape3D
		return "Cylinder3D r=" + str(cylinder.radius) + " h=" + str(cylinder.height)
	return shape.get_class()
