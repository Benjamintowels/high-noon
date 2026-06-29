class_name ShellCasingFX
extends RefCounted

const BRASS_COLOR := Color(0.82, 0.62, 0.18, 1.0)
const SPARK_COLOR := Color(1.0, 0.88, 0.45, 1.0)


static func spawn_burst(
	parent: Node3D,
	origin: Transform3D,
	count: int = 6,
	stagger: float = 0.055
) -> void:
	if parent == null:
		return

	for i in count:
		var delay := float(i) * stagger
		if delay <= 0.0:
			_emit_single(parent, origin, i, count)
		else:
			var timer := parent.get_tree().create_timer(delay)
			timer.timeout.connect(
				func() -> void:
					if is_instance_valid(parent):
						_emit_single(parent, origin, i, count)
			)


static func _emit_single(parent: Node3D, origin: Transform3D, index: int, total: int) -> void:
	var particles := CPUParticles3D.new()
	particles.one_shot = true
	particles.emitting = true
	particles.amount = 14
	particles.lifetime = 0.55
	particles.explosiveness = 0.92

	var spread_angle := TAU * float(index) / float(maxi(total, 1))
	var eject_dir := (
		origin.basis.x * cos(spread_angle)
		+ origin.basis.z * sin(spread_angle)
		+ origin.basis.y * 0.35
	).normalized()
	particles.direction = eject_dir
	particles.spread = 22.0
	particles.initial_velocity_min = 2.8
	particles.initial_velocity_max = 6.5
	particles.angular_velocity_min = -720.0
	particles.angular_velocity_max = 720.0
	particles.gravity = Vector3(0.0, -10.0, 0.0)
	particles.scale_amount_min = 0.035
	particles.scale_amount_max = 0.07
	particles.color = BRASS_COLOR.lerp(SPARK_COLOR, randf_range(0.0, 0.35))

	parent.add_child(particles)
	particles.global_transform = origin
	particles.finished.connect(particles.queue_free)

	var spark := CPUParticles3D.new()
	spark.one_shot = true
	spark.emitting = true
	spark.amount = 6
	spark.lifetime = 0.18
	spark.explosiveness = 1.0
	spark.direction = eject_dir
	spark.spread = 18.0
	spark.initial_velocity_min = 1.5
	spark.initial_velocity_max = 4.0
	spark.gravity = Vector3(0.0, -6.0, 0.0)
	spark.scale_amount_min = 0.02
	spark.scale_amount_max = 0.04
	spark.color = SPARK_COLOR
	parent.add_child(spark)
	spark.global_transform = origin
	spark.finished.connect(spark.queue_free)
