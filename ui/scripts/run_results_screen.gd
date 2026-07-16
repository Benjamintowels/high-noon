extends CanvasLayer

## Animated run extract screen shown on a black frame after death / victory
## portal, before the hub fades in.

signal dismissed

const ANIM_ROW_STAGGER := 0.18
const COUNT_DURATION := 0.85
const SLASH_DELAY := 0.35
const HALF_TWEEN := 0.55

var _root: Control
var _panel: PanelContainer
var _title: Label
var _hint: Label
var _rows: VBoxContainer
var _slash_layer: Control
var _busy := false
var _can_dismiss := false
var _victory := false


func _ready() -> void:
	layer = 130
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	visible = false


func play_results(payload: Dictionary) -> void:
	_busy = true
	_can_dismiss = false
	_victory = bool(payload.get("victory", false))
	visible = true

	var zone_title := str(payload.get("zone_title", "The Run"))
	_title.text = "%s Cleared" % zone_title if _victory else "Ye' Died — %s" % zone_title
	_title.modulate = Color(0.85, 0.95, 0.7, 1.0) if _victory else Color(0.95, 0.25, 0.2, 1.0)
	_hint.text = ""
	_hint.modulate.a = 0.0

	_clear_rows()
	var kills := int(payload.get("kills", 0))
	var gram_collected := int(payload.get("gram_collected", 0))
	var shards_collected := int(payload.get("soul_shards_collected", 0))
	var wallet_gram := int(payload.get("wallet_gram", 0))
	var wallet_shards := int(payload.get("wallet_shards", 0))
	var extract_gram := int(payload.get("extract_gram", 0))
	var extract_shards := int(payload.get("extract_shards", 0))
	var quest_items: Array = payload.get("quest_items", [])

	var kill_row := _add_stat_row("Kills", kills)
	var gram_row := _add_stat_row("Gram Collected", gram_collected)
	var shard_row := _add_stat_row("Soul Shards Collected", shards_collected)
	var extract_gram_row := _add_stat_row("Gram Extracted", wallet_gram)
	var extract_shard_row := _add_stat_row("Shards Extracted", wallet_shards)

	await _animate_count(kill_row, kills)
	await get_tree().create_timer(ANIM_ROW_STAGGER).timeout
	await _animate_count(gram_row, gram_collected)
	await get_tree().create_timer(ANIM_ROW_STAGGER).timeout
	await _animate_count(shard_row, shards_collected)
	await get_tree().create_timer(ANIM_ROW_STAGGER).timeout
	await _animate_count(extract_gram_row, wallet_gram)
	await get_tree().create_timer(ANIM_ROW_STAGGER).timeout
	await _animate_count(extract_shard_row, wallet_shards)

	if not _victory:
		await get_tree().create_timer(SLASH_DELAY).timeout
		await _play_half_slash(extract_gram_row, wallet_gram, extract_gram)
		await _play_half_slash(extract_shard_row, wallet_shards, extract_shards)
	elif not quest_items.is_empty():
		var parts: PackedStringArray = []
		for item_id in quest_items:
			parts.append(str(item_id))
		var quest_label := Label.new()
		quest_label.text = "Quest items secured: %s" % ", ".join(parts)
		quest_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		quest_label.add_theme_font_size_override("font_size", 18)
		quest_label.modulate = Color(0.75, 0.9, 1.0, 1.0)
		_rows.add_child(quest_label)

	_hint.text = "Press any key / click to continue"
	var hint_tween := create_tween()
	hint_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	hint_tween.tween_property(_hint, "modulate:a", 1.0, 0.35)
	_can_dismiss = true
	_busy = false

	while _can_dismiss:
		await get_tree().process_frame

	visible = false
	dismissed.emit()


func _input(event: InputEvent) -> void:
	# Must use _input (not _unhandled_input): the fullscreen root Control eats
	# mouse clicks with MOUSE_FILTER_STOP, so unhandled never sees them.
	_try_dismiss_from_event(event)


