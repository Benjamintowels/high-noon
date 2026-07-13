extends SceneTree

const GLB_PATH := "res://Assets/World/OldChurch.glb"
const OUT_PATH := "res://Assets/World/OldChurch_visual.tscn"


func _init() -> void:
	var packed := load(GLB_PATH) as PackedScene
	if packed == null:
		push_error("Failed to load %s" % GLB_PATH)
		quit(1)
		return

	var source_root := packed.instantiate()
	var root := Node3D.new()
	root.name = "OldChurchVisual"

	for child in source_root.get_children():
		var duplicate := child.duplicate() as Node
		root.add_child(duplicate)
		duplicate.owner = root
		_set_owners_recursive(duplicate, root)

	source_root.free()

	var out_packed := PackedScene.new()
	var err := out_packed.pack(root)
	if err != OK:
		push_error("Failed to pack extracted visual (%s)" % error_string(err))
		quit(1)
		return

	err = ResourceSaver.save(out_packed, OUT_PATH)
	if err != OK:
		push_error("Failed to save %s (%s)" % [OUT_PATH, error_string(err)])
		quit(1)
		return

	print("Saved editable visual to ", OUT_PATH)
	quit()


func _set_owners_recursive(node: Node, owner: Node) -> void:
	for child in node.get_children():
		child.owner = owner
		_set_owners_recursive(child, owner)
