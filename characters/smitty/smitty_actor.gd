extends CharacterBody3D
class_name SmittyActor

@onready var _model: Node3D = $Model
@onready var _animation_tree: AnimationTree = $AnimationTree

var _body: Node3D
var _skeleton: Skeleton3D
var _animation_player: AnimationPlayer


func _ready() -> void:
	_ensure_scene_nodes()
	GroyperBodyUtils.configure_ground_physics(self)
	GroyperBodyUtils.apply_model_baseline(_model)
	_bind_rig()
	MeshyCharacterMaterials.apply_outdoor_skin(_body)
	_on_actor_ready()


func _ensure_scene_nodes() -> void:
	if _model == null:
		_model = get_node_or_null("Model") as Node3D
	if _animation_tree == null:
		_animation_tree = get_node_or_null("AnimationTree") as AnimationTree


func _on_actor_ready() -> void:
	pass


func _bind_rig() -> void:
	_body = _model.get_node("SmittyRig/Body") as Node3D
	_skeleton = GroyperBodyUtils.find_skeleton(_body)
	_animation_player = MeshyLocomotionUtils.find_body_animation_player(_body)


func snap_to_floor() -> void:
	GroyperBodyUtils.snap_character_to_floor(self)


func get_model_facing_yaw_for_direction(direction: Vector3) -> float:
	return MeshyLocomotionUtils.facing_yaw_for_direction(direction)
