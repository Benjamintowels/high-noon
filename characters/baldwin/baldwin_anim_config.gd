class_name BaldwinAnimConfig
extends RefCounted

const MERGED_SCENE := (
	"res://Assets/CharacterModels/Baldwin/Meshy_AI_King_Croaker_biped/"
	+ "Meshy_AI_King_Croaker_biped_Meshy_AI_Meshy_Merged_Animations.fbx"
)

## Use the merged animation FBX for the body mesh so the skeleton matches the clips.
const BODY_SCENE := MERGED_SCENE

const MESHY_AXE_STANCE := &"Axe_Stance_frame_rate_60_fbx"
const MESHY_AGGRO_IDLE := &"Axe_Breathe_and_Look_Around_frame_rate_60_fbx"
const MESHY_IDLE := &"Short_Breathe_and_Look_Around_frame_rate_60_fbx"
const MESHY_WALK := &"Walking_frame_rate_60_fbx"
const MESHY_RUN := &"Running_frame_rate_60_fbx"
const MESHY_SWORD_SLASH := &"Right_Hand_Sword_Slash_frame_rate_60_fbx"
const MESHY_SWORD_PARRY := &"Sword_Parry_frame_rate_60_fbx"
const MESHY_SWORD_PARRY_BACKWARD := &"Sword_Parry_Backward_frame_rate_60_fbx"
const MESHY_SHIELD_BLOCK_HOLD := &"Sword_Parry_Backward_1_frame_rate_60_fbx"
const MESHY_SHIELD_BLOCK_ENTER := &"Sword_Parry_Backward_2_frame_rate_60_fbx"
const MESHY_SHIELD_BLOCK_CLASH := &"Sword_Parry_Backward_4_frame_rate_60_fbx"
const MESHY_SHIELD_BLOCK_BREAK := &"Sword_Parry_Backward_5_frame_rate_60_fbx"
const MESHY_ROLL_DODGE := &"Roll_Dodge_1_frame_rate_60_fbx"

const ROLL_SCENE := (
	"res://Assets/CharacterModels/Baldwin/Meshy_AI_King_Croaker_biped/"
	+ "Meshy_AI_King_Croaker_biped_Animation_Roll_Dodge_1_frame_rate_60.fbx"
)

const LIBRARY := &"baldwin"
const CLIP_AXE_STANCE := &"axe_stance"
const CLIP_AXE_STANCE_REVERSE := &"axe_stance_reverse"
const CLIP_AXE_STANCE_POSE := &"axe_stance_pose"
const CLIP_AXE_STANCE_END_POSE := &"axe_stance_end_pose"
const CLIP_IDLE := &"idle"
const CLIP_AGGRO_IDLE := &"aggro_idle"
const CLIP_WALK := &"walk"
const CLIP_RUN := &"run"
const CLIP_SWORD_SLASH := &"sword_slash"
const CLIP_SWORD_SLASH_REVERSE := &"sword_slash_reverse"
const CLIP_PARRY_POSE := &"parry_pose"
const CLIP_PARRY_BACKWARD := &"parry_backward"
const CLIP_SHIELD_BLOCK_HOLD := &"shield_block_hold"
const CLIP_SHIELD_BLOCK_ENTER := &"shield_block_enter"
const CLIP_SHIELD_BLOCK_CLASH := &"shield_block_clash"
const CLIP_SHIELD_BLOCK_BREAK := &"shield_block_break"
const CLIP_ROLL_DODGE := &"roll_dodge"

const LOCOMOTION_BLEND := &"LocomotionBlend"
const STANCE_ONE_SHOT := &"StanceOneShot"
const RECRUIT_IDLE_BLEND := &"RecruitIdleBlend"
const ATTACK_ONE_SHOT := &"AttackOneShot"
const ATTACK_TIME_SEEK := &"AttackTimeSeek"
const BLOCK_HOLD_BLEND := &"BlockHoldBlend"
const BLOCK_ENTER_ONE_SHOT := &"BlockEnterOneShot"
const BLOCK_CLASH_ONE_SHOT := &"BlockClashOneShot"
const BLOCK_BREAK_ONE_SHOT := &"BlockBreakOneShot"
const ROLL_ONE_SHOT := &"RollOneShot"
const PARRY_STUN_ONE_SHOT := BLOCK_CLASH_ONE_SHOT
