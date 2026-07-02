class_name SkeletonAnimUtils
extends RefCounted

const RigAnimConfigScript := preload("res://characters/groyper/rig_anim_config.gd")
const RigAnimUtilsScript := preload("res://characters/groyper/rig_anim_utils.gd")

const SKELY_TRACK_PREFIX := "Armature_001/Skeleton3D:"
const GROYPER_TRACK_PREFIX := "Armature/Skeleton3D:"

const OUT_DIR := "res://characters/enemies/anims/"
const IDLE_PATH := OUT_DIR + "skeleton_idle.tres"
const WALK_PATH := OUT_DIR + "skeleton_walk.tres"
const ATTACK_PATH := OUT_DIR + "skeleton_attack.tres"
const LIB_PATH := OUT_DIR + "skeleton_anim_library.tres"

const PUNCH_SOURCE_PATH := "res://characters/groyper/punch.tres"

const GROYPER_BODY_SCENE := "res://characters/groyper/groyper_body.tscn"
const SKELY_SCENE := "res://Assets/World/RuinsGR/SkelyScenes/Skely.tscn"

static var _bone_retarget_cache: Dictionary = {}

## Groyper body bone -> Mixamo bone name on Skely (Godot import uses underscores).
const GROYPER_TO_SKELY_BONE := {
	"Hips": "mixamorig_Hips",
	"Spine": "mixamorig_Spine",
	"Spine01": "mixamorig_Spine1",
	"Spine02": "mixamorig_Spine2",
	"neck": "mixamorig_Neck",
	"Head": "mixamorig_Head",
	"LeftShoulder": "mixamorig_LeftShoulder",
	"LeftArm": "mixamorig_LeftArm",
	"LeftForeArm": "mixamorig_LeftForeArm",
	"LeftHand": "mixamorig_LeftHand",
	"RightShoulder": "mixamorig_RightShoulder",
	"RightArm": "mixamorig_RightArm",
	"RightForeArm": "mixamorig_RightForeArm",
	"RightHand": "mixamorig_RightHand",
	"LeftUpLeg": "mixamorig_LeftUpLeg",
	"LeftLeg": "mixamorig_LeftLeg",
	"RightUpLeg": "mixamorig_RightUpLeg",
	"RightLeg": "mixamorig_RightLeg",
	"LeftFoot": "mixamorig_LeftFoot",
	"RightFoot": "mixamorig_RightFoot",
	"LeftToeBase": "mixamorig_LeftToeBase",
	"RightToeBase": "mixamorig_RightToeBase",
}


static func skely_track_path(bone_name: String) -> NodePath:
	return NodePath("%s%s" % [SKELY_TRACK_PREFIX, bone_name])


static func groyper_bone_from_track_path(path: NodePath) -> String:
	var path_str := String(path)
	if not path_str.contains(":"):
		return ""
	return path_str.get_slice(":", 1)


static func is_groyper_skeleton_track(path: NodePath) -> bool:
	return String(path).begins_with(GROYPER_TRACK_PREFIX)


static func finalize_animation_length(animation: Animation) -> void:
	var max_time := 0.0
	for track_idx in animation.get_track_count():
		var key_count := animation.track_get_key_count(track_idx)
		if key_count <= 0:
			continue
		var last_time := animation.track_get_key_time(track_idx, key_count - 1)
		max_time = maxf(max_time, last_time)
	animation.length = maxf(max_time, 0.001)


static func retarget_groyper_animation(source: Animation, resource_name: String) -> Animation:
	if not _ensure_bone_retarget_cache():
		return null

	var retargeted := Animation.new()
	retargeted.resource_name = resource_name
	retargeted.length = source.length
	retargeted.loop_mode = source.loop_mode

	for track_idx in source.get_track_count():
		var track_path := source.track_get_path(track_idx)
		if not is_groyper_skeleton_track(track_path):
			continue

		var groyper_bone := groyper_bone_from_track_path(track_path)
		if not GROYPER_TO_SKELY_BONE.has(groyper_bone):
			continue

		var skely_bone: String = GROYPER_TO_SKELY_BONE[groyper_bone]
		var new_track_idx := retargeted.add_track(source.track_get_type(track_idx))
		retargeted.track_set_path(new_track_idx, skely_track_path(skely_bone))
		retargeted.track_set_interpolation_type(
			new_track_idx,
			source.track_get_interpolation_type(track_idx)
		)
		_copy_track_keys(source, track_idx, retargeted, new_track_idx, groyper_bone)

	RigAnimUtilsScript.make_authored(retargeted)
	finalize_animation_length(retargeted)
	return retargeted


