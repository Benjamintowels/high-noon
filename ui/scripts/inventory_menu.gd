extends Control
class_name InventoryMenuPanel

const GroyperHatCatalog := preload("res://characters/groyper/groyper_hat_catalog.gd")
const ElementalGems := preload("res://gameplay/items/elemental_gems.gd")

const GEM_BADGE_SIZE := 12.0

@onready var _gram_label: Label = $Panel/MarginContainer/VBoxContainer/GramRow/GramLabel
@onready var _soul_shard_label: Label = $Panel/MarginContainer/VBoxContainer/SoulShardRow/SoulShardLabel
@onready var _strength_label: Label = $Panel/MarginContainer/VBoxContainer/StrengthRow/StrengthLabel
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
## Shared picker dialog (embed free gem → weapon, or weapon → gem source).
var _gem_picker_dialog: AcceptDialog
var _gem_picker_list: VBoxContainer
var _gem_picker_hint: Label
## Free-gem flow: gem chosen first, then a weapon.
var _pending_embed_gem_id := &""
## Weapon flow: weapon chosen first, then attach/swap/remove.
var _pending_weapon_gem_id := -1
var _weapon_gem_dialog: AcceptDialog
var _weapon_gem_list: VBoxContainer
var _weapon_gem_hint: Label


func _ready() -> void:
	# Deferred: this menu is created during an autoload's _ready, before the
	# quest singletons have entered the tree and joined "quest_state".
	_connect_quest_signals.call_deferred()
	GameSettings.sound_muted_changed.connect(_on_sound_muted_changed)
	_mute_sound_check.toggled.connect(_on_mute_sound_toggled)
	_day_night_slider.value_changed.connect(_on_day_night_slider_changed)
	_setup_hat_swap_dialog()
	_setup_gem_picker_dialog()
	_setup_weapon_gem_dialog()
	if not PlayerInventory.inventory_changed.is_connected(_on_inventory_changed):
		PlayerInventory.inventory_changed.connect(_on_inventory_changed)
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
			if not visible:
				if _hat_swap_dialog != null:
					_hat_swap_dialog.hide()
				if _gem_picker_dialog != null:
					_gem_picker_dialog.hide()
				if _weapon_gem_dialog != null:
					_weapon_gem_dialog.hide()
	)


func _setup_gem_picker_dialog() -> void:
	_gem_picker_dialog = AcceptDialog.new()
	_gem_picker_dialog.title = "Select Gem"
	_gem_picker_dialog.ok_button_text = "Cancel"
	_gem_picker_dialog.dialog_hide_on_ok = true
	_gem_picker_dialog.canceled.connect(_clear_gem_picker_pending)
	_gem_picker_dialog.confirmed.connect(_clear_gem_picker_pending)

	var built := _build_dialog_list_body(_gem_picker_dialog, "Choose a gem:")
	_gem_picker_hint = built["hint"]
	_gem_picker_list = built["list"]
	add_child(_gem_picker_dialog)


func _setup_weapon_gem_dialog() -> void:
	_weapon_gem_dialog = AcceptDialog.new()
	_weapon_gem_dialog.title = "Weapon Gem"
	_weapon_gem_dialog.ok_button_text = "Cancel"
	_weapon_gem_dialog.dialog_hide_on_ok = true
	_weapon_gem_dialog.canceled.connect(func() -> void: _pending_weapon_gem_id = -1)
	_weapon_gem_dialog.confirmed.connect(func() -> void: _pending_weapon_gem_id = -1)

	var built := _build_dialog_list_body(_weapon_gem_dialog, "")
	_weapon_gem_hint = built["hint"]
	_weapon_gem_list = built["list"]
	add_child(_weapon_gem_dialog)


func _build_dialog_list_body(dialog: AcceptDialog, hint_text: String) -> Dictionary:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	dialog.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var hint := Label.new()
	hint.text = hint_text
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 11)
	vbox.add_child(hint)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(280, 200)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)
	return {"hint": hint, "list": list}


