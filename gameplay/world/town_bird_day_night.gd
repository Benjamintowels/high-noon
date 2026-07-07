extends Node
class_name TownBirdDayNight

## Matches stage ambient audio so birds leave when night ambience starts
## and return when the bird chorus fades back in at dawn.

var _is_night := false


func _ready() -> void:
	_is_night = DayNightCycle.is_night_time()
	_apply_to_all_birds(_is_night, true)
	DayNightCycle.cycle_progress_changed.connect(_on_cycle_changed)


func _exit_tree() -> void:
	if DayNightCycle.cycle_progress_changed.is_connected(_on_cycle_changed):
		DayNightCycle.cycle_progress_changed.disconnect(_on_cycle_changed)


func _on_cycle_changed(_progress: float) -> void:
	var want_night := DayNightCycle.is_night_time()
	if want_night == _is_night:
		return
	_is_night = want_night
	_apply_to_all_birds(want_night, false)


func _apply_to_all_birds(night: bool, instant: bool) -> void:
	for node in get_tree().get_nodes_in_group("ground_bird"):
		if not is_instance_valid(node):
			continue
		if night:
			if node.has_method("roost_for_night"):
				node.call("roost_for_night", instant)
		elif node.has_method("return_at_dawn"):
			node.call("return_at_dawn", instant)