static func _ensure_bone_retarget_cache() -> bool:
	if not _bone_retarget_cache.is_empty():
		return true

	var groyper: Node = load(GROYPER_BODY_SCENE).instantiate()
	var skely: Node = load(SKELY_SCENE).instantiate()
	var g_skel := _find_skeleton(groyper)
	var s_skel := _find_skeleton(skely)
	if g_skel == null or s_skel == null:
		groyper.free()
		skely.free()
		push_error("SkeletonAnimUtils: failed to load rig skeletons for retargeting.")
		return false

	for groyper_bone: String in GROYPER_TO_SKELY_BONE:
		var skely_bone: String = GROYPER_TO_SKELY_BONE[groyper_bone]
		var g_id := g_skel.find_bone(groyper_bone)
		var s_id := s_skel.find_bone(skely_bone)
		if g_id < 0 or s_id < 0:
			push_warning(
				"SkeletonAnimUtils: missing bone mapping %s -> %s" % [groyper_bone, skely_bone]
			)
			continue
		_bone_retarget_cache[groyper_bone] = {
			"g_rest": g_skel.get_bone_rest(g_id).basis.get_rotation_quaternion(),
			"s_rest": s_skel.get_bone_rest(s_id).basis.get_rotation_quaternion(),
		}

	groyper.free()
	skely.free()
	return true


static func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null


static func _retarget_rotation(groyper_bone: String, src_pose: Quaternion) -> Quaternion:
	var entry: Dictionary = _bone_retarget_cache[groyper_bone]
	var g_rest: Quaternion = entry["g_rest"]
	var s_rest: Quaternion = entry["s_rest"]
	return s_rest.inverse() * g_rest * src_pose


static func _copy_track_keys(
	source: Animation,
	source_idx: int,
	target: Animation,
	target_idx: int,
	groyper_bone: String = ""
) -> void:
	var track_type := source.track_get_type(source_idx)
	var key_count := source.track_get_key_count(source_idx)
	for key_idx in key_count:
		var time := source.track_get_key_time(source_idx, key_idx)
		var value = source.track_get_key_value(source_idx, key_idx)
		if track_type == Animation.TYPE_ROTATION_3D and not groyper_bone.is_empty():
			value = _retarget_rotation(groyper_bone, value as Quaternion)
		var transition := source.track_get_key_transition(source_idx, key_idx)
		var new_key_idx := target.track_insert_key(target_idx, time, value)
		target.track_set_key_transition(target_idx, new_key_idx, transition)


static func load_groyper_locomotion(scene_path: String) -> Animation:
	var raw := RigAnimUtilsScript.load_skeleton_animation(scene_path)
	if raw == null:
		return null
	var prepared := RigAnimUtilsScript.prepare_for_body_player(raw, false)
	RigAnimUtilsScript.strip_root_motion(prepared)
	prepared.loop_mode = Animation.LOOP_LINEAR
	return prepared


static func bake_idle() -> Animation:
	var source := load_groyper_locomotion(RigAnimConfigScript.IDLE_SCENE)
	if source == null:
		push_error("SkeletonAnimUtils: failed to load groyper idle.")
		return null
	return retarget_groyper_animation(source, "Idle")


static func bake_walk() -> Animation:
	var source := load_groyper_locomotion(RigAnimConfigScript.WALK_SCENE)
	if source == null:
		push_error("SkeletonAnimUtils: failed to load groyper walk.")
		return null
	return retarget_groyper_animation(source, "Walk")


static func bake_attack() -> Animation:
	if not ResourceLoader.exists(PUNCH_SOURCE_PATH):
		push_error("SkeletonAnimUtils: missing punch source at %s" % PUNCH_SOURCE_PATH)
		return null
	var source := load(PUNCH_SOURCE_PATH) as Animation
	if source == null:
		push_error("SkeletonAnimUtils: failed to load punch animation.")
		return null
	var attack := retarget_groyper_animation(source, "Attack")
	attack.loop_mode = Animation.LOOP_NONE
	return attack


static func bake_library() -> AnimationLibrary:
	var idle := bake_idle()
	var walk := bake_walk()
	var attack := bake_attack()
	if idle == null or walk == null or attack == null:
		return null

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	if ResourceSaver.save(idle, IDLE_PATH) != OK:
		push_error("SkeletonAnimUtils: failed to save %s" % IDLE_PATH)
		return null
	if ResourceSaver.save(walk, WALK_PATH) != OK:
		push_error("SkeletonAnimUtils: failed to save %s" % WALK_PATH)
		return null
	if ResourceSaver.save(attack, ATTACK_PATH) != OK:
		push_error("SkeletonAnimUtils: failed to save %s" % ATTACK_PATH)
		return null

	var library := AnimationLibrary.new()
	library.add_animation("Idle", load(IDLE_PATH) as Animation)
	library.add_animation("Walk", load(WALK_PATH) as Animation)
	library.add_animation("Attack", load(ATTACK_PATH) as Animation)

	if ResourceSaver.save(library, LIB_PATH) != OK:
		push_error("SkeletonAnimUtils: failed to save %s" % LIB_PATH)
		return null

	print(
		"SkeletonAnimUtils: baked Idle (%d tracks), Walk (%d tracks), Attack (%d tracks)"
		% [idle.get_track_count(), walk.get_track_count(), attack.get_track_count()]
	)
	return library
