extends Control
class_name InventoryMenuPanel

const GroyperHatCatalog := preload("res://characters/groyper/groyper_hat_catalog.gd")

@onready var _gram_label: Label = $Panel/MarginContainer/VBoxContainer/GramRow/GramLabel
@onready var _soul_shard_label: Label = $Panel/MarginContainer/VBoxContainer/SoulShardRow/SoulShardLabel
@onready var _weapons_grid: GridContainer = $Panel/MarginContainer/VBoxContainer/WeaponsSection/WeaponsGrid
@onready var _items_grid: GridContainer = $Panel/MarginContainer/VBoxContainer/ItemsSection/ItemsGrid
@onready var _hats_grid: GridContainer = $Panel/MarginContainer/VBoxContainer/HatsSection/HatsGrid
@onready var _quests_list: VBoxContainer = $Panel/MarginContainer/VBoxContainer/QuestsSection/QuestsList
@onready var _mute_sound_check: CheckBox = %MuteSoundCheck
@onready var _time_of_day_label: Label = %TimeOfDayLabel
@onready var _day_night_slider: HSlider = %DayNightSlider

var _syncing_mute_setting := false
var _syncing_time_slider := false
var _hat_swap_dialog: ConfirmationDialog
var _pending_swap_hat_id := &""


func _ready() -> void:
	# Deferred: this menu is created during an autoload's _ready, before the
	# quest singletons have entered the tree and joined "quest_state".
	_connect_quest_signals.call_deferred()
	GameSettings.sound_muted_changed.connect(_on_sound_muted_changed)
	_mute_sound_check.toggled.connect(_on_mute_sound_toggled)
	_day_night_slider.value_changed.connect(_on_day_night_slider_changed)
	_setup_hat_swap_dialog()
	refresh()


func _connect_quest_signals() -> void:
	for quest in get_tree().get_nodes_in_group("quest_state"):
		quest.quest_accepted.connect(_on_quest_journal_changed)


func _setup_hat_swap_dialog() -> void:
	_hat_swap_dialog = ConfirmationDialog.new()
	_hat_swap_dialog.title = "Swap Hat"
	_hat_swap_dialog.ok_button_text = "Swap"
	_hat_swap_dialog.confirmed.connect(_on_hat_swap_confirmed)
	_hat_swap_dialog.canceled.connect(func() -> void: _pending_swap_hat_id = &"")
	add_child(_hat_swap_dialog)
	# The dialog is its own Window — hiding the menu doesn't hide it.
	visibility_changed.connect(
		func() -> void:
			if not visible and _hat_swap_dialog != null:
				_hat_swap_dialog.hide()
	)


func _on_hat_slot_clicked(hat_id: StringName) -> void:
	if hat_id == PlayerInventory.get_worn_hat():
		return
	_pending_swap_hat_id = hat_id
	_hat_swap_dialog.dialog_text = (
		"Swap to the %s?" % PlayerInventory.get_hat_display_name(hat_id)
	)
	_hat_swap_dialog.popup_centered()


func _on_hat_swap_confirmed() -> void:
	if _pending_swap_hat_id.is_empty():
		return
	PlayerInventory.set_worn_hat(_pending_swap_hat_id)
	_pending_swap_hat_id = &""


func refresh() -> void:
	_gram_label.text = "%d Gram" % PlayerInventory.gram
	_soul_shard_label.text = "%d Soul Shards" % PlayerInventory.get_soul_shards()
	_refresh_weapons()
	_refresh_items()
	_refresh_hats()
	_refresh_quests()
	_sync_mute_setting()
	_sync_time_slider()


func _sync_mute_setting() -> void:
	_syncing_mute_setting = true
	_mute_sound_check.button_pressed = GameSettings.sound_muted
	_syncing_mute_setting = false


func _on_mute_sound_toggled(pressed: bool) -> void:
	if _syncing_mute_setting:
		return
	GameSettings.set_sound_muted(pressed)


func _on_sound_muted_changed(muted: bool) -> void:
	_syncing_mute_setting = true
	_mute_sound_check.button_pressed = muted
	_syncing_mute_setting = false


func _sync_time_slider() -> void:
	_syncing_time_slider = true
	_day_night_slider.max_value = float(DayNightCycle.PHASE_COUNT - 1)
	_day_night_slider.step = 1.0
	_day_night_slider.value = float(DayNightCycle.current_phase)
	_time_of_day_label.text = DayNightCycle.get_phase_name()
	_syncing_time_slider = false


func _on_day_night_slider_changed(value: float) -> void:
	if _syncing_time_slider:
		return
	DayNightCycle.set_phase(int(round(value)))
	_time_of_day_label.text = DayNightCycle.get_phase_name()


func _on_quest_journal_changed() -> void:
	_refresh_quests()


func _on_soul_shard_pack_pressed(index: int) -> void:
	if PlayerInventory.use_soul_shard_pack(index) > 0:
		refresh()