func _clear_gem_picker_pending() -> void:
	_pending_embed_gem_id = &""
	_pending_weapon_gem_id = -1


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


func _on_inventory_changed() -> void:
	if visible:
		refresh()


func refresh() -> void:
	_gram_label.text = "%d Gram" % PlayerInventory.gram
	_soul_shard_label.text = "%d Soul Shards" % PlayerInventory.get_soul_shards()
	_strength_label.text = "%d Strength" % PlayerInventory.get_strength()
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
	# Unarmed is always available for gem embedding / display.
	if not weapon_counts.has(GroyperWeapons.Id.UNARMED):
		weapon_counts[GroyperWeapons.Id.UNARMED] = 1

	for weapon_id: int in weapon_counts.keys():
		var count := int(weapon_counts[weapon_id])
		var label_text := PlayerInventory.get_weapon_display_name(weapon_id)
		if weapon_id != GroyperWeapons.Id.UNARMED:
			label_text = "%s x%d" % [label_text, count]
		var slot := _create_weapon_slot(weapon_id, label_text)
		_weapons_grid.add_child(slot)


func _create_weapon_slot(weapon_id: int, label_text: String) -> PanelContainer:
	var slot := PanelContainer.new()
	slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var embedded := PlayerInventory.get_embedded_gems(weapon_id)
	if embedded.is_empty():
		slot.tooltip_text = "Click to attach a gem"
	else:
		slot.tooltip_text = (
			"%s — click to swap or remove"
			% ElementalGems.get_display_name(embedded[0])
		)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.set_content_margin_all(4)
	slot.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(vbox)

	var icon_host := Control.new()
	icon_host.custom_minimum_size = Vector2(48, 48)
	icon_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon_host)

	var icon := GroyperWeapons.get_icon(weapon_id)
	if icon != null:
		var icon_rect := TextureRect.new()
		icon_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.texture = icon
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_host.add_child(icon_rect)
	else:
		var placeholder := ColorRect.new()
		placeholder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		placeholder.color = Color(0.42, 0.38, 0.32, 1.0)
		placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_host.add_child(placeholder)

	if not embedded.is_empty():
		var gem_id: StringName = embedded[0]
		var badge := _create_gem_badge(ElementalGems.get_color(gem_id))
		badge.position = Vector2(48.0 - GEM_BADGE_SIZE - 1.0, 1.0)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_host.add_child(badge)

	var label := Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(label)

	var clicked_weapon := weapon_id
	slot.gui_input.connect(
		func(event: InputEvent) -> void:
			if (
				event is InputEventMouseButton
				and event.pressed
				and event.button_index == MOUSE_BUTTON_LEFT
			):
				_on_weapon_slot_clicked(clicked_weapon)
	)

	return slot


func _create_gem_badge(color: Color) -> ColorRect:
	var badge := ColorRect.new()
	badge.custom_minimum_size = Vector2(GEM_BADGE_SIZE, GEM_BADGE_SIZE)
	badge.size = Vector2(GEM_BADGE_SIZE, GEM_BADGE_SIZE)
	badge.color = color
	return badge


func _on_weapon_slot_clicked(weapon_id: int) -> void:
	if GroyperWeapons.get_gem_slots(weapon_id as GroyperWeapons.Id) <= 0:
		return
	_pending_weapon_gem_id = weapon_id
	_pending_embed_gem_id = &""
	_rebuild_weapon_gem_actions(weapon_id)
	_weapon_gem_dialog.title = PlayerInventory.get_weapon_display_name(weapon_id)
	_weapon_gem_dialog.popup_centered()


