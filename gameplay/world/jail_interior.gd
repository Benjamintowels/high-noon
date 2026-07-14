extends Node3D
## Jail interior root. The sheriff only stands in here during the town-intro
## arrest cutscene — once that's completed he is back on his town beat, so
## later visits load the jail with just the deputies.


func _ready() -> void:
	if TownIntroProgress.completed:
		var sheriff := get_node_or_null("JailSheriff")
		if sheriff != null:
			sheriff.queue_free()
