extends GroyperTownNpc
class_name GroyperBanditNpc

const BANDIT_HAT_COLOR := Color(0.72, 0.18, 0.14)

@export var aggro_range := 18.0


func _ready() -> void:
	random_hat_color = false
	hat_color = BANDIT_HAT_COLOR
	faction_on_sight_aggro_range = aggro_range
	add_to_group("bandit")
	super._ready()


func get_faction_id() -> StringName:
	return FactionIds.BANDITS
