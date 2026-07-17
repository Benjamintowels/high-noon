extends RefCounted

## Distance-based camera shake for nearby players when anything explodes.

const DEFAULT_STRENGTH := 1.35
const RANGE_MULTIPLIER := 2.4


static func shake_nearby(
	source: Node,
	center: Vector3,
	radius: float,
	strength: float = DEFAULT_STRENGTH
) -> void:
	if source == null or radius <= 0.0 or strength <= 0.0:
		return
	var tree := source.get_tree()
	if tree == null:
		return

	var shake_range := radius * RANGE_MULTIPLIER
	for group_name: StringName in [&"overworld_player", &"player"]:
		for node in tree.get_nodes_in_group(group_name):
			if not (node is Node3D) or not node.has_method("apply_camera_shake"):
				continue
			var body := node as Node3D
			var distance := body.global_position.distance_to(center)
			if distance > shake_range:
				continue
			var falloff := 1.0 - clampf(distance / shake_range, 0.0, 1.0)
			node.apply_camera_shake(strength * lerpf(0.35, 1.0, falloff))
