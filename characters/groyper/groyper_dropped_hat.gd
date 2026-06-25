extends RigidBody3D
class_name GroyperDroppedHat

## Cowboy hat knocked loose on duel defeat — tumbles off the head with physics.

const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")

const HAT_PROP_GROUP := &"duel_hat_prop"
const REST_VELOCITY := 0.12
const REST_FRAMES_NEEDED := 10

@export var knockback_force := 1.4
@export var knockback_torque := 1.8
@export var upward_bias := 0.25
@export var hit_radius := 0.18

var _rest_frames := 0


static func launch_from_visual(
	hat_visual: Node3D,
	hit_info: Dictionary,
	world_parent: Node,
	actor: Node3D = null
) -> GroyperDroppedHat:
	if hat_visual == null or world_parent == null:
		return null

	var hat_global := hat_visual.global_transform
	var mount := hat_visual.get_parent()
	if mount != null:
		mount.remove_child(hat_visual)

	var body := GroyperDroppedHat.new()
	body.name = "DroppedCowboyHat"
	body.mass = 1.35
	body.gravity_scale = 1.25
	body.linear_damp = 1.4
	body.angular_damp = 1.1
	body.continuous_cd = true
	body.collision_layer = 1
	body.collision_mask = 1
	body.freeze = false
	body.sleeping = false
	body.add_to_group(HAT_PROP_GROUP)
	body.set_physics_process(true)

	var shape_node := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 0.17
	cylinder.height = 0.09
	shape_node.shape = cylinder
	shape_node.transform = Transform3D(Basis.IDENTITY, Vector3(0.0, 0.04, 0.0))
	body.add_child(shape_node)

	body.add_child(hat_visual)
	hat_visual.transform = Transform3D.IDENTITY
	world_parent.add_child(body)
	body.global_transform = hat_global

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


func get_bullet_hit_center() -> Vector3:
	return global_position + Vector3.UP * 0.04


func get_bullet_hit_radius() -> float:
	return hit_radius


func _physics_process(_delta: float) -> void:
	if freeze:
		set_physics_process(false)
		return

	var motion := linear_velocity.length() + angular_velocity.length()
	if motion < REST_VELOCITY:
		_rest_frames += 1
	else:
		_rest_frames = 0

	if _rest_frames >= REST_FRAMES_NEEDED:
		freeze = true
		set_physics_process(false)


func _apply_launch_impulse(hit_info: Dictionary) -> void:
	var direction: Vector3 = hit_info.get("direction", Vector3.FORWARD).normalized()
	var hit_position: Vector3 = hit_info.get("position", global_position)
	var offset := hit_position - global_position

	var launch := direction * knockback_force + Vector3.UP * upward_bias
	apply_impulse(launch, offset)
	apply_torque_impulse(
		Vector3(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		).normalized() * knockback_torque
	)


func apply_bullet_hit(hit_info: Dictionary) -> void:
	if freeze:
		freeze = false
		_rest_frames = 0
		set_physics_process(true)

	var hit_position: Vector3 = hit_info.get("position", global_position)
	var normal: Vector3 = hit_info.get("normal", Vector3.UP)
	var direction: Vector3 = hit_info.get("direction", Vector3.FORWARD)

	var offset := hit_position - global_position
	apply_impulse(direction * 0.8, offset)
	apply_torque_impulse(
		Vector3(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		).normalized() * 1.2
	)
	ImpactFXScript.spawn_metal_impact(self, hit_position, normal, direction)
