class_name LadderClimbConfig
extends RefCounted

## Authored ladder climb loop + top dismount clips.

const LIBRARY_NAME := &"ladder_climb"
const CLIMB_LOOP := &"ladder_climb_loop"
const CLIMB_FINISH := &"ladder_climb_finish"

const OUT_PATH := "res://characters/groyper/ladder_climb.tres"

const CLIMB_MERGED_SCENE := (
	"res://Assets/CharacterModels/Groyper/GroyperSDanimations/Climb/"
	+ "Meshy_AI_Emerald_Embrace_biped/"
	+ "Meshy_AI_Emerald_Embrace_biped_Meshy_AI_Meshy_Merged_Animations.fbx"
)
const MESHY_CLIMB_LOOP := &"Fast_Ladder_Climb_frame_rate_60_fbx"
const MESHY_CLIMB_FINISH := &"Ladder_Climb_Finish_frame_rate_60_fbx"

const BLEND_NODE := &"LadderClimbBlend"
const FINISH_BLEND_NODE := &"LadderFinishBlend"
const CLIMB_ANIM_NODE := &"LadderClimbAnim"
const CLIMB_TIME_SEEK := &"LadderClimbTimeSeek"
const CLIMB_TIME_SCALE := &"LadderClimbTimeScale"
const FINISH_ANIM_NODE := &"LadderFinishAnim"
const FINISH_TIME_SEEK := &"LadderFinishTimeSeek"
const FINISH_TIME_SCALE := &"LadderFinishTimeScale"

enum Phase { NONE, MOUNT, CLIMB, FINISH, EXIT }


static func get_climb_loop_path() -> StringName:
	return StringName("%s/%s" % [LIBRARY_NAME, CLIMB_LOOP])


static func get_climb_finish_path() -> StringName:
	return StringName("%s/%s" % [LIBRARY_NAME, CLIMB_FINISH])


static func set_master_blend(animation_tree: AnimationTree, amount: float) -> void:
	if animation_tree != null:
		animation_tree.set("parameters/%s/blend_amount" % BLEND_NODE, amount)


static func set_finish_blend(animation_tree: AnimationTree, amount: float) -> void:
	if animation_tree != null:
		animation_tree.set("parameters/%s/blend_amount" % FINISH_BLEND_NODE, amount)


static func set_climb_seek(animation_tree: AnimationTree, time: float) -> void:
	if animation_tree != null:
		animation_tree.set("parameters/%s/seek_request" % CLIMB_TIME_SEEK, time)


static func set_finish_seek(animation_tree: AnimationTree, time: float) -> void:
	if animation_tree != null:
		animation_tree.set("parameters/%s/seek_request" % FINISH_TIME_SEEK, time)


static func set_climb_playback_scale(animation_tree: AnimationTree, scale: float) -> void:
	if animation_tree != null:
		animation_tree.set("parameters/%s/scale" % CLIMB_TIME_SCALE, scale)


static func set_finish_playback_scale(animation_tree: AnimationTree, scale: float) -> void:
	if animation_tree != null:
		animation_tree.set("parameters/%s/scale" % FINISH_TIME_SCALE, scale)
