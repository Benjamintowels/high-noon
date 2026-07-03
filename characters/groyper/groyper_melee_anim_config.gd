class_name GroyperMeleeAnimConfig
extends RefCounted

const MESHY_BASE := (
	"res://Assets/CharacterModels/Groyper/GroyperSDanimations/Meshy_AI_Emerald_Embrace_biped/"
)

const COMBAT_IDLE_SCENE := (
	MESHY_BASE + "Meshy_AI_Emerald_Embrace_biped_Animation_Idle_8_frame_rate_60.fbx"
)
const SWORD_SLASH_SCENE := (
	MESHY_BASE + "Meshy_AI_Emerald_Embrace_biped_Animation_Right_Hand_Sword_Slash_frame_rate_60.fbx"
)
const BLOCK_HOLD_SCENE := (
	MESHY_BASE + "Meshy_AI_Emerald_Embrace_biped_Animation_Sword_Parry_Backward_1_frame_rate_60.fbx"
)
const BLOCK_CLASH_SCENE := (
	MESHY_BASE + "Meshy_AI_Emerald_Embrace_biped_Animation_Sword_Parry_Backward_4_frame_rate_60.fbx"
)
const BLOCK_BREAK_SCENE := (
	MESHY_BASE + "Meshy_AI_Emerald_Embrace_biped_Animation_Sword_Parry_Backward_5_frame_rate_60.fbx"
)
const BLOCK_WALK_BACKWARD_SCENE := (
	MESHY_BASE
	+ "Meshy_AI_Emerald_Embrace_biped_Animation_Walk_Backward_with_Sword_Shield_frame_rate_60.fbx"
)

const LIBRARY := &"melee"
const CLIP_COMBAT_IDLE := &"combat_idle"
const CLIP_SWORD_SLASH := &"sword_slash"
const CLIP_BLOCK_HOLD := &"shield_block_hold"
const CLIP_BLOCK_CLASH := &"shield_block_clash"
const CLIP_BLOCK_BREAK := &"shield_block_break"
const CLIP_BLOCK_WALK_BACKWARD := &"block_walk_backward"
const CLIP_BLOCK_WALK_FORWARD := &"block_walk_forward"

const BLOCK_HOLD_BLEND := &"MeleeBlockHoldBlend"
const ATTACK_ONE_SHOT := &"MeleeAttackOneShot"
const BLOCK_CLASH_ONE_SHOT := &"MeleeBlockClashOneShot"
const BLOCK_BREAK_ONE_SHOT := &"MeleeBlockBreakOneShot"
const SHIELD_BLOCK_HOLD_ANIM := &"MeleeShieldBlockHoldAnim"
const ATTACK_ANIM := &"MeleeAttackAnim"
const SHIELD_BLOCK_CLASH_ANIM := &"MeleeShieldBlockClashAnim"
const SHIELD_BLOCK_BREAK_ANIM := &"MeleeShieldBlockBreakAnim"


static func clip_path(clip_name: StringName) -> StringName:
	return StringName("%s/%s" % [LIBRARY, clip_name])
