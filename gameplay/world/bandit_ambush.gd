extends Node
class_name BanditAmbush

const BANDIT_SCENE := preload("res://characters/groyper/groyper_bandit_npc.tscn")
const PLAYER_SPEAKER := "Groyper"

const SPAWN_OFFSETS: Array[Vector3] = [
	Vector3(-2.5, 0.0, 0.0),
	Vector3(2.5, 0.0, 0.0),
	Vector3(0.0, 0.0, -2.5),
]

const NARRATION_LINES: PackedStringArray = [
	"What was that all about?",
	"There's a Town up ahead probably where my Uncle is",
]

const CHECK_INTERVAL := 0.35
const DEFAULT_HOLD_HALF_EXTENTS := Vector2(10.0, 10.0)

var _bandits: Array[GroyperBanditNpc] = []
var _player: Node3D
var _ambush_area: Area3D
var _hold_center := Vector3.ZERO
var _hold_half_extents := DEFAULT_HOLD_HALF_EXTENTS
var _ambush_triggered := false
var _cinematic_playing := false
var _narration_playing := false
var _check_timer: Timer


func setup(marker: Marker3D, player: Node3D) -> void:
	if BanditAmbushProgress.completed or marker == null:
		return

	_player = player
	_setup_ambush_area(marker)
	_spawn_bandits(marker)
	call_deferred("_configure_bandit_holds")
	_start_death_watch()
	call_deferred("_check_player_already_in_area")


func _setup_ambush_area(marker: Marker3D) -> void:
	_ambush_area = marker.get_node_or_null("Area3D") as Area3D
	if _ambush_area == null:
		push_warning("BanditAmbush: missing Area3D on marker.")
		return

	_ambush_area.monitoring = true
	_ambush_area.monitorable = false
	_ambush_area.collision_layer = 0
	_ambush_area.collision_mask = 1
	if not _ambush_area.body_entered.is_connected(_on_ambush_area_entered):
		_ambush_area.body_entered.connect(_on_ambush_area_entered)

	var bounds := _compute_hold_bounds(_ambush_area)
	_hold_center = bounds.get("center", marker.global_position)
	_hold_half_extents = bounds.get("half_extents", DEFAULT_HOLD_HALF_EXTENTS)


func _compute_hold_bounds(area: Area3D) -> Dictionary:
	var shape_node := area.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node == null or shape_node.shape == null:
		return {
			"center": area.global_position,
			"half_extents": DEFAULT_HOLD_HALF_EXTENTS,
		}

	var shape := shape_node.shape
	var shape_center := shape_node.global_position
	shape_center.y = area.global_position.y

	if shape is SphereShape3D:
		var radius := (shape as SphereShape3D).radius
		return {
			"center": shape_center,
			"half_extents": Vector2(radius, radius),
		}

	if shape is BoxShape3D:
		var box := shape as BoxShape3D
		var half := box.size * 0.5
		return {
			"center": shape_center,
			"half_extents": Vector2(half.x, half.z),
		}

	return {
		"center": shape_center,
		"half_extents": DEFAULT_HOLD_HALF_EXTENTS,
	}


func _spawn_bandits(marker: Marker3D) -> void:
	var spawn_parent := marker.get_parent()
	for offset in SPAWN_OFFSETS:
		var bandit: GroyperBanditNpc = BANDIT_SCENE.instantiate()
		spawn_parent.add_child(bandit)
		bandit.global_position = marker.global_position + marker.global_transform.basis * offset
		bandit.global_rotation = marker.global_rotation
		_bandits.append(bandit)


func _configure_bandit_holds() -> void:
	for bandit in _bandits:
		if not is_instance_valid(bandit):
			continue
		bandit.configure_ambush_hold(_hold_center, _hold_half_extents)


func _check_player_already_in_area() -> void:
	if _ambush_triggered or _ambush_area == null or _player == null:
		return
	for body in _ambush_area.get_overlapping_bodies():
		if body == _player:
			_begin_ambush()
			return


func _on_ambush_area_entered(body: Node3D) -> void:
	if _ambush_triggered or body == null or body != _player:
		return
	_begin_ambush()


func _begin_ambush() -> void:
	if _ambush_triggered:
		return
	_ambush_triggered = true

	GameAudio.play_raid_drama_start(self)
	for bandit in _bandits:
		if is_instance_valid(bandit):
			bandit.begin_ambush_stare(_player)

	_show_ambush_cinematic()


func _show_ambush_cinematic() -> void:
	if _player == null or not _player.has_method("get_raid_hud"):
		_release_bandits()
		return

	var hud: RaidHud = _player.get_raid_hud()
	if hud == null:
		_release_bandits()
		return

	_cinematic_playing = true
	hud.show_ambush_start(func() -> void:
		_on_ambush_cinematic_finished()
	)


func _on_ambush_cinematic_finished() -> void:
	_cinematic_playing = false
	_release_bandits()


func _release_bandits() -> void:
	if _player == null:
		return

	for bandit in _bandits:
		if not is_instance_valid(bandit):
			continue
		bandit.release_ambush_hold()
		bandit.set_faction_aggro_level(3, _player)


func _start_death_watch() -> void:
	_check_timer = Timer.new()
	_check_timer.wait_time = CHECK_INTERVAL
	_check_timer.timeout.connect(_check_all_defeated)
	add_child(_check_timer)
	_check_timer.start()


func _check_all_defeated() -> void:
	if _narration_playing or _cinematic_playing or BanditAmbushProgress.completed:
		return
	if _bandits.is_empty():
		return

	for bandit in _bandits:
		if not is_instance_valid(bandit):
			continue
		if not bandit.is_defeated():
			return

	_play_narration()


func _play_narration() -> void:
	_narration_playing = true
	BanditAmbushProgress.mark_completed()
	if _check_timer != null:
		_check_timer.stop()

	if _player != null and _player.has_method("set_dialog_active"):
		_player.set_dialog_active(true)

	DialogManager.show_dialog_sequence(
		NARRATION_LINES,
		func() -> void:
			_finish_narration(),
		PLAYER_SPEAKER
	)


func _finish_narration() -> void:
	_narration_playing = false
	if _player != null and _player.has_method("set_dialog_active"):
		_player.set_dialog_active(false)
	if not InventoryMenuManager.is_open() and not TownMapManager.is_open():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
