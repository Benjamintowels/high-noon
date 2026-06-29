extends GroyperTownNpc
class_name GroyperBanditNpc

const BANDIT_HAT_COLOR := Color(0.72, 0.18, 0.14)

@export var aggro_range := 18.0


func _ready() -> void:
	random_hat_color = false
	hat_color = BANDIT_HAT_COLOR
	add_to_group("bandit")
	super._ready()


func get_faction_id() -> StringName:
	return FactionIds.BANDITS


func _update_threat_stare() -> void:
	if _faction_standoff_active:
		return
	if _combat_active or _defeated:
		return

	var player := _find_player()
	if player == null:
		if _ai_state == AiState.STARING:
			_resume_peaceful_ai()
		return

	if global_position.distance_to(player.global_position) <= aggro_range:
		enter_combat(player)
	elif _ai_state == AiState.STARING:
		_resume_peaceful_ai()
