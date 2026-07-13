extends SceneTree
## Extracts the bow/arrow meshes from the "medieval weapons asset by niko" FBX
## into self-contained scenes (meshes saved as .res, materials as .tres) so the
## game scenes never depend on the FBX at runtime.
##
## Run headless:
##   Godot --headless --path . --script res://Assets/Weapons/Bow/bow_extract_cli.gd
##
## Source nodes inside the FBX (world scale is huge, ~24 units tall bow):
##   Cube_001     recurve bow body   Cube_002  its string (same node transform)
##   Cylinder     short bow (single mesh)      Cylinder_006  arrow
##
## Normalization: each scene root is the natural grip/center point,
## bows stand vertical along +Y with the string offset toward -X (matching the
## old primitive bow_grip.tscn layout), arrows point tip toward -Z spanning
## z [-0.32 .. +0.24] (matching the old arrow_projectile.tscn envelope).

const FBX_PATH := "res://Assets/Weapons/medieval weapons asset by niko.fbx"
const OUT_DIR := "res://Assets/Weapons/Bow/"
const MAT_DIR := OUT_DIR + "materials/"
const MESH_DIR := OUT_DIR + "meshes/"

const RECURVE_TARGET_HEIGHT := 0.95
const SHORT_TARGET_HEIGHT := 0.95
const ARROW_TARGET_LENGTH := 0.56
const ARROW_Z_MIN := -0.32

## FBX materials are flat grey (vertex-color flag set but no vertex colors),
## so we author replacements keyed by the FBX material names.
const MATERIAL_DEFS := {
	"iron": {"albedo": Color(0.62, 0.63, 0.66), "metallic": 0.85, "roughness": 0.35},
	"brown": {"albedo": Color(0.4, 0.26, 0.15), "metallic": 0.0, "roughness": 0.85},
	"light brown": {"albedo": Color(0.62, 0.45, 0.27), "metallic": 0.0, "roughness": 0.8},
	"white": {"albedo": Color(0.92, 0.9, 0.84), "metallic": 0.0, "roughness": 0.9},
}

var _materials := {}


func _initialize() -> void:
	_ensure_dir(OUT_DIR)
	_ensure_dir(MAT_DIR)
	_ensure_dir(MESH_DIR)
	_build_materials()

	var packed := load(FBX_PATH) as PackedScene
	if packed == null:
		push_error("Failed to load %s" % FBX_PATH)
		quit(1)
		return

	var root := packed.instantiate() as Node3D
	var body := root.find_child("Cube_001", true, false) as MeshInstance3D
	var bow_string := root.find_child("Cube_002", true, false) as MeshInstance3D
	var short_bow := root.find_child("Cylinder", true, false) as MeshInstance3D
	var arrow := root.find_child("Cylinder_006", true, false) as MeshInstance3D
	if body == null or bow_string == null or short_bow == null or arrow == null:
		push_error("Missing source mesh node(s) in FBX")
		root.free()
		quit(1)
		return

	_extract_recurve(body, bow_string, root)
	_extract_short_bow(short_bow, root)
	_extract_arrow(arrow, root)

	root.free()
	print("BOW_EXTRACT_OK")
	quit(0)


func _extract_recurve(body: MeshInstance3D, bow_string: MeshInstance3D, root: Node3D) -> void:
	var body_xf := _world_xform(body, root)
	var string_xf := _world_xform(bow_string, root)
	print("recurve body world xform: ", body_xf)
	print("recurve string world xform: ", string_xf)

	# Grip point = center of the "brown" grip-wrap surface on the body mesh.
	var grip_surface := _find_surface_by_material(body.mesh, "brown")
	var grip_center_local := _surface_aabb(body.mesh, grip_surface).get_center()
	var grip_world := body_xf * grip_center_local
	print("recurve grip surface=", grip_surface, " local center=", grip_center_local, " world=", grip_world)

	var world_aabb := _transformed_aabb(body.mesh.get_aabb(), body_xf)
	print("recurve body world aabb: ", world_aabb)
	var s := RECURVE_TARGET_HEIGHT / world_aabb.size.y
	# World +Z (string-to-grip axis) -> grip +X, so the string lands on -X like
	# the old primitive bow; height stays along +Y.
	var basis_n := Basis(Vector3.UP, PI * 0.5).scaled(Vector3(s, s, s))
	var n := Transform3D(basis_n, -(basis_n * grip_world))

	var body_mesh := _prepare_mesh(body.mesh, MESH_DIR + "recurve_bow_body.res")
	var string_mesh := _prepare_mesh(bow_string.mesh, MESH_DIR + "recurve_bow_string.res")

	var scene_root := Node3D.new()
	scene_root.name = "RecurveBow"
	var body_inst := MeshInstance3D.new()
	body_inst.name = "Body"
	body_inst.mesh = body_mesh
	body_inst.transform = n * body_xf
	scene_root.add_child(body_inst)
	body_inst.owner = scene_root
	var string_inst := MeshInstance3D.new()
	string_inst.name = "String"
	string_inst.mesh = string_mesh
	string_inst.transform = n * string_xf
	scene_root.add_child(string_inst)
	string_inst.owner = scene_root
	print("recurve Body final xform: ", body_inst.transform)
	print("recurve String final xform: ", string_inst.transform)
	print("recurve normalized body aabb: ", _transformed_aabb(body_mesh.get_aabb(), body_inst.transform))
	print("recurve normalized string aabb: ", _transformed_aabb(string_mesh.get_aabb(), string_inst.transform))

	_save_scene(scene_root, OUT_DIR + "recurve_bow.tscn")