func _refresh_weapons() -> void:
	for child in _weapons_grid.get_children():
		child.queue_free()

	var weapon_counts: Dictionary = {}
	for weapon_id in PlayerInventory.owned_weapons:
		weapon_counts[weapon_id] = int(weapon_counts.get(weapon_id, 0)) + 1

	for weapon_id: int in weapon_counts.keys():
		var slot := _create_item_slot(
			GroyperWeapons.get_icon(weapon_id),
			"%s x%d" % [PlayerInventory.get_weapon_display_name(weapon_id), weapon_counts[weapon_id]]
		)
		_weapons_grid.add_child(slot)


func _refresh_items() -> void:
	for child in _items_grid.get_children():
		child.queue_free()

	if PlayerInventory.has_knife:
		_items_grid.add_child(_create_item_slot(null, "Knife"))
	if PlayerInventory.has_sword_shield:
		_items_grid.add_child(_create_item_slot(null, "Sword & Shield"))
	if PlayerInventory.has_ruins_key:
		_items_grid.add_child(_create_item_slot(null, "Ruins Key"))
	if PlayerInventory.has_ranch_key:
		_items_grid.add_child(_create_item_slot(null, "Ranch Key"))
	if PlayerInventory.has_treasure_map:
		_items_grid.add_child(_create_item_slot(null, "Treasure Map"))
	if PlayerInventory.has_deputy_badge:
		_items_grid.add_child(_create_item_slot(null, "Deputy Star"))

	var packs: Array = PlayerInventory.get_soul_shard_packs()
	for i in range(packs.size()):
		var amount := int(packs[i])
		var pack_btn := Button.new()
		pack_btn.text = "Soul Shard Pack (+%d)" % amount
		pack_btn.tooltip_text = "Click to gain %d Soul Shards" % amount
		pack_btn.pressed.connect(_on_soul_shard_pack_pressed.bind(i))
		_items_grid.add_child(pack_btn)

	if _items_grid.get_child_count() == 0:
		var empty_label := Label.new()
		empty_label.text = "None"
		empty_label.add_theme_font_size_override("font_size", 10)
		empty_label.add_theme_color_override("font_color", Color(0.72, 0.68, 0.6, 1))
		_items_grid.add_child(empty_label)


func _refresh_hats() -> void:
	for child in _hats_grid.get_children():
		child.queue_free()

	var worn := PlayerInventory.get_worn_hat()
	for hat_id: StringName in PlayerInventory.owned_hats:
		var slot := _create_hat_slot(
			PlayerInventory.get_hat_display_name(hat_id),
			_hat_slot_color(hat_id),
			hat_id == worn
		)
		var clicked_id := hat_id
		slot.gui_input.connect(
			func(event: InputEvent) -> void:
				if (
					event is InputEventMouseButton
					and event.pressed
					and event.button_index == MOUSE_BUTTON_LEFT
				):
					_on_hat_slot_clicked(clicked_id)
		)
		_hats_grid.add_child(slot)


func _refresh_quests() -> void:
	for child in _quests_list.get_children():
		child.queue_free()

	var quest_labels: Array[String] = []
	for quest in get_tree().get_nodes_in_group("quest_state"):
		quest_labels.append_array(quest.get_active_quest_labels())
	if quest_labels.is_empty():
		var empty_label := Label.new()
		empty_label.text = "None"
		empty_label.add_theme_font_size_override("font_size", 10)
		empty_label.add_theme_color_override("font_color", Color(0.72, 0.68, 0.6, 1))
		_quests_list.add_child(empty_label)
		return

	for quest_label: String in quest_labels:
		var label := Label.new()
		label.text = quest_label
		label.add_theme_font_size_override("font_size", 10)
		_quests_list.add_child(label)


func _hat_slot_color(hat_id: StringName) -> Color:
	return GroyperHatCatalog.get_color(hat_id)


func _create_item_slot(icon: Texture2D, label_text: String) -> VBoxContainer:
	var slot := VBoxContainer.new()
	slot.add_theme_constant_override("separation", 4)

	if icon != null:
		var icon_rect := TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(48, 48)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.texture = icon
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(icon_rect)
	else:
		var placeholder := ColorRect.new()
		placeholder.custom_minimum_size = Vector2(48, 48)
		placeholder.color = Color(0.42, 0.38, 0.32, 1.0)
		placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(placeholder)

	var label := Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	slot.add_child(label)

	return slot


func _create_hat_slot(
	label_text: String,
	hat_color: Color = Color(0.92, 0.9, 0.86),
	is_worn: bool = false
) -> PanelContainer:
	var slot := PanelContainer.new()
	slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	slot.tooltip_text = "Worn" if is_worn else "Click to wear %s" % label_text

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.set_content_margin_all(4)
	if is_worn:
		style.border_color = Color(0.9, 0.78, 0.4, 1.0)
		style.set_border_width_all(2)
	slot.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(vbox)

	var hat_icon := ColorRect.new()
	hat_icon.custom_minimum_size = Vector2(48, 24)
	hat_icon.color = hat_color
	hat_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(hat_icon)

	var label := Label.new()
	label.text = label_text + ("\n(Worn)" if is_worn else "")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(label)

	return slot
