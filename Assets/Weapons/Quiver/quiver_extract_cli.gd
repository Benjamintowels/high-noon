extends SceneTree
## Extracts the quiver container mesh from quiver.fbx into a self-contained scene
## (meshes saved as .res, material as .tres using quiver_texture.png) so the game
## scene never depends on the FBX at runtime. Mirrors bow_extract_cli.gd.
##
## Run headless:
##   Godot --headless --path . --script res://Assets/Weapons/Quiver/quiver_extract_cli.gd
##
## Source nodes inside the FBX (Blender Y-up, real-world metre scale):
##   quiver   the container body        belt   the shoulder strap
##   Cube..Cube_004   UV-grid checker studs (skipped)
##   pijl..pijl_004   built-in arrows (skipped; arrows come from arrow.tscn)
##
## Normalisation: recentre the combined body+belt AABB to the origin and scale
## to QUIVER_TARGET_HEIGHT so the prop sits at a sane size; opening stays at +Y.

const FBX_PATH := "res://Assets/Weapons/Quiver/source/quiver.fbx"
const OUT_DIR := "res://Assets/Weapons/Quiver/"
const MAT_DIR := OUT_DIR + "materials/"
const MESH_DIR := OUT_DIR + "meshes/"
const QUIVER_TEXTURE := "res://Assets/Weapons/Quiver/textures/quiver_texture.png"

## Mesh nodes that make up the visible container (everything else in the FBX is
## a UV-test stud or a built-in arrow we do not want baked in).
const KEEP_NODES := ["quiver", "belt"]
const QUIVER_TARGET_HEIGHT := 0.55


func _initialize() -> void:
	_ensure_dir(OUT_DIR)
	_ensure_dir(MAT_DIR)
	_ensure_dir(MESH_DIR)

	var packed := load(FBX_PATH) as PackedScene
	if packed == null:
		push_error("Failed to load %s" % FBX_PATH)
		quit(1)
		return

	var root := packed.instantiate() as Node3D
	var kept: Array[MeshInstance3D] = []
	for node_name: String in KEEP_NODES:
		var mi := root.find_child(node_name, true, false) as MeshInstance3D
		if mi == null:
			push_error("Missing source node '%s' in FBX" % node_name)
			root.free()
			quit(1)
			return
		kept.append(mi)

	var material := _build_material()

	# Combined world AABB of the kept meshes -> centre + scale normalisation.
	var combined := AABB()
	var have_aabb := false
	var world_xforms: Array[Transform3D] = []
	for mi in kept:
		var world_xf := _world_xform(mi, root)
		world_xforms.append(world_xf)
		var world_aabb := _transformed_aabb(mi.mesh.get_aabb(), world_xf)
		if not have_aabb:
			combined = world_aabb
			have_aabb = true
		else:
			combined = combined.merge(world_aabb)

	print("quiver combined world aabb: ", combined)
	var scale := QUIVER_TARGET_HEIGHT / combined.size.y
	var basis_n := Basis().scaled(Vector3(scale, scale, scale))
	var n := Transform3D(basis_n, -(basis_n * combined.get_center()))
	print("quiver normalise scale=", scale, " n=", n)

	var scene_root := Node3D.new()
	scene_root.name = "Quiver"
	for i in kept.size():
		var mi := kept[i]
		var mesh := _prepare_mesh(mi.mesh, material, MESH_DIR + mi.name + ".res")
		var inst := MeshInstance3D.new()
		inst.name = _pascal(mi.name)
		inst.mesh = mesh
		inst.transform = n * world_xforms[i]
		scene_root.add_child(inst)
		inst.owner = scene_root
		print(
			"quiver piece '", inst.name, "' final xform=", inst.transform,
			" normalized aabb=", _transformed_aabb(mesh.get_aabb(), inst.transform)
		)

	_save_scene(scene_root, OUT_DIR + "quiver.tscn")
	root.free()
	print("QUIVER_EXTRACT_OK")
	quit(0)


func _build_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.resource_name = "quiver"
	var tex := load(QUIVER_TEXTURE) as Texture2D
	if tex == null:
		push_error("Failed to load quiver texture %s" % QUIVER_TEXTURE)
	else:
		mat.albedo_texture = tex
	mat.roughness = 0.85
	mat.metallic = 0.0
	var path := MAT_DIR + "quiver.tres"
	var err := ResourceSaver.save(mat, path)
	if err != OK:
		push_error("Failed to save material %s (%s)" % [path, error_string(err)])
	mat.take_over_path(path)
	print("Saved ", path)
	return mat


func _prepare_mesh(source: Mesh, material: Material, path: String) -> ArrayMesh:
	var mesh := source.duplicate() as ArrayMesh
	for surf in mesh.get_surface_count():
		mesh.surface_set_material(surf, material)
	var err := ResourceSaver.save(mesh, path)
	if err != OK:
		push_error("Failed to save mesh %s (%s)" % [path, error_string(err)])
	mesh.take_over_path(path)
	print("Saved ", path)
	return mesh


func _save_scene(scene_root: Node3D, path: String) -> void:
	var packed := PackedScene.new()
	var err := packed.pack(scene_root)
	if err != OK:
		push_error("Failed to pack %s (%s)" % [path, error_string(err)])
		return
	err = ResourceSaver.save(packed, path)
	if err != OK:
		push_error("Failed to save %s (%s)" % [path, error_string(err)])
		return
	print("Saved ", path)
	scene_root.free()


func _pascal(raw: String) -> String:
	return raw.substr(0, 1).to_upper() + raw.substr(1)


func _world_xform(node: Node3D, root: Node3D) -> Transform3D:
	var xf := node.transform
	var parent := node.get_parent() as Node3D
	while parent != null and parent != root:
		xf = parent.transform * xf
		parent = parent.get_parent() as Node3D
	if parent == root:
		xf = root.transform * xf
	return xf


func _transformed_aabb(aabb: AABB, xf: Transform3D) -> AABB:
	var result := AABB(xf * aabb.position, Vector3.ZERO)
	for i in 8:
		result = result.expand(xf * aabb.get_endpoint(i))
	return result


func _ensure_dir(path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))