func _extract_short_bow(short_bow: MeshInstance3D, root: Node3D) -> void:
	var xf := _world_xform(short_bow, root)
	print("short bow world xform: ", xf)
	var world_aabb := _transformed_aabb(short_bow.mesh.get_aabb(), xf)
	print("short bow world aabb: ", world_aabb)

	var s := SHORT_TARGET_HEIGHT / world_aabb.size.y
	var basis_n := Basis(Vector3.UP, PI * 0.5).scaled(Vector3(s, s, s))
	var n := Transform3D(basis_n, -(basis_n * world_aabb.get_center()))

	var mesh := _prepare_mesh(short_bow.mesh, MESH_DIR + "short_bow.res")
	var scene_root := Node3D.new()
	scene_root.name = "ShortBow"
	var inst := MeshInstance3D.new()
	inst.name = "Body"
	inst.mesh = mesh
	inst.transform = n * xf
	scene_root.add_child(inst)
	inst.owner = scene_root
	print("short bow final xform: ", inst.transform)
	print("short bow normalized aabb: ", _transformed_aabb(mesh.get_aabb(), inst.transform))

	_save_scene(scene_root, OUT_DIR + "short_bow.tscn")


func _extract_arrow(arrow: MeshInstance3D, root: Node3D) -> void:
	var xf := _world_xform(arrow, root)
	print("arrow world xform: ", xf)
	var world_aabb := _transformed_aabb(arrow.mesh.get_aabb(), xf)
	print("arrow world aabb: ", world_aabb)

	# Iron tip sits at local +Z which the FBX node maps to world +Y; rotate
	# world +Y (tip) onto -Z and scale to the old projectile's length.
	var s := ARROW_TARGET_LENGTH / world_aabb.size.y
	var basis_n := Basis(Vector3.RIGHT, -PI * 0.5).scaled(Vector3(s, s, s))
	var no_shift := Transform3D(basis_n, Vector3.ZERO)
	var rotated_aabb := _transformed_aabb(arrow.mesh.get_aabb(), no_shift * xf)
	var offset := Vector3(
		-(rotated_aabb.position.x + rotated_aabb.size.x * 0.5),
		-(rotated_aabb.position.y + rotated_aabb.size.y * 0.5),
		ARROW_Z_MIN - rotated_aabb.position.z
	)
	var n := Transform3D(basis_n, offset)

	var mesh := _prepare_mesh(arrow.mesh, MESH_DIR + "arrow.res")
	var scene_root := Node3D.new()
	scene_root.name = "Arrow"
	var inst := MeshInstance3D.new()
	inst.name = "ArrowMesh"
	inst.mesh = mesh
	inst.transform = n * xf
	scene_root.add_child(inst)
	inst.owner = scene_root
	print("arrow final xform: ", inst.transform)
	print("arrow normalized aabb: ", _transformed_aabb(mesh.get_aabb(), inst.transform))

	_save_scene(scene_root, OUT_DIR + "arrow.tscn")


func _build_materials() -> void:
	for mat_name: String in MATERIAL_DEFS:
		var def: Dictionary = MATERIAL_DEFS[mat_name]
		var mat := StandardMaterial3D.new()
		mat.resource_name = mat_name
		mat.albedo_color = def["albedo"]
		mat.metallic = def["metallic"]
		mat.roughness = def["roughness"]
		var path := MAT_DIR + "bow_" + mat_name.replace(" ", "_") + ".tres"
		var err := ResourceSaver.save(mat, path)
		if err != OK:
			push_error("Failed to save material %s (%s)" % [path, error_string(err)])
			continue
		mat.take_over_path(path)
		_materials[mat_name] = mat
		print("Saved ", path)


## Duplicates the imported mesh, swaps in our authored materials (matched by the
## FBX material names), saves it as .res, and points the resource at that file
## so packed scenes reference it externally instead of the FBX.
func _prepare_mesh(source: Mesh, path: String) -> ArrayMesh:
	var mesh := source.duplicate() as ArrayMesh
	for surf in mesh.get_surface_count():
		var original: Material = mesh.surface_get_material(surf)
		var original_name := original.resource_name if original != null else ""
		var replacement: Material = _materials.get(original_name)
		if replacement == null:
			push_error("No authored material for FBX material '%s' on %s" % [original_name, path])
			continue
		mesh.surface_set_material(surf, replacement)
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


func _find_surface_by_material(mesh: Mesh, mat_name: String) -> int:
	for surf in mesh.get_surface_count():
		var mat: Material = mesh.surface_get_material(surf)
		if mat != null and mat.resource_name == mat_name:
			return surf
	return 0


func _surface_aabb(mesh: ArrayMesh, surface: int) -> AABB:
	var arrays := mesh.surface_get_arrays(surface)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var result := AABB(verts[0], Vector3.ZERO)
	for v in verts:
		result = result.expand(v)
	return result


func _ensure_dir(path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))
