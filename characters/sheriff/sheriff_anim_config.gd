class_name SheriffAnimConfig
extends RefCounted

## Meshy rig animation paths for Sheriff Money Bags.
## Anim FBXs live at ASSETS_ROOT; mesh textures under Meshy_AI_Dapper_Frog_in_a_Blue_biped/.

const MESHY_CLIP_NAME := RigAnimConfig.MESHY_CLIP_NAME

const ASSETS_ROOT := "res://Assets/CharacterModels/SheriffMoneyBags/"
const BODY_DIR := ASSETS_ROOT + "Meshy_AI_Gentleman_Frog_in_Vel_biped/"

const BODY_SCENE := BODY_DIR + "SheriffMoneyBags.fbx"
const IDLE_SCENE := (
	ASSETS_ROOT
	+ "Meshy_AI_Dapper_Frog_in_a_Blue_biped_Animation_Idle_11_frame_rate_60.fbx"
)
const WALK_SCENE := (
	ASSETS_ROOT
	+ "Meshy_AI_Dapper_Frog_in_a_Blue_biped_Animation_Walking_frame_rate_60.fbx"
)

const LOCOMOTION_LIBRARY := &"locomotion"
const LOCOMOTION_IDLE := &"idle"
const LOCOMOTION_WALK := &"walk"
