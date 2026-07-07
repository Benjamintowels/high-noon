extends CivilianNpc
class_name UncleToadNpc

@export var speaker_name := "Uncle Toad"

@onready var _interact_area: Area3D = $InteractArea

func _on_actor_ready() -> void:
	add_to_group("uncle_toad_npc")
	super._on_actor_ready()
	_interact_area.body_entered.connect(_on_interact_body_entered)
	_interact_area.body_exited.connect(_on_interact_body_exited)


func interact(player: Node3D) -> void:
	if _talking or _defeated or player == null:
		return

	_set_dialog_talking(true, player)
	_player_in_range = player
	if player.has_method("set_dialog_active"):
		player.set_dialog_active(true)

	if CivilWarQuest.accepted:
		_show_accepted_dialog(player)
	else:
		_show_recruitment_dialog(player)


func _show_recruitment_dialog(player: Node3D) -> void:
	DialogManager.show_dialog_sequence(
		PackedStringArray(["The Nation needs you son. Join the army today"]),
		func() -> void:
			DialogManager.show_choices(
				PackedStringArray(["Accept", "Deny"]),
				func(choice_index: int) -> void:
					if choice_index == 0:
						_on_player_accepted_quest(player)
					else:
						_on_player_denied_quest(player)
			),
		speaker_name,
		func(_line_index: int) -> void:
			_play_talk_voice()
	)


func _on_player_accepted_quest(player: Node3D) -> void:
	DialogManager.show_dialog_sequence(
		PackedStringArray(["Well how bout that? Train leaves first light tomorrow"]),
		func() -> void:
			CivilWarQuest.begin_quest()
			_end_player_dialog(player),
		speaker_name,
		func(_line_index: int) -> void:
			_play_talk_voice()
	)


func _on_player_denied_quest(player: Node3D) -> void:
	DialogManager.show_dialog_sequence(
		PackedStringArray(["Glory isn't for everyone I spose'"]),
		func() -> void:
			DialogManager.hide_dialog()
			_end_player_dialog(player),
		speaker_name,
		func(_line_index: int) -> void:
			_play_talk_voice()
	)


func _show_accepted_dialog(player: Node3D) -> void:
	DialogManager.show_dialog_sequence(
		PackedStringArray(["Train leaves first light tomorrow. Don't be late now."]),
		func() -> void:
			_end_player_dialog(player),
		speaker_name,
		func(_line_index: int) -> void:
			_play_talk_voice()
	)


func _on_defeated() -> void:
	if _player_in_range != null and _player_in_range.has_method("unregister_interactable"):
		_player_in_range.unregister_interactable(self)
	_player_in_range = null
	if _interact_area != null:
		_interact_area.monitoring = false
		_interact_area.monitorable = false


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _talking and _player_in_range != null:
		_face_position(_player_in_range.global_position, delta)


func _on_interact_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and body.has_method("register_interactable"):
		_player_in_range = body
		body.register_interactable(self)


func _on_interact_body_exited(body: Node3D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		if body.has_method("unregister_interactable"):
			body.unregister_interactable(self)
