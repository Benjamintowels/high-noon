extends SceneTree

const BODY_SCENE := "res://characters/groyper/groyper_body.tscn"
const SaddlePoseConfigScript := preload("res://characters/groyper/saddle_pose_config.gd")
const OUT_PATH := "res://characters/groyper/saddle.tres"


func _init() -> void:
	var err := _capture_from_body_scene()
	quit(0 if err == OK else 1)


func _capture_from_body_scene() -> Error:
	var body: Node = load(BODY_SCENE).instantiate()
	if body == null:
		push_error("SaddlePoseCaptureCLI: failed to load %s" % BODY_SCENE)
		return ERR_CANT_CREATE

	var skeleton := body.get_node_or_null("Armature/Skeleton3D") as Skeleton3D
	if skeleton == null:
		push_error("SaddlePoseCaptureCLI: missing Skeleton3D")
		return ERR_CANT_CREATE

	var animation := _build_pose_animation(skeleton)
	var library := AnimationLibrary.new()
	library.add_animation(SaddlePoseConfigScript.POSE_NAME, animation)

	var err := ResourceSaver.save(library, OUT_PATH)
	if err != OK:
		push_error("SaddlePoseCaptureCLI: failed to save %s (error %s)" % [OUT_PATH, err])
		return err

	print(
		"SaddlePoseCaptureCLI: saved %d bone tracks to %s"
		% [animation.get_track_count(), OUT_PATH]
	)
	return OK


func _build_pose_animation(skeleton: Skeleton3D) -> Animation:
	var animation := Animation.new()
	animation.length = 1.0
	animation.loop_mode = Animation.LOOP_LINEAR

	for bone_name: String in SaddlePoseConfigScript.AUTHORING_BONES:
		var bone_id := skeleton.find_bone(bone_name)
		if bone_id < 0:
			push_warning("SaddlePoseCaptureCLI: bone '%s' not found." % bone_name)
			continue

		var track := animation.add_track(Animation.TYPE_ROTATION_3D)
		animation.track_set_path(track, NodePath("Armature/Skeleton3D:%s" % bone_name))
		var rot := skeleton.get_bone_pose_rotation(bone_id)
		animation.rotation_track_insert_key(track, 0.0, rot)
		print("%s rot: %s" % [bone_name, rot])

	for bone_name: String in SaddlePoseConfigScript.AUTHORING_POSITION_BONES:
		var bone_id := skeleton.find_bone(bone_name)
		if bone_id < 0:
			push_warning("SaddlePoseCaptureCLI: bone '%s' not found." % bone_name)
			continue

		var track := animation.add_track(Animation.TYPE_POSITION_3D)
		animation.track_set_path(track, NodePath("Armature/Skeleton3D:%s" % bone_name))
		var pos := skeleton.get_bone_pose_position(bone_id)
		animation.position_track_insert_key(track, 0.0, pos)
		print("%s pos: %s" % [bone_name, pos])

	return animation
