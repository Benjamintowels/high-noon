class_name HorseModelConfig
extends RefCounted

const TARGET_HEIGHT := 1.5

const VARIANTS: Array[String] = [
	"res://Assets/Animals/horses/FBX/horse/horse.fbx",
	"res://Assets/Animals/horses/FBX/horse/horse.001.fbx",
	"res://Assets/Animals/horses/FBX/horse/horse.002.fbx",
	"res://Assets/Animals/horses/FBX/horse/horse.003.fbx",
	"res://Assets/Animals/horses/FBX/horse/horse.004.fbx",
]

const TEXTURES: Array[String] = [
	"res://Assets/Animals/horses/textures/horse_005_horses-grey-horse-animal-preview.png",
	"res://Assets/Animals/horses/textures/horse_006_Assateague_Island_horses_August_2009_3.png",
	"res://Assets/Animals/horses/textures/horse_007_White_horse_portrait.png",
	"res://Assets/Animals/horses/textures/horse_008_Koktebel_-_horse.png",
	"res://Assets/Animals/horses/textures/horse_009_Spotted_roan_horse_-_geograph.org.png",
]

const DEFAULT_MOUNT_HEIGHT := 1.35
## Tuned from horse[0] (horse.fbx / grey) — all variants align to this saddle point.
const REFERENCE_MOUNT_POS := Vector3(0.0, DEFAULT_MOUNT_HEIGHT, 0.011033)


static func variant_index(variant_path: String) -> int:
	var index := VARIANTS.find(variant_path)
	return index if index >= 0 else 0


static func pick_variant(seed_value: int = -1) -> String:
	if VARIANTS.is_empty():
		return ""
	if seed_value >= 0:
		return VARIANTS[seed_value % VARIANTS.size()]
	return VARIANTS[randi() % VARIANTS.size()]


static func texture_for_variant(variant_path: String) -> String:
	return TEXTURES[variant_index(variant_path)]


static func load_texture(variant_path: String) -> Texture2D:
	var texture_path := texture_for_variant(variant_path)
	var imported: Texture2D = load(texture_path)
	if imported != null:
		return imported

	var image := Image.new()
	var absolute_path := ProjectSettings.globalize_path(texture_path)
	var err := image.load(absolute_path)
	if err != OK:
		push_warning("HorseModelConfig: failed to load texture %s (%s)" % [texture_path, err])
		return null
	return ImageTexture.create_from_image(image)


static func apply_texture(root: Node3D, variant_path: String) -> void:
	var texture := load_texture(variant_path)
	if texture == null:
		return

	for mesh_inst in root.find_children("*", "MeshInstance3D", true, false):
		var material := StandardMaterial3D.new()
		material.albedo_texture = texture
		material.albedo_color = Color.WHITE
		material.roughness = 0.88
		material.metallic = 0.0
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		(mesh_inst as MeshInstance3D).material_override = material


static func transform_to_ancestor(node: Node3D, ancestor: Node3D) -> Transform3D:
	var parts: Array[Node3D] = []
	var current: Node = node
	while current != null and current != ancestor:
		if current is Node3D:
			parts.push_front(current as Node3D)
		current = current.get_parent()
	var xf := Transform3D.IDENTITY
	for part in parts:
		xf = xf * part.transform
	return xf


static func _mesh_aabb_corners(mesh_aabb: AABB) -> Array[Vector3]:
	var p := mesh_aabb.position
	var s := mesh_aabb.size
	return [
		p,
		p + Vector3(s.x, 0.0, 0.0),
		p + Vector3(0.0, s.y, 0.0),
		p + Vector3(0.0, 0.0, s.z),
		p + Vector3(s.x, s.y, 0.0),
		p + Vector3(s.x, 0.0, s.z),
		p + Vector3(0.0, s.y, s.z),
		p + s,
	]


