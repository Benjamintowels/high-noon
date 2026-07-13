extends SceneTree

## Headless check: Lean pose tracks resolve and applying neutral changes bone rotation.


func _initialize() -> void:
	var body: Node = load("res://characters/groyper/groyper_body.tscn").instantiate()
	root.add_child(body)

	var ap := body.get_node("AnimationPlayer") as AnimationPlayer
	var sk := body.get_node("Armature/Skeleton3D") as Skeleton3D

	print("ROOT_NODE:", ap.root_node)
	print("LIBS:", ap.get_animation_library_list())

	var anim := ap.get_animation("Lean/neutral")
	if anim == null:
		push_error("Missing Lean/neutral")
		quit(1)
		return

	var path := anim.track_get_path(0)
	print("TRACK0:", path, " VALID:", _track_valid(ap, path))

	var hips_idx := sk.find_bone("Hips")
	var before := sk.get_bone_pose_rotation(hips_idx)
	ap.play("Lean/neutral")
	ap.advance(0.0)
	var after := sk.get_bone_pose_rotation(hips_idx)
	print("HIPS_CHANGED:", before != after)

	if not _track_valid(ap, path):
		push_error("Track path invalid — root_node must be NodePath('..')")
		quit(1)
		return

	quit(0)


func _track_valid(ap: AnimationPlayer, path: NodePath) -> bool:
	var node_path := path.get_concatenated_subnames()
	if node_path.is_empty():
		return false
	var rel := NodePath(String(path.get_name(0)))
	var base := ap.get_node_or_null(ap.root_node)
	if base == null:
		return false
	return base.get_node_or_null(rel) != null
