extends Node
class_name HomeAmbush
## Special scenario: after the player first visits home_interior, the next time
## they step outside into UnclesHome they are ambushed by seven bandits. The
## leader delivers a short cutscene, everyone aggroes, and when only one bandit
## remains he chickens out and flees. Completing this marks UncleMystery pt.1.

const BANDIT_SCENE := preload("res://characters/groyper/groyper_bandit_npc.tscn")
const FloatingEnemyHealthBarScript := preload("res://gameplay/ui/floating_enemy_health_bar.gd")
const GameAudioScript := preload("res://gameplay/audio/game_audio.gd")

const BANDIT_SPEAKER := "Bandit"
const ALERT_SYMBOL_HEIGHT := 2.1
const CHECK_INTERVAL := 0.35
const PROXIMITY_CHECK_INTERVAL := 0.25
const TRIGGER_RANGE := 42.0
## How far from the door exit spot the player must walk before the intro fires
## (keeps the cinematic camera out of the home exterior mesh).
const DOOR_CLEAR_DISTANCE := 3.0
const COWARD_FLEE_DURATION := 3.0
const CAMERA_RETURN_SECONDS := 0.9

const LEAD_LINES: PackedStringArray = [
	"Told yea he'd go back to his house",
	"Get him!",
]
const COWARD_LINE := "Forget this"

## Placement index → loadout. Leader is always index 0 (BanditScenePlacement1).
## 3 revolvers, 1 shotgun, 1 torch, 2 unarmed.
const LOADOUTS: Array[Dictionary] = [
	{"melee_only": false, "weapon": GroyperWeapons.Id.REVOLVER, "torch": false},
	{"melee_only": false, "weapon": GroyperWeapons.Id.REVOLVER, "torch": false},
	{"melee_only": false, "weapon": GroyperWeapons.Id.REVOLVER, "torch": false},
	{"melee_only": false, "weapon": GroyperWeapons.Id.SHOTGUN, "torch": false},
	{"melee_only": true, "weapon": GroyperWeapons.Id.UNARMED, "torch": true},
	{"melee_only": true, "weapon": GroyperWeapons.Id.UNARMED, "torch": false},
	{"melee_only": true, "weapon": GroyperWeapons.Id.UNARMED, "torch": false},
]

enum Phase {
	WAITING,
	INTRO,
	FIGHTING,
	COWARD_CUTSCENE,
	RESOLVED,
}

var _player: Node3D
var _uncles_home: Node3D
var _markers: Array[Marker3D] = []
var _bandits: Array[GroyperBanditNpc] = []
var _leader: GroyperBanditNpc
var _phase := Phase.WAITING
var _total_bandits := 0
var _proximity_timer: Timer
var _check_timer: Timer
var _coward_played := false
## True once we've seen the player inside a shop/interior after home_visited.
## Used to arm the ambush only on the subsequent exit outdoors.
var _saw_player_inside_home_visit := false
## Player position when they first stepped outdoors after the home visit.
## Ambush waits until they clear DOOR_CLEAR_DISTANCE from this spot.
var _exit_anchor := Vector3.ZERO
var _has_exit_anchor := false
## True while the amortized spawn coroutine is mid-flight; the trigger check
## keeps waiting instead of starting the intro on a half-spawned squad.
var _spawn_in_progress := false


func setup(player: Node3D, uncles_home: Node3D) -> void:
	_player = player
	_uncles_home = uncles_home
	if UncleMysteryQuest.is_part1_done():
		_phase = Phase.RESOLVED
		return
	if uncles_home == null:
		push_warning("HomeAmbush: missing UnclesHome root.")
		_phase = Phase.RESOLVED
		return

	_collect_markers()
	if _markers.is_empty():
		push_warning("HomeAmbush: no BanditScenePlacement markers under UnclesHome.")
		_phase = Phase.RESOLVED
		return

	# Save/reload outdoors after a prior home exit — already armed.
	if ShopSession.is_inside_shop() and UncleMysteryQuest.home_visited:
		_saw_player_inside_home_visit = true

	_start_proximity_watch()


