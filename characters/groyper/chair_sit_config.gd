class_name ChairSitConfig
extends RefCounted

## Chair sitting clips — merged Meshy FBX with stand<->sit transitions and
## three sitting idles, shared by the player and town NPCs.

const MERGED_SCENE := (
	"res://Assets/CharacterModels/Groyper/GroyperSDanimations/Meshy_AI_Emerald_Embrace_biped/"
	+ "Meshy_AI_Emerald_Embrace_biped_Meshy_AI_Meshy_Merged_Animations.fbx"
)

## Clip names as imported from the merged FBX (note the _fbx suffix).
const SOURCE_STAND_TO_SIT := "Stand_to_Sit_Transition_M_frame_rate_60_fbx"
const SOURCE_SIT_TO_STANDS: Array[String] = [
	"Sit_to_Stand_Transition_M_frame_rate_60_fbx",
	"Sit_to_standTransition_Female_2_frame_rate_60_fbx",
]
const SOURCE_SIT_IDLES: Array[String] = [
	"Sit_and_Doze_Off_frame_rate_60_fbx",
	"Sit_and_Drink_frame_rate_60_fbx",
	"Sitting_Answering_Questions_frame_rate_60_fbx",
]

const LIBRARY_NAME := &"chair_sit"
const STAND_TO_SIT := &"stand_to_sit"
const SIT_TO_STAND_PREFIX := "sit_to_stand_"
const SIT_IDLE_PREFIX := "sit_idle_"

const SEAT_ALIGN_DURATION := 0.3


static func get_stand_to_sit_path() -> StringName:
	return StringName("%s/%s" % [LIBRARY_NAME, STAND_TO_SIT])


static func get_random_sit_to_stand_path() -> StringName:
	var index := randi() % SOURCE_SIT_TO_STANDS.size()
	return StringName("%s/%s%d" % [LIBRARY_NAME, SIT_TO_STAND_PREFIX, index])


static func get_random_sit_idle_path() -> StringName:
	var index := randi() % SOURCE_SIT_IDLES.size()
	return StringName("%s/%s%d" % [LIBRARY_NAME, SIT_IDLE_PREFIX, index])


## Builds the chair_sit AnimationLibrary and installs it on the given player.
## Returns true when every clip loaded. Uses the shared NPC anim cache so
## repeated installs (town NPCs / bandits) don't re-extract the merged FBX.
static func install_library(animation_player: AnimationPlayer) -> bool:
	var NpcAnimCache := load("res://characters/groyper/groyper_npc_anim_cache.gd") as GDScript
	if NpcAnimCache != null:
		return bool(NpcAnimCache.call("install_chair_sit", animation_player))
	if animation_player == null:
		return false

	var library := AnimationLibrary.new()
	var all_ok := _add_clip(library, STAND_TO_SIT, SOURCE_STAND_TO_SIT, Animation.LOOP_NONE)
	for i in SOURCE_SIT_TO_STANDS.size():
		var clip_name := StringName("%s%d" % [SIT_TO_STAND_PREFIX, i])
		all_ok = _add_clip(library, clip_name, SOURCE_SIT_TO_STANDS[i], Animation.LOOP_NONE) and all_ok
	for i in SOURCE_SIT_IDLES.size():
		var clip_name := StringName("%s%d" % [SIT_IDLE_PREFIX, i])
		all_ok = _add_clip(library, clip_name, SOURCE_SIT_IDLES[i], Animation.LOOP_LINEAR) and all_ok

	if animation_player.has_animation_library(LIBRARY_NAME):
		animation_player.remove_animation_library(LIBRARY_NAME)
	animation_player.add_animation_library(LIBRARY_NAME, library)
	return all_ok


static func _add_clip(
	library: AnimationLibrary,
	clip_name: StringName,
	source_clip: String,
	loop_mode: Animation.LoopMode
) -> bool:
	var raw := RigAnimUtils.load_skeleton_animation(MERGED_SCENE, source_clip)
	if raw == null:
		push_error("ChairSitConfig: failed to load clip '%s' from merged FBX." % source_clip)
		return false
	var animation := RigAnimUtils.prepare_meshy_merged_clip(raw, false)
	animation.loop_mode = loop_mode
	library.add_animation(clip_name, animation)
	return true
