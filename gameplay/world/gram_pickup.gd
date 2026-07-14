extends AutoLootPickup
class_name GramPickup

const ATTRACT_RANGE_OVERRIDE := 2.1
const BODY_COLOR := Color(0.62, 0.86, 0.98, 1.0)
const HIGHLIGHT_COLOR := Color(0.94, 0.98, 1.0, 1.0)

@export var gram_amount := 1

var _remaining := 0


static func spawn_eject_drop(parent: Node, from_pos: Vector3, amount: int) -> GramPickup:
	if parent == null or amount <= 0:
		return null
	var pickup := GramPickup.new()
	pickup.gram_amount = maxi(amount, 1)
	pickup._remaining = pickup.gram_amount
	parent.add_child(pickup)
	pickup.global_position = from_pos
	pickup.lock_pickup_for(DEFAULT_PICKUP_LOCK)
	pickup.play_drop_arc(from_pos)
	return pickup


func _ready() -> void:
	if _remaining <= 0:
		_remaining = maxi(gram_amount, 1)
	super._ready()


func _get_attract_range() -> float:
	return ATTRACT_RANGE_OVERRIDE


func _apply_pickup() -> int:
	if _remaining <= 0:
		return 0
	PlayerInventory.add_gram(_remaining)
	var collected := _remaining
	_remaining = 0
	return collected


func _build_visual() -> void:
	super._build_visual()

	var diamond := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.12, 0.12, 0.12)
	diamond.mesh = mesh
	diamond.rotation_degrees = Vector3(0.0, 45.0, 45.0)

	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = BODY_COLOR
	body_mat.metallic = 0.55
	body_mat.roughness = 0.22
	body_mat.emission_enabled = true
	body_mat.emission = BODY_COLOR * 0.25
	body_mat.emission_energy_multiplier = 0.9
	diamond.material_override = body_mat
	_visual_root.add_child(diamond)

	var highlight := MeshInstance3D.new()
	var highlight_mesh := BoxMesh.new()
	highlight_mesh.size = Vector3(0.05, 0.05, 0.05)
	highlight.mesh = highlight_mesh
	highlight.rotation_degrees = Vector3(0.0, 45.0, 45.0)
	highlight.position.y = 0.03

	var highlight_mat := StandardMaterial3D.new()
	highlight_mat.albedo_color = HIGHLIGHT_COLOR
	highlight_mat.metallic = 0.2
	highlight_mat.roughness = 0.15
	highlight_mat.emission_enabled = true
	highlight_mat.emission = HIGHLIGHT_COLOR * 0.45
	highlight_mat.emission_energy_multiplier = 1.1
	highlight.material_override = highlight_mat
	_visual_root.add_child(highlight)
