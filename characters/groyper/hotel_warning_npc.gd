extends GroyperTownNpc

var _intro_lines := PackedStringArray([
	"The Hotel people built this wall to keep out the wild",
	"The Wild still finds ways in regardless",
])
var _followup_lines := PackedStringArray([
	"Before you know it, there ain't gonna be a wilderness",
])

@export var speaker_name := "Townsperson"

@onready var _interact_area: Area3D = $InteractArea

var _hold_position := Vector3.ZERO
var _hold_active := true
var _hold_captured := false
var _talking := false
var _told_warning := false
var _player_in_range: Node3D
var _dialog_voice_player: AudioStreamPlayer3D


func _on_actor_ready() -> void:
	_hold_active = true
	_hold_captured = false

	super._on_actor_ready()

	_interact_area.body_entered.connect(_on_interact_body_entered)
	_interact_area.body_exited.connect(_on_interact_body_exited)
	# TownNpcSpawn sets global_transform after add_child/_ready, and the
	# base townsperson snaps to the floor in a deferred finalize. Capture after.
	call_deferred("_capture_hold_position")


func _capture_hold_position() -> void:
	_hold_position = global_position
	_hold_captured = true


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_clamp_to_hold()
	if _talking and _player_in_range != null and _hold_active:
		_face_toward(_player_in_range.global_position, delta)


func _process(delta: float) -> void:
	super._process(delta)
	if (
		_dialog_voice_player == null
		or not is_instance_valid(_dialog_voice_player)
		or not _dialog_voice_player.playing
	):
		return
	_dialog_voice_player.global_position = get_voice_world_position()


func interact(player: Node3D) -> void:
	if _talking or player == null or _defeated:
		return

	_talking = true
	velocity = Vector3.ZERO
	_player_in_range = player

	if player.has_method("set_dialog_active"):
		player.set_dialog_active(true)

	var lines := _followup_lines if _told_warning else _intro_lines
	DialogManager.show_dialog_sequence(
		lines,
		func() -> void:
			_told_warning = true
			_end_dialog(player),
		speaker_name,
		func(_line_index: int) -> void:
			_play_gropyptalk()
	)


func get_interact_hint() -> String:
	return "Talk"


func get_voice_world_position() -> Vector3:
	return global_position + Vector3(0.0, 1.45, 0.0)


func enter_combat(player: Node3D) -> void:
	_release_hold()
	super.enter_combat(player)


func _begin_walk() -> void:
	if _hold_active:
		_state_timer = randf_range(idle_duration_min, idle_duration_max)
		return
	super._begin_walk()


func _update_peaceful_horse_patrol(_delta: float) -> void:
	if _hold_active:
		return
	super._update_peaceful_horse_patrol(_delta)


func _release_hold() -> void:
	_hold_active = false


func _clamp_to_hold() -> void:
	if not _hold_active or not _hold_captured or _defeated:
		return
	global_position = _hold_position
	velocity = Vector3.ZERO


func _face_toward(target_pos: Vector3, delta: float) -> void:
	var flat_target := Vector3(target_pos.x, global_position.y, target_pos.z)
	var to_target := flat_target - global_position
	if to_target.length_squared() < 0.0001:
		return
	var target_yaw := get_model_facing_yaw_for_direction(to_target.normalized())
	_model.rotation.y = lerp_angle(_model.rotation.y, target_yaw, FACING_SPEED * delta)


func _end_dialog(player: Node3D) -> void:
	_talking = false
	_stop_dialog_voice()
	if player != null and player.has_method("set_dialog_active"):
		player.set_dialog_active(false)


func _play_gropyptalk() -> void:
	_stop_dialog_voice()
	var stream := GameAudio.pick_gropyptalk_voice()
	if stream == null:
		return

	_dialog_voice_player = AudioStreamPlayer3D.new()
	_dialog_voice_player.name = "HotelWarningDialogVoice"
	_dialog_voice_player.stream = stream
	_dialog_voice_player.max_distance = 48.0
	_dialog_voice_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	_dialog_voice_player.unit_size = 2.0
	_dialog_voice_player.pitch_scale = randf_range(GameAudio.PITCH_MIN, GameAudio.PITCH_MAX)
	_dialog_voice_player.volume_db = randf_range(
		-GameAudio.VOLUME_JITTER_DB * 0.5,
		GameAudio.VOLUME_JITTER_DB * 0.5
	)
	add_child(_dialog_voice_player)
	_dialog_voice_player.global_position = get_voice_world_position()
	_dialog_voice_player.finished.connect(_on_dialog_voice_finished)
	_dialog_voice_player.play()


func _stop_dialog_voice() -> void:
	if _dialog_voice_player == null or not is_instance_valid(_dialog_voice_player):
		_dialog_voice_player = null
		return
	_dialog_voice_player.stop()
	_dialog_voice_player.queue_free()
	_dialog_voice_player = null


func _on_dialog_voice_finished() -> void:
	_dialog_voice_player = null


func _on_interact_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and body.has_method("register_interactable"):
		_player_in_range = body
		body.register_interactable(self)


func _on_interact_body_exited(body: Node3D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		if body.has_method("unregister_interactable"):
			body.unregister_interactable(self)
