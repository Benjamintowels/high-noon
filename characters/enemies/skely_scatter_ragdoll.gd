extends SkelyRagdoll
class_name SkelyScatterRagdoll

## Procedural skeleton death — limbs tumble apart without PhysicalBone3D (safe on scaled rigs).

var _scatter_rng := RandomNumberGenerator.new()


func _ready() -> void:
	super._ready()
	_scatter_rng.randomize()


func _reset_limb_simulation(hit_info: Dictionary) -> void:
	_limb_angles.clear()
	_limb_velocities.clear()

	var shot_direction: Vector3 = hit_info.get("direction", Vector3.FORWARD).normalized()
	var side_sign := 1.0
	if _skeleton != null and shot_direction.length_squared() > 0.0001:
		side_sign = 1.0 if shot_direction.dot(_skeleton.global_transform.basis.x) >= 0.0 else -1.0

	for bone_name in LIMB_SIM_BONES:
		var scatter_dir := Vector3(
			_scatter_rng.randf_range(-1.0, 1.0),
			_scatter_rng.randf_range(-0.2, 1.0),
			_scatter_rng.randf_range(-1.0, 1.0)
		)
		if shot_direction.length_squared() > 0.0001:
			scatter_dir = (scatter_dir + shot_direction * 0.85).normalized()
		else:
			scatter_dir = scatter_dir.normalized()

		var spin_strength := _scatter_rng.randf_range(5.0, 11.0)
		var kick := Vector3(
			scatter_dir.x * spin_strength,
			scatter_dir.y * spin_strength * 0.75,
			scatter_dir.z * spin_strength
		)

		if bone_name.begins_with("Left"):
			kick.y *= -side_sign
			kick.z *= -side_sign
		elif bone_name.begins_with("Right"):
			kick.y *= side_sign
			kick.z *= side_sign

		_limb_angles[bone_name] = Vector3(
			_scatter_rng.randf_range(-0.8, 0.8),
			_scatter_rng.randf_range(-0.8, 0.8),
			_scatter_rng.randf_range(-0.8, 0.8)
		)
		_limb_velocities[bone_name] = kick


func _simulate_limbs(delta: float) -> void:
	if _lasso_settling:
		return

	var tumble := 1.0 + _fall_progress * 0.65
	for bone_name in LIMB_SIM_BONES:
		var angle: Vector3 = _limb_angles.get(bone_name, Vector3.ZERO)
		var velocity: Vector3 = _limb_velocities.get(bone_name, Vector3.ZERO)

		velocity.x += _fall_pitch_velocity * 0.35 * delta
		velocity += Vector3(
			_scatter_rng.randf_range(-3.0, 3.0),
			_scatter_rng.randf_range(-3.0, 3.0),
			_scatter_rng.randf_range(-3.0, 3.0)
		) * delta * tumble

		velocity *= exp(-0.65 * delta)
		angle += velocity * delta

		_limb_angles[bone_name] = angle
		_limb_velocities[bone_name] = velocity


func _get_limb_rest_angle(_bone_name: String, _strength: float, _cfg: Dictionary) -> Vector3:
	return Vector3.ZERO
