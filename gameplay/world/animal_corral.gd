extends Area3D

enum CorralType { HORSE, COW, PIG }

const STUPID_HORSE_SCENE := preload("res://characters/animals/stupid_horse.tscn")
const COW_SCENE := preload("res://characters/animals/cow.tscn")
const HorseModelConfig := preload("res://characters/animals/horse_model_config.gd")
const StupidHorseScript := preload("res://characters/animals/stupid_horse.gd")
const FactionIds := preload("res://gameplay/faction/faction_ids.gd")

@export var corral_type: CorralType = CorralType.HORSE
@export var spawn_animals := true
@export var owner_faction_id: StringName = &""
@export var capture_margin := 3.25

@onready var _animal_spawns: Node3D = $AnimalSpawns
@onready var _collision_shape: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	add_to_group("animal_corral")
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	if not spawn_animals:
		return
	_spawn_animals()


func get_owner_faction_id() -> StringName:
	return owner_faction_id


func can_capture_cow_at(cow: Node, world_pos: Vector3) -> bool:
	if owner_faction_id == &"":
		return false
	if cow != null and cow.has_method("get_owner_faction_id"):
		if cow.call("get_owner_faction_id") != owner_faction_id:
			return false
	return _is_position_in_capture_zone(world_pos)


func _is_position_in_capture_zone(world_pos: Vector3) -> bool:
	var local := global_transform.affine_inverse() * world_pos
	var half := get_roam_half_extents()
	var dx := maxf(absf(local.x) - half.x, 0.0)
	var dz := maxf(absf(local.z) - half.y, 0.0)
	return sqrt(dx * dx + dz * dz) <= capture_margin


func _on_body_entered(body: Node3D) -> void:
	if owner_faction_id == &"":
		return
	if not body.is_in_group("cow"):
		return
	if not body.has_method("try_enter_corral"):
		return
	body.call("try_enter_corral", self)


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


func get_entry_landing_position(from_world_pos: Vector3) -> Vector3:
	var center := get_roam_center()
	var flat_from := Vector3(from_world_pos.x, center.y, from_world_pos.z)
	var landing := flat_from.lerp(center, 0.72)
	var local := global_transform.affine_inverse() * landing
	var half := get_roam_half_extents() * 0.7
	local.x = clampf(local.x, -half.x, half.x)
	local.z = clampf(local.z, -half.y, half.y)
	return global_transform * Vector3(local.x, center.y, local.z)


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
