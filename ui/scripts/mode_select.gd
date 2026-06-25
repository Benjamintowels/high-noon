extends Control

signal mode_selected(mode: GameState.GameMode)
signal back_requested

@onready var _duel_button: Button = $Layout/ButtonRow/DuelButton
@onready var _target_button: Button = $Layout/ButtonRow/TargetButton
@onready var _back_button: Button = $Layout/BackButton


func _ready() -> void:
	modulate.a = 0.0
	_duel_button.pressed.connect(func() -> void: mode_selected.emit(GameState.GameMode.DUEL))
	_target_button.pressed.connect(func() -> void: mode_selected.emit(GameState.GameMode.TARGET))
	_back_button.pressed.connect(func() -> void: back_requested.emit())


func reveal() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.35)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
