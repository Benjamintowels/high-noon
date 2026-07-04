class_name UndeadAnimConfig
extends RefCounted

const MESHY_BASE := (
	"res://Assets/CharacterModels/Undead/Meshy_AI_Ironbone_Skeleton_Kni_biped/"
)

## Meshy animation-only exports (Idle 7/10, Roll Dodge) have no skinned mesh — use a clip FBX that includes char1.
const BODY_SCENE := MESHY_BASE + "Meshy_AI_Ironbone_Skeleton_Kni_biped_Animation_Walking_frame_rate_60.fbx"
const IDLE_SCENE := MESHY_BASE + "Meshy_AI_Ironbone_Skeleton_Kni_biped_Animation_Idle_7_frame_rate_60.fbx"
const COMBAT_IDLE_SCENE := MESHY_BASE + "Meshy_AI_Ironbone_Skeleton_Kni_biped_Animation_Idle_10_frame_rate_60.fbx"
const WALK_SCENE := MESHY_BASE + "Meshy_AI_Ironbone_Skeleton_Kni_biped_Animation_Walking_frame_rate_60.fbx"
const RUN_SCENE := MESHY_BASE + "Meshy_AI_Ironbone_Skeleton_Kni_biped_Animation_Running_frame_rate_60.fbx"
const SWORD_SLASH_SCENE := (
	MESHY_BASE + "Meshy_AI_Ironbone_Skeleton_Kni_biped_Animation_Right_Hand_Sword_Slash_frame_rate_60.fbx"
)
const CHARGED_UPWARD_SCENE := (
	MESHY_BASE + "Meshy_AI_Ironbone_Skeleton_Kni_biped_Animation_Charged_Upward_Slash_frame_rate_60.fbx"
)
const SPRINT_SPIN_SCENE := (
	MESHY_BASE + "Meshy_AI_Ironbone_Skeleton_Kni_biped_Animation_Double_Blade_Spin_frame_rate_60.fbx"
)
const PARRY_SCENE := MESHY_BASE + "Meshy_AI_Ironbone_Skeleton_Kni_biped_Animation_Sword_Parry_frame_rate_60.fbx"
const PARRY_BACKWARD_SCENE := (
	MESHY_BASE + "Meshy_AI_Ironbone_Skeleton_Kni_biped_Animation_Sword_Parry_Backward_frame_rate_60.fbx"
)
const ROLL_SCENE := MESHY_BASE + "Meshy_AI_Ironbone_Skeleton_Kni_biped_Animation_Roll_Dodge_1_frame_rate_60.fbx"

const MESHY_SWORD_PARRY := &"Armature|Armature|Scene"
const MESHY_SWORD_PARRY_BACKWARD := &"Armature|Armature|Scene"

const LIBRARY := &"undead"
const CLIP_IDLE := &"idle"
const CLIP_COMBAT_IDLE := &"combat_idle"
const CLIP_WALK := &"walk"
const CLIP_RUN := &"run"
const CLIP_SWORD_SLASH := &"sword_slash"
const CLIP_CHARGED_UPWARD := &"charged_upward"
const CLIP_SPRINT_SPIN := &"sprint_spin"
const CLIP_PARRY_POSE := &"parry_pose"
const CLIP_PARRY_BACKWARD := &"parry_backward"
const CLIP_ROLL_DODGE := &"roll_dodge"

const LOCOMOTION_BLEND := &"LocomotionBlend"
const COMBAT_IDLE_BLEND := &"CombatIdleBlend"
const BLOCK_BLEND := &"BlockBlend"
const SWORD_SLASH_ONE_SHOT := &"SwordSlashOneShot"
const SWORD_SLASH_TIME_SCALE := &"SwordSlashTimeScale"
const CHARGED_UPWARD_ONE_SHOT := &"ChargedUpwardOneShot"
const CHARGED_UPWARD_TIME_SCALE := &"ChargedUpwardTimeScale"
const SPRINT_SPIN_ONE_SHOT := &"SprintSpinOneShot"
const SPRINT_SPIN_TIME_SCALE := &"SprintSpinTimeScale"
const PARRY_STUN_ONE_SHOT := &"ParryStunOneShot"
const ROLL_ONE_SHOT := &"RollOneShot"

const OUT_DIR := "res://characters/undead/anims/"
const IDLE_PATH := OUT_DIR + "undead_idle.tres"
const COMBAT_IDLE_PATH := OUT_DIR + "undead_combat_idle.tres"
const WALK_PATH := OUT_DIR + "undead_walk.tres"
const RUN_PATH := OUT_DIR + "undead_run.tres"
const SWORD_SLASH_PATH := OUT_DIR + "undead_sword_slash.tres"
const CHARGED_UPWARD_PATH := OUT_DIR + "undead_charged_upward.tres"
const SPRINT_SPIN_PATH := OUT_DIR + "undead_sprint_spin.tres"
const PARRY_POSE_PATH := OUT_DIR + "undead_parry_pose.tres"
const PARRY_BACKWARD_PATH := OUT_DIR + "undead_parry_backward.tres"
const ROLL_DODGE_PATH := OUT_DIR + "undead_roll_dodge.tres"
const LIB_PATH := OUT_DIR + "undead_anim_library.tres"
