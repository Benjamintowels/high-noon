extends CanvasLayer

## In-game RightArm offset tuner for 1H HipFireAim.
## O — pause (no inventory) and open. Esc / O — close (offsets stay).
## Tab — edit Hip vs ADS. Arrows — X/Y. [ ] — Z. Shift — fine step.
## Enter — lock values to disk + print for baking. R — reset current slot.

const DebugUiGate := preload("res://gameplay/debug/debug_ui_gate.gd")

const TOGGLE_KEY := KEY_O
const STEP_DEG := 2.0
const FINE_STEP_DEG := 0.5

enum EditTarget { HIP, ADS }

var _player: Node = null
var _open := false
var _paused_by_us := false
var _edit_target := EditTarget.HIP
var _root: Control
var _label: Label


func _ready() -> void:
	layer = 125
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	hide()
	set_process(false)
	set_process_input(false)


func setup(player: Node) -> void:
	_player = player


func is_open() -> bool:
	return _open


func toggle() -> void:
	if _open:
		close_menu()
	else:
		open_menu()


func open_menu() -> void:
	if _open:
		return
	var rig := _get_weapon_rig()
	if rig == null:
		push_warning("HipFireArmOffsetDebug: no weapon rig on player.")
		return
	if rig.has_method("load_debug_arm_offsets_from_disk"):
		rig.load_debug_arm_offsets_from_disk()
	_open = true
	show()
	set_process(true)
	set_process_input(true)
	_paused_by_us = not get_tree().paused
	if _paused_by_us:
		get_tree().paused = true
	DebugUiGate.begin(self)
	_apply_preview()
	_refresh_label()


func close_menu() -> void:
	if not _open:
		return
	_open = false
	hide()
	set_process(false)
	set_process_input(false)
	DebugUiGate.end(self)
	if _paused_by_us:
		get_tree().paused = false
		_paused_by_us = false


func _process(_delta: float) -> void:
	if not _open:
		return
	_apply_preview()
	_refresh_label()


func _input(event: InputEvent) -> void:
	if not _open:
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key_event := event as InputEventKey
	var keycode := key_event.keycode

	if keycode == TOGGLE_KEY or keycode == KEY_ESCAPE:
		close_menu()
		get_viewport().set_input_as_handled()
		return

	if keycode == KEY_TAB:
		_edit_target = (
			EditTarget.ADS if _edit_target == EditTarget.HIP else EditTarget.HIP
		)
		_apply_preview()
		_refresh_label()
		get_viewport().set_input_as_handled()
		return

	if keycode == KEY_ENTER or keycode == KEY_KP_ENTER:
		_lock_offsets()
		get_viewport().set_input_as_handled()
		return

	if keycode == KEY_R:
		_set_current_offset(Vector3.ZERO)
		_apply_preview()
		_refresh_label()
		get_viewport().set_input_as_handled()
		return

	var step := FINE_STEP_DEG if key_event.shift_pressed else STEP_DEG
	var delta := Vector3.ZERO
	match keycode:
		KEY_UP:
			delta.x += step
		KEY_DOWN:
			delta.x -= step
		KEY_LEFT:
			delta.y -= step
		KEY_RIGHT:
			delta.y += step
		KEY_BRACKETLEFT:
			delta.z -= step
		KEY_BRACKETRIGHT:
			delta.z += step
		_:
			return

	_set_current_offset(_get_current_offset() + delta)
	_apply_preview()
	_refresh_label()
	get_viewport().set_input_as_handled()


func _build_ui() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_label = Label.new()
	_label.name = "Hud"
	_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_label.position = Vector2(16, 16)
	_label.add_theme_font_size_override("font_size", 16)
	_label.add_theme_color_override("font_color", Color(0.95, 0.92, 0.75, 1.0))
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_label.add_theme_constant_override("outline_size", 4)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_label)


func _get_weapon_rig() -> Node:
	if _player == null or not is_instance_valid(_player):
		return null
	return _player.get_node_or_null("WeaponRig")


func _editing_ads() -> bool:
	return _edit_target == EditTarget.ADS


func _get_current_offset() -> Vector3:
	var rig := _get_weapon_rig()
	if rig == null or not rig.has_method("get_debug_arm_offset_euler_deg"):
		return Vector3.ZERO
	return rig.get_debug_arm_offset_euler_deg(_editing_ads())


func _set_current_offset(euler_deg: Vector3) -> void:
	var rig := _get_weapon_rig()
	if rig == null or not rig.has_method("set_debug_arm_offset_euler_deg"):
		return
	rig.set_debug_arm_offset_euler_deg(_editing_ads(), euler_deg)


func _apply_preview() -> void:
	var rig := _get_weapon_rig()
	if rig == null or not rig.has_method("apply_debug_arm_pose_preview"):
		return
	rig.apply_debug_arm_pose_preview(_editing_ads())


func _lock_offsets() -> void:
	var rig := _get_weapon_rig()
	if rig == null or not rig.has_method("lock_debug_arm_offsets"):
		return
	var summary: String = rig.lock_debug_arm_offsets()
	print(summary)
	_refresh_label()


func _refresh_label() -> void:
	var hip := Vector3.ZERO
	var ads := Vector3.ZERO
	var rig := _get_weapon_rig()
	if rig != null and rig.has_method("get_debug_arm_offset_euler_deg"):
		hip = rig.get_debug_arm_offset_euler_deg(false)
		ads = rig.get_debug_arm_offset_euler_deg(true)
	var slot := "ADS" if _editing_ads() else "HIP"
	_label.text = (
		"1H RightArm offset debug (PAUSED)\n"
		+ "Editing: %s   (Tab = switch Hip/ADS)\n"
		+ "Hip  XYZ deg: %s\n"
		+ "ADS  XYZ deg: %s\n"
		+ "Up/Down = X   Left/Right = Y   [ ] = Z\n"
		+ "Shift = fine (0.5°)   R = reset slot\n"
		+ "Enter = LOCK for bake   O/Esc = close (keep offsets)"
	) % [slot, _fmt_vec(hip), _fmt_vec(ads)]


func _fmt_vec(v: Vector3) -> String:
	return "(%.2f, %.2f, %.2f)" % [v.x, v.y, v.z]
