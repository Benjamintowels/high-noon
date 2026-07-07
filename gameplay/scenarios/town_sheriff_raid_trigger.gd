extends Node
class_name TownSheriffRaidTrigger

const RAID_DELAY := 3.0

var _stage: Node3D
var _sheriff: Node3D
var _player: Node3D
var _raid_armed := false
var _raid_started := false
var _raid_timer := 0.0


func _ready() -> void:
	add_to_group("sheriff_raid_trigger")
	set_process(false)


func setup(stage: Node3D, sheriff: Node3D, player: Node3D) -> void:
	_stage = stage
	_sheriff = sheriff
	_player = player
	if _sheriff != null and not _sheriff.dialog_finished.is_connected(_on_sheriff_dialog_finished):
		_sheriff.dialog_finished.connect(_on_sheriff_dialog_finished)


func _on_sheriff_dialog_finished(player: Node3D) -> void:
	arm_after_sheriff_dialog(player)


func arm_after_sheriff_dialog(player: Node3D) -> void:
	if _should_ignore_raid_arm():
		return
	if player != null and is_instance_valid(player):
		_player = player
	_raid_armed = true
	_raid_timer = RAID_DELAY
	set_process(true)


func _should_ignore_raid_arm() -> bool:
	if _raid_started or _raid_armed:
		return true
	if _stage != null and bool(_stage.get("_town_raid_started")):
		return true
	return false


func _process(delta: float) -> void:
	if not _raid_armed or _raid_started:
		return
	if not is_instance_valid(_player):
		return

	_raid_timer -= delta
	if _raid_timer > 0.0:
		return

	_start_raid()


func _start_raid() -> void:
	if _raid_started:
		return
	_raid_started = true
	_raid_armed = false
	set_process(false)

	if _stage != null and _stage.has_method("begin_town_engines_raid"):
		_stage.call("begin_town_engines_raid")
