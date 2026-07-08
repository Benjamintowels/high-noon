extends SceneTree

const FBX_PATH := "res://Assets/World/ExtraTrees/Trees/Trees.fbx"
const OUT_DIR := "res://Assets/World/ExtraTrees/extracted/"
const OBJECTS_DIR := "res://Assets/World/ExtraTrees/Scenes/objects/"
const STAGE_PROPS_DIR := "res://stages/stage1/props/"
const FENCE_SURFACE_SCRIPT := preload("res://gameplay/targets/fence_surface.gd")
const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")


func _init() -> void:
	_ensure_dir(OUT_DIR)
	_ensure_dir(OBJECTS_DIR)
	_ensure_dir(STAGE_PROPS_DIR)
	extract_all()
	quit()


func _ensure_dir(path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))


func extract_all() -> void:
	var packed := load(FBX_PATH) as PackedScene
	if packed == null:
		push_error("Failed to load %s" % FBX_PATH)
		return

	var source_root := packed.instantiate()
	var trees_root := source_root as Node3D
	if trees_root == null:
		push_error("FBX root is not Node3D")
		source_root.free()
		return

	var prop_names: PackedStringArray = []
	for child in trees_root.get_children():
		if child is MeshInstance3D:
			prop_names.append(child.name)

	prop_names.sort()
	for prop_name in prop_names:
		var prop_node := trees_root.get_node_or_null(NodePath(prop_name)) as Node3D
		if prop_node == null:
			continue
		var scene_path := OUT_DIR + prop_name + ".tscn"
		_save_extracted_prop(prop_name, prop_node, scene_path)
		_save_object_wrapper(prop_name, scene_path)
		_save_stage_prop(prop_name, OBJECTS_DIR + prop_name + ".tscn")

	source_root.free()
	print("Extracted %d extra trees to %s" % [prop_names.size(), OUT_DIR])


func _save_extracted_prop(prop_name: StringName, prop_node: Node3D, scene_path: String) -> void:
	var root := Node3D.new()
	root.name = prop_name

	var duplicate := prop_node.duplicate() as Node3D
	duplicate.transform = prop_node.transform
	root.add_child(duplicate)
	duplicate.owner = root

	_ensure_collision(root, duplicate)

	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err != OK:
		push_error("Failed to pack %s (%s)" % [prop_name, error_string(err)])
		return

	err = ResourceSaver.save(packed, scene_path)
	if err != OK:
		push_error("Failed to save %s (%s)" % [scene_path, error_string(err)])
		return

	print("Saved ", scene_path)


func _save_object_wrapper(prop_name: StringName, extracted_path: String) -> void:
	var wrapper_root := Node3D.new()
	wrapper_root.name = prop_name

	var extracted := load(extracted_path) as PackedScene
	if extracted == null:
		push_error("Missing extracted scene for wrapper %s" % prop_name)
		return

	var instance := extracted.instantiate()
	wrapper_root.add_child(instance)
	instance.owner = wrapper_root

	var wrapper_path := OBJECTS_DIR + str(prop_name) + ".tscn"
	var packed := PackedScene.new()
	if packed.pack(wrapper_root) != OK:
		push_error("Failed to pack wrapper %s" % prop_name)
		return
	var err := ResourceSaver.save(packed, wrapper_path)
	if err != OK:
		push_error("Failed to save wrapper %s (%s)" % [wrapper_path, error_string(err)])
		return


func _save_stage_prop(prop_name: StringName, objects_path: String) -> void:
	var stage_name := _stage_prop_name(prop_name)
	var stage_path := STAGE_PROPS_DIR + stage_name + ".tscn"
	var file := FileAccess.open(stage_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open stage prop %s" % stage_path)
		return
	file.store_line("[gd_scene load_steps=2 format=3]")
	file.store_line("")
	file.store_line(
		'[ext_resource type="PackedScene" path="%s" id="1_prop"]' % objects_path
	)
	file.store_line("")
	file.store_line('[node name="%s" instance=ExtResource("1_prop")]' % stage_name)
	file.close()
	print("Saved ", stage_path)


func _stage_prop_name(prop_name: StringName) -> String:
	if str(prop_name) == "Tree":
		return "extra_tree"
	return "extra_" + str(prop_name).to_snake_case()


func _ensure_collision(root: Node3D, prop_node: Node3D) -> void:
	if _has_physics_body(prop_node):
		_tag_wood_surfaces(prop_node)
		return

	var meshes := _collect_meshes(prop_node)
	if meshes.is_empty():
		return

	var collision_root := Node3D.new()
	collision_root.name = "PropCollision"
	root.add_child(collision_root)
	collision_root.owner = root

	for mesh_inst in meshes:
		var shape := mesh_inst.mesh.create_trimesh_shape()
		if shape == null:
			continue
		var body := StaticBody3D.new()
		body.collision_layer = 1
		body.set_script(FENCE_SURFACE_SCRIPT)
		body.set("surface_kind", ImpactFXScript.SurfaceKind.WOOD)
		collision_root.add_child(body)
		body.owner = root
		body.transform = mesh_inst.transform
		var collision := CollisionShape3D.new()
		collision.shape = shape
		body.add_child(collision)
		collision.owner = root


func _has_physics_body(node: Node) -> bool:
	if node is StaticBody3D or node is RigidBody3D:
		return true
	for child in node.get_children():
		if _has_physics_body(child):
			return true
	return false


func _tag_wood_surfaces(node: Node) -> void:
	if node is StaticBody3D:
		var body := node as StaticBody3D
		body.collision_layer = 1
		if body.get_script() == null:
			body.set_script(FENCE_SURFACE_SCRIPT)
			body.set("surface_kind", ImpactFXScript.SurfaceKind.WOOD)
	for child in node.get_children():
		_tag_wood_surfaces(child)


func _collect_meshes(node: Node) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		var mesh_inst := node as MeshInstance3D
		if mesh_inst.mesh != null:
			meshes.append(mesh_inst)
	for child in node.get_children():
		meshes.append_array(_collect_meshes(child))
	return meshes
