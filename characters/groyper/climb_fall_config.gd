class_name ClimbFallConfig
extends RefCounted

## Authored climb fall / long-fall loop / landing clips for overworld drops.

const LIBRARY_NAME := &"climb_fall"
const FALL_ENTRY := &"fall_entry"
const FALL_LOOP := &"fall_loop"
const FALL_LAND := &"fall_land"

const OUT_PATH := "res://characters/groyper/climb_fall.tres"

const GROYPER_ANIM_DIR := (
	"res://Assets/CharacterModels/Groyper/GroyperSDanimations/Meshy_AI_Emerald_Embrace_biped/"
)

const FALL_ENTRY_SCENE := (
	GROYPER_ANIM_DIR
	+ "Meshy_AI_Emerald_Embrace_biped_Animation_Fall2_frame_rate_60.fbx"
)
const FALL_LOOP_SCENE := (
	GROYPER_ANIM_DIR
	+ "Meshy_AI_Emerald_Embrace_biped_Animation_Fall1_frame_rate_60.fbx"
)

const CLIMB_MERGED_SCENE := (
	"res://Assets/CharacterModels/Groyper/GroyperSDanimations/Climb/"
	+ "Meshy_AI_Emerald_Embrace_biped/"
	+ "Meshy_AI_Emerald_Embrace_biped_Meshy_AI_Meshy_Merged_Animations.fbx"
)
const MESHY_FALL_LAND := &"Fall_from_Bar_frame_rate_60_fbx"

const BLEND_NODE := &"ClimbFallBlend"
const POSE_BLEND_NODE := &"ClimbFallPoseBlend"
const LAND_BLEND_NODE := &"ClimbFallLandBlend"
const FALL_ENTRY_ANIM_NODE := &"ClimbFallEntryAnim"
const FALL_ENTRY_TIME_SEEK := &"ClimbFallEntryTimeSeek"
const FALL_LOOP_ANIM_NODE := &"ClimbFallLoopAnim"
const FALL_LOOP_TIME_SEEK := &"ClimbFallLoopTimeSeek"
const FALL_LAND_ANIM_NODE := &"ClimbFallLandAnim"
const FALL_LAND_TIME_SEEK := &"ClimbFallLandTimeSeek"

enum Phase { NONE, FALL_ENTRY, FALL_LOOP, LAND, EXIT }


static func get_fall_entry_path() -> StringName:
	return StringName("%s/%s" % [LIBRARY_NAME, FALL_ENTRY])


static func get_fall_loop_path() -> StringName:
	return StringName("%s/%s" % [LIBRARY_NAME, FALL_LOOP])


static func get_fall_land_path() -> StringName:
	return StringName("%s/%s" % [LIBRARY_NAME, FALL_LAND])


static func set_master_blend(animation_tree: AnimationTree, amount: float) -> void:
	if animation_tree != null:
		animation_tree.set("parameters/%s/blend_amount" % BLEND_NODE, amount)


static func set_pose_blend(animation_tree: AnimationTree, amount: float) -> void:
	if animation_tree != null:
		animation_tree.set("parameters/%s/blend_amount" % POSE_BLEND_NODE, amount)


static func set_land_blend(animation_tree: AnimationTree, amount: float) -> void:
	if animation_tree != null:
		animation_tree.set("parameters/%s/blend_amount" % LAND_BLEND_NODE, amount)


static func set_fall_entry_seek(animation_tree: AnimationTree, time: float) -> void:
	if animation_tree != null:
		animation_tree.set("parameters/%s/seek_request" % FALL_ENTRY_TIME_SEEK, time)


static func set_fall_loop_seek(animation_tree: AnimationTree, time: float) -> void:
	if animation_tree != null:
		animation_tree.set("parameters/%s/seek_request" % FALL_LOOP_TIME_SEEK, time)


static func set_land_seek(animation_tree: AnimationTree, time: float) -> void:
	if animation_tree != null:
		animation_tree.set("parameters/%s/seek_request" % FALL_LAND_TIME_SEEK, time)
