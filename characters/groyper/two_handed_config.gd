class_name TwoHandedConfig
extends RefCounted

## Authored two-handed melee clips, extracted from the 2Handed Meshy merged FBX
## (plus a duplicate of the sword & shield spin attack) into an editable
## AnimationLibrary so they can be tuned in groyper_body.tscn's AnimationPlayer.

const LIBRARY_NAME := &"two_handed"
const OUT_PATH := "res://characters/groyper/two_handed.tres"

const MERGED_SCENE := (
	"res://Assets/CharacterModels/Groyper/GroyperSDanimations/2Handed/"
	+ "Meshy_AI_Emerald_Embrace_biped/"
	+ "Meshy_AI_Emerald_Embrace_biped_Meshy_AI_Meshy_Merged_Animations.fbx"
)
## Spin/sprint attack is a duplicate of the sword & shield spin attack so the
## player can edit a two-handed variant without touching the original.
const SPIN_ATTACK_SCENE := (
	"res://Assets/CharacterModels/Groyper/GroyperSDanimations/Meshy_AI_Emerald_Embrace_biped/"
	+ "Meshy_AI_Emerald_Embrace_biped_Animation_Axe_Spin_Attack_frame_rate_60.fbx"
)

## Source clip names inside the merged FBX (60fps authored, 30fps imported).
const MESHY_IDLE := &"Idle_5_frame_rate_60_fbx"
const MESHY_WALK := &"Carry_Heavy_Cannon_Forward_frame_rate_60_fbx"
const MESHY_SPRINT := &"ForwardLeft_Run_Fight_frame_rate_60_fbx"
const MESHY_ATTACK := &"Attack_frame_rate_60_fbx"
const MESHY_COMBO := &"Heavy_Hammer_Swing_frame_rate_60_fbx"
const MESHY_PARRY := &"Two_Handed_Parry_frame_rate_60_fbx"

## Authored clip names inside two_handed.tres.
const CLIP_IDLE := &"idle"
const CLIP_WALK := &"walk"
const CLIP_SPRINT := &"sprint"
const CLIP_ATTACK := &"attack"
const CLIP_COMBO := &"combo"
const CLIP_PARRY := &"parry"
## First-frame hold pose derived from the parry, used while holding block.
const CLIP_BLOCK_HOLD := &"block_hold"
## Editable duplicate of the sword & shield spin attack.
const CLIP_SPIN_ATTACK := &"spin_attack"

static func clip_path(clip_name: StringName) -> StringName:
	return StringName("%s/%s" % [LIBRARY_NAME, clip_name])
