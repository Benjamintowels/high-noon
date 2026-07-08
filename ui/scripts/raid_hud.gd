extends Control
class_name RaidHud

const FxCatalogScript := preload("res://gameplay/fx/fx_catalog.gd")
const FxFramesLoaderScript := preload("res://gameplay/fx/fx_frames_loader.gd")

const LETTERBOX_HEIGHT := 72.0
const LETTERBOX_PUNCH_HEIGHT := 108.0
const AMBUSH_DISPLAY_DURATION := 2.0
const AMBUSH_FADE_DURATION := 0.45

@onready var _title_label: Label = $VBox/TitleLabel
@onready var _count_label: Label = $VBox/CountLabel

var _screen_fx_root: Control
var _screen_fx_sprite: AnimatedSprite2D
var _screen_fx_active := false
var _cinematic_layer: CanvasLayer
var _letterbox_top: ColorRect
var _letterbox_bottom: ColorRect
var _cinematic_active := false


func _ready() -> void:
	visible = false


func show_raid_start(total_raiders: int) -> void:
	visible = true
	_count_label.visible = true
	_title_label.text = "Raid!"
	_title_label.modulate = Color(0.95, 0.18, 0.14, 1.0)
	_update_kill_count(0, total_raiders)


func show_ambush_start(on_finished: Callable = Callable()) -> void:
	_ensure_letterbox()
	_cinematic_active = true
	visible = true
	_count_label.visible = false
	_count_label.text = ""
	_title_label.text = "Ambush!"
	_title_label.modulate = Color(0.95, 0.18, 0.14, 0.0)

	_letterbox_top.visible = true
	_letterbox_bottom.visible = true
	_letterbox_top.offset_bottom = LETTERBOX_HEIGHT
	_letterbox_bottom.offset_top = -LETTERBOX_HEIGHT

	var intro := create_tween()
	intro.set_parallel(true)
	intro.tween_property(_letterbox_top, "offset_bottom", LETTERBOX_PUNCH_HEIGHT, 0.18)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	intro.tween_property(_letterbox_bottom, "offset_top", -LETTERBOX_PUNCH_HEIGHT, 0.18)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	intro.tween_property(_title_label, "modulate:a", 1.0, 0.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	var outro := create_tween()
	outro.tween_interval(AMBUSH_DISPLAY_DURATION)
	outro.set_parallel(true)
	outro.tween_property(_title_label, "modulate:a", 0.0, AMBUSH_FADE_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	outro.tween_property(_letterbox_top, "offset_bottom", 0.0, AMBUSH_FADE_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	outro.tween_property(_letterbox_bottom, "offset_top", 0.0, AMBUSH_FADE_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	outro.finished.connect(func() -> void:
		_hide_ambush_cinematic()
		if on_finished.is_valid():
			on_finished.call()
	)


func update_kill_count(killed: int, total: int) -> void:
	if not visible:
		return
	_update_kill_count(killed, total)


func show_raid_victory() -> void:
	_play_success_fx()
	var tween := create_tween()
	tween.tween_interval(2.4)
	tween.tween_callback(hide_raid_hud)


func hide_raid_hud() -> void:
	_hide_ambush_cinematic()
	visible = false
	hide_success_fx()
	_title_label.text = ""
	_count_label.text = ""
	_count_label.visible = true


func _update_kill_count(killed: int, total: int) -> void:
	_count_label.text = "%d/%d" % [killed, total]


func _hide_ambush_cinematic() -> void:
	_cinematic_active = false
	if _letterbox_top != null:
		_letterbox_top.visible = false
		_letterbox_top.offset_bottom = LETTERBOX_HEIGHT
	if _letterbox_bottom != null:
		_letterbox_bottom.visible = false
		_letterbox_bottom.offset_top = -LETTERBOX_HEIGHT
	if _title_label != null:
		_title_label.modulate.a = 1.0
		_title_label.text = ""
	visible = false


func _ensure_letterbox() -> void:
	if _letterbox_top != null:
		return

	_cinematic_layer = CanvasLayer.new()
	_cinematic_layer.name = "RaidCinematicLayer"
	_cinematic_layer.layer = 90
	add_child(_cinematic_layer)

	_letterbox_top = ColorRect.new()
	_letterbox_top.name = "AmbushLetterboxTop"
	_letterbox_top.color = Color(0.02, 0.015, 0.01, 0.92)
	_letterbox_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_letterbox_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_letterbox_top.offset_bottom = LETTERBOX_HEIGHT
	_letterbox_top.visible = false
	_cinematic_layer.add_child(_letterbox_top)

	_letterbox_bottom = ColorRect.new()
	_letterbox_bottom.name = "AmbushLetterboxBottom"
	_letterbox_bottom.color = Color(0.02, 0.015, 0.01, 0.92)
	_letterbox_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_letterbox_bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_letterbox_bottom.offset_top = -LETTERBOX_HEIGHT
	_letterbox_bottom.visible = false
	_cinematic_layer.add_child(_letterbox_bottom)


func _play_success_fx() -> void:
	var frames := FxCatalogScript.success_frames()
	if frames == null or frames.get_frame_count(FxFramesLoaderScript.ANIM_NAME) == 0:
		return

	_ensure_screen_fx_widgets()
	_screen_fx_active = true
	_screen_fx_root.visible = true
	_screen_fx_root.modulate.a = 1.0
	_screen_fx_sprite.sprite_frames = frames
	_screen_fx_sprite.modulate.a = 1.0
	_screen_fx_sprite.texture_filter = FxFramesLoaderScript.FILTER_2D
	_screen_fx_sprite.position = Vector2.ZERO
	_screen_fx_sprite.play(FxFramesLoaderScript.ANIM_NAME)


func hide_success_fx() -> void:
	_screen_fx_active = false
	if _screen_fx_root != null:
		_screen_fx_root.visible = false
	if _screen_fx_sprite != null:
		_screen_fx_sprite.stop()


func _ensure_screen_fx_widgets() -> void:
	if _screen_fx_root != null:
		return

	_screen_fx_root = Control.new()
	_screen_fx_root.name = "RaidSuccessFX"
	_screen_fx_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen_fx_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_screen_fx_root)

	var stack := VBoxContainer.new()
	stack.name = "Stack"
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 10)
	stack.set_anchors_preset(Control.PRESET_CENTER)
	stack.offset_left = -220.0
	stack.offset_right = 220.0
	stack.offset_top = -80.0
	stack.offset_bottom = 120.0
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen_fx_root.add_child(stack)

	_screen_fx_sprite = AnimatedSprite2D.new()
	_screen_fx_sprite.name = "SuccessSprite"
	_screen_fx_sprite.scale = Vector2(4.0, 4.0)
	_screen_fx_sprite.texture_filter = FxFramesLoaderScript.FILTER_2D
	stack.add_child(_screen_fx_sprite)

	_screen_fx_root.visible = false