static func combined_mesh_aabb_legacy(root: Node3D) -> AABB:
	var combined := AABB()
	var first := true
	for mesh_inst in root.find_children("*", "MeshInstance3D", true, false):
		var local := (mesh_inst as MeshInstance3D).get_aabb()
		for corner in _mesh_aabb_corners(local):
			if first:
				combined = AABB(corner, Vector3.ZERO)
				first = false
			else:
				combined = combined.expand(corner)
	return combined


static func combined_mesh_aabb(root: Node3D) -> AABB:
	var combined := AABB()
	var first := true
	for mesh_inst in root.find_children("*", "MeshInstance3D", true, false):
		var mesh := mesh_inst as MeshInstance3D
		var to_root := transform_to_ancestor(mesh, root)
		for corner in _mesh_aabb_corners(mesh.get_aabb()):
			var root_corner := to_root * corner
			if first:
				combined = AABB(root_corner, Vector3.ZERO)
				first = false
			else:
				combined = combined.expand(root_corner)
	return combined


static func saddle_point_visual_root(root: Node3D) -> Vector3:
	for mesh_inst in root.find_children("*", "MeshInstance3D", true, false):
		var mesh := mesh_inst as MeshInstance3D
		var mesh_aabb := mesh.get_aabb()
		var local := Vector3(
			mesh_aabb.position.x + mesh_aabb.size.x * 0.5,
			mesh_aabb.position.y + mesh_aabb.size.y * 0.84,
			mesh_aabb.position.z + mesh_aabb.size.z * 0.44
		)
		return transform_to_ancestor(mesh, root) * local
	return Vector3.ZERO


static func facing_point_from_visual_state(
	visual_pos: Vector3,
	visual_scale: Vector3,
	model_scale: Vector3,
	point_visual_root: Vector3
) -> Vector3:
	var anim_point := visual_pos + Vector3(
		point_visual_root.x * visual_scale.x,
		point_visual_root.y * visual_scale.y,
		point_visual_root.z * visual_scale.z
	)
	return Vector3(
		anim_point.x * model_scale.x,
		anim_point.y * model_scale.y,
		anim_point.z * model_scale.z
	)


static func fit_scale(root: Node3D, requested_scale: float = 0.0) -> float:
	if requested_scale > 0.0:
		return requested_scale

	var local_aabb := combined_mesh_aabb_legacy(root)
	var local_height := local_aabb.size.y
	if local_height < 0.001:
		local_height = maxf(local_aabb.size.x, local_aabb.size.z)
	if local_height < 0.001:
		return 1.0

	var existing_scale := maxf(root.scale.x, maxf(root.scale.y, root.scale.z))
	var world_height := local_height * existing_scale
	if world_height < 0.001:
		return 1.0

	if world_height >= TARGET_HEIGHT * 0.85 and world_height <= TARGET_HEIGHT * 1.35:
		return 1.0

	return TARGET_HEIGHT / world_height


static func reference_mount_position(mount_height: float = DEFAULT_MOUNT_HEIGHT) -> Vector3:
	return Vector3(REFERENCE_MOUNT_POS.x, mount_height, REFERENCE_MOUNT_POS.z)


## Shift each variant mesh laterally so the saddle X matches horse[0]. Feet stay on the
## ground; Z is left at 0 because the reference mount Z was hand-tuned in the scene.
static func align_visual_to_reference_mount(
	root: Node3D,
	visual_scale: Vector3,
	model_scale: Vector3,
	reference_mount: Vector3
) -> Vector3:
	var saddle_root := saddle_point_visual_root(root)
	var legacy_aabb := combined_mesh_aabb_legacy(root)

	var safe_vx := visual_scale.x if absf(visual_scale.x) > 0.0001 else 1.0
	var safe_vy := visual_scale.y if absf(visual_scale.y) > 0.0001 else 1.0
	var safe_mx := model_scale.x if absf(model_scale.x) > 0.0001 else 1.0

	return Vector3(
		reference_mount.x / safe_mx - saddle_root.x * safe_vx,
		-legacy_aabb.position.y * safe_vy,
		0.0
	)