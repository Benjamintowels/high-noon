extends SceneTree

const MODEL_SCENE := preload("res://Assets/CharacterModels/Pyo/PyoMeshRigged.glb")
const SKELETON_REL := "UniRigArmature/Skeleton3D"
const OUT_DIR := "res://characters/pyo/anims/"
const IDLE_PATH := OUT_DIR + "pyo_idle.tres"
const LOOK_UP_PATH := OUT_DIR + "pyo_look_up.tres"


func _initialize() -> void:
	var root := MODEL_SCENE.instantiate()
	var skeleton := _find_skeleton(root)
	if skeleton == null:
		printerr("Pyo pose bake: missing Skeleton3D")
		quit(1)
		return

	var idle := _make_pose_animation(&"idle", skeleton, 1.0, Animation.LOOP_LINEAR)
	var look_up := _make_pose_animation(&"look_up", skeleton, 1.0, Animation.LOOP_NONE)

	_save_resource(IDLE_PATH, idle)
	_save_resource(LOOK_UP_PATH, look_up)

	print("Wrote Pyo animations to ", OUT_DIR)
	root.free()
	quit()


func _make_pose_animation(
	anim_name: StringName,
	skeleton: Skeleton3D,
	length: float,
	loop_mode: Animation.LoopMode
) -> Animation:
	var anim := Animation.new()
	anim.resource_name = String(anim_name)
	anim.length = length
	anim.loop_mode = loop_mode

	for i in skeleton.get_bone_count():
		var bone_name := skeleton.get_bone_name(i)
		var rot := skeleton.get_bone_pose(i).basis.get_rotation_quaternion()
		var track := anim.add_track(Animation.TYPE_ROTATION_3D)
		anim.track_set_path(track, NodePath("%s:%s" % [SKELETON_REL, bone_name]))
		anim.track_insert_key(track, 0.0, rot)

	return anim


func _save_resource(path: String, resource: Resource) -> void:
	var err := ResourceSaver.save(resource, path)
	if err != OK:
		push_error("Failed to save %s (%s)" % [path, error_string(err)])


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null
