extends Node
class_name BanditAmbush

const BANDIT_SCENE := preload("res://characters/groyper/groyper_bandit_npc.tscn")
const GROYPETTE_SCENE := preload("res://gameplay/world/groypette_ambush_captive.tscn")
const GameAudioScript := preload("res://gameplay/audio/game_audio.gd")

const PLAYER_SPEAKER := "Groyper"
const BANDIT_SPEAKER := "Bandit"
const GROYPETTE_SPEAKER := "Groypette"

const SPAWN_OFFSETS: Array[Vector3] = [
	Vector3(-2.5, 0.0, 0.0),
	Vector3(2.5, 0.0, 0.0),
	Vector3(0.0, 0.0, -2.5),
]

const VICTORY_LINES: PackedStringArray = [
	"What was that all about?",
	"There's a Town up ahead probably where my Uncle is",
]

const WARN_LINE := "Just keep movin' mister"
const FIGHT_LINE := "You should've left things alone"
const THANK_LINE := "Thank you Kindly"
const ESCORT_LINE := (
	"My Daddy's farm is not too farm away from here if you'd be so kind as to escort me home"
)
const ESCORT_YES_LINE := "Yay! This way"

const CHECK_INTERVAL := 0.35
const PROXIMITY_CHECK_INTERVAL := 0.2
const DEFAULT_HOLD_HALF_EXTENTS := Vector2(10.0, 10.0)
const PLAYER_WARN_RANGE := 14.0
const PLAYER_WARN_LEAVE_RANGE := 19.0

enum Phase {
	HARASSING,
	WARNED,
	MELEE_AGGRO,
	RESOLVED,
}

var _bandits: Array[GroyperBanditNpc] = []
var _groypette: GroypetteAmbushCaptive
var _player: Node3D
var _marker: Marker3D
var _ambush_area: Area3D
var _hold_center := Vector3.ZERO
var _hold_half_extents := DEFAULT_HOLD_HALF_EXTENTS
var _phase := Phase.HARASSING
var _warn_dialog_active := false
var _fight_dialog_active := false
var _victory_playing := false
var _check_timer: Timer
var _proximity_timer: Timer
var _home_markers: Array[Marker3D] = []


func setup(marker: Marker3D, player: Node3D) -> void:
	if BanditAmbushProgress.completed or marker == null:
		return

	_player = player
	_marker = marker
	_setup_hold_bounds(marker)
	_collect_home_markers()
	_spawn_groypette(marker)
	_spawn_bandits(marker)
	call_deferred("_configure_scene")
	_start_proximity_watch()
	_start_death_watch()


func _setup_hold_bounds(marker: Marker3D) -> void:
	_ambush_area = marker.get_node_or_null("Area3D") as Area3D
	if _ambush_area == null:
		_hold_center = marker.global_position
		_hold_half_extents = DEFAULT_HOLD_HALF_EXTENTS
		push_warning("BanditAmbush: missing Area3D on marker; using default hold bounds.")
		return

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


func _collect_home_markers() -> void:
	_home_markers.clear()
	var town := _get_town_node()
	if town == null:
		push_warning("BanditAmbush: could not find Town node for escort markers.")
		return
	var marker_names: PackedStringArray = [
		"GroypetteRunsHome5",
		"GroypetteRunsHome4",
		"GroypetteRunsHome3",
		"GroypetteRunsHome2",
		"GroypetteRunsHome",
	]
	for marker_name in marker_names:
		var home_marker := town.get_node_or_null(marker_name) as Marker3D
		if home_marker != null:
			_home_markers.append(home_marker)
		else:
			push_warning("BanditAmbush: missing escort marker %s under Town." % marker_name)


func _get_town_node() -> Node3D:
	if _marker == null:
		return null
	var town := _marker.get_node_or_null("../../..") as Node3D
	if town != null and town.name == "Town":
		return town
	var stage := _marker.get_tree().current_scene
	if stage == null:
		return null
	return stage.get_node_or_null("Town") as Node3D


func _spawn_groypette(marker: Marker3D) -> void:
	_groypette = GROYPETTE_SCENE.instantiate() as GroypetteAmbushCaptive
	var spawn_parent := marker.get_parent()
	spawn_parent.add_child(_groypette)
	_groypette.global_position = marker.global_position
	_groypette.global_rotation = marker.global_rotation


func _spawn_bandits(marker: Marker3D) -> void:
	var spawn_parent := marker.get_parent()
	for offset in SPAWN_OFFSETS:
		var bandit: GroyperBanditNpc = BANDIT_SCENE.instantiate()
		spawn_parent.add_child(bandit)
		bandit.global_position = marker.global_position + marker.global_transform.basis * offset
		bandit.global_rotation = marker.global_rotation
		_bandits.append(bandit)


