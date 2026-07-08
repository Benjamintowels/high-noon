extends Node
class_name SoloPracticeManager

const OVERLAY_SCENE := preload("res://gameplay/duel/duel_overlay.tscn")
const GroyperWeaponsScript := preload("res://characters/groyper/groyper_weapons.gd")
const SmokePuffFXScript := preload("res://gameplay/fx/smoke_puff_fx.gd")
const RevolverAmmoPickupScript := preload("res://gameplay/world/revolver_ammo_pickup.gd")

const COUNTDOWN_SECONDS := 3
const ROUND_DURATION := 20.0
const RESULT_HOLD := 2.0
const SUCCESS_RESULT_HOLD := 2.6
const SUCCESS_AMMO_REWARD := 6
const PLAYER_SPEAKER := "Groyper"

const TUTORIAL_LINES: PackedStringArray = [
	"Hold Right Click to aim your pistol.",
	"Left Click to fire.",
	"Press R to reload when you're empty.",
	"Knock down every target before time runs out!",
]

enum Phase { TUTORIAL, COUNTDOWN, ACTIVE, RESULT }

var _player: Node3D
var _fence: HomePracticeFence
var _spawn: Marker3D
var _overlay: CanvasLayer
var _phase := Phase.TUTORIAL
var _active := false
var _hits := 0
var _target_count := 0
var _countdown_left := COUNTDOWN_SECONDS
var _countdown_timer := 0.0
var _active_timer := 0.0
var _result_timer := 0.0


func _ready() -> void:
	set_process(false)


func is_active() -> bool:
	return _active


func request_start(fence: HomePracticeFence, player: Node3D) -> void:
	if _active or fence == null or player == null:
		return

	_fence = fence
	_player = player
	_active = true
	_hits = 0
	_phase = Phase.TUTORIAL
	set_process(true)

	if _player.has_method("set_dialog_active"):
		_player.set_dialog_active(true)

	DialogManager.show_dialog_sequence(
		TUTORIAL_LINES,
		func() -> void:
			_begin_countdown_setup(),
		PLAYER_SPEAKER
	)


func on_target_scored(scorer_id: String) -> void:
	if not _active or _phase != Phase.ACTIVE or scorer_id != "player":
		return

	_hits += 1
	_update_overlay_score()
	if _hits >= _target_count:
		_finish_round(true)


func _begin_countdown_setup() -> void:
	if _player != null and _player.has_method("set_dialog_active"):
		_player.set_dialog_active(false)

	_prepare_player()
	_prepare_targets()

	if _overlay == null:
		_overlay = OVERLAY_SCENE.instantiate()
		add_child(_overlay)

	_overlay.hide_match_end()
	_overlay.show_intro("Practice!")
	_update_overlay_score()
	_begin_countdown()


func _prepare_player() -> void:
	if _player == null:
		return

	if _spawn != null:
		_player.global_position = _spawn.global_position
		if _player.has_method("sync_overworld_spawn_orientation"):
			_player.sync_overworld_spawn_orientation()
		if _fence != null and _player.has_method("orient_toward_world_position"):
			_player.orient_toward_world_position(_fence.global_position)

	if _player.has_method("begin_practice_session"):
		_player.begin_practice_session()

	if _player.has_method("equip_weapon"):
		_player.equip_weapon(GroyperWeaponsScript.Id.REVOLVER, true)

	_player.add_to_group("target_player")


func _prepare_targets() -> void:
	if _fence == null:
		return
	var scorables := _fence.reset_scorable_targets()
	_target_count = scorables.size()


func _begin_countdown() -> void:
	_phase = Phase.COUNTDOWN
	_countdown_left = COUNTDOWN_SECONDS
	_countdown_timer = 0.0
	_overlay.show_countdown(_countdown_left)


func _begin_active_phase() -> void:
	_phase = Phase.ACTIVE
	_active_timer = ROUND_DURATION
	_overlay.show_target_timer(_active_timer)


func _finish_round(early: bool) -> void:
	if _phase == Phase.RESULT:
		return

	_phase = Phase.RESULT
	_result_timer = SUCCESS_RESULT_HOLD if early else RESULT_HOLD
	var message := "All targets down!" if early else "Time's up!"
	_overlay.show_round_result("%s  %d hits." % [message, _hits])
	if early:
		_play_success_reward()


func _play_success_reward() -> void:
	if _overlay != null and _overlay.has_method("show_success_fx"):
		_overlay.show_success_fx()

	if _fence == null:
		return

	var parent := _fence.get_parent()
	if parent == null:
		parent = _fence

	var from_pos := _fence.global_position + Vector3(0.0, 1.15, 0.15)
	SmokePuffFXScript.spawn_burst(parent, from_pos, 8)

	var toward := from_pos + Vector3(0.0, -0.8, 1.6)
	var keep_away := Vector3.INF
	if _player != null:
		keep_away = _player.global_position
		toward = _player.global_position
	elif _spawn != null:
		keep_away = _spawn.global_position
		toward = _spawn.global_position

	RevolverAmmoPickupScript.spawn_reward_drop(
		parent,
		from_pos,
		toward,
		SUCCESS_AMMO_REWARD,
		0.85,
		keep_away
	)


func _end_session() -> void:
	_active = false
	set_process(false)

	if _player != null:
		_player.remove_from_group("target_player")
		if _player.has_method("end_practice_session"):
			_player.end_practice_session()

	if _fence != null:
		_fence.restore_decorative_targets()

	if _overlay != null:
		_overlay.queue_free()
		_overlay = null
	_fence = null
	_player = null


func _update_overlay_score() -> void:
	if _overlay == null:
		return
	_overlay.update_target_score(0, 0, _hits, 0)


func configure_spawn(spawn: Marker3D) -> void:
	_spawn = spawn


func _process(delta: float) -> void:
	if not _active:
		return

	match _phase:
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
				_finish_round(false)
		Phase.RESULT:
			_result_timer -= delta
			if _result_timer <= 0.0:
				_end_session()
		_:
			pass
