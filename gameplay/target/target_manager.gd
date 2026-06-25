extends Node

signal match_finished(player_won: bool)

enum Phase { INTRO, COUNTDOWN, ACTIVE, ROUND_RESULT, MATCH_RESULT }

const DUELIST_SCENE := preload("res://characters/groyper/groyper_duelist.tscn")
const OVERLAY_SCENE := preload("res://gameplay/duel/duel_overlay.tscn")
const TARGET_RANGE_SCRIPT := preload("res://gameplay/target/target_range.gd")
const COUNTDOWN_SECONDS := 5
const ROUND_DURATION := 10.0
const ROUND_RESULT_HOLD := 1.5
const INTRO_DELAY := 1.2
const SHOT_COOLDOWN := 0.38

var _overlay: CanvasLayer
var _player: Node3D
var _rival: Node3D
var _arena_root: Node3D
var _target_range: Node3D
var _phase := Phase.INTRO
var _countdown_left := COUNTDOWN_SECONDS
var _countdown_timer := 0.0
var _round_timer := 0.0
var _active_timer := 0.0
var _player_wins := 0
var _rival_wins := 0
var _round_number := 1
var _player_hits := 0
var _rival_hits := 0
var _active := false


func _ready() -> void:
	set_process(false)


func start_match(player: Node3D, arena_root: Node3D) -> void:
	_player = player
	_arena_root = arena_root
	_player_wins = 0
	_rival_wins = 0
	_round_number = 1
	_active = true
	set_process(true)

	if _overlay == null:
		_overlay = OVERLAY_SCENE.instantiate()
		add_child(_overlay)
		_overlay.continue_requested.connect(_on_continue_requested)

	_setup_arena()
	_spawn_rival()
	_prepare_participants_for_round()
	_begin_intro()


func _process(delta: float) -> void:
	if not _active:
		return

	match _phase:
		Phase.INTRO:
			_round_timer -= delta
			if _round_timer <= 0.0:
				_begin_countdown()
		Phase.COUNTDOWN:
			_countdown_timer -= delta
			if _countdown_timer <= 0.0:
				_countdown_left -= 1
				if _countdown_left > 0:
					_overlay.show_countdown(_countdown_left)
					_countdown_timer = 1.0
				else:
					_begin_active_phase()
		Phase.ACTIVE:
			_active_timer = maxf(_active_timer - delta, 0.0)
			_overlay.show_target_timer(_active_timer)
			if _active_timer <= 0.0:
				_resolve_round()
		Phase.ROUND_RESULT:
			_round_timer -= delta
			if _round_timer <= 0.0:
				_advance_after_round()
		_:
			pass


func _setup_arena() -> void:
	if _target_range != null:
		_target_range.queue_free()

	_target_range = Node3D.new()
	_target_range.name = "TargetRange"
	_target_range.set_script(TARGET_RANGE_SCRIPT)
	_arena_root.add_child(_target_range)
	_target_range.build(_round_number)

	for scorable in _target_range.get_scorables():
		if scorable.has_signal("scored") and not scorable.scored.is_connected(_on_target_scored):
			scorable.scored.connect(_on_target_scored)


func _spawn_rival() -> void:
	if _rival != null:
		_rival.queue_free()
		_rival = null

	_rival = DUELIST_SCENE.instantiate()
	_arena_root.add_child(_rival)
	_rival.add_to_group("target_rival")
	if _rival.has_method("enable_target_mode"):
		_rival.enable_target_mode(true)


func _prepare_participants_for_round() -> void:
	_player_hits = 0
	_rival_hits = 0

	if _round_number > 1:
		_respawn_participants()
		_rebuild_targets()

	_position_participants()
	_reset_participant_round_state()


func _respawn_participants() -> void:
	var stage := get_tree().current_scene
	if stage != null and stage.has_method("respawn_duel_player"):
		_player = stage.respawn_duel_player()
		_player.add_to_group("target_player")
		if _player.has_method("enable_target_mode"):
			_player.enable_target_mode(true)

	if _rival != null:
		_rival.queue_free()
	_spawn_rival()


func _rebuild_targets() -> void:
	for scorable in _target_range.get_scorables():
		if is_instance_valid(scorable):
			scorable.queue_free()
	_target_range.build(_round_number)
	for scorable in _target_range.get_scorables():
		if scorable.has_signal("scored") and not scorable.scored.is_connected(_on_target_scored):
			scorable.scored.connect(_on_target_scored)
	if _rival != null and _rival.has_method("set_target_objects"):
		_rival.set_target_objects(_target_range.get_scorables())


