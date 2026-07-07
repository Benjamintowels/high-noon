extends Control
class_name RaidHud

const FxCatalogScript := preload("res://gameplay/fx/fx_catalog.gd")
const FxFramesLoaderScript := preload("res://gameplay/fx/fx_frames_loader.gd")

@onready var _title_label: Label = $VBox/TitleLabel
@onready var _count_label: Label = $VBox/CountLabel

var _screen_fx_root: Control
var _screen_fx_sprite: AnimatedSprite2D
var _screen_fx_active := false


func _ready() -> void:
	visible = false


func show_raid_start(total_raiders: int) -> void:
	visible = true
	_title_label.text = "Raid!"
	_title_label.modulate = Color(0.95, 0.18, 0.14, 1.0)
	_update_kill_count(0, total_raiders)


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
	visible = false
	hide_success_fx()
	_title_label.text = ""
	_count_label.text = ""


func _update_kill_count(killed: int, total: int) -> void:
	_count_label.text = "%d/%d" % [killed, total]


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
