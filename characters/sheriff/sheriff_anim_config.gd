class_name SheriffAnimConfig
extends RefCounted

## Meshy rig animation paths for Sheriff Money Bags.
## Locomotion clips are Sheriff-specific Dapper Frog exports; draw/aim uses procedural
## GroyperWeaponRig IK (not Groyper lean/standup animations).

const MESHY_CLIP_NAME := RigAnimConfig.MESHY_CLIP_NAME

const ASSETS_ROOT := "res://Assets/CharacterModels/SheriffMoneyBags/"
const BODY_DIR := ASSETS_ROOT + "Meshy_AI_Gentleman_Frog_in_Vel_biped/"

const IDLE_SCENE := (
	ASSETS_ROOT
	+ "Meshy_AI_Dapper_Frog_in_a_Blue_biped_Animation_Idle_11_frame_rate_60.fbx"
)
## Meshy locomotion clips share one skeleton layout — use the idle FBX as the body rig
## (same pattern as groyper_body.tscn) and swap the gentleman albedo onto the mesh.
const BODY_SCENE := IDLE_SCENE
const GENTLEMAN_ALBEDO_TEXTURE := BODY_DIR + "SheriffMoneyBags_0.png"
const WALK_SCENE := (
	ASSETS_ROOT
	+ "Meshy_AI_Dapper_Frog_in_a_Blue_biped_Animation_Walking_frame_rate_60.fbx"
)

const LOCOMOTION_LIBRARY := &"locomotion"
const LOCOMOTION_IDLE := &"idle"
const LOCOMOTION_WALK := &"walk"
