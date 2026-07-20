extends AutoLootPickup

const ElementalGems := preload("res://gameplay/items/elemental_gems.gd")

const GEM_MODEL_SCENE := preload("res://Assets/Particles/GramPickup/Gem_Model.fbx")
const ATTRACT_RANGE_OVERRIDE := 2.1
const MODEL_SCALE := 0.45

@export var gem_id: StringName = ElementalGems.LIGHTNING

var _remaining := 0


static func spawn_eject_drop(parent: Node, from_pos: Vector3, gem: StringName) -> Area3D:
	if parent == null or not ElementalGems.is_valid(gem):
		return null
	var script: Script = load("res://gameplay/world/elemental_gem_pickup.gd") as Script
	var pickup: Area3D = script.new() as Area3D
	pickup.set("gem_id", gem)
	pickup.set("_remaining", 1)
	parent.add_child(pickup)
	pickup.global_position = from_pos
	if pickup.has_method("lock_pickup_for"):
		pickup.lock_pickup_for(DEFAULT_PICKUP_LOCK)
	if pickup.has_method("play_drop_arc"):
		pickup.play_drop_arc(from_pos)
	return pickup


func _ready() -> void:
	if _remaining <= 0:
		_remaining = 1
	if not ElementalGems.is_valid(gem_id):
		gem_id = ElementalGems.LIGHTNING
	super._ready()


func _get_attract_range() -> float:
	return ATTRACT_RANGE_OVERRIDE


func _apply_pickup() -> int:
	if _remaining <= 0:
		return 0
	if not PlayerInventory.add_elemental_gem(gem_id):
		return 0
	_remaining = 0
	return 1


func _build_visual() -> void:
	super._build_visual()

	var model := GEM_MODEL_SCENE.instantiate() as Node3D
	if model == null:
		_build_fallback_visual()
		return

	model.scale = Vector3.ONE * MODEL_SCALE
	_visual_root.add_child(model)
	_tint_meshes(model, ElementalGems.get_color(gem_id))


func _build_fallback_visual() -> void:
	var color := ElementalGems.get_color(gem_id)
	var diamond := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.14, 0.14, 0.14)
	diamond.mesh = mesh
	diamond.rotation_degrees = Vector3(0.0, 45.0, 45.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.55
	mat.roughness = 0.22
	mat.emission_enabled = true
	mat.emission = color * 0.35
	mat.emission_energy_multiplier = 1.2
	diamond.material_override = mat
	_visual_root.add_child(diamond)


func _tint_meshes(root: Node, color: Color) -> void:
	if root is MeshInstance3D:
		var mesh_instance := root as MeshInstance3D
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.metallic = 0.45
		mat.roughness = 0.28
		mat.emission_enabled = true
		mat.emission = color * 0.4
		mat.emission_energy_multiplier = 1.35
		mesh_instance.material_override = mat
	for child in root.get_children():
		_tint_meshes(child, color)
