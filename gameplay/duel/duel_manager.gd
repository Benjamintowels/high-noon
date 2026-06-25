extends Node

signal match_finished(player_won: bool)

enum Phase { INTRO, COUNTDOWN, SHOOT, RESOLVING, ROUND_RESULT, REPLAY, MATCH_RESULT }

const DUELIST_SCENE := preload("res://characters/groyper/groyper_duelist.tscn")
const OVERLAY_SCENE := preload("res://gameplay/duel/duel_overlay.tscn")
const REPLAY_SCRIPT := preload("res://gameplay/duel/duel_round_replay.gd")
const COUNTDOWN_SECONDS := 5
const ROUND_RESULT_HOLD := 1.0
const INTRO_DELAY := 1.2
const ROUND_STALEMATE_DELAY := 2.0
const DEFEATED_CALLBACK_META := &"duel_defeated_callback"
const DuelPacesScript := preload("res://gameplay/duel/duel_paces.gd")
const DuelStreetBoundsScript := preload("res://gameplay/duel/duel_street_bounds.gd")
const DEFAULT_PLAYER_SPAWN_PATH := NodePath("../Town/DuelLane/PlayerSpawn")

@export var enemy_spawn_path: NodePath = ^"../Town/DuelLane/EnemySpawn"

var _overlay: CanvasLayer
var _player: Node3D
var _enemy: Node3D
var _enemy_root: Node3D
var _phase := Phase.INTRO
var _countdown_left := COUNTDOWN_SECONDS
var _countdown_timer := 0.0
var _round_timer := 0.0
var _player_wins := 0
var _enemy_wins := 0
var _round_number := 1
var _player_hat_lost := false
var _enemy_hat_lost := false
var _player_faults := 0
var _active := false
var _player_spawn_path: NodePath
var _stalemate_timer := 0.0
var _replay: Node
var _fade_overlay: ColorRect
var _tumbleweed: Node3D


func _ready() -> void:
	set_process(false)


func preload_opponent(enemy_root: Node3D, player: Node3D) -> void:
	_enemy_root = enemy_root
	_player = player
	if _enemy == null:
		_spawn_enemy()
	if _enemy != null and _enemy.has_method("set_aim_target"):
		_enemy.set_aim_target(_player)
	if _enemy != null and _enemy.has_method("prepare_for_round"):
		_enemy.prepare_for_round()


func start_match(
	player: Node3D,
	enemy_root: Node3D,
	player_spawn_path: NodePath,
	opening_tumbleweed: Node3D = null
) -> void:
	_player = player
	_enemy_root = enemy_root
	_player_spawn_path = player_spawn_path
	_tumbleweed = opening_tumbleweed
	_player_wins = 0
	_enemy_wins = 0
	_round_number = 1
	_player_hat_lost = false
	_enemy_hat_lost = false
	_clear_world_dropped_hats()
	_active = true
	set_process(true)

	if _overlay == null:
		_overlay = OVERLAY_SCENE.instantiate()
		add_child(_overlay)
		_overlay.continue_requested.connect(_on_continue_requested)

	_setup_replay()

	_connect_participant(_player)
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
					_begin_shoot_phase()
		Phase.SHOOT:
			if _stalemate_timer > 0.0:
				_stalemate_timer = maxf(_stalemate_timer - delta, 0.0)
				if _stalemate_timer <= 0.0:
					_resolve_round("draw")
		Phase.ROUND_RESULT:
			_round_timer -= delta
			if _round_timer <= 0.0:
				_try_begin_replay()
		Phase.REPLAY:
			pass
		_:
			pass

	_update_enemy_aim_reticle()


func _begin_intro() -> void:
	_phase = Phase.INTRO
	_countdown_left = COUNTDOWN_SECONDS
	_countdown_timer = 0.0
	_round_timer = INTRO_DELAY
	_set_player_duel_prep(false)
	_set_player_duel_control(false)
	if _enemy != null and _enemy.has_method("set_duel_prep"):
		_enemy.set_duel_prep(false)
	if _overlay != null:
		_overlay.hide_enemy_aim_reticle()
	_overlay.show_intro(DuelPacesScript.pace_label_for_round(_round_number))
	_overlay.update_score(_player_wins, _enemy_wins, _round_number)
	_overlay.hide_match_end()
	if _is_match_point():
		_overlay.show_match_point_fx()


