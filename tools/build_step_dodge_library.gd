extends SceneTree

## Bakes step_dodge animations (Meshy sidesteps + procedural forward/back) to StepDodge.res.
## Run: godot --headless --path . --script res://tools/build_step_dodge_library.gd

const OUT_PATH := "res://characters/groyper/StepDodge.res"
const BODY_SCENE := "res://characters/groyper/groyper_body.tscn"
const STEP_DODGE_LIBRARY := &"step_dodge"
const RigAnimConfig := preload("res://characters/groyper/rig_anim_config.gd")
const RigAnimUtils := preload("res://characters/groyper/rig_anim_utils.gd")
const LeanPoseConfig := preload("res://characters/groyper/lean_pose_config.gd")


func _initialize() -> void:
	var body: Node3D = load(BODY_SCENE).instantiate()
	root.add_child(body)

	var animation_player := body.get_node("AnimationPlayer") as AnimationPlayer
	var skeleton := body.get_node("Armature/Skeleton3D") as Skeleton3D
	var library := AnimationLibrary.new()

	for pose_name: String in RigAnimConfig.AUTHORED_SIDESTEP_POSES.keys():
		var scene_path: String = RigAnimConfig.AUTHORED_SIDESTEP_POSES[pose_name]
		var source := RigAnimUtils.load_skeleton_animation(scene_path)
		if source == null:
			quit(1)
			return
		library.add_animation(StringName(pose_name), RigAnimUtils.prepare_for_body_player(source))

	for pose_name: String in ["forwards", "back"]:
		var direction: Vector2 = LeanPoseConfig.POSE_BLEND_POSITIONS[pose_name]
		library.add_animation(
			StringName(pose_name),
			_make_procedural_step(skeleton, animation_player, direction)
		)

	var err := ResourceSaver.save(library, OUT_PATH)
	print("SAVE_ERR:", err, " PATH:", OUT_PATH)
	quit()


func _make_procedural_step(
	skeleton: Skeleton3D,
	animation_player: AnimationPlayer,
	direction: Vector2
) -> Animation:
	var keyframes := _step_keyframes_for_direction(direction)
	return _build_rotation_animation(skeleton, animation_player, keyframes, 0.38)


func _build_rotation_animation(
	skeleton: Skeleton3D,
	animation_player: AnimationPlayer,
	keyframes: Array,
	length: float
) -> Animation:
	var skeleton_path := animation_player.get_node(animation_player.root_node).get_path_to(skeleton)
	var animation := Animation.new()
	animation.length = length
	animation.loop_mode = Animation.LOOP_NONE

	var bone_tracks: Dictionary = {}
	for keyframe in keyframes:
		var time: float = keyframe["time"] * length
		var poses: Dictionary = keyframe.get("poses", {})
		for bone_name: String in poses:
			var bone_id := skeleton.find_bone(bone_name)
			if bone_id < 0:
				continue
			if not bone_tracks.has(bone_name):
				var track := animation.add_track(Animation.TYPE_ROTATION_3D)
				animation.track_set_path(track, NodePath("%s:%s" % [skeleton_path, bone_name]))
				bone_tracks[bone_name] = track
			var euler_deg: Vector3 = poses[bone_name]
			var euler_rad := Vector3(
				deg_to_rad(euler_deg.x),
				deg_to_rad(euler_deg.y),
				deg_to_rad(euler_deg.z)
			)
			var rest_basis := skeleton.get_bone_rest(bone_id).basis
			var target_rotation := (rest_basis * Basis.from_euler(euler_rad)).get_rotation_quaternion()
			animation.rotation_track_insert_key(bone_tracks[bone_name], time, target_rotation)
	return animation


func _step_keyframes_for_direction(direction: Vector2) -> Array:
	if direction.y > 0.5:
		return [
			{"time": 0.0, "poses": {}},
			{
				"time": 0.24,
				"poses": {
					"Hips": Vector3(-10.0, 0.0, 0.0),
					"LeftUpLeg": Vector3(30.0, 0.0, 10.0),
					"LeftLeg": Vector3(40.0, 0.0, 6.0),
					"RightUpLeg": Vector3(-6.0, 0.0, -10.0),
					"RightLeg": Vector3(10.0, 0.0, 0.0),
				},
			},
			{
				"time": 0.58,
				"poses": {
					"Hips": Vector3(-5.0, 0.0, 0.0),
					"LeftUpLeg": Vector3(10.0, 0.0, 6.0),
					"LeftLeg": Vector3(16.0, 0.0, 4.0),
					"RightUpLeg": Vector3(20.0, 0.0, -6.0),
					"RightLeg": Vector3(24.0, 0.0, 0.0),
				},
			},
			{"time": 1.0, "poses": {}},
		]
	return [
		{"time": 0.0, "poses": {}},
		{
			"time": 0.24,
			"poses": {
				"Hips": Vector3(8.0, 0.0, 0.0),
				"RightUpLeg": Vector3(24.0, 0.0, -8.0),
				"RightLeg": Vector3(32.0, 0.0, 0.0),
				"LeftUpLeg": Vector3(6.0, 0.0, 6.0),
				"LeftLeg": Vector3(12.0, 0.0, 0.0),
			},
		},
		{
			"time": 0.58,
			"poses": {
				"Hips": Vector3(4.0, 0.0, 0.0),
				"RightUpLeg": Vector3(10.0, 0.0, -4.0),
				"RightLeg": Vector3(16.0, 0.0, 0.0),
				"LeftUpLeg": Vector3(18.0, 0.0, 4.0),
				"LeftLeg": Vector3(22.0, 0.0, 0.0),
			},
		},
		{"time": 1.0, "poses": {}},
	]
