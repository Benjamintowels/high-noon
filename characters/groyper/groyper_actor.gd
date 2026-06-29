extends CharacterBody3D
class_name GroyperActor

## Shared CharacterBody3D foundation for every walking groyper (NPCs + overworld player).
## Model placement, collision, and rig wiring live here — subclasses only add behavior.

@onready var _model: Node3D = $Model
@onready var _animation_tree: AnimationTree = $AnimationTree

var _body: Node3D
var _skeleton: Skeleton3D
var _animation_player: AnimationPlayer


func _ready() -> void:
	GroyperBodyUtils.apply_model_baseline(_model)
	_bind_rig()
	_on_actor_ready()


func _on_actor_ready() -> void:
	pass


func _bind_rig() -> void:
	_body = _model.get_node("GroyperRig/Body") as Node3D
	_skeleton = GroyperBodyUtils.find_skeleton(_body)
	_animation_player = GroyperBodyUtils.find_animation_player(_body)


func snap_to_floor() -> void:
	GroyperBodyUtils.snap_character_to_floor(self)
