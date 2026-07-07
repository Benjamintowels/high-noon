class_name TcAnimConfig
extends RefCounted

const MERGED_SCENE := (
	"res://Assets/CharacterModels/TC/Meshy_AI_Crustacean_Colossus_biped/"
	+ "Meshy_AI_Crustacean_Colossus_biped_Meshy_AI_Meshy_Merged_Animations.fbx"
)

const BODY_SCENE := MERGED_SCENE

const MESHY_IDLE := &"Idle_5_frame_rate_60_fbx"
const MESHY_COMBAT_IDLE := &"Idle_5_frame_rate_60_fbx"
const MESHY_WALK := &"Walking_frame_rate_60_fbx"
const MESHY_RUN := &"Running_frame_rate_60_fbx"
const MESHY_PUNCH_FORWARD := &"Punch_Forward_with_Both_Fists_frame_rate_60_fbx"
const MESHY_BACK_JUMP := &"Back_Jump_frame_rate_60_fbx"
const MESHY_FALL2 := &"Fall2_frame_rate_60_fbx"
const MESHY_BACKFLIP_HOOKS := &"Backflip_and_Hooks_frame_rate_60_fbx"
const MESHY_BLOCK1 := &"Block1_frame_rate_60_fbx"
const MESHY_BLOCK2 := &"Block2_frame_rate_60_fbx"
const MESHY_BLOCK3 := &"Block3_frame_rate_60_fbx"
const MESHY_BLOCK4 := &"Block4_frame_rate_60_fbx"
const MESHY_BLOCK5 := &"Block5_frame_rate_60_fbx"
const MESHY_FACE_PUNCH_REACT := &"Face_Punch_Reaction_1_frame_rate_60_fbx"
const MESHY_CHARGE := &"Wall_Push_Jump_and_Flip_frame_rate_60_fbx"

const RUN_FAST_SCENE := (
	"res://Assets/CharacterModels/TC/Meshy_AI_Crustacean_Colossus_biped/"
	+ "Meshy_AI_Crustacean_Colossus_biped_Animation_RunFast_frame_rate_60.fbx"
)
const MESHY_RUN_FAST := &"Armature|Armature|Armature|Armature|RunFast|baselayer"

const WALL_FLIP_SCENE := (
	"res://Assets/CharacterModels/TC/Meshy_AI_Crustacean_Colossus_biped/"
	+ "Meshy_AI_Crustacean_Colossus_biped_Animation_Wall_Flip_frame_rate_60.fbx"
)
const MESHY_WALL_FLIP := &"Armature|Armature|Armature|Armature|Wall_Flip|baselayer"

const HIP_HOP_DANCE_SCENE := (
	"res://Assets/CharacterModels/TC/Meshy_AI_Crustacean_Colossus_biped/"
	+ "Meshy_AI_Crustacean_Colossus_biped_Animation_Hip_Hop_Dance_2_frame_rate_60.fbx"
)
const MESHY_HIP_HOP_DANCE := &"Armature|Armature|Armature|Armature|Hip_Hop_Dance_2|baselayer"

const FALLING_DOWN_SCENE := (
	"res://Assets/CharacterModels/TC/Meshy_AI_Crustacean_Colossus_biped/"
	+ "Meshy_AI_Crustacean_Colossus_biped_Animation_falling_down_frame_rate_60.fbx"
)
const STAND_UP_SCENE := (
	"res://Assets/CharacterModels/TC/Meshy_AI_Crustacean_Colossus_biped/"
	+ "Meshy_AI_Crustacean_Colossus_biped_Animation_Stand_Up1_frame_rate_60.fbx"
)

const BLOCK_REACT_MESHY: Array[StringName] = [
	MESHY_BLOCK2,
	MESHY_BLOCK3,
	MESHY_BLOCK4,
	MESHY_BLOCK5,
]

const LIBRARY := &"tc"
const CLIP_IDLE := &"idle"
const CLIP_COMBAT_IDLE := &"combat_idle"
const CLIP_WALK := &"walk"
const CLIP_RUN := &"run"
const CLIP_PUNCH_FORWARD := &"punch_forward"
const CLIP_BACK_JUMP := &"back_jump"
const CLIP_FALL2 := &"fall2"
const CLIP_BACKFLIP_HOOKS := &"backflip_hooks"
const CLIP_BLOCK1 := &"block1"
const CLIP_BLOCK2 := &"block2"
const CLIP_BLOCK3 := &"block3"
const CLIP_BLOCK4 := &"block4"
const CLIP_BLOCK5 := &"block5"
const CLIP_FACE_PUNCH_REACT := &"face_punch_react"
const CLIP_CHARGE := &"charge"
const CLIP_RUN_FAST := &"run_fast"
const CLIP_WALL_FLIP := &"wall_flip"
const CLIP_HIP_HOP_DANCE := &"hip_hop_dance"
const CLIP_FALLING_DOWN := &"falling_down"
const CLIP_STAND_UP := &"stand_up1"

const LOCOMOTION_BLEND := &"LocomotionBlend"
const COMBAT_IDLE_BLEND := &"CombatIdleBlend"
const BLOCK_BLEND := &"BlockBlend"
const PUNCH_ONE_SHOT := &"PunchOneShot"
const BACK_JUMP_ONE_SHOT := &"BackJumpOneShot"
const FALL2_ONE_SHOT := &"Fall2OneShot"
const BACKFLIP_ONE_SHOT := &"BackflipOneShot"
const CHARGE_ONE_SHOT := &"ChargeOneShot"
const RUN_FAST_ONE_SHOT := &"RunFastOneShot"
const WALL_FLIP_ONE_SHOT := &"WallFlipOneShot"
const BLOCK_REACT_ONE_SHOT := &"BlockReactOneShot"
const HIT_REACT_ONE_SHOT := &"HitReactOneShot"
const HIT_REACT_TIME_SCALE := &"HitReactTimeScale"
const HIP_HOP_ONE_SHOT := &"HipHopOneShot"

const OUT_DIR := "res://characters/tc/anims/"
const IDLE_PATH := OUT_DIR + "tc_idle.tres"
const COMBAT_IDLE_PATH := OUT_DIR + "tc_combat_idle.tres"
const WALK_PATH := OUT_DIR + "tc_walk.tres"
const RUN_PATH := OUT_DIR + "tc_run.tres"
const PUNCH_FORWARD_PATH := OUT_DIR + "tc_punch_forward.tres"
const BACK_JUMP_PATH := OUT_DIR + "tc_back_jump.tres"
const FALL2_PATH := OUT_DIR + "tc_fall2.tres"
const BACKFLIP_HOOKS_PATH := OUT_DIR + "tc_backflip_hooks.tres"
const BLOCK1_PATH := OUT_DIR + "tc_block1.tres"
const BLOCK2_PATH := OUT_DIR + "tc_block2.tres"
const BLOCK3_PATH := OUT_DIR + "tc_block3.tres"
const BLOCK4_PATH := OUT_DIR + "tc_block4.tres"
const BLOCK5_PATH := OUT_DIR + "tc_block5.tres"
const FACE_PUNCH_REACT_PATH := OUT_DIR + "tc_face_punch_react.tres"
const CHARGE_PATH := OUT_DIR + "tc_charge.tres"
const RUN_FAST_PATH := OUT_DIR + "tc_run_fast.tres"
const WALL_FLIP_PATH := OUT_DIR + "tc_wall_flip.tres"
const HIP_HOP_DANCE_PATH := OUT_DIR + "tc_hip_hop_dance.tres"
const LIB_PATH := OUT_DIR + "tc_anim_library.tres"
