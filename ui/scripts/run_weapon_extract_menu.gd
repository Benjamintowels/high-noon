extends CanvasLayer

## Victory extract picker: choose one owned weapon to keep before returning to hub.

signal weapon_chosen(weapon_id: int)
signal cancelled

const DebugUiGate := preload("res://gameplay/debug/debug_ui_gate.gd")

const COLUMNS := 4
const CELL_SIZE := Vector2(96, 112)

var _root: Control
var _grid: GridContainer
var _scroll: ScrollContainer
var _title: Label
var _hint: Label
var _open := false
var _weapon_ids: Array[int] = []
var _resolved := false
var _chosen_id := -1


func _ready() -> void:
	layer = 131
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	hide()
	set_process_input(false)
	set_process(false)


## Shows the picker and waits until the player picks a weapon or cancels.
## Returns the chosen weapon id, or -1 if cancelled / empty.
func pick_weapon(weapon_ids: Array[int]) -> int:
	_weapon_ids = weapon_ids.duplicate()
	_resolved = false
	_chosen_id = -1
	await _open_menu()
	while not _resolved:
		await get_tree().process_frame
	_close_menu()
	return _chosen_id


func _open_menu() -> void:
	_rebuild_grid()
	_open = true
	show()
	set_process_input(true)
	set_process(true)
	DebugUiGate.begin(self)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# Layout needs a frame so button hit-rects match the visible grid.
	await get_tree().process_frame
	if _scroll != null:
		_scroll.grab_focus.call_deferred()


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
	# Portal extract leaves the player transition-locked; keep the cursor free
	# even if something else tries to re-capture it.
	if Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _input(event: InputEvent) -> void:
	if not _open or _resolved:
		return
	if event.is_action_pressed("ui_cancel") or (
		event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE
	):
		_resolve_cancel()
		get_viewport().set_input_as_handled()
		return
	# Number keys 1-9 pick by grid order as a fallback when GUI clicks fail.
	var key_event := event as InputEventKey
	if key_event != null and key_event.pressed and not key_event.echo:
		var digit: int = key_event.keycode - KEY_1
		if digit >= 0 and digit < _weapon_ids.size() and digit < 9:
			_resolve_choice(_weapon_ids[digit])
			get_viewport().set_input_as_handled()


func _resolve_choice(weapon_id: int) -> void:
	if _resolved:
		return
	_chosen_id = weapon_id
	_resolved = true
	weapon_chosen.emit(weapon_id)


func _resolve_cancel() -> void:
	if _resolved:
		return
	_chosen_id = -1
	_resolved = true
	cancelled.emit()


func _build_ui() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.02, 0.04, 0.7)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# STOP (not IGNORE) so the centered panel stays in the GUI hit path while
	# a fullscreen fade/dim sibling is present under the same root.
	center.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 480)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	margin.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.mouse_filter = Control.MOUSE_FILTER_STOP
	margin.add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)

	_title = Label.new()
	_title.text = "Extract One Weapon"
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.add_theme_font_size_override("font_size", 22)
	header.add_child(_title)

	var skip_btn := Button.new()
	skip_btn.text = "Take None"
	skip_btn.focus_mode = Control.FOCUS_NONE
	skip_btn.pressed.connect(_resolve_cancel)
	header.add_child(skip_btn)

	_hint = Label.new()
	_hint.text = "Click a weapon (or press 1-9). Esc / Take None leaves only your revolver."
	_hint.add_theme_font_size_override("font_size", 13)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.modulate = Color(0.85, 0.82, 0.7, 1.0)
	vbox.add_child(_hint)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.custom_minimum_size = Vector2(0, 340)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.focus_mode = Control.FOCUS_ALL
	_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	vbox.add_child(_scroll)

	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	_grid.mouse_filter = Control.MOUSE_FILTER_STOP
	_scroll.add_child(_grid)


func _rebuild_grid() -> void:
	for child in _grid.get_children():
		child.queue_free()
	for weapon_id in _weapon_ids:
		_grid.add_child(_make_weapon_cell(weapon_id))


func _make_weapon_cell(weapon_id: int) -> Control:
	var cell := VBoxContainer.new()
	cell.custom_minimum_size = CELL_SIZE
	cell.add_theme_constant_override("separation", 4)
	cell.mouse_filter = Control.MOUSE_FILTER_STOP

	var button := Button.new()
	button.custom_minimum_size = Vector2(CELL_SIZE.x, 80)
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	var icon := GroyperWeapons.get_icon(weapon_id as GroyperWeapons.Id)
	if icon != null:
		button.icon = icon
		button.expand_icon = true
	button.pressed.connect(_resolve_choice.bind(weapon_id))
	cell.add_child(button)

	var label := Label.new()
	label.text = PlayerInventory.get_weapon_display_name(weapon_id)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 11)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(label)
	return cell
