class_name UndeadAnimUtils
extends RefCounted

const RigAnimUtilsScript := preload("res://characters/groyper/rig_anim_utils.gd")
const UndeadAnimConfigScript := preload("res://characters/undead/undead_anim_config.gd")

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
	return StringName("%s/%s" % [UndeadAnimConfigScript.LIBRARY, clip_name])


static func get_skeleton_track_path(bone_name: String) -> NodePath:
	return NodePath("%s%s" % [SKELETON_TRACK_PREFIX, bone_name])


static func configure_block_pose_blend(blend_node: AnimationNodeBlend2) -> void:
	blend_node.filter_enabled = true
	for bone_name: String in BLOCK_POSE_BONES:
		blend_node.set_filter_path(get_skeleton_track_path(bone_name), true)


static func load_clip(
	scene_path: String,
	loop_mode: Animation.LoopMode,
	strip_root_motion: bool = true
) -> Animation:
	var raw := RigAnimUtilsScript.load_skeleton_animation(scene_path)
	if raw == null:
		push_error("UndeadAnimUtils: failed to load clip from '%s'." % scene_path)
		return null

	var animation := RigAnimUtilsScript.prepare_for_body_player(raw, false)
	if strip_root_motion:
		RigAnimUtilsScript.strip_root_motion(animation)
	animation.loop_mode = loop_mode
	if loop_mode == Animation.LOOP_LINEAR:
		RigAnimUtilsScript.seal_loop_endpoints(animation)
	return RigAnimUtilsScript.make_authored(animation)


static func bake_parry_pose(
	scene_path: String = UndeadAnimConfigScript.PARRY_SCENE
) -> Animation:
	var parry := load_clip(scene_path, Animation.LOOP_NONE)
	if parry == null:
		return null
	var pose := RigAnimUtilsScript.extract_pose_at_time(parry, 0.0)
	pose.loop_mode = Animation.LOOP_NONE
	pose.resource_name = "parry_pose"
	return RigAnimUtilsScript.make_authored(pose)


static func bake_library() -> AnimationLibrary:
	var idle := load_clip(UndeadAnimConfigScript.IDLE_SCENE, Animation.LOOP_LINEAR)
	var combat_idle := load_clip(UndeadAnimConfigScript.COMBAT_IDLE_SCENE, Animation.LOOP_LINEAR)
	var walk := load_clip(UndeadAnimConfigScript.WALK_SCENE, Animation.LOOP_LINEAR)
	var run := load_clip(UndeadAnimConfigScript.RUN_SCENE, Animation.LOOP_LINEAR)
	var sword_slash := load_clip(UndeadAnimConfigScript.SWORD_SLASH_SCENE, Animation.LOOP_NONE)
	var charged_upward := load_clip(UndeadAnimConfigScript.CHARGED_UPWARD_SCENE, Animation.LOOP_NONE)
	var sprint_spin := load_clip(UndeadAnimConfigScript.SPRINT_SPIN_SCENE, Animation.LOOP_NONE)
	var parry_backward := load_clip(UndeadAnimConfigScript.PARRY_BACKWARD_SCENE, Animation.LOOP_NONE)
	var roll_dodge := load_clip(UndeadAnimConfigScript.ROLL_SCENE, Animation.LOOP_NONE)
	var parry_pose := bake_parry_pose()

	if (
		idle == null
		or combat_idle == null
		or walk == null
		or run == null
		or sword_slash == null
		or charged_upward == null
		or sprint_spin == null
		or parry_backward == null
		or roll_dodge == null
		or parry_pose == null
	):
		push_error("UndeadAnimUtils: one or more clips failed to bake.")
		return null

	idle.resource_name = "idle"
	combat_idle.resource_name = "combat_idle"
	walk.resource_name = "walk"
	run.resource_name = "run"
	sword_slash.resource_name = "sword_slash"
	charged_upward.resource_name = "charged_upward"
	sprint_spin.resource_name = "sprint_spin"
	parry_backward.resource_name = "parry_backward"
	roll_dodge.resource_name = "roll_dodge"

	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(UndeadAnimConfigScript.OUT_DIR)
	)

	var paths := {
		UndeadAnimConfigScript.IDLE_PATH: idle,
		UndeadAnimConfigScript.COMBAT_IDLE_PATH: combat_idle,
		UndeadAnimConfigScript.WALK_PATH: walk,
		UndeadAnimConfigScript.RUN_PATH: run,
		UndeadAnimConfigScript.SWORD_SLASH_PATH: sword_slash,
		UndeadAnimConfigScript.CHARGED_UPWARD_PATH: charged_upward,
		UndeadAnimConfigScript.SPRINT_SPIN_PATH: sprint_spin,
		UndeadAnimConfigScript.PARRY_POSE_PATH: parry_pose,
		UndeadAnimConfigScript.PARRY_BACKWARD_PATH: parry_backward,
		UndeadAnimConfigScript.ROLL_DODGE_PATH: roll_dodge,
	}
	for path: String in paths:
		var err := ResourceSaver.save(paths[path], path)
		if err != OK:
			push_error("UndeadAnimUtils: failed to save %s (error %s)." % [path, err])
			return null

	var library := AnimationLibrary.new()
	library.add_animation(UndeadAnimConfigScript.CLIP_IDLE, load(UndeadAnimConfigScript.IDLE_PATH))
	library.add_animation(
		UndeadAnimConfigScript.CLIP_COMBAT_IDLE,
		load(UndeadAnimConfigScript.COMBAT_IDLE_PATH)
	)
	library.add_animation(UndeadAnimConfigScript.CLIP_WALK, load(UndeadAnimConfigScript.WALK_PATH))
	library.add_animation(UndeadAnimConfigScript.CLIP_RUN, load(UndeadAnimConfigScript.RUN_PATH))
	library.add_animation(
		UndeadAnimConfigScript.CLIP_SWORD_SLASH,
		load(UndeadAnimConfigScript.SWORD_SLASH_PATH)
	)
	library.add_animation(
		UndeadAnimConfigScript.CLIP_CHARGED_UPWARD,
		load(UndeadAnimConfigScript.CHARGED_UPWARD_PATH)
	)
	library.add_animation(
		UndeadAnimConfigScript.CLIP_SPRINT_SPIN,
		load(UndeadAnimConfigScript.SPRINT_SPIN_PATH)
	)
	library.add_animation(
		UndeadAnimConfigScript.CLIP_PARRY_POSE,
		load(UndeadAnimConfigScript.PARRY_POSE_PATH)
	)
	library.add_animation(
		UndeadAnimConfigScript.CLIP_PARRY_BACKWARD,
		load(UndeadAnimConfigScript.PARRY_BACKWARD_PATH)
	)
	library.add_animation(
		UndeadAnimConfigScript.CLIP_ROLL_DODGE,
		load(UndeadAnimConfigScript.ROLL_DODGE_PATH)
	)

	var lib_err := ResourceSaver.save(library, UndeadAnimConfigScript.LIB_PATH)
	if lib_err != OK:
		push_error(
			"UndeadAnimUtils: failed to save %s (error %s)."
			% [UndeadAnimConfigScript.LIB_PATH, lib_err]
		)
		return null

	print("UndeadAnimUtils: baked undead animation library -> ", UndeadAnimConfigScript.LIB_PATH)
	return library
