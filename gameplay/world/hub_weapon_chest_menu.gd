extends CanvasLayer

## Deposit / withdraw UI for the hub weapon storage chest.

signal weapon_selected(weapon_id: int)
signal closed

const DebugUiGate := preload("res://gameplay/debug/debug_ui_gate.gd")

enum Mode { DEPOSIT, WITHDRAW }

const COLUMNS := 4
const CELL_SIZE := Vector2(96, 112)

var _root: Control
var _grid: GridContainer
var _scroll: ScrollContainer
var _title: Label
var _hint: Label
var _deposit_btn: Button
var _withdraw_btn: Button
var _empty_label: Label
var _open := false
var _mode: Mode = Mode.DEPOSIT


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	hide()
	set_process_input(false)


func is_open() -> bool:
	return _open


func open_menu(start_mode: Mode = Mode.DEPOSIT) -> void:
	_mode = start_mode
	_sync_mode_buttons()
	_rebuild_grid()
	_open = true
	show()
	set_process_input(true)
	DebugUiGate.begin(self)
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


func get_mode() -> Mode:
	return _mode


func is_deposit_mode() -> bool:
	return _mode == Mode.DEPOSIT


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
	panel.custom_minimum_size = Vector2(540, 500)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)

	_title = Label.new()
	_title.text = "Weapon Chest"
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.add_theme_font_size_override("font_size", 20)
	header.add_child(_title)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.pressed.connect(close_menu)
	header.add_child(close_btn)

	var mode_row := HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 8)
	vbox.add_child(mode_row)

	_deposit_btn = Button.new()
	_deposit_btn.text = "Store"
	_deposit_btn.focus_mode = Control.FOCUS_NONE
	_deposit_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_deposit_btn.pressed.connect(_set_mode.bind(Mode.DEPOSIT))
	mode_row.add_child(_deposit_btn)

	_withdraw_btn = Button.new()
	_withdraw_btn.text = "Take Out"
	_withdraw_btn.focus_mode = Control.FOCUS_NONE
	_withdraw_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_withdraw_btn.pressed.connect(_set_mode.bind(Mode.WITHDRAW))
	mode_row.add_child(_withdraw_btn)

	_hint = Label.new()
	_hint.add_theme_font_size_override("font_size", 12)
	_hint.modulate = Color(0.85, 0.82, 0.7, 1.0)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_hint)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.custom_minimum_size = Vector2(0, 340)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.focus_mode = Control.FOCUS_ALL
	vbox.add_child(_scroll)

	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	_scroll.add_child(_grid)

	_empty_label = Label.new()
	_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_label.add_theme_font_size_override("font_size", 16)
	_empty_label.modulate = Color(0.7, 0.68, 0.6, 1.0)
	_empty_label.visible = false
	vbox.add_child(_empty_label)


func _set_mode(mode: Mode) -> void:
	_mode = mode
	_sync_mode_buttons()
	_rebuild_grid()


func _sync_mode_buttons() -> void:
	_deposit_btn.disabled = _mode == Mode.DEPOSIT
	_withdraw_btn.disabled = _mode == Mode.WITHDRAW
	if _mode == Mode.DEPOSIT:
		_hint.text = "Store a weapon from your pack into the chest. It stays safe on your save."
	else:
		_hint.text = "Take a stored weapon out into your pack for the next run."


func _rebuild_grid() -> void:
	for child in _grid.get_children():
		child.queue_free()

	var ids: Array[int] = []
	if _mode == Mode.DEPOSIT:
		ids = _deposit_candidates()
		_empty_label.text = "Nothing in your pack to store."
	else:
		ids = RunMetaProgress.get_stored_weapons_unique()
		_empty_label.text = "Chest is empty."

	_empty_label.visible = ids.is_empty()
	for weapon_id in ids:
		_grid.add_child(_make_weapon_cell(weapon_id))


func _deposit_candidates() -> Array[int]:
	var result: Array[int] = []
	var seen: Dictionary = {}
	for weapon_id in PlayerInventory.get_unique_owned_weapons():
		if weapon_id == GroyperWeapons.Id.UNARMED:
			continue
		# Keep at least the starting revolver on the player when it's their only gun.
		if (
			weapon_id == GroyperWeapons.Id.REVOLVER
			and PlayerInventory.count_weapon(GroyperWeapons.Id.REVOLVER) <= 1
			and _non_revolver_owned_count() == 0
		):
			continue
		if seen.has(weapon_id):
			continue
		seen[weapon_id] = true
		result.append(weapon_id)
	return result


func _non_revolver_owned_count() -> int:
	var count := 0
	for weapon_id in PlayerInventory.owned_weapons:
		if weapon_id != GroyperWeapons.Id.REVOLVER and weapon_id != GroyperWeapons.Id.UNARMED:
			count += 1
	return count


func _make_weapon_cell(weapon_id: int) -> Control:
	var cell := VBoxContainer.new()
	cell.custom_minimum_size = CELL_SIZE
	cell.add_theme_constant_override("separation", 4)

	var button := Button.new()
	button.custom_minimum_size = Vector2(CELL_SIZE.x, 80)
	button.focus_mode = Control.FOCUS_NONE
	var icon := GroyperWeapons.get_icon(weapon_id as GroyperWeapons.Id)
	if icon != null:
		button.icon = icon
		button.expand_icon = true
	button.pressed.connect(_on_weapon_pressed.bind(weapon_id))
	cell.add_child(button)

	var label := Label.new()
	var count := 0
	if _mode == Mode.DEPOSIT:
		count = PlayerInventory.count_weapon(weapon_id)
	else:
		count = RunMetaProgress.count_stored_weapon(weapon_id)
	var name_text := PlayerInventory.get_weapon_display_name(weapon_id)
	label.text = name_text if count <= 1 else "%s ×%d" % [name_text, count]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 11)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(label)
	return cell


func _on_weapon_pressed(weapon_id: int) -> void:
	weapon_selected.emit(weapon_id)
	# Stay open so the player can store/take several; refresh the grid.
	_rebuild_grid()


func _on_dim_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close_menu()
		_root.accept_event()