func _try_dismiss_from_event(event: InputEvent) -> void:
	if not visible or not _can_dismiss or _busy:
		return
	var pressed := false
	if event is InputEventKey and event.pressed and not event.echo:
		pressed = true
	elif event is InputEventMouseButton and event.pressed:
		pressed = true
	elif event is InputEventJoypadButton and event.pressed:
		pressed = true
	if not pressed:
		return
	_can_dismiss = false
	get_viewport().set_input_as_handled()


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.gui_input.connect(_on_root_gui_input)
	add_child(_root)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(dim)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(520, 360)
	_panel.offset_left = -260
	_panel.offset_top = -180
	_panel.offset_right = 260
	_panel.offset_bottom = 180
	_root.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 32)
	vbox.add_child(_title)

	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 10)
	vbox.add_child(_rows)

	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 16)
	_hint.modulate = Color(0.85, 0.85, 0.8, 0.0)
	vbox.add_child(_hint)

	_slash_layer = Control.new()
	_slash_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_slash_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_slash_layer)


func _on_root_gui_input(event: InputEvent) -> void:
	_try_dismiss_from_event(event)


func _clear_rows() -> void:
	for child in _rows.get_children():
		child.queue_free()


func _add_stat_row(label_text: String, _target: int) -> Dictionary:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_rows.add_child(row)

	var name_label := Label.new()
	name_label.text = label_text
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 20)
	row.add_child(name_label)

	var bar_wrap := Control.new()
	bar_wrap.custom_minimum_size = Vector2(180, 22)
	bar_wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(bar_wrap)

	var bar_bg := ColorRect.new()
	bar_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar_bg.color = Color(0.15, 0.12, 0.1, 0.9)
	bar_wrap.add_child(bar_bg)

	var bar_fill := ColorRect.new()
	bar_fill.color = Color(0.82, 0.62, 0.28, 1.0)
	bar_fill.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	bar_fill.offset_right = 0.0
	bar_wrap.add_child(bar_fill)

	var value_label := Label.new()
	value_label.text = "0"
	value_label.custom_minimum_size = Vector2(64, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_font_size_override("font_size", 22)
	row.add_child(value_label)

	return {
		"row": row,
		"bar_wrap": bar_wrap,
		"bar_fill": bar_fill,
		"value_label": value_label,
	}


func _animate_count(row_data: Dictionary, target: int) -> void:
	var value_label: Label = row_data.get("value_label")
	var bar_fill: ColorRect = row_data.get("bar_fill")
	var bar_wrap: Control = row_data.get("bar_wrap")
	var max_w := bar_wrap.size.x
	if max_w < 8.0:
		max_w = bar_wrap.custom_minimum_size.x

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_method(
		func(v: float) -> void:
			value_label.text = str(int(round(v)))
			var ratio := 0.0 if target <= 0 else clampf(v / float(maxi(target, 1)), 0.0, 1.0)
			bar_fill.offset_right = max_w * ratio,
		0.0,
		float(target),
		COUNT_DURATION
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tween.finished
	value_label.text = str(target)


func _play_half_slash(row_data: Dictionary, from_value: int, to_value: int) -> void:
	var row: Control = row_data.get("row")
	var value_label: Label = row_data.get("value_label")
	var bar_fill: ColorRect = row_data.get("bar_fill")
	var bar_wrap: Control = row_data.get("bar_wrap")
	var max_w := bar_wrap.size.x
	if max_w < 8.0:
		max_w = bar_wrap.custom_minimum_size.x

	var slash := ColorRect.new()
	slash.color = Color(0.95, 0.12, 0.1, 0.95)
	slash.custom_minimum_size = Vector2(row.size.x + 20.0, 4.0)
	slash.size = slash.custom_minimum_size
	slash.rotation = -0.35
	slash.position = row.global_position - _slash_layer.global_position + Vector2(-8, row.size.y * 0.45)
	_slash_layer.add_child(slash)

	var slash_tween := create_tween()
	slash_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	slash.modulate.a = 0.0
	slash_tween.tween_property(slash, "modulate:a", 1.0, 0.08)
	slash_tween.tween_interval(0.2)
	slash_tween.tween_property(slash, "modulate:a", 0.0, 0.25)
	await slash_tween.finished
	slash.queue_free()

	value_label.modulate = Color(1.0, 0.35, 0.3, 1.0)
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_method(
		func(v: float) -> void:
			value_label.text = str(int(round(v)))
			var ratio := 0.0 if from_value <= 0 else clampf(v / float(maxi(from_value, 1)), 0.0, 1.0)
			bar_fill.offset_right = max_w * ratio,
		float(from_value),
		float(to_value),
		HALF_TWEEN
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await tween.finished
	value_label.text = str(to_value)