func _begin_countdown() -> void:
	_phase = Phase.COUNTDOWN
	_countdown_left = COUNTDOWN_SECONDS
	_countdown_timer = 0.0
	_set_player_duel_prep(true)
	_overlay.show_countdown(_countdown_left)


func _begin_shoot_phase() -> void:
	_dismiss_tumbleweed()
	_phase = Phase.SHOOT
	_overlay.show_shoot_callout()
	_set_player_duel_prep(false)
	_set_player_duel_control(true)

	if _enemy != null and _enemy.has_method("set_duel_prep"):
		_enemy.set_duel_prep(false)
	if _enemy != null and _enemy.has_method("begin_duel_sequence"):
		_enemy.begin_duel_sequence()

	if _replay != null and _replay.has_method("start_recording"):
		_replay.start_recording()


func _resolve_round(winner: String, result_message: String = "") -> void:
	if _phase == Phase.RESOLVING or _phase == Phase.ROUND_RESULT or _phase == Phase.MATCH_RESULT:
		return

	if _phase == Phase.INTRO or _phase == Phase.COUNTDOWN:
		_dismiss_tumbleweed()

	_phase = Phase.RESOLVING
	_set_player_duel_prep(false)
	_set_player_duel_control(false)
	if _enemy != null and _enemy.has_method("set_duel_prep"):
		_enemy.set_duel_prep(false)
	_stalemate_timer = 0.0

	if _overlay != null:
		_overlay.hide_enemy_aim_reticle()

	if result_message.is_empty():
		if winner == "player":
			_player_wins += 1
			_overlay.show_round_result("You win the round!")
		elif winner == "enemy":
			_enemy_wins += 1
			_overlay.show_round_result("Foe wins the round.")
		else:
			_overlay.show_round_result("Stalemate. Again.")
	else:
		if winner == "player":
			_player_wins += 1
		elif winner == "enemy":
			_enemy_wins += 1
		_overlay.show_round_result(result_message)

	_overlay.update_score(_player_wins, _enemy_wins, _round_number)
	_phase = Phase.ROUND_RESULT
	_round_timer = ROUND_RESULT_HOLD

	if _replay != null and _replay.has_method("finish_recording"):
		_replay.finish_recording()


func _dismiss_tumbleweed() -> void:
	if _tumbleweed != null and is_instance_valid(_tumbleweed):
		_tumbleweed.queue_free()
	_tumbleweed = null


func _begin_match_result() -> void:
	_dismiss_tumbleweed()
	_phase = Phase.MATCH_RESULT
	_active = false
	set_process(false)

	var player_won := _player_wins >= GameState.ROUNDS_TO_WIN
	_overlay.show_match_end(
		"High Noon is yours." if player_won else "Better luck next draw.",
		player_won
	)
	match_finished.emit(player_won)


func _spawn_enemy() -> void:
	var spawn := get_node_or_null(enemy_spawn_path) as Node3D
	if spawn == null:
		push_error("DuelManager: missing enemy spawn marker.")
		return

	_enemy = DUELIST_SCENE.instantiate()
	_enemy_root.add_child(_enemy)
	_apply_pace_positions()
	_enemy.rotation.y = 0.0
	if _player != null and _enemy.has_method("set_aim_target"):
		_enemy.set_aim_target(_player)


func _respawn_enemy() -> void:
	if _enemy != null:
		_disconnect_participant(_enemy)
		_enemy.queue_free()
		_enemy = null
	_spawn_enemy()
	_connect_participant(_enemy)


func _respawn_player() -> void:
	if _player != null:
		_disconnect_participant(_player)

	var stage := get_tree().current_scene
	if stage != null and stage.has_method("respawn_duel_player"):
		_player = stage.respawn_duel_player()
	else:
		return

	_connect_participant(_player)