func _position_participants() -> void:
	var forward_y: float = _target_range.get_shooter_forward_rotation_y()
	_player.global_position = _target_range.get_player_spawn_position()
	_player.rotation.y = forward_y
	_player.add_to_group("target_player")
	if _player.has_method("sync_stance_anchor"):
		_player.sync_stance_anchor()

	_rival.global_position = _target_range.get_rival_spawn_position()
	_rival.rotation.y = forward_y


func _reset_participant_round_state() -> void:
	if _player.has_method("prepare_for_target_round"):
		_player.prepare_for_target_round()
	if _rival.has_method("prepare_for_target_round"):
		_rival.prepare_for_target_round()
	if _rival.has_method("set_target_objects"):
		_rival.set_target_objects(_target_range.get_scorables())


func _begin_intro() -> void:
	_phase = Phase.INTRO
	_countdown_left = COUNTDOWN_SECONDS
	_countdown_timer = 0.0
	_round_timer = INTRO_DELAY
	_set_player_prep(false)
	_set_player_shoot(false)
	if _overlay != null:
		_overlay.show_target_intro(_round_number)
		_overlay.update_target_score(_player_wins, _rival_wins, _player_hits, _rival_hits)
		_overlay.hide_match_end()
	if _is_match_point():
		_overlay.show_match_point_fx()


func _begin_countdown() -> void:
	_phase = Phase.COUNTDOWN
	_countdown_left = COUNTDOWN_SECONDS
	_countdown_timer = 0.0
	_set_player_prep(true)
	_overlay.show_countdown(_countdown_left)


func _begin_active_phase() -> void:
	_phase = Phase.ACTIVE
	_active_timer = ROUND_DURATION
	_set_player_prep(false)
	_set_player_shoot(true)
	_overlay.show_target_timer(_active_timer)
	_overlay.update_target_score(_player_wins, _rival_wins, _player_hits, _rival_hits)

	if _rival != null and _rival.has_method("begin_target_sequence"):
		_rival.begin_target_sequence()


func _resolve_round() -> void:
	if _phase == Phase.ROUND_RESULT or _phase == Phase.MATCH_RESULT:
		return

	_phase = Phase.ROUND_RESULT
	_set_player_prep(false)
	_set_player_shoot(false)
	if _rival != null and _rival.has_method("stop_target_sequence"):
		_rival.stop_target_sequence()

	var message := ""
	if _player_hits > _rival_hits:
		_player_wins += 1
		message = "You win the round! (%d - %d hits)" % [_player_hits, _rival_hits]
	elif _rival_hits > _player_hits:
		_rival_wins += 1
		message = "Foe wins the round. (%d - %d hits)" % [_rival_hits, _player_hits]
	else:
		message = "Tie round. (%d hits each)" % _player_hits

	_overlay.show_round_result(message)
	_overlay.update_target_score(_player_wins, _rival_wins, _player_hits, _rival_hits)
	_round_timer = ROUND_RESULT_HOLD


func _advance_after_round() -> void:
	if _player_wins >= GameState.ROUNDS_TO_WIN or _rival_wins >= GameState.ROUNDS_TO_WIN:
		_begin_match_result()
		return

	_round_number += 1
	_prepare_participants_for_round()
	_begin_intro()


func _begin_match_result() -> void:
	_phase = Phase.MATCH_RESULT
	_active = false
	set_process(false)

	var player_won := _player_wins >= GameState.ROUNDS_TO_WIN
	_overlay.show_match_end(
		"High Noon is yours." if player_won else "Better luck next draw.",
		player_won
	)
	match_finished.emit(player_won)


func _on_target_scored(scorer_id: String) -> void:
	if _phase != Phase.ACTIVE:
		return

	if scorer_id == "player":
		_player_hits += 1
	elif scorer_id == "enemy":
		_rival_hits += 1

	_overlay.update_target_score(_player_wins, _rival_wins, _player_hits, _rival_hits)


func _set_player_prep(allowed: bool) -> void:
	if _player != null and _player.has_method("set_target_prep_allowed"):
		_player.set_target_prep_allowed(allowed)


func _set_player_shoot(allowed: bool) -> void:
	if _player != null and _player.has_method("set_target_shoot_allowed"):
		_player.set_target_shoot_allowed(allowed)


func _is_match_point() -> bool:
	var points_to_win := GameState.ROUNDS_TO_WIN - 1
	return _player_wins == points_to_win or _rival_wins == points_to_win


func _on_continue_requested() -> void:
	match_finished.emit(_player_wins >= GameState.ROUNDS_TO_WIN)