func _rebuild_weapon_gem_actions(weapon_id: int) -> void:
	for child in _weapon_gem_list.get_children():
		child.queue_free()

	var embedded := PlayerInventory.get_embedded_gems(weapon_id)
	if embedded.is_empty():
		_weapon_gem_hint.text = "No gem embedded. Attach one:"
	else:
		_weapon_gem_hint.text = (
			"Current: %s. Swap it, or remove it back to inventory:"
			% ElementalGems.get_display_name(embedded[0])
		)

	var attach_label := "Attach Gem" if embedded.is_empty() else "Swap Gem"
	var attach_btn := Button.new()
	attach_btn.text = attach_label
	attach_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	attach_btn.pressed.connect(_on_weapon_attach_or_swap_pressed)
	_weapon_gem_list.add_child(attach_btn)

	if not embedded.is_empty():
		var remove_btn := Button.new()
		remove_btn.text = "Remove Gem"
		remove_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		remove_btn.pressed.connect(_on_weapon_remove_gem_pressed)
		_weapon_gem_list.add_child(remove_btn)


func _on_weapon_attach_or_swap_pressed() -> void:
	if _pending_weapon_gem_id < 0:
		return
	_weapon_gem_dialog.hide()
	_open_gem_source_picker_for_weapon(_pending_weapon_gem_id)


func _on_weapon_remove_gem_pressed() -> void:
	if _pending_weapon_gem_id < 0:
		return
	var weapon_id := _pending_weapon_gem_id
	_pending_weapon_gem_id = -1
	_weapon_gem_dialog.hide()
	if PlayerInventory.remove_embedded_gem(weapon_id, 0):
		refresh()


func _open_gem_source_picker_for_weapon(weapon_id: int) -> void:
	_pending_weapon_gem_id = weapon_id
	_pending_embed_gem_id = &""
	_rebuild_gem_source_list(weapon_id)
	var embedded := PlayerInventory.get_embedded_gems(weapon_id)
	_gem_picker_dialog.title = (
		"Swap Gem" if not embedded.is_empty() else "Attach Gem"
	)
	_gem_picker_hint.text = (
		"Choose a free gem, or one already on another weapon:"
	)
	_gem_picker_dialog.popup_centered()


func _rebuild_gem_source_list(target_weapon_id: int) -> void:
	for child in _gem_picker_list.get_children():
		child.queue_free()

	var any := false

	var free_counts: Dictionary = {}
	for gem_id in PlayerInventory.get_owned_elemental_gems():
		free_counts[gem_id] = int(free_counts.get(gem_id, 0)) + 1
	if not free_counts.is_empty():
		_gem_picker_list.add_child(_make_section_label("Free Gems"))
		for gem_id: StringName in free_counts.keys():
			any = true
			var count := int(free_counts[gem_id])
			var text := ElementalGems.get_display_name(gem_id)
			if count > 1:
				text = "%s x%d" % [text, count]
			var btn := Button.new()
			btn.text = text
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.pressed.connect(
				_on_gem_source_chosen.bind(gem_id, -1, target_weapon_id)
			)
			_gem_picker_list.add_child(btn)

	var embedded_sources: Array[Dictionary] = []
	for entry in PlayerInventory.get_embedded_gem_locations():
		var source_weapon := int(entry.get("weapon_id", -1))
		if source_weapon == target_weapon_id:
			continue
		embedded_sources.append(entry)
	if not embedded_sources.is_empty():
		_gem_picker_list.add_child(_make_section_label("On Other Weapons"))
		for entry in embedded_sources:
			any = true
			var gem_id: StringName = entry["gem_id"]
			var source_weapon := int(entry["weapon_id"])
			var btn := Button.new()
			btn.text = "%s (on %s)" % [
				ElementalGems.get_display_name(gem_id),
				PlayerInventory.get_weapon_display_name(source_weapon),
			]
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.pressed.connect(
				_on_gem_source_chosen.bind(gem_id, source_weapon, target_weapon_id)
			)
			_gem_picker_list.add_child(btn)

	if not any:
		var empty := Label.new()
		empty.text = "No gems available to attach."
		empty.add_theme_font_size_override("font_size", 11)
		empty.add_theme_color_override("font_color", Color(0.75, 0.7, 0.62, 1))
		_gem_picker_list.add_child(empty)


func _make_section_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(0.85, 0.78, 0.55, 1))
	return label


