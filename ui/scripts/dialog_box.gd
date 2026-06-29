extends Control
class_name DialogBox

const FADE_DURATION := 0.15

@onready var _click_catcher: ColorRect = $ClickCatcher
@onready var _text_label: Label = $TextLabel

var _speaker_name := ""
var _lines: PackedStringArray = []
var _line_index := 0
var _dismiss_callback: Callable = Callable()
var _on_line_shown: Callable = Callable()
var _tween: Tween
var _dismissing := false


func _ready() -> void:
	hide_immediate()
	_click_catcher.gui_input.connect(_on_click_catcher_input)


func show_line(
	speaker_name: String,
	text: String,
	on_dismiss: Callable = Callable()
) -> void:
	show_sequence(speaker_name, PackedStringArray([text]), on_dismiss)


func show_sequence(
	speaker_name: String,
	lines: PackedStringArray,
	on_dismiss: Callable = Callable(),
	on_line_shown: Callable = Callable()
) -> void:
	if lines.is_empty():
		return

	_speaker_name = speaker_name
	_lines = lines
	_line_index = 0
	_dismiss_callback = on_dismiss
	_on_line_shown = on_line_shown
	_dismissing = false
	_set_text_for_line(_line_index)
	_notify_line_shown()

	show()
	_click_catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	_kill_tween()
	_text_label.modulate.a = 0.0

	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_text_label, "modulate:a", 1.0, FADE_DURATION)


func advance_line() -> void:
	if not visible or _dismissing or _lines.is_empty():
		return

	if _line_index >= _lines.size() - 1:
		hide_line()
		return

	_line_index += 1
	_set_text_for_line(_line_index)
	_notify_line_shown()


func hide_line() -> void:
	if not visible or _dismissing:
		return

	_dismissing = true
	_click_catcher.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_kill_tween()

	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_tween.tween_property(_text_label, "modulate:a", 0.0, FADE_DURATION)
	_tween.chain().tween_callback(func() -> void:
		_dismissing = false
		hide_immediate()
		if _dismiss_callback.is_valid():
			_dismiss_callback.call()
		_dismiss_callback = Callable()
		_on_line_shown = Callable()
		_lines = PackedStringArray()
		_line_index = 0
	)


func hide_immediate() -> void:
	_kill_tween()
	hide()
	_click_catcher.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text_label.modulate.a = 0.0
	_on_line_shown = Callable()
	_lines = PackedStringArray()
	_line_index = 0


func is_showing() -> bool:
	return visible


func _notify_line_shown() -> void:
	if _on_line_shown.is_valid():
		_on_line_shown.call(_line_index)


func _set_text_for_line(index: int) -> void:
	var text := _lines[index]
	_text_label.text = text if _speaker_name.is_empty() else "%s\n%s" % [_speaker_name.to_upper(), text]


func _on_click_catcher_input(event: InputEvent) -> void:
	if not visible or _dismissing:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance_line()


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
