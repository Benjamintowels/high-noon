extends Node
class_name HotelBrawl
## First-fight tutorial scenario in the hotel lobby. Three cowboy patrons
## lounge near the chairs, each with a Talk interactable. Bothering one gets
## "Do you mind?" / "We got a problem here?" with a Yes/No choice. Yes plays
## the letterbox confrontation ("That's that guy. Get him!"), teaches
## punch/block/lock-on, then the cowboys melee the player. Beating them all
## cues the manager telling the player to leave. No dismisses peacefully so
## the player can wander the lobby first.

const COWBOY_SCENE := preload("res://characters/groyper/groyper_bandit_npc.tscn")
const GameAudioScript := preload("res://gameplay/audio/game_audio.gd")
const BrawlAuraFXScript := preload("res://gameplay/fx/brawl_aura_fx.gd")

const BYSTANDER_FLEE_RANGE := 18.0
const ALERT_SYMBOL_HEIGHT := 2.1

const COWBOY_SPEAKER := "Cowboy"
const MANAGER_SPEAKER := "Hotel Manager"
const TUTORIAL_SPEAKER := "How to Fight"
const ASK_LINES: PackedStringArray = [
	"Do you mind?",
	"We got a problem here?",
]
const BACK_DOWN_LINE := "Well alright then"
const FIGHT_LINE := "That's that guy. Get him!"
const SCOLD_LINE := "You better get going mister we don't need trouble like this"
const TUTORIAL_LINES: PackedStringArray = [
	"Press F to throw a punch.",
	"Hold Q to block. Keep facing your attacker or the hit gets through.",
	"Click the Middle Mouse Button to lock on to a target.",
	"Defend yourself!",
]

const CHECK_INTERVAL := 0.35
const CAMERA_RETURN_SECONDS := 0.9
const COWBOY_HAT_COLOR := Color(0.42, 0.31, 0.21)
const CHATTER_INTERVAL_MIN := 8.0
const CHATTER_INTERVAL_MAX := 18.0
const BRAWL_BARK_DELAY_MAX := 1.2
const INTERACT_RADIUS := 2.75
const INTERACT_HEIGHT := 0.85

enum Phase {
	IDLE,
	ASKING,
	CONFRONTING,
	BRAWLING,
	RESOLVED,
}

@export var manager_path: NodePath
@export var spawn_marker_paths: Array[NodePath] = []

var _manager: Node3D
var _cowboys: Array[GroyperBanditNpc] = []
var _interact_areas: Array[CowboyInteractArea] = []
var _ask_cowboy: GroyperBanditNpc
var _player: Node3D
var _phase := Phase.IDLE
var _check_timer: Timer
var _chatter_timer := 0.0


## Talk prompt attached to each cowboy. Bothering one starts the yes/no
## confrontation ask through the owning HotelBrawl.
class CowboyInteractArea extends Area3D:
	var brawl: HotelBrawl
	var cowboy: GroyperBanditNpc
	var _player_in_range: Node3D

	func _init() -> void:
		collision_layer = 0
		collision_mask = 1
		monitorable = false
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)

	func interact(player: Node3D) -> void:
		if brawl != null:
			brawl.request_cowboy_ask(cowboy, player)

	func get_interact_hint() -> String:
		return "Talk"

	func disable() -> void:
		set_deferred("monitoring", false)
		if (
			_player_in_range != null
			and is_instance_valid(_player_in_range)
			and _player_in_range.has_method("unregister_interactable")
		):
			_player_in_range.unregister_interactable(self)
		_player_in_range = null

	func _on_body_entered(body: Node3D) -> void:
		if body is CharacterBody3D and body.has_method("register_interactable"):
			_player_in_range = body
			body.register_interactable(self)

	func _on_body_exited(body: Node3D) -> void:
		if body == _player_in_range:
			_player_in_range = null
			if body.has_method("unregister_interactable"):
				body.unregister_interactable(self)


func _ready() -> void:
	_manager = get_node_or_null(manager_path) as Node3D
	if _manager == null:
		push_warning("HotelBrawl: missing manager node; scenario disabled.")
		return

	if HotelBrawlProgress.completed:
		_phase = Phase.RESOLVED
		return

	# The cowboys are lobby patrons from the start, parked on nearby chairs.
	call_deferred("_spawn_cowboys")
	_chatter_timer = randf_range(2.0, 6.0)