func _prepare_participants_for_round() -> void:
	_player_faults = 0
	if _round_number > 1:
		_respawn_player()
		_respawn_enemy()
	elif _enemy == null:
		_spawn_enemy()
		_connect_participant(_enemy)
	else:
		_connect_participant(_enemy)

	_apply_match_hat_states()
	if _player != null and _player.has_method("prepare_for_duel_round"):
		_player.prepare_for_duel_round()
	if _enemy != null and _enemy.has_method("prepare_for_round"):
		_enemy.prepare_for_round()
	if _enemy != null and _player != null and _enemy.has_method("set_aim_target"):
		_enemy.set_aim_target(_player)

	_apply_pace_positions()
	_apply_pace_enemy_reaction()

	_refresh_replay_participants()


func _apply_match_hat_states() -> void:
	if _player != null and _player.has_method("apply_match_hat_state"):
		_player.apply_match_hat_state(_player_hat_lost)
	if _enemy != null and _enemy.has_method("apply_match_hat_state"):
		_enemy.apply_match_hat_state(_enemy_hat_lost)


func _clear_world_dropped_hats() -> void:
	for node in get_tree().get_nodes_in_group("duel_hat_prop"):
		if is_instance_valid(node):
			node.queue_free()


func _refresh_replay_participants() -> void:
	if _replay == null:
		return
	var stage := get_tree().current_scene
	if stage == null:
		return
	if _replay.has_method("setup"):
		_replay.setup(_player, _enemy, stage, _overlay, _fade_overlay)


func _connect_participant(participant: Node) -> void:
	if participant == null:
		return
	_disconnect_participant(participant)

	if participant.has_signal("defeated"):
		var defeated_cb := func(hit_info: Dictionary) -> void:
			_on_participant_defeated(participant, hit_info)
		participant.set_meta(DEFEATED_CALLBACK_META, defeated_cb)
		participant.defeated.connect(defeated_cb)
	if participant.has_signal("shot_fired") and not participant.shot_fired.is_connected(_on_enemy_shot_fired):
		participant.shot_fired.connect(_on_enemy_shot_fired)
	if participant.has_signal("duel_fault") and not participant.duel_fault.is_connected(_on_player_duel_fault):
		participant.duel_fault.connect(_on_player_duel_fault)
	if participant == _player and participant.has_signal("duel_yeller") \
			and not participant.duel_yeller.is_connected(_on_player_duel_yeller):
		participant.duel_yeller.connect(_on_player_duel_yeller)
	if participant == _player and participant.has_signal("duel_shot_fired") \
			and not participant.duel_shot_fired.is_connected(_on_player_duel_shot_fired):
		participant.duel_shot_fired.connect(_on_player_duel_shot_fired)
	if participant == _player and participant.has_signal("duel_rpg_launched") \
			and not participant.duel_rpg_launched.is_connected(_on_player_duel_rpg_launched):
		participant.duel_rpg_launched.connect(_on_player_duel_rpg_launched)


func _disconnect_participant(participant: Node) -> void:
	if participant == null:
		return
	if participant.has_meta(DEFEATED_CALLBACK_META):
		var defeated_cb: Callable = participant.get_meta(DEFEATED_CALLBACK_META)
		if participant.has_signal("defeated") and participant.defeated.is_connected(defeated_cb):
			participant.defeated.disconnect(defeated_cb)
		participant.remove_meta(DEFEATED_CALLBACK_META)
	if participant.has_signal("shot_fired") and participant.shot_fired.is_connected(_on_enemy_shot_fired):
		participant.shot_fired.disconnect(_on_enemy_shot_fired)
	if participant.has_signal("duel_fault") and participant.duel_fault.is_connected(_on_player_duel_fault):
		participant.duel_fault.disconnect(_on_player_duel_fault)
	if participant == _player and participant.has_signal("duel_yeller") \
			and participant.duel_yeller.is_connected(_on_player_duel_yeller):
		participant.duel_yeller.disconnect(_on_player_duel_yeller)
	if participant == _player and participant.has_signal("duel_shot_fired") \
			and participant.duel_shot_fired.is_connected(_on_player_duel_shot_fired):
		participant.duel_shot_fired.disconnect(_on_player_duel_shot_fired)
	if participant == _player and participant.has_signal("duel_rpg_launched") \
			and participant.duel_rpg_launched.is_connected(_on_player_duel_rpg_launched):
		participant.duel_rpg_launched.disconnect(_on_player_duel_rpg_launched)