func _collect_markers() -> void:
	_markers.clear()
	for i in range(1, 8):
		var marker := _uncles_home.get_node_or_null("BanditScenePlacement%d" % i) as Marker3D
		if marker == null:
			push_warning("HomeAmbush: missing BanditScenePlacement%d." % i)
			continue
		_markers.append(marker)


func _start_proximity_watch() -> void:
	_proximity_timer = Timer.new()
	_proximity_timer.wait_time = PROXIMITY_CHECK_INTERVAL
	_proximity_timer.timeout.connect(_check_trigger)
	add_child(_proximity_timer)
	_proximity_timer.start()


func _check_trigger() -> void:
	if _phase != Phase.WAITING:
		return
	if UncleMysteryQuest.is_part1_done():
		return
	if _player == null or not is_instance_valid(_player):
		return

	var inside := ShopSession.is_inside_shop()
	# Interior scenes load (and mark home_visited) while the player is still
	# outdoors during the door fade. Only arm after a real inside→outside exit.
	if inside:
		if UncleMysteryQuest.home_visited:
			_saw_player_inside_home_visit = true
		return

	if _saw_player_inside_home_visit and UncleMysteryQuest.home_visited:
		UncleMysteryQuest.arm_ambush_after_home_exit()
		_saw_player_inside_home_visit = false
		_capture_exit_anchor()
		_ensure_bandits_spawned()

	if not UncleMysteryQuest.is_ambush_primed():
		return
	# Save/reload while already primed outdoors — still need a walk-clear.
	if not _has_exit_anchor:
		_capture_exit_anchor()
	_ensure_bandits_spawned()
	if _player.has_method("is_defeated") and _player.is_defeated():
		return
	if DialogManager.is_showing():
		return

	# Wait until the player walks clear of the doorway so the cinematic
	# camera isn't buried in the home exterior.
	if _has_exit_anchor:
		var from_door := _player.global_position - _exit_anchor
		from_door.y = 0.0
		if from_door.length() < DOOR_CLEAR_DISTANCE:
			return

	var anchor := _markers[0].global_position if not _markers.is_empty() else _uncles_home.global_position
	var offset := _player.global_position - anchor
	if absf(offset.y) > 16.0:
		return
	offset.y = 0.0
	if offset.length() > TRIGGER_RANGE:
		return

	_begin_ambush()


func _capture_exit_anchor() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	_exit_anchor = _player.global_position
	_has_exit_anchor = true


func _ensure_bandits_spawned() -> void:
	if _spawn_in_progress or not _bandits.is_empty():
		return
	_spawn_in_progress = true
	_spawn_bandits_amortized()


func _begin_ambush() -> void:
	if _phase != Phase.WAITING:
		return

	_ensure_bandits_spawned()
	# Mid-spawn — stay WAITING; the proximity timer retries in 0.25s.
	if _spawn_in_progress:
		return

	_phase = Phase.INTRO
	if _proximity_timer != null:
		_proximity_timer.stop()

	if _bandits.is_empty() or _leader == null:
		_phase = Phase.RESOLVED
		return

	_lock_player_dialog(true)
	_play_intro_cutscene()


## One bandit per frame: instantiating seven full NPC scenes in one tick was a
## visible hitch right as the player stepped out the door. The door fade still
## covers the ~7 frames this takes.
func _spawn_bandits_amortized() -> void:
	_bandits.clear()
	_leader = null
	var count := mini(_markers.size(), LOADOUTS.size())
	for i in range(count):
		_spawn_one_bandit(i)
		if i < count - 1:
			await get_tree().process_frame
			if not is_inside_tree() or _uncles_home == null or not is_instance_valid(_uncles_home):
				_spawn_in_progress = false
				return
	_total_bandits = _bandits.size()
	_spawn_in_progress = false


func _spawn_one_bandit(i: int) -> void:
	var marker := _markers[i]
	var loadout: Dictionary = LOADOUTS[i]
	var bandit: GroyperBanditNpc = BANDIT_SCENE.instantiate()
	bandit.melee_only = bool(loadout.get("melee_only", false))
	if not bandit.melee_only:
		bandit.equipped_weapon_id = loadout.get("weapon", GroyperWeapons.Id.REVOLVER) as GroyperWeapons.Id
	bandit.add_to_group("bandit")
	_uncles_home.add_child(bandit)
	# NPC facing code assumes an unrotated root — never copy marker rotation.
	bandit.global_position = marker.global_position
	# Hold in place until the cutscene fires — no canyon on-sight yet.
	bandit.configure_ambush_hold(marker.global_position, Vector2(1.5, 1.5))
	FloatingEnemyHealthBarScript.attach_to(bandit)
	if bool(loadout.get("torch", false)) and bandit.has_method("equip_handheld_torch"):
		bandit.equip_handheld_torch()
	_bandits.append(bandit)
	if i == 0:
		_leader = bandit


