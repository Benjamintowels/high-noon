extends GroyperTownNpc
class_name ClerkNpc

signal dialog_finished

const CLERK_MAX_HEALTH := 10
const WHITE_HAT_COLOR := Color(0.94, 0.94, 0.92)

@export var speaker_name := "Shopkeeper"
@export var dialog_lines: PackedStringArray = PackedStringArray([
	"Howdy! Let me know what you need",
])

@onready var _interact_area: Area3D = $InteractArea

var _counter_hold_position := Vector3.ZERO
var _counter_hold_active := true
var _talking := false
var _player_in_range: Node3D
var _dialog_voice_player: AudioStreamPlayer3D


func _on_actor_ready() -> void:
	_faction_id = FactionIds.NEUTRAL
	equipped_weapon_id = GroyperWeapons.Id.SHOTGUN
	_health = CLERK_MAX_HEALTH
	random_hat_color = false
	wear_hat = true
	hat_color = WHITE_HAT_COLOR
	faction_on_sight_aggro_range = 0.0
	_counter_hold_position = global_position
	_counter_hold_active = true

	super._on_actor_ready()

	remove_from_group("becker_boys")
	remove_from_group("town_groyper")
	add_to_group("clerk")
	add_to_group("shop_keeper")

	_interact_area.body_entered.connect(_on_interact_body_entered)
	_interact_area.body_exited.connect(_on_interact_body_exited)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_clamp_to_counter_hold()
	if _talking and _player_in_range != null and _counter_hold_active:
		_face_toward(_player_in_range.global_position, delta)


func _process(_delta: float) -> void:
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

	DialogManager.show_dialog_sequence(
		dialog_lines,
		func() -> void:
			_end_dialog(player),
		speaker_name,
		func(_line_index: int) -> void:
			_play_gropyptalk()
	)


func get_interact_hint() -> String:
	return "Talk"


func get_voice_world_position() -> Vector3:
	return global_position + Vector3(0.0, 1.45, 0.0)


func set_faction_aggro_level(level: int, target: Node3D = null, play_alert_voice := true) -> void:
	if level >= 3:
		_release_counter_hold()
	super.set_faction_aggro_level(level, target, play_alert_voice)


func _update_faction_aggro(delta: float) -> void:
	super._update_faction_aggro(delta)
	if _defeated or _combat_active or _faction_aggro_level != 2:
		return
	_update_clerk_level_two_aggro(delta)


func _update_clerk_level_two_aggro(delta: float) -> void:
	var player := _find_player()
	var threatening := (
		player != null
		and _is_player_weapon_threatening_target(player, self)
	)
	if threatening:
		_faction_threat_lost_timer = 0.0
		_faction_aggro_entered_timer += delta
		if _aim_target == null:
			_aim_target = player
		if _ai_state != AiState.STARING:
			_saved_ai_state = _ai_state
			_ai_state = AiState.STARING
			_velocity_zero()
		_tick_faction_escalation(delta, 3)
		return

	_faction_threat_lost_timer += delta
	if _faction_threat_lost_timer >= FACTION_THREAT_LOST_GRACE:
		set_faction_aggro_level(0)


func enter_combat(player: Node3D) -> void:
	if _counter_hold_active and _faction_aggro_level < 3:
		if player != null:
			_aim_target = player
		return
	_release_counter_hold()
	super.enter_combat(player)


func _should_react_to_player_gun_threat() -> bool:
	return not _defeated


func _uses_faction_aggro() -> bool:
	return true


func _try_aggro_hostile_on_sight() -> bool:
	return false


func _check_faction_ally_draw_support() -> void:
	pass


func _check_faction_aimed_at_response() -> void:
	if _faction_aggro_level != 1:
		return

	var player := _find_player()
	if player == null:
		return
	if _faction_aggro_entered_timer < FACTION_STARE_BEFORE_DRAW_DELAY:
		return
	if player.has_method("is_weapon_aimed_at") and player.is_weapon_aimed_at(self, AIM_THREAT_RANGE):
		set_faction_aggro_level(2, player)


func _player_is_threatening_becker_boy(player: Node3D, include_self: bool = false) -> bool:
	if include_self:
		return _is_player_weapon_threatening_target(player, self)
	return false


func _react_to_hostile_shooter(
	shooter: Node3D,
	killed: bool,
	_hit_info: Dictionary = {}
) -> void:
	if shooter == null or not is_instance_valid(shooter):
		return
	if not shooter.is_in_group("overworld_player"):
		return

	_release_counter_hold()
	_ensure_overworld_combat_for_target(shooter)
	if not killed:
		set_faction_aggro_level(maxi(_faction_aggro_level, 3), shooter)


func _begin_walk() -> void:
	if _counter_hold_active:
		_state_timer = randf_range(idle_duration_min, idle_duration_max)
		return
	super._begin_walk()


func _release_counter_hold() -> void:
	_counter_hold_active = false


func _clamp_to_counter_hold() -> void:
	if not _counter_hold_active or _defeated:
		return
	global_position = _counter_hold_position
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
	dialog_finished.emit()


func _play_gropyptalk() -> void:
	_stop_dialog_voice()
	var stream := GameAudio.pick_gropyptalk_voice()
	if stream == null:
		return

	_dialog_voice_player = AudioStreamPlayer3D.new()
	_dialog_voice_player.name = "ClerkDialogVoice"
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
