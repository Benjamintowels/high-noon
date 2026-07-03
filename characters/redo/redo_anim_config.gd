class_name RedoAnimConfig
extends RefCounted

const MERGED_SCENE := (
	"res://Assets/CharacterModels/Redo/Meshy_AI_a_white_dog_with_blac_biped/"
	+ "Meshy_AI_a_white_dog_with_blac_biped_Meshy_AI_Meshy_Merged_Animations.fbx"
)

const BODY_SCENE := MERGED_SCENE

const MESHY_IDLE := &"Idle_5_frame_rate_60_fbx"
const MESHY_WALK := &"Walking_frame_rate_60_fbx"
const MESHY_RUN := &"Running_frame_rate_60_fbx"
const MESHY_HEAVY_HAMMER := &"Heavy_Hammer_Swing_frame_rate_60_fbx"
const MESHY_SWORD_PARRY := &"Sword_Parry_frame_rate_60_fbx"
const MESHY_SWORD_PARRY_BACKWARD := &"Sword_Parry_Backward_frame_rate_60_fbx"
const MESHY_ROLL_DODGE := &"Roll_Dodge_1_frame_rate_60_fbx"
const MAGE_SPELL_SCENE := (
	"res://Assets/CharacterModels/Redo/Meshy_AI_a_white_dog_with_blac_biped/"
	+ "Meshy_AI_a_white_dog_with_blac_biped_Animation_mage_soell_cast_6_frame_rate_60.fbx"
)
const MESHY_MAGE_SPELL := &"Armature|Armature|Scene"

const LIBRARY := &"redo"
const CLIP_IDLE := &"idle"
const CLIP_WALK := &"walk"
const CLIP_RUN := &"run"
const CLIP_HEAVY_HAMMER := &"heavy_hammer"
const CLIP_PARRY_POSE := &"parry_pose"
const CLIP_PARRY_BACKWARD := &"parry_backward"
const CLIP_ROLL_DODGE := &"roll_dodge"
const CLIP_MAGE_SPELL := &"mage_spell"

const LOCOMOTION_BLEND := &"LocomotionBlend"
const BLOCK_BLEND := &"BlockBlend"
const ATTACK_ONE_SHOT := &"AttackOneShot"
const SPELL_ONE_SHOT := &"SpellOneShot"
const PARRY_STUN_ONE_SHOT := &"ParryStunOneShot"
const ROLL_ONE_SHOT := &"RollOneShot"

const OUT_DIR := "res://characters/redo/anims/"
const IDLE_PATH := OUT_DIR + "redo_idle.tres"
const WALK_PATH := OUT_DIR + "redo_walk.tres"
const RUN_PATH := OUT_DIR + "redo_run.tres"
const HEAVY_HAMMER_PATH := OUT_DIR + "redo_heavy_hammer.tres"
const PARRY_POSE_PATH := OUT_DIR + "redo_parry_pose.tres"
const PARRY_BACKWARD_PATH := OUT_DIR + "redo_parry_backward.tres"
const ROLL_DODGE_PATH := OUT_DIR + "redo_roll_dodge.tres"
const MAGE_SPELL_PATH := OUT_DIR + "redo_mage_spell.tres"
const LIB_PATH := OUT_DIR + "redo_anim_library.tres"