func _play_intro_cutscene() -> void:
	GameAudioScript.play_raid_drama_start(self)
	var hud := _get_raid_hud()
	if hud != null:
		if hud.has_method("show_drama_letterbox_in"):
			hud.show_drama_letterbox_in()
		if hud.has_method("show_alert_title"):
			hud.show_alert_title("Ambush!")

	if _leader != null and _player != null and _player.has_method("begin_comet_cinematic_camera"):
		_player.begin_comet_cinematic_camera(_leader)

	_spawn_alert_on(_leader)
	_play_bandit_voice(_leader)

	DialogManager.show_dialog_sequence(
		LEAD_LINES,
		func() -> void:
			_on_intro_dismissed(),
		BANDIT_SPEAKER,
		func(line_index: int) -> void:
			_on_intro_line_shown(line_index)
	)


func _on_intro_line_shown(line_index: int) -> void:
	_play_bandit_voice(_leader)
	_spawn_alert_on(_leader)
	var hud := _get_raid_hud()
	if line_index == 0:
		if hud != null and hud.has_method("show_alert_title"):
			hud.show_alert_title("Ambush!")
	elif line_index == 1:
		for bandit in _bandits:
			_spawn_alert_on(bandit)
		if hud != null and hud.has_method("show_alert_title"):
			hud.show_alert_title("Get him!")


func _on_intro_dismissed() -> void:
	if _player != null and _player.has_method("begin_comet_cinematic_camera_exit"):
		_player.begin_comet_cinematic_camera_exit()
	await get_tree().create_timer(CAMERA_RETURN_SECONDS * 0.35).timeout
	if not is_inside_tree():
		return
	_start_fight()


func _start_fight() -> void:
	_phase = Phase.FIGHTING
	if _player != null and _player.has_method("end_comet_cinematic"):
		_player.end_comet_cinematic()

	var hud := _get_raid_hud()
	if hud != null:
		if hud.has_method("hide_drama_letterbox"):
			hud.hide_drama_letterbox()
		if hud.has_method("show_remaining_count"):
			hud.show_remaining_count(_total_bandits, "Ambush!")

	for bandit in _bandits:
		if not is_instance_valid(bandit) or bandit.is_defeated():
			continue
		if bandit.has_method("release_ambush_hold"):
			bandit.release_ambush_hold()
		_spawn_alert_on(bandit)
		if bandit.has_method("arm_canyon_hostility"):
			bandit.arm_canyon_hostility(_player)
		elif bandit.melee_only:
			bandit.enter_melee_aggro(_player)
		else:
			bandit.set_faction_aggro_level(3, _player)

	_lock_player_dialog(false)
	if _player != null and _player.has_method("enter_overworld_combat"):
		_player.enter_overworld_combat()
	if not InventoryMenuManager.is_open() and not TownMapManager.is_open():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	_start_death_watch()


func _start_death_watch() -> void:
	_check_timer = Timer.new()
	_check_timer.wait_time = CHECK_INTERVAL
	_check_timer.timeout.connect(_check_bandit_status)
	add_child(_check_timer)
	_check_timer.start()


func _check_bandit_status() -> void:
	if _phase != Phase.FIGHTING or _coward_played:
		return

	var alive: Array[GroyperBanditNpc] = []
	for bandit in _bandits:
		if is_instance_valid(bandit) and not bandit.is_defeated():
			alive.append(bandit)

	var hud := _get_raid_hud()
	if hud != null and hud.has_method("update_remaining_count"):
		hud.update_remaining_count(alive.size())

	if alive.is_empty():
		# Safety: every bandit died before the coward beat (e.g. AOE).
		_finish_ambush()
		return

	if alive.size() == 1:
		_begin_coward_cutscene(alive[0])


