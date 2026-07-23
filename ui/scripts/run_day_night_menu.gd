extends CanvasLayer

## Hub→zone picker shown on the black frame after the gate fade.
## Day is always available; Night (hard mode) stays locked until meta unlock.

signal mode_chosen(is_night: bool)

const DebugUiGate := preload("res://gameplay/debug/debug_ui_gate.gd")

var _root: Control
var _title: Label
var _hint: Label
var _day_btn: Button
var _night_btn: Button
var _lock_label: Label
var _open := false
var _resolved := false
var _chosen_night := false


func _ready() -> void:
	layer = 131
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	hide()
	set_process_input(false)
	set_process(false)


## Shows the picker and waits until the player picks Day or Night.
## Returns true for Night, false for Day.
func pick_mode(night_unlocked: bool) -> bool:
	_resolved = false
	_chosen_night = false
	_refresh_night_lock(night_unlocked)
	await _open_menu()
	while not _resolved:
		await get_tree().process_frame
	_close_menu()
	return _chosen_night


func _open_menu() -> void:
	_open = true
	show()
	set_process_input(true)
	set_process(true)
	DebugUiGate.begin(self)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	await get_tree().process_frame
	if _day_btn != null:
		_day_btn.grab_focus.call_deferred()


func _close_menu() -> void:
	if not _open:
		return
	_open = false
	hide()
	set_process_input(false)
	set_process(false)
	DebugUiGate.end(self)


func _process(_delta: float) -> void:
	if not _open:
		return
	if Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _input(event: InputEvent) -> void:
	if not _open or _resolved:
		return
	if event.is_action_pressed("ui_accept") and _day_btn != null and _day_btn.has_focus():
		_resolve_choice(false)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_accept") and _night_btn != null and _night_btn.has_focus() and not _night_btn.disabled:
		_resolve_choice(true)
		get_viewport().set_input_as_handled()
		return
	var key_event := event as InputEventKey
	if key_event != null and key_event.pressed and not key_event.echo:
		if key_event.keycode == KEY_1:
			_resolve_choice(false)
			get_viewport().set_input_as_handled()
		elif key_event.keycode == KEY_2 and _night_btn != null and not _night_btn.disabled:
			_resolve_choice(true)
			get_viewport().set_input_as_handled()


func _resolve_choice(is_night: bool) -> void:
	if _resolved:
		return
	if is_night and _night_btn != null and _night_btn.disabled:
		return
	_chosen_night = is_night
	_resolved = true
	mode_chosen.emit(is_night)


func _refresh_night_lock(night_unlocked: bool) -> void:
	if _night_btn == null:
		return
	_night_btn.disabled = not night_unlocked
	if night_unlocked:
		_lock_label.text = "Night is hard mode — darker and tougher."
		_lock_label.modulate = Color(0.85, 0.82, 0.7, 1.0)
	else:
		_lock_label.text = "Night (Hard) — locked. Clear a zone to unlock."
		_lock_label.modulate = Color(0.7, 0.55, 0.45, 1.0)


func _build_ui() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.02, 0.04, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 280)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	margin.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.mouse_filter = Control.MOUSE_FILTER_STOP
	margin.add_child(vbox)

	_title = Label.new()
	_title.text = "Choose Difficulty"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(_title)

	_hint = Label.new()
	_hint.text = "Day starts at 8:52. Night is hard mode."
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 14)
	_hint.modulate = Color(0.85, 0.82, 0.7, 1.0)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_hint)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 16)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.mouse_filter = Control.MOUSE_FILTER_STOP
	vbox.add_child(buttons)

	_day_btn = _make_mode_button("Day", "Standard")
	_day_btn.pressed.connect(_resolve_choice.bind(false))
	buttons.add_child(_day_btn)

	_night_btn = _make_mode_button("Night", "Hard")
	_night_btn.pressed.connect(_resolve_choice.bind(true))
	buttons.add_child(_night_btn)

	_lock_label = Label.new()
	_lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lock_label.add_theme_font_size_override("font_size", 13)
	_lock_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_lock_label)

	var key_hint := Label.new()
	key_hint.text = "Press 1 for Day, 2 for Night"
	key_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_hint.add_theme_font_size_override("font_size", 12)
	key_hint.modulate = Color(0.65, 0.62, 0.55, 1.0)
	vbox.add_child(key_hint)


func _make_mode_button(title: String, subtitle: String) -> Button:
	var btn := Button.new()
	btn.text = "%s\n%s" % [title, subtitle]
	btn.custom_minimum_size = Vector2(160, 88)
	btn.focus_mode = Control.FOCUS_ALL
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.add_theme_font_size_override("font_size", 18)
	return btn
