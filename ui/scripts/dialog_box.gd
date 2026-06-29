extends Control
class_name DialogBox

const FADE_DURATION := 0.15

@onready var _click_catcher: ColorRect = $ClickCatcher
@onready var _text_label: Label = $TextLabel
@onready var _choice_container: VBoxContainer = $ChoiceContainer

var _speaker_name := ""
var _lines: PackedStringArray = []
var _line_index := 0
var _dismiss_callback: Callable = Callable()
var _on_line_shown: Callable = Callable()
var _choice_callback: Callable = Callable()
var _tween: Tween
var _dismissing := false
var _awaiting_choices := false


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

	_clear_choices()
	_awaiting_choices = false
	_speaker_name = speaker_name
	_lines = lines
	_line_index = 0
	_dismiss_callback = on_dismiss
	_on_line_shown = on_line_shown
	_choice_callback = Callable()
	_dismissing = false
	_set_text_for_line(_line_index)
	_notify_line_shown()

	show()
	_click_catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	_kill_tween()
	_text_label.modulate.a = 0.0

	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_text_label, "modulate:a", 1.0, FADE_DURATION)


func show_choices(choices: PackedStringArray, on_choice: Callable) -> void:
	_clear_choices()
	if choices.is_empty():
		return

	_awaiting_choices = true
	_choice_callback = on_choice
	_dismissing = false
	show()
	_text_label.modulate.a = 1.0
	_click_catcher.mouse_filter = Control.MOUSE_FILTER_IGNORE

	for i in choices.size():
		var button := Button.new()
		button.text = choices[i]
		button.focus_mode = Control.FOCUS_NONE
		var choice_index := i
		button.pressed.connect(func() -> void:
			_on_choice_pressed(choice_index)
		)
		_choice_container.add_child(button)

	_choice_container.visible = true


func advance_line() -> void:
	if not visible or _dismissing or _lines.is_empty() or _awaiting_choices:
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
	_clear_choices()
	_awaiting_choices = false
	hide()
	_click_catcher.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text_label.modulate.a = 0.0
	_on_line_shown = Callable()
	_choice_callback = Callable()
	_lines = PackedStringArray()
	_line_index = 0


func is_showing_choices() -> bool:
	return _awaiting_choices


func is_showing() -> bool:
	return visible


func _notify_line_shown() -> void:
	if _on_line_shown.is_valid():
		_on_line_shown.call(_line_index)


func _set_text_for_line(index: int) -> void:
	var text := _lines[index]
	_text_label.text = text if _speaker_name.is_empty() else "%s\n%s" % [_speaker_name.to_upper(), text]


func _on_click_catcher_input(event: InputEvent) -> void:
	if not visible or _dismissing or _awaiting_choices:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance_line()


func _on_choice_pressed(choice_index: int) -> void:
	if not _awaiting_choices:
		return
	var callback := _choice_callback
	_clear_choices()
	_awaiting_choices = false
	_choice_callback = Callable()
	_dismiss_callback = Callable()
	_on_line_shown = Callable()
	if callback.is_valid():
		callback.call(choice_index)


func _clear_choices() -> void:
	if _choice_container == null:
		return
	for child in _choice_container.get_children():
		child.queue_free()
	_choice_container.visible = false


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