func _begin_coward_cutscene(survivor: GroyperBanditNpc) -> void:
	if _coward_played or survivor == null or not is_instance_valid(survivor):
		return
	_coward_played = true
	_phase = Phase.COWARD_CUTSCENE
	if _check_timer != null:
		_check_timer.stop()

	# Freeze the survivor so he doesn't keep shooting during the line.
	if survivor.has_method("begin_coward_hold"):
		survivor.begin_coward_hold()
	else:
		survivor.set_faction_aggro_level(0, null, false)

	var hud := _get_raid_hud()
	if hud != null:
		if hud.has_method("hide_raid_hud"):
			hud.hide_raid_hud()
		if hud.has_method("show_drama_letterbox_in"):
			hud.show_drama_letterbox_in()

	_lock_player_dialog(true)
	if _player != null and _player.has_method("begin_comet_cinematic_camera"):
		_player.begin_comet_cinematic_camera(survivor)

	_spawn_alert_on(survivor)
	_play_bandit_voice(survivor)
	DialogManager.show_dialog(
		BANDIT_SPEAKER,
		COWARD_LINE,
		func() -> void:
			_on_coward_dismissed(survivor)
	)


func _on_coward_dismissed(survivor: GroyperBanditNpc) -> void:
	if _player != null and _player.has_method("begin_comet_cinematic_camera_exit"):
		_player.begin_comet_cinematic_camera_exit()

	var hud := _get_raid_hud()
	if hud != null and hud.has_method("hide_drama_letterbox"):
		hud.hide_drama_letterbox()

	_lock_player_dialog(false)
	if _player != null and _player.has_method("end_comet_cinematic"):
		_player.end_comet_cinematic()
	if not InventoryMenuManager.is_open() and not TownMapManager.is_open():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Control returns — force the last bandit to run, then despawn.
	var flee_from := _player.global_position if _player != null else survivor.global_position
	if is_instance_valid(survivor) and survivor.has_method("begin_coward_flee"):
		survivor.begin_coward_flee(flee_from, COWARD_FLEE_DURATION)
	await get_tree().create_timer(COWARD_FLEE_DURATION).timeout
	if not is_inside_tree():
		return
	if is_instance_valid(survivor):
		survivor.queue_free()
	_finish_ambush()


func _finish_ambush() -> void:
	if _phase == Phase.RESOLVED:
		return
	_phase = Phase.RESOLVED
	if _check_timer != null:
		_check_timer.stop()
	if _proximity_timer != null:
		_proximity_timer.stop()

	var hud := _get_raid_hud()
	if hud != null:
		if hud.has_method("show_success_fx"):
			hud.show_success_fx()
		if hud.has_method("hide_raid_hud"):
			# Keep success FX briefly; Engines raid uses show_raid_victory.
			get_tree().create_timer(1.6).timeout.connect(func() -> void:
				if is_instance_valid(hud) and hud.has_method("hide_raid_hud"):
					hud.hide_raid_hud()
			)

	if _player != null and _player.has_method("exit_overworld_combat"):
		_player.exit_overworld_combat()
	UncleMysteryQuest.mark_part1_done()
	_lock_player_dialog(false)


func _spawn_alert_on(bandit: Node3D) -> void:
	if bandit == null or not is_instance_valid(bandit):
		return
	AlertSymbolFX.spawn_above(bandit, bandit.global_position + Vector3(0.0, ALERT_SYMBOL_HEIGHT, 0.0))


func _play_bandit_voice(speaker: Node3D) -> void:
	if speaker == null or not is_instance_valid(speaker):
		return
	var stream: AudioStream = GameAudioScript.pick_gropyptalk_voice()
	if stream != null:
		GameAudioScript.play_npc_voice(
			speaker,
			stream,
			speaker.global_position + Vector3(0.0, 1.45, 0.0)
		)


func _get_raid_hud() -> RaidHud:
	if _player != null and _player.has_method("get_raid_hud"):
		return _player.get_raid_hud()
	return null


func _lock_player_dialog(active: bool) -> void:
	if _player != null and _player.has_method("set_dialog_active"):
		_player.set_dialog_active(active)
