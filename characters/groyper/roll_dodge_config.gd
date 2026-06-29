class_name RollDodgeConfig
extends RefCounted

## Authored roll dodge clips for overworld movement.
## walk_roll lives in roll_dodge.tres; run_roll is a standalone run_roll.tres for editing.

const LIBRARY_NAME := &"roll_dodge"
const WALK_ROLL := &"walk_roll"
const RUN_ROLL := &"run_roll"

const OUT_PATH := "res://characters/groyper/roll_dodge.tres"
const RUN_ROLL_OUT_PATH := "res://characters/groyper/run_roll.tres"

const WALK_ROLL_SCENE := (
	"res://Assets/CharacterModels/Groyper/GroyperSDanimations/Meshy_AI_Emerald_Embrace_biped/"
	+ "Meshy_AI_Emerald_Embrace_biped_Animation_Roll_Dodge_1_frame_rate_60.fbx"
)
const RUN_ROLL_SCENE := (
	"res://Assets/CharacterModels/Groyper/GroyperSDanimations/Meshy_AI_Emerald_Embrace_biped/"
	+ "Meshy_AI_Emerald_Embrace_biped_Animation_Roll_Dodge_2_frame_rate_60.fbx"
)

const SOURCE_SCENES := {
	WALK_ROLL: WALK_ROLL_SCENE,
	RUN_ROLL: RUN_ROLL_SCENE,
}
