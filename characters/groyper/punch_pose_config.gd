class_name PunchPoseConfig
extends RefCounted

## Punch clips — extracted from Meshy punch FBXs, or edit the .tres clips directly.
## AnimationPlayer library: Punch/punch, Punch/elbow_strike, Punch/double_combo.
##
## Hit timing: each clip uses Animation markers (`strike` / `strike_1` / `strike_2`).
## Open the .tres in the Animation editor, scrub, and drag markers to retune hits.
## Runtime reads those markers (defaults below if a marker is missing).
##
## IMPORTANT: capture writes to punch.tres only. Do not save bone overrides onto
## Skeleton3D in groyper_body.tscn — that distorts standing locomotion.

const LIBRARY_NAME := &"Punch"
const PUNCH := &"punch"
const ELBOW_STRIKE := &"elbow_strike"
const DOUBLE_COMBO := &"double_combo"

const PUNCH_CLIP_PATH := "res://characters/groyper/punch.tres"
const ELBOW_STRIKE_CLIP_PATH := "res://characters/groyper/elbow_strike.tres"
const DOUBLE_COMBO_CLIP_PATH := "res://characters/groyper/double_combo.tres"
const OUT_PATH := "res://characters/groyper/punch_pose.tres"

const PUNCH_SCENE := (
	"res://Assets/CharacterModels/Groyper/GroyperSDanimations/Meshy_AI_Emerald_Embrace_biped/"
	+ "Meshy_AI_Emerald_Embrace_biped_Animation_Right_Upper_Hook_from_Guard_frame_rate_60.fbx"
)
const ELBOW_STRIKE_SCENE := (
	"res://Assets/CharacterModels/Groyper/GroyperSDanimations/Meshy_AI_Emerald_Embrace_biped/"
	+ "Meshy_AI_Emerald_Embrace_biped_Animation_Elbow_Strike_frame_rate_60.fbx"
)
const DOUBLE_COMBO_SCENE := (
	"res://Assets/CharacterModels/Groyper/GroyperSDanimations/Meshy_AI_Emerald_Embrace_biped/"
	+ "Meshy_AI_Emerald_Embrace_biped_Animation_Double_Combo_Attack_frame_rate_60.fbx"
)

const SKELETON_TRACK_PREFIX := "Armature/Skeleton3D:"

const BLEND_NODE := &"PunchBlend"
## Dual punch slots + crossfade so combo clip swaps don't hard-snap.
const ANIM_NODE_A := &"PunchAnim"
const ANIM_NODE_B := &"PunchAnimB"
const TIME_SEEK_NODE := &"PunchTimeSeek"
const TIME_SEEK_NODE_B := &"PunchTimeSeekB"
const CROSS_BLEND_NODE := &"PunchCrossBlend"
## Wall-clock seconds to blend between combo hits (hook→elbow→double).
const COMBO_CROSSFADE := 0.08
## Anim-seconds after a strike before a buffered follow-up may begin.
const POST_STRIKE_HOLD := 0.12

## Animation marker names (visible / draggable in the Animation editor).
const MARKER_STRIKE := &"strike"
const MARKER_STRIKE_1 := &"strike_1"
const MARKER_STRIKE_2 := &"strike_2"

## Defaults used when a clip has no marker yet (also stamped on extract).
const DEFAULT_HOOK_STRIKE := 0.5
const DEFAULT_ELBOW_STRIKE_1 := 0.17
const DEFAULT_ELBOW_STRIKE_2 := 0.8
const DEFAULT_DOUBLE_STRIKE_1 := 0.55
const DEFAULT_DOUBLE_STRIKE_2 := 1.1

static var _timing_ready := false
static var _hook_strike := DEFAULT_HOOK_STRIKE
static var _elbow_strike_1 := DEFAULT_ELBOW_STRIKE_1
static var _elbow_strike_2 := DEFAULT_ELBOW_STRIKE_2
static var _double_strike_1 := DEFAULT_DOUBLE_STRIKE_1
static var _double_strike_2 := DEFAULT_DOUBLE_STRIKE_2


static func get_animation_path() -> StringName:
	return StringName("%s/%s" % [LIBRARY_NAME, PUNCH])


static func get_elbow_strike_path() -> StringName:
	return StringName("%s/%s" % [LIBRARY_NAME, ELBOW_STRIKE])


static func get_double_combo_path() -> StringName:
	return StringName("%s/%s" % [LIBRARY_NAME, DOUBLE_COMBO])


static func get_skeleton_track_path(bone_name: String) -> NodePath:
	return NodePath("%s%s" % [SKELETON_TRACK_PREFIX, bone_name])


static func configure_punch_blend_filter(blend_node: AnimationNodeBlend2) -> void:
	blend_node.filter_enabled = true
	for bone_name: String in PUNCH_BLEND_BONES:
		blend_node.set_filter_path(get_skeleton_track_path(bone_name), true)


