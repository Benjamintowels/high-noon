extends RefCounted
class_name BirdFacing

enum Facing { LEFT, RIGHT, FRONT, BACK }


static func classify(world_direction: Vector3, camera: Camera3D) -> Dictionary:
	var flat := Vector3(world_direction.x, 0.0, world_direction.z)
	if flat.length_squared() < 0.0001:
		return {"facing": Facing.FRONT, "flip_h": false}

	flat = flat.normalized()

	if camera == null:
		if absf(flat.x) >= absf(flat.z):
			if flat.x >= 0.0:
				return {"facing": Facing.RIGHT, "flip_h": false}
			return {"facing": Facing.LEFT, "flip_h": false}
		if flat.z >= 0.0:
			return {"facing": Facing.BACK, "flip_h": false}
		return {"facing": Facing.FRONT, "flip_h": false}

	var cam_basis := camera.global_transform.basis
	var cam_forward := -cam_basis.z
	cam_forward.y = 0.0
	if cam_forward.length_squared() < 0.0001:
		cam_forward = Vector3(0.0, 0.0, -1.0)
	else:
		cam_forward = cam_forward.normalized()

	var cam_right := cam_basis.x
	cam_right.y = 0.0
	if cam_right.length_squared() < 0.0001:
		cam_right = Vector3(1.0, 0.0, 0.0)
	else:
		cam_right = cam_right.normalized()

	var forward_amount := flat.dot(cam_forward)
	var right_amount := flat.dot(cam_right)

	if absf(forward_amount) >= absf(right_amount):
		if forward_amount >= 0.0:
			return {"facing": Facing.FRONT, "flip_h": false}
		return {"facing": Facing.BACK, "flip_h": false}

	if right_amount >= 0.0:
		return {"facing": Facing.RIGHT, "flip_h": false}
	return {"facing": Facing.RIGHT, "flip_h": true}


static func flee_direction(from_threat: Vector3, bird_position: Vector3) -> Vector3:
	var away := bird_position - from_threat
	away.y = 0.0
	if away.length_squared() < 0.01:
		var angle := randf() * TAU
		return Vector3(cos(angle), 0.0, sin(angle))
	return away.normalized()