func _on_gem_source_chosen(
	gem_id: StringName,
	source_weapon_id: int,
	target_weapon_id: int
) -> void:
	_pending_weapon_gem_id = -1
	_pending_embed_gem_id = &""
	_gem_picker_dialog.hide()
	if PlayerInventory.assign_gem_to_weapon(target_weapon_id, gem_id, source_weapon_id):
		refresh()


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

	var gem_counts: Dictionary = {}
	for gem_id in PlayerInventory.get_owned_elemental_gems():
		gem_counts[gem_id] = int(gem_counts.get(gem_id, 0)) + 1
	for gem_id: StringName in gem_counts.keys():
		var count := int(gem_counts[gem_id])
		var label_text := ElementalGems.get_display_name(gem_id)
		if count > 1:
			label_text = "%s x%d" % [label_text, count]
		var gem_slot := _create_gem_item_slot(gem_id, label_text)
		_items_grid.add_child(gem_slot)

	if _items_grid.get_child_count() == 0:
		var empty_label := Label.new()
		empty_label.text = "None"
		empty_label.add_theme_font_size_override("font_size", 10)
		empty_label.add_theme_color_override("font_color", Color(0.72, 0.68, 0.6, 1))
		_items_grid.add_child(empty_label)


func _create_gem_item_slot(gem_id: StringName, label_text: String) -> PanelContainer:
	var slot := PanelContainer.new()
	slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	slot.tooltip_text = "Click to embed %s into a weapon" % ElementalGems.get_display_name(gem_id)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.set_content_margin_all(4)
	slot.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(vbox)

	var gem_icon := ColorRect.new()
	gem_icon.custom_minimum_size = Vector2(48, 48)
	gem_icon.color = ElementalGems.get_color(gem_id)
	gem_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(gem_icon)

	var label := Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(label)

	var clicked_id := gem_id
	slot.gui_input.connect(
		func(event: InputEvent) -> void:
			if (
				event is InputEventMouseButton
				and event.pressed
				and event.button_index == MOUSE_BUTTON_LEFT
			):
				_on_free_gem_clicked(clicked_id)
	)

	return slot


func _on_free_gem_clicked(gem_id: StringName) -> void:
	_pending_embed_gem_id = gem_id
	_pending_weapon_gem_id = -1
	_rebuild_free_gem_weapon_list()
	_gem_picker_dialog.title = "Embed %s" % ElementalGems.get_display_name(gem_id)
	_gem_picker_hint.text = "Choose a weapon (occupied slots will swap):"
	_gem_picker_dialog.popup_centered()


func _rebuild_free_gem_weapon_list() -> void:
	for child in _gem_picker_list.get_children():
		child.queue_free()

	var candidates := PlayerInventory.get_unique_owned_weapons()
	var any_available := false
	for weapon_id in candidates:
		if GroyperWeapons.get_gem_slots(weapon_id as GroyperWeapons.Id) <= 0:
			continue
		any_available = true
		var embedded := PlayerInventory.get_embedded_gems(weapon_id)
		var button := Button.new()
		if embedded.is_empty():
			button.text = PlayerInventory.get_weapon_display_name(weapon_id)
		else:
			button.text = "%s (swap %s)" % [
				PlayerInventory.get_weapon_display_name(weapon_id),
				ElementalGems.get_display_name(embedded[0]),
			]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var target_id := weapon_id
		button.pressed.connect(_on_free_gem_weapon_chosen.bind(target_id))
		_gem_picker_list.add_child(button)

	if not any_available:
		var empty := Label.new()
		empty.text = "No weapons can hold a gem."
		empty.add_theme_font_size_override("font_size", 11)
		empty.add_theme_color_override("font_color", Color(0.75, 0.7, 0.62, 1))
		_gem_picker_list.add_child(empty)


func _on_free_gem_weapon_chosen(weapon_id: int) -> void:
	if _pending_embed_gem_id.is_empty():
		return
	var gem_id := _pending_embed_gem_id
	_pending_embed_gem_id = &""
	_gem_picker_dialog.hide()
	if PlayerInventory.assign_gem_to_weapon(weapon_id, gem_id, -1):
		refresh()


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
