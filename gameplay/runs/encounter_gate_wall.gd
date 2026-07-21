extends Node3D

## Blocking wall for a run encounter pocket. Present at run start; sinks into
## the ground when that pocket's first enemy pack is cleared.

const DEFAULT_SINK_DURATION := 1.65
const SINK_EXTRA_DEPTH := 0.35

@export var sink_duration := DEFAULT_SINK_DURATION

var _sunk := false
var _sinking := false


func _ready() -> void:
	add_to_group("encounter_gate_wall")


func is_sunk() -> bool:
	return _sunk or _sinking


func sink_into_ground(duration: float = -1.0) -> void:
	if _sunk or _sinking:
		return
	_sinking = true
	_disable_collision()
	var sink_by := _estimate_sink_depth()
	var seconds := sink_duration if duration < 0.0 else maxf(duration, 0.05)
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(
		self,
		"global_position:y",
		global_position.y - sink_by,
		seconds
	)
	tween.tween_callback(_finish_sink)


func _finish_sink() -> void:
	_sunk = true
	_sinking = false
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED


func _disable_collision() -> void:
	for child in find_children("*", "CollisionObject3D", true, false):
		var body := child as CollisionObject3D
		if body == null:
			continue
		body.collision_layer = 0
		body.collision_mask = 0


func _estimate_sink_depth() -> float:
	## Use the mesh's world-up extent so import rotation + instance scale both count.
	var height := 0.5
	if is_inside_tree():
		for child in find_children("*", "MeshInstance3D", true, false):
			var mi := child as MeshInstance3D
			if mi == null or mi.mesh == null:
				continue
			var world_aabb := mi.global_transform * mi.get_aabb()
			height = maxf(height, world_aabb.size.y)
			break
	else:
		height = maxf(absf(scale.y) * 0.154724, 0.5)
	return height + SINK_EXTRA_DEPTH
