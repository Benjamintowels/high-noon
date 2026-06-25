class_name SheriffAnimConfig
extends RefCounted

## Meshy rig animation paths for Sheriff Money Bags.
## Idle uses the shared Groyper Meshy biped clip; walk uses the sheriff model clip.

const MESHY_CLIP_NAME := RigAnimConfig.MESHY_CLIP_NAME

const BODY_SCENE := (
	"res://Assets/CharacterModels/SheriffMoneyBags/Meshy_AI_Gentleman_Frog_in_Vel_biped/"
	+ "Meshy_AI_Gentleman_Frog_in_Vel_biped_Animation_Walking_frame_rate_60.fbx"
)
const IDLE_SCENE := RigAnimConfig.IDLE_SCENE
const WALK_SCENE := (
	"res://Assets/CharacterModels/SheriffMoneyBags/Meshy_AI_Gentleman_Frog_in_Vel_biped/"
	+ "Meshy_AI_Gentleman_Frog_in_Vel_biped_Animation_Walking_frame_rate_60.fbx"
)

const LOCOMOTION_LIBRARY := &"locomotion"
const LOCOMOTION_IDLE := &"idle"
const LOCOMOTION_WALK := &"walk"
