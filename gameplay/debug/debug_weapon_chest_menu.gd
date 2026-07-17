extends CanvasLayer

## Clickable grid of every registered weapon for the debug armory chest.

signal weapon_selected(weapon_id: int)
signal closed

const DebugUiGate := preload("res://gameplay/debug/debug_ui_gate.gd")

const COLUMNS := 4
const CELL_SIZE := Vector2(96, 112)

var _root: Control
var _grid: GridContainer
var _scroll: ScrollContainer
var _open := false


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	hide()
	set_process_input(false)


func is_open() -> bool:
	return _open


func open_menu() -> void:
	_rebuild_grid()
	_open = true
	show()
	set_process_input(true)
	DebugUiGate.begin(self)
	# Give the scroll area focus so wheel events land on the grid, not gameplay.
	if _scroll != null:
		_scroll.grab_focus.call_deferred()


func close_menu() -> void:
	if not _open:
		return
	_open = false
	hide()
	set_process_input(false)
	DebugUiGate.end(self)
	closed.emit()


func _input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("ui_cancel") or (
		event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE
	):
		close_menu()
		get_viewport().set_input_as_handled()


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
	dim.gui_input.connect(_on_dim_gui_input)
	_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 460)
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

	var title := Label.new()
	title.text = "Debug Armory"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 20)
	header.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.pressed.connect(close_menu)
	header.add_child(close_btn)

	var hint := Label.new()
	hint.text = "Click a weapon to drop it. Scroll the list. Esc / click outside to close."
	hint.add_theme_font_size_override("font_size", 12)
	hint.modulate = Color(0.85, 0.82, 0.7, 1.0)
	vbox.add_child(hint)

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

	for weapon_id in GroyperWeapons.get_debug_spawn_weapon_ids():
		_grid.add_child(_make_weapon_cell(weapon_id))


func _make_weapon_cell(weapon_id: int) -> Control:
	var cell := VBoxContainer.new()
	cell.custom_minimum_size = CELL_SIZE
	cell.add_theme_constant_override("separation", 4)
	cell.mouse_filter = Control.MOUSE_FILTER_STOP

	var button := Button.new()
	button.custom_minimum_size = Vector2(CELL_SIZE.x, 80)
	button.focus_mode = Control.FOCUS_NONE
	button.clip_text = true
	var icon := GroyperWeapons.get_icon(weapon_id as GroyperWeapons.Id)
	if icon != null:
		button.icon = icon
		button.expand_icon = true
	button.text = ""
	button.pressed.connect(_on_weapon_pressed.bind(weapon_id))
	cell.add_child(button)

	var label := Label.new()
	label.text = PlayerInventory.get_weapon_display_name(weapon_id)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 11)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(label)

	return cell


func _on_weapon_pressed(weapon_id: int) -> void:
	weapon_selected.emit(weapon_id)
	close_menu()


func _on_dim_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close_menu()
		_root.accept_event()
