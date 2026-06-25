extends CanvasLayer

signal continue_requested

const FxCatalogScript := preload("res://gameplay/fx/fx_catalog.gd")
const FxFramesLoaderScript := preload("res://gameplay/fx/fx_frames_loader.gd")

@onready var _countdown_label: Label = $Layout/CountdownLabel
@onready var _callout_label: Label = $Layout/CalloutLabel
@onready var _score_label: Label = $Layout/ScoreLabel
@onready var _status_label: Label = $Layout/StatusLabel
@onready var _continue_button: Button = $Layout/ContinueButton
@onready var _enemy_aim_reticle: Control = $EnemyAimReticle

var _replay_label: Label
var _replay_hint_label: Label
var _replay_flash: ColorRect
var _replay_vignette: ColorRect
var _replay_slowmo_label: Label
var _screen_fx_root: Control
var _screen_fx_sprite: AnimatedSprite2D
var _screen_fx_active := false


func _ready() -> void:
	_continue_button.pressed.connect(func() -> void:
		continue_requested.emit()
	)
	hide_match_end()
	hide_enemy_aim_reticle()


func show_intro(paces_label: String = "") -> void:
	_countdown_label.text = ""
	_callout_label.text = ""
	_status_label.text = paces_label


func show_countdown(seconds_left: int) -> void:
	_callout_label.text = ""
	_status_label.text = ""
	_countdown_label.text = str(seconds_left)


func show_fault(_message: String) -> void:
	_callout_label.text = "FAULT!"
	_status_label.text = ""
	_countdown_label.text = ""


func show_shoot_callout() -> void:
	_countdown_label.text = ""
	_status_label.text = ""
	_callout_label.text = "SHOOT!"


func show_round_result(message: String) -> void:
	_callout_label.text = ""
	_countdown_label.text = ""
	_status_label.text = message


func show_target_intro(round_number: int) -> void:
	_countdown_label.text = ""
	_callout_label.text = ""
	_status_label.text = "Target Round %d" % round_number


func show_target_timer(seconds_left: float) -> void:
	_callout_label.text = "%.1f" % seconds_left
	_status_label.text = "BLAST!"


func update_target_score(
	player_wins: int,
	rival_wins: int,
	player_hits: int,
	rival_hits: int
) -> void:
	_score_label.text = "Match %d-%d  |  Round %d-%d hits" % [
		player_wins, rival_wins, player_hits, rival_hits
	]


func update_score(player_wins: int, enemy_wins: int, round_number: int) -> void:
	_score_label.text = "Round %d  |  You %d  -  %d Foe" % [round_number, player_wins, enemy_wins]


func show_match_end(message: String, player_won: bool) -> void:
	_countdown_label.text = ""
	_status_label.text = "Match over"
	_score_label.text = "You win!" if player_won else "You lose."
	_continue_button.visible = true
	if player_won:
		_callout_label.text = "That'll Do!"
		show_match_win_fx()
	else:
		hide_screen_symbol_fx()
		_callout_label.text = message


func show_match_win_fx() -> void:
	_play_screen_symbol_fx(FxCatalogScript.crown_frames(), false)


func show_match_point_fx() -> void:
	_callout_label.text = "MatchPoint!"
	_callout_label.modulate.a = 1.0
	_play_screen_symbol_fx(FxCatalogScript.alert_frames(), true)


func hide_match_end() -> void:
	_continue_button.visible = false
	hide_screen_symbol_fx()


func hide_screen_symbol_fx() -> void:
	_screen_fx_active = false
	if _screen_fx_root:
		_screen_fx_root.visible = false
	if _screen_fx_sprite:
		_screen_fx_sprite.stop()


