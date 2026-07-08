extends RefCounted
class_name PracticeTargetFactory

const TARGET_SCORABLE_SCRIPT := preload("res://gameplay/target/target_scorable.gd")
const BOARD_SCENE := preload("res://Assets/Guns/board.fbx")


static func create_scorable(style: String) -> RigidBody3D:
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


static func _add_can_mesh(body: RigidBody3D) -> void:
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


static func _add_bottle_mesh(body: RigidBody3D) -> void:
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


static func _add_board_mesh(body: RigidBody3D) -> void:
	var board := BOARD_SCENE.instantiate()
	board.transform = Transform3D(
		Vector3(0.0070611243, 0, 0.34992877),
		Vector3(0, 0.35, 0),
		Vector3(-0.34992877, 0, 0.0070611243),
		Vector3(0, 0.27618384, 0)
	)
	body.add_child(board)
