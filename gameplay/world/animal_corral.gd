extends Area3D

enum CorralType { HORSE, COW, PIG }

const STUPID_HORSE_SCENE := preload("res://characters/animals/stupid_horse.tscn")
const COW_SCENE := preload("res://characters/animals/cow.tscn")
const HorseModelConfig := preload("res://characters/animals/horse_model_config.gd")
const StupidHorseScript := preload("res://characters/animals/stupid_horse.gd")

@export var corral_type: CorralType = CorralType.HORSE
@export var spawn_animals := true

@onready var _animal_spawns: Node3D = $AnimalSpawns
@onready var _collision_shape: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	add_to_group("animal_corral")
	if not spawn_animals:
		return
	_spawn_animals()


func get_roam_center() -> Vector3:
	return global_position


func get_roam_half_extents() -> Vector2:
	if _collision_shape == null or _collision_shape.shape == null:
		return Vector2(4.5, 3.5)

	var shape := _collision_shape.shape
	if shape is BoxShape3D:
		var box := shape as BoxShape3D
		var collision_scale := _collision_shape.scale
		var half_x := box.size.x * 0.5 * absf(collision_scale.x) * absf(scale.x)
		var half_z := box.size.z * 0.5 * absf(collision_scale.z) * absf(scale.z)
		return Vector2(half_x, half_z)

	return Vector2(4.5, 3.5)


func get_roam_radius() -> float:
	var half := get_roam_half_extents()
	return minf(half.x, half.y) * 0.92


func _spawn_animals() -> void:
	match corral_type:
		CorralType.HORSE:
			_spawn_horses()
		CorralType.COW:
			_spawn_cows()
		CorralType.PIG:
			push_warning("AnimalCorral: pig corrals are not implemented yet.")


func _spawn_horses() -> void:
	var variants := [0, 2]
	var index := 0
	var roam_half := get_roam_half_extents() * 0.76

	for child in _animal_spawns.get_children():
		if not child is Marker3D:
			continue

		var marker := child as Marker3D
		var horse: Node3D = STUPID_HORSE_SCENE.instantiate()
		horse.name = "CorralHorse_%d" % index
		horse.set(
			"model_variant",
			HorseModelConfig.VARIANTS[variants[index % variants.size()]]
		)
		horse.set("personality_seed", 1200 + index * 97)
		horse.set("roam_mode", StupidHorseScript.RoamMode.CORRAL)
		horse.set("roam_half_extents", roam_half)
		add_child(horse)
		horse.global_position = marker.global_position
		horse.set("roam_center", global_position)
		index += 1


func _spawn_cows() -> void:
	var roam_radius := get_roam_radius()
	var index := 0

	for child in _animal_spawns.get_children():
		if not child is Marker3D:
			continue

		var marker := child as Marker3D
		var cow: Node3D = COW_SCENE.instantiate()
		cow.name = "CorralCow_%d" % index
		cow.set("personality_seed", 1400 + index * 83)
		cow.set("roam_center", global_position)
		cow.set("roam_radius", roam_radius)
		add_child(cow)
		cow.global_position = marker.global_position
		index += 1
