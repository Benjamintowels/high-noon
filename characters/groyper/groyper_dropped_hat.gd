extends RigidBody3D
class_name GroyperDroppedHat

## Cowboy hat knocked loose on duel defeat — tumbles off the head with physics.

const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")
const GroyperBodyUtils := preload("res://characters/groyper/groyper_body_utils.gd")

const HAT_PROP_GROUP := &"duel_hat_prop"
const WORLD_PICKUP_GROUP := &"world_hat_pickup"
const REST_VELOCITY := 0.12
const REST_FRAMES_NEEDED := 10
const PICKUP_RADIUS := 1.25
const FLOOR_FEET_OFFSET := 0.06
const FLOOR_PROXIMITY := 0.18
const LASSO_FALL_TIMEOUT := 1.6

@export var knockback_force := 1.4
@export var knockback_torque := 1.8
@export var upward_bias := 0.25
@export var hit_radius := 0.18

var _rest_frames := 0
var _hat_id := &""
var _pickup_enabled := false
var _picked_up := false
var _interact_area: Area3D
var _player_in_range: Node3D
var _drop_anchor := Vector3.ZERO
var _use_drop_anchor := false
var _lasso_collectible := false
var _lasso_fall_time := 0.0


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
	body.can_sleep = false
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


func setup_as_collectible(hat_id: StringName, drop_anchor: Vector3 = Vector3.ZERO) -> void:
	_hat_id = hat_id
	_lasso_collectible = true
	linear_damp = 0.45
	angular_damp = 0.75
	gravity_scale = 1.6
	if drop_anchor != Vector3.ZERO:
		_drop_anchor = drop_anchor
		_use_drop_anchor = true
	add_to_group(WORLD_PICKUP_GROUP)


func get_interact_hint() -> String:
	if not _pickup_enabled or _picked_up or _hat_id.is_empty():
		return ""
	if PlayerInventory.owns_hat(_hat_id):
		return "Pick up %s" % PlayerInventory.get_hat_display_name(_hat_id)
	return "Take %s" % PlayerInventory.get_hat_display_name(_hat_id)


func interact(player: Node3D) -> void:
	if not _pickup_enabled or _picked_up or player == null or _hat_id.is_empty():
		return

	PlayerInventory.add_hat(_hat_id)
	_picked_up = true
	if _player_in_range != null and _player_in_range.has_method("unregister_interactable"):
		_player_in_range.unregister_interactable(self)
	queue_free()


func _enable_pickup() -> void:
	if _pickup_enabled or _picked_up or _hat_id.is_empty():
		return
	_pickup_enabled = true

	_interact_area = Area3D.new()
	_interact_area.name = "InteractArea"
	_interact_area.collision_layer = 0
	_interact_area.collision_mask = 1
	_interact_area.monitorable = false
	add_child(_interact_area)

	var shape_node := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = PICKUP_RADIUS
	shape_node.shape = sphere
	_interact_area.add_child(shape_node)

	_interact_area.body_entered.connect(_on_interact_body_entered)
	_interact_area.body_exited.connect(_on_interact_body_exited)


func _on_interact_body_entered(body: Node3D) -> void:
	if _picked_up or not _pickup_enabled:
		return
	if body is CharacterBody3D and body.has_method("register_interactable"):
		_player_in_range = body
		body.register_interactable(self)


func _on_interact_body_exited(body: Node3D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		if body.has_method("unregister_interactable"):
			body.unregister_interactable(self)


static func _add_actor_collision_exceptions(body: RigidBody3D, actor: Node3D) -> void:
	if actor == null:
		return

	if actor is CollisionObject3D:
		body.add_collision_exception_with(actor)

	for node: CollisionObject3D in actor.find_children("*", "CollisionObject3D", true, false):
		body.add_collision_exception_with(node)


func get_bullet_hit_center() -> Vector3:
	return global_position + Vector3.UP * 0.04


func get_bullet_hit_radius() -> float:
	return hit_radius


func _physics_process(delta: float) -> void:
	if freeze:
		set_physics_process(false)
		return

	if _lasso_collectible:
		_lasso_fall_time += delta
		_clamp_above_floor()
		if _lasso_fall_time >= LASSO_FALL_TIMEOUT:
			_force_settle()
			return

	var motion := linear_velocity.length() + angular_velocity.length()
	var on_floor := _is_near_floor()

	if motion < REST_VELOCITY and (on_floor or not _lasso_collectible):
		_rest_frames += 1
	else:
		_rest_frames = 0

	if _rest_frames >= REST_FRAMES_NEEDED:
		_force_settle()


func _force_settle() -> void:
	if freeze:
		return
	freeze = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	set_physics_process(false)
	_finalize_world_placement()
	if not _hat_id.is_empty():
		_enable_pickup()


func _finalize_world_placement() -> void:
	var pos := global_position
	if _use_drop_anchor:
		pos.x = lerpf(global_position.x, _drop_anchor.x, 0.82)
		pos.z = lerpf(global_position.z, _drop_anchor.z, 0.82)
	global_position = _snap_position_to_floor(pos)


func _snap_position_to_floor(pos: Vector3) -> Vector3:
	var world := get_world_3d()
	if world == null:
		return pos
	return GroyperBodyUtils.snap_position_to_floor(world, pos, FLOOR_FEET_OFFSET)


func _is_near_floor() -> bool:
	var floor_pos := _snap_position_to_floor(global_position)
	return absf(global_position.y - floor_pos.y) <= FLOOR_PROXIMITY


func _clamp_above_floor() -> void:
	var floor_pos := _snap_position_to_floor(global_position)
	if global_position.y < floor_pos.y:
		global_position.y = floor_pos.y
		if linear_velocity.y < 0.0:
			linear_velocity.y = 0.0


func _apply_launch_impulse(hit_info: Dictionary) -> void:
	var direction: Vector3 = hit_info.get("direction", Vector3.FORWARD).normalized()
	var hit_position: Vector3 = hit_info.get("position", global_position)
	var offset := hit_position - global_position
	var power := float(hit_info.get("impulse_scale", 1.0))
	var lasso_drop := bool(hit_info.get("lasso_hat_drop", false))

	var horizontal := Vector3(direction.x, 0.0, direction.z)
	if horizontal.length_squared() > 0.0001:
		horizontal = horizontal.normalized()
	else:
		horizontal = Vector3.FORWARD

	var launch := horizontal * knockback_force + Vector3.UP * upward_bias
	if lasso_drop:
		launch = horizontal * knockback_force * 0.18 + Vector3.UP * 0.55
	launch *= power
	apply_impulse(launch, offset)
	apply_torque_impulse(
		Vector3(
			randf_range(-0.6, 0.6),
			randf_range(-0.6, 0.6),
			randf_range(-0.6, 0.6)
		).normalized() * knockback_torque * (power * 0.65)
	)


func apply_bullet_hit(hit_info: Dictionary) -> void:
	if freeze:
		freeze = false
		_rest_frames = 0
		_lasso_fall_time = 0.0
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
