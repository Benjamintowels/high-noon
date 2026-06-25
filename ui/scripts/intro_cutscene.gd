extends Control

const IMAGE_PATH := "res://Assets/Cutscenes/Intro/1GC.png"
const FADE_IN_DURATION := 1.5
const HOLD_DURATION := 3.0
const FADE_OUT_DURATION := 1.5
const SKIP_FADE_DURATION := 0.35

@onready var _image: TextureRect = $ImagePanel

var _active_tween: Tween
var _leaving := false


func _ready() -> void:
	_image.texture = load(IMAGE_PATH) as Texture2D
	_image.modulate.a = 0.0
	_play_cutscene()


func _unhandled_input(event: InputEvent) -> void:
	if _leaving:
		return
	if event is InputEventMouseButton and event.pressed:
		_skip()
	elif event is InputEventKey and event.pressed and not event.echo:
		_skip()


func _play_cutscene() -> void:
	_active_tween = create_tween()
	_active_tween.tween_property(_image, "modulate:a", 1.0, FADE_IN_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_active_tween.tween_interval(HOLD_DURATION)
	_active_tween.tween_property(_image, "modulate:a", 0.0, FADE_OUT_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_active_tween.finished.connect(_go_to_loading)


func _skip() -> void:
	if _leaving:
		return
	_leaving = true
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()

	var fade := create_tween()
	fade.tween_property(_image, "modulate:a", 0.0, SKIP_FADE_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await fade.finished
	_go_to_loading()


func _go_to_loading() -> void:
	if not _leaving:
		_leaving = true
	get_tree().change_scene_to_file(GameState.LOADING_SCENE_PATH)
