extends RigidBody3D
class_name GroyperDroppedRevolver

## Revolver knocked loose on duel defeat — tumbles like shootable props.

const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")

@export var knockback_force := 16.0
@export var knockback_torque := 9.0


static func launch_from_grip(
	grip: Node3D,
	hit_info: Dictionary,
	world_parent: Node,
	actor: Node3D = null
) -> GroyperDroppedRevolver:
	if grip == null or world_parent == null:
		return null

	var grip_global := grip.global_transform
	var mount := grip.get_parent()
	if mount != null:
		mount.remove_child(grip)

	var body := GroyperDroppedRevolver.new()
	body.name = "DroppedRevolver"
	body.mass = 0.85
	body.gravity_scale = 1.0
	body.linear_damp = 0.25
	body.angular_damp = 0.3
	body.continuous_cd = true
	body.collision_layer = 1
	body.collision_mask = 1
	body.freeze = false
	body.sleeping = false

	var shape_node := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.22, 0.08, 0.32)
	shape_node.shape = box
	shape_node.transform = Transform3D(Basis.IDENTITY, Vector3(0.0, 0.12, 0.0))
	body.add_child(shape_node)

	body.add_child(grip)
	grip.transform = Transform3D.IDENTITY
	world_parent.add_child(body)
	body.global_transform = grip_global

	_add_actor_collision_exceptions(body, actor)
	body._apply_launch_impulse(hit_info)
	return body


static func _add_actor_collision_exceptions(body: RigidBody3D, actor: Node3D) -> void:
	if actor == null:
		return

	for hitbox_name in ["DuelHitbox", "Hitbox"]:
		var hitbox := actor.get_node_or_null(hitbox_name) as CollisionObject3D
		if hitbox != null:
			body.add_collision_exception_with(hitbox)


func _apply_launch_impulse(hit_info: Dictionary) -> void:
	var direction: Vector3 = hit_info.get("direction", Vector3.FORWARD).normalized()
	var hit_position: Vector3 = hit_info.get("position", global_position)
	var offset := hit_position - global_position

	apply_impulse(direction * knockback_force, offset)
	apply_torque_impulse(
		Vector3(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		).normalized() * knockback_torque
	)


func apply_bullet_hit(hit_info: Dictionary) -> void:
	var hit_position: Vector3 = hit_info.get("position", global_position)
	var normal: Vector3 = hit_info.get("normal", Vector3.UP)
	var direction: Vector3 = hit_info.get("direction", Vector3.FORWARD)

	var offset := hit_position - global_position
	apply_impulse(direction * 4.5, offset)
	apply_torque_impulse(
		Vector3(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		).normalized() * 6.0
	)
	ImpactFXScript.spawn_metal_impact(self, hit_position, normal, direction)
