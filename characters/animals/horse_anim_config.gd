class_name HorseAnimConfig
extends RefCounted

const RIGGED_FBX_SCENE := "res://Assets/Animals/horses/NewHorse/horse.fbx"
const RIGGED_SCENE := "res://characters/animals/horsey_rig.tscn"
const LIBRARY := &"horse"

const WALK_SOURCE_CLIP := &"Armature|Armature|Armature|ArmatureAction_002"
const BOW_SOURCE_CLIP := &"Armature|Armature|Armature|ArmatureAction_001"

const WALK_CLIP := &"walk"
const RUN_CLIP := &"run"
const BOW_CLIP := &"bow"
const IDLE_STAND_CLIP := &"idle"
## Legacy alias — standing idle used to share the bow clip name in early exports.
const IDLE_CLIP := &"idle"

const OUT_DIR := "res://characters/animals/anims/"
const IDLE_PATH := OUT_DIR + "horse_idle.tres"
const WALK_PATH := OUT_DIR + "horse_walk.tres"
const RUN_PATH := OUT_DIR + "horse_run.tres"
const BOW_PATH := OUT_DIR + "horse_bow.tres"
const LIB_PATH := OUT_DIR + "horse_anim_library.tres"

const WALK_SPEED_THRESHOLD := 0.08
const SPRINT_SPEED_THRESHOLD := 6.5

## Tuned so legacy mesh height (~9.16) * scale * Model(0.02) ~= 1.5m.
const RIGGED_MODEL_SCALE := 8.2


static func is_rigged_variant(variant_path: String) -> bool:
	return (
		variant_path == HorseAnimConfig.RIGGED_SCENE
		or variant_path == HorseAnimConfig.RIGGED_FBX_SCENE
		or variant_path.ends_with("horsey_rig.tscn")
		or variant_path.ends_with("NewHorse/horse.fbx")
	)


static func clip_path(clip_name: StringName) -> StringName:
	return StringName("%s/%s" % [LIBRARY, clip_name])
