class_name GroyperRagdollModifier
extends SkeletonModifier3D

## Applies defeat ragdoll poses after AnimationMixer — the only stage that wins in Godot 4.6.

var ragdoll: GroyperRagdoll


func _enter_tree() -> void:
	process_priority = 256
	influence = 1.0
	active = false


func _process_modification_with_delta(_delta: float) -> void:
	if ragdoll == null or not ragdoll.is_active():
		return
	ragdoll.apply_skeleton_poses()
