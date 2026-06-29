extends Node
class_name TownAggroVoice

const GameAudio := preload("res://gameplay/audio/game_audio.gd")

const AGGRO_VOICE_CHANCE := 0.3
const AGGRO_VOICE_WINDOW := 10.0
const AIMED_VOICE_CHANCE := 0.65
const AIMED_VOICE_DELAY_MIN := 0.12
const AIMED_VOICE_DELAY_MAX := 1.05
const AIMED_VOICE_COOLDOWN := 12.0

enum VoiceKind {
	WOAH,
	EASY_THERE,
	AGGRO,
	CHEER,
}

var _owner: Node3D
var _voice_player: AudioStreamPlayer3D
var _voice_generation := 0
var _voice_pending := false
var _aimed_voice_cooldown := 0.0


func setup(owner_node: Node3D) -> void:
	_owner = owner_node
	set_process(true)


func schedule_on_aggro() -> void:
	_schedule_voice(
		AGGRO_VOICE_CHANCE,
		randf_range(0.0, AGGRO_VOICE_WINDOW),
		VoiceKind.AGGRO
	)


func schedule_easy_there(
	chance: float = AIMED_VOICE_CHANCE,
	delay_max: float = AIMED_VOICE_DELAY_MAX
) -> void:
	_schedule_voice(chance, delay_max, VoiceKind.EASY_THERE)


func schedule_woah(
	delay_max: float = AIMED_VOICE_DELAY_MAX
) -> void:
	_schedule_voice(1.0, delay_max, VoiceKind.WOAH)


func play_woah_on_alert() -> void:
	schedule_woah()


func play_cheer() -> void:
	if _owner == null:
		return
	if _owner.has_method("is_defeated") and _owner.is_defeated():
		return

	var generation := _voice_generation
	var delay := randf_range(0.0, 1.25)
	var tree := _owner.get_tree()
	if tree == null:
		_play_cheer_voice()
		return

	var timer := tree.create_timer(delay)
	timer.timeout.connect(
		func() -> void:
			if generation != _voice_generation:
				return
			if _owner == null or not is_instance_valid(_owner):
				return
			if _owner.has_method("is_defeated") and _owner.is_defeated():
				return
			_play_cheer_voice()
	)


func _schedule_voice(chance: float, delay_max: float, voice_kind: VoiceKind) -> void:
	if _owner == null or _voice_pending:
		return
	if _aimed_voice_cooldown > 0.0:
		return
	if _voice_player != null and is_instance_valid(_voice_player) and _voice_player.playing:
		return
	if _owner.has_method("is_defeated") and _owner.is_defeated():
		return
	if randf() >= chance:
		return

	_voice_pending = true
	var generation := _voice_generation
	var delay := randf_range(AIMED_VOICE_DELAY_MIN, delay_max)
	var tree := _owner.get_tree()
	if tree == null:
		_voice_pending = false
		return

	var timer := tree.create_timer(delay)
	timer.timeout.connect(
		func() -> void:
			_voice_pending = false
			if generation != _voice_generation:
				return
			if _owner == null or not is_instance_valid(_owner):
				return
			if _owner.has_method("is_defeated") and _owner.is_defeated():
				return
			match voice_kind:
				VoiceKind.AGGRO:
					_play_aggro_voice()
				VoiceKind.EASY_THERE:
					_play_easy_there_voice()
				VoiceKind.WOAH:
					_play_woah_voice()
				VoiceKind.CHEER:
					_play_cheer_voice()
			_aimed_voice_cooldown = AIMED_VOICE_COOLDOWN
	)


func stop_for_death() -> void:
	_voice_generation += 1
	_voice_pending = false
	_stop_voice()


func _play_easy_there_voice() -> void:
	_play_voice_line(GameAudio.EASY_THERE_VOICE)


func _play_woah_voice() -> void:
	var stream: AudioStream = GameAudio.pick_woah_voice()
	if stream == null:
		return
	_play_voice_line(stream)


func _play_aggro_voice() -> void:
	var stream: AudioStream = GameAudio.pick_aggro_voice()
	if stream == null:
		return
	_play_voice_line(stream)


func _play_cheer_voice() -> void:
	var stream: AudioStream = GameAudio.pick_cheer_voice()
	if stream == null:
		return
	_play_voice_line(stream)


func _play_voice_line(stream: AudioStream) -> void:
	_stop_voice()
	if _owner == null:
		return

	_voice_player = AudioStreamPlayer3D.new()
	_voice_player.name = "AggroVoice"
	_voice_player.stream = stream
	_voice_player.max_distance = 48.0
	_voice_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	_voice_player.unit_size = 2.0
	_voice_player.pitch_scale = randf_range(GameAudio.PITCH_MIN, GameAudio.PITCH_MAX)
	_voice_player.volume_db = randf_range(
		-GameAudio.VOLUME_JITTER_DB * 0.5,
		GameAudio.VOLUME_JITTER_DB * 0.5
	)
	_owner.add_child(_voice_player)
	_voice_player.global_position = _get_voice_position()
	_voice_player.finished.connect(_on_voice_finished)
	_voice_player.play()


func _process(delta: float) -> void:
	_aimed_voice_cooldown = maxf(_aimed_voice_cooldown - delta, 0.0)
	if _owner == null or not is_instance_valid(_owner):
		_stop_voice()
		return
	if _voice_player == null or not is_instance_valid(_voice_player) or not _voice_player.playing:
		return
	_voice_player.global_position = _get_voice_position()


func _get_voice_position() -> Vector3:
	if _owner == null or not is_instance_valid(_owner):
		return Vector3.ZERO
	if _owner.has_method("get_voice_world_position"):
		return _owner.get_voice_world_position()
	return _owner.global_position + Vector3(0.0, 1.8, 0.0)


func _stop_voice() -> void:
	if _voice_player != null and is_instance_valid(_voice_player):
		_voice_player.stop()
		_voice_player.queue_free()
	_voice_player = null


func _on_voice_finished() -> void:
	_stop_voice()
