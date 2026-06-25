extends Node3D

const FENCE_PLANKS_MAT := preload("res://stages/stage1/materials/fence_planks.tres")
const FENCE_SURFACE_SCRIPT := preload("res://gameplay/targets/fence_surface.gd")
const TARGET_SCORABLE_SCRIPT := preload("res://gameplay/target/target_scorable.gd")
const BOARD_SCENE := preload("res://Assets/Guns/board.fbx")

const FENCE_COUNT := 3
const OBJECT_COUNT := 10
const FENCE_SPACING := 3.2
const FENCE_DISTANCE_STEPS := [-11.0, -8.5, -6.0, -4.0]
const MIN_FENCE_DISTANCE_Z := -3.5
const SHOOTER_SPACING := 3.0

var _scorables: Array[Node] = []


func get_scorables() -> Array[Node]:
	return _scorables


static func fence_distance_for_round(round_number: int) -> float:
	var index := round_number - 1
	if index < FENCE_DISTANCE_STEPS.size():
		return FENCE_DISTANCE_STEPS[index]

	var steps_past_schedule := round_number - FENCE_DISTANCE_STEPS.size()
	return maxf(FENCE_DISTANCE_STEPS[-1] + float(steps_past_schedule), MIN_FENCE_DISTANCE_Z)


func build(round_number: int = 1) -> void:
	_clear_children()
	_scorables.clear()

	var fence_z := fence_distance_for_round(round_number)
	var fence_positions: Array[float] = []
	var half := (FENCE_COUNT - 1) * 0.5
	for i in FENCE_COUNT:
		fence_positions.append((float(i) - half) * FENCE_SPACING)

	for x in fence_positions:
		_add_fence_segment(Vector3(x, 0.0, fence_z))

	_place_scorables(fence_positions, fence_z)


func get_player_spawn_position() -> Vector3:
	return Vector3(-SHOOTER_SPACING * 0.5, 0.0, 0.0)


func get_rival_spawn_position() -> Vector3:
	return Vector3(SHOOTER_SPACING * 0.5, 0.0, 0.0)


func get_shooter_forward_rotation_y() -> float:
	return 0.0


func _clear_children() -> void:
	for child in get_children():
		child.queue_free()


func _add_fence_segment(origin: Vector3) -> void:
	var root := Node3D.new()
	root.name = "FenceSegment"
	root.position = origin
	add_child(root)

	_add_fence_post(root, Vector3(-1.2, 0.675, 0.0))
	_add_fence_post(root, Vector3(1.2, 0.675, 0.0))
	_add_fence_plank(root, Vector3(0.0, 0.35, 0.0))
	_add_fence_plank(root, Vector3(0.0, 0.72, 0.0))
	_add_fence_plank(root, Vector3(0.0, 1.08, 0.0))


func _add_fence_post(parent: Node3D, local_pos: Vector3) -> void:
	var post := StaticBody3D.new()
	post.position = local_pos
	post.set_script(FENCE_SURFACE_SCRIPT)
	parent.add_child(post)

	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.14, 1.35, 0.14)
	mesh_instance.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.42, 0.28, 0.16, 1.0)
	mat.roughness = 0.9
	mesh_instance.set_surface_override_material(0, mat)
	post.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.14, 1.35, 0.14)
	collision.shape = shape
	post.add_child(collision)


func _add_fence_plank(parent: Node3D, local_pos: Vector3) -> void:
	var plank := StaticBody3D.new()
	plank.position = local_pos
	plank.set_script(FENCE_SURFACE_SCRIPT)
	parent.add_child(plank)

	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(2.4, 0.12, 0.06)
	mesh_instance.mesh = mesh
	mesh_instance.set_surface_override_material(0, FENCE_PLANKS_MAT)
	plank.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.4, 0.12, 0.06)
	collision.shape = shape
	plank.add_child(collision)


