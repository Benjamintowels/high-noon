extends AutoLootPickup

const ATTRACT_RANGE_OVERRIDE := 1.8
const BODY_COLOR := Color(0.92, 0.22, 0.28, 1.0)
const HIGHLIGHT_COLOR := Color(1.0, 0.55, 0.6, 1.0)

@export var heal_amount := 1


static func spawn_eject_drop(parent: Node, from_pos: Vector3, amount: int = 1) -> Area3D:
	if parent == null or amount <= 0:
		return null
	var script: Script = load("res://gameplay/world/health_pickup.gd") as Script
	var pickup: Area3D = script.new() as Area3D
	pickup.set("heal_amount", maxi(amount, 1))
	parent.add_child(pickup)
	pickup.global_position = from_pos
	if pickup.has_method("lock_pickup_for"):
		pickup.lock_pickup_for(0.35)
	if pickup.has_method("play_drop_arc"):
		pickup.play_drop_arc(from_pos)
	return pickup


func _get_attract_range() -> float:
	return ATTRACT_RANGE_OVERRIDE


func _can_collect() -> bool:
	if _player == null or not is_instance_valid(_player):
		return false
	if _player.has_method("get_health") and _player.has_method("get_max_health"):
		return int(_player.get_health()) < int(_player.get_max_health())
	if _player.has_method("heal"):
		return true
	return false


func _apply_pickup() -> int:
	if _player == null or not is_instance_valid(_player):
		return 0
	if _player.has_method("heal"):
		var healed: int = int(_player.heal(heal_amount))
		return maxi(healed, 0)
	return 0


func _build_visual() -> void:
	super._build_visual()

	var heart := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.09
	mesh.height = 0.14
	heart.mesh = mesh
	heart.scale = Vector3(1.0, 0.85, 1.0)

	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = BODY_COLOR
	body_mat.emission_enabled = true
	body_mat.emission = BODY_COLOR * 0.35
	body_mat.emission_energy_multiplier = 1.1
	heart.material_override = body_mat
	_visual_root.add_child(heart)

	var highlight := MeshInstance3D.new()
	var highlight_mesh := SphereMesh.new()
	highlight_mesh.radius = 0.035
	highlight_mesh.height = 0.05
	highlight.mesh = highlight_mesh
	highlight.position = Vector3(-0.02, 0.03, 0.04)
	var highlight_mat := StandardMaterial3D.new()
	highlight_mat.albedo_color = HIGHLIGHT_COLOR
	highlight_mat.emission_enabled = true
	highlight_mat.emission = HIGHLIGHT_COLOR
	highlight_mat.emission_energy_multiplier = 1.2
	highlight.material_override = highlight_mat
	_visual_root.add_child(highlight)