func _process(delta: float) -> void:
	_chatter_timer -= delta
	if _chatter_timer > 0.0:
		return
	_chatter_timer = randf_range(CHATTER_INTERVAL_MIN, CHATTER_INTERVAL_MAX)
	_play_random_chatter()


## The hotel regulars keep up a low murmur of GroypTalk between events.
func _play_random_chatter() -> void:
	var talkers: Array[Node3D] = []
	if _manager != null and is_instance_valid(_manager):
		talkers.append(_manager)
	for cowboy in _cowboys:
		if is_instance_valid(cowboy) and not cowboy.is_defeated():
			talkers.append(cowboy)
	var parent := get_parent()
	if parent != null:
		for folk_name in ["Townsfolk1", "Townsfolk2", "Townsfolk3"]:
			var folk := parent.get_node_or_null(folk_name) as Node3D
			if folk != null and not (folk.has_method("is_defeated") and folk.is_defeated()):
				talkers.append(folk)
	if talkers.is_empty():
		return
	var speaker := talkers[randi() % talkers.size()]
	var stream: AudioStream = GameAudioScript.pick_gropyptalk_voice()
	if stream != null:
		GameAudioScript.play_npc_voice(speaker, stream, speaker.global_position + Vector3(0.0, 1.45, 0.0))


## Everyone hollers when the fight kicks off.
func _play_brawl_barks() -> void:
	var barkers: Array[Node3D] = []
	for cowboy in _cowboys:
		if is_instance_valid(cowboy) and not cowboy.is_defeated():
			barkers.append(cowboy)
	var parent := get_parent()
	if parent != null:
		for folk_name in ["Townsfolk1", "Townsfolk2", "Townsfolk3"]:
			var folk := parent.get_node_or_null(folk_name) as Node3D
			if folk != null:
				barkers.append(folk)
	for barker in barkers:
		var stream: AudioStream = GameAudioScript.pick_gropyptalk_voice()
		if stream == null:
			continue
		var delay := randf_range(0.0, BRAWL_BARK_DELAY_MAX)
		get_tree().create_timer(delay).timeout.connect(func() -> void:
			if is_instance_valid(barker):
				GameAudioScript.play_npc_voice(barker, stream, barker.global_position + Vector3(0.0, 1.45, 0.0))
		)


func request_cowboy_ask(cowboy: GroyperBanditNpc, player: Node3D) -> void:
	if _phase != Phase.IDLE:
		return
	if cowboy == null or not is_instance_valid(cowboy) or cowboy.is_defeated():
		return
	if player == null:
		return

	_phase = Phase.ASKING
	_ask_cowboy = cowboy
	_player = player
	_lock_player_dialog(true)

	DialogManager.show_dialog_sequence(
		ASK_LINES,
		func() -> void:
			DialogManager.show_choices(
				PackedStringArray(["Yes", "No"]),
				func(choice_index: int) -> void:
					if choice_index == 0:
						_on_ask_accepted()
					else:
						_on_ask_declined()
			),
		COWBOY_SPEAKER,
		func(_line_index: int) -> void:
			_play_npc_voice(cowboy)
	)


func _on_ask_accepted() -> void:
	_phase = Phase.CONFRONTING
	# Top Ranch turns on the player here — and stays hostile (persisted)
	# until a future sidequest makes peace.
	HotelBrawlProgress.set_top_ranch_hostile(true)
	_disable_interact_areas()
	call_deferred("_begin_confrontation")


func _on_ask_declined() -> void:
	var cowboy := _ask_cowboy
	_ask_cowboy = null
	if cowboy != null and is_instance_valid(cowboy):
		_play_npc_voice(cowboy)
	DialogManager.show_dialog(
		COWBOY_SPEAKER,
		BACK_DOWN_LINE,
		func() -> void:
			_lock_player_dialog(false)
			_phase = Phase.IDLE
	)


func _disable_interact_areas() -> void:
	for area in _interact_areas:
		if is_instance_valid(area):
			area.disable()


