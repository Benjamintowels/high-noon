class_name TcAnimUtils
extends RefCounted

const RigAnimUtilsScript := preload("res://characters/groyper/rig_anim_utils.gd")
const TcAnimConfigScript := preload("res://characters/tc/tc_anim_config.gd")

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
	return StringName("%s/%s" % [TcAnimConfigScript.LIBRARY, clip_name])


static func get_skeleton_track_path(bone_name: String) -> NodePath:
	return NodePath("%s%s" % [SKELETON_TRACK_PREFIX, bone_name])


static func configure_block_pose_blend(blend_node: AnimationNodeBlend2) -> void:
	blend_node.filter_enabled = true
	for bone_name: String in BLOCK_POSE_BONES:
		blend_node.set_filter_path(get_skeleton_track_path(bone_name), true)


static func load_merged_clip(
	meshy_clip: StringName,
	loop_mode: Animation.LoopMode,
	strip_root_motion: bool = true
) -> Animation:
	var raw := RigAnimUtilsScript.load_skeleton_animation(
		TcAnimConfigScript.MERGED_SCENE,
		meshy_clip
	)
	if raw == null:
		push_error("TcAnimUtils: failed to load clip '%s'." % meshy_clip)
		return null

	var animation := RigAnimUtilsScript.prepare_meshy_merged_clip(raw, false)
	if strip_root_motion:
		RigAnimUtilsScript.strip_root_motion(animation)
	animation.loop_mode = loop_mode
	if loop_mode == Animation.LOOP_LINEAR:
		RigAnimUtilsScript.seal_loop_endpoints(animation)
	return RigAnimUtilsScript.make_authored(animation)


static func bake_block_pose(
	meshy_clip: StringName = TcAnimConfigScript.MESHY_BLOCK1
) -> Animation:
	var block := load_merged_clip(meshy_clip, Animation.LOOP_NONE)
	if block == null:
		return null
	var pose := RigAnimUtilsScript.extract_pose_at_time(block, 0.0)
	pose.loop_mode = Animation.LOOP_NONE
	pose.resource_name = "block1"
	return RigAnimUtilsScript.make_authored(pose)


static func load_knockdown_clip(scene_path: String, resource_name: String) -> Animation:
	var animation := load_body_clip(scene_path, StringName(), Animation.LOOP_NONE)
	if animation != null:
		animation.resource_name = resource_name
	return animation


static func load_dance_clip() -> Animation:
	return load_body_clip(
		TcAnimConfigScript.HIP_HOP_DANCE_SCENE,
		TcAnimConfigScript.MESHY_HIP_HOP_DANCE,
		Animation.LOOP_NONE
	)


static func load_body_clip(
	scene_path: String,
	meshy_clip: StringName,
	loop_mode: Animation.LoopMode
) -> Animation:
	var raw := RigAnimUtilsScript.load_skeleton_animation(scene_path, meshy_clip)
	if raw == null:
		push_error("TcAnimUtils: failed to load clip '%s' from %s." % [meshy_clip, scene_path])
		return null

	var animation := RigAnimUtilsScript.prepare_for_body_player(raw, false)
	RigAnimUtilsScript.strip_root_motion(animation)
	animation.loop_mode = loop_mode
	if loop_mode == Animation.LOOP_LINEAR:
		RigAnimUtilsScript.seal_loop_endpoints(animation)
	return RigAnimUtilsScript.make_authored(animation)


