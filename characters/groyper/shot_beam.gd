extends Node3D

const BEAM_WIDTH := 0.028
const FADE_DURATION := 0.24


static func spawn(parent: Node, from: Vector3, to: Vector3) -> void:
	var delta := to - from
	var length := delta.length()
	if length < 0.05:
		return

	var direction := delta / length
	var beam := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(BEAM_WIDTH, BEAM_WIDTH, length)
	beam.mesh = box

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1.0, 0.98, 0.92, 1.0)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.95, 0.82)
	material.emission_energy_multiplier = 2.4
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam.material_override = material

	parent.add_child(beam)

	var up := Vector3.UP
	if absf(direction.dot(up)) > 0.95:
		up = Vector3.FORWARD
	beam.global_basis = Basis.looking_at(direction, up)
	beam.global_position = from + direction * (length * 0.5)

	var tween := beam.create_tween()
	tween.set_ignore_time_scale(true)
	tween.set_parallel(true)
	tween.tween_property(material, "albedo_color:a", 0.0, FADE_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(material, "emission_energy_multiplier", 0.0, FADE_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.finished.connect(beam.queue_free)
