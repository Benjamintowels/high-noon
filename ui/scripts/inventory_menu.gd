extends Control
class_name InventoryMenuPanel

const GroyperHatCatalog := preload("res://characters/groyper/groyper_hat_catalog.gd")

@onready var _gram_label: Label = $Panel/MarginContainer/VBoxContainer/GramRow/GramLabel
@onready var _weapons_grid: GridContainer = $Panel/MarginContainer/VBoxContainer/WeaponsSection/WeaponsGrid
@onready var _hats_grid: GridContainer = $Panel/MarginContainer/VBoxContainer/HatsSection/HatsGrid
@onready var _quests_list: VBoxContainer = $Panel/MarginContainer/VBoxContainer/QuestsSection/QuestsList
@onready var _mute_sound_check: CheckBox = %MuteSoundCheck

var _syncing_mute_setting := false


func _ready() -> void:
	PinkTreeTreasureQuest.quest_accepted.connect(_on_quest_journal_changed)
	GameSettings.sound_muted_changed.connect(_on_sound_muted_changed)
	_mute_sound_check.toggled.connect(_on_mute_sound_toggled)
	refresh()


func refresh() -> void:
	_gram_label.text = "%d Gram" % PlayerInventory.gram
	_refresh_weapons()
	_refresh_hats()
	_refresh_quests()
	_sync_mute_setting()


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


func _on_quest_journal_changed() -> void:
	_refresh_quests()


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


func _refresh_hats() -> void:
	for child in _hats_grid.get_children():
		child.queue_free()

	for hat_id: StringName in PlayerInventory.owned_hats:
		var slot := _create_hat_slot(
			PlayerInventory.get_hat_display_name(hat_id),
			_hat_slot_color(hat_id)
		)
		_hats_grid.add_child(slot)


func _refresh_quests() -> void:
	for child in _quests_list.get_children():
		child.queue_free()

	var quest_labels: Array[String] = PinkTreeTreasureQuest.get_active_quest_labels()
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
	if hat_id == PlayerInventory.COWBOY_HAT_ID:
		return Color(0.52, 0.28, 0.16)
	return GroyperHatCatalog.get_color(hat_id)


func _create_item_slot(icon: Texture2D, label_text: String) -> VBoxContainer:
	var slot := VBoxContainer.new()
	slot.add_theme_constant_override("separation", 4)

	var icon_rect := TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(48, 48)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.texture = icon
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(icon_rect)

	var label := Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	slot.add_child(label)

	return slot


func _create_hat_slot(label_text: String, hat_color: Color = Color(0.92, 0.9, 0.86)) -> VBoxContainer:
	var slot := VBoxContainer.new()
	slot.add_theme_constant_override("separation", 4)

	var hat_icon := ColorRect.new()
	hat_icon.custom_minimum_size = Vector2(48, 24)
	hat_icon.color = hat_color
	hat_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(hat_icon)

	var label := Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	slot.add_child(label)

	return slot