func _on_enemy_shot_fired() -> void:
	if _phase != Phase.SHOOT:
		return
	_stalemate_timer = ROUND_STALEMATE_DELAY
	_record_enemy_shot_for_replay()


func _on_player_duel_shot_fired(from: Vector3, to: Vector3) -> void:
	if _phase != Phase.SHOOT or _replay == null:
		return
	if _replay.has_method("has_pending_rpg_launch") and _replay.has_pending_rpg_launch():
		if _replay.has_method("record_rpg_impact"):
			_replay.record_rpg_impact(from, to)
		return
	if _replay.has_method("record_shot"):
		_replay.record_shot(from, to)


func _on_player_duel_rpg_launched(from: Vector3, direction: Vector3) -> void:
	if _phase != Phase.SHOOT or _replay == null:
		return
	if _replay.has_method("record_rpg_launch"):
		_replay.record_rpg_launch(from, direction)


func _record_enemy_shot_for_replay() -> void:
	if _replay == null or _enemy == null:
		return
	if not _enemy.has_method("get_replay_shot_points"):
		return
	var points: Dictionary = _enemy.get_replay_shot_points()
	if points.is_empty():
		return
	if _replay.has_method("record_shot"):
		_replay.record_shot(points["from"], points["to"])


func _on_participant_defeated(participant: Node, hit_info: Dictionary) -> void:
	if _phase != Phase.SHOOT and _phase != Phase.RESOLVING:
		return

	if participant == _player:
		_player_hat_lost = true
	else:
		_enemy_hat_lost = true

	if _phase == Phase.SHOOT and _replay != null and _replay.has_method("record_impact"):
		var victim := "player" if participant == _player else "enemy"
		_replay.record_impact(victim, hit_info)

	var winner := "enemy" if participant == _player else "player"
	_resolve_round(winner)


func _set_player_duel_prep(prep_allowed: bool) -> void:
	if _player != null and _player.has_method("set_duel_prep_allowed"):
		_player.set_duel_prep_allowed(prep_allowed)


func _set_player_duel_control(shoot_allowed: bool) -> void:
	if _player != null and _player.has_method("set_duel_shoot_allowed"):
		_player.set_duel_shoot_allowed(shoot_allowed)


func _reset_player_after_fault() -> void:
	if _player != null and _player.has_method("prepare_for_duel_round"):
		_player.prepare_for_duel_round()
	if _player != null and _player.has_method("set_duel_prep_allowed"):
		_player.set_duel_prep_allowed(true)


func _on_player_duel_fault(_reason: String) -> void:
	if _phase != Phase.COUNTDOWN:
		return

	_player_faults += 1
	_set_player_duel_prep(false)

	if _player_faults >= 2:
		_overlay.show_fault("Two faults — foe wins the round.")
		_resolve_round("enemy")
		return

	_overlay.show_fault("Fault! Hands off your iron. (%d/2)" % _player_faults)
	_reset_player_after_fault()
	_begin_countdown()


func _on_player_duel_yeller() -> void:
	if _phase != Phase.SHOOT and _phase != Phase.COUNTDOWN:
		return
	_resolve_round("enemy", "Are you Yeller?")


func _on_continue_requested() -> void:
	match_finished.emit(_player_wins >= GameState.ROUNDS_TO_WIN)


