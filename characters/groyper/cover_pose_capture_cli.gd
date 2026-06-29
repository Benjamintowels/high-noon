extends SceneTree

const BODY_SCENE := "res://characters/groyper/groyper_body.tscn"
const CoverPoseConfigScript := preload("res://characters/groyper/cover_pose_config.gd")


func _init() -> void:
	var err := _capture_from_body_scene()
	quit(0 if err == OK else 1)


func _capture_from_body_scene() -> Error:
	var body: Node = load(BODY_SCENE).instantiate()
	if body == null:
		push_error("CoverPoseCaptureCLI: failed to load %s" % BODY_SCENE)
		return ERR_CANT_CREATE

	var skeleton := body.get_node_or_null("Armature/Skeleton3D") as Skeleton3D
	if skeleton == null:
		push_error("CoverPoseCaptureCLI: missing Skeleton3D")
		return ERR_CANT_CREATE

	var animation := _build_pose_animation(skeleton)
	var library := load(CoverPoseConfigScript.OUT_PATH) as AnimationLibrary
	if library == null:
		library = AnimationLibrary.new()

	if library.has_animation(CoverPoseConfigScript.CROUCH_COVER):
		library.remove_animation(CoverPoseConfigScript.CROUCH_COVER)
	library.add_animation(CoverPoseConfigScript.CROUCH_COVER, animation)

	var err := ResourceSaver.save(library, CoverPoseConfigScript.OUT_PATH)
	if err != OK:
		push_error("CoverPoseCaptureCLI: failed to save %s (error %s)" % [CoverPoseConfigScript.OUT_PATH, err])
		return err

	print(
		"CoverPoseCaptureCLI: saved %d bone tracks to %s/%s"
		% [animation.get_track_count(), CoverPoseConfigScript.OUT_PATH, CoverPoseConfigScript.CROUCH_COVER]
	)
	return OK


func _build_pose_animation(skeleton: Skeleton3D) -> Animation:
	var animation := Animation.new()
	animation.length = 1.0
	animation.loop_mode = Animation.LOOP_LINEAR

	for bone_name: String in CoverPoseConfigScript.AUTHORING_BONES:
		var bone_id := skeleton.find_bone(bone_name)
		if bone_id < 0:
			push_warning("CoverPoseCaptureCLI: bone '%s' not found." % bone_name)
			continue

		var track := animation.add_track(Animation.TYPE_ROTATION_3D)
		animation.track_set_path(track, NodePath("Armature/Skeleton3D:%s" % bone_name))
		animation.rotation_track_insert_key(track, 0.0, skeleton.get_bone_pose_rotation(bone_id))

	for bone_name: String in CoverPoseConfigScript.AUTHORING_POSITION_BONES:
		var bone_id := skeleton.find_bone(bone_name)
		if bone_id < 0:
			push_warning("CoverPoseCaptureCLI: bone '%s' not found." % bone_name)
			continue

		var track := animation.add_track(Animation.TYPE_POSITION_3D)
		animation.track_set_path(track, NodePath("Armature/Skeleton3D:%s" % bone_name))
		animation.position_track_insert_key(track, 0.0, skeleton.get_bone_pose_position(bone_id))

	return animation
