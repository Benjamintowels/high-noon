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


static func combined_mesh_aabb(root: Node3D) -> AABB:
	var combined := AABB()
	var first := true
	for mesh_inst in root.find_children("*", "MeshInstance3D", true, false):
		var local := (mesh_inst as MeshInstance3D).get_aabb()
		var corners := [
			local.position,
			local.position + Vector3(local.size.x, 0.0, 0.0),
			local.position + Vector3(0.0, local.size.y, 0.0),
			local.position + Vector3(0.0, 0.0, local.size.z),
			local.position + local.size,
		]
		for corner in corners:
			if first:
				combined = AABB(corner, Vector3.ZERO)
				first = false
			else:
				combined = combined.expand(corner)
	return combined


static func fit_scale(root: Node3D, requested_scale: float = 0.0) -> float:
	if requested_scale > 0.0:
		return requested_scale

	var local_aabb := combined_mesh_aabb(root)
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


static func ground_offset(root: Node3D, scale_value: float) -> float:
	var aabb := combined_mesh_aabb(root)
	return -aabb.position.y * scale_value