func _configure_scene() -> void:
	for bandit in _bandits:
		if not is_instance_valid(bandit):
			continue
		bandit.configure_ambush_hold(_hold_center, _hold_half_extents)
		if _groypette != null:
			bandit.begin_harass_groypette(_groypette)
	if _groypette != null:
		_groypette.configure_ambush_captive(_bandits, _marker.global_position)
	if _ambush_area != null:
		_ambush_area.monitoring = true
		_ambush_area.monitorable = false
		if not _ambush_area.body_entered.is_connected(_on_ambush_area_entered):
			_ambush_area.body_entered.connect(_on_ambush_area_entered)
		var shape_node := _ambush_area.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if shape_node != null:
			shape_node.disabled = false


func _start_proximity_watch() -> void:
	_proximity_timer = Timer.new()
	_proximity_timer.wait_time = PROXIMITY_CHECK_INTERVAL
	_proximity_timer.timeout.connect(_check_player_proximity)
	add_child(_proximity_timer)
	_proximity_timer.start()


func _check_player_proximity() -> void:
	if _phase == Phase.RESOLVED or _player == null:
		return
	if ShopSession.is_inside_shop():
		return
	if _player.has_method("is_defeated") and _player.is_defeated():
		return
	if _fight_dialog_active or _warn_dialog_active or _victory_playing:
		return

	var offset := _player.global_position - _hold_center
	if absf(offset.y) > 12.0:
		return
	offset.y = 0.0
	var distance := offset.length()

	match _phase:
		Phase.HARASSING:
			if distance <= PLAYER_WARN_RANGE:
				_begin_player_warning()
		Phase.WARNED:
			if distance > PLAYER_WARN_LEAVE_RANGE:
				_deescalate_to_harassment()
			elif _player_pulled_gun():
				_begin_fight_dialog()
		Phase.MELEE_AGGRO:
			if _player_pulled_gun():
				_escalate_bandits_to_guns()


func _player_pulled_gun() -> bool:
	if _player == null:
		return false
	if _player.has_method("is_weapon_raised") and _player.is_weapon_raised():
		return true
	if _player.has_method("is_weapon_aimed_at"):
		for bandit in _bandits:
			if is_instance_valid(bandit) and not bandit.is_defeated():
				if _player.is_weapon_aimed_at(bandit, 48.0):
					return true
	return false


func _begin_player_warning() -> void:
	if _phase != Phase.HARASSING:
		return
	_phase = Phase.WARNED
	for bandit in _bandits:
		if is_instance_valid(bandit) and not bandit.is_defeated():
			bandit.begin_warn_player(_player)
	_play_warn_dialog()


func _play_warn_dialog() -> void:
	_warn_dialog_active = true
	_lock_player_dialog(true)
	_play_bandit_voice()
	DialogManager.show_dialog(
		BANDIT_SPEAKER,
		WARN_LINE,
		func() -> void:
			_warn_dialog_active = false
			_lock_player_dialog(false)
	)


func _deescalate_to_harassment() -> void:
	if _phase != Phase.WARNED:
		return
	_phase = Phase.HARASSING
	if _groypette != null:
		_groypette.resume_harassment()
	for bandit in _bandits:
		if is_instance_valid(bandit) and not bandit.is_defeated() and _groypette != null:
			bandit.end_warn_player(_groypette)


func _on_ambush_area_entered(body: Node3D) -> void:
	if _phase == Phase.RESOLVED or _fight_dialog_active:
		return
	if ShopSession.is_inside_shop():
		return
	if body == null or not body.is_in_group("overworld_player"):
		return
	_begin_fight_dialog()


func _begin_fight_dialog() -> void:
	if _phase == Phase.MELEE_AGGRO or _fight_dialog_active:
		return
	_phase = Phase.MELEE_AGGRO
	_fight_dialog_active = true
	_lock_player_dialog(true)
	_show_fight_drama_and_dialog()


func _show_fight_drama_and_dialog() -> void:
	GameAudio.play_raid_drama_start(self)
	var hud := _get_raid_hud()
	if hud != null and hud.has_method("show_drama_letterbox_in"):
		hud.show_drama_letterbox_in()
	_play_bandit_voice()
	DialogManager.show_dialog(
		BANDIT_SPEAKER,
		FIGHT_LINE,
		func() -> void:
			_on_fight_dialog_dismissed()
	)


func _on_fight_dialog_dismissed() -> void:
	_fight_dialog_active = false
	DialogManager.hide_dialog()
	var hud := _get_raid_hud()
	if hud != null and hud.has_method("hide_drama_letterbox"):
		hud.hide_drama_letterbox()
	_activate_melee_aggro()
	_lock_player_dialog(false)
	if _player != null and _player.has_method("enter_overworld_combat"):
		_player.enter_overworld_combat()
	if not InventoryMenuManager.is_open() and not TownMapManager.is_open():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _activate_melee_aggro() -> void:
	if _player == null:
		return
	var closest: GroyperBanditNpc = null
	var closest_dist_sq := INF
	for bandit in _bandits:
		if not is_instance_valid(bandit) or bandit.is_defeated():
			continue
		bandit.enter_melee_aggro(_player)
		var dist_sq := bandit.global_position.distance_squared_to(_player.global_position)
		if dist_sq < closest_dist_sq:
			closest_dist_sq = dist_sq
			closest = bandit
	if closest != null:
		closest.begin_melee_opening_rush()


