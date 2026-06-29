class_name SheriffAnimConfig
extends RefCounted

## Meshy rig animation paths for Sheriff Money Bags.
## Idle uses the sheriff-specific Meshy clip; walk uses the shared Groyper biped clip.

const MESHY_CLIP_NAME := RigAnimConfig.MESHY_CLIP_NAME

const BODY_SCENE := (
	"res://Assets/CharacterModels/SheriffMoneyBags/Meshy_AI_Gentleman_Frog_in_Vel_biped/"
	+ "SheriffMoneyBags.fbx"
)
const IDLE_SCENE := (
	"res://Assets/CharacterModels/SheriffMoneyBags/Meshy_AI_Gentleman_Frog_in_Vel_biped/"
	+ "Meshy_AI_Dapper_Frog_in_a_Blue_biped_Animation_Idle_11_frame_rate_60.fbx"
)
const WALK_SCENE := RigAnimConfig.WALK_SCENE

const LOCOMOTION_LIBRARY := &"locomotion"
const LOCOMOTION_IDLE := &"idle"
const LOCOMOTION_WALK := &"walk"
