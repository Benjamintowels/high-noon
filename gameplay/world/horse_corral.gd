extends Node3D
class_name HorseCorral

const STUPID_HORSE_SCENE := preload("res://characters/animals/stupid_horse.tscn")
const HorseModelConfig := preload("res://characters/animals/horse_model_config.gd")
const StupidHorseScript := preload("res://characters/animals/stupid_horse.gd")
const FENCE_PLANKS_MAT := preload("res://stages/stage1/materials/fence_planks.tres")

@export var corral_size := Vector2(9.0, 7.0)
@export var post_height := 1.35
@export var spawn_horses := true

@onready var _horse_spawns: Node3D = $HorseSpawns


func _ready() -> void:
	_build_fence()
	if spawn_horses:
		_spawn_horses()


func _build_fence() -> void:
	var half := corral_size * 0.5
	var corners := [
		Vector3(-half.x, 0.0, -half.y),
		Vector3(half.x, 0.0, -half.y),
		Vector3(half.x, 0.0, half.y),
		Vector3(-half.x, 0.0, half.y),
	]

	for i in corners.size():
		var start: Vector3 = corners[i]
		var end: Vector3 = corners[(i + 1) % corners.size()]
		_add_fence_side(start, end)

	for corner in corners:
		_add_corner_post_at(corner)
	_add_fence_post_local(Vector3(0.0, 0.0, -half.y))
	_add_fence_post_local(Vector3(0.0, 0.0, half.y))


func _spawn_horses() -> void:
	var variants := [0, 2]
	var index := 0
	for marker in _horse_spawns.get_children():
		if not marker is Marker3D:
			continue
		var horse: Node3D = STUPID_HORSE_SCENE.instantiate()
		horse.name = "CorralHorse_%d" % index
		horse.set("model_variant", HorseModelConfig.VARIANTS[variants[index % variants.size()]])
		horse.set("personality_seed", 1200 + index * 97)
		horse.set("roam_mode", StupidHorseScript.RoamMode.CORRAL)
		horse.set("roam_half_extents", corral_size * 0.38)
		add_child(horse)
		horse.global_position = marker.global_position
		horse.set("roam_center", global_position)
		index += 1


func _add_fence_side(from: Vector3, to: Vector3) -> void:
	var edge := to - from
	var length := edge.length()
	if length < 0.01:
		return

	var midpoint := from + edge * 0.5
	var yaw := atan2(edge.x, edge.z)
	var segment := Node3D.new()
	segment.position = midpoint
	segment.rotation.y = yaw
	add_child(segment)

	_add_corner_post(segment, Vector3(-length * 0.5, 0.0, 0.0))
	_add_corner_post(segment, Vector3(length * 0.5, 0.0, 0.0))
	for height in [0.35, 0.72, 1.08]:
		_add_fence_plank(segment, Vector3(0.0, height, 0.0), length)


func _add_corner_post(parent: Node3D, local_pos: Vector3) -> void:
	var post := MeshInstance3D.new()
	post.position = local_pos + Vector3(0.0, post_height * 0.5, 0.0)
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.14, post_height, 0.14)
	post.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.42, 0.28, 0.16, 1.0)
	mat.roughness = 0.9
	post.material_override = mat
	parent.add_child(post)


func _add_fence_plank(parent: Node3D, local_pos: Vector3, length: float) -> void:
	var plank := MeshInstance3D.new()
	plank.position = local_pos
	var mesh := BoxMesh.new()
	mesh.size = Vector3(length, 0.12, 0.06)
	plank.mesh = mesh
	plank.material_override = FENCE_PLANKS_MAT
	parent.add_child(plank)


func _add_corner_post_at(world_pos: Vector3) -> void:
	var post_root := Node3D.new()
	post_root.position = world_pos
	add_child(post_root)
	_add_corner_post(post_root, Vector3.ZERO)


func _add_fence_post_local(local_pos: Vector3) -> void:
	var post_root := Node3D.new()
	post_root.position = local_pos
	add_child(post_root)
	_add_corner_post(post_root, Vector3.ZERO)
