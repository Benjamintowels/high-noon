class_name GroyperArmAimModifier
extends SkeletonModifier3D

## Runs arm draw/aim IK after AnimationTree so poses are not overwritten.

var apply_overrides: Callable = Callable()


func _process_modification_with_delta(delta: float) -> void:
	if apply_overrides.is_valid():
		apply_overrides.call(delta)
