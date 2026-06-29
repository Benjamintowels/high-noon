extends GroyperTownNpc
class_name GroyperTownsfolkNpc

const TOWNSFOLK_HAT_COLOR := Color(0.94, 0.94, 0.92)


func _ready() -> void:
	random_hat_color = false
	hat_color = TOWNSFOLK_HAT_COLOR
	super._ready()


func get_faction_id() -> StringName:
	return FactionIds.TOWNSPEOPLE