func update_enemy_aim_reticle(world_point: Vector3, camera: Camera3D, urgency: float = 0.0) -> void:
	if camera == null or not camera.is_inside_tree():
		hide_enemy_aim_reticle()
		return

	if camera.is_position_behind(world_point):
		hide_enemy_aim_reticle()
		return

	var screen_pos := camera.unproject_position(world_point)
	var viewport_rect := get_viewport().get_visible_rect()
	if not viewport_rect.has_point(screen_pos):
		hide_enemy_aim_reticle()
		return

	_enemy_aim_reticle.visible = true
	if _enemy_aim_reticle.has_method("set_aim_urgency"):
		_enemy_aim_reticle.set_aim_urgency(urgency)
	if _enemy_aim_reticle.has_method("set_world_aim_screen_position"):
		_enemy_aim_reticle.set_world_aim_screen_position(screen_pos)


func hide_enemy_aim_reticle() -> void:
	_enemy_aim_reticle.visible = false


func show_replay_hud() -> void:
	_ensure_replay_widgets()
	_replay_label.visible = true
	_replay_hint_label.visible = true
	_replay_flash.visible = false
	_replay_flash.modulate.a = 0.0
	_countdown_label.text = ""
	_callout_label.text = "REPLAY"
	_status_label.text = "Click to skip"


func hide_replay_hud() -> void:
	if _replay_label:
		_replay_label.visible = false
	if _replay_hint_label:
		_replay_hint_label.visible = false
	if _replay_flash:
		_replay_flash.visible = false
	if _replay_vignette:
		_replay_vignette.visible = false
	if _replay_slowmo_label:
		_replay_slowmo_label.visible = false
	_callout_label.text = ""


func begin_replay_slowmo() -> void:
	_ensure_replay_widgets()
	pulse_replay_impact()

	if _replay_vignette:
		_replay_vignette.visible = true
		_replay_vignette.modulate.a = 0.0
		var vignette_tween := create_tween()
		vignette_tween.set_ignore_time_scale(true)
		vignette_tween.tween_property(_replay_vignette, "modulate:a", 1.0, 0.12)\
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

	if _replay_slowmo_label:
		_replay_slowmo_label.visible = true
		_replay_slowmo_label.modulate.a = 0.0
		_replay_slowmo_label.scale = Vector2(1.35, 1.35)
		var label_tween := create_tween()
		label_tween.set_ignore_time_scale(true)
		label_tween.set_parallel(true)
		label_tween.tween_property(_replay_slowmo_label, "modulate:a", 0.92, 0.1)
		label_tween.tween_property(_replay_slowmo_label, "scale", Vector2.ONE, 0.28)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func end_replay_slowmo() -> void:
	if _replay_vignette:
		_replay_vignette.visible = false
		_replay_vignette.modulate.a = 0.0
	if _replay_slowmo_label:
		_replay_slowmo_label.visible = false
		_replay_slowmo_label.modulate.a = 0.0
	GameTime.reset_visual_slowmo()


func update_replay_visual_slowmo(ramp_to_normal: float) -> void:
	_ensure_replay_widgets()
	if _replay_vignette:
		_replay_vignette.modulate.a = lerpf(1.0, 0.0, ramp_to_normal)
	if _replay_slowmo_label:
		_replay_slowmo_label.modulate.a = lerpf(0.92, 0.0, ramp_to_normal)


func pulse_replay_impact() -> void:
	_ensure_replay_widgets()
	_replay_flash.visible = true
	_replay_flash.modulate.a = 0.62
	var tween := create_tween()
	tween.set_ignore_time_scale(true)
	tween.tween_property(_replay_flash, "modulate:a", 0.0, 0.55)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func() -> void:
		if _replay_flash:
			_replay_flash.visible = false
	)


func _play_screen_symbol_fx(frames: SpriteFrames, fade_after: bool) -> void:
	if frames == null or frames.get_frame_count(FxFramesLoaderScript.ANIM_NAME) == 0:
		return

	_ensure_screen_fx_widgets()
	_screen_fx_active = true
	_screen_fx_root.visible = true
	_screen_fx_root.modulate.a = 1.0
	_screen_fx_sprite.sprite_frames = frames
	_screen_fx_sprite.modulate.a = 1.0
	_screen_fx_sprite.texture_filter = FxFramesLoaderScript.FILTER_2D
	_screen_fx_sprite.position.x = -80.0 if fade_after else 0.0
	_screen_fx_sprite.play(FxFramesLoaderScript.ANIM_NAME)

	if fade_after:
		if _screen_fx_sprite.animation_finished.is_connected(_on_match_point_fx_finished):
			_screen_fx_sprite.animation_finished.disconnect(_on_match_point_fx_finished)
		_screen_fx_sprite.animation_finished.connect(_on_match_point_fx_finished, CONNECT_ONE_SHOT)


