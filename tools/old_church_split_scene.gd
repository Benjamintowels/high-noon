extends SceneTree

const SOURCE_PATH := "res://gameplay/world/old_church.scn"
const VISUAL_OUT_PATH := "res://gameplay/world/old_church_visual.scn"
const WRAPPER_OUT_PATH := "res://gameplay/world/old_church.tscn"
const SCRIPT_PATH := "res://gameplay/world/old_church.gd"


func _init() -> void:
	var packed := load(SOURCE_PATH) as PackedScene
	if packed == null:
		push_error("Failed to load %s" % SOURCE_PATH)
		quit(1)
		return

	var source_root := packed.instantiate() as Node3D
	if source_root == null:
		push_error("Source root is not Node3D")
		quit(1)
		return

	var visual_node := source_root.get_node_or_null("Visual") as Node3D
	if visual_node == null:
		push_error("Missing Visual node in %s" % SOURCE_PATH)
		source_root.free()
		quit(1)
		return

	_save_visual_scene(visual_node)
	_save_wrapper_scene(source_root, visual_node)
	source_root.free()
	print("Split old church into %s and %s" % [VISUAL_OUT_PATH, WRAPPER_OUT_PATH])
	quit()


func _save_visual_scene(visual_node: Node3D) -> void:
	var visual_root := Node3D.new()
	visual_root.name = "OldChurchVisual"

	for child in visual_node.get_children():
		var duplicate := child.duplicate() as Node
		visual_root.add_child(duplicate)
		duplicate.owner = visual_root
		_set_owners_recursive(duplicate, visual_root)

	var visual_packed := PackedScene.new()
	if visual_packed.pack(visual_root) != OK:
		push_error("Failed to pack visual scene")
		quit(1)
		return

	if ResourceSaver.save(visual_packed, VISUAL_OUT_PATH) != OK:
		push_error("Failed to save %s" % VISUAL_OUT_PATH)
		quit(1)
		return


func _save_wrapper_scene(source_root: Node3D, visual_node: Node3D) -> void:
	var root := Node3D.new()
	root.name = "OldChurch"
	root.set_script(load(SCRIPT_PATH))

	var visual := Node3D.new()
	visual.name = "Visual"
	root.add_child(visual)
	visual.owner = root

	var visual_packed := load(VISUAL_OUT_PATH) as PackedScene
	if visual_packed == null:
		push_error("Failed to load freshly saved visual scene")
		quit(1)
		return
	var visual_instance := visual_packed.instantiate()
	visual.add_child(visual_instance)
	visual_instance.owner = root
	_set_owners_recursive(visual_instance, root)

	for child_name in ["Entrance", "Props", "Lights"]:
		var source_child := source_root.get_node_or_null(child_name)
		if source_child == null:
			continue
		var duplicate := source_child.duplicate() as Node
		root.add_child(duplicate)
		duplicate.owner = root

	var wrapper_packed := PackedScene.new()
	if wrapper_packed.pack(root) != OK:
		push_error("Failed to pack wrapper scene")
		quit(1)
		return

	if ResourceSaver.save(wrapper_packed, WRAPPER_OUT_PATH) != OK:
		push_error("Failed to save %s" % WRAPPER_OUT_PATH)
		quit(1)
		return


func _set_owners_recursive(node: Node, owner: Node) -> void:
	for child in node.get_children():
		child.owner = owner
		_set_owners_recursive(child, owner)
