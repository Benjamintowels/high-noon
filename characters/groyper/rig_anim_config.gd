class_name RigAnimConfig
extends RefCounted

## Meshy rig animations imported under characters/RigAnim/.
## Clips are pulled from FBX scenes and registered on the groyper Body AnimationPlayer.

const MESHY_CLIP_NAME := &"Armature|Armature|Scene"

const SIDESTEP_LEFT_SCENE := (
	"res://characters/RigAnim/sidestepLeft/"
	+ "Meshy_AI_Emerald_Embrace_biped_Animation_Crouch_Walk_Left_with_Torch_inplace_frame_rate_60.fbx"
)
const SIDESTEP_RIGHT_SCENE := (
	"res://characters/RigAnim/sidestepRight/"
	+ "Meshy_AI_Emerald_Embrace_biped_Animation_Crouch_Walk_Right_with_Torch_inplace_frame_rate_60.fbx"
)

const WALK_SCENE := (
	"res://Assets/CharacterModels/Groyper/GroyperSDanimations/Meshy_AI_Emerald_Embrace_biped/"
	+ "Meshy_AI_Emerald_Embrace_biped_Animation_Walking_frame_rate_60.fbx"
)
const RUN_SCENE := (
	"res://Assets/CharacterModels/Groyper/GroyperSDanimations/Meshy_AI_Emerald_Embrace_biped/"
	+ "Meshy_AI_Emerald_Embrace_biped_Animation_Running_frame_rate_60.fbx"
)
const IDLE_SCENE := (
	"res://Assets/CharacterModels/Groyper/GroyperSDanimations/Meshy_AI_Emerald_Embrace_biped/"
	+ "Meshy_AI_Emerald_Embrace_biped_Animation_Idle_9_frame_rate_60.fbx"
)

const LOCOMOTION_LIBRARY := &"locomotion"
const LOCOMOTION_IDLE := &"idle"
const LOCOMOTION_WALK := &"walk"
const LOCOMOTION_RUN := &"run"

const AUTHORED_SIDESTEP_POSES := {
	"left": SIDESTEP_LEFT_SCENE,
	"right": SIDESTEP_RIGHT_SCENE,
}
