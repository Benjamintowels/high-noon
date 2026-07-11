extends RefCounted
class_name MeleeWeaponVisuals

## Builds and caches a textured material for each stylized melee weapon and
## applies it to every mesh under a grip/display instance. The FBX files import
## without their PBR maps bound, so we wire them up here.

const GroyperWeaponsScript := preload("res://characters/groyper/groyper_weapons.gd")

const AXE_BASE := "res://Assets/Weapons/StylizedWeapons_v1_GENERIC/axe_one_handed/axe_DefaultMaterial_"
const SWORD_BASE := "res://Assets/Weapons/StylizedWeapons_v1_GENERIC/sword_one_handed/sword_sword_"
const AXE_2H_BASE := "res://Assets/Weapons/StylizedWeapons_v1_GENERIC/axe_two_handed/axe2hand_DefaultMaterial_"
const SWORD_2H_BASE := "res://Assets/Weapons/StylizedWeapons_v1_GENERIC/sword_two_handed/sword2hand_sword_blade_"
const HAMMER_2H_BASE := "res://Assets/Weapons/StylizedWeapons_v1_GENERIC/hammer_two_handed/hammer2hand_DefaultMaterial_"

static var _cache: Dictionary = {}


static func material_for(weapon_id: int) -> StandardMaterial3D:
	if _cache.has(weapon_id):
		return _cache[weapon_id]

	var prefix := ""
	match weapon_id:
		GroyperWeaponsScript.Id.AXE_1H:
			prefix = AXE_BASE
		GroyperWeaponsScript.Id.SWORD_1H:
			prefix = SWORD_BASE
		GroyperWeaponsScript.Id.AXE_2H:
			prefix = AXE_2H_BASE
		GroyperWeaponsScript.Id.SWORD_2H:
			prefix = SWORD_2H_BASE
		GroyperWeaponsScript.Id.HAMMER_2H:
			prefix = HAMMER_2H_BASE
		_:
			return null

	var mat := StandardMaterial3D.new()
	var albedo := _load_texture(prefix + "BaseColor.png")
	if albedo != null:
		mat.albedo_texture = albedo
	var normal := _load_texture(prefix + "Normal.png")
	if normal != null:
		mat.normal_enabled = true
		mat.normal_texture = normal
	var roughness := _load_texture(prefix + "Roughness.png")
	if roughness != null:
		mat.roughness_texture = roughness
	var metallic := _load_texture(prefix + "Metallic.png")
	if metallic != null:
		mat.metallic = 1.0
		mat.metallic_texture = metallic

	_cache[weapon_id] = mat
	return mat


static func apply(root: Node, weapon_id: int) -> void:
	if root == null:
		return
	var mat := material_for(weapon_id)
	if mat == null:
		return
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_inst := node as MeshInstance3D
		if mesh_inst.mesh == null:
			continue
		mesh_inst.material_override = mat


static func _load_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
