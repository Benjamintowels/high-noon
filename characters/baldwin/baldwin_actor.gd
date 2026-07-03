extends GroyperActor
class_name BaldwinActor

## Meshy crusader biped — shares physics and rig utilities with Groyper.

## Extra yaw baked into the merged Baldwin mesh bind (degrees). Tune in editor tests.
const MESH_YAW_CORRECTION_DEG := 0.0


func _ready() -> void:
	_ensure_scene_nodes()
	GroyperBodyUtils.configure_ground_physics(self)
	_apply_baldwin_model_baseline()
	_bind_rig()
	_reset_rig_transform()
	_on_actor_ready()


func _bind_rig() -> void:
	var model := _get_model()
	if model == null:
		push_error("BaldwinActor: missing Model node.")
		return
	_body = model.get_node("BaldwinRig/Body") as Node3D
	if _body == null:
		push_error("BaldwinActor: missing BaldwinRig/Body.")
		return
	_skeleton = GroyperBodyUtils.find_skeleton(_body)
	_animation_player = GroyperBodyUtils.find_animation_player(_body)
	if _animation_player == null:
		push_error("BaldwinActor: missing AnimationPlayer on body.")


func _get_model() -> Node3D:
	if _model != null:
		return _model
	return get_node_or_null("Model") as Node3D


func _apply_baldwin_model_baseline() -> void:
	var model := _get_model()
	if model == null:
		return
	model.position.y = GroyperBodyUtils.ACTOR_MODEL_Y
	model.rotation = Vector3.ZERO
	model.rotation.y = GroyperBodyUtils.MODEL_YAW_OFFSET + deg_to_rad(MESH_YAW_CORRECTION_DEG)


func _reset_rig_transform() -> void:
	var model := _get_model()
	if model == null:
		return
	var rig := model.get_node_or_null("BaldwinRig") as Node3D
	if rig != null:
		rig.transform = Transform3D.IDENTITY


func get_model_facing_yaw_for_direction(direction: Vector3) -> float:
	var world_yaw := GroyperBodyUtils.facing_yaw_for_direction(direction)
	return world_yaw - global_rotation.y