func _on_match_point_fx_finished() -> void:
	if not _screen_fx_active or _screen_fx_root == null:
		return

	var tween := create_tween()
	tween.set_ignore_time_scale(true)
	tween.set_parallel(true)
	tween.tween_property(_screen_fx_root, "modulate:a", 0.0, 0.45)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(_callout_label, "modulate:a", 0.0, 0.45)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.finished.connect(func() -> void:
		hide_screen_symbol_fx()
		_callout_label.text = ""
		_callout_label.modulate.a = 1.0
	)


func _ensure_screen_fx_widgets() -> void:
	if _screen_fx_root != null:
		return

	_screen_fx_root = Control.new()
	_screen_fx_root.name = "ScreenSymbolFX"
	_screen_fx_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen_fx_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_screen_fx_root)

	var stack := VBoxContainer.new()
	stack.name = "Stack"
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 10)
	stack.set_anchors_preset(Control.PRESET_CENTER)
	stack.offset_left = -220.0
	stack.offset_right = 220.0
	stack.offset_top = -120.0
	stack.offset_bottom = 120.0
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen_fx_root.add_child(stack)

	_screen_fx_sprite = AnimatedSprite2D.new()
	_screen_fx_sprite.name = "SymbolSprite"
	_screen_fx_sprite.scale = Vector2(4.0, 4.0)
	_screen_fx_sprite.texture_filter = FxFramesLoaderScript.FILTER_2D
	stack.add_child(_screen_fx_sprite)

	_screen_fx_root.visible = false


func _ensure_replay_widgets() -> void:
	if _replay_label != null:
		return

	_replay_label = Label.new()
	_replay_label.name = "ReplayStamp"
	_replay_label.text = "◉ INSTANT REPLAY"
	_replay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_replay_label.add_theme_font_size_override("font_size", 11)
	_replay_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_replay_label.offset_top = 88.0
	_replay_label.offset_bottom = 108.0
	_replay_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_replay_label)

	_replay_hint_label = Label.new()
	_replay_hint_label.name = "ReplaySkipHint"
	_replay_hint_label.text = "Click anywhere to continue"
	_replay_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_replay_hint_label.add_theme_font_size_override("font_size", 10)
	_replay_hint_label.modulate.a = 0.72
	_replay_hint_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_replay_hint_label.offset_top = -48.0
	_replay_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_replay_hint_label)

	_replay_flash = ColorRect.new()
	_replay_flash.name = "ReplayImpactFlash"
	_replay_flash.color = Color(0.95, 0.35, 0.2, 1.0)
	_replay_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_replay_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_replay_flash.visible = false
	add_child(_replay_flash)

	_replay_vignette = ColorRect.new()
	_replay_vignette.name = "ReplaySlowmoVignette"
	_replay_vignette.color = Color(0.01, 0.005, 0.02, 0.62)
	_replay_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_replay_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_replay_vignette.visible = false
	add_child(_replay_vignette)

	_replay_slowmo_label = Label.new()
	_replay_slowmo_label.name = "ReplaySlowmoLabel"
	_replay_slowmo_label.text = "◆ DIRECT HIT ◆"
	_replay_slowmo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_replay_slowmo_label.add_theme_font_size_override("font_size", 22)
	_replay_slowmo_label.modulate = Color(1.0, 0.88, 0.72, 0.92)
	_replay_slowmo_label.set_anchors_preset(Control.PRESET_CENTER)
	_replay_slowmo_label.offset_left = -180.0
	_replay_slowmo_label.offset_right = 180.0
	_replay_slowmo_label.offset_top = -18.0
	_replay_slowmo_label.offset_bottom = 18.0
	_replay_slowmo_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_replay_slowmo_label.visible = false
	add_child(_replay_slowmo_label)
