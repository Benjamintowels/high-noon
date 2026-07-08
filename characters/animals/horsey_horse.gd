extends StupidHorse
class_name HorseyHorse

const PLAYER_SPEAKER := "Groyper"

var _intro_lines := PackedStringArray([
	"My Uncle's old horse....",
	"Horsey...",
])

var _intro_complete := false
var _intro_playing := false


func _ready() -> void:
	super._ready()
	add_to_group("horsey")
	_intro_complete = HorseyProgress.intro_complete
	roam_mode = RoamMode.CORRAL


func interact(player: Node3D) -> void:
	if player == null or _horse_defeated or _intro_playing:
		return
	if _mounted:
		if player == _rider:
			dismount_rider()
		return
	if _rider != null:
		return
	if not _intro_complete:
		_play_intro(player)
		return
	if not player is CharacterBody3D:
		return
	mount_rider(player as CharacterBody3D)


func get_interact_hint() -> String:
	if _mounted:
		return "Dismount"
	if not _intro_complete:
		return "Approach"
	return "Mount"


func _play_intro(player: Node3D) -> void:
	_intro_playing = true
	play_head_bow()
	if player.has_method("set_dialog_active"):
		player.set_dialog_active(true)

	DialogManager.show_dialog_sequence(
		_intro_lines,
		func() -> void:
			_finish_intro(player),
		PLAYER_SPEAKER
	)


func _finish_intro(player: Node3D) -> void:
	_intro_playing = false
	_intro_complete = true
	HorseyProgress.mark_intro_complete()
	if player != null and player.has_method("set_dialog_active"):
		player.set_dialog_active(false)