func _begin_confrontation() -> void:
	_lock_player_dialog(true)
	GameAudioScript.play_raid_drama_start(self)

	# The patrons rise from their chairs to come pick the fight.
	for cowboy in _cowboys:
		if is_instance_valid(cowboy) and cowboy.has_method("request_chair_stand"):
			cowboy.request_chair_stand()

	var hud := _get_raid_hud()
	if hud != null and hud.has_method("show_drama_letterbox_in"):
		hud.show_drama_letterbox_in()

	var lead := _confront_lead()
	if lead != null and _player.has_method("begin_comet_cinematic_camera"):
		_player.begin_comet_cinematic_camera(lead)

	_play_cowboy_voice()
	DialogManager.show_dialog(
		COWBOY_SPEAKER,
		FIGHT_LINE,
		func() -> void:
			_on_confront_dismissed()
	)


func _spawn_cowboys() -> void:
	var spawn_parent := get_parent()
	for marker_path in spawn_marker_paths:
		var marker := get_node_or_null(marker_path) as Node3D
		if marker == null:
			push_warning("HotelBrawl: missing cowboy spawn marker %s." % marker_path)
			continue
		var cowboy: GroyperBanditNpc = COWBOY_SCENE.instantiate()
		cowboy.bandit_hat_color = COWBOY_HAT_COLOR
		cowboy.melee_only = true
		spawn_parent.add_child(cowboy)
		# NPC facing code assumes an unrotated root — never copy marker rotation.
		cowboy.global_position = marker.global_position
		_cowboys.append(cowboy)
		_add_interact_area(cowboy)
		# No forced seating: they idle near the chairs and sit on their own
		# via the random chair-sit urge, which uses the normal transition.


func _add_interact_area(cowboy: GroyperBanditNpc) -> void:
	var area := CowboyInteractArea.new()
	area.name = "BrawlAskArea"
	area.brawl = self
	area.cowboy = cowboy
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = INTERACT_RADIUS
	shape.shape = sphere
	shape.position = Vector3(0.0, INTERACT_HEIGHT, 0.0)
	area.add_child(shape)
	cowboy.add_child(area)
	_interact_areas.append(area)


func _lead_cowboy() -> GroyperBanditNpc:
	for cowboy in _cowboys:
		if is_instance_valid(cowboy):
			return cowboy
	return null


## The cowboy the player picked the fight with, falling back to any survivor.
func _confront_lead() -> GroyperBanditNpc:
	if (
		_ask_cowboy != null
		and is_instance_valid(_ask_cowboy)
		and not _ask_cowboy.is_defeated()
	):
		return _ask_cowboy
	return _lead_cowboy()


func _on_confront_dismissed() -> void:
	if _player != null and _player.has_method("begin_comet_cinematic_camera_exit"):
		_player.begin_comet_cinematic_camera_exit()
	# The dialog box clears its state right after the dismiss callback returns,
	# so chaining straight into another dialog would get wiped. Let a beat pass.
	await get_tree().create_timer(0.35).timeout
	DialogManager.show_dialog_sequence(
		TUTORIAL_LINES,
		func() -> void:
			_start_brawl(),
		TUTORIAL_SPEAKER
	)


func _start_brawl() -> void:
	_phase = Phase.BRAWLING
	if _player != null and _player.has_method("end_comet_cinematic"):
		_player.end_comet_cinematic()

	var hud := _get_raid_hud()
	if hud != null and hud.has_method("hide_drama_letterbox"):
		hud.hide_drama_letterbox()
	if hud != null and hud.has_method("show_alert_title"):
		hud.show_alert_title("Brawl!")

	var closest: GroyperBanditNpc = null
	var closest_dist_sq := INF
	for cowboy in _cowboys:
		if not is_instance_valid(cowboy) or cowboy.is_defeated():
			continue
		cowboy.enter_melee_aggro(_player)
		BrawlAuraFXScript.apply(cowboy)
		AlertSymbolFX.spawn_above(cowboy, cowboy.global_position + Vector3(0.0, ALERT_SYMBOL_HEIGHT, 0.0))
		var dist_sq := cowboy.global_position.distance_squared_to(_player.global_position)
		if dist_sq < closest_dist_sq:
			closest_dist_sq = dist_sq
			closest = cowboy
	if closest != null:
		closest.begin_melee_opening_rush()

	_scatter_bystanders()
	_play_brawl_barks()
	_chatter_timer = randf_range(CHATTER_INTERVAL_MIN, CHATTER_INTERVAL_MAX)

	_lock_player_dialog(false)
	if _player != null and _player.has_method("enter_overworld_combat"):
		_player.enter_overworld_combat()
	if not InventoryMenuManager.is_open() and not TownMapManager.is_open():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	_start_death_watch()


