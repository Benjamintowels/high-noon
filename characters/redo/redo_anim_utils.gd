class_name RedoAnimUtils
extends RefCounted

const RigAnimUtilsScript := preload("res://characters/groyper/rig_anim_utils.gd")
const RedoAnimConfigScript := preload("res://characters/redo/redo_anim_config.gd")

const SKELETON_TRACK_PREFIX := "Armature/Skeleton3D:"

## Full-body sword block pose — same Meshy biped chain as other authored overlays.
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
	return StringName("%s/%s" % [RedoAnimConfigScript.LIBRARY, clip_name])


static func get_skeleton_track_path(bone_name: String) -> NodePath:
	return NodePath("%s%s" % [SKELETON_TRACK_PREFIX, bone_name])


static func configure_block_pose_blend(blend_node: AnimationNodeBlend2) -> void:
	blend_node.filter_enabled = true
	for bone_name: String in BLOCK_POSE_BONES:
		blend_node.set_filter_path(get_skeleton_track_path(bone_name), true)


static func load_mage_spell_clip() -> Animation:
	var raw := RigAnimUtilsScript.load_skeleton_animation(
		RedoAnimConfigScript.MAGE_SPELL_SCENE,
		RedoAnimConfigScript.MESHY_MAGE_SPELL
	)
	if raw == null:
		push_error("RedoAnimUtils: failed to load mage spell clip.")
		return null

	var animation := RigAnimUtilsScript.prepare_meshy_merged_clip(raw, false)
	RigAnimUtilsScript.strip_root_motion(animation)
	animation.loop_mode = Animation.LOOP_NONE
	return RigAnimUtilsScript.make_authored(animation)


static func load_merged_clip(
	meshy_clip: StringName,
	loop_mode: Animation.LoopMode,
	strip_root_motion: bool = true
) -> Animation:
	var raw := RigAnimUtilsScript.load_skeleton_animation(
		RedoAnimConfigScript.MERGED_SCENE,
		meshy_clip
	)
	if raw == null:
		push_error("RedoAnimUtils: failed to load clip '%s'." % meshy_clip)
		return null

	var animation := RigAnimUtilsScript.prepare_meshy_merged_clip(raw, false)
	if strip_root_motion:
		RigAnimUtilsScript.strip_root_motion(animation)
	animation.loop_mode = loop_mode
	return RigAnimUtilsScript.make_authored(animation)


static func bake_parry_pose(
	meshy_clip: StringName = RedoAnimConfigScript.MESHY_SWORD_PARRY
) -> Animation:
	var parry := load_merged_clip(
		meshy_clip,
		Animation.LOOP_NONE,
		true
	)
	if parry == null:
		return null
	var pose := RigAnimUtilsScript.extract_pose_at_time(parry, 0.0)
	pose.loop_mode = Animation.LOOP_NONE
	pose.resource_name = "parry_pose"
	return RigAnimUtilsScript.make_authored(pose)


static func bake_library() -> AnimationLibrary:
	var idle := load_merged_clip(
		RedoAnimConfigScript.MESHY_IDLE,
		Animation.LOOP_LINEAR
	)
	var walk := load_merged_clip(
		RedoAnimConfigScript.MESHY_WALK,
		Animation.LOOP_LINEAR
	)
	var run := load_merged_clip(
		RedoAnimConfigScript.MESHY_RUN,
		Animation.LOOP_LINEAR
	)
	var heavy_hammer := load_merged_clip(
		RedoAnimConfigScript.MESHY_HEAVY_HAMMER,
		Animation.LOOP_NONE
	)
	var parry_backward := load_merged_clip(
		RedoAnimConfigScript.MESHY_SWORD_PARRY_BACKWARD,
		Animation.LOOP_NONE
	)
	var roll_dodge := load_merged_clip(
		RedoAnimConfigScript.MESHY_ROLL_DODGE,
		Animation.LOOP_NONE
	)
	var mage_spell := load_mage_spell_clip()
	var parry_pose := bake_parry_pose()

	if (
		idle == null
		or walk == null
		or run == null
		or heavy_hammer == null
		or parry_backward == null
		or roll_dodge == null
		or mage_spell == null
		or parry_pose == null
	):
		push_error("RedoAnimUtils: one or more clips failed to bake.")
		return null

	idle.resource_name = "idle"
	walk.resource_name = "walk"
	run.resource_name = "run"
	heavy_hammer.resource_name = "heavy_hammer"
	parry_backward.resource_name = "parry_backward"
	roll_dodge.resource_name = "roll_dodge"
	mage_spell.resource_name = "mage_spell"

	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(RedoAnimConfigScript.OUT_DIR)
	)

	var paths := {
		RedoAnimConfigScript.IDLE_PATH: idle,
		RedoAnimConfigScript.WALK_PATH: walk,
		RedoAnimConfigScript.RUN_PATH: run,
		RedoAnimConfigScript.HEAVY_HAMMER_PATH: heavy_hammer,
		RedoAnimConfigScript.PARRY_POSE_PATH: parry_pose,
		RedoAnimConfigScript.PARRY_BACKWARD_PATH: parry_backward,
		RedoAnimConfigScript.ROLL_DODGE_PATH: roll_dodge,
		RedoAnimConfigScript.MAGE_SPELL_PATH: mage_spell,
	}
	for path: String in paths:
		var err := ResourceSaver.save(paths[path], path)
		if err != OK:
			push_error("RedoAnimUtils: failed to save %s (error %s)." % [path, err])
			return null

	var library := AnimationLibrary.new()
	library.add_animation(RedoAnimConfigScript.CLIP_IDLE, load(RedoAnimConfigScript.IDLE_PATH))
	library.add_animation(RedoAnimConfigScript.CLIP_WALK, load(RedoAnimConfigScript.WALK_PATH))
	library.add_animation(RedoAnimConfigScript.CLIP_RUN, load(RedoAnimConfigScript.RUN_PATH))
	library.add_animation(
		RedoAnimConfigScript.CLIP_HEAVY_HAMMER,
		load(RedoAnimConfigScript.HEAVY_HAMMER_PATH)
	)
	library.add_animation(
		RedoAnimConfigScript.CLIP_PARRY_POSE,
		load(RedoAnimConfigScript.PARRY_POSE_PATH)
	)
	library.add_animation(
		RedoAnimConfigScript.CLIP_PARRY_BACKWARD,
		load(RedoAnimConfigScript.PARRY_BACKWARD_PATH)
	)
	library.add_animation(
		RedoAnimConfigScript.CLIP_ROLL_DODGE,
		load(RedoAnimConfigScript.ROLL_DODGE_PATH)
	)
	library.add_animation(
		RedoAnimConfigScript.CLIP_MAGE_SPELL,
		load(RedoAnimConfigScript.MAGE_SPELL_PATH)
	)

	var lib_err := ResourceSaver.save(library, RedoAnimConfigScript.LIB_PATH)
	if lib_err != OK:
		push_error(
			"RedoAnimUtils: failed to save %s (error %s)."
			% [RedoAnimConfigScript.LIB_PATH, lib_err]
		)
		return null

	print("RedoAnimUtils: baked redo animation library -> ", RedoAnimConfigScript.LIB_PATH)
	return library
