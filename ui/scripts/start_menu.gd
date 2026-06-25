extends Control

const TITLE_TEXT := "Pistols at Dawn"
const FADE_DURATION := 1.4
const TITLE_RISE_DURATION := 1.15
const TITLE_RISE_OFFSET := 80.0
const LETTER_STAGGER := 0.04
const LETTER_SPACE_WIDTH := 14.0
const TURN_TRANSITION_DURATION := 0.9
const FIGHT_FADE_DURATION := 0.75
const INTRO_CUTSCENE_SCENE := GameState.INTRO_CUTSCENE_PATH

@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var title_hud: Control = $TitleHud
@onready var title_anchor: Control = $TitleHud/TitleAnchor
@onready var title_container: HBoxContainer = $TitleHud/TitleAnchor/TitleContainer
@onready var button_container: VBoxContainer = $TitleHud/ButtonContainer
@onready var yeehaw_button: Button = $TitleHud/ButtonContainer/YeehawButton
@onready var options_button: Button = $TitleHud/ButtonContainer/OptionsButton
@onready var parallax: Control = $Background
@onready var mode_select: Control = $ModeSelect
@onready var character_select: Control = $CharacterSelect

var _title_target_y: float
var _transitioning: bool = false


func _ready() -> void:
	_build_title_letters()
	_title_target_y = title_anchor.position.y
	button_container.modulate.a = 0.0
	mode_select.position.x = size.x
	mode_select.visible = false
	character_select.position.x = size.x
	character_select.visible = false
	yeehaw_button.pressed.connect(_on_yeehaw_pressed)
	options_button.pressed.connect(_on_options_pressed)
	mode_select.mode_selected.connect(_on_mode_selected)
	mode_select.back_requested.connect(_on_mode_back_requested)
	character_select.fight_requested.connect(_on_fight_requested)
	_play_intro()


func _notification(what: int) -> void:
	if what != NOTIFICATION_RESIZED or not is_node_ready():
		return
	if _transitioning:
		return
	if not mode_select.visible:
		mode_select.position.x = size.x
	if not character_select.visible:
		character_select.position.x = size.x


func _build_title_letters() -> void:
	for child in title_container.get_children():
		child.queue_free()

	for character in TITLE_TEXT:
		if character == " ":
			var spacer := Control.new()
			spacer.custom_minimum_size = Vector2(LETTER_SPACE_WIDTH, 0.0)
			title_container.add_child(spacer)
			continue

		var letter := Label.new()
		letter.text = character
		letter.add_theme_font_size_override("font_size", 26)
		letter.modulate.a = 0.0
		title_container.add_child(letter)


func _play_intro() -> void:
	fade_overlay.modulate.a = 1.0
	title_anchor.position.y = _title_target_y + TITLE_RISE_OFFSET

	var fade_tween := create_tween()
	fade_tween.tween_property(fade_overlay, "modulate:a", 0.0, FADE_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	await get_tree().create_timer(0.3).timeout

	var title_tween := create_tween()
	title_tween.set_parallel(true)
	title_tween.tween_property(
		title_anchor,
		"position:y",
		_title_target_y,
		TITLE_RISE_DURATION
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	var letter_index := 0
	for child in title_container.get_children():
		if child is Label:
			var delay := letter_index * LETTER_STAGGER
			title_tween.tween_property(child, "modulate:a", 1.0, 0.4).set_delay(delay)
			letter_index += 1

	await title_tween.finished

	var buttons_tween := create_tween()
	buttons_tween.tween_property(button_container, "modulate:a", 1.0, 0.55)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_yeehaw_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	yeehaw_button.disabled = true
	options_button.disabled = true
	await _play_turn_to_character_select()


func _play_turn_to_mode_select() -> void:
	mode_select.visible = true
	mode_select.position.x = size.x

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(title_hud, "position:x", -size.x, TURN_TRANSITION_DURATION)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(mode_select, "position:x", 0.0, TURN_TRANSITION_DURATION)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	parallax.play_turn_transition(TURN_TRANSITION_DURATION)

	await tween.finished
	parallax.resume_idle_after_turn()
	mode_select.reveal()
	_transitioning = false


func _on_mode_selected(mode: GameState.GameMode) -> void:
	if _transitioning:
		return
	_transitioning = true
	GameState.selected_game_mode = mode
	await _play_turn_to_character_select()


func _play_turn_to_character_select() -> void:
	character_select.visible = true
	character_select.position.x = size.x

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(title_hud, "position:x", -size.x, TURN_TRANSITION_DURATION)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(character_select, "position:x", 0.0, TURN_TRANSITION_DURATION)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	parallax.play_turn_transition(TURN_TRANSITION_DURATION)

	await tween.finished
	parallax.resume_idle_after_turn()
	character_select.reveal()
	_transitioning = false


func _on_mode_back_requested() -> void:
	if _transitioning:
		return
	_transitioning = true
	await _play_turn_back_to_title()


func _play_turn_back_to_title() -> void:
	title_hud.position.x = -size.x

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(title_hud, "position:x", 0.0, TURN_TRANSITION_DURATION)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(mode_select, "position:x", size.x, TURN_TRANSITION_DURATION)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	parallax.play_turn_transition(TURN_TRANSITION_DURATION)

	await tween.finished
	parallax.resume_idle_after_turn()
	mode_select.visible = false
	mode_select.position.x = size.x
	yeehaw_button.disabled = false
	options_button.disabled = false
	_transitioning = false


func _on_options_pressed() -> void:
	print("Options menu coming soon.")


func _on_fight_requested(character_id: String) -> void:
	if _transitioning:
		return
	_transitioning = true
	GameState.selected_character_id = character_id
	GameState.selected_game_mode = GameState.GameMode.OVERWORLD
	GameState.pending_stage_path = GameState.STAGE1_PATH
	await _fade_out_to_loading()
	get_tree().change_scene_to_file(INTRO_CUTSCENE_SCENE)


func _fade_out_to_loading() -> void:
	fade_overlay.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 1.0, FIGHT_FADE_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
