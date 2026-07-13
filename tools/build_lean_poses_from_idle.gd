@tool
extends SceneTree

const OUT_PATH := "res://characters/groyper/lean_poses.tres"
const BODY_SCENE := "res://characters/groyper/groyper_body.tscn"


func _initialize() -> void:
	var body: Node3D = load(BODY_SCENE).instantiate()
	root.add_child(body)

	var animation_player := body.get_node("AnimationPlayer") as AnimationPlayer
	var skeleton := body.get_node("Armature/Skeleton3D") as Skeleton3D
	var idle_name: StringName = GroyperBodyUtils.find_idle_animation_name(animation_player)

	animation_player.play(idle_name)
	animation_player.seek(0.0, true)
	animation_player.advance(0.0)

	var library := AnimationLibrary.new()
	var neutral := _make_pose_animation(skeleton)
	for pose_name: String in LeanPoseConfig.POSE_BLEND_POSITIONS.keys():
		library.add_animation(StringName(pose_name), neutral.duplicate(true))

	var err := ResourceSaver.save(library, OUT_PATH)
	print("SAVE_ERR:", err, " PATH:", OUT_PATH)
	quit()


func _make_pose_animation(skeleton: Skeleton3D) -> Animation:
	var animation := Animation.new()
	animation.length = 1.0
	animation.loop_mode = Animation.LOOP_LINEAR

	for bone_name: String in LeanPoseConfig.LEAN_BONES:
		var bone_id := skeleton.find_bone(bone_name)
		if bone_id < 0:
			continue

		var track := animation.add_track(Animation.TYPE_ROTATION_3D)
		animation.track_set_path(track, NodePath("Armature/Skeleton3D:%s" % bone_name))
		animation.rotation_track_insert_key(
			track,
			0.0,
			skeleton.get_bone_pose_rotation(bone_id)
		)

	return animation
