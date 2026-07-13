extends Node3D

## Handheld torch visual: brown stick + always-on fire tip.
## Placement is authored on `hand_torch_mount.tscn` (GripOffset / this root).

const FIRE_SCENE := preload("res://Assets/World/RuinsGR/AccessoriesScenes/fire.tscn")

const STICK_SIZE := Vector3(0.035, 0.52, 0.035)
const FIRE_LOCAL := Vector3(0.0, 0.28, 0.0)
const HANDHELD_LIGHT_ENERGY := 2.2
const HANDHELD_LIGHT_RANGE := 12.0


func _ready() -> void:
	_build_stick()
	_build_fire()


func _build_stick() -> void:
	if get_node_or_null("Stick") != null:
		return
	var stick := MeshInstance3D.new()
	stick.name = "Stick"
	var box := BoxMesh.new()
	box.size = STICK_SIZE
	stick.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.42, 0.26, 0.12)
	mat.roughness = 0.92
	stick.material_override = mat
	stick.position = Vector3(0.0, STICK_SIZE.y * 0.5, 0.0)
	add_child(stick)


func _build_fire() -> void:
	if get_node_or_null("Fire") != null:
		return
	var fire: Node3D = FIRE_SCENE.instantiate()
	fire.name = "Fire"
	fire.position = FIRE_LOCAL
	fire.scale = Vector3(0.14, 0.14, 0.14)
	if fire.has_method("set_respect_day_night"):
		fire.set_respect_day_night(false)
	if "base_energy" in fire:
		fire.base_energy = HANDHELD_LIGHT_ENERGY
	add_child(fire)
	call_deferred("_tune_handheld_light", fire)


func _tune_handheld_light(fire: Node3D) -> void:
	if fire == null or not is_instance_valid(fire):
		return
	var light := fire.get_node_or_null("Light") as OmniLight3D
	if light == null:
		return
	light.omni_range = HANDHELD_LIGHT_RANGE
	light.light_energy = HANDHELD_LIGHT_ENERGY
