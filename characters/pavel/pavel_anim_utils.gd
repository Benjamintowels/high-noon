class_name PavelAnimUtils
extends RefCounted

const RigAnimUtilsScript := preload("res://characters/groyper/rig_anim_utils.gd")
const PavelAnimConfigScript := preload("res://characters/pavel/pavel_anim_config.gd")

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
	return StringName("%s/%s" % [PavelAnimConfigScript.LIBRARY, clip_name])


static func get_skeleton_track_path(bone_name: String) -> NodePath:
	return NodePath("%s%s" % [SKELETON_TRACK_PREFIX, bone_name])


static func configure_block_pose_blend(blend_node: AnimationNodeBlend2) -> void:
	blend_node.filter_enabled = true
	for bone_name: String in BLOCK_POSE_BONES:
		blend_node.set_filter_path(get_skeleton_track_path(bone_name), true)


static func load_merged_clip(
	meshy_clip: StringName,
	loop_mode: Animation.LoopMode,
	strip_root_motion: bool = true,
	scene_path: String = PavelAnimConfigScript.MERGED_SCENE
) -> Animation:
	var raw := _load_raw_clip(scene_path, meshy_clip)
	if raw == null:
		return null

	var animation := RigAnimUtilsScript.prepare_meshy_merged_clip(raw, false)
	if strip_root_motion:
		RigAnimUtilsScript.strip_root_motion(animation)
	animation.loop_mode = loop_mode
	if loop_mode == Animation.LOOP_LINEAR:
		RigAnimUtilsScript.seal_loop_endpoints(animation)
	return RigAnimUtilsScript.make_authored(animation)


static func load_mage_spell_clip() -> Animation:
	return load_merged_clip(
		PavelAnimConfigScript.MESHY_MAGE_SPELL,
		Animation.LOOP_NONE,
		true,
		PavelAnimConfigScript.MERGED_SCENE
	)


static func bake_parry_pose(
	meshy_clip: StringName = PavelAnimConfigScript.MESHY_SWORD_PARRY,
	scene_path: String = PavelAnimConfigScript.PARRY_SCENE
) -> Animation:
	var parry := load_merged_clip(
		meshy_clip,
		Animation.LOOP_NONE,
		true,
		scene_path
	)
	if parry == null:
		return null
	var pose := RigAnimUtilsScript.extract_pose_at_time(parry, 0.0)
	pose.loop_mode = Animation.LOOP_NONE
	pose.resource_name = "parry_pose"
	return RigAnimUtilsScript.make_authored(pose)


static func bake_library() -> AnimationLibrary:
	var idle := load_merged_clip(
		PavelAnimConfigScript.MESHY_IDLE,
		Animation.LOOP_LINEAR,
		true,
		PavelAnimConfigScript.IDLE_SCENE
	)
	var walk := load_merged_clip(
		PavelAnimConfigScript.MESHY_WALK,
		Animation.LOOP_LINEAR
	)
	var run := load_merged_clip(
		PavelAnimConfigScript.MESHY_RUN,
		Animation.LOOP_LINEAR
	)
	var parry_backward := load_merged_clip(
		PavelAnimConfigScript.MESHY_SWORD_PARRY_BACKWARD,
		Animation.LOOP_NONE
	)
	var roll_dodge := load_merged_clip(
		PavelAnimConfigScript.MESHY_ROLL_DODGE,
		Animation.LOOP_NONE,
		true,
		PavelAnimConfigScript.ROLL_SCENE
	)
	var mage_spell := load_mage_spell_clip()
	var parry_pose := bake_parry_pose()

	if (
		idle == null
		or walk == null
		or run == null
		or parry_backward == null
		or roll_dodge == null
		or mage_spell == null
		or parry_pose == null
	):
		push_error("PavelAnimUtils: one or more clips failed to bake.")
		return null

	idle.resource_name = "idle"
	walk.resource_name = "walk"
	run.resource_name = "run"
	parry_backward.resource_name = "parry_backward"
	roll_dodge.resource_name = "roll_dodge"
	mage_spell.resource_name = "mage_spell"

	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(PavelAnimConfigScript.OUT_DIR)
	)

	var paths := {
		PavelAnimConfigScript.IDLE_PATH: idle,
		PavelAnimConfigScript.WALK_PATH: walk,
		PavelAnimConfigScript.RUN_PATH: run,
		PavelAnimConfigScript.PARRY_POSE_PATH: parry_pose,
		PavelAnimConfigScript.PARRY_BACKWARD_PATH: parry_backward,
		PavelAnimConfigScript.ROLL_DODGE_PATH: roll_dodge,
		PavelAnimConfigScript.MAGE_SPELL_PATH: mage_spell,
	}
	for path: String in paths:
		var err := ResourceSaver.save(paths[path], path)
		if err != OK:
			push_error("PavelAnimUtils: failed to save %s (error %s)." % [path, err])
			return null

	var library := AnimationLibrary.new()
	library.add_animation(PavelAnimConfigScript.CLIP_IDLE, load(PavelAnimConfigScript.IDLE_PATH))
	library.add_animation(PavelAnimConfigScript.CLIP_WALK, load(PavelAnimConfigScript.WALK_PATH))
	library.add_animation(PavelAnimConfigScript.CLIP_RUN, load(PavelAnimConfigScript.RUN_PATH))
	library.add_animation(
		PavelAnimConfigScript.CLIP_PARRY_POSE,
		load(PavelAnimConfigScript.PARRY_POSE_PATH)
	)
	library.add_animation(
		PavelAnimConfigScript.CLIP_PARRY_BACKWARD,
		load(PavelAnimConfigScript.PARRY_BACKWARD_PATH)
	)
	library.add_animation(
		PavelAnimConfigScript.CLIP_ROLL_DODGE,
		load(PavelAnimConfigScript.ROLL_DODGE_PATH)
	)
	library.add_animation(
		PavelAnimConfigScript.CLIP_MAGE_SPELL,
		load(PavelAnimConfigScript.MAGE_SPELL_PATH)
	)

	var lib_err := ResourceSaver.save(library, PavelAnimConfigScript.LIB_PATH)
	if lib_err != OK:
		push_error(
			"PavelAnimUtils: failed to save %s (error %s)."
			% [PavelAnimConfigScript.LIB_PATH, lib_err]
		)
		return null

	print("PavelAnimUtils: baked pavel animation library -> ", PavelAnimConfigScript.LIB_PATH)
	return library


static func _load_raw_clip(scene_path: String, meshy_clip: StringName) -> Animation:
	var scene: PackedScene = load(scene_path)
	if scene == null:
		push_error("PavelAnimUtils: failed to load scene '%s'." % scene_path)
		return null

	var instance := scene.instantiate()
	var player := RigAnimUtilsScript.find_animation_player(instance)
	if player == null:
		instance.free()
		push_error("PavelAnimUtils: no AnimationPlayer in '%s'." % scene_path)
		return null

	if not RigAnimUtilsScript.player_has_clip(player, meshy_clip):
		var available := RigAnimUtilsScript.collect_animation_names(player)
		instance.free()
		push_error(
			"PavelAnimUtils: clip '%s' not found in '%s' (have %s)."
			% [meshy_clip, scene_path, available]
		)
		return null

	var resolved_name := RigAnimUtilsScript.resolve_animation_name(player, meshy_clip)
	var animation := player.get_animation(resolved_name).duplicate(true)
	instance.free()
	return animation


static func _player_has_clip(player: AnimationPlayer, meshy_clip: StringName) -> bool:
	return RigAnimUtilsScript.player_has_clip(player, meshy_clip)
