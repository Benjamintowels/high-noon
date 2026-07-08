extends Node

const GameAudio := preload("res://gameplay/audio/game_audio.gd")

const LETTERBOX_PUNCH_HEIGHT := 108.0
const LETTERBOX_INTRO_DURATION := 0.25
const DEATH_HOLD_DURATION := 3.0
const FADE_TO_BLACK_DURATION := 0.65
const FADE_IN_DURATION := 0.85
const DESATURATION_DURATION := 0.8

var _layer: CanvasLayer
var _letterbox_top: ColorRect
var _letterbox_bottom: ColorRect
var _title_label: Label
var _fade_overlay: ColorRect
var _active := false
var _world_environment: WorldEnvironment
var _saved_adjustment_enabled := false
var _saved_saturation := 1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func is_active() -> bool:
	return _active


func play_death_sequence(on_complete: Callable = Callable()) -> void:
	if _active:
		return
	_ensure_ui()
	_active = true
	_fade_overlay.modulate.a = 0.0
	_title_label.modulate = Color(0.95, 0.18, 0.14, 0.0)
	_title_label.text = "Ye' Died"
	_letterbox_top.visible = true
	_letterbox_bottom.visible = true
	_letterbox_top.offset_bottom = 0.0
	_letterbox_bottom.offset_top = 0.0

	GameAudio.play_raid_drama_start(self)
	_begin_desaturation()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_letterbox_top, "offset_bottom", LETTERBOX_PUNCH_HEIGHT, LETTERBOX_INTRO_DURATION)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(_letterbox_bottom, "offset_top", -LETTERBOX_PUNCH_HEIGHT, LETTERBOX_INTRO_DURATION)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(_title_label, "modulate:a", 1.0, LETTERBOX_INTRO_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	tween.set_parallel(false)
	tween.tween_interval(DEATH_HOLD_DURATION)
	tween.tween_property(_fade_overlay, "modulate:a", 1.0, FADE_TO_BLACK_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.finished.connect(func() -> void:
		if on_complete.is_valid():
			on_complete.call()
	)


func fade_in_after_respawn(on_finished: Callable = Callable()) -> void:
	_ensure_ui()
	_fade_overlay.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(_fade_overlay, "modulate:a", 0.0, FADE_IN_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func() -> void:
		_reset_cinematic()
		if on_finished.is_valid():
			on_finished.call()
	)


func _reset_cinematic() -> void:
	_active = false
	_restore_desaturation()
	if _letterbox_top != null:
		_letterbox_top.visible = false
		_letterbox_top.offset_bottom = 0.0
	if _letterbox_bottom != null:
		_letterbox_bottom.visible = false
		_letterbox_bottom.offset_top = 0.0
	if _title_label != null:
		_title_label.text = ""
		_title_label.modulate.a = 1.0
	if _fade_overlay != null:
		_fade_overlay.modulate.a = 0.0


func _ensure_ui() -> void:
	if _layer != null:
		return

	_layer = CanvasLayer.new()
	_layer.layer = 120
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_layer)

	_fade_overlay = ColorRect.new()
	_fade_overlay.name = "DeathFadeOverlay"
	_fade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_overlay.color = Color(0.0, 0.0, 0.0, 1.0)
	_fade_overlay.modulate.a = 0.0
	_layer.add_child(_fade_overlay)

	_letterbox_top = ColorRect.new()
	_letterbox_top.name = "DeathLetterboxTop"
	_letterbox_top.color = Color(0.02, 0.015, 0.01, 0.92)
	_letterbox_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_letterbox_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_letterbox_top.offset_bottom = 0.0
	_letterbox_top.visible = false
	_layer.add_child(_letterbox_top)

	_letterbox_bottom = ColorRect.new()
	_letterbox_bottom.name = "DeathLetterboxBottom"
	_letterbox_bottom.color = Color(0.02, 0.015, 0.01, 0.92)
	_letterbox_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_letterbox_bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_letterbox_bottom.offset_top = 0.0
	_letterbox_bottom.visible = false
	_layer.add_child(_letterbox_bottom)

	_title_label = Label.new()
	_title_label.name = "DeathTitle"
	_title_label.text = "Ye' Died"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_title_label.add_theme_font_size_override("font_size", 56)
	_title_label.modulate = Color(0.95, 0.18, 0.14, 0.0)
	_layer.add_child(_title_label)


func _begin_desaturation() -> void:
	_world_environment = _find_world_environment()
	if _world_environment == null or _world_environment.environment == null:
		return

	var env := _world_environment.environment
	_saved_adjustment_enabled = env.adjustment_enabled
	_saved_saturation = env.adjustment_saturation
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.0

	var tween := create_tween()
	tween.tween_property(env, "adjustment_saturation", 0.0, DESATURATION_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func _restore_desaturation() -> void:
	if _world_environment == null or _world_environment.environment == null:
		return
	var env := _world_environment.environment
	env.adjustment_saturation = _saved_saturation
	env.adjustment_enabled = _saved_adjustment_enabled
	_world_environment = null


func _find_world_environment() -> WorldEnvironment:
	var stage := get_tree().current_scene
	if stage == null:
		return null
	return stage.get_node_or_null("WorldEnvironment") as WorldEnvironment
