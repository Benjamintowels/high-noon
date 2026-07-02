class_name BaldwinAnimUtils
extends RefCounted

const RigAnimUtilsScript := preload("res://characters/groyper/rig_anim_utils.gd")
const BaldwinAnimConfigScript := preload("res://characters/baldwin/baldwin_anim_config.gd")

const SKELETON_TRACK_PREFIX := "Armature/Skeleton3D:"

const BLOCK_POSE_BONES: Array[String] = [
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
	"LeftFoot",
	"LeftToeBase",
	"RightUpLeg",
	"RightLeg",
	"RightFoot",
	"RightToeBase",
]


static func clip_path(clip_name: StringName) -> StringName:
	return StringName("%s/%s" % [BaldwinAnimConfigScript.LIBRARY, clip_name])


static func get_skeleton_track_path(bone_name: String) -> NodePath:
	return NodePath("%s%s" % [SKELETON_TRACK_PREFIX, bone_name])


static func configure_block_hold_blend(blend_node: AnimationNodeBlend2) -> void:
	blend_node.filter_enabled = true
	for bone_name: String in BLOCK_POSE_BONES:
		blend_node.set_filter_path(get_skeleton_track_path(bone_name), true)


static func load_merged_clip(
	meshy_clip: StringName,
	loop_mode: Animation.LoopMode,
	strip_root_motion: bool = true
) -> Animation:
	var raw := _load_first_available_clip(meshy_clip)
	if raw == null:
		return null

	var animation := RigAnimUtilsScript.prepare_meshy_merged_clip(raw, false)
	if strip_root_motion:
		RigAnimUtilsScript.strip_root_motion(animation)
	animation.loop_mode = loop_mode
	return animation


static func _load_first_available_clip(meshy_clip: StringName) -> Animation:
	var candidates: Array[StringName] = [meshy_clip]
	var clip_text := String(meshy_clip)
	if not clip_text.ends_with("_frame_rate_60_fbx"):
		candidates.append(StringName("%s_frame_rate_60_fbx" % clip_text))
	if clip_text.ends_with("_frame_rate_60_fbx"):
		candidates.append(StringName(clip_text.trim_suffix("_frame_rate_60_fbx")))

	for candidate: StringName in candidates:
		var raw := RigAnimUtilsScript.load_skeleton_animation(
			BaldwinAnimConfigScript.MERGED_SCENE,
			candidate
		)
		if raw != null:
			return raw

	push_warning("BaldwinAnimUtils: failed to load clip '%s'." % meshy_clip)
	return null