func _start_death_watch() -> void:
	_check_timer = Timer.new()
	_check_timer.wait_time = CHECK_INTERVAL
	_check_timer.timeout.connect(_check_cowboy_status)
	add_child(_check_timer)
	_check_timer.start()


func _scatter_bystanders() -> void:
	if _player == null:
		return
	for node in get_tree().get_nodes_in_group(&"town_npc"):
		if node in _cowboys or not (node is Node3D):
			continue
		if not node.has_method("begin_brawl_flee"):
			continue
		if (node as Node3D).global_position.distance_to(_player.global_position) <= BYSTANDER_FLEE_RANGE:
			node.begin_brawl_flee(_player.global_position)


func _check_cowboy_status() -> void:
	if _phase != Phase.BRAWLING:
		return
	var any_alive := false
	for cowboy in _cowboys:
		if not is_instance_valid(cowboy):
			continue
		if cowboy.is_defeated():
			BrawlAuraFXScript.remove(cowboy)
		else:
			any_alive = true
	if any_alive:
		return
	_play_manager_scold()


func _play_manager_scold() -> void:
	_phase = Phase.RESOLVED
	if _check_timer != null:
		_check_timer.stop()
	if _player != null and _player.has_method("exit_overworld_combat"):
		_player.exit_overworld_combat()

	# If any dialog is still up (or fading out), showing ours now would get
	# wiped by the dialog box's dismiss cleanup. Clear it and let a beat pass.
	if DialogManager.is_showing():
		DialogManager.hide_dialog()
	await get_tree().create_timer(0.45).timeout

	var hud := _get_raid_hud()
	if hud != null and hud.has_method("show_drama_letterbox_in"):
		hud.show_drama_letterbox_in()

	_lock_player_dialog(true)
	if _player != null and _player.has_method("begin_comet_cinematic_camera"):
		_player.begin_comet_cinematic_camera(_manager)

	_play_manager_voice()
	DialogManager.show_dialog(
		MANAGER_SPEAKER,
		SCOLD_LINE,
		func() -> void:
			_on_scold_dismissed()
	)


func _on_scold_dismissed() -> void:
	if _player != null and _player.has_method("begin_comet_cinematic_camera_exit"):
		_player.begin_comet_cinematic_camera_exit()
	await get_tree().create_timer(CAMERA_RETURN_SECONDS).timeout
	if _player != null and _player.has_method("end_comet_cinematic"):
		_player.end_comet_cinematic()

	var hud := _get_raid_hud()
	if hud != null and hud.has_method("hide_drama_letterbox"):
		hud.hide_drama_letterbox()

	_lock_player_dialog(false)
	HotelBrawlProgress.mark_completed()
	if not InventoryMenuManager.is_open() and not TownMapManager.is_open():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _play_cowboy_voice() -> void:
	var speaker: Node3D = _confront_lead()
	if speaker == null:
		speaker = _manager
	var stream: AudioStream = GameAudioScript.pick_gropyptalk_voice()
	if stream != null and speaker != null:
		GameAudioScript.play_npc_voice(speaker, stream, speaker.global_position)


func _play_npc_voice(speaker: Node3D) -> void:
	if speaker == null or not is_instance_valid(speaker):
		return
	var stream: AudioStream = GameAudioScript.pick_gropyptalk_voice()
	if stream != null:
		GameAudioScript.play_npc_voice(
			speaker, stream, speaker.global_position + Vector3(0.0, 1.45, 0.0)
		)


func _play_manager_voice() -> void:
	var stream: AudioStream = GameAudioScript.pick_gropyptalk_voice()
	if stream == null or _manager == null:
		return
	var voice_position := _manager.global_position
	if _manager.has_method("get_voice_world_position"):
		voice_position = _manager.get_voice_world_position()
	GameAudioScript.play_npc_voice(_manager, stream, voice_position)


func _get_raid_hud() -> RaidHud:
	if _player != null and _player.has_method("get_raid_hud"):
		return _player.get_raid_hud()
	return null


func _lock_player_dialog(active: bool) -> void:
	if _player != null and _player.has_method("set_dialog_active"):
		_player.set_dialog_active(active)
