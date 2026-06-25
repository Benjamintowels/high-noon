extends RefCounted
class_name BlastRadiusFX

const FADE_DURATION := 0.55


static func spawn(parent: Node, center: Vector3, radius: float) -> void:
	if parent == null:
		return

	var root := Node3D.new()
	root.name = "BlastRadiusFX"
	parent.add_child(root)
	root.global_position = center

	_add_ground_ring(root, radius)
	_add_shock_sphere(root, radius)
	_add_vertical_column(root, radius)

	var tween := root.create_tween()
	tween.tween_interval(FADE_DURATION)
	tween.tween_callback(root.queue_free)


static func _add_ground_ring(root: Node3D, radius: float) -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = maxf(radius - 0.18, 0.05)
	torus.outer_radius = radius
	torus.rings = 18
	torus.ring_segments = 48
	ring.mesh = torus

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.55, 0.18, 0.55)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.45, 0.12)
	material.emission_energy_multiplier = 2.2
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	ring.material_override = material
	ring.scale = Vector3.ZERO
	root.add_child(ring)

	var tween := root.create_tween().set_parallel(true)
	tween.tween_property(ring, "scale", Vector3.ONE, 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_method(
		func(alpha: float) -> void:
			if is_instance_valid(material):
				material.albedo_color.a = alpha,
		0.55,
		0.0,
		FADE_DURATION
	).set_delay(0.08)


static func _add_shock_sphere(root: Node3D, radius: float) -> void:
	var sphere := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 24
	mesh.rings = 16
	sphere.mesh = mesh

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.72, 0.28, 0.14)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.5, 0.1)
	material.emission_energy_multiplier = 1.4
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	sphere.material_override = material
	sphere.scale = Vector3.ZERO
	root.add_child(sphere)

	var tween := root.create_tween().set_parallel(true)
	tween.tween_property(sphere, "scale", Vector3.ONE, 0.28) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_method(
		func(alpha: float) -> void:
			if is_instance_valid(material):
				material.albedo_color.a = alpha,
		0.14,
		0.0,
		FADE_DURATION
	).set_delay(0.04)


static func _add_vertical_column(root: Node3D, radius: float) -> void:
	var column := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.18
	mesh.bottom_radius = radius * 0.42
	mesh.height = radius * 1.6
	column.mesh = mesh
	column.position.y = mesh.height * 0.5

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.82, 0.45, 0.22)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.55, 0.15)
	material.emission_energy_multiplier = 1.8
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	column.material_override = material
	column.scale = Vector3(0.2, 0.1, 0.2)
	root.add_child(column)

	var tween := root.create_tween().set_parallel(true)
	tween.tween_property(column, "scale", Vector3.ONE, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_method(
		func(alpha: float) -> void:
			if is_instance_valid(material):
				material.albedo_color.a = alpha,
		0.22,
		0.0,
		FADE_DURATION * 0.85
	).set_delay(0.06)