static func bake_library() -> AnimationLibrary:
	var idle := load_merged_clip(TcAnimConfigScript.MESHY_IDLE, Animation.LOOP_LINEAR)
	var combat_idle := load_merged_clip(
		TcAnimConfigScript.MESHY_COMBAT_IDLE,
		Animation.LOOP_LINEAR
	)
	var walk := load_merged_clip(TcAnimConfigScript.MESHY_WALK, Animation.LOOP_LINEAR)
	var run := load_merged_clip(TcAnimConfigScript.MESHY_RUN, Animation.LOOP_LINEAR)
	var punch_forward := load_merged_clip(
		TcAnimConfigScript.MESHY_PUNCH_FORWARD,
		Animation.LOOP_NONE
	)
	var back_jump := load_merged_clip(TcAnimConfigScript.MESHY_BACK_JUMP, Animation.LOOP_NONE)
	var fall2 := load_merged_clip(TcAnimConfigScript.MESHY_FALL2, Animation.LOOP_NONE, false)
	var backflip_hooks := load_merged_clip(
		TcAnimConfigScript.MESHY_BACKFLIP_HOOKS,
		Animation.LOOP_NONE
	)
	var block1_pose := bake_block_pose()
	var block2 := load_merged_clip(TcAnimConfigScript.MESHY_BLOCK2, Animation.LOOP_NONE)
	var block3 := load_merged_clip(TcAnimConfigScript.MESHY_BLOCK3, Animation.LOOP_NONE)
	var block4 := load_merged_clip(TcAnimConfigScript.MESHY_BLOCK4, Animation.LOOP_NONE)
	var block5 := load_merged_clip(TcAnimConfigScript.MESHY_BLOCK5, Animation.LOOP_NONE)
	var face_punch_react := load_merged_clip(
		TcAnimConfigScript.MESHY_FACE_PUNCH_REACT,
		Animation.LOOP_NONE
	)
	var charge := load_merged_clip(TcAnimConfigScript.MESHY_CHARGE, Animation.LOOP_NONE)
	var run_fast := load_body_clip(
		TcAnimConfigScript.RUN_FAST_SCENE,
		TcAnimConfigScript.MESHY_RUN_FAST,
		Animation.LOOP_LINEAR
	)
	var wall_flip := load_body_clip(
		TcAnimConfigScript.WALL_FLIP_SCENE,
		TcAnimConfigScript.MESHY_WALL_FLIP,
		Animation.LOOP_NONE
	)
	var hip_hop_dance := load_dance_clip()

	if (
		idle == null
		or combat_idle == null
		or walk == null
		or run == null
		or punch_forward == null
		or back_jump == null
		or fall2 == null
		or backflip_hooks == null
		or block1_pose == null
		or block2 == null
		or block3 == null
		or block4 == null
		or block5 == null
		or face_punch_react == null
		or charge == null
		or run_fast == null
		or wall_flip == null
		or hip_hop_dance == null
	):
		push_error("TcAnimUtils: one or more clips failed to bake.")
		return null

	idle.resource_name = "idle"
	combat_idle.resource_name = "combat_idle"
	walk.resource_name = "walk"
	run.resource_name = "run"
	punch_forward.resource_name = "punch_forward"
	back_jump.resource_name = "back_jump"
	fall2.resource_name = "fall2"
	backflip_hooks.resource_name = "backflip_hooks"
	block2.resource_name = "block2"
	block3.resource_name = "block3"
	block4.resource_name = "block4"
	block5.resource_name = "block5"
	face_punch_react.resource_name = "face_punch_react"
	charge.resource_name = "charge"
	run_fast.resource_name = "run_fast"
	wall_flip.resource_name = "wall_flip"
	hip_hop_dance.resource_name = "hip_hop_dance"

	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(TcAnimConfigScript.OUT_DIR)
	)

	var paths := {
		TcAnimConfigScript.IDLE_PATH: idle,
		TcAnimConfigScript.COMBAT_IDLE_PATH: combat_idle,
		TcAnimConfigScript.WALK_PATH: walk,
		TcAnimConfigScript.RUN_PATH: run,
		TcAnimConfigScript.PUNCH_FORWARD_PATH: punch_forward,
		TcAnimConfigScript.BACK_JUMP_PATH: back_jump,
		TcAnimConfigScript.FALL2_PATH: fall2,
		TcAnimConfigScript.BACKFLIP_HOOKS_PATH: backflip_hooks,
		TcAnimConfigScript.BLOCK1_PATH: block1_pose,
		TcAnimConfigScript.BLOCK2_PATH: block2,
		TcAnimConfigScript.BLOCK3_PATH: block3,
		TcAnimConfigScript.BLOCK4_PATH: block4,
		TcAnimConfigScript.BLOCK5_PATH: block5,
		TcAnimConfigScript.FACE_PUNCH_REACT_PATH: face_punch_react,
		TcAnimConfigScript.CHARGE_PATH: charge,
		TcAnimConfigScript.RUN_FAST_PATH: run_fast,
		TcAnimConfigScript.WALL_FLIP_PATH: wall_flip,
		TcAnimConfigScript.HIP_HOP_DANCE_PATH: hip_hop_dance,
	}
	for path: String in paths:
		var err := ResourceSaver.save(paths[path], path)
		if err != OK:
			push_error("TcAnimUtils: failed to save %s (error %s)." % [path, err])
			return null

	var library := AnimationLibrary.new()
	library.add_animation(TcAnimConfigScript.CLIP_IDLE, load(TcAnimConfigScript.IDLE_PATH))
	library.add_animation(
		TcAnimConfigScript.CLIP_COMBAT_IDLE,
		load(TcAnimConfigScript.COMBAT_IDLE_PATH)
	)
	library.add_animation(TcAnimConfigScript.CLIP_WALK, load(TcAnimConfigScript.WALK_PATH))
	library.add_animation(TcAnimConfigScript.CLIP_RUN, load(TcAnimConfigScript.RUN_PATH))
	library.add_animation(
		TcAnimConfigScript.CLIP_PUNCH_FORWARD,
		load(TcAnimConfigScript.PUNCH_FORWARD_PATH)
	)
	library.add_animation(
		TcAnimConfigScript.CLIP_BACK_JUMP,
		load(TcAnimConfigScript.BACK_JUMP_PATH)
	)
	library.add_animation(TcAnimConfigScript.CLIP_FALL2, load(TcAnimConfigScript.FALL2_PATH))
	library.add_animation(
		TcAnimConfigScript.CLIP_BACKFLIP_HOOKS,
		load(TcAnimConfigScript.BACKFLIP_HOOKS_PATH)
	)
	library.add_animation(TcAnimConfigScript.CLIP_BLOCK1, load(TcAnimConfigScript.BLOCK1_PATH))
	library.add_animation(TcAnimConfigScript.CLIP_BLOCK2, load(TcAnimConfigScript.BLOCK2_PATH))
	library.add_animation(TcAnimConfigScript.CLIP_BLOCK3, load(TcAnimConfigScript.BLOCK3_PATH))
	library.add_animation(TcAnimConfigScript.CLIP_BLOCK4, load(TcAnimConfigScript.BLOCK4_PATH))
	library.add_animation(TcAnimConfigScript.CLIP_BLOCK5, load(TcAnimConfigScript.BLOCK5_PATH))
	library.add_animation(
		TcAnimConfigScript.CLIP_FACE_PUNCH_REACT,
		load(TcAnimConfigScript.FACE_PUNCH_REACT_PATH)
	)
	library.add_animation(TcAnimConfigScript.CLIP_CHARGE, load(TcAnimConfigScript.CHARGE_PATH))
	library.add_animation(TcAnimConfigScript.CLIP_RUN_FAST, load(TcAnimConfigScript.RUN_FAST_PATH))
	library.add_animation(TcAnimConfigScript.CLIP_WALL_FLIP, load(TcAnimConfigScript.WALL_FLIP_PATH))
	library.add_animation(
		TcAnimConfigScript.CLIP_HIP_HOP_DANCE,
		load(TcAnimConfigScript.HIP_HOP_DANCE_PATH)
	)

	var lib_err := ResourceSaver.save(library, TcAnimConfigScript.LIB_PATH)
	if lib_err != OK:
		push_error(
			"TcAnimUtils: failed to save %s (error %s)."
			% [TcAnimConfigScript.LIB_PATH, lib_err]
		)
		return null

	print("TcAnimUtils: baked tc animation library -> ", TcAnimConfigScript.LIB_PATH)
	return library
