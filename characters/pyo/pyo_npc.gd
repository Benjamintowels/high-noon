extends Node3D
class_name PyoNpc

const GameAudio := preload("res://gameplay/audio/game_audio.gd")

const ANIM_LIBRARY := &"pyo"
const ANIM_IDLE := &"idle"
const ANIM_LOOK_UP := &"look_up"
const LOOK_BLEND := 0.15

@export var yap_cooldown := 0.75

@onready var _animation_player: AnimationPlayer = $Model/PyoMeshRigged/AnimationPlayer
@onready var _interact_area: Area3D = $InteractArea

var _player_in_range: Node3D
var _yap_cooldown_timer := 0.0
var _look_up_active := false


func _ready() -> void:
	_interact_area.body_entered.connect(_on_interact_body_entered)
	_interact_area.body_exited.connect(_on_interact_body_exited)
	_play_idle()


func _process(delta: float) -> void:
	var was_on_cooldown := _yap_cooldown_timer > 0.0
	_yap_cooldown_timer = maxf(_yap_cooldown_timer - delta, 0.0)
	if was_on_cooldown and _yap_cooldown_timer <= 0.0 and _look_up_active:
		_look_up_active = false
		_play_idle()


func interact(player: Node3D) -> void:
	if player == null or _yap_cooldown_timer > 0.0:
		return

	_yap_cooldown_timer = yap_cooldown
	_look_up_active = true
	_play_look_up()
	GameAudio.play_pyo_yap(self, global_position)


func get_interact_hint() -> String:
	return "Pet Pyo"


func _play_idle() -> void:
	_play_animation(ANIM_IDLE)


func _play_look_up() -> void:
	_play_animation(ANIM_LOOK_UP)


func _play_animation(clip: StringName) -> void:
	if _animation_player == null:
		return

	var path := "%s/%s" % [ANIM_LIBRARY, clip]
	if not _animation_player.has_animation(path):
		push_error("PyoNpc: missing animation '%s'" % path)
		return

	_animation_player.play(path, LOOK_BLEND)


func _on_interact_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and body.has_method("register_interactable"):
		_player_in_range = body
		body.register_interactable(self)


func _on_interact_body_exited(body: Node3D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		if body.has_method("unregister_interactable"):
			body.unregister_interactable(self)