func _update_enemy_aim_reticle() -> void:
	if _overlay == null or _enemy == null or _player == null:
		return

	if _phase == Phase.MATCH_RESULT or _phase == Phase.ROUND_RESULT or _phase == Phase.REPLAY or _phase == Phase.INTRO or _phase == Phase.COUNTDOWN:
		_overlay.hide_enemy_aim_reticle()
		return

	if _enemy.has_method("is_aim_reticle_visible") and not _enemy.is_aim_reticle_visible():
		_overlay.hide_enemy_aim_reticle()
		return

	if not _player.has_method("get_active_camera") or not _enemy.has_method("get_display_aim_point"):
		_overlay.hide_enemy_aim_reticle()
		return

	var camera: Camera3D = _player.get_active_camera()
	var urgency := 0.0
	if _enemy.has_method("get_aim_reticle_urgency"):
		urgency = _enemy.get_aim_reticle_urgency()
	_overlay.update_enemy_aim_reticle(_enemy.get_display_aim_point(), camera, urgency)


func _setup_replay() -> void:
	if _replay != null:
		return

	var stage := get_tree().current_scene
	if stage == null:
		return

	if stage.has_method("get_duel_fade_overlay"):
		_fade_overlay = stage.get_duel_fade_overlay()

	_replay = REPLAY_SCRIPT.new()
	_replay.name = "DuelRoundReplay"
	add_child(_replay)
	_replay.setup(_player, _enemy, stage, _overlay, _fade_overlay)


func _try_begin_replay() -> void:
	if _replay != null and _replay.has_method("has_content") and _replay.has_content():
		_phase = Phase.REPLAY
		_replay.play(_on_replay_finished)
		return
	_advance_after_round()


func _on_replay_finished() -> void:
	_advance_after_round()


func _advance_after_round() -> void:
	if _player_wins >= GameState.ROUNDS_TO_WIN or _enemy_wins >= GameState.ROUNDS_TO_WIN:
		_begin_match_result()
		return

	_round_number += 1
	_prepare_participants_for_round()
	_begin_intro()


func _is_match_point() -> bool:
	var points_to_win := GameState.ROUNDS_TO_WIN - 1
	return _player_wins == points_to_win or _enemy_wins == points_to_win


func _get_duel_lane_spawns() -> Dictionary:
	var player_spawn := get_node_or_null(DEFAULT_PLAYER_SPAWN_PATH) as Node3D
	var enemy_spawn := get_node_or_null(enemy_spawn_path) as Node3D
	return {"player": player_spawn, "enemy": enemy_spawn}


func _apply_pace_positions() -> void:
	var spawns := _get_duel_lane_spawns()
	var player_spawn: Node3D = spawns["player"]
	var enemy_spawn: Node3D = spawns["enemy"]
	if player_spawn == null or enemy_spawn == null:
		return

	var positions := DuelPacesScript.duel_positions_for_round(
		_round_number,
		player_spawn,
		enemy_spawn
	)
	if _player != null:
		_player.global_position = positions["player"]
		if _player.has_method("sync_stance_anchor"):
			_player.sync_stance_anchor()
	_apply_player_duel_street_bounds()
	if _enemy != null:
		_enemy.global_position = positions["enemy"]


func _apply_player_duel_street_bounds() -> void:
	if _player == null or not _player.has_method("set_duel_street_bounds"):
		return
	var stage := get_tree().current_scene
	var street := DuelStreetBoundsScript.find_street_in_scene(stage)
	var bounds := DuelStreetBoundsScript.bounds_from_street_node(street)
	if bounds.is_empty():
		return
	_player.set_duel_street_bounds(bounds["center"], bounds["half_width"])


func _apply_pace_enemy_reaction() -> void:
	if _enemy == null:
		return

	if _enemy.has_method("set_fire_delay_bounds"):
		var delays: Vector2 = DuelPacesScript.enemy_fire_delays_for_round(_round_number)
		_enemy.set_fire_delay_bounds(delays.x, delays.y)
	if _enemy.has_method("set_draw_delay_bounds"):
		var draw_delays: Vector2 = DuelPacesScript.enemy_draw_delays_for_round(_round_number)
		_enemy.set_draw_delay_bounds(draw_delays.x, draw_delays.y)
	if _enemy.has_method("set_aim_miss_chance"):
		_enemy.set_aim_miss_chance(
			DuelPacesScript.enemy_aim_miss_chance_for_round(_round_number)
		)
	if _enemy.has_method("set_pace_separation"):
		_enemy.set_pace_separation(DuelPacesScript.separation_for_round(_round_number))