static func set_tree_blend(animation_tree: AnimationTree, amount: float) -> void:
	if animation_tree != null:
		animation_tree.set("parameters/%s/blend_amount" % BLEND_NODE, amount)


static func set_tree_seek(animation_tree: AnimationTree, time: float) -> void:
	set_slot_seek(animation_tree, 0, time)


static func set_slot_seek(animation_tree: AnimationTree, slot: int, time: float) -> void:
	if animation_tree == null:
		return
	var seek_node := TIME_SEEK_NODE_B if slot == 1 else TIME_SEEK_NODE
	animation_tree.set("parameters/%s/seek_request" % seek_node, time)


static func set_cross_blend(animation_tree: AnimationTree, amount: float) -> void:
	if animation_tree != null:
		animation_tree.set("parameters/%s/blend_amount" % CROSS_BLEND_NODE, amount)


static func reload_strike_timing() -> void:
	_timing_ready = false
	ensure_strike_timing()


static func ensure_strike_timing() -> void:
	if _timing_ready:
		return
	_timing_ready = true
	_hook_strike = _read_marker_from_path(
		PUNCH_CLIP_PATH,
		MARKER_STRIKE,
		DEFAULT_HOOK_STRIKE
	)
	_elbow_strike_1 = _read_marker_from_path(
		ELBOW_STRIKE_CLIP_PATH,
		MARKER_STRIKE_1,
		DEFAULT_ELBOW_STRIKE_1
	)
	_elbow_strike_2 = _read_marker_from_path(
		ELBOW_STRIKE_CLIP_PATH,
		MARKER_STRIKE_2,
		DEFAULT_ELBOW_STRIKE_2
	)
	_double_strike_1 = _read_marker_from_path(
		DOUBLE_COMBO_CLIP_PATH,
		MARKER_STRIKE_1,
		DEFAULT_DOUBLE_STRIKE_1
	)
	_double_strike_2 = _read_marker_from_path(
		DOUBLE_COMBO_CLIP_PATH,
		MARKER_STRIKE_2,
		DEFAULT_DOUBLE_STRIKE_2
	)


static func get_hook_strike() -> float:
	ensure_strike_timing()
	return _hook_strike


static func get_elbow_strike_1() -> float:
	ensure_strike_timing()
	return _elbow_strike_1


static func get_elbow_strike_2() -> float:
	ensure_strike_timing()
	return _elbow_strike_2


static func get_double_strike_1() -> float:
	ensure_strike_timing()
	return _double_strike_1


static func get_double_strike_2() -> float:
	ensure_strike_timing()
	return _double_strike_2


## Ensure default strike markers exist without overwriting editor-tuned ones.
static func ensure_strike_markers(animation: Animation, clip_name: StringName) -> void:
	if animation == null:
		return
	var markers := _default_markers_for_clip(clip_name)
	for marker_name: StringName in markers.keys():
		if animation.has_marker(marker_name):
			continue
		animation.add_marker(marker_name, float(markers[marker_name]))


static func _default_markers_for_clip(clip_name: StringName) -> Dictionary:
	match clip_name:
		PUNCH:
			return {MARKER_STRIKE: DEFAULT_HOOK_STRIKE}
		ELBOW_STRIKE:
			return {
				MARKER_STRIKE_1: DEFAULT_ELBOW_STRIKE_1,
				MARKER_STRIKE_2: DEFAULT_ELBOW_STRIKE_2,
			}
		DOUBLE_COMBO:
			return {
				MARKER_STRIKE_1: DEFAULT_DOUBLE_STRIKE_1,
				MARKER_STRIKE_2: DEFAULT_DOUBLE_STRIKE_2,
			}
		_:
			return {}


static func _read_marker_from_path(path: String, marker_name: StringName, fallback: float) -> float:
	var animation := load(path) as Animation
	if animation == null:
		return fallback
	if animation.has_marker(marker_name):
		return animation.get_marker_time(marker_name)
	return fallback


## Upper body blended during punch — legs stay on locomotion.
const PUNCH_BLEND_BONES: Array[String] = [
	"Spine",
	"Spine01",
	"Spine02",
	"LeftShoulder",
	"LeftArm",
	"LeftForeArm",
	"LeftHand",
	"RightShoulder",
	"RightArm",
	"RightForeArm",
	"RightHand",
]

const AUTHORING_BONES: Array[String] = [
	"Hips",
	"Spine",
	"Spine01",
	"Spine02",
	"neck",
	"Head",
	"LeftShoulder",
	"LeftArm",
	"LeftForeArm",
	"LeftHand",
	"RightShoulder",
	"RightArm",
	"RightForeArm",
	"RightHand",
	"LeftUpLeg",
	"LeftLeg",
	"RightUpLeg",
	"RightLeg",
]

const AUTHORING_POSITION_BONES: Array[String] = [
	"Hips",
	"LeftUpLeg",
	"RightUpLeg",
]