func _escalate_bandits_to_guns() -> void:
	if _player == null:
		return
	for bandit in _bandits:
		if not is_instance_valid(bandit) or bandit.is_defeated():
			continue
		bandit.escalate_to_gun_aggro(_player)


func _start_death_watch() -> void:
	_check_timer = Timer.new()
	_check_timer.wait_time = CHECK_INTERVAL
	_check_timer.timeout.connect(_check_bandit_status)
	add_child(_check_timer)
	_check_timer.start()


func _check_bandit_status() -> void:
	if _phase == Phase.RESOLVED or _victory_playing:
		return

	var alive: Array[GroyperBanditNpc] = []
	for bandit in _bandits:
		if is_instance_valid(bandit) and not bandit.is_defeated():
			alive.append(bandit)

	if alive.is_empty():
		_play_victory_sequence()
		return

	if alive.size() == 1 and _player != null:
		alive[0].try_last_stand_gun_aggro(_player)


func _play_victory_sequence() -> void:
	if _victory_playing:
		return
	_victory_playing = true
	_phase = Phase.RESOLVED
	if _check_timer != null:
		_check_timer.stop()
	if _proximity_timer != null:
		_proximity_timer.stop()

	var hud := _get_raid_hud()
	if hud != null:
		if hud.has_method("show_drama_letterbox_in"):
			hud.show_drama_letterbox_in()
		if hud.has_method("show_success_fx"):
			hud.show_success_fx()

	_lock_player_dialog(true)
	DialogManager.show_dialog_sequence(
		VICTORY_LINES,
		func() -> void:
			_on_victory_dialog_finished(),
		PLAYER_SPEAKER
	)


func _on_victory_dialog_finished() -> void:
	var hud := _get_raid_hud()
	if hud != null and hud.has_method("hide_drama_letterbox"):
		hud.hide_drama_letterbox()
	if _groypette != null and _groypette.is_captive_alive():
		_groypette.begin_thank_player(_player, Callable())
		_play_groypette_thank_sequence()
	else:
		_finish_ambush()


func _play_groypette_thank_sequence() -> void:
	_groypette.play_flirty_line()
	await get_tree().create_timer(0.8).timeout
	_groypette.play_cute_line()
	await get_tree().create_timer(0.35).timeout
	_lock_player_dialog(true)
	DialogManager.show_dialog_sequence(
		PackedStringArray([THANK_LINE, ESCORT_LINE]),
		func() -> void:
			_show_escort_choice(),
		GROYPETTE_SPEAKER,
		func(_line_index: int) -> void:
			if _line_index == 0:
				_groypette.play_flirty_line()
			else:
				_groypette.play_cute_line()
	)


func _show_escort_choice() -> void:
	DialogManager.show_choices(
		PackedStringArray(["Yes", "No"]),
		func(choice_index: int) -> void:
			if choice_index == 0:
				_accept_escort()
			else:
				_decline_escort()
	)


func _accept_escort() -> void:
	_collect_home_markers()
	DialogManager.show_dialog(
		GROYPETTE_SPEAKER,
		ESCORT_YES_LINE,
		func() -> void:
			_groypette.play_cute_line()
			_groypette.begin_escort_home(_home_markers)
			_finish_ambush()
	)


func _decline_escort() -> void:
	DialogManager.hide_dialog()
	_groypette.begin_walk_away()
	_finish_ambush()


func _finish_ambush() -> void:
	_lock_player_dialog(false)
	if _player != null and _player.has_method("exit_overworld_combat"):
		_player.exit_overworld_combat()
	BanditAmbushProgress.mark_completed()
	if not InventoryMenuManager.is_open() and not TownMapManager.is_open():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _play_bandit_voice() -> void:
	var speaker: Node3D = _marker
	if not _bandits.is_empty():
		speaker = _bandits[0]
	var stream: AudioStream = GameAudioScript.pick_gropyptalk_voice()
	if stream != null:
		GameAudioScript.play_npc_voice(speaker, stream, speaker.global_position)


func _get_raid_hud() -> RaidHud:
	if _player != null and _player.has_method("get_raid_hud"):
		return _player.get_raid_hud()
	return null


func _lock_player_dialog(active: bool) -> void:
	if _player != null and _player.has_method("set_dialog_active"):
		_player.set_dialog_active(active)
