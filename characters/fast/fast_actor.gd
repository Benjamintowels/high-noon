extends GroyperActor
class_name FastActor

## Meshy biped actor using the Fast body scene — shares locomotion/combat utils with Groyper.


func _bind_rig() -> void:
	_body = _model.get_node("FastRig/Body") as Node3D
	_skeleton = GroyperBodyUtils.find_skeleton(_body)
	_animation_player = GroyperBodyUtils.find_animation_player(_body)
