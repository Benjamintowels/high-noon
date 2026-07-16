extends Control

signal new_game_requested
signal continue_requested
signal back_requested

@onready var _title_label: Label = $Layout/TitleLabel
@onready var _subtitle_label: Label = $Layout/SubtitleLabel
@onready var _new_game_button: Button = $Layout/ButtonRow/NewGameButton
@onready var _continue_button: Button = $Layout/ButtonRow/ContinueButton
@onready var _back_button: Button = $Layout/BackButton

var _continue_available := false


func _ready() -> void:
	modulate.a = 0.0
	_new_game_button.pressed.connect(func() -> void: new_game_requested.emit())
	_continue_button.pressed.connect(_on_continue_pressed)
	_back_button.pressed.connect(func() -> void: back_requested.emit())


func configure(mode_label: String, continue_available: bool, subtitle: String = "") -> void:
	_continue_available = continue_available
	_title_label.text = mode_label
	_subtitle_label.text = subtitle
	_subtitle_label.visible = not subtitle.is_empty()
	_continue_button.disabled = not continue_available
	_continue_button.text = "Continue" if continue_available else "Continue (No Save)"


func reveal() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.35)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_continue_pressed() -> void:
	if not _continue_available:
		return
	continue_requested.emit()