func _place_scorables(fence_positions: Array, fence_z: float) -> void:
	var placements: Array[Dictionary] = [
		{"fence": 0, "offset": Vector3(-0.55, 1.22, 0.04), "style": "can"},
		{"fence": 0, "offset": Vector3(0.15, 1.26, 0.02), "style": "bottle"},
		{"fence": 0, "offset": Vector3(0.82, 1.05, 0.06), "style": "board"},
		{"fence": 0, "offset": Vector3(-0.1, 1.05, 0.05), "style": "can"},
		{"fence": 1, "offset": Vector3(-0.45, 1.2, 0.04), "style": "can"},
		{"fence": 1, "offset": Vector3(0.2, 1.24, 0.02), "style": "bottle"},
		{"fence": 1, "offset": Vector3(0.7, 1.02, 0.06), "style": "board"},
		{"fence": 2, "offset": Vector3(-0.5, 1.22, 0.04), "style": "can"},
		{"fence": 2, "offset": Vector3(0.0, 1.26, 0.02), "style": "bottle"},
		{"fence": 2, "offset": Vector3(0.65, 1.04, 0.06), "style": "board"},
	]

	for placement in placements:
		var fence_idx: int = placement["fence"]
		var fence_x: float = fence_positions[fence_idx]
		var world_pos: Vector3 = Vector3(fence_x, 0.0, fence_z) + placement["offset"]
		var prop := _create_scorable(placement["style"])
		prop.global_position = world_pos
		add_child(prop)
		_scorables.append(prop)


func _create_scorable(style: String) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.set_script(TARGET_SCORABLE_SCRIPT)
	body.mass = 0.35
	body.linear_damp = 0.2
	body.angular_damp = 0.25

	match style:
		"can":
			body.name = "TinCan"
			body.set("prop_style", TARGET_SCORABLE_SCRIPT.PropStyle.KNOCK_OFF)
			body.set("use_metal_fx", true)
			body.set("knockback_force", 14.0)
			body.set("knockback_torque", 7.0)
			_add_can_mesh(body)
		"bottle":
			body.name = "GlassBottle"
			body.mass = 0.25
			body.set("prop_style", TARGET_SCORABLE_SCRIPT.PropStyle.SHATTER)
			_add_bottle_mesh(body)
		"board":
			body.name = "TargetBoard"
			body.mass = 0.8
			body.set("prop_style", TARGET_SCORABLE_SCRIPT.PropStyle.KNOCK_OFF)
			body.set("knockback_force", 18.0)
			body.set("knockback_torque", 11.0)
			_add_board_mesh(body)

	var collision := CollisionShape3D.new()
	body.add_child(collision)

	match style:
		"can":
			var shape := CylinderShape3D.new()
			shape.height = 0.14
			shape.radius = 0.075
			collision.shape = shape
		"bottle":
			var shape := CylinderShape3D.new()
			shape.height = 0.22
			shape.radius = 0.05
			collision.shape = shape
		"board":
			var shape := BoxShape3D.new()
			shape.size = Vector3(0.08, 0.55, 0.45)
			collision.transform = Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, 0.02))
			collision.shape = shape

	return body


func _add_can_mesh(body: RigidBody3D) -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.07
	mesh.bottom_radius = 0.075
	mesh.height = 0.14
	mesh_instance.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.72, 0.18, 0.12, 1.0)
	mat.metallic = 0.75
	mat.roughness = 0.35
	mesh_instance.set_surface_override_material(0, mat)
	body.add_child(mesh_instance)


func _add_bottle_mesh(body: RigidBody3D) -> void:
	var body_mesh := MeshInstance3D.new()
	body_mesh.name = "Body"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.045
	mesh.bottom_radius = 0.05
	mesh.height = 0.22
	body_mesh.mesh = mesh
	var glass := StandardMaterial3D.new()
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color = Color(0.28, 0.62, 0.22, 0.65)
	glass.metallic = 0.02
	glass.roughness = 0.06
	glass.clearcoat_enabled = true
	glass.clearcoat = 0.9
	body_mesh.set_surface_override_material(0, glass)
	body.add_child(body_mesh)

	var cork_mesh := MeshInstance3D.new()
	cork_mesh.name = "Cork"
	cork_mesh.position = Vector3(0.0, 0.135, 0.0)
	var cork := CylinderMesh.new()
	cork.top_radius = 0.022
	cork.bottom_radius = 0.022
	cork.height = 0.05
	cork_mesh.mesh = cork
	var cork_mat := StandardMaterial3D.new()
	cork_mat.albedo_color = Color(0.45, 0.3, 0.16, 1.0)
	cork_mat.roughness = 0.95
	cork_mesh.set_surface_override_material(0, cork_mat)
	body.add_child(cork_mesh)


func _add_board_mesh(body: RigidBody3D) -> void:
	var board := BOARD_SCENE.instantiate()
	board.transform = Transform3D(
		Vector3(0.0070611243, 0, 0.34992877),
		Vector3(0, 0.35, 0),
		Vector3(-0.34992877, 0, 0.0070611243),
		Vector3(0, 0.27618384, 0)
	)
	body.add_child(board)
